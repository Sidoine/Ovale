import { Ovale } from "./Ovale";
import { OvaleDebug } from "./Debug";
import { next, LuaObj } from "@wowts/lua";
import { huge } from "@wowts/math";
import { baseState } from "./BaseState";
import { PositionalParameters, NamedParameters } from "./AST";
let OvaleConditionBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleCondition"));
export let OvaleCondition: OvaleConditionClass;
let INFINITY = huge;
let self_condition: LuaObj<ConditionFunction> = {
}
let self_spellBookCondition: LuaObj<boolean> = {};
self_spellBookCondition["spell"] = true;

export type ConditionResult = number[];
type BaseState = {};
export type ConditionFunction = (positionalParams: PositionalParameters, namedParams: NamedParameters, state: BaseState, atTime: number) => ConditionResult;

export type ComparatorId = "atLeast" | "atMost" | "equal" | "less" | "more";

const COMPARATOR: LuaObj<boolean> = {
    atLeast: true,
    atMost: true,
    equal: true,
    less: true,
    more: true
}

export function isComparator(token: string): token is ComparatorId {
    return COMPARATOR[token] !== undefined;
}

class OvaleConditionClass extends OvaleConditionBase {

    RegisterCondition(name: string, isSpellBookCondition: boolean, func: ConditionFunction) { //, arg?: LuaObj<ConditionFunction>) {
        // if (arg) {
        //     if (isString(func)) {
        //         func = arg[func];
        //     }
        //     self_condition[name] = function (...__args) {
        //         func(arg, ...__args);
        //     }
        // } else {
            self_condition[name] = func;
        // }
        if (isSpellBookCondition) {
            self_spellBookCondition[name] = true;
        }
    }
    UnregisterCondition(name: string) {
        self_condition[name] = undefined;
    }
    IsCondition(name: string) {
        return (self_condition[name] != undefined);
    }
    IsSpellBookCondition(name: string) {
        return (self_spellBookCondition[name] != undefined);
    }
    EvaluateCondition(name: string, positionalParams: PositionalParameters, namedParams: NamedParameters, state: BaseState, atTime: number) {
        return self_condition[name](positionalParams, namedParams, state, atTime);
    }
    HasAny(){
        return next(self_condition) !== undefined;
    }
}

OvaleCondition = new OvaleConditionClass();

export function ParseCondition(positionalParams: PositionalParameters, namedParams: NamedParameters, state: BaseState, defaultTarget?: string):[string, "HARMFUL" | "HELPFUL", boolean] {
    let target = namedParams.target || defaultTarget || "player";
    namedParams.target = namedParams.target || target;
    if (target == "target") {
        target = baseState.next.defaultTarget;
    }
    let filter: "HARMFUL" | "HELPFUL";
    if (namedParams.filter) {
        if (namedParams.filter == "debuff") {
            filter = "HARMFUL";
        } else if (namedParams.filter == "buff") {
            filter = "HELPFUL";
        }
    }
    let mine = true;
    if (namedParams.any && namedParams.any == 1) {
        mine = false;
    } else {
        if (!namedParams.any && namedParams.mine && namedParams.mine != 1) {
            mine = false;
        }
    }
    return [target, filter, mine];
}

export function TestBoolean(a: boolean, yesno: "yes" | "no"): ConditionResult {
    if (!yesno || yesno == "yes") {
        if (a) {
            return [0, INFINITY];
        }
    } else {
        if (!a) {
            return [0, INFINITY];
        }
    }
    return undefined;
}
export function TestValue(start: number, ending: number, value: number, origin: number, rate: number, comparator: string, limit: number): ConditionResult {
    if (!value || !origin || !rate) {
        return undefined;
    }
    start = start || 0;
    ending = ending || INFINITY;
    if (!comparator) {
        if (start < ending) {
            return [start, ending, value, origin, rate];
        } else {
            return [0, INFINITY, 0, 0, 0];
        }
    } else if (!isComparator(comparator)) {
        OvaleCondition.Error("unknown comparator %s", comparator);
    } else if (!limit) {
        OvaleCondition.Error("comparator %s missing limit", comparator);
    } else if (rate == 0) {
        if ((comparator == "less" && value < limit) || (comparator == "atMost" && value <= limit) || (comparator == "equal" && value == limit) || (comparator == "atLeast" && value >= limit) || (comparator == "more" && value > limit)) {
            return [start, ending];
        }
    } else if ((comparator == "less" && rate > 0) || (comparator == "atMost" && rate > 0) || (comparator == "atLeast" && rate < 0) || (comparator == "more" && rate < 0)) {
        let t = (limit - value) / rate + origin;
        ending = (ending < t) && ending || t;
        return [start, ending];
    } else if ((comparator == "less" && rate < 0) || (comparator == "atMost" && rate < 0) || (comparator == "atLeast" && rate > 0) || (comparator == "more" && rate > 0)) {
        let t = (limit - value) / rate + origin;
        start = (start > t) && start || t;
        return [start, INFINITY];
    }
    return undefined;
}

export function Compare(value: number, comparator: string, limit: number) {
    return TestValue(0, INFINITY, value, 0, 0, comparator, limit);
}
