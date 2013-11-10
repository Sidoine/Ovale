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

	local TestValue = OvaleCondition.TestValue

	local RUNE_TYPE = {
		blood = 1,
		unholy = 2,
		frost = 3,
		death = 4,
	}

	--- Get the current number of runes of the given type for death knights.
	-- @name RuneCount
	-- @paramsig number or boolean
	-- @param type The type of rune.
	--     Valid values: blood, frost, unholy, death
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param death Sets whether death runes can fulfill the rune count requirements. If set to 1, then death runes are allowed.
	--     Defaults to death=0 (zero).
	--     Valid values: 0, 1.
	-- @return The number of runes.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if RuneCount(unholy) ==2 or RuneCount(frost) ==2 or RuneCount(death) ==2
	--     Spell(obliterate)

	local function RuneCount(condition)
		local runeType, comparator, limit = condition[1], condition[2], condition[3]
		local death = condition.death
		runeType = RUNE_TYPE[runeType]

		-- Loop through the rune state and count the number of runes that match the given rune type.
		local value, origin, rate = 0, nil, nil
		for i = 1, 6 do
			local rune = OvaleState.state.rune[i]
			if rune and (rune.type == runeType or (rune.type == 4 and death == 1)) then
				if rune.cd > OvaleState.currentTime then
					-- Rune matches but is on cooldown.
					if not origin or rune.cd < origin then
						origin = rune.cd
						rate = 1 / rune.duration
					end
				else
					-- Rune matches and is available, so increment the counter.
					value = value + 1
				end
			end
		end
		if not origin then
			origin, rate = 0, 0
		end
		local start, ending = OvaleState.currentTime, math.huge
		return TestValue(start, ending, value, origin, rate, comparator, limit)
	end

	OvaleCondition:RegisterCondition("runecount", false, RuneCount)
end
