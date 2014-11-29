--[[
	This Lua file may be invoked to test parsing the default script for other classes via:
		cat ast.t | sed "s/DEATHKNIGHT/DRUID/g" | lua
--]]

--[[------------------------------
	Load fake WoW environment.
--]]------------------------------
local root = "../"
do
	local state = {
		class = "DEATHKNIGHT",
		level = 90,
	}
	dofile(root .. "WoWAPI.lua")
	WoWAPI:Initialize("Ovale", state)
	WoWAPI:ExportSymbols()
end

--[[-----------------------------------------------
	Fake loading via file order from Ovale.toc.
--]]-----------------------------------------------
do
	local addonFiles = {
		"Ovale.lua",
		"Localization.lua",
		"Options.lua",
		"Debug.lua",
		-- Profiling module.
		"Profiler.lua",
		-- Utility modules.
		"Pool.lua",
		"Queue.lua",
		-- Core modules.
		"AST.lua",
		"Condition.lua",
		"Lexer.lua",
		"Runes.lua",
		"Scripts.lua",
		"SpellBook.lua",
		"Stance.lua",
		"State.lua",
		-- Additional modules.
		"conditions.lua",
		"scripts/files.xml",
	}
	for _, file in ipairs(addonFiles) do
		WoWAPI:LoadAddonFile(file, root)
	end

	local AceAddon = LibStub("AceAddon-3.0")
	AceAddon:ADDON_LOADED()
end

local OvaleAST = Ovale.OvaleAST
local separator = string.rep("-", 80)

-- Parse the default Ovale script for the class.
local class = UnitClass()
local source = "Ovale"
local ast = OvaleAST:ParseScript(source)
if ast then
	OvaleAST:Optimize(ast)
--	Ovale:Print(OvaleAST:NodeToString(ast))
--	Ovale:Print(separator)
--	Ovale:Print(OvaleAST:Unparse(ast))
--	OvaleAST:Release(ast)
--	Ovale:Print(separator)
--	OvaleAST:DebugAST()
	Ovale:Print("Successfully parsed %s '%s' script.", class, source)
end
