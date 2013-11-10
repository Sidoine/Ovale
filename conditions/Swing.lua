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
	local OvaleSwing = Ovale.OvaleSwing

	local TestValue = OvaleCondition.TestValue

	--- Get the time elapsed in seconds since the player's previous melee swing (white attack).
	-- @name LastSwing
	-- @paramsig number or boolean
	-- @param hand Optional. Sets which hand weapon's melee swing.
	--     If no hand is specified, then return the time elapsed since the previous swing of either hand's weapon.
	--     Valid values: main, off.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see NextSwing

	local function LastSwing(condition)
		local swing = condition[1]
		local comparator, limit
		local start
		if swing and swing == "main" or swing == "off" then
			comparator, limit = condition[2], condition[3]
			start = OvaleSwing:GetLast(swing)
		else
			comparator, limit = condition[1], condition[2]
			start = OvaleSwing:GetLast()
		end
		return TestValue(start, math.huge, 0, start, 1, comparator, limit)
	end

	--- Get the time in seconds until the player's next melee swing (white attack).
	-- @name NextSwing
	-- @paramsig number or boolean
	-- @param hand Optional. Sets which hand weapon's melee swing.
	--     If no hand is specified, then return the time until the next swing of either hand's weapon.
	--     Valid values: main, off.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds
	-- @return A boolean value for the result of the comparison.
	-- @see LastSwing

	local function NextSwing(condition)
		local swing = condition[1]
		local comparator, limit
		local ending
		if swing and swing == "main" or swing == "off" then
			comparator, limit = condition[2], condition[3]
			ending = OvaleSwing:GetNext(swing)
		else
			comparator, limit = condition[1], condition[2]
			ending = OvaleSwing:GetNext()
		end
		return TestValue(0, ending, 0, ending, -1, comparator, limit)
	end

	OvaleCondition:RegisterCondition("lastswing", false, LastSwing)
	OvaleCondition:RegisterCondition("nextswing", false, NextSwing)
end