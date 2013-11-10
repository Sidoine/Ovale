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

	--- Test if a list is currently set to the given value.
	-- @name List
	-- @paramsig boolean
	-- @param id The name of a list. It should match one defined by AddListItem(...).
	-- @param value The value to test.
	-- @return A boolean value.
	-- @usage
	-- AddListItem(opt_curse coe "Curse of the Elements" default)
	-- AddListItem(opt_curse cot "Curse of Tongues")
	-- if List(opt_curse coe) Spell(curse_of_the_elements)

	local function List(condition)
		local name, value = condition[1], condition[2]
		if name and Ovale:GetListValue(name) == value then
			return 0, math.huge
		end
		return nil
	end

	OvaleCondition:RegisterCondition("list", false, List)
end