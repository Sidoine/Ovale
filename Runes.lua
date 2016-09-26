--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

--[[
	This addon tracks rune information on death knights.

	TODO: Handle spells in the simulator that reactivate runes, e.g., Empower Rune Weapon, Blood Tap, etc.
--]]

local OVALE, Ovale = ...
local OvaleRunes = Ovale:NewModule("OvaleRunes", "AceEvent-3.0")
Ovale.OvaleRunes = OvaleRunes

--<private-static-properties>
local OvaleDebug = Ovale.OvaleDebug
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleEquipment = nil
local OvalePower = nil
local OvaleSpellBook = nil
local OvaleStance = nil
local OvaleState = nil

--local debugprint = print
local ipairs = ipairs
local pairs = pairs
local type = type
local wipe = wipe
local API_GetRuneCooldown = GetRuneCooldown
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local INFINITY = math.huge
local sort = sort

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvaleRunes)
-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleRunes)

-- Empower Rune Weapon immediately reactivates all runes.
local EMPOWER_RUNE_WEAPON = 47568

local RUNE_SLOTS = 6
--</private-static-properties>

--<public-static-properties>
-- Current rune information, indexed by slot.
OvaleRunes.rune = {}
--</public-static-properties>

--<private-static-methods>
local function IsActiveRune(rune, atTime)
	return (rune.startCooldown == 0 or rune.endCooldown <= atTime)
end
--</private-static-methods>

--<public-static-methods>
function OvaleRunes:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvaleEquipment = Ovale.OvaleEquipment
	OvalePower = Ovale.OvalePower
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleStance = Ovale.OvaleStance
	OvaleState = Ovale.OvaleState
end

function OvaleRunes:OnEnable()
	if Ovale.playerClass == "DEATHKNIGHT" then
		-- Initialize rune database.
		for slot = 1, RUNE_SLOTS do
			self.rune[slot] = { slot = slot, IsActiveRune = IsActiveRune }
		end
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAllRunes")
		self:RegisterEvent("RUNE_POWER_UPDATE")
		self:RegisterEvent("RUNE_TYPE_UPDATE")
		self:RegisterEvent("UNIT_RANGEDDAMAGE")
		self:RegisterEvent("UNIT_SPELL_HASTE", "UNIT_RANGEDDAMAGE")
		OvaleState:RegisterState(self, self.statePrototype)

		self:UpdateAllRunes()
	end
end

function OvaleRunes:OnDisable()
	if Ovale.playerClass == "DEATHKNIGHT" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		self:UnregisterEvent("RUNE_POWER_UPDATE")
		self:UnregisterEvent("RUNE_TYPE_UPDATE")
		self:UnregisterEvent("UNIT_RANGEDDAMAGE")
		self:UnregisterEvent("UNIT_SPELL_HASTE")
		OvaleState:UnregisterState(self)
		self.rune = {}
	end
end

function OvaleRunes:RUNE_POWER_UPDATE(event, slot, usable)
	self:Debug(event, slot, usable)
	self:UpdateRune(slot)
end

function OvaleRunes:RUNE_TYPE_UPDATE(event, slot)
	self:Debug(event, slot)
	self:UpdateRune(slot)
end

function OvaleRunes:UNIT_RANGEDDAMAGE(event, unitId)
	if unitId == "player" then
		self:Debug(event)
		self:UpdateAllRunes()
	end
end

function OvaleRunes:UpdateRune(slot)
	self:StartProfiling("OvaleRunes_UpdateRune")
	local rune = self.rune[slot]
	local start, duration, runeReady = API_GetRuneCooldown(slot)
	if start and duration then
		if start > 0 then
			-- Rune is on cooldown.
			rune.startCooldown = start
			rune.endCooldown = start + duration
		else
			-- Rune is active.
			rune.startCooldown = 0
			rune.endCooldown = 0
		end
		Ovale.refreshNeeded[Ovale.playerGUID] = true
	else
		self:Debug("Warning: rune information for slot %d not available.", slot)
	end
	self:StopProfiling("OvaleRunes_UpdateRune")
end

function OvaleRunes:UpdateAllRunes(event)
	self:Debug(event)
	for slot = 1, RUNE_SLOTS do
		self:UpdateRune(slot)
	end
end

function OvaleRunes:DebugRunes()
	local now = API_GetTime()
	for slot = 1, RUNE_SLOTS do
		local rune = self.rune[slot]
		if rune:IsActiveRune(now) then
			self:Print("rune[%d] is active.", slot)
		else
			self:Print("rune[%d] comes off cooldown in %f seconds.", slot, rune.endCooldown - now)
		end
	end
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.

	AFTER: OvalePower
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleRunes.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleRunes.statePrototype
--</private-static-properties>

--<state-properties>
-- indexed by slot (1 through 6)
statePrototype.rune = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleRunes:InitializeState(state)
	state.rune = {}
	for slot in ipairs(self.rune) do
		state.rune[slot] = {}
	end
end

-- Reset the state to the current conditions.
function OvaleRunes:ResetState(state)
	self:StartProfiling("OvaleRunes_ResetState")
	for slot, rune in ipairs(self.rune) do
		local stateRune = state.rune[slot]
		for k, v in pairs(rune) do
			stateRune[k] = v
		end
	end
	self:StopProfiling("OvaleRunes_ResetState")
end

-- Release state resources prior to removing from the simulator.
function OvaleRunes:CleanState(state)
	for slot, rune in ipairs(state.rune) do
		for k in pairs(rune) do
			rune[k] = nil
		end
		state.rune[slot] = nil
	end
end

-- Apply the effects of the spell at the start of the spellcast.
function OvaleRunes:ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvaleRunes_ApplySpellStartCast")
	-- Channeled spells cost resources at the start of the channel.
	if isChanneled then
		state:ApplyRuneCost(spellId, startCast, spellcast)
	end
	self:StopProfiling("OvaleRunes_ApplySpellStartCast")
end

-- Apply the effects of the spell on the player's state, assuming the spellcast completes.
function OvaleRunes:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvaleRunes_ApplySpellAfterCast")
	-- Instant or cast-time spells cost resources at the end of the spellcast.
	if not isChanneled then
		state:ApplyRuneCost(spellId, endCast, spellcast)

		if spellId == EMPOWER_RUNE_WEAPON then
			-- Empower Rune Weapon immediately reactivates all runes.
			for slot in ipairs(state.rune) do
				state:ReactivateRune(slot, endCast)
			end
		end
	end
	self:StopProfiling("OvaleRunes_ApplySpellAfterCast")
end
--</public-static-methods>

--<state-methods>
statePrototype.DebugRunes = function(state)
	OvaleRunes:Print("Current rune state:")
	local now = state.currentTime
	for slot, rune in ipairs(state.rune) do
		if rune:IsActiveRune(now) then
			OvaleRunes:Print("    rune[%d] is active.", slot)
		else
			OvaleRunes:Print("    rune[%d] comes off cooldown in %f seconds.", slot, rune.endCooldown - now)
		end
	end
end

-- Update the rune state with the rune cost of the give spell.
statePrototype.ApplyRuneCost = function(state, spellId, atTime, spellcast)
	local si = OvaleData.spellInfo[spellId]
	if si then
		local count = si.runes or 0
		while count > 0 do
			state:ConsumeRune(spellId, atTime, spellcast)
			count = count - 1
		end
	end
end

-- Reactivate the rune in the given slot.  If runeType is given, then reactivate as that type of rune.
statePrototype.ReactivateRune = function(state, slot, atTime)
	local rune = state.rune[slot]
	if atTime < state.currentTime then
		atTime = state.currentTime
	end
	if rune.startCooldown > atTime then
		rune.startCooldown = atTime
	end
	rune.endCooldown = atTime
end

-- Consume a rune of the given type.  Assume that the required runes are available.
statePrototype.ConsumeRune = function(state, spellId, atTime, snapshot)
	OvaleRunes:StartProfiling("OvaleRunes_state_ConsumeRune")
	--[[
		Find a usable rune, preferring a regular rune of that rune type over death
		runes of that rune type over death runes of any rune type.
	--]]
	local consumedRune
	-- Search for an active regular rune of the given rune type.
	for slot = 1, RUNE_SLOTS do
		local rune = state.rune[slot]
		if rune:IsActiveRune(atTime) then
			consumedRune = rune
			break
		end
	end
	
	if consumedRune then
		-- Put that rune on cooldown, starting when the other rune of that slot type comes off cooldown.
		local start = atTime
		for slot = 1, RUNE_SLOTS do
			local rune = state.rune[slot]
			if rune.endCooldown > start then
				start = rune.endCooldown
			end
		end

		local duration = 10 / state:GetSpellHasteMultiplier(snapshot)
		consumedRune.startCooldown = start
		consumedRune.endCooldown = start + duration

		-- Each rune consumed generates 10 runic power.
		local runicpower = state.runicpower
		runicpower = runicpower + 10
		local maxi = OvalePower.maxPower.runicpower
		state.runicpower = (runicpower < maxi) and runicpower or maxi
	else
		state:Log("No %s rune available at %f to consume for spell %d!", RUNE_NAME[runeType], atTime, spellId)
	end
	OvaleRunes:StopProfiling("OvaleRunes_state_ConsumeRune")
end

-- Returns a triplet of count, startCooldown, endCooldown:
--     count			The number of currently active runes of the given type.
--     startCooldown	The time at which the next rune of the given type went on cooldown.
--     endCooldown		The time at which the next rune of the given type will be active.
statePrototype.RuneCount = function(state, atTime)
	OvaleRunes:StartProfiling("OvaleRunes_state_RuneCount")
	atTime = atTime or state.currentTime
	local count = 0
	local startCooldown, endCooldown = INFINITY, INFINITY
	-- Match only the runes of the given type.
	for slot = 1, RUNE_SLOTS do
		local rune = state.rune[slot]
		if rune:IsActiveRune(atTime) then
			count = count + 1
		elseif rune.endCooldown < endCooldown then
			startCooldown, endCooldown = rune.startCooldown, rune.endCooldown
		end
	end
	OvaleRunes:StopProfiling("OvaleRunes_state_RuneCount")
	return count, startCooldown, endCooldown
end

-- Returns the number of seconds before all of the required runes are available.
statePrototype.GetRunesCooldown = nil
do
	-- The remaining count requirements, indexed by rune type.
	local count = {}
	local usedRune = {}

	statePrototype.GetRunesCooldown = function(state, atTime, runes)
		if runes <= 0 then return 0 end 
		if runes > RUNE_SLOTS then
			state:Log("Attempt to read %d runes but the maximum is %d", runes, RUNE_SLOTS)
			return 0
		end

		OvaleRunes:StartProfiling("OvaleRunes_state_GetRunesCooldown")
		atTime = atTime or state.currentTime

		-- Initialize static variables.
		for slot = 1, RUNE_SLOTS do
			local rune = state.rune[slot]
			usedRune[slot] = rune.endCooldown - atTime
		end

		sort(usedRune)
		OvaleRunes:StopProfiling("OvaleRunes_state_GetRunesCooldown")
		return usedRune[runes]
	end
end
--</state-methods>
