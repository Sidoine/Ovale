--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleCooldown = Ovale:NewModule("OvaleCooldown", "AceEvent-3.0")
Ovale.OvaleCooldown = OvaleCooldown

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleGUID = nil
local OvalePaperDoll = nil
local OvaleSpellBook = nil
local OvaleStance = nil
local OvaleState = nil

local next = next
local pairs = pairs
local API_GetSpellCharges = GetSpellCharges
local API_GetSpellCooldown = GetSpellCooldown
local API_UnitClass = UnitClass

-- Profiling set-up.
local Profiler = Ovale.Profiler
local profiler = nil
do
	local group = OvaleCooldown:GetName()

	local function EnableProfiling()
		API_GetSpellCharges = Profiler:Wrap(group, "OvaleCooldown_API_GetSpellCharges", GetSpellCharges)
		API_GetSpellCooldown = Profiler:Wrap(group, "OvaleCooldown_API_GetSpellCooldown", GetSpellCooldown)
		API_UnitHealth = Profiler:Wrap(group, "OvaleCooldown_API_UnitHealth", UnitHealth)
		API_UnitHealthMax = Profiler:Wrap(group, "OvaleCooldown_API_UnitHealthMax", UnitHealthMax)
	end

	local function DisableProfiling()
		API_GetSpellCharges = GetSpellCharges
		API_GetSpellCooldown = GetSpellCooldown
		API_UnitHealth = UnitHealth
		API_UnitHealthMax = UnitHealthMax
	end

	Profiler:RegisterProfilingGroup(group, EnableProfiling, DisableProfiling)
	profiler = Profiler:GetProfilingGroup(group)
end

-- Player's class.
local _, self_class = API_UnitClass("player")
-- Current age of cooldown state.
local self_serial = 0
-- Shared cooldown name (sharedcd) to spell table mapping.
local self_sharedCooldownSpells = {}

-- BASE_GCD[class] = { gcd, isCaster }
local BASE_GCD = {
	["DEATHKNIGHT"]	= { 1.0, false },
	["DRUID"]		= { 1.5,  true },
	["HUNTER"]		= { 1.0, false },
	["MAGE"]		= { 1.5,  true },
	["MONK"]		= { 1.5, false },
	["PALADIN"]		= { 1.5, false },
	["PRIEST"]		= { 1.5,  true },
	["ROGUE"]		= { 1.0, false },
	["SHAMAN"]		= { 1.5,  true },
	["WARLOCK"]		= { 1.5,  true },
	["WARRIOR"]		= { 1.5, false },
}

-- Spells that cause haste to affect the global cooldown.
local FOCUS_AND_HARMONY = 154555
local HEADLONG_RUSH = 158836
--</private-static-properties>

--<public-static-methods>
function OvaleCooldown:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvaleGUID = Ovale.OvaleGUID
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvaleSpellBook = Ovale.OvaleSpellBook
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

-- Empty out the sharedcd table.
function OvaleCooldown:ResetSharedCooldowns()
	for name, spellTable in pairs(self_sharedCooldownSpells) do
		for spellId in pairs(spellTable) do
			spellTable[spellId] = nil
		end
	end
end

function OvaleCooldown:IsSharedCooldown(name)
	local spellTable = self_sharedCooldownSpells[name]
	return (spellTable and next(spellTable) ~= nil)
end

function OvaleCooldown:AddSharedCooldown(name, spellId)
	self_sharedCooldownSpells[name] = self_sharedCooldownSpells[name] or {}
	self_sharedCooldownSpells[name][spellId] = true
end

-- Get the cooldown information for the given spell ID.  If given a shared cooldown name,
-- then cycle through all spells associated with that spell ID to find the cooldown
-- information.
function OvaleCooldown:GetSpellCooldown(spellId)
	local start, duration, enable
	if self_sharedCooldownSpells[spellId] then
		for id in pairs(self_sharedCooldownSpells[spellId]) do
			start, duration, enable = self:GetSpellCooldown(id)
			if start then break end
		end
	else
		local index, bookType = OvaleSpellBook:GetSpellBookIndex(spellId)
		if index and bookType then
			start, duration, enable = API_GetSpellCooldown(index, bookType)
		else
			start, duration, enable = API_GetSpellCooldown(spellId)
		end
	end
	return start, duration, enable
end

-- Return the base GCD and caster status.
function OvaleCooldown:GetBaseGCD()
	local gcd, isCaster
	local baseGCD = BASE_GCD[self_class]
	if baseGCD then
		gcd, isCaster = baseGCD[1], baseGCD[2]
	else
		gcd, isCaster = 1.5, true
	end
	if self_class == "DRUID" then
		if OvaleStance:IsStance("druid_cat_form") then
			gcd = 1.0
			isCaster = false
		elseif OvaleStance:IsStance("druid_bear_form") then
			isCaster = false
		end
	elseif self_class == "MONK" then
		if OvaleStance:IsStance("monk_stance_of_the_fierce_tiger") then
			gcd = 1.0
		elseif OvaleStance:IsStance("monk_stance_of_the_sturdy_ox") then
			gcd = 1.0
		else
			isCaster = true
		end
	end
	return gcd, isCaster
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
	profiler.Start("OvaleCooldown_ResetState")
	for _, cd in pairs(state.cd) do
		-- Remove outdated cooldown state.
		if cd.serial and cd.serial < self_serial then
			for k in pairs(cd) do
				cd[k] = nil
			end
		end
	end
	profiler.Stop("OvaleCooldown_ResetState")
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
function OvaleCooldown:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, spellcast)
	profiler.Start("OvaleCooldown_ApplySpellAfterCast")
	local cd = state:GetCD(spellId)

	local target = OvaleGUID:GetUnitId(targetGUID) or state.defaultTarget
	local start = isChanneled and startCast or endCast
	local duration = state:GetSpellCooldownDuration(spellId, start, target)

	local si = OvaleData.spellInfo[spellId]
	if duration == 0 then
		cd.start = 0
		cd.duration = 0
		cd.enable = 1
	else
		cd.start = start
		cd.duration = duration
		cd.enable = 1
	end

	-- If the spell has charges, then remove a charge.
	if cd.charges and cd.charges > 0 then
		cd.chargeStart = cd.start
		cd.charges = cd.charges - 1
		if cd.charges == 0 then
			cd.duration = cd.chargeDuration
		end
	end

	Ovale:Logf("Spell %d cooldown info: start=%f, duration=%f", spellId, cd.start, cd.duration)
	profiler.Stop("OvaleCooldown_ApplySpellAfterCast")
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

-- Return the GCD after the given spell is cast.
-- If no spell is given, then returns the GCD after the current spell has been cast.
statePrototype.GetGCD = function(state, spellId, target)
	spellId = spellId or state.currentSpellId
	local gcd = spellId and state:GetSpellInfoProperty(spellId, "gcd", target)
	if not gcd then
		local isCaster, haste
		gcd, isCaster = OvaleCooldown:GetBaseGCD()
		if self_class == "MONK" and OvaleSpellBook:IsKnownSpell(FOCUS_AND_HARMONY) then
			haste = "melee"
		elseif self_class == "WARRIOR" and OvaleSpellBook:IsKnownSpell(HEADLONG_RUSH) then
			haste = "melee"
		end
		local gcd_haste = spellId and state:GetSpellInfoProperty(spellId, "gcd_haste", target)
		if gcd_haste then
			haste = gcd_haste
		else
			local si_haste = spellId and state:GetSpellInfoProperty(spellId, "haste", target)
			if si_haste then
				haste = si_haste
			end
		end
		if not haste and isCaster then
			haste = "spell"
		end
		if haste == "melee" then
			gcd = gcd / state:GetMeleeHasteMultiplier()
		elseif haste == "ranged" then
			gcd = gcd / state:GetRangedHasteMultiplier()
		elseif haste == "spell" then
			gcd = gcd / state:GetSpellHasteMultiplier()
		end
		-- Clamp GCD at 1s.
		gcd = (gcd > 1) and gcd or 1
	end
	return gcd
end

-- Return the table holding the simulator's cooldown information for the given spell.
statePrototype.GetCD = function(state, spellId)
	profiler.Start("OvaleCooldown_state_GetCD")
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
		local start, duration, enable = OvaleCooldown:GetSpellCooldown(spellId)
		if si and si.forcecd then
			start, duration = OvaleCooldown:GetSpellCooldown(si.forcecd)
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

	profiler.Stop("OvaleCooldown_state_GetCD")
	return cd
end

-- Return the cooldown for the spell in the simulator.
statePrototype.GetSpellCooldown = function(state, spellId)
	local cd = state:GetCD(spellId)
	return cd.start, cd.duration, cd.enable
end

-- Get the duration of a spell's cooldown.  Returns either the current duration if
-- already on cooldown or the duration if cast at the specified time.
statePrototype.GetSpellCooldownDuration = function(state, spellId, atTime, target)
	local start, duration = state:GetSpellCooldown(spellId)
	if start + duration > atTime then
		Ovale:Logf("Spell %d is on cooldown for %fs starting at %s.", spellId, duration, start)
	else
		local si = OvaleData.spellInfo[spellId]
		if si and si.cd then
			duration = state:GetSpellInfoProperty(spellId, "cd", target)
			if si.addcd then
				duration = duration + si.addcd
			end
			if duration < 0 then
				duration = 0
			end
		else
			duration = 0
		end
		Ovale:Logf("Spell %d has a base cooldown of %fs.", spellId, duration)
		if duration > 0 then
			-- Adjust cooldown duration if it is affected by haste: "cd_haste=melee" or "cd_haste=spell".
			if si.cd_haste then
				local cd_haste = state:GetSpellInfoProperty(spellId, "cd_haste", target)
				if cd_haste == "melee" then
					duration = duration / state:GetMeleeHasteMultiplier()
				elseif cd_haste == "ranged" then
					duration = duration / OvalePaperDoll:GetSpellHasteMultiplier()
				elseif cd_haste == "spell" then
					duration = duration / state:GetSpellHasteMultiplier()
				end
			end
			-- Adjust cooldown duration if it is affected by a cooldown reduction trinket: "buff_cdr=auraId".
			if si.buff_cdr then
				local aura = state:GetAura("player", si.buff_cdr)
				if state:IsActiveAura(aura, atTime) then
					duration = duration / aura.value1
				end
			end
		end
	end
	return duration
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
