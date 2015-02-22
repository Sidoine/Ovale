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

local gsub = string.gsub
local pairs = pairs
local API_UnitClass = UnitClass

-- Player's class.
local _, self_class = API_UnitClass("player")

-- Name and description of "custom" script.
local CUSTOM_NAME = "custom"
local CUSTOM_DESCRIPTION = L["Script personnalisé"]

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
	self:CreateOptions()
	-- Register the custom script.
	self:RegisterScript(self_class, CUSTOM_NAME, CUSTOM_DESCRIPTION, Ovale.db.profile.code)
	-- Register an empty script called "Disabled" that can be used to show no icons.
	self:RegisterScript(nil, "Disabled", "Disabled", "", "script")
end

-- Return a table of script descriptions indexed by name.
function OvaleScripts:GetDescriptions(scriptType)
	local descriptionsTable = {}
	for name, script in pairs(self.script) do
		if not scriptType or script.type == scriptType then
			descriptionsTable[name] = script.desc
		end
	end
	return descriptionsTable
end

function OvaleScripts:RegisterScript(class, name, description, code, scriptType)
	if not class or class == self_class then
		self.script[name] = self.script[name] or {}
		local script = self.script[name]
		script.type = scriptType or "script"
		script.desc = description or name
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

function OvaleScripts:GetScript(name)
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
					OvaleScripts:RegisterScript(self_class, CUSTOM_NAME, CUSTOM_DESCRIPTION, v, "script")
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
					OvaleScripts:RegisterScript(self_class, CUSTOM_NAME, CUSTOM_DESCRIPTION, code, "script")
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
