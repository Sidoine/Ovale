local __exports = LibStub:NewLibrary("ovale/HonorAmongThieves", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local GetTime = GetTime
local OvaleHonorAmongThievesBase = Ovale:NewModule("OvaleHonorAmongThieves", aceEvent)
local self_playerGUID = nil
local HONOR_AMONG_THIEVES = 51699
local MEAN_TIME_TO_HAT = 2.2
local OvaleHonorAmongThievesClass = __class(OvaleHonorAmongThievesBase, {
    OnInitialize = function(self)
        if Ovale.playerClass == "ROGUE" then
            self_playerGUID = Ovale.playerGUID
            self:RegisterMessage("Ovale_SpecializationChanged")
        end
    end,
    OnDisable = function(self)
        if Ovale.playerClass == "ROGUE" then
            self:UnregisterMessage("Ovale_SpecializationChanged")
        end
    end,
    Ovale_SpecializationChanged = function(self, event, specialization, previousSpecialization)
        if specialization == "subtlety" then
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        else
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, _, _, _, arg16, _, _, _, _, _, _, _, _ = ...
        if sourceGUID == self_playerGUID and destGUID == self_playerGUID and cleuEvent == "SPELL_ENERGIZE" then
            local spellId, powerType = arg12, arg16
            if spellId == HONOR_AMONG_THIEVES and powerType == 4 then
                local now = GetTime()
                self.start = now
                local duration = OvaleData:GetSpellInfoProperty(HONOR_AMONG_THIEVES, now, "duration", destGUID) or MEAN_TIME_TO_HAT
                self.duration = duration
                self.ending = self.start + duration
                self.stacks = 1
                OvaleAura:GainedAuraOnGUID(self_playerGUID, self.start, self.spellId, self_playerGUID, "HELPFUL", nil, nil, self.stacks, nil, self.duration, self.ending, nil, self.spellName, nil, nil, nil)
            end
        end
    end,
    constructor = function(self, ...)
        OvaleHonorAmongThievesBase.constructor(self, ...)
        self.spellName = "Honor Among Thieves Cooldown"
        self.spellId = HONOR_AMONG_THIEVES
        self.start = 0
        self.ending = 0
        self.duration = MEAN_TIME_TO_HAT
        self.stacks = 0
    end
})
__exports.OvaleHonorAmongThieves = OvaleHonorAmongThievesClass()
