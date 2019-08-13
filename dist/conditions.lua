local __exports = LibStub:NewLibrary("ovale/conditions", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local LibBabbleCreatureType = LibStub:GetLibrary("LibBabble-CreatureType-3.0", true)
local LibRangeCheck = LibStub:GetLibrary("LibRangeCheck-2.0", true)
local LibInterrupt = LibStub:GetLibrary("LibInterrupt-1.0", true)
local __Condition = LibStub:GetLibrary("ovale/Condition")
local TestValue = __Condition.TestValue
local Compare = __Condition.Compare
local TestBoolean = __Condition.TestBoolean
local isComparator = __Condition.isComparator
local ReturnValue = __Condition.ReturnValue
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
local min = math.min
local __AST = LibStub:GetLibrary("ovale/AST")
local isNodeType = __AST.isNodeType
local lower = string.lower
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Print = __Ovale.Print
local INFINITY = huge
local function BossArmorDamageReduction(target)
    return 0.3
end
local AMPLIFICATION = 146051
local INCREASED_CRIT_EFFECT_3_PERCENT = 44797
local IMBUED_BUFF_ID = 214336
local INNER_DEMONS_TALENT = 17
local HAND_OF_GULDAN_SPELL_ID = 105174
local WILD_IMP_INNER_DEMONS = 143622
local NECROTIC_PLAGUE_TALENT = 19
local NECROTIC_PLAGUE_DEBUFF = 155159
local BLOOD_PLAGUE_DEBUFF = 55078
local FROST_FEVER_DEBUFF = 55095
local STEADY_FOCUS = 177668
local LIGHT_STAGGER = 124275
local MODERATE_STAGGER = 124274
local HEAVY_STAGGER = 124273
__exports.OvaleConditions = __class(nil, {
    ComputeParameter = function(self, spellId, paramName, atTime)
        local si = self.OvaleData:GetSpellInfo(spellId)
        if si and si[paramName] then
            local name = si[paramName]
            local node = self.OvaleCompile:GetFunctionNode(name)
            if node then
                local _, element = self.OvaleBestAction:Compute(node.child[1], atTime)
                if element and isNodeType(element, "value") then
                    local value = element.value + (atTime - element.origin) * element.rate
                    return value
                end
            else
                return si[paramName]
            end
        end
        return nil
    end,
    GetHastedTime = function(self, seconds, haste)
        seconds = seconds or 0
        local multiplier = self.OvalePaperDoll:GetHasteMultiplier(haste, self.OvalePaperDoll.next)
        return seconds / multiplier
    end,
    GetDiseases = function(self, target, atTime)
        local npAura, bpAura, ffAura
        local talented = (self.OvaleSpellBook:GetTalentPoints(NECROTIC_PLAGUE_TALENT) > 0)
        if talented then
            npAura = self.OvaleAura:GetAura(target, NECROTIC_PLAGUE_DEBUFF, atTime, "HARMFUL", true)
        else
            bpAura = self.OvaleAura:GetAura(target, BLOOD_PLAGUE_DEBUFF, atTime, "HARMFUL", true)
            ffAura = self.OvaleAura:GetAura(target, FROST_FEVER_DEBUFF, atTime, "HARMFUL", true)
        end
        return talented, npAura, bpAura, ffAura
    end,
    MaxPower = function(self, powerType, positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = self:ParseCondition(positionalParams, namedParams)
        local value
        if target == "player" then
            value = self.OvalePower.current.maxPower[powerType]
        else
            local powerInfo = self.OvalePower.POWER_INFO[powerType]
            value = UnitPowerMax(target, powerInfo.id, powerInfo.segments)
        end
        return Compare(value, comparator, limit)
    end,
    Power = function(self, powerType, positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = self:ParseCondition(positionalParams, namedParams)
        if target == "player" then
            local value, origin, rate = self.OvalePower.next.power[powerType], atTime, self.OvalePower:getPowerRateAt(self.OvalePower.next, powerType, atTime)
            local start, ending = atTime, INFINITY
            return TestValue(start, ending, value, origin, rate, comparator, limit)
        else
            local powerInfo = self.OvalePower.POWER_INFO[powerType]
            local value = UnitPower(target, powerInfo.id)
            return Compare(value, comparator, limit)
        end
    end,
    PowerDeficit = function(self, powerType, positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = self:ParseCondition(positionalParams, namedParams)
        if target == "player" then
            local powerMax = self.OvalePower.current.maxPower[powerType] or 0
            if powerMax > 0 then
                local value, origin, rate = powerMax - self.OvalePower.next.power[powerType], atTime, -1 * self.OvalePower:getPowerRateAt(self.OvalePower.next, powerType, atTime)
                local start, ending = atTime, INFINITY
                return TestValue(start, ending, value, origin, rate, comparator, limit)
            end
        else
            local powerInfo = self.OvalePower.POWER_INFO[powerType]
            local powerMax = UnitPowerMax(target, powerInfo.id, powerInfo.segments) or 0
            if powerMax > 0 then
                local power = UnitPower(target, powerInfo.id)
                local value = powerMax - power
                return Compare(value, comparator, limit)
            end
        end
        return Compare(0, comparator, limit)
    end,
    PowerPercent = function(self, powerType, positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local target = self:ParseCondition(positionalParams, namedParams)
        if target == "player" then
            local powerMax = self.OvalePower.current.maxPower[powerType] or 0
            if powerMax > 0 then
                local conversion = 100 / powerMax
                local value, origin, rate = self.OvalePower.next.power[powerType] * conversion, atTime, self.OvalePower:getPowerRateAt(self.OvalePower.next, powerType, atTime) * conversion
                if rate > 0 and value >= 100 or rate < 0 and value == 0 then
                    rate = 0
                end
                local start, ending = atTime, INFINITY
                return TestValue(start, ending, value, origin, rate, comparator, limit)
            end
        else
            local powerInfo = self.OvalePower.POWER_INFO[powerType]
            local powerMax = UnitPowerMax(target, powerInfo.id, powerInfo.segments) or 0
            if powerMax > 0 then
                local conversion = 100 / powerMax
                local value = UnitPower(target, powerInfo.id) * conversion
                return Compare(value, comparator, limit)
            end
        end
        return Compare(0, comparator, limit)
    end,
    PowerCost = function(self, powerType, positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = self:ParseCondition(positionalParams, namedParams, "target")
        local maxCost = (namedParams.max == 1)
        local value = self.OvalePower:PowerCost(spellId, powerType, atTime, target, maxCost) or 0
        return Compare(value, comparator, limit)
    end,
    Snapshot = function(self, statName, defaultValue, positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = self.OvalePaperDoll:GetState(atTime)[statName] or defaultValue
        return Compare(value, comparator, limit)
    end,
    SnapshotCritChance = function(self, statName, defaultValue, positionalParams, namedParams, atTime)
        local comparator, limit = positionalParams[1], positionalParams[2]
        local value = self.OvalePaperDoll:GetState(atTime)[statName] or defaultValue
        if namedParams.unlimited ~= 1 and value > 100 then
            value = 100
        end
        return Compare(value, comparator, limit)
    end,
    TimeToPower = function(self, powerType, level, comparator, limit, atTime)
        level = level or 0
        local power = self.OvalePower.next.power[powerType] or 0
        local powerRegen = self.OvalePower:getPowerRateAt(self.OvalePower.next, powerType, atTime) or 1
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
    end,
    TimeToPowerFor = function(self, powerType, positionalParams, namedParams, atTime)
        local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
        local target = self:ParseCondition(positionalParams, namedParams, "target")
        if  not powerType then
            local _, pt = self.OvalePower:GetSpellCost(spellId)
            powerType = pt
        end
        local seconds = self.OvalePower:TimeToPower(spellId, atTime, self.OvaleGUID:UnitGUID(target), powerType)
        if seconds == 0 then
            return Compare(0, comparator, limit)
        elseif seconds < INFINITY then
            return TestValue(0, atTime + seconds, seconds, atTime, -1, comparator, limit)
        else
            return Compare(INFINITY, comparator, limit)
        end
    end,
    ParseCondition = function(self, positionalParams, namedParams, defaultTarget)
        return self.ovaleCondition:ParseCondition(positionalParams, namedParams, defaultTarget)
    end,
    constructor = function(self, ovaleCondition, OvaleData, OvaleCompile, OvalePaperDoll, Ovale, OvaleArtifact, OvaleAzerite, OvaleAzeriteEssence, OvaleAura, baseState, OvaleCooldown, OvaleFuture, OvaleSpellBook, OvaleFrameModule, OvaleGUID, OvaleDamageTaken, OvaleWarlock, OvalePower, OvaleEnemies, variables, lastSpell, OvaleEquipment, OvaleHealth, ovaleOptions, OvaleLossOfControl, OvaleSpellDamage, OvaleStagger, OvaleTotem, OvaleSigil, OvaleDemonHunterSoulFragments, OvaleBestAction, OvaleRunes, OvaleStance, OvaleBossMod, OvaleSpells)
        self.ovaleCondition = ovaleCondition
        self.OvaleData = OvaleData
        self.OvaleCompile = OvaleCompile
        self.OvalePaperDoll = OvalePaperDoll
        self.Ovale = Ovale
        self.OvaleArtifact = OvaleArtifact
        self.OvaleAzerite = OvaleAzerite
        self.OvaleAzeriteEssence = OvaleAzeriteEssence
        self.OvaleAura = OvaleAura
        self.baseState = baseState
        self.OvaleCooldown = OvaleCooldown
        self.OvaleFuture = OvaleFuture
        self.OvaleSpellBook = OvaleSpellBook
        self.OvaleFrameModule = OvaleFrameModule
        self.OvaleGUID = OvaleGUID
        self.OvaleDamageTaken = OvaleDamageTaken
        self.OvaleWarlock = OvaleWarlock
        self.OvalePower = OvalePower
        self.OvaleEnemies = OvaleEnemies
        self.variables = variables
        self.lastSpell = lastSpell
        self.OvaleEquipment = OvaleEquipment
        self.OvaleHealth = OvaleHealth
        self.ovaleOptions = ovaleOptions
        self.OvaleLossOfControl = OvaleLossOfControl
        self.OvaleSpellDamage = OvaleSpellDamage
        self.OvaleStagger = OvaleStagger
        self.OvaleTotem = OvaleTotem
        self.OvaleSigil = OvaleSigil
        self.OvaleDemonHunterSoulFragments = OvaleDemonHunterSoulFragments
        self.OvaleBestAction = OvaleBestAction
        self.OvaleRunes = OvaleRunes
        self.OvaleStance = OvaleStance
        self.OvaleBossMod = OvaleBossMod
        self.OvaleSpells = OvaleSpells
        self.ArmorSetBonus = function(positionalParams, namedParams, atTime)
            self.Ovale:OneTimeMessage("Warning: 'ArmorSetBonus()' is depreciated.  Returns 0")
            local value = 0
            return 0, INFINITY, value, 0, 0
        end
        self.ArmorSetParts = function(positionalParams, namedParams, atTime)
            local _, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = 0
            self.Ovale:OneTimeMessage("Warning: 'ArmorSetBonus()' is depreciated.  Returns 0")
            return Compare(value, comparator, limit)
        end
        self.ArtifactTraitRank = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self.OvaleArtifact:TraitRank(spellId)
            return Compare(value, comparator, limit)
        end
        self.HasArtifactTrait = function(positionalParams, namedParams, atTime)
            local spellId, yesno = positionalParams[1], positionalParams[2]
            local value = self.OvaleArtifact:HasTrait(spellId)
            return TestBoolean(value, yesno)
        end
        self.AzeriteTraitRank = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self.OvaleAzerite:TraitRank(spellId)
            return Compare(value, comparator, limit)
        end
        self.HasAzeriteTrait = function(positionalParams, namedParams, atTime)
            local spellId, yesno = positionalParams[1], positionalParams[2]
            local value = self.OvaleAzerite:HasTrait(spellId)
            return TestBoolean(value, yesno)
        end
        self.AzeriteEssenceIsMajor = function(positionalParams, namedParams, atTime)
            local essenceId, yesno = positionalParams[1], positionalParams[2]
            local value = self.OvaleAzeriteEssence:IsMajorEssence(essenceId)
            return TestBoolean(value, yesno)
        end
        self.AzeriteEssenceIsMinor = function(positionalParams, namedParams, atTime)
            local essenceId, yesno = positionalParams[1], positionalParams[2]
            local value = self.OvaleAzeriteEssence:IsMinorEssence(essenceId)
            return TestBoolean(value, yesno)
        end
        self.AzeriteEssenceIsEnabled = function(positionalParams, namedParams, atTime)
            local essenceId, yesno = positionalParams[1], positionalParams[2]
            local value = self.OvaleAzeriteEssence:IsMajorEssence(essenceId) or self.OvaleAzeriteEssence:IsMinorEssence(essenceId)
            return TestBoolean(value, yesno)
        end
        self.AzeriteEssenceRank = function(positionalParams, namedParams, atTime)
            local essenceId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self.OvaleAzeriteEssence.self_essences[essenceId] and self.OvaleAzeriteEssence.self_essences[essenceId].rank
            return Compare(value, comparator, limit)
        end
        self.BaseDuration = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value
            if (self.OvaleData.buffSpellList[auraId]) then
                local spellList = self.OvaleData.buffSpellList[auraId]
                for id in pairs(spellList) do
                    value = self.OvaleAura:GetBaseDuration(id, self.OvalePaperDoll.next)
                    if value ~= huge then
                        break
                    end
                end
            else
                value = self.OvaleAura:GetBaseDuration(auraId, self.OvalePaperDoll.next)
            end
            return Compare(value, comparator, limit)
        end
        self.BuffAmount = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local value = namedParams.value or 1
            local statName = "value1"
            if value == 1 then
                statName = "value1"
            elseif value == 2 then
                statName = "value2"
            elseif value == 3 then
                statName = "value3"
            end
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if self.OvaleAura:IsActiveAura(aura, atTime) then
                local gain, start, ending = aura.gain, aura.start, aura.ending
                local value = aura[statName] or 0
                return TestValue(gain, ending, value, start, 0, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.BuffComboPoints = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if self.OvaleAura:IsActiveAura(aura, atTime) then
                local gain, start, ending = aura.gain, aura.start, aura.ending
                local value = aura and aura.combopoints or 0
                return TestValue(gain, ending, value, start, 0, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.BuffCooldown = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if aura then
                local gain, cooldownEnding = aura.gain, aura.cooldownEnding
                cooldownEnding = aura.cooldownEnding or 0
                return TestValue(gain, INFINITY, 0, cooldownEnding, -1, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.BuffCount = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local spellList = self.OvaleData.buffSpellList[auraId]
            local count = 0
            for id in pairs(spellList) do
                local aura = self.OvaleAura:GetAura(target, id, atTime, filter, mine)
                if self.OvaleAura:IsActiveAura(aura, atTime) then
                    count = count + 1
                end
            end
            return Compare(count, comparator, limit)
        end
        self.BuffCooldownDuration = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local minCooldown = INFINITY
            if self.OvaleData.buffSpellList[auraId] then
                for id in pairs(self.OvaleData.buffSpellList[auraId]) do
                    local si = self.OvaleData.spellInfo[id]
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
        self.BuffCountOnAny = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local _, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local excludeUnitId = (namedParams.excludeTarget == 1) and self.baseState.next.defaultTarget or nil
            local fractional = (namedParams.count == 0) and true or false
            local count, _, startChangeCount, endingChangeCount, startFirst, endingLast = self.OvaleAura:AuraCount(auraId, filter, mine, namedParams.stacks, atTime, excludeUnitId)
            if count > 0 and startChangeCount < INFINITY and fractional then
                local origin = startChangeCount
                local rate = -1 / (endingChangeCount - startChangeCount)
                local start, ending = startFirst, endingLast
                return TestValue(start, ending, count, origin, rate, comparator, limit)
            end
            return Compare(count, comparator, limit)
        end
        self.BuffDirection = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if aura then
                local gain, _, _, direction = aura.gain, aura.start, aura.ending, aura.direction
                return TestValue(gain, INFINITY, direction, gain, 0, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.BuffDuration = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if self.OvaleAura:IsActiveAura(aura, atTime) then
                local gain, start, ending = aura.gain, aura.start, aura.ending
                local value = ending - start
                return TestValue(gain, ending, value, start, 0, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.BuffExpires = function(positionalParams, namedParams, atTime)
            local auraId, seconds = positionalParams[1], positionalParams[2]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if aura then
                local gain, _, ending = aura.gain, aura.start, aura.ending
                seconds = self:GetHastedTime(seconds, namedParams.haste)
                if ending - seconds <= gain then
                    return gain, INFINITY
                else
                    return ending - seconds, INFINITY
                end
            end
            return 0, INFINITY
        end
        self.BuffPresent = function(positionalParams, namedParams, atTime)
            local auraId, seconds = positionalParams[1], positionalParams[2]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if aura then
                local gain, _, ending = aura.gain, aura.start, aura.ending
                seconds = self:GetHastedTime(seconds, namedParams.haste)
                if ending - seconds <= gain then
                    return nil
                else
                    return gain, ending - seconds
                end
            end
            return nil
        end
        self.BuffGain = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if aura then
                local gain = aura.gain or 0
                return TestValue(gain, INFINITY, 0, gain, 1, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.BuffImproved = function(positionalParams, namedParams, atTime)
            local _, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local _, _ = self:ParseCondition(positionalParams, namedParams)
            return Compare(0, comparator, limit)
        end
        self.BuffPersistentMultiplier = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if self.OvaleAura:IsActiveAura(aura, atTime) then
                local gain, start, ending = aura.gain, aura.start, aura.ending
                local value = aura.damageMultiplier or 1
                return TestValue(gain, ending, value, start, 0, comparator, limit)
            end
            return Compare(1, comparator, limit)
        end
        self.BuffRemaining = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if aura and aura.ending >= atTime then
                local gain, _, ending = aura.gain, aura.start, aura.ending
                return TestValue(gain, INFINITY, 0, ending, -1, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.BuffRemainingOnAny = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local _, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local excludeUnitId = (namedParams.excludeTarget == 1) and self.baseState.next.defaultTarget or nil
            local count, _, _, _, startFirst, endingLast = self.OvaleAura:AuraCount(auraId, filter, mine, namedParams.stacks, atTime, excludeUnitId)
            if count > 0 then
                local start, ending = startFirst, endingLast
                return TestValue(start, INFINITY, 0, ending, -1, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.BuffStacks = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if self.OvaleAura:IsActiveAura(aura, atTime) then
                local gain, start, ending = aura.gain, aura.start, aura.ending
                local value = aura.stacks or 0
                return TestValue(gain, ending, value, start, 0, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.maxStacks = function(positionalParams, namedParameters, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local maxStacks = self.OvaleData:GetSpellInfo(auraId).max_stacks
            return Compare(maxStacks, comparator, limit)
        end
        self.BuffStacksOnAny = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local _, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local excludeUnitId = (namedParams.excludeTarget == 1) and self.baseState.next.defaultTarget or nil
            local count, stacks, _, endingChangeCount, startFirst = self.OvaleAura:AuraCount(auraId, filter, mine, 1, atTime, excludeUnitId)
            if count > 0 then
                local start, ending = startFirst, endingChangeCount
                return TestValue(start, ending, stacks, start, 0, comparator, limit)
            end
            return Compare(count, comparator, limit)
        end
        self.BuffStealable = function(positionalParams, namedParams, atTime)
            local target = self:ParseCondition(positionalParams, namedParams)
            return self.OvaleAura:GetAuraWithProperty(target, "stealable", "HELPFUL", atTime)
        end
        self.CanCast = function(positionalParams, namedParams, atTime)
            local spellId = positionalParams[1]
            local start, duration = self.OvaleCooldown:GetSpellCooldown(spellId, atTime)
            return start + duration, INFINITY
        end
        self.CastTime = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local castTime = self.OvaleSpellBook:GetCastTime(spellId) or 0
            return Compare(castTime, comparator, limit)
        end
        self.ExecuteTime = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local castTime = self.OvaleSpellBook:GetCastTime(spellId) or 0
            local gcd = self.OvaleFuture:GetGCD()
            local t = (castTime > gcd) and castTime or gcd
            return Compare(t, comparator, limit)
        end
        self.Casting = function(positionalParams, namedParams, atTime)
            local spellId = positionalParams[1]
            local target = self:ParseCondition(positionalParams, namedParams)
            local start, ending, castSpellId, castSpellName
            if target == "player" then
                start = self.OvaleFuture.next.currentCast.start
                ending = self.OvaleFuture.next.currentCast.stop
                castSpellId = self.OvaleFuture.next.currentCast.spellId
                castSpellName = self.OvaleSpellBook:GetSpellName(castSpellId)
            else
                local spellName, _, _, startTime, endTime = UnitCastingInfo(target)
                if  not spellName then
                    spellName, _, _, startTime, endTime = UnitChannelInfo(target)
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
                elseif self.OvaleData.buffSpellList[spellId] then
                    for id in pairs(self.OvaleData.buffSpellList[spellId]) do
                        if id == castSpellId or self.OvaleSpellBook:GetSpellName(id) == castSpellName then
                            return start, ending
                        end
                    end
                elseif spellId == "harmful" and self.OvaleSpellBook:IsHarmfulSpell(spellId) then
                    return start, ending
                elseif spellId == "helpful" and self.OvaleSpellBook:IsHelpfulSpell(spellId) then
                    return start, ending
                elseif spellId == castSpellId then
                    Print("%f %f %d %s => %d (%f)", start, ending, castSpellId, castSpellName, spellId, self.baseState.next.currentTime)
                    return start, ending
                elseif type(spellId) == "number" and self.OvaleSpellBook:GetSpellName(spellId) == castSpellName then
                    return start, ending
                end
            end
            return nil
        end
        self.CheckBoxOff = function(positionalParams, namedParams, atTime)
            for _, id in ipairs(positionalParams) do
                if self.OvaleFrameModule.frame and self.OvaleFrameModule.frame:IsChecked(id) then
                    return nil
                end
            end
            return 0, INFINITY
        end
        self.CheckBoxOn = function(positionalParams, namedParams, atTime)
            for _, id in ipairs(positionalParams) do
                if self.OvaleFrameModule.frame and  not self.OvaleFrameModule.frame:IsChecked(id) then
                    return nil
                end
            end
            return 0, INFINITY
        end
        self.Class = function(positionalParams, namedParams, atTime)
            local className, yesno = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local _, classToken = UnitClass(target)
            local boolean = (classToken == className)
            return TestBoolean(boolean, yesno)
        end
        self.Classification = function(positionalParams, namedParams, atTime)
            local classification, yesno = positionalParams[1], positionalParams[2]
            local targetClassification
            local target = self:ParseCondition(positionalParams, namedParams)
            if UnitLevel(target) < 0 then
                targetClassification = "worldboss"
            elseif UnitExists("boss1") and self.OvaleGUID:UnitGUID(target) == self.OvaleGUID:UnitGUID("boss1") then
                targetClassification = "worldboss"
            else
                local aura = self.OvaleAura:GetAura(target, IMBUED_BUFF_ID, atTime, "HARMFUL", false)
                if self.OvaleAura:IsActiveAura(aura, atTime) then
                    targetClassification = "worldboss"
                else
                    targetClassification = UnitClassification(target)
                    -- if targetClassification == "rareelite" then
                        -- targetClassification = "elite"
                    -- elseif targetClassification == "rare" then
                        -- targetClassification = "normal"
                    -- end
                end
            end
            local boolean = (targetClassification == classification)
            return TestBoolean(boolean, yesno)
        end
        self.Counter = function(positionalParams, namedParams, atTime)
            local counter, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self.OvaleFuture:GetCounter(counter, atTime)
            return Compare(value, comparator, limit)
        end
        self.CreatureFamily = function(positionalParams, namedParams, atTime)
            local name, yesno = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local family = UnitCreatureFamily(target)
            local lookupTable = LibBabbleCreatureType and LibBabbleCreatureType:GetLookupTable()
            local boolean = (lookupTable and family == lookupTable[name])
            return TestBoolean(boolean, yesno)
        end
        self.CreatureType = function(positionalParams, namedParams, atTime)
            local target = self:ParseCondition(positionalParams, namedParams)
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
        self.CritDamage = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target = self:ParseCondition(positionalParams, namedParams, "target")
            local value = self:ComputeParameter(spellId, "damage", atTime) or 0
            local si = self.OvaleData.spellInfo[spellId]
            if si and si.physical == 1 then
                value = value * (1 - BossArmorDamageReduction(target))
            end
            local critMultiplier = 2
            do
                local aura = self.OvaleAura:GetAura("player", AMPLIFICATION, atTime, "HELPFUL")
                if self.OvaleAura:IsActiveAura(aura, atTime) then
                    critMultiplier = critMultiplier + aura.value1
                end
            end
            do
                local aura = self.OvaleAura:GetAura("player", INCREASED_CRIT_EFFECT_3_PERCENT, atTime, "HELPFUL")
                if self.OvaleAura:IsActiveAura(aura, atTime) then
                    critMultiplier = critMultiplier * aura.value1
                end
            end
            value = critMultiplier * value
            return Compare(value, comparator, limit)
        end
        self.Damage = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target = self:ParseCondition(positionalParams, namedParams, "target")
            local value = self:ComputeParameter(spellId, "damage", atTime) or 0
            local si = self.OvaleData.spellInfo[spellId]
            if si and si.physical == 1 then
                value = value * (1 - BossArmorDamageReduction(target))
            end
            return Compare(value, comparator, limit)
        end
        self.DamageTaken = function(positionalParams, namedParams, atTime)
            local interval, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = 0
            if interval > 0 then
                local total, totalMagic = self.OvaleDamageTaken:GetRecentDamage(interval)
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
        self.Demons = function(positionalParams, namedParams, atTime)
            local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self.OvaleWarlock:GetDemonsCount(creatureId, atTime)
            return Compare(value, comparator, limit)
        end
        self.NotDeDemons = function(positionalParams, namedParams, atTime)
            local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self.OvaleWarlock:GetNotDemonicEmpoweredDemonsCount(creatureId, atTime)
            return Compare(value, comparator, limit)
        end
        self.DemonDuration = function(positionalParams, namedParams, atTime)
            local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self.OvaleWarlock:GetRemainingDemonDuration(creatureId, atTime)
            return Compare(value, comparator, limit)
        end
        self.ImpsSpawnedDuring = function(positionalParams, namedParams, atTime)
            local ms, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local delay = ms / 1000
            local impsSpawned = 0
            if self.OvaleFuture.next.currentCast.spellId == HAND_OF_GULDAN_SPELL_ID then
                local soulshards = self.OvalePower.current.power["soulshards"]
                if soulshards >= 3 then
                    soulshards = 3
                end
                impsSpawned = impsSpawned + soulshards
            end
            local talented = (self.OvaleSpellBook:GetTalentPoints(INNER_DEMONS_TALENT) > 0)
            if talented then
                local value = self.OvaleWarlock:GetRemainingDemonDuration(WILD_IMP_INNER_DEMONS, atTime + delay)
                if value <= 0 then
                    impsSpawned = impsSpawned + 1
                end
            end
            return Compare(impsSpawned, comparator, limit)
        end
        self.DiseasesRemaining = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, _ = self:ParseCondition(positionalParams, namedParams)
            local talented, npAura, bpAura, ffAura = self:GetDiseases(target, atTime)
            local aura
            if talented and self.OvaleAura:IsActiveAura(npAura, atTime) then
                aura = npAura
            elseif  not talented and self.OvaleAura:IsActiveAura(bpAura, atTime) and self.OvaleAura:IsActiveAura(ffAura, atTime) then
                aura = (bpAura.ending < ffAura.ending) and bpAura or ffAura
            end
            if aura then
                local gain, _, ending = aura.gain, aura.start, aura.ending
                return TestValue(gain, INFINITY, 0, ending, -1, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.DiseasesTicking = function(positionalParams, namedParams, atTime)
            local target, _ = self:ParseCondition(positionalParams, namedParams)
            local talented, npAura, bpAura, ffAura = self:GetDiseases(target, atTime)
            local gain, ending
            if talented and npAura then
                gain, ending = npAura.gain, npAura.start, npAura.ending
            elseif  not talented and bpAura and ffAura then
                gain = (bpAura.gain > ffAura.gain) and bpAura.gain or ffAura.gain
                ending = (bpAura.ending < ffAura.ending) and bpAura.ending or ffAura.ending
            end
            if gain and ending and ending > gain then
                return gain, ending
            end
            return nil
        end
        self.DiseasesAnyTicking = function(positionalParams, namedParams, atTime)
            local target, _ = self:ParseCondition(positionalParams, namedParams)
            local talented, npAura, bpAura, ffAura = self:GetDiseases(target, atTime)
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
        self.Distance = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local value = LibRangeCheck and LibRangeCheck:GetRange(target) or 0
            return Compare(value, comparator, limit)
        end
        self.Enemies = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local value = self.OvaleEnemies.next.enemies
            if  not value then
                local useTagged = self.ovaleOptions.db.profile.apparence.taggedEnemies
                if namedParams.tagged == 0 then
                    useTagged = false
                elseif namedParams.tagged == 1 then
                    useTagged = true
                end
                value = useTagged and self.OvaleEnemies.next.taggedEnemies or self.OvaleEnemies.next.activeEnemies
            end
            if value < 1 then
                value = 1
            end
            return Compare(value, comparator, limit)
        end
        self.EnergyRegenRate = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local value = self.OvalePower:getPowerRateAt(self.OvalePower.next, "energy", atTime)
            return Compare(value, comparator, limit)
        end
        self.EnrageRemaining = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, "enrage", atTime, "HELPFUL", false)
            if aura and aura.ending >= atTime then
                local gain, _, ending = aura.gain, aura.start, aura.ending
                return TestValue(gain, INFINITY, 0, ending, -1, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.Exists = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local target = self:ParseCondition(positionalParams, namedParams)
            local boolean = UnitExists(target)
            return TestBoolean(boolean, yesno)
        end
        self.False = function(positionalParams, namedParams, atTime)
            return nil
        end
        self.FocusRegenRate = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local value = self.OvalePower:getPowerRateAt(self.OvalePower.next, "focus", atTime)
            return Compare(value, comparator, limit)
        end
        self.FocusCastingRegen = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local regenRate = self.OvalePower:getPowerRateAt(self.OvalePower.next, "focus", atTime)
            local power = 0
            local castTime = self.OvaleSpellBook:GetCastTime(spellId) or 0
            local gcd = self.OvaleFuture:GetGCD()
            local castSeconds = (castTime > gcd) and castTime or gcd
            power = power + regenRate * castSeconds
            local aura = self.OvaleAura:GetAura("player", STEADY_FOCUS, atTime, "HELPFUL", true)
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
        self.GCD = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local value = self.OvaleFuture:GetGCD()
            return Compare(value, comparator, limit)
        end
        self.GCDRemaining = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams, "target")
            if self.OvaleFuture.next.lastGCDSpellId then
                local duration = self.OvaleFuture:GetGCD(self.OvaleFuture.next.lastGCDSpellId, atTime, self.OvaleGUID:UnitGUID(target))
                local spellcast = self.lastSpell:LastInFlightSpell()
                local start = (spellcast and spellcast.start) or 0
                local ending = start + duration
                if atTime < ending then
                    return TestValue(start, INFINITY, 0, ending, -1, comparator, limit)
                end
            end
            return Compare(0, comparator, limit)
        end
        self.GetState = function(positionalParams, namedParams, atTime)
            local name, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self.variables:GetState(name)
            return Compare(value, comparator, limit)
        end
        self.GetStateDuration = function(positionalParams, namedParams, atTime)
            local name, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self.variables:GetStateDuration(name)
            return Compare(value, comparator, limit)
        end
        self.Glyph = function(positionalParams, namedParams, atTime)
            local _, yesno = positionalParams[1], positionalParams[2]
            return TestBoolean(false, yesno)
        end
        self.HasEquippedItem = function(positionalParams, namedParams, atTime)
            local itemId, yesno = positionalParams[1], positionalParams[2]
            local boolean = false
            local slotId
            if type(itemId) == "number" then
                slotId = self.OvaleEquipment:HasEquippedItem(itemId)
                if slotId then
                    boolean = true
                end
            elseif self.OvaleData.itemList[itemId] then
                for _, v in pairs(self.OvaleData.itemList[itemId]) do
                    slotId = self.OvaleEquipment:HasEquippedItem(v)
                    if slotId then
                        boolean = true
                        break
                    end
                end
            end
            return TestBoolean(boolean, yesno)
        end
        self.HasFullControlCondition = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean = HasFullControl()
            return TestBoolean(boolean, yesno)
        end
        self.HasShield = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean = self.OvaleEquipment:HasShield()
            return TestBoolean(boolean, yesno)
        end
        self.HasTrinket = function(positionalParams, namedParams, atTime)
            local trinketId, yesno = positionalParams[1], positionalParams[2]
            local boolean = nil
            if type(trinketId) == "number" then
                boolean = self.OvaleEquipment:HasTrinket(trinketId)
            elseif self.OvaleData.itemList[trinketId] then
                for _, v in pairs(self.OvaleData.itemList[trinketId]) do
                    boolean = self.OvaleEquipment:HasTrinket(v)
                    if boolean then
                        break
                    end
                end
            end
            return TestBoolean(boolean ~= nil, yesno)
        end
        self.Health = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local health = self.OvaleHealth:UnitHealth(target) or 0
            if health > 0 then
                local now = GetTime()
                local timeToDie = self.OvaleHealth:UnitTimeToDie(target)
                local value, origin, rate = health, now, -1 * health / timeToDie
                local start, ending = now, INFINITY
                return TestValue(start, ending, value, origin, rate, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.EffectiveHealth = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local health = self.OvaleHealth:UnitHealth(target) + self.OvaleHealth:UnitAbsorb(target) - self.OvaleHealth:UnitHealAbsorb(target) or 0
            local now = GetTime()
            local timeToDie = self.OvaleHealth:UnitTimeToDie(target)
            local value, origin, rate = health, now, -1 * health / timeToDie
            local start, ending = now, INFINITY
            return TestValue(start, ending, value, origin, rate, comparator, limit)
        end
        self.HealthMissing = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local health = self.OvaleHealth:UnitHealth(target) or 0
            local maxHealth = self.OvaleHealth:UnitHealthMax(target) or 1
            if health > 0 then
                local now = GetTime()
                local missing = maxHealth - health
                local timeToDie = self.OvaleHealth:UnitTimeToDie(target)
                local value, origin, rate = missing, now, health / timeToDie
                local start, ending = now, INFINITY
                return TestValue(start, ending, value, origin, rate, comparator, limit)
            end
            return Compare(maxHealth, comparator, limit)
        end
        self.HealthPercent = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local health = self.OvaleHealth:UnitHealth(target) or 0
            if health > 0 then
                local now = GetTime()
                local maxHealth = self.OvaleHealth:UnitHealthMax(target) or 1
                local healthPercent = health / maxHealth * 100
                local timeToDie = self.OvaleHealth:UnitTimeToDie(target)
                local value, origin, rate = healthPercent, now, -1 * healthPercent / timeToDie
                local start, ending = now, INFINITY
                return TestValue(start, ending, value, origin, rate, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.EffectiveHealthPercent = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local health = self.OvaleHealth:UnitHealth(target) + self.OvaleHealth:UnitAbsorb(target) - self.OvaleHealth:UnitHealAbsorb(target) or 0
            local now = GetTime()
            local maxHealth = self.OvaleHealth:UnitHealthMax(target) or 1
            local healthPercent = health / maxHealth * 100
            local timeToDie = self.OvaleHealth:UnitTimeToDie(target)
            local value, origin, rate = healthPercent, now, -1 * healthPercent / timeToDie
            local start, ending = now, INFINITY
            return TestValue(start, ending, value, origin, rate, comparator, limit)
        end
        self.MaxHealth = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local value = self.OvaleHealth:UnitHealthMax(target)
            return Compare(value, comparator, limit)
        end
        self.TimeToDie = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local now = GetTime()
            local timeToDie = self.OvaleHealth:UnitTimeToDie(target)
            local value, origin, rate = timeToDie, now, -1
            local start = now, now + timeToDie
            return TestValue(start, INFINITY, value, origin, rate, comparator, limit)
        end
        self.TimeToHealthPercent = function(positionalParams, namedParams, atTime)
            local percent, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target = self:ParseCondition(positionalParams, namedParams)
            local health = self.OvaleHealth:UnitHealth(target) or 0
            if health > 0 then
                local maxHealth = self.OvaleHealth:UnitHealthMax(target) or 1
                local healthPercent = health / maxHealth * 100
                if healthPercent >= percent then
                    local now = GetTime()
                    local timeToDie = self.OvaleHealth:UnitTimeToDie(target)
                    local t = timeToDie * (healthPercent - percent) / healthPercent
                    local value, origin, rate = t, now, -1
                    local start, ending = now, now + t
                    return TestValue(start, ending, value, origin, rate, comparator, limit)
                end
            end
            return Compare(0, comparator, limit)
        end
        self.InCombat = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean = self.OvaleFuture:IsInCombat(atTime)
            return TestBoolean(boolean, yesno)
        end
        self.InFlightToTarget = function(positionalParams, namedParams, atTime)
            local spellId, yesno = positionalParams[1], positionalParams[2]
            local boolean = (self.OvaleFuture.next.currentCast.spellId == spellId) or self.OvaleFuture:InFlight(spellId)
            return TestBoolean(boolean, yesno)
        end
        self.InRange = function(positionalParams, namedParams, atTime)
            local spellId, yesno = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local boolean = self.OvaleSpells:IsSpellInRange(spellId, target)
            return TestBoolean(boolean, yesno)
        end
        self.IsAggroed = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local target = self:ParseCondition(positionalParams, namedParams)
            local boolean = UnitDetailedThreatSituation("player", target)
            return TestBoolean(boolean, yesno)
        end
        self.IsDead = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local target = self:ParseCondition(positionalParams, namedParams)
            local boolean = UnitIsDead(target)
            return TestBoolean(boolean, yesno)
        end
        self.IsEnraged = function(positionalParams, namedParams, atTime)
            local target = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, "enrage", atTime, "HELPFUL", false)
            if aura then
                local gain, _, ending = aura.gain, aura.start, aura.ending
                return gain, ending
            end
            return nil
        end
        self.IsFeared = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean =  not HasFullControl() and self.OvaleLossOfControl.HasLossOfControl("FEAR", atTime)
            return TestBoolean(boolean, yesno)
        end
        self.IsFriend = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local target = self:ParseCondition(positionalParams, namedParams)
            local boolean = UnitIsFriend("player", target)
            return TestBoolean(boolean, yesno)
        end
        self.IsIncapacitated = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean =  not HasFullControl() and self.OvaleLossOfControl.HasLossOfControl("CONFUSE", atTime)
            return TestBoolean(boolean, yesno)
        end
        self.IsInterruptible = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local target = self:ParseCondition(positionalParams, namedParams)
            local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(target)
            if  not name then
                name, _, _, _, _, _, notInterruptible = UnitChannelInfo(target)
            end
            local boolean = notInterruptible ~= nil and  not notInterruptible
            return TestBoolean(boolean, yesno)
        end
        self.IsPVP = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local target = self:ParseCondition(positionalParams, namedParams)
            local boolean = UnitIsPVP(target)
            return TestBoolean(boolean, yesno)
        end
        self.IsRooted = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean = self.OvaleLossOfControl.HasLossOfControl("ROOT", atTime)
            return TestBoolean(boolean, yesno)
        end
        self.IsStunned = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean =  not HasFullControl() and self.OvaleLossOfControl.HasLossOfControl("STUN_MECHANIC", atTime)
            return TestBoolean(boolean, yesno)
        end
        self.ItemCharges = function(positionalParams, namedParams, atTime)
            local itemId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = GetItemCount(itemId, false, true)
            return Compare(value, comparator, limit)
        end
        self.ItemCooldown = function(positionalParams, namedParams, atTime)
            local itemId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            if itemId and type(itemId) ~= "number" then
                itemId = self.OvaleEquipment:GetEquippedItemBySlotName(itemId)
            end
            if itemId then
                local start, duration = GetItemCooldown(itemId)
                if start > 0 and duration > 0 then
                    return TestValue(start, start + duration, duration, start, -1, comparator, limit)
                end
            end
            return Compare(0, comparator, limit)
        end
        self.ItemCount = function(positionalParams, namedParams, atTime)
            local itemId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = GetItemCount(itemId)
            return Compare(value, comparator, limit)
        end
        self.LastDamage = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self.OvaleSpellDamage:Get(spellId)
            if value then
                return Compare(value, comparator, limit)
            end
            return nil
        end
        self.Level = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local value
            if target == "player" then
                value = self.OvalePaperDoll.level
            else
                value = UnitLevel(target)
            end
            return Compare(value, comparator, limit)
        end
        self.List = function(positionalParams, namedParams, atTime)
            local name, value = positionalParams[1], positionalParams[2]
            if name and self.OvaleFrameModule.frame and self.OvaleFrameModule.frame:GetListValue(name) == value then
                return 0, INFINITY
            end
            return nil
        end
        self.Name = function(positionalParams, namedParams, atTime)
            local name, yesno = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            if type(name) == "number" then
                name = self.OvaleSpellBook:GetSpellName(name)
            end
            local targetName = UnitName(target)
            local boolean = (name == targetName)
            return TestBoolean(boolean, yesno)
        end
        self.PTR = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local version, _, _, uiVersion = GetBuildInfo()
            local value = (version > "8.2.0" or uiVersion > 80200) and 1 or 0
            return Compare(value, comparator, limit)
        end
        self.PersistentMultiplier = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target = self:ParseCondition(positionalParams, namedParams, "target")
            local value = self.OvaleFuture:GetDamageMultiplier(spellId, self.OvaleGUID:UnitGUID(target), atTime)
            return Compare(value, comparator, limit)
        end
        self.PetPresent = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local name = namedParams.name
            local target = "pet"
            local boolean = UnitExists(target) and  not UnitIsDead(target) and (name == nil or name == UnitName(target))
            return TestBoolean(boolean, yesno)
        end
        self.AlternatePower = function(positionalParams, namedParams, atTime)
            return self:Power("alternate", positionalParams, namedParams, atTime)
        end
        self.AstralPower = function(positionalParams, namedParams, atTime)
            return self:Power("lunarpower", positionalParams, namedParams, atTime)
        end
        self.Chi = function(positionalParams, namedParams, atTime)
            return self:Power("chi", positionalParams, namedParams, atTime)
        end
        self.ComboPoints = function(positionalParams, namedParams, atTime)
            return self:Power("combopoints", positionalParams, namedParams, atTime)
        end
        self.Energy = function(positionalParams, namedParams, atTime)
            return self:Power("energy", positionalParams, namedParams, atTime)
        end
        self.Focus = function(positionalParams, namedParams, atTime)
            return self:Power("focus", positionalParams, namedParams, atTime)
        end
        self.Fury = function(positionalParams, namedParams, atTime)
            return self:Power("fury", positionalParams, namedParams, atTime)
        end
        self.HolyPower = function(positionalParams, namedParams, atTime)
            return self:Power("holypower", positionalParams, namedParams, atTime)
        end
        self.Insanity = function(positionalParams, namedParams, atTime)
            return self:Power("insanity", positionalParams, namedParams, atTime)
        end
        self.Mana = function(positionalParams, namedParams, atTime)
            return self:Power("mana", positionalParams, namedParams, atTime)
        end
        self.Maelstrom = function(positionalParams, namedParams, atTime)
            return self:Power("maelstrom", positionalParams, namedParams, atTime)
        end
        self.Pain = function(positionalParams, namedParams, atTime)
            return self:Power("pain", positionalParams, namedParams, atTime)
        end
        self.Rage = function(positionalParams, namedParams, atTime)
            return self:Power("rage", positionalParams, namedParams, atTime)
        end
        self.RunicPower = function(positionalParams, namedParams, atTime)
            return self:Power("runicpower", positionalParams, namedParams, atTime)
        end
        self.SoulShards = function(positionalParams, namedParams, atTime)
            return self:Power("soulshards", positionalParams, namedParams, atTime)
        end
        self.ArcaneCharges = function(positionalParams, namedParams, atTime)
            return self:Power("arcanecharges", positionalParams, namedParams, atTime)
        end
        self.AlternatePowerDeficit = function(positionalParams, namedParams, atTime)
            return self:PowerDeficit("alternate", positionalParams, namedParams, atTime)
        end
        self.AstralPowerDeficit = function(positionalParams, namedParams, atTime)
            return self:PowerDeficit("lunarpower", positionalParams, namedParams, atTime)
        end
        self.ChiDeficit = function(positionalParams, namedParams, atTime)
            return self:PowerDeficit("chi", positionalParams, namedParams, atTime)
        end
        self.ComboPointsDeficit = function(positionalParams, namedParams, atTime)
            return self:PowerDeficit("combopoints", positionalParams, namedParams, atTime)
        end
        self.EnergyDeficit = function(positionalParams, namedParams, atTime)
            return self:PowerDeficit("energy", positionalParams, namedParams, atTime)
        end
        self.FocusDeficit = function(positionalParams, namedParams, atTime)
            return self:PowerDeficit("focus", positionalParams, namedParams, atTime)
        end
        self.FuryDeficit = function(positionalParams, namedParams, atTime)
            return self:PowerDeficit("fury", positionalParams, namedParams, atTime)
        end
        self.HolyPowerDeficit = function(positionalParams, namedParams, atTime)
            return self:PowerDeficit("holypower", positionalParams, namedParams, atTime)
        end
        self.ManaDeficit = function(positionalParams, namedParams, atTime)
            return self:PowerDeficit("mana", positionalParams, namedParams, atTime)
        end
        self.PainDeficit = function(positionalParams, namedParams, atTime)
            return self:PowerDeficit("pain", positionalParams, namedParams, atTime)
        end
        self.RageDeficit = function(positionalParams, namedParams, atTime)
            return self:PowerDeficit("rage", positionalParams, namedParams, atTime)
        end
        self.RunicPowerDeficit = function(positionalParams, namedParams, atTime)
            return self:PowerDeficit("runicpower", positionalParams, namedParams, atTime)
        end
        self.SoulShardsDeficit = function(positionalParams, namedParams, atTime)
            return self:PowerDeficit("soulshards", positionalParams, namedParams, atTime)
        end
        self.ManaPercent = function(positionalParams, namedParams, atTime)
            return self:PowerPercent("mana", positionalParams, namedParams, atTime)
        end
        self.MaxAlternatePower = function(positionalParams, namedParams, atTime)
            return self:MaxPower("alternate", positionalParams, namedParams, atTime)
        end
        self.MaxChi = function(positionalParams, namedParams, atTime)
            return self:MaxPower("chi", positionalParams, namedParams, atTime)
        end
        self.MaxComboPoints = function(positionalParams, namedParams, atTime)
            return self:MaxPower("combopoints", positionalParams, namedParams, atTime)
        end
        self.MaxEnergy = function(positionalParams, namedParams, atTime)
            return self:MaxPower("energy", positionalParams, namedParams, atTime)
        end
        self.MaxFocus = function(positionalParams, namedParams, atTime)
            return self:MaxPower("focus", positionalParams, namedParams, atTime)
        end
        self.MaxFury = function(positionalParams, namedParams, atTime)
            return self:MaxPower("fury", positionalParams, namedParams, atTime)
        end
        self.MaxHolyPower = function(positionalParams, namedParams, atTime)
            return self:MaxPower("holypower", positionalParams, namedParams, atTime)
        end
        self.MaxMana = function(positionalParams, namedParams, atTime)
            return self:MaxPower("mana", positionalParams, namedParams, atTime)
        end
        self.MaxPain = function(positionalParams, namedParams, atTime)
            return self:MaxPower("pain", positionalParams, namedParams, atTime)
        end
        self.MaxRage = function(positionalParams, namedParams, atTime)
            return self:MaxPower("rage", positionalParams, namedParams, atTime)
        end
        self.MaxRunicPower = function(positionalParams, namedParams, atTime)
            return self:MaxPower("runicpower", positionalParams, namedParams, atTime)
        end
        self.MaxSoulShards = function(positionalParams, namedParams, atTime)
            return self:MaxPower("soulshards", positionalParams, namedParams, atTime)
        end
        self.MaxArcaneCharges = function(positionalParams, namedParams, atTime)
            return self:MaxPower("arcanecharges", positionalParams, namedParams, atTime)
        end
        self.EnergyCost = function(positionalParams, namedParams, atTime)
            return self:PowerCost("energy", positionalParams, namedParams, atTime)
        end
        self.FocusCost = function(positionalParams, namedParams, atTime)
            return self:PowerCost("focus", positionalParams, namedParams, atTime)
        end
        self.ManaCost = function(positionalParams, namedParams, atTime)
            return self:PowerCost("mana", positionalParams, namedParams, atTime)
        end
        self.RageCost = function(positionalParams, namedParams, atTime)
            return self:PowerCost("rage", positionalParams, namedParams, atTime)
        end
        self.RunicPowerCost = function(positionalParams, namedParams, atTime)
            return self:PowerCost("runicpower", positionalParams, namedParams, atTime)
        end
        self.AstralPowerCost = function(positionalParams, namedParams, atTime)
            return self:PowerCost("lunarpower", positionalParams, namedParams, atTime)
        end
        self.MainPowerCost = function(positionalParams, namedParams, atTime)
            return self:PowerCost(self.OvalePower.current.powerType, positionalParams, namedParams, atTime)
        end
        self.Present = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local target = self:ParseCondition(positionalParams, namedParams)
            local boolean = UnitExists(target) and  not UnitIsDead(target)
            return TestBoolean(boolean, yesno)
        end
        self.PreviousGCDSpell = function(positionalParams, namedParams, atTime)
            local spellId, yesno = positionalParams[1], positionalParams[2]
            local count = namedParams.count
            local boolean
            if count and count > 1 then
                boolean = (spellId == self.OvaleFuture.next.lastGCDSpellIds[#self.OvaleFuture.next.lastGCDSpellIds - count + 2])
            else
                boolean = (spellId == self.OvaleFuture.next.lastGCDSpellId)
            end
            return TestBoolean(boolean, yesno)
        end
        self.PreviousOffGCDSpell = function(positionalParams, namedParams, atTime)
            local spellId, yesno = positionalParams[1], positionalParams[2]
            local boolean = (spellId == self.OvaleFuture.next.lastOffGCDSpellcast.spellId)
            return TestBoolean(boolean, yesno)
        end
        self.PreviousSpell = function(positionalParams, namedParams, atTime)
            local spellId, yesno = positionalParams[1], positionalParams[2]
            local boolean = (spellId == self.OvaleFuture.next.lastGCDSpellId)
            return TestBoolean(boolean, yesno)
        end
        self.RelativeLevel = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local value, level
            if target == "player" then
                level = self.OvalePaperDoll.level
            else
                level = UnitLevel(target)
            end
            if level < 0 then
                value = 3
            else
                value = level - self.OvalePaperDoll.level
            end
            return Compare(value, comparator, limit)
        end
        self.Refreshable = function(positionalParams, namedParams, atTime)
            local auraId = positionalParams[1]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if aura then
                local baseDuration = self.OvaleAura:GetBaseDuration(auraId)
                if baseDuration == INFINITY then
                    baseDuration = aura.ending - aura.start
                end
                local extensionDuration = 0.3 * baseDuration
                return aura.ending - extensionDuration, INFINITY
            end
            return 0, INFINITY
        end
        self.RemainingCastTime = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local _, _, _, startTime, endTime = UnitCastingInfo(target)
            if startTime and endTime then
                startTime = startTime / 1000
                endTime = endTime / 1000
                return TestValue(startTime, endTime, 0, endTime, -1, comparator, limit)
            end
            return nil
        end
        self.Rune = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local count, startCooldown, endCooldown = self.OvaleRunes:RuneCount(atTime)
            if startCooldown < INFINITY then
                local origin = startCooldown
                local rate = 1 / (endCooldown - startCooldown)
                local start, ending = startCooldown, INFINITY
                return TestValue(start, ending, count, origin, rate, comparator, limit)
            end
            return Compare(count, comparator, limit)
        end
        self.RuneDeficit = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local count, startCooldown, endCooldown = self.OvaleRunes:RuneDeficit(atTime)
            if startCooldown < INFINITY then
                local origin = startCooldown
                local rate = -1 / (endCooldown - startCooldown)
                local start, ending = startCooldown, INFINITY
                return TestValue(start, ending, count, origin, rate, comparator, limit)
            end
            return Compare(count, comparator, limit)
        end
        self.RuneCount = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local count, startCooldown, endCooldown = self.OvaleRunes:RuneCount(atTime)
            if startCooldown < INFINITY then
                local start, ending = startCooldown, endCooldown
                return TestValue(start, ending, count, start, 0, comparator, limit)
            end
            return Compare(count, comparator, limit)
        end
        self.TimeToRunes = function(positionalParams, namedParams, atTime)
            local runes, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local seconds = self.OvaleRunes:GetRunesCooldown(atTime, runes)
            if seconds < 0 then
                seconds = 0
            end
            return Compare(seconds, comparator, limit)
        end
        self.Agility = function(positionalParams, namedParams, atTime)
            return self:Snapshot("agility", 0, positionalParams, namedParams, atTime)
        end
        self.AttackPower = function(positionalParams, namedParams, atTime)
            return self:Snapshot("attackPower", 0, positionalParams, namedParams, atTime)
        end
        self.CritRating = function(positionalParams, namedParams, atTime)
            return self:Snapshot("critRating", 0, positionalParams, namedParams, atTime)
        end
        self.HasteRating = function(positionalParams, namedParams, atTime)
            return self:Snapshot("hasteRating", 0, positionalParams, namedParams, atTime)
        end
        self.Intellect = function(positionalParams, namedParams, atTime)
            return self:Snapshot("intellect", 0, positionalParams, namedParams, atTime)
        end
        self.MasteryEffect = function(positionalParams, namedParams, atTime)
            return self:Snapshot("masteryEffect", 0, positionalParams, namedParams, atTime)
        end
        self.MasteryRating = function(positionalParams, namedParams, atTime)
            return self:Snapshot("masteryRating", 0, positionalParams, namedParams, atTime)
        end
        self.MeleeCritChance = function(positionalParams, namedParams, atTime)
            return self:SnapshotCritChance("meleeCrit", 0, positionalParams, namedParams, atTime)
        end
        self.MeleeAttackSpeedPercent = function(positionalParams, namedParams, atTime)
            return self:Snapshot("meleeAttackSpeedPercent", 0, positionalParams, namedParams, atTime)
        end
        self.RangedCritChance = function(positionalParams, namedParams, atTime)
            return self:SnapshotCritChance("rangedCrit", 0, positionalParams, namedParams, atTime)
        end
        self.SpellCritChance = function(positionalParams, namedParams, atTime)
            return self:SnapshotCritChance("spellCrit", 0, positionalParams, namedParams, atTime)
        end
        self.SpellCastSpeedPercent = function(positionalParams, namedParams, atTime)
            return self:Snapshot("spellCastSpeedPercent", 0, positionalParams, namedParams, atTime)
        end
        self.Spellpower = function(positionalParams, namedParams, atTime)
            return self:Snapshot("spellPower", 0, positionalParams, namedParams, atTime)
        end
        self.Stamina = function(positionalParams, namedParams, atTime)
            return self:Snapshot("stamina", 0, positionalParams, namedParams, atTime)
        end
        self.Strength = function(positionalParams, namedParams, atTime)
            return self:Snapshot("strength", 0, positionalParams, namedParams, atTime)
        end
        self.Versatility = function(positionalParams, namedParams, atTime)
            return self:Snapshot("versatility", 0, positionalParams, namedParams, atTime)
        end
        self.VersatilityRating = function(positionalParams, namedParams, atTime)
            return self:Snapshot("versatilityRating", 0, positionalParams, namedParams, atTime)
        end
        self.Speed = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local value = GetUnitSpeed(target) * 100 / 7
            return Compare(value, comparator, limit)
        end
        self.SpellChargeCooldown = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local charges, maxCharges, start, duration = self.OvaleCooldown:GetSpellCharges(spellId, atTime)
            if charges and charges < maxCharges then
                return TestValue(start, start + duration, duration, start, -1, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.SpellCharges = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local charges, maxCharges, start, duration = self.OvaleCooldown:GetSpellCharges(spellId, atTime)
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
        self.SpellFullRecharge = function(positionalParams, namedParams, atTime)
            local spellId = positionalParams[1]
            local comparator = positionalParams[2]
            local limit = positionalParams[3]
            local charges, maxCharges, start, dur = self.OvaleCooldown:GetSpellCharges(spellId, atTime)
            if charges and charges < maxCharges then
                local duration = (maxCharges - charges) * dur
                local ending = start + duration
                return TestValue(start, ending, ending - start, start, -1, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.SpellCooldown = function(positionalParams, namedParams, atTime)
            local comparator, limit
            local usable = (namedParams.usable == 1)
            local target = self:ParseCondition(positionalParams, namedParams, "target")
            local earliest = INFINITY
            for i, spellId in ipairs(positionalParams) do
                if isComparator(spellId) then
                    comparator, limit = spellId, positionalParams[i + 1]
                    break
                elseif  not usable or self.OvaleSpells:IsUsableSpell(spellId, atTime, self.OvaleGUID:UnitGUID(target)) then
                    local start, duration = self.OvaleCooldown:GetSpellCooldown(spellId, atTime)
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
        self.SpellCooldownDuration = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target = self:ParseCondition(positionalParams, namedParams, "target")
            local duration = self.OvaleCooldown:GetSpellCooldownDuration(spellId, atTime, target)
            return Compare(duration, comparator, limit)
        end
        self.SpellRechargeDuration = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target = self:ParseCondition(positionalParams, namedParams, "target")
            local cd = self.OvaleCooldown:GetCD(spellId, atTime)
            local duration = cd.chargeDuration or self.OvaleCooldown:GetSpellCooldownDuration(spellId, atTime, target)
            return Compare(duration, comparator, limit)
        end
        self.SpellData = function(positionalParams, namedParams, atTime)
            local spellId, key, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3], positionalParams[4]
            local si = self.OvaleData.spellInfo[spellId]
            if si then
                local value = si[key]
                if value then
                    return Compare(value, comparator, limit)
                end
            end
            return nil
        end
        self.SpellInfoProperty = function(positionalParams, namedParams, atTime)
            local spellId, key, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3], positionalParams[4]
            local value = self.OvaleData:GetSpellInfoProperty(spellId, atTime, key, nil)
            if value then
                return Compare(value, comparator, limit)
            end
            return nil
        end
        self.SpellCount = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local spellCount = self.OvaleSpells:GetSpellCount(spellId)
            return Compare(spellCount, comparator, limit)
        end
        self.SpellKnown = function(positionalParams, namedParams, atTime)
            local spellId, yesno = positionalParams[1], positionalParams[2]
            local boolean = self.OvaleSpellBook:IsKnownSpell(spellId)
            return TestBoolean(boolean, yesno)
        end
        self.SpellMaxCharges = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local _, maxCharges, _ = self.OvaleCooldown:GetSpellCharges(spellId, atTime)
            if  not maxCharges then
                return nil
            end
            maxCharges = maxCharges or 1
            return Compare(maxCharges, comparator, limit)
        end
        self.SpellUsable = function(positionalParams, namedParams, atTime)
            local spellId, yesno = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams, "target")
            local isUsable, noMana = self.OvaleSpells:IsUsableSpell(spellId, atTime, self.OvaleGUID:UnitGUID(target))
            local boolean = isUsable or noMana
            return TestBoolean(boolean, yesno)
        end
        self.StaggerRemaining = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, HEAVY_STAGGER, atTime, "HARMFUL")
            if  not self.OvaleAura:IsActiveAura(aura, atTime) then
                aura = self.OvaleAura:GetAura(target, MODERATE_STAGGER, atTime, "HARMFUL")
            end
            if  not self.OvaleAura:IsActiveAura(aura, atTime) then
                aura = self.OvaleAura:GetAura(target, LIGHT_STAGGER, atTime, "HARMFUL")
            end
            if self.OvaleAura:IsActiveAura(aura, atTime) then
                local gain, start, ending = aura.gain, aura.start, aura.ending
                local stagger = UnitStagger(target)
                local rate = -1 * stagger / (ending - start)
                return TestValue(gain, ending, 0, ending, rate, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.StaggerTick = function(positionalParams, namedParams, atTime)
            local count, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[2]
            local damage = self.OvaleStagger:LastTickDamage(count)
            return Compare(damage, comparator, limit)
        end
        self.Stance = function(positionalParams, namedParams, atTime)
            local stance, yesno = positionalParams[1], positionalParams[2]
            local boolean = self.OvaleStance:IsStance(stance, atTime)
            return TestBoolean(boolean, yesno)
        end
        self.Stealthed = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean = self.OvaleAura:GetAura("player", "stealthed_buff", atTime, "HELPFUL") ~= nil or IsStealthed()
            return TestBoolean(boolean, yesno)
        end
        self.LastSwing = function(positionalParams, namedParams, atTime)
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
            self.Ovale:OneTimeMessage("Warning: 'LastSwing()' is not implemented.")
            return TestValue(start, INFINITY, 0, start, 1, comparator, limit)
        end
        self.NextSwing = function(positionalParams, namedParams, atTime)
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
            self.Ovale:OneTimeMessage("Warning: 'NextSwing()' is not implemented.")
            return TestValue(0, ending, 0, ending, -1, comparator, limit)
        end
        self.Talent = function(positionalParams, namedParams, atTime)
            local talentId, yesno = positionalParams[1], positionalParams[2]
            local boolean = (self.OvaleSpellBook:GetTalentPoints(talentId) > 0)
            return TestBoolean(boolean, yesno)
        end
        self.TalentPoints = function(positionalParams, namedParams, atTime)
            local talent, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self.OvaleSpellBook:GetTalentPoints(talent)
            return Compare(value, comparator, limit)
        end
        self.TargetIsPlayer = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local target = self:ParseCondition(positionalParams, namedParams)
            local boolean = UnitIsUnit("player", target .. "target")
            return TestBoolean(boolean, yesno)
        end
        self.Threat = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local target = self:ParseCondition(positionalParams, namedParams, "target")
            local _, _, value = UnitDetailedThreatSituation("player", target)
            return Compare(value, comparator, limit)
        end
        self.TickTime = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            local tickTime
            if self.OvaleAura:IsActiveAura(aura, atTime) then
                tickTime = aura.tick
            else
                tickTime = self.OvaleAura:GetTickLength(auraId, self.OvalePaperDoll.next)
            end
            if tickTime and tickTime > 0 then
                return Compare(tickTime, comparator, limit)
            end
            return Compare(INFINITY, comparator, limit)
        end
        self.CurrentTickTime = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            local tickTime
            if self.OvaleAura:IsActiveAura(aura, atTime) then
                tickTime = aura.tick
            else
                tickTime = 0
            end
            return Compare(tickTime, comparator, limit)
        end
        self.TicksRemaining = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if aura then
                local gain, _, ending, tick = aura.gain, aura.start, aura.ending, aura.tick
                if tick and tick > 0 then
                    return TestValue(gain, INFINITY, 1, ending, -1 / tick, comparator, limit)
                end
            end
            return Compare(0, comparator, limit)
        end
        self.TickTimeRemaining = function(positionalParams, namedParams, atTime)
            local auraId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local target, filter, mine = self:ParseCondition(positionalParams, namedParams)
            local aura = self.OvaleAura:GetAura(target, auraId, atTime, filter, mine)
            if self.OvaleAura:IsActiveAura(aura, atTime) then
                local lastTickTime = aura.lastTickTime or aura.start
                local tick = aura.tick or self.OvaleAura:GetTickLength(auraId, self.OvalePaperDoll.next)
                local remainingTime = tick - (atTime - lastTickTime)
                if remainingTime and remainingTime > 0 then
                    return Compare(remainingTime, comparator, limit)
                end
            end
            return Compare(0, comparator, limit)
        end
        self.TimeInCombat = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            if self.OvaleFuture:IsInCombat(atTime) then
                local start = self.OvaleFuture:GetState(atTime).combatStartTime
                return TestValue(start, INFINITY, 0, start, 1, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.TimeSincePreviousSpell = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local t = self.OvaleFuture:TimeOfLastCast(spellId, atTime)
            return TestValue(0, INFINITY, 0, t, 1, comparator, limit)
        end
        self.TimeToBloodlust = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = 3600
            return Compare(value, comparator, limit)
        end
        self.TimeToEclipse = function(positionalParams, namedParams, atTime)
            local _, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = 3600 * 24 * 7
            self.Ovale:OneTimeMessage("Warning: 'TimeToEclipse()' is not implemented.")
            return TestValue(0, INFINITY, value, atTime, -1, comparator, limit)
        end
        self.TimeToEnergy = function(positionalParams, namedParams, atTime)
            local level, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            return self:TimeToPower("energy", level, comparator, limit, atTime)
        end
        self.TimeToMaxEnergy = function(positionalParams, namedParams, atTime)
            local powerType = "energy"
            local comparator, limit = positionalParams[1], positionalParams[2]
            local level = self.OvalePower.current.maxPower[powerType] or 0
            return self:TimeToPower(powerType, level, comparator, limit, atTime)
        end
        self.TimeToFocus = function(positionalParams, namedParams, atTime)
            local level, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            return self:TimeToPower("focus", level, comparator, limit, atTime)
        end
        self.TimeToMaxFocus = function(positionalParams, namedParams, atTime)
            local powerType = "focus"
            local comparator, limit = positionalParams[1], positionalParams[2]
            local level = self.OvalePower.current.maxPower[powerType] or 0
            return self:TimeToPower(powerType, level, comparator, limit, atTime)
        end
        self.TimeToMaxMana = function(positionalParams, namedParams, atTime)
            local powerType = "mana"
            local comparator, limit = positionalParams[1], positionalParams[2]
            local level = self.OvalePower.current.maxPower[powerType] or 0
            return self:TimeToPower(powerType, level, comparator, limit, atTime)
        end
        self.TimeToEnergyFor = function(positionalParams, namedParams, atTime)
            return self:TimeToPowerFor("energy", positionalParams, namedParams, atTime)
        end
        self.TimeToFocusFor = function(positionalParams, namedParams, atTime)
            return self:TimeToPowerFor("focus", positionalParams, namedParams, atTime)
        end
        self.TimeToSpell = function(positionalParams, namedParams, atTime)
            local _, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            self.Ovale:OneTimeMessage("Warning: 'TimeToSpell()' is not implemented.")
            return TestValue(0, INFINITY, 0, atTime, -1, comparator, limit)
        end
        self.TimeWithHaste = function(positionalParams, namedParams, atTime)
            local seconds, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local haste = namedParams.haste or "spell"
            local value = self:GetHastedTime(seconds, haste)
            return Compare(value, comparator, limit)
        end
        self.TotemExpires = function(positionalParams, namedParams, atTime)
            local id, seconds = positionalParams[1], positionalParams[2]
            seconds = seconds or 0
            local count, _, ending = self.OvaleTotem:GetTotemInfo(id, atTime)
            if count > 0 then
                return ending - seconds, INFINITY
            end
            return 0, INFINITY
        end
        self.TotemPresent = function(positionalParams, namedParams, atTime)
            local id = positionalParams[1]
            local count, start, ending = self.OvaleTotem:GetTotemInfo(id, atTime)
            if count > 0 then
                return start, ending
            end
            return nil
        end
        self.TotemRemaining = function(positionalParams, namedParams, atTime)
            local id, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local count, start, ending = self.OvaleTotem:GetTotemInfo(id, atTime)
            if count > 0 then
                return TestValue(start, ending, 0, ending, -1, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.Tracking = function(positionalParams, namedParams, atTime)
            local spellId, yesno = positionalParams[1], positionalParams[2]
            local spellName = self.OvaleSpellBook:GetSpellName(spellId)
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
        self.TravelTime = function(positionalParams, namedParams, atTime)
            local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local si = spellId and self.OvaleData.spellInfo[spellId]
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
        self.True = function(positionalParams, namedParams, atTime)
            return 0, INFINITY
        end
        self.WeaponDPS = function(positionalParams, namedParams, atTime)
            local hand = positionalParams[1]
            local comparator, limit
            local value = 0
            if hand == "offhand" or hand == "off" then
                comparator, limit = positionalParams[2], positionalParams[3]
                value = self.OvalePaperDoll.current.offHandWeaponDPS
            elseif hand == "mainhand" or hand == "main" then
                comparator, limit = positionalParams[2], positionalParams[3]
                value = self.OvalePaperDoll.current.mainHandWeaponDPS
            else
                comparator, limit = positionalParams[1], positionalParams[2]
                value = self.OvalePaperDoll.current.mainHandWeaponDPS
            end
            return Compare(value, comparator, limit)
        end
        self.WeaponEnchantExpires = function(positionalParams, namedParams, atTime)
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
        self.SigilCharging = function(positionalParams, namedParams, atTime)
            local charging = false
            for _, v in ipairs(positionalParams) do
                charging = charging or self.OvaleSigil:IsSigilCharging(v, atTime)
            end
            return TestBoolean(charging, "yes")
        end
        self.IsBossFight = function(positionalParams, namedParams, atTime)
            local bossEngaged = self.OvaleFuture:IsInCombat(atTime) and self.OvaleBossMod:IsBossEngaged(atTime)
            return TestBoolean(bossEngaged, "yes")
        end
        self.Race = function(positionalParams, namedParams, atTime)
            local isRace = false
            local target = namedParams.target or "player"
            local _, targetRaceId = UnitRace(target)
            for _, v in ipairs(positionalParams) do
                isRace = isRace or (v == targetRaceId)
            end
            return TestBoolean(isRace, "yes")
        end
        self.UnitInPartyCond = function(positionalParams, namedParams, atTime)
            local target = namedParams.target or "player"
            local isTrue = UnitInParty(target)
            return TestBoolean(isTrue, "yes")
        end
        self.UnitInRaidCond = function(positionalParams, namedParams, atTime)
            local target = namedParams.target or "player"
            local raidIndex = UnitInRaid(target)
            return TestBoolean(raidIndex ~= nil, "yes")
        end
        self.SoulFragments = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local value = self.OvaleDemonHunterSoulFragments:SoulFragments(atTime)
            return Compare(value, comparator, limit)
        end
        self.TimeToShard = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local value = self.OvaleWarlock:TimeToShard(atTime)
            return Compare(value, comparator, limit)
        end
        self.HasDebuffType = function(positionalParams, namedParams, atTime)
            local target = self:ParseCondition(positionalParams, namedParams)
            for _, debuffType in ipairs(positionalParams) do
                local aura = self.OvaleAura:GetAura(target, lower(debuffType), atTime, (target == "player" and "HARMFUL" or "HELPFUL"), false)
                if aura then
                    local gain, _, ending = aura.gain, aura.start, aura.ending
                    return gain, ending
                end
            end
            return nil
        end
        self.stackTimeTo = function(positionalParams, namedParams, atTime)
            local spellId = positionalParams[1]
            local stacks = positionalParams[2]
            local direction = positionalParams[3]
            local incantersFlowBuff = self.OvaleData:GetSpellInfo(spellId)
            local tickCycle = (incantersFlowBuff.max_stacks or 5) * 2
            local posLo
            local posHi
            if direction == "up" then
                posLo = stacks
                posHi = stacks
            elseif direction == "down" then
                posLo = tickCycle - stacks + 1
                posHi = posLo
            elseif direction == "any" then
                posLo = stacks
                posHi = tickCycle - stacks + 1
            end
            local aura = self.OvaleAura:GetAura("player", spellId, atTime, "HELPFUL")
            if  not aura then
                return nil
            end
            local buffPos
            local buffStacks = aura.stacks
            if aura.direction < 0 then
                buffPos = tickCycle - buffStacks + 1
            else
                buffPos = buffStacks
            end
            if posLo == buffPos or posHi == buffPos then
                return ReturnValue(0, 0, 0)
            end
            local ticksLo = (tickCycle + posLo - buffPos) % tickCycle
            local ticksHi = (tickCycle + posHi - buffPos) % tickCycle
            local tickTime = aura.tick
            local tickRem = tickTime - (atTime - aura.lastTickTime)
            local value = tickRem + tickTime * (min(ticksLo, ticksHi) - 1)
            return ReturnValue(value, atTime, -1)
        end
		self.MustBeInterrupted = function(positionalParams, namedParams, atTime)
			local yesno = positionalParams[1]
			local target = self:ParseCondition(positionalParams, namedParams)
			local boolean = LibInterrupt:MustInterrupt(target)
			return TestBoolean(boolean, yesno)
		end
		self.HasManagedInterrupts = function(positionalParams, namedParams, atTime)
			local yesno = positionalParams[1]
			local target = self:ParseCondition(positionalParams, namedParams)
			local boolean = LibInterrupt:HasInterrupts(target)
			return TestBoolean(boolean, yesno)
		end
		self.RaidMembersWithHealthPercent = function(positionalParams, namedParams, atTime)
			local healthComparator, healthLimit, countComparator, countLimit = positionalParams[1], positionalParams[2], positionalParams[3], positionalParams[4]
			local value = 0
			for _, uid in pairs(self.OvaleData.RAID_UIDS) do
				local health = self.OvaleHealth:UnitHealth(uid) or 0
				if health > 0 then
					local maxHealth = self.OvaleHealth:UnitHealthMax(uid) or 1
					local healthPercent = health / maxHealth * 100
					if Compare(healthPercent, healthComparator, healthLimit) then
						value = value + 1
					end
				end
			end
			return Compare(value, countComparator, countLimit)
		end
		self.RaidMembersInRange = function(positionalParams, namedParams, atTime)
			local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
			local value = 0
			for _, uid in pairs(self.OvaleData.RAID_UIDS) do
				local boolean = self.OvaleSpells:IsSpellInRange(spellId, uid)
				if boolean then
					value = value + 1
				end
			end
			return Compare(value, comparator, limit)
		end
		self.PartyMembersWithHealthPercent = function(positionalParams, namedParams, atTime)
			local healthComparator, healthLimit, countComparator, countLimit = positionalParams[1], positionalParams[2], positionalParams[3], positionalParams[4]
			local value = 0
			for _, uid in pairs(self.OvaleData.PARTY_UIDS) do
				local health = self.OvaleHealth:UnitHealth(uid) or 0
				if health > 0 then
					local maxHealth = self.OvaleHealth:UnitHealthMax(uid) or 1
					local healthPercent = health / maxHealth * 100
					if Compare(healthPercent, healthComparator, healthLimit) then
						value = value + 1
					end
				end
			end
			-- Ovale:OneTimeMessage("Warning: Party members with low health: '%s'.", value)
			return Compare(value, countComparator, countLimit)
		end
		self.PartyMemberWithLowestHealth = function(positionalParams, namedParams, atTime)
			local countComparator, countLimit = positionalParams[1], positionalParams[2]
			local value = 0
			local prevHealth = 100
			for num, uid in pairs(self.OvaleData.PARTY_UIDS) do
				local health = self.OvaleHealth:UnitHealth(uid) or 0
				if health > 0 then
					local maxHealth = self.OvaleHealth:UnitHealthMax(uid) or 1
					local healthPercent = health / maxHealth * 100
					if healthPercent < prevHealth then
						prevHealth = healthPercent
						value = num
					end
				end
			end
			return Compare(value, countComparator, countLimit)
		end
		self.PartyMembersInRange = function(positionalParams, namedParams, atTime)
			local spellId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
			local value = 0
			for _, uid in pairs(self.OvaleData.PARTY_UIDS) do
				local boolean = self.OvaleSpells:IsSpellInRange(spellId, uid)
				if boolean then
					value = value + 1
				end
			end
			-- Ovale:OneTimeMessage("Warning: Party members in range: '%s'.", value)
			return Compare(value, comparator, limit)
		end
		self.PlayerIsResting = function(positionalParams, namedParams, atTime)
			local yesno = positionalParams[1]
			local boolean = IsResting()
			return TestBoolean(boolean, yesno)
		end
		self.IsFocus = function(positionalParams, namedParams, atTime)
			local yesno = positionalParams[1]
			local target = self:ParseCondition(positionalParams, namedParams)
			local boolean = UnitIsUnit("focus", target)
			return TestBoolean(boolean, yesno)
		end
		self.IsTarget = function(positionalParams, namedParams, atTime)
			local yesno = positionalParams[1]
			local target = self:ParseCondition(positionalParams, namedParams)
			local boolean = UnitIsUnit("target", target)
			return TestBoolean(boolean, yesno)
		end
		self.IsMouseover = function(positionalParams, namedParams, atTime)
			local yesno = positionalParams[1]
			local target = self:ParseCondition(positionalParams, namedParams)
			local boolean = UnitIsUnit("mouseover", target)
			return TestBoolean(boolean, yesno)
		end
		self.mounted = function(condition)
			local yesno = condition[1]
			return TestBoolean(IsMounted(), yesno)
		end
		self.falling = function(condition)
			local yesno = condition[1]
			return TestBoolean(IsFalling(), yesno)
		end
		self.canfly = function(condition)
			local yesno = condition[1]
			return TestBoolean(IsFlyableArea(), yesno)
		end
		self.flying = function(condition)
			local yesno = condition[1]
			return TestBoolean(IsFlying(), yesno)
		end
		self.instanced = function(condition)
			local yesno = condition[1]
			return TestBoolean(IsInInstance(), yesno)
		end
		self.indoors = function(condition)
			local yesno = condition[1]
			return TestBoolean(IsIndoors(), yesno)
		end
		self.outdoors = function(condition)
			local yesno = condition[1]
			return TestBoolean(IsOutdoors(), yesno)
		end
		self.wet = function(condition)
			local yesno = condition[1]
			return TestBoolean(IsSwimming(), yesno)
		end
        ovaleCondition:RegisterCondition("present", false, self.Present)
        ovaleCondition:RegisterCondition("stacktimeto", false, self.stackTimeTo)
        ovaleCondition:RegisterCondition("armorsetbonus", false, self.ArmorSetBonus)
        ovaleCondition:RegisterCondition("armorsetparts", false, self.ArmorSetParts)
        ovaleCondition:RegisterCondition("hasartifacttrait", false, self.HasArtifactTrait)
        ovaleCondition:RegisterCondition("artifacttraitrank", false, self.ArtifactTraitRank)
        ovaleCondition:RegisterCondition("hasazeritetrait", false, self.HasAzeriteTrait)
        ovaleCondition:RegisterCondition("azeritetraitrank", false, self.AzeriteTraitRank)
        ovaleCondition:RegisterCondition("azeriteessenceismajor", false, self.AzeriteEssenceIsMajor)
        ovaleCondition:RegisterCondition("azeriteessenceisminor", false, self.AzeriteEssenceIsMinor)
        ovaleCondition:RegisterCondition("azeriteessenceisenabled", false, self.AzeriteEssenceIsEnabled)
        ovaleCondition:RegisterCondition("azeriteessencerank", false, self.AzeriteEssenceRank)
        ovaleCondition:RegisterCondition("baseduration", false, self.BaseDuration)
        ovaleCondition:RegisterCondition("buffdurationifapplied", false, self.BaseDuration)
        ovaleCondition:RegisterCondition("debuffdurationifapplied", false, self.BaseDuration)
        ovaleCondition:RegisterCondition("buffamount", false, self.BuffAmount)
        ovaleCondition:RegisterCondition("debuffamount", false, self.BuffAmount)
        ovaleCondition:RegisterCondition("tickvalue", false, self.BuffAmount)
        ovaleCondition:RegisterCondition("buffcombopoints", false, self.BuffComboPoints)
        ovaleCondition:RegisterCondition("debuffcombopoints", false, self.BuffComboPoints)
        ovaleCondition:RegisterCondition("buffcooldown", false, self.BuffCooldown)
        ovaleCondition:RegisterCondition("debuffcooldown", false, self.BuffCooldown)
        ovaleCondition:RegisterCondition("buffcount", false, self.BuffCount)
        ovaleCondition:RegisterCondition("buffcooldownduration", false, self.BuffCooldownDuration)
        ovaleCondition:RegisterCondition("debuffcooldownduration", false, self.BuffCooldownDuration)
        ovaleCondition:RegisterCondition("buffcountonany", false, self.BuffCountOnAny)
        ovaleCondition:RegisterCondition("debuffcountonany", false, self.BuffCountOnAny)
        ovaleCondition:RegisterCondition("buffdirection", false, self.BuffDirection)
        ovaleCondition:RegisterCondition("debuffdirection", false, self.BuffDirection)
        ovaleCondition:RegisterCondition("buffduration", false, self.BuffDuration)
        ovaleCondition:RegisterCondition("debuffduration", false, self.BuffDuration)
        ovaleCondition:RegisterCondition("buffexpires", false, self.BuffExpires)
        ovaleCondition:RegisterCondition("debuffexpires", false, self.BuffExpires)
        ovaleCondition:RegisterCondition("buffpresent", false, self.BuffPresent)
        ovaleCondition:RegisterCondition("debuffpresent", false, self.BuffPresent)
        ovaleCondition:RegisterCondition("buffgain", false, self.BuffGain)
        ovaleCondition:RegisterCondition("debuffgain", false, self.BuffGain)
        ovaleCondition:RegisterCondition("buffimproved", false, self.BuffImproved)
        ovaleCondition:RegisterCondition("debuffimproved", false, self.BuffImproved)
        ovaleCondition:RegisterCondition("buffpersistentmultiplier", false, self.BuffPersistentMultiplier)
        ovaleCondition:RegisterCondition("debuffpersistentmultiplier", false, self.BuffPersistentMultiplier)
        ovaleCondition:RegisterCondition("buffremaining", false, self.BuffRemaining)
        ovaleCondition:RegisterCondition("debuffremaining", false, self.BuffRemaining)
        ovaleCondition:RegisterCondition("buffremains", false, self.BuffRemaining)
        ovaleCondition:RegisterCondition("debuffremains", false, self.BuffRemaining)
        ovaleCondition:RegisterCondition("buffremainingonany", false, self.BuffRemainingOnAny)
        ovaleCondition:RegisterCondition("debuffremainingonany", false, self.BuffRemainingOnAny)
        ovaleCondition:RegisterCondition("buffremainsonany", false, self.BuffRemainingOnAny)
        ovaleCondition:RegisterCondition("debuffremainsonany", false, self.BuffRemainingOnAny)
        ovaleCondition:RegisterCondition("buffstacks", false, self.BuffStacks)
        ovaleCondition:RegisterCondition("debuffstacks", false, self.BuffStacks)
        ovaleCondition:RegisterCondition("maxstacks", true, self.maxStacks)
        ovaleCondition:RegisterCondition("buffstacksonany", false, self.BuffStacksOnAny)
        ovaleCondition:RegisterCondition("debuffstacksonany", false, self.BuffStacksOnAny)
        ovaleCondition:RegisterCondition("buffstealable", false, self.BuffStealable)
        ovaleCondition:RegisterCondition("cancast", true, self.CanCast)
        ovaleCondition:RegisterCondition("casttime", true, self.CastTime)
        ovaleCondition:RegisterCondition("executetime", true, self.ExecuteTime)
        ovaleCondition:RegisterCondition("casting", false, self.Casting)
        ovaleCondition:RegisterCondition("checkboxoff", false, self.CheckBoxOff)
        ovaleCondition:RegisterCondition("checkboxon", false, self.CheckBoxOn)
        ovaleCondition:RegisterCondition("class", false, self.Class)
        ovaleCondition:RegisterCondition("classification", false, self.Classification)
        ovaleCondition:RegisterCondition("counter", false, self.Counter)
        ovaleCondition:RegisterCondition("creaturefamily", false, self.CreatureFamily)
        ovaleCondition:RegisterCondition("creaturetype", false, self.CreatureType)
        ovaleCondition:RegisterCondition("critdamage", false, self.CritDamage)
        ovaleCondition:RegisterCondition("damage", false, self.Damage)
        ovaleCondition:RegisterCondition("damagetaken", false, self.DamageTaken)
        ovaleCondition:RegisterCondition("incomingdamage", false, self.DamageTaken)
        ovaleCondition:RegisterCondition("demons", false, self.Demons)
        ovaleCondition:RegisterCondition("notdedemons", false, self.NotDeDemons)
        ovaleCondition:RegisterCondition("demonduration", false, self.DemonDuration)
        ovaleCondition:RegisterCondition("impsspawnedduring", false, self.ImpsSpawnedDuring)
        ovaleCondition:RegisterCondition("diseasesremaining", false, self.DiseasesRemaining)
        ovaleCondition:RegisterCondition("diseasesticking", false, self.DiseasesTicking)
        ovaleCondition:RegisterCondition("diseasesanyticking", false, self.DiseasesAnyTicking)
        ovaleCondition:RegisterCondition("distance", false, self.Distance)
        ovaleCondition:RegisterCondition("enemies", false, self.Enemies)
        ovaleCondition:RegisterCondition("energyregen", false, self.EnergyRegenRate)
        ovaleCondition:RegisterCondition("energyregenrate", false, self.EnergyRegenRate)
        ovaleCondition:RegisterCondition("enrageremaining", false, self.EnrageRemaining)
        ovaleCondition:RegisterCondition("exists", false, self.Exists)
        ovaleCondition:RegisterCondition("false", false, self.False)
        ovaleCondition:RegisterCondition("focusregen", false, self.FocusRegenRate)
        ovaleCondition:RegisterCondition("focusregenrate", false, self.FocusRegenRate)
        ovaleCondition:RegisterCondition("focuscastingregen", false, self.FocusCastingRegen)
        ovaleCondition:RegisterCondition("gcd", false, self.GCD)
        ovaleCondition:RegisterCondition("gcdremaining", false, self.GCDRemaining)
        ovaleCondition:RegisterCondition("getstate", false, self.GetState)
        ovaleCondition:RegisterCondition("getstateduration", false, self.GetStateDuration)
        ovaleCondition:RegisterCondition("glyph", false, self.Glyph)
        ovaleCondition:RegisterCondition("hasequippeditem", false, self.HasEquippedItem)
        ovaleCondition:RegisterCondition("hasfullcontrol", false, self.HasFullControlCondition)
        ovaleCondition:RegisterCondition("hasshield", false, self.HasShield)
        ovaleCondition:RegisterCondition("hastrinket", false, self.HasTrinket)
        ovaleCondition:RegisterCondition("health", false, self.Health)
        ovaleCondition:RegisterCondition("life", false, self.Health)
        ovaleCondition:RegisterCondition("effectivehealth", false, self.EffectiveHealth)
        ovaleCondition:RegisterCondition("healthmissing", false, self.HealthMissing)
        ovaleCondition:RegisterCondition("lifemissing", false, self.HealthMissing)
        ovaleCondition:RegisterCondition("healthpercent", false, self.HealthPercent)
        ovaleCondition:RegisterCondition("lifepercent", false, self.HealthPercent)
        ovaleCondition:RegisterCondition("effectivehealthpercent", false, self.EffectiveHealthPercent)
        ovaleCondition:RegisterCondition("maxhealth", false, self.MaxHealth)
        ovaleCondition:RegisterCondition("deadin", false, self.TimeToDie)
        ovaleCondition:RegisterCondition("timetodie", false, self.TimeToDie)
        ovaleCondition:RegisterCondition("timetohealthpercent", false, self.TimeToHealthPercent)
        ovaleCondition:RegisterCondition("timetolifepercent", false, self.TimeToHealthPercent)
        ovaleCondition:RegisterCondition("incombat", false, self.InCombat)
        ovaleCondition:RegisterCondition("inflighttotarget", false, self.InFlightToTarget)
        ovaleCondition:RegisterCondition("inrange", false, self.InRange)
        ovaleCondition:RegisterCondition("isaggroed", false, self.IsAggroed)
        ovaleCondition:RegisterCondition("isdead", false, self.IsDead)
        ovaleCondition:RegisterCondition("isenraged", false, self.IsEnraged)
        ovaleCondition:RegisterCondition("isfeared", false, self.IsFeared)
        ovaleCondition:RegisterCondition("isfriend", false, self.IsFriend)
        ovaleCondition:RegisterCondition("isincapacitated", false, self.IsIncapacitated)
        ovaleCondition:RegisterCondition("isinterruptible", false, self.IsInterruptible)
        ovaleCondition:RegisterCondition("ispvp", false, self.IsPVP)
        ovaleCondition:RegisterCondition("isrooted", false, self.IsRooted)
        ovaleCondition:RegisterCondition("isstunned", false, self.IsStunned)
        ovaleCondition:RegisterCondition("itemcharges", false, self.ItemCharges)
        ovaleCondition:RegisterCondition("itemcooldown", false, self.ItemCooldown)
        ovaleCondition:RegisterCondition("itemcount", false, self.ItemCount)
        ovaleCondition:RegisterCondition("lastdamage", false, self.LastDamage)
        ovaleCondition:RegisterCondition("lastspelldamage", false, self.LastDamage)
        ovaleCondition:RegisterCondition("level", false, self.Level)
        ovaleCondition:RegisterCondition("list", false, self.List)
        ovaleCondition:RegisterCondition("name", false, self.Name)
        ovaleCondition:RegisterCondition("ptr", false, self.PTR)
        ovaleCondition:RegisterCondition("persistentmultiplier", false, self.PersistentMultiplier)
        ovaleCondition:RegisterCondition("petpresent", false, self.PetPresent)
        ovaleCondition:RegisterCondition("alternatepower", false, self.AlternatePower)
        ovaleCondition:RegisterCondition("arcanecharges", false, self.ArcaneCharges)
        ovaleCondition:RegisterCondition("astralpower", false, self.AstralPower)
        ovaleCondition:RegisterCondition("chi", false, self.Chi)
        ovaleCondition:RegisterCondition("combopoints", false, self.ComboPoints)
        ovaleCondition:RegisterCondition("energy", false, self.Energy)
        ovaleCondition:RegisterCondition("focus", false, self.Focus)
        ovaleCondition:RegisterCondition("fury", false, self.Fury)
        ovaleCondition:RegisterCondition("holypower", false, self.HolyPower)
        ovaleCondition:RegisterCondition("insanity", false, self.Insanity)
        ovaleCondition:RegisterCondition("maelstrom", false, self.Maelstrom)
        ovaleCondition:RegisterCondition("mana", false, self.Mana)
        ovaleCondition:RegisterCondition("pain", false, self.Pain)
        ovaleCondition:RegisterCondition("rage", false, self.Rage)
        ovaleCondition:RegisterCondition("runicpower", false, self.RunicPower)
        ovaleCondition:RegisterCondition("soulshards", false, self.SoulShards)
        ovaleCondition:RegisterCondition("alternatepowerdeficit", false, self.AlternatePowerDeficit)
        ovaleCondition:RegisterCondition("astralpowerdeficit", false, self.AstralPowerDeficit)
        ovaleCondition:RegisterCondition("chideficit", false, self.ChiDeficit)
        ovaleCondition:RegisterCondition("combopointsdeficit", false, self.ComboPointsDeficit)
        ovaleCondition:RegisterCondition("energydeficit", false, self.EnergyDeficit)
        ovaleCondition:RegisterCondition("focusdeficit", false, self.FocusDeficit)
        ovaleCondition:RegisterCondition("furydeficit", false, self.FuryDeficit)
        ovaleCondition:RegisterCondition("holypowerdeficit", false, self.HolyPowerDeficit)
        ovaleCondition:RegisterCondition("manadeficit", false, self.ManaDeficit)
        ovaleCondition:RegisterCondition("paindeficit", false, self.PainDeficit)
        ovaleCondition:RegisterCondition("ragedeficit", false, self.RageDeficit)
        ovaleCondition:RegisterCondition("runicpowerdeficit", false, self.RunicPowerDeficit)
        ovaleCondition:RegisterCondition("soulshardsdeficit", false, self.SoulShardsDeficit)
        ovaleCondition:RegisterCondition("manapercent", false, self.ManaPercent)
        ovaleCondition:RegisterCondition("maxalternatepower", false, self.MaxAlternatePower)
        ovaleCondition:RegisterCondition("maxarcanecharges", false, self.MaxArcaneCharges)
        ovaleCondition:RegisterCondition("maxchi", false, self.MaxChi)
        ovaleCondition:RegisterCondition("maxcombopoints", false, self.MaxComboPoints)
        ovaleCondition:RegisterCondition("maxenergy", false, self.MaxEnergy)
        ovaleCondition:RegisterCondition("maxfocus", false, self.MaxFocus)
        ovaleCondition:RegisterCondition("maxfury", false, self.MaxFury)
        ovaleCondition:RegisterCondition("maxholypower", false, self.MaxHolyPower)
        ovaleCondition:RegisterCondition("maxmana", false, self.MaxMana)
        ovaleCondition:RegisterCondition("maxpain", false, self.MaxPain)
        ovaleCondition:RegisterCondition("maxrage", false, self.MaxRage)
        ovaleCondition:RegisterCondition("maxrunicpower", false, self.MaxRunicPower)
        ovaleCondition:RegisterCondition("maxsoulshards", false, self.MaxSoulShards)
        ovaleCondition:RegisterCondition("powercost", true, self.MainPowerCost)
        ovaleCondition:RegisterCondition("astralpowercost", true, self.AstralPowerCost)
        ovaleCondition:RegisterCondition("energycost", true, self.EnergyCost)
        ovaleCondition:RegisterCondition("focuscost", true, self.FocusCost)
        ovaleCondition:RegisterCondition("manacost", true, self.ManaCost)
        ovaleCondition:RegisterCondition("ragecost", true, self.RageCost)
        ovaleCondition:RegisterCondition("runicpowercost", true, self.RunicPowerCost)
        ovaleCondition:RegisterCondition("previousgcdspell", true, self.PreviousGCDSpell)
        ovaleCondition:RegisterCondition("previousoffgcdspell", true, self.PreviousOffGCDSpell)
        ovaleCondition:RegisterCondition("previousspell", true, self.PreviousSpell)
        ovaleCondition:RegisterCondition("relativelevel", false, self.RelativeLevel)
        ovaleCondition:RegisterCondition("refreshable", false, self.Refreshable)
        ovaleCondition:RegisterCondition("debuffrefreshable", false, self.Refreshable)
        ovaleCondition:RegisterCondition("buffrefreshable", false, self.Refreshable)
        ovaleCondition:RegisterCondition("remainingcasttime", false, self.RemainingCastTime)
        ovaleCondition:RegisterCondition("rune", false, self.Rune)
        ovaleCondition:RegisterCondition("runecount", false, self.RuneCount)
        ovaleCondition:RegisterCondition("timetorunes", false, self.TimeToRunes)
        ovaleCondition:RegisterCondition("runedeficit", false, self.RuneDeficit)
        ovaleCondition:RegisterCondition("agility", false, self.Agility)
        ovaleCondition:RegisterCondition("attackpower", false, self.AttackPower)
        ovaleCondition:RegisterCondition("critrating", false, self.CritRating)
        ovaleCondition:RegisterCondition("hasterating", false, self.HasteRating)
        ovaleCondition:RegisterCondition("intellect", false, self.Intellect)
        ovaleCondition:RegisterCondition("mastery", false, self.MasteryEffect)
        ovaleCondition:RegisterCondition("masteryeffect", false, self.MasteryEffect)
        ovaleCondition:RegisterCondition("masteryrating", false, self.MasteryRating)
        ovaleCondition:RegisterCondition("meleecritchance", false, self.MeleeCritChance)
        ovaleCondition:RegisterCondition("meleeattackspeedpercent", false, self.MeleeAttackSpeedPercent)
        ovaleCondition:RegisterCondition("rangedcritchance", false, self.RangedCritChance)
        ovaleCondition:RegisterCondition("spellcritchance", false, self.SpellCritChance)
        ovaleCondition:RegisterCondition("spellcastspeedpercent", false, self.SpellCastSpeedPercent)
        ovaleCondition:RegisterCondition("spellpower", false, self.Spellpower)
        ovaleCondition:RegisterCondition("stamina", false, self.Stamina)
        ovaleCondition:RegisterCondition("strength", false, self.Strength)
        ovaleCondition:RegisterCondition("versatility", false, self.Versatility)
        ovaleCondition:RegisterCondition("versatilityRating", false, self.VersatilityRating)
        ovaleCondition:RegisterCondition("speed", false, self.Speed)
        ovaleCondition:RegisterCondition("spellchargecooldown", true, self.SpellChargeCooldown)
        ovaleCondition:RegisterCondition("charges", true, self.SpellCharges)
        ovaleCondition:RegisterCondition("spellcharges", true, self.SpellCharges)
        ovaleCondition:RegisterCondition("spellfullrecharge", true, self.SpellFullRecharge)
        ovaleCondition:RegisterCondition("spellcooldown", true, self.SpellCooldown)
        ovaleCondition:RegisterCondition("spellcooldownduration", true, self.SpellCooldownDuration)
        ovaleCondition:RegisterCondition("spellrechargeduration", true, self.SpellRechargeDuration)
        ovaleCondition:RegisterCondition("spelldata", false, self.SpellData)
        ovaleCondition:RegisterCondition("spellinfoproperty", false, self.SpellInfoProperty)
        ovaleCondition:RegisterCondition("spellcount", true, self.SpellCount)
        ovaleCondition:RegisterCondition("spellknown", true, self.SpellKnown)
        ovaleCondition:RegisterCondition("spellmaxcharges", true, self.SpellMaxCharges)
        ovaleCondition:RegisterCondition("spellusable", true, self.SpellUsable)
        ovaleCondition:RegisterCondition("staggerremaining", false, self.StaggerRemaining)
        ovaleCondition:RegisterCondition("staggerremains", false, self.StaggerRemaining)
        ovaleCondition:RegisterCondition("staggertick", false, self.StaggerTick)
        ovaleCondition:RegisterCondition("stance", false, self.Stance)
        ovaleCondition:RegisterCondition("isstealthed", false, self.Stealthed)
        ovaleCondition:RegisterCondition("stealthed", false, self.Stealthed)
        ovaleCondition:RegisterCondition("lastswing", false, self.LastSwing)
        ovaleCondition:RegisterCondition("nextswing", false, self.NextSwing)
        ovaleCondition:RegisterCondition("talent", false, self.Talent)
        ovaleCondition:RegisterCondition("hastalent", false, self.Talent)
        ovaleCondition:RegisterCondition("talentpoints", false, self.TalentPoints)
        ovaleCondition:RegisterCondition("istargetingplayer", false, self.TargetIsPlayer)
        ovaleCondition:RegisterCondition("targetisplayer", false, self.TargetIsPlayer)
        ovaleCondition:RegisterCondition("threat", false, self.Threat)
        ovaleCondition:RegisterCondition("ticktime", false, self.TickTime)
        ovaleCondition:RegisterCondition("currentticktime", false, self.CurrentTickTime)
        ovaleCondition:RegisterCondition("ticksremaining", false, self.TicksRemaining)
        ovaleCondition:RegisterCondition("ticksremain", false, self.TicksRemaining)
        ovaleCondition:RegisterCondition("ticktimeremaining", false, self.TickTimeRemaining)
        ovaleCondition:RegisterCondition("timeincombat", false, self.TimeInCombat)
        ovaleCondition:RegisterCondition("timesincepreviousspell", false, self.TimeSincePreviousSpell)
        ovaleCondition:RegisterCondition("timetobloodlust", false, self.TimeToBloodlust)
        ovaleCondition:RegisterCondition("timetoeclipse", false, self.TimeToEclipse)
        ovaleCondition:RegisterCondition("timetoenergy", false, self.TimeToEnergy)
        ovaleCondition:RegisterCondition("timetofocus", false, self.TimeToFocus)
        ovaleCondition:RegisterCondition("timetomaxenergy", false, self.TimeToMaxEnergy)
        ovaleCondition:RegisterCondition("timetomaxfocus", false, self.TimeToMaxFocus)
        ovaleCondition:RegisterCondition("timetomaxmana", false, self.TimeToMaxMana)
        ovaleCondition:RegisterCondition("timetoenergyfor", true, self.TimeToEnergyFor)
        ovaleCondition:RegisterCondition("timetofocusfor", true, self.TimeToFocusFor)
        ovaleCondition:RegisterCondition("timetospell", true, self.TimeToSpell)
        ovaleCondition:RegisterCondition("timewithhaste", false, self.TimeWithHaste)
        ovaleCondition:RegisterCondition("totemexpires", false, self.TotemExpires)
        ovaleCondition:RegisterCondition("totempresent", false, self.TotemPresent)
        ovaleCondition:RegisterCondition("totemremaining", false, self.TotemRemaining)
        ovaleCondition:RegisterCondition("totemremains", false, self.TotemRemaining)
        ovaleCondition:RegisterCondition("tracking", false, self.Tracking)
        ovaleCondition:RegisterCondition("traveltime", true, self.TravelTime)
        ovaleCondition:RegisterCondition("maxtraveltime", true, self.TravelTime)
        ovaleCondition:RegisterCondition("true", false, self.True)
        ovaleCondition:RegisterCondition("weapondps", false, self.WeaponDPS)
        ovaleCondition:RegisterCondition("weaponenchantexpires", false, self.WeaponEnchantExpires)
        ovaleCondition:RegisterCondition("sigilcharging", false, self.SigilCharging)
        ovaleCondition:RegisterCondition("isbossfight", false, self.IsBossFight)
        ovaleCondition:RegisterCondition("race", false, self.Race)
        ovaleCondition:RegisterCondition("unitinparty", false, self.UnitInPartyCond)
        ovaleCondition:RegisterCondition("unitinraid", false, self.UnitInRaidCond)
        ovaleCondition:RegisterCondition("soulfragments", false, self.SoulFragments)
        ovaleCondition:RegisterCondition("timetoshard", false, self.TimeToShard)
        ovaleCondition:RegisterCondition("hasdebufftype", false, self.HasDebuffType)
		ovaleCondition:RegisterCondition("mustbeinterrupted", false, self.MustBeInterrupted)
		ovaleCondition:RegisterCondition("hasmanagedinterrupts", false, self.HasManagedInterrupts)
		ovaleCondition:RegisterCondition("raidmemberswithhealthpercent", false, self.RaidMembersWithHealthPercent)
		ovaleCondition:RegisterCondition("raidmembersinrange", false, self.RaidMembersInRange)
		ovaleCondition:RegisterCondition("partymemberswithhealthpercent", false, self.PartyMembersWithHealthPercent)
		ovaleCondition:RegisterCondition("partymemberwithlowesthealth", false, self.PartyMemberWithLowestHealth)
		ovaleCondition:RegisterCondition("partymembersinrange", false, self.PartyMembersInRange)
		ovaleCondition:RegisterCondition("playerisresting", false, self.PlayerIsResting)
		ovaleCondition:RegisterCondition("isfocus", false, self.IsFocus)
		ovaleCondition:RegisterCondition("istarget", false, self.IsTarget)
		ovaleCondition:RegisterCondition("ismouseover", false, self.IsMouseover)
		ovaleCondition:RegisterCondition("mounted", false, self.mounted)
		ovaleCondition:RegisterCondition("falling", false, self.falling)
		ovaleCondition:RegisterCondition("canfly", false, self.canfly)
		ovaleCondition:RegisterCondition("flying", false, self.flying)
		ovaleCondition:RegisterCondition("instanced", false, self.instanced)
		ovaleCondition:RegisterCondition("indoors", false, self.indoors)
		ovaleCondition:RegisterCondition("outdoors", false, self.outdoors)
		ovaleCondition:RegisterCondition("wet", false, self.wet)
    end,
})
