--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...

do
	local OvaleBestAction = Ovale.OvaleBestAction
	local OvaleCompile = Ovale.OvaleCompile
	local OvaleCondition = Ovale.OvaleCondition
	local OvaleData = Ovale.OvaleData
	local OvaleEquipement = Ovale.OvaleEquipement
	local OvaleFuture = Ovale.OvaleFuture
	local OvaleGUID = Ovale.OvaleGUID
	local OvaleState = Ovale.OvaleState

	local Compare = OvaleCondition.Compare
	local ParseCondition = OvaleCondition.ParseCondition
	local state = OvaleState.state

	function ComputeParameter(spellId, paramName, state)
		local si = OvaleData:GetSpellInfo(spellId)
		if si and si[paramName] then
			local name = si[paramName]
			local node = OvaleCompile:GetFunctionNode(name)
			if node then
				local timeSpan, priority, element = OvaleBestAction:Compute(node, state)
				if element and element.type == "value" then
					local value = element.value + (state.currentTime - element.origin) * element.rate
					return value
				end
			else
				return si[paramName]
			end
		end
		return nil
	end

	-- Return the damage reduction from armor, assuming the target is boss-level.
	local BOSS_ARMOR = 24835
	local WEAKENED_ARMOR_DEBUFF = 113746

	local function BossArmorDamageReduction(target)
		local aura = state:GetAura(target, WEAKENED_ARMOR_DEBUFF, "HARMFUL")
		local armor = BOSS_ARMOR
		if state:IsActiveAura(aura) then
			armor = armor * (1 - 0.04 * aura.stacks)
		end
		local constant = 4037.5 * state.level - 317117.5
		if constant < 0 then
			constant = 0
		end
		return armor / (armor + constant)
	end

	--- Get the estimated damage of the most recent cast of the player's spell on the target.
	-- The calculated damage takes into account the values of attack power, spellpower, weapon damage and combo points (if used)
	-- at the time the spell was most recent cast.
	-- The damage is computed from information for the spell set via SpellInfo(...):
	--
	-- damage = base + bonusmainhand * MH + bonusoffhand * OH + bonusap * AP + bonuscp * CP + bonusapcp * AP * CP + bonussp * SP
	-- @name LastEstimatedDamage
	-- @paramsig number or boolean
	-- @param id The spell ID.
	-- @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	-- @param number Optional. The number to compare against.
	-- @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	--     Defaults to target=target.
	--     Valid values: player, target, focus, pet.
	-- @return The estimated damage of the most recent cast of the given spell by the player.
	-- @return A boolean value for the result of the comparison.
	-- @see Damage, LastDamage
	-- @usage
	-- if {Damage(rake) / target.LastEstimateDamage(rake)} >1.1
	--     Spell(rake)

	local function LastEstimatedDamage(condition)
		local spellId, comparator, limit = condition[1], condition[2], condition[3]
		local target = ParseCondition(condition, "target")
		local value = ComputeParameter(spellId, "lastEstimatedDamage", state)
		if not value then
			local guid = OvaleGUID:GetGUID(target)
			local ap = OvaleFuture:GetLastSpellInfo(guid, spellId, "attackPower") or 0
			local sp = OvaleFuture:GetLastSpellInfo(guid, spellId, "spellBonusDamage") or 0
			local mh = OvaleFuture:GetLastSpellInfo(guid, spellId, "mainHandWeaponDamage") or 0
			local oh = OvaleFuture:GetLastSpellInfo(guid, spellId, "offHandWeaponDamage") or 0
			local combo = OvaleFuture:GetLastSpellInfo(guid, spellId, "combo") or 0
			local bdm = OvaleFuture:GetLastSpellInfo(guid, spellId, "baseDamageMultiplier") or 1
			local dm = OvaleFuture:GetLastSpellInfo(guid, spellId, "damageMultiplier") or 1
			value = OvaleData:GetDamage(spellId, ap, sp, mh, oh, combo) * bdm * dm
		end
		-- Reduce by armor damage reduction for physical attacks.
		local si = OvaleData:GetSpellInfo(spellId)
		if si and si.physical then
			value = value * (1 - BossArmorDamageReduction(target))
		end
		return Compare(value, comparator, limit)
	end

	OvaleCondition:RegisterCondition("lastestimateddamage", false, LastEstimatedDamage)
	OvaleCondition:RegisterCondition("lastspellestimateddamage", false, LastEstimatedDamage)
end