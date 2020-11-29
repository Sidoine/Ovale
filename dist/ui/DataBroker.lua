local __exports = LibStub:NewLibrary("ovale/ui/DataBroker", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/ui/Localization")
local L = __Localization.L
local LibDataBroker = LibStub:GetLibrary("LibDataBroker-1.1", true)
local LibDBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)
local __engineScripts = LibStub:GetLibrary("ovale/engine/Scripts")
local DEFAULT_NAME = __engineScripts.DEFAULT_NAME
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local pairs = pairs
local kpairs = pairs
local insert = table.insert
local CreateFrame = CreateFrame
local EasyMenu = EasyMenu
local IsShiftKeyDown = IsShiftKeyDown
local UIParent = UIParent
local CLASS_ICONS = {
    ["DEATHKNIGHT"] = "Interface\\Icons\\ClassIcon_DeathKnight",
    ["DEMONHUNTER"] = "Interface\\Icons\\ClassIcon_DemonHunter",
    ["DRUID"] = "Interface\\Icons\\ClassIcon_Druid",
    ["HUNTER"] = "Interface\\Icons\\ClassIcon_Hunter",
    ["MAGE"] = "Interface\\Icons\\ClassIcon_Mage",
    ["MONK"] = "Interface\\Icons\\ClassIcon_Monk",
    ["PALADIN"] = "Interface\\Icons\\ClassIcon_Paladin",
    ["PRIEST"] = "Interface\\Icons\\ClassIcon_Priest",
    ["ROGUE"] = "Interface\\Icons\\ClassIcon_Rogue",
    ["SHAMAN"] = "Interface\\Icons\\ClassIcon_Shaman",
    ["WARLOCK"] = "Interface\\Icons\\ClassIcon_Warlock",
    ["WARRIOR"] = "Interface\\Icons\\ClassIcon_Warrior"
}
local defaultDB = {
    minimap = {
        hide = false
    }
}
__exports.OvaleDataBrokerClass = __class(nil, {
    constructor = function(self, ovalePaperDoll, ovaleFrameModule, ovaleOptions, ovale, ovaleDebug, ovaleScripts, ovaleVersion)
        self.ovalePaperDoll = ovalePaperDoll
        self.ovaleFrameModule = ovaleFrameModule
        self.ovaleOptions = ovaleOptions
        self.ovale = ovale
        self.ovaleDebug = ovaleDebug
        self.ovaleScripts = ovaleScripts
        self.ovaleVersion = ovaleVersion
        self.broker = {
            text = ""
        }
        self.OnTooltipShow = function(tooltip)
            self.tooltipTitle = self.tooltipTitle or self.ovale:GetName() .. " " .. self.ovaleVersion.version
            tooltip:SetText(self.tooltipTitle, 1, 1, 1)
            tooltip:AddLine(L["Click to select the script."])
            tooltip:AddLine(L["Middle-Click to toggle the script options panel."])
            tooltip:AddLine(L["Right-Click for options."])
            tooltip:AddLine(L["Shift-Right-Click for the current trace log."])
        end
        self.OnClick = function(fr, button)
            if button == "LeftButton" then
                local menu = {
                    [1] = {
                        text = L["Script"],
                        isTitle = true
                    }
                }
                local scriptType = ( not self.ovaleOptions.db.profile.showHiddenScripts and "script") or nil
                local descriptions = self.ovaleScripts:GetDescriptions(scriptType)
                for name, description in pairs(descriptions) do
                    local menuItem = {
                        text = description,
                        func = function()
                            self.ovaleScripts:SetScript(name)
                        end
                    }
                    insert(menu, menuItem)
                end
                self.menuFrame = self.menuFrame or CreateFrame("Frame", "OvaleDataBroker_MenuFrame", UIParent, "UIDropDownMenuTemplate")
                EasyMenu(menu, self.menuFrame, "cursor", 0, 0, "MENU")
            elseif button == "MiddleButton" then
                self.ovaleFrameModule.frame:ToggleOptions()
            elseif button == "RightButton" then
                if IsShiftKeyDown() then
                    self.ovaleDebug:DoTrace(true)
                else
                    self.ovaleOptions:ToggleConfig()
                end
            end
        end
        self.OnInitialize = function()
            if LibDataBroker then
                local broker = {
                    type = "data source",
                    text = "",
                    icon = CLASS_ICONS[self.ovale.playerClass],
                    OnClick = self.OnClick,
                    OnTooltipShow = self.OnTooltipShow
                }
                self.broker = LibDataBroker:NewDataObject(self.ovale:GetName(), broker)
                if LibDBIcon then
                    LibDBIcon:Register(self.ovale:GetName(), self.broker, self.ovaleOptions.db.profile.apparence.minimap)
                end
            end
            if self.broker then
                self.module:RegisterMessage("Ovale_ProfileChanged", self.UpdateIcon)
                self.module:RegisterMessage("Ovale_ScriptChanged", self.Ovale_ScriptChanged)
                self.module:RegisterMessage("Ovale_SpecializationChanged", self.Ovale_ScriptChanged)
                self.module:RegisterEvent("PLAYER_ENTERING_WORLD", self.Ovale_ScriptChanged)
                self.Ovale_ScriptChanged()
                self.UpdateIcon()
            end
        end
        self.OnDisable = function()
            if self.broker then
                self.module:UnregisterEvent("PLAYER_ENTERING_WORLD")
                self.module:UnregisterMessage("Ovale_SpecializationChanged")
                self.module:UnregisterMessage("Ovale_ProfileChanged")
                self.module:UnregisterMessage("Ovale_ScriptChanged")
            end
        end
        self.UpdateIcon = function()
            if LibDBIcon and self.broker then
                local minimap = self.ovaleOptions.db.profile.apparence.minimap
                LibDBIcon:Refresh(self.ovale:GetName(), minimap)
                if minimap and minimap.hide then
                    LibDBIcon:Hide(self.ovale:GetName())
                else
                    LibDBIcon:Show(self.ovale:GetName())
                end
            end
        end
        self.Ovale_ScriptChanged = function()
            local script = self.ovaleOptions.db.profile.source[self.ovale.playerClass .. "_" .. self.ovalePaperDoll:GetSpecialization()]
            self.broker.text = (script == DEFAULT_NAME and self.ovaleScripts:GetDefaultScriptName(self.ovale.playerClass, self.ovalePaperDoll:GetSpecialization())) or script or "Disabled"
        end
        self.module = ovale:createModule("OvaleDataBroker", self.OnInitialize, self.OnDisable, aceEvent)
        local options = {
            minimap = {
                order = 25,
                type = "toggle",
                name = L["Show minimap icon"],
                get = function()
                    return  not self.ovaleOptions.db.profile.apparence.minimap.hide
                end,
                set = function(info, value)
                    self.ovaleOptions.db.profile.apparence.minimap.hide =  not value
                    self.UpdateIcon()
                end
            }
        }
        for k, v in kpairs(defaultDB) do
            self.ovaleOptions.defaultDB.profile.apparence[k] = v
        end
        for k, v in pairs(options) do
            self.ovaleOptions.apparence.args[k] = v
        end
        self.ovaleOptions:RegisterOptions()
    end,
})
