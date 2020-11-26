local __exports = LibStub:NewLibrary("ovale/states/Equipment", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local pairs = pairs
local wipe = wipe
local ipairs = ipairs
local kpairs = pairs
local type = type
local sub = string.sub
local GetInventoryItemID = GetInventoryItemID
local GetInventoryItemLink = GetInventoryItemLink
local GetItemStats = GetItemStats
local GetItemInfoInstant = GetItemInfoInstant
local GetInventorySlotInfo = GetInventorySlotInfo
local INVSLOT_FIRST_EQUIPPED = INVSLOT_FIRST_EQUIPPED
local INVSLOT_LAST_EQUIPPED = INVSLOT_LAST_EQUIPPED
local GetItemCooldown = GetItemCooldown
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local GetTime = GetTime
local concat = table.concat
local insert = table.insert
local __tools = LibStub:GetLibrary("ovale/tools")
local isNumber = __tools.isNumber
local __Condition = LibStub:GetLibrary("ovale/Condition")
local Compare = __Condition.Compare
local TestBoolean = __Condition.TestBoolean
local TestValue = __Condition.TestValue
local huge = math.huge
local OVALE_SLOTID_BY_SLOTNAME = {
    ammoslot = 0,
    headslot = 1,
    neckslot = 2,
    shoulderslot = 3,
    shirtslot = 4,
    chestslot = 5,
    waistslot = 6,
    legsslot = 7,
    feetslot = 8,
    wristslot = 9,
    handsslot = 10,
    finger0slot = 11,
    finger1slot = 12,
    trinket0slot = 13,
    trinket1slot = 14,
    backslot = 15,
    mainhandslot = 16,
    secondaryhandslot = 17,
    tabardslot = 19
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
    constructor = function(self, ovale, ovaleDebug, ovaleProfiler, OvaleData)
        self.ovale = ovale
        self.OvaleData = OvaleData
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
        self.hasEquippedItem = function(positionalParams, namedParams, atTime)
            local itemId, yesno = positionalParams[1], positionalParams[2]
            local boolean = false
            local slotId
            if type(itemId) == "number" then
                slotId = self:HasEquippedItem(itemId)
                if slotId then
                    boolean = true
                end
            elseif self.OvaleData.itemList[itemId] then
                for _, v in pairs(self.OvaleData.itemList[itemId]) do
                    slotId = self:HasEquippedItem(v)
                    if slotId then
                        boolean = true
                        break
                    end
                end
            end
            return TestBoolean(boolean, yesno)
        end
        self.hasShield = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean = self:HasShield()
            return TestBoolean(boolean, yesno)
        end
        self.hasTrinket = function(positionalParams, namedParams, atTime)
            local trinketId, yesno = positionalParams[1], positionalParams[2]
            local boolean = nil
            if type(trinketId) == "number" then
                boolean = self:HasTrinket(trinketId)
            elseif self.OvaleData.itemList[trinketId] then
                for _, v in pairs(self.OvaleData.itemList[trinketId]) do
                    boolean = self:HasTrinket(v)
                    if boolean then
                        break
                    end
                end
            end
            return TestBoolean(boolean ~= nil, yesno)
        end
        self.ItemCooldown = function(positionalParams, namedParams, atTime)
            local itemId, comparator, limit = positionalParams[1], positionalParams[2], positionalParams[3]
            if itemId and type(itemId) ~= "number" then
                itemId = self:GetEquippedItemBySlotName(itemId)
            end
            if itemId then
                local start, duration = GetItemCooldown(itemId)
                if start > 0 and duration > 0 then
                    return TestValue(start, start + duration, duration, start, -1, comparator, limit)
                end
            end
            return Compare(0, comparator, limit)
        end
        self.WeaponEnchantExpires = function(positionalParams)
            local expectedEnchantmentId = positionalParams[1]
            local hand = positionalParams[2]
            local hasMainHandEnchant, mainHandExpiration, enchantmentId, hasOffHandEnchant, offHandExpiration = GetWeaponEnchantInfo()
            local now = GetTime()
            if hand == "main" or hand == nil then
                if hasMainHandEnchant and expectedEnchantmentId == enchantmentId then
                    mainHandExpiration = mainHandExpiration / 1000
                    return now + mainHandExpiration, huge
                end
            elseif hand == "offhand" or hand == "off" then
                if hasOffHandEnchant then
                    offHandExpiration = offHandExpiration / 1000
                    return now + offHandExpiration, huge
                end
            end
            return 0, huge
        end
        self.weaponEnchantPresent = function(positionalParams)
            local expectedEnchantmentId = positionalParams[1]
            local hand = positionalParams[2]
            local hasMainHandEnchant, mainHandExpiration, enchantmentId, hasOffHandEnchant, offHandExpiration = GetWeaponEnchantInfo()
            local now = GetTime()
            if hand == "main" or hand == nil then
                if hasMainHandEnchant and expectedEnchantmentId == enchantmentId then
                    mainHandExpiration = mainHandExpiration / 1000
                    return 0, now + mainHandExpiration
                end
            elseif hand == "offhand" or hand == "off" then
                if hasOffHandEnchant then
                    offHandExpiration = offHandExpiration / 1000
                    return 0, now + offHandExpiration
                end
            end
            return 
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
    registerConditions = function(self, ovaleCondition)
        ovaleCondition:RegisterCondition("hasequippeditem", false, self.hasEquippedItem)
        ovaleCondition:RegisterCondition("hasshield", false, self.hasShield)
        ovaleCondition:RegisterCondition("hastrinket", false, self.hasTrinket)
        ovaleCondition:RegisterCondition("itemcooldown", false, self.ItemCooldown)
        ovaleCondition:RegisterCondition("weaponenchantexpires", false, self.WeaponEnchantExpires)
        ovaleCondition:RegisterCondition("weaponenchantpresent", false, self.weaponEnchantPresent)
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
        return self.equippedItemBySlot[OVALE_SLOTID_BY_SLOTNAME["trinket0slot"]], self.equippedItemBySlot[OVALE_SLOTID_BY_SLOTNAME["trinket1slot"]]
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
            if slotId == OVALE_SLOTID_BY_SLOTNAME["mainhandslot"] then
                return (self.mainHandItemType and OVALE_ONE_HANDED_WEAPON[self.mainHandItemType])
            elseif slotId == OVALE_SLOTID_BY_SLOTNAME["secondaryhandslot"] then
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
            if slotId == OVALE_SLOTID_BY_SLOTNAME["mainhandslot"] then
                local itemEquipLoc, dps = self:UpdateWeapons(slotId, newItemId)
                self.mainHandItemType = itemEquipLoc
                self.mainHandDPS = dps
            elseif slotId == OVALE_SLOTID_BY_SLOTNAME["secondaryhandslot"] then
                local itemEquipLoc, dps = self:UpdateWeapons(slotId, newItemId)
                self.offHandItemType = itemEquipLoc
                self.offHandDPS = dps
            end
        else
            self.equippedItemBySlot[slotId] = nil
            if slotId == OVALE_SLOTID_BY_SLOTNAME["mainhandslot"] then
                self.mainHandItemType = nil
                self.mainHandDPS = 0
            elseif slotId == OVALE_SLOTID_BY_SLOTNAME["secondaryhandslot"] then
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
