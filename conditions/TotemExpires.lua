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

	local type = type
	local API_GetTotemInfo = GetTotemInfo

	local OVALE_TOTEMTYPE =
	{
		-- Death Knights
		ghoul = 1,
		-- Monks
		statue = 1,
		-- Shamans
		fire = 1,
		earth = 2,
		water = 3,
		air = 4
	}

	--- Test if the totem for shamans, the ghoul for death knights, or the statue for monks has expired.
	-- @name TotemExpires
	-- @paramsig boolean
	-- @param id The totem ID of the totem, ghoul or statue, or the type of totem.
	--     Valid types: fire, water, air, earth, ghoul, statue.
	-- @param seconds Optional. The maximum number of seconds before the totem should expire.
	--     Defaults to 0 (zero).
	-- @param totem Optional. Sets the specific totem to check of given totem ID type.
	--     Valid values: any totem spell ID
	-- @return A boolean value.
	-- @see TotemPresent
	-- @usage
	-- if TotemExpires(fire) Spell(searing_totem)
	-- if TotemPresent(water totem=healing_stream_totem) and TotemExpires(water 3) Spell(totemic_recall)

	local function TotemExpires(condition)
		local totemId, seconds = condition[1], condition[2]
		seconds = seconds or 0
		if type(totemId) ~= "number" then
			totemId = OVALE_TOTEMTYPE[totemId]
		end
		local haveTotem, name, startTime, duration = API_GetTotemInfo(totemId)
		if not haveTotem or not startTime then
			return 0, math.huge
		end
		if condition.totem and OvaleSpellBook:GetSpellName(condition.totem) ~= name then
			return 0, math.huge
		end
		return startTime + duration - seconds, math.huge
	end

	--- Test if the totem for shamans, the ghoul for death knights, or the statue for monks is present.
	-- @name TotemPresent
	-- @paramsig boolean
	-- @param id The totem ID of the totem, ghoul or statue, or the type of totem.
	--     Valid types: fire, water, air, earth, ghoul, statue.
	-- @param totem Optional. Sets the specific totem to check of given totem ID type.
	--     Valid values: any totem spell ID
	-- @return A boolean value.
	-- @see TotemExpires
	-- @usage
	-- if not TotemPresent(fire) Spell(searing_totem)
	-- if TotemPresent(water totem=healing_stream_totem) and TotemExpires(water 3) Spell(totemic_recall)

	local function TotemPresent(condition)
		local totemId = condition[1]
		if type(totemId) ~= "number" then
			totemId = OVALE_TOTEMTYPE[totemId]
		end
		local haveTotem, name, startTime, duration = API_GetTotemInfo(totemId)
		if not haveTotem or not startTime then
			return nil
		end
		if condition.totem and OvaleSpellBook:GetSpellName(condition.totem) ~= name then
			return nil
		end
		return startTime, startTime + duration
	end

	OvaleCondition:RegisterCondition("totemexpires", false, TotemExpires)
	OvaleCondition:RegisterCondition("totempresent", false, TotemPresent)
end