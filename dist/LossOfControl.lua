local __exports = LibStub:NewLibrary("ovale/LossOfControl", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local C_LossOfControl = C_LossOfControl
local GetTime = GetTime
local pairs = pairs
local insert = table.insert
local sub = string.sub
local upper = string.upper
__exports.OvaleLossOfControlClass = __class(nil, {
    constructor = function(self, ovale, ovaleDebug, requirement)
        self.ovale = ovale
        self.requirement = requirement
        self.OnInitialize = function()
            self.tracer:Debug("Enabled LossOfControl module")
            self.lossOfControlHistory = {}
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
            self.tracer:Debug("GetEventInfo:", eventIndex, C_LossOfControl.GetEventInfo(eventIndex))
            local locType, spellID, _, _, startTime, _, duration = C_LossOfControl.GetEventInfo(eventIndex)
            local data = {
                locType = upper(locType),
                spellID = spellID,
                startTime = startTime or GetTime(),
                duration = duration or 10
            }
            insert(self.lossOfControlHistory, data)
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
                self.ovale:OneTimeMessage("Warning: requirement '%s' is missing a locType argument.", requirement)
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
