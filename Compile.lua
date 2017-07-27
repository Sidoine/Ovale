--[[--------------------------------------------------------------------
    Copyright (C) 2009, 2010, 2011, 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleCompile = Ovale:NewModule("OvaleCompile", "AceEvent-3.0")
Ovale.OvaleCompile = OvaleCompile

--<private-static-properties>
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleArtifact = nil
local OvaleAST = nil
local OvaleCondition = nil
local OvaleCooldown = nil
local OvaleData = nil
local OvaleEquipment = nil
local OvalePaperDoll = nil
local OvalePower = nil
local OvaleScore = nil
local OvaleScripts = nil
local OvaleSpellBook = nil
local OvaleStance = nil

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local type = type
local strfind = string.find
local strmatch = string.match
local strsub = string.sub
local wipe = wipe
local API_GetSpellInfo = GetSpellInfo

-- Register for debugging messages.
OvaleDebug:RegisterDebugging(OvaleCompile)
-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleCompile)

-- Whether to trigger a script compilation stances change.
local self_compileOnStances = false

-- This module needs the information in other modules to be preloaded and ready for use.
local self_canEvaluate = false
local self_requirePreload = { "OvaleEquipment", "OvaleSpellBook", "OvaleStance" }

-- Current age of the script evaluation state.
-- This advances every time an event occurs that requires re-evaluating the script.
local self_serial = 0
-- Number of times the script has been evaluated.
local self_timesEvaluated = 0
-- Icon nodes of the current script (one node for each icon)
local self_icon = {}

-- Lua pattern to match a floating-point number that may start with a minus sign.
local NUMBER_PATTERN = "^%-?%d+%.?%d*$"
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
		OvaleCompile:Print("Warning: unknown talent ID '%s'", talentId)
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

local function TestConditionLevel(value)
	return OvalePaperDoll.level >= value
end

local function TestConditionMaxLevel(value)
	return OvalePaperDoll.level <= value
end

local function TestConditionSpecialization(value)
	local spec, required = RequireValue(value)
	local isSpec = OvalePaperDoll:IsSpecialization(spec)
	return (required and isSpec) or (not required and not isSpec)
end

local function TestConditionStance(value)
	self_compileOnStances = true
	local stance, required = RequireValue(value)
	local isStance = OvaleStance:IsStance(stance)
	return (required and isStance) or (not required and not isStance)
end

local function TestConditionSpell(value)
	local spell, required = RequireValue(value)
	local hasSpell = OvaleSpellBook:IsKnownSpell(spell)
	return (required and hasSpell) or (not required and not hasSpell)
end

local function TestConditionTalent(value)
	local talent, required = RequireValue(value)
	local hasTalent = HasTalent(talent)
	return (required and hasTalent) or (not required and not hasTalent)
end

local function TestConditionEquipped(value)
	local item, required = RequireValue(value)
	local hasItemEquipped = OvaleEquipment:HasEquippedItem(item)
	return (required and hasItemEquipped) or (not required and not hasItemEquipped)
end

local function TestConditionTrait(value)
	local trait, required = RequireValue(value)
	local hasTrait = OvaleArtifact:HasTrait(trait)
	return (required and hasTrait) or (not required and not hasTrait)
end

local TEST_CONDITION_DISPATCH = {
	if_spell = TestConditionSpell,
	if_equipped = TestConditionEquipped,
	if_stance = TestConditionStance,
	level = TestConditionLevel,
	maxLevel = TestConditionMaxLevel,
	specialization = TestConditionSpecialization,
	talent = TestConditionTalent,
	trait = TestConditionTrait,
	pertrait = TestConditionTrait,
}

local function TestConditions(positionalParams, namedParams)
	OvaleCompile:StartProfiling("OvaleCompile_TestConditions")
	local boolean = true
	for param, dispatch in pairs(TEST_CONDITION_DISPATCH) do
		local value = namedParams[param]
		if type(value) == "table" then
			-- Comma-separated value.
			for _, v in ipairs(value) do
				boolean = dispatch(v)
				if not boolean then
					break
				end
			end
		elseif value then
			boolean = dispatch(value)
		end
		if not boolean then
			break
		end
	end
	if boolean and namedParams.itemset and namedParams.itemcount then
		local equippedCount = OvaleEquipment:GetArmorSetCount(namedParams.itemset)
		boolean = (equippedCount >= namedParams.itemcount)
	end
	if boolean and namedParams.checkbox then
		local profile = Ovale.db.profile
		for _, checkbox in ipairs(namedParams.checkbox) do
			local name, required = RequireValue(checkbox)
			local control = Ovale.checkBox[name] or {}
			control.triggerEvaluation = true
			Ovale.checkBox[name] = control
			-- Check the value of the checkbox.
			local isChecked = profile.check[name]
			boolean = (required and isChecked) or (not required and not isChecked)
			if not boolean then
				break
			end
		end
	end
	if boolean and namedParams.listitem then
		local profile = Ovale.db.profile
		for name, listitem in pairs(namedParams.listitem) do
			local item, required = RequireValue(listitem)
			local control = Ovale.list[name] or { items = {}, default = nil }
			control.triggerEvaluation = true
			Ovale.list[name] = control
			-- Check the selected item in the list.
			local isSelected = (profile.list[name] == item)
			boolean = (required and isSelected) or (not required and not isSelected)
			if not boolean then
				break
			end
		end
	end
	OvaleCompile:StopProfiling("OvaleCompile_TestConditions")
	return boolean
end

local function EvaluateAddCheckBox(node)
	local ok = true
	local name, positionalParams, namedParams = node.name, node.positionalParams, node.namedParams
	if TestConditions(positionalParams, namedParams) then
		--[[
			If this control was not previously existing, then age the script evaluation state
			so that anything that checks the value of this control are re-evaluated after the
			current evaluation cycle.
		--]]
		local checkBox = Ovale.checkBox[name]
		if not checkBox then
			self_serial = self_serial + 1
			OvaleCompile:Debug("New checkbox '%s': advance age to %d.", name, self_serial)
		end
		checkBox = checkBox or {}
		checkBox.text = node.description.value
		for _, v in ipairs(positionalParams) do
			if v == "default" then
				checkBox.checked = true
				break
			end
		end
		Ovale.checkBox[name] = checkBox
	end
	return ok
end

local function EvaluateAddIcon(node)
	local ok = true
	local positionalParams, namedParams = node.positionalParams, node.namedParams
	if TestConditions(positionalParams, namedParams) then
		self_icon[#self_icon + 1] = node
	end
	return ok
end

local function EvaluateAddListItem(node)
	local ok = true
	local name, item, positionalParams, namedParams = node.name, node.item, node.positionalParams, node.namedParams
	if TestConditions(positionalParams, namedParams) then
		--[[
			If this control was not previously existing, then age the script evaluation state
			so that anything that checks the value of this control are re-evaluated after the
			current evaluation cycle.
		--]]
		local list = Ovale.list[name]
		if not (list and list.items and list.items[item]) then
			self_serial = self_serial + 1
			OvaleCompile:Debug("New list '%s': advance age to %d.", name, self_serial)
		end
		list = list or { items = {}, default = nil }
		list.items[item] = node.description.value
		for _, v in ipairs(positionalParams) do
			if v == "default" then
				list.default = item
				break
			end
		end
		Ovale.list[name] = list
	end
	return ok
end

local function EvaluateItemInfo(node)
	local ok = true
	local itemId, positionalParams, namedParams = node.itemId, node.positionalParams, node.namedParams
	if itemId and TestConditions(positionalParams, namedParams) then
		local ii = OvaleData:ItemInfo(itemId)
		for k, v in pairs(namedParams) do
			if k == "proc" then
				-- Add the buff for this item proc to the spell list "item_proc_<proc>".
				local buff = tonumber(namedParams.buff)
				if buff then
					local name = "item_proc_" .. namedParams.proc
					local list = OvaleData.buffSpellList[name] or {}
					list[buff] = true
					OvaleData.buffSpellList[name] = list
				else
					ok = false
					break
				end
			elseif not OvaleAST.PARAMETER_KEYWORD[k] then
				ii[k] = v
			end
		end
		OvaleData.itemInfo[itemId] = ii
	end
	return ok
end

local function EvaluateItemRequire(node)
	local ok = true
	local itemId, positionalParams, namedParams = node.itemId, node.positionalParams, node.namedParams
	if TestConditions(positionalParams, namedParams) then
		local property = node.property
		local count = 0
		local ii = OvaleData:ItemInfo(itemId)
		local tbl = ii.require[property] or {}
		for k, v in pairs(namedParams) do
			if not OvaleAST.PARAMETER_KEYWORD[k] then
				tbl[k] = v
				count = count + 1
			end
		end
		if count > 0 then
			ii.require[property] = tbl
		end
	end
	return ok
end

local function EvaluateList(node)
	local ok = true
	local name, positionalParams, namedParams = node.name, node.positionalParams, node.namedParams
	local listDB
	if node.keyword == "ItemList" then
		listDB = "itemList"
	else -- if node.keyword == "SpellList" then
		listDB = "buffSpellList"
	end
	local list = OvaleData[listDB][name] or {}
	for _, id in pairs(positionalParams) do
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
	local positionalParams, namedParams = node.positionalParams, node.namedParams
	for _, spellId in ipairs(positionalParams) do
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
	local spellId, positionalParams, namedParams = node.spellId, node.positionalParams, node.namedParams

	if	not spellId then
		OvaleCompile:Print("No spellId for name %s", node.name)
		return false
	end

	if TestConditions(positionalParams, namedParams) then
		local keyword = node.keyword
		local si = OvaleData:SpellInfo(spellId)
		local auraTable
		if strfind(keyword, "^SpellDamage") then
			auraTable = si.aura.damage
		elseif strfind(keyword, "^SpellAddPet") then
			auraTable = si.aura.pet
		elseif strfind(keyword, "^SpellAddTarget") then
			auraTable = si.aura.target
		else
			auraTable = si.aura.player
		end
		local filter = strfind(node.keyword, "Debuff") and "HARMFUL" or "HELPFUL"
		local tbl = auraTable[filter] or {}
		local count = 0
		for k, v in pairs(namedParams) do
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
	local addpower = {}
	for powertype, _ in pairs(OvalePower.POWER_INFO) do
		local key = "add" .. powertype
		addpower[key] = powertype
	end
	
	
	local ok = true
	local spellId, positionalParams, namedParams = node.spellId, node.positionalParams, node.namedParams
	if spellId and TestConditions(positionalParams, namedParams) then
		local si = OvaleData:SpellInfo(spellId)
		for k, v in pairs(namedParams) do
			if k == "addduration" then
				-- Accumulate "addduration" into a single "addduration" SpellInfo property.
				local value = tonumber(v)
				if value then
					local realValue = value
					if namedParams.pertrait ~= nil then
						realValue = value * OvaleArtifact:TraitRank(namedParams.pertrait)
					end
					local addDuration = si.addduration or 0
					si.addduration = addDuration + realValue
				else
					ok = false
					break
				end
			elseif k == "addcd" then
				-- Accumulate "addcd" into a single "addcd" SpellInfo property.
				local value = tonumber(v)
				if value then
					local addCd = si.addcd or 0
					si.addcd = addCd + value
				else
					ok = false
					break
				end
			elseif k == "addlist" then
				-- Add this buff to the named spell list.
				local list = OvaleData.buffSpellList[v] or {}
				list[spellId] = true
				OvaleData.buffSpellList[v] = list
			elseif k == "dummy_replace" then
				local spellName = API_GetSpellInfo(v) or v
				OvaleSpellBook:AddSpell(spellId, spellName)
			elseif k == "learn" and v == 1 then
				-- Forcibly learn this spell.
				local spellName = API_GetSpellInfo(spellId)
				OvaleSpellBook:AddSpell(spellId, spellName)
			elseif k == "sharedcd" then
				si[k] = v
				OvaleCooldown:AddSharedCooldown(v, spellId)
			elseif addpower[k] ~= nil  then
				local powertype = addpower[k]
				-- Accumulate "add<power>" into a single "add<power>" SpellInfo property.
				local value = tonumber(v)
				if value then
					local realValue = value
					if namedParams.pertrait ~= nil then
						realValue = value * OvaleArtifact:TraitRank(namedParams.pertrait)
					end
					local power = si[k] or 0
					si[k] = power + realValue
				else
					ok = false
					break
				end
			elseif not OvaleAST.PARAMETER_KEYWORD[k] then
				si[k] = v
			end
		end
	end
	return ok
end

local function EvaluateSpellRequire(node)
	local ok = true
	local spellId, positionalParams, namedParams = node.spellId, node.positionalParams, node.namedParams
	if TestConditions(positionalParams, namedParams) then
		local property = node.property
		local count = 0
		local si = OvaleData:SpellInfo(spellId)
		local tbl = si.require[property] or {}
		for k, v in pairs(namedParams) do
			if not OvaleAST.PARAMETER_KEYWORD[k] then
				tbl[k] = v
				count = count + 1
			end
		end
		if count > 0 then
			si.require[property] = tbl
		end
	end
	return ok
end

-- Scan for spell IDs used in the script that are missing from the spellbook and add them if
-- they are variants of a spell with the same name as one already in the spellbook.
local function AddMissingVariantSpells(annotation)
	if annotation.functionReference then
		for _, node in ipairs(annotation.functionReference) do
			local positionalParams, namedParams = node.positionalParams, node.namedParams
			local spellId = positionalParams[1]
			if spellId and OvaleCondition:IsSpellBookCondition(node.func) then
				if not OvaleSpellBook:IsKnownSpell(spellId) and not OvaleCooldown:IsSharedCooldown(spellId) then
					local spellName
					if type(spellId) == "number" then
						spellName = OvaleSpellBook:GetSpellName(spellId)
					end
					if spellName then
						local name = API_GetSpellInfo(spellName)
						if spellName == name then
							OvaleCompile:Debug("Learning spell %s with ID %d.", spellName, spellId)
							OvaleSpellBook:AddSpell(spellId, spellName)
						end
					else
						local functionCall = node.name
						if node.paramsAsString then
							functionCall = node.name .. "(" .. node.paramsAsString .. ")"
						end
						OvaleCompile:Print("Unknown spell with ID %s used in %s.", spellId, functionCall)
					end
				end
			end
		end
	end
end

-- Add the buffId to the appropriate buff lists based on SpellInfo() data for that buff.
local function AddToBuffList(buffId, statName, isStacking)
	if statName then
		for _, useName in pairs(OvaleData.STAT_USE_NAMES) do
			if isStacking or not strfind(useName, "_stacking_") then
				-- Add to primary stat buff list.
				local name = useName .. "_" .. statName .. "_buff"
				local list = OvaleData.buffSpellList[name] or {}
				list[buffId] = true
				OvaleData.buffSpellList[name] = list
				-- Add to primary "short-name" stat buff list.
				local shortStatName = OvaleData.STAT_SHORTNAME[statName]
				if shortStatName then
					name = useName .. "_" .. shortStatName .. "_buff"
					list = OvaleData.buffSpellList[name] or {}
					list[buffId] = true
					OvaleData.buffSpellList[name] = list
				end
				-- Add to "any" buff list.
				name = useName .. "_any_buff"
				list = OvaleData.buffSpellList[name] or {}
				list[buffId] = true
				OvaleData.buffSpellList[name] = list
			end
		end
	else
		-- Look up the "stat" SpellInfo() property for the buff.
		local si = OvaleData.spellInfo[buffId]
		isStacking = si and (si.stacking == 1 or si.max_stacks)
		if si and si.stat then
			local stat = si.stat
			if type(stat) == "table" then
				for _, name in ipairs(stat) do
					AddToBuffList(buffId, name, isStacking)
				end
			else
				AddToBuffList(buffId, stat, isStacking)
			end
		end
	end
end

--[[
	Add the trinket buffs from the equipped trinkets to the appropriate buff lists.
--]]
local UpdateTrinketInfo = nil
do
	local trinket = {}

	UpdateTrinketInfo = function()
		trinket[1], trinket[2] = OvaleEquipment:GetEquippedTrinkets()
		for i = 1, 2 do
			local itemId = trinket[i]
			local ii = itemId and OvaleData:ItemInfo(itemId)
			local buffId = ii and ii.buff
			if buffId then
				if type(buffId) == "table" then
					for _, id in ipairs(buffId) do
						AddToBuffList(id)
					end
				else
					AddToBuffList(buffId)
				end
			end
		end
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleCompile:OnInitialize()
	-- Resolve module dependencies.
	OvaleArtifact = Ovale.OvaleArtifact
	OvaleAST = Ovale.OvaleAST
	OvaleCondition = Ovale.OvaleCondition
	OvaleCooldown = Ovale.OvaleCooldown
	OvaleData = Ovale.OvaleData
	OvaleEquipment = Ovale.OvaleEquipment
	OvalePaperDoll = Ovale.OvalePaperDoll
	OvalePower = Ovale.OvalePower
	OvaleScore = Ovale.OvaleScore
	OvaleScripts = Ovale.OvaleScripts
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleStance = Ovale.OvaleStance
end

function OvaleCompile:OnEnable()
	self:RegisterMessage("Ovale_CheckBoxValueChanged", "ScriptControlChanged")
	self:RegisterMessage("Ovale_EquipmentChanged", "EventHandler")
	self:RegisterMessage("Ovale_ListValueChanged", "ScriptControlChanged")
	self:RegisterMessage("Ovale_ScriptChanged")
	self:RegisterMessage("Ovale_SpecializationChanged", "Ovale_ScriptChanged")
	self:RegisterMessage("Ovale_SpellsChanged", "EventHandler")
	self:RegisterMessage("Ovale_StanceChanged")
	self:RegisterMessage("Ovale_TalentsChanged", "EventHandler")
	self:SendMessage("Ovale_ScriptChanged")
end

function OvaleCompile:OnDisable()
	self:UnregisterMessage("Ovale_CheckBoxValueChanged")
	self:UnregisterMessage("Ovale_EquipmentChanged")
	self:UnregisterMessage("Ovale_ListValueChanged")
	self:UnregisterMessage("Ovale_ScriptChanged")
	self:UnregisterMessage("Ovale_SpecializationChanged")
	self:UnregisterMessage("Ovale_SpellsChanged")
	self:UnregisterMessage("Ovale_StanceChanged")
	self:UnregisterMessage("Ovale_TalentsChanged")
end

function OvaleCompile:Ovale_ScriptChanged(event)
	-- Compile the script named in the current profile.
	self:CompileScript(Ovale.db.profile.source)
	-- Trigger script evaluation.
	self:EventHandler(event)
end

function OvaleCompile:Ovale_StanceChanged(event)
	if self_compileOnStances then
		self:EventHandler(event)
	end
end

function OvaleCompile:ScriptControlChanged(event, name)
	if not name then
		self:EventHandler(event)
	else
		-- Locate the correct script control definition.
		local control
		if event == "Ovale_CheckBoxValueChanged" then
			control = Ovale.checkBox[name]
		elseif event == "Ovale_ListValueChanged" then
			control = Ovale.list[name]
		end
		-- Only trigger script evaluation if "triggerEvaluation" was set
		-- for the named control.
		if control and control.triggerEvaluation then
			self:EventHandler(event)
		end
	end
end

function OvaleCompile:EventHandler(event)
	-- Advance age of the script evaluation state.
	self_serial = self_serial + 1
	self:Debug("%s: advance age to %d.", event, self_serial)
	Ovale.refreshNeeded[Ovale.playerGUID] = true
end

function OvaleCompile:CompileScript(name)
	-- Reset the trace state if we compile a new script.
	OvaleDebug:ResetTrace()
	-- Generate the node tree from the named script.
	self:Debug("Compiling script '%s'.", name)
	if self.ast then
		OvaleAST:Release(self.ast)
		self.ast = nil
	end
	self.ast = OvaleAST:ParseScript(name)
	-- Reset the controls defined by the previous script.
	Ovale:ResetControls()
end

function OvaleCompile:EvaluateScript(ast, forceEvaluation)
	self:StartProfiling("OvaleCompile_EvaluateScript")
	if type(ast) ~= "table" then
		forceEvaluation = ast
		ast = self.ast
	end
	local changed = false
	self_canEvaluate = self_canEvaluate or Ovale:IsPreloaded(self_requirePreload)
	if self_canEvaluate and ast and (forceEvaluation or not self.serial or self.serial < self_serial) then
		self:Debug("Evaluating script.")
		changed = true
		-- Reset compilation state.
		local ok = true
		self_compileOnStances = false
		wipe(self_icon)
		OvaleData:Reset()
		OvaleCooldown:ResetSharedCooldowns()
		self_timesEvaluated = self_timesEvaluated + 1
		self.serial = self_serial

		-- Evaluate every declaration node of the script.
		for _, node in ipairs(ast.child) do
			local nodeType = node.type
			if nodeType == "checkbox" then
				ok = EvaluateAddCheckBox(node)
			elseif nodeType == "icon" then
				ok = EvaluateAddIcon(node)
			elseif nodeType == "list_item" then
				ok = EvaluateAddListItem(node)
			elseif nodeType == "item_info" then
				ok = EvaluateItemInfo(node)
			elseif nodeType == "item_require" then
				ok = EvaluateItemRequire(node)
			elseif nodeType == "list" then
				ok = EvaluateList(node)
			elseif nodeType == "score_spells" then
				ok = EvaluateScoreSpells(node)
			elseif nodeType == "spell_aura_list" then
				ok = EvaluateSpellAuraList(node)
			elseif nodeType == "spell_info" then
				ok = EvaluateSpellInfo(node)
			elseif nodeType == "spell_require" then
				ok = EvaluateSpellRequire(node)
			else
				-- Any other top-level node types are no-ops when evaluating the script.
			end
			if not ok then
				break
			end
		end
		if ok then
			AddMissingVariantSpells(ast.annotation)
			UpdateTrinketInfo()
		end
	end
	self:StopProfiling("OvaleCompile_EvaluateScript")
	return changed
end

function OvaleCompile:GetFunctionNode(name)
	local node
	if self.ast and self.ast.annotation and self.ast.annotation.customFunction then
		node = self.ast.annotation.customFunction[name]
	end
	return node
end

function OvaleCompile:GetIconNodes()
	return self_icon
end

function OvaleCompile:DebugCompile()
	self:Print("Total number of times the script was evaluated: %d", self_timesEvaluated)
end
--</public-static-methods>
