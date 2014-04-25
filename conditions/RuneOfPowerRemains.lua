--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleCondition = Ovale.OvaleCondition
	local OvaleState = Ovale.OvaleState

	local type = type
	local API_GetTotemInfo = GetTotemInfo
	local Compare = OvaleCondition.Compare
	local TestValue = OvaleCondition.TestValue
	local state = OvaleState.state

	local RUNE_OF_POWER_BUFF = 116014

	--- Get the remaining time in seconds before the latest Rune of Power expires.
	--- Returns non-zero only if the player is standing within an existing Rune of Power.
	-- @name RuneOfPowerRemains
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if RuneOfPowerRemains() < CastTime(rune_of_power) Spell(rune_of_power)

	local function RuneOfPowerRemains(condition)
		local comparator, limit = condition[1], condition[2]
		local aura = state:GetAura("player", RUNE_OF_POWER_BUFF, "HELPFUL")
		if aura then
			local start, ending
			for totemSlot = 1, 2 do
				local haveTotem, name, startTime, duration = API_GetTotemInfo(totemSlot)
				if haveTotem and startTime and (not start or startTime > start) then
					start = startTime
					ending = startTime + duration
				end
			end
			if start then
				return TestValue(start, ending, ending - start, start, -1, comparator, limit)
			end
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("runeofpowerremains", false, RuneOfPowerRemains)
end
