--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- This addon tracks the player's current stance.

local _, Ovale = ...
local OvaleStance = Ovale:NewModule("OvaleStance", "AceEvent-3.0")
Ovale.OvaleStance = OvaleStance

--<private-static-properties>
local ipairs = ipairs
local pairs = pairs
local tinsert = table.insert
local tsort = table.sort
local wipe = table.wipe
local API_GetNumShapeshiftForms = GetNumShapeshiftForms
local API_GetShapeshiftForm = GetShapeshiftForm
local API_GetShapeshiftFormInfo = GetShapeshiftFormInfo
local API_GetSpellInfo = GetSpellInfo

local OVALE_SPELLID_TO_STANCE = {
	-- Death Knight
	[API_GetSpellInfo(48263)] = "death_knight_blood_presence",
	[API_GetSpellInfo(48265)] = "death_knight_unholy_presence",
	[API_GetSpellInfo(48266)] = "death_knight_frost_presence",
	-- Druid
	[API_GetSpellInfo(768)] = "druid_cat_form",
	[API_GetSpellInfo(783)] = "druid_travel_form",
	[API_GetSpellInfo(1066)] = "druid_aquatic_form",
	[API_GetSpellInfo(5487)] = "druid_bear_form",
	[API_GetSpellInfo(24858)] = "druid_moonkin_form",
	[API_GetSpellInfo(33943)] = "druid_flight_form",
	[API_GetSpellInfo(40120)] = "druid_swift_flight_form",
	-- Hunter
	[API_GetSpellInfo(5118)] = "hunter_aspect_of_the_cheetah",
	[API_GetSpellInfo(13159)] = "hunter_aspect_of_the_pack",
	[API_GetSpellInfo(13165)] = "hunter_aspect_of_the_hawk",
	[API_GetSpellInfo(109260)] = "hunter_asepct_of_the_iron_hawk",
	-- Monk
	[API_GetSpellInfo(103985)] = "monk_stance_of_the_fierce_tiger",
	[API_GetSpellInfo(115069)] = "monk_stance_of_the_sturdy_ox",
	[API_GetSpellInfo(115070)] = "monk_stance_of_the_wise_serpent",
	-- Paladin
	[API_GetSpellInfo(20154)] = "paladin_seal_of_righteousness",
	[API_GetSpellInfo(20164)] = "paladin_seal_of_justice",
	[API_GetSpellInfo(20165)] = "paladin_seal_of_insight",
	[API_GetSpellInfo(31801)] = "paladin_seal_of_truth",
	[API_GetSpellInfo(105361)] = "paladin_seal_of_command",
	-- Priest
	[API_GetSpellInfo(15473)] = "priest_shadowform",
	-- Rogue
	[API_GetSpellInfo(1784)] = "rogue_stealth",
	[API_GetSpellInfo(51713)] = "rogue_shadow_dance",
	-- Warlock
	[API_GetSpellInfo(103958)] = "warlock_metamorphosis",
	-- Warrior
	[API_GetSpellInfo(71)] = "warrior_defensive_stance",
	[API_GetSpellInfo(2457)] = "warrior_battle_stance",
	[API_GetSpellInfo(2458)] = "warrior_berserker_stance",
}
--</private-static-properties>

--<public-static-properties>
-- List of available stances, populated by CreateStanceList()
OvaleStance.stanceList = {}
-- Player's current stance.
OvaleStance.stance = nil
--</public-static-properties>

--<public-static-methods>
function OvaleStance:OnEnable()
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "UpdateStances")
	self:RegisterEvent("PLAYER_ALIVE", "UpdateStances")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStances")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateStances")
	self:RegisterEvent("SPELLS_CHANGED", "UpdateStances")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
end

function OvaleStance:OnDisable()
	self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:UnregisterEvent("PLAYER_ALIVE")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_TALENT_UPDATE")
	self:UnregisterEvent("SPELLS_CHANGED")
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORMS")
end

function OvaleStance:UPDATE_SHAPESHIFT_FORM(event)
	self:ShapeshiftEventHandler()
end

function OvaleStance:UPDATE_SHAPESHIFT_FORMS(event)
	self:ShapeshiftEventHandler()
end

-- Fill OvaleStance.stanceList with stance bar index <-> Ovale stance name mappings.
function OvaleStance:CreateStanceList()
	wipe(self.stanceList)
	local _, name, stanceName
	for i = 1, API_GetNumShapeshiftForms() do
		_, name = API_GetShapeshiftFormInfo(i)
		stanceName = OVALE_SPELLID_TO_STANCE[name]
		if stanceName then
			self.stanceList[i] = stanceName
		end
	end
end

-- Print out the list of stances in alphabetical order.
function OvaleStance:DebugStances()
	local array = {}
	for k, v in pairs(self.stanceList) do
		if self.stance == k then
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
	Ovale:FormatPrint("current stance: %s", self.stance)
end

-- Return the current stance's name.
function OvaleStance:GetStance()
	return self.stanceList[self.stance]
end

-- Return true if the current stance matches the given name.
function OvaleStance:IsStance(name)
	if not name or not self.stance then return false end
	if type(name) == "number" then
		return name == self.stance
	else
		return name == self.stanceList[self.stance]
	end
end

function OvaleStance:ShapeshiftEventHandler()
	local newStance = API_GetShapeshiftForm()
	if self.stance ~= newStance then
		self.stance = newStance
		self:SendMessage("Ovale_StanceChanged")
	end
end

function OvaleStance:UpdateStances()
	self:CreateStanceList()
	self:ShapeshiftEventHandler()
end
--</public-static-methods>
