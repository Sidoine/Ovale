local __exports = LibStub:NewLibrary("ovale/states/Cooldown", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local next = next
local pairs = pairs
local kpairs = pairs
local GetSpellCooldown = GetSpellCooldown
local GetTime = GetTime
local GetSpellCharges = GetSpellCharges
local __State = LibStub:GetLibrary("ovale/State")
local States = __State.States
local GLOBAL_COOLDOWN = 61304
local COOLDOWN_THRESHOLD = 0.1
local BASE_GCD = {
    ["DEATHKNIGHT"] = {
        [1] = 1.5,
        [2] = "base"
    },
    ["DEMONHUNTER"] = {
        [1] = 1.5,
        [2] = "base"
    },
    ["DRUID"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["HUNTER"] = {
        [1] = 1.5,
        [2] = "base"
    },
    ["MAGE"] = {
        [1] = 1.5,
        [2] = "spell"
    },
    ["MONK"] = {
        [1] = 1,
        [2] = "none"
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
        [2] = "none"
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
        [2] = "base"
    }
}
__exports.CooldownData = __class(nil, {
    constructor = function(self)
        self.cd = {}
    end
})
__exports.OvaleCooldownClass = __class(States, {
    constructor = function(self, ovalePaperDoll, ovaleData, lastSpell, ovale, ovaleDebug, ovaleProfiler, ovaleSpellBook)
        self.ovalePaperDoll = ovalePaperDoll
        self.ovaleData = ovaleData
        self.lastSpell = lastSpell
        self.ovale = ovale
        self.ovaleSpellBook = ovaleSpellBook
        self.serial = 0
        self.sharedCooldown = {}
        self.gcd = {
            serial = 0,
            start = 0,
            duration = 0
        }
        self.OnInitialize = function()
            self.module:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", self.Update)
            self.module:RegisterEvent("BAG_UPDATE_COOLDOWN", self.Update)
            self.module:RegisterEvent("PET_BAR_UPDATE_COOLDOWN", self.Update)
            self.module:RegisterEvent("SPELL_UPDATE_CHARGES", self.Update)
            self.module:RegisterEvent("SPELL_UPDATE_USABLE", self.Update)
            self.module:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", self.Update)
            self.module:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", self.Update)
            self.module:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", self.UNIT_SPELLCAST_INTERRUPTED)
            self.module:RegisterEvent("UNIT_SPELLCAST_START", self.Update)
            self.module:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", self.Update)
            self.module:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", self.Update)
            self.lastSpell:RegisterSpellcastInfo(self)
        end
        self.OnDisable = function()
            self.lastSpell:UnregisterSpellcastInfo(self)
            self.module:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
            self.module:UnregisterEvent("BAG_UPDATE_COOLDOWN")
            self.module:UnregisterEvent("PET_BAR_UPDATE_COOLDOWN")
            self.module:UnregisterEvent("SPELL_UPDATE_CHARGES")
            self.module:UnregisterEvent("SPELL_UPDATE_USABLE")
            self.module:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
            self.module:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
            self.module:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
            self.module:UnregisterEvent("UNIT_SPELLCAST_START")
            self.module:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            self.module:UnregisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
        end
        self.UNIT_SPELLCAST_INTERRUPTED = function(event, unit)
            if unit == "player" or unit == "pet" then
                self.Update(event, unit)
                self.tracer:Debug("Resetting global cooldown.")
                local cd = self.gcd
                cd.start = 0
                cd.duration = 0
            end
        end
        self.Update = function(event, unit)
            if  not unit or unit == "player" or unit == "pet" then
                self.serial = self.serial + 1
                self.ovale:needRefresh()
                self.tracer:Debug(event, self.serial)
            end
        end
        self.CopySpellcastInfo = function(spellcast, dest)
            if spellcast.offgcd then
                dest.offgcd = spellcast.offgcd
            end
        end
        self.SaveSpellcastInfo = function(spellcast)
            local spellId = spellcast.spellId
            if spellId then
                local gcd = self.ovaleData:GetSpellInfoProperty(spellId, spellcast.start, "gcd", spellcast.target)
                if gcd and gcd == 0 then
                    spellcast.offgcd = true
                end
            end
        end
        self.ApplySpellStartCast = function(spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
            self.profiler:StartProfiling("OvaleCooldown_ApplySpellStartCast")
            if isChanneled then
                self:ApplyCooldown(spellId, targetGUID, startCast)
            end
            self.profiler:StopProfiling("OvaleCooldown_ApplySpellStartCast")
        end
        self.ApplySpellAfterCast = function(spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
            self.profiler:StartProfiling("OvaleCooldown_ApplySpellAfterCast")
            if  not isChanneled then
                self:ApplyCooldown(spellId, targetGUID, endCast)
            end
            self.profiler:StopProfiling("OvaleCooldown_ApplySpellAfterCast")
        end
        States.constructor(self, __exports.CooldownData)
        self.module = ovale:createModule("OvaleCooldown", self.OnInitialize, self.OnDisable, aceEvent)
        self.tracer = ovaleDebug:create("OvaleCooldown")
        self.profiler = ovaleProfiler:create("OvaleCooldown")
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
        return spellTable and next(spellTable) ~= nil
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
        local cdStart, cdDuration, cdEnable = 0, 0, true
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
            local index, bookType = self.ovaleSpellBook:GetSpellBookIndex(spellId)
            if index and bookType then
                start, duration, enable = GetSpellCooldown(index, bookType)
            else
                start, duration, enable = GetSpellCooldown(spellId)
            end
            self.tracer:Log("Call GetSpellCooldown which returned %f, %f, %d", start, duration, enable)
            if start and start > 0 then
                local gcdStart, gcdDuration = self:GetGlobalCooldown()
                self.tracer:Log("GlobalCooldown is %d, %d", gcdStart, gcdDuration)
                if start + duration > gcdStart + gcdDuration then
                    cdStart, cdDuration, cdEnable = start, duration, enable
                else
                    cdStart = start + duration
                    cdDuration = 0
                    cdEnable = enable
                end
            else
                cdStart, cdDuration, cdEnable = start or 0, duration or 0, enable
            end
        end
        return cdStart - COOLDOWN_THRESHOLD, cdDuration, cdEnable
    end,
    GetBaseGCD = function(self)
        local gcd, haste
        local baseGCD = BASE_GCD[self.ovale.playerClass]
        if baseGCD then
            gcd, haste = baseGCD[1], baseGCD[2]
        else
            gcd, haste = 1.5, "spell"
        end
        return gcd, haste
    end,
    GetCD = function(self, spellId, atTime)
        self.profiler:StartProfiling("OvaleCooldown_state_GetCD")
        local cdName = spellId
        local si = self.ovaleData.spellInfo[spellId]
        if si and si.shared_cd then
            cdName = si.shared_cd
        end
        if  not self.next.cd[cdName] then
            self.next.cd[cdName] = {
                start = 0,
                duration = 0,
                enable = false,
                chargeDuration = 0,
                chargeStart = 0,
                charges = 0,
                maxCharges = 0
            }
        end
        local cd = self.next.cd[cdName]
        if  not cd.start or  not cd.serial or cd.serial < self.serial then
            self.tracer:Log("Didn't find an existing cd in next, look for one in current")
            local start, duration, enable = self:GetSpellCooldown(spellId, nil)
            if si and si.forcecd then
                start, duration = self:GetSpellCooldown(si.forcecd, nil)
            end
            self.tracer:Log("It returned %f, %f", start, duration)
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
                self.tracer:Log("Spell cooldown is in the past")
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
        self.tracer:Log("Cooldown of spell %d is %f + %f", spellId, cd.start, cd.duration)
        self.profiler:StopProfiling("OvaleCooldown_state_GetCD")
        return cd
    end,
    GetSpellCooldownDuration = function(self, spellId, atTime, targetGUID)
        local start, duration = self:GetSpellCooldown(spellId, atTime)
        if duration > 0 and start + duration > atTime then
            self.tracer:Log("Spell %d is on cooldown for %fs starting at %s.", spellId, duration, start)
        else
            duration = self.ovaleData:GetSpellInfoPropertyNumber(spellId, atTime, "cd", targetGUID)
            if duration then
                if duration < 0 then
                    duration = 0
                end
            else
                duration = 0
            end
            self.tracer:Log("Spell %d has a base cooldown of %fs.", spellId, duration)
            if duration > 0 then
                local haste = self.ovaleData:GetSpellInfoProperty(spellId, atTime, "cd_haste", targetGUID)
                if haste then
                    local multiplier = self.ovalePaperDoll:GetBaseHasteMultiplier(self.ovalePaperDoll.next)
                    duration = duration / multiplier
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
        local cd = self:GetCD(spellId, atTime)
        local duration = self:GetSpellCooldownDuration(spellId, atTime, targetGUID)
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
