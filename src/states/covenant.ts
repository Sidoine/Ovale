import { OvaleClass } from "../Ovale";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { AceModule } from "@wowts/tsaddon";
import { CovenantChosenEvent, C_Covenants } from "@wowts/wow-mock";
import { AceEventHandler } from "../tools/tools";
import {
    ConditionFunction,
    OvaleConditionClass,
    ReturnBoolean,
} from "../engine/condition";
import { ipairs, LuaArray, LuaObj, unpack } from "@wowts/lua";
import { OvaleDebugClass } from "../engine/debug";
import { OptionUiGroup } from "../ui/acegui-helpers";
import { gsub, lower } from "@wowts/string";
import { concat, insert } from "@wowts/table";

const COVENANT_ID_BY_NAME: LuaObj<number> = {};

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
                    const output: LuaArray<string> = {};
                    for (const [k, v] of pairs(COVENANT_ID_BY_NAME)) {
                        if (this.covenantId == v) {
                            insert(output, `${k}: ${v} (active)`);
                        } else {
                            insert(output, `${k}: ${v}`);
                        }
                    }
                    return concat(output, "\n");
                },
            },
        },
    };

    constructor(ovale: OvaleClass, debug: OvaleDebugClass) {
        this.module = ovale.createModule(
            "Covenant",
            this.onInitialize,
            this.onDisable,
            aceEvent
        );
        debug.defaultOptions.args["covenant"] = this.debugOptions;
        const ids = C_Covenants.GetCovenantIDs();
        for (const [, v] of ipairs(ids)) {
            const covenant = C_Covenants.GetCovenantData(v);
            if (covenant && covenant.name && covenant.ID) {
                const [name] = gsub(lower(covenant.name), " ", "_");
                COVENANT_ID_BY_NAME[name] = covenant.ID;
            }
        }
    }

    public registerConditions(condition: OvaleConditionClass) {
        condition.RegisterCondition("iscovenant", false, this.isCovenant);
    }

    private onInitialize = () => {
        this.module.RegisterEvent("COVENANT_CHOSEN", this.onCovenantChosen);
        this.covenantId = C_Covenants.GetActiveCovenantID();
    };

    private onDisable = () => {
        this.module.UnregisterEvent("COVENANT_CHOSEN");
    };

    private onCovenantChosen: AceEventHandler<CovenantChosenEvent> = (
        _,
        covenantId
    ) => {
        this.covenantId = covenantId;
    };

    private isCovenant: ConditionFunction = (positionalParameters) => {
        const [covenant] = unpack(positionalParameters);
        if (type(covenant) == "number") {
            return ReturnBoolean(this.covenantId === covenant);
        } else {
            return ReturnBoolean(this.covenantId === COVENANT_ID_BY_NAME[covenant]);
        }
    };
}
