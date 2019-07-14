local __exports = LibStub:NewLibrary("ovale/AzeriteEssence", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local pairs = pairs
local tostring = tostring
local ipairs = ipairs
local sort = table.sort
local insert = table.insert
local concat = table.concat
local C_AzeriteEssence = C_AzeriteEssence
local tsort = sort
local tinsert = insert
local tconcat = concat
local OvaleAzeriteEssenceBase = OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleAzeriteEssence", aceEvent))
local OvaleAzeriteEssenceClass = __class(OvaleAzeriteEssenceBase, {
    constructor = function(self)
        self.self_essences = {}
        self.debugOptions = {
            azeraitessences = {
                name = "Azerite essences",
                type = "group",
                args = {
                    azeraitessences = {
                        name = "Azerite essences",
                        type = "input",
                        multiline = 25,
                        width = "full",
                        get = function(info)
                            return self:DebugEssences()
                        end
                    }
                }
            }
        }
        OvaleAzeriteEssenceBase.constructor(self)
        for k, v in pairs(self.debugOptions) do
            OvaleDebug.options.args[k] = v
        end
    end,
    OnInitialize = function(self)
        self:RegisterEvent("AZERITE_ESSENCE_CHANGED", "UpdateEssences")
        self:RegisterEvent("AZERITE_ESSENCE_UPDATE", "UpdateEssences")
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateEssences")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("AZERITE_ESSENCE_CHANGED")
        self:UnregisterEvent("AZERITE_ESSENCE_UPDATE")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end,
    UpdateEssences = function(self, e)
        self:Debug("UpdateEssences after event %s", e)
        self.self_essences = {}
        for _, mileStoneInfo in pairs(C_AzeriteEssence.GetMilestones() or {}) do
            if mileStoneInfo.ID and mileStoneInfo.unlocked and mileStoneInfo.slot ~= nil then
                local essenceId = C_AzeriteEssence.GetMilestoneEssence(mileStoneInfo.ID)
                if essenceId then
                    local essenceInfo = C_AzeriteEssence.GetEssenceInfo(essenceId)
                    local essenceData = {
                        ID = essenceId,
                        name = essenceInfo.name,
                        rank = essenceInfo.rank,
                        slot = mileStoneInfo.slot
                    }
                    self.self_essences[essenceId] = essenceData
                    self:Debug("Found essence {ID: %d, name: %s, rank: %d, slot: %d}", essenceData.ID, essenceData.name, essenceData.rank, essenceData.slot)
                end
            end
        end
    end,
    IsMajorEssence = function(self, essenceId)
        local essence = self.self_essences[essenceId]
        if essence then
            return essence.slot == 0 and true or false
        end
        return false
    end,
    IsMinorEssence = function(self, essenceId)
        return self.self_essences[essenceId] ~= nil and true or false
    end,
    DebugEssences = function(self)
        local output = {}
        local array = {}
        for k, v in pairs(self.self_essences) do
            tinsert(array, tostring(v.name) .. ": " .. tostring(k) .. " (slot:" .. v.slot .. " | rank:" .. v.rank .. ")")
        end
        tsort(array)
        for _, v in ipairs(array) do
            output[#output + 1] = v
        end
        return tconcat(output, "\n")
    end,
})
__exports.OvaleAzeriteEssence = OvaleAzeriteEssenceClass()
