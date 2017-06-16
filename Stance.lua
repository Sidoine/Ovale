--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- This addon tracks the player's current stance.

local OVALE, Ovale = ...
local OvaleStance = Ovale:NewModule("OvaleStance", "AceEvent-3.0")
Ovale.OvaleStance = OvaleStance

--<private-static-properties>
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleState = nil

local ipairs = ipairs
local pairs = pairs
local substr = string.sub
local tconcat = table.concat
local tinsert = table.insert
local tonumber = tonumber
local tsort = table.sort
local type = type
local wipe = wipe
local API_GetNumShapeshiftForms = GetNumShapeshiftForms
local API_GetShapeshiftForm = GetShapeshiftForm
local API_GetShapeshiftFormInfo = GetShapeshiftFormInfo
local API_GetSpellInfo = GetSpellInfo

-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleStance)

local SPELL_NAME_TO_STANCE = {
	-- Druid
	[API_GetSpellInfo(   768)] = "druid_cat_form",
	[API_GetSpellInfo(   783)] = "druid_travel_form",
	[API_GetSpellInfo(  1066)] = "druid_aquatic_form",
	[API_GetSpellInfo(  5487)] = "druid_bear_form",
	[API_GetSpellInfo( 24858)] = "druid_moonkin_form",
	[API_GetSpellInfo( 33943)] = "druid_flight_form",
	[API_GetSpellInfo( 40120)] = "druid_swift_flight_form",
	-- Rogue
	[API_GetSpellInfo(  1784)] = "rogue_stealth"
}

-- Table of all valid stance names.
local STANCE_NAME = {}
do
	for _, name in pairs(SPELL_NAME_TO_STANCE) do
		STANCE_NAME[name] = true
	end
end

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
-- Table of all valid stance names.
OvaleStance.STANCE_NAME = STANCE_NAME
--</public-static-properties>

--<public-static-methods>
function OvaleStance:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvaleState = Ovale.OvaleState

end

function OvaleStance:OnEnable()
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
	self:StartProfiling("OvaleStance_CreateStanceList")
	wipe(self.stanceList)
	wipe(self.stanceId)
	local _, name, stanceName
	for i = 1, API_GetNumShapeshiftForms() do
		_, name = API_GetShapeshiftFormInfo(i)
		stanceName = SPELL_NAME_TO_STANCE[name]
		if stanceName then
			self.stanceList[i] = stanceName
			self.stanceId[stanceName] = i
		end
	end
	self:StopProfiling("OvaleStance_CreateStanceList")
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

-- Return the name of the given stance or the current stance.
function OvaleStance:GetStance(stanceId)
	stanceId = stanceId or self.stance
	return self.stanceList[stanceId]
end

-- Return true if the current stance matches the given name.
-- NOTE: Mirrored in statePrototype below.
function OvaleStance:IsStance(name)
	if name and self.stance then
		if type(name) == "number" then
			return name == self.stance
		else
			return name == OvaleStance:GetStance(self.stance)
		end
	end
	return false
end

function OvaleStance:IsStanceSpell(spellId)
	local name = API_GetSpellInfo(spellId)
	return not not (name and SPELL_NAME_TO_STANCE[name])
end

function OvaleStance:ShapeshiftEventHandler()
	self:StartProfiling("OvaleStance_ShapeshiftEventHandler")
	local oldStance = self.stance
	local newStance = API_GetShapeshiftForm()
	if oldStance ~= newStance then
		self.stance = newStance
		Ovale.refreshNeeded[Ovale.playerGUID] = true
		self:SendMessage("Ovale_StanceChanged", self:GetStance(newStance), self:GetStance(oldStance))
	end
	self:StopProfiling("OvaleStance_ShapeshiftEventHandler")
end

function OvaleStance:UpdateStances()
	self:CreateStanceList()
	self:ShapeshiftEventHandler()
	self.ready = true
end

-- Run-time check that the player is in a certain stance.
-- NOTE: Mirrored in statePrototype below.
function OvaleStance:RequireStanceHandler(spellId, atTime, requirement, tokens, index, targetGUID)
	local verified = false
	-- If index isn't given, then tokens holds the actual token value.
	local stance = tokens
	if index then
		stance = tokens[index]
		index = index + 1
	end
	if stance then
		local isBang = false
		if substr(stance, 1, 1) == "!" then
			isBang = true
			stance = substr(stance, 2)
		end
		stance = tonumber(stance) or stance
		local isStance = self:IsStance(stance)
		if not isBang and isStance or isBang and not isStance then
			verified = true
		end
		local result = verified and "passed" or "FAILED"
		if isBang then
			self:Log("    Require NOT stance '%s': %s", stance, result)
		else
			self:Log("    Require stance '%s': %s", stance, result)
		end
	else
		Ovale:OneTimeMessage("Warning: requirement '%s' is missing a stance argument.", requirement)
	end
	return verified, requirement, index
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
	self:StartProfiling("OvaleStance_ResetState")
	state.stance = self.stance or 0
	self:StopProfiling("OvaleStance_ResetState")
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleStance:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvaleStance_ApplySpellAfterCast")
	local stance = state:GetSpellInfoProperty(spellId, endCast, "to_stance", targetGUID)
	if stance then
		if type(stance) == "string" then
			stance = self.stanceId[stance]
		end
		state.stance = stance
	end
	self:StopProfiling("OvaleStance_ApplySpellAfterCast")
end
--</public-static-methods>

--<state-methods>
-- Mirrored methods.
statePrototype.IsStance = OvaleStance.IsStance
statePrototype.RequireStanceHandler = OvaleStance.RequireStanceHandler
--</state-methods>
