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
		local comparator, limit = condition[1], condition[2]
		local maxEnergy = OvalePower.maxPower.energy or 0
		local state = OvaleState.state
		local energy = state.energy or 0
		local energyRegen = state.powerRate.energy or 10
		local t = (maxEnergy - energy) / energyRegen
		if t > 0 then
			return TestValue(0, OvaleState.currentTime + t, t, OvaleState.currentTime, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timetomaxenergy", false, TimeToMaxEnergy)
end