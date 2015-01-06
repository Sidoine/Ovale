--[[--------------------------------------------------------------------
    Copyright (C) 2010 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local Skada = LibStub("AceAddon-3.0"):GetAddon("Skada", true)
local OvaleSkada = Skada and Skada:NewModule(OVALE) or Ovale:NewModule("OvaleSkada")
Ovale.OvaleSkada = OvaleSkada

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleScore = nil

local ipairs = ipairs
local floor = math.floor
local tostring = tostring
-- GLOBALS: GameTooltip
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
--</private-static-methods>

--<public-static-methods>
function OvaleSkada:OnInitialize()
	-- Resolve module dependencies.
	OvaleScore = Ovale.OvaleScore
end

function OvaleSkada:OnEnable()
	self.metadata = { showspots = true }
	if Skada then
		Skada:AddMode(self)
		OvaleScore:RegisterDamageMeter("OvaleSkada", self, "ReceiveScore")
	end
end

function OvaleSkada:OnDisable()
	OvaleScore:UnregisterDamageMeter("OvaleSkada")
	if Skada then Skada:RemoveMode(self) end
end

function OvaleSkada:ReceiveScore(name, guid, scored, scoreMax)
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
