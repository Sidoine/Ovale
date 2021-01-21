import { LuaArray, LuaObj } from "@wowts/lua";
import { CreateFrame, UIFrame } from "@wowts/wow-mock";
import AceGUI, { AceGUIWidgetBase } from "@wowts/ace_gui-3.0";

export class Widget<T extends UIFrame> extends AceGUI.WidgetBase {
    userdata: LuaObj<unknown> = {};
    events: LuaObj<unknown> = {};
    base = AceGUI.WidgetBase;
    frame: T & { obj?: Widget<T> };

    // eslint-disable-next-line @typescript-eslint/naming-convention
    protected OnWidthSet?: (width: number) => void;
    // eslint-disable-next-line @typescript-eslint/naming-convention
    protected OnHeightSet?: (height: number) => void;

    constructor(frame: T) {
        super();
        this.frame = frame;
        this.frame.obj = this;
        this.frame.SetScript("OnSizeChanged", this.handleFrameResize);
    }

    private handleFrameResize = () => {
        if (this.frame.GetWidth() && this.frame.GetHeight()) {
            if (this.OnWidthSet) this.OnWidthSet(this.frame.GetWidth());
            if (this.OnHeightSet) this.OnHeightSet(this.frame.GetHeight());
        }
    };
}

export class WidgetContainer<
    T extends UIFrame
> extends AceGUI.WidgetContainerBase {
    children: LuaArray<AceGUIWidgetBase> = {};
    userdata: LuaObj<unknown> = {};
    events: LuaObj<unknown> = {};

    /** Where the child frames are placed */
    content: UIFrame & { obj?: WidgetContainer<T> };
    frame: T & { obj?: WidgetContainer<T> };
    base = AceGUI.WidgetContainerBase;
    width = 0;
    height = 0;

    // eslint-disable-next-line @typescript-eslint/naming-convention
    protected OnWidthSet?: (width: number) => void;
    // eslint-disable-next-line @typescript-eslint/naming-convention
    protected OnHeightSet?: (height: number) => void;

    constructor(frame: T) {
        super();
        const content = CreateFrame("Frame", undefined, frame);
        content.SetScript("OnSizeChanged", this.handleContentResize);
        frame.SetScript("OnSizeChanged", this.handleFrameResize);
        this.content = content;
        this.content.obj = this;
        this.frame = frame;
        this.frame.obj = this;
        this.SetLayout("List");
    }

    private handleFrameResize = () => {
        if (this.frame.GetWidth() && this.frame.GetHeight()) {
            if (this.OnWidthSet) this.OnWidthSet(this.frame.GetWidth());
            if (this.OnHeightSet) this.OnHeightSet(this.frame.GetHeight());
        }
    };

    private handleContentResize = () => {
        if (this.content.GetWidth() && this.content.GetHeight()) {
            this.width = this.content.GetWidth();
            this.height = this.content.GetHeight();
            this.DoLayout();
        }
    };
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
