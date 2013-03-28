--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

-- Gather information about ennemies

local _, Ovale = ...
local OvaleEnemies = Ovale:NewModule("OvaleEnemies", "AceEvent-3.0", "AceTimer-3.0")
Ovale.OvaleEnemies = OvaleEnemies

--<private-static-properties>
local bit_band = bit.band
local pairs = pairs
local select = select
local tostring = tostring
local wipe = table.wipe
local COMBATLOG_OBJECT_AFFILIATION_OUTSIDER = COMBATLOG_OBJECT_AFFILIATION_OUTSIDER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

-- self_enemyLastSeen[guid] = timestamp
local self_enemyLastSeen = {}
-- self_enemyName[guid] = name
local self_enemyName = {}
-- timer for reaper function to remove inactive enemies
local self_reaperTimer = nil
local REAP_INTERVAL = 3

local OVALE_ENEMIES_DEBUG = "enemy"
--</private-static-properties>

--<public-static-properties>
OvaleEnemies.activeEnemies = 0
--</public-static-properties>

--<private-static-methods>
local function AddEnemy(guid, name, timestamp)
	if not guid then return end
	local self = OvaleEnemies
	local seen = self_enemyLastSeen[guid]
	self_enemyLastSeen[guid] = timestamp
	self_enemyName[guid] = name
	if not seen then
		self.activeEnemies = self.activeEnemies + 1
		Ovale:DebugPrintf(OVALE_ENEMIES_DEBUG, "New enemy (%d total): %s (%s)", self.activeEnemies, guid, name)
		Ovale.refreshNeeded["player"] = true
	end
end

local function RemoveEnemy(guid, isDead)
	if not guid then return end
	local self = OvaleEnemies
	local seen = self_enemyLastSeen[guid]
	local name = self_enemyName[guid]
	self_enemyLastSeen[guid] = nil
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
--</private-static-methods>

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

function OvaleEnemies:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)

	if event == "UNIT_DIED" then
		RemoveEnemy(destGUID, true)
	elseif sourceFlags and bit_band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
			and bit_band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0
			and destFlags and bit_band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
		AddEnemy(sourceGUID, sourceName, Ovale.now)
	elseif destGUID and bit_band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
			and bit_band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0
			and sourceFlags and bit_band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
		AddEnemy(destGUID, destName, Ovale.now)
	end
end

function OvaleEnemies:PLAYER_REGEN_DISABLED()
	-- Reset enemy tracking when combat starts.
	wipe(self_enemyLastSeen)
	wipe(self_enemyName)
	self.activeEnemies = 0
end

-- Remove enemies that have been inactive for at least REAP_INTERVAL seconds.
-- These enemies are not in combat with your group, out of range, or
-- incapacitated and shouldn't count toward the number of active enemies.
function OvaleEnemies:RemoveInactiveEnemies()
	for guid, timestamp in pairs(self_enemyLastSeen) do
		if Ovale.now - timestamp > REAP_INTERVAL then
			RemoveEnemy(guid)
		end
	end
end

function OvaleEnemies:Debug()
	for guid, timestamp in pairs(self_enemyLastSeen) do
		Ovale:Printf("enemy %s (%s) last seen at %f", guid, self_enemyName[guid], timestamp)
	end	
end
--</public-static-methods>
