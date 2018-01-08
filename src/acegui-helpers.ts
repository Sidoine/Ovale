import { UIFrame } from "@wowts/wow-mock";


export function AceGUIRegisterAsContainer(widget: { frame: UIFrame & { obj?: any}, children?: any, userdata?: any, events?: any, base?: any, content: UIFrame & {obj?:any}, SetLayout(list:string):void }) {
    widget.children = {}
    widget.userdata = {}
    widget.events = {}
    // widget.base = WidgetContainerBase
    widget.content.obj = widget
    widget.frame.obj = widget
    // widget.content.SetScript("OnSizeChanged", ContentResize)
    // widget.frame.SetScript("OnSizeChanged", FrameResize)
    widget.SetLayout("List")
}

export function AceGUIRegisterAsWidget(widget: { frame: UIFrame & { obj?: any }, userdata?: any, events?: any, base?:any }) {
    widget.userdata = {}
    widget.events = {}
    // widget.base = WidgetBase
    widget.frame.obj = widget
    // widget.frame.SetScript("OnSizeChanged", FrameResize)
    return widget
}