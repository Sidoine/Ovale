--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- Gather information about ennemies

local _, Ovale = ...
local OvaleEnemies = Ovale:NewModule("OvaleEnemies", "AceEvent-3.0", "AceTimer-3.0")
Ovale.OvaleEnemies = OvaleEnemies

--<private-static-properties>
local bit_band = bit.band
local pairs = pairs
local tostring = tostring
local wipe = table.wipe
local API_GetTime = GetTime
local COMBATLOG_OBJECT_AFFILIATION_OUTSIDER = COMBATLOG_OBJECT_AFFILIATION_OUTSIDER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

-- Timer for reaper function to remove inactive enemies.
local self_reaperTimer = nil
local REAP_INTERVAL = 3

local OVALE_ENEMIES_DEBUG = "enemy"
--</private-static-properties>

--<public-static-properties>
-- enemyLastSeen[guid] = timestamp
OvaleEnemies.enemyLastSeen = {}
-- enemyName[guid] = name
OvaleEnemies.enemyName = {}

-- Total number of active enemies.
OvaleEnemies.activeEnemies = 0
--</public-static-properties>

--<public-static-methods>
function OvaleEnemies:OnEnable()
	if not self_reaperTimer then
		self_reaperTimer = self:ScheduleRepeatingTimer("RemoveInactiveEnemies", REAP_INTERVAL)
	end
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function OvaleEnemies:OnDisable()
	if not self_reaperTimer then
		self:CancelTimer(self_reaperTimer)
		self_reaperTimer = nil
	end
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
end

function OvaleEnemies:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local now = API_GetTime()
	if cleuEvent == "UNIT_DIED" then
		self:RemoveEnemy(destGUID, true)
	elseif sourceFlags and bit_band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
			and bit_band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0
			and destFlags and bit_band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
		self:AddEnemy(sourceGUID, sourceName, now)
	elseif destGUID and bit_band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
			and bit_band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0
			and sourceFlags and bit_band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
		self:AddEnemy(destGUID, destName, now)
	end
end

function OvaleEnemies:PLAYER_REGEN_DISABLED()
	-- Reset enemy tracking when combat starts.
	wipe(self.enemyLastSeen)
	wipe(self.enemyName)
	self.activeEnemies = 0
end

-- Remove enemies that have been inactive for at least REAP_INTERVAL seconds.
-- These enemies are not in combat with your group, out of range, or
-- incapacitated and shouldn't count toward the number of active enemies.
function OvaleEnemies:RemoveInactiveEnemies()
	local now = API_GetTime()
	for guid, timestamp in pairs(self.enemyLastSeen) do
		if now - timestamp > REAP_INTERVAL then
			self:RemoveEnemy(guid)
		end
	end
end

function OvaleEnemies:AddEnemy(guid, name, timestamp)
	if not guid then return end
	local seen = self.enemyLastSeen[guid]
	self.enemyLastSeen[guid] = timestamp
	self.enemyName[guid] = name
	if not seen then
		self.activeEnemies = self.activeEnemies + 1
		Ovale:DebugPrintf(OVALE_ENEMIES_DEBUG, "New enemy (%d total): %s (%s)", self.activeEnemies, guid, name)
		Ovale.refreshNeeded["player"] = true
	end
end

function OvaleEnemies:RemoveEnemy(guid, isDead)
	if not guid then return end
	local seen = self.enemyLastSeen[guid]
	local name = self.enemyName[guid]
	self.enemyLastSeen[guid] = nil
	if seen then
		if self.activeEnemies > 0 then
			self.activeEnemies = self.activeEnemies - 1
		end
		if isDead then
			Ovale:DebugPrintf(OVALE_ENEMIES_DEBUG, "Enemy died (%d total): %s (%s)", self.activeEnemies, guid, name)
		else
			Ovale:DebugPrintf(OVALE_ENEMIES_DEBUG, "Enemy removed (%d total): %s (%s), last seen at %f", self.activeEnemies, guid, name, seen)
		end
		self:SendMessage("Ovale_InactiveUnit", guid)
		Ovale.refreshNeeded["player"] = true
	end
end

function OvaleEnemies:Debug()
	for guid, timestamp in pairs(self.enemyLastSeen) do
		Ovale:FormatPrint("enemy %s (%s) last seen at %f", guid, self.enemyName[guid], timestamp)
	end	
end
--</public-static-methods>
