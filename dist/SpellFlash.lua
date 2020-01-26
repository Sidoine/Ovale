local __exports = LibStub:NewLibrary("ovale/SpellFlash", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local _G = _G
local GetTime = GetTime
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitExists = UnitExists
local UnitIsDead = UnitIsDead
local UnitCanAttack = UnitCanAttack
local SpellFlashCore = nil
local colorMain = {
    r = nil,
    g = nil,
    b = nil
}
local colorShortCd = {
    r = nil,
    g = nil,
    b = nil
}
local colorCd = {
    r = nil,
    g = nil,
    b = nil
}
local colorInterrupt = {
    r = nil,
    g = nil,
    b = nil
}
local FLASH_COLOR = {
    main = colorMain,
    cd = colorCd,
    shortcd = colorCd
}
local COLORTABLE = {
    aqua = {
        r = 0,
        g = 1,
        b = 1
    },
    blue = {
        r = 0,
        g = 0,
        b = 1
    },
    gray = {
        r = 0.5,
        g = 0.5,
        b = 0.5
    },
    green = {
        r = 0.1,
        g = 1,
        b = 0.1
    },
    orange = {
        r = 1,
        g = 0.5,
        b = 0.25
    },
    pink = {
        r = 0.9,
        g = 0.4,
        b = 0.4
    },
    purple = {
        r = 1,
        g = 0,
        b = 1
    },
    red = {
        r = 1,
        g = 0.1,
        b = 0.1
    },
    white = {
        r = 1,
        g = 1,
        b = 1
    },
    yellow = {
        r = 1,
        g = 1,
        b = 0
    }
}
__exports.OvaleSpellFlashClass = __class(nil, {
    constructor = function(self, ovaleOptions, ovale, ovaleFuture, ovaleData, ovaleSpellBook, ovaleStance)
        self.ovaleOptions = ovaleOptions
        self.ovaleFuture = ovaleFuture
        self.ovaleData = ovaleData
        self.ovaleSpellBook = ovaleSpellBook
        self.ovaleStance = ovaleStance
        self.OnInitialize = function()
            SpellFlashCore = _G["SpellFlashCore"]
            self.module:RegisterMessage("Ovale_OptionChanged", self.Ovale_OptionChanged)
            self.Ovale_OptionChanged()
        end
        self.OnDisable = function()
            SpellFlashCore = nil
            self.module:UnregisterMessage("Ovale_OptionChanged")
        end
        self.Ovale_OptionChanged = function()
            local db = self.ovaleOptions.db.profile.apparence.spellFlash
            colorMain.r = db.colorMain.r
            colorMain.g = db.colorMain.g
            colorMain.b = db.colorMain.b
            colorCd.r = db.colorCd.r
            colorCd.g = db.colorCd.g
            colorCd.b = db.colorCd.b
            colorShortCd.r = db.colorShortCd.r
            colorShortCd.g = db.colorShortCd.g
            colorShortCd.b = db.colorShortCd.b
            colorInterrupt.r = db.colorInterrupt.r
            colorInterrupt.g = db.colorInterrupt.g
            colorInterrupt.b = db.colorInterrupt.b
        end
        self.module = ovale:createModule("OvaleSpellFlash", self.OnInitialize, self.OnDisable, aceEvent)
        self.ovaleOptions.options.args.apparence.args.spellFlash = self:getSpellFlashOptions()
    end,
    getSpellFlashOptions = function(self)
        return {
            type = "group",
            name = "SpellFlash",
            disabled = function()
                return  not self:isEnabled()
            end,
            get = function(info)
                return self.ovaleOptions.db.profile.apparence.spellFlash[info[#info]]
            end,
            set = function(info, value)
                self.ovaleOptions.db.profile.apparence.spellFlash[info[#info]] = value
                self.module:SendMessage("Ovale_OptionChanged")
            end,
            args = {
                enabled = {
                    order = 10,
                    type = "toggle",
                    name = L["Enabled"],
                    desc = L["Flash spells on action bars when they are ready to be cast. Requires SpellFlashCore."],
                    width = "full"
                },
                inCombat = {
                    order = 10,
                    type = "toggle",
                    name = L["En combat uniquement"],
                    disabled = function()
                        return  not self:isEnabled() or  not self.ovaleOptions.db.profile.apparence.spellFlash.enabled
                    end
                },
                hasTarget = {
                    order = 20,
                    type = "toggle",
                    name = L["Si cible uniquement"],
                    disabled = function()
                        return  not self:isEnabled() or  not self.ovaleOptions.db.profile.apparence.spellFlash.enabled
                    end
                },
                hasHostileTarget = {
                    order = 30,
                    type = "toggle",
                    name = L["Cacher si cible amicale ou morte"],
                    disabled = function()
                        return  not self:isEnabled() or  not self.ovaleOptions.db.profile.apparence.spellFlash.enabled
                    end
                },
                hideInVehicle = {
                    order = 40,
                    type = "toggle",
                    name = L["Cacher dans les véhicules"],
                    disabled = function()
                        return  not self:isEnabled() or  not self.ovaleOptions.db.profile.apparence.spellFlash.enabled
                    end
                },
                brightness = {
                    order = 50,
                    type = "range",
                    name = L["Flash brightness"],
                    min = 0,
                    max = 1,
                    bigStep = 0.01,
                    isPercent = true,
                    disabled = function()
                        return  not self:isEnabled() or  not self.ovaleOptions.db.profile.apparence.spellFlash.enabled
                    end
                },
                size = {
                    order = 60,
                    type = "range",
                    name = L["Flash size"],
                    min = 0,
                    max = 3,
                    bigStep = 0.01,
                    isPercent = true,
                    disabled = function()
                        return  not self:isEnabled() or  not self.ovaleOptions.db.profile.apparence.spellFlash.enabled
                    end
                },
                threshold = {
                    order = 70,
                    type = "range",
                    name = L["Flash threshold"],
                    desc = L["Time (in milliseconds) to begin flashing the spell to use before it is ready."],
                    min = 0,
                    max = 1000,
                    step = 1,
                    bigStep = 50,
                    disabled = function()
                        return  not self:isEnabled() or  not self.ovaleOptions.db.profile.apparence.spellFlash.enabled
                    end
                },
                colors = {
                    order = 80,
                    type = "group",
                    name = L["Colors"],
                    inline = true,
                    disabled = function()
                        return  not self:isEnabled() or  not self.ovaleOptions.db.profile.apparence.spellFlash.enabled
                    end,
                    get = function(info)
                        local color = self.ovaleOptions.db.profile.apparence.spellFlash[info[#info]]
                        return color.r, color.g, color.b, 1
                    end,
                    set = function(info, r, g, b, a)
                        local color = self.ovaleOptions.db.profile.apparence.spellFlash[info[#info]]
                        color.r = r
                        color.g = g
                        color.b = b
                        self.module:SendMessage("Ovale_OptionChanged")
                    end,
                    args = {
                        colorMain = {
                            order = 10,
                            type = "color",
                            name = L["Main attack"],
                            hasAlpha = false
                        },
                        colorCd = {
                            order = 20,
                            type = "color",
                            name = L["Long cooldown abilities"],
                            hasAlpha = false
                        },
                        colorShortCd = {
                            order = 30,
                            type = "color",
                            name = L["Short cooldown abilities"],
                            hasAlpha = false
                        },
                        colorInterrupt = {
                            order = 40,
                            type = "color",
                            name = L["Interrupts"],
                            hasAlpha = false
                        }
                    }
                }
            }
        }
    end,
    isEnabled = function(self)
        return SpellFlashCore ~= nil
    end,
    IsSpellFlashEnabled = function(self)
        local enabled = (SpellFlashCore ~= nil)
        local db = self.ovaleOptions.db.profile.apparence.spellFlash
        if enabled and  not db.enabled then
            enabled = false
        end
        if enabled and db.inCombat and  not self.ovaleFuture:IsInCombat(nil) then
            enabled = false
        end
        if enabled and db.hideInVehicle and UnitHasVehicleUI("player") then
            enabled = false
        end
        if enabled and db.hasTarget and  not UnitExists("target") then
            enabled = false
        end
        if enabled and db.hasHostileTarget and (UnitIsDead("target") or  not UnitCanAttack("player", "target")) then
            enabled = false
        end
        return enabled
    end,
    Flash = function(self, node, element, start, now)
        local db = self.ovaleOptions.db.profile.apparence.spellFlash
        now = now or GetTime()
        if self:IsSpellFlashEnabled() and start and start - now <= db.threshold / 1000 then
            if element and element.type == "action" then
                local spellId, spellInfo
                if element.name == "spell" then
                    spellId = element.positionalParams[1]
                    spellInfo = self.ovaleData.spellInfo[spellId]
                end
                local interrupt = spellInfo and spellInfo.interrupt
                local color = nil
                local flash = element.namedParams and element.namedParams.flash
                local iconFlash = node.namedParams.flash
                local iconHelp = node.namedParams.help
                if flash and COLORTABLE[flash] then
                    color = COLORTABLE[flash]
                elseif iconFlash and COLORTABLE[iconFlash] then
                    color = COLORTABLE[iconFlash]
                elseif iconHelp and FLASH_COLOR[iconHelp] then
                    color = FLASH_COLOR[iconHelp]
                    if interrupt == 1 and iconHelp == "cd" then
                        color = colorInterrupt
                    end
                end
                local size = db.size * 100
                if iconHelp == "cd" then
                    if interrupt ~= 1 then
                        size = size * 0.5
                    end
                end
                local brightness = db.brightness * 100
                if SpellFlashCore then
                    if element.name == "spell" and spellId then
                        if self.ovaleStance:IsStanceSpell(spellId) then
                            SpellFlashCore.FlashForm(spellId, color, size, brightness)
                        end
                        if self.ovaleSpellBook:IsPetSpell(spellId) then
                            SpellFlashCore.FlashPet(spellId, color, size, brightness)
                        end
                        SpellFlashCore.FlashAction(spellId, color, size, brightness)
                    elseif element.name == "item" then
                        local itemId = element.positionalParams[1]
                        SpellFlashCore.FlashItem(itemId, color, size, brightness)
                    end
                end
            end
        end
    end,
})
