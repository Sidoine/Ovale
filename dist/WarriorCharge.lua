local __exports = LibStub:NewLibrary("ovale/WarriorCharge", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local huge = math.huge
local OvaleWarriorChargeBase = OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleWarriorCharge", aceEvent))
local INFINITY = huge
local self_playerGUID = nil
local CHARGED = 100
local CHARGED_NAME = "Charged"
local CHARGED_DURATION = INFINITY
local CHARGED_ATTACKS = {
    [100] = GetSpellInfo(100)
}
local OvaleWarriorChargeClass = __class(OvaleWarriorChargeBase, {
    OnInitialize = function(self)
        if Ovale.playerClass == "WARRIOR" then
            self_playerGUID = Ovale.playerGUID
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    OnDisable = function(self)
        if Ovale.playerClass == "WARRIOR" then
            self:UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, arg13, _, _, _, _, _, _, _, _, _, _, _ = ...
        if sourceGUID == self_playerGUID and cleuEvent == "SPELL_CAST_SUCCESS" then
            local spellId, spellName = arg12, arg13
            if CHARGED_ATTACKS[spellId] and destGUID ~= self.targetGUID then
                self:Debug("Spell %d (%s) on new target %s.", spellId, spellName, destGUID)
                local now = GetTime()
                if self.targetGUID then
                    self:Debug("Removing Charged debuff on previous target %s.", self.targetGUID)
                    OvaleAura:LostAuraOnGUID(self.targetGUID, now, CHARGED, self_playerGUID)
                end
                self:Debug("Adding Charged debuff to %s.", destGUID)
                local duration = CHARGED_DURATION
                local ending = now + CHARGED_DURATION
                OvaleAura:GainedAuraOnGUID(destGUID, now, CHARGED, self_playerGUID, "HARMFUL", nil, nil, 1, nil, duration, ending, nil, CHARGED_NAME, nil, nil, nil)
                self.targetGUID = destGUID
            end
        end
    end,
    constructor = function(self, ...)
        OvaleWarriorChargeBase.constructor(self, ...)
        self.targetGUID = nil
    end
})
__exports.OvaleWarriorCharge = OvaleWarriorChargeClass()
