import { LuaObj, wipe } from "@wowts/lua";
import { AstNode } from "./AST";

export interface CheckBox {
    text?: string;
    checked: boolean;
    triggerEvaluation?: boolean;
    enabled?: AstNode;
}
export const checkBoxes: LuaObj<CheckBox> = {};

type ListItem = string;

interface List {
    items: LuaObj<ListItem>;
    default: string;
    triggerEvaluation?: boolean;
    enabled?: AstNode;
}
export const lists: LuaObj<List> = {};

export function ResetControls() {
    wipe(checkBoxes);
    wipe(lists);
}
