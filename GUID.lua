--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

--[[
	This addon manages mappings between GUIDs, unit IDs, and names.

	A unit ID can only have one GUID.
	A unit ID can only have one name.
	A unit ID may not exist.

	A GUID can have multiple unit IDs.
	A GUID can only have one name.

	A name can have multiple unit IDs.
	A name can have mulitple GUIDs.
--]]

local OVALE, Ovale = ...
local OvaleGUID = Ovale:NewModule("OvaleGUID", "AceEvent-3.0")
Ovale.OvaleGUID = OvaleGUID

--<private-static-properties>
local OvaleDebug = Ovale.OvaleDebug

local floor = math.floor
local ipairs = ipairs
local setmetatable = setmetatable
local tinsert = table.insert
local tremove = table.remove
local type = type
local unpack = unpack
local API_GetTime = GetTime
local API_UnitGUID = UnitGUID
local API_UnitName = UnitName

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvaleGUID)

-- PET_UNIT[unitId] = pet's unit ID
local PET_UNIT = {}
do
	PET_UNIT["player"] = "pet"
	for i = 1, 5 do
		PET_UNIT["arena" .. i] = "arenapet" .. i
	end
	for i = 1, 4 do
		PET_UNIT["party" .. i] = "partypet" .. i
	end
	for i = 1, 40 do
		PET_UNIT["raid" .. i] = "raidpet" .. i
	end
	-- Default unit pet name is the unit ID with "pet" appended to it.
	setmetatable(PET_UNIT, { __index = function(t, unitId) return unitId .. "pet" end })
end

--[[
	Unit IDs for which UNIT_AURA events are known to fire.

	UNIT_AURA_UNITS is an ordered list of unit ID priority.
	UNIT_AURA_UNIT is a table that holds the reverse mapping of UNIT_AURA_UNITS.
--]]
local UNIT_AURA_UNITS = {}
do
	tinsert(UNIT_AURA_UNITS, "player")
	tinsert(UNIT_AURA_UNITS, "pet")
	tinsert(UNIT_AURA_UNITS, "vehicle")
	tinsert(UNIT_AURA_UNITS, "target")
	tinsert(UNIT_AURA_UNITS, "focus")
	for i = 1, 40 do
		local unitId = "raid" .. i
		tinsert(UNIT_AURA_UNITS, unitId)
		tinsert(UNIT_AURA_UNITS, PET_UNIT[unitId])
	end
	for i = 1, 4 do
		local unitId = "party" .. i
		tinsert(UNIT_AURA_UNITS, unitId)
		tinsert(UNIT_AURA_UNITS, PET_UNIT[unitId])
	end
	for i = 1, 4 do
		tinsert(UNIT_AURA_UNITS, "boss" .. i)
	end
	for i = 1, 5 do
		local unitId = "arena" .. i
		tinsert(UNIT_AURA_UNITS, unitId)
		tinsert(UNIT_AURA_UNITS, PET_UNIT[unitId])
	end
	tinsert(UNIT_AURA_UNITS, "npc")
end

local UNIT_AURA_UNIT = {}
do
	for i, unitId in ipairs(UNIT_AURA_UNITS) do
		UNIT_AURA_UNIT[unitId] = i
	end
	-- Default unit priority is after all listed units.
	setmetatable(UNIT_AURA_UNIT, { __index = function(t, unitId) return #UNIT_AURA_UNITS + 1 end })
end
--</private-static-properties>

--<public-static-properties>
-- Mappings between GUIDs, unit IDS, and names.
OvaleGUID.unitGUID = {}
OvaleGUID.guidUnit = {}
OvaleGUID.unitName = {}
OvaleGUID.nameUnit = {}
OvaleGUID.guidName = {}
OvaleGUID.nameGUID = {}

-- Table of player pet GUIDs.
OvaleGUID.petGUID = {}

-- Export UNIT_AURA_UNIT table of units that receive UNIT_AURA events.
OvaleGUID.UNIT_AURA_UNIT = UNIT_AURA_UNIT
--</public-static-properties>

--<private-static-methods>
local BinaryInsert
local BinaryRemove
local BinarySearch
do
	-- Binary search algorithm pseudocode from: http://rosettacode.org/wiki/Binary_search

	local function compareDefault(a, b)
		return a < b
	end

	-- Insert the value at the rightmost insertion point of a sorted array using binary search.
	BinaryInsert = function(t, value, unique, compare)
		if type(unique) == "function" then
			unique, compare = nil, unique
		end
		compare = compare or compareDefault
		local low, high = 1, #t
		while low <= high do
			-- invariants: value >= t[i] for all i < low
			--             value < t[i] for all i > high
			local mid = floor((low + high) / 2)
			if compare(value, t[mid]) then
				high = mid - 1
			elseif not unique or compare(t[mid], value) then
				low = mid + 1
			else
				return mid
			end
		end
		tinsert(t, low, value)
		return low
	end

	-- Remove the value in a sorted array using binary search.
	BinaryRemove = function(t, value, compare)
		local index = BinarySearch(t, value, compare)
		if index then
			tremove(t, index)
		end
		return index
	end

	-- Return the index of the value in a sorted array using binary search.
	BinarySearch = function(t, value, compare)
		compare = compare or compareDefault
		local low, high = 1, #t
		while low <= high do
			-- invariants: value > t[i] for all i < low
			--             value < t[i] for all i > high
			local mid = floor((low + high) / 2)
			if compare(value, t[mid]) then
				high = mid - 1
			elseif compare(t[mid], value) then
				low = mid + 1
			else
				return mid
			end
		end
		return nil
	end
end

-- Comparator for unit IDs based on their unit priorities from UNIT_AURA_UNIT.
local function CompareUnit(a, b)
	return UNIT_AURA_UNIT[a] < UNIT_AURA_UNIT[b]
end
--</private-static-methods>

--<public-static-methods>
function OvaleGUID:OnEnable()
	self:RegisterEvent("ARENA_OPPONENT_UPDATE")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAllUnits")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("UNIT_TARGET")
end

function OvaleGUID:OnDisable()
	self:UnregisterEvent("ARENA_OPPONENT_UPDATE")
	self:UnregisterEvent("GROUP_ROSTER_UPDATE")
	self:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("UNIT_NAME_UPDATE")
	self:UnregisterEvent("UNIT_PET")
	self:UnregisterEvent("UNIT_TARGET")
end

function OvaleGUID:ARENA_OPPONENT_UPDATE(event, unitId, eventType)
	if eventType ~= "cleared" or self.unitGUID[unitId] then
		self:Debug(event, unitId, eventType)
		self:UpdateUnitWithTarget(unitId)
	end
end

function OvaleGUID:GROUP_ROSTER_UPDATE(event)
	self:Debug(event)
	self:UpdateAllUnits()
	self:SendMessage("Ovale_GroupChanged")
end

function OvaleGUID:INSTANCE_ENCOUNTER_ENGAGE_UNIT(event)
	self:Debug(event)
	for i= 1, 4 do
		self:UpdateUnitWithTarget("boss" .. i)
	end
end

function OvaleGUID:PLAYER_FOCUS_CHANGED(event)
	self:Debug(event)
	self:UpdateUnitWithTarget("focus")
end

function OvaleGUID:PLAYER_TARGET_CHANGED(event, cause)
	self:Debug(event, cause)
	self:UpdateUnit("target")
end

function OvaleGUID:UNIT_NAME_UPDATE(event, unitId)
	self:Debug(event, unitId)
	self:UpdateUnit(unitId)
end

function OvaleGUID:UNIT_PET(event, unitId)
	self:Debug(event, unitId)
	local pet = PET_UNIT[unitId]
	self:UpdateUnitWithTarget(pet)
	if unitId == "player" then
		local guid = self:UnitGUID("pet")
		if guid then
			-- Add pet's GUID to the table of player's pet GUIDs.
			self.petGUID[guid] = API_GetTime()
		end
		self:SendMessage("Ovale_PetChanged", guid)
	end
	self:SendMessage("Ovale_GroupChanged")
end

function OvaleGUID:UNIT_TARGET(event, unitId)
	-- Changes to the player's target are tracked with PLAYER_TARGET_CHANGED.
	if unitId ~= "player" then
		self:Debug(event, unitId)
		local target = unitId .. "target"
		self:UpdateUnit(target)
	end
end

function OvaleGUID:UpdateAllUnits()
	for _, unitId in ipairs(UNIT_AURA_UNITS) do
		self:UpdateUnitWithTarget(unitId)
	end
end

function OvaleGUID:UpdateUnit(unitId)
	local guid = API_UnitGUID(unitId)
	local name = API_UnitName(unitId)
	local previousGUID = self.unitGUID[unitId]
	local previousName = self.unitName[unitId]
	--[[
		Remove the previous GUID and name mappings for this unit ID if they've changed.
	--]]
	if not guid or guid ~= previousGUID then
		-- unit <--> GUID
		self.unitGUID[unitId] = nil
		if previousGUID then
			if self.guidUnit[previousGUID] then
				BinaryRemove(self.guidUnit[previousGUID], unitId, CompareUnit)
			end
			Ovale.refreshNeeded[previousGUID] = true
		end
	end
	if not name or name ~= previousName then
		-- unit <--> name
		self.unitName[unitId] = nil
		if previousName and self.nameUnit[previousName] then
			BinaryRemove(self.nameUnit[previousName], unitId, CompareUnit)
		end
	end
	if guid and guid == previousGUID and name and name ~= previousName then
		-- GUID <--> name
		self.guidName[guid] = nil
		if previousName and self.nameGUID[previousName] then
			BinaryRemove(self.nameGUID[previousName], guid, CompareUnit)
		end
	end
	--[[
		Create new mappings from this unit ID to the current GUID and name.
	--]]
	if guid and guid ~= previousGUID then
		-- unit <--> GUID
		self.unitGUID[unitId] = guid
		do
			local list = self.guidUnit[guid] or {}
			BinaryInsert(list, unitId, true, CompareUnit)
			self.guidUnit[guid] = list
		end
		self:Debug("'%s' is '%s'.", unitId, guid)
		Ovale.refreshNeeded[guid] = true
	end
	if name and name ~= previousName then
		-- unit <--> name
		self.unitName[unitId] = name
		do
			local list = self.nameUnit[name] or {}
			BinaryInsert(list, unitId, true, CompareUnit)
			self.nameUnit[name] = list
		end
		self:Debug("'%s' is '%s'.", unitId, name)
	end
	if guid and name then
		-- GUID <--> name
		local previousNameFromGUID = self.guidName[guid]
		self.guidName[guid] = name
		if name ~= previousNameFromGUID then
			local list = self.nameGUID[name] or {}
			BinaryInsert(list, guid, true)
			self.nameGUID[name] = list
			if guid == previousGUID then
				self:Debug("'%s' changed names to '%s'.", guid, name)
			else
				self:Debug("'%s' is '%s'.", guid, name)
			end
		end
	end
	if guid and guid ~= previousGUID then
		self:SendMessage("Ovale_UnitChanged", unitId, guid)
	end
end

function OvaleGUID:UpdateUnitWithTarget(unitId)
	self:UpdateUnit(unitId)
	self:UpdateUnit(unitId .. "target")
end

-- Return whether the GUID is a player's pet.
function OvaleGUID:IsPlayerPet(guid)
	local atTime = self.petGUID[guid]
	return (not not atTime), atTime
end

-- Return the GUID of the given unit.
function OvaleGUID:UnitGUID(unitId)
	if unitId then
		return self.unitGUID[unitId] or API_UnitGUID(unitId)
	end
	return nil
end

-- Return a list of unit IDs for the given GUID.
function OvaleGUID:GUIDUnit(guid)
	if guid and self.guidUnit[guid] then
		return unpack(self.guidUnit[guid])
	end
	return nil
end

-- Return the name of the given unit.
function OvaleGUID:UnitName(unitId)
	if unitId then
		return self.unitName[unitId] or API_UnitName(unitId)
	end
	return nil
end

-- Return a list of the unit IDs with the given name.
function OvaleGUID:NameUnit(name)
	if name and self.nameUnit[name] then
		return unpack(self.nameUnit[name])
	end
	return nil
end

-- Return the name of the given GUID.
function OvaleGUID:GUIDName(guid)
	if guid then
		return self.guidName[guid]
	end
	return nil
end

-- Return a list of the GUIDs with the given name.
function OvaleGUID:NameGUID(name)
	if name and self.nameGUID[name] then
		return unpack(self.nameGUID[name])
	end
	return nil
end
--</public-static-methods>
