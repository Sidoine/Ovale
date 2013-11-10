--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- Keep the current state in the simulation
-- XXX Split out Runes module.

local _, Ovale = ...
local OvaleState = Ovale:NewModule("OvaleState")
Ovale.OvaleState = OvaleState

--<private-static-properties>
local OvaleData = Ovale.OvaleData
local OvaleQueue = Ovale.OvaleQueue

local pairs = pairs
local select = select
local API_GetRuneCooldown = GetRuneCooldown
local API_GetRuneType = GetRuneType
local API_GetTime = GetTime
local API_UnitClass = UnitClass

local self_statePrototype = {}
local self_stateModules = OvaleQueue:NewQueue("OvaleState_stateModules")

local self_runes = {}
local self_runesCD = {}

-- Player's class.
local self_class = select(2, API_UnitClass("player"))
-- Whether the state of the simulator has been initialized.
local self_stateIsInitialized = false
--</private-static-properties>

--<public-static-properties>
-- The state in the current frame
OvaleState.state = {}
-- The spell being cast
OvaleState.currentSpellId = nil
OvaleState.now = nil
OvaleState.currentTime = nil
OvaleState.nextCast = nil
OvaleState.startCast = nil
OvaleState.endCast = nil
OvaleState.lastSpellId = nil
--</public-static-properties>

--<private-static-methods>
-- XXX The way this function updates the rune state looks completely wrong.
local function AddRune(atTime, runeType, value)
	local self = OvaleState
	for i = 1, 6 do
		local rune = self.state.rune[i]
		if (rune.type == runeType or rune.type == 4) and rune.cd <= atTime then
			rune.cd = atTIme + 10
		end
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleState:RegisterState(addon, statePrototype)
	self_stateModules:Insert(addon)
	self_statePrototype[addon] = statePrototype

	-- Mix-in addon's state prototype into OvaleState.state.
	for k, v in pairs(statePrototype) do
		self.state[k] = v
	end
end

function OvaleState:UnregisterState(addon)
	stateModules = OvaleQueue:NewQueue("OvaleState_stateModules")
	while self_stateModules:Size() > 0 do
		local stateAddon = self_stateModules:Remove()
		if stateAddon ~= addon then
			stateModules:Insert(addon)
		end
	end
	self_stateModules = stateModules

	-- Remove mix-in methods from addon's state prototype.
	local statePrototype = self_statePrototype[addon]
	for k in pairs(statePrototype) do
		self.state[k] = nil
	end
	self_stateModules[addon] = nil
end

function OvaleState:InvokeMethod(methodName, ...)
	for _, addon in self_stateModules:Iterator() do
		if addon[methodName] then
			addon[methodName](addon, self.state, ...)
		end
	end
end

function OvaleState:StartNewFrame()
	if not self_stateIsInitialized then
		self:InitializeState()
	end
	self.now = API_GetTime()
end

function OvaleState:InitializeState()
	self:InvokeMethod("InitializeState")

	self.state.rune = {}
	for i = 1, 6 do
		self.state.rune[i] = {}
	end

	self_stateIsInitialized = true
end

function OvaleState:Reset()
	self.lastSpellId = Ovale.lastSpellcast and Ovale.lastSpellcast.spellId
	self.currentTime = self.now
	Ovale:Logf("Reset state with current time = %f", self.currentTime)
	self.currentSpellId = nil
	self.nextCast = self.now

	self:InvokeMethod("ResetState")

	if self_class == "DEATHKNIGHT" then
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
	self.nextCast = nextCast
	self.currentSpellId = spellId
	self.startCast = startCast
	self.endCast = endCast

	self.lastSpellId = spellId

	-- Set the current time in the simulator to a little after the start of the current cast,
	-- or to now if in the past.
	if startCast >= self.now then
		self.currentTime = startCast + 0.1
	else
		self.currentTime = self.now
	end

	Ovale:Logf("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, self.currentTime, self.nextCast, endCast, targetGUID)

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
	self:InvokeMethod("ApplySpellStart", spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleState:ApplySpellOnPlayer(spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
	self:InvokeMethod("ApplySpellOnPlayer", spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
	--[[
		If the spellcast has already ended, then the effects have already occurred,
		so only consider spells that have not yet finished casting in the simulator.
	--]]
	if endCast > self.now then
		local si = OvaleData.spellInfo[spellId]
		if si then
			-- Runes
			if si.blood and si.blood < 0 then
				AddRune(startCast, 1, si.blood)
			end
			if si.unholy and si.unholy < 0 then
				AddRune(startCast, 2, si.unholy)
			end
			if si.frost and si.frost < 0 then
				AddRune(startCast, 3, si.frost)
			end
			if si.death and si.death < 0 then
				AddRune(startCast, 4, si.death)
			end
		end
	end
end

-- Apply the effects of the spell on the target's state when it lands on the target.
function OvaleState:ApplySpellOnTarget(spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
	self:InvokeMethod("ApplySpellOnTarget", spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
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
--</public-static-methods>
