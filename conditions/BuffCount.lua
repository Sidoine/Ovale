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

	--- Get the total count of the given aura across all targets.
	-- @name BuffCount
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @return The total aura count.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffCount

	local function BuffCount(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local _, filter, mine = ParseCondition(condition)

		local count, startChangeCount, endingChangeCount, startFirst, endingLast = state:AuraCount(auraId, filter, mine)
		Ovale:Logf("BuffCount(%d) is %s, %s, %s, %s, %s", auraId, count, startChangeCount, endingChangeCount, startFirst, endingLast)
		if count > 0 and startChangeCount < math.huge then
			local origin = startChangeCount
			local rate = -1 / (endingChangeCount - startChangeCount)
			local start, ending = startFirst, endingLast
			return TestValue(start, ending, count, origin, rate, comparator, limit)
		end
		return Compare(count, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffcount", false, BuffCount)
	OvaleCondition:RegisterCondition("debuffcount", false, BuffCount)
end
