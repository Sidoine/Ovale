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
	local OvaleState = Ovale.OvaleState

	local API_HasFullControl = HasFullControl
	local TestBoolean = OvaleCondition.TestBoolean
	local state = OvaleState.state

	--- Test if the player is feared.
	-- @name IsFeared
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if feared. If no, then return true if it not feared.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if IsFeared() Spell(every_man_for_himself)

	local function IsFeared(condition)
		local yesno = condition[1]
		local boolean = not API_HasFullControl() and state:GetAura("player", "fear", "HARMFUL")
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("isfeared", false, IsFeared)
end