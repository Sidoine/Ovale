import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { L } from "./Localization";
import AceDB, { AceDatabase } from "@wowts/ace_db-3.0";
import AceDBOptions from "@wowts/ace_db_options-3.0";
import aceConsole, { AceConsole } from "@wowts/ace_console-3.0";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { InterfaceOptionsFrame_OpenToCategory } from "@wowts/wow-mock";
import { ipairs, LuaObj, lualength, LuaArray } from "@wowts/lua";
import { huge } from "@wowts/math";
import { Color } from "./SpellFlash";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import { Print } from "../tools/tools";
import { OptionUiGroup } from "./acegui-helpers";

interface OptionModule {
    UpgradeSavedVariables(): void;
}

const self_register: LuaObj<OptionModule> = {};

export interface SpellFlashOptions {
    enabled: boolean;
    colors: {
        colorMain: Color;
        colorCd: Color;
        colorShortCd: Color;
        colorInterrupt: Color;
    };
    inCombat?: boolean;
    hideInVehicle?: boolean;
    hasTarget?: boolean;
    hasHostileTarget?: boolean;
    threshold: number;
    size: number;
    brightness: number;
}

export interface ApparenceOptions {
    avecCible: boolean;
    clickThru: boolean;
    enCombat: boolean;
    enableIcons: boolean;
    hideEmpty: boolean;
    hideVehicule: boolean;
    margin: number;
    offsetX: number;
    offsetY: number;
    targetHostileOnly: boolean;
    verrouille: boolean;
    vertical: boolean;
    alpha: number;
    flashIcon: boolean;
    remainsFontColor: {
        r: number;
        g: number;
        b: number;
    };
    fontScale: number;
    highlightIcon: true;
    iconScale: number;
    numeric: false;
    raccourcis: true;
    smallIconScale: number;
    targetText: string;
    iconShiftX: number;
    iconShiftY: number;
    optionsAlpha: number;
    secondIconScale: number;
    taggedEnemies: boolean;
    minFrameRefresh: number;
    maxFrameRefresh: number;
    fullAuraScan: false;
    frequentHealthUpdates: true;
    auraLag: number;
    moving: boolean;
    spellFlash: SpellFlashOptions;
    minimap: {
        hide: boolean;
    };
}

export interface OvaleDb {
    profile: {
        source: LuaObj<string>;
        code: string;
        check: LuaObj<boolean>;
        list: LuaObj<string>;
        standaloneOptions: boolean;
        showHiddenScripts: boolean;
        overrideCode?: string;
        apparence: ApparenceOptions;
    };
    global: {
        debug: LuaObj<boolean>;
        profiler: LuaObj<string>;
    };
}

export class OvaleOptionsClass {
    db!: AceDatabase & OvaleDb;

    defaultDB: OvaleDb = {
        profile: {
            source: {},
            code: "",
            showHiddenScripts: false,
            overrideCode: undefined,
            check: {},
            list: {},
            standaloneOptions: false,
            apparence: {
                avecCible: false,
                clickThru: false,
                enCombat: false,
                enableIcons: true,
                hideEmpty: false,
                hideVehicule: false,
                margin: 4,
                offsetX: 0,
                offsetY: 0,
                targetHostileOnly: false,
                verrouille: false,
                vertical: false,
                alpha: 1,
                flashIcon: true,
                remainsFontColor: {
                    r: 1,
                    g: 1,
                    b: 1,
                },
                fontScale: 1,
                highlightIcon: true,
                iconScale: 1,
                numeric: false,
                raccourcis: true,
                smallIconScale: 0.8,
                targetText: "●",
                iconShiftX: 0,
                iconShiftY: 0,
                optionsAlpha: 1,
                secondIconScale: 1,
                taggedEnemies: false,
                minFrameRefresh: 50,
                maxFrameRefresh: 250,
                fullAuraScan: false,
                frequentHealthUpdates: true,
                auraLag: 400,
                moving: false,
                spellFlash: {
                    enabled: true,
                    brightness: 1,
                    hasHostileTarget: false,
                    hasTarget: false,
                    hideInVehicle: false,
                    inCombat: false,
                    size: 2.4,
                    threshold: 500,
                    colors: {
                        colorMain: {
                            r: 1,
                            g: 1,
                            b: 1,
                        },
                        colorShortCd: {
                            r: 1,
                            g: 1,
                            b: 0,
                        },
                        colorCd: {
                            r: 1,
                            g: 1,
                            b: 0,
                        },
                        colorInterrupt: {
                            r: 0,
                            g: 1,
                            b: 1,
                        },
                    },
                },
                minimap: {
                    hide: false,
                },
            },
        },
        global: {
            debug: {},
            profiler: {},
        },
    };

    actions: OptionUiGroup = {
        name: "Actions",
        type: "group",
        args: {
            show: {
                type: "execute",
                name: L["show_frame"],
                guiHidden: true,
                func: () => {
                    this.db.profile.apparence.enableIcons = true;
                    this.module.SendMessage(
                        "Ovale_OptionChanged",
                        "visibility"
                    );
                },
            },
            hide: {
                type: "execute",
                name: L["hide_frame"],
                guiHidden: true,
                func: () => {
                    this.db.profile.apparence.enableIcons = false;
                    this.module.SendMessage(
                        "Ovale_OptionChanged",
                        "visibility"
                    );
                },
            },
            config: {
                name: "Configuration",
                type: "execute",
                func: () => {
                    this.ToggleConfig();
                },
            },
            refresh: {
                name: L["display_refresh_statistics"],
                type: "execute",
                func: () => {
                    let [
                        avgRefresh,
                        minRefresh,
                        maxRefresh,
                        count,
                    ] = this.ovale.GetRefreshIntervalStatistics();
                    if (minRefresh == huge) {
                        [avgRefresh, minRefresh, maxRefresh, count] = [
                            0,
                            0,
                            0,
                            0,
                        ];
                    }
                    Print(
                        "Refresh intervals: count = %d, avg = %d, min = %d, max = %d (ms)",
                        count,
                        avgRefresh,
                        minRefresh,
                        maxRefresh
                    );
                },
            },
        },
    };
    apparence: OptionUiGroup = {
        name: "Ovale Spell Priority",
        type: "group",
        get: (info: LuaArray<keyof ApparenceOptions>) => {
            return this.db.profile.apparence[info[lualength(info)]];
        },
        set: <T extends keyof ApparenceOptions>(
            info: LuaArray<T>,
            value: ApparenceOptions[T]
        ) => {
            this.db.profile.apparence[info[lualength(info)]] = value;
            this.module.SendMessage(
                "Ovale_OptionChanged",
                info[lualength(info) - 1]
            );
        },
        args: {
            standaloneOptions: {
                order: 30,
                name: L["standalone_options"],
                desc: L["movable_configuration_pannel"],
                type: "toggle",
                get: () => {
                    return this.db.profile.standaloneOptions;
                },
                set: (info: LuaArray<string>, value: boolean) => {
                    this.db.profile.standaloneOptions = value;
                },
            },
            iconGroupAppearance: {
                order: 40,
                type: "group",
                name: L["icon_group"],
                args: {
                    enableIcons: {
                        order: 10,
                        type: "toggle",
                        name: L["enabled"],
                        width: "full",
                        set: (info: LuaArray<string>, value: boolean) => {
                            this.db.profile.apparence.enableIcons = value;
                            this.module.SendMessage(
                                "Ovale_OptionChanged",
                                "visibility"
                            );
                        },
                    },
                    verrouille: {
                        order: 10,
                        type: "toggle",
                        name: L["lock_position"],
                        disabled: () => {
                            return !this.db.profile.apparence.enableIcons;
                        },
                    },
                    clickThru: {
                        order: 20,
                        type: "toggle",
                        name: L["ignore_mouse_clicks"],
                        disabled: () => {
                            return !this.db.profile.apparence.enableIcons;
                        },
                    },
                    visibility: {
                        order: 20,
                        type: "group",
                        name: L["visibility"],
                        inline: true,
                        disabled: () => {
                            return !this.db.profile.apparence.enableIcons;
                        },
                        args: {
                            enCombat: {
                                order: 10,
                                type: "toggle",
                                name: L["combat_only"],
                            },
                            avecCible: {
                                order: 20,
                                type: "toggle",
                                name: L["if_target"],
                            },
                            targetHostileOnly: {
                                order: 30,
                                type: "toggle",
                                name: L["hide_if_dead_or_friendly_target"],
                            },
                            hideVehicule: {
                                order: 40,
                                type: "toggle",
                                name: L["hide_in_vehicles"],
                            },
                            hideEmpty: {
                                order: 50,
                                type: "toggle",
                                name: L["hide_empty_buttons"],
                            },
                        },
                    },
                    layout: {
                        order: 30,
                        type: "group",
                        name: L["layout"],
                        inline: true,
                        disabled: () => {
                            return !this.db.profile.apparence.enableIcons;
                        },
                        args: {
                            moving: {
                                order: 10,
                                type: "toggle",
                                name: L["scrolling"],
                                desc: L["scrolling_help"],
                            },
                            vertical: {
                                order: 20,
                                type: "toggle",
                                name: L["vertical"],
                            },
                            offsetX: {
                                order: 30,
                                type: "range",
                                name: L["horizontal_offset"],
                                desc: L["horizontal_offset_help"],
                                min: -1000,
                                max: 1000,
                                softMin: -500,
                                softMax: 500,
                                bigStep: 1,
                            },
                            offsetY: {
                                order: 40,
                                type: "range",
                                name: L["vertical_offset"],
                                desc: L["vertical_offset_help"],
                                min: -1000,
                                max: 1000,
                                softMin: -500,
                                softMax: 500,
                                bigStep: 1,
                            },
                            margin: {
                                order: 50,
                                type: "range",
                                name: L["margin_between_icons"],
                                min: -16,
                                max: 64,
                                step: 1,
                            },
                        },
                    },
                },
            },
            iconAppearance: {
                order: 50,
                type: "group",
                name: L["icon"],
                args: {
                    iconScale: {
                        order: 10,
                        type: "range",
                        name: L["icon_scale"],
                        desc: L["icon_scale"],
                        min: 0.5,
                        max: 3,
                        bigStep: 0.01,
                        isPercent: true,
                    },
                    smallIconScale: {
                        order: 20,
                        type: "range",
                        name: L["small_icon_scale"],
                        desc: L["small_icon_scale_help"],
                        min: 0.5,
                        max: 3,
                        bigStep: 0.01,
                        isPercent: true,
                    },
                    remainsFontColor: {
                        type: "color",
                        order: 25,
                        name: L["remaining_time_font_color"],
                        get: () => {
                            const t = this.db.profile.apparence
                                .remainsFontColor;
                            return [t.r, t.g, t.b];
                        },
                        set: (
                            info: LuaArray<string>,
                            r: number,
                            g: number,
                            b: number
                        ) => {
                            const t = this.db.profile.apparence
                                .remainsFontColor;
                            [t.r, t.g, t.b] = [r, g, b];
                            this.db.profile.apparence.remainsFontColor = t;
                        },
                    },
                    fontScale: {
                        order: 30,
                        type: "range",
                        name: L["font_scale"],
                        desc: L["font_scale_help"],
                        min: 0.2,
                        max: 2,
                        bigStep: 0.01,
                        isPercent: true,
                    },
                    alpha: {
                        order: 40,
                        type: "range",
                        name: L["icon_opacity"],
                        min: 0,
                        max: 1,
                        bigStep: 0.01,
                        isPercent: true,
                    },
                    raccourcis: {
                        order: 50,
                        type: "toggle",
                        name: L["keyboard_shortcuts"],
                        desc: L["show_keyboard_shortcuts"],
                    },
                    numeric: {
                        order: 60,
                        type: "toggle",
                        name: L["show_cooldown"],
                        desc: L["show_cooldown_help"],
                    },
                    highlightIcon: {
                        order: 70,
                        type: "toggle",
                        name: L["highlight_icon"],
                        desc: L["highlight_icon_help"],
                    },
                    flashIcon: {
                        order: 80,
                        type: "toggle",
                        name: L["highlight_icon_on_cd"],
                    },
                    targetText: {
                        order: 90,
                        type: "input",
                        name: L["range_indicator"],
                        desc: L["range_indicator_help"],
                    },
                },
            },
            optionsAppearance: {
                order: 60,
                type: "group",
                name: L["options"],
                args: {
                    iconShiftX: {
                        order: 10,
                        type: "range",
                        name: L["options_horizontal_shift"],
                        min: -256,
                        max: 256,
                        step: 1,
                    },
                    iconShiftY: {
                        order: 20,
                        type: "range",
                        name: L["options_vertical_shift"],
                        min: -256,
                        max: 256,
                        step: 1,
                    },
                    optionsAlpha: {
                        order: 30,
                        type: "range",
                        name: L["option_opacity"],
                        min: 0,
                        max: 1,
                        bigStep: 0.01,
                        isPercent: true,
                    },
                },
            },
            predictiveIcon: {
                order: 70,
                type: "group",
                name: L["two_abilities"],
                args: {
                    predictif: {
                        order: 10,
                        type: "toggle",
                        name: L["two_abilities"],
                        desc: L["two_icons"],
                    },
                    secondIconScale: {
                        order: 20,
                        type: "range",
                        name: L["second_icon_scale"],
                        min: 0.2,
                        max: 1,
                        bigStep: 0.01,
                        isPercent: true,
                    },
                },
            },
            advanced: {
                order: 80,
                type: "group",
                name: "Advanced",
                args: {
                    taggedEnemies: {
                        order: 10,
                        type: "toggle",
                        name: L["only_tagged"],
                        desc: L["only_tagged_help"],
                    },
                    auraLag: {
                        order: 20,
                        type: "range",
                        name: L["aura_lag"],
                        desc: L["lag_threshold"],
                        min: 100,
                        max: 700,
                        step: 10,
                    },
                    minFrameRefresh: {
                        order: 30,
                        type: "range",
                        name: L["min_refresh"],
                        desc: L["min_refresh_help"],
                        min: 50,
                        max: 100,
                        step: 5,
                    },
                    maxFrameRefresh: {
                        order: 40,
                        type: "range",
                        name: L["max_refresh"],
                        desc: L["min_refresh_help"],
                        min: 100,
                        max: 400,
                        step: 10,
                    },
                    fullAuraScan: {
                        order: 50,
                        width: "full",
                        type: "toggle",
                        name: L["scan_all_auras"],
                        desc: L.scan_all_auras_help,
                    },
                    frequentHealthUpdates: {
                        order: 60,
                        width: "full",
                        type: "toggle",
                        name: L["frequent_health_updates"],
                        desc: L["frequent_health_updates_help"],
                    },
                },
            },
        },
    };
    options: OptionUiGroup = {
        type: "group",
        args: {
            apparence: this.apparence,
            actions: this.actions,
            profile: {} as OptionUiGroup,
        },
    };

    module: AceModule & AceConsole & AceEvent;

    constructor(private ovale: OvaleClass) {
        this.module = ovale.createModule(
            "OvaleOptions",
            this.OnInitialize,
            this.handleDisable,
            aceConsole,
            aceEvent
        );
    }

    private OnInitialize = () => {
        const ovale = this.ovale.GetName();
        this.db = AceDB.New("OvaleDB", this.defaultDB);
        const db = this.db;
        this.options.args.profile = AceDBOptions.GetOptionsTable(db);
        // let LibDualSpec = LibStub("LibDualSpec-1.0", true);
        // if (LibDualSpec) {
        //     LibDualSpec.EnhanceDatabase(db, "Ovale");
        //     LibDualSpec.EnhanceOptions(this.options.args.profile, db);
        // }
        db.RegisterCallback(this, "OnNewProfile", this.HandleProfileChanges);
        db.RegisterCallback(this, "OnProfileReset", this.HandleProfileChanges);
        db.RegisterCallback(
            this,
            "OnProfileChanged",
            this.HandleProfileChanges
        );
        db.RegisterCallback(this, "OnProfileCopied", this.HandleProfileChanges);
        this.UpgradeSavedVariables();
        AceConfig.RegisterOptionsTable(ovale, this.options.args.apparence);
        AceConfig.RegisterOptionsTable(
            `${ovale} Profiles`,
            this.options.args.profile
        );
        AceConfig.RegisterOptionsTable(
            `${ovale} Actions`,
            this.options.args.actions,
            "Ovale"
        );
        AceConfigDialog.AddToBlizOptions(ovale);
        AceConfigDialog.AddToBlizOptions(
            `${ovale} Profiles`,
            "Profiles",
            ovale
        );
        this.HandleProfileChanges();
    };

    private handleDisable = () => {};

    RegisterOptions() {
        // tinsert(self_register, addon);
    }
    UpgradeSavedVariables() {
        // const profile = Ovale.db.profile;
        // if (profile.display != undefined && _type(profile.display) == "boolean") {
        //     profile.apparence.enableIcons = profile.display;
        //     profile.display = undefined;
        // }
        // if (profile.left || profile.top) {
        //     profile.left = undefined;
        //     profile.top = undefined;
        //     Ovale.OneTimeMessage("The Ovale icon frames position has been reset.");
        // }
        for (const [, addon] of ipairs(self_register)) {
            if (addon.UpgradeSavedVariables) {
                addon.UpgradeSavedVariables();
            }
        }
        this.db.RegisterDefaults(this.defaultDB);
    }
    private HandleProfileChanges = () => {
        this.module.SendMessage("Ovale_ProfileChanged");
        this.module.SendMessage("Ovale_ScriptChanged");
        this.module.SendMessage("Ovale_OptionChanged", "layout");
        this.module.SendMessage("Ovale_OptionChanged", "visibility");
    };
    ToggleConfig() {
        const appName = this.ovale.GetName();
        if (this.db.profile.standaloneOptions) {
            if (AceConfigDialog.OpenFrames[appName]) {
                AceConfigDialog.Close(appName);
            } else {
                AceConfigDialog.Open(appName);
            }
        } else {
            InterfaceOptionsFrame_OpenToCategory(appName);
            InterfaceOptionsFrame_OpenToCategory(appName);
        }
    }
}
