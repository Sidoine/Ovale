-- Constants.
local outputDirectory = "../scripts"
local profilesDirectory = "../simulationcraft"
local root = "../"

local SIMC_CLASS = {
	deathknight = true,
	druid = true,
	hunter = true,
	mage = true,
	monk = true,
	paladin = true,
	priest = true,
	rogue = true,
	shaman = true,
	warlock = true,
	warrior = true,
}

local format = string.format
local gmatch = string.gmatch
local gsub = string.gsub
local ipairs = ipairs
local strfind = string.find
local strlen = string.len
local strlower = string.lower
local strsub = string.sub
local strupper = string.upper
local tconcat = table.concat
local tinsert = table.insert
local tsort = table.sort

--[[
	Returns the lowercase version of a string, with spaces and non-alphanumeric
	characters removed or converted to underscores.
--]]
local function Canonicalize(s)
	local token = "xXxUnDeRsCoReXxX"
	-- Convert to lowercase.
	s = strlower(s)
	-- Convert spaces, dashes, underscores, and parentheses into the token.
	s = gsub(s, "[%s%-%_%(%)%{%}%[%]]", token)
	-- Strip other punctuation characters.
	s = gsub(s, "%p", "")
	-- Convert the token to an underscore.
	s = gsub(s, token, "_")
	-- Trim extra underscores.
	s = gsub(s, "_+", "_")
	-- Trim leading and trailing underscores.
	s = gsub(s, "^_", "")
	s = gsub(s, "_$", "")
	return s
end

-- Save original input and output handles.
local saveInput = io.input()
local saveOutput = io.output()

-- Create the output directory.
os.execute("mkdir " .. gsub(outputDirectory, "/", "\\"))

-- Get the profile names from the profiles directory.
local files = {}
do
	local dir = io.popen("dir /b " .. gsub(profilesDirectory, "/", "\\"))
	for name in dir:lines() do
		tinsert(files, name)
	end
	dir:close()
	tsort(files)
end

local output = {}
for _, filename in ipairs(files) do
	local inputName = profilesDirectory .. "/" .. filename
	io.input(inputName)
	local simc = io.read("*all")
	-- Valid profiles never set "optimal_raid".
	if not strfind(simc, "optimal_raid=") then
		-- Find the source, class, and specialization from the profile.
		local source, class, specialization
		for line in gmatch(simc, "[^\r\n]+") do
			if not source then
				-- The source is named at the start of the profile as "### source".
				if strsub(line, 1, 4) == "### " then
					source = strsub(line, 5)
				end
			end
			if not class then
				for simcClass in pairs(SIMC_CLASS) do
					local length = strlen(simcClass)
					if strsub(line, 1, length + 1) == simcClass .. "=" then
						class = strupper(simcClass)
					end
				end
			end
			if not specialization then
				if strsub(line, 1, 5) == "spec=" then
					specialization = strsub(line, 6)
				end
			end
			if class and specialization then
				break
			end
		end

		-- Create WoWMock sandbox.
		dofile(root .. "WoWMock.lua")
		local config = {
			class = class,
			specialization = specialization,
		}
		local sandbox = WoWMock:NewSandbox(config)

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
		local wipe = wipe
		-- Parse SimulationCraft profile and emit the corresponding Ovale script.
		local profile = OvaleSimulationCraft:ParseProfile(simc)
		local profileName = strsub(profile.annotation.name, 2, -2)
		local name, desc
		if source then
			desc = format("%s: %s", source, profileName)
		else
			desc = profileName
		end
		name = Canonicalize(desc)
		wipe(output)
		output[#output + 1] = "local OVALE, Ovale = ..."
		output[#output + 1] = "local OvaleScripts = Ovale.OvaleScripts"
		output[#output + 1] = ""
		output[#output + 1] = "do"
		output[#output + 1] = format('	local name = "%s"', name)
		output[#output + 1] = format('	local desc = "[6.0] %s"', desc)
		output[#output + 1] = "	local code = [["
		output[#output + 1] = OvaleSimulationCraft:Emit(profile, true)
		output[#output + 1] = "]]"
		output[#output + 1] = format('	OvaleScripts:RegisterScript("%s", "%s", name, desc, code, "%s")', profile.annotation.class, profile.annotation.specialization, "script")
		output[#output + 1] = "end"
		output[#output + 1] = ""

		-- Output the Lua code into the proper output file.
		local outputFileName = gsub(strlower(filename), ".simc", ".lua")
		-- Strip the tier designation from the end of the output filename.
		outputFileName = gsub(outputFileName, "_t%d+%w+%.", ".")
		outputFileName = gsub(outputFileName, "_t%d+%w+_", "_")
		-- Fix the name of the death knight output file.
		outputFileName = gsub(outputFileName, "death_knight", "deathknight")
		print("Generating " .. outputFileName)
		local outputName = outputDirectory .. "/" .. outputFileName
		io.output(outputName)
		io.write(tconcat(output, "\n"))
		io.close()
	end
end

-- Restore original input and output handles.
io.input(saveInput)
io.output(saveOutput)
