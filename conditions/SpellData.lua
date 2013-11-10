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

	local Compare = OvaleCondition.Compare

	--- Get data for the given spell defined by SpellInfo(...)
	-- @name SpellData
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param key The name of the data set by SpellInfo(...).
	--     Valid values are any alphanumeric string.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number data associated with the given key.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if BuffRemains(slice_and_dice) >= SpellData(shadow_blades duration)
	--     Spell(shadow_blades)

	local function SpellData(condition)
		local spellId, key, comparator, limit = condition[1], condition[2], condition[3], condition[4]
		local si = OvaleData.spellInfo[spellId]
		if si then
			local value = si[key]
			if value then
				return Compare(value, comparator, limit)
			end
		end
		return nil
	end

	OvaleCondition:RegisterCondition("spelldata", false, SpellData)
end