--[[------------------------------
	Load fake WoW environment.
--]]------------------------------
local root = "../"
do
	local state = {
		class = "DRUID",
		level = 90,
	}
	dofile(root .. "WoWMock.lua")
	WoWAPI:Initialize("Ovale", state)
	WoWAPI:ExportSymbols()
end

do
	-- Load all of the addon files.
	WoWAPI:LoadAddonFile("Ovale.toc", root, true)

	-- Fake loading process.
	WoWAPI:Fire("ADDON_LOADED")
	WoWAPI:Fire("SPELLS_CHANGED")
	WoWAPI:Fire("PLAYER_LOGIN")
	WoWAPI:Fire("PLAYER_ENTERING_WORLD")
end
