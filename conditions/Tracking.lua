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
	local OvaleSpellBook = Ovale.OvaleSpellBook

	local API_GetNumTrackingTypes = GetNumTrackingTypes
	local API_GetTrackingInfo = GetTrackingInfo
	local TestBoolean = OvaleCondition.TestBoolean

	-- Check if a tracking is enabled
	-- 1: the spell id
	-- return bool

	local function Tracking(condition)
		local spellId, yesno = condition[1], condition[2]
		local spellName = OvaleSpellBook:GetSpellName(spellId)
		local numTrackingTypes = API_GetNumTrackingTypes()
		local boolean = false
		for i = 1, numTrackingTypes do
			local name, _, active = API_GetTrackingInfo(i)
			if name and name == spellName then
				boolean = (active == 1)
				break
			end
		end
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("tracking", false, Tracking)
end