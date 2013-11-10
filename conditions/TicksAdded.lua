--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleCondition = Ovale.OvaleCondition
	local OvaleState = Ovale.OvaleState

	local ParseCondition = OvaleCondition.ParseCondition
	local TestValue = OvaleCondition.TestValue

	local auraFound = {}

	--- Get the number of ticks that would be added if the dot were refreshed.
	-- Not implemented, always returns 0.
	-- @name TicksAdded
	-- @paramsig number or boolean
	-- @param id The aura spell ID
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of added ticks.
	-- @return A boolean value for the result of the comparison.

	local function TicksAdded(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		auraFound.tick = nil
		local start, ending = OvaleState:GetAura(target, auraId, filter, mine, auraFound)
		local tick = auraFound.tick
		return TestValue(start, ending, 0, start, 0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("ticksadded", false, TicksAdded)
end