--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- Double-ended queue.
local OVALE, Ovale = ...
local OvaleQueue = {}
Ovale.OvaleQueue = OvaleQueue

--<private-static-properties>
local setmetatable = setmetatable
--</private-static-properties>

--<public-static-properties>
OvaleQueue.name = "OvaleQueue"
OvaleQueue.first = 1
OvaleQueue.last = 0
OvaleQueue.__index = OvaleQueue
--</public-static-properties>

--<private-static-methods>
local function BackToFrontIterator(invariant, control)
	control = control - 1
	local element = invariant[control]
	if element then
		return control, element
	end
end

local function FrontToBackIterator(invariant, control)
	control = control + 1
	local element = invariant[control]
	if element then
		return control, element
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleQueue:NewDeque(name)
	return setmetatable({ name = name, first = 0, last = -1 }, OvaleQueue)
end

function OvaleQueue:InsertFront(element)
	local first = self.first - 1
	self.first = first
	self[first] = element
end

function OvaleQueue:InsertBack(element)
	local last = self.last + 1
	self.last = last
	self[last] = element
end

function OvaleQueue:RemoveFront()
	local first = self.first
	local element = self[first]
	if element then
		self[first] = nil
		self.first = first + 1
	end
	return element
end

function OvaleQueue:RemoveBack()
	local last = self.last
	local element = self[last]
	if element then
		self[last] = nil
		self.last = last - 1
	end
	return element
end

function OvaleQueue:At(index)
	if index > self:Size() then
		return
	end
	return self[self.first + index - 1]
end

function OvaleQueue:Front()
	return self[self.first]
end

function OvaleQueue:Back()
	return self[self.last]
end

function OvaleQueue:BackToFrontIterator()
	return BackToFrontIterator, self, self.last + 1
end

function OvaleQueue:FrontToBackIterator()
	return FrontToBackIterator, self, self.first - 1
end

function OvaleQueue:Reset()
	for i in self:BackToFrontIterator() do
		self[i] = nil
	end
	self.first = 0
	self.last = -1
end

function OvaleQueue:Size()
	return self.last - self.first + 1
end

function OvaleQueue:DebuggingInfo()
	Ovale:Print("Queue %s has %d item(s), first=%d, last=%d.", self.name, self:Size(), self.first, self.last)
end
--</public-static-methods>

--<public-static-properties>
-- Queue (FIFO) methods
OvaleQueue.NewQueue = OvaleQueue.NewDeque
OvaleQueue.Insert = OvaleQueue.InsertBack
OvaleQueue.Remove = OvaleQueue.RemoveFront
OvaleQueue.Iterator = OvaleQueue.FrontToBackIterator

-- Stack (LIFO) methods
OvaleQueue.NewStack = OvaleQueue.NewDeque
OvaleQueue.Push = OvaleQueue.InsertBack
OvaleQueue.Pop = OvaleQueue.RemoveBack
OvaleQueue.Top = OvaleQueue.Back
--</public-static-properties>
