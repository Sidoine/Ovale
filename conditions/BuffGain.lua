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
	local ParseCondition = OvaleCondition.ParseCondition
	local TestValue = OvaleCondition.TestValue
	local state = OvaleState.state

	--- Get the time elapsed since the aura was last gained on the target.
	-- @paramsig number or boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see DebuffGain

	local function BuffGain(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local gain = aura.gain or 0
			if true then
				Ovale:Error("not implemented")
				return nil
			end
			return TestValue(gain, math.huge, 0, gain, 1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffgain", false, BuffGain)
	OvaleCondition:RegisterCondition("debuffgain", false, BuffGain)
end