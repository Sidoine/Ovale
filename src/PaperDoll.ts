import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleEquipment } from "./Equipment";
import { OvaleState } from "./State";
import { lastSpell, SpellCast, PaperDollSnapshot, SpellCastModule } from "./LastSpell";
import aceEvent from "@wowts/ace_event-3.0";
import { tonumber, LuaObj, LuaArray, ipairs } from "@wowts/lua";
import { GetCombatRating, GetCombatRatingBonus, GetCritChance, GetMastery, GetMasteryEffect, GetHaste, GetMeleeHaste, GetRangedCritChance, GetRangedHaste, GetSpecialization, GetSpellBonusDamage, GetSpellCritChance, GetTime, UnitAttackPower, UnitDamage, UnitRangedDamage, UnitLevel, UnitRangedAttackPower, UnitSpellHaste, UnitStat, CR_CRIT_MELEE, CR_HASTE_MELEE, CR_VERSATILITY_DAMAGE_DONE, ClassId, SpecializationIndex, UnitClass } from "@wowts/wow-mock";
import { isNumber } from "./tools";

export let OvalePaperDoll: OvalePaperDollClass;
let OVALE_SPELLDAMAGE_SCHOOL: LuaObj<number> = {
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

export type HasteType = "melee" | "spell" | "ranged" | "base" | "none";
export type SpecializationName = "blood" | "frost" | "unholy" | "havoc"
    | "vengeance" | "restoration" | "guardian" | "mistweaver" |
    "brewmaster" | "feral" | "holy" | "protection" | "discipline" |
    "survival" | "marksmanship" | "beast_mastery" | "destruction" |
    "demonology" | "affliction" | "shadow" | "retribution" | "fire" |
    "arcane" | "subtlety" | "outlaw" | "assassination" | "balance" |
    "enhancement" | "elemental" | "fury" | "arms" | "windwalker";

export let OVALE_SPECIALIZATION_NAME: {[key in ClassId]: {[key in 1 | 2 | 3 | 4]?: SpecializationName}} = {
    DEATHKNIGHT: {
        1: "blood",
        2: "frost",
        3: "unholy",
    },
    DEMONHUNTER: {
        1: "havoc",
        2: "vengeance",
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
        3: "survival",
    },
    MAGE: {
        1: "arcane",
        2: "fire",
        3: "frost",
    },
    MONK: {
        1: "brewmaster",
        2: "mistweaver",
        3: "windwalker",
    },
    PALADIN: {
        1: "holy",
        2: "protection",
        3: "retribution",
    },
    PRIEST: {
        1: "discipline",
        2: "holy",
        3: "shadow",
    },
    ROGUE: {
        1: "assassination",
        2: "outlaw",
        3: "subtlety",
    },
    SHAMAN: {
        1: "elemental",
        2: "enhancement",
        3: "restoration",
    },
    WARLOCK: {
        1: "affliction",
        2: "demonology",
        3: "destruction",
    },
    WARRIOR: {
        1: "arms",
        2: "fury",
        3: "protection",
    }
}

const GetAppropriateDamageMultiplier = function(unit: string)
{
    let damageMultiplier = 1;
	if (OvaleEquipment.HasRangedWeapon()) {
		[, , , , , damageMultiplier] = UnitRangedDamage(unit);
    }
	else {
        [, , , , , damageMultiplier] = UnitDamage(unit);
    }
    return damageMultiplier;
}

export class PaperDollData implements PaperDollSnapshot {
    snapshotTime = 0;

    strength = 0;
    agility = 0;
    stamina = 0;
    intellect = 0;
    // spirit = 0;

    attackPower = 0;
    spellPower = 0;
    // rangedAttackPower = 0;
    // spellBonusDamage = 0;
    // spellBonusHealing = 0;
    
    critRating = 0;
    meleeCrit = 0;
    rangedCrit = 0;
    spellCrit = 0;

    hasteRating = 0;
    hastePercent = 0;
    meleeAttackSpeedPercent = 0;
    rangedAttackSpeedPercent = 0;
    spellCastSpeedPercent = 0;

    masteryRating = 0;
    masteryEffect = 0;

    versatilityRating = 0;
    versatility = 0;

    mainHandWeaponDPS = 0;
    offHandWeaponDPS = 0;
    baseDamageMultiplier = 1;
}

let OvalePaperDollBase = OvaleState.RegisterHasState(OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvalePaperDoll", aceEvent))), PaperDollData);

const STAT_NAME: LuaArray<keyof PaperDollSnapshot> = {
    [1]: "snapshotTime",
    [2]: "strength",
    [3]: "agility",
    [4]: "stamina",
    [5]: "intellect",
    [6]: "attackPower",
    [7]: "spellPower",
    [8]: "critRating",
    [9]: "meleeCrit",
    [10]: "rangedCrit",
    [11]: "spellCrit",
    [12]: "hasteRating",
    [13]: "hastePercent",
    [14]: "meleeAttackSpeedPercent",
    [15]: "rangedAttackSpeedPercent",
    [16]: "spellCastSpeedPercent",
    [17]: "masteryRating",
    [18]: "masteryEffect",
    [19]: "versatilityRating",
    [20]: "versatility",
    [21]: "mainHandWeaponDPS",
    [22]: "offHandWeaponDPS",
    [23]: "baseDamageMultiplier"
}
const SNAPSHOT_STAT_NAME: LuaArray<keyof PaperDollSnapshot> = {
    [1]: "snapshotTime",
    [2]: "masteryEffect",
    [3]: "baseDamageMultiplier"
}

class OvalePaperDollClass extends OvalePaperDollBase implements SpellCastModule {
    class: ClassId;
    level = UnitLevel("player");
    specialization: SpecializationIndex | undefined = undefined;
    
    constructor() {
        super();
        const [, className] = UnitClass("player");
        this.class = className;
    }
    
    OnInitialize() {
        this.class = Ovale.playerClass;
        this.RegisterEvent("UNIT_STATS"); // Primary Stats (str, agi, sta, int)
        this.RegisterEvent("COMBAT_RATING_UPDATE"); // Secondary Stats (crit, haste, vers)
        this.RegisterEvent("MASTERY_UPDATE"); // Mastery
        this.RegisterEvent("UNIT_ATTACK_POWER"); // Attack Power
        this.RegisterEvent("UNIT_RANGED_ATTACK_POWER"); // Ranged Attack Power
        this.RegisterEvent("SPELL_POWER_CHANGED"); // Spell Power
        this.RegisterEvent("UNIT_DAMAGE", "UpdateDamage"); // Damage Multiplier
        this.RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStats");
        this.RegisterEvent("PLAYER_ALIVE", "UpdateStats");
        this.RegisterEvent("PLAYER_LEVEL_UP");
        this.RegisterEvent("UNIT_LEVEL");
        // this.RegisterEvent("UNIT_ATTACK_SPEED"); // Melee Haste (covered by COMBAT_RATING_UPDATE)
        // this.RegisterEvent("UNIT_RANGEDDAMAGE"); // Ranged Haste (covered by COMBAT_RATING_UPDATE)
        // this.RegisterEvent("UNIT_SPELL_HASTE"); // Spell Haste (covered by COMBAT_RATING_UPDATE)
        // this.RegisterEvent("PLAYER_DAMAGE_DONE_MODS"); // SpellBonusHealing (not really needed; spell power covered by SPELL_POWER_CHANGED)
        this.RegisterMessage("Ovale_EquipmentChanged", "UpdateDamage");
        // this.RegisterMessage("Ovale_StanceChanged", "UpdateDamage"); // Shouldn't be needed anymore, UNIT_DAMAGE covers it
        this.RegisterMessage("Ovale_TalentsChanged", "UpdateStats");
        lastSpell.RegisterSpellcastInfo(this);
    }
    OnDisable() {
        lastSpell.UnregisterSpellcastInfo(this);
        this.UnregisterEvent("UNIT_STATS");
        this.UnregisterEvent("COMBAT_RATING_UPDATE");
        this.UnregisterEvent("MASTERY_UPDATE");
        this.UnregisterEvent("UNIT_ATTACK_POWER");
        this.UnregisterEvent("UNIT_RANGED_ATTACK_POWER");
        this.UnregisterEvent("SPELL_POWER_CHANGED");
        this.UnregisterEvent("UNIT_DAMAGE");
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("PLAYER_ALIVE");
        this.UnregisterEvent("PLAYER_LEVEL_UP");
        this.UnregisterEvent("UNIT_LEVEL");
        // this.UnregisterEvent("UNIT_ATTACK_SPEED");
        // this.UnregisterEvent("UNIT_RANGEDDAMAGE");
        // this.UnregisterEvent("UNIT_SPELL_HASTE");
        // this.UnregisterEvent("PLAYER_DAMAGE_DONE_MODS");
        this.UnregisterMessage("Ovale_EquipmentChanged");
        this.UnregisterMessage("Ovale_StanceChanged");
        this.UnregisterMessage("Ovale_TalentsChanged");
    }
    UNIT_STATS(event: string, unitId: string) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.current.strength = UnitStat(unitId, 1);
            this.current.agility = UnitStat(unitId, 2);
            this.current.stamina = UnitStat(unitId, 3);
            this.current.intellect = UnitStat(unitId, 4);
            // this.current.spirit = 0;
            this.current.snapshotTime = GetTime();
            Ovale.needRefresh();
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    COMBAT_RATING_UPDATE(event: string) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        // Crit
        this.current.critRating = GetCombatRating(CR_CRIT_MELEE);
        this.current.meleeCrit = GetCritChance();
        this.current.rangedCrit = GetRangedCritChance();
        this.current.spellCrit = GetSpellCritChance(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        // Haste
        this.current.hasteRating = GetCombatRating(CR_HASTE_MELEE);
        this.current.hastePercent = GetHaste();
        this.current.meleeAttackSpeedPercent = GetMeleeHaste();
        this.current.rangedAttackSpeedPercent = GetRangedHaste();
        this.current.spellCastSpeedPercent = UnitSpellHaste("player");
        // Versatility
        this.current.versatilityRating = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE);
        this.current.versatility = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE);

        this.current.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    MASTERY_UPDATE(event: string) {
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
    UNIT_ATTACK_POWER(event: string, unitId: string) {
        if (unitId == "player" && !OvaleEquipment.HasRangedWeapon()) {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            let [base, posBuff, negBuff] = UnitAttackPower(unitId);
            this.current.attackPower = base + posBuff + negBuff;
            this.current.snapshotTime = GetTime();
            Ovale.needRefresh();
            this.UpdateDamage(event);
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_RANGED_ATTACK_POWER(event: string, unitId: string) {
        if (unitId == "player" && OvaleEquipment.HasRangedWeapon()) {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            let [base, posBuff, negBuff] = UnitRangedAttackPower(unitId);
            Ovale.needRefresh();
            this.current.attackPower = base + posBuff + negBuff;
            this.current.snapshotTime = GetTime();
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    SPELL_POWER_CHANGED(event: string) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.current.spellPower = GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.current.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    PLAYER_LEVEL_UP(event: string, level: string, ...__args: any[]) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.level = tonumber(level) || UnitLevel("player");
        this.current.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.DebugTimestamp("%s: level = %d", event, this.level);
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    UNIT_LEVEL(event: string, unitId: string) {
        Ovale.refreshNeeded[unitId] = true;
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.level = UnitLevel(unitId);
            this.DebugTimestamp("%s: level = %d", event, this.level);
            this.current.snapshotTime = GetTime();
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    /*
    UNIT_ATTACK_SPEED(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.current.meleeAttackSpeedPercent = GetMeleeHaste();
            this.current.snapshotTime = GetTime();
            Ovale.needRefresh();
            this.UpdateDamage(event);
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_RANGEDDAMAGE(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.current.rangedAttackSpeedPercent = GetRangedHaste();
            this.current.snapshotTime = GetTime();
            Ovale.needRefresh();
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_SPELL_HASTE(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.current.spellCastSpeedPercent = UnitSpellHaste(unitId);
            this.current.snapshotTime = GetTime();
            Ovale.needRefresh();
            this.UpdateDamage(event);
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    PLAYER_DAMAGE_DONE_MODS(event, unitId) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.current.spellPower = GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.current.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    */
    UpdateDamage(event: string) {
        this.StartProfiling("OvalePaperDoll_UpdateDamage");
        let damageMultiplier = GetAppropriateDamageMultiplier("player");
        // let [mainHandAttackSpeed, offHandAttackSpeed] = UnitAttackSpeed("player"); // Could add back if we need something like calculating next swing

        // Appartently, if the character is not loaded, it returns 0
        if (damageMultiplier == 0) return;
        this.current.baseDamageMultiplier = damageMultiplier;
        this.current.mainHandWeaponDPS = OvaleEquipment.mainHandDPS || 0;
        this.current.offHandWeaponDPS = OvaleEquipment.offHandDPS || 0;
        this.current.snapshotTime = GetTime();
        Ovale.needRefresh();
        this.StopProfiling("OvalePaperDoll_UpdateDamage");
    }
    UpdateSpecialization(event: string) {
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
    UpdateStats(event: string) {
        this.UpdateSpecialization(event);
        this.UNIT_STATS(event, "player");
        this.COMBAT_RATING_UPDATE(event);
        this.MASTERY_UPDATE(event);
        this.UNIT_ATTACK_POWER(event, "player");
        this.UNIT_RANGED_ATTACK_POWER(event, "player");
        this.SPELL_POWER_CHANGED(event);
        //this.PLAYER_DAMAGE_DONE_MODS(event, "player");
        //this.UNIT_ATTACK_SPEED(event, "player");
        //this.UNIT_RANGEDDAMAGE(event, "player");
        //this.UNIT_SPELL_HASTE(event, "player");
        this.UpdateDamage(event);
    }
    GetSpecialization(specialization?: SpecializationIndex) {
        specialization = specialization || this.specialization || 1;
        return OVALE_SPECIALIZATION_NAME[this.class][specialization];
    }
    IsSpecialization(name: number | string) {
        if (name && this.specialization) {
            if (isNumber(name)) {
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
    GetBaseHasteMultiplier(snapshot?:PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.hastePercent / 100;
    } 
    GetMeleeAttackSpeedPercentMultiplier(snapshot?:PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.meleeAttackSpeedPercent / 100;
    } 
    GetRangedAttackSpeedPercentMultiplier(snapshot?:PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.rangedAttackSpeedPercent / 100;
    } 
    GetSpellCastSpeedPercentMultiplier(snapshot?:PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.spellCastSpeedPercent / 100;
    } 
    GetHasteMultiplier(haste: HasteType | undefined, snapshot:PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        let multiplier = this.GetBaseHasteMultiplier(snapshot) || 1;
        if (haste === "melee") {
            multiplier = this.GetMeleeAttackSpeedPercentMultiplier(snapshot);
        }  else if (haste === "ranged") {
            multiplier = this.GetRangedAttackSpeedPercentMultiplier(snapshot);
        }  else if (haste === "spell") {
            multiplier = this.GetSpellCastSpeedPercentMultiplier(snapshot);
        }
        return multiplier;
    }
    UpdateSnapshot(target:PaperDollSnapshot, snapshot?:PaperDollSnapshot, updateAllStats?: boolean) {
        snapshot = snapshot || this.current;
        let nameTable = (updateAllStats && STAT_NAME) || SNAPSHOT_STAT_NAME;
        for (const [,k] of ipairs(nameTable)) {
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

        this.next.strength = 0;
        this.next.agility = 0;
        this.next.stamina = 0;
        this.next.intellect = 0;
        // this.next.spirit = 0;

        this.next.attackPower = 0;
        this.next.spellPower = 0;
        // this.next.rangedAttackPower = 0;
        // this.next.spellBonusDamage = 0;
        // this.next.spellBonusHealing = 0;
        
        this.next.critRating = 0;
        this.next.meleeCrit = 0;
        this.next.rangedCrit = 0;
        this.next.spellCrit = 0;

        this.next.hasteRating = 0;
        this.next.hastePercent = 0;
        this.next.meleeAttackSpeedPercent = 0;
        this.next.rangedAttackSpeedPercent = 0;
        this.next.spellCastSpeedPercent = 0;

        this.next.masteryRating = 0;
        this.next.masteryEffect = 0;

        this.next.versatilityRating = 0;
        this.next.versatility = 0;

        this.next.mainHandWeaponDPS = 0;
        this.next.offHandWeaponDPS = 0;
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
