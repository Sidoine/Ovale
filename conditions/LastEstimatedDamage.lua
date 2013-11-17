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
	local OvaleData = Ovale.OvaleData
	local OvaleGUID = Ovale.OvaleGUID
	local OvaleFuture = Ovale.OvaleFuture

	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition

	--- Get the estimated damage of the most recent cast of the player's spell on the target.
	-- The calculated damage takes into account the values of attack power, spellpower, weapon damage and combo points (if used)
	-- at the time the spell was most recent cast.
	-- The damage is computed from information for the spell set via SpellInfo(...):
	--
	-- damage = base + bonusmainhand * MH + bonusoffhand * OH + bonusap * AP + bonuscp * CP + bonusapcp * AP * CP + bonussp * SP
	-- @name LastEstimatedDamage
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The estimated damage of the most recent cast of the given spell by the player.
	-- @return A boolean value for the result of the comparison.
	-- @see Damage, LastDamage
	-- @usage
	-- if {Damage(rake) / target.LastEstimateDamage(rake)} >1.1
	--     Spell(rake)

	local function LastEstimatedDamage(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local target = ParseCondition(condition, "target")
		local guid = OvaleGUID:GetGUID(target)
		local ap = OvaleFuture:GetLastSpellInfo(guid, spellId, "attackPower") or 0
		local sp = OvaleFuture:GetLastSpellInfo(guid, spellId, "spellBonusDamage") or 0
		local mh = OvaleFuture:GetLastSpellInfo(guid, spellId, "mainHandWeaponDamage") or 0
		local oh = OvaleFuture:GetLastSpellInfo(guid, spellId, "offHandWeaponDamage") or 0
		local combo = OvaleFuture:GetLastSpellInfo(guid, spellId, "combo") or 0
		local bdm = OvaleFuture:GetLastSpellInfo(guid, spellId, "baseDamageMultiplier") or 1
		local dm = OvaleFuture:GetLastSpellInfo(guid, spellId, "damageMultiplier") or 1
		local value = OvaleData:GetDamage(spellId, ap, sp, mh, oh, combo) * bdm * dm
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("lastestimateddamage", false, LastEstimatedDamage)
	OvaleCondition:RegisterCondition("lastspellestimateddamage", false, LastEstimatedDamage)
end