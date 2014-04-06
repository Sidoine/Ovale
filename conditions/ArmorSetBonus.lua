--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleCondition = Ovale.OvaleCondition
	local OvaleEquipement = Ovale.OvaleEquipement

	--- Check whether the player currently has an armor set bonus.
	-- @name ArmorSetBonus
	-- @paramsig number
	-- @param name The name of the armor set.
	--     Valid names: T11, T12, T13, T14, T15, T16
	--     Valid names for hybrid classes: append _caster, _heal, _melee, _tank.
	-- @param count The number of pieces needed to activate the armor set bonus.
	-- @return 1 if the set bonus is active, or 0 otherwise.
	-- @usage
	-- if ArmorSetBonus(T16_melee 2) == 1 Spell(unleash_elements)

	local function ArmorSetBonus(condition)
		local armorSet, count = condition[1], condition[2]
		local value = (OvaleEquipement:GetArmorSetCount(armorSet) >= count) and 1 or 0
		return 0, math.huge, value, 0, 0
	end

	OvaleCondition:RegisterCondition("armorsetbonus", false, ArmorSetBonus)
end
