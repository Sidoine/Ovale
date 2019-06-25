local __exports = LibStub:NewLibrary("ovale/acegui-helpers", 80000)
if not __exports then return end
__exports.AceGUIRegisterAsContainer = function(widget)
    widget.children = {}
    widget.userdata = {}
    widget.events = {}
    widget.content.obj = widget
    widget.frame.obj = widget
    widget:SetLayout("List")
end
__exports.AceGUIRegisterAsWidget = function(widget)
    widget.userdata = {}
    widget.events = {}
    widget.frame.obj = widget
    return widget
end
