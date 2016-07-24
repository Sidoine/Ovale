--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvalePower = Ovale:NewModule("OvalePower", "AceEvent-3.0")
Ovale.OvalePower = OvalePower

--<private-static-properties>
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleAura = nil
local OvaleFuture = nil
local OvaleData = nil
local OvaleState = nil

local ceil = math.ceil
local format = string.format
local gsub = string.gsub
local pairs = pairs
local strmatch = string.match
local tconcat = table.concat
local tonumber = tonumber
local tostring = tostring
local wipe = wipe
local API_CreateFrame = CreateFrame
local API_GetPowerRegen = GetPowerRegen
local API_GetTime = GetTime
local API_UnitPower = UnitPower
local API_UnitPowerMax = UnitPowerMax
local API_UnitPowerType = UnitPowerType
local INFINITY = math.huge
-- GLOBALS: _G
-- GLOBALS: UIParent

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvalePower)
-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvalePower)

-- Player's GUID.
local self_playerGUID = nil

-- Table of functions to update spellcast information to register with OvaleFuture.
local self_updateSpellcastInfo = {}
-- List of resources that have finishers that we need to save to the spellcast.
local self_SpellcastInfoPowerTypes = { "chi", "holy" }

-- Frame for resolving strings.
local self_button = nil
-- Frame for tooltip-scanning.
local self_tooltip = nil
-- Table of Lua patterns for matching spell costs in tooltips.
local self_costPatterns = {}

-- Map suffix for buff parameters to multiplier for spell cost reduction.
local BUFF_PERCENT_REDUCTION = {
	["_less15"] = 0.15,
	["_less50"] = 0.50,
	["_less75"] = 0.75,
	["_half"] = 0.5,
	["_more40"] = -0.4,
	["_more50"] = -0.5
}

do
	local debugOptions = {
		power = {
			name = L["Power"],
			type = "group",
			args = {
				power = {
					name = L["Power"],
					type = "input",
					multiline = 25,
					width = "full",
					get = function(info) return OvaleState.state:DebugPower() end,
				},
			},
		},
	}
	-- Insert debug options into OvaleDebug.
	for k, v in pairs(debugOptions) do
		OvaleDebug.options.args[k] = v
	end
end
--</private-static-properties>

--<public-static-properties>
-- Player's current power type (key for POWER table).
OvalePower.powerType = nil
-- Player's current power; power[powerType] = number.
OvalePower.power = {}
-- Player's current max power; maxPower[powerType] = number.
OvalePower.maxPower = {}
-- Player's current power regeneration rate for the active power type.
OvalePower.activeRegen = 0
OvalePower.inactiveRegen = 0
--[[
	This block is here to quiet lint.pl since these properties are used in a
	method mirrored to the state machine.

	OvalePower.powerRate = nil
	OvalePower.currentTime = nil
--]]

OvalePower.POWER_INFO =
{
	alternate = { id = SPELL_POWER_ALTERNATE_POWER, token = "ALTERNATE_RESOURCE_TEXT", mini = 0 },
	chi = { id = SPELL_POWER_CHI, token = "CHI", mini = 0, costString = CHI_COST },
	combopoints = { id = SPELL_POWER_COMBO_POINTS, token = "COMBO_POINTS", mini = 0, costString = COMBO_POINTS_COST },
	energy = { id = SPELL_POWER_ENERGY, token = "ENERGY", mini = 0, costString = ENERGY_COST },
	focus = { id = SPELL_POWER_FOCUS, token = "FOCUS", mini = 0, costString = FOCUS_COST },
	holy = { id = SPELL_POWER_HOLY_POWER, token = "HOLY_POWER", mini = 0, costString = HOLY_POWER_COST },
	mana = { id = SPELL_POWER_MANA, token = "MANA", mini = 0, costString = MANA_COST },
	rage = { id = SPELL_POWER_RAGE, token = "RAGE", mini = 0, costString = RAGE_COST },
	runicpower = { id = SPELL_POWER_RUNIC_POWER, token = "RUNIC_POWER", mini = 0, costString = RUNIC_POWER_COST },
	soulshards = { id = SPELL_POWER_SOUL_SHARDS, token = "SOUL_SHARDS", mini = 0, costString = SOUL_SHARDS_COST },
	astralpower = { id = SPELL_POWER_LUNAR_POWER, token = "ASTRAL_POWER", mini = 0, costString = LUNAR_POWER_COST },
	insanity = { id = SPELL_POWER_INSANITY, token = "INSANITY", mini = 0, costString = INSANITY_COST },
	maelstrom = { id = SPELL_POWER_MAELSTROM, token = "MAELSTROM", mini = 0, costString = MAELSTROM_COST }
}

-- Power types that can regenerate/pool over time with no actions.
OvalePower.PRIMARY_POWER = {
	energy = true,
	focus = true,
	mana = true,
}

OvalePower.POWER_TYPE = {}
do
	for powerType, v in pairs(OvalePower.POWER_INFO) do
		if not v.id then
			OvalePower:Print("Unknown resource %s", v.token)
		end
		OvalePower.POWER_TYPE[v.id] = powerType
		OvalePower.POWER_TYPE[v.token] = powerType
	end
end

-- POOLED_RESOURCE[class] = powerType
OvalePower.POOLED_RESOURCE = {
	["DRUID"] = "energy",
	["HUNTER"] = "focus",
	["MONK"] = "energy",
	["ROGUE"] = "energy"
}
--</public-static-properties>

--<public-static-methods>
function OvalePower:OnInitialize()
	-- Resolve module dependencies.
	OvaleAura = Ovale.OvaleAura
	OvaleData = Ovale.OvaleData
	OvaleFuture = Ovale.OvaleFuture
	OvaleState = Ovale.OvaleState

	-- Create the tooltip used for scanning.
	self_tooltip = API_CreateFrame("GameTooltip", "OvalePower_ScanningTooltip", nil, "GameTooltipTemplate")
	self_tooltip:SetOwner(UIParent, "ANCHOR_NONE")

	-- Populate the table of patterns to match spell costs in tooltips.
	self_button = API_CreateFrame("Button")
	for powerType, powerInfo in pairs(self.POWER_INFO) do
		local costString = powerInfo.costString
		if costString then
			for i = 1, 3 do
				-- Resolve the string then extract it again.
				self_button:SetFormattedText(format(costString, i))
				local text = self_button:GetText()
				local pattern = gsub(text, tostring(i), "(%%d)")
				self_costPatterns[pattern] = powerType
			end
		end
	end
end

function OvalePower:OnEnable()
	self_playerGUID = Ovale.playerGUID
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "EventHandler")
	self:RegisterEvent("PLAYER_LEVEL_UP", "EventHandler")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("UNIT_LEVEL")
	self:RegisterEvent("UNIT_MAXPOWER")
	self:RegisterEvent("UNIT_POWER")
	self:RegisterEvent("UNIT_POWER_FREQUENT", "UNIT_POWER")
	self:RegisterEvent("UNIT_RANGEDDAMAGE")
	self:RegisterEvent("UNIT_SPELL_HASTE", "UNIT_RANGEDDAMAGE")
	self:RegisterMessage("Ovale_StanceChanged", "EventHandler")
	self:RegisterMessage("Ovale_TalentsChanged", "EventHandler")
	for powerType in pairs(self.POWER_INFO) do
		OvaleData:RegisterRequirement(powerType, "RequirePowerHandler", self)
	end
	OvaleFuture:RegisterSpellcastInfo(self)
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvalePower:OnDisable()
	OvaleState:UnregisterState(self)
	OvaleFuture:UnregisterSpellcastInfo(self)
	for powerType in pairs(self.POWER_INFO) do
		OvaleData:UnregisterRequirement(powerType)
	end
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_LEVEL_UP")
	self:UnregisterEvent("UNIT_DISPLAYPOWER")
	self:UnregisterEvent("UNIT_LEVEL")
	self:UnregisterEvent("UNIT_MAXPOWER")
	self:UnregisterEvent("UNIT_POWER")
	self:UnregisterEvent("UNIT_POWER_FREQUENT")
	self:UnregisterEvent("UNIT_RANGEDDAMAGE")
	self:UnregisterEvent("UNIT_SPELL_HASTE")
	self:UnregisterMessage("Ovale_StanceChanged")
	self:UnregisterMessage("Ovale_TalentsChanged")
end

function OvalePower:EventHandler(event)
	self:UpdatePowerType(event)
	self:UpdateMaxPower(event)
	self:UpdatePower(event)
	self:UpdatePowerRegen(event)
end

function OvalePower:UNIT_DISPLAYPOWER(event, unitId)
	if unitId == "player" then
		self:UpdatePowerType(event)
		self:UpdatePowerRegen(event)
	end
end

function OvalePower:UNIT_LEVEL(event, unitId)
	if unitId == "player" then
		self:EventHandler(event)
	end
end

function OvalePower:UNIT_MAXPOWER(event, unitId, powerToken)
	if unitId == "player" then
		local powerType = self.POWER_TYPE[powerToken]
		if powerType then
			self:UpdateMaxPower(event, powerType)
		end
	end
end

function OvalePower:UNIT_POWER(event, unitId, powerToken)
	if unitId == "player" then
		local powerType = self.POWER_TYPE[powerToken]
		if powerType then
			self:UpdatePower(event, powerType)
		end
	end
end

function OvalePower:UNIT_RANGEDDAMAGE(event, unitId)
	if unitId == "player" then
		self:UpdatePowerRegen(event)
	end
end

function OvalePower:UpdateMaxPower(event, powerType)
	self:StartProfiling("OvalePower_UpdateMaxPower")
	if powerType then
		local powerInfo = self.POWER_INFO[powerType]
		local maxPower = API_UnitPowerMax("player", powerInfo.id, powerInfo.segments)
		if self.maxPower[powerType] ~= maxPower then
			self.maxPower[powerType] = maxPower
			Ovale.refreshNeeded[self_playerGUID] = true
		end
	else
		for powerType, powerInfo in pairs(self.POWER_INFO) do
			local maxPower = API_UnitPowerMax("player", powerInfo.id, powerInfo.segments)
			if self.maxPower[powerType] ~= maxPower then
				self.maxPower[powerType] = maxPower
				Ovale.refreshNeeded[self_playerGUID] = true
			end
		end
	end
	self:StopProfiling("OvalePower_UpdateMaxPower")
end

function OvalePower:UpdatePower(event, powerType)
	self:StartProfiling("OvalePower_UpdatePower")
	if powerType then
		local powerInfo = self.POWER_INFO[powerType]
		local power = API_UnitPower("player", powerInfo.id, powerInfo.segments)
		if self.power[powerType] ~= power then
			self.power[powerType] = power
			Ovale.refreshNeeded[self_playerGUID] = true
		end
		self:DebugTimestamp("%s: %d -> %d (%s).", event, self.power[powerType], power, powerType)
	else
		for powerType, powerInfo in pairs(self.POWER_INFO) do
			local power = API_UnitPower("player", powerInfo.id, powerInfo.segments)
			if self.power[powerType] ~= power then
				self.power[powerType] = power
				Ovale.refreshNeeded[self_playerGUID] = true
			end
			self:DebugTimestamp("%s: %d -> %d (%s).", event, self.power[powerType], power, powerType)
		end
	end
	Ovale.refreshNeeded[self_playerGUID] = true
	self:StopProfiling("OvalePower_UpdatePower")
end

function OvalePower:UpdatePowerRegen(event)
	self:StartProfiling("OvalePower_UpdatePowerRegen")
	local inactiveRegen, activeRegen = API_GetPowerRegen()
	if self.inactiveRegen ~= inactiveRegen or self.activeRegen ~= activeRegen then
		self.inactiveRegen, self.activeRegen = inactiveRegen, activeRegen
		Ovale.refreshNeeded[self_playerGUID] = true
	end
	self:StopProfiling("OvalePower_UpdatePowerRegen")
end

function OvalePower:UpdatePowerType(event)
	self:StartProfiling("OvalePower_UpdatePowerType")
	local currentType, currentToken = API_UnitPowerType("player")
	local powerType = self.POWER_TYPE[currentType]
	if self.powerType ~= powerType then
		self.powerType = powerType
		Ovale.refreshNeeded[self_playerGUID] = true
	end
	Ovale.refreshNeeded[self_playerGUID] = true
	self:StopProfiling("OvalePower_UpdatePowerType")
end

function OvalePower:GetSpellCost(spellId, powerType)
	self:StartProfiling("OvalePower_GetSpellCost")
	self_tooltip:SetSpellByID(spellId)
	local spellCost, spellPowerType
	for i = 2, self_tooltip:NumLines() do
		local line = _G["OvalePower_ScanningTooltipTextLeft" .. i]
		local text = line:GetText()
		if text then
			for pattern, pt in pairs(self_costPatterns) do
				if not powerType or pt == powerType then
					local cost = strmatch(text, pattern)
					if cost then
						spellCost = tonumber(cost)
						spellPowerType = pt
						break
					end
				end
			end
			if spellCost and spellPowerType then
				break
			end
		end
	end
	self:StopProfiling("OvalePower_GetSpellCost")
	return spellCost, spellPowerType
end

-- Get power at the given time.
-- NOTE: Mirrored in statePrototype below.
function OvalePower:GetPower(powerType, atTime)
	local power = (self.power and self.power[powerType]) or self[powerType] or 0
	local powerRate = 0
	if self.powerType and self.powerType == powerType then
		powerRate = self.activeRegen
	elseif self.powerRate then
		powerRate = self.powerRate[powerType]
	end
	if atTime then
		local now = self.currentTime or API_GetTime()
		local seconds = atTime - now
		if seconds > 0 then
			power = power + powerRate * seconds
		end
	end
	return power
end

-- Get power cost of the spell.
-- NOTE: Mirrored in statePrototype below.
function OvalePower:PowerCost(spellId, powerType, atTime, targetGUID, maximumCost)
	OvalePower:StartProfiling("OvalePower_PowerCost")
	local buffParam = "buff_" .. powerType
	local spellCost = 0
	local spellRefund = 0
	local si = OvaleData.spellInfo[spellId]
	if si and si[powerType] then
		-- Get references to mirrored methods used.
		local GetAura, GetAuraByGUID, IsActiveAura
		local GetSpellInfoProperty
		local auraModule, dataModule
		GetAura, auraModule = self:GetMethod("GetAura", OvaleAura)
		GetAuraByGUID, auraModule = self:GetMethod("GetAuraByGUID", OvaleAura)
		IsActiveAura, auraModule = self:GetMethod("IsActiveAura", OvaleAura)
		GetSpellInfoProperty, dataModule = self:GetMethod("GetSpellInfoProperty", OvaleData)

		--[[
			cost == 0 means the that spell uses no resources.
			cost > 0 means that the spell costs resources.
			cost < 0 means that the spell generates resources.
			cost == "finisher" means that the spell uses all of the resources (zeroes it out).
		--]]
		local cost = GetSpellInfoProperty(dataModule, spellId, atTime, powerType, targetGUID)
		if cost == "finisher" then
			-- This spell is a finisher so compute the cost based on the amount of resources consumed.
			cost = self:GetPower(powerType, atTime)
			-- Clamp cost between values defined by min_<powerType> and max_<powerType>.
			local minCostParam = "min_" .. powerType
			local maxCostParam = "max_" .. powerType
			local minCost = si[minCostParam] or 1
			local maxCost = si[maxCostParam]
			if cost < minCost then
				cost = minCost
			end
			if maxCost and cost > maxCost then
				cost = maxCost
			end
		elseif cost == "refill" then
			cost = self:GetPower(powerType, atTime) - OvalePower.maxPower[powerType] 
		else
			--[[
				Add extra resource generated by presence of a buff.
				"buff_<powerType>" is the spell ID of the buff that causes extra resources to be generated or used.
				"buff_<powerType>_amount" is the amount of extra resources generated or used, defaulting to -1
					(one extra resource generated).
			--]]
			local buffExtraParam = buffParam
			local buffAmountParam = buffParam .. "_amount"
			local buffExtra = si[buffExtraParam]
			if buffExtra then
				local aura = GetAura(auraModule, "player", buffExtra, nil, true)
				local isActiveAura = IsActiveAura(auraModule, aura, atTime)
				if isActiveAura then
					local buffAmount = si[buffAmountParam] or -1
					-- Check if this aura has a stacking effect.
					local siAura = OvaleData.spellInfo[buffExtra]
					if siAura and siAura.stacking == 1 then
						buffAmount = buffAmount * aura.stacks
					end
					cost = cost + buffAmount
					self:Log("Spell ID '%d' had %f %s added from aura ID '%d'.", spellId, buffAmount, powerType, aura.spellId)
				end
			end
		end
		--[[
			Compute any multiplier to the resource cost of the spell due to the presence of a buff.
			"buff_<powerType>_less<N>" is the spell Id of the buff that reduces the resource cost by N percent.
		--]]
		local multiplier = 1
		for suffix, reduction in pairs(BUFF_PERCENT_REDUCTION) do
			local buffPercentReduction = si[buffParam .. suffix]
			if buffPercentReduction then
				local aura = GetAuraByGUID(auraModule, self_playerGUID, buffPercentReduction)
				local isActiveAura = IsActiveAura(auraModule, aura, atTime)
				if isActiveAura then
					-- Check if this aura has a stacking effect.
					local siAura = OvaleData.spellInfo[buffPercentReduction]
					if siAura and siAura.stacking == 1 then
						reduction = reduction * aura.stacks
						-- Clamp to a maximum of 100% reduction.
						if reduction > 1 then
							reduction = 1
						end
					end
					multiplier = multiplier * (1 - reduction)
				end
			end
		end
		--[[
			Apply any percent reductions to cost after fixed reductions are applied.
			This seems to be a consistent Blizzard rule for spell costs so that you
			never end up with a negative spell cost.
		--]]
		if cost > 0 then
			cost = cost * multiplier
		end
		--[[
			Some abilities use "up to" N additional resources if available, e.g., Ferocious Bite.
			Document this with "extra_<powerType>=N" in SpellInfo().
			Add these additional resources to the cost after checking if the spell is resource-free for the base cost.
		--]]
		local extraPowerParam = "extra_" .. powerType
		local extraPower = GetSpellInfoProperty(dataModule, spellId, atTime, extraPowerParam, targetGUID)
		if extraPower then
			if not maximumCost then
				-- Clamp the extra power to the remaining power.
				local power = self:GetPower(powerType, atTime)
				power = power > cost and power - cost or 0
				if extraPower >= power then
					extraPower = power
				end
			end
			-- Apply any percent reductions to the extra resource cost.
			if extraPower > 0 then
				extraPower = extraPower * multiplier
				self:Log("Spell ID '%d' will use %d extra %s.", spellId, extraPower, powerType)
			end
			cost = cost + extraPower
		end
		-- Round up to whole number of resources.
		spellCost = ceil(cost)

		local refundParam = "refund_" .. powerType
		local refund = GetSpellInfoProperty(dataModule, spellId, atTime, refundParam, targetGUID)
		if refund == "cost" then
			refund = spellCost
		end
		refund = refund or 0
		-- Round up to whole number of resources.
		spellRefund = ceil(refund)
	else
		-- Determine cost using information from the spell tooltip if there is no SpellInfo() for the spell's cost.
		local cost = OvalePower:GetSpellCost(spellId, powerType)
		if cost then
			spellCost = cost
		end
	end
	OvalePower:StopProfiling("OvalePower_PowerCost")
	return spellCost, spellRefund
end

-- Run-time check that the player has enough power.
-- NOTE: Mirrored in statePrototype below.
function OvalePower:RequirePowerHandler(spellId, atTime, requirement, tokens, index, targetGUID)
	local verified = false
	-- If index isn't given, then tokens holds the actual token value.
	local cost = tokens
	if index then
		cost = tokens[index]
		index = index + 1
	end
	if cost then
		local powerType = requirement
		cost = self:PowerCost(spellId, powerType, atTime, targetGUID)
		if cost > 0 then
			local power = self:GetPower(powerType, atTime)
			if power >= cost then
				verified = true
			end
		else
			verified = true
		end
		if cost > 0 then
			local result = verified and "passed" or "FAILED"
			self:Log("    Require %f %s at time=%f: %s", cost, powerType, atTime, result)
		end
	else
		Ovale:OneTimeMessage("Warning: requirement '%s' is missing a cost argument.", requirement)
	end
	return verified, requirement, index
end

function OvalePower:DebugPower()
	self:Print("Power type: %s", self.powerType)
	for powerType, v in pairs(self.power) do
		self:Print("Power (%s): %d / %d", powerType, v, self.maxPower[powerType])
	end
	self:Print("Active regen: %f", self.activeRegen)
	self:Print("Inactive regen: %f", self.inactiveRegen)
end

-- Copy power information from the spellcast to the destination table.
function OvalePower:CopySpellcastInfo(spellcast, dest)
	for _, powerType in pairs(self_SpellcastInfoPowerTypes) do
		if spellcast[powerType] then
			dest[powerType] = spellcast[powerType]
		end
	end
end

-- Save power information to the spellcast.
function OvalePower:SaveSpellcastInfo(spellcast, atTime, state)
	local spellId = spellcast.spellId
	if spellId then
		local si = OvaleData.spellInfo[spellId]
		if si then
			local dataModule = state or OvaleData
			local powerModule = state or self
			for _, powerType in pairs(self_SpellcastInfoPowerTypes) do
				if si[powerType] == "finisher" then
					-- Get the maximum cost of the finisher.
					local maxCostParam = "max_" .. powerType
					local maxCost = si[maxCostParam] or 1
					local cost = dataModule:GetSpellInfoProperty(spellId, atTime, powerType, spellcast.target)
					if cost == "finisher" then
						-- This finisher costs up to maxCost resources.
						local power = powerModule:GetPower(powerType, atTime)
						if power > maxCost then
							cost = maxCost
						else
							cost = power
						end
					elseif cost == 0 then
						-- If this is a finisher that costs no resources, then treat it as using the maximum cost.
						cost = maxCost
					end
					-- Save the cost to the spellcast table.
					spellcast[powerType] = cost
				end
			end
		end
	end
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvalePower.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvalePower.statePrototype
--</private-static-properties>

--<state-properties>
--[[
	This block is here for lint.pl to know that these properties are added to the state machine.

	statePrototype.alternate = nil
	statePrototype.astralpower = nil
	statePrototype.chi = nil
	statePrototype.demonicfury = nil
	statePrototype.energy = nil
	statePrototype.focus = nil
	statePrototype.holy = nil
	statePrototype.mana = nil
	statePrototype.rage = nil
	statePrototype.runicpower = nil
	statePrototype.shadoworbs = nil
	statePrototype.shards = nil
--]]

-- powerRate[powerType] = regen rate
statePrototype.powerRate = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvalePower:InitializeState(state)
	for powerType in pairs(self.POWER_INFO) do
		state[powerType] = 0
	end
	state.powerRate = {}
end

-- Reset the state to the current conditions.
function OvalePower:ResetState(state)
	self:StartProfiling("OvalePower_ResetState")
	-- Power levels for each resource.
	for powerType in pairs(self.POWER_INFO) do
		state[powerType] = self.power[powerType] or 0
	end
	-- Clear power regeneration rates for each resource.
	for powerType in pairs(self.POWER_INFO) do
		state.powerRate[powerType] = 0
	end
	-- Set power regeneration for current resource.
	if OvaleFuture.inCombat then
		state.powerRate[self.powerType] = self.activeRegen
	else
		state.powerRate[self.powerType] = self.inactiveRegen
	end
	self:StopProfiling("OvalePower_ResetState")
end

-- Release state resources prior to removing from the simulator.
function OvalePower:CleanState(state)
	for powerType in pairs(self.POWER_INFO) do
		state[powerType] = nil
	end
	for k in pairs(state.powerRate) do
		state.powerRate[k] = nil
	end
end

-- Apply the effects of the spell at the start of the spellcast.
function OvalePower:ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvalePower_ApplySpellStartCast")
	-- Channeled spells cost resources at the start of the channel.
	if isChanneled then
		if state.inCombat then
			state.powerRate[self.powerType] = self.activeRegen
		end
		state:ApplyPowerCost(spellId, targetGUID, startCast, spellcast)
	end
	self:StopProfiling("OvalePower_ApplySpellStartCast")
end

-- Apply the effects of the spell when the spellcast completes.
function OvalePower:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvalePower_ApplySpellAfterCast")
	-- Instant or cast-time spells cost resources at the end of the spellcast.
	if not isChanneled then
		if state.inCombat then
			state.powerRate[self.powerType] = self.activeRegen
		end
		state:ApplyPowerCost(spellId, targetGUID, endCast, spellcast)
	end
	self:StopProfiling("OvalePower_ApplySpellAfterCast")
end
--</public-static-methods>

--<state-methods>
-- Update the state of the simulator for the power cost of the given spell.
statePrototype.ApplyPowerCost = function(state, spellId, targetGUID, atTime, spellcast)
	OvalePower:StartProfiling("OvalePower_state_ApplyPowerCost")
	local si = OvaleData.spellInfo[spellId]

	-- Update power using information from the spell tooltip if there is no SpellInfo() for the spell's cost.
	do
		local cost, powerType = OvalePower:GetSpellCost(spellId)
		if cost and powerType and state[powerType] and not (si and si[powerType]) then
			state[powerType] = state[powerType] - cost
		end
	end

	if si then
		-- Update power state.
		for powerType, powerInfo in pairs(OvalePower.POWER_INFO) do
			local cost, refund = state:PowerCost(spellId, powerType, atTime, targetGUID)
			local power = state[powerType] or 0
			if cost then
				power = power - cost + refund
				-- Add any power regenerated or consumed before the next spell can be cast.
				local seconds = state.nextCast - atTime
				if seconds > 0 then
					local powerRate = state.powerRate[powerType]
					power = power + powerRate * seconds
				end
				-- Clamp power to lower and upper limits.
				local mini = powerInfo.mini or 0
				local maxi = powerInfo.maxi or OvalePower.maxPower[powerType]
				if mini and power < mini then
					power = mini
				end
				if maxi and power > maxi then
					power = maxi
				end
				state[powerType] = power
			end
		end
	end
	OvalePower:StopProfiling("OvalePower_state_ApplyPowerCost")
end

-- Return the number of seconds before enough of the given power type is available for the spell.
-- If not powerType is given, the the pooled resource for that class is used.
statePrototype.TimeToPower = function(state, spellId, atTime, targetGUID, powerType)
	local seconds = 0
	powerType = powerType or OvalePower.POOLED_RESOURCE[state.class]
	if powerType then
		local cost = state:PowerCost(spellId, powerType, atTime, targetGUID)
		local power = state:GetPower(powerType, atTime)
		local powerRate = state.powerRate[powerType]
		if power < cost then
			if powerRate > 0 then
				seconds = (cost - power) / powerRate
			else
				seconds = INFINITY
			end
		end
	end
	return seconds
end

-- Return the amount of the given resource needed to cast the given spell.
-- Mirrored methods.
statePrototype.GetPower = OvalePower.GetPower
statePrototype.PowerCost = OvalePower.PowerCost
statePrototype.RequirePowerHandler = OvalePower.RequirePowerHandler

-- Print out the levels of each power type in the current state.
do
	local output = {}

	statePrototype.DebugPower = function(state)
		wipe(output)
		for powerType in pairs(OvalePower.POWER_INFO) do
			output[#output + 1] = Ovale:MakeString("%s = %d", powerType, state[powerType])
		end
		return tconcat(output, "\n")
	end
end
--</state-methods>
