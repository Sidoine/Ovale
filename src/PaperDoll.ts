import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleEquipment } from "./Equipment";
import { OvaleStance } from "./Stance";
import { OvaleState } from "./State";
import { lastSpell, SpellCast, PaperDollSnapshot, SpellCastModule } from "./LastSpell";
import aceEvent from "@wowts/ace_event-3.0";
import { pairs, tonumber, type } from "@wowts/lua";
import { GetCombatRating, GetCombatRatingBonus, GetCritChance, GetMastery, GetMasteryEffect, GetMeleeHaste, GetRangedCritChance, GetRangedHaste, GetSpecialization, GetSpellBonusDamage, GetSpellBonusHealing, GetSpellCritChance, GetTime, UnitAttackPower, UnitAttackSpeed, UnitDamage, UnitLevel, UnitRangedAttackPower, UnitSpellHaste, UnitStat, CR_CRIT_MELEE, CR_HASTE_MELEE, CR_VERSATILITY_DAMAGE_DONE } from "@wowts/wow-mock";

export let OvalePaperDoll: OvalePaperDollClass;
let OVALE_SPELLDAMAGE_SCHOOL = {
    DEATHKNIGHT: 4,
    DEMONHUNTER: 3,
    DRUID: 4,
    HUNTER: 4,
    MAGE: 5,
    MONK: 4,
    PALADIN: 2,
    PRIEST: 2,
    ROGUE: 4,
    SHAMAN: 4,
    WARLOCK: 6,
    WARRIOR: 4
}
// let OVALE_HEALING_CLASS = {
//     DRUID: true,
//     MONK: true,
//     PALADIN: true,
//     PRIEST: true,
//     SHAMAN: true
// }
let OVALE_SPECIALIZATION_NAME = {
    DEATHKNIGHT: {
        1: "blood",
        2: "frost",
        3: "unholy"
    },
    DEMONHUNTER: {
        1: "havoc",
        2: "vengeance"
    },
    DRUID: {
        1: "balance",
        2: "feral",
        3: "guardian",
        4: "restoration"
    },
    HUNTER: {
        1: "beast_mastery",
        2: "marksmanship",
        3: "survival"
    },
    MAGE: {
        1: "arcane",
        2: "fire",
        3: "frost"
    },
    MONK: {
        1: "brewmaster",
        2: "mistweaver",
        3: "windwalker"
    },
    PALADIN: {
        1: "holy",
        2: "protection",
        3: "retribution"
    },
    PRIEST: {
        1: "discipline",
        2: "holy",
        3: "shadow"
    },
    ROGUE: {
        1: "assassination",
        2: "outlaw",
        3: "subtlety"
    },
    SHAMAN: {
        1: "elemental",
        2: "enhancement",
        3: "restoration"
    },
    WARLOCK: {
        1: "affliction",
        2: "demonology",
        3: "destruction"
    },
    WARRIOR: {
        1: "arms",
        2: "fury",
        3: "protection"
    }
}

export class PaperDollData implements PaperDollSnapshot {
    snapshotTime = 0;
    agility = 0;
    intellect = 0;
    spirit = 0;
    stamina = 0;
    strength = 0;
    attackPower = 0;
    rangedAttackPower = 0;
    spellBonusDamage = 0;
    spellBonusHealing = 0;
    masteryEffect = 0;
    meleeCrit = 0;
    meleeHaste = 0;
    rangedCrit = 0;
    rangedHaste = 0;
    spellCrit = 0;
    spellHaste = 0;
    critRating = 0;
    hasteRating = 0;
    masteryRating = 0;
    versatilityRating = 0;
    versatility = 0;
    mainHandWeaponDamage = 0;
    offHandWeaponDamage = 0;
    baseDamageMultiplier = 1;
}

let OvalePaperDollBase = OvaleState.RegisterHasState(OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvalePaperDoll", aceEvent))), PaperDollData);

class OvalePaperDollClass extends OvalePaperDollBase implements SpellCastModule {
    class = Ovale.playerClass;
    level = UnitLevel("player");
    specialization = undefined;
    STAT_NAME = {
        snapshotTime: true,
        agility: true,
        intellect: true,
        spirit: true,
        stamina: true,
        strength: true,
        attackPower: true,
        rangedAttackPower: true,
        spellBonusDamage: true,
        spellBonusHealing: true,
        masteryEffect: true,
        meleeCrit: true,
        meleeHaste: true,
        rangedCrit: true,
        rangedHaste: true,
        spellCrit: true,
        spellHaste: true,
        critRating: true,
        hasteRating: true,
        masteryRating: true,
        versatilityRating: true,
        versatility: true,
        mainHandWeaponDamage: true,
        offHandWeaponDamage: true,
        baseDamageMultiplier: true
    }
    SNAPSHOT_STAT_NAME = {
        snapshotTime: true,
        masteryEffect: true,
        baseDamageMultiplier: true
    }
   
    
    OnInitialize() {
        this.RegisterEvent("COMBAT_RATING_UPDATE");
        this.RegisterEvent("MASTERY_UPDATE");
        this.RegisterEvent("PLAYER_ALIVE", "UpdateStats");
        this.RegisterEvent("PLAYER_DAMAGE_DONE_MODS");
        this.RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStats");
        this.RegisterEvent("PLAYER_LEVEL_UP");
        this.RegisterEvent("SPELL_POWER_CHANGED");
        this.RegisterEvent("UNIT_ATTACK_POWER");
        this.RegisterEvent("UNIT_DAMAGE", "UpdateDamage");
        this.RegisterEvent("UNIT_LEVEL");
        this.RegisterEvent("UNIT_RANGEDDAMAGE");
        this.RegisterEvent("UNIT_RANGED_ATTACK_POWER");
        this.RegisterEvent("UNIT_SPELL_HASTE");
        this.RegisterEvent("UNIT_STATS");
        this.RegisterMessage("Ovale_EquipmentChanged", "UpdateDamage");
        this.RegisterMessage("Ovale_StanceChanged", "UpdateDamage");
        this.RegisterMessage("Ovale_TalentsChanged", "UpdateStats");
        lastSpell.RegisterSpellcastInfo(this);
    }
    OnDisable() {
        lastSpell.UnregisterSpellcastInfo(this);
        this.UnregisterEvent("COMBAT_RATING_UPDATE");
        this.UnregisterEvent("MASTERY_UPDATE");
        this.UnregisterEvent("PLAYER_ALIVE");
        this.UnregisterEvent("PLAYER_DAMAGE_DONE_MODS");
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("PLAYER_LEVEL_UP");
        this.UnregisterEvent("SPELL_POWER_CHANGED");
        this.UnregisterEvent("UNIT_ATTACK_POWER");
        this.UnregisterEvent("UNIT_DAMAGE");
        this.UnregisterEvent("UNIT_LEVEL");
        this.UnregisterEvent("UNIT_RANGEDDAMAGE");
        this.UnregisterEvent("UNIT_RANGED_ATTACK_POWER");
        this.UnregisterEvent("UNIT_SPELL_HASTE");
        this.UnregisterEvent("UNIT_STATS");
        this.UnregisterMessage("Ovale_EquipmentChanged");
        this.UnregisterMessage("Ovale_StanceChanged");
        this.UnregisterMessage("Ovale_TalentsChanged");
    }
    COMBAT_RATING_UPDATE(event) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.current.meleeCrit = GetCritChance();
        this.current.rangedCrit = GetRangedCritChance();
        this.current.spellCrit = GetSpellCritChance(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.current.critRating = GetCombatRating(CR_CRIT_MELEE);
        this.current.hasteRating = GetCombatRating(CR_HASTE_MELEE);
        this.current.versatilityRating = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE);
        this.current.versatility = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE);
        this.current.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    MASTERY_UPDATE(event) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.current.masteryRating = GetMastery();
        if (this.level < 80) {
            this.current.masteryEffect = 0;
        } else {
            this.current.masteryEffect = GetMasteryEffect();
            Ovale.needRefresh();
        }
        this.current.snapshotTime = GetTime();
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    PLAYER_LEVEL_UP(event, level, ...__args) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.level = tonumber(level) || UnitLevel("player");
        this.current.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.DebugTimestamp("%s: level = %d", event, this.level);
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    PLAYER_DAMAGE_DONE_MODS(event, unitId) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.current.spellBonusDamage = GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.current.spellBonusHealing = GetSpellBonusHealing();
        this.current.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    SPELL_POWER_CHANGED(event) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.current.spellBonusDamage = GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.current.spellBonusDamage = GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.current.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    UNIT_ATTACK_POWER(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            let [base, posBuff, negBuff] = UnitAttackPower(unitId);
            this.current.attackPower = base + posBuff + negBuff;
            this.current.snapshotTime = GetTime();
            Ovale.needRefresh();
            this.UpdateDamage(event);
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_LEVEL(event, unitId) {
        Ovale.refreshNeeded[unitId] = true;
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.level = UnitLevel(unitId);
            this.DebugTimestamp("%s: level = %d", event, this.level);
            this.current.snapshotTime = GetTime();
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_RANGEDDAMAGE(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.current.rangedHaste = GetRangedHaste();
            this.current.snapshotTime = GetTime();
            Ovale.needRefresh();
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_RANGED_ATTACK_POWER(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            let [base, posBuff, negBuff] = UnitRangedAttackPower(unitId);
            Ovale.needRefresh();
            this.current.rangedAttackPower = base + posBuff + negBuff;
            this.current.snapshotTime = GetTime();
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_SPELL_HASTE(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.current.meleeHaste = GetMeleeHaste();
            this.current.spellHaste = UnitSpellHaste(unitId);
            this.current.snapshotTime = GetTime();
            Ovale.needRefresh();
            this.UpdateDamage(event);
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_STATS(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.current.strength = UnitStat(unitId, 1);
            this.current.agility = UnitStat(unitId, 2);
            this.current.stamina = UnitStat(unitId, 3);
            this.current.intellect = UnitStat(unitId, 4);
            this.current.spirit = 0;
            this.current.snapshotTime = GetTime();
            Ovale.needRefresh();
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UpdateDamage(event) {
        this.StartProfiling("OvalePaperDoll_UpdateDamage");
        let [minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, , , damageMultiplier] = UnitDamage("player");
        let [mainHandAttackSpeed, offHandAttackSpeed] = UnitAttackSpeed("player");

        // Appartently, if the character is not loaded, it returns 0
        if (damageMultiplier == 0 || mainHandAttackSpeed == 0) return;
        this.current.baseDamageMultiplier = damageMultiplier;
        if (this.class == "DRUID" && OvaleStance.IsStance("druid_cat_form", undefined)) {
            damageMultiplier = damageMultiplier * 2;
        } else if (this.class == "MONK" && OvaleEquipment.HasOneHandedWeapon()) {
            damageMultiplier = damageMultiplier * 1.25;
        }
        let avgDamage = (minDamage + maxDamage) / 2 / damageMultiplier;
        let mainHandWeaponSpeed = mainHandAttackSpeed * this.GetMeleeHasteMultiplier();
        let normalizedMainHandWeaponSpeed = OvaleEquipment.mainHandWeaponSpeed || 1.5;
        if (this.class == "DRUID") {
            if (OvaleStance.IsStance("druid_cat_form", undefined)) {
                normalizedMainHandWeaponSpeed = 1;
            } else if (OvaleStance.IsStance("druid_bear_form", undefined)) {
                normalizedMainHandWeaponSpeed = 2.5;
            }
        }
        this.current.mainHandWeaponDamage = avgDamage / mainHandWeaponSpeed * normalizedMainHandWeaponSpeed;
        if (OvaleEquipment.HasOffHandWeapon()) {
            let avgOffHandDamage = (minOffHandDamage + maxOffHandDamage) / 2 / damageMultiplier;
            offHandAttackSpeed = offHandAttackSpeed || mainHandAttackSpeed;
            let offHandWeaponSpeed = offHandAttackSpeed * this.GetMeleeHasteMultiplier();
            let normalizedOffHandWeaponSpeed = OvaleEquipment.offHandWeaponSpeed || 1.5;
            if (this.class == "DRUID") {
                if (OvaleStance.IsStance("druid_cat_form", undefined)) {
                    normalizedOffHandWeaponSpeed = 1;
                } else if (OvaleStance.IsStance("druid_bear_form", undefined)) {
                    normalizedOffHandWeaponSpeed = 2.5;
                }
            }
            this.current.offHandWeaponDamage = avgOffHandDamage / offHandWeaponSpeed * normalizedOffHandWeaponSpeed;
        } else {
            this.current.offHandWeaponDamage = 0;
        }
        this.current.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.StopProfiling("OvalePaperDoll_UpdateDamage");
    }
    UpdateSpecialization(event) {
        this.StartProfiling("OvalePaperDoll_UpdateSpecialization");
        let newSpecialization = GetSpecialization();
        if (this.specialization != newSpecialization) {
            let oldSpecialization = this.specialization;
            this.specialization = newSpecialization;
            this.current.snapshotTime = GetTime();
            Ovale.needRefresh();
            this.SendMessage("Ovale_SpecializationChanged", this.GetSpecialization(newSpecialization), this.GetSpecialization(oldSpecialization));
        }
        this.StopProfiling("OvalePaperDoll_UpdateSpecialization");
    }
    UpdateStats(event) {
        this.UpdateSpecialization(event);
        this.COMBAT_RATING_UPDATE(event);
        this.MASTERY_UPDATE(event);
        this.PLAYER_DAMAGE_DONE_MODS(event, "player");
        this.SPELL_POWER_CHANGED(event);
        this.UNIT_ATTACK_POWER(event, "player");
        this.UNIT_RANGEDDAMAGE(event, "player");
        this.UNIT_RANGED_ATTACK_POWER(event, "player");
        this.UNIT_SPELL_HASTE(event, "player");
        this.UNIT_STATS(event, "player");
        this.UpdateDamage(event);
    }
    GetSpecialization(specialization?) {
        specialization = specialization || this.specialization;
        return OVALE_SPECIALIZATION_NAME[this.class][specialization];
    }
    IsSpecialization(name) {
        if (name && this.specialization) {
            if (type(name) == "number") {
                return name == this.specialization;
            } else {
                return name == OVALE_SPECIALIZATION_NAME[this.class][this.specialization];
            }
        }
        return false;
    }
    GetMasteryMultiplier(snapshot?:PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.masteryEffect / 100;
    }
    GetMeleeHasteMultiplier(snapshot?:PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.meleeHaste / 100;
    }
    GetRangedHasteMultiplier(snapshot?:PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.rangedHaste / 100;
    }
    GetSpellHasteMultiplier(snapshot?:PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.spellHaste / 100;
    }
    GetHasteMultiplier(haste: string, snapshot:PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        let multiplier = 1;
        if (haste == "melee") {
            multiplier = this.GetMeleeHasteMultiplier(snapshot);
        } else if (haste == "ranged") {
            multiplier = this.GetRangedHasteMultiplier(snapshot);
        } else if (haste == "spell") {
            multiplier = this.GetSpellHasteMultiplier(snapshot);
        }
        return multiplier;
    }
    UpdateSnapshot(target:PaperDollSnapshot, snapshot?:PaperDollSnapshot, updateAllStats?: boolean) {
        snapshot = snapshot || this.current;
        let nameTable = updateAllStats && OvalePaperDoll.STAT_NAME || OvalePaperDoll.SNAPSHOT_STAT_NAME;
        for (const [k] of pairs(nameTable)) {
            target[k] = snapshot[k];
        }
    }
    CopySpellcastInfo = (module: OvalePaperDollClass, spellcast: SpellCast, dest: SpellCast) => {
        this.UpdateSnapshot(dest, spellcast, true);
    }
    SaveSpellcastInfo = (module: OvalePaperDollClass, spellcast: SpellCast, atTime: number, state: PaperDollSnapshot) => {
        let paperDollModule = state || this.current;
        this.UpdateSnapshot(spellcast, paperDollModule, true);
    }
    InitializeState() {
        // this.next.class = undefined;
        // this.level = undefined;
        // this.specialization = undefined;
        this.next.snapshotTime = 0;
        this.next.agility = 0;
        this.next.agility = 0;
        this.next.intellect = 0;
        this.next.spirit = 0;
        this.next.stamina = 0;
        this.next.strength = 0;
        this.next.attackPower = 0;
        this.next.rangedAttackPower = 0;
        this.next.spellBonusDamage = 0;
        this.next.spellBonusHealing = 0;
        this.next.masteryEffect = 0;
        this.next.meleeCrit = 0;
        this.next.meleeHaste = 0;
        this.next.rangedCrit = 0;
        this.next.rangedHaste = 0;
        this.next.spellCrit = 0;
        this.next.spellHaste = 0;
        this.next.critRating = 0;
        this.next.hasteRating = 0;
        this.next.masteryRating = 0;
        this.next.versatilityRating = 0;
        this.next.versatility = 0;
        this.next.mainHandWeaponDamage = 0;
        this.next.offHandWeaponDamage = 0;
        this.next.baseDamageMultiplier = 1;
    }
    CleanState(): void {
    }

    ResetState() {
        this.UpdateSnapshot(this.next, this.current, true);
    }
}

OvalePaperDoll = new OvalePaperDollClass();
OvaleState.RegisterState(OvalePaperDoll);
