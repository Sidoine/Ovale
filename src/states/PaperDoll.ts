import { Tracer, OvaleDebugClass } from "../engine/Debug";
import { Profiler, OvaleProfilerClass } from "../engine/Profiler";
import { OvaleClass } from "../Ovale";
import { OvaleEquipmentClass } from "./Equipment";
import { States, StateModule } from "../engine/State";
import {
    SpellCast,
    PaperDollSnapshot,
    SpellCastModule,
    LastSpell,
} from "./LastSpell";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { tonumber, LuaObj, LuaArray, ipairs, unpack } from "@wowts/lua";
import {
    GetCombatRating,
    GetCombatRatingBonus,
    GetCritChance,
    GetMastery,
    GetMasteryEffect,
    GetHaste,
    GetMeleeHaste,
    GetRangedCritChance,
    GetRangedHaste,
    GetSpecialization,
    GetSpellBonusDamage,
    GetSpellCritChance,
    GetTime,
    UnitAttackPower,
    UnitDamage,
    UnitRangedDamage,
    UnitLevel,
    UnitRangedAttackPower,
    UnitSpellHaste,
    UnitStat,
    CR_CRIT_MELEE,
    CR_HASTE_MELEE,
    CR_VERSATILITY_DAMAGE_DONE,
    ClassId,
    SpecializationIndex,
} from "@wowts/wow-mock";
import { isNumber } from "../tools/tools";
import { AceModule } from "@wowts/tsaddon";
import {
    ConditionFunction,
    OvaleConditionClass,
    ReturnBoolean,
    ReturnConstant,
} from "../engine/Condition";

const OVALE_SPELLDAMAGE_SCHOOL: LuaObj<number> = {
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
    WARRIOR: 4,
};

export type HasteType = "melee" | "spell" | "ranged" | "base" | "none";
export type SpecializationName =
    | "blood"
    | "frost"
    | "unholy"
    | "havoc"
    | "vengeance"
    | "restoration"
    | "guardian"
    | "mistweaver"
    | "brewmaster"
    | "feral"
    | "holy"
    | "protection"
    | "discipline"
    | "survival"
    | "marksmanship"
    | "beast_mastery"
    | "destruction"
    | "demonology"
    | "affliction"
    | "shadow"
    | "retribution"
    | "fire"
    | "arcane"
    | "subtlety"
    | "outlaw"
    | "assassination"
    | "balance"
    | "enhancement"
    | "elemental"
    | "fury"
    | "arms"
    | "windwalker";

export const OVALE_SPECIALIZATION_NAME: {
    [key in ClassId]: { [key in 1 | 2 | 3 | 4]?: SpecializationName };
} = {
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
        4: "restoration",
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
    },
};

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
    [23]: "baseDamageMultiplier",
};
const SNAPSHOT_STAT_NAME: LuaArray<keyof PaperDollSnapshot> = {
    [1]: "snapshotTime",
    [2]: "masteryEffect",
    [3]: "baseDamageMultiplier",
};

export class OvalePaperDollClass
    extends States<PaperDollSnapshot>
    implements SpellCastModule, StateModule {
    class: ClassId;
    level = UnitLevel("player");
    specialization: SpecializationIndex | undefined = undefined;
    private module: AceModule & AceEvent;
    private debug: Tracer;
    private profiler: Profiler;

    constructor(
        private ovaleEquipement: OvaleEquipmentClass,
        private ovale: OvaleClass,
        ovaleDebug: OvaleDebugClass,
        ovaleProfiler: OvaleProfilerClass,
        private lastSpell: LastSpell
    ) {
        super(PaperDollData);
        this.class = ovale.playerClass;
        this.module = ovale.createModule(
            "OvalePaperDoll",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
        this.debug = ovaleDebug.create("OvalePaperDoll");
        this.profiler = ovaleProfiler.create("OvalePaperDoll");
    }

    registerConditions(condition: OvaleConditionClass) {
        condition.RegisterCondition("level", false, this.getLevel);
        condition.RegisterCondition(
            "specialization",
            false,
            this.isSpecialization
        );
    }

    private getLevel: ConditionFunction = () => {
        return ReturnConstant(this.level);
    };

    private isSpecialization: ConditionFunction = (positional) => {
        const [id] = unpack(positional);
        if (this.specialization)
            return ReturnBoolean(
                OVALE_SPECIALIZATION_NAME[this.class][this.specialization] ===
                    id
            );
        return [];
    };

    private GetAppropriateDamageMultiplier(unit: string) {
        let damageMultiplier = 1;
        if (this.ovaleEquipement.HasRangedWeapon()) {
            [, , , , , damageMultiplier] = UnitRangedDamage(unit);
        } else {
            [, , , , , damageMultiplier] = UnitDamage(unit);
        }
        return damageMultiplier;
    }

    private OnInitialize = () => {
        // TODO this module should be the source of this value
        this.class = this.ovale.playerClass;
        this.module.RegisterEvent("UNIT_STATS", this.UNIT_STATS); // Primary Stats (str, agi, sta, int)
        this.module.RegisterEvent(
            "COMBAT_RATING_UPDATE",
            this.COMBAT_RATING_UPDATE
        ); // Secondary Stats (crit, haste, vers)
        this.module.RegisterEvent("MASTERY_UPDATE", this.MASTERY_UPDATE); // Mastery
        this.module.RegisterEvent("UNIT_ATTACK_POWER", this.UNIT_ATTACK_POWER); // Attack Power
        this.module.RegisterEvent(
            "UNIT_RANGED_ATTACK_POWER",
            this.UNIT_RANGED_ATTACK_POWER
        ); // Ranged Attack Power
        this.module.RegisterEvent(
            "SPELL_POWER_CHANGED",
            this.SPELL_POWER_CHANGED
        ); // Spell Power
        this.module.RegisterEvent("UNIT_DAMAGE", this.UpdateDamage); // Damage Multiplier
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.UpdateStats);
        this.module.RegisterEvent("PLAYER_ALIVE", this.UpdateStats);
        this.module.RegisterEvent("PLAYER_LEVEL_UP", this.PLAYER_LEVEL_UP);
        this.module.RegisterEvent("UNIT_LEVEL", this.UNIT_LEVEL);
        // this.RegisterEvent("UNIT_ATTACK_SPEED"); // Melee Haste (covered by COMBAT_RATING_UPDATE)
        // this.RegisterEvent("UNIT_RANGEDDAMAGE"); // Ranged Haste (covered by COMBAT_RATING_UPDATE)
        // this.RegisterEvent("UNIT_SPELL_HASTE"); // Spell Haste (covered by COMBAT_RATING_UPDATE)
        // this.RegisterEvent("PLAYER_DAMAGE_DONE_MODS"); // SpellBonusHealing (not really needed; spell power covered by SPELL_POWER_CHANGED)
        this.module.RegisterMessage(
            "Ovale_EquipmentChanged",
            this.UpdateDamage
        );
        // this.RegisterMessage("Ovale_StanceChanged", "UpdateDamage"); // Shouldn't be needed anymore, UNIT_DAMAGE covers it
        this.module.RegisterMessage("Ovale_TalentsChanged", this.UpdateStats);
        this.lastSpell.RegisterSpellcastInfo(this);
    };
    private OnDisable = () => {
        this.lastSpell.UnregisterSpellcastInfo(this);
        this.module.UnregisterEvent("UNIT_STATS");
        this.module.UnregisterEvent("COMBAT_RATING_UPDATE");
        this.module.UnregisterEvent("MASTERY_UPDATE");
        this.module.UnregisterEvent("UNIT_ATTACK_POWER");
        this.module.UnregisterEvent("UNIT_RANGED_ATTACK_POWER");
        this.module.UnregisterEvent("SPELL_POWER_CHANGED");
        this.module.UnregisterEvent("UNIT_DAMAGE");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_ALIVE");
        this.module.UnregisterEvent("PLAYER_LEVEL_UP");
        this.module.UnregisterEvent("UNIT_LEVEL");
        // this.UnregisterEvent("UNIT_ATTACK_SPEED");
        // this.UnregisterEvent("UNIT_RANGEDDAMAGE");
        // this.UnregisterEvent("UNIT_SPELL_HASTE");
        // this.UnregisterEvent("PLAYER_DAMAGE_DONE_MODS");
        this.module.UnregisterMessage("Ovale_EquipmentChanged");
        this.module.UnregisterMessage("Ovale_StanceChanged");
        this.module.UnregisterMessage("Ovale_TalentsChanged");
    };
    private UNIT_STATS = (unitId: string) => {
        if (unitId == "player") {
            this.profiler.StartProfiling("OvalePaperDoll_UpdateStats");
            this.current.strength = UnitStat(unitId, 1);
            this.current.agility = UnitStat(unitId, 2);
            this.current.stamina = UnitStat(unitId, 3);
            this.current.intellect = UnitStat(unitId, 4);
            // this.current.spirit = 0;
            this.current.snapshotTime = GetTime();
            this.ovale.needRefresh();
            this.profiler.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    };
    private COMBAT_RATING_UPDATE = () => {
        this.profiler.StartProfiling("OvalePaperDoll_UpdateStats");
        // Crit
        this.current.critRating = GetCombatRating(CR_CRIT_MELEE);
        this.current.meleeCrit = GetCritChance();
        this.current.rangedCrit = GetRangedCritChance();
        this.current.spellCrit = GetSpellCritChance(
            OVALE_SPELLDAMAGE_SCHOOL[this.class]
        );
        // Haste
        this.current.hasteRating = GetCombatRating(CR_HASTE_MELEE);
        this.current.hastePercent = GetHaste();
        this.current.meleeAttackSpeedPercent = GetMeleeHaste();
        this.current.rangedAttackSpeedPercent = GetRangedHaste();
        this.current.spellCastSpeedPercent = UnitSpellHaste("player");
        // Versatility
        this.current.versatilityRating = GetCombatRating(
            CR_VERSATILITY_DAMAGE_DONE
        );
        this.current.versatility = GetCombatRatingBonus(
            CR_VERSATILITY_DAMAGE_DONE
        );

        this.current.snapshotTime = GetTime();
        this.ovale.needRefresh();
        this.profiler.StopProfiling("OvalePaperDoll_UpdateStats");
    };
    private MASTERY_UPDATE = () => {
        this.profiler.StartProfiling("OvalePaperDoll_UpdateStats");
        this.current.masteryRating = GetMastery();
        if (this.level < 80) {
            this.current.masteryEffect = 0;
        } else {
            this.current.masteryEffect = GetMasteryEffect();
            this.ovale.needRefresh();
        }
        this.current.snapshotTime = GetTime();
        this.profiler.StopProfiling("OvalePaperDoll_UpdateStats");
    };
    private UNIT_ATTACK_POWER = (event: string, unitId: string) => {
        if (unitId == "player" && !this.ovaleEquipement.HasRangedWeapon()) {
            this.profiler.StartProfiling("OvalePaperDoll_UpdateStats");
            const [base, posBuff, negBuff] = UnitAttackPower(unitId);
            this.current.attackPower = base + posBuff + negBuff;
            this.current.snapshotTime = GetTime();
            this.ovale.needRefresh();
            this.UpdateDamage();
            this.profiler.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    };
    private UNIT_RANGED_ATTACK_POWER = (unitId: string) => {
        if (unitId == "player" && this.ovaleEquipement.HasRangedWeapon()) {
            this.profiler.StartProfiling("OvalePaperDoll_UpdateStats");
            const [base, posBuff, negBuff] = UnitRangedAttackPower(unitId);
            this.ovale.needRefresh();
            this.current.attackPower = base + posBuff + negBuff;
            this.current.snapshotTime = GetTime();
            this.profiler.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    };
    private SPELL_POWER_CHANGED = () => {
        this.profiler.StartProfiling("OvalePaperDoll_UpdateStats");
        this.current.spellPower = GetSpellBonusDamage(
            OVALE_SPELLDAMAGE_SCHOOL[this.class]
        );
        this.current.snapshotTime = GetTime();
        this.ovale.needRefresh();
        this.profiler.StopProfiling("OvalePaperDoll_UpdateStats");
    };
    private PLAYER_LEVEL_UP = (event: string, level: string) => {
        this.profiler.StartProfiling("OvalePaperDoll_UpdateStats");
        this.level = tonumber(level) || UnitLevel("player");
        this.current.snapshotTime = GetTime();
        this.ovale.needRefresh();
        this.debug.DebugTimestamp("%s: level = %d", event, this.level);
        this.profiler.StopProfiling("OvalePaperDoll_UpdateStats");
    };
    private UNIT_LEVEL = (event: string, unitId: string) => {
        this.ovale.refreshNeeded[unitId] = true;
        if (unitId == "player") {
            this.profiler.StartProfiling("OvalePaperDoll_UpdateStats");
            this.level = UnitLevel(unitId);
            this.debug.DebugTimestamp("%s: level = %d", event, this.level);
            this.current.snapshotTime = GetTime();
            this.profiler.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    };
    private UpdateDamage = () => {
        this.profiler.StartProfiling("OvalePaperDoll_UpdateDamage");
        const damageMultiplier = this.GetAppropriateDamageMultiplier("player");
        // let [mainHandAttackSpeed, offHandAttackSpeed] = UnitAttackSpeed("player"); // Could add back if we need something like calculating next swing

        // Appartently, if the character is not loaded, it returns 0
        this.current.baseDamageMultiplier = damageMultiplier || 1;
        this.current.mainHandWeaponDPS = this.ovaleEquipement.mainHandDPS || 0;
        this.current.offHandWeaponDPS = this.ovaleEquipement.offHandDPS || 0;
        this.current.snapshotTime = GetTime();
        this.ovale.needRefresh();
        this.profiler.StopProfiling("OvalePaperDoll_UpdateDamage");
    };
    UpdateSpecialization() {
        this.profiler.StartProfiling("OvalePaperDoll_UpdateSpecialization");
        const newSpecialization = GetSpecialization();
        if (this.specialization != newSpecialization) {
            const oldSpecialization = this.specialization;
            this.specialization = newSpecialization;
            this.current.snapshotTime = GetTime();
            this.ovale.needRefresh();
            this.module.SendMessage(
                "Ovale_SpecializationChanged",
                this.GetSpecialization(newSpecialization),
                this.GetSpecialization(oldSpecialization)
            );
        }
        this.profiler.StopProfiling("OvalePaperDoll_UpdateSpecialization");
    }
    private UpdateStats = (event: string) => {
        this.UpdateSpecialization();
        this.UNIT_STATS("player");
        this.COMBAT_RATING_UPDATE();
        this.MASTERY_UPDATE();
        this.UNIT_ATTACK_POWER(event, "player");
        this.UNIT_RANGED_ATTACK_POWER("player");
        this.SPELL_POWER_CHANGED();
        //this.PLAYER_DAMAGE_DONE_MODS(event, "player");
        //this.UNIT_ATTACK_SPEED(event, "player");
        //this.UNIT_RANGEDDAMAGE(event, "player");
        //this.UNIT_SPELL_HASTE(event, "player");
        this.UpdateDamage();
    };
    GetSpecialization(specialization?: SpecializationIndex) {
        specialization = specialization || this.specialization || 1;
        return OVALE_SPECIALIZATION_NAME[this.class][specialization] || "arms";
    }
    IsSpecialization(name: number | string) {
        if (name && this.specialization) {
            if (isNumber(name)) {
                return name == this.specialization;
            } else {
                return (
                    name ==
                    OVALE_SPECIALIZATION_NAME[this.class][this.specialization]
                );
            }
        }
        return false;
    }
    GetMasteryMultiplier(snapshot?: PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.masteryEffect / 100;
    }
    GetBaseHasteMultiplier(snapshot?: PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.hastePercent / 100;
    }
    GetMeleeAttackSpeedPercentMultiplier(snapshot?: PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.meleeAttackSpeedPercent / 100;
    }
    GetRangedAttackSpeedPercentMultiplier(snapshot?: PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.rangedAttackSpeedPercent / 100;
    }
    GetSpellCastSpeedPercentMultiplier(snapshot?: PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.spellCastSpeedPercent / 100;
    }
    GetHasteMultiplier(
        haste: HasteType | undefined,
        snapshot: PaperDollSnapshot
    ) {
        snapshot = snapshot || this.current;
        let multiplier = this.GetBaseHasteMultiplier(snapshot) || 1;
        if (haste === "melee") {
            multiplier = this.GetMeleeAttackSpeedPercentMultiplier(snapshot);
        } else if (haste === "ranged") {
            multiplier = this.GetRangedAttackSpeedPercentMultiplier(snapshot);
        } else if (haste === "spell") {
            multiplier = this.GetSpellCastSpeedPercentMultiplier(snapshot);
        }
        return multiplier;
    }
    UpdateSnapshot(
        target: PaperDollSnapshot,
        snapshot?: PaperDollSnapshot,
        updateAllStats?: boolean
    ) {
        snapshot = snapshot || this.current;
        const nameTable = (updateAllStats && STAT_NAME) || SNAPSHOT_STAT_NAME;
        for (const [, k] of ipairs(nameTable)) {
            const value = snapshot[k];
            if (value) target[k] = value;
        }
    }
    CopySpellcastInfo = (spellcast: SpellCast, dest: SpellCast) => {
        this.UpdateSnapshot(dest, spellcast, true);
    };
    SaveSpellcastInfo = (
        spellcast: SpellCast,
        atTime: number,
        state?: PaperDollSnapshot
    ) => {
        const paperDollModule = state || this.current;
        this.UpdateSnapshot(spellcast, paperDollModule, true);
    };
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
    CleanState(): void {}

    ResetState() {
        this.UpdateSnapshot(this.next, this.current, true);
    }
}
