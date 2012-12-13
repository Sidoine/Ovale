--[[--------------------------------------------------------------------
    Ovale Spell Priority
    Copyright (C) 2009, 2010, 2011, 2012 Sidoine

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License in the LICENSE
    file accompanying this program.
----------------------------------------------------------------------]]

local L = LibStub("AceLocale-3.0"):GetLocale("Ovale")

OvaleCompile = {}

--<private-static-properties>
local node={}
local defines = {}
local customFunctions = {}
local unknownSpellNodes = {}

local ipairs, pairs, tonumber = ipairs, pairs, tonumber
local strfind, strgmatch, strgsub = string.find, string.gmatch, string.gsub
local strlen, strlower, strmatch, strsub = string.len, string.lower, string.match, string.sub
local GetGlyphSocketInfo, GetNumGlyphSockets, GetSpecialization = GetGlyphSocketInfo, GetNumGlyphSockets, GetSpecialization
--</private-static-properties>

--<private-static-methods>
local function AddNode(newNode)
	node[#node+1] = newNode
	newNode.nodeId = #node
	return "node"..#node
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


local function HasGlyph(spellId)
	for i = 1, GetNumGlyphSockets() do
		local enabled, glyphType, glyphTooltipIndex, glyphSpellID = GetGlyphSocketInfo(i)
		if (glyphSpellID == spellId) then
			return true
		end
	end
	return false
end

local function HasTalent(talentId)
	if not OvaleData.listeTalentsRemplie then
		OvaleData:RemplirListeTalents()
	end
	if OvaleData.listeTalentsRemplie then
		if OvaleData.pointsTalent[talentId]~=nil then
			return OvaleData.pointsTalent[talentId]>0
		else
			Ovale:Print("Unknown talent "..talentId)
			return false
		end
	else
		return false
	end
end

local function TestConditions(paramList)
	if paramList.glyph and not HasGlyph(paramList.glyph) then
		return false
	end
	if paramList.mastery and paramList.mastery~=GetSpecialization() then
		return false
	end
	if paramList.if_stance then
		Ovale.compileOnStances = true
		if paramList.if_stance ~= GetShapeshiftForm() then
			return false
		end
	end
	if paramList.if_spell then
		if not OvaleData.spellList[paramList.if_spell] then
			return false
		end
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
		local set = paramList.itemset
		local count = paramList.itemcount
		local nombre = 0
		Ovale.compileOnItems = true
		if OvaleEquipement.nombre[set] then
			nombre = OvaleEquipement.nombre[set]
		end
		if nombre < count then
			return false
		end
	end
	return true
end

local function ParseTime(value)
	return AddNode({type="time", value=tonumber(value)})
end

local function ParseNumber(dummy, value)
	return dummy..AddNode({type="value", value=tonumber(value), origin=0, rate=0})
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
	
	if customFunctions[func] then
		return customFunctions[func]
	end
	
	func = strlower(func)

	local newNode = { type="function", func=func, params=paramList}
	local newNodeName = AddNode(newNode)

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
			if not OvaleData.spellList[spellId] and not OvaleData.missingSpellList[spellId] then
				local spellName
				if type(spellId) == "number" then
					spellName = GetSpellInfo(spellId)
				end
				if spellName then
					if spellName == GetSpellInfo(spellName) then
						Ovale:debugPrint("missing_spells", "Learning spell "..tostring(spellName).." with ID "..spellId)
						OvaleData.missingSpellList[spellId] = spellName
					else
						unknownSpellNodes[newNode.nodeId] = spellId
					end
				else
					Ovale:debugPrint("unknown_spells", "Unknown spell with ID "..spellId)
				end
			end
		end

		-- For the conditions that refer to aura spell IDs, add those spell IDs to
		-- the list of auras OvaleAura should be tracking.
		if OvaleCondition.auraConditions[func] then
			if type(spellId) == "number" then
				OvaleData:AddSpellToFilter(spellId, mine)
			elseif OvaleData.buffSpellList[spellId] then
				for _, v in pairs(OvaleData.buffSpellList[spellId]) do
					OvaleData:AddSpellToFilter(v, mine)
				end
			end
		end
	end

	return newNodeName
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
			--Ovale:Print("Add spell to score "..spellId)
			OvaleData.scoreSpell[spellId] = true
		else
			Ovale:Print("unknown spell "..v)
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

local function ParseIf(a, b)
	local newNode = {type="if", a=node[tonumber(a)], b=node[tonumber(b)]}
	return AddNode(newNode)
end

local function ParseUnless(a, b)
	local newNode = {type="unless", a=node[tonumber(a)], b=node[tonumber(b)]}
	return AddNode(newNode)
end

local function ParseWait(a)
	local newNode = {type="wait", a=node[tonumber(a)]}
	return AddNode(newNode)
end

local function ParseAnd(a,b)
	local newNode = {type="and", a=node[tonumber(a)], b=node[tonumber(b)]}
	return AddNode(newNode)
end

local function ParseNot(a)
	local newNode = {type="not", a=node[tonumber(a)]}
	return AddNode(newNode)
end

local function ParseBefore(a,b)
	local newNode = {type="before", time=node[tonumber(a)], a=node[tonumber(b)]}
	return AddNode(newNode)
end

local function ParseAfter(a,b)
	local newNode = {type="after", time=node[tonumber(a)], a=node[tonumber(b)]}
	return AddNode(newNode)
end

local function ParseBetween(a,b)
	local newNode = {type="between", a=node[tonumber(a)], b=node[tonumber(b)]}
	return AddNode(newNode)
end

local function ParseFromUntil(a,b)
	local newNode = {type="fromuntil", a=node[tonumber(a)], b=node[tonumber(b)]}
	return AddNode(newNode)
end

local function ParseOr(a,b)
	local newNode = {type="or", a=node[tonumber(a)], b=node[tonumber(b)]}
	return AddNode(newNode)
end

local function ParseOp(a, op, b)
	local newNode = {type="operator", operator=op, a=node[tonumber(a)], b=node[tonumber(b)]}
	return AddNode(newNode)
end

local function ParseCompare(comp,t,a)
	local newNode = {type="compare", comparison=comp, time=node[tonumber(t)], a=node[tonumber(a)]}
	return AddNode(newNode)
end

local function ParseGroup(text)
	local nodes={}
	
	for w in strgmatch(text, "node(%d+)") do
		nodes[#nodes+1] = node[tonumber(w)]
	end
	
	text = strgsub(text, "node%d+", "")

	if (strmatch(text,"[^ ]")) then
		Ovale:Print("syntax error:"..text)
		return nil
	end
	
	local newNode = {type="group", nodes=nodes}
	return AddNode(newNode)
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
	defines[key] = value
	return ""
end

local function ReplaceDefine(key)
	return defines[key]
end

local function ParseLua(text)
	local newNode = {type="lua", lua = strsub(text, 2, strlen(text)-1)}
	return AddNode(newNode)
end

local function ParseCommands(text)
	local original = text
	text = strgsub(text,"(%b[])", ParseLua)
	while (1==1) do
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
	
	while (1==1) do
		local was = text
		text = strgsub(text, "node(%d+)%s*([%>%<]=?)%s*node(%d+)", ParseOp)
		text = strgsub(text, "node(%d+)%s*(==)%s*node(%d+)", ParseOp)
		text = strgsub(text, "{([node%d ]*)}", ParseGroup)
		if was == text then
			break
		end
	end
		
	while (1==1) do
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
		if (was == text) then
			break
		end
	end

	while (1==1) do
		local was = text
		text = strgsub(text, "not%s+node(%d+)", ParseNot)
		text = strgsub(text, "node(%d+)%s*([%*%+%-%/%>%<]=?|==)%s*node(%d+)", ParseOp)
		text = strgsub(text, "node(%d+)%s+and%s+node(%d+)", ParseAnd)
		text = strgsub(text, "node(%d+)%s+or%s+node(%d+)", ParseOr)
		text = strgsub(text, "if%s+node(%d+)%s+node(%d+)",ParseIf)
		text = strgsub(text, "unless%s+node(%d+)%s+node(%d+)",ParseUnless)
		text = strgsub(text, "wait%s+node(%d+)",ParseWait)
		text = strgsub(text, "{([node%d ]*)}", ParseGroup)
		if (was == text) then
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
	if (strmatch(text,"[^ ]")) then
		Ovale:Print("Group:"..original)
		Ovale:Print("syntax error:"..text)
		return nil
	end
	return masterNode
end

local function ParseAddIcon(params, text, secure)
	-- On convertit le numéro de node en node
	local masterNode = ParseCommands(text)
	if not masterNode then return nil end
	masterNode = node[tonumber(masterNode)]
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
		Ovale:Print("CanStopChannelling with unknown spell "..spellId)
	end
	return ""
end

local function ParseSpellName(text)
	local spell = OvaleData:GetSpellInfoOrNil(text)
	if (spell) then
		return '"'..spell..'"'
	else
		Ovale:Print("SpellName of "..text.." unknown")
		return nil
	end
end

local function ParseL(text)
	return '"'..L[text]..'"'
end
--</private-static-methods>

--<public-static-methods>
function OvaleCompile:CompileComments(text)
	text = strgsub(text, "#.-\n","")
	text = strgsub(text, "#.*$","")
	return text
end

function OvaleCompile:CompileInputs(text)
	Ovale.casesACocher = {}
	Ovale.listes = {}
	
	text = strgsub(text, "AddListItem%s*%(%s*([%w_]+)%s+([%w_]+)%s+\"(.-)\"%s*(.-)%s*%)", ParseAddListItem)
	text = strgsub(text, "AddCheckBox%s*%(%s*([%w_]+)%s+\"(.-)\"%s*(.-)%s*%)", ParseAddCheckBox)
	return text
end

function OvaleCompile:CompileDeclarations(text)
	-- Define(CONSTANTE valeur)
	text = strgsub(text, "Define%s*%(%s*([%w_]+)%s+(%w+)%s*%)", ParseDefine)
	
	-- On remplace les constantes par leur valeur
	text = strgsub(text, "([%w_]+)", ReplaceDefine)
	
	-- Fonctions
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

	-- On vire les espaces en trop
	text = strgsub(text, "\n", " ")
	text = strgsub(text, "%s+", " ")
	
	return text
end

function OvaleCompile:Compile(text)
	Ovale.compileOnItems = false
	Ovale.compileOnStances = false
	Ovale.bug = false
	node = {}
	defines = {}
	unknownSpellNodes = {}

	-- Suppression des commentaires
	text = self:CompileComments(text)

	-- Compile non-function and non-icon declarations.
	text = self:CompileDeclarations(text)

	-- On compile les AddCheckBox et AddListItem
	text = self:CompileInputs(text)

	OvaleData:ResetSpellFilter()

	for p,t in strgmatch(text, "AddFunction%s+(%w+)%s*(%b{})") do
		local newNode = ParseCommands(t)
		if newNode then
			customFunctions[p] = "node"..newNode
		end
	end
	
	local masterNodes ={}
	
	-- On compile les AddIcon
	for p,t in strgmatch(text, "AddActionIcon%s*(.-)%s*(%b{})") do
		local newNode = ParseAddIcon(p,t,true)
		if newNode then
			masterNodes[#masterNodes+1] = newNode
		end
	end
	
	for p,t in strgmatch(text, "AddIcon%s*(.-)%s*(%b{})") do
		local newNode = ParseAddIcon(p,t)
		if newNode then
			masterNodes[#masterNodes+1] = newNode
		end
	end
	return masterNodes
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
		local spellId = unknownSpellNodes[node.nodeId]
		for k,p in pairs(node.params) do
			if spellId and p == spellId then
				p = p .. ":unknown"
			end
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
