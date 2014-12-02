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
	WoWMock:Initialize("Ovale", state)
	WoWMock:ExportSymbols()
end

do
	-- Load all of the addon files.
	WoWMock:LoadAddonFile("Ovale.toc", root, true)

	-- Fake loading process.
	WoWMock:Fire("ADDON_LOADED")
	WoWMock:Fire("SPELLS_CHANGED")
	WoWMock:Fire("PLAYER_LOGIN")
	WoWMock:Fire("PLAYER_ENTERING_WORLD")
end
