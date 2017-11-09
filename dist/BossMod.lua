local __exports = LibStub:NewLibrary("ovale/BossMod", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local GetNumGroupMembers = GetNumGroupMembers
local IsInGroup = IsInGroup
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local UnitExists = UnitExists
local UnitLevel = UnitLevel
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME
local UnitName = UnitName
local _G = _G
local hooksecurefunc = hooksecurefunc
local OvaleBossModBase = OvaleProfiler:RegisterProfiling(OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleBossMod")))
local _BigWigsLoader = _G["BigWigsLoader"]
local _DBM = _G["DBM"]
local OvaleBossModClass = __class(OvaleBossModBase, {
    constructor = function(self)
        self.EngagedDBM = nil
        self.EngagedBigWigs = nil
        OvaleBossModBase.constructor(self)
        if _DBM then
            self:Debug("DBM is loaded")
            hooksecurefunc(_DBM, "StartCombat", function(_DBM, mod, delay, event, ...)
                if event ~= "TIMER_RECOVERY" then
                    self.EngagedDBM = mod
                end
            end)
            hooksecurefunc(_DBM, "EndCombat", function(_DBM, mod)
                self.EngagedDBM = nil
            end)
        end
        if _BigWigsLoader then
            self:Debug("BigWigs is loaded")
            _BigWigsLoader.RegisterMessage(__exports.OvaleBossMod, "BigWigs_OnBossEngage", function(_, mod, diff)
                self.EngagedBigWigs = mod
            end)
            _BigWigsLoader.RegisterMessage(__exports.OvaleBossMod, "BigWigs_OnBossDisable", function(_, mod)
                self.EngagedBigWigs = nil
            end)
        end
    end,
    OnDisable = function(self)
    end,
    IsBossEngaged = function(self, state)
        if  not state.inCombat then
            return false
        end
        local dbmEngaged = (_DBM ~= nil and self.EngagedDBM ~= nil and self.EngagedDBM.inCombat)
        local bigWigsEngaged = (_BigWigsLoader ~= nil and self.EngagedBigWigs ~= nil and self.EngagedBigWigs.isEngaged)
        local neitherEngaged = (_DBM == nil and _BigWigsLoader == nil and self:ScanTargets())
        if dbmEngaged then
            self:Debug("DBM Engaged: [name=%s]", self.EngagedDBM.localization.general.name)
        end
        if bigWigsEngaged then
            self:Debug("BigWigs Engaged: [name=%s]", self.EngagedBigWigs.displayName)
        end
        return dbmEngaged or bigWigsEngaged or neitherEngaged
    end,
    ScanTargets = function(self)
        self:StartProfiling("OvaleBossMod:ScanTargets")
        local RecursiveScanTargets = function(target, depth)
            local isWorldBoss = false
            local dep = depth or 1
            isWorldBoss = target ~= nil and UnitExists(target) and UnitLevel(target) < 0
            if isWorldBoss then
                self:Debug("%s is worldboss (%s)", target, UnitName(target))
            end
            return isWorldBoss or (dep <= 3 and RecursiveScanTargets(target .. "target", dep + 1))
        end
        local bossEngaged = false
        bossEngaged = bossEngaged or UnitExists("boss1") or UnitExists("boss2") or UnitExists("boss3") or UnitExists("boss4")
        bossEngaged = bossEngaged or RecursiveScanTargets("target") or RecursiveScanTargets("pet") or RecursiveScanTargets("focus") or RecursiveScanTargets("focuspet") or RecursiveScanTargets("mouseover") or RecursiveScanTargets("mouseoverpet")
        if  not bossEngaged then
            if (IsInInstance() and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 1) then
                for i = 1, GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE), 1 do
                    bossEngaged = bossEngaged or RecursiveScanTargets("party" .. i) or RecursiveScanTargets("party" .. i .. "pet")
                end
            end
            if ( not IsInInstance() and IsInGroup(LE_PARTY_CATEGORY_HOME) and GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1) then
                for i = 1, GetNumGroupMembers(LE_PARTY_CATEGORY_HOME), 1 do
                    bossEngaged = bossEngaged or RecursiveScanTargets("party" .. i) or RecursiveScanTargets("party" .. i .. "pet")
                end
            end
            if (IsInInstance() and IsInRaid(LE_PARTY_CATEGORY_INSTANCE) and GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 1) then
                for i = 1, GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE), 1 do
                    bossEngaged = bossEngaged or RecursiveScanTargets("raid" .. i) or RecursiveScanTargets("raid" .. i .. "pet")
                end
            end
            if ( not IsInInstance() and IsInRaid(LE_PARTY_CATEGORY_HOME) and GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1) then
                for i = 1, GetNumGroupMembers(LE_PARTY_CATEGORY_HOME), 1 do
                    bossEngaged = bossEngaged or RecursiveScanTargets("raid" .. i) or RecursiveScanTargets("raid" .. i .. "pet")
                end
            end
        end
        self:StopProfiling("OvaleBossMod:ScanTargets")
        return bossEngaged
    end,
})
__exports.OvaleBossMod = OvaleBossModClass()
