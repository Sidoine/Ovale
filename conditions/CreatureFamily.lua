--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local LBCT = LibStub("LibBabble-CreatureType-3.0"):GetLookupTable()
	local OvaleCondition = Ovale.OvaleCondition

	local API_UnitCreatureFamily = UnitCreatureFamily
	local ParseCondition = OvaleCondition.ParseCondition
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test whether the target's creature family matches the given name.
	-- Applies only to beasts that can be taken as hunter pets (e.g., cats, worms, and ravagers but not zhevras, talbuks and pterrordax),
	-- demons that can be summoned by Warlocks (e.g., imps and felguards, but not demons that require enslaving such as infernals
	-- and doomguards or world demons such as pit lords and armored voidwalkers), and Death Knight's pets (ghouls)
	-- @name CreatureFamily
	-- @paramsig boolean
	-- @param name The English name of the creature family to check.
	--     Valid values: Bat, Beast, Felguard, Imp, Ravager, etc.
	-- @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if pet.CreatureFamily(Felguard)
	--     Spell(summon_felhunter)
	-- if target.CreatureFamily(Dragonkin)
	--     Spell(hibernate)

	local function CreatureFamily(condition)
		local name, yesno = condition[1], condition[2]
		local target = ParseCondition(condition)
		local family = API_UnitCreatureFamily(target)
		local boolean = (family == LBCT[name])
		return TestBoolean(boolean, yesno)	
	end

	OvaleCondition:RegisterCondition("creaturefamily", false, CreatureFamily)
end
