local __exports = LibStub:NewLibrary("ovale/ActionBar", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local aceTimer = LibStub:GetLibrary("AceTimer-3.0", true)
local gsub = string.gsub
local len = string.len
local match = string.match
local upper = string.upper
local concat = table.concat
local sort = table.sort
local insert = table.insert
local tonumber = tonumber
local wipe = wipe
local pairs = pairs
local tostring = tostring
local ipairs = ipairs
local _G = _G
local GetActionInfo = GetActionInfo
local GetActionText = GetActionText
local GetBindingKey = GetBindingKey
local GetBonusBarIndex = GetBonusBarIndex
local GetMacroItem = GetMacroItem
local GetMacroSpell = GetMacroSpell
local ElvUI = LibStub:GetLibrary("LibActionButton-1.0-ElvUI", true)
local OvaleActionBarBase = OvaleProfiler:RegisterProfiling(OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleActionBar", aceEvent, aceTimer)))
local OvaleActionBarClass = __class(OvaleActionBarBase, {
    constructor = function(self)
        self.debugOptions = {
            actionbar = {
                name = L["Action bar"],
                type = "group",
                args = {
                    spellbook = {
                        name = L["Action bar"],
                        type = "input",
                        multiline = 25,
                        width = "full",
                        get = function(info)
                            return self:DebugActions()
                        end
                    }
                }
            }
        }
        self.action = {}
        self.keybind = {}
        self.spell = {}
        self.macro = {}
        self.item = {}
        self.output = {}
        OvaleActionBarBase.constructor(self)
        for k, v in pairs(self.debugOptions) do
            OvaleDebug.options.args[k] = v
        end
    end,
    OnInitialize = function(self)
        self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
        self:RegisterEvent("PLAYER_ENTERING_WORLD", function(event)
            return self:UpdateActionSlots(event)
        end)
        self:RegisterEvent("UPDATE_BINDINGS")
        self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", function(event)
            return self:UpdateActionSlots(event)
        end)
        self:RegisterEvent("SPELLS_CHANGED", function(event)
            return self:UpdateActionSlots(event)
        end)
        self:RegisterMessage("Ovale_StanceChanged", function(event)
            return self:UpdateActionSlots(event)
        end)
        self:RegisterMessage("Ovale_TalentsChanged", function(event)
            return self:UpdateActionSlots(event)
        end)
    end,
    GetKeyBinding = function(self, slot)
        local name
        if _G["Bartender4"] and slot > 12 then
            name = "CLICK BT4Button " .. slot .. ":LeftButton"
        else
            if slot <= 24 or slot > 72 then
                name = "ACTIONBUTTON" .. ((slot - 1) % 12) + 1
            elseif slot <= 36 then
                name = "MULTIACTIONBAR3BUTTON" .. slot - 24
            elseif slot <= 48 then
                name = "MULTIACTIONBAR4BUTTON" .. slot - 36
            elseif slot <= 60 then
                name = "MULTIACTIONBAR2BUTTON" .. slot - 48
            else
                name = "MULTIACTIONBAR1BUTTON" .. slot - 60
            end
        end
        local key = name and GetBindingKey(name)
        if key and len(key) > 4 then
            key = upper(key)
            key = gsub(key, "%s+", "")
            key = gsub(key, "ALT%-", "A")
            key = gsub(key, "CTRL%-", "C")
            key = gsub(key, "SHIFT%-", "S")
            key = gsub(key, "NUMPAD", "N")
            key = gsub(key, "PLUS", "+")
            key = gsub(key, "MINUS", "-")
            key = gsub(key, "MULTIPLY", "*")
            key = gsub(key, "DIVIDE", "/")
            key = gsub(key, "BUTTON", "B")
        end
        return key
    end,
    ParseHyperlink = function(self, hyperlink)
        local color, linkType, linkData, text = match(hyperlink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
        return color, linkType, linkData, text
    end,
    OnDisable = function(self)
        self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("UPDATE_BINDINGS")
        self:UnregisterEvent("UPDATE_BONUS_ACTIONBAR")
        self:UnregisterEvent("SPELLS_CHANGED")
        self:UnregisterMessage("Ovale_StanceChanged")
        self:UnregisterMessage("Ovale_TalentsChanged")
    end,
    ACTIONBAR_SLOT_CHANGED = function(self, event, slot)
        slot = tonumber(slot)
        if slot == 0 then
            self:UpdateActionSlots(event)
        elseif ElvUI then
            local elvUIButtons = ElvUI.buttonRegistry
            for btn in pairs(elvUIButtons) do
                local s = btn:GetAttribute("action")
                if s == slot then
                    self:UpdateActionSlot(slot)
                end
            end
        elseif slot then
            local bonus = tonumber(GetBonusBarIndex()) * 12
            local bonusStart = (bonus > 0) and (bonus - 11) or 1
            local isBonus = slot >= bonusStart and slot < bonusStart + 12
            if isBonus or slot > 12 and slot < 73 then
                self:UpdateActionSlot(slot)
            end
        end
    end,
    UPDATE_BINDINGS = function(self, event)
        self:Debug("%s: Updating key bindings.", event)
        self:UpdateKeyBindings()
    end,
    TimerUpdateActionSlots = function(self)
        self:UpdateActionSlots("TimerUpdateActionSlots")
    end,
    UpdateActionSlots = function(self, event)
        self:StartProfiling("OvaleActionBar_UpdateActionSlots")
        self:Debug("%s: Updating all action slot mappings.", event)
        wipe(self.action)
        wipe(self.item)
        wipe(self.macro)
        wipe(self.spell)
        if ElvUI then
            local elvUIButtons = ElvUI.buttonRegistry
            for btn in pairs(elvUIButtons) do
                local s = btn:GetAttribute("action")
                self:UpdateActionSlot(s)
            end
        else
            local start = 1
            local bonus = tonumber(GetBonusBarIndex()) * 12
            if bonus > 0 and not _G["Bartender4"] then
                start = 13
                for slot = bonus - 11, bonus, 1 do
                    self:UpdateActionSlot(slot)
                end
            end
            for slot = start, 72, 1 do
                self:UpdateActionSlot(slot)
            end
            if event ~= "TimerUpdateActionSlots" then
                self:ScheduleTimer("TimerUpdateActionSlots", 1)
            end
        end
        self:StopProfiling("OvaleActionBar_UpdateActionSlots")
    end,
    UpdateActionSlot = function(self, slot)
        self:StartProfiling("OvaleActionBar_UpdateActionSlot")
        local action = self.action[slot]
        if self.spell[action] == slot then
            self.spell[action] = nil
        elseif self.item[action] == slot then
            self.item[action] = nil
        elseif self.macro[action] == slot then
            self.macro[action] = nil
        end
        self.action[slot] = nil
        local actionType, actionId = GetActionInfo(slot)
        if actionType == "spell" then
            local id = tonumber(actionId)
            if id then
                if  not self.spell[id] or slot < self.spell[id] then
                    self.spell[id] = slot
                end
                self.action[slot] = id
            end
        elseif actionType == "item" then
            local id = tonumber(actionId)
            if id then
                if  not self.item[id] or slot < self.item[id] then
                    self.item[id] = slot
                end
                self.action[slot] = id
            end
        elseif actionType == "macro" then
            local id = tonumber(actionId)
            if id then
                local actionText = GetActionText(slot)
                if actionText then
                    if  not self.macro[actionText] or slot < self.macro[actionText] then
                        self.macro[actionText] = slot
                    end
                    local _, _, spellId = GetMacroSpell(id)
                    if spellId then
                        if  not self.spell[spellId] or slot < self.spell[spellId] then
                            self.spell[spellId] = slot
                        end
                        self.action[slot] = spellId
                    else
                        local _, hyperlink = GetMacroItem(id)
                        if hyperlink then
                            local _, _, linkData = self:ParseHyperlink(hyperlink)
                            local itemIdText = gsub(linkData, ":.*", "")
                            local itemId = tonumber(itemIdText)
                            if itemId then
                                if  not self.item[itemId] or slot < self.item[itemId] then
                                    self.item[itemId] = slot
                                end
                                self.action[slot] = itemId
                            end
                        end
                    end
                    if  not self.action[slot] then
                        self.action[slot] = actionText
                    end
                end
            end
        end
        if self.action[slot] then
            self:Debug("Mapping button %s to %s.", slot, self.action[slot])
        else
            self:Debug("Clearing mapping for button %s.", slot)
        end
        self.keybind[slot] = self:GetKeyBinding(slot)
        self:StopProfiling("OvaleActionBar_UpdateActionSlot")
    end,
    UpdateKeyBindings = function(self)
        self:StartProfiling("OvaleActionBar_UpdateKeyBindings")
        for slot = 1, 120, 1 do
            self.keybind[slot] = self:GetKeyBinding(slot)
        end
        self:StopProfiling("OvaleActionBar_UpdateKeyBindings")
    end,
    GetForSpell = function(self, spellId)
        return self.spell[spellId]
    end,
    GetForMacro = function(self, macroName)
        return self.macro[macroName]
    end,
    GetForItem = function(self, itemId)
        return self.item[itemId]
    end,
    GetBinding = function(self, slot)
        return self.keybind[slot]
    end,
    OutputTableValues = function(self, output, tbl)
    end,
    DebugActions = function(self)
        wipe(self.output)
        local array = {}
        for k, v in pairs(self.spell) do
            insert(array, tostring(self:GetKeyBinding(v)) .. ": " .. tostring(k) .. " " .. tostring(OvaleSpellBook:GetSpellName(k)))
        end
        sort(array)
        for _, v in ipairs(array) do
            self.output[#self.output + 1] = v
        end
        local total = 0
        for _ in pairs(self.spell) do
            total = total + 1
        end
        self.output[#self.output + 1] = "Total spells: " .. total
        return concat(self.output, "\n")
    end,
})
__exports.OvaleActionBar = OvaleActionBarClass()
