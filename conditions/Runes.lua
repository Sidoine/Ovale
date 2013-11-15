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
	local OvaleRunes = Ovale.OvaleRunes
	local OvaleState = Ovale.OvaleState

	local RUNE_TYPE = OvaleRunes.RUNE_TYPE

	local ParseRuneCondition = nil
	do
		local runes = {}

		function ParseRuneCondition(condition)
			for name in pairs(RUNE_TYPE) do
				runes[name] = 0
			end
			local k = 1
			while true do
				local name, count = condition[2*k - 1], condition[2*k]
				if not RUNE_TYPE[name] then break end
				runes[name] = runes[name] + count
				k = k + 1
			end
			local deathCondition
			if condition.death == 0 then
				deathCondition = "none"
			elseif condition.death == 1 then
				deathCondition = "any"
			end
			-- Legacy parameter "nodeath"; no longer documented.
			if not condition.death and condition.nodeath == 1 then
				deathCondition = "none"
			elseif condition.nodeath == 0 then
				deathCondition = "any"
			end
			return runes.blood, runes.unholy, runes.frost, runes.death, deathCondition
		end
	end

	--- Test if the current active rune counst meets the minimum rune requirements set out in the parameters.
	-- This condition takes pairs of "type number" to mean that there must be a minimum of number runes of the named type.
	-- E.g., Runes(blood 1 frost 1 unholy 1) means at least one blood, one frost, and one unholy rune is available.
	-- @name Runes
	-- @paramsig boolean
	-- @param type The type of rune.
	--     Valid values: blood, frost, unholy, death
	-- @param number The number of runes
	-- @param ... Optional. Additional "type number" pairs for minimum rune requirements.
	-- @param death Sets how death runes are used to fulfill the rune count requirements.
	--     If not set, then only death runes of the proper rune type are used.
	--     If set with "death=0", then no death runes are used.
	--     If set with "death=1", then death runes of any rune type are used.
	--     Default is unset.
	--     Valid values: unset, 0, 1
	-- @return A boolean value.
	-- @usage
	-- if Runes(frost 1) Spell(howling_blast)

	local function Runes(condition)
		local blood, unholy, frost, death, deathCondition = ParseRuneCondition(condition)
		local state = OvaleState.state
		local seconds = state:GetRunesCooldown(blood, unholy, frost, death, deathCondition)
		return state.currentTime + seconds, math.huge
	end

	--- Get the number of seconds before the rune conditions are met.
	-- This condition takes pairs of "type number" to mean that there must be a minimum of number runes of the named type.
	-- E.g., RunesCooldown(blood 1 frost 1 unholy 1) returns the number of seconds before
	-- there are at least one blood, one frost, and one unholy rune, death runes included.
	-- @name RunesCooldown
	-- @paramsig number
	-- @param type The type of rune.
	--     Valid values: blood, frost, unholy, death
	-- @param number The number of runes
	-- @param ... Optional. Additional "type number" pairs for minimum rune requirements.
	-- @param death Sets how death runes are used to fulfill the rune count requirements.
	--     If not set, then only death runes of the proper rune type are used.
	--     If set with "death=0", then no death runes are used.
	--     If set with "death=1", then death runes of any rune type are used.
	--     Default is unset.
	--     Valid values: unset, 0, 1
	-- @return The number of seconds.

	local function RunesCooldown(condition)
		local blood, unholy, frost, death, deathCondition = ParseRuneCondition(condition)
		local state = OvaleState.state
		local seconds = state:GetRunesCooldown(blood, unholy, frost, death, deathCondition)
		return 0, state.currentTime + seconds, seconds, state.currentTime, -1
	end

	OvaleCondition:RegisterCondition("runes", false, Runes)
	OvaleCondition:RegisterCondition("runescooldown", false, RunesCooldown)
end