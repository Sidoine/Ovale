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

	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition
	local TestValue = OvaleCondition.TestValue
	local state = OvaleState.state

	--- Get the number of stacks of an aura on the target.
	-- @name BuffStacks
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of stacks of the aura.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffStacks
	-- @usage
	-- if BuffStacks(pet_frenzy any=1) ==5
	--     Spell(focus_fire)
	-- if target.DebuffStacks(weakened_armor) <3
	--     Spell(faerie_fire)

	local function BuffStacks(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura) then
			local start, ending = aura.start, aura.ending
			local value = aura.stacks or 0
			return TestValue(start, ending, value, start, 0, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffstacks", false, BuffStacks)
	OvaleCondition:RegisterCondition("debuffstacks", false, BuffStacks)
end
