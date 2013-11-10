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
	local OvaleSpellBook = Ovale.OvaleSpellBook
	local OvaleState = Ovale.OvaleState

	local type = type
	local Compare = OvaleCondition.Compare
	local TestValue = OvaleCondition.TestValue

	--- Get the cooldown in seconds before a spell is ready for use.
	-- @name SpellCooldown
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if ShadowOrbs() ==3 and SpellCooldown(mind_blast) <2
	--     Spell(devouring_plague)

	local function SpellCooldown(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local start, duration
		if type(spellId) == "string" then
			local sharedCd = OvaleState.state.cd[spellId]
			if not sharedCd then
				return nil
			end
			start, duration = sharedCd.start, sharedCd.duration
		elseif not OvaleSpellBook:IsKnownSpell(spellId) then
			return nil
		else
			start, duration = OvaleState:GetComputedSpellCD(spellId)
		end
		if start > 0 and duration > 0 then
			return TestValue(start, start + duration, duration, start, -1, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("spellcooldown", true, SpellCooldown)
end