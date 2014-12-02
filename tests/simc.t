-- Create WoWMock sandbox.
local root = "../"
dofile(root .. "WoWMock.lua")
local sandbox = WoWMock:NewSandbox()

-- Load addon files into the sandbox.
sandbox:LoadAddonFile("Ovale.toc", root)

-- Fire events to simulate the addon-loading process.
sandbox:Fire("ADDON_LOADED")
sandbox:Fire("SPELLS_CHANGED")
sandbox:Fire("PLAYER_LOGIN")
sandbox:Fire("PLAYER_ENTERING_WORLD")

-- Enter sandbox.
setfenv(1, sandbox)

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
