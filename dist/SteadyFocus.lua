local __exports = LibStub:NewLibrary("ovale/SteadyFocus", 10000)
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
local auraState = __Aura.auraState
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local GetTime = GetTime
local huge = math.huge
local OvaleSteadyFocusBase = OvaleDebug:RegisterDebugging(OvaleProfiler:RegisterProfiling(Ovale:NewModule("OvaleSteadyFocus", aceEvent)))
local INFINITY = huge
local self_playerGUID = nil
local PRE_STEADY_FOCUS = 177667
local STEADY_FOCUS_TALENT = 10
local STEADY_FOCUS = 177668
local STEADY_FOCUS_DURATION = 15
local STEADY_SHOT = {
    [56641] = "Steady Shot",
    [77767] = "Cobra Shot",
    [163485] = "Focusing Shot"
}
local RANGED_ATTACKS = {
    [2643] = "Multi-Shot",
    [3044] = "Arcane Shot",
    [19434] = "Aimed Shot",
    [19801] = "Tranquilizing Shot",
    [53209] = "Chimaera Shot",
    [53351] = "Kill Shot",
    [109259] = "Powershot",
    [117050] = "Glaive Toss",
    [120360] = "Barrage",
    [120361] = "Barrage",
    [120761] = "Glaive Toss",
    [121414] = "Glaive Toss"
}
local OvaleSteadyFocusClass = __class(OvaleSteadyFocusBase, {
    OnInitialize = function(self)
        if Ovale.playerClass == "HUNTER" then
            self_playerGUID = Ovale.playerGUID
            self:RegisterMessage("Ovale_TalentsChanged")
        end
    end,
    OnDisable = function(self)
        if Ovale.playerClass == "HUNTER" then
            self:UnregisterMessage("Ovale_TalentsChanged")
        end
    end,
    UNIT_SPELLCAST_SUCCEEDED = function(self, event, unitId, spell, rank, lineId, spellId)
        if unitId == "player" then
            self:StartProfiling("OvaleSteadyFocus_UNIT_SPELLCAST_SUCCEEDED")
            if STEADY_SHOT[spellId] then
                self:DebugTimestamp("Spell %s (%d) successfully cast.", spell, spellId)
                if self.stacks == 0 then
                    local now = GetTime()
                    self:GainedAura(now)
                end
            elseif RANGED_ATTACKS[spellId] and self.stacks > 0 then
                local now = GetTime()
                self:DebugTimestamp("Spell %s (%d) successfully cast.", spell, spellId)
                self:LostAura(now)
            end
            self:StopProfiling("OvaleSteadyFocus_UNIT_SPELLCAST_SUCCEEDED")
        end
    end,
    Ovale_AuraAdded = function(self, event, timestamp, target, auraId, caster)
        if self.stacks > 0 and auraId == STEADY_FOCUS and target == self_playerGUID then
            self:DebugTimestamp("Gained Steady Focus buff.")
            self:LostAura(timestamp)
        end
    end,
    Ovale_TalentsChanged = function(self, event)
        self.hasSteadyFocus = (OvaleSpellBook:GetTalentPoints(STEADY_FOCUS_TALENT) > 0)
        if self.hasSteadyFocus then
            self:Debug("Registering event handlers to track Steady Focus.")
            self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            self:RegisterMessage("Ovale_AuraAdded")
            self:RegisterMessage("Ovale_AuraChanged", "Ovale_AuraAdded")
        else
            self:Debug("Unregistering event handlers to track Steady Focus.")
            self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            self:UnregisterMessage("Ovale_AuraAdded")
            self:UnregisterMessage("Ovale_AuraChanged")
        end
    end,
    GainedAura = function(self, atTime)
        self:StartProfiling("OvaleSteadyFocus_GainedAura")
        self.start = atTime
        self.ending = self.start + self.duration
        self.stacks = self.stacks + 1
        self:Debug("Gaining %s buff at %s.", self.spellName, atTime)
        OvaleAura:GainedAuraOnGUID(self_playerGUID, self.start, self.spellId, self_playerGUID, "HELPFUL", nil, nil, self.stacks, nil, self.duration, self.ending, nil, self.spellName, nil, nil, nil)
        self:StopProfiling("OvaleSteadyFocus_GainedAura")
    end,
    LostAura = function(self, atTime)
        self:StartProfiling("OvaleSteadyFocus_LostAura")
        self.ending = atTime
        self.stacks = 0
        self:Debug("Losing %s buff at %s.", self.spellName, atTime)
        OvaleAura:LostAuraOnGUID(self_playerGUID, atTime, self.spellId, self_playerGUID)
        self:StopProfiling("OvaleSteadyFocus_LostAura")
    end,
    DebugSteadyFocus = function(self)
        local aura = OvaleAura:GetAuraByGUID(self_playerGUID, self.spellId, "HELPFUL", true)
        if aura then
            self:Print("Player has pre-Steady Focus aura with start=%s, end=%s, stacks=%d.", aura.start, aura.ending, aura.stacks)
        else
            self:Print("Player has no pre-Steady Focus aura!")
        end
    end,
    constructor = function(self, ...)
        OvaleSteadyFocusBase.constructor(self, ...)
        self.hasSteadyFocus = nil
        self.spellName = "Pre-Steady Focus"
        self.spellId = PRE_STEADY_FOCUS
        self.start = 0
        self.ending = 0
        self.duration = INFINITY
        self.stacks = 0
    end
})
local SteadyFocusState = __class(nil, {
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        if __exports.OvaleSteadyFocus.hasSteadyFocus then
            __exports.OvaleSteadyFocus:StartProfiling("OvaleSteadyFocus_ApplySpellAfterCast")
            if STEADY_SHOT[spellId] then
                local aura = auraState:GetAuraByGUID(self_playerGUID, __exports.OvaleSteadyFocus.spellId, "HELPFUL", true)
                if auraState:IsActiveAura(aura, endCast) then
                    auraState:RemoveAuraOnGUID(self_playerGUID, __exports.OvaleSteadyFocus.spellId, "HELPFUL", true, endCast)
                    aura = auraState:GetAuraByGUID(self_playerGUID, STEADY_FOCUS, "HELPFUL", true)
                    if  not aura then
                        aura = auraState:AddAuraToGUID(self_playerGUID, STEADY_FOCUS, self_playerGUID, "HELPFUL", nil, endCast, nil, spellcast)
                    end
                    aura.start = endCast
                    aura.duration = STEADY_FOCUS_DURATION
                    aura.ending = endCast + STEADY_FOCUS_DURATION
                    aura.gain = endCast
                else
                    local ending = endCast + __exports.OvaleSteadyFocus.duration
                    aura = auraState:AddAuraToGUID(self_playerGUID, __exports.OvaleSteadyFocus.spellId, self_playerGUID, "HELPFUL", nil, endCast, ending, spellcast)
                    aura.name = __exports.OvaleSteadyFocus.spellName
                end
            elseif RANGED_ATTACKS[spellId] then
                auraState:RemoveAuraOnGUID(self_playerGUID, __exports.OvaleSteadyFocus.spellId, "HELPFUL", true, endCast)
            end
            __exports.OvaleSteadyFocus:StopProfiling("OvaleSteadyFocus_ApplySpellAfterCast")
        end
    end,
})
__exports.steadyFocusState = SteadyFocusState()
OvaleState:RegisterState(__exports.steadyFocusState)
__exports.OvaleSteadyFocus = OvaleSteadyFocusClass()
