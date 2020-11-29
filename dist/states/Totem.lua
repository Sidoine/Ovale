local __exports = LibStub:NewLibrary("ovale/states/Totem", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ipairs = ipairs
local pairs = pairs
local kpairs = pairs
local GetTotemInfo = GetTotemInfo
local MAX_TOTEMS = MAX_TOTEMS
local __engineState = LibStub:GetLibrary("ovale/engine/State")
local States = __engineState.States
local self_serial = 0
local TOTEM_CLASS = {
    DRUID = true,
    MAGE = true,
    MONK = true,
    PALADIN = true,
    SHAMAN = true
}
local TotemData = __class(nil, {
    constructor = function(self)
        self.totems = {}
    end
})
__exports.OvaleTotemClass = __class(States, {
    constructor = function(self, ovale, ovaleState, ovaleProfiler, ovaleData, ovaleFuture, ovaleAura, ovaleSpellBook, ovaleDebug)
        self.ovale = ovale
        self.ovaleData = ovaleData
        self.ovaleFuture = ovaleFuture
        self.ovaleAura = ovaleAura
        self.ovaleSpellBook = ovaleSpellBook
        self.OnInitialize = function()
            if TOTEM_CLASS[self.ovale.playerClass] then
                self.debug:DebugTimestamp("Initialzing OvaleTotem for class %s", self.ovale.playerClass)
                self.module:RegisterEvent("PLAYER_ENTERING_WORLD", self.Update)
                self.module:RegisterEvent("PLAYER_TALENT_UPDATE", self.Update)
                self.module:RegisterEvent("PLAYER_TOTEM_UPDATE", self.Update)
                self.module:RegisterEvent("UPDATE_SHAPESHIFT_FORM", self.Update)
            else
                self.debug:DebugTimestamp("Class %s is not a TOTEM_CLASS!", self.ovale.playerClass)
            end
        end
        self.OnDisable = function()
            if TOTEM_CLASS[self.ovale.playerClass] then
                self.module:UnregisterEvent("PLAYER_ENTERING_WORLD")
                self.module:UnregisterEvent("PLAYER_TALENT_UPDATE")
                self.module:UnregisterEvent("PLAYER_TOTEM_UPDATE")
                self.module:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
            end
        end
        self.Update = function()
            self_serial = self_serial + 1
            self.ovale:needRefresh()
        end
        self.ApplySpellAfterCast = function(spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
            self.profiler:StartProfiling("OvaleTotem_ApplySpellAfterCast")
            if TOTEM_CLASS[self.ovale.playerClass] then
                self.debug:Log("OvaleTotem_ApplySpellAfterCast: spellId %s, endCast %s", spellId, endCast)
                local si = self.ovaleData.spellInfo[spellId]
                if si and si.totem then
                    self:SummonTotem(spellId, endCast)
                end
            end
            self.profiler:StopProfiling("OvaleTotem_ApplySpellAfterCast")
        end
        States.constructor(self, TotemData)
        self.debug = ovaleDebug:create("OvaleTotem")
        self.module = ovale:createModule("OvaleTotem", self.OnInitialize, self.OnDisable, aceEvent)
        self.profiler = ovaleProfiler:create(self.module:GetName())
        ovaleState:RegisterState(self)
    end,
    InitializeState = function(self)
        self.next.totems = {}
        for slot = 1, MAX_TOTEMS + 1, 1 do
            self.next.totems[slot] = {
                slot = slot,
                serial = 0,
                start = 0,
                duration = 0
            }
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
    IsActiveTotem = function(self, totem, atTime)
        if  not totem then
            return false
        end
        if  not totem.serial or totem.serial < self_serial then
            totem = self:GetTotem(totem.slot)
        end
        return (totem and totem.serial == self_serial and totem.start and totem.duration and totem.start < atTime and atTime < totem.start + totem.duration)
    end,
    GetTotem = function(self, slot)
        self.profiler:StartProfiling("OvaleTotem_state_GetTotem")
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
            totem.slot = slot
            totem.serial = self_serial
        end
        self.profiler:StopProfiling("OvaleTotem_state_GetTotem")
        return totem
    end,
    GetTotemInfo = function(self, spellId, atTime)
        local start, ending
        local count = 0
        local si = self.ovaleData.spellInfo[spellId]
        if si and si.totem then
            self.debug:Log("Spell %s is a totem spell", spellId)
            local buffPresent = self.ovaleFuture.next.lastGCDSpellId == spellId
            if  not buffPresent and si.buff_totem then
                local aura = self.ovaleAura:GetAura("player", si.buff_totem, atTime, "HELPFUL")
                buffPresent = (aura and self.ovaleAura:IsActiveAura(aura, atTime)) or false
            end
            if  not si.buff_totem or buffPresent then
                local texture = self.ovaleSpellBook:GetSpellTexture(spellId)
                local maxTotems = si.max_totems or MAX_TOTEMS + 1
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
        else
            self.debug:Log("Spell %s is NOT a totem spell", spellId)
        end
        return count, start, ending
    end,
    SummonTotem = function(self, spellId, atTime)
        self.profiler:StartProfiling("OvaleTotem_state_SummonTotem")
        local totemSlot = self:GetAvailableTotemSlot(spellId, atTime)
        if totemSlot then
            local name, _, icon = self.ovaleSpellBook:GetSpellInfo(spellId)
            local duration = self.ovaleData:GetSpellInfoProperty(spellId, atTime, "duration", nil)
            local totem = self.next.totems[totemSlot]
            totem.name = name
            totem.start = atTime
            totem.duration = duration or 15
            totem.icon = icon
            totem.slot = totemSlot
        end
        self.profiler:StopProfiling("OvaleTotem_state_SummonTotem")
    end,
    GetAvailableTotemSlot = function(self, spellId, atTime)
        self.profiler:StartProfiling("OvaleTotem_state_GetNextAvailableTotemSlot")
        local availableSlot = nil
        local si = self.ovaleData.spellInfo[spellId]
        if si and si.totem then
            local _, _, icon = self.ovaleSpellBook:GetSpellInfo(spellId)
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
        self.profiler:StopProfiling("OvaleTotem_state_GetNextAvailableTotemSlot")
        return availableSlot
    end,
})
