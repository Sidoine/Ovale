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

	-- Return the value of the stat from the snapshot at the time the spell was cast.
	local function LastSnapshot(statName, defaultValue, condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local target = ParseCondition(condition, "target")
		local guid = OvaleGUID:GetGUID(target)
		local value = OvaleFuture:GetLastSpellInfo(guid, spellId, statName)
		value = value and value or defaultValue
		return Compare(value, comparator, limit)
	end

	-- Return the value of the given critical strike chance from the aura snapshot at the time the aura was applied.
	local function LastSnapshotCritChance(statName, defaultValue, condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local target = ParseCondition(condition)
		local guid = OvaleGUID:GetGUID(target)
		local value = OvaleFuture:GetLastSpellInfo(guid, spellId, statName)
		value = value and value or defaultValue
		if condition.unlimited ~= 1 and value > 100 then
			value = 100
		end
		return Compare(value, comparator, limit)
	end

	--- Get the attack power of the player during the most recent cast of a spell on the target.
	-- @name LastAttackPower
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The previous attack power.
	-- @return A boolean value for the result of the comparison.
	-- @see AttackPower
	-- @usage
	-- if {AttackPower() / target.LastAttackPower(hemorrhage)} >1.25
	--     Spell(hemorrhage)

	local function LastAttackPower(condition)
		return LastSnapshot("attackPower", 0, condition)
	end

	OvaleCondition:RegisterCondition("lastattackpower", false, LastAttackPower)
	OvaleCondition:RegisterCondition("lastspellattackpower", false, LastAttackPower)

	--- Get the number of combo points consumed by the most recent cast of a spell on the target for a feral druid or a rogue.
	-- @name LastComboPoints
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The number of combo points.
	-- @return A boolean value for the result of the comparison.
	-- @see ComboPoints
	-- @usage
	-- if ComboPoints() >3 and target.LastComboPoints(rip) <3
	--     Spell(rip)

	local function LastComboPoints(condition)
		return LastSnapshot("comboPoints", 0, condition)
	end

	OvaleCondition:RegisterCondition("lastcombopoints", false, LastComboPoints)
	OvaleCondition:RegisterCondition("lastspellcombopoints", false, LastComboPoints)

	--- Get the mastery effect of the player during the most recent cast of a spell on the target.
	-- Mastery effect is the effect of the player's mastery, typically a percent-increase to damage
	-- or a percent-increase to chance to trigger some effect.
	-- @name LastMastery
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The previous mastery effect.
	-- @return A boolean value for the result of the comparison.
	-- @see Mastery
	-- @usage
	-- if {Mastery(shadow_bolt) - LastMastery(shadow_bolt)} > 1000
	--     Spell(metamorphosis)

	local function LastMasteryEffect(condition)
		return LastSnapshot("masteryEffect", 0, condition)
	end

	OvaleCondition:RegisterCondition("lastmastery", false, LastMasteryEffect)
	OvaleCondition:RegisterCondition("lastmasteryeffect", false, LastMasteryEffect)
	OvaleCondition:RegisterCondition("lastspellmastery", false, LastMasteryEffect)

	--- Get the melee critical strike chance of the player during the most recent cast of a spell on the target.
	-- @name LastMeleeCritChance
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	--     Defaults to unlimited=0.
	--     Valid values: 0, 1
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The previous critical strike chance.
	-- @return A boolean value for the result of the comparison.
	-- @see MeleeCritChance
	-- @usage
	-- if MeleeCritChance() > target.LastMeleeCritChance(rip)
	--     Spell(rip)

	local function LastMeleeCritChance(condition)
		return LastSnapshotCritChance("meleeCrit", 0, condition)
	end

	OvaleCondition:RegisterCondition("lastmeleecritchance", false, LastMeleeCritChance)
	OvaleCondition:RegisterCondition("lastspellmeleecritchance", false, LastMeleeCritChance)

	--- Get the ranged critical strike chance of the player during the most recent cast of a spell on the target.
	-- @name LastRangedCritChance
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	--     Defaults to unlimited=0.
	--     Valid values: 0, 1
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The previous critical strike chance.
	-- @return A boolean value for the result of the comparison.
	-- @see RangedCritChance
	-- @usage
	-- if RangedCritChance() > target.LastRangedCritChance(serpent_sting_dot)
	--     Spell(serpent_sting)

	local function LastRangedCritChance(condition)
		return LastSnapshotCritChance("rangedCrit", 0, condition)
	end

	OvaleCondition:RegisterCondition("lastrangedcritchance", false, LastRangedCritChance)
	OvaleCondition:RegisterCondition("lastspellrangedcritchance", false, LastRangedCritChance)

	--- Get the spell critical strike chance of the player during the most recent cast of a spell on the target.
	-- @name LastSpellCritChance
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	--     Defaults to unlimited=0.
	--     Valid values: 0, 1
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The previous critical strike chance.
	-- @return A boolean value for the result of the comparison.
	-- @see SpellCritChance
	-- @usage
	-- if SpellCritChance() > target.LastSpellCritChance(shadow_bolt)
	--     Spell(metamorphosis)

	local function LastSpellCritChance(condition)
		return LastSnapshotCritChance("spellCrit", 0, condition)
	end

	OvaleCondition:RegisterCondition("lastspellcritchance", false, LastSpellCritChance)
	OvaleCondition:RegisterCondition("lastspellspellcritchance", false, LastSpellCritChance)

	--- Get the spellpower of the player during the most recent cast of a spell on the target.
	-- @name LastSpellpower
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The previous spellpower.
	-- @return A boolean value for the result of the comparison.
	-- @see Spellpower
	-- @usage
	-- if {Spellpower() / target.LastSpellpower(living_bomb)} >1.25
	--     Spell(living_bomb)

	local function LastSpellpower(condition)
		return LastSnapshot("spellBonusDamage", 0, condition)
	end

	OvaleCondition:RegisterCondition("lastspellpower", false, LastSpellpower)
	OvaleCondition:RegisterCondition("lastspellspellpower", false, LastSpellpower)
end
