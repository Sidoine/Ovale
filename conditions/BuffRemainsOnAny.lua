--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013, 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleCondition = Ovale.OvaleCondition
	local OvaleState = Ovale.OvaleState

	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition
	local TestValue = OvaleCondition.TestValue
	local state = OvaleState.state

	--- Get the remaining time in seconds before the aura expires across all targets.
	-- @name BuffRemainsOnAny
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param stacks Optional. The minimum number of stacks of the aura required.
	--     Defaults to stacks=1.
	--     Valid values: any number greater than zero.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param excludeTarget Optional. Sets whether to ignore the current target when scanning targets.
	--     Defaults to excludeTarget=0.
	--     Valid values: 0, 1.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffRemainsOnAny

	local function BuffRemainsOnAny(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local _, filter, mine = ParseCondition(condition)
		local excludeUnitId = (condition.excludeTarget == 1) and OvaleCondition.defaultTarget or nil

		local count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast = state:AuraCount(auraId, filter, mine, condition.stacks, excludeUnitId)
		if count > 0 then
			local start, ending = startFirst, endingLast
			return TestValue(start, math.huge, 0, ending, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffremainsonany", false, BuffRemainsOnAny)
	OvaleCondition:RegisterCondition("debuffremainsonany", false, BuffRemainsOnAny)
end
