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
	local OvaleAura = Ovale.OvaleAura

	local ParseCondition = OvaleCondition.ParseCondition

	--- Test if there is a stealable buff on the target.
	-- @name BuffStealable
	-- @paramsig boolean
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if target.BuffStealable()
	--     Spell(spellsteal)

	local function BuffStealable(condition)
		-- TODO: This should really be checked only against OvaleState.
		local target = ParseCondition(condition)
		return OvaleAura:GetStealable(target)
	end

	OvaleCondition:RegisterCondition("buffstealable", false, BuffStealable)
end
