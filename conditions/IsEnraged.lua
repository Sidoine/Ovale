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

	local TestBoolean = OvaleCondition.TestBoolean
	local state = OvaleState.state

	--- Test if the target is enraged.
	-- @name IsEnraged
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if enraged. If no, then return true if not enraged.
	--     Default is yes.
	--     Valid values: yes.  "no" currently doesn't work.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if target.IsEnraged() Spell(soothe)

	local function IsEnraged(condition)
		local yesno = condition[1]
		return state:GetAuraWithProperty(target, "enraged", "HELPFUL")
	end

	OvaleCondition:RegisterCondition("isfeared", false, IsFeared)
end