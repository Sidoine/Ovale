import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    LuaObj,
    LuaArray,
    wipe,
    pairs,
    tostring,
    lualength,
    ipairs,
} from "@wowts/lua";
import { sort, insert, concat } from "@wowts/table";
import {
    C_Item,
    ItemLocation,
    C_AzeriteEmpoweredItem,
    GetSpellInfo,
    AzeriteEmpoweredItemSelectionUpdatedEvent,
    PlayerEnteringWorldEvent,
} from "@wowts/wow-mock";
import { OvaleEquipmentClass } from "./Equipment";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { DebugTools } from "../engine/debug";
import { AceEventHandler } from "../tools/tools";
import { OptionUiAll } from "../ui/acegui-helpers";
import {
    OvaleConditionClass,
    returnBoolean,
    returnConstant,
} from "../engine/condition";
import { AstFunctionNode, NamedParametersOf } from "../engine/ast";

const azeriteSlots: LuaArray<boolean> = {
    [1]: true,
    [3]: true,
    [5]: true,
};
interface Trait {
    name?: string;
    spellID: number;
    rank: number;
}

export class OvaleAzeriteArmor {
    traits: LuaObj<Trait> = {};
    output: LuaArray<string> = {};

    debugOptions: LuaObj<OptionUiAll> = {
        azeraittraits: {
            name: "Azerite traits",
            type: "group",
            args: {
                azeraittraits: {
                    name: "Azerite traits",
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: (info: LuaArray<string>) => {
                        return this.debugTraits();
                    },
                },
            },
        },
    };

    private module: AceModule & AceEvent;

    constructor(
        private equipments: OvaleEquipmentClass,
        ovale: OvaleClass,
        ovaleDebug: DebugTools
    ) {
        this.module = ovale.createModule(
            "OvaleAzeriteArmor",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        for (const [k, v] of pairs(this.debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }
    }

    public registerConditions(ovaleCondition: OvaleConditionClass) {
        ovaleCondition.registerCondition(
            "hasazeritetrait",
            false,
            this.hasAzeriteTrait
        );
        ovaleCondition.registerCondition(
            "azeritetraitrank",
            false,
            this.azeriteTraitRank
        );
    }

    private handleInitialize = () => {
        this.module.RegisterMessage("Ovale_EquipmentChanged", this.itemChanged);
        this.module.RegisterEvent(
            "AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED",
            this.handleAzeriteEmpoweredItemSelectionUpdated
        );
        this.module.RegisterEvent(
            "PLAYER_ENTERING_WORLD",
            this.handlePlayerEnteringWorld
        );
    };

    private handleDisable = () => {
        this.module.UnregisterMessage("Ovale_EquipmentChanged");
        this.module.UnregisterEvent("AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
    };

    private itemChanged = () => {
        const slotId = this.equipments.lastChangedSlot;
        if (slotId != undefined && azeriteSlots[slotId]) {
            this.updateTraits();
        }
    };

    private handleAzeriteEmpoweredItemSelectionUpdated: AceEventHandler<AzeriteEmpoweredItemSelectionUpdatedEvent> = () => {
        this.updateTraits();
    };

    private handlePlayerEnteringWorld: AceEventHandler<PlayerEnteringWorldEvent> = () => {
        this.updateTraits();
    };

    updateTraits() {
        this.traits = {};
        for (const [slotId] of pairs(azeriteSlots)) {
            const itemSlot = ItemLocation.CreateFromEquipmentSlot(slotId);
            if (
                C_Item.DoesItemExist(itemSlot) &&
                C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemSlot)
            ) {
                const allTraits = C_AzeriteEmpoweredItem.GetAllTierInfo(
                    itemSlot
                );
                for (const [, traitsInRow] of pairs(allTraits)) {
                    for (const [, powerId] of pairs(
                        traitsInRow.azeritePowerIDs
                    )) {
                        const isEnabled = C_AzeriteEmpoweredItem.IsPowerSelected(
                            itemSlot,
                            powerId
                        );
                        if (isEnabled) {
                            const powerInfo = C_AzeriteEmpoweredItem.GetPowerInfo(
                                powerId
                            );
                            const [name] = GetSpellInfo(powerInfo.spellID);
                            if (this.traits[powerInfo.spellID]) {
                                const rank = this.traits[powerInfo.spellID]
                                    .rank;
                                this.traits[powerInfo.spellID].rank = rank + 1;
                            } else {
                                this.traits[powerInfo.spellID] = {
                                    spellID: powerInfo.spellID,
                                    name: name,
                                    rank: 1,
                                };
                            }
                            break;
                        }
                    }
                }
            }
        }
    }

    hasTrait(spellId: number) {
        return (this.traits[spellId] && true) || false;
    }

    traitRank(spellId: number) {
        if (!this.traits[spellId]) {
            return 0;
        }
        return this.traits[spellId].rank;
    }

    debugTraits() {
        wipe(this.output);
        const array: LuaArray<string> = {};
        for (const [k, v] of pairs(this.traits)) {
            insert(array, `${tostring(v.name)}: ${tostring(k)} (${v.rank})`);
        }
        sort(array);
        for (const [, v] of ipairs(array)) {
            this.output[lualength(this.output) + 1] = v;
        }
        return concat(this.output, "\n");
    }

    private azeriteTraitRank = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const value = this.traitRank(spellId);
        return returnConstant(value);
    };
    private hasAzeriteTrait = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const spellId = positionalParams[1];
        const value = this.hasTrait(spellId);
        return returnBoolean(value);
    };
}
