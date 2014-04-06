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

	local API_GetSpellInfo = GetSpellInfo
	local Compare = OvaleCondition.Compare

	--- Get the cast time in seconds of the spell for the player, taking into account current haste effects.
	-- @name CastTime
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see RemainingCastTime
	-- @usage
	-- if target.DebuffRemains(flame_shock) < CastTime(lava_burst)
	--     Spell(lava_burst)

	local function CastTime(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local castTime = 0
		if spellId then
			local _, _, _, _, _, _, _castTime = API_GetSpellInfo(spellId)
			if _castTime then
				castTime = _castTime / 1000
				Ovale:Logf("castTime = %f %s %s", castTime, comparator, limit)
			end
		end
		return Compare(castTime, comparator, limit)
	end

	OvaleCondition:RegisterCondition("casttime", true, CastTime)
end
