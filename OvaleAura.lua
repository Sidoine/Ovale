--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- This addon keep the list of all the aura for all the units
-- Fore each aura, it saves the state of the player when it was refreshed

local _, Ovale = ...
local OvaleAura = Ovale:NewModule("OvaleAura", "AceEvent-3.0")
Ovale.OvaleAura = OvaleAura

--<private-static-properties>
local OvalePool = Ovale.OvalePool
local OvalePoolRefCount = Ovale.OvalePoolRefCount

-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleFuture = nil
local OvaleGUID = nil
local OvalePaperDoll = nil
local OvaleState = nil

local ipairs = ipairs
local pairs = pairs
local select = select
local strfind = string.find
local tinsert = table.insert
local tsort = table.sort
local wipe = table.wipe
local API_GetTime = GetTime
local API_UnitAura = UnitAura

-- aura pool
local self_pool = OvalePoolRefCount("OvaleAura_pool")
do
	self_pool.Clean = function(self, aura)
		-- Release reference-counted snapshot before wiping.
		if aura.snapshot then
			aura.snapshot:ReleaseReference()
		end
	end
end
-- self_aura[guid] pool
local self_aura_pool = OvalePool("OvaleAura_aura_pool")
-- player's GUID
local self_guid = nil
-- self_aura[guid][filter][spellId][casterGUID] = { aura properties }
local self_aura = {}
-- self_serial[guid] = aura age
local self_serial = {}

local OVALE_UNKNOWN_GUID = 0

local OVALE_AURA_DEBUG = "aura"
-- Aura debuff types
local OVALE_DEBUFF_TYPES = {
	Curse = true,
	Disease = true,
	Magic = true,
	Poison = true,
}
-- CLEU events triggered by auras being applied, removed, refreshed, or changed in stack size.
local OVALE_CLEU_AURA_EVENTS = {
	SPELL_AURA_APPLIED = true,
	SPELL_AURA_REMOVED = true,
	SPELL_AURA_APPLIED_DOSE = true,
	SPELL_AURA_REMOVED_DOSE = true,
	SPELL_AURA_REFRESH = true,
	SPELL_AURA_BROKEN = true,
	SPELL_AURA_BROKEN_SPELL = true,
}
-- CLEU events triggered by a periodic aura.
local OVALE_CLEU_TICK_EVENTS = {
	SPELL_PERIODIC_DAMAGE = true,
	SPELL_PERIODIC_HEAL = true,
	SPELL_PERIODIC_ENERGIZE = true,
	SPELL_PERIODIC_DRAIN = true,
	SPELL_PERIODIC_LEECH = true,
}
--</private-static-properties>

--<private-static-methods>
local function UnitGainedAura(guid, spellId, filter, casterGUID, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3)
	local self = OvaleAura
	if not self_aura[guid][filter] then
		self_aura[guid][filter] = {}
	end
	if not self_aura[guid][filter][spellId] then
		self_aura[guid][filter][spellId] = {}
	end

	casterGUID = casterGUID or OVALE_UNKNOWN_GUID
	local mine = (casterGUID == self_guid)
	local existingAura, aura
	local now = API_GetTime()
	existingAura = self_aura[guid][filter][spellId][casterGUID]
	if existingAura then
		aura = existingAura
	else
		aura = self_pool:Get()
		aura.gain = now
		self_aura[guid][filter][spellId][casterGUID] = aura
	end
	aura.serial = self_serial[guid]

	-- UnitAura() can return zero count for auras that are present.
	count = (count > 0) and count or 1
	-- "Zero" duration and expiration actually mean the aura never expires.
	duration = (duration > 0) and duration or math.huge
	expirationTime = (expirationTime > 0) and expirationTime or math.huge

	-- Only overwrite an existing aura's information if the aura has changed.
	-- An aura's "fingerprint" is its:
	--     caster, duration, expiration time, stack count.
	local auraIsUnchanged = (
		existingAura
			and aura.source == casterGUID
			and aura.duration == duration
			and aura.ending == expirationTime
			and aura.stacks == count
	)
	local addAura = not existingAura or not auraIsUnchanged
	if addAura then
		Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    Adding %s %s (%s) to %s at %f, aura.serial=%d",
			filter, name, spellId, guid, now, aura.serial)
		aura.icon = icon
		aura.stacks = count
		aura.debuffType = debuffType
		if duration < math.huge and expirationTime < math.huge then
			aura.start = expirationTime - duration
		else
			aura.start = now
		end
		aura.duration = duration
		aura.ending = expirationTime
		aura.stealable = isStealable
		aura.mine = mine
		aura.source = casterGUID
		aura.name = name
		aura.value1, aura.value2, aura.value3 = value1, value2, value3

		-- Snapshot stats for DoTs.
		if mine then
			local si = OvaleData.spellInfo[spellId]
			if si and si.tick then
				Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    %s (%s) is a periodic aura.", name, spellId)
				-- Only set the initial tick information for new auras.
				if not existingAura then
					aura.ticksSeen = 0
					aura.tick = self:GetTickLength(spellId)
				end
				-- Determine whether to snapshot player stats for the aura or to keep the existing stats.
				local lastSpellcast = OvaleFuture.lastSpellcast
				local lastSpellId = lastSpellcast and lastSpellcast.spellId
				if lastSpellId and OvaleData:NeedNewSnapshot(spellId, lastSpellId) then
					Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    Snapshot stats for %s %s (%s) on %s from %f, now=%f, aura.serial=%d",
						filter, name, spellId, guid, lastSpellcast.snapshotTime, now, aura.serial)
					-- TODO: damageMultiplier isn't correct if lastSpellId spreads the DoT.
					OvaleFuture:UpdateFromSpellcast(aura, lastSpellcast)
				end
			end
		end
	end
	if not existingAura then
		self:SendMessage("Ovale_AuraAdded", now, guid, spellId, casterGUID)
	elseif not auraIsUnchanged then
		self:SendMessage("Ovale_AuraChanged", now, guid, spellId, casterGUID)
	end
	return addAura
end

local function RemoveAuraIfExpired(guid, spellId, filter, aura, serial)
	local self = OvaleAura
	if aura and serial and aura.serial ~= serial then
		local now = API_GetTime()
		Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    Removing expired %s %s (%s) from %s at %f, serial=%d aura.serial=%d",
			filter, aura.name, spellId, guid, now, serial, aura.serial)
		self:SendMessage("Ovale_AuraRemoved", now, guid, spellId, aura.source)
		self_pool:Release(aura)
		return true
	end
	return false
end

-- Return all auras for the given GUID to the aura pool.
local function RemoveAurasForGUID(guid, expired)
	if not guid or not self_aura[guid] or not self_serial[guid] then return end
	if not expired then
		Ovale:DebugPrintf(OVALE_AURA_DEBUG, "Removing auras from guid %s", guid)
	end
	local serial = self_serial[guid]
	local auraTable = self_aura[guid]
	for filter, auraList in pairs(auraTable) do
		for auraId, whoseTable in pairs(auraList) do
			for whose, aura in pairs(whoseTable) do
				if expired then
					if RemoveAuraIfExpired(guid, auraId, filter, aura, serial) then
						whoseTable[whose] = nil
					end
				else
					Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    Removing %s %s (%s) from %s, serial=%d aura.serial=%d",
						filter, aura.name, auraId, guid, serial, aura.serial)
					whoseTable[whose] = nil
					self_pool:Release(aura)
				end
			end
			if not next(whoseTable) then
				auraList[auraId] = nil
			end
		end
		if not next(auraList) then
			auraTable[filter] = nil
		end
	end
	if not next(auraTable) then
		self_aura[guid] = nil
		self_aura_pool:Release(auraTable)
	end

	local unitId = OvaleGUID:GetUnitId(guid)
	if unitId then
		Ovale.refreshNeeded[unitId] = true
	end
end

-- Remove all auras from GUIDs that can no longer be referenced by a unit ID,
-- i.e., not in the group or not targeted by anyone in the group or focus.
local function RemoveAurasForMissingUnits()
	for guid in pairs(self_aura) do
		local unitId = OvaleGUID:GetUnitId(guid)
		if not unitId then
			RemoveAurasForGUID(guid)
			self_serial[guid] = nil
		end
	end
end

-- Scan auras on the given unit and update the aura database.
local function ScanUnitAuras(unitId, guid)
	if not unitId and not guid then return end
	unitId = unitId or OvaleGUID:GetUnitId(guid)
	guid = guid or OvaleGUID:GetGUID(unitId)
	if not (unitId and guid) then return end

	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "Scanning auras on %s (%s)", guid, unitId)

	-- Advance the age of the unit's auras.
	if not self_serial[guid] then
		self_serial[guid] = 0
	end
	self_serial[guid] = self_serial[guid] + 1
	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "    Advancing age of auras for %s (%s) to %d.", guid, unitId, self_serial[guid])

	if not self_aura[guid] then
		self_aura[guid] = self_aura_pool:Get()
	end

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
			local added = UnitGainedAura(guid, spellId, filter, casterGUID, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3)
			if added then
				Ovale.refreshNeeded[unitId] = true
			end
			i = i + 1
		end
	end
	RemoveAurasForGUID(guid, true)
end

-- Update the tick length of an aura using event timestamps from the combat log.
local function UpdateAuraTick(guid, spellId, timestamp)
	local self = OvaleAura
	local aura, filter
	if self_aura[guid] then
		local serial = self_serial[guid]
		filter = "HARMFUL"
		while true do
			if self_aura[guid][filter] and self_aura[guid][filter][spellId] and self_aura[guid][filter][spellId][self_guid] then
				if RemoveAuraIfExpired(guid, spellId, filter, self_aura[guid][filter][spellId][self_guid], serial) then
					self_aura[guid][filter][spellId][self_guid] = nil
				end
				aura = self_aura[guid][filter][spellId][self_guid]
			end
			if aura then break end
			if filter == "HARMFUL" then
				filter = "HELPFUL"
			else
				break
			end
		end
	end
	if aura and aura.tick then
		local tick = aura.tick
		local ticksSeen = aura.ticksSeen or 0
		if not aura.lastTickTime then
			-- For some reason, there was no lastTickTime information recorded,
			-- so approximate the tick time using the player's current stats.
			tick = self:GetTickLength(spellId)
			ticksSeen = 0
		else
			-- Tick times tend to vary about the "true" value by a up to a few
			-- hundredths of a second.  Keep a running average to try to protect
			-- against unusually short or long tick times.
			tick = ((tick * ticksSeen) + (timestamp - aura.lastTickTime)) / (ticksSeen + 1)
			ticksSeen = ticksSeen + 1
		end
		aura.lastTickTime = timestamp
		aura.tick = tick
		aura.ticksSeen = ticksSeen
		Ovale:DebugPrintf(OVALE_AURA_DEBUG, "Updating %s %s (%s) on %s, tick=%f", filter, aura.name, spellId, guid, tick)
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
	self_guid = OvaleGUID:GetGUID("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UNIT_AURA")
	self:RegisterMessage("Ovale_GroupChanged", RemoveAurasForMissingUnits)
	self:RegisterMessage("Ovale_InactiveUnit")
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvaleAura:OnDisable()
	OvaleState:UnregisterState(self)
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("UNIT_AURA")
	self:UnregisterMessage("Ovale_GroupChanged")
	self:UnregisterMessage("Ovale_InactiveUnit")
end

function OvaleAura:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)
	local mine = sourceGUID == self_guid

	if event == "UNIT_DIED" then
		RemoveAurasForGUID(destGUID)
	elseif OVALE_CLEU_AURA_EVENTS[event] then
		local unitId = OvaleGUID:GetUnitId(destGUID)
		if unitId and not OvaleGUID.UNIT_AURA_UNITS[unitId] then
			ScanUnitAuras(unitId, destGUID)
		end
	elseif mine and OVALE_CLEU_TICK_EVENTS[event] then
		-- Update the latest tick time of the periodic aura cast by the player.
		local spellId, spellName, spellSchool = select(12, ...)
		UpdateAuraTick(destGUID, spellId, timestamp)
	end
end

function OvaleAura:PLAYER_ENTERING_WORLD(event)
	Ovale:DebugPrint(OVALE_AURA_DEBUG, event)
	-- Update auras on all visible units.
	for unitId in pairs(OvaleGUID.UNIT_AURA_UNITS) do
		ScanUnitAuras(unitId)
	end
	RemoveAurasForMissingUnits()
	self_pool:Drain()
	self_aura_pool:Drain()
end

function OvaleAura:UNIT_AURA(event, unitId)
	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s: %s", event, unitId)
	ScanUnitAuras(unitId)
end

function OvaleAura:Ovale_InactiveUnit(event, guid)
	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s: %s", event, guid)
	RemoveAurasForGUID(guid)
end

function OvaleAura:GetAuraByGUID(guid, spellId, filter, mine, unitId)
	if not guid then
		Ovale:Log("nil guid does not exist in OvaleAura")
		return nil
	end

	local auraTable = self_aura[guid]
	if not auraTable then
		unitId = unitId or OvaleGUID:GetUnitId(guid)
		if not unitId then
			Ovale:Logf("Unable to get unitId from %s", guid)
			return nil
		end
		-- This GUID has no auras previously cached, so do an aura scan.
		if not self_serial[guid] then
			ScanUnitAuras(unitId, guid)
		end
		auraTable = self_aura[guid]
		if not auraTable then
			Ovale:Logf("Target %s has no aura", guid)
			return nil
		end
	end

	local auraFound
	local serial = self_serial[guid]

	if type(spellId) == "number" then
		for auraFilter, auraList in pairs(auraTable) do
			if not filter or (filter == auraFilter) then
				local whoseTable = auraList[spellId]
				if whoseTable then
					if mine then
						if RemoveAuraIfExpired(guid, spellId, filter, whoseTable[self_guid], serial) then
							whoseTable[self_guid] = nil
						end
						auraFound = whoseTable[self_guid]
					else
						for k, v in pairs(whoseTable) do
							if RemoveAuraIfExpired(guid, spellId, filter, v, serial) then
								whoseTable[k] = nil
							end
							auraFound = whoseTable[k]
							if auraFound then break end
						end
					end
					if auraFound then break end
				end
			end
		end
	elseif OVALE_DEBUFF_TYPES[spellId] then
		for auraFilter, auraList in pairs(auraTable) do
			if not filter or (filter == auraFilter) then
				for auraId, whoseTable in pairs(auraList) do
					for caster, aura in pairs(whoseTable) do
						if not mine or caster == self_guid then
							if RemoveAuraIfExpired(guid, auraId, filter, aura, serial) then
								whoseTable[caster] = nil
							end
							auraFound = whoseTable[caster]
							if auraFound and auraFound.debuffType == spellId then
								-- Stop after finding the first aura of the given debuff type.
								break
							end
						end
					end
				end
			end
		end
	end

	return auraFound
end

function OvaleAura:GetAura(unitId, spellId, filter, mine)
	local guid = OvaleGUID:GetGUID(unitId)
	if OvaleData.buffSpellList[spellId] then
		local auraFound
		for auraId in pairs(OvaleData.buffSpellList[spellId]) do
			local aura = self:GetAuraByGUID(guid, auraId, filter, mine, unitId)
			if aura and (not auraFound or aura.stacks > auraFound.stacks) then
				auraFound = aura
			end
		end
		return auraFound
	else
		return self:GetAuraByGUID(guid, spellId, filter, mine, unitId)
	end
end

function OvaleAura:GetStealable(unitId)
	local guid = OvaleGUID:GetGUID(unitId)
	local auraTable = self_aura[guid]
	if not auraTable then return nil end

	-- only buffs are stealable
	local auraList = auraTable.HELPFUL
	if not auraList then return nil end

	local start, ending
	local serial = self_serial[guid]
	for auraId, whoseTable in pairs(auraList) do
		for caster, aura in pairs(whoseTable) do
			if RemoveAuraIfExpired(guid, auraId, "HELPFUL", aura, serial) then
				whoseTable[caster] = nil
			end
			aura = whoseTable[caster]
			if aura and aura.stealable then
				if aura.start and (not start or aura.start < start) then
					start = aura.start
				end
				if aura.ending and (not ending or aura.ending > ending) then
					ending = aura.ending
				end
			end
		end
	end
	return start, ending
end

-- Look for an aura on any target, excluding the given GUID.
-- Returns the earliest start time, the latest ending time, and the number of auras seen.
function OvaleAura:GetAuraOnAnyTarget(spellId, filter, mine, excludingGUID)
	local start, ending
	local count = 0
	for guid, auraTable in pairs(self_aura) do
		if guid ~= excludingGUID then
			local serial = self_serial[guid]
			for auraFilter, auraList in pairs(auraTable) do
				if not filter or auraFilter == filter then
					local whoseTable = auraList[spellId]
					if whoseTable then
						for caster, aura in pairs(whoseTable) do
							if not mine or caster == self_guid then
								if RemoveAuraIfExpired(guid, spellId, filter, aura, serial) then
									whoseTable[caster] = nil
								end
								aura = whoseTable[caster]
								if aura then
									if aura.start and (not start or aura.start < start) then
										start = aura.start
									end
									if aura.ending and (not ending or aura.ending > ending) then
										ending = aura.ending
									end
									count = count + 1
								end
							end
						end
					end
				end
			end
		end
	end
	return start, ending, count
end

function OvaleAura:GetTickLength(spellId)
	local si
	if type(spellId) == "number" then
		si = OvaleData.spellInfo[spellId]
	elseif OvaleData.buffSpellList[spellId] then
		for auraId in pairs(OvaleData.buffSpellList[spellId]) do
			si = OvaleData.spellInfo[auraId]
			if si then break end
		end
	end
	if si then
		local tick = si.tick or 3
		local hasteMultiplier = 1
		if si.haste then
			if si.haste == "spell" then
				hasteMultiplier = OvalePaperDoll:GetSpellHasteMultiplier()
			elseif si.haste == "melee" then
				hasteMultiplier = OvalePaperDoll:GetMeleeHasteMultiplier()
			end
			return tick / hasteMultiplier
		else
			return tick
		end
	end
	return math.huge
end

function OvaleAura:Debug()
	self_pool:Debug()
	self_aura_pool:Debug()
	for guid, auraTable in pairs(self_aura) do
		Ovale:FormatPrint("Auras for %s:", guid)
		for filter, auraList in pairs(auraTable) do
			for auraId, whoseTable in pairs(auraList) do
				for whose, aura in pairs(whoseTable) do
					Ovale:FormatPrint("%s %s %s %s %s stacks=%d tick=%s serial=%d", guid, filter, whose, auraId, aura.name, aura.stacks, aura.tick, aura.serial)
				end
			end
		end
	end
end

-- Print the auras matching the filter on the unit in alphabetical order.
function OvaleAura:DebugListAura(unitId, filter)
	local guid = OvaleGUID:GetGUID(unitId)
	RemoveAurasForGUID(guid, true)
	if self_aura[guid] and self_aura[guid][filter] then
		local array = {}
		for auraId, whoseTable in pairs(self_aura[guid][filter]) do
			for whose, aura in pairs(whoseTable) do
				tinsert(array, aura.name .. ": " .. auraId)
			end
		end
		tsort(array)
		for _, v in ipairs(array) do
			Ovale:Print(v)
		end
	end
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

--<public-static-methods>
-- Initialize the state.
function OvaleAura:InitializeState(state)
	state.aura = {}
	state.serial = 0
end

-- Reset the state to the current conditions.
function OvaleAura:ResetState(state)
	state.serial = state.serial + 1
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleAura:ApplySpellAfterCast(state, spellId, startCast, endCast, nextCast, isChanneled, nocd, targetGUID, spellcast)
	local si = OvaleData.spellInfo[spellId]
	-- Apply the auras on the player.
	if si and si.aura and si.aura.player then
		state:ApplySpellAuras(spellId, startCast, endCast, isChanneled, OvaleGUID:GetGUID("player"), si.aura.player, spellcast)
	end
end

-- Apply the effects of the spell on the target's state when it lands on the target.
function OvaleAura:ApplySpellOnHit(state, spellId, startCast, endCast, nextCast, isChanneled, nocd, targetGUID, spellcast)
	local si = OvaleData.spellInfo[spellId]
	-- Apply the auras on the target.
	if si and si.aura and si.aura.target then
		state:ApplySpellAuras(spellId, startCast, endCast, isChanneled, targetGUID, si.aura.target, spellcast)
	end
end
--</public-static-methods>

-- Mix-in methods for simulator state.
do
	local statePrototype = OvaleAura.statePrototype

	-- Apply the auras caused by the given spell in the simulator.
	function statePrototype:ApplySpellAuras(spellId, startCast, endCast, isChanneled, guid, auraList, spellcast)
		local state = self
		local target = OvaleGUID:GetUnitId(guid)
		for filter, filterInfo in pairs(auraList) do
			for auraId, spellData in pairs(filterInfo) do
				local si = OvaleData.spellInfo[auraId]
				-- An aura is treated as a periodic aura if it sets "tick" explicitly in SpellInfo.
				local isDoT = (si and si.tick)
				local duration = spellData
				local stacks = spellData

				-- If aura is specified with a duration, then assume stacks == 1.
				if type(duration) == "number" and duration > 0 then
					stacks = 1
				end
				-- Set the duration to the proper length if it's a DoT.
				if si and si.duration then
					duration = state:GetDuration(auraId)
				end

				local aura = state:GetAuraByGUID(guid, auraId, filter, true, target)
				local newAura = state:NewAura(guid, auraId, filter, state.currentTime)
				newAura.mine = true

				--[[
					auraId=N, N > 0		N is duration, auraID is applied, add one stack
					auraId=0			aura is removed
					auraId=N, N < 0		N is number of stacks of aura removed
					auraId=refresh		auraId is refreshed, no change to stacks
				--]]
				local atTime = isChanneled and startCast or endCast
				if type(stacks) == "number" and stacks == 0 then
					Ovale:Logf("Aura %d is completely removed", auraId)
					newAura.stacks = 0
					newAura.start = aura and aura.start or 0
					newAura.ending = aura and atTime or 0
				elseif aura and ((isChanneled and startCast < aura.ending) or (not isChanneled and endCast <= aura.ending)) then
					local start, ending, tick = aura.start, aura.ending, aura.tick
					-- Spell starts channeling before the aura expires, or spellcast ends before the aura expires.
					if stacks == "refresh" or stacks > 0 then
						if stacks == "refresh" then
							Ovale:Logf("Aura %d is refreshed", auraId)
							newAura.stacks = aura.stacks
						else -- if stacks > 0 then
							newAura.stacks = aura.stacks + stacks
							Ovale:Logf("Aura %d gains a stack to %d because of spell %d (ending was %s)", auraId, newAura.stacks, spellId, ending)
						end
						newAura.start = start
						if isDoT and ending > newAura.start and tick and tick > 0 then
							-- Add new duration after the next tick is complete.
							local remainingTicks = floor((ending - atTime) / tick)
							newAura.ending = (ending - tick * remainingTicks) + duration
							newAura.tick = OvaleAura:GetTickLength(auraId)
							-- Re-snapshot stats for the DoT.
							OvaleFuture:UpdateFromSpellcast(newAura, spellcast)
						else
							newAura.ending = atTime + duration
						end
						Ovale:Logf("Aura %d ending is now %f", auraId, newAura.ending)
					elseif stacks < 0 then
						newAura.stacks = aura.stacks + stacks
						newAura.start = start
						newAura.ending = ending
						Ovale:Logf("Aura %d loses %d stack(s) to %d because of spell %d", auraId, -1 * stacks, newAura.stacks, spellId)
						if newAura.stacks <= 0 then
							Ovale:Logf("Aura %d is completely removed", auraId)
							newAura.stacks = 0
							newAura.ending = atTime
						end
					end
				elseif type(stacks) == "number" and type(duration) == "number" and stacks > 0 and duration > 0 then
					Ovale:Logf("New aura %d at %f on %s", auraId, atTime, guid)
					newAura.stacks = stacks
					newAura.start = atTime
					newAura.ending = atTime + duration
					if isDoT then
						newAura.tick = OvaleAura:GetTickLength(auraId)
						-- Snapshot stats for the DoT.
						OvaleFuture:UpdateFromSpellcast(newAura, spellcast)
					end
				end
			end
		end
	end

	function statePrototype:GetAuraByGUID(guid, spellId, filter, mine, unitId)
		local state = self
		local auraFound
		if mine then
			local auraTable = state.aura[guid]
			if auraTable then
				if filter then
					local auraList = auraTable[filter]
					if auraList then
						if auraList[spellId] and auraList[spellId].serial == state.serial then
							auraFound = auraList[spellId]
						end
					end
				else
					for auraFilter, auraList in pairs(auraTable) do
						if auraList[spellId] and auraList[spellId].serial == state.serial then
							auraFound = auraList[spellId]
							filter = auraFilter
							break
						end
					end
				end
			end
		end
		if auraFound then
			if auraFound.stacks > 0 then
				Ovale:Logf("Found %s aura %s on %s", filter, spellId, guid)
			else
				Ovale:Logf("Found %s aura %s on %s (removed)", filter, spellId, guid)
			end
			return auraFound
		else
			Ovale:Logf("Aura %s not found in state for %s", spellId, guid)
			return OvaleAura:GetAuraByGUID(guid, spellId, filter, mine, unitId)
		end
	end

	function statePrototype:GetAura(unitId, spellId, filter, mine)
		local state = self
		local guid = OvaleGUID:GetGUID(unitId)
		if OvaleData.buffSpellList[spellId] then
			local auraFound
			for auraId in pairs(OvaleData.buffSpellList[spellId]) do
				local aura = state:GetAuraByGUID(guid, auraId, filter, mine, unitId)
				if aura and (not auraFound or aura.stacks > auraFound.stacks) then
					auraFound = aura
				end
			end
			return auraFound
		else
			return state:GetAuraByGUID(guid, spellId, filter, mine, unitId)
		end
	end

	-- Look for an aura on any target, excluding the given GUID.
	-- Returns the earliest start time, the latest ending time, and the number of auras seen.
	function statePrototype:GetAuraOnAnyTarget(spellId, filter, mine, excludingGUID)
		local state = self
		local start, ending, count = OvaleAura:GetAuraOnAnyTarget(spellId, filter, mine, excludingGUID)
		-- TODO: This is broken because it doesn't properly account for removed auras in the current frame.
		for guid, auraTable in pairs(state.aura) do
			if guid ~= excludingGUID then
				for auraFilter, auraList in pairs(auraTable) do
					if not filter or auraFilter == filter then
						local aura = auraList[spellId]
						if aura and aura.serial == state.serial then
							if aura.start and (not start or aura.start < start) then
								start = aura.start
							end
							if aura.ending and (not ending or aura.ending > ending) then
								ending = aura.ending
							end
							count = count + 1
						end
					end
				end
			end
		end
		return start, ending, count
	end

	function statePrototype:NewAura(guid, spellId, filter, gain)
		local state = self
		if not state.aura[guid] then
			state.aura[guid] = {}
		end
		if not state.aura[guid][filter] then
			state.aura[guid][filter] = {}
		end
		if not state.aura[guid][filter][spellId] then
			state.aura[guid][filter][spellId] = {}
		end
		local aura = state.aura[guid][filter][spellId]
		aura.serial = state.serial
		aura.mine = true
		aura.gain = gain
		return aura
	end

	function statePrototype:GetDamageMultiplier(spellId)
		local state = self
		local damageMultiplier = 1
		if spellId then
			local si = OvaleData.spellInfo[spellId]
			if si and si.damageAura then
				local playerGUID = OvaleGUID:GetGUID("player")
				for filter, auraList in pairs(si.damageAura) do
					for auraSpellId, multiplier in pairs(auraList) do
						local aura = state:GetAuraByGUID(playerGUID, auraSpellId, filter, nil, "player")
						if aura and aura.stacks > 0 then
							local auraSpellInfo = OvaleData.spellInfo[auraSpellId]
							if auraSpellInfo.stacking and auraSpellInfo.stacking > 0 then
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

	-- Returns the duration, tick length, and number of ticks of an aura.
	function statePrototype:GetDuration(auraSpellId)
		local state = self
		local si
		if type(auraSpellId) == "number" then
			si = OvaleData.spellInfo[auraSpellId]
		elseif OvaleData.buffSpellList[auraSpellId] then
			for spellId in pairs(OvaleData.buffSpellList[auraSpellId]) do
				si = OvaleData.spellInfo[spellId]
				if si then
					auraSpellId = spellId
					break
				end
			end
		end
		if si and si.duration then
			local OvaleComboPoints = Ovale.OvaleComboPoints
			local OvalePower = Ovale.OvalePower
			local duration = si.duration
			local combo = state.combo or 0
			local holy = state.holy or 1
			if si.adddurationcp then
				duration = duration + si.adddurationcp * combo
			end
			if si.adddurationholy then
				duration = duration + si.adddurationholy * (holy - 1)
			end
			if si.tick then	-- DoT
				--DoT duration is tick * numTicks.
				local tick = OvaleAura:GetTickLength(auraSpellId)
				local numTicks = floor(duration / tick + 0.5)
				duration = tick * numTicks
				return duration, tick, numTicks
			end
			return duration
		end
	end

	-- Add a new aura to the unit specified by GUID.
	function statePrototype:AddAuraToGUID(guid, spellId, filter, mine, start, ending)
		local state = self
		local aura = state:NewAura(guid, spellId, filter, start)
		aura.mine = mine
		aura.start = start
		aura.ending = ending
		aura.stacks = 1
	end
end
