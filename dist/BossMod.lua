local __exports = LibStub:NewLibrary("ovale/BossMod", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local UnitExists = UnitExists
local UnitClassification = UnitClassification
local _G = _G
local hooksecurefunc = hooksecurefunc
local __BaseState = LibStub:GetLibrary("ovale/BaseState")
local baseState = __BaseState.baseState
local OvaleBossModBase = OvaleProfiler:RegisterProfiling(OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleBossMod")))
local _BigWigsLoader = _G["BigWigsLoader"]
local _DBM = _G["DBM"]
local OvaleBossModClass = __class(OvaleBossModBase, {
    OnInitialize = function(self)
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
    IsBossEngaged = function(self, atTime)
        if  not baseState:IsInCombat(atTime) then
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
        local bossEngaged = false
        if UnitExists("target") then
            bossEngaged = (UnitClassification("target") == "worldboss") or false
        end
        self:StopProfiling("OvaleBossMod:ScanTargets")
        return bossEngaged
    end,
    constructor = function(self, ...)
        OvaleBossModBase.constructor(self, ...)
        self.EngagedDBM = nil
        self.EngagedBigWigs = nil
    end
})
__exports.OvaleBossMod = OvaleBossModClass()
