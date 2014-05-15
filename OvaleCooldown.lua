--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleCooldown = Ovale:NewModule("OvaleCooldown", "AceEvent-3.0")
Ovale.OvaleCooldown = OvaleCooldown

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleGUID = nil
local OvalePaperDoll = nil
local OvaleStance = nil
local OvaleState = nil

local API_GetSpellCharges = GetSpellCharges
local API_GetSpellCooldown = GetSpellCooldown
local API_UnitHealth = UnitHealth
local API_UnitHealthMax = UnitHealthMax
local API_UnitClass = UnitClass

-- Player's class.
local _, self_class = API_UnitClass("player")
-- Current age of cooldown state.
local self_serial = 0
--</private-static-properties>

--<public-static-methods>
function OvaleCooldown:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvaleGUID = Ovale.OvaleGUID
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvaleStance = Ovale.OvaleStance
	OvaleState = Ovale.OvaleState
end

function OvaleCooldown:OnEnable()
	self:RegisterEvent("SPELL_UPDATE_CHARGES", "Update")
	self:RegisterEvent("SPELL_UPDATE_USABLE", "Update")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "Update")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "Update")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "Update")
	self:RegisterEvent("UNIT_SPELLCAST_START", "Update")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "Update")
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvaleCooldown:OnDisable()
	OvaleState:UnregisterState(self)
	self:UnregisterEvent("SPELL_UPDATE_CHARGES")
	self:UnregisterEvent("SPELL_UPDATE_USABLE")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:UnregisterEvent("UNIT_SPELLCAST_START")
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function OvaleCooldown:Update()
	-- Advance age of current cooldown state.
	self_serial = self_serial + 1
end

-- Return the GCD after the given spellId is cast.
-- If no spellId is given, then returns the GCD after a "yellow-hit" ability has been cast.
function OvaleCooldown:GetGCD(spellId)
	-- Base global cooldown.
	local cd
	local isCaster = false
	if self_class == "DEATHKNIGHT" then
		cd = 1.0
	elseif self_class == "DRUID" and OvaleStance:IsStance("druid_cat_form") then
		cd = 1.0
	elseif self_class == "HUNTER" then
		cd = 1.0
	elseif self_class == "MONK" then
		cd = 1.0
	elseif self_class == "ROGUE" then
		cd = 1.0
	else
		isCaster = true
		cd = 1.5
	end

	-- Use SpellInfo() information if available.
	if spellId and OvaleData.spellInfo[spellId] then
		local si = OvaleData.spellInfo[spellId]
		if si.gcd then
			return si.gcd
		end
		if si.haste then
			if si.haste == "melee" then
				cd = cd / OvalePaperDoll:GetMeleeHasteMultiplier()
			elseif si.haste == "ranged" then
				cd = cd / OvalePaperDoll:GetRangedHasteMultiplier()
			elseif si.haste == "spell" then
				cd = cd / OvalePaperDoll:GetSpellHasteMultiplier()
			end
		end
	elseif isCaster then
		cd = cd / OvalePaperDoll:GetSpellHasteMultiplier()
	end

	-- Clamp GCD at 1s.
	cd = (cd > 1) and cd or 1
	return cd
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleCooldown.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleCooldown.statePrototype
--</private-static-properties>

--<state-properties>
statePrototype.cd = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleCooldown:InitializeState(state)
	state.cd = {}
end

-- Reset the state to the current conditions.
function OvaleCooldown:ResetState(state)
	for _, cd in pairs(state.cd) do
		-- Remove outdated cooldown state.
		if cd.serial and cd.serial < self_serial then
			for k in pairs(cd) do
				cd[k] = nil
			end
		end
	end
end

-- Release state resources prior to removing from the simulator.
function OvaleCooldown:CleanState(state)
	for spellId, cd in pairs(state.cd) do
		for k in pairs(cd) do
			cd[k] = nil
		end
		state.cd[spellId] = nil
	end
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleCooldown:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast)
	local si = OvaleData.spellInfo[spellId]
	if si then
		local cd = state:GetCD(spellId)
		cd.start = isChanneled and startCast or endCast
		cd.duration = si.cd or 0
		cd.enable = 1

		-- If the spell has charges, then remove a charge.
		if cd.charges and cd.charges > 0 then
			cd.chargeStart = cd.start
			cd.charges = cd.charges - 1
			if cd.charges == 0 then
				cd.duration = cd.chargeDuration
			end
		end

		-- Test for no cooldown.
		if nocd then
			cd.duration = 0
		else
			-- There is no cooldown if the buff named by "buff_no_cd" parameter is present.
			local buffNoCooldown = si.buff_no_cd or si.buffnocd
			if buffNoCooldown then
				local aura = state:GetAura("player", buffNoCooldown)
				if state:IsActiveAura(aura, cd.start) then
					Ovale:Logf("buff_no_cd stacks = %s, start = %s, ending = %s, cd.start = %f", aura.stacks, aura.start, aura.ending, cd.start)
					cd.duration = 0
				end
			end

			-- There is no cooldown if the target's health percent is below what's specified
			-- with the "target_health_pct_no_cd" parameter.
			local target = OvaleGUID:GetUnitId(targetGUID)
			local targetHealthPctNoCooldown = si.target_health_pct_no_cd or si.targetlifenocd
			if target and targetHealthPctNoCooldown then
				local healthPercent = API_UnitHealth(target) / API_UnitHealthMax(target) * 100
				if healthPercent < targetHealthPctNoCooldown then
					cd.duration = 0
				end
			end
		end

		-- Adjust cooldown duration if it is affected by haste: "cd_haste=melee" or "cd_haste=spell".
		if cd.duration > 0 and si.cd_haste then
			if si.cd_haste == "melee" then
				cd.duration = cd.duration / state:GetMeleeHasteMultiplier(spellcast.snapshot)
			elseif si.haste == "ranged" then
				cd.duration = cd.duration / OvalePaperDoll:GetSpellHasteMultiplier()
			elseif si.cd_haste == "spell" then
				cd.duration = cd.duration / state:GetSpellHasteMultiplier(spellcast.snapshot)
			end
		end

		Ovale:Logf("Spell %d cooldown info: start=%f, duration=%f", spellId, cd.start, cd.duration)
	end
end
--</public-static-methods>

--<state-methods>
statePrototype.DebugCooldown = function(state)
	for spellId, cd in pairs(state.cd) do
		if cd.start then
			if cd.charges then
				Ovale:FormatPrint("Spell %s cooldown: start=%f, duration=%f, charges=%d, maxCharges=%d, chargeStart=%f, chargeDuration=%f",
					spellId, cd.start, cd.duration, cd.charges, cd.start, cd.duration)
			else
				Ovale:FormatPrint("Spell %s cooldown: start=%f, duration=%f", spellId, cd.start, cd.duration)
			end
		end
	end
end

-- Return the table holding the simulator's cooldown information for the given spell.
statePrototype.GetCD = function(state, spellId)
	local cdName = spellId
	local si = OvaleData.spellInfo[spellId]
	if si and si.sharedcd then
		cdName = si.sharedcd
	end
	if not state.cd[cdName] then
		state.cd[cdName] = {}
	end

	-- Populate the cooldown information from the current game state if it is outdated.
	local cd = state.cd[cdName]
	if not cd.start or not cd.serial or cd.serial < self_serial then
		local start, duration, enable = API_GetSpellCooldown(spellId)
		if start and start > 0 then
			charges = 0
		end
		if si and si.forcecd then
			if si.forcecd then
				start, duration = API_GetSpellCooldown(si.forcecd)
			end
		end
		cd.serial = self_serial
		cd.start = start
		cd.duration = duration
		cd.enable = enable

		local charges, maxCharges, chargeStart, chargeDuration = API_GetSpellCharges(spellId)
		if charges then
			cd.charges = charges
			cd.maxCharges = maxCharges
			cd.chargeStart = chargeStart
			cd.chargeDuration = chargeDuration
		end
	end

	-- Advance the cooldown state to the current time.
	local now = state.currentTime
	if cd.start then
		if cd.start + cd.duration <= now then
			cd.start = 0
			cd.duration = 0
		end
	end
	if cd.charges then
		local charges, maxCharges, chargeStart, chargeDuration = cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration
		while chargeStart + chargeDuration <= now and charges < maxCharges do
			chargeStart = chargeStart + chargeDuration
			charges = charges + 1
		end
		cd.charges = charges
		cd.chargeStart = chargeStart
	end

	return cd
end

-- Return the cooldown for the spell in the simulator.
statePrototype.GetSpellCooldown = function(state, spellId)
	local cd = state:GetCD(spellId)
	return cd.start, cd.duration, cd.enable
end

-- Return the information on the number of charges for the spell in the simulator.
statePrototype.GetSpellCharges = function(state, spellId)
	local cd = state:GetCD(spellId)
	return cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration
end

-- Force the cooldown of a spell to reset at the specified time.
statePrototype.ResetSpellCooldown = function(state, spellId, atTime)
	local now = state.currentTime
	if atTime >= now then
		local cd = state:GetCD(spellId)
		if cd.start + cd.duration > now then
			cd.start = now
			cd.duration = atTime - now
		end
	end
end
--</state-methods>
