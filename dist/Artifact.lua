local __exports = LibStub:NewLibrary("ovale/Artifact", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
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
    end,
    OnDisable = function(self)
    end,
    UpdateTraits = function(self, message)
        return 
    end,
    HasTrait = function(self, spellId)
        return false
    end,
    TraitRank = function(self, spellId)
        return 0
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
