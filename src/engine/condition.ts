import { next, LuaObj, LuaArray, ipairs, unpack, pack } from "@wowts/lua";
import { huge } from "@wowts/math";
import { BaseState } from "../states/BaseState";
import {
    PositionalParameters,
    AstNodeSnapshot,
    AstActionNode,
    AstFunctionNode,
    NamedParametersOf,
} from "./ast";
import { AuraType } from "./data";
import { isString, KeyCheck } from "../tools/tools";
import { insert } from "@wowts/table";
const INFINITY = huge;

export type ConditionResult = [
    /** If defined, the value is defined only after this time in seconds */
    start?: number,
    /** If defined, the value is defined only before this time in seconds */
    end?: number,
    /** The value */
    value?: number | string,
    /** If defined, the time at which the value is defined, otherwise, the value is a constant */
    origin?: number,
    /** If defined, the rate at which each second the value change, otherwise, the value is a constant */
    rate?: number
];
export type ConditionFunction = (
    positionalParams: PositionalParameters,
    namedParams: NamedParametersOf<AstFunctionNode>,
    atTime: number
) => ConditionResult;

export type ConditionAction = (
    positionalParams: PositionalParameters,
    namedParams: NamedParametersOf<AstActionNode>,
    atTime: number,
    result: AstNodeSnapshot
) => void;

interface NumberParameterInfo<Optional = boolean> {
    type: "number";
    name: string;
    optional: Optional;
    isSpell?: boolean;
    isItem?: boolean;
    defaultValue?: number;
}

interface StringParameterInfo<T extends string, Optional = boolean> {
    type: "string";
    name: string;
    optional: Optional;
    checkTokens?: KeyCheck<T>;
    defaultValue?: string;
    mapValues?: LuaObj<string>;
}

interface BooleanParameterInfo<Optional = boolean> {
    type: "boolean";
    name: string;
    optional: Optional;
    defaultValue?: boolean;
}

type ParameterInfos =
    | NumberParameterInfo
    | StringParameterInfo<string>
    | BooleanParameterInfo;

type DefinedParameterInfo<T, Optional = boolean> = T extends number
    ? NumberParameterInfo<Optional>
    : T extends string
    ? StringParameterInfo<T, Optional>
    : T extends boolean
    ? BooleanParameterInfo<Optional>
    : never;

export type ParameterInfo<T> = DefinedParameterInfo<T>;

// type ParameterInfo<T> = T extends (infer P | undefined)
//     ? DefinedParameterInfo<P, true>
//     : DefinedParameterInfo<T, false>;

// const test: ParameterInfo<string | undefined> = {
//     type: "string",
//     name: "",
//     optional: true,
// };
// const test3: ParameterInfo<string | undefined> = {
//     type: "string",
//     name: "",
//     optional: false,
// };
// const test2: ParameterInfo<string> = {
//     type: "string",
//     name: "",
//     optional: false
// };
// const test4: ParameterInfo<string> = {
//     type: "string",
//     name: "",
//     optional: true
// };

type ParametersInfo<T extends readonly unknown[]> = {
    [Index in keyof T]: ParameterInfo<T[Index]>;
};

interface ReturnInfo {
    type: "number" | "string" | "none";
}

export interface FunctionInfos {
    parameters: LuaArray<ParameterInfos>;
    namedParameters: LuaObj<number>;
    returnValue: ReturnInfo;
    replacements?: LuaArray<{ index: number; mapValues: LuaObj<string> }>;
    func: (atTime: number, ...args: unknown[]) => ConditionResult;
    // TODO should be better
    targetIndex?: number;
}

export function getFunctionSignature(name: string, infos: FunctionInfos) {
    let result = name + "(";
    for (const [k, v] of ipairs(infos.parameters)) {
        if (k > 1) result += ", ";
        result += `${v.name}: ${v.type}`;
    }
    return result + ")";
}

export class OvaleConditionClass {
    private conditions: LuaObj<ConditionFunction> = {};
    private actions: LuaObj<ConditionAction> = {};
    private spellBookConditions: LuaObj<boolean> = {
        spell: true,
    };
    private typedConditions: LuaObj<FunctionInfos> = {};

    constructor(private baseState: BaseState) {}

    /**
     * Register a new condition
     * @param name The condition name (must be lowercase)
     * @param isSpellBookCondition Is the first argument a spell id from the spell book or a spell list name
     * @param func The function to register
     */
    RegisterCondition(
        name: string,
        isSpellBookCondition: boolean,
        func: ConditionFunction
    ) {
        this.conditions[name] = func;
        if (isSpellBookCondition) {
            this.spellBookConditions[name] = true;
        }
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    register<P extends any[], R extends ConditionResult>(
        name: string,
        func: (atTime: number, ...args: P) => R,
        returnParameters: ReturnInfo,
        ...parameters: ParametersInfo<P>
    ) {
        const infos: FunctionInfos = {
            func: func as any,
            parameters: pack(...(parameters as ParameterInfos[])),
            namedParameters: {},
            returnValue: returnParameters,
        };
        for (const [k, v] of ipairs(infos.parameters)) {
            infos.namedParameters[v.name] = k;
            if (v.name === "target") {
                infos.targetIndex = k;
            }
            if (v.type === "string" && v.mapValues) {
                infos.replacements = infos.replacements || {};
                insert(infos.replacements, {
                    index: k,
                    mapValues: v.mapValues,
                });
            }
        }
        this.typedConditions[name] = infos;
    }

    registerAlias(name: string, alias: string) {
        this.typedConditions[alias] = this.typedConditions[name];
    }

    call(name: string, atTime: number, positionalParams: PositionalParameters) {
        const infos = this.typedConditions[name];
        if (infos.replacements) {
            for (const [, v] of ipairs(infos.replacements)) {
                const value = positionalParams[v.index];
                if (value) {
                    const replacement = v.mapValues[value as string];
                    if (replacement) positionalParams[v.index] = replacement;
                }
            }
        }
        if (
            infos.targetIndex &&
            (positionalParams[infos.targetIndex] === "target" ||
                positionalParams[infos.targetIndex] === "cycle")
        ) {
            positionalParams[infos.targetIndex] = this.baseState.defaultTarget;
        }
        return infos.func(atTime, ...unpack(positionalParams));
    }

    registerAction(name: string, func: ConditionAction) {
        this.actions[name] = func;
    }

    UnregisterCondition(name: string) {
        delete this.conditions[name];
    }

    getInfos(name: string): FunctionInfos | undefined {
        return this.typedConditions[name];
    }

    IsCondition(name: string) {
        return this.conditions[name] != undefined;
    }
    IsSpellBookCondition(name: string) {
        return this.spellBookConditions[name] != undefined;
    }
    EvaluateCondition(
        name: string,
        positionalParams: PositionalParameters,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) {
        return this.conditions[name](positionalParams, namedParams, atTime);
    }
    HasAny() {
        return next(this.conditions) !== undefined;
    }
}

export function ParseCondition(
    namedParams: NamedParametersOf<AstFunctionNode>,
    baseState: BaseState,
    defaultTarget?: string
): [target: string, filter: AuraType | undefined, mine: boolean] {
    let target =
        (isString(namedParams.target) && namedParams.target) ||
        defaultTarget ||
        "player";
    namedParams.target = namedParams.target || target;

    if (target === "cycle" || target === "target") {
        target = baseState.defaultTarget;
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
    }
    return [target, filter, mine];
}

export function ReturnValue(
    value: number,
    origin: number,
    rate: number
): ConditionResult {
    return [0, INFINITY, value, origin, rate];
}

export function ReturnValueBetween(
    start: number,
    ending: number,
    value: number,
    origin: number,
    rate: number
): ConditionResult {
    if (start >= ending) return [];
    return [start, ending, value, origin, rate];
}

export function ReturnConstant(
    value: number | string | undefined
): ConditionResult {
    return [0, INFINITY, value, 0, 0];
}

export function ReturnBoolean(value: boolean): ConditionResult {
    if (value) return [0, INFINITY];
    return [];
}
