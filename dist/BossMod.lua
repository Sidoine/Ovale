local __exports = LibStub:NewLibrary("ovale/BossMod", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local UnitExists = UnitExists
local UnitClassification = UnitClassification
local _G = _G
local hooksecurefunc = hooksecurefunc
local _BigWigsLoader = _G["BigWigsLoader"]
local _DBM = _G["DBM"]
__exports.OvaleBossModClass = __class(nil, {
    constructor = function(self, ovale, ovaleDebug, ovaleProfiler, combat)
        self.combat = combat
        self.EngagedDBM = nil
        self.EngagedBigWigs = nil
        self.OnInitialize = function()
            if _DBM then
                self.tracer:Debug("DBM is loaded")
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
                self.tracer:Debug("BigWigs is loaded")
                _BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossEngage", function(_, mod, diff)
                    self.EngagedBigWigs = mod
                end)
                _BigWigsLoader.RegisterMessage(self, "BigWigs_OnBossDisable", function(_, mod)
                    self.EngagedBigWigs = nil
                end)
            end
        end
        self.module = ovale:createModule("BossMod", self.OnInitialize, self.OnDisable)
        self.tracer = ovaleDebug:create(self.module:GetName())
        self.profiler = ovaleProfiler:create(self.module:GetName())
    end,
    OnDisable = function(self)
    end,
    IsBossEngaged = function(self, atTime)
        if  not self.combat:isInCombat(atTime) then
            return false
        end
        local dbmEngaged = _DBM ~= nil and self.EngagedDBM ~= nil and self.EngagedDBM.inCombat
        local bigWigsEngaged = _BigWigsLoader ~= nil and self.EngagedBigWigs ~= nil and self.EngagedBigWigs.isEngaged
        local neitherEngaged = _DBM == nil and _BigWigsLoader == nil and self:ScanTargets()
        if dbmEngaged then
            self.tracer:Debug("DBM Engaged: [name=%s]", self.EngagedDBM.localization.general.name)
        end
        if bigWigsEngaged then
            self.tracer:Debug("BigWigs Engaged: [name=%s]", self.EngagedBigWigs.displayName)
        end
        return dbmEngaged or bigWigsEngaged or neitherEngaged
    end,
    ScanTargets = function(self)
        self.profiler:StartProfiling("OvaleBossMod:ScanTargets")
        local bossEngaged = false
        if UnitExists("target") then
            bossEngaged = UnitClassification("target") == "worldboss" or false
        end
        self.profiler:StopProfiling("OvaleBossMod:ScanTargets")
        return bossEngaged
    end,
})
