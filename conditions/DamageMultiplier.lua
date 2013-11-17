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

	--- Get the current damage multiplier of a spell.
	-- This currently does not take into account increased damage due to mastery.
	-- @name DamageMultiplier
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current damage multiplier of the given spell.
	-- @return A boolean value for the result of the comparison.
	-- @see LastDamageMultiplier
	-- @usage
	-- if {DamageMultiplier(rupture) / LastDamageMultiplier(rupture)} >1.1
	--     Spell(rupture)

	local function DamageMultiplier(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local state = OvaleState.state
		local bdm = state.snapshot.baseDamageMultiplier
		local dm = state:GetDamageMultiplier(spellId)
		local value = bdm * dm
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("damagemultiplier", false, DamageMultiplier)
end
