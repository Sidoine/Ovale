--[[--------------------------------------------------------------------
    Copyright (C) 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]----------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleVersion = Ovale:NewModule("OvaleVersion", "AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0")
Ovale.OvaleVersion = OvaleVersion

--<private-static-properties>
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug
local OvaleOptions = Ovale.OvaleOptions

local format = string.format
local ipairs = ipairs
local next = next
local pairs = pairs
local tinsert = table.insert
local tsort = table.sort
local wipe = wipe
local API_IsInGroup = IsInGroup
local API_IsInGuild = IsInGuild
local API_IsInRaid = IsInRaid
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvaleVersion)

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
			func = function() OvaleVersion:VersionCheck() end,
		},
		version = {
			name = L["Show version number"],
			type = "execute",
			func = function() OvaleVersion:Print(OvaleVersion.version) end,
		},
	}

	-- Insert defaults and options into OvaleOptions.
	for k, v in pairs(actions) do
		OvaleOptions.options.args.actions.args[k] = v
	end
	OvaleOptions:RegisterOptions(OvaleVersion)
end
--</private-static-properties>

--<public-static-properties>
OvaleVersion.version = (OVALE_VERSION == REPOSITORY_KEYWORD) and "development version" or OVALE_VERSION
OvaleVersion.warned = false
--</public-static-properties>

--<public-static-methods>
function OvaleVersion:OnEnable()
	self:RegisterComm(MSG_PREFIX)
end

function OvaleVersion:OnCommReceived(prefix, message, channel, sender)
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
end

function OvaleVersion:VersionCheck()
	if not self_timer then
		wipe(self_userVersion)
		local message = self:Serialize("V", self.version)
		local channel
		if API_IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
			channel = "INSTANCE_CHAT"
		elseif API_IsInRaid() then
			channel = "RAID"
		elseif API_IsInGroup() then
			channel = "PARTY"
		elseif API_IsInGuild() then
			channel = "GUILD"
		end
		if channel then
			self:SendCommMessage(MSG_PREFIX, message, channel)
		end
		self_timer = self:ScheduleTimer("PrintVersionCheck", 3)
	end
end

function OvaleVersion:PrintVersionCheck()
	if next(self_userVersion) then
		wipe(self_printTable)
		for sender, version in pairs(self_userVersion) do
			tinsert(self_printTable, format(">>> %s is using Ovale %s", sender, version))
		end
		tsort(self_printTable)
		for _, v in ipairs(self_printTable) do
			self:Print(v)
		end
	else
		self:Print(">>> No other Ovale users present.")
	end
	self_timer = nil
end
--</public-static-methods>
