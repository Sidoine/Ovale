local L = LibStub("AceLocale-3.0"):GetLocale("Ovale")

local node={}
local defines = {}

local function ParseParameters(params)
	local paramList = {}
	for k,v in string.gmatch(params, "(%w+)=(%w+)") do
		if (string.match(v,"^%-?%d+%.?%d*$")) then
			v = tonumber(v)
		end		
		paramList[k] = v
	end
	params = string.gsub(params,"%w+=%w+","")
	local n=0
	for w in string.gmatch(params, "%w+") do
		if (string.match(w,"^%-?%d+%.?%d*$")) then
			w = tonumber(w)
		end		
		paramList[n+1] = w
		n=n+1
	end
	return paramList
end

local function ParseFunction(func, params)
	local paramList = ParseParameters(params)
	local newNode = { type="function", func=func, params=paramList}
	node[#node+1] = newNode
	return "node"..#node
end

local function ParseIf(a, b)
	local newNode = {type="if", a=node[tonumber(a)], b=node[tonumber(b)]}
	node[#node+1] = newNode
	return "node"..#node
end

local function ParseUnless(a, b)
	local newNode = {type="unless", a=node[tonumber(a)], b=node[tonumber(b)]}
	node[#node+1] = newNode
	return "node"..#node
end

local function ParseAnd(a,b)
	local newNode = {type="and", a=node[tonumber(a)], b=node[tonumber(b)]}
	node[#node+1] = newNode
	return "node"..#node
end

local function ParseBefore(a,b)
	local newNode = {type="before", time=tonumber(a), a=node[tonumber(b)]}
	node[#node+1] = newNode
	return "node"..#node
end

local function ParseOr(a,b)
	local newNode = {type="or", a=node[tonumber(a)], b=node[tonumber(b)]}
	node[#node+1] = newNode
	return "node"..#node
end

local function ParseGroup(text)
	local nodes={}
	
	for w in string.gmatch(text, "node(%d+)") do
		nodes[#nodes+1] = node[tonumber(w)]
	end
	
	text = string.gsub(text, "node%d+", "")

	if (string.match(text,"[^ ]")) then
		Ovale:Print("syntax error:"..text)
		return nil
	end
	
	local newNode = {type="group", nodes=nodes}
	node[#node+1] = newNode
	return "node"..#node
end

local function subtest(text, pattern, func)
	while (1==1) do
		local was = text
		text = string.gsub(text, pattern, func)
		if (was == text) then
			break
		end
	end
	return text
end

local function ParseAddListItem(list,item,text)
	if (not Ovale.listes[list]) then
		Ovale.listes[list] = {}
	end
	Ovale.listes[list][item] = text
	return ""
end

local function ParseAddCheckBox(item, text)
	Ovale.casesACocher[item] = text
	return ""
end

local function ParseDefine(key, value)
	defines[key] = value
	return ""
end

local function ParseAddIcon(params, text)
	local original = text
	while (1==1) do
		local was = text
		text = string.gsub(text, "(%w+)%s*%((.-)%)", ParseFunction)
		text = string.gsub(text, "node(%d+)%s+and%s+node(%d+)", ParseAnd)
		text = string.gsub(text, "node(%d+)%s+or%s+node(%d+)", ParseOr)
		text = string.gsub(text, "(%d+%.?%d*)s%s+before%s+node(%d+)", ParseBefore)
		text = string.gsub(text, "if%s+node(%d+)%s+node(%d+)",ParseIf)
		text = string.gsub(text, "unless%s+node(%d+)%s+node(%d+)",ParseUnless)
		text = string.gsub(text, "{([node%d ]*)}", ParseGroup)
		if (was == text) then
			break
		end
	end
		
	local masterNode
	if (text) then
		masterNode = string.match(text, "node(%d+)")
	end
	if (not masterNode) then
		Ovale:Print("no master node")
		return nil
	end
	
	-- Si il reste autre chose que des espaces, c'est une erreur de syntaxe
	text = string.gsub(text, "node%d+", "", 1)
	if (string.match(text,"[^ ]")) then
		Ovale:Print("Group:"..original)
		Ovale:Print("syntax error:"..text)
		return nil
	end
	
	-- On convertit le numéro de node en node
	masterNode = node[tonumber(masterNode)]
	masterNode.params = ParseParameters(params)
	return masterNode
end

function Ovale:CompileInputs(text)
	self.casesACocher = {}
	self.listes = {}
	
	text = string.gsub(text, "AddListItem%s*%(%s*(%w+)%s+(%w+)%s+\"(.-)\"%s*%)", ParseAddListItem)
	text = string.gsub(text, "AddCheckBox%s*%(%s*(%w+)%s+\"(.-)\"%s*%)", ParseAddCheckBox)
	return text
end

local function ParseCanStopChannelling(text)
	local spell = Ovale:GetSpellInfoOrNil(text)
	if (spell) then
		Ovale.canStopChannelling[spell] = true
	else
		Ovale:Print("CanStopChannelling with unknown spell "..text)
	end
	return ""
end

local function ParseSpellName(text)
	local spell = Ovale:GetSpellInfoOrNil(text)
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

function Ovale:Compile(text)
	self.bug = false
	node = {}
	defines = {}
	
	-- Suppression des commentaires
	text = string.gsub(text, "#.-\n","")
	text = string.gsub(text, "#.*$","")

	-- Define(CONSTANTE valeur)
	text = string.gsub(text, "Define%s*%(%s*(%w+)%s+(%w+)%s*%)", ParseDefine)
	
	-- On remplace les constantes par leur valeur
	for k,v in pairs(defines) do
		text = string.gsub(text, "([^%w])"..k.."([^%w])", "%1"..v.."%2")
	end
	
	-- Fonctions
	text = string.gsub(text, "SpellName%s*%(%s*(%w+)%s*%)", ParseSpellName)
	text = string.gsub(text, "L%s*%(%s*(%w+)%s*%)", ParseL)
	
	-- Options diverses
	Ovale.canStopChannelling = {}
	text = string.gsub(text, "CanStopChannelling%s*%(%s*(%w+)%s*%)", ParseCanStopChannelling)
			
	-- On vire les espaces en trop
	text = string.gsub(text, "\n", " ")
	text = string.gsub(text, "%s+", " ")
	
	-- On compile les AddCheckBox et AddListItem
	text = self:CompileInputs(text)
	
	local masterNodes ={}
	
	-- On compile les AddIcon
	for p,t in string.gmatch(text, "AddIcon%s*(.-)%s*(%b{})") do
		masterNodes[#masterNodes+1] = ParseAddIcon(p,t)
	end
	return masterNodes
end

function Ovale:DebugNode(node)
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
	elseif (node.type == "and") then
		text = self:DebugNode(node.a).." and "..self:DebugNode(node.b)
	elseif (node.type == "or") then
		text = self:DebugNode(node.a).." or "..self:DebugNode(node.b)
	else
		text = "#unknown node type#"
	end
	
	return text
end