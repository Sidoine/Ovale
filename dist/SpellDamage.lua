local __exports = LibStub:NewLibrary("ovale/SpellDamage", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local CLEU_DAMAGE_EVENT = {
    SPELL_DAMAGE = true,
    SPELL_PERIODIC_AURA = true
}
__exports.OvaleSpellDamageClass = __class(nil, {
    constructor = function(self, ovale, ovaleProfiler)
        self.ovale = ovale
        self.value = {}
        self.OnInitialize = function()
            self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", self.COMBAT_LOG_EVENT_UNFILTERED)
        end
        self.OnDisable = function()
            self.module:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
        self.COMBAT_LOG_EVENT_UNFILTERED = function(event, ...)
            local _, cleuEvent, _, sourceGUID, _, _, _, _, _, _, _, arg12, _, _, arg15 = CombatLogGetCurrentEventInfo()
            if sourceGUID == self.ovale.playerGUID then
                self.profiler:StartProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED")
                if CLEU_DAMAGE_EVENT[cleuEvent] then
                    local spellId, amount = arg12, arg15
                    self.value[spellId] = amount
                    self.ovale:needRefresh()
                end
                self.profiler:StopProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED")
            end
        end
        self.module = ovale:createModule("OvaleSpellDamage", self.OnInitialize, self.OnDisable, aceEvent)
        self.profiler = ovaleProfiler:create(self.module:GetName())
    end,
    Get = function(self, spellId)
        return self.value[spellId]
    end,
})
