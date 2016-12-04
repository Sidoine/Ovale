--[[--------------------------------------------------------------------
    Copyright (C) 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleTotem = Ovale:NewModule("OvaleTotem", "AceEvent-3.0")
Ovale.OvaleTotem = OvaleTotem

--<private-static-properties>
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleSpellBook = nil
local OvaleState = nil

local ipairs = ipairs
local pairs = pairs
local API_GetTotemInfo = GetTotemInfo
local AIR_TOTEM_SLOT = AIR_TOTEM_SLOT		-- FrameXML\Constants
local EARTH_TOTEM_SLOT = EARTH_TOTEM_SLOT	-- FrameXML\Constants
local FIRE_TOTEM_SLOT = FIRE_TOTEM_SLOT		-- FrameXML\Constants
local INFINITY = math.huge
local MAX_TOTEMS = MAX_TOTEMS				-- FrameXML\Constants
local WATER_TOTEM_SLOT = WATER_TOTEM_SLOT	-- FrameXML\Constants

-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleTotem)

-- Current age of totem state.
local self_serial = 0

-- Classes that can have totems.
local TOTEM_CLASS = {
	DRUID = true,			-- Wild Mushroom
	MAGE = true,			-- Rune of Power, Prismatic Crystal
	MONK = true,			-- Summon Black Ox Statue, Summon Jade Serpent Statue
	SHAMAN = true,			-- Totems
}

-- Maps totem type to the totem slot.
local TOTEM_SLOT = {
	air = AIR_TOTEM_SLOT,
	earth = EARTH_TOTEM_SLOT,
	fire = FIRE_TOTEM_SLOT,
	water = WATER_TOTEM_SLOT,
	spirit_wolf = 1
}

-- Shaman's Totemic Recall destroys all totems.
local TOTEMIC_RECALL = 36936
--</private-static-properties>

--<public-static-properties>
-- Current totem information, indexed by slot.
OvaleTotem.totem = {}
--</public-static-properties>

--<public-static-methods>
function OvaleTotem:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleState = Ovale.OvaleState
end

function OvaleTotem:OnEnable()
	if TOTEM_CLASS[Ovale.playerClass] then
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
		self:RegisterEvent("PLAYER_TALENT_UPDATE", "Update")
		self:RegisterEvent("PLAYER_TOTEM_UPDATE", "Update")
		self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "Update")
		OvaleState:RegisterState(self, self.statePrototype)
	end
end

function OvaleTotem:OnDisable()
	if TOTEM_CLASS[Ovale.playerClass] then
		OvaleState:UnregisterState(self)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		self:UnregisterEvent("PLAYER_TALENT_UPDATE")
		self:UnregisterEvent("PLAYER_TOTEM_UPDATE")
		self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	end
end

function OvaleTotem:Update()
	-- Advance age of current totem state.
	self_serial = self_serial + 1
	Ovale.refreshNeeded[Ovale.playerGUID] = true
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleTotem.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleTotem.statePrototype
--</private-static-properties>

--<state-properties>
-- Totem state, indexed by slot (1 through 4).
statePrototype.totem = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleTotem:InitializeState(state)
	state.totem = {}
	for slot = 1, MAX_TOTEMS do
		state.totem[slot] = {}
	end
end

-- Release state resources prior to removing from the simulator.
function OvaleTotem:CleanState(state)
	for slot, totem in pairs(state.totem) do
		for k in pairs(totem) do
			totem[k] = nil
		end
		state.totem[slot] = nil
	end
end

-- Apply the effects of the spell when the spellcast completes.
function OvaleTotem:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvaleTotem_ApplySpellAfterCast")
	if Ovale.playerClass == "SHAMAN" and spellId == TOTEMIC_RECALL then
		-- Shaman's Totemic Recall destroys all totems.
		for slot in ipairs(state.totem) do
			state:DestroyTotem(slot, endCast)
		end
	else
		-- Summon a totem in the slot after the cast has ended.
		local atTime = endCast
		local slot = state:GetTotemSlot(spellId, atTime)
		if slot then
			state:SummonTotem(spellId, slot, atTime)
		end
	end
	self:StopProfiling("OvaleTotem_ApplySpellAfterCast")
end
--</public-static-methods>

--<state-methods>
statePrototype.IsActiveTotem = function(state, totem, atTime)
	atTime = atTime or state.currentTime
	local boolean = false
	if totem and (totem.serial == self_serial) and totem.start and totem.duration and totem.start < atTime and atTime < totem.start + totem.duration then
		boolean = true
	end
	return boolean
end

-- Return the table holding the simulator's totem information for the given slot.
statePrototype.GetTotem = function(state, slot)
	OvaleTotem:StartProfiling("OvaleTotem_state_GetTotem")
	slot = TOTEM_SLOT[slot] or slot
	-- Populate the totem information from the current game state if it is outdated.
	local totem = state.totem[slot]
	if totem and (not totem.serial or totem.serial < self_serial) then
		local haveTotem, name, startTime, duration, icon = API_GetTotemInfo(slot)
		if haveTotem then
			totem.name = name
			totem.start = startTime
			totem.duration = duration
			totem.icon = icon
		else
			totem.name = ""
			totem.start = 0
			totem.duration = 0
			totem.icon = ""
		end
		totem.serial = self_serial
	end
	OvaleTotem:StopProfiling("OvaleTotem_state_GetTotem")
	return totem
end

-- Return the totem information in the given slot in the simulator.
statePrototype.GetTotemInfo = function(state, slot)
	local haveTotem, name, startTime, duration, icon
	slot = TOTEM_SLOT[slot] or slot
	local totem = state:GetTotem(slot)
	if totem then
		haveTotem = state:IsActiveTotem(totem)
		name = totem.name
		startTime = totem.start
		duration = totem.duration
		icon = totem.icon
	end
	return haveTotem, name, startTime, duration, icon
end

-- Return the number of totems previously summoned by the spell and the interval of time that at least one totem is active.
statePrototype.GetTotemCount = function(state, spellId, atTime)
	atTime = atTime or state.currentTime
	local start, ending
	local count = 0
	local si = OvaleData.spellInfo[spellId]
	if si and si.totem then
		local buffPresent = true
		-- "buff_totem" is the ID of the aura applied by the totem summoned by the spell.
		-- If the aura is absent, then the totem is considered to be expired.
		if si.buff_totem then
			local aura = state:GetAura("player", si.buff_totem)
			buffPresent = state:IsActiveAura(aura, atTime)
		end
		if buffPresent then
			local texture = OvaleSpellBook:GetSpellTexture(spellId)
			-- "max_totems" is the maximum number of the totem that can be summoned concurrently.
			-- Default to allowing only one such totem.
			local maxTotems = si.max_totems or 1
			for slot in ipairs(state.totem) do
				local totem = state:GetTotem(slot)
				if state:IsActiveTotem(totem, atTime) and totem.icon == texture then
					count = count + 1
					-- Save earliest start time.
					if not start or start > totem.start then
						start = totem.start
					end
					-- Save latest ending time.
					if not ending or ending < totem.start + totem.duration then
						ending = totem.start + totem.duration
					end
				end
				if count >= maxTotems then
					break
				end
			end
		end
	end
	return count, start, ending
end

-- Return the totem slot that will contain the totem summoned by the spell.
statePrototype.GetTotemSlot = function(state, spellId, atTime)
	OvaleTotem:StartProfiling("OvaleTotem_state_GetTotemSlot")
	atTime = atTime or state.currentTime
	local totemSlot
	local si = OvaleData.spellInfo[spellId]
	if si and si.totem then
		-- Check if the totem summoned by the spell maps to a known totem slot.
		totemSlot = TOTEM_SLOT[si.totem]
		if not totemSlot then
			-- Find the first available totem slot.
			local availableSlot
			for slot in ipairs(state.totem) do
				local totem = state:GetTotem(slot)
				if not state:IsActiveTotem(totem, atTime) then
					availableSlot = slot
					break
				end
			end

			local texture = OvaleSpellBook:GetSpellTexture(spellId)
			-- "max_totems" is the maximum number of the totem that can be summoned concurrently.
			-- Default to allowing only one such totem.
			local maxTotems = si.max_totems or 1
			local count = 0
			-- Find the totem slot with the oldest such totem.
			local start = INFINITY
			for slot in ipairs(state.totem) do
				local totem = state:GetTotem(slot)
				if state:IsActiveTotem(totem, atTime) and totem.icon == texture then
					count = count + 1
					if start > totem.start then
						start = totem.start
						totemSlot = slot
					end
				end
			end
			-- If there are fewer than the maximum number of totems, then summon into the first available slot.
			if count < maxTotems then
				totemSlot = availableSlot
			end
		end
		-- Catch-all: if there are no totem slots for the spell, then summon the totem into the first totem slot.
		totemSlot = totemSlot or 1
	end
	OvaleTotem:StopProfiling("OvaleTotem_state_GetTotemSlot")
	return totemSlot
end

-- Summon a totem into the slot in the simulator at the given time.
statePrototype.SummonTotem = function(state, spellId, slot, atTime)
	OvaleTotem:StartProfiling("OvaleTotem_state_SummonTotem")
	atTime = atTime or state.currentTime
	slot = TOTEM_SLOT[slot] or slot
	state:Log("Spell %d summons totem into slot %d.", spellId, slot)
	local name, _, icon = OvaleSpellBook:GetSpellInfo(spellId)
	local duration = state:GetSpellInfoProperty(spellId, atTime, "duration")
	local totem = state.totem[slot]
	-- The name is not always the same as the name of the summoning spell, but totems
	-- are compared based on their icon/texture, so this inaccuracy doesn't break anything.
	totem.name = name
	totem.start = atTime
	-- Default to 15 seconds if no duration is found.
	totem.duration = duration or 15
	totem.icon = icon
	OvaleTotem:StopProfiling("OvaleTotem_state_SummonTotem")
end

-- Destroy the totem in the slot at the given time.
statePrototype.DestroyTotem = function(state, slot, atTime)
	OvaleTotem:StartProfiling("OvaleTotem_state_DestroyTotem")
	atTime = atTime or state.currentTime
	slot = TOTEM_SLOT[slot] or slot
	state:Log("Destroying totem in slot %d.", slot)
	local totem = state.totem[slot]
	local duration = atTime - totem.start
	if duration < 0 then
		duration = 0
	end
	totem.duration = duration
	OvaleTotem:StopProfiling("OvaleTotem_state_DestroyTotem")
end
--</state-methods>
