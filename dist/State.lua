local __exports = LibStub:NewLibrary("ovale/State", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Queue = LibStub:GetLibrary("ovale/Queue")
local OvaleQueue = __Queue.OvaleQueue
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local OvaleStateBase = Ovale:NewModule("OvaleState")
local self_stateAddons = OvaleQueue("OvaleState_stateAddons")
local OvaleStateBaseClass = OvaleDebug:RegisterDebugging(OvaleStateBase)
local OvaleStateClass = __class(OvaleStateBaseClass, {
    RegisterHasState = function(self, Base, ctor)
        return __class(Base, {
            GetState = function(self, atTime)
                if  not atTime then
                    return self.current
                end
                return self.next
            end,
            constructor = function(self, ...)
                Base.constructor(self, ...)
                self.current = ctor()
                self.next = ctor()
            end
        })
    end,
    RegisterState = function(self, stateAddon)
        self_stateAddons:Insert(stateAddon)
    end,
    UnregisterState = function(self, stateAddon)
        local stateModules = OvaleQueue("OvaleState_stateModules")
        while self_stateAddons:Size() > 0 do
            local addon = self_stateAddons:Remove()
            if stateAddon ~= addon then
                stateModules:Insert(addon)
            end
        end
        self_stateAddons = stateModules
        stateAddon:CleanState()
    end,
    InitializeState = function(self)
        local iterator = self_stateAddons:Iterator()
        while iterator:Next() do
            iterator.value:InitializeState()
        end
    end,
    ResetState = function(self)
        local iterator = self_stateAddons:Iterator()
        while iterator:Next() do
            iterator.value:ResetState()
        end
    end,
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        local iterator = self_stateAddons:Iterator()
        while iterator:Next() do
            if iterator.value.ApplySpellStartCast then
                iterator.value:ApplySpellStartCast(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
        end
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        local iterator = self_stateAddons:Iterator()
        while iterator:Next() do
            if iterator.value.ApplySpellAfterCast then
                iterator.value:ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
        end
    end,
    ApplySpellOnHit = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        local iterator = self_stateAddons:Iterator()
        while iterator:Next() do
            if iterator.value.ApplySpellOnHit then
                iterator.value:ApplySpellOnHit(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
        end
    end,
})
__exports.OvaleState = OvaleStateClass()
