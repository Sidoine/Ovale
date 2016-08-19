--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- This addon tracks the player's stats as available on the in-game paper doll.

local OVALE, Ovale = ...
local OvalePaperDoll = Ovale:NewModule("OvalePaperDoll", "AceEvent-3.0")
Ovale.OvalePaperDoll = OvalePaperDoll

--<private-static-properties>
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleEquipment = nil
local OvaleFuture = nil
local OvaleStance = nil
local OvaleState = nil

local pairs = pairs
local select = select
local tonumber = tonumber
local type = type
local API_GetCombatRating = GetCombatRating
local API_GetCritChance = GetCritChance
local API_GetMastery = GetMastery
local API_GetMasteryEffect = GetMasteryEffect
local API_GetMeleeHaste = GetMeleeHaste
local API_GetMultistrike = GetMultistrike
local API_GetMultistrikeEffect = GetMultistrikeEffect
local API_GetRangedCritChance = GetRangedCritChance
local API_GetRangedHaste = GetRangedHaste
local API_GetSpecialization = GetSpecialization
local API_GetSpellBonusDamage = GetSpellBonusDamage
local API_GetSpellBonusHealing = GetSpellBonusHealing
local API_GetSpellCritChance = GetSpellCritChance
local API_GetTime = GetTime
local API_UnitAttackPower = UnitAttackPower
local API_UnitAttackSpeed = UnitAttackSpeed
local API_UnitDamage = UnitDamage
local API_UnitLevel = UnitLevel
local API_UnitRangedAttackPower = UnitRangedAttackPower
local API_UnitSpellHaste = UnitSpellHaste
local API_UnitStat = UnitStat
local CR_CRIT_MELEE = CR_CRIT_MELEE
local CR_HASTE_MELEE = CR_HASTE_MELEE

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvalePaperDoll)
-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvalePaperDoll)

local self_playerGUID = nil

local OVALE_SPELLDAMAGE_SCHOOL = {
	DEATHKNIGHT = 4, -- Nature
	DEMONHUNTER = 3, -- Fire
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
local OVALE_SPECIALIZATION_NAME = {
	DEATHKNIGHT = { "blood", "frost", "unholy" },
	DEMONHUNTER = { "havoc", "vengeance" },
	DRUID = { "balance", "feral", "guardian", "restoration" },
	HUNTER = { "beast_mastery", "marksmanship", "survival" },
	MAGE = { "arcane", "fire", "frost" },
	MONK = { "brewmaster", "mistweaver", "windwalker" },
	PALADIN = { "holy", "protection", "retribution" },
	PRIEST = { "discipline", "holy", "shadow" },
	ROGUE = { "assassination", "outlaw", "subtlety" },
	SHAMAN = { "elemental", "enhancement", "restoration" },
	WARLOCK = { "affliction", "demonology", "destruction" },
	WARRIOR = { "arms", "fury", "protection" },
}
--</private-static-properties>

--<public-static-properties>
-- Player's class.
OvalePaperDoll.class = Ovale.playerClass
-- Player's level.
OvalePaperDoll.level = API_UnitLevel("player")
-- Player's current specialization.
OvalePaperDoll.specialization = nil
-- Names of paper doll stats.
OvalePaperDoll.STAT_NAME = {
-- Most recent snapshot time.
	snapshotTime = true,
-- Primary stats.
	agility = true,
	intellect = true,
	spirit = true,
	stamina = true,
	strength = true,
	attackPower = true,
	rangedAttackPower = true,
	spellBonusDamage = true,
	spellBonusHealing = true,
-- Percent increase of effect due to mastery.
	masteryEffect = true,
-- Percent increase to melee critical strike and haste.
	meleeCrit = true,
	meleeHaste = true,
-- Percent increase to ranged critical strike and haste.
	rangedCrit = true,
	rangedHaste = true,
-- Percent increase to spell critical strike and haste.
	spellCrit = true,
	spellHaste = true,
-- Percent chance to multistrike.
	multistrike = true,
-- Combat ratings.
	critRating = true,
	hasteRating = true,
	masteryRating = true,
	multistrikeRating = true,
-- Normalized weapon damage of mainhand and offhand weapons.
	mainHandWeaponDamage = true,
	offHandWeaponDamage = true,
-- Damage multiplier.
	baseDamageMultiplier = true,
}
-- SNAPSHOT_STAT_NAME[statName] = true if statName may be snapshot into an aura or channeled spell.
OvalePaperDoll.SNAPSHOT_STAT_NAME = {
	snapshotTime = true,
	masteryEffect = true,
	baseDamageMultiplier = true,
}

OvalePaperDoll.snapshotTime = 0
OvalePaperDoll.agility = 0
OvalePaperDoll.intellect = 0
OvalePaperDoll.spirit = 0
OvalePaperDoll.stamina = 0
OvalePaperDoll.strength = 0
OvalePaperDoll.attackPower = 0
OvalePaperDoll.rangedAttackPower = 0
OvalePaperDoll.spellBonusDamage = 0
OvalePaperDoll.spellBonusHealing = 0
OvalePaperDoll.masteryEffect = 0
OvalePaperDoll.meleeCrit = 0
OvalePaperDoll.meleeHaste = 0
OvalePaperDoll.rangedCrit = 0
OvalePaperDoll.rangedHaste = 0
OvalePaperDoll.spellCrit = 0
OvalePaperDoll.spellHaste = 0
OvalePaperDoll.multistrike = 0
OvalePaperDoll.critRating = 0
OvalePaperDoll.hasteRating = 0
OvalePaperDoll.masteryRating = 0
OvalePaperDoll.multistrikeRating = 0
OvalePaperDoll.mainHandWeaponDamage = 0
OvalePaperDoll.offHandWeaponDamage = 0
OvalePaperDoll.baseDamageMultiplier = 1
--</public-static-properties>

--<public-static-methods>
function OvalePaperDoll:OnInitialize()
	-- Resolve module dependencies.
	OvaleEquipment = Ovale.OvaleEquipment
	OvaleFuture = Ovale.OvaleFuture
	OvaleStance = Ovale.OvaleStance
	OvaleState = Ovale.OvaleState
end

function OvalePaperDoll:OnEnable()
	self_playerGUID = Ovale.playerGUID
	self:RegisterEvent("COMBAT_RATING_UPDATE")
	self:RegisterEvent("MASTERY_UPDATE")
	self:RegisterEvent("MULTISTRIKE_UPDATE")
	self:RegisterEvent("PLAYER_ALIVE", "UpdateStats")
	self:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStats")
	self:RegisterEvent("PLAYER_LEVEL_UP")
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
	self:RegisterMessage("Ovale_TalentsChanged", "UpdateStats")
	OvaleFuture:RegisterSpellcastInfo(self)
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvalePaperDoll:OnDisable()
	OvaleState:UnregisterState(self)
	OvaleFuture:UnregisterSpellcastInfo(self)
	self:UnregisterEvent("COMBAT_RATING_UPDATE")
	self:UnregisterEvent("MASTERY_UPDATE")
	self:UnregisterEvent("MULTISTRIKE_UPDATE")
	self:UnregisterEvent("PLAYER_ALIVE")
	self:UnregisterEvent("PLAYER_DAMAGE_DONE_MODS")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_LEVEL_UP")
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
	self:UnregisterMessage("Ovale_TalentsChanged")
end

function OvalePaperDoll:COMBAT_RATING_UPDATE(event)
	self:StartProfiling("OvalePaperDoll_UpdateStats")
	self.meleeCrit = API_GetCritChance()
	self.rangedCrit = API_GetRangedCritChance()
	self.spellCrit = API_GetSpellCritChance(OVALE_SPELLDAMAGE_SCHOOL[self.class])
	self.critRating = API_GetCombatRating(CR_CRIT_MELEE)
	self.hasteRating = API_GetCombatRating(CR_HASTE_MELEE)
	self.snapshotTime = API_GetTime()
	Ovale.refreshNeeded[self_playerGUID] = true
	self:StopProfiling("OvalePaperDoll_UpdateStats")
end

function OvalePaperDoll:MASTERY_UPDATE(event)
	self:StartProfiling("OvalePaperDoll_UpdateStats")
	self.masteryRating = API_GetMastery()
	if self.level < 80 then
		self.masteryEffect = 0
	else
		self.masteryEffect = API_GetMasteryEffect()
		Ovale.refreshNeeded[self_playerGUID] = true
	end
	self.snapshotTime = API_GetTime()
	self:StopProfiling("OvalePaperDoll_UpdateStats")
end

function OvalePaperDoll:MULTISTRIKE_UPDATE(event)
	self:StartProfiling("OvalePaperDoll_UpdateStats")
	self.multistrikeRating = API_GetMultistrike()
	self.multistrike = API_GetMultistrikeEffect()
	self.snapshotTime = API_GetTime()
	Ovale.refreshNeeded[self_playerGUID] = true
	self:StopProfiling("OvalePaperDoll_UpdateStats")
end

function OvalePaperDoll:PLAYER_LEVEL_UP(event, level, ...)
	self:StartProfiling("OvalePaperDoll_UpdateStats")
	self.level = tonumber(level) or API_UnitLevel("player")
	self.snapshotTime = API_GetTime()
	Ovale.refreshNeeded[self_playerGUID] = true
	self:DebugTimestamp("%s: level = %d", event, self.level)
	self:StopProfiling("OvalePaperDoll_UpdateStats")
end

function OvalePaperDoll:PLAYER_DAMAGE_DONE_MODS(event, unitId)
	self:StartProfiling("OvalePaperDoll_UpdateStats")
	self.spellBonusDamage = API_GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[self.class])
	self.spellBonusHealing = API_GetSpellBonusHealing()
	self.snapshotTime = API_GetTime()
	Ovale.refreshNeeded[self_playerGUID] = true
	self:StopProfiling("OvalePaperDoll_UpdateStats")
end

function OvalePaperDoll:SPELL_POWER_CHANGED(event)
	self:StartProfiling("OvalePaperDoll_UpdateStats")
	self.spellBonusDamage = API_GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[self.class])
	self.spellBonusDamage = API_GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[self.class])
	self.snapshotTime = API_GetTime()
	Ovale.refreshNeeded[self_playerGUID] = true
	self:StopProfiling("OvalePaperDoll_UpdateStats")
end

function OvalePaperDoll:UNIT_ATTACK_POWER(event, unitId)
	if unitId == "player" then
		self:StartProfiling("OvalePaperDoll_UpdateStats")
		local base, posBuff, negBuff = API_UnitAttackPower(unitId)
		self.attackPower = base + posBuff + negBuff
		self.snapshotTime = API_GetTime()
		Ovale.refreshNeeded[self_playerGUID] = true
		self:UpdateDamage(event)
		self:StopProfiling("OvalePaperDoll_UpdateStats")
	end
end

function OvalePaperDoll:UNIT_LEVEL(event, unitId)
	Ovale.refreshNeeded[unitId] = true
	if unitId == "player" then
		self:StartProfiling("OvalePaperDoll_UpdateStats")
		self.level = API_UnitLevel(unitId)
		self:DebugTimestamp("%s: level = %d", event, self.level)
		self.snapshotTime = API_GetTime()
		self:StopProfiling("OvalePaperDoll_UpdateStats")
	end
end

function OvalePaperDoll:UNIT_RANGEDDAMAGE(event, unitId)
	if unitId == "player" then
		self:StartProfiling("OvalePaperDoll_UpdateStats")
		self.rangedHaste = API_GetRangedHaste()
		self.snapshotTime = API_GetTime()
		Ovale.refreshNeeded[self_playerGUID] = true
		self:StopProfiling("OvalePaperDoll_UpdateStats")
	end
end

function OvalePaperDoll:UNIT_RANGED_ATTACK_POWER(event, unitId)
	if unitId == "player" then
		self:StartProfiling("OvalePaperDoll_UpdateStats")
		local base, posBuff, negBuff = API_UnitRangedAttackPower(unitId)
		Ovale.refreshNeeded[self_playerGUID] = true
		self.rangedAttackPower = base + posBuff + negBuff
		self.snapshotTime = API_GetTime()
		self:StopProfiling("OvalePaperDoll_UpdateStats")
	end
end

function OvalePaperDoll:UNIT_SPELL_HASTE(event, unitId)
	if unitId == "player" then
		self:StartProfiling("OvalePaperDoll_UpdateStats")
		self.meleeHaste = API_GetMeleeHaste()
		self.spellHaste = API_UnitSpellHaste(unitId)
		self.snapshotTime = API_GetTime()
		Ovale.refreshNeeded[self_playerGUID] = true
		self:UpdateDamage(event)
		self:StopProfiling("OvalePaperDoll_UpdateStats")
	end
end

function OvalePaperDoll:UNIT_STATS(event, unitId)
	if unitId == "player" then
		self:StartProfiling("OvalePaperDoll_UpdateStats")
		self.strength = API_UnitStat(unitId, 1)
		self.agility = API_UnitStat(unitId, 2)
		self.stamina = API_UnitStat(unitId, 3)
		self.intellect = API_UnitStat(unitId, 4)
		self.spirit = 0
		self.snapshotTime = API_GetTime()
		Ovale.refreshNeeded[self_playerGUID] = true
		self:StopProfiling("OvalePaperDoll_UpdateStats")
	end
end

function OvalePaperDoll:UpdateDamage(event)
	self:StartProfiling("OvalePaperDoll_UpdateDamage")
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, _, _, damageMultiplier = API_UnitDamage("player")
	local mainHandAttackSpeed, offHandAttackSpeed = API_UnitAttackSpeed("player")

	self.baseDamageMultiplier = damageMultiplier
	if self.class == "DRUID" and OvaleStance:IsStance("druid_cat_form") then
		-- Cat Form: 100% increased auto-attack damage.
		damageMultiplier = damageMultiplier * 2
	elseif self.class == "MONK" and OvaleEquipment:HasOneHandedWeapon() then
		-- Way of the Monk: 25% increased auto-attack damage if dual-wielding.
		damageMultiplier = damageMultiplier * 1.25
	end

	-- weaponDamage = (weaponDPS + attackPower / 14) * weaponSpeed
	-- normalizedWeaponDamage = (weaponDPS + attackPower / 14) * normalizedWeaponSpeed
	local avgDamage = (minDamage + maxDamage) / 2 / damageMultiplier
	local mainHandWeaponSpeed = mainHandAttackSpeed * self:GetMeleeHasteMultiplier()
	local normalizedMainHandWeaponSpeed = OvaleEquipment.mainHandWeaponSpeed or 0
	if self.class == "DRUID" then
		if OvaleStance:IsStance("druid_cat_form") then
			normalizedMainHandWeaponSpeed = 1
		elseif OvaleStance:IsStance("druid_bear_form") then
			normalizedMainHandWeaponSpeed = 2.5
		end
	end
	self.mainHandWeaponDamage = avgDamage / mainHandWeaponSpeed * normalizedMainHandWeaponSpeed
	--self:Debug("    MH weapon damage = ((%f + %f) / 2 / %f) / %f * %f",
	--	minDamage, maxDamage, damageMultiplier, mainHandWeaponSpeed, normalizedMainHandWeaponSpeed)

	if OvaleEquipment:HasOffHandWeapon() then
		local avgOffHandDamage = (minOffHandDamage + maxOffHandDamage) / 2 / damageMultiplier
		-- Sometimes, UnitAttackSpeed() doesn't return a value for OH attack speed, so approximate with MH one.
		offHandAttackSpeed = offHandAttackSpeed or mainHandAttackSpeed
		local offHandWeaponSpeed = offHandAttackSpeed * self:GetMeleeHasteMultiplier()
		local normalizedOffHandWeaponSpeed = OvaleEquipment.offHandWeaponSpeed or 0
		if self.class == "DRUID" then
			if OvaleStance:IsStance("druid_cat_form") then
				normalizedOffHandWeaponSpeed = 1
			elseif OvaleStance:IsStance("druid_bear_form") then
				normalizedOffHandWeaponSpeed = 2.5
			end
		end
		self.offHandWeaponDamage = avgOffHandDamage / offHandWeaponSpeed * normalizedOffHandWeaponSpeed
		--self:Debug("    OH weapon damage = ((%f + %f) / 2 / %f) / %f * %f",
		--	minOffHandDamage, maxOffHandDamage, damageMultiplier, offHandWeaponSpeed, normalizedOffHandWeaponSpeed)
	else
		self.offHandWeaponDamage = 0
	end
	self.snapshotTime = API_GetTime()
	Ovale.refreshNeeded[self_playerGUID] = true
	self:StopProfiling("OvalePaperDoll_UpdateDamage")
end

function OvalePaperDoll:UpdateSpecialization(event)
	self:StartProfiling("OvalePaperDoll_UpdateSpecialization")
	local newSpecialization = API_GetSpecialization()
	if self.specialization ~= newSpecialization then
		local oldSpecialization = self.specialization
		self.specialization = newSpecialization
		self.snapshotTime = API_GetTime()
		Ovale.refreshNeeded[self_playerGUID] = true
		self:SendMessage("Ovale_SpecializationChanged", self:GetSpecialization(newSpecialization), self:GetSpecialization(oldSpecialization))
	end
	self:StopProfiling("OvalePaperDoll_UpdateSpecialization")
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

-- Return the given specialization's name, or the current one if none is specified.
function OvalePaperDoll:GetSpecialization(specialization)
	specialization = specialization or self.specialization
	return OVALE_SPECIALIZATION_NAME[self.class][specialization]
end

-- Return true if the current specialization matches the given name.
function OvalePaperDoll:IsSpecialization(name)
	if name and self.specialization then
		if type(name) == "number" then
			return name == self.specialization
		else
			return name == OVALE_SPECIALIZATION_NAME[self.class][self.specialization]
		end
	end
	return false
end

-- NOTE: Mirrored in statePrototype below.
function OvalePaperDoll:GetMasteryMultiplier(snapshot)
	snapshot = snapshot or self
	return 1 + snapshot.masteryEffect / 100
end

-- NOTE: Mirrored in statePrototype below.
function OvalePaperDoll:GetMeleeHasteMultiplier(snapshot)
	snapshot = snapshot or self
	return 1 + snapshot.meleeHaste / 100
end

-- NOTE: Mirrored in statePrototype below.
function OvalePaperDoll:GetRangedHasteMultiplier(snapshot)
	snapshot = snapshot or self
	return 1 + snapshot.rangedHaste / 100
end

-- NOTE: Mirrored in statePrototype below.
function OvalePaperDoll:GetSpellHasteMultiplier(snapshot)
	snapshot = snapshot or self
	return 1 + snapshot.spellHaste / 100
end

-- NOTE: Mirrored in statePrototype below.
function OvalePaperDoll:GetHasteMultiplier(haste, snapshot)
	snapshot = snapshot or self
	local multiplier = 1
	if haste == "melee" then
		multiplier = self:GetMeleeHasteMultiplier(snapshot)
	elseif haste == "ranged" then
		multiplier = self:GetRangedHasteMultiplier(snapshot)
	elseif haste == "spell" then
		multiplier = self:GetSpellHasteMultiplier(snapshot)
	end
	return multiplier
end

-- Copy the snapshot stats from the snapshot table into the destination table.
-- NOTE: Mirrored in statePrototype below.
function OvalePaperDoll:UpdateSnapshot(tbl, snapshot, updateAllStats)
	if type(snapshot) ~= "table" then
		snapshot, updateAllStats = self, snapshot
	end
	local nameTable = updateAllStats and OvalePaperDoll.STAT_NAME or OvalePaperDoll.SNAPSHOT_STAT_NAME
	for k in pairs(nameTable) do
		tbl[k] = snapshot[k]
	end
end

-- Copy snapshot information from the spellcast to the destination table.
function OvalePaperDoll:CopySpellcastInfo(spellcast, dest)
	self:UpdateSnapshot(dest, spellcast, true)
end

-- Save snapshot information to the spellcast.
function OvalePaperDoll:SaveSpellcastInfo(spellcast, atTime, state)
	local paperDollModule = state or self
	self:UpdateSnapshot(spellcast, true)
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvalePaperDoll.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvalePaperDoll.statePrototype
--</private-static-properties>

--<state-properties>
-- Player's class.
statePrototype.class = nil
-- Player's level.
statePrototype.level = nil
-- Player's chosen specialization/mastery.
statePrototype.specialization = nil
-- Player's current snapshot.
statePrototype.snapshotTime = nil
statePrototype.agility = nil
statePrototype.intellect = nil
statePrototype.spirit = nil
statePrototype.stamina = nil
statePrototype.strength = nil
statePrototype.attackPower = nil
statePrototype.rangedAttackPower = nil
statePrototype.spellBonusDamage = nil
statePrototype.spellBonusHealing = nil
statePrototype.masteryEffect = nil
statePrototype.meleeCrit = nil
statePrototype.meleeHaste = nil
statePrototype.rangedCrit = nil
statePrototype.rangedHaste = nil
statePrototype.spellCrit = nil
statePrototype.spellHaste = nil
statePrototype.multistrike = nil
statePrototype.critRating = nil
statePrototype.hasteRating = nil
statePrototype.masteryRating = nil
statePrototype.multistrikeRating = nil
statePrototype.mainHandWeaponDamage = nil
statePrototype.offHandWeaponDamage = nil
statePrototype.baseDamageMultiplier = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvalePaperDoll:InitializeState(state)
	state.class = nil
	state.level = nil
	state.specialization = nil
	state.snapshotTime = 0
	state.agility = 0
	state.intellect = 0
	state.spirit = 0
	state.stamina = 0
	state.strength = 0
	state.attackPower = 0
	state.rangedAttackPower = 0
	state.spellBonusDamage = 0
	state.spellBonusHealing = 0
	state.masteryEffect = 0
	state.meleeCrit = 0
	state.meleeHaste = 0
	state.rangedCrit = 0
	state.rangedHaste = 0
	state.spellCrit = 0
	state.spellHaste = 0
	state.multistrike = 0
	state.critRating = 0
	state.hasteRating = 0
	state.masteryRating = 0
	state.multistrikeRating = 0
	state.mainHandWeaponDamage = 0
	state.offHandWeaponDamage = 0
	state.baseDamageMultiplier = 1
end

-- Reset the state to the current conditions.
function OvalePaperDoll:ResetState(state)
	state.class = self.class
	state.level = self.level
	state.specialization = self.specialization
	self:UpdateSnapshot(state, true)
end
--</public-static-methods>

--<state-methods>
-- Mirrored methods.
statePrototype.GetMasteryMultiplier = OvalePaperDoll.GetMasteryMultiplier
statePrototype.GetMeleeHasteMultiplier = OvalePaperDoll.GetMeleeHasteMultiplier
statePrototype.GetRangedHasteMultiplier = OvalePaperDoll.GetRangedHasteMultiplier
statePrototype.GetSpellHasteMultiplier = OvalePaperDoll.GetSpellHasteMultiplier
statePrototype.GetHasteMultiplier = OvalePaperDoll.GetHasteMultiplier
statePrototype.UpdateSnapshot = OvalePaperDoll.UpdateSnapshot
--</state-methods>
