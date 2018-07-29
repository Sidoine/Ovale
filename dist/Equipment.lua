local __exports = LibStub:NewLibrary("ovale/Equipment", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local pairs = pairs
local select = select
local type = type
local unpack = unpack
local wipe = wipe
local GetInventoryItemID = GetInventoryItemID
local GetItemInfoInstant = GetItemInfoInstant
local INVSLOT_AMMO = INVSLOT_AMMO
local INVSLOT_BACK = INVSLOT_BACK
local INVSLOT_BODY = INVSLOT_BODY
local INVSLOT_CHEST = INVSLOT_CHEST
local INVSLOT_FEET = INVSLOT_FEET
local INVSLOT_FINGER1 = INVSLOT_FINGER1
local INVSLOT_FINGER2 = INVSLOT_FINGER2
local INVSLOT_FIRST_EQUIPPED = INVSLOT_FIRST_EQUIPPED
local INVSLOT_HAND = INVSLOT_HAND
local INVSLOT_HEAD = INVSLOT_HEAD
local INVSLOT_LEGS = INVSLOT_LEGS
local INVSLOT_MAINHAND = INVSLOT_MAINHAND
local INVSLOT_NECK = INVSLOT_NECK
local INVSLOT_OFFHAND = INVSLOT_OFFHAND
local INVSLOT_SHOULDER = INVSLOT_SHOULDER
local INVSLOT_TABARD = INVSLOT_TABARD
local INVSLOT_TRINKET1 = INVSLOT_TRINKET1
local INVSLOT_TRINKET2 = INVSLOT_TRINKET2
local INVSLOT_WAIST = INVSLOT_WAIST
local INVSLOT_WRIST = INVSLOT_WRIST
local OvaleEquipmentBase = OvaleDebug:RegisterDebugging(OvaleProfiler:RegisterProfiling(Ovale:NewModule("OvaleEquipment", aceEvent)))
local OVALE_SLOTNAME = {
    AmmoSlot = INVSLOT_AMMO,
    BackSlot = INVSLOT_BACK,
    ChestSlot = INVSLOT_CHEST,
    FeetSlot = INVSLOT_FEET,
    Finger0Slot = INVSLOT_FINGER1,
    Finger1Slot = INVSLOT_FINGER2,
    HandsSlot = INVSLOT_HAND,
    HeadSlot = INVSLOT_HEAD,
    LegsSlot = INVSLOT_LEGS,
    MainHandSlot = INVSLOT_MAINHAND,
    NeckSlot = INVSLOT_NECK,
    SecondaryHandSlot = INVSLOT_OFFHAND,
    ShirtSlot = INVSLOT_BODY,
    ShoulderSlot = INVSLOT_SHOULDER,
    TabardSlot = INVSLOT_TABARD,
    Trinket0Slot = INVSLOT_TRINKET1,
    Trinket1Slot = INVSLOT_TRINKET2,
    WaistSlot = INVSLOT_WAIST,
    WristSlot = INVSLOT_WRIST
}
local OVALE_ARMORSET_SLOT_IDS = {
    [1] = INVSLOT_CHEST,
    [2] = INVSLOT_HAND,
    [3] = INVSLOT_HEAD,
    [4] = INVSLOT_LEGS,
    [5] = INVSLOT_SHOULDER,
    [6] = INVSLOT_BACK
}
local OVALE_ARMORSET = {}
local result = {}
local count = 0
local armorSetName = {}
local OvaleEquipmentClass = __class(OvaleEquipmentBase, {
    constructor = function(self)
        self.ready = false
        self.equippedItemById = {}
        self.equippedItemBySlot = {}
        self.mainHandItemType = nil
        self.offHandItemType = nil
        self.armorSetCount = {}
        self.offhandHasWeapon = nil
        OvaleEquipmentBase.constructor(self)
    end,
    OnInitialize = function(self)
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateEquippedItems")
        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    end,
    OnDisable = function(self)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
    end,
    PLAYER_EQUIPMENT_CHANGED = function(self, event, slotId, hasItem)
        self:StartProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED")
        local changed = self:UpdateItemBySlot(slotId)
        if changed then
            self:UpdateArmorSetCount()
            Ovale:needRefresh()
            self:SendMessage("Ovale_EquipmentChanged")
        end
        self:StopProfiling("OvaleEquipment_PLAYER_EQUIPMENT_CHANGED")
    end,
    GetArmorSetCount = function(self, name)
        local count = self.armorSetCount[name]
        if  not count then
            local className = Ovale.playerClass
            if armorSetName[className] and armorSetName[className][name] then
                name = armorSetName[className][name]
                count = self.armorSetCount[name]
            end
        end
        return count or 0
    end,
    GetEquippedItem = function(self, ...)
        count = select("#", ...)
        for n = 1, count, 1 do
            local slotId = select(n, ...)
            if slotId and type(slotId) ~= "number" then
                slotId = OVALE_SLOTNAME[slotId]
            end
            if slotId then
                result[n] = self.equippedItemBySlot[slotId]
            else
                result[n] = nil
            end
        end
        if count > 0 then
            return unpack(result, 1, count)
        else
            return nil
        end
    end,
    GetEquippedTrinkets = function(self)
        return self.equippedItemBySlot[INVSLOT_TRINKET1], self.equippedItemBySlot[INVSLOT_TRINKET2]
    end,
    HasEquippedItem = function(self, itemId)
        return self.equippedItemById[itemId]
    end,
    HasShield = function(self)
        return self.offHandItemType == "INVTYPE_SHIELD"
    end,
    HasRangedWeapon = function(self)
        return (self.mainHandItemType == "INVTYPE_RANGEDRIGHT" or self.mainHandItemType == "INVTYPE_RANGED")
    end,
    HasTrinket = function(self, itemId)
        return self:HasEquippedItem(itemId)
    end,
    UpdateArmorSetCount = function(self)
        self:StartProfiling("OvaleEquipment_UpdateArmorSetCount")
        wipe(self.armorSetCount)
        for i = 1, #OVALE_ARMORSET_SLOT_IDS, 1 do
            local itemId = self:GetEquippedItem(OVALE_ARMORSET_SLOT_IDS[i])
            if itemId then
                local name = OVALE_ARMORSET[itemId]
                if name then
                    if  not self.armorSetCount[name] then
                        self.armorSetCount[name] = 1
                    else
                        self.armorSetCount[name] = self.armorSetCount[name] + 1
                    end
                end
            end
        end
        self:StopProfiling("OvaleEquipment_UpdateArmorSetCount")
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
            if slotId == INVSLOT_MAINHAND then
                local _, _, _, itemEquipLoc = GetItemInfoInstant(newItemId)
                self.mainHandItemType = itemEquipLoc
            elseif slotId == INVSLOT_OFFHAND then
                local _, _, _, itemEquipLoc = GetItemInfoInstant(newItemId)
                self.offHandItemType = itemEquipLoc
            end
        else
            self.equippedItemBySlot[slotId] = nil
            if slotId == INVSLOT_MAINHAND then
                self.mainHandItemType = nil
            elseif slotId == INVSLOT_OFFHAND then
                self.offHandItemType = nil
            end
        end
        if prevItemId ~= newItemId then
            return true
        end
        return false
    end,
    UpdateEquippedItems = function(self)
        self:StartProfiling("OvaleEquipment_UpdateEquippedItems")
        local changed = false
        for slotId = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED, 1 do
            if self:UpdateItemBySlot(slotId) then
                changed = true
            end
        end
        if changed then
            self:UpdateArmorSetCount()
            Ovale:needRefresh()
            self:SendMessage("Ovale_EquipmentChanged")
        end
        self.ready = true
        self:StopProfiling("OvaleEquipment_UpdateEquippedItems")
    end,
    DebugEquipment = function(self)
        for slotId = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED, 1 do
            self:Print("Slot %d = %s", slotId, self:GetEquippedItem(slotId))
        end
        self:Print("Main-hand item type: %s", self.mainHandItemType)
        self:Print("Off-hand item type: %s", self.offHandItemType)
        for k, v in pairs(self.armorSetCount) do
            self:Print("Player has %d piece(s) of %s armor set.", v, k)
        end
    end,
})
__exports.OvaleEquipment = OvaleEquipmentClass()
