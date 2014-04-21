--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleCondition = Ovale.OvaleCondition

	local API_UnitIsDead = UnitIsDead
	local ParseCondition = OvaleCondition.ParseCondition
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the target is dead.
	-- @name IsDead
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the target is dead. If no, then return true if it isn't dead.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if pet.IsDead() Spell(revive_pet)

	local function IsDead(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
		local boolean = API_UnitIsDead(target)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isdead", false, IsDead)
end