--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- Gather information about ennemies

local OVALE, Ovale = ...
local OvaleEnemies = Ovale:NewModule("OvaleEnemies", "AceEvent-3.0", "AceTimer-3.0")
Ovale.OvaleEnemies = OvaleEnemies

--<private-static-properties>
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleGUID = nil
local OvaleState = nil

local bit_band = bit.band
local bit_bor = bit.bor
local ipairs = ipairs
local pairs = pairs
local strfind = string.find
local tostring = tostring
local wipe = wipe
local API_GetTime = GetTime
local COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE
local COMBATLOG_OBJECT_AFFILIATION_PARTY = COMBATLOG_OBJECT_AFFILIATION_PARTY
local COMBATLOG_OBJECT_AFFILIATION_RAID = COMBATLOG_OBJECT_AFFILIATION_RAID
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY

-- Bitmask for player, party or raid unit controller affiliation.
local GROUP_MEMBER = bit_bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvaleEnemies)
-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleEnemies)

--[[
	List of CLEU event suffixes that can correspond to the player damaging or try to
	damage (tag) an enemy, or vice versa.
--]]
local CLEU_TAG_SUFFIXES = {
	"_DAMAGE",
	"_MISSED",
	"_AURA_APPLIED",
	"_AURA_APPLIED_DOSE",
	"_AURA_REFRESH",
	"_CAST_START",
	"_INTERRUPT",
	"_DISPEL",
	"_DISPEL_FAILED",
	"_STOLEN",
	"_DRAIN",
	"_LEECH",
}

-- Table of CLEU events for auto-attacks.
local CLEU_AUTOATTACK = {
	RANGED_DAMAGE = true,
	RANGED_MISSED = true,
	SWING_DAMAGE = true,
	SWING_MISSED = true,
}

-- Table of CLEU events for when a unit is removed from combat.
local CLEU_UNIT_REMOVED = {
	UNIT_DESTROYED = true,
	UNIT_DIED = true,
	UNIT_DISSIPATES = true,
}

-- Player's GUID.
local self_playerGUID = nil

-- enemyName[guid] = name
local self_enemyName = {}
-- enemyLastSeen[guid] = timestamp
local self_enemyLastSeen = {}
-- taggedEnemyLastSeen[guid] = timestamp
-- GUIDs used as keys for this table are a subset of the GUIDs used for enemyLastSeen.
local self_taggedEnemyLastSeen = {}

-- Timer for reaper function to remove inactive enemies.
local self_reaperTimer = nil
local REAP_INTERVAL = 3
--</private-static-properties>

--<public-static-properties>
-- Total number of active enemies.
OvaleEnemies.activeEnemies = 0
-- Total number of tagged enemies.
OvaleEnemies.taggedEnemies = 0
--</public-static-properties>

--<private-static-methods>
local function IsTagEvent(cleuEvent)
	local isTagEvent = false
	if CLEU_AUTOATTACK[cleuEvent] then
		isTagEvent = true
	else
		for _, suffix in ipairs(CLEU_TAG_SUFFIXES) do
			if strfind(cleuEvent, suffix .. "$") then
				isTagEvent = true
				break
			end
		end
	end
	return isTagEvent
end

local function IsFriendly(unitFlags, isGroupMember)
	return bit_band(unitFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 and (not isGroupMember or bit_band(unitFlags, GROUP_MEMBER) > 0)
end
--</private-static-methods>

--<public-static-methods>
function OvaleEnemies:OnInitialize()
	-- Resolve module dependencies.
	OvaleGUID = Ovale.OvaleGUID
	OvaleState = Ovale.OvaleState
end

function OvaleEnemies:OnEnable()
	self_playerGUID = Ovale.playerGUID
	if not self_reaperTimer then
		self_reaperTimer = self:ScheduleRepeatingTimer("RemoveInactiveEnemies", REAP_INTERVAL)
	end
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvaleEnemies:OnDisable()
	OvaleState:UnregisterState(self)
	if not self_reaperTimer then
		self:CancelTimer(self_reaperTimer)
		self_reaperTimer = nil
	end
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
end

function OvaleEnemies:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	if CLEU_UNIT_REMOVED[cleuEvent] then
		local now = API_GetTime()
		self:RemoveEnemy(cleuEvent, destGUID, now, true)
	elseif sourceGUID and sourceGUID ~= "" and sourceName and sourceFlags and destGUID and destGUID ~= "" and destName and destFlags then
		if not IsFriendly(sourceFlags) and IsFriendly(destFlags, true) then
			--[[
				Unfriendly enemy attacks friendly group member.
				Filter out periodic damage effects since they can occur after the caster's death
				and can cause false positives.
			--]]
			if not cleuEvent == "SPELL_PERIODIC_DAMAGE" and IsTagEvent(cleuEvent) then
				local now = API_GetTime()
				self:AddEnemy(cleuEvent, sourceGUID, sourceName, now)
			end
		elseif IsFriendly(sourceFlags, true) and not IsFriendly(destFlags) and IsTagEvent(cleuEvent) then
			-- Friendly group member attacks unfriendly enemy.
			local now = API_GetTime()
			-- Treat both player and pet attacks as a player tag.
			local isPlayerTag = (sourceGUID == self_playerGUID) or OvaleGUID:IsPlayerPet(sourceGUID)
			self:AddEnemy(cleuEvent, destGUID, destName, now, isPlayerTag)
		end
	end
end

function OvaleEnemies:PLAYER_REGEN_DISABLED()
	-- Reset enemy tracking when combat starts.
	wipe(self_enemyName)
	wipe(self_enemyLastSeen)
	wipe(self_taggedEnemyLastSeen)
	self.activeEnemies = 0
	self.taggedEnemies = 0
end

--[[
	Remove enemies that have been inactive for at least REAP_INTERVAL seconds.
	These enemies are not in combat with your group, out of range, or
	incapacitated and shouldn't count toward the number of active enemies.
--]]
function OvaleEnemies:RemoveInactiveEnemies()
	self:StartProfiling("OvaleEnemies_RemoveInactiveEnemies")
	local now = API_GetTime()
	-- Remove inactive enemies first.
	for guid, timestamp in pairs(self_enemyLastSeen) do
		if now - timestamp > REAP_INTERVAL then
			self:RemoveEnemy("REAPED", guid, now)
		end
	end
	-- Remove inactive tagged enemies last.
	for guid, timestamp in pairs(self_taggedEnemyLastSeen) do
		if now - timestamp > REAP_INTERVAL then
			self:RemoveTaggedEnemy("REAPED", guid, now)
		end
	end
	self:StopProfiling("OvaleEnemies_RemoveInactiveEnemies")
end

function OvaleEnemies:AddEnemy(cleuEvent, guid, name, timestamp, isTagged)
	self:StartProfiling("OvaleEnemies_AddEnemy")
	if guid then
		self_enemyName[guid] = name
		local changed = false
		do
			-- Update last time this enemy was seen.
			if not self_enemyLastSeen[guid] then
				self.activeEnemies = self.activeEnemies + 1
				changed = true
			end
			self_enemyLastSeen[guid] = timestamp
		end
		if isTagged then
			-- Update last time this enemy was tagged.
			if not self_taggedEnemyLastSeen[guid] then
				self.taggedEnemies = self.taggedEnemies + 1
				changed = true
			end
			self_taggedEnemyLastSeen[guid] = timestamp
		end
		if changed then
			self:DebugTimestamp("%s: %d/%d enemy seen: %s (%s)", cleuEvent, self.taggedEnemies, self.activeEnemies, guid, name)
			Ovale.refreshNeeded[self_playerGUID] = true
		end
	end
	self:StopProfiling("OvaleEnemies_AddEnemy")
end

function OvaleEnemies:RemoveEnemy(cleuEvent, guid, timestamp, isDead)
	self:StartProfiling("OvaleEnemies_RemoveEnemy")
	if guid then
		local name = self_enemyName[guid]
		local changed = false
		-- Update seen enemy count.
		if self_enemyLastSeen[guid] then
			self_enemyLastSeen[guid] = nil
			if self.activeEnemies > 0 then
				self.activeEnemies = self.activeEnemies - 1
				changed = true
			end
		end
		-- Update tagged enemy count.
		if self_taggedEnemyLastSeen[guid] then
			self_taggedEnemyLastSeen[guid] = nil
			if self.taggedEnemies > 0 then
				self.taggedEnemies = self.taggedEnemies - 1
				changed = true
			end
		end
		if changed then
			self:DebugTimestamp("%s: %d/%d enemy %s: %s (%s)", cleuEvent, self.taggedEnemies, self.activeEnemies, isDead and "died" or "removed", guid, name)
			Ovale.refreshNeeded[self_playerGUID] = true
			self:SendMessage("Ovale_InactiveUnit", guid, isDead)
		end
	end
	self:StopProfiling("OvaleEnemies_RemoveEnemy")
end

function OvaleEnemies:RemoveTaggedEnemy(cleuEvent, guid, timestamp)
	self:StartProfiling("OvaleEnemies_RemoveTaggedEnemy")
	if guid then
		local name = self_enemyName[guid]
		local tagged = self_taggedEnemyLastSeen[guid]
		if tagged then
			self_taggedEnemyLastSeen[guid] = nil
			if self.taggedEnemies > 0 then
				self.taggedEnemies = self.taggedEnemies - 1
			end
			self:DebugTimestamp("%s: %d/%d enemy removed: %s (%s), last tagged at %f", cleuEvent, self.taggedEnemies, self.activeEnemies, guid, name, tagged)
			Ovale.refreshNeeded[self_playerGUID] = true
		end
	end
	self:StopProfiling("OvaleEnemies_RemoveEnemy")
end

function OvaleEnemies:DebugEnemies()
	for guid, seen in pairs(self_enemyLastSeen) do
		local name = self_enemyName[guid]
		local tagged = self_taggedEnemyLastSeen[guid]
		if tagged then
			self:Print("Tagged enemy %s (%s) last seen at %f", guid, name, tagged)
		else
			self:Print("Enemy %s (%s) last seen at %f", guid, name, seen)
		end
	end
	self:Print("Total enemies: %d", self.activeEnemies)
	self:Print("Total tagged enemies: %d", self.taggedEnemies)
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleEnemies.statePrototype = {}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleEnemies.statePrototype
--</private-static-properties>

--<state-properties>
-- Total number of active enemies.
statePrototype.activeEnemies = nil
-- Total number of tagged enemies.
statePrototype.taggedEnemies = nil
-- Requested number of enemies.
statePrototype.enemies = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleEnemies:InitializeState(state)
	state.enemies = nil
end

-- Reset the state to the current conditions.
function OvaleEnemies:ResetState(state)
	self:StartProfiling("OvaleEnemies_ResetState")
	state.activeEnemies = self.activeEnemies
	state.taggedEnemies = self.taggedEnemies
	self:StopProfiling("OvaleEnemies_ResetState")
end

-- Release state resources prior to removing from the simulator.
function OvaleEnemies:CleanState(state)
	state.activeEnemies = nil
	state.taggedEnemies = nil
	state.enemies = nil
end
--</public-static-methods>
