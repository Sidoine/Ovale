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
	local OvaleDamage = Ovale.OvaleDamage

	local Compare = OvaleCondition.Compare

	--- Get the damage taken by the player in the previous time interval.
	-- @name DamageTaken
	-- @paramsig number or boolean
	-- @param interval The number of seconds before now.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of damage taken in the previous interval.
	-- @return A boolean value for the result of the comparison.
	-- @see IncomingDamage
	-- @usage
	-- if DamageTaken(5) > 50000 Spell(death_strike)

	local function DamageTaken(condition)
		-- Damage taken shouldn't be smoothed since spike damage is important data.
		-- Just present damage taken as a constant value.
		local interval, comparator, limit = condition[1], condition[2], condition[3]
		local value = 0
		if interval > 0 then
			value = OvaleDamageTaken:GetRecentDamage(interval)
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("damagetaken", false, DamageTaken)
	OvaleCondition:RegisterCondition("incomingdamage", false, DamageTaken)
end
