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
local OvaleState = Ovale:NewModule("OvaleState")
Ovale.OvaleState = OvaleState

--<private-static-properties>
local OvaleAura = Ovale.OvaleAura
local OvaleComboPoints = Ovale.OvaleComboPoints
local OvaleData = Ovale.OvaleData
local OvaleFuture = Ovale.OvaleFuture
local OvaleGUID = Ovale.OvaleGUID
local OvalePaperDoll = Ovale.OvalePaperDoll
local OvalePower = Ovale.OvalePower
local OvaleSpellBook = Ovale.OvaleSpellBook
local OvaleStance = Ovale.OvaleStance

local floor = math.floor
local pairs = pairs
local select = select
local tostring = tostring
local type = type
local wipe = table.wipe
local API_GetEclipseDirection = GetEclipseDirection
local API_GetRuneCooldown = GetRuneCooldown
local API_GetRuneType = GetRuneType
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local API_UnitHealth = UnitHealth
local API_UnitHealthMax = UnitHealthMax
local MAX_COMBO_POINTS = MAX_COMBO_POINTS

local self_runes = {}
local self_runesCD = {}

-- Aura IDs for Eclipse buffs.
local LUNAR_ECLIPSE = 48518
local SOLAR_ECLIPSE = 48517
-- Spell ID for Starfall (Balance specialization spell).
local STARFALL = 48505
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
local function ApplySpell(spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
	local self = OvaleState
	self:ApplySpell(spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
end

-- Track a new Eclipse buff that starts at timestamp.
local function AddEclipse(timestamp, spellId)
	local self = OvaleState
	local newAura = self:NewAura(OvaleGUID:GetGUID("player"), spellId, "HELPFUL")
	newAura.start = timestamp
	newAura.ending = nil
	newAura.stacks = 1
end
--</private-static-methods>

--<public-static-methods>
function OvaleState:StartNewFrame()
	self.maintenant = API_GetTime()
	self.gcd = self:GetGCD()
end

function OvaleState:UpdatePowerRates()
	for powerType in pairs(OvalePower.POWER_INFO) do
		self.powerRate[powerType] = 0
	end
	-- Power regeneration for current power type.
	if Ovale.enCombat then
		self.powerRate[OvalePower.powerType] = OvalePower.activeRegen
	else
		self.powerRate[OvalePower.powerType] = OvalePower.inactiveRegen
	end
end

function OvaleState:Reset()
	self.lastSpellId = Ovale.lastSpellcast and Ovale.lastSpellcast.spellId
	self.serial = self.serial + 1
	self.currentTime = self.maintenant
	Ovale:Logf("Reset state with current time = %f", self.currentTime)
	self.currentSpellId = nil
	self.attenteFinCast = self.maintenant

	-- Snapshot the current power and regeneration rates.
	self.state.combo = OvaleComboPoints.combo
	for powerType in pairs(OvalePower.POWER_INFO) do
		self.state[powerType] = OvalePower.power[powerType]
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

--[[
	Cast a spell in the simulator and advance the state of the simulator.

	Parameters:
		spellId		The ID of the spell to cast.
		startCast	The time at the start of the spellcast.
		endCast		The time at the end of the spellcast.
		nextCast	The earliest time at which the next spell can be cast (nextCast >= endCast).
		nocd		The spell's cooldown is not triggered.
		targetGUID	The GUID of the target of the spellcast.
		spellcast	(optional) Table of spellcast information, including a snapshot of player's stats.
--]]
function OvaleState:ApplySpell(spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
	if not spellId or not targetGUID then
		return
	end

	-- Update the latest spell cast in the simulator.
	self.attenteFinCast = nextCast
	self.currentSpellId = spellId
	self.startCast = startCast
	self.endCast = endCast

	self.lastSpellId = spellId

	-- Set the current time in the simulator to a little after the start of the current cast,
	-- or to now if in the past.
	if startCast >= self.maintenant then
		self.currentTime = startCast + 0.1
	else
		self.currentTime = self.maintenant
	end

	Ovale:Logf("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, self.currentTime, self.attenteFinCast, endCast, targetGUID)

	--[[
		Apply the effects of the spellcast in three phases.
			1. Spell effects at the beginning of the cast.
			2. Spell effects on player assuming the cast completes.
			3. Spell effects on target when it lands.
	--]]
	self:ApplySpellStart(spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
	self:ApplySpellOnPlayer(spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
	self:ApplySpellOnTarget(spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
end

-- Apply the effects of the spell at the start of the spellcast.
function OvaleState:ApplySpellStart(spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
	local si = OvaleData.spellInfo[spellId]
	--[[
		If the spellcast has already started, then the effects have already occurred,
		so only consider spells that are cast in the future in the simulator.
	--]]
	if startCast >= self.maintenant then
		if si then
			-- Increment and reset spell counters.
			if si.inccounter then
				local id = si.inccounter
				local value = self.state.counter[id] and self.state.counter[id] or 0
				self.state.counter[id] = value + 1
			end
			if si.resetcounter then
				local id = si.resetcounter
				self.state.counter[id] = 0
			end
		end
	end
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleState:ApplySpellOnPlayer(spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
	local si = OvaleData.spellInfo[spellId]
	--[[
		If the spellcast has already ended, then the effects have already occurred,
		so only consider spells that have not yet finished casting in the simulator.
	--]]
	if endCast > self.maintenant then
		-- Adjust the spell's cooldown.
		self:ApplySpellCooldown(spellId, startCast, endCast, nocd)

		-- Adjust the player's resources.
		self:ApplySpellCost(spellId, startCast, endCast)

		-- Apply the auras on the player.
		if si and si.aura and si.aura.player then
			self:ApplySpellAuras(spellId, startCast, endCast, OvaleGUID:GetGUID("player"), si.aura.player, spellcast)
		end
	end
end

-- Apply the effects of the spell on the target's state when it lands on the target.
function OvaleState:ApplySpellOnTarget(spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
	local si = OvaleData.spellInfo[spellId]
	if si and si.aura and si.aura.target then
		-- Apply the auras on the target.
		self:ApplySpellAuras(spellId, startCast, endCast, targetGUID, si.aura.target, spellcast)
	end
end

-- Adjust a spell cooldown in the simulator.
function OvaleState:ApplySpellCooldown(spellId, startCast, endCast, nocd)
	local si = OvaleData.spellInfo[spellId]
	if si then
		local cd = self:GetCD(spellId)
		if cd then
			cd.start = startCast
			cd.duration = si.cd or 0

			-- Test for no cooldown.
			if nocd then
				cd.duration = 0
			else
				-- There is no cooldown if the buff named by "buffnocd" parameter is present.
				if si.buffnocd then
					local start, ending, stacks = self:GetAura("player", si.buffnocd)
					if start and stacks and stacks > 0 then
						Ovale:Logf("buffnocd stacks = %s, start = %s, ending = %s, startCast = %f", stacks, start, ending, startCast)
						-- XXX Shouldn't this be (not ending or ending > endCast)?
						-- XXX The spellcast needs to finish before the buff expires.
						if start <= startCast and (not ending or ending > startCast) then
							cd.duration = 0
						end
					end
				end

				-- There is no cooldown if the target's health percent is below what's specified
				-- with the "targetlifenocd" parameter.
				if si.targetlifenocd then
					local healthPercent = API_UnitHealth("target") / API_UnitHealthMax("target") * 100
					if healthPercent < si.targetlifenocd then
						cd.duration = 0
					end
				end
			end

			-- Adjust cooldown duration if it is affected by haste: "cd_haste=melee" or "cd_haste=spell".
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
			Ovale:Logf("Spell %d cooldown info: start=%f, duration=%f", spellId, cd.start, cd.duration)
		end
	end
end

-- Adjust the player's resources in the simulator from casting the given spell.
function OvaleState:ApplySpellCost(spellId, startCast, endCast)
	local si = OvaleData.spellInfo[spellId]
	local _, _, _, cost, _, powerType = API_GetSpellInfo(spellId)

	-- Update power using information from GetSpellInfo() if there is no user-defined SpellInfo() for the spell's cost.
	if cost and powerType then
		powerType = OvalePower.POWER_TYPE[powerType]
		if not si or not si[powerType] then
			self.state[powerType] = self.state[powerType] - cost
		end
	end

	if si then
		-- Update power state, except for combo points, eclipse energy, and runes.
		for powerType, powerInfo in pairs(OvalePower.POWER_INFO) do
			if powerType ~= "eclipse" then
				local cost = si[powerType]
				if cost then
					--[[
						cost > 0 means that the spell costs resources.
						cost < 0 means that the spell generates resources.
						cost == 0 means that the spell uses all of the resources (zeroes it out).
					--]]
					if cost == 0 then
						self.state[powerType] = 0
					else
						self.state[powerType] = self.state[powerType] - cost
					end
					--[[
						Add extra resource generated by presence of a buff.
						"buff_<powerType>" is the spell ID of the buff that causes extra resources to be generated or used.
						"buff_<powerType>_amount" is the amount of extra resources generated or used, defaulting to -1
							(one extra resource generated).
					--]]
					local buffParam = "buff_" .. tostring(powerType)
					local buffAmoumtParam = buffParam .. "_amount"
					if si[buffParam] and self:GetAura("player", si[buffParam], nil, true) then
						local buffAmount = si[buffAmountParam] or -1
						self.state[powerType] = self.state[powerType] - buffAmount
					end
					-- Clamp self.state[powerType] to lower and upper limits.
					local mini = powerInfo.mini or 0
					local maxi = powerInfo.maxi or OvalePower.maxPower[powerType]
					if mini and self.state[powerType] < mini then
						self.state[powerType] = mini
					end
					if maxi and self.state[powerType] > maxi then
						self.state[powerType] = maxi
					end
				end
			end
		end

		--[[
			Combo points: This resource is handled specially because it has different semantics
			from other resources. In particular, it's a resource that's attached to the target
			and not to the player.
		--]]
		if si.combo then
			local combo = si.combo
			--[[
				Combo points have the opposite meaning from other resources:

				combo > 0 means that the spell generates resources.
				combo < 0 means that the spell costs resources.
				combo == 0 means that the spell uses all of the combo points.
			--]]
			if combo == 0 then
				self.state.combo = 0
			else
				self.state.combo = self.state.combo + combo
			end
			--[[
				Add extra combo points generated by presence of a buff.
				"buff_combo" is the spell ID of the buff that causes extra points to be generated or used.
				"buff_combo_amount" is the number of extra points generated or used, defaulting to 1
					(one extra resource generated).
			--]]
			if si.buff_combo and self:GetAura("player", si.buff_combo, nil, true) then
				local buffAmount = si.buff_combo_amount or 1
				self.state.combo = self.state.combo + buffAmount
			end
			-- Clamp self.state.combo to lower and upper limits.
			if self.state.combo < 0 then
				self.state.combo = 0
			end
			if self.state.combo > MAX_COMBO_POINTS then
				self.state.combo = MAX_COMBO_POINTS
			end
		end

		-- Eclipse
		if si.eclipse then
			local energy = si.eclipse
			local direction = self:GetEclipseDir()
			if si.eclipsedir then
				energy = energy * direction
			end
			-- Euphoria: While not in an Eclipse state, your spells generate double the normal amount of Solar or Lunar energy.
			if OvaleSpellBook:IsKnownSpell(81062)
					and not self:GetAura("player", LUNAR_ECLIPSE, "HELPFUL", true)
					and not self:GetAura("player", SOLAR_ECLIPSE, "HELPFUL", true) then
				energy = energy * 2
			end
			-- Only adjust Eclipse energy if the spell moves the Eclipse bar in the right direction.
			if (direction < 0 and energy < 0) or (direction > 0 and energy > 0) then
				self.state.eclipse = self.state.eclipse + energy
			end
			-- Clamp Eclipse energy to min/max values and note that an Eclipse state will be reached after the spellcast.
			if self.state.eclipse <= -100 then
				self.state.eclipse = -100
				AddEclipse(endCast, LUNAR_ECLIPSE)
				-- Reaching Lunar Eclipse resets the cooldown of Starfall.
				local cd = self:GetCD(STARFALL)
				if cd then
					cd.start = 0
					cd.duration = 0
					cd.enable = 0
				end
			elseif self.state.eclipse >= 100 then
				self.state.eclipse = 100
				AddEclipse(endCast, SOLAR_ECLIPSE)
			end
		end

		-- Runes
		if si.blood and si.blood < 0 then
			self:AddRune(startCast, 1, si.blood)
		end
		if si.unholy and si.unholy < 0 then
			self:AddRune(startCast, 2, si.unholy)
		end
		if si.frost and si.frost < 0 then
			self:AddRune(startCast, 3, si.frost)
		end
		if si.death and si.death < 0 then
			self:AddRune(startCast, 4, si.death)
		end
	end
end

-- XXX The way this function updates the rune state looks completely wrong.
function OvaleState:AddRune(atTime, runeType, value)
	for i = 1, 6 do
		local rune = self.state.rune[i]
		if (rune.type == runeType or rune.type == 4) and rune.cd <= atTime then
			rune.cd = atTime + 10
		end
	end
end

-- Apply the auras caused by the given spell in the simulator.
function OvaleState:ApplySpellAuras(spellId, startCast, endCast, guid, auraList, spellcast)
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
				duration = self:GetDuration(auraId)
			end

			local start, ending, currentStacks, tick = self:GetAuraByGUID(guid, auraId, filter, true, target)
			local newAura = self:NewAura(guid, auraId, filter)
			newAura.mine = true

			--[[
				auraId=N, N > 0		N is duration, auraID is applied, add one stack
				auraId=0			aura is removed
				auraId=N, N < 0		N is number of stacks of aura removed
				auraId=refresh		auraId is refreshed, no change to stacks
			--]]
			if type(stacks) == "number" and stacks == 0 then
				Ovale:Logf("Aura %d is completely removed", auraId)
				newAura.stacks = 0
				newAura.start = start
				newAura.ending = endCast
			elseif ending and endCast <= ending then
				-- Spellcast ends before the aura expires.
				if stacks == "refresh" or stacks > 0 then
					if stacks == "refresh" then
						Ovale:Logf("Aura %d is refreshed", auraId)
						newAura.stacks = currentStacks
					else -- if stacks > 0 then
						newAura.stacks = currentStacks + stacks
						Ovale:Logf("Aura %d gains a stack to %d because of spell %d (ending was %s)", auraId, newAura.stacks, spellId, ending)
					end
					newAura.start = start
					if isDoT and ending > newAura.start and tick and tick > 0 then
						-- Add new duration after the next tick is complete.
						local remainingTicks = floor((ending - endCast) / tick)
						newAura.ending = (ending - tick * remainingTicks) + duration
						newAura.tick = OvaleAura:GetTickLength(auraId)
						-- Re-snapshot stats for the DoT.
						-- XXX This is not quite right because it uses the current player stats instead of the simulator's state.
						OvalePaperDoll:SnapshotStats(newAura, spellcast)
						newAura.damageMultiplier = self:GetDamageMultiplier(auraId)
					else
						newAura.ending = endCast + duration
					end
					Ovale:Logf("Aura %d ending is now %f", auraId, newAura.ending)
				elseif stacks < 0 then
					newAura.stacks = currentStacks + stacks
					newAura.start = start
					newAura.ending = ending
					Ovale:Logf("Aura %d loses %d stack(s) to %d because of spell %d", auraId, -1 * stacks, newAura.stacks, spellId)
					if newAura.stacks <= 0 then
						Ovale:Logf("Aura %d is completely removed", auraId)
						newAura.stacks = 0
						newAura.ending = endCast
					end
				end
			elseif type(stacks) == "number" and type(duration) == "number" and stacks > 0 and duration > 0 then
				Ovale:Logf("New aura %d at %f on %s", auraId, endCast, guid)
				newAura.stacks = stacks
				newAura.start = endCast
				newAura.ending = endCast + duration
				if isDoT then
					newAura.tick = OvaleAura:GetTickLength(auraId)
					-- Snapshot stats for the DoT.
					-- XXX This is not quite right because it uses the current player stats instead of the simulator's state.
					OvalePaperDoll:SnapshotStats(newAura, spellcast)
					newAura.damageMultiplier = self:GetDamageMultiplier(auraId)
				end
			end
		end
	end
end

-- Return the GCD after the given spellId is cast.
-- If no spellId is given, then returns the GCD after a "yellow-hit" ability has been cast.
function OvaleState:GetGCD(spellId)
	-- Use SpellInfo() information if available.
	if spellId and OvaleData.spellInfo[spellId] then
		local si = OvaleData.spellInfo[spellId]
		if si.haste then
			local cd = si.gcd or 1.5
			if si.haste == "melee" then
				cd = cd / OvalePaperDoll:GetMeleeHasteMultiplier()
			elseif si.haste == "spell" then
				cd = cd / OvalePaperDoll:GetSpellHasteMultiplier()
			end
			if cd < 1 then
				cd = 1
			end
			return cd
		elseif si.gcd then
			return si.gcd
		end
	end

	-- Default value.
	local class = OvalePaperDoll.class
	local isCaster = false
	if class == "DRUID" and not (OvaleStance:IsStance("druid_bear_form") or OvaleStance:IsStance("druid_cat_form")) then
		isCaster = true
	elseif class == "MAGE" then
		isCaster = true
	elseif class == "PRIEST" then
		isCaster = true
	elseif class == "SHAMAN" then
		isCaster = true
	elseif class == "WARLOCK" then
		isCaster = true
	end
	if isCaster then
		local cd = 1.5 / OvalePaperDoll:GetSpellHasteMultiplier()
		if cd < 1 then
			cd = 1
		end
		return cd
	elseif class == "DEATHKNIGHT" then
		return 1.0
	elseif class == "DRUID" and OvaleStance:IsStance("druid_cat_form") then
		return 1.0
	elseif class == "MONK" then
		return 1.0
	elseif class == "ROGUE" then
		return 1.0
	else
		return 1.5
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

do
	local aura = {}
	local newAura = {}

	function OvaleState:GetAura(unitId, spellId, filter, mine, auraFound)
		local guid = OvaleGUID:GetGUID(unitId)
		if OvaleData.buffSpellList[spellId] then
			if auraFound then wipe(newAura) end
			local newStart, newEnding, newStacks, newGain
			for auraId in pairs(OvaleData.buffSpellList[spellId]) do
				if auraFound then wipe(aura) end
				local start, ending, stacks, gain = self:GetAuraByGUID(guid, auraId, filter, mine, unitId, aura)
				if start and (not newStart or stacks > newStacks) then
					newStart = start
					newEnding = ending
					newStacks = stacks
					newGain = gain
					if auraFound then
						wipe(newAura)
						for k, v in pairs(aura) do
							newAura[k] = v
						end
					end
				end
			end
			if auraFound then
				for k, v in pairs(newAura) do
					auraFound[k] = v
				end
			end
			return newStart, newEnding, newStacks, newGain
		else
			return self:GetAuraByGUID(guid, spellId, filter, mine, unitId, auraFound)
		end
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
						local auraSpellInfo = OvaleData.spellInfo[auraSpellId]
						if auraSpellInfo.stacking and auraSpellInfo.stacking > 0 then
							multiplier = 1 + (multiplier - 1) * count
						end
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

-- Returns the duration, tick length, and number of ticks of an aura.
function OvaleState:GetDuration(auraSpellId)
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
		local duration = si.duration
		local combo = self.state.combo or 0
		local holy = self.state.holy or 1
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

-- Print out the levels of each power type in the current state.
function OvaleState:DebugPower()
	for powerType in pairs(OvalePower.POWER_INFO) do
		Ovale:FormatPrint("%s = %d", powerType, self.state[powerType])
	end
end
--</public-static-methods>
