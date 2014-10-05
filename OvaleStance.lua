--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- This addon tracks the player's current stance.

local _, Ovale = ...
local OvaleStance = Ovale:NewModule("OvaleStance", "AceEvent-3.0")
Ovale.OvaleStance = OvaleStance

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleState = nil

local ipairs = ipairs
local pairs = pairs
local tinsert = table.insert
local tsort = table.sort
local wipe = table.wipe
local API_GetNumShapeshiftForms = GetNumShapeshiftForms
local API_GetShapeshiftForm = GetShapeshiftForm
local API_GetShapeshiftFormInfo = GetShapeshiftFormInfo
local API_GetSpellInfo = GetSpellInfo

-- Profiling set-up.
local Profiler = Ovale.Profiler
local profiler = nil
do
	local group = OvaleStance:GetName()

	local function EnableProfiling()
		API_GetNumShapeshiftForms = Profiler:Wrap(group, "OvaleStance_API_GetNumShapeshiftForms", GetNumShapeshiftForms)
		API_GetShapeshiftForm = Profiler:Wrap(group, "OvaleStance_API_GetShapeshiftForm", GetShapeshiftForm)
		API_GetShapeshiftFormInfo = Profiler:Wrap(group, "OvaleStance_API_GetShapeshiftFormInfo", GetShapeshiftFormInfo)
	end

	local function DisableProfiling()
		API_GetNumShapeshiftForms = GetNumShapeshiftForms
		API_GetShapeshiftForm = GetShapeshiftForm
		API_GetShapeshiftFormInfo = GetShapeshiftFormInfo
	end

	Profiler:RegisterProfilingGroup(group, EnableProfiling, DisableProfiling)
	profiler = Profiler:GetProfilingGroup(group)
end

local OVALE_SPELLID_TO_STANCE = {
	-- Death Knight
	[API_GetSpellInfo(48263)] = "deathknight_blood_presence",
	[API_GetSpellInfo(48265)] = "deathknight_unholy_presence",
	[API_GetSpellInfo(48266)] = "deathknight_frost_presence",
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
	[API_GetSpellInfo(109260)] = "hunter_aspect_of_the_iron_hawk",
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
-- Whether the stance information is ready for use by other modules.
OvaleStance.ready = false
-- List of available stances, populated by CreateStanceList()
OvaleStance.stanceList = {}
-- Map stance names to stance ID (index on shapeshift/stance bar).
OvaleStance.stanceId = {}
-- Player's current stance.
OvaleStance.stance = nil
--</public-static-properties>

--<public-static-methods>
function OvaleStance:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvaleState = Ovale.OvaleState
end

function OvaleStance:OnEnable()
	self:RegisterEvent("PLAYER_ALIVE", "UpdateStances")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStances")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
	self:RegisterMessage("Ovale_SpellsChanged", "UpdateStances")
	self:RegisterMessage("Ovale_TalentsChanged", "UpdateStances")
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvaleStance:OnDisable()
	OvaleState:UnregisterState(self)
	self:UnregisterEvent("PLAYER_ALIVE")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORMS")
	self:UnregisterMessage("Ovale_SpellsChanged")
	self:UnregisterMessage("Ovale_TalentsChanged")
end

function OvaleStance:PLAYER_TALENT_UPDATE(event)
	-- Clear old stance ID since talent update may overwrite old stance with new one with same ID.
	self.stance = nil
	UpdateStances()
end

function OvaleStance:UPDATE_SHAPESHIFT_FORM(event)
	self:ShapeshiftEventHandler()
end

function OvaleStance:UPDATE_SHAPESHIFT_FORMS(event)
	self:ShapeshiftEventHandler()
end

-- Fill OvaleStance.stanceList with stance bar index <-> Ovale stance name mappings.
function OvaleStance:CreateStanceList()
	profiler.Start("OvaleStance_CreateStanceList")
	wipe(self.stanceList)
	wipe(self.stanceId)
	local _, name, stanceName
	for i = 1, API_GetNumShapeshiftForms() do
		_, name = API_GetShapeshiftFormInfo(i)
		stanceName = OVALE_SPELLID_TO_STANCE[name]
		if stanceName then
			self.stanceList[i] = stanceName
			self.stanceId[stanceName] = i
		end
	end
	profiler.Stop("OvaleStance_CreateStanceList")
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
	profiler.Start("OvaleStance_ShapeshiftEventHandler")
	local newStance = API_GetShapeshiftForm()
	if self.stance ~= newStance then
		self.stance = newStance
		self:SendMessage("Ovale_StanceChanged")
	end
	profiler.Stop("OvaleStance_ShapeshiftEventHandler")
end

function OvaleStance:UpdateStances()
	self:CreateStanceList()
	self:ShapeshiftEventHandler()
	self.ready = true
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleStance.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleStance.statePrototype
--</private-static-properties>

--<state-properties>
statePrototype.stance = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleStance:InitializeState(state)
	state.stance = nil
end

-- Reset the state to the current conditions.
function OvaleStance:ResetState(state)
	profiler.Start("OvaleStance_ResetState")
	state.stance = self.stance or 0
	profiler.Stop("OvaleStance_ResetState")
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleStance:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast)
	profiler.Start("OvaleStance_ApplySpellAfterCast")
	local si = OvaleData.spellInfo[spellId]
	if si and si.to_stance then
		local stance = si.to_stance
		stance = (type(stance) == "number") and stance or self.stanceId[stance]
		state.stance = stance
	end
	profiler.Stop("OvaleStance_ApplySpellAfterCast")
end
--</public-static-methods>

--<state-methods>
-- Return true if the stance matches the given name.
statePrototype.IsStance = function(state, name)
	if name and state.stance then
		if type(name) == "number" then
			return name == state.stance
		else
			return name == OvaleStance.stanceList[state.stance]
		end
	end
	return false
end
--</state-methods>
