--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

--[[
	This addon tracks all auras for all units.
--]]

local OVALE, Ovale = ...
local OvaleAura = Ovale:NewModule("OvaleAura", "AceEvent-3.0")
Ovale.OvaleAura = OvaleAura

--<private-static-properties>
-- Profiling set-up.
local Profiler = Ovale.Profiler
local profiler = nil
do
	local group = OvaleAura:GetName()
	Profiler:RegisterProfilingGroup(group)
	profiler = Profiler:GetProfilingGroup(group)
end

local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug
local OvalePool = Ovale.OvalePool

-- Forward declarations for module dependencies.
local LibDispellable = LibStub("LibDispellable-1.0", true)
local OvaleData = nil
local OvaleFuture = nil
local OvaleGUID = nil
local OvalePaperDoll = nil
local OvaleSpellBook = nil
local OvaleState = nil

local bit_band = bit.band
local bit_bor = bit.bor
local floor = math.floor
local gmatch = string.gmatch
local ipairs = ipairs
local next = next
local pairs = pairs
local substr = string.sub
local strmatch = string.match
local tinsert = table.insert
local tonumber = tonumber
local tsort = table.sort
local wipe = table.wipe
local API_GetTime = GetTime
local API_UnitAura = UnitAura
local API_UnitGUID = UnitGUID
local API_UnitHealth = UnitHealth
local API_UnitHealthMax = UnitHealthMax
local SCHOOL_MASK_ARCANE = SCHOOL_MASK_ARCANE
local SCHOOL_MASK_FIRE = SCHOOL_MASK_FIRE
local SCHOOL_MASK_FROST = SCHOOL_MASK_FROST
local SCHOOL_MASK_HOLY = SCHOOL_MASK_HOLY
local SCHOOL_MASK_NATURE = SCHOOL_MASK_NATURE
local SCHOOL_MASK_SHADOW = SCHOOL_MASK_SHADOW

-- Player's GUID.
local self_guid = nil
-- Table pool.
local self_pool = OvalePool("OvaleAura_pool")
do
	self_pool.Clean = function(self, aura)
		-- Release reference-counted snapshot before wiping.
		if aura.snapshot then
			OvalePaperDoll:ReleaseSnapshot(aura.snapshot)
		end
	end
end

-- Some auras have a nil caster, so treat those as having a GUID of zero for indexing purposes.
local UNKNOWN_GUID = 0

local OVALE_AURA_DEBUG = "aura"
do
	OvaleDebug:RegisterDebugOption(OVALE_AURA_DEBUG, L["Auras"], L["Debug auras"])
end

-- Aura debuff types.
local DEBUFF_TYPES = {
	Curse = true,
	Disease = true,
	Magic = true,
	Poison = true,
}

-- CLEU events triggered by auras being applied, removed, refreshed, or changed in stack size.
local CLEU_AURA_EVENTS = {
	SPELL_AURA_APPLIED = true,
	SPELL_AURA_REMOVED = true,
	SPELL_AURA_APPLIED_DOSE = true,
	SPELL_AURA_REMOVED_DOSE = true,
	SPELL_AURA_REFRESH = true,
	SPELL_AURA_BROKEN = true,
	SPELL_AURA_BROKEN_SPELL = true,
}

-- CLEU events triggered by a periodic aura.
local CLEU_TICK_EVENTS = {
	SPELL_PERIODIC_DAMAGE = true,
	SPELL_PERIODIC_HEAL = true,
	SPELL_PERIODIC_ENERGIZE = true,
	SPELL_PERIODIC_DRAIN = true,
	SPELL_PERIODIC_LEECH = true,
}

-- Spell school bitmask to identify magic effects.
local CLEU_SCHOOL_MASK_MAGIC = bit_bor(SCHOOL_MASK_ARCANE, SCHOOL_MASK_FIRE, SCHOOL_MASK_FROST, SCHOOL_MASK_HOLY, SCHOOL_MASK_NATURE, SCHOOL_MASK_SHADOW)
--</private-static-properties>

--<public-static-properties>
-- Auras on the target (past & present): aura[guid][auraId][casterGUID] = aura.
OvaleAura.aura = {}
-- Current age of auras per unit: serial[guid] = age.
OvaleAura.serial = {}
--</public-static-properties>

--<private-static-methods>
local function PutAura(auraDB, guid, auraId, casterGUID, aura)
	if not auraDB[guid] then
		auraDB[guid] = self_pool:Get()
	end
	if not auraDB[guid][auraId] then
		auraDB[guid][auraId] = self_pool:Get()
	end
	-- Remove any pre-existing aura at that slot.
	if auraDB[guid][auraId][casterGUID] then
		self_pool:Release(auraDB[guid][auraId][casterGUID])
	end
	-- Save the aura into that slot.
	auraDB[guid][auraId][casterGUID] = aura
	-- Set aura properties as a result of where it's slotted.
	aura.guid = guid
	aura.spellId = auraId
	aura.source = casterGUID
end

local function GetAura(auraDB, guid, auraId, casterGUID)
	if auraDB[guid] and auraDB[guid][auraId] and auraDB[guid][auraId][casterGUID] then
		return auraDB[guid][auraId][casterGUID]
	end
end

local function GetAuraAnyCaster(auraDB, guid, auraId)
	local auraFound
	if auraDB[guid] and auraDB[guid][auraId] then
		for casterGUID, aura in pairs(auraDB[guid][auraId]) do
			-- Find the aura with the latest expiration time.
			if not auraFound or auraFound.ending < aura.ending then
				auraFound = aura
			end
		end
	end
	return auraFound
end

local function GetDebuffType(auraDB, guid, debuffType, filter, casterGUID)
	local auraFound
	if auraDB[guid] then
		for auraId, whoseTable in pairs(auraDB[guid]) do
			local aura = whoseTable[casterGUID]
			if aura and aura.debuffType == debuffType and aura.filter == filter then
				-- Find the aura with the latest expiration time.
				if not auraFound or auraFound.ending < aura.ending then
					auraFound = aura
				end
			end
		end
	end
	return auraFound
end

local function GetDebuffTypeAnyCaster(auraDB, guid, debuffType, filter)
	local auraFound
	if auraDB[guid] then
		for auraId, whoseTable in pairs(auraDB[guid]) do
			for casterGUID, aura in pairs(whoseTable) do
				if aura and aura.debuffType == debuffType and aura.filter == filter then
					-- Find the aura with the latest expiration time.
					if not auraFound or auraFound.ending < aura.ending then
						auraFound = aura
					end
				end
			end
		end
	end
	return auraFound
end

local function GetAuraOnGUID(auraDB, guid, auraId, filter, mine)
	local auraFound
	if DEBUFF_TYPES[auraId] then
		if mine then
			auraFound = GetDebuffType(auraDB, guid, auraId, filter, self_guid)
		else
			auraFound = GetDebuffTypeAnyCaster(auraDB, guid, auraId, filter)
		end
	else
		if mine then
			auraFound = GetAura(auraDB, guid, auraId, self_guid)
		else
			auraFound = GetAuraAnyCaster(auraDB, guid, auraId)
		end
	end
	return auraFound
end

local function RemoveAurasOnGUID(auraDB, guid)
	if auraDB[guid] then
		local auraTable = auraDB[guid]
		for auraId, whoseTable in pairs(auraTable) do
			for casterGUID, aura in pairs(whoseTable) do
				self_pool:Release(aura)
				whoseTable[casterGUID] = nil
			end
			self_pool:Release(whoseTable)
			auraTable[auraId] = nil
		end
		self_pool:Release(auraTable)
		auraDB[guid] = nil
	end
end

local function IsEnrageEffect(auraId)
	local boolean = OvaleData.buffSpellList.enrage[auraId]
	if LibDispellable then
		boolean = LibDispellable:IsEnrageEffect(auraId)
	end
	return boolean or nil
end

local function IsWithinAuraLag(time1, time2, factor)
	factor = factor or 1
	local auraLag = Ovale.db.profile.apparence.auraLag
	local tolerance = factor * auraLag / 1000
	return (time1 - time2 < tolerance) and (time2 - time1 < tolerance)
end
--</private-static-methods>

--<public-static-methods>
function OvaleAura:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvaleFuture = Ovale.OvaleFuture
	OvaleGUID = Ovale.OvaleGUID
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleState = Ovale.OvaleState
end

function OvaleAura:OnEnable()
	self_guid = API_UnitGUID("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ScanAllUnitAuras")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("PLAYER_UNGHOST", "PLAYER_ALIVE")
	self:RegisterEvent("UNIT_AURA")
	self:RegisterMessage("Ovale_GroupChanged", "ScanAllUnitAuras")
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvaleAura:OnDisable()
	OvaleState:UnregisterState(self)
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_ALIVE")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("PLAYER_UNGHOST")
	self:UnregisterEvent("UNIT_AURA")
	self:UnregisterMessage("Ovale_GroupChanged")
	for guid in pairs(self.aura) do
		RemoveAurasOnGUID(self.aura, guid)
	end
	self_pool:Drain()
end

function OvaleAura:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...

	local mine = (sourceGUID == self_guid)
	if CLEU_AURA_EVENTS[cleuEvent] then
		local unitId = OvaleGUID:GetUnitId(destGUID)
		if unitId then
			-- Only update auras on the unit if it is not a unit type that receives UNIT_AURA events.
			if not OvaleGUID.UNIT_AURA_UNIT[unitId] then
				Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s: %s (%s)", cleuEvent, destGUID, unitId)
				self:ScanAurasOnGUID(destGUID, unitId)
			end
		elseif mine then
			-- There is no unit ID, but the action was caused by the player, so update this aura on destGUID.
			local spellId, spellName, spellSchool = arg12, arg13, arg14
			Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s: %s (%d) on %s", cleuEvent, spellName, spellId, destGUID)
			local now = API_GetTime()
			if cleuEvent == "SPELL_AURA_REMOVED" or cleuEvent == "SPELL_AURA_BROKEN" or cleuEvent == "SPELL_AURA_BROKEN_SPELL" then
				self:LostAuraOnGUID(destGUID, now, spellId, sourceGUID)
			else
				local auraType, amount = arg15, arg16
				local filter = (auraType == "BUFF") and "HELPFUL" or "HARMFUL"
				local si = OvaleData.spellInfo[spellId]
				-- Find an existing aura applied by the player on destGUID.
				local aura = GetAuraOnGUID(self.aura, destGUID, spellId, filter, true)
				local duration = aura and aura.duration or si.duration or 15
				local expirationTime = now + duration
				local count
				if cleuEvent == "SPELL_AURA_APPLIED" then
					count = 1
				elseif cleuEvent == "SPELL_AURA_APPLIED_DOSE" or cleuEvent == "SPELL_AURA_REMOVED_DOSE" then
					count = amount
				elseif cleuEvent == "SPELL_AURA_REFRESH" then
					count = aura and aura.stacks or 1
				end
				self:GainedAuraOnGUID(destGUID, now, spellId, sourceGUID, filter, true, nil, count, nil, duration, expirationTime, nil, spellName)
			end
		end
	elseif mine and CLEU_TICK_EVENTS[cleuEvent] then
		-- Update the latest tick time of the periodic aura cast by the player.
		local spellId, spellName, spellSchool = arg12, arg13, arg14
		local unitId = OvaleGUID:GetUnitId(destGUID)
		if unitId then
			Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s: %s (%s)", cleuEvent, destGUID, unitId)
		else
			Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s: %s", cleuEvent, destGUID)
		end
		local aura = GetAura(self.aura, destGUID, spellId, self_guid)
		if self:IsActiveAura(aura) then
			local name = aura.name or "Unknown spell"
			local baseTick, lastTickTime = aura.baseTick, aura.lastTickTime
			local tick = baseTick
			if lastTickTime then
				-- Update the tick length based on the timestamps of the current tick and the previous tick.
				tick = timestamp - lastTickTime
			elseif not baseTick then
				-- This isn't a known periodic aura, but it's ticking so treat this as the first tick.
				Ovale:DebugPrintf(OVALE_AURA_DEBUG, "First tick seen of unknown periodic aura %s (%d) on %s.", name, spellId, destGUID)
				local si = OvaleData.spellInfo[spellId]
				baseTick = (si and si.tick) and si.tick or 3
				tick = OvaleData:GetTickLength(spellId)
			end
			aura.baseTick = baseTick
			aura.lastTickTime = timestamp
			aura.tick = tick
			Ovale:DebugPrintf(OVALE_AURA_DEBUG, "Updating %s (%s) on %s, tick=%s, lastTickTime=%s", name, spellId, destGUID, tick, lastTickTime)
		end
	end
end

function OvaleAura:PLAYER_ALIVE(event)
	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s", event)
	self:ScanAurasOnGUID(self_guid, "player")
end

function OvaleAura:PLAYER_REGEN_ENABLED(event)
	self:RemoveAurasOnInactiveUnits()
	self_pool:Drain()
end

function OvaleAura:PLAYER_TARGET_CHANGED(event, cause)
	if cause == "NIL" or cause == "down" then
		-- Target was cleared.
	else
		-- Target has changed.
		Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s", event)
		self:ScanAuras("target")
	end
end

function OvaleAura:UNIT_AURA(event, unitId)
	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s: %s", event, unitId)
	self:ScanAuras(unitId)
end

function OvaleAura:ScanAllUnitAuras()
	-- Update auras on all visible units.
	for unitId in pairs(OvaleGUID.UNIT_AURA_UNIT) do
		self:ScanAuras(unitId)
	end
end

function OvaleAura:RemoveAurasOnInactiveUnits()
	-- Remove all auras from GUIDs that can no longer be referenced by a unit ID,
	-- i.e., not in the group or not targeted by anyone in the group or focus.
	for guid in pairs(self.aura) do
		local unitId = OvaleGUID:GetUnitId(guid)
		if not unitId then
			Ovale:DebugPrintf(OVALE_AURA_DEBUG, "Removing auras from guid %s", guid)
			RemoveAurasOnGUID(self.aura, guid)
			self.serial[guid] = nil
		end
	end
end

function OvaleAura:IsActiveAura(aura, now)
	local boolean = false
	if aura then
		now = now or API_GetTime()
		if aura.serial == self.serial[aura.guid] and aura.stacks > 0 and aura.gain <= now and now <= aura.ending then
			boolean = true
		elseif aura.consumed and IsWithinAuraLag(aura.ending, now) then
			boolean = true
		end
	end
	return boolean
end

function OvaleAura:GainedAuraOnGUID(guid, atTime, auraId, casterGUID, filter, visible, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3)
	profiler.Start("OvaleAura_GainedAuraOnGUID")
	-- Whose aura is it?
	casterGUID = casterGUID or UNKNOWN_GUID
	local mine = (casterGUID == self_guid)

	-- UnitAura() can return zero count for auras that are present.
	count = (count and count > 0) and count or 1
	-- "Zero" or nil duration and expiration actually mean the aura never expires.
	duration = (duration and duration > 0) and duration or math.huge
	expirationTime = (expirationTime and expirationTime > 0) and expirationTime or math.huge

	local aura = GetAura(self.aura, guid, auraId, casterGUID)
	local auraIsActive
	if aura then
		auraIsActive = (aura.stacks > 0 and aura.gain <= atTime and atTime <= aura.ending)
	else
		aura = self_pool:Get()
		PutAura(self.aura, guid, auraId, casterGUID, aura)
		auraIsActive = false
	end

	-- Only overwrite an active aura's information if the aura has changed.
	-- An aura's "fingerprint" is its: caster, duration, expiration time, stack count, value
	local auraIsUnchanged = (
		aura.source == casterGUID
			and aura.duration == duration
			and aura.ending == expirationTime
			and aura.stacks == count
			and aura.value1 == value1
			and aura.value2 == value2
			and aura.value3 == value3
	)

	-- Update age of aura, regardless of whether it's changed.
	aura.serial = self.serial[guid]

	if not auraIsActive or not auraIsUnchanged then
		Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    Adding %s %s (%s) to %s at %f, aura.serial=%d",
			filter, name, auraId, guid, atTime, aura.serial)
		aura.name = name
		aura.duration = duration
		aura.ending = expirationTime
		if duration < math.huge and expirationTime < math.huge then
			aura.start = expirationTime - duration
		else
			aura.start = atTime
		end
		aura.gain = atTime
		aura.lastUpdated = atTime
		aura.stacks = count
		aura.consumed = nil
		aura.filter = filter
		aura.visible = visible
		aura.icon = icon
		aura.debuffType = debuffType
		aura.enrage = IsEnrageEffect(auraId)
		aura.stealable = isStealable
		aura.value1, aura.value2, aura.value3 = value1, value2, value3

		-- Snapshot stats for auras applied by the player.
		if mine then
			-- Determine whether to snapshot player stats for the aura or to keep the existing stats.
			local spellcast = OvaleFuture:LastInFlightSpell()
			if spellcast and spellcast.stop and not IsWithinAuraLag(spellcast.stop, atTime) then
				spellcast = OvaleFuture.lastSpellcast
				if spellcast and spellcast.stop and not IsWithinAuraLag(spellcast.stop, atTime) then
					spellcast = nil
				end
			end
			if spellcast and spellcast.target == guid then
				local spellName = OvaleSpellBook:GetSpellName(spellcast.spellId) or "Unknown spell"
				Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    Snapshot stats for %s %s (%d) on %s applied by %s (%d) from %f, now=%f, aura.serial=%d",
					filter, name, auraId, guid, spellName, spellcast.spellId, spellcast.snapshot.snapshotTime, atTime, aura.serial)
				-- TODO: damageMultiplier isn't correct if spellId spreads the DoT.
				OvaleFuture:UpdateSnapshotFromSpellcast(aura, spellcast)
			end

			local si = OvaleData.spellInfo[auraId]
			if si then
				-- Set the tick information for known DoTs.
				if si.tick then
					Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    %s (%s) is a periodic aura.", name, auraId)
					-- Only set the initial tick information for new auras.
					if not auraIsActive then
						aura.baseTick = si.tick
						if spellcast and spellcast.target == guid then
							aura.tick = OvaleData:GetTickLength(auraId, spellcast.snapshot)
						else
							aura.tick = OvaleData:GetTickLength(auraId)
						end
					end
				end
				-- Set the cooldown expiration time for player buffs applied by items with a cooldown.
				if si.buff_cd and guid == self_guid then
					Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    %s (%s) is applied by an item with a cooldown of %ds.", name, auraId, si.buff_cd)
					if not auraIsActive then
						-- cooldownEnding is the earliest time at which we expect to gain this buff again.
						aura.cooldownEnding = aura.gain + si.buff_cd
					end
				end
			end
		end
		if not auraIsActive then
			self:SendMessage("Ovale_AuraAdded", atTime, guid, auraId, aura.source)
		elseif not auraIsUnchanged then
			self:SendMessage("Ovale_AuraChanged", atTime, guid, auraId, aura.source)
		end
		local unitId = OvaleGUID:GetUnitId(guid)
		if unitId then
			Ovale.refreshNeeded[unitId] = true
		end
	end
	profiler.Stop("OvaleAura_GainedAuraOnGUID")
end

function OvaleAura:LostAuraOnGUID(guid, atTime, auraId, casterGUID)
	profiler.Start("OvaleAura_LostAuraOnGUID")
	local aura = GetAura(self.aura, guid, auraId, casterGUID)
	if aura then
		local filter = aura.filter
		Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    Expiring %s %s (%d) from %s at %f.",
			filter, aura.name, auraId, guid, atTime)
		if aura.ending > atTime then
			aura.ending = atTime
		end

		local mine = (casterGUID == self_guid)
		if mine then
			-- Clear old tick information for player-applied periodic auras.
			aura.baseTick = nil
			aura.lastTickTime = nil
			aura.tick = nil

			-- Check if the aura was consumed by the last spellcast.
			-- The aura must have ended early, i.e., start + duration > ending.
			if aura.start + aura.duration > aura.ending then
				local spellcast
				if guid == self_guid then
					-- Player aura, so it was possibly consumed by an in-flight spell.
					spellcast = OvaleFuture:LastInFlightSpell()
				else
					-- Non-player aura, so it was possibly consumed by a spell that landed on its target.
					spellcast = OvaleFuture.lastSpellcast
				end
				if spellcast and spellcast.stop and IsWithinAuraLag(spellcast.stop, aura.ending) then
					aura.consumed = true
					local spellName = OvaleSpellBook:GetSpellName(spellcast.spellId) or "Unknown spell"
					Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    Consuming %s %s (%d) on %s with %s (%d) at %f.",
						filter, aura.name, auraId, guid, spellName, spellcast.spellId, spellcast.stop)
				end
			end
		end
		aura.lastUpdated = atTime

		self:SendMessage("Ovale_AuraRemoved", atTime, guid, auraId, aura.source)
		local unitId = OvaleGUID:GetUnitId(guid)
		if unitId then
			Ovale.refreshNeeded[unitId] = true
		end
	end
	profiler.Stop("OvaleAura_LostAuraOnGUID")
end

-- Scan auras on the given GUID and update the aura database.
function OvaleAura:ScanAurasOnGUID(guid, unitId)
	if not unitId then return end

	profiler.Start("OvaleAura_ScanAurasOnGUID")
	guid = guid or OvaleGUID:GetGUID(unitId)
	local now = API_GetTime()
	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "Scanning auras on %s (%s) at %f", guid, unitId, now)

	-- Advance the age of the unit's auras.
	local serial = self.serial[guid] or 0
	serial = serial + 1
	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    Advancing age of auras for %s (%s) to %d.", guid, unitId, serial)
	self.serial[guid] = serial

	-- Add all auras on the unit into the database.
	local i = 1
	local filter = "HELPFUL"
	while true do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId,
			canApplyAura, isBossDebuff, isCastByPlayer, value1, value2, value3 = API_UnitAura(unitId, i, filter)
		if not name then
			if filter == "HELPFUL" then
				filter = "HARMFUL"
				i = 1
			else
				break
			end
		else
			local casterGUID = OvaleGUID:GetGUID(unitCaster)
			self:GainedAuraOnGUID(guid, now, spellId, casterGUID, filter, true, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3)
			i = i + 1
		end
	end

	-- Find recently expired auras on the unit.
	if self.aura[guid] then
		local auraTable = self.aura[guid]
		for auraId, whoseTable in pairs(auraTable) do
			for casterGUID, aura in pairs(whoseTable) do
				if aura.serial == serial - 1 then
					if aura.visible then
						-- Remove the aura if it was visible.
						self:LostAuraOnGUID(guid, now, auraId, casterGUID)
					else
						-- Age any hidden auras that are managed by outside modules.
						aura.serial = serial
					end
				end
			end
		end
	end
	profiler.Stop("OvaleAura_ScanAurasOnGUID")
end

function OvaleAura:ScanAuras(unitId)
	local guid = OvaleGUID:GetGUID(unitId)
	if guid then
		return self:ScanAurasOnGUID(guid, unitId)
	end
end

function OvaleAura:GetAuraByGUID(guid, auraId, filter, mine)
	-- If this GUID has no auras in the database, then do an aura scan.
	if not self.serial[guid] then
		local unitId = OvaleGUID:GetUnitId(guid)
		self:ScanAurasOnGUID(guid, unitId)
	end

	local auraFound
	if OvaleData.buffSpellList[auraId] then
		for id in pairs(OvaleData.buffSpellList[auraId]) do
			local aura = GetAuraOnGUID(self.aura, guid, id, filter, mine)
			if aura and (not auraFound or auraFound.ending < aura.ending) then
				auraFound = aura
			end
		end
	else
		auraFound = GetAuraOnGUID(self.aura, guid, auraId, filter, mine)
	end
	return auraFound
end

function OvaleAura:GetAura(unitId, auraId, filter, mine)
	local guid = OvaleGUID:GetGUID(unitId)
	return self:GetAuraByGUID(guid, auraId, filter, mine)
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleAura.statePrototype = {
	aura = nil,
	serial = nil,
}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleAura.statePrototype
--</private-static-properties>

--<state-properties>
-- Aura database: aura[guid][auraId][casterId] = aura
statePrototype.aura = nil
-- Age of active auras in the simulator.
statePrototype.serial = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleAura:InitializeState(state)
	state.aura = {}
	state.serial = 0
end

-- Reset the state to the current conditions.
function OvaleAura:ResetState(state)
	profiler.Start("OvaleAura_ResetState")
	-- Advance age of auras in state machine.
	state.serial = state.serial + 1

	-- Garbage-collect auras in the state machine that are more recently updated in the true aura database.
	if next(state.aura) then
		Ovale:Log("Resetting aura state:")
	end
	for guid, auraTable in pairs(state.aura) do
		for auraId, whoseTable in pairs(auraTable) do
			for casterGUID, aura in pairs(whoseTable) do
				self_pool:Release(aura)
				whoseTable[casterGUID] = nil
				Ovale:Logf("    Aura %d on %s removed, now=%f.", auraId, guid, state.currentTime)
			end
			if not next(whoseTable) then
				self_pool:Release(whoseTable)
				auraTable[auraId] = nil
			end
		end
		if not next(auraTable) then
			self_pool:Release(auraTable)
			state.aura[guid] = nil
		end
	end
	profiler.Stop("OvaleAura_ResetState")
end

-- Release state resources prior to removing from the simulator.
function OvaleAura:CleanState(state)
	for guid in pairs(state.aura) do
		RemoveAurasOnGUID(state.aura, guid)
	end
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleAura:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast)
	profiler.Start("OvaleAura_ApplySpellAfterCast")
	local si = OvaleData.spellInfo[spellId]
	-- Apply the auras on the player.
	if si and si.aura and si.aura.player then
		state:ApplySpellAuras(spellId, self_guid, startCast, endCast, isChanneled, si.aura.player, spellcast)
	end
	profiler.Stop("OvaleAura_ApplySpellAfterCast")
end

-- Apply the effects of the spell on the target's state after it lands on the target.
function OvaleAura:ApplySpellAfterHit(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast)
	profiler.Start("OvaleAura_ApplySpellAfterHit")
	local si = OvaleData.spellInfo[spellId]
	-- Apply the auras on the target.
	if si and si.aura and si.aura.target then
		state:ApplySpellAuras(spellId, targetGUID, startCast, endCast, isChanneled, si.aura.target, spellcast)
	end
	profiler.Stop("OvaleAura_ApplySpellAfterHit")
end
--</public-static-methods>

--<state-methods>
local function GetStateAura(state, guid, auraId, casterGUID)
	local aura = GetAura(state.aura, guid, auraId, casterGUID)
	if not aura or aura.serial < state.serial then
		aura = GetAura(OvaleAura.aura, guid, auraId, casterGUID)
	end
	return aura
end

local function GetStateAuraAnyCaster(state, guid, auraId)
	--[[
		Loop over all of the auras in the true aura database and the state machine aura
		database and find the one with the latest expiration time.
	--]]
	local auraFound
	if OvaleAura.aura[guid] and OvaleAura.aura[guid][auraId] then
		for casterGUID in pairs(OvaleAura.aura[guid][auraId]) do
			local aura = GetStateAura(state, guid, auraId, casterGUID)
			-- Skip over auras found in the state machine for now.
			if not aura.state and OvaleAura:IsActiveAura(aura, state.currentTime) then
				if not auraFound or auraFound.ending < aura.ending then
					auraFound = aura
				end
			end
		end
	end
	if state.aura[guid] and state.aura[guid][auraId] then
		for casterGUID, aura in pairs(state.aura[guid][auraId]) do
			if aura.stacks > 0 then
				if not auraFound or auraFound.ending < aura.ending then
					auraFound = aura
				end
			end
		end
	end
	return auraFound
end

local function GetStateDebuffType(state, guid, debuffType, filter, casterGUID)
	--[[
		Loop over all of the auras in the true aura database and the state machine aura
		database and find the one with the latest expiration time.
	--]]
	local auraFound
	if OvaleAura.aura[guid] then
		for auraId in pairs(OvaleAura.aura[guid]) do
			local aura = GetStateAura(state, guid, auraId, casterGUID)
			-- Skip over auras found in the state machine for now.
			if aura and not aura.state and OvaleAura:IsActiveAura(aura, state.currentTime) then
				if aura.debuffType == debuffType and aura.filter == filter then
					if not auraFound or auraFound.ending < aura.ending then
						auraFound = aura
					end
				end
			end
		end
	end
	if state.aura[guid] then
		for auraId, whoseTable in pairs(state.aura[guid]) do
			local aura = whoseTable[casterGUID]
			if aura and aura.stacks > 0 then
				if aura.debuffType == debuffType and aura.filter == filter then
					if not auraFound or auraFound.ending < aura.ending then
						auraFound = aura
					end
				end
			end
		end
	end
	return auraFound
end

local function GetStateDebuffTypeAnyCaster(state, guid, debuffType, filter)
	--[[
		Loop over all of the auras in the true aura database and the state machine aura
		database and find the one with the latest expiration time.
	--]]
	local auraFound
	if OvaleAura.aura[guid] then
		for auraId, whoseTable in pairs(OvaleAura.aura[guid]) do
			for casterGUID in pairs(whoseTable) do
				local aura = GetStateAura(state, guid, auraId, casterGUID)
				if aura and not aura.state and OvaleAura:IsActiveAura(aura, state.currentTime) then
					if aura.debuffType == debuffType and aura.filter == filter then
						if not auraFound or auraFound.ending < aura.ending then
							auraFound = aura
						end
					end
				end
			end
		end
	end
	if state.aura[guid] then
		for auraId, whoseTable in pairs(state.aura[guid]) do
			for casterGUID, aura in pairs(whoseTable) do
				if aura and not aura.state and aura.stacks > 0 then
					if aura.debuffType == debuffType and aura.filter == filter then
						if not auraFound or auraFound.ending < aura.ending then
							auraFound = aura
						end
					end
				end
			end
		end
	end
	return auraFound
end

local function GetStateAuraOnGUID(state, guid, auraId, filter, mine)
	local auraFound
	if DEBUFF_TYPES[auraId] then
		if mine then
			auraFound = GetStateDebuffType(state, guid, auraId, filter, self_guid)
		else
			auraFound = GetStateDebuffTypeAnyCaster(state, guid, auraId, filter)
		end
	else
		if mine then
			local aura = GetStateAura(state, guid, auraId, self_guid)
			if aura and aura.stacks > 0 then
				auraFound = aura
			end
		else
			auraFound = GetStateAuraAnyCaster(state, guid, auraId)
		end
	end
	return auraFound
end

-- Print the auras matching the filter on the unit in alphabetical order.
do
	local array = {}

	statePrototype.PrintUnitAuras = function(state, unitId, filter)
		wipe(array)
		local guid = OvaleGUID:GetGUID(unitId)
		if OvaleAura.aura[guid] then
			for auraId, whoseTable in pairs(OvaleAura.aura[guid]) do
				for casterGUID in pairs(whoseTable) do
					local aura = GetStateAura(state, guid, auraId, casterGUID)
					if state:IsActiveAura(aura) and aura.filter == filter and not aura.state then
						local name = aura.name or "Unknown spell"
						tinsert(array, name .. ": " .. auraId)
					end
				end
			end
		end
		if state.aura[guid] then
			for auraId, whoseTable in pairs(state.aura[guid]) do
				for casterGUID, aura in pairs(whoseTable) do
					if state:IsActiveAura(aura) and aura.filter == filter then
						local name = aura.name or "Unknown spell"
						tinsert(array, name .. ": " .. auraId)
					end
				end
			end
		end
		if next(array) then
			tsort(array)
			for _, v in ipairs(array) do
				Ovale:Print(v)
			end
		end
	end
end

statePrototype.IsActiveAura = function(state, aura, atTime)
	-- Default to checking if an aura is active at the end of the current spellcast
	-- in the simulator, or at the current time if no spell is being cast.
	if not atTime then
		if state.endCast and state.endCast > state.currentTime then
			atTime = state.endCast
		else
			atTime = state.currentTime
		end
	end
	local boolean = false
	if aura then
		if aura.state then
			if aura.serial == state.serial and aura.stacks > 0 and aura.gain <= atTime and atTime <= aura.ending then
				boolean = true
			elseif aura.consumed and IsWithinAuraLag(aura.ending, atTime) then
				boolean = true
			end
		else
			boolean = OvaleAura:IsActiveAura(aura, atTime)
		end
	end
	return boolean
end

statePrototype.ApplySpellAuras = function(state, spellId, guid, startCast, endCast, isChanneled, auraList, spellcast)
	profiler.Start("OvaleAura_state_ApplySpellAuras")
	local unitId = OvaleGUID:GetUnitId(guid)
	for filter, filterInfo in pairs(auraList) do
		for auraId, spellData in pairs(filterInfo) do
			--[[
				For lists described by SpellAddBuff(), etc., use the following interpretation:
					auraId=extend,N		aura is extended by N seconds, no change to stacks
					auraId=refresh		aura is refreshed, no change to stacks
					auraId=N, N > 0		N is duration if aura has no duration SpellInfo() [deprecated].
					auraId=N, N > 0		N is number of stacks added
					auraId=0			aura is removed
					auraId=N, N < 0		N is number of stacks of aura removed
			--]]
			local si = OvaleData.spellInfo[auraId]
			local duration = OvaleData:GetBaseDuration(auraId, spellcast)
			local stacks = 1
			local refresh = false
			local extend = 0

			-- Parser for spellData as comma-separated values.
			local tokenIterator = gmatch(spellData, "[^,]+")

			-- Set stacks and refresh based on spellData.
			local value = tokenIterator()
			if value == "refresh" then
				refresh = true
			elseif value == "extend" then
				local seconds = tokenIterator()
				if seconds then
					extend = tonumber(seconds)
				else
					Ovale:OneTimeMessage("Warning: '%d=%s' has '%s' missing duration.", auraId, spellData, value)
				end
			else
				value = tonumber(value)
				if value then
					stacks = value
					-- Deprecated after transition.
					if not (si and si.duration) and value > 0 then
						-- Aura doesn't have duration SpellInfo(), so treat spell data as duration.
						Ovale:OneTimeMessage("Warning: '%s=%d' is deprecated for spell ID %d; aura ID %s should have duration information.", auraId, value, spellId, auraId)
						duration = value
						stacks = 1
					end
				end
			end

			-- Verify any conditions for this aura.
			local verified = true
			local condition = tokenIterator()
			while verified and condition do
				Ovale:Logf("Aura %d has conditions:")
				if condition == "buff" or condition == "debuff" or condition == "target_buff" or condition == "target_debuff" then
					local buffName = tokenIterator()
					if buffName then
						local isBang = false
						if substr(buffName, 1, 1) == "!" then
							buffName = substr(buffName, 2)
						end
						local buffId = tonumber(buffName)
						local buffUnitId = (substr(condition, 1, 7) == "target_") and state.defaultTarget or "player"
						local result = "fail"
						local aura
						if buffId then
							aura = state:GetAura(buffUnitId, buffId)
						else
							aura = state:GetAura(buffUnitId, buffName)
						end
						local isActiveAura = state:IsActiveAura(aura)
						if not isBang and isActiveAura or isBang and not isActiveAura then
							result = "pass"
							verified = true
						end
						if isBang then
							Ovale:Logf("    Aura %s missing on %s: %s", buffId, buffName, result)
						else
							Ovale:Logf("    Aura %s on %s: %s", buffId, buffName, result)
						end
					else
						Ovale:OneTimeMessage("Warning: '%d=%s' has '%s' missing buff.", auraId, spellData, condition)
					end
				elseif condition == "target_health_pct" then
					local threshold = tokenIterator()
					if threshold then
						local isBang = false
						if substr(threshold, 1, 1) == "!" then
							threshold = substr(threshold, 2)
						end
						threshold = tonumber(threshold) or 0
						local healthPercent = API_UnitHealth(unitId) / API_UnitHealthMax(unitId) * 100
						local result = "fail"
						if not isBang and healthPercent <= threshold or isBang and healthPercent > threshold then
							result = "pass"
							verified = true
						end
						if isBang then
							Ovale:Logf("    Target health > %f%%: %s", threshold, result)
						else
							Ovale:Logf("    Target health <= %f%%: %s", threshold, result)
						end
					else
						Ovale:OneTimeMessage("Warning: '%d=%s' has '%s' missing threshold.", auraId, spellData, condition)
					end
				end
				condition = tokenIterator()
			end

			if verified then
				local auraFound = state:GetAuraByGUID(guid, auraId, filter, true)
				local atTime = isChanneled and startCast or endCast

				if state:IsActiveAura(auraFound, atTime) then
					local aura
					if auraFound.state then
						-- Re-use existing aura in the simulator.
						aura = auraFound
					else
						-- Add an aura in the simulator and copy the existing aura information over.
						aura = state:AddAuraToGUID(guid, auraId, auraFound.source, filter, 0, math.huge)
						for k, v in pairs(auraFound) do
							aura[k] = v
						end
						if auraFound.snapshot then
							aura.snapshot = OvalePaperDoll:GetSnapshot(auraFound.snapshot)
						end
						-- Reset the aura age relative to the state of the simulator.
						aura.serial = state.serial
						Ovale:Logf("Aura %d is copied into simulator.", auraId)
						-- Information that needs to be set below: stacks, start, ending, duration, gain.
					end
					-- Spell starts channeling before the aura expires, or spellcast ends before the aura expires.
					if refresh or extend > 0 or stacks > 0 then
						-- Adjust stack count.
						if refresh then
							Ovale:Logf("Aura %d is refreshed to %d stack(s).", auraId, aura.stacks)
						elseif extend > 0 then
							Ovale:Logf("Aura %d is extended by %f seconds, preserving %d stack(s).", auraId, extend, aura.stacks)
						else -- if stacks > 0 then
							local maxStacks = 1
							if si and (si.max_stacks or si.maxstacks) then
								maxStacks = si.max_stacks or si.maxstacks
							end
							aura.stacks = aura.stacks + stacks
							if aura.stacks > maxStacks then
								aura.stacks = maxStacks
							end
							Ovale:Logf("Aura %d gains %d stack(s) to %d because of spell %d.", auraId, stacks, aura.stacks, spellId)
						end
						-- Set start, ending, and duration for the aura.
						if extend > 0 then
							-- aura.start is preserved.
							aura.duration = aura.duration + extend
							aura.ending = aura.ending + extend
						else
							aura.start = atTime
							if aura.tick and aura.tick > 0 then
								-- This is a periodic aura, so add new duration to extend the aura up to 130% of the normal duration.
								local remainingDuration = aura.ending - atTime
								local extensionDuration = 0.3 * duration
								if remainingDuration < extensionDuration then
									-- Aura is extended by the normal duration.
									aura.duration = remainingDuration + duration
								else
									aura.duration = extensionDuration + duration
								end
							else
								aura.duration = duration
							end
							aura.ending = aura.start + aura.duration
						end
						aura.gain = atTime
						Ovale:Logf("Aura %d with duration %f now ending at %f", auraId, aura.duration, aura.ending)
					elseif stacks == 0 or stacks < 0 then
						if stacks == 0 then
							aura.stacks = 0
						else -- if stacks < 0 then
							aura.stacks = aura.stacks + stacks
							if aura.stacks < 0 then
								aura.stacks = 0
							end
							Ovale:Logf("Aura %d loses %d stack(s) to %d because of spell %d.", auraId, -1 * stacks, aura.stacks, spellId)
						end
						-- An existing aura is losing stacks, so inherit start, duration, ending and gain information.
						if aura.stacks == 0 then
							Ovale:Logf("Aura %d is completely removed.", auraId)
							-- The aura is completely removed, so set ending to the time that the aura is removed.
							aura.ending = atTime
							aura.consumed = true
						end
					end
				else
					-- Aura is not on the target.
					if not refresh and stacks > 0 then
						-- Spellcast causes a new aura.
						Ovale:Logf("New aura %d at %f on %s", auraId, atTime, guid)
						-- Add an aura in the simulator and copy the existing aura information over.
						local aura = state:AddAuraToGUID(guid, auraId, self_guid, filter, 0, math.huge)
						-- Information that needs to be set below: stacks, start, ending, duration, gain.
						aura.stacks = stacks
						-- Set start and duration for aura.
						aura.start = atTime
						aura.duration = duration
						-- If "tick" is set explicitly in SpellInfo, then this is a known periodic aura.
						if si and si.tick then
							aura.baseTick = si.tick
							aura.tick = OvaleData:GetTickLength(auraId, spellcast.snapshot)
						end
						aura.ending = aura.start + aura.duration
						aura.gain = aura.start
						OvaleFuture:UpdateSnapshotFromSpellcast(aura, spellcast)
					end
				end
			else
				Ovale:Logf("Aura %d is not applied.")
			end
		end
	end
	profiler.Stop("OvaleAura_state_ApplySpellAuras")
end

statePrototype.GetAuraByGUID = function(state, guid, auraId, filter, mine)
	local auraFound
	if OvaleData.buffSpellList[auraId] then
		for id in pairs(OvaleData.buffSpellList[auraId]) do
			local aura = GetStateAuraOnGUID(state, guid, id, filter, mine)
			if aura and (not auraFound or auraFound.ending < aura.ending) then
				Ovale:Logf("Aura %s matching '%s' found on %s with (%f, %f)", id, auraId, guid, aura.start, aura.ending)
				auraFound = aura
			else
				Ovale:Logf("Aura %s matching '%s' is missing on %s.", id, auraId, guid)
			end
		end
		if not auraFound then
			Ovale:Logf("Aura matching '%s' is missing on %s.", auraId, guid)
		end
	else
		auraFound = GetStateAuraOnGUID(state, guid, auraId, filter, mine)
		if auraFound then
			Ovale:Logf("Aura %s found on %s with (%f, %f)", auraId, guid, auraFound.start, auraFound.ending)
		else
			Ovale:Logf("Aura %s is missing on %s.", auraId, guid)
		end
	end
	return auraFound
end

statePrototype.GetAura = function(state, unitId, auraId, filter, mine)
	local guid = OvaleGUID:GetGUID(unitId)
	return state:GetAuraByGUID(guid, auraId, filter, mine)
end

-- Add a new aura to the unit specified by GUID.
statePrototype.AddAuraToGUID = function(state, guid, auraId, casterGUID, filter, start, ending, snapshot)
	local aura = self_pool:Get()
	aura.state = true
	aura.serial = state.serial
	aura.lastUpdated = state.currentTime
	aura.filter = filter
	aura.mine = (casterGUID == self_guid)
	aura.start = start or 0
	aura.ending = ending or math.huge
	aura.duration = ending - start
	aura.gain = aura.start
	aura.stacks = 1
	if snapshot then
		aura.snapshot = OvalePaperDoll:GetSnapshot(snapshot)
	end
	PutAura(state.aura, guid, auraId, casterGUID, aura)
	return aura
end

-- Remove an aura from the unit specified by GUID.
statePrototype.RemoveAuraOnGUID = function(state, guid, auraId, filter, mine, atTime)
	local auraFound = state:GetAuraByGUID(guid, auraId, filter, mine)
	if state:IsActiveAura(auraFound, atTime) then
		local aura
		if auraFound.state then
			-- Re-use existing aura in the simulator.
			aura = auraFound
		else
			-- Add an aura in the simulator and copy the existing aura information over.
			aura = state:AddAuraToGUID(guid, auraId, auraFound.source, filter, 0, math.huge)
			for k, v in pairs(auraFound) do
				aura[k] = v
			end
			if auraFound.snapshot then
				aura.snapshot = OvalePaperDoll:GetSnapshot(auraFound.snapshot)
			end
			-- Reset the aura age relative to the state of the simulator.
			aura.serial = state.serial
		end

		-- Expire the aura.
		aura.stacks = 0
		aura.ending = atTime
		aura.lastUpdated = atTime
	end
end

statePrototype.GetAuraWithProperty = function(state, unitId, propertyName, filter)
	local count = 0
	local guid = OvaleGUID:GetGUID(unitId)
	local start, ending = math.huge, 0

	-- Loop through auras not kept in the simulator that match the criteria.
	if OvaleAura.aura[guid] then
		for auraId, whoseTable in pairs(OvaleAura.aura[guid]) do
			for casterGUID in pairs(whoseTable) do
				local aura = GetStateAura(state, guid, auraId, self_guid)
				if state:IsActiveAura(aura) and not aura.state then
					if aura[propertyName] and aura.filter == filter then
						count = count + 1
						start = (aura.gain < start) and aura.gain or start
						ending = (aura.ending > ending) and aura.ending or ending
					end
				end
			end
		end
	end
	-- Loop through auras in the simulator that match the criteria.
	if state.aura[guid] then
		for auraId, whoseTable in pairs(state.aura[guid]) do
			for casterGUID, aura in pairs(whoseTable) do
				if state:IsActiveAura(aura) then
					if aura[propertyName] and aura.filter == filter then
						count = count + 1
						start = (aura.gain < start) and aura.gain or start
						ending = (aura.ending > ending) and aura.ending or ending
					end
				end
			end
		end
	end

	if count > 0 then
		Ovale:Logf("Aura with '%s' property found on %s (count=%s, minStart=%s, maxEnding=%s).", propertyName, unitId, count, start, ending)
	else
		Ovale:Logf("Aura with '%s' property is missing on %s.", propertyName, unitId)
		start, ending = nil
	end
	return start, ending
end

do
	-- The total count of the matched aura.
	local count
	-- The total number of stacks of the matched aura.
	local stacks
	-- The start and ending times of the first aura to expire that will change the total count.
	local startChangeCount, endingChangeCount
	-- The time interval over which count > 0.
	local startFirst, endingLast

	local function CountMatchingActiveAura(aura)
		Ovale:Logf("Counting aura %s found on %s with (%f, %f)", aura.spellId, aura.guid, aura.start, aura.ending)
		count = count + 1
		stacks = stacks + aura.stacks
		if aura.ending < endingChangeCount then
			startChangeCount, endingChangeCount = aura.gain, aura.ending
		end
		if aura.gain < startFirst then
			startFirst = aura.gain
		end
		if aura.ending > endingLast then
			endingLast = aura.ending
		end
	end

	--[[
		Return the total count and stacks of the given aura across all units, the start/end times of
		the first aura to expire that will change the total count, and the time interval over which
		the count is more than 0.  If excludeUnitId is given, then that unit is excluded from the count.
	--]]
	statePrototype.AuraCount = function(state, auraId, filter, mine, minStacks, excludeUnitId)
		profiler.Start("OvaleAura_state_AuraCount")
		-- Initialize.
		minStacks = minStacks or 1
		count = 0
		stacks = 0
		startChangeCount, endingChangeCount = math.huge, math.huge
		startFirst, endingLast = math.huge, 0
		local excludeGUID = excludeUnitId and OvaleGUID:GetGUID(excludeUnitId) or nil

		-- Loop through auras not kept in the simulator that match the criteria.
		for guid, auraTable in pairs(OvaleAura.aura) do
			if guid ~= excludeGUID and auraTable[auraId] then
				if mine then
					local aura = GetStateAura(state, guid, auraId, self_guid)
					if state:IsActiveAura(aura) and aura.filter == filter and aura.stacks >= minStacks and not aura.state then
						CountMatchingActiveAura(aura)
					end
				else
					for casterGUID in pairs(auraTable[auraId]) do
						local aura = GetStateAura(state, guid, auraId, casterGUID)
						if state:IsActiveAura(aura) and aura.filter == filter and aura.stacks >= minStacks and not aura.state then
							CountMatchingActiveAura(aura)
						end
					end
				end
			end
		end
		-- Loop through auras in the simulator that match the criteria.
		for guid, auraTable in pairs(state.aura) do
			if guid ~= excludeGUID and auraTable[auraId] then
				if mine then
					local aura = auraTable[auraId][self_guid]
					if aura then
						if state:IsActiveAura(aura) and aura.filter == filter and aura.stacks >= minStacks then
							CountMatchingActiveAura(aura)
						end
					end
				else
					for casterGUID, aura in pairs(auraTable[auraId]) do
						if state:IsActiveAura(aura) and aura.filter == filter and aura.stacks >= minStacks then
							CountMatchingActiveAura(aura)
						end
					end
				end
			end
		end

		Ovale:Logf("AuraCount(%d) is %s, %s, %s, %s, %s, %s", auraId, count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast)
		profiler.Stop("OvaleAura_state_AuraCount")
		return count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast
	end
end
--</state-methods>
