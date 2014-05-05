--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleCondition = Ovale.OvaleCondition

	local API_IsSpellOverlayed = IsSpellOverlayed
	local ParseCondition = OvaleCondition.ParseCondition
	local TestBoolean = OvaleCondition.TestBoolean

	local WILD_MUSHROOM_BLOOM = 102791

	--- Test if the player's Wild Mushroom is fully charged for maximum healing.
	-- @name WildMushroomIsCharged
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the player's Wild Mushroom is fully charged. If no, then return true if it isn't fully charged.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if WildMushroomIsCharged() Spell(wild_mushroom_bloom)

	local function WildMushroomIsCharged(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
		local boolean = API_IsSpellOverlayed(WILD_MUSHROOM_BLOOM)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("wildmushroomischarged", false, WildMushroomIsCharged)
end
