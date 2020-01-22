local __exports = LibStub:NewLibrary("ovale/Stagger", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local pairs = pairs
local insert = table.insert
local remove = table.remove
local self_serial = 1
local MAX_LENGTH = 30
__exports.OvaleStaggerClass = __class(nil, {
    constructor = function(self, ovale, ovaleFuture)
        self.ovale = ovale
        self.ovaleFuture = ovaleFuture
        self.staggerTicks = {}
        self.OnInitialize = function()
            if self.ovale.playerClass == "MONK" then
                self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", self.COMBAT_LOG_EVENT_UNFILTERED)
            end
        end
        self.OnDisable = function()
            if self.ovale.playerClass == "MONK" then
                self.module:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            end
        end
        self.COMBAT_LOG_EVENT_UNFILTERED = function(event, ...)
            local _, cleuEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, _, _, amount = CombatLogGetCurrentEventInfo()
            if sourceGUID ~= self.ovale.playerGUID then
                return 
            end
            self_serial = self_serial + 1
            if cleuEvent == "SPELL_PERIODIC_DAMAGE" and spellId == 124255 then
                insert(self.staggerTicks, amount)
                if #self.staggerTicks > MAX_LENGTH then
                    remove(self.staggerTicks, 1)
                end
            end
        end
        self.module = ovale:createModule("OvaleStagger", self.OnInitialize, self.OnDisable, aceEvent)
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
        if  not self.ovaleFuture:IsInCombat(nil) then
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
})
