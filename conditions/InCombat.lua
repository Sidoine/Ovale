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

	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the player is in combat.
	-- @name InCombat
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the player is in combat. If no, then return true if the player isn't in combat.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if InCombat(no) and Stealthed(no) Spell(stealth)

	local function InCombat(condition)
		local yesno = condition[1]
		local boolean = Ovale.enCombat
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("incombat", false, InCombat)
end