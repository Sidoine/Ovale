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
	local OvaleEnemies = Ovale.OvaleEnemies

	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition

	--- Get the number of hostile enemies on the battlefield.
	-- @name Enemies
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param any Optional. By default, only enemies tagged by the player are counted. To count all enemies of the player's group, set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @return The number of enemies.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if Enemies() >4 Spell(fan_of_knives)
	-- if Enemies(more 4) Spell(fan_of_knives)

	local function Enemies(condition)
		local comparator, limit = condition[1], condition[2]
		local _, _, mine = ParseCondition(condition)
		local value
		if mine then
			value = OvaleEnemies.taggedEnemies
		else
			value = OvaleEnemies.activeEnemies
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("enemies", false, Enemies)
end
