--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleCondition = Ovale.OvaleCondition
	local OvaleLatency = Ovale.OvaleLatency

	local Compare = OvaleCondition.Compare

	--- Get the most recent estimate of roundtrip latency in milliseconds.
	-- @name Latency
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number of milliseconds to compare against.
	-- @return The most recent estimate of latency.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Latency() >1000 Spell(sinister_strike)
	-- if Latency(more 1000) Spell(sinister_strike)

	local function Latency(condition)
		local comparator, limit = condition[1], condition[2]
		local value = OvaleLatency:GetLatency() * 1000
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("latency", false, Latency)
end