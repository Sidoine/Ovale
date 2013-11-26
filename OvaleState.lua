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
local OvaleQueue = Ovale.OvaleQueue

-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleFuture = nil

local pairs = pairs
local API_GetTime = GetTime

local self_statePrototype = {}
local self_stateModules = OvaleQueue:NewQueue("OvaleState_stateModules")
--</private-static-properties>

--<public-static-properties>
-- The state for the simulator.
OvaleState.state = {}
--</public-static-properties>

--<public-static-methods>
function OvaleState:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvaleFuture = Ovale.OvaleFuture
end

function OvaleState:OnEnable()
	self:RegisterState(self, self.statePrototype)
end

function OvaleState:OnDisable()
	self:UnregisterState(self)
end


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

	-- Release resources used by the state machine managed by the addon.
	if addon.CleanState then
		addon:CleanState(self.state)
	end

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
			addon[methodName](addon, ...)
		end
	end
end

function OvaleState:StartNewFrame(state)
	if not state.isInitialized then
		self:InvokeMethod("InitializeState", state)
	end
end

function OvaleState:Reset(state)
	self:InvokeMethod("ResetState", state)
end

--[[
	Cast a spell in the simulator and advance the state of the simulator.

	Parameters:
		spellId		The ID of the spell to cast.
		targetGUID	The GUID of the target of the spellcast.
		startCast	The time at the start of the spellcast.
		endCast		The time at the end of the spellcast.
		nextCast	The earliest time at which the next spell can be cast (nextCast >= endCast).
		isChanneled	The spell is a channeled spell.
		nocd		The spell's cooldown is not triggered.
		spellcast	(optional) Table of spellcast information, including a snapshot of player's stats.
--]]
function OvaleState:ApplySpell(state, ...)
	local spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast = ...
	if not spellId or not targetGUID then
		return
	end

	-- Handle missing start/end/next cast times.
	if not startCast or not endCast or not nextCast then
		local castTime = 0
		local castTime = select(7, API_GetSpellInfo(spellId))
		castTime = castTime and (castTime / 1000) or 0
		local gcd = OvaleCooldown:GetGCD(spellId)

		startCast = startCast or state.nextCast
		endCast = endCast or (startCast + castTime)
		nextCast = (castTime > gcd) and endCast or (startCast + gcd)
	end

	-- Update the latest spell cast in the simulator.
	state.currentSpellId = spellId
	state.startCast = startCast
	state.endCast = endCast
	state.nextCast = nextCast
	state.isChanneling = isChanneled
	state.lastSpellId = spellId

	-- Set the current time in the simulator to a little after the start of the current cast,
	-- or to now if in the past.
	local now = API_GetTime()
	if startCast >= now then
		state.currentTime = startCast + 0.1
	else
		state.currentTime = now
	end

	Ovale:Logf("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, state.currentTime, nextCast, endCast, targetGUID)

	--[[
		Apply the effects of the spellcast in three phases.
			1. Effects at the beginning of the spellcast.
			2. Effects when the spell has been cast.
			3. Effects when the spellcast hits the target.
	--]]
	-- If the spellcast has already started, then the effects have already occurred.
	if startCast >= now then
		self:InvokeMethod("ApplySpellStartCast", state, ...)
	end
	-- If the spellcast has already ended, then the effects have already occurred.
	if endCast > now then
		self:InvokeMethod("ApplySpellAfterCast", state, ...)
	end
	self:InvokeMethod("ApplySpellOnHit", state, ...)
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleState.statePrototype = {
	-- Whether the state of the simulator has been initialized.
	isInitialized = nil,
	-- The current time in the simulator.
	currentTime = nil,
	-- The spell being cast in the simulator.
	currentSpellId = nil,
	-- The starting cast time of the spell being cast in the simulator.
	startCast = nil,
	-- The ending cast time of the spell being cast in the simulator.
	endCast = nil,
	-- The time at which the next GCD spell can be cast in the simulator.
	nextCast = nil,
	-- Whether the player is channeling a spell in the simulator at the current time.
	isChanneling = nil,
	-- The previous spell cast in the simulator.
	lastSpellId = nil,
}
--</public-static-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleState:InitializeState(state)
	state.isInitialized = true
end

-- Reset the state to the current conditions.
function OvaleState:ResetState(state)
	local now = API_GetTime()
	state.currentTime = now
	Ovale:Logf("Reset state with current time = %f", state.currentTime)

	state.lastSpellId = OvaleFuture.lastSpellcast and OvaleFuture.lastSpellcast.spellId
	state.currentSpellId = nil
	state.isChanneling = false
	state.nextCast = now
end
--</public-static-methods>
