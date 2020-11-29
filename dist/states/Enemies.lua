local __exports = LibStub:NewLibrary("ovale/states/Enemies", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local aceTimer = LibStub:GetLibrary("AceTimer-3.0", true)
local band = bit.band
local bor = bit.bor
local ipairs = ipairs
local pairs = pairs
local wipe = wipe
local find = string.find
local GetTime = GetTime
local COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE
local COMBATLOG_OBJECT_AFFILIATION_PARTY = COMBATLOG_OBJECT_AFFILIATION_PARTY
local COMBATLOG_OBJECT_AFFILIATION_RAID = COMBATLOG_OBJECT_AFFILIATION_RAID
local COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local __engineState = LibStub:GetLibrary("ovale/engine/State")
local States = __engineState.States
local GROUP_MEMBER = bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)
local CLEU_TAG_SUFFIXES = {
    [1] = "_DAMAGE",
    [2] = "_MISSED",
    [3] = "_AURA_APPLIED",
    [4] = "_AURA_APPLIED_DOSE",
    [5] = "_AURA_REFRESH",
    [6] = "_CAST_START",
    [7] = "_INTERRUPT",
    [8] = "_DISPEL",
    [9] = "_DISPEL_FAILED",
    [10] = "_STOLEN",
    [11] = "_DRAIN",
    [12] = "_LEECH"
}
local CLEU_AUTOATTACK = {
    RANGED_DAMAGE = true,
    RANGED_MISSED = true,
    SWING_DAMAGE = true,
    SWING_MISSED = true
}
local CLEU_UNIT_REMOVED = {
    UNIT_DESTROYED = true,
    UNIT_DIED = true,
    UNIT_DISSIPATES = true
}
local self_enemyName = {}
local self_enemyLastSeen = {}
local self_taggedEnemyLastSeen = {}
local self_reaperTimer = nil
local REAP_INTERVAL = 3
local IsTagEvent = function(cleuEvent)
    local isTagEvent = false
    if CLEU_AUTOATTACK[cleuEvent] then
        isTagEvent = true
    else
        for _, suffix in ipairs(CLEU_TAG_SUFFIXES) do
            if find(cleuEvent, suffix .. "$") then
                isTagEvent = true
                break
            end
        end
    end
    return isTagEvent
end

local IsFriendly = function(unitFlags, isGroupMember)
    return (band(unitFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 and ( not isGroupMember or band(unitFlags, GROUP_MEMBER) > 0))
end

local EnemiesData = __class(nil, {
    constructor = function(self)
        self.activeEnemies = 0
        self.taggedEnemies = 0
        self.enemies = nil
    end
})
__exports.OvaleEnemiesClass = __class(States, {
    constructor = function(self, ovaleGuid, ovale, ovaleProfiler, ovaleDebug)
        self.ovaleGuid = ovaleGuid
        self.ovale = ovale
        self.OnInitialize = function()
            if  not self_reaperTimer then
                self_reaperTimer = self.module:ScheduleRepeatingTimer(self.RemoveInactiveEnemies, REAP_INTERVAL)
            end
            self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", self.COMBAT_LOG_EVENT_UNFILTERED)
            self.module:RegisterEvent("PLAYER_REGEN_DISABLED", self.PLAYER_REGEN_DISABLED)
        end
        self.OnDisable = function()
            if self_reaperTimer then
                self.module:CancelTimer(self_reaperTimer)
                self_reaperTimer = nil
            end
            self.module:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self.module:UnregisterEvent("PLAYER_REGEN_DISABLED")
        end
        self.COMBAT_LOG_EVENT_UNFILTERED = function(event, ...)
            local _, cleuEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags = CombatLogGetCurrentEventInfo()
            if CLEU_UNIT_REMOVED[cleuEvent] then
                local now = GetTime()
                self:RemoveEnemy(cleuEvent, destGUID, now, true)
            elseif sourceGUID and sourceGUID ~= "" and sourceName and sourceFlags and destGUID and destGUID ~= "" and destName and destFlags then
                if  not IsFriendly(sourceFlags) and IsFriendly(destFlags, true) then
                    if  not (cleuEvent == "SPELL_PERIODIC_DAMAGE" and IsTagEvent(cleuEvent)) then
                        local now = GetTime()
                        self:AddEnemy(cleuEvent, sourceGUID, sourceName, now)
                    end
                elseif IsFriendly(sourceFlags, true) and  not IsFriendly(destFlags) and IsTagEvent(cleuEvent) then
                    local now = GetTime()
                    local isPlayerTag
                    if sourceGUID == self.ovale.playerGUID then
                        isPlayerTag = true
                    else
                        isPlayerTag = self.ovaleGuid:IsPlayerPet(sourceGUID)
                    end
                    self:AddEnemy(cleuEvent, destGUID, destName, now, isPlayerTag)
                end
            end
        end
        self.PLAYER_REGEN_DISABLED = function()
            wipe(self_enemyName)
            wipe(self_enemyLastSeen)
            wipe(self_taggedEnemyLastSeen)
            self.current.activeEnemies = 0
            self.current.taggedEnemies = 0
        end
        self.RemoveInactiveEnemies = function()
            self.profiler:StartProfiling("OvaleEnemies_RemoveInactiveEnemies")
            local now = GetTime()
            for guid, timestamp in pairs(self_enemyLastSeen) do
                if now - timestamp > REAP_INTERVAL then
                    self:RemoveEnemy("REAPED", guid, now)
                end
            end
            for guid, timestamp in pairs(self_taggedEnemyLastSeen) do
                if now - timestamp > REAP_INTERVAL then
                    self:RemoveTaggedEnemy("REAPED", guid, now)
                end
            end
            self.profiler:StopProfiling("OvaleEnemies_RemoveInactiveEnemies")
        end
        States.constructor(self, EnemiesData)
        self.module = ovale:createModule("OvaleEnemies", self.OnInitialize, self.OnDisable, aceEvent, aceTimer)
        self.profiler = ovaleProfiler:create(self.module:GetName())
        self.tracer = ovaleDebug:create(self.module:GetName())
    end,
    AddEnemy = function(self, cleuEvent, guid, name, timestamp, isTagged)
        self.profiler:StartProfiling("OvaleEnemies_AddEnemy")
        if guid then
            self_enemyName[guid] = name
            local changed = false
            do
                if  not self_enemyLastSeen[guid] then
                    self.current.activeEnemies = self.current.activeEnemies + 1
                    changed = true
                end
                self_enemyLastSeen[guid] = timestamp
            end
            if isTagged then
                if  not self_taggedEnemyLastSeen[guid] then
                    self.current.taggedEnemies = self.current.taggedEnemies + 1
                    changed = true
                end
                self_taggedEnemyLastSeen[guid] = timestamp
            end
            if changed then
                self.tracer:DebugTimestamp("%s: %d/%d enemy seen: %s (%s)", cleuEvent, self.current.taggedEnemies, self.current.activeEnemies, guid, name)
                self.ovale:needRefresh()
            end
        end
        self.profiler:StopProfiling("OvaleEnemies_AddEnemy")
    end,
    RemoveEnemy = function(self, cleuEvent, guid, timestamp, isDead)
        self.profiler:StartProfiling("OvaleEnemies_RemoveEnemy")
        if guid then
            local name = self_enemyName[guid]
            local changed = false
            if self_enemyLastSeen[guid] then
                self_enemyLastSeen[guid] = nil
                if self.current.activeEnemies > 0 then
                    self.current.activeEnemies = self.current.activeEnemies - 1
                    changed = true
                end
            end
            if self_taggedEnemyLastSeen[guid] then
                self_taggedEnemyLastSeen[guid] = nil
                if self.current.taggedEnemies > 0 then
                    self.current.taggedEnemies = self.current.taggedEnemies - 1
                    changed = true
                end
            end
            if changed then
                self.tracer:DebugTimestamp("%s: %d/%d enemy %s: %s (%s)", cleuEvent, self.current.taggedEnemies, self.current.activeEnemies, (isDead and "died") or "removed", guid, name)
                self.ovale:needRefresh()
                self.module:SendMessage("Ovale_InactiveUnit", guid, isDead)
            end
        end
        self.profiler:StopProfiling("OvaleEnemies_RemoveEnemy")
    end,
    RemoveTaggedEnemy = function(self, cleuEvent, guid, timestamp)
        self.profiler:StartProfiling("OvaleEnemies_RemoveTaggedEnemy")
        if guid then
            local name = self_enemyName[guid]
            local tagged = self_taggedEnemyLastSeen[guid]
            if tagged then
                self_taggedEnemyLastSeen[guid] = nil
                if self.current.taggedEnemies > 0 then
                    self.current.taggedEnemies = self.current.taggedEnemies - 1
                end
                self.tracer:DebugTimestamp("%s: %d/%d enemy removed: %s (%s), last tagged at %f", cleuEvent, self.current.taggedEnemies, self.current.activeEnemies, guid, name, tagged)
                self.ovale:needRefresh()
            end
        end
        self.profiler:StopProfiling("OvaleEnemies_RemoveTaggedEnemy")
    end,
    DebugEnemies = function(self)
        for guid, seen in pairs(self_enemyLastSeen) do
            local name = self_enemyName[guid]
            local tagged = self_taggedEnemyLastSeen[guid]
            if tagged then
                self.tracer:Print("Tagged enemy %s (%s) last seen at %f", guid, name, tagged)
            else
                self.tracer:Print("Enemy %s (%s) last seen at %f", guid, name, seen)
            end
        end
        self.tracer:Print("Total enemies: %d", self.current.activeEnemies)
        self.tracer:Print("Total tagged enemies: %d", self.current.taggedEnemies)
    end,
    InitializeState = function(self)
        self.next.enemies = nil
    end,
    ResetState = function(self)
        self.profiler:StartProfiling("OvaleEnemies_ResetState")
        self.next.activeEnemies = self.current.activeEnemies
        self.next.taggedEnemies = self.current.taggedEnemies
        self.profiler:StopProfiling("OvaleEnemies_ResetState")
    end,
    CleanState = function(self)
        self.next.activeEnemies = 0
        self.next.taggedEnemies = 0
        self.next.enemies = nil
    end,
})
