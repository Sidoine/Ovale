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
