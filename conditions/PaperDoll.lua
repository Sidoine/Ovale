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
	local OvalePaperDoll = Ovale.OvalePaperDoll

	local Compare = OvaleCondition.Compare

	-- Returns the value of the given paper-doll stat.
	local function PaperDoll(statName, defaultValue, condition)
		local comparator, limit = condition[1], condition[2]
		local value = OvalePaperDoll.stat[statName]
		value = value and value or defaultValue
		return Compare(value, comparator, limit)
	end

	-- Returns the critical strike chance of the given paper-doll stat.
	local function PaperDollCritChance(statName, defaultValue, condition)
		local comparator, limit = condition[1], condition[2]
		local value = OvalePaperDoll.stat[statName]
		value = value and value or defaultValue
		if condition.unlimited ~= 1 and value > 100 then
			value = 100
		end
		return Compare(value, comparator, limit)
	end

	--- Get the current agility of the player.
	-- @name Agility
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current agility.
	-- @return A boolean value for the result of the comparison.

	local function Agility(condition)
		return PaperDoll("agility", 0, condition)
	end

	--- Get the current attack power of the player.
	-- @name AttackPower
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current attack power.
	-- @return A boolean value for the result of the comparison.
	-- @see LastAttackPower
	-- @usage
	-- if AttackPower() >10000 Spell(rake)
	-- if AttackPower(more 10000) Spell(rake)

	local function AttackPower(condition)
		return PaperDoll("attackPower", 0, condition)
	end

	--- Get the current intellect of the player.
	-- @name Intellect
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current intellect.
	-- @return A boolean value for the result of the comparison.

	local function Intellect(condition)
		return PaperDoll("intellect", 0, condition)
	end

	--- Get the current mastery effect of the player.
	-- Mastery effect is the effect of the player's mastery, typically a percent-increase to damage
	-- or a percent-increase to chance to trigger some effect.
	-- @name MasteryEffect
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current mastery effect.
	-- @return A boolean value for the result of the comparison.
	-- @see LastMasteryEffect
	-- @usage
	-- if {DamageMultiplier(rake) * {1 + MasteryEffect()/100}} >1.8
	--     Spell(rake)

	local function MasteryEffect(condition)
		return PaperDoll("masteryEffect", 0, condition)
	end

	--- Get the current melee critical strike chance of the player.
	-- @name MeleeCritChance
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	--     Defaults to unlimited=0.
	--     Valid values: 0, 1
	-- @return The current critical strike chance (in percent).
	-- @return A boolean value for the result of the comparison.
	-- @see LastMeleeCritChance
	-- @usage
	-- if MeleeCritChance() >90 Spell(rip)

	local function MeleeCritChance(condition)
		return PaperDollCritChance("meleeCrit", 0, condition)
	end

	--- Get the current ranged critical strike chance of the player.
	-- @name RangedCritChance
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	--     Defaults to unlimited=0.
	--     Valid values: 0, 1
	-- @return The current critical strike chance (in percent).
	-- @return A boolean value for the result of the comparison.
	-- @see LastRangedCritChance
	-- @usage
	-- if RangedCritChance() >90 Spell(serpent_sting)

	local function RangedCritChance(condition)
		return PaperDollCritChance("rangedCrit", 0, condition)
	end

	--- Get the current spell critical strike chance of the player.
	-- @name SpellCritChance
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
	--     Defaults to unlimited=0.
	--     Valid values: 0, 1
	-- @return The current critical strike chance (in percent).
	-- @return A boolean value for the result of the comparison.
	-- @see CritChance, LastSpellCritChance
	-- @usage
	-- if SpellCritChance() >30 Spell(immolate)

	local function SpellCritChance(condition)
		return PaperDollCritChance("spellCrit", 0, condition)
	end

	--- Get the current percent increase to spell haste of the player.
	-- @name SpellHaste
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current percent increase to spell haste.
	-- @return A boolean value for the result of the comparison.
	-- @see BuffSpellHaste
	-- @usage
	-- if SpellHaste() >target.DebuffSpellHaste(moonfire) Spell(moonfire)

	local function SpellHaste(condition)
		return PaperDoll("spellHaste", 0, condition)
	end

	--- Get the current spellpower of the player.
	-- @name Spellpower
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current spellpower.
	-- @return A boolean value for the result of the comparison.
	-- @see LastSpellpower
	-- @usage
	-- if {Spellpower() / LastSpellpower(living_bomb)} >1.25
	--     Spell(living_bomb)

	local function Spellpower(condition)
		return PaperDoll("spellBonusDamage", 0, condition)
	end

	--- Get the current spirit of the player.
	-- @name Spirit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current spirit.
	-- @return A boolean value for the result of the comparison.

	local function Spirit(condition)
		return PaperDoll("spirit", 0, condition)
	end

	--- Get the current stamina of the player.
	-- @name Stamina
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current stamina.
	-- @return A boolean value for the result of the comparison.

	local function Stamina(condition)
		return PaperDoll("stamina", 0, condition)
	end

	--- Get the current strength of the player.
	-- @name Strength
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current strength.
	-- @return A boolean value for the result of the comparison.

	local function Strength(condition)
		return PaperDoll("strength", 0, condition)
	end

	OvaleCondition:RegisterCondition("agility", false, Agility)
	OvaleCondition:RegisterCondition("attackpower", false, AttackPower)
	OvaleCondition:RegisterCondition("intellect", false, Intellect)
	OvaleCondition:RegisterCondition("mastery", false, MasteryEffect)
	OvaleCondition:RegisterCondition("masteryeffect", false, MasteryEffect)
	OvaleCondition:RegisterCondition("meleecritchance", false, MeleeCritChance)
	OvaleCondition:RegisterCondition("rangedcritchance", false, RangedCritChance)
	OvaleCondition:RegisterCondition("spellcritchance", false, SpellCritChance)
	OvaleCondition:RegisterCondition("spellhaste", false, SpellHaste)
	OvaleCondition:RegisterCondition("spellpower", false, Spellpower)
	OvaleCondition:RegisterCondition("spirit", false, Spirit)
	OvaleCondition:RegisterCondition("stamina", false, Stamina)
	OvaleCondition:RegisterCondition("strength", false, Strength)
end

do
	local OvaleScripts = Ovale.OvaleScripts

	local name = "Regression: PaperDoll"
	local code = [[
# Add a separate icon for each paper-doll stat.
# Need to manually verify numbers against the in-game paper-doll.
#
AddIcon help=agility { Agility() }
AddIcon help=attackPower { AttackPower() }
AddIcon help=intellect { Intellect() }
AddIcon help=masteryEffect { MasteryEffect() }
AddIcon help=meleeCrit { MeleeCritChance() }
AddIcon help=rangedCrit { RangedCritChance() }
AddIcon help=spellCrit { SpellCritChance() }
AddIcon help=spellHaste { SpellHaste() }
AddIcon help=spellpower { Spellpower() }
AddIcon help=spirit { Spirit() }
AddIcon help=stamina { Stamina() }
AddIcon help=strength { Strength() }
]]
	OvaleScripts:RegisterScript(nil, name, nil, code, "regression")
end
