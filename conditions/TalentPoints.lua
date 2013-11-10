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
	local OvaleSpellBook = Ovale.OvaleSpellBook

	local Compare = OvaleCondition.Compare

	--- Get the number of points spent in a talent (0 or 1)
	-- @name TalentPoints
	-- @paramsig number or boolean
	-- @param talent Talent to inspect.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of talent points.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if TalentPoints(blood_tap_talent) Spell(blood_tap)

	local function TalentPoints(condition)
		local talent, comparator, limit = condition[1], condition[2], condition[3]
		local value = OvaleSpellBook:GetTalentPoints(talent)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("talentpoints", false, TalentPoints)
end