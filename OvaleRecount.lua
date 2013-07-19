--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2009 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleRecount = Ovale:NewModule("OvaleRecount")
Ovale.OvaleRecount = OvaleRecount

--<private-static-properties>
local Recount = LibStub("AceAddon-3.0"):GetAddon("Recount", true)
local L = LibStub("AceLocale-3.0"):GetLocale("Recount", true)
if not L then
	L = setmetatable({}, { __index = function(t, k) t[k] = k; return k; end })
end
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
	if Recount then
		Recount:AddModeTooltip("Ovale", DataModes, TooltipFuncs, nil, nil, nil, nil)
	end
end

function OvaleRecount:OnEnable()
	if Recount then
		Ovale:RegisterDamageMeter("OvaleRecount", "ReceiveScore")
	end
end

function OvaleRecount:OnDisable()
	if Recount then
		Ovale:UnregisterDamageMeter("OvaleRecount")
	end
end

function OvaleRecount:ReceiveScore(name, guid, scored, scoreMax)
	if Recount then
		local source = Recount.db2.combatants[name]
		if source then
			Recount:AddAmount(source, "Ovale", scored)
			Recount:AddAmount(source, "OvaleMax", scoreMax)
		end
	end
end
--</public-static-methods>
