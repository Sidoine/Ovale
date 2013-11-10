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
	local OvaleSpellBook = Ovale.OvaleSpellBook

	local API_IsSpellInRange = IsSpellInRange
	local ParseCondition = OvaleCondition.ParseCondition
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the distance from the player to the target is within the spell's range.
	-- @name InRange
	-- @paramsig boolean
	-- @param id The spell ID.
	-- @param yesno Optional. If yes, then return true if the target is in range. If no, then return true if it isn't in range.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if target.IsInterruptible() and target.InRange(kick)
	--     Spell(kick)

	local function InRange(condition)
		local spellId, yesno = condition[1], condition[2]
		local target = ParseCondition(condition)
		local spellName = OvaleSpellBook:GetSpellName(spellId)
		local boolean = (API_IsSpellInRange(spellName, target) == 1)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("inrange", false, InRange)
end