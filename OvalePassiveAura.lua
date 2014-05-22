--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]-------------------------------------------------------------------

local _, Ovale = ...
local OvalePassiveAura = Ovale:NewModule("OvalePassiveAura", "AceEvent-3.0")
Ovale.OvalePassiveAura = OvalePassiveAura

--[[
	This module manages passive, usually hidden, auras from various class and item effects.
--]]

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleAura = nil
local OvaleEquipement = nil
local OvalePaperDoll = nil

local exp = math.exp
local log = math.log
local API_GetTime = GetTime
local API_UnitClass = UnitClass
local API_UnitGUID = UnitGUID
local INVSLOT_TRINKET1 = INVSLOT_TRINKET1
local INVSLOT_TRINKET2 = INVSLOT_TRINKET2

-- Player's class.
local _, self_class = API_UnitClass("player")
-- Player's GUID.
local self_guid = nil

-- Readiness (cooldown reduction) passive aura.
local READINESS_AGILITY_DPS = 146019
local READINESS_STRENGTH_DPS = 145955
local READINESS_TANK = 146025
local READINESS_TRINKET = {
	[102292] = READINESS_AGILITY_DPS,	-- Assurance of Consequence
	[104476] = READINESS_AGILITY_DPS,	-- Assurance of Consequence (Heroic)
	[104725] = READINESS_AGILITY_DPS,	-- Assurance of Consequence (Flexible)
	[104974] = READINESS_AGILITY_DPS,	-- Assurance of Consequence (Raid Finder)
	[105223] = READINESS_AGILITY_DPS,	-- Assurance of Consequence (Warforged)
	[105472] = READINESS_AGILITY_DPS,	-- Assurance of Consequence (Heroic Warforged)

	[102298] = READINESS_STRENGTH_DPS,	-- Evil Eye of Galakras
	[104495] = READINESS_STRENGTH_DPS,	-- Evil Eye of Galakras (Heroic)
	[104744] = READINESS_STRENGTH_DPS,	-- Evil Eye of Galakras (Flexible)
	[104993] = READINESS_STRENGTH_DPS,	-- Evil Eye of Galakras (Raid Finder)
	[105242] = READINESS_STRENGTH_DPS,	-- Evil Eye of Galakras (Warforged)
	[105491] = READINESS_STRENGTH_DPS,	-- Evil Eye of Galakras (Heroic Warforged)

	[102306] = READINESS_TANK,			-- Vial of Living Corruption
	[104572] = READINESS_TANK,			-- Vial of Living Corruption (Heroic)
	[104821] = READINESS_TANK,			-- Vial of Living Corruption (Flexible)
	[105070] = READINESS_TANK,			-- Vial of Living Corruption (Raid Finder)
	[105319] = READINESS_TANK,			-- Vial of Living Corruption (Warforged)
	[105568] = READINESS_TANK,			-- Vial of Living Corruption (Heroic Warforged)
}
local READINESS_ROLE = {
	DEATHKNIGHT = { blood = READINESS_TANK, frost = READINESS_STRENGTH_DPS, unholy = READINESS_STRENGTH_DPS },
	DRUID = { feral = READINESS_AGILITY_DPS, guardian = READINESS_TANK },
	HUNTER = { beast_mastery = READINESS_AGILITY_DPS, marksmanship = READINESS_AGILITY_DPS, survival = READINESS_AGILITY_DPS },
	MONK = { brewmaster = READINESS_TANK, windwalker = READINESS_AGILITY_DPS },
	PALADIN = { protection = READINESS_TANK, retribution = READINESS_STRENGTH_DPS },
	ROGUE = { assassination = READINESS_AGILITY_DPS, combat = READINESS_AGILITY_DPS, subtlety = READINESS_AGILITY_DPS },
	SHAMAN = { enhancement = READINESS_AGILITY_DPS },
	WARRIOR = { arms = READINESS_STRENGTH_DPS, fury = READINESS_STRENGTH_DPS, protection = READINESS_TANK },
}
--</private-static-properties>

--<public-static-methods>
function OvalePassiveAura:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
	OvaleEquipement = Ovale.OvaleEquipement
	OvalePaperDoll = Ovale.OvalePaperDoll
end

function OvalePassiveAura:OnEnable()
	self_guid = API_UnitGUID("player")
	self:RegisterMessage("Ovale_EquipmentChanged")
	self:RegisterMessage("Ovale_SpecializationChanged")
end

function OvalePassiveAura:OnDisable()
	self:UnregisterMessage("Ovale_EquipmentChanged")
	self:UnregisterMessage("Ovale_SpecializationChanged")
end

function OvalePassiveAura:Ovale_EquipmentChanged()
	self:UpdateReadiness()
end

function OvalePassiveAura:Ovale_SpecializationChanged()
	self:UpdateReadiness()
end

function OvalePassiveAura:UpdateReadiness()
	local specialization = OvalePaperDoll:GetSpecialization()
	local spellId = READINESS_ROLE[self_class] and READINESS_ROLE[self_class][specialization]
	if spellId then
		-- Check a Readiness trinket is equipped and for the correct role.
		local slot = INVSLOT_TRINKET1
		local trinket = OvaleEquipement:GetEquippedItem(slot)
		local readiness = trinket and READINESS_TRINKET[trinket]
		if not readiness then
			slot = INVSLOT_TRINKET2
			trinket = OvaleEquipement:GetEquippedItem(slot)
			readiness = trinket and READINESS_TRINKET[trinket]
		end
		local now = API_GetTime()
		if readiness == spellId then
			local name = "Readiness"
			local start = now
			local duration = math.huge
			local ending = math.huge
			local stacks = 1
			-- Use a derived formula that very closely approximates the true cooldown recovery rate increase based on item level.
			local ilevel = OvaleEquipement:GetEquippedItemLevel(slot)
			local cdRecoveryRateIncrease = exp((ilevel - 528) * 0.009317881032 + 3.434954478)
			if readiness == READINESS_TANK then
				-- The cooldown recovery rate of the tank trinket is half the value of the same item-level DPS trinket.
				cdRecoveryRateIncrease = cdRecoveryRateIncrease / 2
			end
			local value = 1 / (1 + cdRecoveryRateIncrease / 100)
			OvaleAura:GainedAuraOnGUID(self_guid, start, spellId, self_guid, "HELPFUL", nil, nil, stacks, nil, duration, ending, nil, name, value, nil, nil)
		else
			OvaleAura:LostAuraOnGUID(self_guid, now, spellId, self_guid)
		end
	end
end
--</public-static-methods>
