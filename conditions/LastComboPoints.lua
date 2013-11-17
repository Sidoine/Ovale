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
	local OvaleGUID = Ovale.OvaleGUID
	local OvaleFuture = Ovale.OvaleFuture

	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition

	--- Get the number of combo points consumed by the most recent cast of a spell on the target for a feral druid or a rogue.
	-- @name LastComboPoints
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The number of combo points.
	-- @return A boolean value for the result of the comparison.
	-- @see ComboPoints
	-- @usage
	-- if ComboPoints() >3 and target.LastComboPoints(rip) <3
	--     Spell(rip)

	local function LastComboPoints(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local target = ParseCondition(condition, "target")
		local guid = OvaleGUID:GetGUID(target)
		local value = OvaleFuture:GetLastSpellInfo(guid, spellId, "combo") or 0
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("lastcombopoints", false, LastComboPoints)
	OvaleCondition:RegisterCondition("lastspellcombopoints", false, LastComboPoints)
end
