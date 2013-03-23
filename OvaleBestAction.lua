--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013 Sidoine, Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

local _, Ovale = ...
local OvaleBestAction = {}
Ovale.OvaleBestAction = OvaleBestAction

--<private-static-properties>
local OvaleActionBar = Ovale.OvaleActionBar
local OvaleCondition = Ovale.OvaleCondition
local OvaleData = Ovale.OvaleData
local OvaleEquipement = Ovale.OvaleEquipement
local OvalePaperDoll = Ovale.OvalePaperDoll
local OvaleStance = Ovale.OvaleStance
local OvaleState = Ovale.OvaleState

local floor = math.floor
local ipairs = ipairs
local loadstring = loadstring
local pairs = pairs
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
--</private-static-properties>

--<private-static-methods>
local function printTime(temps)
	if (temps == nil) then
		Ovale:Print("> nil")
	else
		Ovale:Print("> "..temps)
	end
end

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

local function ComputeAfter(element)
	local self = OvaleBestAction
	local timeA = self:Compute(element.time)
	local startA, endA = self:Compute(element.a)
	return addTime(startA, timeA), addTime(endA, timeA)
end

local function ComputeAnd(element)
	Ovale:Log(element.type .. " [" .. element.nodeId .. "]")
	local self = OvaleBestAction
	local startA, endA, priorityA, elementA = self:ComputeBool(element.a)
	if not startA then
		Ovale:Log(element.type .. " return nil  [" .. element.nodeId .. "]")
		return nil
	end
	if startA == endA then
		Ovale:Log(element.type .. " return startA=endA  [" .. element.nodeId .. "]")
		return nil
	end
	local startB, endB, prioriteB, elementB
	if element.type == "if" then
		startB, endB, prioriteB, elementB = self:Compute(element.b)
	else
		startB, endB, prioriteB, elementB = self:ComputeBool(element.b)
	end
	-- If the "then" clause is a "wait" node, then only wait if the conditions are true.
	if elementB and elementB.wait and not isBetween(OvaleState.currentTime, startA, endA) then
		elementB.wait = nil
	end
	if isAfter(startB, endA) or isAfter(startA, endB) then
		Ovale:Log(element.type .. " return nil [" .. element.nodeId .. "]")
		return nil
	end
	if isBefore(startB, startA) then
		startB = startA
	end
	if isAfter(endB, endA) then
		endB = endA
	end
	Ovale:Log(element.type .. " return " .. tostring(startB) .. "," .. tostring(endB) .. " [" .. element.nodeId .. "]")
	return startB, endB, prioriteB, elementB
end

local function ComputeBefore(element)
	local self = OvaleBestAction
	local timeA = self:Compute(element.time)
	local startA, endA = self:Compute(element.a)
	return addTime(startA, -timeA), addTime(endA, -timeA)
end

local function ComputeBetween(element)
	Ovale:Log("between")
	local self = OvaleBestAction
	local tempsA = self:Compute(element.a)
	local tempsB = self:Compute(element.b)
	if not tempsA and not tempsB then
		Ovale:Log("diff returns 0 because the two nodes are nil")
		return 0
	end
	if not tempsA or not tempsB then
		Ovale:Log(element.type .. " return nil")
		return nil
	end
	local diff
	if tempsA > tempsB then
		diff = tempsA - tempsB
	else
		diff = tempsB - tempsA
	end
	Ovale:Log("diff returns "..diff)
	return diff
end

local function ComputeCompare(element)
	Ovale:Log("compare " .. element.comparison)
	local self = OvaleBestAction
	local tempsA = self:Compute(element.a)
	local timeB = self:Compute(element.time)
	Ovale:Log(tostring(tempsA) .. " " .. element.comparison .. " " .. tostring(timeB))
	if element.comparison == "more" and (not tempsA or tempsA > timeB) then
		Ovale:Log(element.type .. " return 0")
		return 0
	elseif element.comparison == "less" and tempsA and tempsA < timeB then
		Ovale:Log(element.type .. " return 0")
		return 0
	elseif element.comparison == "at most" and tempsA and tempsA <= timeB then
		Ovale:Log(element.type .. " return 0")
		return 0
	elseif element.comparison == "at least" and (not tempsA or tempsA >= timeB) then
		Ovale:Log(element.type .. " return 0")
		return 0
	end
	return nil
end

local function ComputeFromUntil(element)
	Ovale:Log("fromuntil")
	local self = OvaleBestAction
	local tempsA = self:Compute(element.a)
	if not tempsA then
		Ovale:Log(element.type .. " return nil")
		return nil
	end
	local tempsB = self:Compute(element.b)
	if not tempsB then
		Ovale:Log(element.type .. " return nil")
		return nil
	end
	Ovale:Log("fromuntil returns " .. (tempsB - tempsA))
	return tempsB - tempsA
end

local function ComputeFunction(element)
	local self = OvaleBestAction
	if element.func == "spell" or element.func == "macro" or element.func == "item" or element.func == "texture" then
		local action
		local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
			actionUsable, actionShortcut, actionIsCurrent, actionEnable, spellId = self:GetActionInfo(element)

		if not actionTexture then
			Ovale:Log("Action "..element.params[1].." not found")
			return nil
		end
		if element.params.usable == 1 and not actionUsable then
			Ovale:Log("Action "..element.params[1].." not usable")
			return nil
		end
		if spellId and OvaleData.spellInfo[spellId] and OvaleData.spellInfo[spellId].casttime then
			element.castTime = OvaleData.spellInfo[spellId].casttime
		elseif spellId then
			local spell, rank, icon, cost, isFunnel, powerType, castTime = API_GetSpellInfo(spellId)
			if castTime then
				element.castTime = castTime / 1000
			else
				element.castTime = nil
			end
		else
			element.castTime = 0
		end
		--TODO: not useful anymore?
		if spellId and OvaleData.spellInfo[spellId] and OvaleData.spellInfo[spellId].toggle and actionIsCurrent then
			Ovale:Log("Action "..element.params[1].." is current action")
			return nil
		end
		if actionEnable and actionEnable > 0 then
			local remaining
			if not actionCooldownDuration or actionCooldownStart == 0 then
				remaining = OvaleState.currentTime
			else
				remaining = actionCooldownDuration + actionCooldownStart
			end
			Ovale:Log("remaining = " .. remaining .. " attenteFinCast=" .. tostring(OvaleState.attenteFinCast))
			if remaining < OvaleState.attenteFinCast then
				if	not OvaleData.spellInfo[OvaleState.currentSpellId] or
						not OvaleData.spellInfo[OvaleState.currentSpellId].canStopChannelling then
					remaining = OvaleState.attenteFinCast
				else
					--TODO: pas exact, parce que si ce sort est reporté de par exemple 0,5s par un debuff
					--ça tombera entre deux ticks
					local ticks = floor(OvalePaperDoll:GetSpellHasteMultiplier() * OvaleData.spellInfo[OvaleState.currentSpellId].canStopChannelling + 0.5)
					local tickLength = (OvaleState.attenteFinCast - OvaleState.startCast) / ticks
					local tickTime = OvaleState.startCast + tickLength
					Ovale:Log(spellId .. " remaining = " .. remaining)
					Ovale:Log("ticks = "..ticks.." tickLength="..tickLength.." tickTime="..tickTime)
					for i=1, ticks do
						if remaining <= tickTime then
							remaining = tickTime
							break
						end
						tickTime = tickTime + tickLength
					end
					Ovale:Log(spellId .. " remaining = " .. remaining)
				end
			end
			Ovale:Log("Action "..element.params[1].." remains "..remaining)
			local priority = element.params.priority or OVALE_DEFAULT_PRIORITY
			return remaining, nil, priority, element
		else
			Ovale:Log("Action "..element.params[1].." not enabled")
		end
	else
		local condition = OvaleCondition.conditions[element.func]
		if not condition then
			Ovale.bug = true
			Ovale:Print("Function "..element.func.." not found")
			return nil
		end
		local start, ending, value, origin, rate = condition(element.params)

		if Ovale.trace then
			local parameterList = element.func.."("
			for k,v in pairs(element.params) do
				parameterList = parameterList..k.."="..v..","
			end
			Ovale:Print("Function "..parameterList..") returned "..tostring(start)..","..tostring(ending)..","..tostring(value)..","..tostring(origin)..","..tostring(rate))
		end

		if value then
			return start, ending, OVALE_DEFAULT_PRIORITY, PutValue(element, value, origin, rate)
		else
			return start, ending
		end
	end
end


local function ComputeGroup(element)
	local self = OvaleBestAction
	local bestStart
	local bestEnding
	local bestPriority
	local bestElement
	local bestCastTime

	Ovale:Log(element.type .. " [" .. element.nodeId .. "]")

	if #element.nodes == 1 then
		return self:Compute(element.nodes[1])
	end

	for k, v in ipairs(element.nodes) do
		local start, ending, priority, newElement = self:Compute(v)

		if start and start < OvaleState.currentTime then
			start = OvaleState.currentTime
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
				-- Maximum time between the best spell and the current spell.
				local maxDiff
				if priority and not bestPriority then
					Ovale:Error("Internal error: bestPriority=nil and priority=" .. priority)
					return nil
				elseif priority and priority > bestPriority then
					-- Si le nouveau sort est plus prioritaire que le précédent, on le lance
					-- si caster le sort actuel repousse le nouveau sort
					maxDiff = bestCastTime * 0.75
				elseif priority and priority < bestPriority then
					-- A l'inverse, si il est moins prioritaire que le précédent, on ne le lance
					-- que si caster le nouveau sort ne repousse pas le meilleur
					maxDiff = castTime * 0.75
				else
					maxDiff = -0.01
				end
				if start - bestStart < maxDiff then
					replace = true
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
		Ovale:Log("group best action " .. tostring(id) .. " remains " .. bestStart .. "," .. tostring(bestEnding) .. " [" .. element.nodeId .. "]")
	else
		Ovale:Log("group no best action returns " .. bestStart .. "," .. tostring(bestEnding) .. " [" .. element.nodeId .. "]")
	end
	return bestStart, bestEnding, bestPriority, bestElement
end

local function ComputeLua(element)
	local ret = loadstring(element.lua)()
	Ovale:Log("lua "..tostring(ret))
	return 0, nil, OVALE_DEFAULT_PRIORITY, PutValue(element, ret, 0, 0)
end

local function ComputeNot(element)
	local self = OvaleBestAction
	local startA, endA = self:ComputeBool(element.a)
	if startA then
		return endA, nil
	else
		return 0, nil
	end
end

local function ComputeOr(element)
	Ovale:Log(element.type)
	local self = OvaleBestAction
	local startA, endA = self:ComputeBool(element.a)
	local startB, endB = self:ComputeBool(element.b)

	if isBefore(endA, OvaleState.currentTime) then
		return startB, endB
	elseif isBefore(endB, OvaleState.currentTime) then
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

local function ComputeOperator(element)
	local self = OvaleBestAction
	local startA, endA, prioA, elementA = self:Compute(element.a)
	local startB, endB, prioB, elementB = self:Compute(element.b)
	if not elementA or not elementB then
		Ovale:Log("operator " .. element.operator .. ": elementA or elementB is nil")
		return nil
	end

	-- A(t) = a + (t - b) * c
	-- B(t) = x + (t - y) * z
	local a, b, c
	local x, y, z

	if elementA then
		a = elementA.value
		b = elementA.origin
		c = elementA.rate
	else
		-- A boolean used in a number context has the value 1
		a = 1
		b = 0
		c = 0
	end
	if elementB then
		x = elementB.value
		y = elementB.origin
		z = elementB.rate
	else
		x = 1
		y = 0
		z = 0
	end

	if startA == endA then
		startA, endA = 0, nil
		a, b, c = 0, 0, 0
	end
	if startB == endB then
		startB, endB = 0, nil
		x, y, z = 0, 0, 0
	end

	if isBefore(startA, startB) then
		startA = startB
	end
	if isAfter(endA, endB) then
		endA = endB
	end

	if not a or not x or not b or not y then
		Ovale:Log("operator " .. element.operator .. ": a or x is nil")
		return nil
	end

	Ovale:Log(a .. "+(t-" .. b .. ")*" .. c .. " " .. element.operator .. " " .. x .. "+(t-" .. y .. ")*" .. z)

	-- result(t) = l + (t - m) * n
	local l, m, n

	if element.operator == "*" then
		if c == 0 then
			l = a * x
			m = y
			n = a * z
		elseif z == 0 then
			l = x * a
			m = b
			n = x * c
		else
			Ovale:Error("at least one value must be constant when multiplying")
		end
	elseif element.operator == "+" then
		if c + z == 0 then
			l = (a + x) - (b - y) * c
			m = 0
			n = 0
		else
			l = a + x
			m = (b * c + y * z) / (c + z)
			n = c + z
		end
	elseif element.operator == "-" then
		if c - z == 0 then
			l = (a - x) - (b - y) * c
			m = 0
			n = 0
		else
			l = a - x
			m = (b * c - y * z) / (c - z)
			n = c - z
		end
	elseif element.operator == "/" then
		if z ~= 0 then
			-- To allow constructs like {target.Health() / target.DeadIn()}
			x = x + (OvaleState.currentTime - y) * z
		end
		l = a / x
		m = b
		n = c / x
	elseif element.operator == "%" then
		if c == 0 and z == 0 then
			l = c % z
			m = 0
			n = 0
		else
			Ovale:Error("Parameters of % must be constants")
		end
	else
		-- Comparisons
		-- a + (t-b)*c = x + (t-y)*z
		-- (t-b)*c - (t-y)*z = x-a
		-- t*c - b*c - t*z + y*z = x-a
		-- t*(c-z) = x-a + b*c - y*z
		-- t = (x-a + b*c - y*z)/(c-z)
		local A, B, t
		if c == z then
			A = a - b * c
			B = x - y * z
		else
			t = (x - a + b * c - y * z) / (c - z)
		end
		if element.operator == "<" then
			if c == z then
				if A < B then
					return startA, endA
				else
					return nil
				end
			elseif c > z then
				return startA, minTime(endA, t)
			else
				return maxTime(startA, t), endA
			end
		elseif element.operator == "<=" then
			if c == z then
				if A <= B then
					return startA, endA
				else
					return nil
				end
			elseif c > z then
				return startA, minTime(endA, t)
			else
				return maxTime(startA, t), endA
			end
		elseif element.operator == ">" then
			if c == z then
				if A > B then
					return startA, endA
				else
					return nil
				end
			elseif c < z then
				return startA, minTime(endA, t)
			else
				return maxTime(startA, t), endA
			end
		elseif element.operator == ">=" then
			if c == z then
				if A >= B then
					return startA, endA
				else
					return nil
				end
			elseif c < z then return
				startA, minTime(endA, t)
			else
				return maxTime(startA, t), endA
			end
		elseif element.operator == "==" then
			if c == z and A == B then
				return startA, endA
			else
				return nil
			end
		end
	end

	Ovale:Log("result = " .. l .. " + " .. m .. "*" .. n)
	return startA, endA, OVALE_DEFAULT_PRIORITY, PutValue(element, l, m, n)
end

local function ComputeTime(element)
	return element.value
end

local function ComputeUnless(element)
	Ovale:Log(element.type)
	local self = OvaleBestAction
	local startA, endA = self:ComputeBool(element.a)
	local startB, endB, prioriteB, elementB = self:Compute(element.b)
	-- If the "then" clause is a "wait" node, then only wait if the conditions are false.
	if elementB and elementB.wait and isBetween(OvaleState.currentTime, startA, endA) then
		elementB.wait = nil
	end

	if isBeforeEqual(startA, startB) and isAfterEqual(endA, endB) then
		Ovale:Log(element.type .. " return nil")
		return nil
	end
	if isAfterEqual(startA, startB) and isBefore(endA, endB) then
		Ovale:Log(element.type .. " return " .. tostring(endA) .. "," .. tostring(endB))
		return endA, endB, prioriteB, elementB
	end
	if isAfter(startA, startB) and isBefore(startA, endB) then
		endB = startA
	end
	if isAfter(endA, startB) and isBefore(endA, endB) then
		startB = endA
	end
	Ovale:Log(element.type .. " return " .. tostring(startB) .. "," .. tostring(endB))
	return startB, endB, prioriteB, elementB
end

local function ComputeValue(element)
	Ovale:Log("value " .. element.value)
	return 0, nil, OVALE_DEFAULT_PRIORITY, element
end

local function ComputeWait(element)
	Ovale:Log(element.type .. " [" .. element.nodeId .. "]")
	local self = OvaleBestAction
	local startA, endA, prioriteA, elementA = self:Compute(element.a)
	if elementA then
		elementA.wait = true
		Ovale:Log(element.type .. " return " .. tostring(startA) .. "," .. tostring(endA) .. " [" .. element.nodeId .. "]")
	end
	return startA, endA, prioriteA, elementA
end
--</private-static-methods>

--<private-static-properties>
local OVALE_COMPUTE_VISITOR =
{
	["after"] = ComputeAfter,
	["and"] = ComputeAnd,
	["before"] = ComputeBefore,
	["between"] = ComputeBetween,
	["compare"] = ComputeCompare,
	["fromuntil"] = ComputeFromUntil,
	["function"] = ComputeFunction,
	["group"] = ComputeGroup,
	["if"] = ComputeAnd,
	["lua"] = ComputeLua,
	["not"] = ComputeNot,
	["operator"] = ComputeOperator,
	["or"] = ComputeOr,
	["time"] = ComputeTime,
	["unless"] = ComputeUnless,
	["value"] = ComputeValue,
	["wait"] = ComputeWait,
}
--</private-static-properties>

--<public-static-methods>
function OvaleBestAction:StartNewAction()
	OvaleState:Reset()
	OvaleState:ApplyActiveSpells()
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
		if not OvaleData.spellList[spellId] and not action then
			Ovale:Log("Spell "..spellId.." not learnt")
			return nil
		end

		actionCooldownStart, actionCooldownDuration, actionEnable = OvaleState:GetComputedSpellCD(spellId)
		if not actionCooldownStart or not actionCooldownDuration then
			Ovale:DebugPrint("unknown_spells", "No cooldown data for spell "..spellId)
		end

		local si = OvaleData:GetSpellInfo(spellId)
		if si then
			if si.stance and not OvaleStance:IsStance(si.stance) then
				return nil
			end

			if si.combo == 0 and OvaleState.state.combo == 0 then
				return nil
			end
			for k,v in pairs(OvaleData.secondaryPower) do
				if si[v] and si[v] > OvaleState.state[v] then
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
		end

		local spellName = OvaleData.spellList[spellId]
		if not spellName then
			spellName = API_GetSpellInfo(spellId)
		end
		actionTexture = API_GetSpellTexture(spellId)
		actionInRange = API_IsSpellInRange(spellName, target)
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
			Ovale:Log("Unknown macro "..element.params[1])
		end
	elseif (element.func=="item") then
		local itemId = element.params[1]
		if itemId and type(itemId) ~= "number" then
			itemId = OvaleEquipement:GetEquippedItem(itemId)
		end
		if not itemId then
			return nil
		end

		if (Ovale.trace) then
			Ovale:Print("Item "..tostring(itemId))
		end

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

function OvaleBestAction:Compute(element)
	if not element or (Ovale.bug and not Ovale.trace) then
		return nil
	end

	local visitor = OVALE_COMPUTE_VISITOR[element.type]
	if visitor then
		return visitor(element)
	end

	Ovale:Log("unknown element " .. element.type .. ", return nil")
	return nil
end

function OvaleBestAction:ComputeBool(element)
	local start, ending, priority, element = self:Compute(element)
	--Special case of a value element: it must not be 0
	if element and element.type == "value" and element.value == 0 and element.rate == 0 then
		return nil
	else
		return start, ending, priority, element
	end
end
--</public-static-methods>
