import { OvaleGUID } from "./GUID";
import { Ovale } from "./Ovale";
import { LuaObj, LuaArray } from "@wowts/lua";
import { baseState } from "./BaseState";
import { isLuaArray } from "./tools";

export type Tokens = LuaArray<string | number>;
export type RequirementMethod = (spellId: number, atTime: number, name: string, tokens: Tokens, index: number, targetGUID: string) => [boolean, string, number];

export const nowRequirements:LuaObj<RequirementMethod> = {}
export function RegisterRequirement(name: string, nowMethod: RequirementMethod) {
    nowRequirements[name] = nowMethod;
}

export function UnregisterRequirement(name: string) {
    nowRequirements[name] = undefined;
}

export function getNextToken(tokens: Tokens, index: number) : [string | number, number] {
    if (isLuaArray(tokens)) {
        const result = tokens[index];
        return [result, index + 1];
    }
    return [tokens, index];
}

export function CheckRequirements(spellId: number, atTime: number, tokens: Tokens, index: number, targetGUID: string):[boolean, string, number] {
    let requirements = nowRequirements;

    targetGUID = targetGUID || OvaleGUID.UnitGUID(baseState.next.defaultTarget || "target");
    let name = <string>tokens[index];
    index = index + 1;
    if (name) {
        // this.Log("Checking requirements:");
        let verified = true;
        let requirement = name;
        while (verified && name) {
            let handler = requirements[name];
            if (handler) {
                [verified, requirement, index] = handler(spellId, atTime, name, tokens, index, targetGUID);
                name = <string>tokens[index];
                index = index + 1;
            } else {
                Ovale.OneTimeMessage("Warning: requirement '%s' has no registered handler; FAILING requirement.", name);
                verified = false;
            }
        }
        return [verified, requirement, index];
    }
    return [true, undefined, undefined];
}

// TODO to avoid circular dependencies
RegisterRequirement("combat", baseState.CombatRequirement);
