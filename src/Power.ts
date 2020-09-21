import { L } from "./Localization";
import { Tokens, OvaleRequirement } from "./Requirement";
import { SpellCast } from "./LastSpell";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { ceil, huge as INFINITY, floor } from "@wowts/math";
import {
    ipairs,
    pairs,
    LuaObj,
    tostring,
    tonumber,
    LuaArray,
    kpairs,
} from "@wowts/lua";
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
import { isNumber, isLuaArray, OneTimeMessage } from "./tools";
import { OvaleDebugClass, Tracer } from "./Debug";
import { OvaleFutureClass } from "./Future";
import { BaseState } from "./BaseState";
import { OvaleDataClass, SpellInfo } from "./Data";
import { OvaleClass } from "./Ovale";
import { AceModule } from "@wowts/tsaddon";
import { OvaleAuraClass } from "./Aura";
import { States, StateModule } from "./State";
import { OvaleProfilerClass, Profiler } from "./Profiler";
import { OvalePaperDollClass } from "./PaperDoll";
import { OvaleSpellBookClass } from "./SpellBook";
import { Combat } from "./combat";

let strlower = lower;

let self_SpellcastInfoPowerTypes: LuaArray<PowerType> = {
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
        private ovaleFuture: OvaleFutureClass,
        private baseState: BaseState,
        private ovaleAura: OvaleAuraClass,
        private ovalePaperDoll: OvalePaperDollClass,
        private requirement: OvaleRequirement,
        private ovaleSpellBook: OvaleSpellBookClass,
        private combat: Combat
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
        let debugOptions = {
            power: {
                name: L["Power"],
                type: "group",
                args: {
                    power: {
                        name: L["Power"],
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
        for (const [powerType] of pairs(this.POWER_INFO)) {
            this.requirement.RegisterRequirement(
                powerType,
                this.RequirePowerHandler
            );
        }
    };

    initializePower() {
        let possiblePowerTypes: {
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
            let powerTypeLower = <PowerType>strlower(powerType);
            let powerToken =
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
        for (const [powerType] of pairs(this.POWER_INFO)) {
            this.requirement.UnregisterRequirement(powerType);
        }
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
            let powerType = this.POWER_TYPE[powerToken];
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
            let powerType = this.POWER_TYPE[powerToken];
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
            let powerInfo = this.POWER_INFO[powerType];
            if (powerInfo) {
                let maxPower = UnitPowerMax(
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
                let maxPower = UnitPowerMax(
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
            let powerInfo = this.POWER_INFO[powerType];
            if (powerInfo) {
                let power = UnitPower(
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
                let power = UnitPower(
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
            let currentType = this.current.powerType;
            if (powerType == currentType) {
                let [inactiveRegen, activeRegen] = GetPowerRegen();
                [
                    this.current.inactiveRegen[powerType],
                    this.current.activeRegen[powerType],
                ] = [inactiveRegen, activeRegen];
                this.ovale.needRefresh();
            } else if (powerType == "mana") {
                let [inactiveRegen, activeRegen] = GetManaRegen();
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
        let [powerId] = UnitPowerType("player");
        let powerType = this.POWER_TYPE[powerId];
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
            let spellPowerCost = spellPowerCosts && spellPowerCosts[1];
            if (spellPowerCost) {
                let cost = spellPowerCost.cost;
                let typeId = spellPowerCost.type;
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

    RequirePowerHandler = (
        spellId: number,
        atTime: number,
        requirement: string,
        tokens: Tokens,
        index: number,
        targetGUID: string | undefined
    ): [boolean, string, number] => {
        return this.getPowerRequirementAt(
            this.GetState(atTime),
            spellId,
            atTime,
            requirement,
            tokens,
            index,
            targetGUID
        );
    };

    DebugPower() {
        let array = {};
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
        extraPower?: number
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
    ApplySpellStartCast(
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) {
        this.profiler.StartProfiling("OvalePower_ApplySpellStartCast");
        if (isChanneled) {
            this.ApplyPowerCost(spellId, targetGUID, startCast, spellcast);
        }
        this.profiler.StopProfiling("OvalePower_ApplySpellStartCast");
    }
    ApplySpellAfterCast(
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) {
        this.profiler.StartProfiling("OvalePower_ApplySpellAfterCast");
        if (!isChanneled) {
            this.ApplyPowerCost(spellId, targetGUID, endCast, spellcast);
        }
        this.profiler.StopProfiling("OvalePower_ApplySpellAfterCast");
    }

    ApplyPowerCost(
        spellId: number,
        targetGUID: string,
        atTime: number,
        spellcast: SpellCast
    ) {
        this.profiler.StartProfiling("OvalePower_state_ApplyPowerCost");
        let si = this.ovaleData.spellInfo[spellId];
        {
            let [cost, powerType] = this.GetSpellCost(spellId);
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
                let power = this.next.power[powerType] || 0;
                if (cost) {
                    power = power - cost;
                }
                if (refund) {
                    power = power + refund;
                }
                let seconds = this.ovaleFuture.next.nextCast - atTime;
                if (seconds > 0) {
                    let powerRate =
                        this.getPowerRateAt(this.next, powerType, atTime) || 0;
                    power = power + powerRate * seconds;
                }
                let mini = powerInfo.mini || 0;
                if (mini && power < mini) {
                    power = mini;
                }
                let maxi = this.current.maxPower[powerType];
                if (maxi && power > maxi) {
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
    getPowerRateAt(state: PowerState, powerType: string, atTime: number) {
        if (this.combat.isInCombat(atTime)) {
            return state.activeRegen[powerType];
        } else {
            return state.inactiveRegen[powerType];
        }
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
        if (atTime) {
            let now = this.baseState.next.currentTime;
            let seconds = atTime - now;
            if (seconds > 0) {
                let powerRate =
                    this.getPowerRateAt(state, powerType, atTime) || 0;
                power = power + powerRate * seconds;
            }
        }
        return power;
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
        let si = this.ovaleData.spellInfo[spellId];
        if (si && si[powerType]) {
            let [cost, ratio] = this.ovaleData.GetSpellInfoPropertyNumber(
                spellId,
                atTime,
                powerType,
                targetGUID,
                true
            );
            if (ratio && ratio != 0) {
                let addRequirements =
                    si &&
                    si.require &&
                    si.require[`add_${powerType}_from_aura` as keyof SpellInfo];
                if (addRequirements) {
                    for (const [v, rArray] of pairs(addRequirements)) {
                        if (isLuaArray(rArray)) {
                            for (const [, requirement] of ipairs<any>(rArray)) {
                                let verified = this.requirement.CheckRequirements(
                                    spellId,
                                    atTime,
                                    requirement,
                                    1,
                                    targetGUID
                                );
                                if (verified) {
                                    let aura = this.ovaleAura.GetAura(
                                        "player",
                                        requirement[2],
                                        atTime,
                                        undefined,
                                        true
                                    );
                                    if (
                                        aura &&
                                        this.ovaleAura.IsActiveAura(
                                            aura,
                                            atTime
                                        )
                                    ) {
                                        cost =
                                            cost +
                                            (tonumber(v) || 0) * aura.stacks;
                                    }
                                }
                            }
                        }
                    }
                }

                let maxCostParam = `max_${powerType}`;
                let maxCost = <number>si[maxCostParam as keyof SpellInfo];
                if (maxCost) {
                    let power = this.getPowerAt(state, powerType, atTime);
                    if (power > maxCost || maximumCost) {
                        cost = maxCost;
                    } else if (power > cost) {
                        cost = power;
                    }
                }

                spellCost =
                    (cost > 0 && floor(cost * ratio)) || ceil(cost * ratio);

                let refund = si[`refund_${powerType}` as keyof SpellInfo] || 0;
                if (refund == "cost") {
                    spellRefund = spellCost;
                } else {
                    let refundRequirements =
                        si &&
                        si.require[`refund_${powerType}` as keyof SpellInfo];
                    if (refundRequirements) {
                        for (const [v, rArray] of pairs(refundRequirements)) {
                            if (isLuaArray(rArray)) {
                                for (const [, requirement] of ipairs<any>(
                                    rArray
                                )) {
                                    let verified = this.requirement.CheckRequirements(
                                        spellId,
                                        atTime,
                                        requirement,
                                        1,
                                        targetGUID
                                    );
                                    if (verified) {
                                        if (v == "cost") {
                                            spellRefund = spellCost;
                                        } else if (isNumber(v)) {
                                        }
                                        refund =
                                            <number>refund + (tonumber(v) || 0);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            let [cost] = this.GetSpellCost(spellId, powerType);
            if (cost) {
                spellCost = cost;
            }
        }
        this.profiler.StopProfiling("OvalePower_PowerCost");
        return [spellCost, spellRefund];
    }

    /**
     * @name RequirePowerHandler
     * @param spellId
     * @param atTime
     * @param requirement
     * @param index
     * @param targetGUID
     * @return [verified, requirement, index] <[boolean, string, number]>
     */
    private getPowerRequirementAt(
        state: PowerState,
        spellId: number,
        atTime: number,
        requirement: string,
        tokens: Tokens,
        index: number,
        targetGUID: string | undefined
    ): [boolean, string, number] {
        let verified = false;
        let baseCost = tokens[index];
        index = index + 1;
        if (baseCost) {
            if (baseCost > 0) {
                // Don't check power requirements for abilities that generate power
                let powerType = <PowerType>requirement;
                let [cost] = this.getPowerCostAt(
                    state,
                    spellId,
                    powerType,
                    atTime,
                    targetGUID
                );
                if (cost > 0) {
                    let power = this.getPowerAt(state, powerType, atTime);
                    if (power >= cost) {
                        verified = true;
                    }
                    this.tracer.Log("   Has power %f %s", power, powerType);
                } else {
                    verified = true;
                }
                if (cost > 0) {
                    let result = (verified && "passed") || "FAILED";
                    this.tracer.Log(
                        "    Require %f %s at time=%f: %s",
                        cost,
                        powerType,
                        atTime,
                        result
                    );
                }
            } else {
                verified = true;
            }
        } else {
            OneTimeMessage(
                "Warning: requirement '%s' power is missing a cost argument.",
                requirement
            );
            OneTimeMessage(tostring(index));
            if (isLuaArray(tokens)) {
                for (const [k, v] of pairs(tokens)) {
                    OneTimeMessage(`${k} = ${tostring(v)}`);
                }
            }
        }
        return [verified, requirement, index];
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
        extraPower?: number
    ) {
        let seconds = 0;
        powerType = powerType || POOLED_RESOURCE[this.ovalePaperDoll.class];
        if (powerType) {
            let [cost] = this.getPowerCostAt(
                state,
                spellId,
                powerType,
                atTime,
                targetGUID
            );
            if (cost > 0) {
                let power = this.getPowerAt(state, powerType, atTime);
                if (extraPower) {
                    cost = cost + extraPower;
                }
                if (power < cost) {
                    let powerRate =
                        this.getPowerRateAt(state, powerType, atTime) || 0;
                    if (powerRate > 0) {
                        seconds = (cost - power) / powerRate;
                    } else {
                        seconds = INFINITY;
                    }
                }
            }
        }
        return seconds;
    }
}
