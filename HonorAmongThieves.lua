--[[--------------------------------------------------------------------
    Copyright (C) 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]-------------------------------------------------------------------

--[[
	This addon tracks the hidden cooldown of Honor Among Thieves on a
	subtlety rogue.

	Honor Among Thieves description from wowhead.com:

		Critical hits in combat by you or by your party or raid members grant
		you a combo point, but no more often than once every 2 seconds.

	Mechanically, there is a hidden buff applied to the player that lasts 2
	seconds and prevents critical hits from generating an extra combo point.
--]]

local OVALE, Ovale = ...
local OvaleHonorAmongThieves = Ovale:NewModule("OvaleHonorAmongThieves", "AceEvent-3.0")
Ovale.OvaleHonorAmongThieves = OvaleHonorAmongThieves

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleAura = nil
local OvaleData = nil

local API_GetTime = GetTime
local INFINITY = math.huge

-- Player's GUID.
local self_playerGUID = nil

-- Honor Among Thieves spell ID.
local HONOR_AMONG_THIEVES = 51699

-- Use a mean time between procs of 2.2 seconds (estimation from SimulationCraft).
local MEAN_TIME_TO_HAT = 2.2
--</private-static-properties>

--<public-static-properties>
OvaleHonorAmongThieves.spellName = "Honor Among Thieves Cooldown"
-- Honor Among Thieves spell ID from spellbook; re-used as the aura ID of the hidden buff.
OvaleHonorAmongThieves.spellId = HONOR_AMONG_THIEVES
OvaleHonorAmongThieves.start = 0
OvaleHonorAmongThieves.ending = 0
OvaleHonorAmongThieves.duration = MEAN_TIME_TO_HAT
OvaleHonorAmongThieves.stacks = 0
--</public-static-properties>

--<public-static-methods>
function OvaleHonorAmongThieves:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
	OvaleData = Ovale.OvaleData
end

function OvaleHonorAmongThieves:OnEnable()
	if Ovale.playerClass == "ROGUE" then
		self_playerGUID = Ovale.playerGUID
		self:RegisterMessage("Ovale_SpecializationChanged")
	end
end

function OvaleHonorAmongThieves:OnDisable()
	if Ovale.playerClass == "ROGUE" then
		self:UnregisterMessage("Ovale_SpecializationChanged")
	end
end

function OvaleHonorAmongThieves:Ovale_SpecializationChanged(event, specialization, previousSpecialization)
	if specialization == "subtlety" then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

function OvaleHonorAmongThieves:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
	if sourceGUID == self_playerGUID and destGUID == self_playerGUID and cleuEvent == "SPELL_ENERGIZE" then
		local spellId, powerType = arg12, arg16
		if spellId == HONOR_AMONG_THIEVES and powerType == 4 then
			local now = API_GetTime()
			self.start = now
			-- Prefer the duration set in the script, if given; otherwise, default to MEAN_TIME_TO_HAT.
			local duration = OvaleData:GetSpellInfoProperty(HONOR_AMONG_THIEVES, now, "duration", destGUID) or MEAN_TIME_TO_HAT 
			self.duration = duration
			self.ending = self.start + duration
			self.stacks = 1
			OvaleAura:GainedAuraOnGUID(self_playerGUID, self.start, self.spellId, self_playerGUID, "HELPFUL", nil, nil, self.stacks, nil, self.duration, self.ending, nil, self.spellName, nil, nil, nil)
		end
	end
end
--</public-static-methods>
