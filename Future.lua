--[[--------------------------------------------------------------------
    Copyright (C) 2012, 2013 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- The travelling missiles or spells that have been cast but whose effects were not still not applied

local OVALE, Ovale = ...
local OvaleFuture = Ovale:NewModule("OvaleFuture", "AceEvent-3.0")
Ovale.OvaleFuture = OvaleFuture

--<private-static-properties>
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

local ipairs = ipairs
local next = next
local pairs = pairs
local strfind = string.find
local tinsert = table.insert
local tonumber = tonumber
local tostring = tostring
local tremove = table.remove
local type = type
local wipe = wipe
local API_GetTime = GetTime
local API_UnitCastingInfo = UnitCastingInfo
local API_UnitChannelInfo = UnitChannelInfo
local API_UnitGUID = UnitGUID
local API_UnitName = UnitName
local MAX_COMBO_POINTS = MAX_COMBO_POINTS

-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleFuture)

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

-- Table of external functions to save additional data about a spellcast.
local self_updateSpellcastInfo = {}

-- Prefer target auras to player auras for aura-tracking so that spell travel time is more accurately taken into account.
local SPELLCAST_AURA_ORDER = { "target", "pet", "player" }

local OVALE_UNKNOWN_GUID = 0

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
local CLEU_SUCCESSFUL_SPELLCAST_EVENT = {
--	SPELL_CAST_SUCCESS = "hit",
	SPELL_CAST_FAILED = "miss",
	SPELL_DAMAGE = "hit",
	SPELL_DISPEL = "hit",
	SPELL_DISPEL_FAILED = "miss",
	SPELL_HEAL = "hit",
	SPELL_INTERRUPT = "hit",
	SPELL_MISSED = "miss",
	SPELL_STOLEN = "hit",
}
do
	-- All aura events are also successful spellcast events.
	for cleuEvent, v in pairs(CLEU_AURA_EVENT) do
		CLEU_SUCCESSFUL_SPELLCAST_EVENT[cleuEvent] = v
	end
end

-- Table of spells that are "white attacks" but are also tracked in UNIT_SPELLCAST_* events.
local WHITE_ATTACK = {
	[    75] = true,	-- Auto Shot
	[  5019] = true,	-- Shoot
}

-- Table of aura additions.
local AURA_ADDED = {
	count = true,
	extend = true,
	refresh = true,
	refresh_keep_snapshot = true,
}

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
-- Spell counter (see Counter script condition).
OvaleFuture.counter = {}
-- Most recent spellcast.
OvaleFuture.lastSpellcast = nil
-- Most recent GCD spellcast.
OvaleFuture.lastGCDSpellcast = nil
-- Table of most recent cast times of spells, indexed by spell ID.
OvaleFuture.lastCastTime = {}
-- Debugging: spells to trace
OvaleFuture.traceSpellList = nil
--</public-static-properties>

--<private-static-methods>
local function TracePrintf(spellId, ...)
	if OvaleFuture.traceSpellList then
		local name = spellId
		if type(spellId) == "number" then
			name = OvaleSpellBook:GetSpellName(spellId)
		end
		if OvaleFuture.traceSpellList[spellId] or OvaleFuture.traceSpellList[name] then
			local now = API_GetTime()
			OvaleFuture:Print("[trace] @%f %s", now, Ovale:MakeString(...))
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
local function GetDamageMultiplier(spellId, atTime, snapshot, auraObject)
	auraObject = auraObject or OvaleAura
	local damageMultiplier = 1
	local si = OvaleData.spellInfo[spellId]
	if si and si.aura and si.aura.damage then
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
				multiplier = tonumber(multiplier)
				local verified
				if index then
					if auraObject.CheckRequirements then
						verified = auraObject.CheckRequirements(auraObject, spellId, atTime, spellData, index, "player")
					else
						verified = OvaleData:CheckRequirements(spellId, atTime, spellData, index, "player")
					end
				else
					verified = true
				end
				if verified then
					local aura = auraObject:GetAura("player", auraId, filter)
					if auraObject:IsActiveAura(aura, atTime) then
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
	-- Factor in additional damage multipliers that are registered with this module.
	for tbl in pairs(self_updateSpellcastInfo) do
		if tbl.GetDamageMultiplier then
			local multiplier = tbl.GetDamageMultiplier(spellId, atTime, snapshot, auraObject)
			damageMultiplier = damageMultiplier * multiplier
		end
	end
	return damageMultiplier
end

local function QueueSpellcast(spellId, lineId, startTime, endTime, channeled, allowRemove)
	OvaleFuture:StartProfiling("OvaleFuture_QueueSpellcast")
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
	local target = OvaleGUID:GetUnitId(spellcast.target)
	TracePrintf(spellId, "    QueueSpellcast: %s (%d), lineId=%d, startTime=%f, endTime=%f, target=%s (%s)",
		spellName, spellId, lineId, startTime, endTime, spellcast.target, target)

	-- Snapshot the current stats for the spellcast.
	spellcast.snapshot = OvalePaperDoll:GetSnapshot()

	local atTime = channeled and startTime or endTime
	spellcast.damageMultiplier = GetDamageMultiplier(spellId, atTime, spellcast.snapshot)

	local si = OvaleData.spellInfo[spellId]
	if si then
		-- Save additional information to the spellcast that are registered with this module.
		for tbl in pairs(self_updateSpellcastInfo) do
			if tbl.SaveToSpellcast then
				tbl.SaveToSpellcast(spellcast, atTime)
			end
		end

		--[[
			Set spellcast.auraId to one of the auras, if any, that are added or refreshed by this spell.
			This helps to later identify whether the spellcast succeeded by noting when the aura is
			applied or refreshed.
		--]]
		if si.aura then
			for _, auraTarget in ipairs(SPELLCAST_AURA_ORDER) do
				for filter, auraList in pairs(si.aura[auraTarget]) do
					for auraId, spellData in pairs(auraList) do
						local verified, value, data = OvaleData:CheckSpellAuraData(auraId, spellData, atTime, target)
						if verified and (AURA_ADDED[value] or type(value) == "number" and value > 0) then
							spellcast.auraId = auraId
							if target ~= "player" then
								spellcast.removeOnAuraSuccess = true
							end
							break
						end
					end
					if spellcast.auraId then break end
				end
				if spellcast.auraId then
					TracePrintf(spellId, "    QueueSpellcast: %s (%d) waiting on aura %d on %s.", spellName, spellId, spellcast.auraId, auraTarget)
					break
				end
			end
		end

		-- Increment or reset any counters used by the Counter() condition.
		local inccounter = OvaleData:GetSpellInfoProperty(spellId, atTime, "inccounter", target)
		if inccounter then
			local value = self.counter[inccounter] and self.counter[inccounter] or 0
			self.counter[inccounter] = value + 1
		end
		local resetcounter = OvaleData:GetSpellInfoProperty(spellId, atTime, "resetcounter", target)
		if resetcounter then
			self.counter[resetcounter] = 0
		end
	end

	-- Set the condition for detecting a successful spellcast.
	if not spellcast.removeOnAuraSuccess then
		spellcast.removeOnSuccess = true
	end

	tinsert(self_activeSpellcast, spellcast)

	OvaleScore:ScoreSpell(spellId)
	Ovale.refreshNeeded.player = true
	OvaleFuture:StopProfiling("OvaleFuture_QueueSpellcast")
	return spellcast
end

local function UnqueueSpellcast(spellId, lineId)
	OvaleFuture:StartProfiling("OvaleFuture_UnqueueSpellcast")
	for index, spellcast in ipairs(self_activeSpellcast) do
		if spellcast.lineId == lineId then
			TracePrintf(spellId, "    UnqueueSpellcast: %s (%d)", OvaleSpellBook:GetSpellName(spellId), spellId)
			tremove(self_activeSpellcast, index)
			self_pool:Release(spellcast)
			break
		end
	end
	Ovale.refreshNeeded.player = true
	OvaleFuture:StopProfiling("OvaleFuture_UnqueueSpellcast")
end

-- UpdateLastSpellcast() is called at the end of the event handler for CLEU_SUCCESSFUL_SPELLCAST_EVENT[].
-- It saves the given spellcast as the most recent one on its target and ensures that the spellcast
-- snapshot values are correctly adjusted for buffs that are added or cleared simultaneously with the
-- spellcast.
local function UpdateLastSpellcast(spellcast)
	OvaleFuture:StartProfiling("OvaleFuture_UpdateLastSpellcast")
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
		local si = OvaleData.spellInfo[spellId]
		local gcd = si and si.gcd
		if not gcd or gcd > 0 then
			self.lastGCDSpellcast = spellcast
		end

		--[[
			If any auras have been added between the start of the spellcast and this event,
			then take a more recent snapshot of the player stats for this spellcast.

			This is needed to see any auras that were applied at the same time as the
			spellcast, e.g., potions or other on-use abilities or items.
		--]]
		if self_timeAuraAdded then
			if self_timeAuraAdded >= spellcast.start and self_timeAuraAdded - spellcast.stop < 1 then
				OvalePaperDoll:UpdateSnapshot(spellcast.snapshot)
				spellcast.damageMultiplier = GetDamageMultiplier(spellId, self_timeAuraAdded, spellcast.snapshot)
				TracePrintf(spellId, "    Updated spell info for %s (%d) to snapshot from %f.",
					OvaleSpellBook:GetSpellName(spellId), spellId, spellcast.snapshot.snapshotTime)
			end
		end
	end
	OvaleFuture:StopProfiling("OvaleFuture_UpdateLastSpellcast")
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
	self_guid = API_UnitGUID("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
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
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
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
	wipe(self.lastCastTime)
	Ovale.refreshNeeded.player = true
end

function OvaleFuture:PLAYER_REGEN_DISABLED(event)
	local now = API_GetTime()
	self.inCombat = true
	self.combatStartTime = now
	Ovale.refreshNeeded.player = true
	self:SendMessage("Ovale_CombatStarted", now)
end

function OvaleFuture:PLAYER_REGEN_ENABLED(event)
	local now = API_GetTime()
	self.inCombat = false
	Ovale.refreshNeeded.player = true
	self_pool:Drain()
	self:SendMessage("Ovale_CombatEnded", now)
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
	Ovale.refreshNeeded[unit] = true
	if unit == "player" then
		local _, _, _, _, startTime, endTime = API_UnitChannelInfo("player")
		TracePrintf(spellId, "%s: %d, lineId=%d, startTime=%f, endTime=%f",
			event, spellId, lineId, startTime, endTime)
		QueueSpellcast(spellId, lineId, startTime/1000, endTime/1000, true, false)
	end
end

function OvaleFuture:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, name, rank, lineId, spellId)
	Ovale.refreshNeeded[unit] = true
	if unit == "player" then
		TracePrintf(spellId, "%s: %d, lineId=%d", event, spellId, lineId)
		UnqueueSpellcast(spellId, lineId)
	end
end

--Called when a spell started its cast
function OvaleFuture:UNIT_SPELLCAST_START(event, unit, name, rank, lineId, spellId)
	Ovale.refreshNeeded[unit] = true
	if unit == "player" then
		local _, _, _, _, startTime, endTime = API_UnitCastingInfo("player")
		TracePrintf(spellId, "%s: %d, lineId=%d, startTime=%f, endTime=%f",
			event, spellId, lineId, startTime, endTime)
		QueueSpellcast(spellId, lineId, startTime/1000, endTime/1000, false, false)
	end
end

--Called if the player interrupted early his cast
function OvaleFuture:UNIT_SPELLCAST_INTERRUPTED(event, unit, name, rank, lineId, spellId)
	Ovale.refreshNeeded[unit] = true
	if unit == "player" then
		TracePrintf(spellId, "%s: %d, lineId=%d", event, spellId, lineId)
		UnqueueSpellcast(spellId, lineId)
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
		if target ~= "" then
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
	Ovale.refreshNeeded[unit] = true
	if unit == "player" and not WHITE_ATTACK[spellId] then
		self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED")
		TracePrintf(spellId, "%s: %d, lineId=%d", event, spellId, lineId)

		-- Search for a cast-time spell matching this spellcast that was added by UNIT_SPELLCAST_START.
		for _, spellcast in ipairs(self_activeSpellcast) do
			if spellcast.lineId == lineId then
				spellcast.allowRemove = true
				-- Take a more recent snapshot of the player stats for this cast-time spell.
				if spellcast.snapshot then
					OvalePaperDoll:ReleaseSnapshot(spellcast.snapshot)
				end
				local now = API_GetTime()
				spellcast.snapshot = OvalePaperDoll:GetSnapshot()
				spellcast.damageMultiplier = GetDamageMultiplier(spellId, now, spellcast.snapshot)
				self:SendMessage("Ovale_SpellCast", now, spellcast.spellId, spellcast.target)
				Ovale.refreshNeeded.player = true
				self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED")
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
			local spellcast = QueueSpellcast(spellId, lineId, now, now, false, true)
			self:SendMessage("Ovale_SpellCast", now, spellId, spellcast.target)
		end
		self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED")
	end
end

function OvaleFuture:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...

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
	SPELL_CAST_SUCCESS
	SPELL_AURA_APPLIED
	SPELL_PERIODIC_DAMAGE
	SPELL_PERIODIC_DAMAGE
	]]--

	-- Called when a missile reaches or misses its target
	if sourceGUID == self_guid then
		local success = CLEU_SUCCESSFUL_SPELLCAST_EVENT[cleuEvent]
		--[[
			If this is a "SPELL_DAMAGE" event, then only count it as a success if it was the "main" attack,
			and not an off-hand or multistrike attack.  Also change success type to "critical" if true.
		--]]
		if cleuEvent == "SPELL_DAMAGE" then
			local critical, isOffHand, multistrike = arg21, arg24, arg25
			if isOffHand or multistrike then
				success = nil
			elseif critical then
				success = "critical"
			end
		end
		if success then
			self:StartProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED")
			local spellId, spellName = arg12, arg13
			TracePrintf(spellId, "%s: %s (%d)", cleuEvent, spellName, spellId)
			for index, spellcast in ipairs(self_activeSpellcast) do
				if spellcast.allowRemove and not spellcast.channeled and (spellcast.spellId == spellId or spellcast.auraId == spellId) then
					spellcast.success = success
					if spellcast.removeOnSuccess or (spellcast.removeOnAuraSuccess and CLEU_AURA_EVENT[cleuEvent]) or success == "miss" then
						TracePrintf(spellId, "    Spell finished (%s): %s (%d)", success, spellName, spellId)
						tremove(self_activeSpellcast, index)
						UpdateLastSpellcast(spellcast)
						local now = API_GetTime()
						self.lastCastTime[spellcast.spellId] = now
						self:SendMessage("Ovale_SpellFinished", now, spellcast.spellId, spellcast.target, success)
						local unitId = spellcast.target and OvaleGUID:GetUnitId(spellcast.target) or "player"
						Ovale.refreshNeeded[unitId] = true
						Ovale.refreshNeeded.player = true
					end
					break
				end
			end
			self:StopProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED")
		end
	end
end

-- Apply the effects of spells that are being cast or are in flight, allowing us to
-- ignore lag or missile travel time.
function OvaleFuture:ApplyInFlightSpells(state)
	self:StartProfiling("OvaleFuture_ApplyInFlightSpells")
	local now = API_GetTime()
	local index = 1
	while index <= #self_activeSpellcast do
		local spellcast = self_activeSpellcast[index]
		state:Log("Spell %d in flight to %s, now=%f, endCast=%f", spellcast.spellId, spellcast.target, now, spellcast.stop)
		if now - spellcast.stop < 5 then
			state:ApplySpell(spellcast.spellId, spellcast.target, spellcast.start, spellcast.stop, spellcast.channeled, spellcast)
		else
			tremove(self_activeSpellcast, index)
			self_pool:Release(spellcast)
			-- Decrement current index since item was removed and rest of items shifted up.
			index = index - 1
		end
		index = index + 1
	end
	self:StopProfiling("OvaleFuture_ApplyInFlightSpells")
end

function OvaleFuture:LastInFlightSpell()
	if #self_activeSpellcast > 0 then
		return self_activeSpellcast[#self_activeSpellcast]
	end
	return self.lastGCDSpellcast
end

function OvaleFuture:UpdateFromSpellcast(dest, spellcast)
	self:StartProfiling("OvaleFuture_UpdateFromSpellcast")
	if dest.snapshot then
		OvalePaperDoll:ReleaseSnapshot(dest.snapshot)
	end
	if spellcast.snapshot then
		dest.snapshot = OvalePaperDoll:GetSnapshot(spellcast.snapshot)
	end
	if spellcast.damageMultiplier then
		dest.damageMultiplier = spellcast.damageMultiplier
	end
	-- Update additional information from the spellcast that are registered with this module.
	for tbl in pairs(self_updateSpellcastInfo) do
		if tbl.UpdateFromSpellcast then
			tbl.UpdateFromSpellcast(dest, spellcast)
		end
	end
	self:StopProfiling("OvaleFuture_UpdateFromSpellcast")
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

function OvaleFuture:RegisterSpellcastInfo(functionTable)
	self_updateSpellcastInfo[functionTable] = true
end

function OvaleFuture:UnregisterSpellcastInfo(functionTable)
	self_updateSpellcastInfo[functionTable] = nil
end

function OvaleFuture:DebugSpellsInFlight()
	if next(self_activeSpellcast) then
		self:Print("Spells in flight:")
	else
		self:Print("No spells in flight!")
	end
	for _, spellcast in ipairs(self_activeSpellcast) do
		self:Print("    %s (%d), lineId=%s", OvaleSpellBook:GetSpellName(spellcast.spellId), spellcast.spellId, spellcast.lineId)
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
-- Whether the spell being cast in the simulator is a channeled spell.
statePrototype.isChanneled = nil
-- The previous spell cast in the simulator.
statePrototype.lastSpellId = nil
-- The previous GCD spell cast in the simulator.
statePrototype.lastGCDSpellId = nil
-- counter[name] = count
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

	state.lastSpellId = self.lastSpellcast and self.lastSpellcast.spellId
	state.isChanneled = self.lastSpellcast and self.lastSpellcast.channeled
	state.currentSpellId = state.lastSpellId
	state.lastGCDSpellId = self.lastGCDSpellcast and self.lastGCDSpellcast.spellId
	state:Log("    lastSpellId = %s", state.lastSpellId or "nil")
	state:Log("    isChanneled = %s", state.isChanneled and "true" or "false")
	state:Log("    lastGCDSpellId = %s", state.lastGCDSpellId or "nil")

	local start, duration = OvaleCooldown:GetGlobalCooldown(now)
	if start and start > 0 then
		state.nextCast = start + duration
		state:Log("    nextCast = %f (waiting for GCD)", state.nextCast)
	else
		state.nextCast = now
		state:Log("    nextCast = %f", state.nextCast)
	end

	for k in pairs(state.lastCast) do
		state.lastCast[k] = nil
	end
	for k, v in pairs(self.counter) do
		state.counter[k] = self.counter[k]
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
function OvaleFuture:ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvaleFuture_ApplySpellStartCast")
	if isChanneled then
		-- Increment and reset spell counters.
		local target = OvaleGUID:GetUnitId(targetGUID)
		local inccounter = state:GetSpellInfoProperty(spellId, startCast, "inccounter", target)
		if inccounter then
			local value = state.counter[inccounter] and state.counter[inccounter] or 0
			state.counter[inccounter] = value + 1
		end
		local resetcounter = state:GetSpellInfoProperty(spellId, startCast, "resetcounter", target)
		if resetcounter then
			state.counter[resetcounter] = 0
		end
	end
	self:StopProfiling("OvaleFuture_ApplySpellStartCast")
end

-- Apply the effects of the spell when the spellcast completes.
function OvaleFuture:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvaleFuture_ApplySpellAfterCast")
	if not isChanneled then
		-- Increment and reset spell counters.
		local target = OvaleGUID:GetUnitId(targetGUID)
		local inccounter = state:GetSpellInfoProperty(spellId, endCast, "inccounter", target)
		if inccounter then
			local value = state.counter[inccounter] and state.counter[inccounter] or 0
			state.counter[inccounter] = value + 1
		end
		local resetcounter = state:GetSpellInfoProperty(spellId, endCast, "resetcounter", target)
		if resetcounter then
			state.counter[resetcounter] = 0
		end
	end
	self:StopProfiling("OvaleFuture_ApplySpellAfterCast")
end

--</public-static-methods>

--<state-methods>
statePrototype.GetCounterValue = function(state, id)
	return state.counter[id] or 0
end

statePrototype.GetDamageMultiplier = function(state, spellId, atTime)
	atTime = atTime or state.currentTime
	return GetDamageMultiplier(spellId, atTime, state.snapshot, state)
end

statePrototype.TimeOfLastCast = function(state, spellId)
	return state.lastCast[spellId] or OvaleFuture.lastCastTime[spellId] or 0
end

-- Return whether the player is currently channeling a spell in the simulator.
statePrototype.IsChanneling = function(state, atTime)
	atTime = atTime or state.currentTime
	return state.isChanneled and (atTime < state.endCast)
end

--[[
	Cast a spell in the simulator and advance the state of the simulator.

	Parameters:
		spellId		The ID of the spell to cast.
		targetGUID	The GUID of the target of the spellcast.
		startCast	The time at the start of the spellcast.
		endCast		The time at the end of the spellcast.
		isChanneled	The spell is a channeled spell.
		spellcast	(optional) Table of spellcast information, including a snapshot of player's stats.
--]]
statePrototype.ApplySpell = function(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	OvaleFuture:StartProfiling("OvaleFuture_state_ApplySpell")
	if spellId and targetGUID then

		-- Handle missing start/end/next cast times.
		local castTime
		if startCast and endCast then
			castTime = endCast - startCast
		else
			castTime = OvaleSpellBook:GetCastTime(spellId) or 0
			startCast = startCast or state.nextCast
			endCast = endCast or (startCast + castTime)
		end

		-- Update the latest spell cast in the simulator.
		state.currentSpellId = spellId
		state.startCast = startCast
		state.endCast = endCast
		state.lastCast[spellId] = endCast
		state.lastSpellId = spellId
		state.isChanneled = isChanneled

		-- Update the GCD-related spell information in the simulator.
		local target = OvaleGUID:GetUnitId(targetGUID)
		local gcd = state:GetGCD(spellId, startCast, target)
		local nextCast = (castTime > gcd) and endCast or (startCast + gcd)
		if state.nextCast < nextCast then
			state.nextCast = nextCast
		end
		if gcd > 0 then
			state.lastGCDSpellId = spellId
		end

		-- Set the current time in the simulator to *slightly* after the start of the current cast,
		-- or to now if in the past.
		local now = API_GetTime()
		if startCast >= now then
			state.currentTime = startCast + SIMULATOR_LAG
		else
			state.currentTime = now
		end

		state:Log("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, state.currentTime, nextCast, endCast, targetGUID)

		-- Update the combat state so this condition can be checked in other state prototype methods.
		-- This condition isn't quite right because casting a harmful spell at a target doesn't always put us into combat.
		if not state.inCombat and OvaleSpellBook:IsHarmfulSpell(spellId) then
			state.inCombat = true
			if isChanneled then
				state.combatStartTime = startCast
			else
				state.combatStartTime = endCast
			end
		end

		--[[
			Apply the effects of the spellcast in four phases.
				1. Effects at the beginning of the spellcast.
				2. Effects when the spell has been cast.
				3. Effects when the spellcast hits the target.
		--]]
		-- If the spellcast has already started, then the effects have already occurred.
		if startCast > now then
			OvaleState:InvokeMethod("ApplySpellStartCast", state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
		end
		-- If the spellcast has already ended, then the effects have already occurred.
		if endCast > now then
			OvaleState:InvokeMethod("ApplySpellAfterCast", state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
		end
		if not spellcast or not spellcast.success or spellcast.success == "hit" or spellcast.success == "critical" then
			OvaleState:InvokeMethod("ApplySpellOnHit", state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
		end
	end
	OvaleFuture:StopProfiling("OvaleFuture_state_ApplySpell")
end
--</state-methods>
