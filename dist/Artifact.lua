local __exports = LibStub:NewLibrary("ovale/Artifact", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
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
__exports.OvaleArtifactClass = __class(nil, {
    constructor = function(self, ovaleDebug)
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
                        get = function()
                            return self:DebugTraits()
                        end
                    }
                }
            }
        }
        self.output = {}
        for k, v in pairs(self.debugOptions) do
            ovaleDebug.defaultOptions.args[k] = v
        end
    end,
    OnInitialize = function(self)
    end,
    OnDisable = function(self)
    end,
    UpdateTraits = function(self)
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
