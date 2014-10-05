--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleBestAction = Ovale:NewModule("OvaleBestAction", "AceEvent-3.0")
Ovale.OvaleBestAction = OvaleBestAction

--<private-static-properties>
local OvalePool = Ovale.OvalePool
local OvaleTimeSpan = Ovale.OvaleTimeSpan

-- Forward declarations for module dependencies.
local OvaleAST = nil
local OvaleActionBar = nil
local OvaleCompile = nil
local OvaleCondition = nil
local OvaleCooldown = nil
local OvaleData = nil
local OvaleEquipement = nil
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
local wipe = table.wipe
local Complement = OvaleTimeSpan.Complement
local CopyTimeSpan = OvaleTimeSpan.CopyTo
local HasTime = OvaleTimeSpan.HasTime
local Intersect = OvaleTimeSpan.Intersect
local IntersectInterval = OvaleTimeSpan.IntersectInterval
local Measure = OvaleTimeSpan.Measure
local Union = OvaleTimeSpan.Union

local API_GetTime = GetTime
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
local API_IsUsableItem = IsUsableItem

-- Profiling set-up.
local Profiler = Ovale.Profiler
local profiler = nil
do
	local group = OvaleBestAction:GetName()

	local function EnableProfiling()
		API_GetActionCooldown = Profiler:Wrap(group, "OvaleBestAction_API_GetActionCooldown", GetActionCooldown)
		API_GetActionTexture = Profiler:Wrap(group, "OvaleBestAction_API_GetActionTexture", GetActionTexture)
		API_GetItemIcon = Profiler:Wrap(group, "OvaleBestAction_API_GetItemIcon", GetItemIcon)
		API_GetItemCooldown = Profiler:Wrap(group, "OvaleBestAction_API_GetItemCooldown", GetItemCooldown)
		API_GetItemSpell = Profiler:Wrap(group, "OvaleBestAction_API_GetItemSpell", GetItemSpell)
		API_GetSpellInfo = Profiler:Wrap(group, "OvaleBestAction_API_GetSpellInfo", GetSpellTexture)
		API_GetSpellTexture = Profiler:Wrap(group, "OvaleBestAction_API_GetSpellTexture", GetSpellTexture)
		API_IsActionInRange = Profiler:Wrap(group, "OvaleBestAction_API_IsActionInRange", IsActionInRange)
		API_IsCurrentAction = Profiler:Wrap(group, "OvaleBestAction_API_IsCurrentAction", IsCurrentAction)
		API_IsItemInRange = Profiler:Wrap(group, "OvaleBestAction_API_IsItemInRange", IsItemInRange)
		API_IsSpellInRange = Profiler:Wrap(group, "OvaleBestAction_API_IsSpellInRange", IsSpellInRange)
		API_IsUsableAction = Profiler:Wrap(group, "OvaleBestAction_API_IsUsableAction", IsUsableAction)
		API_IsUsableItem = Profiler:Wrap(group, "OvaleBestAction_API_IsUsableItem", IsUsableItem)
	end

	local function DisableProfiling()
		API_GetTime = GetTime
		API_GetActionCooldown = GetActionCooldown
		API_GetActionTexture = GetActionTexture
		API_GetItemIcon = GetItemIcon
		API_GetItemCooldown = GetItemCooldown
		API_GetItemSpell = GetItemSpell
		API_GetSpellInfo = GetSpellInfo
		API_GetSpellTexture = GetSpellTexture
		API_IsActionInRange = IsActionInRange
		API_IsCurrentAction = IsCurrentAction
		API_IsItemInRange = IsItemInRange
		API_IsSpellInRange = IsSpellInRange
		API_IsUsableAction = IsUsableAction
		API_IsUsableItem = IsUsableItem
	end

	Profiler:RegisterProfilingGroup(group, EnableProfiling, DisableProfiling)
	profiler = Profiler:GetProfilingGroup(group)
end

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

local function GetActionItemInfo(element, state, target)
	profiler.Start("OvaleBestAction_GetActionItemInfo")

	local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId

	local itemId = element.params[1]
	if type(itemId) ~= "number" then
		itemId = OvaleEquipement:GetEquippedItem(itemId)
	end
	if not itemId then
		Ovale:Logf("Unknown item '%s'.", element.params[1])
	else
		Ovale:Logf("Item ID '%s'", itemId)
		local action = OvaleActionBar:GetForItem(itemId)
		local spellName = API_GetItemSpell(itemId)

		-- Use texture specified in the action if given.
		if element.params.texture then
			actionTexture = "Interface\\Icons\\" .. element.params.texture
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

	profiler.Stop("OvaleBestAction_GetActionItemInfo")
	return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end

local function GetActionMacroInfo(element, state, target)
	profiler.Start("OvaleBestAction_GetActionMacroInfo")

	local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId

	local macro = element.params[1]
	local action = OvaleActionBar:GetForMacro(macro)
	if not action then
		Ovale:Logf("Unknown macro '%s'.", macro)
	else
		-- Use texture specified in the action if given.
		if element.params.texture then
			actionTexture = "Interface\\Icons\\" .. element.params.texture
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

	profiler.Stop("OvaleBestAction_GetActionMacroInfo")
	return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end

local function GetActionSpellInfo(element, state, target)
	profiler.Start("OvaleBestAction_GetActionSpellInfo")

	local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId

	local spellId = element.params[1]
	local action = OvaleActionBar:GetForSpell(spellId)
	if not OvaleSpellBook:IsKnownSpell(spellId) and not action then
		Ovale:Logf("Unknown spell ID '%s'.", spellId)
	else
		-- Use texture specified in the action if given.
		if element.params.texture then
			actionTexture = "Interface\\Icons\\" .. element.params.texture
		end
		actionTexture = actionTexture or API_GetSpellTexture(spellId)
		actionInRange = API_IsSpellInRange(OvaleSpellBook:GetSpellName(spellId), target)
		actionCooldownStart, actionCooldownDuration, actionEnable = state:GetSpellCooldown(spellId)
		actionUsable = OvaleSpellBook:IsUsableSpell(spellId)
		if action then
			actionShortcut = OvaleActionBar:GetBinding(action)
			actionIsCurrent = API_IsCurrentAction(action)
		end
		actionType = "spell"
		actionId = spellId

		local si = OvaleData.spellInfo[spellId]
		if si then
			-- Verify that the spell may be cast given restrictions specified in SpellInfo().
			local meetsRequirements = true
			if si.stance and not OvaleStance:IsStance(si.stance) then
				Ovale:Logf("Spell ID '%s' requires the player to be in stance '%s'", spellId, si.stance)
				meetsRequirements = false
			end
			if meetsRequirements and si.combo then
				-- Spell requires combo points.
				local cost = state:ComboPointCost(spellId)
				if cost > 0 and state.combo < cost then
					Ovale:Logf("Spell ID '%s' requires at least %d combo points.", spellId, cost)
					meetsRequirements = false
				end
			end
			if meetsRequirements then
				for powerType in pairs(OvalePower.SECONDARY_POWER) do
					if si[powerType] then
						-- Spell requires "secondary" resources, e.g., chi, focus, rage, etc.,
						local cost = state:PowerCost(spellId, powerType)
						if cost > 0 and state[powerType] < cost then
							Ovale:Logf("Spell ID '%s' requires at least %d %s.", spellId, cost, powerType)
							meetsRequirements = false
							break
						end
					end
				end
			end

			-- Fix spell cooldown information using primary resource requirements specified in SpellInfo().
			if actionCooldownStart and actionCooldownDuration then
				-- Get the maximum time before all "primary" resources are ready.
				local atTime = state.currentTime
				for powerType in pairs(OvalePower.PRIMARY_POWER) do
					if si[powerType] then
						local t = state.currentTime + state:TimeToPower(spellId, powerType)
						if atTime < t then
							atTime = t
						end
					end
				end
				if actionCooldownStart > 0 then
					if atTime > actionCooldownStart + actionCooldownDuration then
						Ovale:Logf("Delaying spell ID '%s' for primary resource.", spellId)
						actionCooldownDuration = atTime - actionCooldownStart
					end
				else
					actionCooldownStart = state.currentTime
					actionCooldownDuration = atTime - actionCooldownStart
				end

				if si.blood or si.frost or si.unholy or si.death then
					-- Spell requires runes.
					local needRunes = true
					-- "buff_runes_none" is the spell ID of the buff that makes casting the spell cost no runes.
					local buffNoRunes = si.buff_runes_none
					if buffNoRunes then
						local aura = state:GetAura("player", buffNoRunes)
						if state:IsActiveAura(aura) then
							needRunes = false
						end
					end
					if needRunes then
						local ending = state.currentTime + state:GetRunesCooldown(si.blood, si.unholy, si.frost, si.death)
						if ending > actionCooldownStart + actionCooldownDuration then
							actionCooldownDuration = ending - actionCooldownStart
						end
					end
				end
			end

			-- Use texture specified in the SpellInfo() if given.
			if si.texture then
				actionTexture = "Interface\\Icons\\" .. si.texture
			end

			if not meetsRequirements then
				-- Assign all return values to nil.
				actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
					actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target = nil
			end
		end
	end

	profiler.Stop("OvaleBestAction_GetActionSpellInfo")
	return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end

local function GetActionTextureInfo(element, state, target)
	profiler.Start("OvaleBestAction_GetActionTextureInfo")

	local texture = element.params[1]
	local actionTexture = "Interface\\Icons\\" .. texture
	local actionInRange = nil
	local actionCooldownStart = 0
	local actionCooldownDuration = 0
	local actionEnable = 1
	local actionUsable = true
	local actionShortcut = nil
	local actionIsCurrent = nil
	local actionType = "texture"
	local actionId = texture

	profiler.Stop("OvaleBestAction_GetActionTextureInfo")
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
	OvaleEquipement = Ovale.OvaleEquipement
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

function OvaleBestAction:GetActionInfo(element, state)
	if element and element.type == "action" then
		local target = element.params.target or OvaleCondition.defaultTarget
		if element.lowername == "item" then
			return GetActionItemInfo(element, state, target)
		elseif element.lowername == "macro" then
			return GetActionMacroInfo(element, state, target)
		elseif element.lowername == "spell" then
			return GetActionSpellInfo(element, state, target)
		elseif element.lowername == "texture" then
			return GetActionTextureInfo(element, state, target)
		end
	end
	return nil
end

function OvaleBestAction:GetAction(node, state)
	local timeSpan, priority, element = self:Compute(node.child[1], state)
	self_computedTimeSpan:Reset(timeSpan)
	if element and element.type == "state" then
		-- Loop-count check to guard against infinite loops.
		local loopCount = 0
		while element and element.type == "state" do
			loopCount = loopCount + 1
			if loopCount >= 10 then
				Ovale:Error("Found too many SetState() actions -- probably an infinite loop in script.")
				break
			end
			-- Set the state in the simulator.
			local variable, value = element.params[1], element.params[2]
			local isFuture = not HasTime(computedTimeSpan, state.currentTime)
			state:PutState(variable, value, isFuture)
			-- Get the cumulative intersection of time spans for these re-computations.
			self_tempTimeSpan:Reset(self_computedTimeSpan)
			timeSpan, priority, element = self:Compute(node.child[1], state)
			Intersect(self_tempTimeSpan, timeSpan, self_computedTimeSpan)
		end
	end
	return self_computedTimeSpan, priority, element
end

function OvaleBestAction:Compute(element, state)
	local timeSpan, priority, result
	if element then
		if element.asString then
			Ovale:Logf("[%d] >>> Computing '%s': %s", element.nodeId, element.type, element.asString)
		else
			Ovale:Logf("[%d] >>> Computing '%s'", element.nodeId, element.type)
		end
		-- Check for recently cached computation results.
		if element.serial and element.serial >= self_serial then
			timeSpan = element.timeSpan
			priority = element.priority
			result = element.result
			Ovale:Logf("[%d]    using cached result (age = %d)", element.nodeId, element.serial)
		else
			local visitor = COMPUTE_VISITOR[element.type]
			if visitor and self[visitor] then
				timeSpan, priority, result = self[visitor](self, element, state)
				element.serial = self_serial
				element.timeSpan = timeSpan
				element.priority = priority
				element.result = result
			else
				Ovale:Logf("[%d] Runtime error: unable to compute node of type '%s'.", element.nodeId, element.type)
			end
		end
		if result and result.type == "value" then
			local value, origin, rate = result.value, result.origin, result.rate
			Ovale:Logf("[%d] <<< '%s' returns %s with value = %f, %f, %f", element.nodeId, element.type, tostring(timeSpan), value, origin, rate)
		elseif result and result.nodeId then
			Ovale:Logf("[%d] <<< '%s' returns [%d] %s", element.nodeId, element.type, result.nodeId, tostring(timeSpan))
		else
			Ovale:Logf("[%d] <<< '%s' returns %s", element.nodeId, element.type, tostring(timeSpan))
		end
	end
	return timeSpan, priority, result
end

function OvaleBestAction:ComputeBool(element, state)
	local timeSpan, _, newElement = self:Compute(element, state)
	-- Match SimulationCraft: 0 is false, non-zero is true.
	--	(https://code.google.com/p/simulationcraft/wiki/ActionLists#Logical_operators)
	if newElement and newElement.type == "value" and newElement.value == 0 and newElement.rate == 0 then
		return nil
	else
		return timeSpan
	end
end

function OvaleBestAction:ComputeAction(element, state)
	profiler.Start("OvaleBestAction_ComputeAction")
	local nodeId = element.nodeId
	local timeSpan = GetTimeSpan(element)
	local priority, result

	Ovale:Logf("[%d]    evaluating action: %s(%s)", element.nodeId, element.name, element.paramsAsString)
	local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
		actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId = self:GetActionInfo(element, state)

	local action = element.params[1]
	if not actionTexture then
		Ovale:Logf("[%s]    Action %s not found.", nodeId, action)
	elseif not (actionEnable and actionEnable > 0) then
		Ovale:Logf("[%s]    Action %s not enabled.", nodeId, action)
	elseif element.params.usable == 1 and not actionUsable then
		Ovale:Logf("[%s]    Action %s not usable.", nodeId, action)
	else
		-- Set the cast time of the action.
		if actionType == "spell" then
			local spellId = actionId
			local si = spellId and OvaleData.spellInfo[spellId]
			if si and si.casttime then
				element.castTime = si.casttime
			else
				local _, _, _, _, _, _, castTime = API_GetSpellInfo(spellId)
				if castTime then
					element.castTime = castTime / 1000
				else
					element.castTime = nil
				end
			end
		else
			element.castTime = 0
		end

		-- If the action is not on cooldown, then treat it like it's immediately ready.
		local start
		if actionCooldownDuration and actionCooldownStart and actionCooldownStart > 0 then
			start = actionCooldownDuration + actionCooldownStart
		else
			start = state.currentTime
		end

		Ovale:Logf("[%d]    start=%f nextCast=%s", nodeId, start, state.nextCast)

		-- If the action is available before the end of the current spellcast, then wait until we can first cast the action.
		if start < state.nextCast then
			-- Default to starting at next available cast time.
			local newStart = state.nextCast
			-- If we are currently channeling a spellcast, then see if it is interruptible.
			-- If we are allowed to interrupt it, then start after the next tick of the channel.
			if state.isChanneling then
				local spellId = state.currentSpellId
				local si = spellId and OvaleData.spellInfo[spellId]
				if si then
					-- "channel=N" means that the channel has N total ticks and can be interrupted.
					local channel = si.channel or si.canStopChannelling
					if channel then
						local hasteMultiplier = 1
						if si.haste == "spell" then
							hasteMultiplier = state:GetSpellHasteMultiplier()
						elseif si.haste == "melee" then
							hasteMultiplier = state:GetMeleeHasteMultiplier()
						end
						local numTicks = floor(channel * hasteMultiplier + 0.5)
						local tick = (state.nextCast - state.startCast) / numTicks
						local tickTime = state.startCast
						for i = 1, numTicks do
							tickTime = tickTime + tick
							if start <= tickTime then
								break
							end
						end
						newStart = tickTime
						Ovale:Logf("[%d]    %s start=%f, numTicks=%d, tick=%f, tickTime=%f", nodeId, spellId, newStart, numTicks, tick, tickTime)
					end
				end
			end
			start = newStart
		end
		Ovale:Logf("[%d]    Action %s can start at %f.", nodeId, action, start)
		timeSpan[1], timeSpan[2] = start, math.huge

		--[[
			Allow for the return value of an to be "typecast" to a constant value by specifying
			asValue=1 as a parameter.

			Return 1 if the action is off of cooldown, or 0 if it is on cooldown.
		--]]
		local value
		if element.params.asValue == 1 then
			local atTime = state.currentTime
			local value = HasTime(timeSpan, atTime) and 1 or 0
			result = SetValue(element, value)
			timeSpan[1], timeSpan[2] = 0, math.huge
			Ovale:Logf("[%d]    Action %s typecast to value %f.", nodeId, action, value)
		else
			result = element
		end
		priority = element.params.priority or OVALE_DEFAULT_PRIORITY
	end

	profiler.Stop("OvaleBestAction_ComputeAction")
	return timeSpan, priority, result
end

function OvaleBestAction:ComputeArithmetic(element, state)
	profiler.Start("OvaleBestAction_Compute")
	local timeSpanA, _, elementA = self:Compute(element.child[1], state)
	local timeSpanB, _, elementB = self:Compute(element.child[2], state)
	local timeSpan = GetTimeSpan(element)
	local result

	-- Take intersection of A and B.
	Intersect(timeSpanA, timeSpanB, timeSpan)
	if Measure(timeSpan) == 0 then
		Ovale:Logf("[%d]    arithmetic '%s' returns %s with zero measure", element.nodeId, element.operator, tostring(timeSpan))
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
		local atTime = state.currentTime

		Ovale:Logf("[%d]    %f+(t-%f)*%f %s %f+(t-%f)*%f", element.nodeId, a, b, c, operator, x, y, z)

		-- result(t) = l + (t - m)*n
		local l, m, n

		--[[
			A(t) = a + (t - b)*c = a + (t - t0 + t0 - b)*c = [a + (t0 - b)*c] + (t - t0)*c = A(t0) + (t - t0)*c
			B(t) = x + (t - y)*z = x + (t - t0 + t0 - y)*z = [x + (t0 - y)*z] + (t - t0)*z = B(t0) + (t - t0)*z
		--]]
		local A = a + (atTime - b)*c
		local B = x + (atTime - y)*z

		if operator == "+" then
			--[[
				A(t) = A(t0) + (t - t0)*c = A + (t - t0)*c
				B(t) = B(t0) + (t - t0)*z = B + (t - t0)*z

				A(t) + B(t) = (A + B) + (t - t0)*(c + z)
			--]]
			l = A + B
			m = atTime
			n = c + z
		elseif operator == "-" then
			--[[
				A(t) = A(t0) + (t - t0)*c = A + (t - t0)*c
				B(t) = B(t0) + (t - t0)*z = B + (t - t0)*z

				A(t) - B(t) = (A - B) + (t - t0)*(c - z)
			--]]
			l = A - B
			m = atTime
			n = c - z
		elseif operator == "*" then
			--[[
					 A(t) = A(t0) + (t - t0)*c = A + (t - t0)*c
					 B(t) = B(t0) + (t - t0)*z = B + (t - t0)*z
				A(t)*B(t) = A*B + (t - t0)*[A*z + B*c] + [(t - t0)^2]*(c*z)
						  = A*B + (t - t0)*[A*z + B*c] + O(t^2) converges everywhere.
			--]]
				l = A*B
				m = atTime
				n = A*z + B*c
		elseif operator == "/" then
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
			local scratch = OvaleTimeSpan(self_timeSpanPool:Get())
			scratch:Reset(timeSpan)
			timeSpan:Reset()
			IntersectInterval(scratch, atTime - bound, atTime + bound, timeSpan)
			self_timeSpanPool:Release(scratch)
		elseif operator == "%" then
			if c == 0 and z == 0 then
				l = A % B
				m = atTime
				n = 0
			else
				Ovale:Errorf("[%d]    Parameters of modulus operator '%' must be constants.", element.nodeId)
				l = 0
				m = 0
				n = 0
			end
		end
		Ovale:Logf("[%d]    arithmetic '%s' returns %f+(t-%f)*%f", element.nodeId, operator, l, m, n)
		result = SetValue(element, l, m, n)
	end
	profiler.Stop("OvaleBestAction_Compute")
	return timeSpan, OVALE_DEFAULT_PRIORITY, result
end

function OvaleBestAction:ComputeCompare(element, state)
	profiler.Start("OvaleBestAction_Compute")
	local timeSpanA, _, elementA = self:Compute(element.child[1], state)
	local timeSpanB, _, elementB = self:Compute(element.child[2], state)
	local timeSpan = GetTimeSpan(element)

	-- Take intersection of A and B.
	Intersect(timeSpanA, timeSpanB, timeSpan)
	if Measure(timeSpan) == 0 then
		Ovale:Logf("[%d]    compare '%s' returns %s with zero measure", element.nodeId, element.operator, tostring(timeSpan))
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

		Ovale:Logf("[%d]    %f+(t-%f)*%f %s %f+(t-%f)*%f", element.nodeId, a, b, c, operator, x, y, z)

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
			Ovale:Logf("[%d]    intersection at t = %f", element.nodeId, t)
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
			self_timeSpanPool:Release(scratch)
		end
		Ovale:Logf("[%d]    compare '%s' returns %s", element.nodeId, operator, tostring(timeSpan))
	end
	profiler.Stop("OvaleBestAction_Compute")
	return timeSpan
end

function OvaleBestAction:ComputeCustomFunction(element, state)
	profiler.Start("OvaleBestAction_Compute")
	local timeSpan = GetTimeSpan(element)
	local priority, result

	local node = OvaleCompile:GetFunctionNode(element.name)
	if node then
		Ovale:Logf("[%d]    evaluating function: %s(%s)", element.nodeId, node.name, node.paramsAsString)
		local timeSpanA, priorityA, elementA = self:Compute(node.child[1], state)
		if element.params.asValue == 1 or node.params.asValue == 1 then
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
			local atTime = state.currentTime
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
			Ovale:Logf("[%d]    function '%s' typecast to value %f", element.nodeId, element.name, value)
			timeSpan[1], timeSpan[2] = 0, math.huge
			result = SetValue(element, value)
		else
			CopyTimeSpan(timeSpanA, timeSpan)
			result = elementA
		end
	end

	profiler.Stop("OvaleBestAction_Compute")
	return timeSpan, priority, result
end

function OvaleBestAction:ComputeFunction(element, state)
	profiler.Start("OvaleBestAction_ComputeFunction")
	local timeSpan = GetTimeSpan(element)
	local priority, result

	Ovale:Logf("[%d]    evaluating condition: %s(%s)", element.nodeId, element.name, element.paramsAsString)
	local start, ending, value, origin, rate = OvaleCondition:EvaluateCondition(element.func, element.params)
	if start and ending then
		timeSpan[1], timeSpan[2] = start, ending
	end
	Ovale:Logf("[%d]    condition '%s' returns %s, %s, %s, %s, %s", element.nodeId, element.name, start, ending, value, origin, rate)

	--[[
		Allow for the return value of a script condition to be "typecast" to a constant value
		by specifying asValue=1 as a script parameter.

		If the return value is a time span (a "boolean" value), then if the current time of
		the simulation is within the time span, then return 1, or 0 otherwise.

		If the return value is a linear function, then if the current time of the simulation
		is within the function's domain, then the function is simply evaluated at the current
		time, or 0 otherwise.
	--]]
	if element.params.asValue == 1 then
		local atTime = state.currentTime
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
		timeSpan[1], timeSpan[2] = 0, math.huge
		priority = OVALE_DEFAULT_PRIORITY
		Ovale:Logf("[%d]    condition '%s' typecast to value %f", element.nodeId, element.name, value)
	elseif value then
		result = SetValue(element, value, origin, rate)
	end

	profiler.Stop("OvaleBestAction_ComputeFunction")
	return timeSpan, priority, result
end

function OvaleBestAction:ComputeGroup(element, state)
	profiler.Start("OvaleBestAction_Compute")
	local bestTimeSpan, bestPriority, bestElement, bestCastTime
	local timeSpan = GetTimeSpan(element)

	local best = OvaleTimeSpan(self_timeSpanPool:Get())
	local current = OvaleTimeSpan(self_timeSpanPool:Get())

	for _, node in ipairs(element.child) do
		local currentTimeSpan, currentPriority, currentElement = self:Compute(node, state)
		-- We only care about actions that are available at time t > state.currentTime.
		current:Reset()
		IntersectInterval(currentTimeSpan, state.currentTime, math.huge, current)
		if Measure(current) > 0 then
			Ovale:Logf("[%d]    group checking %s", element.nodeId, tostring(current))
			local currentCastTime
			if currentElement then
				currentCastTime = currentElement.castTime
			end
			local gcd = OvaleCooldown:GetGCD()
			if not currentCastTime or currentCastTime < gcd then
				currentCastTime = gcd
			end

			local currentIsBetter = false
			if Measure(best) == 0 then
				Ovale:Logf("[%d]    group first best is %s", element.nodeId, tostring(current))
				currentIsBetter = true
			elseif not currentPriority or not bestPriority or currentPriority == bestPriority then
				-- If the spells have the same priority, then pick the one with an earlier cast time.
				local threshold = (bestElement and bestElement.params) and bestElement.params.wait or 0
				if best[1] - current[1] > threshold then
					Ovale:Logf("[%d]    group new best is %s", element.nodeId, tostring(current))
					currentIsBetter = true
				end
			elseif currentPriority > bestPriority then
				-- If the current spell has a higher priority than the best one found, then choose the
				-- higher priority spell if its cast is pushed back too far by the lower priority one.
				local threshold = (currentElement and currentElement.params) and currentElement.params.wait or (bestCastTime * 0.75)
				if current[1] - best[1] < threshold then
					Ovale:Logf("[%d]    group new best (lower prio) is %s", element.nodeId, tostring(current))
					currentIsBetter = true
				end
			elseif currentPriority < bestPriority then
				-- If the current spell has a lower priority than the best one found, then choose the
				-- lower priority spell only if it doesn't push back the cast of the higher priority
				-- one by too much.
				local threshold = (bestElement and bestElement.params) and bestElement.params.wait or (currentCastTime * 0.75)
				if best[1] - current[1] > threshold then
					Ovale:Logf("[%d]    group new best (higher prio) is %s", element.nodeId, tostring(current))
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
		if bestElement.params then
			id = bestElement.params[1]
		end
		Ovale:Logf("[%d]    group best action %s remains %s", element.nodeId, id, tostring(timeSpan))
	else
		Ovale:Logf("[%d]    group no best action returns %s", element.nodeId, tostring(timeSpan))
	end

	profiler.Stop("OvaleBestAction_Compute")
	return timeSpan, bestPriority, bestElement
end

function OvaleBestAction:ComputeIf(element, state)
	profiler.Start("OvaleBestAction_Compute")
	local timeSpanA = self:ComputeBool(element.child[1], state)
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
		Ovale:Logf("[%d]    '%s' returns %s with zero measure", element.nodeId, element.type, tostring(timeSpan))
		priority = OVALE_DEFAULT_PRIORITY
		result = SetValue(element, 0)
	else
		local timeSpanB, priorityB, elementB = self:Compute(element.child[2], state)
		-- If the "then" clause is a "wait" node, then only wait if the conditions are true.
		if elementB and elementB.wait and not HasTime(conditionTimeSpan, state.currentTime) then
			elementB.wait = nil
		end
		-- Take intersection of the condition and B.
		Intersect(conditionTimeSpan, timeSpanB, timeSpan)
		Ovale:Logf("[%d]    '%s' returns %s", element.nodeId, element.type, tostring(timeSpan))
		priority = priorityB
		result = elementB
	end
	self_timeSpanPool:Release(conditionTimeSpan)

	profiler.Stop("OvaleBestAction_Compute")
	return timeSpan, priority, result
end

function OvaleBestAction:ComputeLogical(element, state)
	profiler.Start("OvaleBestAction_Compute")
	local timeSpanA = self:ComputeBool(element.child[1], state)
	local timeSpan = GetTimeSpan(element)

	if element.operator == "and" then
		-- Short-circuit evaluation of left argument to AND.
		if Measure(timeSpanA) == 0 then
			timeSpan:Reset(timeSpanA)
			Ovale:Logf("[%d]    logical '%s' short-circuits with zero measure left argument", element.nodeId, element.operator)
		else
			local timeSpanB = self:ComputeBool(element.child[2], state)
			-- Take intersection of A and B.
			Intersect(timeSpanA, timeSpanB, timeSpan)
		end
	elseif element.operator == "not" then
		Complement(timeSpanA, timeSpan)
	elseif element.operator == "or" then
		-- Short-circuit evaluation of left argument to OR.
		if timeSpanA and timeSpanA[1] == 0 and timeSpanA[2] == math.huge then
			timeSpan:Reset(timeSpanA)
			Ovale:Logf("[%d]    logical '%s' short-circuits with universe as left argument", element.nodeId, element.operator)
		else
			local timeSpanB = self:ComputeBool(element.child[2], state)
			-- Take union of A and B.
			Union(timeSpanA, timeSpanB, timeSpan)
		end
	end

	Ovale:Logf("[%d]    logical '%s' returns %s", element.nodeId, element.operator, tostring(timeSpan))
	profiler.Stop("OvaleBestAction_Compute")
	return timeSpan
end

function OvaleBestAction:ComputeLua(element, state)
	profiler.Start("OvaleBestAction_ComputeLua")
	local value = loadstring(element.lua)()
	Ovale:Logf("[%d]    lua returns %s", element.nodeId, value)

	local timeSpan = GetTimeSpan(element)
	local priority, result
	if value then
		timeSpan[1], timeSpan[2] = 0, math.huge
		result = SetValue(element, value)
		priority = OVALE_DEFAULT_PRIORITY
	end
	profiler.Stop("OvaleBestAction_ComputeLua")
	return timeSpan, priority, result
end

function OvaleBestAction:ComputeState(element, state)
	profiler.Start("OvaleBestAction_ComputeState")
	local timeSpan = GetTimeSpan(element)
	local result

	if element.func == "setstate" then
		Ovale:Logf("[%d]    %s: %s = %s", element.nodeId, element.name, element.params[1], element.params[2])
		timespan[1], timespan[2] = 0, math.huge
		result = element
	end
	profiler.Stop("OvaleBestAction_ComputeState")
	return timeSpan, OVALE_DEFAULT_PRIORITY, result
end

function OvaleBestAction:ComputeValue(element, state)
	profiler.Start("OvaleBestAction_ComputeValue")
	Ovale:Logf("[%d]    value is %s", element.nodeId, element.value)
	local timeSpan = GetTimeSpan(element)
	timeSpan[1], timeSpan[2] = 0, math.huge
	profiler.Stop("OvaleBestAction_ComputeValue")
	return timeSpan, OVALE_DEFAULT_PRIORITY, element
end

function OvaleBestAction:ComputeWait(element, state)
	profiler.Start("OvaleBestAction_Compute")
	local timeSpanA, priorityA, elementA = self:Compute(element.child[1], state)
	local timeSpan = GetTimeSpan(element)

	if elementA then
		elementA.wait = true
		CopyTimeSpan(timeSpanA, timeSpan)
		Ovale:Logf("[%d]    '%s' returns %s", element.nodeId, element.type, tostring(timeSpan))
	end
	profiler.Stop("OvaleBestAction_Compute")
	return timeSpan, priorityA, elementA
end

function OvaleBestAction:Debug()
	self_timeSpanPool:Debug()
	self_valuePool:Debug()
end
--</public-static-methods>
