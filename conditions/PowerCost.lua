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
	local state = OvaleState.state

	-- Return the amount of power of the given power type required to cast the given spell.
	local function PowerCost(powerType, condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local value = state:PowerCost(spellId, powerType) or 0
		return Compare(value, comparator, limit)
	end

	--- Get the amount of energy required to cast the given spell.
	-- This returns zero for spells that use either mana or another resource based on stance/specialization, e.g., Monk's Jab.
	-- @name EnergyCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of energy.
	-- @return A boolean value for the result of the comparison.

	local function EnergyCost(condition)
		return PowerCost("energy", condition)
	end

	--- Get the amount of focus required to cast the given spell.
	-- @name FocusCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of focus.
	-- @return A boolean value for the result of the comparison.

	local function FocusCost(condition)
		return PowerCost("focus", condition)
	end

	--- Get the amount of mana required to cast the given spell.
	-- This returns zero for spells that use either mana or another resource based on stance/specialization, e.g., Monk's Jab.
	-- @name ManaCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of mana.
	-- @return A boolean value for the result of the comparison.

	local function ManaCost(condition)
		return PowerCost("mana", condition)
	end

	--- Get the amount of rage required to cast the given spell.
	-- @name RageCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of rage.
	-- @return A boolean value for the result of the comparison.

	local function RageCost(condition)
		return PowerCost("rage", condition)
	end

	--- Get the amount of runic power required to cast the given spell.
	-- @name RunicPowerCost
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of runic power.
	-- @return A boolean value for the result of the comparison.

	local function RunicPowerCost(condition)
		return PowerCost("runicpower", condition)
	end

	OvaleCondition:RegisterCondition("energycost", true, EnergyCost)
	OvaleCondition:RegisterCondition("focuscost", true, FocusCost)
	OvaleCondition:RegisterCondition("manacost", true, ManaCost)
	OvaleCondition:RegisterCondition("ragecost", true, RageCost)
	OvaleCondition:RegisterCondition("runicpowercost", true, RunicPowerCost)
end
