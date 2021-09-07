import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray, ipairs, pairs } from "@wowts/lua";
import { concat, insert, sort } from "@wowts/table";
import { AceModule } from "@wowts/tsaddon";
import { C_LegendaryCrafting, Enum } from "@wowts/wow-mock";
import { OvaleClass } from "../Ovale";
import {
    ConditionFunction,
    OvaleConditionClass,
    returnBoolean,
} from "../engine/condition";
import { runeforgeBonusId } from "../engine/dbc";
import { DebugTools, Tracer } from "../engine/debug";
import { OptionUiGroup } from "../ui/acegui-helpers";
import { OvaleEquipmentClass, SlotName } from "./Equipment";

export class Runeforge {
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    private equippedRuneforgeById: LuaArray<SlotName> = {};

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
                    const powers =
                        C_LegendaryCrafting.GetRuneforgePowers(undefined);
                    const output: LuaArray<string> = {};
                    for (const [, id] of pairs(powers)) {
                        const [spellId, name] = this.getRuneforgePowerInfo(id);
                        const bonusId =
                            (spellId && runeforgeBonusId[spellId]) || 0;
                        if (bonusId !== 0) {
                            const slot = this.equippedRuneforgeById[bonusId];
                            if (slot) {
                                insert(
                                    output,
                                    `* ${name}: ${bonusId} (${slot})`
                                );
                            } else {
                                insert(output, `  ${name}: ${bonusId}`);
                            }
                        }
                    }
                    sort(output);
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
        this.module = ovale.createModule(
            "OvaleRuneforge",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.tracer = debug.create(this.module.GetName());
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

    private handleOvaleEquipmentChanged = (event: string, slot: SlotName) => {
        for (const [id, slotName] of pairs(this.equippedRuneforgeById)) {
            if (slotName == slot) {
                delete this.equippedRuneforgeById[id];
            }
        }
        const quality = this.equipment.getEquippedItemQuality(slot);
        if (quality == Enum.ItemQuality.Legendary) {
            const powerId = this.getRuneforgePowerId(slot);
            if (powerId) {
                const [spellId] = this.getRuneforgePowerInfo(powerId);
                if (spellId) {
                    const bonusId = runeforgeBonusId[spellId];
                    const bonusIds =
                        this.equipment.getEquippedItemBonusIds(slot);
                    for (const [, id] of ipairs(bonusIds)) {
                        if (bonusId === id) {
                            this.tracer.debug(
                                event,
                                `Slot ${slot} has runeforge bonus ID ${bonusId}`
                            );
                            this.equippedRuneforgeById[id] = slot;
                            break;
                        }
                    }
                }
            }
        }
    };

    private getRuneforgePowerId = (slot: SlotName): number | undefined => {
        const location = this.equipment.getEquippedItemLocation(slot);
        if (location) {
            if (C_LegendaryCrafting.IsRuneforgeLegendary(location)) {
                const componentInfo =
                    C_LegendaryCrafting.GetRuneforgeLegendaryComponentInfo(
                        location
                    );
                return componentInfo.powerID;
            }
        }
        return undefined;
    };

    private getRuneforgePowerInfo = (
        powerId: number
    ): [number | undefined, string | undefined] => {
        const powerInfo = C_LegendaryCrafting.GetRuneforgePowerInfo(powerId);
        if (powerInfo) {
            const spellId = powerInfo.descriptionSpellID;
            const name = powerInfo.name;
            return [spellId, name];
        }
        return [undefined, undefined];
    };

    hasRuneforge(id: number) {
        return this.equippedRuneforgeById[id] !== undefined;
    }

    registerConditions(condition: OvaleConditionClass) {
        condition.registerCondition(
            "equippedruneforge",
            false,
            this.equippedRuneforge
        );
        condition.registerCondition("runeforge", false, this.equippedRuneforge);
    }

    private equippedRuneforge: ConditionFunction = (positionalParameters) => {
        const id = positionalParameters[1] as number;
        return returnBoolean(this.hasRuneforge(id));
    };
}
