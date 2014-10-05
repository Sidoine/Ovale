--[[--------------------------------------------------------------------
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
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
	local group = OvaleComboPoints:GetName()
	Profiler:RegisterProfilingGroup(group)
	profiler = Profiler:GetProfilingGroup(group)
end

-- Forward declarations for module dependencies.
local OvaleAura = nil
local OvaleData = nil
local OvaleFuture = nil
local OvaleGUID = nil
local OvaleSpellBook = nil
local OvaleState = nil

local API_GetComboPoints = GetComboPoints
local API_UnitClass = UnitClass
local API_UnitGUID = UnitGUID
local MAX_COMBO_POINTS = MAX_COMBO_POINTS

-- Player's class.
local _, self_class = API_UnitClass("player")
-- Player's GUID.
local self_guid = nil

-- Rogue's Anticipation talent.
local ANTICIPATION = 115189
local ANTICIPATION_DURATION = 15
local ANTICIPATION_TALENT = 18
local self_hasAnticipation = false
-- The number of stacks of Anticipation that were on the player when the most recent finisher was cast.
local self_anticipation = 0
-- Rogue offensive finishers.
local OFFENSIVE_FINISHER_ROGUE = {
	[   408] = "Kidney Shot",
	[  1943] = "Rupture",
	[  2098] = "Eviscerate",
	[ 32645] = "Envenom",
	[121411] = "Crimson Tempest",
}

-- Table of functions to update spellcast information to register with OvaleFuture.
local self_updateSpellcastInfo = {}

local OVALE_COMBO_POINTS_DEBUG = "combo_points"
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
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleState = Ovale.OvaleState
end

function OvaleComboPoints:OnEnable()
	self_guid = API_UnitGUID("player")
	if self_class == "ROGUE" or self_class == "DRUID" then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "Refresh")
		self:RegisterEvent("PLAYER_LOGIN", "Refresh")
		self:RegisterEvent("PLAYER_TARGET_CHANGED", "Refresh")
		self:RegisterEvent("UNIT_COMBO_POINTS")
		self:RegisterEvent("UNIT_TARGET", "UNIT_COMBO_POINTS")
		if self_class == "ROGUE" then
			self:RegisterMessage("Ovale_AuraRemoved")
			self:RegisterMessage("Ovale_TalentsChanged")
		end
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
		if self_class == "ROGUE" then
			self:RegisterMessage("Ovale_AuraRemoved")
			self:RegisterMessage("Ovale_TalentsChanged")
		end
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

	if sourceGUID == self_guid and destGUID == OvaleGUID:GetGUID("target") then
		if cleuEvent == "SPELL_DAMAGE" then
			local spellId, critical = arg12, arg21
			local si = OvaleData.spellInfo[spellId]
			if critical and si and si.critcombo then
				Ovale:DebugPrintf(OVALE_COMBO_POINTS_DEBUG, "Critical strike for %d additional combo points.", si.critcombo)
				self.combo = self.combo + si.critcombo
				if self.combo > MAX_COMBO_POINTS then
					self.combo = MAX_COMBO_POINTS
				end
			end
		elseif self_hasAnticipation and cleuEvent == "SPELL_CAST_SUCCESS" then
			local spellId = arg12
			if OFFENSIVE_FINISHER_ROGUE[spellId] then
				local aura = OvaleAura:GetAuraByGUID(self_guid, ANTICIPATION, "HELPFUL", true)
				if OvaleAura:IsActiveAura(aura) then
					self_anticipation = aura.stacks
					Ovale:DebugPrintf(OVALE_COMBO_POINTS_DEBUG, "Finisher with %d anticipation stacks.", self_anticipation)
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

function OvaleComboPoints:Ovale_AuraRemoved(event, atTime, guid, auraId, source)
	if guid == self_guid and auraId == ANTICIPATION then
		self_anticipation = 0
	end
end

function OvaleComboPoints:Ovale_TalentsChanged(event)
	self_hasAnticipation = (self_class == "ROGUE" and OvaleSpellBook:GetTalentPoints(ANTICIPATION_TALENT) > 0)
end

function OvaleComboPoints:Refresh()
	profiler.Start("OvaleComboPoints_Refresh")
	local combo = API_GetComboPoints("player") or 0
	local oldCombo = self.combo
	if oldCombo == combo then
		-- Game state has caught up with the adjusted combo point total, so remove the adjustment.
		self_anticipation = 0
	else
		if self_hasAnticipation and self_anticipation > 0 then
			self.combo = combo + self_anticipation
			if self.combo > MAX_COMBO_POINTS then
				self.combo = MAX_COMBO_POINTS
			end
			Ovale:DebugPrintf(OVALE_COMBO_POINTS_DEBUG, "%d -> %d (+%d).", oldCombo, combo, self_anticipation)
		else
			self.combo = combo
			Ovale:DebugPrintf(OVALE_COMBO_POINTS_DEBUG, "%d -> %d.", oldCombo, combo)
		end
	end
	profiler.Stop("OvaleComboPoints_Refresh")
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
		if power <= 0 then
			power = 0
			--[[
				If a rogue is talented into Anticipation, then any stacks of Anticipation
				become combo points on the target after the finisher is cast.
			--]]
			if self_hasAnticipation and state.combo > 0 then
				local aura = state:GetAuraByGUID(self_guid, ANTICIPATION, "HELPFUL", true)
				if state:IsActiveAura(aura, endCast) then
					power = aura.stacks
					state:RemoveAuraOnGUID(self_guid, ANTICIPATION, "HELPFUL", true, state.currentTime)
				end
			end
		end
		if power > MAX_COMBO_POINTS then
			--[[
				If a rogue is talented into Anticipation, then any combo points over
				MAX_COMBO_POINTS are added to the stacks of Anticipation on the player
				to a maximum of MAX_COMBO_POINTS stacks.
			--]]
			if self_hasAnticipation then
				local stacks = power - MAX_COMBO_POINTS
				-- Look for a pre-existing Anticipation buff and add to its stacks.
				local aura = state:GetAuraByGUID(self_guid, ANTICIPATION, "HELPFUL", true)
				if state:IsActiveAura(aura, endCast) then
					stacks = stacks + aura.stacks
					if stacks > MAX_COMBO_POINTS then
						stacks = MAX_COMBO_POINTS
					end
				end
				-- Add a new Anticipation buff with the updated start, ending, stacks information.
				local start = state.currentTime
				local ending = start + ANTICIPATION_DURATION
				aura = state:AddAuraToGUID(self_guid, ANTICIPATION, self_guid, "HELPFUL", start, ending)
				aura.stacks = stacks
			end
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
