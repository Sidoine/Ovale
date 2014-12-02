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
	WoWMock:LoadAddonFile("Ovale.toc", root)
	-- Fire ADDON_LOADED event.
	WoWMock:Fire("ADDON_LOADED")
end

local OvaleSimulationCraft = Ovale.OvaleSimulationCraft

local format = string.format
local gsub = string.gsub
local strfind = string.find
local strlower = string.lower
local strsub = string.sub
local tconcat = table.concat
local tinsert = table.insert
local wipe = wipe

local profilesDirectory = "../../SimulationCraft/profiles/Tier17M"
local outputDirectory = "../scripts"

-- Save original input and output handles.
local saveInput = io.input()
local saveOutput = io.output()

local files = {}
do
	local dir = io.popen("dir /b " .. gsub(profilesDirectory, "/", "\\"))
	for name in dir:lines() do
		tinsert(files, name)
	end
	dir:close()
	OvaleSimulationCraft:GetValidProfiles(files)

	-- Create the output directory.
	local outputDir = 
	os.execute("mkdir " .. gsub(outputDirectory, "/", "\\"))
end

local output = {}
for _, filename in ipairs(files) do
	local inputName = profilesDirectory .. "/" .. filename
	io.input(inputName)
	local simc = io.read("*all")
	-- Valid profiles never set "optimal_raid".
	if not strfind(simc, "optimal_raid=") then
		-- Parse SimulationCraft profile and emit the corresponding Ovale script.
		local profile = OvaleSimulationCraft:ParseProfile(simc)
		local name = format("SimulationCraft: %s", strsub(profile.annotation.name, 2, -2))
		wipe(output)
		output[#output + 1] = "local OVALE, Ovale = ..."
		output[#output + 1] = "local OvaleScripts = Ovale.OvaleScripts"
		output[#output + 1] = ""
		output[#output + 1] = "do"
		output[#output + 1] = format('	local name = "%s"', name)
		output[#output + 1] = format('	local desc = "[6.0] %s"', name)
		output[#output + 1] = "	local code = [["
		output[#output + 1] = OvaleSimulationCraft:Emit(profile)
		output[#output + 1] = "]]"
		output[#output + 1] = format('	OvaleScripts:RegisterScript("%s", name, desc, code, "reference")', profile.annotation.class)
		output[#output + 1] = "end"
		output[#output + 1] = ""

		-- Output the Lua code into the proper output file.
		local outputFileName = "simulationcraft_" .. gsub(strlower(filename), ".simc", ".lua")
		-- Strip the tier designation from the end of the output filename.
		outputFileName = gsub(outputFileName, "_t%d+%w+%.", ".")
		outputFileName = gsub(outputFileName, "_t%d+%w+_", "_")
		-- Fix the name of the death knight output file.
		outputFileName = gsub(outputFileName, "death_knight", "deathknight")
		print("Generating " .. outputFileName)
		local outputName = outputDirectory .. "/" .. outputFileName
		io.output(outputName)
		io.write(tconcat(output, "\n"))
	end
end

-- Restore original input and output handles.
io.input(saveInput)
io.output(saveOutput)
