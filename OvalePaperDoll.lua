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
local OvalePool = Ovale.OvalePool
local OvaleQueue = Ovale.OvaleQueue
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
local API_GetTime = GetTime
local API_UnitAttackPower = UnitAttackPower
local API_UnitAttackSpeed = UnitAttackSpeed
local API_UnitClass = UnitClass
local API_UnitDamage = UnitDamage
local API_UnitLevel = UnitLevel
local API_UnitRangedAttackPower = UnitRangedAttackPower
local API_UnitSpellHaste = UnitSpellHaste
local API_UnitStat = UnitStat

-- Player's class.
local self_class = select(2, API_UnitClass("player"))
-- Snapshot table pool.
local self_pool = OvalePool("OvalePaperDoll_pool")
-- Snapshot queue: new snapshots are inserted at the front of the queue.
local self_snapshot = OvaleQueue:NewDeque("OvalePaperDoll_snapshot")
-- Total number of snapshots taken.
local self_snapshotCount = 0
-- Time window (past number of seconds) for which snapshots are stored.
local SNAPSHOT_WINDOW = 5

local OVALE_PAPERDOLL_DEBUG = "paper_doll"
local OVALE_SNAPSHOT_DEBUG = "snapshot"

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
-- player's level
OvalePaperDoll.level = API_UnitLevel("player")
-- Player's current specialization.
OvalePaperDoll.specialization = nil
-- Most recent snapshot.
OvalePaperDoll.stat = nil

-- Maps field names to default value & descriptions for player's stats.
OvalePaperDoll.SNAPSHOT_STATS = {
	snapshotTime =			{ default = 0, description = "snapshot time" }

	-- primary stats
	agility = 				{ default = 0, description = "agility" },
	intellect =				{ default = 0, description = "intellect" },
	spirit =				{ default = 0, description = "spirit" },
	stamina =				{ default = 0, description = "stamina" },
	strength =				{ default = 0, description = "strength" },

	attackPower =			{ default = 0, description = "attack power" },
	rangedAttackPower =		{ default = 0, description = "ranged attack power" },
	-- percent increase of effect due to mastery
	masteryEffect =			{ default = 0, description = "mastery effect" },
	-- percent increase to melee critical strike & haste
	meleeCrit =				{ default = 0, description = "melee critical strike chance" },
	meleeHaste =			{ default = 0, description = "melee haste effect" },
	-- percent increase to ranged critical strike & haste
	rangedCrit =			{ default = 0, description = "ranged critical strike chance" },
	rangedHaste =			{ default = 0, description = "ranged haste effect" },
	-- percent increase to spell critical strike & haste
	spellCrit =				{ default = 0, description = "spell critical strike chance" },
	spellHaste =			{ default = 0, description = "spell haste effect" },
	-- spellpower
	spellBonusDamage =		{ default = 0, description = "spell bonus damage" },
	spellBonusHealing =		{ default = 0, description = "spell bonus healing" },
	-- normalized weapon damage of mainhand and offhand weapons
	mainHandWeaponDamage =	{ default = 0, description = "normalized weapon damage (mainhand)" },
	offHandWeaponDamage =	{ default = 0, description = "normalized weapon damage (offhand)" },
	baseDamageMultiplier =	{ default = 1, description = "base damage multiplier" },
}
--</public-static-properties>

--<private-static-methods>
-- Return stat table for most recent snapshot no older than the given time.
local function GetSnapshot(t)
	local self = OvalePaperDoll
	self:RemoveOldSnapshots()
	local stat = self_snapshot:Front()
	local now = API_GetTime()
	if not stat then
		local newStat = self_pool:Get()
		do
			-- Initialize stat table.
			for k, info in pairs(self.SNAPSHOT_STATS) do
				newStat[k] = info.default
			end
		end
		newStat.snapshotTime = now
		self_snapshot:InsertFront(newStat)
		stat = self_snapshot:Front()
	elseif stat.snapshotTime < t then
		local newStat = self_pool:Get()
		self:SnapshotStats(newStat, stat)
		newStat.snapshotTime = now
		self_snapshot:InsertFront(newStat)
		stat = self_snapshot:Front()
		Ovale:DebugPrintf(OVALE_SNAPSHOT_DEBUG, true, "New snapshot.")
		self_snapshotCount = self_snapshotCount + 1
	end
	return stat
end
--</private-static-methods>

--<public-static-methods>
function OvalePaperDoll:OnEnable()
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "UpdateStats")
	self:RegisterEvent("COMBAT_RATING_UPDATE")
	self:RegisterEvent("MASTERY_UPDATE")
	self:RegisterEvent("PLAYER_ALIVE", "UpdateStats")
	self:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStats")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
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

	local now = API_GetTime()
	self.stat = GetSnapshot(now)
end

function OvalePaperDoll:OnDisable()
	self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:UnregisterEvent("COMBAT_RATING_UPDATE")
	self:UnregisterEvent("MASTERY_UPDATE")
	self:UnregisterEvent("PLAYER_ALIVE")
	self:UnregisterEvent("PLAYER_DAMAGE_DONE_MODS")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_LEVEL_UP")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
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
	local now = API_GetTime()
	self.stat = GetSnapshot(now)
	self.stat.meleeCrit = API_GetCritChance()
	self.stat.rangedCrit = API_GetRangedCritChance()
	self.stat.spellCrit = API_GetSpellCritChance(OVALE_SPELLDAMAGE_SCHOOL[self_class])
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, true, "%s", event)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    %s = %f%%", self.SNAPSHOT_STATS["meleeCrit"].description, self.stat.meleeCrit)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    %s = %f%%", self.SNAPSHOT_STATS["rangedCrit"].description, self.stat.rangedCrit)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    %s = %f%%", self.SNAPSHOT_STATS["spellCrit"].description, self.stat.spellCrit)
end

function OvalePaperDoll:MASTERY_UPDATE(event)
	local now = API_GetTime()
	self.stat = GetSnapshot(now)
	if self.level < 80 then
		self.stat.masteryEffect = 0
	else
		self.stat.masteryEffect = API_GetMasteryEffect()
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, true, "%s: %s = %f%%",
			event, self.SNAPSHOT_STATS["masteryEffect"].description, self.stat.masteryEffect)
	end
end

function OvalePaperDoll:PLAYER_LEVEL_UP(event, level, ...)
	self.level = tonumber(level) or API_UnitLevel("player")
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, true, "%s: level = %d", event, self.level)
end

function OvalePaperDoll:PLAYER_DAMAGE_DONE_MODS(event, unitId)
	local now = API_GetTime()
	self.stat = GetSnapshot(now)
	self.stat.spellBonusHealing = API_GetSpellBonusHealing()
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, true, "%s: %s = %d",
		event, self.SNAPSHOT_STATS["spellBonusHealing"].description, self.stat.spellBonusHealing)
end

function OvalePaperDoll:PLAYER_REGEN_DISABLED(event)
	self_snapshotCount = 0
end

function OvalePaperDoll:PLAYER_REGEN_ENABLED(event)
	local now = API_GetTime()
	if Ovale.enCombat and Ovale.combatStartTime then
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, true, "%d snapshots in %f seconds.",
			self_snapshotCount, now - Ovale.combatStartTime)
	end
	self_pool:Drain()
end

function OvalePaperDoll:SPELL_POWER_CHANGED(event)
	local now = API_GetTime()
	self.stat = GetSnapshot(now)
	self.stat.spellBonusDamage = API_GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[self_class])
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, true, "%s: %s = %d",
		event, self.SNAPSHOT_STATS["spellBonusDamage"].description, self.stat.spellBonusDamage)
end

function OvalePaperDoll:UNIT_ATTACK_POWER(event, unitId)
	if unitId == "player" then
		local now = API_GetTime()
		self.stat = GetSnapshot(now)
		local base, posBuff, negBuff = API_UnitAttackPower(unitId)
		self.stat.attackPower = base + posBuff + negBuff
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, true, "%s: %s = %d",
			event, self.SNAPSHOT_STATS["attackPower"].description, self.stat.attackPower)
		self:UpdateDamage(event)
	end
end

function OvalePaperDoll:UNIT_LEVEL(event, unitId)
	if unitId == "player" then
		self.level = API_UnitLevel(unitId)
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, true, "%s: level = %d", event, self.level)
	end
end

function OvalePaperDoll:UNIT_RANGEDDAMAGE(event, unitId)
	if unitId == "player" then
		local now = API_GetTime()
		self.stat = GetSnapshot(now)
		self.stat.rangedHaste = API_GetRangedHaste()
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, true, "%s: %s = %f%%",
			event, self.SNAPSHOT_STATS["rangedHaste"].description, self.stat.rangedHaste)
	end
end

function OvalePaperDoll:UNIT_RANGED_ATTACK_POWER(event, unitId)
	if unitId == "player" then
		local base, posBuff, negBuff = API_UnitRangedAttackPower(unitId)
		local now = API_GetTime()
		self.stat = GetSnapshot(now)
		self.stat.rangedAttackPower = base + posBuff + negBuff
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, true, "%s: %s = %d",
			event, self.SNAPSHOT_STATS["rangedAttackPower"].description, self.stat.rangedAttackPower)
	end
end

function OvalePaperDoll:UNIT_SPELL_HASTE(event, unitId)
	if unitId == "player" then
		local now = API_GetTime()
		self.stat = GetSnapshot(now)
		self.stat.meleeHaste = API_GetMeleeHaste()
		self.stat.spellHaste = API_UnitSpellHaste(unitId)
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, true, "%s", event)
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    %s = %f%%", self.SNAPSHOT_STATS["meleeHaste"].description, self.stat.meleeHaste)
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    %s = %f%%", self.SNAPSHOT_STATS["spellHaste"].description, self.stat.spellHaste)
		self:UpdateDamage(event)
	end
end

function OvalePaperDoll:UNIT_STATS(event, unitId)
	if unitId == "player" then
		local now = API_GetTime()
		self.stat = GetSnapshot(now)
		self.stat.strength = API_UnitStat(unitId, 1)
		self.stat.agility = API_UnitStat(unitId, 2)
		self.stat.stamina = API_UnitStat(unitId, 3)
		self.stat.intellect = API_UnitStat(unitId, 4)
		self.stat.spirit = API_UnitStat(unitId, 5)
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, true, "%s", event)
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    %s = %d", self.SNAPSHOT_STATS["agility"].description, self.stat.agility)
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    %s = %d", self.SNAPSHOT_STATS["intellect"].description, self.stat.intellect)
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    %s = %d", self.SNAPSHOT_STATS["spirit"].description, self.stat.spirit)
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    %s = %d", self.SNAPSHOT_STATS["stamina"].description, self.stat.stamina)
		Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    %s = %d", self.SNAPSHOT_STATS["strength"].description, self.stat.strength)
		self:COMBAT_RATING_UPDATE(event)
	end
end

function OvalePaperDoll:UpdateDamage(event)
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, _, _, damageMultiplier = API_UnitDamage("player")
	local mainHandAttackSpeed, offHandAttackSpeed = API_UnitAttackSpeed("player")

	local now = API_GetTime()
	self.stat = GetSnapshot(now)
	self.stat.baseDamageMultiplier = damageMultiplier
	if self_class == "DRUID" and OvaleStance:IsStance("druid_cat_form") then
		-- Cat Form: 100% increased auto-attack damage.
		damageMultiplier = damageMultiplier * 2
	elseif self_class == "MONK" and OvaleEquipement:HasOneHandedWeapon() then
		-- Way of the Monk: 40% increased auto-attack damage if dual-wielding.
		damageMultiplier = damageMultiplier * 1.4
	end

	-- weaponDamage = (weaponDPS + attackPower / 14) * weaponSpeed
	-- normalizedWeaponDamage = (weaponDPS + attackPower / 14) * normalizedWeaponSpeed
	local avgDamage = (minDamage + maxDamage) / 2 / damageMultiplier
	local mainHandWeaponSpeed = mainHandAttackSpeed * self:GetMeleeHasteMultiplier()
	local normalizedMainHandWeaponSpeed = OvaleEquipement.mainHandWeaponSpeed or 0
	if self_class == "DRUID" then
		if OvaleStance:IsStance("druid_cat_form") then
			normalizedMainHandWeaponSpeed = 1
		elseif OvaleStance:IsStance("druid_bear_form") then
			normalizedMainHandWeaponSpeed = 2.5
		end
	end
	self.stat.mainHandWeaponDamage = avgDamage / mainHandWeaponSpeed * normalizedMainHandWeaponSpeed
	--Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    MH weapon damage = ((%f + %f) / 2 / %f) / %f * %f",
	--	minDamage, maxDamage, damageMultiplier, mainHandWeaponSpeed, normalizedMainHandWeaponSpeed)

	if OvaleEquipement:HasOffHandWeapon() then
		local avgOffHandDamage = (minOffHandDamage + maxOffHandDamage) / 2 / damageMultiplier
		-- Sometimes, UnitAttackSpeed() doesn't return a value for OH attack speed, so approximate with MH one.
		offHandAttackSpeed = offHandAttackSpeed or mainHandAttackSpeed
		local offHandWeaponSpeed = offHandAttackSpeed * self:GetMeleeHasteMultiplier()
		local normalizedOffHandWeaponSpeed = OvaleEquipement.offHandWeaponSpeed or 0
		if self_class == "DRUID" then
			if OvaleStance:IsStance("druid_cat_form") then
				normalizedOffHandWeaponSpeed = 1
			elseif OvaleStance:IsStance("druid_bear_form") then
				normalizedOffHandWeaponSpeed = 2.5
			end
		end
		self.stat.offHandWeaponDamage = avgOffHandDamage / offHandWeaponSpeed * normalizedOffHandWeaponSpeed
		--Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    OH weapon damage = ((%f + %f) / 2 / %f) / %f * %f",
		--	minOffHandDamage, maxOffHandDamage, damageMultiplier, offHandWeaponSpeed, normalizedOffHandWeaponSpeed)
	else
		self.stat.offHandWeaponDamage = 0
	end

	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, true, "%s", event)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    %s = %f", self.SNAPSHOT_STATS["baseDamageMultiplier"].description, self.stat.baseDamageMultiplier)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    %s = %f", self.SNAPSHOT_STATS["mainHandWeaponDamage"].description, self.stat.mainHandWeaponDamage)
	Ovale:DebugPrintf(OVALE_PAPERDOLL_DEBUG, "    %s = %f", self.SNAPSHOT_STATS["offHandWeaponDamage"].description, self.stat.offHandWeaponDamage)
end

function OvalePaperDoll:UpdateSpecialization(event)
	local newSpecialization = API_GetSpecialization()
	if self.specialization ~= newSpecialization then
		self.specialization = newSpecialization
		self:SendMessage("Ovale_SpecializationChanged", self.specialization)
	end
end

function OvalePaperDoll:UpdateStats(event)
	self:UpdateSpecialization(event)
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

-- Snapshot the stats into the given table using the same keynames as SNAPSHOT_STATS.
-- If source is nil, then use the most recent player stats; otherwise, use the given stat table.
function OvalePaperDoll:SnapshotStats(t, source)
	if not source then
		self:UpdateStats("SnapshotStats")
		source = self_snapshot:Front()
	end
	for k in pairs(self.SNAPSHOT_STATS) do
		if source[k] then
			t[k] = source[k]
		end
	end
	-- Copy other properties that might be present that are relevant for auras.
	-- TODO: Holy power?
	if source.comboPoints then
		t.comboPoints = source.comboPoints
	end
end

-- Remove snapshots older than SNAPSHOT_WINDOW seconds from now, but always leave most recent snapshot.
function OvalePaperDoll:RemoveOldSnapshots()
	local now = API_GetTime()
	while self_snapshot:Size() > 1 do
		local stat = self_snapshot:Back()
		if stat then
			if now - stat.snapshotTime < SNAPSHOT_WINDOW then break end
			self_snapshot:RemoveBack()
			self_pool:Release(stat)
		end
	end
end

function OvalePaperDoll:Debug(stat)
	stat = stat or self.stat
	Ovale:FormatPrint("Level: %d", self.level)
	Ovale:FormatPrint("Specialization: %s", self.specialization)
	Ovale:FormatPrint("Total snapshots: %d", self_snapshotCount)
	Ovale:FormatPrint("Snapshot time: %f", stat.snapshotTime)
	Ovale:FormatPrint("%s: %d", self.SNAPSHOT_STATS["agility"].description, stat.agility)
	Ovale:FormatPrint("%s: %d", self.SNAPSHOT_STATS["intellect"].description, stat.intellect)
	Ovale:FormatPrint("%s: %d", self.SNAPSHOT_STATS["spirit"].description, stat.spirit)
	Ovale:FormatPrint("%s: %d", self.SNAPSHOT_STATS["stamina"].description, stat.stamina)
	Ovale:FormatPrint("%s: %d", self.SNAPSHOT_STATS["strength"].description, stat.strength)
	Ovale:FormatPrint("%s: %d", self.SNAPSHOT_STATS["attackPower"].description, stat.attackPower)
	Ovale:FormatPrint("%s: %d", self.SNAPSHOT_STATS["rangedAttackPower"].description, stat.rangedAttackPower)
	Ovale:FormatPrint("%s: %d", self.SNAPSHOT_STATS["spellBonusDamage"].description, stat.spellBonusDamage)
	Ovale:FormatPrint("%s: %d", self.SNAPSHOT_STATS["spellBonusHealing"].description, stat.spellBonusHealing)
	Ovale:FormatPrint("%s: %f%%", self.SNAPSHOT_STATS["spellCrit"].description, stat.spellCrit)
	Ovale:FormatPrint("%s: %f%%", self.SNAPSHOT_STATS["spellHaste"].description, stat.spellHaste)
	Ovale:FormatPrint("%s: %f%%", self.SNAPSHOT_STATS["meleeCrit"].description, stat.meleeCrit)
	Ovale:FormatPrint("%s: %f%%", self.SNAPSHOT_STATS["meleeHaste"].description, stat.meleeHaste)
	Ovale:FormatPrint("%s: %f%%", self.SNAPSHOT_STATS["rangedCrit"].description, stat.rangedCrit)
	Ovale:FormatPrint("%s: %f%%", self.SNAPSHOT_STATS["rangedHaste"].description, stat.rangedHaste)
	Ovale:FormatPrint("%s: %f%%", self.SNAPSHOT_STATS["masteryEffect"].description, stat.masteryEffect)
	Ovale:FormatPrint("%s: %f", self.SNAPSHOT_STATS["baseDamageMultiplier"].description, stat.baseDamageMultiplier)
	Ovale:FormatPrint("%s: %f", self.SNAPSHOT_STATS["mainHandWeaponDamage"].description, stat.mainHandWeaponDamage)
	Ovale:FormatPrint("%s: %f", self.SNAPSHOT_STATS["offHandWeaponDamage"].description, stat.offHandWeaponDamage)
end
--</public-static-methods>
