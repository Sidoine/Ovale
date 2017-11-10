local __exports = LibStub:NewLibrary("ovale/Cooldown", 10000)
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
local OvaleCooldownBase = OvaleDebug:RegisterDebugging(OvaleProfiler:RegisterProfiling(Ovale:NewModule("OvaleCooldown", aceEvent)))
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
        RegisterRequirement("oncooldown", "RequireCooldownHandler", self)
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
    UNIT_SPELLCAST_INTERRUPTED = function(self, event, unit, name, rank, lineId, spellId)
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
    GetSpellCooldown = function(self, spellId)
        local cdStart, cdDuration, cdEnable = 0, 0, 1
        if self.sharedCooldown[spellId] then
            for id in pairs(self.sharedCooldown[spellId]) do
                local start, duration, enable = self:GetSpellCooldown(id)
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
            if start and start > 0 then
                local gcdStart, gcdDuration = self:GetGlobalCooldown()
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
                if state then
                    gcd = state:GetSpellInfoProperty(spellId, spellcast.start, "gcd", spellcast.target)
                else
                    gcd = OvaleData:GetSpellInfoProperty(spellId, spellcast.start, "gcd", spellcast.target)
                end
                if gcd and gcd == 0 then
                    spellcast.offgcd = true
                end
            end
        end
    end
})
__exports.OvaleCooldown = OvaleCooldownClass()
