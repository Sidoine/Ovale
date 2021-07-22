import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    LuaArray,
    LuaObj,
    ipairs,
    kpairs,
    lualength,
    pairs,
    tonumber,
    type,
    wipe,
} from "@wowts/lua";
import { huge as INFINITY } from "@wowts/math";
import { find, len, lower, match, sub } from "@wowts/string";
import { concat, insert, sort } from "@wowts/table";
import { AceModule } from "@wowts/tsaddon";
import {
    C_Item,
    Enum,
    GetInventorySlotInfo,
    GetItemCooldown,
    GetItemStats,
    GetTime,
    GetWeaponEnchantInfo,
    InventorySlotName,
    ItemLocation,
    ItemLocationMixin,
} from "@wowts/wow-mock";
import { OvaleClass } from "../Ovale";
import { AstFunctionNode, NamedParametersOf } from "../engine/ast";
import {
    ConditionFunction,
    ConditionResult,
    OvaleConditionClass,
    ParameterInfo,
    returnBoolean,
    returnConstant,
    returnValueBetween,
} from "../engine/condition";
import { OvaleDataClass } from "../engine/data";
import { DebugTools, Tracer } from "../engine/debug";
import { Profiler, OvaleProfilerClass } from "../engine/profiler";
import { KeyCheck } from "../tools/tools";
import { OptionUiAll } from "../ui/acegui-helpers";

// To allow iteration over InventorySlotNames.
export type InventorySlotNameMap = { [key in InventorySlotName]?: boolean };
export const inventorySlotNames: InventorySlotNameMap = {
    AMMOSLOT: true,
    BACKSLOT: true,
    CHESTSLOT: true,
    FEETSLOT: true,
    FINGER0SLOT: true,
    FINGER1SLOT: true,
    HANDSSLOT: true,
    HEADSLOT: true,
    LEGSSLOT: true,
    MAINHANDSLOT: true,
    NECKSLOT: true,
    // (removed in retail) RANGEDSLOT: true,
    SECONDARYHANDSLOT: true,
    SHIRTSLOT: true,
    SHOULDERSLOT: true,
    TABARDSLOT: true,
    TRINKET0SLOT: true,
    TRINKET1SLOT: true,
    WAISTSLOT: true,
    WRISTSLOT: true,
};

// Bijection between InventorySlotName and InventorySlotID.
const slotIdByName: LuaObj<number> = {};
const slotNameById: LuaArray<InventorySlotName> = {};

// Slot names used in Ovale scripts.
export type SlotName =
    | "ammoslot"
    | "backslot"
    | "chestslot"
    | "feetslot"
    | "finger0slot"
    | "finger1slot"
    | "handsslot"
    | "headslot"
    | "legsslot"
    | "mainhandslot"
    | "neckslot"
    | "offhandslot"
    | "secondaryhandslot"
    | "shirtslot"
    | "shoulderslot"
    | "tabardslot"
    | "trinket0slot"
    | "trinket1slot"
    | "waistslot"
    | "wristslot";

const checkSlotName: KeyCheck<SlotName> = {
    ammoslot: true,
    backslot: true,
    chestslot: true,
    feetslot: true,
    finger0slot: true,
    finger1slot: true,
    handsslot: true,
    headslot: true,
    legsslot: true,
    mainhandslot: true,
    neckslot: true,
    offhandslot: true,
    secondaryhandslot: true,
    shirtslot: true,
    shoulderslot: true,
    tabardslot: true,
    trinket0slot: true,
    trinket1slot: true,
    waistslot: true,
    wristslot: true,
};

// Map Ovale slot names to InventorySlotName.
const slotNameByName: LuaObj<InventorySlotName> = {
    ammoslot: "AMMOSLOT",
    backslot: "BACKSLOT",
    chestslot: "CHESTSLOT",
    feetslot: "FEETSLOT",
    finger0slot: "FINGER0SLOT",
    finger1slot: "FINGER1SLOT",
    handsslot: "HANDSSLOT",
    headslot: "HEADSLOT",
    legsslot: "LEGSSLOT",
    mainhandslot: "MAINHANDSLOT",
    neckslot: "NECKSLOT",
    offhandslot: "SECONDARYHANDSLOT",
    secondaryhandslot: "SECONDARYHANDSLOT",
    shirtslot: "SHIRTSLOT",
    shoulderslot: "SHOULDERSLOT",
    tabardslot: "TABARDSLOT",
    trinket0slot: "TRINKET0SLOT",
    trinket1slot: "TRINKET1SLOT",
    waistslot: "WAISTSLOT",
    wristslot: "WRISTSLOT",
};

// Map InventorySlotName to Ovale slot names.
type OvaleSlotNameMap = { [key in InventorySlotName]?: SlotName };
const ovaleSlotNameByName: OvaleSlotNameMap = {};

interface ItemInfo {
    exists: boolean;
    guid: string;
    pending?: number;
    id?: number;
    link?: string;
    location?: ItemLocationMixin;
    name?: string;
    quality?: number; // Enum.ItemQuality
    type?: number; // Enum.InventoryType
    // The properties below are populated by parseItemLink().
    gem: LuaArray<number>;
    bonus: LuaArray<number>;
    modifier: LuaArray<number>;
}

function resetItemInfo(item: ItemInfo) {
    item.exists = false;
    item.guid = "";
    delete item.pending;
    delete item.link;
    delete item.location;
    delete item.name;
    delete item.quality;
    delete item.type;
    delete item.id;
    wipe(item.gem);
    wipe(item.bonus);
    wipe(item.modifier);
}

export class OvaleEquipmentClass {
    mainHandDPS = 0;
    offHandDPS = 0;
    // armorSetCount = {};

    private equippedItem: LuaObj<ItemInfo> = {};
    private equippedItemBySharedCooldown: LuaObj<number> = {};
    private isEquippedItemById: LuaObj<boolean> = {};

    private debugOptions: LuaObj<OptionUiAll> = {
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
                        return this.debugEquipment();
                    },
                },
            },
        },
    };
    private module: AceModule & AceEvent;
    private tracer: Tracer;
    private profiler: Profiler;

    constructor(
        private ovale: OvaleClass,
        ovaleDebug: DebugTools,
        ovaleProfiler: OvaleProfilerClass,
        private data: OvaleDataClass
    ) {
        this.module = ovale.createModule(
            "OvaleEquipment",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create("OvaleEquipment");
        this.profiler = ovaleProfiler.create(this.module.GetName());

        for (const [k, v] of pairs(this.debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }

        for (const [slot] of kpairs(inventorySlotNames)) {
            ovaleSlotNameByName[slot] = lower(slot) as SlotName;
            const [slotId] = GetInventorySlotInfo(slot);
            slotIdByName[slot] = slotId;
            slotNameById[slotId] = slot;
            this.equippedItem[slot] = {
                exists: false,
                guid: "",
                gem: {},
                bonus: {},
                modifier: {},
            };
        }
    }

    private handleInitialize = () => {
        this.module.RegisterEvent(
            "ITEM_DATA_LOAD_RESULT",
            this.handleItemDataLoadResult
        );
        this.module.RegisterEvent(
            "PLAYER_ENTERING_WORLD",
            this.handlePlayerEnteringWorld
        );
        this.module.RegisterEvent(
            "PLAYER_EQUIPMENT_CHANGED",
            this.handlePlayerEquipmentChanged
        );
    };
    private handleDisable = () => {
        this.module.UnregisterEvent("ITEM_DATA_LOAD_RESULT");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
    };

    private handleItemDataLoadResult = (
        event: string,
        itemId: number,
        success: boolean
    ) => {
        if (success && this.isEquippedItemById[itemId]) {
            for (const [slot, item] of pairs(this.equippedItem)) {
                if (item.pending) {
                    const slotId = slotIdByName[slot];
                    const location =
                        ItemLocation.CreateFromEquipmentSlot(slotId);
                    if (location.IsValid() && item.pending == itemId) {
                        this.finishUpdateForSlot(
                            slot as InventorySlotName,
                            itemId,
                            location
                        );
                    }
                }
            }
        }
    };

    private handlePlayerEnteringWorld = (event: string) => {
        for (const [slot] of kpairs(inventorySlotNames)) {
            this.queueUpdateForSlot(slot);
        }
    };

    private handlePlayerEquipmentChanged = (
        event: string,
        slotId: number,
        hasCurrent: boolean
    ) => {
        const slot = slotNameById[slotId];
        this.queueUpdateForSlot(slot);
    };

    // Armor sets are retiring after Legion; for now, return 0
    getArmorSetCount(name: string) {
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

    getEquippedItemId(slot: SlotName): number | undefined {
        const invSlot = slotNameByName[slot];
        const item = this.equippedItem[invSlot];
        return (item.exists && item.id) || undefined;
    }

    getEquippedItemIdBySharedCooldown(
        sharedCooldown: string
    ): number | undefined {
        return this.equippedItemBySharedCooldown[sharedCooldown];
    }

    getEquippedItemLocation(slot: SlotName): ItemLocationMixin | undefined {
        const invSlot = slotNameByName[slot];
        const item = this.equippedItem[invSlot];
        if (item.exists) {
            if (item.location && item.location.IsValid()) {
                return item.location;
            }
        }
        return undefined;
    }

    getEquippedItemQuality(slot: SlotName): number | undefined {
        const invSlot = slotNameByName[slot];
        const item = this.equippedItem[invSlot];
        return (item.exists && item.quality) || undefined;
    }

    getEquippedItemBonusIds(slot: SlotName): LuaArray<number> {
        // Returns the array of bonus IDs for the slot.
        const invSlot = slotNameByName[slot];
        const item = this.equippedItem[invSlot];
        return item.bonus;
    }

    hasRangedWeapon() {
        const item = this.equippedItem["MAINHANDSLOT"];
        if (item.exists && item.type != undefined) {
            return (
                item.type == Enum.InventoryType.IndexRangedType ||
                item.type == Enum.InventoryType.IndexRangedrightType
            );
        }
        return false;
    }

    private parseItemLink = (link: string, item: ItemInfo) => {
        let [s] = match(link, "item:([%-?%d:]+)");
        const pattern = "[^:]*:";
        let [i, j] = find(s, pattern);
        let eos = len(s);
        let numBonus = 0;
        let numModifiers = 0;
        let index = 0;
        while (i) {
            const token = tonumber(sub(s, i, j - 1)) || 0;
            index = index + 1;
            if (index == 1) {
                item.id = token;
            } else if (3 <= index && index <= 5) {
                if (token != 0) {
                    const gem = item.gem || {};
                    insert(gem, token);
                    item.gem = gem;
                }
            } else if (index == 13) {
                numBonus = token;
            } else if (index > 13 && index <= 13 + numBonus) {
                const bonus = item.bonus || {};
                insert(bonus, token);
                item.bonus = bonus;
            } else if (index == 13 + numBonus + 1) {
                numModifiers = token;
            } else if (
                index > 13 + numBonus + 1 &&
                index <= 13 + numBonus + 1 + numModifiers
            ) {
                const modifier = item.modifier || {};
                insert(modifier, token);
                item.modifier = modifier;
            }
            if (j < eos) {
                s = sub(s, j + 1);
                [i, j] = find(s, pattern);
            } else {
                break;
            }
        }
        // Ignore the last token since we don't need it for Ovale.
    };

    private queueUpdateForSlot = (slot: InventorySlotName) => {
        const slotId = slotIdByName[slot];
        const location = ItemLocation.CreateFromEquipmentSlot(slotId);
        const item = this.equippedItem[slot];
        if (location.IsValid()) {
            const itemId = C_Item.GetItemID(location);
            this.isEquippedItemById[itemId] = true;
            const link = C_Item.GetItemLink(location);
            if (link) {
                // Item link is available, so data is already loaded.
                this.finishUpdateForSlot(slot, itemId, location);
            } else {
                // Save pending itemID to be checked in event handler.
                item.pending = itemId;
                C_Item.RequestLoadItemData(location);
                this.tracer.debug(`Slot ${slot}, item ${itemId}: queued`);
            }
        } else {
            this.tracer.debug(`Slot ${slot}: empty`);
            resetItemInfo(item);
        }
    };

    private finishUpdateForSlot = (
        slot: InventorySlotName,
        itemId: number,
        location: ItemLocationMixin
    ) => {
        this.profiler.startProfiling(
            "OvaleEquipment_finishUpdateForEquippedItem"
        );
        this.tracer.debug(`Slot ${slot}, item ${itemId}: finished`);
        const item = this.equippedItem[slot];
        if (location.IsValid()) {
            const prevGUID = item.guid;
            const prevItemId = item.id;
            if (prevItemId != undefined) {
                delete this.isEquippedItemById[prevItemId];
            }
            resetItemInfo(item);
            item.exists = true;
            item.guid = C_Item.GetItemGUID(location);
            item.id = itemId;
            item.location = location;
            item.name = C_Item.GetItemName(location);
            item.quality = C_Item.GetItemQuality(location);
            item.type = C_Item.GetItemInventoryType(location);
            const link = C_Item.GetItemLink(location);
            if (link) {
                item.link = link;
                this.parseItemLink(link, item);
                if (slot == "MAINHANDSLOT" || slot == "SECONDARYHANDSLOT") {
                    const stats = GetItemStats(link);
                    if (stats != undefined) {
                        const dps =
                            stats["ITEM_MOD_DAMAGE_PER_SECOND_SHORT"] || 0;
                        if (slot == "MAINHANDSLOT") {
                            this.mainHandDPS = dps;
                        } else if (slot == "SECONDARYHANDSLOT") {
                            this.offHandDPS = dps;
                        }
                    }
                }
            }
            this.isEquippedItemById[itemId] = true;
            const info = this.data.itemInfo[itemId];
            if (info != undefined && info.shared_cd != undefined) {
                this.equippedItemBySharedCooldown[info.shared_cd] = itemId;
            }

            if (prevGUID != item.guid) {
                //this.UpdateArmorSetCount();
                this.ovale.needRefresh();
                const slotName = ovaleSlotNameByName[slot];
                this.module.SendMessage("Ovale_EquipmentChanged", slotName);
            }
        } else {
            resetItemInfo(item);
        }
        this.profiler.stopProfiling(
            "OvaleEquipment_finishUpdateForEquippedItem"
        );
    };

    private debugEquipment = () => {
        const output: LuaArray<string> = {};
        const array: LuaArray<string> = {};
        insert(output, "Equipped Items:");
        for (const [id] of kpairs(this.isEquippedItemById)) {
            insert(array, `    ${id}`);
        }
        sort(array);
        for (const [, v] of ipairs(array)) {
            insert(output, v);
        }
        insert(output, "");
        wipe(array);
        for (const [slot, item] of pairs(this.equippedItem)) {
            const shortSlot = lower(sub(slot, 1, -5));
            if (item.exists) {
                let s = `${shortSlot}: ${item.id}`;
                if (lualength(item.gem) > 0) {
                    s = s + " gem[";
                    for (const [, v] of ipairs(item.gem)) {
                        s = s + ` ${v}`;
                    }
                    s = s + "]";
                }
                if (lualength(item.bonus) > 0) {
                    s = s + " bonus[";
                    for (const [, v] of ipairs(item.bonus)) {
                        s = s + ` ${v}`;
                    }
                    s = s + "]";
                }
                if (lualength(item.modifier) > 0) {
                    s = s + " mod[";
                    for (const [, v] of ipairs(item.modifier)) {
                        s = s + ` ${v}`;
                    }
                    s = s + "]";
                }
                insert(array, s);
            } else {
                insert(array, `${shortSlot}: empty`);
            }
        }
        sort(array);
        for (const [, v] of ipairs(array)) {
            insert(output, v);
        }
        insert(output, "");
        insert(output, `Main-hand DPS = ${this.mainHandDPS}`);
        insert(output, `Off-hand DPS = ${this.offHandDPS}`);
        return concat(output, "\n");
    };

    registerConditions(ovaleCondition: OvaleConditionClass) {
        ovaleCondition.registerCondition(
            "hasequippeditem",
            false,
            this.hasItemEquipped
        );
        ovaleCondition.registerCondition("hasshield", false, this.hasShield);
        ovaleCondition.registerCondition("hastrinket", false, this.hasTrinket);
        const slotParameter: ParameterInfo<SlotName> = {
            type: "string",
            name: "slot",
            checkTokens: checkSlotName,
            optional: true,
        };
        const itemParameter: ParameterInfo<number> = {
            name: "item",
            type: "number",
            optional: true,
            isItem: true,
        };
        ovaleCondition.register(
            "itemcooldown",
            this.itemCooldown,
            { type: "number" },
            itemParameter,
            slotParameter,
            { name: "shared", type: "string", optional: true }
        );
        ovaleCondition.register(
            "itemrppm",
            this.itemRppm,
            { type: "number" },
            { type: "number", name: "item", optional: true },
            {
                type: "string",
                name: "slot",
                checkTokens: checkSlotName,
                optional: true,
            }
        );
        ovaleCondition.register(
            "itemcooldownduration",
            this.itemCooldownDuration,
            { type: "number" },
            itemParameter,
            slotParameter
        );
        ovaleCondition.registerCondition(
            "weaponenchantexpires",
            false,
            this.weaponEnchantExpires
        );
        ovaleCondition.registerCondition(
            "weaponenchantpresent",
            false,
            this.weaponEnchantPresent
        );
        ovaleCondition.register(
            "iteminslot",
            this.itemInSlot,
            { type: "number" },
            {
                type: "string",
                optional: false,
                name: "slot",
                checkTokens: checkSlotName,
            }
        );
    }

    /**  Test if the player has a particular item equipped.
	 @name HasEquippedItem
	 @paramsig boolean
	 @param item Item to be checked whether it is equipped.
     */
    private hasItemEquipped = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const itemId = positionalParams[1];
        let boolean = false;
        if (type(itemId) == "number") {
            boolean = this.isEquippedItemById[itemId];
        } else if (this.data.itemList[itemId] != undefined) {
            for (const [, id] of pairs(this.data.itemList[itemId])) {
                boolean = this.isEquippedItemById[id];
                if (boolean) break;
            }
        }
        return returnBoolean(boolean);
    };

    /** Test if the player has a shield equipped.
	 @name HasShield
	 @paramsig boolean
	 @return A boolean value.
	 @usage
	 if HasShield() Spell(shield_wall)
     */
    private hasShield = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const item = this.equippedItem["SECONDARYHANDSLOT"];
        const boolean =
            item.exists && item.type == Enum.InventoryType.IndexShieldType;
        return returnBoolean(boolean);
    };

    /** Test if the player has a particular trinket equipped.
	 @name HasTrinket
	 @paramsig boolean
	 @param id The item ID of the trinket or the name of an item list.
	 @usage
	 ItemList(rune_of_reorigination 94532 95802 96546)
	 if HasTrinket(rune_of_reorigination) and BuffPresent(rune_of_reorigination_buff)
	     Spell(rake)
     */
    private hasTrinket = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const itemId = positionalParams[1];
        let boolean = false;
        if (type(itemId) == "number") {
            // Check only in the trinket slots.
            boolean =
                (this.equippedItem["TRINKET0SLOT"].exists &&
                    this.equippedItem["TRINKET0SLOT"].id == itemId) ||
                (this.equippedItem["TRINKET1SLOT"].exists &&
                    this.equippedItem["TRINKET1SLOT"].id == itemId);
        } else if (this.data.itemList[itemId] != undefined) {
            for (const [, id] of pairs(this.data.itemList[itemId])) {
                boolean =
                    (this.equippedItem["TRINKET0SLOT"].exists &&
                        this.equippedItem["TRINKET0SLOT"].id == id) ||
                    (this.equippedItem["TRINKET1SLOT"].exists &&
                        this.equippedItem["TRINKET1SLOT"].id == id);
                if (boolean) break;
            }
        }
        return returnBoolean(boolean);
    };

    /** Get the cooldown time in seconds of an item, e.g., trinket.
	 @name ItemCooldown
	 @paramsig number or boolean
	 @param id The item ID or the equipped slot name.
	 @return The number of seconds.
	 @usage
	 if not ItemCooldown(ancient_petrified_seed) > 0
	     Spell(berserk_cat)
	 if not ItemCooldown(Trinket0Slot) > 0
	     Spell(berserk_cat)
     */
    private itemCooldown = (
        atTime: number,
        itemId: number | undefined,
        slot: SlotName | undefined,
        sharedCooldown: string | undefined
    ) => {
        if (sharedCooldown) {
            itemId = this.getEquippedItemIdBySharedCooldown(sharedCooldown);
        }
        if (slot != undefined) {
            itemId = this.getEquippedItemId(slot);
        }
        if (itemId) {
            const [start, duration] = GetItemCooldown(itemId);
            if (start > 0 && duration > 0) {
                const ending = start + duration;
                return returnValueBetween(start, ending, duration, start, -1);
            }
        }
        return returnConstant(0);
    };

    private itemCooldownDuration = (
        atTime: number,
        itemId: number | undefined,
        slot: SlotName | undefined
    ) => {
        if (slot !== undefined) {
            itemId = this.getEquippedItemId(slot);
        }
        if (!itemId) return returnConstant(0);

        let [, duration] = GetItemCooldown(itemId);
        if (duration <= 0) {
            duration =
                (this.data.getItemInfoProperty(
                    itemId,
                    atTime,
                    "cd"
                ) as number) || 0;
        }
        return returnConstant(duration);
    };

    private itemInSlot = (atTime: number, slot: SlotName) => {
        const itemId = this.getEquippedItemId(slot);
        return returnConstant(itemId);
    };

    /** Get the number of seconds since the enchantment has expired
     */
    private weaponEnchantExpires: ConditionFunction = (
        positionalParams
    ): ConditionResult => {
        const expectedEnchantmentId = positionalParams[1];
        const hand = positionalParams[2];
        let [
            hasMainHandEnchant,
            mainHandExpiration,
            enchantmentId,
            hasOffHandEnchant,
            offHandExpiration,
        ] = GetWeaponEnchantInfo();
        const now = GetTime();
        if (hand == "main" || hand === undefined) {
            if (hasMainHandEnchant && expectedEnchantmentId === enchantmentId) {
                mainHandExpiration = mainHandExpiration / 1000;
                return [now + mainHandExpiration, INFINITY];
            }
        } else if (hand == "offhand" || hand == "off") {
            if (hasOffHandEnchant) {
                offHandExpiration = offHandExpiration / 1000;
                return [now + offHandExpiration, INFINITY];
            }
        }
        return [0, INFINITY];
    };

    /** Get the number of seconds since the enchantment has expired
     */
    private weaponEnchantPresent: ConditionFunction = (positionalParams) => {
        const expectedEnchantmentId = positionalParams[1];
        const hand = positionalParams[2];
        let [
            hasMainHandEnchant,
            mainHandExpiration,
            enchantmentId,
            hasOffHandEnchant,
            offHandExpiration,
        ] = GetWeaponEnchantInfo();
        const now = GetTime();
        if (hand == "main" || hand === undefined) {
            if (hasMainHandEnchant && expectedEnchantmentId === enchantmentId) {
                mainHandExpiration = mainHandExpiration / 1000;
                return [0, now + mainHandExpiration];
            }
        } else if (hand == "offhand" || hand == "off") {
            if (hasOffHandEnchant) {
                offHandExpiration = offHandExpiration / 1000;
                return [0, now + offHandExpiration];
            }
        }
        return [];
    };

    private itemRppm = (
        atTime: number,
        itemId: number | undefined,
        slot: SlotName | undefined
    ): ConditionResult => {
        if (slot) {
            itemId = this.getEquippedItemId(slot);
        }
        if (itemId) {
            const rppm = this.data.getItemInfoProperty(itemId, atTime, "rppm");
            return returnConstant(rppm);
        }
        return [];
    };
}
