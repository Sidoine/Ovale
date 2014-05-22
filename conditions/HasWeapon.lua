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
	local OvaleEquipement = Ovale.OvaleEquipement

	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the player has a weapon equipped.
	-- @name HasWeapon
	-- @paramsig boolean
	-- @param hand Sets which hand weapon.
	--     Valid values: main, off
	-- @param yesno Optional. If yes, then return true if the weapon is equipped. If no, then return true if it isn't equipped.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param type Optional. If set via type=value, then specify whether the weapon must be one-handed or two-handed.
	--     Default is unset.
	--     Valid values: 1h, 2h
	-- @return A boolean value.
	-- @usage
	-- if HasWeapon(offhand) and BuffStacks(killing_machine) Spell(frost_strike)

	local function HasWeapon(condition)
		local hand, yesno = condition[1], condition[2]
		local weaponType = condition.type
		local boolean = false
		if weaponType == "1h" then
			weaponType = 1
		elseif weaponType == "2h" then
			weaponType = 2
		end
		if hand == "offhand" or hand == "off" then
			boolean = OvaleEquipement:HasOffHandWeapon(weaponType)
		elseif hand == "mainhand" or hand == "main" then
			boolean = OvaleEquipement:HasMainHandWeapon(weaponType)
		end
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("hasweapon", false, HasWeapon)
end