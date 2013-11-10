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

	--- Get the amount of regenerated energy per second for feral druids, non-mistweaver monks, and rogues.
	-- @name EnergyRegen
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current rate of energy regeneration.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if EnergyRegen() >11 Spell(stance_of_the_sturdy_ox)

	local function EnergyRegen(condition)
		local comparator, limit = condition[1], condition[2]
		local value = OvaleState.powerRate.energy
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("energyregen", false, EnergyRegen)
end
