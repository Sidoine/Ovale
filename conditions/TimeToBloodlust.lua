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
	local ParseCondition = OvaleCondition.ParseCondition
	local TestValue = OvaleCondition.TestValue
	local state = OvaleState.state

	--- Get the time in seconds until the next scheduled Bloodlust cast.
	-- Not implemented, always returns 3600 seconds.
	-- @name TimeToBloodlust
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.

	local function TimeToBloodlust(condition)
		local comparator, limit = condition[1], condition[2], condition[3]
		local value = 3600
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timetobloodlust", false, TimeToBloodlust)
end