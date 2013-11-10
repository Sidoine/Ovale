--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleCondition = Ovale.OvaleCondition
	local OvalePaperDoll = Ovale.OvalePaperDoll

	local API_UnitLevel = UnitLevel
	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition

	--- Get the result of the target's level minus the player's level. This number may be negative.
	-- @name RelativeLevel
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The difference in levels.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if target.RelativeLevel() >3
	--     Texture(ability_rogue_sprint)
	-- if target.RelativeLevel(more 3)
	--     Texture(ability_rogue_sprint)

	local function RelativeLevel(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local value, level
		if target == "player" then
			level = OvalePaperDoll.level
		else
			level = API_UnitLevel(target)
		end
		if level < 0 then
			-- World boss, so treat it as three levels higher.
			value = 3
		else
			value = level - OvalePaperDoll.level
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("relativelevel", false, RelativeLevel)
end