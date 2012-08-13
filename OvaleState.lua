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
--</public-static-properties>

--<private-static-properties>
local UnitGUID = UnitGUID
--</private-static-properties>

--<private-static-methods>
local function nilstring(text)
	if text == nil then
		return "nil"
	else
		return text
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleState:StartNewFrame()
	self.maintenant = GetTime()
	self.gcd = OvaleData:GetGCD()
end

function OvaleState:Reset()
	self.serial = self.serial + 1
	self.currentTime = self.maintenant
	self.currentSpellId = nil
	self.attenteFinCast = self.maintenant
	self.state.combo = GetComboPoints("player")
	self.state.mana = UnitPower("player")
	self.state.shard = UnitPower("player", 7)
	self.state.eclipse = UnitPower("player", 8)
	self.state.holy = UnitPower("player", 9)
	if OvaleData.className == "DEATHKNIGHT" then
		for i=1,6 do
			self.state.rune[i].type = GetRuneType(i)
			local start, duration, runeReady = GetRuneCooldown(i)
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
		Ovale:Print("add spell "..spellId.." at "..startCast.." currentTime = "..self.currentTime.. " nextCast="..self.attenteFinCast .. " endCast="..endCast)
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
		local _, _, _, cost = GetSpellInfo(spellId)
		if cost then
			self.state.mana = self.state.mana - cost
		end

		if newSpellInfo then
		
			if newSpellInfo.mana then
				self.state.mana = self.state.mana - newSpellInfo.mana
			end
			
			--Points de combo
			if newSpellInfo.combo then
				self.state.combo = self.state.combo + newSpellInfo.combo
				if self.state.combo<0 then
					self.state.combo = 0
				end
			end
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
			if newSpellInfo.holy then
				self.state.holy = self.state.holy + newSpellInfo.holy
				if self.state.holy < 0 then
					self.state.holy = 0
				elseif self.state.holy > 3 then
					self.state.holy = 3
				end
			end
			if newSpellInfo.shard then
				self.state.shard = self.state.shard + newSpellInfo.shard
				if self.state.shard < 0 then
					self.state.shard = 0
				elseif self.state.shard > 3 then
					self.state.shard = 3
				end
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
				local buffAura = self:GetAura("player", newSpellInfo.buffnocd)
				if self.traceAura then
					if buffAura then
						Ovale:Print("buffAura stacks = "..buffAura.stacks.." start="..nilstring(buffAura.start).." ending = "..nilstring(buffAura.ending))
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
		if newSpellInfo.starsurge then
			local buffAura = self:GetAura("player", 48517) --Solar
			if buffAura and buffAura.stacks>0 then
				Ovale:Log("starsurge with solar buff = " .. (- newSpellInfo.starsurge))
				self.state.eclipse = self.state.eclipse - newSpellInfo.starsurge
			else
				buffAura = self:GetAura("player", 48518) --Lunar
				if buffAura and buffAura.stacks>0 then
					Ovale:Log("starsurge with lunar buff = " .. newSpellInfo.starsurge)
					self.state.eclipse = self.state.eclipse + newSpellInfo.starsurge
				elseif self.state.eclipse < 0 then
					Ovale:Log("starsurge with eclipse < 0 = " .. (- newSpellInfo.starsurge))
					self.state.eclipse = self.state.eclipse - newSpellInfo.starsurge
				else
					Ovale:Log("starsurge with eclipse > 0 = " .. newSpellInfo.starsurge)
					self.state.eclipse = self.state.eclipse + newSpellInfo.starsurge
				end
			end
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
				for filter, filterInfo in pairs(targetInfo) do
					for auraSpellId, spellData in pairs(filterInfo) do
						local newAura
						if target == "target" then
							newAura = self:NewAura(targetGUID, auraSpellId)
						else
							newAura = self:NewAura(UnitGUID(target), auraSpellId)
						end
						newAura.mine = true
						local duration = spellData
						local stacks = duration
						--Optionnellement, on va regarder la durée du buff
						if auraSpellId and OvaleData.spellInfo[auraSpellId] and OvaleData.spellInfo[auraSpellId].duration then
							duration = OvaleData.spellInfo[auraSpellId].duration
						elseif stacks~="refresh" and stacks > 0 then
							stacks = 1
						end
						if stacks=="refresh" then
							if newAura.ending then
								newAura.ending = endCast + duration
							end
						elseif stacks<0 and newAura.ending then
							--Buff are immediatly removed when the cast ended, do not need to do it again
							if filter~="HELPFUL" or target~="player" or endCast>=self.maintenant then
								newAura.stacks = newAura.stacks + stacks
								if Ovale.trace then
									Ovale:Print("removing one stack of "..auraSpellId.." because of ".. spellId.." to ".. newAura.stacks)
								end
								--Plus de stacks, on supprime l'aura
								if newAura.stacks<=0 then
									Ovale:Log("Aura is completly removed")
									newAura.stacks = 0
									newAura.ending = 0
								end
							end
						elseif newAura.ending and newAura.ending >= endCast then
							newAura.ending = endCast + duration
							newAura.stacks = newAura.stacks + stacks
						else
							newAura.start = endCast
							newAura.ending = endCast + duration
							newAura.stacks = stacks
						end
						if Ovale.trace then
							if auraSpellId then
								Ovale:Print(spellId.." adding "..stacks.." aura "..auraSpellId.." to "..target.." "..filter.." "..newAura.start..","..newAura.ending)
							else
								Ovale:Print("adding nil aura")
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

function OvaleState:GetAura(target, spellId, mine)
	local guid = UnitGUID(target)
	
	if self.aura[guid] and self.aura[guid][spellId] and self.aura[guid][spellId].serial == self.serial then
		return self.aura[guid][spellId]
	else
		return OvaleAura:GetAuraByGUID(guid, spellId, mine, target)
	end
end

function OvaleState:GetExpirationTimeOnAnyTarget(spellId)
	local starting, ending = OvaleAura:GetExpirationTimeOnAnyTarget(spellId)
	for unitId,auraTable in pairs(self.aura) do
		local aura = auraTable[spellId]
		if aura and aura.serial == self.serial then
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
	return starting, ending
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
--</public-static-methods>
