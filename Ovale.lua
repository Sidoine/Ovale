--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2009, 2010, 2011, 2012, 2013 Sidoine, Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

local _, Ovale = ...
_G.Ovale = LibStub("AceAddon-3.0"):NewAddon(Ovale, "Ovale", "AceConsole-3.0", "AceEvent-3.0")

--<private-static-properties>
local L = LibStub("AceLocale-3.0"):GetLocale("Ovale")

local ipairs, pairs, strsplit, tinsert, tsort = ipairs, pairs, string.split, table.insert, table.sort
local SendAddonMessage, UnitAura, UnitCanAttack = SendAddonMessage, UnitAura, UnitCanAttack
local UnitExists, UnitHasVehicleUI, UnitIsDead = UnitExists, UnitHasVehicleUI, UnitIsDead

local damageMeterModules = {}
--</private-static-properties>

--<public-static-properties>
Ovale.L = L
--The current time, updated once per frame refresh.
Ovale.now = GetTime()
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
--score in current combat
Ovale.score = 0
--maximal theoric score in current combat
Ovale.maxScore = 0
Ovale.refreshNeeded = {}
Ovale.combatStartTime = nil
Ovale.listes = {}
--</public-static-properties>

--Key bindings
BINDING_HEADER_OVALE = "Ovale"
BINDING_NAME_OVALE_CHECKBOX0 = L["Inverser la boîte à cocher "].."(1)"
BINDING_NAME_OVALE_CHECKBOX1 = L["Inverser la boîte à cocher "].."(2)"
BINDING_NAME_OVALE_CHECKBOX2 = L["Inverser la boîte à cocher "].."(3)"
BINDING_NAME_OVALE_CHECKBOX3 = L["Inverser la boîte à cocher "].."(4)"
BINDING_NAME_OVALE_CHECKBOX4 = L["Inverser la boîte à cocher "].."(5)"

--<public-static-methods>
function Ovale:DebugPrint(flag, ...)
	local profile = OvaleOptions:GetProfile()
	if profile and profile.debug and profile.debug[flag] then
		self:Print("[" .. flag .. "]", ...)
	end
end

-- Print the auras matching the filter on the target in alphabetical order.
function Ovale:DebugListAura(target, filter)
	local i = 1
	local array = {}
	while true do
		local name, _, _, _, _, _, _, _, _, _, spellId =  UnitAura(target, i, filter)
		if not name then
			break
		end
		tinsert(array, name .. ": " .. spellId)
		i = i + 1
	end
	tsort(array)
	for _, v in ipairs(array) do
		Ovale:Print(v)
	end
end

function Ovale:OnEnable()
    -- Called when the addon is enabled
	RegisterAddonMessagePrefix("Ovale")
	self:RegisterEvent("PLAYER_REGEN_ENABLED");
	self:RegisterEvent("PLAYER_REGEN_DISABLED");
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("CHAT_MSG_ADDON")

	local profile = OvaleOptions:GetProfile()
	self.frame = LibStub("AceGUI-3.0"):Create("OvaleFrame")
	self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", profile.left, profile.top)
	self:UpdateFrame()
end

function Ovale:OnDisable()
    -- Called when the addon is disabled
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("CHAT_MSG_ADDON")
	self.frame:Hide()
end

--Called when the player target change
--Used to update the visibility e.g. if the user chose
--to hide Ovale if a friendly unit is targeted
function Ovale:PLAYER_TARGET_CHANGED()
	self.refreshNeeded.target = true
	self:UpdateVisibility()
end

function Ovale:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	if prefix ~= "Ovale" then return end
	if type ~= "RAID" and type~= "PARTY" then return end

	local value, maxValue, guid = strsplit(";", msg)
	self:SendScoreToDamageMeter(author, guid, value, maxValue)
end

function Ovale:PLAYER_REGEN_ENABLED()
	self.enCombat = false
	self:UpdateVisibility()
	-- if self.maxScore and self.maxScore > 0 then
	-- 	self:Print((self.score/self.maxScore*100).."%")
	-- end
end

function Ovale:PLAYER_REGEN_DISABLED()
	if self.maxScore>0 then
		SendAddonMessage("Ovale", self.score..";"..self.maxScore..";"..UnitGUID("player"), "RAID")
	end
	self.enCombat = true
	self.score = 0
	self.maxScore = 0
	self.combatStartTime = Ovale.now
	self:UpdateVisibility()
end

function Ovale:AddDamageMeter(name, module)
	damageMeterModules[name] = module
end

function Ovale:RemoveDamageMeter(name)
	damageMeterModules[name] = nil
end

function Ovale:SendScoreToDamageMeter(name, guid, scored, scoreMax)
	for _, module in pairs(damageMeterModules) do
		module:SendScoreToDamageMeter(name, guid, scored, scoreMax)
	end
end

function Ovale:Log(text)
	if self.trace then
		self:Print(text)
	end
end

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

function Ovale:ToggleOptions()
	self.frame:ToggleOptions()
end

function Ovale:UpdateVisibility()
	local profile = OvaleOptions:GetProfile()

	if not profile.display then
		self.frame:Hide()
		return
	end

	self.frame:Show()
	if profile.apparence.hideVehicule and UnitHasVehicleUI("player") then
		self.frame:Hide()
	end
	
	if profile.apparence.avecCible and not UnitExists("target") then
		self.frame:Hide()
	end
	
	if profile.apparence.enCombat and not Ovale.enCombat then
		self.frame:Hide()
	end	
	
	if profile.apparence.targetHostileOnly and (UnitIsDead("target") or not UnitCanAttack("player", "target")) then
		self.frame:Hide()
	end
end

function Ovale:UpdateFrame()
	self.frame:ReleaseChildren()

	self.frame:UpdateIcons()
	
	self:UpdateVisibility()
	
	self.checkBoxes = {}
	
	local profile = OvaleOptions:GetProfile()
	
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
	
	self.dropDowns = {}
	
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

function Ovale:Error(text)
	self:Print("Fatal error: " .. text)
	self.bug = true
end
--</public-static-methods>
