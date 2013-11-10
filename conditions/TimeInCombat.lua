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

	local Compare = OvaleCondition.Compare
	local TestValue = OvaleCondition.TestValue

	--- Get the number of seconds elapsed since the player entered combat.
	-- @name TimeInCombat
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if TimeInCombat(more 5) Spell(bloodlust)

	local function TimeInCombat(condition)
		local comparator, limit = condition[1], condition[2]
		if Ovale.enCombat then
			local start = Ovale.combatStartTime
			return TestValue(start, math.huge, 0, start, 1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timeincombat", false, TimeInCombat)
end