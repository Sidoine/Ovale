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

	--- Get the player's combo points for the given aura at the time the aura was applied on the target.
	-- @name BuffComboPoints
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of combo points.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffComboPoints
	-- @usage
	-- if target.DebuffComboPoints(rip) <5 Spell(rip)

	local function BuffComboPoints(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura) then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			local value = aura and aura.combo or 0
			return TestValue(gain, ending, value, start, 0, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffcombopoints", false, BuffComboPoints)
	OvaleCondition:RegisterCondition("debuffcombopoints", false, BuffComboPoints)
end
