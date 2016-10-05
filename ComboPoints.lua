--[[--------------------------------------------------------------------
    Copyright (C) 2012, 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- This addon tracks the number of combo points on the player.

local OVALE, Ovale = ...
local OvaleComboPoints = Ovale:NewModule("OvaleComboPoints", "AceEvent-3.0")
Ovale.OvaleComboPoints = OvaleComboPoints

--<private-static-properties>
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleAura = nil
local OvaleData = nil
local OvaleEquipment = nil
local OvaleFuture = nil
local OvalePaperDoll = nil
local OvalePower = nil
local OvaleSpellBook = nil
local OvaleState = nil

local tinsert = table.insert
local tremove = table.remove
local API_GetTime = GetTime
local API_UnitPower = UnitPower
local MAX_COMBO_POINTS = MAX_COMBO_POINTS
local UNKNOWN = UNKNOWN

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvaleComboPoints)
-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleComboPoints)

-- Player's GUID.
local self_playerGUID = nil

-- Rogue's Anticipation talent.
local ANTICIPATION = 115189
local ANTICIPATION_DURATION = 15
local ANTICIPATION_TALENT = 18
local self_hasAnticipation = false

-- Rogue's Ruthlessness passive spell.
local RUTHLESSNESS = 14161
local self_hasRuthlessness = false

-- Envenom spell ID.
local ENVENOM = 32645
local self_hasAssassination4pT17 = false

-- Queue of pending combo point events.
local self_pendingComboEvents = {}
-- Number of seconds a pending combo point event can exist without expiring.
local PENDING_THRESHOLD = 0.8

-- Table of functions to update spellcast information to register with OvaleFuture.
local self_updateSpellcastInfo = {}
--</private-static-properties>

--<public-static-properties>
-- The current number of combo points on the player.
OvaleComboPoints.combo = 0
--</public-static-properties>

--<private-static-methods>
-- Add a pending combo event caused by the given spell.
local function AddPendingComboEvent(atTime, spellId, guid, reason, combo)
	local comboEvent = {
		atTime = atTime,
		spellId = spellId,
		guid = guid,
		reason = reason,
		combo = combo,
	}
	tinsert(self_pendingComboEvents, comboEvent)
	Ovale.refreshNeeded[self_playerGUID] = true
end

-- Remove all pending combo point events caused by the given spell on the target GUID.
-- If only atTime is given, then all expired events are removed.
local function RemovePendingComboEvents(atTime, spellId, guid, reason, combo)
	local count = 0
	for k = #self_pendingComboEvents, 1, -1 do
		local comboEvent = self_pendingComboEvents[k]
		-- Remove expired or matching pending events.
		if (atTime and atTime - comboEvent.atTime > PENDING_THRESHOLD)
				or (comboEvent.spellId == spellId and comboEvent.guid == guid and (not reason or comboEvent.reason == reason) and (not combo or comboEvent.combo == combo)) then
			if comboEvent.combo == "finisher" then
				OvaleComboPoints:Debug("Removing expired %s event: spell %d combo point finisher from %s.", comboEvent.reason, comboEvent.spellId, comboEvent.reason)
			else
				OvaleComboPoints:Debug("Removing expired %s event: spell %d for %d combo points from %s.", comboEvent.reason, comboEvent.spellId, comboEvent.combo, comboEvent.reason)
			end
			count = count + 1
			tremove(self_pendingComboEvents, k)
			Ovale.refreshNeeded[self_playerGUID] = true
		end
	end
	return count
end
--</private-static-methods>

--<public-static-methods>
function OvaleComboPoints:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
	OvaleData = Ovale.OvaleData
	OvaleEquipment = Ovale.OvaleEquipment
	OvaleFuture = Ovale.OvaleFuture
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvalePower = Ovale.OvalePower
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleState = Ovale.OvaleState
end

function OvaleComboPoints:OnEnable()
	self_playerGUID = Ovale.playerGUID
	if Ovale.playerClass == "ROGUE" or Ovale.playerClass == "DRUID" then
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UNIT_POWER")
		self:RegisterEvent("Ovale_EquipmentChanged")
		self:RegisterMessage("Ovale_SpellFinished")
		self:RegisterMessage("Ovale_TalentsChanged")
		OvaleData:RegisterRequirement("combo", "RequireComboPointsHandler", self)
		OvaleFuture:RegisterSpellcastInfo(self)
		OvaleState:RegisterState(self, self.statePrototype)
	end
end

function OvaleComboPoints:OnDisable()
	if Ovale.playerClass == "ROGUE" or Ovale.playerClass == "DRUID" then
		OvaleState:UnregisterState(self)
		OvaleFuture:UnregisterSpellcastInfo(self)
		OvaleData:UnregisterRequirement("combo")
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UNIT_POWER")
		self:UnregisterEvent("Ovale_EquipmentChanged")
		self:UnregisterMessage("Ovale_SpellFinished")
		self:UnregisterMessage("Ovale_TalentsChanged")
	end
end

function OvaleComboPoints:PLAYER_TARGET_CHANGED(event, cause)
	if cause == "NIL" or cause == "down" then
		-- Target was cleared.
	else
		-- Target has changed.
		self:Update()
	end
end

function OvaleComboPoints:UNIT_POWER(event, unitId, powerToken)
	if powerToken ~= OvalePower.POWER_INFO.combopoints.token then return end
	if unitId == "player" then
		-- Save the old combo point count and update to the current count.
		local oldCombo = self.combo
		self:Update()

		local difference = self.combo - oldCombo
		self:DebugTimestamp("%s: %d -> %d.", event, oldCombo, self.combo)

		-- Remove expired events.
		local now = API_GetTime()
		RemovePendingComboEvents(now)

		local pendingMatched = false
		if #self_pendingComboEvents > 0 then
			local comboEvent = self_pendingComboEvents[1]
			local spellId, guid, reason, combo = comboEvent.spellId, comboEvent.guid, comboEvent.reason, comboEvent.combo
			if combo == difference or (combo == "finisher" and self.combo == 0 and difference < 0) then
				self:Debug("    Matches pending %s event for %d.", reason, spellId)
				pendingMatched = true
				tremove(self_pendingComboEvents, 1)
			end
		end
--[[	if not pendingMatched and not OvaleFuture.inCombat and difference <= 0 then
			self:Debug("    Out-of-combat combo point decay.")
			if difference == 0 then
				-- Decrement the combo point count until game state catches up with the event.
				local newCombo = self.combo - 1
				self.combo = newCombo > 0 and newCombo or 0
				self:Debug("    Decaying to %d combo point(s).", self.combo)
			end
		end ]]--
	end
end

function OvaleComboPoints:Ovale_EquipmentChanged(event)
	self_hasAssassination4pT17 = (Ovale.playerClass == "ROGUE" and OvalePaperDoll:IsSpecialization("assassination") and OvaleEquipment:GetArmorSetCount("T17") >= 4)
end

function OvaleComboPoints:Ovale_SpellFinished(event, atTime, spellId, targetGUID, finish)
	self:Debug("%s (%f): Spell %d finished (%s) on %s", event, atTime, spellId, finish, targetGUID or UNKNOWN)
	local si = OvaleData.spellInfo[spellId]
	if si and si.combo == "finisher" and finish == "hit" then
		self:Debug("    Spell %d hit and consumed all combo points.", spellId)
		AddPendingComboEvent(atTime, spellId, targetGUID, "finisher", "finisher")
		if self_hasRuthlessness and self.combo == MAX_COMBO_POINTS then
			-- Ruthlessness grants a 20% chance to grant a combo point for each combo point spent on a finishing move.
			self:Debug("    Spell %d has 100% chance to grant an extra combo point from Ruthlessness.", spellId)
			AddPendingComboEvent(atTime, spellId, targetGUID, "Ruthlessness", 1)
		end
		if self_hasAssassination4pT17 and spellId == ENVENOM then
			-- The 4pT17 bonus for Assassination rogues causes Envenom to refunds 1 combo point.
			self:Debug("    Spell %d refunds 1 combo point from Assassination 4pT17 set bonus.", spellId)
			AddPendingComboEvent(atTime, spellId, targetGUID, "Assassination 4pT17", 1)
		end
		if self_hasAnticipation and targetGUID ~= self_playerGUID then
			-- Anticipation causes offensive finishing moves to consume all Anticipation charges and to grant a combo point for each.
			if OvaleSpellBook:IsHarmfulSpell(spellId) then
				local aura = OvaleAura:GetAuraByGUID(self_playerGUID, ANTICIPATION, "HELPFUL", true)
				if OvaleAura:IsActiveAura(aura, atTime) then
					self:Debug("    Spell %d hit with %d Anticipation charges.", spellId, aura.stacks)
					AddPendingComboEvent(atTime, spellId, targetGUID, "Anticipation", aura.stacks)
				end
			end
		end
	end
end

function OvaleComboPoints:Ovale_TalentsChanged(event)
	if Ovale.playerClass == "ROGUE" then
		self_hasAnticipation = OvaleSpellBook:GetTalentPoints(ANTICIPATION_TALENT) > 0
		self_hasRuthlessness = OvaleSpellBook:IsKnownSpell(RUTHLESSNESS)
	end
end

function OvaleComboPoints:Update()
	self:StartProfiling("OvaleComboPoints_Update")
	self.combo = API_UnitPower("player", 4)
	Ovale.refreshNeeded[self_playerGUID] = true
	self:StopProfiling("OvaleComboPoints_Update")
end

function OvaleComboPoints:GetComboPoints()
	-- Remove expired events.
	local now = API_GetTime()
	RemovePendingComboEvents(now)

	-- Start with the true combo point total and adjust for any pending combo points.
	local total = self.combo
	for k = 1, #self_pendingComboEvents do
		local combo = self_pendingComboEvents[k].combo
		if combo == "finisher" then
			total = 0
		else -- if type(combo) == "number" then
			total = total + combo
		end
		-- Clamp combo points to the maximum.
		if total > MAX_COMBO_POINTS then
			total = MAX_COMBO_POINTS
		end
	end
	return total
end

function OvaleComboPoints:DebugComboPoints()
	self:Print("Player has %d combo points.", self.combo)
end

-- Return the number of combo points required to cast the given spell.
-- NOTE: Mirrored in statePrototype below.
function OvaleComboPoints:ComboPointCost(spellId, atTime, targetGUID)
	OvaleComboPoints:StartProfiling("OvaleComboPoints_ComboPointCost")
	local spellCost = 0
	local spellRefund = 0
	local si = OvaleData.spellInfo[spellId]
	if si and si.combo then
		-- Get references to mirrored methods used.
		local GetAura, IsActiveAura
		local GetSpellInfoProperty
		local auraModule, dataModule
		GetAura, auraModule = self:GetMethod("GetAura", OvaleAura)
		IsActiveAura, auraModule = self:GetMethod("IsActiveAura", OvaleAura)
		GetSpellInfoProperty, dataModule = self:GetMethod("GetSpellInfoProperty", OvaleData)

		--[[
			combo == 0 means the that spell uses no resources.
			combo > 0 means that the spell generates combo points.
			combo < 0 means that the spell costs combo points.
			combo == "finisher" means that the spell uses all of the combo points (zeroes it out).
		--]]
		local cost = GetSpellInfoProperty(dataModule, spellId, atTime, "combo", targetGUID)
		if cost == "finisher" then
			-- This spell is a finisher so compute the cost based on the amount of resources consumed.
			cost = self:GetComboPoints()
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
				local aura = GetAura(auraModule, "player", buffExtra, nil, true)
				local isActiveAura = IsActiveAura(auraModule, aura, atTime)
				if isActiveAura then
					local buffAmount = si.buff_combo_amount or 1
					cost = cost + buffAmount
				end
			end
			cost = -1 * cost
		end
		spellCost = cost

		local refundParam = "refund_combo"
		local refund = GetSpellInfoProperty(dataModule, spellId, atTime, refundParam, targetGUID)
		if refund == "cost" then
			refund = spellCost
		end
		spellRefund = refund or 0
	end
	OvaleComboPoints:StopProfiling("OvaleComboPoints_ComboPointCost")
	return spellCost, spellRefund
end

-- Run-time check that the player has enough combo points.
-- NOTE: Mirrored in statePrototype below.
function OvaleComboPoints:RequireComboPointsHandler(spellId, atTime, requirement, tokens, index, targetGUID)
	local verified = false
	-- If index isn't given, then tokens holds the actual token value.
	local cost = tokens
	if index then
		cost = tokens[index]
		index = index + 1
	end
	if cost then
		cost = self:ComboPointCost(spellId, atTime, targetGUID)
		if cost > 0 then
			local power = self:GetComboPoints()
			if power >= cost then
				verified = true
			end
		else
			verified = true
		end
		if cost > 0 then
			local result = verified and "passed" or "FAILED"
			self:Log("    Require %d combo point(s) at time=%f: %s", cost, atTime, result)
		end
	else
		Ovale:OneTimeMessage("Warning: requirement '%s' is missing a cost argument.", requirement)
	end
	return verified, requirement, index
end

-- Copy combo point information from the spellcast to the destination table.
function OvaleComboPoints:CopySpellcastInfo(spellcast, dest)
	if spellcast.combo then
		dest.combo = spellcast.combo
	end
end

-- Save combo point finisher information to the spellcast.
function OvaleComboPoints:SaveSpellcastInfo(spellcast, atTime, state)
	local spellId = spellcast.spellId
	if spellId then
		local si = OvaleData.spellInfo[spellId]
		if si then
			local dataModule = state or OvaleData
			local comboPointModule = state or self
			if si.combo == "finisher" then
				local combo = dataModule:GetSpellInfoProperty(spellId, atTime, "combo", spellcast.target)
				if combo == "finisher" then
					local min_combo = si.min_combo or si.mincombo or 1
					if comboPointModule.combo >= min_combo then
						combo = comboPointModule.combo
					else
						combo = min_combo
					end
				elseif combo == 0 then
					-- If this is a finisher that costs no combo points, then treat it as a maximum combo-point finisher.
					combo = MAX_COMBO_POINTS
				end
				spellcast.combo = combo
			end
		end
	end
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
	self:StartProfiling("OvaleComboPoints_ResetState")
	state.combo = self:GetComboPoints()
	-- Scan the pending combo point events and remove the Anticipation buff if there is pending Anticipation event.
	for k = 1, #self_pendingComboEvents do
		local comboEvent = self_pendingComboEvents[k]
		if comboEvent.reason == "Anticipation" then
			state:RemoveAuraOnGUID(self_playerGUID, ANTICIPATION, "HELPFUL", true, comboEvent.atTime)
			break
		end
	end
	self:StopProfiling("OvaleComboPoints_ResetState")
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleComboPoints:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvaleComboPoints_ApplySpellAfterCast")
	local si = OvaleData.spellInfo[spellId]
	if si and si.combo then
		local cost, refund = state:ComboPointCost(spellId, endCast, targetGUID)
		local power = state.combo
		power = power - cost + refund
		-- Clamp combo points to lower and upper limits.
		if power <= 0 then
			power = 0
			-- Ruthlessness grants a 20% chance to grant a combo point for each combo point spent on a finishing move.
			if self_hasRuthlessness and state.combo == MAX_COMBO_POINTS then
				state:Log("Spell %d grants one extra combo point from Ruthlessness.", spellId)
				power = power + 1
			end
			-- Anticipation causes offensive finishing moves to consume all Anticipation charges and to grant a combo point for each.
			if self_hasAnticipation and state.combo > 0 then
				local aura = state:GetAuraByGUID(self_playerGUID, ANTICIPATION, "HELPFUL", true)
				if state:IsActiveAura(aura, endCast) then
					power = power + aura.stacks
					state:RemoveAuraOnGUID(self_playerGUID, ANTICIPATION, "HELPFUL", true, endCast)
					-- Anticipation charges that are consumed to grant combo points don't overflow into new Anticipation charges.
					if power > MAX_COMBO_POINTS then
						power = MAX_COMBO_POINTS
					end
				end
			end
		end
		if power > MAX_COMBO_POINTS then
			--[[
				If a rogue is talented into Anticipation, then any combo points over
				MAX_COMBO_POINTS are added to the Anticipation charges on the player
				to a maximum of MAX_COMBO_POINTS charges.

				If a spell is flagged with "temp_combo=1", then any combo points it
				grants cannot overflow into Anticipation charges.
			--]]
			if self_hasAnticipation and not si.temp_combo then
				local stacks = power - MAX_COMBO_POINTS
				-- Look for a pre-existing Anticipation buff and add to its stack count.
				local aura = state:GetAuraByGUID(self_playerGUID, ANTICIPATION, "HELPFUL", true)
				if state:IsActiveAura(aura, endCast) then
					stacks = stacks + aura.stacks
					if stacks > MAX_COMBO_POINTS then
						stacks = MAX_COMBO_POINTS
					end
				end
				-- Add a new Anticipation buff with the updated start, ending, stacks information.
				local start = endCast
				local ending = start + ANTICIPATION_DURATION
				aura = state:AddAuraToGUID(self_playerGUID, ANTICIPATION, self_playerGUID, "HELPFUL", nil, start, ending)
				aura.stacks = stacks
			end
			power = MAX_COMBO_POINTS
		end
		state.combo = power
	end
	self:StopProfiling("OvaleComboPoints_ApplySpellAfterCast")
end
--</public-static-methods>

--<state-methods>
statePrototype.GetComboPoints = function(state)
	return state.combo
end

-- Mirrored methods.
statePrototype.ComboPointCost = OvaleComboPoints.ComboPointCost
statePrototype.RequireComboPointsHandler = OvaleComboPoints.RequireComboPointsHandler
--</state-methods>
