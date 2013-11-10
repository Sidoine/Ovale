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

	--- A condition that always returns true.
	-- @name True
	-- @paramsig boolean
	-- @return A boolean value.

	local function True(condition)
		return 0, math.huge
	end

	OvaleCondition:RegisterCondition("true", false, True)
end