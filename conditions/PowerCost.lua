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

	local API_GetSpellInfo = GetSpellInfo
	local Compare = OvaleCondition.Compare

	--- Get the resource cost of the given spell.
	-- This returns zero for spells that use either mana or another resource based on stance/specialization, e.g., Monk's Jab.
	-- @name PowerCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of power (energy, focus, rage, etc.).
	-- @return A boolean value for the result of the comparison.
	-- @see EnergyCost, FocusCost, ManaCost, RageCost
	-- @usage
	-- if Energy() > PowerCost(rake) Spell(rake)

	local function PowerCost(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local _, _, _, cost = API_GetSpellInfo(spellId)
		local value = cost or 0
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("energycost", true, PowerCost)
	OvaleCondition:RegisterCondition("focuscost", true, PowerCost)
	OvaleCondition:RegisterCondition("manacost", true, PowerCost)
	OvaleCondition:RegisterCondition("powercost", true, PowerCost)
	OvaleCondition:RegisterCondition("ragecost", true, PowerCost)
end