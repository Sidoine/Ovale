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
	WoWAPI:LoadAddonFile("Ovale.toc", root)

	-- Pretend to fire ADDON_LOADED event.
	local AceAddon = LibStub("AceAddon-3.0")
	AceAddon:ADDON_LOADED()
end

local OvaleSimulationCraft = Ovale.OvaleSimulationCraft

local format = string.format
local gsub = string.gsub
local strfind = string.find
local strlower = string.lower
local strmatch = string.match
local strsub = string.sub
local tconcat = table.concat
local wipe = table.wipe

local profilesDirectory = "..\\..\\SimulationCraft\\profiles\\Tier16M"
local outputDirectory = "..\\scripts"
local output = {}

-- Save original input and output handles.
local saveInput = io.input()
local saveOutput = io.output()

local dir = io.popen("dir /b " .. profilesDirectory)
os.execute("mkdir " .. outputDirectory)

for filename in dir:lines() do
	local doFile = true
	-- Profile names always begin with a capital letter.
	if doFile and not strmatch(filename, "^[A-Z]") then
		doFile = false
	end
	-- Profile names always end in ".simc".
	if doFile and not strmatch(filename, "%.simc$") then
		doFile = false
	end
	-- Skip files that are variations of the default profiles.
	if doFile and strmatch(filename, "_T%d+%w+_[%w_]+%.simc$") then
		doFile = false
	end
	if doFile then
		local inputName = gsub(profilesDirectory, "\\", "/") .. "/" .. filename
		io.input(inputName)
		local simc = io.read("*all")
		-- Valid profiles never set "optimal_raid".
		if not strfind(simc, "optimal_raid=") then
			-- Parse SimulationCraft profile and emit the corresponding Ovale script.
			local profile = OvaleSimulationCraft:ParseProfile(simc)
			local name = format("SimulationCraft: %s", strsub(profile.annotation.name, 2, -2))
			wipe(output)
			output[#output + 1] = "local _, Ovale = ..."
			output[#output + 1] = "local OvaleScripts = Ovale.OvaleScripts"
			output[#output + 1] = ""
			output[#output + 1] = "do"
			output[#output + 1] = format('	local name = "%s"', name)
			output[#output + 1] = format('	local desc = "[6.0.2] %s"', name)
			output[#output + 1] = "	local code = [["
			output[#output + 1] = OvaleSimulationCraft:Emit(profile)
			output[#output + 1] = "]]"
			output[#output + 1] = format('	OvaleScripts:RegisterScript("%s", name, desc, code, "reference")', profile.annotation.class)
			output[#output + 1] = "end"
			output[#output + 1] = ""

			-- Output the Lua code into the proper output file.
			local outputFileName = "simulationcraft_" .. strlower(gsub(filename, ".simc", ".lua"))
			-- Strip the tier designation from the end of the output filename.
			outputFileName = gsub(outputFileName, "_t%d+%w+%.", ".")
			-- Fix the name of the death knight output file.
			outputFileName = gsub(outputFileName, "death_knight", "deathknight")
			print("Generating " .. outputFileName)
			local outputName = gsub(outputDirectory, "\\", "/") .. "/" .. outputFileName
			io.output(outputName)
			io.write(tconcat(output, "\n"))
		end
	end
end

-- Restore original input and output handles.
io.input(saveInput)
io.output(saveOutput)
