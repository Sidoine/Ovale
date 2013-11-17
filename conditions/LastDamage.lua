--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleCondition = Ovale.OvaleCondition
	local OvaleSpellDamage = Ovale.OvaleSpellDamage

	local Compare = OvaleCondition.Compare

	--- Get the damage done by the most recent damage event for the given spell.
	-- If the spell is a periodic aura, then it gives the damage done by the most recent tick.
	-- @name LastDamage
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The damage done.
	-- @return A boolean value for the result of the comparison.
	-- @see Damage, LastEstimatedDamage
	-- @usage
	-- if LastDamage(ignite) >10000 Spell(combustion)
	-- if LastDamage(ignite more 10000) Spell(combustion)

	local function LastDamage(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local value = OvaleSpellDamage:Get(spellId)
		if value then
			return Compare(value, comparator, limit)
		end
		return nil
	end

	OvaleCondition:RegisterCondition("lastdamage", false, LastDamage)
	OvaleCondition:RegisterCondition("lastspelldamage", false, LastDamage)
end