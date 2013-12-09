--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- The travelling missiles or spells that have been cast but whose effects were not still not applied

local _, Ovale = ...
local OvaleFuture = Ovale:NewModule("OvaleFuture", "AceEvent-3.0")
Ovale.OvaleFuture = OvaleFuture

--<private-static-properties>
local OvalePool = Ovale.OvalePool

-- Forward declarations for module dependencies.
local OvaleAura = nil
local OvaleComboPoints = nil
local OvaleData = nil
local OvaleGUID = nil
local OvalePaperDoll = nil
local OvalePower = nil
local OvaleScore = nil
local OvaleSpellBook = nil
local OvaleState = nil

local ipairs = ipairs
local pairs = pairs
local select = select
local tinsert = table.insert
local tostring = tostring
local tremove = table.remove
local API_GetTime = GetTime
local API_UnitCastingInfo = UnitCastingInfo
local API_UnitChannelInfo = UnitChannelInfo
local API_UnitGUID = UnitGUID
local API_UnitName = UnitName

-- Player's GUID.
local self_guid = nil

-- The spells that the player is casting or has cast but are still in-flight toward their targets.
local self_activeSpellcast = {}
-- self_lastSpellcast[targetGUID][spellId] is the most recent spell that has landed successfully on the target.
local self_lastSpellcast = {}
local self_pool = OvalePool("OvaleFuture_pool")
do
	self_pool.Clean = function(self, spellcast)
		-- Release reference-counted snapshot before wiping.
		if spellcast.snapshot then
			OvalePaperDoll:ReleaseSnapshot(spellcast.snapshot)
		end
	end
end

-- Used to track the most recent spellcast started with UNIT_SPELLCAST_SENT.
local self_lastLineID = nil
local self_lastSpell = nil
local self_lastTarget = nil

-- Time at which a player aura was last added.
local self_timeAuraAdded = nil

local OVALE_UNKNOWN_GUID = 0

-- These CLEU events are eventually received after a successful spellcast.
local OVALE_CLEU_SPELLCAST_RESULTS = {
	SPELL_AURA_APPLIED = true,
	SPELL_AURA_REFRESH = true,
	SPELL_CAST_SUCCESS = true,
	SPELL_CAST_FAILED = true,
	SPELL_DAMAGE = true,
	SPELL_MISSED = true,
}
--</private-static-properties>

--<public-static-properties>
--spell counter (see Counter function)
OvaleFuture.counter = {}
-- Most recent spellcast.
OvaleFuture.lastSpellcast = nil
-- Debugging: spells to trace
OvaleFuture.traceSpellList = nil
--</public-static-properties>

--<private-static-methods>
local function TracePrintf(spellId, ...)
	local self = OvaleFuture
	if self.traceSpellList then
		local name = spellId
		if type(spellId) == "number" then
			name = OvaleSpellBook:GetSpellName(spellId)
		end
		if self.traceSpellList[spellId] or self.traceSpellList[name] then
			local now = API_GetTime()
			Ovale:Printf("[trace] @%f %s", now, Ovale:Format(...))
		end
	end
end

--[[
	Return the spell-specific damage multiplier using the information from
	SpellDamage{Buff,Debuff} declarations.  This doesn't include the base
	damage multiplier of the character kept in snapshots.

	auraObject is an object that provides the following two methods:

		GetAura(unitId, auraId, filter, mine)
		IsActiveAura(aura, atTime)
--]]
local function GetDamageMultiplier(spellId, auraObject)
	auraObject = auraObject or OvaleAura
	local damageMultiplier = 1
	local si = OvaleData.spellInfo[spellId]
	if si and si.damageAura then
		for filter, auraList in pairs(si.damageAura) do
			for auraId, multiplier in pairs(auraList) do
				local aura = auraObject:GetAura("player", auraId, filter)
				if auraObject:IsActiveAura(aura) then
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
	return damageMultiplier
end

local function AddSpellToQueue(spellId, lineId, startTime, endTime, channeled, allowRemove)
	local self = OvaleFuture
	local spellcast = self_pool:Get()
	spellcast.spellId = spellId
	spellcast.lineId = lineId
	spellcast.start = startTime
	spellcast.stop = endTime
	spellcast.channeled = channeled
	spellcast.allowRemove = allowRemove

	-- Set the target from the data taken from UNIT_SPELLCAST_SENT if it's the same spellcast.
	local spellName = OvaleSpellBook:GetSpellName(spellId)
	if lineId == self_lastLineID and spellName == self_lastSpell then
		spellcast.target = self_lastTarget
	else
		spellcast.target = API_UnitGUID("target")
	end
	TracePrintf(spellId, "    AddSpellToQueue: %s (%d), lineId=%d, startTime=%f, endTime=%f, target=%s",
		spellName, spellId, lineId, startTime, endTime, spellcast.target)

	-- Snapshot the current stats for the spellcast.
	spellcast.snapshot = OvalePaperDoll:GetSnapshot()
	spellcast.damageMultiplier = GetDamageMultiplier(spellId)

	local si = OvaleData.spellInfo[spellId]
	if si then
		if si.buffnocd then
			local now = API_GetTime()
			local aura = OvaleAura:GetAura("player", si.buffnocd)
			if OvaleAura:IsActiveAura(aura) then
				spellcast.nocd = true
			end
		end

		-- Save the number of combo points used if this spell is a finisher.
		if si.combo == 0 then
			if OvaleComboPoints.combo > 0 then
				spellcast.combo = OvaleComboPoints.combo
			end
		end

		-- Save the number of holy power used if this spell is a finisher.
		if si.holy == 0 then
			if OvalePower.power.holy > 0 then
				spellcast.holy = OvalePower.power.holy
			end
		end

		-- Track one of the auras, if any, that are added or refreshed by this spell.
		-- This helps to later identify whether the spellcast succeeded by noting when
		-- the aura is applied or refreshed.
		if si.aura then
			for target, auraTable in pairs(si.aura) do
				for filter, auraList in pairs(auraTable) do
					for auraId, spellData in pairs(auraList) do
						if spellData and type(spellData) == "number" and spellData > 0 then
							spellcast.auraId = auraId
							if target == "player" then
								spellcast.removeOnSuccess = true
							end
							break
						end
					end
				end
			end
		end

		-- Increase or reset any counters used by the Counter() condition.
		if si.resetcounter then
			self.counter[si.resetcounter] = 0
		end
		if si.inccounter then
			local prev = self.counter[si.inccounter] or 0
			self.counter[si.inccounter] = prev + 1
		end
	else
		spellcast.removeOnSuccess = true
	end
	tinsert(self_activeSpellcast, spellcast)

	OvaleScore:ScoreSpell(spellId)
	Ovale.refreshNeeded["player"] = true
end

local function RemoveSpellFromQueue(spellId, lineId)
	local self = OvaleFuture
	for index, spellcast in ipairs(self_activeSpellcast) do
		if spellcast.lineId == lineId then
			TracePrintf(spellId, "    RemoveSpellFromQueue: %s (%d)", OvaleSpellBook:GetSpellName(spellId), spellId)
			tremove(self_activeSpellcast, index)
			self_pool:Release(spellcast)
			break
		end
	end
	Ovale.refreshNeeded["player"] = true
end

-- UpdateLastSpellcast() is called at the end of the event handler for OVALE_CLEU_SPELLCAST_RESULTS[].
-- It saves the given spellcast as the most recent one on its target and ensures that the spellcast
-- snapshot values are correctly adjusted for buffs that are added or cleared simultaneously with the
-- spellcast.
local function UpdateLastSpellcast(spellcast)
	local self = OvaleFuture
	local targetGUID = spellcast.target
	local spellId = spellcast.spellId
	if targetGUID and spellId then
		if not self_lastSpellcast[targetGUID] then
			self_lastSpellcast[targetGUID] = {}
		end
		local oldSpellcast = self_lastSpellcast[targetGUID][spellId]
		if oldSpellcast then
			self_pool:Release(oldSpellcast)
		end
		self_lastSpellcast[targetGUID][spellId] = spellcast
		self.lastSpellcast = spellcast

		--[[
			If any auras have been added between the start of the spellcast and this event,
			then take a more recent snapshot of the player stats for this spellcast.

			This is needed to see any auras that were applied at the same time as the
			spellcast, e.g., potions or other on-use abilities or items.
		--]]
		if self_timeAuraAdded then
			if self_timeAuraAdded >= spellcast.start and self_timeAuraAdded - spellcast.stop < 1 then
				OvalePaperDoll:UpdateSnapshot(spellcast.snapshot)
				spellcast.damageMultiplier = GetDamageMultiplier(spellId)
				TracePrintf(spellId, "    Updated spell info for %s (%d) to snapshot from %f.",
					OvaleSpellBook:GetSpellName(spellId), spellId, spellcast.snapshot.snapshotTime)
			end
		end
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleFuture:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
	OvaleComboPoints = Ovale.OvaleComboPoints
	OvaleData = Ovale.OvaleData
	OvaleGUID = Ovale.OvaleGUID
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvalePower = Ovale.OvalePower
	OvaleScore = Ovale.OvaleScore
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleState = Ovale.OvaleState
end

function OvaleFuture:OnEnable()
	self_guid = API_UnitGUID("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterMessage("Ovale_AuraAdded")
	self:RegisterMessage("Ovale_InactiveUnit")
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvaleFuture:OnDisable()
	OvaleState:UnregisterState(self)
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:UnregisterEvent("UNIT_SPELLCAST_SENT")
	self:UnregisterEvent("UNIT_SPELLCAST_START")
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:UnregisterMessage("Ovale_AuraAdded")
	self:UnregisterMessage("Ovale_InactiveUnit")
	self:PLAYER_ENTERING_WORLD("OnDisable")
	self_pool:Drain()
end

function OvaleFuture:PLAYER_ENTERING_WORLD(event)
	-- Empty out self_lastSpellcast.
	for guid in pairs(self_lastSpellcast) do
		self:Ovale_InactiveUnit(event, guid)
	end
end

function OvaleFuture:PLAYER_REGEN_ENABLED(event)
	self_pool:Drain()
end

function OvaleFuture:Ovale_AuraAdded(event, timestamp, guid, spellId, caster)
	if guid == self_guid then
		self_timeAuraAdded = timestamp
	end
end

function OvaleFuture:Ovale_InactiveUnit(event, guid)
	-- Remove spellcasts for inactive units.
	local spellTable = self_lastSpellcast[guid]
	if spellTable then
		for spellId, spellcast in pairs(spellTable) do
			spellTable[spellId] = nil
			self_pool:Release(spellcast)
		end
		self_lastSpellcast[guid] = nil
	end
end

function OvaleFuture:UNIT_SPELLCAST_CHANNEL_START(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		local startTime, endTime = select(5, API_UnitChannelInfo("player"))
		TracePrintf(spellId, "%s: %d, lineId=%d, startTime=%f, endTime=%f",
			event, spellId, lineId, startTime, endTime)
		AddSpellToQueue(spellId, lineId, startTime/1000, endTime/1000, true, false)
	end
end

function OvaleFuture:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		TracePrintf(spellId, "%s: %d, lineId=%d", event, spellId, lineId)
		RemoveSpellFromQueue(spellId, lineId)
	end
end

--Called when a spell started its cast
function OvaleFuture:UNIT_SPELLCAST_START(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		local startTime, endTime = select(5, API_UnitCastingInfo("player"))
		TracePrintf(spellId, "%s: %d, lineId=%d, startTime=%f, endTime=%f",
			event, spellId, lineId, startTime, endTime)
		AddSpellToQueue(spellId, lineId, startTime/1000, endTime/1000, false, false)
	end
end

--Called if the player interrupted early his cast
function OvaleFuture:UNIT_SPELLCAST_INTERRUPTED(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		TracePrintf(spellId, "%s: %d, lineId=%d", event, spellId, lineId)
		RemoveSpellFromQueue(spellId, lineId)
	end
end

-- UNIT_SPELLCAST_SENT is triggered when the spellcast is sent to the server.
-- This is sent before all other UNIT_SPELLCAST_* events for the same spellcast.
function OvaleFuture:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target, lineId)
	if unit == "player" then
		self_lastLineID = lineId
		self_lastSpell = spell

		-- UNIT_TARGET may arrive out of order with UNIT_SPELLCAST* events, so we can't track
		-- the target in an event handler.
		if target then
			if target == API_UnitName("target") then
				self_lastTarget = API_UnitGUID("target")
			else
				self_lastTarget = OvaleGUID:GetGUIDForName(target)
			end
		else
			self_lastTarget = OVALE_UNKNOWN_GUID
		end
		TracePrintf(spell, "%s: %s on %s, lineId=%d", event, spell, self_lastTarget, lineId)
	end
end

-- UNIT_SPELLCAST_SUCCEEDED is triggered when a spellcast successfully completes.
--[[
	For a cast-time spell:
		UNIT_SPELLCAST_SENT
		UNIT_SPELLCAST_START
		UNIT_SPELLCAST_SUCCEEDED
	For an instant-cast spell:
		UNIT_SPELLCAST_SENT
		UNIT_SPELLCAST_SUCCEEDED
]]--
function OvaleFuture:UNIT_SPELLCAST_SUCCEEDED(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		TracePrintf(spellId, "%s: %d, lineId=%d", event, spellId, lineId)

		-- Search for a cast-time spell matching this spellcast that was added by UNIT_SPELLCAST_START.
		for _, spellcast in ipairs(self_activeSpellcast) do
			if spellcast.lineId == lineId then
				spellcast.allowRemove = true
				-- Take a more recent snapshot of the player stats for this cast-time spell.
				if spellcast.snapshot then
					OvalePaperDoll:ReleaseSnapshot(spellcast.snapshot)
				end
				spellcast.snapshot = OvalePaperDoll:GetSnapshot()
				spellcast.damageMultiplier = GetDamageMultiplier(spellId)
				return
			end
		end

		--[[
			This spell was an instant-cast spell, but only add it to the queue if it's not part
			of a channeled spell.  A channeled spell is actually two separate spells, an
			instant-cast portion and a channel portion, with different line IDs.  The instant-cast
			triggers UNIT_SPELLCAST_SENT and UNIT_SPELLCAST_SUCCEEDED, while the channel triggers
			UNIT_SPELLCAST_CHANNEL_START and UNIT_SPELLCAST_CHANNEL_STOP.
		]]--
		if not API_UnitChannelInfo("player") then
			local now = API_GetTime()
			AddSpellToQueue(spellId, lineId, now, now, false, true)
		end
	end
end

function OvaleFuture:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)

	--[[
	Sequence of events:
	- casting a spell that damages
	SPELL_CAST_START
	SPELL_DAMAGE
	- casting a spell that misses
	SPELL_CAST_START
	SPELL_MISSED
	- casting a spell then interrupting it
	SPELL_CAST_START
	SPELL_CAST_FAILED
	- casting an instant damaging spell
	SPELL_CAST_SUCCESS
	SPELL_DAMAGE
	- chanelling a damaging spell
	SPELL_CAST_SUCCESS
	SPELL_AURA_APPLIED
	SPELL_PERIODIC_DAMAGE
	SPELL_PERIODIC_DAMAGE
	SPELL_PERIODIC_DAMAGE
	(interruption does not generate an event)
	- refreshing a buff
	SPELL_AURA_REFRESH
	SPELL_CAST_SUCCESS
	- removing a buff
	SPELL_AURA_REMOVED
	- casting a buff
	SPELL_AURA_APPLIED
	SPELL_CAST_SUCCESS
	-casting a DOT that misses
	SPELL_CAST_SUCCESS
	SPELL_MISSED
	- casting a DOT that damages
	SPELL_CAST_SUCESS
	SPELL_AURA_APPLIED
	SPELL_PERIODIC_DAMAGE
	SPELL_PERIODIC_DAMAGE
	]]--

	-- Called when a missile reaches or misses its target
	if sourceGUID == self_guid then
		if OVALE_CLEU_SPELLCAST_RESULTS[event] then
			local spellId, spellName = select(12, ...)
			TracePrintf(spellId, "%s: %s (%d)", event, spellName, spellId)
			for index, spellcast in ipairs(self_activeSpellcast) do
				if spellcast.allowRemove and (spellcast.spellId == spellId or spellcast.auraId == spellId) then
					if not spellcast.channeled and (spellcast.removeOnSuccess or event ~= "SPELL_CAST_SUCCESS") then
						TracePrintf(spellId, "    Spell finished: %s (%d)", spellName, spellId)
						tremove(self_activeSpellcast, index)
						UpdateLastSpellcast(spellcast)
						Ovale.refreshNeeded["player"] = true
					end
					break
				end
			end
		end
	end
end

-- Apply the effects of spells that are being cast or are in flight, allowing us to
-- ignore lag or missile travel time.
function OvaleFuture:ApplyInFlightSpells(state)
	local now = API_GetTime()
	local index = 0
	while true do
		index = index + 1
		if index > #self_activeSpellcast then return end

		local spellcast = self_activeSpellcast[index]
		Ovale:Logf("now = %f, spellId = %d, endCast = %f", now, spellcast.spellId, spellcast.stop)
		if now - spellcast.stop < 5 then
			state:ApplySpell(spellcast.spellId, spellcast.target, spellcast.start, spellcast.stop, spellcast.stop, spellcast.channeled, spellcast.nocd, spellcast)
		else
			tremove(self_activeSpellcast, index)
			self_pool:Release(spellcast)
			-- Decrement current index since item was removed and rest of items shifted up.
			index = index - 1
		end
	end
end

function OvaleFuture:LastInFlightSpell()
	if #self_activeSpellcast > 0 then
		return self_activeSpellcast[#self_activeSpellcast]
	end
	return self.lastSpellcast
end

function OvaleFuture:UpdateSnapshotFromSpellcast(dest, spellcast)
	if dest.snapshot then
		OvalePaperDoll:ReleaseSnapshot(dest.snapshot)
	end
	if spellcast.snapshot then
		dest.snapshot = OvalePaperDoll:GetSnapshot(spellcast.snapshot)
	end
	if spellcast.damageMultiplier then
		dest.damageMultiplier = spellcast.damageMultiplier
	end
	if spellcast.combo then
		dest.combo = spellcast.combo
	end
	if spellcast.holy then
		dest.holy = spellcast.holy
	end
end

function OvaleFuture:GetLastSpellInfo(guid, spellId, statName)
	if self_lastSpellcast[guid] and self_lastSpellcast[guid][spellId] then
		if OvalePaperDoll.SNAPSHOT_STATS[statName] then
			return self_lastSpellcast[guid][spellId].snapshot[statName]
		else
			return self_lastSpellcast[guid][spellId][statName]
		end
	end
end

function OvaleFuture:InFlight(spellId)
	for _, spellcast in ipairs(self_activeSpellcast) do
		if spellcast.spellId == spellId then
			return true
		end
	end
	return false
end

function OvaleFuture:Debug()
	if next(self_activeSpellcast) then
		Ovale:Print("Spells in flight:")
	else
		Ovale:Print("No spells in flight!")
	end
	for _, spellcast in ipairs(self_activeSpellcast) do
		Ovale:FormatPrint("    %s (%d), lineId=%s", OvaleSpellBook:GetSpellName(spellcast.spellId), spellcast.spellId, spellcast.lineId)
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
-- Whether the player is channeling a spell in the simulator at the current time.
statePrototype.isChanneling = nil
-- The previous spell cast in the simulator.
statePrototype.lastSpellId = nil
-- counter[name] = count
statePrototype.counter = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleFuture:InitializeState(state)
	state.counter = {}
end

-- Reset the state to the current conditions.
function OvaleFuture:ResetState(state)
	local now = API_GetTime()
	state.currentTime = now
	Ovale:Logf("Reset state with current time = %f", state.currentTime)

	state.lastSpellId = self.lastSpellcast and self.lastSpellcast.spellId
	state.currentSpellId = nil
	state.isChanneling = false
	state.nextCast = now

	for k, v in pairs(self.counter) do
		state.counter[k] = self.counter[k]
	end
end

-- Release state resources prior to removing from the simulator.
function OvaleFuture:CleanState(state)
	state.currentTime = nil
	state.currentSpellId = nil
	state.startCast = nil
	state.endCast = nil
	state.nextCast = nil
	state.isChanneling = nil
	state.lastSpellId = nil

	for k in pairs(state.counter) do
		state.counter[k] = nil
	end
end

-- Apply the effects of the spell at the start of the spellcast.
function OvaleFuture:ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast)
	local si = OvaleData.spellInfo[spellId]
	if si then
		-- Increment and reset spell counters.
		if si.inccounter then
			local id = si.inccounter
			local value = state.counter[id] and state.counter[id] or 0
			state.counter[id] = value + 1
		end
		if si.resetcounter then
			local id = si.resetcounter
			state.counter[id] = 0
		end
	end
end
--</public-static-methods>

--<state-methods>
statePrototype.GetCounterValue = function(state, id)
	return state.counter[id] or 0
end

statePrototype.GetDamageMultiplier = function(state, spellId)
	return GetDamageMultiplier(spellId, state)
end

--[[
	Cast a spell in the simulator and advance the state of the simulator.

	Parameters:
		spellId		The ID of the spell to cast.
		targetGUID	The GUID of the target of the spellcast.
		startCast	The time at the start of the spellcast.
		endCast		The time at the end of the spellcast.
		nextCast	The earliest time at which the next spell can be cast (nextCast >= endCast).
		isChanneled	The spell is a channeled spell.
		nocd		The spell's cooldown is not triggered.
		spellcast	(optional) Table of spellcast information, including a snapshot of player's stats.
--]]
statePrototype.ApplySpell = function(state, ...)
	local spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast = ...
	if not spellId or not targetGUID then
		return
	end

	-- Handle missing start/end/next cast times.
	if not startCast or not endCast or not nextCast then
		local castTime = 0
		local castTime = select(7, API_GetSpellInfo(spellId))
		castTime = castTime and (castTime / 1000) or 0
		local gcd = OvaleCooldown:GetGCD(spellId)

		startCast = startCast or state.nextCast
		endCast = endCast or (startCast + castTime)
		nextCast = (castTime > gcd) and endCast or (startCast + gcd)
	end

	-- Update the latest spell cast in the simulator.
	state.currentSpellId = spellId
	state.startCast = startCast
	state.endCast = endCast
	state.nextCast = nextCast
	state.isChanneling = isChanneled
	state.lastSpellId = spellId

	-- Set the current time in the simulator to a little after the start of the current cast,
	-- or to now if in the past.
	local now = API_GetTime()
	if startCast >= now then
		state.currentTime = startCast + 0.1
	else
		state.currentTime = now
	end

	Ovale:Logf("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, state.currentTime, nextCast, endCast, targetGUID)

	--[[
		Apply the effects of the spellcast in three phases.
			1. Effects at the beginning of the spellcast.
			2. Effects when the spell has been cast.
			3. Effects when the spellcast hits the target.
	--]]
	-- If the spellcast has already started, then the effects have already occurred.
	if startCast >= now then
		OvaleState:InvokeMethod("ApplySpellStartCast", state, ...)
	end
	-- If the spellcast has already ended, then the effects have already occurred.
	if endCast > now then
		OvaleState:InvokeMethod("ApplySpellAfterCast", state, ...)
	end
	OvaleState:InvokeMethod("ApplySpellOnHit", state, ...)
end
--</state-methods>
