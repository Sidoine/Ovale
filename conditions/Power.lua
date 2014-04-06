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
	local OvalePower = Ovale.OvalePower
	local OvaleState = Ovale.OvaleState

	local API_UnitPower = UnitPower
	local API_UnitPowerMax = UnitPowerMax
	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition
	local TestValue = OvaleCondition.TestValue
	local state = OvaleState.state

	-- Return the maximum power of the given power type on the target.
	local function MaxPower(powerType, condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local value
		if target == "player" then
			value = OvalePower.maxPower[powerType]
		else
			local powerInfo = OvalePower.POWER_INFO[powerType]
			value = API_UnitPowerMax(target, powerInfo.id, powerInfo.segments)
		end
		return Compare(value, comparator, limit)
	end

	-- Return the amount of power of the given power type on the target.
	local function Power(powerType, condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		if target == "player" then
			local value, origin, rate = state[powerType], state.currentTime, state.powerRate[powerType]
			local start, ending = state.currentTime, math.huge
			return TestValue(start, ending, value, origin, rate, comparator, limit)
		else
			local powerInfo = OvalePower.POWER_INFO[powerType]
			local value = API_UnitPower(target, powerInfo.id)
			return Compare(value, comparator, limit)
		end
	end

	--- Return the current percent level of power (between 0 and 100) on the target.
	local function PowerPercent(powerType, condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		if target == "player" then
			local powerMax = OvalePower.maxPower[powerType] or 0
			if powerMax > 0 then
				local conversion = 100 / powerMax
				local value, origin, rate = state[powerType] * conversion, state.currentTime, state.powerRate[powerType] * conversion
				local start, ending = state.currentTime, math.huge
				return TestValue(start, ending, value, origin, rate, comparator, limit)
			end
		else
			local powerInfo = OvalePower.POWER_INFO[powerType]
			local powerMax = API_UnitPowerMax(target, powerInfo.id, powerInfo.segments) or 0
			if powerMax > 0 then
				local conversion = 100 / powerMax
				local value = API_UnitPower(target, powerInfo.id) * conversion
				return Compare(value, comparator, limit)
			end
		end
		return Compare(0, comparator, limit)
	end

	--- Get the current amount of alternate power displayed on the alternate power bar.
	-- @name AlternatePower
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current alternate power.
	-- @return A boolean value for the result of the comparison.

	local function AlternatePower(condition)
		return Power("alternate", condition)
	end

	--- Get the current number of Burning Embers for destruction warlocks.
	-- @name BurningEmbers
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of Burning Embers.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if BurningEmbers() >10 Spell(chaos_bolt)
	-- if BurningEmbers(more 10) Spell(chaos_bolt)

	local function BurningEmbers(condition)
		return Power("burningembers", condition)
	end

	--- Get the current amount of stored Chi for monks.
	-- @name Chi
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of stored Chi.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Chi() ==4 Spell(chi_burst)
	-- if Chi(more 3) Spell(chi_burst)

	local function Chi(condition)
		return Power("chi", condition)
	end

	--- Get the current amount of demonic fury for demonology warlocks.
	-- @name DemonicFury
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of demonic fury.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if DemonicFury() >=1000 Spell(metamorphosis)
	-- if DemonicFury(more 999) Spell(metamorphosis)

	local function DemonicFury(condition)
		return Power("demonicfury", condition)
	end

	--- Get the current amount of energy for feral druids, non-mistweaver monks, and rogues.
	-- @name Energy
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current energy.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Energy() >70 Spell(vanish)
	-- if Energy(more 70) Spell(vanish)

	local function Energy(condition)
		return Power("energy", condition)
	end

	--- Get the current amount of focus for hunters.
	-- @name Focus
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current focus.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Focus() >70 Spell(arcane_shot)
	-- if Focus(more 70) Spell(arcane_shot)

	local function Focus(condition)
		return Power("focus", condition)
	end

	--- Get the current amount of holy power for a paladin.
	-- @name HolyPower
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of holy power.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if HolyPower() >=3 Spell(word_of_glory)
	-- if HolyPower(more 2) Spell(word_of_glory)

	local function HolyPower(condition)
		return Power("holy", condition)
	end

	--- Get the current level of mana of the target.
	-- @name Mana
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current mana.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if {MaxMana() - Mana()} > 12500 Item(mana_gem)

	local function Mana(condition)
		return Power("mana", condition)
	end

	--- Get the current amount of rage for guardian druids and warriors.
	-- @name Rage
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current rage.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Rage() >70 Spell(heroic_strike)
	-- if Rage(more 70) Spell(heroic_strike)

	local function Rage(condition)
		return Power("rage", condition)
	end

	--- Get the current amount of runic power for death knights.
	-- @name RunicPower
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current runic power.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if RunicPower() >70 Spell(frost_strike)
	-- if RunicPower(more 70) Spell(frost_strike)

	local function RunicPower(condition)
		return Power("runicpower", condition)
	end

	--- Get the current number of Shadow Orbs for shadow priests.
	-- @name ShadowOrbs
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of Shadow Orbs.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if ShadowOrbs() >2 Spell(mind_blast)
	-- if ShadowOrbs(more 2) Spell(mind_blast)

	local function ShadowOrbs(condition)
		return Power("shadoworbs", condition)
	end

	--- Get the current number of Soul Shards for warlocks.
	-- @name SoulShards
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of Soul Shards.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if SoulShards() >0 Spell(summon_felhunter)
	-- if SoulShards(more 0) Spell(summon_felhunter)

	local function SoulShards(condition)
		return Power("shards", condition)
	end

	OvaleCondition:RegisterCondition("alternatepower", false, AlternatePower)
	OvaleCondition:RegisterCondition("burningembers", false, BurningEmbers)
	OvaleCondition:RegisterCondition("chi", false, Chi)
	OvaleCondition:RegisterCondition("demonicfury", false, DemonicFury)
	OvaleCondition:RegisterCondition("energy", false, Energy)
	OvaleCondition:RegisterCondition("focus", false, Focus)
	OvaleCondition:RegisterCondition("holypower", false, HolyPower)
	OvaleCondition:RegisterCondition("mana", false, Mana)
	OvaleCondition:RegisterCondition("rage", false, Rage)
	OvaleCondition:RegisterCondition("runicpower", false, RunicPower)
	OvaleCondition:RegisterCondition("shadoworbs", false, ShadowOrbs)
	OvaleCondition:RegisterCondition("soulshards", false, SoulShards)

	--- Get the current percent level of mana (between 0 and 100) of the target.
	-- @name ManaPercent
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current mana percent.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if ManaPercent() >90 Spell(arcane_blast)
	-- if ManaPercent(more 90) Spell(arcane_blast)

	local function ManaPercent(condition)
		return PowerPercent("mana", condition)
	end

	OvaleCondition:RegisterCondition("manapercent", false, ManaPercent)

	--- Get the maximum amount of alternate power of the target.
	-- Alternate power is the resource tracked by the alternate power bar in certain boss fights.
	-- @name MaxAlternatePower
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum value.
	-- @return A boolean value for the result of the comparison.

	local function MaxAlternatePower(condition)
		return MaxPower("alternate", condition)
	end

	--- Get the maximum amount of burning embers of the target.
	-- @name MaxBurningEmbers
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum value.
	-- @return A boolean value for the result of the comparison.

	local function MaxBurningEmbers(condition)
		return MaxPower("burningembers", condition)
	end

	--- Get the maximum amount of Chi of the target.
	-- @name MaxChi
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum value.
	-- @return A boolean value for the result of the comparison.

	local function MaxChi(condition)
		return MaxPower("chi", condition)
	end

	--- Get the maximum amount of Demonic Fury of the target.
	-- @name MaxDemonicFury
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum value.
	-- @return A boolean value for the result of the comparison.

	local function MaxDemonicFury(condition)
		return MaxPower("demonicfury", condition)
	end

	--- Get the maximum amount of energy of the target.
	-- @name MaxEnergy
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum value.
	-- @return A boolean value for the result of the comparison.

	local function MaxEnergy(condition)
		return MaxPower("energy", condition)
	end

	--- Get the maximum amount of focus of the target.
	-- @name MaxFocus
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum value.
	-- @return A boolean value for the result of the comparison.

	local function MaxFocus(condition)
		return MaxPower("focus", condition)
	end

	--- Get the maximum amount of Holy Power of the target.
	-- @name MaxHolyPower
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum value.
	-- @return A boolean value for the result of the comparison.

	local function MaxHolyPower(condition)
		return MaxPower("holy", condition)
	end

	--- Get the maximum amount of mana of the target.
	-- @name MaxMana
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum value.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if {MaxMana() - Mana()} > 12500 Item(mana_gem)

	local function MaxMana(condition)
		return MaxPower("mana", condition)
	end

	--- Get the maximum amount of rage of the target.
	-- @name MaxRage
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum value.
	-- @return A boolean value for the result of the comparison.

	local function MaxRage(condition)
		return MaxPower("rage", condition)
	end

	--- Get the maximum amount of Runic Power of the target.
	-- @name MaxRunicPower
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum value.
	-- @return A boolean value for the result of the comparison.

	local function MaxRunicPower(condition)
		return MaxPower("runicpower", condition)
	end

	--- Get the maximum amount of Shadow Orbs of the target.
	-- @name MaxShadowOrbs
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum value.
	-- @return A boolean value for the result of the comparison.

	local function MaxShadowOrbs(condition)
		return MaxPower("shadoworbs", condition)
	end

	--- Get the maximum amount of Soul Shards of the target.
	-- @name MaxSoulShards
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum value.
	-- @return A boolean value for the result of the comparison.

	local function MaxSoulShards(condition)
		return MaxPower("shards", condition)
	end

	OvaleCondition:RegisterCondition("maxalternatepower", false, MaxAlternatePower)
	OvaleCondition:RegisterCondition("maxburningembers", false, MaxBurningEmbers)
	OvaleCondition:RegisterCondition("maxchi", false, MaxChi)
	OvaleCondition:RegisterCondition("maxdemonicfury", false, MaxDemonicFury)
	OvaleCondition:RegisterCondition("maxenergy", false, MaxEnergy)
	OvaleCondition:RegisterCondition("maxfocus", false, MaxFocus)
	OvaleCondition:RegisterCondition("maxholypower", false, MaxHolyPower)
	OvaleCondition:RegisterCondition("maxmana", false, MaxMana)
	OvaleCondition:RegisterCondition("maxrage", false, MaxRage)
	OvaleCondition:RegisterCondition("maxrunicpower", false, MaxRunicPower)
	OvaleCondition:RegisterCondition("maxshadoworbs", false, MaxShadowOrbs)
	OvaleCondition:RegisterCondition("maxsoulshards", false, MaxSoulShards)
end
