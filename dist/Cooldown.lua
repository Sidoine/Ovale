local __exports = LibStub:NewLibrary("ovale/Cooldown", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __LastSpell = LibStub:GetLibrary("ovale/LastSpell")
local lastSpell = __LastSpell.lastSpell
local __Requirement = LibStub:GetLibrary("ovale/Requirement")
local RegisterRequirement = __Requirement.RegisterRequirement
local UnregisterRequirement = __Requirement.UnregisterRequirement
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local next = next
local pairs = pairs
local GetSpellCooldown = GetSpellCooldown
local GetTime = GetTime
local GetSpellCharges = GetSpellCharges
local sub = string.sub
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local GLOBAL_COOLDOWN = 61304
local COOLDOWN_THRESHOLD = 0.1
local BASE_GCD = {
    ["DEATHKNIGHT"] = {
        [1] = 1.5,
        [2] = "melee"
    },
    ["DEMONHUNTER"] = {
        [1] = 1.5,
        [2] = "melee"
    },
    ["DRUID"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["HUNTER"] = {
        [1] = 1.5,
        [2] = "ranged"
    },
    ["MAGE"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["MONK"] = {
        [1] = 1,
        [2] = false
    },
    ["PALADIN"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["PRIEST"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["ROGUE"] = {
        [1] = 1,
        [2] = false
    },
    ["SHAMAN"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["WARLOCK"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["WARRIOR"] = {
        [1] = 1.5,
        [2] = "melee"
    }
}
__exports.CooldownData = __class(nil, {
    constructor = function(self)
        self.cd = nil
    end
})
local OvaleCooldownBase = OvaleState:RegisterHasState(OvaleDebug:RegisterDebugging(OvaleProfiler:RegisterProfiling(Ovale:NewModule("OvaleCooldown", aceEvent))), __exports.CooldownData)
local OvaleCooldownClass = __class(OvaleCooldownBase, {
    OnInitialize = function(self)
        self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", "Update")
        self:RegisterEvent("BAG_UPDATE_COOLDOWN", "Update")
        self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN", "Update")
        self:RegisterEvent("SPELL_UPDATE_CHARGES", "Update")
        self:RegisterEvent("SPELL_UPDATE_USABLE", "Update")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "Update")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "Update")
        self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        self:RegisterEvent("UNIT_SPELLCAST_START", "Update")
        self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "Update")
        self:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", "Update")
        lastSpell:RegisterSpellcastInfo(self)
        RegisterRequirement("oncooldown", self.RequireCooldownHandler)
    end,
    OnDisable = function(self)
        lastSpell:UnregisterSpellcastInfo(self)
        UnregisterRequirement("oncooldown")
        self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
        self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
        self:UnregisterEvent("PET_BAR_UPDATE_COOLDOWN")
        self:UnregisterEvent("SPELL_UPDATE_CHARGES")
        self:UnregisterEvent("SPELL_UPDATE_USABLE")
        self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        self:UnregisterEvent("UNIT_SPELLCAST_START")
        self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        self:UnregisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
    end,
    UNIT_SPELLCAST_INTERRUPTED = function(self, event, unit, lineId, spellId)
        if unit == "player" or unit == "pet" then
            self:Update(event, unit)
            self:Debug("Resetting global cooldown.")
            local cd = self.gcd
            cd.start = 0
            cd.duration = 0
        end
    end,
    Update = function(self, event, unit)
        if  not unit or unit == "player" or unit == "pet" then
            self.serial = self.serial + 1
            Ovale:needRefresh()
            self:Debug(event, self.serial)
        end
    end,
    ResetSharedCooldowns = function(self)
        for _, spellTable in pairs(self.sharedCooldown) do
            for spellId in pairs(spellTable) do
                spellTable[spellId] = nil
            end
        end
    end,
    IsSharedCooldown = function(self, name)
        local spellTable = self.sharedCooldown[name]
        return (spellTable and next(spellTable) ~= nil)
    end,
    AddSharedCooldown = function(self, name, spellId)
        self.sharedCooldown[name] = self.sharedCooldown[name] or {}
        self.sharedCooldown[name][spellId] = true
    end,
    GetGlobalCooldown = function(self, now)
        local cd = self.gcd
        if  not cd.start or  not cd.serial or cd.serial < self.serial then
            now = now or GetTime()
            if now >= cd.start + cd.duration then
                cd.start, cd.duration = GetSpellCooldown(GLOBAL_COOLDOWN)
            end
        end
        return cd.start, cd.duration
    end,
    GetSpellCooldown = function(self, spellId, atTime)
        if atTime then
            local cd = self:GetCD(spellId, atTime)
            return cd.start, cd.duration, cd.enable
        end
        local cdStart, cdDuration, cdEnable = 0, 0, 1
        if self.sharedCooldown[spellId] then
            for id in pairs(self.sharedCooldown[spellId]) do
                local start, duration, enable = self:GetSpellCooldown(id, atTime)
                if start then
                    cdStart, cdDuration, cdEnable = start, duration, enable
                    break
                end
            end
        else
            local start, duration, enable
            local index, bookType = OvaleSpellBook:GetSpellBookIndex(spellId)
            if index and bookType then
                start, duration, enable = GetSpellCooldown(index, bookType)
            else
                start, duration, enable = GetSpellCooldown(spellId)
            end
            self:Log("Call GetSpellCooldown which returned %f, %f, %d", start, duration, enable)
            if start and start > 0 then
                local gcdStart, gcdDuration = self:GetGlobalCooldown()
                self:Log("GlobalCooldown is %d, %d", gcdStart, gcdDuration)
                if start + duration > gcdStart + gcdDuration then
                    cdStart, cdDuration, cdEnable = start, duration, enable
                else
                    cdStart = start + duration
                    cdDuration = 0
                    cdEnable = enable
                end
            else
                cdStart, cdDuration, cdEnable = start or 0, duration, enable
            end
        end
        return cdStart - COOLDOWN_THRESHOLD, cdDuration, cdEnable
    end,
    GetBaseGCD = function(self)
        local gcd, haste
        local baseGCD = BASE_GCD[Ovale.playerClass]
        if baseGCD then
            gcd, haste = baseGCD[1], baseGCD[2]
        else
            gcd, haste = 1.5, "spell"
        end
        return gcd, haste
    end,
    GetCD = function(self, spellId, atTime)
        __exports.OvaleCooldown:StartProfiling("OvaleCooldown_state_GetCD")
        local cdName = spellId
        local si = OvaleData.spellInfo[spellId]
        if si and si.shared_cd then
            cdName = si.shared_cd
        end
        if  not self.next.cd[cdName] then
            self.next.cd[cdName] = {}
        end
        local cd = self.next.cd[cdName]
        if  not cd.start or  not cd.serial or cd.serial < self.serial then
            self:Log("Didn't find an existing cd in next, look for one in current")
            local start, duration, enable = self:GetSpellCooldown(spellId, nil)
            if si and si.forcecd then
                start, duration = self:GetSpellCooldown(si.forcecd, nil)
            end
            self:Log("It returned %f, %f", start, duration)
            cd.serial = self.serial
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
        local now = atTime
        if cd.start then
            if cd.start + cd.duration <= now then
                self:Log("Spell cooldown is in the past")
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
        self:Log("Cooldown of spell %d is %f + %f", spellId, cd.start, cd.duration)
        self:StopProfiling("OvaleCooldown_state_GetCD")
        return cd
    end,
    GetSpellCooldownDuration = function(self, spellId, atTime, targetGUID)
        local start, duration = self:GetSpellCooldown(spellId, atTime)
        if duration > 0 and start + duration > atTime then
            __exports.OvaleCooldown:Log("Spell %d is on cooldown for %fs starting at %s.", spellId, duration, start)
        else
            local si = OvaleData.spellInfo[spellId]
            duration = OvaleData:GetSpellInfoPropertyNumber(spellId, atTime, "cd", targetGUID)
            if duration then
                if duration < 0 then
                    duration = 0
                end
            else
                duration = 0
            end
            __exports.OvaleCooldown:Log("Spell %d has a base cooldown of %fs.", spellId, duration)
            if duration > 0 then
                local haste = OvaleData:GetSpellInfoProperty(spellId, atTime, "cd_haste", targetGUID)
                local multiplier = OvalePaperDoll:GetHasteMultiplier(haste, OvalePaperDoll.next)
                duration = duration / multiplier
                if si and si.buff_cdr then
                    local aura = OvaleAura:GetAura("player", si.buff_cdr, atTime)
                    if OvaleAura:IsActiveAura(aura, atTime) then
                        duration = duration * aura.value1
                    end
                end
            end
        end
        return duration
    end,
    GetSpellCharges = function(self, spellId, atTime)
        local cd = self:GetCD(spellId, atTime)
        local charges, maxCharges, chargeStart, chargeDuration = cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration
        if charges then
            while chargeStart + chargeDuration <= atTime and charges < maxCharges do
                chargeStart = chargeStart + chargeDuration
                charges = charges + 1
            end
        end
        return charges, maxCharges, chargeStart, chargeDuration
    end,
    constructor = function(self, ...)
        OvaleCooldownBase.constructor(self, ...)
        self.serial = 0
        self.sharedCooldown = {}
        self.gcd = {
            serial = 0,
            start = 0,
            duration = 0
        }
        self.CopySpellcastInfo = function(mod, spellcast, dest)
            if spellcast.offgcd then
                dest.offgcd = spellcast.offgcd
            end
        end
        self.SaveSpellcastInfo = function(mod, spellcast, atTime, state)
            local spellId = spellcast.spellId
            if spellId then
                local gcd
                gcd = OvaleData:GetSpellInfoProperty(spellId, spellcast.start, "gcd", spellcast.target)
                if gcd and gcd == 0 then
                    spellcast.offgcd = true
                end
            end
        end
        self.RequireCooldownHandler = function(spellId, atTime, requirement, tokens, index, targetGUID)
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
                local cd = self:GetCD(cdSpellId, atTime)
                verified =  not isBang and cd.duration > 0 or isBang and cd.duration <= 0
                local result = verified and "passed" or "FAILED"
                self:Log("    Require spell %s %s cooldown at time=%f: %s (duration = %f)", cdSpellId, isBang and "OFF" or  not isBang and "ON", atTime, result, cd.duration)
            else
                Ovale:OneTimeMessage("Warning: requirement '%s' is missing a spell argument.", requirement)
            end
            return verified, requirement, index
        end
    end
})
__exports.OvaleCooldown = OvaleCooldownClass()
