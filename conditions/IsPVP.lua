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

	local API_UnitIsPVP = UnitIsPVP
	local ParseCondition = OvaleCondition.ParseCondition
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the target is flagged for PvP activity.
	-- @name IsPVP
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the target is flagged for PvP activity. If no, then return true if it isn't PvP-flagged.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if not target.IsFriend() and target.IsPVP() Spell(sap)

	local function IsPVP(condition)
		local yesno = condition[1]
		local target = ParseCondition(condition)
		local boolean = API_UnitIsPVP(target)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("ispvp", false, IsPVP)
end