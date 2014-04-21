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

	local API_GetTotemInfo = GetTotemInfo
	local Compare = OvaleCondition.Compare

	--- Get the number of active Wild Mushrooms by the player.
	-- @name WildMushroomCount
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of Wild Mushrooms.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if WildMushroomCount() < 3 Spell(wild_mushroom_caster)

	local function WildMushroomCount(condition)
		local comparator, limit = condition[1], condition[2]
		local count = 0
		for slot = 1, 3 do
			local haveTotem = API_GetTotemInfo(slot)
			if haveTotem then
				count = count + 1
			end
		end
		return Compare(count, comparator, limit)
	end

	OvaleCondition:RegisterCondition("wildmushroomcount", false, WildMushroomCount)
end
