local __exports = LibStub:NewLibrary("ovale/CooldownState", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __State = LibStub:GetLibrary("ovale/State")
local baseState = __State.baseState
local OvaleState = __State.OvaleState
local __Cooldown = LibStub:GetLibrary("ovale/Cooldown")
local OvaleCooldown = __Cooldown.OvaleCooldown
local __DataState = LibStub:GetLibrary("ovale/DataState")
local dataState = __DataState.dataState
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local paperDollState = __PaperDoll.paperDollState
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
local __Aura = LibStub:GetLibrary("ovale/Aura")
local auraState = __Aura.auraState
local GetSpellCharges = GetSpellCharges
local sub = string.sub
local pairs = pairs
local COOLDOWN_THRESHOLD = 0.1
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
    RequireCooldownHandler = function(self, spellId, atTime, requirement, tokens, index, targetGUID)
        local cdSpellId = tokens
        local verified = false
        if index then
            cdSpellId = tokens[index]
            index = index + 1
        end
        if cdSpellId then
            local isBang = false
            if sub(cdSpellId, 1, 1) == "!" then
                isBang = true
                cdSpellId = sub(cdSpellId, 2)
            end
            local cd = self:GetCD(cdSpellId)
            verified =  not isBang and cd.duration > 0 or isBang and cd.duration <= 0
            local result = verified and "passed" or "FAILED"
            OvaleCooldown:Log("    Require spell %s %s cooldown at time=%f: %s (duration = %f)", cdSpellId, isBang and "OFF" or  not isBang and "ON", atTime, result, cd.duration)
        else
            Ovale:OneTimeMessage("Warning: requirement '%s' is missing a spell argument.", requirement)
        end
        return verified, requirement, index
    end,
    InitializeState = function(self)
        self.cd = {}
    end,
    ResetState = function(self)
        for _, cd in pairs(self.cd) do
            cd.serial = nil
        end
    end,
    CleanState = function(self)
        for spellId, cd in pairs(self.cd) do
            for k in pairs(cd) do
                cd[k] = nil
            end
            self.cd[spellId] = nil
        end
    end,
    ApplyCooldown = function(self, spellId, targetGUID, atTime)
        OvaleCooldown:StartProfiling("OvaleCooldown_state_ApplyCooldown")
        local cd = self:GetCD(spellId)
        local duration = self:GetSpellCooldownDuration(spellId, atTime, targetGUID)
        if duration == 0 then
            cd.start = 0
            cd.duration = 0
            cd.enable = 1
        else
            cd.start = atTime
            cd.duration = duration
            cd.enable = 1
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
        for spellId, cd in pairs(self.cd) do
            if cd.start then
                if cd.charges then
                    OvaleCooldown:Print("Spell %s cooldown: start=%f, duration=%f, charges=%d, maxCharges=%d, chargeStart=%f, chargeDuration=%f", spellId, cd.start, cd.duration, cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration)
                else
                    OvaleCooldown:Print("Spell %s cooldown: start=%f, duration=%f", spellId, cd.start, cd.duration)
                end
            end
        end
    end,
    GetCD = function(self, spellId)
        OvaleCooldown:StartProfiling("OvaleCooldown_state_GetCD")
        local cdName = spellId
        local si = OvaleData.spellInfo[spellId]
        if si and si.sharedcd then
            cdName = si.sharedcd
        end
        if  not self.cd[cdName] then
            self.cd[cdName] = {}
        end
        local cd = self.cd[cdName]
        if  not cd.start or  not cd.serial or cd.serial < OvaleCooldown.serial then
            local start, duration, enable = OvaleCooldown:GetSpellCooldown(spellId)
            if si and si.forcecd then
                start, duration = OvaleCooldown:GetSpellCooldown(si.forcecd)
            end
            cd.serial = OvaleCooldown.serial
            cd.start = start - COOLDOWN_THRESHOLD
            cd.duration = duration
            cd.enable = enable
            local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spellId)
            if charges then
                cd.charges = charges
                cd.maxCharges = maxCharges
                cd.chargeStart = chargeStart
                cd.chargeDuration = chargeDuration
            end
        end
        local now = baseState.currentTime
        if cd.start then
            if cd.start + cd.duration <= now then
                cd.start = 0
                cd.duration = 0
            end
        end
        if cd.charges then
            local charges, maxCharges, chargeStart, chargeDuration = cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration
            while chargeStart + chargeDuration <= now and charges < maxCharges do
                chargeStart = chargeStart + chargeDuration
                charges = charges + 1
            end
            cd.charges = charges
            cd.chargeStart = chargeStart
        end
        OvaleCooldown:StopProfiling("OvaleCooldown_state_GetCD")
        return cd
    end,
    GetSpellCooldown = function(self, spellId)
        local cd = self:GetCD(spellId)
        return cd.start, cd.duration, cd.enable
    end,
    GetSpellCooldownDuration = function(self, spellId, atTime, targetGUID)
        local start, duration = self:GetSpellCooldown(spellId)
        if duration > 0 and start + duration > atTime then
            OvaleCooldown:Log("Spell %d is on cooldown for %fs starting at %s.", spellId, duration, start)
        else
            local si = OvaleData.spellInfo[spellId]
            duration = dataState:GetSpellInfoProperty(spellId, atTime, "cd", targetGUID)
            if duration then
                if si and si.addcd then
                    duration = duration + si.addcd
                end
                if duration < 0 then
                    duration = 0
                end
            else
                duration = 0
            end
            OvaleCooldown:Log("Spell %d has a base cooldown of %fs.", spellId, duration)
            if duration > 0 then
                local haste = dataState:GetSpellInfoProperty(spellId, atTime, "cd_haste", targetGUID)
                local multiplier = paperDollState:GetHasteMultiplier(haste)
                duration = duration / multiplier
                if si and si.buff_cdr then
                    local aura = auraState:GetAura("player", si.buff_cdr)
                    if auraState:IsActiveAura(aura, atTime) then
                        duration = duration * aura.value1
                    end
                end
            end
        end
        return duration
    end,
    GetSpellCharges = function(self, spellId, atTime)
        atTime = atTime or baseState.currentTime
        local cd = self:GetCD(spellId)
        local charges, maxCharges, chargeStart, chargeDuration = cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration
        if charges then
            while chargeStart + chargeDuration <= atTime and charges < maxCharges do
                chargeStart = chargeStart + chargeDuration
                charges = charges + 1
            end
        end
        return charges, maxCharges, chargeStart, chargeDuration
    end,
    ResetSpellCooldown = function(self, spellId, atTime)
        local now = baseState.currentTime
        if atTime >= now then
            local cd = self:GetCD(spellId)
            if cd.start + cd.duration > now then
                cd.start = now
                cd.duration = atTime - now
            end
        end
    end,
    constructor = function(self)
        self.cd = nil
    end
})
__exports.cooldownState = CooldownState()
OvaleState:RegisterState(__exports.cooldownState)
