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
	local OvalePaperDoll = Ovale.PaperDoll
	local OvaleState = Ovale.OvaleState

	local ParseCondition = OvaleCondition.ParseCondition

	local function TimeWithHaste(t, haste)
		if not t then
			t = 0
		end
		if not haste then
			return t
		elseif haste == "spell" then
			return t / OvalePaperDoll:GetSpellHasteMultiplier()
		elseif haste == "melee" then
			return t / OvalePaperDoll:GetMeleeHasteMultiplier()
		else
			Ovale:Logf("Unknown haste parameter haste=%s", haste)
			return t
		end
	end

	--- Test if an aura is expired, or will expire after a given number of seconds.
	-- @name BuffExpires
	-- @paramsig boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param seconds Optional. The maximum number of seconds before the buff should expire.
	--     Defaults to 0 (zero).
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param haste Optional. Sets whether "seconds" should be lengthened or shortened due to haste.
	--     Defaults to haste=none.
	--     Valid values: melee, spell, none.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @see DebuffExpires
	-- @usage
	-- if BuffExpires(stamina any=1)
	--     Spell(power_word_fortitude)
	-- if target.DebuffExpires(rake 2)
	--     Spell(rake)

	local function BuffExpires(condition)
		local auraId, seconds = condition[1], condition[2]
		local target, filter, mine = ParseCondition(condition)
		local state = OvaleState.state
		local start, ending = state:GetAura(target, auraId, filter, mine)
		if not start or not ending then
			return 0, math.huge
		end
		seconds = TimeWithHaste(seconds or 0, condition.haste)
		if ending - seconds <= start then
			return start, math.huge
		else
			return ending - seconds, math.huge
		end
	end

	OvaleCondition:RegisterCondition("buffexpires", false, BuffExpires)
	OvaleCondition:RegisterCondition("debuffexpires", false, BuffExpires)

	--- Test if an aura is present or if the remaining time on the aura is more than the given number of seconds.
	-- @name BuffPresent
	-- @paramsig boolean
	-- @param id The spell ID of the aura or the name of a spell list.
	-- @param seconds Optional. The mininum number of seconds before the buff should expire.
	--     Defaults to 0 (zero).
	-- @param any Optional. Sets by whom the aura was applied. If the aura can be applied by anyone, then set any=1.
	--     Defaults to any=0.
	--     Valid values: 0, 1.
	-- @param haste Optional. Sets whether "seconds" should be lengthened or shortened due to haste.
	--     Defaults to haste=none.
	--     Valid values: melee, spell, none.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @see DebuffPresent
	-- @usage
	-- if not BuffPresent(stamina any=1)
	--     Spell(power_word_fortitude)
	-- if not target.DebuffPresent(rake 2)
	--     Spell(rake)

	local function BuffPresent(condition)
		local auraId, seconds = condition[1], condition[2]
		local target, filter, mine = ParseCondition(condition)
		local state = OvaleState.state
		local start, ending = state:GetAura(target, auraId, filter, mine)
		if not start or not ending then
			return nil
		end
		seconds = TimeWithHaste(seconds or 0, condition.haste)
		if ending - seconds <= start then
			return nil
		else
			return start, ending - seconds
		end
	end

	OvaleCondition:RegisterCondition("buffpresent", false, BuffPresent)
	OvaleCondition:RegisterCondition("debuffpresent", false, BuffPresent)
end
