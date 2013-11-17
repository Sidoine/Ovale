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

	--- Get the time scaled by the specified haste type, defaulting to spell haste.
	--- For example, if a DoT normally ticks every 3 seconds and is scaled by spell haste, then it ticks every TimeWithHaste(3 haste=spell) seconds.
	-- @name TimeWithHaste
	-- @paramsig number or boolean
	-- @param time The time in seconds.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param haste Optional. Sets whether "time" should be lengthened or shortened due to haste.
	--     Defaults to haste=spell.
	--     Valid values: melee, spell.
	-- @return The time in seconds scaled by haste.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if target.DebuffRemains(flame_shock) < TimeWithHaste(3)
	--     Spell(flame_shock)

	local function TimeWithHaste(condition)
		local seconds, comparator, limit = condition[1], condition[2], condition[3]
		local haste = condition.haste or "spell"
		local state = OvaleState.state
		seconds = seconds or 0
		local value = seconds
		if haste == "spell" then
			value = seconds / state:GetSpellHasteMultiplier()
		elseif haste == "melee" then
			value = seconds / state:GetMeleeHasteMultiplier()
		else
			Ovale:Logf("Unknown haste parameter haste=%s", haste)
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timewithhaste", false, TimeWithHaste)
end