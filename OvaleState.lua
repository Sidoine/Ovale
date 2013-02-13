--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013 Sidoine, Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

-- Keep the current state in the simulation

OvaleState = {}

--<public-static-properties>
--the state in the current frame
OvaleState.state = {rune={}, cd = {}, counter={}}
OvaleState.aura = {}
OvaleState.serial = 0
for i=1,6 do
	OvaleState.state.rune[i] = {}
end
--The spell being cast
OvaleState.currentSpellId = nil
--Allows to debug auras
OvaleState.traceAura = false
OvaleState.maintenant = nil
OvaleState.currentTime = nil
OvaleState.attenteFinCast = nil
OvaleState.startCast = nil
OvaleState.endCast = nil
OvaleState.gcd = 1.5
OvaleState.powerRate = {}
OvaleState.lastSpellId = nil
--</public-static-properties>

--<private-static-properties>
local floor, pairs, tostring = math.floor, pairs, tostring
local GetRuneCooldown, GetRuneType = GetRuneCooldown, GetRuneType
local GetSpellInfo, UnitGUID, UnitHealth = GetSpellInfo, UnitGUID, UnitHealth
local UnitHealthMax, UnitPower, UnitPowerMax = UnitHealthMax, UnitPower, UnitPowerMax
local MAX_COMBO_POINTS = MAX_COMBO_POINTS
--</private-static-properties>

--<public-static-methods>
function OvaleState:StartNewFrame()
	self.maintenant = GetTime()
	self.gcd = OvaleData:GetGCD()
end

function OvaleState:UpdatePowerRates()
	for k,v in pairs(OvaleData.power) do
		self.powerRate[k] = 0
	end

	self.powerRate.energy = 10 * OvaleAura.meleeHaste

	if OvaleData.className == "MONK" then
		-- Ascension (monk)
		if OvaleData:GetTalentPoints(8) > 0 then
			self.powerRate.energy = self.powerRate.energy * 1.15
		end

		-- Stance of the Sturdy Ox (brewmaster monk)
		if OvaleStance:IsStance("monk_stance_of_the_sturdy_ox") then
			self.powerRate.energy = self.powerRate.energy * 1.1
		end
	end

	-- Adrenaline Rush (rogue)
	if OvaleData.className == "ROGUE" and OvaleState:GetAura("player", 13750, true) then
		self.powerRate.energy = self.powerRate.energy * 2
	end
	
	self.powerRate.focus = 4 * OvaleAura.meleeHaste
end

function OvaleState:Reset()
	self.lastSpellId = OvaleFuture.lastSpellId
	self.serial = self.serial + 1
	self.currentTime = self.maintenant
	Ovale:Log("Reset state with current time = " .. self.currentTime)
	self.currentSpellId = nil
	self.attenteFinCast = self.maintenant
	self.state.combo = OvaleComboPoints.combo
	for k,v in pairs(OvaleData.power) do
		self.state[k] = UnitPower("player", v.id)
	end
	
	self:UpdatePowerRates()
	
	if OvaleData.className == "DEATHKNIGHT" then
		for i=1,6 do
			self.state.rune[i].type = GetRuneType(i)
			local start, duration, runeReady = GetRuneCooldown(i)
			self.state.rune[i].duration = duration
			if runeReady then
				self.state.rune[i].cd = start
			else
				self.state.rune[i].cd = duration + start
				if self.state.rune[i].cd<0 then
					self.state.rune[i].cd = 0
				end
			end
		end
	end
	for k,v in pairs(self.state.cd) do
		v.start = nil
		v.duration = nil
		v.enable = 0
		v.toggled = nil
	end
	
	for k,v in pairs(self.state.counter) do
		self.state.counter[k] = OvaleFuture.counter[k]
	end
end

-- Cast a spell in the simulator
-- spellId : the spell id
-- startCast : temps du cast
-- endCast : fin du cast
-- nextCast : temps auquel le prochain sort peut être lancé (>=endCast, avec le GCD)
-- nocd : le sort ne déclenche pas son cooldown
function OvaleState:AddSpellToStack(spellId, startCast, endCast, nextCast, nocd, targetGUID)
	if not spellId or not targetGUID then
		return
	end
	
	local newSpellInfo = OvaleData.spellInfo[spellId]
	
	self.lastSpellId = spellId
	--On enregistre les infos sur le sort en cours
	self.attenteFinCast = nextCast
	self.currentSpellId = spellId
	self.startCast = startCast
	self.endCast = endCast
	--Temps actuel de la simulation : un peu après le dernier cast (ou maintenant si dans le passé)
	if startCast>=self.maintenant then
		self.currentTime = startCast+0.1
	else
		self.currentTime = self.maintenant
	end
	
	if Ovale.trace then
		Ovale:Print("add spell "..spellId.." at "..startCast.." currentTime = "..self.currentTime.. " nextCast="..self.attenteFinCast .. " endCast="..endCast .. " targetGUID = " .. tostring(targetGUID))
	end
	
	--Effet du sort au moment du début du cast
	--(donc si cast déjà commencé, on n'en tient pas compte)
	if startCast >= self.maintenant then
		if newSpellInfo then
			if newSpellInfo.inccounter then
				local id = newSpellInfo.inccounter
				self.state.counter[id] = self:GetCounterValue(id) + 1
			end
			
			if newSpellInfo.resetcounter then
				self.state.counter[newSpellInfo.resetcounter] = 0
			end
		end
	end
	
	--Effet du sort au moment où il est lancé
	--(donc si il est déjà lancé, on n'en tient pas compte)
	if endCast >= self.maintenant then
		--Mana
		local _, _, _, cost, _, powerType = GetSpellInfo(spellId)
		local power = OvaleData.powerType[powerType]
		if cost and power and (not newSpellInfo or not newSpellInfo[power]) then
			self.state[power] = self.state[power] - cost
		end

		if newSpellInfo then
			-- Update power state, except for eclipse, combo, and runes.
			for k,v in pairs(OvaleData.power) do
				-- eclipse cost is on hit
				if newSpellInfo[k] and k ~= "eclipse" then
					if newSpellInfo[k] == 0 then
						self.state[k] = 0
					else
						self.state[k] = self.state[k] - newSpellInfo[k]
					end
					if self.state[k] < v.mini then
						self.state[k] = v.mini
					end
					if v.maxi and self.state[k] > v.maxi then
						self.state[k] = v.maxi
					else
						local maxi = UnitPowerMax("player", v.id)
						if maxi and self.state[k] > maxi then
							self.state[k] = maxi
						end
					end
				end
			end

			--[[
				This section is not needed since self.state.combo tracks OvaleComboPoints, which updates
				the number of combo points even before the spell has been "successfully" cast.

			--Points de combo
			if newSpellInfo.combo then
				if newSpellInfo.combo == 0 then
					self.state.combo = 0
				else
					self.state.combo = self.state.combo + newSpellInfo.combo
					if OvaleData.className == "ROGUE" and self:GetAura("player", 121471, true) then
						-- Shadow Blades generates an extra combo point.
						self.state.combo = self.state.combo + 1
					end
				end
				if self.state.combo < 0 then
					self.state.combo = 0
				end
				if self.state.combo > MAX_COMBO_POINTS then
					self.state.combo = MAX_COMBO_POINTS
				end
			end
			]]--

			--Runes
			if newSpellInfo.frost then
				self:AddRune(startCast, 3, newSpellInfo.frost)
			end
			if newSpellInfo.death then
				self:AddRune(startCast, 4, newSpellInfo.death)
			end
			if newSpellInfo.blood then
				self:AddRune(startCast, 1, newSpellInfo.blood)
			end
			if newSpellInfo.unholy then
				self:AddRune(startCast, 2, newSpellInfo.unholy)
			end
		end
	end
	
	-- Effets du sort au moment où il atteint sa cible
	if newSpellInfo then
		-- Cooldown du sort
		local cd = self:GetCD(spellId)
		if cd then
			cd.start = startCast
			cd.duration = newSpellInfo.cd
			--Pas de cooldown
			if nocd then
				cd.duration = 0
			end
			--On vérifie si le buff "buffnocd" est présent, auquel cas le CD du sort n'est pas déclenché
			if newSpellInfo.buffnocd and not nocd then
				local buffAura = self:GetAura("player", newSpellInfo.buffnocd, true)
				if self.traceAura then
					if buffAura then
						Ovale:Print("buffAura stacks = "..buffAura.stacks.." start="..tostring(buffAura.start).." ending = "..tostring(buffAura.ending))
						Ovale:Print("startCast = "..startCast)
					else
						Ovale:Print("buffAura = nil")
					end
					self.traceAura = false
				end
				if buffAura and buffAura.stacks>0 and buffAura.start and buffAura.start<=startCast and (not buffAura.ending or buffAura.ending>startCast) then
					cd.duration = 0
				end
			end
			if newSpellInfo.targetlifenocd and not nocd then
				--TODO
				if UnitHealth("target")/UnitHealthMax("target")*100<newSpellInfo.targetlifenocd then
					cd.duration = 0
				end
			end
			cd.enable = 1
			if newSpellInfo.toggle then
				cd.toggled = 1
			end
		end

		if newSpellInfo.eclipse then
			self.state.eclipse = self.state.eclipse + newSpellInfo.eclipse
			if self.state.eclipse < -100 then
				self.state.eclipse = -100
				self:AddEclipse(endCast, 48518)
			elseif self.state.eclipse > 100 then
				self.state.eclipse = 100
				self:AddEclipse(endCast, 48517)
			end
		end
		if spellId == 78674 then -- starsurge
			self.state.eclipse = self.state.eclipse + self:GetEclipseDir() * 20
			if self.state.eclipse < -100 then
				self.state.eclipse = -100
				self:AddEclipse(endCast, 48518)
			elseif self.state.eclipse > 100 then
				self.state.eclipse = 100
				self:AddEclipse(endCast, 48517)
			end
		end
			
		
		--Auras causés par le sort
		if newSpellInfo.aura then
			for target, targetInfo in pairs(newSpellInfo.aura) do
				if not (target == "player" and endCast <= self.maintenant) then
					-- If the spell has already finished casting, then player auras match the game
					-- state already, so no need to account for traveling spells.  Update auras
					-- affected by the spell in all other cases.
					for filter, filterInfo in pairs(targetInfo) do
						for auraSpellId, spellData in pairs(filterInfo) do

							local auraSpellInfo = OvaleData.spellInfo[auraSpellId]
							local isDoT = auraSpellInfo and auraSpellInfo.tick
							local duration = spellData
							local stacks = duration
							local auraGUID
							if target == "target" then
								auraGUID = targetGUID
							else
								auraGUID = UnitGUID(target)
							end

							-- Set the duration to the proper length if it's a DoT.
							if auraSpellInfo and auraSpellInfo.duration then
								duration = OvaleData:GetDuration(auraSpellId, OvaleAura.spellHaste, self.state.combo, self.state.holy)
							end

							-- If aura is specified with a duration, then assume stacks == 1.
							if stacks ~= "refresh" and stacks > 0 then
								stacks = 1
							end

							local previousAura = self:GetAuraByGUID(auraGUID, auraSpellId, true, target)
							local newAura = self:NewAura(auraGUID, auraSpellId)

							newAura.mine = true

							if stacks ~= "refresh" and stacks == 0 then
								Ovale:Log("Aura "..auraSpellId.." is completely removed")
								newAura.stacks = 0
								newAura.ending = 0	-- self.currentTime?
							elseif previousAura and previousAura.ending and previousAura.ending >= endCast then
								if stacks == "refresh" or stacks > 0 then
									if stacks == "refresh" then
										Ovale:Log("Aura "..auraSpellId.." is refreshed")
										newAura.stacks = previousAura.stacks
									else -- if stacks > 0
										Ovale:Log("Aura "..auraSpellId.." gain stacks (ending was " .. tostring(newAura.ending)..")")
										newAura.stacks = previousAura.stacks + stacks
									end
									newAura.start = previousAura.start
									if isDoT and previousAura.ending > newAura.start then
										-- TODO: check that refreshed DoTs take a new snapshot of player stats.
										local tickLength = OvaleData:GetTickLength(auraSpellId, previousAura.spellHaste)
										local k = floor((previousAura.ending - endCast) / tickLength)
										newAura.ending = previousAura.ending - tickLength * k + duration
										newAura.spellHaste = OvaleAura.spellHaste
									else
										newAura.ending = endCast + duration
									end
									Ovale:Log("Aura "..auraSpellId.." ending is now "..newAura.ending)
								elseif stacks < 0 then
									Ovale:Log("Aura "..auraSpellId.." loses stacks")
									newAura.stacks = previousAura.stacks + stacks
									if Ovale.trace then
										Ovale:Print("removing one stack of "..auraSpellId.." because of ".. spellId.." to ".. newAura.stacks)
									end
									newAura.start = previousAura.start
									newAura.ending = previousAura.ending
									if newAura.stacks <= 0 then
										Ovale:Log("Aura is completely removed")
										newAura.stacks = 0
										newAura.ending = 0	-- self.currentTime?
									end
								end
							else
								Ovale:Log("New aura "..auraSpellId.." at " .. endCast .." on " .. target .. " " .. auraGUID)
								newAura.stacks = stacks
								newAura.start = endCast
								newAura.ending = endCast + duration
								if isDoT then
									newAura.spellHaste = OvaleAura.spellHaste
								end
							end
						end
					end
				end
			end
		end
	end
end

function OvaleState:AddRune(time, type, value)
	if value<0 then
		for i=1,6 do
			if (self.state.rune[i].type == type or self.state.rune[i].type==4)and self.state.rune[i].cd<=time then
				self.state.rune[i].cd = time + 10
			end
		end
	else
	
	end
end

function OvaleState:GetCounterValue(id)
	if self.state.counter[id] then
		return self.state.counter[id]
	else
		return 0
	end
end

function OvaleState:GetCD(spellId)
	if not spellId then
		return nil
	end
	
	if OvaleData.spellInfo[spellId] and OvaleData.spellInfo[spellId].cd then
		local cdname
		if OvaleData.spellInfo[spellId].sharedcd then
			cdname = OvaleData.spellInfo[spellId].sharedcd
		else
			cdname = spellId
		end
		if not self.state.cd[cdname] then
			self.state.cd[cdname] = {}
		end
		return self.state.cd[cdname]
	else
		return nil
	end
end

function OvaleState:AddEclipse(endCast, spellId)
	local newAura = self:NewAura(OvaleGUID.player, spellId)
	newAura.start = endCast + 0.5
	newAura.stacks = 1
	newAura.ending = nil
end

function OvaleState:GetAuraByGUID(guid, spellId, mine, target)
	if self.aura[guid] and self.aura[guid][spellId] and self.aura[guid][spellId].serial == self.serial then
		Ovale:Log("Found aura " .. spellId .. " on " .. tostring(guid))
		return self.aura[guid][spellId]
	else
		Ovale:Log("Aura " .. spellId .. " not found in state for " .. tostring(guid))
		return OvaleAura:GetAuraByGUID(guid, spellId, mine, target)
	end
end

function OvaleState:GetAura(target, spellId, mine)
	return self:GetAuraByGUID(UnitGUID(target), spellId, mine, target)
end

function OvaleState:GetExpirationTimeOnAnyTarget(spellId, excludingTarget)
	local starting, ending, count = OvaleAura:GetExpirationTimeOnAnyTarget(spellId, excludingTarget)
	for unitId,auraTable in pairs(self.aura) do
		if unitId ~= excludingTarget then
			local aura = auraTable[spellId]
			if aura and aura.serial == self.serial then
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
	return starting, ending, count
end

function OvaleState:NewAura(guid, spellId)
	if not self.aura[guid] then
		self.aura[guid] = {}
	end
	if not self.aura[guid][spellId] then
		self.aura[guid][spellId] = {}
	end
	local myAura = self.aura[guid][spellId]
	myAura.serial = self.serial
	myAura.mine = true
	myAura.gain = self.currentTime
	return myAura
end


function OvaleState:GetEclipseDir()
	local value
	local buffAura = self:GetAura("player", 48517) --Solar
	if buffAura and buffAura.stacks>0 then
		value = -1
	else
		buffAura = self:GetAura("player", 48518) --Lunar
		if buffAura and buffAura.stacks>0 then
			value =1
		elseif self.state.eclipse < 0 then
			value = -1
		else
			value = 1
		end
	end
	return value
end

local runes = {}
local runesCD = {}

function OvaleState:GetRunes(blood, frost, unholy, death, nodeath)
	local nombre = 0
	local nombreCD = 0
	local maxCD = nil
	
	for i=1,4 do
		runesCD[i] = 0
	end
	
	runes[1] = blood or 0
	runes[2] = frost or 0
	runes[3] = unholy or 0
	runes[4] = death or 0
		
	for i=1,6 do
		local rune = self.state.rune[i]
		if rune then
			if runes[rune.type] > 0 then
				runes[rune.type] = runes[rune.type] - 1
				if rune.cd > runesCD[rune.type] then
					runesCD[rune.type] = rune.cd
				end
			elseif rune.cd < runesCD[rune.type] then
				runesCD[rune.type] = rune.cd
			end
		end
	end
	
	if not nodeath then
		for i=1,6 do
			local rune = self.state.rune[i]
			if rune and rune.type == 4 then
				for j=1,3 do
					if runes[j]>0 then
						runes[j] = runes[j] - 1
						if rune.cd > runesCD[j] then
							runesCD[j] = rune.cd
						end
						break
					elseif rune.cd < runesCD[j] then
						runesCD[j] = rune.cd
						break
					end
				end
			end
		end
	end
	
	for i=1,4 do
		if runes[i]> 0 then
			return nil
		end
		if not maxCD or runesCD[i]>maxCD then
			maxCD = runesCD[i]
		end
	end
	return maxCD
end
--</public-static-methods>
