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

	local floor = math.floor
	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition

	local auraFound = {}

	--- Get the total number of ticks of a periodic aura.
	-- @name Ticks
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of ticks.
	-- @return A boolean value for the result of the comparison.
	-- @see NextTick, TicksRemain, TickTime

	local function Ticks(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		auraFound.tick = nil
		local start, ending = OvaleState:GetAura(target, auraId, filter, mine, auraFound)
		local tick = auraFound.tick
		local duration, numTicks
		if start then
			-- Aura exists on the target
			if ending and tick and tick > 0 then
				duration = ending - start
				numTicks = floor(duration / tick + 0.5)
			end
		else
			duration, tick, numTicks = OvaleState:GetDuration(auraId)
		end
		if numTicks then
			return Compare(numTicks, comparator, limit)
		end
		return nil
	end

	OvaleCondition:RegisterCondition("ticks", false, Ticks)
end