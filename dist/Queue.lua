local __exports = LibStub:NewLibrary("ovale/Queue", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local format = string.format
local BackToFrontIterator = __class(nil, {
    constructor = function(self, invariant, control)
        self.invariant = invariant
        self.control = control
    end,
    Next = function(self)
        self.control = self.control - 1
        self.value = self.invariant[self.control]
        return self.control >= self.invariant.first
    end,
})
local FrontToBackIterator = __class(nil, {
    constructor = function(self, invariant, control)
        self.invariant = invariant
        self.control = control
    end,
    Next = function(self)
        self.control = self.control + 1
        self.value = self.invariant[self.control]
        return self.control <= self.invariant.last
    end,
})
__exports.OvaleDequeue = __class(nil, {
    constructor = function(self, name)
        self.name = name
        self.first = 0
        self.last = -1
    end,
    InsertFront = function(self, element)
        local first = self.first - 1
        self.first = first
        self[first] = element
    end,
    InsertBack = function(self, element)
        local last = self.last + 1
        self.last = last
        self[last] = element
    end,
    RemoveFront = function(self)
        local first = self.first
        local element = self[first]
        if element then
            self[first] = nil
            self.first = first + 1
        end
        return element
    end,
    RemoveBack = function(self)
        local last = self.last
        local element = self[last]
        if element then
            self[last] = nil
            self.last = last - 1
        end
        return element
    end,
    At = function(self, index)
        if index > self:Size() then
            return 
        end
        return self[self.first + index - 1]
    end,
    Front = function(self)
        return self[self.first]
    end,
    Back = function(self)
        return self[self.last]
    end,
    BackToFrontIterator = function(self)
        return BackToFrontIterator(self, self.last + 1)
    end,
    FrontToBackIterator = function(self)
        return FrontToBackIterator(self, self.first - 1)
    end,
    Reset = function(self)
        local iterator = self:BackToFrontIterator()
        while iterator:Next() do
            self[iterator.control] = nil
        end
        self.first = 0
        self.last = -1
    end,
    Size = function(self)
        return self.last - self.first + 1
    end,
    DebuggingInfo = function(self)
        return format("Queue %s has %d item(s), first=%d, last=%d.", self.name, self:Size(), self.first, self.last)
    end,
})
__exports.OvaleQueue = __class(__exports.OvaleDequeue, {
    Insert = function(self, value)
        self:InsertBack(value)
    end,
    Remove = function(self)
        return self:RemoveFront()
    end,
    Iterator = function(self)
        return self:FrontToBackIterator()
    end,
})
__exports.OvaleStack = __class(__exports.OvaleDequeue, {
    Push = function(self, value)
        self:InsertBack(value)
    end,
    Pop = function(self)
        return self:RemoveBack()
    end,
    Top = function(self)
        return self:Back()
    end,
})
