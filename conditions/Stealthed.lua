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

	local API_IsStealthed = IsStealthed
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the player is currently stealthed.
	-- The player is stealthed if rogue Stealth, druid Prowl, or a similar ability is active.
	-- Note that the rogue Vanish buff causes this condition to return false,
	-- but as soon as the buff disappears and the rogue is stealthed, this condition will return true.
	-- @name Stealthed
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if stealthed. If no, then return true if it not stealthed.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if Stealthed() or BuffPresent(vanish_buff) or BuffPresent(shadow_dance)
	--     Spell(ambush)

	local function Stealthed(condition)
		local yesno = condition[1]
		local boolean = API_IsStealthed()
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isstealthed", false, Stealthed)
	OvaleCondition:RegisterCondition("stealthed", false, Stealthed)
end