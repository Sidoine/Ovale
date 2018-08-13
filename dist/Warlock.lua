local __exports = LibStub:NewLibrary("ovale/Warlock", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local tonumber = tonumber
local pairs = pairs
local GetTime = GetTime
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local find = string.find
local __Options = LibStub:GetLibrary("ovale/Options")
local OvaleOptions = __Options.OvaleOptions
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local pow = math.pow
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local OvaleWarlockBase = Ovale:NewModule("OvaleWarlock", aceEvent)
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
    }
}
local self_demons = {}
local self_serial = 1
local OvaleWarlockClass = __class(OvaleWarlockBase, {
    OnInitialize = function(self)
        if Ovale.playerClass == "WARLOCK" then
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self_demons = {}
        end
    end,
    OnDisable = function(self)
        if Ovale.playerClass == "WARLOCK" then
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, ...)
        local _, cleuEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId = CombatLogGetCurrentEventInfo()
        if sourceGUID ~= Ovale.playerGUID then
            return 
        end
        self_serial = self_serial + 1
        if cleuEvent == "SPELL_SUMMON" then
            local _, _, _, _, _, _, _, creatureId = find(destGUID, "(%S+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%S+)")
            creatureId = tonumber(creatureId)
            local now = GetTime()
            for id, v in pairs(demonData) do
                if id == creatureId then
                    creatureId = (creatureId == 143622) and 55659 or creatureId
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
            Ovale:needRefresh()
        elseif cleuEvent == "SPELL_CAST_SUCCESS" then
            if spellId == 196277 then
                for k, d in pairs(self_demons) do
                    if d.id == 55659 or d.id == 143622 then
                        self_demons[k] = nil
                    end
                end
                Ovale:needRefresh()
            end
            if CUSTOM_AURAS[spellId] then
                local aura = CUSTOM_AURAS[spellId]
                self:AddCustomAura(aura.customId, aura.stacks, aura.duration, aura.auraName)
            end
        end
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
        local filter = OvaleOptions.defaultDB.profile.apparence.fullAuraScan and "HELPFUL" or "HELPFUL|PLAYER"
        OvaleAura:GainedAuraOnGUID(Ovale.playerGUID, now, customId, Ovale.playerGUID, filter, nil, nil, stacks, nil, duration, expire, nil, buffName, nil, nil, nil)
    end,
    TimeToShard = function(self)
        local now = GetTime()
        local filter = OvaleOptions.defaultDB.profile.apparence.fullAuraScan and "HARMFUL" or "HARMFUL|PLAYER"
        local value = 3600
        local creepingDeathTalent = 20
        local tickTime = 2 / OvalePaperDoll:GetHasteMultiplier("spell", OvalePaperDoll.next)
        local activeAgonies = OvaleAura:AuraCount(980, filter, true, nil, now, nil)
        if activeAgonies > 0 then
            value = 1 / (0.184 * pow(activeAgonies, -2 / 3)) * tickTime / activeAgonies
            if OvaleSpellBook:IsKnownTalent(creepingDeathTalent) then
                value = value * 0.85
            end
        end
        return value
    end,
})
__exports.OvaleWarlock = OvaleWarlockClass()
OvaleState:RegisterState(__exports.OvaleWarlock)
