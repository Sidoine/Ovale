import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleDebug } from "./Debug";
import aceEvent from "@wowts/ace_event-3.0";
import { pairs, select,  type, unpack, wipe, lualength, LuaArray, ipairs } from "@wowts/lua";
import { sub } from "@wowts/string";
import { GetInventoryItemID, GetInventoryItemLink, GetItemStats, GetItemInfoInstant, GetInventorySlotInfo, INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED } from "@wowts/wow-mock";
import { concat, insert } from "@wowts/table";

let strsub = sub;
let tinsert = insert;
let tconcat = concat;

let OvaleEquipmentBase = OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvaleEquipment", aceEvent)));
export let OvaleEquipment: OvaleEquipmentClass;

let OVALE_SLOTID_BY_SLOTNAME = {
    AmmoSlot: 0,
    HeadSlot: 1,
    NeckSlot: 2,
    ShoulderSlot: 3,
    ShirtSlot: 4, 
    ChestSlot: 5,
    WaistSlot: 6,
    LegsSlot: 7,
    FeetSlot: 8,
    WristSlot: 9,
    HandsSlot: 10,
    Finger0Slot: 11,
    Finger1Slot: 12,
    Trinket0Slot: 13,
    Trinket1Slot: 14,
    BackSlot: 15,
    MainHandSlot: 16,
    SecondaryHandSlot: 17,
    // RangedSlot: 18, no longer used
    TabardSlot: 19
}
let OVALE_SLOTNAME_BY_SLOTID: LuaArray<string> = {}
let OVALE_ONE_HANDED_WEAPON = {
    INVTYPE_WEAPON: true,
    INVTYPE_WEAPONOFFHAND: true,
    INVTYPE_WEAPONMAINHAND: true
}
let OVALE_RANGED_WEAPON = {
    INVTYPE_RANGEDRIGHT: true,
    INVTYPE_RANGED: true
}
let result = {}
let count = 0;
class OvaleEquipmentClass extends OvaleEquipmentBase {
    ready = false;
    equippedItemById = {}
    equippedItemBySlot = {}
    // equippedItemLevels = {}
    mainHandItemType = undefined;
    offHandItemType = undefined;
    mainHandDPS = 0
    offHandDPS = 0
    armorSetCount = {}
    // mainHandWeaponSpeed = 0;
    // offHandWeaponSpeed = 0;
    lastChangedSlot:number = undefined;
    output: LuaArray<string> = {}
    
    debugOptions = {
        itemsequipped: {
            name: "Items equipped",
            type: "group",
            args: {
                itemsequipped: {
                    name: "Items equipped",
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: (info: LuaArray<string>) => {
                        return this.DebugEquipment();
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
        for (const [slotName, ] of pairs(OVALE_SLOTID_BY_SLOTNAME)) {
            let [invSlotId] = GetInventorySlotInfo(slotName)
            OVALE_SLOTID_BY_SLOTNAME[slotName] = invSlotId; // Should already match but in case Blizzard ever changes the slotIds
            OVALE_SLOTNAME_BY_SLOTID[invSlotId] = slotName;
        }
    }

    OnInitialize() {
        //this.RegisterEvent("GET_ITEM_INFO_RECEIVED");
        this.RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateEquippedItems");
        //this.RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE", "UpdateEquippedItemLevels");
        this.RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    }
    OnDisable() {
        //this.UnregisterEvent("GET_ITEM_INFO_RECEIVED");
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        //this.UnregisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE");
        this.UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
    }
    
    PLAYER_EQUIPMENT_CHANGED(event, slotId, hasItem) {
        this.StartProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED");
        let changed = this.UpdateItemBySlot(slotId)
        if (changed) {
            //this.UpdateArmorSetCount();
            Ovale.needRefresh();
            this.SendMessage("Ovale_EquipmentChanged");
        }
        this.StopProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED");
    }
    // Armor sets are retiring after Legion; for now, return 0
    GetArmorSetCount(name) {
        /*
        let count = this.armorSetCount[name];
        if (!count) {
            const className = Ovale.playerClass;
            if (armorSetName[className] && armorSetName[className][name]) {
                name = armorSetName[className][name];
                count = this.armorSetCount[name];
            }
        }
        */
        return 0;
    }
    GetEquippedItemBySlotName(slotName):number {
        if (slotName) {
            let slotId = OVALE_SLOTID_BY_SLOTNAME[slotName];
            if (slotId != undefined) {
                return this.equippedItemBySlot[OVALE_SLOTID_BY_SLOTNAME[slotName]];
            }
        }
        return undefined;
    }
    // What's the purpose with doing it this way vs the above
    /*
    GetEquippedItem(...__args):number[] {
        count = select("#", __args);
        for (let n = 1; n <= count; n += 1) {
            let slotId = select(n, __args);
            if (slotId && type(slotId) != "number") {
                slotId = OVALE_SLOTID_BY_SLOTNAME[slotId];
            }
            if (slotId) {
                result[n] = this.equippedItemBySlot[slotId];
            } else {
                result[n] = undefined;
            }
        }
        if (count > 0) {
            return unpack(result, 1, count);
        } else {
            return undefined;
        }
    }
    */
    GetEquippedTrinkets() {
        return [this.equippedItemBySlot[OVALE_SLOTID_BY_SLOTNAME["Trinket0Slot"]], this.equippedItemBySlot[OVALE_SLOTID_BY_SLOTNAME["Trinket1Slot"]]];
    }
    HasEquippedItem(itemId) {
        return this.equippedItemById[itemId];
    } 
    HasMainHandWeapon(handedness?) {
        if (handedness) {
            if (handedness == 1) {
                return OVALE_ONE_HANDED_WEAPON[this.mainHandItemType];
            } else if (handedness == 2) {
                return this.mainHandItemType == "INVTYPE_2HWEAPON";
            }
        } else {
            return OVALE_ONE_HANDED_WEAPON[this.mainHandItemType] || this.mainHandItemType == "INVTYPE_2HWEAPON";
        }
        return false;
    } 
    HasOffHandWeapon(handedness?) {
        if (handedness) {
            if (handedness == 1) {
                return OVALE_ONE_HANDED_WEAPON[this.offHandItemType];
            } else if (handedness == 2) {
                return this.offHandItemType == "INVTYPE_2HWEAPON";
            }
        } else {
            return OVALE_ONE_HANDED_WEAPON[this.offHandItemType] || this.offHandItemType == "INVTYPE_2HWEAPON";
        }
        return false;
    } 
    HasShield() {
        return this.offHandItemType == "INVTYPE_SHIELD";
    }
    HasRangedWeapon() {
        return OVALE_RANGED_WEAPON[this.mainHandItemType];
    }
    HasTrinket(itemId) {
        return this.HasEquippedItem(itemId);
    }
    HasTwoHandedWeapon() {
        return this.mainHandItemType == "INVTYPE_2HWEAPON" || this.offHandItemType == "INVTYPE_2HWEAPON";
    } 
    HasOneHandedWeapon(slotId?) {
        if (slotId && type(slotId) != "number") {
            slotId = OVALE_SLOTID_BY_SLOTNAME[slotId];
        }
        if (slotId) {
            if (slotId == OVALE_SLOTID_BY_SLOTNAME["MainHandSlot"]) {
                return OVALE_ONE_HANDED_WEAPON[this.mainHandItemType];
            } else if (slotId == OVALE_SLOTID_BY_SLOTNAME["SecondaryHandSlot"]) {
                return OVALE_ONE_HANDED_WEAPON[this.offHandItemType];
            }
        } else {
            return OVALE_ONE_HANDED_WEAPON[this.mainHandItemType] || OVALE_ONE_HANDED_WEAPON[this.offHandItemType];
        }
        return false;
    } 
    UpdateItemBySlot(slotId: number) {
        let prevItemId = this.equippedItemBySlot[slotId];
        if (prevItemId) {
            this.equippedItemById[prevItemId] = undefined;
            //this.equippedItemLevels[prevItemId] = undefined;
        }
        let newItemId = GetInventoryItemID("player", slotId);
        if (newItemId) {
            this.equippedItemById[newItemId] = slotId;
            this.equippedItemBySlot[slotId] = newItemId;
            //this.equippedItemLevels[newItemId] = GetDetailedItemLevelInfo(newItemId);
            if (slotId == OVALE_SLOTID_BY_SLOTNAME["MainHandSlot"]) {
                let [itemEquipLoc, dps] = this.UpdateWeapons(slotId, newItemId);
                this.mainHandItemType = itemEquipLoc;
                this.mainHandDPS = dps;
            } else if (slotId == OVALE_SLOTID_BY_SLOTNAME["SecondaryHandSlot"]) {
                let [itemEquipLoc, dps] = this.UpdateWeapons(slotId, newItemId);
                this.offHandItemType = itemEquipLoc;
                this.offHandDPS = dps
            }
            
        } else {
            this.equippedItemBySlot[slotId] = undefined;
            
            if (slotId == OVALE_SLOTID_BY_SLOTNAME["MainHandSlot"]) {
                this.mainHandItemType = undefined;
                this.mainHandDPS = 0;
            } else if (slotId == OVALE_SLOTID_BY_SLOTNAME["SecondaryHandSlot"] ) {
                this.offHandItemType = undefined;
                this.offHandDPS = 0;
            }
        }
        if (prevItemId != newItemId) {
            return true;
        }
        return false;
    }
    UpdateWeapons(slotId: number, itemId: number): [string, number] {
        let [ , , , itemEquipLoc] = GetItemInfoInstant(itemId);
        let dps = 0;
        let itemLink = GetInventoryItemLink("player", slotId);
        if (itemLink) {
            let stats = GetItemStats(itemLink);
            if (stats) {
                dps = stats["ITEM_MOD_DAMAGE_PER_SECOND_SHORT"];
            }
        }
        return [itemEquipLoc, dps]
    }
    UpdateEquippedItems() {
        this.StartProfiling("OvaleEquipment_UpdateEquippedItems");
        let changed = false;
        for (let slotId = INVSLOT_FIRST_EQUIPPED; slotId <= INVSLOT_LAST_EQUIPPED; slotId += 1) {
            if (OVALE_SLOTNAME_BY_SLOTID[slotId] && this.UpdateItemBySlot(slotId)) {
                changed = true;
            }
        }
        if (changed) {
            Ovale.needRefresh();
            this.SendMessage("Ovale_EquipmentChanged");
        }
        this.ready = true;
        this.StopProfiling("OvaleEquipment_UpdateEquippedItems");
    } 
    
    DebugEquipment() {
        wipe(this.output)
        let array: LuaArray<string> = {}
        /*
        for (let slotId = INVSLOT_FIRST_EQUIPPED; slotId <= INVSLOT_LAST_EQUIPPED; slotId += 1) {
            let slot = tostring(OVALE_SLOTNAME_BY_SLOTID[slotId])
            let itemid = this.GetEquippedItem(slotId) != undefined && tostring(this.GetEquippedItem(slotId)) || ''

            tinsert(array, `${slot}: ${itemid}`)
        }*/
        for (const [slotId, slotName] of ipairs(OVALE_SLOTNAME_BY_SLOTID)) {
            let itemId = this.equippedItemBySlot[slotId] || '';
            let shortSlotName = strsub(slotName, 1, -5)
            tinsert(array, `${shortSlotName}: ${itemId}`)
        }
        tinsert(array, `\n`)
        tinsert(array, `Main Hand DPS = ${this.mainHandDPS}`)
        if (this.HasOffHandWeapon()) {
            tinsert(array, `Off hand DPS = ${this.offHandDPS}`)
        }
        /*
        for (const [k, v] of pairs(this.armorSetCount)) {
            tinsert(array, `Player has ${tonumber(v)} piece(s) of ${tostring(k)} armor set.`)
        }
        */
        for (const [, v] of ipairs(array)) {
            this.output[lualength(this.output) + 1] = v;
        }
        return tconcat(this.output, "\n");
    }
    /* Removed for simplicity as I don't think anyone uses this.  If it does need to be added back then GET_ITEM_INFO_RECEIVED will need to be as well.
const GetItemLevel = function(slotId) {
    OvaleEquipment.StartProfiling("OvaleEquipment_GetItemLevel");
    let [itemId] = OvaleEquipment.GetEquippedItem(slotId);
    let [itemLevel] = GetDetailedItemLevelInfo(itemId)
    OvaleEquipment.StopProfiling("OvaleEquipment_GetItemLevel");
    return itemLevel;
}
    GetEquippedItemLevel(...__args):number[] {
        count = select("#", __args);
        for (let n = 1; n <= count; n += 1) {
            let slotId = select(n, __args);
            if (slotId && type(slotId) != "number") {
                slotId = OVALE_SLOTID_BY_SLOTNAME[slotId];
            }
            if (slotId) {
                result[n] = this.equippedItemLevels[slotId];
            } else {
                result[n] = undefined;
            }
        }
        if (count > 0) {
            return unpack(result, 1, count);
        } else {
            return undefined;
        }
    }
    Can now get necessary information from GetItemInfoInstant so event currently unnecessary
       Will be needed if we need to get ilevel again?
    GET_ITEM_INFO_RECEIVED(event) {
        this.StartProfiling("OvaleEquipment_GET_ITEM_INFO_RECEIVED");
        
        let changed = false;
        if (changed) {
            Ovale.needRefresh();
            this.SendMessage("Ovale_EquipmentChanged");
        }
        this.StopProfiling("OvaleEquipment_GET_ITEM_INFO_RECEIVED");
    }
    UpdateEquippedItemLevels() {
        this.StartProfiling("OvaleEquipment_UpdateEquippedItemLevels");
        let changed = false;
        let itemLevel;
        for (let slotId = INVSLOT_FIRST_EQUIPPED; slotId <= INVSLOT_LAST_EQUIPPED; slotId += 1) {
            itemLevel = GetItemLevel(slotId);
            if (itemLevel != this.equippedItemLevels[slotId]) {
                this.equippedItemLevels[slotId] = itemLevel;
                changed = true;
            }
        }
        if (changed) {
            Ovale.needRefresh();
            this.SendMessage("Ovale_EquipmentChanged");
        }
        this.StopProfiling("OvaleEquipment_UpdateEquippedItemLevels");
        return changed;
    } 
*/
}

OvaleEquipment = new OvaleEquipmentClass();