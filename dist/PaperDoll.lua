local __exports = LibStub:NewLibrary("ovale/PaperDoll", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Equipment = LibStub:GetLibrary("ovale/Equipment")
local OvaleEquipment = __Equipment.OvaleEquipment
local __Stance = LibStub:GetLibrary("ovale/Stance")
local OvaleStance = __Stance.OvaleStance
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __LastSpell = LibStub:GetLibrary("ovale/LastSpell")
local lastSpell = __LastSpell.lastSpell
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local pairs = pairs
local tonumber = tonumber
local type = type
local GetCombatRating = GetCombatRating
local GetCombatRatingBonus = GetCombatRatingBonus
local GetCritChance = GetCritChance
local GetMastery = GetMastery
local GetMasteryEffect = GetMasteryEffect
local GetHaste = GetHaste
local GetMeleeHaste = GetMeleeHaste
local GetRangedCritChance = GetRangedCritChance
local GetRangedHaste = GetRangedHaste
local GetSpecialization = GetSpecialization
local GetSpellBonusDamage = GetSpellBonusDamage
local GetSpellCritChance = GetSpellCritChance
local GetTime = GetTime
local UnitAttackPower = UnitAttackPower
local UnitAttackSpeed = UnitAttackSpeed
local UnitDamage = UnitDamage
local UnitRangedDamage = UnitRangedDamage
local UnitLevel = UnitLevel
local UnitRangedAttackPower = UnitRangedAttackPower
local UnitSpellHaste = UnitSpellHaste
local UnitStat = UnitStat
local CR_CRIT_MELEE = CR_CRIT_MELEE
local CR_HASTE_MELEE = CR_HASTE_MELEE
local CR_VERSATILITY_DAMAGE_DONE = CR_VERSATILITY_DAMAGE_DONE
local OVALE_SPELLDAMAGE_SCHOOL = {
    DEATHKNIGHT = 4,
    DEMONHUNTER = 3,
    DRUID = 4,
    HUNTER = 4,
    MAGE = 5,
    MONK = 4,
    PALADIN = 2,
    PRIEST = 2,
    ROGUE = 4,
    SHAMAN = 4,
    WARLOCK = 6,
    WARRIOR = 4
}
local OVALE_SPECIALIZATION_NAME = {
    DEATHKNIGHT = {
        [1] = "blood",
        [2] = "frost",
        [3] = "unholy"
    },
    DEMONHUNTER = {
        [1] = "havoc",
        [2] = "vengeance"
    },
    DRUID = {
        [1] = "balance",
        [2] = "feral",
        [3] = "guardian",
        [4] = "restoration"
    },
    HUNTER = {
        [1] = "beast_mastery",
        [2] = "marksmanship",
        [3] = "survival"
    },
    MAGE = {
        [1] = "arcane",
        [2] = "fire",
        [3] = "frost"
    },
    MONK = {
        [1] = "brewmaster",
        [2] = "mistweaver",
        [3] = "windwalker"
    },
    PALADIN = {
        [1] = "holy",
        [2] = "protection",
        [3] = "retribution"
    },
    PRIEST = {
        [1] = "discipline",
        [2] = "holy",
        [3] = "shadow"
    },
    ROGUE = {
        [1] = "assassination",
        [2] = "outlaw",
        [3] = "subtlety"
    },
    SHAMAN = {
        [1] = "elemental",
        [2] = "enhancement",
        [3] = "restoration"
    },
    WARLOCK = {
        [1] = "affliction",
        [2] = "demonology",
        [3] = "destruction"
    },
    WARRIOR = {
        [1] = "arms",
        [2] = "fury",
        [3] = "protection"
    }
}
local GetAppropriateDamage = function(unit)
    if OvaleEquipment:HasRangedWeapon() then
        local _, minDamage, maxDamage, _, _, percent = UnitRangedDamage(unit)
        return minDamage, maxDamage, nil, nil, 0, 0, percent
    else
        return UnitDamage(unit)
    end
end

__exports.PaperDollData = __class(nil, {
    constructor = function(self)
        self.snapshotTime = 0
        self.strength = 0
        self.agility = 0
        self.stamina = 0
        self.intellect = 0
        self.attackPower = 0
        self.spellPower = 0
        self.critRating = 0
        self.meleeCrit = 0
        self.rangedCrit = 0
        self.spellCrit = 0
        self.hasteRating = 0
        self.hastePercent = 0
        self.meleeAttackSpeedPercent = 0
        self.rangedAttackSpeedPercent = 0
        self.spellCastSpeedPercent = 0
        self.masteryRating = 0
        self.masteryEffect = 0
        self.versatilityRating = 0
        self.versatility = 0
        self.mainHandWeaponDPS = 0
        self.offHandWeaponDPS = 0
        self.baseDamageMultiplier = 1
    end
})
local OvalePaperDollBase = OvaleState:RegisterHasState(OvaleDebug:RegisterDebugging(OvaleProfiler:RegisterProfiling(Ovale:NewModule("OvalePaperDoll", aceEvent))), __exports.PaperDollData)
local OvalePaperDollClass = __class(OvalePaperDollBase, {
    OnInitialize = function(self)
        self:RegisterEvent("COMBAT_RATING_UPDATE")
        self:RegisterEvent("MASTERY_UPDATE")
        self:RegisterEvent("PLAYER_ALIVE", "UpdateStats")
        self:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStats")
        self:RegisterEvent("PLAYER_LEVEL_UP")
        self:RegisterEvent("SPELL_POWER_CHANGED")
        self:RegisterEvent("UNIT_ATTACK_POWER")
        self:RegisterEvent("UNIT_DAMAGE", "UpdateDamage")
        self:RegisterEvent("UNIT_LEVEL")
        self:RegisterEvent("UNIT_RANGEDDAMAGE")
        self:RegisterEvent("UNIT_RANGED_ATTACK_POWER")
        self:RegisterEvent("UNIT_SPELL_HASTE")
        self:RegisterEvent("UNIT_STATS")
        self:RegisterMessage("Ovale_EquipmentChanged", "UpdateDamage")
        self:RegisterMessage("Ovale_StanceChanged", "UpdateDamage")
        self:RegisterMessage("Ovale_TalentsChanged", "UpdateStats")
        lastSpell:RegisterSpellcastInfo(self)
    end,
    OnDisable = function(self)
        lastSpell:UnregisterSpellcastInfo(self)
        self:UnregisterEvent("COMBAT_RATING_UPDATE")
        self:UnregisterEvent("MASTERY_UPDATE")
        self:UnregisterEvent("PLAYER_ALIVE")
        self:UnregisterEvent("PLAYER_DAMAGE_DONE_MODS")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("PLAYER_LEVEL_UP")
        self:UnregisterEvent("SPELL_POWER_CHANGED")
        self:UnregisterEvent("UNIT_ATTACK_POWER")
        self:UnregisterEvent("UNIT_DAMAGE")
        self:UnregisterEvent("UNIT_LEVEL")
        self:UnregisterEvent("UNIT_RANGEDDAMAGE")
        self:UnregisterEvent("UNIT_RANGED_ATTACK_POWER")
        self:UnregisterEvent("UNIT_SPELL_HASTE")
        self:UnregisterEvent("UNIT_STATS")
        self:UnregisterMessage("Ovale_EquipmentChanged")
        self:UnregisterMessage("Ovale_StanceChanged")
        self:UnregisterMessage("Ovale_TalentsChanged")
    end,
    COMBAT_RATING_UPDATE = function(self, event)
        self:StartProfiling("OvalePaperDoll_UpdateStats")
        self.current.meleeCrit = GetCritChance()
        self.current.rangedCrit = GetRangedCritChance()
        self.current.spellCrit = GetSpellCritChance(OVALE_SPELLDAMAGE_SCHOOL[self.class])
        self.current.critRating = GetCombatRating(CR_CRIT_MELEE)
        self.current.hasteRating = GetCombatRating(CR_HASTE_MELEE)
        self.current.hastePercent = GetHaste()
        self.current.versatilityRating = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE)
        self.current.versatility = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
        self.current.snapshotTime = GetTime()
        Ovale:needRefresh()
        self:StopProfiling("OvalePaperDoll_UpdateStats")
    end,
    MASTERY_UPDATE = function(self, event)
        self:StartProfiling("OvalePaperDoll_UpdateStats")
        self.current.masteryRating = GetMastery()
        if self.level < 80 then
            self.current.masteryEffect = 0
        else
            self.current.masteryEffect = GetMasteryEffect()
            Ovale:needRefresh()
        end
        self.current.snapshotTime = GetTime()
        self:StopProfiling("OvalePaperDoll_UpdateStats")
    end,
    PLAYER_LEVEL_UP = function(self, event, level, ...)
        self:StartProfiling("OvalePaperDoll_UpdateStats")
        self.level = tonumber(level) or UnitLevel("player")
        self.current.snapshotTime = GetTime()
        Ovale:needRefresh()
        self:DebugTimestamp("%s: level = %d", event, self.level)
        self:StopProfiling("OvalePaperDoll_UpdateStats")
    end,
    PLAYER_DAMAGE_DONE_MODS = function(self, event, unitId)
        self:StartProfiling("OvalePaperDoll_UpdateStats")
        self.current.spellPower = GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[self.class])
        self.current.snapshotTime = GetTime()
        Ovale:needRefresh()
        self:StopProfiling("OvalePaperDoll_UpdateStats")
    end,
    SPELL_POWER_CHANGED = function(self, event)
        self:StartProfiling("OvalePaperDoll_UpdateStats")
        self.current.spellPower = GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[self.class])
        self.current.snapshotTime = GetTime()
        Ovale:needRefresh()
        self:StopProfiling("OvalePaperDoll_UpdateStats")
    end,
    UNIT_ATTACK_POWER = function(self, event, unitId)
        if unitId == "player" and  not OvaleEquipment:HasRangedWeapon() then
            self:StartProfiling("OvalePaperDoll_UpdateStats")
            local base, posBuff, negBuff = UnitAttackPower(unitId)
            self.current.attackPower = base + posBuff + negBuff
            self.current.snapshotTime = GetTime()
            Ovale:needRefresh()
            self:UpdateDamage(event)
            self:StopProfiling("OvalePaperDoll_UpdateStats")
        end
    end,
    UNIT_LEVEL = function(self, event, unitId)
        Ovale.refreshNeeded[unitId] = true
        if unitId == "player" then
            self:StartProfiling("OvalePaperDoll_UpdateStats")
            self.level = UnitLevel(unitId)
            self:DebugTimestamp("%s: level = %d", event, self.level)
            self.current.snapshotTime = GetTime()
            self:StopProfiling("OvalePaperDoll_UpdateStats")
        end
    end,
    UNIT_RANGEDDAMAGE = function(self, event, unitId)
        if unitId == "player" then
            self:StartProfiling("OvalePaperDoll_UpdateStats")
            self.current.rangedAttackSpeedPercent = GetRangedHaste()
            self.current.snapshotTime = GetTime()
            Ovale:needRefresh()
            self:StopProfiling("OvalePaperDoll_UpdateStats")
        end
    end,
    UNIT_RANGED_ATTACK_POWER = function(self, event, unitId)
        if unitId == "player" then
            self:StartProfiling("OvalePaperDoll_UpdateStats")
            local base, posBuff, negBuff = UnitRangedAttackPower(unitId)
            Ovale:needRefresh()
            self.current.attackPower = base + posBuff + negBuff
            self.current.snapshotTime = GetTime()
            self:StopProfiling("OvalePaperDoll_UpdateStats")
        end
    end,
    UNIT_SPELL_HASTE = function(self, event, unitId)
        if unitId == "player" then
            self:StartProfiling("OvalePaperDoll_UpdateStats")
            self.current.meleeAttackSpeedPercent = GetMeleeHaste()
            self.current.spellCastSpeedPercent = UnitSpellHaste(unitId)
            self.current.snapshotTime = GetTime()
            Ovale:needRefresh()
            self:UpdateDamage(event)
            self:StopProfiling("OvalePaperDoll_UpdateStats")
        end
    end,
    UNIT_STATS = function(self, event, unitId)
        if unitId == "player" then
            self:StartProfiling("OvalePaperDoll_UpdateStats")
            self.current.strength = UnitStat(unitId, 1)
            self.current.agility = UnitStat(unitId, 2)
            self.current.stamina = UnitStat(unitId, 3)
            self.current.intellect = UnitStat(unitId, 4)
            self.current.snapshotTime = GetTime()
            Ovale:needRefresh()
            self:StopProfiling("OvalePaperDoll_UpdateStats")
        end
    end,
    UpdateDamage = function(self, event)
        self:StartProfiling("OvalePaperDoll_UpdateDamage")
        local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, _, _, damageMultiplier = GetAppropriateDamage("player")
        local mainHandAttackSpeed, offHandAttackSpeed = UnitAttackSpeed("player")
        if damageMultiplier == 0 or mainHandAttackSpeed == 0 then
            return 
        end
        self.current.baseDamageMultiplier = damageMultiplier
        if self.class == "DRUID" and OvaleStance:IsStance("druid_cat_form", nil) then
            damageMultiplier = damageMultiplier * 1.4
        end
        self.current.mainHandWeaponDPS = (minDamage + maxDamage) * 0.5 / damageMultiplier / mainHandAttackSpeed
        if offHandAttackSpeed then
            self.current.offHandWeaponDPS = (minOffHandDamage + maxOffHandDamage) * 0.5 / damageMultiplier / offHandAttackSpeed
        else
            self.current.offHandWeaponDPS = 0
        end
        self.current.snapshotTime = GetTime()
        Ovale:needRefresh()
        self:StopProfiling("OvalePaperDoll_UpdateDamage")
    end,
    UpdateSpecialization = function(self, event)
        self:StartProfiling("OvalePaperDoll_UpdateSpecialization")
        local newSpecialization = GetSpecialization()
        if self.specialization ~= newSpecialization then
            local oldSpecialization = self.specialization
            self.specialization = newSpecialization
            self.current.snapshotTime = GetTime()
            Ovale:needRefresh()
            self:SendMessage("Ovale_SpecializationChanged", self:GetSpecialization(newSpecialization), self:GetSpecialization(oldSpecialization))
        end
        self:StopProfiling("OvalePaperDoll_UpdateSpecialization")
    end,
    UpdateStats = function(self, event)
        self:UpdateSpecialization(event)
        self:COMBAT_RATING_UPDATE(event)
        self:MASTERY_UPDATE(event)
        self:PLAYER_DAMAGE_DONE_MODS(event, "player")
        self:SPELL_POWER_CHANGED(event)
        self:UNIT_ATTACK_POWER(event, "player")
        self:UNIT_RANGEDDAMAGE(event, "player")
        self:UNIT_RANGED_ATTACK_POWER(event, "player")
        self:UNIT_SPELL_HASTE(event, "player")
        self:UNIT_STATS(event, "player")
        self:UpdateDamage(event)
    end,
    GetSpecialization = function(self, specialization)
        specialization = specialization or self.specialization
        return OVALE_SPECIALIZATION_NAME[self.class][specialization]
    end,
    IsSpecialization = function(self, name)
        if name and self.specialization then
            if type(name) == "number" then
                return name == self.specialization
            else
                return name == OVALE_SPECIALIZATION_NAME[self.class][self.specialization]
            end
        end
        return false
    end,
    GetMasteryMultiplier = function(self, snapshot)
        snapshot = snapshot or self.current
        return 1 + snapshot.masteryEffect / 100
    end,
    GetBaseHasteMultiplier = function(self, snapshot)
        snapshot = snapshot or self.current
        return 1 + snapshot.hastePercent / 100
    end,
    GetMeleeAttackSpeedPercentMultiplier = function(self, snapshot)
        snapshot = snapshot or self.current
        return 1 + snapshot.meleeAttackSpeedPercent / 100
    end,
    GetRangedAttackSpeedPercentMultiplier = function(self, snapshot)
        snapshot = snapshot or self.current
        return 1 + snapshot.rangedAttackSpeedPercent / 100
    end,
    GetSpellCastSpeedPercentMultiplier = function(self, snapshot)
        snapshot = snapshot or self.current
        return 1 + snapshot.spellCastSpeedPercent / 100
    end,
    GetHasteMultiplier = function(self, haste, snapshot)
        snapshot = snapshot or self.current
        local multiplier = self:GetBaseHasteMultiplier(snapshot) or 1
        if haste == "melee" then
            multiplier = self:GetMeleeAttackSpeedPercentMultiplier(snapshot)
        elseif haste == "ranged" then
            multiplier = self:GetRangedAttackSpeedPercentMultiplier(snapshot)
        elseif haste == "spell" then
            multiplier = self:GetSpellCastSpeedPercentMultiplier(snapshot)
        end
        return multiplier
    end,
    UpdateSnapshot = function(self, target, snapshot, updateAllStats)
        snapshot = snapshot or self.current
        local nameTable = updateAllStats and __exports.OvalePaperDoll.STAT_NAME or __exports.OvalePaperDoll.SNAPSHOT_STAT_NAME
        for k in pairs(nameTable) do
            target[k] = snapshot[k]
        end
    end,
    InitializeState = function(self)
        self.next.snapshotTime = 0
        self.next.strength = 0
        self.next.agility = 0
        self.next.stamina = 0
        self.next.intellect = 0
        self.next.attackPower = 0
        self.next.spellPower = 0
        self.next.critRating = 0
        self.next.meleeCrit = 0
        self.next.rangedCrit = 0
        self.next.spellCrit = 0
        self.next.hasteRating = 0
        self.next.hastePercent = 0
        self.next.meleeAttackSpeedPercent = 0
        self.next.rangedAttackSpeedPercent = 0
        self.next.spellCastSpeedPercent = 0
        self.next.masteryRating = 0
        self.next.masteryEffect = 0
        self.next.versatilityRating = 0
        self.next.versatility = 0
        self.next.mainHandWeaponDPS = 0
        self.next.offHandWeaponDPS = 0
        self.next.baseDamageMultiplier = 1
    end,
    CleanState = function(self)
    end,
    ResetState = function(self)
        self:UpdateSnapshot(self.next, self.current, true)
    end,
    constructor = function(self, ...)
        OvalePaperDollBase.constructor(self, ...)
        self.class = Ovale.playerClass
        self.level = UnitLevel("player")
        self.specialization = nil
        self.STAT_NAME = {
            snapshotTime = true,
            strength = true,
            agility = true,
            stamina = true,
            intellect = true,
            attackPower = true,
            spellPower = true,
            critRating = true,
            meleeCrit = true,
            rangedCrit = true,
            spellCrit = true,
            hasteRating = true,
            hastePercent = true,
            meleeAttackSpeedPercent = true,
            rangedAttackSpeedPercent = true,
            spellCastSpeedPercent = true,
            masteryRating = true,
            masteryEffect = true,
            versatilityRating = true,
            versatility = true,
            mainHandWeaponDPS = true,
            offHandWeaponDPS = true,
            baseDamageMultiplier = true
        }
        self.SNAPSHOT_STAT_NAME = {
            snapshotTime = true,
            masteryEffect = true,
            baseDamageMultiplier = true
        }
        self.CopySpellcastInfo = function(module, spellcast, dest)
            self:UpdateSnapshot(dest, spellcast, true)
        end
        self.SaveSpellcastInfo = function(module, spellcast, atTime, state)
            local paperDollModule = state or self.current
            self:UpdateSnapshot(spellcast, paperDollModule, true)
        end
    end
})
__exports.OvalePaperDoll = OvalePaperDollClass()
OvaleState:RegisterState(__exports.OvalePaperDoll)
