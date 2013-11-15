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

	local ParseCondition = OvaleCondition.ParseCondition
	local TestValue = OvaleCondition.TestValue

	local auraFound = {}

	--- Get the number of seconds until the next tick of a periodic aura on the target.
	-- @name NextTick
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param filter Optional. The type of aura to check.
	--     Default is any.
	--     Valid values: any, buff, debuff
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see Ticks, TicksRemain, TickTime

	local function NextTick(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local state = OvaleState.state
		auraFound.tick = nil
		local start, ending = state:GetAura(target, auraId, filter, mine, auraFound)
		local tick = auraFound.tick
		if ending and ending < math.huge and tick then
			while ending - tick > state.currentTime do
				ending = ending - tick
			end
			return TestValue(0, ending, 0, ending, -1, comparator, limit)
		end
		return nil
	end

	OvaleCondition:RegisterCondition("nexttick", false, NextTick)
end