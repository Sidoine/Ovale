--[[--------------------------------------------------------------------
    Copyright (C) 2012, 2013 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
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
	infinity is represented by INFINITY (math.huge).  Time is a value such as
	returned by the API function GetTime().

	Examples:

	(1)	(0, INFINITY) means the condition is always true.

	(2)	nil is the empty set and means the condition is always false.

	(3)	(0, INFINITY, constant, 0, 0) means the condition has a constant value.

	(4)	(start, ending, ending - start, start, -1) means the condition has a
		value of f(t) = ending - t, at time t between start and ending.  This
		basically returns how much time is left within the time interval.
--]]----------------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleCondition = Ovale:NewModule("OvaleCondition")
Ovale.OvaleCondition = OvaleCondition

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleState = nil

local type = type
local wipe = wipe
local INFINITY = math.huge

-- Table of script conditions.
local self_condition = {}
-- List of script conditions that refer to a castable spell from the player's spellbook.
local self_spellBookCondition = {}
do
	-- Spell(spellId) can be used as a condition instead of an action.
	self_spellBookCondition["spell"] = true
end
--</private-static-properties>

--<public-static-properties>
OvaleCondition.Compare = nil
OvaleCondition.ParseCondition = nil
OvaleCondition.ParseRuneCondition = nil
OvaleCondition.TestBoolean = nil
OvaleCondition.TestValue = nil

OvaleCondition.COMPARATOR = {
	atLeast = true,
	atMost = true,
	equal = true,
	less = true,
	more = true,
}
--</public-static-properties>

--<public-static-methods>
function OvaleCondition:OnInitialize()
	-- Resolve module dependencies.
	OvaleState = Ovale.OvaleState
end

function OvaleCondition:OnEnable()
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvaleCondition:OnDisable()
	OvaleState:UnregisterState(self)
end

function OvaleCondition:RegisterCondition(name, isSpellBookCondition, func, arg)
	if arg then
		if type(func) == "string" then
			func = arg[func]
		end
		self_condition[name] = function(...) func(arg, ...) end
	else
		self_condition[name] = func
	end
	if isSpellBookCondition then
		self_spellBookCondition[name] = true
	end
end

function OvaleCondition:UnregisterCondition(name)
	self_condition[name] = nil
end

function OvaleCondition:IsCondition(name)
	return (self_condition[name] ~= nil)
end

function OvaleCondition:IsSpellBookCondition(name)
	return (self_spellBookCondition[name] ~= nil)
end

function OvaleCondition:EvaluateCondition(name, positionalParams, namedParams, state, atTime)
	return self_condition[name](positionalParams, namedParams, state, atTime)
end

OvaleCondition.ParseCondition = function(positionalParams, namedParams, state, defaultTarget)
	local target = namedParams.target or defaultTarget or "player"
	-- Side-effect: set namedParams.target to the correct value if not present.
	namedParams.target = namedParams.target or target
	if target == "target" then
		target = state.defaultTarget
	end

	local filter
	if namedParams.filter then
		if namedParams.filter == "debuff" then
			filter = "HARMFUL"
		elseif namedParams.filter == "buff" then
			filter = "HELPFUL"
		end
	end

	local mine = true
	if namedParams.any and namedParams.any == 1 then
		mine = false
	else
		-- Legacy parameter "mine"; no longer documented.
		if not namedParams.any and namedParams.mine and namedParams.mine ~= 1 then
			mine = false
		end
	end

	return target, filter, mine
end

-- Returns whether "a" matches "yesno".
OvaleCondition.TestBoolean = function(a, yesno)
	if not yesno or yesno == "yes" then
		if a then
			return 0, INFINITY
		end
	else
		if not a then
			return 0, INFINITY
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

	start = start or 0
	ending = ending or INFINITY

	if not comparator then
		if start < ending then
			return start, ending, value, origin, rate
		else
			return 0, INFINITY, 0, 0, 0
		end
	elseif not OvaleCondition.COMPARATOR[comparator] then
		OvaleCondition:Error("unknown comparator %s", comparator)
	elseif not limit then
		OvaleCondition:Error("comparator %s missing limit", comparator)
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
		return start, INFINITY
	end
	return nil
end

OvaleCondition.Compare = function(value, comparator, limit)
	return OvaleCondition.TestValue(0, INFINITY, value, 0, 0, comparator, limit)
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleCondition.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleCondition.statePrototype
--</private-static-properties>

--<state-properties>
--[[
	The default target referenced when the "target" parameter is used in a condition.
	This is to support setting a different target in an AddIcon "target" parameter,
	e.g., target=focus, while re-using the same script.
--]]
statePrototype.defaultTarget = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleCondition:InitializeState(state)
	state.defaultTarget = "target"
end

-- Release state resources prior to removing from the simulator.
function OvaleCondition:CleanState(state)
	state.defaultTarget = nil
end
--</public-static-methods>

