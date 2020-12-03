import { LuaArray, LuaObj, wipe } from "@wowts/lua";
import { insert } from "@wowts/table";
import { AstNode } from "./ast";

export interface CheckBox {
    name: string;
    text?: string;
    defaultValue: boolean;
    triggerEvaluation?: boolean;
    enabled?: AstNode;
}

interface ListItem {
    name: string;
    text: string;
    enabled?: AstNode;
}

interface List {
    name: string;
    items: LuaArray<ListItem>;
    itemsByName: LuaObj<ListItem>;
    defaultValue: string;
    triggerEvaluation?: boolean;
}

export class Controls {
    public checkBoxesByName: LuaObj<CheckBox> = {};
    public checkBoxes: LuaArray<CheckBox> = {};
    public listsByName: LuaObj<List> = {};
    public lists: LuaArray<List> = {};

    addCheckBox(
        name: string,
        text: string,
        defaultValue: boolean,
        enabled?: AstNode
    ) {
        let checkBox = this.checkBoxesByName[name];
        if (!checkBox) {
            checkBox = {
                name: name,
                text: text,
                defaultValue: defaultValue,
                enabled: enabled,
            };
            this.checkBoxesByName[name] = checkBox;
            insert(this.checkBoxes, checkBox);
            return true;
        } else {
            checkBox.text = text;
            checkBox.enabled = enabled;
            checkBox.defaultValue = defaultValue;
            return false;
        }
    }

    addListItem(
        listName: string,
        itemName: string,
        itemText: string,
        defaultValue: boolean,
        enabled?: AstNode
    ) {
        let list = this.listsByName[listName];
        let isNew = false;
        if (!list) {
            list = {
                name: listName,
                items: {},
                itemsByName: {},
                defaultValue: listName,
            };
            this.listsByName[listName] = list;
            insert(this.lists, list);
            isNew = true;
        }
        if (defaultValue) {
            list.defaultValue = listName;
        }

        let item = list.itemsByName[itemName];
        if (!item) {
            item = {
                name: itemName,
                enabled: enabled,
                text: itemText,
            };
            isNew = true;
            list.itemsByName[itemName] = item;
            insert(list.items, item);
        } else {
            item.text = itemText;
            item.enabled = enabled;
        }

        return isNew;
    }

    reset() {
        wipe(this.checkBoxesByName);
        wipe(this.checkBoxes);
        wipe(this.listsByName);
        wipe(this.lists);
    }
}
