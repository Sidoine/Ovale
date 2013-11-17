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

	local API_UnitLevel = UnitLevel
	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition
	local state = OvaleState.state

	--- Get the level of the target.
	-- @name Level
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The level of the target.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Level() >=34 Spell(tiger_palm)
	-- if Level(more 33) Spell(tiger_palm)

	local function Level(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local value
		if target == "player" then
			value = state.level
		else
			value = API_UnitLevel(target)
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("level", false, Level)
end