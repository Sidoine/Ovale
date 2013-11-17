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

	--- Get the value of a buff as a number.  Not all buffs return an amount.
	-- @name BuffAmount
	-- @paramsig number
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param value Optional. Sets which aura value to return from UnitAura().
	--     Defaults to value=1.
	--     Valid values: 1, 2, 3.
	-- @return The value of the buff as a number.
	-- @see DebuffAmount
	-- @see TickValue
	-- @usage
	-- if DebuffAmount(stagger) >10000 Spell(purifying_brew)
	-- if DebuffAmount(stagger more 10000) Spell(purifying_brew)

	local function BuffAmount(condition)
		local auraId, comparator, limit = condition[1], condition[2], condition[3]
		local target, filter, mine = ParseCondition(condition)
		local value = condition.value or 1
		local state = OvaleState.state
		local statName = "value1"
		if value == 1 then
			statName = "value1"
		elseif value == 2 then
			statName = "value2"
		elseif value == 3 then
			statName = "value3"
		end
		local aura = state:GetAura(target, auraId, filter, mine)
		if aura then
			local start, ending = aura.start, aura.ending
			local value = aura[statName] or 0
			return TestValue(start, ending, value, start, 0, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("buffamount", false, BuffAmount)
	OvaleCondition:RegisterCondition("debuffamount", false, BuffAmount)
	OvaleCondition:RegisterCondition("tickvalue", false, BuffAmount)
end
