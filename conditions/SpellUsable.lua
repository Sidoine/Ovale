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

	local API_IsUsableSpell = IsUsableSpell
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the given spell is usable.
	-- A spell is usable if the player has learned the spell and has the resources required to cast the spell.
	-- @name SpellUsable
	-- @paramsig boolean
	-- @param id The spell ID.
	-- @param yesno Optional. If yes, then return true if the spell has been learned and the player has enough resources to cast it.
	--     If no, then return true if the player can't cast the spell for one of the above reasons.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @see SpellKnown
	-- @usage
	-- if SpellUsable(avenging_wrath) and SpellCooldown(avenging_wrath) <10
	--     Spell(guardian_of_ancient_kings_retribution)

	local function SpellUsable(condition)
		local spellId, yesno = condition[1], condition[2]
		local boolean = API_IsUsableSpell(spellId)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("spellusable", true, SpellUsable)
end