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
	local OvaleFuture = Ovale.OvaleFuture
	local OvaleState = OvaleState

	local TestBoolean = OvaleCondition.TestBoolean

	--- Test if the given spell is in flight for spells that have a flight time after cast, e.g., Lava Burst.
	-- @name InFlightToTarget
	-- @paramsig boolean
	-- @param id The spell ID.
	-- @param yesno Optional. If yes, then return true if the spell is in flight. If no, then return true if it isn't in flight.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if target.DebuffRemains(haunt) <3 and not InFlightToTarget(haunt)
	--     Spell(haunt)

	local function InFlightToTarget(condition)
		local spellId, yesno = condition[1], condition[2]
		local boolean = (OvaleState.currentSpellId == spellId) or OvaleFuture:InFlight(spellId)
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("inflighttotarget", false, InFlightToTarget)
end