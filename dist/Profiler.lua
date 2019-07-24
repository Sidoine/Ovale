local __exports = LibStub:NewLibrary("ovale/Profiler", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local AceConfig = LibStub:GetLibrary("AceConfig-3.0", true)
local AceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0", true)
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local LibTextDump = LibStub:GetLibrary("LibTextDump-1.0", true)
local debugprofilestop = debugprofilestop
local GetTime = GetTime
local format = string.format
local pairs = pairs
local next = next
local wipe = wipe
local insert = table.insert
local sort = table.sort
local concat = table.concat
local self_timestamp = debugprofilestop()
local self_timeSpent = {}
local self_timesInvoked = {}
local self_stack = {}
local self_stackSize = 0
__exports.Profiler = __class(nil, {
    constructor = function(self, name, profiler)
        self.enabled = false
        local args = profiler.options.args.profiling.args.modules.args
        args[name] = {
            name = name,
            desc = format(L["Enable profiling for the %s module."], name),
            type = "toggle"
        }
        profiler.profiles[name] = self
    end,
    StartProfiling = function(self, tag)
        if  not self.enabled then
            return 
        end
        local newTimestamp = debugprofilestop()
        if self_stackSize > 0 then
            local delta = newTimestamp - self_timestamp
            local previous = self_stack[self_stackSize]
            local timeSpent = self_timeSpent[previous] or 0
            timeSpent = timeSpent + delta
            self_timeSpent[previous] = timeSpent
        end
        self_timestamp = newTimestamp
        self_stackSize = self_stackSize + 1
        self_stack[self_stackSize] = tag
        do
            local timesInvoked = self_timesInvoked[tag] or 0
            timesInvoked = timesInvoked + 1
            self_timesInvoked[tag] = timesInvoked
        end
    end,
    StopProfiling = function(self, tag)
        if  not self.enabled then
            return 
        end
        if self_stackSize > 0 then
            local currentTag = self_stack[self_stackSize]
            if currentTag == tag then
                local newTimestamp = debugprofilestop()
                local delta = newTimestamp - self_timestamp
                local timeSpent = self_timeSpent[currentTag] or 0
                timeSpent = timeSpent + delta
                self_timeSpent[currentTag] = timeSpent
                self_timestamp = newTimestamp
                self_stackSize = self_stackSize - 1
            end
        end
    end,
})
__exports.OvaleProfilerClass = __class(nil, {
    constructor = function(self, options, ovale, ovaleOptions)
        self.ovale = ovale
        self.ovaleOptions = ovaleOptions
        self.self_profilingOutput = nil
        self.profiles = {}
        self.actions = {
            profiling = {
                name = L["Profiling"],
                type = "execute",
                func = function()
                    local appName = self.ovale:GetName()
                    AceConfigDialog:SetDefaultSize(appName, 800, 550)
                    AceConfigDialog:Open(appName)
                end
            }
        }
        self.options = {
            name = self.ovale:GetName() .. " " .. L["Profiling"],
            type = "group",
            args = {
                profiling = {
                    name = L["Profiling"],
                    type = "group",
                    args = {
                        modules = {
                            name = L["Modules"],
                            type = "group",
                            inline = true,
                            order = 10,
                            args = {},
                            get = function(info)
                                local name = info[#info]
                                local value = self.ovaleOptions.db.global.profiler[name]
                                return (value ~= nil)
                            end,
                            set = function(info, value)
                                value = value or nil
                                local name = info[#info]
                                self.ovaleOptions.db.global.profiler[name] = value
                                if value then
                                    self:EnableProfiling(name)
                                else
                                    self:DisableProfiling(name)
                                end
                            end
                        },
                        reset = {
                            name = L["Reset"],
                            desc = L["Reset the profiling statistics."],
                            type = "execute",
                            order = 20,
                            func = function()
                                self:ResetProfiling()
                            end
                        },
                        show = {
                            name = L["Show"],
                            desc = L["Show the profiling statistics."],
                            type = "execute",
                            order = 30,
                            func = function()
                                self.self_profilingOutput:Clear()
                                local s = self:GetProfilingInfo()
                                if s then
                                    self.self_profilingOutput:AddLine(s)
                                    self.self_profilingOutput:Display()
                                end
                            end
                        }
                    }
                }
            }
        }
        self.DoNothing = function()
        end

        self.array = {}
        for k, v in pairs(self.actions) do
            options.options.args.actions.args[k] = v
        end
        options.defaultDB.global = options.defaultDB.global or {}
        options.defaultDB.global.profiler = {}
        options:RegisterOptions(__exports.OvaleProfilerClass)
    end,
    OnInitialize = function(self)
        local appName = self.ovale:GetName()
        AceConfig:RegisterOptionsTable(appName, self.options)
        AceConfigDialog:AddToBlizOptions(appName, L["Profiling"], self.ovale:GetName())
        if  not self.self_profilingOutput then
            self.self_profilingOutput = LibTextDump:New(self.ovale:GetName() .. " - " .. L["Profiling"], 750, 500)
        end
    end,
    OnDisable = function(self)
        self.self_profilingOutput:Clear()
    end,
    create = function(self, name)
        return __exports.Profiler(name, self)
    end,
    ResetProfiling = function(self)
        for tag in pairs(self_timeSpent) do
            self_timeSpent[tag] = nil
        end
        for tag in pairs(self_timesInvoked) do
            self_timesInvoked[tag] = nil
        end
    end,
    GetProfilingInfo = function(self)
        if next(self_timeSpent) then
            local width = 1
            do
                local tenPower = 10
                for _, timesInvoked in pairs(self_timesInvoked) do
                    while timesInvoked > tenPower do
                        width = width + 1
                        tenPower = tenPower * 10
                    end
                end
            end
            wipe(self.array)
            local formatString = format("    %%08.3fms: %%0%dd (%%05f) x %%s", width)
            for tag, timeSpent in pairs(self_timeSpent) do
                local timesInvoked = self_timesInvoked[tag]
                insert(self.array, format(formatString, timeSpent, timesInvoked, timeSpent / timesInvoked, tag))
            end
            if next(self.array) then
                sort(self.array)
                local now = GetTime()
                insert(self.array, 1, format("Profiling statistics at %f:", now))
                return concat(self.array, "\n")
            end
        end
    end,
    DebuggingInfo = function(self)
        self.ovale:Print("Profiler stack size = %d", self_stackSize)
        local index = self_stackSize
        while index > 0 and self_stackSize - index < 10 do
            local tag = self_stack[index]
            self.ovale:Print("    [%d] %s", index, tag)
            index = index - 1
        end
    end,
    EnableProfiling = function(self, name)
        self.profiles[name].enabled = true
    end,
    DisableProfiling = function(self, name)
        self.profiles[name].enabled = false
    end,
})
