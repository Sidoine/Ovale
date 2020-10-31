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
import { OvaleEquipmentClass } from "../Equipment";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { OvaleDebugClass } from "../Debug";
import { AceEventHandler } from "../tools";
import { OptionUiAll } from "../acegui-helpers";

let azeriteSlots: LuaArray<boolean> = {
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
    self_traits: LuaObj<Trait> = {};
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
                        return this.DebugTraits();
                    },
                },
            },
        },
    };

    private module: AceModule & AceEvent;

    constructor(
        private OvaleEquipment: OvaleEquipmentClass,
        ovale: OvaleClass,
        ovaleDebug: OvaleDebugClass
    ) {
        this.module = ovale.createModule(
            "OvaleAzeriteArmor",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
        for (const [k, v] of pairs(this.debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }
    }

    private OnInitialize = () => {
        this.module.RegisterMessage("Ovale_EquipmentChanged", this.ItemChanged);
        this.module.RegisterEvent(
            "AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED",
            this.AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED
        );
        this.module.RegisterEvent(
            "PLAYER_ENTERING_WORLD",
            this.PLAYER_ENTERING_WORLD
        );
    };

    private OnDisable = () => {
        this.module.UnregisterMessage("Ovale_EquipmentChanged");
        this.module.UnregisterEvent("AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
    };

    private ItemChanged = () => {
        let slotId = this.OvaleEquipment.lastChangedSlot;
        if (slotId != undefined && azeriteSlots[slotId]) {
            this.UpdateTraits();
        }
    };

    private AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED: AceEventHandler<
        AzeriteEmpoweredItemSelectionUpdatedEvent
    > = () => {
        this.UpdateTraits();
    };

    private PLAYER_ENTERING_WORLD: AceEventHandler<
        PlayerEnteringWorldEvent
    > = () => {
        this.UpdateTraits();
    };

    UpdateTraits() {
        this.self_traits = {};
        for (const [slotId] of pairs(azeriteSlots)) {
            let itemSlot = ItemLocation.CreateFromEquipmentSlot(slotId);
            if (
                C_Item.DoesItemExist(itemSlot) &&
                C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemSlot)
            ) {
                let allTraits = C_AzeriteEmpoweredItem.GetAllTierInfo(itemSlot);
                for (const [, traitsInRow] of pairs(allTraits)) {
                    for (const [, powerId] of pairs(
                        traitsInRow.azeritePowerIDs
                    )) {
                        let isEnabled = C_AzeriteEmpoweredItem.IsPowerSelected(
                            itemSlot,
                            powerId
                        );
                        if (isEnabled) {
                            let powerInfo = C_AzeriteEmpoweredItem.GetPowerInfo(
                                powerId
                            );
                            let [name] = GetSpellInfo(powerInfo.spellID);
                            if (this.self_traits[powerInfo.spellID]) {
                                let rank = this.self_traits[powerInfo.spellID]
                                    .rank;
                                this.self_traits[powerInfo.spellID].rank =
                                    rank + 1;
                            } else {
                                this.self_traits[powerInfo.spellID] = {
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

    HasTrait(spellId: number) {
        return (this.self_traits[spellId] && true) || false;
    }

    TraitRank(spellId: number) {
        if (!this.self_traits[spellId]) {
            return 0;
        }
        return this.self_traits[spellId].rank;
    }

    DebugTraits() {
        wipe(this.output);
        let array: LuaArray<string> = {};
        for (const [k, v] of pairs(this.self_traits)) {
            insert(array, `${tostring(v.name)}: ${tostring(k)} (${v.rank})`);
        }
        sort(array);
        for (const [, v] of ipairs(array)) {
            this.output[lualength(this.output) + 1] = v;
        }
        return concat(this.output, "\n");
    }
}
