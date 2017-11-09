local __exports = LibStub:NewLibrary("ovale/SpellDamage", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local CLEU_DAMAGE_EVENT = {
    SPELL_DAMAGE = true,
    SPELL_PERIODIC_AURA = true
}
local OvaleSpellDamageBase = OvaleProfiler:RegisterProfiling(Ovale:NewModule("OvaleSpellDamage", aceEvent))
local OvaleSpellDamageClass = __class(OvaleSpellDamageBase, {
    constructor = function(self)
        self.value = {}
        OvaleSpellDamageBase.constructor(self)
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
        local arg12, _, _, arg15, _, _, _, _, _, _, _, _, _ = ...
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
})
__exports.OvaleSpellDamage = OvaleSpellDamageClass()
