local __exports = LibStub:NewLibrary("ovale/Totem", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ipairs = ipairs
local pairs = pairs
local kpairs = pairs
local GetTotemInfo = GetTotemInfo
local MAX_TOTEMS = MAX_TOTEMS
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local __Future = LibStub:GetLibrary("ovale/Future")
local OvaleFuture = __Future.OvaleFuture
local self_serial = 0
local TOTEM_CLASS = {
    DRUID = true,
    MAGE = true,
    MONK = true,
    SHAMAN = true
}
local TotemData = __class(nil, {
    constructor = function(self)
        self.totems = {}
    end
})
local OvaleTotemBase = OvaleState:RegisterHasState(OvaleProfiler:RegisterProfiling(Ovale:NewModule("OvaleTotem", aceEvent)), TotemData)
local OvaleTotemClass = __class(OvaleTotemBase, {
    OnInitialize = function(self)
        if TOTEM_CLASS[Ovale.playerClass] then
            self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
            self:RegisterEvent("PLAYER_TALENT_UPDATE", "Update")
            self:RegisterEvent("PLAYER_TOTEM_UPDATE", "Update")
            self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "Update")
        end
    end,
    OnDisable = function(self)
        if TOTEM_CLASS[Ovale.playerClass] then
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self:UnregisterEvent("PLAYER_TALENT_UPDATE")
            self:UnregisterEvent("PLAYER_TOTEM_UPDATE")
            self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
        end
    end,
    Update = function(self)
        self_serial = self_serial + 1
        Ovale:needRefresh()
    end,
    InitializeState = function(self)
        self.next.totems = {}
        for slot = 1, MAX_TOTEMS + 1, 1 do
            self.next.totems[slot] = {}
        end
    end,
    ResetState = function(self)
    end,
    CleanState = function(self)
        for slot, totem in pairs(self.next.totems) do
            for k in kpairs(totem) do
                totem[k] = nil
            end
            self.next.totems[slot] = nil
        end
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_ApplySpellAfterCast")
        if TOTEM_CLASS[Ovale.playerClass] then
            local si = OvaleData.spellInfo[spellId]
            if si and si.totem then
                self:SummonTotem(spellId, endCast)
            end
        end
        __exports.OvaleTotem:StopProfiling("OvaleTotem_ApplySpellAfterCast")
    end,
    IsActiveTotem = function(self, totem, atTime)
        return (totem and (totem.serial == self_serial) and totem.start and totem.duration and totem.start < atTime and atTime < totem.start + totem.duration)
    end,
    GetTotem = function(self, slot)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_state_GetTotem")
        local totem = self.next.totems[slot]
        if totem and ( not totem.serial or totem.serial < self_serial) then
            local haveTotem, name, startTime, duration, icon = GetTotemInfo(slot)
            if haveTotem then
                totem.name = name
                totem.start = startTime
                totem.duration = duration
                totem.icon = icon
            else
                totem.name = ""
                totem.start = 0
                totem.duration = 0
                totem.icon = ""
            end
            totem.serial = self_serial
        end
        __exports.OvaleTotem:StopProfiling("OvaleTotem_state_GetTotem")
        return totem
    end,
    GetTotemInfo = function(self, spellId, atTime)
        local start, ending
        local count = 0
        local si = OvaleData.spellInfo[spellId]
        if si and si.totem then
            local buffPresent = false
            if si.buff_totem then
                local aura = OvaleAura:GetAura("player", si.buff_totem, atTime, "HELPFUL")
                buffPresent = OvaleAura:IsActiveAura(aura, atTime)
                if  not buffPresent then
                    buffPresent = (OvaleFuture.next.lastGCDSpellId == spellId)
                end
            end
            if  not si.buff_totem or buffPresent then
                local texture = OvaleSpellBook:GetSpellTexture(spellId)
                local maxTotems = si.max_totems or 1
                for slot in ipairs(self.next.totems) do
                    local totem = self:GetTotem(slot)
                    if self:IsActiveTotem(totem, atTime) and totem.icon == texture then
                        count = count + 1
                        if  not start or start > totem.start then
                            start = totem.start
                        end
                        if  not ending or ending < totem.start + totem.duration then
                            ending = totem.start + totem.duration
                        end
                    end
                    if count >= maxTotems then
                        break
                    end
                end
            end
        end
        return count, start, ending
    end,
    SummonTotem = function(self, spellId, atTime)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_state_SummonTotem")
        local totemSlot = self:GetAvailableTotemSlot(spellId, atTime)
        local name, _, icon = OvaleSpellBook:GetSpellInfo(spellId)
        local duration = OvaleData:GetSpellInfoProperty(spellId, atTime, "duration", nil)
        local totem = self.next.totems[totemSlot]
        totem.name = name
        totem.start = atTime
        totem.duration = duration or 15
        totem.icon = icon
        __exports.OvaleTotem:StopProfiling("OvaleTotem_state_SummonTotem")
    end,
    GetAvailableTotemSlot = function(self, spellId, atTime)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_state_GetNextAvailableTotemSlot")
        local availableSlot = nil
        local si = OvaleData.spellInfo[spellId]
        if si and si.totem then
            local _, _, icon = OvaleSpellBook:GetSpellInfo(spellId)
            for i = 1, MAX_TOTEMS + 1, 1 do
                local totem = self.next.totems[i]
                if availableSlot == nil and ( not self:IsActiveTotem(totem, atTime) or (si.max_totems == 1 and totem.icon == icon)) then
                    availableSlot = i
                end
            end
            if availableSlot == nil then
                availableSlot = 1
                local firstTotem = self.next.totems[1]
                local smallestEndTime = firstTotem.start + firstTotem.duration
                for i = 2, MAX_TOTEMS + 1, 1 do
                    local totem = self.next.totems[i]
                    local endTime = totem.start + totem.duration
                    if endTime < smallestEndTime then
                        availableSlot = i
                    end
                end
            end
        end
        __exports.OvaleTotem:StopProfiling("OvaleTotem_state_GetNextAvailableTotemSlot")
        return availableSlot
    end,
})
__exports.OvaleTotem = OvaleTotemClass()
OvaleState:RegisterState(__exports.OvaleTotem)
