local LibBabbleCreatureType = LibStub:GetLibrary("LibBabble-CreatureType-3.0", true)
local LibRangeCheck = LibStub:GetLibrary("LibRangeCheck-2.0", true)
local __BestAction = LibStub:GetLibrary("ovale/BestAction")
local OvaleBestAction = __BestAction.OvaleBestAction
local __Compile = LibStub:GetLibrary("ovale/Compile")
local OvaleCompile = __Compile.OvaleCompile
local __Condition = LibStub:GetLibrary("ovale/Condition")
local OvaleCondition = __Condition.OvaleCondition
local TestValue = __Condition.TestValue
local Compare = __Condition.Compare
local TestBoolean = __Condition.TestBoolean
local ParseCondition = __Condition.ParseCondition
local isComparator = __Condition.isComparator
local __DamageTaken = LibStub:GetLibrary("ovale/DamageTaken")
local OvaleDamageTaken = __DamageTaken.OvaleDamageTaken
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
local __Equipment = LibStub:GetLibrary("ovale/Equipment")
local OvaleEquipment = __Equipment.OvaleEquipment
local __Future = LibStub:GetLibrary("ovale/Future")
local OvaleFuture = __Future.OvaleFuture
local __GUID = LibStub:GetLibrary("ovale/GUID")
local OvaleGUID = __GUID.OvaleGUID
local __Health = LibStub:GetLibrary("ovale/Health")
local OvaleHealth = __Health.OvaleHealth
local __Power = LibStub:GetLibrary("ovale/Power")
local OvalePower = __Power.OvalePower
local __Runes = LibStub:GetLibrary("ovale/Runes")
local OvaleRunes = __Runes.OvaleRunes
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local __SpellDamage = LibStub:GetLibrary("ovale/SpellDamage")
local OvaleSpellDamage = __SpellDamage.OvaleSpellDamage
local __Artifact = LibStub:GetLibrary("ovale/Artifact")
local OvaleArtifact = __Artifact.OvaleArtifact
local __BossMod = LibStub:GetLibrary("ovale/BossMod")
local OvaleBossMod = __BossMod.OvaleBossMod
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local __Enemies = LibStub:GetLibrary("ovale/Enemies")
local OvaleEnemies = __Enemies.OvaleEnemies
local __Totem = LibStub:GetLibrary("ovale/Totem")
local OvaleTotem = __Totem.OvaleTotem
local __DemonHunterSoulFragments = LibStub:GetLibrary("ovale/DemonHunterSoulFragments")
local OvaleDemonHunterSoulFragments = __DemonHunterSoulFragments.OvaleDemonHunterSoulFragments
local __Frame = LibStub:GetLibrary("ovale/Frame")
local OvaleFrameModule = __Frame.OvaleFrameModule
local __LastSpell = LibStub:GetLibrary("ovale/LastSpell")
local lastSpell = __LastSpell.lastSpell
local ipairs = ipairs
local pairs = pairs
local type = type
local GetBuildInfo = GetBuildInfo
local GetItemCooldown = GetItemCooldown
local GetItemCount = GetItemCount
local GetNumTrackingTypes = GetNumTrackingTypes
local GetTime = GetTime
local GetTrackingInfo = GetTrackingInfo
local GetUnitSpeed = GetUnitSpeed
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local HasFullControl = HasFullControl
local IsStealthed = IsStealthed
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitClassification = UnitClassification
local UnitCreatureFamily = UnitCreatureFamily
local UnitCreatureType = UnitCreatureType
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitExists = UnitExists
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitIsDead = UnitIsDead
local UnitIsFriend = UnitIsFriend
local UnitIsPVP = UnitIsPVP
local UnitIsUnit = UnitIsUnit
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitRace = UnitRace
local UnitStagger = UnitStagger
local huge = math.huge
local __AST = LibStub:GetLibrary("ovale/AST")
local isValueNode = __AST.isValueNode
local __Cooldown = LibStub:GetLibrary("ovale/Cooldown")
local OvaleCooldown = __Cooldown.OvaleCooldown
local __Variables = LibStub:GetLibrary("ovale/Variables")
local variables = __Variables.variables
local __Stance = LibStub:GetLibrary("ovale/Stance")
local OvaleStance = __Stance.OvaleStance
local __DemonHunterSigils = LibStub:GetLibrary("ovale/DemonHunterSigils")
local OvaleSigil = __DemonHunterSigils.OvaleSigil
local __BaseState = LibStub:GetLibrary("ovale/BaseState")
local baseState = __BaseState.baseState
local __Spells = LibStub:GetLibrary("ovale/Spells")
local OvaleSpells = __Spells.OvaleSpells
local __AzeriteArmor = LibStub:GetLibrary("ovale/AzeriteArmor")
local OvaleAzerite = __AzeriteArmor.OvaleAzerite
local __Warlock = LibStub:GetLibrary("ovale/Warlock")
local OvaleWarlock = __Warlock.OvaleWarlock
local __Stagger = LibStub:GetLibrary("ovale/Stagger")
local OvaleStagger = __Stagger.OvaleStagger
local __LossOfControl = LibStub:GetLibrary("ovale/LossOfControl")
local OvaleLossOfControl = __LossOfControl.OvaleLossOfControl
local INFINITY = huge
local function BossArmorDamageReduction(target)
    return 0.3
end
local function ComputeParameter(spellId, paramName, atTime)
    local si = OvaleData:GetSpellInfo(spellId)
    if si and si[paramName] then
        local name = si[paramName]
        local node = OvaleCompile:GetFunctionNode(name)
        if node then
            local _, element = OvaleBestAction:Compute(node.child[1], atTime)
            if element and isValueNode(element) then
                local value = element.value + (atTime - element.origin) * element.rate
                return value
            end
        else
            return si[paramName]
        end
    end
    return nil
end
local function GetHastedTime(seconds, haste)
    seconds = seconds or 0
    local multiplier = OvalePaperDoll:GetHasteMultiplier(haste, OvalePaperDoll.next)
    return seconds / multiplier
end
do
local function ArmorSetBonus(positionalParams, namedParams, atTime)
        Ovale:OneTimeMessage("Warning: 'ArmorSetBonus()' is depreciated.  Returns 0")
        local value = 0
        return 0, INFINITY, value, 0, 0
    end
    OvaleCondition:RegisterCondition("armorsetbonus", false, ArmorSetBonus)
end
do
local function ArmorSetParts(positionalParams, namedParams, atTime)
        local _, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = 0
        Ovale:OneTimeMessage("Warning: 'ArmorSetBonus()' is depreciated.  Returns 0")
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("armorsetparts", false, ArmorSetParts)
end
do
local function ArtifactTraitRank(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = OvaleArtifact:TraitRank(spellId)
        return Compare(value, comparator, limit)
    end
local function HasArtifactTrait(positionalParams, namedParams, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local value = OvaleArtifact:HasTrait(spellId)
        return TestBoolean(value, yesno)
    end
    OvaleCondition:RegisterCondition("hasartifacttrait", false, HasArtifactTrait)
    OvaleCondition:RegisterCondition("artifacttraitrank", false, ArtifactTraitRank)
end
do
local function AzeriteTraitRank(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = OvaleAzerite:TraitRank(spellId)
        return Compare(value, comparator, limit)
    end
local function HasAzeriteTrait(positionalParams, namedParams, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local value = OvaleAzerite:HasTrait(spellId)
        return TestBoolean(value, yesno)
    end
    OvaleCondition:RegisterCondition("hasazeritetrait", false, HasAzeriteTrait)
    OvaleCondition:RegisterCondition("azeritetraitrank", false, AzeriteTraitRank)
end
do
local function BaseDuration(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value
        if (OvaleData.buffSpellList[auraId]) then
            local spellList = OvaleData.buffSpellList[auraId]
            for id in pairs(spellList) do
                value = OvaleAura:GetBaseDuration(id, OvalePaperDoll.next)
                if value ~= huge then
                    break
                end
            end
        else
            value = OvaleAura:GetBaseDuration(auraId, OvalePaperDoll.next)
        end
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("baseduration", false, BaseDuration)
    OvaleCondition:RegisterCondition("buffdurationifapplied", false, BaseDuration)
    OvaleCondition:RegisterCondition("debuffdurationifapplied", false, BaseDuration)
end
do
local function BuffAmount(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local value = namedParams.value or 1
        local statName = "value1"
        if value == 1 then
            statName = "value1"
        elseif value == 2 then
            statName = "value2"
        elseif value == 3 then
            statName = "value3"
        end
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        if OvaleAura:IsActiveAura(aura, atTime) then
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
local function BuffComboPoints(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        if OvaleAura:IsActiveAura(aura, atTime) then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            local value = aura and aura.combopoints or 0
            return TestValue(gain, ending, value, start, 0, comparator, limit)
        end
        return Compare(0, comparator, limit)
    end
    OvaleCondition:RegisterCondition("buffcombopoints", false, BuffComboPoints)
    OvaleCondition:RegisterCondition("debuffcombopoints", false, BuffComboPoints)
end
do
local function BuffCooldown(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
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
local function BuffCount(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local spellList = OvaleData.buffSpellList[auraId]
        local count = 0
        for id in pairs(spellList) do
            local aura = OvaleAura:GetAura(target, id, atTime, filter, mine)
            if OvaleAura:IsActiveAura(aura, atTime) then
                count = count + 1
            end
        end
        return Compare(count, comparator, limit)
    end
    OvaleCondition:RegisterCondition("buffcount", false, BuffCount)
end
do
local function BuffCooldownDuration(positionalParams, namedParams, atTime)
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
local function BuffCountOnAny(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local _, filter, mine = ParseCondition(positionalParams, namedParams)
        local excludeUnitId = (namedParams.excludeTarget == 1) and baseState.next.defaultTarget or nil
        local fractional = (namedParams.count == 0) and true or false
        local count, _, startChangeCount, endingChangeCount, startFirst, endingLast = OvaleAura:AuraCount(auraId, filter, mine, namedParams.stacks, atTime, excludeUnitId)
        if count > 0 and startChangeCount < INFINITY and fractional then
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
local function BuffDirection(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        if aura then
            local gain, _, _, direction = aura.gain, aura.start, aura.ending, aura.direction
            return TestValue(gain, INFINITY, direction, gain, 0, comparator, limit)
        end
        return Compare(0, comparator, limit)
    end
    OvaleCondition:RegisterCondition("buffdirection", false, BuffDirection)
    OvaleCondition:RegisterCondition("debuffdirection", false, BuffDirection)
end
do
local function BuffDuration(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        if OvaleAura:IsActiveAura(aura, atTime) then
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
local function BuffExpires(positionalParams, namedParams, atTime)
        local auraId, seconds = positionalParams[1], positionalParams[2]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        if aura then
            local gain, _, ending = aura.gain, aura.start, aura.ending
            seconds = GetHastedTime(seconds, namedParams.haste)
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
local function BuffPresent(positionalParams, namedParams, atTime)
        local auraId, seconds = positionalParams[1], positionalParams[2]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        if aura then
            local gain, _, ending = aura.gain, aura.start, aura.ending
            seconds = GetHastedTime(seconds, namedParams.haste)
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
local function BuffGain(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
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
local function BuffImproved(positionalParams, namedParams, atTime)
        local _, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local _, _ = ParseCondition(positionalParams, namedParams)
        return Compare(0, comparator, limit)
    end
    OvaleCondition:RegisterCondition("buffimproved", false, BuffImproved)
    OvaleCondition:RegisterCondition("debuffimproved", false, BuffImproved)
end
do
local function BuffPersistentMultiplier(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        if OvaleAura:IsActiveAura(aura, atTime) then
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
local function BuffRemaining(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        if aura and aura.ending >= atTime then
            local gain, _, ending = aura.gain, aura.start, aura.ending
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
local function BuffRemainingOnAny(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local _, filter, mine = ParseCondition(positionalParams, namedParams)
        local excludeUnitId = (namedParams.excludeTarget == 1) and baseState.next.defaultTarget or nil
        local count, _, _, _, startFirst, endingLast = OvaleAura:AuraCount(auraId, filter, mine, namedParams.stacks, atTime, excludeUnitId)
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
local function BuffStacks(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        if OvaleAura:IsActiveAura(aura, atTime) then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            local value = aura.stacks or 0
            return TestValue(gain, ending, value, start, 0, comparator, limit)
        end
        return Compare(0, comparator, limit)
    end
    OvaleCondition:RegisterCondition("buffstacks", false, BuffStacks)
    OvaleCondition:RegisterCondition("debuffstacks", false, BuffStacks)
local function maxStacks(positionalParams, namedParameters, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local maxStacks = OvaleData:GetSpellInfo(auraId).max_stacks
        return Compare(maxStacks, comparator, limit)
    end
    OvaleCondition:RegisterCondition("maxstacks", true, maxStacks)
end
do
local function BuffStacksOnAny(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local _, filter, mine = ParseCondition(positionalParams, namedParams)
        local excludeUnitId = (namedParams.excludeTarget == 1) and baseState.next.defaultTarget or nil
        local count, stacks, _, endingChangeCount, startFirst = OvaleAura:AuraCount(auraId, filter, mine, 1, atTime, excludeUnitId)
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
local function BuffStealable(positionalParams, namedParams, atTime)
        local target = ParseCondition(positionalParams, namedParams)
        return OvaleAura:GetAuraWithProperty(target, "stealable", "HELPFUL", atTime)
    end
    OvaleCondition:RegisterCondition("buffstealable", false, BuffStealable)
end
do
local function CanCast(positionalParams, namedParams, atTime)
        local spellId = positionalParams[1]
        local start, duration = OvaleCooldown:GetSpellCooldown(spellId, atTime)
        return start + duration, INFINITY
    end
    OvaleCondition:RegisterCondition("cancast", true, CanCast)
end
do
local function CastTime(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local castTime = OvaleSpellBook:GetCastTime(spellId) or 0
        return Compare(castTime, comparator, limit)
    end
local function ExecuteTime(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local castTime = OvaleSpellBook:GetCastTime(spellId) or 0
        local gcd = OvaleFuture:GetGCD()
        local t = (castTime > gcd) and castTime or gcd
        return Compare(t, comparator, limit)
    end
    OvaleCondition:RegisterCondition("casttime", true, CastTime)
    OvaleCondition:RegisterCondition("executetime", true, ExecuteTime)
end
do
local function Casting(positionalParams, namedParams, atTime)
        local spellId = positionalParams[1]
        local target = ParseCondition(positionalParams, namedParams)
        local start, ending, castSpellId, castSpellName
        if target == "player" then
            start = OvaleFuture.next.currentCast.start
            ending = OvaleFuture.next.currentCast.stop
            castSpellId = OvaleFuture.next.currentCast.spellId
            castSpellName = OvaleSpellBook:GetSpellName(castSpellId)
        else
            local spellName, _1, _2, startTime, endTime = UnitCastingInfo(target)
            if  not spellName then
                spellName, _1, _2, startTime, endTime = UnitChannelInfo(target)
            end
            if spellName then
                castSpellName = spellName
                start = startTime / 1000
                ending = endTime / 1000
            end
        end
        if castSpellId or castSpellName then
            if  not spellId then
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
                Ovale:Print("%f %f %d %s => %d (%f)", start, ending, castSpellId, castSpellName, spellId, baseState.next.currentTime)
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
local function CheckBoxOff(positionalParams, namedParams, atTime)
        for _, id in ipairs(positionalParams) do
            if OvaleFrameModule.frame and OvaleFrameModule.frame:IsChecked(id) then
                return nil
            end
        end
        return 0, INFINITY
    end
local function CheckBoxOn(positionalParams, namedParams, atTime)
        for _, id in ipairs(positionalParams) do
            if OvaleFrameModule.frame and  not OvaleFrameModule.frame:IsChecked(id) then
                return nil
            end
        end
        return 0, INFINITY
    end
    OvaleCondition:RegisterCondition("checkboxoff", false, CheckBoxOff)
    OvaleCondition:RegisterCondition("checkboxon", false, CheckBoxOn)
end
do
local function Class(positionalParams, namedParams, atTime)
        local className, yesno = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local _, classToken = UnitClass(target)
        local boolean = (classToken == className)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("class", false, Class)
end
do
    local IMBUED_BUFF_ID = 214336
local function Classification(positionalParams, namedParams, atTime)
        local classification, yesno = positionalParams[1], positionalParams[2]
        local targetClassification
        local target = ParseCondition(positionalParams, namedParams)
        if UnitLevel(target) < 0 then
            targetClassification = "worldboss"
        elseif UnitExists("boss1") and OvaleGUID:UnitGUID(target) == OvaleGUID:UnitGUID("boss1") then
            targetClassification = "worldboss"
        else
            local aura = OvaleAura:GetAura(target, IMBUED_BUFF_ID, atTime, "HARMFUL", false)
            if OvaleAura:IsActiveAura(aura, atTime) then
                targetClassification = "worldboss"
            else
                targetClassification = UnitClassification(target)
                if targetClassification == "rareelite" then
                    targetClassification = "elite"
                elseif targetClassification == "rare" then
                    targetClassification = "normal"
                end
            end
        end
        local boolean = (targetClassification == classification)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("classification", false, Classification)
end
do
local function Counter(positionalParams, namedParams, atTime)
        local counter, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = OvaleFuture:GetCounter(counter, atTime)
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("counter", false, Counter)
end
do
local function CreatureFamily(positionalParams, namedParams, atTime)
        local name, yesno = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local family = UnitCreatureFamily(target)
        local lookupTable = LibBabbleCreatureType and LibBabbleCreatureType:GetLookupTable()
        local boolean = (lookupTable and family == lookupTable[name])
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("creaturefamily", false, CreatureFamily)
end
do
local function CreatureType(positionalParams, namedParams, atTime)
        local target = ParseCondition(positionalParams, namedParams)
        local creatureType = UnitCreatureType(target)
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
    local AMPLIFICATION = 146051
    local INCREASED_CRIT_EFFECT_3_PERCENT = 44797
local function CritDamage(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = ParseCondition(positionalParams, namedParams, "target")
        local value = ComputeParameter(spellId, "damage", atTime) or 0
        local si = OvaleData.spellInfo[spellId]
        if si and si.physical == 1 then
            value = value * (1 - BossArmorDamageReduction(target))
        end
        local critMultiplier = 2
        do
            local aura = OvaleAura:GetAura("player", AMPLIFICATION, atTime, "HELPFUL")
            if OvaleAura:IsActiveAura(aura, atTime) then
                critMultiplier = critMultiplier + aura.value1
            end
        end
        do
            local aura = OvaleAura:GetAura("player", INCREASED_CRIT_EFFECT_3_PERCENT, atTime, "HELPFUL")
            if OvaleAura:IsActiveAura(aura, atTime) then
                critMultiplier = critMultiplier * aura.value1
            end
        end
        value = critMultiplier * value
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("critdamage", false, CritDamage)
local function Damage(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = ParseCondition(positionalParams, namedParams, "target")
        local value = ComputeParameter(spellId, "damage", atTime) or 0
        local si = OvaleData.spellInfo[spellId]
        if si and si.physical == 1 then
            value = value * (1 - BossArmorDamageReduction(target))
        end
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("damage", false, Damage)
end
do
local function DamageTaken(positionalParams, namedParams, atTime)
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
local function Demons(positionalParams, namedParams, atTime)
        local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = OvaleWarlock:GetDemonsCount(creatureId, atTime)
        return Compare(value, comparator, limit)
    end
local function NotDeDemons(positionalParams, namedParams, atTime)
        local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = OvaleWarlock:GetNotDemonicEmpoweredDemonsCount(creatureId, atTime)
        return Compare(value, comparator, limit)
    end
local function DemonDuration(positionalParams, namedParams, atTime)
        local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = OvaleWarlock:GetRemainingDemonDuration(creatureId, atTime)
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
local function GetDiseases(target, atTime)
        local npAura, bpAura, ffAura
        local talented = (OvaleSpellBook:GetTalentPoints(NECROTIC_PLAGUE_TALENT) > 0)
        if talented then
            npAura = OvaleAura:GetAura(target, NECROTIC_PLAGUE_DEBUFF, atTime, "HARMFUL", true)
        else
            bpAura = OvaleAura:GetAura(target, BLOOD_PLAGUE_DEBUFF, atTime, "HARMFUL", true)
            ffAura = OvaleAura:GetAura(target, FROST_FEVER_DEBUFF, atTime, "HARMFUL", true)
        end
        return talented, npAura, bpAura, ffAura
    end
local function DiseasesRemaining(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, _ = ParseCondition(positionalParams, namedParams)
        local talented, npAura, bpAura, ffAura = GetDiseases(target, atTime)
        local aura
        if talented and OvaleAura:IsActiveAura(npAura, atTime) then
            aura = npAura
        elseif  not talented and OvaleAura:IsActiveAura(bpAura, atTime) and OvaleAura:IsActiveAura(ffAura, atTime) then
            aura = (bpAura.ending < ffAura.ending) and bpAura or ffAura
        end
        if aura then
            local gain, _, ending = aura.gain, aura.start, aura.ending
            return TestValue(gain, INFINITY, 0, ending, -1, comparator, limit)
        end
        return Compare(0, comparator, limit)
    end
local function DiseasesTicking(positionalParams, namedParams, atTime)
        local target, _ = ParseCondition(positionalParams, namedParams)
        local talented, npAura, bpAura, ffAura = GetDiseases(target, atTime)
        local gain, start, ending
        if talented and npAura then
            gain, start, ending = npAura.gain, npAura.start, npAura.ending
        elseif  not talented and bpAura and ffAura then
            gain = (bpAura.gain > ffAura.gain) and bpAura.gain or ffAura.gain
            start = (bpAura.start > ffAura.start) and bpAura.start or ffAura.start
            ending = (bpAura.ending < ffAura.ending) and bpAura.ending or ffAura.ending
        end
        if gain and ending and ending > gain then
            return gain, ending
        end
        return nil
    end
local function DiseasesAnyTicking(positionalParams, namedParams, atTime)
        local target, _ = ParseCondition(positionalParams, namedParams)
        local talented, npAura, bpAura, ffAura = GetDiseases(target, atTime)
        local aura
        if talented and npAura then
            aura = npAura
        elseif  not talented and (bpAura or ffAura) then
            aura = bpAura or ffAura
            if bpAura and ffAura then
                aura = (bpAura.ending > ffAura.ending) and bpAura or ffAura
            end
        end
        if aura then
            local gain, _, ending = aura.gain, aura.start, aura.ending
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
local function Distance(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local value = LibRangeCheck and LibRangeCheck:GetRange(target) or 0
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("distance", false, Distance)
end
do
local function Enemies(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = OvaleEnemies.next.enemies
        if  not value then
            local useTagged = Ovale.db.profile.apparence.taggedEnemies
            if namedParams.tagged == 0 then
                useTagged = false
            elseif namedParams.tagged == 1 then
                useTagged = true
            end
            value = useTagged and OvaleEnemies.next.taggedEnemies or OvaleEnemies.next.activeEnemies
        end
        if value < 1 then
            value = 1
        end
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("enemies", false, Enemies)
end
do
local function EnergyRegenRate(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = OvalePower.next:GetPowerRate("energy")
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("energyregen", false, EnergyRegenRate)
    OvaleCondition:RegisterCondition("energyregenrate", false, EnergyRegenRate)
end
do
local function EnrageRemaining(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local start, ending = OvaleAura:GetAuraWithProperty(target, "enrage", "HELPFUL", atTime)
        if start and ending then
            return TestValue(start, INFINITY, 0, ending, -1, comparator, limit)
        end
        return Compare(0, comparator, limit)
    end
    OvaleCondition:RegisterCondition("enrageremaining", false, EnrageRemaining)
end
do
local function Exists(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local target = ParseCondition(positionalParams, namedParams)
        local boolean = UnitExists(target)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("exists", false, Exists)
end
do
    local False = function(positionalParams, namedParams, atTime)
        return nil
    end
    OvaleCondition:RegisterCondition("false", false, False)
end
do
local function FocusRegenRate(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = OvalePower.next:GetPowerRate("focus")
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("focusregen", false, FocusRegenRate)
    OvaleCondition:RegisterCondition("focusregenrate", false, FocusRegenRate)
end
do
    local STEADY_FOCUS = 177668
local function FocusCastingRegen(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local regenRate = OvalePower.next:GetPowerRate("focus")
        local power = 0
        local castTime = OvaleSpellBook:GetCastTime(spellId) or 0
        local gcd = OvaleFuture:GetGCD()
        local castSeconds = (castTime > gcd) and castTime or gcd
        power = power + regenRate * castSeconds
        local aura = OvaleAura:GetAura("player", STEADY_FOCUS, atTime, "HELPFUL", true)
        if aura then
            local seconds = aura.ending - atTime
            if seconds <= 0 then
                seconds = 0
            elseif seconds > castSeconds then
                seconds = castSeconds
            end
            power = power + regenRate * 1.5 * seconds
        end
        return Compare(power, comparator, limit)
    end
    OvaleCondition:RegisterCondition("focuscastingregen", false, FocusCastingRegen)
end
do
local function GCD(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = OvaleFuture:GetGCD()
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("gcd", false, GCD)
end
do
local function GCDRemaining(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams, "target")
        if OvaleFuture.next.lastGCDSpellId then
            local duration = OvaleFuture:GetGCD(OvaleFuture.next.lastGCDSpellId, atTime, OvaleGUID:UnitGUID(target))
            local spellcast = lastSpell:LastInFlightSpell()
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
local function GetState(positionalParams, namedParams, atTime)
        local name, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = variables:GetState(name)
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("getstate", false, GetState)
end
do
local function GetStateDuration(positionalParams, namedParams, atTime)
        local name, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = variables:GetStateDuration(name)
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("getstateduration", false, GetStateDuration)
end
do
local function Glyph(positionalParams, namedParams, atTime)
        local _, yesno = positionalParams[1], positionalParams[2]
        return TestBoolean(false, yesno)
    end
    OvaleCondition:RegisterCondition("glyph", false, Glyph)
end
do
local function HasEquippedItem(positionalParams, namedParams, atTime)
        local itemId, yesno = positionalParams[1], positionalParams[2]
        local boolean = false
        local slotId
        if type(itemId) == "number" then
            slotId = OvaleEquipment:HasEquippedItem(itemId)
            if slotId then
                boolean = true
            end
        elseif OvaleData.itemList[itemId] then
            for _, v in pairs(OvaleData.itemList[itemId]) do
                slotId = OvaleEquipment:HasEquippedItem(v)
                if slotId then
                    boolean = true
                    break
                end
            end
        end
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("hasequippeditem", false, HasEquippedItem)
end
do
local function HasFullControlCondition(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local boolean = HasFullControl()
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("hasfullcontrol", false, HasFullControlCondition)
end
do
local function HasShield(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local boolean = OvaleEquipment:HasShield()
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("hasshield", false, HasShield)
end
do
local function HasTrinket(positionalParams, namedParams, atTime)
        local trinketId, yesno = positionalParams[1], positionalParams[2]
        local boolean = nil
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
        return TestBoolean(boolean ~= nil, yesno)
    end
    OvaleCondition:RegisterCondition("hastrinket", false, HasTrinket)
end
do
local function Health(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local health = OvaleHealth:UnitHealth(target) or 0
        if health > 0 then
            local now = GetTime()
            local timeToDie = OvaleHealth:UnitTimeToDie(target)
            local value, origin, rate = health, now, -1 * health / timeToDie
            local start, ending = now, INFINITY
            return TestValue(start, ending, value, origin, rate, comparator, limit)
        end
        return Compare(0, comparator, limit)
    end
    OvaleCondition:RegisterCondition("health", false, Health)
    OvaleCondition:RegisterCondition("life", false, Health)
local function HealthMissing(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local health = OvaleHealth:UnitHealth(target) or 0
        local maxHealth = OvaleHealth:UnitHealthMax(target) or 1
        if health > 0 then
            local now = GetTime()
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
local function HealthPercent(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local health = OvaleHealth:UnitHealth(target) or 0
        if health > 0 then
            local now = GetTime()
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
local function MaxHealth(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local value = OvaleHealth:UnitHealthMax(target)
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("maxhealth", false, MaxHealth)
local function TimeToDie(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local now = GetTime()
        local timeToDie = OvaleHealth:UnitTimeToDie(target)
        local value, origin, rate = timeToDie, now, -1
        local start = now, now + timeToDie
        return TestValue(start, INFINITY, value, origin, rate, comparator, limit)
    end
    OvaleCondition:RegisterCondition("deadin", false, TimeToDie)
    OvaleCondition:RegisterCondition("timetodie", false, TimeToDie)
local function TimeToHealthPercent(positionalParams, namedParams, atTime)
        local percent, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = ParseCondition(positionalParams, namedParams)
        local health = OvaleHealth:UnitHealth(target) or 0
        if health > 0 then
            local maxHealth = OvaleHealth:UnitHealthMax(target) or 1
            local healthPercent = health / maxHealth * 100
            if healthPercent >= percent then
                local now = GetTime()
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
local function InCombat(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local boolean = baseState.next.inCombat
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("incombat", false, InCombat)
end
do
local function InFlightToTarget(positionalParams, namedParams, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local boolean = (OvaleFuture.next.currentCast.spellId == spellId) or OvaleFuture:InFlight(spellId)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("inflighttotarget", false, InFlightToTarget)
end
do
local function InRange(positionalParams, namedParams, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local boolean = OvaleSpells:IsSpellInRange(spellId, target)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("inrange", false, InRange)
end
do
local function IsAggroed(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local target = ParseCondition(positionalParams, namedParams)
        local boolean = UnitDetailedThreatSituation("player", target)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("isaggroed", false, IsAggroed)
end
do
local function IsDead(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local target = ParseCondition(positionalParams, namedParams)
        local boolean = UnitIsDead(target)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("isdead", false, IsDead)
end
do
local function IsEnraged(positionalParams, namedParams, atTime)
        local target = ParseCondition(positionalParams, namedParams)
        return OvaleAura:GetAuraWithProperty(target, "enrage", "HELPFUL", atTime)
    end
    OvaleCondition:RegisterCondition("isenraged", false, IsEnraged)
end
do
local function IsFeared(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local boolean =  not HasFullControl() and OvaleLossOfControl.HasLossOfControl("FEAR", atTime)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("isfeared", false, IsFeared)
end
do
local function IsFriend(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local target = ParseCondition(positionalParams, namedParams)
        local boolean = UnitIsFriend("player", target)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("isfriend", false, IsFriend)
end
do
local function IsIncapacitated(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local boolean =  not HasFullControl() and OvaleLossOfControl.HasLossOfControl("CONFUSE", atTime)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("isincapacitated", false, IsIncapacitated)
end
do
local function IsInterruptible(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local target = ParseCondition(positionalParams, namedParams)
        local name, _1, _2, _3, _4, _5, _, notInterruptible = UnitCastingInfo(target)
        if  not name then
            name, _1, _2, _3, _4, _5, notInterruptible = UnitChannelInfo(target)
        end
        local boolean = notInterruptible ~= nil and  not notInterruptible
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("isinterruptible", false, IsInterruptible)
end
do
local function IsPVP(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local target = ParseCondition(positionalParams, namedParams)
        local boolean = UnitIsPVP(target)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("ispvp", false, IsPVP)
end
do
local function IsRooted(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local boolean = OvaleLossOfControl.HasLossOfControl("ROOT", atTime)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("isrooted", false, IsRooted)
end
do
local function IsStunned(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local boolean =  not HasFullControl() and OvaleLossOfControl.HasLossOfControl("STUN_MECHANIC", atTime)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("isstunned", false, IsStunned)
end
do
local function ItemCharges(positionalParams, namedParams, atTime)
        local itemId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = GetItemCount(itemId, false, true)
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("itemcharges", false, ItemCharges)
end
do
local function ItemCooldown(positionalParams, namedParams, atTime)
        local itemId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        if itemId and type(itemId) ~= "number" then
            itemId = OvaleEquipment:GetEquippedItemBySlotName(itemId)
        end
        if itemId then
            local start, duration = GetItemCooldown(itemId)
            if start > 0 and duration > 0 then
                return TestValue(start, start + duration, duration, start, -1, comparator, limit)
            end
        end
        return Compare(0, comparator, limit)
    end
    OvaleCondition:RegisterCondition("itemcooldown", false, ItemCooldown)
end
do
local function ItemCount(positionalParams, namedParams, atTime)
        local itemId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = GetItemCount(itemId)
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("itemcount", false, ItemCount)
end
do
local function LastDamage(positionalParams, namedParams, atTime)
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
local function Level(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local value
        if target == "player" then
            value = OvalePaperDoll.level
        else
            value = UnitLevel(target)
        end
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("level", false, Level)
end
do
local function List(positionalParams, namedParams, atTime)
        local name, value = positionalParams[1], positionalParams[2]
        if name and OvaleFrameModule.frame and OvaleFrameModule.frame:GetListValue(name) == value then
            return 0, INFINITY
        end
        return nil
    end
    OvaleCondition:RegisterCondition("list", false, List)
end
do
local function Name(positionalParams, namedParams, atTime)
        local name, yesno = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        if type(name) == "number" then
            name = OvaleSpellBook:GetSpellName(name)
        end
        local targetName = UnitName(target)
        local boolean = (name == targetName)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("name", false, Name)
end
do
local function PTR(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local _, _, _, uiVersion = GetBuildInfo()
        local value = (uiVersion > 70300) and 1 or 0
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("ptr", false, PTR)
end
do
local function PersistentMultiplier(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = ParseCondition(positionalParams, namedParams, "target")
        local value = OvaleFuture:GetDamageMultiplier(spellId, OvaleGUID:UnitGUID(target), atTime)
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("persistentmultiplier", false, PersistentMultiplier)
end
do
local function PetPresent(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local name = namedParams.name
        local target = "pet"
        local boolean = UnitExists(target) and  not UnitIsDead(target) and (name == nil or name == UnitName(target))
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("petpresent", false, PetPresent)
end
do
local function MaxPower(powerType, positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local value
        if target == "player" then
            value = OvalePower.current.maxPower[powerType]
        else
            local powerInfo = OvalePower.POWER_INFO[powerType]
            value = UnitPowerMax(target, powerInfo.id, powerInfo.segments)
        end
        return Compare(value, comparator, limit)
    end
local function Power(powerType, positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        if target == "player" then
            local value, origin, rate = OvalePower.next.power[powerType], atTime, OvalePower.next:GetPowerRate(powerType)
            local start, ending = atTime, INFINITY
            return TestValue(start, ending, value, origin, rate, comparator, limit)
        else
            local powerInfo = OvalePower.POWER_INFO[powerType]
            local value = UnitPower(target, powerInfo.id)
            return Compare(value, comparator, limit)
        end
    end
local function PowerDeficit(powerType, positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        if target == "player" then
            local powerMax = OvalePower.current.maxPower[powerType] or 0
            if powerMax > 0 then
                local value, origin, rate = powerMax - OvalePower.next.power[powerType], atTime, -1 * OvalePower.next:GetPowerRate(powerType)
                local start, ending = atTime, INFINITY
                return TestValue(start, ending, value, origin, rate, comparator, limit)
            end
        else
            local powerInfo = OvalePower.POWER_INFO[powerType]
            local powerMax = UnitPowerMax(target, powerInfo.id, powerInfo.segments) or 0
            if powerMax > 0 then
                local power = UnitPower(target, powerInfo.id)
                local value = powerMax - power
                return Compare(value, comparator, limit)
            end
        end
        return Compare(0, comparator, limit)
    end
local function PowerPercent(powerType, positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        if target == "player" then
            local powerMax = OvalePower.current.maxPower[powerType] or 0
            if powerMax > 0 then
                local conversion = 100 / powerMax
                local value, origin, rate = OvalePower.next.power[powerType] * conversion, atTime, OvalePower.next:GetPowerRate(powerType) * conversion
                if rate > 0 and value >= 100 or rate < 0 and value == 0 then
                    rate = 0
                end
                local start, ending = atTime, INFINITY
                return TestValue(start, ending, value, origin, rate, comparator, limit)
            end
        else
            local powerInfo = OvalePower.POWER_INFO[powerType]
            local powerMax = UnitPowerMax(target, powerInfo.id, powerInfo.segments) or 0
            if powerMax > 0 then
                local conversion = 100 / powerMax
                local value = UnitPower(target, powerInfo.id) * conversion
                return Compare(value, comparator, limit)
            end
        end
        return Compare(0, comparator, limit)
    end
local function AlternatePower(positionalParams, namedParams, atTime)
        return Power("alternate", positionalParams, namedParams, atTime)
    end
local function AstralPower(positionalParams, namedParams, atTime)
        return Power("lunarpower", positionalParams, namedParams, atTime)
    end
local function Chi(positionalParams, namedParams, atTime)
        return Power("chi", positionalParams, namedParams, atTime)
    end
local function ComboPoints(positionalParams, namedParams, atTime)
        return Power("combopoints", positionalParams, namedParams, atTime)
    end
local function Energy(positionalParams, namedParams, atTime)
        return Power("energy", positionalParams, namedParams, atTime)
    end
local function Focus(positionalParams, namedParams, atTime)
        return Power("focus", positionalParams, namedParams, atTime)
    end
local function Fury(positionalParams, namedParams, atTime)
        return Power("fury", positionalParams, namedParams, atTime)
    end
local function HolyPower(positionalParams, namedParams, atTime)
        return Power("holypower", positionalParams, namedParams, atTime)
    end
local function Insanity(positionalParams, namedParams, atTime)
        return Power("insanity", positionalParams, namedParams, atTime)
    end
local function Mana(positionalParams, namedParams, atTime)
        return Power("mana", positionalParams, namedParams, atTime)
    end
local function Maelstrom(positionalParams, namedParams, atTime)
        return Power("maelstrom", positionalParams, namedParams, atTime)
    end
local function Pain(positionalParams, namedParams, atTime)
        return Power("pain", positionalParams, namedParams, atTime)
    end
local function Rage(positionalParams, namedParams, atTime)
        return Power("rage", positionalParams, namedParams, atTime)
    end
local function RunicPower(positionalParams, namedParams, atTime)
        return Power("runicpower", positionalParams, namedParams, atTime)
    end
local function SoulShards(positionalParams, namedParams, atTime)
        return Power("soulshards", positionalParams, namedParams, atTime)
    end
local function ArcaneCharges(positionalParams, namedParams, atTime)
        return Power("arcanecharges", positionalParams, namedParams, atTime)
    end
    OvaleCondition:RegisterCondition("alternatepower", false, AlternatePower)
    OvaleCondition:RegisterCondition("arcanecharges", false, ArcaneCharges)
    OvaleCondition:RegisterCondition("astralpower", false, AstralPower)
    OvaleCondition:RegisterCondition("chi", false, Chi)
    OvaleCondition:RegisterCondition("combopoints", false, ComboPoints)
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
    OvaleCondition:RegisterCondition("soulshards", false, SoulShards)
local function AlternatePowerDeficit(positionalParams, namedParams, atTime)
        return PowerDeficit("alternate", positionalParams, namedParams, atTime)
    end
local function AstralPowerDeficit(positionalParams, namedParams, atTime)
        return PowerDeficit("lunarpower", positionalParams, namedParams, atTime)
    end
local function ChiDeficit(positionalParams, namedParams, atTime)
        return PowerDeficit("chi", positionalParams, namedParams, atTime)
    end
local function ComboPointsDeficit(positionalParams, namedParams, atTime)
        return PowerDeficit("combopoints", positionalParams, namedParams, atTime)
    end
local function EnergyDeficit(positionalParams, namedParams, atTime)
        return PowerDeficit("energy", positionalParams, namedParams, atTime)
    end
local function FocusDeficit(positionalParams, namedParams, atTime)
        return PowerDeficit("focus", positionalParams, namedParams, atTime)
    end
local function FuryDeficit(positionalParams, namedParams, atTime)
        return PowerDeficit("fury", positionalParams, namedParams, atTime)
    end
local function HolyPowerDeficit(positionalParams, namedParams, atTime)
        return PowerDeficit("holypower", positionalParams, namedParams, atTime)
    end
local function ManaDeficit(positionalParams, namedParams, atTime)
        return PowerDeficit("mana", positionalParams, namedParams, atTime)
    end
local function PainDeficit(positionalParams, namedParams, atTime)
        return PowerDeficit("pain", positionalParams, namedParams, atTime)
    end
local function RageDeficit(positionalParams, namedParams, atTime)
        return PowerDeficit("rage", positionalParams, namedParams, atTime)
    end
local function RunicPowerDeficit(positionalParams, namedParams, atTime)
        return PowerDeficit("runicpower", positionalParams, namedParams, atTime)
    end
local function SoulShardsDeficit(positionalParams, namedParams, atTime)
        return PowerDeficit("soulshards", positionalParams, namedParams, atTime)
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
    OvaleCondition:RegisterCondition("soulshardsdeficit", false, SoulShardsDeficit)
local function ManaPercent(positionalParams, namedParams, atTime)
        return PowerPercent("mana", positionalParams, namedParams, atTime)
    end
    OvaleCondition:RegisterCondition("manapercent", false, ManaPercent)
local function MaxAlternatePower(positionalParams, namedParams, atTime)
        return MaxPower("alternate", positionalParams, namedParams, atTime)
    end
local function MaxChi(positionalParams, namedParams, atTime)
        return MaxPower("chi", positionalParams, namedParams, atTime)
    end
local function MaxComboPoints(positionalParams, namedParams, atTime)
        return MaxPower("combopoints", positionalParams, namedParams, atTime)
    end
local function MaxEnergy(positionalParams, namedParams, atTime)
        return MaxPower("energy", positionalParams, namedParams, atTime)
    end
local function MaxFocus(positionalParams, namedParams, atTime)
        return MaxPower("focus", positionalParams, namedParams, atTime)
    end
local function MaxFury(positionalParams, namedParams, atTime)
        return MaxPower("fury", positionalParams, namedParams, atTime)
    end
local function MaxHolyPower(positionalParams, namedParams, atTime)
        return MaxPower("holypower", positionalParams, namedParams, atTime)
    end
local function MaxMana(positionalParams, namedParams, atTime)
        return MaxPower("mana", positionalParams, namedParams, atTime)
    end
local function MaxPain(positionalParams, namedParams, atTime)
        return MaxPower("pain", positionalParams, namedParams, atTime)
    end
local function MaxRage(positionalParams, namedParams, atTime)
        return MaxPower("rage", positionalParams, namedParams, atTime)
    end
local function MaxRunicPower(positionalParams, namedParams, atTime)
        return MaxPower("runicpower", positionalParams, namedParams, atTime)
    end
local function MaxSoulShards(positionalParams, namedParams, atTime)
        return MaxPower("soulshards", positionalParams, namedParams, atTime)
    end
local function MaxArcaneCharges(positionalParams, namedParams, atTime)
        return MaxPower("arcanecharges", positionalParams, namedParams, atTime)
    end
    OvaleCondition:RegisterCondition("maxalternatepower", false, MaxAlternatePower)
    OvaleCondition:RegisterCondition("maxarcanecharges", false, MaxArcaneCharges)
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
    OvaleCondition:RegisterCondition("maxsoulshards", false, MaxSoulShards)
end
do
local function PowerCost(powerType, positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = ParseCondition(positionalParams, namedParams, "target")
        local maxCost = (namedParams.max == 1)
        local value = OvalePower:PowerCost(spellId, powerType, atTime, target, maxCost) or 0
        return Compare(value, comparator, limit)
    end
local function EnergyCost(positionalParams, namedParams, atTime)
        return PowerCost("energy", positionalParams, namedParams, atTime)
    end
local function FocusCost(positionalParams, namedParams, atTime)
        return PowerCost("focus", positionalParams, namedParams, atTime)
    end
local function ManaCost(positionalParams, namedParams, atTime)
        return PowerCost("mana", positionalParams, namedParams, atTime)
    end
local function RageCost(positionalParams, namedParams, atTime)
        return PowerCost("rage", positionalParams, namedParams, atTime)
    end
local function RunicPowerCost(positionalParams, namedParams, atTime)
        return PowerCost("runicpower", positionalParams, namedParams, atTime)
    end
local function AstralPowerCost(positionalParams, namedParams, atTime)
        return PowerCost("lunarpower", positionalParams, namedParams, atTime)
    end
local function MainPowerCost(positionalParams, namedParams, atTime)
        return PowerCost(OvalePower.current.powerType, positionalParams, namedParams, atTime)
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
local function Present(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local target = ParseCondition(positionalParams, namedParams)
        local boolean = UnitExists(target) and  not UnitIsDead(target)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("present", false, Present)
end
do
local function PreviousGCDSpell(positionalParams, namedParams, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local count = namedParams.count
        local boolean
        if count and count > 1 then
            boolean = (spellId == OvaleFuture.next.lastGCDSpellIds[#OvaleFuture.next.lastGCDSpellIds - count + 2])
        else
            boolean = (spellId == OvaleFuture.next.lastGCDSpellId)
        end
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("previousgcdspell", true, PreviousGCDSpell)
end
do
local function PreviousOffGCDSpell(positionalParams, namedParams, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local boolean = (spellId == OvaleFuture.next.lastOffGCDSpellcast.spellId)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("previousoffgcdspell", true, PreviousOffGCDSpell)
end
do
local function PreviousSpell(positionalParams, namedParams, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local boolean = (spellId == OvaleFuture.next.lastGCDSpellId)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("previousspell", true, PreviousSpell)
end
do
local function RelativeLevel(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local value, level
        if target == "player" then
            level = OvalePaperDoll.level
        else
            level = UnitLevel(target)
        end
        if level < 0 then
            value = 3
        else
            value = level - OvalePaperDoll.level
        end
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("relativelevel", false, RelativeLevel)
end
do
local function Refreshable(positionalParams, namedParams, atTime)
        local auraId = positionalParams[1]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        if aura then
            local baseDuration = OvaleAura:GetBaseDuration(auraId)
            if baseDuration == INFINITY then
                baseDuration = aura.ending - aura.start
            end
            local extensionDuration = 0.3 * baseDuration
            OvaleAura:Log("ending = %s extensionDuration = %s", aura.ending, extensionDuration)
            return aura.ending - extensionDuration, INFINITY
        end
        return 0, INFINITY
    end
    OvaleCondition:RegisterCondition("refreshable", false, Refreshable)
    OvaleCondition:RegisterCondition("debuffrefreshable", false, Refreshable)
    OvaleCondition:RegisterCondition("buffrefreshable", false, Refreshable)
end
do
local function RemainingCastTime(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local _, _, _, startTime, endTime = UnitCastingInfo(target)
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
local function Rune(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local count, startCooldown, endCooldown = OvaleRunes:RuneCount(atTime)
        if startCooldown < INFINITY then
            local origin = startCooldown
            local rate = 1 / (endCooldown - startCooldown)
            local start, ending = startCooldown, INFINITY
            return TestValue(start, ending, count, origin, rate, comparator, limit)
        end
        return Compare(count, comparator, limit)
    end
local function RuneDeficit(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local count, startCooldown, endCooldown = OvaleRunes:RuneDeficit(atTime)
        if startCooldown < INFINITY then
            local origin = startCooldown
            local rate = -1 / (endCooldown - startCooldown)
            local start, ending = startCooldown, INFINITY
            return TestValue(start, ending, count, origin, rate, comparator, limit)
        end
        return Compare(count, comparator, limit)
    end
local function RuneCount(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local count, startCooldown, endCooldown = OvaleRunes:RuneCount(atTime)
        if startCooldown < INFINITY then
            local start, ending = startCooldown, endCooldown
            return TestValue(start, ending, count, start, 0, comparator, limit)
        end
        return Compare(count, comparator, limit)
    end
local function TimeToRunes(positionalParams, namedParams, atTime)
        local runes, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local seconds = OvaleRunes:GetRunesCooldown(atTime, runes)
        if seconds < 0 then
            seconds = 0
        end
        return Compare(seconds, comparator, limit)
    end
    OvaleCondition:RegisterCondition("rune", false, Rune)
    OvaleCondition:RegisterCondition("runecount", false, RuneCount)
    OvaleCondition:RegisterCondition("timetorunes", false, TimeToRunes)
    OvaleCondition:RegisterCondition("runedeficit", false, RuneDeficit)
end
do
local function Snapshot(statName, defaultValue, positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = OvalePaperDoll:GetState(atTime)[statName] or defaultValue
        return Compare(value, comparator, limit)
    end
local function SnapshotCritChance(statName, defaultValue, positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = OvalePaperDoll:GetState(atTime)[statName] or defaultValue
        if namedParams.unlimited ~= 1 and value > 100 then
            value = 100
        end
        return Compare(value, comparator, limit)
    end
local function Agility(positionalParams, namedParams, atTime)
        return Snapshot("agility", 0, positionalParams, namedParams, atTime)
    end
local function AttackPower(positionalParams, namedParams, atTime)
        return Snapshot("attackPower", 0, positionalParams, namedParams, atTime)
    end
local function CritRating(positionalParams, namedParams, atTime)
        return Snapshot("critRating", 0, positionalParams, namedParams, atTime)
    end
local function HasteRating(positionalParams, namedParams, atTime)
        return Snapshot("hasteRating", 0, positionalParams, namedParams, atTime)
    end
local function Intellect(positionalParams, namedParams, atTime)
        return Snapshot("intellect", 0, positionalParams, namedParams, atTime)
    end
local function MasteryEffect(positionalParams, namedParams, atTime)
        return Snapshot("masteryEffect", 0, positionalParams, namedParams, atTime)
    end
local function MasteryRating(positionalParams, namedParams, atTime)
        return Snapshot("masteryRating", 0, positionalParams, namedParams, atTime)
    end
local function MeleeCritChance(positionalParams, namedParams, atTime)
        return SnapshotCritChance("meleeCrit", 0, positionalParams, namedParams, atTime)
    end
local function MeleeAttackSpeedPercent(positionalParams, namedParams, atTime)
        return Snapshot("meleeAttackSpeedPercent", 0, positionalParams, namedParams, atTime)
    end
local function RangedCritChance(positionalParams, namedParams, atTime)
        return SnapshotCritChance("rangedCrit", 0, positionalParams, namedParams, atTime)
    end
local function SpellCritChance(positionalParams, namedParams, atTime)
        return SnapshotCritChance("spellCrit", 0, positionalParams, namedParams, atTime)
    end
local function SpellCastSpeedPercent(positionalParams, namedParams, atTime)
        return Snapshot("spellCastSpeedPercent", 0, positionalParams, namedParams, atTime)
    end
local function Spellpower(positionalParams, namedParams, atTime)
        return Snapshot("spellPower", 0, positionalParams, namedParams, atTime)
    end
local function Stamina(positionalParams, namedParams, atTime)
        return Snapshot("stamina", 0, positionalParams, namedParams, atTime)
    end
local function Strength(positionalParams, namedParams, atTime)
        return Snapshot("strength", 0, positionalParams, namedParams, atTime)
    end
local function Versatility(positionalParams, namedParams, atTime)
        return Snapshot("versatility", 0, positionalParams, namedParams, atTime)
    end
local function VersatilityRating(positionalParams, namedParams, atTime)
        return Snapshot("versatilityRating", 0, positionalParams, namedParams, atTime)
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
    OvaleCondition:RegisterCondition("meleeattackspeedpercent", false, MeleeAttackSpeedPercent)
    OvaleCondition:RegisterCondition("rangedcritchance", false, RangedCritChance)
    OvaleCondition:RegisterCondition("spellcritchance", false, SpellCritChance)
    OvaleCondition:RegisterCondition("spellcastspeedpercent", false, SpellCastSpeedPercent)
    OvaleCondition:RegisterCondition("spellpower", false, Spellpower)
    OvaleCondition:RegisterCondition("stamina", false, Stamina)
    OvaleCondition:RegisterCondition("strength", false, Strength)
    OvaleCondition:RegisterCondition("versatility", false, Versatility)
    OvaleCondition:RegisterCondition("versatilityRating", false, VersatilityRating)
end
do
local function Speed(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local value = GetUnitSpeed(target) * 100 / 7
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("speed", false, Speed)
end
do
local function SpellChargeCooldown(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local charges, maxCharges, start, duration = OvaleCooldown:GetSpellCharges(spellId, atTime)
        if charges and charges < maxCharges then
            return TestValue(start, start + duration, duration, start, -1, comparator, limit)
        end
        return Compare(0, comparator, limit)
    end
    OvaleCondition:RegisterCondition("spellchargecooldown", true, SpellChargeCooldown)
end
do
local function SpellCharges(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local charges, maxCharges, start, duration = OvaleCooldown:GetSpellCharges(spellId, atTime)
        if  not charges then
            return nil
        end
        charges = charges or 0
        maxCharges = maxCharges or 1
        if namedParams.count == 0 and charges < maxCharges then
            return TestValue(atTime, INFINITY, charges + 1, start + duration, 1 / duration, comparator, limit)
        end
        return Compare(charges, comparator, limit)
    end
    OvaleCondition:RegisterCondition("charges", true, SpellCharges)
    OvaleCondition:RegisterCondition("spellcharges", true, SpellCharges)
end
do
local function SpellFullRecharge(positionalParams, namedParams, atTime)
        local spellId = positionalParams[1]
        local comparator = positionalParams[2]
        local limit = positionalParams[3]
        local charges, maxCharges, start, dur = OvaleCooldown:GetSpellCharges(spellId, atTime)
        if charges and charges < maxCharges then
            local duration = (maxCharges - charges) * dur
            local ending = start + duration
            return TestValue(start, ending, ending - start, start, -1, comparator, limit)
        end
        return Compare(0, comparator, limit)
    end
    OvaleCondition:RegisterCondition("spellfullrecharge", true, SpellFullRecharge)
end
do
local function SpellCooldown(positionalParams, namedParams, atTime)
        local comparator, limit
        local usable = (namedParams.usable == 1)
        local target = ParseCondition(positionalParams, namedParams, "target")
        local earliest = INFINITY
        for i, spellId in ipairs(positionalParams) do
            if isComparator(spellId) then
                comparator, limit = spellId, positionalParams[i + 1]
                break
            elseif  not usable or OvaleSpells:IsUsableSpell(spellId, atTime, OvaleGUID:UnitGUID(target)) then
                local start, duration = OvaleCooldown:GetSpellCooldown(spellId, atTime)
                local t = 0
                if start > 0 and duration > 0 then
                    t = start + duration
                end
                if earliest > t then
                    earliest = t
                end
            end
        end
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
local function SpellCooldownDuration(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = ParseCondition(positionalParams, namedParams, "target")
        local duration = OvaleCooldown:GetSpellCooldownDuration(spellId, atTime, target)
        return Compare(duration, comparator, limit)
    end
    OvaleCondition:RegisterCondition("spellcooldownduration", true, SpellCooldownDuration)
end
do
local function SpellRechargeDuration(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = ParseCondition(positionalParams, namedParams, "target")
        local cd = OvaleCooldown:GetCD(spellId, atTime)
        local duration = cd.chargeDuration or OvaleCooldown:GetSpellCooldownDuration(spellId, atTime, target)
        return Compare(duration, comparator, limit)
    end
    OvaleCondition:RegisterCondition("spellrechargeduration", true, SpellRechargeDuration)
end
do
local function SpellData(positionalParams, namedParams, atTime)
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
local function SpellInfoProperty(positionalParams, namedParams, atTime)
        local spellId, key, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3], positionalParams[4]
        local value = OvaleData:GetSpellInfoProperty(spellId, atTime, key, nil)
        if value then
            return Compare(value, comparator, limit)
        end
        return nil
    end
    OvaleCondition:RegisterCondition("spellinfoproperty", false, SpellInfoProperty)
end
do
local function SpellCount(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local spellCount = OvaleSpells:GetSpellCount(spellId)
        return Compare(spellCount, comparator, limit)
    end
    OvaleCondition:RegisterCondition("spellcount", true, SpellCount)
end
do
local function SpellKnown(positionalParams, namedParams, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local boolean = OvaleSpellBook:IsKnownSpell(spellId)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("spellknown", true, SpellKnown)
end
do
local function SpellMaxCharges(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local _, maxCharges, _ = OvaleCooldown:GetSpellCharges(spellId, atTime)
        if  not maxCharges then
            return nil
        end
        maxCharges = maxCharges or 1
        return Compare(maxCharges, comparator, limit)
    end
    OvaleCondition:RegisterCondition("spellmaxcharges", true, SpellMaxCharges)
end
do
local function SpellUsable(positionalParams, namedParams, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams, "target")
        local isUsable, noMana = OvaleSpells:IsUsableSpell(spellId, atTime, OvaleGUID:UnitGUID(target))
        local boolean = isUsable or noMana
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("spellusable", true, SpellUsable)
end
do
    local LIGHT_STAGGER = 124275
    local MODERATE_STAGGER = 124274
    local HEAVY_STAGGER = 124273
local function StaggerRemaining(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, HEAVY_STAGGER, atTime, "HARMFUL")
        if  not OvaleAura:IsActiveAura(aura, atTime) then
            aura = OvaleAura:GetAura(target, MODERATE_STAGGER, atTime, "HARMFUL")
        end
        if  not OvaleAura:IsActiveAura(aura, atTime) then
            aura = OvaleAura:GetAura(target, LIGHT_STAGGER, atTime, "HARMFUL")
        end
        if OvaleAura:IsActiveAura(aura, atTime) then
            local gain, start, ending = aura.gain, aura.start, aura.ending
            local stagger = UnitStagger(target)
            local rate = -1 * stagger / (ending - start)
            return TestValue(gain, ending, 0, ending, rate, comparator, limit)
        end
        return Compare(0, comparator, limit)
    end
local function StaggerTick(positionalParams, namedParams, atTime)
        local count, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[2]
        local damage = OvaleStagger:LastTickDamage(count)
        return Compare(damage, comparator, limit)
    end
    OvaleCondition:RegisterCondition("staggerremaining", false, StaggerRemaining)
    OvaleCondition:RegisterCondition("staggerremains", false, StaggerRemaining)
    OvaleCondition:RegisterCondition("staggertick", false, StaggerTick)
end
do
local function Stance(positionalParams, namedParams, atTime)
        local stance, yesno = positionalParams[1], positionalParams[2]
        local boolean = OvaleStance:IsStance(stance, atTime)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("stance", false, Stance)
end
do
local function Stealthed(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local boolean = OvaleAura:GetAura("player", "stealthed_buff", atTime, "HELPFUL") ~= nil or IsStealthed()
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("isstealthed", false, Stealthed)
    OvaleCondition:RegisterCondition("stealthed", false, Stealthed)
end
do
local function LastSwing(positionalParams, namedParams, atTime)
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
local function NextSwing(positionalParams, namedParams, atTime)
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
local function Talent(positionalParams, namedParams, atTime)
        local talentId, yesno = positionalParams[1], positionalParams[2]
        local boolean = (OvaleSpellBook:GetTalentPoints(talentId) > 0)
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("talent", false, Talent)
    OvaleCondition:RegisterCondition("hastalent", false, Talent)
end
do
local function TalentPoints(positionalParams, namedParams, atTime)
        local talent, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = OvaleSpellBook:GetTalentPoints(talent)
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("talentpoints", false, TalentPoints)
end
do
local function TargetIsPlayer(positionalParams, namedParams, atTime)
        local yesno = positionalParams[1]
        local target = ParseCondition(positionalParams, namedParams)
        local boolean = UnitIsUnit("player", target .. "target")
        return TestBoolean(boolean, yesno)
    end
    OvaleCondition:RegisterCondition("istargetingplayer", false, TargetIsPlayer)
    OvaleCondition:RegisterCondition("targetisplayer", false, TargetIsPlayer)
end
do
local function Threat(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = ParseCondition(positionalParams, namedParams, "target")
        local _, _, value = UnitDetailedThreatSituation("player", target)
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("threat", false, Threat)
end
do
local function TickTime(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        local tickTime
        if OvaleAura:IsActiveAura(aura, atTime) then
            tickTime = aura.tick
        else
            tickTime = OvaleAura:GetTickLength(auraId, OvalePaperDoll.next)
        end
        if tickTime and tickTime > 0 then
            return Compare(tickTime, comparator, limit)
        end
        return Compare(INFINITY, comparator, limit)
    end
local function CurrentTickTime(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        local tickTime
        if OvaleAura:IsActiveAura(aura, atTime) then
            tickTime = aura.tick
        else
            tickTime = 0
        end
        return Compare(tickTime, comparator, limit)
    end
    OvaleCondition:RegisterCondition("ticktime", false, TickTime)
    OvaleCondition:RegisterCondition("currentticktime", false, CurrentTickTime)
end
do
local function TicksRemaining(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        if aura then
            local gain, _, ending, tick = aura.gain, aura.start, aura.ending, aura.tick
            if tick and tick > 0 then
                return TestValue(gain, INFINITY, 1, ending, -1 / tick, comparator, limit)
            end
        end
        return Compare(0, comparator, limit)
    end
local function TickTimeRemaining(positionalParams, namedParams, atTime)
        local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target, filter, mine = ParseCondition(positionalParams, namedParams)
        local aura = OvaleAura:GetAura(target, auraId, atTime, filter, mine)
        if OvaleAura:IsActiveAura(aura, atTime) then
            local lastTickTime = aura.lastTickTime or aura.start
            local tick = aura.tick or OvaleAura:GetTickLength(auraId, OvalePaperDoll.next)
            local remainingTime = tick - (atTime - lastTickTime)
            if remainingTime and remainingTime > 0 then
                return Compare(remainingTime, comparator, limit)
            end
        end
        return Compare(0, comparator, limit)
    end
    OvaleCondition:RegisterCondition("ticksremaining", false, TicksRemaining)
    OvaleCondition:RegisterCondition("ticksremain", false, TicksRemaining)
    OvaleCondition:RegisterCondition("ticktimeremaining", false, TickTimeRemaining)
end
do
local function TimeInCombat(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        if baseState.next.inCombat then
            local start = baseState.next.combatStartTime
            return TestValue(start, INFINITY, 0, start, 1, comparator, limit)
        end
        return Compare(0, comparator, limit)
    end
    OvaleCondition:RegisterCondition("timeincombat", false, TimeInCombat)
end
do
local function TimeSincePreviousSpell(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local t = OvaleFuture:TimeOfLastCast(spellId, atTime)
        return TestValue(0, INFINITY, 0, t, 1, comparator, limit)
    end
    OvaleCondition:RegisterCondition("timesincepreviousspell", false, TimeSincePreviousSpell)
end
do
local function TimeToBloodlust(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = 3600
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("timetobloodlust", false, TimeToBloodlust)
end
do
local function TimeToEclipse(positionalParams, namedParams, atTime)
        local _, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local value = 3600 * 24 * 7
        Ovale:OneTimeMessage("Warning: 'TimeToEclipse()' is not implemented.")
        return TestValue(0, INFINITY, value, atTime, -1, comparator, limit)
    end
    OvaleCondition:RegisterCondition("timetoeclipse", false, TimeToEclipse)
end
do
local function TimeToPower(powerType, level, comparator, limit, atTime)
        level = level or 0
        local power = OvalePower.next.power[powerType] or 0
        local powerRegen = OvalePower.next:GetPowerRate(powerType) or 1
        if powerRegen == 0 then
            if power == level then
                return Compare(0, comparator, limit)
            end
            return Compare(INFINITY, comparator, limit)
        else
            local t = (level - power) / powerRegen
            if t > 0 then
                local ending = atTime + t
                return TestValue(0, ending, 0, ending, -1, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
    end
local function TimeToEnergy(positionalParams, namedParams, atTime)
        local level, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        return TimeToPower("energy", level, comparator, limit, atTime)
    end
local function TimeToMaxEnergy(positionalParams, namedParams, atTime)
        local powerType = "energy"
        local comparator, limit = positionalParams[1], positionalParams[2]
        local level = OvalePower.current.maxPower[powerType] or 0
        return TimeToPower(powerType, level, comparator, limit, atTime)
    end
local function TimeToFocus(positionalParams, namedParams, atTime)
        local level, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        return TimeToPower("focus", level, comparator, limit, atTime)
    end
local function TimeToMaxFocus(positionalParams, namedParams, atTime)
        local powerType = "focus"
        local comparator, limit = positionalParams[1], positionalParams[2]
        local level = OvalePower.current.maxPower[powerType] or 0
        return TimeToPower(powerType, level, comparator, limit, atTime)
    end
    OvaleCondition:RegisterCondition("timetoenergy", false, TimeToEnergy)
    OvaleCondition:RegisterCondition("timetofocus", false, TimeToFocus)
    OvaleCondition:RegisterCondition("timetomaxenergy", false, TimeToMaxEnergy)
    OvaleCondition:RegisterCondition("timetomaxfocus", false, TimeToMaxFocus)
end
do
local function TimeToPowerFor(powerType, positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = ParseCondition(positionalParams, namedParams, "target")
        if  not powerType then
            local _, pt = OvalePower:GetSpellCost(spellId)
            powerType = pt
        end
        local seconds = OvalePower:TimeToPower(spellId, atTime, OvaleGUID:UnitGUID(target), powerType)
        if seconds == 0 then
            return Compare(0, comparator, limit)
        elseif seconds < INFINITY then
            return TestValue(0, atTime + seconds, seconds, atTime, -1, comparator, limit)
        else
            return Compare(INFINITY, comparator, limit)
        end
    end
local function TimeToEnergyFor(positionalParams, namedParams, atTime)
        return TimeToPowerFor("energy", positionalParams, namedParams, atTime)
    end
local function TimeToFocusFor(positionalParams, namedParams, atTime)
        return TimeToPowerFor("focus", positionalParams, namedParams, atTime)
    end
    OvaleCondition:RegisterCondition("timetoenergyfor", true, TimeToEnergyFor)
    OvaleCondition:RegisterCondition("timetofocusfor", true, TimeToFocusFor)
end
do
local function TimeToSpell(positionalParams, namedParams, atTime)
        local _, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        Ovale:OneTimeMessage("Warning: 'TimeToSpell()' is not implemented.")
        return TestValue(0, INFINITY, 0, atTime, -1, comparator, limit)
    end
    OvaleCondition:RegisterCondition("timetospell", true, TimeToSpell)
end
do
local function TimeWithHaste(positionalParams, namedParams, atTime)
        local seconds, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local haste = namedParams.haste or "spell"
        local value = GetHastedTime(seconds, haste)
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("timewithhaste", false, TimeWithHaste)
end
do
local function TotemExpires(positionalParams, namedParams, atTime)
        local id, seconds = positionalParams[1], positionalParams[2]
        seconds = seconds or 0
        local count, _, ending = OvaleTotem:GetTotemInfo(id, atTime)
        if count > 0 then
            return ending - seconds, INFINITY
        end
        return 0, INFINITY
    end
    OvaleCondition:RegisterCondition("totemexpires", false, TotemExpires)
local function TotemPresent(positionalParams, namedParams, atTime)
        local id = positionalParams[1]
        local count, start, ending = OvaleTotem:GetTotemInfo(id, atTime)
        if count > 0 then
            return start, ending
        end
        return nil
    end
    OvaleCondition:RegisterCondition("totempresent", false, TotemPresent)
local function TotemRemaining(positionalParams, namedParams, atTime)
        local id, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local count, start, ending = OvaleTotem:GetTotemInfo(id, atTime)
        if count > 0 then
            return TestValue(start, ending, 0, ending, -1, comparator, limit)
        end
        return Compare(0, comparator, limit)
    end
    OvaleCondition:RegisterCondition("totemremaining", false, TotemRemaining)
    OvaleCondition:RegisterCondition("totemremains", false, TotemRemaining)
end
do
local function Tracking(positionalParams, namedParams, atTime)
        local spellId, yesno = positionalParams[1], positionalParams[2]
        local spellName = OvaleSpellBook:GetSpellName(spellId)
        local numTrackingTypes = GetNumTrackingTypes()
        local boolean = false
        for i = 1, numTrackingTypes, 1 do
            local name, _, active = GetTrackingInfo(i)
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
local function TravelTime(positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local si = spellId and OvaleData.spellInfo[spellId]
        local travelTime = 0
        if si then
            travelTime = si.travel_time or si.max_travel_time or 0
        end
        if travelTime > 0 then
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
local function True(positionalParams, namedParams, atTime)
        return 0, INFINITY
    end
    OvaleCondition:RegisterCondition("true", false, True)
end
do
local function WeaponDPS(positionalParams, namedParams, atTime)
        local hand = positionalParams[1]
        local comparator, limit
        local value = 0
        if hand == "offhand" or hand == "off" then
            comparator, limit = positionalParams[2], positionalParams[3]
            value = OvalePaperDoll.current.offHandWeaponDPS
        elseif hand == "mainhand" or hand == "main" then
            comparator, limit = positionalParams[2], positionalParams[3]
            value = OvalePaperDoll.current.mainHandWeaponDPS
        else
            comparator, limit = positionalParams[1], positionalParams[2]
            value = OvalePaperDoll.current.mainHandWeaponDPS
        end
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("weapondps", false, WeaponDPS)
end
do
local function WeaponEnchantExpires(positionalParams, namedParams, atTime)
        local hand, seconds = positionalParams[1], positionalParams[2]
        seconds = seconds or 0
        local hasMainHandEnchant, mainHandExpiration, _, hasOffHandEnchant, offHandExpiration = GetWeaponEnchantInfo()
        local now = GetTime()
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
local function SigilCharging(positionalParams, namedParams, atTime)
        local charging = false
        for _, v in ipairs(positionalParams) do
            charging = charging or OvaleSigil:IsSigilCharging(v, atTime)
        end
        return TestBoolean(charging, "yes")
    end
    OvaleCondition:RegisterCondition("sigilcharging", false, SigilCharging)
end
do
local function IsBossFight(positionalParams, namedParams, atTime)
        local bossEngaged = baseState.next.inCombat and OvaleBossMod:IsBossEngaged(atTime)
        return TestBoolean(bossEngaged, "yes")
    end
    OvaleCondition:RegisterCondition("isbossfight", false, IsBossFight)
end
do
local function Race(positionalParams, namedParams, atTime)
        local isRace = false
        local target = namedParams.target or "player"
        local _, targetRaceId = UnitRace(target)
        for _, v in ipairs(positionalParams) do
            isRace = isRace or (v == targetRaceId)
        end
        return TestBoolean(isRace, "yes")
    end
    OvaleCondition:RegisterCondition("race", false, Race)
end
do
local function UnitInPartyCond(positionalParams, namedParams, atTime)
        local target = namedParams.target or "player"
        local isTrue = UnitInParty(target)
        return TestBoolean(isTrue, "yes")
    end
    OvaleCondition:RegisterCondition("unitinparty", false, UnitInPartyCond)
end
do
local function UnitInRaidCond(positionalParams, namedParams, atTime)
        local target = namedParams.target or "player"
        local raidIndex = UnitInRaid(target)
        return TestBoolean(raidIndex ~= nil, "yes")
    end
    OvaleCondition:RegisterCondition("unitinraid", false, UnitInRaidCond)
end
do
local function SoulFragments(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = OvaleDemonHunterSoulFragments:SoulFragments(atTime)
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("soulfragments", false, SoulFragments)
end
do
local function TimeToShard(positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = OvaleWarlock:TimeToShard(atTime)
        return Compare(value, comparator, limit)
    end
    OvaleCondition:RegisterCondition("timetoshard", false, TimeToShard)
end
