--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleBestAction = {}
Ovale.OvaleBestAction = OvaleBestAction

--<private-static-properties>
local OvaleActionBar = Ovale.OvaleActionBar
local OvaleCondition = Ovale.OvaleCondition
local OvaleData = Ovale.OvaleData
local OvaleEquipement = Ovale.OvaleEquipement
local OvalePaperDoll = Ovale.OvalePaperDoll
local OvalePower = Ovale.OvalePower
local OvaleSpellBook = Ovale.OvaleSpellBook
local OvaleStance = Ovale.OvaleStance
local OvaleState = Ovale.OvaleState

local floor = math.floor
local ipairs = ipairs
local loadstring = loadstring
local pairs = pairs
local select = select
local strfind = string.find
local tonumber = tonumber
local tostring = tostring
local API_GetActionCooldown = GetActionCooldown
local API_GetActionTexture = GetActionTexture
local API_GetItemIcon = GetItemIcon
local API_GetItemCooldown = GetItemCooldown
local API_GetItemSpell = GetItemSpell
local API_GetSpellInfo = GetSpellInfo
local API_GetSpellTexture = GetSpellTexture
local API_IsActionInRange = IsActionInRange
local API_IsCurrentAction = IsCurrentAction
local API_IsItemInRange = IsItemInRange
local API_IsSpellInRange = IsSpellInRange
local API_IsUsableAction = IsUsableAction
local API_IsUsableSpell = IsUsableSpell

local OVALE_DEFAULT_PRIORITY = 3

-- Age of the current computation.
local self_serial = 0
--</private-static-properties>

--<private-static-methods>
local function addTime(time1, duration)
	if not time1 then
		return nil
	else
		return time1 + duration
	end
end

local function isBeforeEqual(time1, time2)
	return time1 and (not time2 or time1<=time2)
end

local function isBefore(time1, time2)
	return time1 and (not time2 or time1<time2)
end

local function isAfterEqual(time1, time2)
	return not time1 or (time2 and time1>=time2)
end

local function isAfter(time1, time2)
	return not time1 or (time2 and time1>time2)
end

local function minTime(time1, time2)
	if isBefore(time1, time2) then
		return time1
	else
		return time2
	end
end

local function isBetween(checkTime, startTime, endTime)
	return isBeforeEqual(startTime, checkTime) and isAfterEqual(endTime, checkTime)
end

local function maxTime(time1, time2)
	if isAfter(time1, time2) then
		return time1
	else
		return time2
	end
end

local function PutValue(element, value, origin, rate)
	if not element.result then
		element.result = { type = "value" }
	end
	local result = element.result
	result.value = value
	result.origin = origin
	result.rate = rate
	return result
end

local function ComputeAnd(element, atTime)
	Ovale:Logf("%s [%d]", element.type, element.nodeId)
	local self = OvaleBestAction
	local startA, endA = self:ComputeBool(element.a, atTime)
	if not startA then
		Ovale:Logf("%s return nil [%d]", element.type, element.nodeId)
		return nil
	end
	if startA == endA then
		Ovale:Logf("%s return startA=endA [%d]", element.type, element.nodeId)
		return nil
	end
	local startB, endB, prioriteB, elementB
	if element.type == "if" then
		startB, endB, prioriteB, elementB = self:Compute(element.b, atTime)
	else
		startB, endB, prioriteB, elementB = self:ComputeBool(element.b, atTime)
	end
	-- If the "then" clause is a "wait" node, then only wait if the conditions are true.
	if elementB and elementB.wait and not isBetween(atTime, startA, endA) then
		elementB.wait = nil
	end
	if isAfter(startB, endA) or isAfter(startA, endB) then
		Ovale:Logf("%s return nil [%d]", element.type, element.nodeId)
		return nil
	end
	if isBefore(startB, startA) then
		startB = startA
	end
	if isAfter(endB, endA) then
		endB = endA
	end
	Ovale:Logf("%s return %s, %s [%d]", element.type, startB, endB, element.nodeId)
	return startB, endB, prioriteB, elementB
end

local function ComputeArithmetic(element, atTime)
	local self = OvaleBestAction
	local startA, endA, _, elementA = self:Compute(element.a, atTime)
	local startB, endB, _, elementB = self:Compute(element.b, atTime)

	-- Take intersection of (startA, endA) and (startB, endB)
	if isBefore(startA, startB) then
		startA = startB
	end
	if isAfter(endA, endB) then
		endA = endB
	end
	if not isBefore(startA, endA) then
		return nil
	end

	--[[
		A(t) = a + (t - b)*c
		B(t) = x + (t - y)*z

		Silently "typecast" non-values to a constant value of 0.
	--]]
	local a = elementA and elementA.value or 0
	local b = elementA and elementA.origin or 0
	local c = elementA and elementA.rate or 0
	local x = elementB and elementB.value or 0
	local y = elementB and elementB.origin or 0
	local z = elementB and elementB.rate or 0

	Ovale:Logf("%f+(t-%f)*%f %s %f+(t-%f)*%f [%d]", a, b, c, element.operator, x, y, z, element.nodeId)

	-- result(t) = l + (t - m) * n
	local l, m, n

	--[[
		A(t) = a + (t - b)*c = a + (t - t0 + t0 - b)*c = [a + (t0 - b)*c] + (t - t0)*c = A(t0) + (t - t0)*c
		B(t) = x + (t - y)*z = x + (t - t0 + t0 - y)*z = [x + (t0 - y)*z] + (t - t0)*z = B(t0) + (t - t0)*z
	--]]
	local A = a + (atTime - b)*c
	local B = x + (atTime - y)*z

	if element.operator == "+" then
		--[[
			A(t) = A(t0) + (t - t0)*c
			B(t) = B(t0) + (t - t0)*z

			A(t) + B(t) = [A(t0) + B(t0)] + (t - t0)*(c + z)
		--]]
		l = A + B
		m = atTime
		n = c + z
	elseif element.operator == "-" then
		--[[
			A(t) = A(t0) + (t - t0)*c
			B(t) = B(t0) + (t - t0)*z

			A(t) - B(t) = [A(t0) - B(t0)] + (t - t0)*(c - z)
		--]]
		l = A - B
		m = atTime
		n = c - z
	elseif element.operator == "*" then
		--[[
			A(t) = A(t0) + (t - t0)*c
			B(t) = B(t0) + (t - t0)*z
		--]]
		if c == 0 then
			l = A * B
			m = atTime
			n = A * z
		elseif z == 0 then
			l = A * B
			m = atTime
			n = c * B
		else
			Ovale:Error("at least one value must be constant when multiplying")
			return nil
		end
	elseif element.operator == "/" then
		--[[
			      A(t) = A(t0) + (t - t0)*c
			A(t)/B(t0) = [A(t0)/B(t0)] + (t - t0)*[c / B(t0)]

			Divide by B(t0) instead of B(t) to allow constructs like {target.Health() / target.TimeToDie()}.
		--]]
		l = A / B
		m = atTime
		n = c / B
	elseif element.operator == "%" then
		if c == 0 and z == 0 then
			l = A % B
			m = atTime
			n = 0
		else
			Ovale:Error("Parameters of % must be constants")
			return nil
		end
	end
	Ovale:Logf("result = %f+(t-%f)*%f [%d]", l, m, n, element.nodeId)
	return startA, endA, OVALE_DEFAULT_PRIORITY, PutValue(element, l, m, n)
end

local function ComputeCompare(element, atTime)
	local self = OvaleBestAction
	local startA, endA, _, elementA = self:Compute(element.a, atTime)
	local startB, endB, _, elementB = self:Compute(element.b, atTime)

	-- Take intersection of (startA, endA) and (startB, endB)
	if isBefore(startA, startB) then
		startA = startB
	end
	if isAfter(endA, endB) then
		endA = endB
	end
	if not isBefore(startA, endA) then
		return nil
	end

	--[[
		A(t) = a + (t - b)*c
		B(t) = x + (t - y)*z

		Silently "typecast" non-values to a constant value of 0.
	--]]
	local a = elementA and elementA.value or 0
	local b = elementA and elementA.origin or 0
	local c = elementA and elementA.rate or 0
	local x = elementB and elementB.value or 0
	local y = elementB and elementB.origin or 0
	local z = elementB and elementB.rate or 0

	Ovale:Logf("%f+(t-%f)*%f %s %f+(t-%f)*%f [%d]", a, b, c, element.operator, x, y, z, element.nodeId)

	--[[
		         A(t) = B(t)
		a + (t - b)*c = x + (t - y)*z
		a + t*c - b*c = x + t*z - y*z
		    t*c - t*z = (x - y*z) - (a - b*c)
		    t*(c - z) = B(0) - A(0)
	--]]
	local A = a - b*c
	local B = x - y*z
	if c == z then
		if (element.operator == "==" and A == B)
				or (element.operator == "<" and A < B)
				or (element.operator == "<=" and A <= B)
				or (element.operator == ">" and A > B)
				or (element.operator == ">=" and A >= B) then
			return startA, endA
		end
	else
		local t = (B - A)/(c - z)
		if (c > z and element.operator == "<")
				or (c > z and element.operator == "<=")
				or (c < z and element.operator == ">")
				or (c < z and element.operator == ">=") then
			-- (startA, endA) intersect (-inf, t)
			endA = minTime(endA, t)
		end
		if (c < z and element.operator == "<")
				or (c < z and element.operator == "<=")
				or (c > z and element.operator == ">")
				or (c > z and element.operator == ">=") then
			-- (startA, endA) intersect (t, inf)
			startA = maxTime(startA, t)
		end
		if isBefore(startA, endA) then
			return startA, endA
		end
	end
	return nil
end

local function ComputeCustomFunction(element, atTime)
	Ovale:Logf("custom function %s", element.name)
	local self = OvaleBestAction
	if not element.serial or element.serial < self_serial then
		element.startA, element.endA, element.priorityA, element.elementA = self:Compute(element.a, atTime)
		element.serial = self_serial
	else
		Ovale:Logf("Using cached values for %s", element.name)
	end
	return element.startA, element.endA, element.priorityA, element.elementA
end

local function ComputeFunction(element, atTime)
	local self = OvaleBestAction
	if element.func == "spell" or element.func == "macro" or element.func == "item" or element.func == "texture" then
		local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
			actionUsable, actionShortcut, actionIsCurrent, actionEnable, spellId = self:GetActionInfo(element)

		if not actionTexture then
			Ovale:Logf("Action %s not found", element.params[1])
			return nil
		end
		if element.params.usable == 1 and not actionUsable then
			Ovale:Logf("Action %s not usable", element.params[1])
			return nil
		end

		if spellId then
			local si = spellId and OvaleData.spellInfo[spellId]
			if si and si.casttime then
				element.castTime = si.casttime
			else
				local castTime = select(7, API_GetSpellInfo(spellId))
				if castTime then
					element.castTime = castTime / 1000
				else
					element.castTime = nil
				end
			end
			if si and si.toggle and actionIsCurrent then
				Ovale:Logf("Action %s (toggle) is the current action", element.params[1])
				return nil
			end
		else
			element.castTime = 0
		end

		if actionEnable and actionEnable > 0 then
			local start
			if actionCooldownDuration and actionCooldownStart and actionCooldownStart > 0 then
				start = actionCooldownDuration + actionCooldownStart
			else
				start = atTime
			end
			Ovale:Logf("start=%f attenteFinCast=%s [%d]", start, OvaleState.attenteFinCast, element.nodeId)
			if start < OvaleState.attenteFinCast then
				local si = OvaleState.currentSpellId and OvaleData.spellInfo[OvaleState.currentSpellId]
				if not (si and si.canStopChannelling) then
					-- not a channelled spell, or a channelled spell that cannot be interrupted
					start = OvaleState.attenteFinCast
				else
					--TODO: pas exact, parce que si ce sort est reporté de par exemple 0,5s par un debuff
					--ça tombera entre deux ticks
					local numTicks = floor(OvalePaperDoll:GetSpellHasteMultiplier() * si.canStopChannelling + 0.5)
					local tick = (OvaleState.attenteFinCast - OvaleState.startCast) / numTicks
					local tickTime = OvaleState.startCast + tick
					Ovale:Logf("%s start=%f", spellId, start)
					for i = 1, numTicks do
						if start <= tickTime then
							start = tickTime
							break
						end
						tickTime = tickTime + tick
					end
					Ovale:Logf("%s start=%f, numTicks=%d, tick=%f, tickTime=%f", spellId, start, numTicks, tick, tickTime)
				end
			end
			Ovale:Logf("Action %s can start at %f", element.params[1], start)
			local priority = element.params.priority or OVALE_DEFAULT_PRIORITY
			return start, nil, priority, element
		else
			Ovale:Logf("Action %s not enabled", element.params[1])
		end
	else
		local condition = OvaleCondition.conditions[element.func]
		if not condition then
			Ovale:Errorf("Condition %s not found", element.func)
			return nil
		end
		local start, ending, value, origin, rate = condition(element.params, atTime)

		if Ovale.trace then
			local conditionCall = element.func .. "("
			for k, v in pairs(element.params) do
				conditionCall = conditionCall .. k .. "=" .. v .. ","
			end
			conditionCall = conditionCall .. ")"
			Ovale:FormatPrint("Condition %s returned %s, %s, %s, %s, %s", conditionCall, start, ending, value, origin, rate)
		end

		if value then
			return start, ending, OVALE_DEFAULT_PRIORITY, PutValue(element, value, origin, rate)
		else
			return start, ending
		end
	end
end

local function ComputeGroup(element, atTime)
	local self = OvaleBestAction
	local bestStart, bestEnding, bestPriority, bestElement, bestCastTime

	Ovale:Logf("%s [%d]", element.type, element.nodeId)

	if #element.nodes == 1 then
		return self:Compute(element.nodes[1], atTime)
	end

	for k, v in ipairs(element.nodes) do
		local start, ending, priority, newElement = self:Compute(v, atTime)

		if start and start < atTime then
			start = atTime
		end

		if start and (not ending or start <= ending) then
			-- The node has a valid time interval.
			local castTime
			if newElement then
				castTime = newElement.castTime
			end
			if not castTime or castTime < OvaleState.gcd then
				castTime = OvaleState.gcd
			end

			local replace = false
			if not bestStart then
				replace = true
			else
				if priority and not bestPriority then
					Ovale:Errorf("Internal error: bestPriority=nil and priority=%d", priority)
					return nil
				elseif priority and priority > bestPriority then
					-- If the new spell has a higher priority than the previous one, then choose the
					-- higher priority spell if its cast is pushed back too far by the lower priority one.
					if newElement and newElement.params and newElement.params.wait then
						if start and start - bestStart < newElement.params.wait then
							replace = true
						end
					elseif start - bestStart < bestCastTime * 0.75 then
						replace = true
					end
				elseif priority and priority < bestPriority then
					-- If the new spell has a lower priority than the previous one, then choose the
					-- lower priority spell only if it doesn't push back the cast of the higher priority
					-- one by too much.
					if bestElement and bestElement.params and bestElement.params.wait then
						if bestStart - start > bestElement.params.wait then
							replace = true
						end
					elseif bestStart - start > castTime * 0.75 then
						replace = true
					end
				else
					-- If the spells have the same priority, then pick the one with an earlier cast time.
					-- TODO: why have a 0.01 second threshold here?
					if bestElement and bestElement.params and bestElement.params.wait then
						if bestStart - start > bestElement.params.wait then
							replace = true
						end
					elseif bestStart - start > 0.01 then
						replace = true
					end
				end
			end
			if replace then
				bestStart = start
				bestPriority = priority
				bestElement = newElement
				bestEnding = ending
				bestCastTime = castTime
			end
		end
		-- If the node is a "wait" node, then skip the remaining nodes.
		if newElement and newElement.wait then break end
	end

	if not bestStart then
		Ovale:Log("group return nil")
		return nil
	end

	if bestElement then
		local id = bestElement.value
		if bestElement.params then
			id = bestElement.params[1]
		end
		Ovale:Logf("group best action %s remains %s, %s [%d]", id, bestStart, bestEnding, element.nodeId)
	else
		Ovale:Logf("group no best action returns %s, %s [%d]", bestStart, bestEnding, element.nodeId)
	end
	return bestStart, bestEnding, bestPriority, bestElement
end

local function ComputeLua(element, atTime)
	local ret = loadstring(element.lua)()
	Ovale:Logf("lua %s", ret)
	return 0, nil, OVALE_DEFAULT_PRIORITY, PutValue(element, ret, 0, 0)
end

local function ComputeNot(element, atTime)
	local self = OvaleBestAction
	local startA, endA = self:ComputeBool(element.a, atTime)
	--[[
		NOT start < t < ending    ==>  0 < t < start  OR  ending < t < infinity
		NOT start < t < infinity  ==>  0 < t < start
		NOT nil                   ==>  0 < t < infinity
	]]--
	if startA and endA then
		-- TODO: This is not quite right since we ignore 0 < t < startA.
		return endA, nil
	elseif startA then
		return 0, startA
	else
		return 0, nil
	end
end

local function ComputeOr(element, atTime)
	Ovale:Log(element.type)
	local self = OvaleBestAction
	local startA, endA = self:ComputeBool(element.a, atTime)
	local startB, endB = self:ComputeBool(element.b, atTime)

	if isBefore(endA, atTime) then
		return startB, endB
	elseif isBefore(endB, atTime) then
		return startA, endA
	end
	if isBefore(endA, startB) then
		return startA, endA
	elseif isBefore(endB, startA) then
		return startB, endB
	end
	if isBefore(startA, startB) then
		startB = startA
	end
	if isAfter(endA, endB) then
		endB = endA
	end
	return startB, endB
end

local function ComputeUnless(element, atTime)
	Ovale:Logf("%s [%d]", element.type, element.nodeId)
	local self = OvaleBestAction
	local startA, endA = self:ComputeBool(element.a, atTime)
	local startB, endB, prioriteB, elementB = self:Compute(element.b, atTime)
	-- If the "then" clause is a "wait" node, then only wait if the conditions are false.
	if elementB and elementB.wait and isBetween(atTime, startA, endA) then
		elementB.wait = nil
	end
	-- unless {t: startA < t < endA} then {t: startB < t < endB}
	-- if not {t: startA < t < endA} then {t: startB < t < endB}
	-- if {t: t < startA} or {t: t > endA} then {t: startB < t < endB}
	-- {t: t < startA and startB < t < endB} or {t: startB < t < endB and endA < t}
	if isBeforeEqual(startA, startB) and isAfterEqual(endA, endB) then
		Ovale:Logf("%s return nil [%d]", element.type, element.nodeId)
		return nil
	end
	if isAfterEqual(startA, startB) and isBefore(endA, endB) then
		Ovale:Logf("%s return %s, %s [%d]", element.type, endA, endB, element.nodeId)
		return endA, endB, prioriteB, elementB
	end
	if isAfter(startA, startB) and isBefore(startA, endB) then
		endB = startA
	end
	if isAfter(endA, startB) and isBefore(endA, endB) then
		startB = endA
	end
	Ovale:Logf("%s return %s, %s [%d]", element.type, startB, endB, element.nodeId)
	return startB, endB, prioriteB, elementB
end

local function ComputeValue(element, atTime)
	Ovale:Logf("value %s", element.value)
	return 0, nil, OVALE_DEFAULT_PRIORITY, element
end

local function ComputeWait(element, atTime)
	Ovale:Logf("%s [%d]", element.type, element.nodeId)
	local self = OvaleBestAction
	local startA, endA, prioriteA, elementA = self:Compute(element.a, atTime)
	if elementA then
		elementA.wait = true
		Ovale:Logf("%s return %s, %s [%d]", element.type, startA, endA, element.nodeId)
	end
	return startA, endA, prioriteA, elementA
end
--</private-static-methods>

--<private-static-properties>
local OVALE_COMPUTE_VISITOR =
{
	["and"] = ComputeAnd,
	["arithmetic"] = ComputeArithmetic,
	["compare"] = ComputeCompare,
	["customfunction"] = ComputeCustomFunction,
	["function"] = ComputeFunction,
	["group"] = ComputeGroup,
	["if"] = ComputeAnd,
	["lua"] = ComputeLua,
	["not"] = ComputeNot,
	["or"] = ComputeOr,
	["unless"] = ComputeUnless,
	["value"] = ComputeValue,
	["wait"] = ComputeWait,
}
--</private-static-properties>

--<public-static-methods>
function OvaleBestAction:StartNewAction()
	OvaleState:Reset()
	OvaleState:ApplyActiveSpells()
	self_serial = self_serial + 1
end

function OvaleBestAction:GetActionInfo(element)
	if not element then
		return nil
	end

	local spellId = element.params[1]
	local action
	local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable

	local target = element.params.target
	if (not target) then
		target = OvaleCondition.defaultTarget
	end

	if (element.func == "spell" ) then
		action = OvaleActionBar:GetForSpell(spellId)
		if not OvaleSpellBook:IsKnownSpell(spellId) and not action then
			Ovale:Logf("Spell %s not learnt", spellId)
			return nil
		end

		actionCooldownStart, actionCooldownDuration, actionEnable = OvaleState:GetComputedSpellCD(spellId)

		local si = OvaleData.spellInfo[spellId]
		if si then
			if si.stance and not OvaleStance:IsStance(si.stance) then
				return nil
			end
			if si.combo == 0 and OvaleState.state.combo == 0 then
				return nil
			end
			for _, power in pairs(OvalePower.SECONDARY_POWER) do
				if si[power] and si[power] > OvaleState.state[power] then
					return nil
				end
			end
			if actionCooldownStart and actionCooldownDuration then
				if si.blood or si.frost or si.unholy or si.death then
					local runecd = OvaleState:GetRunesCooldown(si.blood, si.frost, si.unholy, si.death, false)
					if runecd > actionCooldownStart + actionCooldownDuration then
						actionCooldownDuration = runecd - actionCooldownStart
					end
				end
			end
			if si.texture then
				actionTexture = "Interface\\Icons\\" .. si.texture
			end
		end

		actionTexture = actionTexture or API_GetSpellTexture(spellId)
		actionInRange = API_IsSpellInRange(OvaleSpellBook:GetSpellName(spellId), target)
		actionUsable = API_IsUsableSpell(spellId)
		actionShortcut = nil
	elseif (element.func=="macro") then
		action = OvaleActionBar:GetForMacro(element.params[1])
		if action then
			actionTexture = API_GetActionTexture(action)
			actionInRange = API_IsActionInRange(action, target)
			actionCooldownStart, actionCooldownDuration, actionEnable = API_GetActionCooldown(action)
			actionUsable = API_IsUsableAction(action)
			actionShortcut = OvaleActionBar:GetBinding(action)
			actionIsCurrent = API_IsCurrentAction(action)
		else
			Ovale:Logf("Unknown macro %s", element.params[1])
		end
	elseif (element.func=="item") then
		local itemId = element.params[1]
		if itemId and type(itemId) ~= "number" then
			itemId = OvaleEquipement:GetEquippedItem(itemId)
		end
		if not itemId then
			return nil
		end

		Ovale:Logf("Item %s", itemId)

		local spellName = API_GetItemSpell(itemId)
		actionUsable = (spellName~=nil)

		action = OvaleActionBar:GetForItem(itemId)
		actionTexture = API_GetItemIcon(itemId)
		actionInRange = API_IsItemInRange(itemId, target)
		actionCooldownStart, actionCooldownDuration, actionEnable = API_GetItemCooldown(itemId)
		actionShortcut = nil
		actionIsCurrent = nil
	elseif element.func=="texture" then
		actionTexture = "Interface\\Icons\\"..element.params[1]
		actionCooldownStart = OvaleState.maintenant
		actionCooldownDuration = 0
		actionEnable = 1
		actionUsable = true
	end

	if action then
		if actionUsable == nil then
			actionUsable = API_IsUsableAction(action)
		end
		actionShortcut = OvaleActionBar:GetBinding(action)
		actionIsCurrent = API_IsCurrentAction(action)
	end

	local cd = OvaleState:GetCD(spellId)
	if cd and cd.toggle then
		actionIsCurrent = 1
	end

	return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, spellId, target, element.params.nored
end

function OvaleBestAction:Compute(element, atTime)
	if not element or (Ovale.bug and not Ovale.trace) then
		return nil
	end

	local visitor = OVALE_COMPUTE_VISITOR[element.type]
	if visitor then
		return visitor(element, atTime)
	end

	Ovale:Logf("unknown element %s, return nil", element.type)
	return nil
end

function OvaleBestAction:ComputeBool(element, atTime)
	local start, ending, priority, element = self:Compute(element, atTime)
	--Special case of a value element: it must not be 0
	if element and element.type == "value" and element.value == 0 and element.rate == 0 then
		return nil
	else
		return start, ending, priority, element
	end
end
--</public-static-methods>
