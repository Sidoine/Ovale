--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

--[[
	Time spans are continuous open intervals (start, ending) that are subsets of (0, infinity).

	Infinity is represented by math.huge.
	Point sets are considered empty.
	"nil" time spans are considered empty.
--]]

local _, Ovale = ...
local OvaleTimeSpan = {}
Ovale.OvaleTimeSpan = OvaleTimeSpan

--<public-static-methods>
function OvaleTimeSpan.Complement(startA, endA, atTime)
	--[[
		The complement of an interval is as follows:

			COMPLEMENT{} = (0, math.huge)
			COMPLEMENT(0, math.huge) = {}
			COMPLEMENT(a, b) = (0, a) UNION (b, math.huge)

		In the second case, it is the union of two intervals.  If the point of interest (atTime)
		lies in the left interval, then return it.  Otherwise, return the right interval.
	--]]
	if not startA or not endA then
		return 0, math.huge
	elseif startA == 0 and endA == math.huge then
		return nil
	elseif 0 <= atTime and atTime < startA then
		return 0, startA
	else
		return endA, math.huge
	end
end

function OvaleTimeSpan.HasTime(start, ending, atTime)
	if not start or not ending then
		return nil
	else
		return start <= atTime and atTime <= ending
	end
end

function OvaleTimeSpan.Intersect(startA, endA, startB, endB)
	-- If either (startA, endA) or (startB, endB) are the empty set, then return the empty set.
	if not startA or not endA or not startB or not endB then
		return nil
	end
	-- Swap around so that (startA, endA) comes "before" (startB, endB).
	if startA > startB then
		startA, startB = startB, startA
		endA, endB = endB, endA
	end
	-- If the two time spans don't overlap, then return the empty set.
	-- Otherwise, the take leftmost right endpoint.
	if endA <= startB then
		return nil
	elseif endB < endA then
		return startB, endB
	else
		return startB, endA
	end
end

function OvaleTimeSpan.Measure(startA, endA)
	if not startA or not endA then
		return 0
	elseif startA >= endA then
		return 0
	else
		return endA - startA
	end
end

function OvaleTimeSpan.Union(startA, endA, startB, endB)
	-- TODO: this assumes that (startA, endA) and (startB, endB) overlap.
	-- If either (startA, endA) or (startB, endB) are the empty set, then return the other time span.
	if not startA or not endA then
		return startB, endB
	elseif not startB or not endB then
		return startA, endA
	end
	-- Swap around so that (startA, endA) comes "before" (startB, endB).
	if startA > startB then
		startA, startB = startB, startA
		endA, endB = endB, endA
	end
	-- Take the rightmost right endpoint.
	if endA > endB then
		return startA, endA
	else
		return startA, endB
	end
end
--</public-static-methods>
