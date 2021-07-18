import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import aceTimer, { AceTimer } from "@wowts/ace_timer-3.0";
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

interface ItemInfo {
    exists: boolean;
    guid: string;
    link?: string;
    location?: ItemLocationMixin;
    name?: string;
    quality?: number; // Enum.ItemQuality
    type?: number; // Enum.InventoryType
    // The properties below are populated by parseItemLink().
    id?: number;
    gem: LuaArray<number>;
    bonus: LuaArray<number>;
    modifier: LuaArray<number>;
}

function resetItemInfo(item: ItemInfo) {
    item.exists = false;
    item.guid = "";
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
    private module: AceModule & AceEvent & AceTimer;
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
            aceEvent,
            aceTimer
        );
        this.tracer = ovaleDebug.create("OvaleEquipment");
        this.profiler = ovaleProfiler.create(this.module.GetName());

        for (const [k, v] of pairs(this.debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }

        for (const [slot] of kpairs(inventorySlotNames)) {
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

    private handleInitialize = () => {
        this.module.RegisterEvent("PLAYER_LOGIN", this.handlePlayerLogin);
        this.module.RegisterEvent(
            "PLAYER_ENTERING_WORLD",
            this.updateEquippedItems
        );
        this.module.RegisterEvent(
            "PLAYER_EQUIPMENT_CHANGED",
            this.handlePlayerEquipmentChanged
        );
    };
    private handleDisable = () => {
        this.module.UnregisterEvent("PLAYER_LOGIN");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
    };

    private handlePlayerLogin = (event: string) => {
        /* Update all equipped items at 3 seconds after player login.
           This is to workaround a delay in the item information being
           available to the game client.
		 */
        this.module.ScheduleTimer(this.updateEquippedItems, 3);
    };

    private handlePlayerEquipmentChanged = (
        event: string,
        slotId: number,
        hasCurrent: boolean
    ) => {
        this.profiler.startProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED");
        const slot = slotNameById[slotId];
        const changed = this.updateEquippedItem(slot);
        if (changed) {
            //this.UpdateArmorSetCount();
            this.ovale.needRefresh();
            this.module.SendMessage("Ovale_EquipmentChanged", slot);
        }
        this.profiler.stopProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED");
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

    getEquippedItemId(slot: InventorySlotName): number | undefined {
        const item = this.equippedItem[slot];
        return (item.exists && item.id) || undefined;
    }

    getEquippedItemIdBySharedCooldown(
        sharedCooldown: string
    ): number | undefined {
        return this.equippedItemBySharedCooldown[sharedCooldown];
    }

    getEquippedItemLocation(
        slot: InventorySlotName
    ): ItemLocationMixin | undefined {
        const item = this.equippedItem[slot];
        return (item.exists && item.location) || undefined;
    }

    getEquippedItemQuality(slot: InventorySlotName): number | undefined {
        const item = this.equippedItem[slot];
        return (item.exists && item.quality) || undefined;
    }

    getEquippedItemBonusIds(slot: InventorySlotName): LuaArray<number> {
        // Returns the array of bonus IDs for the slot.
        const item = this.equippedItem[slot];
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
                    let gem = item.gem || {};
                    insert(gem, token);
                    item.gem = gem;
                }
            } else if (index == 13) {
                numBonus = token;
            } else if (index > 13 && index <= 13 + numBonus) {
                let bonus = item.bonus || {};
                insert(bonus, token);
                item.bonus = bonus;
            } else if (index == 13 + numBonus + 1) {
                numModifiers = token;
            } else if (
                index > 13 + numBonus + 1 &&
                index <= 13 + numBonus + 1 + numModifiers
            ) {
                let modifier = item.modifier || {};
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

    private updateEquippedItem = (slot: InventorySlotName): boolean => {
        this.tracer.debug(`Updating slot ${slot}`);
        let item = this.equippedItem[slot];
        const prevGUID = item.guid;
        const prevItemId = item.id;
        if (prevItemId != undefined) {
            delete this.isEquippedItemById[prevItemId];
        }
        resetItemInfo(item);
        const slotId = slotIdByName[slot];
        const location = ItemLocation.CreateFromEquipmentSlot(slotId);
        const exists = C_Item.DoesItemExist(location);
        if (exists) {
            item.exists = true;
            item.guid = C_Item.GetItemGUID(location);
            item.location = location;
            item.name = C_Item.GetItemName(location);
            item.quality = C_Item.GetItemQuality(location);
            item.type = C_Item.GetItemInventoryType(location);
            const link = C_Item.GetItemLink(location);
            if (link != undefined) {
                item.link = link;
                this.parseItemLink(link, item);
                const id = item.id;
                if (id != undefined) {
                    this.isEquippedItemById[id] = true;
                    const info = this.data.itemInfo[id];
                    if (info != undefined && info.shared_cd != undefined) {
                        this.equippedItemBySharedCooldown[info.shared_cd] = id;
                    }
                }
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
        }
        return prevGUID != item.guid;
    };

    private updateEquippedItems = () => {
        this.profiler.startProfiling("OvaleEquipment_UpdateEquippedItems");
        let anyChanged = false;
        for (const [slot] of kpairs(inventorySlotNames)) {
            const changed = this.updateEquippedItem(slot);
            anyChanged = anyChanged || changed;
        }
        if (anyChanged) {
            this.ovale.needRefresh();
            this.module.SendMessage("Ovale_EquipmentChanged");
        }
        this.profiler.stopProfiling("OvaleEquipment_UpdateEquippedItems");
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

    // CONDITIONS:

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
            const invSlot = slotNameByName[slot];
            itemId = this.getEquippedItemId(invSlot);
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
            const invSlot = slotNameByName[slot];
            itemId = this.getEquippedItemId(invSlot);
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
        const invSlot = slotNameByName[slot];
        const itemId = this.getEquippedItemId(invSlot);
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
            const invSlot = slotNameByName[slot];
            itemId = this.getEquippedItemId(invSlot);
        }
        if (itemId) {
            const rppm = this.data.getItemInfoProperty(itemId, atTime, "rppm");
            return returnConstant(rppm);
        }
        return [];
    };
}
