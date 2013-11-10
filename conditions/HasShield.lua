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

	--- Test if the player has a shield equipped.
	-- @name HasShield
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if a shield is equipped. If no, then return true if it isn't equipped.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if HasShield() Spell(shield_wall)

	local function HasShield(condition)
		local yesno = condition[1]
		local boolean = OvaleEquipement:HasShield()
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("hasshield", false, HasShield)
end