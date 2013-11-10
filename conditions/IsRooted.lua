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
	local OvaleState = Ovale.OvaleState

	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the player is rooted.
	-- @name IsRooted
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if rooted. If no, then return true if it not rooted.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if IsRooted() Item(Trinket0Slot usable=1)

	local function IsRooted(condition)
		local yesno = condition[1]
		local boolean = OvaleState:GetAura("player", "root", "HARMFUL")
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isrooted", false, IsRooted)
end