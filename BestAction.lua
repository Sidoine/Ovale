--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleBestAction = Ovale:NewModule("OvaleBestAction", "AceEvent-3.0")
Ovale.OvaleBestAction = OvaleBestAction

--<private-static-properties>
local OvaleDebug = Ovale.OvaleDebug
local OvalePool = Ovale.OvalePool
local OvaleProfiler = Ovale.OvaleProfiler
local OvaleTimeSpan = Ovale.OvaleTimeSpan

-- Forward declarations for module dependencies.
local OvaleAST = nil
local OvaleActionBar = nil
local OvaleCompile = nil
local OvaleCondition = nil
local OvaleCooldown = nil
local OvaleData = nil
local OvaleEquipment = nil
local OvaleFuture = nil
local OvalePower = nil
local OvaleSpellBook = nil
local OvaleStance = nil

local abs = math.abs
local floor = math.floor
local ipairs = ipairs
local loadstring = loadstring
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local type = type
local wipe = wipe
local Complement = OvaleTimeSpan.Complement
local CopyTimeSpan = OvaleTimeSpan.CopyTo
local HasTime = OvaleTimeSpan.HasTime
local Intersect = OvaleTimeSpan.Intersect
local IntersectInterval = OvaleTimeSpan.IntersectInterval
local IsUniverse = OvaleTimeSpan.IsUniverse
local Measure = OvaleTimeSpan.Measure
local Union = OvaleTimeSpan.Union
local INFINITY = math.huge

local API_GetTime = GetTime
local API_GetActionCooldown = GetActionCooldown
local API_GetActionTexture = GetActionTexture
local API_GetItemIcon = GetItemIcon
local API_GetItemCooldown = GetItemCooldown
local API_GetItemSpell = GetItemSpell
local API_GetSpellTexture = GetSpellTexture
local API_IsActionInRange = IsActionInRange
local API_IsCurrentAction = IsCurrentAction
local API_IsItemInRange = IsItemInRange
local API_IsUsableAction = IsUsableAction
local API_IsUsableItem = IsUsableItem

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvaleBestAction)
-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleBestAction)

local OVALE_DEFAULT_PRIORITY = 3

-- Table of node types to visitor methods.
local COMPUTE_VISITOR = {
	["action"] = "ComputeAction",
	["arithmetic"] = "ComputeArithmetic",
	["compare"] = "ComputeCompare",
	["custom_function"] = "ComputeCustomFunction",
	["function"] = "ComputeFunction",
	["group"] = "ComputeGroup",
	["if"] = "ComputeIf",
	["logical"] = "ComputeLogical",
	["lua"] = "ComputeLua",
	["state"] = "ComputeState",
	["unless"] = "ComputeIf",
	["value"] = "ComputeValue",
	["wait"] = "ComputeWait",
}

-- Age of the current computation.
local self_serial = 0

-- Pool of time-span tables.
local self_timeSpanPool = OvalePool("OvaleBestAction_timeSpanPool")
-- timeSpan[node] = computed time span for that node.
local self_timeSpan = {}

-- Pool of value nodes for results.
local self_valuePool = OvalePool("OvaleBestAction_valuePool")
-- value[node] = result node of that node.
local self_value = {}

-- Static time-span variables.
local self_computedTimeSpan = OvaleTimeSpan()
local self_tempTimeSpan = OvaleTimeSpan()
--</private-static-properties>

--<private-static-methods>
local function SetValue(node, value, origin, rate)
	-- Re-use existing result.
	local result = self_value[node]
	if not result then
		result = self_valuePool:Get()
		self_value[node] = result
	end
	-- Overwrite any pre-existing values.
	result.type = "value"
	result.value = value or 0
	result.origin = origin or 0
	result.rate = rate or 0
	return result
end

local function GetTimeSpan(node)
	local timeSpan = self_timeSpan[node]
	if timeSpan then
		timeSpan:Reset()
	else
		timeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
		self_timeSpan[node] = timeSpan
	end
	return timeSpan
end

local function GetActionItemInfo(element, state, atTime, target)
	OvaleBestAction:StartProfiling("OvaleBestAction_GetActionItemInfo")

	local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId

	local itemId = element.positionalParams[1]
	if type(itemId) ~= "number" then
		itemId = OvaleEquipment:GetEquippedItem(itemId)
	end
	if not itemId then
		state:Log("Unknown item '%s'.", element.positionalParams[1])
	else
		state:Log("Item ID '%s'", itemId)
		local action = OvaleActionBar:GetForItem(itemId)
		local spellName = API_GetItemSpell(itemId)

		-- Use texture specified in the action if given.
		if element.namedParams.texture then
			actionTexture = "Interface\\Icons\\" .. element.namedParams.texture
		end
		actionTexture = actionTexture or API_GetItemIcon(itemId)
		actionInRange = API_IsItemInRange(itemId, target)
		actionCooldownStart, actionCooldownDuration, actionEnable = API_GetItemCooldown(itemId)
		actionUsable = spellName and API_IsUsableItem(itemId)
		if action then
			actionShortcut = OvaleActionBar:GetBinding(action)
			actionIsCurrent = API_IsCurrentAction(action)
		end
		actionType = "item"
		actionId = itemId
	end

	OvaleBestAction:StopProfiling("OvaleBestAction_GetActionItemInfo")
	return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end

local function GetActionMacroInfo(element, state, atTime, target)
	OvaleBestAction:StartProfiling("OvaleBestAction_GetActionMacroInfo")

	local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId

	local macro = element.positionalParams[1]
	local action = OvaleActionBar:GetForMacro(macro)
	if not action then
		state:Log("Unknown macro '%s'.", macro)
	else
		-- Use texture specified in the action if given.
		if element.namedParams.texture then
			actionTexture = "Interface\\Icons\\" .. element.namedParams.texture
		end
		actionTexture = actionTexture or API_GetActionTexture(action)
		actionInRange = API_IsActionInRange(action, target)
		actionCooldownStart, actionCooldownDuration, actionEnable = API_GetActionCooldown(action)
		actionUsable = API_IsUsableAction(action)
		actionShortcut = OvaleActionBar:GetBinding(action)
		actionIsCurrent = API_IsCurrentAction(action)
		actionType = "macro"
		actionId = macro
	end

	OvaleBestAction:StopProfiling("OvaleBestAction_GetActionMacroInfo")
	return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end

local function GetActionSpellInfo(element, state, atTime, target)
	OvaleBestAction:StartProfiling("OvaleBestAction_GetActionSpellInfo")

	local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId

	local spellId = element.positionalParams[1]
	local si = OvaleData.spellInfo[spellId]
	local replacedSpellId = nil
	if si and si.replace then
		local replacement = state:GetSpellInfoProperty(spellId, atTime, "replace", target)
		if replacement then
			replacedSpellId = spellId
			spellId = replacement
			si = OvaleData.spellInfo[spellId]
			state:Log("Spell ID '%s' is replaced by spell ID '%s'.", replacedSpellId, spellId)
		end
	end

	local action = OvaleActionBar:GetForSpell(spellId)
	if not action and replacedSpellId then
		state:Log("Action not found for spell ID '%s'; checking for replaced spell ID '%s'.", spellId, replacedSpellId)
		action = OvaleActionBar:GetForSpell(replacedSpellId)
	end
	local isKnownSpell = OvaleSpellBook:IsKnownSpell(spellId)
	if not isKnownSpell and replacedSpellId then
		state:Log("Spell ID '%s' is not known; checking for replaced spell ID '%s'.", spellId, replacedSpellId)
		isKnownSpell = OvaleSpellBook:IsKnownSpell(replacedSpellId)
	end

	if not isKnownSpell and not action then
		state:Log("Unknown spell ID '%s'.", spellId)
	else
		local isUsable, noMana = state:IsUsableSpell(spellId, atTime, target)
		if isUsable or noMana then
			-- Use texture specified in the action if given.
			if element.namedParams.texture then
				actionTexture = "Interface\\Icons\\" .. element.namedParams.texture
			end
			actionTexture = actionTexture or API_GetSpellTexture(spellId)
			actionInRange = OvaleSpellBook:IsSpellInRange(spellId, target)
			actionCooldownStart, actionCooldownDuration, actionEnable = state:GetSpellCooldown(spellId)
			actionUsable = isUsable
			if action then
				actionShortcut = OvaleActionBar:GetBinding(action)
				actionIsCurrent = API_IsCurrentAction(action)
			end
			actionType = "spell"
			actionId = spellId

			if si then
				-- Use texture specified in the SpellInfo() if given.
				if si.texture then
					actionTexture = "Interface\\Icons\\" .. si.texture
				end
				-- Extend the cooldown duration if the spell needs additional time to pool resources.
				if actionCooldownStart and actionCooldownDuration then
					local seconds = state:GetTimeToSpell(spellId, atTime, target)
					if seconds > 0 then
						local t = atTime + seconds
						if t > actionCooldownStart + actionCooldownDuration then
							if actionCooldownDuration > 0 then
								local extend = t - (actionCooldownStart + actionCooldownDuration)
								actionCooldownDuration = actionCooldownDuration + extend
								state:Log("Extending cooldown of spell ID '%s' for primary resource by %fs.", spellId, extend)
							else
								actionCooldownStart = t
								state:Log("Delaying spell ID '%s' for primary resource by %fs.", spellId, seconds)
							end
						end
					end
				end
			end
		end
	end

	OvaleBestAction:StopProfiling("OvaleBestAction_GetActionSpellInfo")
	return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end

local function GetActionTextureInfo(element, state, atTime, target)
	OvaleBestAction:StartProfiling("OvaleBestAction_GetActionTextureInfo")

	local actionTexture
	do
		local texture = element.positionalParams[1]
		local spellId = tonumber(texture)
		if spellId then
			actionTexture = API_GetSpellTexture(spellId)
		else
			actionTexture = "Interface\\Icons\\" .. texture
		end
	end
	local actionInRange = nil
	local actionCooldownStart = 0
	local actionCooldownDuration = 0
	local actionEnable = 1
	local actionUsable = true
	local actionShortcut = nil
	local actionIsCurrent = nil
	local actionType = "texture"
	local actionId = actionTexture

	OvaleBestAction:StopProfiling("OvaleBestAction_GetActionTextureInfo")
	return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end
--</private-static-methods>

--<public-static-methods>
function OvaleBestAction:OnInitialize()
	-- Resolve module dependencies.
	OvaleAST = Ovale.OvaleAST
	OvaleActionBar = Ovale.OvaleActionBar
	OvaleCompile = Ovale.OvaleCompile
	OvaleCondition = Ovale.OvaleCondition
	OvaleCooldown = Ovale.OvaleCooldown
	OvaleData = Ovale.OvaleData
	OvaleEquipment = Ovale.OvaleEquipment
	OvaleFuture = Ovale.OvaleFuture
	OvalePower = Ovale.OvalePower
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleStance = Ovale.OvaleStance
end

function OvaleBestAction:OnEnable()
	self:RegisterMessage("Ovale_ScriptChanged")
end

function OvaleBestAction:OnDisable()
	self:UnregisterMessage("Ovale_ScriptChanged")
end

function OvaleBestAction:Ovale_ScriptChanged()
	-- Clean-up tables that are referenced using obsolete nodes as keys.
	for node, timeSpan in pairs(self_timeSpan) do
		self_timeSpanPool:Release(timeSpan)
		self_timeSpan[node] = nil
	end
	for node, value in pairs(self_value) do
		self_valuePool:Release(value)
		self_value[node] = nil
	end
end

function OvaleBestAction:StartNewAction(state)
	state:Reset()
	OvaleFuture:ApplyInFlightSpells(state)
	self_serial = self_serial + 1
end

function OvaleBestAction:GetActionInfo(element, state, atTime)
	if element and element.type == "action" then
		-- Check for recently cached results from ComputeAction().
		if element.serial and element.serial >= self_serial then
			state:Log("[%d]    using cached result (age = %d)", element.nodeId, element.serial)
			return element.actionTexture,
				element.actionInRange,
				element.actionCooldownStart,
				element.actionCooldownDuration,
				element.actionUsable,
				element.actionShortcut,
				element.actionIsCurrent,
				element.actionEnable,
				element.actionType,
				element.actionId,
				element.actionTarget
		else
			local target = element.namedParams.target or state.defaultTarget
			if element.lowername == "item" then
				return GetActionItemInfo(element, state, atTime, target)
			elseif element.lowername == "macro" then
				return GetActionMacroInfo(element, state, atTime, target)
			elseif element.lowername == "spell" then
				return GetActionSpellInfo(element, state, atTime, target)
			elseif element.lowername == "texture" then
				return GetActionTextureInfo(element, state, atTime, target)
			end
		end
	end
	return nil
end

function OvaleBestAction:GetAction(node, state, atTime)
	self:StartProfiling("OvaleBestAction_GetAction")
	local groupNode = node.child[1]
	local timeSpan, priority, element = self:Compute(groupNode, state, atTime)
	self_computedTimeSpan:Reset(timeSpan)
	if element and element.type == "state" then
		-- Loop-count check to guard against infinite loops.
		local loopCount = 0
		while element and element.type == "state" do
			loopCount = loopCount + 1
			if loopCount >= 10 then
				self:Debug("Found too many SetState() actions -- probably an infinite loop in script.")
				break
			end
			-- Set the state in the simulator.
			local variable, value = element.positionalParams[1], element.positionalParams[2]
			local isFuture = not HasTime(self_computedTimeSpan, atTime)
			state:PutState(variable, value, isFuture)
			-- Get the cumulative intersection of time spans for these re-computations.
			self_tempTimeSpan:Reset(self_computedTimeSpan)
			self:StartNewAction(state)
			timeSpan, priority, element = self:Compute(groupNode, state, atTime)
			Intersect(self_tempTimeSpan, timeSpan, self_computedTimeSpan)
		end
	end
	self:StopProfiling("OvaleBestAction_GetAction")
	return self_computedTimeSpan, priority, element
end

function OvaleBestAction:PostOrderCompute(element, state, atTime)
	self:StartProfiling("OvaleBestAction_Compute")
	local timeSpan, priority, result

	-- Check for recently cached computation results if this is a node with a postOrder list.
	local postOrder = element.postOrder
	if postOrder and not (element.serial and element.serial >= self_serial) then
		local index = 1
		local N = #postOrder
		while index < N do
			local childNode, parentNode = postOrder[index], postOrder[index + 1]
			index = index + 2

			timeSpan, priority, result = self:PostOrderCompute(childNode, state, atTime)
			--[[
				Check for cases where short-circuit evaluation applies:

				1. Left child of IF node returns zero measure.
				2. Left child of UNLESS node returns universe.
				3. Left child of AND node returns zero measure.
				4. Left child of OR node returns universe.
			--]]
			if parentNode then
				local shortCircuit = false
				if parentNode.child and parentNode.child[1] == childNode then
					if parentNode.type == "if" and Measure(timeSpan) == 0 then
						state:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero-measure time span.", element.nodeId, childNode.type, parentNode.nodeId)
						shortCircuit = true
					elseif parentNode.type == "unless" and IsUniverse(timeSpan) then
						state:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId)
						shortCircuit = true
					elseif parentNode.type == "logical" and parentNode.operator == "and" and Measure(timeSpan) == 0 then
						state:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero measure.", element.nodeId, childNode.type, parentNode.nodeId)
						shortCircuit = true
					elseif parentNode.type == "logical" and parentNode.operator == "or" and IsUniverse(timeSpan) then
						state:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId)
						shortCircuit = true
					end
				end
				if shortCircuit then
					-- Traverse the postOrder array looking for the parent node.
					while parentNode ~= postOrder[index] and index <= N do
						index = index + 2
					end
					if index > N then
						self:Error("Ran off end of postOrder node list for node %d.", element.nodeId)
					end
				end
			end
		end
	end
	-- Compute the result for this node.
	timeSpan, priority, result = self:RecursiveCompute(element, state, atTime)
	self:StartProfiling("OvaleBestAction_Compute")
	return timeSpan, priority, result
end

function OvaleBestAction:RecursiveCompute(element, state, atTime)
	self:StartProfiling("OvaleBestAction_Compute")
	local timeSpan, priority, result
	if element then
		if element.asString then
			state:Log("[%d] >>> Computing '%s' at time=%f: %s", element.nodeId, element.type, atTime, element.asString)
		else
			state:Log("[%d] >>> Computing '%s' at time=%f", element.nodeId, element.type, atTime)
		end
		-- Check for recently cached computation results.
		if element.serial and element.serial >= self_serial then
			timeSpan = element.timeSpan
			priority = element.priority
			result = element.result
			state:Log("[%d]    using cached result (age = %d)", element.nodeId, element.serial)
		else
			local visitor = COMPUTE_VISITOR[element.type]
			if visitor and self[visitor] then
				timeSpan, priority, result = self[visitor](self, element, state, atTime)
				element.serial = self_serial
				element.timeSpan = timeSpan
				element.priority = priority
				element.result = result
			else
				state:Log("[%d] Runtime error: unable to compute node of type '%s'.", element.nodeId, element.type)
			end
		end
		if result and result.type == "value" then
			local value, origin, rate = result.value, result.origin, result.rate
			state:Log("[%d] <<< '%s' returns %s with value = %f, %f, %f", element.nodeId, element.type, tostring(timeSpan), value, origin, rate)
		elseif result and result.nodeId then
			state:Log("[%d] <<< '%s' returns [%d] %s", element.nodeId, element.type, result.nodeId, tostring(timeSpan))
		else
			state:Log("[%d] <<< '%s' returns %s", element.nodeId, element.type, tostring(timeSpan))
		end
	end
	self:StopProfiling("OvaleBestAction_Compute")
	return timeSpan, priority, result
end

function OvaleBestAction:ComputeBool(element, state, atTime)
	local timeSpan, _, newElement = self:Compute(element, state, atTime)
	-- Match SimulationCraft: 0 is false, non-zero is true.
	--	(https://code.google.com/p/simulationcraft/wiki/ActionLists#Logical_operators)
	if newElement and newElement.type == "value" and newElement.value == 0 and newElement.rate == 0 then
		return nil
	else
		return timeSpan
	end
end

function OvaleBestAction:ComputeAction(element, state, atTime)
	self:StartProfiling("OvaleBestAction_ComputeAction")
	local nodeId = element.nodeId
	local timeSpan = GetTimeSpan(element)
	local priority, result

	state:Log("[%d]    evaluating action: %s(%s)", nodeId, element.name, element.paramsAsString)
	local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget = self:GetActionInfo(element, state, atTime)

	-- Cache results for future GetActionInfo() when computation age has not advanced.
	element.actionTexture = actionTexture
	element.actionInRange = actionInRange
	element.actionCooldownStart = actionCooldownStart
	element.actionCooldownDuration = actionCooldownDuration
	element.actionUsable = actionUsable
	element.actionShortcut = actionShortcut
	element.actionIsCurrent = actionIsCurrent
	element.actionEnable = actionEnable
	element.actionType = actionType
	element.actionId = actionId
	element.actionTarget = actionTarget

	local action = element.positionalParams[1]
	if not actionTexture then
		state:Log("[%d]    Action %s not found.", nodeId, action)
	elseif not (actionEnable and actionEnable > 0) then
		state:Log("[%d]    Action %s not enabled.", nodeId, action)
	elseif element.namedParams.usable == 1 and not actionUsable then
		state:Log("[%d]    Action %s not usable.", nodeId, action)
	else
		-- Set the cast time of the action.
		local spellInfo
		if actionType == "spell" then
			local spellId = actionId
			spellInfo = spellId and OvaleData.spellInfo[spellId]
			if spellInfo and spellInfo.casttime then
				element.castTime = spellInfo.casttime
			else
				element.castTime = OvaleSpellBook:GetCastTime(spellId)
			end
		else
			element.castTime = 0
		end

		-- If the action is not on cooldown, then treat it like it's immediately ready.
		local start
		if actionCooldownStart and actionCooldownStart > 0 then
			-- Action is on cooldown.
			if actionCooldownDuration and actionCooldownDuration > 0 then
				state:Log("[%d]    Action %s is on cooldown (start=%f, duration=%f).", nodeId, action, actionCooldownStart, actionCooldownDuration)
				start = actionCooldownStart + actionCooldownDuration
			else
				state:Log("[%d]    Action %s is waiting on the GCD or resources (start=%f).", nodeId, action, actionCooldownStart)
				start = actionCooldownStart
			end
		else
			state:Log("[%d]    Action %s is off cooldown.", nodeId, action)
			start = state.currentTime
		end
		state:Log("[%d]    start=%f atTime=%s", nodeId, start, atTime)

		-- Set the "offgcd" flag in the element if it is a spell.
		local offgcd = element.namedParams.offgcd or (spellInfo and spellInfo.offgcd) or 0
		element.offgcd = (offgcd == 1) and true or nil

		-- If the action is available before the end of the current spellcast, then wait until we can first cast the action.
		if element.offgcd then
			state:Log("[%d]    Action %s is off the global cooldown.", nodeId, action)
		elseif start < atTime then
			state:Log("[%d]    Action %s is waiting for the global cooldown.", nodeId, action)
			-- Default to starting at the given time.
			local newStart = atTime
			--[[
				If we are channeling a spellcast, then see if it is interruptible; if so, then
				delay the start until after the next tick of the channeled spell.
			--]]
			if state:IsChanneling(atTime) then
				local spellId = state.currentSpellId
				local si = spellId and OvaleData.spellInfo[spellId]
				if si then
					-- "channel=N" means that the channel has N total ticks and can be interrupted.
					local channel = si.channel or si.canStopChannelling
					if channel then
						local hasteMultiplier = state:GetHasteMultiplier(si.haste)
						local numTicks = floor(channel * hasteMultiplier + 0.5)
						local tick = (state.endCast - state.startCast) / numTicks
						local tickTime = state.startCast
						for i = 1, numTicks do
							tickTime = tickTime + tick
							if newStart <= tickTime then
								break
							end
						end
						newStart = tickTime
						state:Log("[%d]    %s start=%f, numTicks=%d, tick=%f, tickTime=%f", nodeId, spellId, newStart, numTicks, tick, tickTime)
					end
				end
			end
			if start < newStart then
				start = newStart
			end
		end
		state:Log("[%d]    Action %s can start at %f.", nodeId, action, start)
		timeSpan[1], timeSpan[2] = start, INFINITY

		--[[
			Allow for the return value of an to be "typecast" to a constant value by specifying
			asValue=1 as a parameter.

			Return 1 if the action is off of cooldown, or 0 if it is on cooldown.
		--]]
		local value
		if element.namedParams.asValue == 1 then
			local value = HasTime(timeSpan, atTime) and 1 or 0
			result = SetValue(element, value)
			timeSpan[1], timeSpan[2] = 0, INFINITY
			state:Log("[%d]    Action %s typecast to value %f.", nodeId, action, value)
		else
			result = element
		end
		priority = element.namedParams.priority or OVALE_DEFAULT_PRIORITY
	end

	self:StopProfiling("OvaleBestAction_ComputeAction")
	return timeSpan, priority, result
end

function OvaleBestAction:ComputeArithmetic(element, state, atTime)
	self:StartProfiling("OvaleBestAction_Compute")
	local timeSpanA, _, elementA = self:Compute(element.child[1], state, atTime)
	local timeSpanB, _, elementB = self:Compute(element.child[2], state, atTime)
	local timeSpan = GetTimeSpan(element)
	local result

	-- Take intersection of A and B.
	Intersect(timeSpanA, timeSpanB, timeSpan)
	if Measure(timeSpan) == 0 then
		state:Log("[%d]    arithmetic '%s' returns %s with zero measure", element.nodeId, element.operator, tostring(timeSpan))
		result = SetValue(element, 0)
	else
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
		local t = atTime

		state:Log("[%d]    %f+(t-%f)*%f %s %f+(t-%f)*%f", element.nodeId, a, b, c, operator, x, y, z)

		-- result(t) = l + (t - m)*n
		local l, m, n

		--[[
			A(t) = a + (t - b)*c = a + (t - t0 + t0 - b)*c = [a + (t0 - b)*c] + (t - t0)*c = A(t0) + (t - t0)*c
			B(t) = x + (t - y)*z = x + (t - t0 + t0 - y)*z = [x + (t0 - y)*z] + (t - t0)*z = B(t0) + (t - t0)*z
		--]]
		local A = a + (t - b)*c
		local B = x + (t - y)*z

		if operator == "+" then
			--[[
				A(t) = A(t0) + (t - t0)*c = A + (t - t0)*c
				B(t) = B(t0) + (t - t0)*z = B + (t - t0)*z

				A(t) + B(t) = (A + B) + (t - t0)*(c + z)
			--]]
			l = A + B
			m = t
			n = c + z
		elseif operator == "-" then
			--[[
				A(t) = A(t0) + (t - t0)*c = A + (t - t0)*c
				B(t) = B(t0) + (t - t0)*z = B + (t - t0)*z

				A(t) - B(t) = (A - B) + (t - t0)*(c - z)
			--]]
			l = A - B
			m = t
			n = c - z
		elseif operator == "*" then
			--[[
					 A(t) = A(t0) + (t - t0)*c = A + (t - t0)*c
					 B(t) = B(t0) + (t - t0)*z = B + (t - t0)*z
				A(t)*B(t) = A*B + (t - t0)*[A*z + B*c] + [(t - t0)^2]*(c*z)
						  = A*B + (t - t0)*[A*z + B*c] + O(t^2) converges everywhere.
			--]]
				l = A*B
				m = t
				n = A*z + B*c
		elseif operator == "/" then
			--[[
					 A(t) = A(t0) + (t - t0)*c = A + (t - t0)*c
					 B(t) = B(t0) + (t - t0)*z = B + (t - t0)*z
				A(t)/B(t) = A/B + (t - t0)*[(B*c - A*z)/B^2] + O(t^2) converges when |t - t0| < |B/z|.
			--]]
			l = A/B
			m = t
			n = (B*c - A*z)/(B^2)
			local bound
			if z == 0 then
				bound = INFINITY
			else
				bound = abs(B/z)
			end
			local scratch = OvaleTimeSpan(self_timeSpanPool:Get())
			scratch:Reset(timeSpan)
			timeSpan:Reset()
			IntersectInterval(scratch, t - bound, t + bound, timeSpan)
			self_timeSpanPool:Release(scratch)
		elseif operator == "%" then
			if c == 0 and z == 0 then
				l = A % B
				m = t
				n = 0
			else
				self:Error("[%d]    Parameters of modulus operator '%' must be constants.", element.nodeId)
				l = 0
				m = 0
				n = 0
			end
		end
		state:Log("[%d]    arithmetic '%s' returns %f+(t-%f)*%f", element.nodeId, operator, l, m, n)
		result = SetValue(element, l, m, n)
	end
	self:StopProfiling("OvaleBestAction_Compute")
	return timeSpan, OVALE_DEFAULT_PRIORITY, result
end

function OvaleBestAction:ComputeCompare(element, state, atTime)
	self:StartProfiling("OvaleBestAction_Compute")
	local timeSpanA, _, elementA = self:Compute(element.child[1], state, atTime)
	local timeSpanB, _, elementB = self:Compute(element.child[2], state, atTime)
	local timeSpan = GetTimeSpan(element)

	-- Take intersection of A and B.
	Intersect(timeSpanA, timeSpanB, timeSpan)
	if Measure(timeSpan) == 0 then
		state:Log("[%d]    compare '%s' returns %s with zero measure", element.nodeId, element.operator, tostring(timeSpan))
	else
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

		state:Log("[%d]    %f+(t-%f)*%f %s %f+(t-%f)*%f", element.nodeId, a, b, c, operator, x, y, z)

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
					or (operator == "!=" and A ~= B)
					or (operator == "<" and A < B)
					or (operator == "<=" and A <= B)
					or (operator == ">" and A > B)
					or (operator == ">=" and A >= B)) then
				timeSpan:Reset()
			end
		else
			local scratch = OvaleTimeSpan(self_timeSpanPool:Get())
			scratch:Reset(timeSpan)
			timeSpan:Reset()
			local t = (B - A)/(c - z)
			t = (t > 0) and t or 0
			state:Log("[%d]    intersection at t = %f", element.nodeId, t)
			if (c > z and operator == "<")
					or (c > z and operator == "<=")
					or (c < z and operator == ">")
					or (c < z and operator == ">=") then
				IntersectInterval(scratch, 0, t, timeSpan)
			elseif (c < z and operator == "<")
					or (c < z and operator == "<=")
					or (c > z and operator == ">")
					or (c > z and operator == ">=") then
				IntersectInterval(scratch, t, INFINITY, timeSpan)
			end
			self_timeSpanPool:Release(scratch)
		end
		state:Log("[%d]    compare '%s' returns %s", element.nodeId, operator, tostring(timeSpan))
	end
	self:StopProfiling("OvaleBestAction_Compute")
	return timeSpan
end

function OvaleBestAction:ComputeCustomFunction(element, state, atTime)
	self:StartProfiling("OvaleBestAction_Compute")
	local timeSpan = GetTimeSpan(element)
	local priority, result

	local node = OvaleCompile:GetFunctionNode(element.name)
	if node then
		state:Log("[%d]    evaluating function: %s(%s)", element.nodeId, node.name, node.paramsAsString)
		local timeSpanA, priorityA, elementA = self:Compute(node.child[1], state, atTime)
		if element.namedParams.asValue == 1 or node.namedParams.asValue == 1 then
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
			state:Log("[%d]    function '%s' typecast to value %f", element.nodeId, element.name, value)
			timeSpan[1], timeSpan[2] = 0, INFINITY
			result = SetValue(element, value)
		else
			CopyTimeSpan(timeSpanA, timeSpan)
			result = elementA
		end
	end

	self:StopProfiling("OvaleBestAction_Compute")
	return timeSpan, priority, result
end

function OvaleBestAction:ComputeFunction(element, state, atTime)
	self:StartProfiling("OvaleBestAction_ComputeFunction")
	local timeSpan = GetTimeSpan(element)
	local priority, result

	state:Log("[%d]    evaluating condition: %s(%s)", element.nodeId, element.name, element.paramsAsString)
	local start, ending, value, origin, rate = OvaleCondition:EvaluateCondition(element.func, element.positionalParams, element.namedParams, state, atTime)
	if start and ending then
		timeSpan[1], timeSpan[2] = start, ending
	end
	state:Log("[%d]    condition '%s' returns %s, %s, %s, %s, %s", element.nodeId, element.name, start, ending, value, origin, rate)

	--[[
		Allow for the return value of a script condition to be "typecast" to a constant value
		by specifying asValue=1 as a script parameter.

		If the return value is a time span (a "boolean" value), then if the current time of
		the simulation is within the time span, then return 1, or 0 otherwise.

		If the return value is a linear function, then if the current time of the simulation
		is within the function's domain, then the function is simply evaluated at the current
		time, or 0 otherwise.
	--]]
	if element.namedParams.asValue == 1 then
		if HasTime(timeSpan, atTime) then
			if value then
				value = value + (atTime - origin) * rate
			else
				value = 1
			end
		else
			value = 0
		end
		result = SetValue(element, value)
		timeSpan[1], timeSpan[2] = 0, INFINITY
		priority = OVALE_DEFAULT_PRIORITY
		state:Log("[%d]    condition '%s' typecast to value %f", element.nodeId, element.name, value)
	elseif value then
		result = SetValue(element, value, origin, rate)
	end

	self:StopProfiling("OvaleBestAction_ComputeFunction")
	return timeSpan, priority, result
end

function OvaleBestAction:ComputeGroup(element, state, atTime)
	self:StartProfiling("OvaleBestAction_Compute")
	local bestTimeSpan, bestPriority, bestElement, bestCastTime
	local timeSpan = GetTimeSpan(element)

	local best = OvaleTimeSpan(self_timeSpanPool:Get())
	local current = OvaleTimeSpan(self_timeSpanPool:Get())

	for _, node in ipairs(element.child) do
		local currentTimeSpan, currentPriority, currentElement = self:Compute(node, state, atTime)
		-- We only care about actions that are available at time t > atTime.
		current:Reset()
		IntersectInterval(currentTimeSpan, atTime, INFINITY, current)
		if Measure(current) > 0 then
			state:Log("[%d]    group checking %s", element.nodeId, tostring(current))
			local currentCastTime
			if currentElement then
				currentCastTime = currentElement.castTime
			end
			local gcd = state:GetGCD()
			if not currentCastTime or currentCastTime < gcd then
				currentCastTime = gcd
			end

			local currentIsBetter = false
			if Measure(best) == 0 then
				state:Log("[%d]    group first best is %s", element.nodeId, tostring(current))
				currentIsBetter = true
			elseif not currentPriority or not bestPriority or currentPriority == bestPriority then
				-- If the spells have the same priority, then pick the one with an earlier cast time.
				local threshold = (bestElement and bestElement.namedParams) and bestElement.namedParams.wait or 0
				if best[1] - current[1] > threshold then
					state:Log("[%d]    group new best is %s", element.nodeId, tostring(current))
					currentIsBetter = true
				end
			elseif currentPriority > bestPriority then
				-- If the current spell has a higher priority than the best one found, then choose the
				-- higher priority spell if its cast is pushed back too far by the lower priority one.
				local threshold = (currentElement and currentElement.namedParams) and currentElement.namedParams.wait or (bestCastTime * 0.75)
				if current[1] - best[1] < threshold then
					state:Log("[%d]    group new best (lower prio) is %s", element.nodeId, tostring(current))
					currentIsBetter = true
				end
			elseif currentPriority < bestPriority then
				-- If the current spell has a lower priority than the best one found, then choose the
				-- lower priority spell only if it doesn't push back the cast of the higher priority
				-- one by too much.
				local threshold = (bestElement and bestElement.namedParams) and bestElement.namedParams.wait or (currentCastTime * 0.75)
				if best[1] - current[1] > threshold then
					state:Log("[%d]    group new best (higher prio) is %s", element.nodeId, tostring(current))
					currentIsBetter = true
				end
			end
			if currentIsBetter then
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

	self_timeSpanPool:Release(best)
	self_timeSpanPool:Release(current)

	CopyTimeSpan(bestTimeSpan, timeSpan)
	if bestElement then
		local id = bestElement.value
		if bestElement.positionalParams then
			id = bestElement.positionalParams[1]
		end
		state:Log("[%d]    group best action %s remains %s", element.nodeId, id, tostring(timeSpan))
	else
		state:Log("[%d]    group no best action returns %s", element.nodeId, tostring(timeSpan))
	end

	self:StopProfiling("OvaleBestAction_Compute")
	return timeSpan, bestPriority, bestElement
end

function OvaleBestAction:ComputeIf(element, state, atTime)
	self:StartProfiling("OvaleBestAction_Compute")
	local timeSpanA = self:ComputeBool(element.child[1], state, atTime)
	local timeSpan = GetTimeSpan(element)
	local priority, result
	local conditionTimeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
	if element.type == "if" then
		conditionTimeSpan:Reset(timeSpanA)
	elseif element.type == "unless" then
		-- "unless A B" is equivalent to "if (not A) B", so take the complement of A.
		Complement(timeSpanA, conditionTimeSpan)
	end
	-- Short-circuit evaluation of left argument to IF.
	if Measure(conditionTimeSpan) == 0 then
		timeSpan:Reset(conditionTimeSpan)
		state:Log("[%d]    '%s' returns %s with zero measure", element.nodeId, element.type, tostring(timeSpan))
		priority = OVALE_DEFAULT_PRIORITY
		result = SetValue(element, 0)
	else
		local timeSpanB, priorityB, elementB = self:Compute(element.child[2], state, atTime)
		-- If the "then" clause is a "wait" node, then only wait if the conditions are true.
		if elementB and elementB.wait and not HasTime(conditionTimeSpan, atTime) then
			elementB.wait = nil
		end
		-- Take intersection of the condition and B.
		Intersect(conditionTimeSpan, timeSpanB, timeSpan)
		state:Log("[%d]    '%s' returns %s", element.nodeId, element.type, tostring(timeSpan))
		priority = priorityB
		result = elementB
	end
	self_timeSpanPool:Release(conditionTimeSpan)

	self:StopProfiling("OvaleBestAction_Compute")
	return timeSpan, priority, result
end

function OvaleBestAction:ComputeLogical(element, state, atTime)
	self:StartProfiling("OvaleBestAction_Compute")
	local timeSpanA = self:ComputeBool(element.child[1], state, atTime)
	local timeSpan = GetTimeSpan(element)

	if element.operator == "and" then
		-- Short-circuit evaluation of left argument to AND.
		if Measure(timeSpanA) == 0 then
			timeSpan:Reset(timeSpanA)
			state:Log("[%d]    logical '%s' short-circuits with zero measure left argument", element.nodeId, element.operator)
		else
			local timeSpanB = self:ComputeBool(element.child[2], state, atTime)
			-- Take intersection of A and B.
			Intersect(timeSpanA, timeSpanB, timeSpan)
		end
	elseif element.operator == "not" then
		Complement(timeSpanA, timeSpan)
	elseif element.operator == "or" then
		-- Short-circuit evaluation of left argument to OR.
		if IsUniverse(timeSpanA) then
			timeSpan:Reset(timeSpanA)
			state:Log("[%d]    logical '%s' short-circuits with universe as left argument", element.nodeId, element.operator)
		else
			local timeSpanB = self:ComputeBool(element.child[2], state, atTime)
			-- Take union of A and B.
			Union(timeSpanA, timeSpanB, timeSpan)
		end
	elseif element.operator == "xor" then
		-- A xor B = (A and not B) or (not A and B)
		local timeSpanB = self:ComputeBool(element.child[2], state, atTime)
		local left = OvaleTimeSpan(self_timeSpanPool:Get())
		local right = OvaleTimeSpan(self_timeSpanPool:Get())
		local scratch = OvaleTimeSpan(self_timeSpanPool:Get())
		Complement(timeSpanB, scratch)
		Intersect(timeSpanA, scratch, left)
		Complement(timeSpanA, scratch)
		Intersect(scratch, timeSpanB, right)
		Union(left, right, timeSpan)
		self_timeSpanPool:Release(left)
		self_timeSpanPool:Release(right)
		self_timeSpanPool:Release(scratch)
	end

	state:Log("[%d]    logical '%s' returns %s", element.nodeId, element.operator, tostring(timeSpan))
	self:StopProfiling("OvaleBestAction_Compute")
	return timeSpan
end

function OvaleBestAction:ComputeLua(element, state, atTime)
	self:StartProfiling("OvaleBestAction_ComputeLua")
	local value = loadstring(element.lua)()
	state:Log("[%d]    lua returns %s", element.nodeId, value)

	local timeSpan = GetTimeSpan(element)
	local priority, result
	if value then
		timeSpan[1], timeSpan[2] = 0, INFINITY
		result = SetValue(element, value)
		priority = OVALE_DEFAULT_PRIORITY
	end
	self:StopProfiling("OvaleBestAction_ComputeLua")
	return timeSpan, priority, result
end

function OvaleBestAction:ComputeState(element, state, atTime)
	self:StartProfiling("OvaleBestAction_Compute")
	local timeSpan = GetTimeSpan(element)
	local result

	if element.func == "setstate" then
		state:Log("[%d]    %s: %s = %s", element.nodeId, element.name, element.positionalParams[1], element.positionalParams[2])
		timeSpan[1], timeSpan[2] = 0, INFINITY
		result = element
	end
	self:StopProfiling("OvaleBestAction_Compute")
	return timeSpan, OVALE_DEFAULT_PRIORITY, result
end

function OvaleBestAction:ComputeValue(element, state, atTime)
	self:StartProfiling("OvaleBestAction_Compute")
	state:Log("[%d]    value is %s", element.nodeId, element.value)
	local timeSpan = GetTimeSpan(element)
	timeSpan[1], timeSpan[2] = 0, INFINITY
	self:StopProfiling("OvaleBestAction_Compute")
	return timeSpan, OVALE_DEFAULT_PRIORITY, element
end

function OvaleBestAction:ComputeWait(element, state, atTime)
	self:StartProfiling("OvaleBestAction_Compute")
	local timeSpanA, priorityA, elementA = self:Compute(element.child[1], state, atTime)
	local timeSpan = GetTimeSpan(element)

	if elementA then
		elementA.wait = true
		CopyTimeSpan(timeSpanA, timeSpan)
		state:Log("[%d]    '%s' returns %s", element.nodeId, element.type, tostring(timeSpan))
	end
	self:StopProfiling("OvaleBestAction_Compute")
	return timeSpan, priorityA, elementA
end
--</public-static-methods>

--<public-static-properties>
OvaleBestAction.Compute = OvaleBestAction.PostOrderCompute
--</public-static-properties>
