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
local strmatch = string.match

local profilesDirectory = "..\\..\\SimulationCraft\\profiles\\Tier16M"

-- Save original input and output handles.
local saveInput = io.input()
local saveOutput = io.output()

--[[
	Load each SimulationCraft profile and do the following things:

	1. Unparse the profile to verify the action list is being properly parsed.
	2. Emit the corresponding Ovale script to standard output.
--]]

local separator = string.rep("-", 80)
local dir = io.popen("dir /b " .. profilesDirectory)
for filename in dir:lines() do
	-- Profile names always begin with a capital letter.
	if strmatch(filename, "^[A-Z]") then
		local inputName = gsub(profilesDirectory, "\\", "/") .. "/" .. filename
		io.input(inputName)
		local simc = io.read("*all")
		-- Valid profiles never set "optimal_raid".
		if not strfind(simc, "optimal_raid=") then
			-- Parse SimulationCraft profile and emit the corresponding Ovale script.
			local profile = OvaleSimulationCraft:ParseProfile(simc)
			if profile then
				print(separator)
				print(OvaleSimulationCraft:Unparse(profile))
				print(separator)
				print(OvaleSimulationCraft:Emit(profile))
			end
		end
	end
end

-- Restore original input and output handles.
io.input(saveInput)
io.output(saveOutput)
