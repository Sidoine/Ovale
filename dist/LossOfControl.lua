local __exports = LibStub:NewLibrary("ovale/LossOfControl", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __Requirement = LibStub:GetLibrary("ovale/Requirement")
local RegisterRequirement = __Requirement.RegisterRequirement
local UnregisterRequirement = __Requirement.UnregisterRequirement
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local C_LossOfControl = C_LossOfControl
local GetTime = GetTime
local pairs = pairs
local insert = table.insert
local sub = string.sub
local upper = string.upper
local OvaleLossOfControlBase = OvaleProfiler:RegisterProfiling(OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleLossOfControl", aceEvent)))
local OvaleLossOfControlClass = __class(OvaleLossOfControlBase, {
    OnInitialize = function(self)
        self:Debug("Enabled LossOfControl module")
        self.lossOfControlHistory = {}
        self:RegisterEvent("LOSS_OF_CONTROL_ADDED")
        RegisterRequirement("lossofcontrol", self.RequireLossOfControlHandler)
    end,
    OnDisable = function(self)
        self:Debug("Disabled LossOfControl module")
        self.lossOfControlHistory = {}
        self:UnregisterEvent("LOSS_OF_CONTROL_ADDED")
        UnregisterRequirement("lossofcontrol")
    end,
    LOSS_OF_CONTROL_ADDED = function(self, event, eventIndex)
        self:Debug("GetEventInfo:", eventIndex, C_LossOfControl.GetEventInfo(eventIndex))
        local locType, spellID, _, _, startTime, _, duration = C_LossOfControl.GetEventInfo(eventIndex)
        local data = {
            locType = upper(locType),
            spellID = spellID,
            startTime = startTime or GetTime(),
            duration = duration or 10
        }
        insert(self.lossOfControlHistory, data)
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    constructor = function(self, ...)
        OvaleLossOfControlBase.constructor(self, ...)
        self.RequireLossOfControlHandler = function(spellId, atTime, requirement, tokens, index, targetGUID)
            local verified = false
            local locType = tokens[index]
            index = index + 1
            if locType then
                local required = true
                if sub(locType, 1, 1) == "!" then
                    required = false
                    locType = sub(locType, 2)
                end
                local hasLoss = self.HasLossOfControl(locType, atTime)
                verified = (required and hasLoss) or ( not required and  not hasLoss)
            else
                Ovale:OneTimeMessage("Warning: requirement '%s' is missing a locType argument.", requirement)
            end
            return verified, requirement, index
        end
        self.HasLossOfControl = function(locType, atTime)
            local lowestStartTime = nil
            local highestEndTime = nil
            for _, data in pairs(self.lossOfControlHistory) do
                if upper(locType) == data.locType and (data.startTime <= atTime and atTime <= data.startTime + data.duration) then
                    if lowestStartTime == nil or lowestStartTime > data.startTime then
                        lowestStartTime = data.startTime
                    end
                    if highestEndTime == nil or highestEndTime < data.startTime + data.duration then
                        highestEndTime = data.startTime + data.duration
                    end
                end
            end
            return lowestStartTime ~= nil and highestEndTime ~= nil
        end

    end
})
__exports.OvaleLossOfControl = OvaleLossOfControlClass()
OvaleState:RegisterState(__exports.OvaleLossOfControl)
