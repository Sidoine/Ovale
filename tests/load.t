-- Create WoWMock sandbox.
local root = "../"
dofile(root .. "WoWMock.lua")
local sandbox = WoWMock:NewSandbox()

-- Load addon files into the sandbox.
sandbox:LoadAddonFile("Ovale.toc", root, true)

-- Fire events to simulate the addon-loading process.
sandbox:Fire("ADDON_LOADED")
sandbox:Fire("SPELLS_CHANGED")
sandbox:Fire("PLAYER_LOGIN")
sandbox:Fire("PLAYER_ENTERING_WORLD")
