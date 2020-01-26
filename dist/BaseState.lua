local __exports = LibStub:NewLibrary("ovale/BaseState", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __State = LibStub:GetLibrary("ovale/State")
local States = __State.States
local GetTime = GetTime
local BaseStateData = __class(nil, {
    constructor = function(self)
        self.currentTime = 0
        self.defaultTarget = "target"
    end
})
__exports.BaseState = __class(States, {
    constructor = function(self)
        States.constructor(self, BaseStateData)
    end,
    InitializeState = function(self)
        self.next.defaultTarget = "target"
    end,
    ResetState = function(self)
        local now = GetTime()
        self.next.currentTime = now
        self.next.defaultTarget = self.current.defaultTarget
    end,
    CleanState = function(self)
    end,
})
