--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2010 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local Skada = LibStub("AceAddon-3.0"):GetAddon("Skada", true)
local OvaleSkada = Skada and Skada:NewModule("Ovale Spell Priority") or {}
Ovale.OvaleSkada = OvaleSkada

--<private-static-properties>
local ipairs = ipairs
local floor = math.floor
local tostring = tostring
--</private-static-properties>

--<public-static-properties>
-- OvaleSkada.metadata = nil
--</public-static-properties>

--<private-static-methods>
local function GetValue(set)
	if set.ovaleMax and set.ovaleMax > 0 then
		return floor(1000 * set.ovale / set.ovaleMax)
	else
		return nil
	end
end

local function ReceiveScore(name, guid, scored, scoreMax)
	local self = OvaleSkada
	if guid and Skada and Skada.current and Skada.total then
		local player = Skada:get_player(Skada.current, guid, nil)
		if player then
			self:AddPlayerAttributes(player)
			player.ovale = player.ovale + scored
			player.ovaleMax = player.ovaleMax + scoreMax
			player = Skada:get_player(Skada.total, guid, nil)
			player.ovale = player.ovale + scored
			player.ovaleMax = player.ovaleMax + scoreMax
		end
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleSkada:OnEnable()
	self.metadata = { showspots = true }
	Skada:AddMode(self)
	Ovale:RegisterDamageMeter("OvaleSkada", ReceiveScore)
end

function OvaleSkada:OnDisable()
	Ovale:UnregisterDamageMeter("OvaleSkada")
	Skada:RemoveMode(self)
end

function OvaleSkada:Update(win, set)
	local max = 0
	local nr = 1

	for i, player in ipairs(set.players) do
		if player.ovaleMax and player.ovaleMax > 0 then
			local d = win.dataset[nr] or {}
			win.dataset[nr] = d
			d.value = GetValue(player)
			d.label = player.name
			d.class = player.class
			d.id = player.id
			d.valuetext = tostring(d.value)
			if d.value > max then
				max = d.value
			end
			nr = nr + 1
		end
	end

	win.metadata.maxvalue = max
end

function OvaleSkada:AddToTooltip(set, tooltip)
	GameTooltip:AddDoubleLine("Ovale", GetValue(set), 1, 1, 1)
end

-- Called by Skada when a new player is added to a set.
function OvaleSkada:AddPlayerAttributes(player)
	if not player.ovale then
		player.ovale = 0
	end
	if not player.ovaleMax then
		player.ovaleMax = 0
	end
end

-- Called by Skada when a new set is created.
function OvaleSkada:AddSetAttributes(set)
	if not set.ovale then
		set.ovale = 0
	end
	if not set.ovaleMax then
		set.ovaleMax = 0
	end
end

function OvaleSkada:GetSetSummary(set)
	return GetValue(set)
end
--</public-static-methods>
