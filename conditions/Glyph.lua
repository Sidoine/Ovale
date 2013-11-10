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
	local OvaleSpellBook = Ovale.OvaleSpellBook

	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the given glyph is active.
	-- @name Glyph
	-- @paramsig boolean
	-- @param id The glyph spell ID.
	-- @param yesno Optional. If yes, then return true if the glyph is active. If no, then return true if it isn't active.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if InCombat(no) and Glyph(glyph_of_savagery)
	--     Spell(savage_roar)

	local function Glyph(condition)
		local glyph, yesno = condition[1], condition[2]
		local boolean = OvaleSpellBook:IsActiveGlyph(glyph)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("glyph", false, Glyph)
end