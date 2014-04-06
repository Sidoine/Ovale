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
	local OvalePower = Ovale.OvalePower
	local OvaleState = Ovale.OvaleState

	local API_GetSpellInfo = GetSpellInfo
	local Compare = OvaleCondition.Compare
	local TestValue = OvaleCondition.TestValue
	local state = OvaleState.state

	--- Get the number of seconds before the player has enough primary resources to cast the given spell.
	-- @name TimeToPowerFor
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see TimeToEnergyFor, TimeToFocusFor, TimeToMaxEnergy

	local function TimeToPowerFor(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local _, _, _, cost, _, powerToken = API_GetSpellInfo(spellId)
		local powerType = OvalePower.POWER_TYPE[powerToken]
		local currentPower = state[powerType]
		local powerRate = state.powerRate[powerType]
		cost = cost or 0
		if currentPower < cost then
			if powerRate > 0 then
				local t = (cost - currentPower)/powerRate
				return TestValue(0, state.currentTime + t, t, state.currentTime, -1, comparator, limit)
			else
				return Compare(math.huge, comparator, limit)
			end
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timetoenergyfor", true, TimeToPowerFor)
	OvaleCondition:RegisterCondition("timetofocusfor", true, TimeToPowerFor)
	OvaleCondition:RegisterCondition("timetopowerfor", true, TimeToPowerFor)
end