--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvalePower = Ovale:NewModule("OvalePower", "AceEvent-3.0")
Ovale.OvalePower = OvalePower

--<private-static-properties>
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
local tonumber = tonumber
local tostring = tostring
local API_CreateFrame = CreateFrame
local API_GetPowerRegen = GetPowerRegen
local API_UnitPower = UnitPower
local API_UnitPowerMax = UnitPowerMax
local API_UnitPowerType = UnitPowerType

-- Profiling set-up.
local Profiler = Ovale.Profiler
local profiler = nil
do
	local group = OvalePower:GetName()
	Profiler:RegisterProfilingGroup(group)
	profiler = Profiler:GetProfilingGroup(group)
end

-- Table of functions to update spellcast information to register with OvaleFuture.
local self_updateSpellcastInfo = {}

-- Frame for resolving strings.
local self_button = nil
-- Frame for tooltip-scanning.
local self_tooltip = nil
-- Table of Lua patterns for matching spell costs in tooltips.
local self_costPatterns = {}
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

OvalePower.POWER_INFO =
{
	alternate = { id = SPELL_POWER_ALTERNATE_POWER, token = "ALTERNATE_RESOURCE_TEXT", mini = 0 },
	burningembers = { id = SPELL_POWER_BURNING_EMBERS, token = "BURNING_EMBERS", mini = 0, segments = true, costString = BURNING_EMBERS_COST },
	chi = { id = SPELL_POWER_CHI, token = "CHI", mini = 0, costString = CHI_COST },
	demonicfury = { id = SPELL_POWER_DEMONIC_FURY, token = "DEMONIC_FURY", mini = 0, costString = DEMONIC_FURY_COST },
	energy = { id = SPELL_POWER_ENERGY, token = "ENERGY", mini = 0, costString = ENERGY_COST },
	focus = { id = SPELL_POWER_FOCUS, token = "FOCUS", mini = 0, costString = FOCUS_COST },
	holy = { id = SPELL_POWER_HOLY_POWER, token = "HOLY_POWER", mini = 0, costString = HOLY_POWER_COST },
	mana = { id = SPELL_POWER_MANA, token = "MANA", mini = 0, costString = MANA_COST },
	rage = { id = SPELL_POWER_RAGE, token = "RAGE", mini = 0, costString = RAGE_COST },
	runicpower = { id = SPELL_POWER_RUNIC_POWER, token = "RUNIC_POWER", mini = 0, costString = RUNIC_POWER_COST },
	shadoworbs = { id = SPELL_POWER_SHADOW_ORBS, token = "SHADOW_ORBS", mini = 0 },
	shards = { id = SPELL_POWER_SOUL_SHARDS, token = "SOUL_SHARDS_POWER", mini = 0, costString = SOUL_SHARDS_COST },
}
OvalePower.SECONDARY_POWER = {
	alternate = true,
	burningembers = true,
	chi = true,
	demonicfury = true,
	focus = true,
	holy = true,
	rage = true,
	runicpower = true,
	shadoworbs = true,
	shards = true,
}
OvalePower.PRIMARY_POWER = {}
do
	for powerType in pairs(OvalePower.POWER_INFO) do
		if not OvalePower.SECONDARY_POWER[powerType] then
			OvalePower.PRIMARY_POWER[powerType] = true
		end
	end
end
OvalePower.POWER_TYPE = {}
do
	for powerType, v in pairs(OvalePower.POWER_INFO) do
		OvalePower.POWER_TYPE[v.id] = powerType
		OvalePower.POWER_TYPE[v.token] = powerType
	end
end
--</public-static-properties>

--<private-static-methods>
-- Manage spellcast.holy information.
local function SaveToSpellcast(spellcast)
	if spellcast.spellId then
		local si = OvaleData.spellInfo[spellcast.spellId]
		-- Save the number of holy power used if this spell is a finisher.
		if si.holy == "finisher" then
			local max_holy = si.max_holy or 3
			-- If a buff is present that removes the holy power cost of the spell,
			-- then treat it as using the maximum amount of holy power.
			if si.buff_holy_none then
				if OvaleAura:GetAura("player", si.buff_holy_none) then
					spellcast.holy = max_holy
				end
			end
			local holy = OvalePower.power.holy
			if holy > 0 then
				if holy > max_holy then
					spellcast.holy = max_holy
				else
					spellcast.holy = holy
				end
			end
		end
	end
end

local function UpdateFromSpellcast(dest, spellcast)
	if spellcast.holy then
		dest.holy = spellcast.holy
	end
end

do
	self_updateSpellcastInfo.SaveToSpellcast = SaveToSpellcast
	self_updateSpellcastInfo.UpdateFromSpellcast = UpdateFromSpellcast
end
--</private-static-methods>

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
	self:RegisterEvent("PLAYER_ALIVE", "EventHandler")
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
	OvaleState:RegisterState(self, self.statePrototype)
	OvaleFuture:RegisterSpellcastInfo(self_updateSpellcastInfo)
end

function OvalePower:OnDisable()
	OvaleState:UnregisterState(self)
	OvaleFuture:UnregisterSpellcastInfo(self_updateSpellcastInfo)
	self:UnregisterEvent("PLAYER_ALIVE")
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
	self:UpdatePowerType()
	self:UpdateMaxPower()
	self:UpdatePower()
	self:UpdatePowerRegen()
end

function OvalePower:UNIT_DISPLAYPOWER(event, unitId)
	if unitId == "player" then
		self:UpdatePowerType()
		self:UpdatePowerRegen()
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
			self:UpdateMaxPower(powerType)
		end
	end
end

function OvalePower:UNIT_POWER(event, unitId, powerToken)
	if unitId == "player" then
		local powerType = self.POWER_TYPE[powerToken]
		if powerType then
			self:UpdatePower(powerType)
		end
	end
end

function OvalePower:UNIT_RANGEDDAMAGE(event, unitId)
	if unitId == "player" then
		self:UpdatePowerRegen()
	end
end

function OvalePower:UpdateMaxPower(powerType)
	profiler.Start("OvalePower_UpdateMaxPower")
	if powerType then
		local powerInfo = self.POWER_INFO[powerType]
		self.maxPower[powerType] = API_UnitPowerMax("player", powerInfo.id, powerInfo.segments)
	else
		for powerType, powerInfo in pairs(self.POWER_INFO) do
			self.maxPower[powerType] = API_UnitPowerMax("player", powerInfo.id, powerInfo.segments)
		end
	end
	profiler.Stop("OvalePower_UpdateMaxPower")
end

function OvalePower:UpdatePower(powerType)
	profiler.Start("OvalePower_UpdatePower")
	if powerType then
		local powerInfo = self.POWER_INFO[powerType]
		self.power[powerType] = API_UnitPower("player", powerInfo.id, powerInfo.segments)
	else
		for powerType, powerInfo in pairs(self.POWER_INFO) do
			self.power[powerType] = API_UnitPower("player", powerInfo.id, powerInfo.segments)
		end
	end
	profiler.Stop("OvalePower_UpdatePower")
end

function OvalePower:UpdatePowerRegen()
	profiler.Start("OvalePower_UpdatePowerRegen")
	self.inactiveRegen, self.activeRegen = API_GetPowerRegen()
	profiler.Stop("OvalePower_UpdatePowerRegen")
end

function OvalePower:UpdatePowerType()
	profiler.Start("OvalePower_UpdatePowerType")
	local currentType, currentToken = API_UnitPowerType("player")
	self.powerType = self.POWER_TYPE[currentType]
	profiler.Stop("OvalePower_UpdatePowerType")
end

function OvalePower:PowerCost(spellId, powerType)
	profiler.Start("OvalePower_PowerCost")
	self_tooltip:SetSpellByID(spellId)
	local spellCost, spellPowerType
	for i = 2, self_tooltip:NumLines() do
		local line = _G["OvalePower_ScanningTooltipTextLeft" .. i]
		local text = line:GetText()
		if text then
			for pattern, pt in pairs(self_costPatterns) do
				if not powerType or pt == powerType then
					cost = strmatch(text, pattern)
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
	profiler.Stop("OvaleEquipement_PowerCost")
	return spellCost, spellPowerType
end

function OvalePower:Debug()
	Ovale:FormatPrint("Power type: %s", self.powerType)
	for powerType, v in pairs(self.power) do
		Ovale:FormatPrint("Power (%s): %d / %d", powerType, v, self.maxPower[powerType])
	end
	Ovale:FormatPrint("Active regen: %f", self.activeRegen)
	Ovale:FormatPrint("Inactive regen: %f", self.inactiveRegen)
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
	This block is here for compiler.pl to know that these properties are added to the state machine.

	statePrototype.alternate = nil
	statePrototype.burningembers = nil
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
	profiler.Start("OvalePower_ResetState")
	-- Power levels for each resource.
	for powerType in pairs(self.POWER_INFO) do
		state[powerType] = self.power[powerType] or 0
	end
	-- Clear power regeneration rates for each resource.
	for powerType in pairs(self.POWER_INFO) do
		state.powerRate[powerType] = 0
	end
	-- Set power regeneration for current resource.
	if Ovale.enCombat then
		state.powerRate[self.powerType] = self.activeRegen
	else
		state.powerRate[self.powerType] = self.inactiveRegen
	end
	profiler.Stop("OvalePower_ResetState")
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
function OvalePower:ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast)
	profiler.Start("OvalePower_ApplySpellStartCast")
	-- Channeled spells cost resources at the start of the channel.
	if isChanneled then
		state:ApplyPowerCost(spellId)
	end
	profiler.Stop("OvalePower_ApplySpellStartCast")
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvalePower:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, nextCast, isChanneled, nocd, spellcast)
	profiler.Start("OvalePower_ApplySpellAfterCast")
	-- Instant or cast-time spells cost resources at the end of the spellcast.
	if not isChanneled then
		state:ApplyPowerCost(spellId)
	end
	profiler.Stop("OvalePower_ApplySpellAfterCast")
end
--</public-static-methods>

--<state-methods>
-- Update the state of the simulator for the power cost of the given spell.
statePrototype.ApplyPowerCost = function(state, spellId)
	profiler.Start("OvalePower_state_ApplyPowerCost")
	local si = OvaleData.spellInfo[spellId]

	-- Update power using information from the spell tooltip if there is no SpellInfo() for the spell's cost.
	do
		local cost, powerType = OvalePower:PowerCost(spellId)
		if cost and powerType and state[powerType] and not (si and si[powerType]) then
			state[powerType] = state[powerType] - cost
		end
	end

	if si then
		-- Update power state.
		for powerType, powerInfo in pairs(OvalePower.POWER_INFO) do
			local cost = state:PowerCost(spellId, powerType)
			local power = state[powerType] or 0
			if cost then
				power = power - cost
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
	profiler.Stop("OvalePower_state_ApplyPowerCost")
end

-- Return the number of seconds before all of the primary resources needed by a spell are available.
statePrototype.TimeToPower = function(state, spellId, powerType)
	local power = state[powerType]
	local powerRate = state.powerRate[powerType]
	local cost = state:PowerCost(spellId, powerType)

	local seconds = 0
	if power < cost then
		if powerRate > 0 then
			seconds = (cost - power) / powerRate
		else
			seconds = math.huge
		end
	end
	return seconds
end

-- Return the amount of the given resource needed to cast the given spell.
do
	local BUFF_PERCENT_REDUCTION = {
		["_less15"] = 0.15,
		["_less50"] = 0.50,
		["_less75"] = 0.75,
		["_half"] = 0.5,
	}

	statePrototype.PowerCost = function(state, spellId, powerType)
		profiler.Start("OvalePower_state_PowerCost")
		local buffParam = "buff_" .. powerType
		local spellCost = 0
		local si = OvaleData.spellInfo[spellId]
		if si and si[powerType] then
			--[[
				cost == 0 means the that spell uses no resources.
				cost > 0 means that the spell costs resources.
				cost < 0 means that the spell generates resources.
				cost == "finisher" means that the spell uses all of the resources (zeroes it out).
			--]]
			local cost = si[powerType]
			if cost == "finisher" then
				-- This spell is a finisher so compute the cost based on the amount of resources consumed.
				cost = state[powerType]
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
					local aura = state:GetAura("player", buffExtra, nil, true)
					if state:IsActiveAura(aura) then
						local buffAmount = si[buffAmountParam] or -1
						-- Check if this aura has a stacking effect.
						local siAura = OvaleData.spellInfo[buffExtra]
						if siAura and siAura.stacking == 1 then
							buffAmount = buffAmount * aura.stacks
						end
						cost = cost + buffAmount
					end
				end
				if cost > 0 then
					--[[
						Apply any percent reductions to cost after fixed reductions are applied.
						This seems to be a consistent Blizzard rule for spell costs so that you
						never end up with a negative spell cost.
					--]]
					for suffix, reduction in pairs(BUFF_PERCENT_REDUCTION) do
						local buffPercentReduction = si[buffParam .. suffix]
						if buffPercentReduction then
							local aura = state:GetAura("player", buffPercentReduction)
							if state:IsActiveAura(aura) then
								-- Check if this aura has a stacking effect.
								local siAura = OvaleData.spellInfo[buffPercentReduction]
								if siAura and siAura.stacking then
									reduction = reduction * aura.stacks
									-- Clamp to a maximum of 100% reduction.
									if reduction > 1 then
										reduction = 1
									end
								end
								local multiplier = 1 - reduction
								cost = cost * multiplier
							end
						end
					end
					cost = ceil(cost)
				end
			end

			local buffNoCostParam = buffParam .. "_none"
			local buffNoCost = si[buffNoCostParam]
			if buffNoCost then
				-- "buff_<powerType>_none" is the spell ID of the buff that makes casting the spell resource-free.
				local aura = state:GetAura("player", buffNoCost)
				if state:IsActiveAura(aura) then
					cost = 0
				end
			end
			spellCost = cost
		else
			-- Determine cost using information from the spell tooltip if there is no SpellInfo() for the spell's cost.
			local cost = OvalePower:PowerCost(spellId, powerType)
			if cost then
				spellCost = cost
			end
		end
		profiler.Stop("OvalePower_state_PowerCost")
		return spellCost
	end
end

-- Print out the levels of each power type in the current state.
statePrototype.DebugPower = function(state)
	for powerType in pairs(OvalePower.POWER_INFO) do
		Ovale:FormatPrint("%s = %d", powerType, state[powerType])
	end
end
--</state-methods>
