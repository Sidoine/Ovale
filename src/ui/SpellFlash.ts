import { L } from "./Localization";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { lualength, _G, LuaArray, LuaObj } from "@wowts/lua";
import {
    GetTime,
    UnitHasVehicleUI,
    UnitExists,
    UnitIsDead,
    UnitCanAttack,
} from "@wowts/wow-mock";
import { AstNodeSnapshot } from "../engine/ast";
import { SpellFlashOptions, OvaleOptionsClass } from "./Options";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import { OvaleDataClass } from "../engine/data";
import { OvaleSpellBookClass } from "../states/SpellBook";
import { OvaleStanceClass } from "../states/Stance";
import { OvaleCombatClass } from "../states/combat";
import { OptionUiGroup } from "./acegui-helpers";
import { isNumber, isString } from "../tools/tools";

interface SpellFlashCoreClass {
    FlashForm: (
        spellId: number,
        color: Color | undefined,
        size: number,
        brightness: number
    ) => void;
    FlashPet: (
        spellId: number,
        color: Color | undefined,
        size: number,
        brightness: number
    ) => void;
    FlashAction: (
        spellId: number,
        color: Color | undefined,
        size: number,
        brightness: number
    ) => void;
    FlashItem: (
        spellId: number,
        color: Color | undefined,
        size: number,
        brightness: number
    ) => void;
}

let SpellFlashCore: SpellFlashCoreClass | undefined = undefined;
export interface Color {
    r?: number;
    g?: number;
    b?: number;
}
const colorMain: Color = { r: undefined, g: undefined, b: undefined };
const colorShortCd: Color = { r: undefined, g: undefined, b: undefined };
const colorCd: Color = { r: undefined, g: undefined, b: undefined };
const colorInterrupt: Color = { r: undefined, g: undefined, b: undefined };
const FLASH_COLOR: LuaObj<Color> = {
    main: colorMain,
    cd: colorCd,
    shortcd: colorCd,
};
const COLORTABLE: LuaObj<Color> = {
    aqua: {
        r: 0,
        g: 1,
        b: 1,
    },
    blue: {
        r: 0,
        g: 0,
        b: 1,
    },
    gray: {
        r: 0.5,
        g: 0.5,
        b: 0.5,
    },
    green: {
        r: 0.1,
        g: 1,
        b: 0.1,
    },
    orange: {
        r: 1,
        g: 0.5,
        b: 0.25,
    },
    pink: {
        r: 0.9,
        g: 0.4,
        b: 0.4,
    },
    purple: {
        r: 1,
        g: 0,
        b: 1,
    },
    red: {
        r: 1,
        g: 0.1,
        b: 0.1,
    },
    white: {
        r: 1,
        g: 1,
        b: 1,
    },
    yellow: {
        r: 1,
        g: 1,
        b: 0,
    },
};

export class OvaleSpellFlashClass {
    private module: AceModule & AceEvent;

    constructor(
        private ovaleOptions: OvaleOptionsClass,
        ovale: OvaleClass,
        private combat: OvaleCombatClass,
        private ovaleData: OvaleDataClass,
        private ovaleSpellBook: OvaleSpellBookClass,
        private ovaleStance: OvaleStanceClass
    ) {
        this.module = ovale.createModule(
            "OvaleSpellFlash",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
        this.ovaleOptions.apparence.args.spellFlash = this.getSpellFlashOptions();
    }

    private getSpellFlashOptions(): OptionUiGroup {
        return {
            type: "group",
            name: "SpellFlash",
            disabled: () => {
                return !this.isEnabled();
            },
            get: (info: LuaArray<keyof SpellFlashOptions>) => {
                return this.ovaleOptions.db.profile.apparence.spellFlash[
                    info[lualength(info)]
                ];
            },
            set: <T extends keyof SpellFlashOptions>(
                info: LuaArray<T>,
                value: SpellFlashOptions[T]
            ) => {
                this.ovaleOptions.db.profile.apparence.spellFlash[
                    info[lualength(info)]
                ] = value;
                this.module.SendMessage("Ovale_OptionChanged");
            },
            args: {
                enabled: {
                    order: 10,
                    type: "toggle",
                    name: L["enabled"],
                    desc: L["flash_spells_help"],
                    width: "full",
                },
                inCombat: {
                    order: 10,
                    type: "toggle",
                    name: L["combat_only"],
                    disabled: () => {
                        return (
                            !this.isEnabled() ||
                            !this.ovaleOptions.db.profile.apparence.spellFlash
                                .enabled
                        );
                    },
                },
                hasTarget: {
                    order: 20,
                    type: "toggle",
                    name: L["if_target"],
                    disabled: () => {
                        return (
                            !this.isEnabled() ||
                            !this.ovaleOptions.db.profile.apparence.spellFlash
                                .enabled
                        );
                    },
                },
                hasHostileTarget: {
                    order: 30,
                    type: "toggle",
                    name: L["hide_if_dead_or_friendly_target"],
                    disabled: () => {
                        return (
                            !this.isEnabled() ||
                            !this.ovaleOptions.db.profile.apparence.spellFlash
                                .enabled
                        );
                    },
                },
                hideInVehicle: {
                    order: 40,
                    type: "toggle",
                    name: L["hide_in_vehicles"],
                    disabled: () => {
                        return (
                            !this.isEnabled() ||
                            !this.ovaleOptions.db.profile.apparence.spellFlash
                                .enabled
                        );
                    },
                },
                brightness: {
                    order: 50,
                    type: "range",
                    name: L["flash_brightness"],
                    min: 0,
                    max: 1,
                    bigStep: 0.01,
                    isPercent: true,
                    disabled: () => {
                        return (
                            !this.isEnabled() ||
                            !this.ovaleOptions.db.profile.apparence.spellFlash
                                .enabled
                        );
                    },
                },
                size: {
                    order: 60,
                    type: "range",
                    name: L["flash_size"],
                    min: 0,
                    max: 3,
                    bigStep: 0.01,
                    isPercent: true,
                    disabled: () => {
                        return (
                            !this.isEnabled() ||
                            !this.ovaleOptions.db.profile.apparence.spellFlash
                                .enabled
                        );
                    },
                },
                threshold: {
                    order: 70,
                    type: "range",
                    name: L["flash_threshold"],
                    desc: L["flash_time"],
                    min: 0,
                    max: 1000,
                    step: 1,
                    bigStep: 50,
                    disabled: () => {
                        return (
                            !this.isEnabled() ||
                            !this.ovaleOptions.db.profile.apparence.spellFlash
                                .enabled
                        );
                    },
                },
                colors: {
                    order: 80,
                    type: "group",
                    name: L["colors"],
                    inline: true,
                    disabled: () => {
                        return (
                            !this.isEnabled() ||
                            !this.ovaleOptions.db.profile.apparence.spellFlash
                                .enabled
                        );
                    },
                    get: (
                        info: LuaArray<
                            | "colorMain"
                            | "colorCd"
                            | "colorShortCd"
                            | "colorInterrupt"
                        >
                    ) => {
                        const color = this.ovaleOptions.db.profile.apparence
                            .spellFlash.colors[info[lualength(info)]];
                        return [color.r, color.g, color.b, 1.0];
                    },
                    set: (
                        info: LuaArray<
                            | "colorMain"
                            | "colorCd"
                            | "colorShortCd"
                            | "colorInterrupt"
                        >,
                        r: number,
                        g: number,
                        b: number
                    ) => {
                        const color = this.ovaleOptions.db.profile.apparence
                            .spellFlash.colors[info[lualength(info)]];
                        color.r = r;
                        color.g = g;
                        color.b = b;
                        this.module.SendMessage("Ovale_OptionChanged");
                    },
                    args: {
                        colorMain: {
                            order: 10,
                            type: "color",
                            name: L["main_attack"],
                            hasAlpha: false,
                        },
                        colorCd: {
                            order: 20,
                            type: "color",
                            name: L["long_cd"],
                            hasAlpha: false,
                        },
                        colorShortCd: {
                            order: 30,
                            type: "color",
                            name: L["short_cd"],
                            hasAlpha: false,
                        },
                        colorInterrupt: {
                            order: 40,
                            type: "color",
                            name: L["interrupts"],
                            hasAlpha: false,
                        },
                    },
                },
            },
        };
    }

    isEnabled() {
        return SpellFlashCore !== undefined;
    }

    private OnInitialize = () => {
        SpellFlashCore = _G["SpellFlashCore"];
        this.module.RegisterMessage(
            "Ovale_OptionChanged",
            this.Ovale_OptionChanged
        );
        this.Ovale_OptionChanged();
    };
    private OnDisable = () => {
        SpellFlashCore = undefined;
        this.module.UnregisterMessage("Ovale_OptionChanged");
    };
    private Ovale_OptionChanged = () => {
        const db = this.ovaleOptions.db.profile.apparence.spellFlash;
        colorMain.r = db.colors.colorMain.r;
        colorMain.g = db.colors.colorMain.g;
        colorMain.b = db.colors.colorMain.b;
        colorCd.r = db.colors.colorCd.r;
        colorCd.g = db.colors.colorCd.g;
        colorCd.b = db.colors.colorCd.b;
        colorShortCd.r = db.colors.colorShortCd.r;
        colorShortCd.g = db.colors.colorShortCd.g;
        colorShortCd.b = db.colors.colorShortCd.b;
        colorInterrupt.r = db.colors.colorInterrupt.r;
        colorInterrupt.g = db.colors.colorInterrupt.g;
        colorInterrupt.b = db.colors.colorInterrupt.b;
    };
    IsSpellFlashEnabled() {
        let enabled = SpellFlashCore != undefined;
        const db = this.ovaleOptions.db.profile.apparence.spellFlash;
        if (enabled && !db.enabled) {
            enabled = false;
        }
        if (enabled && db.inCombat && !this.combat.isInCombat(undefined)) {
            enabled = false;
        }
        if (enabled && db.hideInVehicle && UnitHasVehicleUI("player")) {
            enabled = false;
        }
        if (enabled && db.hasTarget && !UnitExists("target")) {
            enabled = false;
        }
        if (
            enabled &&
            db.hasHostileTarget &&
            (UnitIsDead("target") || !UnitCanAttack("player", "target"))
        ) {
            enabled = false;
        }
        return enabled;
    }
    Flash(
        iconFlash: string | undefined,
        iconHelp: string | undefined,
        element: AstNodeSnapshot,
        start: number,
        now?: number
    ) {
        const db = this.ovaleOptions.db.profile.apparence.spellFlash;
        now = now || GetTime();
        if (
            this.IsSpellFlashEnabled() &&
            start &&
            start - now <= db.threshold / 1000
        ) {
            if (element.type == "action") {
                let spellId, spellInfo;
                if (element.actionType == "spell") {
                    spellId = element.actionId;
                    spellInfo = spellId && this.ovaleData.spellInfo[spellId];
                }
                const interrupt = spellInfo && spellInfo.interrupt;
                let color = undefined;
                const flash = element.options && element.options.flash;
                if (isString(flash) && COLORTABLE[flash]) {
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
                const brightness = db.brightness * 100;
                if (SpellFlashCore) {
                    if (element.actionType == "spell" && isNumber(spellId)) {
                        if (this.ovaleStance.IsStanceSpell(spellId)) {
                            SpellFlashCore.FlashForm(
                                spellId,
                                color,
                                size,
                                brightness
                            );
                        }
                        if (this.ovaleSpellBook.IsPetSpell(spellId)) {
                            SpellFlashCore.FlashPet(
                                spellId,
                                color,
                                size,
                                brightness
                            );
                        }
                        SpellFlashCore.FlashAction(
                            spellId,
                            color,
                            size,
                            brightness
                        );
                    } else if (element.actionType == "item") {
                        const itemId = element.actionId;
                        if (isNumber(itemId))
                            SpellFlashCore.FlashItem(
                                itemId,
                                color,
                                size,
                                brightness
                            );
                    }
                }
            }
        }
    }
}
