--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013 Sidoine, Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

local _, Ovale = ...
local OvaleCondition = {}
Ovale.OvaleCondition = OvaleCondition

--<private-static-properties>
local LBCT = LibStub("LibBabble-CreatureType-3.0"):GetLookupTable()
local LRC = LibStub("LibRangeCheck-2.0", true)
local OvaleAura = Ovale.OvaleAura
local OvaleData = Ovale.OvaleData
local OvaleEnemies = Ovale.OvaleEnemies
local OvaleEquipement = Ovale.OvaleEquipement
local OvaleGUID = Ovale.OvaleGUID
local OvaleFuture = Ovale.OvaleFuture
local OvalePaperDoll = Ovale.OvalePaperDoll
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
local API_UnitIsUnit = UnitIsUnit
local API_UnitLevel = UnitLevel
local API_UnitPower = UnitPower
local API_UnitPowerMax = UnitPowerMax

-- static property for GetRunesCooldown(), indexed by rune name
local self_runes = {}

-- static properties for TimeToDie(), indexed by unit ID
local self_lastTTDTime = {}
local self_lastTTDHealth = {}
local self_lastTTDguid = {}

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
--</private-static-properties>

--<private-static-methods>
local function isDebuffInList(list)
	local i=1;
	while (true) do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId =  API_UnitDebuff("player", i);
		if (not name) then
			break
		end
		if (list[spellId]) then
			return true
		end
		i = i +1
	end
	return false
end

local function avecHate(temps, hate)
	if not temps then
		temps = 0
	end
	if (not hate) then
		return temps
	elseif (hate == "spell") then
		return temps / OvalePaperDoll:GetSpellHasteMultiplier()
	elseif (hate == "melee") then
		return temps / OvalePaperDoll:GetMeleeHasteMultiplier()
	else
		return temps
	end
end

local function compare(a, comparison, b)
	if not comparison then
		return 0, nil, a, 0, 0 -- this is not a compare, returns the value a
	elseif comparison == "more" then
		if (not b or (a~=nil and a>b)) then
			return 0
		else
			return nil
		end
	elseif comparison == "equal" then
		if b == a then
			return 0
		else
			return nil
		end
	elseif comparison == "less" then
		if (not a or (b~=nil and a<b)) then
			return 0
		else
			return nil
		end
	else
		Ovale:Error("unknown compare term "..comparison.." (should be more, equal, or less)")
	end
end

local function testbool(a, condition)
	if (condition == "yes" or not condition) then
		if (a) then
			return 0
		else
			return nil
		end
	else
		if (not a) then
			return 0
		else
			return nil
		end
	end
end

local function getTarget(condition)
	if (not condition) then
		return "player"
	elseif condition == "target" then
		return OvaleCondition.defaultTarget
	else	
		return condition
	end
end

local function getFilter(condition)
	if condition.filter then
		if condition.filter == "debuff" then
			return "HARMFUL"
		elseif condition.filter == "buff" then
			return "HELPFUL"
		end
	end
	return nil
end

local function addTime(time1, duration)
	if not time1 then
		return nil
	else
		return time1 + duration
	end
end

--Return time2-time1
local function diffTime(time1, time2)
	if not time1 then
		return 0
	end
	if not time2 then
		return nil
	end
	return time2 - time1
end

local function addOrSubTime(time1, operator, duration)
	if operator == "more" then
		return addTime(time1, -duration)
	else
		return addTime(time1, duration)
	end
end

-- Get the expiration time of a debuff
-- that can be on any unit except the target
-- Returns the first to expires, the last to expires
-- Returns nil if the debuff is not present
local function getOtherAura(spellId, filter, suppTime, excludingTarget)
	if excludingTarget then
		excludingTarget = OvaleGUID:GetGUID(excludingTarget)
	end
	return OvaleState:GetExpirationTimeOnAnyTarget(spellId, filter, excludingTarget)
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

local lastEnergyValue = nil
local lastEnergyTime

local function testValue(comparator, limit, value, atTime, rate)
	if not value or not atTime then
		return nil
	elseif not comparator then
		return 0, nil, value, atTime, rate
	else
		if rate == 0 then
			if comparator == "more" then
				if value > limit then return 0 else return nil end
			elseif comparator == "less" then
				if value < limit then return 0 else return nil end
			else
				Ovale:Error("Unknown operator "..comparator)
			end
		elseif (comparator == "more" and rate > 0) or (comparator == "less" and rate < 0) then
			return (limit - value) / rate + atTime
		elseif (comparator == "more" and rate < 0) or (comparator == "less" and rate > 0) then
			return 0, (limit - value) / rate + atTime
		else
			Ovale:Error("Unknown operator "..comparator)
		end
	end
end

local function getAura(target, spellId, filter, mine)
	if type(spellId) == "number" then
		return OvaleState:GetAura(target, spellId, filter, mine)
	elseif OvaleData.buffSpellList[spellId] then
		local newStart, newEnding, newStacks, newSpellHasteMultiplier, newValue, newGain
		local start, ending, stacks, spellHasteMultiplier, value, gain
		for _, v in pairs(OvaleData.buffSpellList[spellId]) do
			start, ending, stacks, spellHasteMultiplier, value, gain = OvaleState:GetAura(target, v, filter, mine)
			if start and (not newStart or stacks > newStacks) then
				newStart = start
				newEnding = ending
				newStacks = stacks
				newSpellHasteMultiplier = spellHasteMultiplier
				newValue = value
				newGain = gain
			end
		end
		return newStart, newEnding, newStacks, newSpellHasteMultiplier, newValue, newGain
	elseif spellId == "Magic" or spellId == "Disease" or spellId == "Curse" or spellId == "Poison" then
		return OvaleState:GetAura(target, spellId, filter, mine)
	end
end

local function getMine(condition)
	local mine = true
	if condition.any then
		if condition.any == 0 then
			mine = true
		else
			mine = false
		end
	end
	return mine
end

-- Recherche un aura sur la cible et récupère sa durée et le nombre de stacks
-- return start, ending, stacks, spellHasteMultiplier
local function GetTargetAura(condition, target)
	if (not target) then
		target=condition.target
		if (not target) then
			target="target"
		end
	end
	local stacks = condition.stacks
	if not stacks then
		stacks = 1
	end
	local spellId = condition[1]
	local mine = getMine(condition)

	local auraStart, auraEnding, auraStacks, auraSpellHasteMultiplier, auraValue, auraGain = getAura(target, spellId, getFilter(condition), mine)
	if not auraStart then
		Ovale:Log("Aura "..spellId.." not found on " .. target .. " mine=" .. tostring(mine))
		return 0,0,0,0
	end
	if Ovale.trace then
		Ovale:Print("GetTargetAura = start=".. tostring(auraStart) .. " end="..tostring(auraEnding).." stacks=" ..tostring(auraStacks).."/"..stacks .. " target="..target)
	end
		
	if (not condition.mine or (mine and condition.mine == 1) or (not mine and condition.mine == 0)) and auraStacks >= stacks then
		local ending
		if condition.forceduration then
			--TODO: this is incorrect.
			if OvaleData.spellInfo[spellId] and OvaleData.spellInfo[spellId].duration then
				ending = auraStart + OvaleData.spellInfo[spellId].duration
			else
				ending = auraStart + condition.forceduration
			end
		else
			ending = auraEnding
		end
		return auraStart, ending, auraStacks, auraSpellHasteMultiplier
	else
		return 0,0,0,0
	end
end

local function TimeToDie(unitId)
	if self_lastTTDguid[unitId] ~= OvaleGUID:GetGUID(unitId) then
		self_lastTTDguid[unitId] = OvaleGUID:GetGUID(unitId)
		self_lastTTDTime[unitId] = nil
		if self_lastTTDHealth[unitId] then
			wipe(self_lastTTDHealth[unitId])
		else
			self_lastTTDHealth[unitId] = {}
		end
	end
	local newHealth = API_UnitHealth(unitId)
	if newHealth then
		Ovale:Log("newHealth = " .. newHealth)
	end
	if API_UnitHealthMax(unitId) <= 2 then
		Ovale:Log("Training Dummy, return in the future")
		return OvaleState.currentTime + 3600
	end

	local second = floor(OvaleState.maintenant)
	local dps = 0
	if self_lastTTDTime[unitId] ~= second and self_lastTTDguid[unitId] then
		self_lastTTDTime[unitId] = second
		local mod10 = second % 10
		local prevHealth = self_lastTTDHealth[unitId][mod10]
		self_lastTTDHealth[unitId][mod10] = newHealth
		if prevHealth and prevHealth>newHealth then
			dps = (prevHealth - newHealth) / 10
			if dps > 0 then
				Ovale:Log("dps = " .. dps)
			end
		end
	end
	if dps > 0 then
		local duration = newHealth / dps
		return OvaleState.maintenant + duration
	end
	return OvaleState.currentTime + 3600
end

local function isSameSpell(spellIdA, spellIdB, spellNameB)
	if spellIdB then
		return spellIdA == spellIdB
	elseif spellIdA and spellNameB then
		return API_GetSpellInfo(spellIdA) == spellNameB
	else
		return false
	end
end
--</private-static-methods>

--<public-static-properties>
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
	infinity is represented by "nil".  Time is a value such as returned by
	the API function GetTime().

	Examples:

	(1)	(0, nil) means the condition is always true.  This can be shortened
		to just return 0.

	(2)	(nil, nil) means the condition is always false.  This can be shorted
		to just return nil.

	(3)	(0, nil, constant, 0, 0) means the condition has a constant value.

	(4)	(start, ending, ending - start, start, -1) means the condition has a
		value of f(t) = ending - t, at time t between start and ending.  This
		basically returns how much time is left within the time interval.
--]]----------------------------------------------------------------------------

OvaleCondition.conditions = {}
-- List of script conditions that refer to a castable spell from the player's spellbook.
OvaleCondition.spellbookConditions = { spell = true }

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
	return compare(OvaleEquipement:GetArmorSetCount(condition[1]), condition[2], condition[3])
end

--- Get the current attack power of the player.
-- @name AttackPower
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The current attack power.
-- @return A boolean value for the result of the comparison.
-- @see LastSpellAttackPower
-- @usage
-- if AttackPower() >10000 Spell(rake)
-- if AttackPower(more 10000) Spell(rake)

OvaleCondition.conditions.attackpower = function(condition)
	return compare(OvalePaperDoll.attackPower, condition[1], condition[2])
end

--- Get the total count of the given aura across all targets.
-- @name BuffCount
-- @paramsig number
-- @param id The aura spell ID.
-- @return The total aura count.
-- @see DebuffCount

OvaleCondition.conditions.buffcount = function(condition)
	local start, ending, count = OvaleState:GetExpirationTimeOnAnyTarget(condition[1], getFilter(condition))
	return start, ending, count, 0, 0
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
	local start, ending = GetTargetAura(condition, getTarget(condition.target))
	return compare(diffTime(start, ending), condition[2], condition[3])
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
-- @param haste Optional. Sets whether "seconds" should be lengthened or shortened due to spell haste.
--     Defaults to haste=none.
--     Valid values: spell, none.
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
	local start, ending = GetTargetAura(condition, getTarget(condition.target))
	local timeBefore = avecHate(condition[2], condition.haste)
	if Ovale.trace then
		Ovale:Print("timeBefore = " .. tostring(timeBefore))
		Ovale:Print("start = " .. tostring(ending))
	end
	return addTime(ending, -timeBefore)
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
	local start, ending = GetTargetAura(condition, getTarget(condition.target))
	if ending then
		return start, ending, ending - start, start, -1
	else
		return nil
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
	local spellId = condition[1]
	if not spellId then Ovale:Error("buffgain parameter spellId is not optional"); return end
	local target = getTarget(condition.target)
	local gain = select(6, OvaleState:GetAura(target, spellId, true)) or 0
	return 0, nil, 0, 0, 1
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
-- @param haste Optional. Sets whether "seconds" should be lengthened or shortened due to spell haste.
--     Defaults to haste=none.
--     Valid values: spell, none.
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
	local start, ending = GetTargetAura(condition, getTarget(condition.target))
	local timeBefore = avecHate(condition[2], condition.haste)
	return start, addTime(ending, -timeBefore)
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
	local start, ending, stacks = GetTargetAura(condition, getTarget(condition.target))
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
	return OvaleAura:GetStealable(getTarget(condition.target))
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
	return testValue(condition[1], condition[2], OvaleState.state.burningembers, OvaleState.currentTime, OvaleState.powerRate.burningembers)
end

	-- Check if the player can cast (cooldown is down)
	-- 1: spellId
	-- returns: bool
OvaleCondition.conditions.cancast = function(condition)
	local name, rank, icon, cost, isFunnel, powerType, castTime = OvaleData:GetSpellInfoOrNil(condition[1])
	local actionCooldownStart, actionCooldownDuration, actionEnable = OvaleState:GetComputedSpellCD(condition[1])
	local startCast = actionCooldownStart + actionCooldownDuration
	if startCast<OvaleState.currentTime then
		startCast = OvaleState.currentTime
	end
	--TODO why + castTime?
	return startCast + castTime/1000
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
	local target = getTarget(condition.target)
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
		if isSameSpell(spellId, castSpellId, castSpellName) then
			return start, ending
		else
			return nil
		end
	elseif OvaleData.buffSpellList[spellId] then
		local found = false
		for k,v in pairs(OvaleData.buffSpellList[spellId]) do
			if isSameSpell(v, castSpellId, castSpellName) then
				return start, ending
			end
		end
		return nil
	elseif spellId == "harmful" then
		if not castSpellName then
			castSpellName = API_GetSpellInfo(castSpellId)
		end
		if API_IsHarmfulSpell(castSpellName) then
			return start, ending
		else
			return nil
		end
	elseif spellId == "helpful" then
		if not castSpellName then
			castSpellName = API_GetSpellInfo(castSpellId)
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
	local name, rank, icon, cost, isFunnel, powerType, castTime = OvaleData:GetSpellInfoOrNil(condition[1])
	if Ovale.trace then
		Ovale:Print("castTime/1000 = " .. (castTime/1000) .. " " .. tostring(condition[2]) .. " " .. tostring(condition[3]))
	end
	return compare(castTime/1000, condition[2], condition[3])
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
	return compare(currentCharges, condition[2], condition[3])
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
	return 0
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
	return 0
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
	return testValue(condition[1], condition[2], OvaleState.state.chi, OvaleState.currentTime, OvaleState.powerRate.chi)
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
	local loc, noloc = API_UnitClass(getTarget(condition.target))
	return testbool(noloc == condition[1], condition[2])
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
	local target = getTarget(condition.target)
	if API_UnitLevel(target) == -1 then
		classification = "worldboss"
	else
		classification = API_UnitClassification(target);
		if (classification == "rareelite") then
			classification = "elite"
		elseif (classification == "rare") then
			classification = "normal"
		end
	end
	return testbool(condition[1]==classification, condition[2])
end

--- Get the number of combo points on the currently selected target for a feral druid or a rogue.
-- @name ComboPoints
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of combo points.
-- @return A boolean value for the result of the comparison.
-- @see LastSpellComboPoints
-- @usage
-- if ComboPoints() >=1 Spell(savage_roar)
-- if ComboPoints(more 0) Spell(savage_roar)

OvaleCondition.conditions.combopoints = function(condition)
	return compare(OvaleState.state.combo, condition[1], condition[2])
end

--- Get the current value of a script counter.
-- @name Counter
-- @paramsig number or boolean
-- @param id The name of the counter. It should match one that's defined by inccounter=xxx in SpellInfo(...).
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The current value the counter.
-- @return A boolean value for the result of the comparison.
-- @see LastSpellComboPoints
-- @usage
-- if ComboPoints() >=1 Spell(savage_roar)
-- if ComboPoints(more 0) Spell(savage_roar)

OvaleCondition.conditions.counter = function(condition)
	return compare(OvaleState:GetCounterValue(condition[1]), condition[2], condition[3])
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
	return testbool(API_UnitCreatureFamily(getTarget(condition.target)) == LBCT[condition[1]], condition[2])
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
	local creatureType = API_UnitCreatureType(getTarget(condition.target))
	for _,v in pairs(condition) do
		if (creatureType == LBCT[v]) then
			return 0
		end
	end
	return nil
end

--- Get the current estimated damage of a spell if it is a critical strike.
-- @name CritDamage
-- @paramsig number
-- @param id The spell ID.
-- @return The estimated critical strike damage of the given spell.
-- @see Damage, LastSpellDamage, LastSpellEstimatedDamage

OvaleCondition.conditions.critdamage = function(condition)
	local spellId = condition[1]
	local ret = OvaleData:GetDamage(spellId, OvalePaperDoll.attackPower, OvalePaperDoll.spellBonusDamage, OvaleState.state.combo)
	return 0, nil, 2 * ret * OvaleAura:GetDamageMultiplier(spellId), 0, 0
end

--- Get the current estimated damage of a spell.
-- The calculated damage takes into account the current attack power, spellpower and combo points (if used).
-- The damage is computed from information for the spell set via SpellInfo(...):
--
-- damage = base + bonusap * AP + bonuscp * CP + bonusapcp * AP * CP + bonussp * SP
-- @name Damage
-- @paramsig number
-- @param id The spell ID.
-- @return The estimated damage of the given spell.
-- @see CritDamage, LastSpellDamage, LastSpellEstimatedDamage
-- @usage
-- if {Damage(rake) / LastSpellEstimateDamage(rake)} >1.1
--     Spell(rake)

OvaleCondition.conditions.damage = function(condition)
	local spellId = condition[1]
	local ret = OvaleData:GetDamage(spellId, OvalePaperDoll.attackPower, OvalePaperDoll.spellBonusDamage, OvaleState.state.combo)
	return 0, nil, ret * OvaleAura:GetDamageMultiplier(spellId), 0, 0
end

--- Get the current damage multiplier of a spell.
-- This currently does not take into account increased damage due to mastery.
-- @name DamageMultiplier
-- @paramsig number
-- @param id The spell ID.
-- @return The current damage multiplier of the given spell.
-- @see LastSpellDamageMultiplier
-- @usage
-- if {DamageMultiplier(rupture) / LastSpellDamageMultiplier(rupture)} >1.1
--     Spell(rupture)

OvaleCondition.conditions.damagemultiplier = function(condition)
	-- TODO: use OvaleState
	return 0, nil, OvaleAura:GetDamageMultiplier(condition[1]), 0, 0
end

--- Get the estimated number of seconds remaining before the target is dead.
-- @name DeadIn
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The number of seconds.
-- @return A boolean value for the result of the comparison.
-- @see TimeToDie
-- @usage
-- if target.DeadIn() <2 and ComboPoints() >0 Spell(eviscerate)
-- if target.DeadIn(less 2) and ComboPoints() >0 Spell(eviscerate)

OvaleCondition.conditions.deadin = function(condition)
	return testValue(condition[1], condition[2], 0, TimeToDie(getTarget(condition.target)), -1)
end

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
	return testValue(condition[1], condition[2], OvaleState.state.demonicfury, OvaleState.currentTime, OvaleState.powerRate.demonicfury)
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
		return compare(LRC:GetRange(getTarget(condition.target)), condition[1], condition[2])
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
	return compare(OvaleState.state.eclipse, condition[1], condition[2])
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
	return compare(OvaleState:GetEclipseDir(), condition[1], condition[2])
end

	-- Get the effective mana (e.g. if spell cost is divided by two, will returns the mana multiplied by two)
	-- TODO: not working
	-- returns: bool or number
OvaleCondition.conditions.effectivemana = function(condition)
	return testValue(condition[1], condition[2], OvaleState.state.mana, OvaleState.currentTime, OvaleState.powerRate.mana)
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
	return compare(OvaleEnemies.activeEnemies, condition[1], condition[2])
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
	return testValue(condition[1], condition[2], OvaleState.state.energy, OvaleState.currentTime, OvaleState.powerRate.energy)
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
	return compare(OvaleState.powerRate.energy, condition[1], condition[2])
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
	return testbool(API_UnitExists(getTarget(condition.target)) == 1, condition[1])
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
	return testValue(condition[1], condition[2], OvaleState.state.focus, OvaleState.currentTime, OvaleState.powerRate.focus)
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
	return compare(OvaleState.powerRate.focus, condition[1], condition[2])
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
	return compare(OvaleState.gcd, condition[1], condition[2])
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
	return testbool(OvaleData.glyphs[condition[1]], condition[2])
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
	return testbool(API_HasFullControl(), condition[1])
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
	return testbool(OvaleEquipement:HasShield(), condition[1])
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
		return testbool(OvaleEquipement:HasTrinket(trinketId), condition[2])
	elseif OvaleData.itemList[trinketId] then
		for _, v in pairs(OvaleData.itemList[trinketId]) do
			if OvaleEquipement:HasTrinket(v) then
				return testbool(true, condition[2])
			end
		end
	end
	return testbool(false, condition[2])
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
		return testbool(OvaleEquipement:HasOffHandWeapon(), condition[2])
	elseif condition[1] == "mainhand" then
		return testbool(OvaleEquipement:HasMainHandWeapon(), condition[2])
	else
		return testbool(false, condition[2])
	end
end

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
	return compare(OvaleState.state.holy, condition[1], condition[2])
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
	return testbool(Ovale.enCombat, condition[1])
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
	return testbool(OvaleFuture:InFlight(condition[1] or OvaleState.currentSpellId == condition[1]), condition[2])
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
	--TODO is IsSpellInRange using spell id now?
	local spellName = API_GetSpellInfo(condition[1])
	return testbool(API_IsSpellInRange(spellName, getTarget(condition.target)) == 1,condition[2])
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
	return 0, nil, actionCooldownDuration, actionCooldownStart, -1
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
	return compare(API_GetItemCount(condition[1]), condition[2], condition[3])
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
	return compare(API_GetItemCount(condition[1], false, true), condition[2], condition[3])
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
	return testbool(API_UnitDetailedThreatSituation("player", getTarget(condition.target)), condition[1])
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
	local fearSpellList = OvaleData:GetFearSpellList()
	return testbool(not API_HasFullControl() and isDebuffInList(fearSpellList), condition[1])
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
	return testbool(API_UnitIsFriend("player", getTarget(condition.target)), condition[1])
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
	local incapacitateSpellList = OvaleData:GetIncapacitateSpellList()
	return testbool(not API_HasFullControl() and isDebuffInList(incapacitateSpellList), condition[1])
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
	local target = getTarget(condition.target)
	local spell, rank, name, icon, start, ending, isTradeSkill, castID, protected = API_UnitCastingInfo(target)
	if not spell then
		spell, rank, name, icon, start, ending, isTradeSkill, protected = API_UnitChannelInfo(target)
	end
	return testbool(protected ~= nil and not protected, condition[1])
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
	local rootSpellList = OvaleData:GetRootSpellList()
	return testbool(isDebuffInList(rootSpellList), condition[1])
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
	local stunSpellList = OvaleData:GetStunSpellList()
	return testbool(not API_HasFullControl() and isDebuffInList(stunSpellList), condition[1])
end

--- Get the damage done by the most recent damage event for the given spell.
-- If the spell is a periodic aura, then it gives the damage done by the most recent tick.
-- @name LastSpellDamage
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The damage done.
-- @return A boolean value for the result of the comparison.
-- @see Damage, LastSpellEstimatedDamage
-- @usage
-- if LastDamage(ignite) >10000 Spell(combustion)
-- if LastDamage(ignite more 10000) Spell(combustion)

OvaleCondition.conditions.lastspelldamage = function(condition)
	local spellId = condition[1]
	if not OvaleSpellDamage:Get(spellId) then
		return nil
	end
	return compare(OvaleSpellDamage:Get(spellId), condition[2], condition[3])
end

--- Get the estimated damage of the most recent cast of a spell.
-- The calculated damage takes into account the values of attack power, spellpower and combo points (if used)
-- at the time the spell was most recent cast.
-- The damage is computed from information for the spell set via SpellInfo(...):
--
-- damage = base + bonusap * AP + bonuscp * CP + bonusapcp * AP * CP + bonussp * SP
-- @name LastSpellEstimatedDamage
-- @paramsig number
-- @param id The spell ID.
-- @return The estimated damage of the most recent cast of the given spell.
-- @see Damage, LastSpellDamage
-- @usage
-- if {Damage(rake) / LastSpellEstimateDamage(rake)} >1.1
--     Spell(rake)

OvaleCondition.conditions.lastspellestimateddamage = function(condition)
	local spellId = condition[1]
	local ret = OvaleData:GetDamage(spellId, OvaleFuture.lastSpellAP[spellId], OvaleFuture.lastSpellSP[spellId], OvaleFuture.lastSpellCombo[spellId])
	return 0, nil, ret * (OvaleFuture.lastSpellDM[spellId] or 0), 0, 0
end

--- Get the damage multiplier of the most recent cast of a spell.
-- This currently does not take into account increased damage due to mastery.
-- @name LastSpellDamageMultiplier
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The previous damage multiplier.
-- @return A boolean value for the result of the comparison.
-- @see DamageMultiplier
-- @usage
-- if {DamageMultiplier(rupture) / LastSpellDamageMultiplier(rupture)} >1.1
--     Spell(rupture)

OvaleCondition.conditions.lastspelldamagemultiplier = function(condition)
	return compare(OvaleFuture.lastSpellDM[condition[1]], condition[2], condition[3])
end

--- Get the attack power of the player during the most recent cast of a spell.
-- @name LastSpellAttackPower
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The previous attack power.
-- @return A boolean value for the result of the comparison.
-- @see AttackPower
-- @usage
-- if {Attackpower() / LastSpellAttackPower(hemorrhage)} >1.25
--     Spell(hemorrhage)

OvaleCondition.conditions.lastspellattackpower = function(condition)
	return compare(OvaleFuture.lastSpellAP[condition[1]], condition[2], condition[3])
end

--- Get the spellpower of the player during the most recent cast of a spell.
-- @name LastSpellSpellpower
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The previous spellpower.
-- @return A boolean value for the result of the comparison.
-- @see Spellpower
-- @usage
-- if {Spellpower() / LastSpellSpellpower(living_bomb)} >1.25
--     Spell(living_bomb)

OvaleCondition.conditions.lastspellspellpower = function(condition)
	return compare(OvaleFuture.lastSpellSP[condition[1]], condition[2], condition[3])
end

--- Get the number of combo points consumed by the most recent cast of a spell for a feral druid or a rogue.
-- @name LastSpellComboPoints
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of combo points.
-- @return A boolean value for the result of the comparison.
-- @see ComboPoints
-- @usage
-- if ComboPoints() >3 and LastComboPoints(rip) <3
--     Spell(rip)

OvaleCondition.conditions.lastspellcombopoints = function(condition)
	return compare(OvaleFuture.lastSpellCombo[condition[1]], condition[2], condition[3])
end

--- Get the mastery effect of the player during the most recent cast of a spell.
-- Mastery effect is the effect of the player's mastery, typically a percent-increase to damage
-- or a percent-increase to chance to trigger some effect.
-- @name LastSpellMastery
-- @paramsig number or boolean
-- @param id The spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The previous mastery effect.
-- @return A boolean value for the result of the comparison.
-- @see Mastery
-- @usage
-- if {Mastery(shadow_bolt) - LastSpellMastery(shadow_bolt)} > 1000
--     Spell(metamorphosis)

OvaleCondition.conditions.lastspellmastery = function(condition)
	return compare(OvaleFuture.lastSpellMastery[condition[1]], condition[2], condition[3])
end

--- Get the time elapsed in seconds since the player's previous melee swing (white attack).
-- @name LastSwing
-- @paramsig number
-- @param hand Optional. Sets which hand weapon's melee swing.
--     If no hand is specified, then return the time elapsed since the previous swing of either hand's weapon.
--     Valid values: main, off.
-- @return The number of seconds.
-- @see NextSwing

OvaleCondition.conditions.lastswing = function(condition)
	return 0, nil, 0, OvaleSwing:GetLast(condition[1]), 1
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
	local target = getTarget(condition.target)
	local level
	if target == "player" then
		level = OvalePaperDoll.level
	else
		level = API_UnitLevel(target)
	end
	return compare(level, condition[1], condition[2])
end

--- Get the current amount of health points of the target.
-- @name Life
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The current health.
-- @return A boolean value for the result of the comparison.
-- @see Health
-- @usage
-- if Life() <10000 Spell(last_stand)
-- if Life(less 10000) Spell(last_stand)

OvaleCondition.conditions.life = function(condition)
	local target = getTarget(condition.target)
	return compare(API_UnitHealth(target), condition[1], condition[2])
end
OvaleCondition.conditions.health = OvaleCondition.conditions.life

--- Get the number of health points away from full health of the target.
-- @name LifeMissing
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The current missing health.
-- @return A boolean value for the result of the comparison.
-- @see HealthMissing
-- @usage
-- if LifeMissing() <20000 Item(healthstone)
-- if LifeMissing(less 20000) Item(healthstone)

OvaleCondition.conditions.lifemissing = function(condition)
	local target = getTarget(condition.target)
	return compare(API_UnitHealthMax(target) - API_UnitHealth(target), condition[1], condition[2])
end
OvaleCondition.conditions.healthmissing = OvaleCondition.conditions.lifemissing

--- Get the current percent level of health of the target.
-- @name LifePercent
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The current health percent.
-- @return A boolean value for the result of the comparison.
-- @see HealthPercent
-- @usage
-- if LifePercent() <20 Spell(last_stand)
-- if target.LifePercent(less 25) Spell(kill_shot)

OvaleCondition.conditions.lifepercent = function(condition)
	--TODO: use prediction based on the DPS on the target
	local target = getTarget(condition.target)
	local targetHealthMax = API_UnitHealthMax(target) or 0
	if targetHealthMax == 0 then
		return nil
	end
	return compare(100 * API_UnitHealth(target) / targetHealthMax, condition[1], condition[2])
end
OvaleCondition.conditions.healthpercent = OvaleCondition.conditions.lifepercent

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
	if (condition[1]) then
		if (Ovale:GetListValue(condition[1]) == condition[2]) then
			return 0
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
	local target = getTarget(condition.target)
	if target == "player" then
		return testValue(condition[1], condition[2], OvaleState.state.mana, OvaleState.currentTime, OvaleState.powerRate.mana)
	else
		return compare(API_UnitPower(target), condition[1], condition[2])
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
	local target = getTarget(condition.target)
	local powerMax = API_UnitPowerMax(target, 0) or 0
	if powerMax == 0 then
		return nil
	end
	if target == "player "then
		local conversion = 100 / powerMax
		return testValue(condition[1], condition[2], OvaleState.state.mana * conversion, OvaleState.currentTime, OvaleState.powerRate.mana * conversion)
	else
		return compare(API_UnitPower(target, 0)*100 / powerMax, condition[1], condition[2])
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
-- @see LastSpellMastery
-- @usage
-- if {DamageMultiplier(rake) * {1 + Mastery()/100}} >1.8
--     Spell(rake)

OvaleCondition.conditions.mastery = function(condition)
	return compare(OvalePaperDoll.masteryEffect, condition[1], condition[2])
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
	local target = getTarget(condition.target)
	return compare(API_UnitHealthMax(target), condition[1], condition[2])
end

--- Get the level of mana of the target when it is at full mana.
-- @name MaxMana
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The maximum mana.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if {MaxMana() - Mana()} > 12500 Item(mana_gem)

OvaleCondition.conditions.maxmana = function(condition)
	return compare(API_UnitPowerMax(getTarget(condition.target)), condition[1], condition[2])
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
	return 0, nil, 0, OvaleSwing:GetNext(condition[1]), 0, -1
end

--- Get the number of seconds until the next tick of a periodic aura on the target.
-- @name NextTick
-- @paramsig number
-- @param id The aura spell ID.
-- @param filter Optional. The type of aura to check.
--     Default is any.
--     Valid values: any, buff, debuff
-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
--     Defaults to target=player.
--     Valid values: player, target, focus, pet.
-- @return The number of seconds.
-- @see Ticks, TicksRemain, TickTime

OvaleCondition.conditions.nexttick = function(condition)
	local start, ending, _, spellHasteMultiplier = GetTargetAura(condition, getTarget(condition.target))
	local tickLength = OvaleData:GetTickLength(condition[1], spellHasteMultiplier)
	if ending and tickLength then
		while ending - tickLength > OvaleState.currentTime do
			ending = ending - tickLength
		end
		return 0, nil, 0, ending, -1
	end
	return nil
end

	-- Check if the aura is not on any other unit than the current target
	-- 1: spell id
	-- return: bool
	-- alias: otherauraexpires
OvaleCondition.conditions.otherauraexpires = function(condition)
	local minTime, maxTime = getOtherAura(condition[1], getFilter(condition), condition[3], "target")
	if minTime then
		local timeBefore = condition[2] or 0
		return minTime - timeBefore, nil
	end
	return 0, nil
end
OvaleCondition.conditions.otherbuffexpires = OvaleCondition.conditions.otherauraexpires
OvaleCondition.conditions.otherdebuffexpires = OvaleCondition.conditions.otherauraexpires

	-- Check if the aura is present on any other unit than the current target
	-- return: bool
	-- alias: otheraurapresent
OvaleCondition.conditions.otheraurapresent = function(condition)
	local minTime, maxTime = getOtherAura(condition[1], getFilter(condition), condition[3], "target")
	if maxTime and maxTime>0 then
		local timeBefore = condition[2] or 0
		return 0, addTime(maxTime, -timeBefore)
	end
	return nil
end
OvaleCondition.conditions.otherbuffpresent = OvaleCondition.conditions.otheraurapresent
OvaleCondition.conditions.otherdebuffpresent = OvaleCondition.conditions.otheraurapresent

	-- Get the maximum aura remaining duration on any target
	-- return: number
OvaleCondition.conditions.otherauraremains = function(condition)
	local minTime, maxTime = getOtherAura(condition[1], getFilter(condition))
	return 0, nil, 0, maxTime, -1
end
OvaleCondition.conditions.otherbuffremains = OvaleCondition.conditions.otherauraremains
OvaleCondition.conditions.otherdebuffremains = OvaleCondition.conditions.otherauraremains

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
	local target = getTarget(condition.target)
	return testbool(API_UnitExists(target) and not API_UnitIsDead(target), condition[1])
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
	return testbool(condition[1] == OvaleState.lastSpellId, condition[2])
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
	return testbool(API_UnitExists("pet") and not API_UnitIsDead("pet"), condition[1])
end

--- Test if the game is on a PTR server
-- @paramsig boolean
-- @param yesno Optional. If yes, then returns true if it is a PTR realm. If no, return true if it is a live realm.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value
OvaleCondition.conditions.ptr = function(condition)
	local uiVersion = select(4, API_GetBuildInfo())
	return testbool(uiVersion > 50200, condition[1])
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
	return testValue(condition[1], condition[2], OvaleState.state.rage, OvaleState.currentTime, OvaleState.powerRate.rage)
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
	local target = getTarget(condition.target)
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
	return compare(difference, condition[1], condition[2])
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
	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = API_UnitCastingInfo(getTarget(condition.target))
	if not endTime then
		return nil
	end
	return 0, nil, 0, endTime/1000, -1
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
	return 0, nil, GetRuneCount(condition[1], condition.death)
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
	return 0, nil, 0, ret, -1
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
	return testValue(condition[1], condition[2], OvaleState.state.runicpower, OvaleState.currentTime, OvaleState.powerRate.runicpower)
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
	return testValue(condition[1], condition[2], OvaleState.state.shadoworbs, OvaleState.currentTime, OvaleState.powerRate.shadoworbs)
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
	return compare(OvaleState.state.shards, condition[1], condition[2])
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
	return compare(API_GetUnitSpeed(getTarget(condition.target))*100/7, condition[1], condition[2])
end

--- Test if the given spell is usable.
-- A spell is usable if the player has learned the spell and has the resources required to cast the spell.
-- @name SpellUsable
-- @paramsig boolean
-- @param id The spell ID.
-- @param yesno Optional. If yes, then return true if the target is aggroed. If no, then return true if it isn't aggroed.
--     Default is yes.
--     Valid values: yes, no.
-- @return A boolean value.
-- @usage
-- if SpellUsable(tigers_fury) Spell(berserk_cat)

OvaleCondition.conditions.spellusable = function(condition)
	return testbool(API_IsUsableSpell(condition[1]), condition[2])
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
	return compare(charges, condition[2], condition[3])
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
		return 0, nil, cooldownDuration, cooldownStart, -1
	else
		return 0, nil, 0, 0, 0
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
	if type(condition[1]) == "string" then
		local sharedCd = OvaleState.state.cd[condition[1]]
		if sharedCd then
			return 0, nil, sharedCd.duration, sharedCd.start, -1
		else
			return nil
		end
	elseif not OvaleData.spellList[condition[1]] then
		return 0, nil, 0, OvaleState.currentTime + 3600, -1
	else
		local actionCooldownStart, actionCooldownDuration, actionEnable = OvaleState:GetComputedSpellCD(condition[1])
		return 0, nil, actionCooldownDuration, actionCooldownStart, -1
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
			return 0, nil, ret, 0, 0
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
-- @see LastSpellSpellpower
-- @usage
-- if {Spellpower() / LastSpellSpellpower(living_bomb)} >1.25
--     Spell(living_bomb)

OvaleCondition.conditions.spellpower = function(condition)
	return compare(OvalePaperDoll.spellBonusDamage, condition[1], condition[2])
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
		return 0
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
	return testbool(API_IsStealthed(), condition[1])
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
	return compare(OvaleData:GetTalentPoints(condition[1]), condition[2], condition[3])
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
	return testbool(API_UnitIsUnit("player", getTarget(condition.target).."target"), condition[1])
end

--- Get the amount of threat on the current target relative to the its primary aggro target, scaled to between 0 (zero) and 100.
-- This is a number between 0 (no threat) and 100 (will become the primary aggro target).
-- @name Threat
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The amount of threat.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if Threat() >90 Spell(fade)
-- if Threat(more 90) Spell(fade)

OvaleCondition.conditions.threat = function(condition)
	local isTanking, status, threatpct = API_UnitDetailedThreatSituation("player", getTarget(condition.target))
	return compare(threatpct, condition[1], condition[2])
end

--- Get the current tick value of a periodic aura on the target.
-- @name TickValue
-- @paramsig number or boolean
-- @param id The aura spell ID.
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
	local value = select(5, getAura(getTarget(condition.target), condition[1], getFilter(condition), getMine(condition))) or 0
	return compare(value, condition[2], condition[3])
end

--- Get the estimated total number of ticks of a periodic aura.
-- @name Ticks
-- @paramsig number or boolean
-- @param id The aura spell ID.
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of ticks.
-- @return A boolean value for the result of the comparison.
-- @see NextTick, TicksRemain, TickTime

OvaleCondition.conditions.ticks = function(condition)
	-- TODO: extend to allow checking an existing DoT (how to get DoT duration?)
	local spellId = condition[1]
	local duration, tickLength = OvaleData:GetDuration(spellId, OvalePaperDoll:GetSpellHasteMultiplier(), OvaleState.state.combo, OvaleState.state.holy)
	if tickLength then
		local numTicks = floor(duration / tickLength + 0.5)
		return compare(numTicks, condition[2], condition[3])
	end
	return nil
end

--- Get the number of ticks that would be added if the dot is refreshed.
-- Not implemented, always returns 0.
-- @name TicksAdded
-- @paramsig number
-- @param id The aura spell ID
-- @return The number of added ticks.

OvaleCondition.conditions.ticksadded = function(condition)
	return 0, nil, 0, 0, 0
end

--- Get the remaining number of ticks of a periodic aura on a target.
-- @name TicksRemain
-- @paramsig number
-- @param id The aura spell ID.
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
	local start, ending, _, spellHasteMultiplier = GetTargetAura(condition, getTarget(condition.target))
	local tickLength = OvaleData:GetTickLength(condition[1], spellHasteMultiplier)
	if ending and tickLength then
		return 0, nil, 1, ending, -1/tickLength
	end
	return nil
end

--- Get the number of seconds between ticks of a periodic aura on a target.
-- @name TickTime
-- @paramsig number or boolean
-- @param id The aura spell ID.
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
	local start, ending, _, spellHasteMultiplier = GetTargetAura(condition, getTarget(condition.target))
	if not start or not ending or start > OvaleState.currentTime or ending < OvaleState.currentTime then
		spellHasteMultiplier = OvalePaperDoll:GetSpellHasteMultiplier()
	end
	local tickLength = OvaleData:GetTickLength(condition[1], spellHasteMultiplier)
	if tickLength then
		return compare(tickLength, condition[2], condition[3])
	end
	return nil
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
	return testValue(condition[1], condition[2], 0, Ovale.combatStartTime, 1)
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
	return 0, nil, 0, TimeToDie(getTarget(condition.target)), -1
end

--- Get the number of seconds before the player reaches maximum energy for feral druids, non-mistweaver monks and rogues.
-- @name TimeToMaxEnergy
-- @paramsig number or boolean
-- @param operator Optional. Comparison operator: equal, less, more.
-- @param number Optional. The number to compare against.
-- @return The number of seconds.
-- @return A boolean value for the result of the comparison.
-- @usage
-- if TimeInToMaxEnergy() < 1.2 Spell(sinister_strike)
-- if TimeInToMaxEnergy(less 1.2) Spell(sinister_strike)

OvaleCondition.conditions.timetomaxenergy = function(condition)
-- TODO: temp, need to allow function calls in functions call to do things link TimeTo(Energy() == 100) which would be TimeTo(Equal(Energy(), 100))
-- TODO: This incorrect for class specializations that can exceed 100 energy.
	local t = OvaleState.currentTime + (100 - OvaleState.state.energy) / OvaleState.powerRate.energy
	return 0, nil, 0, t, -1
end

	-- Multiply a time by the current spell haste
	-- 1: the time
	-- return: number
OvaleCondition.conditions.timewithhaste = function(condition)
	return 0, nil, avecHate(condition[1], "spell"),0,0
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
	if type(condition[1]) ~= "number" then
		condition[1] = OVALE_TOTEMTYPE[condition[1]]
	end
	
	local haveTotem, totemName, startTime, duration = API_GetTotemInfo(condition[1])
	if not startTime then
		return 0
	end
	if (condition.totem and OvaleData:GetSpellInfoOrNil(condition.totem)~=totemName) then
		return 0
	end
	return addTime(startTime + duration, -(condition[2] or 0))
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
	if type(condition[1]) ~= "number" then
		condition[1] = OVALE_TOTEMTYPE[condition[1]]
	end

	local haveTotem, totemName, startTime, duration = API_GetTotemInfo(condition[1])
	if not startTime then
		return nil
	end
	if (condition.totem and OvaleData:GetSpellInfoOrNil(condition.totem)~=totemName) then
		return nil
	end
	return startTime, startTime + duration
end

	-- Check if a tracking is enabled
	-- 1: the spell id
	-- return bool
OvaleCondition.conditions.tracking = function(condition)
	local what = OvaleData:GetSpellInfoOrNil(condition[1])
	local numTrackingTypes = API_GetNumTrackingTypes()
	local present = false
	for i=1,numTrackingTypes do
		local name, texture, active = API_GetTrackingInfo(i)
		if name == what then
			present = (active == 1)
			break
		end
	end
	return testbool(present, condition[2])
end

--- A condition that always returns true.
-- @name True
-- @paramsig boolean
-- @return A boolean value.

OvaleCondition.conditions["true"] = function(condition)
	return 0, nil
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
			return 0
		end
		mainHandExpiration = mainHandExpiration/1000
		if ((condition[2] or 0) >= mainHandExpiration) then
			return 0
		else
			return OvaleState.maintenant + mainHandExpiration - (condition[2] or 60)
		end
	else
		if (not hasOffHandEnchant) then
			return 0
		end
		offHandExpiration = offHandExpiration/1000
		if ((condition[2] or 0) >= offHandExpiration) then
			return 0
		else
			return OvaleState.maintenant + offHandExpiration - (condition[2] or 60)
		end
	end
end

OvaleCondition.defaultTarget = "target"

--</public-static-properties>
