local __exports = LibStub:NewLibrary("ovale/Stagger", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local pairs = pairs
local insert = table.insert
local remove = table.remove
local __Future = LibStub:GetLibrary("ovale/Future")
local OvaleFuture = __Future.OvaleFuture
local OvaleStaggerBase = Ovale.NewModule("OvaleStagger", aceEvent)
local self_serial = 1
local MAX_LENGTH = 30
local OvaleStaggerClass = __class(OvaleStaggerBase, {
    OnInitialize = function(self)
        if Ovale.playerClass == "MONK" then
            self.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    OnDisable = function(self)
        if Ovale.playerClass == "MONK" then
            self.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, ...)
        local _, cleuEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, _, _, amount = CombatLogGetCurrentEventInfo()
        if sourceGUID ~= Ovale.playerGUID then
            return 
        end
        self_serial = self_serial + 1
        if cleuEvent == "SPELL_PERIODIC_DAMAGE" and spellId == 124255 then
            insert(self.staggerTicks, amount)
            if #self.staggerTicks > MAX_LENGTH then
                remove(self.staggerTicks, 1)
            end
        end
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
        if  not OvaleFuture.IsInCombat(nil) then
            for k in pairs(self.staggerTicks) do
                self.staggerTicks[k] = nil
            end
        end
    end,
    LastTickDamage = function(self, countTicks)
        if  not countTicks or countTicks == 0 or countTicks < 0 then
            countTicks = 1
        end
        local damage = 0
        local arrLen = #self.staggerTicks
        if arrLen < 1 then
            return 0
        end
        for i = arrLen, arrLen - (countTicks - 1), -1 do
            damage = damage + (self.staggerTicks[i] or 0)
        end
        return damage
    end,
    constructor = function(self, ...)
        OvaleStaggerBase.constructor(self, ...)
        self.staggerTicks = {}
    end
})
__exports.OvaleStagger = OvaleStaggerClass()
OvaleState.RegisterState(__exports.OvaleStagger)
