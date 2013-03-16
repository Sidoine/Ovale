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

--<private-static-properties>
local bit_band = bit.band
local pairs = pairs
local select = select
local time = time
local tostring = tostring
local wipe = table.wipe

local COMBATLOG_OBJECT_AFFILIATION_OUTSIDER = COMBATLOG_OBJECT_AFFILIATION_OUTSIDER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

-- enemyLastSeen[guid] = timestamp
local enemyLastSeen = {}
-- enemyName[guid] = name
local enemyName = {}
-- timer for reaper function to remove inactive enemies
local reaperTimer = nil
local REAP_INTERVAL = 3
--</private-static-properties>

--<public-static-properties>
OvaleEnemies.activeEnemies = 0
--</public-static-properties>

--<private-static-methods>
function AddEnemy(guid, name, timestamp)
	if not guid then return end
	local seen = enemyLastSeen[guid]
	enemyLastSeen[guid] = timestamp
	enemyName[guid] = name
	if not seen then
		OvaleEnemies.activeEnemies = OvaleEnemies.activeEnemies + 1
		Ovale:DebugPrint("enemy", "New enemy (" .. OvaleEnemies.activeEnemies .. " total): " .. guid .. "(" .. tostring(name) .. ")")
		Ovale.refreshNeeded["player"] = true
	end
end

function RemoveEnemy(guid, isDead)
	if not guid then return end
	local seen = enemyLastSeen[guid]
	local name = enemyName[guid]
	enemyLastSeen[guid] = nil
	if seen then
		if OvaleEnemies.activeEnemies > 0 then
			OvaleEnemies.activeEnemies = OvaleEnemies.activeEnemies - 1
		end
		if isDead then
			Ovale:DebugPrint("enemy", "Enemy died (" .. OvaleEnemies.activeEnemies .. " total): " .. guid .. " (" .. tostring(name) .. ")")
		else
			Ovale:DebugPrint("enemy", "Enemy removed: (" .. OvaleEnemies.activeEnemies .. " total): " .. guid .. " (" .. tostring(name) .. "), last seen at " .. seen)
		end
		OvaleEnemies:SendMessage("Ovale_InactiveUnit", guid)
		Ovale.refreshNeeded["player"] = true
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleEnemies:OnEnable()
	if not reaperTimer then
		reaperTimer = self:ScheduleRepeatingTimer("RemoveInactiveEnemies", REAP_INTERVAL)
	end
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function OvaleEnemies:OnDisable()
	if not reaperTimer then
		self:CancelTimer(reaperTimer)
		reaperTimer = nil
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
	wipe(enemyLastSeen)
	wipe(enemyName)
	self.activeEnemies = 0
end

-- Remove enemies that have been inactive for at least REAP_INTERVAL seconds.
-- These enemies are not in combat with your group, out of range, or
-- incapacitated and shouldn't count toward the number of active enemies.
function OvaleEnemies:RemoveInactiveEnemies()
	for guid, timestamp in pairs(enemyLastSeen) do
		if Ovale.now - timestamp > REAP_INTERVAL then
			RemoveEnemy(guid)
		end
	end
end

function OvaleEnemies:Debug()
	for guid, timestamp in pairs(enemyLastSeen) do
		Ovale:Print("enemy " .. guid .. " (" .. tostring(enemyName[guid]) .. ") last seen at " .. timestamp)
	end	
end
--</public-static-methods>
