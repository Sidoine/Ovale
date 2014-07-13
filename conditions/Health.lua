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
	local OvaleGUID = Ovale.OvaleGUID

	local floor = math.floor
	local API_GetTime = GetTime
	local API_UnitHealth = UnitHealth
	local API_UnitHealthMax = UnitHealthMax
	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition
	local TestValue = OvaleCondition.TestValue

	-- static properties for TimeToDie(), indexed by unit ID
	local lastTTDTime = {}
	local lastTTDHealth = {}
	local lastTTDguid = {}
	local lastTTDdps = {}

	--[[
		Returns:
			Estimated number of seconds before the specified unit reaches zero health
			The current time
			Unit's current health
			Unit's maximum health
	--]]
	local function EstimatedTimeToDie(unitId)
		-- Check for target switch.
		if lastTTDguid[unitId] ~= OvaleGUID:GetGUID(unitId) then
			lastTTDguid[unitId] = OvaleGUID:GetGUID(unitId)
			lastTTDTime[unitId] = nil
			if lastTTDHealth[unitId] then
				wipe(lastTTDHealth[unitId])
			else
				lastTTDHealth[unitId] = {}
			end
			lastTTDdps[unitId] = nil
		end

		local timeToDie
		local health = API_UnitHealth(unitId) or 0
		local maxHealth = API_UnitHealthMax(unitId) or 1
		local currentTime = API_GetTime()

		-- Clamp maxHealth to always be at least 1.
		if maxHealth < health then
			maxHealth = health
		end
		if maxHealth < 1 then
			maxHealth = 1
		end

		if health == 0 then
			timeToDie = 0
		elseif maxHealth <= 5 then
			timeToDie = math.huge
		else
			local now = floor(currentTime)
			if (not lastTTDTime[unitId] or lastTTDTime[unitId] < now) and lastTTDguid[unitId] then
				lastTTDTime[unitId] = now
				local mod10, prevHealth
				for delta = 10, 1, -1 do
					mod10 = (now - delta) % 10
					prevHealth = lastTTDHealth[unitId][mod10]
					if delta == 10 then
						lastTTDHealth[unitId][mod10] = health
					end
					if prevHealth and prevHealth > health then
						lastTTDdps[unitId] = (prevHealth - health) / delta
						Ovale:Logf("prevHealth = %d, health = %d, delta = %d, dps = %d", prevHealth, health, delta, lastTTDdps[unitId])
						break
					end
				end
			end
			local dps = lastTTDdps[unitId]
			if dps and dps > 0 then
				timeToDie = health / dps
			else
				timeToDie = math.huge
			end
		end
		-- Clamp time to die at a finite number.
		if timeToDie == math.huge then
			-- Return time to die in the far-off future (one week).
			timeToDie = 3600 * 24 * 7
		end
		return timeToDie, currentTime, health, maxHealth
	end

	--- Get the current amount of health points of the target.
	-- @name Health
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current health.
	-- @return A boolean value for the result of the comparison.
	-- @see Life
	-- @usage
	-- if Health() <10000 Spell(last_stand)
	-- if Health(less 10000) Spell(last_stand)

	local function Health(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local timeToDie, now, health, maxHealth = EstimatedTimeToDie(target)
		if not timeToDie then
			return nil
		elseif timeToDie == 0 then
			return Compare(0, comparator, limit)
		end
		local value, origin, rate = health, now, -1 * health / timeToDie
		local start, ending = now, math.huge
		return TestValue(start, ending, value, origin, rate, comparator, limit)
	end

	OvaleCondition:RegisterCondition("health", false, Health)
	OvaleCondition:RegisterCondition("life", false, Health)

	--- Get the number of health points away from full health of the target.
	-- @name HealthMissing
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current missing health.
	-- @return A boolean value for the result of the comparison.
	-- @see LifeMissing
	-- @usage
	-- if HealthMissing() <20000 Item(healthstone)
	-- if HealthMissing(less 20000) Item(healthstone)

	local function HealthMissing(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local timeToDie, now, health, maxHealth = EstimatedTimeToDie(target)
		if not timeToDie or timeToDie == 0 then
			return nil
		end
		local missing = maxHealth - health
		local value, origin, rate = missing, now, health / timeToDie
		local start, ending = now, math.huge
		return TestValue(start, ending, value, origin, rate, comparator, limit)
	end

	OvaleCondition:RegisterCondition("healthmissing", false, Health)
	OvaleCondition:RegisterCondition("lifemissing", false, Health)

	--- Get the current percent level of health of the target.
	-- @name HealthPercent
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The current health percent.
	-- @return A boolean value for the result of the comparison.
	-- @see LifePercent
	-- @usage
	-- if HealthPercent() <20 Spell(last_stand)
	-- if target.HealthPercent(less 25) Spell(kill_shot)

	local function HealthPercent(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local timeToDie, now, health, maxHealth = EstimatedTimeToDie(target)
		if not timeToDie then
			return nil
		elseif timeToDie == 0 then
			return Compare(0, comparator, limit)
		end
		local healthPercent = health / maxHealth * 100
		local value, origin, rate = healthPercent, now, -1 * healthPercent / timeToDie
		local start, ending = now, math.huge
		return TestValue(start, ending, value, origin, rate, comparator, limit)
	end

	OvaleCondition:RegisterCondition("healthpercent", false, HealthPercent)
	OvaleCondition:RegisterCondition("lifepercent", false, HealthPercent)

	--- Get the amount of health points of the target when it is at full health.
	-- @name MaxHealth
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The maximum health.
	-- @return A boolean value for the result of the comparison.
	-- @usage
	-- if target.MaxHealth() >10000000 Item(mogu_power_potion)
	-- if target.MaxHealth(more 10000000) Item(mogu_power_potion)

	local function MaxHealth(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local value = API_UnitHealthMax(target)
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("maxhealth", false, MaxHealth)

	--- Get the estimated number of seconds remaining before the target is dead.
	-- @name TimeToDie
	-- @paramsig number or boolean
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see DeadIn
	-- @usage
	-- if target.TimeToDie() <2 and ComboPoints() >0 Spell(eviscerate)

	local function TimeToDie(condition)
		local comparator, limit = condition[1], condition[2]
		local target = ParseCondition(condition)
		local timeToDie, now = EstimatedTimeToDie(target)
		local value, origin, rate = timeToDie, now, -1
		local start, ending = now, now + timeToDie
		return TestValue(start, ending, value, origin, rate, comparator, limit)
	end

	OvaleCondition:RegisterCondition("deadin", false, TimeToDie)
	OvaleCondition:RegisterCondition("timetodie", false, TimeToDie)

	--- Get the estimated number of seconds remaining before the target reaches the given percent of max health.
	-- @name TimeToHealthPercent
	-- @paramsig number or boolean
	-- @param percent The percent of maximum health of the target.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=player.
	--     Valid values: player, target, focus, pet.
	-- @return The number of seconds.
	-- @return A boolean value for the result of the comparison.
	-- @see TimeToDie
	-- @usage
	-- if target.TimeToHealthPercent(25) <15 Item(virmens_bite_potion)

	local function TimeToHealthPercent(condition)
		local percent, comparator, limit = condition[1], condition[2], condition[3]
		local target = ParseCondition(condition)
		local timeToDie, now, health, maxHealth = EstimatedTimeToDie(target)
		local healthPercent = health / maxHealth * 100
		if healthPercent >= percent then
			local t = timeToDie * (healthPercent - percent) / healthPercent
			local value, origin, rate = t, now, -1
			local start, ending = now, now + t
			return TestValue(start, ending, value, origin, rate, comparator, limit)
		end
		return Compare(0, comparator, limit)
	end

	OvaleCondition:RegisterCondition("timetohealthpercent", false, TimeToHealthPercent)
	OvaleCondition:RegisterCondition("timetolifepercent", false, TimeToHealthPercent)
end