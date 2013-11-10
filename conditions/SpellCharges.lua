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

	local API_GetSpellCharges = GetSpellCharges
	local Compare = OvaleCondition.Compare

	--- Get the number of charges of the spell.
	-- @name SpellCharges
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of charges.
	-- @return A boolean value for the result of the comparison.
	-- @see SpellChargeCooldown
	-- @usage
	-- if SpellCharges(savage_defense) >1
	--     Spell(savage_defense)

	local function SpellCharges(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local value = API_GetSpellCharges(spellId)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("charges", true, SpellCharges)
	OvaleCondition:RegisterCondition("spellcharges", true, SpellCharges)
end
