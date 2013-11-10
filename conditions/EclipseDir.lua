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

	--- Get the current direction of the Eclipse status on the Eclipse bar for balance druids.
	-- A negative number means heading toward Lunar Eclipse.
	-- A positive number means heading toward Solar Eclipse.
	-- Zero means it can head in either direction.
	-- @name EclipseDir
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The current direction.
	-- @return A boolean value for the result of the comparison.
	-- @see Eclipse
	-- @usage
	-- if Eclipse() < 0-70 and EclipseDir() <0 Spell(wrath)
	-- if Eclipse(less -70) and EclipseDir(less 0) Spell(wrath)

	local function EclipseDir(condition)
		local comparator, limit = condition[1], condition[2]
		local value = OvaleState.state.eclipseDirection
		return Compare(value, comparator, limit)		
	end

	OvaleCondition:RegisterCondition("eclipsedir", false, EclipseDir)
end
