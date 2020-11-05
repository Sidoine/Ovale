local __exports = LibStub:NewLibrary("ovale/states/Stagger", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitStagger = UnitStagger
local pairs = pairs
local insert = table.insert
local remove = table.remove
local __Condition = LibStub:GetLibrary("ovale/Condition")
local Compare = __Condition.Compare
local ParseCondition = __Condition.ParseCondition
local ReturnValueBetween = __Condition.ReturnValueBetween
local __tools = LibStub:GetLibrary("ovale/tools")
local isNumber = __tools.isNumber
local LIGHT_STAGGER = 124275
local MODERATE_STAGGER = 124274
local HEAVY_STAGGER = 124273
local self_serial = 1
local MAX_LENGTH = 30
__exports.OvaleStaggerClass = __class(nil, {
    constructor = function(self, ovale, combat, baseState, aura, health)
        self.ovale = ovale
        self.combat = combat
        self.baseState = baseState
        self.aura = aura
        self.health = health
        self.staggerTicks = {}
        self.OnInitialize = function()
            if self.ovale.playerClass == "MONK" then
                self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", self.COMBAT_LOG_EVENT_UNFILTERED)
            end
        end
        self.OnDisable = function()
            if self.ovale.playerClass == "MONK" then
                self.module:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            end
        end
        self.COMBAT_LOG_EVENT_UNFILTERED = function(event, ...)
            local _, cleuEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, _, _, amount = CombatLogGetCurrentEventInfo()
            if sourceGUID ~= self.ovale.playerGUID then
                return 
            end
            self_serial = self_serial + 1
            if cleuEvent == "SPELL_PERIODIC_DAMAGE" and spellId == 124255 then
                insert(self.staggerTicks, amount)
                if #self.staggerTicks > MAX_LENGTH then
                    remove(self.staggerTicks, 1)
                end
            end
        end
        self.StaggerRemaining = function(positionalParams, namedParams, atTime)
            local target = ParseCondition(namedParams, self.baseState)
            return self:getAnyStaggerAura(target, atTime)
        end
        self.staggerPercent = function(positionalparameters, namedParams, atTime)
            local target = ParseCondition(namedParams, self.baseState)
            local start, end, value, origin, rate = self:getAnyStaggerAura(target, atTime)
            local healthMax = self.health:UnitHealthMax(target)
            if value ~= nil and isNumber(value) then
                value = (value * 100) / healthMax
            end
            if rate ~= nil then
                rate = (rate * 100) / healthMax
            end
            return start, end, value, origin, rate
        end
        self.missingStaggerPercent = function(positionalparameters, namedParams, atTime)
            local target = ParseCondition(namedParams, self.baseState)
            local start, end, value, origin, rate = self:getAnyStaggerAura(target, atTime)
            local healthMax = self.health:UnitHealthMax(target)
            if value ~= nil and isNumber(value) then
                value = ((healthMax - value) * 100) / healthMax
            end
            if rate ~= nil then
                rate = -(rate * 100) / healthMax
            end
            return start, end, value, origin, rate
        end
        self.StaggerTick = function(positionalParams, namedParams, atTime)
            local count, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[2]
            local damage = self:LastTickDamage(count)
            return Compare(damage, comparator, limit)
        end
        self.module = ovale:createModule("OvaleStagger", self.OnInitialize, self.OnDisable, aceEvent)
    end,
    registerConditions = function(self, ovaleCondition)
        ovaleCondition:RegisterCondition("staggerremaining", false, self.StaggerRemaining)
        ovaleCondition:RegisterCondition("staggerremains", false, self.StaggerRemaining)
        ovaleCondition:RegisterCondition("staggertick", false, self.StaggerTick)
        ovaleCondition:RegisterCondition("staggerpercent", false, self.staggerPercent)
        ovaleCondition:RegisterCondition("staggermissingpercent", false, self.missingStaggerPercent)
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
        if  not self.combat:isInCombat(nil) then
            for k in pairs(self.staggerTicks) do
                self.staggerTicks[k] = nil
            end
        end
    end,
    LastTickDamage = function(self, countTicks)
        if  not countTicks or countTicks == 0 or countTicks < 0 then
            countTicks = 1
        end
        local damage = 0
        local arrLen = #self.staggerTicks
        if arrLen < 1 then
            return 0
        end
        for i = arrLen, arrLen - (countTicks - 1), -1 do
            damage = damage + (self.staggerTicks[i] or 0)
        end
        return damage
    end,
    getAnyStaggerAura = function(self, target, atTime)
        local aura = self.aura:GetAura(target, HEAVY_STAGGER, atTime, "HARMFUL")
        if  not aura or  not self.aura:IsActiveAura(aura, atTime) then
            aura = self.aura:GetAura(target, MODERATE_STAGGER, atTime, "HARMFUL")
        end
        if  not aura or  not self.aura:IsActiveAura(aura, atTime) then
            aura = self.aura:GetAura(target, LIGHT_STAGGER, atTime, "HARMFUL")
        end
        if aura and self.aura:IsActiveAura(aura, atTime) then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            local stagger = UnitStagger(target)
            local rate = (-1 * stagger) / (ending - start)
            return ReturnValueBetween(gain, ending, 0, ending, rate)
        end
        return 
    end,
})
