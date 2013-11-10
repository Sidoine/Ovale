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

	local API_GetItemCount = GetItemCount
	local Compare = OvaleCondition.Compare

	--- Get the current number of charges of the given item in the player's inventory.
	-- @name ItemCharges
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of charges.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if ItemCount(mana_gem) ==0 or ItemCharges(mana_gem) <3
	--     Spell(conjure_mana_gem)
	-- if ItemCount(mana_gem equal 0) or ItemCharges(mana_gem less 3)
	--     Spell(conjure_mana_gem)

	local function ItemCharges(condition)
		local itemId, comparator, limit = condition[1], condition[2], condition[3]
		local value = API_GetItemCount(itemId, false, true)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("itemcharges", false, ItemCharges)
end