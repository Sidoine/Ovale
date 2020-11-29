local __exports = LibStub:NewLibrary("ovale/states/Health", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local wipe = wipe
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local huge = math.huge
local __toolstools = LibStub:GetLibrary("ovale/tools/tools")
local OneTimeMessage = __toolstools.OneTimeMessage
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
__exports.OvaleHealthClass = __class(nil, {
    constructor = function(self, ovaleGuid, ovale, ovaleOptions, ovaleDebug, ovaleProfiler)
        self.ovaleGuid = ovaleGuid
        self.ovaleOptions = ovaleOptions
        self.health = {}
        self.maxHealth = {}
        self.absorb = {}
        self.healAbsorb = {}
        self.totalDamage = {}
        self.totalHealing = {}
        self.firstSeen = {}
        self.lastUpdated = {}
        self.OnInitialize = function()
            self.module:RegisterEvent("PLAYER_REGEN_DISABLED", self.PLAYER_REGEN_DISABLED)
            self.module:RegisterEvent("PLAYER_REGEN_ENABLED", self.PLAYER_REGEN_ENABLED)
            if self.ovaleOptions.db.profile.apparence.frequentHealthUpdates then
                self.module:RegisterEvent("UNIT_HEALTH", self.UpdateHealth)
            else
                self.module:RegisterEvent("UNIT_HEALTH", self.UpdateHealth)
            end
            self.module:RegisterEvent("UNIT_MAXHEALTH", self.UpdateHealth)
            self.module:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", self.UpdateAbsorb)
            self.module:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", self.UpdateAbsorb)
            self.module:RegisterMessage("Ovale_UnitChanged", self.Ovale_UnitChanged)
        end
        self.OnDisable = function()
            self.module:UnregisterEvent("PLAYER_REGEN_ENABLED")
            self.module:UnregisterEvent("PLAYER_TARGET_CHANGED")
            self.module:UnregisterEvent("UNIT_HEALTH")
            self.module:UnregisterEvent("UNIT_HEALTH")
            self.module:UnregisterEvent("UNIT_MAXHEALTH")
            self.module:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
            self.module:UnregisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
            self.module:UnregisterMessage("Ovale_UnitChanged")
        end
        self.COMBAT_LOG_EVENT_UNFILTERED = function(event, ...)
            local timestamp, cleuEvent, _, _, _, _, _, destGUID, _, _, _, arg12, arg13, _, arg15 = CombatLogGetCurrentEventInfo()
            self.profiler:StartProfiling("OvaleHealth_COMBAT_LOG_EVENT_UNFILTERED")
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
                self.tracer:Debug(cleuEvent, destGUID, amount)
                local total = self.totalDamage[destGUID] or 0
                self.totalDamage[destGUID] = total + amount
                healthUpdate = true
            elseif CLEU_HEAL_EVENT[cleuEvent] then
                local amount = arg15
                self.tracer:Debug(cleuEvent, destGUID, amount)
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
            self.profiler:StopProfiling("OvaleHealth_COMBAT_LOG_EVENT_UNFILTERED")
        end
        self.PLAYER_REGEN_DISABLED = function(event)
            self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", self.COMBAT_LOG_EVENT_UNFILTERED)
        end
        self.PLAYER_REGEN_ENABLED = function(event)
            self.module:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            wipe(self.totalDamage)
            wipe(self.totalHealing)
            wipe(self.firstSeen)
            wipe(self.lastUpdated)
        end
        self.Ovale_UnitChanged = function(event, unitId, guid)
            self.profiler:StartProfiling("Ovale_UnitChanged")
            if unitId == "target" or unitId == "focus" then
                self.tracer:Debug(event, unitId, guid)
                self.UpdateHealth("UNIT_HEALTH", unitId)
                self.UpdateHealth("UNIT_MAXHEALTH", unitId)
                self.UpdateAbsorb("UNIT_ABSORB_AMOUNT_CHANGED", unitId)
                self.UpdateAbsorb("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unitId)
            end
            self.profiler:StopProfiling("Ovale_UnitChanged")
        end
        self.UpdateAbsorb = function(event, unitId)
            if  not unitId then
                return 
            end
            self.profiler:StartProfiling("OvaleHealth_UpdateAbsorb")
            local func
            local db
            if event == "UNIT_ABSORB_AMOUNT_CHANGED" then
                func = UnitGetTotalAbsorbs
                db = self.absorb
            elseif event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
                func = UnitGetTotalHealAbsorbs
                db = self.absorb
            else
                OneTimeMessage("Warning: Invalid event (%s) in UpdateAbsorb.", event)
                return 
            end
            local amount = func(unitId)
            if amount >= 0 then
                local guid = self.ovaleGuid:UnitGUID(unitId)
                self.tracer:Debug(event, unitId, guid, amount)
                if guid then
                    db[guid] = amount
                end
            end
            self.profiler:StopProfiling("OvaleHealth_UpdateHealth")
        end
        self.UpdateHealth = function(event, unitId)
            if  not unitId then
                return 
            end
            self.profiler:StartProfiling("OvaleHealth_UpdateHealth")
            local func
            local db
            if event == "UNIT_HEALTH" then
                func = UnitHealth
                db = self.health
            elseif event == "UNIT_MAXHEALTH" then
                func = UnitHealthMax
                db = self.maxHealth
            else
                OneTimeMessage("Warning: Invalid event (%s) in UpdateHealth.", event)
                return 
            end
            local amount = func(unitId)
            if amount then
                local guid = self.ovaleGuid:UnitGUID(unitId)
                self.tracer:Debug(event, unitId, guid, amount)
                if guid then
                    if amount > 0 then
                        db[guid] = amount
                    else
                        db[guid] = nil
                        self.firstSeen[guid] = nil
                        self.lastUpdated[guid] = nil
                    end
                end
            end
            self.profiler:StopProfiling("OvaleHealth_UpdateHealth")
        end
        self.module = ovale:createModule("OvaleHealth", self.OnInitialize, self.OnDisable, aceEvent)
        self.tracer = ovaleDebug:create(self.module:GetName())
        self.profiler = ovaleProfiler:create(self.module:GetName())
    end,
    UnitHealth = function(self, unitId, guid)
        return self:UnitAmount(UnitHealth, self.health, unitId, guid)
    end,
    UnitHealthMax = function(self, unitId, guid)
        return self:UnitAmount(UnitHealthMax, self.maxHealth, unitId, guid)
    end,
    UnitAbsorb = function(self, unitId, guid)
        return self:UnitAmount(UnitGetTotalAbsorbs, self.absorb, unitId, guid)
    end,
    UnitHealAbsorb = function(self, unitId, guid)
        return self:UnitAmount(UnitGetTotalHealAbsorbs, self.healAbsorb, unitId, guid)
    end,
    UnitAmount = function(self, func, db, unitId, guid)
        local amount
        if unitId then
            guid = guid or self.ovaleGuid:UnitGUID(unitId)
            if guid then
                if (unitId == "focus" or unitId == "target") and db[guid] ~= nil then
                    amount = db[guid]
                else
                    amount = func(unitId)
                    if amount ~= nil then
                        db[guid] = amount
                    else
                        amount = 0
                    end
                end
            else
                amount = 0
            end
        else
            amount = 0
        end
        return amount
    end,
    UnitTimeToDie = function(self, unitId, effectiveHealth, guid)
        self.profiler:StartProfiling("OvaleHealth_UnitTimeToDie")
        local timeToDie = INFINITY
        guid = guid or self.ovaleGuid:UnitGUID(unitId)
        if guid then
            local health = self:UnitHealth(unitId, guid) or 0
            if effectiveHealth then
                health = health + self:UnitAbsorb(unitId, guid) - self:UnitHealAbsorb(unitId, guid)
            end
            local maxHealth = self:UnitHealthMax(unitId, guid)
            if health and maxHealth > 0 then
                if health == 0 then
                    timeToDie = 0
                    self.firstSeen[guid] = nil
                    self.lastUpdated[guid] = nil
                elseif maxHealth > 5 then
                    local firstSeen, lastUpdated = self.firstSeen[guid], self.lastUpdated[guid]
                    local damage = self.totalDamage[guid] or 0
                    local healing = self.totalHealing[guid] or 0
                    if firstSeen and lastUpdated and lastUpdated > firstSeen and damage > healing then
                        timeToDie = (health * (lastUpdated - firstSeen)) / (damage - healing)
                    end
                end
            end
        end
        self.profiler:StopProfiling("OvaleHealth_UnitTimeToDie")
        return timeToDie
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
})
