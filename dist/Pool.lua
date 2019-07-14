local __exports = LibStub:NewLibrary("ovale/Pool", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local assert = assert
local tostring = tostring
local wipe = wipe
local insert = table.insert
local remove = table.remove
__exports.OvalePool = __class(nil, {
    constructor = function(self, name)
        self.pool = nil
        self.size = 0
        self.unused = 0
        self.name = name or "OvalePool"
        self:Drain()
    end,
    Get = function(self)
        assert(self.pool)
        local item = remove(self.pool)
        if item then
            self.unused = self.unused - 1
        else
            self.size = self.size + 1
            item = {}
        end
        return item
    end,
    Release = function(self, item)
        assert(self.pool)
        self:Clean(item)
        wipe(item)
        insert(self.pool, item)
        self.unused = self.unused + 1
    end,
    Drain = function(self)
        self.pool = {}
        self.size = self.size - self.unused
        self.unused = 0
    end,
    DebuggingInfo = function(self)
        Ovale:Print("Pool %s has size %d with %d item(s).", tostring(self.name), self.size, self.unused)
    end,
    Clean = function(self, item)
    end,
})
