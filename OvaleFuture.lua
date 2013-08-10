--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012, 2013 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- The travelling missiles or spells that have been cast but whose effects were not still not applied

local _, Ovale = ...
local OvaleFuture = Ovale:NewModule("OvaleFuture", "AceEvent-3.0")
Ovale.OvaleFuture = OvaleFuture

--<private-static-properties>
local OvaleAura = Ovale.OvaleAura
local OvaleComboPoints = Ovale.OvaleComboPoints
local OvaleData = Ovale.OvaleData
local OvaleGUID = Ovale.OvaleGUID
local OvalePaperDoll = Ovale.OvalePaperDoll
local OvalePool = Ovale.OvalePool

local ipairs = ipairs
local pairs = pairs
local select = select
local tinsert = table.insert
local tostring = tostring
local tremove = table.remove
local API_UnitCastingInfo = UnitCastingInfo
local API_UnitChannelInfo = UnitChannelInfo
local API_UnitGUID = UnitGUID
local API_UnitName = UnitName

local self_playerName = nil

-- The spells that the player is casting or has cast but are still in-flight toward their targets.
local self_activeSpellcast = {}
-- self_lastSpellcast[targetGUID][spellId] is the most recent spell that has landed successfully on the target.
local self_lastSpellcast = {}
local self_pool = OvalePool:NewPool("OvaleFuture_pool")

-- Used to track the most recent spellcast started with UNIT_SPELLCAST_SENT.
local self_lastLineID = nil
local self_lastSpell = nil
local self_lastTarget = nil

-- Time at which a player aura was last added.
local self_timeAuraAdded = nil

local OVALE_UNKNOWN_GUID = 0

-- These CLEU events are eventually received after a successful spellcast.
local OVALE_CLEU_SPELLCAST_RESULTS = {
	SPELL_AURA_APPLIED = true,
	SPELL_AURA_REFRESH = true,
	SPELL_CAST_SUCCESS = true,
	SPELL_CAST_FAILED = true,
	SPELL_DAMAGE = true,
	SPELL_MISSED = true,
}
--</private-static-properties>

--<public-static-properties>
--spell counter (see Counter function)
OvaleFuture.counter = {}
-- Debugging: spells to trace
OvaleFuture.traceSpellList = nil
--</public-static-properties>

--<private-static-methods>
local function TracePrintf(spellId, ...)
	local self = OvaleFuture
	if self.traceSpellList then
		local name = spellId
		if type(spellId) == "number" then
			name = OvaleData:GetSpellName(spellId)
		end
		if self.traceSpellList[spellId] or self.traceSpellList[name] then
			Ovale:FormatPrint(...)
		end
	end
end

local function ScoreSpell(spellId)
	local si = OvaleData.spellInfo[spellId]
	if Ovale.enCombat and not (si and si.toggle) and OvaleData.scoreSpell[spellId] then
		local scored = Ovale.frame:GetScore(spellId)
		Ovale:Logf("Scored %s", scored)
		if scored then
			Ovale.score = Ovale.score + scored
			Ovale.maxScore = Ovale.maxScore + 1
			Ovale:SendScoreToDamageMeter(self_playerName, OvaleGUID:GetGUID("player"), scored, 1)
		end
	end
end

-- Return the spell-specific damage multiplier using the information from SpellDamage{Buff,Debuff} declarations.
-- This doesn't include the base damage multiplier of the character.
local function GetDamageMultiplier(spellId)
	local damageMultiplier = 1
	if spellId then
		local si = OvaleData.spellInfo[spellId]
		if si and si.damageAura then
			local playerGUID = OvaleGUID:GetGUID("player")
			for filter, auraList in pairs(si.damageAura) do
				for auraSpellId, multiplier in pairs(auraList) do
					local count = select(3, OvaleAura:GetAuraByGUID(playerGUID, auraSpellId, filter, nil, "player"))
					if count and count > 0 then
						-- TODO: Try to account for a stacking aura.
						-- multiplier = 1 + (multiplier - 1) * count
						damageMultiplier = damageMultiplier * multiplier
					end
				end
			end
		end
	end
	return damageMultiplier
end

local function AddSpellToQueue(spellId, lineId, startTime, endTime, channeled, allowRemove)
	local self = OvaleFuture
	local spellcast = self_pool:Get()
	spellcast.spellId = spellId
	spellcast.lineId = lineId
	spellcast.start = startTime
	spellcast.stop = endTime
	spellcast.channeled = channeled
	spellcast.allowRemove = allowRemove

	-- Set the target from the data taken from UNIT_SPELLCAST_SENT if it's the same spellcast.
	if lineId == self_lastLineID and OvaleData:GetSpellName(spellId) == self_lastSpell then
		spellcast.target = self_lastTarget
	else
		spellcast.target = API_UnitGUID("target")
	end
	TracePrintf(spellId, "    AddSpellToQueue: %f %s (%d), lineId=%d, startTime=%f, endTime=%f, target=%s",
		Ovale.now, OvaleData:GetSpellName(spellId), spellId, lineId, startTime, endTime, spellcast.target)

	-- Snapshot the current stats for the spellcast.
	OvalePaperDoll:SnapshotStats(spellcast)
	spellcast.damageMultiplier = GetDamageMultiplier(spellId)

	local si = OvaleData.spellInfo[spellId]
	if si then
		spellcast.nocd = (si.buffnocd and OvaleAura:GetAura("player", si.buffnocd))

		-- Save the number of combo points used if this spell is a finisher.
		if si.combo == 0 then
			local comboPoints = OvaleComboPoints.combo
			if comboPoints > 0 then
				spellcast.comboPoints = comboPoints
			end
		end

		-- Track one of the auras, if any, that are added or refreshed by this spell.
		-- This helps to later identify whether the spellcast succeeded by noting when
		-- the aura is applied or refreshed.
		if si.aura then
			for target, auraTable in pairs(si.aura) do
				for filter, auraList in pairs(auraTable) do
					for auraSpellId, spellData in pairs(auraList) do
						if spellData and type(spellData) == "number" and spellData > 0 then
							spellcast.auraSpellId = auraSpellId
							if target == "player" then
								spellcast.removeOnSuccess = true
							end
							break
						end
					end
				end
			end
		end

		-- Increase or reset any counters used by the Counter() condition.
		if si.resetcounter then
			self.counter[si.resetcounter] = 0
		end
		if si.inccounter then
			local prev = self.counter[si.inccounter] or 0
			self.counter[si.inccounter] = prev + 1
		end
	else
		spellcast.removeOnSuccess = true
	end
	tinsert(self_activeSpellcast, spellcast)

	ScoreSpell(spellId)
	Ovale.refreshNeeded["player"] = true
end

local function RemoveSpellFromQueue(spellId, lineId)
	local self = OvaleFuture
	for index, spellcast in ipairs(self_activeSpellcast) do
		if spellcast.lineId == lineId then
			TracePrintf(spellId, "    RemoveSpellFromQueue: %f %s (%d)", Ovale.now, OvaleData:GetSpellName(spellId), spellId)
			tremove(self_activeSpellcast, index)
			self_pool:Release(spellcast)
			break
		end
	end
	Ovale.refreshNeeded["player"] = true
end

-- UpdateLastSpellInfo() is called at the end of the event handler for OVALE_CLEU_SPELLCAST_RESULTS[].
-- It saves the given spellcast as the most recent one on its target and ensures that the spellcast
-- snapshot values are correctly adjusted for buffs that are added or cleared simultaneously with the
-- spellcast.
local function UpdateLastSpellInfo(spellcast)
	local targetGUID = spellcast.target
	local spellId = spellcast.spellId
	if targetGUID and spellId then
		if not self_lastSpellcast[targetGUID] then
			self_lastSpellcast[targetGUID] = {}
		end
		local oldSpellcast = self_lastSpellcast[targetGUID][spellId]
		if oldSpellcast then
			self_pool:Release(oldSpellcast)
		end
		self_lastSpellcast[targetGUID][spellId] = spellcast

		--[[
			If any auras have been added between the start of the spellcast and this event,
			then take a more recent snapshot of the player stats for this spellcast.

			This is needed to see any auras that were applied at the same time as the
			spellcast, e.g., potions or other on-use abilities or items.
		]]--
		if self_timeAuraAdded then
			if self_timeAuraAdded >= spellcast.start and self_timeAuraAdded - spellcast.stop < 1 then
				OvalePaperDoll:SnapshotStats(spellcast)
				spellcast.damageMultiplier = GetDamageMultiplier(spellId)
				TracePrintf(spellId, "    Updated spell info for %s (%d) to snapshot from %f.",
					OvaleData:GetSpellName(spellId), spellId, spellcast.snapshotTime)
			end
		end

		-- Save this most recent spellcast.
		Ovale:UpdateLastSpellcast(spellcast)
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleFuture:OnEnable()
	self_playerName = API_UnitName("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterMessage("Ovale_AuraAdded")
	self:RegisterMessage("Ovale_InactiveUnit")
end

function OvaleFuture:OnDisable()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:UnregisterEvent("UNIT_SPELLCAST_SENT")
	self:UnregisterEvent("UNIT_SPELLCAST_START")
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:UnregisterMessage("Ovale_AuraAdded")
	self:UnregisterMessage("Ovale_InactiveUnit")
end

function OvaleFuture:PLAYER_ENTERING_WORLD(event)
	-- Empty out self_lastSpellcast.
	for guid in pairs(self_lastSpellcast) do
		self:Ovale_InactiveUnit(event, guid)
	end
end

function OvaleFuture:Ovale_AuraAdded(event, guid, spellId, caster)
	if guid == OvaleGUID:GetGUID("player") then
		self_timeAuraAdded = Ovale.now
	end
end

function OvaleFuture:Ovale_InactiveUnit(event, guid)
	-- Remove spellcasts for inactive units.
	local spellTable = self_lastSpellcast[guid]
	if spellTable then
		for spellId, spellcast in pairs(spellTable) do
			spellTable[spellId] = nil
			self_pool:Release(spellcast)
		end
		self_lastSpellcast[guid] = nil
	end
end

function OvaleFuture:UNIT_SPELLCAST_CHANNEL_START(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		local startTime, endTime = select(5, API_UnitChannelInfo("player"))
		TracePrintf(spellId, "%s: %f %d, lineId=%d, startTime=%f, endTime=%f",
			event, Ovale.now, spellId, lineId, startTime, endTime)
		AddSpellToQueue(spellId, lineId, startTime/1000, endTime/1000, true, false)
	end
end

function OvaleFuture:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		TracePrintf(spellId, "%s: %f %d, lineId=%d", event, Ovale.now, spellId, lineId)
		RemoveSpellFromQueue(spellId, lineId)
	end
end

--Called when a spell started its cast
function OvaleFuture:UNIT_SPELLCAST_START(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		local startTime, endTime = select(5, API_UnitCastingInfo("player"))
		TracePrintf(spellId, "%s: %f %d, lineId=%d, startTime=%f, endTime=%f",
			event, Ovale.now, spellId, lineId, startTime, endTime)
		AddSpellToQueue(spellId, lineId, startTime/1000, endTime/1000, false, false)
	end
end

--Called if the player interrupted early his cast
function OvaleFuture:UNIT_SPELLCAST_INTERRUPTED(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		TracePrintf(spellId, "%s: %f %d, lineId=%d", event, Ovale.now, spellId, lineId)
		RemoveSpellFromQueue(spellId, lineId)
	end
end

-- UNIT_SPELLCAST_SENT is triggered when the spellcast is sent to the server.
-- This is sent before all other UNIT_SPELLCAST_* events for the same spellcast.
function OvaleFuture:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target, lineId)
	if unit == "player" then
		self_lastLineID = lineId
		self_lastSpell = spell

		-- UNIT_TARGET may arrive out of order with UNIT_SPELLCAST* events, so we can't track
		-- the target in an event handler.
		if target then
			if target == API_UnitName("target") then
				self_lastTarget = API_UnitGUID("target")
			else
				self_lastTarget = OvaleGUID:GetGUIDForName(target)
			end
		else
			self_lastTarget = OVALE_UNKNOWN_GUID
		end
		TracePrintf(spell, "%s: %f %s on %s, lineId=%d", event, Ovale.now, spell, self_lastTarget, lineId)
	end
end

-- UNIT_SPELLCAST_SUCCEEDED is triggered when a spellcast successfully completes.
--[[
	For a cast-time spell:
		UNIT_SPELLCAST_SENT
		UNIT_SPELLCAST_START
		UNIT_SPELLCAST_SUCCEEDED
	For an instant-cast spell:
		UNIT_SPELLCAST_SENT
		UNIT_SPELLCAST_SUCCEEDED
]]--
function OvaleFuture:UNIT_SPELLCAST_SUCCEEDED(event, unit, name, rank, lineId, spellId)
	if unit == "player" then
		TracePrintf(spellId, "%s: %f %d, lineId=%d", event, Ovale.now, spellId, lineId)

		-- Search for a cast-time spell matching this spellcast that was added by UNIT_SPELLCAST_START.
		for _, spellcast in ipairs(self_activeSpellcast) do
			if spellcast.lineId == lineId then
				spellcast.allowRemove = true
				-- Take a more recent snapshot of the player stats for this cast-time spell.
				OvalePaperDoll:SnapshotStats(spellcast)
				spellcast.damageMultiplier = GetDamageMultiplier(spellId)
				return
			end
		end

		--[[
			This spell was an instant-cast spell, but only add it to the queue if it's not part
			of a channeled spell.  A channeled spell is actually two separate spells, an
			instant-cast portion and a channel portion, with different line IDs.  The instant-cast
			triggers UNIT_SPELLCAST_SENT and UNIT_SPELLCAST_SUCCEEDED, while the channel triggers
			UNIT_SPELLCAST_CHANNEL_START and UNIT_SPELLCAST_CHANNEL_STOP.
		]]--
		if not API_UnitChannelInfo("player") then
			AddSpellToQueue(spellId, lineId, Ovale.now, Ovale.now, false, true)
		end
	end
end

function OvaleFuture:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1, ...)

	--[[
	Sequence of events:
	- casting a spell that damages
	SPELL_CAST_START
	SPELL_DAMAGE
	- casting a spell that misses
	SPELL_CAST_START
	SPELL_MISSED
	- casting a spell then interrupting it
	SPELL_CAST_START
	SPELL_CAST_FAILED
	- casting an instant damaging spell
	SPELL_CAST_SUCCESS
	SPELL_DAMAGE
	- chanelling a damaging spell
	SPELL_CAST_SUCCESS
	SPELL_AURA_APPLIED
	SPELL_PERIODIC_DAMAGE
	SPELL_PERIODIC_DAMAGE
	SPELL_PERIODIC_DAMAGE
	(interruption does not generate an event)
	- refreshing a buff
	SPELL_AURA_REFRESH
	SPELL_CAST_SUCCESS
	- removing a buff
	SPELL_AURA_REMOVED
	- casting a buff
	SPELL_AURA_APPLIED
	SPELL_CAST_SUCCESS
	-casting a DOT that misses
	SPELL_CAST_SUCCESS
	SPELL_MISSED
	- casting a DOT that damages
	SPELL_CAST_SUCESS
	SPELL_AURA_APPLIED
	SPELL_PERIODIC_DAMAGE
	SPELL_PERIODIC_DAMAGE
	]]--

	-- Called when a missile reaches or misses its target
	if sourceGUID == OvaleGUID:GetGUID("player") then
		if OVALE_CLEU_SPELLCAST_RESULTS[event] then
			local spellId, spellName = select(12, ...)
			TracePrintf(spellId, "%s: %f %s (%d)", event, Ovale.now, spellName, spellId)
			for index, spellcast in ipairs(self_activeSpellcast) do
				if spellcast.allowRemove and (spellcast.spellId == spellId or spellcast.auraSpellId == spellId) then
					if not spellcast.channeled and (spellcast.removeOnSuccess or event ~= "SPELL_CAST_SUCCESS") then
						TracePrintf(spellId, "    Spell finished: %f %s (%d)", Ovale.now, spellName, spellId)
						tremove(self_activeSpellcast, index)
						UpdateLastSpellInfo(spellcast)
						Ovale.refreshNeeded["player"] = true
					end
					break
				end
			end
		end
	end
end

-- Apply spells that are being cast or are in flight.
function OvaleFuture:ApplyInFlightSpells(now, ApplySpell)
	local index = 0
	local spellcast, si
	while true do
		index = index + 1
		if index > #self_activeSpellcast then return end

		spellcast = self_activeSpellcast[index]
		si = OvaleData.spellInfo[spellcast.spellId]
		-- skip over spells that are toggles for other spells
		if not (si and si.toggle) then
			Ovale:Logf("now = %f, spellId = %d, endCast = %f", now, spellcast.spellId, spellcast.stop)
			if now - spellcast.stop < 5 then
				ApplySpell(spellcast.spellId, spellcast.start, spellcast.stop, spellcast.stop, spellcast.nocd, spellcast.target, spellcast)
			else
				tremove(self_activeSpellcast, index)
				self_pool:Release(spellcast)
				-- Decrement current index since item was removed and rest of items shifted up.
				index = index - 1
			end
		end
	end
end

function OvaleFuture:GetLastSpellInfo(guid, spellId, statName)
	if self_lastSpellcast[guid] and self_lastSpellcast[guid][spellId] then
		return self_lastSpellcast[guid][spellId][statName]
	end
end

function OvaleFuture:InFlight(spellId)
	for _, spellcast in ipairs(self_activeSpellcast) do
		if spellcast.spellId == spellId then
			return true
		end
	end
	return false
end

function OvaleFuture:Debug()
	if next(self_activeSpellcast) then
		Ovale:Print("Spells in flight:")
	else
		Ovale:Print("No spells in flight!")
	end
	for _, spellcast in ipairs(self_activeSpellcast) do
		Ovale:FormatPrint("    %s (%d), lineId=%s", OvaleData:GetSpellName(spellcast.spellId), spellcast.spellId, spellcast.lineId)
	end
end
--</public-static-methods>
