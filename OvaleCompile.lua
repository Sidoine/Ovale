--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2009, 2010, 2011, 2012, 2013 Sidoine, Johnny C. Lam

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

local _, Ovale = ...
local OvaleCompile = Ovale:NewModule("OvaleCompile", "AceEvent-3.0")
Ovale.OvaleCompile = OvaleCompile

--<private-static-properties>
local L = Ovale.L
local OvaleCondition = Ovale.OvaleCondition
local OvaleData = Ovale.OvaleData
local OvaleEquipement = Ovale.OvaleEquipement
local OvaleOptions = Ovale.OvaleOptions
local OvalePaperDoll = Ovale.OvalePaperDoll
local OvalePool = Ovale.OvalePool
local OvaleScripts = Ovale.OvaleScripts
local OvaleStance = Ovale.OvaleStance

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local strfind = string.find
local strgmatch = string.gmatch
local strgsub = string.gsub
local strlen = string.len
local strlower = string.lower
local strmatch = string.match
local strsub = string.sub
local tinsert = table.insert
local tremove = table.remove
local wipe = table.wipe
local API_GetItemInfo = GetItemInfo
local API_GetSpellInfo = GetSpellInfo

local self_node = {}
local self_pool = OvalePool:NewPool("OvaleCompile_pool")
local self_defines = {}
local self_customFunctions = {}
local self_missingSpellList = {}

-- Whether to trigger a script compilation if items or stances change.
local self_compileOnItems = false
local self_compileOnStances = false

local OVALE_COMPILE_DEBUG = "compile"
local OVALE_MISSING_SPELL_DEBUG = "missing_spells"
local OVALE_UNKNOWN_SPELL_DEBUG = "unknown_spells"
--</private-static-properties>

--<public-static-properties>
--master nodes of the current script (one node for each icon)
OvaleCompile.masterNodes = {}
--</public-static-properties>

--<private-static-methods>
local function AddNode(node)
	tinsert(self_node, node)
	node.nodeId = #self_node
	return "node" .. #self_node
end

local function ParseParameters(params)
	local paramList = {}
	if not params then
		return paramList
	end
	for k,v in strgmatch(params, "([%w_]+)=([-%w\\_%.]+)") do
		if (strmatch(v,"^%-?%d+%.?%d*$")) then
			v = tonumber(v)
		end	
		if (strmatch(k,"^%-?%d+%.?%d*$")) then
			k = tonumber(k)
		end		
		paramList[k] = v
	end
	params = strgsub(params,"[%w_]+=[-%w\\_%.]+","")
	local n=0
	for w in strgmatch(params, "[-%w_\\%.]+") do
		if (strmatch(w,"^%-?%d+%.?%d*$")) then
			w = tonumber(w)
		end		
		paramList[n+1] = w
		n=n+1
	end
	return paramList
end

local function HasTalent(talentId)
	if not OvaleData.listeTalentsRemplie then
		OvaleData:RemplirListeTalents()
	end
	if OvaleData.listeTalentsRemplie then
		if OvaleData.pointsTalent[talentId]~=nil then
			return OvaleData.pointsTalent[talentId]>0
		else
			Ovale:FormatPrint("Unknown talent %s", talentId)
			return false
		end
	else
		return false
	end
end

local function TestConditions(paramList)
	if paramList.glyph and not OvaleData.glyphs[paramList.glyph] then
		return false
	end
	if paramList.mastery and OvalePaperDoll.specialization ~= paramList.mastery then
		return false
	end
	if paramList.if_stance then
		self_compileOnStances = true
		if not OvaleStance:IsStance(paramList.if_stance) then
			return false
		end
	end
	if paramList.if_spell and not OvaleData.spellList[paramList.if_spell] then
		return false
	end
	if paramList.talent and not HasTalent(paramList.talent) then
		return false
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

local function ParseTime(value)
	local node = self_pool:Get()
	node.type = "time"
	node.value = tonumber(value)
	return AddNode(node)
end

local function ParseNumber(dummy, value)
	local node = self_pool:Get()
	node.type = "value"
	node.value = tonumber(value)
	node.origin = 0
	node.rate = 0
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
		if strfind(func, "Target") == 1 then
			paramList.target = "target"
			func = strsub(func, 7)
		end
	end
	
	if self_customFunctions[func] then
		return self_customFunctions[func]
	end
	
	func = strlower(func)

	-- "debuff" and "buff" conditions implicitly set their aura filter.
	if not paramList.filter then
		if strfind(func, "debuff") == 1 then
			paramList.filter = "debuff"
		elseif strfind(func, "buff") == 1 then
			paramList.filter = "buff"
		elseif strfind(func, "otherdebuff") == 1 then
			paramList.filter = "debuff"
		elseif strfind(func, "otherbuff") == 1 then
			paramList.filter = "buff"
		end
	end

	local node = self_pool:Get()
	node.type = "function"
	node.func = func
	node.params = paramList
	local nodeName = AddNode(node)

	local mine = true
	if paramList.any then
		mine = false
	end

	local spellId = paramList[1]
	if spellId then
		-- For the conditions that refer to player's spells, check if the spell ID
		-- is a variant of a spell with the same name as one already in the
		-- spellbook.  If it is, then add that variant spell ID to our spellList.
		if OvaleCondition.spellbookConditions[func] then
			if not OvaleData.spellList[spellId] and not self_missingSpellList[spellId] then
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
					Ovale:DebugPrintf(OVALE_UNKNOWN_SPELL_DEBUG, "Unknown spell with ID %d", spellId)
				end
			end
		end
	end

	return nodeName
end

local function ParseSpellAddDebuff(params)
	local paramList = ParseParameters(params)
	local spellId = paramList[1]
	if spellId then
		paramList[1] = nil
		OvaleData:GetSpellInfo(spellId).aura.player.HARMFUL = paramList
	end
	return ""
end

local function ParseSpellAddBuff(params)
	local paramList = ParseParameters(params)
	local spellId = paramList[1]
	if spellId then
		paramList[1] = nil
		OvaleData:GetSpellInfo(spellId).aura.player.HELPFUL = paramList
	end
	return ""
end

local function ParseSpellAddTargetDebuff(params)
	local paramList = ParseParameters(params)
	local spellId = paramList[1]
	if spellId then
		paramList[1] = nil
		OvaleData:GetSpellInfo(spellId).aura.target.HARMFUL = paramList
	end
	return ""
end

local function ParseSpellDamageBuff(params)
	local paramList = ParseParameters(params)
	local spellId = paramList[1]
	if spellId then
		paramList[1] = nil
		OvaleData:GetSpellInfo(spellId).damageAura.HELPFUL = paramList
	end
	return ""
end

local function ParseSpellDamageDebuff(params)
	local paramList = ParseParameters(params)
	local spellId = paramList[1]
	if spellId then
		paramList[1] = nil
		OvaleData:GetSpellInfo(spellId).damageAura.HARMFUL = paramList
	end
	return ""
end

local function ParseSpellInfo(params)
	local paramList = ParseParameters(params)
	local spellId = paramList[1]
	if spellId then
		if not TestConditions(paramList) then
			return ""
		end
		local spellInfo = OvaleData:GetSpellInfo(spellId)
		for k,v in pairs(paramList) do
			if k == "addduration" then
				spellInfo.duration = spellInfo.duration + v
			elseif k == "addcd" then
				spellInfo.cd = spellInfo.cd + v
			else
				spellInfo[k] = v
			end
		end
	end
	return ""
end

local function ParseScoreSpells(params)
	for v in strgmatch(params, "(%d+)") do
		local spellId = tonumber(v)
		if spellId then
			--Ovale:FormatPrint("Add spell to score %d", spellId)
			OvaleData.scoreSpell[spellId] = true
		else
			Ovale:FormatPrint("ScoreSpell with unknown spell %s", v)
		end
	end
end

local function ParseSpellList(name, params)
	OvaleData.buffSpellList[name] = {}
	local i = 1
	for v in strgmatch(params, "(%d+)") do
		OvaleData.buffSpellList[name][i] = tonumber(v)
		i = i + 1
	end
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
	return AddNode(node)
end

local function ParseUnless(a, b)
	local node = self_pool:Get()
	node.type = "unless"
	node.a = self_node[tonumber(a)]
	node.b = self_node[tonumber(b)]
	return AddNode(node)
end

local function ParseWait(a)
	local node = self_pool:Get()
	node.type = "wait"
	node.a = self_node[tonumber(a)]
	return AddNode(node)
end

local function ParseAnd(a,b)
	local node = self_pool:Get()
	node.type = "and"
	node.a = self_node[tonumber(a)]
	node.b = self_node[tonumber(b)]
	return AddNode(node)
end

local function ParseNot(a)
	local node = self_pool:Get()
	node.type = "not"
	node.a = self_node[tonumber(a)]
	return AddNode(node)
end

local function ParseBefore(t,a)
	local node = self_pool:Get()
	node.type = "before"
	node.time = self_node[tonumber(t)]
	node.a = self_node[tonumber(a)]
	return AddNode(node)
end

local function ParseAfter(t,a)
	local node = self_pool:Get()
	node.type = "after"
	node.time = self_node[tonumber(t)]
	node.a = self_node[tonumber(a)]
	return AddNode(node)
end

local function ParseBetween(a,b)
	local node = self_pool:Get()
	node.type = "between"
	node.a = self_node[tonumber(a)]
	node.b = self_node[tonumber(b)]
	return AddNode(node)
end

local function ParseFromUntil(a,b)
	local node = self_pool:Get()
	node.type = "fromuntil"
	node.a = self_node[tonumber(a)]
	node.b = self_node[tonumber(b)]
	return AddNode(node)
end

local function ParseOr(a,b)
	local node = self_pool:Get()
	node.type = "or"
	node.a = self_node[tonumber(a)]
	node.b = self_node[tonumber(b)]
	return AddNode(node)
end

local function ParseOp(a, op, b)
	local node = self_pool:Get()
	node.type = "operator"
	node.operator = op
	node.a = self_node[tonumber(a)]
	node.b = self_node[tonumber(b)]
	return AddNode(node)
end

local function ParseCompare(comp,t,a)
	local node = self_pool:Get()
	node.type = "compare"
	node.comparison = comp
	node.time = self_node[tonumber(t)]
	node.b = self_node[tonumber(b)]
	return AddNode(node)
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
	return AddNode(node)
end

local function ParseCommands(text)
	local original = text
	text = strgsub(text,"(%b[])", ParseLua)
	while true do
		local was = text
		text = strgsub(text, "(%w+)%.?(%w*)%s*%((.-)%)", ParseFunction)
		text = strgsub(text, "(%d+%.?%d*)s", ParseTime)
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
		text = strgsub(text, "between%s+node(%d+)%s+and%s+node(%d+)", ParseBetween)
		text = strgsub(text, "from%s+node(%d+)%s+until%s+node(%d+)", ParseFromUntil)
		text = strgsub(text, "(more)%s+than%s+node(%d+)%s+node(%d+)", ParseCompare)
		text = strgsub(text, "(less)%s+than%s+node(%d+)%s+node(%d+)", ParseCompare)		
		text = strgsub(text, "(at least)%s+node(%d+)%s+node(%d+)", ParseCompare)
		text = strgsub(text, "(at most)%s+node(%d+)%s+node(%d+)", ParseCompare)		
		text = strgsub(text, "node(%d+)%s+before%s+node(%d+)", ParseBefore)
		text = strgsub(text, "node(%d+)%s+after%s+node(%d+)", ParseAfter)
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

	local masterNode
	if (text) then
		masterNode = strmatch(text, "node(%d+)")
	end
	if (not masterNode) then
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
	return masterNode
end

local function ParseAddIcon(params, text, secure)
	-- On convertit le numéro de node en node
	local masterNode = ParseCommands(text)
	if not masterNode then return nil end
	masterNode = self_node[tonumber(masterNode)]
	masterNode.params = ParseParameters(params)
	masterNode.secure = secure
	if not TestConditions(masterNode.params) then
		return nil
	end
	return masterNode
end

local function ParseCanStopChannelling(text)
	local spellId = tonumber(text)
	if spellId then
		OvaleData:GetSpellInfo(spellId).canStopChannelling = true
	else
		Ovale:FormatPrint("CanStopChannelling with unknown spell %s", text)
	end
	return ""
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
	local spell = OvaleData:GetSpellName(spellId)
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

-- Suppression des commentaires
local function CompileComments(text)
	text = strgsub(text, "#.-\n","")
	text = strgsub(text, "#.*$","")
	return text
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
	text = strgsub(text, "Define%s*%(%s*([%w_]+)%s+(%w+)%s*%)", ParseDefine)
	
	-- On remplace les constantes par leur valeur
	text = strgsub(text, "([%w_]+)", ReplaceDefine)
	
	-- Fonctions
	text = strgsub(text, "ItemName%s*%(%s*(%w+)%s*%)", ParseItemName)
	text = strgsub(text, "SpellName%s*%(%s*(%w+)%s*%)", ParseSpellName)
	text = strgsub(text, "L%s*%(%s*(%w+)%s*%)", ParseL)
	
	-- Options diverses
	OvaleData:ResetSpellInfo()
	text = strgsub(text, "CanStopChannelling%s*%(%s*(%w+)%s*%)", ParseCanStopChannelling)
	text = strgsub(text, "SpellAddBuff%s*%((.-)%)", ParseSpellAddBuff)
	text = strgsub(text, "SpellAddDebuff%s*%((.-)%)", ParseSpellAddDebuff)
	text = strgsub(text, "SpellAddTargetDebuff%s*%((.-)%)", ParseSpellAddTargetDebuff)
	text = strgsub(text, "SpellDamageBuff%s*%((.-)%)", ParseSpellDamageBuff)
	text = strgsub(text, "SpellDamageDebuff%s*%((.-)%)", ParseSpellDamageDebuff)
	text = strgsub(text, "SpellInfo%s*%((.-)%)", ParseSpellInfo)
	text = strgsub(text, "ScoreSpells%s*%((.-)%)", ParseScoreSpells)
	text = strgsub(text, "SpellList%s*%(%s*([%w_]+)%s*(.-)%)", ParseSpellList)
	text = strgsub(text, "ItemList%s*%(%s*([%w_]+)%s*(.-)%)", ParseItemList)

	-- On vire les espaces en trop
	text = strgsub(text, "\n", " ")
	text = strgsub(text, "%s+", " ")
	
	return text
end

local function CompileScript(text)
	self_compileOnItems = false
	self_compileOnStances = false
	Ovale.bug = false

	wipe(self_defines)
	wipe(self_missingSpellList)

	-- Return all existing nodes to the node pool.
	local node 
	while true do
		node = tremove(self_node)
		if not node then break end
		self_pool:Release(node)
	end
	wipe(self_node)

	text = CompileComments(text)
	text = CompileDeclarations(text)
	text = CompileInputs(text)

	for p,t in strgmatch(text, "AddFunction%s+(%w+)%s*(%b{})") do
		local node = ParseCommands(t)
		if node then
			self_customFunctions[p] = "node"..node
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

	-- Add any missing spells found while compiling the script into the spellbook.
	for k, v in pairs(self_missingSpellList) do
		OvaleData.spellList[k] = v
	end
end
--</private-static-methods>

--<public-static-methods>
function OvaleCompile:OnEnable()
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

function OvaleCompile:EventHandler(event)
	Ovale:DebugPrint(OVALE_COMPILE_DEBUG, event)
	self:Compile()
end

function OvaleCompile:Ovale_EquipmentChanged(event)
	if self_compileOnItems then
		self:EventHandler(event)
	end
	Ovale.refreshNeeded.player = true
end

function OvaleCompile:Ovale_StanceChanged(event)
	if self_compileOnStances then
		self:EventHandler(event)
	end
	Ovale.refreshNeeded.player = true
end

function OvaleCompile:Compile()
	local profile = OvaleOptions:GetProfile()
	local source = profile.source
	local code = OvaleScripts.script[OvalePaperDoll.class][source].code
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
	elseif (node.type == "function") then
		text = node.func.."("
		for k,p in pairs(node.params) do
			text = text .. k.."=" .. p .. " "
		end
		text = text .. ")"
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
	elseif (node.type == "before") then
		text = self:DebugNode(node.time) .. " before "..self:DebugNode(node.a)
	elseif (node.type == "between") then
		text = "between "..self:DebugNode(node.a).." and "..self:DebugNode(node.b)
	elseif (node.type == "fromuntil") then
		text = "from "..self:DebugNode(node.a).." until "..self:DebugNode(node.b)
	elseif (node.type == "compare") then
		text = node.comparison.." than "..self:DebugNode(node.time).." "..self:DebugNode(node.a)
	elseif (node.type == "time") then
		text = node.value.."s"
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
