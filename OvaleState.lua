--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- Keep the current state in the simulation

local _, Ovale = ...
OvaleState = {}
Ovale.OvaleState = OvaleState

--<private-static-properties>
local OvaleAura = Ovale.OvaleAura
local OvaleComboPoints = Ovale.OvaleComboPoints
local OvaleData = Ovale.OvaleData
local OvaleEquipement = Ovale.OvaleEquipement
local OvaleFuture = Ovale.OvaleFuture
local OvaleGUID = Ovale.OvaleGUID
local OvalePaperDoll = Ovale.OvalePaperDoll
local OvaleStance = Ovale.OvaleStance

local floor = math.floor
local pairs = pairs
local select = select
local tostring = tostring
local wipe = table.wipe
local API_GetEclipseDirection = GetEclipseDirection
local API_GetRuneCooldown = GetRuneCooldown
local API_GetRuneType = GetRuneType
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local API_UnitHealth = UnitHealth
local API_UnitHealthMax = UnitHealthMax
local API_UnitPower = UnitPower
local API_UnitPowerMax = UnitPowerMax
local MAX_COMBO_POINTS = MAX_COMBO_POINTS

local self_runes = {}
local self_runesCD = {}

-- Static properties used by "GetAura" method.
local aura_GetAura = {}
local newAura_GetAura = {}

-- Aura IDs for Eclipse buffs.
local LUNAR_ECLIPSE = 48518
local SOLAR_ECLIPSE = 48517
--</private-static-properties>

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
OvaleState.maintenant = nil
OvaleState.currentTime = nil
OvaleState.attenteFinCast = nil
OvaleState.startCast = nil
OvaleState.endCast = nil
OvaleState.gcd = 1.5
OvaleState.powerRate = {}
OvaleState.lastSpellId = nil
--</public-static-properties>

--<private-static-methods>
local function ApplySpell(spellId, startCast, endCast, nextCast, nocd, targetGUID, stats)
	local self = OvaleState
	self:ApplySpell(spellId, startCast, endCast, nextCast, nocd, targetGUID, stats)
end

-- Track a new Eclipse buff that starts at endCast.
local function AddEclipse(endCast, spellId)
	local self = OvaleState
	local newAura = self:NewAura(OvaleGUID:GetGUID("player"), spellId, "HELPFUL")
	newAura.start = endCast
	newAura.ending = nil
	newAura.stacks = 1
end
--</private-static-methods>

--<public-static-methods>
function OvaleState:StartNewFrame()
	self.maintenant = API_GetTime()
	self.gcd = OvaleData:GetGCD()
end

function OvaleState:UpdatePowerRates()
	for k,v in pairs(OvaleData.power) do
		self.powerRate[k] = 0
	end

	-- Energy regeneration for druids and monks out of DPS stance.
	local class = OvalePaperDoll.class
	if class == "DRUID" or class == "MONK" then
		-- Base energy regen is 10 energy per second, scaled by the melee haste.
		local energyRegen = 10 * OvalePaperDoll:GetMeleeHasteMultiplier()
		-- Strip off 10% attack speed bonus that doesn't count toward energy regeneration.
		if OvaleState:GetAura("player", "melee_haste") then
			energyRegen = energyRegen / 1.1
		end
		if class == "MONK" then
			-- Way of the Monk (monk): melee attack speed increased by 40% for two-handed weapons.
			if OvaleEquipement:HasTwoHandedWeapon() then
				energyRegen = energyRegen / 1.4
			end
			-- Ascension (monk): increases energy regen by 15%.
			if OvaleData:GetTalentPoints(8) > 0 then
				energyRegen = energyRegen * 1.15
			end
			-- Stance of the Sturdy Ox (brewmaster monk): increases Energy regeneration by 10%.
			if OvaleStance:IsStance("monk_stance_of_the_sturdy_ox") then
				energyRegen = energyRegen * 1.1
			end
		end
		self.powerRate.energy = energyRegen
	end
	-- TODO: mana regen for classes that that use mana based on stance.

	-- Power regeneration for current power type.
	if Ovale.enCombat then
		self.powerRate[OvaleData.powerType[OvalePaperDoll.powerType]] = OvalePaperDoll.activeRegen
	else
		self.powerRate[OvaleData.powerType[OvalePaperDoll.powerType]] = OvalePaperDoll.inactiveRegen
	end
end

function OvaleState:Reset()
	self.lastSpellId = Ovale.lastSpellcast and Ovale.lastSpellcast.spellId
	self.serial = self.serial + 1
	self.currentTime = self.maintenant
	Ovale:Logf("Reset state with current time = %f", self.currentTime)
	self.currentSpellId = nil
	self.attenteFinCast = self.maintenant
	self.state.combo = OvaleComboPoints.combo
	for k,v in pairs(OvaleData.power) do
		self.state[k] = API_UnitPower("player", v.id, v.segments)
	end
	
	self:UpdatePowerRates()
	
	if OvalePaperDoll.class == "DEATHKNIGHT" then
		for i=1,6 do
			self.state.rune[i].type = API_GetRuneType(i)
			local start, duration, runeReady = API_GetRuneCooldown(i)
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

-- Apply the effects of spells that are being cast or are in flight, allowing us to
-- ignore lag or missile travel time.
function OvaleState:ApplyActiveSpells()
	OvaleFuture:ApplyInFlightSpells(self.maintenant, ApplySpell)
end

-- Cast a spell in the simulator
-- spellId : the spell id
-- startCast : temps du cast
-- endCast : fin du cast
-- nextCast : temps auquel le prochain sort peut être lancé (>=endCast, avec le GCD)
-- nocd : le sort ne déclenche pas son cooldown
-- spellcast : snapshot of player stats at the time the spell was cast
function OvaleState:ApplySpell(spellId, startCast, endCast, nextCast, nocd, targetGUID, stats)
	if not spellId or not targetGUID then
		return
	end
	
	local si = OvaleData.spellInfo[spellId]
	
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
	
	Ovale:Logf("add spell %d at %f currentTime = %f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, self.currentTime, self.attenteFinCast, endCast, targetGUID)
	
	--Effet du sort au moment du début du cast
	--(donc si cast déjà commencé, on n'en tient pas compte)
	if startCast >= self.maintenant then
		if si then
			if si.inccounter then
				local id = si.inccounter
				self.state.counter[id] = self:GetCounterValue(id) + 1
			end
			
			if si.resetcounter then
				self.state.counter[si.resetcounter] = 0
			end
		end
	end
	
	--Effet du sort au moment où il est lancé
	--(donc si il est déjà lancé, on n'en tient pas compte)
	if endCast >= self.maintenant then
		--Mana
		local _, _, _, cost, _, powerType = API_GetSpellInfo(spellId)
		local power = OvaleData.powerType[powerType]
		if cost and power and (not si or not si[power]) then
			self.state[power] = self.state[power] - cost
		end

		if si then
			-- Update power state, except for eclipse, combo, and runes.
			for k,v in pairs(OvaleData.power) do
				if si[k] and k ~= "eclipse" then
					if si[k] == 0 then
						self.state[k] = 0
					else
						self.state[k] = self.state[k] - si[k]
					end
					-- Add extra resource generated by presence of a buff.
					local buffParam = "buff_" .. tostring(k)
					local buffAmoumtParam = buffParam .. "_amount"
					if si[k] < 0 and si[buffParam] and self:GetAura("player", si[buffParam], nil, true) then
						local buffAmount = si[buffAmountParam] or 1
						self.state[k] = self.state[k] + buffAmount
					end
					if self.state[k] < v.mini then
						self.state[k] = v.mini
					end
					if v.maxi and self.state[k] > v.maxi then
						self.state[k] = v.maxi
					else
						local maxi = API_UnitPowerMax("player", v.id, v.segments)
						if maxi and self.state[k] > maxi then
							self.state[k] = maxi
						end
					end
				end
			end

			-- Eclipse
			if si.eclipse then
				local energy = si.eclipse
				local direction = self:GetEclipseDir()
				if si.eclipsedir then
					energy = energy * direction
				end
				-- Eclipse energy generated is doubled if not in an Eclipse state with Euphoria.
				if OvaleData.spellList[81062]
						and not self:GetAura("player", LUNAR_ECLIPSE, "HELPFUL", true)
						and not self:GetAura("player", SOLAR_ECLIPSE, "HELPFUL", true) then
					energy = energy * 2
				end
				-- Only adjust Eclipse energy if the spell moves the Eclipse bar in the right direction.
				if (direction < 0 and energy < 0) or (direction > 0 and energy > 0) then
					self.state.eclipse = self.state.eclipse + energy
				end
				-- Clamp Eclipse energy to min/max values and note that an Eclipse state will be reached.
				if self.state.eclipse <= -100 then
					self.state.eclipse = -100
					AddEclipse(endCast, LUNAR_ECLIPSE)
				elseif self.state.eclipse >= 100 then
					self.state.eclipse = 100
					AddEclipse(endCast, SOLAR_ECLIPSE)
				end
			end

			-- Combo points
			if si.combo then
				if si.combo == 0 then
					self.state.combo = 0
				elseif si.combo > 0 then
					self.state.combo = self.state.combo + si.combo
					-- Add extra combo points generated by presence of a buff.
					if si.buff_combo and self:GetAura("player", si.buff_combo, nil, true) then
						local buffAmount = si.buff_combo_amount or 1
						self.state.combo = self.state.combo + buffAmount
					end
					if self.state.combo > MAX_COMBO_POINTS then
						self.state.combo = MAX_COMBO_POINTS
					end
				else -- si.combo < 0
					self.state.combo = self.state.combo + si.combo
					if self.state.combo < 0 then
						self.state.combo = 0
					end
				end
			end

			--Runes
			if si.frost then
				self:AddRune(startCast, 3, si.frost)
			end
			if si.death then
				self:AddRune(startCast, 4, si.death)
			end
			if si.blood then
				self:AddRune(startCast, 1, si.blood)
			end
			if si.unholy then
				self:AddRune(startCast, 2, si.unholy)
			end
		end
	end
	
	-- Effets du sort au moment où il atteint sa cible
	if si then
		-- Cooldown du sort
		local cd = self:GetCD(spellId)
		if cd then
			cd.start = startCast
			cd.duration = si.cd
			--Pas de cooldown
			if nocd then
				cd.duration = 0
			else
				--On vérifie si le buff "buffnocd" est présent, auquel cas le CD du sort n'est pas déclenché
				if si.buffnocd then
					local buffStart, buffEnding, buffStacks = self:GetAura("player", si.buffnocd)
					if buffStart then
						Ovale:Logf("buffnocd stacks = %s, start = %s, ending = %s, startCast = %f", buffStacks, buffStart, buffEnding, startCast)
					end
					if buffStacks and buffStacks > 0 and buffStart and buffStart <= startCast and (not buffEnding or buffEnding > startCast) then
						cd.duration = 0
					end
				end
				if si.targetlifenocd then
					--TODO
					if API_UnitHealth("target") / API_UnitHealthMax("target") * 100 < si.targetlifenocd then
						cd.duration = 0
					end
				end
			end
			if cd.duration > 0 and si.cd_haste then
				if si.cd_haste == "melee" then
					cd.duration = cd.duration / OvalePaperDoll:GetMeleeHasteMultiplier()
				elseif si.cd_haste == "spell" then
					cd.duration = cd.duration / OvalePaperDoll:GetSpellHasteMultiplier()
				end
			end
			cd.enable = 1
			if si.toggle then
				cd.toggled = 1
			end
			Ovale:Logf("%d cd.start=%f, cd.duration=%f", spellId, cd.start, cd.duration)
		end

		--Auras causés par le sort
		if si.aura then
			for target, targetInfo in pairs(si.aura) do
				if not (target == "player" and endCast <= self.maintenant) then
					-- If the spell has already finished casting, then player auras match the game
					-- state already, so no need to account for traveling spells.  Update auras
					-- affected by the spell in all other cases.
					for filter, filterInfo in pairs(targetInfo) do
						for auraSpellId, spellData in pairs(filterInfo) do

							local auraSpellInfo = OvaleData.spellInfo[auraSpellId]
							-- An aura is treated as a periodic aura if it sets "tick" explicitly in SpellInfo.
							local isDoT = auraSpellInfo and auraSpellInfo.tick
							local duration = spellData
							local stacks = duration
							local auraGUID
							if target == "target" then
								auraGUID = targetGUID
							else
								auraGUID = OvaleGUID:GetGUID(target)
							end

							-- Set the duration to the proper length if it's a DoT.
							if auraSpellInfo and auraSpellInfo.duration then
								duration = OvaleData:GetDuration(auraSpellId, self.state.combo, self.state.holy)
							end

							-- If aura is specified with a duration, then assume stacks == 1.
							if type(stacks) == "number" and stacks > 0 then
								stacks = 1
							end

							local oldStart, oldEnding, oldStacks, oldTick = self:GetAuraByGUID(auraGUID, auraSpellId, filter, true, target)
							local newAura = self:NewAura(auraGUID, auraSpellId, filter)

							newAura.mine = true

							if type(stacks) == "number" and stacks == 0 then
								Ovale:Logf("Aura %d is completely removed", auraSpellId)
								newAura.stacks = 0
								newAura.ending = 0	-- self.currentTime?
							elseif oldEnding and oldEnding >= endCast then
								if stacks == "refresh" or stacks > 0 then
									if stacks == "refresh" then
										Ovale:Logf("Aura %d is refreshed", auraSpellId)
										newAura.stacks = oldStacks
									else -- if stacks > 0
										Ovale:Logf("Aura %d gains stacks (ending was %s)", auraSpellId, newAura.ending)
										newAura.stacks = oldStacks + stacks
									end
									newAura.start = oldStart
									if isDoT and oldEnding > newAura.start and oldTick and oldTick > 0 then
										-- Add new duration after the next tick is complete.
										local remainingTicks = floor((oldEnding - endCast) / oldTick)
										newAura.ending = (oldEnding - oldTick * remainingTicks) + duration
										newAura.tick = OvaleData:GetTickLength(auraSpellId)
										-- Re-snapshot stats for the DoT.
										OvalePaperDoll:SnapshotStats(newAura, stats)
										newAura.damageMultiplier = self:GetDamageMultiplier(auraSpellId)
									else
										newAura.ending = endCast + duration
									end
									Ovale:Logf("Aura %d ending is now %f", auraSpellId, newAura.ending)
								elseif stacks < 0 then
									Ovale:Logf("Aura %d loses stacks", auraSpellId)
									newAura.stacks = oldStacks + stacks
									Ovale:Logf("removing %d stack(s) of %d because of %d to %d", stacks, auraSpellId, spellId, newAura.stacks)
									newAura.start = oldStart
									newAura.ending = oldEnding
									if newAura.stacks <= 0 then
										Ovale:Log("Aura is completely removed")
										newAura.stacks = 0
										newAura.ending = 0	-- self.currentTime?
									end
								end
							elseif type(stacks) == "number" and type(duration) == "number" then
								Ovale:Logf("New aura %d at %f on %s %s", auraSpellId, endCast, target, auraGUID)
								newAura.stacks = stacks
								newAura.start = endCast
								newAura.ending = endCast + duration
								if isDoT then
									newAura.tick = OvaleData:GetTickLength(auraSpellId)
									OvalePaperDoll:SnapshotStats(newAura, stats)
									newAura.damageMultiplier = self:GetDamageMultiplier(auraSpellId)
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
	local si = OvaleData.spellInfo[spellId]
	if si and si.cd then
		local cdname
		if si.sharedcd then
			cdname = si.sharedcd
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

--Compute the spell Cooldown
function OvaleState:GetComputedSpellCD(spellId)
	local actionCooldownStart, actionCooldownDuration, actionEnable
	local cd = self:GetCD(spellId)
	if cd and cd.start then
		actionCooldownStart = cd.start
		actionCooldownDuration = cd.duration
		actionEnable = cd.enable
	else
		actionCooldownStart, actionCooldownDuration, actionEnable = OvaleData:GetSpellCD(spellId)
	end
	return actionCooldownStart, actionCooldownDuration, actionEnable
end

function OvaleState:GetAuraByGUID(guid, spellId, filter, mine, unitId, auraFound)
	local aura
	if mine then
		local auraTable = self.aura[guid]
		if auraTable then
			if filter then
				local auraList = auraTable[filter]
				if auraList then
					if auraList[spellId] and auraList[spellId].serial == self.serial then
						aura = auraList[spellId]
					end
				end
			else
				for auraFilter, auraList in pairs(auraTable) do
					if auraList[spellId] and auraList[spellId].serial == self.serial then
						aura = auraList[spellId]
						filter = auraFilter
						break
					end
				end
			end
		end
	end
	if aura then
		if aura.stacks > 0 then
			Ovale:Logf("Found %s aura %s on %s", filter, spellId, guid)
		else
			Ovale:Logf("Found %s aura %s on %s (removed)", filter, spellId, guid)
		end
		if auraFound then
			for k, v in pairs(aura) do
				auraFound[k] = v
			end
		end
		return aura.start, aura.ending, aura.stacks, aura.gain
	else
		Ovale:Logf("Aura %s not found in state for %s", spellId, guid)
		return OvaleAura:GetAuraByGUID(guid, spellId, filter, mine, unitId, auraFound)
	end
end

function OvaleState:GetAura(unitId, spellId, filter, mine, auraFound)
	local guid = OvaleGUID:GetGUID(unitId)
	if OvaleData.buffSpellList[spellId] then
		if auraFound then wipe(newAura_GetAura) end
		local newStart, newEnding, newStacks, newGain
		for auraId in pairs(OvaleData.buffSpellList[spellId]) do
			if auraFound then wipe(aura_GetAura) end
			local start, ending, stacks, gain = self:GetAuraByGUID(guid, auraId, filter, mine, unitId, aura_GetAura)
			if start and (not newStart or stacks > newStacks) then
				newStart = start
				newEnding = ending
				newStacks = stacks
				newGain = gain
				if auraFound then
					wipe(newAura_GetAura)
					for k, v in pairs(aura_GetAura) do
						newAura_GetAura[k] = v
					end
				end
			end
		end
		if auraFound then
			for k, v in pairs(newAura_GetAura) do
				auraFound[k] = v
			end
		end
		return newStart, newEnding, newStacks, newGain
	else
		return self:GetAuraByGUID(guid, spellId, filter, mine, unitId, auraFound)
	end
end

-- Look for an aura on any target, excluding the given GUID.
-- Returns the earliest start time, the latest ending time, and the number of auras seen.
function OvaleState:GetAuraOnAnyTarget(spellId, filter, mine, excludingGUID)
	local start, ending, count = OvaleAura:GetAuraOnAnyTarget(spellId, filter, mine, excludingGUID)
	-- TODO: This is broken because it doesn't properly account for removed auras in the current frame.
	for guid, auraTable in pairs(self.aura) do
		if guid ~= excludingGUID then
			for auraFilter, auraList in pairs(auraTable) do
				if not filter or auraFilter == filter then
					local aura = auraList[spellId]
					if aura and aura.serial == self.serial then
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

function OvaleState:NewAura(guid, spellId, filter)
	if not self.aura[guid] then
		self.aura[guid] = {}
	end
	if not self.aura[guid][filter] then
		self.aura[guid][filter] = {}
	end
	if not self.aura[guid][filter][spellId] then
		self.aura[guid][filter][spellId] = {}
	end
	local aura = self.aura[guid][filter][spellId]
	aura.serial = self.serial
	aura.mine = true
	aura.gain = self.currentTime
	return aura
end

function OvaleState:GetDamageMultiplier(spellId)
	local damageMultiplier = 1
	if spellId then
		local si = OvaleData.spellInfo[spellId]
		if si and si.damageAura then
			local playerGUID = OvaleGUID:GetGUID("player")
			for filter, auraList in pairs(si.damageAura) do
				for auraSpellId, multiplier in pairs(auraList) do
					local count = select(3, self:GetAuraByGUID(playerGUID, auraSpellId, filter, nil, "player"))
					if count and count > 0 then
						-- TODO: Try to account for a stacking aura.
						-- multiplier = 1 + (multiplier - 1) * count
						damageMultiplier = damageMultiplier * multiplier
					end
				end
			end
		end
	end
	return damageMultiplier
end

-- Returns 1 if moving toward Solar or -1 if moving toward Lunar.
function OvaleState:GetEclipseDir()
	local stacks = select(3, self:GetAura("player", SOLAR_ECLIPSE, "HELPFUL", true))
	if stacks and stacks > 0 then
		return -1
	else
		stacks = select(3, self:GetAura("player", LUNAR_ECLIPSE, "HELPFUL", true))
		if stacks and stacks > 0 then
			return 1
		elseif self.state.eclipse < 0 then
			return -1
		elseif self.state.eclipse > 0 then
			return 1
		else
			local direction = API_GetEclipseDirection()
			if direction == "moon" then
				return -1
			else -- direction == "sun" then
				return 1
			end
		end
	end
end

-- Returns the cooldown time before all of the required runes are available.
function OvaleState:GetRunesCooldown(blood, frost, unholy, death, nodeath)
	local nombre = 0
	local nombreCD = 0
	local maxCD = nil
	
	for i=1,4 do
		self_runesCD[i] = 0
	end
	
	self_runes[1] = blood or 0
	self_runes[2] = frost or 0
	self_runes[3] = unholy or 0
	self_runes[4] = death or 0
		
	for i=1,6 do
		local rune = self.state.rune[i]
		if rune then
			if self_runes[rune.type] > 0 then
				self_runes[rune.type] = self_runes[rune.type] - 1
				if rune.cd > self_runesCD[rune.type] then
					self_runesCD[rune.type] = rune.cd
				end
			elseif rune.cd < self_runesCD[rune.type] then
				self_runesCD[rune.type] = rune.cd
			end
		end
	end
	
	if not nodeath then
		for i=1,6 do
			local rune = self.state.rune[i]
			if rune and rune.type == 4 then
				for j=1,3 do
					if self_runes[j]>0 then
						self_runes[j] = self_runes[j] - 1
						if rune.cd > self_runesCD[j] then
							self_runesCD[j] = rune.cd
						end
						break
					elseif rune.cd < self_runesCD[j] then
						self_runesCD[j] = rune.cd
						break
					end
				end
			end
		end
	end
	
	for i=1,4 do
		if self_runes[i]> 0 then
			return nil
		end
		if not maxCD or self_runesCD[i]>maxCD then
			maxCD = self_runesCD[i]
		end
	end
	return maxCD
end

-- Print out the levels of each power type in the current state.
function OvaleState:DebugPower()
	for powerType in pairs(OvaleData.power) do
		Ovale:FormatPrint("%s = %d", powerType, self.state[powerType])
	end
end
--</public-static-methods>
