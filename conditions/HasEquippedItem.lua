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
	local OvaleData = Ovale.OvaleData
	local OvaleEquipement = Ovale.OvaleEquipement

	local pairs = pairs
	local type = type
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the player has a particular item equipped.
	-- @name HasEquippedItem
	-- @paramsig boolean
	-- @param item Item to be checked whether it is equipped.
	-- @param yesno Optional. If yes, then return true if the item is equipped. If no, then return true if it isn't equipped.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param ilevel Optional.  Checks the item level of the equipped item.  If not specified, then any item level is valid.
	--     Defaults to not specified.
	--     Valid values: ilevel=N, where N is any number.
	-- @param slot Optional. Sets the inventory slot to check.  If not specified, then all slots are checked.
	--     Defaults to not specified.
	--     Valid values: slot=SLOTNAME, where SLOTNAME is a valid slot name, e.g., HandSlot.

	local function HasEquippedItem(condition)
		local itemId, yesno = condition[1], condition[2]
		local ilevel, slot = condition.ilevel, condition.slot
		local boolean = false
		local slotId
		if type(itemId) == "number" then
			slotId = OvaleEquipement:HasEquippedItem(itemId, slot)
			if slotId then
				if not ilevel or (ilevel and ilevel == OvaleEquipement:GetEquippedItemLevel(slotId)) then
					boolean = true
				end
			end
		elseif OvaleData.itemList[itemId] then
			for _, v in pairs(OvaleData.itemList[itemId]) do
				slotId = OvaleEquipement:HasEquippedItem(v, slot)
				if slotId then
					if not ilevel or (ilevel and ilevel == OvaleEquipement:GetEquippedItemLevel(slotId)) then
						boolean = true
						break
					end
				end
			end
		end
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("hasequippeditem", false, HasEquippedItem)
end