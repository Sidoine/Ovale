--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2009, 2010, 2011, 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]----------------------------------------------------------------------

local addonName, addonTable = ...
Ovale = LibStub("AceAddon-3.0"):NewAddon(addonTable, addonName, "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0", "AceTimer-3.0")

--<private-static-properties>
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local OvaleOptions = nil

local format = string.format
local next = next
local pairs = pairs
local select = select
local tostring = tostring
local wipe = table.wipe
local API_GetTime = GetTime
local API_IsInGroup = IsInGroup
local API_RegisterAddonMessagePrefix = RegisterAddonMessagePrefix
local API_SendAddonMessage = SendAddonMessage
local API_UnitCanAttack = UnitCanAttack
local API_UnitExists = UnitExists
local API_UnitHasVehicleUI = UnitHasVehicleUI
local API_UnitIsDead = UnitIsDead

local OVALE_FALSE_STRING = tostring(false)
local OVALE_NIL_STRING = tostring(nil)
local OVALE_TRUE_STRING = tostring(true)

-- Addon message prefix.
local OVALE_MSG_PREFIX = addonName
--</private-static-properties>

--<public-static-properties>
-- Project version number.
Ovale.version = "@project-version@"
-- Localization string table.
Ovale.L = L
--The table of check boxes definition
Ovale.casesACocher = {}
--the frame with the icons
Ovale.frame = nil
--check boxes GUI items
Ovale.checkBoxes = {}
--drop down GUI items
Ovale.dropDowns = {}
--set it if there was a bug, traces will be enabled on next frame
Ovale.bug = false
Ovale.traced = false
--trace next script function calls
Ovale.trace=false
--in combat?
Ovale.enCombat = false
Ovale.refreshNeeded = {}
Ovale.combatStartTime = nil
Ovale.listes = {}
--</public-static-properties>

--Key bindings
BINDING_HEADER_OVALE = addonName
BINDING_NAME_OVALE_CHECKBOX0 = L["Inverser la boîte à cocher "].."(1)"
BINDING_NAME_OVALE_CHECKBOX1 = L["Inverser la boîte à cocher "].."(2)"
BINDING_NAME_OVALE_CHECKBOX2 = L["Inverser la boîte à cocher "].."(3)"
BINDING_NAME_OVALE_CHECKBOX3 = L["Inverser la boîte à cocher "].."(4)"
BINDING_NAME_OVALE_CHECKBOX4 = L["Inverser la boîte à cocher "].."(5)"

--<private-static-methods>
local function OnCheckBoxValueChanged(widget)
	OvaleOptions:GetProfile().check[widget.userdata.k] = widget:GetValue()
	if Ovale.casesACocher[widget.userdata.k].compile then
		Ovale:SendMessage("Ovale_CheckBoxValueChanged")
	end
end

local function OnDropDownValueChanged(widget)
	OvaleOptions:GetProfile().list[widget.userdata.k] = widget.value
	if Ovale.listes[widget.userdata.k].compile then
		Ovale:SendMessage("Ovale_ListValueChanged")
	end
end
--</private-static-methods>

--<public-static-methods>
function Ovale:OnInitialize()
	-- Resolve module dependencies.
	OvaleOptions = self:GetModule("OvaleOptions")
	-- Register message prefix for the addon.
	API_RegisterAddonMessagePrefix(OVALE_MSG_PREFIX)
end

function Ovale:OnEnable()
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")

	self.frame = LibStub("AceGUI-3.0"):Create(addonName .. "Frame")
	self:UpdateFrame()
end

function Ovale:OnDisable()
	self:UnregisterEvent("CHAT_MSG_ADDON")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self.frame:Hide()
end

do
	local versionReply = {}
	local timer

	function Ovale:CHAT_MSG_ADDON(event, ...)
		local prefix, message, channel, sender = ...
		if prefix == OVALE_MSG_PREFIX then
			local ok, msgType, version = self:Deserialize(message)
			if ok then
				if msgType == "V" then
					local msg = self:Serialize("VR", self.version)
					local channel = API_IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID"
					API_SendAddonMessage(OVALE_MSG_PREFIX, msg, channel)
				elseif msgType == "VR" then
					versionReply[sender] = version
				end
			end
		end
	end

	function Ovale:VersionCheck()
		if not timer then
			wipe(versionReply)
			local message = self:Serialize("V", self.version)
			local channel = API_IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID"
			API_SendAddonMessage(OVALE_MSG_PREFIX, message, channel)
			timer = self:ScheduleTimer("PrintVersionCheck", 3)
		end
	end

	function Ovale:PrintVersionCheck()
		if next(versionReply) then
			for sender, version in pairs(versionReply) do
				self:FormatPrint(">>> %s is using Ovale %s", sender, version)
			end
		else
			self:Print(">>> No other Ovale users present.")
		end
		timer = nil
	end
end

--Called when the player target change
--Used to update the visibility e.g. if the user chose
--to hide Ovale if a friendly unit is targeted
function Ovale:PLAYER_TARGET_CHANGED()
	self.refreshNeeded.target = true
	self:UpdateVisibility()
end

function Ovale:PLAYER_REGEN_ENABLED()
	self.enCombat = false
	self:UpdateVisibility()
end

function Ovale:PLAYER_REGEN_DISABLED()
	self.enCombat = true
	self.combatStartTime = API_GetTime()
	self:UpdateVisibility()
end

function Ovale:IsPreloaded(moduleList)
	local preloaded = true
	for _, moduleName in pairs(moduleList) do
		preloaded = preloaded and self[moduleName].ready
	end
	return preloaded
end

function Ovale:ToggleOptions()
	self.frame:ToggleOptions()
end

function Ovale:UpdateVisibility()
	local visible = true
	local profile = OvaleOptions:GetProfile()

	if not self.frame.hider:IsVisible() then
		visible = false
	elseif not profile.display then
		visible = false
	else
		if profile.apparence.hideVehicule and API_UnitHasVehicleUI("player") then
			visible = false
		end
		if profile.apparence.avecCible and not API_UnitExists("target") then
			visible = false
		end
		if profile.apparence.enCombat and not Ovale.enCombat then
			visible = false
		end
		if profile.apparence.targetHostileOnly and (API_UnitIsDead("target") or not API_UnitCanAttack("player", "target")) then
			visible = false
		end
	end

	if visible then
		self.frame:Show()
	else
		self.frame:Hide()
	end
end

function Ovale:UpdateFrame()
	local profile = OvaleOptions:GetProfile()
	self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", profile.left, profile.top)

	self.frame:ReleaseChildren()

	self.frame:UpdateIcons()
	
	self:UpdateVisibility()
	
	wipe(self.checkBoxes)
	
	for k,checkBox in pairs(self.casesACocher) do
		self.checkBoxes[k] = LibStub("AceGUI-3.0"):Create("CheckBox");
		self.frame:AddChild(self.checkBoxes[k])
		self.checkBoxes[k]:SetLabel(checkBox.text)
		if profile.check[k]==nil then
			profile.check[k] = checkBox.checked
		end
		if (profile.check[k]) then
			self.checkBoxes[k]:SetValue(profile.check[k]);
		end
		self.checkBoxes[k].userdata.k = k
		self.checkBoxes[k]:SetCallback("OnValueChanged",OnCheckBoxValueChanged)
	end
	
	wipe(self.dropDowns)
	
	if (self.listes) then
		for k,list in pairs(self.listes) do
			self.dropDowns[k] = LibStub("AceGUI-3.0"):Create("Dropdown");
			self.dropDowns[k]:SetList(list.items)
			if not profile.list[k] then
				profile.list[k] = list.default
			end
			if (profile.list[k]) then
				self.dropDowns[k]:SetValue(profile.list[k]);
			end
			self.dropDowns[k].userdata.k = k
			self.dropDowns[k]:SetCallback("OnValueChanged",OnDropDownValueChanged)
			self.frame:AddChild(self.dropDowns[k])
		end
	end
end

function Ovale:IsChecked(v)
	return self.checkBoxes[v] and self.checkBoxes[v]:GetValue()
end

function Ovale:GetListValue(v)
	return self.dropDowns[v] and self.dropDowns[v].value
end

function Ovale:SetCheckBox(v,on)
	for k,checkBox in pairs(self.casesACocher) do
		if v==0 then
			self.checkBoxes[k]:SetValue(on)
			OvaleOptions:GetProfile().check[k] = on
			break
		end
		v = v - 1
	end
end

function Ovale:ToggleCheckBox(v)
	for k,checkBox in pairs(self.casesACocher) do
		if v==0 then
			self.checkBoxes[k]:SetValue(not self.checkBoxes[k]:GetValue())
			OvaleOptions:GetProfile().check[k] = self.checkBoxes[k]:GetValue()
			break
		end
		v = v - 1
	end
end

-- Debugging methods.
-- format() wrapper that turns nil arguments into tostring(nil)
function Ovale:Format(...)
	local arg = {}
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if type(v) == "boolean" then
			arg[i] = v and OVALE_TRUE_STRING or OVALE_FALSE_STRING
		else
			arg[i] = v or OVALE_NIL_STRING
		end
	end
	return format(unpack(arg))
end

function Ovale:FormatPrint(...)
	self:Print(self:Format(...))
end

function Ovale:DebugPrint(flag, ...)
	local profile = OvaleOptions:GetProfile()
	if profile and profile.debug and profile.debug[flag] then
		self:Print("[" .. flag .. "]", ...)
	end
end

function Ovale:DebugPrintf(flag, ...)
	local profile = OvaleOptions:GetProfile()
	if profile and profile.debug and profile.debug[flag] then
		local addTimestamp = select(1, ...)
		if type(addTimestamp) == "boolean" or type(addTimestamp) == "nil" then
			if addTimestamp then
				local now = API_GetTime()
				self:Printf("[%s] @%f %s", flag, now, self:Format(select(2, ...)))
			else
				self:Printf("[%s] %s", flag, self:Format(select(2, ...)))
			end
		else
			self:Printf("[%s] %s", flag, self:Format(...))
		end
	end
end

function Ovale:Error(...)
	self:Print("Fatal error: ", ...)
	self.bug = true
end

function Ovale:Errorf(...)
	self:Printf("Fatal error: %s", self:Format(...))
	self.bug = true
end

function Ovale:Log(...)
	if self.trace then
		self:Print(...)
	end
end

function Ovale:Logf(...)
	if self.trace then
		return self:FormatPrint(...)
	end
end
--</public-static-methods>
