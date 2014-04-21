--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
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

-- Steady Focus spell ID from spellbook; re-used has as the aura ID of the hidden buff.
local PRE_STEADY_FOCUS = 53224
-- Steady Focus aura ID for visible buff.
local STEADY_FOCUS = 53220
-- Steady Shot spell Id.
local STEADY_SHOT = 56641
-- Spell IDs of abilities that clear "pre-Steady Focus".
local RANGED_ATTACKS_MM = {
	[  1978] = "Serpent Sting",
	[  2643] = "Multi-Shot",
	[  3044] = "Arcane Shot",
	[ 13813] = "Explosive Trap",
	[ 19434] = "Aimed Shot",
	[ 19503] = "Scatter Shot",
	[ 34490] = "Silencing Shot",
	[ 53209] = "Chimera Shot",
	[ 53351] = "Kill Shot",
	[109259] = "Powershot",
	[117050] = "Glaive Toss",
}
--</private-static-properties>

--<public-static-properties>
OvaleSteadyFocus.start = 0
OvaleSteadyFocus.ending = 0
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
	if sourceGUID == self_guid and cleuEvent == "SPELL_DAMAGE" then
		local spellId = arg12
		if spellId == STEADY_SHOT and self.stacks == 0 then			
			local now = API_GetTime()
			if now - self.ending > 1 then
				self:GainedAura(now)
			end
		elseif RANGED_ATTACKS_MM[spellId] and self.stacks > 0 then
			local now = API_GetTime()
			self:LostAura(now)
		end
	end
end

function OvaleSteadyFocus:Ovale_AuraAdded(event, timestamp, target, auraId, caster)
	if target == self_guid and auraId == STEADY_FOCUS and self.stacks > 0 then
		self:LostAura(timestamp)
	end
end

function OvaleSteadyFocus:GainedAura(atTime)
	self.start = atTime
	self.ending = math.huge
	self.stacks = self.stacks + 1
	OvaleAura:GainedAuraOnGUID(self_guid, self.start, PRE_STEADY_FOCUS, self_guid, "HELPFUL", nil, nil, 1, nil, math.huge, self.ending, nil, "Pre-Steady Focus", nil, nil, nil)
end

function OvaleSteadyFocus:LostAura(atTime)
	self.ending = atTime
	self.stacks = 0
	OvaleAura:LostAuraOnGUID(self_guid, atTime, PRE_STEADY_FOCUS, self_guid)
end

function OvaleSteadyFocus:Debug()
	local aura = OvaleAura:GetAuraByGUID(self_guid, PRE_STEADY_FOCUS, "HELPFUL", true)
	if aura then
		Ovale:FormatPrint("Player has pre-Steady Focus aura with start=%s, end=%s, stacks=%d.", aura.start, aura.ending, aura.stacks)
	else
		Ovale:Print("Player has no pre-Steady Focus aura!")
	end
end
--</public-static-methods>
