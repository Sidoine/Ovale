--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

-- Gather information about ennemies

local _, Ovale = ...
OvaleEnemies = Ovale:NewModule("OvaleEnemies", "AceEvent-3.0")

--<private-static-properties>
local bit_band, pairs, select, tostring = bit.band, pairs, select, tostring
local wipe = wipe

local COMBATLOG_OBJECT_AFFILIATION_OUTSIDER = COMBATLOG_OBJECT_AFFILIATION_OUTSIDER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

numberOfEnemies = 0
enemies = {}
--</private-static-properties>

--<public-static-methods>
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
		for k,v in pairs(enemies) do
			if k==destGUID then
				enemies[v] = nil
				numberOfEnemies = numberOfEnemies - 1
				Ovale.refreshNeeded["player"] = true
				Ovale:DebugPrint("enemy", "enemy die")
			end
		end
	elseif sourceFlags and not enemies[sourceGUID] and bit_band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE)>0
				and bit_band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0 and
			destFlags and bit_band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
		enemies[sourceGUID] = true
		Ovale:DebugPrint("enemy", "new enemy source=" .. tostring(sourceName))
		numberOfEnemies = numberOfEnemies + 1
		Ovale.refreshNeeded["player"] = true
	elseif destGUID and not enemies[destGUID] and bit_band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE)>0
				and bit_band(destFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) > 0 and
			sourceFlags and bit_band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0 then
		enemies[destGUID] = true
		Ovale:DebugPrint("enemy", "new enemy dest=".. tostring(destName))
		numberOfEnemies = numberOfEnemies + 1
		Ovale.refreshNeeded["player"] = true
	end
end

function OvaleEnemies:PLAYER_REGEN_DISABLED()
	if numberOfEnemies then
		numberOfEnemies = 0
		wipe(enemies)
	end
end

function OvaleEnemies:GetNumberOfEnemies()
	if not numberOfEnemies then
		numberOfEnemies = 0
	end
	return numberOfEnemies
end
--</public-static-methods>

