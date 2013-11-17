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
	local OvaleState = Ovale.OvaleState

	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the previous spell cast matches the given spell.
	-- @name PreviousSpell
	-- @paramsig boolean
	-- @param id The spell ID.
	-- @param yesno Optional. If yes, then return true if there is a match. If no, then return true if it doesn't match.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.

	local function PreviousSpell(condition)
		local spellId, yesno = condition[1], condition[2]
		local boolean = (spellId == OvaleState.lastSpellId)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("previousspell", true, PreviousSpell)
end