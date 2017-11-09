local __exports = LibStub:NewLibrary("ovale/SpellBookState", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __State = LibStub:GetLibrary("ovale/State")
local baseState = __State.baseState
local OvaleState = __State.OvaleState
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
local __DataState = LibStub:GetLibrary("ovale/DataState")
local dataState = __DataState.dataState
local __Power = LibStub:GetLibrary("ovale/Power")
local OvalePower = __Power.OvalePower
local powerState = __Power.powerState
local __CooldownState = LibStub:GetLibrary("ovale/CooldownState")
local cooldownState = __CooldownState.cooldownState
local __Runes = LibStub:GetLibrary("ovale/Runes")
local runesState = __Runes.runesState
local type = type
local IsUsableItem = IsUsableItem
local SpellBookState = __class(nil, {
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    IsUsableItem = function(self, itemId, atTime)
        OvaleSpellBook:StartProfiling("OvaleSpellBook_state_IsUsableItem")
        local isUsable = IsUsableItem(itemId)
        local ii = OvaleData:ItemInfo(itemId)
        if ii then
            if isUsable then
                local unusable = dataState:GetItemInfoProperty(itemId, atTime, "unusable")
                if unusable and unusable > 0 then
                    OvaleSpellBook:Log("Item ID '%s' is flagged as unusable.", itemId)
                    isUsable = false
                end
            end
        end
        OvaleSpellBook:StopProfiling("OvaleSpellBook_state_IsUsableItem")
        return isUsable
    end,
    IsUsableSpell = function(self, spellId, atTime, targetGUID)
        OvaleSpellBook:StartProfiling("OvaleSpellBook_state_IsUsableSpell")
        if type(atTime) == "string" and  not targetGUID then
            atTime, targetGUID = nil, atTime
        end
        atTime = atTime or baseState.currentTime
        local isUsable = OvaleSpellBook:IsKnownSpell(spellId)
        local noMana = false
        local si = OvaleData.spellInfo[spellId]
        if si then
            if isUsable then
                local unusable = dataState:GetSpellInfoProperty(spellId, atTime, "unusable", targetGUID)
                if unusable and unusable > 0 then
                    OvaleSpellBook:Log("Spell ID '%s' is flagged as unusable.", spellId)
                    isUsable = false
                end
            end
            if isUsable then
                local requirement
                isUsable, requirement = dataState:CheckSpellInfo(spellId, atTime, targetGUID)
                if  not isUsable then
                    if OvalePower.PRIMARY_POWER[requirement] then
                        noMana = true
                    end
                    if noMana then
                        OvaleSpellBook:Log("Spell ID '%s' does not have enough %s.", spellId, requirement)
                    else
                        OvaleSpellBook:Log("Spell ID '%s' failed '%s' requirements.", spellId, requirement)
                    end
                end
            end
        else
            isUsable, noMana = OvaleSpellBook:IsUsableSpell(spellId)
        end
        OvaleSpellBook:StopProfiling("OvaleSpellBook_state_IsUsableSpell")
        return isUsable, noMana
    end,
    GetTimeToSpell = function(self, spellId, atTime, targetGUID, extraPower)
        if type(atTime) == "string" and  not targetGUID then
            atTime, targetGUID = nil, atTime
        end
        atTime = atTime or baseState.currentTime
        local timeToSpell = 0
        do
            local start, duration = cooldownState:GetSpellCooldown(spellId)
            local seconds = (duration > 0) and (start + duration - atTime) or 0
            if timeToSpell < seconds then
                timeToSpell = seconds
            end
        end
        do
            local seconds = powerState:TimeToPower(spellId, atTime, targetGUID, nil, extraPower)
            if timeToSpell < seconds then
                timeToSpell = seconds
            end
        end
        do
            local runes = dataState:GetSpellInfoProperty(spellId, atTime, "runes", targetGUID)
            if runes then
                local seconds = runesState:GetRunesCooldown(atTime, runes)
                if timeToSpell < seconds then
                    timeToSpell = seconds
                end
            end
        end
        return timeToSpell
    end,
    RequireSpellCountHandler = function(self, spellId, atTime, requirement, tokens, index, targetGUID)
        return OvaleSpellBook:RequireSpellCountHandler(spellId, atTime, requirement, tokens, index, targetGUID)
    end,
})
__exports.spellBookState = SpellBookState()
OvaleState:RegisterState(__exports.spellBookState)
