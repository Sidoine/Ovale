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

	local API_UnitClassification = UnitClassification
	local API_UnitLevel = UnitLevel
	local ParseCondition = OvaleCondition.ParseCondition
	local TestBoolean = OvaleCondition.TestBoolean

	--- Test whether the target's classification matches the given classification.
	-- @name Classification
	-- @paramsig boolean
	-- @param classification The unit classification to check.
	--     Valid values: normal, elite, worldboss.
	-- @param yesno Optional. If yes, then return true if it matches. If no, then return true if it doesn't match.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return A boolean value.
	-- @usage
	-- if target.Classification(worldboss) Item(virmens_bite_potion)

	local function Classification(condition)
		local classification, yesno = condition[1], condition[2]
		local targetClassification
		local target = ParseCondition(condition)
		if API_UnitLevel(target) < 0 then
			targetClassification = "worldboss"
		else
			targetClassification = API_UnitClassification(target)
			if targetClassification == "rareelite" then
				targetClassification = "elite"
			elseif targetClassification == "rare" then
				targetClassification = "normal"
			end
		end
		local boolean = (targetClassification == classification)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("classification", false, Classification)
end
