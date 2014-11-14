--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- This addon tracks the player's current stance.

local OVALE, Ovale = ...
local OvaleStance = Ovale:NewModule("OvaleStance", "AceEvent-3.0")
Ovale.OvaleStance = OvaleStance

--<private-static-properties>
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug

-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleGUID = nil
local OvaleState = nil

local ipairs = ipairs
local pairs = pairs
local substr = string.sub
local tconcat = table.concat
local tinsert = table.insert
local tonumber = tonumber
local tsort = table.sort
local type = type
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
	Profiler:RegisterProfilingGroup(group)
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
	-- Monk
	[API_GetSpellInfo(103985)] = "monk_stance_of_the_fierce_tiger",
	[API_GetSpellInfo(115069)] = "monk_stance_of_the_sturdy_ox",
	[API_GetSpellInfo(115070)] = "monk_stance_of_the_wise_serpent",
	[API_GetSpellInfo(154436)] = "monk_stance_of_the_spirited_crane",
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
	-- Warlock
	[API_GetSpellInfo(103958)] = "warlock_metamorphosis",
	-- Warrior
	[API_GetSpellInfo(71)] = "warrior_defensive_stance",
	[API_GetSpellInfo(2457)] = "warrior_battle_stance",
	[API_GetSpellInfo(156291)] = "warrior_gladiator_stance",
}

do
	local debugOptions = {
		stance = {
			name = L["Stances"],
			type = "group",
			args = {
				stance = {
					name = L["Stances"],
					type = "input",
					multiline = 25,
					width = "full",
					get = function(info) return OvaleStance:DebugStances() end,
				},
			},
		},
	}
	-- Insert debug options into OvaleDebug.
	for k, v in pairs(debugOptions) do
		OvaleDebug.options.args[k] = v
	end
end
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
	OvaleGUID = Ovale.OvaleGUID
	OvaleState = Ovale.OvaleState
end

function OvaleStance:OnEnable()
	self:RegisterEvent("PLAYER_ALIVE", "UpdateStances")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStances")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
	self:RegisterMessage("Ovale_SpellsChanged", "UpdateStances")
	self:RegisterMessage("Ovale_TalentsChanged", "UpdateStances")
	OvaleData:RegisterRequirement("stance", "RequireStanceHandler", self)
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvaleStance:OnDisable()
	OvaleState:UnregisterState(self)
	OvaleData:UnregisterRequirement("stance")
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
	self:UpdateStances()
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
do
	local array = {}

	function OvaleStance:DebugStances()
		wipe(array)
		for k, v in pairs(self.stanceList) do
			if self.stance == k then
				tinsert(array, v .. " (active)")
			else
				tinsert(array, v)
			end
		end
		tsort(array)
		return tconcat(array, "\n")
	end
end

-- Return the current stance's name.
function OvaleStance:GetStance()
	return self.stanceList[self.stance]
end

-- Return true if the current stance matches the given name.
-- NOTE: Mirrored in statePrototype below.
function OvaleStance:IsStance(name)
	if name and self.stance then
		if type(name) == "number" then
			return name == self.stance
		else
			return name == OvaleStance.stanceList[self.stance]
		end
	end
	return false
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

-- Run-time check that the player is in a certain stance.
-- NOTE: Mirrored in statePrototype below.
function OvaleStance:RequireStanceHandler(spellId, requirement, tokenIterator, target)
	local verified = false
	local stance = tokenIterator()
	if stance then
		local isBang = false
		if substr(stance, 1, 1) == "!" then
			stance = substr(stance, 2)
		end
		stance = tonumber(stance) or stance
		local isStance = self:IsStance(stance)
		if not isBang and isStance or isBang and not isStance then
			verified = true
		end
		local result = verified and "passed" or "FAILED"
		if isBang then
			self:Logf("    Require stance '%s': %s", stance, result)
		else
			self:Logf("    Require NOT stance 's': %s", stance, result)
		end
	else
		Ovale:OneTimeMessage("Warning: requirement '%s' is missing a stance argument.", requirement)
	end
	return verified, requirement
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
function OvaleStance:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, spellcast)
	profiler.Start("OvaleStance_ApplySpellAfterCast")
	local target = OvaleGUID:GetUnitId(targetGUID)
	local stance = state:GetSpellInfoProperty(spellId, "to_stance", target)
	if stance then
		if type(stance) == "string" then
			stance = self.stanceId[stance]
		end
		state.stance = stance
	end
	profiler.Stop("OvaleStance_ApplySpellAfterCast")
end
--</public-static-methods>

--<state-methods>
-- Mirrored methods.
statePrototype.IsStance = OvaleStance.IsStance
statePrototype.RequireStanceHandler = OvaleStance.RequireStanceHandler
--</state-methods>
