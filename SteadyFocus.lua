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
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug

-- Forward declarations for module dependencies.
local OvaleAura = nil
local OvaleSpellBook = nil

local API_GetTime = GetTime
local API_UnitClass = UnitClass
local API_UnitGUID = UnitGUID
local INFINITY = math.huge

-- Player's class.
local _, self_class = API_UnitClass("player")
-- Player's GUID.
local self_guid = nil

-- Steady Focus talent ID.
local STEADY_FOCUS_TALENT = 10
-- Steady Focus aura ID for visible buff.
local STEADY_FOCUS = 177668
-- Steady Shot spell Id.
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
--</private-static-properties>

--<public-static-properties>
OvaleSteadyFocus.spellName = "Pre-Steady Focus"
-- Steady Focus talent spell ID; re-used as the aura ID of the hidden buff.
OvaleSteadyFocus.spellId = 177667
OvaleSteadyFocus.start = 0
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
end

function OvaleSteadyFocus:OnEnable()
	if self_class == "HUNTER" then
		self_guid = API_UnitGUID("player")
		self:RegisterMessage("Ovale_TalentsChanged")
	end
end

function OvaleSteadyFocus:OnDisable()
	if self_class == "HUNTER" then
		self:UnregisterMessage("Ovale_TalentsChanged")
	end
end

function OvaleSteadyFocus:UNIT_SPELLCAST_SUCCEEDED(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		if STEADY_SHOT[spellId] and self.stacks == 0 then
			local now = API_GetTime()
			if now - self.ending > 1 then
				self:Debug("Spell %d successfully cast to gain %s buff.", spellId, self.spellName)
				self:GainedAura(now)
			end
		elseif RANGED_ATTACKS[spellId] and self.stacks > 0 then
			local now = API_GetTime()
			self:Debug("Spell %d successfully cast to lose %s buff.", spellId, self.spellName)
			self:LostAura(now)
		end
	end
end

function OvaleSteadyFocus:Ovale_AuraAdded(event, timestamp, target, auraId, caster)
	if self.stacks > 0 and auraId == STEADY_FOCUS and target == self_guid then
		self:Debug("Gained Steady Focus buff.")
		self:LostAura(timestamp)
	end
end

-- Only register for events to track shots if the Steady Focus talent is enabled.
function OvaleSteadyFocus:Ovale_TalentsChanged(event)
	if OvaleSpellBook:GetTalentPoints(STEADY_FOCUS_TALENT) > 0 then
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
	self.start = atTime
	self.ending = self.start + self.duration
	self.stacks = self.stacks + 1
	OvaleAura:GainedAuraOnGUID(self_guid, self.start, self.spellId, self_guid, "HELPFUL", nil, nil, self.stacks, nil, self.duration, self.ending, nil, self.spellName, nil, nil, nil)
end

function OvaleSteadyFocus:LostAura(atTime)
	self.ending = atTime
	self.stacks = 0
	OvaleAura:LostAuraOnGUID(self_guid, atTime, self.spellId, self_guid)
end

function OvaleSteadyFocus:DebugSteadyFocus()
	local aura = OvaleAura:GetAuraByGUID(self_guid, self.spellId, "HELPFUL", true)
	if aura then
		self:Print("Player has pre-Steady Focus aura with start=%s, end=%s, stacks=%d.", aura.start, aura.ending, aura.stacks)
	else
		self:Print("Player has no pre-Steady Focus aura!")
	end
end
--</public-static-methods>
