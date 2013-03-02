--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- This addon is a script repository.

local _, Ovale = ...
OvaleScripts = Ovale:NewModule("OvaleScripts")

--<private-static-properties>
--</private-static-properties>

--<public-static-properties>
-- Table of default class scripts, indexed by class tokens.
OvaleScripts.script = {
	DEATHKNIGHT = {},
	DRUID = {},
	HUNTER = {},
	MAGE = {},
	MONK = {},
	PALADIN = {},
	PRIEST = {},
	ROGUE = {},
	SHAMAN = {},
	WARLOCK = {},
	WARRIOR = {},
}
--</public-static-properties>

--<public-static-methods>
-- Return a table of script descriptions indexed by source.
function OvaleScripts:GetDescriptions()
	local descriptionsTable = {}
	for src, tbl in pairs(self.script[OvaleData.className]) do
		descriptionsTable[src] = tbl.desc
	end
	return descriptionsTable
end

function OvaleScripts:RegisterScript(class, source, description, code)
	-- Default values for description and code.
	description = description or source
	code = code or ""

	if not self.script[class][source] then
		self.script[class][source] = {}
	end
	self.script[class][source].desc = description
	self.script[class][source].code = code
end

function OvaleScripts:UnregisterScript(class, source)
	self.script[class][source] = nil
end
--</public-static-methods>