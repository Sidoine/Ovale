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
local OvaleGUID = Ovale.OvaleGUID
local OvaleFuture = Ovale.OvaleFuture
local OvalePool = Ovale.OvalePool
local OvaleQueue = Ovale.OvaleQueue

local select = select

-- Player's GUID.
local self_player_guid = nil
-- Damage event pool.
local self_pool = OvalePool:NewPool("OvaleDamageTaken_pool")
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
	self:RemoveExpiredEvents()
end
--</private-static-methods>

--<public-static-methods>
function OvaleDamageTaken:OnEnable()
	self_player_guid = OvaleGUID:GetGUID("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function OvaleDamageTaken:OnDisable()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

function OvaleDamageTaken:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)
	if destGUID == self_player_guid and event:find("_DAMAGE") then
		if event:find("SWING_") == 1 then
			local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = select(12, ...)
			Ovale:DebugPrintf(OVALE_DAMAGE_TAKEN_DEBUG, "%s caused %d damage.", event, amount)
			AddDamageTaken(Ovale.now, amount)
		elseif event:find("RANGE_") == 1 or event:find("SPELL_") == 1 then
			local spellId, spellName, spellSchool = select(12, ...)
			local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = select(15, ...)
			Ovale:DebugPrintf(OVALE_DAMAGE_TAKEN_DEBUG, "%s (%s) caused %d damage.", event, spellName, amount)
			AddDamageTaken(Ovale.now, amount)
		end
	end
end

function OvaleDamageTaken:PLAYER_REGEN_ENABLED(event)
	self_pool:Drain()
end

-- Return the total damage taken in the previous time interval (in seconds).
function OvaleDamageTaken:GetRecentDamage(interval, lagCorrection)
	local lowerBound = Ovale.now - interval
	if lagCorrection then
		lowerBound = lowerBound - OvaleFuture.latency
	end
	self:RemoveExpiredEvents()

	local total = 0
	for i, event in self_damageEvent:FrontToBackIterator() do
		if event.timestamp < lowerBound then
			break
		end
		total = total + event.damage
	end
	return total
end

function OvaleDamageTaken:RemoveExpiredEvents()
	local now = Ovale.now
	while true do
		local event = self_damageEvent:Back()
		if not event then break end
		if event then
			if now - event.timestamp < DAMAGE_TAKEN_WINDOW then
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
