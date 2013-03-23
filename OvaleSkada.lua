--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2010 Sidoine

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

local _, Ovale = ...
local OvaleSkada = Ovale:NewModule("OvaleSkada")
Ovale.OvaleSkada = OvaleSkada

--<private-static-properties>
local Skada = LibStub("AceAddon-3.0"):GetAddon("Skada", true)
local SkadaModule = Skada and Skada:NewModule("Ovale Spell Priority") or { noSkada = true }

local ipairs = ipairs
local math = math
local tostring = tostring
--</private-static-properties>

--<private-static-methods>
local function getValue(set)
	if set.ovaleMax and set.ovaleMax > 0 then
		return math.floor(1000 * set.ovale / set.ovaleMax)
	else
		return nil
	end
end
--</private-static-methods>

--<public-static-methods>
function SkadaModule:OnEnable()
	self.metadata = { showspots = true }
	Skada:AddMode(self)
end

function SkadaModule:OnDisable()
	Skada:RemoveMode(self)
end

function SkadaModule:Update(win, set)
	local max = 0
	local nr = 1

	for i, player in ipairs(set.players) do
		if player.ovaleMax and player.ovaleMax > 0 then
			local d = win.dataset[nr] or {}
			win.dataset[nr] = d
			d.value = getValue(player)
			d.label = player.name
			d.class = player.class
			d.id = player.id
			d.valuetext = tostring(getValue(player))
			if d.value > max then
				max = d.value
			end
			nr = nr + 1
		end
	end

	win.metadata.maxvalue = max
end

function SkadaModule:AddToTooltip(set, tooltip)
	GameTooltip:AddDoubleLine("Ovale", getValue(set), 1, 1, 1)
end

-- Called by Skada when a new player is added to a set.
function SkadaModule:AddPlayerAttributes(player)
	if not player.ovale then
		player.ovale = 0
	end
	if not player.ovaleMax then
		player.ovaleMax = 0
	end
end

-- Called by Skada when a new set is created.
function SkadaModule:AddSetAttributes(set)
	if not set.ovale then
		set.ovale = 0
	end
	if not set.ovaleMax then
		set.ovaleMax = 0
	end
end

function SkadaModule:GetSetSummary(set)
	return getValue(set)
end

function OvaleSkada:OnEnable()
	if SkadaModule.noSkada then return end
	Ovale:AddDamageMeter("OvaleSkada", self)
	if not SkadaModule:IsEnabled() then
		SkadaModule:Enable()
	end
end

function OvaleSkada:OnDisable()
	if SkadaModule.noSkada then return end
	Ovale:RemoveDamageMeter("OvaleSkada")
	if SkadaModule:IsEnabled() then
		SkadaModule:Disable()
	end
end

function OvaleSkada:SendScoreToDamageMeter(name, guid, scored, scoreMax)
	if SkadaModule.noSkada then return end
	if not guid or not Skada.current or not Skada.total then return end

	local player = Skada:get_player(Skada.current, guid, nil)
	if not player then return end

	SkadaModule:AddPlayerAttributes(player)
	player.ovale = player.ovale + scored
	player.ovaleMax = player.ovaleMax + scoreMax
	player = Skada:get_player(Skada.total, guid, nil)
	player.ovale = player.ovale + scored
	player.ovaleMax = player.ovaleMax + scoreMax
end
--</public-static-methods>
