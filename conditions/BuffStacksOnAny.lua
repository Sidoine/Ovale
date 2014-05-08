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

	--- Get the total number of stacks of the given aura across all targets.
	-- @name BuffStacksOnAny
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @return The total number of stacks.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffStacksOnAny

	local function BuffStacksOnAny(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local _, filter, mine = ParseCondition(condition)

		local count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast = state:AuraCount(auraId, filter, mine)
		if count > 0 then
			local start, ending = startFirst, endingChangeCount
			return TestValue(start, ending, stacks, start, 0, comparator, limit)
		end
		return Compare(count, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffstacksonany", false, BuffStacksOnAny)
	OvaleCondition:RegisterCondition("debuffstacksonany", false, BuffStacksOnAny)
end
