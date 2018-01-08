local __exports = LibStub:NewLibrary("ovale/Score", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Future = LibStub:GetLibrary("ovale/Future")
local OvaleFuture = __Future.OvaleFuture
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0", true)
local pairs = pairs
local type = type
local IsInGroup = IsInGroup
local SendAddonMessage = SendAddonMessage
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local OvaleScoreBase = OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleScore", aceEvent, AceSerializer))
local MSG_PREFIX = Ovale.MSG_PREFIX
local self_playerGUID = nil
local OvaleScoreClass = __class(OvaleScoreBase, {
    OnInitialize = function(self)
        self_playerGUID = Ovale.playerGUID
        self:RegisterEvent("CHAT_MSG_ADDON")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        self:RegisterEvent("UNIT_SPELLCAST_START")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("CHAT_MSG_ADDON")
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:UnregisterEvent("PLAYER_REGEN_DISABLED")
        self:UnregisterEvent("UNIT_SPELLCAST_START")
    end,
    CHAT_MSG_ADDON = function(self, event, ...)
        local prefix, message, _, sender = ...
        if prefix == MSG_PREFIX then
            local ok, msgType, scored, scoreMax, guid = self:Deserialize(message)
            if ok and msgType == "S" then
                self:SendScore(sender, guid, scored, scoreMax)
            end
        end
    end,
    PLAYER_REGEN_ENABLED = function(self)
        if self.maxScore > 0 and IsInGroup() then
            local message = self:Serialize("score", self.score, self.maxScore, self_playerGUID)
            local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID"
            SendAddonMessage(MSG_PREFIX, message, channel)
        end
    end,
    PLAYER_REGEN_DISABLED = function(self)
        self.score = 0
        self.maxScore = 0
    end,
    RegisterDamageMeter = function(self, moduleName, addon, func)
        if  not func then
            func = addon
        elseif addon then
            self.damageMeter[moduleName] = addon
        end
        self.damageMeterMethod[moduleName] = func
    end,
    UnregisterDamageMeter = function(self, moduleName)
        self.damageMeter[moduleName] = nil
        self.damageMeterMethod[moduleName] = nil
    end,
    AddSpell = function(self, spellId)
        self.scoredSpell[spellId] = true
    end,
    ScoreSpell = function(self, spellId)
    end,
    SendScore = function(self, name, guid, scored, scoreMax)
        for moduleName, method in pairs(self.damageMeterMethod) do
            local addon = self.damageMeter[moduleName]
            if addon then
                addon[method](addon, name, guid, scored, scoreMax)
            elseif type(method) == "function" then
            end
        end
    end,
    UNIT_SPELLCAST_CHANNEL_START = function(self, event, unitId, spell, rank, lineId, spellId)
        if unitId == "player" or unitId == "pet" then
            local now = GetTime()
            local spellcast = OvaleFuture:GetSpellcast(spell, spellId, nil, now)
            if spellcast then
                local name = UnitChannelInfo(unitId)
                if name == spell then
                    self:ScoreSpell(spellId)
                end
            end
        end
    end,
    UNIT_SPELLCAST_START = function(self, event, unitId, spell, rank, lineId, spellId)
        if unitId == "player" or unitId == "pet" then
            local now = GetTime()
            local spellcast = OvaleFuture:GetSpellcast(spell, spellId, lineId, now)
            if spellcast then
                local name, _, _, _, _, _, _, castId = UnitCastingInfo(unitId)
                if lineId == castId and name == spell then
                    self:ScoreSpell(spellId)
                end
            end
        end
    end,
    UNIT_SPELLCAST_SUCCEEDED = function(self, event, unitId, spell, rank, lineId, spellId)
        if unitId == "player" or unitId == "pet" then
            local now = GetTime()
            local spellcast = OvaleFuture:GetSpellcast(spell, spellId, lineId, now)
            if spellcast then
                if spellcast.success or ( not spellcast.start) or ( not spellcast.stop) or spellcast.channel then
                    local name = UnitChannelInfo(unitId)
                    if  not name then
                        __exports.OvaleScore:ScoreSpell(spellId)
                    end
                end
            end
        end
    end,
    constructor = function(self, ...)
        OvaleScoreBase.constructor(self, ...)
        self.damageMeter = {}
        self.damageMeterMethod = {}
        self.score = 0
        self.maxScore = 0
        self.scoredSpell = {}
    end
})
__exports.OvaleScore = OvaleScoreClass()
