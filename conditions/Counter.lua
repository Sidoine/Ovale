--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleCondition = Ovale.OvaleCondition
	local OvaleState = Ovale.OvaleState

	local Compare = OvaleCondition.Compare

	--- Get the current value of a script counter.
	-- @name Counter
	-- @paramsig number or boolean
	-- @param id The name of the counter. It should match one that's defined by inccounter=xxx in SpellInfo(...).
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current value the counter.
	-- @return A boolean value for the result of the comparison.

	local function Counter(condition)
		local counter, comparator, limit = condition[1], condition[2], condition[3]
		local state = OvaleState.state
		local value = state:GetCounterValue(counter)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("counter", false, Counter)
end
