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

	local Compare = OvaleCondition.Compare
	local TestValue = OvaleCondition.TestValue

	--- Get the current number of active runes of the given type for death knights.
	-- @name RuneCount
	-- @paramsig number or boolean
	-- @param type The type of rune.
	--     Valid values: blood, frost, unholy, death
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param death Sets how death runes are used to fulfill the rune count requirements.
	--     If not set, then only death runes of the proper rune type are used.
	--     If set with "death=0", then no death runes are used.
	--     If set with "death=1", then death runes of any rune type are used.
	--     Default is unset.
	--     Valid values: unset, 0, 1
	-- @return The number of runes.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if RuneCount(unholy) ==2 or RuneCount(frost) ==2 or RuneCount(death) ==2
	--     Spell(obliterate)

	local function RuneCount(condition)
		local name, comparator, limit = condition[1], condition[2], condition[3]
		local deathCondition = condition.death

		local state = OvaleState.state
		local count, startCooldown, endCooldown = state:RuneCount(name, deathCondition)
		if startCooldown < math.huge then
			local origin = startCooldown
			local rate = 1 / (endCooldown - startCooldown)
			local start, ending = startCooldown, math.huge
			return TestValue(start, ending, count, origin, rate, comparator, limit)
		end
		return Compare(count, comparator, limit)
	end

	OvaleCondition:RegisterCondition("runecount", false, RuneCount)
end
