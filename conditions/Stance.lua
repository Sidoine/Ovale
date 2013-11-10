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
	local OvaleStance = Ovale.OvaleStance

	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the player is in a given stance.
	-- @name Stance
	-- @paramsig boolean
	-- @param stance The stance name or a number representing the stance index.
	-- @param yesno Optional. If yes, then return true if the player is in the given stance. If no, then return true otherwise.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- unless Stance(druid_bear_form) Spell(bear_form)

	local function Stance(condition)
		local stance, yesno = condition[1], condition[2]
		local boolean = OvaleStance:IsStance(stance)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("stance", false, Stance)
end