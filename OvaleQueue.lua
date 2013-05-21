--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- Double-ended queue.
local _, Ovale = ...
local OvaleQueue = {}
Ovale.OvaleQueue = OvaleQueue

--<public-static-properties>
OvaleQueue.name = "OvaleQueue"
OvaleQueue.first = 0
OvaleQueue.last = -1
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
	obj = { name = name, first = 0, last = -1 }
	setmetatable(obj, { __index = self })
	return obj
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

function OvaleQueue:Debug()
	Ovale:FormatPrint("Queue %s has %d item(s), first=%d, last=%d.", self.name, self.last - self.first + 1, self.first, self.last)
end
--</public-static-methods>

--<public-static-properties>
-- Queue (LIFO) methods
OvaleQueue.NewQueue = OvaleQueue.NewDeque
OvaleQueue.Insert = OvaleQueue.InsertBack
OvaleQueue.Remove = OvaleQueue.RemoveFront
OvaleQueue.Iterator = OvaleQueue.FrontToBackIterator

-- Stack (FIFO) methods
OvaleQueue.NewStack = OvaleQueue.NewDeque
OvaleQueue.Push = OvaleQueue.InsertFront
OvaleQueue.Pop = OvaleQueue.RemoveFront
OvaleQueue.Top = OvaleQueue.Front
--</public-static-properties>
