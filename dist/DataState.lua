local __exports = LibStub:NewLibrary("ovale/DataState", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __Requirement = LibStub:GetLibrary("ovale/Requirement")
local CheckRequirements = __Requirement.CheckRequirements
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
__exports.DataState = __class(nil, {
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    CheckRequirements = function(self, spellId, atTime, tokens, index, targetGUID)
        return CheckRequirements(spellId, atTime, tokens, index, targetGUID)
    end,
    CheckSpellAuraData = function(self, auraId, spellData, atTime, guid)
        return OvaleData:CheckSpellAuraData(auraId, spellData, atTime, guid)
    end,
    CheckSpellInfo = function(self, spellId, atTime, targetGUID)
        return OvaleData:CheckSpellInfo(spellId, atTime, targetGUID)
    end,
    GetItemInfoProperty = function(self, itemId, atTime, property)
        return OvaleData:GetItemInfoProperty(itemId, atTime, property)
    end,
    GetSpellInfoProperty = function(self, spellId, atTime, property, targetGUID)
        return OvaleData:GetSpellInfoProperty(spellId, atTime, property, targetGUID)
    end,
})
__exports.dataState = __exports.DataState()
OvaleState:RegisterState(__exports.dataState)
