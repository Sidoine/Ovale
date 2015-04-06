--[[--------------------------------------------------------------------
    Copyright (C) 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]-------------------------------------------------------------------

--[[
	This addon tracks the status of the buff from Steady Focus on a MM hunter.

	Steady Focus description from wowhead.com:

		Using Steady Shot twice in a row increases your Focus Regeneration by
		50% for 10 sec.

	Mechanically, there is a hidden buff that is added after a Steady Shot is
	fired that is cleared if any other ranged attack other than Steady Shot
	is fired next.

	This addon manages the hidden aura in OvaleAura using events triggered by
	attacking with ranged attacks.  The aura ID of the hidden aura is set to
	53224, the spell ID of Steady Focus, and can be checked like any other
	aura using OvaleAura's public or state methods.
--]]

local OVALE, Ovale = ...
local OvaleSteadyFocus = Ovale:NewModule("OvaleSteadyFocus", "AceEvent-3.0")
Ovale.OvaleSteadyFocus = OvaleSteadyFocus

--<private-static-properties>
local OvaleDebug = Ovale.OvaleDebug
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleAura = nil
local OvaleSpellBook = nil
local OvaleState = nil

local API_GetTime = GetTime
local INFINITY = math.huge

-- Player's GUID.
local self_playerGUID = nil

-- Steady Focus talent spell ID; re-used as the aura ID of the hidden buff.
local PRE_STEADY_FOCUS = 177667
-- Steady Focus talent ID.
local STEADY_FOCUS_TALENT = 10
-- Steady Focus aura ID for visible buff.
local STEADY_FOCUS = 177668
-- Steady Focus buff duration in seconds.
local STEADY_FOCUS_DURATION = 15
-- Steady Shot spell ID.
local STEADY_SHOT = {
	[ 56641] = "Steady Shot",
	[ 77767] = "Cobra Shot",
	[163485] = "Focusing Shot",
}
-- Spell IDs of abilities that clear "pre-Steady Focus".
local RANGED_ATTACKS = {
	[  2643] = "Multi-Shot",
	[  3044] = "Arcane Shot",
	[ 19434] = "Aimed Shot",
	[ 19801] = "Tranquilizing Shot",
	[ 53209] = "Chimaera Shot",
	[ 53351] = "Kill Shot",
	[109259] = "Powershot",
	[117050] = "Glaive Toss",
	[120360] = "Barrage",
	[120361] = "Barrage",
	[120761] = "Glaive Toss",
	[121414] = "Glaive Toss",
}

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvaleSteadyFocus)
-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleSteadyFocus)
--</private-static-properties>

--<public-static-properties>
OvaleSteadyFocus.hasSteadyFocus = nil
OvaleSteadyFocus.spellName = "Pre-Steady Focus"
-- Steady Focus talent spell ID; re-used as the aura ID of the hidden buff.
OvaleSteadyFocus.spellId = PRE_STEADY_FOCUS
OvaleSteadyFocus.start = 0
OvaleSteadyFocus.ending = 0
OvaleSteadyFocus.duration = INFINITY
OvaleSteadyFocus.stacks = 0
--</public-static-properties>

--<public-static-methods>
function OvaleSteadyFocus:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleState = Ovale.OvaleState
end

function OvaleSteadyFocus:OnEnable()
	if Ovale.playerClass == "HUNTER" then
		self_playerGUID = Ovale.playerGUID
		self:RegisterMessage("Ovale_TalentsChanged")
		OvaleState:RegisterState(self, self.statePrototype)
	end
end

function OvaleSteadyFocus:OnDisable()
	if Ovale.playerClass == "HUNTER" then
		OvaleState:UnregisterState(self)
		self:UnregisterMessage("Ovale_TalentsChanged")
	end
end

function OvaleSteadyFocus:UNIT_SPELLCAST_SUCCEEDED(event, unitId, spell, rank, lineId, spellId)
	if unitId == "player" then
		self:StartProfiling("OvaleSteadyFocus_UNIT_SPELLCAST_SUCCEEDED")
		if STEADY_SHOT[spellId] then
			self:DebugTimestamp("Spell %s (%d) successfully cast.", spell, spellId)
			if self.stacks == 0 then
				local now = API_GetTime()
				self:GainedAura(now)
			end
		elseif RANGED_ATTACKS[spellId] and self.stacks > 0 then
			local now = API_GetTime()
			self:DebugTimestamp("Spell %s (%d) successfully cast.", spell, spellId)
			self:LostAura(now)
		end
		self:StopProfiling("OvaleSteadyFocus_UNIT_SPELLCAST_SUCCEEDED")
	end
end

function OvaleSteadyFocus:Ovale_AuraAdded(event, timestamp, target, auraId, caster)
	if self.stacks > 0 and auraId == STEADY_FOCUS and target == self_playerGUID then
		self:DebugTimestamp("Gained Steady Focus buff.")
		self:LostAura(timestamp)
	end
end

-- Only register for events to track shots if the Steady Focus talent is enabled.
function OvaleSteadyFocus:Ovale_TalentsChanged(event)
	self.hasSteadyFocus = (OvaleSpellBook:GetTalentPoints(STEADY_FOCUS_TALENT) > 0)
	if self.hasSteadyFocus then
		self:Debug("Registering event handlers to track Steady Focus.")
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		self:RegisterMessage("Ovale_AuraAdded")
		self:RegisterMessage("Ovale_AuraChanged", "Ovale_AuraAdded")
	else
		self:Debug("Unregistering event handlers to track Steady Focus.")
		self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		self:UnregisterMessage("Ovale_AuraAdded")
		self:UnregisterMessage("Ovale_AuraChanged")
	end
end

function OvaleSteadyFocus:GainedAura(atTime)
	self:StartProfiling("OvaleSteadyFocus_GainedAura")
	self.start = atTime
	self.ending = self.start + self.duration
	self.stacks = self.stacks + 1
	self:Debug("Gaining %s buff at %s.", self.spellName, atTime)
	OvaleAura:GainedAuraOnGUID(self_playerGUID, self.start, self.spellId, self_playerGUID, "HELPFUL", nil, nil, self.stacks, nil, self.duration, self.ending, nil, self.spellName, nil, nil, nil)
	self:StopProfiling("OvaleSteadyFocus_GainedAura")
end

function OvaleSteadyFocus:LostAura(atTime)
	self:StartProfiling("OvaleSteadyFocus_LostAura")
	self.ending = atTime
	self.stacks = 0
	self:Debug("Losing %s buff at %s.", self.spellName, atTime)
	OvaleAura:LostAuraOnGUID(self_playerGUID, atTime, self.spellId, self_playerGUID)
	self:StopProfiling("OvaleSteadyFocus_LostAura")
end

function OvaleSteadyFocus:DebugSteadyFocus()
	local aura = OvaleAura:GetAuraByGUID(self_playerGUID, self.spellId, "HELPFUL", true)
	if aura then
		self:Print("Player has pre-Steady Focus aura with start=%s, end=%s, stacks=%d.", aura.start, aura.ending, aura.stacks)
	else
		self:Print("Player has no pre-Steady Focus aura!")
	end
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleSteadyFocus.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleSteadyFocus.statePrototype
--</private-static-properties>

--<public-static-methods>
-- Apply the effects of the spell when the spellcast completes.
function OvaleSteadyFocus:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, channel, spellcast)
	if self.hasSteadyFocus then
		self:StartProfiling("OvaleSteadyFocus_ApplySpellAfterCast")
		if STEADY_SHOT[spellId] then
			--[[
				If player cast Steady Shot, then check if the Pre-Steady Focus buff
				is already present.  If it is, then remove it and add or refresh the
				Steady Focus buff; otherwise, add a Pre-Steady Focus buff.
			--]]
			local aura = state:GetAuraByGUID(self_playerGUID, self.spellId, "HELPFUL", true)
			if state:IsActiveAura(aura, endCast) then
				-- Remove the existing Pre-Steady Focus buff.
				state:RemoveAuraOnGUID(self_playerGUID, self.spellId, "HELPFUL", true, endCast)
				-- Add or refresh the Steady Focus buff.
				aura = state:GetAuraByGUID(self_playerGUID, STEADY_FOCUS, "HELPFUL", true)
				if not aura then
					aura = state:AddAuraToGUID(self_playerGUID, STEADY_FOCUS, self_playerGUID, "HELPFUL", nil, endCast, nil, spellcast)
				end
				aura.start = endCast
				aura.duration = STEADY_FOCUS_DURATION
				aura.ending = endCast + STEADY_FOCUS_DURATION
				aura.gain = endCast
			else
				local ending = endCast + self.duration
				aura = state:AddAuraToGUID(self_playerGUID, self.spellId, self_playerGUID, "HELPFUL", nil, endCast, ending, spellcast)
				aura.name = self.spellName
			end
		elseif RANGED_ATTACKS[spellId] then
			-- Remove any existing Pre-Steady Focus buff.
			state:RemoveAuraOnGUID(self_playerGUID, self.spellId, "HELPFUL", true, endCast)
		end
		self:StopProfiling("OvaleSteadyFocus_ApplySpellAfterCast")
	end
end
--</public-static-methods>
