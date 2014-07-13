--[[------------------------------
	Load fake WoW environment.
--]]------------------------------
local root = "../"
do
	local state = {
		class = "DRUID",
	}
	dofile("WoWAPI.lua")
	WoWAPI:Initialize("Ovale", state)
	WoWAPI:ExportSymbols()
end

do
	-- Load all of the addon files.
	WoWAPI:LoadAddonFile("Ovale.toc")

	-- Pretend to fire ADDON_LOADED event.
	local AceAddon = LibStub("AceAddon-3.0")
	AceAddon:ADDON_LOADED()
end

local OvaleSimulationCraft = Ovale.OvaleSimulationCraft

local profilesDirectory = "..\\SimulationCraft\\profiles\\Tier16H"
local outputDirectory = "scripts"

local saveInput = io.input()
local saveOutput = io.output()

local dir = io.popen("dir /b " .. profilesDirectory)
os.execute("mkdir " .. outputDirectory)
for filename in dir:lines() do
	if string.match(filename, "^[A-Z]") then
		local inputName = string.gsub(profilesDirectory, "\\", "/") .. "/" .. filename
		io.input(inputName)
		local simcStr = io.read("*all")
		if not string.find(simcStr, "optimal_raid=") then
			local simc = OvaleSimulationCraft(simcStr)
			simc.simcComments = true

			local outputFileName = "simulationcraft_" .. string.lower(string.gsub(filename, ".simc", ".lua"))
			outputFileName = string.gsub(outputFileName, "death_knight", "deathknight")
			print("Generating " .. outputFileName)
			local outputName = outputDirectory .. "/" .. outputFileName
			io.output(outputName)
			io.write(table.concat(simc:GenerateScript(), "\n"))
		end
	end
end

io.input(saveInput)
io.output(saveOutput)
