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
	local OvaleData = Ovale.OvaleData
	local OvaleState = Ovale.OvaleState

	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition
	local state = OvaleState.state

	--- Get the number of seconds between ticks of a periodic aura on a target.
	-- @name TickTime
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
	-- @see NextTick, Ticks, TicksRemain

	local function TickTime(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if state:IsActiveAura(aura) then
			local value = aura.tick or OvaleData:GetTickLength(auraId)
			return Compare(value, comparator, limit)
		end
		return Compare(math.huge, comparator, limit)
	end

	OvaleCondition:RegisterCondition("ticktime", false, TickTime)
end