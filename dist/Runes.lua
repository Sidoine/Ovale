local __exports = LibStub:NewLibrary("ovale/Runes", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __State = LibStub:GetLibrary("ovale/State")
local States = __State.States
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ipairs = ipairs
local wipe = wipe
local GetRuneCooldown = GetRuneCooldown
local GetTime = GetTime
local huge = math.huge
local sort = table.sort
local EMPOWER_RUNE_WEAPON = 47568
local RUNE_SLOTS = 6
local IsActiveRune = function(rune, atTime)
    return (rune.startCooldown == 0 or rune.endCooldown <= atTime)
end

local RuneData = __class(nil, {
    constructor = function(self)
        self.rune = {}
    end
})
local usedRune = {}
__exports.OvaleRunesClass = __class(States, {
    constructor = function(self, ovale, ovaleDebug, ovaleProfiler, ovaleData, ovalePower, ovalePaperDoll)
        self.ovale = ovale
        self.ovaleData = ovaleData
        self.ovalePower = ovalePower
        self.ovalePaperDoll = ovalePaperDoll
        self.OnInitialize = function()
            if self.ovale.playerClass == "DEATHKNIGHT" then
                for slot = 1, RUNE_SLOTS, 1 do
                    self.current.rune[slot] = {
                        endCooldown = 0,
                        startCooldown = 0
                    }
                end
                -- self.module:RegisterEvent("PLAYER_ENTERING_WORLD", self.UpdateAllRunes)
                self.module:RegisterEvent("RUNE_POWER_UPDATE", self.RUNE_POWER_UPDATE)
                self.module:RegisterEvent("UNIT_RANGEDDAMAGE", self.UNIT_RANGEDDAMAGE)
                self.module:RegisterEvent("UNIT_SPELL_HASTE", self.UNIT_RANGEDDAMAGE)
                if self.ovale.playerGUID then
                    self.UpdateAllRunes()
                end
            end
        end
        self.OnDisable = function()
            if self.ovale.playerClass == "DEATHKNIGHT" then
                self.module:UnregisterEvent("PLAYER_ENTERING_WORLD")
                self.module:UnregisterEvent("RUNE_POWER_UPDATE")
                self.module:UnregisterEvent("UNIT_RANGEDDAMAGE")
                self.module:UnregisterEvent("UNIT_SPELL_HASTE")
                self.current.rune = {}
            end
        end
        self.RUNE_POWER_UPDATE = function(event, slot, usable)
            self.tracer:Debug(event, slot, usable)
            self:UpdateRune(slot)
        end
        self.UNIT_RANGEDDAMAGE = function(event, unitId)
            if unitId == "player" then
                self.tracer:Debug(event)
                self.UpdateAllRunes()
            end
        end
        self.UpdateAllRunes = function()
            for slot = 1, RUNE_SLOTS, 1 do
                self:UpdateRune(slot)
            end
        end
        States.constructor(self, RuneData)
        self.module = ovale:createModule("OvaleRunes", self.OnInitialize, self.OnDisable, aceEvent)
        self.tracer = ovaleDebug:create(self.module:GetName())
        self.profiler = ovaleProfiler:create(self.module:GetName())
    end,
    UpdateRune = function(self, slot)
        self.profiler:StartProfiling("OvaleRunes_UpdateRune")
        local rune = self.current.rune[slot]
        local start, duration = GetRuneCooldown(slot)
        if start and duration then
            if start > 0 then
                rune.startCooldown = start
                rune.endCooldown = start + duration
            else
                rune.startCooldown = 0
                rune.endCooldown = 0
            end
            self.ovale:needRefresh()
        else
            self.tracer:Debug("Warning: rune information for slot %d not available.", slot)
        end
        self.profiler:StopProfiling("OvaleRunes_UpdateRune")
    end,
    DebugRunes = function(self)
        local now = GetTime()
        for slot = 1, RUNE_SLOTS, 1 do
            local rune = self.current.rune[slot]
            if IsActiveRune(rune, now) then
                self.tracer:Print("rune[%d] is active.", slot)
            else
                self.tracer:Print("rune[%d] comes off cooldown in %f seconds.", slot, rune.endCooldown - now)
            end
        end
    end,
    InitializeState = function(self)
        self.next.rune = {}
        for slot in ipairs(self.current.rune) do
            self.next.rune[slot] = {
                endCooldown = 0,
                startCooldown = 0
            }
        end
    end,
    ResetState = function(self)
        self.profiler:StartProfiling("OvaleRunes_ResetState")
        for slot, rune in ipairs(self.current.rune) do
            local stateRune = self.next.rune[slot]
            stateRune.endCooldown = rune.endCooldown
            stateRune.startCooldown = rune.startCooldown
        end
        self.profiler:StopProfiling("OvaleRunes_ResetState")
    end,
    CleanState = function(self)
        for slot, rune in ipairs(self.next.rune) do
            wipe(rune)
            self.next.rune[slot] = nil
        end
    end,
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        self.profiler:StartProfiling("OvaleRunes_ApplySpellStartCast")
        if isChanneled then
            self:ApplyRuneCost(spellId, startCast, spellcast)
        end
        self.profiler:StopProfiling("OvaleRunes_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        self.profiler:StartProfiling("OvaleRunes_ApplySpellAfterCast")
        if  not isChanneled then
            self:ApplyRuneCost(spellId, endCast, spellcast)
            if spellId == EMPOWER_RUNE_WEAPON then
                for slot in ipairs(self.next.rune) do
                    self:ReactivateRune(slot, endCast)
                end
            end
        end
        self.profiler:StopProfiling("OvaleRunes_ApplySpellAfterCast")
    end,
    ApplyRuneCost = function(self, spellId, atTime, spellcast)
        local si = self.ovaleData.spellInfo[spellId]
        if si then
            local count = si.runes or 0
            while count > 0 do
                self:ConsumeRune(spellId, atTime, spellcast)
                count = count - 1
            end
        end
    end,
    ReactivateRune = function(self, slot, atTime)
        local rune = self.next.rune[slot]
        if rune.startCooldown > atTime then
            rune.startCooldown = atTime
        end
        rune.endCooldown = atTime
    end,
    ConsumeRune = function(self, spellId, atTime, snapshot)
        self.profiler:StartProfiling("OvaleRunes_state_ConsumeRune")
        local consumedRune
        for slot = 1, RUNE_SLOTS, 1 do
            local rune = self.next.rune[slot]
            if IsActiveRune(rune, atTime) then
                consumedRune = rune
                break
            end
        end
        if consumedRune then
            local start = atTime
            for slot = 1, RUNE_SLOTS, 1 do
                local rune = self.next.rune[slot]
                if rune.endCooldown > start then
                    start = rune.endCooldown
                end
            end
            local duration = 10 / self.ovalePaperDoll:GetSpellCastSpeedPercentMultiplier(snapshot)
            consumedRune.startCooldown = start
            consumedRune.endCooldown = start + duration
            local runicpower = (self.ovalePower.next.power.runicpower or 0) + 10
            local maxi = self.ovalePower.current.maxPower.runicpower
            self.ovalePower.next.power.runicpower = (runicpower < maxi) and runicpower or maxi
        end
        self.profiler:StopProfiling("OvaleRunes_state_ConsumeRune")
    end,
    RuneCount = function(self, atTime)
        self.profiler:StartProfiling("OvaleRunes_state_RuneCount")
        local state = self:GetState(atTime)
        local count = 0
        local startCooldown, endCooldown = huge, huge
        for slot = 1, RUNE_SLOTS, 1 do
            local rune = state.rune[slot]
            if IsActiveRune(rune, atTime) then
                count = count + 1
            elseif rune.endCooldown < endCooldown then
                startCooldown, endCooldown = rune.startCooldown, rune.endCooldown
            end
        end
        self.profiler:StopProfiling("OvaleRunes_state_RuneCount")
        return count, startCooldown, endCooldown
    end,
    RuneDeficit = function(self, atTime)
        self.profiler:StartProfiling("OvaleRunes_state_RuneDeficit")
        local state = self:GetState(atTime)
        local count = 0
        local startCooldown, endCooldown = huge, huge
        for slot = 1, RUNE_SLOTS, 1 do
            local rune = state.rune[slot]
            if  not IsActiveRune(rune, atTime) then
                count = count + 1
                if rune.endCooldown < endCooldown then
                    startCooldown, endCooldown = rune.startCooldown, rune.endCooldown
                end
            end
        end
        self.profiler:StopProfiling("OvaleRunes_state_RuneDeficit")
        return count, startCooldown, endCooldown
    end,
    GetRunesCooldown = function(self, atTime, runes)
        if runes <= 0 then
            return 0
        end
        if runes > RUNE_SLOTS then
            self.tracer:Log("Attempt to read %d runes but the maximum is %d", runes, RUNE_SLOTS)
            return 0
        end
        local state = self:GetState(atTime)
        self.profiler:StartProfiling("OvaleRunes_state_GetRunesCooldown")
        for slot = 1, RUNE_SLOTS, 1 do
            local rune = state.rune[slot]
            usedRune[slot] = rune.endCooldown - atTime
        end
        sort(usedRune)
        self.profiler:StopProfiling("OvaleRunes_state_GetRunesCooldown")
        return usedRune[runes]
    end,
})
