import { Tracer, DebugTools } from "../engine/debug";
import { Profiler, OvaleProfilerClass } from "../engine/profiler";
import { OvaleClass } from "../Ovale";
import { OvaleEquipmentClass } from "./Equipment";
import { States, StateModule } from "../engine/state";
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
    returnBoolean,
} from "../engine/condition";

const spellDamageSchools: LuaObj<number> = {
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

export const ovaleSpecializationName: {
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

const statName: LuaArray<keyof PaperDollSnapshot> = {
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
const snapshotStatName: LuaArray<keyof PaperDollSnapshot> = {
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
        ovaleDebug: DebugTools,
        ovaleProfiler: OvaleProfilerClass,
        private lastSpell: LastSpell
    ) {
        super(PaperDollData);
        this.class = ovale.playerClass;
        this.module = ovale.createModule(
            "OvalePaperDoll",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.debug = ovaleDebug.create("OvalePaperDoll");
        this.profiler = ovaleProfiler.create("OvalePaperDoll");
    }

    registerConditions(condition: OvaleConditionClass) {
        condition.registerCondition(
            "specialization",
            false,
            this.hasSpecialization
        );
    }

    private hasSpecialization: ConditionFunction = (positional) => {
        const [id] = unpack(positional);
        if (this.specialization)
            return returnBoolean(
                ovaleSpecializationName[this.class][this.specialization] === id
            );
        return [];
    };

    private getAppropriateDamageMultiplier(unit: string) {
        let damageMultiplier = 1;
        if (this.ovaleEquipement.hasRangedWeapon()) {
            [, , , , , damageMultiplier] = UnitRangedDamage(unit);
        } else {
            [, , , , , damageMultiplier] = UnitDamage(unit);
        }
        return damageMultiplier;
    }

    private handleInitialize = () => {
        // TODO this module should be the source of this value
        this.class = this.ovale.playerClass;
        this.module.RegisterEvent("UNIT_STATS", this.handleUnitStats); // Primary Stats (str, agi, sta, int)
        this.module.RegisterEvent(
            "COMBAT_RATING_UPDATE",
            this.handleCombatRatingUpdate
        ); // Secondary Stats (crit, haste, vers)
        this.module.RegisterEvent("MASTERY_UPDATE", this.handleMasteryUpdate); // Mastery
        this.module.RegisterEvent(
            "UNIT_ATTACK_POWER",
            this.handleUnitAttackPower
        ); // Attack Power
        this.module.RegisterEvent(
            "UNIT_RANGED_ATTACK_POWER",
            this.handleUnitRangedAttackPower
        ); // Ranged Attack Power
        this.module.RegisterEvent(
            "SPELL_POWER_CHANGED",
            this.handleSpellPowerChanged
        ); // Spell Power
        this.module.RegisterEvent("UNIT_DAMAGE", this.handleUpdateDamage); // Damage Multiplier
        this.module.RegisterEvent(
            "PLAYER_ENTERING_WORLD",
            this.handleUpdateStats
        );
        this.module.RegisterEvent("PLAYER_ALIVE", this.handleUpdateStats);
        this.module.RegisterEvent("PLAYER_LEVEL_UP", this.handlePlayerLevelUp);
        this.module.RegisterEvent("UNIT_LEVEL", this.handleUnitLevel);
        // this.RegisterEvent("UNIT_ATTACK_SPEED"); // Melee Haste (covered by COMBAT_RATING_UPDATE)
        // this.RegisterEvent("UNIT_RANGEDDAMAGE"); // Ranged Haste (covered by COMBAT_RATING_UPDATE)
        // this.RegisterEvent("UNIT_SPELL_HASTE"); // Spell Haste (covered by COMBAT_RATING_UPDATE)
        // this.RegisterEvent("PLAYER_DAMAGE_DONE_MODS"); // SpellBonusHealing (not really needed; spell power covered by SPELL_POWER_CHANGED)
        this.module.RegisterMessage(
            "Ovale_EquipmentChanged",
            this.handleUpdateDamage
        );
        // this.RegisterMessage("Ovale_StanceChanged", "UpdateDamage"); // Shouldn't be needed anymore, UNIT_DAMAGE covers it
        this.module.RegisterMessage(
            "Ovale_TalentsChanged",
            this.handleUpdateStats
        );
        this.lastSpell.registerSpellcastInfo(this);
    };
    private handleDisable = () => {
        this.lastSpell.unregisterSpellcastInfo(this);
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
    private handleUnitStats = (unitId: string) => {
        if (unitId == "player") {
            this.profiler.startProfiling("OvalePaperDoll_UpdateStats");
            this.current.strength = UnitStat(unitId, 1);
            this.current.agility = UnitStat(unitId, 2);
            this.current.stamina = UnitStat(unitId, 3);
            this.current.intellect = UnitStat(unitId, 4);
            // this.current.spirit = 0;
            this.current.snapshotTime = GetTime();
            this.ovale.needRefresh();
            this.profiler.stopProfiling("OvalePaperDoll_UpdateStats");
        }
    };
    private handleCombatRatingUpdate = () => {
        this.profiler.startProfiling("OvalePaperDoll_UpdateStats");
        // Crit
        this.current.critRating = GetCombatRating(CR_CRIT_MELEE);
        this.current.meleeCrit = GetCritChance();
        this.current.rangedCrit = GetRangedCritChance();
        this.current.spellCrit = GetSpellCritChance(
            spellDamageSchools[this.class]
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
        this.profiler.stopProfiling("OvalePaperDoll_UpdateStats");
    };
    private handleMasteryUpdate = () => {
        this.profiler.startProfiling("OvalePaperDoll_UpdateStats");
        this.current.masteryRating = GetMastery();
        if (this.level < 80) {
            this.current.masteryEffect = 0;
        } else {
            this.current.masteryEffect = GetMasteryEffect();
            this.ovale.needRefresh();
        }
        this.current.snapshotTime = GetTime();
        this.profiler.stopProfiling("OvalePaperDoll_UpdateStats");
    };
    private handleUnitAttackPower = (event: string, unitId: string) => {
        if (unitId == "player" && !this.ovaleEquipement.hasRangedWeapon()) {
            this.profiler.startProfiling("OvalePaperDoll_UpdateStats");
            const [base, posBuff, negBuff] = UnitAttackPower(unitId);
            this.current.attackPower = base + posBuff + negBuff;
            this.current.snapshotTime = GetTime();
            this.ovale.needRefresh();
            this.handleUpdateDamage();
            this.profiler.stopProfiling("OvalePaperDoll_UpdateStats");
        }
    };
    private handleUnitRangedAttackPower = (unitId: string) => {
        if (unitId == "player" && this.ovaleEquipement.hasRangedWeapon()) {
            this.profiler.startProfiling("OvalePaperDoll_UpdateStats");
            const [base, posBuff, negBuff] = UnitRangedAttackPower(unitId);
            this.ovale.needRefresh();
            this.current.attackPower = base + posBuff + negBuff;
            this.current.snapshotTime = GetTime();
            this.profiler.stopProfiling("OvalePaperDoll_UpdateStats");
        }
    };
    private handleSpellPowerChanged = () => {
        this.profiler.startProfiling("OvalePaperDoll_UpdateStats");
        this.current.spellPower = GetSpellBonusDamage(
            spellDamageSchools[this.class]
        );
        this.current.snapshotTime = GetTime();
        this.ovale.needRefresh();
        this.profiler.stopProfiling("OvalePaperDoll_UpdateStats");
    };
    private handlePlayerLevelUp = (event: string, level: string) => {
        this.profiler.startProfiling("OvalePaperDoll_UpdateStats");
        this.level = tonumber(level) || UnitLevel("player");
        this.current.snapshotTime = GetTime();
        this.ovale.needRefresh();
        this.debug.debugTimestamp("%s: level = %d", event, this.level);
        this.profiler.stopProfiling("OvalePaperDoll_UpdateStats");
    };
    private handleUnitLevel = (event: string, unitId: string) => {
        this.ovale.refreshNeeded[unitId] = true;
        if (unitId == "player") {
            this.profiler.startProfiling("OvalePaperDoll_UpdateStats");
            this.level = UnitLevel(unitId);
            this.debug.debugTimestamp("%s: level = %d", event, this.level);
            this.current.snapshotTime = GetTime();
            this.profiler.stopProfiling("OvalePaperDoll_UpdateStats");
        }
    };
    private handleUpdateDamage = () => {
        this.profiler.startProfiling("OvalePaperDoll_UpdateDamage");
        const damageMultiplier = this.getAppropriateDamageMultiplier("player");
        // let [mainHandAttackSpeed, offHandAttackSpeed] = UnitAttackSpeed("player"); // Could add back if we need something like calculating next swing

        // Appartently, if the character is not loaded, it returns 0
        this.current.baseDamageMultiplier = damageMultiplier || 1;
        this.current.mainHandWeaponDPS = this.ovaleEquipement.mainHandDPS || 0;
        this.current.offHandWeaponDPS = this.ovaleEquipement.offHandDPS || 0;
        this.current.snapshotTime = GetTime();
        this.ovale.needRefresh();
        this.profiler.stopProfiling("OvalePaperDoll_UpdateDamage");
    };
    updateSpecialization() {
        this.profiler.startProfiling("OvalePaperDoll_UpdateSpecialization");
        const newSpecialization = GetSpecialization();
        if (this.specialization != newSpecialization) {
            const oldSpecialization = this.specialization;
            this.specialization = newSpecialization;
            this.current.snapshotTime = GetTime();
            this.ovale.needRefresh();
            this.module.SendMessage(
                "Ovale_SpecializationChanged",
                this.getSpecialization(newSpecialization),
                this.getSpecialization(oldSpecialization)
            );
        }
        this.profiler.stopProfiling("OvalePaperDoll_UpdateSpecialization");
    }
    private handleUpdateStats = (event: string) => {
        this.updateSpecialization();
        this.handleUnitStats("player");
        this.handleCombatRatingUpdate();
        this.handleMasteryUpdate();
        this.handleUnitAttackPower(event, "player");
        this.handleUnitRangedAttackPower("player");
        this.handleSpellPowerChanged();
        //this.PLAYER_DAMAGE_DONE_MODS(event, "player");
        //this.UNIT_ATTACK_SPEED(event, "player");
        //this.UNIT_RANGEDDAMAGE(event, "player");
        //this.UNIT_SPELL_HASTE(event, "player");
        this.handleUpdateDamage();
    };
    getSpecialization(specialization?: SpecializationIndex) {
        specialization = specialization || this.specialization || 1;
        return ovaleSpecializationName[this.class][specialization] || "arms";
    }
    isSpecialization(name: number | string) {
        if (name && this.specialization) {
            if (isNumber(name)) {
                return name == this.specialization;
            } else {
                return (
                    name ==
                    ovaleSpecializationName[this.class][this.specialization]
                );
            }
        }
        return false;
    }
    getMasteryMultiplier(snapshot?: PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.masteryEffect / 100;
    }
    getBaseHasteMultiplier(snapshot?: PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.hastePercent / 100;
    }
    getMeleeAttackSpeedPercentMultiplier(snapshot?: PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.meleeAttackSpeedPercent / 100;
    }
    getRangedAttackSpeedPercentMultiplier(snapshot?: PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.rangedAttackSpeedPercent / 100;
    }
    getSpellCastSpeedPercentMultiplier(snapshot?: PaperDollSnapshot) {
        snapshot = snapshot || this.current;
        return 1 + snapshot.spellCastSpeedPercent / 100;
    }
    getHasteMultiplier(
        haste: HasteType | undefined,
        snapshot: PaperDollSnapshot
    ) {
        snapshot = snapshot || this.current;
        let multiplier = this.getBaseHasteMultiplier(snapshot) || 1;
        if (haste === "melee") {
            multiplier = this.getMeleeAttackSpeedPercentMultiplier(snapshot);
        } else if (haste === "ranged") {
            multiplier = this.getRangedAttackSpeedPercentMultiplier(snapshot);
        } else if (haste === "spell") {
            multiplier = this.getSpellCastSpeedPercentMultiplier(snapshot);
        }
        return multiplier;
    }
    updateSnapshot(
        target: PaperDollSnapshot,
        snapshot?: PaperDollSnapshot,
        updateAllStats?: boolean
    ) {
        snapshot = snapshot || this.current;
        const nameTable = (updateAllStats && statName) || snapshotStatName;
        for (const [, k] of ipairs(nameTable)) {
            const value = snapshot[k];
            if (value) target[k] = value;
        }
    }
    copySpellcastInfo = (spellcast: SpellCast, dest: SpellCast) => {
        this.updateSnapshot(dest, spellcast, true);
    };
    saveSpellcastInfo = (
        spellcast: SpellCast,
        atTime: number,
        state?: PaperDollSnapshot
    ) => {
        const paperDollModule = state || this.current;
        this.updateSnapshot(spellcast, paperDollModule, true);
    };
    initializeState() {
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
    cleanState(): void {}

    resetState() {
        this.updateSnapshot(this.next, this.current, true);
    }
}
