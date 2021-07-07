import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    LuaArray,
    ipairs,
    kpairs,
    lualength,
    tonumber,
    unpack,
    wipe,
} from "@wowts/lua";
import { concat, insert } from "@wowts/table";
import { AceModule } from "@wowts/tsaddon";
import { C_LegendaryCrafting, Enum } from "@wowts/wow-mock";
import { OvaleClass } from "../Ovale";
import {
    ConditionFunction,
    OvaleConditionClass,
    returnBoolean,
} from "../engine/condition";
import { DebugTools } from "../engine/debug";
import { isNumber, oneTimeMessage } from "../tools/tools";
import { OptionUiGroup } from "../ui/acegui-helpers";
import { OvaleEquipmentClass, inventorySlotNames } from "./Equipment";

export class Runeforge {
    private module: AceModule & AceEvent;
    private equippedLegendaryById: LuaArray<boolean> = {};
    private equippedRuneforgeById: LuaArray<boolean> = {};

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
                    const ids =
                        C_LegendaryCrafting.GetRuneforgePowers(undefined);
                    const output: LuaArray<string> = {};
                    for (const [, id] of ipairs(ids)) {
                        const runeforgePower =
                            C_LegendaryCrafting.GetRuneforgePowerInfo(id);
                        if (runeforgePower != undefined) {
                            insert(output, `${id}: ${runeforgePower.name}`);
                        }
                    }
                    insert(output, "");
                    insert(output, "Equipped:");
                    for (const [id] of kpairs(this.equippedRuneforgeById)) {
                        insert(output, `    ${id}`);
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
                    insert(output, "Legendary bonus IDs:");
                    for (const [id] of kpairs(this.equippedLegendaryById)) {
                        insert(output, `    ${id}`);
                    }
                    return concat(output, "\n");
                },
            },
        },
    };

    constructor(
        ovale: OvaleClass,
        debug: DebugTools,
        private equipment: OvaleEquipmentClass
    ) {
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
            this.handleOvaleEquipmentChanged
        );
    };

    private handleDisable = () => {
        this.module.UnregisterMessage("Ovale_EquipmentChanged");
    };

    private handleOvaleEquipmentChanged = (event: string) => {
        wipe(this.equippedLegendaryById);
        wipe(this.equippedRuneforgeById);
        for (const [slot] of kpairs(inventorySlotNames)) {
            // Update bonus IDs list in equippedLegendaryById.
            const quality = this.equipment.getEquippedItemQuality(slot);
            if (quality == Enum.ItemQuality.Legendary) {
                // XXX Assume the first bonus ID is the legendary bonus ID.
                const bonusIds = this.equipment.getEquippedItemBonusIds(slot);
                if (lualength(bonusIds) > 0) {
                    const id = bonusIds[1];
                    this.equippedLegendaryById[id] = true;
                }
            }
            // Update power IDs list in equippedRuneforgeById.
            const location = this.equipment.getEquippedItemLocation(slot);
            if (location != undefined) {
                if (C_LegendaryCrafting.IsRuneforgeLegendary(location)) {
                    const componentInfo =
                        C_LegendaryCrafting.GetRuneforgeLegendaryComponentInfo(
                            location
                        );
                    const id = tonumber(componentInfo.powerID);
                    this.equippedRuneforgeById[id] = true;
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
        const [id] = unpack(positionalParameters);
        if (!isNumber(id)) {
            oneTimeMessage(`${id} is not defined in EquippedRuneforge`);
            return [];
        }
        /* Check both lists and return true if the ID is in either of them.
         * Technically could be incorrect, but chance of collision is very low.
         */
        return returnBoolean(
            this.equippedLegendaryById[id] || this.equippedRuneforgeById[id]
        );
    };
}
