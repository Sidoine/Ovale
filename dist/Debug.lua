local __exports = LibStub:NewLibrary("ovale/Debug", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local AceConfig = LibStub:GetLibrary("AceConfig-3.0", true)
local AceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0", true)
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local LibTextDump = LibStub:GetLibrary("LibTextDump-1.0", true)
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local MakeString = __Ovale.MakeString
local aceTimer = LibStub:GetLibrary("AceTimer-3.0", true)
local format = string.format
local pairs = pairs
local GetTime = GetTime
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local OVALE_TRACELOG_MAXLINES = 4096
__exports.Tracer = __class(nil, {
    constructor = function(self, options, debug, name)
        self.options = options
        self.debug = debug
        self.name = name
        debug.defaultOptions.args.toggles.args[name] = {
            name = name,
            desc = format(L["Enable debugging messages for the %s module."], name),
            type = "toggle"
        }
    end,
    Debug = function(self, ...)
        local name = self.name
        if self.options.db.global.debug[name] then
            DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", name, MakeString(...)))
        end
    end,
    DebugTimestamp = function(self, ...)
        local name = self.name
        if self.options.db.global.debug[name] then
            local now = GetTime()
            local s = format("|cffffff00%f|r %s", now, MakeString(...))
            DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", name, s))
        end
    end,
    Log = function(self, ...)
        if self.debug.trace then
            local N = self.debug.traceLog:Lines()
            if N < OVALE_TRACELOG_MAXLINES - 1 then
                self.debug.traceLog:AddLine(MakeString(...))
            elseif N == OVALE_TRACELOG_MAXLINES - 1 then
                self.debug.traceLog:AddLine("WARNING: Maximum length of trace log has been reached.")
            end
        end
    end,
    Error = function(self, ...)
        local name = self.name
        local s = MakeString(...)
        DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r:|cffff3333 Error:|r %s", name, s))
        self.debug.bug = s
    end,
    Warning = function(self, ...)
        local name = self.name
        local s = MakeString(...)
        DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: |cff999933Warning:|r %s", name, s))
        self.debug.warning = s
    end,
    Print = function(self, ...)
        local name = self.name
        local s = MakeString(...)
        DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", name, s))
    end,
})
__exports.OvaleDebugClass = __class(nil, {
    constructor = function(self, ovale, options)
        self.ovale = ovale
        self.options = options
        self.self_traced = false
        self.defaultOptions = {
            name = "Ovale " .. L["Debug"],
            type = "group",
            args = {
                toggles = {
                    name = L["Options"],
                    type = "group",
                    order = 10,
                    args = {},
                    get = function(info)
                        local value = self.options.db.global.debug[info[#info]]
                        return (value ~= nil)
                    end,
                    set = function(info, value)
                        value = value or nil
                        self.options.db.global.debug[info[#info]] = value
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
        self.traceLog = nil
        self.trace = false
        self.OnInitialize = function()
            local appName = self.module:GetName()
            AceConfig:RegisterOptionsTable(appName, self.defaultOptions)
            AceConfigDialog:AddToBlizOptions(appName, L["Debug"], self.ovale:GetName())
            self.traceLog = LibTextDump:New(self.ovale:GetName() .. " - " .. L["Trace Log"], 750, 500)
        end
        self.OnDisable = function()
        end
        self.module = ovale:createModule("OvaleDebug", self.OnInitialize, self.OnDisable, aceTimer)
        local actions = {
            debug = {
                name = L["Debug"],
                type = "execute",
                func = function()
                    local appName = self.module:GetName()
                    AceConfigDialog:SetDefaultSize(appName, 800, 550)
                    AceConfigDialog:Open(appName)
                end
            }
        }
        for k, v in pairs(actions) do
            options.options.args.actions.args[k] = v
        end
        options.defaultDB.global = options.defaultDB.global or {}
        options.defaultDB.global.debug = {}
        options:RegisterOptions(self)
    end,
    create = function(self, name)
        return __exports.Tracer(self.options, self, name)
    end,
    DoTrace = function(self, displayLog)
        self.traceLog:Clear()
        self.trace = true
        DEFAULT_CHAT_FRAME:AddMessage(format("=== Trace @%f", GetTime()))
        if displayLog then
            self.module:ScheduleTimer(function()
                self:DisplayTraceLog()
            end, 0.5)
        end
    end,
    ResetTrace = function(self)
        self.bug = nil
        self.trace = false
        self.self_traced = false
    end,
    UpdateTrace = function(self)
        if self.trace then
            self.self_traced = true
        end
        if self.bug then
            self.trace = true
        end
        if self.trace and self.self_traced then
            self.self_traced = false
            self.trace = false
        end
    end,
    DisplayTraceLog = function(self)
        if self.traceLog:Lines() == 0 then
            self.traceLog:AddLine("Trace log is empty.")
        end
        self.traceLog:Display()
    end,
})
