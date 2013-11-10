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

	local pairs = pairs
	local type = type
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the player has a particular trinket equipped.
	-- @name HasTrinket
	-- @paramsig boolean
	-- @param id The item ID of the trinket or the name of an item list.
	-- @param yesno Optional. If yes, then return true if the trinket is equipped. If no, then return true if it isn't equipped.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- ItemList(rune_of_reorigination 94532 95802 96546)
	-- if HasTrinket(rune_of_reorigination) and BuffPresent(rune_of_reorigination_buff)
	--     Spell(rake)

	local function HasTrinket(condition)
		local trinketId, yesno = condition[1], condition[2]
		local boolean = false
		if type(trinketId) == "number" then
			boolean = OvaleEquipement:HasTrinket(trinketId)
		elseif OvaleData.itemList[trinketId] then
			for _, v in pairs(OvaleData.itemList[trinketId]) do
				boolean = OvaleEquipement:HasTrinket(v)
				if boolean then
					break
				end
			end
		end
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("hastrinket", false, HasTrinket)
end
