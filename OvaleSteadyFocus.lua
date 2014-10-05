--[[--------------------------------------------------------------------
    Copyright (C) 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]-------------------------------------------------------------------

--[[
	This addon tracks the status of the buff from Steady Focus on a MM hunter.

	Steady Focus description from wowhead.com:

		When you Steady Shot twice in a row, your ranged attack speed will
		be increased by 15% and your Steady Shot will generate 3 additional
		Focus for 20 sec.

	Mechanically, there is a hidden buff that is added after a Steady Shot is
	fired that is cleared if any other ranged attack other than Steady Shot
	is fired next.

	This addon manages the hidden aura in OvaleAura using events triggered by
	attacking with ranged attacks.  The aura ID of the hidden aura is set to
	53224, the spell ID of Steady Focus, and can be checked like any other
	aura using OvaleAura's public or state methods.
--]]

local _, Ovale = ...
local OvaleSteadyFocus = Ovale:NewModule("OvaleSteadyFocus", "AceEvent-3.0")
Ovale.OvaleSteadyFocus = OvaleSteadyFocus

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleAura = nil

local API_GetTime = GetTime
local API_UnitClass = UnitClass
local API_UnitGUID = UnitGUID

-- Player's class.
local _, self_class = API_UnitClass("player")
-- Player's GUID.
local self_guid = nil

-- Steady Focus aura ID for visible buff.
local STEADY_FOCUS = 53220
-- Steady Shot spell Id.
local STEADY_SHOT = 56641
-- Spell IDs of abilities that clear "pre-Steady Focus".
local RANGED_ATTACKS_DAMAGING = {
	[  1978] = "Serpent Sting",
	[  2643] = "Multi-Shot",
	[  3044] = "Arcane Shot",
	[ 19434] = "Aimed Shot",
	[ 19503] = "Scatter Shot",
	[ 53209] = "Chimera Shot",
	[ 53351] = "Kill Shot",
	[109259] = "Powershot",
	[117050] = "Glaive Toss",
	[120360] = "Barrage",
	[120361] = "Barrage",
	[120761] = "Glaive Toss",
	[121414] = "Glaive Toss",
}
local RANGED_ATTACKS_ON_CAST = {
	[ 19801] = "Tranquilizing Shot",
	[ 34490] = "Silencing Shot",
}
local RANGED_ATTACKS_BY_DEBUFF = {
	[118253] = "Serpent Sting",
}
--</private-static-properties>

--<public-static-properties>
OvaleSteadyFocus.spellName = "Pre-Steady Focus"
-- Steady Focus spell ID from spellbook; re-used as the aura ID of the hidden buff.
OvaleSteadyFocus.spellId = 53224
OvaleSteadyFocus.start = 0
OvaleSteadyFocus.start = 0
OvaleSteadyFocus.ending = 0
OvaleSteadyFocus.duration = math.huge
OvaleSteadyFocus.stacks = 0
--</public-static-properties>

--<public-static-methods>
function OvaleSteadyFocus:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
end

function OvaleSteadyFocus:OnEnable()
	if self_class == "HUNTER" then
		self_guid = API_UnitGUID("player")
		self:RegisterMessage("Ovale_SpecializationChanged")
	end
end

function OvaleSteadyFocus:OnDisable()
	if self_class == "HUNTER" then
		self:UnregisterMessage("Ovale_SpecializationChanged")
	end
end

function OvaleSteadyFocus:Ovale_SpecializationChanged(event, specialization, previousSpecialization)
	if specialization == "marksmanship" then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterMessage("Ovale_AuraAdded")
		self:RegisterMessage("Ovale_AuraChanged", "Ovale_AuraAdded")
	else
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:UnregisterMessage("Ovale_AuraAdded")
		self:UnregisterMessage("Ovale_AuraChanged")
	end
end

function OvaleSteadyFocus:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23 = ...
	if sourceGUID == self_guid then
		if cleuEvent == "SPELL_DAMAGE" then
			local spellId = arg12
			if spellId == STEADY_SHOT and self.stacks == 0 then
				local now = API_GetTime()
				if now - self.ending > 1 then
					self:GainedAura(now)
				end
			elseif RANGED_ATTACKS_DAMAGING[spellId] and self.stacks > 0 then
				local now = API_GetTime()
				self:LostAura(now)
			end
		elseif cleuEvent == "SPELL_CAST_SUCCESS" then
			local spellId = arg12
			if RANGED_ATTACKS_ON_CAST[spellId] and self.stacks > 0 then
				local now = API_GetTime()
				self:LostAura(now)
			end
		end
	end
end

function OvaleSteadyFocus:Ovale_AuraAdded(event, timestamp, target, auraId, caster)
	if self.stacks > 0 then
		if auraId == STEADY_FOCUS and target == self_guid then
			self:LostAura(timestamp)
		elseif RANGED_ATTACKS_BY_DEBUFF[auraId] and caster == self_guid then
			self:LostAura(timestamp)
		end
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

function OvaleSteadyFocus:Debug()
	local aura = OvaleAura:GetAuraByGUID(self_guid, self.spellId, "HELPFUL", true)
	if aura then
		Ovale:FormatPrint("Player has pre-Steady Focus aura with start=%s, end=%s, stacks=%d.", aura.start, aura.ending, aura.stacks)
	else
		Ovale:Print("Player has no pre-Steady Focus aura!")
	end
end
--</public-static-methods>
