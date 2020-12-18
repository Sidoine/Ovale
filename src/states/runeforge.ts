import { ipairs, LuaArray, tonumber, unpack } from "@wowts/lua";
import { concat, insert } from "@wowts/table";
import { C_LegendaryCrafting, RuneforgePowerState } from "@wowts/wow-mock";
import { OptionUiGroup } from "../ui/acegui-helpers";
import {
    ConditionFunction,
    OvaleConditionClass,
    ReturnBoolean,
} from "../engine/condition";
import { OvaleDebugClass } from "../engine/debug";
import { isNumber, OneTimeMessage } from "../tools/tools";

export class Runeforge {
    private debugOptions: OptionUiGroup = {
        type: "group",
        name: "Runeforges",
        args: {
            runeforge: {
                type: "input",
                name: "Runeforges",
                multiline: 25,
                width: "full",
                get: () => {
                    const ids = C_LegendaryCrafting.GetRuneforgePowers(
                        undefined
                    );
                    const output: LuaArray<string> = {};
                    for (const [, v] of ipairs(ids)) {
                        const runeforgePower = C_LegendaryCrafting.GetRuneforgePowerInfo(
                            v
                        );
                        if (runeforgePower) {
                            insert(output, `${v}: ${runeforgePower.name}`);
                        }
                    }
                    return concat(output, "\n");
                },
            },
        },
    };

    constructor(debug: OvaleDebugClass) {
        debug.defaultOptions.args["runeforge"] = this.debugOptions;
    }

    registerConditions(condition: OvaleConditionClass) {
        condition.RegisterCondition(
            "equippedruneforge",
            false,
            this.equippedRuneforge
        );
        condition.RegisterCondition("runeforge", false, this.equippedRuneforge);
    }

    private equippedRuneforge: ConditionFunction = (positionalParameters) => {
        const [powerId] = unpack(positionalParameters);
        if (!isNumber(powerId)) {
            OneTimeMessage(`${powerId} is not defined in EquippedRuneforge`);
            return [];
        }
        const runeforgePower = C_LegendaryCrafting.GetRuneforgePowerInfo(
            tonumber(powerId)
        );
        return ReturnBoolean(
            runeforgePower.state === RuneforgePowerState.Available
        );
    };
}
