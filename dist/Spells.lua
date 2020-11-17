local __exports = LibStub:NewLibrary("ovale/Spells", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local GetSpellCount = GetSpellCount
local IsSpellInRange = IsSpellInRange
local IsUsableItem = IsUsableItem
local IsUsableSpell = IsUsableSpell
local UnitIsFriend = UnitIsFriend
local WARRIOR_INCERCEPT_SPELLID = 198304
local WARRIOR_HEROICTHROW_SPELLID = 57755
__exports.OvaleSpellsClass = __class(nil, {
    constructor = function(self, OvaleSpellBook, ovale, ovaleDebug, ovaleProfiler, ovaleData, power)
        self.OvaleSpellBook = OvaleSpellBook
        self.ovaleData = ovaleData
        self.power = power
        self.OnInitialize = function()
        end
        self.OnDisable = function()
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
        if si then
            self.tracer:Log("Found spell info about %s (isUsable = %s)", spellId, isUsable)
            if isUsable then
                local unusable = self.ovaleData:GetSpellInfoProperty(spellId, atTime, "unusable", targetGUID)
                if unusable ~= nil and unusable > 0 then
                    self.tracer:Log("Spell ID '%s' is flagged as unusable.", spellId)
                    isUsable = false
                end
            end
            if isUsable then
                noMana =  not self.power:hasPowerFor(si, atTime)
                if noMana then
                    isUsable = false
                    self.tracer:Log("Spell ID '%s' does not have enough power.", spellId)
                else
                    self.tracer:Log("Spell ID '%s' passed power requirements.", spellId)
                end
            end
        else
            self.tracer:Log("Look for spell info about %s in spell book", spellId)
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
