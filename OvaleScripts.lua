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
-- Table of scripts, indexed by source; a script is a table { description = description, code = "..." }.
OvaleScripts.script = {}
--</public-static-properties>

--<public-static-methods>
-- Return a table of script descriptions indexed by source.
function OvaleScripts:GetDescriptions()
	local descriptionsTable = {}
	for src, tbl in pairs(self.script) do
		descriptionsTable[src] = tbl.desc
	end
	return descriptionsTable
end

function OvaleScripts:RegisterScript(class, source, description, code)
	if class == OvalePaperDoll.class then
		self.script[source] = self.script[source] or {}
		self.script[source].desc = description or source
		self.script[source].code = code or ""
	end
end

function OvaleScripts:UnregisterScript(class, source)
	if class == OvalePaperDoll.class then
		self.script[source] = nil
	end
end
--</public-static-methods>
