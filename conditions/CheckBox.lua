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

	--- Test if all of the listed checkboxes are off.
	-- @name CheckBoxOff
	-- @paramsig boolean
	-- @param id The name of a checkbox. It should match one defined by AddCheckBox(...).
	-- @param ... Optional. Additional checkbox names.
	-- @return A boolean value.
	-- @see CheckBoxOn
	-- @usage
	-- AddCheckBox(opt_black_arrow "Black Arrow" default)
	-- if CheckBoxOff(opt_black_arrow) Spell(explosive_trap)

	local function CheckBoxOff(condition)
		for i = 1, #condition do
			if Ovale:IsChecked(condition[i]) then
				return nil
			end
		end
		return 0, math.huge
	end

	--- Test if all of the listed checkboxes are on.
	-- @name CheckBoxOn
	-- @paramsig boolean
	-- @param id The name of a checkbox. It should match one defined by AddCheckBox(...).
	-- @param ... Optional. Additional checkbox names.
	-- @return A boolean value.
	-- @see CheckBoxOff
	-- @usage
	-- AddCheckBox(opt_black_arrow "Black Arrow" default)
	-- if CheckBoxOn(opt_black_arrow) Spell(black_arrow)

	local function CheckBoxOn(condition)
		for i = 1, #condition do
			if not Ovale:IsChecked(condition[i]) then
				return nil
			end
		end
		return 0, math.huge
	end

	OvaleCondition:RegisterCondition("checkboxoff", false, CheckBoxOff)
	OvaleCondition:RegisterCondition("checkboxon", false, CheckBoxOn)
end
