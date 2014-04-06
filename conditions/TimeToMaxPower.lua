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

	local Compare = OvaleCondition.Compare
	local TestValue = OvaleCondition.TestValue
	local state = OvaleState.state

	--- Get the number of seconds before the player reaches maximum power.
	local function TimeToMax(powerType, condition)
		local comparator, limit = condition[1], condition[2]
		local maxPower = OvalePower.maxPower[powerType] or 0
		local power = state[powerType] or 0
		local powerRegen = state.powerRate[powerType] or 1
		local t = (maxPower - power) / powerRegen
		if t > 0 then
			return TestValue(0, state.currentTime + t, t, state.currentTime, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	--- Get the number of seconds before the player reaches maximum energy for feral druids, non-mistweaver monks and rogues.
	-- @name TimeToMaxEnergy
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @see TimeToEnergyFor
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if TimeToMaxEnergy() < 1.2 Spell(sinister_strike)

	local function TimeToMaxEnergy(condition)
		return TimeToMax("energy", condition)
	end

	--- Get the number of seconds before the player reaches maximum focus for hunters.
	-- @name TimeToMaxFocus
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @see TimeToEnergyFor
	-- @return A boolean value for the result of the comparison.

	local function TimeToMaxFocus(condition)
		return TimeToMax("focus", condition)
	end

	OvaleCondition:RegisterCondition("timetomaxenergy", false, TimeToMaxEnergy)
	OvaleCondition:RegisterCondition("timetomaxfocus", false, TimeToMaxFocus)
end