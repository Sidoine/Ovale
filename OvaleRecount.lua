--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2009 Sidoine

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

local _, Ovale = ...
local OvaleRecount = Ovale:NewModule("OvaleRecount", "AceEvent-3.0")
Ovale.OvaleRecount = OvaleRecount

--<private-static-properties>
local Recount = LibStub("AceAddon-3.0"):GetAddon("Recount", true)
local L = LibStub("AceLocale-3.0"):GetLocale("Recount", true)
if not L then
	L = setmetatable({}, { __index = function(t, k) t[k] = k; return k; end })
end

local strsplit = string.split
local API_RegisterAddonMessagePrefix = RegisterAddonMessagePrefix
--</private-static-properties>

--<private-static-methods>
local function DataModes(self, data, num)
	if not data then
		return 0, 0
	end
	local fight = data.Fights[Recount.db.profile.CurDataSet]
	local score
	if fight and fight.Ovale and fight.OvaleMax then
		score = fight.Ovale * 1000 / fight.OvaleMax
	else
		score = 0
	end
	if num == 1 then
		return score
	end
	return score, nil
end

local function TooltipFuncs(self, name, data)
	local SortedData, total
	GameTooltip:ClearLines()
	GameTooltip:AddLine(name)
	-- Recount:AddSortedTooltipData(L["Top 3"].." Ovale",data and data.Fights[Recount.db.profile.CurDataSet] and data.Fights[Recount.db.profile.CurDataSet].Ovale,3)
	-- GameTooltip:AddLine("<"..L["Click for more Details"]..">",0,0.9,0)
end
--</private-static-methods>

--<public-static-methods>
function OvaleRecount:OnInitialize()
	if not Recount then return end
	Recount:AddModeTooltip("Ovale", DataModes, TooltipFuncs, nil, nil, nil, nil)
end

function OvaleRecount:OnEnable()
	if not Recount then return end
	self:RegisterEvent("CHAT_MSG_ADDON")
	API_RegisterAddonMessagePrefix("Ovale")
end

function OvaleRecount:OnDisable()
	if not Recount then return end
	self:UnregisterEvent("CHAT_MSG_ADDON")
end

function OvaleRecount:CHAT_MSG_ADDON(event, ...)
	local prefix, message, channel, sender = ...
	if prefix ~= "Ovale" then return end
	if channel ~= "RAID" and channel ~= "PARTY" then return end

	local scored, scoreMax, guid = strsplit(";", message)
	local source = Recount.db2.combatants[sender]
	if source then
		Recount:AddAmount(source, "Ovale", scored)
		Recount:AddAmount(source, "OvaleMax", scoreMax)
	end
end
--</public-static-methods>
