local __exports = LibStub:NewLibrary("ovale/AzeriteArmor", 80000)
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
local __Equipment = LibStub:GetLibrary("ovale/Equipment")
local OvaleEquipment = __Equipment.OvaleEquipment
local tsort = sort
local tinsert = insert
local tconcat = concat
local item = C_Item
local itemLocation = ItemLocation
local azeriteItem = C_AzeriteEmpoweredItem
local azeriteSlots = {
    [1] = true,
    [3] = true,
    [5] = true
}
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
        self:RegisterMessage("Ovale_EquipmentChanged", "ItemChanged")
        self:RegisterEvent("AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
    end,
    OnDisable = function(self)
        self:UnregisterMessage("Ovale_EquipmentChanged")
        self:UnregisterEvent("AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end,
    ItemChanged = function(self)
        local slotId = OvaleEquipment.lastChangedSlot
        if slotId ~= nil and azeriteSlots[slotId] then
            self:UpdateTraits()
        end
    end,
    AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED = function(self, event, itemSlot)
        self:UpdateTraits()
    end,
    PLAYER_ENTERING_WORLD = function(self, event)
        self:UpdateTraits()
    end,
    UpdateTraits = function(self)
        self.self_traits = {}
        for slotId in pairs(azeriteSlots) do
            local itemSlot = itemLocation:CreateFromEquipmentSlot(slotId)
            if item.DoesItemExist(itemSlot) and azeriteItem.IsAzeriteEmpoweredItem(itemSlot) then
                local allTraits = azeriteItem.GetAllTierInfo(itemSlot)
                for _, traitsInRow in pairs(allTraits) do
                    for _, powerId in pairs(traitsInRow.azeritePowerIDs) do
                        local isEnabled = azeriteItem.IsPowerSelected(itemSlot, powerId)
                        if isEnabled then
                            local powerInfo = azeriteItem.GetPowerInfo(powerId)
                            local name = GetSpellInfo(powerInfo.spellID)
                            if self.self_traits[powerInfo.spellID] then
                                local rank = self.self_traits[powerInfo.spellID].rank
                                self.self_traits[powerInfo.spellID].rank = rank + 1
                            else
                                self.self_traits[powerInfo.spellID] = {
                                    spellID = powerInfo.spellID,
                                    name = name,
                                    rank = 1
                                }
                            end
                            break
                        end
                    end
                end
            end
        end
    end,
    HasTrait = function(self, spellId)
        return (self.self_traits[spellId]) and true or false
    end,
    TraitRank = function(self, spellId)
        if  not self.self_traits[spellId] then
            return 0
        end
        return self.self_traits[spellId].rank
    end,
    DebugTraits = function(self)
        wipe(self.output)
        local array = {}
        for k, v in pairs(self.self_traits) do
            tinsert(array, tostring(v.name) .. ": " .. tostring(k) .. " (" .. v.rank .. ")")
        end
        tsort(array)
        for _, v in ipairs(array) do
            self.output[#self.output + 1] = v
        end
        return tconcat(self.output, "\n")
    end,
})
__exports.OvaleAzerite = OvaleAzeriteArmor()
