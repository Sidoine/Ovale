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

	local API_UnitStagger = UnitStagger
	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition
	local TestValue = OvaleCondition.TestValue

	local LIGHT_STAGGER = 124275
	local MODERATE_STAGGER = 124274
	local HEAVY_STAGGER = 124273

	--- Get the remaining amount of damage Stagger will cause to the target.
	-- @name StaggerRemains
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The amount of damage.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if StaggerRemains() / MaxHealth() >0.4 Spell(purifying_brew)

	local function StaggerRemains(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local state = OvaleState.state
		local start, ending, stacks
		start, ending, stacks = state:GetAura(target, HEAVY_STAGGER, "HARMFUL")
		if not stacks or stacks == 0 then
			start, ending, stacks = state:GetAura(target, MODERATE_STAGGER, "HARMFUL")
		end
		if not stacks or stacks == 0 then
			start, ending, stacks = state:GetAura(target, LIGHT_STAGGER, "HARMFUL")
		end
		if start and ending then
			local stagger = API_UnitStagger(target)
			return TestValue(start, ending, 0, ending, -1 * stagger / (ending - start), comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("staggerremains", false, StaggerRemains)
end