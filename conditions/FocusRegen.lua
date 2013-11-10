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

	--- Get the amount of regenerated focus per second for hunters.
	-- @name FocusRegen
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current rate of focus regeneration.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if FocusRegen() >20 Spell(arcane_shot)
	-- if FocusRegen(more 20) Spell(arcane_shot)

	local function FocusRegen(condition)
		local comparator, limit = condition[1], condition[2]
		local value = OvaleState.powerRate.focus
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("focusregen", false, FocusRegen)
end
