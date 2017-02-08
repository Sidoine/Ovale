--[[--------------------------------------------------------------------
    Copyright (C) 2009, 2010, 2011, 2012, 2013 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...

local LibBabbleCreatureType = LibStub("LibBabble-CreatureType-3.0", true)
local LibRangeCheck = LibStub("LibRangeCheck-2.0", true)
local OvaleBestAction = Ovale.OvaleBestAction
local OvaleCompile = Ovale.OvaleCompile
local OvaleCondition = Ovale.OvaleCondition
local OvaleCooldown = Ovale.OvaleCooldown
local OvaleDamageTaken = Ovale.OvaleDamageTaken
local OvaleData = Ovale.OvaleData
local OvaleEquipment = Ovale.OvaleEquipment
local OvaleFuture = Ovale.OvaleFuture
local OvaleGUID = Ovale.OvaleGUID
local OvaleHealth = Ovale.OvaleHealth
local OvalePower = Ovale.OvalePower
local OvaleRunes = Ovale.OvaleRunes
local OvaleSpellBook = Ovale.OvaleSpellBook
local OvaleSpellDamage = Ovale.OvaleSpellDamage
local OvaleArtifact = Ovale.OvaleArtifact
local OvaleBossMod = Ovale.OvaleBossMod

local floor = math.floor
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local type = type
local wipe = wipe
local API_GetBuildInfo = GetBuildInfo
local API_GetItemCooldown = GetItemCooldown
local API_GetItemCount = GetItemCount
local API_GetNumTrackingTypes = GetNumTrackingTypes
local API_GetTime = GetTime
local API_GetTrackingInfo = GetTrackingInfo
local API_GetUnitSpeed = GetUnitSpeed
local API_GetWeaponEnchantInfo = GetWeaponEnchantInfo
local API_HasFullControl = HasFullControl
local API_IsSpellOverlayed = IsSpellOverlayed
local API_IsStealthed = IsStealthed
local API_UnitCastingInfo = UnitCastingInfo
local API_UnitChannelInfo = UnitChannelInfo
local API_UnitClass = UnitClass
local API_UnitClassification = UnitClassification
local API_UnitCreatureFamily = UnitCreatureFamily
local API_UnitCreatureType = UnitCreatureType
local API_UnitDetailedThreatSituation = UnitDetailedThreatSituation
local API_UnitExists = UnitExists
local API_UnitIsDead = UnitIsDead
local API_UnitIsFriend = UnitIsFriend
local API_UnitIsPVP = UnitIsPVP
local API_UnitIsUnit = UnitIsUnit
local API_UnitLevel = UnitLevel
local API_UnitName = UnitName
local API_UnitPower = UnitPower
local API_UnitPowerMax = UnitPowerMax
local API_UnitRace = UnitRace
local API_UnitStagger = UnitStagger
local INFINITY = math.huge

local Compare = OvaleCondition.Compare
local ParseCondition = OvaleCondition.ParseCondition
local TestBoolean = OvaleCondition.TestBoolean
local TestValue = OvaleCondition.TestValue

--[[--------------------
	Helper functions
--]]--------------------

-- Return the target's damage reduction from armor, assuming the target is boss-level.
-- This function makes heavy use of magic constants and is only valid for level 93 bosses.
local function BossArmorDamageReduction(target, state)
	-- Boss armor value empirically determined.
	local armor = 24835
	local constant = 4037.5 * state.level - 317117.5
	if constant < 0 then
		constant = 0
	end
	return armor / (armor + constant)
end

--[[
	Return the value of a parameter from the named spell's information.  If the value is the name of a
	function in the script, then return the compute the value of that function instead.
--]]
local function ComputeParameter(spellId, paramName, state, atTime)
	local si = OvaleData:GetSpellInfo(spellId)
	if si and si[paramName] then
		local name = si[paramName]
		local node = OvaleCompile:GetFunctionNode(name)
		if node then
			local timeSpan, element = OvaleBestAction:Compute(node.child[1], state, atTime)
			if element and element.type == "value" then
				local value = element.value + (state.currentTime - element.origin) * element.rate
				return value
			end
		else
			return si[paramName]
		end
	end
	return nil
end

-- Return the time in seconds, adjusted by the named haste effect.
local function GetHastedTime(seconds, haste, state)
	seconds = seconds or 0
	local multiplier = state:GetHasteMultiplier(haste)
	return seconds / multiplier
end

--[[---------------------
	Script conditions
--]]---------------------

do
	-- Test if a white hit just occured
	-- 1 : maximum time after a white hit
	-- Not useful anymore. No widely used spell reset swing timer anyway

	local function AfterWhiteHit(positionalParams, namedParams, state, atTime)
		local seconds, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = 0
		Ovale:OneTimeMessage("Warning: 'AfterWhiteHit()' is not implemented.")
		return TestValue(0, INFINITY, value, state.currentTime, -1, comparator, limit)
	end

	--OvaleCondition:RegisterCondition("afterwhitehit", false, AfterWhiteHit)
end

do
	--- Check whether the player currently has an armor set bonus.
	-- @name ArmorSetBonus
	-- @paramsig number
	-- @param name The name of the armor set.
	--     Valid names: T11, T12, T13, T14, T15, T16
	--     Valid names for hybrid classes: append _caster, _heal, _melee, _tank.
	-- @param count The number of pieces needed to activate the armor set bonus.
	-- @return 1 if the set bonus is active, or 0 otherwise.
	-- @usage
	-- if ArmorSetBonus(T16_melee 2) == 1 Spell(unleash_elements)

	local function ArmorSetBonus(positionalParams, namedParams, state, atTime)
		local armorSet, count = positionalParams[1], positionalParams[2]
		local value = (OvaleEquipment:GetArmorSetCount(armorSet) >= count) and 1 or 0
		return 0, INFINITY, value, 0, 0
	end

	OvaleCondition:RegisterCondition("armorsetbonus", false, ArmorSetBonus)
end

do
	--- Get how many pieces of an armor set, e.g., Tier 14 set, are equipped by the player.
	-- @name ArmorSetParts
	-- @paramsig number or boolean
	-- @param name The name of the armor set.
	--     Valid names: T11, T12, T13, T14, T15.
	--     Valid names for hybrid classes: append _caster, _heal, _melee, _tank.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of pieces of the named set that are equipped by the player.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if ArmorSetParts(T13) >=2 and target.HealthPercent() <60
	--     Spell(ferocious_bite)
	-- if ArmorSetParts(T13 more 1) and TargetHealthPercent(less 60)
	--     Spell(ferocious_bite)

	local function ArmorSetParts(positionalParams, namedParams, state, atTime)
		local armorSet, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = OvaleEquipment:GetArmorSetCount(armorSet)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("armorsetparts", false, ArmorSetParts)
end

do
	local function ArtifactTraitRank(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = OvaleArtifact:TraitRank(spellId)
		return Compare(value, comparator, limit)
	end

	local function HasArtifactTrait(positionalParams, namedParams, state, atTime)
		local spellId, yesno = positionalParams[1], positionalParams[2]
		local value = OvaleArtifact:HasTrait(spellId)
		return TestBoolean(value, yesno)
	end

	OvaleCondition:RegisterCondition("hasartifacttrait", false, HasArtifactTrait)
	OvaleCondition:RegisterCondition("artifacttraitrank", false, ArtifactTraitRank)
end

do
	--- Get the base duration of the aura in seconds if it is applied at the current time.
	-- @name BaseDuration
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The base duration in seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see BuffDuration
	-- @usage
	-- if BaseDuration(slice_and_dice_buff) > BuffDuration(slice_and_dice_buff)
	--     Spell(slice_and_dice)

	local function BaseDuration(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value
		if (OvaleData.buffSpellList[auraId]) then
			local spellList = OvaleData.buffSpellList[auraId]
			local count = 0
			for id in pairs(spellList) do
				value = OvaleData:GetBaseDuration(id, state)
				if value ~=  math.huge then
					break
				end
			end
		else
			value = OvaleData:GetBaseDuration(auraId, state)
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("baseduration", false, BaseDuration)
	OvaleCondition:RegisterCondition("buffdurationifapplied", false, BaseDuration)
	OvaleCondition:RegisterCondition("debuffdurationifapplied", false, BaseDuration)
end

do
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

	local function BuffAmount(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local value = namedParams.value or 1
		local statName = "value1"
		if value == 1 then
			statName = "value1"
		elseif value == 2 then
			statName = "value2"
		elseif value == 3 then
			statName = "value3"
		end
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura, atTime) then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			local value = aura[statName] or 0
			return TestValue(gain, ending, value, start, 0, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffamount", false, BuffAmount)
	OvaleCondition:RegisterCondition("debuffamount", false, BuffAmount)
	OvaleCondition:RegisterCondition("tickvalue", false, BuffAmount)
end

do
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

	local function BuffComboPoints(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura, atTime) then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			local value = aura and aura.combo or 0
			return TestValue(gain, ending, value, start, 0, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffcombopoints", false, BuffComboPoints)
	OvaleCondition:RegisterCondition("debuffcombopoints", false, BuffComboPoints)
end

do
	--- Get the number of seconds before a buff can be gained again.
	-- @name BuffCooldown
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffCooldown
	-- @usage
	-- if BuffCooldown(trinket_stat_agility_buff) > 45
	--     Spell(tigers_fury)

	local function BuffCooldown(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain, cooldownEnding = aura.gain, aura.cooldownEnding
			cooldownEnding = aura.cooldownEnding or 0
			return TestValue(gain, INFINITY, 0, cooldownEnding, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffcooldown", false, BuffCooldown)
	OvaleCondition:RegisterCondition("debuffcooldown", false, BuffCooldown)
end

do
	-- Get the number of buff if the given spell list
	-- @name BuffCount
	-- @paramsig number or boolean
	-- @param id the spell list ID	
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of buffs
	-- @return A boolean value for the result of the comparison
	local function BuffCount(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local spellList = OvaleData.buffSpellList[auraId]
		local count = 0
		for id in pairs(spellList) do
			local si = OvaleData.spellInfo[id]
			local aura = state:GetAura(target, id, filter, mine)
			if state:IsActiveAura(aura, atTime) then
				count = count + 1
			end
		end
		return Compare(count, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffcount", false, BuffCount)
end

do
	--- Get the duration in seconds of the cooldown before a buff can be gained again.
	-- @name BuffCooldownDuration
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffCooldown
	-- @usage
	-- if target.TimeToDie() > BuffCooldownDuration(trinket_stat_any_buff)
	--     Item(Trinket0Slot)

	local function BuffCooldownDuration(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local minCooldown = INFINITY
		if OvaleData.buffSpellList[auraId] then
			for id in pairs(OvaleData.buffSpellList[auraId]) do
				local si = OvaleData.spellInfo[id]
				local cd = si and si.buff_cd
				if cd and minCooldown > cd then
					minCooldown = cd
				end
			end
		else
			minCooldown = 0
		end
		return Compare(minCooldown, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffcooldownduration", false, BuffCooldownDuration)
	OvaleCondition:RegisterCondition("debuffcooldownduration", false, BuffCooldownDuration)
end

do
	--- Get the total count of the given aura across all targets.
	-- @name BuffCountOnAny
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param stacks Optional. The minimum number of stacks of the aura required.
	--     Defaults to stacks=1.
	--     Valid values: any number greater than zero.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param excludeTarget Optional. Sets whether to ignore the current target when scanning targets.
	--     Defaults to excludeTarget=0.
	--     Valid values: 0, 1.
	-- @return The total aura count.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffCountOnAny

	local function BuffCountOnAny(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local _, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local excludeUnitId = (namedParams.excludeTarget == 1) and state.defaultTarget or nil

		local count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast = state:AuraCount(auraId, filter, mine, namedParams.stacks, atTime, excludeUnitId)
		if count > 0 and startChangeCount < INFINITY then
			local origin = startChangeCount
			local rate = -1 / (endingChangeCount - startChangeCount)
			local start, ending = startFirst, endingLast
			return TestValue(start, ending, count, origin, rate, comparator, limit)
		end
		return Compare(count, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffcountonany", false, BuffCountOnAny)
	OvaleCondition:RegisterCondition("debuffcountonany", false, BuffCountOnAny)
end

do
	--- Get the current direction of an aura's stack count.
	-- A negative number means the aura is decreasing in stack count.
	-- A positive number means the aura is increasing in stack count.
	-- @name BuffDirection
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current direction.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffDirection

	local function BuffDirection(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain, start, ending, direction = aura.gain, aura.start, aura.ending, aura.direction
			return TestValue(gain, INFINITY, direction, gain, 0, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffdirection", false, BuffDirection)
	OvaleCondition:RegisterCondition("debuffdirection", false, BuffDirection)
end

do
	--- Get the total duration of the aura from when it was first applied to when it ended.
	-- @name BuffDuration
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The total duration of the aura.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffDuration

	local function BuffDuration(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura, atTime) then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			local value = ending - start
			return TestValue(gain, ending, value, start, 0, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffduration", false, BuffDuration)
	OvaleCondition:RegisterCondition("debuffduration", false, BuffDuration)
end

do
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

	local function BuffExpires(positionalParams, namedParams, state, atTime)
		local auraId, seconds = positionalParams[1], positionalParams[2]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			seconds = GetHastedTime(seconds, namedParams.haste, state)
			if ending - seconds <= gain then
				return gain, INFINITY
			else
				return ending - seconds, INFINITY
			end
		end
		return 0, INFINITY
	end

	OvaleCondition:RegisterCondition("buffexpires", false, BuffExpires)
	OvaleCondition:RegisterCondition("debuffexpires", false, BuffExpires)

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

	local function BuffPresent(positionalParams, namedParams, state, atTime)
		local auraId, seconds = positionalParams[1], positionalParams[2]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			seconds = GetHastedTime(seconds, namedParams.haste, state)
			if ending - seconds <= gain then
				return nil
			else
				return gain, ending - seconds
			end
		end
		return nil
	end

	OvaleCondition:RegisterCondition("buffpresent", false, BuffPresent)
	OvaleCondition:RegisterCondition("debuffpresent", false, BuffPresent)
end

do
	--- Get the time elapsed since the aura was last gained on the target.
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffGain

	local function BuffGain(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain = aura.gain or 0
			return TestValue(gain, INFINITY, 0, gain, 1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffgain", false, BuffGain)
	OvaleCondition:RegisterCondition("debuffgain", false, BuffGain)
end

do
	--- Get the player's persistent multiplier for the given aura at the time the aura was applied on the target.
	-- The persistent multiplier is snapshotted to the aura for its duration at the time the aura is applied.
	-- @name BuffPersistentMultiplier
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The persistent multiplier.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffPersistentMultiplier
	-- @usage
	-- if target.DebuffPersistentMultiplier(rake) < 1 Spell(rake)

	local function BuffPersistentMultiplier(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura, atTime) then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			local value = aura.damageMultiplier or 1
			return TestValue(gain, ending, value, start, 0, comparator, limit)
		end
		return Compare(1, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffpersistentmultiplier", false, BuffPersistentMultiplier)
	OvaleCondition:RegisterCondition("debuffpersistentmultiplier", false, BuffPersistentMultiplier)
end

do
	--- Get the remaining time in seconds on an aura.
	-- @name BuffRemaining
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds remaining on the aura.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffRemaining
	-- @usage
	-- if BuffRemaining(slice_and_dice) <2
	--     Spell(slice_and_dice)

	local function BuffRemaining(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			return TestValue(gain, INFINITY, 0, ending, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffremaining", false, BuffRemaining)
	OvaleCondition:RegisterCondition("debuffremaining", false, BuffRemaining)
	OvaleCondition:RegisterCondition("buffremains", false, BuffRemaining)
	OvaleCondition:RegisterCondition("debuffremains", false, BuffRemaining)
end

do
	--- Get the remaining time in seconds before the aura expires across all targets.
	-- @name BuffRemainingOnAny
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param stacks Optional. The minimum number of stacks of the aura required.
	--     Defaults to stacks=1.
	--     Valid values: any number greater than zero.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param excludeTarget Optional. Sets whether to ignore the current target when scanning targets.
	--     Defaults to excludeTarget=0.
	--     Valid values: 0, 1.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffRemainingOnAny

	local function BuffRemainingOnAny(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local _, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local excludeUnitId = (namedParams.excludeTarget == 1) and state.defaultTarget or nil

		local count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast = state:AuraCount(auraId, filter, mine, namedParams.stacks, atTime, excludeUnitId)
		if count > 0 then
			local start, ending = startFirst, endingLast
			return TestValue(start, INFINITY, 0, ending, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffremainingonany", false, BuffRemainingOnAny)
	OvaleCondition:RegisterCondition("debuffremainingonany", false, BuffRemainingOnAny)
	OvaleCondition:RegisterCondition("buffremainsonany", false, BuffRemainingOnAny)
	OvaleCondition:RegisterCondition("debuffremainsonany", false, BuffRemainingOnAny)
end

do
	--- Get the number of stacks of an aura on the target.
	-- @name BuffStacks
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of stacks of the aura.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffStacks
	-- @usage
	-- if BuffStacks(pet_frenzy any=1) ==5
	--     Spell(focus_fire)
	-- if target.DebuffStacks(weakened_armor) <3
	--     Spell(faerie_fire)

	local function BuffStacks(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura, atTime) then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			local value = aura.stacks or 0
			return TestValue(gain, ending, value, start, 0, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffstacks", false, BuffStacks)
	OvaleCondition:RegisterCondition("debuffstacks", false, BuffStacks)
end

do
	--- Get the total number of stacks of the given aura across all targets.
	-- @name BuffStacksOnAny
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param excludeTarget Optional. Sets whether to ignore the current target when scanning targets.
	--     Defaults to excludeTarget=0.
	--     Valid values: 0, 1.
	-- @return The total number of stacks.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffStacksOnAny

	local function BuffStacksOnAny(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local _, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local excludeUnitId = (namedParams.excludeTarget == 1) and state.defaultTarget or nil

		local count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast = state:AuraCount(auraId, filter, mine, 1, atTime, excludeUnitId)
		if count > 0 then
			local start, ending = startFirst, endingChangeCount
			return TestValue(start, ending, stacks, start, 0, comparator, limit)
		end
		return Compare(count, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffstacksonany", false, BuffStacksOnAny)
	OvaleCondition:RegisterCondition("debuffstacksonany", false, BuffStacksOnAny)
end

do
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

	local function BuffStealable(positionalParams, namedParams, state, atTime)
		local target = ParseCondition(positionalParams, namedParams, state)
		return state:GetAuraWithProperty(target, "stealable", "HELPFUL", atTime)
	end

	OvaleCondition:RegisterCondition("buffstealable", false, BuffStealable)
end

do
	--- Check if the player can cast the given spell (not on cooldown).
	-- @name CanCast
	-- @paramsig boolean
	-- @param id The spell ID to check.
	-- @return True if the spell cast be cast; otherwise, false.

	local function CanCast(positionalParams, namedParams, state, atTime)
		local spellId = positionalParams[1]
		local start, duration = state:GetSpellCooldown(spellId)
		return start + duration, INFINITY
	end

	OvaleCondition:RegisterCondition("cancast", true, CanCast)
end

do
	--- Get the cast time in seconds of the spell for the player, taking into account current haste effects.
	-- @name CastTime
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see ExecuteTime
	-- @usage
	-- if target.DebuffRemaining(flame_shock) < CastTime(lava_burst)
	--     Spell(lava_burst)

	local function CastTime(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local castTime = OvaleSpellBook:GetCastTime(spellId) or 0
		return Compare(castTime, comparator, limit)
	end

	--- Get the cast time in seconds of the spell for the player or the GCD for the player, whichever is greater.
	-- @name ExecuteTime
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see CastTime
	-- @usage
	-- if target.DebuffRemaining(flame_shock) < ExecuteTime(lava_burst)
	--     Spell(lava_burst)

	local function ExecuteTime(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local castTime = OvaleSpellBook:GetCastTime(spellId) or 0
		local gcd = state:GetGCD()
		local t = (castTime > gcd) and castTime or gcd
		return Compare(t, comparator, limit)
	end

	OvaleCondition:RegisterCondition("casttime", true, CastTime)
	OvaleCondition:RegisterCondition("executetime", true, ExecuteTime)
end

do
	--- Test if the target is casting the given spell.
	-- The spell may be specified either by spell ID, spell list name (as defined in SpellList),
	-- "harmful" for any harmful spell, or "helpful" for any helpful spell.
	-- @name Casting
	-- @paramsig boolean
	-- @param spell The spell to check.
	--     Valid values: spell ID, spell list name, harmful, helpful
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- Define(maloriak_release_aberrations 77569)
	-- if target.Casting(maloriak_release_aberrations)
	--     Spell(pummel)

	local function Casting(positionalParams, namedParams, state, atTime)
		local spellId = positionalParams[1]
		local target = ParseCondition(positionalParams, namedParams, state)

		-- Get the information about the current spellcast.
		local start, ending, castSpellId, castSpellName
		if target == "player" then
			start = state.startCast
			ending = state.endCast
			castSpellId = state.currentSpellId
			castSpellName = OvaleSpellBook:GetSpellName(castSpellId)
		else
			local spellName, _, _, _, startTime, endTime = API_UnitCastingInfo(target)
			if not spellName then
				spellName, _, _, _, startTime, endTime = API_UnitChannelInfo("unit")
			end
			if spellName then
				castSpellName = spellName
				start = startTime/1000
				ending = endTime/1000
			end
		end

		if castSpellId or castSpellName then
			if not spellId then
				-- No spell specified, so whatever spell is currently casting.
				return start, ending
			elseif OvaleData.buffSpellList[spellId] then
				for id in pairs(OvaleData.buffSpellList[spellId]) do
					if id == castSpellId or OvaleSpellBook:GetSpellName(id) == castSpellName then
						return start, ending
					end
				end
			elseif spellId == "harmful" and OvaleSpellBook:IsHarmfulSpell(spellId) then
				return start, ending
			elseif spellId == "helpful" and OvaleSpellBook:IsHelpfulSpell(spellId) then
				return start, ending
			elseif spellId == castSpellId then
				return start, ending
			elseif type(spellId) == "number" and OvaleSpellBook:GetSpellName(spellId) == castSpellName then
				return start, ending
			end
		end
		return nil
	end

	OvaleCondition:RegisterCondition("casting", false, Casting)
end

do
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

	local function CheckBoxOff(positionalParams, namedParams, state, atTime)
		for _, id in ipairs(positionalParams) do
			if Ovale:IsChecked(id) then
				return nil
			end
		end
		return 0, INFINITY
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

	local function CheckBoxOn(positionalParams, namedParams, state, atTime)
		for _, id in ipairs(positionalParams) do
			if not Ovale:IsChecked(id) then
				return nil
			end
		end
		return 0, INFINITY
	end

	OvaleCondition:RegisterCondition("checkboxoff", false, CheckBoxOff)
	OvaleCondition:RegisterCondition("checkboxon", false, CheckBoxOn)
end

do
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

	local function Class(positionalParams, namedParams, state, atTime)
		local class, yesno = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local _, classToken = API_UnitClass(target)
		local boolean = (classToken == class)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("class", false, Class)
end

do
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

	local function Classification(positionalParams, namedParams, state, atTime)
		local classification, yesno = positionalParams[1], positionalParams[2]
		local targetClassification
		local target = ParseCondition(positionalParams, namedParams, state)
		if API_UnitLevel(target) < 0 then
			targetClassification = "worldboss"
		else
			targetClassification = API_UnitClassification(target)
			if targetClassification == "rareelite" then
				targetClassification = "elite"
			elseif targetClassification == "rare" then
				targetClassification = "normal"
			end
		end
		local boolean = (targetClassification == classification)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("classification", false, Classification)
end

do
	--- Get the number of combo points for a feral druid or a rogue.
	-- @name ComboPoints
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of combo points.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if ComboPoints() >=1 Spell(savage_roar)

	local function ComboPoints(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local value = state.combo
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("combopoints", false, ComboPoints)
end

do
	--- Get the current value of a script counter.
	-- @name Counter
	-- @paramsig number or boolean
	-- @param id The name of the counter. It should match one that's defined by inccounter=xxx in SpellInfo(...).
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current value the counter.
	-- @return A boolean value for the result of the comparison.

	local function Counter(positionalParams, namedParams, state, atTime)
		local counter, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = state:GetCounterValue(counter)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("counter", false, Counter)
end

do
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

	local function CreatureFamily(positionalParams, namedParams, state, atTime)
		local name, yesno = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local family = API_UnitCreatureFamily(target)
		local lookupTable = LibBabbleCreatureType and LibBabbleCreatureType:GetLookupTable()
		local boolean = (lookupTable and family == lookupTable[name])
		return TestBoolean(boolean, yesno)	
	end

	OvaleCondition:RegisterCondition("creaturefamily", false, CreatureFamily)
end

do
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

	local function CreatureType(positionalParams, namedParams, state, atTime)
		local target = ParseCondition(positionalParams, namedParams, state)
		local creatureType = API_UnitCreatureType(target)
		local lookupTable = LibBabbleCreatureType and LibBabbleCreatureType:GetLookupTable()
		if lookupTable then
			for _, name in ipairs(positionalParams) do
				if creatureType == lookupTable[name] then
					return 0, INFINITY
				end
			end
		end
		return nil
	end

	OvaleCondition:RegisterCondition("creaturetype", false, CreatureType)
end

do
	--- Get the current estimated damage of a spell on the target if it is a critical strike.
	-- @name CritDamage
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The estimated critical strike damage of the given spell.
	-- @return A boolean value for the result of the comparison.
	-- @see Damage

	local AMPLIFICATION = 146051
	local INCREASED_CRIT_EFFECT_3_PERCENT = 44797

	local function CritDamage(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target = ParseCondition(positionalParams, namedParams, state, "target")
		local value = ComputeParameter(spellId, "damage", state, atTime) or 0
		-- Reduce by armor damage reduction for physical attacks.
		local si = OvaleData.spellInfo[spellId]
		if si and si.physical == 1 then
			value = value * (1 - BossArmorDamageReduction(target))
		end
		-- Default crit damage is two times normal damage.
		local critMultiplier = 2
		-- Add additional critical strike damage from MoP amplification trinkets.
		do
			local aura = state:GetAura("player", AMPLIFICATION, "HELPFUL")
			if state:IsActiveAura(aura, atTime) then
				critMultiplier = critMultiplier + aura.value1
			end
		end
		-- Multiply by increased crit effect from the meta gem.
		do
			local aura = state:GetAura("player", INCREASED_CRIT_EFFECT_3_PERCENT, "HELPFUL")
			if state:IsActiveAura(aura, atTime) then
				critMultiplier = critMultiplier * aura.value1
			end
		end
		value = critMultiplier * value
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("critdamage", false, CritDamage)

	--- Get the current estimated damage of a spell on the target.
	-- The script must provide a function to calculate the damage of the spell and assign it to the "damage" SpellInfo() parameter.
	-- @name Damage
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The estimated damage of the given spell on the target.
	-- @return A boolean value for the result of the comparison.
	-- @see CritDamage, LastDamage, LastEstimatedDamage
	-- @usage
	-- if {target.Damage(rake) / target.LastEstimateDamage(rake)} >1.1
	--     Spell(rake)

	local function Damage(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target = ParseCondition(positionalParams, namedParams, state, "target")
		local value = ComputeParameter(spellId, "damage", state, atTime) or 0
		-- Reduce by armor damage reduction for physical attacks.
		local si = OvaleData.spellInfo[spellId]
		if si and si.physical == 1 then
			value = value * (1 - BossArmorDamageReduction(target))
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("damage", false, Damage)
end

do
	--- Get the damage taken by the player in the previous time interval.
	-- @name DamageTaken
	-- @paramsig number or boolean
	-- @param interval The number of seconds before now.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param magic Optional. By default, all damage is counted. Set "magic=1" to count only magic damage.
	--     Defaults to magic=0.
	--     Valid values: 0, 1
	-- @param physical Optional. By default, all damage is counted. Set "physical=1" to count only physical damage.
	--     Defaults to physical=0.
	--     Valid values: 0, 1
	-- @return The amount of damage taken in the previous interval.
	-- @return A boolean value for the result of the comparison.
	-- @see IncomingDamage
	-- @usage
	-- if DamageTaken(5) > 50000 Spell(death_strike)
	-- if DamageTaken(5 magic=1) > 0 Spell(antimagic_shell)

	local function DamageTaken(positionalParams, namedParams, state, atTime)
		-- Damage taken shouldn't be smoothed since spike damage is important data.
		-- Just present damage taken as a constant value.
		local interval, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = 0
		if interval > 0 then
			local total, totalMagic = OvaleDamageTaken:GetRecentDamage(interval)
			if namedParams.magic == 1 then
				value = totalMagic
			elseif namedParams.physical == 1 then
				value = total - totalMagic
			else
				value = total
			end
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("damagetaken", false, DamageTaken)
	OvaleCondition:RegisterCondition("incomingdamage", false, DamageTaken)
end

do
	local function Demons(positionalParams, namedParams, state, atTime)
		local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = state:GetDemonsCount(creatureId, atTime)
		return Compare(value, comparator, limit) 
	end

	local function NotDeDemons(positionalParams, namedParams, state, atTime)
		local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = state:GetNotDemonicEmpoweredDemonsCount(creatureId, atTime)
		return Compare(value, comparator, limit) 
	end

	local function DemonDuration(positionalParams, namedParams, state, atTime)
		local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = state:GetRemainingDemonDuration(creatureId, atTime)
		return Compare(value, comparator, limit) 
	end

	OvaleCondition:RegisterCondition("demons", false, Demons)
	OvaleCondition:RegisterCondition("notdedemons", false, NotDeDemons)
	OvaleCondition:RegisterCondition("demonduration", false, DemonDuration)
end

do
	local NECROTIC_PLAGUE_TALENT = 19
	local NECROTIC_PLAGUE_DEBUFF = 155159
	local BLOOD_PLAGUE_DEBUFF = 55078
	local FROST_FEVER_DEBUFF = 55095

	local function GetDiseases(target, state)
		local npAura, bpAura, ffAura
		local talented = (OvaleSpellBook:GetTalentPoints(NECROTIC_PLAGUE_TALENT) > 0)
		if talented then
			npAura = state:GetAura(target, NECROTIC_PLAGUE_DEBUFF, "HARMFUL", true)
		else
			bpAura = state:GetAura(target, BLOOD_PLAGUE_DEBUFF, "HARMFUL", true)
			ffAura = state:GetAura(target, FROST_FEVER_DEBUFF, "HARMFUL", true)
		end
		return talented, npAura, bpAura, ffAura
	end

	--- Get the remaining time in seconds before any diseases applied by the death knight will expire.
	-- @name DiseasesRemaining
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.

	local function DiseasesRemaining(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local talented, npAura, bpAura, ffAura = GetDiseases(target, state)
		local aura
		if talented and state:IsActiveAura(npAura, atTime) then
			aura = npAura
		elseif not talented and state:IsActiveAura(bpAura, atTime) and state:IsActiveAura(ffAura, atTime) then
			aura = (bpAura.ending < ffAura.ending) and bpAura or ffAura
		end
		if aura then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			return TestValue(gain, INFINITY, 0, ending, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	--- Test if all diseases applied by the death knight are present on the target.
	-- @name DiseasesTicking
	-- @paramsig boolean
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.

	local function DiseasesTicking(positionalParams, namedParams, state, atTime)
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local talented, npAura, bpAura, ffAura = GetDiseases(target, state)
		local gain, start, ending
		if talented and npAura then
			gain, start, ending = npAura.gain, npAura.start, npAura.ending
		elseif not talented and bpAura and ffAura then
			-- Compute the intersection of the time spans for the two disease auras.
			gain = (bpAura.gain > ffAura.gain) and bpAura.gain or ffAura.gain
			start = (bpAura.start > ffAura.start) and bpAura.start or ffAura.start
			ending = (bpAura.ending < ffAura.ending) and bpAura.ending or ffAura.ending
		end
		if gain and ending and ending > gain then
			return gain, ending
		end
		return nil
	end

	--- Test if any diseases applied by the death knight are present on the target.
	-- @name DiseasesAnyTicking
	-- @paramsig boolean
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.

	local function DiseasesAnyTicking(positionalParams, namedParams, state, atTime)
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local talented, npAura, bpAura, ffAura = GetDiseases(target, state)
		local aura
		if talented and npAura then
			aura = npAura
		elseif not talented and (bpAura or ffAura) then
			aura = bpAura or ffAura
			if bpAura and ffAura then
				-- Find the disease that expires latest.
				aura = (bpAura.ending > ffAura.ending) and bpAura or ffAura
			end
		end
		if aura then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			if ending > gain then
				return gain, ending
			end
		end
		return nil
	end

	OvaleCondition:RegisterCondition("diseasesremaining", false, DiseasesRemaining)
	OvaleCondition:RegisterCondition("diseasesticking", false, DiseasesTicking)
	OvaleCondition:RegisterCondition("diseasesanyticking", false, DiseasesAnyTicking)
end

do
	--- Get the distance in yards to the target.
	-- The distances are from LibRangeCheck-2.0, which determines distance based on spell range checks, so results are approximate.
	-- You should not test for equality.
	-- @name Distance
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The distance to the target.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if target.Distance(less 25)
	--     Texture(ability_rogue_sprint)

	local function Distance(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local value = LibRangeCheck and LibRangeCheck:GetRange(target) or 0
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("distance", false, Distance)
end

do
	--- Get the current amount of Eclipse power for balance druids.
	-- A negative amount of power signifies being closer to Lunar Eclipse.
	-- A positive amount of power signifies being closer to Solar Eclipse.
	-- @name Eclipse
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of Eclipse power.
	-- @return A boolean value for the result of the comparison.
	-- @see EclipseDir
	-- @usage
	-- if Eclipse() < 0-70 and EclipseDir() <0 Spell(wrath)
	-- if Eclipse(less -70) and EclipseDir(less 0) Spell(wrath)

	local function Eclipse(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local value = state.eclipse
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("eclipse", false, Eclipse)
end

do
	--- Get the current direction of the Eclipse status on the Eclipse bar for balance druids.
	-- A negative number means heading toward Lunar Eclipse.
	-- A positive number means heading toward Solar Eclipse.
	-- Zero means it can head in either direction.
	-- @name EclipseDir
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current direction.
	-- @return A boolean value for the result of the comparison.
	-- @see Eclipse
	-- @usage
	-- if Eclipse() < 0-70 and EclipseDir() <0 Spell(wrath)
	-- if Eclipse(less -70) and EclipseDir(less 0) Spell(wrath)

	local function EclipseDir(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local value = state.eclipseDirection
		return Compare(value, comparator, limit)		
	end

	OvaleCondition:RegisterCondition("eclipsedir", false, EclipseDir)
end

do
	local function EclipseEnergy(positionalParams, namedParams, state, atTime)
		local seconds, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = 0
		Ovale:OneTimeMessage("Warning: 'EclipseEnergy()' is not implemented.")
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("eclipseenergy", false, EclipseEnergy)
end

do
	--- Get the number of hostile enemies on the battlefield.
	-- The minimum value returned is 1.
	-- @name Enemies
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param tagged Optional. By default, all enemies are counted. To count only enemies directly tagged by the player, set tagged=1.
	--     Defaults to tagged=0.
	--     Valid values: 0, 1.
	-- @return The number of enemies.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Enemies() >4 Spell(fan_of_knives)
	-- if Enemies(more 4) Spell(fan_of_knives)

	local function Enemies(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local value = state.enemies
		if not value then
			-- Use the profile's tagged enemies option as the default.
			local useTagged = Ovale.db.profile.apparence.taggedEnemies
			-- Override the default if "tagged" is explicitly given.
			if namedParams.tagged == 0 then
				useTagged = false
			elseif namedParams.tagged == 1 then
				useTagged = true
			end
			value = useTagged and state.taggedEnemies or state.activeEnemies
		end
		-- This works around problems with testing on target dummies, which are never hostile.
		if value < 1 then
			value = 1
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("enemies", false, Enemies)
end

do
	--- Get the amount of regenerated energy per second for feral druids, non-mistweaver monks, and rogues.
	-- @name EnergyRegenRate
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current rate of energy regeneration.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if EnergyRegenRage() >11 Spell(stance_of_the_sturdy_ox)

	local function EnergyRegenRate(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local value = state.powerRate.energy
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("energyregen", false, EnergyRegenRate)
	OvaleCondition:RegisterCondition("energyregenrate", false, EnergyRegenRate)
end

do
	--- Get the remaining time in seconds the target is Enraged.
	-- @name EnrageRemaining
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see IsEnraged
	-- @usage
	-- if EnrageRemaining() < 3 Spell(berserker_rage)

	local function EnrageRemaining(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local start, ending = state:GetAuraWithProperty(target, "enrage", "HELPFUL", atTime)
		if start and ending then
			return TestValue(start, INFINITY, 0, ending, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("enrageremaining", false, EnrageRemaining)
end

do
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

	local function Exists(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local target = ParseCondition(positionalParams, namedParams, state)
		local boolean = API_UnitExists(target)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("exists", false, Exists)
end

do
	--- A condition that always returns false.
	-- @name False
	-- @paramsig boolean
	-- @return A boolean value.

	local function False(positionalParams, namedParams, state, atTime)
		return nil
	end

	OvaleCondition:RegisterCondition("false", false, False)
end

do
	--- Get the amount of regenerated focus per second for hunters.
	-- @name FocusRegenRate
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current rate of focus regeneration.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if FocusRegenRate() >20 Spell(arcane_shot)
	-- if FocusRegenRate(more 20) Spell(arcane_shot)

	local function FocusRegenRate(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local value = state.powerRate.focus
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("focusregen", false, FocusRegenRate)
	OvaleCondition:RegisterCondition("focusregenrate", false, FocusRegenRate)
end

do
	--- Get the amount of focus that would be regenerated during the cast time of the given spell for hunters.
	-- @name FocusCastingRegen
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of focus.
	-- @return A boolean value for the result of the comparison.

	local STEADY_FOCUS = 177668

	local function FocusCastingRegen(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local regenRate = state.powerRate.focus
		local power = 0

		-- Get the "execute time" of the spell (larger of GCD or the cast time).
		local castTime = OvaleSpellBook:GetCastTime(spellId) or 0
		local gcd = state:GetGCD()
		local castSeconds = (castTime > gcd) and castTime or gcd
		power = power + regenRate * castSeconds

		-- Get the amount of time remaining on the Steady Focus buff.
		local aura = state:GetAura("player", STEADY_FOCUS, "HELPFUL", true)
		if aura then
			local seconds = aura.ending - state.currentTime
			if seconds <= 0 then
				seconds = 0
			elseif seconds > castSeconds then
				seconds = castSeconds
			end
			-- Steady Focus increases the focus regeneration rate by 50% for its duration.
			power = power + regenRate * 1.5 * seconds
		end
		return Compare(power, comparator, limit)
	end

	OvaleCondition:RegisterCondition("focuscastingregen", false, FocusCastingRegen)
end

do
	--- Get the player's global cooldown in seconds.
	-- @name GCD
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if GCD() <1.1 Spell(frostfire_bolt)
	-- if GCD(less 1.1) Spell(frostfire_bolt)

	local function GCD(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local value = state:GetGCD()
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("gcd", false, GCD)
end

do
	--- Get the number of seconds before the player's global cooldown expires.
	-- @name GCDRemaining
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target of the previous spell. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- unless SpellCooldown(seraphim) < GCDRemaining() Spell(judgment)

	local function GCDRemaining(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state, "target")
		if state.lastSpellId then
			local duration = state:GetGCD(state.lastSpellId, atTime, OvaleGUID:UnitGUID(target))
			local spellcast = OvaleFuture:LastInFlightSpell()
			local start = (spellcast and spellcast.start) or 0
			local ending = start + duration
			
			if atTime < ending then
				return TestValue(start, INFINITY, 0, ending, -1, comparator, limit)
			end
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("gcdremaining", false, GCDRemaining)
end

do
	--- Get the value of the named state variable from the simulator.
	-- @name GetState
	-- @paramsig number or boolean
	-- @param name The name of the state variable.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The value of the state variable.
	-- @return A boolean value for the result of the comparison.

	local function GetState(positionalParams, namedParams, state, atTime)
		local name, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = state:GetState(name)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("getstate", false, GetState)
end

do
	--- Get the duration in seconds that the simulator was most recently in the named state.
	-- @name GetStateDuration
	-- @paramsig number or boolean
	-- @param name The name of the state variable.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.

	local function GetStateDuration(positionalParams, namedParams, state, atTime)
		local name, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = state:GetStateDuration(name)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("getstateduration", false, GetStateDuration)
end

do
	--- Provided for backward compatibility, no use
	local function Glyph(positionalParams, namedParams, state, atTime)
		local stub, yesno = positionalParams[1], positionalParams[2]
		return TestBoolean(false, yesno)
	end

	OvaleCondition:RegisterCondition("glyph", false, Glyph)
end

do
	--- Test if the player has a particular item equipped.
	-- @name HasEquippedItem
	-- @paramsig boolean
	-- @param item Item to be checked whether it is equipped.
	-- @param yesno Optional. If yes, then return true if the item is equipped. If no, then return true if it isn't equipped.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param ilevel Optional.  Checks the item level of the equipped item.  If not specified, then any item level is valid.
	--     Defaults to not specified.
	--     Valid values: ilevel=N, where N is any number.
	-- @param slot Optional. Sets the inventory slot to check.  If not specified, then all slots are checked.
	--     Defaults to not specified.
	--     Valid values: slot=SLOTNAME, where SLOTNAME is a valid slot name, e.g., HandSlot.

	local function HasEquippedItem(positionalParams, namedParams, state, atTime)
		local itemId, yesno = positionalParams[1], positionalParams[2]
		local ilevel, slot = namedParams.ilevel, namedParams.slot
		local boolean = false
		local slotId
		if type(itemId) == "number" then
			slotId = OvaleEquipment:HasEquippedItem(itemId, slot)
			if slotId then
				if not ilevel or (ilevel and ilevel == OvaleEquipment:GetEquippedItemLevel(slotId)) then
					boolean = true
				end
			end
		elseif OvaleData.itemList[itemId] then
			for _, v in pairs(OvaleData.itemList[itemId]) do
				slotId = OvaleEquipment:HasEquippedItem(v, slot)
				if slotId then
					if not ilevel or (ilevel and ilevel == OvaleEquipment:GetEquippedItemLevel(slotId)) then
						boolean = true
						break
					end
				end
			end
		end
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("hasequippeditem", false, HasEquippedItem)
end

do
	--- Test if the player has full control, i.e., isn't feared, charmed, etc.
	-- @name HasFullControl
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the target exists. If no, then return true if it doesn't exist.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if HasFullControl(no) Spell(barkskin)

	local function HasFullControl(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local boolean = API_HasFullControl()
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("hasfullcontrol", false, HasFullControl)
end

do
	--- Test if the player has a shield equipped.
	-- @name HasShield
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if a shield is equipped. If no, then return true if it isn't equipped.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if HasShield() Spell(shield_wall)

	local function HasShield(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local boolean = OvaleEquipment:HasShield()
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("hasshield", false, HasShield)
end

do
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

	local function HasTrinket(positionalParams, namedParams, state, atTime)
		local trinketId, yesno = positionalParams[1], positionalParams[2]
		local boolean = false
		if type(trinketId) == "number" then
			boolean = OvaleEquipment:HasTrinket(trinketId)
		elseif OvaleData.itemList[trinketId] then
			for _, v in pairs(OvaleData.itemList[trinketId]) do
				boolean = OvaleEquipment:HasTrinket(v)
				if boolean then
					break
				end
			end
		end
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("hastrinket", false, HasTrinket)
end

do
	--- Test if the player has a weapon equipped.
	-- @name HasWeapon
	-- @paramsig boolean
	-- @param hand Sets which hand weapon.
	--     Valid values: main, off
	-- @param yesno Optional. If yes, then return true if the weapon is equipped. If no, then return true if it isn't equipped.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param type Optional. If set via type=value, then specify whether the weapon must be one-handed or two-handed.
	--     Default is unset.
	--     Valid values: one_handed, two_handed
	-- @return A boolean value.
	-- @usage
	-- if HasWeapon(offhand) and BuffStacks(killing_machine) Spell(frost_strike)

	local function HasWeapon(positionalParams, namedParams, state, atTime)
		local hand, yesno = positionalParams[1], positionalParams[2]
		local weaponType = namedParams.type
		local boolean = false
		if weaponType == "one_handed" then
			weaponType = 1
		elseif weaponType == "two_handed" then
			weaponType = 2
		end
		if hand == "offhand" or hand == "off" then
			boolean = OvaleEquipment:HasOffHandWeapon(weaponType)
		elseif hand == "mainhand" or hand == "main" then
			boolean = OvaleEquipment:HasMainHandWeapon(weaponType)
		end
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("hasweapon", false, HasWeapon)
end

do
	--- Get the current amount of health points of the target.
	-- @name Health
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
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

	local function Health(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local health = OvaleHealth:UnitHealth(target) or 0
		if health > 0 then
			local now = API_GetTime()
			local timeToDie = OvaleHealth:UnitTimeToDie(target)
			local value, origin, rate = health, now, -1 * health / timeToDie
			local start, ending = now, INFINITY
			return TestValue(start, ending, value, origin, rate, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("health", false, Health)
	OvaleCondition:RegisterCondition("life", false, Health)

	--- Get the number of health points away from full health of the target.
	-- @name HealthMissing
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
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

	local function HealthMissing(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local health = OvaleHealth:UnitHealth(target) or 0
		local maxHealth = OvaleHealth:UnitHealthMax(target) or 1
		if health > 0 then
			local now = API_GetTime()
			local missing = maxHealth - health
			local timeToDie = OvaleHealth:UnitTimeToDie(target)
			local value, origin, rate = missing, now, health / timeToDie
			local start, ending = now, INFINITY
			return TestValue(start, ending, value, origin, rate, comparator, limit)
		end
		return Compare(maxHealth, comparator, limit)
	end

	OvaleCondition:RegisterCondition("healthmissing", false, HealthMissing)
	OvaleCondition:RegisterCondition("lifemissing", false, HealthMissing)

	--- Get the current percent level of health of the target.
	-- @name HealthPercent
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
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

	local function HealthPercent(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local health = OvaleHealth:UnitHealth(target) or 0
		if health > 0 then
			local now = API_GetTime()
			local maxHealth = OvaleHealth:UnitHealthMax(target) or 1
			local healthPercent = health / maxHealth * 100
			local timeToDie = OvaleHealth:UnitTimeToDie(target)
			local value, origin, rate = healthPercent, now, -1 * healthPercent / timeToDie
			local start, ending = now, INFINITY
			return TestValue(start, ending, value, origin, rate, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("healthpercent", false, HealthPercent)
	OvaleCondition:RegisterCondition("lifepercent", false, HealthPercent)

	--- Get the current percent level of health of the target.
	-- @name HealthPercent
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
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

	local function TimeToHealthPercent(positionalParams, namedParams, state, atTime)
		local percent, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target = ParseCondition(positionalParams, namedParams, state)
		local now = API_GetTime()
		local health = OvaleHealth:UnitHealth(target) or 0
		local maxHealth = OvaleHealth:UnitHealthMax(target) or 1
		local healthPercent = health / maxHealth * 100
		local timeToDie = OvaleHealth:UnitTimeToDie(target)
		local timeToPercent = timeToDie / healthPercent * (healthPercent - percent)
		if timeToPercent < 0 then timeToPercent = 0 end
		local value, origin, rate = timeToPercent, now, -1
		local start, ending = now, now + timeToPercent
		return TestValue(start, ending, value, origin, rate, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timetohealthpercent", false, TimeToHealthPercent)

	--- Get the amount of health points of the target when it is at full health.
	-- @name MaxHealth
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum health.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if target.MaxHealth() >10000000 Item(mogu_power_potion)
	-- if target.MaxHealth(more 10000000) Item(mogu_power_potion)

	local function MaxHealth(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local value = OvaleHealth:UnitHealthMax(target)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("maxhealth", false, MaxHealth)

	--- Get the estimated number of seconds remaining before the target is dead.
	-- @name TimeToDie
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see DeadIn
	-- @usage
	-- if target.TimeToDie() <2 and ComboPoints() >0 Spell(eviscerate)

	local function TimeToDie(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local now = API_GetTime()
		local timeToDie = OvaleHealth:UnitTimeToDie(target)
		local value, origin, rate = timeToDie, now, -1
		local start, ending = now, now + timeToDie
		return TestValue(start, ending, value, origin, rate, comparator, limit)
	end

	OvaleCondition:RegisterCondition("deadin", false, TimeToDie)
	OvaleCondition:RegisterCondition("timetodie", false, TimeToDie)

	--- Get the estimated number of seconds remaining before the target reaches the given percent of max health.
	-- @name TimeToHealthPercent
	-- @paramsig number or boolean
	-- @param percent The percent of maximum health of the target.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see TimeToDie
	-- @usage
	-- if target.TimeToHealthPercent(25) <15 Item(virmens_bite_potion)

	local function TimeToHealthPercent(positionalParams, namedParams, state, atTime)
		local percent, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target = ParseCondition(positionalParams, namedParams, state)
		local health = OvaleHealth:UnitHealth(target) or 0
		if health > 0 then
			local maxHealth = OvaleHealth:UnitHealthMax(target) or 1
			local healthPercent = health / maxHealth * 100
			if healthPercent >= percent then
				local now = API_GetTime()
				local timeToDie = OvaleHealth:UnitTimeToDie(target)
				local t = timeToDie * (healthPercent - percent) / healthPercent
				local value, origin, rate = t, now, -1
				local start, ending = now, now + t
				return TestValue(start, ending, value, origin, rate, comparator, limit)
			end
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timetohealthpercent", false, TimeToHealthPercent)
	OvaleCondition:RegisterCondition("timetolifepercent", false, TimeToHealthPercent)
end

do
	--- Test if the player is in combat.
	-- @name InCombat
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the player is in combat. If no, then return true if the player isn't in combat.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if InCombat(no) and Stealthed(no) Spell(stealth)

	local function InCombat(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local boolean = state.inCombat
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("incombat", false, InCombat)
end

do
	--- Test if the given spell is in flight for spells that have a flight time after cast, e.g., Lava Burst.
	-- @name InFlightToTarget
	-- @paramsig boolean
	-- @param id The spell ID.
	-- @param yesno Optional. If yes, then return true if the spell is in flight. If no, then return true if it isn't in flight.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if target.DebuffRemaining(haunt) <3 and not InFlightToTarget(haunt)
	--     Spell(haunt)

	local function InFlightToTarget(positionalParams, namedParams, state, atTime)
		local spellId, yesno = positionalParams[1], positionalParams[2]
		local boolean = (state.currentSpellId == spellId) or OvaleFuture:InFlight(spellId)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("inflighttotarget", false, InFlightToTarget)
end

do
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

	local function InRange(positionalParams, namedParams, state, atTime)
		local spellId, yesno = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local boolean = (OvaleSpellBook:IsSpellInRange(spellId, target) == 1)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("inrange", false, InRange)
end

do
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

	local function IsAggroed(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local target = ParseCondition(positionalParams, namedParams, state)
		local boolean = API_UnitDetailedThreatSituation("player", target)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isaggroed", false, IsAggroed)
end

do
	--- Test if the target is dead.
	-- @name IsDead
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the target is dead. If no, then return true if it isn't dead.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if pet.IsDead() Spell(revive_pet)

	local function IsDead(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local target = ParseCondition(positionalParams, namedParams, state)
		local boolean = API_UnitIsDead(target)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isdead", false, IsDead)
end

do
	--- Test if the target is enraged.
	-- @name IsEnraged
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if enraged. If no, then return true if not enraged.
	--     Default is yes.
	--     Valid values: yes.  "no" currently doesn't work.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if target.IsEnraged() Spell(soothe)

	local function IsEnraged(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local target = ParseCondition(positionalParams, namedParams, state)
		return state:GetAuraWithProperty(target, "enrage", "HELPFUL", atTime)
	end

	OvaleCondition:RegisterCondition("isenraged", false, IsEnraged)
end

do
	--- Test if the player is feared.
	-- @name IsFeared
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if feared. If no, then return true if it not feared.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if IsFeared() Spell(every_man_for_himself)

	local function IsFeared(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local aura = state:GetAura("player", "fear_debuff", "HARMFUL")
		local boolean = not API_HasFullControl() and state:IsActiveAura(aura, atTime)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isfeared", false, IsFeared)
end

do
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

	local function IsFriend(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local target = ParseCondition(positionalParams, namedParams, state)
		local boolean = API_UnitIsFriend("player", target)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isfriend", false, IsFriend)
end

do
	--- Test if the player is incapacitated.
	-- @name IsIncapacitated
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if incapacitated. If no, then return true if it not incapacitated.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if IsIncapacitated() Spell(every_man_for_himself)

	local function IsIncapacitated(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local aura = state:GetAura("player", "incapacitate_debuff", "HARMFUL")
		local boolean = not API_HasFullControl() and state:IsActiveAura(aura, atTime)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isincapacitated", false, IsIncapacitated)
end

do
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

	local function IsInterruptible(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local target = ParseCondition(positionalParams, namedParams, state)
		local name, _, _, _, _, _, _, _, notInterruptible = API_UnitCastingInfo(target)
		if not name then
			name, _, _, _, _, _, _, notInterruptible = API_UnitChannelInfo(target)
		end
		local boolean = notInterruptible ~= nil and not notInterruptible
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isinterruptible", false, IsInterruptible)
end

do
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

	local function IsPVP(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local target = ParseCondition(positionalParams, namedParams, state)
		local boolean = API_UnitIsPVP(target)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("ispvp", false, IsPVP)
end

do
	--- Test if the player is rooted.
	-- @name IsRooted
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if rooted. If no, then return true if it not rooted.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if IsRooted() Item(Trinket0Slot usable=1)

	local function IsRooted(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local aura = state:GetAura("player", "root_debuff", "HARMFUL")
		local boolean = state:IsActiveAura(aura, atTime)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isrooted", false, IsRooted)
end

do
	--- Test if the player is stunned.
	-- @name IsStunned
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if stunned. If no, then return true if it not stunned.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if IsStunned() Item(Trinket0Slot usable=1)

	local function IsStunned(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local aura = state:GetAura("player", "stun_debuff", "HARMFUL")
		local boolean = not API_HasFullControl() and state:IsActiveAura(aura, atTime)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isstunned", false, IsStunned)
end

do
	--- Get the current number of charges of the given item in the player's inventory.
	-- @name ItemCharges
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of charges.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if ItemCount(mana_gem) ==0 or ItemCharges(mana_gem) <3
	--     Spell(conjure_mana_gem)
	-- if ItemCount(mana_gem equal 0) or ItemCharges(mana_gem less 3)
	--     Spell(conjure_mana_gem)

	local function ItemCharges(positionalParams, namedParams, state, atTime)
		local itemId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = API_GetItemCount(itemId, false, true)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("itemcharges", false, ItemCharges)
end

do
	--- Get the cooldown time in seconds of an item, e.g., trinket.
	-- @name ItemCooldown
	-- @paramsig number or boolean
	-- @param id The item ID or the equipped slot name.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if not ItemCooldown(ancient_petrified_seed) > 0
	--     Spell(berserk_cat)
	-- if not ItemCooldown(Trinket0Slot) > 0
	--     Spell(berserk_cat)

	local function ItemCooldown(positionalParams, namedParams, state, atTime)
		local itemId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		if itemId and type(itemId) ~= "number" then
			itemId = OvaleEquipment:GetEquippedItem(itemId)
		end
		if itemId then
			local start, duration = API_GetItemCooldown(itemId)
			if start > 0 and duration > 0 then
				return TestValue(start, start + duration, duration, start, -1, comparator, limit)
			end
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("itemcooldown", false, ItemCooldown)
end

do
	--- Get the current number of the given item in the player's inventory.
	-- Items with more than one charge count as one item.
	-- @name ItemCount
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The count of the item.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if ItemCount(mana_gem) ==0 Spell(conjure_mana_gem)
	-- if ItemCount(mana_gem equal 0) Spell(conjure_mana_gem)

	local function ItemCount(positionalParams, namedParams, state, atTime)
		local itemId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = API_GetItemCount(itemId)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("itemcount", false, ItemCount)
end

do
	--- Get the damage done by the most recent damage event for the given spell.
	-- If the spell is a periodic aura, then it gives the damage done by the most recent tick.
	-- @name LastDamage
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The damage done.
	-- @return A boolean value for the result of the comparison.
	-- @see Damage, LastEstimatedDamage
	-- @usage
	-- if LastDamage(ignite) >10000 Spell(combustion)
	-- if LastDamage(ignite more 10000) Spell(combustion)

	local function LastDamage(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = OvaleSpellDamage:Get(spellId)
		if value then
			return Compare(value, comparator, limit)
		end
		return nil
	end

	OvaleCondition:RegisterCondition("lastdamage", false, LastDamage)
	OvaleCondition:RegisterCondition("lastspelldamage", false, LastDamage)
end

do
	--- Get the level of the target.
	-- @name Level
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The level of the target.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Level() >=34 Spell(tiger_palm)
	-- if Level(more 33) Spell(tiger_palm)

	local function Level(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local value
		if target == "player" then
			value = state.level
		else
			value = API_UnitLevel(target)
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("level", false, Level)
end

do
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

	local function List(positionalParams, namedParams, state, atTime)
		local name, value = positionalParams[1], positionalParams[2]
		if name and Ovale:GetListValue(name) == value then
			return 0, INFINITY
		end
		return nil
	end

	OvaleCondition:RegisterCondition("list", false, List)
end

do
	--- Test whether the target's name matches the given name.
	-- @name Name
	-- @paramsig boolean
	-- @param name The localized target name.
	-- @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.

	local function Name(positionalParams, namedParams, state, atTime)
		local name, yesno = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		-- If the given name is a number, then look up the name of the corresponding spell.
		if type(name) == "number" then
			name = OvaleSpellBook:GetSpellName(name)
		end
		local targetName = API_UnitName(target)
		local boolean = (name == targetName)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("name", false, Name)
end

do
	--- Test if the game is on a PTR server
	-- @name PTR
	-- @paramsig number
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return 1 if it is a PTR realm, or 0 if it is a live realm.
	-- @usage
	-- if PTR() > 0 Spell(wacky_new_spell)

	local function PTR(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local _, _, _, uiVersion = API_GetBuildInfo()
		local value = (uiVersion > 70100) and 1 or 0
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("ptr", false, PTR)
end

do
	--- Get the persistent multiplier to the given aura if applied.
	-- The persistent multiplier is snapshotted to the aura for its duration.
	-- @name PersistentMultiplier
	-- @paramsig number or boolean
	-- @param id The aura ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The persistent multiplier.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff)
	--     Spell(rake)

	local function PersistentMultiplier(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target = ParseCondition(positionalParams, namedParams, state, "target")
		local value = state:GetDamageMultiplier(spellId, OvaleGUID:UnitGUID(target), atTime)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("persistentmultiplier", false, PersistentMultiplier)
end

do
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
	-- if PetPresent(name=Niuzao) 
	--     Spell(provoke_pet)


	local function PetPresent(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local name = namedParams.name
		local target = "pet"
		local boolean = API_UnitExists(target) and not API_UnitIsDead(target) and (name == nil or name == API_UnitName(target))
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("petpresent", false, PetPresent)
end

do
	-- Return the maximum power of the given power type on the target.
	local function MaxPower(powerType, positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
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
	local function Power(powerType, positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		if target == "player" then
			local value, origin, rate = state[powerType], state.currentTime, state.powerRate[powerType]
			local start, ending = state.currentTime, INFINITY
			return TestValue(start, ending, value, origin, rate, comparator, limit)
		else
			local powerInfo = OvalePower.POWER_INFO[powerType]
			local value = API_UnitPower(target, powerInfo.id)
			return Compare(value, comparator, limit)
		end
	end

	--- Return the current deficit of power from max power on the target.
	local function PowerDeficit(powerType, positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		if target == "player" then
			local powerMax = OvalePower.maxPower[powerType] or 0
			if powerMax > 0 then
				local value, origin, rate = powerMax - state[powerType], state.currentTime, -1 * state.powerRate[powerType]
				local start, ending = state.currentTime, INFINITY
				return TestValue(start, ending, value, origin, rate, comparator, limit)
			end
		else
			local powerInfo = OvalePower.POWER_INFO[powerType]
			local powerMax = API_UnitPowerMax(target, powerInfo.id, powerInfo.segments) or 0
			if powerMax > 0 then
				local power = API_UnitPower(target, powerInfo.id)
				local value = powerMax - power
				return Compare(value, comparator, limit)
			end
		end
		return Compare(0, comparator, limit)
	end

	--- Return the current percent level of power (between 0 and 100) on the target.
	local function PowerPercent(powerType, positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		if target == "player" then
			local powerMax = OvalePower.maxPower[powerType] or 0
			if powerMax > 0 then
				local conversion = 100 / powerMax
				local value, origin, rate = state[powerType] * conversion, state.currentTime, state.powerRate[powerType] * conversion
				if rate > 0 and value >= 100 or rate < 0 and value == 0 then
					-- Cap the values at 0 or 100 depending on whether the power is increasing or decreasing.
					rate = 0
				end
				local start, ending = state.currentTime, INFINITY
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

	--- Get the current amount of the player's primary resource for the given spell.
	-- @name PrimaryResource
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of the primary resource.
	-- @return A boolean value for the result of the comparison.

	local function PrimaryResource(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local primaryPowerType
		local si = OvaleData:GetSpellInfo(spellId)
		if si then
			-- Check the spell information to see if a primary resource cost was given.
			for powerType in pairs(OvalePower.PRIMARY_POWER) do
				if si[powerType] then
					primaryPowerType = powerType
					break
				end
			end
		end
		-- If no primary resource cost was found, then query using Blizzard API.
		if not primaryPowerType then
			local _, powerType = OvalePower:GetSpellCost(spellId)
			if powerType then
				primaryPowerType = powerType
			end
		end
		if primaryPowerType then
			local value, origin, rate = state[primaryPowerType], state.currentTime, state.powerRate[primaryPowerType]
			local start, ending = state.currentTime, INFINITY
			return TestValue(start, ending, value, origin, rate, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("primaryresource", true, PrimaryResource)

	--- Get the current amount of alternate power displayed on the alternate power bar.
	-- @name AlternatePower
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current alternate power.
	-- @return A boolean value for the result of the comparison.

	local function AlternatePower(positionalParams, namedParams, state, atTime)
		return Power("alternate", positionalParams, namedParams, state, atTime)
	end

	--- Get the current amount of astral power for balance druids.
	-- @name AstraPower
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current runic power.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if AstraPower() >70 Spell(frost_strike)
	-- if AstraPower(more 70) Spell(frost_strike)

	local function AstralPower(positionalParams, namedParams, state, atTime)
		return Power("astralpower", positionalParams, namedParams, state, atTime)
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

	local function Chi(positionalParams, namedParams, state, atTime)
		return Power("chi", positionalParams, namedParams, state, atTime)
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

	local function Energy(positionalParams, namedParams, state, atTime)
		return Power("energy", positionalParams, namedParams, state, atTime)
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

	local function Focus(positionalParams, namedParams, state, atTime)
		return Power("focus", positionalParams, namedParams, state, atTime)
	end
	
	local function Fury(positionalParams, namedParams, state, atTime)
		return Power("fury", positionalParams, namedParams, state, atTime)
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

	local function HolyPower(positionalParams, namedParams, state, atTime)
		return Power("holy", positionalParams, namedParams, state, atTime)
	end

	local function Insanity(positionalParams, namedParams, state, atTime)
		return Power("insanity", positionalParams, namedParams, state, atTime)
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
	local function Mana(positionalParams, namedParams, state, atTime)
		return Power("mana", positionalParams, namedParams, state, atTime)
	end

	local function Maelstrom(positionalParams, namedParams, state, atTime)
		return Power("maelstrom", positionalParams, namedParams, state, atTime)
	end
	
	local function Pain(positionalParams, namedParams, state, atTime)
		return Power("pain", positionalParams, namedParams, state, atTime)
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

	local function Rage(positionalParams, namedParams, state, atTime)
		return Power("rage", positionalParams, namedParams, state, atTime)
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

	local function RunicPower(positionalParams, namedParams, state, atTime)
		return Power("runicpower", positionalParams, namedParams, state, atTime)
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

	local function ShadowOrbs(positionalParams, namedParams, state, atTime)
		return Power("shadoworbs", positionalParams, namedParams, state, atTime)
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

	local function SoulShards(positionalParams, namedParams, state, atTime)
		return Power("soulshards", positionalParams, namedParams, state, atTime)
	end

	local function ArcaneCharges(positionalParams, namedParams, state, atTime)
		return Power("arcanecharges", positionalParams, namedParams, state, atTime)
	end

	OvaleCondition:RegisterCondition("alternatepower", false, AlternatePower)
	OvaleCondition:RegisterCondition("arcanecharges", false, ArcaneCharges)
	OvaleCondition:RegisterCondition("astralpower", false, AstralPower)
	OvaleCondition:RegisterCondition("chi", false, Chi)
	OvaleCondition:RegisterCondition("energy", false, Energy)
	OvaleCondition:RegisterCondition("focus", false, Focus)
	OvaleCondition:RegisterCondition("fury", false, Fury)
	OvaleCondition:RegisterCondition("holypower", false, HolyPower)
	OvaleCondition:RegisterCondition("insanity", false, Insanity)
	OvaleCondition:RegisterCondition("maelstrom", false, Maelstrom)
	OvaleCondition:RegisterCondition("mana", false, Mana)
	OvaleCondition:RegisterCondition("pain", false, Pain)
	OvaleCondition:RegisterCondition("rage", false, Rage)
	OvaleCondition:RegisterCondition("runicpower", false, RunicPower)
	OvaleCondition:RegisterCondition("shadoworbs", false, ShadowOrbs)
	OvaleCondition:RegisterCondition("soulshards", false, SoulShards)

	--- Get the number of lacking resource points for a full alternate power bar, between 0 and maximum alternate power, of the target.
	-- @name AlternatePowerDeficit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current alternate power deficit.
	-- @return A boolean value for the result of the comparison.

	local function AlternatePowerDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("alternatepower", positionalParams, namedParams, state, atTime)
	end

	--- Get the number of lacking resource points for a full runic power bar, between 0 and maximum runic power, of the target.
	-- @name AstralPowerDeficit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current runic power deficit.
	-- @return A boolean value for the result of the comparison.

	local function AstralPowerDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("astralpower", positionalParams, namedParams, state, atTime)
	end

	--- Get the number of lacking resource points for full chi, between 0 and maximum chi, of the target.
	-- @name ChiDeficit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current chi deficit.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if ChiDeficit() >=2 Spell(keg_smash)
	-- if ChiDeficit(more 1) Spell(keg_smash)

	local function ChiDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("chi", positionalParams, namedParams, state, atTime)
	end

	local function ComboPointsDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("combopoints", positionalParams, namedParams, state, atTime)
	end

	--- Get the number of lacking resource points for a full energy bar, between 0 and maximum energy, of the target.
	-- @name EnergyDeficit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current energy deficit.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if EnergyDeficit() >60 Spell(tigers_fury)
	-- if EnergyDeficit(more 60) Spell(tigers_fury)

	local function EnergyDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("energy", positionalParams, namedParams, state, atTime)
	end

	--- Get the number of lacking resource points for a full focus bar, between 0 and maximum focus, of the target.
	-- @name FocusDeficit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current focus deficit.
	-- @return A boolean value for the result of the comparison.

	local function FocusDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("focus", positionalParams, namedParams, state, atTime)
	end
	
	local function FuryDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("fury", positionalParams, namedParams, state, atTime)
	end

	--- Get the number of lacking resource points for full holy power, between 0 and maximum holy power, of the target.
	-- @name HolyPowerDeficit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current holy power deficit.
	-- @return A boolean value for the result of the comparison.

	local function HolyPowerDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("holypower", positionalParams, namedParams, state, atTime)
	end

	--- Get the number of lacking resource points for a full mana bar, between 0 and maximum mana, of the target.
	-- @name ManaDeficit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current mana deficit.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if ManaDeficit() >30000 Item(mana_gem)
	-- if ManaDeficit(more 30000) Item(mana_gem)

	local function ManaDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("mana", positionalParams, namedParams, state, atTime)
	end

	local function PainDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("pain", positionalParams, namedParams, state, atTime)
	end

	--- Get the number of lacking resource points for a full rage bar, between 0 and maximum rage, of the target.
	-- @name RageDeficit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current rage deficit.
	-- @return A boolean value for the result of the comparison.

	local function RageDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("rage", positionalParams, namedParams, state, atTime)
	end

	--- Get the number of lacking resource points for a full runic power bar, between 0 and maximum runic power, of the target.
	-- @name RunicPowerDeficit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current runic power deficit.
	-- @return A boolean value for the result of the comparison.

	local function RunicPowerDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("runicpower", positionalParams, namedParams, state, atTime)
	end

	--- Get the number of lacking resource points for full shadow orbs, between 0 and maximum shadow orbs, of the target.
	-- @name ShadowOrbsDeficit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current shadow orbs deficit.
	-- @return A boolean value for the result of the comparison.

	local function ShadowOrbsDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("shadoworbs", positionalParams, namedParams, state, atTime)
	end

	--- Get the number of lacking resource points for full soul shards, between 0 and maximum soul shards, of the target.
	-- @name SoulShardsDeficit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current soul shards deficit.
	-- @return A boolean value for the result of the comparison.

	local function SoulShardsDeficit(positionalParams, namedParams, state, atTime)
		return PowerDeficit("soulshards", positionalParams, namedParams, state, atTime)
	end

	OvaleCondition:RegisterCondition("alternatepowerdeficit", false, AlternatePowerDeficit)
	OvaleCondition:RegisterCondition("astralpowerdeficit", false, AstralPowerDeficit)
	OvaleCondition:RegisterCondition("chideficit", false, ChiDeficit)
	OvaleCondition:RegisterCondition("combopointsdeficit", false, ComboPointsDeficit)
	OvaleCondition:RegisterCondition("energydeficit", false, EnergyDeficit)
	OvaleCondition:RegisterCondition("focusdeficit", false, FocusDeficit)
	OvaleCondition:RegisterCondition("furydeficit", false, FuryDeficit)
	OvaleCondition:RegisterCondition("holypowerdeficit", false, HolyPowerDeficit)
	OvaleCondition:RegisterCondition("manadeficit", false, ManaDeficit)
	OvaleCondition:RegisterCondition("paindeficit", false, PainDeficit)
	OvaleCondition:RegisterCondition("ragedeficit", false, RageDeficit)
	OvaleCondition:RegisterCondition("runicpowerdeficit", false, RunicPowerDeficit)
	OvaleCondition:RegisterCondition("shadoworbsdeficit", false, ShadowOrbsDeficit)
	OvaleCondition:RegisterCondition("soulshardsdeficit", false, SoulShardsDeficit)

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

	local function ManaPercent(positionalParams, namedParams, state, atTime)
		return PowerPercent("mana", positionalParams, namedParams, state, atTime)
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

	local function MaxAlternatePower(positionalParams, namedParams, state, atTime)
		return MaxPower("alternate", positionalParams, namedParams, state, atTime)
	end

	local function MaxChi(positionalParams, namedParams, state, atTime)
		return MaxPower("chi", positionalParams, namedParams, state, atTime)
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

	local function MaxComboPoints(positionalParams, namedParams, state, atTime)
		return MaxPower("combopoints", positionalParams, namedParams, state, atTime)
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

	local function MaxEnergy(positionalParams, namedParams, state, atTime)
		return MaxPower("energy", positionalParams, namedParams, state, atTime)
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

	local function MaxFocus(positionalParams, namedParams, state, atTime)
		return MaxPower("focus", positionalParams, namedParams, state, atTime)
	end
	
	local function MaxFury(positionalParams, namedParams, state, atTime)
		return MaxPower("fury", positionalParams, namedParams, state, atTime)
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

	local function MaxHolyPower(positionalParams, namedParams, state, atTime)
		return MaxPower("holy", positionalParams, namedParams, state, atTime)
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

	local function MaxMana(positionalParams, namedParams, state, atTime)
		return MaxPower("mana", positionalParams, namedParams, state, atTime)
	end
	
	local function MaxPain(positionalParams, namedParams, state, atTime)
		return MaxPower("pain", positionalParams, namedParams, state, atTime)
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

	local function MaxRage(positionalParams, namedParams, state, atTime)
		return MaxPower("rage", positionalParams, namedParams, state, atTime)
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

	local function MaxRunicPower(positionalParams, namedParams, state, atTime)
		return MaxPower("runicpower", positionalParams, namedParams, state, atTime)
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

	local function MaxShadowOrbs(positionalParams, namedParams, state, atTime)
		return MaxPower("shadoworbs", positionalParams, namedParams, state, atTime)
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

	local function MaxSoulShards(positionalParams, namedParams, state, atTime)
		return MaxPower("soulshards", positionalParams, namedParams, state, atTime)
	end

	OvaleCondition:RegisterCondition("maxalternatepower", false, MaxAlternatePower)
	OvaleCondition:RegisterCondition("maxchi", false, MaxChi)
	OvaleCondition:RegisterCondition("maxcombopoints", false, MaxComboPoints)
	OvaleCondition:RegisterCondition("maxenergy", false, MaxEnergy)
	OvaleCondition:RegisterCondition("maxfocus", false, MaxFocus)
	OvaleCondition:RegisterCondition("maxfury", false, MaxFury)
	OvaleCondition:RegisterCondition("maxholypower", false, MaxHolyPower)
	OvaleCondition:RegisterCondition("maxmana", false, MaxMana)
	OvaleCondition:RegisterCondition("maxpain", false, MaxPain)
	OvaleCondition:RegisterCondition("maxrage", false, MaxRage)
	OvaleCondition:RegisterCondition("maxrunicpower", false, MaxRunicPower)
	OvaleCondition:RegisterCondition("maxshadoworbs", false, MaxShadowOrbs)
	OvaleCondition:RegisterCondition("maxsoulshards", false, MaxSoulShards)
end

do
	-- Return the amount of power of the given power type required to cast the given spell.
	local function PowerCost(powerType, positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target = ParseCondition(positionalParams, namedParams, state, "target")
		local maxCost = (namedParams.max == 1)
		local value = state:PowerCost(spellId, powerType, atTime, target, maxCost) or 0
		return Compare(value, comparator, limit)
	end

	--- Get the amount of energy required to cast the given spell.
	-- This returns zero for spells that use either mana or another resource based on stance/specialization, e.g., Monk's Jab.
	-- @name EnergyCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param max Optional. Set max=1 to return the maximum energy cost for the spell.
	--     Defaults to max=0.
	--     Valid values: 0, 1
	-- @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The amount of energy.
	-- @return A boolean value for the result of the comparison.

	local function EnergyCost(positionalParams, namedParams, state, atTime)
		return PowerCost("energy", positionalParams, namedParams, state, atTime)
	end

	--- Get the amount of focus required to cast the given spell.
	-- @name FocusCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param max Optional. Set max=1 to return the maximum focus cost for the spell.
	--     Defaults to max=0.
	--     Valid values: 0, 1
	-- @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The amount of focus.
	-- @return A boolean value for the result of the comparison.

	local function FocusCost(positionalParams, namedParams, state, atTime)
		return PowerCost("focus", positionalParams, namedParams, state, atTime)
	end
	
	--- Get the amount of mana required to cast the given spell.
	-- This returns zero for spells that use either mana or another resource based on stance/specialization, e.g., Monk's Jab.
	-- @name ManaCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param max Optional. Set max=1 to return the maximum mana cost for the spell.
	--     Defaults to max=0.
	--     Valid values: 0, 1
	-- @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The amount of mana.
	-- @return A boolean value for the result of the comparison.

	local function ManaCost(positionalParams, namedParams, state, atTime)
		return PowerCost("mana", positionalParams, namedParams, state, atTime)
	end

	--- Get the amount of rage required to cast the given spell.
	-- @name RageCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param max Optional. Set max=1 to return the maximum rage cost for the spell.
	--     Defaults to max=0.
	--     Valid values: 0, 1
	-- @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The amount of rage.
	-- @return A boolean value for the result of the comparison.

	local function RageCost(positionalParams, namedParams, state, atTime)
		return PowerCost("rage", positionalParams, namedParams, state, atTime)
	end

	--- Get the amount of runic power required to cast the given spell.
	-- @name RunicPowerCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param max Optional. Set max=1 to return the maximum runic power cost for the spell.
	--     Defaults to max=0.
	--     Valid values: 0, 1
	-- @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The amount of runic power.
	-- @return A boolean value for the result of the comparison.

	local function RunicPowerCost(positionalParams, namedParams, state, atTime)
		return PowerCost("runicpower", positionalParams, namedParams, state, atTime)
	end

	local function AstralPowerCost(positionalParams, namedParams, state, atTime)
		return PowerCost("astralpower", positionalParams, namedParams, state, atTime)
	end

	local function MainPowerCost(positionalParams, namedParams, state, atTime)
		return PowerCost(OvalePower.powerType, positionalParams, namedParams, state, atTime)
	end

	OvaleCondition:RegisterCondition("powercost", true, MainPowerCost)
	OvaleCondition:RegisterCondition("astralpowercost", true, AstralPowerCost)
	OvaleCondition:RegisterCondition("energycost", true, EnergyCost)
	OvaleCondition:RegisterCondition("focuscost", true, FocusCost)
	OvaleCondition:RegisterCondition("manacost", true, ManaCost)
	OvaleCondition:RegisterCondition("ragecost", true, RageCost)
	OvaleCondition:RegisterCondition("runicpowercost", true, RunicPowerCost)
end

do
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

	local function Present(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local target = ParseCondition(positionalParams, namedParams, state)
		local boolean = API_UnitExists(target) and not API_UnitIsDead(target)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("present", false, Present)
end

do
	--- Test if the previous spell cast that invoked the GCD matches the given spell.
	-- @name PreviousGCDSpell
	-- @paramsig boolean
	-- @param id The spell ID.
	-- @param yesno Optional. If yes, then return true if there is a match. If no, then return true if it doesn't match.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.

	local function PreviousGCDSpell(positionalParams, namedParams, state, atTime)
		local spellId, yesno = positionalParams[1], positionalParams[2]
		local count = namedParams.count
		local boolean
		if count and count > 1 then
			boolean = (spellId == state.lastGCDSpellIds[#state.lastGCDSpellIds - count + 2])
		else
			boolean = (spellId == state.lastGCDSpellId)
		end
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("previousgcdspell", true, PreviousGCDSpell)
end

do
	--- Test if the previous spell cast that did not trigger the GCD matches the given spell.
	-- @name PreviousOffGCDSpell
	-- @paramsig boolean
	-- @param id The spell ID.
	-- @param yesno Optional. If yes, then return true if there is a match. If no, then return true if it doesn't match.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.

	local function PreviousOffGCDSpell(positionalParams, namedParams, state, atTime)
		local spellId, yesno = positionalParams[1], positionalParams[2]
		local boolean = (spellId == state.lastOffGCDSpellId)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("previousoffgcdspell", true, PreviousOffGCDSpell)
end

do
	--- Test if the previous spell cast matches the given spell.
	-- @name PreviousSpell
	-- @paramsig boolean
	-- @param id The spell ID.
	-- @param yesno Optional. If yes, then return true if there is a match. If no, then return true if it doesn't match.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.

	local function PreviousSpell(positionalParams, namedParams, state, atTime)
		local spellId, yesno = positionalParams[1], positionalParams[2]
		local boolean = (spellId == state.lastSpellId)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("previousspell", true, PreviousSpell)
end

do
	--- Get the result of the target's level minus the player's level. This number may be negative.
	-- @name RelativeLevel
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
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

	local function RelativeLevel(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local value, level
		if target == "player" then
			level = state.level
		else
			level = API_UnitLevel(target)
		end
		if level < 0 then
			-- World boss, so treat it as three levels higher.
			value = 3
		else
			value = level - state.level
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("relativelevel", false, RelativeLevel)
end

do
	local function Refreshable(positionalParams, namedParams, state, atTime)
		local auraId = positionalParams[1]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local tickTime
			if state:IsActiveAura(aura, atTime) then
				tickTime = aura.tick
			end
			if not tickTime then
				tickTime = OvaleData:GetTickLength(auraId, state)
			end

			local gain, start, ending = aura.gain, aura.start, aura.ending
			if ending - tickTime <= gain then
				return gain, INFINITY
			else
				return ending - tickTime, INFINITY
			end
		end
		return 0, INFINITY
	end

	OvaleCondition:RegisterCondition("refreshable", false, Refreshable)
	OvaleCondition:RegisterCondition("debuffrefreshable", false, Refreshable)
	OvaleCondition:RegisterCondition("buffrefreshable", false, Refreshable)
end

do
	--- Get the remaining cast time in seconds of the target's current spell cast.
	-- @name RemainingCastTime
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see CastTime
	-- @usage
	-- if target.Casting(hour_of_twilight) and target.RemainingCastTime() <2
	--     Spell(cloak_of_shadows)

	local function RemainingCastTime(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local _, _, _, _, startTime, endTime = API_UnitCastingInfo(target)
		if startTime and endTime then
			startTime = startTime / 1000
			endTime = endTime / 1000
			return TestValue(startTime, endTime, 0, endTime, -1, comparator, limit)
		end
		return nil
	end

	OvaleCondition:RegisterCondition("remainingcasttime", false, RemainingCastTime)
end

do
	--- Get the current number of active and regenerating (fractional) runes of the given type for death knights.
	-- @name Rune
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of runes.
	-- @return A boolean value for the result of the comparison.
	-- @see RuneCount
	-- @usage
	-- if Rune() > 1 Spell(blood_tap)

	local function Rune(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		
		local count, startCooldown, endCooldown = state:RuneCount(atTime)
		if startCooldown < INFINITY then
			local origin = startCooldown
			local rate = 1 / (endCooldown - startCooldown)
			local start, ending = startCooldown, INFINITY
			return TestValue(start, ending, count, origin, rate, comparator, limit)
		end
		return Compare(count, comparator, limit)
	end

	--- Get the current number of active runes of the given type for death knights.
	-- @name RuneCount
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param death Optional. Set death=1 to include all active death runes in the count. Set death=0 to exclude all death runes.
	--     Defaults to unset.
	--     Valid values: unset, 0, 1
	-- @return The number of runes.
	-- @return A boolean value for the result of the comparison.
	-- @see Rune
	-- @usage
	-- if RuneCount() ==2
	--     Spell(obliterate)

	local function RuneCount(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local count, startCooldown, endCooldown = state:RuneCount(atTime)
		if startCooldown < INFINITY then
			local start, ending = startCooldown, endCooldown
			return TestValue(start, ending, count, start, 0, comparator, limit)
		end
		return Compare(count, comparator, limit)
	end

	OvaleCondition:RegisterCondition("rune", false, Rune)
	OvaleCondition:RegisterCondition("runecount", false, RuneCount)
end

do
	-- Returns the value of the given snapshot stat.
	local function Snapshot(statName, defaultValue, positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local value = state[statName] or defaultValue
		return Compare(value, comparator, limit)
	end

	-- Returns the critical strike chance of the given snapshot stat.
	local function SnapshotCritChance(statName, defaultValue, positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local value = state[statName] or defaultValue
		if namedParams.unlimited ~= 1 and value > 100 then
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

	local function Agility(positionalParams, namedParams, state, atTime)
		return Snapshot("agility", 0, positionalParams, namedParams, state, atTime)
	end

	--- Get the current attack power of the player.
	-- @name AttackPower
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current attack power.
	-- @return A boolean value for the result of the comparison.

	local function AttackPower(positionalParams, namedParams, state, atTime)
		return Snapshot("attackPower", 0, positionalParams, namedParams, state, atTime)
	end

	--- Get the current critical strike rating of the player.
	-- @name CritRating
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current critical strike rating.
	-- @return A boolean value for the result of the comparison.

	local function CritRating(positionalParams, namedParams, state, atTime)
		return Snapshot("critRating", 0, positionalParams, namedParams, state, atTime)
	end

	--- Get the current haste rating of the player.
	-- @name HasteRating
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current haste rating.
	-- @return A boolean value for the result of the comparison.

	local function HasteRating(positionalParams, namedParams, state, atTime)
		return Snapshot("hasteRating", 0, positionalParams, namedParams, state, atTime)
	end

	--- Get the current intellect of the player.
	-- @name Intellect
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current intellect.
	-- @return A boolean value for the result of the comparison.

	local function Intellect(positionalParams, namedParams, state, atTime)
		return Snapshot("intellect", 0, positionalParams, namedParams, state, atTime)
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

	local function MasteryEffect(positionalParams, namedParams, state, atTime)
		return Snapshot("masteryEffect", 0, positionalParams, namedParams, state, atTime)
	end

	--- Get the current mastery rating of the player.
	-- @name MasteryRating
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current mastery rating.
	-- @return A boolean value for the result of the comparison.

	local function MasteryRating(positionalParams, namedParams, state, atTime)
		return Snapshot("masteryRating", 0, positionalParams, namedParams, state, atTime)
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

	local function MeleeCritChance(positionalParams, namedParams, state, atTime)
		return SnapshotCritChance("meleeCrit", 0, positionalParams, namedParams, state, atTime)
	end
	
	--- Get the current percent increase to melee haste of the player.
	-- @name MeleeHaste
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current percent increase to melee haste.
	-- @return A boolean value for the result of the comparison.

	local function MeleeHaste(positionalParams, namedParams, state, atTime)
		return Snapshot("meleeHaste", 0, positionalParams, namedParams, state, atTime)
	end

	--- Get the current multistrike chance of the player.
	-- @name MultistrikeChance
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current multistrike chance (in percent).
	-- @return A boolean value for the result of the comparison.

	local function MultistrikeChance(positionalParams, namedParams, state, atTime)
		return Snapshot("multistrike", 0, positionalParams, namedParams, state, atTime)
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

	local function RangedCritChance(positionalParams, namedParams, state, atTime)
		return SnapshotCritChance("rangedCrit", 0, positionalParams, namedParams, state, atTime)
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

	local function SpellCritChance(positionalParams, namedParams, state, atTime)
		return SnapshotCritChance("spellCrit", 0, positionalParams, namedParams, state, atTime)
	end

	--- Get the current percent increase to spell haste of the player.
	-- @name SpellHaste
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current percent increase to spell haste.
	-- @return A boolean value for the result of the comparison.

	local function SpellHaste(positionalParams, namedParams, state, atTime)
		return Snapshot("spellHaste", 0, positionalParams, namedParams, state, atTime)
	end

	--- Get the current spellpower of the player.
	-- @name Spellpower
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current spellpower.
	-- @return A boolean value for the result of the comparison.

	local function Spellpower(positionalParams, namedParams, state, atTime)
		return Snapshot("spellBonusDamage", 0, positionalParams, namedParams, state, atTime)
	end

	--- Get the current spirit of the player.
	-- @name Spirit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current spirit.
	-- @return A boolean value for the result of the comparison.

	local function Spirit(positionalParams, namedParams, state, atTime)
		return Snapshot("spirit", 0, positionalParams, namedParams, state, atTime)
	end

	--- Get the current stamina of the player.
	-- @name Stamina
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current stamina.
	-- @return A boolean value for the result of the comparison.

	local function Stamina(positionalParams, namedParams, state, atTime)
		return Snapshot("stamina", 0, positionalParams, namedParams, state, atTime)
	end

	--- Get the current strength of the player.
	-- @name Strength
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current strength.
	-- @return A boolean value for the result of the comparison.

	local function Strength(positionalParams, namedParams, state, atTime)
		return Snapshot("strength", 0, positionalParams, namedParams, state, atTime)
	end

	OvaleCondition:RegisterCondition("agility", false, Agility)
	OvaleCondition:RegisterCondition("attackpower", false, AttackPower)
	OvaleCondition:RegisterCondition("critrating", false, CritRating)
	OvaleCondition:RegisterCondition("hasterating", false, HasteRating)
	OvaleCondition:RegisterCondition("intellect", false, Intellect)
	OvaleCondition:RegisterCondition("mastery", false, MasteryEffect)
	OvaleCondition:RegisterCondition("masteryeffect", false, MasteryEffect)
	OvaleCondition:RegisterCondition("masteryrating", false, MasteryRating)
	OvaleCondition:RegisterCondition("meleecritchance", false, MeleeCritChance)
	OvaleCondition:RegisterCondition("meleehaste", false, MeleeHaste)
	OvaleCondition:RegisterCondition("multistrikechance", false, MultistrikeChance)
	OvaleCondition:RegisterCondition("rangedcritchance", false, RangedCritChance)
	OvaleCondition:RegisterCondition("spellcritchance", false, SpellCritChance)
	OvaleCondition:RegisterCondition("spellhaste", false, SpellHaste)
	OvaleCondition:RegisterCondition("spellpower", false, Spellpower)
	OvaleCondition:RegisterCondition("spirit", false, Spirit)
	OvaleCondition:RegisterCondition("stamina", false, Stamina)
	OvaleCondition:RegisterCondition("strength", false, Strength)
end

do
	--- Get the current speed of the target.
	-- If the target is not moving, then this condition returns 0 (zero).
	-- If the target is at running speed, then this condition returns 100.
	-- @name Speed
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The speed of the target.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Speed(more 0) and not BuffPresent(aspect_of_the_fox)
	--     Spell(aspect_of_the_fox)

	local function Speed(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local value = API_GetUnitSpeed(target) * 100 / 7
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("speed", false, Speed)
end

do
	--- Get the cooldown in seconds on a spell before it gains another charge.
	-- @name SpellChargeCooldown
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see SpellCharges
	-- @usage
	-- if SpellChargeCooldown(roll) <2
	--     Spell(roll usable=1)

	local function SpellChargeCooldown(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local charges, maxCharges, start, duration = state:GetSpellCharges(spellId, atTime)
		if charges and charges < maxCharges then
			return TestValue(start, start + duration, duration, start, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("spellchargecooldown", true, SpellChargeCooldown)
end

do
	--- Get the number of charges of the spell.
	-- @name SpellCharges
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param count Optional. Sets whether a count or a fractional value is returned.
	--     Defaults to count=1.
	--     Valid values: 0, 1.
	-- @return The number of charges.
	-- @return A boolean value for the result of the comparison.
	-- @see SpellChargeCooldown
	-- @usage
	-- if SpellCharges(savage_defense) >1
	--     Spell(savage_defense)

	local function SpellCharges(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local charges, maxCharges, start, duration = state:GetSpellCharges(spellId, atTime)
		if not charges then return nil end
		charges = charges or 0
		maxCharges = maxCharges or 1
		if namedParams.count == 0 and charges < maxCharges then
			return TestValue(state.currentTime, INFINITY, charges + 1, start + duration, 1 / duration, comparator, limit)
		end
		return Compare(charges, comparator, limit)
	end

	OvaleCondition:RegisterCondition("charges", true, SpellCharges)
	OvaleCondition:RegisterCondition("spellcharges", true, SpellCharges)
end

do
	--- Get the number of seconds before any of the listed spells are ready for use.
	-- @name SpellCooldown
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param ... Optional. Additional spell IDs.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see TimeToSpell
	-- @usage
	-- if ShadowOrbs() ==3 and SpellCooldown(mind_blast) <2
	--     Spell(devouring_plague)

	local function SpellCooldown(positionalParams, namedParams, state, atTime)
		local comparator, limit
		local usable = (namedParams.usable == 1)
		local target = ParseCondition(positionalParams, namedParams, state, "target")
		local earliest = INFINITY
		for i, spellId in ipairs(positionalParams) do
			if OvaleCondition.COMPARATOR[spellId] then
				comparator, limit = spellId, positionalParams[i + 1]
				break
			elseif not usable or state:IsUsableSpell(spellId, atTime, OvaleGUID:UnitGUID(target)) then
				local start, duration = state:GetSpellCooldown(spellId)
				local t = 0
				if start > 0 and duration > 0 then
					t = start + duration
				end
				if earliest > t then
					earliest = t
				end
			end
		end
		--[[
			If there are no known spells in the list, then treat the spell as ready.
			This matches SimulationCraft's behavior regarding cooldowns of spells that
			are not known -- they are considered to have a cooldown of zero.
		--]]
		if earliest == INFINITY then
			return Compare(0, comparator, limit)
		elseif earliest > 0 then
			return TestValue(0, earliest, 0, earliest, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("spellcooldown", true, SpellCooldown)
end

do
	--- Get the cooldown duration in seconds for a given spell.
	-- @name SpellCooldownDuration
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.

	local function SpellCooldownDuration(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target = ParseCondition(positionalParams, namedParams, state, "target")
		local duration = state:GetSpellCooldownDuration(spellId, atTime, target)
		return Compare(duration, comparator, limit)
	end

	OvaleCondition:RegisterCondition("spellcooldownduration", true, SpellCooldownDuration)
end

do
	--- Get the recharge duration in seconds for a given spell.
	-- @name SpellRechargeDuration
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.

	local function SpellRechargeDuration(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target = ParseCondition(positionalParams, namedParams, state, "target")
		
		local cd = state:GetCD(spellId)
		local duration = cd.chargeDuration or state:GetSpellCooldownDuration(spellId, atTime, target)
		
		return Compare(duration, comparator, limit)
	end

	OvaleCondition:RegisterCondition("spellrechargeduration", true, SpellRechargeDuration)
end

do
	--- Get data for the given spell defined by SpellInfo(...)
	-- @name SpellData
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param key The name of the data set by SpellInfo(...).
	--     Valid values are any alphanumeric string.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number data associated with the given key.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if BuffRemaining(slice_and_dice) >= SpellData(shadow_blades duration)
	--     Spell(shadow_blades)

	local function SpellData(positionalParams, namedParams, state, atTime)
		local spellId, key, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3], positionalParams[4]
		local si = OvaleData.spellInfo[spellId]
		if si then
			local value = si[key]
			if value then
				return Compare(value, comparator, limit)
			end
		end
		return nil
	end

	OvaleCondition:RegisterCondition("spelldata", false, SpellData)
end

do
	--- Returns the number of times a spell can be cast. Generally used for spells whose casting is limited by the number of item reagents in the player's possession. .
	-- @name SpellCount
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of times a spell can be cast.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if SpellCount(expel_harm) > 1
	--     Spell(expel_harm)
	local function SpellCount(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local spellCount = OvaleSpellBook:GetSpellCount(spellId)
		return Compare(spellCount, comparator, limit)
	end

	OvaleCondition:RegisterCondition("spellcount", true, SpellCount)
end

do
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

	local function SpellKnown(positionalParams, namedParams, state, atTime)
		local spellId, yesno = positionalParams[1], positionalParams[2]
		local boolean = OvaleSpellBook:IsKnownSpell(spellId)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("spellknown", true, SpellKnown)
end

do
	--- Get the maximum number of charges of the spell.
	-- @name SpellMaxCharges
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param count Optional. Sets whether a count or a fractional value is returned.
	--     Defaults to count=1.
	--     Valid values: 0, 1.
	-- @return The number of charges.
	-- @return A boolean value for the result of the comparison.
	-- @see SpellChargeCooldown
	-- @usage
	-- if SpellCharges(savage_defense) >1
	--     Spell(savage_defense)

	local function SpellMaxCharges(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local charges, maxCharges, start, duration = state:GetSpellCharges(spellId, atTime)
		if not maxCharges then return nil end
		maxCharges = maxCharges or 1
		return Compare(maxCharges, comparator, limit)
	end

	OvaleCondition:RegisterCondition("spellmaxcharges", true, SpellMaxCharges)
end

do
	--- Test if the given spell is usable.
	-- A spell is usable if the player has learned the spell and meets any requirements for casting the spell.
	-- Does not account for spell cooldowns or having enough of a primary (pooled) resource.
	-- @name SpellUsable
	-- @paramsig boolean
	-- @param id The spell ID.
	-- @param yesno Optional. If yes, then return true if the spell is usable. If no, then return true if it isn't usable.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @see SpellKnown

	local function SpellUsable(positionalParams, namedParams, state, atTime)
		local spellId, yesno = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state, "target")
		local isUsable, noMana = state:IsUsableSpell(spellId, atTime, OvaleGUID:UnitGUID(target))
		local boolean = isUsable or noMana
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("spellusable", true, SpellUsable)
end

do
	local LIGHT_STAGGER = 124275
	local MODERATE_STAGGER = 124274
	local HEAVY_STAGGER = 124273

	--- Get the remaining amount of damage Stagger will cause to the target.
	-- @name StaggerRemaining
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The amount of damage.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if StaggerRemaining() / MaxHealth() >0.4 Spell(purifying_brew)

	local function StaggerRemaining(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, HEAVY_STAGGER, "HARMFUL")
		if not state:IsActiveAura(aura, atTime) then
			aura = state:GetAura(target, MODERATE_STAGGER, "HARMFUL")
		end
		if not state:IsActiveAura(aura, atTime) then
			aura = state:GetAura(target, LIGHT_STAGGER, "HARMFUL")
		end
		if state:IsActiveAura(aura, atTime) then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			local stagger = API_UnitStagger(target)
			local rate = -1 * stagger / (ending - start)
			return TestValue(gain, ending, 0, ending, rate, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("staggerremaining", false, StaggerRemaining)
	OvaleCondition:RegisterCondition("staggerremains", false, StaggerRemaining)
end

do
	--- Test if the player is in a given stance.
	-- @name Stance
	-- @paramsig boolean
	-- @param stance The stance name or a number representing the stance index.
	-- @param yesno Optional. If yes, then return true if the player is in the given stance. If no, then return true otherwise.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- unless Stance(druid_bear_form) Spell(bear_form)

	local function Stance(positionalParams, namedParams, state, atTime)
		local stance, yesno = positionalParams[1], positionalParams[2]
		local boolean = state:IsStance(stance)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("stance", false, Stance)
end

do
	--- Test if the player is currently stealthed.
	-- The player is stealthed if rogue Stealth, druid Prowl, or a similar ability is active.
	-- @name Stealthed
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if stealthed. If no, then return true if it not stealthed.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if Stealthed() or BuffPresent(shadow_dance)
	--     Spell(ambush)

	local function Stealthed(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local boolean = state:GetAura("player", "stealthed_buff") or API_IsStealthed()
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isstealthed", false, Stealthed)
	OvaleCondition:RegisterCondition("stealthed", false, Stealthed)
end

do
	--- Get the time elapsed in seconds since the player's previous melee swing (white attack).
	-- @name LastSwing
	-- @paramsig number or boolean
	-- @param hand Optional. Sets which hand weapon's melee swing.
	--     If no hand is specified, then return the time elapsed since the previous swing of either hand's weapon.
	--     Valid values: main, off.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see NextSwing

	local function LastSwing(positionalParams, namedParams, state, atTime)
		local swing = positionalParams[1]
		local comparator, limit
		local start
		if swing and swing == "main" or swing == "off" then
			comparator, limit = positionalParams[2], positionalParams[3]
			start = 0
		else
			comparator, limit = positionalParams[1], positionalParams[2]
			start = 0
		end
		Ovale:OneTimeMessage("Warning: 'LastSwing()' is not implemented.")
		return TestValue(start, INFINITY, 0, start, 1, comparator, limit)
	end

	--- Get the time in seconds until the player's next melee swing (white attack).
	-- @name NextSwing
	-- @paramsig number or boolean
	-- @param hand Optional. Sets which hand weapon's melee swing.
	--     If no hand is specified, then return the time until the next swing of either hand's weapon.
	--     Valid values: main, off.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds
	-- @return A boolean value for the result of the comparison.
	-- @see LastSwing

	local function NextSwing(positionalParams, namedParams, state, atTime)
		local swing = positionalParams[1]
		local comparator, limit
		local ending
		if swing and swing == "main" or swing == "off" then
			comparator, limit = positionalParams[2], positionalParams[3]
			ending = 0
		else
			comparator, limit = positionalParams[1], positionalParams[2]
			ending = 0
		end
		Ovale:OneTimeMessage("Warning: 'NextSwing()' is not implemented.")
		return TestValue(0, ending, 0, ending, -1, comparator, limit)
	end

	OvaleCondition:RegisterCondition("lastswing", false, LastSwing)
	OvaleCondition:RegisterCondition("nextswing", false, NextSwing)
end

do
	--- Test if the given talent is active.
	-- @name Talent
	-- @paramsig boolean
	-- @param id The talent ID.
	-- @param yesno Optional. If yes, then return true if the talent is active. If no, then return true if it isn't active.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if Talent(blood_tap_talent) Spell(blood_tap)

	local function Talent(positionalParams, namedParams, state, atTime)
		local talentId, yesno = positionalParams[1], positionalParams[2]
		local boolean = (OvaleSpellBook:GetTalentPoints(talentId) > 0)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("talent", false, Talent)
end

do
	--- Get the number of points spent in a talent (0 or 1)
	-- @name TalentPoints
	-- @paramsig number or boolean
	-- @param talent Talent to inspect.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of talent points.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if TalentPoints(blood_tap_talent) Spell(blood_tap)

	local function TalentPoints(positionalParams, namedParams, state, atTime)
		local talent, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = OvaleSpellBook:GetTalentPoints(talent)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("talentpoints", false, TalentPoints)
end

do
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

	local function TargetIsPlayer(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local target = ParseCondition(positionalParams, namedParams, state)
		local boolean = API_UnitIsUnit("player", target .. "target")
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("istargetingplayer", false, TargetIsPlayer)
	OvaleCondition:RegisterCondition("targetisplayer", false, TargetIsPlayer)
end

do
	--- Get the amount of threat on the current target relative to the its primary aggro target, scaled to between 0 (zero) and 100.
	-- This is a number between 0 (no threat) and 100 (will become the primary aggro target).
	-- @name Threat
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The amount of threat.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Threat() >90 Spell(fade)
	-- if Threat(more 90) Spell(fade)

	local function Threat(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		local target = ParseCondition(positionalParams, namedParams, state, "target")
		local _, _, value = API_UnitDetailedThreatSituation("player", target)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("threat", false, Threat)
end

do
	--- Get the number of seconds between ticks of a periodic aura on a target.
	-- @name TickTime
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param filter Optional. The type of aura to check.
	--     Default is any.
	--     Valid values: any, buff, debuff
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see TicksRemaining

	local function TickTime(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, auraId, filter, mine)
		local tickTime
		if state:IsActiveAura(aura, atTime) then
			tickTime = aura.tick
		else
			tickTime = OvaleData:GetTickLength(auraId, state)
		end
		if tickTime and tickTime > 0 then
			return Compare(tickTime, comparator, limit)
		end
		return Compare(INFINITY, comparator, limit)
	end

	OvaleCondition:RegisterCondition("ticktime", false, TickTime)
end

do
	--- Get the remaining number of ticks of a periodic aura on a target.
	-- @name TicksRemaining
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param filter Optional. The type of aura to check.
	--     Default is any.
	--     Valid values: any, buff, debuff
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of ticks.
	-- @return A boolean value for the result of the comparison.
	-- @see TickTime
	-- @usage
	-- if target.TicksRemaining(shadow_word_pain) <2
	--     Spell(shadow_word_pain)

	local function TicksRemaining(positionalParams, namedParams, state, atTime)
		local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target, filter, mine = ParseCondition(positionalParams, namedParams, state)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain, start, ending, tick = aura.gain, aura.start, aura.ending, aura.tick
			if tick and tick > 0 then
				return TestValue(gain, INFINITY, 1, ending, -1/tick, comparator, limit)
			end
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("ticksremaining", false, TicksRemaining)
	OvaleCondition:RegisterCondition("ticksremain", false, TicksRemaining)
end

do
	--- Get the number of seconds elapsed since the player entered combat.
	-- @name TimeInCombat
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if TimeInCombat(more 5) Spell(bloodlust)

	local function TimeInCombat(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2]
		if state.inCombat then
			local start = state.combatStartTime
			return TestValue(start, INFINITY, 0, start, 1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timeincombat", false, TimeInCombat)
end

do
	--- Get the number of seconds elapsed since the player cast the given spell.
	-- @name TimeSincePreviousSpell
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if TimeSincePreviousSpell(pestilence) > 28 Spell(pestilence)

	local function TimeSincePreviousSpell(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local t = state:TimeOfLastCast(spellId)
		return TestValue(0, INFINITY, 0, t, 1, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timesincepreviousspell", false, TimeSincePreviousSpell)
end

do
	--- Get the time in seconds until the next scheduled Bloodlust cast.
	-- Not implemented, always returns 3600 seconds.
	-- @name TimeToBloodlust
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.

	local function TimeToBloodlust(positionalParams, namedParams, state, atTime)
		local comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = 3600
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timetobloodlust", false, TimeToBloodlust)
end

do
	local function TimeToEclipse(positionalParams, namedParams, state, atTime)
		local seconds, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local value = 3600 * 24 * 7
		Ovale:OneTimeMessage("Warning: 'TimeToEclipse()' is not implemented.")
		return TestValue(0, INFINITY, value, atTime, -1, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timetoeclipse", false, TimeToEclipse)
end

do
	--- Get the number of seconds before the player reaches the given power level.
	local function TimeToPower(powerType, level, comparator, limit, state, atTime)
		local level = level or 0
		local power = state[powerType] or 0
		local powerRegen = state.powerRate[powerType] or 1
		if powerRegen == 0 then
			if power == level then
				return Compare(0, comparator, limit)
			end
			return Compare(INFINITY, comparator, limit)
		else
			local t = (level - power) / powerRegen
			if t > 0 then
				local ending = state.currentTime + t
				return TestValue(0, ending, 0, ending, -1, comparator, limit)
			end
			return Compare(0, comparator, limit)
		end
	end

	--- Get the number of seconds before the player reaches the given energy level for feral druids, non-mistweaver monks and rogues.
	-- @name TimeToEnergy
	-- @paramsig number or boolean
	-- @param level. The level of energy to reach.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @see TimeToEnergyFor, TimeToMaxEnergy
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if TimeToEnergy(100) < 1.2 Spell(sinister_strike)

	local function TimeToEnergy(positionalParams, namedParams, state, atTime)
		local level, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		return TimeToPower("energy", level, comparator, limit, state, atTime)
	end

	--- Get the number of seconds before the player reaches maximum energy for feral druids, non-mistweaver monks and rogues.
	-- @name TimeToMaxEnergy
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @see TimeToEnergy, TimeToEnergyFor
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if TimeToMaxEnergy() < 1.2 Spell(sinister_strike)

	local function TimeToMaxEnergy(positionalParams, namedParams, state, atTime)
		local powerType = "energy"
		local comparator, limit = positionalParams[1], positionalParams[2]
		local level = OvalePower.maxPower[powerType] or 0
		return TimeToPower(powerType, level, comparator, limit, state, atTime)
	end

	--- Get the number of seconds before the player reaches the given focus level for hunters.
	-- @name TimeToFocus
	-- @paramsig number or boolean
	-- @param level. The level of focus to reach.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @see TimeToFocusFor, TimeToMaxFocus
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if TimeToFocus(100) < 1.2 Spell(cobra_shot)

	local function TimeToFocus(positionalParams, namedParams, state, atTime)
		local level, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		return TimeToPower("focus", level, comparator, limit, state, atTime)
	end

	--- Get the number of seconds before the player reaches maximum focus for hunters.
	-- @name TimeToMaxFocus
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @see TimeToFocus, TimeToFocusFor
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if TimeToMaxFocus() < 1.2 Spell(cobra_shot)

	local function TimeToMaxFocus(positionalParams, namedParams, state, atTime)
		local powerType = "focus"
		local comparator, limit = positionalParams[1], positionalParams[2]
		local level = OvalePower.maxPower[powerType] or 0
		return TimeToPower(powerType, level, comparator, limit, state, atTime)
	end

	OvaleCondition:RegisterCondition("timetoenergy", false, TimeToEnergy)
	OvaleCondition:RegisterCondition("timetofocus", false, TimeToFocus)
	OvaleCondition:RegisterCondition("timetomaxenergy", false, TimeToMaxEnergy)
	OvaleCondition:RegisterCondition("timetomaxfocus", false, TimeToMaxFocus)
end

do
	local function TimeToPowerFor(powerType, positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target = ParseCondition(positionalParams, namedParams, state, "target")
		if not powerType then
			local _, pt = OvalePower:GetSpellCost(spellId)
			powerType = pt
		end
		local seconds = state:TimeToPower(spellId, atTime, OvaleGUID:UnitGUID(target), powerType)

		if seconds == 0 then
			return Compare(0, comparator, limit)
		elseif seconds < INFINITY then
			return TestValue(0, state.currentTime + seconds, seconds, state.currentTime, -1, comparator, limit)
		else -- if seconds == INFINITY then
			return Compare(INFINITY, comparator, limit)
		end
	end

	--- Get the number of seconds before the player has enough energy to cast the given spell.
	-- @name TimeToEnergyFor
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see TimeToEnergyFor, TimeToMaxEnergy

	local function TimeToEnergyFor(positionalParams, namedParams, state, atTime)
		return TimeToPowerFor("energy", positionalParams, namedParams, state, atTime)
	end

	--- Get the number of seconds before the player has enough focus to cast the given spell.
	-- @name TimeToFocusFor
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see TimeToFocusFor

	local function TimeToFocusFor(positionalParams, namedParams, state, atTime)
		return TimeToPowerFor("focus", positionalParams, namedParams, state, atTime)
	end

	OvaleCondition:RegisterCondition("timetoenergyfor", true, TimeToEnergyFor)
	OvaleCondition:RegisterCondition("timetofocusfor", true, TimeToFocusFor)
end

do
	--- Get the number of seconds before the spell is ready to be cast, either due to cooldown or resources.
	-- @name TimeToSpell
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.

	local function TimeToSpell(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target = ParseCondition(positionalParams, namedParams, state, "target")
		local seconds = state:GetTimeToSpell(spellId, atTime, OvaleGUID:UnitGUID(target))
		if seconds == 0 then
			return Compare(0, comparator, limit)
		elseif seconds < INFINITY then
			return TestValue(0, state.currentTime + seconds, seconds, state.currentTime, -1, comparator, limit)
		else -- if seconds == INFINITY then
			return Compare(INFINITY, comparator, limit)
		end
	end

	OvaleCondition:RegisterCondition("timetospell", true, TimeToSpell)
end

do
	--- Get the time scaled by the specified haste type, defaulting to spell haste.
	--- For example, if a DoT normally ticks every 3 seconds and is scaled by spell haste, then it ticks every TimeWithHaste(3 haste=spell) seconds.
	-- @name TimeWithHaste
	-- @paramsig number or boolean
	-- @param time The time in seconds.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param haste Optional. Sets whether "time" should be lengthened or shortened due to haste.
	--     Defaults to haste=spell.
	--     Valid values: melee, spell.
	-- @return The time in seconds scaled by haste.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if target.DebuffRemaining(flame_shock) < TimeWithHaste(3)
	--     Spell(flame_shock)

	local function TimeWithHaste(positionalParams, namedParams, state, atTime)
		local seconds, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local haste = namedParams.haste or "spell"
		local value = GetHastedTime(seconds, haste, state)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timewithhaste", false, TimeWithHaste)
end

do
	--- Test if the totem has expired.
	-- @name TotemExpires
	-- @paramsig boolean
	-- @param id The ID of the spell used to summon the totem or one of the four shaman totem categories (air, earth, fire, water).
	-- @param seconds Optional. The maximum number of seconds before the totem should expire.
	--     Defaults to 0 (zero).
	-- @return A boolean value.
	-- @see TotemPresent, TotemRemaining
	-- @usage
	-- if TotemExpires(fire) Spell(searing_totem)
	-- if TotemPresent(healing_stream_totem) and TotemExpires(water 3) Spell(totemic_recall)

	local function TotemExpires(positionalParams, namedParams, state, atTime)
		local id, seconds = positionalParams[1], positionalParams[2]
		seconds = seconds or 0
		if type(id) == "string" then
			local _, name, startTime, duration = state:GetTotemInfo(id)
			if startTime then
				return startTime + duration - seconds, INFINITY
			end
		else -- if type(id) == "number" then
			local count, start, ending = state:GetTotemCount(id, atTime)
			if count > 0 then
				return ending - seconds, INFINITY
			end
		end
		return 0, INFINITY
	end

	--- Test if the totem is present.
	-- @name TotemPresent
	-- @paramsig boolean
	-- @param id The ID of the spell used to summon the totem or one of the four shaman totem categories (air, earth, fire, water).
	-- @return A boolean value.
	-- @see TotemExpires, TotemRemaining
	-- @usage
	-- if not TotemPresent(fire) Spell(searing_totem)
	-- if TotemPresent(healing_stream_totem) and TotemExpires(water 3) Spell(totemic_recall)

	local function TotemPresent(positionalParams, namedParams, state, atTime)
		local id = positionalParams[1]
		if type(id) == "string" then
			local _, name, startTime, duration = state:GetTotemInfo(id)
			if startTime and duration > 0 then
				return startTime, startTime + duration
			end
		else -- if type(id) == "number" then
			local count, start, ending = state:GetTotemCount(id, atTime)
			if count > 0 then
				return start, ending
			end
		end
		return nil
	end

	OvaleCondition:RegisterCondition("totemexpires", false, TotemExpires)
	OvaleCondition:RegisterCondition("totempresent", false, TotemPresent)

	--- Get the remaining time in seconds before a totem expires.
	-- @name TotemRemaining
	-- @paramsig number or boolean
	-- @param id The ID of the spell used to summon the totem or one of the four shaman totem categories (air, earth, fire, water).
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see TotemExpires, TotemPresent
	-- @usage
	-- if TotemRemaining(healing_stream_totem) <2 Spell(totemic_recall)

	local function TotemRemaining(positionalParams, namedParams, state, atTime)
		local id, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		if type(id) == "string" then
			local _, name, startTime, duration = state:GetTotemInfo(id)
			if startTime and duration > 0 then
				local start, ending = startTime, startTime + duration
				return TestValue(start, ending, 0, ending, -1, comparator, limit)
			end
		else -- if type(id) == "number" then
			local count, start, ending = state:GetTotemCount(id, atTime)
			if count > 0 then
				return TestValue(start, ending, 0, ending, -1, comparator, limit)
			end
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("totemremaining", false, TotemRemaining)
	OvaleCondition:RegisterCondition("totemremains", false, TotemRemaining)
end

do
	-- Check if a tracking is enabled
	-- 1: the spell id
	-- return bool

	local function Tracking(positionalParams, namedParams, state, atTime)
		local spellId, yesno = positionalParams[1], positionalParams[2]
		local spellName = OvaleSpellBook:GetSpellName(spellId)
		local numTrackingTypes = API_GetNumTrackingTypes()
		local boolean = false
		for i = 1, numTrackingTypes do
			local name, _, active = API_GetTrackingInfo(i)
			if name and name == spellName then
				boolean = (active == 1)
				break
			end
		end
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("tracking", false, Tracking)
end

do
	--- The travel time of a spell to the target in seconds.
	-- This is a fixed guess at 0s or the travel time of the spell in the spell information if given.
	-- @name TravelTime
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target of the spell. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if target.DebuffPresent(shadowflame_debuff) < TravelTime(hand_of_guldan) + GCD()
	--     Spell(hand_of_guldan)

	local function TravelTime(positionalParams, namedParams, state, atTime)
		local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
		local target = ParseCondition(positionalParams, namedParams, state, "target")
		local si = spellId and OvaleData.spellInfo[spellId]
		-- TODO: Track average time in flight to target for the spell.
		local travelTime = 0
		if si then
			travelTime = si.travel_time or si.max_travel_time or 0
		end
		if travelTime > 0 then
			-- XXX Estimate the travel time to the target
			local estimatedTravelTime = 1
			if travelTime < estimatedTravelTime then
				travelTime = estimatedTravelTime
			end
		end
		return Compare(travelTime, comparator, limit)
	end

	OvaleCondition:RegisterCondition("traveltime", true, TravelTime)
	OvaleCondition:RegisterCondition("maxtraveltime", true, TravelTime)
end

do
	--- A condition that always returns true.
	-- @name True
	-- @paramsig boolean
	-- @return A boolean value.

	local function True(positionalParams, namedParams, state, atTime)
		return 0, INFINITY
	end

	OvaleCondition:RegisterCondition("true", false, True)
end

do
	--- The normalized weapon damage of the weapon in the given hand.
	-- @name WeaponDamage
	-- @paramsig number or boolean
	-- @param hand Optional. Sets which hand weapon.
	--     Defaults to main.
	--     Valid values: main, off
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The normalized weapon damage.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- AddFunction MangleDamage {
	--     WeaponDamage() * 5 + 78
	-- }

	local function WeaponDamage(positionalParams, namedParams, state, atTime)
		local hand = positionalParams[1]
		local comparator, limit
		local value = 0
		if hand == "offhand" or hand == "off" then
			comparator, limit = positionalParams[2], positionalParams[3]
			value = state.offHandWeaponDamage
		elseif hand == "mainhand" or hand == "main" then
			comparator, limit = positionalParams[2], positionalParams[3]
			value = state.mainHandWeaponDamage
		else
			comparator, limit = positionalParams[1], positionalParams[2]
			value = state.mainHandWeaponDamage
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("weapondamage", false, WeaponDamage)
end

do
	--- Test if the weapon imbue on the given weapon has expired or will expire after a given number of seconds.
	-- @name WeaponEnchantExpires
	-- @paramsig boolean
	-- @param hand Sets which hand weapon.
	--     Valid values: main, off.
	-- @param seconds Optional. The maximum number of seconds before the weapon imbue should expire.
	--     Defaults to 0 (zero).
	-- @return A boolean value.
	-- @usage
	-- if WeaponEnchantExpires(main) Spell(windfury_weapon)

	local function WeaponEnchantExpires(positionalParams, namedParams, state, atTime)
		local hand, seconds = positionalParams[1], positionalParams[2]
		seconds = seconds or 0
		local hasMainHandEnchant, mainHandExpiration, _, hasOffHandEnchant, offHandExpiration = API_GetWeaponEnchantInfo()
		local now = API_GetTime()
		if hand == "mainhand" or hand == "main" then
			if hasMainHandEnchant then
				mainHandExpiration = mainHandExpiration / 1000
				return now + mainHandExpiration - seconds, INFINITY
			end
		elseif hand == "offhand" or hand == "off" then
			if hasOffHandEnchant then
				offHandExpiration = offHandExpiration / 1000
				return now + offHandExpiration - seconds, INFINITY
			end
		end
		return 0, INFINITY
	end

	OvaleCondition:RegisterCondition("weaponenchantexpires", false, WeaponEnchantExpires)
end

do
	--- Test if a sigil is charging
	-- @name SigilCharging
	-- @paramsig boolean
	-- @param flame, silence, misery, chains
	-- @return A boolean value.
	-- @usage
	-- if not SigilCharging(flame) Spell(sigil_of_flame)
	local function SigilCharging(positionalParams, namedParams, state, atTime)
		local charging = false
		for _,v in ipairs(positionalParams) do
			charging = charging or state:IsSigilCharging(v, atTime) 
		end
		return TestBoolean(charging, "yes")
	end
	
	OvaleCondition:RegisterCondition("sigilcharging", false, SigilCharging)
end

do
	--- Test with DBM or BigWigs (if available) whether a boss is currently engaged
	--- otherwise test for known units and/or world boss
	-- @name IsBossFight
	-- @return A boolean value.
	-- @usage
	-- if IsBossFight() Spell(metamorphosis_havoc)
	local function IsBossFight(positionalParams, namedParams, state, atTime)
		local bossEngaged = state.inCombat and OvaleBossMod:IsBossEngaged(state)
		return TestBoolean(bossEngaged, "yes")
	end
	
	OvaleCondition:RegisterCondition("isbossfight", false, IsBossFight)
end

do
	--- Check for the target's race
	-- @name Race
	-- @param all the races you which to check for
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @usage
	-- if Race(BloodElf) Spell(arcane_torrent)
	local function Race(positionalParams, namedParams, state, atTime)
		local isRace = false
		local target = namedParams.target or "player"
		local _, targetRaceId = API_UnitRace(target)
		
		for _,v in ipairs(positionalParams) do
			isRace = isRace or (v == raceId)
		end
		return TestBoolean(isRace, "yes")
	end
	
	OvaleCondition:RegisterCondition("race", false, Race)
end
