--[[--------------------------------------------------------------------
    Copyright (C) 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]-------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleWarriorCharge = Ovale:NewModule("OvaleWarriorCharge", "AceEvent-3.0")
Ovale.OvaleWarriorCharge = OvaleWarriorCharge

--[[
	Charge will generate rage the first time that it is used against a new target,
	and then subsequent charges to the same target no longer generate rage.

	Add a hidden debuff on a target when it has been the target of a Charge.
	Remove the debuff from the existing target when the warrior uses Charge on a
	new target.
--]]

--<private-static-properties>
local OvaleDebug = Ovale.OvaleDebug

-- Forward declarations for module dependencies.
local OvaleAura = nil

local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local INFINITY = math.huge

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvaleWarriorCharge)

-- Player's GUID.
local self_playerGUID = nil

-- Re-use the spell ID of Charge for the hidden target debuff "Charged" spell ID.
local CHARGED = 100
local CHARGED_NAME = "Charged"
local CHARGED_DURATION = INFINITY
-- Spell IDs for abilities that trigger the Charge debuff.
local CHARGED_ATTACKS = {
	[   100] = API_GetSpellInfo(100),	-- Charge
}
--</private-static-properties>

--<public-static-properties>
-- GUID of the most recently Charged target.
OvaleWarriorCharge.targetGUID = nil
--</public-static-properties>

--<public-static-methods>
function OvaleWarriorCharge:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
end

function OvaleWarriorCharge:OnEnable()
	if Ovale.playerClass == "WARRIOR" then
		self_playerGUID = Ovale.playerGUID
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

function OvaleWarriorCharge:OnDisable()
	if Ovale.playerClass == "WARRIOR" then
		self:UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

function OvaleWarriorCharge:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
	if sourceGUID == self_playerGUID and cleuEvent == "SPELL_CAST_SUCCESS" then
		local spellId, spellName = arg12, arg13
		if CHARGED_ATTACKS[spellId] and destGUID ~= self.targetGUID then
			self:Debug("Spell %d (%s) on new target %s.", spellId, spellName, destGUID)
			local now = API_GetTime()
			-- Remove the existing Charged debuff from the previous target.
			if self.targetGUID then
				self:Debug("Removing Charged debuff on previous target %s.", self.targetGUID)
				OvaleAura:LostAuraOnGUID(self.targetGUID, now, CHARGED, self_playerGUID)
			end
			-- Add a new Charged debuff to the new target.
			self:Debug("Adding Charged debuff to %s.", destGUID)
			local duration = CHARGED_DURATION
			local ending = now + CHARGED_DURATION
			OvaleAura:GainedAuraOnGUID(destGUID, now, CHARGED, self_playerGUID, "HARMFUL", nil, nil, 1, nil, duration, ending, nil, CHARGED_NAME, nil, nil, nil)
			self.targetGUID = destGUID
		end
	end
end
--</public-static-methods>
