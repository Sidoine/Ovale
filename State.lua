--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

--[[
	This addon is the core of the state machine for the simulator.
--]]

local OVALE, Ovale = ...
local OvaleState = Ovale:NewModule("OvaleState")
Ovale.OvaleState = OvaleState

--<private-static-properties>
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug
local OvaleQueue = Ovale.OvaleQueue

local pairs = pairs

-- Registered state prototypes from which mix-in methods are added to state machines.
local self_statePrototype = {}
local self_stateAddons = OvaleQueue:NewQueue("OvaleState_stateAddons")

OvaleDebug:RegisterDebugging(OvaleState)
--</private-static-properties>

--<public-static-properties>
-- The state for the simulator.
OvaleState.state = {}
--</public-static-properties>

--<public-static-methods>
function OvaleState:OnEnable()
	self:RegisterState(self, self.statePrototype)
end

function OvaleState:OnDisable()
	self:UnregisterState(self)
end


function OvaleState:RegisterState(stateAddon, statePrototype)
	self_stateAddons:Insert(stateAddon)
	self_statePrototype[stateAddon] = statePrototype

	-- Mix-in addon's state prototype into OvaleState.state.
	for k, v in pairs(statePrototype) do
		self.state[k] = v
	end
end

function OvaleState:UnregisterState(stateAddon)
	local stateModules = OvaleQueue:NewQueue("OvaleState_stateModules")
	while self_stateAddons:Size() > 0 do
		local addon = self_stateAddons:Remove()
		if stateAddon ~= addon then
			stateModules:Insert(addon)
		end
	end
	self_stateAddons = stateModules

	-- Release resources used by the state machine managed by the addon.
	if stateAddon.CleanState then
		stateAddon:CleanState(self.state)
	end

	-- Remove mix-in methods from addon's state prototype.
	local statePrototype = self_statePrototype[stateAddon]
	if statePrototype then
		for k in pairs(statePrototype) do
			self.state[k] = nil
		end
	end
	self_statePrototype[stateAddon] = nil
end

function OvaleState:InvokeMethod(methodName, ...)
	for _, addon in self_stateAddons:Iterator() do
		if addon[methodName] then
			addon[methodName](addon, ...)
		end
	end
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleState.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleState.statePrototype
--</private-static-properties>

--<state-properties>
-- Whether this object is a state machine.
statePrototype.isState = true
-- Whether the state of the simulator has been initialized.
statePrototype.isInitialized = nil
-- Table of state variables added by scripts that is reset on every refresh.
statePrototype.futureVariable = nil
-- Table of most recent time a state variable that is reset on every refresh was added.
statePrototype.futureLastEnable = nil
-- Table of state variables added by scripts that is reset only when out of combat.
statePrototype.variable = nil
-- Table of most recent time a state variable that is reset when out of combat was added.
statePrototype.lastEnable = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleState:InitializeState(state)
	state.futureVariable = {}
	state.futureLastEnable = {}
	state.variable = {}
	state.lastEnable = {}
end

-- Reset the state to the current conditions.
function OvaleState:ResetState(state)
	for k in pairs(state.futureVariable) do
		state.futureVariable[k] = nil
		state.futureLastEnable[k] = nil
	end
	-- TODO: What conditions should trigger resetting state variables?
	-- For now, reset/remove all state variables if out of combat.
	if not state.inCombat then
		for k in pairs(state.variable) do
			state:Log("Resetting state variable '%s'.", k)
			state.variable[k] = nil
			state.lastEnable[k] = nil
		end
	end
end

-- Release state resources prior to removing from the simulator.
function OvaleState:CleanState(state)
	for k in pairs(state.futureVariable) do
		state.futureVariable[k] = nil
	end
	for k in pairs(state.futureLastEnable) do
		state.futureLastEnable[k] = nil
	end
	for k in pairs(state.variable) do
		state.variable[k] = nil
	end
	for k in pairs(state.lastEnable) do
		state.lastEnable[k] = nil
	end
end
--</public-static-methods>

--<state-methods>
statePrototype.Initialize = function(state)
	if not state.isInitialized then
		OvaleState:InvokeMethod("InitializeState", state)
		state.isInitialized = true
	end
end

statePrototype.Reset = function(state)
	OvaleState:InvokeMethod("ResetState", state)
end

-- Get the value of the named state variable.  If missing, then return 0.
statePrototype.GetState = function(state, name)
	return state.futureVariable[name] or state.variable[name] or 0
end

--[[
	Get the duration in seconds that the simulator has been most recently
	in the named state.
--]]
statePrototype.GetStateDuration = function(state, name)
	local lastEnable = state.futureLastEnable[name] or state.lastEnable[name] or state.currentTime
	return state.currentTime - lastEnable
end

-- Put a value into the named state variable.
statePrototype.PutState = function(state, name, value, isFuture)
	if isFuture then
		local oldValue = state:GetState(name)
		if value ~= oldValue then
			state:Log("Setting future state: %s from %s to %s.", name, oldValue, value)
			state.futureVariable[name] = value
			state.futureLastEnable[name] = state.currentTime
		end
	else
		local oldValue = state.variable[name] or 0
		if value ~= oldValue then
			OvaleState:DebugTimestamp("Advancing combat state: %s from %s to %s.", name, oldValue, value)
			state:Log("Advancing combat state: %s from %s to %s.", name, oldValue, value)
			state.variable[name] = value
			state.lastEnable[name] = state.currentTime
		end
	end
end

-- Logging function.
statePrototype.Log = function(state, ...)
	return OvaleDebug:Log(...)
end

-- GetMethod function (mirrored from Ovale).
statePrototype.GetMethod = Ovale.GetMethod
--</state-methods>
