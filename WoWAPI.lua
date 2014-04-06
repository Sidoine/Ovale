--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

--[[
	This file implements parts of the WoW API for development and unit-testing.

	This file is not meant to be loaded into the addon.  It should be used only
	outside of the WoW environment, such as when loaded by a standalone Lua 5.1
	interpreter.

	It provides global symbols.
--]]

-- RAID_CLASS_COLORS is useful mostly as a table to loop through the keys, which are
-- the class tokens for all playable classes.
RAID_CLASS_COLORS = RAID_CLASS_COLORS or {
	DEATHKNIGHT = true,
	DRUID = true,
	HUNTER = true,
	MAGE = true,
	MONK = true,
	PALADIN = true,
	PRIEST = true,
	ROGUE = true,
	SHAMAN = true,
	WARLOCK = true,
	WARRIOR = true,
}

-- wipe() is a non-standard Lua function that clears the contents of a table
-- and leaves the table pointer intact.
wipe = wipe or function(t)
	for k in pairs(t) do
		t[k] = nil
	end
end
table.wipe = table.wipe or wipe

-- strsplit() is a non-standard Lua function that splits a string and returns
-- multiple return values for each substring delimited by the named delimiter
-- character.
--
-- This implementaiton is taken verbatim from http://lua-users.org/wiki/SplitJoin
strsplit = strsplit or function(delim, str, maxNb)
	-- Eliminate bad cases...
	if string.find(str, delim) == nil then
		return str
	end
	if maxNb == nil or maxNb < 1 then
		maxNb = 0    -- No limit
	end
	local result = {}
	local pat = "(.-)" .. delim .. "()"
	local nb = 0
	local lastPos
	for part, pos in string.gfind(str, pat) do
		nb = nb + 1
		result[nb] = part
		lastPos = pos
		if nb == maxNb then break end
	end
	-- Handle the last field
	if nb ~= maxNb then
		result[nb + 1] = string.sub(str, lastPos)
	end
	return unpack(result)
end

-- LoadAddonFile() does the equivalent of dofile(), but strips out the WoW addon
-- file line that uses ... to get the file arguments.
LoadAddonFile = LoadAddonFile or function(filename)
	local lineList = {}
	for line in io.lines(filename) do
		if not string.match(line, "^%s*local%s+[%w%s_,]*%s*=%s*[.][.][.]%s*$") then
			table.insert(lineList, line)
		end
	end
	local fileString = table.concat(lineList, "\n")
	local func = loadstring(fileString)
	func()
end
