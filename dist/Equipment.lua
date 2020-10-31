local __exports = LibStub:NewLibrary("ovale/Equipment", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local pairs = pairs
local wipe = wipe
local ipairs = ipairs
local kpairs = pairs
local sub = string.sub
local GetInventoryItemID = GetInventoryItemID
local GetInventoryItemLink = GetInventoryItemLink
local GetItemStats = GetItemStats
local GetItemInfoInstant = GetItemInfoInstant
local GetInventorySlotInfo = GetInventorySlotInfo
local INVSLOT_FIRST_EQUIPPED = INVSLOT_FIRST_EQUIPPED
local INVSLOT_LAST_EQUIPPED = INVSLOT_LAST_EQUIPPED
local concat = table.concat
local insert = table.insert
local __tools = LibStub:GetLibrary("ovale/tools")
local isNumber = __tools.isNumber
local OVALE_SLOTID_BY_SLOTNAME = {
    AmmoSlot = 0,
    HeadSlot = 1,
    NeckSlot = 2,
    ShoulderSlot = 3,
    ShirtSlot = 4,
    ChestSlot = 5,
    WaistSlot = 6,
    LegsSlot = 7,
    FeetSlot = 8,
    WristSlot = 9,
    HandsSlot = 10,
    Finger0Slot = 11,
    Finger1Slot = 12,
    Trinket0Slot = 13,
    Trinket1Slot = 14,
    BackSlot = 15,
    MainHandSlot = 16,
    SecondaryHandSlot = 17,
    TabardSlot = 19
}
local OVALE_SLOTNAME_BY_SLOTID = {}
local OVALE_ONE_HANDED_WEAPON = {
    INVTYPE_WEAPON = true,
    INVTYPE_WEAPONOFFHAND = true,
    INVTYPE_WEAPONMAINHAND = true
}
local OVALE_RANGED_WEAPON = {
    INVTYPE_RANGEDRIGHT = true,
    INVTYPE_RANGED = true
}
__exports.OvaleEquipmentClass = __class(nil, {
    constructor = function(self, ovale, ovaleDebug, ovaleProfiler)
        self.ovale = ovale
        self.ready = false
        self.equippedItemById = {}
        self.equippedItemBySlot = {}
        self.mainHandDPS = 0
        self.offHandDPS = 0
        self.armorSetCount = {}
        self.lastChangedSlot = nil
        self.output = {}
        self.debugOptions = {
            itemsequipped = {
                name = "Items equipped",
                type = "group",
                args = {
                    itemsequipped = {
                        name = "Items equipped",
                        type = "input",
                        multiline = 25,
                        width = "full",
                        get = function(info)
                            return self:DebugEquipment()
                        end
                    }
                }
            }
        }
        self.OnInitialize = function()
            self.module:RegisterEvent("PLAYER_ENTERING_WORLD", self.UpdateEquippedItems)
            self.module:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", self.PLAYER_EQUIPMENT_CHANGED)
        end
        self.OnDisable = function()
            self.module:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self.module:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
        end
        self.PLAYER_EQUIPMENT_CHANGED = function(event, slotId, hasItem)
            self.profiler:StartProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED")
            local changed = self:UpdateItemBySlot(slotId)
            if changed then
                self.lastChangedSlot = slotId
                self.ovale:needRefresh()
                self.module:SendMessage("Ovale_EquipmentChanged")
            end
            self.profiler:StopProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED")
        end
        self.UpdateEquippedItems = function()
            self.profiler:StartProfiling("OvaleEquipment_UpdateEquippedItems")
            local changed = false
            for slotId = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED, 1 do
                if OVALE_SLOTNAME_BY_SLOTID[slotId] and self:UpdateItemBySlot(slotId) then
                    changed = true
                end
            end
            if changed then
                self.ovale:needRefresh()
                self.module:SendMessage("Ovale_EquipmentChanged")
            end
            self.ready = true
            self.profiler:StopProfiling("OvaleEquipment_UpdateEquippedItems")
        end
        self.module = ovale:createModule("OvaleEquipment", self.OnInitialize, self.OnDisable, aceEvent)
        self.profiler = ovaleProfiler:create(self.module:GetName())
        for k, v in pairs(self.debugOptions) do
            ovaleDebug.defaultOptions.args[k] = v
        end
        for slotName in kpairs(OVALE_SLOTID_BY_SLOTNAME) do
            local invSlotId = GetInventorySlotInfo(slotName)
            OVALE_SLOTID_BY_SLOTNAME[slotName] = invSlotId
            OVALE_SLOTNAME_BY_SLOTID[invSlotId] = slotName
        end
    end,
    GetArmorSetCount = function(self, name)
        return 0
    end,
    GetEquippedItemBySlotName = function(self, slotName)
        if slotName then
            local slotId = OVALE_SLOTID_BY_SLOTNAME[slotName]
            if slotId ~= nil then
                return self.equippedItemBySlot[OVALE_SLOTID_BY_SLOTNAME[slotName]]
            end
        end
        return nil
    end,
    GetEquippedTrinkets = function(self)
        return self.equippedItemBySlot[OVALE_SLOTID_BY_SLOTNAME["Trinket0Slot"]], self.equippedItemBySlot[OVALE_SLOTID_BY_SLOTNAME["Trinket1Slot"]]
    end,
    HasEquippedItem = function(self, itemId)
        return (self.equippedItemById[itemId] and true) or false
    end,
    HasMainHandWeapon = function(self, handedness)
        if  not self.mainHandItemType then
            return false
        end
        if handedness then
            if handedness == 1 then
                return OVALE_ONE_HANDED_WEAPON[self.mainHandItemType]
            elseif handedness == 2 then
                return self.mainHandItemType == "INVTYPE_2HWEAPON"
            end
        else
            return (OVALE_ONE_HANDED_WEAPON[self.mainHandItemType] or self.mainHandItemType == "INVTYPE_2HWEAPON")
        end
        return false
    end,
    HasOffHandWeapon = function(self, handedness)
        if  not self.offHandItemType then
            return false
        end
        if handedness then
            if handedness == 1 then
                return OVALE_ONE_HANDED_WEAPON[self.offHandItemType]
            elseif handedness == 2 then
                return self.offHandItemType == "INVTYPE_2HWEAPON"
            end
        else
            return (OVALE_ONE_HANDED_WEAPON[self.offHandItemType] or self.offHandItemType == "INVTYPE_2HWEAPON")
        end
        return false
    end,
    HasShield = function(self)
        return self.offHandItemType == "INVTYPE_SHIELD"
    end,
    HasRangedWeapon = function(self)
        return (self.mainHandItemType and OVALE_RANGED_WEAPON[self.mainHandItemType])
    end,
    HasTrinket = function(self, itemId)
        return self:HasEquippedItem(itemId)
    end,
    HasTwoHandedWeapon = function(self)
        return (self.mainHandItemType == "INVTYPE_2HWEAPON" or self.offHandItemType == "INVTYPE_2HWEAPON")
    end,
    HasOneHandedWeapon = function(self, slotId)
        if slotId and  not isNumber(slotId) then
            slotId = OVALE_SLOTID_BY_SLOTNAME[slotId]
        end
        if slotId then
            if slotId == OVALE_SLOTID_BY_SLOTNAME["MainHandSlot"] then
                return (self.mainHandItemType and OVALE_ONE_HANDED_WEAPON[self.mainHandItemType])
            elseif slotId == OVALE_SLOTID_BY_SLOTNAME["SecondaryHandSlot"] then
                return (self.offHandItemType and OVALE_ONE_HANDED_WEAPON[self.offHandItemType])
            end
        else
            return ((self.mainHandItemType and OVALE_ONE_HANDED_WEAPON[self.mainHandItemType]) or (self.offHandItemType and OVALE_ONE_HANDED_WEAPON[self.offHandItemType]))
        end
        return false
    end,
    UpdateItemBySlot = function(self, slotId)
        local prevItemId = self.equippedItemBySlot[slotId]
        if prevItemId then
            self.equippedItemById[prevItemId] = nil
        end
        local newItemId = GetInventoryItemID("player", slotId)
        if newItemId then
            self.equippedItemById[newItemId] = slotId
            self.equippedItemBySlot[slotId] = newItemId
            if slotId == OVALE_SLOTID_BY_SLOTNAME["MainHandSlot"] then
                local itemEquipLoc, dps = self:UpdateWeapons(slotId, newItemId)
                self.mainHandItemType = itemEquipLoc
                self.mainHandDPS = dps
            elseif slotId == OVALE_SLOTID_BY_SLOTNAME["SecondaryHandSlot"] then
                local itemEquipLoc, dps = self:UpdateWeapons(slotId, newItemId)
                self.offHandItemType = itemEquipLoc
                self.offHandDPS = dps
            end
        else
            self.equippedItemBySlot[slotId] = nil
            if slotId == OVALE_SLOTID_BY_SLOTNAME["MainHandSlot"] then
                self.mainHandItemType = nil
                self.mainHandDPS = 0
            elseif slotId == OVALE_SLOTID_BY_SLOTNAME["SecondaryHandSlot"] then
                self.offHandItemType = nil
                self.offHandDPS = 0
            end
        end
        if prevItemId ~= newItemId then
            return true
        end
        return false
    end,
    UpdateWeapons = function(self, slotId, itemId)
        local _, _, _, itemEquipLoc = GetItemInfoInstant(itemId)
        local dps = 0
        local itemLink = GetInventoryItemLink("player", slotId)
        if itemLink then
            local stats = GetItemStats(itemLink)
            if stats then
                dps = stats["ITEM_MOD_DAMAGE_PER_SECOND_SHORT"] or 0
            end
        end
        return itemEquipLoc, dps
    end,
    DebugEquipment = function(self)
        wipe(self.output)
        local array = {}
        for slotId, slotName in ipairs(OVALE_SLOTNAME_BY_SLOTID) do
            local itemId = self.equippedItemBySlot[slotId] or ""
            local shortSlotName = sub(slotName, 1, -5)
            insert(array, shortSlotName .. ": " .. itemId)
        end
        insert(array, [[
]])
        insert(array, "Main Hand DPS = " .. self.mainHandDPS)
        if self:HasOffHandWeapon() then
            insert(array, "Off hand DPS = " .. self.offHandDPS)
        end
        for _, v in ipairs(array) do
            self.output[#self.output + 1] = v
        end
        return concat(self.output, "\n")
    end,
})
