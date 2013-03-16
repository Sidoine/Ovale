--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2012 Sidoine

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

-- Keep data about the player action bars (key bindings mostly)
local _, Ovale = ...
OvaleActionBar = Ovale:NewModule("OvaleActionBar", "AceEvent-3.0")

--<private-static-properties>
local tonumber = tonumber
local wipe = wipe

local GetActionInfo = GetActionInfo
local GetActionText = GetActionText

--key: spell name / value: action icon id
actionSpell = {}
actionMacro = {}
actionItem = {}
keybind = {}
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
		Ovale:DebugPrint("action_bar", "Mapping button " ..tonumber(slot).." to spell/macro")
	end
end

function OvaleActionBar:FillActionIndexes(event)
	Ovale:DebugPrint("action_bar", "Mapping buttons to spells/macros for " ..event)
	wipe(actionSpell)
	wipe(actionMacro)
	wipe(actionItem)
	wipe(keybind)
	for i=1,120 do
		self:FillActionIndex(i)
	end
end

function OvaleActionBar:FillActionIndex(i)
	keybind[i] = self:FindKeyBinding(i)
	local actionText = GetActionText(i)
	if actionText then
		actionMacro[actionText] = i
	else
		local type, spellId = GetActionInfo(i);
		if (type=="spell") then
			actionSpell[spellId] = i
		elseif (type =="item") then
			actionItem[spellId] = i
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
	local key = GetBindingKey(name);
--[[	if (not key) then
		DEFAULT_CHAT_FRAME:AddMessage(id.."=>"..name.." introuvable")
	else
		DEFAULT_CHAT_FRAME:AddMessage(id.."=>"..name.."="..key)
	end]]
	return key;
end

-- Get the action id that match a spell id
function OvaleActionBar:GetForSpell(spellId)
	return actionSpell[spellId]
end

-- Get the action id that match a macro id
function OvaleActionBar:GetForMacro(macroId)
	return actionMacro[macroId]
end

-- Get the action id that match an item id
function OvaleActionBar:GetForItem(itemId)
	return actionItem[itemId]
end

function OvaleActionBar:GetBinding(actionId)
	return keybind[actionId]
end
--</public-static-methods>
