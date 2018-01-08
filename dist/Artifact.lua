local __exports = LibStub:NewLibrary("ovale/Artifact", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __lib_artifact_data10 = LibStub:GetLibrary("LibArtifactData-1.0", true)
local GetArtifactTraits = __lib_artifact_data10.GetArtifactTraits
local RegisterCallback = __lib_artifact_data10.RegisterCallback
local UnregisterCallback = __lib_artifact_data10.UnregisterCallback
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local sort = table.sort
local insert = table.insert
local concat = table.concat
local pairs = pairs
local ipairs = ipairs
local wipe = wipe
local tostring = tostring
local tsort = sort
local tinsert = insert
local tconcat = concat
local OvaleArtifactBase = OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleArtifact", aceEvent))
local OvaleArtifactClass = __class(OvaleArtifactBase, {
    constructor = function(self)
        self.self_traits = {}
        self.debugOptions = {
            artifacttraits = {
                name = L["Artifact traits"],
                type = "group",
                args = {
                    artifacttraits = {
                        name = L["Artifact traits"],
                        type = "input",
                        multiline = 25,
                        width = "full",
                        get = function(info)
                            return self:DebugTraits()
                        end
                    }
                }
            }
        }
        self.output = {}
        OvaleArtifactBase.constructor(self)
        for k, v in pairs(self.debugOptions) do
            OvaleDebug.options.args[k] = v
        end
    end,
    OnInitialize = function(self)
        self:RegisterEvent("SPELLS_CHANGED", function(message)
            return self:UpdateTraits(message)
        end)
        RegisterCallback(self, "ARTIFACT_ADDED", function(message)
            return self:UpdateTraits(message)
        end)
        RegisterCallback(self, "ARTIFACT_EQUIPPED_CHANGED", function(m)
            return self:UpdateTraits(m)
        end)
        RegisterCallback(self, "ARTIFACT_ACTIVE_CHANGED", function(m)
            return self:UpdateTraits(m)
        end)
        RegisterCallback(self, "ARTIFACT_TRAITS_CHANGED", function(m)
            return self:UpdateTraits(m)
        end)
    end,
    OnDisable = function(self)
        UnregisterCallback(self, "ARTIFACT_ADDED")
        UnregisterCallback(self, "ARTIFACT_EQUIPPED_CHANGED")
        UnregisterCallback(self, "ARTIFACT_ACTIVE_CHANGED")
        UnregisterCallback(self, "ARTIFACT_TRAITS_CHANGED")
        self:UnregisterEvent("SPELLS_CHANGED")
    end,
    UpdateTraits = function(self, message)
        local _, traits = GetArtifactTraits()
        self.self_traits = {}
        if  not traits then
            return 
        end
        for _, v in ipairs(traits) do
            self.self_traits[v.spellID] = v
        end
    end,
    HasTrait = function(self, spellId)
        return self.self_traits[spellId] and self.self_traits[spellId].currentRank > 0
    end,
    TraitRank = function(self, spellId)
        if  not self.self_traits[spellId] then
            return 0
        end
        return self.self_traits[spellId].currentRank
    end,
    DebugTraits = function(self)
        wipe(self.output)
        local array = {}
        for k, v in pairs(self.self_traits) do
            tinsert(array, tostring(v.name) .. ": " .. tostring(k))
        end
        tsort(array)
        for _, v in ipairs(array) do
            self.output[#self.output + 1] = v
        end
        return tconcat(self.output, "\n")
    end,
})
__exports.OvaleArtifact = OvaleArtifactClass()
