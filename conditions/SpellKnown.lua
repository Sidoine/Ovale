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

	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the given spell is in the spellbook.
	-- A spell is known if the player has learned the spell and it is in the spellbook.
	-- @name SpellKnown
	-- @paramsig boolean
	-- @param id The spell ID.
	-- @param yesno Optional. If yes, then return true if the spell has been learned.
	--     If no, then return true if the player hasn't learned the spell.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @see SpellUsable
	-- @usage
	-- if SpellKnown(avenging_wrath) and SpellCooldown(avenging_wrath) <10
	--     Spell(guardian_of_ancient_kings_retribution)

	local function SpellKnown(condition)
		local spellId, yesno = condition[1], condition[2]
		local boolean = OvaleSpellBook:IsKnownSpell(spellId)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("spellknown", true, SpellKnown)
end