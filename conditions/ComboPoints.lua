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

	--- Get the number of combo points on the currently selected target for a feral druid or a rogue.
	-- @name ComboPoints
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of combo points.
	-- @return A boolean value for the result of the comparison.
	-- @see LastComboPoints
	-- @usage
	-- if ComboPoints() >=1 Spell(savage_roar)
	-- if ComboPoints(more 0) Spell(savage_roar)

	local function ComboPoints(condition)
		local comparator, limit = condition[1], condition[2]
		local value = OvaleState.state.combo
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("combopoints", false, ComboPoints)
end
