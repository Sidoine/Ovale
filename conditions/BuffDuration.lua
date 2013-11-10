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
	local TestValue = OvaleCondition.TestValue

	--- Get the total duration of the aura from when it was first applied to when it ended.
	-- @name BuffDuration
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The total duration of the aura.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffDuration

	local function BuffDuration(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local state = OvaleState.state
		local start, ending = state:GetAura(target, auraId, filter, mine)
		start = start or 0
		ending = ending or math.huge
		value = ending - start
		return TestValue(start, ending, value, start, 0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffduration", false, BuffDuration)
	OvaleCondition:RegisterCondition("debuffduration", false, BuffDuration)
end
