import { L } from "./Localization";
import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleAura } from "./Aura";
import { OvaleFuture } from "./Future";
import { OvaleData } from "./Data";
import { OvaleState } from "./State";
import { RegisterRequirement, UnregisterRequirement, CheckRequirements, Tokens } from "./Requirement";
import { SpellCast } from "./LastSpell";
import aceEvent from "@wowts/ace_event-3.0";
import { ceil, huge as INFINITY, floor } from "@wowts/math";
import { pairs, LuaObj, tostring, tonumber } from "@wowts/lua";
import { lower } from "@wowts/string";
import { concat, insert } from "@wowts/table";
import { GetPowerRegen, GetManaRegen, GetSpellPowerCost, UnitPower, UnitPowerMax, UnitPowerType, Enum, MAX_COMBO_POINTS } from "@wowts/wow-mock";
import { OvalePaperDoll } from "./PaperDoll";
import { baseState } from "./BaseState";
import { isNumber, isLuaArray } from "./tools";

let strlower = lower;

let self_SpellcastInfoPowerTypes = {
    1: "chi",
    2: "holypower"
}
// let self_button = undefined;
{
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
                    get: function (info: any) {
                        return OvalePower.DebugPower();
                    }
                }
            }
        }
    }
    for (const [k, v] of pairs(debugOptions)) {
        OvaleDebug.options.args[k] = v;
    }
}

interface PowerInfo {
    id: number;
    token: string;
    mini?: number;
    maxCost?: number;
    segments?: number;
}

class PowerModule {
    powerType: string = undefined;
    activeRegen: LuaObj<number> = {};
    inactiveRegen: LuaObj<number> = {};
    maxPower: LuaObj<number> = {};
    power: LuaObj<number> = {};
    /**
     * Power regeneration rate for the given powerType.
     * @param powerType
     */
    GetPowerRate(powerType: string) {
        if (baseState.next.inCombat) {
            return this.activeRegen[powerType]
        } else {
            return this.inactiveRegen[powerType]
        }
    }
    /**
     * Power atTime for the given powerType.
     * @param powerType 
     * @param atTime 
     */
    GetPower(powerType: string, atTime: number): number {
        let power = this.power[powerType] || 0;
        if (atTime) {
            let now = baseState.next.currentTime;
            let seconds = atTime - now;
            if (seconds > 0) {
                let powerRate = this.GetPowerRate(powerType) || 0;
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
    PowerCost(spellId: number, powerType: string, atTime:number, targetGUID:string, maximumCost?:boolean): [number, number] {
        this.StartProfiling("OvalePower_PowerCost");
        let spellCost = 0;
        let spellRefund = 0;
        let si = OvaleData.spellInfo[spellId];
        if (si && si[powerType]) {
            let [cost, ratio] = OvaleData.GetSpellInfoPropertyNumber(spellId, atTime, powerType, targetGUID, true);
            if (ratio && ratio != 0) {
                let maxCostParam = `max_${powerType}`;
                let maxCost = <number>si[maxCostParam];
                if (maxCost) {
                    let power = this.GetPower(powerType, atTime);
                    if (power > (maxCost || maximumCost)) {
                        cost = maxCost;
                    } else if (power > cost) {
                        cost = power;
                    }
                } else {
                    let addRequirements = si && si.require[`add_${powerType}_from_aura`];
                    if (addRequirements) {
                        for (const [v, requirement] of pairs(addRequirements)) {
                            let verified = CheckRequirements(spellId, atTime, requirement, 1, targetGUID);
                            if (verified) {
                                let aura = <any>OvaleAura.GetAura("player", requirement[2], atTime, undefined, true);
                                if (aura[v]) {
                                    cost = cost + aura[v];
                                }
                            }
                        }
                    }
                }
                spellCost = (cost > 0 && floor(cost * ratio)) || ceil(cost * ratio);

                let refund = si[`refund_${powerType}`] || 0;
                if (refund == "cost") {
                    spellRefund = spellCost;
                } else {
                    let refundRequirements = si && si.require[`refund_${powerType}`];
                    if (refundRequirements) {
                        for (const [v, requirement] of pairs(refundRequirements)) {
                            let verified = CheckRequirements(spellId, atTime, requirement, 1, targetGUID);
                            if (verified) {
                                if (v == "cost") {
                                    spellRefund = spellCost
                                } else if (isNumber(v)) {

                                }
                                refund = <number>refund + (tonumber(v) || 0);
                                break;
                            }
                        }
                    }
                }
            }
        }
        else {
            let [cost] = OvalePower.GetSpellCost(spellId, powerType);
            if (cost) {
                spellCost = cost;
            }
        }
        this.StopProfiling("OvalePower_PowerCost");
        return [spellCost, spellRefund];
    }
    StartProfiling(name: string) {
        OvalePower.StartProfiling(name);
    }
    StopProfiling(name: string) {
        OvalePower.StopProfiling(name);
    }
    Log(...__args: any[]): void {
        OvalePower.Log(...__args);
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
    RequirePowerHandler = (spellId: number, atTime: number, requirement: string, tokens: Tokens, index: number, targetGUID: string): [boolean, string, number] => {
        let verified = false;
        let baseCost = tokens[index];
        index = index + 1;
        if (baseCost) {
            if (baseCost > 0) { // Don't check power requirements for abilities that generate power
                let powerType = requirement;
                let [cost] = this.PowerCost(spellId, powerType, atTime, targetGUID);
                if (cost > 0) {
                    let power = this.GetPower(powerType, atTime);
                    if (power >= cost) {
                        verified = true;
                    }
                    this.Log("   Has power %f %s", power, powerType);
                } else {
                    verified = true;
                }
                if (cost > 0) {
                    let result = verified && "passed" || "FAILED";
                    this.Log("    Require %f %s at time=%f: %s", cost, powerType, atTime, result);
                }
            } else {
                verified = true;
            }
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' power is missing a cost argument.", requirement);
            Ovale.OneTimeMessage(tostring(index));
            if (isLuaArray(tokens)) {
                for (const [k, v] of pairs(tokens)) {
                    Ovale.OneTimeMessage(`${k} = ${tostring(v)}`);
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
    TimeToPower(spellId:number, atTime:number, targetGUID:string, powerType:string, extraPower?:number) {
        let seconds = 0;
        powerType = powerType || OvalePower.POOLED_RESOURCE[OvalePaperDoll.class];
        if (powerType) {
            let [cost] = this.PowerCost(spellId, powerType, atTime, targetGUID);
            if (cost > 0) {
                let power = this.GetPower(powerType, atTime);
                if (extraPower) {
                    cost = cost + extraPower;
                }
                if (power < cost) {
                    let powerRate = this.GetPowerRate(powerType) || 0;
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

let OvalePowerBase = OvaleState.RegisterHasState(OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvalePower", aceEvent))), PowerModule);
export let OvalePower: OvalePowerClass;

export type PowerType = "mana" | "rage" | "focus" | "energy" |
    "combopoints" | "runicpower" | "soulshards" |
    "lunarpower" | "holypower" | "alternate" | "maelstrom" |
    "chi" | "insanity" | "arcanecharges" | "pain" | "fury";

class OvalePowerClass extends OvalePowerBase {
    POWER_INFO: LuaObj<PowerInfo> = {}
    POWER_TYPE: LuaObj<string> = {}

    POOLED_RESOURCE: LuaObj<PowerType> = {
        ["DRUID"]: "energy",
        ["HUNTER"]: "focus",
        ["MONK"]: "energy",
        ["ROGUE"]: "energy"
    }

    PRIMARY_POWER: LuaObj<boolean> = {
        energy: true,
        focus: true,
        mana: true
    }

    OnInitialize() {
        this.RegisterEvent("PLAYER_ENTERING_WORLD", "EventHandler");
        this.RegisterEvent("PLAYER_LEVEL_UP", "EventHandler");
        this.RegisterEvent("UNIT_DISPLAYPOWER");
        this.RegisterEvent("UNIT_LEVEL");
        this.RegisterEvent("UNIT_MAXPOWER");
        this.RegisterEvent("UNIT_POWER_UPDATE");
        this.RegisterEvent("UNIT_POWER_FREQUENT", "UNIT_POWER_UPDATE");
        this.RegisterEvent("UNIT_RANGEDDAMAGE");
        this.RegisterEvent("UNIT_SPELL_HASTE", "UNIT_RANGEDDAMAGE");
        this.RegisterMessage("Ovale_StanceChanged", "EventHandler");
        this.RegisterMessage("Ovale_TalentsChanged", "EventHandler");
        for (const [powerType] of pairs(this.POWER_INFO)) {
            RegisterRequirement(powerType, this.RequirePowerHandler);
        }
        this.initializePower();
    }

    initializePower() {
        let possiblePowerTypes: LuaObj<LuaObj<string>> = {
            DEATHKNIGHT:{
                runicpower: "RUNIC_POWER",
            },
            DEMONHUNTER:{
                pain: "PAIN",
                fury: "FURY"
            },
            DRUID:{
                mana: "MANA",
                rage: "RAGE",
                energy: "ENERGY",
                combopoints: "COMBO_POINTS",
                lunarpower: "LUNAR_POWER",
            },
            HUNTER:{
                focus: "FOCUS",
            },
            MAGE:{
                mana: "MANA",
                arcanecharges: "ARCANE_CHARGES",
            },
            MONK:{
                mana: "MANA",
                energy: "ENERGY",
                chi: "CHI",
            },
            PALADIN:{
                mana: "MANA",
            holypower: "HOLY_POWER",
            },
            PRIEST:{
                mana: "MANA",
                insanity: "INSANITY",
            },
            ROGUE:{
                energy: "ENERGY",
                combopoints: "COMBO_POINTS",
            },
            SHAMAN:{
                mana: "MANA",
            maelstrom: "MAELSTROM",
            },
            WARLOCK:{
                mana: "MANA",
                soulshards: "SOUL_SHARDS",
            },
            WARRIOR:{
                rage: "RAGE",
            },
        }

        for (const [powerType, powerId] of pairs(Enum.PowerType)) {
            let powerTypeLower = strlower(powerType);
            let powerToken = possiblePowerTypes[Ovale.playerClass][powerTypeLower];
            if (powerToken) {
                this.POWER_TYPE[powerId] = powerTypeLower;
                this.POWER_TYPE[powerToken] = powerTypeLower;
                this.POWER_INFO[powerTypeLower] = {
                    id: powerId,
                    token: powerToken,
                    mini: 0,
                    maxCost: (powerTypeLower == "combopoints" && MAX_COMBO_POINTS) || 0 // Not currently used.
                }
            }
        }
    }
    OnDisable() {
        for (const [powerType] of pairs(this.POWER_INFO)) {
            UnregisterRequirement(powerType);
        }
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("PLAYER_LEVEL_UP");
        this.UnregisterEvent("UNIT_DISPLAYPOWER");
        this.UnregisterEvent("UNIT_LEVEL");
        this.UnregisterEvent("UNIT_MAXPOWER");
        this.UnregisterEvent("UNIT_POWER_UPDATE");
        this.UnregisterEvent("UNIT_POWER_FREQUENT");
        this.UnregisterEvent("UNIT_RANGEDDAMAGE");
        this.UnregisterEvent("UNIT_SPELL_HASTE");
        this.UnregisterMessage("Ovale_StanceChanged");
        this.UnregisterMessage("Ovale_TalentsChanged");
    }
    EventHandler(event: string) {
        this.UpdatePowerType(event);
        this.UpdateMaxPower(event);
        this.UpdatePower(event);
        this.UpdatePowerRegen(event);
    }
    UNIT_DISPLAYPOWER(event: string, unitId: string) {
        if (unitId == "player") {
            this.UpdatePowerType(event);
            this.UpdatePowerRegen(event);
        }
    }
    UNIT_LEVEL(event: string, unitId: string) {
        if (unitId == "player") {
            this.EventHandler(event);
        }
    }
    UNIT_MAXPOWER(event: string, unitId: string, powerToken: string) {
        if (unitId == "player") {
            let powerType = this.POWER_TYPE[powerToken];
            if (powerType) {
                this.UpdateMaxPower(event, powerType);
            }
        }
    }
    UNIT_POWER_UPDATE(event: string, unitId: string, powerToken: string) {
        if (unitId == "player") {
            let powerType = this.POWER_TYPE[powerToken];
            if (powerType) {
                this.UpdatePower(event, powerType);
            }
        }
    }
    UNIT_RANGEDDAMAGE(event: string, unitId: string) {
        if (unitId == "player") {
            this.UpdatePowerRegen(event);
        }
    }
    UpdateMaxPower(event: string, powerType?: string) {
        this.StartProfiling("OvalePower_UpdateMaxPower");
        if (powerType) {
            let powerInfo = this.POWER_INFO[powerType];
            let maxPower = UnitPowerMax("player", powerInfo.id, powerInfo.segments);
            if (this.current.maxPower[powerType] != maxPower) {
                this.current.maxPower[powerType] = maxPower;
                Ovale.needRefresh();
            }
        } else {
            for (const [powerType, powerInfo] of pairs(this.POWER_INFO)) {
                let maxPower = UnitPowerMax("player", powerInfo.id, powerInfo.segments);
                if (this.current.maxPower[powerType] != maxPower) {
                    this.current.maxPower[powerType] = maxPower;
                    Ovale.needRefresh();
                }
            }
        }
        this.StopProfiling("OvalePower_UpdateMaxPower");
    }
    UpdatePower(event: string, powerType?: string) {
        this.StartProfiling("OvalePower_UpdatePower");
        if (powerType) {
            let powerInfo = this.POWER_INFO[powerType];
            let power = UnitPower("player", powerInfo.id, powerInfo.segments);
            this.DebugTimestamp("%s: %d -> %d (%s).", event, this.current.power[powerType], power, powerType);
            if (this.current.power[powerType] != power) {
                this.current.power[powerType] = power;
            }
        } else {
            for (const [powerType, powerInfo] of pairs(this.POWER_INFO)) {
                let power = UnitPower("player", powerInfo.id, powerInfo.segments);
                this.DebugTimestamp("%s: %d -> %d (%s).", event, this.current.power[powerType], power, powerType);
                if (this.current.power[powerType] != power) {
                    this.current.power[powerType] = power;
                }
            }
        }
        if (event == "UNIT_POWER_UPDATE") {
            Ovale.needRefresh();
        }
        this.StopProfiling("OvalePower_UpdatePower");
    }
    UpdatePowerRegen(event: string) {
        this.StartProfiling("OvalePower_UpdatePowerRegen");
        for (const [powerType,] of pairs(this.POWER_INFO)) {
            let currentType = this.current.powerType
            if (powerType == currentType) {
                let [inactiveRegen, activeRegen] = GetPowerRegen();
                [this.current.inactiveRegen[powerType], this.current.activeRegen[powerType]] = [inactiveRegen, activeRegen];
                Ovale.needRefresh();
            } else if (powerType == "mana") {
                let [inactiveRegen, activeRegen] = GetManaRegen();
                [this.current.inactiveRegen[powerType], this.current.activeRegen[powerType]] = [inactiveRegen, activeRegen];
                Ovale.needRefresh();
            } else if (this.current.activeRegen[powerType] == undefined) {
                let [inactiveRegen, activeRegen] = [0, 0];
                if (powerType == "energy") {
                    [inactiveRegen, activeRegen] = [10, 10];
                }
                [this.current.inactiveRegen[powerType], this.current.activeRegen[powerType]] = [inactiveRegen, activeRegen]
                Ovale.needRefresh();
            }
        }
        this.StopProfiling("OvalePower_UpdatePowerRegen");
    }
    UpdatePowerType(event: string) {
        this.StartProfiling("OvalePower_UpdatePowerType");
        let [powerId,] = UnitPowerType("player");
        let powerType = this.POWER_TYPE[powerId];
        if (this.current.powerType != powerType) {
            this.current.powerType = powerType;
            Ovale.needRefresh();
        }
        this.StopProfiling("OvalePower_UpdatePowerType");
    }
    GetSpellCost(spellId: number, powerType?: string): [number, string] {
        let spellPowerCost = GetSpellPowerCost(spellId)[1];
        if (spellPowerCost) {
            let cost = spellPowerCost.cost;
            let typeId = spellPowerCost.type;
            for (const [pt, p] of pairs(this.POWER_INFO)) {
                if (p.id == typeId && (powerType == undefined || pt == powerType)) {
                    return [cost, pt];
                }
            }
        }
        return [undefined, undefined];
    }

    RequirePowerHandler = (spellId: number, atTime: number, requirement: string, tokens: Tokens, index: number, targetGUID: string): [boolean, string, number] => {
        return this.GetState(atTime).RequirePowerHandler(spellId, atTime, requirement, tokens, index, targetGUID);
    }

    DebugPower() {
        let array = {};
        insert(array, `Current Power Type: ${this.current.powerType}`);
        for (const [powerType, v] of pairs(this.current.power)) {
            insert(array, `\nPower Type: ${powerType}`);
            insert(array, `Power: ${v} / ${this.current.maxPower[powerType]}`);
            insert(array, `Active Regen: / ${this.current.activeRegen[powerType]}`);
            insert(array, `Inactive Regen: / ${this.current.inactiveRegen[powerType]}`);
        }
        return concat(array, '\n');
    }
    CopySpellcastInfo = (mod: this, spellcast: SpellCast, dest: SpellCast) => {
        for (const [, powerType] of pairs(self_SpellcastInfoPowerTypes)) {
            if (spellcast[powerType]) {
                dest[powerType] = spellcast[powerType];
            }
        }
    }

    TimeToPower(spellId: number, atTime: number, targetGUID: string, powerType: string, extraPower?: number) {
        return this.GetState(atTime).TimeToPower(spellId, atTime, targetGUID, powerType, extraPower);
    }

    InitializeState() {
        for (const [powerType] of pairs(OvalePower.POWER_INFO)) {
            this.next.power[powerType] = 0;
            [this.next.inactiveRegen[powerType], this.next.activeRegen[powerType]] = [0, 0];
        }
    }
    ResetState() {
        OvalePower.StartProfiling("OvalePower_ResetState");
        for (const [powerType] of pairs(OvalePower.POWER_INFO)) {
            this.next.power[powerType] = this.current.power[powerType] || 0;
            this.next.maxPower[powerType] = this.current.maxPower[powerType] || 0;
            this.next.activeRegen[powerType] = this.current.activeRegen[powerType] || 0;
            this.next.inactiveRegen[powerType] = this.current.inactiveRegen[powerType] || 0;
        }
        OvalePower.StopProfiling("OvalePower_ResetState");
    }
    CleanState() {
        for (const [powerType] of pairs(OvalePower.POWER_INFO)) {
            this.next.power[powerType] = undefined;
        }
    }
    ApplySpellStartCast(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        OvalePower.StartProfiling("OvalePower_ApplySpellStartCast");
        if (isChanneled) {
            this.ApplyPowerCost(spellId, targetGUID, startCast, spellcast);
        }
        OvalePower.StopProfiling("OvalePower_ApplySpellStartCast");
    }
    ApplySpellAfterCast(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        OvalePower.StartProfiling("OvalePower_ApplySpellAfterCast");
        if (!isChanneled) {
            this.ApplyPowerCost(spellId, targetGUID, endCast, spellcast);
        }
        OvalePower.StopProfiling("OvalePower_ApplySpellAfterCast");
    }

    ApplyPowerCost(spellId: number, targetGUID: string, atTime:number , spellcast: SpellCast) {
        OvalePower.StartProfiling("OvalePower_state_ApplyPowerCost");
        let si = OvaleData.spellInfo[spellId];
        {
            let [cost, powerType] = OvalePower.GetSpellCost(spellId);
            if (cost && powerType && this.next.power[powerType] && !(si && si[powerType])) {
                this.next.power[powerType] = this.next.power[powerType] - cost;
            }
        }
        if (si) {
            for (const [powerType, powerInfo] of pairs(OvalePower.POWER_INFO)) {
                let [cost, refund] = this.next.PowerCost(spellId, powerType, atTime, targetGUID);
                let power = this.next.power[powerType] || 0;
                if (cost) {
                    power = power - cost
                }
                if (refund) {
                    power = power + refund;
                }
                let seconds = OvaleFuture.next.nextCast - atTime;
                if (seconds > 0) {
                    let powerRate = this.next.GetPowerRate(powerType) || 0;
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
        OvalePower.StopProfiling("OvalePower_state_ApplyPowerCost");
    }

    PowerCost(spellId: number, powerType: string, atTime: number, targetGUID: string, maximumCost?: boolean) {
        return this.GetState(atTime).PowerCost(spellId, powerType, atTime, targetGUID, maximumCost);
    }
}

OvalePower = new OvalePowerClass();
OvaleState.RegisterState(OvalePower);
