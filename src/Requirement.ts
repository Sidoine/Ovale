import { LuaObj, LuaArray, truthy } from "@wowts/lua";
import { isLuaArray, OneTimeMessage } from "./tools";
import { BaseState } from "./BaseState";
import { OvaleGUIDClass } from "./GUID";
import { PowerType } from "./states/Power";
import { gsub, match } from "@wowts/string";

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

export type RequirementName =
    | "stance"
    | "target_health_pct"
    | "lossofcontrol"
    | "pet_health_pct"
    | "health_pct"
    | "oncooldown"
    | "target_debuff_any"
    | "target_debuff"
    | "target_buff_any"
    | "target_buff"
    | "stealthed"
    | "stealth"
    | "pet_debuff"
    | "pet_buff"
    | "debuff_any"
    | "buff_any"
    | "spellcount_max"
    | "spellcount_min"
    | "combat"
    | "buff"
    | "debuff"
    | PowerType;

export class OvaleRequirement {
    nowRequirements: LuaObj<RequirementMethod> = {};

    constructor(
        private baseState: BaseState,
        private ovaleGuid: OvaleGUIDClass
    ) {}

    RegisterRequirement(name: RequirementName, nowMethod: RequirementMethod) {
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
                let negate;
                if (truthy(match(name, "^not_"))) {
                    name = gsub(name, "^not_", "");
                    negate = true;
                } else {
                    negate = false;
                }
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
                    if (negate) verified = !verified;
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
