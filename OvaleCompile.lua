local node={}
local defines = {}

local function ParseFunction(func, params)
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

local function ParseOr(a,b)
	local newNode = {type="or", a=node[tonumber(a)], b=node[tonumber(b)]}
	node[#node+1] = newNode
	return "node"..#node
end

local function ParseGroup(text)
	text = string.gsub(text, "if%s+node(%d+)%s+node(%d+)",ParseIf)
	text = string.gsub(text, "unless%s+node(%d+)%s+node(%d+)",ParseUnless)
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

function Ovale:CompileInputs(text)
	self.casesACocher = {}
	self.listes = {}
	
	text = string.gsub(text, "AddListItem%s*%(%s*(%w+)%s+(%w+)%s+\"(.-)\"%s*%)", ParseAddListItem)
	text = string.gsub(text, "AddCheckBox%s*%(%s*(%w+)%s+\"(.-)\"%s*%)", ParseAddCheckBox)
	
	self:UpdateFrame()
	return text
end

function Ovale:Compile(text)
	self.bug = false
	node = {}
	defines = {}
	
	text = string.gsub(text, "#.-\n","")

	text = string.gsub(text, "Define%s*%(%s*(%w+)%s+(%w+)%s*%)", ParseDefine)
		
	for k,v in pairs(defines) do
		text = string.gsub(text, "([^%w])"..k.."([^%w])", "%1"..v.."%2")
	end
	
	text = self:CompileInputs(text)
	
	text = string.gsub(text, "\n", " ")
	text = string.gsub(text, "%s+", " ")
	
	text = string.gsub(text, "(%w+)%s*%((.-)%)", ParseFunction)
	text = subtest(text, "node(%d+)%s+and%s+node(%d+)", ParseAnd)
	text = subtest(text, "node(%d+)%s+or%s+node(%d+)", ParseOr)
	
	text = subtest(text, "{([^{}]*)}", ParseGroup)
	
	text = ParseGroup(text)
	local masterNode
	if (text) then
		masterNode = string.match(text, "node(%d+)")
	end
	if (not masterNode) then
		self:Print("no master node")
		return nil
	end
	text = string.gsub(text, "node%d+", "", 1)
	if (string.match(text,"[^ ]")) then
		self:Print("syntax error:"..text)
		return nil
	end
	masterNode = node[tonumber(masterNode)]
	return masterNode
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
		text = self:DebugNode(node.a).." and "..self:DebugNode(node.b)
	else
		text = "#unknown node type#"
	end
	
	return text
end