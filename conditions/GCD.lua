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
	local OvaleState = Ovale.OvaleState

	local Compare = OvaleCondition.Compare

	--- Get the player's global cooldown in seconds.
	-- @name GCD
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if GCD() <1.1 Spell(frostfire_bolt)
	-- if GCD(less 1.1) Spell(frostfire_bolt)

	local function GCD(condition)
		local comparator, limit = condition[1], condition[2]
		local value = OvaleState.gcd
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("gcd", false, GCD)
end
