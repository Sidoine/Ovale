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
local API_IsDualWielding = IsDualWielding
local API_UnitAttackPower = UnitAttackPower
local API_UnitClass = UnitClass
local API_UnitDamage = UnitDamage
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

OvalePaperDoll.stat = {
	-- time of most recent snapshot
	snapshotTime = 0,

-- primary stats
	agility = 0,
	intellect = 0,
	spirit = 0,
	stamina = 0,
	strength = 0,

-- secondary stats
	attackPower = 0,
	rangedAttackPower = 0,
	-- percent increase of effect due to mastery
	masteryEffect = 0,
	-- percent increase to melee critical strike
	meleeCrit = 0,
	-- percent increase to melee haste
	meleeHaste = 0,
	-- percent increase to ranged critical strike
	rangedCrit = 0,
	-- percent increase to ranged haste
	rangedHaste = 0,
	-- percent increase to spell critical strike
	spellCrit = 0,
	-- percent increase to spell haste
	spellHaste = 0,
	-- spellpower
	spellBonusDamage = 0,
	spellBonusHealing = 0,

-- miscellaneous stats
	-- average weapon damage of mainhand and offhand weapons
	mainHandWeaponDamage = 0,
	offHandWeaponDamage = 0,
}
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
	self:RegisterMessage("Ovale_EquipmentChanged")
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
	self:UnregisterMessage("Ovale_EquipmentChanged")
end

function OvalePaperDoll:COMBAT_RATING_UPDATE(event)
	self.stat.meleeCrit = API_GetCritChance()
	self.stat.rangedCrit = API_GetRangedCritChance()
	self.stat.spellCrit = API_GetSpellCritChance(OVALE_SPELLDAMAGE_SCHOOL[self.class])
	self.stat.snapshotTime = Ovale.now
end

function OvalePaperDoll:MASTERY_UPDATE(event)
	if self.level < 80 then
		self.stat.masteryEffect = 0
	else
		self.stat.masteryEffect = API_GetMasteryEffect()
		self.stat.snapshotTime = Ovale.now
	end
end

function OvalePaperDoll:PLAYER_LEVEL_UP(event, level, ...)
	self.level = tonumber(level) or API_UnitLevel("player")
end

function OvalePaperDoll:PLAYER_DAMAGE_DONE_MODS(event, unitId)
	self.stat.spellBonusHealing = API_GetSpellBonusHealing()
	self.stat.snapshotTime = Ovale.now
end

function OvalePaperDoll:SPELL_POWER_CHANGED(event)
	self.stat.spellBonusDamage = API_GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[self.class])
	self.stat.snapshotTime = Ovale.now
end

function OvalePaperDoll:UNIT_ATTACK_POWER(event, unitId)
	if unitId ~= "player" then return end
	local base, posBuff, negBuff = API_UnitAttackPower(unitId)
	self.stat.attackPower = base + posBuff + negBuff
	self.stat.snapshotTime = Ovale.now
end

function OvalePaperDoll:UNIT_LEVEL(event, unitId)
	if unitId ~= "player" then return end
	self.level = API_UnitLevel(unitId)
end

function OvalePaperDoll:UNIT_RANGEDDAMAGE(event, unitId)
	if unitId ~= "player" then return end
	self.stat.rangedHaste = API_GetRangedHaste()
	self.stat.snapshotTime = Ovale.now
end

function OvalePaperDoll:UNIT_RANGED_ATTACK_POWER(event, unitId)
	if unitId ~= "player" then return end
	local base, posBuff, negBuff = API_UnitRangedAttackPower(unitId)
	self.stat.rangedAttackPower = base + posBuff + negBuff
	self.stat.snapshotTime = Ovale.now
end

function OvalePaperDoll:UNIT_SPELL_HASTE(event, unitId)
	if unitId ~= "player" then return end
	self.stat.meleeHaste = API_GetMeleeHaste()
	self.stat.spellHaste = API_UnitSpellHaste(unitId)
	self.stat.snapshotTime = Ovale.now
end

function OvalePaperDoll:UNIT_STATS(event, unitId)
	if unitId ~= "player" then return end
	self.stat.strength = API_UnitStat(unitId, 1)
	self.stat.agility = API_UnitStat(unitId, 2)
	self.stat.stamina = API_UnitStat(unitId, 3)
	self.stat.intellect = API_UnitStat(unitId, 4)
	self.stat.spirit = API_UnitStat(unitId, 5)
	self.stat.snapshotTime = Ovale.now
	self:COMBAT_RATING_UPDATE(event)
end

function OvalePaperDoll:Ovale_EquipmentChanged(event)
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage = API_UnitDamage("player")
	self.stat.mainHandWeaponDamage = (minDamage + maxDamage) / 2
	if API_IsDualWielding() then
		self.stat.offHandWeaponDamage = (minOffHandDamage + maxOffHandDamage) / 2
	else
		self.stat.offHandWeaponDamage = 0
	end
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
	self:Ovale_EquipmentChanged(event)
end

function OvalePaperDoll:GetMasteryMultiplier()
	return 1 + self.stat.masteryEffect / 100
end

function OvalePaperDoll:GetMeleeHasteMultiplier()
	return 1 + self.stat.meleeHaste / 100
end

function OvalePaperDoll:GetRangedHasteMultiplier()
	return 1 + self.stat.rangedHaste / 100
end

function OvalePaperDoll:GetSpellHasteMultiplier()
	return 1 + self.stat.spellHaste / 100
end

-- Snapshot the stats into the given table using the same keynames as self.stat.
-- If source is nil, then use the current player stats; otherwise, use the given stat table.
-- Only take the snapshot if the source snapshot time is older than timestamp.
function OvalePaperDoll:SnapshotStats(timestamp, t, source)
	source = source or self.stat
	if timestamp and timestamp >= source.snapshotTime then
		for k in pairs(self.stat) do
			t[k] = source[k]
		end
		-- Also snapshot damageMultiplier if it's present (added by OvaleFuture and OvaleAura).
		t.damageMultiplier = source.damageMultiplier
	end
end

function OvalePaperDoll:Debug()
	Ovale:FormatPrint("Class: %s", self.class)
	Ovale:FormatPrint("Level: %d", self.level)
	Ovale:FormatPrint("Specialization: %s", self.specialization)
	Ovale:FormatPrint("Agility: %d", self.stat.agility)
	Ovale:FormatPrint("Intellect: %d", self.stat.intellect)
	Ovale:FormatPrint("Spirit: %d", self.stat.spirit)
	Ovale:FormatPrint("Stamina: %d", self.stat.stamina)
	Ovale:FormatPrint("Strength: %d", self.stat.strength)
	Ovale:FormatPrint("AP: %d", self.stat.attackPower)
	Ovale:FormatPrint("RAP: %d", self.stat.rangedAttackPower)
	Ovale:FormatPrint("Spell bonus damage: %d", self.stat.spellBonusDamage)
	Ovale:FormatPrint("Spell bonus healing: %d", self.stat.spellBonusHealing)
	Ovale:FormatPrint("Spell critical strike effect: %f%%", self.stat.spellCrit)
	Ovale:FormatPrint("Spell haste effect: %f%%", self.stat.spellHaste)
	Ovale:FormatPrint("Melee critical strike effect: %f%%", self.stat.meleeCrit)
	Ovale:FormatPrint("Melee haste effect: %f%%", self.stat.meleeHaste)
	Ovale:FormatPrint("Ranged critical strike effect: %f%%", self.stat.rangedCrit)
	Ovale:FormatPrint("Ranged haste effect: %f%%", self.stat.rangedHaste)
	Ovale:FormatPrint("Mastery effect: %f%%", self.stat.masteryEffect)
	Ovale:FormatPrint("Weapon damage (mainhand): %f", self.stat.mainHandWeaponDamage)
	Ovale:FormatPrint("Weapon damage (offhand): %f", self.stat.offHandWeaponDamage)
end
--</public-static-methods>
