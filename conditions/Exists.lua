--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleCondition = Ovale.OvaleCondition

	local API_UnitExists = UnitExists
	local ParseCondition = OvaleCondition.ParseCondition
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the target exists. The target may be alive or dead.
	-- @name Exists
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the target exists. If no, then return true if it doesn't exist.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @see Present
	-- @usage
	-- if pet.Exists(no) Spell(summon_imp)

	local function Exists(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
		local boolean = (API_UnitExists(target) == 1)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("exists", false, Exists)
end
