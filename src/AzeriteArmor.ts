import { OvaleDebug } from "./Debug";
import { L } from "./Localization";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { LuaObj, LuaArray, wipe, pairs, tostring, lualength, ipairs } from "@wowts/lua";
import { sort, insert, concat } from "@wowts/table";
import { C_Item, ItemLocation, C_AzeriteEmpoweredItem, GetSpellInfo } from "@wowts/wow-mock";

let tsort = sort;
let tinsert = insert;
let tconcat = concat;

let item = C_Item
let itemLocation = ItemLocation
let azeriteItem = C_AzeriteEmpoweredItem

interface Trait {
    name?: string;
    spellID: number;
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
        this.RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED", "UpdateTraits")
        this.RegisterEvent("AZERITE_ITEM_POWER_LEVEL_CHANGED", "UpdateTraits")
        this.RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateTraits");
        this.RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "UpdateTraits");
        this.RegisterEvent("SPELLS_CHANGED", "UpdateTraits");
        this.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "UpdateTraits")
    }
    
    OnDisable() {
        this.UnregisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED")
        this.UnregisterEvent("AZERITE_ITEM_POWER_LEVEL_CHANGED")
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
        this.UnregisterEvent("SPELLS_CHANGED");
        this.UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    }
    
    UpdateTraits() {
        this.self_traits = {}
        for(let slot=1; slot < 14; slot+= 1){
            let itemSlot = itemLocation.CreateFromEquipmentSlot(slot)
            if(item.DoesItemExist(itemSlot) && azeriteItem.IsAzeriteEmpoweredItem(itemSlot)){
                let allTraits = azeriteItem.GetAllTierInfo(itemSlot)
                for(const [,traitsInRow] of pairs(allTraits)){
                    for(const [,powerId] of pairs(traitsInRow.azeritePowerIDs)){
                        let isEnabled = azeriteItem.IsPowerSelected(itemSlot, powerId);
                        if(isEnabled){
                            let powerInfo = azeriteItem.GetPowerInfo(powerId)
                            let [name] = GetSpellInfo(powerInfo.spellID);
                            this.self_traits[powerInfo.spellID] = {
                                spellID: powerInfo.spellID,
                                name: name
                            };
                        }
                    }
                }
            }
        }  
    }

    HasTrait(spellId: number) {
        return (this.self_traits[spellId]) && true || false;
    }

    DebugTraits(){
        wipe(this.output);
        let array: LuaArray<string> = {}
        for (const [k, v] of pairs(this.self_traits)) {
            tinsert(array, `${tostring(v.name)}: ${tostring(k)}`);
        }
        tsort(array);
        for (const [, v] of ipairs(array)) {
            this.output[lualength(this.output) + 1] = v;
        }
        return tconcat(this.output, "\n");
    }
}
export const OvaleAzerite = new OvaleAzeriteArmor();