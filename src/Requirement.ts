import { OvaleGUID } from "./GUID";
import { Ovale } from "./Ovale";
import { LuaObj, LuaArray } from "@wowts/lua";
import { baseState } from "./BaseState";

export type RequirementMethod = (spellId: number, atTime: number, name: string, tokens: LuaArray<string> | string | number, index: number, targetGUID: string) => [boolean, string, number];

export const nowRequirements:LuaObj<RequirementMethod> = {}
export function RegisterRequirement(name: string, nowMethod: RequirementMethod) {
    nowRequirements[name] = nowMethod;
}

export function UnregisterRequirement(name) {
    nowRequirements[name] = undefined;
}

export function CheckRequirements(spellId: number, atTime: number, tokens: LuaArray<string>, index: number, targetGUID: string):[boolean, string, number] {
    let requirements = nowRequirements;

    targetGUID = targetGUID || OvaleGUID.UnitGUID(baseState.next.defaultTarget || "target");
    let name = tokens[index];
    index = index + 1;
    if (name) {
        // this.Log("Checking requirements:");
        let verified = true;
        let requirement = name;
        while (verified && name) {
            let handler = requirements[name];
            if (handler) {
                [verified, requirement, index] = handler(spellId, atTime, name, tokens, index, targetGUID);
                name = tokens[index];
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


