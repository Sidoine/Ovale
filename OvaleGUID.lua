--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- This addon translates a GUID to a target name
-- Usage: OvaleGUID:GetUnitId(guid)

local _, Ovale = ...
local OvaleGUID = Ovale:NewModule("OvaleGUID", "AceEvent-3.0", "AceConsole-3.0")
Ovale.OvaleGUID = OvaleGUID

--<private-static-properties>
local strfind = string.find
local strsub = string.sub
local API_GetNumGroupMembers = GetNumGroupMembers
local API_UnitExists = UnitExists
local API_UnitGUID = UnitGUID
local API_UnitName = UnitName

local OVALE_GUID_DEBUG = "guid"
--</private-static-properties>

--<public-static-properties>
OvaleGUID.unitId = {}
OvaleGUID.guid = {}
OvaleGUID.nameToGUID = {}
OvaleGUID.nameToUnit = {}

-- Units for which UNIT_AURA is known to fire.
-- These are unit IDs that correspond to unit frames in the default WoW UI.
OvaleGUID.UNIT_AURA_UNITS = {}
do
	local self = OvaleGUID
	self.UNIT_AURA_UNITS["focus"] = true
	self.UNIT_AURA_UNITS["pet"] = true
	self.UNIT_AURA_UNITS["player"] = true
	self.UNIT_AURA_UNITS["target"] = true

	for i = 1, 5 do
		self.UNIT_AURA_UNITS["arena" .. i] = true
		self.UNIT_AURA_UNITS["arenapet" .. i] = true
	end
	for i = 1, 4 do
		self.UNIT_AURA_UNITS["boss" .. i] = true
	end
	for i = 1, 4 do
		self.UNIT_AURA_UNITS["party" .. i] = true
		self.UNIT_AURA_UNITS["partypet" .. i] = true
	end
	for i = 1, 40 do
		self.UNIT_AURA_UNITS["raid" .. i] = true
		self.UNIT_AURA_UNITS["raidpet" .. i] = true
	end
end
--</public-static-properties>

--<public-static-methods>
function OvaleGUID:OnEnable()
	self:Update("player")
	self:RegisterEvent("ARENA_OPPONENT_UPDATE")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
end

function OvaleGUID:OnDisable()
	self:UnregisterEvent("ARENA_OPPONENT_UPDATE")
	self:UnregisterEvent("GROUP_ROSTER_UPDATE")
	self:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
	self:UnregisterEvent("PLAYER_LOGIN")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("UNIT_PET")
	self:UnregisterEvent("UNIT_TARGET")
	self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
end

function OvaleGUID:Update(unitId)
	local guid = API_UnitGUID(unitId)
	local previousGuid = self.guid[unitId]
	if previousGuid ~= guid then
		if previousGuid and self.unitId[previousGuid] then
			self.unitId[previousGuid][unitId] = nil
			if not next(self.unitId[previousGuid]) then
				self.unitId[previousGuid] = nil
			end
		end
		self.guid[unitId] = guid
		if guid then
			if not self.unitId[guid] then
				self.unitId[guid] = {}
			end
			Ovale:DebugPrintf(OVALE_GUID_DEBUG, "GUID %s is %s", guid, unitId)
			self.unitId[guid][unitId] = true
		end
	end
	local name = API_UnitName(unitId)
	if name and (not self.nameToGUID[name] or unitId == "target" 
			or self.nameToUnit[name] == "mouseover") then
		self.nameToGUID[name] = guid
		self.nameToUnit[name] = unitId
	end
end

function OvaleGUID:GetGUID(unitId)
	if not unitId then return nil end
	local guid = self.guid[unitId]
	if not guid or strfind(unitId, "mouseover") == 1 then
		self.guid[unitId] = API_UnitGUID(unitId)
		guid = self.guid[unitId]
	end
	return guid
end

function OvaleGUID:GetGUIDForName(name)
	return self.nameToGUID[name]
end

-- Return a unit Id associated with guid.
-- Prefer to return a unit Id for which the WoW servers fire UNIT_AURA events.
function OvaleGUID:GetUnitId(guid)
	local unitIdFound = nil
	local unitIdTable = self.unitId[guid]
	if unitIdTable then
		for unitId in pairs(unitIdTable) do
			if self.UNIT_AURA_UNITS[unitId] then
				return unitId
			elseif not unitIdFound then
				if strfind(unitId, "mouseover") == 1 then
					if API_UnitExists(unitId) then
						unitIdFound = unitId
					else
						unitIdTable[unitId] = nil
						self.guid[unitId] = nil
					end
				else
					unitIdFound = unitId
				end
			end
		end
	end
	return unitIdFound
end

function OvaleGUID:GetUnitIdForName(name)
	local unitId = self.nameToUnit[name]
	if strfind(unitId, "mouseover") == 1 then
		if API_UnitExists("mouseover") then
			return unitId
		else
			self.nameToUnit[name] = nil
			return nil
		end
	end
	return unitId
end

function OvaleGUID:UpdateWithTarget(unitId)
	self:Update(unitId)
	self:Update(unitId.."target")
end

function OvaleGUID:PLAYER_LOGIN(event)
	self:Update("player")
end

function OvaleGUID:PLAYER_TARGET_CHANGED(event)
	self:UNIT_TARGET(event, "player")
end

function OvaleGUID:UNIT_TARGET(event, unitId)
	self:Update(unitId .. "target")
	if unitId == "player" then
		self:Update("target")
	end
end

function OvaleGUID:GROUP_ROSTER_UPDATE(event)
	for i=1, API_GetNumGroupMembers() do
		self:UpdateWithTarget("raid"..i)
		self:UpdateWithTarget("raidpet"..i)
	end
	self:SendMessage("Ovale_GroupChanged")
end

function OvaleGUID:UNIT_PET(event, unitId)
	if strfind(unitId, "party") == 0 then
		local petId = "partypet" .. strsub(unitId, 6)
		self:UpdateWithTarget(petId)
	elseif strfind(unitId, "raid") == 0 then
		local petId = "raidpet" .. strsub(unitId, 5)
		self:UpdateWithTarget(petId)
	elseif unitId == "player" then
		self:UpdateWithTarget("pet")
	end
	self:SendMessage("Ovale_GroupChanged")
end

function OvaleGUID:ARENA_OPPONENT_UPDATE(event)
	for i=1, 5 do
		self:UpdateWithTarget("arena"..i)
	end
end

function OvaleGUID:PLAYER_FOCUS_CHANGED(event)
	self:UpdateWithTarget("focus")
end

function OvaleGUID:UPDATE_MOUSEOVER_UNIT(event)
	self:UpdateWithTarget("mouseover")
end

function OvaleGUID:INSTANCE_ENCOUNTER_ENGAGE_UNIT(event)
	for i=1, 4 do
		self:UpdateWithTarget("boss"..i)
	end
end
--</public-static-methods>
