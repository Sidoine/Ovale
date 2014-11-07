--[[--------------------------------------------------------------------
    Copyright (C) 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

--[[
	This addon manages mappings between GUID <--> unit ID <--> unit name.

	A GUID can have multiple unit IDs.
	A unit ID can only have one GUID.
	A unit ID may not exist.

	All primary unit IDs receive events.
	No <unit>target IDs receive events.
	No "mouseover" unit IDs receive events.
--]]

local OVALE, Ovale = ...
local OvaleGUID = Ovale:NewModule("OvaleGUID", "AceEvent-3.0")
Ovale.OvaleGUID = OvaleGUID

--<private-static-properties>
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug

local ipairs = ipairs
local next = next
local pairs = pairs
local tinsert = table.insert
local API_GetNumGroupMembers = GetNumGroupMembers
local API_UnitGUID = UnitGUID
local API_UnitName = UnitName

local OVALE_GUID_DEBUG = "guid"
do
	OvaleDebug:RegisterDebugOption(OVALE_GUID_DEBUG, L["GUIDs"], L["Debug GUID"])
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
	tinsert(UNIT_AURA_UNITS, "npc")
	tinsert(UNIT_AURA_UNITS, "target")
	tinsert(UNIT_AURA_UNITS, "focus")
	for i = 1, 5 do
		tinsert(UNIT_AURA_UNITS, "arena" .. i)
		tinsert(UNIT_AURA_UNITS, "arenapet" .. i)
	end
	for i = 1, 40 do
		tinsert(UNIT_AURA_UNITS, "raid" .. i)
		tinsert(UNIT_AURA_UNITS, "raidpet" .. i)
	end
	for i = 1, 4 do
		tinsert(UNIT_AURA_UNITS, "party" .. i)
		tinsert(UNIT_AURA_UNITS, "partypet" .. i)
	end
	for i = 1, 4 do
		tinsert(UNIT_AURA_UNITS, "boss" .. i)
	end
end

local UNIT_AURA_UNIT = {}
do
	for i, unitId in ipairs(UNIT_AURA_UNITS) do
		UNIT_AURA_UNIT[unitId] = i
	end
end

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
end
--</private-static-properties>

--<public-static-properties>
--[[
	Unit ID --> GUID mapping.
	unit ID can only have one GUID.
	self.unitIdToGUID[unitId] = GUID
--]]
OvaleGUID.unitIdToGUID = {}

--[[
	GUID --> unit ID mapping.
	A GUID can have multiple unit IDs.
	self.GUIDtoUnitId[guid] = { unitId = true if it exists and points to guid; nil otherwise }
--]]
OvaleGUID.GUIDtoUnitId = {}

--[[
--]]
OvaleGUID.nameToGUID = {}

-- Export UNIT_AURA_UNIT table of units that receive UNIT_AURA events.
OvaleGUID.UNIT_AURA_UNIT = UNIT_AURA_UNIT
--</public-static-properties>

--<public-static-methods>
function OvaleGUID:OnEnable()
	self:RegisterEvent("ARENA_OPPONENT_UPDATE")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAllUnits")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("PLAYER_LOGIN", "UpdateAllUnits")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
end

function OvaleGUID:OnDisable()
	self:UnregisterEvent("ARENA_OPPONENT_UPDATE")
	self:UnregisterEvent("GROUP_ROSTER_UPDATE")
	self:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
	self:UnregisterEvent("PLAYER_LOGIN")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("UNIT_PET")
	self:UnregisterEvent("UNIT_TARGET")
	self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
end

function OvaleGUID:ARENA_OPPONENT_UPDATE(event, unitId, eventType)
	for i = 1, 5 do
		local unit = "arena" .. i
		self:UpdateUnitWithTarget(unit)
		local pet = PET_UNIT[unit] or (unit .. "pet")
		self:UpdateUnitWithTarget(pet)
	end
end

function OvaleGUID:GROUP_ROSTER_UPDATE(event)
	self:UpdateAllUnits()
	self:SendMessage("Ovale_GroupChanged")
end

function OvaleGUID:INSTANCE_ENCOUNTER_ENGAGE_UNIT(event)
	for i= 1, 4 do
		self:UpdateUnitWithTarget("boss" .. i)
	end
end

function OvaleGUID:PLAYER_FOCUS_CHANGED(event)
	self:UpdateUnitWithTarget("focus")
end

function OvaleGUID:PLAYER_TARGET_CHANGED(event, cause)
	self:UNIT_TARGET(event, "player")
end

function OvaleGUID:UNIT_PET(event, unitId)
	local pet = PET_UNIT[unitId] or (unitId .. "pet")
	self:UpdateUnitWithTarget(pet)
	self:SendMessage("Ovale_GroupChanged")
end

function OvaleGUID:UNIT_TARGET(event, unitId)
	local target = (unitId == "player") and "target" or (unitId .. "target")
	self:UpdateUnit(target)
end

function OvaleGUID:UPDATE_MOUSEOVER_UNIT(event)
	self:UpdateUnitWithTarget("mouseover")
end

function OvaleGUID:UpdateAllUnits()
	for _, unitId in pairs(UNIT_AURA_UNITS) do
		self:UpdateUnitWithTarget(unitId)
	end
end

function OvaleGUID:UpdateUnitWithTarget(unitId)
	self:UpdateUnit(unitId)
	self:UpdateUnit(unitId .. "target")
end

function OvaleGUID:UpdateUnit(unitId)
	local guid = API_UnitGUID(unitId)
	if guid then
		local previousGUID = self.unitIdToGUID[unitId]
		if previousGUID ~= guid then
			-- Remove previous mappings for this unit ID.
			if previousGUID and self.GUIDtoUnitId[previousGUID] then
				self.GUIDtoUnitId[previousGUID][unitId] = nil
				if not next(self.GUIDtoUnitId[previousGUID]) then
					self.GUIDtoUnitId[previousGUID] = nil
				end
			end
			-- Create new mappings this unit ID to the GUID.
			self.unitIdToGUID[unitId] = guid
			self.GUIDtoUnitId[guid] = self.GUIDtoUnitId[guid] or {}
			self.GUIDtoUnitId[guid][unitId] = true

			Ovale:DebugPrintf(OVALE_GUID_DEBUG, "GUID %s is %s", guid, unitId)

			if unitId == "target" or self.unitIdToGUID.target ~= guid then
				local name = API_UnitName(unitId)
				self.nameToGUID[name] = self.nameToGUID[name] or guid
			end
		end
	else
		-- This unit ID doesn't point to a valid GUID.
		self.unitIdToGUID[unitId] = nil
		if self.GUIDtoUnitId[guid] then
			self.GUIDtoUnitId[guid][unitId] = nil
			if not next(self.GUIDtoUnitId[guid]) then
				self.GUIDtoUnitId[guid] = nil
			end
		end
	end
end

function OvaleGUID:GetGUID(unitId)
	if unitId then
		-- If the unit ID doesn't receive events, then refresh it now.
		if not UNIT_AURA_UNIT[unitId] then
			self:UpdateUnit(unitId)
		end
		return self.unitIdToGUID[unitId]
	end
	return nil
end

function OvaleGUID:GetUnitId(guid)
	if self.GUIDtoUnitId[guid] then
		-- Find the unit ID with the best (lowest) priority.
		local bestUnitId, bestPriority
		for unitId in pairs(self.GUIDtoUnitId[guid]) do
			local priority = UNIT_AURA_UNIT[unitId]
			if priority then
				if not bestPriority or priority < bestPriority then
					bestUnitId, bestPriority = unitId, priority
				end
			else
				-- This isn't a unit ID that receives events, so refresh it to make
				-- sure it still points to this GUID.
				self:UpdateUnit(unitId)
				if not bestPriority and self.unitIdToGUID[unitId] == guid then
					bestUnitId = unitId
				end
			end
		end
		return bestUnitId
	end
	return nil
end

function OvaleGUID:GetGUIDForName(name)
	return self.nameToGUID[name]
end

function OvaleGUID:GetUnitIdForName(name)
	return self:GetUnitId(self:GetGUIDForName(name))
end
--</public-static-methods>
