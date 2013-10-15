--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleCondition = {}
Ovale.OvaleCondition = OvaleCondition

--<private-static-properties>
local LBCT = LibStub("LibBabble-CreatureType-3.0"):GetLookupTable()
local LRC = LibStub("LibRangeCheck-2.0", true)
local OvaleAura = Ovale.OvaleAura
local OvaleBestAction = nil	-- forward declaration
local OvaleCompile = nil	-- forward declaration
local OvaleDamageTaken = Ovale.OvaleDamageTaken
local OvaleData = Ovale.OvaleData
local OvaleEnemies = Ovale.OvaleEnemies
local OvaleEquipement = Ovale.OvaleEquipement
local OvaleFuture = Ovale.OvaleFuture
local OvaleGUID = Ovale.OvaleGUID
local OvaleLatency = Ovale.OvaleLatency
local OvalePaperDoll = Ovale.OvalePaperDoll
local OvalePower = Ovale.OvalePower
local OvaleSpellBook = Ovale.OvaleSpellBook
local OvaleSpellDamage = Ovale.OvaleSpellDamage
local OvaleStance = Ovale.OvaleStance
local OvaleState = Ovale.OvaleState
local OvaleSwing = Ovale.OvaleSwing

local floor = floor
local pairs = pairs
local select = select
local tostring = tostring
local wipe = table.wipe
local API_GetBuildInfo = GetBuildInfo
local API_GetItemCooldown = GetItemCooldown
local API_GetItemCount = GetItemCount
local API_GetNumTrackingTypes = GetNumTrackingTypes
local API_GetSpellCharges = GetSpellCharges
local API_GetSpellInfo = GetSpellInfo
local API_GetTotemInfo = GetTotemInfo
local API_GetTrackingInfo = GetTrackingInfo
local API_GetUnitSpeed = GetUnitSpeed
local API_GetWeaponEnchantInfo = GetWeaponEnchantInfo
local API_HasFullControl = HasFullControl
local API_IsHarmfulSpell = IsHarmfulSpell
local API_IsHelpfulSpell = IsHelpfulSpell
local API_IsSpellInRange = IsSpellInRange
local API_IsStealthed = IsStealthed
local API_IsUsableSpell = IsUsableSpell
local API_UnitCastingInfo = UnitCastingInfo
local API_UnitChannelInfo = UnitChannelInfo
local API_UnitClass = UnitClass
local API_UnitClassification = UnitClassification
local API_UnitCreatureFamily = UnitCreatureFamily
local API_UnitCreatureType = UnitCreatureType
local API_UnitDebuff = UnitDebuff
local API_UnitDetailedThreatSituation = UnitDetailedThreatSituation
local API_UnitExists = UnitExists
local API_UnitHealth = UnitHealth
local API_UnitHealthMax = UnitHealthMax
local API_UnitIsDead = UnitIsDead
local API_UnitIsFriend = UnitIsFriend
local API_UnitIsPVP = UnitIsPVP
local API_UnitIsUnit = UnitIsUnit
local API_UnitLevel = UnitLevel
local API_UnitPower = UnitPower
local API_UnitPowerMax = UnitPowerMax
local API_UnitStagger = UnitStagger
local SPELL_POWER_MANA = SPELL_POWER_MANA

-- static property for GetRunesCooldown(), indexed by rune name
local self_runes = {}

-- static properties for TimeToDie(), indexed by unit ID
local self_lastTTDTime = {}
local self_lastTTDHealth = {}
local self_lastTTDguid = {}
local self_lastTTDdps = {}

-- static property for conditions that use GetAura()
local self_auraFound = {}

local OVALE_RUNETYPE =
{
	blood = 1,
	unholy = 2,
	frost = 3,
	death = 4
}	

local OVALE_TOTEMTYPE =
{
	-- Death Knights
	ghoul = 1,
	-- Monks
	statue = 1,
	-- Shamans
	fire = 1,
	earth = 2,
	water = 3,
	air = 4
}

local DEFAULT_CRIT_CHANCE = 0.01
--</private-static-properties>

--<private-static-methods>
local function IsSameSpell(spellIdA, spellIdB, spellNameB)
	if spellIdB then
		return spellIdA == spellIdB
	elseif spellIdA and spellNameB then
		return OvaleSpellBook:GetSpellName(spellIdA) == spellNameB
	else
		return false
	end
end

local function TimeWithHaste(time1, haste)
	if not time1 then
		time1 = 0
	end
	if not haste then
		return time1
	elseif haste == "spell" then
		return time1 / OvalePaperDoll:GetSpellHasteMultiplier()
	elseif haste == "melee" then
		return time1 / OvalePaperDoll:GetMeleeHasteMultiplier()
	else
		Ovale:Logf("Unknown haste parameter haste=%s", haste)
		return time1
	end
end

local function Compare(a, comparison, b)
	if not comparison then
		return 0, math.huge, a, 0, 0 -- this is not a compare, returns the value a
	elseif comparison == "more" then
		if not b or (a and a > b) then
			return 0, math.huge
		else
			return nil
		end
	elseif comparison == "equal" then
		if b == a then
			return 0, math.huge
		else
			return nil
		end
	elseif comparison == "less" then
		if not a or (b and a < b) then
			return 0, math.huge
		else
			return nil
		end
	else
		Ovale:Errorf("unknown compare term %s (should be more, equal, or less)", comparison)
	end
end

local function TestBoolean(a, condition)
	if condition == "yes" or not condition then
		if a then
			return 0, math.huge
		else
			return nil
		end
	else
		if not a then
			return 0, math.huge
		else
			return nil
		end
	end
end

local function TestValue(comparator, limit, value, atTime, rate)
	if not value or not atTime then
		return nil
	elseif not comparator then
		return 0, math.huge, value, atTime, rate
	else
		local start, ending = 0, math.huge
		if comparator == "more" and rate == 0 then
			if value <= limit then return nil end
		elseif comparator == "less" and rate == 0 then
			if value >= limit then return nil end
		elseif (comparator == "more" and rate > 0) or (comparator == "less" and rate < 0) then
			start = (limit - value)/rate + atTime
		elseif (comparator == "more" and rate < 0) or (comparator == "less" and rate > 0) then
			ending = (limit - value)/rate + atTime
		else
			Ovale:Errorf("Unknown operator %s", comparator)
			return nil
		end
		return start, ending
	end
end

local function GetFilter(condition)
	if condition.filter then
		if condition.filter == "debuff" then
			return "HARMFUL"
		elseif condition.filter == "buff" then
			return "HELPFUL"
		end
	end
	return nil
end

local function GetMine(condition)
	if condition.any then
		if condition.any == 1 then
			return false
		else
			return true
		end
	elseif condition.mine then
		-- Use of "mine=1" is deprecated.
		if condition.mine == 1 then
			return true
		else
			return false
		end
	end
	return true
end

local function GetTarget(condition, defaultTarget)
	local target = condition.target
	defaultTarget = defaultTarget or "player"
	if not target then
		return defaultTarget
	elseif target == "target" then
		return OvaleCondition.defaultTarget
	else
		return target
	end
end

local function GetRuneCount(type, death)
	local ret = 0
	local atTime = nil
	local rate = nil
	type = OVALE_RUNETYPE[type]
	for i=1,6 do
		local rune = OvaleState.state.rune[i]
		if rune and (rune.type == type or (rune.type == 4 and death==1)) then
			if rune.cd > OvaleState.currentTime then
				if not atTime or rune.cd < atTime then
					atTime = rune.cd
					rate = 1/rune.duration
				end
			else
				ret = ret + 1
			end
		end
	end
	if atTime then
		return ret + 1, atTime, rate
	else
		return ret, 0, 0
	end
end

local function GetRunesCooldown(condition)
	for k in pairs(OVALE_RUNETYPE) do
		self_runes[k] = 0
	end

	local k = 1
	while true do
		local type = condition[2 * k - 1]
		if not OVALE_RUNETYPE[type] then break end
		self_runes[type] = self_runes[type] + condition[2 * k]
		k = k + 1
	end
	return OvaleState:GetRunesCooldown(self_runes.blood, self_runes.frost, self_runes.unholy, self_runes.death, condition.nodeath)
end

-- Front-end for OvaleState:GetAura() using condition parameters.
-- return start, ending, stacks, gain
local function GetAura(condition, auraFound)
	local unitId = GetTarget(condition)
	local spellId = condition[1]
	local filter = GetFilter(condition)
	local mine = GetMine(condition)

	if not spellId then
		Ovale:Log("GetAura: nil spellId")
		return nil
	end
	local start, ending, stacks, gain = OvaleState:GetAura(unitId, spellId, filter, mine, auraFound)

	if not start then
		Ovale:Logf("GetAura: aura %s not found on %s filter=%s mine=%s", spellId, unitId, filter, mine)
		return nil
	end
	local conditionStacks = condition.stacks or 1
	if stacks and stacks < conditionStacks then
		Ovale:Logf("GetAura: aura %s found on %s but stacks %d < %d", spellId, unitId, stacks, conditionStacks)
		return nil
	end
	Ovale:Logf("GetAura: aura %s found on %s start=%s ending=%s stacks=%s/%d", spellId, unitId, start, ending, stacks, conditionStacks)
	return start, ending, stacks, gain
end

-- Front-end for OvaleState:GetAuraOnAnyTarget() using condition parameters.
-- return start, ending, count
local function GetAuraOnAnyTarget(condition, excludingUnit)
	local spellId = condition[1]
	local filter = GetFilter(condition)
	local mine = GetMine(condition)
	if excludingUnit then
		excludingUnit = OvaleGUID:GetGUID(excludingUnit)
	end
	if not spellId then
		Ovale:Log("GetAura: nil spellId")
		return nil
	end
	local start, ending, count = OvaleState:GetAuraOnAnyTarget(spellId, filter, mine, excludingUnit)

	if not start then
		Ovale:Logf("GetAuraOnAnyTarget: aura %s not found, filter=%s mine=%s excludingUnit=%s", spellId, filter, mine, excludingUnit)
		return nil
	end
	Ovale:Logf("GetAuraOnAnyTarget: aura %s found, start=%s ending=%s count=%d", spellId, start, ending, stacks, count)
	return start, ending, count
end

-- Returns:
--     Estimated number of seconds before the specified unit reaches zero health
--     Unit's current health
--     Unit's maximum health
local function TimeToDie(unitId)
	if self_lastTTDguid[unitId] ~= OvaleGUID:GetGUID(unitId) then
		self_lastTTDguid[unitId] = OvaleGUID:GetGUID(unitId)
		self_lastTTDTime[unitId] = nil
		if self_lastTTDHealth[unitId] then
			wipe(self_lastTTDHealth[unitId])
		else
			self_lastTTDHealth[unitId] = {}
		end
		self_lastTTDdps[unitId] = nil
	end
	local timeToDie
	local health = API_UnitHealth(unitId)
	local maxHealth = API_UnitHealthMax(unitId) or 1
	if health then
		Ovale:Logf("target = %s, health = %d, maxHealth = %d", self_lastTTDguid[unitId], health, maxHealth)
	end
	if maxHealth < health then
		maxHealth = health
	end
	-- Clamp maxHealth to always be at least 1.
	if maxHealth < 1 then
		maxHealth = 1
	end
	if health == 0 then
		timeToDie = 0
	elseif maxHealth <= 2 then
		Ovale:Log("Training Dummy, return in the future")
		timeToDie = 3600
	else
		local now = floor(OvaleState.maintenant)
		if (not self_lastTTDTime[unitId] or self_lastTTDTime[unitId] < now) and self_lastTTDguid[unitId] then
			self_lastTTDTime[unitId] = now
			local mod10, prevHealth
			for delta = 10, 1, -1 do
				mod10 = (now - delta) % 10
				prevHealth = self_lastTTDHealth[unitId][mod10]
				if delta == 10 then
					self_lastTTDHealth[unitId][mod10] = health
				end
				if prevHealth and prevHealth > health then
					self_lastTTDdps[unitId] = (prevHealth - health) / delta
					Ovale:Logf("prevHealth = %d, health = %d, delta = %d, dps = %d", prevHealth, health, delta, self_lastTTDdps[unitId])
					break
				end
			end
		end
		-- Clamp timeToDie at under 3600 to avoid integer division overflow.
		local dps = self_lastTTDdps[unitId]
		if dps and dps > health / 3600 then
			timeToDie = health / dps
		else
			timeToDie = 3600
		end
	end
	return timeToDie, health, maxHealth
end

local function ComputeFunctionParam(spellId, paramName)
	local si = OvaleData.spellInfo[spellId]
	if si and si[paramName] then
		-- Resolve forward declarations.
		OvaleBestAction = OvaleBestAction or Ovale.OvaleBestAction
		OvaleCompile = OvaleCompile or Ovale.OvaleCompile
		if OvaleBestAction and OvaleCompile then
			local element = OvaleCompile:GetFunctionNode(si[paramName])
			if element then
				local element = select(4, OvaleBestAction:Compute(element))
				local element = element.result
				if element and element.type == "value" then
					return element.value, element.origin, element.rate
				end
			end
			return 0, 0, 0
		end
	end
	return nil
end
--</private-static-methods>

--<public-static-properties>

-- The actual target referenced when the "target" parameter is used in a condition.
-- This is to support setting a different target in an AddIcon "target" parameter,
-- e.g., target=focus, while re-using the same script.
OvaleCondition.defaultTarget = "target"

--[[----------------------------------------------------------------------------
	Script conditions.

	A script condition must have a name that is lowercase.  Script function
	names are always converted to lowercase before comparing against the
	conditions in the OvaleCondition.conditions table.

	A script condition can return in two different ways:

	(1) start, ending
		This returns a time interval representing when the condition is true
		and is used by conditions that return only a time interval.

	(2) start, ending, value, origin, rate
		This returns a function f(t) = value + (t - origin) * rate that is
		valid for start < t < ending.  This return method is used by
		conditions that return a value that is used in numerical comparisons
		or operations.

	The endpoint of a time interval must be between 0 and infinity, where
	infinity is represented by math.huge.  Time is a value such as returned by
	the API function GetTime().

	Examples:

	(1)	(0, math.huge) means the condition is always true.

	(2)	nil is the empty set and means the condition is always false.

	(3)	(0, math.huge, constant, 0, 0) means the condition has a constant value.

	(4)	(start, ending, ending - start, start, -1) means the condition has a
		value of f(t) = ending - t, at time t between start and ending.  This
		basically returns how much time is left within the time interval.
--]]----------------------------------------------------------------------------

OvaleCondition.conditions = {}
-- List of script conditions that refer to a castable spell from the player's spellbook.
OvaleCondition.spellbookConditions = {}

do
	-- Spell(spellId) can be used as a condition instead of an action.
	OvaleCondition.spellbookConditions.spell = true
end

	-- Test if a white hit just occured
	-- 1 : maximum time after a white hit
	-- Not useful anymore. No widely used spell reset swing timer anyway
	--[[AfterWhiteHit = function(condition)
		local debut = OvaleSwing.starttime
		local fin = OvaleSwing.duration + debut
		local maintenant = API_GetTime()
		if (maintenant-debut<condition[1]) then
			return 0
		elseif (maintenant<fin-0.1) then
			return fin-maintenant
		else 
			return 0.1
		end 
	end,]]

--- Get how many pieces of an armor set, e.g., Tier 14 set, are equipped by the player.
-- @name ArmorSetParts
-- @paramsig number or boolean
-- @param name The name of the armor set.
--     Valid names: T11, T12, T13, T14, T15.
--     Valid names for hybrid classes: append _caster, _heal, _melee, _tank.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of pieces of the named set that are equipped by the player.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if ArmorSetParts(T13) >=2 and target.HealthPercent() <60
--     Spell(ferocious_bite)
-- if ArmorSetParts(T13 more 1) and TargetHealthPercent(less 60)
--     Spell(ferocious_bite)

OvaleCondition.conditions.armorsetparts = function(condition)
	return Compare(OvaleEquipement:GetArmorSetCount(condition[1]), condition[2], condition[3])
end

--- Get the current attack power of the player.
-- @name AttackPower
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The current attack power.
-- @return A boolean value for the result of the comparison.
-- @see LastAttackPower
-- @usage
-- if AttackPower() >10000 Spell(rake)
-- if AttackPower(more 10000) Spell(rake)

OvaleCondition.conditions.attackpower = function(condition)
	return Compare(OvalePaperDoll.stat.attackPower, condition[1], condition[2])
end

--- Get the player's attack power at the time the given aura was applied on the target.
-- @name BuffAttackPower
-- @paramsig number
-- @param id The aura spell ID.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The attack power.
-- @see DebuffAttackPower
-- @usage
-- if AttackPower() >target.DebuffAttackPower(rake) Spell(rake)

OvaleCondition.conditions.buffattackpower = function(condition)
	self_auraFound.attackPower = nil
	local start, ending = GetAura(condition, self_auraFound)
	local attackPower = self_auraFound.attackPower or 0
	if start and ending and start <= ending then
		return start, ending, attackPower, start, 0
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.conditions.debuffattackpower = OvaleCondition.conditions.buffattackpower

--- Get the player's ranged attack power at the time the given aura was applied on the target.
-- @name BuffRangedAttackPower
-- @paramsig number
-- @param id The aura spell ID.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The ranged attack power.
-- @see DebuffRangedAttackPower
-- @usage
-- if RangedAttackPower() >target.DebuffRangedAttackPower(serpent_sting_dot)
--     Spell(serpent_sting)

OvaleCondition.conditions.buffrangedattackpower = function(condition)
	self_auraFound.rangedAttackPower = nil
	local start, ending = GetAura(condition, self_auraFound)
	local rangedAttackPower = self_auraFound.rangedAttackPower or 0
	if start and ending and start <= ending then
		return start, ending, rangedAttackPower, start, 0
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.conditions.debuffrangedattackpower = OvaleCondition.conditions.buffrangedattackpower

--- Get the player's combo points for the given aura at the time the aura was applied on the target.
-- @name BuffComboPoints
-- @paramsig number
-- @param id The aura spell ID.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The number of combo points.
-- @see DebuffComboPoints
-- @usage
-- if target.DebuffComboPoints(rip) <5 Spell(rip)

OvaleCondition.conditions.buffcombopoints = function(condition)
	self_auraFound.comboPoints = nil
	local start, ending = GetAura(condition, self_auraFound)
	local comboPoints = self_auraFound.comboPoints or 1
	if start and ending and start <= ending then
		return start, ending, comboPoints, start, 0
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.conditions.debuffcombopoints = OvaleCondition.conditions.buffcombopoints

--- Get the player's damage multiplier for the given aura at the time the aura was applied on the target.
-- @name BuffDamageMultiplier
-- @paramsig number
-- @param id The aura spell ID.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The damage multiplier.
-- @see DebuffDamageMultiplier
-- @usage
-- if target.DebuffDamageMultiplier(rake) <1 Spell(rake)

OvaleCondition.conditions.buffdamagemultiplier = function(condition)
	self_auraFound.baseDamageMultiplier = nil
	self_auraFound.damageMultiplier = nil
	local start, ending = GetAura(condition, self_auraFound)
	local baseDamageMultiplier = self_auraFound.baseDamageMultiplier or 1
	local damageMultiplier = self_auraFound.damageMultiplier or 1
	if start and ending and start <= ending then
		return start, ending, baseDamageMultiplier * damageMultiplier, start, 0
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.conditions.debuffdamagemultiplier = OvaleCondition.conditions.buffdamagemultiplier

--- Get the player's melee critical strike chance at the time the given aura was applied on the target.
-- @name BuffMeleeCritChance
-- @paramsig number
-- @param id The aura spell ID.
-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
--     Defaults to unlimited=0.
--     Valid values: 0, 1
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The critical strike chance.
-- @see DebuffMeleeCritChance
-- @usage
-- if MeleeCritChance() >target.DebuffMeleeCritChance(rake) Spell(rake)

OvaleCondition.conditions.buffmeleecritchance = function(condition)
	self_auraFound.meleeCrit = nil
	local start, ending = GetAura(condition, self_auraFound)
	local critChance = self_auraFound.meleeCrit or DEFAULT_CRIT_CHANCE
	if condition.unlimited ~= 1 and critChance > 100 then
		critChance = 100
	end
	if start and ending and start <= ending then
		return start, ending, critChance, start, 0
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.conditions.debuffmeleecritchance = OvaleCondition.conditions.buffmeleecritchance

--- Get the player's ranged critical strike chance at the time the given aura was applied on the target.
-- @name BuffRangedCritChance
-- @paramsig number
-- @param id The aura spell ID.
-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
--     Defaults to unlimited=0.
--     Valid values: 0, 1
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The critical strike chance.
-- @see DebuffRangedCritChance
-- @usage
-- if RangedCritChance() >target.DebuffRangedCritChance(serpent_sting_dot)
--     Spell(serpent_sting)

OvaleCondition.conditions.buffrangedcritchance = function(condition)
	self_auraFound.rangedCrit = nil
	local start, ending = GetAura(condition, self_auraFound)
	local critChance = self_auraFound.rangedCrit or DEFAULT_CRIT_CHANCE
	if condition.unlimited ~= 1 and critChance > 100 then
		critChance = 100
	end
	if start and ending and start <= ending then
		return start, ending, critChance, start, 0
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.conditions.debuffrangedcritchance = OvaleCondition.conditions.buffrangedcritchance

--- Get the player's spell critical strike chance at the time the given aura was applied on the target.
-- @name BuffSpellCritChance
-- @paramsig number
-- @param id The aura spell ID.
-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
--     Defaults to unlimited=0.
--     Valid values: 0, 1
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The critical strike chance.
-- @see DebuffSpellCritChance
-- @usage
-- if SpellCritChance() >target.DebuffSpellCritChance(moonfire) Spell(moonfire)

OvaleCondition.conditions.buffspellcritchance = function(condition)
	self_auraFound.spellCrit = nil
	local start, ending = GetAura(condition, self_auraFound)
	local critChance = self_auraFound.spellCrit or DEFAULT_CRIT_CHANCE
	if condition.unlimited ~= 1 and critChance > 100 then
		critChance = 100
	end
	if start and ending and start <= ending then
		return start, ending, critChance, start, 0
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.conditions.debuffspellcritchance = OvaleCondition.conditions.buffspellcritchance

--- Get the player's mastery effect at the time the given aura was applied on the target.
-- @name BuffMastery
-- @paramsig number
-- @param id The aura spell ID.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The mastery effect.
-- @see DebuffMastery
-- @usage
-- if Mastery() >target.DebuffMastery(rip) Spell(rip)

OvaleCondition.conditions.buffmastery = function(condition)
	self_auraFound.masteryEffect = nil
	local start, ending = GetAura(condition, self_auraFound)
	local masteryEffect = self_auraFound.masteryEffect or 0
	if start and ending and start <= ending then
		return start, ending, masteryEffect, start, 0
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.conditions.debuffmastery = OvaleCondition.conditions.buffmastery

--- Get the player's spellpower at the time the given aura was applied on the target.
-- @name BuffSpellpower
-- @paramsig number
-- @param id The aura spell ID.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The spellpower.
-- @see DebuffSpellpower
-- @usage
-- if Spellpower() >target.DebuffSpellpower(moonfire) Spell(moonfire)

OvaleCondition.conditions.buffspellpower = function(condition)
	self_auraFound.spellBonusDamage = nil
	local start, ending = GetAura(condition, self_auraFound)
	local spellBonusDamage = self_auraFound.spellBonusDamage or 0
	if start and ending and start <= ending then
		return start, ending, spellBonusDamage, start, 0
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.conditions.debuffspellpower = OvaleCondition.conditions.buffspellpower

--- Get the player's spell haste at the time the given aura was applied on the target.
-- @name BuffSpellHaste
-- @paramsig number
-- @param id The aura spell ID.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The percent increase to spell haste.
-- @see DebuffSpellHaste
-- @usage
-- if SpellHaste() >target.DebuffSpellHaste(moonfire) Spell(moonfire)

OvaleCondition.conditions.buffspellhaste = function(condition)
	self_auraFound.spellHaste = nil
	local start, ending = GetAura(condition, self_auraFound)
	local spellHaste = self_auraFound.spellHaste or 0
	if start and ending and start <= ending then
		return start, ending, spellHaste, start, 0
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.conditions.debuffspellhaste = OvaleCondition.conditions.buffspellhaste

--- Get the current percent increase to spell haste of the player.
-- @name SpellHaste
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The current percent increase to spell haste.
-- @return A boolean value for the result of the comparison.
-- @see BuffSpellHaste
-- @usage
-- if SpellHaste() >target.DebuffSpellHaste(moonfire) Spell(moonfire)

OvaleCondition.conditions.spellhaste = function(condition)
	return Compare(OvalePaperDoll.stat.spellHaste, condition[1], condition[2])
end

--- Get the total count of the given aura applied by the player across all targets.
-- @name BuffCount
-- @paramsig number
-- @param id The aura spell ID.
-- @return The total aura count.
-- @see DebuffCount

OvaleCondition.conditions.buffcount = function(condition)
	local start, ending, count = GetAuraOnAnyTarget(condition)
	return start, ending, count, start, 0
end
OvaleCondition.conditions.debuffcount = OvaleCondition.conditions.buffcount

--- Get the total duration of the aura from when it was first applied to when it ended.
-- @name BuffDuration
-- @paramsig number or boolean
-- @param id The aura spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The total duration of the aura.
-- @return A boolean value for the result of the comparison.
-- @see DebuffDuration

OvaleCondition.conditions.buffduration = function(condition)
	local start, ending = GetAura(condition)
	start = start or 0
	ending = ending or math.huge
	return Compare(ending - start, condition[2], condition[3])
end
OvaleCondition.conditions.debuffduration = OvaleCondition.conditions.buffduration

--- Test if an aura is expired, or will expire after a given number of seconds.
-- @name BuffExpires
-- @paramsig boolean
-- @param id The spell ID of the aura or the name of a spell list.
-- @param seconds Optional. The maximum number of seconds before the buff should expire.
--     Defaults to 0 (zero).
-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
--     Defaults to any=0.
--     Valid values: 0, 1.
-- @param haste Optional. Sets whether "seconds" should be lengthened or shortened due to haste.
--     Defaults to haste=none.
--     Valid values: melee, spell, none.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @see DebuffExpires
-- @usage
-- if BuffExpires(stamina any=1)
--     Spell(power_word_fortitude)
-- if target.DebuffExpires(rake 2)
--     Spell(rake)

OvaleCondition.conditions.buffexpires = function(condition)
	local start, ending = GetAura(condition)
	local timeBefore = TimeWithHaste(condition[2], condition.haste)
	if not start then
		return 0, math.huge
	end
	Ovale:Logf("timeBefore = %s, ending = %s", timeBefore, ending)
	return ending - timeBefore, math.huge
end
OvaleCondition.conditions.debuffexpires = OvaleCondition.conditions.buffexpires

--- Get the remaining time in seconds on an aura.
-- @name BuffRemains
-- @paramsig number
-- @param id The spell ID of the aura or the name of a spell list.
-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
--     Defaults to any=0.
--     Valid values: 0, 1.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The number of seconds remaining on the aura.
-- @see DebuffRemains
-- @usage
-- if BuffRemains(slice_and_dice) <2
--     Spell(slice_and_dice)

OvaleCondition.conditions.buffremains = function(condition)
	local start, ending = GetAura(condition)
	if start and ending and start <= ending then
		return start, ending, ending - start, start, -1
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.conditions.debuffremains = OvaleCondition.conditions.buffremains

	-- Returns the time elapsed since the last buff gain
	-- TODO won't work because the aura is not kept in cache
	-- 1 : aura spell id
	-- returns : number
	-- alias: debuffgain
OvaleCondition.conditions.buffgain = function(condition)
	Ovale:Error("not implemented")
	if true then return nil end
	local gain = select(4, GetAura(condition)) or 0
	return 0, math.huge, 0, 0, 1
end
OvaleCondition.conditions.debuffgain = OvaleCondition.conditions.buffgain

--- Test if an aura is present or if the remaining time on the aura is more than the given number of seconds.
-- @name BuffPresent
-- @paramsig boolean
-- @param id The spell ID of the aura or the name of a spell list.
-- @param seconds Optional. The mininum number of seconds before the buff should expire.
--     Defaults to 0 (zero).
-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
--     Defaults to any=0.
--     Valid values: 0, 1.
-- @param haste Optional. Sets whether "seconds" should be lengthened or shortened due to haste.
--     Defaults to haste=none.
--     Valid values: melee, spell, none.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @see DebuffPresent
-- @usage
-- if not BuffPresent(stamina any=1)
--     Spell(power_word_fortitude)
-- if not target.DebuffPresent(rake 2)
--     Spell(rake)

OvaleCondition.conditions.buffpresent = function(condition)
	local start, ending = GetAura(condition)
	if not start then
		return nil
	end
	local timeBefore = TimeWithHaste(condition[2], condition.haste)
	return start, ending - timeBefore
end
OvaleCondition.conditions.debuffpresent = OvaleCondition.conditions.buffpresent

--- Get the number of stacks of an aura on the target.
-- @name BuffStacks
-- @paramsig number
-- @param id The spell ID of the aura or the name of a spell list.
-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
--     Defaults to any=0.
--     Valid values: 0, 1.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The number of stacks of the aura.
-- @see DebuffStacks
-- @usage
-- if BuffStacks(pet_frenzy any=1) ==5
--     Spell(focus_fire)
-- if target.DebuffStacks(weakened_armor) <3
--     Spell(faerie_fire)

OvaleCondition.conditions.buffstacks = function(condition)
	local start, ending, stacks = GetAura(condition)
	start = start or 0
	ending = ending or math.huge
	stacks = stacks or 0
	return start, ending, stacks, 0, 0
end
OvaleCondition.conditions.debuffstacks = OvaleCondition.conditions.buffstacks

--- Test if there is a stealable buff on the target.
-- @name BuffStealable
-- @paramsig boolean
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @usage
-- if target.BuffStealable()
--     Spell(spellsteal)

OvaleCondition.conditions.buffstealable = function(condition)
	-- TODO: This should really be checked only against OvaleState.
	return OvaleAura:GetStealable(GetTarget(condition))
end

--- Get the current number of Burning Embers for destruction warlocks.
-- @name BurningEmbers
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: less, more.
-- @param number Optional. The number to compare against.
-- @return The number of Burning Embers.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if BurningEmbers() >10 Spell(chaos_bolt)
-- if BurningEmbers(more 10) Spell(chaos_bolt)

OvaleCondition.conditions.burningembers = function(condition)
	return TestValue(condition[1], condition[2], OvaleState.state.burningembers, OvaleState.currentTime, OvaleState.powerRate.burningembers)
end

--- Check if the player can cast the given spell (not on cooldown).
-- @name CanCast
-- @paramsig boolean
-- @param id The spell ID to check.
-- @return True if the spell cast be cast; otherwise, false.

OvaleCondition.conditions.cancast = function(condition)
	local spellId = condition[1]
	local actionCooldownStart, actionCooldownDuration = OvaleState:GetComputedSpellCD(spellId)
	return actionCooldownStart + actionCooldownDuration, math.huge
end

--- Test if the target is casting the given spell.
-- The spell may be specified either by spell ID, localized spell name, spell list name (as defined in SpellList),
-- "harmful" for any harmful spell, or "helpful" for any helpful spell.
-- @name Casting
-- @paramsig boolean
-- @param spell The spell to check.
--     Valid values: spell ID, spell name, spell list name, harmful, helpful
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @usage
-- Define(maloriak_release_aberrations 77569)
-- if target.Casting(maloriak_release_aberrations)
--     Spell(pummel)

OvaleCondition.conditions.casting = function(condition)
	local casting
	local target = GetTarget(condition)
	local spellId = condition[1]
	local start, ending, castSpellId, castSpellName, _
	if target == "player" then
		start = OvaleState.startCast
		ending = OvaleState.endCast
		castSpellId = OvaleState.currentSpellId
	else
		castSpellName, _, _, _, start, ending = API_UnitCastingInfo(target)
		if not castSpellName then
			castSpellName, _, _, _, start, ending = API_UnitChannelInfo(target)
		end
	end
	if not castSpellId and not castSpellName then
		return nil
	end
	if not spellId then
		return start, ending
	elseif type(spellId) == "number" then
		if IsSameSpell(spellId, castSpellId, castSpellName) then
			return start, ending
		else
			return nil
		end
	elseif OvaleData.buffSpellList[spellId] then
		local found = false
		for auraId in pairs(OvaleData.buffSpellList[spellId]) do
			if IsSameSpell(auraId, castSpellId, castSpellName) then
				return start, ending
			end
		end
		return nil
	elseif spellId == "harmful" then
		if not castSpellName then
			castSpellName = OvaleSpellBook:GetSpellName(castSpellId)
		end
		if API_IsHarmfulSpell(castSpellName) then
			return start, ending
		else
			return nil
		end
	elseif spellId == "helpful" then
		if not castSpellName then
			castSpellName = OvaleSpellBook:GetSpellName(castSpellId)
		end
		if API_IsHelpfulSpell(castSpellName) then
			return start, ending
		else
			return nil
		end
	end
end

--- Get the cast time in seconds of the spell for the player, taking into account current haste effects.
-- @name CastTime
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The number of seconds.
-- @return A boolean value for the result of the comparison.
-- @see RemainingCastTime
-- @usage
-- if target.DebuffRemains(flame_shock) < CastTime(lava_burst)
--     Spell(lava_burst)

OvaleCondition.conditions.casttime = function(condition)
	local castTime
	if condition[1] then
		castTime = select(7, API_GetSpellInfo(condition[1]))
		if castTime then
			castTime = castTime / 1000
			Ovale:Logf("castTime = %f %s %s", castTime, condition[2], condition[3])
		end
	end
	return Compare(castTime, condition[2], condition[3])
end

--- Get the number of charges on a spell with multiple charges.
-- @name Charges
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of charges
-- @return A boolean value for the result of the comparison.

OvaleCondition.conditions.charges = function(condition)
	local currentCharges, maxCharges, timeLastCast, cooldownDuration = API_GetSpellCharges(condition[1])
	return Compare(currentCharges, condition[2], condition[3])
end

--- Test if all of the listed checkboxes are off.
-- @name CheckBoxOff
-- @paramsig boolean
-- @param id The name of a checkbox. It should match one defined by AddCheckBox(...).
-- @param ... Optional. Additional checkbox names.
-- @return A boolean value.
-- @see CheckBoxOn
-- @usage
-- AddCheckBox(opt_black_arrow "Black Arrow" default)
-- if CheckBoxOff(opt_black_arrow) Spell(explosive_trap)

OvaleCondition.conditions.checkboxoff = function(condition)
	for k,v in pairs(condition) do
		if (Ovale:IsChecked(v)) then
			return nil
		end
	end
	return 0, math.huge
end

--- Test if all of the listed checkboxes are on.
-- @name CheckBoxOn
-- @paramsig boolean
-- @param id The name of a checkbox. It should match one defined by AddCheckBox(...).
-- @param ... Optional. Additional checkbox names.
-- @return A boolean value.
-- @see CheckBoxOff
-- @usage
-- AddCheckBox(opt_black_arrow "Black Arrow" default)
-- if CheckBoxOn(opt_black_arrow) Spell(black_arrow)

OvaleCondition.conditions.checkboxon = function(condition)
	for k,v in pairs(condition) do
		if (not Ovale:IsChecked(v)) then
			return nil
		end
	end
	return 0, math.huge
end

--- Get the current amount of stored Chi for monks.
-- @name Chi
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: less, more.
-- @param number Optional. The number to compare against.
-- @return The amount of stored Chi.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if Chi() ==4 Spell(chi_burst)
-- if Chi(more 3) Spell(chi_burst)

OvaleCondition.conditions.chi = function(condition)
	return TestValue(condition[1], condition[2], OvaleState.state.chi, OvaleState.currentTime, OvaleState.powerRate.chi)
end

--- Test whether the target's class matches the given class.
-- @name Class
-- @paramsig boolean
-- @param class The class to check.
--     Valid values: DEATHKNIGHT, DRUID, HUNTER, MAGE, MONK, PALADIN, PRIEST, ROGUE, SHAMAN, WARLOCK, WARRIOR.
-- @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
--     Default is yes.
--     Valid values: yes, no.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @usage
-- if target.Class(PRIEST) Spell(cheap_shot)

OvaleCondition.conditions.class = function(condition)
	local class, classToken = API_UnitClass(GetTarget(condition))
	return TestBoolean(classToken == condition[1], condition[2])
end

--- Test whether the target's classification matches the given classification.
-- @name Classification
-- @paramsig boolean
-- @param classification The unit classification to check.
--     Valid values: normal, elite, worldboss.
-- @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
--     Default is yes.
--     Valid values: yes, no.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @usage
-- if target.Classification(worldboss) Item(virmens_bite_potion)

OvaleCondition.conditions.classification = function(condition)
	local classification
	local target = GetTarget(condition)
	if API_UnitLevel(target) < 0 then
		classification = "worldboss"
	else
		classification = API_UnitClassification(target)
		if classification == "rareelite" then
			classification = "elite"
		elseif classification == "rare" then
			classification = "normal"
		end
	end
	return TestBoolean(classification == condition[1], condition[2])
end

--- Get the number of combo points on the currently selected target for a feral druid or a rogue.
-- @name ComboPoints
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of combo points.
-- @return A boolean value for the result of the comparison.
-- @see LastComboPoints
-- @usage
-- if ComboPoints() >=1 Spell(savage_roar)
-- if ComboPoints(more 0) Spell(savage_roar)

OvaleCondition.conditions.combopoints = function(condition)
	return Compare(OvaleState.state.combo, condition[1], condition[2])
end

--- Get the current value of a script counter.
-- @name Counter
-- @paramsig number or boolean
-- @param id The name of the counter. It should match one that's defined by inccounter=xxx in SpellInfo(...).
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The current value the counter.
-- @return A boolean value for the result of the comparison.

OvaleCondition.conditions.counter = function(condition)
	return Compare(OvaleState:GetCounterValue(condition[1]), condition[2], condition[3])
end

--- Test whether the target's creature family matches the given name.
-- Applies only to beasts that can be taken as hunter pets (e.g., cats, worms, and ravagers but not zhevras, talbuks and pterrordax),
-- demons that can be summoned by Warlocks (e.g., imps and felguards, but not demons that require enslaving such as infernals
-- and doomguards or world demons such as pit lords and armored voidwalkers), and Death Knight's pets (ghouls)
-- @name CreatureFamily
-- @paramsig boolean
-- @param name The English name of the creature family to check.
--     Valid values: Bat, Beast, Felguard, Imp, Ravager, etc.
-- @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
--     Default is yes.
--     Valid values: yes, no.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @usage
-- if pet.CreatureFamily(Felguard)
--     Spell(summon_felhunter)
-- if target.CreatureFamily(Dragonkin)
--     Spell(hibernate)

OvaleCondition.conditions.creaturefamily = function(condition)
	local family = API_UnitCreatureFamily(GetTarget(condition))
	return TestBoolean(family == LBCT[condition[1]], condition[2])
end

--- Test if the target is any of the listed creature types.
-- @name CreatureType
-- @paramsig boolean
-- @param name The English name of a creature type.
--     Valid values: Beast, Humanoid, Undead, etc.
-- @param ... Optional. Additional creature types.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @usage
-- if target.CreatureType(Humanoid Critter)
--     Spell(polymorph)

OvaleCondition.conditions.creaturetype = function(condition)
	local creatureType = API_UnitCreatureType(GetTarget(condition))
	for _, v in pairs(condition) do
		if creatureType == LBCT[v] then
			return 0, math.huge
		end
	end
	return nil
end

--- Get the current estimated damage of a spell on the target if it is a critical strike.
-- @name CritDamage
-- @paramsig number
-- @param id The spell ID.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The estimated critical strike damage of the given spell.
-- @see Damage, LastDamage, LastEstimatedDamage

OvaleCondition.conditions.critdamage = function(condition)
	-- TODO: Need to account for increased crit effect from meta-gems.
	local critFactor = 2
	local start, ending, value, origin, rate = OvaleCondition.conditions.damage(condition)
	return start, ending, critFactor * value, origin, critFactor * rate
end

--- Get the current estimated damage of a spell on the target.
-- The calculated damage takes into account the current attack power, spellpower, weapon damage and combo points (if used).
-- The damage is computed from information for the spell set via SpellInfo(...):
--
-- damage = base + bonusmainhand * MH + bonusoffhand * OH + bonusap * AP + bonuscp * CP + bonusapcp * AP * CP + bonussp * SP
-- @name Damage
-- @paramsig number
-- @param id The spell ID.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The estimated damage of the given spell on the target.
-- @see CritDamage, LastDamage, LastEstimatedDamage
-- @usage
-- if {target.Damage(rake) / target.LastEstimateDamage(rake)} >1.1
--     Spell(rake)

OvaleCondition.conditions.damage = function(condition)
	-- TODO: Use target's debuffs in this calculation.
	local spellId = condition[1]
	local value, origin, rate = ComputeFunctionParam(spellId, "damage")
	if value then
		return 0, math.huge, value, origin, rate
	else
		local ap = OvalePaperDoll.stat.attackPower
		local sp = OvalePaperDoll.stat.spellBonusDamage
		local mh = OvalePaperDoll.stat.mainHandWeaponDamage
		local oh = OvalePaperDoll.stat.offHandWeaponDamage
		local bdm = OvalePaperDoll.stat.baseDamageMultiplier
		local dm = OvaleState:GetDamageMultiplier(spellId)
		return 0, math.huge, OvaleData:GetDamage(spellId, ap, sp, mh, oh, combo) * bdm * dm, 0, 0
	end
end

--- Get the current damage multiplier of a spell.
-- This currently does not take into account increased damage due to mastery.
-- @name DamageMultiplier
-- @paramsig number
-- @param id The spell ID.
-- @return The current damage multiplier of the given spell.
-- @see LastDamageMultiplier
-- @usage
-- if {DamageMultiplier(rupture) / LastDamageMultiplier(rupture)} >1.1
--     Spell(rupture)

OvaleCondition.conditions.damagemultiplier = function(condition)
	local spellId = condition[1]
	local bdm = OvalePaperDoll.stat.baseDamageMultiplier
	local dm = OvaleState:GetDamageMultiplier(spellId)
	return 0, math.huge, bdm * dm, 0, 0
end

--- Get the damage taken by the player in the previous time interval.
-- @name DamageTaken
-- @paramsig number
-- @param interval The number of seconds before now.
-- @return The amount of damage taken in the previous interval.
-- @see IncomingDamage
-- @usage
-- if DamageTaken(5) > 50000 Spell(death_strike)

OvaleCondition.conditions.damagetaken = function(condition)
	-- Damage taken shouldn't be smoothed since spike damage is important data.
	-- Just present damage taken as a constant value.
	local interval = condition[1]
	local damage = 0
	if interval > 0 then
		damage = OvaleDamageTaken:GetRecentDamage(interval)
	end
	return 0, math.huge, damage, 0, 0
end
OvaleCondition.conditions.incomingdamage = OvaleCondition.conditions.damagetaken

--- Get the current amount of demonic fury for demonology warlocks.
-- @name DemonicFury
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: less, more.
-- @param number Optional. The number to compare against.
-- @return The amount of demonic fury.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if DemonicFury() >=1000 Spell(metamorphosis)
-- if DemonicFury(more 999) Spell(metamorphosis)

OvaleCondition.conditions.demonicfury = function(condition)
	return TestValue(condition[1], condition[2], OvaleState.state.demonicfury, OvaleState.currentTime, OvaleState.powerRate.demonicfury)
end

--- Get the distance in yards to the target.
-- The distances are from LibRangeCheck-2.0, which determines distance based on spell range checks, so results are approximate.
-- You should not test for equality.
-- @name Distance
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The distance to the target.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if target.Distance(less 25)
--     Texture(ability_rogue_sprint)

OvaleCondition.conditions.distance = function(condition)
	if LRC then
		return Compare(LRC:GetRange(GetTarget(condition)), condition[1], condition[2])
	else
		return nil
	end
end

--- Get the current amount of Eclipse power for balance druids.
-- A negative amount of power signifies being closer to Lunar Eclipse.
-- A positive amount of power signifies being closer to Solar Eclipse.
-- @name Eclipse
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The amount of Eclipse power.
-- @return A boolean value for the result of the comparison.
-- @see EclipseDir
-- @usage
-- if Eclipse() < 0-70 and EclipseDir() <0 Spell(wrath)
-- if Eclipse(less -70) and EclipseDir(less 0) Spell(wrath)

OvaleCondition.conditions.eclipse = function(condition)
	return Compare(OvaleState.state.eclipse, condition[1], condition[2])
end

--- Get the current direction of the Eclipse status on the Eclipse bar for balance druids.
-- A negative number means heading toward Lunar Eclipse.
-- A positive number means heading toward Solar Eclipse.
-- @name EclipseDir
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The current direction.
-- @return A boolean value for the result of the comparison.
-- @see Eclipse
-- @usage
-- if Eclipse() < 0-70 and EclipseDir() <0 Spell(wrath)
-- if Eclipse(less -70) and EclipseDir(less 0) Spell(wrath)

OvaleCondition.conditions.eclipsedir = function(condition)
	return Compare(OvaleState:GetEclipseDir(), condition[1], condition[2])
end

	-- Get the effective mana (e.g. if spell cost is divided by two, will returns the mana multiplied by two)
	-- TODO: not working
	-- returns: bool or number
OvaleCondition.conditions.effectivemana = function(condition)
	return TestValue(condition[1], condition[2], OvaleState.state.mana, OvaleState.currentTime, OvaleState.powerRate.mana)
end

--- Get the number of hostile enemies on the battlefield.
-- @name Enemies
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of enemies.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if Enemies() >4 Spell(fan_of_knives)
-- if Enemies(more 4) Spell(fan_of_knives)

OvaleCondition.conditions.enemies = function(condition)
	return Compare(OvaleEnemies.activeEnemies, condition[1], condition[2])
end

--- Get the current amount of energy for feral druids, non-mistweaver monks, and rogues.
-- @name Energy
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: less, more.
-- @param number Optional. The number to compare against.
-- @return The current energy.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if Energy() >70 Spell(vanish)
-- if Energy(more 70) Spell(vanish)

OvaleCondition.conditions.energy = function(condition)
	return TestValue(condition[1], condition[2], OvaleState.state.energy, OvaleState.currentTime, OvaleState.powerRate.energy)
end

--- Get the amount of regenerated energy per second for feral druids, non-mistweaver monks, and rogues.
-- @name EnergyRegen
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The current rate of energy regeneration.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if EnergyRegen() >11 Spell(stance_of_the_sturdy_ox)

OvaleCondition.conditions.energyregen = function(condition)
	return Compare(OvaleState.powerRate.energy, condition[1], condition[2])
end

--- Test if the target exists. The target may be alive or dead.
-- @name Exists
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if the target exists. If no, then return true if it doesn't exist.
--     Default is yes.
--     Valid values: yes, no.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @see Present
-- @usage
-- if pet.Exists(no) Spell(summon_imp)

OvaleCondition.conditions.exists = function(condition)
	return TestBoolean(API_UnitExists(GetTarget(condition)) == 1, condition[1])
end

--- A condition that always returns false.
-- @name False
-- @paramsig boolean
-- @return A boolean value.

OvaleCondition.conditions["false"] = function(condition)
	return nil
end

--- Get the current amount of focus for hunters.
-- @name Focus
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: less, more.
-- @param number Optional. The number to compare against.
-- @return The current focus.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if Focus() >70 Spell(arcane_shot)
-- if Focus(more 70) Spell(arcane_shot)

OvaleCondition.conditions.focus = function(condition)
	return TestValue(condition[1], condition[2], OvaleState.state.focus, OvaleState.currentTime, OvaleState.powerRate.focus)
end

--- Get the amount of regenerated focus per second for hunters.
-- @name FocusRegen
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The current rate of focus regeneration.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if FocusRegen() >20 Spell(arcane_shot)
-- if FocusRegen(more 20) Spell(arcane_shot)

OvaleCondition.conditions.focusregen = function(condition)
	return Compare(OvaleState.powerRate.focus, condition[1], condition[2])
end

--- Get the player's global cooldown in seconds.
-- @name GCD
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of seconds.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if GCD() <1.1 Spell(frostfire_bolt)
-- if GCD(less 1.1) Spell(frostfire_bolt)

OvaleCondition.conditions.gcd = function(condition)
	return Compare(OvaleState.gcd, condition[1], condition[2])
end

--- Test if the given glyph is active.
-- @name Glyph
-- @paramsig boolean
-- @param id The glyph spell ID.
-- @param yesno Optional. If yes, then return true if the glyph is active. If no, then return true if it isn't active.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- if InCombat(no) and Glyph(glyph_of_savagery)
--     Spell(savage_roar)

OvaleCondition.conditions.glyph = function(condition)
	return TestBoolean(OvaleSpellBook:IsActiveGlyph(condition[1]), condition[2])
end

--- Test if the player has full control, i.e., isn't feared, charmed, etc.
-- @name HasFullControl
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if the target exists. If no, then return true if it doesn't exist.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- if HasFullControl(no) Spell(barkskin)

OvaleCondition.conditions.hasfullcontrol = function(condition)
	return TestBoolean(API_HasFullControl(), condition[1])
end

--- Test if the player has a shield equipped.
-- @name HasShield
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if a shield is equipped. If no, then return true if it isn't equipped.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- if HasShield() Spell(shield_wall)

OvaleCondition.conditions.hasshield = function(condition)
	return TestBoolean(OvaleEquipement:HasShield(), condition[1])
end

--- Test if the player has a particular trinket equipped.
-- @name HasTrinket
-- @paramsig boolean
-- @param id The item ID of the trinket or the name of an item list.
-- @param yesno Optional. If yes, then return true if the trinket is equipped. If no, then return true if it isn't equipped.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- ItemList(rune_of_reorigination 94532 95802 96546)
-- if HasTrinket(rune_of_reorigination) and BuffPresent(rune_of_reorigination_buff)
--     Spell(rake)

OvaleCondition.conditions.hastrinket = function(condition)
	local trinketId = condition[1]
	if type(trinketId) == "number" then
		return TestBoolean(OvaleEquipement:HasTrinket(trinketId), condition[2])
	elseif OvaleData.itemList[trinketId] then
		for _, v in pairs(OvaleData.itemList[trinketId]) do
			if OvaleEquipement:HasTrinket(v) then
				return TestBoolean(true, condition[2])
			end
		end
	end
	return TestBoolean(false, condition[2])
end

--- Test if the player has a weapon equipped.
-- @name HasWeapon
-- @paramsig boolean
-- @param hand Sets which hand weapon.
--     Valid values: mainhand, offhand.
-- @param yesno Optional. If yes, then return true if the weapon is equipped. If no, then return true if it isn't equipped.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- if HasWeapon(offhand) and BuffStacks(killing_machine) Spell(frost_strike)

OvaleCondition.conditions.hasweapon = function(condition)
	if condition[1] == "offhand" then
		return TestBoolean(OvaleEquipement:HasOffHandWeapon(), condition[2])
	elseif condition[1] == "mainhand" then
		return TestBoolean(OvaleEquipement:HasMainHandWeapon(), condition[2])
	else
		return TestBoolean(false, condition[2])
	end
end

--- Get the current amount of health points of the target.
-- @name Health
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The current health.
-- @return A boolean value for the result of the comparison.
-- @see Life
-- @usage
-- if Health() <10000 Spell(last_stand)
-- if Health(less 10000) Spell(last_stand)

OvaleCondition.conditions.health = function(condition)
	local timeToDie, health, maxHealth = TimeToDie(GetTarget(condition))
	if not timeToDie or timeToDie == 0 then
		return nil
	end
	return TestValue(condition[1], condition[2], health, OvaleState.maintenant, -1 * health / timeToDie)
end
OvaleCondition.conditions.life = OvaleCondition.conditions.health

--- Get the number of health points away from full health of the target.
-- @name HealthMissing
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The current missing health.
-- @return A boolean value for the result of the comparison.
-- @see LifeMissing
-- @usage
-- if HealthMissing() <20000 Item(healthstone)
-- if HealthMissing(less 20000) Item(healthstone)

OvaleCondition.conditions.healthmissing = function(condition)
	local timeToDie, health, maxHealth = TimeToDie(GetTarget(condition))
	if not timeToDie or timeToDie == 0 then
		return nil
	end
	local missing = maxHealth - health
	return TestValue(condition[1], condition[2], missing, OvaleState.maintenant, health / timeToDie)
end
OvaleCondition.conditions.lifemissing = OvaleCondition.conditions.healthmissing

--- Get the current percent level of health of the target.
-- @name HealthPercent
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The current health percent.
-- @return A boolean value for the result of the comparison.
-- @see LifePercent
-- @usage
-- if HealthPercent() <20 Spell(last_stand)
-- if target.HealthPercent(less 25) Spell(kill_shot)

OvaleCondition.conditions.healthpercent = function(condition)
	local timeToDie, health, maxHealth = TimeToDie(GetTarget(condition))
	if not timeToDie or timeToDie == 0 then
		return nil
	end
	local healthPercent = health / maxHealth * 100
	return TestValue(condition[1], condition[2], healthPercent, OvaleState.maintenant, -1 * healthPercent / timeToDie)
end
OvaleCondition.conditions.lifepercent = OvaleCondition.conditions.healthpercent

--- Get the current amount of holy power for a paladin.
-- @name HolyPower
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The amount of holy power.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if HolyPower() >=3 Spell(word_of_glory)
-- if HolyPower(more 2) Spell(word_of_glory)

OvaleCondition.conditions.holypower = function(condition)
	return Compare(OvaleState.state.holy, condition[1], condition[2])
end

--- Test if the player is in combat.
-- @name InCombat
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if the player is in combat. If no, then return true if the player isn't in combat.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- if InCombat(no) and Stealthed(no) Spell(stealth)

OvaleCondition.conditions.incombat = function(condition)
	return TestBoolean(Ovale.enCombat, condition[1])
end

--- Test if the given spell is in flight for spells that have a flight time after cast, e.g., Lava Burst.
-- @name InFlightToTarget
-- @paramsig boolean
-- @param id The spell ID.
-- @param yesno Optional. If yes, then return true if the spell is in flight. If no, then return true if it isn't in flight.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- if target.DebuffRemains(haunt) <3 and not InFlightToTarget(haunt)
--     Spell(haunt)

OvaleCondition.conditions.inflighttotarget = function(condition)
	local spellId = condition[1]
	return TestBoolean(OvaleState.currentSpellId == spellId or OvaleFuture:InFlight(spellId), condition[2])
end

--- Test if the distance from the player to the target is within the spell's range.
-- @name InRange
-- @paramsig boolean
-- @param id The spell ID.
-- @param yesno Optional. If yes, then return true if the target is in range. If no, then return true if it isn't in range.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- if target.IsInterruptible() and target.InRange(kick)
--     Spell(kick)

OvaleCondition.conditions.inrange = function(condition)
	local spellName = OvaleSpellBook:GetSpellName(condition[1])
	return TestBoolean(API_IsSpellInRange(spellName, GetTarget(condition)) == 1,condition[2])
end

--- Get the cooldown time in seconds of an item, e.g., trinket.
-- @name ItemCooldown
-- @paramsig number
-- @param id The item ID.
-- @return The number of seconds.
-- @usage
-- if not ItemCooldown(ancient_petrified_seed) >0
--     Spell(berserk_cat)

OvaleCondition.conditions.itemcooldown = function(condition)
	local actionCooldownStart, actionCooldownDuration, actionEnable = API_GetItemCooldown(condition[1])
	return 0, math.huge, actionCooldownDuration, actionCooldownStart, -1
end

--- Get the current number of the given item in the player's inventory.
-- Items with more than one charge count as one item.
-- @name ItemCount
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The count of the item.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if ItemCount(mana_gem) ==0 Spell(conjure_mana_gem)
-- if ItemCount(mana_gem equal 0) Spell(conjure_mana_gem)

OvaleCondition.conditions.itemcount = function(condition)
	return Compare(API_GetItemCount(condition[1]), condition[2], condition[3])
end

--- Get the current number of charges of the given item in the player's inventory.
-- @name ItemCharges
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of charges.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if ItemCount(mana_gem) ==0 or ItemCharges(mana_gem) <3
--     Spell(conjure_mana_gem)
-- if ItemCount(mana_gem equal 0) or ItemCharges(mana_gem less 3)
--     Spell(conjure_mana_gem)

OvaleCondition.conditions.itemcharges = function(condition)
	return Compare(API_GetItemCount(condition[1], false, true), condition[2], condition[3])
end

--- Test if the target's primary aggro is on the player.
-- Even if the target briefly targets and casts a spell on another raid member,
-- this condition returns true as long as the player is highest on the threat table.
-- @name IsAggroed
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if the target is aggroed. If no, then return true if it isn't aggroed.
--     Default is yes.
--     Valid values: yes, no.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @usage
-- if target.IsAggroed() Spell(feign_death)

OvaleCondition.conditions.isaggroed = function(condition)
	return TestBoolean(API_UnitDetailedThreatSituation("player", GetTarget(condition)), condition[1])
end

--- Test if the player is feared.
-- @name IsFeared
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if feared. If no, then return true if it not feared.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- if IsFeared() Spell(every_man_for_himself)

OvaleCondition.conditions.isfeared = function(condition)
	return TestBoolean(not API_HasFullControl() and OvaleState:GetAura("player", "fear", "HARMFUL"), condition[1])
end

--- Test if the target is friendly to the player.
-- @name IsFriend
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if the target is friendly (able to help in combat). If no, then return true if it isn't friendly.
--     Default is yes.
--     Valid values: yes, no.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @usage
-- if target.IsFriend() Spell(healing_touch)

OvaleCondition.conditions.isfriend = function(condition)
	return TestBoolean(API_UnitIsFriend("player", GetTarget(condition)), condition[1])
end

--- Test if the target is flagged for PvP activity.
-- @name IsPVP
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if the target is flagged for PvP activity. If no, then return true if it isn't PvP-flagged.
--     Default is yes.
--     Valid values: yes, no.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @usage
-- if not target.IsFriend() and target.IsPVP() Spell(sap)

OvaleCondition.conditions.ispvp = function(condition)
	return TestBoolean(API_UnitIsPVP(GetTarget(condition)), condition[1])
end

--- Test if the player is incapacitated.
-- @name IsIncapacitated
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if incapacitated. If no, then return true if it not incapacitated.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- if IsIncapacitated() Spell(every_man_for_himself)

OvaleCondition.conditions.isincapacitated = function(condition)
	return TestBoolean(not API_HasFullControl() and OvaleState:GetAura("player", "incapacitate", "HARMFUL"), condition[1])
end

--- Test if the target is currently casting an interruptible spell.
-- @name IsInterruptible
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if the target is interruptible. If no, then return true if it isn't interruptible.
--     Default is yes.
--     Valid values: yes, no.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @usage
-- if target.IsInterruptible() Spell(kick)

OvaleCondition.conditions.isinterruptible = function(condition)
	local target = GetTarget(condition)
	local spell, rank, name, icon, start, ending, isTradeSkill, castID, protected = API_UnitCastingInfo(target)
	if not spell then
		spell, rank, name, icon, start, ending, isTradeSkill, protected = API_UnitChannelInfo(target)
	end
	return TestBoolean(protected ~= nil and not protected, condition[1])
end

--- Test if the player is rooted.
-- @name IsRooted
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if rooted. If no, then return true if it not rooted.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- if IsRooted() Item(Trinket0Slot usable=1)

OvaleCondition.conditions.isrooted = function(condition)
	return TestBoolean(OvaleState:GetAura("player", "root", "HARMFUL"), condition[1])
end

--- Test if the player is stunned.
-- @name IsStunned
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if stunned. If no, then return true if it not stunned.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- if IsStunned() Item(Trinket0Slot usable=1)

OvaleCondition.conditions.isstunned = function(condition)
	return TestBoolean(not API_HasFullControl() and OvaleState:GetAura("player", "stun", "HARMFUL"), condition[1])
end

--- Get the damage done by the most recent damage event for the given spell.
-- If the spell is a periodic aura, then it gives the damage done by the most recent tick.
-- @name LastDamage
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The damage done.
-- @return A boolean value for the result of the comparison.
-- @see Damage, LastEstimatedDamage
-- @usage
-- if LastDamage(ignite) >10000 Spell(combustion)
-- if LastDamage(ignite more 10000) Spell(combustion)

OvaleCondition.conditions.lastdamage = function(condition)
	local spellId = condition[1]
	if not OvaleSpellDamage:Get(spellId) then
		return nil
	end
	return Compare(OvaleSpellDamage:Get(spellId), condition[2], condition[3])
end
OvaleCondition.conditions.lastspelldamage = OvaleCondition.conditions.lastdamage

--- Get the estimated damage of the most recent cast of the player's spell on the target.
-- The calculated damage takes into account the values of attack power, spellpower, weapon damage and combo points (if used)
-- at the time the spell was most recent cast.
-- The damage is computed from information for the spell set via SpellInfo(...):
--
-- damage = base + bonusmainhand * MH + bonusoffhand * OH + bonusap * AP + bonuscp * CP + bonusapcp * AP * CP + bonussp * SP
-- @name LastEstimatedDamage
-- @paramsig number
-- @param id The spell ID.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=target.
--     Valid values: player, target, focus, pet.
-- @return The estimated damage of the most recent cast of the given spell by the player.
-- @see Damage, LastDamage
-- @usage
-- if {Damage(rake) / target.LastEstimateDamage(rake)} >1.1
--     Spell(rake)

OvaleCondition.conditions.lastestimateddamage = function(condition)
	local spellId = condition[1]
	local guid = OvaleGUID:GetGUID(GetTarget(condition, "target"))
	local ap = OvaleFuture:GetLastSpellInfo(guid, spellId, "attackPower") or 1
	local sp = OvaleFuture:GetLastSpellInfo(guid, spellId, "spellBonusDamage") or 1
	local mh = OvaleFuture:GetLastSpellInfo(guid, spellId, "mainHandWeaponDamage") or 1
	local oh = OvaleFuture:GetLastSpellInfo(guid, spellId, "offHandWeaponDamage") or 1
	local combo = OvaleFuture:GetLastSpellInfo(guid, spellId, "comboPoints") or 1
	local bdm = OvaleFuture:GetLastSpellInfo(guid, spellId, "baseDamageMultiplier") or 1
	local dm = OvaleFuture:GetLastSpellInfo(guid, spellId, "damageMultiplier") or 1
	return 0, math.huge, OvaleData:GetDamage(spellId, ap, sp, mh, oh, combo) * bdm * dm, 0, 0
end
OvaleCondition.conditions.lastspellestimateddamage = OvaleCondition.conditions.lastestimateddamage

--- Get the damage multiplier of the most recent cast of a spell on the target.
-- This currently does not take into account increased damage due to mastery.
-- @name LastDamageMultiplier
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
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

OvaleCondition.conditions.lastdamagemultiplier = function(condition)
	local guid = OvaleGUID:GetGUID(GetTarget(condition, "target"))
	local bdm = OvaleFuture:GetLastSpellInfo(guid, condition[1], "baseDamageMultiplier") or 1
	local dm = OvaleFuture:GetLastSpellInfo(guid, condition[1], "damageMultiplier") or 1
	return Compare(bdm * dm, condition[2], condition[3])
end
OvaleCondition.conditions.lastspelldamagemultiplier = OvaleCondition.conditions.lastdamagemultiplier

--- Get the attack power of the player during the most recent cast of a spell on the target.
-- @name LastAttackPower
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
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

OvaleCondition.conditions.lastattackpower = function(condition)
	local guid = OvaleGUID:GetGUID(GetTarget(condition, "target"))
	local ap = OvaleFuture:GetLastSpellInfo(guid, condition[1], "attackPower") or 1
	return Compare(ap, condition[2], condition[3])
end
OvaleCondition.conditions.lastspellattackpower = OvaleCondition.conditions.lastattackpower

--- Get the spellpower of the player during the most recent cast of a spell on the target.
-- @name LastSpellpower
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
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

OvaleCondition.conditions.lastspellpower = function(condition)
	local guid = OvaleGUID:GetGUID(GetTarget(condition, "target"))
	local sp = OvaleFuture:GetLastSpellInfo(guid, condition[1], "spellBonusDamage") or 1
	return Compare(sp, condition[2], condition[3])
end
OvaleCondition.conditions.lastspellspellpower = OvaleCondition.conditions.lastspellpower

--- Get the number of combo points consumed by the most recent cast of a spell on the target for a feral druid or a rogue.
-- @name LastComboPoints
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
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

OvaleCondition.conditions.lastcombopoints = function(condition)
	local guid = OvaleGUID:GetGUID(GetTarget(condition, "target"))
	local combo = OvaleFuture:GetLastSpellInfo(guid, condition[1], "comboPoints") or 1
	return Compare(combo, condition[2], condition[3])
end
OvaleCondition.conditions.lastspellcombopoints = OvaleCondition.conditions.lastcombopoints

--- Get the spell critical strike chance of the player during the most recent cast of a spell on the target.
-- @name LastSpellCritChance
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
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

OvaleCondition.conditions.lastspellcritchance = function(condition)
	local guid = OvaleGUID:GetGUID(GetTarget(condition, "target"))
	local critChance = OvaleFuture:GetLastSpellInfo(guid, condition[1], "spellCrit") or DEFAULT_CRIT_CHANCE
	if condition.unlimited ~= 1 and critChance > 100 then
		critChance = 100
	end
	return Compare(critChance, condition[2], condition[3])
end
OvaleCondition.conditions.lastspellspellcritchance = OvaleCondition.conditions.lastspellcritchance

--- Get the mastery effect of the player during the most recent cast of a spell on the target.
-- Mastery effect is the effect of the player's mastery, typically a percent-increase to damage
-- or a percent-increase to chance to trigger some effect.
-- @name LastMastery
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
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

OvaleCondition.conditions.lastmastery = function(condition)
	local guid = OvaleGUID:GetGUID(GetTarget(condition, "target"))
	local mastery = OvaleFuture:GetLastSpellInfo(guid, condition[1], "masteryEffect") or 0
	return Compare(mastery, condition[2], condition[3])
end
OvaleCondition.conditions.lastspellmastery = OvaleCondition.conditions.lastmastery

--- Get the melee critical strike chance of the player during the most recent cast of a spell on the target.
-- @name LastMeleeCritChance
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
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

OvaleCondition.conditions.lastmeleecritchance = function(condition)
	local guid = OvaleGUID:GetGUID(GetTarget(condition, "target"))
	local critChance = OvaleFuture:GetLastSpellInfo(guid, condition[1], "meleeCrit") or DEFAULT_CRIT_CHANCE
	if condition.unlimited ~= 1 and critChance > 100 then
		critChance = 100
	end
	return Compare(critChance, condition[2], condition[3])
end
OvaleCondition.conditions.lastspellmeleecritchance = OvaleCondition.conditions.lastmeleecritchance

--- Get the ranged critical strike chance of the player during the most recent cast of a spell on the target.
-- @name LastRangedCritChance
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
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

OvaleCondition.conditions.lastrangedcritchance = function(condition)
	local guid = OvaleGUID:GetGUID(GetTarget(condition, "target"))
	local critChance = OvaleFuture:GetLastSpellInfo(guid, condition[1], "rangedCrit") or DEFAULT_CRIT_CHANCE
	if condition.unlimited ~= 1 and critChance > 100 then
		critChance = 100
	end
	return Compare(critChance, condition[2], condition[3])
end
OvaleCondition.conditions.lastspellrangedcritchance = OvaleCondition.conditions.lastrangedcritchance

--- Get the time elapsed in seconds since the player's previous melee swing (white attack).
-- @name LastSwing
-- @paramsig number
-- @param hand Optional. Sets which hand weapon's melee swing.
--     If no hand is specified, then return the time elapsed since the previous swing of either hand's weapon.
--     Valid values: main, off.
-- @return The number of seconds.
-- @see NextSwing

OvaleCondition.conditions.lastswing = function(condition)
	return 0, math.huge, 0, OvaleSwing:GetLast(condition[1]), 1
end

--- Get the most recent estimate of roundtrip latency in milliseconds.
-- @name Latency
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number of milliseconds to compare against.
-- @return The most recent estimate of latency.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if Latency() >1000 Spell(sinister_strike)
-- if Latency(more 1000) Spell(sinister_strike)

OvaleCondition.conditions.latency = function(condition)
	return 0, math.huge, OvaleLatency:GetLatency() * 1000, 0, 0
end

--- Get the level of the target.
-- @name Level
-- @paramsig number or boolean
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The level of the target.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if Level() >=34 Spell(tiger_palm)
-- if Level(more 33) Spell(tiger_palm)

OvaleCondition.conditions.level = function(condition)
	local target = GetTarget(condition)
	local level
	if target == "player" then
		level = OvalePaperDoll.level
	else
		level = API_UnitLevel(target)
	end
	return Compare(level, condition[1], condition[2])
end

--- Test if a list is currently set to the given value.
-- @name List
-- @paramsig boolean
-- @param id The name of a list. It should match one defined by AddListItem(...).
-- @param value The value to test.
-- @return A boolean value.
-- @usage
-- AddListItem(opt_curse coe "Curse of the Elements" default)
-- AddListItem(opt_curse cot "Curse of Tongues")
-- if List(opt_curse coe) Spell(curse_of_the_elements)

OvaleCondition.conditions.list = function(condition)
	if condition[1] then
		if Ovale:GetListValue(condition[1]) == condition[2] then
			return 0, math.huge
		end
	end
	return nil
end

--- Get the current level of mana of the target.
-- @name Mana
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The current mana.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if {MaxMana() - Mana()} > 12500 Item(mana_gem)

OvaleCondition.conditions.mana = function(condition)
	local target = GetTarget(condition)
	if target == "player" then
		return TestValue(condition[1], condition[2], OvaleState.state.mana, OvaleState.currentTime, OvaleState.powerRate.mana)
	else
		return Compare(API_UnitPower(target, SPELL_POWER_MANA), condition[1], condition[2])
	end
end

--- Get the current percent level of mana (between 0 and 100) of the target.
-- @name ManaPercent
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The current mana percent.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if ManaPercent() >90 Spell(arcane_blast)
-- if ManaPercent(more 90) Spell(arcane_blast)

OvaleCondition.conditions.manapercent = function(condition)
	local target = GetTarget(condition)
	if target == "player" then
		local powerMax = OvalePower.maxPower.mana or 0
		if powerMax > 0 then
			local conversion = 100 / powerMax
			return TestValue(condition[1], condition[2], OvaleState.state.mana * conversion, OvaleState.currentTime, OvaleState.powerRate.mana * conversion)
		end
	else
		local powerMax = API_UnitPowerMax(target, SPELL_POWER_MANA) or 0
		local conversion = 100 / powerMax
		return Compare(API_UnitPower(target, SPELL_POWER_MANA) * conversion, condition[1], condition[2])
	end
end

--- Get the current mastery effect of the player.
-- Mastery effect is the effect of the player's mastery, typically a percent-increase to damage
-- or a percent-increase to chance to trigger some effect.
-- @name Mastery
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The current mastery effect.
-- @return A boolean value for the result of the comparison.
-- @see LastMastery
-- @usage
-- if {DamageMultiplier(rake) * {1 + Mastery()/100}} >1.8
--     Spell(rake)

OvaleCondition.conditions.mastery = function(condition)
	return Compare(OvalePaperDoll.stat.masteryEffect, condition[1], condition[2])
end

--- Get the amount of health points of the target when it is at full health.
-- @name MaxHealth
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum health.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if target.MaxHealth() >10000000 Item(mogu_power_potion)
-- if target.MaxHealth(more 10000000) Item(mogu_power_potion)

OvaleCondition.conditions.maxhealth = function(condition)
	local target = GetTarget(condition)
	return Compare(API_UnitHealthMax(target), condition[1], condition[2])
end

-- Return the maximum power of the given power type on the target.
local function MaxPowerConditionHelper(target, power)
	local maxi
	if target == "player" then
		maxi = OvalePower.maxPower[power]
	else
		maxi = API_UnitPowerMax(target, OvalePower.POWER[power].id, OvalePower.POWER[power].segments)
	end
	return maxi
end

--- Get the maximum amount of alternate power of the target.
-- Alternate power is the resource tracked by the alternate power bar in certain boss fights.
-- @name MaxAlternatePower
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum value.
-- @return A boolean value for the result of the comparison.

OvaleCondition.conditions.maxalternatepower = function(condition)
	local maxi = MaxPowerConditionHelper(GetTarget(condition), "alternate")
	return Compare(maxi, condition[1], condition[2])
end

--- Get the maximum amount of burning embers of the target.
-- @name MaxBurningEmbers
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum value.
-- @return A boolean value for the result of the comparison.

OvaleCondition.conditions.maxburningembers = function(condition)
	local maxi = MaxPowerConditionHelper(GetTarget(condition), "burningembers")
	return Compare(maxi, condition[1], condition[2])
end

--- Get the maximum amount of Chi of the target.
-- @name MaxChi
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum value.
-- @return A boolean value for the result of the comparison.

OvaleCondition.conditions.maxchi = function(condition)
	local maxi = MaxPowerConditionHelper(GetTarget(condition), "chi")
	return Compare(maxi, condition[1], condition[2])
end

--- Get the maximum amount of Demonic Fury of the target.
-- @name MaxDemonicFury
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum value.
-- @return A boolean value for the result of the comparison.

OvaleCondition.conditions.maxdemonicfury = function(condition)
	local maxi = MaxPowerConditionHelper(GetTarget(condition), "demonicfury")
	return Compare(maxi, condition[1], condition[2])
end

--- Get the maximum amount of energy of the target.
-- @name MaxEnergy
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum value.
-- @return A boolean value for the result of the comparison.

OvaleCondition.conditions.maxenergy = function(condition)
	local maxi = MaxPowerConditionHelper(GetTarget(condition), "energy")
	return Compare(maxi, condition[1], condition[2])
end

--- Get the maximum amount of focus of the target.
-- @name MaxFocus
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum value.
-- @return A boolean value for the result of the comparison.

OvaleCondition.conditions.maxfocus = function(condition)
	local maxi = MaxPowerConditionHelper(GetTarget(condition), "maxfocus")
	return Compare(maxi, condition[1], condition[2])
end

--- Get the maximum amount of Holy Power of the target.
-- @name MaxHolyPower
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum value.
-- @return A boolean value for the result of the comparison.

OvaleCondition.conditions.maxholypower = function(condition)
	local maxi = MaxPowerConditionHelper(GetTarget(condition), "holy")
	return Compare(maxi, condition[1], condition[2])
end

--- Get the maximum amount of mana of the target.
-- @name MaxMana
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum value.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if {MaxMana() - Mana()} > 12500 Item(mana_gem)

OvaleCondition.conditions.maxmana = function(condition)
	local maxi = MaxPowerConditionHelper(GetTarget(condition), "mana")
	return Compare(maxi, condition[1], condition[2])
end

--- Get the maximum amount of rage of the target.
-- @name MaxRage
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum value.
-- @return A boolean value for the result of the comparison.

OvaleCondition.conditions.maxrage = function(condition)
	local maxi = MaxPowerConditionHelper(GetTarget(condition), "rage")
	return Compare(maxi, condition[1], condition[2])
end

--- Get the maximum amount of Runic Power of the target.
-- @name MaxRunicPower
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum value.
-- @return A boolean value for the result of the comparison.

OvaleCondition.conditions.maxrunicpower = function(condition)
	local maxi = MaxPowerConditionHelper(GetTarget(condition), "runicpower")
	return Compare(maxi, condition[1], condition[2])
end

--- Get the maximum amount of Shadow Orbs of the target.
-- @name MaxShadowOrbs
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum value.
-- @return A boolean value for the result of the comparison.

OvaleCondition.conditions.maxshadoworbs = function(condition)
	local maxi = MaxPowerConditionHelper(GetTarget(condition), "shadoworbs")
	return Compare(maxi, condition[1], condition[2])
end

--- Get the maximum amount of Soul Shards of the target.
-- @name MaxSoulShards
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum value.
-- @return A boolean value for the result of the comparison.

OvaleCondition.conditions.maxsoulshards = function(condition)
	local maxi = MaxPowerConditionHelper(GetTarget(condition), "shards")
	return Compare(maxi, condition[1], condition[2])
end

--- Get the current melee critical strike chance of the player.
-- @name MeleeCritChance
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
--     Defaults to unlimited=0.
--     Valid values: 0, 1
-- @return The current critical strike chance (in percent).
-- @return A boolean value for the result of the comparison.
-- @see LastMeleeCritChance
-- @usage
-- if MeleeCritChance() >90 Spell(rip)

OvaleCondition.conditions.meleecritchance = function(condition)
	local critChance = OvalePaperDoll.stat.meleeCrit or DEFAULT_CRIT_CHANCE
	if condition.unlimited ~= 1 and critChance > 100 then
		critChance = 100
	end
	return Compare(critChance, condition[1], condition[2])
end

--- Get the time in seconds until the player's next melee swing (white attack).
-- @name NextSwing
-- @paramsig number
-- @param hand Optional. Sets which hand weapon's melee swing.
--     If no hand is specified, then return the time until the next swing of either hand's weapon.
--     Valid values: main, off.
-- @return The number of seconds
-- @see LastSwing

OvaleCondition.conditions.nextswing = function(condition)
	return 0, math.huge, OvaleSwing:GetNext(condition[1]), 0, -1
end

--- Get the number of seconds until the next tick of a periodic aura on the target.
-- @name NextTick
-- @paramsig number
-- @param id The spell ID of the aura or the name of a spell list.
-- @param filter Optional. The type of aura to check.
--     Default is any.
--     Valid values: any, buff, debuff
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The number of seconds.
-- @see Ticks, TicksRemain, TickTime

OvaleCondition.conditions.nexttick = function(condition)
	self_auraFound.tick = nil
	local start, ending = GetAura(condition, self_auraFound)
	local tick = self_auraFound.tick
	if ending and tick then
		while ending - tick > OvaleState.currentTime do
			ending = ending - tick
		end
		return 0, math.huge, 0, ending, -1
	end
	return nil
end

--- Test if an aura applied by the player is expired, or will expire after a given number of seconds, on every unit other than the current target.
-- @name OtherDebuffExpires
-- @paramsig boolean
-- @param id The spell ID of the aura or the name of a spell list.
-- @param seconds Optional. The maximum number of seconds before the aura should expire.
--     Defaults to 0 (zero).
-- @param haste Optional. Sets whether "seconds" should be lengthened or shortened due to haste.
--     Defaults to haste=none.
--     Valid values: melee, spell, none.
-- @return A boolean value.
-- @see OtherBuffExpires
-- @usage
-- if OtherDebuffExpires(deep_wounds)
--     Spell(thunder_clap)

OvaleCondition.conditions.otherdebuffexpires = function(condition)
	local start, ending = GetAuraOnAnyTarget(condition, "target")
	local timeBefore = TimeWithHaste(condition[2], condition.haste)
	if not start then
		return nil
	end
	Ovale:Logf("timeBefore = %s, ending = %s", timeBefore, ending)
	return ending - timeBefore, math.huge
end
OvaleCondition.conditions.otherbuffexpires = OvaleCondition.conditions.otherdebuffexpires

--- Test if an aura applied by the player is present, or if the remaining time on the aura is more than the given number of seconds, on at least one unit other than the current target.
-- @name OtherDebuffPresent
-- @paramsig boolean
-- @param id The spell ID of the aura or the name of a spell list.
-- @param seconds Optional. The mininum number of seconds before the aura should expire.
--     Defaults to 0 (zero).
-- @param haste Optional. Sets whether "seconds" should be lengthened or shortened due to haste.
--     Defaults to haste=none.
--     Valid values: melee, spell, none.
-- @return A boolean value.
-- @see OtherBuffPresent
-- @usage
-- if not OtherDebuffPresent(devouring_plague)
--     Spell(devouring_plague)

OvaleCondition.conditions.otherdebuffpresent = function(condition)
	local start, ending = GetAuraOnAnyTarget(condition, "target")
	if not start then
		return nil
	end
	local timeBefore = TimeWithHaste(condition[2], condition.haste)
	return start, ending - timeBefore
end
OvaleCondition.conditions.otherbuffpresent = OvaleCondition.conditions.otherdebuffpresent

--- Get the remaining time in seconds on an aura applied by the player across every unit other than the current target.
-- @name OtherDebuffRemains
-- @paramsig number
-- @param id The spell ID of the aura or the name of a spell list.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The number of seconds remaining on the aura.
-- @see OtherBuffRemains
-- @usage
-- if OtherDebuffRemains(devouring_plague) <2
--     Spell(devouring_plague)

OvaleCondition.conditions.otherdebuffremains = function(condition)
	local start, ending = GetAuraOnAnyTarget(condition, "target")
	if start and ending and start <= ending then
		return start, ending, ending - start, start, -1
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.conditions.otherbuffremains = OvaleCondition.conditions.otherdebuffremains

--- Get the resource cost of the given spell.
-- This returns zero for spells that use either mana or another resource based on stance/specialization, e.g., Monk's Jab.
-- @name PowerCost
-- @paramsig number
-- @param id The spell ID.
-- @return The amount of power (energy, focus, rage, etc.).
-- @see EnergyCost, FocusCost, ManaCost, RageCost
-- @usage
-- if Energy() > PowerCost(rake) Spell(rake)

OvaleCondition.conditions.powercost = function(condition)
	local cost = select(4, API_GetSpellInfo(condition[1])) or 0
	return 0, math.huge, cost, 0, 0
end
OvaleCondition.conditions.energycost = OvaleCondition.conditions.powercost
OvaleCondition.conditions.focuscost = OvaleCondition.conditions.powercost
OvaleCondition.conditions.manacost = OvaleCondition.conditions.powercost
OvaleCondition.conditions.ragecost = OvaleCondition.conditions.powercost
OvaleCondition.spellbookConditions.energycost = true
OvaleCondition.spellbookConditions.focuscost = true
OvaleCondition.spellbookConditions.manacost = true
OvaleCondition.spellbookConditions.ragecost = true
OvaleCondition.spellbookConditions.powercost = true

--- Test if the target exists and is alive.
-- @name Present
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if the target exists. If no, then return true if it doesn't exist.
--     Default is yes.
--     Valid values: yes, no.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @see Exists
-- @usage
-- if target.IsInterruptible() and pet.Present(yes)
--     Spell(pet_pummel)

OvaleCondition.conditions.present = function(condition)
	local target = GetTarget(condition)
	return TestBoolean(API_UnitExists(target) and not API_UnitIsDead(target), condition[1])
end

--- Test if the previous spell cast matches the given spell.
-- @name PreviousSpell
-- @paramsig boolean
-- @param id The spell ID.
-- @param yesno Optional. If yes, then return true if there is a match. If no, then return true if it doesn't match.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.

OvaleCondition.conditions.previousspell = function(condition)
	return TestBoolean(condition[1] == OvaleState.lastSpellId, condition[2])
end

--- Test if the pet exists and is alive.
-- PetPresent() is equivalent to pet.Present().
-- @name PetPresent
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if the target exists. If no, then return true if it doesn't exist.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @see Present
-- @usage
-- if target.IsInterruptible() and PetPresent(yes)
--     Spell(pet_pummel)

OvaleCondition.conditions.petpresent = function(condition)
	return TestBoolean(API_UnitExists("pet") and not API_UnitIsDead("pet"), condition[1])
end

--- Test if the game is on a PTR server
-- @paramsig boolean
-- @param yesno Optional. If yes, then returns true if it is a PTR realm. If no, return true if it is a live realm.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value
OvaleCondition.conditions.ptr = function(condition)
	local uiVersion = select(4, API_GetBuildInfo())
	return TestBoolean(uiVersion > 50200, condition[1])
end

--- Get the current amount of rage for guardian druids and warriors.
-- @name Rage
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: less, more.
-- @param number Optional. The number to compare against.
-- @return The current rage.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if Rage() >70 Spell(heroic_strike)
-- if Rage(more 70) Spell(heroic_strike)

OvaleCondition.conditions.rage = function(condition)
	return TestValue(condition[1], condition[2], OvaleState.state.rage, OvaleState.currentTime, OvaleState.powerRate.rage)
end

--- Get the current ranged critical strike chance of the player.
-- @name RangedCritChance
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
--     Defaults to unlimited=0.
--     Valid values: 0, 1
-- @return The current critical strike chance (in percent).
-- @return A boolean value for the result of the comparison.
-- @see LastRangedCritChance
-- @usage
-- if RangedCritChance() >90 Spell(serpent_sting)

OvaleCondition.conditions.rangedcritchance = function(condition)
	local critChance = OvalePaperDoll.stat.rangedCrit or DEFAULT_CRIT_CHANCE
	if condition.unlimited ~= 1 and critChance > 100 then
		critChance = 100
	end
	return Compare(critChance, condition[1], condition[2])
end

--- Get the result of the target's level minus the player's level. This number may be negative.
-- @name RelativeLevel
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The difference in levels.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if target.RelativeLevel() >3
--     Texture(ability_rogue_sprint)
-- if target.RelativeLevel(more 3)
--     Texture(ability_rogue_sprint)

OvaleCondition.conditions.relativelevel = function(condition)
	local difference, level
	local target = GetTarget(condition)
	if target == "player" then
		level = OvalePaperDoll.level
	else
		level = API_UnitLevel(target)
	end
	if level < 0 then
		difference = 3
	else
		difference = level - OvalePaperDoll.level
	end
	return Compare(difference, condition[1], condition[2])
end

--- Get the remaining cast time in seconds of the target's current spell cast.
-- @name RemainingCastTime
-- @paramsig number
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The number of seconds.
-- @see CastTime
-- @usage
-- if target.Casting(hour_of_twilight) and target.RemainingCastTime() <2
--     Spell(cloak_of_shadows)

OvaleCondition.conditions.remainingcasttime = function(condition)
	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = API_UnitCastingInfo(GetTarget(condition))
	if not endTime then
		return nil
	end
	return 0, math.huge, 0, endTime/1000, -1
end

--- Test if the current rune count meets the minimum rune requirements set out in the parameters.
-- This condition takes pairs of "type number" to mean that there must be a minimum of number runes of the named type.
-- E.g., Runes(blood 1 frost 1 unholy 1) means at least one blood, one frost, and one unholy rune is available, death runes included.
-- @name Runes
-- @paramsig boolean
-- @param type The type of rune.
--     Valid values: blood, frost, unholy, death
-- @param number The number of runes
-- @param ... Optional. Additional "type number" pairs for minimum rune requirements.
-- @param nodeath Sets whether death runes can fulfill the rune count requirements. If set to 0, then death runes are allowed.
--     Defaults to nodeath=0 (zero).
--     Valid values: 0, 1.
-- @return A boolean value.
-- @usage
-- if Runes(frost 1) Spell(howling_blast)

OvaleCondition.conditions.runes = function(condition)
	return GetRunesCooldown(condition)
end

--- Get the current number of runes of the given type for death knights.
-- @name RuneCount
-- @paramsig number
-- @param type The type of rune.
--     Valid values: blood, frost, unholy, death
-- @param death Sets whether death runes can fulfill the rune count requirements. If set to 1, then death runes are allowed.
--     Defaults to death=0 (zero).
--     Valid values: 0, 1.
-- @return The number of runes.
-- @usage
-- if RuneCount(unholy) ==2 or RuneCount(frost) ==2 or RuneCount(death) ==2
--     Spell(obliterate)

OvaleCondition.conditions.runecount = function(condition)
	return 0, math.huge, GetRuneCount(condition[1], condition.death)
end

--- Get the number of seconds before the rune conditions are met.
-- This condition takes pairs of "type number" to mean that there must be a minimum of number runes of the named type.
-- E.g., RunesCooldown(blood 1 frost 1 unholy 1) returns the number of seconds before
-- there are at least one blood, one frost, and one unholy rune, death runes included.
-- @name RunesCooldown
-- @paramsig number
-- @param type The type of rune.
--     Valid values: blood, frost, unholy, death
-- @param number The number of runes
-- @param ... Optional. Additional "type number" pairs for minimum rune requirements.
-- @param nodeath Sets whether death runes can fulfill the rune count requirements. If set to 0, then death runes are allowed.
--     Defaults to nodeath=0 (zero).
--     Valid values: 0, 1.
-- @return The number of seconds.
-- @usage
-- if Runes(frost 1) Spell(howling_blast)

OvaleCondition.conditions.runescooldown = function(condition)
	local ret = GetRunesCooldown(condition)
	if not ret then
		return nil
	end
	if ret < OvaleState.maintenant then
		ret = OvaleState.maintenant
	end
	return 0, math.huge, 0, ret, -1
end

--- Get the current amount of runic power for death knights.
-- @name RunicPower
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: less, more.
-- @param number Optional. The number to compare against.
-- @return The current runic power.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if RunicPower() >70 Spell(frost_strike)
-- if RunicPower(more 70) Spell(frost_strike)

OvaleCondition.conditions.runicpower = function(condition)
	return TestValue(condition[1], condition[2], OvaleState.state.runicpower, OvaleState.currentTime, OvaleState.powerRate.runicpower)
end

--- Get the current number of Shadow Orbs for shadow priests.
-- @name ShadowOrbs
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: less, more.
-- @param number Optional. The number to compare against.
-- @return The number of Shadow Orbs.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if ShadowOrbs() >2 Spell(mind_blast)
-- if ShadowOrbs(more 2) Spell(mind_blast)

OvaleCondition.conditions.shadoworbs = function(condition)
	return TestValue(condition[1], condition[2], OvaleState.state.shadoworbs, OvaleState.currentTime, OvaleState.powerRate.shadoworbs)
end

--- Get the current number of Soul Shards for warlocks.
-- @name SoulShards
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of Soul Shards.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if SoulShards() >0 Spell(summon_felhunter)
-- if SoulShards(more 0) Spell(summon_felhunter)

OvaleCondition.conditions.soulshards = function(condition)
	return Compare(OvaleState.state.shards, condition[1], condition[2])
end

--- Get the current speed of the target.
-- If the target is not moving, then this condition returns 0 (zero).
-- If the target is at running speed, then this condition returns 100.
-- @name Speed
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The speed of the target.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if Speed(more 0) and not BuffPresent(aspect_of_the_fox)
--     Spell(aspect_of_the_fox)

OvaleCondition.conditions.speed = function(condition)
	return Compare(API_GetUnitSpeed(GetTarget(condition))*100/7, condition[1], condition[2])
end

--- Get the current spell critical strike chance of the player.
-- @name SpellCritChance
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param unlimited Optional. Set unlimited=1 to allow critical strike chance to exceed 100%.
--     Defaults to unlimited=0.
--     Valid values: 0, 1
-- @return The current critical strike chance (in percent).
-- @return A boolean value for the result of the comparison.
-- @see CritChance, LastSpellCritChance
-- @usage
-- if SpellCritChance() >30 Spell(immolate)

OvaleCondition.conditions.spellcritchance = function(condition)
	local critChance = OvalePaperDoll.stat.spellCrit or DEFAULT_CRIT_CHANCE
	if condition.unlimited ~= 1 and critChance > 100 then
		critChance = 100
	end
	return Compare(critChance, condition[1], condition[2])
end
OvaleCondition.conditions.critchance = OvaleCondition.conditions.spellcritchance

--- Test if the given spell is in the spellbook.
-- A spell is known if the player has learned the spell and it is in the spellbook.
-- @name SpellKnown
-- @paramsig boolean
-- @param id The spell ID.
-- @param yesno Optional. If yes, then return true if the spell has been learned.
--     If no, then return true if the player hasn't learned the spell.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @see SpellUsable
-- @usage
-- if SpellKnown(avenging_wrath) and SpellCooldown(avenging_wrath) <10
--     Spell(guardian_of_ancient_kings_retribution)

OvaleCondition.conditions.spellknown = function(condition)
	return TestBoolean(OvaleSpellBook:IsKnownSpell(condition[1]), condition[2])
end
OvaleCondition.spellbookConditions.spellknown = true

--- Test if the given spell is usable.
-- A spell is usable if the player has learned the spell and has the resources required to cast the spell.
-- @name SpellUsable
-- @paramsig boolean
-- @param id The spell ID.
-- @param yesno Optional. If yes, then return true if the spell has been learned and the player has enough resources to cast it.
--     If no, then return true if the player can't cast the spell for one of the above reasons.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @see SpellKnown
-- @usage
-- if SpellUsable(avenging_wrath) and SpellCooldown(avenging_wrath) <10
--     Spell(guardian_of_ancient_kings_retribution)

OvaleCondition.conditions.spellusable = function(condition)
	return TestBoolean(API_IsUsableSpell(condition[1]), condition[2])
end
OvaleCondition.spellbookConditions.spellusable = true

--- Get the number of charges of the spell.
-- @name SpellCharges
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of charges.
-- @return A boolean value for the result of the comparison.
-- @see SpellChargeCooldown
-- @usage
-- if SpellCharges(savage_defense) >1
--     Spell(savage_defense)

OvaleCondition.conditions.spellcharges = function(condition)
	local charges = API_GetSpellCharges(condition[1])
	return Compare(charges, condition[2], condition[3])
end
OvaleCondition.spellbookConditions.spellcharges = true

--- Get the cooldown in seconds on a spell before it gains another charge.
-- @name SpellChargeCooldown
-- @paramsig number
-- @param id The spell ID.
-- @return The number of seconds.
-- @see SpellCharges
-- @usage
-- if SpellChargeCooldown(roll) <2
--     Spell(roll usable=1)

OvaleCondition.conditions.spellchargecooldown = function(condition)
	local charges, maxCharges, cooldownStart, cooldownDuration = API_GetSpellCharges(condition[1])
	if charges < maxCharges then
		return 0, math.huge, cooldownDuration, cooldownStart, -1
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.spellbookConditions.spellchargecooldown = true

--- Get the cooldown in seconds before a spell is ready for use.
-- @name SpellCooldown
-- @paramsig number
-- @param id The spell ID.
-- @return The number of seconds.
-- @usage
-- if ShadowOrbs() ==3 and SpellCooldown(mind_blast) <2
--     Spell(devouring_plague)

OvaleCondition.conditions.spellcooldown = function(condition)
	local spellId = condition[1]
	if type(spellId) == "string" then
		local sharedCd = OvaleState.state.cd[spellId]
		if sharedCd then
			return 0, math.huge, sharedCd.duration, sharedCd.start, -1
		else
			return nil
		end
	elseif not OvaleSpellBook:IsKnownSpell(spellId) then
		return 0, math.huge, 0, OvaleState.currentTime + 3600, -1
	else
		local actionCooldownStart, actionCooldownDuration, actionEnable = OvaleState:GetComputedSpellCD(spellId)
		return 0, math.huge, actionCooldownDuration, actionCooldownStart, -1
	end
end
-- OvaleCondition.spellbookConditions.spellcooldown = true / may be a sharedcd

--- Get data for the given spell defined by SpellInfo(...)
-- @name SpellData
-- @paramsig number
-- @param id The spell ID.
-- @param key The name of the data set by SpellInfo(...).
--     Valid values are any alphanumeric string.
-- @return The number data associated with the given key.
-- @usage
-- if BuffRemains(slice_and_dice) >= SpellData(shadow_blades duration)
--     Spell(shadow_blades)

OvaleCondition.conditions.spelldata = function(condition)
	local si = OvaleData.spellInfo[condition[1]]
	if si then
		local ret = si[condition[2]]
		if ret then
			return 0, math.huge, ret, 0, 0
		end
	end
	return nil
end

--- Get the current spellpower of the player.
-- @name Spellpower
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The current spellpower.
-- @return A boolean value for the result of the comparison.
-- @see LastSpellpower
-- @usage
-- if {Spellpower() / LastSpellpower(living_bomb)} >1.25
--     Spell(living_bomb)

OvaleCondition.conditions.spellpower = function(condition)
	return Compare(OvalePaperDoll.stat.spellBonusDamage, condition[1], condition[2])
end

--- Get the remaining amount of damage Stagger will cause to the target.
-- @name StaggerRemains
-- @paramsig number
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The amount of damage.
-- @usage
-- if StaggerRemains() / MaxHealth() >0.4 Spell(purifying_brew)

OvaleCondition.conditions.staggerremains = function(condition)
	local target = GetTarget(condition)
	local start, ending, stacks
	-- Heavy Stagger
	start, ending, stacks = OvaleState:GetAura(target, 124273, "HARMFUL")
	if not stacks or stacks == 0 then
		-- Moderate Stagger
		start, ending, stacks = OvaleState:GetAura(target, 124274, "HARMFUL")
	end
	if not stacks or stacks == 0 then
		-- Light Stagger
		start, ending, stacks = OvaleState:GetAura(target, 124275, "HARMFUL")
	end
	if start and ending and start < ending and stacks and stacks > 0 then
		local stagger = API_UnitStagger(target)
		return start, ending, 0, ending, -1 * stagger / (ending - start)
	else
		return 0, math.huge, 0, 0, 0
	end
end

--- Test if the player is in a given stance.
-- @name Stance
-- @paramsig boolean
-- @param stance The stance name or a number representing the stance index.
-- @return A boolean value.
-- @usage
-- unless Stance(druid_bear_form) Spell(bear_form)

OvaleCondition.conditions.stance = function(condition)
	if OvaleStance:IsStance(condition[1]) then
		return 0, math.huge
	else
		return nil
	end
end

--- Test if the player is currently stealthed.
-- The player is stealthed if rogue Stealth, druid Prowl, or a similar ability is active.
-- Note that the rogue Vanish buff causes this condition to return false,
-- but as soon as the buff disappears and the rogue is stealthed, this condition will return true.
-- @name Stealthed
-- @paramsig
-- @param yesno Optional. If yes, then return true if stealthed. If no, then return true if it not stealthed.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- if Stealthed() or BuffPresent(vanish_buff) or BuffPresent(shadow_dance)
--     Spell(ambush)

OvaleCondition.conditions.stealthed = function(condition)
	return TestBoolean(API_IsStealthed(), condition[1])
end

--- Get the number of points spent in a talent (0 or 1)
-- @name TalentPoints
-- @paramsig number or boolean
-- @param talent Talent to inspect.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of talent points.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if TalentPoints(blood_tap_talent) Spell(blood_tap)

OvaleCondition.conditions.talentpoints = function(condition)
	return Compare(OvaleSpellBook:GetTalentPoints(condition[1]), condition[2], condition[3])
end

--- Test if the player is the in-game target of the target.
-- @name TargetIsPlayer
-- @paramsig boolean
-- @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
--     Default is yes.
--     Valid values: yes, no.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return A boolean value.
-- @usage
-- if target.TargetIsPlayer() Spell(feign_death)

OvaleCondition.conditions.targetisplayer = function(condition)
	return TestBoolean(API_UnitIsUnit("player", GetTarget(condition).."target"), condition[1])
end

--- Get the amount of threat on the current target relative to the its primary aggro target, scaled to between 0 (zero) and 100.
-- This is a number between 0 (no threat) and 100 (will become the primary aggro target).
-- @name Threat
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=target.
--     Valid values: player, target, focus, pet.
-- @return The amount of threat.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if Threat() >90 Spell(fade)
-- if Threat(more 90) Spell(fade)

OvaleCondition.conditions.threat = function(condition)
	local isTanking, status, threatpct = API_UnitDetailedThreatSituation("player", GetTarget(condition, "target"))
	return Compare(threatpct, condition[1], condition[2])
end

--- Get the current tick value of a periodic aura on the target.
-- @name TickValue
-- @paramsig number or boolean
-- @param id The spell ID of the aura or the name of a spell list.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param filter Optional. The type of aura to check.
--     Default is any.
--     Valid values: any, buff, debuff
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The tick value.
-- @return A boolean value for the result of the comparison.
-- @see TicksRemain
-- @usage
-- if DebuffRemains(light_stagger) >0 and TickValue(light_stagger) >10000
--     Spell(purifying_brew)

OvaleCondition.conditions.tickvalue = function(condition)
	self_auraFound.value = nil
	local start, ending = GetAura(condition, self_auraFound)
	local value = self_auraFound.value or 0
	return Compare(value, condition[2], condition[3])
end

--- Get the total number of ticks of a periodic aura.
-- @name Ticks
-- @paramsig number or boolean
-- @param id The spell ID of the aura or the name of a spell list.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of ticks.
-- @return A boolean value for the result of the comparison.
-- @see NextTick, TicksRemain, TickTime

OvaleCondition.conditions.ticks = function(condition)
	self_auraFound.tick = nil
	local start, ending = GetAura(condition, self_auraFound)
	local tick = self_auraFound.tick
	local duration, numTicks
	if start then
		-- Aura exists on the target
		if ending and tick and tick > 0 then
			duration = ending - start
			numTicks = floor(duration / tick + 0.5)
		end
	else
		duration, tick, numTicks = OvaleState:GetDuration(condition[1])
	end
	if numTicks then
		return Compare(numTicks, condition[2], condition[3])
	else
		return nil
	end
end

--- Get the number of ticks that would be added if the dot is refreshed.
-- Not implemented, always returns 0.
-- @name TicksAdded
-- @paramsig number
-- @param id The aura spell ID
-- @return The number of added ticks.

OvaleCondition.conditions.ticksadded = function(condition)
	return 0, math.huge, 0, 0, 0
end

--- Get the remaining number of ticks of a periodic aura on a target.
-- @name TicksRemain
-- @paramsig number
-- @param id The spell ID of the aura or the name of a spell list.
-- @param filter Optional. The type of aura to check.
--     Default is any.
--     Valid values: any, buff, debuff
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The number of ticks.
-- @see NextTick, Ticks, TickTime
-- @usage
-- if target.TicksRemain(shadow_word_pain) <2
--     Spell(shadow_word_pain)

OvaleCondition.conditions.ticksremain = function(condition)
	self_auraFound.tick = nil
	local start, ending = GetAura(condition, self_auraFound)
	local tick = self_auraFound.tick
	if ending and tick and tick > 0 then
		return 0, math.huge, 1, ending, -1/tick
	end
	return 0, math.huge, 0, 0, 0
end

--- Get the number of seconds between ticks of a periodic aura on a target.
-- @name TickTime
-- @paramsig number or boolean
-- @param id The spell ID of the aura or the name of a spell list.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param filter Optional. The type of aura to check.
--     Default is any.
--     Valid values: any, buff, debuff
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The number of seconds.
-- @return A boolean value for the result of the comparison.
-- @see NextTick, Ticks, TicksRemain

OvaleCondition.conditions.ticktime = function(condition)
	self_auraFound.tick = nil
	local start, ending = GetAura(condition, self_auraFound)
	local tick = self_auraFound.tick
	if not tick then
		tick = OvaleAura:GetTickLength(condition[1])
	end
	if tick then
		return Compare(tick, condition[2], condition[3])
	else
		return nil
	end
end

--- Get the number of seconds elapsed since the player entered combat.
-- @name TimeInCombat
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: less, more.
-- @param number Optional. The number to compare against.
-- @return The number of seconds.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if TimeInCombat(more 5) Spell(bloodlust)

OvaleCondition.conditions.timeincombat = function(condition)
	return TestValue(condition[1], condition[2], 0, Ovale.combatStartTime, 1)
end

--- Get the estimated number of seconds remaining before the target is dead.
-- @name TimeToDie
-- @paramsig number
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The number of seconds.
-- @see DeadIn
-- @usage
-- if target.TimeToDie() <2 and ComboPoints() >0 Spell(eviscerate)

OvaleCondition.conditions.timetodie = function(condition)
	local timeToDie = TimeToDie(GetTarget(condition))
	return 0, math.huge, timeToDie, OvaleState.maintenant, -1
end
OvaleCondition.conditions.deadin = OvaleCondition.conditions.timetodie

--- Get the estimated number of seconds remaining before the target is reaches the given percent of max health.
-- @name TimeToHealthPercent
-- @paramsig number
-- @param percent The percent of max health of the target.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The number of seconds.
-- @see TimeToDie
-- @usage
-- if target.TimeToHealthPercent(25) <15 Item(virmens_bite_potion)

OvaleCondition.conditions.timetohealthpercent = function(condition)
	local timeToDie, health, maxHealth = TimeToDie(GetTarget(condition))
	local percent = condition[1]
	local healthPercent = health / maxHealth * 100
	if healthPercent >= percent then
		local t = timeToDie * (healthPercent - percent) / healthPercent
		return 0, math.huge, t, OvaleState.maintenant, -1
	end
	return 0, math.huge, 0, 0, 0
end
OvaleCondition.conditions.timetolifepercent = OvaleCondition.conditions.timetohealthpercent

--- Get the number of seconds before the player has enough primary resources to cast the given spell.
-- @name TimeToPowerFor
-- @paramsig number
-- @param id The spell ID.
-- @return The number of seconds.
-- @see TimeToEnergyFor, TimeToFocusFor, TimeToMaxEnergy

OvaleCondition.conditions.timetopowerfor = function(condition)
	local cost, _, powerType = select(4, API_GetSpellInfo(condition[1]))
	local power = OvalePower.POWER_TYPE[powerType]
	local currentPower = OvaleState.state[power]
	local powerRate = OvaleState.powerRate[power]
	cost = cost or 0
	if currentPower < cost then
		if powerRate > 0 then
			local t = OvaleState.currentTime + (cost - currentPower) / powerRate
			return 0, math.huge, 0, t, -1
		else
			return 0, math.huge, OvaleState.currentTime + 3600, 0, 0
		end
	else
		return 0, math.huge, 0, 0, 0
	end
end
OvaleCondition.conditions.timetoenergyfor = OvaleCondition.conditions.timetopowerfor
OvaleCondition.conditions.timetofocusfor = OvaleCondition.conditions.timetopowerfor
OvaleCondition.spellbookConditions.timetoenergyfor = true
OvaleCondition.spellbookConditions.timetofocusfor = true
OvaleCondition.spellbookConditions.timetopowerfor = true

--- Get the number of seconds before the player reaches maximum energy for feral druids, non-mistweaver monks and rogues.
-- @name TimeToMaxEnergy
-- @paramsig number or boolean
-- @return The number of seconds.
-- @see TimeToEnergyFor
-- @usage
-- if TimeToMaxEnergy() < 1.2 Spell(sinister_strike)

OvaleCondition.conditions.timetomaxenergy = function(condition)
	local maxEnergy = OvalePower.maxPower.energy or 0
	local t = OvaleState.currentTime + (maxEnergy - OvaleState.state.energy) / OvaleState.powerRate.energy
	return 0, math.huge, 0, t, -1
end

--- Get the time scaled by the specified haste type, defaulting to spell haste.
--- For example, if a DoT normally ticks every 3 seconds and is scaled by spell haste, then it ticks every TimeWithHaste(3 haste=spell) seconds.
-- @name TimeWithHaste
-- @paramsig number
-- @param time The time in seconds.
-- @param haste Optional. Sets whether "time" should be lengthened or shortened due to haste.
--     Defaults to haste=spell.
--     Valid values: melee, spell.
-- @return The time in seconds scaled by haste.
-- @usage
-- if target.DebuffRemains(flame_shock) < TimeWithHaste(3)
--     Spell(flame_shock)

OvaleCondition.conditions.timewithhaste = function(condition)
	haste = condition.haste or "spell"
	return 0, math.huge, TimeWithHaste(condition[1], haste), 0, 0
end

--- Test if the totem for shamans, the ghoul for death knights, or the statue for monks has expired.
-- @name TotemExpires
-- @paramsig boolean
-- @param id The totem ID of the totem, ghoul or statue, or the type of totem.
--     Valid types: fire, water, air, earth, ghoul, statue.
-- @param seconds Optional. The maximum number of seconds before the totem should expire.
--     Defaults to 0 (zero).
-- @param totem Optional. Sets the specific totem to check of given totem ID type.
--     Valid values: any totem spell ID
-- @return A boolean value.
-- @see TotemPresent
-- @usage
-- if TotemExpires(fire) Spell(searing_totem)
-- if TotemPresent(water totem=healing_stream_totem) and TotemExpires(water 3) Spell(totemic_recall)

OvaleCondition.conditions.totemexpires = function(condition)
	local totemId = condition[1]
	local seconds = condition[2] or 0
	if type(totemId) ~= "number" then
		totemId = OVALE_TOTEMTYPE[totemId]
	end
	local haveTotem, totemName, startTime, duration = API_GetTotemInfo(totemId)
	if not startTime then
		return 0, math.huge
	end
	if condition.totem and OvaleSpellBook:GetSpellName(condition.totem) ~= totemName then
		return 0, math.huge
	end
	return startTime + duration - seconds, math.huge
end

--- Test if the totem for shamans, the ghoul for death knights, or the statue for monks is present.
-- @name TotemPresent
-- @paramsig boolean
-- @param id The totem ID of the totem, ghoul or statue, or the type of totem.
--     Valid types: fire, water, air, earth, ghoul, statue.
-- @param totem Optional. Sets the specific totem to check of given totem ID type.
--     Valid values: any totem spell ID
-- @return A boolean value.
-- @see TotemExpires
-- @usage
-- if not TotemPresent(fire) Spell(searing_totem)
-- if TotemPresent(water totem=healing_stream_totem) and TotemExpires(water 3) Spell(totemic_recall)

OvaleCondition.conditions.totempresent = function(condition)
	local totemId = condition[1]
	if type(totemId) ~= "number" then
		totemId = OVALE_TOTEMTYPE[totemId]
	end
	local haveTotem, totemName, startTime, duration = API_GetTotemInfo(totemId)
	if not startTime then
		return nil
	end
	if condition.totem and OvaleSpellBook:GetSpellName(condition.totem) ~= totemName then
		return nil
	end
	return startTime, startTime + duration
end

	-- Check if a tracking is enabled
	-- 1: the spell id
	-- return bool
OvaleCondition.conditions.tracking = function(condition)
	local what = OvaleSpellBook:GetSpellName(condition[1])
	local numTrackingTypes = API_GetNumTrackingTypes()
	local present = false
	for i = 1, numTrackingTypes do
		local name, _, active = API_GetTrackingInfo(i)
		if name and name == what then
			present = (active == 1)
			break
		end
	end
	return TestBoolean(present, condition[2])
end

--- A condition that always returns true.
-- @name True
-- @paramsig boolean
-- @return A boolean value.

OvaleCondition.conditions["true"] = function(condition)
	return TestBoolean(true)
end

--- Test if the weapon imbue on the given weapon has expired or will expire after a given number of seconds.
-- @name WeaponEnchantExpires
-- @paramsig boolean
-- @param hand Sets which hand weapon.
--     Valid values: mainhand, offhand.
-- @param seconds Optional. The maximum number of seconds before the weapon imbue should expire.
--     Defaults to 0 (zero).
-- @return A boolean value.
-- @usage
-- if WeaponEnchantExpires(mainhand) Spell(windfury_weapon)

OvaleCondition.conditions.weaponenchantexpires = function(condition)
	local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = API_GetWeaponEnchantInfo()
	if (condition[1] == "mainhand") then
		if (not hasMainHandEnchant) then
			return 0, math.huge
		end
		mainHandExpiration = mainHandExpiration/1000
		if ((condition[2] or 0) >= mainHandExpiration) then
			return 0, math.huge
		else
			return OvaleState.maintenant + mainHandExpiration - (condition[2] or 60), math.huge
		end
	else
		if (not hasOffHandEnchant) then
			return 0, math.huge
		end
		offHandExpiration = offHandExpiration/1000
		if ((condition[2] or 0) >= offHandExpiration) then
			return 0, math.huge
		else
			return OvaleState.maintenant + offHandExpiration - (condition[2] or 60), math.huge
		end
	end
end

--- The normalized weapon damage of the weapon in the given hand.
-- @name WeaponDamage
-- @paramsig number
-- @param hand Optional. Sets which hand weapon.
--     Defaults to mainhand.
--     Valid values: mainhand, offhand.
-- @return The normalized weapon damage.
-- @usage
-- AddFunction MangleDamage {
--     WeaponDamage() * 5 + 78
-- }

OvaleCondition.conditions.weapondamage = function(condition)
	local hand = condition[1]
	local damage = 0
	if hand == "offhand" or hand == "off" then
		damage = OvalePaperDoll.stat.offHandWeaponDamage
	else -- if hand == "mainhand" or hand == "main" then
		damage = OvalePaperDoll.stat.mainHandWeaponDamage
	end
	return 0, math.huge, damage, 0, 0
end
--</public-static-properties>
