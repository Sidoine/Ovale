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
	local OvaleGUID = Ovale.OvaleGUID
	local OvaleFuture = Ovale.OvaleFuture

	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition

	--- Get the damage multiplier of the most recent cast of a spell on the target.
	-- This currently does not take into account increased damage due to mastery.
	-- @name LastDamageMultiplier
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The previous damage multiplier.
	-- @return A boolean value for the result of the comparison.
	-- @see DamageMultiplier
	-- @usage
	-- if {DamageMultiplier(rupture) / target.LastDamageMultiplier(rupture)} >1.1
	--     Spell(rupture)

	local function LastDamageMultiplier(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local target = ParseCondition(condition, "target")
		local guid = OvaleGUID:GetGUID(target)
		local bdm = OvaleFuture:GetLastSpellInfo(guid, spellId, "baseDamageMultiplier") or 1
		local dm = OvaleFuture:GetLastSpellInfo(guid, spellId, "damageMultiplier") or 1
		local value = bdm * dm
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("lastdamagemultiplier", false, LastDamageMultiplier)
	OvaleCondition:RegisterCondition("lastspelldamagemultiplier", false, LastDamageMultiplier)
end
