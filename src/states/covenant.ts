import { OvaleClass } from "../Ovale";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { AceModule } from "@wowts/tsaddon";
import { CovenantChosenEvent, C_Covenants } from "@wowts/wow-mock";
import { AceEventHandler } from "../tools";
import {
    ConditionFunction,
    OvaleConditionClass,
    ReturnBoolean,
} from "../Condition";
import { ipairs, LuaArray, unpack } from "@wowts/lua";
import { OvaleDebugClass } from "../Debug";
import { OptionUiGroup } from "../acegui-helpers";
import { concat, insert } from "@wowts/table";

export class Covenant {
    private module: AceModule & AceEvent;
    private covenantId?: number;
    private debugOptions: OptionUiGroup = {
        type: "group",
        name: "Covenants",
        args: {
            covenants: {
                type: "input",
                name: "Covenants",
                multiline: 25,
                width: "full",
                get: () => {
                    const ids = C_Covenants.GetCovenantIDs();
                    let output: LuaArray<string> = {};
                    for (const [, v] of ipairs(ids)) {
                        const covenant = C_Covenants.GetCovenantData(v);
                        if (covenant) {
                            insert(output, `${covenant.name}: ${covenant.ID}`);
                        }
                    }
                    return concat(output, "\n");
                },
            },
        },
    };

    constructor(
        ovale: OvaleClass,
        condition: OvaleConditionClass,
        debug: OvaleDebugClass
    ) {
        this.module = ovale.createModule(
            "Covenant",
            this.onInitialize,
            this.onDisable,
            aceEvent
        );
        condition.RegisterCondition("iscovenant", false, this.isCovenant);
        debug.defaultOptions.args["covenant"] = this.debugOptions;
    }

    private onInitialize = () => {
        this.module.RegisterEvent("COVENANT_CHOSEN", this.onCovenantChosen);
        this.covenantId = C_Covenants.GetActiveCovenantID();
    };

    private onDisable = () => {};

    private onCovenantChosen: AceEventHandler<CovenantChosenEvent> = (
        _,
        covenantId
    ) => {
        this.covenantId = covenantId;
    };

    private isCovenant: ConditionFunction = (positionalParameters) => {
        const [covenantId] = unpack(positionalParameters);
        return ReturnBoolean(this.covenantId === covenantId);
    };
}
