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

	--- Get the player's damage multiplier for the given aura at the time the aura was applied on the target.
	-- @name BuffDamageMultiplier
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The damage multiplier.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffDamageMultiplier
	-- @usage
	-- if target.DebuffDamageMultiplier(rake) <1 Spell(rake)

	local function BuffDamageMultiplier(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local state = OvaleState.state
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local start, ending = aura.start, aura.ending
			local baseDamageMultiplier = aura.snapshot and aura.snapshot.baseDamageMultiplier or 1
			local damageMultiplier = aura.damageMultiplier or 1
			local value = baseDamageMultiplier * damageMultiplier
			return TestValue(start, ending, value, start, 0, comparator, limit)
		end
		return Compare(1, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffdamagemultiplier", false, BuffDamageMultiplier)
	OvaleCondition:RegisterCondition("debuffdamagemultiplier", false, BuffDamageMultiplier)
end
