local __exports = LibStub:NewLibrary("ovale/SpellDamage", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local CLEU_DAMAGE_EVENT = {
    SPELL_DAMAGE = true,
    SPELL_PERIODIC_AURA = true
}
local OvaleSpellDamageBase = OvaleProfiler:RegisterProfiling(Ovale:NewModule("OvaleSpellDamage", aceEvent))
local OvaleSpellDamageClass = __class(OvaleSpellDamageBase, {
    OnInitialize = function(self)
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, ...)
        local _, cleuEvent, _, sourceGUID, _, _, _, _, _, _, _, arg12, _, _, arg15 = CombatLogGetCurrentEventInfo()
        if sourceGUID == Ovale.playerGUID then
            self:StartProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED")
            if CLEU_DAMAGE_EVENT[cleuEvent] then
                local spellId, amount = arg12, arg15
                self.value[spellId] = amount
                Ovale:needRefresh()
            end
            self:StopProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    Get = function(self, spellId)
        return self.value[spellId]
    end,
    constructor = function(self, ...)
        OvaleSpellDamageBase.constructor(self, ...)
        self.value = {}
    end
})
__exports.OvaleSpellDamage = OvaleSpellDamageClass()
