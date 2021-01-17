import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    pairs,
    wipe,
    lualength,
    LuaArray,
    ipairs,
    kpairs,
    LuaObj,
    type,
} from "@wowts/lua";
import { sub } from "@wowts/string";
import {
    GetInventoryItemID,
    GetInventoryItemLink,
    GetItemStats,
    GetItemInfoInstant,
    INVSLOT_FIRST_EQUIPPED,
    INVSLOT_LAST_EQUIPPED,
    GetItemCooldown,
    GetWeaponEnchantInfo,
    GetTime,
    INVSLOT_AMMO,
    INVSLOT_HEAD,
    INVSLOT_NECK,
    INVSLOT_BODY,
    INVSLOT_LEGS,
    INVSLOT_FEET,
    INVSLOT_HAND,
    INVSLOT_FINGER1,
    INVSLOT_TRINKET1,
    INVSLOT_BACK,
    INVSLOT_OFFHAND,
    INVSLOT_MAINHAND,
    INVSLOT_TABARD,
    INVSLOT_FINGER2,
    INVSLOT_TRINKET2,
    INVSLOT_WRIST,
    INVSLOT_WAIST,
    INVSLOT_CHEST,
    INVSLOT_SHOULDER,
} from "@wowts/wow-mock";
import { concat, insert } from "@wowts/table";
import { isNumber, KeyCheck } from "../tools/tools";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { OvaleDebugClass } from "../engine/debug";
import { Profiler, OvaleProfilerClass } from "../engine/profiler";
import { OptionUiAll } from "../ui/acegui-helpers";
import {
    ConditionFunction,
    ConditionResult,
    OvaleConditionClass,
    ParameterInfo,
    ReturnBoolean,
    ReturnConstant,
    ReturnValueBetween,
} from "../engine/condition";
import { OvaleDataClass } from "../engine/data";
import { huge } from "@wowts/math";
import { AstFunctionNode, NamedParametersOf } from "../engine/ast";

const OVALE_SLOTID_BY_SLOTNAME = {
    ammoslot: INVSLOT_AMMO,
    headslot: INVSLOT_HEAD,
    neckslot: INVSLOT_NECK,
    shoulderslot: INVSLOT_SHOULDER,
    shirtslot: INVSLOT_BODY,
    chestslot: INVSLOT_CHEST,
    waistslot: INVSLOT_WAIST,
    legsslot: INVSLOT_LEGS,
    feetslot: INVSLOT_FEET,
    wristslot: INVSLOT_WRIST,
    handsslot: INVSLOT_HAND,
    finger0slot: INVSLOT_FINGER1,
    finger1slot: INVSLOT_FINGER2,
    trinket0slot: INVSLOT_TRINKET1,
    trinket1slot: INVSLOT_TRINKET2,
    backslot: INVSLOT_BACK,
    mainhandslot: INVSLOT_MAINHAND,
    secondaryhandslot: INVSLOT_OFFHAND,
    tabardslot: INVSLOT_TABARD,
};
export type SlotName = keyof typeof OVALE_SLOTID_BY_SLOTNAME;
const OVALE_SLOTNAME_BY_SLOTID: LuaArray<SlotName> = {};

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
    secondaryhandslot: true,
    shirtslot: true,
    shoulderslot: true,
    tabardslot: true,
    trinket0slot: true,
    trinket1slot: true,
    waistslot: true,
    wristslot: true,
};

type WeaponType =
    | "INVTYPE_WEAPON"
    | "INVTYPE_WEAPONOFFHAND"
    | "INVTYPE_WEAPONMAINHAND"
    | "INVTYPE_2HWEAPON"
    | "INVTYPE_SHIELD"
    | "INVTYPE_RANGEDRIGHT"
    | "INVTYPE_RANGED";
type WeaponMap = { [key in WeaponType]?: boolean };

const OVALE_ONE_HANDED_WEAPON: WeaponMap = {
    INVTYPE_WEAPON: true,
    INVTYPE_WEAPONOFFHAND: true,
    INVTYPE_WEAPONMAINHAND: true,
};

const OVALE_RANGED_WEAPON: WeaponMap = {
    INVTYPE_RANGEDRIGHT: true,
    INVTYPE_RANGED: true,
};

export class OvaleEquipmentClass {
    ready = false;
    equippedItemById: LuaArray<number> = {};
    equippedItemBySlot: LuaObj<number> = {};
    equippedItemBySharedCooldown: LuaObj<number> = {};
    // equippedItemLevels = {}
    mainHandItemType?: WeaponType;
    offHandItemType?: WeaponType;
    mainHandDPS = 0;
    offHandDPS = 0;
    armorSetCount = {};
    // mainHandWeaponSpeed = 0;
    // offHandWeaponSpeed = 0;
    lastChangedSlot?: number = undefined;
    output: LuaArray<string> = {};

    debugOptions: LuaObj<OptionUiAll> = {
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
                    },
                },
            },
        },
    };
    private module: AceModule & AceEvent;
    private profiler: Profiler;

    constructor(
        private ovale: OvaleClass,
        ovaleDebug: OvaleDebugClass,
        ovaleProfiler: OvaleProfilerClass,
        private OvaleData: OvaleDataClass
    ) {
        this.module = ovale.createModule(
            "OvaleEquipment",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
        this.profiler = ovaleProfiler.create(this.module.GetName());
        for (const [k, v] of pairs(this.debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }
        for (const [slotName, invSlotId] of kpairs(OVALE_SLOTID_BY_SLOTNAME)) {
            OVALE_SLOTNAME_BY_SLOTID[invSlotId] = slotName;
        }
    }

    registerConditions(ovaleCondition: OvaleConditionClass) {
        ovaleCondition.RegisterCondition(
            "hasequippeditem",
            false,
            this.hasEquippedItem
        );
        ovaleCondition.RegisterCondition("hasshield", false, this.hasShield);
        ovaleCondition.RegisterCondition("hastrinket", false, this.hasTrinket);
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
            this.ItemCooldown,
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
        ovaleCondition.RegisterCondition(
            "weaponenchantexpires",
            false,
            this.WeaponEnchantExpires
        );
        ovaleCondition.RegisterCondition(
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

    private OnInitialize = () => {
        this.module.RegisterEvent(
            "PLAYER_ENTERING_WORLD",
            this.UpdateEquippedItems
        );
        this.module.RegisterEvent(
            "PLAYER_EQUIPMENT_CHANGED",
            this.PLAYER_EQUIPMENT_CHANGED
        );
    };
    private OnDisable = () => {
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
    };

    private PLAYER_EQUIPMENT_CHANGED = (
        event: string,
        slotId: number,
        hasItem: number
    ) => {
        this.profiler.StartProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED");
        const changed = this.UpdateItemBySlot(slotId);
        if (changed) {
            this.lastChangedSlot = slotId;
            //this.UpdateArmorSetCount();
            this.ovale.needRefresh();
            this.module.SendMessage("Ovale_EquipmentChanged");
        }
        this.profiler.StopProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED");
    };
    // Armor sets are retiring after Legion; for now, return 0
    GetArmorSetCount(name: string) {
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
    GetEquippedItemBySlotName(slotName: SlotName): number | undefined {
        if (slotName) {
            const slotId = OVALE_SLOTID_BY_SLOTNAME[slotName];
            if (slotId != undefined) {
                return this.equippedItemBySlot[
                    OVALE_SLOTID_BY_SLOTNAME[slotName]
                ];
            }
        }
        return undefined;
    }

    getEquippedItemBySharedCooldown(
        sharedCooldown: string
    ): number | undefined {
        return this.equippedItemBySharedCooldown[sharedCooldown];
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
        return [
            this.equippedItemBySlot[OVALE_SLOTID_BY_SLOTNAME["trinket0slot"]],
            this.equippedItemBySlot[OVALE_SLOTID_BY_SLOTNAME["trinket1slot"]],
        ];
    }
    HasEquippedItem(itemId: number) {
        return (this.equippedItemById[itemId] && true) || false;
    }
    HasMainHandWeapon(handedness?: number) {
        if (!this.mainHandItemType) return false;
        if (handedness) {
            if (handedness == 1) {
                return OVALE_ONE_HANDED_WEAPON[this.mainHandItemType];
            } else if (handedness == 2) {
                return this.mainHandItemType == "INVTYPE_2HWEAPON";
            }
        } else {
            return (
                OVALE_ONE_HANDED_WEAPON[this.mainHandItemType] ||
                this.mainHandItemType == "INVTYPE_2HWEAPON"
            );
        }
        return false;
    }
    HasOffHandWeapon(handedness?: number) {
        if (!this.offHandItemType) return false;
        if (handedness) {
            if (handedness == 1) {
                return OVALE_ONE_HANDED_WEAPON[this.offHandItemType];
            } else if (handedness == 2) {
                return this.offHandItemType == "INVTYPE_2HWEAPON";
            }
        } else {
            return (
                OVALE_ONE_HANDED_WEAPON[this.offHandItemType] ||
                this.offHandItemType == "INVTYPE_2HWEAPON"
            );
        }
        return false;
    }
    HasShield() {
        return this.offHandItemType == "INVTYPE_SHIELD";
    }
    HasRangedWeapon() {
        return (
            this.mainHandItemType && OVALE_RANGED_WEAPON[this.mainHandItemType]
        );
    }
    HasTrinket(itemId: number) {
        return this.HasEquippedItem(itemId);
    }
    HasTwoHandedWeapon() {
        return (
            this.mainHandItemType == "INVTYPE_2HWEAPON" ||
            this.offHandItemType == "INVTYPE_2HWEAPON"
        );
    }
    HasOneHandedWeapon(slotId?: number | SlotName) {
        if (slotId && !isNumber(slotId)) {
            slotId = OVALE_SLOTID_BY_SLOTNAME[slotId];
        }
        if (slotId) {
            if (slotId == OVALE_SLOTID_BY_SLOTNAME["mainhandslot"]) {
                return (
                    this.mainHandItemType &&
                    OVALE_ONE_HANDED_WEAPON[this.mainHandItemType]
                );
            } else if (
                slotId == OVALE_SLOTID_BY_SLOTNAME["secondaryhandslot"]
            ) {
                return (
                    this.offHandItemType &&
                    OVALE_ONE_HANDED_WEAPON[this.offHandItemType]
                );
            }
        } else {
            return (
                (this.mainHandItemType &&
                    OVALE_ONE_HANDED_WEAPON[this.mainHandItemType]) ||
                (this.offHandItemType &&
                    OVALE_ONE_HANDED_WEAPON[this.offHandItemType])
            );
        }
        return false;
    }
    UpdateItemBySlot(slotId: number) {
        const prevItemId = this.equippedItemBySlot[slotId];
        if (prevItemId) {
            delete this.equippedItemById[prevItemId];
            //this.equippedItemLevels[prevItemId] = undefined;
        }
        const newItemId = GetInventoryItemID("player", slotId);
        if (newItemId) {
            this.equippedItemById[newItemId] = slotId;
            this.equippedItemBySlot[slotId] = newItemId;
            //this.equippedItemLevels[newItemId] = GetDetailedItemLevelInfo(newItemId);
            if (slotId == OVALE_SLOTID_BY_SLOTNAME["mainhandslot"]) {
                const [itemEquipLoc, dps] = this.UpdateWeapons(
                    slotId,
                    newItemId
                );
                this.mainHandItemType = itemEquipLoc;
                this.mainHandDPS = dps;
            } else if (
                slotId == OVALE_SLOTID_BY_SLOTNAME["secondaryhandslot"]
            ) {
                const [itemEquipLoc, dps] = this.UpdateWeapons(
                    slotId,
                    newItemId
                );
                this.offHandItemType = itemEquipLoc;
                this.offHandDPS = dps;
            }
            const itemInfo = this.OvaleData.itemInfo[newItemId];
            if (itemInfo) {
                if (itemInfo.shared_cd) {
                    this.equippedItemBySharedCooldown[
                        itemInfo.shared_cd
                    ] = newItemId;
                }
            }
        } else {
            delete this.equippedItemBySlot[slotId];

            if (slotId == OVALE_SLOTID_BY_SLOTNAME["mainhandslot"]) {
                this.mainHandItemType = undefined;
                this.mainHandDPS = 0;
            } else if (
                slotId == OVALE_SLOTID_BY_SLOTNAME["secondaryhandslot"]
            ) {
                this.offHandItemType = undefined;
                this.offHandDPS = 0;
            }
        }
        if (prevItemId != newItemId) {
            return true;
        }
        return false;
    }
    UpdateWeapons(slotId: number, itemId: number): [WeaponType, number] {
        const [, , , itemEquipLoc] = GetItemInfoInstant(itemId);
        let dps = 0;
        const itemLink = GetInventoryItemLink("player", slotId);
        if (itemLink) {
            const stats = GetItemStats(itemLink);
            if (stats) {
                dps = stats["ITEM_MOD_DAMAGE_PER_SECOND_SHORT"] || 0;
            }
        }
        return [<WeaponType>itemEquipLoc, dps];
    }
    private UpdateEquippedItems = () => {
        this.profiler.StartProfiling("OvaleEquipment_UpdateEquippedItems");
        let changed = false;
        for (
            let slotId = INVSLOT_FIRST_EQUIPPED;
            slotId <= INVSLOT_LAST_EQUIPPED;
            slotId += 1
        ) {
            if (
                OVALE_SLOTNAME_BY_SLOTID[slotId] &&
                this.UpdateItemBySlot(slotId)
            ) {
                changed = true;
            }
        }
        if (changed) {
            this.ovale.needRefresh();
            this.module.SendMessage("Ovale_EquipmentChanged");
        }
        this.ready = true;
        this.profiler.StopProfiling("OvaleEquipment_UpdateEquippedItems");
    };

    DebugEquipment() {
        wipe(this.output);
        const array: LuaArray<string> = {};
        /*
        for (let slotId = INVSLOT_FIRST_EQUIPPED; slotId <= INVSLOT_LAST_EQUIPPED; slotId += 1) {
            let slot = tostring(OVALE_SLOTNAME_BY_SLOTID[slotId])
            let itemid = this.GetEquippedItem(slotId) != undefined && tostring(this.GetEquippedItem(slotId)) || ''

            tinsert(array, `${slot}: ${itemid}`)
        }*/
        for (const [slotId, slotName] of ipairs(OVALE_SLOTNAME_BY_SLOTID)) {
            const itemId = this.equippedItemBySlot[slotId] || "";
            const shortSlotName = sub(slotName, 1, -5);
            insert(array, `${shortSlotName}: ${itemId}`);
        }
        insert(array, `\n`);
        insert(array, `Main Hand DPS = ${this.mainHandDPS}`);
        if (this.HasOffHandWeapon()) {
            insert(array, `Off hand DPS = ${this.offHandDPS}`);
        }
        /*
        for (const [k, v] of pairs(this.armorSetCount)) {
            tinsert(array, `Player has ${tonumber(v)} piece(s) of ${tostring(k)} armor set.`)
        }
        */
        for (const [, v] of ipairs(array)) {
            this.output[lualength(this.output) + 1] = v;
        }
        return concat(this.output, "\n");
    }

    /**  Test if the player has a particular item equipped.
	 @name HasEquippedItem
	 @paramsig boolean
	 @param item Item to be checked whether it is equipped.
     */
    private hasEquippedItem = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const itemId = positionalParams[1];
        let boolean = false;
        let slotId;
        if (type(itemId) == "number") {
            slotId = this.HasEquippedItem(itemId);
            if (slotId) {
                boolean = true;
            }
        } else if (this.OvaleData.itemList[itemId]) {
            for (const [, v] of pairs(this.OvaleData.itemList[itemId])) {
                slotId = this.HasEquippedItem(v);
                if (slotId) {
                    boolean = true;
                    break;
                }
            }
        }
        return ReturnBoolean(boolean);
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
        const boolean = this.HasShield();
        return ReturnBoolean(boolean);
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
        const trinketId = positionalParams[1];
        let boolean: boolean | undefined = undefined;
        if (type(trinketId) == "number") {
            boolean = this.HasTrinket(trinketId);
        } else if (this.OvaleData.itemList[trinketId]) {
            for (const [, v] of pairs(this.OvaleData.itemList[trinketId])) {
                boolean = this.HasTrinket(v);
                if (boolean) {
                    break;
                }
            }
        }
        return ReturnBoolean(boolean !== undefined);
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
    private ItemCooldown = (
        atTime: number,
        itemId: number | undefined,
        slot: SlotName | undefined,
        sharedCooldown: string | undefined
    ) => {
        if (sharedCooldown) {
            itemId = this.getEquippedItemBySharedCooldown(sharedCooldown);
        }
        if (slot) {
            itemId = this.GetEquippedItemBySlotName(slot);
        }
        if (itemId) {
            const [start, duration] = GetItemCooldown(itemId);
            if (start > 0 && duration > 0) {
                const ending = start + duration;
                return ReturnValueBetween(start, ending, duration, start, -1);
            }
        }
        return ReturnConstant(0);
    };

    private itemCooldownDuration = (
        atTime: number,
        itemId: number | undefined,
        slot: SlotName | undefined
    ) => {
        if (slot !== undefined) {
            itemId = this.GetEquippedItemBySlotName(slot);
        }
        if (!itemId) return ReturnConstant(0);

        let [, duration] = GetItemCooldown(itemId);
        if (duration <= 0) {
            duration =
                (this.OvaleData.GetItemInfoProperty(
                    itemId,
                    atTime,
                    "cd"
                ) as number) || 0;
        }
        return ReturnConstant(duration);
    };

    private itemInSlot = (atTime: number, slot: SlotName) => {
        return ReturnConstant(this.GetEquippedItemBySlotName(slot));
    };

    /** Get the number of seconds since the enchantment has expired
     */
    private WeaponEnchantExpires: ConditionFunction = (
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
                return [now + mainHandExpiration, huge];
            }
        } else if (hand == "offhand" || hand == "off") {
            if (hasOffHandEnchant) {
                offHandExpiration = offHandExpiration / 1000;
                return [now + offHandExpiration, huge];
            }
        }
        return [0, huge];
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
        if (slot) itemId = this.GetEquippedItemBySlotName(slot);
        if (itemId)
            return ReturnConstant(
                this.OvaleData.GetItemInfoProperty(itemId, atTime, "rppm")
            );
        return [];
    };

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
