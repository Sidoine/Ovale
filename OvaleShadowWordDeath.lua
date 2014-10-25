--[[--------------------------------------------------------------------
    Copyright (C) 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]-------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleShadowWordDeath = Ovale:NewModule("OvaleShadowWordDeath", "AceEvent-3.0")
Ovale.OvaleShadowWordDeath = OvaleShadowWordDeath

--[[
	Shadow Word: Death description from wowhead.com:

		If the target does not die, the cooldown is reset, but this additional
		Shadow Word: Death does not grant a Shadow Orb. This effect has a 9 second
		cooldown.

	Add a hidden buff when the player casts Shadow Word: Death and the target does
	not die.
--]]

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

-- Shadow Word: Death spell IDs.
local SHADOW_WORD_DEATH = {
	[ 32379] = true,
	[129176] = true,
}
--</private-static-properties>

--<public-static-properties>
OvaleShadowWordDeath.spellName = "Shadow Word: Death Reset Cooldown"
OvaleShadowWordDeath.spellId = 125927	-- spell ID to use for the hidden buff
OvaleShadowWordDeath.start = 0
OvaleShadowWordDeath.ending = 0
OvaleShadowWordDeath.duration = 9
OvaleShadowWordDeath.stacks = 0
--</public-static-properties>

--<public-static-methods>
function OvaleShadowWordDeath:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
end

function OvaleShadowWordDeath:OnEnable()
	if self_class == "PRIEST" then
		self_guid = API_UnitGUID("player")
		self:RegisterMessage("Ovale_SpecializationChanged")
	end
end

function OvaleShadowWordDeath:OnDisable()
	if self_class == "PRIEST" then
		self:UnregisterMessage("Ovale_SpecializationChanged")
	end
end

function OvaleShadowWordDeath:Ovale_SpecializationChanged(event, specialization, previousSpecialization)
	if specialization == "shadow" then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

function OvaleShadowWordDeath:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
	if sourceGUID == self_guid then
		if cleuEvent == "SPELL_DAMAGE" then
			local spellId, overkill = arg12, arg16
			if SHADOW_WORD_DEATH[spellId] and not (overkill and overkill > 0) then
				local now = API_GetTime()
				self.start = now
				self.ending = now + self.duration
				self.stacks = 1
				OvaleAura:GainedAuraOnGUID(self_guid, self.start, self.spellId, self_guid, "HELPFUL", nil, nil, self.stacks, nil, self.duration, self.ending, nil, self.spellName, nil, nil, nil)
			end
		end
	end
end
--</public-static-methods>
