local __exports = LibStub:NewLibrary("ovale/Debug", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local AceConfig = LibStub:GetLibrary("AceConfig-3.0", true)
local AceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0", true)
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local LibTextDump = LibStub:GetLibrary("LibTextDump-1.0", true)
local __Options = LibStub:GetLibrary("ovale/Options")
local OvaleOptions = __Options.OvaleOptions
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local MakeString = __Ovale.MakeString
local Ovale = __Ovale.Ovale
local aceTimer = LibStub:GetLibrary("AceTimer-3.0", true)
local format = string.format
local pairs = pairs
local GetTime = GetTime
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local OvaleDebugBase = Ovale:NewModule("OvaleDebug", aceTimer)
local self_traced = false
local self_traceLog = nil
local OVALE_TRACELOG_MAXLINES = 4096
local OvaleDebugClass = __class(OvaleDebugBase, {
    constructor = function(self)
        self.options = {
            name = Ovale:GetName() .. " " .. L["Debug"],
            type = "group",
            args = {
                toggles = {
                    name = L["Options"],
                    type = "group",
                    order = 10,
                    args = {},
                    get = function(info)
                        local value = Ovale.db.global.debug[info[#info]]
                        return (value ~= nil)
                    end
,
                    set = function(info, value)
                        value = value or nil
                        Ovale.db.global.debug[info[#info]] = value
                    end

                },
                trace = {
                    name = L["Trace"],
                    type = "group",
                    order = 20,
                    args = {
                        trace = {
                            order = 10,
                            type = "execute",
                            name = L["Trace"],
                            desc = L["Trace the next frame update."],
                            func = function()
                                self:DoTrace(true)
                            end
                        },
                        traceLog = {
                            order = 20,
                            type = "execute",
                            name = L["Show Trace Log"],
                            func = function()
                                self:DisplayTraceLog()
                            end
                        }
                    }
                }
            }
        }
        self.trace = false
        OvaleDebugBase.constructor(self)
        local actions = {
            debug = {
                name = L["Debug"],
                type = "execute",
                func = function()
                    local appName = self:GetName()
                    AceConfigDialog:SetDefaultSize(appName, 800, 550)
                    AceConfigDialog:Open(appName)
                end
            }
        }
        for k, v in pairs(actions) do
            OvaleOptions.options.args.actions.args[k] = v
        end
        OvaleOptions.defaultDB.global = OvaleOptions.defaultDB.global or {}
        OvaleOptions.defaultDB.global.debug = {}
        OvaleOptions:RegisterOptions(self)
    end,
    OnInitialize = function(self)
        local appName = self:GetName()
        AceConfig:RegisterOptionsTable(appName, self.options)
        AceConfigDialog:AddToBlizOptions(appName, L["Debug"], Ovale:GetName())
        self_traceLog = LibTextDump:New(Ovale:GetName() .. " - " .. L["Trace Log"], 750, 500)
    end,
    DoTrace = function(self, displayLog)
        self_traceLog:Clear()
        self.trace = true
        DEFAULT_CHAT_FRAME:AddMessage(format("=== Trace @%f", GetTime()))
        if displayLog then
            self:ScheduleTimer("DisplayTraceLog", 0.5)
        end
    end,
    ResetTrace = function(self)
        self.bug = nil
        self.trace = false
        self_traced = false
    end,
    UpdateTrace = function(self)
        if self.trace then
            self_traced = true
        end
        if self.bug then
            self.trace = true
        end
        if self.trace and self_traced then
            self_traced = false
            self.trace = false
        end
    end,
    RegisterDebugging = function(self, addon)
        local debug = self
        return __class(addon, {
            constructor = function(self, args)
                addon.constructor(self, args)
                local name = self:GetName()
                debug.options.args.toggles.args[name] = {
                    name = name,
                    desc = format(L["Enable debugging messages for the %s module."], name),
                    type = "toggle"
                }
            end,
            Debug = function(self, ...)
                local name = self:GetName()
                if Ovale.db.global.debug[name] then
                    DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", name, MakeString(...)))
                end
            end,
            DebugTimestamp = function(self, ...)
                local name = self:GetName()
                if Ovale.db.global.debug[name] then
                    local now = GetTime()
                    local s = format("|cffffff00%f|r %s", now, MakeString(...))
                    DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", name, s))
                end
            end,
            Log = function(self, ...)
                if debug.trace then
                    local N = self_traceLog:Lines()
                    if N < OVALE_TRACELOG_MAXLINES - 1 then
                        self_traceLog:AddLine(MakeString(...))
                    elseif N == OVALE_TRACELOG_MAXLINES - 1 then
                        self_traceLog:AddLine("WARNING: Maximum length of trace log has been reached.")
                    end
                end
            end,
            Error = function(self, ...)
                local s = MakeString(...)
                self:Print("Fatal error: %s", s)
                __exports.OvaleDebug.bug = s
            end,
            Print = function(self, ...)
                local name = self:GetName()
                local s = MakeString(...)
                DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", name, s))
            end,
        })
    end,
    DisplayTraceLog = function(self)
        if self_traceLog:Lines() == 0 then
            self_traceLog:AddLine("Trace log is empty.")
        end
        self_traceLog:Display()
    end,
})
__exports.OvaleDebug = OvaleDebugClass()
