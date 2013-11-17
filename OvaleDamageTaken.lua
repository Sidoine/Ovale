--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- This addon tracks the damage taken by the player from non-player sources.

local _, Ovale = ...
local OvaleDamageTaken = Ovale:NewModule("OvaleDamageTaken", "AceEvent-3.0")
Ovale.OvaleDamageTaken = OvaleDamageTaken

--<private-static-properties>
local OvalePool = Ovale.OvalePool
local OvaleQueue = Ovale.OvaleQueue

-- Forward declarations for module dependencies.
local OvaleLatency = nil

local select = select
local API_GetTime = GetTime
local API_UnitGUID = UnitGUID

-- Player's GUID.
local self_guid = API_UnitGUID("player")
-- Damage event pool.
local self_pool = OvalePool("OvaleDamageTaken_pool")
-- Damage event queue: new events are inserted at the front of the queue.
local self_damageEvent = OvaleQueue:NewDeque("OvaleDamageTaken_damageEvent")
-- Time window (past number of seconds) for which damage events are stored.
local DAMAGE_TAKEN_WINDOW = 20

local OVALE_DAMAGE_TAKEN_DEBUG = "damage_taken"
--</private-static-properties>

--<private-static-methods>
local function AddDamageTaken(timestamp, damage)
	local self = OvaleDamageTaken
	local event = self_pool:Get()
	event.timestamp = timestamp
	event.damage = damage
	self_damageEvent:InsertFront(event)
	self:RemoveExpiredEvents(timestamp)
end
--</private-static-methods>

--<public-static-methods>
function OvaleDamageTaken:OnInitialize()
	-- Resolve module dependencies.
	OvaleLatency = Ovale.OvaleLatency
end

function OvaleDamageTaken:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function OvaleDamageTaken:OnDisable()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

function OvaleDamageTaken:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)
	if destGUID == self_guid and event:find("_DAMAGE") then
		local now = API_GetTime()
		if event:find("SWING_") == 1 then
			local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = select(12, ...)
			Ovale:DebugPrintf(OVALE_DAMAGE_TAKEN_DEBUG, "%s caused %d damage.", event, amount)
			AddDamageTaken(now, amount)
		elseif event:find("RANGE_") == 1 or event:find("SPELL_") == 1 then
			local spellId, spellName, spellSchool = select(12, ...)
			local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = select(15, ...)
			Ovale:DebugPrintf(OVALE_DAMAGE_TAKEN_DEBUG, "%s (%s) caused %d damage.", event, spellName, amount)
			AddDamageTaken(now, amount)
		end
	end
end

function OvaleDamageTaken:PLAYER_REGEN_ENABLED(event)
	self_pool:Drain()
end

-- Return the total damage taken in the previous time interval (in seconds).
function OvaleDamageTaken:GetRecentDamage(interval, lagCorrection)
	local now = API_GetTime()
	local lowerBound = now - interval
	if lagCorrection then
		lowerBound = lowerBound - OvaleLatency:GetLatency()
	end
	self:RemoveExpiredEvents(now)

	local total = 0
	for i, event in self_damageEvent:FrontToBackIterator() do
		if event.timestamp < lowerBound then
			break
		end
		total = total + event.damage
	end
	return total
end

-- Remove all events that are more than DAMAGE_TAKEN_WINDOW seconds before the given timestamp.
function OvaleDamageTaken:RemoveExpiredEvents(timestamp)
	while true do
		local event = self_damageEvent:Back()
		if not event then break end
		if event then
			if timestamp - event.timestamp < DAMAGE_TAKEN_WINDOW then
				break
			end
			self_damageEvent:RemoveBack()
			self_pool:Release(event)
		end
	end
end

function OvaleDamageTaken:Debug()
	self_damageEvent:Debug()
	for i, event in self_damageEvent:BackToFrontIterator() do
		Ovale:FormatPrint("%d: %d damage", event.timestamp, event.damage)
	end
end
--</public-static-methods>
