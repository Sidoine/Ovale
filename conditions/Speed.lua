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

	local API_GetUnitSpeed = GetUnitSpeed
	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition

	--- Get the current speed of the target.
	-- If the target is not moving, then this condition returns 0 (zero).
	-- If the target is at running speed, then this condition returns 100.
	-- @name Speed
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The speed of the target.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Speed(more 0) and not BuffPresent(aspect_of_the_fox)
	--     Spell(aspect_of_the_fox)

	local function Speed(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local value = API_GetUnitSpeed(target) * 100 / 7
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("speed", false, Speed)
end