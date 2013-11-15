--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

--[[
	This addon is the core of the state machine for the simulator.
--]]

local _, Ovale = ...
local OvaleState = Ovale:NewModule("OvaleState")
Ovale.OvaleState = OvaleState

--<private-static-properties>
local OvaleData = Ovale.OvaleData
local OvaleQueue = Ovale.OvaleQueue

local pairs = pairs
local API_GetTime = GetTime

local self_statePrototype = {}
local self_stateModules = OvaleQueue:NewQueue("OvaleState_stateModules")

-- Whether the state of the simulator has been initialized.
local self_stateIsInitialized = false
--</private-static-properties>

--<public-static-properties>
-- The state for the simulator.
OvaleState.state = {}
-- The spell being cast.
OvaleState.currentSpellId = nil
OvaleState.now = nil
OvaleState.currentTime = nil
OvaleState.nextCast = nil
OvaleState.startCast = nil
OvaleState.endCast = nil
OvaleState.lastSpellId = nil
--</public-static-properties>

--<private-static-methods>
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
	self_stateIsInitialized = true
end

function OvaleState:Reset()
	self.currentTime = self.now
	Ovale:Logf("Reset state with current time = %f", self.currentTime)

	self.lastSpellId = Ovale.lastSpellcast and Ovale.lastSpellcast.spellId
	self.currentSpellId = nil
	self.nextCast = self.now

	self:InvokeMethod("ResetState")
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
	self:InvokeMethod("ApplySpellStart", spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
	self:InvokeMethod("ApplySpellOnPlayer", spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
	self:InvokeMethod("ApplySpellOnTarget", spellId, startCast, endCast, nextCast, nocd, targetGUID, spellcast)
end
--</public-static-methods>
