--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013 Sidoine
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleCondition = Ovale.OvaleCondition
	local OvaleData = Ovale.OvaleData
	local OvaleSpellBook = Ovale.OvaleSpellBook
	local OvaleState = Ovale.OvaleState

	local pairs = pairs
	local type = type
	local API_IsHarmfulSpell = IsHarmfulSpell
	local API_IsHelpfulSpell = IsHelpfulSpell
	local API_UnitCastingInfo = UnitCastingInfo
	local API_UnitChannelInfo = UnitChannelInfo
	local ParseCondition = OvaleCondition.ParseCondition
	local state = OvaleState.state

	--- Test if the target is casting the given spell.
	-- The spell may be specified either by spell ID, spell list name (as defined in SpellList),
	-- "harmful" for any harmful spell, or "helpful" for any helpful spell.
	-- @name Casting
	-- @paramsig boolean
	-- @param spell The spell to check.
	--     Valid values: spell ID, spell list name, harmful, helpful
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- Define(maloriak_release_aberrations 77569)
	-- if target.Casting(maloriak_release_aberrations)
	--     Spell(pummel)

	local function Casting(condition)
		local spellId = condition[1]
		local target = ParseCondition(condition)

		-- Get the information about the current spellcast.
		local start, ending, castSpellId, castSpellName
		if target == "player" then
			start = state.startCast
			ending = state.endCast
			castSpellId = state.currentSpellId
			castSpellName = OvaleSpellBook:GetSpellName(castSpellId)
		else
			local spellName, _, _, _, startTime, endTime = UnitCastingInfo(target)
			if not spellName then
				spellName, _, _, _, startTime, endTime = UnitChannelInfo("unit")
			end
			if spellName then
				castSpellName = spellName
				start = startTime/1000
				ending = endTime/1000
			end
		end

		if castSpellId or castSpellName then
			if not spellId then
				-- No spell specified, so whatever spell is currently casting.
				return start, ending
			elseif OvaleData.buffSpellList[spellId] then
				for id in pairs(OvaleData.buffSpellList[spellId]) do
					if id == castSpellId or OvaleSpellBook:GetSpellName(id) == castSpellName then
						return start, ending
					end
				end
			elseif spellId == "harmful" and API_IsHarmfulSpell(castSpellName) then
				return start, ending
			elseif spellId == "helpful" and API_IsHelpfulSpell(castSpellName) then
				return start, ending
			elseif spellId == castSpellId then
				return start, ending
			elseif type(spellId) == "number" and OvaleSpellBook:GetSpellName(spellId) == castSpellName then
				return start, ending
			end
		end
		return nil
	end

	OvaleCondition:RegisterCondition("casting", false, Casting)
end
