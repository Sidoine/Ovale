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

	local API_GetItemCooldown = GetItemCooldown
	local Compare = OvaleCondition.Compare
	local TestValue = OvaleCondition.TestValue

	--- Get the cooldown time in seconds of an item, e.g., trinket.
	-- @name ItemCooldown
	-- @paramsig number or boolean
	-- @param id The item ID or the equipped slot name.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if not ItemCooldown(ancient_petrified_seed) > 0
	--     Spell(berserk_cat)
	-- if not ItemCooldown(Trinket0Slot) > 0
	--     Spell(berserk_cat)

	local function ItemCooldown(condition)
		local itemId, comparator, limit = condition[1], condition[2], condition[3]
		if itemId and type(itemId) ~= "number" then
			itemId = OvaleEquipement:GetEquippedItem(itemId)
		end
		if itemId then
			local start, duration = API_GetItemCooldown(itemId)
			if start > 0 and duration > 0 then
				return TestValue(start, start + duration, duration, start, -1, comparator, limit)
			end
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("itemcooldown", false, ItemCooldown)
end