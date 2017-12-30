--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local __Condition = LibStub:GetLibrary("ovale/Condition")
	local OvaleCondition = __Condition.OvaleCondition

	local API_IsMounted = IsMounted
	local API_IsFalling = IsFalling
	local API_IsFlyableArea = IsFlyableArea
	local API_IsFlying = IsFlying
	local API_IsInInstance = IsInInstance
	local API_IsIndoors = IsIndoors
	local API_IsOutdoors = IsOutdoors
	local API_IsSwimming = IsSwimming
	local TestBoolean = __Condition.TestBoolean

	--- Test if the player is currently stealthed.
	-- The player is stealthed if rogue Stealth, druid Prowl, or a similar ability is active.
	-- Note that the rogue Vanish buff causes this condition to return false,
	-- but as soon as the buff disappears and the rogue is stealthed, this condition will return true.
	-- @name Stealthed
	-- @paramsig boolean
	-- @param yesno Optional. If yes, then return true if stealthed. If no, then return true if it not stealthed.
	--     Default is yes.
	--     Valid values: yes, no.
	-- @return A boolean value.
	-- @usage
	-- if Stealthed() or BuffPresent(vanish_buff) or BuffPresent(shadow_dance)
	--     Spell(ambush)

	local function mounted(condition)
		local yesno = condition[1]
		return TestBoolean(API_IsMounted(), yesno)
	end

	local function falling(condition)
		local yesno = condition[1]
		return TestBoolean(API_IsFalling(), yesno)
	end

	local function canfly(condition)
		local yesno = condition[1]
		return TestBoolean(API_IsFlyableArea(), yesno)
	end

	local function flying(condition)
		local yesno = condition[1]
		return TestBoolean(API_IsFlying(), yesno)
	end

	local function instanced(condition)
		local yesno = condition[1]
		return TestBoolean(API_IsInInstance(), yesno)
	end

	local function indoors(condition)
		local yesno = condition[1]
		return TestBoolean(API_IsIndoors(), yesno)
	end

	local function outdoors(condition)
		local yesno = condition[1]
		return TestBoolean(API_IsOutdoors(), yesno)
	end

	local function wet(positionalParams, namedParams, state, atTime)
		local yesno = positionalParams[1]
		local boolean = API_IsSwimming()
		return TestBoolean(boolean, yesno)
	end

	OvaleCondition:RegisterCondition("mounted", false, mounted)
	OvaleCondition:RegisterCondition("falling", false, falling)
	OvaleCondition:RegisterCondition("canfly", false, canfly)
	OvaleCondition:RegisterCondition("flying", false, flying)
	OvaleCondition:RegisterCondition("instanced", false, instanced)
	OvaleCondition:RegisterCondition("indoors", false, indoors)
	OvaleCondition:RegisterCondition("outdoors", false, outdoors)
	OvaleCondition:RegisterCondition("wet", false, wet)
end