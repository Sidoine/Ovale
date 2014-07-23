--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- Gather information about ennemies

local _, Ovale = ...
local OvaleEnemies = Ovale:NewModule("OvaleEnemies", "AceEvent-3.0", "AceTimer-3.0")
Ovale.OvaleEnemies = OvaleEnemies

--<private-static-properties>
-- Profiling set-up.
local Profiler = Ovale.Profiler
local profiler = nil
do
	local group = OvaleEnemies:GetName()
	Profiler:RegisterProfilingGroup(group)
	profiler = Profiler:GetProfilingGroup(group)
end

local bit_band = bit.band
local ipairs = ipairs
local pairs = pairs
local strfind = string.find
local tostring = tostring
local wipe = table.wipe
local API_GetTime = GetTime
local API_UnitGUID = UnitGUID
local COMBATLOG_OBJECT_AFFILIATION_OUTSIDER = COMBATLOG_OBJECT_AFFILIATION_OUTSIDER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

-- List of CLEU event suffixes that can correspond to the player damaging or try to damage (tag) an enemy.
local CLEU_TAG_SUFFIXES = {
	"_CAST_START",
	"_DAMAGE",
	"_MISSED",
	"_DRAIN",
	"_LEECH",
	"_INTERRUPT",
	"_DISPEL",
	"_DISPEL_FAILED",
	"_STOLEN",
	"_AURA_APPLIED",
	"_AURA_APPLIED_DOSE",
	"_AURA_REFRESH",
}

-- Player's GUID.
local self_guid = nil

-- enemyName[guid] = name
local self_enemyName = {}
-- enemyLastSeen[guid] = timestamp
local self_enemyLastSeen = {}
-- taggedEnemyLastSeen[guid] = timestamp
-- GUIDs used as keys for this table are a subset of the GUIDs used for enemyLastSeen.
local self_taggedEnemyLastSeen = {}

-- Timer for reaper function to remove inactive enemies.
local self_reaperTimer = nil
local REAP_INTERVAL = 3

local OVALE_ENEMIES_DEBUG = "enemy"
--</private-static-properties>

--<public-static-properties>
-- Total number of active enemies.
OvaleEnemies.activeEnemies = 0
-- Total number of tagged enemies.
OvaleEnemies.taggedEnemies = 0
--</public-static-properties>

--<private-static-methods>
local function IsTagEvent(cleuEvent)
	for _, suffix in ipairs(CLEU_TAG_SUFFIXES) do
		if strfind(cleuEvent, suffix .. "$") then
			return true
		end
	end
	return false
end
--</private-static-methods>

--<public-static-methods>
function OvaleEnemies:OnEnable()
	self_guid = API_UnitGUID("player")
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
	if cleuEvent == "UNIT_DIED" then
		local now = API_GetTime()
		self:RemoveEnemy(destGUID, now, true)
	elseif sourceFlags and bit_band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
			and bit_band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0
			and destFlags and bit_band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
		local now = API_GetTime()
		self:AddEnemy(sourceGUID, sourceName, now)
	elseif destGUID and bit_band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
			and bit_band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0
			and sourceFlags and bit_band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
		local now = API_GetTime()
		local isTagged = (sourceGUID == self_guid and IsTagEvent(cleuEvent))
		self:AddEnemy(destGUID, destName, now, isTagged)
	end
end

function OvaleEnemies:PLAYER_REGEN_DISABLED()
	-- Reset enemy tracking when combat starts.
	wipe(self_enemyName)
	wipe(self_enemyLastSeen)
	wipe(self_taggedEnemyLastSeen)
	self.activeEnemies = 0
	self.taggedEnemies = 0
end

-- Remove enemies that have been inactive for at least REAP_INTERVAL seconds.
-- These enemies are not in combat with your group, out of range, or
-- incapacitated and shouldn't count toward the number of active enemies.
function OvaleEnemies:RemoveInactiveEnemies()
	profiler.Start("OvaleEnemies_RemoveInactiveEnemies")
	local now = API_GetTime()
	for guid, timestamp in pairs(self_enemyLastSeen) do
		if now - timestamp > REAP_INTERVAL then
			self:RemoveEnemy(guid, now)
		end
	end
	profiler.Stop("OvaleEnemies_RemoveInactiveEnemies")
end

function OvaleEnemies:AddEnemy(guid, name, timestamp, isTagged)
	profiler.Start("OvaleEnemies_AddEnemy")
	if guid then
		self_enemyName[guid] = name
		local tagged = self_taggedEnemyLastSeen[guid]
		if isTagged then
			local tagged = self_taggedEnemyLastSeen[guid]
			self_taggedEnemyLastSeen[guid] = timestamp
			if not tagged then
				self.taggedEnemies = self.taggedEnemies + 1
			end
		end
		local seen = self_enemyLastSeen[guid]
		self_enemyLastSeen[guid] = timestamp
		if not seen then
			self.activeEnemies = self.activeEnemies + 1
		end
		if isTagged and not tagged then
			Ovale:DebugPrintf(OVALE_ENEMIES_DEBUG, "New tagged enemy seen at %f (%d total, %d tagged): %s (%s)", timestamp, self.activeEnemies, self.taggedEnemies, guid, name)
			Ovale.refreshNeeded["player"] = true
		elseif not seen then
			Ovale:DebugPrintf(OVALE_ENEMIES_DEBUG, "New enemy seen at %f (%d total): %s (%s)", timestamp, self.activeEnemies, guid, name)
			Ovale.refreshNeeded["player"] = true
		end
	end
	profiler.Stop("OvaleEnemies_AddEnemy")
end

function OvaleEnemies:RemoveEnemy(guid, timestamp, isDead)
	profiler.Start("OvaleEnemies_RemoveEnemy")
	if guid then
		local name = self_enemyName[guid]
		local seen = self_enemyLastSeen[guid]
		local tagged = self_taggedEnemyLastSeen[guid]
		if tagged then
			self_taggedEnemyLastSeen[guid] = nil
			if self.taggedEnemies > 0 then
				self.taggedEnemies = self.taggedEnemies - 1
			end
		end
		if seen then
			self_enemyLastSeen[guid] = nil
			if self.activeEnemies > 0 then
				self.activeEnemies = self.activeEnemies - 1
			end
		end
		if tagged then
			if isDead then
				Ovale:DebugPrintf(OVALE_ENEMIES_DEBUG, "Tagged enemy died at %f (%d total, %d tagged): %s (%s)", timestamp, self.activeEnemies, self.taggedEnemies, guid, name)
			else
				Ovale:DebugPrintf(OVALE_ENEMIES_DEBUG, "Tagged enemy removed at %f(%d total, %d tagged): %s (%s), last seen at %f", timestamp, self.activeEnemies, self.taggedEnemies, guid, name, tagged)
			end
		elseif seen then
			if isDead then
				Ovale:DebugPrintf(OVALE_ENEMIES_DEBUG, "Enemy died at %f (%d total): %s (%s)", timestamp, self.activeEnemies, guid, name)
			else
				Ovale:DebugPrintf(OVALE_ENEMIES_DEBUG, "Enemy removed at %f (%d total): %s (%s), last seen at %f", timestamp, self.activeEnemies, guid, name, seen)
			end
		end
		if tagged or seen then
			Ovale.refreshNeeded["player"] = true
			self:SendMessage("Ovale_InactiveUnit", guid)
		end
	end
	profiler.Stop("OvaleEnemies_RemoveEnemy")
end

function OvaleEnemies:Debug()
	for guid, seen in pairs(self_enemyLastSeen) do
		local name = self_enemyName[guid]
		local tagged = self_taggedEnemyLastSeen[guid]
		if tagged then
			Ovale:FormatPrint("Tagged enemy %s (%s) last seen at %f", guid, name, tagged)
		else
			Ovale:FormatPrint("Enemy %s (%s) last seen at %f", guid, name, seen)
		end
	end
	Ovale:FormatPrint("Total enemies: %d", self.activeEnemies)
	Ovale:FormatPrint("Total tagged enemies: %d", self.taggedEnemies)
end
--</public-static-methods>
