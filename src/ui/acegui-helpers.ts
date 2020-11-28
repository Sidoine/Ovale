import { LuaArray, LuaObj } from "@wowts/lua";
import { UIFrame } from "@wowts/wow-mock";

interface Widget<T> {
    frame: UIFrame & { obj?: T };
    children?: unknown;
    userdata?: unknown;
    events?: unknown;
    base?: unknown;
    content: UIFrame & { obj?: T };
    SetLayout(list: string): void;
}

export function AceGUIRegisterAsContainer<T extends Widget<U>, U>(
    widget: T & U
) {
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

export function AceGUIRegisterAsWidget<T extends Widget<U>, U>(widget: T & U) {
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

type OptionUiSetter<T> = T extends unknown[]
    ? (info: LuaArray<string>, ...value: T) => void
    : (info: LuaArray<string>, value: T) => void;

interface OptionValueType {
    input: string;
    toggle: boolean;
    range: number;
    color: [r: number, g: number, b: number];
}

type OptionValueTypes = keyof OptionValueType;
export type LuaArrayElement<T> = T extends LuaArray<infer U> ? U : never;

interface OptionUiValue<T extends OptionValueTypes> extends OptionUiBase {
    type: T;
    get?: (info: LuaArray<string>) => OptionValueType[T];
    set?: OptionUiSetter<OptionValueType[T]>;
}

export interface OptionUiExecute extends OptionUiBase {
    type: "execute";
    func: () => void;
}

export interface OptionUiGroup extends OptionUiBase {
    type: "group";
    args: LuaObj<OptionUiAll>;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    get?: (info: LuaArray<any>) => any;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    set?: (info: LuaArray<any>, ...value: any[]) => void;
}

export interface OptionUiInput extends OptionUiValue<"input"> {
    multiline?: number;
}

type OptionUiToggle = OptionUiValue<"toggle">;

export interface OptionUiRange extends OptionUiValue<"range"> {
    min: number;
    max: number;
    softMin?: number;
    softMax?: number;
    bigStep?: number;
    step?: number;
    isPercent?: boolean;
}

export interface OptionUiColor extends OptionUiValue<"color"> {
    hasAlpha?: boolean;
}

export type OptionUiAll =
    | OptionUiGroup
    | OptionUiInput
    | OptionUiExecute
    | OptionUiToggle
    | OptionUiRange
    | OptionUiColor;
