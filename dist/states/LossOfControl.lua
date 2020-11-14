local __exports = LibStub:NewLibrary("ovale/states/LossOfControl", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local C_LossOfControl = C_LossOfControl
local GetTime = GetTime
local HasFullControl = HasFullControl
local pairs = pairs
local ipairs = ipairs
local insert = table.insert
local sub = string.sub
local upper = string.upper
local format = string.format
local __tools = LibStub:GetLibrary("ovale/tools")
local OneTimeMessage = __tools.OneTimeMessage
local __Condition = LibStub:GetLibrary("ovale/Condition")
local TestBoolean = __Condition.TestBoolean
__exports.OvaleLossOfControlClass = __class(nil, {
    constructor = function(self, ovale, ovaleDebug, requirement)
        self.requirement = requirement
        self.lossOfControlHistory = {}
        self.OnInitialize = function()
            self.tracer:Debug("Enabled LossOfControl module")
            self.module:RegisterEvent("LOSS_OF_CONTROL_ADDED", self.LOSS_OF_CONTROL_ADDED)
            self.requirement:RegisterRequirement("lossofcontrol", self.RequireLossOfControlHandler)
        end
        self.OnDisable = function()
            self.tracer:Debug("Disabled LossOfControl module")
            self.lossOfControlHistory = {}
            self.module:UnregisterEvent("LOSS_OF_CONTROL_ADDED")
            self.requirement:UnregisterRequirement("lossofcontrol")
        end
        self.LOSS_OF_CONTROL_ADDED = function(event, eventIndex)
            self.tracer:Debug("LOSS_OF_CONTROL_ADDED", format("C_LossOfControl.GetActiveLossOfControlData(%d)", eventIndex), C_LossOfControl.GetActiveLossOfControlData(eventIndex))
            local lossOfControlData = C_LossOfControl.GetActiveLossOfControlData(eventIndex)
            if lossOfControlData then
                local data = {
                    locType = upper(lossOfControlData.locType),
                    spellID = lossOfControlData.spellID,
                    startTime = lossOfControlData.startTime or GetTime(),
                    duration = lossOfControlData.duration or 10
                }
                insert(self.lossOfControlHistory, data)
            end
        end
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
                OneTimeMessage("Warning: requirement '%s' is missing a locType argument.", requirement)
            end
            return verified, requirement, index
        end
        self.GetLossOfControlTiming = function(locType, atTime)
            local lowestStartTime = nil
            local highestEndTime = nil
            for _, data in pairs(self.lossOfControlHistory) do
                if upper(locType) == data.locType and data.startTime <= atTime and atTime <= data.startTime + data.duration then
                    if lowestStartTime == nil or lowestStartTime > data.startTime then
                        lowestStartTime = data.startTime
                    end
                    if highestEndTime == nil or highestEndTime < data.startTime + data.duration then
                        highestEndTime = data.startTime + data.duration
                    end
                end
            end
            return lowestStartTime, highestEndTime
        end
        self.HasLossOfControl = function(locType, atTime)
            local lowestStartTime, highestEndTime = self.GetLossOfControlTiming(locType, atTime)
            return lowestStartTime ~= nil and highestEndTime ~= nil
        end
        self.IsFeared = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean =  not HasFullControl() and self.HasLossOfControl("FEAR", atTime)
            return TestBoolean(boolean, yesno)
        end
        self.IsIncapacitated = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean =  not HasFullControl() and self.HasLossOfControl("CONFUSE", atTime)
            return TestBoolean(boolean, yesno)
        end
        self.IsRooted = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean = self.HasLossOfControl("ROOT", atTime)
            return TestBoolean(boolean, yesno)
        end
        self.IsStunned = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean =  not HasFullControl() and self.HasLossOfControl("STUN_MECHANIC", atTime)
            return TestBoolean(boolean, yesno)
        end
        self.HasLossOfControlCondition = function(positionalParams, namedParams, atTime)
            for _, lossOfControlType in ipairs(positionalParams) do
                local start, ending = self.GetLossOfControlTiming(upper(lossOfControlType), atTime)
                if start ~= nil and ending ~= nil then
                    return start, ending
                end
            end
            return 
        end
        self.module = ovale:createModule("OvaleLossOfControl", self.OnInitialize, self.OnDisable, aceEvent)
        self.tracer = ovaleDebug:create(self.module:GetName())
    end,
    registerConditions = function(self, ovaleCondition)
        ovaleCondition:RegisterCondition("isfeared", false, self.IsFeared)
        ovaleCondition:RegisterCondition("isincapacitated", false, self.IsIncapacitated)
        ovaleCondition:RegisterCondition("isrooted", false, self.IsRooted)
        ovaleCondition:RegisterCondition("isstunned", false, self.IsStunned)
        ovaleCondition:RegisterCondition("haslossofcontrol", false, self.HasLossOfControlCondition)
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
})
