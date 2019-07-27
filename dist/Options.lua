local __exports = LibStub:NewLibrary("ovale/Options", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local AceConfig = LibStub:GetLibrary("AceConfig-3.0", true)
local AceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0", true)
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local AceDB = LibStub:GetLibrary("AceDB-3.0", true)
local AceDBOptions = LibStub:GetLibrary("AceDBOptions-3.0", true)
local aceConsole = LibStub:GetLibrary("AceConsole-3.0", true)
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
local ipairs = ipairs
local huge = math.huge
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Print = __Ovale.Print
local self_register = {}
__exports.OvaleOptionsClass = __class(nil, {
    constructor = function(self, ovale)
        self.ovale = ovale
        self.db = nil
        self.defaultDB = {
            profile = {
                source = nil,
                code = nil,
                showHiddenScripts = false,
                overrideCode = nil,
                check = {},
                list = {},
                standaloneOptions = false,
                apparence = {
                    avecCible = false,
                    clickThru = false,
                    enCombat = false,
                    enableIcons = true,
                    hideEmpty = false,
                    hideVehicule = false,
                    margin = 4,
                    offsetX = 0,
                    offsetY = 0,
                    targetHostileOnly = false,
                    verrouille = false,
                    vertical = false,
                    alpha = 1,
                    flashIcon = true,
                    remainsFontColor = {
                        r = 1,
                        g = 1,
                        b = 1
                    },
                    fontScale = 1,
                    highlightIcon = true,
                    iconScale = 1,
                    numeric = false,
                    raccourcis = true,
                    smallIconScale = 0.8,
                    targetText = "●",
                    iconShiftX = 0,
                    iconShiftY = 0,
                    optionsAlpha = 1,
                    predictif = false,
                    secondIconScale = 1,
                    taggedEnemies = false,
                    minFrameRefresh = 50,
                    maxFrameRefresh = 250,
                    fullAuraScan = false,
                    frequentHealthUpdates = true,
                    auraLag = 400,
                    moving = false,
                    spellFlash = {
                        enabled = true,
                        brightness = 1,
                        hasHostileTarget = false,
                        hasTarget = false,
                        hideInVehicle = false,
                        inCombat = false,
                        size = 2.4,
                        threshold = 500,
                        colorMain = {
                            r = 1,
                            g = 1,
                            b = 1
                        },
                        colorShortCd = {
                            r = 1,
                            g = 1,
                            b = 0
                        },
                        colorCd = {
                            r = 1,
                            g = 1,
                            b = 0
                        },
                        colorInterrupt = {
                            r = 0,
                            g = 1,
                            b = 1
                        }
                    },
                    minimap = {
                        hide = false
                    }
                }
            },
            global = nil
        }
        self.options = {
            type = "group",
            args = {
                apparence = {
                    name = "Ovale Spell Priority",
                    type = "group",
                    get = function(info)
                        return self.db.profile.apparence[info[#info]]
                    end,
                    set = function(info, value)
                        self.db.profile.apparence[info[#info]] = value
                        self.module:SendMessage("Ovale_OptionChanged", info[#info - 1])
                    end,
                    args = {
                        standaloneOptions = {
                            order = 30,
                            name = L["Standalone options"],
                            desc = L["Open configuration panel in a separate, movable window."],
                            type = "toggle",
                            get = function(info)
                                return self.db.profile.standaloneOptions
                            end,
                            set = function(info, value)
                                self.db.profile.standaloneOptions = value
                            end
                        },
                        iconGroupAppearance = {
                            order = 40,
                            type = "group",
                            name = L["Groupe d'icônes"],
                            args = {
                                enableIcons = {
                                    order = 10,
                                    type = "toggle",
                                    name = L["Enabled"],
                                    width = "full",
                                    set = function(info, value)
                                        self.db.profile.apparence.enableIcons = value
                                        self.module:SendMessage("Ovale_OptionChanged", "visibility")
                                    end
                                },
                                verrouille = {
                                    order = 10,
                                    type = "toggle",
                                    name = L["Verrouiller position"],
                                    disabled = function()
                                        return  not self.db.profile.apparence.enableIcons
                                    end
                                },
                                clickThru = {
                                    order = 20,
                                    type = "toggle",
                                    name = L["Ignorer les clics souris"],
                                    disabled = function()
                                        return  not self.db.profile.apparence.enableIcons
                                    end
                                },
                                visibility = {
                                    order = 20,
                                    type = "group",
                                    name = L["Visibilité"],
                                    inline = true,
                                    disabled = function()
                                        return  not self.db.profile.apparence.enableIcons
                                    end,
                                    args = {
                                        enCombat = {
                                            order = 10,
                                            type = "toggle",
                                            name = L["En combat uniquement"]
                                        },
                                        avecCible = {
                                            order = 20,
                                            type = "toggle",
                                            name = L["Si cible uniquement"]
                                        },
                                        targetHostileOnly = {
                                            order = 30,
                                            type = "toggle",
                                            name = L["Cacher si cible amicale ou morte"]
                                        },
                                        hideVehicule = {
                                            order = 40,
                                            type = "toggle",
                                            name = L["Cacher dans les véhicules"]
                                        },
                                        hideEmpty = {
                                            order = 50,
                                            type = "toggle",
                                            name = L["Cacher bouton vide"]
                                        }
                                    }
                                },
                                layout = {
                                    order = 30,
                                    type = "group",
                                    name = L["Layout"],
                                    inline = true,
                                    disabled = function()
                                        return  not self.db.profile.apparence.enableIcons
                                    end,
                                    args = {
                                        moving = {
                                            order = 10,
                                            type = "toggle",
                                            name = L["Défilement"],
                                            desc = L["Les icônes se déplacent"]
                                        },
                                        vertical = {
                                            order = 20,
                                            type = "toggle",
                                            name = L["Vertical"]
                                        },
                                        offsetX = {
                                            order = 30,
                                            type = "range",
                                            name = L["Horizontal offset"],
                                            desc = L["Horizontal offset from the center of the screen."],
                                            min = -1000,
                                            max = 1000,
                                            softMin = -500,
                                            softMax = 500,
                                            bigStep = 1
                                        },
                                        offsetY = {
                                            order = 40,
                                            type = "range",
                                            name = L["Vertical offset"],
                                            desc = L["Vertical offset from the center of the screen."],
                                            min = -1000,
                                            max = 1000,
                                            softMin = -500,
                                            softMax = 500,
                                            bigStep = 1
                                        },
                                        margin = {
                                            order = 50,
                                            type = "range",
                                            name = L["Marge entre deux icônes"],
                                            min = -16,
                                            max = 64,
                                            step = 1
                                        }
                                    }
                                }
                            }
                        },
                        iconAppearance = {
                            order = 50,
                            type = "group",
                            name = L["Icône"],
                            args = {
                                iconScale = {
                                    order = 10,
                                    type = "range",
                                    name = L["Taille des icônes"],
                                    desc = L["La taille des icônes"],
                                    min = 0.5,
                                    max = 3,
                                    bigStep = 0.01,
                                    isPercent = true
                                },
                                smallIconScale = {
                                    order = 20,
                                    type = "range",
                                    name = L["Taille des petites icônes"],
                                    desc = L["La taille des petites icônes"],
                                    min = 0.5,
                                    max = 3,
                                    bigStep = 0.01,
                                    isPercent = true
                                },
                                remainsFontColor = {
                                    type = "color",
                                    order = 25,
                                    name = L["Remaining time font color"],
                                    get = function(info)
                                        local t = self.db.profile.apparence.remainsFontColor
                                        return t.r, t.g, t.b
                                    end,
                                    set = function(info, r, g, b)
                                        local t = self.db.profile.apparence.remainsFontColor
                                        t.r, t.g, t.b = r, g, b
                                        self.db.profile.apparence.remainsFontColor = t
                                    end
                                },
                                fontScale = {
                                    order = 30,
                                    type = "range",
                                    name = L["Taille des polices"],
                                    desc = L["La taille des polices"],
                                    min = 0.2,
                                    max = 2,
                                    bigStep = 0.01,
                                    isPercent = true
                                },
                                alpha = {
                                    order = 40,
                                    type = "range",
                                    name = L["Opacité des icônes"],
                                    min = 0,
                                    max = 1,
                                    bigStep = 0.01,
                                    isPercent = true
                                },
                                raccourcis = {
                                    order = 50,
                                    type = "toggle",
                                    name = L["Raccourcis clavier"],
                                    desc = L["Afficher les raccourcis clavier dans le coin inférieur gauche des icônes"]
                                },
                                numeric = {
                                    order = 60,
                                    type = "toggle",
                                    name = L["Affichage numérique"],
                                    desc = L["Affiche le temps de recharge sous forme numérique"]
                                },
                                highlightIcon = {
                                    order = 70,
                                    type = "toggle",
                                    name = L["Illuminer l'icône"],
                                    desc = L["Illuminer l'icône quand la technique doit être spammée"]
                                },
                                flashIcon = {
                                    order = 80,
                                    type = "toggle",
                                    name = L["Illuminer l'icône quand le temps de recharge est écoulé"]
                                },
                                targetText = {
                                    order = 90,
                                    type = "input",
                                    name = L["Caractère de portée"],
                                    desc = L["Ce caractère est affiché dans un coin de l'icône pour indiquer si la cible est à portée"]
                                }
                            }
                        },
                        optionsAppearance = {
                            order = 60,
                            type = "group",
                            name = L["Options"],
                            args = {
                                iconShiftX = {
                                    order = 10,
                                    type = "range",
                                    name = L["Décalage horizontal des options"],
                                    min = -256,
                                    max = 256,
                                    step = 1
                                },
                                iconShiftY = {
                                    order = 20,
                                    type = "range",
                                    name = L["Décalage vertical des options"],
                                    min = -256,
                                    max = 256,
                                    step = 1
                                },
                                optionsAlpha = {
                                    order = 30,
                                    type = "range",
                                    name = L["Opacité des options"],
                                    min = 0,
                                    max = 1,
                                    bigStep = 0.01,
                                    isPercent = true
                                }
                            }
                        },
                        predictiveIcon = {
                            order = 70,
                            type = "group",
                            name = L["Prédictif"],
                            args = {
                                predictif = {
                                    order = 10,
                                    type = "toggle",
                                    name = L["Prédictif"],
                                    desc = L["Affiche les deux prochains sorts et pas uniquement le suivant"]
                                },
                                secondIconScale = {
                                    order = 20,
                                    type = "range",
                                    name = L["Taille du second icône"],
                                    min = 0.2,
                                    max = 1,
                                    bigStep = 0.01,
                                    isPercent = true
                                }
                            }
                        },
                        advanced = {
                            order = 80,
                            type = "group",
                            name = "Advanced",
                            args = {
                                taggedEnemies = {
                                    order = 10,
                                    type = "toggle",
                                    name = L["Only count tagged enemies"],
                                    desc = L["Only count a mob as an enemy if it is directly affected by a player's spells."]
                                },
                                auraLag = {
                                    order = 20,
                                    type = "range",
                                    name = L["Aura lag"],
                                    desc = L["Lag (in milliseconds) between when an spell is cast and when the affected aura is applied or removed"],
                                    min = 100,
                                    max = 700,
                                    step = 10
                                },
                                minFrameRefresh = {
                                    order = 30,
                                    type = "range",
                                    name = L["Min Refresh"],
                                    desc = L["Minimum time (in milliseconds) between updates; lower values may reduce FPS."],
                                    min = 50,
                                    max = 100,
                                    step = 5
                                },
                                maxFrameRefresh = {
                                    order = 40,
                                    type = "range",
                                    name = L["Max Refresh"],
                                    desc = L["Minimum time (in milliseconds) between updates; lower values may reduce FPS."],
                                    min = 100,
                                    max = 400,
                                    step = 10
                                },
                                fullAuraScan = {
                                    order = 50,
                                    width = "full",
                                    type = "toggle",
                                    name = L["Full buffs/debuffs scan"],
                                    desc = L["Scans also buffs/debuffs casted by other players or NPCs.\n\nWarning!: Very CPU intensive"]
                                },
                                frequentHealthUpdates = {
                                    order = 60,
                                    width = "full",
                                    type = "toggle",
                                    name = L["Frequent health updates"],
                                    desc = L["Updates health of units more frquently; enabling this may reduce FPS."]
                                }
                            }
                        }
                    }
                },
                actions = {
                    name = "Actions",
                    type = "group",
                    args = {
                        show = {
                            type = "execute",
                            name = L["Afficher la fenêtre"],
                            guiHidden = true,
                            func = function()
                                self.db.profile.apparence.enableIcons = true
                                self.module:SendMessage("Ovale_OptionChanged", "visibility")
                            end
                        },
                        hide = {
                            type = "execute",
                            name = L["Cacher la fenêtre"],
                            guiHidden = true,
                            func = function()
                                self.db.profile.apparence.enableIcons = false
                                self.module:SendMessage("Ovale_OptionChanged", "visibility")
                            end
                        },
                        config = {
                            name = "Configuration",
                            type = "execute",
                            func = function()
                                self:ToggleConfig()
                            end
                        },
                        refresh = {
                            name = L["Display refresh statistics"],
                            type = "execute",
                            func = function()
                                local avgRefresh, minRefresh, maxRefresh, count = self.ovale:GetRefreshIntervalStatistics()
                                if minRefresh == huge then
                                    avgRefresh, minRefresh, maxRefresh, count = 0, 0, 0, 0
                                end
                                Print("Refresh intervals: count = %d, avg = %d, min = %d, max = %d (ms)", count, avgRefresh, minRefresh, maxRefresh)
                            end
                        }
                    }
                },
                profile = {}
            }
        }
        self.OnInitialize = function()
            local ovale = self.ovale:GetName()
            local db = AceDB:New("OvaleDB", self.defaultDB)
            self.options.args.profile = AceDBOptions:GetOptionsTable(db)
            db.RegisterCallback(self, "OnNewProfile", self.HandleProfileChanges)
            db.RegisterCallback(self, "OnProfileReset", self.HandleProfileChanges)
            db.RegisterCallback(self, "OnProfileChanged", self.HandleProfileChanges)
            db.RegisterCallback(self, "OnProfileCopied", self.HandleProfileChanges)
            self.db = db
            self:UpgradeSavedVariables()
            AceConfig:RegisterOptionsTable(ovale, self.options.args.apparence)
            AceConfig:RegisterOptionsTable(ovale .. " Profiles", self.options.args.profile)
            AceConfig:RegisterOptionsTable(ovale .. " Actions", self.options.args.actions, "Ovale")
            AceConfigDialog:AddToBlizOptions(ovale)
            AceConfigDialog:AddToBlizOptions(ovale .. " Profiles", "Profiles", ovale)
            self.HandleProfileChanges()
        end
        self.handleDisable = function()
        end
        self.HandleProfileChanges = function()
            self.module:SendMessage("Ovale_ProfileChanged")
            self.module:SendMessage("Ovale_ScriptChanged")
            self.module:SendMessage("Ovale_OptionChanged", "layout")
            self.module:SendMessage("Ovale_OptionChanged", "visibility")
        end
        self.module = ovale:createModule("OvaleOptions", self.OnInitialize, self.handleDisable, aceConsole, aceEvent)
    end,
    RegisterOptions = function(self, addon)
    end,
    UpgradeSavedVariables = function(self)
        for _, addon in ipairs(self_register) do
            if addon.UpgradeSavedVariables then
                addon:UpgradeSavedVariables()
            end
        end
        self.db.RegisterDefaults(self.defaultDB)
    end,
    ToggleConfig = function(self)
        local appName = self.ovale:GetName()
        if self.db.profile.standaloneOptions then
            if AceConfigDialog.OpenFrames[appName] then
                AceConfigDialog:Close(appName)
            else
                AceConfigDialog:Open(appName)
            end
        else
            InterfaceOptionsFrame_OpenToCategory(appName)
            InterfaceOptionsFrame_OpenToCategory(appName)
        end
    end,
})
