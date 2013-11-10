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
	local API_UnitIsDead = UnitIsDead
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the pet exists and is alive.
	-- PetPresent() is equivalent to pet.Present().
	-- @name PetPresent
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the target exists. If no, then return true if it doesn't exist.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @see Present
	-- @usage
	-- if target.IsInterruptible() and PetPresent(yes)
	--     Spell(pet_pummel)

	local function PetPresent(condition)
		local yesno = condition[1]
		local target = "pet"
		local boolean = API_UnitExists(target) and not API_UnitIsDead(target)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("petpresent", false, PetPresent)
end
