local __exports = LibStub:NewLibrary("ovale/PoolGC", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local tostring = tostring
__exports.OvalePoolGC = __class(nil, {
    constructor = function(self, name)
        self.name = "OvalePoolGC"
        self.size = 0
        self.__index = __exports.OvalePoolGC
        self.name = name
    end,
    Get = function(self)
        self.size = self.size + 1
        return {}
    end,
    Release = function(self, item)
        self:Clean(item)
    end,
    Clean = function(self, item)
    end,
    Drain = function(self)
        self.size = 0
    end,
    DebuggingInfo = function(self)
        Ovale:Print("Pool %s has size %d.", tostring(self.name), self.size)
    end,
})
