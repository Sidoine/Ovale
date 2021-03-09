import { pairs, ipairs, LuaArray, tonumber, unpack } from "@wowts/lua";
import { concat, insert } from "@wowts/table";
import {
    C_LegendaryCrafting,
    GetInventoryItemQuality,
    GetInventoryItemLink,
    INVSLOT_FIRST_EQUIPPED,
    INVSLOT_LAST_EQUIPPED,
} from "@wowts/wow-mock";
import { OptionUiGroup } from "../ui/acegui-helpers";
import {
    ConditionFunction,
    OvaleConditionClass,
    returnBoolean,
} from "../engine/condition";
import { DebugTools } from "../engine/debug";
import { isNumber, oneTimeMessage } from "../tools/tools";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { match } from "@wowts/string";

export class Runeforge {
    private module: AceModule & AceEvent;
    private equippedLegendaryById: LuaArray<number> = {};

    private debugRuneforges: OptionUiGroup = {
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

    private debugLegendaries: OptionUiGroup = {
        type: "group",
        name: "Legendaries",
        args: {
            legendaries: {
                type: "input",
                name: "Legendaries",
                multiline: 25,
                width: "full",
                get: () => {
                    const output: LuaArray<string> = {};
                    for (const [id, v] of pairs(this.equippedLegendaryById)) {
                        insert(output, `${id}: ${v}`);
                    }
                    return concat(output, "\n");
                },
            },
        },
    };

    constructor(ovale: OvaleClass, debug: DebugTools) {
        debug.defaultOptions.args["runeforge"] = this.debugRuneforges;
        debug.defaultOptions.args["legendaries"] = this.debugLegendaries;

        this.module = ovale.createModule(
            "OvaleRuneforge",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
    }

    private handleInitialize = () => {
        this.module.RegisterMessage(
            "Ovale_EquipmentChanged",
            this.updateEquippedItems
        );
    };
    private handleDisable = () => {
        this.module.UnregisterMessage("Ovale_EquipmentChanged");
    };
    private updateEquippedItems = () => {
        this.equippedLegendaryById = {};
        // we need to scan for legendaries now
        for (
            let slotId = INVSLOT_FIRST_EQUIPPED;
            slotId <= INVSLOT_LAST_EQUIPPED;
            slotId += 1
        ) {
            if (GetInventoryItemQuality("player", slotId) == 5) {
                const [newItemLink] = match(
                    GetInventoryItemLink("player", slotId),
                    "item:([%-?%d:]+)"
                );
                if (newItemLink) {
                    const [newLegendaryId] = match(
                        newItemLink,
                        "%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:(%d*):"
                    );
                    this.equippedLegendaryById[
                        tonumber(newLegendaryId)
                    ] = tonumber(slotId);
                }
            }
        }
    };

    registerConditions(condition: OvaleConditionClass) {
        condition.registerCondition(
            "equippedruneforge",
            false,
            this.equippedRuneforge
        );
        condition.registerCondition("runeforge", false, this.equippedRuneforge);
    }

    private equippedRuneforge: ConditionFunction = (positionalParameters) => {
        const [bonusItemId] = unpack(positionalParameters);
        if (!isNumber(bonusItemId)) {
            oneTimeMessage(
                `${bonusItemId} is not defined in EquippedRuneforge`
            );
            return [];
        }
        return returnBoolean(
            this.equippedLegendaryById[bonusItemId] !== undefined
        );
    };
}
