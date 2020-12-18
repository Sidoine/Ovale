import { getItemProps } from "./ast-helpers";
import { convertFromItemData } from "./customspell";
import { replaceInFile } from "./file-tools";
import { DbcData } from "./importspells";

const enum InventoryType {
    INVTYPE_NON_EQUIP = 0,
    INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2,
    INVTYPE_SHOULDERS = 3,
    INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5,
    INVTYPE_WAIST = 6,
    INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8,
    INVTYPE_WRISTS = 9,
    INVTYPE_HANDS = 10,
    INVTYPE_FINGER = 11,
    INVTYPE_TRINKET = 12,
    INVTYPE_WEAPON = 13,
    INVTYPE_SHIELD = 14,
    INVTYPE_RANGED = 15,
    INVTYPE_CLOAK = 16,
    INVTYPE_2HWEAPON = 17,
    INVTYPE_BAG = 18,
    INVTYPE_TABARD = 19,
    INVTYPE_ROBE = 20,
    INVTYPE_WEAPONMAINHAND = 21,
    INVTYPE_WEAPONOFFHAND = 22,
    INVTYPE_HOLDABLE = 23,
    INVTYPE_AMMO = 24,
    INVTYPE_THROWN = 25,
    INVTYPE_RANGEDRIGHT = 26,
    INVTYPE_QUIVER = 27,
    INVTYPE_RELIC = 28,
    INVTYPE_MAX = 29,
}

export function exportCommon(dbc: DbcData) {
    let lines: string[] = ["let code = `"];
    for (const item of dbc.itemsById.values()) {
        if (
            item.req_level === 60 &&
            item.inventory_type === InventoryType.INVTYPE_TRINKET
        ) {
            const itemData = convertFromItemData(item, dbc.spellDataById);
            const itemInfos = getItemProps(itemData);
            if (itemInfos.length > 0) {
                lines.push(`ItemInfo(${item.id}${itemInfos})`);
            }
        }
    }
    lines.push("`;");

    replaceInFile("src/scripts/ovale_common.ts", lines.join("\n"));
}
