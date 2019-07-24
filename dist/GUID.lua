local __exports = LibStub:NewLibrary("ovale/GUID", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local floor = math.floor
local ipairs = ipairs
local setmetatable = setmetatable
local type = type
local unpack = unpack
local insert = table.insert
local remove = table.remove
local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitName = UnitName
local OvaleGUIDBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleGUID", aceEvent))
local PET_UNIT = {}
do
    PET_UNIT["player"] = "pet"
    for i = 1, 5, 1 do
        PET_UNIT["arena" .. i] = "arenapet" .. i
    end
    for i = 1, 4, 1 do
        PET_UNIT["party" .. i] = "partypet" .. i
    end
    for i = 1, 40, 1 do
        PET_UNIT["raid" .. i] = "raidpet" .. i
    end
    setmetatable(PET_UNIT, {
        __index = function(t, unitId)
            return unitId .. "pet"
        end

    })
end
local UNIT_AURA_UNITS = {}
do
    insert(UNIT_AURA_UNITS, "player")
    insert(UNIT_AURA_UNITS, "pet")
    insert(UNIT_AURA_UNITS, "vehicle")
    insert(UNIT_AURA_UNITS, "target")
    insert(UNIT_AURA_UNITS, "focus")
    for i = 1, 40, 1 do
        local unitId = "raid" .. i
        insert(UNIT_AURA_UNITS, unitId)
        insert(UNIT_AURA_UNITS, PET_UNIT[unitId])
    end
    for i = 1, 4, 1 do
        local unitId = "party" .. i
        insert(UNIT_AURA_UNITS, unitId)
        insert(UNIT_AURA_UNITS, PET_UNIT[unitId])
    end
    for i = 1, 4, 1 do
        insert(UNIT_AURA_UNITS, "boss" .. i)
    end
    for i = 1, 5, 1 do
        local unitId = "arena" .. i
        insert(UNIT_AURA_UNITS, unitId)
        insert(UNIT_AURA_UNITS, PET_UNIT[unitId])
    end
    insert(UNIT_AURA_UNITS, "npc")
end
local UNIT_AURA_UNIT = {}
for i, unitId in ipairs(UNIT_AURA_UNITS) do
    UNIT_AURA_UNIT[unitId] = i
end
setmetatable(UNIT_AURA_UNIT, {
    __index = function(t, unitId)
        return #UNIT_AURA_UNITS + 1
    end

})
local function compareDefault(a, b)
    return a < b
end
local function isCompareFunction(a)
    return type(a) == "function"
end
local function BinaryInsert(t, value, unique, compare)
    if isCompareFunction(unique) then
        unique, compare = false, unique
    end
    compare = compare or compareDefault
    local low, high = 1, #t
    while low <= high do
        local mid = floor((low + high) / 2)
        if compare(value, t[mid]) then
            high = mid - 1
        elseif  not unique or compare(t[mid], value) then
            low = mid + 1
        else
            return mid
        end
    end
    insert(t, low, value)
    return low
end
local function BinarySearch(t, value, compare)
    compare = compare or compareDefault
    local low, high = 1, #t
    while low <= high do
        local mid = floor((low + high) / 2)
        if compare(value, t[mid]) then
            high = mid - 1
        elseif compare(t[mid], value) then
            low = mid + 1
        else
            return mid
        end
    end
    return nil
end
local function BinaryRemove(t, value, compare)
    local index = BinarySearch(t, value, compare)
    if index then
        remove(t, index)
    end
    return index
end
local CompareUnit = function(a, b)
    return UNIT_AURA_UNIT[a] < UNIT_AURA_UNIT[b]
end

__exports.OvaleGUIDClass = __class(OvaleGUIDBase, {
    OnInitialize = function(self)
        self.RegisterEvent("ARENA_OPPONENT_UPDATE")
        self.RegisterEvent("GROUP_ROSTER_UPDATE")
        self.RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
        self.RegisterEvent("PLAYER_ENTERING_WORLD", function(event)
            return self:UpdateAllUnits()
        end)
        self.RegisterEvent("PLAYER_FOCUS_CHANGED")
        self.RegisterEvent("PLAYER_TARGET_CHANGED")
        self.RegisterEvent("UNIT_NAME_UPDATE")
        self.RegisterEvent("UNIT_PET")
        self.RegisterEvent("UNIT_TARGET")
    end,
    OnDisable = function(self)
        self.UnregisterEvent("ARENA_OPPONENT_UPDATE")
        self.UnregisterEvent("GROUP_ROSTER_UPDATE")
        self.UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
        self.UnregisterEvent("PLAYER_ENTERING_WORLD")
        self.UnregisterEvent("PLAYER_FOCUS_CHANGED")
        self.UnregisterEvent("PLAYER_TARGET_CHANGED")
        self.UnregisterEvent("UNIT_NAME_UPDATE")
        self.UnregisterEvent("UNIT_PET")
        self.UnregisterEvent("UNIT_TARGET")
    end,
    ARENA_OPPONENT_UPDATE = function(self, event, unitId, eventType)
        if eventType ~= "cleared" or self.unitGUID[unitId] then
            self.Debug(event, unitId, eventType)
            self:UpdateUnitWithTarget(unitId)
        end
    end,
    GROUP_ROSTER_UPDATE = function(self, event)
        self.Debug(event)
        self:UpdateAllUnits()
        self.SendMessage("Ovale_GroupChanged")
    end,
    INSTANCE_ENCOUNTER_ENGAGE_UNIT = function(self, event)
        self.Debug(event)
        for i = 1, 4, 1 do
            self:UpdateUnitWithTarget("boss" .. i)
        end
    end,
    PLAYER_FOCUS_CHANGED = function(self, event)
        self.Debug(event)
        self:UpdateUnitWithTarget("focus")
    end,
    PLAYER_TARGET_CHANGED = function(self, event, cause)
        self.Debug(event, cause)
        self:UpdateUnit("target")
    end,
    UNIT_NAME_UPDATE = function(self, event, unitId)
        self.Debug(event, unitId)
        self:UpdateUnit(unitId)
    end,
    UNIT_PET = function(self, event, unitId)
        self.Debug(event, unitId)
        local pet = PET_UNIT[unitId]
        self:UpdateUnitWithTarget(pet)
        if unitId == "player" then
            local guid = self:UnitGUID("pet")
            if guid then
                self.petGUID[guid] = GetTime()
            end
            self.SendMessage("Ovale_PetChanged", guid)
        end
        self.SendMessage("Ovale_GroupChanged")
    end,
    UNIT_TARGET = function(self, event, unitId)
        if unitId ~= "player" then
            self.Debug(event, unitId)
            local target = unitId .. "target"
            self:UpdateUnit(target)
        end
    end,
    UpdateAllUnits = function(self)
        for _, unitId in ipairs(UNIT_AURA_UNITS) do
            self:UpdateUnitWithTarget(unitId)
        end
    end,
    UpdateUnit = function(self, unitId)
        local guid = UnitGUID(unitId)
        local name = UnitName(unitId)
        local previousGUID = self.unitGUID[unitId]
        local previousName = self.unitName[unitId]
        if  not guid or guid ~= previousGUID then
            self.unitGUID[unitId] = nil
            if previousGUID then
                if self.guidUnit[previousGUID] then
                    BinaryRemove(self.guidUnit[previousGUID], unitId, CompareUnit)
                end
                Ovale.refreshNeeded[previousGUID] = true
            end
        end
        if  not name or name ~= previousName then
            self.unitName[unitId] = nil
            if previousName and self.nameUnit[previousName] then
                BinaryRemove(self.nameUnit[previousName], unitId, CompareUnit)
            end
        end
        if guid and guid == previousGUID and name and name ~= previousName then
            self.guidName[guid] = nil
            if previousName and self.nameGUID[previousName] then
                BinaryRemove(self.nameGUID[previousName], guid, CompareUnit)
            end
        end
        if guid and guid ~= previousGUID then
            self.unitGUID[unitId] = guid
            do
                local list = self.guidUnit[guid] or {}
                BinaryInsert(list, unitId, true, CompareUnit)
                self.guidUnit[guid] = list
            end
            self.Debug("'%s' is '%s'.", unitId, guid)
            Ovale.refreshNeeded[guid] = true
        end
        if name and name ~= previousName then
            self.unitName[unitId] = name
            do
                local list = self.nameUnit[name] or {}
                BinaryInsert(list, unitId, true, CompareUnit)
                self.nameUnit[name] = list
            end
            self.Debug("'%s' is '%s'.", unitId, name)
        end
        if guid and name then
            local previousNameFromGUID = self.guidName[guid]
            self.guidName[guid] = name
            if name ~= previousNameFromGUID then
                local list = self.nameGUID[name] or {}
                BinaryInsert(list, guid, true)
                self.nameGUID[name] = list
                if guid == previousGUID then
                    self.Debug("'%s' changed names to '%s'.", guid, name)
                else
                    self.Debug("'%s' is '%s'.", guid, name)
                end
            end
        end
        if guid and guid ~= previousGUID then
            self.SendMessage("Ovale_UnitChanged", unitId, guid)
        end
    end,
    UpdateUnitWithTarget = function(self, unitId)
        self:UpdateUnit(unitId)
        self:UpdateUnit(unitId .. "target")
    end,
    IsPlayerPet = function(self, guid)
        local atTime = self.petGUID[guid]
        return ( not  not atTime), atTime
    end,
    UnitGUID = function(self, unitId)
        return self.unitGUID[unitId] or UnitGUID(unitId)
    end,
    GUIDUnit = function(self, guid)
        if guid and self.guidUnit[guid] then
            return unpack(self.guidUnit[guid])
        end
        return nil
    end,
    UnitName = function(self, unitId)
        if unitId then
            return self.unitName[unitId] or UnitName(unitId)
        end
        return nil
    end,
    NameUnit = function(self, name)
        if name and self.nameUnit[name] then
            return unpack(self.nameUnit[name])
        end
        return nil
    end,
    GUIDName = function(self, guid)
        if guid then
            return self.guidName[guid]
        end
        return nil
    end,
    NameGUID = function(self, name)
        if name and self.nameGUID[name] then
            return unpack(self.nameGUID[name])
        end
        return nil
    end,
    constructor = function(self, ...)
        OvaleGUIDBase.constructor(self, ...)
        self.unitGUID = {}
        self.guidUnit = {}
        self.unitName = {}
        self.nameUnit = {}
        self.guidName = {}
        self.nameGUID = {}
        self.petGUID = {}
        self.UNIT_AURA_UNIT = UNIT_AURA_UNIT
    end
})
