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

	local ParseCondition = OvaleCondition.ParseCondition
	local state = OvaleState.state

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
		local target = ParseCondition(condition)
		local count, start, ending = state:GetStealable(target)
		if count > 0 then
			return start, ending
		end
		return nil
	end

	OvaleCondition:RegisterCondition("buffstealable", false, BuffStealable)
end
