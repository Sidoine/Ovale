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
local OvaleEquipement = Ovale.OvaleEquipement
local OvaleStance = Ovale.OvaleStance

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
local API_UnitAttackSpeed = UnitAttackSpeed
local API_UnitClass = UnitClass
local API_UnitDamage = UnitDamage
local API_UnitLevel = UnitLevel
local API_UnitRangedAttackPower = UnitRangedAttackPower
local API_UnitSpellHaste = UnitSpellHaste
local API_UnitStat = UnitStat

local OVALE_PAPERDOLL_DEBUG = "paper_doll"
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
	-- normalized weapon damage of mainhand and offhand weapons
	mainHandWeaponDamage = 0,
	offHandWeaponDamage = 0,
	-- damage multiplier
	damageMultiplier = 1,
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
	self:RegisterEvent("UNIT_DAMAGE", "UpdateDamage")
	self:RegisterEvent("UNIT_LEVEL")
	self:RegisterEvent("UNIT_RANGEDDAMAGE")
	self:RegisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:RegisterEvent("UNIT_SPELL_HASTE")
	self:RegisterEvent("UNIT_STATS")
	self:RegisterMessage("Ovale_EquipmentChanged", "UpdateDamage")
	self:RegisterMessage("Ovale_StanceChanged", "UpdateDamage")
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
	self:UnregisterEvent("UNIT_DAMAGE")
	self:UnregisterEvent("UNIT_LEVEL")
	self:UnregisterEvent("UNIT_RANGEDDAMAGE")
	self:UnregisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:UnregisterEvent("UNIT_SPELL_HASTE")
	self:UnregisterEvent("UNIT_STATS")
	self:UnregisterMessage("Ovale_EquipmentChanged")
	self:UnregisterMessage("Ovale_StanceChanged")
end

function OvalePaperDoll:COMBAT_RATING_UPDATE(event)
	self.stat.meleeCrit = API_GetCritChance()
	self.stat.rangedCrit = API_GetRangedCritChance()
	self.stat.spellCrit = API_GetSpellCritChance(OVALE_SPELLDAMAGE_SCHOOL[self.class])
	self.stat.snapshotTime = Ovale.now
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "%s @ %f", event, Ovale.now)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    melee critical strike chance = %f%%", self.stat.meleeCrit)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    ranged critical strike chance = %f%%", self.stat.rangedCrit)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    spell critical strike chance = %f%%", self.stat.spellCrit)
end

function OvalePaperDoll:MASTERY_UPDATE(event)
	if self.level < 80 then
		self.stat.masteryEffect = 0
	else
		self.stat.masteryEffect = API_GetMasteryEffect()
		self.stat.snapshotTime = Ovale.now
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "%s @ %f: mastery effect = %f%%", event, Ovale.now, self.stat.masteryEffect)
	end
end

function OvalePaperDoll:PLAYER_LEVEL_UP(event, level, ...)
	self.level = tonumber(level) or API_UnitLevel("player")
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "%s @ %f: level = %d", event, Ovale.now, self.level)
end

function OvalePaperDoll:PLAYER_DAMAGE_DONE_MODS(event, unitId)
	self.stat.spellBonusHealing = API_GetSpellBonusHealing()
	self.stat.snapshotTime = Ovale.now
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "%s @ %f: spell bonus healing = %d", event, Ovale.now, self.stat.spellBonusHealing)
end

function OvalePaperDoll:SPELL_POWER_CHANGED(event)
	self.stat.spellBonusDamage = API_GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[self.class])
	self.stat.snapshotTime = Ovale.now
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "%s @ %f: spell bonus damage = %d", event, Ovale.now, self.stat.spellBonusDamage)
end

function OvalePaperDoll:UNIT_ATTACK_POWER(event, unitId)
	if unitId == "player" then
		local base, posBuff, negBuff = API_UnitAttackPower(unitId)
		self.stat.attackPower = base + posBuff + negBuff
		self.stat.snapshotTime = Ovale.now
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "%s @ %f: attack power = %d", event, Ovale.now, self.stat.attackPower)
		self:UpdateDamage(event)
	end
end

function OvalePaperDoll:UNIT_LEVEL(event, unitId)
	if unitId == "player" then
		self.level = API_UnitLevel(unitId)
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "%s @ %f: level = %d", event, Ovale.now, self.level)
	end
end

function OvalePaperDoll:UNIT_RANGEDDAMAGE(event, unitId)
	if unitId == "player" then
		self.stat.rangedHaste = API_GetRangedHaste()
		self.stat.snapshotTime = Ovale.now
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "%s @ %f: ranged haste effect = %f%%", event, Ovale.now, self.stat.rangedHaste)
	end
end

function OvalePaperDoll:UNIT_RANGED_ATTACK_POWER(event, unitId)
	if unitId == "player" then
		local base, posBuff, negBuff = API_UnitRangedAttackPower(unitId)
		self.stat.rangedAttackPower = base + posBuff + negBuff
		self.stat.snapshotTime = Ovale.now
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "%s @ %f: ranged attack power = %d", event, Ovale.now, self.stat.rangedAttackPower)
	end
end

function OvalePaperDoll:UNIT_SPELL_HASTE(event, unitId)
	if unitId == "player" then
		self.stat.meleeHaste = API_GetMeleeHaste()
		self.stat.spellHaste = API_UnitSpellHaste(unitId)
		self.stat.snapshotTime = Ovale.now
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "%s @ %f", event, Ovale.now)
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    melee haste effect = %f%%", self.stat.meleeHaste)
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    spell haste effect = %f%%", self.stat.spellHaste)
		self:UpdateDamage(event)
	end
end

function OvalePaperDoll:UNIT_STATS(event, unitId)
	if unitId ~= "player" then return end
	self.stat.strength = API_UnitStat(unitId, 1)
	self.stat.agility = API_UnitStat(unitId, 2)
	self.stat.stamina = API_UnitStat(unitId, 3)
	self.stat.intellect = API_UnitStat(unitId, 4)
	self.stat.spirit = API_UnitStat(unitId, 5)
	self.stat.snapshotTime = Ovale.now
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "%s @ %f", event, Ovale.now)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    agility = %d", self.stat.agility)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    intellect = %d", self.stat.intellect)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    spirit = %d", self.stat.spirit)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    stamina = %d", self.stat.stamina)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    strength = %d", self.stat.strength)
	self:COMBAT_RATING_UPDATE(event)
end

function OvalePaperDoll:UpdateDamage(event)
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, _, _, damageMultiplier = API_UnitDamage("player")
	local mainHandAttackSpeed, offHandAttackSpeed = API_UnitAttackSpeed("player")

	self.stat.damageMultiplier = damageMultiplier
	if self.class == "DRUID" and OvaleStance:IsStance("druid_cat_form") then
		-- Cat Form: 100% increased auto-attack damage.
		damageMultiplier = damageMultiplier * 2
	elseif self.class == "MONK" and OvaleEquipement:HasOneHandedWeapon() then
		-- Way of the Monk: 40% increased auto-attack damage if dual-wielding.
		damageMultiplier = damageMultiplier * 1.4
	end

	-- weaponDamage = (weaponDPS + attackPower / 14) * weaponSpeed
	-- normalizedWeaponDamage = (weaponDPS + attackPower / 14) * normalizedWeaponSpeed
	local avgDamage = (minDamage + maxDamage) / 2 / damageMultiplier
	local mainHandWeaponSpeed = mainHandAttackSpeed * self:GetMeleeHasteMultiplier()
	local normalizedMainHandWeaponSpeed = OvaleEquipement.mainHandWeaponSpeed or 0
	if self.class == "DRUID" then
		if OvaleStance:IsStance("druid_cat_form") then
			normalizedMainHandWeaponSpeed = 1
		elseif OvaleStance:IsStance("druid_bear_form") then
			normalizedMainHandWeaponSpeed = 2.5
		end
	end
	self.stat.mainHandWeaponDamage = avgDamage / mainHandWeaponSpeed * normalizedMainHandWeaponSpeed
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    MH weapon damage = ((%f + %f) / 2 / %f) / %f * %f",
		minDamage, maxDamage, damageMultiplier, mainHandWeaponSpeed, normalizedMainHandWeaponSpeed)

	if OvaleEquipement:HasOffHandWeapon() then
		local avgOffHandDamage = (minOffHandDamage + maxOffHandDamage) / 2 / damageMultiplier
		-- Sometimes, UnitAttackSpeed() doesn't return a value for OH attack speed, so approximate with MH one.
		offHandAttackSpeed = offHandAttackSpeed or mainHandAttackSpeed
		local offHandWeaponSpeed = offHandAttackSpeed * self:GetMeleeHasteMultiplier()
		local normalizedOffHandWeaponSpeed = OvaleEquipement.offHandWeaponSpeed or 0
		if self.class == "DRUID" then
			if OvaleStance:IsStance("druid_cat_form") then
				normalizedOffHandWeaponSpeed = 1
			elseif OvaleStance:IsStance("druid_bear_form") then
				normalizedOffHandWeaponSpeed = 2.5
			end
		end
		self.stat.offHandWeaponDamage = avgOffHandDamage / offHandWeaponSpeed * normalizedOffHandWeaponSpeed
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    OH weapon damage = ((%f + %f) / 2 / %f) / %f * %f",
			minOffHandDamage, maxOffHandDamage, damageMultiplier, offHandWeaponSpeed, normalizedOffHandWeaponSpeed)
	else
		self.stat.offHandWeaponDamage = 0
	end
	self.stat.snapshotTime = Ovale.now

	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "%s @ %f", event, Ovale.now)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    damage multiplier = %f", self.stat.damageMultiplier)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    weapon damage (mainhand): %f", self.stat.mainHandWeaponDamage)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    weapon damage (offhand): %f", self.stat.offHandWeaponDamage)
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
	self:UpdateDamage(event)
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
function OvalePaperDoll:SnapshotStats(t, source)
	if not source then
		self:UpdateStats()
		source = self.stat
	end
	for k in pairs(self.stat) do
		if source[k] then
			t[k] = source[k]
		end
	end
	-- Copy other properties that are relevant for auras that might be present.
	-- TODO: Holy power?
	if source.comboPoints then
		t.comboPoints = source.comboPoints
	end
end

function OvalePaperDoll:Debug(stat)
	stat = stat or self.stat
	Ovale:FormatPrint("Class: %s", self.class)
	Ovale:FormatPrint("Level: %d", self.level)
	Ovale:FormatPrint("Specialization: %s", self.specialization)
	Ovale:FormatPrint("Agility: %d", stat.agility)
	Ovale:FormatPrint("Intellect: %d", stat.intellect)
	Ovale:FormatPrint("Spirit: %d", stat.spirit)
	Ovale:FormatPrint("Stamina: %d", stat.stamina)
	Ovale:FormatPrint("Strength: %d", stat.strength)
	Ovale:FormatPrint("Attack power: %d", stat.attackPower)
	Ovale:FormatPrint("Ranged attack power: %d", stat.rangedAttackPower)
	Ovale:FormatPrint("Spell bonus damage: %d", stat.spellBonusDamage)
	Ovale:FormatPrint("Spell bonus healing: %d", stat.spellBonusHealing)
	Ovale:FormatPrint("Spell critical strike effect: %f%%", stat.spellCrit)
	Ovale:FormatPrint("Spell haste effect: %f%%", stat.spellHaste)
	Ovale:FormatPrint("Melee critical strike effect: %f%%", stat.meleeCrit)
	Ovale:FormatPrint("Melee haste effect: %f%%", stat.meleeHaste)
	Ovale:FormatPrint("Ranged critical strike effect: %f%%", stat.rangedCrit)
	Ovale:FormatPrint("Ranged haste effect: %f%%", stat.rangedHaste)
	Ovale:FormatPrint("Mastery effect: %f%%", stat.masteryEffect)
	Ovale:FormatPrint("Damage multiplier: %f", stat.damageMultiplier)
	Ovale:FormatPrint("Weapon damage (mainhand): %f", stat.mainHandWeaponDamage)
	Ovale:FormatPrint("Weapon damage (offhand): %f", stat.offHandWeaponDamage)
end
--</public-static-methods>
