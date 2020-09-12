local __exports = LibStub:NewLibrary("ovale/Score", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local MSG_PREFIX = __Ovale.MSG_PREFIX
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local aceSerializer = LibStub:GetLibrary("AceSerializer-3.0", true)
local pairs = pairs
local type = type
local IsInGroup = IsInGroup
local SendAddonMessage = SendAddonMessage
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
__exports.OvaleScoreClass = __class(nil, {
    constructor = function(self, ovale, ovaleFuture, ovaleDebug, ovaleSpellBook, combat)
        self.ovale = ovale
        self.ovaleFuture = ovaleFuture
        self.ovaleSpellBook = ovaleSpellBook
        self.combat = combat
        self.damageMeter = {}
        self.damageMeterMethod = {}
        self.score = 0
        self.maxScore = 0
        self.scoredSpell = {}
        self.OnInitialize = function()
            self.module:RegisterEvent("CHAT_MSG_ADDON", self.CHAT_MSG_ADDON)
            self.module:RegisterEvent("PLAYER_REGEN_ENABLED", self.PLAYER_REGEN_ENABLED)
            self.module:RegisterEvent("PLAYER_REGEN_DISABLED", self.PLAYER_REGEN_DISABLED)
            self.module:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", self.UNIT_SPELLCAST_CHANNEL_START)
            self.module:RegisterEvent("UNIT_SPELLCAST_START", self.UNIT_SPELLCAST_START)
        end
        self.OnDisable = function()
            self.module:UnregisterEvent("CHAT_MSG_ADDON")
            self.module:UnregisterEvent("PLAYER_REGEN_ENABLED")
            self.module:UnregisterEvent("PLAYER_REGEN_DISABLED")
            self.module:UnregisterEvent("UNIT_SPELLCAST_START")
        end
        self.CHAT_MSG_ADDON = function(event, ...)
            local prefix, message, _, sender = ...
            if prefix == MSG_PREFIX then
                local ok, msgType, scored, scoreMax, guid = self.module:Deserialize(message)
                if ok and msgType == "S" then
                    self:SendScore(sender, guid, scored, scoreMax)
                end
            end
        end
        self.PLAYER_REGEN_ENABLED = function()
            if self.maxScore > 0 and IsInGroup() then
                local message = self.module:Serialize("score", self.score, self.maxScore, self.ovale.playerGUID)
                local channel = (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT") or "RAID"
                SendAddonMessage(MSG_PREFIX, message, channel)
            end
        end
        self.PLAYER_REGEN_DISABLED = function()
            self.score = 0
            self.maxScore = 0
        end
        self.UNIT_SPELLCAST_CHANNEL_START = function(event, unitId, lineId, spellId)
            if unitId == "player" or unitId == "pet" then
                local now = GetTime()
                local spell = self.ovaleSpellBook:GetSpellName(spellId)
                if spell then
                    local spellcast = self.ovaleFuture:GetSpellcast(spell, spellId, nil, now)
                    if spellcast then
                        local name = UnitChannelInfo(unitId)
                        if name == spell then
                            self:ScoreSpell(spellId)
                        end
                    end
                end
            end
        end
        self.UNIT_SPELLCAST_START = function(event, unitId, lineId, spellId)
            if unitId == "player" or unitId == "pet" then
                local spell = self.ovaleSpellBook:GetSpellName(spellId)
                if spell then
                    local now = GetTime()
                    local spellcast = self.ovaleFuture:GetSpellcast(spell, spellId, lineId, now)
                    if spellcast then
                        local name, _, _, _, _, _, castId = UnitCastingInfo(unitId)
                        if lineId == castId and name == spell then
                            self:ScoreSpell(spellId)
                        end
                    end
                end
            end
        end
        self.UNIT_SPELLCAST_SUCCEEDED = function(event, unitId, lineId, spellId)
            if unitId == "player" or unitId == "pet" then
                local spell = self.ovaleSpellBook:GetSpellName(spellId)
                if spell then
                    local now = GetTime()
                    local spellcast = self.ovaleFuture:GetSpellcast(spell, spellId, lineId, now)
                    if spellcast then
                        if spellcast.success or  not spellcast.start or  not spellcast.stop or spellcast.channel then
                            local name = UnitChannelInfo(unitId)
                            if  not name then
                                self:ScoreSpell(spellId)
                            end
                        end
                    end
                end
            end
        end
        self.module = ovale:createModule("OvaleScore", self.OnInitialize, self.OnDisable, aceEvent, aceSerializer)
        self.tracer = ovaleDebug:create(self.module:GetName())
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
        if self.combat:isInCombat(nil) and self.scoredSpell[spellId] then
            local scored = 0
            self.tracer:DebugTimestamp("Scored %s for %d.", scored, spellId)
            if scored then
                self.score = self.score + scored
                self.maxScore = self.maxScore + 1
                self:SendScore(self.module:GetName(), self.ovale.playerGUID, scored, 1)
            end
        end
    end,
    SendScore = function(self, name, guid, scored, scoreMax)
        for moduleName, method in pairs(self.damageMeterMethod) do
            local addon = self.damageMeter[moduleName]
            if addon then
                method(name, guid, scored, scoreMax)
            elseif type(method) == "function" then
            end
        end
    end,
})
