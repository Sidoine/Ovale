--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013, 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleCondition = Ovale.OvaleCondition
	local OvaleState = Ovale.OvaleState

	local Compare = OvaleCondition.Compare
	local TestValue = OvaleCondition.TestValue
	local state = OvaleState.state

	--- Get the cooldown in seconds on a spell before it gains another charge.
	-- @name SpellChargeCooldown
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see SpellCharges
	-- @usage
	-- if SpellChargeCooldown(roll) <2
	--     Spell(roll usable=1)

	local function SpellChargeCooldown(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local charges, maxCharges, start, duration = state:GetSpellCharges(spellId)
		if charges and charges < maxCharges then
			return TestValue(start, start + duration, duration, start, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("spellchargecooldown", true, SpellChargeCooldown)
end