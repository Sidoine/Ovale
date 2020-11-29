local __exports = LibStub:NewLibrary("ovale/states/Variables", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local pairs = pairs
local wipe = wipe
local __engineCondition = LibStub:GetLibrary("ovale/engine/Condition")
local Compare = __engineCondition.Compare
local huge = math.huge
local __engineAST = LibStub:GetLibrary("ovale/engine/AST")
local setResultType = __engineAST.setResultType
__exports.Variables = __class(nil, {
    constructor = function(self, combat, baseState, ovaleDebug)
        self.combat = combat
        self.baseState = baseState
        self.isState = true
        self.isInitialized = false
        self.futureVariable = {}
        self.futureLastEnable = {}
        self.variable = {}
        self.lastEnable = {}
        self.getState = function(positionalParams, namedParams, atTime)
            local name, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self:GetState(name)
            return Compare(value, comparator, limit)
        end
        self.getStateDuration = function(positionalParams, namedParams, atTime)
            local name, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self:GetStateDuration(name)
            return Compare(value, comparator, limit)
        end
        self.setState = function(positionalParams, namedParams, atTime, result)
            local name = positionalParams[1]
            local value = positionalParams[2]
            local currentValue = self:GetState(name)
            if currentValue ~= value then
                setResultType(result, "state")
                result.value = value
                result.name = name
                result.timeSpan:Copy(0, huge)
            else
                wipe(result.timeSpan)
            end
        end
        self.tracer = ovaleDebug:create("Variables")
    end,
    registerConditions = function(self, condition)
        condition:RegisterCondition("getstate", false, self.getState)
        condition:registerAction("setstate", self.setState)
        condition:RegisterCondition("getstateduration", false, self.getStateDuration)
    end,
    InitializeState = function(self)
        if  not self.combat:isInCombat(nil) then
            for k in pairs(self.variable) do
                self.tracer:Log("Resetting state variable '%s'.", k)
                self.variable[k] = nil
                self.lastEnable[k] = nil
            end
        end
    end,
    ResetState = function(self)
        for k in pairs(self.futureVariable) do
            self.futureVariable[k] = nil
            self.futureLastEnable[k] = nil
        end
    end,
    CleanState = function(self)
        for k in pairs(self.futureVariable) do
            self.futureVariable[k] = nil
        end
        for k in pairs(self.futureLastEnable) do
            self.futureLastEnable[k] = nil
        end
        for k in pairs(self.variable) do
            self.variable[k] = nil
        end
        for k in pairs(self.lastEnable) do
            self.lastEnable[k] = nil
        end
    end,
    GetState = function(self, name)
        return self.futureVariable[name] or self.variable[name] or 0
    end,
    GetStateDuration = function(self, name)
        local lastEnable = self.futureLastEnable[name] or self.lastEnable[name] or self.baseState.next.currentTime
        return self.baseState.next.currentTime - lastEnable
    end,
    PutState = function(self, name, value, isFuture, atTime)
        if isFuture then
            local oldValue = self:GetState(name)
            if value ~= oldValue then
                self.tracer:Log("Setting future state: %s from %s to %s.", name, oldValue, value)
                self.futureVariable[name] = value
                self.futureLastEnable[name] = atTime
            end
        else
            local oldValue = self.variable[name] or 0
            if value ~= oldValue then
                self.tracer:DebugTimestamp("Advancing combat state: %s from %s to %s.", name, oldValue, value)
                self.tracer:Log("Advancing combat state: %s from %s to %s.", name, oldValue, value)
                self.variable[name] = value
                self.lastEnable[name] = atTime
            end
        end
    end,
})
