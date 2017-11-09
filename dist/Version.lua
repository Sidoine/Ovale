local __exports = LibStub:NewLibrary("ovale/Version", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Options = LibStub:GetLibrary("ovale/Options")
local OvaleOptions = __Options.OvaleOptions
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local AceComm = LibStub:GetLibrary("AceComm-3.0", true)
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0", true)
local AceTimer = LibStub:GetLibrary("AceTimer-3.0", true)
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
local OvaleVersionBase = OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleVersion", AceComm, AceSerializer, AceTimer))
local self_printTable = {}
local self_userVersion = {}
local self_timer
local MSG_PREFIX = Ovale.MSG_PREFIX
local OVALE_VERSION = "@project-version@"
local REPOSITORY_KEYWORD = "@" .. "project-version" .. "@"
do
    local actions = {
        ping = {
            name = L["Ping for Ovale users in group"],
            type = "execute",
            func = function()
                __exports.OvaleVersion:VersionCheck()
            end

        },
        version = {
            name = L["Show version number"],
            type = "execute",
            func = function()
                __exports.OvaleVersion:Print(__exports.OvaleVersion.version)
            end

        }
    }
    for k, v in pairs(actions) do
        OvaleOptions.options.args.actions.args[k] = v
    end
    OvaleOptions:RegisterOptions(__exports.OvaleVersion)
end
local OvaleVersionClass = __class(OvaleVersionBase, {
    constructor = function(self)
        self.version = (OVALE_VERSION == REPOSITORY_KEYWORD) and "development version" or OVALE_VERSION
        self.warned = false
        OvaleVersionBase.constructor(self)
        self:RegisterComm(MSG_PREFIX)
    end,
    OnCommReceived = function(self, prefix, message, channel, sender)
        if prefix == MSG_PREFIX then
            local ok, msgType, version = self:Deserialize(message)
            if ok then
                self:Debug(msgType, version, channel, sender)
                if msgType == "V" then
                    local msg = self:Serialize("VR", self.version)
                    self:SendCommMessage(MSG_PREFIX, msg, channel)
                elseif msgType == "VR" then
                    self_userVersion[sender] = version
                end
            end
        end
    end,
    VersionCheck = function(self)
        if  not self_timer then
            wipe(self_userVersion)
            local message = self:Serialize("V", self.version)
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
                self:SendCommMessage(MSG_PREFIX, message, channel)
            end
            self_timer = self:ScheduleTimer("PrintVersionCheck", 3)
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
                self:Print(v)
            end
        else
            self:Print(">>> No other Ovale users present.")
        end
        self_timer = nil
    end,
})
__exports.OvaleVersion = OvaleVersionClass()
