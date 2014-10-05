--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- This addon tracks the damage taken by the player from non-player sources.

local _, Ovale = ...
local OvaleDamageTaken = Ovale:NewModule("OvaleDamageTaken", "AceEvent-3.0")
Ovale.OvaleDamageTaken = OvaleDamageTaken

--<private-static-properties>
-- Profiling set-up.
local Profiler = Ovale.Profiler
local profiler = nil
do
	local group = OvaleDamageTaken:GetName()
	Profiler:RegisterProfilingGroup(group)
	profiler = Profiler:GetProfilingGroup(group)
end

local OvalePool = Ovale.OvalePool
local OvaleQueue = Ovale.OvaleQueue

-- Forward declarations for module dependencies.
local OvaleLatency = nil

local API_GetTime = GetTime
local API_UnitGUID = UnitGUID

-- Player's GUID.
local self_guid = nil
-- Damage event pool.
local self_pool = OvalePool("OvaleDamageTaken_pool")
-- Time window (past number of seconds) for which damage events are stored.
local DAMAGE_TAKEN_WINDOW = 20

local OVALE_DAMAGE_TAKEN_DEBUG = "damage_taken"
--</private-static-properties>

--<public-static-properties>
-- Damage event queue: new events are inserted at the front of the queue.
OvaleDamageTaken.damageEvent = OvaleQueue:NewDeque("OvaleDamageTaken_damageEvent")
--</public-static-properties>

--<public-static-methods>
function OvaleDamageTaken:OnInitialize()
	-- Resolve module dependencies.
	OvaleLatency = Ovale.OvaleLatency
end

function OvaleDamageTaken:OnEnable()
	self_guid = API_UnitGUID("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function OvaleDamageTaken:OnDisable()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self_pool:Drain()
end

function OvaleDamageTaken:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23 = ...

	if destGUID == self_guid and strsub(cleuEvent, -7) == "_DAMAGE" then
		profiler.Start("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED")
		local now = API_GetTime()
		local eventPrefix = strsub(cleuEvent, 1, 6)
		if eventPrefix == "SWING_" then
			local amount = arg12
			Ovale:DebugPrintf(OVALE_DAMAGE_TAKEN_DEBUG, "%s caused %d damage.", cleuEvent, amount)
			self:AddDamageTaken(now, amount)
		elseif eventPrefix == "RANGE_" or eventPrefix == "SPELL_" then
			local spellName, amount = arg13, arg15
			Ovale:DebugPrintf(OVALE_DAMAGE_TAKEN_DEBUG, "%s (%s) caused %d damage.", cleuEvent, spellName, amount)
			self:AddDamageTaken(now, amount)
		end
		profiler.Stop("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED")
	end
end

function OvaleDamageTaken:PLAYER_REGEN_ENABLED(event)
	self_pool:Drain()
end

function OvaleDamageTaken:AddDamageTaken(timestamp, damage)
	profiler.Start("OvaleDamageTaken_AddDamageTaken")
	local event = self_pool:Get()
	event.timestamp = timestamp
	event.damage = damage
	self.damageEvent:InsertFront(event)
	self:RemoveExpiredEvents(timestamp)
	profiler.Stop("OvaleDamageTaken_AddDamageTaken")
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
	for i, event in self.damageEvent:FrontToBackIterator() do
		if event.timestamp < lowerBound then
			break
		end
		total = total + event.damage
	end
	return total
end

-- Remove all events that are more than DAMAGE_TAKEN_WINDOW seconds before the given timestamp.
function OvaleDamageTaken:RemoveExpiredEvents(timestamp)
	profiler.Start("OvaleDamageTaken_RemoveExpiredEvents")
	while true do
		local event = self.damageEvent:Back()
		if not event then break end
		if event then
			if timestamp - event.timestamp < DAMAGE_TAKEN_WINDOW then
				break
			end
			self.damageEvent:RemoveBack()
			self_pool:Release(event)
		end
	end
	profiler.Stop("OvaleDamageTaken_RemoveExpiredEvents")
end

function OvaleDamageTaken:Debug()
	self.damageEvent:Debug()
	for i, event in self.damageEvent:BackToFrontIterator() do
		Ovale:FormatPrint("%d: %d damage", event.timestamp, event.damage)
	end
end
--</public-static-methods>
