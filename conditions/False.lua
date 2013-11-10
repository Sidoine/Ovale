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

	--- A condition that always returns false.
	-- @name False
	-- @paramsig boolean
	-- @return A boolean value.

	local function False(condition)
		return nil
	end

	OvaleCondition:RegisterCondition("false", false, False)
end
