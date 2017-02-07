--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleCooldown = Ovale:NewModule("OvaleCooldown", "AceEvent-3.0")
Ovale.OvaleCooldown = OvaleCooldown

--<private-static-properties>
local OvaleDebug = Ovale.OvaleDebug
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleFuture = nil
local OvaleGUID = nil
local OvalePaperDoll = nil
local OvaleSpellBook = nil
local OvaleStance = nil
local OvaleState = nil

local next = next
local pairs = pairs
local API_GetSpellCharges = GetSpellCharges
local API_GetSpellCooldown = GetSpellCooldown
local API_GetTime = GetTime

-- Spell ID for the dummy Global Cooldown spell.
local GLOBAL_COOLDOWN = 61304
-- This should be more than OvaleFuture's SIMULATOR_LAG.
local COOLDOWN_THRESHOLD = 0.10

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvaleCooldown)
-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleCooldown)

-- BASE_GCD[class] = { gcd, haste }
local BASE_GCD = {
	["DEATHKNIGHT"]	= { 1.5, "melee"  },
	["DEMONHUNTER"]	= { 1.5, "melee"  },
	["DRUID"]		= { 1.5, "spell"  },
	["HUNTER"]		= { 1.5, "ranged" },
	["MAGE"]		= { 1.5, "spell"  },
	["MONK"]		= { 1.0, false    },
	["PALADIN"]		= { 1.5, "spell"  },
	["PRIEST"]		= { 1.5, "spell"  },
	["ROGUE"]		= { 1.0, false    },
	["SHAMAN"]		= { 1.5, "spell"  },
	["WARLOCK"]		= { 1.5, "spell"  },
	["WARRIOR"]		= { 1.5, "melee"  },
}

--</private-static-properties>

--<public-static-properties>
-- Current age of cooldown state.
OvaleCooldown.serial = 0
-- Shared cooldown name (sharedcd) to spell table mapping.
OvaleCooldown.sharedCooldown = {}
-- Cached global cooldown information.
OvaleCooldown.gcd = {
	serial = 0,
	start = 0,
	duration = 0,
}

--</public-static-properties>

--<public-static-methods>
function OvaleCooldown:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvaleFuture = Ovale.OvaleFuture
	OvaleGUID = Ovale.OvaleGUID
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleStance = Ovale.OvaleStance
	OvaleState = Ovale.OvaleState
end

function OvaleCooldown:OnEnable()
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", "Update")
	self:RegisterEvent("BAG_UPDATE_COOLDOWN", "Update")
	self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN", "Update")
	self:RegisterEvent("SPELL_UPDATE_CHARGES", "Update")
	self:RegisterEvent("SPELL_UPDATE_USABLE", "Update")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "Update")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "Update")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:RegisterEvent("UNIT_SPELLCAST_START", "Update")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "Update")
	self:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", "Update")
	OvaleFuture:RegisterSpellcastInfo(self)
	OvaleState:RegisterState(self, self.statePrototype)
	OvaleData:RegisterRequirement("oncooldown", "RequireCooldownHandler", self)
end

function OvaleCooldown:OnDisable()
	OvaleState:UnregisterState(self)
	OvaleFuture:UnregisterSpellcastInfo(self)
	OvaleData:UnregisterRequirement("oncooldown")
	self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
	self:UnregisterEvent("PET_BAR_UPDATE_COOLDOWN")
	self:UnregisterEvent("SPELL_UPDATE_CHARGES")
	self:UnregisterEvent("SPELL_UPDATE_USABLE")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:UnregisterEvent("UNIT_SPELLCAST_START")
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:UnregisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
end

function OvaleCooldown:UNIT_SPELLCAST_INTERRUPTED(event, unit, name, rank, lineId, spellId)
	if unit == "player" or unit == "pet" then
		-- Age the current cooldown state.
		self:Update(event, unit)

		--[[
			Interrupted spells reset the global cooldown, but the GetSpellCooldown() on the
			GCD spell ID doesn't return accurate information until after some delay.

			Reset the global cooldown forcibly.
		--]]
		self:Debug("Resetting global cooldown.")
		local cd = self.gcd
		cd.start = 0
		cd.duration = 0
	end
end

function OvaleCooldown:Update(event, unit)
	if not unit or unit == "player" or unit == "pet" then
		-- Advance age of current cooldown state.
		self.serial = self.serial + 1
		Ovale.refreshNeeded[Ovale.playerGUID] = true
		self:Debug(event, self.serial)
	end
end

-- Empty out the sharedcd table.
function OvaleCooldown:ResetSharedCooldowns()
	for name, spellTable in pairs(self.sharedCooldown) do
		for spellId in pairs(spellTable) do
			spellTable[spellId] = nil
		end
	end
end

function OvaleCooldown:IsSharedCooldown(name)
	local spellTable = self.sharedCooldown[name]
	return (spellTable and next(spellTable) ~= nil)
end

function OvaleCooldown:AddSharedCooldown(name, spellId)
	self.sharedCooldown[name] = self.sharedCooldown[name] or {}
	self.sharedCooldown[name][spellId] = true
end

function OvaleCooldown:GetGlobalCooldown(now)
	local cd = self.gcd
	if not cd.start or not cd.serial or cd.serial < self.serial then
		now = now or API_GetTime()
		if now >= cd.start + cd.duration then
			cd.start, cd.duration = API_GetSpellCooldown(GLOBAL_COOLDOWN)
		end
	end
	return cd.start, cd.duration
end

-- Get the cooldown information for the given spell ID.  If given a shared cooldown name,
-- then cycle through all spells associated with that spell ID to find the cooldown
-- information.
function OvaleCooldown:GetSpellCooldown(spellId)
	local cdStart, cdDuration, cdEnable = 0, 0, 1
	if self.sharedCooldown[spellId] then
		for id in pairs(self.sharedCooldown[spellId]) do
			local start, duration, enable = self:GetSpellCooldown(id)
			if start then
				cdStart, cdDuration, cdEnable = start, duration, enable
				break
			end
		end
	else
		local start, duration, enable
		local index, bookType = OvaleSpellBook:GetSpellBookIndex(spellId)
		if index and bookType then
			start, duration, enable = API_GetSpellCooldown(index, bookType)
		else
			start, duration, enable = API_GetSpellCooldown(spellId)
		end
		if start and start > 0 then
			local gcdStart, gcdDuration = self:GetGlobalCooldown()
			if start + duration > gcdStart + gcdDuration then
				-- Spell is on cooldown.
				cdStart, cdDuration, cdEnable = start, duration, enable
			else
				-- GCD is active, so set the start to when the spell can next be cast.
				cdStart = start + duration
				cdDuration = 0
				cdEnable = enable
			end
		else
			-- Spell is ready now.
			cdStart, cdDuration, cdEnable = start or 0, duration, enable
		end
	end

	-- The game allows you to cast a spell a small time before it is really available, to compensate for lag.
	-- The COOLDOWN_THRESHOLD is used to take this in account
	return cdStart - COOLDOWN_THRESHOLD, cdDuration, cdEnable
end

-- Return the base GCD and caster status.
function OvaleCooldown:GetBaseGCD()
	local gcd, haste
	local baseGCD = BASE_GCD[Ovale.playerClass]
	if baseGCD then
		gcd, haste = baseGCD[1], baseGCD[2]
	else
		gcd, haste = 1.5, "spell"
	end
	return gcd, haste
end

-- Copy cooldown information from the spellcast to the destination table.
function OvaleCooldown:CopySpellcastInfo(spellcast, dest)
	if spellcast.offgcd then
		dest.offgcd = spellcast.offgcd
	end
end

-- Save cooldown information to the spellcast.
function OvaleCooldown:SaveSpellcastInfo(spellcast, atTime, state)
	local spellId = spellcast.spellId
	if spellId then
		local dataModule = state or OvaleData
		local gcd = dataModule:GetSpellInfoProperty(spellId, spellcast.start, "gcd", spellcast.target)
		if gcd and gcd == 0 then
			spellcast.offgcd = true
		end
	end
end

function OvaleCooldown:RequireCooldownHandler(spellId, atTime, requirement, tokens, index, targetGUID)
	local cdSpellId = tokens
	local verified = false
	if index then
		cdSpellId = tokens[index]
		index = index + 1
	end
	if cdSpellId then
		local cd = self:GetCD(cdSpellId)
		verified = cd.duration > 0
		local result = verified and "passed" or "FAILED"
		self:Log("    Require spell %s with cooldown at time=%f: %s (duration = %f)", cdSpellId, atTime, result, duration)
	else
		Ovale:OneTimeMessage("Warning: requirement '%s' is missing a spell argument.", requirement)
	end
	return verified, requirement, index
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
-- Table of cooldown information, indexed by spell ID.
statePrototype.cd = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleCooldown:InitializeState(state)
	state.cd = {}
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

-- Apply the effects of the spell at the start of the spellcast.
function OvaleCooldown:ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvaleCooldown_ApplySpellStartCast")
	-- Channeled spells trigger their cooldown the moment they begin casting.
	if isChanneled then
		state:ApplyCooldown(spellId, targetGUID, startCast)
	end
	self:StopProfiling("OvaleCooldown_ApplySpellStartCast")
end

-- Apply the effects of the spell when the spellcast completes.
function OvaleCooldown:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvaleCooldown_ApplySpellAfterCast")
	-- Instant and cast-time spells trigger their cooldown after the spellcast is complete.
	if not isChanneled then
		state:ApplyCooldown(spellId, targetGUID, endCast)
	end
	self:StopProfiling("OvaleCooldown_ApplySpellAfterCast")
end
--</public-static-methods>

--<state-methods>
statePrototype.ApplyCooldown = function(state, spellId, targetGUID, atTime)
	OvaleCooldown:StartProfiling("OvaleCooldown_state_ApplyCooldown")
	local cd = state:GetCD(spellId)
	local duration = state:GetSpellCooldownDuration(spellId, atTime, targetGUID)

	if duration == 0 then
		cd.start = 0
		cd.duration = 0
		cd.enable = 1
	else
		cd.start = atTime
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

	state:Log("Spell %d cooldown info: start=%f, duration=%f", spellId, cd.start, cd.duration)
	OvaleCooldown:StopProfiling("OvaleCooldown_state_ApplyCooldown")
end

statePrototype.DebugCooldown = function(state)
	for spellId, cd in pairs(state.cd) do
		if cd.start then
			if cd.charges then
				OvaleCooldown:Print("Spell %s cooldown: start=%f, duration=%f, charges=%d, maxCharges=%d, chargeStart=%f, chargeDuration=%f",
					spellId, cd.start, cd.duration, cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration)
			else
				OvaleCooldown:Print("Spell %s cooldown: start=%f, duration=%f", spellId, cd.start, cd.duration)
			end
		end
	end
end

-- Return the GCD after the given spell is cast.
-- If no spell is given, then returns the GCD after the current spell has been cast.
statePrototype.GetGCD = function(state, spellId, atTime, targetGUID)
	spellId = spellId or state.currentSpellId
	if not atTime then
		if state.endCast and state.endCast > state.currentTime then
			atTime = state.endCast
		else
			atTime = state.currentTime
		end
	end
	targetGUID = targetGUID or OvaleGUID:UnitGUID(state.defaultTarget)

	local gcd = spellId and state:GetSpellInfoProperty(spellId, atTime, "gcd", targetGUID)
	if not gcd then
		local haste
		gcd, haste = OvaleCooldown:GetBaseGCD()
		 
		if Ovale.playerClass == "MONK" and OvalePaperDoll:IsSpecialization("mistweaver") then
			-- Mistweaver Monk = 1.5, spell
			gcd = 1.5
			haste = "spell"
		elseif Ovale.playerClass == "DRUID" then
			if OvaleStance:IsStance("druid_cat_form") then
				-- Cat Form Druid = 1.0, false
				gcd = 1.0
				haste = false
			end
		-- Adrenaline Rush buffed Outlaw Rogue = 0.8, false (TODO)
		
		-- Possible Additional Exceptions. 
		-- Shouldn't be any differene between using melee haste or spell haste so didn't bother changing these.
		-- Bear Form Druid = 1.5, melee
		-- Retribution Paladin = 1.5, melee
		-- Protection Paladin = 1.5, melee
		-- Enhancement Shaman = 1.5, melee
		end
		local gcdHaste = spellId and state:GetSpellInfoProperty(spellId, atTime, "gcd_haste", targetGUID)
		if gcdHaste then
			haste = gcdHaste
		else
			local siHaste = spellId and state:GetSpellInfoProperty(spellId, atTime, "haste", targetGUID)
			if siHaste then
				haste = siHaste
			end
		end
		local multiplier = state:GetHasteMultiplier(haste)
		gcd = gcd / multiplier
		-- Clamp GCD at 750ms.
		gcd = (gcd > 0.750) and gcd or 0.750
	end
	return gcd
end

-- Return the table holding the simulator's cooldown information for the given spell.
statePrototype.GetCD = function(state, spellId)
	OvaleCooldown:StartProfiling("OvaleCooldown_state_GetCD")
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
	if not cd.start or not cd.serial or cd.serial < OvaleCooldown.serial then
		local start, duration, enable = OvaleCooldown:GetSpellCooldown(spellId)
		if si and si.forcecd then
			start, duration = OvaleCooldown:GetSpellCooldown(si.forcecd)
		end
		cd.serial = OvaleCooldown.serial
		cd.start = start - COOLDOWN_THRESHOLD
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

	OvaleCooldown:StopProfiling("OvaleCooldown_state_GetCD")
	return cd
end

-- Return the cooldown for the spell in the simulator.
statePrototype.GetSpellCooldown = function(state, spellId)
	local cd = state:GetCD(spellId)
	return cd.start, cd.duration, cd.enable
end

-- Get the duration of a spell's cooldown.  Returns either the current duration if
-- already on cooldown or the duration if cast at the specified time.
statePrototype.GetSpellCooldownDuration = function(state, spellId, atTime, targetGUID)
	local start, duration = state:GetSpellCooldown(spellId)
	if duration > 0 and start + duration > atTime then
		state:Log("Spell %d is on cooldown for %fs starting at %s.", spellId, duration, start)
	else
		local si = OvaleData.spellInfo[spellId]
		duration = state:GetSpellInfoProperty(spellId, atTime, "cd", targetGUID)
		if duration then
			if si and si.addcd then
				duration = duration + si.addcd
			end
			if duration < 0 then
				duration = 0
			end
		else
			duration = 0
		end
		state:Log("Spell %d has a base cooldown of %fs.", spellId, duration)
		if duration > 0 then
			-- Adjust cooldown duration if it is affected by haste: "cd_haste=melee" or "cd_haste=spell".
			local haste = state:GetSpellInfoProperty(spellId, atTime, "cd_haste", targetGUID)
			local multiplier = state:GetHasteMultiplier(haste)
			duration = duration / multiplier
			-- Adjust cooldown duration if it is affected by a cooldown reduction trinket: "buff_cdr=auraId".
			if si and si.buff_cdr then
				local aura = state:GetAura("player", si.buff_cdr)
				if state:IsActiveAura(aura, atTime) then
					duration = duration * aura.value1
				end
			end
		end
	end
	return duration
end

-- Return the information on the number of charges for the spell in the simulator.
statePrototype.GetSpellCharges = function(state, spellId, atTime)
	atTime = atTime or state.currentTime
	local cd = state:GetCD(spellId)
	local charges, maxCharges, chargeStart, chargeDuration = cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration
	-- Advance the spell charges state to the given time.
	if charges then
		while chargeStart + chargeDuration <= atTime and charges < maxCharges do
			chargeStart = chargeStart + chargeDuration
			charges = charges + 1
		end
	end
	return charges, maxCharges, chargeStart, chargeDuration
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

statePrototype.RequireCooldownHandler = OvaleCooldown.RequireCooldownHandler
--</state-methods>
