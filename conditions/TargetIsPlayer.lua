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

	local API_UnitIsUnit = UnitIsUnit
	local ParseCondition = OvaleCondition.ParseCondition
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the player is the in-game target of the target.
	-- @name TargetIsPlayer
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if target.TargetIsPlayer() Spell(feign_death)

	local function TargetIsPlayer(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
		local boolean = API_UnitIsUnit("player", target .. "target")
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("istargetingplayer", false, TargetIsPlayer)
	OvaleCondition:RegisterCondition("targetisplayer", false, TargetIsPlayer)
end