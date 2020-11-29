local __exports = LibStub:NewLibrary("ovale/ui/Version", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/ui/Localization")
local L = __Localization.L
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local MSG_PREFIX = __Ovale.MSG_PREFIX
local aceComm = LibStub:GetLibrary("AceComm-3.0", true)
local aceSerializer = LibStub:GetLibrary("AceSerializer-3.0", true)
local aceTimer = LibStub:GetLibrary("AceTimer-3.0", true)
local format = string.format
local ipairs = ipairs
local next = next
local pairs = pairs
local wipe = wipe
local insert = table.insert
local sort = table.sort
local IsInGroup = IsInGroup
local IsInGuild = IsInGuild
local IsInRaid = IsInRaid
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local self_printTable = {}
local self_userVersion = {}
local self_timer
local OVALE_VERSION = "@project-version@"
local REPOSITORY_KEYWORD = "@" .. "project-version" .. "@"
__exports.OvaleVersionClass = __class(nil, {
    constructor = function(self, ovale, ovaleOptions, ovaleDebug)
        self.version = (OVALE_VERSION == REPOSITORY_KEYWORD and "development version") or OVALE_VERSION
        self.warned = false
        self.handleInitialize = function()
            self.module:RegisterComm(MSG_PREFIX, self.OnCommReceived)
        end
        self.handleDisable = function()
        end
        self.OnCommReceived = function(prefix, message, channel, sender)
            if prefix == MSG_PREFIX then
                local ok, msgType, version = self.module:Deserialize(message)
                if ok then
                    self.tracer:Debug(msgType, version, channel, sender)
                    if msgType == "V" then
                        local msg = self.module:Serialize("VR", self.version)
                        self.module:SendCommMessage(MSG_PREFIX, msg, channel)
                    elseif msgType == "VR" then
                        self_userVersion[sender] = version
                    end
                end
            end
        end
        self.module = ovale:createModule("OvaleVersion", self.handleInitialize, self.handleDisable, aceComm, aceSerializer, aceTimer)
        self.tracer = ovaleDebug:create(self.module:GetName())
        local actions = {
            ping = {
                name = L["Ping for Ovale users in group"],
                type = "execute",
                func = function()
                    self:VersionCheck()
                end
            },
            version = {
                name = L["Show version number"],
                type = "execute",
                func = function()
                    self.tracer:Print(self.version)
                end
            }
        }
        for k, v in pairs(actions) do
            ovaleOptions.actions.args[k] = v
        end
        ovaleOptions:RegisterOptions()
    end,
    VersionCheck = function(self)
        if  not self_timer then
            wipe(self_userVersion)
            local message = self.module:Serialize("V", self.version)
            local channel
            if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
                channel = "INSTANCE_CHAT"
            elseif IsInRaid() then
                channel = "RAID"
            elseif IsInGroup() then
                channel = "PARTY"
            elseif IsInGuild() then
                channel = "GUILD"
            end
            if channel then
                self.module:SendCommMessage(MSG_PREFIX, message, channel)
            end
            self_timer = self.module:ScheduleTimer("PrintVersionCheck", 3)
        end
    end,
    PrintVersionCheck = function(self)
        if next(self_userVersion) then
            wipe(self_printTable)
            for sender, version in pairs(self_userVersion) do
                insert(self_printTable, format(">>> %s is using Ovale %s", sender, version))
            end
            sort(self_printTable)
            for _, v in ipairs(self_printTable) do
                self.tracer:Print(v)
            end
        else
            self.tracer:Print(">>> No other Ovale users present.")
        end
        self_timer = nil
    end,
})
