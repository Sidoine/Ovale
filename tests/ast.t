-- Create WoWMock sandbox.
local root = "../"
dofile(root .. "WoWMock.lua")
local sandbox = WoWMock:NewSandbox()

-- Addon files needed to run methods from OvaleAST.
-- The order of the the files is as listed in Ovale.toc.
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
	"TimeSpan.lua",
	-- Core modules.
	"AST.lua",
	"Compile.lua",
	"Condition.lua",
	"Data.lua",
	"Equipment.lua",
	"Lexer.lua",
	"PaperDoll.lua",
	"Runes.lua",
	"Scripts.lua",
	"SpellBook.lua",
	"Stance.lua",
	"State.lua",
	-- Core modules with dependencies.
	"Frame.lua",
	-- Additional modules.
	"conditions.lua",
	"scripts/files.xml",
}

-- Load addon files into the sandbox.
sandbox:SetAddonName("Ovale")
for _, filename in ipairs(addonFiles) do
	sandbox:LoadAddonFile(filename, root)
end

-- Fire events to simulate the addon-loading process.
sandbox:Fire("ADDON_LOADED")
sandbox:Fire("SPELLS_CHANGED")
sandbox:Fire("PLAYER_LOGIN")
sandbox:Fire("PLAYER_ENTERING_WORLD")

-- Enter sandbox.
setfenv(1, sandbox)

local OvaleAST = Ovale.OvaleAST
local separator = string.rep("-", 80)

-- Parse the default Ovale script for the class.
local class = UnitClass()
local source = "Ovale"
local ast = OvaleAST:ParseScript(source)
if ast then
	OvaleAST:Optimize(ast)
	print(OvaleAST:NodeToString(ast))
	print(separator)
	print(OvaleAST:Unparse(ast))
	OvaleAST:Release(ast)
	print(separator)
	OvaleAST:DebugAST()
end
