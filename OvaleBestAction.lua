OvaleBestAction = {}

--<private-static-methods>
local function nilstring(text)
	if text == nil then
		return "nil"
	else
		return text
	end
end

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

local function maxTime(time1, time2)
	if isAfter(time1, time2) then
		return time1
	else
		return time2
	end
end

--</private-static-methods>

--<public-static-methods>
function OvaleBestAction:StartNewAction()
	OvaleState:Reset()
	OvaleFuture:Apply()
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
		
		actionCooldownStart, actionCooldownDuration, actionEnable = OvaleData:GetComputedSpellCD(spellId)
		
		local si = OvaleData:GetSpellInfo(spellId)
		if si then
			if si.stance and si.stance > 0 and GetShapeshiftForm()~=si.stance then
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
			if si.blood or si.frost or si.unholy or si.death then
				local runecd = OvaleState:GetRunes(si.blood, si.frost, si.unholy, si.death, false)
				if runecd > actionCooldownStart + actionCooldownDuration then
					actionCooldownDuration = runecd - actionCooldownStart
				end
			end
		end
		
		spellName = OvaleData.spellList[spellId]
		if not spellName then
			spellName = GetSpellInfo(spellId)
		end
		actionTexture = GetSpellTexture(spellId)
		actionInRange = IsSpellInRange(spellName, target)
		actionUsable = IsUsableSpell(spellId)
		actionShortcut = nil
	elseif (element.func=="macro") then
		action = OvaleActionBar:GetForMacro(element.params[1])
		if action then
			actionTexture = GetActionTexture(action)
			actionInRange = IsActionInRange(action, target)
			actionCooldownStart, actionCooldownDuration, actionEnable = GetActionCooldown(action)
			actionUsable = IsUsableAction(action)
			actionShortcut = OvaleActionBar:GetBinding(action)
			actionIsCurrent = IsCurrentAction(action)
		else
			Ovale:Log("Unknown macro "..element.params[1])
		end
	elseif (element.func=="item") then
		local itemId
		if (type(element.params[1]) == "number") then
			itemId = element.params[1]
		else
			local _,_,id = string.find(GetInventoryItemLink("player",GetInventorySlotInfo(element.params[1])) or "","item:(%d+):%d+:%d+:%d+")
			if not id then
				return nil
			end
			itemId = tonumber(id)
		end
		
		if (Ovale.trace) then
			Ovale:Print("Item "..nilstring(itemId))
		end

		local spellName = GetItemSpell(itemId)
		actionUsable = (spellName~=nil)
		
		action = OvaleActionBar:GetForItem(itemId)
		actionTexture = GetItemIcon(itemId)
		actionInRange = IsItemInRange(itemId, target)
		actionCooldownStart, actionCooldownDuration, actionEnable = GetItemCooldown(itemId)
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
			actionUsable = IsUsableAction(action)
		end
		actionShortcut = OvaleActionBar:GetBinding(action)
		actionIsCurrent = IsCurrentAction(action)
	end
	
	local cd = OvaleState:GetCD(spellId)
	if cd and cd.toggle then
		actionIsCurrent = 1
	end
	
	return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
					actionUsable, actionShortcut, actionIsCurrent, actionEnable, spellId, target, element.params.nored
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

function OvaleBestAction:Compute(element)
	if (Ovale.bug and not Ovale.trace) then
		return nil
	end
	
	if (not element) then
		return nil
	end
	
	--TODO: créer un objet par type au lieu de ce if else if tout moche
	if (element.type=="function")then
		if (element.func == "spell" or element.func=="macro" or element.func=="item" or element.func=="texture") then
			local action
			local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
				actionUsable, actionShortcut, actionIsCurrent, actionEnable, spellId = self:GetActionInfo(element)
			
			if not actionTexture then
				if (Ovale.trace) then
					Ovale:Print("Action "..element.params[1].." not found")
				end
				return nil
			end
			if element.params.usable==1 and not actionUsable then
				if (Ovale.trace) then
					Ovale:Print("Action "..element.params[1].." not usable")
				end
				return nil
			end
			if spellId and OvaleData.spellInfo[spellId] and OvaleData.spellInfo[spellId].casttime then
				element.castTime = OvaleData.spellInfo[spellId].casttime
			elseif spellId then
				local spell, rank, icon, cost, isFunnel, powerType, castTime = GetSpellInfo(spellId)
				if castTime then
					element.castTime = castTime/1000
				else
					element.castTime = nil
				end
			else
				element.castTime = 0
			end
			--TODO: not useful anymore?
			if (spellId and OvaleData.spellInfo[spellId] and OvaleData.spellInfo[spellId].toggle and actionIsCurrent) then
				if (Ovale.trace) then
					Ovale:Print("Action "..element.params[1].." is current action")
				end
				return nil
			end
			if actionEnable and actionEnable>0 then
				local restant
				if (not actionCooldownDuration or actionCooldownStart==0) then
					restant = OvaleState.currentTime
				else
					restant = actionCooldownDuration + actionCooldownStart
				end
				Ovale:Log("restant = "..restant.." attenteFinCast="..nilstring(OvaleState.attenteFinCast))
				if restant<OvaleState.attenteFinCast then
					if	not OvaleData.spellInfo[OvaleState.currentSpellId] or
							not OvaleData.spellInfo[OvaleState.currentSpellId].canStopChannelling then
						restant = OvaleState.attenteFinCast
					else
						--TODO: pas exact, parce que si ce sort est reporté de par exemple 0,5s par un debuff
						--ça tombera entre deux ticks
						local ticks = floor(OvaleAura.spellHaste * OvaleData.spellInfo[OvaleState.currentSpellId].canStopChannelling + 0.5)
						local tickLength = (OvaleState.attenteFinCast - OvaleState.startCast) / ticks
						local tickTime = OvaleState.startCast + tickLength
						if (Ovale.trace) then
							Ovale:Print(spellName.." restant = " .. restant)
							Ovale:Print("ticks = "..ticks.." tickLength="..tickLength.." tickTime="..tickTime)
						end	
						for i=1,ticks do
							if restant<=tickTime then
								restant = tickTime
								break
							end
							tickTime = tickTime + tickLength
						end
						if (Ovale.trace) then
							Ovale:Print(spellId.." restant = " .. restant)
						end	
					end
				end
				if (Ovale.trace) then
					Ovale:Print("Action "..element.params[1].." remains "..restant)
				end
				local retourPriorite = element.params.priority
				if (not retourPriorite) then
					retourPriorite = 3
				end
				return restant, nil, retourPriorite, element
			else
				if (Ovale.trace) then
					Ovale:Print("Action "..element.params[1].." not enabled")
				end
			end
		else
			local classe = OvaleCondition.conditions[element.func]
			if (not classe) then
				Ovale.bug = true
				Ovale:Print("Function "..element.func.." not found")
				return nil
			end
			local start, ending, value, origin, rate = classe(element.params)
			
			if (Ovale.trace) then
				local parameterList = element.func.."("
				for k,v in pairs(element.params) do
					parameterList = parameterList..k.."="..v..","
				end
				Ovale:Print("Function "..parameterList..") returned "..nilstring(start)..","..nilstring(ending)..","..nilstring(value)..","..nilstring(origin)..","..nilstring(rate))
			end
			
			if value  then
				if not element.result then
					element.result = { type = "value" }
				end
				local result = element.result
				result.value = value
				result.origin = origin
				result.rate = rate
				return start, ending, 3, result
			else
				return start, ending
			end
		end
	elseif element.type == "time" then
		return element.value
	elseif element.type == "value" then
		Ovale:Log("value " .. element.value)
		return 0, nil, 3, element
	elseif element.type == "after" then
		local timeA = self:Compute(element.time)
		local startA, endA = self:Compute(element.a)
		return addTime(startA, timeA), addTime(endA, timeA)
	elseif (element.type == "before") then
		if (Ovale.trace) then
			--Ovale:Print(nilstring(element.time).."s before ["..element.nodeId.."]")
		end
		local timeA = self:Compute(element.time)
		local startA, endA = self:Compute(element.a)
		return addTime(startA, -timeA), addTime(endA, -timeA)
	elseif (element.type == "between") then
		Ovale:Log("between")
		local tempsA = self:Compute(element.a)
		local tempsB = self:Compute(element.b)
		if tempsB==nil and tempsA==nil then
			Ovale:Log("diff returns 0 because the two nodes are nil")
			return 0
		end
		
		if tempsA==nil or tempsB==nil then
			if Ovale.trace then Ovale:Print(element.type.." return nil") end
			return nil
		end
		local diff
		if tempsA>tempsB then
			diff = tempsA - tempsB
		else
			diff = tempsB - tempsA
		end
		Ovale:Log("diff returns "..diff)
		return diff
	elseif element.type == "fromuntil" then
		Ovale:Log("fromuntil")
		local tempsA = self:Compute(element.a)
		if (tempsA==nil) then
			if Ovale.trace then Ovale:Print(element.type.." return nil") end
			return nil
		end
		local tempsB = self:Compute(element.b)
		if (tempsB==nil) then
			if Ovale.trace then Ovale:Print(element.type.." return nil") end
			return nil
		end
		Ovale:Log("fromuntil returns "..(tempsB - tempsA))
		return tempsB - tempsA
	elseif element.type == "compare" then
		Ovale:Log("compare "..element.comparison)
		local tempsA = self:Compute(element.a)
		local timeB = self:Compute(element.time)
		Ovale:Log(nilstring(tempsA).." "..element.comparison.." "..nilstring(timeB))
		if element.comparison == "more" and (not tempsA or tempsA>timeB) then
			if Ovale.trace then Ovale:Print(element.type.." return 0") end
			return 0
		elseif element.comparison == "less" and tempsA and tempsA<timeB then
			if Ovale.trace then Ovale:Print(element.type.." return 0") end
			return 0
		elseif element.comparison == "at most" and tempsA and tempsA<=timeB then
			if Ovale.trace then Ovale:Print(element.type.." return 0") end
			return 0
		elseif element.comparison == "at least" and (not tempsA or tempsA>=timeB) then
			if Ovale.trace then Ovale:Print(element.type.." return 0") end
			return 0
		end
		return nil
	elseif element.type == "and" or element.type == "if" then
		if (Ovale.trace) then
			Ovale:Print(element.type.." ["..element.nodeId.."]")
		end
		local startA, endA, prioriteA, elementA = self:ComputeBool(element.a)
		if (startA==nil) then
			if Ovale.trace then Ovale:Print(element.type.." return nil  ["..element.nodeId.."]") end
			return nil
		end
		if startA == endA then
			if Ovale.trace then Ovale:Print(element.type.." return startA=endA  ["..element.nodeId.."]") end
			return nil
		end
	
		local startB, endB, prioriteB, elementB
		if element.type == "if" then
			startB, endB, prioriteB, elementB = self:Compute(element.b)
		else
			startB, endB, prioriteB, elementB = self:ComputeBool(element.b)
		end
		if isAfter(startB, endA) or isAfter(startA, endB) then
			if Ovale.trace then Ovale:Print(element.type.." return nil ["..element.nodeId.."]") end
			return nil
		end
		if isBefore(startB, startA) then
			startB = startA
		end
		if isAfter(endB, endA) then
			endB = endA
		end
		if Ovale.trace then
			Ovale:Print(element.type.." return "..nilstring(startB)..","..nilstring(endB).." ["..element.nodeId.."]")
		end
		return startB, endB, prioriteB, elementB
	elseif element.type == "unless" then
		if Ovale.trace then
			Ovale:Print(element.type)
		end
		local startA, endA = self:ComputeBool(element.a)
		local startB, endB, prioriteB, elementB = self:Compute(element.b)
		
		if isBeforeEqual(startA, startB) and isAfterEqual(endA, endB) then
			if Ovale.trace then Ovale:Print(element.type.." return nil") end
			return nil
		end
		
		if isAfterEqual(startA, startB) and isBefore(endA, endB) then
			if Ovale.trace then Ovale:Print(element.type.." return "..nilstring(endA)..","..nilstring(endB)) end
			return endA, endB, prioriteB, elementB
		end
		
		if isAfter(startA, startB) and isBefore(startA, endB) then
			endB = startA
		end
		
		if isAfter(endA, startB) and isBefore(endA, endB) then
			startB = endA
		end
					
		if Ovale.trace then Ovale:Print(element.type.." return "..nilstring(startB)..","..nilstring(endB)) end
		return startB, endB, prioriteB, elementB
	elseif element.type == "not" then
		local startA, endA = self:ComputeBool(element.a)
		if startA then
			return endA, nil
		else
			return 0, nil
		end
	elseif element.type == "or" then
		if Ovale.trace then
			Ovale:Print(element.type)
		end
		
		local startA, endA = self:ComputeBool(element.a)
		local startB, endB = self:ComputeBool(element.b)
		if isBefore(endA,OvaleState.currentTime) then
			return startB,endB
		elseif isBefore(endB,OvaleState.currentTime) then
			return startA,endA
		end		
		
		if isBefore(endA,startB) then
			return startA,endA
		elseif isBefore(endB,startA) then
			return startB,endB
		end
				
		if isBefore(startA, startB) then
			startB = startA
		end
		if isAfter(endA, endB) then
			endB = endA
		end
		return startB, endB
	elseif element.type == "operator" then
		local startA, endA, prioA, elementA = self:Compute(element.a)
		local startB, endB, prioB, elementB = self:Compute(element.b)
		--if not elementA or not elementB then
		--	Ovale:Log("operator " .. element.operator .. ": elementA or elementB is nil")
		--	return nil
		--end
		
		local a,b,c,x,y,z
		
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
			startA = 0; endA = nil;	a = 0; b = 0; c= 0
		end
		if startB == endB then
			startB = 0; endB = nil; x =0; y =0; z =0
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
		
		Ovale:Log(a.."+(t-"..b..")*"..c.. element.operator..x.."+(t-"..y..")*"..z)
		
		local l, m, n
		
		if element.operator == "*" then
			if c == 0 then
				l = a*x
				m = y
				n = a*z
			elseif z == 0 then
				l = x*a; m = b; n = x*c
			else
				Ovale:Print("ERROR: at least one value must be constant when multiplying")
				Ovale.bug = true
			end
		elseif element.operator == "+" then
			if c+z == 0 then
				l = a+x; m = 0; n = 0
			else
				l = a+x; m = (b*c+y*z)/(c+z); n = c+z
			end
		elseif element.operator == '-' then
			if c-z == 0 then
				l = a-x; m = 0; n = 0
			else
				l = a-x; m = (b*c-y*z)/(c-z); n = c-z
			end
		elseif element.operator == '/' then
			if z == 0 then
				l = a/x; m = b; n = c/x
			else
				Ovale:Print("ERROR: second value of / must be constant")
				Ovale.bug = true
			end
		elseif element.operator == '%' then
			if c == 0 and z == 0 then
				l = c % z; m = 0; n = 0
			else
				Ovale:Error("Parameters of % must be constants")
			end
		elseif element.operator == '<' then
			-- a + (t-b)*c = x + (t-y)*z
			-- (t-b)*c - (t-y)*z = x - a
			-- t*c - b*c - t*z + y*z = x - a
			-- t*(c-z) = x - a + b*c - y*z
			-- t = (x-a + b*c - y*z)/(c-z)
			if c == z then
				if a-b*c < x-y*z then
					return startA, endA
				else
					return nil
				end
			else
				local t = (x-a + b*c - y*z)/(c-z)
				if c > z then
					return startA, minTime(endA, t)
				else
					return maxTime(startA, t), endA
				end
			end
		elseif element.operator == '<=' then
			if c == z then
				if a - b*c <= x-y*z then return startA, endA else return nil end
			else
				local t = (x-a + b*c - y*z)/(c-z)
				if c > z then return startA, minTime(endA, t) else return maxTime(startA, t), endA end
			end		
		elseif element.operator == '>' then
			if c == z then
				if a-b*c > x-y*z then
					return startA, endA
				else
					return nil
				end
			else
				local t = (x-a + b*c - y*z)/(c-z)
				if c < z then
					return startA, minTime(endA, t)
				else
					return maxTime(startA, t), endA
				end
			end
		elseif element.operator == '==' then
			if c == z then
				if a - b*c == x-y*z then return startA,endA else return nil end
			else
				return nil
			end
		elseif element.operator == '>=' then
			if c == z then
				if a - b*c >= x-y*z then return startA, endA else return nil end
			else
				local t = (x-a + b*c - y*z)/(c-z)
				if c < z then return startA, minTime(endA, t) else return maxTime(startA, t), endA end
			end		
		end
		if not element.result then
			element.result = { type = "value" }
		end
		local result = element.result
		result.value = l
		result.origin = m
		result.rate = n
		Ovale:Log("result = " .. l .." + "..m.."*"..n)
		return startA, endA, 3, result
	elseif element.type == "lua" then
		local ret = loadstring(element.lua)()
		Ovale:Log("lua "..nilstring(ret))
		if not element.result then
			element.result = { type = "value" }
		end
		local result = element.result
		result.value = ret
		result.origin = 0
		result.rate = 0
		return 0, nil, 3, result
	elseif (element.type == "group") then
		local meilleurTempsFils
		local bestEnd
		local meilleurePrioriteFils
		local bestElement
		local bestCastTime
		 
		if (Ovale.trace) then
			Ovale:Print(element.type.." ["..element.nodeId.."]")
		end
		
		if #element.nodes == 1 then
			return self:Compute(element.nodes[1])
		end
		
		for k, v in ipairs(element.nodes) do
			local newStart, newEnd, priorite, nouveauElement = self:Compute(v)
			if newStart~=nil and newStart<OvaleState.currentTime then
				newStart = OvaleState.currentTime
			end

			
			if newStart and (not newEnd or newStart<=newEnd) then
				local remplacer

				local newCastTime
				if nouveauElement then
					newCastTime = nouveauElement.castTime
				end
				if not newCastTime or newCastTime < OvaleState.gcd then
					newCastTime = OvaleState.gcd
				end
			
				if (not meilleurTempsFils) then
					remplacer = true
				else
					-- temps maximum entre le nouveau sort et le précédent
					local maxEcart
					if (priorite and not meilleurePrioriteFils) then
						Ovale.bug = true
						Ovale:Print("Internal error: meilleurePrioriteFils=nil and priorite="..priorite)
						return nil
					end
					if (priorite and priorite > meilleurePrioriteFils) then
						-- Si le nouveau sort est plus prioritaire que le précédent, on le lance
						-- si caster le sort actuel repousse le nouveau sort
						maxEcart = bestCastTime*0.75
					elseif (priorite and priorite < meilleurePrioriteFils) then
						-- A l'inverse, si il est moins prioritaire que le précédent, on ne le lance
						-- que si caster le nouveau sort ne repousse pas le meilleur
						maxEcart = -newCastTime*0.75
					else
						maxEcart = -0.01
					end
					if (newStart-meilleurTempsFils < maxEcart) then
						remplacer = true
					end
				end
				if (remplacer) then
					meilleurTempsFils = newStart
					meilleurePrioriteFils = priorite
					bestElement = nouveauElement
					bestEnd = newEnd
					bestCastTime = newCastTime
				end
			end
		end
		
		if (meilleurTempsFils) then
			if (Ovale.trace) then
				if bestElement then
					Ovale:Print("group best action "..bestElement.params[1].." remains "..meilleurTempsFils..","..nilstring(bestEnd).." ["..element.nodeId.."]")
				else
					Ovale:Print("group no best action returns "..meilleurTempsFils..","..nilstring(bestEnd).." ["..element.nodeId.."]")
				end
			end
			return meilleurTempsFils, bestEnd, meilleurePrioriteFils, bestElement
		else
			if (Ovale.trace) then Ovale:Print("group return nil") end
			return nil
		end
	end
	if (Ovale.trace) then Ovale:Print("unknown element "..element.type..", return nil") end
	return nil
end
--</public-static-methods>
