import { L } from "./Localization";
import { OvaleOptions } from "./Options";
import { Ovale } from "./Ovale";
import { OvaleData } from "./Data";
import { OvaleSpellBook } from "./SpellBook";
import { OvaleStance } from "./Stance";
import aceEvent from "@wowts/ace_event-3.0";
import { pairs, lualength, _G, LuaArray, LuaObj } from "@wowts/lua";
import { GetTime, UnitHasVehicleUI, UnitExists, UnitIsDead, UnitCanAttack } from "@wowts/wow-mock";
import { OvaleFuture } from "./Future";
import { AstNode } from "./AST";
import { Element } from "./BestAction";

interface SpellFlashCoreClass {
    FlashForm: (spellId: number, color: Color, size: number, brightness: number) => void;   
    FlashPet: (spellId: number, color: Color, size: number, brightness: number) => void;
    FlashAction: (spellId: number, color: Color, size: number, brightness: number) => void;
    FlashItem: (spellId: number, color: Color, size: number, brightness: number) => void;
}

let OvaleSpellFlashBase = Ovale.NewModule("OvaleSpellFlash", aceEvent);
export let OvaleSpellFlash: OvaleSpellFlashClass;
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
{
    let defaultDB = {
        spellFlash: {
            brightness: 1,
            enabled: true,
            hasHostileTarget: false,
            hasTarget: false,
            hideInVehicle: false,
            inCombat: false,
            size: 2.4,
            threshold: 500,
            colorMain: {
                r: 1,
                g: 1,
                b: 1
            },
            colorShortCd: {
                r: 1,
                g: 1,
                b: 0
            },
            colorCd: {
                r: 1,
                g: 1,
                b: 0
            },
            colorInterrupt: {
                r: 0,
                g: 1,
                b: 1
            }
        }
    }
    let options = {
        spellFlash: {
            type: "group",
            name: "SpellFlash",
            disabled: function () {
                return !SpellFlashCore;
            },
            get: function (info: LuaArray<keyof typeof Ovale.db.profile.apparence.spellFlash>) {
                return Ovale.db.profile.apparence.spellFlash[info[lualength(info)]];
            },
            set: function (info: LuaArray<keyof typeof Ovale.db.profile.apparence.spellFlash>, value: number | boolean | Color) {
                Ovale.db.profile.apparence.spellFlash[info[lualength(info)]] = value;
                OvaleOptions.SendMessage("Ovale_OptionChanged");
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
                    disabled: function () {
                        return !SpellFlashCore || !Ovale.db.profile.apparence.spellFlash.enabled;
                    }
                },
                hasTarget: {
                    order: 20,
                    type: "toggle",
                    name: L["Si cible uniquement"],
                    disabled: function () {
                        return !SpellFlashCore || !Ovale.db.profile.apparence.spellFlash.enabled;
                    }
                },
                hasHostileTarget: {
                    order: 30,
                    type: "toggle",
                    name: L["Cacher si cible amicale ou morte"],
                    disabled: function () {
                        return !SpellFlashCore || !Ovale.db.profile.apparence.spellFlash.enabled;
                    }
                },
                hideInVehicle: {
                    order: 40,
                    type: "toggle",
                    name: L["Cacher dans les véhicules"],
                    disabled: function () {
                        return !SpellFlashCore || !Ovale.db.profile.apparence.spellFlash.enabled;
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
                    disabled: function () {
                        return !SpellFlashCore || !Ovale.db.profile.apparence.spellFlash.enabled;
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
                    disabled: function () {
                        return !SpellFlashCore || !Ovale.db.profile.apparence.spellFlash.enabled;
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
                    disabled: function () {
                        return !SpellFlashCore || !Ovale.db.profile.apparence.spellFlash.enabled;
                    }
                },
                colors: {
                    order: 80,
                    type: "group",
                    name: L["Colors"],
                    inline: true,
                    disabled: function () {
                        return !SpellFlashCore || !Ovale.db.profile.apparence.spellFlash.enabled;
                    },
                    get: function (info: LuaArray<keyof typeof Ovale.db.profile.apparence.spellFlash>) {
                        const color = <Color>Ovale.db.profile.apparence.spellFlash[info[lualength(info)]];
                        return [color.r, color.g, color.b, 1.0];
                    },
                    set: function (info: LuaArray<keyof typeof Ovale.db.profile.apparence.spellFlash>, r: number, g: number, b: number, a: number) {
                        const color = <Color>Ovale.db.profile.apparence.spellFlash[info[lualength(info)]];
                        color.r = r;
                        color.g = g;
                        color.b = b;
                        OvaleOptions.SendMessage("Ovale_OptionChanged");
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
    for (const [k, v] of pairs(defaultDB)) {
        OvaleOptions.defaultDB.profile.apparence[k] = v;
    }
    for (const [k, v] of pairs(options)) {
        OvaleOptions.options.args.apparence.args[k] = v;
    }
    OvaleOptions.RegisterOptions(OvaleSpellFlash);
}
class OvaleSpellFlashClass extends OvaleSpellFlashBase {
    OnInitialize() {
        SpellFlashCore = _G["SpellFlashCore"];
        this.RegisterMessage("Ovale_OptionChanged");
        this.Ovale_OptionChanged();
    }
    OnDisable() {
        SpellFlashCore = undefined;
        this.UnregisterMessage("Ovale_OptionChanged");
    }
    Ovale_OptionChanged() {
        const db = Ovale.db.profile.apparence.spellFlash
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
        const db = Ovale.db.profile.apparence.spellFlash
        if (enabled && !db.enabled) {
            enabled = false;
        }
        if (enabled && db.inCombat && !OvaleFuture.IsInCombat(undefined)) {
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
        const db = Ovale.db.profile.apparence.spellFlash
        now = now || GetTime();
        if (this.IsSpellFlashEnabled() && start && start - now <= db.threshold / 1000) {
            if (element && element.type == "action") {
                let spellId, spellInfo;
                if (element.lowername == "spell") {
                    spellId = <number>element.positionalParams[1];
                    spellInfo = OvaleData.spellInfo[spellId];
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
                    if (OvaleStance.IsStanceSpell(spellId)) {
                        SpellFlashCore.FlashForm(spellId, color, size, brightness);
                    }
                    if (OvaleSpellBook.IsPetSpell(spellId)) {
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

OvaleSpellFlash = new OvaleSpellFlashClass()