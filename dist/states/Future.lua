local __exports = LibStub:NewLibrary("ovale/states/Future", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __LastSpell = LibStub:GetLibrary("ovale/states/LastSpell")
local self_pool = __LastSpell.self_pool
local createSpellCast = __LastSpell.createSpellCast
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ipairs = ipairs
local pairs = pairs
local type = type
local wipe = wipe
local kpairs = pairs
local unpack = unpack
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
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local __State = LibStub:GetLibrary("ovale/State")
local States = __State.States
local __tools = LibStub:GetLibrary("ovale/tools")
local isLuaArray = __tools.isLuaArray
local __Condition = LibStub:GetLibrary("ovale/Condition")
local ReturnValueBetween = __Condition.ReturnValueBetween
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
    local boolean = a.spellId == b.spellId and a.queued == b.queued
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
    GetCounter = function(self, id)
        return self.counter[id] or 0
    end,
    IsChanneling = function(self, atTime)
        return self.currentCast.channel and atTime < self.currentCast.stop
    end,
    constructor = function(self)
        self.lastCastTime = {}
        self.lastOffGCDSpellcast = createSpellCast()
        self.lastGCDSpellcast = createSpellCast()
        self.lastGCDSpellIds = {}
        self.lastGCDSpellId = 0
        self.counter = {}
        self.lastCast = {}
        self.currentCast = createSpellCast()
        self.nextCast = 0
    end
})
__exports.OvaleFutureClass = __class(States, {
    constructor = function(self, ovaleData, ovaleAura, ovalePaperDoll, baseState, ovaleCooldown, ovaleState, ovaleGuid, lastSpell, ovale, ovaleDebug, ovaleProfiler, ovaleStance, requirement, ovaleSpellBook)
        self.ovaleData = ovaleData
        self.ovaleAura = ovaleAura
        self.ovalePaperDoll = ovalePaperDoll
        self.baseState = baseState
        self.ovaleCooldown = ovaleCooldown
        self.ovaleState = ovaleState
        self.ovaleGuid = ovaleGuid
        self.lastSpell = lastSpell
        self.ovale = ovale
        self.ovaleStance = ovaleStance
        self.requirement = requirement
        self.ovaleSpellBook = ovaleSpellBook
        self.isChanneling = function(positionalParameters, namedParameters, atTime)
            local spellId = unpack(positionalParameters)
            local state = self:GetState(atTime)
            if state.currentCast.spellId ~= spellId or  not state.currentCast.channel then
                return 
            end
            return ReturnValueBetween(state.currentCast.start, state.currentCast.stop, 1, state.currentCast.start, 0)
        end
        self.OnInitialize = function()
            self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", self.COMBAT_LOG_EVENT_UNFILTERED)
            self.module:RegisterEvent("PLAYER_ENTERING_WORLD", self.PLAYER_ENTERING_WORLD)
            self.module:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", self.UNIT_SPELLCAST_CHANNEL_START)
            self.module:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", self.UNIT_SPELLCAST_CHANNEL_STOP)
            self.module:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", self.UNIT_SPELLCAST_CHANNEL_UPDATE)
            self.module:RegisterEvent("UNIT_SPELLCAST_DELAYED", self.UNIT_SPELLCAST_DELAYED)
            self.module:RegisterEvent("UNIT_SPELLCAST_FAILED", self.UnitSpellcastEnded)
            self.module:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET", self.UnitSpellcastEnded)
            self.module:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", self.UnitSpellcastEnded)
            self.module:RegisterEvent("UNIT_SPELLCAST_SENT", self.UNIT_SPELLCAST_SENT)
            self.module:RegisterEvent("UNIT_SPELLCAST_START", self.UNIT_SPELLCAST_START)
            self.module:RegisterEvent("UNIT_SPELLCAST_STOP", self.UnitSpellcastEnded)
            self.module:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", self.UNIT_SPELLCAST_SUCCEEDED)
            self.module:RegisterMessage("Ovale_AuraAdded", self.Ovale_AuraAdded)
            self.module:RegisterMessage("Ovale_AuraChanged", self.Ovale_AuraChanged)
        end
        self.OnDisable = function()
            self.module:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self.module:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self.module:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
            self.module:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
            self.module:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
            self.module:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
            self.module:UnregisterEvent("UNIT_SPELLCAST_FAILED")
            self.module:UnregisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
            self.module:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
            self.module:UnregisterEvent("UNIT_SPELLCAST_SENT")
            self.module:UnregisterEvent("UNIT_SPELLCAST_START")
            self.module:UnregisterEvent("UNIT_SPELLCAST_STOP")
            self.module:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            self.module:UnregisterMessage("Ovale_AuraAdded")
            self.module:UnregisterMessage("Ovale_AuraChanged")
        end
        self.COMBAT_LOG_EVENT_UNFILTERED = function(event, ...)
            self.tracer:DebugTimestamp("COMBAT_LOG_EVENT_UNFILTERED", CombatLogGetCurrentEventInfo())
            local _, cleuEvent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellId, spellName, _, _, _, _, _, _, _, _, _, _, isOffHand = CombatLogGetCurrentEventInfo()
            if sourceGUID == self.ovale.playerGUID or self.ovaleGuid:IsPlayerPet(sourceGUID) then
                self.profiler:StartProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED")
                if CLEU_SPELLCAST_EVENT[cleuEvent] then
                    local now = GetTime()
                    if strsub(cleuEvent, 1, 11) == "SPELL_CAST_" and destName and destName ~= "" then
                        self.tracer:DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName)
                        local spellcast = self:GetSpellcast(spellName, spellId, nil, now)
                        if spellcast and spellcast.targetName and spellcast.targetName == destName and spellcast.target ~= destGUID then
                            self.tracer:Debug("Disambiguating target of spell %s (%d) to %s (%s).", spellName, spellId, destName, destGUID)
                            spellcast.target = destGUID
                        end
                    end
                    self.tracer:DebugTimestamp("CLUE", cleuEvent)
                    local finish = CLEU_SPELLCAST_FINISH_EVENT[cleuEvent]
                    if cleuEvent == "SPELL_DAMAGE" or cleuEvent == "SPELL_HEAL" then
                        if isOffHand then
                            finish = nil
                        end
                    end
                    if finish then
                        local anyFinished = false
                        for i = #self.lastSpell.queue, 1, -1 do
                            local spellcast = self.lastSpell.queue[i]
                            if spellcast.success and (spellcast.spellId == spellId or spellcast.auraId == spellId) then
                                if self:FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, finish, i) then
                                    anyFinished = true
                                end
                            end
                        end
                        if  not anyFinished then
                            self.tracer:Debug("Found no spell to finish for %s (%d)", spellName, spellId)
                            for i = #self.lastSpell.queue, 1, -1 do
                                local spellcast = self.lastSpell.queue[i]
                                if spellcast.success and spellcast.spellName == spellName then
                                    if self:FinishSpell(spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, finish, i) then
                                        anyFinished = true
                                    end
                                end
                            end
                            if  not anyFinished then
                                self.tracer:Debug("No spell found for %s", spellName, spellId)
                            end
                        end
                    end
                end
                self.profiler:StopProfiling("OvaleFuture_COMBAT_LOG_EVENT_UNFILTERED")
            end
        end
        self.PLAYER_ENTERING_WORLD = function(event)
            self.profiler:StartProfiling("OvaleFuture_PLAYER_ENTERING_WORLD")
            self.tracer:Debug(event)
            self.profiler:StopProfiling("OvaleFuture_PLAYER_ENTERING_WORLD")
        end
        self.UNIT_SPELLCAST_CHANNEL_START = function(event, unitId, lineId, spellId)
            if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
                local spell = self.ovaleSpellBook:GetSpellName(spellId)
                self.profiler:StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_START")
                self.tracer:DebugTimestamp(event, unitId, spell, lineId, spellId)
                local now = GetTime()
                local spellcast = self:GetSpellcast(spell, spellId, nil, now)
                if spellcast then
                    local name, _, _, startTime, endTime = UnitChannelInfo(unitId)
                    if name == spell then
                        startTime = startTime / 1000
                        endTime = endTime / 1000
                        spellcast.channel = true
                        spellcast.spellId = spellId
                        spellcast.success = now
                        spellcast.start = startTime
                        spellcast.stop = endTime
                        local delta = now - spellcast.queued
                        self.tracer:Debug("Channelling spell %s (%d): start = %s (+%s), ending = %s", spell, spellId, startTime, delta, endTime)
                        self:SaveSpellcastInfo(spellcast, now)
                        self:UpdateLastSpellcast(now, spellcast)
                        self:UpdateCounters(spellId, spellcast.start, spellcast.target)
                        self.ovale:needRefresh()
                    elseif  not name then
                        self.tracer:Debug("Warning: not channelling a spell.")
                    else
                        self.tracer:Debug("Warning: channelling unexpected spell %s", name)
                    end
                else
                    self.tracer:Debug("Warning: channelling spell %s (%d) without previous UNIT_SPELLCAST_SENT.", spell, spellId)
                end
                self.profiler:StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_START")
            end
        end
        self.UNIT_SPELLCAST_CHANNEL_STOP = function(event, unitId, lineId, spellId)
            if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
                local spell = self.ovaleSpellBook:GetSpellName(spellId)
                self.profiler:StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_STOP")
                self.tracer:DebugTimestamp(event, unitId, spell, lineId, spellId)
                local now = GetTime()
                local spellcast, index = self:GetSpellcast(spell, spellId, nil, now)
                if spellcast and spellcast.channel then
                    self.tracer:Debug("Finished channelling spell %s (%d) queued at %s.", spell, spellId, spellcast.queued)
                    spellcast.stop = now
                    self:UpdateLastSpellcast(now, spellcast)
                    local targetGUID = spellcast.target
                    tremove(self.lastSpell.queue, index)
                    self_pool:Release(spellcast)
                    self.ovale:needRefresh()
                    self.module:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, "hit")
                end
                self.profiler:StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_STOP")
            end
        end
        self.UNIT_SPELLCAST_CHANNEL_UPDATE = function(event, unitId, lineId, spellId)
            if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
                local spell = self.ovaleSpellBook:GetSpellName(spellId)
                self.profiler:StartProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_UPDATE")
                self.tracer:DebugTimestamp(event, unitId, spell, lineId, spellId)
                local now = GetTime()
                local spellcast = self:GetSpellcast(spell, spellId, nil, now)
                if spellcast and spellcast.channel then
                    local name, _, _, startTime, endTime = UnitChannelInfo(unitId)
                    if name == spell then
                        startTime = startTime / 1000
                        endTime = endTime / 1000
                        local delta = endTime - spellcast.stop
                        spellcast.start = startTime
                        spellcast.stop = endTime
                        self.tracer:Debug("Updating channelled spell %s (%d) to ending = %s (+%s).", spell, spellId, endTime, delta)
                        self.ovale:needRefresh()
                    elseif  not name then
                        self.tracer:Debug("Warning: not channelling a spell.")
                    else
                        self.tracer:Debug("Warning: delaying unexpected channelled spell %s.", name)
                    end
                else
                    self.tracer:Debug("Warning: no queued, channelled spell %s (%d) found to update.", spell, spellId)
                end
                self.profiler:StopProfiling("OvaleFuture_UNIT_SPELLCAST_CHANNEL_UPDATE")
            end
        end
        self.UNIT_SPELLCAST_DELAYED = function(event, unitId, lineId, spellId)
            if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
                local spell = self.ovaleSpellBook:GetSpellName(spellId)
                self.profiler:StartProfiling("OvaleFuture_UNIT_SPELLCAST_DELAYED")
                self.tracer:DebugTimestamp(event, unitId, spell, lineId, spellId)
                local now = GetTime()
                local spellcast = self:GetSpellcast(spell, spellId, lineId, now)
                if spellcast then
                    local name, _, _, startTime, endTime, _, castId = UnitCastingInfo(unitId)
                    if lineId == castId and name == spell then
                        startTime = startTime / 1000
                        endTime = endTime / 1000
                        local delta = endTime - spellcast.stop
                        spellcast.start = startTime
                        spellcast.stop = endTime
                        self.tracer:Debug("Delaying spell %s (%d) to ending = %s (+%s).", spell, spellId, endTime, delta)
                        self.ovale:needRefresh()
                    elseif  not name then
                        self.tracer:Debug("Warning: not casting a spell.")
                    else
                        self.tracer:Debug("Warning: delaying unexpected spell %s.", name)
                    end
                else
                    self.tracer:Debug("Warning: no queued spell %s (%d) found to delay.", spell, spellId)
                end
                self.profiler:StopProfiling("OvaleFuture_UNIT_SPELLCAST_DELAYED")
            end
        end
        self.UNIT_SPELLCAST_SENT = function(event, unitId, targetName, lineId, spellId)
            if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
                local spell = self.ovaleSpellBook:GetSpellName(spellId)
                self.profiler:StartProfiling("OvaleFuture_UNIT_SPELLCAST_SENT")
                self.tracer:DebugTimestamp(event, unitId, spell, targetName, lineId)
                local now = GetTime()
                local caster = self.ovaleGuid:UnitGUID(unitId)
                local spellcast = self_pool:Get()
                spellcast.lineId = lineId
                spellcast.caster = caster
                spellcast.spellName = spell or "Unknown spell"
                spellcast.queued = now
                insert(self.lastSpell.queue, spellcast)
                if targetName == "" then
                    self.tracer:Debug("Queueing (%d) spell %s with no target.", #self.lastSpell.queue, spell)
                else
                    spellcast.targetName = targetName
                    local targetGUID, nextGUID = self.ovaleGuid:NameGUID(targetName)
                    if nextGUID then
                        local name = self.ovaleGuid:UnitName("target")
                        if name == targetName then
                            targetGUID = self.ovaleGuid:UnitGUID("target")
                        else
                            name = self.ovaleGuid:UnitName("focus")
                            if name == targetName then
                                targetGUID = self.ovaleGuid:UnitGUID("focus")
                            elseif UnitExists("mouseover") then
                                name = UnitName("mouseover")
                                if name == targetName then
                                    targetGUID = UnitGUID("mouseover")
                                end
                            end
                        end
                        spellcast.target = targetGUID or "unknown"
                        self.tracer:Debug("Queueing (%d) spell %s to %s (possibly %s).", #self.lastSpell.queue, spell, targetName, targetGUID)
                    else
                        spellcast.target = targetGUID or "unknown"
                        self.tracer:Debug("Queueing (%d) spell %s to %s (%s).", #self.lastSpell.queue, spell, targetName, targetGUID)
                    end
                end
                self:SaveSpellcastInfo(spellcast, now)
                self.profiler:StopProfiling("OvaleFuture_UNIT_SPELLCAST_SENT")
            end
        end
        self.UNIT_SPELLCAST_START = function(event, unitId, lineId, spellId)
            if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
                local spellName = self.ovaleSpellBook:GetSpellName(spellId)
                self.profiler:StartProfiling("OvaleFuture_UNIT_SPELLCAST_START")
                self.tracer:DebugTimestamp(event, unitId, spellName, lineId, spellId)
                local now = GetTime()
                local spellcast = self:GetSpellcast(spellName, spellId, lineId, now)
                if spellcast then
                    local name, _, _, startTime, endTime, _, castId = UnitCastingInfo(unitId)
                    if lineId == castId and name == spellName then
                        startTime = startTime / 1000
                        endTime = endTime / 1000
                        spellcast.spellId = spellId
                        spellcast.start = startTime
                        spellcast.stop = endTime
                        spellcast.channel = false
                        local delta = now - spellcast.queued
                        self.tracer:Debug("Casting spell %s (%d): start = %s (+%s), ending = %s.", spellName, spellId, startTime, delta, endTime)
                        local auraId, auraGUID = self:GetAuraFinish(spellId, spellcast.target, now)
                        if auraId and auraGUID then
                            spellcast.auraId = auraId
                            spellcast.auraGUID = auraGUID
                            self.tracer:Debug("Spell %s (%d) will finish after updating aura %d on %s.", spellName, spellId, auraId, auraGUID)
                        end
                        self:SaveSpellcastInfo(spellcast, now)
                        self:UpdateLastSpellcast(now, spellcast)
                        self.ovale:needRefresh()
                    elseif  not name then
                        self.tracer:Debug("Warning: not casting a spell.")
                    else
                        self.tracer:Debug("Warning: casting unexpected spell %s.", name)
                    end
                else
                    self.tracer:Debug("Warning: casting spell %s (%d) without previous sent data.", spellName, spellId)
                end
                self.profiler:StopProfiling("OvaleFuture_UNIT_SPELLCAST_START")
            end
        end
        self.UNIT_SPELLCAST_SUCCEEDED = function(event, unitId, lineId, spellId)
            if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
                local spell = self.ovaleSpellBook:GetSpellName(spellId)
                self.profiler:StartProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED")
                self.tracer:DebugTimestamp(event, unitId, spell, lineId, spellId)
                local now = GetTime()
                local spellcast, index = self:GetSpellcast(spell, spellId, lineId, now)
                if spellcast then
                    local success = false
                    if  not spellcast.success and spellcast.start and spellcast.stop and  not spellcast.channel then
                        self.tracer:Debug("Succeeded casting spell %s (%d) at %s, now in flight.", spell, spellId, spellcast.stop)
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
                            self.tracer:Debug("Instant-cast spell %s (%d): start = %s (+%s).", spell, spellId, now, delta)
                            local auraId, auraGUID = self:GetAuraFinish(spellId, spellcast.target, now)
                            if auraId and auraGUID then
                                spellcast.auraId = auraId
                                spellcast.auraGUID = auraGUID
                                self.tracer:Debug("Spell %s (%d) will finish after updating aura %d on %s.", spell, spellId, auraId, auraGUID)
                            end
                            self:SaveSpellcastInfo(spellcast, now)
                            success = true
                        else
                            self.tracer:Debug("Succeeded casting spell %s (%d) but it is channelled.", spell, spellId)
                        end
                    end
                    if success then
                        local targetGUID = spellcast.target
                        self:UpdateLastSpellcast(now, spellcast)
                        self.next:PushGCDSpellId(spellcast.spellId)
                        self:UpdateCounters(spellId, spellcast.stop, targetGUID)
                        local finished = false
                        local finish = "miss"
                        if  not spellcast.targetName then
                            self.tracer:Debug("Finished spell %s (%d) with no target queued at %s.", spell, spellId, spellcast.queued)
                            finished = true
                            finish = "hit"
                        elseif targetGUID == self.ovale.playerGUID and self.ovaleSpellBook:IsHelpfulSpell(spellId) then
                            self.tracer:Debug("Finished helpful spell %s (%d) cast on player queued at %s.", spell, spellId, spellcast.queued)
                            finished = true
                            finish = "hit"
                        end
                        if finished then
                            tremove(self.lastSpell.queue, index)
                            self_pool:Release(spellcast)
                            self.ovale:needRefresh()
                            self.module:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish)
                        end
                    end
                else
                    self.tracer:Debug("Warning: no queued spell %s (%d) found to successfully complete casting.", spell, spellId)
                end
                self.profiler:StopProfiling("OvaleFuture_UNIT_SPELLCAST_SUCCEEDED")
            end
        end
        self.Ovale_AuraAdded = function(event, atTime, guid, auraId, caster)
            if guid == self.ovale.playerGUID then
                self_timeAuraAdded = atTime
                self:UpdateSpellcastSnapshot(self.lastSpell.lastGCDSpellcast, atTime)
                self:UpdateSpellcastSnapshot(self.current.lastOffGCDSpellcast, atTime)
            end
        end
        self.Ovale_AuraChanged = function(event, atTime, guid, auraId, caster)
            self.tracer:DebugTimestamp("Ovale_AuraChanged", event, atTime, guid, auraId, caster)
            if caster == self.ovale.playerGUID then
                local anyFinished = false
                for i = #self.lastSpell.queue, 1, -1 do
                    local spellcast = self.lastSpell.queue[i]
                    if spellcast.success and spellcast.auraId == auraId then
                        if self:FinishSpell(spellcast, "Ovale_AuraChanged", caster, self.ovale.playerGUID, spellcast.targetName, guid, spellcast.spellId, spellcast.spellName, "hit", i) then
                            anyFinished = true
                        end
                    end
                end
                if  not anyFinished then
                    self.tracer:Debug("No spell found to finish for auraId %d", auraId)
                end
            end
        end
        self.UnitSpellcastEnded = function(event, unitId, lineId, spellId)
            if (unitId == "player" or unitId == "pet") and  not WHITE_ATTACK[spellId] then
                if event == "UNIT_SPELLCAST_INTERRUPTED" then
                    self.next.lastGCDSpellId = 0
                end
                local spellName = self.ovaleSpellBook:GetSpellName(spellId)
                self.profiler:StartProfiling("OvaleFuture_UnitSpellcastEnded")
                self.tracer:DebugTimestamp(event, unitId, spellName, lineId, spellId)
                local now = GetTime()
                local spellcast, index = self:GetSpellcast(spellName, spellId, lineId, now)
                if spellcast then
                    self.tracer:Debug("End casting spell %s (%d) queued at %s due to %s.", spellName, spellId, spellcast.queued, event)
                    if  not spellcast.success then
                        self.tracer:Debug("Remove spell from queue because there was no success before")
                        tremove(self.lastSpell.queue, index)
                        self_pool:Release(spellcast)
                        self.ovale:needRefresh()
                    end
                elseif lineId then
                    self.tracer:Debug("Warning: no queued spell %s (%d) found to end casting.", spellName, spellId)
                end
                self.profiler:StopProfiling("OvaleFuture_UnitSpellcastEnded")
            end
        end
        States.constructor(self, __exports.OvaleFutureData)
        local name = "OvaleFuture"
        self.tracer = ovaleDebug:create(name)
        self.profiler = ovaleProfiler:create(name)
        self.module = ovale:createModule(name, self.OnInitialize, self.OnDisable, aceEvent)
    end,
    registerConditions = function(self, condition)
        condition:RegisterCondition("channeling", true, self.isChanneling)
    end,
    UpdateStateCounters = function(self, state, spellId, atTime, targetGUID)
        local inccounter = self.ovaleData:GetSpellInfoProperty(spellId, atTime, "inccounter", targetGUID)
        if inccounter then
            local value = (state.counter[inccounter] and state.counter[inccounter]) or 0
            state.counter[inccounter] = value + 1
        end
        local resetcounter = self.ovaleData:GetSpellInfoProperty(spellId, atTime, "resetcounter", targetGUID)
        if resetcounter then
            state.counter[resetcounter] = 0
        end
    end,
    FinishSpell = function(self, spellcast, cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName, finish, i)
        local finished = false
        if  not spellcast.auraId then
            self.tracer:DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName)
            if  not spellcast.channel then
                self.tracer:Debug("Finished (%s) spell %s (%d) queued at %s due to %s.", finish, spellName, spellId, spellcast.queued, cleuEvent)
                finished = true
            end
        elseif CLEU_AURA_EVENT[cleuEvent] and spellcast.auraGUID and destGUID == spellcast.auraGUID then
            self.tracer:DebugTimestamp("CLEU", cleuEvent, sourceName, sourceGUID, destName, destGUID, spellId, spellName)
            self.tracer:Debug("Finished (%s) spell %s (%d) queued at %s after seeing aura %d on %s.", finish, spellName, spellId, spellcast.queued, spellcast.auraId, spellcast.auraGUID)
            finished = true
        elseif cleuEvent == "Ovale_AuraChanged" and spellcast.auraGUID and destGUID == spellcast.auraGUID then
            self.tracer:Debug("Finished (%s) spell %s (%d) queued at %s after Ovale_AuraChanged was called for aura %d on %s.", finish, spellName, spellId, spellcast.queued, spellcast.auraId, spellcast.auraGUID)
            finished = true
        end
        if finished then
            local now = GetTime()
            if self_timeAuraAdded then
                if IsSameSpellcast(spellcast, self.lastSpell.lastGCDSpellcast) then
                    self:UpdateSpellcastSnapshot(self.lastSpell.lastGCDSpellcast, self_timeAuraAdded)
                end
                if IsSameSpellcast(spellcast, self.current.lastOffGCDSpellcast) then
                    self:UpdateSpellcastSnapshot(self.current.lastOffGCDSpellcast, self_timeAuraAdded)
                end
            end
            local delta = now - spellcast.stop
            local targetGUID = spellcast.target
            self.tracer:Debug("Spell %s (%d) was in flight for %f seconds.", spellName, spellId, delta)
            tremove(self.lastSpell.queue, i)
            self_pool:Release(spellcast)
            self.ovale:needRefresh()
            self.module:SendMessage("Ovale_SpellFinished", now, spellId, targetGUID, finish)
        end
        return finished
    end,
    GetSpellcast = function(self, spellName, spellId, lineId, atTime)
        self.profiler:StartProfiling("OvaleFuture_GetSpellcast")
        local spellcast = nil
        local index = 0
        if  not lineId or lineId ~= "" then
            for i, sc in ipairs(self.lastSpell.queue) do
                if  not lineId or sc.lineId == lineId then
                    if spellId and sc.spellId == spellId then
                        spellcast = sc
                        index = i
                        break
                    elseif spellName then
                        local spellName = sc.spellName or self.ovaleSpellBook:GetSpellName(spellId)
                        if spellName == spellName then
                            spellcast = sc
                            index = i
                            break
                        end
                    end
                end
            end
        end
        if spellcast then
            spellName = spellName or spellcast.spellName or self.ovaleSpellBook:GetSpellName(spellId)
            if spellcast.targetName then
                self.tracer:Debug("Found spellcast for %s to %s queued at %f.", spellName, spellcast.targetName, spellcast.queued)
            else
                self.tracer:Debug("Found spellcast for %s with no target queued at %f.", spellName, spellcast.queued)
            end
        end
        self.profiler:StopProfiling("OvaleFuture_GetSpellcast")
        return spellcast, index
    end,
    GetAuraFinish = function(self, spellId, targetGUID, atTime)
        self.profiler:StartProfiling("OvaleFuture_GetAuraFinish")
        local auraId, auraGUID
        local si = self.ovaleData.spellInfo[spellId]
        if si and si.aura then
            for _, unitId in ipairs(SPELLCAST_AURA_ORDER) do
                for _, auraList in kpairs(si.aura[unitId]) do
                    for id, spellData in kpairs(auraList) do
                        local verified, value = self.ovaleData:CheckSpellAuraData(id, spellData, atTime, targetGUID)
                        if verified and (SPELLAURALIST_AURA_VALUE[value] or (type(value) == "number" and value > 0)) then
                            auraId = id
                            auraGUID = self.ovaleGuid:UnitGUID(unitId)
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
        self.profiler:StopProfiling("OvaleFuture_GetAuraFinish")
        return auraId, auraGUID
    end,
    SaveSpellcastInfo = function(self, spellcast, atTime)
        self.profiler:StartProfiling("OvaleFuture_SaveSpellcastInfo")
        self.tracer:Debug("    Saving information from %s to the spellcast for %s.", atTime, spellcast.spellName)
        if spellcast.spellId then
            spellcast.damageMultiplier = self:GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime)
        end
        for _, mod in pairs(self.lastSpell.modules) do
            local func = mod.SaveSpellcastInfo
            if func then
                func(spellcast, atTime)
            end
        end
        self.profiler:StopProfiling("OvaleFuture_SaveSpellcastInfo")
    end,
    GetDamageMultiplier = function(self, spellId, targetGUID, atTime)
        local damageMultiplier = 1
        local si = self.ovaleData.spellInfo[spellId]
        if si and si.aura and si.aura.damage then
            for filter, auraList in kpairs(si.aura.damage) do
                for auraId, spellData in pairs(auraList) do
                    local index, multiplier
                    local verified
                    if isLuaArray(spellData) then
                        multiplier = spellData[1]
                        index = 2
                        verified = self.requirement:CheckRequirements(spellId, atTime, spellData, index, targetGUID)
                    else
                        multiplier = spellData
                        verified = true
                    end
                    if verified then
                        local aura = self.ovaleAura:GetAuraByGUID(self.ovale.playerGUID, auraId, filter, false, atTime)
                        if aura and self.ovaleAura:IsActiveAura(aura, atTime) then
                            local siAura = self.ovaleData.spellInfo[auraId]
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
        return self:UpdateStateCounters(self:GetState(atTime), spellId, atTime, targetGUID)
    end,
    IsActive = function(self, spellId)
        for _, spellcast in ipairs(self.lastSpell.queue) do
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
        self.profiler:StartProfiling("OvaleFuture_UpdateLastSpellcast")
        self.current.lastCastTime[spellcast.spellId] = atTime
        if spellcast.offgcd then
            self.tracer:Debug("    Caching spell %s (%d) as most recent off-GCD spellcast.", spellcast.spellName, spellcast.spellId)
            for k, v in kpairs(spellcast) do
                (self.current.lastOffGCDSpellcast)[k] = v
            end
            self.lastSpell.lastSpellcast = self.current.lastOffGCDSpellcast
            self.next.lastOffGCDSpellcast = self.current.lastOffGCDSpellcast
        else
            self.tracer:Debug("    Caching spell %s (%d) as most recent GCD spellcast.", spellcast.spellName, spellcast.spellId)
            for k, v in kpairs(spellcast) do
                (self.lastSpell.lastGCDSpellcast)[k] = v
            end
            self.lastSpell.lastSpellcast = self.lastSpell.lastGCDSpellcast
            self.next.lastGCDSpellId = self.lastSpell.lastGCDSpellcast.spellId
        end
        self.profiler:StopProfiling("OvaleFuture_UpdateLastSpellcast")
    end,
    UpdateSpellcastSnapshot = function(self, spellcast, atTime)
        if spellcast.queued and ( not spellcast.snapshotTime or (spellcast.snapshotTime < atTime and atTime < spellcast.stop + 1)) then
            if spellcast.targetName then
                self.tracer:Debug("    Updating to snapshot from %s for spell %s to %s (%s) queued at %s.", atTime, spellcast.spellName, spellcast.targetName, spellcast.target, spellcast.queued)
            else
                self.tracer:Debug("    Updating to snapshot from %s for spell %s with no target queued at %s.", atTime, spellcast.spellName, spellcast.queued)
            end
            self.ovalePaperDoll:UpdateSnapshot(spellcast, self.ovalePaperDoll.current, true)
            if spellcast.spellId then
                spellcast.damageMultiplier = self:GetDamageMultiplier(spellcast.spellId, spellcast.target, atTime)
                if spellcast.damageMultiplier ~= 1 then
                    self.tracer:Debug("        persistent multiplier = %f", spellcast.damageMultiplier)
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
        return (self.next.lastCastTime[spellId] or self.current.lastCastTime[spellId] or 0)
    end,
    IsChanneling = function(self, atTime)
        return self:GetState(atTime):IsChanneling(atTime)
    end,
    GetCurrentCast = function(self, atTime)
        if atTime and self.next.currentCast and self.next.currentCast.start <= atTime and self.next.currentCast.stop >= atTime then
            return self.next.currentCast
        end
        for _, value in ipairs(self.lastSpell.queue) do
            if value.start and value.start <= atTime and ( not value.stop or value.stop >= atTime) then
                return value
            end
        end
    end,
    GetGCD = function(self, spellId, atTime, targetGUID)
        spellId = spellId or self.next.currentCast.spellId
        if  not atTime then
            if self.next.currentCast.stop and self.next.currentCast.stop > self.baseState.next.currentTime then
                atTime = self.next.currentCast.stop
            else
                atTime = self.baseState.next.currentTime or self.baseState.current.currentTime
            end
        end
        targetGUID = targetGUID or self.ovaleGuid:UnitGUID(self.baseState.next.defaultTarget)
        local gcd = spellId and self.ovaleData:GetSpellInfoProperty(spellId, atTime, "gcd", targetGUID)
        if  not gcd then
            local haste
            gcd, haste = self.ovaleCooldown:GetBaseGCD()
            if self.ovale.playerClass == "MONK" and self.ovalePaperDoll:IsSpecialization("mistweaver") then
                gcd = 1.5
                haste = "spell"
            elseif self.ovale.playerClass == "DRUID" then
                if self.ovaleStance:IsStance("druid_cat_form", atTime) then
                    gcd = 1
                    haste = "none"
                end
            end
            local gcdHaste = spellId and self.ovaleData:GetSpellInfoProperty(spellId, atTime, "gcd_haste", targetGUID)
            if gcdHaste then
                haste = gcdHaste
            else
                local siHaste = spellId and self.ovaleData:GetSpellInfoProperty(spellId, atTime, "haste", targetGUID)
                if siHaste then
                    haste = siHaste
                end
            end
            local multiplier = self.ovalePaperDoll:GetHasteMultiplier(haste, self.ovalePaperDoll.next)
            gcd = gcd / multiplier
            gcd = (gcd > 0.75 and gcd) or 0.75
        end
        return gcd
    end,
    InitializeState = function(self)
        self.next.lastCast = {}
        self.next.counter = {}
    end,
    ResetState = function(self)
        self.profiler:StartProfiling("OvaleFuture_ResetState")
        local now = self.baseState.next.currentTime
        self.tracer:Log("Reset state with current time = %f", now)
        self.next.nextCast = now
        wipe(self.next.lastCast)
        wipe(__exports.OvaleFutureClass.staticSpellcast)
        self.next.currentCast = __exports.OvaleFutureClass.staticSpellcast
        local reason = ""
        local start, duration = self.ovaleCooldown:GetGlobalCooldown(now)
        if start and start > 0 then
            local ending = start + duration
            if self.next.nextCast < ending then
                self.next.nextCast = ending
                reason = " (waiting for GCD)"
            end
        end
        local lastGCDSpellcastFound, lastOffGCDSpellcastFound, lastSpellcastFound
        for i = #self.lastSpell.queue, 1, -1 do
            local spellcast = self.lastSpell.queue[i]
            if spellcast.spellId and spellcast.start then
                self.tracer:Log("    Found cast %d of spell %s (%d), start = %s, stop = %s.", i, spellcast.spellName, spellcast.spellId, spellcast.start, spellcast.stop)
                if  not lastSpellcastFound then
                    if spellcast.start and spellcast.stop and spellcast.start <= now and now < spellcast.stop then
                        self.next.currentCast = spellcast
                    end
                    lastSpellcastFound = true
                end
                if  not lastGCDSpellcastFound and  not spellcast.offgcd then
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
            local spellcast = self.lastSpell.lastSpellcast
            if spellcast then
                if spellcast.start and spellcast.stop and spellcast.start <= now and now < spellcast.stop then
                    self.next.currentCast = spellcast
                end
            end
        end
        if  not lastGCDSpellcastFound then
            local spellcast = self.lastSpell.lastGCDSpellcast
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
        self.tracer:Log("    nextCast = %f%s", self.next.nextCast, reason)
        for k, v in pairs(self.current.counter) do
            self.next.counter[k] = v
        end
        self.profiler:StopProfiling("OvaleFuture_ResetState")
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
        self.profiler:StartProfiling("OvaleFuture_ApplySpellStartCast")
        if channel then
            self:UpdateCounters(spellId, startCast, targetGUID)
        end
        self.profiler:StopProfiling("OvaleFuture_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        self.profiler:StartProfiling("OvaleFuture_ApplySpellAfterCast")
        if  not channel then
            self:UpdateCounters(spellId, endCast, targetGUID)
        end
        self.profiler:StopProfiling("OvaleFuture_ApplySpellAfterCast")
    end,
    staticSpellcast = createSpellCast(),
    ApplySpell = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        channel = channel or false
        self.profiler:StartProfiling("OvaleFuture_state_ApplySpell")
        if spellId then
            if  not targetGUID then
                targetGUID = self.ovale.playerGUID
            end
            local castTime
            if startCast and endCast then
                castTime = endCast - startCast
            else
                castTime = self.ovaleSpellBook:GetCastTime(spellId) or 0
                startCast = startCast or self.next.nextCast
                endCast = endCast or startCast + castTime
            end
            if  not spellcast then
                spellcast = __exports.OvaleFutureClass.staticSpellcast
                wipe(spellcast)
                spellcast.caster = self.ovale.playerGUID
                spellcast.spellId = spellId
                spellcast.spellName = self.ovaleSpellBook:GetSpellName(spellId) or "unknown spell"
                spellcast.target = targetGUID
                spellcast.targetName = self.ovaleGuid:GUIDName(targetGUID) or "target"
                spellcast.start = startCast
                spellcast.stop = endCast
                spellcast.channel = channel
                self.ovalePaperDoll:UpdateSnapshot(spellcast, self.ovalePaperDoll.next)
                local atTime = (channel and startCast) or endCast
                for _, mod in pairs(self.lastSpell.modules) do
                    local func = mod.SaveSpellcastInfo
                    if func then
                        func(spellcast, atTime, self.ovalePaperDoll.next)
                    end
                end
            end
            self.next.currentCast = spellcast
            self.next.lastCast[spellId] = endCast
            local gcd = self:GetGCD(spellId, startCast, targetGUID)
            local nextCast = (castTime > gcd and endCast) or startCast + gcd
            if self.next.nextCast < nextCast then
                self.next.nextCast = nextCast
            end
            self.tracer:Log("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, self.baseState.next.currentTime, nextCast, endCast, targetGUID)
            if startCast > self.baseState.next.currentTime then
                self.ovaleState:ApplySpellStartCast(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
            if endCast > self.baseState.next.currentTime then
                self.ovaleState:ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
            self.ovaleState:ApplySpellOnHit(spellId, targetGUID, startCast, endCast, channel, spellcast)
        end
        self.profiler:StopProfiling("OvaleFuture_state_ApplySpell")
    end,
    ApplyInFlightSpells = function(self)
        self.profiler:StartProfiling("OvaleFuture_ApplyInFlightSpells")
        local now = GetTime()
        local index = 1
        while index <= #self.lastSpell.queue do
            local spellcast = self.lastSpell.queue[index]
            if spellcast.stop then
                local isValid = false
                local description
                if now < spellcast.stop then
                    isValid = true
                    description = (spellcast.channel and "channelling") or "being cast"
                elseif now < spellcast.stop + 5 then
                    isValid = true
                    description = "in flight"
                end
                if isValid then
                    if spellcast.target then
                        self.tracer:Log("Active spell %s (%d) is %s to %s (%s), now=%f, endCast=%f, start=%f", spellcast.spellName, spellcast.spellId, description, spellcast.targetName, spellcast.target, now, spellcast.stop, spellcast.start)
                    else
                        self.tracer:Log("Active spell %s (%d) is %s, now=%f, endCast=%f, start=%f", spellcast.spellName, spellcast.spellId, description, now, spellcast.stop, spellcast.start)
                    end
                    self:ApplySpell(spellcast.spellId, spellcast.target, spellcast.start, spellcast.stop, spellcast.channel, spellcast)
                else
                    if spellcast.target then
                        self.tracer:Debug("Warning: removing active spell %s (%d) to %s (%s) that should have finished.", spellcast.spellName, spellcast.spellId, spellcast.targetName, spellcast.target)
                    else
                        self.tracer:Debug("Warning: removing active spell %s (%d) that should have finished.", spellcast.spellName, spellcast.spellId)
                    end
                    remove(self.lastSpell.queue, index)
                    self_pool:Release(spellcast)
                    index = index - 1
                end
            end
            index = index + 1
        end
        self.profiler:StopProfiling("OvaleFuture_ApplyInFlightSpells")
    end,
})
