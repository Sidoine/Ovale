local __exports = LibStub:NewLibrary("ovale/ShadowWordDeath", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local GetTime = GetTime
local OvaleShadowWordDeathBase = Ovale:NewModule("OvaleShadowWordDeath", aceEvent)
local self_playerGUID = nil
local SHADOW_WORD_DEATH = {
    [32379] = true,
    [129176] = true
}
local OvaleShadowWordDeathClass = __class(OvaleShadowWordDeathBase, {
    OnInitialize = function(self)
        if Ovale.playerClass == "PRIEST" then
            self_playerGUID = Ovale.playerGUID
            self:RegisterMessage("Ovale_SpecializationChanged")
        end
    end,
    OnDisable = function(self)
        if Ovale.playerClass == "PRIEST" then
            self:UnregisterMessage("Ovale_SpecializationChanged")
        end
    end,
    Ovale_SpecializationChanged = function(self, event, specialization, previousSpecialization)
        if specialization == "shadow" then
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        else
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, _, _, _, arg16 = ...
        if sourceGUID == self_playerGUID then
            if cleuEvent == "SPELL_DAMAGE" then
                local spellId, overkill = arg12, arg16
                if SHADOW_WORD_DEATH[spellId] and  not (overkill and overkill > 0) then
                    local now = GetTime()
                    self.start = now
                    self.ending = now + self.duration
                    self.stacks = 1
                    OvaleAura:GainedAuraOnGUID(self_playerGUID, self.start, self.spellId, self_playerGUID, "HELPFUL", nil, nil, self.stacks, nil, self.duration, self.ending, nil, self.spellName, nil, nil, nil)
                end
            end
        end
    end,
    constructor = function(self, ...)
        OvaleShadowWordDeathBase.constructor(self, ...)
        self.spellName = "Shadow Word: Death Reset Cooldown"
        self.spellId = 125927
        self.start = 0
        self.ending = 0
        self.duration = 9
        self.stacks = 0
    end
})
__exports.OvaleShadowWordDeath = OvaleShadowWordDeathClass()
