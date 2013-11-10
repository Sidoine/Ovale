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

	local API_UnitCastingInfo = UnitCastingInfo
	local API_UnitChannelInfo = UnitChannelInfo
	local ParseCondition = OvaleCondition.ParseCondition
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the target is currently casting an interruptible spell.
	-- @name IsInterruptible
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the target is interruptible. If no, then return true if it isn't interruptible.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if target.IsInterruptible() Spell(kick)

	local function IsInterruptible(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
		local name, _, _, _, _, _, _, _, notInterruptible = API_UnitCastingInfo(target)
		if not name then
			name, _, _, _, _, _, _, notInterruptible = API_UnitChannelInfo(target)
		end
		local boolean = notInterruptible ~= nil and not notInterruptible
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isinterruptible", false, IsInterruptible)
end