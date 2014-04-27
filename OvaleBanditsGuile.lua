--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013, 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]-------------------------------------------------------------------

--[[
	This addon tracks the hidden stacking damage buff from Bandit's Guile
	on a combat rogue.

	Bandit's Guile description from wowhead.com:

		Your training allows you to recognize and take advantage of the
		natural ebb and flow of combat.  Your Sinister Strike and Revealing
		Strike abilities increase your damage dealt by up to 30%.  After
		reaching this maximum, the effect will fade after 15 sec and the
		cycle will begin anew.

	Mechanically, there is a hidden buff that stacks up to 12.  At 4 stacks,
	the rogue gains Shallow Insight (10% increased damage).  At 8 stacks, the
	rogue gains Moderate Insight (20% increased damage).  At 12 stacks, the
	rogue gains Deep Insight (30% increased damage).

	This addon manages the hidden aura in OvaleAura using events triggered by
	either attacking with Sinister/Revealing Strike or by changes to the
	Insight auras on the player.  The aura ID of the hidden aura is set to
	84654, the spell ID of Bandit's Guile, and can be checked like any other
	aura using OvaleAura's public or state methods.
--]]

local _, Ovale = ...
local OvaleBanditsGuile = Ovale:NewModule("OvaleBanditsGuile", "AceEvent-3.0")
Ovale.OvaleBanditsGuile = OvaleBanditsGuile

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

-- Aura IDs for visible buff from Bandit's Guile.
local SHALLOW_INSIGHT = 84745
local MODERATE_INSIGHT = 84746
local DEEP_INSIGHT = 84747
-- Spell IDs for abilities that proc Bandit's Guile.
local REVEALING_STRIKE = 84617
local SINISTER_STRIKE = 1752
--</private-static-properties>

--<public-static-properties>
OvaleBanditsGuile.name = "Bandit's Guile"
-- Bandit's Guile spell ID from spellbook; re-used as the aura ID of the hidden, stacking buff.
OvaleBanditsGuile.spellId = 84654
OvaleBanditsGuile.start = 0
OvaleBanditsGuile.ending = math.huge
OvaleBanditsGuile.duration = 15
OvaleBanditsGuile.stacks = 0
--</public-static-properties>

--<public-static-methods>
function OvaleBanditsGuile:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
end

function OvaleBanditsGuile:OnEnable()
	if self_class == "ROGUE" then
		self_guid = API_UnitGUID("player")
		self:RegisterMessage("Ovale_SpecializationChanged")
	end
end

function OvaleBanditsGuile:OnDisable()
	if self_class == "ROGUE" then
		self:UnregisterMessage("Ovale_SpecializationChanged")
	end
end

function OvaleBanditsGuile:Ovale_SpecializationChanged(event, specialization, previousSpecialization)
	if specialization == "combat" then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterMessage("Ovale_AuraAdded")
		self:RegisterMessage("Ovale_AuraChanged")
		self:RegisterMessage("Ovale_AuraRemoved")
	else
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:UnregisterMessage("Ovale_AuraAdded")
		self:UnregisterMessage("Ovale_AuraChanged")
		self:UnregisterMessage("Ovale_AuraRemoved")
	end
end

function OvaleBanditsGuile:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23 = ...
	if sourceGUID == self_guid and cleuEvent == "SPELL_DAMAGE" and self.stacks < 4 then
		local spellId = arg12
		if spellId == REVEALING_STRIKE or spellID == SINISTER_STRIKE then
			local now = API_GetTime()
			self.start = now
			self.ending = now + INSIGHT_DURATION
			self.stacks = self.stacks + 1
			self:GainedAura(now)
		end
	end
end

function OvaleBanditsGuile:Ovale_AuraAdded(event, timestamp, target, auraId, caster)
	if target == self_guid then
		if auraId == SHALLOW_INSIGHT or auraId == MODERATE_INSIGHT or auraId == DEEP_INSIGHT then
			-- Unregister for CLEU since we can now track stacks using refreshes on Insight buffs.
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			-- Set stacks to count implied by seeing the given aura added to the player.
			if auraId == SHALLOW_INSIGHT then
				self.stacks = 4
			elseif auraId == MODERATE_INSIGHT then
				self.stacks = 8
			elseif auraId == DEEP_INSIGHT then
				self.stacks = 12
			end
			self.start, self.ending = OvaleAura:GetAura("player", auraId, "HELPFUL", true)
			self:GainedAura(timestamp)
		end
	end
end

function OvaleBanditsGuile:Ovale_AuraChanged(event, timestamp, target, auraId, caster)
	if target == self_guid then
		if auraId == SHALLOW_INSIGHT or auraId == MODERATE_INSIGHT or auraId == DEEP_INSIGHT then
			-- A changed Insight buff also means that the Bandit's Guile hidden buff gained a stack.
			self.stacks = self.stacks + 1
			self.start, self.ending = OvaleAura:GetAura("player", auraId, "HELPFUL", true)
			self:GainedAura(timestamp)
		end
	end
end

function OvaleBanditsGuile:Ovale_AuraRemoved(event, timestamp, target, auraId, caster)
	if target == self_guid then
		if (auraId == SHALLOW_INSIGHT and self.stacks < 8)
				or (auraId == MODERATE_INSIGHT and self.stacks < 12)
				or auraId == DEEP_INSIGHT then
			self.start = 0
			self.ending = math.huge
			self.stacks = 0
			self:LostAura(timestamp)
			-- Register for CLEU again to track the aura before reaching Shallow Insight.
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
	end
end

function OvaleBanditsGuile:GainedAura(atTime)
	atTime = atTime or API_GetTime()
	OvaleAura:GainedAuraOnGUID(self_guid, atTime, self.spellId, self_guid, "HELPFUL", nil, nil, self.stacks, nil, INSIGHT_DURATION, self.ending, nil, self.name, nil, nil, nil)
end

function OvaleBanditsGuile:LostAura(atTime)
	atTime = atTime or API_GetTime()
	OvaleAura:LostAuraOnGUID(self_guid, atTime, self.spellId, self_guid)
end

function OvaleBanditsGuile:Debug()
	local aura = OvaleAura:GetAuraByGUID(self_guid, self.spellId, "HELPFUL", true)
	Ovale:FormatPrint("Player has Bandit's Guile aura with start=%s, end=%s, stacks=%d.", aura.start, aura.ending, aura.stacks)
end
--</public-static-methods>
