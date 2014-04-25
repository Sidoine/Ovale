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

	local function TimeToPower(powerType, condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		if not powerType then
			local _, _, _, _, _, powerToken = API_GetSpellInfo(spellId)
			powerType = OvalePower.POWER_TYPE[powerToken]
		end
		local seconds = state:TimeToPower(spellId, powerType)

		if seconds == 0 then
			return Compare(0, comparator, limit)
		elseif seconds < math.huge then
			return TestValue(0, state.currentTime + seconds, seconds, state.currentTime, -1, comparator, limit)
		else -- if seconds == math.huge then
			return Compare(math.huge, comparator, limit)
		end
	end

	--- Get the number of seconds before the player has enough energy to cast the given spell.
	-- @name TimeToEnergyFor
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see TimeToEnergyFor, TimeToMaxEnergy

	local function TimeToEnergyFor(condition)
		return TimeToPower("energy", condition)
	end

	--- Get the number of seconds before the player has enough focus to cast the given spell.
	-- @name TimeToFocusFor
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see TimeToFocusFor

	local function TimeToFocusFor(condition)
		return TimeToPower("focus", condition)
	end

	OvaleCondition:RegisterCondition("timetoenergyfor", true, TimeToEnergyFor)
	OvaleCondition:RegisterCondition("timetofocusfor", true, TimeToFocusFor)
end
