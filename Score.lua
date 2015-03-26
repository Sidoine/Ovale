--[[--------------------------------------------------------------------
    Copyright (C) 2009, 2010, 2011, 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
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

local OVALE, Ovale = ...
local OvaleScore = Ovale:NewModule("OvaleScore", "AceEvent-3.0", "AceSerializer-3.0")
Ovale.OvaleScore = OvaleScore

--<private-static-properties>
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug

-- Forward declarations for module dependencies.
local OvaleFuture = nil

local pairs = pairs
local type = type
local API_IsInGroup = IsInGroup
local API_SendAddonMessage = SendAddonMessage
local API_UnitName = UnitName
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local MSG_PREFIX = Ovale.MSG_PREFIX

-- Player's GUID.
local self_playerGUID = nil
-- Player's name.
local self_name = nil

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvaleScore)
--</private-static-properties>

--<public-static-properties>
-- self_damageMeter[moduleName] = module
OvaleScore.damageMeter = {}
-- self_damageMeterMethod[moduleName] = methodName or function
OvaleScore.damageMeterMethod = {}
-- Score from current combat session.
OvaleScore.score = 0
-- Maximum possible score from current combat session.
OvaleScore.maxScore = 0
-- Spells for which a score is computed.
OvaleScore.scoredSpell = {}
--</public-static-properties>

--<public-static-methods>
function OvaleScore:OnInitialize()
	-- Resolve module dependencies.
	OvaleFuture = Ovale.OvaleFuture
end

function OvaleScore:OnEnable()
	self_playerGUID = Ovale.playerGUID
	self_name = API_UnitName("player")
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
	if prefix == MSG_PREFIX then
		local ok, msgType, scored, scoreMax, guid = self:Deserialize(message)
		if ok and msgType == "S" then
			self:SendScore(sender, guid, scored, scoreMax)
		end
	end
end

function OvaleScore:PLAYER_REGEN_ENABLED()
	-- Broadcast the player's own score for damage meters when combat ends.
	-- Broadcast message is "score;maxScore;playerGUID"
	if self.maxScore > 0 and API_IsInGroup() then
		local message = self:Serialize("score", self.score, self.maxScore, self_playerGUID)
		local channel = API_IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID"
		API_SendAddonMessage(MSG_PREFIX, message, channel)
	end
end

function OvaleScore:PLAYER_REGEN_DISABLED()
	self.score = 0
	self.maxScore = 0
end

-- RegisterDamageMeter(moduleName, function) or
-- RegisterDamageMeter(moduleName, addonObject, methodName)
function OvaleScore:RegisterDamageMeter(moduleName, addon, func)
	if not func then
		func = addon
	elseif addon then
		self.damageMeter[moduleName] = addon
	end
	self.damageMeterMethod[moduleName] = func
end

function OvaleScore:UnregisterDamageMeter(moduleName)
	self.damageMeter[moduleName] = nil
	self.damageMeterMethod[moduleName] = nil
end

function OvaleScore:AddSpell(spellId)
	self.scoredSpell[spellId] = true
end

function OvaleScore:ScoreSpell(spellId)
	if OvaleFuture.inCombat and self.scoredSpell[spellId] then
		local scored = Ovale.frame:GetScore(spellId)
		self:DebugTimestamp("Scored %s for %d.", scored, spellId)
		if scored then
			self.score = self.score + scored
			self.maxScore = self.maxScore + 1
			self:SendScore(self_name, self_playerGUID, scored, 1)
		end
	end
end

function OvaleScore:SendScore(name, guid, scored, scoreMax)
	for moduleName, method in pairs(self.damageMeterMethod) do
		local addon = self.damageMeter[moduleName]
		if addon then
			addon[method](addon, name, guid, scored, scoreMax)
		elseif type(method) == "function" then
			method(name, guid, scored, scoreMax)
		end
	end
end
--</public-static-methods>
