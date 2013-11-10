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

	local API_HasFullControl = HasFullControl
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the player has full control, i.e., isn't feared, charmed, etc.
	-- @name HasFullControl
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if the target exists. If no, then return true if it doesn't exist.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if HasFullControl(no) Spell(barkskin)

	local function HasFullControl(condition)
		local yesno = condition[1]
		local boolean = API_HasFullControl()
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("hasfullcontrol", false, HasFullControl)
end