import { next, LuaObj } from "@wowts/lua";
import { huge } from "@wowts/math";
import { BaseState } from "./BaseState";
import { PositionalParameters, NamedParameters } from "./AST";
import { AuraType } from "./Data";
let INFINITY = huge;

export type ConditionResult = [number?, number?, number?, number?, number?];
export type ConditionFunction = (positionalParams: PositionalParameters, namedParams: NamedParameters, atTime: number) => ConditionResult;

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

export class OvaleConditionClass {
    private conditions: LuaObj<ConditionFunction> = {}
    private spellBookConditions: LuaObj<boolean> = {
        spell: true
    };
    
    constructor(private baseState: BaseState) {        
    }

    /**
     * Register a new condition
     * @param name The condition name (must be lowercase)
     * @param isSpellBookCondition Is the first argument a spell id from the spell book or a spell list name 
     * @param func The function to register
     */
    RegisterCondition(name: string, isSpellBookCondition: boolean, func: ConditionFunction) {
        this.conditions[name] = func;
        if (isSpellBookCondition) {
            this.spellBookConditions[name] = true;
        }
    }
    UnregisterCondition(name: string) {
        delete this.conditions[name];
    }
    IsCondition(name: string) {
        return (this.conditions[name] != undefined);
    }
    IsSpellBookCondition(name: string) {
        return (this.spellBookConditions[name] != undefined);
    }
    EvaluateCondition(name: string, positionalParams: PositionalParameters, namedParams: NamedParameters, atTime: number) {
        return this.conditions[name](positionalParams, namedParams, atTime);
    }
    HasAny(){
        return next(this.conditions) !== undefined;
    }

    
    ParseCondition(positionalParams: PositionalParameters, namedParams: NamedParameters, defaultTarget?: string):[string, AuraType | undefined, boolean] {
        let target = namedParams.target || defaultTarget || "player";
        namedParams.target = namedParams.target || target;

        if (target === "cycle" || target === "target") {
            target = this.baseState.next.defaultTarget;
        }
        let filter: AuraType | undefined;
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
    return [];
}

export function ReturnValue(value: number, origin: number, rate: number): ConditionResult {
    return [0, INFINITY, value, origin, rate];
}

export function TestValue(start: number, ending: number, value: number | undefined, origin: number | undefined, rate: number | undefined, comparator: string | undefined, limit: number | undefined): ConditionResult {
    if (value === undefined || origin === undefined || rate === undefined) {
        return [];
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
        return [];
    } else if (!limit) {
        return [];
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
    return [];
}

export function Compare(value: number, comparator: string | undefined, limit: number |undefined): ConditionResult {
    return TestValue(0, INFINITY, value, 0, 0, comparator, limit);
}
