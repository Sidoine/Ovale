--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- This addon tracks the player's current stance.

local _, Ovale = ...
OvaleStance = Ovale:NewModule("OvaleStance", "AceEvent-3.0")

--<private-static-properties>
local ipairs = ipairs
local pairs = pairs
local strfind = string.find
local tinsert = table.insert
local tsort = table.sort
local GetNumShapeshiftForms = GetNumShapeshiftForms
local GetShapeshiftForm = GetShapeshiftForm
local GetSpecialization = GetSpecialization
local GetSpellInfo = GetSpellInfo

local spellIdToStance = {
	-- Death Knight
	[GetSpellInfo(48263)] = "death_knight_blood_presence",
	[GetSpellInfo(48265)] = "death_knight_unholy_presence",
	[GetSpellInfo(48266)] = "death_knight_frost_presence",
	-- Druid
	[GetSpellInfo(768)] = "druid_cat_form",
	[GetSpellInfo(783)] = "druid_travel_form",
	[GetSpellInfo(1066)] = "druid_aquatic_form",
	[GetSpellInfo(5487)] = "druid_bear_form",
	[GetSpellInfo(24858)] = "druid_moonkin_form",
	[GetSpellInfo(33943)] = "druid_flight_form",
	[GetSpellInfo(40120)] = "druid_swift_flight_form",
	-- Hunter
	[GetSpellInfo(5118)] = "hunter_aspect_of_the_cheetah",
	[GetSpellInfo(13159)] = "hunter_aspect_of_the_pack",
	[GetSpellInfo(13165)] = "hunter_aspect_of_the_hawk",
	[GetSpellInfo(109260)] = "hunter_asepct_of_the_iron_hawk",
	-- Monk
	[GetSpellInfo(103985)] = "monk_stance_of_the_fierce_tiger",
	[GetSpellInfo(115069)] = "monk_stance_of_the_sturdy_ox",
	[GetSpellInfo(115070)] = "monk_stance_of_the_wise_serpent",
	-- Paladin
	[GetSpellInfo(20154)] = "paladin_seal_of_righteousness",
	[GetSpellInfo(20164)] = "paladin_seal_of_justice",
	[GetSpellInfo(20165)] = "paladin_seal_of_insight",
	[GetSpellInfo(31801)] = "paladin_seal_of_truth",
	[GetSpellInfo(105361)] = "paladin_seal_of_command",
	-- Priest
	[GetSpellInfo(15473)] = "priest_shadowform",
	-- Rogue
	[GetSpellInfo(1784)] = "rogue_stealth",
	[GetSpellInfo(51713)] = "rogue_shadow_dance",
	-- Warlock
	[GetSpellInfo(103958)] = "warlock_metamorphosis",
	-- Warrior
	[GetSpellInfo(71)] = "warrior_defensive_stance",
	[GetSpellInfo(2457)] = "warrior_battle_stance",
	[GetSpellInfo(2458)] = "warrior_berserker_stance",
}

-- List of available stances, populated by CreateStanceList()
local stanceList
-- Player's current stance.
local stance
-- Player's current specialization/mastery.
local specialization
--</private-static-properties>

--<public-static-methods>
function OvaleStance:OnEnable()
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
end

function OvaleStance:OnDisable()
	self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_TALENT_UPDATE")
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORMS")
end

function OvaleStance:ACTIVE_TALENT_GROUP_CHANGED(event)
	specialization = GetSpecialization()
	self:PLAYER_TALENT_UPDATE(event)
end

function OvaleStance:PLAYER_ENTERING_WORLD(event)
	self:ACTIVE_TALENT_GROUP_CHANGED(event)
end

function OvaleStance:PLAYER_TALENT_UPDATE(event)
	self:CreateStanceList()
	self:ShapeshiftEventHandler()
end

function OvaleStance:UPDATE_SHAPESHIFT_FORM(event)
	self:ShapeshiftEventHandler()
end

function OvaleStance:UPDATE_SHAPESHIFT_FORMS(event)
	self:ShapeshiftEventHandler()
end

-- Fill stanceList with stance bar index <-> Ovale stance name mappings.
function OvaleStance:CreateStanceList()
	stanceList = {}
	local name, stanceName
	for i = 1, GetNumShapeshiftForms() do
		_, name = GetShapeshiftFormInfo(i)
		stanceName = spellIdToStance[name]
		if stanceName then
			stanceList[i] = stanceName
		end
	end
end

-- Print out the list of stances in alphabetical order.
function OvaleStance:DebugStances()
	local array = {}
	for k, v in pairs(stanceList) do
		if stance == k then
			tinsert(array, v .. " (active)")
		else
			tinsert(array, v)
		end
	end
	tsort(array)
	for _, v in ipairs(array) do
		Ovale:Print(v)
	end
end

function OvaleStance:Debug()
	Ovale:Print("current stance: " .. stance)
	Ovale:Print("current specialization: " .. specialization)
end

-- Return true if the current specialization matches the given name.
function OvaleStance:IsSpecialization(name)
	if not name then return false end
	return name == specialization
end

-- Return true if the current stance matches the given name.
function OvaleStance:IsStance(name)
	if not name then return false end
	if type(name) == "number" then
		return name == stance
	else
		return name == stanceList[stance]
	end
end

function OvaleStance:ShapeshiftEventHandler()
	local newStance = GetShapeshiftForm()
	if stance ~= newStance then
		stance = newStance
		self:SendMessage("Ovale_UpdateShapeshiftForm")
	end
end
--</public-static-methods>
