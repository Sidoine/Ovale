import { OvaleGUID } from "./GUID";
import { Ovale } from "./Ovale";
import { baseState } from "./State";
import { LuaObj } from "@wowts/lua";

interface Requirement {
    1: any;
    2: any;
}

export const self_requirement:LuaObj<Requirement> = {}
export function RegisterRequirement(name, method, arg) {
    self_requirement[name] = {
        1: method,
        2: arg
    }
}

export function UnregisterRequirement(name) {
    self_requirement[name] = undefined;
}

export function CheckRequirements(spellId, atTime, tokens, index, targetGUID):[boolean, string, number] {
    targetGUID = targetGUID || OvaleGUID.UnitGUID(baseState.defaultTarget || "target");
    let name = tokens[index];
    index = index + 1;
    if (name) {
        // this.Log("Checking requirements:");
        let verified = true;
        let requirement = name;
        while (verified && name) {
            let handler = self_requirement[name];
            if (handler) {
                let method = handler[1];
                let arg = /*this[method] && this ||*/ handler[2]; //TODO
                [verified, requirement, index] = arg[method](arg, spellId, atTime, name, tokens, index, targetGUID);
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


