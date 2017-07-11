--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- This addon is a script repository.

local OVALE, Ovale = ...
local OvaleScripts = Ovale:NewModule("OvaleScripts", "AceEvent-3.0")
Ovale.OvaleScripts = OvaleScripts

--<private-static-properties>
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local OvaleOptions = Ovale.OvaleOptions
local L = Ovale.L

-- Forward declarations for module dependencies.
local OvaleEquipment = nil
local OvalePaperDoll = nil
local OvaleSpellBook = nil
local OvaleStance = nil

local format = string.format
local gsub = string.gsub
local pairs = pairs
local strlower = string.lower

-- Name and description of default script.
local DEFAULT_NAME = "Ovale"
local DEFAULT_DESCRIPTION = L["Script défaut"]

-- Name and description of "custom" script.
local CUSTOM_NAME = "custom"
local CUSTOM_DESCRIPTION = L["Script personnalisé"]

-- Name and description of "disabled" script.
local DISABLED_NAME = "Disabled"
local DISABLED_DESCRIPTION = L["Disabled"]

do
	local defaultDB = {
		code = "",
		source = "Ovale",	-- The name given to all default class scripts.
		showHiddenScripts = false,
	}
	local actions = {
		code  = {
			name = L["Code"],
			type = "execute",
			func = function()
				local appName = OvaleScripts:GetName()
				AceConfigDialog:SetDefaultSize(appName, 700, 550)
				AceConfigDialog:Open(appName)
			end,
		},
	}
	-- Insert defaults into OvaleOptions.
	for k, v in pairs(defaultDB) do
		OvaleOptions.defaultDB.profile[k] = v
	end
	for k, v in pairs(actions) do
		OvaleOptions.options.args.actions.args[k] = v
	end
	OvaleOptions:RegisterOptions(OvaleScripts)
end
--</private-static-properties>

--<public-static-properties>
-- A "script" is a table { type = "scriptType", desc = "description", code = "..." }
-- Table of scripts, indexed by name.
OvaleScripts.script = {}
--</public-static-properties>

--<public-static-methods>
function OvaleScripts:OnInitialize()
	-- Resolve module dependencies.
	OvaleEquipment = Ovale.OvaleEquipment
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleStance = Ovale.OvaleStance

	self:CreateOptions()
	-- Register the default script that triggers the automatic script selection; the body code is ignored.
	self:RegisterScript(nil, nil, DEFAULT_NAME, DEFAULT_DESCRIPTION, nil, "script")
	-- Register the custom script.
	self:RegisterScript(Ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, Ovale.db.profile.code, "script")
	-- Register an empty script called "Disabled" that can be used to show no icons.
	self:RegisterScript(nil, nil, DISABLED_NAME, DISABLED_DESCRIPTION, nil, "script")
end

function OvaleScripts:OnEnable()
	self:RegisterMessage("Ovale_StanceChanged")
end

function OvaleScripts:OnDisable()
	self:UnregisterMessage("Ovale_StanceChanged")
end

function OvaleScripts:Ovale_StanceChanged(event, newStance, oldStance)
end

-- Return a table of script descriptions indexed by name.
function OvaleScripts:GetDescriptions(scriptType)
	local descriptionsTable = {}
	for name, script in pairs(self.script) do
		if (not scriptType or script.type == scriptType) and (not script.specialization or OvalePaperDoll:IsSpecialization(script.specialization)) then
			if name == DEFAULT_NAME then
				descriptionsTable[name] = script.desc .. " (" .. self:GetScriptName(name) .. ")"
			else
				descriptionsTable[name] = script.desc
			end
		end
	end
	return descriptionsTable
end

function OvaleScripts:RegisterScript(class, specialization, name, description, code, scriptType)
	if not class or class == Ovale.playerClass then
		self.script[name] = self.script[name] or {}
		local script = self.script[name]
		script.type = scriptType or "script"
		script.desc = description or name
		script.specialization = specialization
		script.code = code or ""
	end
end

function OvaleScripts:UnregisterScript(name)
	self.script[name] = nil
end

function OvaleScripts:SetScript(name)
	local oldSource = Ovale.db.profile.source
	if oldSource ~= name then
		Ovale.db.profile.source = name
		self:SendMessage("Ovale_ScriptChanged")
	end
end

function OvaleScripts:GetDefaultScriptName(class, specialization)
	local name
	-- only override when no default script is found in simulationcraft folder
	-- default scripts in the form off "simulationcraft_<class>_<specialization>_t18m"
	if class == "DEATHKNIGHT" then
		if specialization == "blood" then
			name = "icyveins_deathknight_blood"
		elseif specialization == "frost" then
			name = "simulationcraft_death_knight_frost_t19p"
		elseif specialization == "unholy" then
			name = "simulationcraft_death_knight_unholy_t19p"
		end
	elseif class == "DEMONHUNTER" then
		if specialization == "vengeance" then 
			name = "icyveins_demonhunter_vengeance"
		elseif specialization == "havoc" then
			name = "simulationcraft_demon_hunter_havoc_t19p"
		end
	elseif class == "DRUID" then
		if specialization == "restoration" then
			name = DISABLED_NAME
		elseif specialization == "guardian" then
			name = "icyveins_druid_guardian"
		end
	elseif class == "HUNTER" then
		local short
		if specialization == "beast_mastery" then
			short = "bm"
		elseif specialization == "marksmanship" then
			short = "mm"
		elseif specialization == "survival" then
			short = "sv"
		end
		if short then
			name = format("simulationcraft_hunter_%s_t19p", short)
		end
	elseif class == "MONK" then
		if specialization == "mistweaver" then
			name = DISABLED_NAME
		elseif specialization == "brewmaster" then
			name = "icyveins_monk_brewmaster"
		end
	elseif class == "PALADIN" then
		if specialization == "holy" then
			name = DISABLED_NAME
		elseif specialization == "protection" then
			name = "icyveins_paladin_protection"
		end
	elseif class == "PRIEST" then
		if specialization == "discipline" then
			name = "icyveins_priest_discipline"
		elseif specialization == "holy" then
			name = DISABLED_NAME
		end
	elseif class == "SHAMAN" then
		if specialization == "restoration" then
			name = DISABLED_NAME
		end
	elseif class == "WARRIOR" then
		if specialization == "protection" then
			name = "icyveins_warrior_protection"
		end
	end
	if not name and specialization then
		name = format("simulationcraft_%s_%s_t19p", strlower(class), specialization)
	end
	if not (name and self.script[name]) then
		name = DISABLED_NAME
	end
	return name
end

function OvaleScripts:GetScriptName(name)
	return (name == DEFAULT_NAME) and self:GetDefaultScriptName(Ovale.playerClass, OvalePaperDoll:GetSpecialization()) or name
end

function OvaleScripts:GetScript(name)
	name = self:GetScriptName(name)
	if name and self.script[name] then
		return self.script[name].code
	end
end

function OvaleScripts:CreateOptions()
	local options = {
		name = OVALE .. " " .. L["Script"],
		type = "group",
		args = {
			source = {
				order = 10,
				type = "select",
				name = L["Script"],
				width = "double",
				values = function(info)
					local scriptType = not Ovale.db.profile.showHiddenScripts and "script"
					return OvaleScripts:GetDescriptions(scriptType)
				end,
				get = function(info)
					return Ovale.db.profile.source
				end,
				set = function(info, v)
					self:SetScript(v)
				end,
			},
			script = {
				order = 20,
				type = "input",
				multiline = 25,
				name = L["Script"],
				width = "full",
				disabled = function()
					return Ovale.db.profile.source ~= CUSTOM_NAME
				end,
				get = function(info)
					local code = OvaleScripts:GetScript(Ovale.db.profile.source)
					code = code or ""
					-- Substitute spaces for tabs.
					return gsub(code, "\t", "    ")
				end,
				set = function(info, v)
					OvaleScripts:RegisterScript(Ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, v, "script")
					Ovale.db.profile.code = v
					self:SendMessage("Ovale_ScriptChanged")
				end,
			},
			copy = {
				order = 30,
				type = "execute",
				name = L["Copier sur Script personnalisé"],
				disabled = function()
					return Ovale.db.profile.source == CUSTOM_NAME
				end,
				confirm = function()
					return L["Ecraser le Script personnalisé préexistant?"]
				end,
				func = function()
					local code = OvaleScripts:GetScript(Ovale.db.profile.source)
					OvaleScripts:RegisterScript(Ovale.playerClass, nil, CUSTOM_NAME, CUSTOM_DESCRIPTION, code, "script")
					Ovale.db.profile.source = CUSTOM_NAME
					Ovale.db.profile.code = OvaleScripts:GetScript(CUSTOM_NAME)
					self:SendMessage("Ovale_ScriptChanged")
				end,
			},
			showHiddenScripts = {
				order = 40,
				type = "toggle",
				name = L["Show hidden"],
				get = function(info) return Ovale.db.profile.showHiddenScripts end,
				set = function(info, value) Ovale.db.profile.showHiddenScripts = value end
			},
		},
	}

	local appName = self:GetName()
	AceConfig:RegisterOptionsTable(appName, options)
	AceConfigDialog:AddToBlizOptions(appName, L["Script"], OVALE)
end
--</public-static-methods>
