--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- This addon tracks the number of combo points by the player on the current target.

local _, Ovale = ...
local OvaleComboPoints = Ovale:NewModule("OvaleComboPoints", "AceEvent-3.0")
Ovale.OvaleComboPoints = OvaleComboPoints

--<private-static-properties>
-- Profiling set-up.
local Profiler = Ovale.Profiler
local profiler = nil
do
	Profiler:RegisterProfilingGroup("OvaleComboPoints")
	profiler = Profiler.group["OvaleComboPoints"]
end

-- Forward declarations for module dependencies.
local OvaleAura = nil
local OvaleData = nil
local OvaleFuture = nil
local OvaleGUID = nil
local OvaleState = nil

local API_GetComboPoints = GetComboPoints
local API_UnitClass = UnitClass
local MAX_COMBO_POINTS = MAX_COMBO_POINTS

-- Player's class.
local _, self_class = API_UnitClass("player")

-- Table of functions to update spellcast information to register with OvaleFuture.
local self_updateSpellcastInfo = {}
--</private-static-properties>

--<public-static-properties>
OvaleComboPoints.combo = 0
--</public-static-properties>

--<private-static-methods>
-- Manage spellcast.combo information.
local function SaveToSpellcast(spellcast)
	if spellcast.spellId then
		local si = OvaleData.spellInfo[spellcast.spellId]
		if si.combo == "finisher" then
			-- If a buff is present that removes the combo point cost of the spell,
			-- then treat it as a maximum combo-point finisher.
			if si.buff_combo_none then
				if OvaleAura:GetAura("player", si.buff_combo_none) then
					spellcast.combo = MAX_COMBO_POINTS
				end
			end
			local min_combo = si.min_combo or si.mincombo or 1
			if OvaleComboPoints.combo >= min_combo then
				spellcast.combo = OvaleComboPoints.combo
			end
		end
	end
end

local function UpdateFromSpellcast(dest, spellcast)
	if spellcast.combo then
		dest.combo = spellcast.combo
	end
end

do
	self_updateSpellcastInfo.SaveToSpellcast = SaveToSpellcast
	self_updateSpellcastInfo.UpdateFromSpellcast = UpdateFromSpellcast
end
--</private-static-methods>

--<public-static-methods>
function OvaleComboPoints:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
	OvaleData = Ovale.OvaleData
	OvaleFuture = Ovale.OvaleFuture
	OvaleGUID = Ovale.OvaleGUID
	OvaleState = Ovale.OvaleState
end

function OvaleComboPoints:OnEnable()
	if self_class == "ROGUE" or self_class == "DRUID" then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "Refresh")
		self:RegisterEvent("PLAYER_LOGIN", "Refresh")
		self:RegisterEvent("PLAYER_TARGET_CHANGED", "Refresh")
		self:RegisterEvent("UNIT_COMBO_POINTS")
		self:RegisterEvent("UNIT_TARGET", "UNIT_COMBO_POINTS")
		OvaleState:RegisterState(self, self.statePrototype)
		OvaleFuture:RegisterSpellcastInfo(self_updateSpellcastInfo)
	end
end

function OvaleComboPoints:OnDisable()
	if self_class == "ROGUE" or self_class == "DRUID" then
		OvaleState:UnregisterState(self)
		OvaleFuture:UnregisterSpellcastInfo(self_updateSpellcastInfo)
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		self:UnregisterEvent("PLAYER_LOGIN")
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UNIT_COMBO_POINTS")
		self:UnregisterEvent("UNIT_TARGET")
	end
end

--[[
A rogue's Seal Fate or a druid's Primal Fury are passive abilities that grant an
extra combo point when a combo-point generator critically strikes the target.

Workaround the "combo point delay" after a generator critically strikes the target
by catching the critical strike damage event and adding the given number of extra
combo points.  The delay MUST be less than the GCD.

An ability that generates extra combo points after it critically strikes the target
should have a "critcombo=N" parameter in its SpellInfo() description, where N is
the number of extra combo points to add, e.g., critcombo=1.
--]]
function OvaleComboPoints:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23 = ...

	if sourceGUID == OvaleGUID:GetGUID("player") and destGUID == OvaleGUID:GetGUID("target") then
		if cleuEvent == "SPELL_DAMAGE" then
			local spellId, critical = arg12, arg21
			local si = OvaleData.spellInfo[spellId]
			if critical and si and si.critcombo then
				self.combo = self.combo + si.critcombo
				if self.combo > MAX_COMBO_POINTS then
					self.combo = MAX_COMBO_POINTS
				end
			end
		end
	end
end

function OvaleComboPoints:UNIT_COMBO_POINTS(event, ...)
	local unitId = ...
	if unitId == "player" then
		self:Refresh()
	end
end

function OvaleComboPoints:Refresh()
	self.combo = API_GetComboPoints("player") or 0
end

function OvaleComboPoints:Debug()
	Ovale:FormatPrint("Player has %d combo points on target %s.", self.combo, OvaleGUID:GetGUID("target"))
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleComboPoints.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleComboPoints.statePrototype
--</private-static-properties>

--<state-properties>
statePrototype.combo = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleComboPoints:InitializeState(state)
	state.combo = 0
end

-- Reset the state to the current conditions.
function OvaleComboPoints:ResetState(state)
	profiler.Start("OvaleComboPoints_ResetState")
	state.combo = self.combo or 0
	profiler.Stop("OvaleComboPoints_ResetState")
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleComboPoints:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast)
	profiler.Start("OvaleComboPoints_ApplySpellAfterCast")
	local si = OvaleData.spellInfo[spellId]
	if si and si.combo then
		local cost = state:ComboPointCost(spellId)
		local power = state.combo
		power = power - cost
		-- Clamp combo points to lower and upper limits.
		if power < 0 then
			power = 0
		end
		if power > MAX_COMBO_POINTS then
			power = MAX_COMBO_POINTS
		end
		state.combo = power
	end
	profiler.Stop("OvaleComboPoints_ApplySpellAfterCast")
end
--</public-static-methods>

--<state-methods>
-- Return the number of combo points required to cast the given spell.
statePrototype.ComboPointCost = function(state, spellId)
	profiler.Start("OvaleComboPoints_state_ComboPointCost")
	local spellCost = 0
	local si = OvaleData.spellInfo[spellId]
	if si and si.combo then
		local cost = si.combo
		--[[
			combo == 0 means the that spell uses no resources.
			combo > 0 means that the spell generates combo points.
			combo < 0 means that the spell costs combo points.
			combo == "finisher" means that the spell uses all of the combo points (zeroes it out).
		--]]
		if cost == "finisher" then
			-- This spell is a finisher so compute the cost based on the amount of resources consumed.
			cost = state.combo
			-- Clamp cost between values defined by min_combo and max_combo.
			local minCost = si.min_combo or si.mincombo or 1
			local maxCost = si.max_combo
			if cost < minCost then
				cost = minCost
			end
			if maxCost and cost > maxCost then
				cost = maxCost
			end
		else
			--[[
				Add extra combo points generated by presence of a buff.
				"buff_combo" is the spell ID of the buff that causes extra resources to be generated or used.
				"buff_combo_amount" is the amount of extra resources generated or used, defaulting to 1
					(one extra combo point generated).
			--]]
			local buffExtra = si.buff_combo
			if buffExtra then
				local aura = state:GetAura("player", buffExtra, nil, true)
				if state:IsActiveAura(aura) then
					local buffAmount = si.buff_combo_amount or 1
					cost = cost + buffAmount
				end
			end
			cost = -1 * cost
		end

		local buffNoCost = si.buff_combo_none
		if buffNoCost then
			-- "buff_combo_none" is the spell ID of the buff that makes casting the spell cost zero combo points.
			local aura = state:GetAura("player", buffNoCost)
			if state:IsActiveAura(aura) then
				cost = 0
			end
		end
		spellCost = cost
	end
	profiler.Stop("OvaleComboPoints_state_ComboPointCost")
	return spellCost
end
--</state-methods>
