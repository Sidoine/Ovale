import { unpack } from "@wowts/lua";
import { C_Soulbinds } from "@wowts/wow-mock";
import { OptionUiGroup } from "../ui/acegui-helpers";
import {
    ConditionFunction,
    ConditionResult,
    OvaleConditionClass,
    returnBoolean,
    returnConstant,
} from "../engine/condition";
import { DebugTools } from "../engine/debug";
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

    constructor(debug: DebugTools) {
        debug.defaultOptions.args["conduit"] = this.debugOptions;
    }

    registerConditions(condition: OvaleConditionClass) {
        condition.registerCondition("conduit", false, this.conduit);
        condition.registerCondition("conduitrank", false, this.conduitRank);
        condition.registerCondition(
            "enabledsoulbind",
            false,
            this.enabledSoulbind
        );
        condition.registerCondition("soulbind", false, this.enabledSoulbind);
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
        return returnBoolean(
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
        return returnConstant(data.conduitRank);
    };

    private enabledSoulbind: ConditionFunction = (positionalParameters) => {
        const [soulbindId] = unpack(positionalParameters);
        return returnBoolean(C_Soulbinds.GetActiveSoulbindID() === soulbindId);
    };

    private conduitValue = (
        atTime: number,
        conduitId: number
    ): ConditionResult => {
        const data = C_Soulbinds.GetConduitCollectionData(conduitId);
        if (!data) return [];
        return returnConstant(conduits[conduitId].ranks[data.conduitRank]);
    };
}
