--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- Double-ended queue.
local _, Ovale = ...
local OvaleDeque = {}
Ovale.OvaleDeque = OvaleDeque

--<public-static-properties>
OvaleDeque.name = "OvaleDeque"
OvaleDeque.first = 0
OvaleDeque.last = -1
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
function OvaleDeque:New(name)
	obj = { name = name, first = 0, last = -1 }
	setmetatable(obj, { __index = self })
	return obj
end

function OvaleDeque:InsertFront(element)
	local first = self.first - 1
	self.first = first
	self[first] = element
end

function OvaleDeque:InsertBack(element)
	local last = self.last + 1
	self.last = last
	self[last] = element
end

function OvaleDeque:RemoveFront()
	local first = self.first
	local element = self[first]
	if element then
		self[first] = nil
		self.first = first + 1
	end
	return element
end

function OvaleDeque:RemoveBack()
	local last = self.last
	local element = self[last]
	if element then
		self[last] = nil
		self.last = last - 1
	end
	return element
end

function OvaleDeque:Front()
	return self[self.first]
end

function OvaleDeque:Back()
	return self[self.last]
end

function OvaleDeque:BackToFrontIterator()
	return BackToFrontIterator, self, self.last + 1
end

function OvaleDeque:FrontToBackIterator()
	return FrontToBackIterator, self, self.first - 1
end

function OvaleDeque:Reset()
	for i in self:BackToFrontIterator() do
		self[i] = nil
	end
	self.first = 0
	self.last = -1
end

function OvaleDeque:Debug()
	Ovale:FormatPrint("Deque %s has %d item(s), first=%d, last=%d.", self.name, self.last - self.first + 1, self.first, self.last)
end
--</public-static-methods>
