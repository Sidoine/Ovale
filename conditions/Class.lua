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

	local API_UnitClass = UnitClass
	local ParseCondition = OvaleCondition.ParseCondition
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test whether the target's class matches the given class.
	-- @name Class
	-- @paramsig boolean
	-- @param class The class to check.
	--     Valid values: DEATHKNIGHT, DRUID, HUNTER, MAGE, MONK, PALADIN, PRIEST, ROGUE, SHAMAN, WARLOCK, WARRIOR.
	-- @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if target.Class(PRIEST) Spell(cheap_shot)

	local function Class(condition)
		local class, yesno = condition[1], condition[2]
		local target = ParseCondition(condition)
		local _, classToken = API_UnitClass(target)
		local boolean = (classToken == class)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("class", false, Class)
end
