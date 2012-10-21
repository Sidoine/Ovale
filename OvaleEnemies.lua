--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

-- Gather information about ennemies

OvaleEnemies = LibStub("AceAddon-3.0"):NewAddon("OvaleEnemies", "AceEvent-3.0")

--<private-static-properties>
local bit_band, pairs, select, tostring = bit.band, pairs, select, tostring
local COMBATLOG_OBJECT_AFFILIATION_OUTSIDER = COMBATLOG_OBJECT_AFFILIATION_OUTSIDER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
--</private-static-properties>

--<public-static-properties>
OvaleEnemies.numberOfEnemies = 0
OvaleEnemies.enemies = {}
--</public-static-properties>

--<public-static-methods>
-- Events
function OvaleEnemies:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function OvaleEnemies:OnDisable()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
end

function OvaleEnemies:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local time, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)

	if event == "UNIT_DIED" then
		for k,v in pairs(self.enemies) do
			if k==destGUID then
				self.enemies[v] = nil
				self.numberOfEnemies = self.numberOfEnemies - 1
				Ovale.refreshNeeded["player"] = true
				Ovale:debugPrint("enemy", "enemy die")
			end
		end
	elseif sourceFlags and not self.enemies[sourceGUID] and bit_band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE)>0
				and bit_band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0 and
			destFlags and bit_band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
		self.enemies[sourceGUID] = true
		Ovale:debugPrint("enemy", "new enemy source=" .. tostring(sourceName))
		self.numberOfEnemies = self.numberOfEnemies + 1
		Ovale.refreshNeeded["player"] = true
	elseif destGUID and not self.enemies[destGUID] and bit_band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE)>0
				and bit_band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0 and
			sourceFlags and bit_band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
		self.enemies[destGUID] = true
		Ovale:debugPrint("enemy", "new enemy dest=".. tostring(destName))
		self.numberOfEnemies = self.numberOfEnemies + 1
		Ovale.refreshNeeded["player"] = true
	end
end

function OvaleEnemies:PLAYER_REGEN_DISABLED()
	if self.numberOfEnemies then
		self.numberOfEnemies = 0
		self.enemies = {}
	end
end

function OvaleEnemies:GetNumberOfEnemies()
	if not self.numberOfEnemies then
		self.numberOfEnemies = 0
	end
	return self.numberOfEnemies
end
--</public-static-methods>

