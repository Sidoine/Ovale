local __exports = LibStub:NewLibrary("ovale/Future", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
local __GUID = LibStub:GetLibrary("ovale/GUID")
local OvaleGUID = __GUID.OvaleGUID
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local __LastSpell = LibStub:GetLibrary("ovale/LastSpell")
local lastSpell = __LastSpell.lastSpell
local self_pool = __LastSpell.self_pool
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ipairs = ipairs
local pairs = pairs
local type = type
local wipe = wipe
local sub = string.sub
local insert = table.insert
local remove = table.remove
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __Cooldown = LibStub:GetLibrary("ovale/Cooldown")
local OvaleCooldown = __Cooldown.OvaleCooldown
local __Stance = LibStub:GetLibrary("ovale/Stance")
local OvaleStance = __Stance.OvaleStance
local __BaseState = LibStub:GetLibrary("ovale/BaseState")
local baseState = __BaseState.baseState
local strsub = sub
local tremove = remove
local self_timeAuraAdded = nil
local CLEU_AURA_EVENT = {
    SPELL_AURA_APPLIED = "hit",
    SPELL_AURA_APPLIED_DOSE = "hit",
    SPELL_AURA_BROKEN = "hit",
    SPELL_AURA_BROKEN_SPELL = "hit",
    SPELL_AURA_REFRESH = "hit",
    SPELL_AURA_REMOVED = "hit",
    SPELL_AURA_REMOVED_DOSE = "hit"
}
local CLEU_SPELLCAST_FINISH_EVENT = {
    SPELL_DAMAGE = "hit",
    SPELL_DISPEL = "hit",
    SPELL_DISPEL_FAILED = "miss",
    SPELL_HEAL = "hit",
    SPELL_INTERRUPT = "hit",
    SPELL_MISSED = "miss",
    SPELL_STOLEN = "hit"
}
local CLEU_SPELLCAST_EVENT = {
    SPELL_CAST_FAILED = true,
    SPELL_CAST_START = true,
    SPELL_CAST_SUCCESS = true
}
do
    for cleuEvent, v in pairs(CLEU_AURA_EVENT) do
        CLEU_SPELLCAST_FINISH_EVENT[cleuEvent] = v
    end
    for cleuEvent in pairs(CLEU_SPELLCAST_FINISH_EVENT) do
        CLEU_SPELLCAST_EVENT[cleuEvent] = true
    end
end
local SPELLCAST_AURA_ORDER = {
    [1] = "target",
    [2] = "pet"
}
local SPELLAURALIST_AURA_VALUE = {
    count = true,
    extend = true,
    refresh = true,
    refresh_keep_snapshot = true
}
local WHITE_ATTACK = {
    [75] = true,
    [5019] = true,
    [6603] = true
}
local WHITE_ATTACK_NAME = {}
do
    for spellId in pairs(WHITE_ATTACK) do
        local name = GetSpellInfo(spellId)
        if name then
            WHITE_ATTACK_NAME[name] = true
        end
    end
end
local IsSameSpellcast = function(a, b)
    local boolean = (a.spellId == b.spellId and a.queued == b.queued)
    if boolean then
        if a.channel or b.channel then
            if a.channel ~= b.channel then
                boolean = false
            end
        elseif a.lineId ~= b.lineId then
            boolean = false
        end
    end
    return boolean
end

local eventDebug = false
__exports.OvaleFutureData = __class(nil, {
    PushGCDSpellId = function(self, spellId)
        if self.lastGCDSpellId then
            insert(self.lastGCDSpellIds, self.lastGCDSpellId)
            if #self.lastGCDSpellIds > 5 then
                remove(self.lastGCDSpellIds, 1)
            end
        end
        self.lastGCDSpellId = spellId
    end,
    UpdateCounters = function(self, spellId, atTime, targetGUID)
        local inccounter = OvaleData:GetSpellInfoProperty(spellId, atTime, "inccounter", targetGUID)
        if inccounter then
            local value = self.counter[inccounter] and self.counter[inccounter] or 0
            self.counter[inccounter] = value + 1
        end
        local resetcounter = OvaleData:GetSpellInfoProperty(spellId, atTime, "resetcounter", targetGUID)
        if resetcounter then
            self.counter[resetcounter] = 0
        end
    end,
    GetCounter = function(self, id)
        return self.counter[id] or 0
    end,
    IsChanneling = function(self, atTime)
        return self.currentCast.channel and (atTime < self.currentCast.stop)
    end,
    constructor = function(self)
        self.lastCastTime = {}
        self.lastOffGCDSpellcast = {}
        self.lastGCDSpellcast = {}
        self.lastGCDSpellIds = {}
        self.counter = {}
        self.lastCast = {}
        self.currentCast = {}
    end
})
local OvaleFutureBase = OvaleState:RegisterHasState(OvaleProfiler:RegisterProfiling(OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleFuture", aceEvent))), __exports.OvaleFutureData)
__exports.OvaleFutureClass = __class(OvaleFutureBase, {
    constructor = function(self)
        OvaleFutureBase.constructor(self)
        OvaleState:RegisterState(self)
    end,
    OnInitialize = function(self)
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
        self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
        self:RegisterEvent("UNIT_SPELLCAST_FAILED", "UnitSpellcastEnded")
        self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET", "UnitSpellcastEnded")
        self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "UnitSpellcastEnded")
        self:RegisterEvent("UNIT_SPELLCAST_SENT")
        self:RegisterEvent("UNIT_SPELLCAST_START")
        self:RegisterEvent("UNIT_SPELLCAST_STOP", "UnitSpellcastEnded")
        self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        self:RegisterMessage("Ovale_AuraAdded")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("PLAYER_REGEN_DISABLED")
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
        self:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
        self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
        self:UnregisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
        self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        self:UnregisterEvent("UNIT_SPELLCAST_SENT")
        self:UnregisterEvent("UNIT_SPELLCAST_START")
        self:UnregisterEvent("UNIT_SPELLCAST_STOP")
        self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        self:UnregisterMessage("Ovale_AuraAdded")
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, arg13, _, _, _, _, _, _, _, _, _, _, arg24, arg25 = ...
        if sourceGUID == Ovale.playerGUID or OvaleGUID:IsPlayerPet(sourceGUID) then
            self:StartProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED")
            if CLEU_SPELLCAST_EVENT[cleuEvent] then
                local now = GetTime()
                local spellId, spellName = arg12, arg13
                local eventDebug = false
                local delta = 0
                if strsub(cleuEvent, 1, 11) == "SPELL_CAST_" and (destName and destName ~= "") then
                    if  not eventDebug then
                        self:DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName)
                        eventDebug = true
                    end
                    local spellcast = self:GetSpellcast(spellName, spellId, nil, now)
                    if spellcast and spellcast.targetName and spellcast.targetName == destName and spellcast.target ~= destGUID then
                        self:Debug("Disambiguating target of spell %s (%d) to %s (%s).", spellName, spellId, destName, destGUID)
                        spellcast.target = destGUID
                    end
                end
                local finish = CLEU_SPELLCAST_FINISH_EVENT[cleuEvent]
                if cleuEvent == "SPELL_DAMAGE" or cleuEvent == "SPELL_HEAL" then
                    local isOffHand, multistrike = arg24, arg25
                    if isOffHand or multistrike then
                        finish = nil
                    end
                end
                if finish then
                    local anyFinished = false
                    for i = #lastSpell.queue, 1, -1 do
                        local spellcast = lastSpell.queue[i]
                        if spellcast.success and (spellcast.spellId == spellId or spellcast.auraId == spellId) then
                            if self:FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i) then
                                anyFinished = true
                            end
                        end
                    end
                    if  not anyFinished then
                        self:Debug("Found no spell to finish for %s (%d)", spellName, spellId)
                        for i = #lastSpell.queue, 1, -1 do
                            local spellcast = lastSpell.queue[i]
                            if spellcast.success and (spellcast.spellName == spellName) then
                                if self:FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i) then
                                    anyFinished = true
                                end
                            end
                        end
                        if  not anyFinished then
                            self:Debug("No spell found for %s", spellName, spellId)
                        end
                    end
                end
            end
            self:StopProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    FinishSpell = function(self, spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, delta, finish, i)
        local finished = false
        if  not spellcast.auraId then
            if  not eventDebug then
                self:DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName)
                eventDebug = true
            end
            if  not spellcast.channel then
                self:Debug("Finished (%s) spell %s (%d) queued at %s due to %s.", finish, spellName, spellId, spellcast.queued, cleuEvent)
                finished = true
            end
        elseif CLEU_AURA_EVENT[cleuEvent] and spellcast.auraGUID and destGUID == spellcast.auraGUID then
            if  not eventDebug then
                self:DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName)
                eventDebug = true
            end
            self:Debug("Finished (%s) spell %s (%d) queued at %s after seeing aura %d on %s.", finish, spellName, spellId, spellcast.queued, spellcast.auraId, spellcast.auraGUID)
            finished = true
        end
        if finished then
            local now = GetTime()
            if self_timeAuraAdded then
                if IsSameSpellcast(spellcast, lastSpell.lastGCDSpellcast) then
                    self:UpdateSpellcastSnapshot(lastSpell.lastGCDSpellcast, self_timeAuraAdded)
                end
                if IsSameSpellcast(spellcast, self.current.lastOffGCDSpellcast) then
                    self:UpdateSpellcastSnapshot(self.current.lastOffGCDSpellcast, self_timeAuraAdded)
                end
            end
            local delta = now - spellcast.stop
            local targetGUID = spellcast.target
            self:Debug("Spell %s (%d) was in flight for %f seconds.", spellName, spellId, delta)
            tremove(lastSpell.queue, i)
            self_pool:Release(spellcast)
            Ovale:needRefresh()
            self:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish)
        end
        return finished
    end,
    PLAYER_ENTERING_WORLD = function(self, event)
        self:StartProfiling("OvaleFuture_PLAYER_ENTERING_WORLD")
        self:Debug(event)
        self:StopProfiling("OvaleFuture_PLAYER_ENTERING_WORLD")
    end,
    PLAYER_REGEN_DISABLED = function(self, event)
        self:StartProfiling("OvaleFuture_PLAYER_REGEN_DISABLED")
        self:Debug(event, "Entering combat.")
        local now = GetTime()
        baseState.current.inCombat = true
        baseState.current.combatStartTime = now
        Ovale:needRefresh()
        self:SendMessage("Ovale_CombatStarted", now)
        self:StopProfiling("OvaleFuture_PLAYER_REGEN_DISABLED")
    end,
    PLAYER_REGEN_ENABLED = function(self, event)
        self:StartProfiling("OvaleFuture_PLAYER_REGEN_ENABLED")
        self:Debug(event, "Leaving combat.")
        local now = GetTime()
        baseState.current.inCombat = false
        Ovale:needRefresh()
        self:SendMessage("Ovale_CombatEnded", now)
        self:StopProfiling("OvaleFuture_PLAYER_REGEN_ENABLED")
    end,
    UNIT_SPELLCAST_CHANNEL_START = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_START")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = GetTime()
            local spellcast = self:GetSpellcast(spell, spellId, nil, now)
            if spellcast then
                local name, _, _, _, startTime, endTime = UnitChannelInfo(unitId)
                if name == spell then
                    startTime = startTime / 1000
                    endTime = endTime / 1000
                    spellcast.channel = true
                    spellcast.spellId = spellId
                    spellcast.success = now
                    spellcast.start = startTime
                    spellcast.stop = endTime
                    local delta = now - spellcast.queued
                    self:Debug("Channelling spell %s (%d): start = %s (+%s), ending = %s", spell, spellId, startTime, delta, endTime)
                    self:SaveSpellcastInfo(spellcast, now)
                    self:UpdateLastSpellcast(now, spellcast)
                    self:UpdateCounters(spellId, spellcast.start, spellcast.target)
                    Ovale:needRefresh()
                elseif  not name then
                    self:Debug("Warning: not channelling a spell.")
                else
                    self:Debug("Warning: channelling unexpected spell %s", name)
                end
            else
                self:Debug("Warning: channelling spell %s (%d) without previous UNIT_SPELLCAST_SENT.", spell, spellId)
            end
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_START")
        end
    end,
    UNIT_SPELLCAST_CHANNEL_STOP = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_STOP")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = GetTime()
            local spellcast, index = self:GetSpellcast(spell, spellId, nil, now)
            if spellcast and spellcast.channel then
                self:Debug("Finished channelling spell %s (%d) queued at %s.", spell, spellId, spellcast.queued)
                spellcast.stop = now
                self:UpdateLastSpellcast(now, spellcast)
                local targetGUID = spellcast.target
                tremove(lastSpell.queue, index)
                self_pool:Release(spellcast)
                Ovale:needRefresh()
                self:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, "hit")
            end
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_STOP")
        end
    end,
    UNIT_SPELLCAST_CHANNEL_UPDATE = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_UPDATE")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = GetTime()
            local spellcast = self:GetSpellcast(spell, spellId, nil, now)
            if spellcast and spellcast.channel then
                local name, _, _, _, startTime, endTime = UnitChannelInfo(unitId)
                if name == spell then
                    startTime = startTime / 1000
                    endTime = endTime / 1000
                    local delta = endTime - spellcast.stop
                    spellcast.start = startTime
                    spellcast.stop = endTime
                    self:Debug("Updating channelled spell %s (%d) to ending = %s (+%s).", spell, spellId, endTime, delta)
                    Ovale:needRefresh()
                elseif  not name then
                    self:Debug("Warning: not channelling a spell.")
                else
                    self:Debug("Warning: delaying unexpected channelled spell %s.", name)
                end
            else
                self:Debug("Warning: no queued, channelled spell %s (%d) found to update.", spell, spellId)
            end
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_UPDATE")
        end
    end,
    UNIT_SPELLCAST_DELAYED = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_DELAYED")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = GetTime()
            local spellcast = self:GetSpellcast(spell, spellId, lineId, now)
            if spellcast then
                local name, _, _, _, startTime, endTime, _, castId = UnitCastingInfo(unitId)
                if lineId == castId and name == spell then
                    startTime = startTime / 1000
                    endTime = endTime / 1000
                    local delta = endTime - spellcast.stop
                    spellcast.start = startTime
                    spellcast.stop = endTime
                    self:Debug("Delaying spell %s (%d) to ending = %s (+%s).", spell, spellId, endTime, delta)
                    Ovale:needRefresh()
                elseif  not name then
                    self:Debug("Warning: not casting a spell.")
                else
                    self:Debug("Warning: delaying unexpected spell %s.", name)
                end
            else
                self:Debug("Warning: no queued spell %s (%d) found to delay.", spell, spellId)
            end
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_DELAYED")
        end
    end,
    UNIT_SPELLCAST_SENT = function(self, event, unitId, spell, rank, targetName, lineId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK_NAME[spell] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_SENT")
            self:DebugTimestamp(event, unitId, spell, rank, targetName, lineId)
            local now = GetTime()
            local caster = OvaleGUID:UnitGUID(unitId)
            local spellcast = self_pool:Get()
            spellcast.lineId = lineId
            spellcast.caster = caster
            spellcast.spellName = spell
            spellcast.queued = now
            insert(lastSpell.queue, spellcast)
            if targetName == "" then
                self:Debug("Queueing (%d) spell %s with no target.", #lastSpell.queue, spell)
            else
                spellcast.targetName = targetName
                local targetGUID, nextGUID = OvaleGUID:NameGUID(targetName)
                if nextGUID then
                    local name = OvaleGUID:UnitName("target")
                    if name == targetName then
                        targetGUID = OvaleGUID:UnitGUID("target")
                    else
                        name = OvaleGUID:UnitName("focus")
                        if name == targetName then
                            targetGUID = OvaleGUID:UnitGUID("focus")
                        elseif UnitExists("mouseover") then
                            name = UnitName("mouseover")
                            if name == targetName then
                                targetGUID = UnitGUID("mouseover")
                            end
                        end
                    end
                    spellcast.target = targetGUID
                    self:Debug("Queueing (%d) spell %s to %s (possibly %s).", #lastSpell.queue, spell, targetName, targetGUID)
                else
                    spellcast.target = targetGUID
                    self:Debug("Queueing (%d) spell %s to %s (%s).", #lastSpell.queue, spell, targetName, targetGUID)
                end
            end
            self:SaveSpellcastInfo(spellcast, now)
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_SENT")
        end
    end,
    UNIT_SPELLCAST_START = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_START")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = GetTime()
            local spellcast = self:GetSpellcast(spell, spellId, lineId, now)
            if spellcast then
                local name, _, _, _, startTime, endTime, _, castId = UnitCastingInfo(unitId)
                if lineId == castId and name == spell then
                    startTime = startTime / 1000
                    endTime = endTime / 1000
                    spellcast.spellId = spellId
                    spellcast.start = startTime
                    spellcast.stop = endTime
                    spellcast.channel = false
                    local delta = now - spellcast.queued
                    self:Debug("Casting spell %s (%d): start = %s (+%s), ending = %s.", spell, spellId, startTime, delta, endTime)
                    local auraId, auraGUID = self:GetAuraFinish(spell, spellId, spellcast.target, now)
                    if auraId and auraGUID then
                        spellcast.auraId = auraId
                        spellcast.auraGUID = auraGUID
                        self:Debug("Spell %s (%d) will finish after updating aura %d on %s.", spell, spellId, auraId, auraGUID)
                    end
                    self:SaveSpellcastInfo(spellcast, now)
                    Ovale:needRefresh()
                elseif  not name then
                    self:Debug("Warning: not casting a spell.")
                else
                    self:Debug("Warning: casting unexpected spell %s.", name)
                end
            else
                self:Debug("Warning: casting spell %s (%d) without previous sent data.", spell, spellId)
            end
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_START")
        end
    end,
    UNIT_SPELLCAST_SUCCEEDED = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = GetTime()
            local spellcast, index = self:GetSpellcast(spell, spellId, lineId, now)
            if spellcast then
                local success = false
                if  not spellcast.success and spellcast.start and spellcast.stop and  not spellcast.channel then
                    self:Debug("Succeeded casting spell %s (%d) at %s, now in flight.", spell, spellId, spellcast.stop)
                    spellcast.success = now
                    self:UpdateSpellcastSnapshot(spellcast, now)
                    success = true
                else
                    local name = UnitChannelInfo(unitId)
                    if  not name then
                        local now = GetTime()
                        spellcast.spellId = spellId
                        spellcast.start = now
                        spellcast.stop = now
                        spellcast.channel = false
                        spellcast.success = now
                        local delta = now - spellcast.queued
                        self:Debug("Instant-cast spell %s (%d): start = %s (+%s).", spell, spellId, now, delta)
                        local auraId, auraGUID = self:GetAuraFinish(spell, spellId, spellcast.target, now)
                        if auraId and auraGUID then
                            spellcast.auraId = auraId
                            spellcast.auraGUID = auraGUID
                            self:Debug("Spell %s (%d) will finish after updating aura %d on %s.", spell, spellId, auraId, auraGUID)
                        end
                        self:SaveSpellcastInfo(spellcast, now)
                        success = true
                    else
                        self:Debug("Succeeded casting spell %s (%d) but it is channelled.", spell, spellId)
                    end
                end
                if success then
                    local targetGUID = spellcast.target
                    self:UpdateLastSpellcast(now, spellcast)
                    self:UpdateCounters(spellId, spellcast.stop, targetGUID)
                    local finished = false
                    local finish = "miss"
                    if  not spellcast.targetName then
                        self:Debug("Finished spell %s (%d) with no target queued at %s.", spell, spellId, spellcast.queued)
                        finished = true
                        finish = "hit"
                    elseif targetGUID == Ovale.playerGUID and OvaleSpellBook:IsHelpfulSpell(spellId) then
                        self:Debug("Finished helpful spell %s (%d) cast on player queued at %s.", spell, spellId, spellcast.queued)
                        finished = true
                        finish = "hit"
                    end
                    if finished then
                        tremove(lastSpell.queue, index)
                        self_pool:Release(spellcast)
                        Ovale:needRefresh()
                        self:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish)
                    end
                end
            else
                self:Debug("Warning: no queued spell %s (%d) found to successfully complete casting.", spell, spellId)
            end
            self:StopProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED")
        end
    end,
    Ovale_AuraAdded = function(self, event, atTime, guid, auraId, caster)
        if guid == Ovale.playerGUID then
            self_timeAuraAdded = atTime
            self:UpdateSpellcastSnapshot(lastSpell.lastGCDSpellcast, atTime)
            self:UpdateSpellcastSnapshot(self.current.lastOffGCDSpellcast, atTime)
        end
    end,
    UnitSpellcastEnded = function(self, event, unitId, spell, rank, lineId, spellId)
        if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
            self:StartProfiling("OvaleFuture_UnitSpellcastEnded")
            self:DebugTimestamp(event, unitId, spell, rank, lineId, spellId)
            local now = GetTime()
            local spellcast, index = self:GetSpellcast(spell, spellId, lineId, now)
            if spellcast then
                self:Debug("End casting spell %s (%d) queued at %s due to %s.", spell, spellId, spellcast.queued, event)
                if  not spellcast.success then
                    self:Debug("Remove spell from queue because there was no success before")
                    tremove(lastSpell.queue, index)
                    self_pool:Release(spellcast)
                    Ovale:needRefresh()
                end
            elseif lineId then
                self:Debug("Warning: no queued spell %s (%d) found to end casting.", spell, spellId)
            end
            self:StopProfiling("OvaleFuture_UnitSpellcastEnded")
        end
    end,
    GetSpellcast = function(self, spell, spellId, lineId, atTime)
        self:StartProfiling("OvaleFuture_GetSpellcast")
        local spellcast, index
        if  not lineId or lineId ~= "" then
            for i, sc in ipairs(lastSpell.queue) do
                if  not lineId or sc.lineId == lineId then
                    if spellId and sc.spellId == spellId then
                        spellcast = sc
                        index = i
                        break
                    elseif spell then
                        local spellName = sc.spellName or OvaleSpellBook:GetSpellName(spellId)
                        if spell == spellName then
                            spellcast = sc
                            index = i
                            break
                        end
                    end
                end
            end
        end
        if spellcast then
            local spellName = spell or spellcast.spellName or OvaleSpellBook:GetSpellName(spellId)
            if spellcast.targetName then
                self:Debug("Found spellcast for %s to %s queued at %f.", spellName, spellcast.targetName, spellcast.queued)
            else
                self:Debug("Found spellcast for %s with no target queued at %f.", spellName, spellcast.queued)
            end
        end
        self:StopProfiling("OvaleFuture_GetSpellcast")
        return spellcast, index
    end,
    GetAuraFinish = function(self, spell, spellId, targetGUID, atTime)
        self:StartProfiling("OvaleFuture_GetAuraFinish")
        local auraId, auraGUID
        local si = OvaleData.spellInfo[spellId]
        if si and si.aura then
            for _, unitId in ipairs(SPELLCAST_AURA_ORDER) do
                for _, auraList in pairs(si.aura[unitId]) do
                    for id, spellData in pairs(auraList) do
                        local verified, value = OvaleData:CheckSpellAuraData(id, spellData, atTime, targetGUID)
                        if verified and (SPELLAURALIST_AURA_VALUE[value] or type(value) == "number" and value > 0) then
                            auraId = id
                            auraGUID = OvaleGUID:UnitGUID(unitId)
                            break
                        end
                    end
                    if auraId then
                        break
                    end
                end
                if auraId then
                    break
                end
            end
        end
        self:StopProfiling("OvaleFuture_GetAuraFinish")
        return auraId, auraGUID
    end,
    SaveSpellcastInfo = function(self, spellcast, atTime)
        self:StartProfiling("OvaleFuture_SaveSpellcastInfo")
        self:Debug("    Saving information from %s to the spellcast for %s.", atTime, spellcast.spellName)
        if spellcast.spellId then
            spellcast.damageMultiplier = self:GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime)
        end
        for _, mod in pairs(lastSpell.modules) do
            local func = mod.SaveSpellcastInfo
            if func then
                func(mod, spellcast, atTime)
            end
        end
        self:StopProfiling("OvaleFuture_SaveSpellcastInfo")
    end,
    GetDamageMultiplier = function(self, spellId, targetGUID, atTime)
        atTime = atTime or self["currentTime"] or GetTime()
        local damageMultiplier = 1
        local si = OvaleData.spellInfo[spellId]
        if si and si.aura and si.aura.damage then
            local CheckRequirements
            for filter, auraList in pairs(si.aura.damage) do
                for auraId, spellData in pairs(auraList) do
                    local index, multiplier
                    if type(spellData) == "table" then
                        multiplier = spellData[1]
                        index = 2
                    else
                        multiplier = spellData
                    end
                    local verified
                    if index then
                        verified = CheckRequirements(spellId, atTime, spellData, index, targetGUID)
                    else
                        verified = true
                    end
                    if verified then
                        local aura = OvaleAura:GetAuraByGUID(Ovale.playerGUID, auraId, filter, false, atTime)
                        local isActiveAura = OvaleAura:IsActiveAura(aura, atTime)
                        if isActiveAura then
                            local siAura = OvaleData.spellInfo[auraId]
                            if siAura and siAura.stacking and siAura.stacking > 0 then
                                multiplier = 1 + (multiplier - 1) * aura.stacks
                            end
                            damageMultiplier = damageMultiplier * multiplier
                        end
                    end
                end
            end
        end
        return damageMultiplier
    end,
    UpdateCounters = function(self, spellId, atTime, targetGUID)
        return self:GetState(atTime):UpdateCounters(spellId, atTime, targetGUID)
    end,
    IsActive = function(self, spellId)
        for _, spellcast in ipairs(lastSpell.queue) do
            if spellcast.spellId == spellId and spellcast.start then
                return true
            end
        end
        return false
    end,
    InFlight = function(self, spellId)
        return self:IsActive(spellId)
    end,
    UpdateLastSpellcast = function(self, atTime, spellcast)
        self:StartProfiling("OvaleFuture_UpdateLastSpellcast")
        self.current.lastCastTime[spellcast.spellId] = atTime
        if spellcast.offgcd then
            self:Debug("    Caching spell %s (%d) as most recent off-GCD spellcast.", spellcast.spellName, spellcast.spellId)
            for k, v in pairs(spellcast) do
                self.current.lastOffGCDSpellcast[k] = v
            end
            lastSpell.lastSpellcast = self.current.lastOffGCDSpellcast
        else
            self:Debug("    Caching spell %s (%d) as most recent GCD spellcast.", spellcast.spellName, spellcast.spellId)
            for k, v in pairs(spellcast) do
                lastSpell.lastGCDSpellcast[k] = v
            end
            lastSpell.lastSpellcast = lastSpell.lastGCDSpellcast
        end
        self:StopProfiling("OvaleFuture_UpdateLastSpellcast")
    end,
    UpdateSpellcastSnapshot = function(self, spellcast, atTime)
        if spellcast.queued and ( not spellcast.snapshotTime or (spellcast.snapshotTime < atTime and atTime < spellcast.stop + 1)) then
            if spellcast.targetName then
                self:Debug("    Updating to snapshot from %s for spell %s to %s (%s) queued at %s.", atTime, spellcast.spellName, spellcast.targetName, spellcast.target, spellcast.queued)
            else
                self:Debug("    Updating to snapshot from %s for spell %s with no target queued at %s.", atTime, spellcast.spellName, spellcast.queued)
            end
            OvalePaperDoll:UpdateSnapshot(spellcast, OvalePaperDoll.current, true)
            if spellcast.spellId then
                spellcast.damageMultiplier = self:GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime)
                if spellcast.damageMultiplier ~= 1 then
                    self:Debug("        persistent multiplier = %f", spellcast.damageMultiplier)
                end
            end
        end
    end,
    GetCounter = function(self, id, atTime)
        return self:GetState(atTime).counter[id] or 0
    end,
    TimeOfLastCast = function(self, spellId, atTime)
        if  not atTime then
            return self.current.lastCastTime[spellId]
        end
        return self.next.lastCastTime[spellId] or self.current.lastCastTime[spellId] or 0
    end,
    IsChanneling = function(self, atTime)
        return self:GetState(atTime):IsChanneling(atTime)
    end,
    GetCurrentCast = function(self, atTime)
        if atTime and self.next.currentCast and self.next.currentCast.start <= atTime and self.next.currentCast.stop >= atTime then
            return self.next.currentCast
        end
        for _, value in ipairs(lastSpell.queue) do
            if value.start and value.start <= atTime and ( not value.stop or value.stop >= atTime) then
                return value
            end
        end
    end,
    GetGCD = function(self, spellId, atTime, targetGUID)
        spellId = spellId or self.next.currentCast.spellId
        if  not atTime then
            if self.next.currentCast.stop and self.next.currentCast.stop > baseState.next.currentTime then
                atTime = self.next.currentCast.stop
            else
                atTime = baseState.next.currentTime or baseState.current.currentTime
            end
        end
        targetGUID = targetGUID or OvaleGUID:UnitGUID(baseState.next.defaultTarget)
        local gcd = spellId and OvaleData:GetSpellInfoProperty(spellId, atTime, "gcd", targetGUID)
        if  not gcd then
            local haste
            gcd, haste = OvaleCooldown:GetBaseGCD()
            if Ovale.playerClass == "MONK" and OvalePaperDoll:IsSpecialization("mistweaver") then
                gcd = 1.5
                haste = "spell"
            elseif Ovale.playerClass == "DRUID" then
                if OvaleStance:IsStance("druid_cat_form", atTime) then
                    gcd = 1
                    haste = false
                end
            end
            local gcdHaste = spellId and OvaleData:GetSpellInfoProperty(spellId, atTime, "gcd_haste", targetGUID)
            if gcdHaste then
                haste = gcdHaste
            else
                local siHaste = spellId and OvaleData:GetSpellInfoProperty(spellId, atTime, "haste", targetGUID)
                if siHaste then
                    haste = siHaste
                end
            end
            local multiplier = OvalePaperDoll:GetHasteMultiplier(haste, OvalePaperDoll.next)
            gcd = gcd / multiplier
            gcd = (gcd > 0.75) and gcd or 0.75
        end
        return gcd
    end,
    InitializeState = function(self)
        self.next.lastCast = {}
        self.next.counter = {}
    end,
    ResetState = function(self)
        __exports.OvaleFuture:StartProfiling("OvaleFuture_ResetState")
        local now = baseState.next.currentTime
        self:Log("Reset state with current time = %f", now)
        self.next.nextCast = now
        wipe(self.next.lastCast)
        wipe(__exports.OvaleFutureClass.staticSpellcast)
        self.next.currentCast = __exports.OvaleFutureClass.staticSpellcast
        local reason = ""
        local start, duration = OvaleCooldown:GetGlobalCooldown(now)
        if start and start > 0 then
            local ending = start + duration
            if self.next.nextCast < ending then
                self.next.nextCast = ending
                reason = " (waiting for GCD)"
            end
        end
        local lastGCDSpellcastFound, lastOffGCDSpellcastFound, lastSpellcastFound
        for i = #lastSpell.queue, 1, -1 do
            local spellcast = lastSpell.queue[i]
            if spellcast.spellId and spellcast.start then
                __exports.OvaleFuture:Log("    Found cast %d of spell %s (%d), start = %s, stop = %s.", i, spellcast.spellName, spellcast.spellId, spellcast.start, spellcast.stop)
                if  not lastSpellcastFound then
                    if spellcast.start and spellcast.stop and spellcast.start <= now and now < spellcast.stop then
                        self.next.currentCast = spellcast
                    end
                    lastSpellcastFound = true
                end
                if  not lastGCDSpellcastFound and  not spellcast.offgcd then
                    self.next:PushGCDSpellId(spellcast.spellId)
                    if spellcast.stop and self.next.nextCast < spellcast.stop then
                        self.next.nextCast = spellcast.stop
                        reason = " (waiting for spellcast)"
                    end
                    lastGCDSpellcastFound = true
                end
                if  not lastOffGCDSpellcastFound and spellcast.offgcd then
                    self.next.lastOffGCDSpellcast = spellcast
                    lastOffGCDSpellcastFound = true
                end
            end
            if lastGCDSpellcastFound and lastOffGCDSpellcastFound and lastSpellcastFound then
                break
            end
        end
        if  not lastSpellcastFound then
            local spellcast = lastSpell.lastSpellcast
            if spellcast then
                if spellcast.start and spellcast.stop and spellcast.start <= now and now < spellcast.stop then
                    self.next.currentCast = spellcast
                end
            end
        end
        if  not lastGCDSpellcastFound then
            local spellcast = lastSpell.lastGCDSpellcast
            if spellcast then
                self.next.lastGCDSpellcast = spellcast
                if spellcast.stop and self.next.nextCast < spellcast.stop then
                    self.next.nextCast = spellcast.stop
                    reason = " (waiting for spellcast)"
                end
            end
        end
        if  not lastOffGCDSpellcastFound then
            self.next.lastOffGCDSpellcast = self.current.lastOffGCDSpellcast
        end
        __exports.OvaleFuture:Log("    nextCast = %f%s", self.next.nextCast, reason)
        for k, v in pairs(self.current.counter) do
            self.next.counter[k] = v
        end
        __exports.OvaleFuture:StopProfiling("OvaleFuture_ResetState")
    end,
    CleanState = function(self)
        for k in pairs(self.next.lastCast) do
            self.next.lastCast[k] = nil
        end
        for k in pairs(self.next.counter) do
            self.next.counter[k] = nil
        end
    end,
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        __exports.OvaleFuture:StartProfiling("OvaleFuture_ApplySpellStartCast")
        if channel then
            __exports.OvaleFuture:UpdateCounters(spellId, startCast, targetGUID)
        end
        __exports.OvaleFuture:StopProfiling("OvaleFuture_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        __exports.OvaleFuture:StartProfiling("OvaleFuture_ApplySpellAfterCast")
        if  not channel then
            __exports.OvaleFuture:UpdateCounters(spellId, endCast, targetGUID)
        end
        __exports.OvaleFuture:StopProfiling("OvaleFuture_ApplySpellAfterCast")
    end,
    staticSpellcast = {},
    ApplySpell = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        __exports.OvaleFuture:StartProfiling("OvaleFuture_state_ApplySpell")
        if spellId then
            if  not targetGUID then
                targetGUID = Ovale.playerGUID
            end
            local castTime
            if startCast and endCast then
                castTime = endCast - startCast
            else
                castTime = OvaleSpellBook:GetCastTime(spellId) or 0
                startCast = startCast or self.next.nextCast
                endCast = endCast or (startCast + castTime)
            end
            if  not spellcast then
                spellcast = __exports.OvaleFutureClass.staticSpellcast
                wipe(spellcast)
                spellcast.caster = Ovale.playerGUID
                spellcast.spellId = spellId
                spellcast.spellName = OvaleSpellBook:GetSpellName(spellId)
                spellcast.target = targetGUID
                spellcast.targetName = OvaleGUID:GUIDName(targetGUID)
                spellcast.start = startCast
                spellcast.stop = endCast
                spellcast.channel = channel
                OvalePaperDoll:UpdateSnapshot(spellcast, OvalePaperDoll.next)
                local atTime = channel and startCast or endCast
                for _, mod in pairs(lastSpell.modules) do
                    local func = mod.SaveSpellcastInfo
                    if func then
                        func(mod, spellcast, atTime, OvalePaperDoll.next)
                    end
                end
            end
            self.next.currentCast = spellcast
            self.next.lastCast[spellId] = endCast
            local gcd = __exports.OvaleFuture:GetGCD(spellId, startCast, targetGUID)
            local nextCast = (castTime > gcd) and endCast or (startCast + gcd)
            if self.next.nextCast < nextCast then
                self.next.nextCast = nextCast
            end
            if gcd > 0 then
                self.next:PushGCDSpellId(spellId)
            else
                self.next.lastOffGCDSpellcast = self.next.currentCast
            end
            __exports.OvaleFuture:Log("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, baseState.next.currentTime, nextCast, endCast, targetGUID)
            if  not baseState.next.inCombat and OvaleSpellBook:IsHarmfulSpell(spellId) then
                baseState.next.inCombat = true
                if channel then
                    baseState.next.combatStartTime = startCast
                else
                    baseState.next.combatStartTime = endCast
                end
            end
            if startCast > baseState.next.currentTime then
                OvaleState:ApplySpellStartCast(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
            if endCast > baseState.next.currentTime then
                OvaleState:ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
            OvaleState:ApplySpellOnHit(spellId, targetGUID, startCast, endCast, channel, spellcast)
        end
        __exports.OvaleFuture:StopProfiling("OvaleFuture_state_ApplySpell")
    end,
    ApplyInFlightSpells = function(self)
        self:StartProfiling("OvaleFuture_ApplyInFlightSpells")
        local now = GetTime()
        local index = 1
        while index <= #lastSpell.queue do
            local spellcast = lastSpell.queue[index]
            if spellcast.stop then
                local isValid = false
                local description
                if now < spellcast.stop then
                    isValid = true
                    description = spellcast.channel and "channelling" or "being cast"
                elseif now < spellcast.stop + 5 then
                    isValid = true
                    description = "in flight"
                end
                if isValid then
                    if spellcast.target then
                        OvaleState:Log("Active spell %s (%d) is %s to %s (%s), now=%f, endCast=%f", spellcast.spellName, spellcast.spellId, description, spellcast.targetName, spellcast.target, now, spellcast.stop)
                    else
                        OvaleState:Log("Active spell %s (%d) is %s, now=%f, endCast=%f", spellcast.spellName, spellcast.spellId, description, now, spellcast.stop)
                    end
                    self:ApplySpell(spellcast.spellId, spellcast.target, spellcast.start, spellcast.stop, spellcast.channel, spellcast)
                else
                    if spellcast.target then
                        self:Debug("Warning: removing active spell %s (%d) to %s (%s) that should have finished.", spellcast.spellName, spellcast.spellId, spellcast.targetName, spellcast.target)
                    else
                        self:Debug("Warning: removing active spell %s (%d) that should have finished.", spellcast.spellName, spellcast.spellId)
                    end
                    remove(lastSpell.queue, index)
                    self_pool:Release(spellcast)
                    index = index - 1
                end
            end
            index = index + 1
        end
        self:StopProfiling("OvaleFuture_ApplyInFlightSpells")
    end,
})
__exports.OvaleFuture = __exports.OvaleFutureClass()
