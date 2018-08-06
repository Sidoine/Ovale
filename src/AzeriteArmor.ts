import { OvaleDebug } from "./Debug";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { LuaObj, LuaArray, wipe, pairs, tostring, lualength, ipairs } from "@wowts/lua";
import { sort, insert, concat } from "@wowts/table";
import { C_Item, ItemLocation, C_AzeriteEmpoweredItem, GetSpellInfo, ItemLocationMixin } from "@wowts/wow-mock";
import { OvaleEquipment } from "./Equipment";

let tsort = sort;
let tinsert = insert;
let tconcat = concat;

let item = C_Item
let itemLocation = ItemLocation
let azeriteItem = C_AzeriteEmpoweredItem

let azeriteSlots: LuaArray<boolean> = {
    [1]: true,
    [3]: true,
    [5]: true
}
interface Trait {
    name?: string;
    spellID: number;
    rank: number
}

let OvaleAzeriteArmorBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleAzerite", aceEvent));

class OvaleAzeriteArmor extends OvaleAzeriteArmorBase {
    self_traits: LuaObj<Trait> = {}
    output: LuaArray<string> = {}

    debugOptions = {
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
                    }
                }
            }
        }
    }

    constructor() {
        super();
        for (const [k, v] of pairs(this.debugOptions)) {
            OvaleDebug.options.args[k] = v;
        }
    }
    
    OnInitialize() {
        this.RegisterMessage("Ovale_EquipmentChanged", "ItemChanged")
        this.RegisterEvent("AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED")
        this.RegisterEvent("PLAYER_ENTERING_WORLD")
    }
    
    OnDisable() {
        this.UnregisterMessage("Ovale_EquipmentChanged")
        this.UnregisterEvent("AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED")
        this.UnregisterEvent("PLAYER_ENTERING_WORLD")
    }

    ItemChanged(){
        let slotId = OvaleEquipment.lastChangedSlot;
        if(slotId != undefined && azeriteSlots[slotId]){
            this.UpdateTraits()
        }
    }

    AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED(event: string, itemSlot: ItemLocationMixin){
        this.UpdateTraits()
    }

    PLAYER_ENTERING_WORLD(event:string){
        this.UpdateTraits()
    }
    
    UpdateTraits() {
        this.self_traits = {}
        for(const [slotId,] of pairs(azeriteSlots)){
            let itemSlot = itemLocation.CreateFromEquipmentSlot(slotId)
            if(item.DoesItemExist(itemSlot) && azeriteItem.IsAzeriteEmpoweredItem(itemSlot)){
                let allTraits = azeriteItem.GetAllTierInfo(itemSlot)
                for(const [,traitsInRow] of pairs(allTraits)){
                    for(const [,powerId] of pairs(traitsInRow.azeritePowerIDs)){
                        let isEnabled = azeriteItem.IsPowerSelected(itemSlot, powerId);
                        if(isEnabled){
                            let powerInfo = azeriteItem.GetPowerInfo(powerId)
                            let [name] = GetSpellInfo(powerInfo.spellID);
                            if(this.self_traits[powerInfo.spellID]){
                                let rank = this.self_traits[powerInfo.spellID].rank
                                this.self_traits[powerInfo.spellID].rank = rank + 1
                            }else{
                                this.self_traits[powerInfo.spellID] = {
                                    spellID: powerInfo.spellID,
                                    name: name,
                                    rank: 1
                                };
                            }                            
                            break
                        }
                    }
                }
            }
        }  
    }

    HasTrait(spellId: number) {
        return (this.self_traits[spellId]) && true || false;
    }

    TraitRank(spellId: number) {
        if (!this.self_traits[spellId]) {
            return 0;
        }
        return this.self_traits[spellId].rank;
    }

    DebugTraits(){
        wipe(this.output);
        let array: LuaArray<string> = {}
        for (const [k, v] of pairs(this.self_traits)) {
            tinsert(array, `${tostring(v.name)}: ${tostring(k)} (${v.rank})`);
        }
        tsort(array);
        for (const [, v] of ipairs(array)) {
            this.output[lualength(this.output) + 1] = v;
        }
        return tconcat(this.output, "\n");
    }
}
export const OvaleAzerite = new OvaleAzeriteArmor();