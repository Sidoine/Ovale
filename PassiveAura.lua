--[[--------------------------------------------------------------------
    Copyright (C) 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]-------------------------------------------------------------------

local OVALE, Ovale = ...
local OvalePassiveAura = Ovale:NewModule("OvalePassiveAura", "AceEvent-3.0")
Ovale.OvalePassiveAura = OvalePassiveAura

--[[
	This module manages passive, usually hidden, auras from various class and item effects.
--]]

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleAura = nil
local OvaleEquipment = nil
local OvalePaperDoll = nil

local exp = math.exp
local log = math.log
local pairs = pairs
local API_GetTime = GetTime
local INFINITY = math.huge
local INVSLOT_TRINKET1 = INVSLOT_TRINKET1
local INVSLOT_TRINKET2 = INVSLOT_TRINKET2

-- Player's GUID.
local self_playerGUID = nil
-- Trinket slot IDs list.
local TRINKET_SLOTS = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 }

local AURA_NAME = {}

-- Meta Gem Increased Critical Effect passive aura.
local INCREASED_CRIT_EFFECT_3_PERCENT = 44797
do
	AURA_NAME[INCREASED_CRIT_EFFECT_3_PERCENT] = "3% Increased Critical Effect"
end
local INCREASED_CRIT_EFFECT = {
	[INCREASED_CRIT_EFFECT_3_PERCENT] = 1.03,
}
local INCREASED_CRIT_META_GEM = {
	[32409] = INCREASED_CRIT_EFFECT_3_PERCENT,	-- Relentless Earthstorm Diamond
	[34220] = INCREASED_CRIT_EFFECT_3_PERCENT,	-- Chaotic Skyfire Diamond
	[41285] = INCREASED_CRIT_EFFECT_3_PERCENT,	-- Chaotic Skyflare Diamond
	[41398] = INCREASED_CRIT_EFFECT_3_PERCENT,	-- Relentless Earthsiege Diamond
	[52291] = INCREASED_CRIT_EFFECT_3_PERCENT,	-- Chaotic Shadowspirit Diamond
	[52297] = INCREASED_CRIT_EFFECT_3_PERCENT,	-- Revitalizing Shadowspirit Diamond
	[68778] = INCREASED_CRIT_EFFECT_3_PERCENT,	-- Agile Shadowspirit Diamond
	[68779] = INCREASED_CRIT_EFFECT_3_PERCENT,	-- Reverberating Shadowspirit Diamond
	[68780] = INCREASED_CRIT_EFFECT_3_PERCENT,	-- Burning Shadowspirit Diamond
	[76884] = INCREASED_CRIT_EFFECT_3_PERCENT,	-- Agile Primal Diamond
	[76885] = INCREASED_CRIT_EFFECT_3_PERCENT,	-- Burning Primal Diamond
	[76886] = INCREASED_CRIT_EFFECT_3_PERCENT,	-- Reverberating Primal Diamond
	[76888] = INCREASED_CRIT_EFFECT_3_PERCENT,	-- Revitalizing Primal Diamond
}

-- Amplification (secondary stats increase) passive aura.
local AMPLIFICATION = 146051
do
	AURA_NAME[AMPLIFICATION] = "Amplification"
end
local AMPLIFICATION_TRINKET = {
	[102293] = AMPLIFICATION,	-- Purified Bindings of Immerseus
	[104426] = AMPLIFICATION,	-- Purified Bindings of Immerseus (Heroic)
	[104675] = AMPLIFICATION,	-- Purified Bindings of Immerseus (Flexible)
	[104924] = AMPLIFICATION,	-- Purified Bindings of Immerseus (Raid Finder)
	[105173] = AMPLIFICATION,	-- Purified Bindings of Immerseus (Warforged)
	[105422] = AMPLIFICATION,	-- Purified Bindings of Immerseus (Heroic Warforged)

	[102299] = AMPLIFICATION,	-- Prismatic Prison of Pride
	[104478] = AMPLIFICATION,	-- Prismatic Prison of Pride (Heroic)
	[104727] = AMPLIFICATION,	-- Prismatic Prison of Pride (Flexible)
	[104976] = AMPLIFICATION,	-- Prismatic Prison of Pride (Raid Finder)
	[105225] = AMPLIFICATION,	-- Prismatic Prison of Pride (Warforged)
	[105474] = AMPLIFICATION,	-- Prismatic Prison of Pride (Heroic Warforged)

	[102305] = AMPLIFICATION,	-- Thok's Tail Tip
	[104613] = AMPLIFICATION,	-- Thok's Tail Tip (Heroic)
	[104862] = AMPLIFICATION,	-- Thok's Tail Tip (Flexible)
	[105111] = AMPLIFICATION,	-- Thok's Tail Tip (Raid Finder)
	[105360] = AMPLIFICATION,	-- Thok's Tail Tip (Warforged)
	[105609] = AMPLIFICATION,	-- Thok's Tail Tip (Heroic Warforged)
}

-- Readiness (cooldown reduction) passive aura.
local READINESS_AGILITY_DPS = 146019
local READINESS_STRENGTH_DPS = 145955
local READINESS_TANK = 146025
do
	AURA_NAME[READINESS_AGILITY_DPS] = "Readiness"
	AURA_NAME[READINESS_STRENGTH_DPS] = "Readiness"
	AURA_NAME[READINESS_TANK] = "Readiness"
end
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
	OvaleEquipment = Ovale.OvaleEquipment
	OvalePaperDoll = Ovale.OvalePaperDoll
end

function OvalePassiveAura:OnEnable()
	self_playerGUID = Ovale.playerGUID
	self:RegisterMessage("Ovale_EquipmentChanged")
	self:RegisterMessage("Ovale_SpecializationChanged")
end

function OvalePassiveAura:OnDisable()
	self:UnregisterMessage("Ovale_EquipmentChanged")
	self:UnregisterMessage("Ovale_SpecializationChanged")
end

function OvalePassiveAura:Ovale_EquipmentChanged()
	self:UpdateIncreasedCritEffectMetaGem()
	self:UpdateAmplification()
	self:UpdateReadiness()
end

function OvalePassiveAura:Ovale_SpecializationChanged()
	self:UpdateReadiness()
end

function OvalePassiveAura:UpdateIncreasedCritEffectMetaGem()
	local metaGem = OvaleEquipment.metaGem
	local spellId = metaGem and INCREASED_CRIT_META_GEM[metaGem]

	-- Update the passive, hidden aura for the meta gem.
	local now = API_GetTime()
	if spellId then
		local name = AURA_NAME[spellId]
		local start = now
		local duration = INFINITY
		local ending = INFINITY
		local stacks = 1
		local value = INCREASED_CRIT_EFFECT[spellId]
		OvaleAura:GainedAuraOnGUID(self_playerGUID, start, spellId, self_playerGUID, "HELPFUL", nil, nil, stacks, nil, duration, ending, nil, name, value, nil, nil)
	else
		OvaleAura:LostAuraOnGUID(self_playerGUID, now, spellId, self_playerGUID)
	end
end

function OvalePassiveAura:UpdateAmplification()
	local hasAmplification = false
	local critDamageIncrease = 0
	local statMultiplier = 1

	-- Check if an Amplification trinket is equipped.  If more than one Amplification trinket is
	-- equipped, then the effects stack.
	for _, slot in pairs(TRINKET_SLOTS) do
		local trinket = OvaleEquipment:GetEquippedItem(slot)
		if trinket and AMPLIFICATION_TRINKET[trinket] then
			hasAmplification = true
			-- Use a derived formula that very closely approximates the true percent increase based on item level.
			local ilevel = OvaleEquipment:GetEquippedItemLevel(slot) or 528
			local amplificationEffect = exp((ilevel - 528) * 0.009327061882 + 1.713797928)
			-- Scale the Amplification effect so that it gives full Amplification at level 90 to 0% at level 100.
			if OvalePaperDoll.level >= 90 then
				amplificationEffect = amplificationEffect * (100 - OvalePaperDoll.level) / 10
				-- Cap at 1%.
				amplificationEffect = amplificationEffect > 1 and amplificationEffect or 1
			end
			critDamageIncrease = critDamageIncrease + amplificationEffect / 100
			statMultiplier = statMultiplier * (1 + amplificationEffect / 100)
		end
	end

	-- Update the passive, hidden aura for the Amplification trinkets.
	local now = API_GetTime()
	local spellId = AMPLIFICATION
	if hasAmplification then
		local name = AURA_NAME[spellId]
		local start = now
		local duration = INFINITY
		local ending = INFINITY
		local stacks = 1
		local value1 = critDamageIncrease
		local value2 = statMultiplier
		OvaleAura:GainedAuraOnGUID(self_playerGUID, start, spellId, self_playerGUID, "HELPFUL", nil, nil, stacks, nil, duration, ending, nil, name, value1, value2, nil)
	else
		OvaleAura:LostAuraOnGUID(self_playerGUID, now, spellId, self_playerGUID)
	end
end

function OvalePassiveAura:UpdateReadiness()
	local specialization = OvalePaperDoll:GetSpecialization()
	local spellId = READINESS_ROLE[Ovale.playerClass] and READINESS_ROLE[Ovale.playerClass][specialization]
	if spellId then
		local hasReadiness = false
		local cdMultiplier

		-- Check if a Readiness trinket is equipped and for the correct role.
		for _, slot in pairs(TRINKET_SLOTS) do
			local trinket = OvaleEquipment:GetEquippedItem(slot)
			local readinessId = trinket and READINESS_TRINKET[trinket]
			if readinessId then
				hasReadiness = true
				-- Use a derived formula that very closely approximates the true cooldown recovery rate increase based on item level.
				local ilevel = OvaleEquipment:GetEquippedItemLevel(slot) or 528
				local cdRecoveryRateIncrease = exp((ilevel - 528) * 0.009317881032 + 3.434954478)
				if readinessId == READINESS_TANK then
					-- The cooldown recovery rate of the tank trinket is half the value of the same item-level DPS trinket.
					cdRecoveryRateIncrease = cdRecoveryRateIncrease / 2
				end
				-- Scale the Readiness effect so that it gives full Readiness at level 90 to 0% at level 100.
				if OvalePaperDoll.level >= 90 then
					cdRecoveryRateIncrease = cdRecoveryRateIncrease * (100 - OvalePaperDoll.level) / 10
				end
				-- Convert the cooldown recovery rate into a multiplier for the cooldown duration.
				cdMultiplier = 1 / (1 + cdRecoveryRateIncrease / 100)
				-- Cap at 90%.
				cdMultiplier = cdMultiplier < 0.9 and cdMultiplier or 0.9
				break
			end
		end

	-- Update the passive, hidden aura for the Readiness trinkets.
		local now = API_GetTime()
		if hasReadiness then
			local name = AURA_NAME[spellId]
			local start = now
			local duration = INFINITY
			local ending = INFINITY
			local stacks = 1
			local value = cdMultiplier
			OvaleAura:GainedAuraOnGUID(self_playerGUID, start, spellId, self_playerGUID, "HELPFUL", nil, nil, stacks, nil, duration, ending, nil, name, value, nil, nil)
		else
			OvaleAura:LostAuraOnGUID(self_playerGUID, now, spellId, self_playerGUID)
		end
	end
end
--</public-static-methods>
