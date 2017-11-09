local __exports = LibStub:NewLibrary("ovale/FutureState", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Future = LibStub:GetLibrary("ovale/Future")
local OvaleFuture = __Future.OvaleFuture
local __Cooldown = LibStub:GetLibrary("ovale/Cooldown")
local OvaleCooldown = __Cooldown.OvaleCooldown
local __LastSpell = LibStub:GetLibrary("ovale/LastSpell")
local lastSpell = __LastSpell.lastSpell
local self_pool = __LastSpell.self_pool
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local __GUID = LibStub:GetLibrary("ovale/GUID")
local OvaleGUID = __GUID.OvaleGUID
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local baseState = __State.baseState
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local paperDollState = __PaperDoll.paperDollState
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local __DataState = LibStub:GetLibrary("ovale/DataState")
local dataState = __DataState.dataState
local __Stance = LibStub:GetLibrary("ovale/Stance")
local OvaleStance = __Stance.OvaleStance
local wipe = wipe
local pairs = pairs
local GetTime = GetTime
local insert = table.insert
local remove = table.remove
local SIMULATOR_LAG = 0.005
local FutureState = __class(nil, {
    InitializeState = function(self)
        self.lastCast = {}
        self.counter = {}
    end,
    ResetState = function(self)
        OvaleFuture:StartProfiling("OvaleFuture_ResetState")
        local now = GetTime()
        baseState.currentTime = now
        OvaleFuture:Log("Reset state with current time = %f", baseState.currentTime)
        self.inCombat = OvaleFuture.inCombat
        self.combatStartTime = OvaleFuture.combatStartTime or 0
        self.nextCast = now
        local reason = ""
        local start, duration = OvaleCooldown:GetGlobalCooldown(now)
        if start and start > 0 then
            local ending = start + duration
            if self.nextCast < ending then
                self.nextCast = ending
                reason = " (waiting for GCD)"
            end
        end
        local lastGCDSpellcastFound, lastOffGCDSpellcastFound, lastSpellcastFound
        for i = #lastSpell.queue, 1, -1 do
            local spellcast = lastSpell.queue[i]
            if spellcast.spellId and spellcast.start then
                OvaleFuture:Log("    Found cast %d of spell %s (%d), start = %s, stop = %s.", i, spellcast.spellName, spellcast.spellId, spellcast.start, spellcast.stop)
                if  not lastSpellcastFound then
                    self.lastSpellId = spellcast.spellId
                    if spellcast.start and spellcast.stop and spellcast.start <= now and now < spellcast.stop then
                        self.currentSpellId = spellcast.spellId
                        self.startCast = spellcast.start
                        self.endCast = spellcast.stop
                        self.channel = spellcast.channel
                    end
                    lastSpellcastFound = true
                end
                if  not lastGCDSpellcastFound and  not spellcast.offgcd then
                    self:PushGCDSpellId(spellcast.spellId)
                    if spellcast.stop and self.nextCast < spellcast.stop then
                        self.nextCast = spellcast.stop
                        reason = " (waiting for spellcast)"
                    end
                    lastGCDSpellcastFound = true
                end
                if  not lastOffGCDSpellcastFound and spellcast.offgcd then
                    self.lastOffGCDSpellId = spellcast.spellId
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
                self.lastSpellId = spellcast.spellId
                if spellcast.start and spellcast.stop and spellcast.start <= now and now < spellcast.stop then
                    self.currentSpellId = spellcast.spellId
                    self.startCast = spellcast.start
                    self.endCast = spellcast.stop
                    self.channel = spellcast.channel
                end
            end
        end
        if  not lastGCDSpellcastFound then
            local spellcast = lastSpell.lastGCDSpellcast
            if spellcast then
                self.lastGCDSpellId = spellcast.spellId
                if spellcast.stop and self.nextCast < spellcast.stop then
                    self.nextCast = spellcast.stop
                    reason = " (waiting for spellcast)"
                end
            end
        end
        if  not lastOffGCDSpellcastFound then
            local spellcast = OvaleFuture.lastOffGCDSpellcast
            if spellcast then
                self.lastOffGCDSpellId = spellcast.spellId
            end
        end
        OvaleFuture:Log("    lastSpellId = %s, lastGCDSpellId = %s, lastOffGCDSpellId = %s", self.lastSpellId, self.lastGCDSpellId, self.lastOffGCDSpellId)
        OvaleFuture:Log("    nextCast = %f%s", self.nextCast, reason)
        wipe(self.lastCast)
        for k, v in pairs(OvaleFuture.counter) do
            self.counter[k] = v
        end
        OvaleFuture:StopProfiling("OvaleFuture_ResetState")
    end,
    CleanState = function(self)
        for k in pairs(self.lastCast) do
            self.lastCast[k] = nil
        end
        for k in pairs(self.counter) do
            self.counter[k] = nil
        end
    end,
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        OvaleFuture:StartProfiling("OvaleFuture_ApplySpellStartCast")
        if channel then
            OvaleFuture:UpdateCounters(spellId, startCast, targetGUID)
        end
        OvaleFuture:StopProfiling("OvaleFuture_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        OvaleFuture:StartProfiling("OvaleFuture_ApplySpellAfterCast")
        if  not channel then
            OvaleFuture:UpdateCounters(spellId, endCast, targetGUID)
        end
        OvaleFuture:StopProfiling("OvaleFuture_ApplySpellAfterCast")
    end,
    GetCounter = function(self, id)
        return self.counter[id] or 0
    end,
    GetCounterValue = function(self, id)
        return self:GetCounter(id)
    end,
    TimeOfLastCast = function(self, spellId)
        return self.lastCast[spellId] or OvaleFuture.lastCastTime[spellId] or 0
    end,
    IsChanneling = function(self, atTime)
        atTime = atTime or baseState.currentTime
        return self.channel and (atTime < self.endCast)
    end,
    PushGCDSpellId = function(self, spellId)
        if self.lastGCDSpellId then
            insert(self.lastGCDSpellIds, self.lastGCDSpellId)
            if #self.lastGCDSpellIds > 5 then
                remove(self.lastGCDSpellIds, 1)
            end
        end
        self.lastGCDSpellId = spellId
    end,
    ApplySpell = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        OvaleFuture:StartProfiling("OvaleFuture_state_ApplySpell")
        if spellId then
            if  not targetGUID then
                targetGUID = Ovale.playerGUID
            end
            local castTime
            if startCast and endCast then
                castTime = endCast - startCast
            else
                castTime = OvaleSpellBook:GetCastTime(spellId) or 0
                startCast = startCast or self.nextCast
                endCast = endCast or (startCast + castTime)
            end
            if  not spellcast then
                spellcast = FutureState.staticSpellcast
                wipe(spellcast)
                spellcast.caster = Ovale.playerGUID
                spellcast.spellId = spellId
                spellcast.spellName = OvaleSpellBook:GetSpellName(spellId)
                spellcast.target = targetGUID
                spellcast.targetName = OvaleGUID:GUIDName(targetGUID)
                spellcast.start = startCast
                spellcast.stop = endCast
                spellcast.channel = channel
                paperDollState:UpdateSnapshot(spellcast)
                local atTime = channel and startCast or endCast
                for _, mod in pairs(lastSpell.modules) do
                    local func = mod.SaveSpellcastInfo
                    if func then
                        func(mod, spellcast, atTime, self)
                    end
                end
            end
            self.lastSpellId = spellId
            self.startCast = startCast
            self.endCast = endCast
            self.lastCast[spellId] = endCast
            self.channel = channel
            local gcd = self:GetGCD(spellId, startCast, targetGUID)
            local nextCast = (castTime > gcd) and endCast or (startCast + gcd)
            if self.nextCast < nextCast then
                self.nextCast = nextCast
            end
            if gcd > 0 then
                self:PushGCDSpellId(spellId)
            else
                self.lastOffGCDSpellId = spellId
            end
            local now = GetTime()
            if startCast >= now then
                baseState.currentTime = startCast + SIMULATOR_LAG
            else
                baseState.currentTime = now
            end
            OvaleFuture:Log("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, baseState.currentTime, nextCast, endCast, targetGUID)
            if  not self.inCombat and OvaleSpellBook:IsHarmfulSpell(spellId) then
                self.inCombat = true
                if channel then
                    self.combatStartTime = startCast
                else
                    self.combatStartTime = endCast
                end
            end
            if startCast > now then
                OvaleState:ApplySpellStartCast(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
            if endCast > now then
                OvaleState:ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
            OvaleState:ApplySpellOnHit(spellId, targetGUID, startCast, endCast, channel, spellcast)
        end
        OvaleFuture:StopProfiling("OvaleFuture_state_ApplySpell")
    end,
    GetDamageMultiplier = function(self, spellId, targetGUID, atTime)
        return OvaleFuture:GetDamageMultiplier(spellId, targetGUID, atTime)
    end,
    UpdateCounters = function(self, spellId, atTime, targetGUID)
        return OvaleFuture:UpdateCounters(spellId, atTime, targetGUID)
    end,
    ApplyInFlightSpells = function(self)
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
                    remove(lastSpell.queue, index)
                    self_pool:Release(spellcast)
                    index = index - 1
                end
            end
            index = index + 1
        end
    end,
    GetGCD = function(self, spellId, atTime, targetGUID)
        spellId = spellId or __exports.futureState.currentSpellId
        if  not atTime then
            if __exports.futureState.endCast and __exports.futureState.endCast > baseState.currentTime then
                atTime = __exports.futureState.endCast
            else
                atTime = baseState.currentTime
            end
        end
        targetGUID = targetGUID or OvaleGUID:UnitGUID(baseState.defaultTarget)
        local gcd = spellId and dataState:GetSpellInfoProperty(spellId, atTime, "gcd", targetGUID)
        if  not gcd then
            local haste
            gcd, haste = OvaleCooldown:GetBaseGCD()
            if Ovale.playerClass == "MONK" and OvalePaperDoll:IsSpecialization("mistweaver") then
                gcd = 1.5
                haste = "spell"
            elseif Ovale.playerClass == "DRUID" then
                if OvaleStance:IsStance("druid_cat_form") then
                    gcd = 1
                    haste = false
                end
            end
            local gcdHaste = spellId and dataState:GetSpellInfoProperty(spellId, atTime, "gcd_haste", targetGUID)
            if gcdHaste then
                haste = gcdHaste
            else
                local siHaste = spellId and dataState:GetSpellInfoProperty(spellId, atTime, "haste", targetGUID)
                if siHaste then
                    haste = siHaste
                end
            end
            local multiplier = paperDollState:GetHasteMultiplier(haste)
            gcd = gcd / multiplier
            gcd = (gcd > 0.75) and gcd or 0.75
        end
        return gcd
    end,
    constructor = function(self)
        self.inCombat = nil
        self.combatStartTime = nil
        self.currentSpellId = nil
        self.startCast = nil
        self.endCast = nil
        self.nextCast = nil
        self.lastCast = nil
        self.channel = nil
        self.lastSpellId = nil
        self.lastGCDSpellId = nil
        self.lastGCDSpellIds = {}
        self.lastOffGCDSpellId = nil
        self.counter = nil
        self.staticSpellcast = {}
    end
})
__exports.futureState = FutureState()
OvaleState:RegisterState(__exports.futureState)
