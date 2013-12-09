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
--</private-static-properties>

--<public-static-properties>
-- Registered state prototypes from which mix-in methods are added to state machines.
OvaleState.statePrototype = {}
OvaleState.stateAddons = OvaleQueue:NewQueue("OvaleState_stateAddons")

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
	for k in pairs(statePrototype) do
		self.state[k] = nil
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
--</state-properties>

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
--</state-methods>
