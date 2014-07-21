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
-- taggedEnemy[guid] = true/nil
OvaleEnemies.taggedEnemy = {}

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
		self:RemoveEnemy(destGUID, true)
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
	wipe(self.enemyLastSeen)
	wipe(self.enemyName)
	self.activeEnemies = 0
end

-- Remove enemies that have been inactive for at least REAP_INTERVAL seconds.
-- These enemies are not in combat with your group, out of range, or
-- incapacitated and shouldn't count toward the number of active enemies.
function OvaleEnemies:RemoveInactiveEnemies()
	profiler.Start("OvaleEnemies_RemoveInactiveEnemies")
	local now = API_GetTime()
	for guid, timestamp in pairs(self.enemyLastSeen) do
		if now - timestamp > REAP_INTERVAL then
			self:RemoveEnemy(guid)
		end
	end
	profiler.Stop("OvaleEnemies_RemoveInactiveEnemies")
end

function OvaleEnemies:AddEnemy(guid, name, timestamp, isTagged)
	profiler.Start("OvaleEnemies_AddEnemy")
	if guid then
		local seen = self.enemyLastSeen[guid]
		self.enemyLastSeen[guid] = timestamp
		self.enemyName[guid] = name
		if not seen then
			self.activeEnemies = self.activeEnemies + 1
			if isTagged then
				self.taggedEnemies = self.taggedEnemies + 1
				self.taggedEnemy[guid] = true
				Ovale:DebugPrintf(OVALE_ENEMIES_DEBUG, "New tagged enemy (%d total, %d tagged): %s (%s)", self.activeEnemies, self.taggedEnemies, guid, name)
			else
				Ovale:DebugPrintf(OVALE_ENEMIES_DEBUG, "New enemy (%d total): %s (%s)", self.activeEnemies, guid, name)
			end
			Ovale.refreshNeeded["player"] = true
		end
	end
	profiler.Stop("OvaleEnemies_AddEnemy")
end

function OvaleEnemies:RemoveEnemy(guid, isDead)
	profiler.Start("OvaleEnemies_RemoveEnemy")
	if guid then
		local seen = self.enemyLastSeen[guid]
		local name = self.enemyName[guid]
		self.enemyLastSeen[guid] = nil
		if seen then
			if self.activeEnemies > 0 then
				self.activeEnemies = self.activeEnemies - 1
				if self.taggedEnemy[guid] then
					self.taggedEnemy[guid] = nil
					self.taggedEnemies = self.taggedEnemies - 1
				end
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
	profiler.Stop("OvaleEnemies_RemoveEnemy")
end

function OvaleEnemies:Debug()
	for guid, timestamp in pairs(self.enemyLastSeen) do
		Ovale:FormatPrint("enemy %s (%s) last seen at %f", guid, self.enemyName[guid], timestamp)
	end	
end
--</public-static-methods>
