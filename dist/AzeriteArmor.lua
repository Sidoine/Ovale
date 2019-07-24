local __exports = LibStub:NewLibrary("ovale/AzeriteArmor", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
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
local azeriteSlots = {
    [1] = true,
    [3] = true,
    [5] = true
}
__exports.OvaleAzeriteArmor = __class(nil, {
    constructor = function(self, OvaleEquipment, ovale, ovaleDebug)
        self.OvaleEquipment = OvaleEquipment
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
        self.OnInitialize = function()
            self.module:RegisterMessage("Ovale_EquipmentChanged", self.ItemChanged)
            self.module:RegisterEvent("AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED", self.AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED)
            self.module:RegisterEvent("PLAYER_ENTERING_WORLD", self.PLAYER_ENTERING_WORLD)
        end
        self.OnDisable = function()
            self.module:UnregisterMessage("Ovale_EquipmentChanged")
            self.module:UnregisterEvent("AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED")
            self.module:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end
        self.ItemChanged = function()
            local slotId = self.OvaleEquipment.lastChangedSlot
            if slotId ~= nil and azeriteSlots[slotId] then
                self:UpdateTraits()
            end
        end
        self.AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED = function(event, itemSlot)
            self:UpdateTraits()
        end
        self.PLAYER_ENTERING_WORLD = function(event)
            self:UpdateTraits()
        end
        self.module = ovale:createModule("OvaleAzeriteArmor", self.OnInitialize, self.OnDisable, aceEvent)
        for k, v in pairs(self.debugOptions) do
            ovaleDebug.defaultOptions.args[k] = v
        end
    end,
    UpdateTraits = function(self)
        self.self_traits = {}
        for slotId in pairs(azeriteSlots) do
            local itemSlot = ItemLocation:CreateFromEquipmentSlot(slotId)
            if C_Item.DoesItemExist(itemSlot) and C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemSlot) then
                local allTraits = C_AzeriteEmpoweredItem.GetAllTierInfo(itemSlot)
                for _, traitsInRow in pairs(allTraits) do
                    for _, powerId in pairs(traitsInRow.azeritePowerIDs) do
                        local isEnabled = C_AzeriteEmpoweredItem.IsPowerSelected(itemSlot, powerId)
                        if isEnabled then
                            local powerInfo = C_AzeriteEmpoweredItem.GetPowerInfo(powerId)
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
            insert(array, tostring(v.name) .. ": " .. tostring(k) .. " (" .. v.rank .. ")")
        end
        sort(array)
        for _, v in ipairs(array) do
            self.output[#self.output + 1] = v
        end
        return concat(self.output, "\n")
    end,
})
