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

	local API_UnitIsFriend = UnitIsFriend
	local ParseCondition = OvaleCondition.ParseCondition
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the target is friendly to the player.
	-- @name IsFriend
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the target is friendly (able to help in combat). If no, then return true if it isn't friendly.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if target.IsFriend() Spell(healing_touch)

	local function IsFriend(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
		local boolean = API_UnitIsFriend("player", target)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isfriend", false, IsFriend)
end