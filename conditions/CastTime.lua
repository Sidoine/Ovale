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
	local OvaleCooldown = Ovale.OvaleCooldown

	local API_GetSpellInfo = GetSpellInfo
	local Compare = OvaleCondition.Compare

	local function GetCastTime(spellId)
		local _, _, _, _, _, _, castTime = API_GetSpellInfo(spellId)
		if castTime then
			castTime = castTime / 1000
		else
			castTime = 0
		end
		return castTime
	end

	--- Get the cast time in seconds of the spell for the player, taking into account current haste effects.
	-- @name CastTime
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see ExecuteTime
	-- @usage
	-- if target.DebuffRemains(flame_shock) < CastTime(lava_burst)
	--     Spell(lava_burst)

	local function CastTime(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local castTime = GetCastTime(spellId)
		return Compare(castTime, comparator, limit)
	end

	--- Get the cast time in seconds of the spell for the player or the GCD for the player, whichever is greater.
	-- @name ExecuteTime
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see CastTime
	-- @usage
	-- if target.DebuffRemains(flame_shock) < ExecuteTime(lava_burst)
	--     Spell(lava_burst)

	local function ExecuteTime(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local castTime = GetCastTime(spellId)
		local gcd = OvaleCooldown:GetGCD()
		local t = (castTime > gcd) and castTime or gcd
		return Compare(t, comparator, limit)
	end

	OvaleCondition:RegisterCondition("casttime", true, CastTime)
	OvaleCondition:RegisterCondition("executetime", true, ExecuteTime)
end
