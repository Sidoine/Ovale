--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

--[[----------------------------------------------------------------------------
	Script conditions.

	A script condition must have a name that is lowercase.

	A script condition can return in two different ways:

	(1) start, ending
		This returns a time interval representing when the condition is true
		and is used by conditions that return only a time interval.

	(2) start, ending, value, origin, rate
		This returns a function f(t) = value + (t - origin) * rate that is
		valid for start < t < ending.  This return method is used by
		conditions that return a value that is used in numerical comparisons
		or operations.

	The endpoint of a time interval must be between 0 and infinity, where
	infinity is represented by math.huge.  Time is a value such as returned by
	the API function GetTime().

	Examples:

	(1)	(0, math.huge) means the condition is always true.

	(2)	nil is the empty set and means the condition is always false.

	(3)	(0, math.huge, constant, 0, 0) means the condition has a constant value.

	(4)	(start, ending, ending - start, start, -1) means the condition has a
		value of f(t) = ending - t, at time t between start and ending.  This
		basically returns how much time is left within the time interval.
--]]----------------------------------------------------------------------------

local _, Ovale = ...
local OvaleCondition = Ovale:NewModule("OvaleCondition")
Ovale.OvaleCondition = OvaleCondition

--<private-static-properties>
local type = type
local wipe = table.wipe

-- Table of script conditions.
self_condition = {}
-- List of script conditions that refer to a castable spell from the player's spellbook.
self_spellbookCondition = {}
do
	-- Spell(spellId) can be used as a condition instead of an action.
	self_spellbookCondition["spell"] = true
end
--</private-static-properties>

--<public-static-properties>
--[[
	The actual target referenced when the "target" parameter is used in a condition.
	This is to support setting a different target in an AddIcon "target" parameter,
	e.g., target=focus, while re-using the same script.
--]]
OvaleCondition.defaultTarget = "target"
OvaleCondition.Compare = nil
OvaleCondition.ParseCondition = nil
OvaleCondition.ParseRuneCondition = nil
OvaleCondition.TestBoolean = nil
OvaleCondition.TestValue = nil
--</public-static-properties>

--<public-static-methods>
function OvaleCondition:RegisterCondition(name, isSpellbookCondition, func, arg)
	if arg then
		if type(func) == "string" then
			func = arg[func]
		end
		self_condition[name] = function(...) func(arg, ...) end
	else
		self_condition[name] = func
	end
	if isSpellbookCondition then
		self_spellbookCondition[name] = true
	end
end

function OvaleCondition:UnregisterCondition(name)
	self_condition[name] = nil
end

function OvaleCondition:IsCondition(name)
	return (self_condition[name] ~= nil)
end

function OvaleCondition:IsSpellbookCondition(name)
	return (self_spellbookCondition[name] ~= nil)
end

function OvaleCondition:EvaluateCondition(name, ...)
	return self_condition[name](...)
end

OvaleCondition.ParseCondition = function(condition, defaultTarget)
	defaultTarget = defaultTarget or "player"
	local target = condition.target and condition.target or defaultTarget
	if target == "target" then
		target = OvaleCondition.defaultTarget
	end

	local filter
	if condition.filter then
		if condition.filter == "debuff" then
			filter = "HARMFUL"
		elseif condition.filter == "buff" then
			filter = "HELPFUL"
		end
	end

	local mine = true
	if condition.any and condition.any == 1 then
		mine = false
	else
		-- Legacy parameter "mine"; no longer documented.
		if not condition.any and condition.mine and condition.mine ~= 1 then
			mine = false
		end
	end

	return target, filter, mine
end

-- Returns whether "a" matches "yesno".
OvaleCondition.TestBoolean = function(a, yesno)
	if not yesno or yesno == "yes" then
		if a then
			return 0, math.huge
		end
	else
		if not a then
			return 0, math.huge
		end
	end
	return nil
end

-- Returns either an "Ovale value" or a boolean, depending on whether "comparator" is given.
-- An "Ovale value" is a quintuplet (start, ending, value, origin, rate) that determines a
-- linear function A(t) = value + (t - origin)*rate, with domain (start, ending).
OvaleCondition.TestValue = function(start, ending, value, origin, rate, comparator, limit)
	--[[
							 A(t) = limit
		value + (t - origin)*rate = limit
				(t - origin)*rate = limit - value
	--]]
	if not value or not origin or not rate then
		return nil
	end

	start = start and start or 0
	ending = (start and ending) and ending or math.huge

	if not comparator then
		if start < ending then
			return start, ending, value, origin, rate
		else
			return 0, math.huge, 0, 0, 0
		end
	elseif comparator ~= "atLeast" and comparator ~= "atMost" and comparator ~= "equal"
			and comparator ~= "less" and comparator ~= "more" then
		Ovale:Errorf("unknown compare term %s", comparator)
	elseif not limit then
		Ovale:Errorf("comparator %s missing limit", comparator)
	elseif rate == 0 then
		if (comparator == "less" and value < limit)
				or (comparator == "atMost" and value <= limit)
				or (comparator == "equal" and value == limit)
				or (comparator == "atLeast" and value >= limit)
				or (comparator == "more" and value > limit) then
			return start, ending
		end
	elseif (comparator == "less" and rate > 0)
			or (comparator == "atMost" and rate > 0)
			or (comparator == "atLeast" and rate < 0)
			or (comparator == "more" and rate < 0) then
		local t = (limit - value)/rate + origin
		ending = (ending < t) and ending or t
		return start, ending
	elseif (comparator == "less" and rate < 0)
			or (comparator == "atMost" and rate < 0)
			or (comparator == "atLeast" and rate > 0)
			or (comparator == "more" and rate > 0) then
		local t = (limit - value)/rate + origin
		start = (start > t) and start or t
		return start, math.huge
	end
	return nil
end

OvaleCondition.Compare = function(value, comparator, limit)
	return OvaleCondition.TestValue(0, math.huge, value, 0, 0, comparator, limit)
end
--</public-static-methods>
