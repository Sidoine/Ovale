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

	local API_GetBuildInfo = GetBuildInfo
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the game is on a PTR server
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then returns true if it is a PTR realm. If no, return true if it is a live realm.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value

	local function PTR(condition)
		local yesno = condition[1]
		local _, _, _, uiVersion = API_GetBuildInfo()
		local boolean = (uiVersion > 50400)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("ptr", false, PTR)
end