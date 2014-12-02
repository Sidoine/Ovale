--[[------------------------------
	Load fake WoW environment.
--]]------------------------------
local root = "../"
do
	dofile(root .. "WoWMock.lua")
	WoWMock:Initialize("Ovale")
	WoWMock:ExportSymbols()
end

--[[-----------------------------------------------
	Fake loading via file order from Ovale.toc.
--]]-----------------------------------------------
do
	local addonFiles = {
		"Ovale.lua",
		"TimeSpan.lua",
	}
	for _, file in ipairs(addonFiles) do
		WoWMock:LoadAddonFile(file, root)
	end
end

local OvaleTimeSpan = Ovale.OvaleTimeSpan
local format = string.format
local tconcat = table.concat
local tinsert = table.insert

local tests = {}

tests[#tests + 1] = function()
	local A = OvaleTimeSpan(1, 2, 3, 4)
	local atTime = 0

	local msg = format("%s should not contain %s", tostring(A), tostring(atTime))
	if A:HasTime(atTime) then
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A = OvaleTimeSpan(1, 2, 3, 4)
	local atTime = 1

	local msg = format("%s should contain %s", tostring(A), tostring(atTime))
	if not A:HasTime(atTime) then
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 2, 3, 4)
	local expected = OvaleTimeSpan(0, 1, 2, 3, 4, math.huge)

	local msg = { format("complement of %s", tostring(A)) }
	local result = A:Complement()
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan()
	local expected = OvaleTimeSpan(0, math.huge)

	local msg = { "complement of empty set should be the universe" }
	local result = A:Complement()
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(0, math.huge)
	local expected = OvaleTimeSpan()

	local msg = { "complement of the universe should be the empty set" }
	local result = A:Complement()
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 2)
	local B        = OvaleTimeSpan(3, 4)
	local expected = OvaleTimeSpan(1, 2, 3, 4)

	local msg = { format("union of disjoint A%s and B%s, A before B", tostring(A), tostring(B)) }
	local result = A:Union(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(3, 4)
	local B        = OvaleTimeSpan(1, 2)
	local expected = OvaleTimeSpan(1, 2, 3, 4)

	local msg = { format("union of disjoint A%s and B%s, A after B", tostring(A), tostring(B)) }
	local result = A:Union(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 2, 3, 4)
	local B        = OvaleTimeSpan(2, 3, 4, 5)
	local expected = OvaleTimeSpan(1, 5)

	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	local result = A:Union(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(2, 3, 4, 5)
	local B        = OvaleTimeSpan(1, 2, 3, 4)
	local expected = OvaleTimeSpan(1, 5)

	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	local result = A:Union(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 2)
	local B        = OvaleTimeSpan(2, 3, 4, 5)
	local expected = OvaleTimeSpan(1, 3, 4, 5)

	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	local result = A:Union(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(2, 3, 4, 5)
	local B        = OvaleTimeSpan(1, 2)
	local expected = OvaleTimeSpan(1, 3, 4, 5)

	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	local result = A:Union(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(2, 3, 4, 5)
	local B        = OvaleTimeSpan(1, 4)
	local expected = OvaleTimeSpan(1, 5)

	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	local result = A:Union(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 5, 6, 10, 15, 17, 20, 30, 99, 101)
	local B        = OvaleTimeSpan(2, 3, 7, 11, 14, 18, 21, 29, 42, 47, 99, 101)
	local expected = OvaleTimeSpan(1, 5, 6, 11, 14, 18, 20, 30, 42, 47, 99, 101)

	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	local result = A:Union(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 5, 6, 10, 15, 17, 20, 30, 99, 101)
	local B        = OvaleTimeSpan(2, 3, 7, 11, 14, 18, 21, 29, 42, 47, 101, 105)
	local expected = OvaleTimeSpan(1, 5, 6, 11, 14, 18, 20, 30, 42, 47, 99, 105)

	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	local result = A:Union(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan()
	local B        = OvaleTimeSpan()
	local expected = OvaleTimeSpan()

	local msg = { "union of empty sets should be empty" }
	local result = A:Intersect(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 3)
	local B        = OvaleTimeSpan(2, 4)
	local expected = OvaleTimeSpan(2, 3)

	local msg = { format("intersection of %s and %s", tostring(A), tostring(B)) }
	local result = A:Intersect(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 3, 4, 6)
	local B        = OvaleTimeSpan(2, 5)
	local expected = OvaleTimeSpan(2, 3, 4, 5)

	local msg = { format("intersection of %s and %s", tostring(A), tostring(B)) }
	local result = A:Intersect(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 5, 6, 10, 15, 17, 20, 30, 99, 101)
	local B        = OvaleTimeSpan(2, 3, 7, 11, 14, 18, 21, 29, 42, 47, 99, 101)
	local expected = OvaleTimeSpan(2, 3, 7, 10, 15, 17, 21, 29, 99, 101)

	local msg = { format("intersection of %s and %s", tostring(A), tostring(B)) }
	local result = A:Intersect(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(2, math.huge)
	local B        = OvaleTimeSpan(3, math.huge)
	local expected = OvaleTimeSpan(3, math.huge)

	local msg = { format("intersection of %s and %s", tostring(A), tostring(B)) }
	local result = A:Intersect(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A            = OvaleTimeSpan(1, 3, 4, 6)
	local startB, endB = 2, 5
	local expected     = OvaleTimeSpan(2, 3, 4, 5)

	local msg = { format("intersect %s with interval (%s, %s)", tostring(A), tostring(startB), tostring(endB)) }
	local result = A:IntersectInterval(startB, endB)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 3, 4, 6)
	local B        = OvaleTimeSpan(3, math.huge)
	local expected = OvaleTimeSpan(4, 6)

	local msg = { format("intersection of %s and %s", tostring(A), tostring(B)) }
	local result = A:Intersect(B)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

tests[#tests + 1] = function()
	local A            = OvaleTimeSpan(1, 3, 4, 6)
	local startB, endB = 3, math.huge
	local expected     = OvaleTimeSpan(4, 6)

	local msg = { format("intersect %s with interval (%s, %s)", tostring(A), tostring(startB), tostring(endB)) }
	local result = A:IntersectInterval(startB, endB)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		return false, msg
	end
	return true, msg
end

-- Produce TAP output for unit tests.
do
	print(format("1..%d", #tests))
	for i, func in ipairs(tests) do
		local result, msg = func()
		local msgString = msg
		if type(msg) == "table" then
			msgString = tconcat(msg, "\n")
		end
		local resultString = result and "ok" or "not ok"
		print(format("%s %d - %s", resultString, i, msgString))
	end
end
