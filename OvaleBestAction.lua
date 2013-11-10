--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleBestAction = Ovale:NewModule("OvaleBestAction")
Ovale.OvaleBestAction = OvaleBestAction

--<private-static-properties>
local OvaleActionBar = Ovale.OvaleActionBar
local OvaleCondition = Ovale.OvaleCondition
local OvaleData = Ovale.OvaleData
local OvaleEquipement = Ovale.OvaleEquipement
local OvaleFuture = Ovale.OvaleFuture
local OvalePaperDoll = Ovale.OvalePaperDoll
local OvalePool = Ovale.OvalePool
local OvalePower = Ovale.OvalePower
local OvaleSpellBook = Ovale.OvaleSpellBook
local OvaleStance = Ovale.OvaleStance
local OvaleState = Ovale.OvaleState
local OvaleTimeSpan = Ovale.OvaleTimeSpan

local abs = math.abs
local floor = math.floor
local ipairs = ipairs
local loadstring = loadstring
local pairs = pairs
local select = select
local strfind = string.find
local tonumber = tonumber
local tostring = tostring
local wipe = table.wipe
local Complement = OvaleTimeSpan.Complement
local CopyTimeSpan = OvaleTimeSpan.CopyTo
local HasTime = OvaleTimeSpan.HasTime
local Intersect = OvaleTimeSpan.Intersect
local IntersectInterval = OvaleTimeSpan.IntersectInterval
local Measure = OvaleTimeSpan.Measure
local Union = OvaleTimeSpan.Union
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
-- Pool of time-span tables.
local self_pool = OvalePool("OvaleBestAction_pool")
--</private-static-properties>

--<private-static-methods>
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

local function ComputeAction(element)
	local self = OvaleBestAction
	local action = element.params[1]
	local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, spellId = self:GetActionInfo(element)
	local timeSpan = element.timeSpan
	timeSpan:Reset()

	if not actionTexture then
		Ovale:Logf("Action %s not found", action)
		return timeSpan
	elseif not (actionEnable and actionEnable > 0) then
		Ovale:Logf("Action %s not enabled", action)
		return timeSpan
	elseif element.params.usable == 1 and not actionUsable then
		Ovale:Logf("Action %s not usable", action)
		return timeSpan
	end

	-- Set the cast time of the action.
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
			Ovale:Logf("Action %s (toggle) is the current action", action)
			return timeSpan
		end
	else
		element.castTime = 0
	end

	-- If the action is not on cooldown, then treat it like it's immediately ready.
	local start
	if actionCooldownDuration and actionCooldownStart and actionCooldownStart > 0 then
		start = actionCooldownDuration + actionCooldownStart
	else
		start = OvaleState.currentTime
	end

	Ovale:Logf("start=%f attenteFinCast=%s [%d]", start, OvaleState.attenteFinCast, element.nodeId)

	-- If the action is available before the end of the current spellcast, then wait until we can first cast the action.
	if start < OvaleState.attenteFinCast then
		local si = OvaleState.currentSpellId and OvaleData.spellInfo[OvaleState.currentSpellId]
		if not (si and si.canStopChannelling) then
			-- not a channelled spell, or a channelled spell that cannot be interrupted
			start = OvaleState.attenteFinCast
		else
			-- This is a channelled spell that can be interrupted, so wait till the next tick.
			-- "canStopChannelling=N" means that there are N total ticks in the channelled spell.
			local numTicks, scaling
			if si.haste == "spell" then
				scaling = OvalePaperDoll:GetSpellHasteMultiplier()
			elseif si.haste == "melee" then
				scaling = OvalePaperDoll:GetMeleeHasteMultiplier()
			else
				scaling = 1
			end
			numTicks = floor(si.canStopChannelling * scaling + 0.5)
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
	Ovale:Logf("Action %s can start at %f", action, start)
	timeSpan[1], timeSpan[2] = start, math.huge

	--[[
		Allow for the return value of an to be "typecast" to a constant value by specifying
		asValue=1 as a parameter.

		Return 1 if the action is off of cooldown, or 0 if it is on cooldown.
	--]]
	local value
	if element.params.asValue and element.params.asValue == 1 then
		local atTime = OvaleState.currentTime
		if HasTime(timeSpan, atTime) then
			value = 1
		else
			value = 0
		end
		timeSpan[1], timeSpan[2] = 0, math.huge
	end

	local priority = element.params.priority or OVALE_DEFAULT_PRIORITY
	if value then
		return timeSpan, priority, PutValue(element, value, 0, 0)
	else
		return timeSpan, priority, element
	end
end

local function ComputeAnd(element)
	Ovale:Logf("%s [%d]", element.type, element.nodeId)
	local self = OvaleBestAction
	local timeSpanA = self:ComputeBool(element.a)
	local timeSpan = element.timeSpan

	-- Short-circuit evaluation of left argument to AND.
	if Measure(timeSpanA) == 0 then
		timeSpan:Reset(timeSpanA)
	else
		local timeSpanB = self:ComputeBool(element.b)
		-- Take intersection of A and B.
		timeSpan:Reset()
		Intersect(timeSpanA, timeSpanB, timeSpan)
	end
	Ovale:Logf("%s returns %s [%d]", element.type, tostring(timeSpan), element.nodeId)
	return timeSpan
end

local function ComputeArithmetic(element)
	local self = OvaleBestAction
	local timeSpanA, _, elementA = self:Compute(element.a)
	local timeSpanB, _, elementB = self:Compute(element.b)
	local timeSpan = element.timeSpan
	timeSpan:Reset()

	-- Take intersection of A and B.
	Intersect(timeSpanA, timeSpanB, timeSpan)
	if Measure(timeSpan) == 0 then
		Ovale:Logf("%s return %s [%d]", element.type, tostring(timeSpan), element.nodeId)
		return timeSpan, OVALE_DEFAULT_PRIORITY, PutValue(element, 0, 0, 0)
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
	local atTime = OvaleState.currentTime

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
			A(t) = A(t0) + (t - t0)*c = A + (t - t0)*c
			B(t) = B(t0) + (t - t0)*z = B + (t - t0)*z

			A(t) + B(t) = (A + B) + (t - t0)*(c + z)
		--]]
		l = A + B
		m = atTime
		n = c + z
	elseif element.operator == "-" then
		--[[
			A(t) = A(t0) + (t - t0)*c = A + (t - t0)*c
			B(t) = B(t0) + (t - t0)*z = B + (t - t0)*z

			A(t) - B(t) = (A - B) + (t - t0)*(c - z)
		--]]
		l = A - B
		m = atTime
		n = c - z
	elseif element.operator == "*" then
		--[[
				 A(t) = A(t0) + (t - t0)*c = A + (t - t0)*c
				 B(t) = B(t0) + (t - t0)*z = B + (t - t0)*z
			A(t)*B(t) = A*B + (t - t0)*[A*z + B*c] + [(t - t0)^2]*(c*z)
					  = A*B + (t - t0)*[A*z + B*c] + O(t^2) converges everywhere.
		--]]
			l = A*B
			m = atTime
			n = A*z + B*c
	elseif element.operator == "/" then
		--[[
				 A(t) = A(t0) + (t - t0)*c = A + (t - t0)*c
				 B(t) = B(t0) + (t - t0)*z = B + (t - t0)*z
			A(t)/B(t) = A/B + (t - t0)*[(B*c - A*z)/B^2] + O(t^2) converges when |t - t0| < |B/z|.
		--]]
		l = A/B
		m = atTime
		n = (B*c - A*z)/(B^2)
		local bound
		if z == 0 then
			bound = math.huge
		else
			bound = abs(B/z)
		end
		local scratch = OvaleTimeSpan(self_pool:Get())
		scratch:Reset(timeSpan)
		timeSpan:Reset()
		IntersectInterval(scratch, atTime - bound, atTime + bound, timeSpan)
		self_pool:Release(scratch)
	elseif element.operator == "%" then
		if c == 0 and z == 0 then
			l = A % B
			m = atTime
			n = 0
		else
			Ovale:Error("Parameters of % must be constants")
			l = 0
			m = 0
			n = 0
			timeSpan:Reset()
		end
	end
	Ovale:Logf("result = %f+(t-%f)*%f [%d]", l, m, n, element.nodeId)
	return timeSpan, OVALE_DEFAULT_PRIORITY, PutValue(element, l, m, n)
end

local function ComputeCompare(element)
	local self = OvaleBestAction
	local timeSpanA, _, elementA = self:Compute(element.a)
	local timeSpanB, _, elementB = self:Compute(element.b)
	local timeSpan = element.timeSpan
	timeSpan:Reset()

	-- Take intersection of A and B.
	Intersect(timeSpanA, timeSpanB, timeSpan)
	if Measure(timeSpan) == 0 then
		return timeSpan
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
	local operator = element.operator

	Ovale:Logf("%f+(t-%f)*%f %s %f+(t-%f)*%f [%d]", a, b, c, operator, x, y, z, element.nodeId)

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
		if not ((operator == "==" and A == B)
				or (operator == "<" and A < B)
				or (operator == "<=" and A <= B)
				or (operator == ">" and A > B)
				or (operator == ">=" and A >= B)) then
			timeSpan:Reset()
		end
	else
		local scratch = OvaleTimeSpan(self_pool:Get())
		scratch:Reset(timeSpan)
		timeSpan:Reset()
		local t = (B - A)/(c - z)
		t = (t > 0) and t or 0
		Ovale:Logf("t = %f", t)
		if (c > z and operator == "<")
				or (c > z and operator == "<=")
				or (c < z and operator == ">")
				or (c < z and operator == ">=") then
			IntersectInterval(scratch, 0, t, timeSpan)
		elseif (c < z and operator == "<")
				or (c < z and operator == "<=")
				or (c > z and operator == ">")
				or (c > z and operator == ">=") then
			IntersectInterval(scratch, t, math.huge, timeSpan)
		end
		self_pool:Release(scratch)
	end
	Ovale:Logf("compare %s returns %s [%d]", operator, tostring(timeSpan), element.nodeId)
	return timeSpan
end

local function ComputeCustomFunction(element)
	Ovale:Logf("custom function %s", element.name)
	local self = OvaleBestAction
	if not element.serial or element.serial < self_serial then
		-- Cache new values in element.
		element.timeSpanA, element.priorityA, element.elementA = self:Compute(element.a)
		element.serial = self_serial
	else
		Ovale:Logf("Using cached values for %s", element.name)
	end

	local timeSpanA, priorityA, elementA = element.timeSpanA, element.priorityA, element.elementA
	local timeSpan = element.timeSpan
	timeSpan:Reset()

	if element.params.asValue and element.params.asValue == 1 then
		--[[
			Allow for the return value of a custom function to be "typecast" to a constant value.

			If the return value is a time span (a "boolean" value), then if the current time of
			the simulation is within the time span, then return 1, or 0 otherwise.

			If the return value is a linear function, then if the current time of the simulation
			is within the function's domain, then the function is simply evaluated at the current
			time, or 0 otherwise.

			If the return value is an action, then return 1 if the action is off of cooldown, or
			0 if it is on cooldown.
		--]]
		local atTime = OvaleState.currentTime
		local value = 0
		if HasTime(timeSpanA, atTime) then
			if not elementA then	-- boolean
				value = 1
			elseif elementA.type == "value" then
				value = elementA.value + (atTime - elementA.origin) * elementA.rate
			elseif elementA.type == "action" then
				value = 1
			end
		end
		timeSpan[1], timeSpan[2] = 0, math.huge
		return timeSpan, priorityA, PutValue(element, value, 0, 0)
	else
		CopyTimeSpan(timeSpanA, timeSpan)
		return timeSpan, priorityA, elementA
	end
end

local function ComputeFunction(element)
	local self = OvaleBestAction
	local timeSpan = element.timeSpan
	timeSpan:Reset()

	if not OvaleCondition:IsCondition(element.func) then
		Ovale:Errorf("Condition %s not found", element.func)
		return timeSpan
	end

	local start, ending, value, origin, rate = OvaleCondition:EvaluateCondition(element.func, element.params)
	if start and ending then
		timeSpan[1], timeSpan[2] = start, ending
	end

	if Ovale.trace then
		local conditionCall = element.func .. "("
		for k, v in pairs(element.params) do
			conditionCall = conditionCall .. k .. "=" .. v .. ","
		end
		conditionCall = conditionCall .. ")"
		Ovale:FormatPrint("Condition %s returned %s, %s, %s, %s, %s", conditionCall, start, ending, value, origin, rate)
	end

	--[[
		Allow for the return value of a script condition to be "typecast" to a constant value
		by specifying asValue=1 as a script parameter.

		If the return value is a time span (a "boolean" value), then if the current time of
		the simulation is within the time span, then return 1, or 0 otherwise.

		If the return value is a linear function, then if the current time of the simulation
		is within the function's domain, then the function is simply evaluated at the current
		time, or 0 otherwise.
	--]]
	if element.params.asValue and element.params.asValue == 1 then
		local atTime = OvaleState.currentTime
		if HasTime(timeSpan, atTime) then
			if value then
				value = value + (atTime - origin) * rate
			else
				value = 1
			end
		else
			value = 0
		end
		origin, rate = 0, 0
		timeSpan[1], timeSpan[2] = 0, math.huge
	end

	if value then
		return timeSpan, OVALE_DEFAULT_PRIORITY, PutValue(element, value, origin, rate)
	else
		return timeSpan
	end
end

local function ComputeGroup(element)
	local self = OvaleBestAction
	local bestTimeSpan, bestPriority, bestElement, bestCastTime
	local timeSpan = element.timeSpan
	timeSpan:Reset()

	Ovale:Logf("%s [%d]", element.type, element.nodeId)

	if #element.nodes == 1 then
		return self:Compute(element.nodes[1])
	end

	local best = OvaleTimeSpan(self_pool:Get())
	local current = OvaleTimeSpan(self_pool:Get())

	for k, v in ipairs(element.nodes) do
		local currentTimeSpan, currentPriority, currentElement = self:Compute(v)
		-- We only care about actions that are available at time t > OvaleState.currentTime.
		current:Reset()
		IntersectInterval(currentTimeSpan, OvaleState.currentTime, math.huge, current)
		if Measure(current) > 0 then
			Ovale:Logf("    group checking %s [%d]", tostring(current), element.nodeId)
			local currentCastTime
			if currentElement then
				currentCastTime = currentElement.castTime
			end
			if not currentCastTime or currentCastTime < OvaleState.gcd then
				currentCastTime = OvaleState.gcd
			end

			local replace = false
			if Measure(best) == 0 then
				Ovale:Logf("    group first best %s [%d]", tostring(current), element.nodeId)
				replace = true
			elseif not currentPriority or not bestPriority or currentPriority == bestPriority then
				-- If the spells have the same priority, then pick the one with an earlier cast time.
				local threshold = (bestElement and bestElement.params) and bestElement.params.wait or 0
				if best[1] - current[1] > threshold then
					Ovale:Logf("    group new best %s [%d]", tostring(current), element.nodeId)
					replace = true
				end
			elseif currentPriority > bestPriority then
				-- If the current spell has a higher priority than the best one found, then choose the
				-- higher priority spell if its cast is pushed back too far by the lower priority one.
				local threshold = (currentElement and currentElement.params) and currentElement.params.wait or (bestCastTime * 0.75)
				if current[1] - best[1] < threshold then
					Ovale:Logf("    group new best (lower prio) %s [%d]", tostring(current), element.nodeId)
					replace = true
				end
			elseif currentPriority < bestPriority then
				-- If the current spell has a lower priority than the best one found, then choose the
				-- lower priority spell only if it doesn't push back the cast of the higher priority
				-- one by too much.
				local threshold = (bestElement and bestElement.params) and bestElement.params.wait or (currentCastTime * 0.75)
				if best[1] - current[1] > threshold then
					Ovale:Logf("    group new best (higher prio) %s [%d]", tostring(current), element.nodeId)
					replace = true
				end
			end
			if replace then
				best:Reset(current)
				bestTimeSpan = currentTimeSpan
				bestPriority = currentPriority
				bestElement = currentElement
				bestCastTime = currentCastTime
			end
			-- If the node is a "wait" node, then skip the remaining nodes.
			if currentElement and currentElement.wait then break end
		end
	end

	self_pool:Release(best)
	self_pool:Release(current)

	if not bestTimeSpan then
		Ovale:Logf("group return %s [%d]", tostring(timeSpan), element.nodeId)
		return timeSpan
	else
		CopyTimeSpan(bestTimeSpan, timeSpan)
		if bestElement then
			local id = bestElement.value
			if bestElement.params then
				id = bestElement.params[1]
			end
			Ovale:Logf("group best action %s remains %s [%d]", id, tostring(timeSpan), element.nodeId)
		else
			Ovale:Logf("group no best action returns %s [%d]", tostring(timeSpan), element.nodeId)
		end
		return timeSpan, bestPriority, bestElement
	end
end

local function ComputeIf(element)
	Ovale:Logf("%s [%d]", element.type, element.nodeId)
	local self = OvaleBestAction

	local timeSpanA = self:ComputeBool(element.a)
	local timeSpan = element.timeSpan
	timeSpan:Reset()

	local conditionTimeSpan = OvaleTimeSpan(self_pool:Get())
	if element.type == "if" then
		conditionTimeSpan:Reset(timeSpanA)
	elseif element.type == "unless" then
		-- "unless A B" is equivalent to "if (not A) B", so take the complement of A.
		Complement(timeSpanA, conditionTimeSpan)
	end
	-- Short-circuit evaluation of left argument to IF.
	if Measure(conditionTimeSpan) == 0 then
		timeSpan:Reset(conditionTimeSpan)
		self_pool:Release(conditionTimeSpan)
		Ovale:Logf("%s return %s [%d]", element.type, tostring(timeSpan), element.nodeId)
		return timeSpan, OVALE_DEFAULT_PRIORITY, PutValue(element, 0, 0, 0)
	end

	local timeSpanB, priorityB, elementB = self:Compute(element.b)
	-- If the "then" clause is a "wait" node, then only wait if the conditions are true.
	if elementB and elementB.wait and not HasTime(conditionTimeSpan, OvaleState.currentTime) then
		elementB.wait = nil
	end
	-- Take intersection of the condition and B.
	Intersect(conditionTimeSpan, timeSpanB, timeSpan)
	self_pool:Release(conditionTimeSpan)

	Ovale:Logf("%s return %s [%d]", element.type, tostring(timeSpan), element.nodeId)
	return timeSpan, priorityB, elementB
end

local function ComputeLua(element)
	local ret = loadstring(element.lua)()
	Ovale:Logf("lua %s [%d]", ret, element.nodeId)

	local timeSpan = element.timeSpan
	timeSpan:Reset()

	timeSpan[1], timeSpan[2] = 0, math.huge
	return timeSpan, OVALE_DEFAULT_PRIORITY, PutValue(element, ret, 0, 0)
end

local function ComputeNot(element)
	Ovale:Logf("%s [%d]", element.type, element.nodeId)
	local self = OvaleBestAction
	local timeSpanA = self:ComputeBool(element.a)
	local timeSpan = element.timeSpan
	timeSpan:Reset()

	Complement(timeSpanA, timeSpan)
	Ovale:Logf("%s returns %s [%d]", element.type, tostring(timeSpan), element.nodeId)
	return timeSpan
end

local function ComputeOr(element)
	Ovale:Logf("%s [%d]", element.type, element.nodeId)
	local self = OvaleBestAction
	local timeSpanA = self:ComputeBool(element.a)
	local timeSpanB = self:ComputeBool(element.b)
	local timeSpan = element.timeSpan
	timeSpan:Reset()

	-- Take union of A and B.
	Union(timeSpanA, timeSpanB, timeSpan)
	Ovale:Logf("%s returns %s [%d]", element.type, tostring(timeSpan), element.nodeId)
	return timeSpan
end

local function ComputeValue(element)
	Ovale:Logf("value %s", element.value)
	local timeSpan = element.timeSpan
	timeSpan:Reset()

	timeSpan[1], timeSpan[2] = 0, math.huge
	return timeSpan, OVALE_DEFAULT_PRIORITY, element
end

local function ComputeWait(element)
	Ovale:Logf("%s [%d]", element.type, element.nodeId)
	local self = OvaleBestAction
	local timeSpanA, priorityA, elementA = self:Compute(element.a)
	local timeSpan = element.timeSpan
	timeSpan:Reset()

	if elementA then
		elementA.wait = true
		CopyTimeSpan(timeSpanA, timeSpan)
		Ovale:Logf("%s return %s [%d]", element.type, tostring(timeSpan), element.nodeId)
	end
	return timeSpan, priorityA, elementA
end
--</private-static-methods>

--<private-static-properties>
local OVALE_COMPUTE_VISITOR =
{
	["action"] = ComputeAction,
	["and"] = ComputeAnd,
	["arithmetic"] = ComputeArithmetic,
	["compare"] = ComputeCompare,
	["customfunction"] = ComputeCustomFunction,
	["function"] = ComputeFunction,
	["group"] = ComputeGroup,
	["if"] = ComputeIf,
	["lua"] = ComputeLua,
	["not"] = ComputeNot,
	["or"] = ComputeOr,
	["unless"] = ComputeIf,
	["value"] = ComputeValue,
	["wait"] = ComputeWait,
}
--</private-static-properties>

--<public-static-methods>
function OvaleBestAction:StartNewAction()
	OvaleState:Reset()
	OvaleFuture:ApplyInFlightSpells()
	self_serial = self_serial + 1
end

function OvaleBestAction:GetActionInfo(element)
	if not element then
		return nil
	end

	local target = element.params.target or OvaleCondition.defaultTarget
	local action
	local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable

	if element.func == "spell" then
		local spellId = element.params[1]
		action = OvaleActionBar:GetForSpell(spellId)
		if not OvaleSpellBook:IsKnownSpell(spellId) and not action then
			Ovale:Logf("Spell %s not learnt", spellId)
			return nil
		end

		actionTexture = actionTexture or API_GetSpellTexture(spellId)
		actionInRange = API_IsSpellInRange(OvaleSpellBook:GetSpellName(spellId), target)
		actionCooldownStart, actionCooldownDuration, actionEnable = OvaleState:GetComputedSpellCD(spellId)

		-- Verify that the spell may be cast given restrictions specified in SpellInfo().
		local si = OvaleData.spellInfo[spellId]
		if si then
			if si.stance and not OvaleStance:IsStance(si.stance) then
				-- Spell requires a stance that player is not in.
				return nil
			end
			if si.combo == 0 then
				local minCombo = si.minCombo or 1
				if OvaleState.state.combo < minCombo then
					-- Spell is a combo point finisher, but player has too few combo points on the target.
					return nil
				end
			end
			for _, powerType in pairs(OvalePower.SECONDARY_POWER) do
				if si[powerType] and si[powerType] > OvaleState.state[powerType] then
					-- Spell requires "secondary" resources, e.g., chi, focus, rage, etc.,
					-- that the player does not have enough of.
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
			-- Use a custom texture if given.
			if si.texture then
				actionTexture = "Interface\\Icons\\" .. si.texture
			end
		end

		actionUsable = API_IsUsableSpell(spellId)

	elseif element.func == "macro" then
		local macro = element.params[1]
		action = OvaleActionBar:GetForMacro(macro)
		if not action then
			Ovale:Logf("Unknown macro %s", macro)
			return nil
		end
		actionTexture = API_GetActionTexture(action)
		actionInRange = API_IsActionInRange(action, target)
		actionCooldownStart, actionCooldownDuration, actionEnable = API_GetActionCooldown(action)
		actionUsable = API_IsUsableAction(action)

	elseif element.func == "item" then
		local itemId = element.params[1]
		if itemId and type(itemId) ~= "number" then
			itemId = OvaleEquipement:GetEquippedItem(itemId)
		end
		if not itemId then
			Ovale:Logf("Unknown item %s", element.params[1])
			return nil
		end
		Ovale:Logf("Item %s", itemId)
		action = OvaleActionBar:GetForItem(itemId)

		actionTexture = API_GetItemIcon(itemId)
		actionInRange = API_IsItemInRange(itemId, target)
		actionCooldownStart, actionCooldownDuration, actionEnable = API_GetItemCooldown(itemId)

		local spellName = API_GetItemSpell(itemId)
		actionUsable = (spellName ~= nil)

	elseif element.func == "texture" then
		local texture = element.params[1]
		actionTexture = "Interface\\Icons\\" .. texture
		actionInRange = nil
		actionCooldownStart = OvaleState.now
		actionCooldownDuration = 0
		actionEnable = 1
		actionUsable = true
	end

	if action then
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

	Ovale:Logf("unknown element %s, return nil", element.type)
	return nil
end

function OvaleBestAction:ComputeBool(element)
	local timeSpan, _, newElement = self:Compute(element)
	-- Match SimC: 0 is false, non-zero is true.
	--	(https://code.google.com/p/simulationcraft/wiki/ActionLists#Logical_operators)
	if newElement and newElement.type == "value" and newElement.value == 0 and newElement.rate == 0 then
		return nil
	else
		return timeSpan
	end
end
--</public-static-methods>
