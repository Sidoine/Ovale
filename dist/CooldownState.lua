local __exports = LibStub:NewLibrary("ovale/CooldownState", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __Cooldown = LibStub:GetLibrary("ovale/Cooldown")
local OvaleCooldown = __Cooldown.OvaleCooldown
local pairs = pairs
local kpairs = pairs
local CooldownState = __class(nil, {
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        OvaleCooldown:StartProfiling("OvaleCooldown_ApplySpellStartCast")
        if isChanneled then
            self:ApplyCooldown(spellId, targetGUID, startCast)
        end
        OvaleCooldown:StopProfiling("OvaleCooldown_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        OvaleCooldown:StartProfiling("OvaleCooldown_ApplySpellAfterCast")
        if  not isChanneled then
            self:ApplyCooldown(spellId, targetGUID, endCast)
        end
        OvaleCooldown:StopProfiling("OvaleCooldown_ApplySpellAfterCast")
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
        OvaleCooldown:StartProfiling("OvaleCooldown_state_ApplyCooldown")
        local cd = OvaleCooldown:GetCD(spellId, atTime)
        local duration = OvaleCooldown:GetSpellCooldownDuration(spellId, atTime, targetGUID)
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
        OvaleCooldown:Log("Spell %d cooldown info: start=%f, duration=%f, charges=%s", spellId, cd.start, cd.duration, cd.charges or "(nil)")
        OvaleCooldown:StopProfiling("OvaleCooldown_state_ApplyCooldown")
    end,
    DebugCooldown = function(self)
        for spellId, cd in pairs(self.next.cd) do
            if cd.start then
                if cd.charges then
                    OvaleCooldown:Print("Spell %s cooldown: start=%f, duration=%f, charges=%d, maxCharges=%d, chargeStart=%f, chargeDuration=%f", spellId, cd.start, cd.duration, cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration)
                else
                    OvaleCooldown:Print("Spell %s cooldown: start=%f, duration=%f", spellId, cd.start, cd.duration)
                end
            end
        end
    end,
    constructor = function(self)
        self.next = OvaleCooldown.next
    end
})
__exports.cooldownState = CooldownState()
OvaleState:RegisterState(__exports.cooldownState)
