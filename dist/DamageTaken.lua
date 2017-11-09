local __exports = LibStub:NewLibrary("ovale/DamageTaken", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Pool = LibStub:GetLibrary("ovale/Pool")
local OvalePool = __Pool.OvalePool
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Queue = LibStub:GetLibrary("ovale/Queue")
local OvaleQueue = __Queue.OvaleQueue
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local RegisterPrinter = __Ovale.RegisterPrinter
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local band = bit.band
local bor = bit.bor
local sub = string.sub
local GetTime = GetTime
local SCHOOL_MASK_ARCANE = SCHOOL_MASK_ARCANE
local SCHOOL_MASK_FIRE = SCHOOL_MASK_FIRE
local SCHOOL_MASK_FROST = SCHOOL_MASK_FROST
local SCHOOL_MASK_HOLY = SCHOOL_MASK_HOLY
local SCHOOL_MASK_NATURE = SCHOOL_MASK_NATURE
local SCHOOL_MASK_SHADOW = SCHOOL_MASK_SHADOW
local OvaleDamageTakenBase = RegisterPrinter(OvaleProfiler:RegisterProfiling(OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleDamageTaken", aceEvent))))
local self_pool = OvalePool("OvaleDamageTaken_pool")
local DAMAGE_TAKEN_WINDOW = 20
local SCHOOL_MASK_MAGIC = bor(SCHOOL_MASK_ARCANE, SCHOOL_MASK_FIRE, SCHOOL_MASK_FROST, SCHOOL_MASK_HOLY, SCHOOL_MASK_NATURE, SCHOOL_MASK_SHADOW)
local OvaleDamageTakenClass = __class(OvaleDamageTakenBase, {
    constructor = function(self)
        self.damageEvent = OvaleQueue("OvaleDamageTaken_damageEvent")
        OvaleDamageTakenBase.constructor(self)
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self_pool:Drain()
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, arg13, arg14, arg15, _, _, _, _, _, _, _, _, _ = ...
        if destGUID == Ovale.playerGUID and sub(cleuEvent, -7) == "_DAMAGE" then
            self:StartProfiling("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED")
            local now = GetTime()
            local eventPrefix = sub(cleuEvent, 1, 6)
            if eventPrefix == "SWING_" then
                local amount = arg12
                self:Debug("%s caused %d damage.", cleuEvent, amount)
                self:AddDamageTaken(now, amount)
            elseif eventPrefix == "RANGE_" or eventPrefix == "SPELL_" then
                local spellName, spellSchool, amount = arg13, arg14, arg15
                local isMagicDamage = (band(spellSchool, SCHOOL_MASK_MAGIC) > 0)
                if isMagicDamage then
                    self:Debug("%s (%s) caused %d magic damage.", cleuEvent, spellName, amount)
                else
                    self:Debug("%s (%s) caused %d damage.", cleuEvent, spellName, amount)
                end
                self:AddDamageTaken(now, amount, isMagicDamage)
            end
            self:StopProfiling("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    PLAYER_REGEN_ENABLED = function(self, event)
        self_pool:Drain()
    end,
    AddDamageTaken = function(self, timestamp, damage, isMagicDamage)
        self:StartProfiling("OvaleDamageTaken_AddDamageTaken")
        local event = self_pool:Get()
        event.timestamp = timestamp
        event.damage = damage
        event.magic = isMagicDamage
        self.damageEvent:InsertFront(event)
        self:RemoveExpiredEvents(timestamp)
        Ovale:needRefresh()
        self:StopProfiling("OvaleDamageTaken_AddDamageTaken")
    end,
    GetRecentDamage = function(self, interval)
        local now = GetTime()
        local lowerBound = now - interval
        self:RemoveExpiredEvents(now)
        local total, totalMagic = 0, 0
        local iterator = self.damageEvent:FrontToBackIterator()
        while iterator:Next() do
            local event = iterator.value
            if event.timestamp < lowerBound then
                break
            end
            total = total + event.damage
            if event.magic then
                totalMagic = totalMagic + event.damage
            end
        end
        return total, totalMagic
    end,
    RemoveExpiredEvents = function(self, timestamp)
        self:StartProfiling("OvaleDamageTaken_RemoveExpiredEvents")
        while true do
            local event = self.damageEvent:Back()
            if  not event then
                break
            end
            if event then
                if timestamp - event.timestamp < DAMAGE_TAKEN_WINDOW then
                    break
                end
                self.damageEvent:RemoveBack()
                self_pool:Release(event)
                Ovale:needRefresh()
            end
        end
        self:StopProfiling("OvaleDamageTaken_RemoveExpiredEvents")
    end,
    DebugDamageTaken = function(self)
        self.damageEvent:DebuggingInfo()
        local iterator = self.damageEvent:BackToFrontIterator()
        while iterator:Next() do
            local event = iterator.value
            self:Print("%d: %d damage", event.timestamp, event.damage)
        end
    end,
})
__exports.OvaleDamageTaken = OvaleDamageTakenClass()
