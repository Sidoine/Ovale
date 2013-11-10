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

	--- Get the current amount of Eclipse power for balance druids.
	-- A negative amount of power signifies being closer to Lunar Eclipse.
	-- A positive amount of power signifies being closer to Solar Eclipse.
	-- @name Eclipse
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The amount of Eclipse power.
	-- @return A boolean value for the result of the comparison.
	-- @see EclipseDir
	-- @usage
	-- if Eclipse() < 0-70 and EclipseDir() <0 Spell(wrath)
	-- if Eclipse(less -70) and EclipseDir(less 0) Spell(wrath)

	local function Eclipse(condition)
		local comparator, limit = condition[1], condition[2]
		local state = OvaleState.state
		local value = state.eclipse
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("eclipse", false, Eclipse)
end
