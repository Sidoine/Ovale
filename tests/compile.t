-- Number of specializations for each class.
local NUM_SPECIALIZATIONS = {
	DEATHKNIGHT = 3,
	DRUID = 4,
	HUNTER = 3,
	MAGE = 3,
	MONK = 3,
	PALADIN = 3,
	PRIEST = 3,
	ROGUE = 3,
	SHAMAN = 3,
	WARLOCK = 3,
	WARRIOR = 3,
}

-- Addon files needed to run methods from OvaleCompile.
-- The order of files is as listed in Ovale.toc.
local addonFiles = {
	"Ovale.lua",
	"Localization.lua",
	"Options.lua",
	"Debug.lua",
	-- Profiling module.
	"Profiler.lua",
	-- Utility modules.
	"Pool.lua",
	"PoolRefCount.lua",
	"Queue.lua",
	-- Core modules.
	"AST.lua",
	"Compile.lua",
	"Condition.lua",
	"Cooldown.lua",
	"Data.lua",
	"Equipment.lua",
	"Lexer.lua",
	"PaperDoll.lua",
	"Runes.lua",
	"Score.lua",
	"Scripts.lua",
	"SpellBook.lua",
	"Stance.lua",
	"State.lua",
	-- Additional modules.
	"conditions.lua",
	"scripts/files.xml",
}

local root = "../"
for class, numSpecializations in pairs(NUM_SPECIALIZATIONS) do
	for specialization = 1, numSpecializations do
		-- Create WoWMock sandbox.
		dofile(root .. "WoWMock.lua")
		local config = {
			class = class,
			specialization = specialization,
		}
		local sandbox = WoWMock:NewSandbox(config)

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
		local OvaleCompile = Ovale.OvaleCompile
		local OvalePaperDoll = Ovale.OvalePaperDoll
		local OvaleScripts = Ovale.OvaleScripts

		-- Parse the default Ovale script for the class.
		local class = UnitClass()
		local specialization = OvalePaperDoll:GetSpecialization()
		local descriptionTbl = OvaleScripts:GetDescriptions("script")
		for source in pairs(descriptionTbl) do
			if source ~= "custom" and source ~= "Disabled" then
				print(string.format("Compiling '%s' script for %s (%s).", source, class, specialization))
				OvaleCompile:CompileScript(source)
				OvaleCompile:EvaluateScript(true)
			end
		end
	end
end
