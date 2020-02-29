local __exports = LibStub:NewLibrary("ovale/CooldownState", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local pairs = pairs
local kpairs = pairs
__exports.CooldownState = __class(nil, {
    constructor = function(self, ovaleCooldown, ovaleProfiler, ovaleDebug)
        self.ovaleCooldown = ovaleCooldown
        self.profiler = ovaleProfiler:create("CooldownState")
        self.tracer = ovaleDebug:create("CooldownState")
        self.next = self.ovaleCooldown.next
    end,
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        self.profiler:StartProfiling("OvaleCooldown_ApplySpellStartCast")
        if isChanneled then
            self:ApplyCooldown(spellId, targetGUID, startCast)
        end
        self.profiler:StopProfiling("OvaleCooldown_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        self.profiler:StartProfiling("OvaleCooldown_ApplySpellAfterCast")
        if  not isChanneled then
            self:ApplyCooldown(spellId, targetGUID, endCast)
        end
        self.profiler:StopProfiling("OvaleCooldown_ApplySpellAfterCast")
    end,
    InitializeState = function(self)
        self.next.cd = {}
    end,
    ResetState = function(self)
        for _, cd in pairs(self.next.cd) do
            cd.serial = nil
        end
    end,
    CleanState = function(self)
        for spellId, cd in pairs(self.next.cd) do
            for k in kpairs(cd) do
                cd[k] = nil
            end
            self.next.cd[spellId] = nil
        end
    end,
    ApplyCooldown = function(self, spellId, targetGUID, atTime)
        self.profiler:StartProfiling("OvaleCooldown_state_ApplyCooldown")
        local cd = self.ovaleCooldown:GetCD(spellId, atTime)
        local duration = self.ovaleCooldown:GetSpellCooldownDuration(spellId, atTime, targetGUID)
        if duration == 0 then
            cd.start = 0
            cd.duration = 0
            cd.enable = true
        else
            cd.start = atTime
            cd.duration = duration
            cd.enable = true
        end
        if cd.charges and cd.charges > 0 then
            cd.chargeStart = cd.start
            cd.charges = cd.charges - 1
            if cd.charges == 0 then
                cd.duration = cd.chargeDuration
            end
        end
        self.tracer:Log("Spell %d cooldown info: start=%f, duration=%f, charges=%s", spellId, cd.start, cd.duration, cd.charges or "(nil)")
        self.profiler:StopProfiling("OvaleCooldown_state_ApplyCooldown")
    end,
    DebugCooldown = function(self)
        for spellId, cd in pairs(self.next.cd) do
            if cd.start then
                if cd.charges then
                    self.tracer:Print("Spell %s cooldown: start=%f, duration=%f, charges=%d, maxCharges=%d, chargeStart=%f, chargeDuration=%f", spellId, cd.start, cd.duration, cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration)
                else
                    self.tracer:Print("Spell %s cooldown: start=%f, duration=%f", spellId, cd.start, cd.duration)
                end
            end
        end
    end,
})
