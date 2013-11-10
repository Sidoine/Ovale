--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local LBCT = LibStub("LibBabble-CreatureType-3.0"):GetLookupTable()
	local OvaleCondition = Ovale.OvaleCondition

	local API_UnitCreatureType = UnitCreatureType
	local ParseCondition = OvaleCondition.ParseCondition

	--- Test if the target is any of the listed creature types.
	-- @name CreatureType
	-- @paramsig boolean
	-- @param name The English name of a creature type.
	--     Valid values: Beast, Humanoid, Undead, etc.
	-- @param ... Optional. Additional creature types.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if target.CreatureType(Humanoid Critter)
	--     Spell(polymorph)

	local function CreatureType(condition)
		local target = ParseCondition(condition)
		local creatureType = API_UnitCreatureType(target)
		for i = 1, #condition do
			if creatureType == LBCT[condition[i]] then
				return 0, math.huge
			end
		end
		return nil
	end

	OvaleCondition:RegisterCondition("creaturetype", false, CreatureType)
end
