local __exports = LibStub:NewLibrary("ovale/engine/state", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __toolsQueue = LibStub:GetLibrary("ovale/tools/Queue")
local OvaleQueue = __toolsQueue.OvaleQueue
__exports.States = __class(nil, {
    constructor = function(self, c)
        self.current = c()
        self.next = c()
    end,
    GetState = function(self, atTime)
        if  not atTime then
            return self.current
        end
        return self.next
    end,
})
__exports.OvaleStateClass = __class(nil, {
    RegisterState = function(self, stateAddon)
        self.self_stateAddons:Insert(stateAddon)
    end,
    UnregisterState = function(self, stateAddon)
        local stateModules = OvaleQueue("OvaleState_stateModules")
        while self.self_stateAddons:Size() > 0 do
            local addon = self.self_stateAddons:Remove()
            if stateAddon ~= addon then
                stateModules:Insert(addon)
            end
        end
        self.self_stateAddons = stateModules
        stateAddon:CleanState()
    end,
    InitializeState = function(self)
        local iterator = self.self_stateAddons:Iterator()
        while iterator:Next() do
            iterator.value:InitializeState()
        end
    end,
    ResetState = function(self)
        local iterator = self.self_stateAddons:Iterator()
        while iterator:Next() do
            iterator.value:ResetState()
        end
    end,
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        local iterator = self.self_stateAddons:Iterator()
        while iterator:Next() do
            if iterator.value.ApplySpellStartCast then
                iterator.value.ApplySpellStartCast(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
        end
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        local iterator = self.self_stateAddons:Iterator()
        while iterator:Next() do
            if iterator.value.ApplySpellAfterCast then
                iterator.value.ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
        end
    end,
    ApplySpellOnHit = function(self, spellId, targetGUID, startCast, endCast, channel, spellcast)
        local iterator = self.self_stateAddons:Iterator()
        while iterator:Next() do
            if iterator.value.ApplySpellOnHit then
                iterator.value.ApplySpellOnHit(spellId, targetGUID, startCast, endCast, channel, spellcast)
            end
        end
    end,
    constructor = function(self)
        self.self_stateAddons = OvaleQueue("OvaleState_stateAddons")
    end
})