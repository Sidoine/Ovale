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

	local wipe = table.wipe

	local RUNE_TYPE = {
		blood = 1,
		unholy = 2,
		frost = 3,
		death = 4
	}	

	local runes = {}

	local function ParseRuneCondition(condition)
		wipe(runes)

		local k = 1
		while true do
			local runeType, count = condition[2*k - 1], condition[2*k]
			if not RUNE_TYPE[runeType] then break end
			runes[runeType] = runes[runeType] + count
			k = k + 1
		end
		return runes.blood, runes.frost, runes.unholy, runes.death, condition.nodeath
	end

	--- Test if the current rune count meets the minimum rune requirements set out in the parameters.
	-- This condition takes pairs of "type number" to mean that there must be a minimum of number runes of the named type.
	-- E.g., Runes(blood 1 frost 1 unholy 1) means at least one blood, one frost, and one unholy rune is available, death runes included.
	-- @name Runes
	-- @paramsig boolean
	-- @param type The type of rune.
	--     Valid values: blood, frost, unholy, death
	-- @param number The number of runes
	-- @param ... Optional. Additional "type number" pairs for minimum rune requirements.
	-- @param nodeath Sets whether death runes can fulfill the rune count requirements. If set to 0, then death runes are allowed.
	--     Defaults to nodeath=0 (zero).
	--     Valid values: 0, 1.
	-- @return A boolean value.
	-- @usage
	-- if Runes(frost 1) Spell(howling_blast)

	local function Runes(condition)
		local blood, frost, unholy, death, nodeath = ParseRuneCondition(condition)
		local seconds = OvaleState:GetRunesCooldown(blood, frost, unholy, death, nodeath)
		local boolean = (seconds == 0)
		if boolean then
			return 0, math.huge
		end
		return nil
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
	-- @param nodeath Sets whether death runes can fulfill the rune count requirements. If set to 0, then death runes are allowed.
	--     Defaults to nodeath=0 (zero).
	--     Valid values: 0, 1.
	-- @return The number of seconds.

	local function RunesCooldown(condition)
		local blood, frost, unholy, death, nodeath = ParseRuneCondition(condition)
		local seconds = OvaleState:GetRunesCooldown(blood, frost, unholy, death, nodeath)
		if seconds then
			if seconds < OvaleState.maintenant then
				seconds = OvaleState.maintenant
			end
			return 0, OvaleState.currentTime + seconds, seconds, OvaleState.currentTime, -1
		end
		return nil
	end

	OvaleCondition:RegisterCondition("runes", false, Runes)
	OvaleCondition:RegisterCondition("runescooldown", false, RunesCooldown)
end