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
local GetTotemInfo = GetTotemInfo
local AIR_TOTEM_SLOT = AIR_TOTEM_SLOT
local EARTH_TOTEM_SLOT = EARTH_TOTEM_SLOT
local FIRE_TOTEM_SLOT = FIRE_TOTEM_SLOT
local WATER_TOTEM_SLOT = WATER_TOTEM_SLOT
local huge = math.huge
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local __tools = LibStub:GetLibrary("ovale/tools")
local isString = __tools.isString
local INFINITY = huge
local self_serial = 0
local TOTEM_CLASS = {
    DRUID = true,
    MAGE = true,
    MONK = true,
    SHAMAN = true
}
local TOTEM_SLOT = {
    air = AIR_TOTEM_SLOT,
    earth = EARTH_TOTEM_SLOT,
    fire = FIRE_TOTEM_SLOT,
    water = WATER_TOTEM_SLOT,
    spirit_wolf = 1
}
local TOTEMIC_RECALL = 36936
local TotemData = __class(nil, {
    constructor = function(self)
        self.totem = {}
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
        self.next.totem = {}
        for slot = 1, MAX_TOTEMS, 1 do
            self.next.totem[slot] = {}
        end
    end,
    ResetState = function(self)
    end,
    CleanState = function(self)
        for slot, totem in pairs(self.next.totem) do
            for k in pairs(totem) do
                totem[k] = nil
            end
            self.next.totem[slot] = nil
        end
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_ApplySpellAfterCast")
        if Ovale.playerClass == "SHAMAN" and spellId == TOTEMIC_RECALL then
            for slot in ipairs(self.next.totem) do
                self:DestroyTotem(slot, endCast)
            end
        else
            local atTime = endCast
            local slot = self:GetTotemSlot(spellId, atTime)
            if slot then
                self:SummonTotem(spellId, slot, atTime)
            end
        end
        __exports.OvaleTotem:StopProfiling("OvaleTotem_ApplySpellAfterCast")
    end,
    IsActiveTotem = function(self, totem, atTime)
        local boolean = false
        if totem and (totem.serial == self_serial) and totem.start and totem.duration and totem.start < atTime and atTime < totem.start + totem.duration then
            boolean = true
        end
        return boolean
    end,
    GetTotem = function(self, slot)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_state_GetTotem")
        if isString(slot) then
            slot = TOTEM_SLOT[slot]
        end
        local totem = self.next.totem[slot]
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
    GetTotemInfo = function(self, slot)
        local haveTotem, name, startTime, duration, icon
        if isString(slot) then
            slot = TOTEM_SLOT[slot]
        end
        local totem = self:GetTotem(slot)
        if totem then
            haveTotem = self:IsActiveTotem(totem)
            name = totem.name
            startTime = totem.start
            duration = totem.duration
            icon = totem.icon
        end
        return haveTotem, name, startTime, duration, icon
    end,
    GetTotemCount = function(self, spellId, atTime)
        local start, ending
        local count = 0
        local si = OvaleData.spellInfo[spellId]
        if si and si.totem then
            local buffPresent = true
            if si.buff_totem then
                local aura = OvaleAura:GetAura("player", si.buff_totem, atTime)
                buffPresent = OvaleAura:IsActiveAura(aura, atTime)
            end
            if buffPresent then
                local texture = OvaleSpellBook:GetSpellTexture(spellId)
                local maxTotems = si.max_totems or 1
                for slot in ipairs(self.next.totem) do
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
    GetTotemSlot = function(self, spellId, atTime)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_state_GetTotemSlot")
        local totemSlot
        local si = OvaleData.spellInfo[spellId]
        if si and si.totem then
            totemSlot = TOTEM_SLOT[si.totem]
            if  not totemSlot then
                local availableSlot
                for slot in ipairs(self.next.totem) do
                    local totem = self:GetTotem(slot)
                    if  not self:IsActiveTotem(totem, atTime) then
                        availableSlot = slot
                        break
                    end
                end
                local texture = OvaleSpellBook:GetSpellTexture(spellId)
                local maxTotems = si.max_totems or 1
                local count = 0
                local start = INFINITY
                for slot in ipairs(self.next.totem) do
                    local totem = self:GetTotem(slot)
                    if self:IsActiveTotem(totem, atTime) and totem.icon == texture then
                        count = count + 1
                        if start > totem.start then
                            start = totem.start
                            totemSlot = slot
                        end
                    end
                end
                if count < maxTotems then
                    totemSlot = availableSlot
                end
            end
            totemSlot = totemSlot or 1
        end
        __exports.OvaleTotem:StopProfiling("OvaleTotem_state_GetTotemSlot")
        return totemSlot
    end,
    SummonTotem = function(self, spellId, slot, atTime)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_state_SummonTotem")
        if isString(slot) then
            slot = TOTEM_SLOT[slot]
        end
        local name, _, icon = OvaleSpellBook:GetSpellInfo(spellId)
        local duration = OvaleData:GetSpellInfoProperty(spellId, atTime, "duration", nil)
        local totem = self.next.totem[slot]
        totem.name = name
        totem.start = atTime
        totem.duration = duration or 15
        totem.icon = icon
        __exports.OvaleTotem:StopProfiling("OvaleTotem_state_SummonTotem")
    end,
    DestroyTotem = function(self, slot, atTime)
        __exports.OvaleTotem:StartProfiling("OvaleTotem_state_DestroyTotem")
        if isString(slot) then
            slot = TOTEM_SLOT[slot]
        end
        local totem = self.next.totem[slot]
        local duration = atTime - totem.start
        if duration < 0 then
            duration = 0
        end
        totem.duration = duration
        __exports.OvaleTotem:StopProfiling("OvaleTotem_state_DestroyTotem")
    end,
})
__exports.OvaleTotem = OvaleTotemClass()
OvaleState:RegisterState(__exports.OvaleTotem)
