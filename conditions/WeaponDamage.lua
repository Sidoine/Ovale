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

	--- The normalized weapon damage of the weapon in the given hand.
	-- @name WeaponDamage
	-- @paramsig number or boolean
	-- @param hand Optional. Sets which hand weapon.
	--     Defaults to main.
	--     Valid values: main, off
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The normalized weapon damage.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- AddFunction MangleDamage {
	--     WeaponDamage() * 5 + 78
	-- }

	local function WeaponDamage(condition)
		local hand = condition[1]
		local comparator, limit
		local state = OvaleState.state
		local value = 0
		if hand == "offhand" or hand == "off" then
			comparator, limit = condition[2], condition[3]
			value = state.snapshot.offHandWeaponDamage
		elseif hand == "mainhand" or hand == "main" then
			comparator, limit = condition[2], condition[3]
			value = state.snapshot.mainHandWeaponDamage
		else
			comparator, limit = condition[1], condition[2]
			value = state.snapshot.mainHandWeaponDamage
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("weapondamage", false, WeaponDamage)
end