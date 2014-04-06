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

	local API_UnitDetailedThreatSituation = UnitDetailedThreatSituation
	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition

	--- Get the amount of threat on the current target relative to the its primary aggro target, scaled to between 0 (zero) and 100.
	-- This is a number between 0 (no threat) and 100 (will become the primary aggro target).
	-- @name Threat
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The amount of threat.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Threat() >90 Spell(fade)
	-- if Threat(more 90) Spell(fade)

	local function Threat(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition, "target")
		local _, _, value = API_UnitDetailedThreatSituation("player", target)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("threat", false, Threat)
end