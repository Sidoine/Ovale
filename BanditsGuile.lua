--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]-------------------------------------------------------------------

--[[
	This addon tracks the hidden stacking damage buff from Bandit's Guile
	on a combat rogue.

	Bandit's Guile description from wowhead.com:

		Take advantage of the natural ebb and flow of combat, causing your
		Sinister Strike to gradually increase your damage dealt by up to 30%.
		This maximum effect will last for 15 sec before fading and beginning
		the cycle anew.

	Mechanically, there is a hidden buff that stacks up to 12.  At 4 stacks,
	the rogue gains Shallow Insight (10% increased damage).  At 8 stacks, the
	rogue gains Moderate Insight (20% increased damage).  At 12 stacks, the
	rogue gains Deep Insight (30% increased damage).

	This addon manages the hidden aura in OvaleAura using events triggered by
	attacking with Sinister Strike or by changes to the	Insight auras on the
	player.  The aura ID of the hidden aura is set to 84654, the spell ID of
	Bandit's Guile, and can be checked like any other aura using OvaleAura's
	public or state methods.
--]]

local OVALE, Ovale = ...
local OvaleBanditsGuile = Ovale:NewModule("OvaleBanditsGuile", "AceEvent-3.0")
Ovale.OvaleBanditsGuile = OvaleBanditsGuile

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleAura = nil

local API_GetTime = GetTime
local API_UnitClass = UnitClass
local API_UnitGUID = UnitGUID
local INFINITY = math.huge

-- Player's class.
local _, self_class = API_UnitClass("player")
-- Player's GUID.
local self_guid = nil

-- Aura IDs for visible buff from Bandit's Guile.
local SHALLOW_INSIGHT = 84745
local MODERATE_INSIGHT = 84746
local DEEP_INSIGHT = 84747
-- Bandit's Guile spell ID.
local BANDITS_GUILE = 84654
-- Spell IDs for abilities that proc Bandit's Guile.
local BANDITS_GUILE_ATTACK = {
	[ 1752] = "Sinister Strike",
}
--</private-static-properties>

--<public-static-properties>
OvaleBanditsGuile.spellName = "Bandit's Guile"
-- Bandit's Guile spell ID from spellbook; re-used as the aura ID of the hidden, stacking buff.
OvaleBanditsGuile.spellId = BANDITS_GUILE
OvaleBanditsGuile.start = 0
OvaleBanditsGuile.ending = INFINITY
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

-- This event handler uses CLEU to track Bandit's Guile before it has procced any level of the
-- Insight buff.
function OvaleBanditsGuile:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
	if sourceGUID == self_guid and cleuEvent == "SPELL_DAMAGE" and self.stacks < 3 then
		local spellId, multistrike = arg12, arg25
		if BANDITS_GUILE_ATTACK[spellId] and not multistrike then
			local now = API_GetTime()
			self.start = now
			self.ending = self.start + self.duration
			self.stacks = self.stacks + 1
			self:GainedAura(now)
		end
	end
end

-- This event handler uses Ovale_AuraAdded to track the Insight buff being applied for the first
-- time and sets the implied stacks of Bandit's Guile.
function OvaleBanditsGuile:Ovale_AuraAdded(event, timestamp, target, auraId, caster)
	if target == self_guid then
		if auraId == SHALLOW_INSIGHT or auraId == MODERATE_INSIGHT or auraId == DEEP_INSIGHT then
			local aura = OvaleAura:GetAura("player", auraId, "HELPFUL", true)
			self.start, self.ending = aura.start, aura.ending

			-- Set stacks to count implied by seeing the given aura added to the player.
			if auraId == SHALLOW_INSIGHT then
				self.stacks = 4
			elseif auraId == MODERATE_INSIGHT then
				self.stacks = 8
			elseif auraId == DEEP_INSIGHT then
				self.stacks = 12
			end

			self:GainedAura(timestamp)
		end
	end
end

-- This event handler uses Ovale_AuraChanged to track refreshes of the Insight buff, which indicates
-- that it the hidden Bandit's Guile buff has gained extra stacks.
function OvaleBanditsGuile:Ovale_AuraChanged(event, timestamp, target, auraId, caster)
	if target == self_guid then
		if auraId == SHALLOW_INSIGHT or auraId == MODERATE_INSIGHT or auraId == DEEP_INSIGHT then
			local aura = OvaleAura:GetAura("player", auraId, "HELPFUL", true)
			self.start, self.ending = aura.start, aura.ending

			-- A changed Insight buff also means that the Bandit's Guile hidden buff gained a stack.
			self.stacks = self.stacks + 1

			self:GainedAura(timestamp)
		end
	end
end

function OvaleBanditsGuile:Ovale_AuraRemoved(event, timestamp, target, auraId, caster)
	if target == self_guid then
		if (auraId == SHALLOW_INSIGHT and self.stacks < 8)
				or (auraId == MODERATE_INSIGHT and self.stacks < 12)
				or auraId == DEEP_INSIGHT then
			self.ending = timestamp
			self.stacks = 0
			OvaleAura:LostAuraOnGUID(self_guid, timestamp, self.spellId, self_guid)
		end
	end
end

function OvaleBanditsGuile:GainedAura(atTime)
	OvaleAura:GainedAuraOnGUID(self_guid, atTime, self.spellId, self_guid, "HELPFUL", nil, nil, self.stacks, nil, self.duration, self.ending, nil, self.spellName, nil, nil, nil)
end

function OvaleBanditsGuile:DebugBanditsGuile()
	local aura = OvaleAura:GetAuraByGUID(self_guid, self.spellId, "HELPFUL", true)
	if aura then
		self:Print("Player has Bandit's Guile aura with start=%s, end=%s, stacks=%d.", aura.start, aura.ending, aura.stacks)
	end
end
--</public-static-methods>
