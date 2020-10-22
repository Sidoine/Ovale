local __exports = LibStub:NewLibrary("ovale/Warlock", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local tonumber = tonumber
local pairs = pairs
local GetTime = GetTime
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local find = string.find
local pow = math.pow
local CUSTOM_AURAS = {
    [80240] = {
        customId = -80240,
        duration = 10,
        stacks = 1,
        auraName = "active_havoc"
    }
}
local demonData = {
    [55659] = {
        duration = 12
    },
    [98035] = {
        duration = 12
    },
    [103673] = {
        duration = 12
    },
    [11859] = {
        duration = 25
    },
    [89] = {
        duration = 25
    },
    [143622] = {
        duration = 12
    },
    [135002] = {
        duration = 15
    },
    [17252] = {
        duration = 15
    },
    [135816] = {
        duration = 15
    }
}
local self_demons = {}
local self_serial = 1
__exports.OvaleWarlockClass = __class(nil, {
    constructor = function(self, ovale, ovaleAura, ovalePaperDoll, ovaleSpellBook)
        self.ovale = ovale
        self.ovaleAura = ovaleAura
        self.ovalePaperDoll = ovalePaperDoll
        self.ovaleSpellBook = ovaleSpellBook
        self.OnInitialize = function()
            if self.ovale.playerClass == "WARLOCK" then
                self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", self.COMBAT_LOG_EVENT_UNFILTERED)
                self_demons = {}
            end
        end
        self.OnDisable = function()
            if self.ovale.playerClass == "WARLOCK" then
                self.module:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            end
        end
        self.COMBAT_LOG_EVENT_UNFILTERED = function(event, ...)
            local _, cleuEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId = CombatLogGetCurrentEventInfo()
            if sourceGUID ~= self.ovale.playerGUID then
                return 
            end
            self_serial = self_serial + 1
            if cleuEvent == "SPELL_SUMMON" then
                local _, _, _, _, _, _, _, creatureId = find(destGUID, "(%S+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%S+)")
                creatureId = tonumber(creatureId)
                local now = GetTime()
                for id, v in pairs(demonData) do
                    if id == creatureId then
                        self_demons[destGUID] = {
                            id = creatureId,
                            timestamp = now,
                            finish = now + v.duration
                        }
                        break
                    end
                end
                for k, d in pairs(self_demons) do
                    if d.finish < now then
                        self_demons[k] = nil
                    end
                end
                self.ovale:needRefresh()
            elseif cleuEvent == "SPELL_CAST_SUCCESS" then
                if spellId == 196277 then
                    for k, d in pairs(self_demons) do
                        if d.id == 55659 or d.id == 143622 then
                            self_demons[k] = nil
                        end
                    end
                    self.ovale:needRefresh()
                end
                local aura = CUSTOM_AURAS[spellId]
                if aura then
                    self:AddCustomAura(aura.customId, aura.stacks, aura.duration, aura.auraName)
                end
            end
        end
        self.module = ovale:createModule("OvaleWarlock", self.OnInitialize, self.OnDisable, aceEvent)
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    GetNotDemonicEmpoweredDemonsCount = function(self, creatureId, atTime)
        local count = 0
        for _, d in pairs(self_demons) do
            if d.finish >= atTime and d.id == creatureId and  not d.de then
                count = count + 1
            end
        end
        return count
    end,
    GetDemonsCount = function(self, creatureId, atTime)
        local count = 0
        for _, d in pairs(self_demons) do
            if d.finish >= atTime and d.id == creatureId then
                count = count + 1
            end
        end
        return count
    end,
    GetRemainingDemonDuration = function(self, creatureId, atTime)
        local max = 0
        for _, d in pairs(self_demons) do
            if d.finish >= atTime and d.id == creatureId then
                local remaining = d.finish - atTime
                if remaining > max then
                    max = remaining
                end
            end
        end
        return max
    end,
    AddCustomAura = function(self, customId, stacks, duration, buffName)
        local now = GetTime()
        local expire = now + duration
        self.ovaleAura:GainedAuraOnGUID(self.ovale.playerGUID, now, customId, self.ovale.playerGUID, "HELPFUL", false, nil, stacks, nil, duration, expire, false, buffName, nil, nil, nil)
    end,
    TimeToShard = function(self, now)
        local value = 3600
        local creepingDeathTalent = 20
        local tickTime = 2 / self.ovalePaperDoll:GetHasteMultiplier("spell", self.ovalePaperDoll.next)
        local activeAgonies = self.ovaleAura:AuraCount(980, "HARMFUL", true, nil, now, nil)
        if activeAgonies > 0 then
            value = ((1 / (0.184 * pow(activeAgonies, -2 / 3))) * tickTime) / activeAgonies
            if self.ovaleSpellBook:IsKnownTalent(creepingDeathTalent) then
                value = value * 0.85
            end
        end
        return value
    end,
})
