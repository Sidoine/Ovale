local __exports = LibStub:NewLibrary("ovale/Spells", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Requirement = LibStub:GetLibrary("ovale/Requirement")
local RegisterRequirement = __Requirement.RegisterRequirement
local UnregisterRequirement = __Requirement.UnregisterRequirement
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local tonumber = tonumber
local GetSpellCount = GetSpellCount
local IsSpellInRange = IsSpellInRange
local IsUsableItem = IsUsableItem
local IsUsableSpell = IsUsableSpell
local UnitIsFriend = UnitIsFriend
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
local __Power = LibStub:GetLibrary("ovale/Power")
local OvalePower = __Power.OvalePower
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local WARRIOR_INCERCEPT_SPELLID = 198304
local WARRIOR_HEROICTHROW_SPELLID = 57755
local OvaleSpellsBase = OvaleProfiler:RegisterProfiling(OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleSpellBook", aceEvent)))
local OvaleSpellsClass = __class(OvaleSpellsBase, {
    OnInitialize = function(self)
        RegisterRequirement("spellcount_min", self.RequireSpellCountHandler)
        RegisterRequirement("spellcount_max", self.RequireSpellCountHandler)
    end,
    OnDisable = function(self)
        UnregisterRequirement("spellcount_max")
        UnregisterRequirement("spellcount_min")
    end,
    GetCastTime = function(self, spellId)
        if spellId then
            local name, _, _, castTime = OvaleSpellBook:GetSpellInfo(spellId)
            if name then
                if castTime then
                    castTime = castTime / 1000
                else
                    castTime = 0
                end
            else
                castTime = nil
            end
            return castTime
        end
    end,
    GetSpellCount = function(self, spellId)
        local index, bookType = OvaleSpellBook:GetSpellBookIndex(spellId)
        if index and bookType then
            local spellCount = GetSpellCount(index, bookType)
            self:Debug("GetSpellCount: index=%s bookType=%s for spellId=%s ==> spellCount=%s", index, bookType, spellId, spellCount)
            return spellCount
        else
            local spellName = OvaleSpellBook:GetSpellName(spellId)
            local spellCount = GetSpellCount(spellName)
            self:Debug("GetSpellCount: spellName=%s for spellId=%s ==> spellCount=%s", spellName, spellId, spellCount)
            return spellCount
        end
    end,
    IsSpellInRange = function(self, spellId, unitId)
        local index, bookType = OvaleSpellBook:GetSpellBookIndex(spellId)
        local returnValue = nil
        if index and bookType then
            returnValue = IsSpellInRange(index, bookType, unitId)
        elseif OvaleSpellBook:IsKnownSpell(spellId) then
            local name = OvaleSpellBook:GetSpellName(spellId)
            returnValue = IsSpellInRange(name, unitId)
        end
        if (returnValue == 1 and spellId == WARRIOR_INCERCEPT_SPELLID) then
            return (UnitIsFriend("player", unitId) == 1 or __exports.OvaleSpells:IsSpellInRange(WARRIOR_HEROICTHROW_SPELLID, unitId) == 1) and 1 or 0
        end
        return returnValue
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    IsUsableItem = function(self, itemId, atTime)
        __exports.OvaleSpells:StartProfiling("OvaleSpellBook_state_IsUsableItem")
        local isUsable = IsUsableItem(itemId)
        local ii = OvaleData:ItemInfo(itemId)
        if ii then
            if isUsable then
                local unusable = OvaleData:GetItemInfoProperty(itemId, atTime, "unusable")
                if unusable and unusable > 0 then
                    __exports.OvaleSpells:Log("Item ID '%s' is flagged as unusable.", itemId)
                    isUsable = false
                end
            end
        end
        __exports.OvaleSpells:StopProfiling("OvaleSpellBook_state_IsUsableItem")
        return isUsable
    end,
    IsUsableSpell = function(self, spellId, atTime, targetGUID)
        __exports.OvaleSpells:StartProfiling("OvaleSpellBook_state_IsUsableSpell")
        local isUsable = OvaleSpellBook:IsKnownSpell(spellId)
        local noMana = false
        local si = OvaleData.spellInfo[spellId]
        if si then
            if isUsable then
                local unusable = OvaleData:GetSpellInfoProperty(spellId, atTime, "unusable", targetGUID)
                if unusable and unusable > 0 then
                    __exports.OvaleSpells:Log("Spell ID '%s' is flagged as unusable.", spellId)
                    isUsable = false
                end
            end
            if isUsable then
                local requirement
                isUsable, requirement = OvaleData:CheckSpellInfo(spellId, atTime, targetGUID)
                if  not isUsable then
                    noMana = OvalePower.PRIMARY_POWER[requirement]
                    if noMana then
                        __exports.OvaleSpells:Log("Spell ID '%s' does not have enough %s.", spellId, requirement)
                    else
                        __exports.OvaleSpells:Log("Spell ID '%s' failed '%s' requirements.", spellId, requirement)
                    end
                end
            end
        else
            local index, bookType = OvaleSpellBook:GetSpellBookIndex(spellId)
            if index and bookType then
                return IsUsableSpell(index, bookType)
            elseif OvaleSpellBook:IsKnownSpell(spellId) then
                local name = OvaleSpellBook:GetSpellName(spellId)
                return IsUsableSpell(name)
            end
        end
        __exports.OvaleSpells:StopProfiling("OvaleSpellBook_state_IsUsableSpell")
        return isUsable, noMana
    end,
    constructor = function(self, ...)
        OvaleSpellsBase.constructor(self, ...)
        self.RequireSpellCountHandler = function(spellId, atTime, requirement, tokens, index, targetGUID)
            local verified = false
            local countString
            if index then
                countString = tokens[index]
                index = index + 1
            end
            if countString then
                local count = tonumber(countString) or 1
                local actualCount = __exports.OvaleSpells:GetSpellCount(spellId)
                verified = (requirement == "spellcount_min" and count <= actualCount) or (requirement == "spellcount_max" and count >= actualCount)
            else
                Ovale:OneTimeMessage("Warning: requirement '%s' is missing a count argument.", requirement)
            end
            return verified, requirement, index
        end
    end
})
__exports.OvaleSpells = OvaleSpellsClass()
OvaleState:RegisterState(__exports.OvaleSpells)
