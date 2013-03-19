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

local pairs = pairs
local select = select
local strfind = string.find
local API_UnitAura = UnitAura

local self_baseDamageMultiplier = 1
local self_pool = OvalePool:NewPool("OvaleAura_pool")
local self_aura = {}
local self_serial = 0
--</private-static-properties>

--<private-static-methods>
local function AddAura(unitGUID, spellId, unitCaster, icon, count, debuffType, duration, expirationTime, isStealable, name, value)
	local auraList = self_aura[unitGUID]
	if not auraList[spellId] then
		auraList[spellId] = {}
	end

	-- Re-use existing aura by updating its serial number and adding new information
	-- if it differs from the old aura.
	local mine = (unitCaster == "player")
	local aura
	if mine then
		if not auraList[spellId].mine then
			aura = self_pool:Get()
			aura.gain = Ovale.now
			auraList[spellId].mine = aura
		end
		aura = auraList[spellId].mine
	else
		if not auraList[spellId].other then
			aura = self_pool:Get()
			aura.gain = Ovale.now
			auraList[spellId].other = aura
		end
		aura = auraList[spellId].other
	end

	aura.serial = self_serial
	if count == 0 then
		count = 1
	end

	if not aura.ending or aura.ending < expirationTime or aura.stacks ~= count then
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
	end
end

local function RemoveAurasForGUID(guid)
	-- Return all auras for the given GUID to the aura pool.
	if not guid or not self_aura[guid] then return end
	Ovale:DebugPrint("aura", "Removing auras for guid " .. guid)
	for spellId, whoseTable in pairs(self_aura[guid]) do
		for whose, aura in pairs(whoseTable) do
			whoseTable[whose] = nil
			self_pool:Release(aura)
		end
		self_aura[guid][spellId] = nil
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
	local time, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)

	if event == "UNIT_DIED" then
		RemoveAurasForGUID(destGUID)
	elseif strfind(event, "SPELL_AURA_") == 1 then
		-- KNOWN BUG: an aura refreshed by a spell other than then one that applies it won't cause the CLEU event to fire.
		local spellId, spellName, spellSchool, auraType = select(12, ...)

		-- Only update for "*target" unit IDs.  All others are handled by UNIT_AURA event handler.
		local unitId = OvaleGUID:GetUnitId(destGUID)
		if unitId and unitId ~= "target" and strfind(unitId, "target") then
			self:UpdateAuras(unitId, destGUID)
		end

		if sourceGUID == OvaleGUID:GetGUID("player") and (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_APPLIED_DOSE") then
			if self:GetAuraByGUID(destGUID, spellId, true) then
				local aura = self_aura[destGUID][spellId].mine
				aura.spellHasteMultiplier = OvalePaperDoll:GetSpellHasteMultiplier()
			end
		end
	end
end

function OvaleAura:PLAYER_ENTERING_WORLD(event)
	RemoveAurasForMissingUnits()
	self_pool:Drain()
end

function OvaleAura:UNIT_AURA(event, unitId)
	if unitId == "player" then
		self:UpdateAuras("player", OvaleGUID:GetGUID("player"))
	elseif unitId then
		self:UpdateAuras(unitId)
	end
end

function OvaleAura:Ovale_InactiveUnit(event, guid)
	RemoveAurasForGUID(guid)
end

function OvaleAura:UpdateAuras(unitId, unitGUID)
	self_serial = self_serial + 1
	
	local damageMultiplier

	if not unitId then
		return
	end
	if not unitGUID then
		unitGUID = OvaleGUID:GetGUID(unitId)
	end
	if not unitGUID then
		return
	end

	if unitId == "player" then
		damageMultiplier = 1
	end

	if not self_aura[unitGUID] then
		self_aura[unitGUID] = {}
	end
	
	local i = 1
	
	local mode = "HELPFUL"
	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId
	local canApplyAura, isBossDebuff, isCastByPlayer, value1, value2, value3
	while (true) do
		name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId,
			canApplyAura, isBossDebuff, isCastByPlayer, value1, value2, value3 = API_UnitAura(unitId, i, mode)
		if not name then
			if mode == "HELPFUL" then
				mode = "HARMFUL"
				i = 1
			else
				break
			end
		else
			AddAura(unitGUID, spellId, unitCaster, icon, count, debuffType, duration, expirationTime, isStealable, name, value1)
			if debuffType then
				-- TODO: not very clean
				-- should be computed by OvaleState:GetAura
				AddAura(unitGUID, debuffType, unitCaster, icon, count, debuffType, duration, expirationTime, isStealable, name, value1)
			end
			
			if unitId == "player" then
				if OvaleData.selfDamageBuff[spellId] then
					damageMultiplier = damageMultiplier * OvaleData.selfDamageBuff[spellId]
				end
			end
			i = i + 1
		end
	end
	
	--Removes expired auras
	local auraList = self_aura[unitGUID]
	for spellId,whoseTable in pairs(auraList) do
		for whose,aura in pairs(whoseTable) do
			if aura.serial ~= self_serial then
				Ovale:DebugPrint("aura", "Removing "..aura.name.." from "..whose .. ", serial = " ..self_serial.. " aura.serial = " ..aura.serial)
				whoseTable[whose] = nil
				self_pool:Release(aura)
			end
		end
		if not next(whoseTable) then
			Ovale:DebugPrint("aura", "Removing "..spellId)
			auraList[spellId] = nil
		end
	end
	
	--Clear unit if all aura have been deleted
	if not next(auraList) then
		self_aura[unitGUID] = nil
	end
	
	if unitId == "player" then
		self_baseDamageMultiplier = damageMultiplier
	end
	
	Ovale.refreshNeeded[unitId] = true
end

-- Public methods
function OvaleAura:GetAuraByGUID(guid, spellId, mine, unitId)
	if not guid then
		Ovale:Log(tostring(guid) .. " does not exists in OvaleAura")
		return nil
	end
	local auraTable = self_aura[guid]
	if not auraTable then 
		if not unitId then
			unitId = OvaleGUID:GetUnitId(guid)
		end
		if not unitId then
			Ovale:Log("Unable to get unitId from " .. tostring(guid))
			return nil
		end
		self:UpdateAuras(unitId, guid)
		auraTable = self_aura[guid]
		if not auraTable then
			-- no aura on target
			Ovale:Log("Target " .. guid .. " has no aura")
			return nil
		end
	end
	local whoseTable = auraTable[spellId]
	if not whoseTable then return nil end
	local aura
	if mine or mine == 1 then
		aura = whoseTable.mine
	elseif whoseTable.other then
		aura = whoseTable.other
	else
		aura = whoseTable.mine
	end
	if not aura then return nil end
	return aura.start, aura.ending, aura.stacks, aura.spellHasteMultiplier, aura.value, aura.gain
end

function OvaleAura:GetAura(unitId, spellId, mine)
	return self:GetAuraByGUID(OvaleGUID:GetGUID(unitId), spellId, mine, unitId)
end

function OvaleAura:GetStealable(unitId)
	local auraTable = self_aura[OvaleGUID:GetGUID(unitId)]
	if not auraTable then
		return nil
	end
	local starting,ending
	
	for spellId, ownerTable in pairs(auraTable) do
		local aura = ownerTable.other
		if aura and aura.stealable then
			if not starting or aura.start < starting then
				starting = aura.start
			end
			if not ending or aura.ending > ending then
				ending = aura.ending
			end
		end
	end
	return starting, ending
end

-- Look for the last of my aura on any targt that will expires.
-- Returns its expiration time
function OvaleAura:GetExpirationTimeOnAnyTarget(spellId, excludingTarget)
	local ending = nil
	local starting = nil
	local count = 0
	
	for unitId,auraTable in pairs(self_aura) do
		if unitId ~= excludingTarget then
			if auraTable[spellId] then
				local aura = auraTable[spellId].mine
				if aura then
					local newEnding = aura.ending
					local newStarting = aura.start
					if newStarting and (not starting or newStarting < starting) then
						starting = newStarting
					end
					if newEnding and (not ending or newEnding > ending) then
						ending = newEnding
					end
					count = count + 1
				end
			end		
		end
	end
	return starting, ending, count
end

function OvaleAura:GetDamageMultiplier(spellId)
	local damageMultiplier = self_baseDamageMultiplier
	if spellId then
		local si = OvaleData.spellInfo[spellId]
		if si and si.damageAura then
			local guid = OvaleGUID:GetGUID("player")
			self:UpdateAuras("player", guid)
			local auraTable = self_aura[guid]
			if auraTable then
				for filter, filterInfo in pairs(si.damageAura) do
					for auraSpellId, multiplier in pairs(filterInfo) do
						if auraTable[auraSpellId] then
							damageMultiplier = damageMultiplier * multiplier
						end
					end
				end
			end
		end
	end
	return damageMultiplier
end

function OvaleAura:Debug()
	self_pool:Debug()
	for guid,auraTable in pairs(self_aura) do
		Ovale:Print("***"..guid)
		for spellId,whoseTable in pairs(auraTable) do
			for whose,aura in pairs(whoseTable) do
				Ovale:Print(guid.." "..whose.." "..spellId .. " "..aura.name .. " stacks ="..aura.stacks)
			end
		end
	end
	Ovale:Print("------")
end
--</public-static-methods>
