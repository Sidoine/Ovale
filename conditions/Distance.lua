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
	local LRC = LibStub("LibRangeCheck-2.0", true)
	local OvaleCondition = Ovale.OvaleCondition

	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition

	--- Get the distance in yards to the target.
	-- The distances are from LibRangeCheck-2.0, which determines distance based on spell range checks, so results are approximate.
	-- You should not test for equality.
	-- @name Distance
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The distance to the target.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if target.Distance(less 25)
	--     Texture(ability_rogue_sprint)

	local function Distance(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local value = LRC and LRC:GetRange(target) or 0
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("distance", false, Distance)
end
