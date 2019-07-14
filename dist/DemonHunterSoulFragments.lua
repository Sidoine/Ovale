local __exports = LibStub:NewLibrary("ovale/DemonHunterSoulFragments", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local GetTime = GetTime
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local OvaleDemonHunterSoulFragmentsBase = OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleDemonHunterSoulFragments", aceEvent))
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
local OvaleDemonHunterSoulFragmentsClass = __class(OvaleDemonHunterSoulFragmentsBase, {
    constructor = function(self)
        OvaleDemonHunterSoulFragmentsBase.constructor(self)
    end,
    OnInitialize = function(self)
        if Ovale.playerClass == "DEMONHUNTER" then
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    OnDisable = function(self)
        if Ovale.playerClass == "DEMONHUNTER" then
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, ...)
        local _, subtype, _, sourceGUID, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
        local me = Ovale.playerGUID
        if sourceGUID == me then
            if subtype == "SPELL_CAST_SUCCESS" and SOUL_FRAGMENT_SPELLS[spellID] then
                self:AddPredictedSoulFragments(GetTime(), SOUL_FRAGMENT_SPELLS[spellID])
            end
            if subtype == "SPELL_CAST_SUCCESS" and SOUL_FRAGMENT_FINISHERS[spellID] then
                self:SetPredictedSoulFragment(GetTime(), 0)
            end
        end
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
        local aura = OvaleAura:GetAura("player", SOUL_FRAGMENTS_BUFF_ID, atTime, "HELPFUL", true)
        local stacks = OvaleAura:IsActiveAura(aura, atTime) and aura.stacks or 0
        return stacks
    end,
})
local DemonHunterSoulFragmentsState = __class(nil, {
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
})
__exports.OvaleDemonHunterSoulFragments = OvaleDemonHunterSoulFragmentsClass()
__exports.demonHunterSoulFragmentsState = DemonHunterSoulFragmentsState()
OvaleState:RegisterState(__exports.demonHunterSoulFragmentsState)
