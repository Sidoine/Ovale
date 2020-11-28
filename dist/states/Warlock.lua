local __exports = LibStub:NewLibrary("ovale/states/Warlock", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local tonumber = tonumber
local pairs = pairs
local GetTime = GetTime
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local find = string.find
local pow = math.pow
local __engineCondition = LibStub:GetLibrary("ovale/engine/Condition")
local Compare = __engineCondition.Compare
local CUSTOM_AURAS = {
    [80240] = {
        customId = -80240,
        duration = 10,
        stacks = 1,
        auraName = "active_havoc"
    }
}
local INNER_DEMONS_TALENT = 17
local demonData = {
    [55659] = {
        duration = 15
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
__exports.OvaleWarlockClass = __class(nil, {
    constructor = function(self, ovale, ovaleAura, ovalePaperDoll, ovaleSpellBook, future, power)
        self.ovale = ovale
        self.ovaleAura = ovaleAura
        self.ovalePaperDoll = ovalePaperDoll
        self.ovaleSpellBook = ovaleSpellBook
        self.future = future
        self.power = power
        self.demonsCount = {}
        self.serial = 1
        self.OnInitialize = function()
            if self.ovale.playerClass == "WARLOCK" then
                self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", self.COMBAT_LOG_EVENT_UNFILTERED)
                self.demonsCount = {}
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
            self.serial = self.serial + 1
            if cleuEvent == "SPELL_SUMMON" then
                local _, _, _, _, _, _, _, creatureId = find(destGUID, "(%S+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%S+)")
                creatureId = tonumber(creatureId)
                local now = GetTime()
                for id, v in pairs(demonData) do
                    if id == creatureId then
                        self.demonsCount[destGUID] = {
                            id = creatureId,
                            timestamp = now,
                            finish = now + v.duration
                        }
                        break
                    end
                end
                for k, d in pairs(self.demonsCount) do
                    if d.finish < now then
                        self.demonsCount[k] = nil
                    end
                end
                self.ovale:needRefresh()
            elseif cleuEvent == "SPELL_CAST_SUCCESS" then
                if spellId == 196277 then
                    for k, d in pairs(self.demonsCount) do
                        if d.id == 55659 or d.id == 143622 then
                            self.demonsCount[k] = nil
                        end
                    end
                    self.ovale:needRefresh()
                end
                local aura = CUSTOM_AURAS[spellId]
                if aura then
                    self:addCustomAura(aura.customId, aura.stacks, aura.duration, aura.auraName)
                end
            end
        end
        self.impsSpawnedDuring = function(positionalParams, namedParams, atTime)
            local ms, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local delay = (ms or 0) / 1000
            local impsSpawned = 0
            if self.future.next.currentCast.spellId == 105174 then
                local soulshards = self.power.current.power["soulshards"] or 0
                if soulshards >= 3 then
                    soulshards = 3
                end
                impsSpawned = impsSpawned + soulshards
            end
            local talented = self.ovaleSpellBook:GetTalentPoints(INNER_DEMONS_TALENT) > 0
            if talented then
                local value = self:getRemainingDemonDuration(143622, atTime + delay)
                if value <= 0 then
                    impsSpawned = impsSpawned + 1
                end
            end
            return Compare(impsSpawned, comparator, limit)
        end
        self.getDemonsCount = function(positionalParams, namedParams, atTime)
            local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local count = 0
            for _, d in pairs(self.demonsCount) do
                if d.finish >= atTime and d.id == creatureId then
                    count = count + 1
                end
            end
            return Compare(count, comparator, limit)
        end
        self.demonDuration = function(positionalParams, namedParams, atTime)
            local creatureId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            local value = self:getRemainingDemonDuration(creatureId, atTime)
            return Compare(value, comparator, limit)
        end
        self.timeToShard = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            local value = self:getTimeToShard(atTime)
            return Compare(value, comparator, limit)
        end
        self.module = ovale:createModule("OvaleWarlock", self.OnInitialize, self.OnDisable, aceEvent)
    end,
    registerConditions = function(self, condition)
        condition:RegisterCondition("timetoshard", false, self.timeToShard)
        condition:RegisterCondition("demons", false, self.getDemonsCount)
        condition:RegisterCondition("demonduration", false, self.demonDuration)
        condition:RegisterCondition("impsspawnedduring", false, self.impsSpawnedDuring)
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    getRemainingDemonDuration = function(self, creatureId, atTime)
        local max = 0
        for _, d in pairs(self.demonsCount) do
            if d.finish >= atTime and d.id == creatureId then
                local remaining = d.finish - atTime
                if remaining > max then
                    max = remaining
                end
            end
        end
        return max
    end,
    addCustomAura = function(self, customId, stacks, duration, buffName)
        local now = GetTime()
        local expire = now + duration
        self.ovaleAura:GainedAuraOnGUID(self.ovale.playerGUID, now, customId, self.ovale.playerGUID, "HELPFUL", false, nil, stacks, nil, duration, expire, false, buffName, nil, nil, nil)
    end,
    getTimeToShard = function(self, now)
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
