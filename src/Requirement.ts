import { LuaObj, LuaArray } from "@wowts/lua";
import { isLuaArray, OneTimeMessage } from "./tools";
import { BaseState } from "./BaseState";
import { OvaleGUIDClass } from "./GUID";

export type Tokens = LuaArray<string | number>;
export type RequirementMethod = (
    spellId: number,
    atTime: number,
    name: string,
    tokens: Tokens,
    index: number,
    targetGUID: string | undefined
) => [boolean, string, number];

export function getNextToken(
    tokens: Tokens,
    index: number
): [string | number, number] {
    if (isLuaArray(tokens)) {
        const result = tokens[index];
        return [result, index + 1];
    }
    return [tokens, index];
}

export class OvaleRequirement {
    nowRequirements: LuaObj<RequirementMethod> = {};

    constructor(
        private baseState: BaseState,
        private ovaleGuid: OvaleGUIDClass
    ) {}

    RegisterRequirement(name: string, nowMethod: RequirementMethod) {
        this.nowRequirements[name] = nowMethod;
    }

    UnregisterRequirement(name: string) {
        delete this.nowRequirements[name];
    }

    public CheckRequirements(
        spellId: number,
        atTime: number,
        tokens: Tokens,
        index: number,
        targetGUID: string | undefined
    ): [boolean, string?, number?] {
        let requirements = this.nowRequirements;

        targetGUID =
            targetGUID ||
            this.ovaleGuid.UnitGUID(
                this.baseState.next.defaultTarget || "target"
            );
        let name = <string>tokens[index];
        index = index + 1;
        if (name) {
            let verified = true;
            let requirement = name;
            while (verified && name) {
                let handler = requirements[name];
                if (handler) {
                    [verified, requirement, index] = handler(
                        spellId,
                        atTime,
                        name,
                        tokens,
                        index,
                        targetGUID
                    );
                    name = <string>tokens[index];
                    index = index + 1;
                } else {
                    OneTimeMessage(
                        "Warning: requirement '%s' has no registered handler; FAILING requirement.",
                        name
                    );
                    verified = false;
                }
            }
            return [verified, requirement, index];
        }
        return [true, undefined, undefined];
    }
}
