--[[------------------------------
	Load fake WoW environment.
--]]------------------------------
local root = "../"
do
	local state = {
		class = "DRUID",
		level = 90,
	}
	dofile(root .. "WoWAPI.lua")
	WoWAPI:Initialize("Ovale", state)
	WoWAPI:ExportSymbols()
end

do
	-- Load all of the addon files.
	WoWAPI:LoadAddonFile("Ovale.toc", root, true)

	-- Pretend to fire ADDON_LOADED event.
	local AceAddon = LibStub("AceAddon-3.0")
	AceAddon:ADDON_LOADED()
end
