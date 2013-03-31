--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- This addon tracks the player's stats as available on the in-game paper doll.

local _, Ovale = ...
local OvalePaperDoll = Ovale:NewModule("OvalePaperDoll", "AceEvent-3.0")
Ovale.OvalePaperDoll = OvalePaperDoll

--<private-static-properties>
local select = select
local tonumber = tonumber
local API_GetCritChance = GetCritChance
local API_GetMasteryEffect = GetMasteryEffect
local API_GetMeleeHaste = GetMeleeHaste
local API_GetRangedCritChance = GetRangedCritChance
local API_GetRangedHaste = GetRangedHaste
local API_GetSpecialization = GetSpecialization
local API_GetSpellBonusDamage = GetSpellBonusDamage
local API_GetSpellBonusHealing = GetSpellBonusHealing
local API_GetSpellCritChance = GetSpellCritChance
local API_UnitAttackPower = UnitAttackPower
local API_UnitClass = UnitClass
local API_UnitLevel = UnitLevel
local API_UnitRangedAttackPower = UnitRangedAttackPower
local API_UnitSpellHaste = UnitSpellHaste
local API_UnitStat = UnitStat

local OVALE_SPELLDAMAGE_SCHOOL = {
	DEATHKNIGHT = 4, -- Nature
	DRUID = 4, -- Nature
	HUNTER = 4, -- Nature
	MAGE = 5, -- Frost
	MONK = 4, -- Nature
	PALADIN = 2, -- Holy
	PRIEST = 2, -- Holy
	ROGUE = 4, -- Nature
	SHAMAN = 4, -- Nature
	WARLOCK = 6, -- Shadow
	WARRIOR = 4, -- Nature
}
local OVALE_HEALING_CLASS = {
	DRUID = true,
	MONK = true,
	PALADIN = true,
	PRIEST = true,
	SHAMAN = true,
}
--</private-static-properties>

--<public-static-properties>
-- player's class token
OvalePaperDoll.class = select(2, API_UnitClass("player"))
-- player's level
OvalePaperDoll.level = API_UnitLevel("player")
-- Player's current specialization.
OvalePaperDoll.specialization = nil

-- primary stats
OvalePaperDoll.agility = 0
OvalePaperDoll.intellect = 0
OvalePaperDoll.spirit = 0
OvalePaperDoll.stamina = 0
OvalePaperDoll.strength = 0

-- secondary stats
OvalePaperDoll.attackPower = 0
OvalePaperDoll.rangedAttackPower = 0
-- percent increase of effect due to mastery
OvalePaperDoll.masteryEffect = 0
-- percent increase to melee critical strike
OvalePaperDoll.meleeCrit = 0
-- percent increase to melee haste
OvalePaperDoll.meleeHaste = 0
-- percent increase to ranged critical strike
OvalePaperDoll.rangedCrit = 0
-- percent increase to ranged haste
OvalePaperDoll.rangedHaste = 0
-- percent increase to spell critical strike
OvalePaperDoll.spellCrit = 0
-- percent increase to spell haste
OvalePaperDoll.spellHaste = 0
-- spellpower
OvalePaperDoll.spellBonusDamage = 0
OvalePaperDoll.spellBonusHealing = 0
--</public-static-properties>

--<public-static-methods>
function OvalePaperDoll:OnEnable()
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "UpdateStats")
	self:RegisterEvent("COMBAT_RATING_UPDATE")
	self:RegisterEvent("MASTERY_UPDATE")
	self:RegisterEvent("PLAYER_ALIVE", "UpdateStats")
	self:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStats")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateStats")
	self:RegisterEvent("SPELL_POWER_CHANGED")
	self:RegisterEvent("UNIT_ATTACK_POWER")
	self:RegisterEvent("UNIT_LEVEL")
	self:RegisterEvent("UNIT_RANGEDDAMAGE")
	self:RegisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:RegisterEvent("UNIT_SPELL_HASTE")
	self:RegisterEvent("UNIT_STATS")
end

function OvalePaperDoll:OnDisable()
	self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:UnregisterEvent("COMBAT_RATING_UPDATE")
	self:UnregisterEvent("MASTERY_UPDATE")
	self:UnregisterEvent("PLAYER_ALIVE")
	self:UnregisterEvent("PLAYER_DAMAGE_DONE_MODS")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_LEVEL_UP")
	self:UnregisterEvent("PLAYER_TALENT_UPDATE")
	self:UnregisterEvent("SPELL_POWER_CHANGED")
	self:UnregisterEvent("UNIT_ATTACK_POWER")
	self:UnregisterEvent("UNIT_LEVEL")
	self:UnregisterEvent("UNIT_RANGEDDAMAGE")
	self:UnregisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:UnregisterEvent("UNIT_SPELL_HASTE")
	self:UnregisterEvent("UNIT_STATS")
end

function OvalePaperDoll:COMBAT_RATING_UPDATE(event)
	self.meleeCrit = API_GetCritChance()
	self.rangedCrit = API_GetRangedCritChance()
	self.spellCrit = API_GetSpellCritChance(OVALE_SPELLDAMAGE_SCHOOL[self.class])
end

function OvalePaperDoll:MASTERY_UPDATE(event)
	if self.level < 80 then
		self.masteryEffect = 0
	else
		self.masteryEffect = API_GetMasteryEffect()
	end
end

function OvalePaperDoll:PLAYER_LEVEL_UP(event, level, ...)
	self.level = tonumber(level) or API_UnitLevel("player")
end

function OvalePaperDoll:PLAYER_DAMAGE_DONE_MODS(event, unitId)
	self.spellBonusHealing = API_GetSpellBonusHealing()
end

function OvalePaperDoll:SPELL_POWER_CHANGED(event)
	self.spellBonusDamage = API_GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[self.class])
end

function OvalePaperDoll:UNIT_ATTACK_POWER(event, unitId)
	if unitId ~= "player" then return end
	local base, posBuff, negBuff = API_UnitAttackPower(unitId)
	self.attackPower = base + posBuff + negBuff
end

function OvalePaperDoll:UNIT_LEVEL(event, unitId)
	if unitId ~= "player" then return end
	self.level = API_UnitLevel(unitId)
end

function OvalePaperDoll:UNIT_RANGEDDAMAGE(event, unitId)
	if unitId ~= "player" then return end
	self.rangedHaste = API_GetRangedHaste()
end

function OvalePaperDoll:UNIT_RANGED_ATTACK_POWER(event, unitId)
	if unitId ~= "player" then return end
	local base, posBuff, negBuff = API_UnitRangedAttackPower(unitId)
	self.rangedAttackPower = base + posBuff + negBuff
end

function OvalePaperDoll:UNIT_SPELL_HASTE(event, unitId)
	if unitId ~= "player" then return end
	self.meleeHaste = API_GetMeleeHaste()
	self.spellHaste = API_UnitSpellHaste(unitId)
end

function OvalePaperDoll:UNIT_STATS(event, unitId)
	if unitId ~= "player" then return end
	self.strength = API_UnitStat(unitId, 1)
	self.agility = API_UnitStat(unitId, 2)
	self.stamina = API_UnitStat(unitId, 3)
	self.intellect = API_UnitStat(unitId, 4)
	self.spirit = API_UnitStat(unitId, 5)
end

function OvalePaperDoll:UpdateStats(event)
	self.specialization = API_GetSpecialization()
	self:COMBAT_RATING_UPDATE(event)
	self:MASTERY_UPDATE(event)
	self:PLAYER_DAMAGE_DONE_MODS(event, "player")
	self:SPELL_POWER_CHANGED(event)
	self:UNIT_ATTACK_POWER(event, "player")
	self:UNIT_RANGEDDAMAGE(event, "player")
	self:UNIT_RANGED_ATTACK_POWER(event, "player")
	self:UNIT_SPELL_HASTE(event, "player")
	self:UNIT_STATS(event, "player")
end

function OvalePaperDoll:GetMasteryMultiplier()
	return 1 + self.masteryEffect / 100
end

function OvalePaperDoll:GetMeleeHasteMultiplier()
	return 1 + self.meleeHaste / 100
end

function OvalePaperDoll:GetRangedHasteMultiplier()
	return 1 + self.rangedHaste / 100
end

function OvalePaperDoll:GetSpellHasteMultiplier()
	return 1 + self.spellHaste / 100
end

function OvalePaperDoll:Debug()
	Ovale:FormatPrint("Class: %s", self.class)
	Ovale:FormatPrint("Level: %d", self.level)
	Ovale:FormatPrint("Specialization: %s", self.specialization)
	Ovale:FormatPrint("Agility: %d", self.agility)
	Ovale:FormatPrint("Intellect: %d", self.intellect)
	Ovale:FormatPrint("Spirit: %d", self.spirit)
	Ovale:FormatPrint("Stamina: %d", self.stamina)
	Ovale:FormatPrint("Strength: %d", self.strength)
	Ovale:FormatPrint("AP: %d", self.attackPower)
	Ovale:FormatPrint("RAP: %d", self.rangedAttackPower)
	Ovale:FormatPrint("Spell bonus damage: %d", self.spellBonusDamage)
	Ovale:FormatPrint("Spell bonus healing: %d", self.spellBonusHealing)
	Ovale:FormatPrint("Spell critical strike effect: %f%%", self.spellCrit)
	Ovale:FormatPrint("Spell haste effect: %f%%", self.spellHaste)
	Ovale:FormatPrint("Melee critical strike effect: %f%%", self.meleeCrit)
	Ovale:FormatPrint("Melee haste effect: %f%%", self.meleeHaste)
	Ovale:FormatPrint("Ranged critical strike effect: %f%%", self.rangedCrit)
	Ovale:FormatPrint("Ranged haste effect: %f%%", self.rangedHaste)
	Ovale:FormatPrint("Mastery effect: %f%%", self.masteryEffect)
end
--</public-static-methods>
