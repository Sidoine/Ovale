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

	local function IsSameSpell(spellIdA, spellIdB, spellNameB)
		if spellIdB then
			return spellIdA == spellIdB
		elseif spellIdA and spellNameB then
			return OvaleSpellBook:GetSpellName(spellIdA) == spellNameB
		else
			return false
		end
	end

	--- Test if the target is casting the given spell.
	-- The spell may be specified either by spell ID, localized spell name, spell list name (as defined in SpellList),
	-- "harmful" for any harmful spell, or "helpful" for any helpful spell.
	-- @name Casting
	-- @paramsig boolean
	-- @param spell The spell to check.
	--     Valid values: spell ID, spell name, spell list name, harmful, helpful
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
		local start, ending, castSpellId, castSpellName, _
		if target == "player" then
			start = state.startCast
			ending = state.endCast
			castSpellId = state.currentSpellId
		else
			castSpellName, _, _, _, start, ending = API_UnitCastingInfo(target)
			if not castSpellName then
				castSpellName, _, _, _, start, ending = API_UnitChannelInfo(target)
			end
		end
		if not castSpellId and not castSpellName then
			return nil
		end
		if not spellId then
			return start, ending
		elseif type(spellId) == "number" then
			if IsSameSpell(spellId, castSpellId, castSpellName) then
				return start, ending
			else
				return nil
			end
		elseif OvaleData.buffSpellList[spellId] then
			local found = false
			for auraId in pairs(OvaleData.buffSpellList[spellId]) do
				if IsSameSpell(auraId, castSpellId, castSpellName) then
					return start, ending
				end
			end
			return nil
		elseif spellId == "harmful" then
			if not castSpellName then
				castSpellName = OvaleSpellBook:GetSpellName(castSpellId)
			end
			if API_IsHarmfulSpell(castSpellName) then
				return start, ending
			else
				return nil
			end
		elseif spellId == "helpful" then
			if not castSpellName then
				castSpellName = OvaleSpellBook:GetSpellName(castSpellId)
			end
			if API_IsHelpfulSpell(castSpellName) then
				return start, ending
			else
				return nil
			end
		end
	end

	OvaleCondition:RegisterCondition("casting", false, casting)
end
