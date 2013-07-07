--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013 Sidoine, Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

-- This addon keep the list of all the aura for all the units
-- Fore each aura, it saves the state of the player when it was refreshed

local _, Ovale = ...
local OvaleAura = Ovale:NewModule("OvaleAura", "AceEvent-3.0")
Ovale.OvaleAura = OvaleAura

--<private-static-properties>
local OvaleData = Ovale.OvaleData
local OvaleGUID = Ovale.OvaleGUID
local OvalePaperDoll = Ovale.OvalePaperDoll
local OvalePool = Ovale.OvalePool

local ipairs = ipairs
local pairs = pairs
local select = select
local strfind = string.find
local tinsert = table.insert
local tsort = table.sort
local API_UnitAura = UnitAura

-- aura pool
local self_pool = OvalePool:NewPool("OvaleAura_pool")
-- self_aura[guid] pool
local self_aura_pool = OvalePool:NewPool("OvaleAura_aura_pool")
-- player's GUID
local self_player_guid = nil
-- self_aura[guid][filter][spellId]["mine" or "other"] = { aura properties }
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
-- Units for which UNIT_AURA is known to fire.
local OVALE_UNIT_AURA_UNITS = {}
do
	OVALE_UNIT_AURA_UNITS["focus"] = true
	OVALE_UNIT_AURA_UNITS["pet"] = true
	OVALE_UNIT_AURA_UNITS["player"] = true
	OVALE_UNIT_AURA_UNITS["target"] = true

	for i = 1, 5 do
		OVALE_UNIT_AURA_UNITS["arena" .. i] = true
		OVALE_UNIT_AURA_UNITS["arenapet" .. i] = true
	end
	for i = 1, 4 do
		OVALE_UNIT_AURA_UNITS["boss" .. i] = true
	end
	for i = 1, 4 do
		OVALE_UNIT_AURA_UNITS["party" .. i] = true
		OVALE_UNIT_AURA_UNITS["partypet" .. i] = true
	end
	for i = 1, 40 do
		OVALE_UNIT_AURA_UNITS["raid" .. i] = true
		OVALE_UNIT_AURA_UNITS["raidpet" .. i] = true
	end
end
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
local function UnitGainedAura(event, guid, spellId, filter, casterGUID, icon, count, debuffType, duration, expirationTime, isStealable, name, value)
	if not self_aura[guid][filter] then
		self_aura[guid][filter] = {}
	end
	if not self_aura[guid][filter][spellId] then
		self_aura[guid][filter][spellId] = {}
	end

	casterGUID = casterGUID or OVALE_UNKNOWN_GUID
	local mine = (casterGUID == self_player_guid)
	local existingAura, aura
	existingAura = self_aura[guid][filter][spellId][casterGUID]
	if existingAura then
		aura = existingAura
	else
		aura = self_pool:Get()
		aura.gain = Ovale.now
		self_aura[guid][filter][spellId][casterGUID] = aura
	end

	aura.serial = self_serial[guid]
	if count == 0 then
		count = 1
	end

	-- Only overwrite an existing aura's information if the aura has changed.
	-- An aura's "fingerprint" is its:
	--     caster, duration, expiration time, stack count.
	local auraIsUnchanged = (
		existingAura and
		(aura.source == casterGUID) and
		((not aura.duration and duration == 0) or aura.duration == duration) and
		((not aura.ending and expirationTime == 0) or aura.ending == expirationTime) and
		(aura.stacks == count)
	)
	local addAura = not existingAura or not auraIsUnchanged
	if addAura then
		Ovale:DebugPrintf(OVALE_AURA_DEBUG, "Adding %s %s (%s) to %s, aura.serial=%d", filter, name, spellId, guid, aura.serial)
		aura.icon = icon
		aura.stacks = count
		aura.debuffType = debuffType
		if duration > 0 then
			aura.duration = duration
			aura.ending = expirationTime
		else
			aura.duration = nil
			aura.ending = nil
		end
		aura.start = expirationTime - duration
		aura.stealable = isStealable
		aura.mine = mine
		aura.source = casterGUID
		aura.name = name
		aura.value = value

		-- Only snapshot stats for periodic auras that have been applied or re-applied.
		-- If SPELL_AURA_REFRESH didn't fire, then the aura was extended by adding ticks,
		-- which doesn't re-snapshot stats.
		if mine and (not existingAura or event == "SPELL_AURA_REFRESH") then
			local si = OvaleData.spellInfo[spellId]
			if si and si.tick then
				aura.ticksSeen = 0
				aura.tick = OvaleData:GetTickLength(spellId)
				OvalePaperDoll:SnapshotStats(aura.gain, aura)
			end
		end
	end
	return addAura
end

local function RemoveAuraIfExpired(guid, spellId, filter, aura, serial)
	if aura and serial and aura.serial ~= serial then
		Ovale:DebugPrintf(OVALE_AURA_DEBUG, "Removing expired %s %s (%s) from %s, serial=%d aura.serial=%d",
			filter, aura.name, spellId, guid, serial, aura.serial)
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
					Ovale:DebugPrintf(OVALE_AURA_DEBUG, "Removing %s %s (%s) from %s, serial=%d aura.serial=%d",
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
local function ScanUnitAuras(event, unitId, guid)
	if not unitId then
		return
	end
	if not guid then
		guid = OvaleGUID:GetGUID(unitId)
	end
	if not guid then
		return
	end
	if not self_aura[guid] then
		self_aura[guid] = self_aura_pool:Get()
	end
	-- Advance the age of the unit's auras.
	if not self_serial[guid] then
		self_serial[guid] = 0
	end
	self_serial[guid] = self_serial[guid] + 1
	Ovale:DebugPrintf(OVALE_AURA_DEBUG, "%s: advancing age of auras for %s (%s) to %d.", event, guid, unitId, self_serial[guid])

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
			local added = UnitGainedAura(event, guid, spellId, filter, casterGUID, icon, count, debuffType, duration, expirationTime, isStealable, name, value1)
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
	local aura, filter
	if self_aura[guid] then
		local serial = self_serial[guid]
		filter = "HARMFUL"
		while true do
			if self_aura[guid][filter] and self_aura[guid][filter][spellId] and self_aura[guid][filter][spellId][self_player_guid] then
				if RemoveAuraIfExpired(guid, spellId, filter, self_aura[guid][filter][spellId][self_player_guid], serial) then
					self_aura[guid][filter][spellId][self_player_guid] = nil
				end
				aura = self_aura[guid][filter][spellId][self_player_guid]
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
			tick = OvaleData:GetTickLength(spellId)
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
function OvaleAura:OnEnable()
	self_player_guid = OvaleGUID:GetGUID("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UNIT_AURA")
	self:RegisterMessage("Ovale_GroupChanged", RemoveAurasForMissingUnits)
	self:RegisterMessage("Ovale_InactiveUnit")
end

function OvaleAura:OnDisable()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("UNIT_AURA")
	self:UnregisterMessage("Ovale_GroupChanged")
	self:UnregisterMessage("Ovale_InactiveUnit")
end

function OvaleAura:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)

	if event == "UNIT_DIED" then
		RemoveAurasForGUID(destGUID)
	elseif OVALE_CLEU_AURA_EVENTS[event] then
		local unitId = OvaleGUID:GetUnitId(destGUID)
		if unitId and not OVALE_UNIT_AURA_UNITS[unitId] then
			ScanUnitAuras(event, unitId, destGUID)
		end
	elseif OVALE_CLEU_TICK_EVENTS[event] and sourceGUID == self_player_guid then
		-- Periodic aura cast by the player.
		-- Update the latest tick time of the aura.
		local spellId, spellName, spellSchool = select(12, ...)
		UpdateAuraTick(destGUID, spellId, timestamp)
	end
end

function OvaleAura:PLAYER_ENTERING_WORLD(event)
	-- Update auras on all visible units.
	for unitId in pairs(OVALE_UNIT_AURA_UNITS) do
		ScanUnitAuras(event, unitId, OvaleGUID:GetGUID(unitId))
	end
	RemoveAurasForMissingUnits()
	self_pool:Drain()
	self_aura_pool:Drain()
end

function OvaleAura:UNIT_AURA(event, unitId)
	ScanUnitAuras(event, unitId, OvaleGUID:GetGUID(unitId))
end

function OvaleAura:Ovale_InactiveUnit(event, guid)
	RemoveAurasForGUID(guid)
end

function OvaleAura:GetAuraByGUID(guid, spellId, filter, mine, unitId)
	if not guid then
		Ovale:Log("nil guid does not exist in OvaleAura")
		return nil
	end

	local auraTable = self_aura[guid]
	if not auraTable then 
		if not unitId then
			unitId = OvaleGUID:GetUnitId(guid)
		end
		if not unitId then
			Ovale:Logf("Unable to get unitId from %s", guid)
			return nil
		end
		-- This GUID has no auras previously cached, so do an aura scan.
		if not self_serial[guid] then
			ScanUnitAuras("GetAuraByGUID", unitId, guid)
		end
		auraTable = self_aura[guid]
		if not auraTable then
			Ovale:Logf("Target %s has no aura", guid)
			return nil
		end
	end

	local aura
	local serial = self_serial[guid]

	if type(spellId) == "number" then
		for auraFilter, auraList in pairs(auraTable) do
			if not filter or (filter == auraFilter) then
				local whoseTable = auraList[spellId]
				if whoseTable then
					if mine then
						if RemoveAuraIfExpired(guid, spellId, filter, whoseTable[self_player_guid], serial) then
							whoseTable[self_player_guid] = nil
						end
						aura = whoseTable[self_player_guid]
					else
						for k, v in pairs(whoseTable) do
							if RemoveAuraIfExpired(guid, spellId, filter, v, serial) then
								whoseTable[k] = nil
							end
							aura = whoseTable[k]
							if aura then break end
						end
					end
					if aura then break end
				end
			end
		end
	elseif OVALE_DEBUFF_TYPES[spellId] then
		for auraFilter, auraList in pairs(auraTable) do
			if not filter or (filter == auraFilter) then
				for auraId, whoseTable in pairs(auraList) do
					for caster, aura in pairs(whoseTable) do
						if not mine or caster == self_player_guid then
							if RemoveAuraIfExpired(guid, auraId, filter, aura, serial) then
								whoseTable[caster] = nil
							end
							aura = whoseTable[caster]
							if aura and aura.debuffType == spellId then
								-- Stop after finding the first aura of the given debuff type.
								break
							end
						end
					end
				end
			end
		end
	end

	if not aura then return nil end
	return aura.start, aura.ending, aura.stacks, aura.tick, aura.value, aura.gain
end

function OvaleAura:GetAura(unitId, spellId, filter, mine)
	local guid = OvaleGUID:GetGUID(unitId)
	if OvaleData.buffSpellList[spellId] then
		local newStart, newEnding, newStacks, newTick, newValue, newGain
		for auraId in pairs(OvaleData.buffSpellList[spellId]) do
			local start, ending, stacks, tick, value, gain = self:GetAuraByGUID(guid, auraId, filter, mine, unitId)
			if start and (not newStart or stacks > newStacks) then
				newStart = start
				newEnding = ending
				newStacks = stacks
				newTick = tick
				newValue = value
				newGain = gain
			end
		end
		return newStart, newEnding, newStacks, newTick, newValue, newGain
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
							if not mine or caster == self_player_guid then
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

function OvaleAura:GetDamageMultiplier(spellId)
	-- Calculate the base damage multiplier for all spells.
	local damageMultiplier = 1
	for auraSpellId, multiplier in pairs(OvaleData.selfDamageBuff) do
		local count = select(3, self:GetAuraByGUID(self_player_guid, auraSpellId, filter, nil, "player"))
		if count and count > 0 then
			-- Try to account for a stacking aura.
			-- multiplier = 1 + (multiplier - 1) * count
			damageMultiplier = damageMultiplier * multiplier
		end
	end

	-- Factor in the spell-specific multipliers from SpellDamage{Buff,Debuff} declarations.
	if spellId then
		local si = OvaleData.spellInfo[spellId]
		if si and si.damageAura then
			for filter, auraList in pairs(si.damageAura) do
				for auraSpellId, multiplier in pairs(auraList) do
					count = select(3, self:GetAuraByGUID(self_player_guid, auraSpellId, filter, nil, "player"))
					if count and count > 0 then
						-- Try to account for a stacking aura.
						-- multiplier = 1 + (multiplier - 1) * count
						damageMultiplier = damageMultiplier * multiplier
					end
				end
			end
		end
	end
	return damageMultiplier
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
