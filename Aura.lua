--[[--------------------------------------------------------------------
    Copyright (C) 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

--[[
	This addon tracks all auras for all units.
--]]

local OVALE, Ovale = ...
local OvaleAura = Ovale:NewModule("OvaleAura", "AceEvent-3.0")
Ovale.OvaleAura = OvaleAura

--<private-static-properties>
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug
local OvalePool = Ovale.OvalePool
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleData = nil
local OvaleFuture = nil
local OvaleGUID = nil
local OvalePaperDoll = nil
local OvaleSpellBook = nil
local OvaleState = nil

local bit_band = bit.band
local bit_bor = bit.bor
local floor = math.floor
local ipairs = ipairs
local next = next
local pairs = pairs
local strfind = string.find
local strlower = string.lower
local strsub = string.sub
local tconcat = table.concat
local tinsert = table.insert
local tonumber = tonumber
local tsort = table.sort
local type = type
local wipe = wipe
local API_GetTime = GetTime
local API_UnitAura = UnitAura
local INFINITY = math.huge
local SCHOOL_MASK_ARCANE = SCHOOL_MASK_ARCANE
local SCHOOL_MASK_FIRE = SCHOOL_MASK_FIRE
local SCHOOL_MASK_FROST = SCHOOL_MASK_FROST
local SCHOOL_MASK_HOLY = SCHOOL_MASK_HOLY
local SCHOOL_MASK_NATURE = SCHOOL_MASK_NATURE
local SCHOOL_MASK_SHADOW = SCHOOL_MASK_SHADOW

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvaleAura)
-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleAura)

-- Player's GUID.
local self_playerGUID = nil
-- Player's pet's GUID.
local self_petGUID = nil
-- Table pool.
local self_pool = OvalePool("OvaleAura_pool")

-- Some auras have a nil caster, so treat those as having a GUID of zero for indexing purposes.
local UNKNOWN_GUID = 0

do
	local output = {}
	local debugOptions = {
		playerAura = {
			name = L["Auras (player)"],
			type = "group",
			args = {
				buff = {
					name = L["Auras on the player"],
					type = "input",
					multiline = 25,
					width = "full",
					get = function(info)
						wipe(output)
						local helpful = OvaleState.state:DebugUnitAuras("player", "HELPFUL")
						if helpful then
							output[#output + 1] = "== BUFFS =="
							output[#output + 1] = helpful
						end
						local harmful = OvaleState.state:DebugUnitAuras("player", "HARMFUL")
						if harmful then
							output[#output + 1] = "== DEBUFFS =="
							output[#output + 1] = harmful
						end
						return tconcat(output, "\n")
					end,
				},
			},
		},
		targetAura = {
			name = L["Auras (target)"],
			type = "group",
			args = {
				targetbuff = {
					name = L["Auras on the target"],
					type = "execute",
					type = "input",
					multiline = 25,
					width = "full",
					get = function(info)
						wipe(output)
						local helpful = OvaleState.state:DebugUnitAuras("target", "HELPFUL")
						if helpful then
							output[#output + 1] = "== BUFFS =="
							output[#output + 1] = helpful
						end
						local harmful = OvaleState.state:DebugUnitAuras("target", "HARMFUL")
						if harmful then
							output[#output + 1] = "== DEBUFFS =="
							output[#output + 1] = harmful
						end
						return tconcat(output, "\n")
					end,
				},
			},
		},
	}
	-- Insert debug options into OvaleDebug.
	for k, v in pairs(debugOptions) do
		OvaleDebug.options.args[k] = v
	end
end

-- Aura debuff types.
local DEBUFF_TYPE = {
	Curse = true,
	Disease = true,
	Enrage = true,
	Magic = true,
	Poison = true,
}
local SPELLINFO_DEBUFF_TYPE = {}
do
	for debuffType in pairs(DEBUFF_TYPE) do
		local siDebuffType = strlower(debuffType)
		SPELLINFO_DEBUFF_TYPE[siDebuffType] = debuffType
	end
end

-- CLEU events triggered by auras being applied, removed, refreshed, or changed in stack size.
local CLEU_AURA_EVENTS = {
	SPELL_AURA_APPLIED = true,
	SPELL_AURA_REMOVED = true,
	SPELL_AURA_APPLIED_DOSE = true,
	SPELL_AURA_REMOVED_DOSE = true,
	SPELL_AURA_REFRESH = true,
	SPELL_AURA_BROKEN = true,
	SPELL_AURA_BROKEN_SPELL = true,
}

-- CLEU events triggered by a periodic aura.
local CLEU_TICK_EVENTS = {
	SPELL_PERIODIC_DAMAGE = true,
	SPELL_PERIODIC_HEAL = true,
	SPELL_PERIODIC_ENERGIZE = true,
	SPELL_PERIODIC_DRAIN = true,
	SPELL_PERIODIC_LEECH = true,
}

-- Spell school bitmask to identify magic effects.
local CLEU_SCHOOL_MASK_MAGIC = bit_bor(SCHOOL_MASK_ARCANE, SCHOOL_MASK_FIRE, SCHOOL_MASK_FROST, SCHOOL_MASK_HOLY, SCHOOL_MASK_NATURE, SCHOOL_MASK_SHADOW)
--</private-static-properties>

--<public-static-properties>
-- Auras on the target (past & present): aura[guid][auraId][casterGUID] = aura.
OvaleAura.aura = {}
-- Current age of auras per unit: serial[guid] = age.
OvaleAura.serial = {}
-- Begin aura bypass code
OvaleAura.bypassState = {}
-- End aura bypass code
-- Unused public property to suppress lint warnings.
--OvaleAura.defaultTarget = nil
--</public-static-properties>

--<private-static-methods>
local function PutAura(auraDB, guid, auraId, casterGUID, aura)
	if not auraDB[guid] then
		auraDB[guid] = self_pool:Get()
	end
	if not auraDB[guid][auraId] then
		auraDB[guid][auraId] = self_pool:Get()
	end
	-- Remove any pre-existing aura at that slot.
	if auraDB[guid][auraId][casterGUID] then
		self_pool:Release(auraDB[guid][auraId][casterGUID])
	end
	-- Save the aura into that slot.
	auraDB[guid][auraId][casterGUID] = aura
	-- Set aura properties as a result of where it's slotted.
	aura.guid = guid
	aura.spellId = auraId
	aura.source = casterGUID
end

local function GetAura(auraDB, guid, auraId, casterGUID)
	if auraDB[guid] and auraDB[guid][auraId] and auraDB[guid][auraId][casterGUID] then
		-- TODO: Use a SpellInfo instead of hard numbers here so it could be declared in the script in case any other abilities do this?
		-- Wrecking Ball Buff
		if auraId == 215570 then
			local spellcast = OvaleFuture:LastInFlightSpell()
			-- Whirlwind
			if spellcast and spellcast.spellId and spellcast.spellId == 190411 and spellcast.start then
				local aura = auraDB[guid][auraId][casterGUID]
				if aura.start and aura.start < spellcast.start then
					-- If the aura began before the start of the Whirlwind, then the aura has ended
					-- Shows as an active aura in game until the animation of Whirlwind ends.
					aura.ending = spellcast.start
				end
			end
		end
		return auraDB[guid][auraId][casterGUID]
	end
end

local function GetAuraAnyCaster(auraDB, guid, auraId)
	local auraFound
	if auraDB[guid] and auraDB[guid][auraId] then
		for casterGUID, aura in pairs(auraDB[guid][auraId]) do
			-- Find the aura with the latest expiration time.
			if not auraFound or auraFound.ending < aura.ending then
				auraFound = aura
			end
		end
	end
	return auraFound
end

local function GetDebuffType(auraDB, guid, debuffType, filter, casterGUID)
	local auraFound
	if auraDB[guid] then
		for auraId, whoseTable in pairs(auraDB[guid]) do
			local aura = whoseTable[casterGUID]
			if aura and aura.debuffType == debuffType and aura.filter == filter then
				-- Find the aura with the latest expiration time.
				if not auraFound or auraFound.ending < aura.ending then
					auraFound = aura
				end
			end
		end
	end
	return auraFound
end

local function GetDebuffTypeAnyCaster(auraDB, guid, debuffType, filter)
	local auraFound
	if auraDB[guid] then
		for auraId, whoseTable in pairs(auraDB[guid]) do
			for casterGUID, aura in pairs(whoseTable) do
				if aura and aura.debuffType == debuffType and aura.filter == filter then
					-- Find the aura with the latest expiration time.
					if not auraFound or auraFound.ending < aura.ending then
						auraFound = aura
					end
				end
			end
		end
	end
	return auraFound
end

local function GetAuraOnGUID(auraDB, guid, auraId, filter, mine)
	local auraFound
	if DEBUFF_TYPE[auraId] then
		if mine then
			-- Check for aura applied by player, then player's pet if it exists.
			auraFound = GetDebuffType(auraDB, guid, auraId, filter, self_playerGUID)
			if not auraFound then
				for petGUID in pairs(self_petGUID) do
					local aura = GetDebuffType(auraDB, guid, auraId, filter, petGUID)
					-- Find the aura with the latest expiration time.
					if aura and (not auraFound or auraFound.ending < aura.ending) then
						auraFound = aura
					end
				end
			end
		else
			auraFound = GetDebuffTypeAnyCaster(auraDB, guid, auraId, filter)
		end
	else
		if mine then
			-- Check for aura applied by player, then player's pet if it exists.
			auraFound = GetAura(auraDB, guid, auraId, self_playerGUID)
			if not auraFound then
				for petGUID in pairs(self_petGUID) do
					local aura = GetAura(auraDB, guid, auraId, petGUID)
					-- Find the aura with the latest expiration time.
					if aura and (not auraFound or auraFound.ending < aura.ending) then
						auraFound = aura
					end
				end
			end
		else
			auraFound = GetAuraAnyCaster(auraDB, guid, auraId)
		end
	end
	return auraFound
end

local function RemoveAurasOnGUID(auraDB, guid)
	if auraDB[guid] then
		local auraTable = auraDB[guid]
		for auraId, whoseTable in pairs(auraTable) do
			for casterGUID, aura in pairs(whoseTable) do
				self_pool:Release(aura)
				whoseTable[casterGUID] = nil
			end
			self_pool:Release(whoseTable)
			auraTable[auraId] = nil
		end
		self_pool:Release(auraTable)
		auraDB[guid] = nil
	end
end

local function IsWithinAuraLag(time1, time2, factor)
	factor = factor or 1
	local auraLag = Ovale.db.profile.apparence.auraLag
	local tolerance = factor * auraLag / 1000
	return (time1 - time2 < tolerance) and (time2 - time1 < tolerance)
end
--</private-static-methods>

--<public-static-methods>
function OvaleAura:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
	OvaleFuture = Ovale.OvaleFuture
	OvaleGUID = Ovale.OvaleGUID
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleState = Ovale.OvaleState
end

function OvaleAura:OnEnable()
	self_playerGUID = Ovale.playerGUID
	self_petGUID = OvaleGUID.petGUID
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("UNIT_AURA")
	self:RegisterMessage("Ovale_GroupChanged", "ScanAllUnitAuras")
	self:RegisterMessage("Ovale_UnitChanged")
	OvaleData:RegisterRequirement("buff", "RequireBuffHandler", self)
	OvaleData:RegisterRequirement("buff_any", "RequireBuffHandler", self)
	OvaleData:RegisterRequirement("debuff", "RequireBuffHandler", self)
	OvaleData:RegisterRequirement("debuff_any", "RequireBuffHandler", self)
	OvaleData:RegisterRequirement("pet_buff", "RequireBuffHandler", self)
	OvaleData:RegisterRequirement("pet_debuff", "RequireBuffHandler", self)
	OvaleData:RegisterRequirement("stealth", "RequireStealthHandler", self)
	OvaleData:RegisterRequirement("stealthed", "RequireStealthHandler", self)
	OvaleData:RegisterRequirement("target_buff", "RequireBuffHandler", self)
	OvaleData:RegisterRequirement("target_buff_any", "RequireBuffHandler", self)
	OvaleData:RegisterRequirement("target_debuff", "RequireBuffHandler", self)
	OvaleData:RegisterRequirement("target_debuff_any", "RequireBuffHandler", self)
	OvaleState:RegisterState(self, self.statePrototype)
end

function OvaleAura:OnDisable()
	OvaleState:UnregisterState(self)
	OvaleData:UnregisterRequirement("buff")
	OvaleData:UnregisterRequirement("buff_any")
	OvaleData:UnregisterRequirement("debuff")
	OvaleData:UnregisterRequirement("debuff_any")
	OvaleData:UnregisterRequirement("pet_buff")
	OvaleData:UnregisterRequirement("pet_debuff")
	OvaleData:UnregisterRequirement("stealth")
	OvaleData:UnregisterRequirement("stealthed")
	OvaleData:UnregisterRequirement("target_buff")
	OvaleData:UnregisterRequirement("target_buff_any")
	OvaleData:UnregisterRequirement("target_debuff")
	OvaleData:UnregisterRequirement("target_debuff_any")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_UNGHOST")
	self:UnregisterEvent("UNIT_AURA")
	self:UnregisterMessage("Ovale_GroupChanged")
	self:UnregisterMessage("Ovale_UnitChanged")
	for guid in pairs(self.aura) do
		RemoveAurasOnGUID(self.aura, guid)
	end
	self_pool:Drain()
end

function OvaleAura:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25 = ...

	local mine = (sourceGUID == self_playerGUID or OvaleGUID:IsPlayerPet(sourceGUID))
	-- Begin aura bypass code.
	if mine and cleuEvent == "SPELL_MISSED" then
		local spellId, spellName, spellSchool = arg12, arg13, arg14
		local si = OvaleData.spellInfo[spellId]
		local bypassState = OvaleAura.bypassState
		-- Bypass the state for auras applied to player. 
		if si and si.aura and si.aura.player then
			for filter, auraTable in pairs(si.aura.player) do 
				for auraId in pairs(auraTable) do
					if not bypassState[auraId] then
						bypassState[auraId] = {}
					end
					bypassState[auraId][self_playerGUID] = true
				end
			end
		end
		-- Bypass the state for auras applied to target.
		if si and si.aura and si.aura.target then
			for filter, auraTable in pairs(si.aura.target) do 
				for auraId in pairs(auraTable) do
					if not bypassState[auraId] then
						bypassState[auraId] = {}
					end
					bypassState[auraId][destGUID] = true
				end
			end
		end
		-- Bypass the state for auras applied to pet.
		if si and si.aura and si.aura.pet then
			for filter, auraTable in pairs(si.aura.pet) do 
				for auraId, index in pairs(auraTable) do
					for petGUID in pairs(self_petGUID) do
						if not bypassState[petGUID] then
							bypassState[auraId] = {}
						end
						bypassState[auraId][petGUID] = true
					end
				end
			end
		end
	end
	-- End aura bypass code
	if CLEU_AURA_EVENTS[cleuEvent] then
		local unitId = OvaleGUID:GUIDUnit(destGUID)
		if unitId then
			-- Only update auras on the unit if it is not a unit type that receives UNIT_AURA events.
			if not OvaleGUID.UNIT_AURA_UNIT[unitId] then
				self:DebugTimestamp("%s: %s (%s)", cleuEvent, destGUID, unitId)
				self:ScanAuras(unitId, destGUID)
			end
		elseif mine then
			-- There is no unit ID, but the action was caused by the player, so update this aura on destGUID.
			local spellId, spellName, spellSchool = arg12, arg13, arg14
			self:DebugTimestamp("%s: %s (%d) on %s", cleuEvent, spellName, spellId, destGUID)
			local now = API_GetTime()
			if cleuEvent == "SPELL_AURA_REMOVED" or cleuEvent == "SPELL_AURA_BROKEN" or cleuEvent == "SPELL_AURA_BROKEN_SPELL" then
				self:LostAuraOnGUID(destGUID, now, spellId, sourceGUID)
			else
				local auraType, amount = arg15, arg16
				local filter = (auraType == "BUFF") and "HELPFUL" or "HARMFUL"
				local si = OvaleData.spellInfo[spellId]
				-- Find an existing aura applied by the player on destGUID.
				local aura = GetAuraOnGUID(self.aura, destGUID, spellId, filter, true)
				local duration
				if aura then
					-- Re-use the duration of the previous aura on the target.
					duration = aura.duration
				elseif si and si.duration then
					-- Look up the duration from the SpellInfo.
					duration = OvaleData:GetSpellInfoProperty(spellId, now, "duration", destGUID)
					if si.addduration then
						duration = duration + si.addduration
					end
				else
					-- No aura duration information known and we can't scan the aura on that GUID,
					-- so assume the aura lasts 15 seconds.
					-- TODO: There is probably something smarter to be done here.
					duration = 15
				end
				local expirationTime = now + duration
				local count
				if cleuEvent == "SPELL_AURA_APPLIED" then
					count = 1
				elseif cleuEvent == "SPELL_AURA_APPLIED_DOSE" or cleuEvent == "SPELL_AURA_REMOVED_DOSE" then
					count = amount
				elseif cleuEvent == "SPELL_AURA_REFRESH" then
					count = aura and aura.stacks or 1
				end
				self:GainedAuraOnGUID(destGUID, now, spellId, sourceGUID, filter, true, nil, count, nil, duration, expirationTime, nil, spellName)
			end
		end
	elseif mine and CLEU_TICK_EVENTS[cleuEvent] then
		-- Update the latest tick time of the periodic aura cast by the player.
		local spellId, spellName, spellSchool = arg12, arg13, arg14
		local multistrike
		if strsub(cleuEvent, -7) == "_DAMAGE" then
			multistrike = arg25
		elseif strsub(cleuEvent, -5) == "_HEAL" then
			multistrike = arg19
		end
		if not multistrike then
			self:DebugTimestamp("%s: %s", cleuEvent, destGUID)
			local aura = GetAura(self.aura, destGUID, spellId, self_playerGUID)
			local now = API_GetTime()
			if self:IsActiveAura(aura, now) then
				local name = aura.name or "Unknown spell"
				local baseTick, lastTickTime = aura.baseTick, aura.lastTickTime
				local tick = baseTick
				if lastTickTime then
					-- Update the tick length based on the timestamps of the current tick and the previous tick.
					tick = timestamp - lastTickTime
				elseif not baseTick then
					-- This isn't a known periodic aura, but it's ticking so treat this as the first tick.
					self:Debug("    First tick seen of unknown periodic aura %s (%d) on %s.", name, spellId, destGUID)
					local si = OvaleData.spellInfo[spellId]
					baseTick = (si and si.tick) and si.tick or 3
					tick = OvaleData:GetTickLength(spellId)
				end
				aura.baseTick = baseTick
				aura.lastTickTime = timestamp
				aura.tick = tick
				self:Debug("    Updating %s (%s) on %s, tick=%s, lastTickTime=%s", name, spellId, destGUID, tick, lastTickTime)
				Ovale.refreshNeeded[destGUID] = true
			end
		end
	end
end

function OvaleAura:PLAYER_ENTERING_WORLD(event)
	-- Initialize aura databases by scanning all unit auras.
	self:ScanAllUnitAuras()
end

function OvaleAura:PLAYER_REGEN_ENABLED(event)
	self:RemoveAurasOnInactiveUnits()
	self_pool:Drain()
end

function OvaleAura:UNIT_AURA(event, unitId)
	self:Debug("%s: %s", event, unitId)
	self:ScanAuras(unitId)
end

function OvaleAura:Ovale_UnitChanged(event, unitId, guid)
	if (unitId == "pet" or unitId == "target") and guid then
		self:Debug(event, unitId, guid)
		self:ScanAuras(unitId, guid)
	end
end

function OvaleAura:ScanAllUnitAuras()
	-- Update auras on all visible units.
	for unitId in pairs(OvaleGUID.UNIT_AURA_UNIT) do
		self:ScanAuras(unitId)
	end
end

function OvaleAura:RemoveAurasOnInactiveUnits()
	-- Remove all auras from GUIDs that can no longer be referenced by a unit ID,
	-- i.e., not in the group or not targeted by anyone in the group or focus.
	for guid in pairs(self.aura) do
		local unitId = OvaleGUID:GUIDUnit(guid)
		if not unitId then
			self:Debug("Removing auras from GUID %s", guid)
			RemoveAurasOnGUID(self.aura, guid)
			self.serial[guid] = nil
		end
	end
end

function OvaleAura:IsActiveAura(aura, atTime)
	local boolean = false
	if aura then
		atTime = atTime or API_GetTime()
		if aura.serial == self.serial[aura.guid] and aura.stacks > 0 and aura.gain <= atTime and atTime <= aura.ending then
			boolean = true
		elseif aura.consumed and IsWithinAuraLag(aura.ending, atTime) then
			boolean = true
		end
	end
	return boolean
end

function OvaleAura:GainedAuraOnGUID(guid, atTime, auraId, casterGUID, filter, visible, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3)
	self:StartProfiling("OvaleAura_GainedAuraOnGUID")
	-- Whose aura is it?
	casterGUID = casterGUID or UNKNOWN_GUID

	-- UnitAura() can return zero count for auras that are present.
	count = (count and count > 0) and count or 1
	-- "Zero" or nil duration and expiration actually mean the aura never expires.
	duration = (duration and duration > 0) and duration or INFINITY
	expirationTime = (expirationTime and expirationTime > 0) and expirationTime or INFINITY

	local aura = GetAura(self.aura, guid, auraId, casterGUID)
	local auraIsActive
	if aura then
		auraIsActive = (aura.stacks > 0 and aura.gain <= atTime and atTime <= aura.ending)
	else
		aura = self_pool:Get()
		PutAura(self.aura, guid, auraId, casterGUID, aura)
		auraIsActive = false
	end

	-- Only overwrite an active aura's information if the aura has changed.
	-- An aura's "fingerprint" is its: caster, duration, expiration time, stack count, value
	local auraIsUnchanged = (
		aura.source == casterGUID
			and aura.duration == duration
			and aura.ending == expirationTime
			and aura.stacks == count
			and aura.value1 == value1
			and aura.value2 == value2
			and aura.value3 == value3
	)

	-- Update age of aura, regardless of whether it's changed.
	aura.serial = self.serial[guid]

	if not auraIsActive or not auraIsUnchanged then
		self:Debug("    Adding %s %s (%s) to %s at %f, aura.serial=%d", filter, name, auraId, guid, atTime, aura.serial)
		aura.name = name
		aura.duration = duration
		aura.ending = expirationTime
		if duration < INFINITY and expirationTime < INFINITY then
			aura.start = expirationTime - duration
		else
			aura.start = atTime
		end
		aura.gain = atTime
		aura.lastUpdated = atTime
		local direction = aura.direction or 1
		if aura.stacks then
			if aura.stacks < count then
				direction = 1	-- increasing stack count
			elseif aura.stacks > count then
				direction = -1	-- decreasing stack count
			end
		end
		aura.direction = direction
		aura.stacks = count
		aura.consumed = nil
		aura.filter = filter
		aura.visible = visible
		aura.icon = icon
		aura.debuffType = debuffType
		aura.enrage = (debuffType == "Enrage") or nil
		aura.stealable = isStealable
		aura.value1, aura.value2, aura.value3 = value1, value2, value3

		-- Snapshot stats for auras applied by the player or player's pet.
		local mine = (casterGUID == self_playerGUID or OvaleGUID:IsPlayerPet(casterGUID))
		if mine then
			-- Determine whether to snapshot player stats for the aura or to keep the existing stats.
			local spellcast = OvaleFuture:LastInFlightSpell()
			if spellcast and spellcast.stop and not IsWithinAuraLag(spellcast.stop, atTime) then
				spellcast = OvaleFuture.lastSpellcast
				if spellcast and spellcast.stop and not IsWithinAuraLag(spellcast.stop, atTime) then
					spellcast = nil
				end
			end
			if spellcast and spellcast.target == guid then
				local spellId = spellcast.spellId
				local spellName = OvaleSpellBook:GetSpellName(spellId) or "Unknown spell"
				-- Parse the spell data for this aura to see if this is a "refresh_keep_snapshot" aura.
				local keepSnapshot = false
				local si = OvaleData.spellInfo[spellId]
				if si and si.aura then
					local auraTable = OvaleGUID:IsPlayerPet(guid) and si.aura.pet or si.aura.target
					if auraTable and auraTable[filter] then
						local spellData = auraTable[filter][auraId]
						if spellData == "refresh_keep_snapshot" then
							keepSnapshot = true
						elseif type(spellData) == "table" and spellData[1] == "refresh_keep_snapshot" then
							-- Comma-separated value.
							keepSnapshot = OvaleData:CheckRequirements(spellId, atTime, spellData, 2, guid)
						end
					end
				end
				if keepSnapshot then
					self:Debug("    Keeping snapshot stats for %s %s (%d) on %s refreshed by %s (%d) from %f, now=%f, aura.serial=%d",
						filter, name, auraId, guid, spellName, spellId, aura.snapshotTime, atTime, aura.serial)
				else
					self:Debug("    Snapshot stats for %s %s (%d) on %s applied by %s (%d) from %f, now=%f, aura.serial=%d",
						filter, name, auraId, guid, spellName, spellId, spellcast.snapshotTime, atTime, aura.serial)
					-- TODO: damageMultiplier isn't correct if spellId spreads the DoT.
					OvaleFuture:CopySpellcastInfo(spellcast, aura)
				end
			end

			local si = OvaleData.spellInfo[auraId]
			if si then
				-- Set the tick information for known DoTs.
				if si.tick then
					self:Debug("    %s (%s) is a periodic aura.", name, auraId)
					-- Only set the initial tick information for new auras.
					if not auraIsActive then
						aura.baseTick = si.tick
						if spellcast and spellcast.target == guid then
							aura.tick = OvaleData:GetTickLength(auraId, spellcast)
						else
							aura.tick = OvaleData:GetTickLength(auraId)
						end
					end
				end
				-- Set the cooldown expiration time for player buffs applied by items with a cooldown.
				if si.buff_cd and guid == self_playerGUID then
					self:Debug("    %s (%s) is applied by an item with a cooldown of %ds.", name, auraId, si.buff_cd)
					if not auraIsActive then
						-- cooldownEnding is the earliest time at which we expect to gain this buff again.
						aura.cooldownEnding = aura.gain + si.buff_cd
					end
				end
			end
		end
		if not auraIsActive then
			self:SendMessage("Ovale_AuraAdded", atTime, guid, auraId, aura.source)
		elseif not auraIsUnchanged then
			self:SendMessage("Ovale_AuraChanged", atTime, guid, auraId, aura.source)
		end
		Ovale.refreshNeeded[guid] = true
	end
	self:StopProfiling("OvaleAura_GainedAuraOnGUID")
end

function OvaleAura:LostAuraOnGUID(guid, atTime, auraId, casterGUID)
	self:StartProfiling("OvaleAura_LostAuraOnGUID")
	local aura = GetAura(self.aura, guid, auraId, casterGUID)
	if aura then
		local filter = aura.filter
		self:Debug("    Expiring %s %s (%d) from %s at %f.", filter, aura.name, auraId, guid, atTime)
		if aura.ending > atTime then
			aura.ending = atTime
		end

		-- Snapshot stats for auras applied by the player or player's pet.
		local mine = (casterGUID == self_playerGUID or OvaleGUID:IsPlayerPet(casterGUID))
		if mine then
			-- Clear old tick information for player-applied periodic auras.
			aura.baseTick = nil
			aura.lastTickTime = nil
			aura.tick = nil

			-- Check if the aura was consumed by the last spellcast.
			-- The aura must have ended early, i.e., start + duration > ending.
			if aura.start + aura.duration > aura.ending then
				local spellcast
				if guid == self_playerGUID then
					-- Player aura, so it was possibly consumed by an in-flight spell.
					spellcast = OvaleFuture:LastSpellSent()
				else
					-- Non-player aura, so it was possibly consumed by a spell that landed on its target.
					spellcast = OvaleFuture.lastSpellcast
				end
				if spellcast then 
					-- If last spell is successful, check against stop time, i.e., end of cast for cast time spells or succeeded time for instant-cast spells
					if (spellcast.success and spellcast.stop and IsWithinAuraLag(spellcast.stop, aura.ending)) or
					-- If last spell sent was not successful, check against the time it was queued, i.e., when the ability was sent
					-- Required as sometimes UNIT_AURA event fires before UNIT_SPELLCAST_SUCCEEDED event
						 (spellcast.queued and IsWithinAuraLag(spellcast.queued, aura.ending)) then
						aura.consumed = true
						local spellName = OvaleSpellBook:GetSpellName(spellcast.spellId) or "Unknown spell"
						self:Debug("    Consuming %s %s (%d) on %s with queued %s (%d) at %f.", filter, aura.name, auraId, guid, spellName, spellcast.spellId, spellcast.queued)
					end
				end
			end
		end
		aura.lastUpdated = atTime

		self:SendMessage("Ovale_AuraRemoved", atTime, guid, auraId, aura.source)
		Ovale.refreshNeeded[guid] = true
	end
	self:StopProfiling("OvaleAura_LostAuraOnGUID")
end

-- Scan auras on the given GUID and update the aura database.
function OvaleAura:ScanAuras(unitId, guid)
	self:StartProfiling("OvaleAura_ScanAuras")
	guid = guid or OvaleGUID:UnitGUID(unitId)
	if guid then
		self:DebugTimestamp("Scanning auras on %s (%s)", guid, unitId)

		-- Advance the age of the unit's auras.
		local serial = self.serial[guid] or 0
		serial = serial + 1
		self:Debug("    Advancing age of auras for %s (%s) to %d.", guid, unitId, serial)
		self.serial[guid] = serial

		-- Add all auras on the unit into the database.
		local i = 1
		local filter = "HELPFUL"
		local now = API_GetTime()
		while true do
			local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId,
				canApplyAura, isBossDebuff, isCastByPlayer, value1, value2, value3 = API_UnitAura(unitId, i, filter)
			if not name then
				if filter == "HELPFUL" then
					filter = "HARMFUL"
					i = 1
				else
					break
				end
			else
				local casterGUID = OvaleGUID:UnitGUID(unitCaster)
				if debuffType == "" then
					-- Empty string for the debuff type means this is an Enrage effect.
					debuffType = "Enrage"
				end
				self:GainedAuraOnGUID(guid, now, spellId, casterGUID, filter, true, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3)
				i = i + 1
			end
		end

		-- Find recently expired auras on the unit.
		if self.aura[guid] then
			local auraTable = self.aura[guid]
			for auraId, whoseTable in pairs(auraTable) do
				for casterGUID, aura in pairs(whoseTable) do
					if aura.serial == serial - 1 then
						if aura.visible then
							-- Remove the aura if it was visible.
							self:LostAuraOnGUID(guid, now, auraId, casterGUID)
						else
							-- Age any hidden auras that are managed by outside modules.
							aura.serial = serial
							self:Debug("    Preserving aura %s (%d), start=%s, ending=%s, aura.serial=%d", aura.name, aura.spellId, aura.start, aura.ending, aura.serial)
						end
					end
				end
			end
		end
		self:Debug("End scanning of auras on %s (%s).", guid, unitId)
	end
	self:StopProfiling("OvaleAura_ScanAuras")
end

function OvaleAura:GetAuraByGUID(guid, auraId, filter, mine)
	-- If this GUID has no auras in the database, then do an aura scan.
	if not self.serial[guid] then
		local unitId = OvaleGUID:GUIDUnit(guid)
		self:ScanAuras(unitId, guid)
	end

	local auraFound
	if OvaleData.buffSpellList[auraId] then
		for id in pairs(OvaleData.buffSpellList[auraId]) do
			local aura = GetAuraOnGUID(self.aura, guid, id, filter, mine)
			if aura and (not auraFound or auraFound.ending < aura.ending) then
				auraFound = aura
			end
		end
	else
		auraFound = GetAuraOnGUID(self.aura, guid, auraId, filter, mine)
	end
	return auraFound
end

function OvaleAura:GetAura(unitId, auraId, filter, mine)
	local guid = OvaleGUID:UnitGUID(unitId)
	return self:GetAuraByGUID(guid, auraId, filter, mine)
end

-- Run-time check for an aura on the player or the target.
-- NOTE: Mirrored in statePrototype below.
function OvaleAura:RequireBuffHandler(spellId, atTime, requirement, tokens, index, targetGUID)
	local verified = false
	-- If index isn't given, then tokens holds the actual token value.
	local buffName = tokens
	local stacks = 1
	if index then
		buffName = tokens[index]
		index = index + 1
		-- Peek at the next token to see if it is an optional minimum stack count.
		local count = tonumber(tokens[index])
		if count then
			stacks = count
			index = index + 1
		end
	end
	if buffName then
		local isBang = false
		if strsub(buffName, 1, 1) == "!" then
			isBang = true
			buffName = strsub(buffName, 2)
		end
		local buffName = tonumber(buffName) or buffName
		local guid, unitId, filter, mine
		if strsub(requirement, 1, 7) == "target_" then
			if targetGUID then
				guid = targetGUID
				unitId = OvaleGUID:GUIDUnit(guid)
			else
				unitId = self.defaultTarget or "target"
			end
			filter = (strsub(requirement, 8, 11) == "buff") and "HELPFUL" or "HARMFUL"
			mine = not (strsub(requirement, -4) == "_any")
		elseif strsub(requirement, 1, 4) == "pet_" then
			unitId = "pet"
			filter = (strsub(requirement, 5, 11) == "buff") and "HELPFUL" or "HARMFUL"
			mine = false
		else
			unitId = "player"
			filter = (strsub(requirement, 1, 4) == "buff") and "HELPFUL" or "HARMFUL"
			mine = not (strsub(requirement, -4) == "_any")
		end
		guid = guid or OvaleGUID:UnitGUID(unitId)
		local aura = self:GetAuraByGUID(guid, buffName, filter, mine)
		local isActiveAura = self:IsActiveAura(aura, atTime) and aura.stacks >= stacks
		if not isBang and isActiveAura or isBang and not isActiveAura then
			verified = true
		end
		local result = verified and "passed" or "FAILED"
		if isBang then
			self:Log("    Require aura %s with at least %d stack(s) NOT on %s at time=%f: %s", buffName, stacks, unitId, atTime, result)
		else
			self:Log("    Require aura %s with at least %d stack(s) on %s at time=%f: %s", buffName, stacks, unitId, atTime, result)
		end
	else
		Ovale:OneTimeMessage("Warning: requirement '%s' is missing a buff argument.", requirement)
	end
	return verified, requirement, index
end

-- Run-time check for the player being stealthed.
-- NOTE: Mirrored in statePrototype below.
function OvaleAura:RequireStealthHandler(spellId, atTime, requirement, tokens, index, targetGUID)
	local verified = false
	-- If index isn't given, then tokens holds the actual token value.
	local stealthed = tokens
	if index then
		stealthed = tokens[index]
		index = index + 1
	end
	if stealthed then
		stealthed = tonumber(stealthed)
		local aura = self:GetAura("player", "stealthed_buff", "HELPFUL", true)
		local isActiveAura = self:IsActiveAura(aura, atTime)
		if stealthed == 1 and isActiveAura or stealthed ~= 1 and not isActiveAura then
			verified = true
		end
		local result = verified and "passed" or "FAILED"
		if stealthed == 1 then
			self:Log("    Require stealth at time=%f: %s", atTime, result)
		else
			self:Log("    Require NOT stealth at time=%f: %s", atTime, result)
		end
	else
		Ovale:OneTimeMessage("Warning: requirement '%s' is missing an argument.", requirement)
	end
	return verified, requirement, index
end
--</public-static-methods>

--[[----------------------------------------------------------------------------
	State machine for simulator.
--]]----------------------------------------------------------------------------

--<public-static-properties>
OvaleAura.statePrototype = {
	aura = nil,
	serial = nil,
}
--</public-static-properties>

--<private-static-properties>
local statePrototype = OvaleAura.statePrototype
--</private-static-properties>

--<state-properties>
-- Aura database: aura[guid][auraId][casterId] = aura
statePrototype.aura = nil
-- Age of active auras in the simulator.
statePrototype.serial = nil
--</state-properties>

--<public-static-methods>
-- Initialize the state.
function OvaleAura:InitializeState(state)
	state.aura = {}
	state.serial = 0
end

-- Reset the state to the current conditions.
function OvaleAura:ResetState(state)
	self:StartProfiling("OvaleAura_ResetState")
	-- Advance age of auras in state machine.
	state.serial = state.serial + 1

	-- Garbage-collect auras in the state machine that are more recently updated in the true aura database.
	if next(state.aura) then
		state:Log("Resetting aura state:")
	end
	for guid, auraTable in pairs(state.aura) do
		for auraId, whoseTable in pairs(auraTable) do
			for casterGUID, aura in pairs(whoseTable) do
				self_pool:Release(aura)
				whoseTable[casterGUID] = nil
				state:Log("    Aura %d on %s removed.", auraId, guid)
			end
			if not next(whoseTable) then
				self_pool:Release(whoseTable)
				auraTable[auraId] = nil
			end
		end
		if not next(auraTable) then
			self_pool:Release(auraTable)
			state.aura[guid] = nil
		end
	end
	self:StopProfiling("OvaleAura_ResetState")
end

-- Release state resources prior to removing from the simulator.
function OvaleAura:CleanState(state)
	for guid in pairs(state.aura) do
		RemoveAurasOnGUID(state.aura, guid)
	end
end

-- Apply the effects of the spell at the start of the spellcast.
function OvaleAura:ApplySpellStartCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvaleAura_ApplySpellStartCast")
	-- Channeled spells apply their auras when the player starts channeling.
	if isChanneled then
		local si = OvaleData.spellInfo[spellId]
		if si and si.aura then
			-- Apply the auras on the player.
			if si.aura.player then
				state:ApplySpellAuras(spellId, self_playerGUID, startCast, si.aura.player, spellcast)
			end
			-- Apply the auras on the target.
			if si.aura.target then
				state:ApplySpellAuras(spellId, targetGUID, startCast, si.aura.target, spellcast)
			end
			-- Apply the auras on the pet.
			if si.aura.pet then
				local petGUID = OvaleGUID:UnitGUID("pet")
				if petGUID then
					state:ApplySpellAuras(spellId, petGUID, startCast, si.aura.pet, spellcast)
				end
			end
		end
	end
	self:StopProfiling("OvaleAura_ApplySpellStartCast")
end

-- Apply the effects of the spell when the spellcast completes.
function OvaleAura:ApplySpellAfterCast(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvaleAura_ApplySpellAfterCast")
	-- Cast-time spells apply their auras on the player and any pets when the player completes the cast.
	if not isChanneled then
		local si = OvaleData.spellInfo[spellId]
		if si and si.aura then
			-- Apply the auras on the player.
			if si.aura.player then
				state:ApplySpellAuras(spellId, self_playerGUID, endCast, si.aura.player, spellcast)
			end
			-- Apply the auras on the pet.
			if si.aura.pet then
				local petGUID = OvaleGUID:UnitGUID("pet")
				if petGUID then
					state:ApplySpellAuras(spellId, petGUID, startCast, si.aura.pet, spellcast)
				end
			end
		end
	end
	self:StopProfiling("OvaleAura_ApplySpellAfterCast")
end

-- Apply the effects of the spell when it lands on the target.
function OvaleAura:ApplySpellOnHit(state, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
	self:StartProfiling("OvaleAura_ApplySpellAfterHit")
	-- Cast-time spells apply their auras on the target when they hit the target.
	if not isChanneled then
		local si = OvaleData.spellInfo[spellId]
		if si and si.aura and si.aura.target then
			-- Get the travel time of the spell to the target, defaulting to no travel time.
			local travelTime = si.travel_time or 0
			if travelTime > 0 then
				-- XXX Estimate the travel time to the target.
				local estimatedTravelTime = 1
				if travelTime < estimatedTravelTime then
					travelTime = estimatedTravelTime
				end
			end
			local atTime = endCast + travelTime
			state:ApplySpellAuras(spellId, targetGUID, atTime, si.aura.target, spellcast)
		end
	end
	self:StopProfiling("OvaleAura_ApplySpellAfterHit")
end
--</public-static-methods>

--<state-methods>
local function GetStateAura(state, guid, auraId, casterGUID)
	local aura = GetAura(state.aura, guid, auraId, casterGUID)
	if not aura or aura.serial < state.serial then
		aura = GetAura(OvaleAura.aura, guid, auraId, casterGUID)
	end
	return aura
end

local function GetStateAuraAnyCaster(state, guid, auraId)
	--[[
		Loop over all of the auras in the true aura database and the state machine aura
		database and find the one with the latest expiration time.
	--]]
	local auraFound
	if OvaleAura.aura[guid] and OvaleAura.aura[guid][auraId] then
		for casterGUID in pairs(OvaleAura.aura[guid][auraId]) do
			local aura = GetStateAura(state, guid, auraId, casterGUID)
			-- Skip over auras found in the state machine for now.
			if aura and not aura.state and OvaleAura:IsActiveAura(aura, state.currentTime) then
				if not auraFound or auraFound.ending < aura.ending then
					auraFound = aura
				end
			end
		end
	end
	if state.aura[guid] and state.aura[guid][auraId] then
		for casterGUID, aura in pairs(state.aura[guid][auraId]) do
			if aura.stacks > 0 then
				if not auraFound or auraFound.ending < aura.ending then
					auraFound = aura
				end
			end
		end
	end
	return auraFound
end

local function GetStateDebuffType(state, guid, debuffType, filter, casterGUID)
	--[[
		Loop over all of the auras in the true aura database and the state machine aura
		database and find the one with the latest expiration time.
	--]]
	local auraFound
	if OvaleAura.aura[guid] then
		for auraId in pairs(OvaleAura.aura[guid]) do
			local aura = GetStateAura(state, guid, auraId, casterGUID)
			-- Skip over auras found in the state machine for now.
			if aura and not aura.state and OvaleAura:IsActiveAura(aura, state.currentTime) then
				if aura.debuffType == debuffType and aura.filter == filter then
					if not auraFound or auraFound.ending < aura.ending then
						auraFound = aura
					end
				end
			end
		end
	end
	if state.aura[guid] then
		for auraId, whoseTable in pairs(state.aura[guid]) do
			local aura = whoseTable[casterGUID]
			if aura and aura.stacks > 0 then
				if aura.debuffType == debuffType and aura.filter == filter then
					if not auraFound or auraFound.ending < aura.ending then
						auraFound = aura
					end
				end
			end
		end
	end
	return auraFound
end

local function GetStateDebuffTypeAnyCaster(state, guid, debuffType, filter)
	--[[
		Loop over all of the auras in the true aura database and the state machine aura
		database and find the one with the latest expiration time.
	--]]
	local auraFound
	if OvaleAura.aura[guid] then
		for auraId, whoseTable in pairs(OvaleAura.aura[guid]) do
			for casterGUID in pairs(whoseTable) do
				local aura = GetStateAura(state, guid, auraId, casterGUID)
				if aura and not aura.state and OvaleAura:IsActiveAura(aura, state.currentTime) then
					if aura.debuffType == debuffType and aura.filter == filter then
						if not auraFound or auraFound.ending < aura.ending then
							auraFound = aura
						end
					end
				end
			end
		end
	end
	if state.aura[guid] then
		for auraId, whoseTable in pairs(state.aura[guid]) do
			for casterGUID, aura in pairs(whoseTable) do
				if aura and not aura.state and aura.stacks > 0 then
					if aura.debuffType == debuffType and aura.filter == filter then
						if not auraFound or auraFound.ending < aura.ending then
							auraFound = aura
						end
					end
				end
			end
		end
	end
	return auraFound
end

local function GetStateAuraOnGUID(state, guid, auraId, filter, mine)
	local auraFound
	if DEBUFF_TYPE[auraId] then
		if mine then
			-- Check for aura applied by player, then player's pet if it exists.
			auraFound = GetStateDebuffType(state, guid, auraId, filter, self_playerGUID)
			if not auraFound then
				for petGUID in pairs(self_petGUID) do
					local aura = GetStateDebuffType(state, guid, auraId, filter, petGUID)
					-- Find the aura with the latest expiration time.
					if aura and (not auraFound or auraFound.ending < aura.ending) then
						auraFound = aura
					end
				end
			end
		else
			auraFound = GetStateDebuffTypeAnyCaster(state, guid, auraId, filter)
		end
	else
		if mine then
			-- Check for aura applied by player, then player's pet if it exists.
			local aura = GetStateAura(state, guid, auraId, self_playerGUID)
			if aura and aura.stacks > 0 then
				auraFound = aura
			else
				for petGUID in pairs(self_petGUID) do
					aura = GetStateAura(state, guid, auraId, petGUID)
					if aura and aura.stacks > 0 then
						auraFound = aura
						break
					end
				end
			end
		else
			auraFound = GetStateAuraAnyCaster(state, guid, auraId)
		end
	end
	return auraFound
end

-- Print the auras matching the filter on the unit in alphabetical order.
do
	local array = {}

	statePrototype.DebugUnitAuras = function(state, unitId, filter)
		wipe(array)
		local guid = OvaleGUID:UnitGUID(unitId)
		if OvaleAura.aura[guid] then
			for auraId, whoseTable in pairs(OvaleAura.aura[guid]) do
				for casterGUID in pairs(whoseTable) do
					local aura = GetStateAura(state, guid, auraId, casterGUID)
					if state:IsActiveAura(aura) and aura.filter == filter and not aura.state then
						local name = aura.name or "Unknown spell"
						tinsert(array, name .. ": " .. auraId)
					end
				end
			end
		end
		if state.aura[guid] then
			for auraId, whoseTable in pairs(state.aura[guid]) do
				for casterGUID, aura in pairs(whoseTable) do
					if state:IsActiveAura(aura) and aura.filter == filter then
						local name = aura.name or "Unknown spell"
						tinsert(array, name .. ": " .. auraId)
					end
				end
			end
		end
		if next(array) then
			tsort(array)
			return tconcat(array, "\n")
		end
	end
end

statePrototype.IsActiveAura = function(state, aura, atTime)
	atTime = atTime or state.currentTime
	local boolean = false
	if aura then
		if aura.state then
			if aura.serial == state.serial and aura.stacks > 0 and aura.gain <= atTime and atTime <= aura.ending then
				boolean = true
			elseif aura.consumed and IsWithinAuraLag(aura.ending, atTime) then
				boolean = true
			end
		else
			boolean = OvaleAura:IsActiveAura(aura, atTime)
		end
	end
	return boolean
end

statePrototype.CanApplySpellAura = function(spellData)
	if spellData["if_target_debuff"] then
		-- TODO other combinations
	elseif spellData["if_buff"] then
	end
end

statePrototype.ApplySpellAuras = function(state, spellId, guid, atTime, auraList, spellcast)
	OvaleAura:StartProfiling("OvaleAura_state_ApplySpellAuras")
	for filter, filterInfo in pairs(auraList) do
		for auraId, spellData in pairs(filterInfo) do
			local duration = OvaleData:GetBaseDuration(auraId, spellcast)

			local stacks = 1
			local count = nil
			local extend = 0
			local toggle = nil
			local refresh = false
			local keepSnapshot = false

			local verified, value, data = state:CheckSpellAuraData(auraId, spellData, atTime, guid)
			if value == "refresh" then
				refresh = true
			elseif value == "refresh_keep_snapshot" then
				refresh = true
				keepSnapshot = true
			elseif value == "toggle" then
				toggle = true
			elseif value == "count" then
				count = data
			elseif value == "extend" then
				extend = data
			elseif tonumber(value) then
				stacks = tonumber(value)
			else
				state:Log("Unknown stack %s", stacks)
			end
			if verified then
				local si = OvaleData.spellInfo[auraId]
				local auraFound = state:GetAuraByGUID(guid, auraId, filter, true)
				if state:IsActiveAura(auraFound, atTime) then
					local aura
					if auraFound.state then
						-- Re-use existing aura in the simulator.
						aura = auraFound
					else
						-- Add an aura in the simulator and copy the existing aura information over.
						aura = state:AddAuraToGUID(guid, auraId, auraFound.source, filter, nil, 0, INFINITY)
						for k, v in pairs(auraFound) do
							aura[k] = v
						end
						-- Reset the aura age relative to the state of the simulator.
						aura.serial = state.serial
						state:Log("Aura %d is copied into simulator.", auraId)
						-- Information that needs to be set below: stacks, start, ending, duration, gain.
					end
					-- If the aura is already present, then toggle the aura away.
					if toggle then
						state:Log("Aura %d is toggled off by spell %d.", auraId, spellId)
						stacks = 0
					end
					-- Adjust stacks to add/remove if count is present.
					if count and count > 0 then
						stacks = count - aura.stacks
					end
					-- Spell starts channeling before the aura expires, or spellcast ends before the aura expires.
					if refresh or extend > 0 or stacks > 0 then
						-- Adjust stack count.
						if refresh then
							state:Log("Aura %d is refreshed to %d stack(s).", auraId, aura.stacks)
						elseif extend > 0 then
							state:Log("Aura %d is extended by %f seconds, preserving %d stack(s).", auraId, extend, aura.stacks)
						else -- if stacks > 0 then
							local maxStacks = 1
							if si and (si.max_stacks or si.maxstacks) then
								maxStacks = si.max_stacks or si.maxstacks
							end
							aura.stacks = aura.stacks + stacks
							if aura.stacks > maxStacks then
								aura.stacks = maxStacks
							end
							state:Log("Aura %d gains %d stack(s) to %d because of spell %d.", auraId, stacks, aura.stacks, spellId)
						end
						-- Set start, ending, and duration for the aura.
						if extend > 0 then
							-- aura.start is preserved.
							aura.duration = aura.duration + extend
							aura.ending = aura.ending + extend
						else
							aura.start = atTime
							if aura.tick and aura.tick > 0 then
								-- This is a periodic aura, so add new duration to extend the aura up to 130% of the normal duration.
								local remainingDuration = aura.ending - atTime
								local extensionDuration = 0.3 * duration
								if remainingDuration < extensionDuration then
									-- Aura is extended by the normal duration.
									aura.duration = remainingDuration + duration
								else
									aura.duration = extensionDuration + duration
								end
							else
								aura.duration = duration
							end
							aura.ending = aura.start + aura.duration
						end
						aura.gain = atTime
						state:Log("Aura %d with duration %s now ending at %s", auraId, aura.duration, aura.ending)
						if keepSnapshot then
							state:Log("Aura %d keeping previous snapshot.", auraId)
						elseif spellcast then
							OvaleFuture:CopySpellcastInfo(spellcast, aura)
						end
					elseif stacks == 0 or stacks < 0 then
						if stacks == 0 then
							aura.stacks = 0
						else -- if stacks < 0 then
							aura.stacks = aura.stacks + stacks
							if aura.stacks < 0 then
								aura.stacks = 0
							end
							state:Log("Aura %d loses %d stack(s) to %d because of spell %d.", auraId, -1 * stacks, aura.stacks, spellId)
						end
						-- An existing aura is losing stacks, so inherit start, duration, ending and gain information.
						if aura.stacks == 0 then
							state:Log("Aura %d is completely removed.", auraId)
							-- The aura is completely removed, so set ending to the time that the aura is removed.
							aura.ending = atTime
							aura.consumed = true
						end
					end
				else
					-- Aura is not on the target.
					if toggle then
						state:Log("Aura %d is toggled on by spell %d.", auraId, spellId)
						stacks = 1
					end
					if not refresh and stacks > 0 then
						-- Spellcast causes a new aura.
						state:Log("New aura %d at %f on %s", auraId, atTime, guid)
						-- Add an aura in the simulator and copy the existing aura information over.
						local debuffType
						if si then
							for k, v in pairs(SPELLINFO_DEBUFF_TYPE) do
								if si[k] == 1 then
									debuffType = v
									break
								end
							end
						end
						local aura = state:AddAuraToGUID(guid, auraId, self_playerGUID, filter, debuffType, 0, INFINITY)
						-- Information that needs to be set below: stacks, start, ending, duration, gain.
						aura.stacks = stacks
						-- Set start and duration for aura.
						aura.start = atTime
						aura.duration = duration
						-- If "tick" is set explicitly in SpellInfo, then this is a known periodic aura.
						if si and si.tick then
							aura.baseTick = si.tick
							aura.tick = OvaleData:GetTickLength(auraId, spellcast)
						end
						aura.ending = aura.start + aura.duration
						aura.gain = aura.start
						if spellcast then
							OvaleFuture:CopySpellcastInfo(spellcast, aura)
						end
					end
				end
			else
				state:Log("Aura %d (%s) is not applied.", auraId, spellData)
			end
		end
	end
	OvaleAura:StopProfiling("OvaleAura_state_ApplySpellAuras")
end

statePrototype.GetAuraByGUID = function(state, guid, auraId, filter, mine)
	local auraFound
	if OvaleData.buffSpellList[auraId] then
		for id in pairs(OvaleData.buffSpellList[auraId]) do
			local aura = GetStateAuraOnGUID(state, guid, id, filter, mine)
			if aura and (not auraFound or auraFound.ending < aura.ending) then
				state:Log("Aura %s matching '%s' found on %s with (%s, %s)", id, auraId, guid, aura.start, aura.ending)
				auraFound = aura
			else
				--state:Log("Aura %s matching '%s' is missing on %s.", id, auraId, guid)
			end
		end
		if not auraFound then
			state:Log("Aura matching '%s' is missing on %s.", auraId, guid)
		end
	else
		auraFound = GetStateAuraOnGUID(state, guid, auraId, filter, mine)
		if auraFound then
			state:Log("Aura %s found on %s with (%s, %s)", auraId, guid, auraFound.start, auraFound.ending)
		else
			state:Log("Aura %s is missing on %s.", auraId, guid)
		end
	end
	return auraFound
end

statePrototype.GetAura = function(state, unitId, auraId, filter, mine)
	local guid = OvaleGUID:UnitGUID(unitId)
	-- Begin aura bypass code
	local stateAura = state:GetAuraByGUID(guid, auraId, filter, mine)
	local aura = OvaleAura:GetAuraByGUID(guid, auraId, filter, mine)
	local bypassState = OvaleAura.bypassState
	if not bypassState[auraId] then
		bypassState[auraId] = {}
	end
	-- Checks to see if we might need to bypass the state because a spell missed.
	if bypassState[auraId][guid] then
		if aura and aura.start and aura.ending and stateAura and stateAura.start and stateAura.ending and aura.start == stateAura.start and aura.ending == stateAura.ending then
			-- If the auras match, we don't need to bypass anymore
			bypassState[auraId][guid] = false
			return stateAura
		else
			-- Aura on this GUID was flagged for a bypass and the state aura is still incorrect
			return aura
		end
	end
	-- No need to bypass, return the state aura
	-- End aura bypass code
	return state:GetAuraByGUID(guid, auraId, filter, mine)
end

-- Add a new aura to the unit specified by GUID.
statePrototype.AddAuraToGUID = function(state, guid, auraId, casterGUID, filter, debuffType, start, ending, snapshot)
	local aura = self_pool:Get()
	aura.state = true
	aura.serial = state.serial
	aura.lastUpdated = state.currentTime
	aura.filter = filter
	aura.start = start or 0
	aura.ending = ending or INFINITY
	aura.duration = aura.ending - aura.start
	aura.gain = aura.start
	aura.stacks = 1
	aura.debuffType = debuffType
	aura.enrage = (debuffType == "Enrage") or nil
	state:UpdateSnapshot(aura, snapshot)
	PutAura(state.aura, guid, auraId, casterGUID, aura)
	return aura
end

-- Remove an aura from the unit specified by GUID.
statePrototype.RemoveAuraOnGUID = function(state, guid, auraId, filter, mine, atTime)
	local auraFound = state:GetAuraByGUID(guid, auraId, filter, mine)
	if state:IsActiveAura(auraFound, atTime) then
		local aura
		if auraFound.state then
			-- Re-use existing aura in the simulator.
			aura = auraFound
		else
			-- Add an aura in the simulator and copy the existing aura information over.
			aura = state:AddAuraToGUID(guid, auraId, auraFound.source, filter, nil, 0, INFINITY)
			for k, v in pairs(auraFound) do
				aura[k] = v
			end
			-- Reset the aura age relative to the state of the simulator.
			aura.serial = state.serial
		end

		-- Expire the aura.
		aura.stacks = 0
		aura.ending = atTime
		aura.lastUpdated = atTime
	end
end

statePrototype.GetAuraWithProperty = function(state, unitId, propertyName, filter, atTime)
	atTime = atTime or state.currentTime
	local count = 0
	local guid = OvaleGUID:UnitGUID(unitId)
	local start, ending = INFINITY, 0

	-- Loop through auras not kept in the simulator that match the criteria.
	if OvaleAura.aura[guid] then
		for auraId, whoseTable in pairs(OvaleAura.aura[guid]) do
			for casterGUID in pairs(whoseTable) do
				local aura = GetStateAura(state, guid, auraId, self_playerGUID)
				if state:IsActiveAura(aura, atTime) and not aura.state then
					if aura[propertyName] and aura.filter == filter then
						count = count + 1
						start = (aura.gain < start) and aura.gain or start
						ending = (aura.ending > ending) and aura.ending or ending
					end
				end
			end
		end
	end
	-- Loop through auras in the simulator that match the criteria.
	if state.aura[guid] then
		for auraId, whoseTable in pairs(state.aura[guid]) do
			for casterGUID, aura in pairs(whoseTable) do
				if state:IsActiveAura(aura, atTime) then
					if aura[propertyName] and aura.filter == filter then
						count = count + 1
						start = (aura.gain < start) and aura.gain or start
						ending = (aura.ending > ending) and aura.ending or ending
					end
				end
			end
		end
	end

	if count > 0 then
		state:Log("Aura with '%s' property found on %s (count=%s, minStart=%s, maxEnding=%s).", propertyName, unitId, count, start, ending)
	else
		state:Log("Aura with '%s' property is missing on %s.", propertyName, unitId)
		start, ending = nil
	end
	return start, ending
end

do
	-- The total count of the matched aura.
	local count
	-- The total number of stacks of the matched aura.
	local stacks
	-- The start and ending times of the first aura to expire that will change the total count.
	local startChangeCount, endingChangeCount
	-- The time interval over which count > 0.
	local startFirst, endingLast

	local function CountMatchingActiveAura(state, aura)
		state:Log("Counting aura %s found on %s with (%s, %s)", aura.spellId, aura.guid, aura.start, aura.ending)
		count = count + 1
		stacks = stacks + aura.stacks
		if aura.ending < endingChangeCount then
			startChangeCount, endingChangeCount = aura.gain, aura.ending
		end
		if aura.gain < startFirst then
			startFirst = aura.gain
		end
		if aura.ending > endingLast then
			endingLast = aura.ending
		end
	end

	--[[
		Return the total count and stacks of the given aura across all units, the start/end times of
		the first aura to expire that will change the total count, and the time interval over which
		the count is more than 0.  If excludeUnitId is given, then that unit is excluded from the count.
	--]]
	statePrototype.AuraCount = function(state, auraId, filter, mine, minStacks, atTime, excludeUnitId)
		OvaleAura:StartProfiling("OvaleAura_state_AuraCount")
		-- Initialize.
		minStacks = minStacks or 1
		count = 0
		stacks = 0
		startChangeCount, endingChangeCount = INFINITY, INFINITY
		startFirst, endingLast = INFINITY, 0
		local excludeGUID = excludeUnitId and OvaleGUID:UnitGUID(excludeUnitId) or nil

		-- Loop through auras not kept in the simulator that match the criteria.
		for guid, auraTable in pairs(OvaleAura.aura) do
			if guid ~= excludeGUID and auraTable[auraId] then
				if mine then
					-- Count aura applied by player.
					local aura = GetStateAura(state, guid, auraId, self_playerGUID)
					if state:IsActiveAura(aura, atTime) and aura.filter == filter and aura.stacks >= minStacks and not aura.state then
						CountMatchingActiveAura(state, aura)
					end
					-- Count aura applied by player's pet if it exists.
					for petGUID in pairs(self_petGUID) do
						aura = GetStateAura(state, guid, auraId, petGUID)
						if state:IsActiveAura(aura, atTime) and aura.filter == filter and aura.stacks >= minStacks and not aura.state then
							CountMatchingActiveAura(state, aura)
						end
					end
				else
					for casterGUID in pairs(auraTable[auraId]) do
						local aura = GetStateAura(state, guid, auraId, casterGUID)
						if state:IsActiveAura(aura, atTime) and aura.filter == filter and aura.stacks >= minStacks and not aura.state then
							CountMatchingActiveAura(state, aura)
						end
					end
				end
			end
		end
		-- Loop through auras in the simulator that match the criteria.
		for guid, auraTable in pairs(state.aura) do
			if guid ~= excludeGUID and auraTable[auraId] then
				if mine then
					-- Count aura applied by player.
					local aura = auraTable[auraId][self_playerGUID]
					if aura then
						if state:IsActiveAura(aura, atTime) and aura.filter == filter and aura.stacks >= minStacks then
							CountMatchingActiveAura(state, aura)
						end
					end
					-- Count aura applied by player's pet if it exists.
					for petGUID in pairs(self_petGUID) do
						aura = auraTable[auraId][petGUID]
						if state:IsActiveAura(aura, atTime) and aura.filter == filter and aura.stacks >= minStacks and not aura.state then
							CountMatchingActiveAura(state, aura)
						end
					end
				else
					for casterGUID, aura in pairs(auraTable[auraId]) do
						if state:IsActiveAura(aura, atTime) and aura.filter == filter and aura.stacks >= minStacks then
							CountMatchingActiveAura(state, aura)
						end
					end
				end
			end
		end

		state:Log("AuraCount(%d) is %s, %s, %s, %s, %s, %s", auraId, count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast)
		OvaleAura:StopProfiling("OvaleAura_state_AuraCount")
		return count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast
	end
end

-- Mirrored methods.
statePrototype.RequireBuffHandler = OvaleAura.RequireBuffHandler
statePrototype.RequireStealthHandler = OvaleAura.RequireStealthHandler
--</state-methods>
