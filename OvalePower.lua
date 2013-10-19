--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvalePower = Ovale:NewModule("OvalePower", "AceEvent-3.0")
Ovale.OvalePower = OvalePower

--<private-static-properties>
local pairs = pairs
local API_GetPowerRegen = GetPowerRegen
local API_UnitPower = UnitPower
local API_UnitPowerMax = UnitPowerMax
local API_UnitPowerType = UnitPowerType
local SPELL_POWER_ALTERNATE_POWER = SPELL_POWER_ALTERNATE_POWER
local SPELL_POWER_BURNING_EMBERS = SPELL_POWER_BURNING_EMBERS
local SPELL_POWER_CHI = SPELL_POWER_CHI
local SPELL_POWER_DEMONIC_FURY = SPELL_POWER_DEMONIC_FURY
local SPELL_POWER_ECLIPSE = SPELL_POWER_ECLIPSE
local SPELL_POWER_ENERGY = SPELL_POWER_ENERGY
local SPELL_POWER_FOCUS = SPELL_POWER_FOCUS
local SPELL_POWER_HOLY_POWER = SPELL_POWER_HOLY_POWER
local SPELL_POWER_MANA = SPELL_POWER_MANA
local SPELL_POWER_RAGE = SPELL_POWER_RAGE
local SPELL_POWER_RUNIC_POWER = SPELL_POWER_RUNIC_POWER
local SPELL_POWER_SHADOW_ORBS = SPELL_POWER_SHADOW_ORBS
local SPELL_POWER_SOUL_SHARDS = SPELL_POWER_SOUL_SHARDS
--</private-static-properties>

--<public-static-properties>
-- Player's current power type (key for POWER table).
OvalePower.powerType = nil
-- Player's current power; power[powerType] = number.
OvalePower.power = {}
-- Player's current max power; maxPower[powerType] = number.
OvalePower.maxPower = {}
-- Player's current power regeneration rate for the active power type.
OvalePower.activeRegen = 0
OvalePower.inactiveRegen = 0

OvalePower.POWER_INFO =
{
	alternate = { id = SPELL_POWER_ALTERNATE_POWER, token = "ALTERNATE_RESOURCE_TEXT", mini = 0 },
	burningembers = { id = SPELL_POWER_BURNING_EMBERS, token = "BURNING_EMBERS", mini = 0, segments = true },
	chi = { id = SPELL_POWER_CHI, token = "CHI", mini = 0 },
	demonicfury = { id = SPELL_POWER_DEMONIC_FURY, token = "DEMONIC_FURY", mini = 0 },
	eclipse = { id = SPELL_POWER_ECLIPSE, token = "ECLIPSE", mini = -100, maxi = 100 },
	energy = { id = SPELL_POWER_ENERGY, token = "ENERGY", mini = 0 },
	focus = { id = SPELL_POWER_FOCUS, token = "FOCUS", mini = 0 },
	holy = { id = SPELL_POWER_HOLY_POWER, token = "HOLY_POWER", mini = 0 },
	mana = { id = SPELL_POWER_MANA, token = "MANA", mini = 0 },
	rage = { id = SPELL_POWER_RAGE, token = "RAGE", mini = 0 },
	runicpower = { id = SPELL_POWER_RUNIC_POWER, token = "RUNIC_POWER", mini = 0 },
	shadoworbs = { id = SPELL_POWER_SHADOW_ORBS, token = "SHADOW_ORBS", mini = 0 },
	shards = { id = SPELL_POWER_SOUL_SHARDS, token = "SOUL_SHARDS_POWER", mini = 0 },
}
OvalePower.SECONDARY_POWER = {
	"burningembers",
	"chi",
	"demonicfury",
	"focus",
	"holy",
	"rage",
	"shadoworbs",
	"shards",
}
OvalePower.POWER_TYPE = {}
do
	for powerType, v in pairs(OvalePower.POWER_INFO) do
		OvalePower.POWER_TYPE[v.id] = powerType
		OvalePower.POWER_TYPE[v.token] = powerType
	end
end
--</public-static-properties>

--<public-static-methods>
function OvalePower:OnEnable()
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "EventHandler")
	self:RegisterEvent("PLAYER_ALIVE", "EventHandler")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "EventHandler")
	self:RegisterEvent("PLAYER_LEVEL_UP", "EventHandler")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "EventHandler")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("UNIT_LEVEL")
	self:RegisterEvent("UNIT_MAXPOWER")
	self:RegisterEvent("UNIT_POWER")
	self:RegisterEvent("UNIT_POWER_FREQUENT", "UNIT_POWER")
	self:RegisterEvent("UNIT_RANGEDDAMAGE")
	self:RegisterEvent("UNIT_SPELL_HASTE", "UNIT_RANGEDDAMAGE")
	self:RegisterMessage("Ovale_StanceChanged", "EventHandler")
end

function OvalePower:OnDisable()
	self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:UnregisterEvent("PLAYER_ALIVE")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_LEVEL_UP")
	self:UnregisterEvent("PLAYER_TALENT_UPDATE")
	self:UnregisterEvent("UNIT_DISPLAYPOWER")
	self:UnregisterEvent("UNIT_LEVEL")
	self:UnregisterEvent("UNIT_MAXPOWER")
	self:UnregisterEvent("UNIT_POWER")
	self:UnregisterEvent("UNIT_POWER_FREQUENT")
	self:UnregisterEvent("UNIT_RANGEDDAMAGE")
	self:UnregisterEvent("UNIT_SPELL_HASTE")
	self:UnregisterMessage("Ovale_StanceChanged")
end

function OvalePower:EventHandler(event)
	self:UpdatePowerType()
	self:UpdateMaxPower()
	self:UpdatePower()
	self:UpdatePowerRegen()
end

function OvalePower:UNIT_DISPLAYPOWER(event, unitId)
	if unitId == "player" then
		self:UpdatePowerType()
	end
end

function OvalePower:UNIT_LEVEL(event, unitId)
	if unitId == "player" then
		self:EventHandler(event)
	end
end

function OvalePower:UNIT_MAXPOWER(event, unitId, powerToken)
	if unitId == "player" then
		self:UpdateMaxPower(self.POWER_TYPE[powerToken])
	end
end

function OvalePower:UNIT_POWER(event, unitId, powerToken)
	if unitId == "player" then
		self:UpdatePower(self.POWER_TYPE[powerToken])
	end
end

function OvalePower:UNIT_RANGEDDAMAGE(event, unitId)
	if unitId == "player" then
		self:UpdatePowerRegen()
	end
end

function OvalePower:UpdateMaxPower(powerType)
	if powerType then
		local powerInfo = self.POWER_INFO[powerType]
		self.maxPower[powerType] = API_UnitPowerMax("player", powerInfo.id, powerInfo.segments)
	else
		for powerType, powerInfo in pairs(self.POWER_INFO) do
			self.maxPower[powerType] = API_UnitPowerMax("player", powerInfo.id, powerInfo.segments)
		end
	end
end

function OvalePower:UpdatePower(powerType)
	if powerType then
		local powerInfo = self.POWER_INFO[powerType]
		self.power[powerType] = API_UnitPower("player", powerInfo.id, powerInfo.segments)
	else
		for powerType, powerInfo in pairs(self.POWER_INFO) do
			self.power[powerType] = API_UnitPower("player", powerInfo.id, powerInfo.segments)
		end
	end
end

function OvalePower:UpdatePowerRegen()
	self.inactiveRegen, self.activeRegen = API_GetPowerRegen()
end

function OvalePower:UpdatePowerType()
	local currentType, currentToken = API_UnitPowerType("player")
	self.powerType = self.POWER_TYPE[currentType]
end

function OvalePower:Debug()
	Ovale:FormatPrint("Power type: %s", self.powerType)
	for powerType, v in pairs(self.power) do
		Ovale:FormatPrint("Power (%s): %d / %d", powerType, v, self.maxPower[powerType])
	end
	Ovale:FormatPrint("Active regen: %f", self.activeRegen)
	Ovale:FormatPrint("Inactive regen: %f", self.inactiveRegen)
end
--</public-static-methods>