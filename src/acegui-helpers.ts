import { LuaArray, LuaObj } from "@wowts/lua";
import { UIFrame } from "@wowts/wow-mock";

export function AceGUIRegisterAsContainer(widget: {
    frame: UIFrame & { obj?: any };
    children?: any;
    userdata?: any;
    events?: any;
    base?: any;
    content: UIFrame & { obj?: any };
    SetLayout(list: string): void;
}) {
    widget.children = {};
    widget.userdata = {};
    widget.events = {};
    // widget.base = WidgetContainerBase
    widget.content.obj = widget;
    widget.frame.obj = widget;
    // widget.content.SetScript("OnSizeChanged", ContentResize)
    // widget.frame.SetScript("OnSizeChanged", FrameResize)
    widget.SetLayout("List");
}

export function AceGUIRegisterAsWidget(widget: {
    frame: UIFrame & { obj?: any };
    userdata?: any;
    events?: any;
    base?: any;
}) {
    widget.userdata = {};
    widget.events = {};
    // widget.base = WidgetBase
    widget.frame.obj = widget;
    // widget.frame.SetScript("OnSizeChanged", FrameResize)
    return widget;
}

interface OptionUiBase {
    name?: string;
    desc?: string;
    order?: number;
    width?: "full";
    inline?: boolean;
    guiHidden?: boolean;
    disabled?: () => boolean;
}

type OptionUiSetter<U, T> = T extends any[]
    ? (info: LuaArray<U>, ...value: T) => void
    : (info: LuaArray<U>, value: T) => void;

interface OptionUiValue<T> extends OptionUiBase {
    get?: (info: LuaArray<string>) => T;
    set?: OptionUiSetter<string, T>;
}

export interface OptionUiExecute extends OptionUiValue<void> {
    type: "execute";
    func: () => void;
}

export interface OptionUiGroup extends OptionUiBase {
    type: "group";
    args: LuaObj<OptionUiAll>;
    get?: (info: LuaArray<any>) => any;
    set?: (info: LuaArray<any>, ...value: any[]) => void;
}

export interface OptionUiInput extends OptionUiValue<string> {
    type: "input";
    multiline?: number;
}

export interface OptionUiToggle extends OptionUiValue<boolean> {
    type: "toggle";
}

export interface OptionUiRange extends OptionUiValue<number> {
    type: "range";
    min: number;
    max: number;
    softMin?: number;
    softMax?: number;
    bigStep?: number;
    step?: number;
    isPercent?: boolean;
}

export interface OptionUiColor
    extends OptionUiValue<[r: number, g: number, b: number]> {
    type: "color";
    hasAlpha?: boolean;
}

export type OptionUiAll =
    | OptionUiGroup
    | OptionUiInput
    | OptionUiExecute
    | OptionUiToggle
    | OptionUiRange
    | OptionUiColor;
