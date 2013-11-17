--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2009, 2010, 2011, 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

--[[
	Damage meter addons that want to receive Ovale scores should implement
	and register a function that has the following signature:

		ReceiveScore(name, guid, scored, scoreMax)

		Parameters:
			name - the name of the unit
			guid - GUID of the named unit
			scored - current score
			scoreMax - current maximum score

		Returns:
			none

	The function should be registered with Ovale using the RegisterDamageMeter
	method, which needs a unique name for the meter and either the function itself
	or a method name for the module with the given name.
]]--

local _, Ovale = ...
local OvaleScore = Ovale:NewModule("OvaleScore", "AceEvent-3.0")
Ovale.OvaleScore = OvaleScore

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleGUID = nil

local pairs = pairs
local strsplit = string.split
local API_RegisterAddonMessagePrefix = RegisterAddonMessagePrefix
local API_SendAddonMessage = SendAddonMessage

-- Player's GUID.
local self_guid = nil
-- self_damageMeter[moduleName] = module
local self_damageMeter = {}
-- self_damageMeterMethod[moduleName] = methodName or function
local self_damageMeterMethod = {}
-- Score from current combat session.
local self_score = 0
-- Maximum possible score from current combat session.
local self_maxScore = 0
-- Spells for which a score is computed.
local self_scoredSpell = {}
--</private-static-properties>

--<public-static-properties>
--</public-static-properties>

--<public-static-methods>
function OvaleScore:OnInitialize()
	-- Resolve module dependencies.
	OvaleGUID = Ovale.OvaleGUID
end

function OvaleScore:OnEnable()
	self_guid = OvaleGUID:GetGUID("player")
	API_RegisterAddonMessagePrefix("Ovale")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function OvaleScore:OnDisable()
	self:UnregisterEvent("CHAT_MSG_ADDON")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
end

-- Receive scores for damage meters from other Ovale addons in the raid.
function OvaleScore:CHAT_MSG_ADDON(event, ...)
	local prefix, message, channel, sender = ...
	if prefix ~= "Ovale" then return end
	if channel ~= "RAID" and channel ~= "PARTY" then return end

	local scored, scoreMax, guid = strsplit(";", message)
	self:SendScore(sender, guid, scored, scoreMax)
end

function OvaleScore:PLAYER_REGEN_ENABLED()
	-- Broadcast the player's own score for damage meters when combat ends.
	-- Broadcast message is "score;maxScore;playerGUID"
	if self_maxScore > 0 then
		local message = self_score .. ";" .. self_maxScore .. ";" .. self_guid
		API_SendAddonMessage("Ovale", message, "RAID")
	end
end

function OvaleScore:PLAYER_REGEN_DISABLED()
	self_score = 0
	self_maxScore = 0
end

-- RegisterDamageMeter(moduleName, function) or
-- RegisterDamageMeter(moduleName, addonObject, methodName)
function OvaleScore:RegisterDamageMeter(moduleName, addon, func)
	if not func then
		func = addon
	elseif addon then
		self_damageMeter[moduleName] = addon
	end
	self_damageMeterMethod[moduleName] = func
end

function OvaleScore:UnregisterDamageMeter(moduleName)
	self_damageMeter[moduleName] = nil
	self_damageMeterMethod[moduleName] = nil
end

function OvaleScore:AddSpell(spellId)
	self_scoredSpell[spellId] = true
end

function OvaleScore:ScoreSpell(spellId)
	if Ovale.enCombat and self_scoredSpell[spellId] then
		local scored = Ovale.frame:GetScore(spellId)
		Ovale:Logf("Scored %s", scored)
		if scored then
			self_score = self_score + scored
			self_maxScore = self_maxScore + 1
			self:SendScore(self_playerName, self_guid, scored, 1)
		end
	end
end

function OvaleScore:SendScore(name, guid, scored, scoreMax)
	for moduleName, method in pairs(self_damageMeterMethods) do
		local addon = self_damageMeter[moduleName]
		if addon then
			addon[method](addon, name, guid, scored, scoreMax)
		elseif type(method) == "function" then
			method(name, guid, scored, scoreMax)
		end
	end
end
--</public-static-methods>
