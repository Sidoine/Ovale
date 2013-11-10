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

	local API_UnitDetailedThreatSituation = UnitDetailedThreatSituation
	local ParseCondition = OvaleCondition.ParseCondition
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the target's primary aggro is on the player.
	-- Even if the target briefly targets and casts a spell on another raid member,
	-- this condition returns true as long as the player is highest on the threat table.
	-- @name IsAggroed
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the target is aggroed. If no, then return true if it isn't aggroed.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if target.IsAggroed() Spell(feign_death)

	local function IsAggroed(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
		local boolean = API_UnitDetailedThreatSituation("player", target)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isaggroed", false, IsAggroed)
end