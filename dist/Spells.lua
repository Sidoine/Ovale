local __exports = LibStub:NewLibrary("ovale/Spells", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local tonumber = tonumber
local GetSpellCount = GetSpellCount
local IsSpellInRange = IsSpellInRange
local IsUsableItem = IsUsableItem
local IsUsableSpell = IsUsableSpell
local UnitIsFriend = UnitIsFriend
local __statesPower = LibStub:GetLibrary("ovale/states/Power")
local PRIMARY_POWER = __statesPower.PRIMARY_POWER
local __tools = LibStub:GetLibrary("ovale/tools")
local OneTimeMessage = __tools.OneTimeMessage
local WARRIOR_INCERCEPT_SPELLID = 198304
local WARRIOR_HEROICTHROW_SPELLID = 57755
__exports.OvaleSpellsClass = __class(nil, {
    constructor = function(self, OvaleSpellBook, ovale, ovaleDebug, ovaleProfiler, ovaleData, requirement)
        self.OvaleSpellBook = OvaleSpellBook
        self.ovaleData = ovaleData
        self.requirement = requirement
        self.OnInitialize = function()
            self.requirement:RegisterRequirement("spellcount_min", self.RequireSpellCountHandler)
            self.requirement:RegisterRequirement("spellcount_max", self.RequireSpellCountHandler)
        end
        self.OnDisable = function()
            self.requirement:UnregisterRequirement("spellcount_max")
            self.requirement:UnregisterRequirement("spellcount_min")
        end
        self.RequireSpellCountHandler = function(spellId, atTime, requirement, tokens, index, targetGUID)
            local verified = false
            local countString
            if index then
                countString = tokens[index]
                index = index + 1
            end
            if countString then
                local count = tonumber(countString) or 1
                local actualCount = self:GetSpellCount(spellId)
                verified = (requirement == "spellcount_min" and count <= actualCount) or (requirement == "spellcount_max" and count >= actualCount)
            else
                OneTimeMessage("Warning: requirement '%s' is missing a count argument.", requirement)
            end
            return verified, requirement, index
        end
        self.module = ovale:createModule("OvaleSpells", self.OnInitialize, self.OnDisable, aceEvent)
        self.tracer = ovaleDebug:create(self.module:GetName())
        self.profiler = ovaleProfiler:create(self.module:GetName())
    end,
    GetCastTime = function(self, spellId)
        if spellId then
            local name, _, _, castTime = self.OvaleSpellBook:GetSpellInfo(spellId)
            if name then
                if castTime then
                    castTime = castTime / 1000
                else
                    castTime = 0
                end
            else
                return nil
            end
            return castTime
        end
    end,
    GetSpellCount = function(self, spellId)
        local index, bookType = self.OvaleSpellBook:GetSpellBookIndex(spellId)
        if index and bookType then
            local spellCount = GetSpellCount(index, bookType)
            self.tracer:Debug("GetSpellCount: index=%s bookType=%s for spellId=%s ==> spellCount=%s", index, bookType, spellId, spellCount)
            return spellCount
        else
            local spellName = self.OvaleSpellBook:GetSpellName(spellId)
            if spellName then
                local spellCount = GetSpellCount(spellName)
                self.tracer:Debug("GetSpellCount: spellName=%s for spellId=%s ==> spellCount=%s", spellName, spellId, spellCount)
                return spellCount
            end
            return 0
        end
    end,
    IsSpellInRange = function(self, spellId, unitId)
        local index, bookType = self.OvaleSpellBook:GetSpellBookIndex(spellId)
        local returnValue
        if index and bookType then
            returnValue = IsSpellInRange(index, bookType, unitId)
        elseif self.OvaleSpellBook:IsKnownSpell(spellId) then
            local name = self.OvaleSpellBook:GetSpellName(spellId)
            if name then
                returnValue = IsSpellInRange(name, unitId)
            end
        end
        if returnValue == 1 and spellId == WARRIOR_INCERCEPT_SPELLID then
            return (UnitIsFriend("player", unitId) or self:IsSpellInRange(WARRIOR_HEROICTHROW_SPELLID, unitId))
        end
        if returnValue == 1 then
            return true
        end
        if returnValue == 0 then
            return false
        end
        return nil
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    IsUsableItem = function(self, itemId, atTime)
        self.profiler:StartProfiling("OvaleSpellBook_state_IsUsableItem")
        local isUsable = IsUsableItem(itemId)
        local ii = self.ovaleData:ItemInfo(itemId)
        if ii then
            if isUsable then
                local unusable = self.ovaleData:GetItemInfoProperty(itemId, atTime, "unusable")
                if unusable and unusable > 0 then
                    self.tracer:Log("Item ID '%s' is flagged as unusable.", itemId)
                    isUsable = false
                end
            end
        end
        self.profiler:StopProfiling("OvaleSpellBook_state_IsUsableItem")
        return isUsable
    end,
    IsUsableSpell = function(self, spellId, atTime, targetGUID)
        self.profiler:StartProfiling("OvaleSpellBook_state_IsUsableSpell")
        local isUsable = self.OvaleSpellBook:IsKnownSpell(spellId)
        local noMana = false
        local si = self.ovaleData.spellInfo[spellId]
        local requirement
        if si then
            if isUsable then
                local unusable = self.ovaleData:GetSpellInfoProperty(spellId, atTime, "unusable", targetGUID)
                if unusable and unusable > 0 then
                    self.tracer:Log("Spell ID '%s' is flagged as unusable.", spellId)
                    isUsable = false
                end
            end
            if isUsable then
                isUsable, requirement = self.ovaleData:CheckSpellInfo(spellId, atTime, targetGUID)
                if  not isUsable then
                    noMana = PRIMARY_POWER[requirement] or false
                    if noMana then
                        self.tracer:Log("Spell ID '%s' does not have enough %s.", spellId, requirement)
                    else
                        self.tracer:Log("Spell ID '%s' failed '%s' requirements.", spellId, requirement)
                    end
                end
            end
        else
            local index, bookType = self.OvaleSpellBook:GetSpellBookIndex(spellId)
            if index and bookType then
                return IsUsableSpell(index, bookType)
            elseif self.OvaleSpellBook:IsKnownSpell(spellId) then
                local name = self.OvaleSpellBook:GetSpellName(spellId)
                if  not name then
                    return false, false
                end
                return IsUsableSpell(name)
            end
        end
        self.profiler:StopProfiling("OvaleSpellBook_state_IsUsableSpell")
        return isUsable, noMana
    end,
})
