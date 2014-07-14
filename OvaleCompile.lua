--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2009, 2010, 2011, 2012 Sidoine
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleCompile = Ovale:NewModule("OvaleCompile", "AceEvent-3.0")
Ovale.OvaleCompile = OvaleCompile

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleAST = nil
local OvaleCondition = nil
local OvaleCooldown = nil
local OvaleData = nil
local OvaleEquipement = nil
local OvaleOptions = nil
local OvalePaperDoll = nil
local OvaleScore = nil
local OvaleScripts = nil
local OvaleSpellBook = nil
local OvaleStance = nil

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local strfind = string.find
local strmatch = string.match
local strsub = string.sub
local wipe = table.wipe

-- Profiling set-up.
local Profiler = Ovale.Profiler
local profiler = nil
do
	local group = OvaleCompile:GetName()
	Profiler:RegisterProfilingGroup(group)
	profiler = Profiler:GetProfilingGroup(group)
end

-- Whether to trigger a script compilation if items or stances change.
local self_compileOnItems = false
local self_compileOnStances = false

-- This module needs the information in other modules to be preloaded and ready for use.
local self_canEvaluate = false
local self_requirePreload = { "OvaleEquipement", "OvaleSpellBook", "OvaleStance" }

-- Current age of the script evaluation state.
-- This advances every time an event occurs that requires re-evaluating the script.
local self_serial = 0
-- Number of times the script has been evaluated.
local self_timesEvaluated = 0
-- Icon nodes of the current script (one node for each icon)
local self_icon = {}

-- Lua pattern to match a floating-point number that may start with a minus sign.
local NUMBER_PATTERN = "^%-?%d+%.?%d*$"

local OVALE_COMPILE_DEBUG = "compile"
--</private-static-properties>

--<public-static-properties>
-- Current age of the script; this advances every time the script is evaluated.
OvaleCompile.serial = nil
-- AST for the current script.
OvaleCompile.ast = nil
--</public-static-properties>

--<private-static-methods>
local function HasTalent(talentId)
	if OvaleSpellBook:IsKnownTalent(talentId) then
		return OvaleSpellBook:GetTalentPoints(talentId) > 0
	else
		Ovale:FormatPrint("Warning: unknown talent ID '%s'", talentId)
		return false
	end
end

local function RequireValue(value)
	local required = (strsub(tostring(value), 1, 1) ~= "!")
	if not required then
		value = strsub(value, 2)
		if strmatch(value, NUMBER_PATTERN) then
			value = tonumber(value)
		end
	end
	return value, required
end

local function TestConditions(parameters)
	profiler.Start("OvaleCompile_TestConditions")
	local boolean = true
	if boolean and parameters.glyph then
		local glyph, required = RequireValue(parameters.glyph)
		local hasGlyph = OvaleSpellBook:IsActiveGlyph(glyph)
		boolean = (required and hasGlyph) or (not required and not hasGlyph)
	end
	if boolean and parameters.specialization then
		local spec, required = RequireValue(parameters.specialization)
		local isSpec = OvalePaperDoll:IsSpecialization(spec)
		boolean = (required and isSpec) or (not required and not isSpec)
	end
	if boolean and parameters.if_stance then
		self_compileOnStances = true
		local stance, required = RequireValue(parameters.if_stance)
		local isStance = OvaleStance:IsStance(stance)
		boolean = (required and isStance) or (not required and not isStance)
	end
	if boolean and parameters.if_spell then
		local spell, required = RequireValue(parameters.if_spell)
		local hasSpell = OvaleSpellBook:IsKnownSpell(spell)
		boolean = (required and hasSpell) or (not required and not hasSpell)
	end
	if boolean and parameters.talent then
		local talent, required = RequireValue(parameters.talent)
		local hasTalent = HasTalent(talent)
		boolean = (required and hasTalent) or (not required and not hasTalent)
	end
	if boolean and parameters.itemset and parameters.itemcount then
		local equippedCount = OvaleEquipement:GetArmorSetCount(parameters.itemset)
		self_compileOnItems = true
		boolean = (equippedCount >= parameters.itemcount)
	end
	do
		local profile
		if boolean and parameters.checkbox then
			for _, checkbox in ipairs(parameters.checkbox) do
				local name, required = RequireValue(checkbox)
				local control = Ovale.casesACocher[name] or {}
				control.compile = true
				Ovale.casesACocher[name] = control
				-- Check the value of the checkbox.
				profile = profile or OvaleOptions:GetProfile()
				local isChecked = profile.check[name]
				boolean = (required and isChecked) or (not required and not isChecked)
				if not boolean then
					break
				end
			end
		end
		if boolean and parameters.listitem then
			for list, listitem in pairs(parameters.listitem) do
				local item, required = RequireValue(listitem)
				local control = Ovale.listes[list] or { items = {}, default = nil }
				control.compile = true
				Ovale.listes[list] = control
				-- Check the selected item in the list.
				profile = profile or OvaleOptions:GetProfile()
				local isSelected = (profile.list[list] == item)
				boolean = (required and isSelected) or (not required and not isSelected)
				if not boolean then
					break
				end
			end
		end
	end
	profiler.Stop("OvaleCompile_TestConditions")
	return boolean
end

local function EvaluateAddCheckBox(node)
	local ok = true
	local name, parameters = node.name, node.params
	if TestConditions(parameters) then
		--[[
			If this control was not previously existing, then age the script evaluation state
			so that anything that checks the value of this control are re-evaluated after the
			current evaluation cycle.
		--]]
		local checkBox = Ovale.casesACocher[name]
		if not checkBox then
			self_serial = self_serial + 1
		end
		checkBox = checkBox or {}
		checkBox.text = node.description.value
		for _, v in ipairs(parameters) do
			if v == "default" then
				checkBox.checked = true
				break
			end
		end
		Ovale.casesACocher[name] = checkBox
	end
	return ok
end

local function EvaluateAddIcon(node)
	local ok = true
	if TestConditions(node.params) then
		self_icon[#self_icon + 1] = node
	end
	return ok
end

local function EvaluateAddListItem(node)
	local ok = true
	local name, item, parameters = node.name, node.item, node.params
	if TestConditions(parameters) then
		--[[
			If this control was not previously existing, then age the  script evaluation state
			so that anything that checks the value of this control are re-evaluated after the
			current evaluation cycle.
		--]]
		local list = Ovale.listes[name]
		if not (list and list.items and list.items[item]) then
			self_serial = self_serial + 1
		end
		list = list or { items = {}, default = nil }
		list.items[item] = node.description.value
		for _, v in ipairs(parameters) do
			if v == "default" then
				list.default = item
				break
			end
		end
		Ovale.listes[name] = list
	end
	return ok
end

local function EvaluateItemInfo(node)
	local ok = true
	local itemId, parameters = node.itemId, node.params
	if itemId and TestConditions(parameters) then
		for k, v in pairs(parameters) do
			if k == "proc" then
				-- Add the buff for this item proc to the spell list "item_proc_<proc>".
				local buff = tonumber(parameters.buff)
				if buff then
					local name = "item_proc_" .. v
					local list = OvaleData.buffSpellList[name] or {}
					list[buff] = true
					OvaleData.buffSpellList[name] = list
				else
					ok = false
					break
				end
			end
		end
	end
	return ok
end

local function EvaluateList(node)
	local ok = true
	local name, parameters = node.name, node.params
	local listDB
	if node.keyword == "ItemList" then
		listDB = "itemList"
	else -- if node.keyword == "SpellList" then
		listDB = "buffSpellList"
	end
	local list = OvaleData[listDB][name] or {}
	for i, id in ipairs(parameters) do
		id = tonumber(id)
		if id then
			list[id] = true
		else
			ok = false
			break
		end
	end
	OvaleData[listDB][name] = list
	return ok
end

local function EvaluateScoreSpells(node)
	local ok = true
	for _, spellId in ipairs(node.params) do
		spellId = tonumber(spellId)
		if spellId then
			OvaleScore:AddSpell(tonumber(spellId))
		else
			ok = false
			break
		end
	end
	return ok
end

local function EvaluateSpellAuraList(node)
	local ok = true
	local spellId, parameters = node.spellId, node.params
	if TestConditions(parameters) then
		local keyword = node.keyword
		local si = OvaleData:SpellInfo(spellId)
		local auraTable
		if strfind(keyword, "^SpellAddTarget") then
			auraTable = si.aura.target
		elseif strfind(keyword, "^SpellDamage") then
			auraTable = si.aura.damage
		else
			auraTable = si.aura.player
		end
		local filter = strfind(node.keyword, "Debuff") and "HARMFUL" or "HELPFUL"
		local tbl = auraTable[filter] or {}
		local count = 0
		for k, v in pairs(parameters) do
			if not OvaleAST.PARAMETER_KEYWORD[k] then
				tbl[k] = v
				count = count + 1
			end
		end
		if count > 0 then
			auraTable[filter] = tbl
		end
	end
	return ok
end

local function EvaluateSpellInfo(node)
	local ok = true
	local spellId, parameters = node.spellId, node.params
	if spellId and TestConditions(parameters) then
		local si = OvaleData:SpellInfo(spellId)
		for k, v in pairs(parameters) do
			if k == "addduration" then
				local value = tonumber(v)
				if value then
					si.duration = si.duration + value
				else
					ok = false
					break
				end
			elseif k == "addcd" then
				local value = tonumber(v)
				if value then
					si.cd = si.cd + value
				else
					ok = false
					break
				end
			elseif k == "addlist" then
				-- Add this buff to the named spell list.
				local list = OvaleData.buffSpellList[v] or {}
				list[spellId] = true
				OvaleData.buffSpellList[v] = list
			elseif k == "sharedcd" then
				OvaleCooldown:AddSharedCooldown(v, spellId)
			elseif not OvaleAST.PARAMETER_KEYWORD[k] then
				si[k] = v
			end
		end
	end
	return ok
end
--</private-static-methods>

--<public-static-methods>
function OvaleCompile:OnInitialize()
	-- Resolve module dependencies.
	OvaleAST = Ovale.OvaleAST
	OvaleCondition = Ovale.OvaleCondition
	OvaleCooldown = Ovale.OvaleCooldown
	OvaleData = Ovale.OvaleData
	OvaleEquipement = Ovale.OvaleEquipement
	OvaleOptions = Ovale.OvaleOptions
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvaleScore = Ovale.OvaleScore
	OvaleScripts = Ovale.OvaleScripts
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleStance = Ovale.OvaleStance
end

function OvaleCompile:OnEnable()
	self:RegisterMessage("Ovale_CheckBoxValueChanged", "EventHandler")
	self:RegisterMessage("Ovale_EquipmentChanged")
	self:RegisterMessage("Ovale_GlyphsChanged", "EventHandler")
	self:RegisterMessage("Ovale_ListValueChanged", "EventHandler")
	self:RegisterMessage("Ovale_ScriptChanged", "CompileScript")
	self:RegisterMessage("Ovale_SpellsChanged", "EventHandler")
	self:RegisterMessage("Ovale_StanceChanged")
	self:RegisterMessage("Ovale_TalentsChanged", "EventHandler")
	self:SendMessage("Ovale_ScriptChanged")
end

function OvaleCompile:OnDisable()
	self:UnregisterMessage("Ovale_CheckBoxValueChanged")
	self:UnregisterMessage("Ovale_EquipmentChanged")
	self:UnregisterMessage("Ovale_GlyphsChanged")
	self:UnregisterMessage("Ovale_ListValueChanged")
	self:UnregisterMessage("Ovale_ScriptChanged")
	self:UnregisterMessage("Ovale_SpellsChanged")
	self:UnregisterMessage("Ovale_StanceChanged")
	self:UnregisterMessage("Ovale_TalentsChanged")
end

function OvaleCompile:Ovale_EquipmentChanged(event)
	if self_compileOnItems then
		self:EventHandler(event)
	end
end

function OvaleCompile:Ovale_StanceChanged(event)
	if self_compileOnStances then
		self:EventHandler(event)
	end
end

function OvaleCompile:EventHandler(event)
	-- Advance age of the script evaluation state.
	self_serial = self_serial + 1
	Ovale:DebugPrintf(OVALE_COMPILE_DEBUG, "%s: advance age to %d.", event, self_serial)
	Ovale.refreshNeeded["player"] = true
end

function OvaleCompile:CompileScript(event)
	local profile = OvaleOptions:GetProfile()
	local source = profile.source
	Ovale:DebugPrintf(OVALE_COMPILE_DEBUG, "Compiling script '%s'.", source)
	if self.ast then
		OvaleAST:Release(self.ast)
		self.ast = nil
	end
	local ast = OvaleAST:ParseScript(source)
	if ast then
		OvaleAST:Optimize(ast)
		self.ast = ast
	end
	self:EventHandler(event)
end

function OvaleCompile:EvaluateScript()
	profiler.Start("OvaleCompile_EvaluateScript")
	self_canEvaluate = self_canEvaluate or Ovale:IsPreloaded(self_requirePreload)
	if self_canEvaluate and self.ast then
		Ovale:DebugPrint(OVALE_COMPILE_DEBUG, "Evaluating script.")
		-- Reset compilation state.
		local ok = true
		self_compileOnItems = false
		self_compileOnStances = false
		wipe(self_icon)
		OvaleCooldown:ResetSharedCooldowns()
		self_timesEvaluated = self_timesEvaluated + 1

		-- Evaluate every declaration node of the script.
		for _, node in ipairs(self.ast.child) do
			local nodeType = node.type
			if nodeType == "checkbox" then
				ok = EvaluateAddCheckBox(node)
			elseif nodeType == "icon" then
				ok = EvaluateAddIcon(node)
			elseif nodeType == "list_item" then
				ok = EvaluateAddListItem(node)
			elseif nodeType == "item_info" then
				ok = EvaluateItemInfo(node)
			elseif nodeType == "list" then
				ok = EvaluateList(node)
			elseif nodeType == "score_spells" then
				ok = EvaluateScoreSpells(node)
			elseif nodeType == "spell_aura_list" then
				ok = EvaluateSpellAuraList(node)
			elseif nodeType == "spell_info" then
				ok = EvaluateSpellInfo(node)
			else
				-- Any other top-level node types are no-ops when evaluating the script.
			end
			if not ok then
				break
			end
		end
		if ok then
			Ovale:UpdateFrame()
		end
	end
	profiler.Stop("OvaleCompile_EvaluateScript")
end

function OvaleCompile:GetFunctionNode(name)
	local node
	if self.ast and self.ast.annotation and self.ast.annotation.customFunction then
		node = self.ast.annotation.customFunction[name]
	end
	return node
end

function OvaleCompile:GetIconNodes()
	-- Evaluate the script if it is outdated.
	if not self.serial or self.serial < self_serial then
		self.serial = self_serial
		self:EvaluateScript()
	end
	return self_icon
end

function OvaleCompile:Debug()
	Ovale:FormatPrint("Total number of times the script was evaluated: %d", self_timesEvaluated)
end
--</public-static-methods>
