import { L } from "./Localization";
import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale, MakeString } from "./Ovale";
import { OvaleAura } from "./Aura";
import { OvaleFuture } from "./Future";
import { OvaleData } from "./Data";
import { OvaleState, baseState, StateModule } from "./State";
import { paperDollState } from "./PaperDoll";
import { RegisterRequirement, UnregisterRequirement } from "./Requirement";
import { futureState } from "./FutureState";
import { lastSpell } from "./LastSpell";
import { DataState, dataState } from "./DataState";
import aceEvent from "@wowts/ace_event-3.0";
import { ceil, huge as INFINITY, floor } from "@wowts/math";
import { pairs, wipe, type, LuaObj, lualength, tostring } from "@wowts/lua";
import { concat } from "@wowts/table";
import { GetPowerRegen, GetSpellPowerCost, GetTime, UnitPower, UnitPowerMax, UnitPowerType, SPELL_POWER_ALTERNATE_POWER, SPELL_POWER_CHI, CHI_COST, SPELL_POWER_COMBO_POINTS, COMBO_POINTS_COST, SPELL_POWER_ENERGY, ENERGY_COST, SPELL_POWER_FOCUS, FOCUS_COST, SPELL_POWER_HOLY_POWER, HOLY_POWER_COST, SPELL_POWER_MANA, MANA_COST, SPELL_POWER_RAGE, RAGE_COST, SPELL_POWER_RUNIC_POWER, RUNIC_POWER_COST, SPELL_POWER_SOUL_SHARDS, SOUL_SHARDS_COST, SPELL_POWER_LUNAR_POWER, LUNAR_POWER_COST, SPELL_POWER_INSANITY, INSANITY_COST, SPELL_POWER_MAELSTROM, MAELSTROM_COST, SPELL_POWER_ARCANE_CHARGES, ARCANE_CHARGES_COST, SPELL_POWER_PAIN, PAIN_COST, SPELL_POWER_FURY, FURY_COST } from "@wowts/wow-mock";

let OvalePowerBase = OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvalePower", aceEvent)));
export let OvalePower:OvalePowerClass;

// let self_updateSpellcastInfo = {
// }
let self_SpellcastInfoPowerTypes = {
    1: "chi",
    2: "holy"
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
                    get: function (info) {
                        return powerState.DebugPower();
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
    mini: number;
    costString?: string;
    segments?: number;
}

interface DataModule {
    GetSpellInfoProperty(spellId, atTime, powerType, target): string|number;
}

interface PowerModule {
    GetPower(powerType, atTime): number;
}

function isString(s: any): s is string {
    return type(s) == "string";
}

class OvalePowerClass extends OvalePowerBase {
    powerType = undefined;
    powerRate:number = undefined;
    power = {}
    maxPower:LuaObj<number> = {}
    activeRegen = 0;
    inactiveRegen = 0;
    POWER_INFO:LuaObj<PowerInfo> = {
        alternate: {
            id: SPELL_POWER_ALTERNATE_POWER,
            token: "ALTERNATE_RESOURCE_TEXT",
            mini: 0
        },
        chi: {
            id: SPELL_POWER_CHI,
            token: "CHI",
            mini: 0,
            costString: CHI_COST
        },
        combopoints: {
            id: SPELL_POWER_COMBO_POINTS,
            token: "COMBO_POINTS",
            mini: 0,
            costString: COMBO_POINTS_COST
        },
        energy: {
            id: SPELL_POWER_ENERGY,
            token: "ENERGY",
            mini: 0,
            costString: ENERGY_COST
        },
        focus: {
            id: SPELL_POWER_FOCUS,
            token: "FOCUS",
            mini: 0,
            costString: FOCUS_COST
        },
        holy: {
            id: SPELL_POWER_HOLY_POWER,
            token: "HOLY_POWER",
            mini: 0,
            costString: HOLY_POWER_COST
        },
        mana: {
            id: SPELL_POWER_MANA,
            token: "MANA",
            mini: 0,
            costString: MANA_COST
        },
        rage: {
            id: SPELL_POWER_RAGE,
            token: "RAGE",
            mini: 0,
            costString: RAGE_COST
        },
        runicpower: {
            id: SPELL_POWER_RUNIC_POWER,
            token: "RUNIC_POWER",
            mini: 0,
            costString: RUNIC_POWER_COST
        },
        soulshards: {
            id: SPELL_POWER_SOUL_SHARDS,
            token: "SOUL_SHARDS",
            mini: 0,
            costString: SOUL_SHARDS_COST
        },
        astralpower: {
            id: SPELL_POWER_LUNAR_POWER,
            token: "LUNAR_POWER",
            mini: 0,
            costString: LUNAR_POWER_COST
        },
        insanity: {
            id: SPELL_POWER_INSANITY,
            token: "INSANITY",
            mini: 0,
            costString: INSANITY_COST
        },
        maelstrom: {
            id: SPELL_POWER_MAELSTROM,
            token: "MAELSTROM",
            mini: 0,
            costString: MAELSTROM_COST
        },
        arcanecharges: {
            id: SPELL_POWER_ARCANE_CHARGES,
            token: "ARCANE_CHARGES",
            mini: 0,
            costString: ARCANE_CHARGES_COST
        },
        pain: {
            id: SPELL_POWER_PAIN,
            token: "PAIN",
            mini: 0,
            costString: PAIN_COST
        },
        fury: {
            id: SPELL_POWER_FURY,
            token: "FURY",
            mini: 0,
            costString: FURY_COST
        }
    }

    PRIMARY_POWER = {
        energy: true,
        focus: true,
        mana: true
    }
    POWER_TYPE = {}

    POOLED_RESOURCE: LuaObj<string> = {
        ["DRUID"]: "energy",
        ["HUNTER"]: "focus",
        ["MONK"]: "energy",
        ["ROGUE"]: "energy"
    }
   
    constructor() {
        super();
        for (const [powerType, v] of pairs(this.POWER_INFO)) {
            if (v.id === undefined) {
                this.Print("Unknown resource %s", v.token);
            }
            this.POWER_TYPE[v.id] = powerType;
            this.POWER_TYPE[v.token] = powerType;
        }
        this.RegisterEvent("PLAYER_ENTERING_WORLD", "EventHandler");
        this.RegisterEvent("PLAYER_LEVEL_UP", "EventHandler");
        this.RegisterEvent("UNIT_DISPLAYPOWER");
        this.RegisterEvent("UNIT_LEVEL");
        this.RegisterEvent("UNIT_MAXPOWER");
        this.RegisterEvent("UNIT_POWER");
        this.RegisterEvent("UNIT_POWER_FREQUENT", "UNIT_POWER");
        this.RegisterEvent("UNIT_RANGEDDAMAGE");
        this.RegisterEvent("UNIT_SPELL_HASTE", "UNIT_RANGEDDAMAGE");
        this.RegisterMessage("Ovale_StanceChanged", "EventHandler");
        this.RegisterMessage("Ovale_TalentsChanged", "EventHandler");
        for (const [powerType] of pairs(this.POWER_INFO)) {
            RegisterRequirement(powerType, "RequirePowerHandler", this);
        }
        lastSpell.RegisterSpellcastInfo(this);
    }
    OnDisable() {
        lastSpell.UnregisterSpellcastInfo(this);
        for (const [powerType] of pairs(this.POWER_INFO)) {
            UnregisterRequirement(powerType);
        }
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("PLAYER_LEVEL_UP");
        this.UnregisterEvent("UNIT_DISPLAYPOWER");
        this.UnregisterEvent("UNIT_LEVEL");
        this.UnregisterEvent("UNIT_MAXPOWER");
        this.UnregisterEvent("UNIT_POWER");
        this.UnregisterEvent("UNIT_POWER_FREQUENT");
        this.UnregisterEvent("UNIT_RANGEDDAMAGE");
        this.UnregisterEvent("UNIT_SPELL_HASTE");
        this.UnregisterMessage("Ovale_StanceChanged");
        this.UnregisterMessage("Ovale_TalentsChanged");
    }
    EventHandler(event) {
        this.UpdatePowerType(event);
        this.UpdateMaxPower(event);
        this.UpdatePower(event);
        this.UpdatePowerRegen(event);
    }
    UNIT_DISPLAYPOWER(event, unitId) {
        if (unitId == "player") {
            this.UpdatePowerType(event);
            this.UpdatePowerRegen(event);
        }
    }
    UNIT_LEVEL(event, unitId) {
        if (unitId == "player") {
            this.EventHandler(event);
        }
    }
    UNIT_MAXPOWER(event, unitId, powerToken) {
        if (unitId == "player") {
            let powerType = this.POWER_TYPE[powerToken];
            if (powerType) {
                this.UpdateMaxPower(event, powerType);
            }
        }
    }
    UNIT_POWER(event, unitId, powerToken) {
        if (unitId == "player") {
            let powerType = this.POWER_TYPE[powerToken];
            if (powerType) {
                this.UpdatePower(event, powerType);
            }
        }
    }
    UNIT_RANGEDDAMAGE(event, unitId) {
        if (unitId == "player") {
            this.UpdatePowerRegen(event);
        }
    }
    UpdateMaxPower(event, powerType?) {
        this.StartProfiling("OvalePower_UpdateMaxPower");
        if (powerType) {
            let powerInfo = this.POWER_INFO[powerType];
            let maxPower = UnitPowerMax("player", powerInfo.id, powerInfo.segments);
            if (this.maxPower[powerType] != maxPower) {
                this.maxPower[powerType] = maxPower;
                Ovale.needRefresh();
            }
        } else {
            for (const [powerType, powerInfo] of pairs(this.POWER_INFO)) {
                let maxPower = UnitPowerMax("player", powerInfo.id, powerInfo.segments);
                if (this.maxPower[powerType] != maxPower) {
                    this.maxPower[powerType] = maxPower;
                    Ovale.needRefresh();
                }
            }
        }
        this.StopProfiling("OvalePower_UpdateMaxPower");
    }
    UpdatePower(event, powerType?) {
        this.StartProfiling("OvalePower_UpdatePower");
        if (powerType) {
            let powerInfo = this.POWER_INFO[powerType];
            let power = UnitPower("player", powerInfo.id, powerInfo.segments);
            if (this.power[powerType] != power) {
                this.power[powerType] = power;
                Ovale.needRefresh();
            }
            this.DebugTimestamp("%s: %d -> %d (%s).", event, this.power[powerType], power, powerType);
        } else {
            for (const [powerType, powerInfo] of pairs(this.POWER_INFO)) {
                let power = UnitPower("player", powerInfo.id, powerInfo.segments);
                if (this.power[powerType] != power) {
                    this.power[powerType] = power;
                    Ovale.needRefresh();
                }
                this.DebugTimestamp("%s: %d -> %d (%s).", event, this.power[powerType], power, powerType);
            }
        }
        Ovale.needRefresh();
        this.StopProfiling("OvalePower_UpdatePower");
    }
    UpdatePowerRegen(event) {
        this.StartProfiling("OvalePower_UpdatePowerRegen");
        let [inactiveRegen, activeRegen] = GetPowerRegen();
        if (this.inactiveRegen != inactiveRegen || this.activeRegen != activeRegen) {
            [this.inactiveRegen, this.activeRegen] = [inactiveRegen, activeRegen];
            Ovale.needRefresh();
        }
        this.StopProfiling("OvalePower_UpdatePowerRegen");
    }
    UpdatePowerType(event) {
        this.StartProfiling("OvalePower_UpdatePowerType");
        let [currentType, ] = UnitPowerType("player");
        let powerType = this.POWER_TYPE[currentType];
        if (this.powerType != powerType) {
            this.powerType = powerType;
            Ovale.needRefresh();
        }
        Ovale.needRefresh();
        this.StopProfiling("OvalePower_UpdatePowerType");
    }
    GetSpellCost(spellId, powerType?: string):[number, string] {
        this.StartProfiling("OvalePower_GetSpellCost");
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
        return undefined;
    }
    GetPower(powerType, atTime) {
        let power = (this.power && this.power[powerType]) || this[powerType] || 0;
        let powerRate = 0;
        if (this.powerType && this.powerType == powerType && this.activeRegen) {
            powerRate = this.activeRegen;
        } else if (this.powerRate && this.powerRate[powerType]) {
            powerRate = this.powerRate[powerType];
        }
        if (atTime) {
            let now = baseState.currentTime || GetTime();
            let seconds = atTime - now;
            if (seconds > 0) {
                power = power + powerRate * seconds;
            }
        }
        return power;
    }
    PowerCost(spellId, powerType, atTime, targetGUID, maximumCost?) {
        this.StartProfiling("OvalePower_PowerCost");
        let buffParam = `buff_${powerType}`;
        let spellCost = 0;
        let spellRefund = 0;
        let si = OvaleData.spellInfo[spellId];
        if (si && si[powerType]) {
            let cost = OvaleData.GetSpellInfoProperty(spellId, atTime, powerType, targetGUID);
            let costNumber: number;
            if (isString(cost)) {
                if (cost == "finisher") {
                    cost = this.GetPower(powerType, atTime);
                    let minCostParam = `min_${powerType}`;
                    let maxCostParam = `max_${powerType}`;
                    let minCost = si[minCostParam] || 1;
                    let maxCost = si[maxCostParam];
                    if (cost < minCost) {
                        costNumber = minCost;
                    }
                    if (maxCost && cost > maxCost) {
                        costNumber = maxCost;
                    }
                } else if (cost == "refill") {
                    costNumber = this.GetPower(powerType, atTime) - this.maxPower[powerType];
                }   
                costNumber = 0; 
            } else {
                let buffExtraParam = buffParam;
                let buffAmountParam = `${buffParam}_amount`;
                let buffExtra = si[buffExtraParam];
                if (buffExtra) {
                    let aura = OvaleAura.GetAura("player", buffExtra, undefined, true);
                    let isActiveAura = OvaleAura.IsActiveAura(aura, atTime);
                    if (isActiveAura) {
                        let buffAmount = 0;
                        if (type(buffAmountParam) == "number") {
                            buffAmount = si[buffAmountParam] || -1;
                        } else if (si[buffAmountParam] == "value3") {
                            buffAmount = aura.value3 || -1;
                        } else if (si[buffAmountParam] == "value2") {
                            buffAmount = aura.value2 || -1;
                        } else if (si[buffAmountParam] == "value1") {
                            buffAmount = aura.value1 || -1;
                        } else {
                            buffAmount = -1;
                        }
                        let siAura = OvaleData.spellInfo[buffExtra];
                        if (siAura && siAura.stacking == 1) {
                            buffAmount = buffAmount * aura.stacks;
                        }
                        cost = cost + buffAmount;
                        this.Log("Spell ID '%d' had %f %s added from aura ID '%d'.", spellId, buffAmount, powerType, aura.spellId);
                    }
                }
                costNumber = cost;
            }
            let extraPowerParam = `extra_${powerType}`;
            let extraPower = OvaleData.GetSpellInfoProperty(spellId, atTime, extraPowerParam, targetGUID);
            if (extraPower && !isString(extraPower)) {
                if (!maximumCost) {
                    let power = floor(this.GetPower(powerType, atTime));
                    power = power > cost && power - costNumber || 0;
                    if (extraPower >= power) {
                        extraPower = power;
                    }
                }
                costNumber = costNumber + extraPower;
            }
            spellCost = ceil(costNumber);
            let refundParam = `refund_${powerType}`;
            let refund = OvaleData.GetSpellInfoProperty(spellId, atTime, refundParam, targetGUID);
            if (isString(refund)) {
                if (refund == "cost") {
                    spellRefund = ceil(spellCost);
                }
            }
            else {
                spellRefund = ceil(refund || 0);
            }
        } else {
            let [cost] = this.GetSpellCost(spellId, powerType);
            if (cost) {
                spellCost = cost;
            }
        }
        this.StopProfiling("OvalePower_PowerCost");
        return [spellCost, spellRefund];
    }
    RequirePowerHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        let verified = false;
        let cost = tokens;
        if (index) {
            cost = tokens[index];
            index = index + 1;
        }
        if (cost) {
            let powerType = requirement;
            cost = this.PowerCost(spellId, powerType, atTime, targetGUID);
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
            Ovale.OneTimeMessage("Warning: requirement '%s' power is missing a cost argument.", requirement);
            Ovale.OneTimeMessage(tostring(index));
            if (type(tokens) == "table") {
                for (const [k,v] of pairs(tokens)) {
                    Ovale.OneTimeMessage(`${k} = ${tostring(v)}`);
                }
            }
        }
        return [verified, requirement, index];
    }
    DebugPower() {
        this.Print("Power type: %s", this.powerType);
        for (const [powerType, v] of pairs(this.power)) {
            this.Print("Power (%s): %d / %d", powerType, v, this.maxPower[powerType]);
        }
        this.Print("Active regen: %f", this.activeRegen);
        this.Print("Inactive regen: %f", this.inactiveRegen);
    }
    CopySpellcastInfo = (mod, spellcast, dest) => {
        for (const [, powerType] of pairs(self_SpellcastInfoPowerTypes)) {
            if (spellcast[powerType]) {
                dest[powerType] = spellcast[powerType];
            }
        }
    }
    SaveSpellcastInfo = (mod, spellcast, atTime, state: DataState) => {
        let spellId = spellcast.spellId;
        if (spellId) {
            let si = OvaleData.spellInfo[spellId];
            if (si) {
                let dataModule:DataModule = state || dataState;
                let powerModule: PowerModule;
                if (state) powerModule = powerState;
                else powerModule = this;
                for (const [, powerType] of pairs(self_SpellcastInfoPowerTypes)) {
                    if (si[powerType] == "finisher") {
                        let maxCostParam = `max_${powerType}`;
                        let maxCost = si[maxCostParam] || 1;
                        let cost = dataModule.GetSpellInfoProperty(spellId, atTime, powerType, spellcast.target);
                        if (isString(cost)) {
                            if (cost == "finisher") {
                                let power = powerModule.GetPower(powerType, atTime);
                                if (power > maxCost) {
                                    spellcast[powerType] = maxCost;
                                } else {
                                    spellcast[powerType] = power;
                                }
                            }
                        } else if (cost === 0) {
                            spellcast[powerType] =  maxCost;
                        }
                        spellcast[powerType] = cost;
                    }
                }
            }
        }
    }
}

let output = {}

class PowerState implements StateModule {
    powerRate = undefined;
    InitializeState() {
        for (const [powerType] of pairs(OvalePower.POWER_INFO)) {
            this[powerType] = 0;
        }
        this.powerRate = {
        }
    }
    ResetState() {
        OvalePower.StartProfiling("OvalePower_ResetState");
        for (const [powerType] of pairs(OvalePower.POWER_INFO)) {
            this[powerType] = OvalePower.power[powerType] || 0;
        }
        for (const [powerType] of pairs(OvalePower.POWER_INFO)) {
            this.powerRate[powerType] = 0;
        }
        if (OvaleFuture.inCombat) {
            this.powerRate[OvalePower.powerType] = OvalePower.activeRegen;
        } else {
            this.powerRate[OvalePower.powerType] = OvalePower.inactiveRegen;
        }
        OvalePower.StopProfiling("OvalePower_ResetState");
    }
    CleanState() {
        for (const [powerType] of pairs(OvalePower.POWER_INFO)) {
            this[powerType] = undefined;
        }
        for (const [k] of pairs(this.powerRate)) {
            this.powerRate[k] = undefined;
        }
    }
    ApplySpellStartCast(spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        OvalePower.StartProfiling("OvalePower_ApplySpellStartCast");
        if (isChanneled) {
            if (baseState.inCombat) {
                this.powerRate[OvalePower.powerType] = OvalePower.activeRegen;
            }
            this.ApplyPowerCost(spellId, targetGUID, startCast, spellcast);
        }
        OvalePower.StopProfiling("OvalePower_ApplySpellStartCast");
    }
    ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        OvalePower.StartProfiling("OvalePower_ApplySpellAfterCast");
        if (!isChanneled) {
            if (baseState.inCombat) {
                this.powerRate[OvalePower.powerType] = OvalePower.activeRegen;
            }
            this.ApplyPowerCost(spellId, targetGUID, endCast, spellcast);
        }
        OvalePower.StopProfiling("OvalePower_ApplySpellAfterCast");
    }

    ApplyPowerCost(spellId, targetGUID, atTime, spellcast) {
        OvalePower.StartProfiling("OvalePower_state_ApplyPowerCost");
        let si = OvaleData.spellInfo[spellId];
        {
            let [cost, powerType] = OvalePower.GetSpellCost(spellId);
            if (cost && powerType && this[powerType] && !(si && si[powerType])) {
                this[powerType] = this[powerType] - cost;
            }
        }
        if (si) {
            for (const [powerType, powerInfo] of pairs(OvalePower.POWER_INFO)) {
                let [cost, refund] = this.PowerCost(spellId, powerType, atTime, targetGUID);
                let power = this[powerType] || 0;
                if (cost) {
                    power = power - cost + refund;
                    let seconds = futureState.nextCast - atTime;
                    if (seconds > 0) {
                        let powerRate = this.powerRate[powerType] || 0;
                        power = power + powerRate * seconds;
                    }
                    let mini = powerInfo.mini || 0;
                    let maxi = OvalePower.maxPower[powerType];
                    if (mini && power < mini) {
                        power = mini;
                    }
                    if (maxi && power > maxi) {
                        power = maxi;
                    }
                    this[powerType] = power;
                }
            }
        }
        OvalePower.StopProfiling("OvalePower_state_ApplyPowerCost");
    }
    TimeToPower(spellId, atTime, targetGUID, powerType, extraPower?) {
        let seconds = 0;
        powerType = powerType || OvalePower.POOLED_RESOURCE[paperDollState.class];
        if (powerType) {
            let [cost] = this.PowerCost(spellId, powerType, atTime, targetGUID);
            let power = this.GetPower(powerType, atTime);
            let powerRate = this.powerRate[powerType] || 0;
            if (extraPower) {
                cost = cost + extraPower;
            }
            if (power < cost) {
                if (powerRate > 0) {
                    seconds = (cost - power) / powerRate;
                } else {
                    seconds = INFINITY;
                }
            }
        }
        return seconds;
    }
    GetPower(powerType, atTime) {
        return OvalePower.GetPower(powerType, atTime);
    }
    PowerCost(spellId, powerType, atTime, targetGUID, maximumCost?) {
        return OvalePower.PowerCost(spellId, powerType, atTime, targetGUID, maximumCost);
    }

    RequirePowerHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        return OvalePower.RequirePowerHandler(spellId, atTime, requirement, tokens, index, targetGUID);
    }
    DebugPower() {
        wipe(output);
        for (const [powerType] of pairs(OvalePower.POWER_INFO)) {
            output[lualength(output) + 1] = MakeString("%s = %d", powerType, this[powerType]);
        }
        return concat(output, "\n");
    }
}

export const powerState = new PowerState();
OvaleState.RegisterState(powerState);

OvalePower = new OvalePowerClass();