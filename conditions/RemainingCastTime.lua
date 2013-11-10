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

	local select = select
	local API_UnitCastingInfo = UnitCastingInfo
	local ParseCondition = OvaleCondition.ParseCondition
	local TestValue = OvaleCondition.TestValue

	--- Get the remaining cast time in seconds of the target's current spell cast.
	-- @name RemainingCastTime
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see CastTime
	-- @usage
	-- if target.Casting(hour_of_twilight) and target.RemainingCastTime() <2
	--     Spell(cloak_of_shadows)

	local function RemainingCastTime(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local startTime, endTime = select(5, API_UnitCastingInfo(target))
		if not startTime or not endTime then
			return nil
		end
		startTime = startTime / 1000
		endTime = endTime / 1000
		return TestValue(startTime, endTime, 0, endTime, -1, comparator, limit)
	end

	OvaleCondition:RegisterCondition("remainingcasttime", false, RemainingCastTime)
end