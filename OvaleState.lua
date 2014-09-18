--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam

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

local pairs = pairs
--</private-static-properties>

--<public-static-properties>
-- Registered state prototypes from which mix-in methods are added to state machines.
OvaleState.statePrototype = {}
OvaleState.stateAddons = OvaleQueue:NewQueue("OvaleState_stateAddons")

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
	self.stateAddons:Insert(stateAddon)
	self.statePrototype[stateAddon] = statePrototype

	-- Mix-in addon's state prototype into OvaleState.state.
	for k, v in pairs(statePrototype) do
		self.state[k] = v
	end
end

function OvaleState:UnregisterState(stateAddon)
	stateModules = OvaleQueue:NewQueue("OvaleState_stateModules")
	while self.stateAddons:Size() > 0 do
		local addon = self.stateAddons:Remove()
		if stateAddon ~= addon then
			stateModules:Insert(addon)
		end
	end
	self.stateAddons = stateModules

	-- Release resources used by the state machine managed by the addon.
	if stateAddon.CleanState then
		stateAddon:CleanState(self.state)
	end

	-- Remove mix-in methods from addon's state prototype.
	local statePrototype = self.statePrototype[stateAddon]
	if statePrototype then
		for k in pairs(statePrototype) do
			self.state[k] = nil
		end
	end
	self.statePrototype[stateAddon] = nil
end

function OvaleState:InvokeMethod(methodName, ...)
	for _, addon in self.stateAddons:Iterator() do
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
-- Whether the state of the simulator has been initialized.
statePrototype.isInitialized = nil
-- Table of state variables added by scripts that is reset on every refresh.
statePrototype.futureVariable = nil
-- Table of state variables added by scripts that is reset only when out of combat.
statePrototype.variable = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleState:InitializeState(state)
	state.futureVariable = {}
	state.variable = {}
end

-- Reset the state to the current conditions.
function OvaleState:ResetState(state)
	for k in pairs(state.futureVariable) do
		state.futureVariable[k] = nil
	end
	-- TODO: What conditions should trigger resetting state variables?
	-- For now, reset/remove all state variables if out of combat.
	if not Ovale.enCombat then
		for k in pairs(state.variable) do
			state.variable[k] = nil
		end
	end
end

-- Release state resources prior to removing from the simulator.
function OvaleState:CleanState(state)
	for k in pairs(state.futureVariable) do
		state.futureVariable[k] = nil
	end
	for k in pairs(state.variable) do
		state.variable[k] = nil
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

-- Put a value into the named state variable.
statePrototype.PutState = function(state, name, value, isFuture)
	if isTemporary then
		state.futureVariable[name] = value
	else
		state.variable[name] = value
	end
end
--</state-methods>
