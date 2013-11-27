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

	local API_GetTime = GetTime
	local API_GetWeaponEnchantInfo = GetWeaponEnchantInfo

	--- Test if the weapon imbue on the given weapon has expired or will expire after a given number of seconds.
	-- @name WeaponEnchantExpires
	-- @paramsig boolean
	-- @param hand Sets which hand weapon.
	--     Valid values: main, off.
	-- @param seconds Optional. The maximum number of seconds before the weapon imbue should expire.
	--     Defaults to 0 (zero).
	-- @return A boolean value.
	-- @usage
	-- if WeaponEnchantExpires(main) Spell(windfury_weapon)

	local function WeaponEnchantExpires(condition)
		local hand, seconds = condition[1], condition[2]
		seconds = seconds or 0
		local hasMainHandEnchant, mainHandExpiration, _, hasOffHandEnchant, offHandExpiration = API_GetWeaponEnchantInfo()
		local now = API_GetTime()
		if hand == "mainhand" or hand == "main" then
			if hasMainHandEnchant then
				mainHandExpiration = mainHandExpiration / 1000
				return now + mainHandExpiration - seconds, math.huge
			end
		elseif hand == "offhand" or hand == "off" then
			if hasOffHandEnchant then
				offHandExpiration = offHandExpiration / 1000
				return now + offHandExpiration - seconds, math.huge
			end
		end
		return 0, math.huge
	end

	OvaleCondition:RegisterCondition("weaponenchantexpires", false, WeaponEnchantExpires)
end