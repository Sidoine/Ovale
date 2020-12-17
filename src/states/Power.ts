import { L } from "../ui/Localization";
import { SpellCast } from "./LastSpell";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { ceil, huge as INFINITY, floor } from "@wowts/math";
import { pairs, LuaObj, LuaArray, kpairs } from "@wowts/lua";
import { lower } from "@wowts/string";
import { concat, insert } from "@wowts/table";
import {
    GetPowerRegen,
    GetManaRegen,
    GetSpellPowerCost,
    UnitPower,
    UnitPowerMax,
    UnitPowerType,
    Enum,
    MAX_COMBO_POINTS,
    ClassId,
} from "@wowts/wow-mock";
import { isNumber, OneTimeMessage } from "../tools/tools";
import { OvaleDebugClass, Tracer } from "../engine/debug";
import { BaseState } from "./BaseState";
import { OvaleDataClass } from "../engine/data";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import { States, StateModule } from "../engine/state";
import { OvaleProfilerClass, Profiler } from "../engine/profiler";
import { OvaleSpellBookClass } from "./SpellBook";
import { NamedParametersOf, AstActionNode } from "../engine/ast";
import { OvaleCombatClass } from "./combat";
import { OptionUiAll } from "../ui/acegui-helpers";

const strlower = lower;

const self_SpellcastInfoPowerTypes: LuaArray<PowerType> = {
    1: "chi",
    2: "holypower",
};

interface PowerInfo {
    id: number;
    token: string;
    type: PowerType;
    mini?: number;
    maxCost?: number;
    segments?: number;
}

class PowerState {
    powerType: PowerType = "mana";
    activeRegen: LuaObj<number> = {};
    inactiveRegen: LuaObj<number> = {};
    maxPower: LuaObj<number> = {};
    power: Powers = {};
}

const POWERS = {
    mana: true,
    rage: true,
    focus: true,
    energy: true,
    combopoints: true,
    runicpower: true,
    soulshards: true,
    lunarpower: true,
    holypower: true,
    alternate: true,
    maelstrom: true,
    chi: true,
    insanity: true,
    arcanecharges: true,
    pain: true,
    fury: true,
};

export type PowerType = keyof typeof POWERS;

export type Powers = {
    [K in PowerType]?: number;
};

export const POWER_TYPES: LuaArray<PowerType> = {};

export const POOLED_RESOURCE: { [key in ClassId]?: PowerType } = {
    ["DRUID"]: "energy",
    ["HUNTER"]: "focus",
    ["MONK"]: "energy",
    ["ROGUE"]: "energy",
};

export const PRIMARY_POWER: { [key in PowerType]?: boolean } = {
    energy: true,
    focus: true,
    mana: true,
};

export class OvalePowerClass extends States<PowerState> implements StateModule {
    POWER_INFO: { [k in PowerType]?: PowerInfo } = {};
    POWER_TYPE: LuaObj<PowerType> = {};

    private module: AceModule & AceEvent;
    private tracer: Tracer;
    private profiler: Profiler;

    constructor(
        ovaleDebug: OvaleDebugClass,
        private ovale: OvaleClass,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleData: OvaleDataClass,
        private baseState: BaseState,
        private ovaleSpellBook: OvaleSpellBookClass,
        private combat: OvaleCombatClass
    ) {
        super(PowerState);
        this.module = ovale.createModule(
            "OvalePower",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
        this.profiler = ovaleProfiler.create(this.module.GetName());
        const debugOptions: LuaObj<OptionUiAll> = {
            power: {
                name: L["power"],
                type: "group",
                args: {
                    power: {
                        name: L["power"],
                        type: "input",
                        multiline: 25,
                        width: "full",
                        get: (info: any) => {
                            return this.DebugPower();
                        },
                    },
                },
            },
        };
        for (const [k, v] of pairs(debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }
    }

    private OnInitialize = () => {
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.EventHandler);
        this.module.RegisterEvent("PLAYER_LEVEL_UP", this.EventHandler);
        this.module.RegisterEvent("UNIT_DISPLAYPOWER", this.UNIT_DISPLAYPOWER);
        this.module.RegisterEvent("UNIT_LEVEL", this.UNIT_LEVEL);
        this.module.RegisterEvent("UNIT_MAXPOWER", this.UNIT_MAXPOWER);
        this.module.RegisterEvent("UNIT_POWER_UPDATE", this.UNIT_POWER_UPDATE);
        this.module.RegisterEvent(
            "UNIT_POWER_FREQUENT",
            this.UNIT_POWER_UPDATE
        );
        this.module.RegisterEvent("UNIT_RANGEDDAMAGE", this.UNIT_RANGEDDAMAGE);
        this.module.RegisterEvent("UNIT_SPELL_HASTE", this.UNIT_RANGEDDAMAGE);
        this.module.RegisterMessage("Ovale_StanceChanged", this.EventHandler);
        this.module.RegisterMessage("Ovale_TalentsChanged", this.EventHandler);
        this.initializePower();
    };

    initializePower() {
        const possiblePowerTypes: {
            [k in ClassId]: { [k in PowerType]?: string };
        } = {
            DEATHKNIGHT: {
                runicpower: "RUNIC_POWER",
            },
            DEMONHUNTER: {
                pain: "PAIN",
                fury: "FURY",
            },
            DRUID: {
                mana: "MANA",
                rage: "RAGE",
                energy: "ENERGY",
                combopoints: "COMBO_POINTS",
                lunarpower: "LUNAR_POWER",
            },
            HUNTER: {
                focus: "FOCUS",
            },
            MAGE: {
                mana: "MANA",
                arcanecharges: "ARCANE_CHARGES",
            },
            MONK: {
                mana: "MANA",
                energy: "ENERGY",
                chi: "CHI",
            },
            PALADIN: {
                mana: "MANA",
                holypower: "HOLY_POWER",
            },
            PRIEST: {
                mana: "MANA",
                insanity: "INSANITY",
            },
            ROGUE: {
                energy: "ENERGY",
                combopoints: "COMBO_POINTS",
            },
            SHAMAN: {
                mana: "MANA",
                maelstrom: "MAELSTROM",
            },
            WARLOCK: {
                mana: "MANA",
                soulshards: "SOUL_SHARDS",
            },
            WARRIOR: {
                rage: "RAGE",
            },
        };

        for (const [powerType, powerId] of pairs(Enum.PowerType)) {
            const powerTypeLower = <PowerType>strlower(powerType);
            const powerToken =
                this.ovale.playerClass != undefined &&
                possiblePowerTypes[this.ovale.playerClass][powerTypeLower];
            if (powerToken) {
                this.POWER_TYPE[powerId] = powerTypeLower;
                this.POWER_TYPE[powerToken] = powerTypeLower;
                this.POWER_INFO[powerTypeLower] = {
                    id: powerId,
                    token: powerToken,
                    mini: 0,
                    type: powerTypeLower,
                    maxCost:
                        (powerTypeLower == "combopoints" && MAX_COMBO_POINTS) ||
                        0, // Not currently used.
                };
                insert(POWER_TYPES, powerTypeLower);
            }
        }
    }
    private OnDisable = () => {
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_LEVEL_UP");
        this.module.UnregisterEvent("UNIT_DISPLAYPOWER");
        this.module.UnregisterEvent("UNIT_LEVEL");
        this.module.UnregisterEvent("UNIT_MAXPOWER");
        this.module.UnregisterEvent("UNIT_POWER_UPDATE");
        this.module.UnregisterEvent("UNIT_POWER_FREQUENT");
        this.module.UnregisterEvent("UNIT_RANGEDDAMAGE");
        this.module.UnregisterEvent("UNIT_SPELL_HASTE");
        this.module.UnregisterMessage("Ovale_StanceChanged");
        this.module.UnregisterMessage("Ovale_TalentsChanged");
    };
    private EventHandler = (event: string) => {
        this.UpdatePowerType(event);
        this.UpdateMaxPower(event);
        this.UpdatePower(event);
        this.UpdatePowerRegen(event);
    };
    private UNIT_DISPLAYPOWER = (event: string, unitId: string) => {
        if (unitId == "player") {
            this.UpdatePowerType(event);
            this.UpdatePowerRegen(event);
        }
    };
    private UNIT_LEVEL = (event: string, unitId: string) => {
        if (unitId == "player") {
            this.EventHandler(event);
        }
    };

    private UNIT_MAXPOWER = (
        event: string,
        unitId: string,
        powerToken: string
    ) => {
        if (unitId == "player") {
            const powerType = this.POWER_TYPE[powerToken];
            if (powerType) {
                this.UpdateMaxPower(event, powerType);
            }
        }
    };

    private UNIT_POWER_UPDATE = (
        event: string,
        unitId: string,
        powerToken: string
    ) => {
        if (unitId == "player") {
            const powerType = this.POWER_TYPE[powerToken];
            if (powerType) {
                this.UpdatePower(event, powerType);
            }
        }
    };

    private UNIT_RANGEDDAMAGE = (event: string, unitId: string) => {
        if (unitId == "player") {
            this.UpdatePowerRegen(event);
        }
    };

    private UpdateMaxPower(event: string, powerType?: PowerType) {
        this.profiler.StartProfiling("OvalePower_UpdateMaxPower");
        if (powerType) {
            const powerInfo = this.POWER_INFO[powerType];
            if (powerInfo) {
                const maxPower = UnitPowerMax(
                    "player",
                    powerInfo.id,
                    powerInfo.segments
                );
                if (this.current.maxPower[powerType] != maxPower) {
                    this.current.maxPower[powerType] = maxPower;
                    this.ovale.needRefresh();
                }
            }
        } else {
            for (const [powerType, powerInfo] of pairs(this.POWER_INFO)) {
                const maxPower = UnitPowerMax(
                    "player",
                    powerInfo.id,
                    powerInfo.segments
                );
                if (this.current.maxPower[powerType] != maxPower) {
                    this.current.maxPower[powerType] = maxPower;
                    this.ovale.needRefresh();
                }
            }
        }
        this.profiler.StopProfiling("OvalePower_UpdateMaxPower");
    }
    private UpdatePower(event: string, powerType?: PowerType) {
        this.profiler.StartProfiling("OvalePower_UpdatePower");
        if (powerType) {
            const powerInfo = this.POWER_INFO[powerType];
            if (powerInfo) {
                const power = UnitPower(
                    "player",
                    powerInfo.id,
                    powerInfo.segments
                );
                this.tracer.DebugTimestamp(
                    "%s: %d -> %d (%s).",
                    event,
                    this.current.power[powerType],
                    power,
                    powerType
                );
                if (this.current.power[powerType] != power) {
                    this.current.power[powerType] = power;
                }
            }
        } else {
            for (const [powerType, powerInfo] of kpairs(this.POWER_INFO)) {
                const power = UnitPower(
                    "player",
                    powerInfo.id,
                    powerInfo.segments
                );
                this.tracer.DebugTimestamp(
                    "%s: %d -> %d (%s).",
                    event,
                    this.current.power[powerType],
                    power,
                    powerType
                );
                if (this.current.power[powerType] != power) {
                    this.current.power[powerType] = power;
                }
            }
        }
        if (event == "UNIT_POWER_UPDATE") {
            this.ovale.needRefresh();
        }
        this.profiler.StopProfiling("OvalePower_UpdatePower");
    }
    private UpdatePowerRegen(event: string) {
        this.profiler.StartProfiling("OvalePower_UpdatePowerRegen");
        for (const [powerType] of pairs(this.POWER_INFO)) {
            const currentType = this.current.powerType;
            if (powerType == currentType) {
                const [inactiveRegen, activeRegen] = GetPowerRegen();
                [
                    this.current.inactiveRegen[powerType],
                    this.current.activeRegen[powerType],
                ] = [inactiveRegen, activeRegen];
                this.ovale.needRefresh();
            } else if (powerType == "mana") {
                const [inactiveRegen, activeRegen] = GetManaRegen();
                [
                    this.current.inactiveRegen[powerType],
                    this.current.activeRegen[powerType],
                ] = [inactiveRegen, activeRegen];
                this.ovale.needRefresh();
            } else if (this.current.activeRegen[powerType] == undefined) {
                let [inactiveRegen, activeRegen] = [0, 0];
                if (powerType == "energy") {
                    [inactiveRegen, activeRegen] = [10, 10];
                }
                [
                    this.current.inactiveRegen[powerType],
                    this.current.activeRegen[powerType],
                ] = [inactiveRegen, activeRegen];
                this.ovale.needRefresh();
            }
        }
        this.profiler.StopProfiling("OvalePower_UpdatePowerRegen");
    }
    private UpdatePowerType(event: string) {
        this.profiler.StartProfiling("OvalePower_UpdatePowerType");
        const [powerId] = UnitPowerType("player");
        const powerType = this.POWER_TYPE[powerId];
        if (this.current.powerType != powerType) {
            this.current.powerType = powerType;
            this.ovale.needRefresh();
        }
        this.profiler.StopProfiling("OvalePower_UpdatePowerType");
    }
    GetSpellCost(
        spell: number | string,
        powerType?: PowerType
    ): [number, PowerType] | [undefined, undefined] {
        const spellId = this.ovaleSpellBook.getKnownSpellId(spell);
        if (spellId) {
            const spellPowerCosts = GetSpellPowerCost(spellId);
            const spellPowerCost = spellPowerCosts && spellPowerCosts[1];
            if (spellPowerCost) {
                const cost = spellPowerCost.cost;
                const typeId = spellPowerCost.type;
                for (const [pt, p] of pairs(this.POWER_INFO)) {
                    if (
                        p.id == typeId &&
                        (powerType == undefined || pt == powerType)
                    ) {
                        return [cost, p.type];
                    }
                }
            }
        } else {
            OneTimeMessage(`No spell cost for ${spell}`);
        }
        return [undefined, undefined];
    }

    DebugPower() {
        const array = {};
        insert(array, `Current Power Type: ${this.current.powerType}`);
        for (const [powerType, v] of pairs(this.current.power)) {
            insert(array, `\nPower Type: ${powerType}`);
            insert(array, `Power: ${v} / ${this.current.maxPower[powerType]}`);
            insert(
                array,
                `Active Regen: / ${this.current.activeRegen[powerType]}`
            );
            insert(
                array,
                `Inactive Regen: / ${this.current.inactiveRegen[powerType]}`
            );
        }
        return concat(array, "\n");
    }
    CopySpellcastInfo = (mod: this, spellcast: SpellCast, dest: SpellCast) => {
        for (const [, powerType] of pairs(self_SpellcastInfoPowerTypes)) {
            if (spellcast[powerType]) {
                dest[powerType] = spellcast[powerType];
            }
        }
    };

    TimeToPower(
        spellId: number,
        atTime: number,
        targetGUID: string | undefined,
        powerType: PowerType | undefined,
        extraPower?: NamedParametersOf<AstActionNode>
    ) {
        return this.getTimeToPowerStateAt(
            this.GetState(atTime),
            spellId,
            atTime,
            targetGUID,
            powerType,
            extraPower
        );
    }

    InitializeState() {
        for (const [powerType] of kpairs(this.POWER_INFO)) {
            this.next.power[powerType] = 0;
            [
                this.next.inactiveRegen[powerType],
                this.next.activeRegen[powerType],
            ] = [0, 0];
        }
    }
    ResetState() {
        this.profiler.StartProfiling("OvalePower_ResetState");
        for (const [powerType] of kpairs(this.POWER_INFO)) {
            this.next.power[powerType] = this.current.power[powerType] || 0;
            this.next.maxPower[powerType] =
                this.current.maxPower[powerType] || 0;
            this.next.activeRegen[powerType] =
                this.current.activeRegen[powerType] || 0;
            this.next.inactiveRegen[powerType] =
                this.current.inactiveRegen[powerType] || 0;
        }
        this.profiler.StopProfiling("OvalePower_ResetState");
    }
    CleanState() {
        for (const [powerType] of kpairs(this.POWER_INFO)) {
            this.next.power[powerType] = undefined;
        }
    }
    ApplySpellStartCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.StartProfiling("OvalePower_ApplySpellStartCast");
        if (isChanneled) {
            this.ApplyPowerCost(spellId, targetGUID, startCast, spellcast);
        }
        this.profiler.StopProfiling("OvalePower_ApplySpellStartCast");
    };
    ApplySpellAfterCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.StartProfiling("OvalePower_ApplySpellAfterCast");
        if (!isChanneled) {
            this.ApplyPowerCost(spellId, targetGUID, endCast, spellcast);
        }
        this.profiler.StopProfiling("OvalePower_ApplySpellAfterCast");
    };

    ApplyPowerCost(
        spellId: number,
        targetGUID: string,
        atTime: number,
        spellcast: SpellCast
    ) {
        this.profiler.StartProfiling("OvalePower_state_ApplyPowerCost");
        const si = this.ovaleData.spellInfo[spellId];
        {
            const [cost, powerType] = this.GetSpellCost(spellId);
            if (
                cost &&
                powerType &&
                this.next.power[powerType] &&
                !(si && si[powerType])
            ) {
                const power = this.next.power[powerType];
                if (power) this.next.power[powerType] = power - cost;
            }
        }
        if (si) {
            for (const [powerType, powerInfo] of kpairs(this.POWER_INFO)) {
                let [cost, refund] = this.getPowerCostAt(
                    this.next,
                    spellId,
                    powerInfo.type,
                    atTime,
                    targetGUID
                );
                let power = this.getPowerAt(this.next, powerType, atTime);
                const mini = powerInfo.mini || 0;
                if (power - cost < mini) {
                    cost = power;
                }
                power = (this.next.power[powerType] || 0) + refund - cost;
                const maxi = this.current.maxPower[powerType];
                if (maxi !== undefined && power > maxi) {
                    power = maxi;
                }
                this.next.power[powerType] = power;
            }
        }
        this.profiler.StopProfiling("OvalePower_state_ApplyPowerCost");
    }

    PowerCost(
        spellId: number,
        powerType: PowerType,
        atTime: number,
        targetGUID: string,
        maximumCost?: boolean
    ) {
        return this.getPowerCostAt(
            this.GetState(atTime),
            spellId,
            powerType,
            atTime,
            targetGUID,
            maximumCost
        );
    }

    /**
     * Power regeneration rate for the given powerType.
     * @param powerType
     */
    getPowerRateAt(
        state: PowerState,
        powerType: string,
        atTime: number
    ): number {
        let rate: number;
        if (this.combat.isInCombat(atTime)) {
            rate = state.activeRegen[powerType] || 0;
        } else {
            rate = state.inactiveRegen[powerType] || 0;
        }
        const REGEN_RATE_MIN_THRESHOLD = 0.05;
        if (
            (rate > 0 && rate < REGEN_RATE_MIN_THRESHOLD) ||
            (rate < 0 && rate > -1 * REGEN_RATE_MIN_THRESHOLD)
        ) {
            rate = 0;
        }
        return rate;
    }

    /**
     * Power atTime for the given powerType.
     * @param powerType
     * @param atTime
     */
    getPowerAt(
        state: PowerState,
        powerType: PowerType,
        atTime: number
    ): number {
        let power = state.power[powerType] || 0;
        const now = this.baseState.currentTime;
        const seconds = atTime - now;
        const powerRate = this.getPowerRateAt(state, powerType, atTime);
        power = power + powerRate * seconds;
        return power;
    }

    /**
     * Number of seconds until powrLevel is reached atTime for the powerType.
     * @param powerLevel
     * @param powerType
     * @param atTime
     */
    getTimeToPowerAt(
        state: PowerState,
        powerLevel: number,
        powerType: PowerType,
        atTime: number,
    ): number {
        let seconds = INFINITY;
        const power = this.getPowerAt(state, powerType, atTime)
        if (power < powerLevel) {
            const powerRate = this.getPowerRateAt(state, powerType, atTime);
            if (powerRate > 0) {
                seconds = (powerLevel - power) / powerRate;
            }
        }
        return seconds;
    }

    hasPowerFor(
        spellId: number,
        atTime: number,
        targetGUID?: string
    ): boolean {
        const seconds = this.getTimeToPowerStateAt(
            this.GetState(atTime),
            spellId,
            atTime,
            targetGUID,
            undefined
        );
        return (seconds === 0);
    }

    /**
     * Returns the power cost of a spell atTime for the given powerType
     * @param spellId
     * @param powerType
     * @param atTime
     * @param targetGUID TODO: Necessary?
     * @param maximumCost Force using the maximum cost of the spell for spells that can vary in cost.
     * @return [spellCost, spellRefund]
     */
    private getPowerCostAt(
        state: PowerState,
        spellId: number,
        powerType: PowerType,
        atTime: number,
        targetGUID: string | undefined,
        maximumCost?: boolean
    ): [number, number] {
        this.profiler.StartProfiling("OvalePower_PowerCost");
        let spellCost = 0;
        let spellRefund = 0;
        const si = this.ovaleData.spellInfo[spellId];
        if (si && si[powerType]) {
            const setPowerValue = this.ovaleData.GetSpellInfoProperty(
                spellId,
                atTime,
                `set_${powerType}` as `set_${PowerType}`,
                targetGUID
            );
            if (setPowerValue !== undefined) {
                const power = this.getPowerAt(state, powerType, atTime);
                return [power - setPowerValue, 0];
            }

            let [cost, ratio] = this.ovaleData.GetSpellInfoPropertyNumber(
                spellId,
                atTime,
                powerType,
                targetGUID,
                true
            );
            if (ratio && ratio != 0) {
                const maxCostParam = `max_${powerType}` as `max_${PowerType}`;
                const maxCost = si[maxCostParam];
                if (maxCost) {
                    const power = this.getPowerAt(state, powerType, atTime);
                    if (power > maxCost || maximumCost) {
                        cost = maxCost;
                    } else if (power > cost) {
                        cost = power;
                    }
                }

                spellCost =
                    (cost > 0 && floor(cost * ratio)) || ceil(cost * ratio);

                const parameter = `refund_${powerType}` as `refund_${PowerType}`;
                const refund = this.ovaleData.getSpellInfoProperty(
                    si,
                    atTime,
                    parameter
                );

                if (refund == "cost") {
                    spellRefund = spellCost;
                } else if (isNumber(refund)) {
                    spellRefund = refund;
                }
            }
        } else {
            const [cost] = this.GetSpellCost(spellId, powerType);
            if (cost) {
                spellCost = cost;
            }
        }
        this.profiler.StopProfiling("OvalePower_PowerCost");
        return [spellCost, spellRefund];
    }

    /**
     * How many seconds until there is enough power to use the ability.
     * @param spellId
     * @param atTime
     * @param targetGUID
     * @param powerType
     * @param extraPower If true, will add this to the cost
     */
    private getTimeToPowerStateAt(
        state: PowerState,
        spellId: number,
        atTime: number,
        targetGUID: string | undefined,
        powerType: PowerType | undefined,
        extraPower?: NamedParametersOf<AstActionNode>
    ): number {
        let timeToPower = 0;
        const si = this.ovaleData.spellInfo[spellId];
        if (si) {
            for (const [, powerInfo] of kpairs(this.POWER_INFO)) {
                const pType = powerInfo.type;
                if (powerType === undefined || powerType == pType) {
                    let [cost] = this.getPowerCostAt(
                        state,
                        spellId,
                        pType,
                        atTime,
                        targetGUID
                    );
                    if (cost > 0) {
                        this.tracer.Log("    Spell ID '%d' has cost of %d %s",
                            spellId,
                            cost,
                            pType
                        );
                        if (extraPower) {
                            let extraAmount
                            if (pType == "energy") {
                                extraAmount = extraPower.extra_energy;
                            } else if (pType == "focus") {
                                extraAmount = extraPower.extra_focus;
                            }
                            if (isNumber(extraAmount)) {
                                this.tracer.Log(
                                    "        Including extra power %d for %s",
                                    extraAmount,
                                    pType
                                );
                                cost = cost + <number>extraAmount;
                            }
                        }
                        const seconds = this.getTimeToPowerAt(
                            state,
                            cost,
                            pType,
                            atTime
                        );
                        this.tracer.Log(
                            "        Requires %f seconds to %d %s",
                            seconds,
                            cost,
                            pType
                        );
                        if (timeToPower < seconds) {
                            timeToPower = seconds;
                        }
                        if (timeToPower === INFINITY) break;
                    }
                }
            }
        }
        this.tracer.Log(
            "Spell ID '%d' requires %f seconds for power requirements.",
            spellId,
            timeToPower
        );
        return timeToPower;
    }
}
