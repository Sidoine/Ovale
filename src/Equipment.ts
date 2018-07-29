import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleDebug } from "./Debug";
import aceEvent from "@wowts/ace_event-3.0";
import { pairs, select, type, unpack, wipe, lualength } from "@wowts/lua";
import { GetInventoryItemID, GetItemInfoInstant, INVSLOT_AMMO, INVSLOT_BACK, INVSLOT_BODY, INVSLOT_CHEST, INVSLOT_FEET, INVSLOT_FINGER1, INVSLOT_FINGER2, INVSLOT_FIRST_EQUIPPED, INVSLOT_HAND, INVSLOT_HEAD, INVSLOT_LAST_EQUIPPED, INVSLOT_LEGS, INVSLOT_MAINHAND, INVSLOT_NECK, INVSLOT_OFFHAND, INVSLOT_SHOULDER, INVSLOT_TABARD, INVSLOT_TRINKET1, INVSLOT_TRINKET2, INVSLOT_WAIST, INVSLOT_WRIST } from "@wowts/wow-mock";

let OvaleEquipmentBase = OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvaleEquipment", aceEvent)));
export let OvaleEquipment: OvaleEquipmentClass;

let OVALE_SLOTNAME = {
    AmmoSlot: INVSLOT_AMMO,
    BackSlot: INVSLOT_BACK,
    ChestSlot: INVSLOT_CHEST,
    FeetSlot: INVSLOT_FEET,
    Finger0Slot: INVSLOT_FINGER1,
    Finger1Slot: INVSLOT_FINGER2,
    HandsSlot: INVSLOT_HAND,
    HeadSlot: INVSLOT_HEAD,
    LegsSlot: INVSLOT_LEGS,
    MainHandSlot: INVSLOT_MAINHAND,
    NeckSlot: INVSLOT_NECK,
    SecondaryHandSlot: INVSLOT_OFFHAND,
    ShirtSlot: INVSLOT_BODY,
    ShoulderSlot: INVSLOT_SHOULDER,
    TabardSlot: INVSLOT_TABARD,
    Trinket0Slot: INVSLOT_TRINKET1,
    Trinket1Slot: INVSLOT_TRINKET2,
    WaistSlot: INVSLOT_WAIST,
    WristSlot: INVSLOT_WRIST
}
let OVALE_ARMORSET_SLOT_IDS = {
    1: INVSLOT_CHEST,
    2: INVSLOT_HAND,
    3: INVSLOT_HEAD,
    4: INVSLOT_LEGS,
    5: INVSLOT_SHOULDER,
    6: INVSLOT_BACK
}
let OVALE_ARMORSET = {}

/*
const GetEquippedItemEquipLoc = function(slotId) {
    OvaleEquipment.StartProfiling("OvaleEquipment_GetEquippedItemEquipLoc");
    let [itemId] = OvaleEquipment.GetEquippedItem(slotId);
    let equipLoc;
    if (itemId) {
        let [ , , , itemEquipLoc] = GetItemInfoInstant(itemId);
        equipLoc = itemEquipLoc;
    }
    OvaleEquipment.StopProfiling("OvaleEquipment_GetEquippedItemEquipLoc");
    return equipLoc;
}
const GetItemLevel = function(slotId) {
    OvaleEquipment.StartProfiling("OvaleEquipment_GetItemLevel");
    let [itemId] = OvaleEquipment.GetEquippedItem(slotId);
    let [itemLevel] = GetDetailedItemLevelInfo(itemId)
    OvaleEquipment.StopProfiling("OvaleEquipment_GetItemLevel");
    return itemLevel;
}
*/
let result = {
}
let count = 0;
let armorSetName = {}
class OvaleEquipmentClass extends OvaleEquipmentBase {
    ready = false;
    equippedItemById = {}
    equippedItemBySlot = {}
    // equippedItemLevels = {}
    mainHandItemType = undefined;
    offHandItemType = undefined;
    armorSetCount = {}
    // metaGem = undefined;
    // mainHandWeaponSpeed = undefined;
    // offHandWeaponSpeed = undefined;
    offhandHasWeapon = undefined

    
    constructor() {
        super();
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
    /* Can now get necessary information from GetItemInfoInstant so event is unnecessary
    GET_ITEM_INFO_RECEIVED(event) {
        this.StartProfiling("OvaleEquipment_GET_ITEM_INFO_RECEIVED");
        this.mainHandItemType = GetEquippedItemEquipLoc(INVSLOT_MAINHAND);
        this.offHandItemType = GetEquippedItemEquipLoc(INVSLOT_OFFHAND);
        let changed = false;
        if (changed) {
            Ovale.needRefresh();
            this.SendMessage("Ovale_EquipmentChanged");
        }
        this.StopProfiling("OvaleEquipment_GET_ITEM_INFO_RECEIVED");
    }
    */
    PLAYER_EQUIPMENT_CHANGED(event, slotId, hasItem) {
        this.StartProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED");
        let changed = this.UpdateItemBySlot(slotId)
        if (changed) {
            this.UpdateArmorSetCount();
            Ovale.needRefresh();
            this.SendMessage("Ovale_EquipmentChanged");
        }
        this.StopProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED");
    }

    GetArmorSetCount(name) {
        let count = this.armorSetCount[name];
        if (!count) {
            const className = Ovale.playerClass;
            if (armorSetName[className] && armorSetName[className][name]) {
                name = armorSetName[className][name];
                count = this.armorSetCount[name];
            }
        }
        return count || 0;
    }

    GetEquippedItem(...__args):number[] {
        count = select("#", __args);
        for (let n = 1; n <= count; n += 1) {
            let slotId = select(n, __args);
            if (slotId && type(slotId) != "number") {
                slotId = OVALE_SLOTNAME[slotId];
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
/* Removed for simplicity as I don't think anyone uses this.  If it does need to be added back then GET_ITEM_INFO_RECEIVED will need to be as well.
    GetEquippedItemLevel(...__args):number[] {
        count = select("#", __args);
        for (let n = 1; n <= count; n += 1) {
            let slotId = select(n, __args);
            if (slotId && type(slotId) != "number") {
                slotId = OVALE_SLOTNAME[slotId];
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
*/
    GetEquippedTrinkets() {
        return [this.equippedItemBySlot[INVSLOT_TRINKET1], this.equippedItemBySlot[INVSLOT_TRINKET2]];
    }
    HasEquippedItem(itemId) {
        return this.equippedItemById[itemId];
    } /*
    HasMainHandWeapon(handedness?) {
        if (handedness) {
            if (handedness == 1) {
                return this.mainHandItemType == "INVTYPE_WEAPON" || this.mainHandItemType == "INVTYPE_WEAPONMAINHAND";
            } else if (handedness == 2) {
                return this.mainHandItemType == "INVTYPE_2HWEAPON";
            }
        } else {
            return this.mainHandItemType == "INVTYPE_WEAPON" || this.mainHandItemType == "INVTYPE_WEAPONMAINHAND" || this.mainHandItemType == "INVTYPE_2HWEAPON";
        }
        return false;
    } 
    HasOffHandWeapon(handedness?) {
        if (handedness) {
            if (handedness == 1) {
                return this.offHandItemType == "INVTYPE_WEAPON" || this.offHandItemType == "INVTYPE_WEAPONOFFHAND" || this.offHandItemType == "INVTYPE_WEAPONMAINHAND";
            } else if (handedness == 2) {
                return this.offHandItemType == "INVTYPE_2HWEAPON";
            }
        } else {
            return this.offHandItemType == "INVTYPE_WEAPON" || this.offHandItemType == "INVTYPE_WEAPONOFFHAND" || this.offHandItemType == "INVTYPE_WEAPONMAINHAND" || this.offHandItemType == "INVTYPE_2HWEAPON";
        }
        return false;
    } */
    HasShield() {
        return this.offHandItemType == "INVTYPE_SHIELD";
    }
    HasRangedWeapon() {
        return (this.mainHandItemType == "INVTYPE_RANGEDRIGHT" || this.mainHandItemType == "INVTYPE_RANGED");
    }
    HasTrinket(itemId) {
        return this.HasEquippedItem(itemId);
    } /*
    HasTwoHandedWeapon(slotId) {
        if (slotId && type(slotId) != "number") {
            slotId = OVALE_SLOTNAME[slotId];
        }
        if (slotId) {
            if (slotId == INVSLOT_MAINHAND) {
                return this.mainHandItemType == "INVTYPE_2HWEAPON";
            } else if (slotId == INVSLOT_OFFHAND) {
                return this.offHandItemType == "INVTYPE_2HWEAPON";
            }
        } else {
            return this.mainHandItemType == "INVTYPE_2HWEAPON" || this.offHandItemType == "INVTYPE_2HWEAPON";
        }
        return false;
    }
    HasOneHandedWeapon(slotId?) {
        if (slotId && type(slotId) != "number") {
            slotId = OVALE_SLOTNAME[slotId];
        }
        if (slotId) {
            if (slotId == INVSLOT_MAINHAND) {
                return this.mainHandItemType == "INVTYPE_WEAPON" || this.mainHandItemType == "INVTYPE_WEAPONMAINHAND";
            } else if (slotId == INVSLOT_OFFHAND) {
                return this.offHandItemType == "INVTYPE_WEAPON" || this.offHandItemType == "INVTYPE_WEAPONMAINHAND";
            }
        } else {
            return this.mainHandItemType == "INVTYPE_WEAPON" || this.mainHandItemType == "INVTYPE_WEAPONMAINHAND" || this.offHandItemType == "INVTYPE_WEAPON" || this.offHandItemType == "INVTYPE_WEAPONMAINHAND";
        }
        return false;
    } */
    UpdateArmorSetCount() {
        this.StartProfiling("OvaleEquipment_UpdateArmorSetCount");
        wipe(this.armorSetCount);
        for (let i = 1; i <= lualength(OVALE_ARMORSET_SLOT_IDS); i += 1) {
            let [itemId] = this.GetEquippedItem(OVALE_ARMORSET_SLOT_IDS[i]);
            if (itemId) {
                let name = OVALE_ARMORSET[itemId];
                if (name) {
                    if (!this.armorSetCount[name]) {
                        this.armorSetCount[name] = 1;
                    } else {
                        this.armorSetCount[name] = this.armorSetCount[name] + 1;
                    }
                }
            }
        }
        this.StopProfiling("OvaleEquipment_UpdateArmorSetCount");
    }
    UpdateItemBySlot(slotId) {
        let prevItemId = this.equippedItemBySlot[slotId]
        if (prevItemId) {
            this.equippedItemById[prevItemId] = undefined;
            //this.equippedItemLevels[prevItemId] = undefined;
        }
        let newItemId = GetInventoryItemID("player", slotId);
        if (newItemId) {
            this.equippedItemById[newItemId] = slotId;
            this.equippedItemBySlot[slotId] = newItemId;
            //this.equippedItemLevels[newItemId] = GetDetailedItemLevelInfo(newItemId);
            if (slotId == INVSLOT_MAINHAND) {
                let [ , , , itemEquipLoc] = GetItemInfoInstant(newItemId);
                this.mainHandItemType = itemEquipLoc;
            } else if (slotId == INVSLOT_OFFHAND) {
                let [ , , , itemEquipLoc] = GetItemInfoInstant(newItemId);
                this.offHandItemType = itemEquipLoc;
            }
            
        } else {
            this.equippedItemBySlot[slotId] = undefined;
            
            if (slotId == INVSLOT_MAINHAND) {
                this.mainHandItemType = undefined;
            } else if (slotId == INVSLOT_OFFHAND) {
                this.offHandItemType = undefined;
            }
        }
        if (prevItemId != newItemId) {
            return true;
        }
        return false;
    }
    UpdateEquippedItems() {
        this.StartProfiling("OvaleEquipment_UpdateEquippedItems");
        let changed = false;
        //let item;
        for (let slotId = INVSLOT_FIRST_EQUIPPED; slotId <= INVSLOT_LAST_EQUIPPED; slotId += 1) {
            if (this.UpdateItemBySlot(slotId)) {
                changed = true;
            }
        }
        /*
        let changedItemLevels = this.UpdateEquippedItemLevels();
        changed = changed  || changedItemLevels;
        this.mainHandItemType = GetEquippedItemEquipLoc(INVSLOT_MAINHAND);
        this.offHandItemType = GetEquippedItemEquipLoc(INVSLOT_OFFHAND);
        */
        if (changed) {
            this.UpdateArmorSetCount();
            Ovale.needRefresh();
            this.SendMessage("Ovale_EquipmentChanged");
        }
        this.ready = true;
        this.StopProfiling("OvaleEquipment_UpdateEquippedItems");
    } /*
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
    } */
    DebugEquipment() {
        for (let slotId = INVSLOT_FIRST_EQUIPPED; slotId <= INVSLOT_LAST_EQUIPPED; slotId += 1) {
            this.Print("Slot %d = %s", slotId, this.GetEquippedItem(slotId));
        }
        this.Print("Main-hand item type: %s", this.mainHandItemType);
        this.Print("Off-hand item type: %s", this.offHandItemType);
        for (const [k, v] of pairs(this.armorSetCount)) {
            this.Print("Player has %d piece(s) of %s armor set.", v, k);
        }
    }
}

OvaleEquipment = new OvaleEquipmentClass();