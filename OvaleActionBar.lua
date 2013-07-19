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

--key: spell name / value: action icon id
local self_actionSpell = {}
local self_actionMacro = {}
local self_actionItem = {}
local self_keybind = {}

local OVALE_ACTIONBAR_DEBUG = "action_bar"
--</private-static-properties>

--<public-static-methods>
function OvaleActionBar:OnEnable()
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "FillActionIndexes")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "FillActionIndexes")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "FillActionIndexes")
	self:RegisterEvent("UPDATE_BINDINGS", "FillActionIndexes")
end
	
function OvaleActionBar:OnDisable()
	self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
	self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_TALENT_UPDATE")
	self:UnregisterEvent("UPDATE_BINDINGS")
end
	
function OvaleActionBar:ACTIONBAR_SLOT_CHANGED(event, slot, unknown)
	if (slot == 0) then
		self:FillActionIndexes(event)
	elseif (slot) then
	-- on reçoit aussi si c'est une macro avec mouseover à chaque fois que la souris passe sur une cible!
		self:FillActionIndex(tonumber(slot))
		Ovale:DebugPrintf(OVALE_ACTIONBAR_DEBUG, "Mapping button %s to spell/macro", slot)
	end
end

function OvaleActionBar:FillActionIndexes(event)
	Ovale:DebugPrintf(OVALE_ACTIONBAR_DEBUG, "Mapping buttons to spells/macros for %s", event)
	wipe(self_actionSpell)
	wipe(self_actionMacro)
	wipe(self_actionItem)
	wipe(self_keybind)
	for i=1,120 do
		self:FillActionIndex(i)
	end
end

function OvaleActionBar:FillActionIndex(i)
	self_keybind[i] = self:FindKeyBinding(i)
	local actionText = API_GetActionText(i)
	if actionText then
		self_actionMacro[actionText] = i
	else
		local type, spellId = API_GetActionInfo(i);
		if (type=="spell") then
			self_actionSpell[spellId] = i
		elseif (type =="item") then
			self_actionItem[spellId] = i
		end
	end
end

function OvaleActionBar:FindKeyBinding(id)
-- ACTIONBUTTON1..12 => principale (1..12, 13..24, 73..108)
-- MULTIACTIONBAR1BUTTON1..12 => bas gauche (61..72)
-- MULTIACTIONBAR2BUTTON1..12 => bas droite (49..60)
-- MULTIACTIONBAR3BUTTON1..12 => haut droit (25..36)
-- MULTIACTIONBAR4BUTTON1..12 => haut gauche (37..48)
	local name;
	if (id<=24 or id>72) then
		name = "ACTIONBUTTON"..(((id-1)%12)+1);
	elseif (id<=36) then
		name = "MULTIACTIONBAR3BUTTON"..(id-24);
	elseif (id<=48) then
		name = "MULTIACTIONBAR4BUTTON"..(id-36);
	elseif (id<=60) then
		name = "MULTIACTIONBAR2BUTTON"..(id-48);
	else
		name = "MULTIACTIONBAR1BUTTON"..(id-60);
	end
	local key = API_GetBindingKey(name);
--[[	if (not key) then
		DEFAULT_CHAT_FRAME:AddMessage(id.."=>"..name.." introuvable")
	else
		DEFAULT_CHAT_FRAME:AddMessage(id.."=>"..name.."="..key)
	end]]
	return key;
end

-- Get the action id that match a spell id
function OvaleActionBar:GetForSpell(spellId)
	return self_actionSpell[spellId]
end

-- Get the action id that match a macro id
function OvaleActionBar:GetForMacro(macroId)
	return self_actionMacro[macroId]
end

-- Get the action id that match an item id
function OvaleActionBar:GetForItem(itemId)
	return self_actionItem[itemId]
end

function OvaleActionBar:GetBinding(actionId)
	return self_keybind[actionId]
end
--</public-static-methods>
