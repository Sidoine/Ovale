-- Constants.
local outputDirectory = "../simulationcraft"
local profilesDirectory = "../../SimulationCraft/profiles/Tier18M"
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

local gmatch = string.gmatch
local gsub = string.gsub
local ipairs = ipairs
local strfind = string.find
local strlower = string.lower
local strsub = string.sub
local tinsert = table.insert
local tremove = table.remove
local tsort = table.sort

-- Save original input and output handles.
local saveInput = io.input()
local saveOutput = io.output()

-- Create the output directory.
os.execute("mkdir " .. gsub(outputDirectory, "/", "\\"))

-- Get the valid profile names from the profiles directory.
local files = {}
do
	local dir = io.popen("dir /b " .. gsub(profilesDirectory, "/", "\\"))
	for name in dir:lines() do
		tinsert(files, name)
	end
	dir:close()

	-- Filter out invalid profile names.
	local filter = {}
	for _, name in ipairs(files) do
		local ok = true
		local lowername = strlower(name)

		-- Lexer for the profile filename.
		local tokenIterator = gmatch(lowername, "[^_.]+")

		-- Profile names always end in ".simc".
		ok = ok and strsub(lowername, -5, -1) == ".simc"

		local baseProfileName
		-- Profile names always start with a class name.
		if ok then
			-- The first token should be the class.
			local class = tokenIterator()
			-- SimulationCraft uses "death_knight" while WoW uses "deathknight".
			local wowClass = class
			if class == "death" then
				local token = tokenIterator()
				class = class .. "_" .. token
				wowClass = wowClass .. token
			end
			baseProfileName = class
			if not SIMC_CLASS[wowClass] then
				ok = false
			end
			-- Skip class driver profile that just forces other profiles to be run.
			if ok and strfind(lowername, class .. "_t%d+[a-z].simc") then
				ok = false
			end
		end

		-- The next token should be the required specialization.
		if ok then
			local specialization = tokenIterator()
			baseProfileName = baseProfileName .. "_" .. specialization
		end

		-- Filter out any profiles that are modifications of an existing base profile.
		if ok then
			-- Valid modifiers that can come before the tier designation that are part
			-- of the base profile name.
			local VALID_PRE_TIER_MODIFIER = {
				["1h"] = true,
				["2h"] = true,
			}
			local modifier = tokenIterator()
			while ok and modifier do
				if strfind(modifier, "t%d+[a-z]") then
					baseProfileName = baseProfileName .. "_" .. modifier
					break
				elseif VALID_PRE_TIER_MODIFIER[modifier] then
					baseProfileName = baseProfileName .. "_" .. modifier
				end
				modifier = tokenIterator()
			end
			baseProfileName = baseProfileName .. ".simc"
			if lowername ~= baseProfileName then
				for _, fileName in ipairs(files) do
					if baseProfileName == strlower(fileName) then
						ok = false
						break
					end
				end
			end
		end
		if not ok then
			filter[name] = true
		end
	end
	for k = #files, 1, -1 do
		if filter[files[k]] then
			tremove(files, k)
		end
	end
	tsort(files)
end

for _, filename in ipairs(files) do
	-- Read the entire contents of the input file.
	local inputName = profilesDirectory .. "/" .. filename
	io.input(inputName)
	local simc = io.read("*all")

	-- Output the contents into the proper output file.
	local outputName = outputDirectory .. "/SimulationCraft_" .. filename
	io.output(outputName)
	io.write("### SimulationCraft\n")
	io.write(simc)
	io.close()
end

local outputFiles = {}
do
	local dir = io.popen("dir /b " .. gsub(outputDirectory, "/", "\\"))
	for name in dir:lines() do
		outputFiles[name] = true
	end
	dir:close()
end
for _, name in ipairs(files) do
	local outputName = "SimulationCraft_" .. name
	outputFiles[outputName] = nil
end
local output = {}
for name in pairs(outputFiles) do
	tinsert(output, name)
end
if #output > 0 then
	tsort(output)
	print("Extra files in " .. outputDirectory .. ":")
	for _, name in ipairs(output) do
		print("    " .. name)
	end
end

-- Restore original input and output handles.
io.input(saveInput)
io.output(saveOutput)
