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
	local OvaleSwing = Ovale.OvaleSwing

	local TestValue = OvaleCondition.TestValue

	-- Test if a white hit just occured
	-- 1 : maximum time after a white hit
	-- Not useful anymore. No widely used spell reset swing timer anyway

	local function AfterWhiteHit(condition)
		local seconds, comparator, limit = condition[1], condition[2], condition[3]
		local start = OvaleSwing.starttime
		local ending = start + OvaleSwing.duration
		local now = OvaleState.now
		local value
		if now - start < seconds then
			value = 0
		elseif ending - now > 0.1 then
			value = ending - now
		else
			value = 0.1
		end
		return TestValue(start, math.huge, value, now, -1, comparator, limit)
	end

	--OvaleCondition:RegisterCondition("afterwhitehit", false, AfterWhiteHit)
end
