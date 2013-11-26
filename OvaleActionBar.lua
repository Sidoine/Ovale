--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine
    Copyright (C) 2012, 2013 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

-- Keep data about the player action bars (key bindings mostly)
local _, Ovale = ...
local OvaleActionBar = Ovale:NewModule("OvaleActionBar", "AceEvent-3.0")
Ovale.OvaleActionBar = OvaleActionBar

--<private-static-properties>
local tonumber = tonumber
local wipe = table.wipe
local API_GetActionInfo = GetActionInfo
local API_GetActionText = GetActionText
local API_GetBindingKey = GetBindingKey

-- Maps each action slot (1..120) to the current action: self_action[slot] = action
local self_action = {}
-- Maps each action slot (1..120) to its current keybind: self_keybind[slot] = keybind
local self_keybind = {}

-- Maps each spell/macro/item ID to its current action slot.
-- self_spell[spellId] = slot
local self_spell = {}
-- self_macro[macroName] = slot
local self_macro = {}
-- self_item[itemId] = slot
local self_item = {}

local OVALE_ACTIONBAR_DEBUG = "action_bar"
--</private-static-properties>

--<private-static-methods>
local function GetKeyBinding(slot)
	--[[
		ACTIONBUTTON1..12			=> primary (1..12, 13..24, 73..108)
		MULTIACTIONBAR1BUTTON1..12	=> bottom left (61..72)
		MULTIACTIONBAR2BUTTON1..12	=> bottom right (49..60)
		MULTIACTIONBAR3BUTTON1..12	=> top right (25..36)
		MULTIACTIONBAR4BUTTON1..12	=> top left (37..48)
	--]]
	local name
	if slot <= 24 or slot > 72 then
		name = "ACTIONBUTTON" .. (((slot - 1)%12) + 1)
	elseif slot <= 36 then
		name = "MULTIACTIONBAR3BUTTON" .. (slot - 24)
	elseif slot <= 48 then
		name = "MULTIACTIONBAR4BUTTON" .. (slot - 36)
	elseif slot <= 60 then
		name = "MULTIACTIONBAR2BUTTON" .. (slot - 48)
	else
		name = "MULTIACTIONBAR1BUTTON" .. (slot - 60)
	end
	local key = name and API_GetBindingKey(name)
	return key
end

local function UpdateActionSlot(slot)
	-- Clear old slot and associated actions.
	local action = self_action[slot]
	if self_spell[action] == slot then
		self_spell[action] = nil
	elseif self_item[action] == slot then
		self_item[action] = nil
	elseif self_macro[action] == slot then
		self_macro[action] = nil
	end
	self_action[slot] = nil

	-- Map the current action in the slot.
	local actionType, id, subType = API_GetActionInfo(slot)
	if actionType == "spell" then
		id = tonumber(id)
		if id then
			if self_spell[id] and slot < self_spell[id] then
				self_spell[id] = slot
			end
			self_action[slot] = id
		end
	elseif actionType == "item" then
		id = tonumber(id)
		if id then
			if self_item[id] and slot < self_item[id] then
				self_item[id] = slot
			end
			self_action[slot] = id
		end
	elseif actionType == "macro" then
		local actionText = API_GetActionText(slot)
		if actionText then
			if self_macro[actionText] and slot < self_macro[actionText] then
				self_macro[actionText] = slot
			end
			self_action[slot] = actionText
		end
	end
	Ovale:DebugPrintf(OVALE_ACTIONBAR_DEBUG, "Mapping button %s to %s", slot, self_action[slot])

	-- Update the keybind for the slot.
	self_keybind[slot] = GetKeyBinding(slot)
end
--</private-static-methods>

--<public-static-methods>
function OvaleActionBar:OnEnable()
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "UpdateActionSlots")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateActionSlots")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateActionSlots")
	self:RegisterEvent("UPDATE_BINDINGS")
end
	
function OvaleActionBar:OnDisable()
	self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
	self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_TALENT_UPDATE")
	self:UnregisterEvent("UPDATE_BINDINGS")
end

function OvaleActionBar:ACTIONBAR_SLOT_CHANGED(event, slot)
	slot = tonumber(slot)
	if slot == 0 then
		self:UpdateActionSlots(event)
	elseif slot then
		UpdateActionSlot(slot)
	end
end

function OvaleActionBar:UPDATE_BINDINGS(event)
	Ovale:DebugPrintf(OVALE_ACTIONBAR_DEBUG, "%s: Updating key bindings.", event)
	for slot = 1, 120 do
		self_keybind[slot] = GetKeyBinding(slot)
	end
end

function OvaleActionBar:UpdateActionSlots(event)
	Ovale:DebugPrintf(OVALE_ACTIONBAR_DEBUG, "%s: Updating all action slot mappings.", event)
	wipe(self_action)
	wipe(self_item)
	wipe(self_macro)
	wipe(self_spell)
	for slot = 1, 120 do
		UpdateActionSlot(slot)
	end
end

-- Get the action slot that matches a spell ID.
function OvaleActionBar:GetForSpell(spellId)
	return self_spell[spellId]
end

-- Get the action slot that matches a macro name.
function OvaleActionBar:GetForMacro(macroName)
	return self_macro[macroName]
end

-- Get the action slot that matches an item ID.
function OvaleActionBar:GetForItem(itemId)
	return self_item[itemId]
end

-- Get the keybinding for an action slot.
function OvaleActionBar:GetBinding(slot)
	return self_keybind[slot]
end
--</public-static-methods>
