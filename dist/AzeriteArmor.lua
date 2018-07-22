local __exports = LibStub:NewLibrary("ovale/AzeriteArmor", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local wipe = wipe
local pairs = pairs
local tostring = tostring
local ipairs = ipairs
local sort = table.sort
local insert = table.insert
local concat = table.concat
local C_Item = C_Item
local ItemLocation = ItemLocation
local C_AzeriteEmpoweredItem = C_AzeriteEmpoweredItem
local GetSpellInfo = GetSpellInfo
local tsort = sort
local tinsert = insert
local tconcat = concat
local item = C_Item
local itemLocation = ItemLocation
local azeriteItem = C_AzeriteEmpoweredItem
local OvaleAzeriteArmorBase = OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleAzerite", aceEvent))
local OvaleAzeriteArmor = __class(OvaleAzeriteArmorBase, {
    constructor = function(self)
        self.self_traits = {}
        self.output = {}
        self.debugOptions = {
            azeraittraits = {
                name = "Azerite traits",
                type = "group",
                args = {
                    azeraittraits = {
                        name = "Azerite traits",
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
        OvaleAzeriteArmorBase.constructor(self)
        for k, v in pairs(self.debugOptions) do
            OvaleDebug.options.args[k] = v
        end
    end,
    OnInitialize = function(self)
        self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED", "UpdateTraits")
        self:RegisterEvent("AZERITE_ITEM_POWER_LEVEL_CHANGED", "UpdateTraits")
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateTraits")
        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "UpdateTraits")
        self:RegisterEvent("SPELLS_CHANGED", "UpdateTraits")
        self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "UpdateTraits")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED")
        self:UnregisterEvent("AZERITE_ITEM_POWER_LEVEL_CHANGED")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
        self:UnregisterEvent("SPELLS_CHANGED")
        self:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    end,
    UpdateTraits = function(self)
        self.self_traits = {}
        for slot = 1, 14, 1 do
            local itemSlot = itemLocation:CreateFromEquipmentSlot(slot)
            if item.DoesItemExist(itemSlot) and azeriteItem.IsAzeriteEmpoweredItem(itemSlot) then
                local allTraits = azeriteItem.GetAllTierInfo(itemSlot)
                for _, traitsInRow in pairs(allTraits) do
                    for _, powerId in pairs(traitsInRow.azeritePowerIDs) do
                        local isEnabled = azeriteItem.IsPowerSelected(itemSlot, powerId)
                        if isEnabled then
                            local powerInfo = azeriteItem.GetPowerInfo(powerId)
                            local name = GetSpellInfo(powerInfo.spellID)
                            self.self_traits[powerInfo.spellID] = {
                                spellID = powerInfo.spellID,
                                name = name
                            }
                        end
                    end
                end
            end
        end
    end,
    HasTrait = function(self, spellId)
        return (self.self_traits[spellId]) and true or false
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
__exports.OvaleAzerite = OvaleAzeriteArmor()
