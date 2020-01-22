local __exports = LibStub:NewLibrary("ovale/DemonHunterSoulFragments", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local GetTime = GetTime
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local SOUL_FRAGMENTS_BUFF_ID = 203981
local SOUL_FRAGMENT_SPELLS = {
    [225919] = 2,
    [203782] = 1,
    [228477] = -2
}
local SOUL_FRAGMENT_FINISHERS = {
    [247454] = true,
    [263648] = true
}
__exports.OvaleDemonHunterSoulFragmentsClass = __class(nil, {
    constructor = function(self, ovaleAura, ovale)
        self.ovaleAura = ovaleAura
        self.ovale = ovale
        self.estimatedCount = 0
        self.OnInitialize = function()
            if self.ovale.playerClass == "DEMONHUNTER" then
                self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", self.COMBAT_LOG_EVENT_UNFILTERED)
            end
        end
        self.OnDisable = function()
            if self.ovale.playerClass == "DEMONHUNTER" then
                self.module:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            end
        end
        self.COMBAT_LOG_EVENT_UNFILTERED = function(event, ...)
            local _, subtype, _, sourceGUID, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
            local me = self.ovale.playerGUID
            if sourceGUID == me then
                if subtype == "SPELL_CAST_SUCCESS" and SOUL_FRAGMENT_SPELLS[spellID] then
                    self:AddPredictedSoulFragments(GetTime(), SOUL_FRAGMENT_SPELLS[spellID])
                end
                if subtype == "SPELL_CAST_SUCCESS" and SOUL_FRAGMENT_FINISHERS[spellID] then
                    self:SetPredictedSoulFragment(GetTime(), 0)
                end
            end
        end
        self.module = ovale:createModule("OvaleDemonHunterSoulFragments", self.OnInitialize, self.OnDisable, aceEvent)
    end,
    AddPredictedSoulFragments = function(self, atTime, added)
        local currentCount = self:GetSoulFragmentsBuffStacks(atTime) or 0
        self:SetPredictedSoulFragment(atTime, currentCount + added)
    end,
    SetPredictedSoulFragment = function(self, atTime, count)
        self.estimatedCount = (count < 0 and 0) or (count > 5 and 5) or count
        self.atTime = atTime
        self.estimated = true
    end,
    SoulFragments = function(self, atTime)
        local stacks = self:GetSoulFragmentsBuffStacks(atTime)
        if self.estimated then
            if atTime - (self.atTime or 0) < 1.2 then
                stacks = self.estimatedCount
            else
                self.estimated = false
            end
        end
        return stacks
    end,
    GetSoulFragmentsBuffStacks = function(self, atTime)
        local aura = self.ovaleAura:GetAura("player", SOUL_FRAGMENTS_BUFF_ID, atTime, "HELPFUL", true)
        local stacks = aura and self.ovaleAura:IsActiveAura(aura, atTime) and aura.stacks or 0
        return stacks
    end,
})
