local __exports = LibStub:NewLibrary("ovale/Variables", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local pairs = pairs
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __BaseState = LibStub:GetLibrary("ovale/BaseState")
local baseState = __BaseState.baseState
__exports.Variables = __class(nil, {
    InitializeState = function(self)
        self.futureVariable = {}
        self.futureLastEnable = {}
        self.variable = {}
        self.lastEnable = {}
    end,
    ResetState = function(self)
        for k in pairs(self.futureVariable) do
            self.futureVariable[k] = nil
            self.futureLastEnable[k] = nil
        end
        if  not baseState.current.inCombat then
            for k in pairs(self.variable) do
                self:Log("Resetting state variable '%s'.", k)
                self.variable[k] = nil
                self.lastEnable[k] = nil
            end
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
        local lastEnable = self.futureLastEnable[name] or self.lastEnable[name] or baseState.next.currentTime
        return baseState.next.currentTime - lastEnable
    end,
    PutState = function(self, name, value, isFuture, atTime)
        if isFuture then
            local oldValue = self:GetState(name)
            if value ~= oldValue then
                self:Log("Setting future state: %s from %s to %s.", name, oldValue, value)
                self.futureVariable[name] = value
                self.futureLastEnable[name] = atTime
            end
        else
            local oldValue = self.variable[name] or 0
            if value ~= oldValue then
                OvaleState:DebugTimestamp("Advancing combat state: %s from %s to %s.", name, oldValue, value)
                self:Log("Advancing combat state: %s from %s to %s.", name, oldValue, value)
                self.variable[name] = value
                self.lastEnable[name] = atTime
            end
        end
    end,
    Log = function(self, ...)
        OvaleState:Log(...)
    end,
    constructor = function(self)
        self.isState = true
        self.isInitialized = false
        self.futureVariable = nil
        self.futureLastEnable = nil
        self.variable = nil
        self.lastEnable = nil
    end
})
__exports.variables = __exports.Variables()
OvaleState:RegisterState(__exports.variables)
