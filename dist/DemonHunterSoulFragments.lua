local __exports = LibStub:NewLibrary("ovale/DemonHunterSoulFragments", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local insert = table.insert
local GetTime = GetTime
local GetSpellCount = GetSpellCount
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local type = type
local pairs = pairs
local OvaleDemonHunterSoulFragmentsBase = OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleDemonHunterSoulFragments", aceEvent))
local SOUL_FRAGMENTS_BUFF_ID = 228477
local SOUL_FRAGMENTS_SPELL_HEAL_ID = 203794
local SOUL_FRAGMENTS_SPELL_CAST_SUCCESS_ID = 204255
local SOUL_FRAGMENT_FINISHERS = {
    [228477] = true,
    [247454] = true,
    [227225] = true
}
local OvaleDemonHunterSoulFragmentsClass = __class(OvaleDemonHunterSoulFragmentsBase, {
    constructor = function(self)
        OvaleDemonHunterSoulFragmentsBase.constructor(self)
        self:SetCurrentSoulFragments(0)
    end,
    OnInitialize = function(self)
        if Ovale.playerClass == "DEMONHUNTER" then
            self:RegisterEvent("PLAYER_REGEN_ENABLED")
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self:RegisterEvent("PLAYER_REGEN_DISABLED")
        end
    end,
    OnDisable = function(self)
        if Ovale.playerClass == "DEMONHUNTER" then
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            self:UnregisterEvent("PLAYER_REGEN_DISABLED")
        end
    end,
    PLAYER_REGEN_ENABLED = function(self)
        self:SetCurrentSoulFragments()
    end,
    PLAYER_REGEN_DISABLED = function(self)
        self.soul_fragments = {}
        self.last_checked = nil
        self:SetCurrentSoulFragments()
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, ...)
        local _, subtype, _, sourceGUID, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
        local me = Ovale.playerGUID
        if sourceGUID == me then
            if subtype == "SPELL_HEAL" and spellID == SOUL_FRAGMENTS_SPELL_HEAL_ID then
                self:SetCurrentSoulFragments(self.last_soul_fragment_count.fragments - 1)
            end
            if subtype == "SPELL_CAST_SUCCESS" and spellID == SOUL_FRAGMENTS_SPELL_CAST_SUCCESS_ID then
                self:SetCurrentSoulFragments(self.last_soul_fragment_count.fragments + 1)
            end
            if subtype == "SPELL_CAST_SUCCESS" and SOUL_FRAGMENT_FINISHERS[spellID] then
                self:SetCurrentSoulFragments(0)
            end
            local now = GetTime()
            if self.last_checked == nil or now - self.last_checked >= 1.5 then
                self:SetCurrentSoulFragments()
            end
        end
    end,
    SetCurrentSoulFragments = function(self, count)
        local now = GetTime()
        self.last_checked = now
        self.soul_fragments = self.soul_fragments or {}
        if type(count) ~= "number" then
            count = GetSpellCount(SOUL_FRAGMENTS_BUFF_ID) or 0
        end
        if count < 0 then
            count = 0
        end
        if self.last_soul_fragment_count == nil or self.last_soul_fragment_count.fragments ~= count then
            local entry = {
                timestamp = now,
                fragments = count
            }
            self.last_soul_fragment_count = entry
            insert(self.soul_fragments, entry)
        end
    end,
    DebugSoulFragments = function(self)
    end,
    SoulFragments = function(self, atTime)
        local currentTime = nil
        local count = nil
        for _, v in pairs(self.soul_fragments) do
            if v.timestamp >= atTime and (currentTime == nil or v.timestamp < currentTime) then
                currentTime = v.timestamp
                count = v.fragments
            end
        end
        if count then
            return count
        end
        return (self.last_soul_fragment_count ~= nil and self.last_soul_fragment_count.fragments) or 0
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
