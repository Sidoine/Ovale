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

	-- Fake loading process.
	WoWAPI:Fire("ADDON_LOADED")
	WoWAPI:Fire("SPELLS_CHANGED")
	WoWAPI:Fire("PLAYER_LOGIN")
	WoWAPI:Fire("PLAYER_ENTERING_WORLD")
end

local OvaleSimulationCraft = Ovale.OvaleSimulationCraft

local gsub = string.gsub
local ipairs = ipairs
local strfind = string.find
local tinsert = table.insert

local profilesDirectory = "../../SimulationCraft/profiles/Tier17M"

-- Save original input and output handles.
local saveInput = io.input()
local saveOutput = io.output()

--[[
	Load each SimulationCraft profile and do the following things:

	1. Unparse the profile to verify the action list is being properly parsed.
	2. Emit the corresponding Ovale script to standard output.
--]]

local separator = string.rep("-", 80)

local files = {}
do
	local dir = io.popen("dir /b " .. gsub(profilesDirectory, "/", "\\"))
	for name in dir:lines() do
		tinsert(files, name)
	end
	dir:close()
	OvaleSimulationCraft:GetValidProfiles(files)
end

for _, name in ipairs(files) do
	local inputName =  profilesDirectory .. "/" .. name
	io.input(inputName)
	local simc = io.read("*all")
	-- Valid profiles never set "optimal_raid".
	if not strfind(simc, "optimal_raid=") then
		-- Parse SimulationCraft profile and emit the corresponding Ovale script.
		local profile = OvaleSimulationCraft:ParseProfile(simc)
		if profile then
			print(separator)
			print(">>>", name)
			print(OvaleSimulationCraft:Unparse(profile))
			print(separator)
			print(OvaleSimulationCraft:Emit(profile))
		end
	end
end

-- Restore original input and output handles.
io.input(saveInput)
io.output(saveOutput)
