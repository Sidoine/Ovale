--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- This addon is a script repository.

local _, Ovale = ...
local OvaleScripts = Ovale:NewModule("OvaleScripts")
Ovale.OvaleScripts = OvaleScripts

--<private-static-properties>
local pairs = pairs
local API_UnitClass = UnitClass

-- Player's class.
local _, self_class = API_UnitClass("player")
--</private-static-properties>

--<public-static-properties>
-- A "script" is a table { type = "scriptType", desc = "description", code = "..." }
-- Table of scripts, indexed by name.
OvaleScripts.script = {}
--</public-static-properties>

--<public-static-methods>
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
--</public-static-methods>
