local __exports = LibStub:NewLibrary("ovale/Health", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __GUID = LibStub:GetLibrary("ovale/GUID")
local OvaleGUID = __GUID.OvaleGUID
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __Requirement = LibStub:GetLibrary("ovale/Requirement")
local RegisterRequirement = __Requirement.RegisterRequirement
local UnregisterRequirement = __Requirement.UnregisterRequirement
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local sub = string.sub
local tonumber = tonumber
local wipe = wipe
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local huge = math.huge
local __BaseState = LibStub:GetLibrary("ovale/BaseState")
local baseState = __BaseState.baseState
local OvaleHealthBase = Ovale:NewModule("OvaleHealth", aceEvent)
local INFINITY = huge
local CLEU_DAMAGE_EVENT = {
    DAMAGE_SHIELD = true,
    DAMAGE_SPLIT = true,
    RANGE_DAMAGE = true,
    SPELL_BUILDING_DAMAGE = true,
    SPELL_DAMAGE = true,
    SPELL_PERIODIC_DAMAGE = true,
    SWING_DAMAGE = true,
    ENVIRONMENTAL_DAMAGE = true
}
local CLEU_HEAL_EVENT = {
    SPELL_HEAL = true,
    SPELL_PERIODIC_HEAL = true
}
local OvaleHealthClassBase = OvaleDebug:RegisterDebugging(OvaleProfiler:RegisterProfiling(OvaleHealthBase))
local OvaleHealthClass = __class(OvaleHealthClassBase, {
    OnInitialize = function(self)
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("UNIT_HEALTH_FREQUENT", "UpdateHealth")
        self:RegisterEvent("UNIT_MAXHEALTH", "UpdateHealth")
        self:RegisterMessage("Ovale_UnitChanged")
        RegisterRequirement("health_pct", self.RequireHealthPercentHandler)
        RegisterRequirement("pet_health_pct", self.RequireHealthPercentHandler)
        RegisterRequirement("target_health_pct", self.RequireHealthPercentHandler)
    end,
    OnDisable = function(self)
        UnregisterRequirement("health_pct")
        UnregisterRequirement("pet_health_pct")
        UnregisterRequirement("target_health_pct")
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        self:UnregisterEvent("UNIT_HEALTH_FREQUENT")
        self:UnregisterEvent("UNIT_MAXHEALTH")
        self:UnregisterMessage("Ovale_UnitChanged")
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, ...)
        local timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, arg12, arg13, _, arg15, _, _, _, _, _, _, _, _, _ = CombatLogGetCurrentEventInfo()
        self:StartProfiling("OvaleHealth_COMBAT_LOG_EVENT_UNFILTERED")
        local healthUpdate = false
        if CLEU_DAMAGE_EVENT[cleuEvent] then
            local amount
            if cleuEvent == "SWING_DAMAGE" then
                amount = arg12
            elseif cleuEvent == "ENVIRONMENTAL_DAMAGE" then
                amount = arg13
            else
                amount = arg15
            end
            self:Debug(cleuEvent, destGUID, amount)
            local total = self.totalDamage[destGUID] or 0
            self.totalDamage[destGUID] = total + amount
            healthUpdate = true
        elseif CLEU_HEAL_EVENT[cleuEvent] then
            local amount = arg15
            self:Debug(cleuEvent, destGUID, amount)
            local total = self.totalHealing[destGUID] or 0
            self.totalHealing[destGUID] = total + amount
            healthUpdate = true
        end
        if healthUpdate then
            if  not self.firstSeen[destGUID] then
                self.firstSeen[destGUID] = timestamp
            end
            self.lastUpdated[destGUID] = timestamp
        end
        self:StopProfiling("OvaleHealth_COMBAT_LOG_EVENT_UNFILTERED")
    end,
    PLAYER_REGEN_DISABLED = function(self, event)
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end,
    PLAYER_REGEN_ENABLED = function(self, event)
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        wipe(self.totalDamage)
        wipe(self.totalHealing)
        wipe(self.firstSeen)
        wipe(self.lastUpdated)
    end,
    Ovale_UnitChanged = function(self, event, unitId, guid)
        self:StartProfiling("Ovale_UnitChanged")
        if unitId == "target" or unitId == "focus" then
            self:Debug(event, unitId, guid)
            self:UpdateHealth("UNIT_HEALTH_FREQUENT", unitId)
            self:UpdateHealth("UNIT_MAXHEALTH", unitId)
            self:StopProfiling("Ovale_UnitChanged")
        end
    end,
    UpdateHealth = function(self, event, unitId)
        if  not unitId then
            return 
        end
        self:StartProfiling("OvaleHealth_UpdateHealth")
        local func = UnitHealth
        local db = self.health
        if event == "UNIT_MAXHEALTH" then
            func = UnitHealthMax
            db = self.maxHealth
        end
        local amount = func(unitId)
        if amount then
            local guid = OvaleGUID:UnitGUID(unitId)
            self:Debug(event, unitId, guid, amount)
            if guid then
                if amount > 0 then
                    db[guid] = amount
                else
                    db[guid] = nil
                    self.firstSeen[guid] = nil
                    self.lastUpdated[guid] = nil
                end
                Ovale.refreshNeeded[guid] = true
            end
        end
        self:StopProfiling("OvaleHealth_UpdateHealth")
    end,
    UnitHealth = function(self, unitId, guid)
        local amount
        if unitId then
            guid = guid or OvaleGUID:UnitGUID(unitId)
            if guid then
                if unitId == "target" or unitId == "focus" then
                    amount = self.health[guid] or 0
                else
                    amount = UnitHealth(unitId)
                    self.health[guid] = amount
                end
            else
                amount = 0
            end
        end
        return amount
    end,
    UnitHealthMax = function(self, unitId, guid)
        local amount
        if unitId then
            guid = guid or OvaleGUID:UnitGUID(unitId)
            if guid then
                if unitId == "target" or unitId == "focus" then
                    amount = self.maxHealth[guid] or 0
                else
                    amount = UnitHealthMax(unitId)
                    self.maxHealth[guid] = amount
                end
            else
                amount = 0
            end
        end
        return amount
    end,
    UnitTimeToDie = function(self, unitId, guid)
        self:StartProfiling("OvaleHealth_UnitTimeToDie")
        local timeToDie = INFINITY
        guid = guid or OvaleGUID:UnitGUID(unitId)
        if guid then
            local health = self:UnitHealth(unitId, guid)
            local maxHealth = self:UnitHealthMax(unitId, guid)
            if health and maxHealth then
                if health == 0 then
                    timeToDie = 0
                    self.firstSeen[guid] = nil
                    self.lastUpdated[guid] = nil
                elseif maxHealth > 5 then
                    local firstSeen, lastUpdated = self.firstSeen[guid], self.lastUpdated[guid]
                    local damage = self.totalDamage[guid] or 0
                    local healing = self.totalHealing[guid] or 0
                    if firstSeen and lastUpdated and lastUpdated > firstSeen and damage > healing then
                        timeToDie = health * (lastUpdated - firstSeen) / (damage - healing)
                    end
                end
            end
        end
        self:StopProfiling("OvaleHealth_UnitTimeToDie")
        return timeToDie
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    constructor = function(self, ...)
        OvaleHealthClassBase.constructor(self, ...)
        self.health = {}
        self.maxHealth = {}
        self.totalDamage = {}
        self.totalHealing = {}
        self.firstSeen = {}
        self.lastUpdated = {}
        self.RequireHealthPercentHandler = function(spellId, atTime, requirement, tokens, index, targetGUID)
            local verified = false
            local threshold = tokens
            if index then
                threshold = tokens[index]
                index = index + 1
            end
            if threshold then
                local isBang = false
                if sub(threshold, 1, 1) == "!" then
                    isBang = true
                    threshold = sub(threshold, 2)
                end
                threshold = tonumber(threshold) or 0
                local guid, unitId
                if sub(requirement, 1, 7) == "target_" then
                    if targetGUID then
                        guid = targetGUID
                        unitId = OvaleGUID:GUIDUnit(guid)
                    else
                        unitId = baseState.next.defaultTarget or "target"
                    end
                elseif sub(requirement, 1, 4) == "pet_" then
                    unitId = "pet"
                else
                    unitId = "player"
                end
                guid = guid or OvaleGUID:UnitGUID(unitId)
                local health = __exports.OvaleHealth:UnitHealth(unitId, guid) or 0
                local maxHealth = __exports.OvaleHealth:UnitHealthMax(unitId, guid) or 0
                local healthPercent = (maxHealth > 0) and (health / maxHealth * 100) or 100
                if  not isBang and healthPercent <= threshold or isBang and healthPercent > threshold then
                    verified = true
                end
                local result = verified and "passed" or "FAILED"
                if isBang then
                    self:Log("    Require %s health > %f%% (%f) at time=%f: %s", unitId, threshold, healthPercent, atTime, result)
                else
                    self:Log("    Require %s health <= %f%% (%f) at time=%f: %s", unitId, threshold, healthPercent, atTime, result)
                end
            else
                Ovale:OneTimeMessage("Warning: requirement '%s' is missing a threshold argument.", requirement)
            end
            return verified, requirement, index
        end
    end
})
__exports.OvaleHealth = OvaleHealthClass()
OvaleState:RegisterState(__exports.OvaleHealth)
