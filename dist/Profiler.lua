local __exports = LibStub:NewLibrary("ovale/Profiler", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local AceConfig = LibStub:GetLibrary("AceConfig-3.0", true)
local AceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0", true)
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local LibTextDump = LibStub:GetLibrary("LibTextDump-1.0", true)
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Print = __Ovale.Print
local debugprofilestop = debugprofilestop
local GetTime = GetTime
local format = string.format
local pairs = pairs
local next = next
local wipe = wipe
local insert = table.insert
local sort = table.sort
local concat = table.concat
__exports.Profiler = __class(nil, {
    constructor = function(self, name, profiler)
        self.profiler = profiler
        self.timestamp = debugprofilestop()
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
        if self.profiler.stackSize > 0 then
            local delta = newTimestamp - self.timestamp
            local previous = self.profiler.stack[self.profiler.stackSize]
            local timeSpent = self.profiler.timeSpent[previous] or 0
            timeSpent = timeSpent + delta
            self.profiler.timeSpent[previous] = timeSpent
        end
        self.timestamp = newTimestamp
        self.profiler.stackSize = self.profiler.stackSize + 1
        self.profiler.stack[self.profiler.stackSize] = tag
        do
            local timesInvoked = self.profiler.timesInvoked[tag] or 0
            timesInvoked = timesInvoked + 1
            self.profiler.timesInvoked[tag] = timesInvoked
        end
    end,
    StopProfiling = function(self, tag)
        if  not self.enabled then
            return 
        end
        if self.profiler.stackSize > 0 then
            local currentTag = self.profiler.stack[self.profiler.stackSize]
            if currentTag == tag then
                local newTimestamp = debugprofilestop()
                local delta = newTimestamp - self.timestamp
                local timeSpent = self.profiler.timeSpent[currentTag] or 0
                timeSpent = timeSpent + delta
                self.profiler.timeSpent[currentTag] = timeSpent
                self.timestamp = newTimestamp
                self.profiler.stackSize = self.profiler.stackSize - 1
            end
        end
    end,
})
__exports.OvaleProfilerClass = __class(nil, {
    constructor = function(self, ovaleOptions, ovale)
        self.ovaleOptions = ovaleOptions
        self.ovale = ovale
        self.timeSpent = {}
        self.timesInvoked = {}
        self.stack = {}
        self.stackSize = 0
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
                                self.profilingOutput:Clear()
                                local s = self:GetProfilingInfo()
                                if s then
                                    self.profilingOutput:AddLine(s)
                                    self.profilingOutput:Display()
                                end
                            end
                        }
                    }
                }
            }
        }
        self.OnInitialize = function()
            local appName = self.module:GetName()
            AceConfig:RegisterOptionsTable(appName, self.options)
            AceConfigDialog:AddToBlizOptions(appName, L["Profiling"], self.ovale:GetName())
        end
        self.OnDisable = function()
            self.profilingOutput:Clear()
        end
        self.array = {}
        for k, v in pairs(self.actions) do
            ovaleOptions.options.args.actions.args[k] = v
        end
        ovaleOptions.defaultDB.global = ovaleOptions.defaultDB.global or {}
        ovaleOptions.defaultDB.global.profiler = {}
        ovaleOptions:RegisterOptions(__exports.OvaleProfilerClass)
        self.module = ovale:createModule("OvaleProfiler", self.OnInitialize, self.OnDisable)
        self.profilingOutput = LibTextDump:New(self.ovale:GetName() .. " - " .. L["Profiling"], 750, 500)
    end,
    create = function(self, name)
        return __exports.Profiler(name, self)
    end,
    ResetProfiling = function(self)
        for tag in pairs(self.timeSpent) do
            self.timeSpent[tag] = nil
        end
        for tag in pairs(self.timesInvoked) do
            self.timesInvoked[tag] = nil
        end
    end,
    GetProfilingInfo = function(self)
        if next(self.timeSpent) then
            local width = 1
            do
                local tenPower = 10
                for _, timesInvoked in pairs(self.timesInvoked) do
                    while timesInvoked > tenPower do
                        width = width + 1
                        tenPower = tenPower * 10
                    end
                end
            end
            wipe(self.array)
            local formatString = format("    %%08.3fms: %%0%dd (%%05f) x %%s", width)
            for tag, timeSpent in pairs(self.timeSpent) do
                local timesInvoked = self.timesInvoked[tag]
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
        Print("Profiler stack size = %d", self.stackSize)
        local index = self.stackSize
        while index > 0 and self.stackSize - index < 10 do
            local tag = self.stack[index]
            Print("    [%d] %s", index, tag)
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
