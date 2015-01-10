--[[--------------------------------------------------------------------
    Copyright (C) 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]-------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleMindHarvest = Ovale:NewModule("OvaleMindHarvest", "AceEvent-3.0")
Ovale.OvaleMindHarvest = OvaleMindHarvest

--[[
	Glyph of Mind Harvest description from wowhead.com:

		The first time you damage an enemy with Mind Blast, you gain 2 additional
		Orb, but the cooldown on Mind Blast is increased by 6 sec.

	Add a hidden debuff on targets when they are damaged by the player's Mind Blast.
--]]

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleAura = nil
local OvalePaperDoll = nil
local OvaleSpellBook = nil

local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local API_UnitClass = UnitClass
local API_UnitGUID = UnitGUID
local INFINITY = math.huge

-- Player's class.
local _, self_class = API_UnitClass("player")
-- Player's GUID.
local self_guid = nil

-- Re-use the spell ID of the Glyph of Mind Harvest for the hidden target debuff spell ID.
local MIND_HARVEST = 162532
local MIND_HARVEST_NAME = API_GetSpellInfo(MIND_HARVEST)
local MIND_HARVEST_DURATION = INFINITY
-- Spell IDs for abilities that trigger Mind Harvest.
local MIND_HARVEST_ATTACKS = {
	[  8092] = API_GetSpellInfo(8092),	-- Mind Blast
}
--</private-static-properties>

--<private-static-methods>
-- Returns true if Glyph of Mind Harvest is active and priest is in shadow specialization.
local function IsEnabled()
	return OvalePaperDoll:IsSpecialization("shadow") and OvaleSpellBook:IsActiveGlyph(MIND_HARVEST)
end
--</private-static-methods>

--<public-static-methods>
function OvaleMindHarvest:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvaleSpellBook = Ovale.OvaleSpellBook
end

function OvaleMindHarvest:OnEnable()
	if self_class == "PRIEST" then
		self_guid = API_UnitGUID("player")
		self:RegisterMessage("Ovale_GlyphsChanged", "UpdateEventHandlers")
		self:RegisterMessage("Ovale_SpecializationChanged", "UpdateEventHandlers")
		if IsEnabled() then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
	end
end

function OvaleMindHarvest:OnDisable()
	if self_class == "PRIEST" then
		self:UnregisterMessage("Ovale_GlyphsChanged")
		self:UnregisterMessage("Ovale_SpecializationChanged")
		if IsEnabled() then
			self:UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED")
		end
	end
end

function OvaleMindHarvest:UpdateEventHandlers(event)
	if IsEnabled() then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

function OvaleMindHarvest:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...
	if sourceGUID == self_guid then
		if cleuEvent == "SPELL_DAMAGE" then
			local spellId = arg12
			if MIND_HARVEST_ATTACKS[spellId] then
				local now = API_GetTime()
				local duration = MIND_HARVEST_DURATION
				local ending = now + MIND_HARVEST_DURATION
				OvaleAura:GainedAuraOnGUID(destGUID, now, MIND_HARVEST, self_guid, "HARMFUL", nil, nil, 1, nil, duration, ending, nil, MIND_HARVEST_NAME, nil, nil, nil)
			end
		end
	end
end
--</public-static-methods>
