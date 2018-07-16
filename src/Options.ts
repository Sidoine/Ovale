import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { L } from "./Localization";
import AceDB from "@wowts/ace_db-3.0";
import AceDBOptions from "@wowts/ace_db_options-3.0";
import { OvaleDb, Ovale } from "./Ovale";
import aceConsole from "@wowts/ace_console-3.0";
import aceEvent from "@wowts/ace_event-3.0";
import { InterfaceOptionsFrame_OpenToCategory } from "@wowts/wow-mock";
import { ipairs, LuaObj, lualength, LuaArray } from "@wowts/lua";
let OvaleOptionsBase = Ovale.NewModule("OvaleOptions", aceConsole, aceEvent);
interface OptionModule {
    UpgradeSavedVariables():void;
}

let self_register:LuaObj<OptionModule> = {  }

class OvaleOptionsClass extends OvaleOptionsBase {
    defaultDB:OvaleDb = {
        profile: {
            source: undefined,
            code: undefined,
            showHiddenScripts: false,
            overrideCode: undefined,
            check: {
            },
            list: {
            },
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
                    b: 1
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
                predictif: false,
                secondIconScale: 1,
                taggedEnemies: false,
                minFrameRefresh: 50,
                maxFrameRefresh: 250,
                fullAuraScan: false,
                auraLag: 400,
                moving: false,
                spellFlash: {
                    enabled: true,
                },
                minimap: { 
                    hide: false
                }
            }
        },
        global:undefined
    }

    options: any = {
        type: "group",
        args: {
            apparence: {
                name: Ovale.GetName(),
                type: "group",
                get: (info: LuaArray<string>) => {
                    return Ovale.db.profile.apparence[info[lualength(info)]];
                },
                set: (info: LuaArray<string>, value: string) => {
                    Ovale.db.profile.apparence[info[lualength(info)]] = value;
                    this.SendMessage("Ovale_OptionChanged", info[lualength(info) - 1]);
                },
                args: {
                    standaloneOptions: {
                        order: 30,
                        name: L["Standalone options"],
                        desc: L["Open configuration panel in a separate, movable window."],
                        type: "toggle",
                        get: function (info: LuaArray<string>) {
                            return Ovale.db.profile.standaloneOptions;
                        },
                        set: function (info: LuaArray<string>, value: boolean) {
                            Ovale.db.profile.standaloneOptions = value;
                        }
                    },
                    iconGroupAppearance: {
                        order: 40,
                        type: "group",
                        name: L["Groupe d'icônes"],
                        args: {
                            enableIcons: {
                                order: 10,
                                type: "toggle",
                                name: L["Enabled"],
                                width: "full",
                                set: (info: LuaArray<string>, value: boolean) => {
                                    Ovale.db.profile.apparence.enableIcons = value;
                                    this.SendMessage("Ovale_OptionChanged", "visibility");
                                }
                            },
                            verrouille: {
                                order: 10,
                                type: "toggle",
                                name: L["Verrouiller position"],
                                disabled: () => {
                                    return !Ovale.db.profile.apparence.enableIcons;
                                }
                            },
                            clickThru: {
                                order: 20,
                                type: "toggle",
                                name: L["Ignorer les clics souris"],
                                disabled: () => {
                                    return !Ovale.db.profile.apparence.enableIcons;
                                }
                            },
                            visibility: {
                                order: 20,
                                type: "group",
                                name: L["Visibilité"],
                                inline: true,
                                disabled: function () {
                                    return !Ovale.db.profile.apparence.enableIcons;
                                },
                                args: {
                                    enCombat: {
                                        order: 10,
                                        type: "toggle",
                                        name: L["En combat uniquement"]
                                    },
                                    avecCible: {
                                        order: 20,
                                        type: "toggle",
                                        name: L["Si cible uniquement"]
                                    },
                                    targetHostileOnly: {
                                        order: 30,
                                        type: "toggle",
                                        name: L["Cacher si cible amicale ou morte"]
                                    },
                                    hideVehicule: {
                                        order: 40,
                                        type: "toggle",
                                        name: L["Cacher dans les véhicules"]
                                    },
                                    hideEmpty: {
                                        order: 50,
                                        type: "toggle",
                                        name: L["Cacher bouton vide"]
                                    }
                                }
                            },
                            layout: {
                                order: 30,
                                type: "group",
                                name: L["Layout"],
                                inline: true,
                                disabled: function () {
                                    return !Ovale.db.profile.apparence.enableIcons;
                                },
                                args: {
                                    moving: {
                                        order: 10,
                                        type: "toggle",
                                        name: L["Défilement"],
                                        desc: L["Les icônes se déplacent"]
                                    },
                                    vertical: {
                                        order: 20,
                                        type: "toggle",
                                        name: L["Vertical"]
                                    },
                                    offsetX: {
                                        order: 30,
                                        type: "range",
                                        name: L["Horizontal offset"],
                                        desc: L["Horizontal offset from the center of the screen."],
                                        min: -1000,
                                        max: 1000,
                                        softMin: -500,
                                        softMax: 500,
                                        bigStep: 1
                                    },
                                    offsetY: {
                                        order: 40,
                                        type: "range",
                                        name: L["Vertical offset"],
                                        desc: L["Vertical offset from the center of the screen."],
                                        min: -1000,
                                        max: 1000,
                                        softMin: -500,
                                        softMax: 500,
                                        bigStep: 1
                                    },
                                    margin: {
                                        order: 50,
                                        type: "range",
                                        name: L["Marge entre deux icônes"],
                                        min: -16,
                                        max: 64,
                                        step: 1
                                    }
                                }
                            }
                        }
                    },
                    iconAppearance: {
                        order: 50,
                        type: "group",
                        name: L["Icône"],
                        args: {
                            iconScale: {
                                order: 10,
                                type: "range",
                                name: L["Taille des icônes"],
                                desc: L["La taille des icônes"],
                                min: 0.5,
                                max: 3,
                                bigStep: 0.01,
                                isPercent: true
                            },
                            smallIconScale: {
                                order: 20,
                                type: "range",
                                name: L["Taille des petites icônes"],
                                desc: L["La taille des petites icônes"],
                                min: 0.5,
                                max: 3,
                                bigStep: 0.01,
                                isPercent: true
                            },
                            remainsFontColor: {
                                type: "color",
                                order: 25,
                                name: L["Remaining time font color"],
                                get: function (info: LuaArray<string>) {
                                    const t = Ovale.db.profile.apparence.remainsFontColor;
                                    return [t.r, t.g, t.b];
                                },
                                set: function (info: LuaArray<string>, r: number, g: number, b: number) {
                                    const t = Ovale.db.profile.apparence.remainsFontColor;
                                    [t.r, t.g, t.b] = [r, g, b];
                                    Ovale.db.profile.apparence.remainsFontColor = t;
                                }
                            },
                            fontScale: {
                                order: 30,
                                type: "range",
                                name: L["Taille des polices"],
                                desc: L["La taille des polices"],
                                min: 0.2,
                                max: 2,
                                bigStep: 0.01,
                                isPercent: true
                            },
                            alpha: {
                                order: 40,
                                type: "range",
                                name: L["Opacité des icônes"],
                                min: 0,
                                max: 1,
                                bigStep: 0.01,
                                isPercent: true
                            },
                            raccourcis: {
                                order: 50,
                                type: "toggle",
                                name: L["Raccourcis clavier"],
                                desc: L["Afficher les raccourcis clavier dans le coin inférieur gauche des icônes"]
                            },
                            numeric: {
                                order: 60,
                                type: "toggle",
                                name: L["Affichage numérique"],
                                desc: L["Affiche le temps de recharge sous forme numérique"]
                            },
                            highlightIcon: {
                                order: 70,
                                type: "toggle",
                                name: L["Illuminer l'icône"],
                                desc: L["Illuminer l'icône quand la technique doit être spammée"]
                            },
                            flashIcon: {
                                order: 80,
                                type: "toggle",
                                name: L["Illuminer l'icône quand le temps de recharge est écoulé"]
                            },
                            targetText: {
                                order: 90,
                                type: "input",
                                name: L["Caractère de portée"],
                                desc: L["Ce caractère est affiché dans un coin de l'icône pour indiquer si la cible est à portée"]
                            }
                        }
                    },
                    optionsAppearance: {
                        order: 60,
                        type: "group",
                        name: L["Options"],
                        args: {
                            iconShiftX: {
                                order: 10,
                                type: "range",
                                name: L["Décalage horizontal des options"],
                                min: -256,
                                max: 256,
                                step: 1
                            },
                            iconShiftY: {
                                order: 20,
                                type: "range",
                                name: L["Décalage vertical des options"],
                                min: -256,
                                max: 256,
                                step: 1
                            },
                            optionsAlpha: {
                                order: 30,
                                type: "range",
                                name: L["Opacité des options"],
                                min: 0,
                                max: 1,
                                bigStep: 0.01,
                                isPercent: true
                            }
                        }
                    },
                    predictiveIcon: {
                        order: 70,
                        type: "group",
                        name: L["Prédictif"],
                        args: {
                            predictif: {
                                order: 10,
                                type: "toggle",
                                name: L["Prédictif"],
                                desc: L["Affiche les deux prochains sorts et pas uniquement le suivant"]
                            },
                            secondIconScale: {
                                order: 20,
                                type: "range",
                                name: L["Taille du second icône"],
                                min: 0.2,
                                max: 1,
                                bigStep: 0.01,
                                isPercent: true
                            }
                        }
                    },
                    advanced: {
                        order: 80,
                        type: "group",
                        name: "Advanced",
                        args: {
                            taggedEnemies: {
                                order: 10,
                                type: "toggle",
                                name: L["Only count tagged enemies"],
                                desc: L["Only count a mob as an enemy if it is directly affected by a player's spells."]
                            },
                            auraLag: {
                                order: 20,
                                type: "range",
                                name: L["Aura lag"],
                                desc: L["Lag (in milliseconds) between when an spell is cast and when the affected aura is applied or removed"],
                                min: 100,
                                max: 700,
                                step: 10
                            },
                            minFrameRefresh: {
                                order: 30,
                                type: "range",
                                name: L["Min Refresh"],
                                desc: L["Minimum time (in milliseconds) between updates; lower values may reduce FPS."],
                                min: 50,
                                max: 100,
                                step: 5
                            },
                            maxFrameRefresh: {
                                order: 40,
                                type: "range",
                                name: L["Max Refresh"],
                                desc: L["Minimum time (in milliseconds) between updates; lower values may reduce FPS."],
                                min: 100,
                                max: 400,
                                step: 10
                            },
                            fullAuraScan: {
                                order: 50,
                                width: "full",
                                type: "toggle",
                                name: L['Full buffs/debuffs scan'],
                                desc: L['Scans also buffs/debuffs casted by other players\n\nWarning!: Very CPU intensive'],
                            }
                        }
                    }
                }
            },
            actions: {
                name: "Actions",
                type: "group",
                args: {
                    show: {
                        type: "execute",
                        name: L["Afficher la fenêtre"],
                        guiHidden: true,
                        func: () => {
                            Ovale.db.profile.apparence.enableIcons = true;
                            this.SendMessage("Ovale_OptionChanged", "visibility");
                        }
                    },
                    hide: {
                        type: "execute",
                        name: L["Cacher la fenêtre"],
                        guiHidden: true,
                        func: () => {
                            Ovale.db.profile.apparence.enableIcons = false;
                            this.SendMessage("Ovale_OptionChanged", "visibility");
                        }
                    },
                    config: {
                        name: "Configuration",
                        type: "execute",
                        func: () => {
                            this.ToggleConfig();
                        }
                    },
                    refresh: {
                        name: L["Display refresh statistics"],
                        type: "execute",
                        func: () => {
                            let [avgRefresh, minRefresh, maxRefresh, count] = Ovale.GetRefreshIntervalStatistics();
                            Ovale.Print("Refresh intervals: count = %d, avg = %d, min = %d, max = %d (ms)", count, avgRefresh, minRefresh, maxRefresh);
                        }
                    }
                }
            },
            profile: {}
        }
    }

    OnInitialize() {
        const ovale = Ovale.GetName();
        const db = AceDB.New("OvaleDB", this.defaultDB);
        this.options.args.profile = AceDBOptions.GetOptionsTable(db);
        // let LibDualSpec = LibStub("LibDualSpec-1.0", true);
        // if (LibDualSpec) {
        //     LibDualSpec.EnhanceDatabase(db, "Ovale");
        //     LibDualSpec.EnhanceOptions(this.options.args.profile, db);
        // }
        db.RegisterCallback(this, "OnNewProfile", "HandleProfileChanges");
        db.RegisterCallback(this, "OnProfileReset", "HandleProfileChanges");
        db.RegisterCallback(this, "OnProfileChanged", "HandleProfileChanges");
        db.RegisterCallback(this, "OnProfileCopied", "HandleProfileChanges");
        Ovale.db = db;
        this.UpgradeSavedVariables();
        AceConfig.RegisterOptionsTable(ovale, this.options.args.apparence);
        AceConfig.RegisterOptionsTable(`${ovale} Profiles`, this.options.args.profile);
        AceConfig.RegisterOptionsTable(`${ovale} Actions`, this.options.args.actions, "Ovale");
        AceConfigDialog.AddToBlizOptions(ovale);
        AceConfigDialog.AddToBlizOptions(`${ovale} Profiles`, "Profiles", ovale);
        this.HandleProfileChanges();
    }
    RegisterOptions(addon: {}) {
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
        Ovale.db.RegisterDefaults(this.defaultDB);
    }
    HandleProfileChanges() {
        this.SendMessage("Ovale_ProfileChanged");
        this.SendMessage("Ovale_ScriptChanged");
        this.SendMessage("Ovale_OptionChanged", "layout");
        this.SendMessage("Ovale_OptionChanged", "visibility");
    }
    ToggleConfig() {
        let appName = Ovale.GetName();
        if (Ovale.db.profile.standaloneOptions) {
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

export const OvaleOptions = new OvaleOptionsClass();