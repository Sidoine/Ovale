import { OvaleClass } from "../Ovale";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { AceModule } from "@wowts/tsaddon";
import { CovenantChosenEvent, C_Covenants } from "@wowts/wow-mock";
import { isNumber, isString, AceEventHandler } from "../tools/tools";
import {
    ConditionFunction,
    OvaleConditionClass,
    returnBoolean,
} from "../engine/condition";
import { LuaArray, ipairs, pairs, unpack } from "@wowts/lua";
import { DebugTools } from "../engine/debug";
import { OptionUiGroup } from "../ui/acegui-helpers";
import { gsub, lower } from "@wowts/string";
import { concat, insert } from "@wowts/table";

const covenantNameById: LuaArray<string> = {};

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
                    for (const [id, name] of pairs(covenantNameById)) {
                        if (this.covenantId === id) {
                            insert(output, `${id}: ${name} (active)`);
                        } else {
                            insert(output, `${id}: ${name}`);
                        }
                    }
                    return concat(output, "\n");
                },
            },
        },
    };

    constructor(ovale: OvaleClass, debug: DebugTools) {
        this.module = ovale.createModule(
            "Covenant",
            this.onEnable,
            this.onDisable,
            aceEvent
        );
        debug.defaultOptions.args["covenant"] = this.debugOptions;
        const ids = C_Covenants.GetCovenantIDs();
        for (const [, v] of ipairs(ids)) {
            const covenant = C_Covenants.GetCovenantData(v);
            if (covenant && covenant.name && covenant.ID) {
                const [name] = gsub(lower(covenant.name), " ", "_");
                covenantNameById[covenant.ID] = name;
            }
        }
    }

    private onEnable = () => {
        this.module.RegisterEvent("COVENANT_CHOSEN", this.onCovenantChosen);
        const id = C_Covenants.GetActiveCovenantID();
        if (id) {
            this.onCovenantChosen("COVENANT_CHOSEN", id);
        }
    };

    private onDisable = () => {
        this.module.UnregisterEvent("COVENANT_CHOSEN");
    };

    private onCovenantChosen: AceEventHandler<CovenantChosenEvent> = (
        event,
        covenantId
    ) => {
        this.covenantId = covenantId;
        const name = this.getCovenant(covenantId);
        this.module.SendMessage("Ovale_CovenantChosen", name);
    };

    public getCovenant(covenantId?: number) {
        covenantId = covenantId || this.covenantId;
        return (covenantId && covenantNameById[covenantId]) || "none";
    }

    public isCovenant(covenant: number | string) {
        if (isNumber(covenant)) {
            return this.covenantId === (covenant as number);
        } else {
            const name = this.getCovenant();
            return name === (covenant as string);
        }
    }

    public registerConditions(condition: OvaleConditionClass) {
        condition.registerCondition(
            "iscovenant",
            false,
            this.isCovenantCondition
        );
    }

    private isCovenantCondition: ConditionFunction = (positionalParameters) => {
        const [covenant] = unpack(positionalParameters);
        if (isNumber(covenant) || isString(covenant)) {
            return returnBoolean(this.isCovenant(covenant));
        }
        return returnBoolean(false);
    };
}
