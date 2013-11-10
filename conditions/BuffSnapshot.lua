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

	local ParseCondition = OvaleCondition.ParseCondition
	local TestValue = OvaleCondition.TestValue

	local auraFound = {}

	-- Return the value of the stat from the aura snapshot at the time the aura was applied.
	local function BuffSnapshot(statName, defaultValue, condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local state = OvaleState.state
		auraFound[statName] = nil
		local start, ending = state:GetAura(target, auraId, filter, mine, auraFound)
		local value = auraFound[statName]
		value = value and value or defaultValue
		return TestValue(start, ending, value, start, 0, comparator, limit)
	end

	-- Return the value of the given critical strike chance from the aura snapshot at the time the aura was applied.
	local function BuffSnapshotCritChance(statName, defaultValue, condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local state = OvaleState.state
		auraFound[statName] = nil
		local start, ending = state:GetAura(target, auraId, filter, mine, auraFound)
		local value = auraFound[statName]
		value = value and value or defaultValue
		if condition.unlimited ~= 1 and value > 100 then
			value = 100
		end
		return TestValue(start, ending, value, start, 0, comparator, limit)
	end

	--- Get the value of a buff as a number.  Not all buffs return an amount.
	-- @name BuffAmount
	-- @paramsig number
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param value Optional. Sets which aura value to return from UnitAura().
	--     Defaults to value=1.
	--     Valid values: 1, 2, 3.
	-- @return The value of the buff as a number.
	-- @see DebuffAmount
	-- @see TickValue
	-- @usage
	-- if DebuffAmount(stagger) >10000 Spell(purifying_brew)
	-- if DebuffAmount(stagger more 10000) Spell(purifying_brew)

	local function BuffAmount(condition)
		local value = condition.value or 1
		local statName
		if value == 1 then
			statName = "value1"
		elseif value == 2 then
			statName = "value2"
		elseif value == 3 then
			statName = "value3"
		else
			statName = "value1"
		end
		return BuffSnapshot(statName, 0, condition)
	end

	OvaleCondition:RegisterCondition("buffamount", false, BuffAmount)
	OvaleCondition:RegisterCondition("debuffamount", false, BuffAmount)
	OvaleCondition:RegisterCondition("tickvalue", false, BuffAmount)

	--- Get the player's attack power at the time the given aura was applied on the target.
	-- @name BuffAttackPower
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The attack power.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffAttackPower
	-- @usage
	-- if AttackPower() >target.DebuffAttackPower(rake) Spell(rake)

	local function BuffAttackPower(condition)
		return BuffSnapshot("attackPower", 0, condition)
	end

	OvaleCondition:RegisterCondition("buffattackpower", false, BuffAttackPower)
	OvaleCondition:RegisterCondition("debuffattackpower", false, BuffAttackPower)

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
		-- If the buff is presetnt, then it had at least one combo point.
		return BuffSnapshot("comboPoints", 1, condition)
	end

	OvaleCondition:RegisterCondition("buffcombopoints", false, BuffComboPoints)
	OvaleCondition:RegisterCondition("debuffcombopoints", false, BuffComboPoints)

	--- Get the player's mastery effect at the time the given aura was applied on the target.
	-- @name BuffMasteryEffect
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The mastery effect.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffMasteryEffect
	-- @usage
	-- if MasteryEffect() >target.DebuffMasteryEffect(rip) Spell(rip)

	local function BuffMasteryEffect(condition)
		return BuffSnapshot("masteryEffect", 0, condition)
	end

	OvaleCondition:RegisterCondition("buffmastery", false, BuffMasteryEffect)
	OvaleCondition:RegisterCondition("buffmasteryeffect", false, BuffMasteryEffect)
	OvaleCondition:RegisterCondition("debuffmastery", false, BuffMasteryEffect)
	OvaleCondition:RegisterCondition("debuffmasteryeffect", false, BuffMasteryEffect)

	--- Get the player's melee critical strike chance at the time the given aura was applied on the target.
	-- @name BuffMeleeCritChance
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	--     Defaults to unlimited=0.
	--     Valid values: 0, 1
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The critical strike chance.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffMeleeCritChance
	-- @usage
	-- if MeleeCritChance() >target.DebuffMeleeCritChance(rake) Spell(rake)

	local function BuffMeleeCritChance(condition)
		return BuffSnapshotCritChance("meleeCrit", 0, condition)
	end

	OvaleCondition:RegisterCondition("buffmeleecritchance", false, BuffMeleeCritChance)
	OvaleCondition:RegisterCondition("debuffmeleecritchance", false, BuffMeleeCritChance)

	--- Get the player's ranged attack power at the time the given aura was applied on the target.
	-- @name BuffRangedAttackPower
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The ranged attack power.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffRangedAttackPower
	-- @usage
	-- if RangedAttackPower() >target.DebuffRangedAttackPower(serpent_sting_dot)
	--     Spell(serpent_sting)

	local function BuffRangedAttackPower(condition)
		return BuffSnapshot("rangedAttackPower", 0, condition)
	end

	OvaleCondition:RegisterCondition("buffrangedattackpower", false, BuffRangedAttackPower)
	OvaleCondition:RegisterCondition("debuffrangedattackpower", false, BuffRangedAttackPower)

	--- Get the player's ranged critical strike chance at the time the given aura was applied on the target.
	-- @name BuffRangedCritChance
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	--     Defaults to unlimited=0.
	--     Valid values: 0, 1
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The critical strike chance.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffRangedCritChance
	-- @usage
	-- if RangedCritChance() >target.DebuffRangedCritChance(serpent_sting_dot)
	--     Spell(serpent_sting)

	local function BuffRangedCritChance(condition)
		return BuffSnapshotCritChance("rangedCrit", 0, condition)
	end

	OvaleCondition:RegisterCondition("buffrangedcritchance", false, BuffRangedCritChance)
	OvaleCondition:RegisterCondition("debuffrangedcritchance", false, BuffRangedCritChance)

	--- Get the player's spell critical strike chance at the time the given aura was applied on the target.
	-- @name BuffSpellCritChance
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	--     Defaults to unlimited=0.
	--     Valid values: 0, 1
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The critical strike chance.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffSpellCritChance
	-- @usage
	-- if SpellCritChance() >target.DebuffSpellCritChance(moonfire) Spell(moonfire)

	local function BuffSpellCritChance(condition)
		return BuffSnapshotCritChance("spellCrit", 0, condition)
	end

	OvaleCondition:RegisterCondition("buffspellcritchance", false, BuffSpellCritChance)
	OvaleCondition:RegisterCondition("debuffspellcritchance", false, BuffSpellCritChance)

	--- Get the player's spell haste at the time the given aura was applied on the target.
	-- @name BuffSpellHaste
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param id The aura spell ID.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The percent increase to spell haste.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffSpellHaste
	-- @usage
	-- if SpellHaste() >target.DebuffSpellHaste(moonfire) Spell(moonfire)

	local function BuffSpellHaste(condition)
		return BuffSnapshot("spellHaste", 0, condition)
	end

	OvaleCondition:RegisterCondition("buffspellhaste", false, BuffSpellHaste)
	OvaleCondition:RegisterCondition("debuffspellhaste", false, BuffSpellHaste)

	--- Get the player's spellpower at the time the given aura was applied on the target.
	-- @name BuffSpellpower
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The spellpower.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffSpellpower
	-- @usage
	-- if Spellpower() >target.DebuffSpellpower(moonfire) Spell(moonfire)

	local function BuffSpellpower(condition)
		return BuffSnapshot("spellBonusDamage", 0, condition)
	end
	OvaleCondition:RegisterCondition("buffspellpower", false, BuffSpellpower)
	OvaleCondition:RegisterCondition("debuffspellpower", false, BuffSpellpower)
end
