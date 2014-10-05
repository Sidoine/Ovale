--[[--------------------------------------------------------------------
    Copyright (C) 2009, 2010, 2011, 2012, 2013 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local _, Ovale = ...

local LibBabbleCreatureType = LibStub("LibBabble-CreatureType-3.0", true)
local LibRangeCheck = LibStub("LibRangeCheck-2.0", true)

local OvaleBestAction = Ovale.OvaleBestAction
local OvaleCompile = Ovale.OvaleCompile
local OvaleCondition = Ovale.OvaleCondition
local OvaleCooldown = Ovale.OvaleCooldown
local OvaleDamageTaken = Ovale.OvaleDamageTaken
local OvaleData = Ovale.OvaleData
local OvaleEquipement = Ovale.OvaleEquipement
local OvaleFuture = Ovale.OvaleFuture
local OvaleGUID = Ovale.OvaleGUID
local OvaleLatency = Ovale.OvaleLatency
local OvalePower = Ovale.OvalePower
local OvaleRunes = Ovale.OvaleRunes
local OvaleSpellBook = Ovale.OvaleSpellBook
local OvaleSpellDamage = Ovale.OvaleSpellDamage
local OvaleState = Ovale.OvaleState

local floor = math.floor
local ipairs = ipairs
local pairs = pairs
local type = type
local API_GetBuildInfo = GetBuildInfo
local API_GetItemCooldown = GetItemCooldown
local API_GetItemCount = GetItemCount
local API_GetNumTrackingTypes = GetNumTrackingTypes
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local API_GetTotemInfo = GetTotemInfo
local API_GetTrackingInfo = GetTrackingInfo
local API_GetUnitSpeed = GetUnitSpeed
local API_GetWeaponEnchantInfo = GetWeaponEnchantInfo
local API_HasFullControl = HasFullControl
local API_IsHarmfulSpell = IsHarmfulSpell
local API_IsHelpfulSpell = IsHelpfulSpell
local API_IsSpellInRange = IsSpellInRange
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

local Compare = OvaleCondition.Compare
local ParseCondition = OvaleCondition.ParseCondition
local TestBoolean = OvaleCondition.TestBoolean
local TestValue = OvaleCondition.TestValue

local state = OvaleState.state

--[[--------------------
	Helper functions
--]]--------------------

-- Return the target's damage reduction from armor, assuming the target is boss-level.
local function BossArmorDamageReduction(target)
	local BOSS_ARMOR = 24835
	local WEAKENED_ARMOR_DEBUFF = 113746
	local aura = state:GetAura(target, WEAKENED_ARMOR_DEBUFF, "HARMFUL")
	local armor = BOSS_ARMOR
	if state:IsActiveAura(aura) then
		armor = armor * (1 - 0.04 * aura.stacks)
	end
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
local function ComputeParameter(spellId, paramName, state)
	local si = OvaleData:GetSpellInfo(spellId)
	if si and si[paramName] then
		local name = si[paramName]
		local node = OvaleCompile:GetFunctionNode(name)
		if node then
			local timeSpan, priority, element = OvaleBestAction:Compute(node.child[1], state)
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

-- Return the player's cast time in seconds for the given spell.
local function GetCastTime(spellId)
	local _, _, _, _, _, _, castTime = API_GetSpellInfo(spellId)
	castTime = castTime and castTime / 1000 or 0
	return castTime
end

-- Return the time in seconds, adjusted by the named haste effect.
local function GetHastedTime(seconds, haste)
	seconds = seconds or 0
	if not haste then
		return seconds
	elseif haste == "spell" then
		return seconds / state:GetSpellHasteMultiplier()
	elseif haste == "melee" then
		return seconds / state:GetMeleeHasteMultiplier()
	else
		Ovale:Logf("Unknown haste parameter haste=%s", haste)
		return seconds
	end
end

--[[---------------------
	Script conditions
--]]---------------------

do
	-- Test if a white hit just occured
	-- 1 : maximum time after a white hit
	-- Not useful anymore. No widely used spell reset swing timer anyway

	local function AfterWhiteHit(condition)
		local seconds, comparator, limit = condition[1], condition[2], condition[3]
		local value = 0
		Ovale:OneTimeMessage("Warning: 'AfterWhiteHit() is not implemented.")
		return TestValue(start, math.huge, value, now, -1, comparator, limit)
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

	local function ArmorSetBonus(condition)
		local armorSet, count = condition[1], condition[2]
		local value = (OvaleEquipement:GetArmorSetCount(armorSet) >= count) and 1 or 0
		return 0, math.huge, value, 0, 0
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

	local function ArmorSetParts(condition)
		local armorSet, comparator, limit = condition[1], condition[2], condition[3]
		local value = OvaleEquipement:GetArmorSetCount(armorSet)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("armorsetparts", false, ArmorSetParts)
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

	local function BuffAmount(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local value = condition.value or 1
		local statName = "value1"
		if value == 1 then
			statName = "value1"
		elseif value == 2 then
			statName = "value2"
		elseif value == 3 then
			statName = "value3"
		end
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura) then
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

	local function BuffComboPoints(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura) then
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

	local function BuffCooldown(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain, cooldownEnding = aura.gain, aura.cooldownEnding
			cooldownEnding = aura.cooldownEnding or 0
			return TestValue(gain, math.huge, 0, cooldownEnding, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffcooldown", false, BuffCooldown)
	OvaleCondition:RegisterCondition("debuffcooldown", false, BuffCooldown)
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

	local function BuffCountOnAny(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local _, filter, mine = ParseCondition(condition)
		local excludeUnitId = (condition.excludeTarget == 1) and OvaleCondition.defaultTarget or nil

		local count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast = state:AuraCount(auraId, filter, mine, condition.stacks, excludeUnitId)
		if count > 0 and startChangeCount < math.huge then
			local origin = startChangeCount
			local rate = -1 / (endingChangeCount - startChangeCount)
			local start, ending = startFirst, endingLast
			return TestValue(start, ending, count, origin, rate, comparator, limit)
		end
		return Compare(count, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffcountonany", false, BuffCountOnAny)
	OvaleCondition:RegisterCondition("debuffcountonany", false, BuffCountOnAny)

	-- Deprecated.
	OvaleCondition:RegisterCondition("buffcount", false, BuffCountOnAny)
	OvaleCondition:RegisterCondition("debuffcount", false, BuffCountOnAny)
end

do
	--- Get the player's damage multiplier for the given aura at the time the aura was applied on the target.
	-- @name BuffDamageMultiplier
	-- @paramsig number or boolean
	-- @param id The aura spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The damage multiplier.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffDamageMultiplier
	-- @usage
	-- if target.DebuffDamageMultiplier(rake) <1 Spell(rake)

	local function BuffDamageMultiplier(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura) then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			local baseDamageMultiplier = aura.snapshot and aura.snapshot.baseDamageMultiplier or 1
			local damageMultiplier = aura.damageMultiplier or 1
			local value = baseDamageMultiplier * damageMultiplier
			return TestValue(gain, ending, value, start, 0, comparator, limit)
		end
		return Compare(1, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffdamagemultiplier", false, BuffDamageMultiplier)
	OvaleCondition:RegisterCondition("debuffdamagemultiplier", false, BuffDamageMultiplier)
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

	local function BuffDuration(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura) then
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
	--- Get the duration of the aura if it is applied at the current time.
	-- @name BuffDurationIfApplied
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
	-- @usage
	-- if BuffDurationIfApplied(slice_and_dice_buff) > BuffDuration(slice_and_dice_buff)
	--     Spell(slice_and_dice)

	local function BuffDurationIfApplied(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local duration, dotDuration = state:GetDuration(auraId)
		local si = OvaleData.spellInfo[auraId]
		local value = (si and si.tick) and dotDuration or duration
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffdurationifapplied", false, BuffDurationIfApplied)
	OvaleCondition:RegisterCondition("debuffdurationifapplied", false, BuffDurationIfApplied)
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

	local function BuffExpires(condition)
		local auraId, seconds = condition[1], condition[2]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			seconds = GetHastedTime(seconds, condition.haste)
			if ending - seconds <= gain then
				return gain, math.huge
			else
				return ending - seconds, math.huge
			end
		end
		return 0, math.huge
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

	local function BuffPresent(condition)
		local auraId, seconds = condition[1], condition[2]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			seconds = GetHastedTime(seconds, condition.haste)
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

	local function BuffGain(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain = aura.gain or 0
			return TestValue(gain, math.huge, 0, gain, 1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffgain", false, BuffGain)
	OvaleCondition:RegisterCondition("debuffgain", false, BuffGain)
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

	local function BuffRemaining(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			return TestValue(gain, math.huge, 0, ending, -1, comparator, limit)
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

	local function BuffRemainingOnAny(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local _, filter, mine = ParseCondition(condition)
		local excludeUnitId = (condition.excludeTarget == 1) and OvaleCondition.defaultTarget or nil

		local count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast = state:AuraCount(auraId, filter, mine, condition.stacks, excludeUnitId)
		if count > 0 then
			local start, ending = startFirst, endingLast
			return TestValue(start, math.huge, 0, ending, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffremainingonany", false, BuffRemainingOnAny)
	OvaleCondition:RegisterCondition("debuffremainingonany", false, BuffRemainingOnAny)
	OvaleCondition:RegisterCondition("buffremainsonany", false, BuffRemainingOnAny)
	OvaleCondition:RegisterCondition("debuffremainsonany", false, BuffRemainingOnAny)
end

do
	-- Return the value of the stat from the aura snapshot at the time the aura was applied.
	local function BuffSnapshot(statName, defaultValue, condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura) then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			local value = aura.snapshot and aura.snapshot[statName] or defaultValue
			return TestValue(gain, ending, value, start, 0, comparator, limit)
		end
		return Compare(defaultValue, comparator, limit)
	end

	-- Return the value of the given critical strike chance from the aura snapshot at the time the aura was applied.
	local function BuffSnapshotCritChance(statName, defaultValue, condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura) then
			local gain, start, ending = aura.gain, aura.start, aura.ending
			local value = aura.snapshot and aura.snapshot[statName] or defaultValue
			if condition.unlimited ~= 1 and value > 100 then
				value = 100
			end
			return TestValue(gain, ending, value, start, 0, comparator, limit)
		end
		return Compare(defaultValue, comparator, limit)
	end

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

	local function BuffStacks(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura) then
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

	local function BuffStacksOnAny(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local _, filter, mine = ParseCondition(condition)
		local excludeUnitId = (condition.excludeTarget == 1) and OvaleCondition.defaultTarget or nil

		local count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast = state:AuraCount(auraId, filter, mine, 1, excludeUnitId)
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

	local function BuffStealable(condition)
		local target = ParseCondition(condition)
		return state:GetAuraWithProperty(target, "stealable", "HELPFUL")
	end

	OvaleCondition:RegisterCondition("buffstealable", false, BuffStealable)
end

do
	--- Check if the player can cast the given spell (not on cooldown).
	-- @name CanCast
	-- @paramsig boolean
	-- @param id The spell ID to check.
	-- @return True if the spell cast be cast; otherwise, false.

	local function CanCast(condition)
		local spellId = condition[1]
		local start, duration = state:GetSpellCooldown(spellId)
		return start + duration, math.huge
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

	local function CastTime(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local castTime = GetCastTime(spellId)
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

	local function ExecuteTime(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local castTime = GetCastTime(spellId)
		local gcd = OvaleCooldown:GetGCD()
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

	local function Casting(condition)
		local spellId = condition[1]
		local target = ParseCondition(condition)

		-- Get the information about the current spellcast.
		local start, ending, castSpellId, castSpellName
		if target == "player" then
			start = state.startCast
			ending = state.endCast
			castSpellId = state.currentSpellId
			castSpellName = OvaleSpellBook:GetSpellName(castSpellId)
		else
			local spellName, _, _, _, startTime, endTime = UnitCastingInfo(target)
			if not spellName then
				spellName, _, _, _, startTime, endTime = UnitChannelInfo("unit")
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
			elseif spellId == "harmful" and API_IsHarmfulSpell(castSpellName) then
				return start, ending
			elseif spellId == "helpful" and API_IsHelpfulSpell(castSpellName) then
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

	local function CheckBoxOff(condition)
		for i = 1, #condition do
			if Ovale:IsChecked(condition[i]) then
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

	local function CheckBoxOn(condition)
		for i = 1, #condition do
			if not Ovale:IsChecked(condition[i]) then
				return nil
			end
		end
		return 0, math.huge
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

	local function Class(condition)
		local class, yesno = condition[1], condition[2]
		local target = ParseCondition(condition)
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

	local function Classification(condition)
		local classification, yesno = condition[1], condition[2]
		local targetClassification
		local target = ParseCondition(condition)
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
	--- Get the number of combo points on the currently selected target for a feral druid or a rogue.
	-- @name ComboPoints
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of combo points.
	-- @return A boolean value for the result of the comparison.
	-- @see LastComboPoints
	-- @usage
	-- if ComboPoints() >=1 Spell(savage_roar)
	-- if ComboPoints(more 0) Spell(savage_roar)

	local function ComboPoints(condition)
		local comparator, limit = condition[1], condition[2]
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

	local function Counter(condition)
		local counter, comparator, limit = condition[1], condition[2], condition[3]
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

	local function CreatureFamily(condition)
		local name, yesno = condition[1], condition[2]
		local target = ParseCondition(condition)
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

	local function CreatureType(condition)
		local target = ParseCondition(condition)
		local creatureType = API_UnitCreatureType(target)
		local lookupTable = LibBabbleCreatureType and LibBabbleCreatureType:GetLookupTable()
		if lookupTable then
			for _, name in ipairs(condition) do
				if creatureType == lookupTable[name] then
					return 0, math.huge
				end
			end
		end
		return nil
	end

	OvaleCondition:RegisterCondition("creaturetype", false, CreatureType)
end

do
	-- Return the non-critical-strike damage of a spell, given the player's current stats.
	local function GetDamage(spellId)
		-- TODO: Use target's debuffs in this calculation.
		local ap = state.snapshot.attackPower or 0
		local sp = state.snapshot.spellBonusDamage or 0
		local mh = state.snapshot.mainHandWeaponDamage or 0
		local oh = state.snapshot.offHandWeaponDamage or 0
		local bdm = state.snapshot.baseDamageMultiplier or 1
		local dm = state:GetDamageMultiplier(spellId) or 1
		local combo = state.combo or 0
		return OvaleData:GetDamage(spellId, ap, sp, mh, oh, combo) * bdm * dm
	end

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
	-- @see Damage, LastDamage, LastEstimatedDamage

	local AMPLIFICATION = 146051
	local INCREASED_CRIT_EFFECT_3_PERCENT = 44797

	local function CritDamage(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local target = ParseCondition(condition, "target")
		local value = ComputeParameter(spellId, "damage", state)
		if not value then
			value = GetDamage(spellId)
		end
		-- Reduce by armor damage reduction for physical attacks.
		local si = OvaleData:GetSpellInfo(spellId)
		if si and si.physical then
			value = value * (1 - BossArmorDamageReduction(target))
		end

		-- Default crit damage is 2 times normal damage.
		local critMultiplier = 2
		-- Add additional critical strike damage from MoP amplification trinkets.
		do
			local aura = state:GetAura("player", AMPLIFICATION, "HELPFUL")
			if state:IsActiveAura(aura) then
				critMultiplier = critMultiplier + aura.value1
			end
		end
		-- Multiply by increased crit effect from the meta gem.
		do
			local aura = state:GetAura("player", INCREASED_CRIT_EFFECT_3_PERCENT, "HELPFUL")
			if state:IsActiveAura(aura) then
				critMultiplier = critMultiplier * aura.value1
			end
		end

		local value = critMultiplier * value
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("critdamage", false, CritDamage)

	--- Get the current estimated damage of a spell on the target.
	-- The calculated damage takes into account the current attack power, spellpower, weapon damage and combo points (if used).
	-- The damage is computed from information for the spell set via SpellInfo(...):
	--
	-- damage = base + bonusmainhand * MH + bonusoffhand * OH + bonusap * AP + bonuscp * CP + bonusapcp * AP * CP + bonussp * SP
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

	local function Damage(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local target = ParseCondition(condition, "target")
		local value = ComputeParameter(spellId, "damage", state)
		if not value then
			value = GetDamage(spellId)
		end
		-- Reduce by armor damage reduction for physical attacks.
		local si = OvaleData:GetSpellInfo(spellId)
		if si and si.physical then
			value = value * (1 - BossArmorDamageReduction(target))
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("damage", false, Damage)
end

do
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
		local bdm = state.snapshot.baseDamageMultiplier
		local dm = state:GetDamageMultiplier(spellId)
		local value = bdm * dm
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("damagemultiplier", false, DamageMultiplier)
end

do
	--- Get the damage taken by the player in the previous time interval.
	-- @name DamageTaken
	-- @paramsig number or boolean
	-- @param interval The number of seconds before now.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of damage taken in the previous interval.
	-- @return A boolean value for the result of the comparison.
	-- @see IncomingDamage
	-- @usage
	-- if DamageTaken(5) > 50000 Spell(death_strike)

	local function DamageTaken(condition)
		-- Damage taken shouldn't be smoothed since spike damage is important data.
		-- Just present damage taken as a constant value.
		local interval, comparator, limit = condition[1], condition[2], condition[3]
		local value = 0
		if interval > 0 then
			value = OvaleDamageTaken:GetRecentDamage(interval)
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("damagetaken", false, DamageTaken)
	OvaleCondition:RegisterCondition("incomingdamage", false, DamageTaken)
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

	local function Distance(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
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

	local function Eclipse(condition)
		local comparator, limit = condition[1], condition[2]
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

	local function EclipseDir(condition)
		local comparator, limit = condition[1], condition[2]
		local value = OvaleState.state.eclipseDirection
		return Compare(value, comparator, limit)		
	end

	OvaleCondition:RegisterCondition("eclipsedir", false, EclipseDir)
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

	local function Enemies(condition)
		local comparator, limit = condition[1], condition[2]
		local value = state.enemies
		if not value then
			if condition.tagged == 1 then
				value = state.taggedEnemies
			else
				value = state.activeEnemies
			end
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
	-- @name EnergyRegen
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current rate of energy regeneration.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if EnergyRegen() >11 Spell(stance_of_the_sturdy_ox)

	local function EnergyRegen(condition)
		local comparator, limit = condition[1], condition[2]
		local value = state.powerRate.energy
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("energyregen", false, EnergyRegen)
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

	local function Exists(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
		local boolean = (API_UnitExists(target) == 1)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("exists", false, Exists)
end

do
	--- A condition that always returns false.
	-- @name False
	-- @paramsig boolean
	-- @return A boolean value.

	local function False(condition)
		return nil
	end

	OvaleCondition:RegisterCondition("false", false, False)
end

do
	--- Get the amount of regenerated focus per second for hunters.
	-- @name FocusRegen
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current rate of focus regeneration.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if FocusRegen() >20 Spell(arcane_shot)
	-- if FocusRegen(more 20) Spell(arcane_shot)

	local function FocusRegen(condition)
		local comparator, limit = condition[1], condition[2]
		local value = state.powerRate.focus
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("focusregen", false, FocusRegen)
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

	local function GCD(condition)
		local comparator, limit = condition[1], condition[2]
		local value = OvaleCooldown:GetGCD()
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("gcd", false, GCD)
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

	local function GetState(condition)
		local name, comparator, limit = condition[1], condition[2], condition[3]
		local value = state:GetState(name)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("getstate", false, GetState)
end

do
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

	local function Glyph(condition)
		local glyph, yesno = condition[1], condition[2]
		local boolean = OvaleSpellBook:IsActiveGlyph(glyph)
		return TestBoolean(boolean, yesno)
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

	local function HasEquippedItem(condition)
		local itemId, yesno = condition[1], condition[2]
		local ilevel, slot = condition.ilevel, condition.slot
		local boolean = false
		local slotId
		if type(itemId) == "number" then
			slotId = OvaleEquipement:HasEquippedItem(itemId, slot)
			if slotId then
				if not ilevel or (ilevel and ilevel == OvaleEquipement:GetEquippedItemLevel(slotId)) then
					boolean = true
				end
			end
		elseif OvaleData.itemList[itemId] then
			for _, v in pairs(OvaleData.itemList[itemId]) do
				slotId = OvaleEquipement:HasEquippedItem(v, slot)
				if slotId then
					if not ilevel or (ilevel and ilevel == OvaleEquipement:GetEquippedItemLevel(slotId)) then
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

	local function HasFullControl(condition)
		local yesno = condition[1]
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

	local function HasShield(condition)
		local yesno = condition[1]
		local boolean = OvaleEquipement:HasShield()
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

	local function HasTrinket(condition)
		local trinketId, yesno = condition[1], condition[2]
		local boolean = false
		if type(trinketId) == "number" then
			boolean = OvaleEquipement:HasTrinket(trinketId)
		elseif OvaleData.itemList[trinketId] then
			for _, v in pairs(OvaleData.itemList[trinketId]) do
				boolean = OvaleEquipement:HasTrinket(v)
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
	--     Valid values: 1h, 2h
	-- @return A boolean value.
	-- @usage
	-- if HasWeapon(offhand) and BuffStacks(killing_machine) Spell(frost_strike)

	local function HasWeapon(condition)
		local hand, yesno = condition[1], condition[2]
		local weaponType = condition.type
		local boolean = false
		if weaponType == "1h" then
			weaponType = 1
		elseif weaponType == "2h" then
			weaponType = 2
		end
		if hand == "offhand" or hand == "off" then
			boolean = OvaleEquipement:HasOffHandWeapon(weaponType)
		elseif hand == "mainhand" or hand == "main" then
			boolean = OvaleEquipement:HasMainHandWeapon(weaponType)
		end
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("hasweapon", false, HasWeapon)
end

do
	-- static properties for TimeToDie(), indexed by unit ID
	local lastTTDTime = {}
	local lastTTDHealth = {}
	local lastTTDguid = {}
	local lastTTDdps = {}

	--[[
		Returns:
			Estimated number of seconds before the specified unit reaches zero health
			The current time
			Unit's current health
			Unit's maximum health
	--]]
	local function EstimatedTimeToDie(unitId)
		-- Check for target switch.
		if lastTTDguid[unitId] ~= OvaleGUID:GetGUID(unitId) then
			lastTTDguid[unitId] = OvaleGUID:GetGUID(unitId)
			lastTTDTime[unitId] = nil
			if lastTTDHealth[unitId] then
				wipe(lastTTDHealth[unitId])
			else
				lastTTDHealth[unitId] = {}
			end
			lastTTDdps[unitId] = nil
		end

		local timeToDie
		local health = API_UnitHealth(unitId) or 0
		local maxHealth = API_UnitHealthMax(unitId) or 1
		local currentTime = API_GetTime()

		-- Clamp maxHealth to always be at least 1.
		if maxHealth < health then
			maxHealth = health
		end
		if maxHealth < 1 then
			maxHealth = 1
		end

		if health == 0 then
			timeToDie = 0
		elseif maxHealth <= 5 then
			timeToDie = math.huge
		else
			local now = floor(currentTime)
			if (not lastTTDTime[unitId] or lastTTDTime[unitId] < now) and lastTTDguid[unitId] then
				lastTTDTime[unitId] = now
				local mod10, prevHealth
				for delta = 10, 1, -1 do
					mod10 = (now - delta) % 10
					prevHealth = lastTTDHealth[unitId][mod10]
					if delta == 10 then
						lastTTDHealth[unitId][mod10] = health
					end
					if prevHealth and prevHealth > health then
						lastTTDdps[unitId] = (prevHealth - health) / delta
						Ovale:Logf("prevHealth = %d, health = %d, delta = %d, dps = %d", prevHealth, health, delta, lastTTDdps[unitId])
						break
					end
				end
			end
			local dps = lastTTDdps[unitId]
			if dps and dps > 0 then
				timeToDie = health / dps
			else
				timeToDie = math.huge
			end
		end
		-- Clamp time to die at a finite number.
		if timeToDie == math.huge then
			-- Return time to die in the far-off future (one week).
			timeToDie = 3600 * 24 * 7
		end
		return timeToDie, currentTime, health, maxHealth
	end

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

	local function Health(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local timeToDie, now, health, maxHealth = EstimatedTimeToDie(target)
		if not timeToDie then
			return nil
		elseif timeToDie == 0 then
			return Compare(0, comparator, limit)
		end
		local value, origin, rate = health, now, -1 * health / timeToDie
		local start, ending = now, math.huge
		return TestValue(start, ending, value, origin, rate, comparator, limit)
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

	local function HealthMissing(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local timeToDie, now, health, maxHealth = EstimatedTimeToDie(target)
		if not timeToDie or timeToDie == 0 then
			return nil
		end
		local missing = maxHealth - health
		local value, origin, rate = missing, now, health / timeToDie
		local start, ending = now, math.huge
		return TestValue(start, ending, value, origin, rate, comparator, limit)
	end

	OvaleCondition:RegisterCondition("healthmissing", false, Health)
	OvaleCondition:RegisterCondition("lifemissing", false, Health)

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

	local function HealthPercent(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local timeToDie, now, health, maxHealth = EstimatedTimeToDie(target)
		if not timeToDie then
			return nil
		elseif timeToDie == 0 then
			return Compare(0, comparator, limit)
		end
		local healthPercent = health / maxHealth * 100
		local value, origin, rate = healthPercent, now, -1 * healthPercent / timeToDie
		local start, ending = now, math.huge
		return TestValue(start, ending, value, origin, rate, comparator, limit)
	end

	OvaleCondition:RegisterCondition("healthpercent", false, HealthPercent)
	OvaleCondition:RegisterCondition("lifepercent", false, HealthPercent)

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

	local function MaxHealth(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local value = API_UnitHealthMax(target)
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

	local function TimeToDie(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local timeToDie, now = EstimatedTimeToDie(target)
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

	local function TimeToHealthPercent(condition)
		local percent, comparator, limit = condition[1], condition[2], condition[3]
		local target = ParseCondition(condition)
		local timeToDie, now, health, maxHealth = EstimatedTimeToDie(target)
		local healthPercent = health / maxHealth * 100
		if healthPercent >= percent then
			local t = timeToDie * (healthPercent - percent) / healthPercent
			local value, origin, rate = t, now, -1
			local start, ending = now, now + t
			return TestValue(start, ending, value, origin, rate, comparator, limit)
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

	local function InCombat(condition)
		local yesno = condition[1]
		local boolean = Ovale.enCombat
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

	local function InFlightToTarget(condition)
		local spellId, yesno = condition[1], condition[2]
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

	local function InRange(condition)
		local spellId, yesno = condition[1], condition[2]
		local target = ParseCondition(condition)
		local spellName = OvaleSpellBook:GetSpellName(spellId)
		local boolean = (API_IsSpellInRange(spellName, target) == 1)
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

	local function IsAggroed(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
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

	local function IsDead(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
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

	local function IsEnraged(condition)
		local yesno = condition[1]
		return state:GetAuraWithProperty(target, "enraged", "HELPFUL")
	end

	OvaleCondition:RegisterCondition("isfeared", false, IsFeared)
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

	local function IsFeared(condition)
		local yesno = condition[1]
		local aura = state:GetAura("player", "fear_debuff", "HARMFUL")
		local boolean = not API_HasFullControl() and state:IsActiveAura(aura)
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

	local function IsFriend(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
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

	local function IsIncapacitated(condition)
		local yesno = condition[1]
		local aura = state:GetAura("player", "incapacitate_debuff", "HARMFUL")
		local boolean = not API_HasFullControl() and state:IsActiveAura(aura)
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

	local function IsInterruptible(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
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

	local function IsPVP(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
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

	local function IsRooted(condition)
		local yesno = condition[1]
		local aura = state:GetAura("player", "root_debuff", "HARMFUL")
		local boolean = state:IsActiveAura(aura)
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

	local function IsStunned(condition)
		local yesno = condition[1]
		local aura = state:GetAura("player", "stun_debuff", "HARMFUL")
		local boolean = not API_HasFullControl() and state:IsActiveAura(aura)
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

	local function ItemCharges(condition)
		local itemId, comparator, limit = condition[1], condition[2], condition[3]
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

	local function ItemCooldown(condition)
		local itemId, comparator, limit = condition[1], condition[2], condition[3]
		if itemId and type(itemId) ~= "number" then
			itemId = OvaleEquipement:GetEquippedItem(itemId)
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

	local function ItemCount(condition)
		local itemId, comparator, limit = condition[1], condition[2], condition[3]
		local value = API_GetItemCount(itemId)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("itemcount", false, ItemCount)
end

do
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
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local target = ParseCondition(condition, "target")
		local guid = OvaleGUID:GetGUID(target)
		local value = OvaleFuture:GetLastSpellInfo(guid, spellId, "combo") or 0
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("lastcombopoints", false, LastComboPoints)
	OvaleCondition:RegisterCondition("lastspellcombopoints", false, LastComboPoints)
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

	local function LastDamage(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
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

do
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
		local value = ComputeParameter(spellId, "lastEstimatedDamage", state)
		if not value then
			local guid = OvaleGUID:GetGUID(target)
			local ap = OvaleFuture:GetLastSpellInfo(guid, spellId, "attackPower") or 0
			local sp = OvaleFuture:GetLastSpellInfo(guid, spellId, "spellBonusDamage") or 0
			local mh = OvaleFuture:GetLastSpellInfo(guid, spellId, "mainHandWeaponDamage") or 0
			local oh = OvaleFuture:GetLastSpellInfo(guid, spellId, "offHandWeaponDamage") or 0
			local combo = OvaleFuture:GetLastSpellInfo(guid, spellId, "combo") or 0
			local bdm = OvaleFuture:GetLastSpellInfo(guid, spellId, "baseDamageMultiplier") or 1
			local dm = OvaleFuture:GetLastSpellInfo(guid, spellId, "damageMultiplier") or 1
			value = OvaleData:GetDamage(spellId, ap, sp, mh, oh, combo) * bdm * dm
		end
		-- Reduce by armor damage reduction for physical attacks.
		local si = OvaleData:GetSpellInfo(spellId)
		if si and si.physical then
			value = value * (1 - BossArmorDamageReduction(target))
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("lastestimateddamage", false, LastEstimatedDamage)
	OvaleCondition:RegisterCondition("lastspellestimateddamage", false, LastEstimatedDamage)
end

do
	-- Return the value of the stat from the snapshot at the time the spell was cast.
	local function LastSnapshot(statName, defaultValue, condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local target = ParseCondition(condition, "target")
		local guid = OvaleGUID:GetGUID(target)
		local value = OvaleFuture:GetLastSpellInfo(guid, spellId, statName)
		value = value or defaultValue
		return Compare(value, comparator, limit)
	end

	-- Return the value of the given critical strike chance from the aura snapshot at the time the aura was applied.
	local function LastSnapshotCritChance(statName, defaultValue, condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local target = ParseCondition(condition)
		local guid = OvaleGUID:GetGUID(target)
		local value = OvaleFuture:GetLastSpellInfo(guid, spellId, statName)
		value = value or defaultValue
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

do
	--- Get the most recent estimate of roundtrip latency in milliseconds.
	-- @name Latency
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number of milliseconds to compare against.
	-- @return The most recent estimate of latency.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Latency() >1000 Spell(sinister_strike)
	-- if Latency(more 1000) Spell(sinister_strike)

	local function Latency(condition)
		local comparator, limit = condition[1], condition[2]
		local value = OvaleLatency:GetLatency() * 1000
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("latency", false, Latency)
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

	local function Level(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
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

	local function List(condition)
		local name, value = condition[1], condition[2]
		if name and Ovale:GetListValue(name) == value then
			return 0, math.huge
		end
		return nil
	end

	OvaleCondition:RegisterCondition("list", false, List)
end

do
	--- Get the number of seconds until the next tick of a periodic aura on the target.
	-- @name NextTick
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
	-- @see Ticks, TicksRemaining, TickTime

	local function NextTick(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura) then
			local gain, start, ending, tick = aura.gain, aura.start, aura.ending, aura.tick
			if ending < math.huge and tick then
				while ending - tick > state.currentTime do
					ending = ending - tick
				end
				return TestValue(0, ending, 0, ending, -1, comparator, limit)
			end
		end
		return Compare(math.huge, comparator, limit)
	end

	OvaleCondition:RegisterCondition("nexttick", false, NextTick)
end

do
	--- Test if the game is on a PTR server
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then returns true if it is a PTR realm. If no, return true if it is a live realm.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value

	local function PTR(condition)
		local yesno = condition[1]
		local _, _, _, uiVersion = API_GetBuildInfo()
		local boolean = (uiVersion > 50400)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("ptr", false, PTR)
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

	local function PetPresent(condition)
		local yesno = condition[1]
		local target = "pet"
		local boolean = API_UnitExists(target) and not API_UnitIsDead(target)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("petpresent", false, PetPresent)
end

do
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

	--- Return the current deficit of power from max power on the target.
	local function PowerDeficit(powerType, condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		if target == "player" then
			local powerMax = OvalePower.maxPower[powerType] or 0
			if powerMax > 0 then
				local value, origin, rate = powerMax - state[powerType], state.currentTime, -1 * state.powerRate[powerType]
				local start, ending = state.currentTime, math.huge
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

	--- Get the current amount of the player's primary resource for the given spell.
	-- @name PrimaryResource
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of the primary resource.
	-- @return A boolean value for the result of the comparison.

	local function PrimaryResource(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
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
			local _, _, _, _, _, powerTypeId = API_GetSpellInfo(spellId)
			if powerTypeId then
				primaryPowerType = OvalePower.POWER_TYPE[powerTypeId]
			end
		end
		if primaryPowerType then
			local value, origin, rate = state[primaryPowerType], state.currentTime, state.powerRate[primaryPowerType]
			local start, ending = state.currentTime, math.huge
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

	local function AlternatePowerDeficit(condition)
		return PowerDeficit("alternatepower", condition)
	end

	--- Get the number of lacking resource points for a full burning embers bar, between 0 and maximum burning embers, of the target.
	-- @name BurningEmbersDeficit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current burning embers deficit.
	-- @return A boolean value for the result of the comparison.

	local function BurningEmbersDeficit(condition)
		return PowerDeficit("burningembers", condition)
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

	local function ChiDeficit(condition)
		return PowerDeficit("chi", condition)
	end

	--- Get the number of lacking resource points for a full demonic fury bar, between 0 and maximum demonic fury, of the target.
	-- @name DemonicFuryDeficit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current demonic fury deficit.
	-- @return A boolean value for the result of the comparison.

	local function DemonicFuryDeficit(condition)
		return PowerDeficit("demonicfury", condition)
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

	local function EnergyDeficit(condition)
		return PowerDeficit("energy", condition)
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

	local function FocusDeficit(condition)
		return PowerDeficit("focus", condition)
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

	local function HolyPowerDeficit(condition)
		return PowerDeficit("holypower", condition)
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

	local function ManaDeficit(condition)
		return PowerDeficit("mana", condition)
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

	local function RageDeficit(condition)
		return PowerDeficit("rage", condition)
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

	local function RunicPowerDeficit(condition)
		return PowerDeficit("runicpower", condition)
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

	local function ShadowOrbsDeficit(condition)
		return PowerDeficit("shadoworbs", condition)
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

	local function SoulShardsDeficit(condition)
		return PowerDeficit("shards", condition)
	end

	OvaleCondition:RegisterCondition("alternatepowerdeficit", false, AlternatePowerDeficit)
	OvaleCondition:RegisterCondition("burningembersdeficit", false, BurningEmbersDeficit)
	OvaleCondition:RegisterCondition("chideficit", false, ChiDeficit)
	OvaleCondition:RegisterCondition("demonicfurydeficit", false, DemonicFuryDeficit)
	OvaleCondition:RegisterCondition("energydeficit", false, EnergyDeficit)
	OvaleCondition:RegisterCondition("focusdeficit", false, FocusDeficit)
	OvaleCondition:RegisterCondition("holypowerdeficit", false, HolyPowerDeficit)
	OvaleCondition:RegisterCondition("manadeficit", false, ManaDeficit)
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

do
	-- Return the amount of power of the given power type required to cast the given spell.
	local function PowerCost(powerType, condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local value = state:PowerCost(spellId, powerType) or 0
		return Compare(value, comparator, limit)
	end

	--- Get the amount of energy required to cast the given spell.
	-- This returns zero for spells that use either mana or another resource based on stance/specialization, e.g., Monk's Jab.
	-- @name EnergyCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of energy.
	-- @return A boolean value for the result of the comparison.

	local function EnergyCost(condition)
		return PowerCost("energy", condition)
	end

	--- Get the amount of focus required to cast the given spell.
	-- @name FocusCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of focus.
	-- @return A boolean value for the result of the comparison.

	local function FocusCost(condition)
		return PowerCost("focus", condition)
	end

	--- Get the amount of mana required to cast the given spell.
	-- This returns zero for spells that use either mana or another resource based on stance/specialization, e.g., Monk's Jab.
	-- @name ManaCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of mana.
	-- @return A boolean value for the result of the comparison.

	local function ManaCost(condition)
		return PowerCost("mana", condition)
	end

	--- Get the amount of rage required to cast the given spell.
	-- @name RageCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of rage.
	-- @return A boolean value for the result of the comparison.

	local function RageCost(condition)
		return PowerCost("rage", condition)
	end

	--- Get the amount of runic power required to cast the given spell.
	-- @name RunicPowerCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of runic power.
	-- @return A boolean value for the result of the comparison.

	local function RunicPowerCost(condition)
		return PowerCost("runicpower", condition)
	end

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

	local function Present(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
		local boolean = API_UnitExists(target) and not API_UnitIsDead(target)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("present", false, Present)
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

	local function PreviousSpell(condition)
		local spellId, yesno = condition[1], condition[2]
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

	local function RelativeLevel(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
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

	local function RemainingCastTime(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
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
	-- @param type The type of rune.
	--     Valid values: blood, frost, unholy, death
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of runes.
	-- @return A boolean value for the result of the comparison.
	-- @see RuneCount
	-- @usage
	-- if Rune(blood) > 1 Spell(blood_tap)

	local function Rune(condition)
		local name, comparator, limit = condition[1], condition[2], condition[3]
		local count, startCooldown, endCooldown = state:RuneCount(name)
		if startCooldown < math.huge then
			local origin = startCooldown
			local rate = 1 / (endCooldown - startCooldown)
			local start, ending = startCooldown, math.huge
			return TestValue(start, ending, count, origin, rate, comparator, limit)
		end
		return Compare(count, comparator, limit)
	end

	--- Get the current number of active runes of the given type for death knights.
	-- @name RuneCount
	-- @paramsig number or boolean
	-- @param type The type of rune.
	--     Valid values: blood, frost, unholy, death
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of runes.
	-- @return A boolean value for the result of the comparison.
	-- @see Rune
	-- @usage
	-- if RuneCount(unholy) ==2 or RuneCount(frost) ==2 or RuneCount(death) ==2
	--     Spell(obliterate)

	local function RuneCount(condition)
		local name, comparator, limit = condition[1], condition[2], condition[3]
		local count, startCooldown, endCooldown = state:RuneCount(name)
		if startCooldown < math.huge then
			local start, ending = startCooldown, endCooldown
			return TestValue(start, ending, count, start, 0, comparator, limit)
		end
		return Compare(count, comparator, limit)
	end

	OvaleCondition:RegisterCondition("rune", false, Rune)
	OvaleCondition:RegisterCondition("runecount", false, RuneCount)
end

do
	local RUNE_OF_POWER_BUFF = 116014

	--- Get the remaining time in seconds before the latest Rune of Power expires.
	--- Returns non-zero only if the player is standing within an existing Rune of Power.
	-- @name RuneOfPowerRemaining
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if RuneOfPowerRemaining() < CastTime(rune_of_power) Spell(rune_of_power)

	local function RuneOfPowerRemaining(condition)
		local comparator, limit = condition[1], condition[2]
		local aura = state:GetAura("player", RUNE_OF_POWER_BUFF, "HELPFUL")
		if state:IsActiveAura(aura) then
			local start, ending
			for totemSlot = 1, 2 do
				local haveTotem, name, startTime, duration = API_GetTotemInfo(totemSlot)
				if haveTotem and startTime and (not start or startTime > start) then
					start = startTime
					ending = startTime + duration
				end
			end
			if start then
				return TestValue(0, math.huge, ending - start, start, -1, comparator, limit)
			end
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("runeofpowerremaining", false, RuneOfPowerRemaining)
	OvaleCondition:RegisterCondition("runeofpowerremains", false, RuneOfPowerRemaining)
end

do
	local RUNE_TYPE = OvaleRunes.RUNE_TYPE

	local runes = {
		blood = 0,
		unholy = 0,
		frost = 0,
		death = 0,
	}

	local function ParseRuneCondition(condition)
		for name in pairs(RUNE_TYPE) do
			runes[name] = 0
		end
		local k = 1
		while true do
			local name, count = condition[2*k - 1], condition[2*k]
			if not RUNE_TYPE[name] then break end
			runes[name] = runes[name] + count
			k = k + 1
		end
		return runes.blood, runes.unholy, runes.frost, runes.death
	end

	--- Test if the current active rune counts meets the minimum rune requirements set out in the parameters.
	-- This condition takes pairs of "type number" to mean that there must be a minimum of number runes of the named type.
	-- E.g., Runes(blood 1 frost 1 unholy 1) means at least one blood, one frost, and one unholy rune is available.
	-- @name Runes
	-- @paramsig boolean
	-- @param type The type of rune.
	--     Valid values: blood, frost, unholy, death
	-- @param number The number of runes
	-- @param ... Optional. Additional "type number" pairs for minimum rune requirements.
	-- @return A boolean value.
	-- @usage
	-- if Runes(frost 1) Spell(howling_blast)

	local function Runes(condition)
		local blood, unholy, frost, death = ParseRuneCondition(condition)
		local seconds = state:GetRunesCooldown(blood, unholy, frost, death)
		return state.currentTime + seconds, math.huge
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
	-- @param death Sets how death runes are used to fulfill the rune count requirements.
	--     If not set, then only death runes of the proper rune type are used.
	--     If set with "death=0", then no death runes are used.
	--     If set with "death=1", then death runes of any rune type are used.
	--     Default is unset.
	--     Valid values: unset, 0, 1
	-- @return The number of seconds.

	local function RunesCooldown(condition)
		local blood, unholy, frost, death = ParseRuneCondition(condition)
		local seconds = state:GetRunesCooldown(blood, unholy, frost, death)
		return 0, state.currentTime + seconds, seconds, state.currentTime, -1
	end

	OvaleCondition:RegisterCondition("runes", false, Runes)
	OvaleCondition:RegisterCondition("runescooldown", false, RunesCooldown)
end

do
	-- Returns the value of the given snapshot stat.
	local function Snapshot(statName, defaultValue, condition)
		local comparator, limit = condition[1], condition[2]
		local value = state.snapshot[statName] or defaultValue
		return Compare(value, comparator, limit)
	end

	-- Returns the critical strike chance of the given snapshot stat.
	local function SnapshotCritChance(statName, defaultValue, condition)
		local comparator, limit = condition[1], condition[2]
		local value = state.snapshot[statName] or defaultValue
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
		return Snapshot("agility", 0, condition)
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
		return Snapshot("attackPower", 0, condition)
	end

	--- Get the current critical strike rating of the player.
	-- @name CritRating
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current critical strike rating.
	-- @return A boolean value for the result of the comparison.

	local function CritRating(condition)
		return Snapshot("critRating", 0, condition)
	end

	--- Get the current haste rating of the player.
	-- @name HasteRating
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current haste rating.
	-- @return A boolean value for the result of the comparison.

	local function HasteRating(condition)
		return Snapshot("hasteRating", 0, condition)
	end

	--- Get the current intellect of the player.
	-- @name Intellect
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current intellect.
	-- @return A boolean value for the result of the comparison.

	local function Intellect(condition)
		return Snapshot("intellect", 0, condition)
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
		return Snapshot("masteryEffect", 0, condition)
	end

	--- Get the current mastery rating of the player.
	-- @name MasteryRating
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current mastery rating.
	-- @return A boolean value for the result of the comparison.

	local function MasteryRating(condition)
		return Snapshot("masteryRating", 0, condition)
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
		return SnapshotCritChance("meleeCrit", 0, condition)
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
		return SnapshotCritChance("rangedCrit", 0, condition)
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
		return SnapshotCritChance("spellCrit", 0, condition)
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
		return Snapshot("spellHaste", 0, condition)
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
		return Snapshot("spellBonusDamage", 0, condition)
	end

	--- Get the current spirit of the player.
	-- @name Spirit
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current spirit.
	-- @return A boolean value for the result of the comparison.

	local function Spirit(condition)
		return Snapshot("spirit", 0, condition)
	end

	--- Get the current stamina of the player.
	-- @name Stamina
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current stamina.
	-- @return A boolean value for the result of the comparison.

	local function Stamina(condition)
		return Snapshot("stamina", 0, condition)
	end

	--- Get the current strength of the player.
	-- @name Strength
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current strength.
	-- @return A boolean value for the result of the comparison.

	local function Strength(condition)
		return Snapshot("strength", 0, condition)
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

	local function Speed(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
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

	local function SpellChargeCooldown(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local charges, maxCharges, start, duration = state:GetSpellCharges(spellId)
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
	-- @return The number of charges.
	-- @return A boolean value for the result of the comparison.
	-- @see SpellChargeCooldown
	-- @usage
	-- if SpellCharges(savage_defense) >1
	--     Spell(savage_defense)

	local function SpellCharges(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local charges, maxCharges, start, duration = state:GetSpellCharges(spellId)
		charges = charges or 0
		return Compare(charges, comparator, limit)
	end

	OvaleCondition:RegisterCondition("charges", true, SpellCharges)
	OvaleCondition:RegisterCondition("spellcharges", true, SpellCharges)
end

do
	--- Get the cooldown in seconds before a spell is ready for use.
	-- @name SpellCooldown
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if ShadowOrbs() ==3 and SpellCooldown(mind_blast) <2
	--     Spell(devouring_plague)

	local function SpellCooldown(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local start, duration = state:GetSpellCooldown(spellId)
		if start > 0 and duration > 0 then
			return TestValue(start, start + duration, duration, start, -1, comparator, limit)
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
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.

	local function SpellCooldownDuration(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local start, duration = state:GetSpellCooldown(spellId)
		return Compare(duration, comparator, limit)
	end

	OvaleCondition:RegisterCondition("spellcooldownduration", true, SpellCooldownDuration)
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

	local function SpellData(condition)
		local spellId, key, comparator, limit = condition[1], condition[2], condition[3], condition[4]
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

	local function SpellKnown(condition)
		local spellId, yesno = condition[1], condition[2]
		local boolean = OvaleSpellBook:IsKnownSpell(spellId)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("spellknown", true, SpellKnown)
end

do
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

	local function SpellUsable(condition)
		local spellId, yesno = condition[1], condition[2]
		local boolean = OvaleSpellBook:IsUsableSpell(spellId)
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

	local function StaggerRemaining(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local aura = state:GetAura(target, HEAVY_STAGGER, "HARMFUL")
		if not state:IsActiveAura(aura) then
			aura = state:GetAura(target, MODERATE_STAGGER, "HARMFUL")
		end
		if not state:IsActiveAura(aura) then
			aura = state:GetAura(target, LIGHT_STAGGER, "HARMFUL")
		end
		if state:IsActiveAura(aura) then
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

	local function Stance(condition)
		local stance, yesno = condition[1], condition[2]
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

	local function Stealthed(condition)
		local yesno = condition[1]
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

	local function LastSwing(condition)
		local swing = condition[1]
		local comparator, limit
		local start
		if swing and swing == "main" or swing == "off" then
			comparator, limit = condition[2], condition[3]
			start = 0
		else
			comparator, limit = condition[1], condition[2]
			start = 0
		end
		Ovale:OneTimeMessage("Warning: 'LastSwing() is not implemented.")
		return TestValue(start, math.huge, 0, start, 1, comparator, limit)
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

	local function NextSwing(condition)
		local swing = condition[1]
		local comparator, limit
		local ending
		if swing and swing == "main" or swing == "off" then
			comparator, limit = condition[2], condition[3]
			ending = 0
		else
			comparator, limit = condition[1], condition[2]
			ending = 0
		end
		Ovale:OneTimeMessage("Warning: 'NextSwing() is not implemented.")
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
	-- @param yesno Optional. If yes, then return true if the glyph is active. If no, then return true if it isn't active.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if Talent(blood_tap_talent) Spell(blood_tap)

	local function Talent(condition)
		local talentId, yesno = condition[1], condition[2]
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

	local function TalentPoints(condition)
		local talent, comparator, limit = condition[1], condition[2], condition[3]
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

	local function TargetIsPlayer(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
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

	local function Threat(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition, "target")
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
	-- @see NextTick, Ticks, TicksRemaining

	local function TickTime(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		local tickTime
		if state:IsActiveAura(aura) then
			tickTime = aura.tick
		else
			local _, _, tick = state:GetDuration(auraId)
			tickTime = tick
		end
		if tickTime and tickTime > 0 then
			return Compare(tickTime, comparator, limit)
		end
		return Compare(math.huge, comparator, limit)
	end

	OvaleCondition:RegisterCondition("ticktime", false, TickTime)
end

do
	--- Get the total number of ticks of a periodic aura.
	-- @name Ticks
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of ticks.
	-- @return A boolean value for the result of the comparison.
	-- @see NextTick, TicksRemaining, TickTime

	local function Ticks(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		local numTicks
		if state:IsActiveAura(aura) then
			local gain, start, ending, tick = aura.gain, aura.start, aura.ending, aura.tick
			if tick and tick > 0 then
				numTicks = floor((ending - start) / tick + 0.5)
			end
		else
			local _, _, _, _numTicks = state:GetDuration(auraId)
			numTicks = _numTicks
		end
		if numTicks then
			return Compare(numTicks, comparator, limit)
		end
		return Compare(math.huge, comparator, limit)
	end

	OvaleCondition:RegisterCondition("ticks", false, Ticks)
end

do
	--- Get the number of ticks that would be added if the dot were cast with a current snapshot.
	-- @name TicksAdded
	-- @paramsig number or boolean
	-- @param id The aura spell ID
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of added ticks.
	-- @return A boolean value for the result of the comparison.

	local function TicksAdded(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local _, _, _, numTicks = state:GetDuration(auraId)
		if numTicks and numTicks > 0 then
			return Compare(numTicks, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("ticksadded", false, TicksAdded)
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
	-- @see NextTick, Ticks, TickTime
	-- @usage
	-- if target.TicksRemaining(shadow_word_pain) <2
	--     Spell(shadow_word_pain)

	local function TicksRemaining(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain, start, ending, tick = aura.gain, aura.start, aura.ending, aura.tick
			if tick and tick > 0 then
				return TestValue(gain, math.huge, 1, ending, -1/tick, comparator, limit)
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

	local function TimeInCombat(condition)
		local comparator, limit = condition[1], condition[2]
		if Ovale.enCombat then
			local start = Ovale.combatStartTime
			return TestValue(start, math.huge, 0, start, 1, comparator, limit)
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

	local function TimeSincePreviousSpell(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local t = state:TimeOfLastCast(spellId)
		return TestValue(0, math.huge, t, 0, 1, comparator, limit)
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

	local function TimeToBloodlust(condition)
		local comparator, limit = condition[1], condition[2], condition[3]
		local value = 3600
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timetobloodlust", false, TimeToBloodlust)
end

do
	--- Get the number of seconds before the player reaches maximum power.
	local function TimeToMax(powerType, condition)
		local comparator, limit = condition[1], condition[2]
		local maxPower = OvalePower.maxPower[powerType] or 0
		local power = state[powerType] or 0
		local powerRegen = state.powerRate[powerType] or 1
		local t = (maxPower - power) / powerRegen
		if t > 0 then
			return TestValue(0, state.currentTime + t, t, state.currentTime, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	--- Get the number of seconds before the player reaches maximum energy for feral druids, non-mistweaver monks and rogues.
	-- @name TimeToMaxEnergy
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @see TimeToEnergyFor
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if TimeToMaxEnergy() < 1.2 Spell(sinister_strike)

	local function TimeToMaxEnergy(condition)
		return TimeToMax("energy", condition)
	end

	--- Get the number of seconds before the player reaches maximum focus for hunters.
	-- @name TimeToMaxFocus
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @see TimeToEnergyFor
	-- @return A boolean value for the result of the comparison.

	local function TimeToMaxFocus(condition)
		return TimeToMax("focus", condition)
	end

	OvaleCondition:RegisterCondition("timetomaxenergy", false, TimeToMaxEnergy)
	OvaleCondition:RegisterCondition("timetomaxfocus", false, TimeToMaxFocus)
end

do
	local function TimeToPower(powerType, condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		if not powerType then
			local _, _, _, _, _, powerToken = API_GetSpellInfo(spellId)
			powerType = OvalePower.POWER_TYPE[powerToken]
		end
		local seconds = state:TimeToPower(spellId, powerType)

		if seconds == 0 then
			return Compare(0, comparator, limit)
		elseif seconds < math.huge then
			return TestValue(0, state.currentTime + seconds, seconds, state.currentTime, -1, comparator, limit)
		else -- if seconds == math.huge then
			return Compare(math.huge, comparator, limit)
		end
	end

	--- Get the number of seconds before the player has enough energy to cast the given spell.
	-- @name TimeToEnergyFor
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see TimeToEnergyFor, TimeToMaxEnergy

	local function TimeToEnergyFor(condition)
		return TimeToPower("energy", condition)
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

	local function TimeToFocusFor(condition)
		return TimeToPower("focus", condition)
	end

	OvaleCondition:RegisterCondition("timetoenergyfor", true, TimeToEnergyFor)
	OvaleCondition:RegisterCondition("timetofocusfor", true, TimeToFocusFor)
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

	local function TimeWithHaste(condition)
		local seconds, comparator, limit = condition[1], condition[2], condition[3]
		local haste = condition.haste or "spell"
		local value = GetHastedTime(seconds, haste)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timewithhaste", false, TimeWithHaste)
end

do
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
	-- @see TotemPresent, TotemRemaining
	-- @usage
	-- if TotemExpires(fire) Spell(searing_totem)
	-- if TotemPresent(water totem=healing_stream_totem) and TotemExpires(water 3) Spell(totemic_recall)

	local function TotemExpires(condition)
		local totemId, seconds = condition[1], condition[2]
		seconds = seconds or 0
		if type(totemId) ~= "number" then
			totemId = OVALE_TOTEMTYPE[totemId]
		end
		local haveTotem, name, startTime, duration = API_GetTotemInfo(totemId)
		if haveTotem and startTime and (not condition.totem or OvaleSpellBook:GetSpellName(condition.totem) == name) then
			return startTime + duration - seconds, math.huge
		end
		return 0, math.huge
	end

	--- Test if the totem for shamans, the ghoul for death knights, or the statue for monks is present.
	-- @name TotemPresent
	-- @paramsig boolean
	-- @param id The totem ID of the totem, ghoul or statue, or the type of totem.
	--     Valid types: fire, water, air, earth, ghoul, statue.
	-- @param totem Optional. Sets the specific totem to check of given totem ID type.
	--     Valid values: any totem spell ID
	-- @return A boolean value.
	-- @see TotemExpires, TotemRemaining
	-- @usage
	-- if not TotemPresent(fire) Spell(searing_totem)
	-- if TotemPresent(water totem=healing_stream_totem) and TotemExpires(water 3) Spell(totemic_recall)

	local function TotemPresent(condition)
		local totemId = condition[1]
		if type(totemId) ~= "number" then
			totemId = OVALE_TOTEMTYPE[totemId]
		end
		local haveTotem, name, startTime, duration = API_GetTotemInfo(totemId)
		if haveTotem and startTime and (not condition.totem or OvaleSpellBook:GetSpellName(condition.totem) == name) then
			return startTime, startTime + duration
		end
		return nil
	end

	OvaleCondition:RegisterCondition("totemexpires", false, TotemExpires)
	OvaleCondition:RegisterCondition("totempresent", false, TotemPresent)

	--- Get the remaining time in seconds before a totem expires.
	-- @name TotemRemaining
	-- @paramsig number or boolean
	-- @param id The totem ID of the totem, ghoul or statue, or the type of totem.
	--     Valid types: fire, water, air, earth, ghoul, statue.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param totem Optional. Sets the specific totem to check of given totem ID type.
	--     Valid values: any totem spell ID
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see TotemExpires, TotemPresent
	-- @usage
	-- if TotemRemaining(water totem=healing_stream_totem) <2 Spell(totemic_recall)

	local function TotemRemaining(condition)
		local totemId = condition[1]
		if type(totemId) ~= "number" then
			totemId = OVALE_TOTEMTYPE[totemId]
		end
		local haveTotem, name, startTime, duration = API_GetTotemInfo(totemId)
		if haveTotem and startTime and (not condition.totem or OvaleSpellBook:GetSpellName(condition.totem) == name) then
			local start, ending = startTime, startTime + duration
			return TestValue(start, ending, duration, start, -1, comparator, limit)
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

	local function Tracking(condition)
		local spellId, yesno = condition[1], condition[2]
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
	--- A condition that always returns true.
	-- @name True
	-- @paramsig boolean
	-- @return A boolean value.

	local function True(condition)
		return 0, math.huge
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

	local function WeaponDamage(condition)
		local hand = condition[1]
		local comparator, limit
		local value = 0
		if hand == "offhand" or hand == "off" then
			comparator, limit = condition[2], condition[3]
			value = state.snapshot.offHandWeaponDamage
		elseif hand == "mainhand" or hand == "main" then
			comparator, limit = condition[2], condition[3]
			value = state.snapshot.mainHandWeaponDamage
		else
			comparator, limit = condition[1], condition[2]
			value = state.snapshot.mainHandWeaponDamage
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

	local function WeaponEnchantExpires(condition)
		local hand, seconds = condition[1], condition[2]
		seconds = seconds or 0
		local hasMainHandEnchant, mainHandExpiration, _, hasOffHandEnchant, offHandExpiration = API_GetWeaponEnchantInfo()
		local now = API_GetTime()
		if hand == "mainhand" or hand == "main" then
			if hasMainHandEnchant then
				mainHandExpiration = mainHandExpiration / 1000
				return now + mainHandExpiration - seconds, math.huge
			end
		elseif hand == "offhand" or hand == "off" then
			if hasOffHandEnchant then
				offHandExpiration = offHandExpiration / 1000
				return now + offHandExpiration - seconds, math.huge
			end
		end
		return 0, math.huge
	end

	OvaleCondition:RegisterCondition("weaponenchantexpires", false, WeaponEnchantExpires)
end

do
	--- Get the number of active Wild Mushrooms by the player.
	-- @name WildMushroomCount
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of Wild Mushrooms.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if WildMushroomCount() < 3 Spell(wild_mushroom_caster)

	local function WildMushroomCount(condition)
		local comparator, limit = condition[1], condition[2]
		local count = 0
		for slot = 1, 3 do
			local haveTotem = API_GetTotemInfo(slot)
			if haveTotem then
				count = count + 1
			end
		end
		return Compare(count, comparator, limit)
	end

	OvaleCondition:RegisterCondition("wildmushroomcount", false, WildMushroomCount)
end

do
	local WILD_MUSHROOM_BLOOM = 102791

	--- Test if the player's Wild Mushroom is fully charged for maximum healing.
	-- @name WildMushroomIsCharged
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the player's Wild Mushroom is fully charged. If no, then return true if it isn't fully charged.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if WildMushroomIsCharged() Spell(wild_mushroom_bloom)

	local function WildMushroomIsCharged(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
		local boolean = API_IsSpellOverlayed(WILD_MUSHROOM_BLOOM)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("wildmushroomischarged", false, WildMushroomIsCharged)
end
