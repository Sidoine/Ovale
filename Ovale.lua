--[[--------------------------------------------------------------------
    Copyright (C) 2009, 2010, 2011, 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]----------------------------------------------------------------------

local OVALE, addonTable = ...
Ovale = LibStub("AceAddon-3.0"):NewAddon(addonTable, OVALE, "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0", "AceTimer-3.0")

--<private-static-properties>
local AceGUI = LibStub("AceGUI-3.0")
local OvaleOptions = nil

-- Localized strings table.
local L = nil

local format = string.format
local next = next
local pairs = pairs
local select = select
local tconcat = table.concat
local tostring = tostring
local unpack = unpack
local wipe = table.wipe
local API_GetItemInfo = GetItemInfo
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
local OVALE_MSG_PREFIX = OVALE

-- Flags used by debugging print functions.
-- If "bug" flag is set, then the next frame refresh is traced.
local self_bug = false
-- If "traced" flag is set, then the public "trace" property is toggled before the next frame refresh.
local self_traced = false
-- Table of lines output using Log() or Logf() methods.
local self_traceLog = {}
-- Maximum length of the trace log.
local OVALE_TRACELOG_MAXLINES = 4096	-- 2^14
-- Table of strings to display once per session.
local self_oneTimeMessage = {}
--</private-static-properties>

--<public-static-properties>
-- Project version number.
Ovale.version = "@project-version@"
-- Localization string table.
Ovale.L = nil
--the frame with the icons
Ovale.frame = nil
-- Checkbox and dropdown definitions from evaluating the script.
Ovale.checkBox = {}
Ovale.list = {}
-- Checkbox and dropdown GUI controls.
Ovale.checkBoxWidget = {}
Ovale.listWidget = {}
-- Flag to activate tracing the function calls for the next frame refresh.
Ovale.trace = false
--in combat?
Ovale.enCombat = false
Ovale.refreshNeeded = {}
Ovale.combatStartTime = nil
--</public-static-properties>

--<private-static-methods>
local function OnCheckBoxValueChanged(widget)
	-- Reflect the value change into the profile (model).
	local profile = OvaleOptions:GetProfile()
	local name = widget:GetUserData("name")
	profile.check[name] = widget:GetValue()
	Ovale:SendMessage("Ovale_CheckBoxValueChanged", name)
end

local function OnDropDownValueChanged(widget)
	-- Reflect the value change into the profile (model).
	local profile = OvaleOptions:GetProfile()
	local name = widget:GetUserData("name")
	profile.list[name] = widget:GetValue()
	Ovale:SendMessage("Ovale_ListValueChanged", name)
end
--</private-static-methods>

--<public-static-methods>
function Ovale:OnInitialize()
	-- Resolve module dependencies.
	OvaleOptions = self:GetModule("OvaleOptions")
	-- Register message prefix for the addon.
	API_RegisterAddonMessagePrefix(OVALE_MSG_PREFIX)
	-- Localization.
	L = Ovale.L
	-- Key bindings.
	BINDING_HEADER_OVALE = OVALE
	local toggleCheckBox = L["Inverser la boîte à cocher "]
	BINDING_NAME_OVALE_CHECKBOX0 = toggleCheckBox .. "(1)"
	BINDING_NAME_OVALE_CHECKBOX1 = toggleCheckBox .. "(2)"
	BINDING_NAME_OVALE_CHECKBOX2 = toggleCheckBox .. "(3)"
	BINDING_NAME_OVALE_CHECKBOX3 = toggleCheckBox .. "(4)"
	BINDING_NAME_OVALE_CHECKBOX4 = toggleCheckBox .. "(5)"
end

function Ovale:OnEnable()
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterMessage("Ovale_OptionChanged")

	self.frame = AceGUI:Create(OVALE .. "Frame")
	self:UpdateFrame()
end

function Ovale:OnDisable()
	self:UnregisterEvent("CHAT_MSG_ADDON")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterMessage("Ovale_OptionChanged")
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
function Ovale:PLAYER_ENTERING_WORLD()
	self:ClearOneTimeMessages()
end

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

function Ovale:Ovale_OptionChanged(event, group)
	if group == "visibility" then
		self:UpdateVisibility()
	else
		self:UpdateFrame()
	end
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

function Ovale:ResetControls()
	wipe(self.checkBox)
	wipe(self.list)
end

function Ovale:UpdateControls()
	local profile = OvaleOptions:GetProfile()

	-- Create a new CheckBox widget for each checkbox declared in the script.
	wipe(self.checkBoxWidget)
	for name, checkBox in pairs(self.checkBox) do
		if checkBox.text then
			local widget = AceGUI:Create("CheckBox")
			-- XXX Workaround for GetItemInfo() possibly returning nil.
			local text = self:FinalizeString(checkBox.text)
			widget:SetLabel(text)
			if profile.check[name] == nil then
				profile.check[name] = checkBox.checked
			end
			if profile.check[name] then
				widget:SetValue(profile.check[name])
			end
			widget:SetUserData("name", name)
			widget:SetCallback("OnValueChanged", OnCheckBoxValueChanged)
			self.frame:AddChild(widget)
			self.checkBoxWidget[name] = widget
		else
			self:OneTimeMessage("Warning: checkbox '%s' is used but not defined.", name)
		end
	end

	-- Create a new Dropdown widget for each list declared in the script.
	wipe(self.listWidget)
	for name, list in pairs(self.list) do
		if next(list.items) then
			local widget = AceGUI:Create("Dropdown")
			widget:SetList(list.items)
			if not profile.list[name] then
				profile.list[name] = list.default
			end
			if profile.list[name] then
				widget:SetValue(profile.list[name])
			end
			widget:SetUserData("name", name)
			widget:SetCallback("OnValueChanged", OnDropDownValueChanged)
			self.frame:AddChild(widget)
			self.listWidget[name] = widget
		else
			self:OneTimeMessage("Warning: list '%s' is used but has no items.", name)
		end
	end
end


function Ovale:UpdateFrame()
	local profile = OvaleOptions:GetProfile()
	self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", profile.left, profile.top)
	self.frame:ReleaseChildren()
	self.frame:UpdateIcons()
	self:UpdateControls()
	self:UpdateVisibility()
end

function Ovale:ResetTrace()
	self.trace = false
	self_traced = false
	self_bug = false
end

function Ovale:UpdateTrace()
	-- If trace flag is set here, then flag that we just traced one frame.
	if self.trace then
		self_traced = true
	end
	-- If there was a bug, then enable trace on the next frame.
	if self_bug then
		self.trace = true
	end
	-- Toggle trace flag so we don't endlessly trace successive frames.
	if self.trace and self_traced then
		self_traced = false
		self.trace = false
	end
end

function Ovale:IsChecked(name)
	local widget = self.checkBoxWidget[name]
	return widget and widget:GetValue()
end

function Ovale:GetListValue(name)
	local widget = self.listWidget[name]
	return widget and widget:GetValue()
end

-- Set the k'th checkbox control to the specified on/off (true/false) value.
function Ovale:SetCheckBox(k, on)
	local profile = OvaleOptions:GetProfile()
	for name, widget in pairs(self.checkBoxWidget) do
		if k == 0 then
			widget:SetValue(on)
			profile.check[name] = on
			break
		end
		k = k - 1
	end
end

-- Toggle the k'th checkbox control.
function Ovale:ToggleCheckBox(k)
	local profile = OvaleOptions:GetProfile()
	for name, widget in pairs(self.checkBoxWidget) do
		if k == 0 then
			local on = not widget:GetValue()
			widget:SetValue(on)
			profile.check[name] = on
			break
		end
		k = k - 1
	end
end

function Ovale:FinalizeString(s)
	local item, id = strmatch(s, "^(item:)(.+)")
	if item then
		s = API_GetItemInfo(id)
	end
	return s
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
	self_bug = true
end

function Ovale:Errorf(...)
	self:Printf("Fatal error: %s", self:Format(...))
	self_bug = true
end

function Ovale:Log(...)
	if self.trace then
		local N = #self_traceLog
		if N < OVALE_TRACELOG_MAXLINES - 1 then
			local output = { ... }
			self_traceLog[N + 1] = tconcat(output, "\t")
		elseif N == OVALE_TRACELOG_MAXLINES - 1 then
			self_traceLog[N + 1] = "WARNING: Maximum length of trace log has been reached."
		end
	end
end

function Ovale:Logf(...)
	local N = #self_traceLog
	if self.trace then
		if N < OVALE_TRACELOG_MAXLINES - 1 then
			self_traceLog[N + 1] = self:Format(...)
		elseif N == OVALE_TRACELOG_MAXLINES - 1 then
			self_traceLog[N + 1] = "WARNING: Maximum length of trace log has been reached."
		end
	end
end

-- Reset/empty the contents of the trace log.
function Ovale:ClearLog()
	wipe(self_traceLog)
end

-- Return the contents of the trace log as a string.
function Ovale:TraceLog()
	return tconcat(self_traceLog, "\n")
end

function Ovale:OneTimeMessage(...)
	local s = self:Format(...)
	if not self_oneTimeMessage[s] then
		self_oneTimeMessage[s] = true
	end
end

function Ovale:ClearOneTimeMessages()
	wipe(self_oneTimeMessage)
end

function Ovale:PrintOneTimeMessages()
	for s in pairs(self_oneTimeMessage) do
		if self_oneTimeMessage[s] ~= "printed" then
			self:Print(s)
			self_oneTimeMessage[s] = "printed"
		end
	end
end
--</public-static-methods>
