--[[--------------------------------------------------------------------
    Copyright (C) 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleDataBroker = Ovale:NewModule("OvaleDataBroker", "AceEvent-3.0")
Ovale.OvaleDataBroker = OvaleDataBroker

--<private-static-properties>
local L = Ovale.L
local LibDataBroker = LibStub("LibDataBroker-1.1", true)
local LibDBIcon = LibStub("LibDBIcon-1.0", true)
local OvaleOptions = Ovale.OvaleOptions

-- Forward declarations for module dependencies.
local OvaleScripts = nil

local pairs = pairs
local tinsert = table.insert
local API_CreateFrame = CreateFrame
local API_EasyMenu = EasyMenu
local API_UnitClass = UnitClass
-- GLOBALS: UIParent

-- Class icon textures.
local CLASS_ICONS = {
	["DEATHKNIGHT"] = "Interface\\Icons\\ClassIcon_DeathKnight",
	["DRUID"] = "Interface\\Icons\\ClassIcon_Druid",
	["HUNTER"] = "Interface\\Icons\\ClassIcon_Hunter",
	["MAGE"] = "Interface\\Icons\\ClassIcon_Mage",
	["MONK"] = "Interface\\Icons\\ClassIcon_Monk",
	["PALADIN"] = "Interface\\Icons\\ClassIcon_Paladin",
	["PRIEST"] = "Interface\\Icons\\ClassIcon_Priest",
	["ROGUE"] = "Interface\\Icons\\ClassIcon_Rogue",
	["SHAMAN"] = "Interface\\Icons\\ClassIcon_Shaman",
	["WARLOCK"] = "Interface\\Icons\\ClassIcon_Warlock",
	["WARRIOR"] = "Interface\\Icons\\ClassIcon_Warrior",
}

-- Player's class.
local _, self_class = API_UnitClass("player")

local self_menuFrame = nil
local self_tooltipTitle = nil

do
	local defaultDB = {
		-- LibDBIcon-1.0 needs a table to store minimap settings.
		minimap = {},
	}

	local options = {
		minimap =
		{
			order = 25,
			type = "toggle",
			name = L["Show minimap icon"],
			get = function(info)
				return not Ovale.db.profile.apparence.minimap.hide
			end,
			set = function(info, value)
				Ovale.db.profile.apparence.minimap.hide = not value
				OvaleDataBroker:UpdateIcon()
			end
		},
	}

	-- Insert defaults and options into OvaleOptions.
	for k, v in pairs(defaultDB) do
		OvaleOptions.defaultDB.profile.apparence[k] = v
	end
	for k, v in pairs(options) do
		OvaleOptions.options.args.apparence.args[k] = v
	end
	OvaleOptions:RegisterOptions(OvaleDataBroker)
end
--</private-static-properties>

--<public-static-properties>
OvaleDataBroker.broker = nil
--</public-static-properties>

--<private-static-methods>
local function OnClick(frame, button)
	if button == "LeftButton" then
		local menu = {
			{ text = L["Script"], isTitle = true },
		}
		local scriptType = not Ovale.db.profile.showHiddenScripts and "script"
		local descriptions = OvaleScripts:GetDescriptions(scriptType)
		for name, description in pairs(descriptions) do
			local menuItem = {
				text = description,
				func = function() OvaleScripts:SetScript(name) end,
			}
			tinsert(menu, menuItem)
		end
		self_menuFrame = self_menuFrame or API_CreateFrame("Frame", "OvaleDataBroker_MenuFrame", UIParent, "UIDropDownMenuTemplate")
		API_EasyMenu(menu, self_menuFrame, "cursor", 0, 0, "MENU")
	elseif button == "MiddleButton" then
		Ovale:ToggleOptions()
	elseif button == "RightButton" then
		OvaleOptions:ToggleConfig()
	end
end

local function OnTooltipShow(tooltip)
	self_tooltipTitle = self_tooltipTitle or OVALE .. " " .. Ovale.version
	tooltip:SetText(self_tooltipTitle, 1, 1, 1)
	tooltip:AddLine(L["Click to select the script."])
	tooltip:AddLine(L["Middle-Click to toggle the script options panel."])
	tooltip:AddLine(L["Right-Click for options."])
end
--</private-static-methods>

--<public-static-methods>
function OvaleDataBroker:OnInitialize()
	-- Resolve module dependencies.
	OvaleOptions = Ovale.OvaleOptions
	OvaleScripts = Ovale.OvaleScripts

	-- LDB dataobject
	if LibDataBroker then
		local broker = {
			type = "data source",
			text = "",
			icon = CLASS_ICONS[self_class],
			OnClick = OnClick,
			OnTooltipShow = OnTooltipShow,
		}
		self.broker = LibDataBroker:NewDataObject(OVALE, broker)

		if LibDBIcon then
			LibDBIcon:Register(OVALE, self.broker, Ovale.db.profile.apparence.minimap)
		end
	end
end

function OvaleDataBroker:OnEnable()
	if self.broker then
		self:RegisterMessage("Ovale_ProfileChanged", "UpdateIcon")
		self:RegisterMessage("Ovale_ScriptChanged")
		self:Ovale_ScriptChanged()
		self:UpdateIcon()
	end
end

function OvaleDataBroker:OnDisable()
	if self.broker then
		self:UnregisterMessage("Ovale_ProfileChanged")
		self:UnregisterMessage("Ovale_ScriptChanged")
	end
end

function OvaleDataBroker:UpdateIcon()
	if LibDBIcon and self.broker then
		local minimap = Ovale.db.profile.apparence.minimap
		LibDBIcon:Refresh(OVALE, minimap)
		if minimap.hide then
			LibDBIcon:Hide(OVALE)
		else
			LibDBIcon:Show(OVALE)
		end
	end
end

function OvaleDataBroker:Ovale_ScriptChanged()
	-- Update the LDB dataobject.
	self.broker.text = Ovale.db.profile.source
end
--</public-static-methods>
