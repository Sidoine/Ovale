local __exports = LibStub:NewLibrary("ovale/Ovale", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local __tsaddon = LibStub:GetLibrary("tsaddon", true)
local NewAddon = __tsaddon.NewAddon
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ipairs = ipairs
local pairs = pairs
local strjoin = strjoin
local tostring = tostring
local tostringall = tostringall
local wipe = wipe
local _G = _G
local format = string.format
local find = string.find
local len = string.len
local UnitClass = UnitClass
local UnitGUID = UnitGUID
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local huge = math.huge
__exports.oneTimeMessages = {}
local MAX_REFRESH_INTERVALS = 500
local self_refreshIntervals = {}
local self_refreshIndex = 1
__exports.MakeString = function(s, ...)
    if s and len(s) > 0 then
        if ... then
            if find(s, "%%%.%d") or find(s, "%%[%w]") then
                s = format(s, tostringall(...))
            else
                s = strjoin(" ", s, tostringall(...))
            end
        end
    else
        s = tostring(nil)
    end
    return s
end
local name = "Ovale"
local OvaleBase = NewAddon(name, aceEvent)
__exports.MSG_PREFIX = name
__exports.Print = function(...)
    local s = __exports.MakeString(...)
    DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", name, s))
end
__exports.OvaleClass = __class(OvaleBase, {
    constructor = function(self)
        self.playerClass = "WARRIOR"
        self.playerGUID = ""
        self.refreshNeeded = {}
        OvaleBase.constructor(self)
        _G["BINDING_HEADER_OVALE"] = "Ovale"
        local toggleCheckBox = L["Inverser la boîte à cocher "]
        _G["BINDING_NAME_OVALE_CHECKBOX0"] = toggleCheckBox .. "(1)"
        _G["BINDING_NAME_OVALE_CHECKBOX1"] = toggleCheckBox .. "(2)"
        _G["BINDING_NAME_OVALE_CHECKBOX2"] = toggleCheckBox .. "(3)"
        _G["BINDING_NAME_OVALE_CHECKBOX3"] = toggleCheckBox .. "(4)"
        _G["BINDING_NAME_OVALE_CHECKBOX4"] = toggleCheckBox .. "(5)"
    end,
    OnInitialize = function(self)
        self.playerGUID = UnitGUID("player")
        local _, classId = UnitClass("player")
        self.playerClass = classId
        wipe(self_refreshIntervals)
        self_refreshIndex = 1
        self:ClearOneTimeMessages()
    end,
    needRefresh = function(self)
        if self.playerGUID then
            self.refreshNeeded[self.playerGUID] = true
        end
    end,
    AddRefreshInterval = function(self, milliseconds)
        if milliseconds < huge then
            self_refreshIntervals[self_refreshIndex] = milliseconds
            self_refreshIndex = (self_refreshIndex < MAX_REFRESH_INTERVALS) and (self_refreshIndex + 1) or 1
        end
    end,
    GetRefreshIntervalStatistics = function(self)
        local sumRefresh, minRefresh, maxRefresh, count = 0, huge, 0, 0
        for _, v in ipairs(self_refreshIntervals) do
            if v > 0 then
                if minRefresh > v then
                    minRefresh = v
                end
                if maxRefresh < v then
                    maxRefresh = v
                end
                sumRefresh = sumRefresh + v
                count = count + 1
            end
        end
        local avgRefresh = (count > 0) and (sumRefresh / count) or 0
        return avgRefresh, minRefresh, maxRefresh, count
    end,
    OneTimeMessage = function(self, ...)
        local s = __exports.MakeString(...)
        if  not __exports.oneTimeMessages[s] then
            __exports.oneTimeMessages[s] = true
        end
    end,
    ClearOneTimeMessages = function(self)
        wipe(__exports.oneTimeMessages)
    end,
    PrintOneTimeMessages = function(self)
        for s in pairs(__exports.oneTimeMessages) do
            if __exports.oneTimeMessages[s] ~= "printed" then
                __exports.Print(s)
                __exports.oneTimeMessages[s] = "printed"
            end
        end
    end,
    createModule = function(self, name, onInitialize, onRelease)
    end,
    createModule = function(self, name, onInitialize, onRelease, dep1)
    end,
    createModule = function(self, name, onInitialize, onRelease, dep1, dep2)
    end,
    createModule = function(self, name, onInitialize, onRelease, dep1, dep2, dep3)
    end,
    createModule = function(self, name, onInitialize, onRelease, dep1, dep2, dep3, dep4)
    end,
    createModule = function(self, name, onInitialize, onRelease, dep1, dep2, dep3, dep4)
        local ret = (self:NewModule(name, dep1, dep2, dep3, dep4))()
        ret.OnInitialize = onInitialize
        return ret
    end,
})
