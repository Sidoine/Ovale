local __exports = LibStub:NewLibrary("ovale/Variables", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local pairs = pairs
__exports.Variables = __class(nil, {
    constructor = function(self, ovaleFuture, baseState, ovaleDebug)
        self.ovaleFuture = ovaleFuture
        self.baseState = baseState
        self.isState = true
        self.isInitialized = false
        self.futureVariable = nil
        self.futureLastEnable = nil
        self.variable = {}
        self.lastEnable = {}
        self.tracer = ovaleDebug:create("Variables")
    end,
    InitializeState = function(self)
        self.futureVariable = {}
        self.futureLastEnable = {}
        if  not self.ovaleFuture:IsInCombat(nil) then
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
