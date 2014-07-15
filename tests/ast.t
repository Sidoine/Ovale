--[[------------------------------
	Load fake WoW environment.
--]]------------------------------
local root = "../"
do
	local state = {
		class = "SHAMAN",
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
		-- Profiling module.
		"Profiler.lua",
		-- Utility modules.
		"OvalePool.lua",
		"OvaleQueue.lua",
		-- Core modules.
		"OvaleAST.lua",
		"OvaleCondition.lua",
		"OvaleLexer.lua",
		"OvaleRunes.lua",
		"OvaleScripts.lua",
		"OvaleState.lua",
		-- Additional modules.
		"conditions/files.xml",
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
local ast = OvaleAST:ParseScript("Ovale", { verify = false })
if ast then
	OvaleAST:Optimize(ast)
	Ovale:Print(OvaleAST:NodeToString(ast))
	Ovale:Print(separator)
	Ovale:Print(OvaleAST:Unparse(ast))
	OvaleAST:Release(ast)
end
Ovale:Print(separator)
OvaleAST:Debug()
