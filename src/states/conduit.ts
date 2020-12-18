import { unpack } from "@wowts/lua";
import { C_Soulbinds } from "@wowts/wow-mock";
import { OptionUiGroup } from "../ui/acegui-helpers";
import {
    ConditionFunction,
    ConditionResult,
    OvaleConditionClass,
    ReturnBoolean,
    ReturnConstant,
} from "../engine/condition";
import { OvaleDebugClass } from "../engine/debug";
import { conduits } from "../engine/dbc";

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
        debug.defaultOptions.args["conduit"] = this.debugOptions;
    }

    registerConditions(condition: OvaleConditionClass) {
        condition.RegisterCondition("conduit", false, this.conduit);
        condition.RegisterCondition("conduitrank", false, this.conduitRank);
        condition.RegisterCondition(
            "enabledsoulbind",
            false,
            this.enabledSoulbind
        );
        condition.RegisterCondition("soulbind", false, this.enabledSoulbind);
        condition.register(
            "conduitvalue",
            this.conduitValue,
            { type: "number" },
            { name: "conduit", type: "number", optional: false }
        );
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

    private enabledSoulbind: ConditionFunction = (positionalParameters) => {
        const [soulbindId] = unpack(positionalParameters);
        return ReturnBoolean(C_Soulbinds.GetActiveSoulbindID() === soulbindId);
    };

    private conduitValue = (
        atTime: number,
        conduitId: number
    ): ConditionResult => {
        const data = C_Soulbinds.GetConduitCollectionData(conduitId);
        if (!data) return [];
        return ReturnConstant(conduits[conduitId].ranks[data.conduitRank]);
    };
}
