import { unpack } from "@wowts/lua";
import { C_Soulbinds } from "@wowts/wow-mock";
import { OptionUiGroup } from "../acegui-helpers";
import {
    ConditionFunction,
    OvaleConditionClass,
    ReturnBoolean,
    ReturnConstant,
} from "../Condition";
import { OvaleDebugClass } from "../Debug";

export class Conduit {
    private debugOptions: OptionUiGroup = {
        type: "group",
        name: "Conduits",
        args: {
            conduits: {
                type: "input",
                name: "Conduits",
                multiline: 25,
                width: "full",
                get: () => {
                    return "";
                },
            },
        },
    };

    constructor(debug: OvaleDebugClass) {
        debug.defaultOptions.args["covenant"] = this.debugOptions;
    }

    registerConditions(condition: OvaleConditionClass) {
        condition.RegisterCondition("conduit", false, this.conduit);
        condition.RegisterCondition("conduitrank", false, this.conduitRank);
    }

    private conduit: ConditionFunction = (positionalParameters) => {
        const [conduitId] = unpack(positionalParameters);
        const soulbindID = C_Soulbinds.GetActiveSoulbindID();
        return ReturnBoolean(
            C_Soulbinds.IsConduitInstalledInSoulbind(
                soulbindID,
                conduitId as number
            )
        );
    };

    private conduitRank: ConditionFunction = (positionalParameters) => {
        const [conduitId] = unpack(positionalParameters);
        const data = C_Soulbinds.GetConduitCollectionData(conduitId as number);
        if (!data) return [];
        return ReturnConstant(data.conduitRank);
    };
}
