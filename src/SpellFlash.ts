import { L } from "./Localization";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { lualength, _G, LuaArray, LuaObj } from "@wowts/lua";
import { GetTime, UnitHasVehicleUI, UnitExists, UnitIsDead, UnitCanAttack } from "@wowts/wow-mock";
import { AstNode } from "./AST";
import { Element } from "./BestAction";
import { SpellFlashOptions, OvaleOptionsClass } from "./Options";
import { OvaleClass } from "./Ovale";
import { AceModule } from "@wowts/tsaddon";
import { OvaleFutureClass } from "./Future";
import { OvaleDataClass } from "./Data";
import { OvaleSpellBookClass } from "./SpellBook";
import { OvaleStanceClass } from "./Stance";

interface SpellFlashCoreClass {
    FlashForm: (spellId: number, color: Color, size: number, brightness: number) => void;   
    FlashPet: (spellId: number, color: Color, size: number, brightness: number) => void;
    FlashAction: (spellId: number, color: Color, size: number, brightness: number) => void;
    FlashItem: (spellId: number, color: Color, size: number, brightness: number) => void;
}

let SpellFlashCore: SpellFlashCoreClass = undefined;
export interface Color {
    r?: number;
    g?: number;
    b?: number;
}
let colorMain: Color = { r: undefined, g: undefined, b: undefined }
let colorShortCd: Color = { r: undefined, g: undefined, b: undefined }
let colorCd: Color = {  r: undefined, g: undefined, b: undefined }
let colorInterrupt: Color = {  r: undefined, g: undefined, b: undefined }
let FLASH_COLOR: LuaObj<Color> = {
    main: colorMain,
    cd: colorCd,
    shortcd: colorCd
}
let COLORTABLE: LuaObj<Color> = {
    aqua: {
        r: 0,
        g: 1,
        b: 1
    },
    blue: {
        r: 0,
        g: 0,
        b: 1
    },
    gray: {
        r: 0.5,
        g: 0.5,
        b: 0.5
    },
    green: {
        r: 0.1,
        g: 1,
        b: 0.1
    },
    orange: {
        r: 1,
        g: 0.5,
        b: 0.25
    },
    pink: {
        r: 0.9,
        g: 0.4,
        b: 0.4
    },
    purple: {
        r: 1,
        g: 0,
        b: 1
    },
    red: {
        r: 1,
        g: 0.1,
        b: 0.1
    },
    white: {
        r: 1,
        g: 1,
        b: 1
    },
    yellow: {
        r: 1,
        g: 1,
        b: 0
    }
}

export class OvaleSpellFlashClass {
    private module: AceModule & AceEvent;

    constructor(private ovaleOptions: OvaleOptionsClass, ovale: OvaleClass, private ovaleFuture: OvaleFutureClass, private ovaleData: OvaleDataClass, private ovaleSpellBook: OvaleSpellBookClass, private ovaleStance: OvaleStanceClass) {
        this.module = ovale.createModule("OvaleSpellFlash", this.OnInitialize, this.OnDisable, aceEvent);
        this.ovaleOptions.options.args.apparence.args.spellFlash = this.getSpellFlashOptions();
    }

    private getSpellFlashOptions() {
        return {
            type: "group",
            name: "SpellFlash",
            disabled:  () => {
                return !this.isEnabled();
            },
            get: (info: LuaArray<keyof SpellFlashOptions>) => {
                return this.ovaleOptions.db.profile.apparence.spellFlash[info[lualength(info)]];
            },
            set: <T extends keyof SpellFlashOptions>(info: LuaArray<T>, value: SpellFlashOptions[T]) => {
                this.ovaleOptions.db.profile.apparence.spellFlash[info[lualength(info)]] = value;
                this.module.SendMessage("Ovale_OptionChanged");
            },
            args: {
                enabled: {
                    order: 10,
                    type: "toggle",
                    name: L["Enabled"],
                    desc: L["Flash spells on action bars when they are ready to be cast. Requires SpellFlashCore."],
                    width: "full"
                },
                inCombat: {
                    order: 10,
                    type: "toggle",
                    name: L["En combat uniquement"],
                    disabled: () => {
                        return !this.isEnabled() || !this.ovaleOptions.db.profile.apparence.spellFlash.enabled;
                    }
                },
                hasTarget: {
                    order: 20,
                    type: "toggle",
                    name: L["Si cible uniquement"],
                    disabled: () => {
                        return !this.isEnabled() || !this.ovaleOptions.db.profile.apparence.spellFlash.enabled;
                    }
                },
                hasHostileTarget: {
                    order: 30,
                    type: "toggle",
                    name: L["Cacher si cible amicale ou morte"],
                    disabled: () => {
                        return !this.isEnabled() || !this.ovaleOptions.db.profile.apparence.spellFlash.enabled;
                    }
                },
                hideInVehicle: {
                    order: 40,
                    type: "toggle",
                    name: L["Cacher dans les véhicules"],
                    disabled: () => {
                        return !this.isEnabled() || !this.ovaleOptions.db.profile.apparence.spellFlash.enabled;
                    }
                },
                brightness: {
                    order: 50,
                    type: "range",
                    name: L["Flash brightness"],
                    min: 0,
                    max: 1,
                    bigStep: 0.01,
                    isPercent: true,
                    disabled: () => {
                        return !this.isEnabled() || !this.ovaleOptions.db.profile.apparence.spellFlash.enabled;
                    }
                },
                size: {
                    order: 60,
                    type: "range",
                    name: L["Flash size"],
                    min: 0,
                    max: 3,
                    bigStep: 0.01,
                    isPercent: true,
                    disabled: () => {
                        return !this.isEnabled() || !this.ovaleOptions.db.profile.apparence.spellFlash.enabled;
                    }
                },
                threshold: {
                    order: 70,
                    type: "range",
                    name: L["Flash threshold"],
                    desc: L["Time (in milliseconds) to begin flashing the spell to use before it is ready."],
                    min: 0,
                    max: 1000,
                    step: 1,
                    bigStep: 50,
                    disabled: () => {
                        return !this.isEnabled() || !this.ovaleOptions.db.profile.apparence.spellFlash.enabled;
                    }
                },
                colors: {
                    order: 80,
                    type: "group",
                    name: L["Colors"],
                    inline: true,
                    disabled: () => {
                        return !this.isEnabled() || !this.ovaleOptions.db.profile.apparence.spellFlash.enabled;
                    },
                    get: (info: LuaArray<"colorMain" | "colorCd" | "colorShortCd" | "colorInterrupt">) => {
                        const color = this.ovaleOptions.db.profile.apparence.spellFlash[info[lualength(info)]];
                        return [color.r, color.g, color.b, 1.0];
                    },
                    set: (info: LuaArray<"colorMain" | "colorCd" | "colorShortCd" | "colorInterrupt">, r: number, g: number, b: number, a: number) => {
                        const color = this.ovaleOptions.db.profile.apparence.spellFlash[info[lualength(info)]];
                        color.r = r;
                        color.g = g;
                        color.b = b;
                        this.module.SendMessage("Ovale_OptionChanged");
                    },
                    args: {
                        colorMain: {
                            order: 10,
                            type: "color",
                            name: L["Main attack"],
                            hasAlpha: false
                        },
                        colorCd: {
                            order: 20,
                            type: "color",
                            name: L["Long cooldown abilities"],
                            hasAlpha: false
                        },
                        colorShortCd: {
                            order: 30,
                            type: "color",
                            name: L["Short cooldown abilities"],
                            hasAlpha: false
                        },
                        colorInterrupt: {
                            order: 40,
                            type: "color",
                            name: L["Interrupts"],
                            hasAlpha: false
                        }
                    }
                }
            }
        }
    }

    isEnabled() {
        return SpellFlashCore !== undefined;
    }

    private OnInitialize = () => {
        SpellFlashCore = _G["SpellFlashCore"];
        this.module.RegisterMessage("Ovale_OptionChanged", this.Ovale_OptionChanged);
        this.Ovale_OptionChanged();
    }
    private OnDisable = () => {
        SpellFlashCore = undefined;
        this.module.UnregisterMessage("Ovale_OptionChanged");
    }
    private Ovale_OptionChanged = () => {
        const db = this.ovaleOptions.db.profile.apparence.spellFlash
        colorMain.r = db.colorMain.r;
        colorMain.g = db.colorMain.g;
        colorMain.b = db.colorMain.b;
        colorCd.r = db.colorCd.r;
        colorCd.g = db.colorCd.g;
        colorCd.b = db.colorCd.b;
        colorShortCd.r = db.colorShortCd.r;
        colorShortCd.g = db.colorShortCd.g;
        colorShortCd.b = db.colorShortCd.b;
        colorInterrupt.r = db.colorInterrupt.r;
        colorInterrupt.g = db.colorInterrupt.g;
        colorInterrupt.b = db.colorInterrupt.b;
    }
    IsSpellFlashEnabled() {
        let enabled = (SpellFlashCore != undefined);
        const db = this.ovaleOptions.db.profile.apparence.spellFlash
        if (enabled && !db.enabled) {
            enabled = false;
        }
        if (enabled && db.inCombat && !this.ovaleFuture.IsInCombat(undefined)) {
            enabled = false;
        }
        if (enabled && db.hideInVehicle && UnitHasVehicleUI("player")) {
            enabled = false;
        }
        if (enabled && db.hasTarget && !UnitExists("target")) {
            enabled = false;
        }
        if (enabled && db.hasHostileTarget && (UnitIsDead("target") || !UnitCanAttack("player", "target"))) {
            enabled = false;
        }
        return enabled;
    }
    Flash(state: {}, node: AstNode, element: Element, start: number, now?:number) {
        const db = this.ovaleOptions.db.profile.apparence.spellFlash
        now = now || GetTime();
        if (this.IsSpellFlashEnabled() && start && start - now <= db.threshold / 1000) {
            if (element && element.type == "action") {
                let spellId, spellInfo;
                if (element.lowername == "spell") {
                    spellId = <number>element.positionalParams[1];
                    spellInfo = this.ovaleData.spellInfo[spellId];
                }
                let interrupt = spellInfo && spellInfo.interrupt;
                let color = undefined;
                let flash = element.namedParams && element.namedParams.flash;
                let iconFlash = node.namedParams.flash;
                let iconHelp = node.namedParams.help;
                if (flash && COLORTABLE[flash]) {
                    color = COLORTABLE[flash];
                } else if (iconFlash && COLORTABLE[iconFlash]) {
                    color = COLORTABLE[iconFlash];
                } else if (iconHelp && FLASH_COLOR[iconHelp]) {
                    color = FLASH_COLOR[iconHelp];
                    if (interrupt == 1 && iconHelp == "cd") {
                        color = colorInterrupt;
                    }
                }
                let size = db.size * 100;
                if (iconHelp == "cd") {
                    if (interrupt != 1) {
                        size = size * 0.5;
                    }
                }
                let brightness = db.brightness * 100;
                if (element.lowername == "spell") {
                    if (this.ovaleStance.IsStanceSpell(spellId)) {
                        SpellFlashCore.FlashForm(spellId, color, size, brightness);
                    }
                    if (this.ovaleSpellBook.IsPetSpell(spellId)) {
                        SpellFlashCore.FlashPet(spellId, color, size, brightness);
                    }
                    SpellFlashCore.FlashAction(spellId, color, size, brightness);
                } else if (element.lowername == "item") {
                    let itemId = <number>element.positionalParams[1];
                    SpellFlashCore.FlashItem(itemId, color, size, brightness);
                }
            }
        }
    }
}
