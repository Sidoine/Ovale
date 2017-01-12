--[[--------------------------------------------------------------------
    Copyright (C) 2012, 2013 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

--[[
	OvaleFuture tracks player/pet spells that are being cast or are
	in flight to their targets.

	The UNIT_SPELLCAST_* events are treated as the definitive events for
	the spellcasts, but CLEU events are used to fix up target GUIDs in
	active spellcasts and to track when a spell has landed on its target.
--]]

local OVALE, Ovale = ...
local OvaleFuture = Ovale:NewModule("OvaleFuture", "AceEvent-3.0")
Ovale.OvaleFuture = OvaleFuture

--<private-static-properties>
local OvaleDebug = Ovale.OvaleDebug
local OvalePool = Ovale.OvalePool
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleAura = nil
local OvaleCooldown = nil
local OvaleData = nil
local OvaleGUID = nil
local OvalePaperDoll = nil
local OvaleScore = nil
local OvaleSpellBook = nil
local OvaleState = nil

local assert = assert
local ipairs = ipairs
local pairs = pairs
local strsub = string.sub
local tinsert = table.insert
local tremove = table.remove
local type = type
local wipe = wipe
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local API_UnitCastingInfo = UnitCastingInfo
local API_UnitChannelInfo = UnitChannelInfo
local API_UnitExists = UnitExists
local API_UnitGUID = UnitGUID
local API_UnitName = UnitName

-- Register for debugging.
OvaleDebug:RegisterDebugging(OvaleFuture)
-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleFuture)

-- Player's GUID.
local self_playerGUID = nil
-- Pool of spellcast tables.
local self_pool = OvalePool("OvaleFuture_pool")

-- Time at which an aura on the player was most recently added.
local self_timeAuraAdded = nil

--[[
	List of registered modules with methods to save and copy module-specific
	information to and from spellcasts.

		module:CopySpellcastInfo(spellcast, dest)
		module:SaveSpellcastInfo(spellcast, atTime, state)
--]]
local self_modules = {}

-- These CLEU events are eventually received after a successful spellcast.
local CLEU_AURA_EVENT = {
	SPELL_AURA_APPLIED = "hit",
	SPELL_AURA_APPLIED_DOSE = "hit",
	SPELL_AURA_BROKEN = "hit",
	SPELL_AURA_BROKEN_SPELL = "hit",
	SPELL_AURA_REFRESH = "hit",
	SPELL_AURA_REMOVED = "hit",
	SPELL_AURA_REMOVED_DOSE = "hit",
}
local CLEU_SPELLCAST_FINISH_EVENT = {
	SPELL_DAMAGE = "hit",
	SPELL_DISPEL = "hit",
	SPELL_DISPEL_FAILED = "miss",
	SPELL_HEAL = "hit",
	SPELL_INTERRUPT = "hit",
	SPELL_MISSED = "miss",
	SPELL_STOLEN = "hit",
}
local CLEU_SPELLCAST_EVENT = {
	SPELL_CAST_FAILED = true,
	SPELL_CAST_START = true,
	SPELL_CAST_SUCCESS = true,
}
do
	-- Aura events are also spellcast finishing events.
	for cleuEvent, v in pairs(CLEU_AURA_EVENT) do
		CLEU_SPELLCAST_FINISH_EVENT[cleuEvent] = v
	end
	-- Spellcast finishing events are also spellcast events.
	for cleuEvent, v in pairs(CLEU_SPELLCAST_FINISH_EVENT) do
		CLEU_SPELLCAST_EVENT[cleuEvent] = true
	end
end

-- The order in which auras applied or refreshed by a spell are checked.
local SPELLCAST_AURA_ORDER = { "target", "pet" }

-- Use zero as the target GUID of spells that have no target.
local UNKNOWN_GUID = 0

-- Table of aura additions.
local SPELLAURALIST_AURA_VALUE = {
	count = true,
	extend = true,
	refresh = true,
	refresh_keep_snapshot = true,
}

local WHITE_ATTACK = {
	[    75] = true,	-- Auto Shot
	[  5019] = true,	-- Shoot
	[  6603] = true,	-- Auto Attack
}
local WHITE_ATTACK_NAME = {}
do
	for spellId in pairs(WHITE_ATTACK) do
		local name = API_GetSpellInfo(spellId)
		if name then
			WHITE_ATTACK_NAME[name] = true
		end
	end
end

--[[
	This is the delta added to the starting cast time of the spell in the simulator.
	This ensures that the time in the simulator is just after the spell has started
	being cast.
--]]
local SIMULATOR_LAG = 0.005
--</private-static-properties>

--<public-static-properties>
-- Whether the player is in combat.
OvaleFuture.inCombat = nil
-- The time that combat started.
OvaleFuture.combatStartTime = nil
-- List of queued spellcasts.
OvaleFuture.queue = {}
-- Table of most recent cast times of spells, indexed by spell ID.
OvaleFuture.lastCastTime = {}
-- The most recent spellcast.
OvaleFuture.lastSpellcast = nil
-- The most recent spellcast that triggered the global cooldown.
OvaleFuture.lastGCDSpellcast = {}
-- The most recent spellcast that was off the global cooldown.
OvaleFuture.lastOffGCDSpellcast = {}
-- Spell counters.
OvaleFuture.counter = {}
--</public-static-properties>

--<private-static-methods>
-- Returns true if two spellcasts tables refer to the same spellcast.
local function IsSameSpellcast(a, b)
	local boolean = (a.spellId == b.spellId and a.queued == b.queued)
	if boolean then
		if a.channel or b.channel then
			if a.channel ~= b.channel then
				boolean = false
			end
		elseif a.lineId ~= b.lineId then
			boolean = false
		end
	end
	return boolean
end
--</private-static-methods>

--<public-static-methods>
function OvaleFuture:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
	OvaleCooldown = Ovale.OvaleCooldown
	OvaleData = Ovale.OvaleData
	OvaleGUID = Ovale.OvaleGUID
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvaleScore = Ovale.OvaleScore
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleState = Ovale.OvaleState
end

function OvaleFuture:OnEnable()
	self_playerGUID = Ovale.playerGUID
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "UnitSpellcastEnded")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET", "UnitSpellcastEnded")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "UnitSpellcastEnded")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "UnitSpellcastEnded")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterMessage("Ovale_AuraAdded")
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvaleFuture:OnDisable()
	OvaleState:UnregisterState(self)
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	self:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
	self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
	self:UnregisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:UnregisterEvent("UNIT_SPELLCAST_SENT")
	self:UnregisterEvent("UNIT_SPELLCAST_START")
	self:UnregisterEvent("UNIT_SPELLCAST_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:UnregisterMessage("Ovale_AuraAdded")
end

--[[--------------
	Event handlers
--]]--------------

--[[
	CLEU events generally happen in a certain order, but they can arrive out of order.
	We ignore SPELL_CAST_SUCCESS since it arrives out of order too often to be reliable.

	Cast-time damage spell:
		SPELL_CAST_START
		SPELL_CAST_FAILED/SPELL_DAMAGE/SPELL_INTERRUPT/SPELL_MISSED
	Cast-time heal spell:
		SPELL_CAST_START
		SPELL_CAST_FAILED/SPELL_HEAL/SPELL_INTERRUPT
	Instant-cast damage spell:
		SPELL_CAST_SUCCESS
		SPELL_CAST_FAILED/SPELL_DAMAGE/SPELL_MISSED
	Instant-cast heal spell:
		SPELL_CAST_FAILED/SPELL_HEAL
	Channel damage spell:
		SPELL_CAST_SUCCESS
		SPELL_AURA_APPLIED
		SPELL_PERIODIC_DAMAGE (per tick)
		(interruption does not generate an event)
	Channel heal spell:
		SPELL_CAST_SUCCESS
		SPELL_AURA_APPLIED
		SPELL_PERIODIC_HEAL (per tick)
		(interruption does not generate an event)

	Applying an aura:
		SPELL_AURA_APPLIED
		SPELL_CAST_SUCCESS
	Refreshing an aura:
		SPELL_AURA_REFRESH
		SPELL_CAST_SUCCESS
	Removing an aura:
		SPELL_AURA_REMOVED
	Casting a damage-over-time spell:
		SPELL_CAST_SUCCESS
		SPELL_AURA_APPLIED
		SPELL_PERIODIC_DAMAGE (per tick)
	Casting a heal-over-time spell:
		SPELL_CAST_SUCCESS
		SPELL_AURA_APPLIED
		SPELL_PERIODIC_HEAL (per tick)
--]]

function OvaleFuture:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...

	if sourceGUID == self_playerGUID or OvaleGUID:IsPlayerPet(sourceGUID) then
		self:StartProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED")
		if CLEU_SPELLCAST_EVENT[cleuEvent] then
			local now = API_GetTime()
			local spellId, spellName = arg12, arg13
			local eventDebug = false

			-- Disambiguate the target GUID of any matching spellcast.
			if strsub(cleuEvent, 1, 11) == "SPELL_CAST_" and (destName and destName ~= "") then
				if not eventDebug then
					self:DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName)
					eventDebug = true
				end
				local spellcast = self:GetSpellcast(spellName, spellId, nil, now)
				if spellcast and spellcast.targetName and spellcast.targetName == destName and spellcast.target ~= destGUID then
					self:Debug("Disambiguating target of spell %s (%d) to %s (%s).", spellName, spellId, destName, destGUID)
					spellcast.target = destGUID
				end
			end

			-- Check for a "finishing" event for active spellcasts.
			local finish = CLEU_SPELLCAST_FINISH_EVENT[cleuEvent]
			--[[
				If this is a SPELL_DAMAGE or SPELL_HEAL event, then only count it as
				finishing event if it was the "main" attack, and not an off-hand or
				multistrike attack.
			--]]
			if cleuEvent == "SPELL_DAMAGE" or cleuEvent == "SPELL_HEAL" then
				local isOffHand, multistrike = arg24, arg25
				if isOffHand or multistrike then
					finish = nil
				end
			end
			if finish then
				--[[
					Check every queued spellcast and see if this "finish" event signals
					that the spell has landed.  A single event can signal the finish for
					more than one spellcast.
				--]]
				-- Scan backwards since we are removing list elements while traversing the list.
				local anyFinished = false
				for i = #self.queue, 1, -1 do
					local spellcast = self.queue[i]
					if spellcast.success and (spellcast.spellId == spellId or spellcast.auraId == spellId) then
						if self:FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i) then
							anyFinished = true
						end
					end
				end
				if not anyFinished then
					self:Debug("No spell found for %s (%d)", spellName, spellId)
					for i = #self.queue, 1, -1 do
						local spellcast = self.queue[i]
						if spellcast.success and (spellcast.spellName == spellName) then
							if self:FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i) then
								anyFinished = true
							end
						end
					end

					if not anyFinished then
						self:Debug("No spell found for %s", spellName, spellId)
					end
				end
			end
		end
		self:StopProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED")
	end
end

function OvaleFuture:FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i)
	local finished = false
	if not spellcast.auraId then
		--[[
			There is no aura to detect, so the spell is finished when it lands,
			but not if it is a channelled spell.
		--]]
		if not eventDebug then
			self:DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName)
			eventDebug = true
		end
		if not spellcast.channel then
			self:Debug("Finished (%s) spell %s (%d) queued at %s due to %s.", finish, spellName, spellId, spellcast.queued, cleuEvent)
			finished = true
		end
	elseif CLEU_AURA_EVENT[cleuEvent] and spellcast.auraGUID and destGUID == spellcast.auraGUID then
		-- The spell is finished when the aura update is detected.
		if not eventDebug then
			self:DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName)
			eventDebug = true
		end
		self:Debug("Finished (%s) spell %s (%d) queued at %s after seeing aura %d on %s.", finish, spellName, spellId, spellcast.queued, spellcast.auraId, spellcast.auraGUID)
		finished = true
	end
	if finished then
		local now = API_GetTime()
		-- Update snapshots in cached spellcasts.
		if self_timeAuraAdded then
			if IsSameSpellcast(spellcast, self.lastGCDSpellcast) then
				self:UpdateSpellcastSnapshot(self.lastGCDSpellcast, self_timeAuraAdded)
			end
			if IsSameSpellcast(spellcast, self.lastOffGCDSpellcast) then
				self:UpdateSpellcastSnapshot(self.lastOffGCDSpellcast, self_timeAuraAdded)
			end
		end
		local delta = now - spellcast.stop
		local targetGUID = spellcast.target
		self:Debug("Spell %s (%d) was in flight for %s seconds.", spellName, spellId, delta)
		-- Remove the finished spellcast from the spell queue.
		tremove(self.queue, i)
		self_pool:Release(spellcast)
		Ovale.refreshNeeded[self_playerGUID] = true
		self:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish)
	end
	return finished
end

function OvaleFuture:PLAYER_ENTERING_WORLD(event)
	self:StartProfiling("OvaleFuture_PLAYER_ENTERING_WORLD")
	self:Debug(event)
	self:StopProfiling("OvaleFuture_PLAYER_ENTERING_WORLD")
end

function OvaleFuture:PLAYER_REGEN_DISABLED(event)
	self:StartProfiling("OvaleFuture_PLAYER_REGEN_DISABLED")
	self:Debug(event, "Entering combat.")
	local now = API_GetTime()
	self.inCombat = true
	self.combatStartTime = now
	Ovale.refreshNeeded[self_playerGUID] = true
	self:SendMessage("Ovale_CombatStarted", now)
	self:StopProfiling("OvaleFuture_PLAYER_REGEN_DISABLED")
end

function OvaleFuture:PLAYER_REGEN_ENABLED(event)
	self:StartProfiling("OvaleFuture_PLAYER_REGEN_ENABLED")
	self:Debug(event, "Leaving combat.")
	local now = API_GetTime()
	self.inCombat = false
	Ovale.refreshNeeded[self_playerGUID] = true
	self:SendMessage("Ovale_CombatEnded", now)
	self:StopProfiling("OvaleFuture_PLAYER_REGEN_ENABLED")
end

--[[
	Cast-time spell:
		UNIT_SPELLCAST_SENT
		UNIT_SPELLCAST_START
		UNIT_SPELLCAST_DELAYED
		UNIT_SPELLCAST_INTERRUPTED/UNIT_SPELLCAST_STOP/UNIT_SPELLCAST_SUCCEEDED
	Instant-cast spell:
		UNIT_SPELLCAST_SENT
		UNIT_SPELLCAST_SUCCEEDED
	Channel:
		UNIT_SPELLCAST_SENT
		UNIT_SPELLCAST_CHANNEL_START
		UNIT_SPELLCAST_SUCCEEDED
		UNIT_SPELLCAST_CHANNEL_UPDATE/UNIT_SPELLCAST_CHANNEL_STOP
--]]

function OvaleFuture:UNIT_SPELLCAST_CHANNEL_START(event, unitId, spell, rank, lineId, spellId)
	if (unitId == "player" or unitId == "pet") and not WHITE_ATTACK[spellId] then
		self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_START")
		self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
		--[[
			A channelled spell is actually two separate spells: a cast portion to land
			the spell, and a channel portion, each with different line IDs.  Find the
			previous spellcast that landed the channelled spell.
		--]]
		local now = API_GetTime()
		-- Find the matching spellcast by name -- the line ID is always zero for channelled spells.
		local spellcast = self:GetSpellcast(spell, spellId, nil, now)
		if spellcast then
			local name, _, _, _, startTime, endTime = API_UnitChannelInfo(unitId)
			if name == spell then
				startTime = startTime / 1000
				endTime = endTime / 1000
				spellcast.channel = true
				spellcast.spellId = spellId
				-- Channelled spells are successful once they've started casting.
				spellcast.success = now
				spellcast.start = startTime
				spellcast.stop = endTime
				local delta = now - spellcast.queued
				self:Debug("Channelling spell %s (%d): start = %s (+%s), ending = %s", spell, spellId, startTime, delta, endTime)
				-- Update saved information in the spellcast to the current time.
				self:SaveSpellcastInfo(spellcast, now)
				-- Cache the most recent spellcast information.
				self:UpdateLastSpellcast(now, spellcast)
				-- Update any counters after this successful spellcast.
				self:UpdateCounters(spellId, spellcast.start, spellcast.target)
				OvaleScore:ScoreSpell(spellId)
				Ovale.refreshNeeded[self_playerGUID] = true
			elseif not name then
				self:Debug("Warning: not channelling a spell.")
			else
				self:Debug("Warning: channelling unexpected spell %s", name)
			end
		else
			self:Debug("Warning: channelling spell %s (%d) without previous UNIT_SPELLCAST_SENT.", spell, spellId)
		end
		self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_START")
	end
end


function OvaleFuture:UNIT_SPELLCAST_CHANNEL_STOP(event, unitId, spell, rank, lineId, spellId)
	if (unitId == "player" or unitId == "pet") and not WHITE_ATTACK[spellId] then
		self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_STOP")
		self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
		local now = API_GetTime()
		-- Find the matching spellcast by name -- the line ID is always zero for channelled spells.
		local spellcast, index = self:GetSpellcast(spell, spellId, nil, now)
		if spellcast and spellcast.channel then
			self:Debug("Finished channelling spell %s (%d) queued at %s.", spell, spellId, spellcast.queued)
			spellcast.stop = now
			self:UpdateLastSpellcast(now, spellcast)
			-- Remove the finished spellcast from the spell queue.
			local targetGUID = spellcast.target
			tremove(self.queue, index)
			self_pool:Release(spellcast)
			Ovale.refreshNeeded[self_playerGUID] = true
			self:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, "hit")
		end
		self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_STOP")
	end
end

function OvaleFuture:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unitId, spell, rank, lineId, spellId)
	if (unitId == "player" or unitId == "pet") and not WHITE_ATTACK[spellId] then
		self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_UPDATE")
		self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
		local now = API_GetTime()
		-- Find the matching spellcast by name -- the line ID is always zero for channelled spells.
		local spellcast = self:GetSpellcast(spell, spellId, nil, now)
		if spellcast and spellcast.channel then
			local name, _, _, _, startTime, endTime = API_UnitChannelInfo(unitId)
			if name == spell then
				startTime = startTime / 1000
				endTime = endTime / 1000
				local delta = endTime - spellcast.stop
				spellcast.start = startTime
				spellcast.stop = endTime
				self:Debug("Updating channelled spell %s (%d) to ending = %s (+%s).", spell, spellId, endTime, delta)
				Ovale.refreshNeeded[self_playerGUID] = true
			elseif not name then
				self:Debug("Warning: not channelling a spell.")
			else
				self:Debug("Warning: delaying unexpected channelled spell %s.", name)
			end
		else
			self:Debug("Warning: no queued, channelled spell %s (%d) found to update.", spell, spellId)
		end
		self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_UPDATE")
	end
end

function OvaleFuture:UNIT_SPELLCAST_DELAYED(event, unitId, spell, rank, lineId, spellId)
	if (unitId == "player" or unitId == "pet") and not WHITE_ATTACK[spellId] then
		self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_DELAYED")
		self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
		local now = API_GetTime()
		local spellcast = self:GetSpellcast(spell, spellId, lineId, now)
		if spellcast then
			local name, _, _, _, startTime, endTime, _, castId = API_UnitCastingInfo(unitId)
			if lineId == castId and name == spell then
				startTime = startTime / 1000
				endTime = endTime / 1000
				local delta = endTime - spellcast.stop
				spellcast.start = startTime
				spellcast.stop = endTime
				self:Debug("Delaying spell %s (%d) to ending = %s (+%s).", spell, spellId, endTime, delta)
				Ovale.refreshNeeded[self_playerGUID] = true
			elseif not name then
				self:Debug("Warning: not casting a spell.")
			else
				self:Debug("Warning: delaying unexpected spell %s.", name)
			end
		else
			self:Debug("Warning: no queued spell %s (%d) found to delay.", spell, spellId)
		end
		self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_DELAYED")
	end
end

function OvaleFuture:UNIT_SPELLCAST_SENT(event, unitId, spell, rank, targetName, lineId)
	if (unitId == "player" or unitId == "pet") and not WHITE_ATTACK_NAME[spell] then
		self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_SENT")
		self:DebugTimestamp(event, unitId, spell, rank, targetName, lineId)
		local now = API_GetTime()
		local caster = OvaleGUID:UnitGUID(unitId)
		local spellcast = self_pool:Get()
		spellcast.lineId = lineId
		spellcast.caster = caster
		spellcast.spellName = spell
		spellcast.queued = now
		tinsert(self.queue, spellcast)
		if targetName == "" then
			self:Debug("Queueing (%d) spell %s with no target.", #self.queue, spell)
		else
			spellcast.targetName = targetName
			local targetGUID, nextGUID = OvaleGUID:NameGUID(targetName)
			if nextGUID then
				--[[
					There is more than one GUID with that name, so check if the target, focus,
					or mouseover have that name and set the spellcast target's GUID to that.
				--]]
				local name = OvaleGUID:UnitName("target")
				if name == targetName then
					targetGUID = OvaleGUID:UnitGUID("target")
				else
					name = OvaleGUID:UnitName("focus")
					if name == targetName then
						targetGUID = OvaleGUID:UnitGUID("focus")
					elseif API_UnitExists("mouseover") then
						name = API_UnitName("mouseover")
						if name == targetName then
							targetGUID = API_UnitGUID("mouseover")
						end
					end
				end
				spellcast.target = targetGUID
				self:Debug("Queueing (%d) spell %s to %s (possibly %s).", #self.queue, spell, targetName, targetGUID)
			else
				spellcast.target = targetGUID
				self:Debug("Queueing (%d) spell %s to %s (%s).", #self.queue, spell, targetName, targetGUID)
			end
		end
		--[[
			Save preliminary information into the spellcast.
			This will be overwritten for cast-time and channelled spells.
		--]]
		self:SaveSpellcastInfo(spellcast, now)
		self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_SENT")
	end
end

function OvaleFuture:UNIT_SPELLCAST_START(event, unitId, spell, rank, lineId, spellId)
	if (unitId == "player" or unitId == "pet") and not WHITE_ATTACK[spellId] then
		self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_START")
		self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
		local now = API_GetTime()
		local spellcast = self:GetSpellcast(spell, spellId, lineId, now)
		if spellcast then
			local name, _, _, _, startTime, endTime, _, castId = API_UnitCastingInfo(unitId)
			if lineId == castId and name == spell then
				startTime = startTime / 1000
				endTime = endTime / 1000
				spellcast.spellId = spellId
				spellcast.start = startTime
				spellcast.stop = endTime
				spellcast.channel = false
				local delta = now - spellcast.queued
				self:Debug("Casting spell %s (%d): start = %s (+%s), ending = %s.", spell, spellId, startTime, delta, endTime)
				local auraId, auraGUID = self:GetAuraFinish(spell, spellId, spellcast.target, now)
				if auraId and auraGUID then
					spellcast.auraId = auraId
					spellcast.auraGUID = auraGUID
					self:Debug("Spell %s (%d) will finish after updating aura %d on %s.", spell, spellId, auraId, auraGUID)
				end
				-- Update saved information in the spellcast to the current time.
				self:SaveSpellcastInfo(spellcast, now)
				OvaleScore:ScoreSpell(spellId)
				Ovale.refreshNeeded[self_playerGUID] = true
			elseif not name then
				self:Debug("Warning: not casting a spell.")
			else
				self:Debug("Warning: casting unexpected spell %s.", name)
			end
		else
			self:Debug("Warning: casting spell %s (%d) without previous sent data.", spell, spellId)
		end
		self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_START")
	end
end

function OvaleFuture:UNIT_SPELLCAST_SUCCEEDED(event, unitId, spell, rank, lineId, spellId)
	if (unitId == "player" or unitId == "pet") and not WHITE_ATTACK[spellId] then
		self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED")
		self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
		local now = API_GetTime()
		local spellcast, index = self:GetSpellcast(spell, spellId, lineId, now)
		if spellcast then
			local success = false
			if not spellcast.success and spellcast.start and spellcast.stop and not spellcast.channel then
				self:Debug("Succeeded casting spell %s (%d) at %s, now in flight.", spell, spellId, spellcast.stop)
				spellcast.success = now
				-- Take a more recent snapshot of the player stats for this cast-time spell.
				self:UpdateSpellcastSnapshot(spellcast, now)
				success = true
			else
				--[[
					This spell was an instant-cast spell, but check that it's not also a
					channelled spell.
				]]--
				local name = API_UnitChannelInfo(unitId)
				if not name then
					local now = API_GetTime()
					spellcast.spellId = spellId
					spellcast.start = now
					spellcast.stop = now
					spellcast.channel = false
					spellcast.success = now
					local delta = now - spellcast.queued
					self:Debug("Instant-cast spell %s (%d): start = %s (+%s).", spell, spellId, now, delta)
					local auraId, auraGUID = self:GetAuraFinish(spell, spellId, spellcast.target, now)
					if auraId and auraGUID then
						spellcast.auraId = auraId
						spellcast.auraGUID = auraGUID
						self:Debug("Spell %s (%d) will finish after updating aura %d on %s.", spell, spellId, auraId, auraGUID)
					end
					-- Update saved information in the spellcast to the current time.
					self:SaveSpellcastInfo(spellcast, now)
					OvaleScore:ScoreSpell(spellId)
					success = true
				else
					self:Debug("Succeeded casting spell %s (%d) but it is channelled.", spell, spellId)
				end
			end
			if success then
				local targetGUID = spellcast.target
				-- Cache the most recent spellcast information.
				self:UpdateLastSpellcast(now, spellcast)
				-- Update any counters after this successful spellcast.
				self:UpdateCounters(spellId, spellcast.stop, targetGUID)
				-- Some spells finish upon successful spellcast.
				local finished = false
				local finish = "miss"
				if not spellcast.targetName then
					-- If the spell has no target, then it finishes upon cast.
					self:Debug("Finished spell %s (%d) with no target queued at %s.", spell, spellId, spellcast.queued)
					finished = true
					finish = "hit"
				elseif targetGUID == self_playerGUID and OvaleSpellBook:IsHelpfulSpell(spellId) then
					-- If a helpful spell is cast by the player on the player, then it finishes upon cast.
					self:Debug("Finished helpful spell %s (%d) cast on player queued at %s.", spell, spellId, spellcast.queued)
					finished = true
					finish = "hit"
				end
				if finished then
					-- Remove the finished spellcast from the spell queue.
					tremove(self.queue, index)
					self_pool:Release(spellcast)
					Ovale.refreshNeeded[self_playerGUID] = true
					self:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish)
				end
			end
		else
			self:Debug("Warning: no queued spell %s (%d) found to successfully complete casting.", spell, spellId)
		end
		self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED")
	end
end

function OvaleFuture:Ovale_AuraAdded(event, atTime, guid, auraId, caster)
	if guid == self_playerGUID then
		self_timeAuraAdded = atTime
		-- Update snapshots in cached spellcasts.
		self:UpdateSpellcastSnapshot(self.lastGCDSpellcast, atTime)
		self:UpdateSpellcastSnapshot(self.lastOffGCDSpellcast, atTime)
	end
end

function OvaleFuture:UnitSpellcastEnded(event, unitId, spell, rank, lineId, spellId)
	if (unitId == "player" or unitId == "pet") and not WHITE_ATTACK[spellId] then
		self:StartProfiling("OvaleFuture_UnitSpellcastEnded")
		self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
		local now = API_GetTime()
		local spellcast, index = self:GetSpellcast(spell, spellId, lineId, now)
		if spellcast then
			self:Debug("End casting spell %s (%d) queued at %s due to %s.", spell, spellId, spellcast.queued, event)
			--[[
				Remove this spellcast only if it was not successful.
				Successful spellcasts wait for CLEU finishing events.
			--]]
			if not spellcast.success then
				tremove(self.queue, index)
				self_pool:Release(spellcast)
				Ovale.refreshNeeded[self_playerGUID] = true
			end
		elseif lineId then
			-- Suppress the warning spellcasts with a line ID of zero since those are thrown quite a lot.
			self:Debug("Warning: no queued spell %s (%d) found to end casting.", spell, spellId)
		end
		self:StopProfiling("OvaleFuture_UnitSpellcastEnded")
	end
end

--[[-------
	Methods
--]]-------

--[[
	Find the queued spellcast of the given spell.
	If the line ID is given, then match the oldest queued spellcast of that spell with the given line ID.
	Otherwise, match the the oldest queued spellcast of that spell.
--]]
function OvaleFuture:GetSpellcast(spell, spellId, lineId, atTime)
	self:StartProfiling("OvaleFuture_GetSpellcast")
	local spellcast, index
	if not lineId or lineId ~= "" then
		for i, sc in ipairs(self.queue) do
			if not lineId or sc.lineId == lineId then
				if spellId and sc.spellId == spellId then
					spellcast = sc
					index = i
					break
				elseif spell then
					local spellName = sc.spellName or OvaleSpellBook:GetSpellName(spellId)
					if spell == spellName then
						spellcast = sc
						index = i
						break
					end
				end
			end
		end
	end
	if spellcast then
		local spellName = spell or spellcast.spellName or OvaleSpellBook:GetSpellName(spellId)
		if spellcast.targetName then
			self:Debug("Found spellcast for %s to %s queued at %f.", spellName, spellcast.targetName, spellcast.queued)
		else
			self:Debug("Found spellcast for %s with no target queued at %f.", spellName, spellcast.queued)
		end
	end
	self:StopProfiling("OvaleFuture_GetSpellcast")
	return spellcast, index
end

--[[
	Return the aura ID of one of the auras, if any, that are added or refreshed by the spell
	and the GUID on which the aura appears.
--]]
function OvaleFuture:GetAuraFinish(spell, spellId, targetGUID, atTime)
	self:StartProfiling("OvaleFuture_GetAuraFinish")
	local auraId, auraGUID
	local si = OvaleData.spellInfo[spellId]
	if si and si.aura then
		for _, unitId in ipairs(SPELLCAST_AURA_ORDER) do
			for filter, auraList in pairs(si.aura[unitId]) do
				for id, spellData in pairs(auraList) do
					local verified, value, data = OvaleData:CheckSpellAuraData(id, spellData, atTime, targetGUID)
					if verified and (SPELLAURALIST_AURA_VALUE[value] or type(value) == "number" and value > 0) then
						auraId = id
						auraGUID = OvaleGUID:UnitGUID(unitId)
						break
					end
				end
				if auraId then break end
			end
			if auraId then break end
		end
	end
	self:StopProfiling("OvaleFuture_GetAuraFinish")
	return auraId, auraGUID
end

-- Register functions for saving and copying module-specific information into and from spellcasts.
function OvaleFuture:RegisterSpellcastInfo(mod)
	tinsert(self_modules, mod)
end

-- Unregister functions for saving and copying module-specific information into and from spellcasts.
function OvaleFuture:UnregisterSpellcastInfo(mod)
	for i = #self_modules, 1, -1 do
		if self_modules[i] == mod then
			tremove(self_modules, i)
		end
	end
end

-- Copy information from the spellcast into the destination table.
function OvaleFuture:CopySpellcastInfo(spellcast, dest)
	self:StartProfiling("OvaleFuture_CopySpellcastInfo")
	if spellcast.damageMultiplier then
		dest.damageMultiplier = spellcast.damageMultiplier
	end
	-- Copy the module-specific information from the spellcast to the destination.
	for _, mod in pairs(self_modules) do
		local func = mod.CopySpellcastInfo
		if func then
			func(mod, spellcast, dest)
		end
	end
	self:StopProfiling("OvaleFuture_CopySpellcastInfo")
end

-- Save information from the given time into the spellcast.
function OvaleFuture:SaveSpellcastInfo(spellcast, atTime)
	self:StartProfiling("OvaleFuture_SaveSpellcastInfo")
	self:Debug("    Saving information from %s to the spellcast for %s.", atTime, spellcast.spellName)
	if spellcast.spellId then
		spellcast.damageMultiplier = OvaleFuture:GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime)
	end
	-- Save the module-specific information into the spellcast.
	for _, mod in pairs(self_modules) do
		local func = mod.SaveSpellcastInfo
		if func then
			func(mod, spellcast, atTime)
		end
	end
	self:StopProfiling("OvaleFuture_SaveSpellcastInfo")
end

--[[
	Return the spell-specific damage multiplier using the information from
	SpellDamage{Buff,Debuff} declarations.

	NOTE: Mirrored in statePrototype below.
--]]
function OvaleFuture:GetDamageMultiplier(spellId, targetGUID, atTime)
	atTime = atTime or self["currentTime"] or API_GetTime()
	local damageMultiplier = 1
	local si = OvaleData.spellInfo[spellId]
	if si and si.aura and si.aura.damage then
		-- Get references to mirrored methods used.
		local CheckRequirements
		local GetAuraByGUID, IsActiveAura
		local auraModule, dataModule
		CheckRequirements, dataModule = self:GetMethod("CheckRequirements", OvaleData)
		GetAuraByGUID, auraModule = self:GetMethod("GetAuraByGUID", OvaleAura)
		IsActiveAura, auraModule = self:GetMethod("IsActiveAura", OvaleAura)

		for filter, auraList in pairs(si.aura.damage) do
			for auraId, spellData in pairs(auraList) do
				local index, multiplier
				if type(spellData) == "table" then
					-- Comma-separated value.
					multiplier = spellData[1]
					index = 2
				else
					multiplier = spellData
				end
				local verified
				if index then
					verified = CheckRequirements(dataModule, spellId, atTime, spellData, index, targetGUID)
				else
					verified = true
				end
				if verified then
					local aura = GetAuraByGUID(auraModule, self_playerGUID, auraId, filter)
					local isActiveAura = IsActiveAura(auraModule, aura, atTime)
					if isActiveAura then
						local siAura = OvaleData.spellInfo[auraId]
						-- If an aura does stacking damage, then it needs to set stacking=1.
						if siAura and siAura.stacking and siAura.stacking > 0 then
							multiplier = 1 + (multiplier - 1) * aura.stacks
						end
						damageMultiplier = damageMultiplier * multiplier
					end
				end
			end
		end
	end
	return damageMultiplier
end

--[[
	Update counters for this spellcast.

	NOTE: Mirrored in statePrototype below.
--]]
function OvaleFuture:UpdateCounters(spellId, atTime, targetGUID)
	local inccounter = OvaleData:GetSpellInfoProperty(spellId, atTime, "inccounter", targetGUID)
	if inccounter then
		local value = self.counter[inccounter] and self.counter[inccounter] or 0
		self.counter[inccounter] = value + 1
	end
	local resetcounter = OvaleData:GetSpellInfoProperty(spellId, atTime, "resetcounter", targetGUID)
	if resetcounter then
		self.counter[resetcounter] = 0
	end
end

--[[
	Returns true if the spell is active.
	An active spell is one that queued and has started casting.
--]]
function OvaleFuture:IsActive(spellId)
	for _, spellcast in ipairs(self.queue) do
		if spellcast.spellId == spellId and spellcast.start then
			return true
		end
	end
	return false
end
-- Deprecated function OvaleFuture:InFlight() aliased to "IsActive".
OvaleFuture.InFlight = OvaleFuture.IsActive

-- Return the most recent successful spellcast.
function OvaleFuture:LastInFlightSpell()
	local spellcast
	if self.lastGCDSpellcast.success then
		spellcast = self.lastGCDSpellcast
	end
	for i = #self.queue, 1, -1 do
		local sc = self.queue[i]
		if sc.success then
			-- Use the more recently successful spellcast.
			if not spellcast or spellcast.success < sc.success then
				spellcast = sc
			end
			break
		end
	end
	return spellcast
end

-- Return the most recent spellcast sent.  
-- Required when the UNIT_AURA event fires before the UNIT_SPELLCAST_SUCCEEDED event
function OvaleFuture:LastSpellSent()
	local spellcast = nil
	if self.lastGCDSpellcast.success then
		spellcast = self.lastGCDSpellcast
	end
	for i = #self.queue, 1, -1 do
		local sc = self.queue[i]
		-- If spell in queue was successful
		if sc.success then 
			-- Use the more recently successful spellcast.
			if not spellcast or (spellcast.success and spellcast.success < sc.success) or (not spellcast.success and spellcast.queued < sc.success) then
				spellcast = sc
			end
		-- If spell in queue was not (yet) successful and not a cast time spell
		elseif not sc.start and not sc.stop then
			-- If current most recent spell was successful, check next queued spell against the success time
			if spellcast.success and spellcast.success < sc.queued then
				spellcast = sc
			-- If current most recent spell was not (yet) successful, check next queued spell against the queued time
			elseif spellcast.queued < sc.queued then			
				spellcast = sc
			end
		end
	end
	return spellcast
end

--[[
	Apply the effects of any active spells to the simulator state.
--]]
function OvaleFuture:ApplyInFlightSpells(state)
	self:StartProfiling("OvaleFuture_ApplyInFlightSpells")
	local now = API_GetTime()
	local index = 1
	while index <= #self.queue do
		local spellcast = self.queue[index]
		if spellcast.stop then
			local isValid = false
			local description
			if now < spellcast.stop then
				-- Spell is still being cast or channelled.
				isValid = true
				description = spellcast.channel and "channelling" or "being cast"
			elseif now < spellcast.stop + 5 then
				-- Valid spells should finish within 5 seconds of successful spellcast.
				isValid = true
				description = "in flight"
			end
			if isValid then
				if spellcast.target then
					state:Log("Active spell %s (%d) is %s to %s (%s), now=%f, endCast=%f", spellcast.spellName, spellcast.spellId, description, spellcast.targetName, spellcast.target, now, spellcast.stop)
				else
					state:Log("Active spell %s (%d) is %s, now=%f, endCast=%f", spellcast.spellName, spellcast.spellId, description, now, spellcast.stop)
				end
				state:ApplySpell(spellcast.spellId, spellcast.target, spellcast.start, spellcast.stop, spellcast.channel, spellcast)
			else
				if spellcast.target then
					self:Debug("Warning: removing active spell %s (%d) to %s (%s) that should have finished.", spellcast.spellName, spellcast.spellId, spellcast.targetName, spellcast.target)
				else
					self:Debug("Warning: removing active spell %s (%d) that should have finished.", spellcast.spellName, spellcast.spellId)
				end
				tremove(self.queue, index)
				self_pool:Release(spellcast)
				-- Decrement current index since item was removed and rest of items shifted up.
				index = index - 1
			end
		end
		-- Advance to the next spellcast.
		index = index + 1
	end
	self:StopProfiling("OvaleFuture_ApplyInFlightSpells")
end

-- Cache spellcast as the most recent one.
function OvaleFuture:UpdateLastSpellcast(atTime, spellcast)
	self:StartProfiling("OvaleFuture_UpdateLastSpellcast")
	-- Update the time that this spell was most recently cast.
	self.lastCastTime[spellcast.spellId] = atTime
	if spellcast.offgcd then
		self:Debug("    Caching spell %s (%d) as most recent off-GCD spellcast.", spellcast.spellName, spellcast.spellId)
		for k, v in pairs(spellcast) do
			self.lastOffGCDSpellcast[k] = v
		end
		self.lastSpellcast = self.lastOffGCDSpellcast
	else
		self:Debug("    Caching spell %s (%d) as most recent GCD spellcast.", spellcast.spellName, spellcast.spellId)
		for k, v in pairs(spellcast) do
			self.lastGCDSpellcast[k] = v
		end
		self.lastSpellcast = self.lastGCDSpellcast
	end
	self:StopProfiling("OvaleFuture_UpdateLastSpellcast")
end

--[[
	If any auras have been added on the player in a small window of time after
	a spell was cast, then take a more recent snapshot of the player stats.
	This is needed to see any auras that were applied at the same time as the
	spellcast, e.g., potions or other on-use abilities or items.
--]]
function OvaleFuture:UpdateSpellcastSnapshot(spellcast, atTime)
	if spellcast.queued and (not spellcast.snapshotTime or (spellcast.snapshotTime < atTime and atTime < spellcast.stop + 1)) then
		if spellcast.targetName then
			self:Debug("    Updating to snapshot from %s for spell %s to %s (%s) queued at %s.", atTime, spellcast.spellName, spellcast.targetName, spellcast.target, spellcast.queued)
		else
			self:Debug("    Updating to snapshot from %s for spell %s with no target queued at %s.", atTime, spellcast.spellName, spellcast.queued)
		end
		OvalePaperDoll:UpdateSnapshot(spellcast, true)
		if spellcast.spellId then
			spellcast.damageMultiplier = OvaleFuture:GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime)
			if spellcast.damageMultiplier ~= 1 then
				self:Debug("        persistent multiplier = %f", spellcast.damageMultiplier)
			end
		end
	end
end
--</public-static-methods>


--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleFuture.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleFuture.statePrototype
--</private-static-properties>

--<state-properties>
-- The in-combat state of the player.
statePrototype.inCombat = nil
-- The time that combat began.
statePrototype.combatStartTime = nil
-- The current time in the simulator.
statePrototype.currentTime = nil
-- The spell being cast in the simulator.
statePrototype.currentSpellId = nil
-- The starting cast time of the spell being cast in the simulator.
statePrototype.startCast = nil
-- The ending cast time of the spell being cast in the simulator.
statePrototype.endCast = nil
-- The time at which the next GCD spell can be cast in the simulator.
statePrototype.nextCast = nil
-- The most recent time the spell was cast in the simulator.
statePrototype.lastCast = nil
-- Whether the spell being cast in the simulator is a channelled spell.
statePrototype.channel = nil
-- The previous spell cast in the simulator.
statePrototype.lastSpellId = nil
-- The previous GCD spell cast in the simulator.
statePrototype.lastGCDSpellId = nil
statePrototype.lastGCDSpellIds = {}
-- The previous off-GCD spell cast in the simulator.
statePrototype.lastOffGCDSpellId = nil
-- Counters for spells cast in the simulator.
statePrototype.counter = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleFuture:InitializeState(state)
	state.lastCast = {}
	state.counter = {}
end

-- Reset the state to the current conditions.
function OvaleFuture:ResetState(state)
	self:StartProfiling("OvaleFuture_ResetState")
	local now = API_GetTime()
	state.currentTime = now
	state:Log("Reset state with current time = %f", state.currentTime)

	state.inCombat = self.inCombat
	state.combatStartTime = self.combatStartTime or 0

	state.nextCast = now
	local reason = ""
	local start, duration = OvaleCooldown:GetGlobalCooldown(now)
	if start and start > 0 then
		-- The GCD is active, so adjust the next cast time to the end of the GCD.
		local ending = start + duration
		if state.nextCast < ending then
			state.nextCast = ending
			reason = " (waiting for GCD)"
		end
	end

	local lastGCDSpellcastFound, lastOffGCDSpellcastFound, lastSpellcastFound
	for i = #self.queue, 1, -1 do
		local spellcast = self.queue[i]
		if spellcast.spellId and spellcast.start then
			state:Log("    Found cast %d of spell %s (%d), start = %s, stop = %s.", i, spellcast.spellName, spellcast.spellId, spellcast.start, spellcast.stop)
			if not lastSpellcastFound then
				state.lastSpellId = spellcast.spellId
				if spellcast.start and spellcast.stop and spellcast.start <= now and now < spellcast.stop then
					-- This spell is being actively cast.
					state.currentSpellId = spellcast.spellId
					state.startCast = spellcast.start
					state.endCast = spellcast.stop
					state.channel = spellcast.channel
				end
				lastSpellcastFound = true
			end
			if not lastGCDSpellcastFound and not spellcast.offgcd then
				state:PushGCDSpellId(spellcast.spellId)
				if spellcast.stop and state.nextCast < spellcast.stop then
					--[[
						The most recent GCD spellcast is still being cast, so adjust the next
						cast time to the end of the spellcast.
					--]]
					state.nextCast = spellcast.stop
					reason = " (waiting for spellcast)"
				end
				lastGCDSpellcastFound = true
			end
			if not lastOffGCDSpellcastFound and spellcast.offgcd then
				state.lastOffGCDSpellId = spellcast.spellId
				lastOffGCDSpellcastFound = true
			end
		end
		if lastGCDSpellcastFound and lastOffGCDSpellcastFound and lastSpellcastFound then
			break
		end
	end

	if not lastSpellcastFound then
		local spellcast = self.lastSpellcast
		if spellcast then
			state.lastSpellId = spellcast.spellId
			if spellcast.start and spellcast.stop and spellcast.start <= now and now < spellcast.stop then
				-- The most recent spellcast is still being cast.
				state.currentSpellId = spellcast.spellId
				state.startCast = spellcast.start
				state.endCast = spellcast.stop
				state.channel = spellcast.channel
			end
		end
	end
	if not lastGCDSpellcastFound then
		local spellcast = self.lastGCDSpellcast
		if spellcast then
			state.lastGCDSpellId = spellcast.spellId
			if spellcast.stop and state.nextCast < spellcast.stop then
				--[[
					The most recent GCD spellcast is still being cast, so adjust the next
					cast time to the end of the spellcast.
				--]]
				state.nextCast = spellcast.stop
				reason = " (waiting for spellcast)"
			end
		end
	end
	if not lastOffGCDSpellcastFound then
		local spellcast = self.lastOffGCDSpellcast
		if spellcast then
			state.lastOffGCDSpellId = spellcast.spellId
		end
	end
	state:Log("    lastSpellId = %s, lastGCDSpellId = %s, lastOffGCDSpellId = %s", state.lastSpellId, state.lastGCDSpellId, state.lastOffGCDSpellId)
	state:Log("    nextCast = %f%s", state.nextCast, reason)

	wipe(state.lastCast)
	for k, v in pairs(self.counter) do
		state.counter[k] = v
	end

	self:StopProfiling("OvaleFuture_ResetState")
end

-- Release state resources prior to removing from the simulator.
function OvaleFuture:CleanState(state)
	for k in pairs(state.lastCast) do
		state.lastCast[k] = nil
	end
	for k in pairs(state.counter) do
		state.counter[k] = nil
	end
end

-- Apply the effects of the spell at the start of the spellcast.
function OvaleFuture:ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, channel, spellcast)
	self:StartProfiling("OvaleFuture_ApplySpellStartCast")
	if channel then
		-- Channelled spells are successful when they start casting.
		state:UpdateCounters(spellId, startCast, targetGUID)
	end
	self:StopProfiling("OvaleFuture_ApplySpellStartCast")
end

-- Apply the effects of the spell when the spellcast completes.
function OvaleFuture:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, channel, spellcast)
	self:StartProfiling("OvaleFuture_ApplySpellAfterCast")
	if not channel then
		-- Cast-time and instant-cast spells are successful when they finish casting.
		state:UpdateCounters(spellId, endCast, targetGUID)
	end
	self:StopProfiling("OvaleFuture_ApplySpellAfterCast")
end
--</public-static-methods>

--<state-methods>
-- Return the value of the spell counter in the simulator.
statePrototype.GetCounter = function(state, id)
	return state.counter[id] or 0
end
-- Deprecated.
statePrototype.GetCounterValue = statePrototype.GetCounter

-- Return the time that a spell was last cast in the simulator.
statePrototype.TimeOfLastCast = function(state, spellId)
	return state.lastCast[spellId] or OvaleFuture.lastCastTime[spellId] or 0
end

-- Return whether the player is currently channeling a spell in the simulator.
statePrototype.IsChanneling = function(state, atTime)
	atTime = atTime or state.currentTime
	return state.channel and (atTime < state.endCast)
end

--[[
	Cast a spell in the simulator and advance the state of the simulator.

	Parameters:
		spellId		The ID of the spell to cast.
		targetGUID	The GUID of the target of the spellcast.
		startCast	The time at the start of the spellcast.
		endCast		The time at the end of the spellcast.
		channel		The spell is a channelled spell.
		spellcast	(optional) Table of spellcast information, including a snapshot of player's stats.
--]]
do
	local staticSpellcast = {}


	statePrototype.PushGCDSpellId = function(state, spellId)
		if state.lastGCDSpellId then 
			tinsert(state.lastGCDSpellIds, state.lastGCDSpellId)
			if #state.lastGCDSpellIds > 5 then
				tremove(state.lastGCDSpellIds, 1)
			end
		end
		state.lastGCDSpellId = spellId
	end

	statePrototype.ApplySpell = function(state, spellId, targetGUID, startCast, endCast, channel, spellcast)
		OvaleFuture:StartProfiling("OvaleFuture_state_ApplySpell")
		if spellId then
			if not targetGUID then
				targetGUID = Ovale.playerGUID
			end
			-- Handle missing parameters.
			local castTime
			if startCast and endCast then
				castTime = endCast - startCast
			else
				castTime = OvaleSpellBook:GetCastTime(spellId) or 0
				startCast = startCast or state.nextCast
				endCast = endCast or (startCast + castTime)
			end
			if not spellcast then
				spellcast = staticSpellcast
				wipe(spellcast)
				spellcast.caster = self_playerGUID
				spellcast.spellId = spellId
				spellcast.spellName = OvaleSpellBook:GetSpellName(spellId)
				spellcast.target = targetGUID
				spellcast.targetName = OvaleGUID:GUIDName(targetGUID)
				spellcast.start = startCast
				spellcast.stop = endCast
				spellcast.channel = channel
				-- Save the current snapshot into the spellcast.
				state:UpdateSnapshot(spellcast)
				-- Save the module-specific information into the spellcast.
				local atTime = channel and startCast or endCast
				for _, mod in pairs(self_modules) do
					local func = mod.SaveSpellcastInfo
					if func then
						func(mod, spellcast, atTime, state)
					end
				end
			end

			-- Update the latest spell cast in the simulator.
			state.lastSpellId = spellId
			state.startCast = startCast
			state.endCast = endCast
			state.lastCast[spellId] = endCast
			state.channel = channel

			-- Update the GCD-related spell information in the simulator.
			local gcd = state:GetGCD(spellId, startCast, targetGUID)
			local nextCast = (castTime > gcd) and endCast or (startCast + gcd)
			if state.nextCast < nextCast then
				state.nextCast = nextCast
			end
			if gcd > 0 then
				state:PushGCDSpellId(spellId)
			else
				state.lastOffGCDSpellId = spellId
			end

			--[[
				Set the current time in the simulator to *slightly* after the start of
				the current cast (to prevent weird edge cases), or to now if in the past.
			--]]
			local now = API_GetTime()
			if startCast >= now then
				state.currentTime = startCast + SIMULATOR_LAG
			else
				state.currentTime = now
			end

			state:Log("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, state.currentTime, nextCast, endCast, targetGUID)

			--[[
				Update the combat state so this condition can be checked in other state prototype methods.
				This condition isn't quite right because casting a harmful spell at a target doesn't always
				put the player into combat.
			--]]
			if not state.inCombat and OvaleSpellBook:IsHarmfulSpell(spellId) then
				state.inCombat = true
				if channel then
					state.combatStartTime = startCast
				else
					state.combatStartTime = endCast
				end
			end

			--[[
				Apply the effects of the spellcast.
					1. Effects when the spell starts casting.
					2. Effects when the spell has finished casting.
					3. Effects when the spell lands on its target.
			--]]
			-- If the spellcast has already started, then the effects have already occurred.
			if startCast > now then
				OvaleState:InvokeMethod("ApplySpellStartCast", state, spellId, targetGUID, startCast, endCast, channel, spellcast)
			end
			-- If the spellcast has already ended, then the effects have already occurred.
			if endCast > now then
				OvaleState:InvokeMethod("ApplySpellAfterCast", state, spellId, targetGUID, startCast, endCast, channel, spellcast)
			end
			OvaleState:InvokeMethod("ApplySpellOnHit", state, spellId, targetGUID, startCast, endCast, channel, spellcast)
		end
		OvaleFuture:StopProfiling("OvaleFuture_state_ApplySpell")
	end
end

-- Mirrored methods.
statePrototype.GetDamageMultiplier = OvaleFuture.GetDamageMultiplier
statePrototype.UpdateCounters = OvaleFuture.UpdateCounters
--</state-methods>
