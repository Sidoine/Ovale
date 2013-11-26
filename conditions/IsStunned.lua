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
	local OvaleState = Ovale.OvaleState

	local API_HasFullControl = HasFullControl
	local TestBoolean = OvaleCondition.TestBoolean
	local state = OvaleState.state

	--- Test if the player is stunned.
	-- @name IsStunned
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if stunned. If no, then return true if it not stunned.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if IsStunned() Item(Trinket0Slot usable=1)

	local function IsStunned(condition)
		local yesno = condition[1]
		local aura = state:GetAura("player", "stun", "HARMFUL")
		local boolean = not API_HasFullControl() and state:IsActiveAura(aura)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isstunned", false, IsStunned)
end