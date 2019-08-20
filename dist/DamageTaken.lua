local __exports = LibStub:NewLibrary("ovale/DamageTaken", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Pool = LibStub:GetLibrary("ovale/Pool")
local OvalePool = __Pool.OvalePool
local __Queue = LibStub:GetLibrary("ovale/Queue")
local OvaleQueue = __Queue.OvaleQueue
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
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local self_pool = OvalePool("OvaleDamageTaken_pool")
local DAMAGE_TAKEN_WINDOW = 20
local SCHOOL_MASK_MAGIC = bor(SCHOOL_MASK_ARCANE, SCHOOL_MASK_FIRE, SCHOOL_MASK_FROST, SCHOOL_MASK_HOLY, SCHOOL_MASK_NATURE, SCHOOL_MASK_SHADOW)
__exports.OvaleDamageTakenClass = __class(nil, {
    constructor = function(self, ovale, profiler, ovaleDebug)
        self.ovale = ovale
        self.damageEvent = OvaleQueue("OvaleDamageTaken_damageEvent")
        self.OnInitialize = function()
            self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", self.COMBAT_LOG_EVENT_UNFILTERED)
            self.module:RegisterEvent("PLAYER_REGEN_ENABLED", self.PLAYER_REGEN_ENABLED)
        end
        self.OnDisable = function()
            self.module:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self.module:UnregisterEvent("PLAYER_REGEN_ENABLED")
            self_pool:Drain()
        end
        self.COMBAT_LOG_EVENT_UNFILTERED = function(event, ...)
            local _, cleuEvent, _, _, _, _, _, destGUID, _, _, _, arg12, arg13, arg14, arg15 = CombatLogGetCurrentEventInfo()
            if destGUID == self.ovale.playerGUID and sub(cleuEvent, -7) == "_DAMAGE" then
                self.profiler:StartProfiling("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED")
                local now = GetTime()
                local eventPrefix = sub(cleuEvent, 1, 6)
                if eventPrefix == "SWING_" then
                    local amount = arg12
                    self.tracer:Debug("%s caused %d damage.", cleuEvent, amount)
                    self:AddDamageTaken(now, amount)
                elseif eventPrefix == "RANGE_" or eventPrefix == "SPELL_" then
                    local spellName, spellSchool, amount = arg13, arg14, arg15
                    local isMagicDamage = (band(spellSchool, SCHOOL_MASK_MAGIC) > 0)
                    if isMagicDamage then
                        self.tracer:Debug("%s (%s) caused %d magic damage.", cleuEvent, spellName, amount)
                    else
                        self.tracer:Debug("%s (%s) caused %d damage.", cleuEvent, spellName, amount)
                    end
                    self:AddDamageTaken(now, amount, isMagicDamage)
                end
                self.profiler:StopProfiling("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED")
            end
        end
        self.PLAYER_REGEN_ENABLED = function(event)
            self_pool:Drain()
        end
        self.module = ovale:createModule("OvaleDamageTaken", self.OnInitialize, self.OnDisable, aceEvent)
        self.profiler = profiler:create(self.module:GetName())
        self.tracer = ovaleDebug:create(self.module:GetName())
    end,
    AddDamageTaken = function(self, timestamp, damage, isMagicDamage)
        self.profiler:StartProfiling("OvaleDamageTaken_AddDamageTaken")
        local event = self_pool:Get()
        event.timestamp = timestamp
        event.damage = damage
        event.magic = isMagicDamage
        self.damageEvent:InsertFront(event)
        self:RemoveExpiredEvents(timestamp)
        self.ovale:needRefresh()
        self.profiler:StopProfiling("OvaleDamageTaken_AddDamageTaken")
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
        self.profiler:StartProfiling("OvaleDamageTaken_RemoveExpiredEvents")
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
                self.ovale:needRefresh()
            end
        end
        self.profiler:StopProfiling("OvaleDamageTaken_RemoveExpiredEvents")
    end,
    DebugDamageTaken = function(self)
        self.tracer:Print(self.damageEvent:DebuggingInfo())
        local iterator = self.damageEvent:BackToFrontIterator()
        while iterator:Next() do
            local event = iterator.value
            self.tracer:Print("%d: %d damage", event.timestamp, event.damage)
        end
    end,
})
