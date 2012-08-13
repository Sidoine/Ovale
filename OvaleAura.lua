-- This addon keep the list of all the aura for all the units
-- Fore each aura, it saves the state of the player when it was refreshed

OvaleAura = LibStub("AceAddon-3.0"):NewAddon("OvaleAura", "AceEvent-3.0")

--<public-static-properties>
OvaleAura.aura = {}
OvaleAura.serial = 0
OvaleAura.spellHaste = 1
OvaleAura.meleeHaste = 1
OvaleAura.damageMultiplier = 1
OvaleAura.playerGUID = nil
--</public-static-properties>

-- Events
--<public-static-methods>
function OvaleAura:OnEnable()
	self.playerGUID = UnitGUID("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function OvaleAura:OnDisable()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function OvaleAura:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local time, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)

	if string.find(event, "SPELL_AURA_") == 1 then
		local spellId, spellName, spellSchool, auraType = select(12, ...)
	
		local unitId = OvaleGUID:GetUnitId(destGUID)
	
		if unitId then
			self:UpdateAuras(unitId, destGUID)
		end
		
		if sourceGUID == self.playerGUID and (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_APPLIED_DOSE") then
			local aura = self:GetAuraByGUID(destGUID, spellId, true)
			if aura then
				aura.spellHaste = self.spellHaste
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

function OvaleAura:AddAura(unitGUID, spellId, unitCaster, icon, count, debuffType, duration, expirationTime, isStealable, name)
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
	
	if not aura.ending or aura.ending < expirationTime or aura.stacks < count then
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
	end
end

-- Private methods
function OvaleAura:UpdateAuras(unitId, unitGUID)
	self.serial = self.serial + 1
	
	local hateBase
	local hateCommune
	local hateSorts
	local hateCaC
	local hateHero
	local hateClasse
	local damageMultiplier
	
	if unitId == "player" then
		hateBase = GetCombatRatingBonus(18)
		hateCommune = 0
		hateSorts = 0
		hateCaC = 0
		hateHero = 0
		hateClasse = 0
		damageMultiplier = 1
	end
		
	if not unitGUID then
		unitGUID = UnitGUID(unitId)
	end

	if not self.aura[unitGUID] then
		self.aura[unitGUID] = {}
	end
	
	local i = 1
	
	local mode = "HELPFUL"
	while (true) do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId =  UnitAura(unitId, i, mode)
		if not name then
			if mode == "HELPFUL" then
				mode = "HARMFUL"
				i = 1
			else
				break
			end
		else
			self:AddAura(unitGUID, spellId, unitCaster, icon, count, debuffType, duration, expirationTime, isStealable, name)
			if debuffType then
				-- TODO: not very clean
				-- should be computed by OvaleState:GetAura
				self:AddAura(unitGUID, debuffType, unitCaster, icon, count, debuffType, duration, expirationTime, isStealable, name)
			end
			
			if unitId == "player" then
				if OvaleData.buffSpellList.spellhaste[spellId] then
					hateSorts = 5
				elseif OvaleData.buffSpellList.meleehaste[spellId] then 
					hateCaC = 10
				elseif OvaleData.buffSpellList.heroism[spellId] then
					hateHero = 30
				elseif OvaleData.selfHasteBuff[spellId] then
					hateClasse = OvaleData.selfHasteBuff[spellId]
				end
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
				-- Ovale:Print("Removing "..aura.name.." from "..whose .. " self.serial = " ..self.serial .. " aura.serial = " ..aura.serial)
				whoseTable[whose] = nil
			end
		end
		if not next(whoseTable) then
			--Ovale:Print("Removing "..spellId)
			auraList[spellId] = nil
		end
	end
	
	--Clear unit if all aura have been deleted
	if not next(auraList) then
		self.aura[unitGUID] = nil
	end
	
	--Update player haste 
	if unitId == "player" then
		self.spellHaste = 1 + (hateBase + hateCommune + hateSorts + hateHero + hateClasse)/100
		self.meleeHaste = 1 + (hateBase + hateCommune + hateCaC + hateHero + hateClasse)/100
		self.damageMultiplier = damageMultiplier
	end
	
	Ovale.refreshNeeded[unitId] = true
end

-- Public methods
function OvaleAura:GetAuraByGUID(guid, spellId, mine, unitId)
	if not guid then
		return nil
	end
	local auraTable = self.aura[guid]
	if not auraTable then 
		if not unitId then
			unitId = OvaleGUID:GetUnitId(guid)
		end
		if not unitId then
			return nil
		end
		self:UpdateAuras(unitId, guid)
		auraTable = self.aura[guid]
		if not auraTable then
			-- no aura on target
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

-- Look for the last of my aura on any targt that will expires.
-- Returns its expiration time
function OvaleAura:GetExpirationTimeOnAnyTarget(spellId)
	local ending = nil
	local starting = nil
	
	for unitId,auraTable in pairs(self.aura) do
		if auraTable[spellId] then
			local aura = auraTable[spellId].mine
			if aura then
				local newEnding = aura.ending
				local newStarting = aura.start
				if newStarting and (not staring or newStarting < starting) then
					starting = newStarting
				end
				if newEnding and (not ending or newEnding > ending) then
					ending = newEnding
				end
			end
		end		
	end
	return starting, ending
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
