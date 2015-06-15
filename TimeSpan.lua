--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

--[[
	Time spans are continuous open intervals (start, ending) that are subsets of (0, infinity).

	Infinity is represented by INFINITY.
	Point sets are considered empty.
	"nil" time spans are considered empty.

	This module supports the following operations on time spans:
		Complement
		Union (code kindly contributed by Qrux)
		Intersection
--]]

local OVALE, Ovale = ...
local OvaleTimeSpan = {}
Ovale.OvaleTimeSpan = OvaleTimeSpan

--<private-static-properties>
--local debugprint = print
local select = select
local setmetatable = setmetatable
local format = string.format
local tconcat = table.concat
local tinsert = table.insert
local tremove = table.remove
local type = type
local wipe = wipe
local INFINITY = math.huge

-- Pool of time-span tables.
local self_pool = {}
local self_poolSize = 0
local self_poolUnused = 0

local EMPTY_SET = setmetatable({}, OvaleTimeSpan)
local UNIVERSE = setmetatable({ 0, INFINITY }, OvaleTimeSpan)
--</private-static-properties>

--<public-static-properties>
OvaleTimeSpan.__index = OvaleTimeSpan
do
	-- Class constructor
	setmetatable(OvaleTimeSpan, { __call = function(self, ...) return self:New(...) end })
end

OvaleTimeSpan.EMPTY_SET = EMPTY_SET
OvaleTimeSpan.UNIVERSE = UNIVERSE
--</public-static-properties>

--<private-static-methods>
local function CompareIntervals(startA, endA, startB, endB)
	--debugprint(string.format("  comparing (%s, %s) with (%s, %s)", startA, endA, startB, endB))
	if startA == startB and endA == endB then
		-- same (0)
		return 0
	elseif startA < startB and endA >= startB and endA <= endB then
		-- overlap, A comes-before B (-1)
		return -1
	elseif startB < startA and endB >= startA and endB <= endA then
		-- overlap, B comes-before A (1)
		return 1
	elseif (startA == startB and endA > endB) or (startA < startB and endA == endB) or (startA < startB and endA > endB) then
		-- A contains B (-2)
		return -2
	elseif (startB == startA and endB > endA) or (startB < startA and endB == endA) or (startB < startA and endB > endA) then
		-- B contains A (3)
		return 2
	elseif endA <= startB then
		-- A before B (-3)
		return -3
	elseif endB <= startA then
		-- B before A (3)
		return 3
	end
	-- Fail; unreachable (99)
	return 99
end
--</private-static-methods>

--<public-static-methods>
function OvaleTimeSpan:New(...)
	local obj = tremove(self_pool)
	if obj then
		self_poolUnused = self_poolUnused - 1
	else
		obj = {}
		self_poolSize = self_poolSize + 1
	end
	setmetatable(obj, self)
	obj = OvaleTimeSpan.Copy(obj, ...)
	return obj
end

function OvaleTimeSpan:Release(...)
	local A = ...
	if A then
		local argc = select("#", ...)
		for i = 1, argc do
			A = select(i, ...)
			wipe(A)
			tinsert(self_pool, A)
		end
		self_poolUnused = self_poolUnused + argc
	else
		wipe(self)
		tinsert(self_pool, self)
		self_poolUnused = self_poolUnused + 1
	end
end

function OvaleTimeSpan:GetPoolInfo()
	return self_poolSize, self_poolUnused
end

function OvaleTimeSpan:__tostring()
	if #self == 0 then
		return "empty set"
	else
		return format("(%s)", tconcat(self, ", "))
	end
end

function OvaleTimeSpan:Copy(...)
	local A = ...
	local count = 0
	if type(A) == "table" then
		count = #A
		for i = 1, count do
			self[i] = A[i]
		end
	else
		count = select("#", ...)
		for i = 1, count do
			self[i] = select(i, ...)
		end
	end
	for i = count + 1, #self do
		self[i] = nil
	end
	return self
end

function OvaleTimeSpan:IsEmpty()
	return #self == 0
end

function OvaleTimeSpan:IsUniverse()
	return self[1] == 0 and self[2] == INFINITY
end

function OvaleTimeSpan:Equals(B)
	local A = self
	local countA = #A
	local countB = B and #B or 0

	if countA ~= countB then
		return false
	end
	for k = 1, countA do
		if A[k] ~= B[k] then
			return false
		end
	end
	return true
end

function OvaleTimeSpan:HasTime(atTime)
	local A = self
	for i = 1, #A, 2 do
		if A[i] <= atTime and atTime <= A[i+1] then
			return true
		end
	end
	return false
end

function OvaleTimeSpan:NextTime(atTime)
	local A = self
	for i = 1, #A, 2 do
		if atTime < A[i] then
			return A[i]
		elseif A[i] <= atTime and atTime <= A[i+1] then
			return atTime
		end
	end
end

function OvaleTimeSpan:Measure()
	local A = self
	local measure = 0
	for i = 1, #A, 2 do
		measure = measure + (A[i+1] - A[i])
	end
	return measure
end

function OvaleTimeSpan:Complement(result)
	local A = self
	local countA = #A

	if countA == 0 then
		if result then
			result:Copy(UNIVERSE)
		else
			result = OvaleTimeSpan:New(UNIVERSE)
		end
	else
		result = result or OvaleTimeSpan:New()
		local countResult = 0
		local i, k = 1, 1
		if A[i] == 0 then
			i = i + 1
		else
			result[k] = 0
			countResult = k
			k = k + 1
		end
		while i < countA do
			result[k] = A[i]
			countResult = k
			i, k = i + 1, k + 1
		end
		if A[i] < INFINITY then
			result[k], result[k+1] = A[i], INFINITY
			countResult = k + 1
		end
		for j = countResult + 1, #result do
			result[j] = nil
		end
	end
	return result
end

function OvaleTimeSpan:IntersectInterval(startB, endB, result)
	local A = self
	local countA = #A
	result = result or OvaleTimeSpan:New()

	if countA > 0 and startB and endB then
		local countResult = 0
		local i, k = 1, 1
		while true do
			if i > countA then
				break
			end

			local startA, endA = A[i], A[i+1]
			local compare = CompareIntervals(startA, endA, startB, endB)
			if compare == 0 then
				-- Same; output, exit.
				result[k], result[k+1] = startA, endA
				countResult = k + 1
				break
			elseif compare == -1 then
				-- Overlap; A comes before B, output, advance A.
				if endA > startB then
					result[k], result[k+1] = startB, endA
					countResult = k + 1
					i, k = i + 2, k + 2
				else
					i = i + 2
				end
			elseif compare == 1 then
				-- Overlap; B comes before A, output, exit.
				if endB > startA then
					result[k], result[k+1] = startA, endB
					countResult = k + 1
				end
				break
			elseif compare == -2 then
				-- A contains B; output, exist.
				result[k], result[k+1] = startB, endB
				countResult = k + 1
				break
			elseif compare == 2 then
				-- B contains A; output, advance A.
				result[k], result[k+1] = startA, endA
				countResult = k + 1
				i, k = i + 2, k + 2
			elseif compare == -3 then
				-- A before B
				i = i + 2
			elseif compare == 3 then
				-- B before A
				break
			end
		end
		for n = countResult + 1, #result do
			result[n] = nil
		end
	end
	return result
end

function OvaleTimeSpan:Intersect(B, result)
	local A = self
	local countA = #A
	local countB = B and #B or 0
	result = result or OvaleTimeSpan:New()

	local countResult = 0
	if countA > 0 and countB > 0 then
		local i, j, k = 1, 1, 1
		while true do
			if i > countA or j > countB then
				break
			end

			local startA, endA = A[i], A[i+1]
			local startB, endB = B[j], B[j+1]

			--debugprint(string.format("      A: (%s, %s)", tostring(startA), tostring(endA)))
			--debugprint(string.format("      B: (%s, %s)", tostring(startB), tostring(endB)))

			local compare = CompareIntervals(startA, endA, startB, endB)
			--debugprint("  overlap?", compare)
			if compare == 0 then
				-- Same; output, advance both.
				result[k], result[k+1] = startA, endA
				countResult = k + 1
				i, j, k = i + 2, j + 2, k + 2
				--debugprint("         ADV(A)")
				--debugprint("         ADV(B)")
			elseif compare == -1 then
				-- Overlap; A comes before B, output, advance A.
				if endA > startB then
					result[k], result[k+1] = startB, endA
					countResult = k + 1
					i, k = i + 2, k + 2
				else
					i = i + 2
				end
				--debugprint("         ADV(A)")
			elseif compare == 1 then
				-- Overlap; B comes before A, output, advance B.
				if endB > startA then
					result[k], result[k+1] = startA, endB
					countResult = k + 1
					j, k = j + 2, k + 2
				else
					j = j + 2
				end
				--debugprint("         ADV(B)")
			elseif compare == -2 then
				-- A contains B; output, advance B.
				result[k], result[k+1] = startB, endB
				countResult = k + 1
				j, k = j + 2, k + 2
				--debugprint("         ADV(B)")
			elseif compare == 2 then
				-- B contains A; output, advance A.
				result[k], result[k+1] = startA, endA
				countResult = k + 1
				i, k = i + 2, k + 2
				--debugprint("         ADV(A)")
			elseif compare == -3 then
				-- A before B
				i = i + 2
				--debugprint("         ADV(A)")
			elseif compare == 3 then
				-- B before A
				j = j + 2
				--debugprint("         ADV(B)")
			else
			--debugprint("WTF--can't happen; ABORT NAO!")
				i = i + 2
				j = j + 2
			end
		end
	end
	for n = countResult + 1, #result do
		result[n] = nil
	end
	return result
end

function OvaleTimeSpan:Union(B, result)
	local A = self
	local countA = #A
	local countB = B and #B or 0

	if countA == 0 then
		if B then
			if result then
				result:Copy(B)
			else
				result = OvaleTimeSpan:New(B)
			end
		end
	elseif countB == 0 then
		if result then
			result:Copy(A)
		else
			result = OvaleTimeSpan:New(A)
		end
	else
		result = result or OvaleTimeSpan:New()
		local countResult = 0
		local i, j, k = 1, 1, 1

		local startTemp, endTemp = A[i], A[i+1]

		local holdingA = true
		local scanningA = false

		while true do
			local startA, endA, startB, endB

			if i > countA and j > countB then
				-- Write the final temp to output.
				result[k], result[k+1] = startTemp, endTemp
				countResult = k + 1
				k = k + 2
				break
			end
			if scanningA and i > countA then
				-- Past the end of A; Flip-scan; Flip-hold.
				holdingA = not holdingA
				scanningA = not scanningA
			else
				-- Normal; not past the end of A.
				startA, endA = A[i], A[i+1]
			end
			if not scanningA and j > countB then
				-- Past the end of B; Flip-scan; Flip-hold.
				holdingA = not holdingA
				scanningA = not scanningA
			else
				-- Normal; not past the end of B.
				startB, endB = B[j], B[j+1]
			end

			local startCurrent = scanningA and startA or startB
			local endCurrent = scanningA and endA or endB

			--debugprint(string.format("   temp: (%s, %s)", tostring(startTemp), tostring(endTemp)))
			--debugprint(string.format("      A: (%s, %s)", tostring(startA), tostring(endA)))
			--debugprint(string.format("      B: (%s, %s)", tostring(startB), tostring(endB)))
			--debugprint(string.format("current: (%s, %s)", tostring(startCurrent), tostring(endCurrent)))
			--debugprint("         holdA", holdingA)
			--debugprint("         scanA", scanningA)

			--[[
				Comparing pairs (temp, current):

				 0 is (2, 3) - (2, 3) (temp    equals        current) - Advance-scan.
				-2 is (1, 5) - (2, 4) (temp    contains      current) - Advance-scan.

				-1 is (1, 3) - (2, 5) (temp    starts-before current) - Update temp-end (to cur2); advance-scan.
				 1 is (2, 5) - (1, 3) (current starts-before temp   ) - Update temp-start (to cur1); advance-scan.

				 2 is (1, 5) - (2, 4) (current contains      temp   ) - Reset-temp (to cur); Flip-scan; Flip-hold.

				-3 is (1, 2) - (3, 4) (temp    is-before     current) - Flip-scan; advance-cur.
				 3 is (3, 4) - (1, 2) (current is-before     temp   ) - Reset-temp (to cur); Flip-scan; Flip-hold.
			--]]

			local compare = CompareIntervals(startTemp, endTemp, startCurrent, endCurrent)
			--debugprint("  overlap?", compare)
			if compare == 0 then
				-- Skip.
				if scanningA then i = i + 2 else j = j + 2 end
			elseif compare == -2 then
				-- Simplest cases; advance input-currently-being-scanned.
				if scanningA then i = i + 2 else j = j + 2 end
			elseif compare == -1 then
				-- Update temp-END, advance.
				endTemp = endCurrent
				if scanningA then i = i + 2 else j = j + 2 end
			elseif compare == 1 then
				-- update temp-START, advance.
				startTemp = startCurrent
				if scanningA then i = i + 2 else j = j + 2 end
			elseif compare == 2 then
				-- We need to flip the side we're scanning (and holding), because the other side contains this side.
				startTemp, endTemp = startCurrent, endCurrent
				holdingA = not holdingA
				scanningA = not scanningA
				if scanningA then i = i + 2 else j = j + 2 end
			elseif compare == -3 then
				-- This (and 3) are the only situations where we capture the output.
				--debugprint("    (-3) holdA", holdingA)
				--debugprint("    (-3) scanA", scanningA)
				if holdingA == scanningA then
					result[k], result[k+1] = startTemp, endTemp
					countResult = k + 1
					startTemp, endTemp = startCurrent, endCurrent
					scanningA = not scanningA
					k = k + 2
				else
					scanningA = not scanningA
					if scanningA then
						i = i + 2
						--debugprint("         ADV(A)")
					else
						j = j + 2
						--debugprint("         ADV(B)")
					end
				end
			elseif compare == 3 then
				-- This (and -3) are the only situations where we capture the output.
				startTemp, endTemp = startCurrent, endCurrent
				holdingA = not holdingA
				scanningA = not scanningA
			else
				--debugprint("WTF--can't happen; ABORT NAO!")
				i = i + 2
				j = j + 2
			end
		end
		for n = countResult + 1, #result do
			result[n] = nil
		end
	end
	return result
end
--</public-static-methods>
