import { l } from "../ui/Localization";
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
import { isNumber, oneTimeMessage } from "../tools/tools";
import { DebugTools, Tracer } from "../engine/debug";
import { BaseState } from "./BaseState";
import { OvaleDataClass } from "../engine/data";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import { States, StateModule } from "../engine/state";
import { OvaleProfilerClass, Profiler } from "../engine/profiler";
import { OvaleSpellBookClass } from "./SpellBook";
import { OvaleCombatClass } from "./combat";
import { OptionUiAll } from "../ui/acegui-helpers";

const strlower = lower;

const spellcastInfoPowerTypes: LuaArray<PowerType> = {
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

const powers = {
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

export type PowerType = keyof typeof powers;

export type Powers = {
    [K in PowerType]?: number;
};

export const powerTypes: LuaArray<PowerType> = {};

export const pooledResources: { [key in ClassId]?: PowerType } = {
    ["DRUID"]: "energy",
    ["HUNTER"]: "focus",
    ["MONK"]: "energy",
    ["ROGUE"]: "energy",
};

export const primaryPowers: { [key in PowerType]?: boolean } = {
    energy: true,
    focus: true,
    mana: true,
};

export class OvalePowerClass extends States<PowerState> implements StateModule {
    powerInfos: { [k in PowerType]?: PowerInfo } = {};
    powerTypes: LuaObj<PowerType> = {};

    private module: AceModule & AceEvent;
    private tracer: Tracer;
    private profiler: Profiler;

    constructor(
        ovaleDebug: DebugTools,
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
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
        this.profiler = ovaleProfiler.create(this.module.GetName());
        const debugOptions: LuaObj<OptionUiAll> = {
            power: {
                name: l["power"],
                type: "group",
                args: {
                    power: {
                        name: l["power"],
                        type: "input",
                        multiline: 25,
                        width: "full",
                        get: (info: any) => {
                            return this.debugPower();
                        },
                    },
                },
            },
        };
        for (const [k, v] of pairs(debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }
    }

    private handleInitialize = () => {
        this.module.RegisterEvent(
            "PLAYER_ENTERING_WORLD",
            this.handleEventHandler
        );
        this.module.RegisterEvent("PLAYER_LEVEL_UP", this.handleEventHandler);
        this.module.RegisterEvent(
            "UNIT_DISPLAYPOWER",
            this.handleUnitDisplayPower
        );
        this.module.RegisterEvent("UNIT_LEVEL", this.handleUnitLevel);
        this.module.RegisterEvent("UNIT_MAXPOWER", this.handleUnitMaxPower);
        this.module.RegisterEvent(
            "UNIT_POWER_UPDATE",
            this.handleUnitPowerUpdate
        );
        this.module.RegisterEvent(
            "UNIT_POWER_FREQUENT",
            this.handleUnitPowerUpdate
        );
        this.module.RegisterEvent(
            "UNIT_RANGEDDAMAGE",
            this.handleUnitRangedDamage
        );
        this.module.RegisterEvent(
            "UNIT_SPELL_HASTE",
            this.handleUnitRangedDamage
        );
        this.module.RegisterMessage(
            "Ovale_StanceChanged",
            this.handleEventHandler
        );
        this.module.RegisterMessage(
            "Ovale_TalentsChanged",
            this.handleEventHandler
        );
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
                this.powerTypes[powerId] = powerTypeLower;
                this.powerTypes[powerToken] = powerTypeLower;
                this.powerInfos[powerTypeLower] = {
                    id: powerId,
                    token: powerToken,
                    mini: 0,
                    type: powerTypeLower,
                    maxCost:
                        (powerTypeLower == "combopoints" && MAX_COMBO_POINTS) ||
                        0, // Not currently used.
                };
                insert(powerTypes, powerTypeLower);
            }
        }
    }
    private handleDisable = () => {
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
    private handleEventHandler = (event: string) => {
        this.updatePowerType(event);
        this.updateMaxPower(event);
        this.updatePower(event);
        this.updatePowerRegen(event);
    };
    private handleUnitDisplayPower = (event: string, unitId: string) => {
        if (unitId == "player") {
            this.updatePowerType(event);
            this.updatePowerRegen(event);
        }
    };
    private handleUnitLevel = (event: string, unitId: string) => {
        if (unitId == "player") {
            this.handleEventHandler(event);
        }
    };

    private handleUnitMaxPower = (
        event: string,
        unitId: string,
        powerToken: string
    ) => {
        if (unitId == "player") {
            const powerType = this.powerTypes[powerToken];
            if (powerType) {
                this.updateMaxPower(event, powerType);
            }
        }
    };

    private handleUnitPowerUpdate = (
        event: string,
        unitId: string,
        powerToken: string
    ) => {
        if (unitId == "player") {
            const powerType = this.powerTypes[powerToken];
            if (powerType) {
                this.updatePower(event, powerType);
            }
        }
    };

    private handleUnitRangedDamage = (event: string, unitId: string) => {
        if (unitId == "player") {
            this.updatePowerRegen(event);
        }
    };

    private updateMaxPower(event: string, powerType?: PowerType) {
        this.profiler.startProfiling("OvalePower_UpdateMaxPower");
        if (powerType) {
            const powerInfo = this.powerInfos[powerType];
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
            for (const [powerType, powerInfo] of pairs(this.powerInfos)) {
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
        this.profiler.stopProfiling("OvalePower_UpdateMaxPower");
    }
    private updatePower(event: string, powerType?: PowerType) {
        this.profiler.startProfiling("OvalePower_UpdatePower");
        if (powerType) {
            const powerInfo = this.powerInfos[powerType];
            if (powerInfo) {
                const power = UnitPower(
                    "player",
                    powerInfo.id,
                    powerInfo.segments
                );
                this.tracer.debugTimestamp(
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
            for (const [powerType, powerInfo] of kpairs(this.powerInfos)) {
                const power = UnitPower(
                    "player",
                    powerInfo.id,
                    powerInfo.segments
                );
                this.tracer.debugTimestamp(
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
        this.profiler.stopProfiling("OvalePower_UpdatePower");
    }
    private updatePowerRegen(event: string) {
        this.profiler.startProfiling("OvalePower_UpdatePowerRegen");
        for (const [powerType] of pairs(this.powerInfos)) {
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
        this.profiler.stopProfiling("OvalePower_UpdatePowerRegen");
    }
    private updatePowerType(event: string) {
        this.profiler.startProfiling("OvalePower_UpdatePowerType");
        const [powerId] = UnitPowerType("player");
        const powerType = this.powerTypes[powerId];
        if (this.current.powerType != powerType) {
            this.current.powerType = powerType;
            this.ovale.needRefresh();
        }
        this.profiler.stopProfiling("OvalePower_UpdatePowerType");
    }
    getSpellCost(
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
                for (const [pt, p] of pairs(this.powerInfos)) {
                    if (
                        p.id == typeId &&
                        (powerType == undefined || pt == powerType)
                    ) {
                        return [cost, p.type];
                    }
                }
            }
        } else {
            oneTimeMessage(`No spell cost for ${spell}`);
        }
        return [undefined, undefined];
    }

    debugPower() {
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
    copySpellcastInfo = (mod: this, spellcast: SpellCast, dest: SpellCast) => {
        for (const [, powerType] of pairs(spellcastInfoPowerTypes)) {
            if (spellcast[powerType]) {
                dest[powerType] = spellcast[powerType];
            }
        }
    };

    initializeState() {
        for (const [powerType] of kpairs(this.powerInfos)) {
            this.next.power[powerType] = 0;
            [
                this.next.inactiveRegen[powerType],
                this.next.activeRegen[powerType],
            ] = [0, 0];
        }
    }
    resetState() {
        this.profiler.startProfiling("OvalePower_ResetState");
        for (const [powerType] of kpairs(this.powerInfos)) {
            this.next.power[powerType] = this.current.power[powerType] || 0;
            this.next.maxPower[powerType] =
                this.current.maxPower[powerType] || 0;
            this.next.activeRegen[powerType] =
                this.current.activeRegen[powerType] || 0;
            this.next.inactiveRegen[powerType] =
                this.current.inactiveRegen[powerType] || 0;
        }
        this.profiler.stopProfiling("OvalePower_ResetState");
    }
    cleanState() {
        for (const [powerType] of kpairs(this.powerInfos)) {
            this.next.power[powerType] = undefined;
        }
    }
    applySpellStartCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.startProfiling("OvalePower_ApplySpellStartCast");
        if (isChanneled) {
            this.applyPowerCost(spellId, targetGUID, startCast, spellcast);
        }
        this.profiler.stopProfiling("OvalePower_ApplySpellStartCast");
    };
    applySpellAfterCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.startProfiling("OvalePower_ApplySpellAfterCast");
        if (!isChanneled) {
            this.applyPowerCost(spellId, targetGUID, endCast, spellcast);
        }
        this.profiler.stopProfiling("OvalePower_ApplySpellAfterCast");
    };

    applyPowerCost(
        spellId: number,
        targetGUID: string,
        atTime: number,
        spellcast: SpellCast
    ) {
        this.profiler.startProfiling("OvalePower_state_ApplyPowerCost");
        const si = this.ovaleData.spellInfo[spellId];
        {
            const [cost, powerType] = this.getSpellCost(spellId);
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
            for (const [powerType, powerInfo] of kpairs(this.powerInfos)) {
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
        this.profiler.stopProfiling("OvalePower_state_ApplyPowerCost");
    }

    powerCost(
        spellId: number,
        powerType: PowerType,
        atTime: number,
        targetGUID: string | undefined,
        maximumCost?: boolean
    ) {
        return this.getPowerCostAt(
            this.getState(atTime),
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
        const regenRateMinThreshold = 0.05;
        if (
            (rate > 0 && rate < regenRateMinThreshold) ||
            (rate < 0 && rate > -1 * regenRateMinThreshold)
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
        atTime: number
    ): number {
        const power = this.getPowerAt(state, powerType, atTime);
        if (power < powerLevel) {
            let seconds = INFINITY;
            const powerRate = this.getPowerRateAt(state, powerType, atTime);
            if (powerRate > 0) {
                seconds = (powerLevel - power) / powerRate;
            }
            return seconds;
        }
        return 0;
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
        this.profiler.startProfiling("OvalePower_PowerCost");
        let spellCost = 0;
        let spellRefund = 0;
        const si = this.ovaleData.spellInfo[spellId];
        if (si && si[powerType]) {
            let [cost, ratio] = this.ovaleData.getSpellInfoPropertyNumber(
                spellId,
                atTime,
                powerType,
                targetGUID,
                true
            );
            const setPowerValue = this.ovaleData.getProperty(
                si,
                atTime,
                `set_${powerType}` as `set_${PowerType}`
            );
            if (isNumber(setPowerValue)) {
                const power = this.getPowerAt(state, powerType, atTime);
                spellCost = power - setPowerValue;
                if (spellCost < cost) {
                    spellCost = cost;
                }
            } else {
                const maxCost = this.ovaleData.getProperty(
                    si,
                    atTime,
                    `max_${powerType}` as `max_${PowerType}`
                );
                if (isNumber(maxCost)) {
                    const power = this.getPowerAt(state, powerType, atTime);
                    if (power > maxCost || maximumCost) {
                        if (cost < maxCost) {
                            cost = maxCost;
                        }
                    } else if (power > cost) {
                        cost = power;
                    }
                }
                if (ratio && ratio != 0) {
                    if (cost > 0) {
                        spellCost = floor(cost * ratio);
                    } else {
                        spellCost = ceil(cost * ratio);
                    }
                }
            }
            const refund = this.ovaleData.getProperty(
                si,
                atTime,
                `refund_${powerType}` as `refund_${PowerType}`
            );
            if (refund == "cost") {
                spellRefund = spellCost;
            } else if (isNumber(refund)) {
                spellRefund = refund;
            }
        } else {
            const [cost] = this.getSpellCost(spellId, powerType);
            if (cost) {
                spellCost = cost;
            }
        }
        this.profiler.stopProfiling("OvalePower_PowerCost");
        return [spellCost, spellRefund];
    }
}
