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

--<private-static-properties>
local select = select
local tonumber = tonumber

local GetMasteryEffect = GetMasteryEffect
local GetMeleeHaste = GetMeleeHaste
local GetRangedHaste = GetRangedHaste
local GetSpecialization = GetSpecialization
local GetSpellBonusDamage = GetSpellBonusDamage
local GetSpellBonusHealing = GetSpellBonusHealing
local UnitAttackPower = UnitAttackPower
local UnitClass = UnitClass
local UnitLevel = UnitLevel
local UnitRangedAttackPower = UnitRangedAttackPower
local UnitSpellHaste = UnitSpellHaste
local UnitStat = UnitStat
--</private-static-properties>

--<public-static-properties>
-- player's class token
OvalePaperDoll.class = select(2, UnitClass("player"))
-- player's level
OvalePaperDoll.level = UnitLevel("player")
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
-- percent increase to melee haste
OvalePaperDoll.meleeHaste = 0
-- percent increase to ranged haste
OvalePaperDoll.rangedHaste = 0
-- percent increase to spell haste
OvalePaperDoll.spellHaste = 0
-- spellpower
OvalePaperDoll.spellBonusDamage = 0
OvalePaperDoll.spellBonusHealing = 0
--</public-static-properties>

--<public-static-methods>
function OvalePaperDoll:OnEnable()
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "UpdateStats")
	self:RegisterEvent("MASTERY_UPDATE")
	self:RegisterEvent("PLAYER_ALIVE", "UpdateStats")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStats")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateStats")
	self:RegisterEvent("UNIT_ATTACK_POWER")
	self:RegisterEvent("UNIT_LEVEL")
	self:RegisterEvent("UNIT_RANGEDDAMAGE")
	self:RegisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:RegisterEvent("UNIT_SPELL_HASTE")
	self:RegisterEvent("UNIT_SPELL_POWER")
	self:RegisterEvent("UNIT_STATS")
end

function OvalePaperDoll:OnDisable()
	self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:UnregisterEvent("MASTERY_UPDATE")
	self:UnregisterEvent("PLAYER_ALIVE")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_LEVEL_UP")
	self:UnregisterEvent("PLAYER_TALENT_UPDATE")
	self:UnregisterEvent("UNIT_ATTACK_POWER")
	self:UnregisterEvent("UNIT_LEVEL")
	self:UnregisterEvent("UNIT_RANGEDDAMAGE")
	self:UnregisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:UnregisterEvent("UNIT_SPELL_HASTE")
	self:UnregisterEvent("UNIT_SPELL_POWER")
	self:UnregisterEvent("UNIT_STATS")
end

function OvalePaperDoll:MASTERY_UPDATE(event)
	if self.level < 80 then
		self.masteryEffect = 0
	else
		self.masteryEffect = GetMasteryEffect()
	end
end

function OvalePaperDoll:PLAYER_LEVEL_UP(event, level, ...)
	self.level = tonumber(level) or UnitLevel("player")
end

function OvalePaperDoll:UNIT_ATTACK_POWER(event, unitId)
	if unitId ~= "player" then return end
	local base, posBuff, negBuff = UnitAttackPower(unitId)
	self.attackPower = base + posBuff + negBuff
end

function OvalePaperDoll:UNIT_LEVEL(event, unitId)
	if unitId ~= "player" then return end
	self.level = UnitLevel(unitId)
end

function OvalePaperDoll:UNIT_RANGEDDAMAGE(event, unitId)
	if unitId ~= "player" then return end
	self.rangedHaste = GetRangedHaste()
end

function OvalePaperDoll:UNIT_RANGED_ATTACK_POWER(event, unitId)
	if unitId ~= "player" then return end
	local base, posBuff, negBuff = UnitRangedAttackPower(unitId)
	self.rangedAttackPower = base + posBuff + negBuff
end

function OvalePaperDoll:UNIT_SPELL_HASTE(event, unitId)
	if unitId ~= "player" then return end
	self.meleeHaste = GetMeleeHaste()
	self.spellHaste = UnitSpellHaste(unitId)
end

local classToSchool = {
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
local isHealingClass = {
	DRUID = true,
	MONK = true,
	PALADIN = true,
	PRIEST = true,
	SHAMAN = true,
}

function OvalePaperDoll:UNIT_SPELL_POWER(event, unitId)
	if unitId ~= "player" then return end
	self.spellBonusDamage = GetSpellBonusDamage(classToSchool[self.class])
	if isHealingClass[self.class] then
		self.spellBonusHealing = GetSpellBonusHealing()
	else
		self.spellBonusHealing = self.spellBonusDamage
	end
end

function OvalePaperDoll:UNIT_STATS(event, unitId)
	if unitId ~= "player" then return end
	self.strength = UnitStat(unitId, 1)
	self.agility = UnitStat(unitId, 2)
	self.stamina = UnitStat(unitId, 3)
	self.intellect = UnitStat(unitId, 4)
	self.spirit = UnitStat(unitId, 5)
end

function OvalePaperDoll:UpdateStats(event)
	self.specialization = GetSpecialization()
	self:MASTERY_UPDATE(event)
	self:UNIT_ATTACK_POWER(event, "player")
	self:UNIT_RANGEDDAMAGE(event, "player")
	self:UNIT_RANGED_ATTACK_POWER(event, "player")
	self:UNIT_SPELL_HASTE(event, "player")
	self:UNIT_SPELL_POWER(event, "player")
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
	Ovale:Print("Class: " .. self.class)
	Ovale:Print("Level: " .. self.level)
	Ovale:Print("Specialization: " .. self.specialization)
	Ovale:Print("Agility: " ..self.agility)
	Ovale:Print("Intellect: " ..self.intellect)
	Ovale:Print("Spirit: " ..self.spirit)
	Ovale:Print("Stamina: " ..self.stamina)
	Ovale:Print("Strength: " ..self.strength)
	Ovale:Print("AP: " ..self.attackPower)
	Ovale:Print("RAP: " ..self.rangedAttackPower)
	Ovale:Print("Spell bonus damage: " ..self.spellBonusDamage)
	Ovale:Print("Spell bonus healing: " ..self.spellBonusHealing)
	Ovale:Print("Spell haste effect: " ..self.spellHaste.. "%")
	Ovale:Print("Melee haste effect: " ..self.meleeHaste.. "%")
	Ovale:Print("Ranged haste effect: " ..self.rangedHaste.. "%")
	Ovale:Print("Mastery effect: " ..self.masteryEffect.. "%")
end
--</public-static-methods>
