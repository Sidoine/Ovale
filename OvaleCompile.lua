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
local L = Ovale.L
local OvalePool = Ovale.OvalePool
local OvaleTimeSpan = Ovale.OvaleTimeSpan

-- Forward declarations for module dependencies.
local OvaleCondition = nil
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
local strgmatch = string.gmatch
local strgsub = string.gsub
local strlen = string.len
local strlower = string.lower
local strmatch = string.match
local strsub = string.sub
local tinsert = table.insert
local wipe = table.wipe
local API_GetItemInfo = GetItemInfo
local API_GetSpellInfo = GetSpellInfo

local self_node = {}
local self_pool = OvalePool("OvaleCompile_pool")
local self_timeSpanPool = OvalePool("OvaleCompile_timeSpanPool")
local self_defines = {}
local self_sharedCooldownNames = {}
local self_customFunctions = {}
local self_missingSpellList = {}
-- table of functions called within the script: self_functionCalls[functionName] = node
local self_functionCalls = {}

-- Whether to trigger a script compilation if items or stances change.
local self_compileOnItems = false
local self_compileOnStances = false

-- Lua pattern to match a key=value pair, returning key and value.
local KEY_VALUE_PATTERN = "([%w_]+)=(!?[-%w\\_%.]+)"
-- Lua pattern to match a floating-point number that may start with a minus sign.
local NUMBER_PATTERN = "^%-?%d+%.?%d*$"

local OVALE_COMPILE_DEBUG = "compile"
local OVALE_MISSING_SPELL_DEBUG = "missing_spells"
local OVALE_UNKNOWN_SPELL_DEBUG = "unknown_spells"

-- Parameters used as conditionals in script declarations.
local OVALE_PARAMETER = {
	checkboxoff = true,
	checkboxon = true,
	glyph = true,
	if_spell = true,
	if_stance = true,
	item = true,
	itemcount = true,
	itemset = true,
	list = true,
	mastery = true,
	talent = true,
}

-- Known script functions other than conditions.
local OVALE_FUNCTIONS = {
	item = true,
	macro = true,
	spell = true,
	texture = true,
}
--</private-static-properties>

--<public-static-properties>
--master nodes of the current script (one node for each icon)
OvaleCompile.masterNodes = {}
OvaleCompile.customFunctionNode = {}
--</public-static-properties>

--<private-static-methods>
local function AddNode(node)
	tinsert(self_node, node)
	node.nodeId = #self_node
	return "node" .. #self_node
end

-- Parse params string into key=value pairs and positional arguments stored in paramList table.
local function ParseParameters(params, paramList)
	paramList = paramList or {}
	if params then
		-- Handle key=value pairs.
		for key, value in strgmatch(params, KEY_VALUE_PATTERN) do
			if strmatch(key, NUMBER_PATTERN) then
				key = tonumber(key)
			end
			if strmatch(value, NUMBER_PATTERN) then
				value = tonumber(value)
			end
			paramList[key] = value
		end
		-- Strip out all key=value pairs and handle positional arguments.
		params = strgsub(params, KEY_VALUE_PATTERN, "")
		local k = 1
		for word in strgmatch(params, "[-%w_\\%.]+") do
			if strmatch(word, NUMBER_PATTERN) then
				word = tonumber(word)
			end
			paramList[k] = word
			k = k + 1
		end
	end
	return paramList
end

local function HasTalent(talentId)
	if OvaleSpellBook:IsKnownTalent(talentId) then
		return OvaleSpellBook:GetTalentPoints(talentId) > 0
	else
		Ovale:FormatPrint("Unknown talent %s", talentId)
		return false
	end
end

local function RequireValue(value)
	local requireValue = (strsub(value, 1, 1) ~= "!")
	if not requireValue then
		value = strsub(value, 2)
		if strmatch(value, NUMBER_PATTERN) then
			value = tonumber(value)
		end
	end
	return value, requireValue
end

local function TestConditions(paramList)
	if paramList.glyph then
		local glyph, requireGlyph = RequireValue(paramList.glyph)
		local hasGlyph = OvaleSpellBook:IsActiveGlyph(glyph)
		if (requireGlyph and not hasGlyph) or (not requireGlyph and hasGlyph) then
			return false
		end
	end
	if paramList.mastery then
		local spec, requireSpec = RequireValue(paramList.mastery)
		local isSpec = OvalePaperDoll:IsSpecialization(spec)
		if (requireSpec and not isSpec) or (not requireSpec and isSpec) then
			return false
		end
	end
	if paramList.if_stance then
		local stance, requireStance = RequireValue(paramList.if_stance)
		local isStance = OvaleStance:IsStance(stance)
		if (requireStance and not isStance) or (not requireStance and isStance) then
			return false
		end
	end
	if paramList.if_spell then
		local spell, requireSpell = RequireValue(paramList.if_spell)
		local hasSpell = OvaleSpellBook:IsKnownSpell(spell)
		if (requireSpell and not hasSpell) or (not requireSpell and hasSpell) then
			return false
		end
	end
	if paramList.talent then
		local talent, requireTalent = RequireValue(paramList.talent)
		local hasTalent = HasTalent(talent)
		if (requireTalent and not hasTalent) or (not requireTalent and hasTalent) then
			return false
		end
	end
	if paramList.checkboxon then
		local cb = paramList.checkboxon
		if not Ovale.casesACocher[cb] then
			Ovale.casesACocher[cb] = {}
		end
		Ovale.casesACocher[cb].compile = true
		if not OvaleOptions:GetProfile().check[cb] then
			return false
		end
	end
	if paramList.checkboxoff then
		local cb = paramList.checkboxoff
		if not Ovale.casesACocher[cb] then
			Ovale.casesACocher[cb] = {}
		end
		Ovale.casesACocher[cb].compile = true
		if OvaleOptions:GetProfile().check[cb] then
			return false
		end
	end
	if paramList.list and paramList.item then
		local list = paramList.list
		local key = paramList.item
		if not Ovale.listes[list] then
			Ovale.listes[list] = { items = {}}
		end
		Ovale.listes[list].compile = true
		if OvaleOptions:GetProfile().list[list] ~= key then
			return false
		end
	end
	if paramList.itemset and paramList.itemcount then
		local equippedCount = OvaleEquipement:GetArmorSetCount(paramList.itemset)
		self_compileOnItems = true
		if equippedCount < paramList.itemcount then
			return false
		end
	end
	return true
end

local function ParseNumber(dummy, value)
	local node = self_pool:Get()
	node.type = "value"
	node.value = tonumber(value)
	node.origin = 0
	node.rate = 0
	node.timeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
	return dummy..AddNode(node)
end

local function ParseFunction(prefix, func, params)
	local paramList = ParseParameters(params)
	if func ~= "" then
		paramList.target = prefix
	else
		func = prefix
	end
	
	if not paramList.target then
		if strsub(func, 1, 6) == "Target" then
			paramList.target = "target"
			func = strsub(func, 7)
		end
	end
	
	if self_customFunctions[func] then
		self_functionCalls[func] = self_customFunctions[func]
		return self_customFunctions[func]
	end
	
	func = strlower(func)

	-- "debuff" and "buff" conditions implicitly set their aura filter.
	if not paramList.filter then
		if strsub(func, 1, 6) == "debuff" then
			paramList.filter = "debuff"
		elseif strsub(func, 1, 4) == "buff" then
			paramList.filter = "buff"
		elseif strsub(func, 1, 11) == "otherdebuff" then
			paramList.filter = "debuff"
		elseif strsub(func, 1, 9) == "otherbuff" then
			paramList.filter = "buff"
		end
	end

	local node = self_pool:Get()
	if func == "spell" or func == "macro" or func == "item" or func == "texture" then
		node.type = "action"
	else
		node.type = "function"
	end
	node.func = func
	node.params = paramList
	node.timeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
	local nodeName = AddNode(node)
	self_functionCalls[func] = node

	local mine = true
	if paramList.any then
		mine = false
	end

	local spellId = paramList[1]
	if spellId then
		-- For the conditions that refer to player's spells, check if the spell ID
		-- is a variant of a spell with the same name as one already in the
		-- spellbook.  If it is, then add that variant spell ID to our spellList.
		if OvaleCondition:IsSpellbookCondition(func) then
			if not OvaleSpellBook:IsKnownSpell(spellId) and not self_missingSpellList[spellId] and not self_sharedCooldownNames[spellId] then
				local spellName
				if type(spellId) == "number" then
					spellName = API_GetSpellInfo(spellId)
				end
				if spellName then
					if spellName == API_GetSpellInfo(spellName) then
						Ovale:DebugPrintf(OVALE_MISSING_SPELL_DEBUG, "Learning spell %s with ID %d", spellName, spellId)
						self_missingSpellList[spellId] = spellName
					end
				else
					Ovale:DebugPrintf(OVALE_UNKNOWN_SPELL_DEBUG, "Unknown spell with ID %s", spellId)
				end
			end
		end
	end

	return nodeName
end

--[[
	Parse the various Spell*{Buff,Debuff}() declarations.
	Check for test conditions to see whether this declaration is active.
	Filter out then test conditions and copy the rest of the key=value pairs
	into the aura table.
--]]
local function ParseSpellAuraList(auraTable, filter, paramList)
	if TestConditions(paramList) then
		paramList[1] = nil
		if not auraTable[filter] then
			for k, v in pairs(paramList) do
				if OVALE_PARAMETER[k] then
					paramList[k] = nil
				end
			end
			auraTable[filter] = paramList
		else
			local tbl = auraTable[filter]
			for k, v in pairs(paramList) do
				if not OVALE_PARAMETER[k] then
					tbl[k] = v
				end
			end
		end
	end
	return ""
end

local function ParseSpellAddBuff(params)
	local paramList = ParseParameters(params)
	local spellId = paramList[1]
	local si = OvaleData:SpellInfo(spellId)
	return ParseSpellAuraList(si.aura.player, "HELPFUL", paramList)
end

local function ParseSpellAddDebuff(params)
	local paramList = ParseParameters(params)
	local spellId = paramList[1]
	local si = OvaleData:SpellInfo(spellId)
	return ParseSpellAuraList(si.aura.player, "HARMFUL", paramList)
end

local function ParseSpellAddTargetBuff(params)
	local paramList = ParseParameters(params)
	local spellId = paramList[1]
	local si = OvaleData:SpellInfo(spellId)
	return ParseSpellAuraList(si.aura.target, "HELPFUL", paramList)
end

local function ParseSpellAddTargetDebuff(params)
	local paramList = ParseParameters(params)
	local spellId = paramList[1]
	local si = OvaleData:SpellInfo(spellId)
	return ParseSpellAuraList(si.aura.target, "HARMFUL", paramList)
end

local function ParseSpellDamageBuff(params)
	local paramList = ParseParameters(params)
	local spellId = paramList[1]
	local si = OvaleData:SpellInfo(spellId)
	return ParseSpellAuraList(si.aura.damage, "HELPFUL", paramList)
end

local function ParseSpellDamageDebuff(params)
	local paramList = ParseParameters(params)
	local spellId = paramList[1]
	local si = OvaleData:SpellInfo(spellId)
	return ParseSpellAuraList(si.aura.damage, "HARMFUL", paramList)
end

local function ParseSpellInfo(params)
	local paramList = ParseParameters(params)
	local spellId = paramList[1]
	if spellId then
		if not TestConditions(paramList) then
			return ""
		end
		local si = OvaleData:SpellInfo(spellId)
		for k,v in pairs(paramList) do
			if k == "addduration" then
				si.duration = si.duration + v
			elseif k == "addcd" then
				si.cd = si.cd + v
			elseif k == "addlist" then
				-- Add this buff to the named spell list.
				if not OvaleData.buffSpellList[v] then
					OvaleData.buffSpellList[v] = {}
				end
				OvaleData.buffSpellList[v][spellId] = true
			elseif k == "sharedcd" then
				self_sharedCooldownNames[v] = true
			else
				si[k] = v
			end
		end
	end
	return ""
end

local function ParseScoreSpells(params)
	for v in strgmatch(params, "(%d+)") do
		local spellId = tonumber(v)
		if spellId then
			OvaleScore:AddSpell(spellId)
		else
			Ovale:FormatPrint("ScoreSpell with unknown spell %s", v)
		end
	end
end

local function ParseSpellList(name, params)
	OvaleData.buffSpellList[name] = {}
	for v in strgmatch(params, "(%d+)") do
		v = tonumber(v)
		if v then
			OvaleData.buffSpellList[name][v] = true
		end
	end
end

local function ParseItemInfo(params)
	local paramList = ParseParameters(params)
	local itemId = paramList[1]
	if itemId then
		if not TestConditions(paramList) then
			return ""
		end
		for k, v in pairs(paramList) do
			if k == "proc" then
				-- Add the buff for this item proc to the spell list "item_proc_<proc>".
				local buff = tonumber(paramList.buff)
				if buff then
					local listName = "item_proc_" .. v
					if not OvaleData.buffSpellList[listName] then
						OvaleData.buffSpellList[listName] = {}
					end
					OvaleData.buffSpellList[listName][buff] = true
				end
			end
		end
	end
	return ""
end

local function ParseItemList(name, params)
	OvaleData.itemList[name] = {}
	local i = 1
	for v in strgmatch(params, "(%d+)") do
		OvaleData.itemList[name][i] = tonumber(v)
		i = i + 1
	end
end

local function ParseIf(a, b)
	local node = self_pool:Get()
	node.type = "if"
	node.a = self_node[tonumber(a)]
	node.b = self_node[tonumber(b)]
	node.timeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
	return AddNode(node)
end

local function ParseUnless(a, b)
	local node = self_pool:Get()
	node.type = "unless"
	node.a = self_node[tonumber(a)]
	node.b = self_node[tonumber(b)]
	node.timeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
	return AddNode(node)
end

local function ParseWait(a)
	local node = self_pool:Get()
	node.type = "wait"
	node.a = self_node[tonumber(a)]
	node.timeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
	return AddNode(node)
end

local function ParseAnd(a,b)
	local node = self_pool:Get()
	node.type = "and"
	node.a = self_node[tonumber(a)]
	node.b = self_node[tonumber(b)]
	node.timeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
	return AddNode(node)
end

local function ParseNot(a)
	local node = self_pool:Get()
	node.type = "not"
	node.a = self_node[tonumber(a)]
	node.timeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
	return AddNode(node)
end

local function ParseOr(a,b)
	local node = self_pool:Get()
	node.type = "or"
	node.a = self_node[tonumber(a)]
	node.b = self_node[tonumber(b)]
	node.timeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
	return AddNode(node)
end

local ParseOp
do
	local operator = {
		["+"] = "arithmetic",
		["-"] = "arithmetic",
		["*"] = "arithmetic",
		["/"] = "arithmetic",
		["%"] = "arithmetic",
		["<"] = "compare",
		["<="] = "compare",
		["=="] = "compare",
		[">="] = "compare",
		[">"] = "compare",
	}

	function ParseOp(a, op, b)
		local node = self_pool:Get()
		node.type = operator[op]
		node.operator = op
		node.a = self_node[tonumber(a)]
		node.b = self_node[tonumber(b)]
		node.timeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
		return AddNode(node)
	end
end

local function ParseGroup(text)
	local nodes = {}
	
	for w in strgmatch(text, "node(%d+)") do
		tinsert(nodes, self_node[tonumber(w)])
	end
	
	text = strgsub(text, "node%d+", "")

	if (strmatch(text,"[^ ]")) then
		Ovale:FormatPrint("syntax error: %s", text)
		return nil
	end
	
	local node = self_pool:Get()
	node.type = "group"
	node.nodes = nodes
	node.timeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
	return AddNode(node)
end

local function ParseAddListItem(list, item, text, params)
	local paramList = ParseParameters(params)
	if not TestConditions(paramList) then
		return ""
	end
	if (not Ovale.listes[list]) then
		Ovale.listes[list] = {items={},default=nil}
	end
	Ovale.listes[list].items[item] = text
	if paramList[1] and paramList[1] == "default" then
		Ovale.listes[list].default=item
	end
	return ""
end

local function ParseAddCheckBox(item, text, params)
	local paramList = ParseParameters(params)
	if not TestConditions(paramList) then
		return ""
	end
	if not Ovale.casesACocher[item] then
		Ovale.casesACocher[item] = {}
	end
	Ovale.casesACocher[item].text = text
	if  paramList[1] and paramList[1]=="default" then
		Ovale.casesACocher[item].checked = true
	end
	return ""
end

local function ParseDefine(key, value)
	self_defines[key] = value
	return ""
end

local function ReplaceDefine(key)
	return self_defines[key]
end

local function ParseLua(text)
	local node = self_pool:Get()
	node.type = "lua"
	node.lua = strsub(text, 2, strlen(text)-1)
	node.timeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
	return AddNode(node)
end

local function ParseInclude(name)
	local code
	local script = OvaleScripts.script[name]
	if script then
		code = script.code
	end
	if not code then
		Ovale:FormatPrint("Cannot Include(...): script named \"%s\" not found", name)
	end
	return code or ""
end

local function ParseCommands(text)
	local original = text
	text = strgsub(text,"(%b[])", ParseLua)
	while true do
		local was = text
		text = strgsub(text, "(%w+)%.?(%w*)%s*%((.-)%)", ParseFunction)
		text = strgsub(text, "([^%w])(%d+%.?%d*)", ParseNumber)
		text = strgsub(text, "node(%d+)%s*([%*%/%%])%s*node(%d+)", ParseOp)
		text = strgsub(text, "node(%d+)%s*([%+%-])%s*node(%d+)", ParseOp)
		text = strgsub(text, "{([node%d ]*)}", ParseGroup)
		if was == text then
			break
		end
	end
	
	while true do
		local was = text
		text = strgsub(text, "node(%d+)%s*([%>%<]=?)%s*node(%d+)", ParseOp)
		text = strgsub(text, "node(%d+)%s*(==)%s*node(%d+)", ParseOp)
		text = strgsub(text, "{([node%d ]*)}", ParseGroup)
		if was == text then
			break
		end
	end
		
	while true do
		local was = text
		text = strgsub(text, "not%s+node(%d+)", ParseNot)
		text = strgsub(text, "node(%d+)%s*([%*%+%-%/%>%<]=?|==)%s*node(%d+)", ParseOp)
		text = strgsub(text, "node(%d+)%s+and%s+node(%d+)", ParseAnd)
		text = strgsub(text, "node(%d+)%s+or%s+node(%d+)", ParseOr)
		text = strgsub(text, "if%s+node(%d+)%s+node(%d+)",ParseIf)
		text = strgsub(text, "unless%s+node(%d+)%s+node(%d+)",ParseUnless)
		text = strgsub(text, "wait%s+node(%d+)",ParseWait)
		text = strgsub(text, "{([node%d ]*)}", ParseGroup)
		if was == text then
			break
		end
	end

	local nodeId
	if text then
		nodeId = tonumber(strmatch(text, "node(%d+)"))
	end
	if not nodeId then
		Ovale:Print("no master node")
		return nil
	end
	
	-- Si il reste autre chose que des espaces, c'est une erreur de syntaxe
	text = strgsub(text, "node%d+", "", 1)
	if strmatch(text,"[^ ]") then
		Ovale:FormatPrint("Group: %s", original)
		Ovale:FormatPrint("syntax error: %s", text)
		return nil
	end
	return nodeId
end

local function ParseAddFunction(name, params, text)
	local paramList = ParseParameters(params)
	if TestConditions(paramList) then
		local nodeId = ParseCommands(text)
		if nodeId then
			local node = self_pool:Get()
			node.type = "customfunction"
			node.name = name
			node.params = paramList
			node.a = self_node[nodeId]
			node.timeSpan = OvaleTimeSpan(self_timeSpanPool:Get())
			return AddNode(node)
		end
	end
end

local function ParseAddIcon(params, text, secure)
	local paramList = ParseParameters(params)
	if TestConditions(paramList) then
		local masterNodeId = ParseCommands(text)
		if masterNodeId then
			local masterNode = self_node[masterNodeId]
			masterNode.params = paramList
			masterNode.secure = secure
			return masterNode
		end
	end
end

local function ParseItemName(text)
	local itemId = tonumber(text)
	if itemId then
		local item = API_GetItemInfo(spellId) or "Item " .. itemId
		return '"' .. item .. '"'
	else
		Ovale:FormatPrint("ItemName of %s unknown\n", text)
		return nil
	end
end

local function ParseSpellName(text)
	local spellId = tonumber(text)
	local spell = OvaleSpellBook:GetSpellName(spellId)
	if spell then
		return '"' .. spell .. '"'
	else
		Ovale:FormatPrint("SpellName of %s unknown", text)
		return nil
	end
end

local function ParseL(text)
	return '"'..L[text]..'"'
end

-- On compile les AddCheckBox et AddListItem
local function CompileInputs(text)
	Ovale.casesACocher = {}
	Ovale.listes = {}
	
	text = strgsub(text, "AddListItem%s*%(%s*([%w_]+)%s+([%w_]+)%s+\"(.-)\"%s*(.-)%s*%)", ParseAddListItem)
	text = strgsub(text, "AddCheckBox%s*%(%s*([%w_]+)%s+\"(.-)\"%s*(.-)%s*%)", ParseAddCheckBox)
	return text
end

-- Compile non-function and non-icon declarations.
local function CompileDeclarations(text)
	-- Define(CONSTANTE valeur)
	text = strgsub(text, "Define%s*%(%s*([%w_]+)%s+([%w_.=]+)%s*%)", ParseDefine)
	
	-- On remplace les constantes par leur valeur
	text = strgsub(text, "([%w_]+)", ReplaceDefine)
	
	-- Fonctions
	text = strgsub(text, "ItemName%s*%(%s*(%w+)%s*%)", ParseItemName)
	text = strgsub(text, "SpellName%s*%(%s*(%w+)%s*%)", ParseSpellName)
	text = strgsub(text, "L%s*%(%s*(%w+)%s*%)", ParseL)
	
	-- Options diverses
	OvaleData:ResetSpellInfo()
	text = strgsub(text, "SpellAddBuff%s*%((.-)%)", ParseSpellAddBuff)
	text = strgsub(text, "SpellAddDebuff%s*%((.-)%)", ParseSpellAddDebuff)
	text = strgsub(text, "SpellAddTargetDebuff%s*%((.-)%)", ParseSpellAddTargetDebuff)
	text = strgsub(text, "SpellDamageBuff%s*%((.-)%)", ParseSpellDamageBuff)
	text = strgsub(text, "SpellDamageDebuff%s*%((.-)%)", ParseSpellDamageDebuff)
	text = strgsub(text, "SpellInfo%s*%((.-)%)", ParseSpellInfo)
	text = strgsub(text, "ItemInfo%s*%((.-)%)", ParseItemInfo)
	text = strgsub(text, "ScoreSpells%s*%((.-)%)", ParseScoreSpells)
	text = strgsub(text, "SpellList%s*%(%s*([%w_]+)%s*(.-)%)", ParseSpellList)
	text = strgsub(text, "ItemList%s*%(%s*([%w_]+)%s*(.-)%)", ParseItemList)

	-- On vire les espaces en trop
	text = strgsub(text, "\n", " ")
	text = strgsub(text, "%s+", " ")
	
	return text
end

local function CompileScript(text)
	local self = OvaleCompile
	self_compileOnItems = false
	self_compileOnStances = false
	Ovale.bug = false

	wipe(self_defines)
	wipe(self_sharedCooldownNames)
	wipe(self_customFunctions)
	wipe(self_missingSpellList)
	wipe(self_functionCalls)
	wipe(self.customFunctionNode)

	-- Return all existing nodes to the node pool.
	for i, node in pairs(self_node) do
		self_node[i] = nil
		self_timeSpanPool:Release(node.timeSpan)
		self_pool:Release(node)
	end
	wipe(self_node)

	-- Loop and strip out comments and replace Include() directives until there
	-- are no more inclusions to make.
	while true do
		local was = text
		text = strgsub(text, "#.-\n","")
		text = strgsub(text, "#.*$","")
		text = strgsub(text, "Include%s*%(%s*([%w_]+)%s*%)", ParseInclude)
		if was == text then
			break
		end
	end

	text = CompileDeclarations(text)
	text = CompileInputs(text)

	for name, p, t in strgmatch(text, "AddFunction%s+(%w+)%s*(.-)%s*(%b{})") do
		local node = ParseAddFunction(name, p, t)
		if node then
			self_customFunctions[name] = node
			local nodeId = strmatch(node, "node(%d+)")
			self.customFunctionNode[name] = self_node[tonumber(nodeId)]
		end
	end
	
	local masterNodes = OvaleCompile.masterNodes
	wipe(masterNodes)

	-- On compile les AddIcon
	for p,t in strgmatch(text, "AddActionIcon%s*(.-)%s*(%b{})") do
		local node = ParseAddIcon(p,t,true)
		if node then
			tinsert(masterNodes, node)
		end
	end
	
	for p,t in strgmatch(text, "AddIcon%s*(.-)%s*(%b{})") do
		local node = ParseAddIcon(p,t)
		if node then
			tinsert(masterNodes, node)
		end
	end

	-- Verify that all the functions called within the script are defined.
	for p, v in pairs(self_functionCalls) do
		if not (OVALE_FUNCTIONS[p] or self_customFunctions[p] or OvaleCondition:IsCondition(p)) then
			Ovale:Errorf("Unknown function call: %s (node%s)", p, v.nodeId)
		end
	end

	-- Add any missing spells found while compiling the script into the spellbook.
	for k, v in pairs(self_missingSpellList) do
		OvaleSpellBook:AddSpell(k, v)
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleCompile:OnInitialize()
	-- Resolve module dependencies.
	OvaleCondition = Ovale.OvaleCondition
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
	self:RegisterMessage("PLAYER_REGEN_ENABLED")
	self:RegisterMessage("Ovale_CheckBoxValueChanged", "EventHandler")
	self:RegisterMessage("Ovale_EquipmentChanged")
	self:RegisterMessage("Ovale_GlyphsChanged", "EventHandler")
	self:RegisterMessage("Ovale_ListValueChanged", "EventHandler")
	self:RegisterMessage("Ovale_ScriptChanged", "EventHandler")
	self:RegisterMessage("Ovale_SpellsChanged", "EventHandler")
	self:RegisterMessage("Ovale_StanceChanged")
	self:RegisterMessage("Ovale_TalentsChanged", "EventHandler")
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
	self_pool:Drain()
end

function OvaleCompile:PLAYER_REGEN_ENABLED(event)
	self_pool:Drain()
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
	Ovale:DebugPrint(OVALE_COMPILE_DEBUG, event)
	self:Compile()
end

function OvaleCompile:Compile()
	local profile = OvaleOptions:GetProfile()
	local source = profile.source
	local code
	if source and OvaleScripts.script[source] then
		code = OvaleScripts.script[source].code
	else
		code = ""
	end
	CompileScript(code)
	Ovale.refreshNeeded.player = true
	Ovale:UpdateFrame()
end

function OvaleCompile:Debug()
	self_pool:Debug()
	Ovale:Print(self:DebugNode(self.masterNodes[1]))
end

function OvaleCompile:DebugNode(node)
	local text
	if (not node) then
		return "#nil"
	end
	if (node.type == "group") then
		text = "{"
		for k,n in ipairs(node.nodes) do
			text = text .. self:DebugNode(n) .. " "
		end
		text = text .. "}\n"
	elseif (node.type == "action" or node.type == "function") then
		text = node.func.."("
		for k,p in pairs(node.params) do
			text = text .. k.."=" .. p .. " "
		end
		text = text .. ")"
	elseif (node.type == "customfunction") then
		text = self:DebugNode(node.a)
	elseif (node.type == "if") then
		text = "if "..self:DebugNode(node.a).." "..self:DebugNode(node.b)
	elseif (node.type == "unless") then
		text = "unless "..self:DebugNode(node.a).." "..self:DebugNode(node.b)
	elseif (node.type == "wait") then
		text = "wait "..self:DebugNode(node.a)
	elseif (node.type == "and") then
		text = self:DebugNode(node.a).." and "..self:DebugNode(node.b)
	elseif (node.type == "or") then
		text = self:DebugNode(node.a).." or "..self:DebugNode(node.b)
	elseif (node.type == "not") then
		text = "not "..self:DebugNode(node.a)
	elseif node.type == "operator" then
		text = self:DebugNode(node.a)..node.operator..self:DebugNode(node.b)
	elseif node.type == "lua" then
		text = "["..node.lua.."]"
	elseif node.type == "value" then
		text = node.value
	else
		text = "#unknown node type#"
	end
	
	return text
end
--</public-static-methods>
