local __exports = LibStub:NewLibrary("ovale/states/LossOfControl", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local C_LossOfControl = C_LossOfControl
local GetTime = GetTime
local pairs = pairs
local insert = table.insert
local upper = string.upper
local format = string.format
__exports.OvaleLossOfControlClass = __class(nil, {
    constructor = function(self, ovale, ovaleDebug)
        self.lossOfControlHistory = {}
        self.OnInitialize = function()
            self.tracer:Debug("Enabled LossOfControl module")
            self.module:RegisterEvent("LOSS_OF_CONTROL_ADDED", self.LOSS_OF_CONTROL_ADDED)
        end
        self.OnDisable = function()
            self.tracer:Debug("Disabled LossOfControl module")
            self.lossOfControlHistory = {}
            self.module:UnregisterEvent("LOSS_OF_CONTROL_ADDED")
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
        self.HasLossOfControl = function(locType, atTime)
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
            return lowestStartTime ~= nil and highestEndTime ~= nil
        end
        self.module = ovale:createModule("OvaleLossOfControl", self.OnInitialize, self.OnDisable, aceEvent)
        self.tracer = ovaleDebug:create(self.module:GetName())
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
})
