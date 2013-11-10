--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- This addon is a script repository.

local _, Ovale = ...
local OvaleScripts = Ovale:NewModule("OvaleScripts")
Ovale.OvaleScripts = OvaleScripts

--<private-static-properties>
local OvalePaperDoll = Ovale.OvalePaperDoll
--</private-static-properties>

--<public-static-properties>
-- A "script" is a table { type = "scriptType", desc = "description", code = "..." }
-- Table of scripts, indexed by name.
OvaleScripts.script = {}
--</public-static-properties>

--<public-static-methods>
-- Return a table of script descriptions indexed by name.
function OvaleScripts:GetDescriptions(scriptType)
	scriptType = scriptType or "script"
	local descriptionsTable = {}
	for name, script in pairs(self.script) do
		if script.type == scriptType then
			descriptionsTable[name] = script.desc
		end
	end
	return descriptionsTable
end

function OvaleScripts:RegisterScript(class, name, description, code, scriptType)
	if not class or class == OvalePaperDoll.class then
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
