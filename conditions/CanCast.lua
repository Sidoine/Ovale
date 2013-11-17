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

	local state = OvaleState.state

	--- Check if the player can cast the given spell (not on cooldown).
	-- @name CanCast
	-- @paramsig boolean
	-- @param id The spell ID to check.
	-- @return True if the spell cast be cast; otherwise, false.

	local function CanCast(condition)
		local spellId = condition[1]
		local start, duration = state:GetSpellCooldown(spellId)
		return start + duration, math.huge
	end

	OvaleCondition:RegisterCondition("cancast", true, CanCast)
end
