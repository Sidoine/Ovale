local __exports = LibStub:NewLibrary("ovale/Runes", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
local __Power = LibStub:GetLibrary("ovale/Power")
local OvalePower = __Power.OvalePower
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ipairs = ipairs
local wipe = wipe
local GetRuneCooldown = GetRuneCooldown
local GetTime = GetTime
local huge = math.huge
local sort = table.sort
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local EMPOWER_RUNE_WEAPON = 47568
local RUNE_SLOTS = 6
local IsActiveRune = function(rune, atTime)
    return (rune.startCooldown == 0 or rune.endCooldown <= atTime)
end

local RuneData = __class(nil, {
    constructor = function(self)
        self.rune = {}
        self.runicpower = nil
    end
})
local usedRune = {}
local OvaleRunesBase = OvaleState:RegisterHasState(OvaleDebug:RegisterDebugging(OvaleProfiler:RegisterProfiling(Ovale:NewModule("OvaleRunes", aceEvent))), RuneData)
local OvaleRunesClass = __class(OvaleRunesBase, {
    OnInitialize = function(self)
        if Ovale.playerClass == "DEATHKNIGHT" then
            for slot = 1, RUNE_SLOTS, 1 do
                self.current.rune[slot] = {}
            end
            self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAllRunes")
            self:RegisterEvent("RUNE_POWER_UPDATE")
            self:RegisterEvent("RUNE_TYPE_UPDATE")
            self:RegisterEvent("UNIT_RANGEDDAMAGE")
            self:RegisterEvent("UNIT_SPELL_HASTE", "UNIT_RANGEDDAMAGE")
            if Ovale.playerGUID then
                self:UpdateAllRunes()
            end
        end
    end,
    OnDisable = function(self)
        if Ovale.playerClass == "DEATHKNIGHT" then
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self:UnregisterEvent("RUNE_POWER_UPDATE")
            self:UnregisterEvent("RUNE_TYPE_UPDATE")
            self:UnregisterEvent("UNIT_RANGEDDAMAGE")
            self:UnregisterEvent("UNIT_SPELL_HASTE")
            self.current.rune = {}
        end
    end,
    RUNE_POWER_UPDATE = function(self, event, slot, usable)
        self:Debug(event, slot, usable)
        self:UpdateRune(slot)
    end,
    RUNE_TYPE_UPDATE = function(self, event, slot)
        self:Debug(event, slot)
        self:UpdateRune(slot)
    end,
    UNIT_RANGEDDAMAGE = function(self, event, unitId)
        if unitId == "player" then
            self:Debug(event)
            self:UpdateAllRunes()
        end
    end,
    UpdateRune = function(self, slot)
        self:StartProfiling("OvaleRunes_UpdateRune")
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
            Ovale:needRefresh()
        else
            self:Debug("Warning: rune information for slot %d not available.", slot)
        end
        self:StopProfiling("OvaleRunes_UpdateRune")
    end,
    UpdateAllRunes = function(self)
        for slot = 1, RUNE_SLOTS, 1 do
            self:UpdateRune(slot)
        end
    end,
    DebugRunes = function(self)
        local now = GetTime()
        for slot = 1, RUNE_SLOTS, 1 do
            local rune = self.current.rune[slot]
            if IsActiveRune(rune, now) then
                self:Print("rune[%d] is active.", slot)
            else
                self:Print("rune[%d] comes off cooldown in %f seconds.", slot, rune.endCooldown - now)
            end
        end
    end,
    InitializeState = function(self)
        self.next.rune = {}
        for slot in ipairs(self.current.rune) do
            self.next.rune[slot] = {}
        end
    end,
    ResetState = function(self)
        __exports.OvaleRunes:StartProfiling("OvaleRunes_ResetState")
        for slot, rune in ipairs(self.current.rune) do
            local stateRune = self.next.rune[slot]
            stateRune.endCooldown = rune.endCooldown
            stateRune.startCooldown = rune.startCooldown
        end
        __exports.OvaleRunes:StopProfiling("OvaleRunes_ResetState")
    end,
    CleanState = function(self)
        for slot, rune in ipairs(self.next.rune) do
            wipe(rune)
            self.next.rune[slot] = nil
        end
    end,
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvaleRunes:StartProfiling("OvaleRunes_ApplySpellStartCast")
        if isChanneled then
            self:ApplyRuneCost(spellId, startCast, spellcast)
        end
        __exports.OvaleRunes:StopProfiling("OvaleRunes_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvaleRunes:StartProfiling("OvaleRunes_ApplySpellAfterCast")
        if  not isChanneled then
            self:ApplyRuneCost(spellId, endCast, spellcast)
            if spellId == EMPOWER_RUNE_WEAPON then
                for slot in ipairs(self.next.rune) do
                    self:ReactivateRune(slot, endCast)
                end
            end
        end
        __exports.OvaleRunes:StopProfiling("OvaleRunes_ApplySpellAfterCast")
    end,
    ApplyRuneCost = function(self, spellId, atTime, spellcast)
        local si = OvaleData.spellInfo[spellId]
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
        __exports.OvaleRunes:StartProfiling("OvaleRunes_state_ConsumeRune")
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
            local duration = 10 / OvalePaperDoll:GetSpellHasteMultiplier(snapshot)
            consumedRune.startCooldown = start
            consumedRune.endCooldown = start + duration
            local runicpower = self.next.runicpower
            runicpower = runicpower + 10
            local maxi = OvalePower.current.maxPower.runicpower
            self.next.runicpower = (runicpower < maxi) and runicpower or maxi
        end
        self:StopProfiling("OvaleRunes_state_ConsumeRune")
    end,
    RuneCount = function(self, atTime)
        self:StartProfiling("OvaleRunes_state_RuneCount")
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
        self:StopProfiling("OvaleRunes_state_RuneCount")
        return count, startCooldown, endCooldown
    end,
    GetRunesCooldown = function(self, atTime, runes)
        if runes <= 0 then
            return 0
        end
        if runes > RUNE_SLOTS then
            __exports.OvaleRunes:Log("Attempt to read %d runes but the maximum is %d", runes, RUNE_SLOTS)
            return 0
        end
        local state = self:GetState(atTime)
        __exports.OvaleRunes:StartProfiling("OvaleRunes_state_GetRunesCooldown")
        for slot = 1, RUNE_SLOTS, 1 do
            local rune = state.rune[slot]
            usedRune[slot] = rune.endCooldown - atTime
        end
        sort(usedRune)
        self:StopProfiling("OvaleRunes_state_GetRunesCooldown")
        return usedRune[runes]
    end,
})
__exports.OvaleRunes = OvaleRunesClass()
OvaleState:RegisterState(__exports.OvaleRunes)
