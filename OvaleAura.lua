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

local self_pool = OvalePool:NewPool("OvaleAura_pool")
-- self_aura[guid][filter][spellId]["mine" or "other"] = { aura properties }
local self_aura = {}
local self_serial = 0

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
--</private-static-properties>

--<private-static-methods>
local function AddAura(unitGUID, spellId, filter, unitCaster, icon, count, debuffType, duration, expirationTime, isStealable, name, value)
	if not self_aura[unitGUID][filter] then
		self_aura[unitGUID][filter] = {}
	end
	local auraList = self_aura[unitGUID][filter]
	if not auraList[spellId] then
		auraList[spellId] = {}
	end

	-- Re-use existing aura by updating its serial number and adding new information
	-- if it differs from the old aura.
	local mine = (unitCaster == "player")
	local aura, oldAura
	if mine then
		oldAura = auraList[spellId].mine
		if oldAura then
			aura = oldAura
		else
			aura = self_pool:Get()
			aura.gain = Ovale.now
			auraList[spellId].mine = aura
		end
	else
		oldAura = auraList[spellId].other
		if oldAura then
			aura = oldAura
		else
			aura = self_pool:Get()
			aura.gain = Ovale.now
			auraList[spellId].other = aura
		end
	end

	aura.serial = self_serial
	if count == 0 then
		count = 1
	end

	local isSameAura = oldAura and oldAura.duration == duration and oldAura.ending == expirationTime and oldAura.stacks == count
	if not isSameAura and not aura.ending or aura.ending < expirationTime or aura.stacks ~= count then
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
		aura.source = unitCaster
		aura.name = name
		aura.value = value
		if mine then
			-- This is a new or refreshed aura applied by the player, so set the tick information if needed.
			local si = OvaleData.spellInfo[spellId]
			if si and si.tick then
				aura.tick = OvaleData:GetTickLength(spellId)
			end
		end
	end
end

local function RemoveAurasForGUID(guid)
	-- Return all auras for the given GUID to the aura pool.
	if not guid or not self_aura[guid] then return end
	Ovale:DebugPrintf("aura", "Removing auras for guid %s", guid)
	for filter, auraList in pairs(self_aura[guid]) do
		for spellId, whoseTable in pairs(auraList) do
			for whose, aura in pairs(whoseTable) do
				whoseTable[whose] = nil
				self_pool:Release(aura)
			end
			auraList[spellId] = nil
		end
		self_aura[guid][filter] = nil
	end
	self_aura[guid] = nil

	local unitId = OvaleGUID:GetUnitId(guid)
	if unitId then
		Ovale.refreshNeeded[unitId] = true
	end
end

function RemoveAurasForMissingUnits()
	-- Remove all auras from GUIDs that can no longer be referenced by a unit ID,
	-- i.e., not in the group or not targeted by anyone in the group or focus.
	for guid in pairs(self_aura) do
		if not OvaleGUID:GetUnitId(guid) then
			RemoveAurasForGUID(guid)
		end
	end
end

function UpdateAuras(unitId, unitGUID)
	self_serial = self_serial + 1
	
	if not unitId then
		return
	end
	if not unitGUID then
		unitGUID = OvaleGUID:GetGUID(unitId)
	end
	if not unitGUID then
		return
	end

	if not self_aura[unitGUID] then
		self_aura[unitGUID] = {}
	end
	
	local i = 1
	local filter = "HELPFUL"
	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId
	local canApplyAura, isBossDebuff, isCastByPlayer, value1, value2, value3
	while (true) do
		name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId,
			canApplyAura, isBossDebuff, isCastByPlayer, value1, value2, value3 = API_UnitAura(unitId, i, filter)
		if not name then
			if filter == "HELPFUL" then
				filter = "HARMFUL"
				i = 1
			else
				break
			end
		else
			AddAura(unitGUID, spellId, filter, unitCaster, icon, count, debuffType, duration, expirationTime, isStealable, name, value1)
			if debuffType then
				-- TODO: not very clean
				-- should be computed by OvaleState:GetAura
				AddAura(unitGUID, debuffType, filter, unitCaster, icon, count, debuffType, duration, expirationTime, isStealable, name, value1)
			end
			i = i + 1
		end
	end

	--Removes expired auras
	for filter, auraList in pairs(self_aura[unitGUID]) do
		for spellId, whoseTable in pairs(auraList) do
			for whose, aura in pairs(whoseTable) do
				if aura.serial ~= self_serial then
					Ovale:DebugPrintf("aura", "Removing %s %s from %s, serial=%d aura.serial=%d", filter, aura.name, whose, self_serial, aura.serial)
					whoseTable[whose] = nil
					self_pool:Release(aura)
				end
			end
			if not next(whoseTable) then
				auraList[spellId] = nil
			end
		end
		if not next(auraList) then
			self_aura[unitGUID][filter] = nil
		end
	end
	if not next(self_aura[unitGUID]) then
		self_aura[unitGUID] = nil
	end

	Ovale.refreshNeeded[unitId] = true
end
--</private-static-methods>

--<public-static-methods>
function OvaleAura:OnEnable()
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
	elseif strfind(event, "SPELL_AURA_") == 1 then
		-- KNOWN BUG: an aura refreshed by a spell other than then one that applies it won't cause the CLEU event to fire.
		local unitId = OvaleGUID:GetUnitId(destGUID)
		if unitId and not OVALE_UNIT_AURA_UNITS[unitId] then
			UpdateAuras(unitId, destGUID)
		end
	end
end

function OvaleAura:PLAYER_ENTERING_WORLD(event)
	RemoveAurasForMissingUnits()
	self_pool:Drain()
end

function OvaleAura:UNIT_AURA(event, unitId)
	if unitId == "player" then
		UpdateAuras("player", OvaleGUID:GetGUID("player"))
	elseif unitId then
		UpdateAuras(unitId)
	end
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
		UpdateAuras(unitId, guid)
		auraTable = self_aura[guid]
		if not auraTable then
			-- no aura on target
			Ovale:Logf("Target %s has no aura", guid)
			return nil
		end
	end

	local whose, aura
	if filter then
		if auraTable[filter] then
			local whoseTable = auraTable[filter][spellId]
			if whoseTable then
				if mine then
					aura = whoseTable.mine
				else
					whose, aura = next(whoseTable)
				end
			end
		end
	else
		local whoseTable
		for _, auraList in pairs(auraTable) do
			whoseTable = auraList[spellId]
			if whoseTable then
				if mine then
					aura = whoseTable.mine
				else
					whose, aura = next(whoseTable)
				end
				if aura then break end
			end
		end
	end
	if not aura then return nil end
	return aura.start, aura.ending, aura.stacks, aura.tick, aura.value, aura.gain
end

function OvaleAura:GetAura(unitId, spellId, filter, mine)
	local guid = OvaleGUID:GetGUID(unitId)
	if type(spellId) == "number" then
		return self:GetAuraByGUID(guid, spellId, filter, mine, unitId)
	elseif OvaleData.buffSpellList[spellId] then
		local newStart, newEnding, newStacks, newTick, newValue, newGain
		for _, v in pairs(OvaleData.buffSpellList[spellId]) do
			local start, ending, stacks, tick, value, gain = self:GetAuraByGUID(guid, v, filter, mine, unitId)
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
	elseif spellId == "Magic" or spellId == "Disease" or spellId == "Curse" or spellId == "Poison" then
		return self:GetAuraByGUID(guid, spellId, filter, mine, unitId)
	end
end

function OvaleAura:GetStealable(unitId)
	local auraTable = self_aura[OvaleGUID:GetGUID(unitId)]
	if not auraTable then return nil end

	-- only buffs are stealable
	local auraList = auraTable.HELPFUL
	if not auraList then return nil end

	local start, ending
	for spellId, whoseTable in pairs(auraList) do
		local aura = whoseTable.other
		if aura and aura.stealable then
			if aura.start and (not start or aura.start < start) then
				start = aura.start
			end
			if aura.ending and (not ending or aura.ending > ending) then
				ending = aura.ending
			end
		end
	end
	return start, ending
end

-- Look for my aura on any target.
-- Returns the earliest start time, the latest ending time, and the number of auras seen.
function OvaleAura:GetMyAuraOnAnyTarget(spellId, filter, excludingGUID)
	local start, ending
	local count = 0
	for guid, auraTable in pairs(self_aura) do
		if guid ~= excludingGUID then
			for auraFilter, auraList in pairs(auraTable) do
				if not filter or auraFilter == filter then
					if auraList[spellId] then
						local aura = auraList[spellId].mine
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

function OvaleAura:GetDamageMultiplier(spellId)
	-- Calculate the base damage multiplier for all spells.
	local damageMultiplier = 1
	local playerGUID = OvaleGUID:GetGUID("player")
	for auraSpellId, multiplier in pairs(OvaleData.selfDamageBuff) do
		local count = select(3, self:GetAuraByGUID(playerGUID, auraSpellId, filter, nil, "player"))
		if count and count > 0 then
			-- Try to account for a stacking aura.
			multiplier = 1 + (multiplier - 1) * count
			damageMultiplier = damageMultiplier * multiplier
		end
	end

	-- Factor in the spell-specific multipliers from SpellDamage{Buff,Debuff} declarations.
	if spellId then
		local si = OvaleData.spellInfo[spellId]
		if si and si.damageAura then
			for filter, auraList in pairs(si.damageAura) do
				for auraSpellId, multiplier in pairs(auraList) do
					count = select(3, self:GetAuraByGUID(playerGUID, auraSpellId, filter, nil, "player"))
					if count and count > 0 then
						-- Try to account for a stacking aura.
						multiplier = 1 + (multiplier - 1) * count
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
	for guid, auraTable in pairs(self_aura) do
		for filter, auraList in pairs(auraTable) do
			for spellId, whoseTable in pairs(auraList) do
				for whose, aura in pairs(whoseTable) do
					Ovale:Printf("%s %s %s %s %s stacks=%d tick=%s", guid, filter, whose, spellId, aura.name, aura.stacks, aura.tick)
				end
			end
		end
	end
end

-- Print the auras matching the filter on the unit in alphabetical order.
function OvaleAura:DebugListAura(unitId, filter)
	local guid = OvaleGUID:GetGUID(unitId)
	if self_aura[guid] and self_aura[guid][filter] then
		local array = {}
		for spellId, whoseTable in pairs(self_aura[guid][filter]) do
			for whose, aura in pairs(whoseTable) do
				tinsert(array, aura.name .. ": " .. spellId)
			end
		end
		tsort(array)
		for _, v in ipairs(array) do
			Ovale:Print(v)
		end
	end
end
--</public-static-methods>
