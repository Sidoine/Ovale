--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

--[[
	This addon tracks all auras for all units.
--]]

local _, Ovale = ...
local OvaleAura = Ovale:NewModule("OvaleAura", "AceEvent-3.0")
Ovale.OvaleAura = OvaleAura

--<private-static-properties>
local OvalePool = Ovale.OvalePool

-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleFuture = nil
local OvaleGUID = nil
local OvalePaperDoll = nil
local OvaleState = nil

local floor = math.floor
local ipairs = ipairs
local pairs = pairs
local select = select
local tinsert = table.insert
local tsort = table.sort
local wipe = table.wipe
local API_GetTime = GetTime
local API_UnitAura = UnitAura
local API_UnitGUID = UnitGUID

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

-- Auras on the target (past & present): self_aura[guid][auraId][casterGUID] = aura.
local self_aura = {}
-- Current age of auras per unit: self_serial[guid] = age.
local self_serial = {}

-- Some auras have a nil caster, so treat those as having a GUID of zero for indexing purposes.
local UNKNOWN_GUID = 0

local OVALE_AURA_DEBUG = "aura"

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
--</private-static-properties>

--<public-static-properties>
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
		Ovale:DebugPrintf(OVALE_AURA_DEBUG, "Removing auras from guid %s", guid)
		local auraTable = auraDB[guid]
		for auraId, whoseTable in pairs(auraTable) do
			for casterGUID, aura in pairs(whoseTable) do
				self_pool:Release(aura)
			end
			self_pool:Release(whoseTable)
			auraTable[auraId] = nil
		end
		self_pool:Release(auraTable)
		auraDB[guid] = nil
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleAura:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvaleFuture = Ovale.OvaleFuture
	OvaleGUID = Ovale.OvaleGUID
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvaleState = Ovale.OvaleState
end

function OvaleAura:OnEnable()
	self_guid = API_UnitGUID("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ScanAllUnitAuras")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
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
	self:UnregisterEvent("PLAYER_UNGHOST")
	self:UnregisterEvent("UNIT_AURA")
	self:UnregisterMessage("Ovale_GroupChanged")
	for guid in pairs(self_aura) do
		RemoveAurasOnGUID(self_aura, guid)
	end
	self_pool:Drain()
end

function OvaleAura:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)

	if CLEU_AURA_EVENTS[event] then
		local unitId = OvaleGUID:GetUnitId(destGUID)
		if unitId and not OvaleGUID.UNIT_AURA_UNITS[unitId] then
			Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s: %s", event, unitId)
			self:ScanAurasOnGUID(destGUID)
		end
	elseif sourceGUID == self_guid and CLEU_TICK_EVENTS[event] then
		-- Update the latest tick time of the periodic aura cast by the player.
		local spellId, spellName, spellSchool = select(12, ...)
		local unitId = OvaleGUID:GetUnitId(destGUID)
		Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s: %s", event, unitId)
		local aura = GetAura(self_aura, destGUID, spellId, self_guid)
		if self:IsActiveAura(aura) then
			local tick, ticksSeen, lastTickTime = aura.tick, aura.ticksSeen, aura.lastTickTime
			if not lastTickTime then
				tick = aura.tick or OvaleData:GetTickLength(spellId)
				ticksSeen = aura.ticksSeen or 0
			else
				-- Tick times tend to vary about the "true" value by a up to a few
				-- hundredths of a second.  Keep a running average to try to protect
				-- against unusually short or long tick times.
				tick = ((tick * ticksSeen) + (timestamp - lastTickTime)) / (ticksSeen + 1)
				ticksSeen = ticksSeen + 1
			end
			aura.tick = tick
			aura.ticksSeen = ticksSeen
			aura.lastTickTime = timestamp
			local name = aura.name or "Unknown spell"
			Ovale:DebugPrintf(OVALE_AURA_DEBUG, "Updating %s %s (%s) on %s, tick=%f", filter, name, spellId, destGUID, tick)
		end
	end
end

function OvaleAura:PLAYER_ALIVE(event)
	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s", event)
	self:ScanAurasOnGUID(self_guid)
end

function OvaleAura:PLAYER_REGEN_ENABLED(event)
	self:RemoveAurasOnInactiveUnits()
	self_pool:Drain()
end

function OvaleAura:UNIT_AURA(event, unitId)
	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s: %s", event, unitId)
	self:ScanAuras(unitId)
end

function OvaleAura:ScanAllUnitAuras()
	-- Update auras on all visible units.
	for unitId in pairs(OvaleGUID.UNIT_AURA_UNITS) do
		self:ScanAuras(unitId)
	end
end

function OvaleAura:RemoveAurasOnInactiveUnits()
	-- Remove all auras from GUIDs that can no longer be referenced by a unit ID,
	-- i.e., not in the group or not targeted by anyone in the group or focus.
	for guid in pairs(self_aura) do
		local unitId = OvaleGUID:GetUnitId(guid)
		if not unitId then
			RemoveAurasOnGUID(self_aura, guid)
			self_serial[guid] = nil
		end
	end
end

function OvaleAura:IsActiveAura(aura, now)
	now = now or API_GetTime()
	return (aura and aura.serial == self_serial[aura.guid] and aura.stacks > 0 and aura.start <= now and now <= aura.ending)
end

function OvaleAura:GainedAuraOnGUID(guid, atTime, auraId, casterGUID, filter, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3)
	-- Whose aura is it?
	casterGUID = casterGUID or UNKNOWN_GUID
	local mine = (casterGUID == self_guid)

	-- UnitAura() can return zero count for auras that are present.
	count = (count and count > 0) and count or 1
	-- "Zero" or nil duration and expiration actually mean the aura never expires.
	duration = (duration and duration > 0) and duration or math.huge
	expirationTime = (expirationTime and expirationTime > 0) and expirationTime or math.huge

	local aura = GetAura(self_aura, guid, auraId, casterGUID)
	local auraIsActive
	if aura then
		auraIsActive = (aura.stacks > 0 and aura.start <= atTime and atTime <= aura.ending)
	else
		aura = self_pool:Get()
		PutAura(self_aura, guid, auraId, casterGUID, aura)
		auraIsActive = false
	end

	-- Only overwrite an active aura's information if the aura has changed.
	-- An aura's "fingerprint" is its: caster, duration, expiration time, stack count.
	local auraIsUnchanged = (
		aura.source == casterGUID
			and aura.duration == duration
			and aura.ending == expirationTime
			and aura.stacks == count
	)

	-- Update age of aura, regardless of whether it's changed.
	aura.serial = self_serial[guid]

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
		aura.stacks = count
		aura.filter = filter
		aura.icon = icon
		aura.debuffType = debuffType
		aura.stealable = isStealable
		aura.value1, aura.value2, aura.value3 = value1, value2, value3

		-- Snapshot stats for auras applied by the player.
		if mine then
			-- Determine whether to snapshot player stats for the aura or to keep the existing stats.
			local lastSpellcast = OvaleFuture.lastSpellcast
			local lastSpellId = lastSpellcast and lastSpellcast.spellId
			if lastSpellId and OvaleData:NeedNewSnapshot(auraId, lastSpellId) then
				Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    Snapshot stats for %s %s (%d) on %s from %f, now=%f, aura.serial=%d",
					filter, name, auraId, guid, lastSpellcast.snapshot.snapshotTime, atTime, aura.serial)
				-- TODO: damageMultiplier isn't correct if lastSpellId spreads the DoT.
				OvaleFuture:UpdateSnapshotFromSpellcast(aura, lastSpellcast)
			end

			-- Set the tick information for known DoTs.
			local si = OvaleData.spellInfo[auraId]
			if si and si.tick then
				Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    %s (%s) is a periodic aura.", name, auraId)
				-- Only set the initial tick information for new auras.
				if not auraIsActive then
					aura.ticksSeen = 0
					aura.tick = OvaleData:GetTickLength(auraId)
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
end

function OvaleAura:LostAuraOnGUID(guid, atTime, auraId, casterGUID)
	local aura = GetAura(self_aura, guid, auraId, casterGUID)
	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    Expiring %s %s (%s) from %s at %f.",
		aura.filter, aura.name, auraId, guid, atTime)
	if aura.ending > atTime then
		aura.ending = atTime
	end
	self:SendMessage("Ovale_AuraRemoved", atTime, guid, auraId, aura.source)
	local unitId = OvaleGUID:GetUnitId(guid)
	if unitId then
		Ovale.refreshNeeded[unitId] = true
	end
end

-- Scan auras on the given GUID and update the aura database.
function OvaleAura:ScanAurasOnGUID(guid)
	if not guid then return end
	local unitId = OvaleGUID:GetUnitId(guid)
	if not unitId then return end

	local now = API_GetTime()
	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "Scanning auras on %s (%s) at %f", guid, unitId, now)

	-- Advance the age of the unit's auras.
	self_serial[guid] = self_serial[guid] and (self_serial[guid] + 1) or 1
	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    Advancing age of auras for %s (%s) to %d.", guid, unitId, self_serial[guid])

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
			self:GainedAuraOnGUID(guid, now, spellId, casterGUID, filter, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3)
			i = i + 1
		end
	end

	-- Find recently expired auras on the unit.
	if self_aura[guid] then
		local auraTable = self_aura[guid]
		local serial = self_serial[guid]
		for auraId, whoseTable in pairs(auraTable) do
			for casterGUID, aura in pairs(whoseTable) do
				if aura.serial == serial - 1 then
					self:LostAuraOnGUID(guid, now, auraId, casterGUID)
				end
			end
		end
	end
end

function OvaleAura:ScanAuras(unitId)
	local guid = OvaleGUID:GetGUID(unitId)
	if guid then
		return self:ScanAurasOnGUID(guid)
	end
end

function OvaleAura:GetAuraByGUID(guid, auraId, filter, mine)
	-- If this GUID has no auras in the database, then do an aura scan.
	if not self_serial[guid] then
		self:ScanAurasOnGUID(guid)
	end

	local auraFound
	if OvaleData.buffSpellList[auraId] then
		for id in pairs(OvaleData.buffSpellList[auraId]) do
			local aura = GetAuraOnGUID(self_aura, guid, id, filter, mine)
			if aura and (not auraFound or auraFound.ending < aura.ending) then
				auraFound = aura
			end
		end
	else
		auraFound = GetAuraOnGUID(self_aura, guid, auraId, filter, mine)
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
	-- Periodically garbage-collect auras in the state machine.
	if not Ovale.enCombat and state.serial % 1000 then
		self:CleanState(state)
	end
	state.serial = state.serial + 1
end

-- Release state resources prior to removing from the simulator.
function OvaleAura:CleanState(state)
	for guid in pairs(state.aura) do
		RemoveAurasOnGUID(state.aura, guid)
	end
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleAura:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast)
	local si = OvaleData.spellInfo[spellId]
	-- Apply the auras on the player.
	if si and si.aura and si.aura.player then
		state:ApplySpellAuras(spellId, self_guid, startCast, endCast, isChanneled, si.aura.player, spellcast)
	end
end

-- Apply the effects of the spell on the target's state when it lands on the target.
function OvaleAura:ApplySpellOnHit(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast)
	local si = OvaleData.spellInfo[spellId]
	-- Apply the auras on the target.
	if si and si.aura and si.aura.target then
		state:ApplySpellAuras(spellId, targetGUID, startCast, endCast, isChanneled, si.aura.target, spellcast)
	end
end
--</public-static-methods>

--<state-methods>
local function GetStateAura(state, guid, auraId, casterGUID)
	local auraFound = GetAura(state.aura, guid, auraId, casterGUID)
	if not state:IsActiveAura(auraFound) then
		auraFound = GetAura(self_aura, guid, auraId, casterGUID)
	end
	return auraFound
end

local function GetStateAuraAnyCaster(state, guid, auraId)
	local auraFound = GetAuraAnyCaster(state.aura, guid, auraId)
	local aura = GetAuraAnyCaster(self_aura, guid, auraId)
	local now = state.currentTime
	if OvaleAura:IsActiveAura(aura, now) then
		if not state:IsActiveAura(auraFound, now) or auraFound.ending < aura.ending then
			auraFound = aura
		end
	end
	return auraFound
end

local function GetStateDebuffType(state, guid, debuffType, filter, casterGUID)
	local auraFound = GetDebuffType(state.aura, guid, debuffType, filter, casterGUID)
	local aura = GetDebuffType(self_aura, guid, debuffType, filter, casterGUID)
	local now = state.currentTime
	if OvaleAura:IsActiveAura(aura, now) then
		if not state:IsActiveAura(auraFound, now) or auraFound.ending < aura.ending then
			auraFound = aura
		end
	end
	return auraFound
end

local function GetStateDebuffTypeAnyCaster(state, guid, debuffType, filter)
	local auraFound = GetDebuffTypeAnyCaster(state.aura, guid, debuffType, filter)
	local aura = GetDebuffTypeAnyCaster(self_aura, guid, debuffType, filter)
	local now = state.currentTime
	if OvaleAura:IsActiveAura(aura, now) then
		if not state:IsActiveAura(auraFound, now) or auraFound.ending < aura.ending then
			auraFound = aura
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
			auraFound = GetStateAura(state, guid, auraId, self_guid)
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
		if self_aura[guid] then
			for auraId, whoseTable in pairs(self_aura[guid]) do
				for casterGUID in pairs(whoseTable) do
					local aura = GetStateAura(state, guid, auraId, casterGUID)
					if state:IsActiveAura(aura, now) and aura.filter == filter and not aura.state then
						local name = aura.name or "Unknown spell"
						tinsert(array, name .. ": " .. auraId)
					end
				end
			end
		end
		if state.aura[guid] then
			for auraId, whoseTable in pairs(state.aura[guid]) do
				for casterGUID, aura in pairs(whoseTable) do
					if state:IsActiveAura(aura, now) and aura.filter == filter then
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

statePrototype.IsActiveAura = function(state, aura, now)
	now = now or state.currentTime
	local boolean = false
	if aura then
		if aura.state then
			boolean = (aura.serial == state.serial and aura.stacks > 0 and aura.start <= now and now <= aura.ending)
		else
			boolean = OvaleAura:IsActiveAura(aura, now)
		end
	end
	return boolean
end

statePrototype.ApplySpellAuras = function(state, spellId, guid, startCast, endCast, isChanneled, auraList, spellcast)
	local unitId = OvaleGUID:GetUnitId(guid)
	for filter, filterInfo in pairs(auraList) do
		for auraId, spellData in pairs(filterInfo) do
			--[[
				For lists described by SpellAddBuff(), etc., use the following interpretation:
					auraId=refresh		aura is refreshed, no change to stacks
					auraId=N, N > 0		N is duration if aura has no duration SpellInfo() [deprecated].
					auraId=N, N > 0		N is number of stacks added
					auraId=0			aura is removed
					auraId=N, N < 0		N is number of stacks of aura removed
			--]]
			local si = OvaleData.spellInfo[auraId]
			local duration, dotDuration, tick, numTicks = state:GetDuration(auraId, spellcast)
			local stacks = 1

			if type(spellData) == "number" and spellData > 0 then
				stacks = spellData
				-- Deprecated after transition.
				if not (si and si.duration) then
					-- Aura doesn't have duration SpellInfo(), so treat spell data as duration.
					duration = spellData
					stacks = 1
				end
			end

			local auraFound = state:GetAuraByGUID(guid, auraId, filter, true)
			local atTime = isChanneled and startCast or endCast

			if state:IsActiveAura(auraFound, atTime) then
				local aura
				if auraFound.state then
					-- Re-use existing aura in the simulator.
					aura = auraFound
				else
					-- Add an aura in the simulator and copy the existing aura information over.
					aura = state:AddAuraToGUID(guid, auraId, self_guid, filter, 0, math.huge)
					for k, v in pairs(auraFound) do
						aura[k] = v
					end
					if auraFound.snapshot then
						aura.snapshot = OvalePaperDoll:GetSnapshot(auraFound.snapshot)
					end
					-- Reset the aura age relative to the state of the simulator.
					aura.serial = state.serial
					-- Information that needs to be set below: stacks, start, ending, duration, gain.
				end
				-- Spell starts channeling before the aura expires, or spellcast ends before the aura expires.
				if spellData == "refresh" or stacks > 0 then
					-- Adjust stack count.
					if spellData == "refresh" then
						Ovale:Logf("Aura %d is refreshed.", auraId)
					else -- if stacks > 0 then
						local maxstacks = si.maxstacks or 1
						aura.stacks = aura.stacks + stacks
						if aura.stacks > maxstacks then
							aura.stacks = maxstacks
						end
						Ovale:Logf("Aura %d gains %d stack(s) to %d because of spell %d.", auraId, stacks, aura.stacks, spellId)
					end
					-- Set start and duration for aura.
					if aura.tick and aura.tick > 0 then
						-- This is a periodic aura, so add new duration after the next tick is complete.
						local ticksRemain = floor((aura.ending - atTime) / aura.tick)
						aura.start = aura.ending - aura.tick * ticksRemain
						if OvaleData:NeedNewSnapshot(auraId, spellId) then
							-- Use duration and tick information based on spellcast snapshot.
							aura.duration = dotDuration
							aura.tick = tick
							OvaleFuture:UpdateSnapshotFromSpellcast(aura, spellcast)
						end
					else
						aura.start = atTime
						if OvaleData:NeedNewSnapshot(auraId, spellId) then
							aura.duration = duration
						end
					end
					aura.ending = aura.start + aura.duration
					aura.gain = atTime
					Ovale:Logf("Aura %d now ending at %f", auraId, aura.ending)
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
					end
				end
			else
				-- Aura is not on the target.
				if stacks > 0 then
					-- Spellcast causes a new aura.
					Ovale:Logf("New aura %d at %f on %s", auraId, atTime, guid)
					-- Add an aura in the simulator and copy the existing aura information over.
					local aura = state:AddAuraToGUID(guid, auraId, self_guid, filter, 0, math.huge)
					-- Information that needs to be set below: stacks, start, ending, duration, gain.
					aura.stacks = stacks
					aura.start = atTime
					-- Set start and duration for aura.
					if si and si.tick then
						-- "tick" is set explicitly in SpellInfo, so this is a known periodic aura.
						aura.duration = dotDuration
						aura.tick = tick
						aura.ticksSeen = 0
					else
						aura.duration = duration
					end
					aura.ending = aura.start + aura.duration
					aura.gain = aura.start
					OvaleFuture:UpdateSnapshotFromSpellcast(aura, spellcast)
				end
			end
		end
	end
end

statePrototype.GetAuraByGUID = function(state, guid, auraId, filter, mine)
	local auraFound
	if OvaleData.buffSpellList[auraId] then
		for id in pairs(OvaleData.buffSpellList[auraId]) do
			local aura = GetStateAuraOnGUID(state, guid, id, filter, mine)
			if aura and (not auraFound or auraFound.ending < aura.ending) then
				auraFound = aura
			end
		end
	else
		auraFound = GetStateAuraOnGUID(state, guid, auraId, filter, mine)
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
	aura.filter = filter
	aura.mine = mine
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

statePrototype.GetStealable = function(state, unitId)
	local count = 0
	local start, ending = math.huge, 0
	local guid = OvaleGUID:GetGUID(unitId)
	local now = state.currentTime

	-- Loop through auras not kept in the simulator that match the criteria.
	if self_aura[guid] then
		for auraId, whoseTable in pairs(self_aura[guid]) do
			for casterGUID in pairs(whoseTable) do
				local aura = GetStateAura(state, guid, auraId, self_guid)
				if state:IsActiveAura(aura, now) and not aura.state then
					if aura.stealable and aura.filter == "HELPFUL" then
						count = count + 1
						start = (aura.start < start) and aura.start or start
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
				if state:IsActiveAura(aura, now) then
					if aura.stealable and aura.filter == "HELPFUL" then
						count = count + 1
						start = (aura.start < start) and aura.start or start
						ending = (aura.ending > ending) and aura.ending or ending
					end
				end
			end
		end
	end
	if count > 0 then
		return count, start, ending
	end
	return 0, 0, math.huge
end

do
	-- The total count of the matched aura.
	local count
	-- The start and ending times of the first aura to expire that will change the total count.
	local startChangeCount, endingChangeCount
	-- The time interval over which count > 0.
	local startFirst, endingLast

	local function CountMatchingActiveAura(aura)
		count = count + 1
		if aura.ending < endingChangeCount then
			startChangeCount, endingChangeCount = aura.start, aura.ending
		end
		if aura.start < startFirst then
			startFirst = aura.start
		end
		if aura.ending > endingLast then
			endingLast = aura.ending
		end
	end

	--[[
		Return the total count of the given aura across all units, the start/end times of
		the first aura to expire that will change the total count, and the time interval
		over which the count is more than 0.
	--]]
	statePrototype.AuraCount = function(state, auraId, filter, mine)
		-- Initialize.
		count = 0
		startChangeCount, endingChangeCount = math.huge, math.huge
		startFirst, endingLast = math.huge, 0

		local now = state.currentTime

		-- Loop through auras not kept in the simulator that match the criteria.
		for guid, auraTable in pairs(self_aura) do
			if auraTable[auraId] then
				if mine then
					local aura = GetStateAura(state, guid, auraId, self_guid)
					if state:IsActiveAura(aura, now) and aura.filter == filter and not aura.state then
						CountMatchingActiveAura(aura)
					end
				else
					for casterGUID in pairs(auraTable[auraId]) do
						local aura = GetStateAura(state, guid, auraId, casterGUID)
						if state:IsActiveAura(aura, now) and aura.filter == filter and not aura.state then
							CountMatchingActiveAura(aura)
						end
					end
				end
			end
		end
		-- Loop through auras in the simulator that match the criteria.
		for guid, auraTable in pairs(state.aura) do
			if auraTable[auraId] then
				if mine then
					local aura = auraTable[auraId][self_guid]
					if aura then
						if state:IsActiveAura(aura, now) and aura.filter == filter then
							CountMatchingActiveAura(aura)
						end
					end
				else
					for casterGUID, aura in pairs(auraTable[auraId]) do
						if state:IsActiveAura(aura, now) and aura.filter == filter then
							CountMatchingActiveAura(aura)
						end
					end
				end
			end
		end

		return count, startChangeCount, endingChangeCount, startFirst, endingLast
	end
end
--</state-methods>
