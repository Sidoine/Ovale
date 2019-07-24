local __exports = LibStub:NewLibrary("ovale/LastSpell", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Pool = LibStub:GetLibrary("ovale/Pool")
local OvalePool = __Pool.OvalePool
local pairs = pairs
local remove = table.remove
local insert = table.insert
__exports.self_pool = OvalePool("OvaleFuture_pool")
__exports.LastSpell = __class(nil, {
    LastInFlightSpell = function(self)
        local spellcast = nil
        if self.lastGCDSpellcast.success then
            spellcast = self.lastGCDSpellcast
        end
        for i = #self.queue, 1, -1 do
            local sc = self.queue[i]
            if sc.success then
                if spellcast == nil or (spellcast.success < sc.success) then
                    spellcast = sc
                end
                break
            end
        end
        return spellcast
    end,
    CopySpellcastInfo = function(self, spellcast, dest)
        if spellcast.damageMultiplier then
            dest.damageMultiplier = spellcast.damageMultiplier
        end
        for _, mod in pairs(self.modules) do
            local func = mod.CopySpellcastInfo
            if func then
                func(mod, spellcast, dest)
            end
        end
    end,
    RegisterSpellcastInfo = function(self, mod)
        insert(self.modules, mod)
    end,
    UnregisterSpellcastInfo = function(self, mod)
        for i = #self.modules, 1, -1 do
            if self.modules[i] == mod then
                remove(self.modules, i)
            end
        end
    end,
    LastSpellSent = function(self)
        local spellcast = nil
        if self.lastGCDSpellcast.success then
            spellcast = self.lastGCDSpellcast
        end
        for i = #self.queue, 1, -1 do
            local sc = self.queue[i]
            if sc.success then
                if  not spellcast or (spellcast.success and spellcast.success < sc.success) or ( not spellcast.success and spellcast.queued and spellcast.queued < sc.success) then
                    spellcast = sc
                end
            elseif  not sc.start and  not sc.stop and sc.queued then
                if  not spellcast or (spellcast.success and spellcast.success < sc.queued) then
                    spellcast = sc
                elseif spellcast.queued and spellcast.queued < sc.queued then
                    spellcast = sc
                end
            end
        end
        return spellcast
    end,
    constructor = function(self)
        self.lastSpellcast = nil
        self.lastGCDSpellcast = {
            spellId = 0
        }
        self.queue = {}
        self.modules = {}
    end
})
