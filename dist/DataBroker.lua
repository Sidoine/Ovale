local __exports = LibStub:NewLibrary("ovale/DataBroker", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local LibDataBroker = LibStub:GetLibrary("LibDataBroker-1.1", true)
local LibDBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Options = LibStub:GetLibrary("ovale/Options")
local OvaleOptions = __Options.OvaleOptions
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
local __Version = LibStub:GetLibrary("ovale/Version")
local OvaleVersion = __Version.OvaleVersion
local __Frame = LibStub:GetLibrary("ovale/Frame")
local OvaleFrameModule = __Frame.OvaleFrameModule
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local pairs = pairs
local insert = table.insert
local CreateFrame = CreateFrame
local EasyMenu = EasyMenu
local IsShiftKeyDown = IsShiftKeyDown
local UIParent = UIParent
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local OvaleDataBrokerBase = Ovale:NewModule("OvaleDataBroker", aceEvent)
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
local self_menuFrame = nil
local self_tooltipTitle = nil
do
    local defaultDB = {
        minimap = {}
    }
    local options = {
        minimap = {
            order = 25,
            type = "toggle",
            name = L["Show minimap icon"],
            get = function(info)
                return  not Ovale.db.profile.apparence.minimap.hide
            end
,
            set = function(info, value)
                Ovale.db.profile.apparence.minimap.hide =  not value
                __exports.OvaleDataBroker:UpdateIcon()
            end

        }
    }
    for k, v in pairs(defaultDB) do
        OvaleOptions.defaultDB.profile.apparence[k] = v
    end
    for k, v in pairs(options) do
        OvaleOptions.options.args.apparence.args[k] = v
    end
    OvaleOptions:RegisterOptions(__exports.OvaleDataBroker)
end
local OnClick = function(fr, button)
    if button == "LeftButton" then
        local menu = {
            [1] = {
                text = L["Script"],
                isTitle = true
            }
        }
        local scriptType =  not Ovale.db.profile.showHiddenScripts and "script"
        local descriptions = OvaleScripts:GetDescriptions(scriptType)
        for name, description in pairs(descriptions) do
            local menuItem = {
                text = description,
                func = function()
                    OvaleScripts:SetScript(name)
                end

            }
            insert(menu, menuItem)
        end
        self_menuFrame = self_menuFrame or CreateFrame("Frame", "OvaleDataBroker_MenuFrame", UIParent, "UIDropDownMenuTemplate")
        EasyMenu(menu, self_menuFrame, "cursor", 0, 0, "MENU")
    elseif button == "MiddleButton" then
        OvaleFrameModule.frame:ToggleOptions()
    elseif button == "RightButton" then
        if IsShiftKeyDown() then
            OvaleDebug:DoTrace(true)
        else
            OvaleOptions:ToggleConfig()
        end
    end
end

local OnTooltipShow = function(tooltip)
    self_tooltipTitle = self_tooltipTitle or Ovale:GetName() .. " " .. OvaleVersion.version
    tooltip:SetText(self_tooltipTitle, 1, 1, 1)
    tooltip:AddLine(L["Click to select the script."])
    tooltip:AddLine(L["Middle-Click to toggle the script options panel."])
    tooltip:AddLine(L["Right-Click for options."])
    tooltip:AddLine(L["Shift-Right-Click for the current trace log."])
end

local OvaleDataBrokerClass = __class(OvaleDataBrokerBase, {
    OnInitialize = function(self)
        if LibDataBroker then
            local broker = {
                type = "data source",
                text = "",
                icon = CLASS_ICONS[Ovale.playerClass],
                OnClick = OnClick,
                OnTooltipShow = OnTooltipShow
            }
            self.broker = LibDataBroker:NewDataObject(Ovale:GetName(), broker)
            if LibDBIcon then
                LibDBIcon:Register(Ovale:GetName(), self.broker, Ovale.db.profile.apparence.minimap)
            end
        end
        if self.broker then
            self:RegisterMessage("Ovale_ProfileChanged", "UpdateIcon")
            self:RegisterMessage("Ovale_ScriptChanged")
            self:Ovale_ScriptChanged()
            self:UpdateIcon()
        end
    end,
    OnDisable = function(self)
        if self.broker then
            self:UnregisterMessage("Ovale_ProfileChanged")
            self:UnregisterMessage("Ovale_ScriptChanged")
        end
    end,
    UpdateIcon = function(self)
        if LibDBIcon and self.broker then
            local minimap = Ovale.db.profile.apparence.minimap
            LibDBIcon:Refresh(Ovale:GetName(), minimap)
            if minimap and minimap.hide then
                LibDBIcon:Hide(Ovale:GetName())
            else
                LibDBIcon:Show(Ovale:GetName())
            end
        end
    end,
    Ovale_ScriptChanged = function(self)
        local specName = OvalePaperDoll:GetSpecialization()
        self.broker.text = Ovale.db.profile.source[specName]
    end,
    constructor = function(self, ...)
        OvaleDataBrokerBase.constructor(self, ...)
        self.broker = nil
    end
})
__exports.OvaleDataBroker = OvaleDataBrokerClass()
