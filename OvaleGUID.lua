--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

-- This addon translates a GUID to a target name
-- Usage: OvaleGUID:GetUnitId(guid)

local _, Ovale = ...
local OvaleGUID = Ovale:NewModule("OvaleGUID", "AceEvent-3.0", "AceConsole-3.0")
Ovale.OvaleGUID = OvaleGUID

--<private-static-properties>
local strfind = string.find
local strsub = string.sub
local API_GetNumGroupMembers = GetNumGroupMembers
local API_UnitGUID = UnitGUID
local API_UnitName = UnitName

local self_unitId = {}
local self_guid = {}
local self_nameToGUID = {}
local self_nameToUnit = {}

local OVALE_GUID_DEBUG = "guid"
--</private-static-properties>

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
	--self:FormatPrint("OvaleGUID:Update %s", unitId)
	local guid = API_UnitGUID(unitId)
	local previousGuid = self_guid[unitId]
	if previousGuid ~= guid then
		if previousGuid and self_unitId[previousGuid] then
			self_unitId[previousGuid][unitId] = nil
			if not next(self_unitId[previousGuid]) then
				self_unitId[previousGuid] = nil
			end
		end
		self_guid[unitId] = guid
		if guid then
			if not self_unitId[guid] then
				self_unitId[guid] = {}
			end
			Ovale:DebugPrintf(OVALE_GUID_DEBUG, "GUID %s is %s", guid, unitId)
			self_unitId[guid][unitId] = true
		end
	end
	local name = API_UnitName(unitId)
	if name and (not self_nameToGUID[name] or unitId == "target" 
			or self_nameToUnit[name] == "mouseover") then
		self_nameToGUID[name] = guid
		self_nameToUnit[name] = unitId
	end
end

function OvaleGUID:GetGUID(unitId)
	if not self_guid[unitId] then
		self_guid[unitId] = API_UnitGUID(unitId)
	end
	return self_guid[unitId]
end

function OvaleGUID:GetGUIDForName(name)
	return self_nameToGUID[name]
end

function OvaleGUID:GetUnitId(guid)
	local unitIdTable = self_unitId[guid]
	if not unitIdTable then return nil end
	return next(unitIdTable)
end

function OvaleGUID:GetUnitIdForName(name)
	return self_nameToUnit[name]
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
