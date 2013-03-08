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
OvaleAura = Ovale:NewModule("OvaleAura", "AceEvent-3.0")

--<public-static-properties>
OvaleAura.aura = {}
OvaleAura.serial = 0
OvaleAura.playerGUID = nil
--</public-static-properties>

--<private-static-properties>
local baseDamageMultiplier = 1

local pairs, select, strfind = pairs, select, string.find
local UnitAura = UnitAura
--</private-static-properties>

-- Events
--<public-static-methods>
function OvaleAura:OnEnable()
	self.playerGUID = UnitGUID("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("UNIT_AURA")
end

function OvaleAura:OnDisable()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("UNIT_AURA")
end

function OvaleAura:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local time, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)

	-- KNOWN BUG: an aura refreshed by a spell other than then one that applies it won't cause the CLEU event to fire.
	if strfind(event, "SPELL_AURA_") == 1 then
		local spellId, spellName, spellSchool, auraType = select(12, ...)

		if (sourceGUID == self.playerGUID and OvaleData.spellFilter.mine[spellId]) or OvaleData.spellFilter.any[spellId] then
			local unitId = OvaleGUID:GetUnitId(destGUID)

			-- Only update for "*target" unit IDs.  All others are handled by UNIT_AURA event handler.
			if unitId and unitId ~= "target" and strfind(unitId, "target") then
				self:UpdateAuras(unitId, destGUID)
			end

			if sourceGUID == self.playerGUID and (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_APPLIED_DOSE") then
				local aura = self:GetAuraByGUID(destGUID, spellId, true)
				if aura then
					aura.spellHasteMultiplier = OvalePaperDoll:GetSpellHasteMultiplier()
				end
			end
		end
	end

	if event == "UNIT_DIED" then
		self.aura[destGUID] = nil
		local unitId = OvaleGUID:GetUnitId(destGUID)
		if unitId then
			Ovale.refreshNeeded[unitId] = true
		end
	end
end

function OvaleAura:UNIT_AURA(event, unitId)
	if unitId == "player" then
		self:UpdateAuras("player", self.playerGUID)
	elseif unitId then
		self:UpdateAuras(unitId)
	end
end

function OvaleAura:AddAura(unitGUID, spellId, unitCaster, icon, count, debuffType, duration, expirationTime, isStealable, name, value)
	local auraList = self.aura[unitGUID]

	if not auraList[spellId] then
		auraList[spellId] = {}
	end
		
	local mine = (unitCaster == "player")
	local aura
	if mine then
		if not auraList[spellId].mine then
			auraList[spellId].mine = { gain = OvaleState.maintenant }
		end
		aura = auraList[spellId].mine
	else
		if not auraList[spellId].other then
			auraList[spellId].other = { gain = OvaleState.maintenant }
		end
		aura = auraList[spellId].other
	end
	
	aura.serial = self.serial
	
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

-- Private methods
function OvaleAura:UpdateAuras(unitId, unitGUID)
	self.serial = self.serial + 1
	
	local damageMultiplier

	if not unitId then
		return
	end
	if not unitGUID and unitId == "player" then
		unitGUID = self.playerGUID
	end
	if not unitGUID then
		unitGUID = UnitGUID(unitId)
	end
	if not unitGUID then
		return
	end

	if unitId == "player" then
		damageMultiplier = 1
	end

	if not self.aura[unitGUID] then
		self.aura[unitGUID] = {}
	end
	
	local i = 1
	
	local mode = "HELPFUL"
	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId
	local canApplyAura, isBossDebuff, isCastByPlayer, value1, value2, value3
	while (true) do
		name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId,
			canApplyAura, isBossDebuff, isCastByPlayer, value1, value2, value3 = UnitAura(unitId, i, mode)
		if not name then
			if mode == "HELPFUL" then
				mode = "HARMFUL"
				i = 1
			else
				break
			end
		else
			if (unitCaster == "player" and OvaleData.spellFilter.mine[spellId]) or OvaleData.spellFilter.any[spellId] then
				self:AddAura(unitGUID, spellId, unitCaster, icon, count, debuffType, duration, expirationTime, isStealable, name, value1)
				if debuffType then
					-- TODO: not very clean
					-- should be computed by OvaleState:GetAura
					self:AddAura(unitGUID, debuffType, unitCaster, icon, count, debuffType, duration, expirationTime, isStealable, name, value1)
				end
			end
			
			if unitId == "player" then
				if OvaleData.selfDamageBuff[spellId] then
					damageMultiplier = damageMultiplier * OvaleData.selfDamageBuff[spellId]
				end
			end
			i = i + 1
		end
	end
	
	local auraList = self.aura[unitGUID]
	--Removes expired aura
	for spellId,whoseTable in pairs(auraList) do
		for whose,aura in pairs(whoseTable) do
			if aura.serial ~= self.serial then
				Ovale:debugPrint("aura", "Removing "..aura.name.." from "..whose .. " self.serial = " ..self.serial .. " aura.serial = " ..aura.serial)
				whoseTable[whose] = nil
			end
		end
		if not next(whoseTable) then
			Ovale:debugPrint("aura", "Removing "..spellId)
			auraList[spellId] = nil
		end
	end
	
	--Clear unit if all aura have been deleted
	if not next(auraList) then
		self.aura[unitGUID] = nil
	end
	
	if unitId == "player" then
		baseDamageMultiplier = damageMultiplier
	end
	
	Ovale.refreshNeeded[unitId] = true
end

-- Public methods
function OvaleAura:GetAuraByGUID(guid, spellId, mine, unitId)
	if not guid then
		Ovale:Log(tostring(guid) .. " does not exists in OvaleAura")
		return nil
	end
	local auraTable = self.aura[guid]
	if not auraTable then 
		if not unitId then
			unitId = OvaleGUID:GetUnitId(guid)
		end
		if not unitId then
			Ovale:Log("Unable to get unitId from " .. tostring(guid))
			return nil
		end
		self:UpdateAuras(unitId, guid)
		auraTable = self.aura[guid]
		if not auraTable then
			-- no aura on target
			Ovale:Log("Target " .. guid .. " has no aura")
			return nil
		end
	end
	local aura = auraTable[spellId]
	if not aura then return nil end
	if mine or mine == 1 then
		return aura.mine
	elseif aura.other then
		return aura.other
	else
		return aura.mine
	end
end

function OvaleAura:GetAura(unitId, spellId, mine)
	return self:GetAuraByGUID(UnitGUID(unitId), spellId, mine, unitId)
end

function OvaleAura:GetStealable(unitId)
	local auraTable = self.aura[UnitGUID(unitId)]
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
	
	for unitId,auraTable in pairs(self.aura) do
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
	local damageMultiplier = baseDamageMultiplier
	if spellId then
		local si = OvaleData.spellInfo[spellId]
		if si and si.damageAura then
			self:UpdateAuras("player", self.playerGUID)
			local auraTable = self.aura[self.playerGUID]
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
	Ovale:Print("------")
	for guid,auraTable in pairs(self.aura) do
		Ovale:Print("***"..guid)
		for spellId,whoseTable in pairs(auraTable) do
			for whose,aura in pairs(whoseTable) do
				Ovale:Print(guid.." "..whose.." "..spellId .. " "..aura.name .. " stacks ="..aura.stacks)
			end
		end
	end
end
--</public-static-methods>
