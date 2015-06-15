-- Create WoWMock sandbox.
local root = "../"
dofile(root .. "WoWMock.lua")
local sandbox = WoWMock:NewSandbox()

-- Load addon files into the sandbox.
local function Setup()
	-- Declare a globally-accessible "Ovale" addon table.
	Ovale = {}
end
sandbox:Execute(Setup)
sandbox:LoadAddonFile("TimeSpan.lua", root)

-- Enter sandbox.
setfenv(1, sandbox)

local OvaleTimeSpan = Ovale.OvaleTimeSpan
local format = string.format
local tinsert = table.insert
local tconcat = table.concat
local INFINITY = math.huge
local EMPTY_SET = OvaleTimeSpan.EMPTY_SET
local UNIVERSE = OvaleTimeSpan.UNIVERSE

local tests = {}

tests[#tests + 1] = function()
	local A = OvaleTimeSpan(UNIVERSE)

	local boolean = true
	local msg = format("%s is the universe", tostring(A))
	if not A:IsUniverse() then
		boolean = false
	end

	A:Release()
	return boolean, msg
end

tests[#tests + 1] = function()
	local A = OvaleTimeSpan(1, INFINITY)

	local boolean = true
	local msg = format("%s is not the universe", tostring(A))
	if A:IsUniverse() then
		boolean = false
	end

	A:Release()
	return boolean, msg
end

tests[#tests + 1] = function()
	local A = OvaleTimeSpan(1, 2, 3, 4)
	local atTime = 0

	local boolean = true
	local msg = format("%s should not contain %s", tostring(A), tostring(atTime))
	if A:HasTime(atTime) then
		boolean = false
	end

	A:Release()
	return boolean, msg
end

tests[#tests + 1] = function()
	local A = OvaleTimeSpan(1, 2, 3, 4)
	local atTime = 1

	local boolean = true
	local msg = format("%s should contain %s", tostring(A), tostring(atTime))
	if not A:HasTime(atTime) then
		boolean = false
	end

	A:Release()
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 2)
	local expected = OvaleTimeSpan(1, 2)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("overwrite %s with %s", tostring(result), tostring(A)) }
	result:Copy(A)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
	end

	OvaleTimeSpan:Release(A, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 2, 3, 4)
	local expected = OvaleTimeSpan(1, 2, 3, 4)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("overwrite %s with %s", tostring(result), tostring(A)) }
	result:Copy(A)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
	end

	OvaleTimeSpan:Release(A, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local expected = OvaleTimeSpan(0, INFINITY)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("overwrite %s with %s", tostring(result), tostring(expected)) }
	result:Copy(expected[1], expected[2])
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
	end

	OvaleTimeSpan:Release(expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 2, 3, 4)
	local expected = OvaleTimeSpan(0, 1, 2, 3, 4, math.huge)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("complement of %s", tostring(A)) }
	A:Complement(result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
	end

	OvaleTimeSpan:Release(A, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan()
	local expected = OvaleTimeSpan(0, math.huge)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { "complement of empty set should be the universe" }
	A:Complement(result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
	end

	OvaleTimeSpan:Release(A, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(0, math.huge)
	local expected = OvaleTimeSpan()
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { "complement of the universe should be the empty set" }
	A:Complement(result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 2)
	local B        = OvaleTimeSpan(3, 4)
	local expected = OvaleTimeSpan(1, 2, 3, 4)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("union of disjoint A%s and B%s, A before B", tostring(A), tostring(B)) }
	A:Union(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(3, 4)
	local B        = OvaleTimeSpan(1, 2)
	local expected = OvaleTimeSpan(1, 2, 3, 4)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("union of disjoint A%s and B%s, A after B", tostring(A), tostring(B)) }
	A:Union(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 2, 3, 4)
	local B        = OvaleTimeSpan(2, 3, 4, 5)
	local expected = OvaleTimeSpan(1, 5)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	A:Union(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(2, 3, 4, 5)
	local B        = OvaleTimeSpan(1, 2, 3, 4)
	local expected = OvaleTimeSpan(1, 5)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	A:Union(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 2)
	local B        = OvaleTimeSpan(2, 3, 4, 5)
	local expected = OvaleTimeSpan(1, 3, 4, 5)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	A:Union(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(2, 3, 4, 5)
	local B        = OvaleTimeSpan(1, 2)
	local expected = OvaleTimeSpan(1, 3, 4, 5)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	A:Union(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(2, 3, 4, 5)
	local B        = OvaleTimeSpan(1, 4)
	local expected = OvaleTimeSpan(1, 5)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	A:Union(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 5, 6, 10, 15, 17, 20, 30, 99, 101)
	local B        = OvaleTimeSpan(2, 3, 7, 11, 14, 18, 21, 29, 42, 47, 99, 101)
	local expected = OvaleTimeSpan(1, 5, 6, 11, 14, 18, 20, 30, 42, 47, 99, 101)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	A:Union(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 5, 6, 10, 15, 17, 20, 30, 99, 101)
	local B        = OvaleTimeSpan(2, 3, 7, 11, 14, 18, 21, 29, 42, 47, 101, 105)
	local expected = OvaleTimeSpan(1, 5, 6, 11, 14, 18, 20, 30, 42, 47, 99, 105)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("union of %s and %s", tostring(A), tostring(B)) }
	A:Union(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan()
	local B        = OvaleTimeSpan()
	local expected = OvaleTimeSpan()
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { "union of empty sets should be empty" }
	A:Intersect(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 3)
	local expected = EMPTY_SET
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("intersection of %s and %s", tostring(A), tostring(EMPTY_SET)) }
	A:Intersect(EMPTY_SET, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 3)
	local B        = OvaleTimeSpan(2, 4)
	local expected = OvaleTimeSpan(2, 3)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("intersection of %s and %s", tostring(A), tostring(B)) }
	A:Intersect(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 3, 4, 6)
	local B        = OvaleTimeSpan(2, 5)
	local expected = OvaleTimeSpan(2, 3, 4, 5)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("intersection of %s and %s", tostring(A), tostring(B)) }
	A:Intersect(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 5, 6, 10, 15, 17, 20, 30, 99, 101)
	local B        = OvaleTimeSpan(2, 3, 7, 11, 14, 18, 21, 29, 42, 47, 99, 101)
	local expected = OvaleTimeSpan(2, 3, 7, 10, 15, 17, 21, 29, 99, 101)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("intersection of %s and %s", tostring(A), tostring(B)) }
	A:Intersect(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(2, math.huge)
	local B        = OvaleTimeSpan(3, math.huge)
	local expected = OvaleTimeSpan(3, math.huge)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("intersection of %s and %s", tostring(A), tostring(B)) }
	A:Intersect(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A            = OvaleTimeSpan(1, 3, 4, 6)
	local startB, endB = 2, 5
	local expected     = OvaleTimeSpan(2, 3, 4, 5)
	local result       = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("intersect %s with interval (%s, %s)", tostring(A), tostring(startB), tostring(endB)) }
	A:IntersectInterval(startB, endB, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A        = OvaleTimeSpan(1, 3, 4, 6)
	local B        = OvaleTimeSpan(3, math.huge)
	local expected = OvaleTimeSpan(4, 6)
	local result   = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("intersection of %s and %s", tostring(A), tostring(B)) }
	A:Intersect(B, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, B, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local A            = OvaleTimeSpan(1, 3, 4, 6)
	local startB, endB = 3, math.huge
	local expected     = OvaleTimeSpan(4, 6)
	local result       = OvaleTimeSpan(10, 20, 30, 40)

	local boolean = true
	local msg = { format("intersect %s with interval (%s, %s)", tostring(A), tostring(startB), tostring(endB)) }
	A:IntersectInterval(startB, endB, result)
	if not result:Equals(expected) then
		tinsert(msg, format("#   result: %s", tostring(result)))
		tinsert(msg, format("# expected: %s", tostring(expected)))
		boolean = false
	end

	OvaleTimeSpan:Release(A, expected, result)
	return boolean, msg
end

tests[#tests + 1] = function()
	local boolean = true
	local size, unused = OvaleTimeSpan:GetPoolInfo()
	local msg = { format("pool has size %d with %d unused tables", size, unused) }
	local result = unused - size
	if result ~= 0 then
		boolean = false
	end
	return boolean, msg
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
