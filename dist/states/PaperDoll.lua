local __exports = LibStub:NewLibrary("ovale/states/PaperDoll", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __State = LibStub:GetLibrary("ovale/State")
local States = __State.States
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local tonumber = tonumber
local ipairs = ipairs
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
local UnitDamage = UnitDamage
local UnitRangedDamage = UnitRangedDamage
local UnitLevel = UnitLevel
local UnitRangedAttackPower = UnitRangedAttackPower
local UnitSpellHaste = UnitSpellHaste
local UnitStat = UnitStat
local CR_CRIT_MELEE = CR_CRIT_MELEE
local CR_HASTE_MELEE = CR_HASTE_MELEE
local CR_VERSATILITY_DAMAGE_DONE = CR_VERSATILITY_DAMAGE_DONE
local __tools = LibStub:GetLibrary("ovale/tools")
local isNumber = __tools.isNumber
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
__exports.OVALE_SPECIALIZATION_NAME = {
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
local STAT_NAME = {
    [1] = "snapshotTime",
    [2] = "strength",
    [3] = "agility",
    [4] = "stamina",
    [5] = "intellect",
    [6] = "attackPower",
    [7] = "spellPower",
    [8] = "critRating",
    [9] = "meleeCrit",
    [10] = "rangedCrit",
    [11] = "spellCrit",
    [12] = "hasteRating",
    [13] = "hastePercent",
    [14] = "meleeAttackSpeedPercent",
    [15] = "rangedAttackSpeedPercent",
    [16] = "spellCastSpeedPercent",
    [17] = "masteryRating",
    [18] = "masteryEffect",
    [19] = "versatilityRating",
    [20] = "versatility",
    [21] = "mainHandWeaponDPS",
    [22] = "offHandWeaponDPS",
    [23] = "baseDamageMultiplier"
}
local SNAPSHOT_STAT_NAME = {
    [1] = "snapshotTime",
    [2] = "masteryEffect",
    [3] = "baseDamageMultiplier"
}
__exports.OvalePaperDollClass = __class(States, {
    constructor = function(self, ovaleEquipement, ovale, ovaleDebug, ovaleProfiler, lastSpell)
        self.ovaleEquipement = ovaleEquipement
        self.ovale = ovale
        self.lastSpell = lastSpell
        self.level = UnitLevel("player")
        self.specialization = nil
        self.OnInitialize = function()
            self.class = self.ovale.playerClass
            self.module:RegisterEvent("UNIT_STATS", self.UNIT_STATS)
            self.module:RegisterEvent("COMBAT_RATING_UPDATE", self.COMBAT_RATING_UPDATE)
            self.module:RegisterEvent("MASTERY_UPDATE", self.MASTERY_UPDATE)
            self.module:RegisterEvent("UNIT_ATTACK_POWER", self.UNIT_ATTACK_POWER)
            self.module:RegisterEvent("UNIT_RANGED_ATTACK_POWER", self.UNIT_RANGED_ATTACK_POWER)
            self.module:RegisterEvent("SPELL_POWER_CHANGED", self.SPELL_POWER_CHANGED)
            self.module:RegisterEvent("UNIT_DAMAGE", self.UpdateDamage)
            self.module:RegisterEvent("PLAYER_ENTERING_WORLD", self.UpdateStats)
            self.module:RegisterEvent("PLAYER_ALIVE", self.UpdateStats)
            self.module:RegisterEvent("PLAYER_LEVEL_UP", self.PLAYER_LEVEL_UP)
            self.module:RegisterEvent("UNIT_LEVEL", self.UNIT_LEVEL)
            self.module:RegisterMessage("Ovale_EquipmentChanged", self.UpdateDamage)
            self.module:RegisterMessage("Ovale_TalentsChanged", self.UpdateStats)
            self.lastSpell:RegisterSpellcastInfo(self)
        end
        self.OnDisable = function()
            self.lastSpell:UnregisterSpellcastInfo(self)
            self.module:UnregisterEvent("UNIT_STATS")
            self.module:UnregisterEvent("COMBAT_RATING_UPDATE")
            self.module:UnregisterEvent("MASTERY_UPDATE")
            self.module:UnregisterEvent("UNIT_ATTACK_POWER")
            self.module:UnregisterEvent("UNIT_RANGED_ATTACK_POWER")
            self.module:UnregisterEvent("SPELL_POWER_CHANGED")
            self.module:UnregisterEvent("UNIT_DAMAGE")
            self.module:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self.module:UnregisterEvent("PLAYER_ALIVE")
            self.module:UnregisterEvent("PLAYER_LEVEL_UP")
            self.module:UnregisterEvent("UNIT_LEVEL")
            self.module:UnregisterMessage("Ovale_EquipmentChanged")
            self.module:UnregisterMessage("Ovale_StanceChanged")
            self.module:UnregisterMessage("Ovale_TalentsChanged")
        end
        self.UNIT_STATS = function(unitId)
            if unitId == "player" then
                self.profiler:StartProfiling("OvalePaperDoll_UpdateStats")
                self.current.strength = UnitStat(unitId, 1)
                self.current.agility = UnitStat(unitId, 2)
                self.current.stamina = UnitStat(unitId, 3)
                self.current.intellect = UnitStat(unitId, 4)
                self.current.snapshotTime = GetTime()
                self.ovale:needRefresh()
                self.profiler:StopProfiling("OvalePaperDoll_UpdateStats")
            end
        end
        self.COMBAT_RATING_UPDATE = function()
            self.profiler:StartProfiling("OvalePaperDoll_UpdateStats")
            self.current.critRating = GetCombatRating(CR_CRIT_MELEE)
            self.current.meleeCrit = GetCritChance()
            self.current.rangedCrit = GetRangedCritChance()
            self.current.spellCrit = GetSpellCritChance(OVALE_SPELLDAMAGE_SCHOOL[self.class])
            self.current.hasteRating = GetCombatRating(CR_HASTE_MELEE)
            self.current.hastePercent = GetHaste()
            self.current.meleeAttackSpeedPercent = GetMeleeHaste()
            self.current.rangedAttackSpeedPercent = GetRangedHaste()
            self.current.spellCastSpeedPercent = UnitSpellHaste("player")
            self.current.versatilityRating = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE)
            self.current.versatility = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
            self.current.snapshotTime = GetTime()
            self.ovale:needRefresh()
            self.profiler:StopProfiling("OvalePaperDoll_UpdateStats")
        end
        self.MASTERY_UPDATE = function()
            self.profiler:StartProfiling("OvalePaperDoll_UpdateStats")
            self.current.masteryRating = GetMastery()
            if self.level < 80 then
                self.current.masteryEffect = 0
            else
                self.current.masteryEffect = GetMasteryEffect()
                self.ovale:needRefresh()
            end
            self.current.snapshotTime = GetTime()
            self.profiler:StopProfiling("OvalePaperDoll_UpdateStats")
        end
        self.UNIT_ATTACK_POWER = function(event, unitId)
            if unitId == "player" and  not self.ovaleEquipement:HasRangedWeapon() then
                self.profiler:StartProfiling("OvalePaperDoll_UpdateStats")
                local base, posBuff, negBuff = UnitAttackPower(unitId)
                self.current.attackPower = base + posBuff + negBuff
                self.current.snapshotTime = GetTime()
                self.ovale:needRefresh()
                self.UpdateDamage()
                self.profiler:StopProfiling("OvalePaperDoll_UpdateStats")
            end
        end
        self.UNIT_RANGED_ATTACK_POWER = function(unitId)
            if unitId == "player" and self.ovaleEquipement:HasRangedWeapon() then
                self.profiler:StartProfiling("OvalePaperDoll_UpdateStats")
                local base, posBuff, negBuff = UnitRangedAttackPower(unitId)
                self.ovale:needRefresh()
                self.current.attackPower = base + posBuff + negBuff
                self.current.snapshotTime = GetTime()
                self.profiler:StopProfiling("OvalePaperDoll_UpdateStats")
            end
        end
        self.SPELL_POWER_CHANGED = function()
            self.profiler:StartProfiling("OvalePaperDoll_UpdateStats")
            self.current.spellPower = GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[self.class])
            self.current.snapshotTime = GetTime()
            self.ovale:needRefresh()
            self.profiler:StopProfiling("OvalePaperDoll_UpdateStats")
        end
        self.PLAYER_LEVEL_UP = function(event, level, ...)
            self.profiler:StartProfiling("OvalePaperDoll_UpdateStats")
            self.level = tonumber(level) or UnitLevel("player")
            self.current.snapshotTime = GetTime()
            self.ovale:needRefresh()
            self.debug:DebugTimestamp("%s: level = %d", event, self.level)
            self.profiler:StopProfiling("OvalePaperDoll_UpdateStats")
        end
        self.UNIT_LEVEL = function(event, unitId)
            self.ovale.refreshNeeded[unitId] = true
            if unitId == "player" then
                self.profiler:StartProfiling("OvalePaperDoll_UpdateStats")
                self.level = UnitLevel(unitId)
                self.debug:DebugTimestamp("%s: level = %d", event, self.level)
                self.current.snapshotTime = GetTime()
                self.profiler:StopProfiling("OvalePaperDoll_UpdateStats")
            end
        end
        self.UpdateDamage = function()
            self.profiler:StartProfiling("OvalePaperDoll_UpdateDamage")
            local damageMultiplier = self:GetAppropriateDamageMultiplier("player")
            self.current.baseDamageMultiplier = damageMultiplier or 1
            self.current.mainHandWeaponDPS = self.ovaleEquipement.mainHandDPS or 0
            self.current.offHandWeaponDPS = self.ovaleEquipement.offHandDPS or 0
            self.current.snapshotTime = GetTime()
            self.ovale:needRefresh()
            self.profiler:StopProfiling("OvalePaperDoll_UpdateDamage")
        end
        self.UpdateStats = function(event)
            self:UpdateSpecialization()
            self.UNIT_STATS("player")
            self.COMBAT_RATING_UPDATE()
            self.MASTERY_UPDATE()
            self.UNIT_ATTACK_POWER(event, "player")
            self.UNIT_RANGED_ATTACK_POWER("player")
            self.SPELL_POWER_CHANGED()
            self.UpdateDamage()
        end
        self.CopySpellcastInfo = function(spellcast, dest)
            self:UpdateSnapshot(dest, spellcast, true)
        end
        self.SaveSpellcastInfo = function(spellcast, atTime, state)
            local paperDollModule = state or self.current
            self:UpdateSnapshot(spellcast, paperDollModule, true)
        end
        States.constructor(self, __exports.PaperDollData)
        self.class = ovale.playerClass
        self.module = ovale:createModule("OvalePaperDoll", self.OnInitialize, self.OnDisable, aceEvent)
        self.debug = ovaleDebug:create("OvalePaperDoll")
        self.profiler = ovaleProfiler:create("OvalePaperDoll")
    end,
    GetAppropriateDamageMultiplier = function(self, unit)
        local damageMultiplier = 1
        if self.ovaleEquipement:HasRangedWeapon() then
            _, _, _, _, _, damageMultiplier = UnitRangedDamage(unit)
        else
            _, _, _, _, _, damageMultiplier = UnitDamage(unit)
        end
        return damageMultiplier
    end,
    UpdateSpecialization = function(self)
        self.profiler:StartProfiling("OvalePaperDoll_UpdateSpecialization")
        local newSpecialization = GetSpecialization()
        if self.specialization ~= newSpecialization then
            local oldSpecialization = self.specialization
            self.specialization = newSpecialization
            self.current.snapshotTime = GetTime()
            self.ovale:needRefresh()
            self.module:SendMessage("Ovale_SpecializationChanged", self:GetSpecialization(newSpecialization), self:GetSpecialization(oldSpecialization))
        end
        self.profiler:StopProfiling("OvalePaperDoll_UpdateSpecialization")
    end,
    GetSpecialization = function(self, specialization)
        specialization = specialization or self.specialization or 1
        return __exports.OVALE_SPECIALIZATION_NAME[self.class][specialization] or "arms"
    end,
    IsSpecialization = function(self, name)
        if name and self.specialization then
            if isNumber(name) then
                return name == self.specialization
            else
                return (name == __exports.OVALE_SPECIALIZATION_NAME[self.class][self.specialization])
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
        local nameTable = (updateAllStats and STAT_NAME) or SNAPSHOT_STAT_NAME
        for _, k in ipairs(nameTable) do
            local value = snapshot[k]
            if value then
                target[k] = value
            end
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
})
