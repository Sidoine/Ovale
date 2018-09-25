local __exports = LibStub:NewLibrary("ovale/DemonHunterSoulFragments", 80000)
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
local SOUL_FRAGMENT_BUILDERS = {
    [225919] = 2,
    [203782] = 1
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
            if subtype == "SPELL_CAST_SUCCESS" and SOUL_FRAGMENT_BUILDERS[spellID] then
                self:AddPredictedSoulFragments(GetTime(), SOUL_FRAGMENT_BUILDERS[spellID])
            end
        end
    end,
    AddPredictedSoulFragments = function(self, atTime, added)
        local currentCount = self:GetSoulFragmentsBuffStacks(atTime) or 0
        self.estimatedCount = currentCount + added
        self.atTime = atTime
        self.estimated = true
    end,
    SoulFragments = function(self, atTime)
        local stacks = self:GetSoulFragmentsBuffStacks(atTime)
        if self.estimated then
            if atTime - (self.atTime or 0) < 1.2 then
                if (self.estimatedCount or 0) > stacks then
                    stacks = self.estimatedCount
                end
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
