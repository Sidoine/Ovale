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
	local OvaleState = Ovale.OvaleState

	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition
	local TestValue = OvaleCondition.TestValue
	local state = OvaleState.state

	--- Get the remaining number of ticks of a periodic aura on a target.
	-- @name TicksRemaining
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
	-- @return The number of ticks.
	-- @return A boolean value for the result of the comparison.
	-- @see NextTick, Ticks, TickTime
	-- @usage
	-- if target.TicksRemaining(shadow_word_pain) <2
	--     Spell(shadow_word_pain)

	local function TicksRemaining(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain, start, ending, tick = aura.gain, aura.start, aura.ending, aura.tick
			if tick and tick > 0 then
				return TestValue(gain, math.huge, 1, ending, -1/tick, comparator, limit)
			end
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("ticksremaining", false, TicksRemaining)
	OvaleCondition:RegisterCondition("ticksremain", false, TicksRemaining)
end