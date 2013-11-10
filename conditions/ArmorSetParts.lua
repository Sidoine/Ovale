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

	local Compare = OvaleCondition.Compare

	--- Get how many pieces of an armor set, e.g., Tier 14 set, are equipped by the player.
	-- @name ArmorSetParts
	-- @paramsig number or boolean
	-- @param name The name of the armor set.
	--     Valid names: T11, T12, T13, T14, T15.
	--     Valid names for hybrid classes: append _caster, _heal, _melee, _tank.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of pieces of the named set that are equipped by the player.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if ArmorSetParts(T13) >=2 and target.HealthPercent() <60
	--     Spell(ferocious_bite)
	-- if ArmorSetParts(T13 more 1) and TargetHealthPercent(less 60)
	--     Spell(ferocious_bite)

	local function ArmorSetParts(condition)
		local armorSet, comparator, limit = condition[1], condition[2], condition[3]
		local value = OvaleEquipement:GetArmorSetCount(armorSet)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("armorsetparts", false, ArmorSetParts)
end
