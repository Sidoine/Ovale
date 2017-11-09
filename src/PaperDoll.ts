import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleEquipment } from "./Equipment";
import { OvaleStance } from "./Stance";
import { OvaleState, StateModule } from "./State";
import { lastSpell, SpellCast, PaperDollSnapshot, SpellCastModule } from "./LastSpell";
import aceEvent from "@wowts/ace_event-3.0";
import { pairs, tonumber, type } from "@wowts/lua";
import { GetCombatRating, GetCritChance, GetMastery, GetMasteryEffect, GetMeleeHaste, GetMultistrike, GetMultistrikeEffect, GetRangedCritChance, GetRangedHaste, GetSpecialization, GetSpellBonusDamage, GetSpellBonusHealing, GetSpellCritChance, GetTime, UnitAttackPower, UnitAttackSpeed, UnitDamage, UnitLevel, UnitRangedAttackPower, UnitSpellHaste, UnitStat, CR_CRIT_MELEE, CR_HASTE_MELEE } from "@wowts/wow-mock";

let OvalePaperDollBase = OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvalePaperDoll", aceEvent)));
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

class OvalePaperDollClass extends OvalePaperDollBase implements PaperDollSnapshot, SpellCastModule {
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
        multistrike: true,
        critRating: true,
        hasteRating: true,
        masteryRating: true,
        multistrikeRating: true,
        mainHandWeaponDamage: true,
        offHandWeaponDamage: true,
        baseDamageMultiplier: true
    }
    SNAPSHOT_STAT_NAME = {
        snapshotTime: true,
        masteryEffect: true,
        baseDamageMultiplier: true
    }
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
    multistrike = 0;
    critRating = 0;
    hasteRating = 0;
    masteryRating = 0;
    multistrikeRating = 0;
    mainHandWeaponDamage = 0;
    offHandWeaponDamage = 0;
    baseDamageMultiplier = 1;

    
    constructor() {
        super();
        this.RegisterEvent("COMBAT_RATING_UPDATE");
        this.RegisterEvent("MASTERY_UPDATE");
        this.RegisterEvent("MULTISTRIKE_UPDATE");
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
        this.UnregisterEvent("MULTISTRIKE_UPDATE");
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
        this.meleeCrit = GetCritChance();
        this.rangedCrit = GetRangedCritChance();
        this.spellCrit = GetSpellCritChance(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.critRating = GetCombatRating(CR_CRIT_MELEE);
        this.hasteRating = GetCombatRating(CR_HASTE_MELEE);
        this.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    MASTERY_UPDATE(event) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.masteryRating = GetMastery();
        if (this.level < 80) {
            this.masteryEffect = 0;
        } else {
            this.masteryEffect = GetMasteryEffect();
            Ovale.needRefresh();
        }
        this.snapshotTime = GetTime();
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    MULTISTRIKE_UPDATE(event) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.multistrikeRating = GetMultistrike();
        this.multistrike = GetMultistrikeEffect();
        this.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    PLAYER_LEVEL_UP(event, level, ...__args) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.level = tonumber(level) || UnitLevel("player");
        this.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.DebugTimestamp("%s: level = %d", event, this.level);
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    PLAYER_DAMAGE_DONE_MODS(event, unitId) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.spellBonusDamage = GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.spellBonusHealing = GetSpellBonusHealing();
        this.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    SPELL_POWER_CHANGED(event) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.spellBonusDamage = GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.spellBonusDamage = GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    UNIT_ATTACK_POWER(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            let [base, posBuff, negBuff] = UnitAttackPower(unitId);
            this.attackPower = base + posBuff + negBuff;
            this.snapshotTime = GetTime();
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
            this.snapshotTime = GetTime();
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_RANGEDDAMAGE(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.rangedHaste = GetRangedHaste();
            this.snapshotTime = GetTime();
            Ovale.needRefresh();
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_RANGED_ATTACK_POWER(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            let [base, posBuff, negBuff] = UnitRangedAttackPower(unitId);
            Ovale.needRefresh();
            this.rangedAttackPower = base + posBuff + negBuff;
            this.snapshotTime = GetTime();
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_SPELL_HASTE(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.meleeHaste = GetMeleeHaste();
            this.spellHaste = UnitSpellHaste(unitId);
            this.snapshotTime = GetTime();
            Ovale.needRefresh();
            this.UpdateDamage(event);
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_STATS(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.strength = UnitStat(unitId, 1);
            this.agility = UnitStat(unitId, 2);
            this.stamina = UnitStat(unitId, 3);
            this.intellect = UnitStat(unitId, 4);
            this.spirit = 0;
            this.snapshotTime = GetTime();
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
        this.baseDamageMultiplier = damageMultiplier;
        if (this.class == "DRUID" && OvaleStance.IsStance("druid_cat_form")) {
            damageMultiplier = damageMultiplier * 2;
        } else if (this.class == "MONK" && OvaleEquipment.HasOneHandedWeapon()) {
            damageMultiplier = damageMultiplier * 1.25;
        }
        let avgDamage = (minDamage + maxDamage) / 2 / damageMultiplier;
        let mainHandWeaponSpeed = mainHandAttackSpeed * this.GetMeleeHasteMultiplier();
        let normalizedMainHandWeaponSpeed = OvaleEquipment.mainHandWeaponSpeed || 1.5;
        if (this.class == "DRUID") {
            if (OvaleStance.IsStance("druid_cat_form")) {
                normalizedMainHandWeaponSpeed = 1;
            } else if (OvaleStance.IsStance("druid_bear_form")) {
                normalizedMainHandWeaponSpeed = 2.5;
            }
        }
        this.mainHandWeaponDamage = avgDamage / mainHandWeaponSpeed * normalizedMainHandWeaponSpeed;
        if (OvaleEquipment.HasOffHandWeapon()) {
            let avgOffHandDamage = (minOffHandDamage + maxOffHandDamage) / 2 / damageMultiplier;
            offHandAttackSpeed = offHandAttackSpeed || mainHandAttackSpeed;
            let offHandWeaponSpeed = offHandAttackSpeed * this.GetMeleeHasteMultiplier();
            let normalizedOffHandWeaponSpeed = OvaleEquipment.offHandWeaponSpeed || 1.5;
            if (this.class == "DRUID") {
                if (OvaleStance.IsStance("druid_cat_form")) {
                    normalizedOffHandWeaponSpeed = 1;
                } else if (OvaleStance.IsStance("druid_bear_form")) {
                    normalizedOffHandWeaponSpeed = 2.5;
                }
            }
            this.offHandWeaponDamage = avgOffHandDamage / offHandWeaponSpeed * normalizedOffHandWeaponSpeed;
        } else {
            this.offHandWeaponDamage = 0;
        }
        this.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.StopProfiling("OvalePaperDoll_UpdateDamage");
    }
    UpdateSpecialization(event) {
        this.StartProfiling("OvalePaperDoll_UpdateSpecialization");
        let newSpecialization = GetSpecialization();
        if (this.specialization != newSpecialization) {
            let oldSpecialization = this.specialization;
            this.specialization = newSpecialization;
            this.snapshotTime = GetTime();
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
        snapshot = snapshot || this;
        return 1 + snapshot.masteryEffect / 100;
    }
    GetMeleeHasteMultiplier(snapshot?:PaperDollSnapshot) {
        snapshot = snapshot || this;
        return 1 + snapshot.meleeHaste / 100;
    }
    GetRangedHasteMultiplier(snapshot?:PaperDollSnapshot) {
        snapshot = snapshot || this;
        return 1 + snapshot.rangedHaste / 100;
    }
    GetSpellHasteMultiplier(snapshot?:PaperDollSnapshot) {
        snapshot = snapshot || this;
        return 1 + snapshot.spellHaste / 100;
    }
    GetHasteMultiplier(haste: string, snapshot:PaperDollSnapshot) {
        snapshot = snapshot || this;
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
    UpdateSnapshot(target:PaperDollSnapshot, snapshot:PaperDollSnapshot, updateAllStats?: boolean) {
        let nameTable = updateAllStats && OvalePaperDoll.STAT_NAME || OvalePaperDoll.SNAPSHOT_STAT_NAME;
        for (const [k] of pairs(nameTable)) {
            target[k] = snapshot[k];
        }
    }
    CopySpellcastInfo = (module: OvalePaperDollClass, spellcast: SpellCast, dest: SpellCast) => {
        this.UpdateSnapshot(dest, spellcast, true);
    }
    SaveSpellcastInfo = (module: OvalePaperDollClass, spellcast: SpellCast, atTime: number, state: PaperDollState) => {
        let paperDollModule = state || this;
        this.UpdateSnapshot(spellcast, paperDollModule, true);
    }
}
class PaperDollState implements StateModule {
    class = undefined;
    level = undefined;
    specialization = undefined;
    snapshotTime = undefined;
    agility = undefined;
    intellect = undefined;
    spirit = undefined;
    stamina = undefined;
    strength = undefined;
    attackPower = undefined;
    rangedAttackPower = undefined;
    spellBonusDamage = undefined;
    spellBonusHealing = undefined;
    masteryEffect = undefined;
    meleeCrit = undefined;
    meleeHaste = undefined;
    rangedCrit = undefined;
    rangedHaste = undefined;
    spellCrit = undefined;
    spellHaste = undefined;
    multistrike = undefined;
    critRating = undefined;
    hasteRating = undefined;
    masteryRating = undefined;
    multistrikeRating = undefined;
    mainHandWeaponDamage = undefined;
    offHandWeaponDamage = undefined;
    baseDamageMultiplier = undefined;
    
    InitializeState() {
        this.class = undefined;
        this.level = undefined;
        this.specialization = undefined;
        this.snapshotTime = 0;
        this.agility = 0;
        this.intellect = 0;
        this.spirit = 0;
        this.stamina = 0;
        this.strength = 0;
        this.attackPower = 0;
        this.rangedAttackPower = 0;
        this.spellBonusDamage = 0;
        this.spellBonusHealing = 0;
        this.masteryEffect = 0;
        this.meleeCrit = 0;
        this.meleeHaste = 0;
        this.rangedCrit = 0;
        this.rangedHaste = 0;
        this.spellCrit = 0;
        this.spellHaste = 0;
        this.multistrike = 0;
        this.critRating = 0;
        this.hasteRating = 0;
        this.masteryRating = 0;
        this.multistrikeRating = 0;
        this.mainHandWeaponDamage = 0;
        this.offHandWeaponDamage = 0;
        this.baseDamageMultiplier = 1;
    }
    CleanState(): void {
    }

    ResetState() {
        this.class = OvalePaperDoll.class;
        this.level = OvalePaperDoll.level;
        this.specialization = OvalePaperDoll.specialization;
        this.UpdateSnapshot(this, OvalePaperDoll, true);
    }

    GetMasteryMultiplier(snapshot:PaperDollSnapshot) {
        return OvalePaperDoll.GetMasteryMultiplier(snapshot);
    }
    GetMeleeHasteMultiplier(snapshot:PaperDollSnapshot) {
        return OvalePaperDoll.GetMeleeHasteMultiplier(snapshot);
    }
    GetRangedHasteMultiplier(snapshot:PaperDollSnapshot) {
        return OvalePaperDoll.GetRangedHasteMultiplier(snapshot);
    }
    GetSpellHasteMultiplier(snapshot:PaperDollSnapshot) {
        return OvalePaperDoll.GetSpellHasteMultiplier(snapshot);
    }
    GetHasteMultiplier(haste, snapshot?:PaperDollSnapshot) {
        return OvalePaperDoll.GetHasteMultiplier(haste, snapshot);
    }
    UpdateSnapshot(target:PaperDollSnapshot, snapshot?:PaperDollSnapshot, updateAllStats?: boolean) {
        if (!snapshot) {
            OvalePaperDoll.UpdateSnapshot(target, this, updateAllStats);
        }
        else {
            OvalePaperDoll.UpdateSnapshot(target, snapshot, updateAllStats);
        }
    }
}

export const paperDollState = new PaperDollState();
OvaleState.RegisterState(paperDollState);

OvalePaperDoll = new OvalePaperDollClass();
