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

	--- Get the current number of the given item in the player's inventory.
	-- Items with more than one charge count as one item.
	-- @name ItemCount
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The count of the item.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if ItemCount(mana_gem) ==0 Spell(conjure_mana_gem)
	-- if ItemCount(mana_gem equal 0) Spell(conjure_mana_gem)

	local function ItemCount(condition)
		local itemId, comparator, limit = condition[1], condition[2], condition[3]
		local value = API_GetItemCount(itemId)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("itemcount", false, ItemCount)
end