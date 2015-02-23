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
local API_GetRuneType = GetRuneType
local API_GetSpellInfo = GetSpellInfo
local API_GetTime = GetTime
local API_UnitClass = UnitClass
local INFINITY = math.huge

-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleRunes)

-- Player's class.
local _, self_class = API_UnitClass("player")

local BLOOD_RUNE = 1
local UNHOLY_RUNE = 2
local FROST_RUNE = 3
local DEATH_RUNE = 4

local RUNE_TYPE = {
	blood = BLOOD_RUNE,
	unholy = UNHOLY_RUNE,
	frost = FROST_RUNE,
	death = DEATH_RUNE,
}
local RUNE_NAME = {}
do
	for k, v in pairs(RUNE_TYPE) do
		RUNE_NAME[v] = k
	end
end

--[[
	Rune slots are numbered as follows in the default UI:

		blood	frost	unholy
		[1][2]	[5][6]	[3][4]
--]]
local RUNE_SLOTS = {
	[BLOOD_RUNE] =	{ 1, 2 },
	[UNHOLY_RUNE] =	{ 3, 4 },
	[FROST_RUNE] =	{ 5, 6 },
}

--[[
	From SimulationCraft's sc_death_knight.cpp:

	If explicitly consuming a death rune, any death runes available are preferred in the order:

		frost > blood > unholy.

	If consuming a non-death rune of a given type and that no rune of that type is available,
	any death runes available are preferred in the order:

		blood > unholy > frost
--]]
local DEATH_RUNE_PRIORITY = { 3, 4, 5, 6, 1, 2 }
local ANY_RUNE_PRIORITY = { 1, 2, 3, 4, 5, 6 }

-- Blood of the North (frost) permanently transforms Blood Runes into Death Runes.
local BLOOD_OF_THE_NORTH = 54637
-- Blood Rites (blood) causes the Frost and Unholy runes consumed by Death Strike to reactivate as Death runes.
local BLOOD_RITES = 50034
local BLOOD_RITES_ATTACK = {
	[49998] = API_GetSpellInfo(49998),	-- Death Strike
}
-- Reaping (unholy) causes the runes consumed by Blood Strike, Pestilence, Festering Strike, Icy Touch or Blood Boil to reactivate as Death Runes.
local REAPING = 56835
local REAPING_ATTACK = {
	[45477] = API_GetSpellInfo(45477),	-- Icy Touch
	[50842] = API_GetSpellInfo(50842),	-- Pestilence
	[85948] = API_GetSpellInfo(85948),	-- Festering Strike
}
-- Empower Rune Weapon immediately reactivates all runes.
local EMPOWER_RUNE_WEAPON = 47568
-- 4pT16 tanking bonus causes Dancing Rune Weapon to reactivate immediately all Frost and Unholy runes as Death runes.
local DANCING_RUNE_WEAPON = 49028
--</private-static-properties>

--<public-static-properties>
-- Current rune information, indexed by slot.
OvaleRunes.rune = {}
OvaleRunes.RUNE_TYPE = RUNE_TYPE
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
	if self_class == "DEATHKNIGHT" then
		-- Initialize rune database.
		for runeType, slots in ipairs(RUNE_SLOTS) do
			for _, slot in pairs(slots) do
				self.rune[slot] = { slot = slot, slotType = runeType, IsActiveRune = IsActiveRune }
			end
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
	if self_class == "DEATHKNIGHT" then
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
	self:UpdateRune(slot)
end

function OvaleRunes:RUNE_TYPE_UPDATE(event, slot)
	self:UpdateRune(slot)
end

function OvaleRunes:UNIT_RANGEDDAMAGE(event, unitId)
	if unitId == "player" then
		self:UpdateAllRunes()
	end
end

function OvaleRunes:UpdateRune(slot)
	self:StartProfiling("OvaleRunes_UpdateRune")
	local rune = self.rune[slot]
	local runeType = API_GetRuneType(slot)
	local start, duration, runeReady = API_GetRuneCooldown(slot)
	rune.type = runeType
	if start > 0 then
		-- Rune is on cooldown.
		rune.startCooldown = start
		rune.endCooldown = start + duration
	else
		-- Rune is active.
		rune.startCooldown = 0
		rune.endCooldown = 0
	end
	Ovale.refreshNeeded.player = true
	self:StopProfiling("OvaleRunes_UpdateRune")
end

function OvaleRunes:UpdateAllRunes()
	for slot = 1, 6 do
		self:UpdateRune(slot)
	end
end

function OvaleRunes:DebugRunes()
	local now = API_GetTime()
	for slot = 1, 6 do
		local rune = self.rune[slot]
		if rune:IsActiveRune(now) then
			self:Print("rune[%d] (%s) is active.", slot, RUNE_NAME[rune.type])
		else
			self:Print("rune[%d] (%s) comes off cooldown in %f seconds.", slot, RUNE_NAME[rune.type], rune.endCooldown - now)
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
		elseif spellId == DANCING_RUNE_WEAPON and OvaleEquipment:GetArmorSetCount("T16_tank") >= 4 then
			-- 4pT16 tanking bonus causes Dancing Rune Weapon to reactivate immediately all Frost and Unholy runes as Death runes.
			for slot in ipairs(RUNE_SLOTS[FROST_RUNE]) do
				state:ReactivateRune(slot, endCast, DEATH_RUNE)
			end
			for slot in ipairs(RUNE_SLOTS[UNHOLY_RUNE]) do
				state:ReactivateRune(slot, endCast, DEATH_RUNE)
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
			OvaleRunes:Print("    rune[%d] (%s) is active.", slot, RUNE_NAME[rune.type])
		else
			OvaleRunes:Print("    rune[%d] (%s) comes off cooldown in %f seconds.", slot, RUNE_NAME[rune.type], rune.endCooldown - now)
		end
	end
end

-- Update the rune state with the rune cost of the give spell.
statePrototype.ApplyRuneCost = function(state, spellId, atTime, spellcast)
	local si = OvaleData.spellInfo[spellId]
	if si then
		for i, name in ipairs(RUNE_NAME) do
			local count = si[name] or 0
			while count > 0 do
				state:ConsumeRune(spellId, atTime, name, spellcast)
				count = count - 1
			end
		end
	end
end

-- Reactivate the rune in the given slot.  If runeType is given, then reactivate as that type of rune.
statePrototype.ReactivateRune = function(state, slot, atTime, runeType)
	local rune = state.rune[slot]
	if atTime < state.currentTime then
		atTime = state.currentTime
	end
	if rune.startCooldown > atTime then
		rune.startCooldown = atTime
	end
	rune.endCooldown = atTime
	if runeType then
		rune.type = runeType
	end
end

-- Consume a rune of the given type.  Assume that the required runes are available.
statePrototype.ConsumeRune = function(state, spellId, atTime, name, snapshot)
	OvaleRunes:StartProfiling("OvaleRunes_state_ConsumeRune")
	--[[
		Find a usable rune, preferring a regular rune of that rune type over death
		runes of that rune type over death runes of any rune type.
	--]]
	local consumedRune
	local runeType = RUNE_TYPE[name]
	if runeType ~= DEATH_RUNE then
		-- Search for an active regular rune of the given rune type.
		for _, slot in ipairs(RUNE_SLOTS[runeType]) do
			local rune = state.rune[slot]
			if rune.type == runeType and rune:IsActiveRune(atTime) then
				consumedRune = rune
				break
			end
		end
		if not consumedRune then
			-- Search for an active death rune of the given rune type.
			for _, slot in ipairs(RUNE_SLOTS[runeType]) do
				local rune = state.rune[slot]
				if rune.type == DEATH_RUNE and rune:IsActiveRune(atTime) then
					consumedRune = rune
					break
				end
			end
		end
	end
	-- No runes of the right type are active, so look for any active death rune.
	if not consumedRune then
		local deathRunePriority = (runeType == DEATH_RUNE) and DEATH_RUNE_PRIORITY or ANY_RUNE_PRIORITY
		for _, slot in ipairs(deathRunePriority) do
			local rune = state.rune[slot]
			if rune.type == DEATH_RUNE and rune:IsActiveRune(atTime) then
				consumedRune = rune
				break
			end
		end
	end
	if consumedRune then
		-- Put that rune on cooldown, starting when the other rune of that slot type comes off cooldown.
		local slotType = consumedRune.slotType
		local start = atTime
		for _, slot in ipairs(RUNE_SLOTS[slotType]) do
			local rune = state.rune[slot]
			if rune.endCooldown > start then
				start = rune.endCooldown
			end
		end
		local duration = 10 / state:GetSpellHasteMultiplier(snapshot)
		consumedRune.startCooldown = start
		consumedRune.endCooldown = start + duration

		-- Set the type of rune that this consumed rune will reactivate as.
		if slotType == BLOOD_RUNE and OvaleSpellBook:IsKnownSpell(BLOOD_OF_THE_NORTH) then
			-- Blood of the North (frost) permanently transforms Blood Runes into Death Runes.
			consumedRune.type = DEATH_RUNE
		elseif (slotType == FROST_RUNE or slotType == UNHOLY_RUNE) and BLOOD_RITES_ATTACK[spellId] and OvaleSpellBook:IsKnownSpell(BLOOD_RITES) then
			-- Blood Rites (blood) causes the Frost and Unholy runes consumed by Death Strike to reactivate as Death runes.
			consumedRune.type = DEATH_RUNE
		elseif REAPING_ATTACK[spellId] and OvaleSpellBook:IsKnownSpell(REAPING) then
			-- Reaping (unholy) causes the runes consumed by Blood Strike, Pestilence, Festering Strike, Icy Touch or
			-- Blood Boil to reactivate as Death Runes.
			consumedRune.type = DEATH_RUNE
		else
			-- In all other cases, runes reactivate according to their slot type.
			consumedRune.type = slotType
		end

		-- Each rune consumed generates 10 (12, if in Frost Presence) runic power.
		local runicpower = state.runicpower
		if OvaleStance:IsStance("deathknight_frost_presence") then
			runicpower = runicpower + 12
		else
			runicpower = runicpower + 10
		end
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
statePrototype.RuneCount = function(state, name, includeDeath, atTime)
	OvaleRunes:StartProfiling("OvaleRunes_state_RuneCount")
	-- Default to matching death runes of the same type.
	if type(includeDeath) == "number" then
		includeDeath, atTime = nil, includeDeath
	end
	atTime = atTime or state.currentTime
	local count = 0
	local startCooldown, endCooldown = INFINITY, INFINITY
	local runeType = RUNE_TYPE[name]
	if runeType ~= DEATH_RUNE and not includeDeath then
		-- Match only the runes of the given type.
		for _, slot in ipairs(RUNE_SLOTS[runeType]) do
			local rune = state.rune[slot]
			if rune.type == runeType or (includeDeath == nil and rune.type == DEATH_RUNE) then
				if rune:IsActiveRune(atTime) then
					count = count + 1
				elseif rune.endCooldown < endCooldown then
					startCooldown, endCooldown = rune.startCooldown, rune.endCooldown
				end
			end
		end
	else
		-- Match any runes that can satisfy the rune type.
		for slot, rune in ipairs(state.rune) do
			if rune.type == runeType or rune.type == DEATH_RUNE then
				if rune:IsActiveRune(atTime) then
					count = count + 1
				elseif rune.endCooldown < endCooldown then
					startCooldown, endCooldown = rune.startCooldown, rune.endCooldown
				end
			end
		end
	end
	OvaleRunes:StopProfiling("OvaleRunes_state_RuneCount")
	return count, startCooldown, endCooldown
end

statePrototype.DeathRuneCount = function(state, name, atTime)
	OvaleRunes:StartProfiling("OvaleRunes_state_DeathRuneCount")
	atTime = atTime or state.currentTime
	local count = 0
	local startCooldown, endCooldown = INFINITY, INFINITY
	local runeType = RUNE_TYPE[name]
	if runeType ~= DEATH_RUNE then
		-- Match only the runes of the given type.
		for _, slot in ipairs(RUNE_SLOTS[runeType]) do
			local rune = state.rune[slot]
			if rune.type == DEATH_RUNE then
				if rune:IsActiveRune(atTime) then
					count = count + 1
				elseif rune.endCooldown < endCooldown then
					startCooldown, endCooldown = rune.startCooldown, rune.endCooldown
				end
			end
		end
	end
	OvaleRunes:StopProfiling("OvaleRunes_state_DeathRuneCount")
	return count, startCooldown, endCooldown
end

-- Returns the number of seconds before all of the required runes are available.
statePrototype.GetRunesCooldown = nil
do
	-- The remaining count requirements, indexed by rune type.
	local count = {}
	local usedRune = {}

	statePrototype.GetRunesCooldown = function(state, blood, unholy, frost, death, atTime)
		OvaleRunes:StartProfiling("OvaleRunes_state_GetRunesCooldown")
		atTime = atTime or state.currentTime

		-- Initialize static variables.
		count[BLOOD_RUNE] = blood or 0
		count[UNHOLY_RUNE] = unholy or 0
		count[FROST_RUNE] = frost or 0
		count[DEATH_RUNE] = death or 0
		wipe(usedRune)

		for runeType in pairs(RUNE_SLOTS) do
			-- Match active, regular runes.
			for _, slot in pairs(RUNE_SLOTS[runeType]) do
				if count[runeType] == 0 then break end
				local rune = state.rune[slot]
				if not usedRune[rune] and rune.type ~= DEATH_RUNE and IsActiveRune(rune, atTime) then
					--debugprint(string.format("    [1] Match active regular rune in slot %d to %s", slot, RUNE_NAME[runeType]))
					usedRune[rune] = true
					count[runeType] = count[runeType] - 1
				end
			end
			-- Match active death runes of the same socket type.
			for _, slot in pairs(RUNE_SLOTS[runeType]) do
				if count[runeType] == 0 then break end
				local rune = state.rune[slot]
				if not usedRune[rune] and rune.type == DEATH_RUNE and IsActiveRune(rune, atTime) then
					--debugprint(string.format("    [2] Match active death rune in slot %d to %s, type = %s", slot, RUNE_NAME[slotType]))
					usedRune[rune] = true
					count[runeType] = count[runeType] - 1
				end
			end
		end
		-- Match active death runes in DEATH_RUNE_PRIORITY order to meet death count requirements.
		for _, slot in ipairs(DEATH_RUNE_PRIORITY) do
			if count[DEATH_RUNE] == 0 then break end
			local rune = state.rune[slot]
			if not usedRune[rune] and rune.type == DEATH_RUNE and IsActiveRune(rune, atTime) then
				--debugprint(string.format("    [3] Match active death rune in slot %d", slot))
				usedRune[rune] = true
				count[DEATH_RUNE] = count[DEATH_RUNE] - 1
			end
		end
		-- At this point, if count[runeType] > 0 then there are no active runes of the appropriate type that match that requirement.
		-- Match active death runes in ANY_RUNE_PRIORITY order to meet remaining count requirements.
		for _, runeType in pairs(RUNE_TYPE) do
			for _, slot in ipairs(ANY_RUNE_PRIORITY) do
				if count[runeType] == 0 then break end
				local rune = state.rune[slot]
				if not usedRune[rune] and rune.type == DEATH_RUNE and IsActiveRune(rune, atTime) then
					--debugprint(string.format("    [4] Match active death rune in slot %d to %s", slot, RUNE_NAME[runeType]))
					usedRune[rune] = true
					count[runeType] = count[runeType] - 1
				end
			end
		end

		-- At this point, there are no more active runes, death or otherwise, that can satisfy count requirements.
		for runeType, slotList in pairs(RUNE_SLOTS) do
			-- Match regenerating runes of the appropriate socket type.
			if count[runeType] > 0 then
				local slot1, slot2 = slotList[1], slotList[2]
				local rune1, rune2 = state.rune[slot1], state.rune[slot2]
				if count[runeType] == 1 then
					local rune, slot
					if not usedRune[rune1] and not usedRune[rune2] then
						rune = (rune1.endCooldown < rune2.endCooldown) and rune1 or rune2
						slot = (rune1.endCooldown < rune2.endCooldown) and slot1 or slot2
					elseif not usedRune[rune1] then
						rune = rune1
						slot = slot1
					elseif not usedRune[rune2] then
						rune = rune2
						slot = slot2
					end
					if rune then
						--debugprint(string.format("    [5] Match regenerating rune in slot %d to %s", slot, RUNE_NAME[runeType]))
						usedRune[rune] = true
						count[runeType] = 0
					end
				else -- if count[runeType] == 2 then
					if not usedRune[rune1] and not usedRune[rune2] then	
						--debugprint(string.format("    [5] Match regenerating rune in slot %d to %s", slot1, RUNE_NAME[runeType]))
						--debugprint(string.format("    [5] Match regenerating rune in slot %d to %s", slot2, RUNE_NAME[runeType]))
						usedRune[rune1] = true
						usedRune[rune2] = true
						count[runeType] = 0
					elseif not usedRune[rune1] then
						--debugprint(string.format("    [5] Match regenerating rune in slot %d to %s", slot1, RUNE_NAME[runeType]))
						usedRune[rune1] = true
						count[runeType] = 1
					elseif not usedRune[rune2] then
						--debugprint(string.format("    [5] Match regenerating rune in slot %d to %s", slot2, RUNE_NAME[runeType]))
						usedRune[rune2] = true
						count[runeType] = 1
					end
				end
			end
			-- Match any unused, regenerating death runes.
			for slot, rune in pairs(state.rune) do
				if count[runeType] == 0 then break end
				if not usedRune[rune] and rune.type == DEATH_RUNE then
					--debugprint(string.format("    [6] Match regenerating rune in slot %d to %s", slot, RUNE_NAME[runeType]))
					usedRune[rune] = true
					count[runeType] = count[runeType] - 1
				end
			end
		end

		-- Replace any used runes with a regenerating death rune with a shorter cooldown.
		for slot, rune in pairs(state.rune) do
			if not usedRune[rune] and rune.type == DEATH_RUNE then
				for used in pairs(usedRune) do
					if rune.endCooldown < used.endCooldown then
						--debugprint(string.format("    [7] Replacing matched rune in slot %d with regenerating rune in slot %d", used.slot, slot))
						usedRune[used] = nil
						usedRune[rune] = true
						break
					end
				end
			end
		end

		-- This shouldn't happen because it means the rune requirements will never be met.
		for _, runeType in pairs(RUNE_TYPE) do
			if count[runeType] > 0 then
				state:Log("Impossible rune count requirements: blood=%d, unholy=%d, frost=%d, death=%d", blood, unholy, frost, death)
				OvaleRunes:StopProfiling("OvaleRunes_state_GetRunesCooldown")
				return INFINITY
			end
		end

		local seconds = 0
		local maxEndCooldown = 0
		for rune in pairs(usedRune) do
			if maxEndCooldown < rune.endCooldown then
				maxEndCooldown = rune.endCooldown
			end
		end
		if maxEndCooldown > atTime then
			seconds = maxEndCooldown - atTime
		end

		OvaleRunes:StopProfiling("OvaleRunes_state_GetRunesCooldown")
		return seconds
	end
end
--</state-methods>
