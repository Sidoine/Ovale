--[[--------------------------------------------------------------------
    Copyright (C) 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local _, Ovale = ...
local OvaleSimulationCraft = Ovale:NewModule("OvaleSimulationCraft")
Ovale.OvaleSimulationCraft = OvaleSimulationCraft

--<private-static-properties>
local OvalePool = Ovale.OvalePool

-- Forward declarations for module dependencies.
local OvaleAST = nil
local OvaleData = nil
local OvaleLexer = nil

local format = string.format
local gmatch = string.gmatch
local gsub = string.gsub
local strfind = string.find
local strlen = string.len
local strlower = string.lower
local strmatch = string.match
local strsub = string.sub
local strupper = string.upper
local tconcat = table.concat
local tinsert = table.insert
local tonumber = tonumber
local tostring = tostring
local tsort = table.sort
local yield = coroutine.yield

-- Keywords for SimulationCraft action lists.
local KEYWORD = {}

local MODIFIER_KEYWORD = {
	["chain"] = true,
	["choose"] = true,
	["cycle_targets"] = true,
	["damage"] = true,
	["early_chain_if"] = true,
	["extra_amount"] = true,
	["five_stacks"] = true,
	["for_next"] = true,
	["if"] = true,
	["interrupt"] = true,
	["interrupt_if"] = true,
	["lethal"] = true,
	["line_cd"] = true,
	["max_cycle_targets"] = true,
	["moving"] = true,
	["name"] = true,
	["sec"] = true,
	["slot"] = true,
	["sync"] = true,
	["sync_weapons"] = true,
	["target"] = true,
	["travel_speed"] = true,
	["type"] = true,
	["wait"] = true,
	["wait_on_ready"] = true,
	["weapon"] = true,
}

local FUNCTION_KEYWORD = {
	["ceil"] = true,
	["floor"] = true,
}

local SPECIAL_ACTION = {
	["apply_poison"] = true,
	["auto_attack"] = true,
	["cancel_buff"] = true,
	["cancel_metamorphosis"] = true,
	["flask"] = true,
	["food"] = true,
	["health_stone"] = true,
	["pool_resource"] = true,
	["run_action_list"] = true,
	["snapshot_stats"] = true,
	["stance"] = true,
	["start_moving"] = true,
	["stealth"] = true,
	["stop_moving"] = true,
	["swap_action_list"] = true,
	["use_item"] = true,
	["wait"] = true,
}

local RUNE_OPERAND = {
	["blood"] = "blood",
	["death"] = "death",
	["frost"] = "frost",
	["unholy"] = "unholy",
	["rune.blood"] = "blood",
	["rune.death"] = "death",
	["rune.frost"] = "frost",
	["rune.unholy"] = "unholy",
}

do
	-- All expression keywords are keywords.
	for keyword, value in pairs(MODIFIER_KEYWORD) do
		KEYWORD[keyword] = value
	end
	-- All function keywords are keywords.
	for keyword, value in pairs(FUNCTION_KEYWORD) do
		KEYWORD[keyword] = value
	end
	-- All special actions are keywords.
	for keyword, value in pairs(SPECIAL_ACTION) do
		KEYWORD[keyword] = value
	end
end

-- Table of pattern/tokenizer pairs for SimulationCraft action lists.
local MATCHES = nil

-- Unary and binary operators with precedence.
local UNARY_OPERATOR = {
	["!"] = { "logical", 15 },
	["-"]   = { "arithmetic", 50 },
}
local BINARY_OPERATOR = {
	-- logical
	["|"]  = { "logical", 5 },
	["&"] = { "logical", 10 },
	-- comparison
	["!="]  = { "compare", 20 },
	["<"]   = { "compare", 20 },
	["<="]  = { "compare", 20 },
	["="]  = { "compare", 20 },
	[">"]   = { "compare", 20 },
	[">="]  = { "compare", 20 },
	["~"] = { "compare", 20 },
	["!~"] = { "compare", 20 },
	-- addition, subtraction
	["+"]   = { "arithmetic", 30 },
	["-"]   = { "arithmetic", 30 },
	-- multiplication, division, modulus
	["%"]   = { "arithmetic", 40 },
	["*"]   = { "arithmetic", 40 },
	-- exponentiation
	["^"]   = { "arithmetic", 100 },
}

-- INDENT[k] is a string of k concatenated tabs.
local INDENT = {}
do
	INDENT[0] = ""
	local metatable = {
		__index = function(tbl, key)
			key = tonumber(key)
			if key > 0 then
				local s = tbl[key - 1] .. "\t"
				rawset(tbl, key, s)
				return s
			end
			return INDENT[0]
		end,
	}
	setmetatable(INDENT, metatable)
end

local EMIT_DISAMBIGUATION = {}
local EMIT_EXTRA_PARAMETERS = {}
local OPERAND_TOKEN_PATTERN = "[^.]+"

local TOTEM_TYPE = {
	["capacitor_totem"] = "air",
	["earth_elemental_totem"] = "earth",
	["earthbind_totem"] = "earth",
	["earthgrab_totem"] = "earth",
	["fire_elemental_totem"] = "fire",
	["grounding_totem"] = "air",
	["healing_stream_totem"] = "water",
	["healing_tide_totem"] = "water",
	["magma_totem"] = "fire",
	["mana_tide_totem"] = "water",
	["searing_totem"] = "fire",
	["stone_bulwark_totem"] = "earth",
	["stormlash_totem"] = "air",
	["tremor_totem"] = "earth",
	["windwalk_totem"] = "air",
}

local self_outputPool = OvalePool("OvaleSimulationCraft_outputPool")
local self_childrenPool = OvalePool("OvaleSimulationCraft_childrenPool")
local self_pool = OvalePool("OvaleSimulationCraft_pool")
do
	self_pool.Clean = function(self, node)
		if node.child then
			self_childrenPool:Release(node.child)
			node.child = nil
		end
	end
end
--</private-static-properties>

--<private-static-methods>
-- Implementation of PHP-like print_r() taken from http://lua-users.org/wiki/TableSerialization.
-- This is used to print out a table, but has been modified to print out an AST.
local function print_r(node, indent, done, output)
	done = done or {}
	output = output or {}
	indent = indent or ''
	for key, value in pairs(node) do
		if type(value) == "table" then
			if done[value] then
				tinsert(output, indent .. "[" .. tostring(key) .. "] => (self_reference)")
			else
				-- Shortcut conditional allocation
				done[value] = true
				tinsert(output, indent .. "[" .. tostring(key) .. "] => {")
				print_r(value, indent .. "    ", done, output)
				tinsert(output, indent .. "}")
			end
		else
			tinsert(output, indent .. "[" .. tostring(key) .. "] => " .. tostring(value))
		end
	end
	return output
end

-- Get a new node from the pool and save it in the nodes array.
local function NewNode(nodeList, hasChild)
	local node = self_pool:Get()
	if nodeList then
		local nodeId = #nodeList + 1
		node.nodeId = nodeId
		nodeList[nodeId] = node
	end
	if hasChild then
		node.child = self_childrenPool:Get()
	end
	return node
end

--[[---------------------------------------------
	Lexer functions (for use with OvaleLexer)
--]]---------------------------------------------
local function TokenizeName(token)
	if KEYWORD[token] then
		return yield("keyword", token)
	else
		return yield("name", token)
	end
end

local function TokenizeNumber(token, options)
	if options and options.number then
		token = tonumber(token)
	end
	return yield("number", token)
end

local function Tokenize(token)
	return yield(token, token)
end

local function NoToken()
	return yield(nil)
end

do
	MATCHES = {
		{ "^%d+%.?%d*", TokenizeNumber },
		{ "^[%a_][%w_]*[.:]?[%w_.]*", TokenizeName },
		{ "^!=", Tokenize },
		{ "^<=", Tokenize },
		{ "^>=", Tokenize },
		{ "^!~", Tokenize },
		{ "^.", Tokenize },
		{ "^$", NoToken },
	}
end

local function GetTokenIterator(s)
	local exclude = { space = false, comments = false }
	return OvaleLexer.scan(s, MATCHES, exclude)
end

--[[------------------------
	"Unparser" functions
--]]------------------------

-- Return the precedence of an operator in the given node.
-- Returns nil if the node is not an expression node.
local function GetPrecedence(node)
	local precedence = node.precedence
	if not precedence then
		local operator = node.operator
		if operator then
			if node.expressionType == "unary" and UNARY_OPERATOR[operator] then
				precedence = UNARY_OPERATOR[operator][2]
			elseif node.expressionType == "binary" and BINARY_OPERATOR[operator] then
				precedence = BINARY_OPERATOR[operator][2]
			end
		end
	end
	return precedence
end

local UNPARSE_VISITOR = nil

local function Unparse(node)
	local visitor = UNPARSE_VISITOR[node.type]
	if not visitor then
		Ovale:FormatPrint("Unable to unparse node of type '%s'.", node.type)
	else
		return visitor(node)
	end
end

local function UnparseAction(node)
	local output = self_outputPool:Get()
	output[#output + 1] = node.name
	for modifier, expressionNode in pairs(node.child) do
		output[#output + 1] = modifier .. "=" .. Unparse(expressionNode)
	end
	local s = tconcat(output, ",")
	self_outputPool:Release(output)
	return s
end

local function UnparseActionList(node)
	local output = self_outputPool:Get()
	local listName
	if node.name == "default" then
		listName = "action"
	else
		listName = "action." .. node.name
	end
	output[#output + 1] = ""
	for i, actionNode in pairs(node.child) do
		local operator = (i == 1) and "=" or "+=/"
		output[#output + 1] = listName .. operator .. Unparse(actionNode)
	end
	local s = tconcat(output, "\n")
	self_outputPool:Release(output)
	return s
end

local function UnparseExpression(node)
	local expression
	local precedence = GetPrecedence(node)
	if node.expressionType == "unary" then
		local rhsExpression
		local rhsNode = node.child[1]
		local rhsPrecedence = GetPrecedence(rhsNode)
		if rhsPrecedence and precedence >= rhsPrecedence then
			rhsExpression = "(" .. Unparse(rhsNode) .. ")"
		else
			rhsExpression = Unparse(rhsNode)
		end
		expression = node.operator .. rhsExpression
	elseif node.expressionType == "binary" then
		local lhsExpression, rhsExpression
		local lhsNode = node.child[1]
		local lhsPrecedence = GetPrecedence(lhsNode)
		if lhsPrecedence and lhsPrecedence < precedence then
			lhsExpression = "(" .. Unparse(lhsNode) .. ")"
		else
			lhsExpression = Unparse(lhsNode)
		end
		local rhsNode = node.child[2]
		local rhsPrecedence = GetPrecedence(rhsNode)
		if rhsPrecedence and precedence > rhsPrecedence then
			rhsExpression = "(" .. Unparse(rhsNode) .. ")"
		elseif rhsPrecedence and precedence == rhsPrecedence and node.operator ~= rhsNode.operator then
			rhsExpression = "(" .. Unparse(rhsNode) .. ")"
		else
			rhsExpression = Unparse(rhsNode)
		end
		expression = lhsExpression .. node.operator .. rhsExpression
	end
	return expression
end

local function UnparseFunction(node)
	return node.name .. "(" .. Unparse(node.child[1]) .. ")"
end

local function UnparseNumber(node)
	return tostring(node.value)
end

local function UnparseOperand(node)
	return node.name
end

do
	UNPARSE_VISITOR = {
		["action"] = UnparseAction,
		["action_list"] = UnparseActionList,
		["arithmetic"] = UnparseExpression,
		["compare"] = UnparseExpression,
		["function"] = UnparseFunction,
		["logical"] = UnparseExpression,
		["number"] = UnparseNumber,
		["operand"] = UnparseOperand,
	}
end

--[[--------------------
	Parser functions
--]]--------------------

-- Prints the error message and the next 20 tokens from tokenStream.
local function SyntaxError(tokenStream, ...)
	Ovale:FormatPrint(...)
	local context = { "Next tokens:" }
	for i = 1, 20 do
		local tokenType, token = tokenStream:Peek(i)
		if tokenType then
			context[#context + 1] = token
		else
			context[#context + 1] = "<EOS>"
			break
		end
	end
	Ovale:Print(tconcat(context, " "))
end

-- Left-rotate tree to preserve precedence.
local function LeftRotateTree(node)
	local rhsNode = node.child[2]
	while node.type == rhsNode.type and node.operator == rhsNode.operator and rhsNode.expressionType == "binary" do
		node.child[2] = rhsNode.child[1]
		rhsNode.child[1] = node
		node = rhsNode
		rhsNode = node.child[2]
	end
	return node
end

-- Forward declarations of parser functions needed to implement a recursive descent parser.
local ParseAction = nil
local ParseActionList = nil
local ParseExpression = nil
local ParseFunction = nil
local ParseModifier = nil
local ParseNumber = nil
local ParseOperand = nil
local ParseParentheses = nil
local ParseSimpleExpression = nil

local function TicksRemainTranslationHelper(p1, p2, p3, p4)
	if p4 then
		return p1 .. p2 .. "<" .. tostring(tonumber(p4) + 1)
	else
		return p1 .. "<" .. tostring(tonumber(p3) + 1)
	end
end

ParseAction = function(action, nodeList, annotation)
	local ok = true
	local stream = action
	do
		-- Changes to SimulationCraft action lists for easier translation into Ovale timespan concept.
		-- "cooldown_remains=0" into "!(cooldown_remains>0)"
		stream = gsub(stream, "([^_%.])(cooldown_remains)=0", "%1!(%2>0)")
		stream = gsub(stream, "([a-z_%.]+%.cooldown_remains)=0", "!(%1>0)")
		-- "remains=0" into "!(remains>0)"
		stream = gsub(stream, "([^_%.])(remains)=0", "%1!(%2>0)")
		stream = gsub(stream, "([a-z_%.]+%.remains)=0", "!(%1>0)")
		-- "ticks_remain=1" into "ticks_remain<2"
		-- "ticks_remain<=N" into "ticks_remain<N+1"
		stream = gsub(stream, "([^_%.])(ticks_remain)(<?=)([0-9]+)", TicksRemainTranslationHelper)
		stream = gsub(stream, "([a-z_%.]+%.ticks_remain)(<?=)([0-9]+)", TicksRemainTranslationHelper)
	end
	local tokenStream = OvaleLexer("SimulationCraft", GetTokenIterator(stream))
	-- Consume the action.
	local name
	do
		local tokenType, token = tokenStream:Consume()
		if (tokenType == "keyword" and SPECIAL_ACTION[token]) or tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line; name or special action expected.", token)
			ok = false
		end
	end
	local child = self_childrenPool:Get()
	if ok then
		local tokenType, token = tokenStream:Peek()
		while ok and tokenType do
			if tokenType == "," then
				-- Consume the ',' token.
				tokenStream:Consume()
				local modifier, expressionNode
				ok, modifier, expressionNode = ParseModifier(tokenStream, nodeList, annotation)
				if ok then
					child[modifier] = expressionNode
					tokenType, token = tokenStream:Peek()
				end
			else
				SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line; ',' expected.", token)
				ok = false
			end
		end
	end
	local node
	if ok then
		node = NewNode(nodeList)
		node.type = "action"
		node.action = action
		node.name = name
		node.child = child
	else
		self_childrenPool:Release(child)
	end
	return ok, node
end

ParseActionList = function(name, actionList, nodeList, annotation)
	local ok = true
	local child = self_childrenPool:Get()
	for action in gmatch(actionList, "[^/]+") do
		local actionNode
		ok, actionNode = ParseAction(action, nodeList, annotation)
		if ok then
			child[#child + 1] = actionNode
		else
			break
		end
	end
	local node
	if ok then
		node = NewNode(nodeList)
		node.type = "action_list"
		node.name = name
		node.child = child
	else
		self_childrenPool:Release(child)
	end
	return ok, node
end

--[[
	Operator-precedence parser for logical and arithmetic expressions.
	Implementation taken from Wikipedia:
		http://en.wikipedia.org/wiki/Operator-precedence_parser
--]]
ParseExpression = function(tokenStream, nodeList, annotation, minPrecedence)
	minPrecedence = minPrecedence or 0
	local ok = true
	local node

	-- Check for unary operator expressions first as they decorate the underlying expression.
	do
		local tokenType, token = tokenStream:Peek()
		if tokenType then
			local opInfo = UNARY_OPERATOR[token]
			if opInfo then
				local opType, precedence = opInfo[1], opInfo[2]
				local asType = (opType == "logical") and "boolean" or "value"
				tokenStream:Consume()
				local operator = token
				local rhsNode
				ok, rhsNode = ParseExpression(tokenStream, nodeList, annotation, precedence)
				if ok then
					if operator == "-" and rhsNode.type == "number" then
						-- Elide the unary negation operator into the number.
						rhsNode.value = -1 * rhsNode.value
						node = rhsNode
					else
						node = NewNode(nodeList, true)
						node.type = opType
						node.expressionType = "unary"
						node.operator = operator
						node.precedence = precedence
						node.child[1] = rhsNode
						rhsNode.asType = asType
					end
				end
			else
				ok, node = ParseSimpleExpression(tokenStream, nodeList, annotation)
				node.asType = "boolean"
			end
		end
	end

	-- Peek at the next token to see if it is a binary operator.
	while ok do
		local keepScanning = false
		local tokenType, token = tokenStream:Peek()
		if tokenType then
			local opInfo = BINARY_OPERATOR[token]
			if opInfo then
				local opType, precedence = opInfo[1], opInfo[2]
				local asType = (opType == "logical") and "boolean" or "value"
				if precedence and precedence > minPrecedence then
					keepScanning = true
					tokenStream:Consume()
					local operator = token
					local lhsNode = node
					local rhsNode
					ok, rhsNode = ParseExpression(tokenStream, nodeList, annotation, precedence)
					if ok then
						node = NewNode(nodeList, true)
						node.type = opType
						node.expressionType = "binary"
						node.operator = operator
						node.precedence = precedence
						node.child[1] = lhsNode
						node.child[2] = rhsNode
						lhsNode.asType = asType
						rhsNode.asType = asType
						-- Left-rotate tree to preserve precedence.
						node = LeftRotateTree(node)
					end
				end
			end
		end
		if not keepScanning then
			break
		end
	end

	return ok, node
end

ParseFunction = function(tokenStream, nodeList, annotation)
	local ok = true
	local name
	-- Consume the name.
	do
		local tokenType, token = tokenStream:Consume()
		if tokenType == "keyword" and FUNCTION_KEYWORD[token] then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token)
			ok = false
		end
	end
	-- Consume the left parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "(" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; '(' expected.", token)
			ok = false
		end
	end
	-- Consume the function argument.
	local argumentNode
	if ok then
		ok, argumentNode = ParseExpression(tokenStream, nodeList, annotation)
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= ")" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = NewNode(nodeList, true)
		node.type = "function"
		node.name = name
		node.child[1] = argumentNode
	end
	return ok, node
end

ParseModifier = function(tokenStream, nodeList, annotation)
	local ok = true
	local name
	do
		local tokenType, token = tokenStream:Consume()
		if tokenType == "keyword" and MODIFIER_KEYWORD[token] then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line; expression keyword expected.", token)
			ok = false
		end
	end
	if ok then
		-- Consume the '=' token.
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "=" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line; '=' expected.", token)
			ok = false
		end
	end
	local expressionNode
	if ok then
		ok, expressionNode = ParseExpression(tokenStream, nodeList, annotation)
	end
	return ok, name, expressionNode
end

ParseNumber = function(tokenStream, nodeList, annotation)
	local ok = true
	local value
	-- Consume the number.
	do
		local tokenType, token = tokenStream:Consume()
		if tokenType == "number" then
			value = tonumber(token)
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing NUMBER; number expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = NewNode(nodeList)
		node.type = "number"
		node.value = value
	end
	return ok, node
end

ParseOperand = function(tokenStream, nodeList, annotation)
	local ok = true
	local name
	-- Consume the operand.
	do
		local tokenType, token = tokenStream:Consume()
		if tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing OPERAND; operand expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = NewNode(nodeList)
		node.type = "operand"
		node.name = name
		if RUNE_OPERAND[name] then
			node.rune = RUNE_OPERAND[name]
		end
		annotation.operand = annotation.operand or {}
		annotation.operand[#annotation.operand + 1] = node
	end
	return ok, node
end

ParseParentheses = function(tokenStream, nodeList, annotation)
	local ok = true
	local leftToken, rightToken
	-- Consume the left parenthesis.
	do
		local tokenType, token = tokenStream:Consume()
		if tokenType == "(" then
			leftToken, rightToken = "(", ")"
		elseif tokenType == "{" then
			leftToken, rightToken = "{", "}"
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '(' or '{' expected.", token)
			ok = false
		end
	end
	-- Consume the inner expression.
	local node
	if ok then
		ok, node = ParseExpression(tokenStream, nodeList, annotation)
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= rightToken then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '%s' expected.", token, rightToken)
			ok = false
		end
	end
	-- Create the AST node.
	if ok then
		node.left = leftToken
		node.right = rightToken
	end
	return ok, node
end

ParseSimpleExpression = function(tokenStream, nodeList, annotation)
	local ok = true
	local node
	local tokenType, token = tokenStream:Peek()
	if tokenType == "number" then
		ok, node = ParseNumber(tokenStream, nodeList, annotation)
	elseif tokenType == "keyword" and FUNCTION_KEYWORD[token] then
		ok, node = ParseFunction(tokenStream, nodeList, annotation)
	elseif tokenType == "name" then
		ok, node = ParseOperand(tokenStream, nodeList, annotation)
	elseif tokenType == "(" then
		ok, node = ParseParentheses(tokenStream, nodeList, annotation)
	else
		SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION", token)
		tokenStream:Consume()
		ok = false
	end
	return ok, node
end

--[[-----------------------------
	Code generation functions
--]]-----------------------------

local CamelCase = nil
do
	local function CamelCaseHelper(first, rest)
		return strupper(first) .. strlower(rest)
	end

	CamelCase = function(s)
		local tc = gsub(s, "(%a)(%w*)", CamelCaseHelper)
		return gsub(tc, "[%s_]", "")
	end
end

local function OvaleFunctionName(name, class, spec)
	local functionName
	if spec then
		functionName = CamelCase(spec .. " " .. name) .. "Actions"
	else
		functionName = CamelCase(name) .. "Actions"
	end
	return functionName
end

local function AddSymbol(annotation, symbol)
	local symbolTable = annotation.symbolTable or {}
	-- Add the symbol to the table if it's not already present and it's not a globally-defined spell list name.
	if not symbolTable[symbol] and not OvaleData.buffSpellList[symbol] then
		symbolTable[symbol] = true
		symbolTable[#symbolTable + 1] = symbol
	end
	annotation.symbolTable = symbolTable
end

local function AddPerClassSpecialization(tbl, name, info, class, specialization)
	class = class or "ALL_CLASSES"
	specialization = specialization or "ALL_SPECIALIZATIONS"
	tbl[class] = tbl[class] or {}
	tbl[class][specialization] = tbl[class][specialization] or {}
	tbl[class][specialization][name] = info
end

local function GetPerClassSpecialization(tbl, name, class, specialization)
	local info
	while not info do
		while not info do
			if tbl[class] and tbl[class][specialization] and tbl[class][specialization][name] then
				info = tbl[class][specialization][name]
			end
			if specialization ~= "ALL_SPECIALIZATIONS" then
				specialization = "ALL_SPECIALIZATIONS"
			else
				break
			end
		end
		if class ~= "ALL_CLASSES" then
			class = "ALL_CLASSES"
		else
			break
		end
	end
	return info
end

local function AddDisambiguation(name, info, class, specialization)
	AddPerClassSpecialization(EMIT_DISAMBIGUATION, name, info, class, specialization)
end

local function Disambiguate(name, class, specialization)
	return GetPerClassSpecialization(EMIT_DISAMBIGUATION, name, class, specialization) or name
end

local function InitializeDisambiguation()
	AddDisambiguation("bloodlust_buff",	"burst_haste_buff")
	AddDisambiguation("vicious_buff",	"trinket_proc_agility_buff")
	-- Death Knight
	AddDisambiguation("arcane_torrent",	"arcane_torrent_runicpower",	"DEATHKNIGHT")
	AddDisambiguation("blood_fury",		"blood_fury_ap",				"DEATHKNIGHT")
	AddDisambiguation("soul_reaper",	"soul_reaper_blood",			"DEATHKNIGHT", "blood")
	AddDisambiguation("soul_reaper",	"soul_reaper_frost",			"DEATHKNIGHT", "frost")
	AddDisambiguation("soul_reaper",	"soul_reaper_unholy",			"DEATHKNIGHT", "unholy")
	-- Druid
	AddDisambiguation("arcane_torrent",		"arcane_torrent_energy",	"DRUID")
	AddDisambiguation("berserk",			"berserk_bear",				"DRUID", "guardian")
	AddDisambiguation("berserk",			"berserk_cat",				"DRUID", "feral")
	AddDisambiguation("blood_fury",			"blood_fury_apsp",			"DRUID")
	AddDisambiguation("dream_of_cenarius",	"dream_of_cenarius_caster",	"DRUID", "balance")
	AddDisambiguation("dream_of_cenarius",	"dream_of_cenarius_melee",	"DRUID", "feral")
	AddDisambiguation("force_of_nature",	"force_of_nature_caster",	"DRUID", "balance")
	AddDisambiguation("force_of_nature",	"force_of_nature_heal",		"DRUID", "restoration")
	AddDisambiguation("force_of_nature",	"force_of_nature_melee",	"DRUID", "feral")
	AddDisambiguation("incarnation",		"incarnation_caster",		"DRUID", "balance")
	AddDisambiguation("incarnation",		"incarnation_heal",			"DRUID", "restoration")
	AddDisambiguation("incarnation",		"incarnation_melee",		"DRUID", "feral")
	AddDisambiguation("incarnation",		"incarnation_tank",			"DRUID", "guardian")
	AddDisambiguation("heart_of_the_wild",	"heart_of_the_wild_caster",	"DRUID", "balance")
	AddDisambiguation("heart_of_the_wild",	"heart_of_the_wild_heal",	"DRUID", "restoration")
	AddDisambiguation("heart_of_the_wild",	"heart_of_the_wild_melee",	"DRUID", "feral")
	AddDisambiguation("omen_of_clarity",	"omen_of_clarity_heal",		"DRUID", "restoration")
	AddDisambiguation("omen_of_clarity",	"omen_of_clarity_melee",	"DRUID", "feral")
	AddDisambiguation("stealth",			"prowl",					"DRUID")
	AddDisambiguation("wild_mushroom",		"wild_mushroom_caster",		"DRUID", "balance")
	AddDisambiguation("wild_mushroom",		"wild_mushroom_heal",		"DRUID", "restoration")
	-- Hunter
	AddDisambiguation("arcane_torrent",		"arcane_torrent_focus",	"HUNTER")
	AddDisambiguation("blood_fury",			"blood_fury_ap",		"HUNTER")
	-- Mage
	AddDisambiguation("alter_time_activate",	"alter_time",			"MAGE")
	AddDisambiguation("arcane_torrent",			"arcane_torrent_mana",	"MAGE")
	AddDisambiguation("arcane_charge_buff",		"arcane_charge_debuff",	"MAGE", "arcane")
	AddDisambiguation("blood_fury",				"blood_fury_sp",		"MAGE")
	-- Monk
	AddDisambiguation("arcane_torrent",		"arcane_torrent_chi",	"MONK")
	AddDisambiguation("blood_fury",			"blood_fury_apsp",		"MONK")
	AddDisambiguation("zen_sphere_debuff",	"zen_sphere_buff",		"MONK")
	-- Paladin
	AddDisambiguation("arcane_torrent",				"arcane_torrent_mana",				"PALADIN")
	AddDisambiguation("blood_fury",					"blood_fury_apsp",					"PALADIN")
	AddDisambiguation("guardian_of_ancient_kings",	"guardian_of_ancient_kings_heal",	"PALADIN", "holy")
	AddDisambiguation("guardian_of_ancient_kings",	"guardian_of_ancient_kings_melee",	"PALADIN", "retribution")
	AddDisambiguation("guardian_of_ancient_kings",	"guardian_of_ancient_kings_tank",	"PALADIN", "protection")
	AddDisambiguation("sacred_shield_debuff",		"sacred_shield_buff",				"PALADIN")
	-- Priest
	AddDisambiguation("arcane_torrent",			"arcane_torrent_mana",	"PRIEST")
	AddDisambiguation("blood_fury",				"blood_fury_sp",		"PRIEST")
	AddDisambiguation("devouring_plague_tick",	"devouring_plague",		"PRIEST")
	AddDisambiguation("mind_flay_insanity",		"mind_flay",			"PRIEST")
	-- Rogue
	AddDisambiguation("arcane_torrent",	"arcane_torrent_energy",	"ROGUE")
	AddDisambiguation("blood_fury",		"blood_fury_ap",			"ROGUE")
	AddDisambiguation("stealth_buff",	"stealthed_buff",			"ROGUE")
	-- Shaman
	AddDisambiguation("arcane_torrent",	"arcane_torrent_mana",	"SHAMAN")
	AddDisambiguation("ascendance",		"ascendance_caster",	"SHAMAN", "elemental")
	AddDisambiguation("ascendance",		"ascendance_heal",		"SHAMAN", "restoration")
	AddDisambiguation("ascendance",		"ascendance_melee",		"SHAMAN", "enhancement")
	AddDisambiguation("blood_fury",		"blood_fury_apsp",		"SHAMAN")
	-- Warlock
	AddDisambiguation("arcane_torrent",	"arcane_torrent_mana",		"WARLOCK")
	AddDisambiguation("blood_fury",		"blood_fury_sp",			"WARLOCK")
	AddDisambiguation("dark_soul",		"dark_soul_instability",	"WARLOCK", "destruction")
	AddDisambiguation("dark_soul",		"dark_soul_knowledge",		"WARLOCK", "demonology")
	AddDisambiguation("dark_soul",		"dark_soul_misery",			"WARLOCK", "affliction")
	AddDisambiguation("rain_of_fire",	"rain_of_fire_aftermath",	"WARLOCK", "destruction")
	-- Warrior
	AddDisambiguation("arcane_torrent",		"arcane_torrent_rage",			"WARRIOR")
	AddDisambiguation("blood_fury",			"blood_fury_ap",				"WARRIOR")
	AddDisambiguation("cooldown_reduction",	"cooldown_reduction_strength",	"WARRIOR", "arms")
	AddDisambiguation("cooldown_reduction",	"cooldown_reduction_strength",	"WARRIOR", "fury")
end

local EMIT_VISITOR = nil
-- Forward declarations of code generation functions.
local Emit = nil
local EmitAction = nil
local EmitActionList = nil
local EmitExpression = nil
local EmitFunction = nil
local EmitModifier = nil
local EmitNumber = nil
local EmitOperand = nil
local EmitOperandAction = nil
local EmitOperandBuff = nil
local EmitOperandCharacter = nil
local EmitOperandCooldown = nil
local EmitOperandDot = nil
local EmitOperandGlyph = nil
local EmitOperandTalent = nil
local EmitOperandTotem = nil

Emit = function(parseNode, nodeList, annotation, action)
	local visitor = EMIT_VISITOR[parseNode.type]
	if not visitor then
		Ovale:FormatPrint("Unable to emit node of type '%s'.", parseNode.type)
	else
		return visitor(parseNode, nodeList, annotation, action)
	end
end

EmitAction = function(parseNode, nodeList, annotation)
	local node
	local canonicalizedName = gsub(parseNode.name, ":", "_")
	local class = annotation.class
	local specialization = annotation.specialization
	local action = Disambiguate(canonicalizedName, class, specialization)

	if action == "auto_attack" or action == "auto_shot" then
		-- skip
	elseif action == "elixir" or action == "flask" or action == "food" then
		-- skip
	elseif action == "snapshot_stats" then
		-- skip
	else
		local bodyNode, conditionNode
		local bodyCode, conditionCode
		local expressionType = "expression"
		local modifier = parseNode.child
		local isSpellAction = true
		if class == "DEATHKNIGHT" and action == "blood_tap" then
			-- Blood Tap requires a minimum of five stacks of Blood Charge to be on the player.
			local buffName = "blood_charge_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffStacks(%s) >= 5", buffName)
		elseif class == "DEATHKNIGHT" and action == "dark_transformation" then
			-- Dark Transformation requires a five stacks of Shadow Infusion to be on the player/pet.
			local buffName = "shadow_infusion_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffStacks(%s) >= 5", buffName)
		elseif class == "DEATHKNIGHT" and action == "mind_freeze" then
			bodyCode = "InterruptActions()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "DEATHKNIGHT" and action == "plague_leech" then
			-- Plague Leech requires both Blood Plague and Frost Fever to exist on the target.
			AddSymbol(annotation, "blood_plague_debuff")
			AddSymbol(annotation, "frost_fever_debuff")
			conditionCode = "target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff)"
		elseif class == "DRUID" and action == "faerie_fire" then
			bodyCode = "FaerieFire()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "DRUID" and action == "prowl" then
			-- Don't Prowl if already stealthed.
			conditionCode = "BuffExpires(stealthed_buff any=1)"
		elseif class == "DRUID" and action == "ravage" then
			-- Ravage requires stealth.
			conditionCode = "BuffPresent(stealthed_buff any=1)"
		elseif class == "DRUID" and action == "savage_roar" then
			bodyCode = "SavageRoar()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "DRUID" and (action == "skull_bash_bear" or action == "skull_bash_cat") then
			bodyCode = "InterruptActions()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "HUNTER" and action == "aspect_of_the_hawk" then
			bodyCode = "AspectOfTheHawk()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "HUNTER" and action == "explosive_trap" then
			-- Glyph of Explosive Trap removes the damage component from Explosive Trap.
			local glyphName = "glyph_of_explosive_trap"
			AddSymbol(annotation, glyphName)
			annotation.trap_launcher = class
			conditionCode = format("CheckBoxOn(opt_trap_launcher) and Glyph(%s no)", glyphName)
		elseif class == "HUNTER" and action == "focus_fire" then
			-- Focus Fire requires at least one stack of Frenzy.
			local buffName = "frenzy_buff"
			AddSymbol(annotation, buffName)
			if modifier.five_stacks then
				local value = tonumber(Unparse(modifier.five_stacks))
				if value == 1 then
					conditionCode = format("BuffStacks(%s any=1) == 5", buffName)
				end
			end
			if not conditionCode then
				conditionCode = format("BuffPresent(%s any=1)", buffName)
			end
		elseif class == "HUNTER" and action == "kill_command" then
			-- Kill Command requires that a pet that can move freely.
			conditionCode = "pet.Present() and pet.IsIncapacitated(no) and pet.IsFeared(no) and pet.IsStunned(no)"
		elseif class == "HUNTER" and action == "kill_shot" then
			-- Kill Shot can only be used on targets below 20% health.
			conditionCode = "target.HealthPercent() < 20"
		elseif class == "HUNTER" and strsub(action, -5) == "_trap" then
			annotation.trap_launcher = class
			conditionCode = "CheckBoxOn(opt_trap_launcher)"
		elseif class == "MAGE" and strsub(action, -6) == "_armor" then
			local buffName = action .. "_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffExpires(%s)", buffName)
		elseif class == "MAGE" and action == "arcane_brilliance" then
			-- Only cast Arcane Brilliance if not already raid-buffed.
			conditionCode = "BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1)"
		elseif class == "MAGE" and action == "arcane_missiles" then
			-- Arcane Missiles can only be fired if the Arcane Missiles! buff is present.
			local buffName = "arcane_missiles_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffPresent(%s)", buffName)
		elseif class == "MAGE" and action == "cancel_buff" then
			-- Only cancel Alter Time if "moving" is not one of the modifier conditions.
			-- It is assumed the player knows to cancel Alter Time to prevent teleport-death.
			if modifier.name and not modifier.moving then
				local name = Unparse(modifier.name)
				if name == "alter_time" then
					bodyCode = "Texture(spell_mage_altertime text=cancel)"
				end
			end
			isSpellAction = false
		elseif class == "MAGE" and action == "conjure_mana_gem" then
			bodyCode = "ConjureManaGem()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "MAGE" and action == "counterspell" then
			bodyCode = "InterruptActions()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "MAGE" and action == "ice_floes" then
			-- skip
			isSpellAction = false
		elseif class == "MAGE" and action == "icy_veins" then
			bodyCode = "IcyVeins()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "MAGE" and action == "mana_gem" then
			bodyCode = "UseManaGem()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "MAGE" and action == "start_pyro_chain" then
			bodyCode = "SetState(pyro_chain 1)"
			isSpellAction = false
		elseif class == "MAGE" and action == "stop_pyro_chain" then
			bodyCode = "SetState(pyro_chain 0)"
			isSpellAction = false
		elseif class == "MAGE" and action == "time_warp" then
			-- Only suggest Time Warp if it will have an effect.
			conditionCode = "CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1)"
			annotation[action] = class
		elseif class == "MAGE" and action == "water_elemental" then
			-- Only suggest summoning the Water Elemental if the pet is not already summoned.
			conditionCode = "pet.Present(no)"
		elseif class == "MONK" and action == "chi_sphere" then
			-- skip
			isSpellAction = false
		elseif class == "PALADIN" and action == "blessing_of_kings" then
			-- Only cast Blessing of Kings if it won't overwrite the player's own Blessing of Might.
			conditionCode = "BuffExpires(mastery_buff)"
		elseif class == "PALADIN" and action == "consecration" then
			bodyCode = "Consecration()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "PALADIN" and action == "exorcism" then
			bodyCode = "Exorcism()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "PALADIN" and action == "hammer_of_wrath" then
			-- Hammer of Wrath can only be cast on targets below 20% health.
			conditionCode = "target.HealthPercent() < 20"
			-- Retribution paladins can also cast Hammer of Wrath if Avenging Wrath is up.
			if specialization == "retribution" then
				local buffName = "avenging_wrath_buff"
				AddSymbol(annotation, buffName)
				conditionCode = format("%s or BuffPresent(%s)", conditionCode, buffName)
			end
		elseif class == "PALADIN" and action == "rebuke" then
			bodyCode = "InterruptActions()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "PRIEST" and action == "inner_fire" then
			local buffName = action .. "_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffExpires(%s)", buffName)
		elseif class == "PRIEST" and canonicalizedName == "mind_flay_insanity" then
			-- Mind Flay: Insanity requires Devouring Plague to be present on the target.
			local talentName = "solace_and_insanity_talent"
			local debuffName = "devouring_plague_debuff"
			AddSymbol(annotation, talentName)
			AddSymbol(annotation, debuffName)
			conditionCode = format("Talent(%s) and target.DebuffPresent(%s)", talentName, debuffName)
		elseif class == "PRIEST" and action == "shadow_word_death" then
			-- Shadow Word: Death needs to be glyphed or else it can only be cast on targets below 20% health.
			local glyphName = "glyph_of_shadow_word_death"
			AddSymbol(annotation, glyphName)
			conditionCode = format("Glyph(%s) or target.HealthPercent() < 20", glyphName)
		elseif class == "PRIEST" and action == "silence" then
			bodyCode = "InterruptActions()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "ROGUE" and action == "ambush" then
			-- Ambush requires stealth or the 4pT16 proc.
			if specialization == "subtlety" then
				local buffName = "sleight_of_hand_buff"
				AddSymbol(annotation, buffName)
				conditionCode = format("BuffPresent(stealthed_buff any=1) or BuffPresent(%s)", buffName)
			else
				conditionCode = "BuffPresent(stealthed_buff any=1)"
			end
		elseif class == "ROGUE" and action == "apply_poison" then
			if modifier.lethal then
				local name = Unparse(modifier.lethal)
				action = name .. "_poison"
				-- Always have at least 20 minutes of a lethal poison applied when out of combat.
				local buffName = "lethal_poison_buff"
				AddSymbol(annotation, buffName)
				conditionCode = format("BuffRemaining(%s) < 1200", buffName)
			else
				isSpellAction = false
			end
		elseif class == "ROGUE" and (action == "cheap_shot" or action == "premeditation") then
			-- Cheap Shot and Premeditation require stealth.
			conditionCode = "BuffPresent(stealthed_buff any=1)"
		elseif class == "ROGUE" and action == "dispatch" then
			-- Dispatch requires a Blindside proc or else it can only be cast on targets below 35% health.
			local buffName = "blindside_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("target.HealthPercent() < 35 or BuffPresent(%s)", buffName)
		elseif class == "ROGUE" and action == "kick" then
			bodyCode = "InterruptActions()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "ROGUE" and action == "slice_and_dice" then
			-- The game does not prevent the player from overwriting a longer Slice and Dice buff with a shorter one.
			local buffName = "slice_and_dice_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffDurationIfApplied(%s) > BuffRemaining(%s)", buffName, buffName)
		elseif class == "ROGUE" and action == "stealth" then
			-- Don't Stealth if already stealthed.
			conditionCode = "BuffExpires(stealthed_buff any=1)"
			bodyCode = "Stealth()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "ROGUE" and action == "tricks_of_the_trade" then
			-- Only suggest Tricks of the Trade if not glyphed.
			local glyphName = "glyph_of_tricks_of_the_trade"
			AddSymbol(annotation, glyphName)
			annotation[action] = class
			conditionCode = format("CheckBoxOn(opt_tricks_of_the_trade) and Glyph(%s no)", glyphName)
		elseif class == "SHAMAN" and strsub(action, -7) == "_weapon" then
			if modifier.weapon then
				local weapon = Unparse(modifier.weapon)
				conditionCode = format("WeaponEnchantExpires(%s)", weapon)
			else
				isSpellAction = false
			end
		elseif class == "SHAMAN" and action == "bloodlust" then
			bodyCode = "Bloodlust()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "SHAMAN" and action == "lava_beam" then
			-- Lava Beam is the elemental Ascendance version of Chain Lightning.
			local buffName = "ascendance_caster_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffPresent(%s)", buffName)
		elseif class == "SHAMAN" and action == "magma_totem" then
			-- Only suggest Magma Totem if within melee range of the target.
			local spellName = "primal_strike"
			AddSymbol(annotation, spellName)
			conditionCode = format("target.InRange(%s)", spellName)
		elseif class == "SHAMAN" and action == "stormblast" then
			-- Stormblast is the enhancement Ascendance version of Stormstrike.
			local buffName = "ascendance_melee_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffPresent(%s)", buffName)
		elseif class == "SHAMAN" and action == "stormstrike" then
			-- Only suggest Stormstrike if Ascendance isn't active.
			local buffName = "ascendance_melee_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffExpires(%s)", buffName)
		elseif class == "SHAMAN" and action == "wind_shear" then
			bodyCode = "InterruptActions()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "WARLOCK" and action == "cancel_metamorphosis" then
			bodyCode = "Texture(spell_shadow_demonform text=cancel)"
			isSpellAction = false
		elseif class == "WARLOCK" and action == "felguard_felstorm" then
			conditionCode = "pet.Present() and pet.CreatureFamily(Felguard)"
		elseif class == "WARLOCK" and action == "grimoire_of_sacrifice" then
			-- Grimoire of Sacrifice requires a pet to already be summoned.
			conditionCode = "pet.Present()"
		elseif class == "WARLOCK" and action == "service_pet" then
			if annotation.pet then
				local spellName = "grimoire_" .. annotation.pet
				AddSymbol(annotation, spellName)
				bodyCode = format("Spell(%s)", spellName)
			else
				bodyCode = "Texture(spell_nature_removecurse help=ServicePet)"
			end
			isSpellAction = false
		elseif class == "WARLOCK" and action == "shadowburn" then
			-- Shadowburn can only be cast on targets below 20% health.
			conditionCode = "target.HealthPercent() < 20"
		elseif class == "WARLOCK" and action == "summon_pet" then
			if annotation.pet then
				local spellName = "summon_" .. annotation.pet
				AddSymbol(annotation, spellName)
				bodyCode = format("Spell(%s)", spellName)
			else
				bodyCode = "Texture(spell_nature_removecurse help=L(summon_pet))"
			end
			-- Only summon a pet if one is not already summoned.
			conditionCode = "pet.Present(no)"
			isSpellAction = false
		elseif class == "WARLOCK" and action == "wrathguard_wrathstorm" then
			conditionCode = "pet.Present() and pet.CreatureFamily(Wrathguard)"
		elseif class == "WARRIOR" and action == "execute" then
			-- Execute requires the 4pT16 DPS proc or else it can only be cast on targets below 20% health.
			local buffName = "death_sentence_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffPresent(%s) or target.HealthPercent() < 20", buffName)
		elseif class == "WARRIOR" and action == "heroic_leap" then
			annotation[action] = class
			conditionCode = "CheckBoxOn(opt_heroic_leap_dps)"
		elseif class == "WARRIOR" and (action == "impending_victory" or action == "victory_rush") then
			-- Impending Victory and Victory Rush requires the Victorious buff to be on the player.
			local buffName = "victorious_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffPresent(%s)", buffName)
		elseif class == "WARRIOR" and action == "raging_blow" then
			-- Raging Blow can only be used if the Raging Blow buff is present on the player.
			local buffName = "raging_blow_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffPresent(%s)", buffName)
		elseif class == "WARRIOR" and action == "skull_banner" then
			-- Only suggest Skull Banner if the checkbox option is selected.
			conditionCode = "CheckBoxOn(opt_skull_banner)"
			annotation[action] = class
		elseif (class == "DEATHKNIGHT" and strsub(action, -9) == "_presence")
				or (class == "DRUID" and strsub(action, -5) == "_form")
				or (class == "HUNTER" and strsub(action, 1, 14) == "aspect_of_the_")
				or (class == "MONK" and strsub(action, 1, 14) == "stance_of_the_")
				or (class == "PALADIN" and strsub(action, 1, 8) == "seal_of_")
				or (class == "PRIEST" and action == "shadowform")
				or (class == "WARLOCK" and action == "metamorphosis")
				or (class == "WARRIOR" and strsub(action, -7) == "_stance") then
			local stanceName = format("%s_%s", strlower(class), action)
			conditionCode = format("not Stance(%s)", stanceName)
		elseif action == "jade_serpent_potion" then
			bodyCode = "UsePotionIntellect()"
			annotation.use_potion_intellect = class
			isSpellAction = false
		elseif action == "mogu_power_potion" then
			bodyCode = "UsePotionStrength()"
			annotation.use_potion_strength = class
			isSpellAction = false
		elseif action == "mountains_potion" then
			bodyCode = "UsePotionArmor()"
			annotation.use_potion_armor = class
			isSpellAction = false
		elseif action == "virmens_bite_potion" then
			bodyCode = "UsePotionAgility()"
			annotation.use_potion_agility = class
			isSpellAction = false
		elseif strsub(action, -7) == "_potion" then
			AddSymbol(annotation, action)
			bodyCode = "Item(" .. action .. " usable=1)"
			isSpellAction = false
		elseif action == "pool_resource" then
			-- Create a special "simc_pool_resource" AST node that will be transformed in
			-- a later step into something OvaleAST can understand and unparse.
			bodyNode = OvaleAST:NewNode(nodeList)
			bodyNode.type = "simc_pool_resource"
			bodyNode.for_next = (modifier.for_next ~= nil)
			if modifier.extra_amount then
				bodyNode.extra_amount = tonumber(Unparse(modifier.extra_amount))
			end
			isSpellAction = false
		elseif action == "run_action_list" or action == "swap_action_list" then
			if modifier.name then
				local name = Unparse(modifier.name)
				bodyCode = OvaleFunctionName(name, class, specialization) .. "()"
			end
			isSpellAction = false
		elseif action == "stance" then
			if modifier.choose then
				local name = Unparse(modifier.choose)
				if class == "DEATHKNIGHT" then
					action = name .. "_presence"
				elseif class == "MONK" then
					action = "stance_of_the_" .. name
				elseif class == "WARRIOR" then
					action = name .. "_stance"
				else
					action = name
				end
				local stanceName = format("%s_%s", strlower(class), action)
				conditionCode = format("not Stance(%s)", stanceName)
			else
				isSpellAction = false
			end
		elseif action == "summon_pet" then
			bodyCode = "SummonPet()"
			annotation[action] = class
			isSpellAction = false
		elseif action == "use_item" then
			if true then
				--[[
					When "use_item" is encountered in an action list, it is usually meant to use
					all of the equipped items at the same time, so all hand tinkers and on-use
					trinkets.  Assume a "UseItemActions()" function is available that does this.
				--]]
				bodyCode = "UseItemActions()"
				annotation[action] = true
			else
				if modifier.name == "name" then
					local name = Unparse(modifier.name)
					if strmatch(name, "gauntlets") or strmatch(name, "gloves") or strmatch(name, "grips") or strmatch(name, "handguards") then
						bodyCode = "Item(HandsSlot usable=1)"
					end
				elseif modifier.slot then
					local slot = Unparse(modifier.slot)
					if slot == "hands" then
						bodyCode = "Item(HandsSlot usable=1)"
					elseif strmatch(slot, "trinket") then
						bodyCode = "{ Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) }"
						expressionType = "group"
					end
				end
			end
			isSpellAction = false
		elseif action == "wait" then
			if modifier.sec then
				-- Create a special "wait" AST node that will be transformed in
				-- a later step into something OvaleAST can understand and unparse.
				bodyNode = OvaleAST:NewNode(nodeList)
				bodyNode.type = "simc_wait"
				-- "wait,sec=expr" means to halt the processing of the action list if "expr > 0".
				conditionNode = OvaleAST:NewNode(nodeList, true)
				conditionNode.type = "compare"
				conditionNode.expressionType = "binary"
				conditionNode.operator = ">"
				conditionNode.child[1] = Emit(modifier.sec, nodeList, annotation, action)
				conditionNode.child[2] = OvaleAST:ParseCode("value", "0", nodeList, annotation.astAnnotation)
			end
			isSpellAction = false
		end
		if isSpellAction then
			AddSymbol(annotation, action)
			bodyCode = "Spell(" .. action .. ")"
		end
		annotation.astAnnotation = annotation.astAnnotation or {}
		if not bodyNode and bodyCode then
			bodyNode = OvaleAST:ParseCode(expressionType, bodyCode, nodeList, annotation.astAnnotation)
		end
		if not conditionNode and conditionCode then
			conditionNode = OvaleAST:ParseCode(expressionType, conditionCode, nodeList, annotation.astAnnotation)
		end

		-- Conditions from modifiers, if present.
		if bodyNode then
			-- Put the extra conditions on the right-most side.
			local extraConditionNode = conditionNode
			conditionNode = nil
			-- Concatenate all of the conditions from modifiers using the "and" operator.
			for modifier, expressionNode in pairs(parseNode.child) do
				local rhsNode = EmitModifier(modifier, expressionNode, nodeList, annotation, action)
				if rhsNode then
					if not conditionNode then
						conditionNode = rhsNode
					else
						local lhsNode = conditionNode
						conditionNode = OvaleAST:NewNode(nodeList, true)
						conditionNode.type = "logical"
						conditionNode.expressionType = "binary"
						conditionNode.operator = "and"
						conditionNode.child[1] = lhsNode
						conditionNode.child[2] = rhsNode
						-- Left-rotate tree to preserve precedence.
						conditionNode = LeftRotateTree(conditionNode)
					end
				end
			end
			if extraConditionNode then
				if conditionNode then
					local lhsNode = conditionNode
					local rhsNode = extraConditionNode
					conditionNode = OvaleAST:NewNode(nodeList, true)
					conditionNode.type = "logical"
					conditionNode.expressionType = "binary"
					conditionNode.operator = "and"
					conditionNode.child[1] = lhsNode
					conditionNode.child[2] = rhsNode
					-- Left-rotate tree to preserve precedence.
					conditionNode = LeftRotateTree(conditionNode)
				else
					conditionNode = extraConditionNode
				end
			end

			-- Create "if" node.
			if conditionNode then
				node = OvaleAST:NewNode(nodeList, true)
				node.type = "if"
				node.child[1] = conditionNode
				node.child[2] = bodyNode
				if bodyNode.type == "simc_pool_resource" then
					node.simc_pool_resource = true
				elseif bodyNode.type == "simc_wait" then
					node.simc_wait = true
				end
			else
				node = bodyNode
			end
		end
	end

	return node
end

EmitActionList = function(parseNode, nodeList, annotation)
	-- Function body is a group of statements.
	local groupNode = OvaleAST:NewNode(nodeList, true)
	groupNode.type = "group"
	local child = groupNode.child
	local poolResourceNode
	local emit = true
	for _, actionNode in ipairs(parseNode.child) do
		-- Add a comment containing the action to be translated.
		local commentNode = OvaleAST:NewNode(nodeList)
		commentNode.type = "comment"
		commentNode.comment = actionNode.action
		child[#child + 1] = commentNode
		if emit then
			-- Add the translated statement.
			local statementNode = EmitAction(actionNode, nodeList, annotation)
			if statementNode then
				if statementNode.type == "simc_pool_resource" then
					if statementNode.for_next then
						poolResourceNode = statementNode
					else
						-- This is a bare "pool_resource" statement, which means pool
						-- continually and skip the rest of the action list.
						emit = false
					end
				elseif poolResourceNode then
					-- This is the action following "pool_resource,for_next=1".
					child[#child + 1] = statementNode
					if poolResourceNode.extra_amount then
						local commentNode = OvaleAST:NewNode(nodeList)
						commentNode.type = "comment"
						commentNode.comment = format("Remove any 'extra_amount=%d' condition from the following statement.", poolResourceNode.extra_amount)
						child[#child + 1] = commentNode
					end
					if statementNode.type == "if" or statementNode.type == "unless" then
						local bodyNode = statementNode.child[2]
						if bodyNode.type == "action" and bodyNode.rawParams and bodyNode.rawParams[1] then
							-- Create a condition node that includes checking that the spell is not on cooldown.
							local name = OvaleAST:Unparse(bodyNode.rawParams[1])
							local code = format("not SpellCooldown(%s) > 0", name)
							local conditionNode = OvaleAST:NewNode(nodeList, true)
							conditionNode.type = "logical"
							conditionNode.expressionType = "binary"
							conditionNode.operator = "and"
							conditionNode.child[1] = statementNode.child[1]
							conditionNode.child[2] = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
							-- Create node to hold the rest of the statements.
							local restNode = OvaleAST:NewNode(nodeList, true)
							child[#child + 1] = restNode
							if statementNode.type == "if" then
								restNode.type = "unless"
							elseif statementNode.type == "unless" then
								restNode.type = "if"
							end
							restNode.child[1] = conditionNode
							restNode.child[2] = OvaleAST:NewNode(nodeList, true)
							restNode.child[2].type = "group"
							child = restNode.child[2].child
						end
					else
						-- We are pooling for this action, but it has no condition, which means
						-- pool continually and skip the rest of the action list.
						emit = false
					end
					poolResourceNode = nil
				elseif statementNode.type == "simc_wait" then
					-- This is a bare "wait" statement, which we don't know how to process, so
					-- skip it.
				elseif statementNode.simc_wait then
					-- Create an "unless" node with the remaining statements as the body.
					local restNode = OvaleAST:NewNode(nodeList, true)
					child[#child + 1] = restNode
					restNode.type = "unless"
					restNode.child[1] = statementNode.child[1]
					restNode.child[2] = OvaleAST:NewNode(nodeList, true)
					restNode.child[2].type = "group"
					child = restNode.child[2].child
				else
					child[#child + 1] = statementNode
					if statementNode.simc_pool_resource then
						-- Flip the "if/unless" statement and change the body into a group node
						-- containing all of the rest of the statements.
						if statementNode.type == "if" then
							statementNode.type = "unless"
						elseif statementNode.type == "unless" then
							statementNode.type = "if"
						end
						statementNode.child[2] = OvaleAST:NewNode(nodeList, true)
						statementNode.child[2].type = "group"
						child = statementNode.child[2].child
					end
				end
			end
		end
	end

	local node = OvaleAST:NewNode(nodeList, true)
	node.type = "add_function"
	node.name = OvaleFunctionName(parseNode.name, annotation.class, annotation.specialization)
	node.child[1] = groupNode
	return node
end

EmitExpression = function(parseNode, nodeList, annotation, action)
	local node
	local msg
	if parseNode.expressionType == "unary" then
		local opInfo = UNARY_OPERATOR[parseNode.operator]
		if opInfo then
			local operator
			if parseNode.operator == "!" then
				operator = "not"
			elseif parseNode.operator == "-" then
				operator = parseNode.operator
			end
			if operator then
				local rhsNode = Emit(parseNode.child[1], nodeList, annotation, action)
				if rhsNode then
					if operator == "-" and rhsNode.type == "value" then
						rhsNode.value = -1 * rhsNode.value
					else
						node = OvaleAST:NewNode(nodeList, true)
						node.type = opInfo[1]
						node.expressionType = "unary"
						node.operator = operator
						node.precedence = opInfo[2]
						node.child[1] = rhsNode
					end
				end
			end
		end
	elseif parseNode.expressionType == "binary" then
		local opInfo = BINARY_OPERATOR[parseNode.operator]
		if opInfo then
			local operator
			if parseNode.operator == "&" then
				operator = "and"
			elseif parseNode.operator == "|" then
				operator = "or"
			elseif parseNode.operator == "=" then
				operator = "=="
			elseif parseNode.operator == "%" then
				operator = "/"
			elseif parseNode.type == "compare" or parseNode.type == "arithmetic" then
				operator = parseNode.operator
			end
			--[[
				Special handling for rune comparisons.
				This ONLY handles rune conditions of the form "<rune><operator><number>".
			--]]
			if parseNode.type == "compare" and parseNode.child[1].rune then
				local lhsNode = parseNode.child[1]
				local rhsNode = parseNode.child[2]
				local runeType = lhsNode.rune
				local number = (rhsNode.type == "number") and tonumber(Unparse(rhsNode)) or nil
				if rhsNode.type == "number" then
					number = tonumber(Unparse(rhsNode))
				end
				if runeType and number then
					local code
					local op = parseNode.operator
					if op == ">" then
						code = format("Runes(%s %d)", runeType, number + 1)
					elseif op == ">=" then
						code = format("Runes(%s %d)", runeType, number)
					elseif op == "=" then
						if runeType ~= "death" and number == 2 then
							-- We can never have more than 2 non-death runes of the same type.
							code = format("Runes(%s %d)", runeType, number)
						else
							code = format("Runes(%s %d) and not Runes(%s %d)", runeType, number, runeType, number + 1)
						end
					elseif op == "<=" then
						code = format("not Runes(%s %d)", runeType, number + 1)
					elseif op == "<" then
						code = format("not Runes(%s %d)", runeType, number)
					end
					if not node and code then
						annotation.astAnnotation = annotation.astAnnotation or {}
						node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
					end
				end
			elseif operator then
				local lhsNode = Emit(parseNode.child[1], nodeList, annotation, action)
				local rhsNode = Emit(parseNode.child[2], nodeList, annotation, action)
				if lhsNode and rhsNode then
					node = OvaleAST:NewNode(nodeList, true)
					node.type = opInfo[1]
					node.expressionType = "binary"
					node.operator = operator
					node.precedence = opInfo[2]
					node.child[1] = lhsNode
					node.child[2] = rhsNode
				else
					msg = Ovale:Format("Warning: %s operator '%s' left and right failed.", parseNode.type, parseNode.operator)
				end
			end
		end
	end
	if node then
		if parseNode.left and parseNode.right then
			node.left = "{"
			node.right = "}"
		end
	else
		msg = msg or Ovale:Format("Warning: Operator '%s' is not implemented.", parseNode.operator)
		Ovale:Print(msg)
		node = OvaleAST:NewNode(nodeList)
		node.type = "string"
		node.value = "FIXME_" .. parseNode.operator
	end
	return node
end

EmitFunction = function(parseNode, nodeList, annotation, action)
	Ovale:FormatPrint("Warning: Function '%s' is not implemented.", parseNode.name)
	local node = OvaleAST:NewNode(nodeList)
	node.type = "variable"
	node.name = "FIXME_" .. parseNode.name
	return node
end

EmitModifier = function(modifier, parseNode, nodeList, annotation, action)
	local node, code
	local class = annotation.class
	local specialization = annotation.specialization

	if modifier == "if" then
		node = Emit(parseNode, nodeList, annotation, action)
	elseif modifier == "line_cd" then
		if not SPECIAL_ACTION[action] then
			local value = tonumber(Unparse(parseNode))
			AddSymbol(annotation, action)
			code = format("TimeSincePreviousSpell(%s) > %d", action, value)
		end
	elseif modifier == "max_cycle_targets" then
		local value = tonumber(Unparse(parseNode))
		local debuffName = action .. "_debuff"
		AddSymbol(annotation, debuffName)
		code = format("DebuffCountOnAny(%s) <= Enemies() and DebuffCountOnAny(%s) <= %d", debuffName, debuffName, value)
	elseif modifier == "moving" then
		local value = tonumber(Unparse(parseNode))
		if value == 1 then
			code = "Speed() > 0"
		end
	elseif modifier == "sync" then
		local name = Unparse(parseNode)
		name = Disambiguate(name, class, specialization)
		AddSymbol(annotation, name)
		code = format("not SpellCooldown(%s) > 0", name)
	end
	if not node and code then
		annotation.astAnnotation = annotation.astAnnotation or {}
		node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
	end
	return node
end

EmitNumber = function(parseNode, nodeList, annotation, action)
	local node = OvaleAST:NewNode(nodeList)
	node.type = "value"
	node.value = parseNode.value
	node.origin = 0
	node.rate = 0
	return node
end

EmitOperand = function(parseNode, nodeList, annotation, action)
	local ok = false
	local node

	local operand = parseNode.name
	local token = strmatch(operand, OPERAND_TOKEN_PATTERN)	-- peek
	local target
	if token == "target" or token == "pet" then
		target = token
		operand = strsub(operand, strlen(target) + 2)		-- consume
		token = strmatch(operand, OPERAND_TOKEN_PATTERN)	-- peek
	end
	ok, node = EmitOperandSpecial(operand, parseNode, nodeList, annotation, action, target)
	if not ok then
		ok, node = EmitOperandAction(operand, parseNode, nodeList, annotation, action, target)
	end
	if not ok then
		ok, node = EmitOperandCharacter(operand, parseNode, nodeList, annotation, action, target)
	end
	if not ok then
		if token == "aura" then
			ok, node = EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target)
		elseif token == "buff" then
			ok, node = EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target)
		elseif token == "cooldown" then
			ok, node = EmitOperandCooldown(operand, parseNode, nodeList, annotation, action)
		elseif token == "debuff" then
			target = target or "target"
			ok, node = EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target)
		elseif token == "dot" then
			target = target or "target"
			ok, node = EmitOperandDot(operand, parseNode, nodeList, annotation, action, target)
		elseif token == "glyph" then
			ok, node = EmitOperandGlyph(operand, parseNode, nodeList, annotation, action)
		elseif token == "set_bonus" then
			ok, node = EmitOperandSetBonus(operand, parseNode, nodeList, annotation, action)
		elseif token == "talent" then
			ok, node = EmitOperandTalent(operand, parseNode, nodeList, annotation, action)
		elseif token == "totem" then
			ok, node = EmitOperandTotem(operand, parseNode, nodeList, annotation, action)
		elseif token == "trinket" then
			ok, node = EmitOperandTrinket(operand, parseNode, nodeList, annotation, action)
		end
	end
	if not ok then
		node = OvaleAST:NewNode(nodeList)
		node.type = "variable"
		node.name = "FIXME_" .. parseNode.name
	end

	return node
end

EmitOperandAction = function(operand, parseNode, nodeList, annotation, action, target)
	local ok = true
	local node

	local name
	local property
	if strsub(operand, 1, 7) == "action." then
		local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
		local token = tokenIterator()
		name = tokenIterator()
		property = tokenIterator()
	else
		name = action
		property = operand
	end

	name = Disambiguate(name, annotation.class, annotation.specialization)
	target = target and (target .. ".") or ""
	local buffName = name .. "_debuff"
	buffName = Disambiguate(buffName, annotation.class, annotation.specialization)
	local prefix = strfind(buffName, "_buff$") and "Buff" or "Debuff"
	local buffTarget = (prefix == "Debuff") and "target." or target
	local talentName = name .. "_talent"
	talentName = Disambiguate(talentName, annotation.class, annotation.specialization)
	local symbol = name

	local code
	if property == "active" then
		if strsub(name, -6) == "_totem" then
			local totemType = TOTEM_TYPE[name]
			if totemType then
				code = format("TotemPresent(%s totem=%s)", totemType, name)
			else
				code = format("TotemPresent(%s)", name)
				symbol = false
			end
		else
			code = format("%s%sPresent(%s)", target, prefix, buffName)
			symbol = buffName
		end
	elseif property == "add_ticks" then
		code = format("TicksAdded(%s)", buffName)
			symbol = buffName
	elseif property == "cast_delay" then
		-- "cast_delay" has no meaning in Ovale.
		code = "True(cast_delay)"
	elseif property == "cast_time" then
		code = format("CastTime(%s)", name)
	elseif property == "charges" then
		code = format("Charges(%s)", name)
	elseif property == "cooldown" then
		code = format("SpellCooldown(%s)", name)
	elseif property == "cooldown_react" then
		code = format("not SpellCooldown(%s) > 0", name)
	elseif property == "crit_damage" then
		-- TODO: Melee/Ranged/Spell crit chance depending on type of attack, or at least class of player.
		code = format("%sCritDamage(%s)", target, name)
	elseif property == "crit_pct_current" then
		-- TODO: Melee/Ranged/Spell crit chance depending on type of attack, or at least class of player.
		code = "SpellCritChance()"
	elseif property == "crit_tick_damage" then
		code = format("%sCritDamage(%s)", buffTarget, buffName)
		symbol = buffName
	elseif property == "duration" then
		code = format("SpellData(%s duration)", buffName)
		symbol = buffName
	elseif property == "ember_react" then
		-- XXX
		code = "BurningEmbers() >= 10"
	elseif property == "enabled" then
		code = format("Talent(%s)", talentName)
		symbol = talentName
	elseif property == "execute_time" then
		code = format("ExecuteTime(%s)", name)
	elseif property == "gcd" then
		code = "GCD()"
	elseif property == "hit_damage" then
		code = format("%sDamage(%s)", target, name)
	elseif property == "in_flight" or property == "in_flight_to_target" then
		code = format("InFlightToTarget(%s)", name)
	elseif property == "miss_react" then
		-- "miss_react" has no meaning in Ovale.
		code = "True(miss_react)"
	elseif property == "n_ticks" then
		code = format("%sTicks(%s)", buffTarget, buffName)
	elseif property == "recharge_time" then
		code = format("SpellChargeCooldown(%s)", name)
	elseif property == "remains" then
		if strsub(name, -6) == "_totem" then
			local totemType = TOTEM_TYPE[name]
			if totemType then
				code = format("TotemRemaining(%s totem=%s)", totemType, name)
			else
				code = format("TotemRemaining(%s)", name)
				symbol = false
			end
		else
			code = format("%s%sRemaining(%s)", buffTarget, prefix, buffName)
			symbol = buffName
		end
	elseif property == "shard_react" then
		-- XXX
		code = "SoulShards() >= 1"
	elseif property == "spell_power" then
		code = format("%s%sSpellpower(%s)", buffTarget, prefix, buffName)
	elseif property == "tick_damage" then
		code = format("%sDamage(%s)", buffTarget, buffName)
		symbol = buffName
	elseif property == "tick_multiplier" then
		code = format("%sDamageMultiplier(%s)", buffTarget, buffName)
		symbol = buffName
	elseif property == "tick_time" then
		code = format("%sTickTime(%s)", buffTarget, buffName)
		symbol = buffName
	elseif property == "ticking" then
		code = format("%s%sPresent(%s)", buffTarget, prefix, buffName)
		symbol = buffName
	elseif property == "ticks_remain" then
		code = format("%sTicksRemaining(%s)", buffTarget, buffName)
		symbol = buffName
	elseif property == "travel_time" then
		-- Assume travel time of a spell is always 0.5s.
		-- TODO: Track average time in flight to target for the spell.
		code = "0.5"
	else
		ok = false
	end
	if ok and code then
		annotation.astAnnotation = annotation.astAnnotation or {}
		node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
		if symbol then
			AddSymbol(annotation, symbol)
		end
	end

	return ok, node
end

EmitOperandBuff = function(operand, parseNode, nodeList, annotation, action, target)
	local ok = true
	local node

	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "aura" or token == "buff" or token == "debuff" then
		local name = tokenIterator()
		local property = tokenIterator()
		name = Disambiguate(name, annotation.class, annotation.specialization)
		local buffName = (token == "debuff") and name .. "_debuff" or name .. "_buff"
		buffName = Disambiguate(buffName, annotation.class, annotation.specialization)
		local prefix = strfind(buffName, "_buff$") and "Buff" or "Debuff"
		local any = OvaleData.buffSpellList[buffName] and " any=1" or ""
		target = target and (target .. ".") or ""

		-- Unholy death knight's Dark Transformation applies the buff to the ghoul/pet.
		if buffName == "dark_transformation_buff" then
			if target == "" then
				target = "pet."
			end
			any = " any=1"
		end

		local code
		if property == "cooldown_remains" then
			-- Assume that the spell and the buff have the same name.
			code = format("SpellCooldown(%s)", name)
		elseif property == "down" then
			code = format("%s%sExpires(%s%s)", target, prefix, buffName, any)
		elseif property == "duration" then
			code = format("SpellData(%s duration)", buffName)
		elseif property == "max_stack" then
			local maxStack = 1
			if buffName == "lightning_shield_buff" then
				maxStack = 7
			end
			code = tostring(maxStack)
		elseif property == "react" or property == "stack" then
			if parseNode.asType == "boolean" then
				code = format("%s%sPresent(%s%s)", target, prefix, buffName, any)
			else
				code = format("%s%sStacks(%s%s)", target, prefix, buffName, any)
			end
		elseif property == "remains" then
			code = format("%s%sRemaining(%s%s)", target, prefix, buffName, any)
		elseif property == "up" then
			code = format("%s%sPresent(%s%s)", target, prefix, buffName, any)
		elseif property == "value" then
			code = format("%s%sAmount(%s%s)", target, prefix, buffName, any)
		else
			ok = false
		end
		if ok and code then
			annotation.astAnnotation = annotation.astAnnotation or {}
			node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
			AddSymbol(annotation, buffName)
		end
	else
		ok = false
	end

	return ok, node
end

do
	local CHARACTER_PROPERTY = {
		["active_enemies"]		= "Enemies()",
		["adds"]				= "Enemies()",
		["chi"]					= "Chi()",
		["chi.max"]				= "MaxChi()",
		["combo_points"]		= "ComboPoints()",
		["demonic_fury"]		= "DemonicFury()",
		["eclipse"]				= "Eclipse()",
		["eclipse_dir"]			= "EclipseDir()",
		["energy"]				= "Energy()",
		["energy.regen"]		= "EnergyRegen()",
		["energy.time_to_max"]	= "TimeToMaxEnergy()",
		["focus"]				= "Focus()",
		["focus.regen"]			= "FocusRegen()",
		["focus.time_to_max"]	= "TimeToMaxFocus()",
		["health"]				= "Health()",
		["health.deficit"]		= "HealthMissing()",
		["health.max"]			= "MaxHealth()",
		["health.pct"]			= "HealthPercent()",
		["holy_power"]			= "HolyPower()",
		["in_combat"]			= "InCombat()",
		["level"]				= "Level()",
		["mana"]				= "Mana()",
		["mana.deficit"]		= "ManaDeficit()",
		["mana.max"]			= "MaxMana()",
		["mana.max_nonproc"]	= "MaxMana()",
		["mana.pct"]			= "ManaPercent()",
		["mana.pct_nonproc"]	= "ManaPercent()",
		["multiplier"]			= "DamageMultiplier()",
		["ptr"]					= "PTR()",
		["rage"]				= "Rage()",
		["rage.max"]			= "MaxRage()",
		["runic_power"]			= "RunicPower()",
		["shadow_orb"]			= "ShadowOrbs()",
		["soul_shards"]			= "SoulShards()",
		["spell_haste"]			= "SpellHaste() / 100",
		["stat.agility"]		= "Agility()",
		["stat.attack_power"]	= "AttackPower()",
		["stat.crit"]			= "CritRating()",
		["stat.crit_rating"]	= "CritRating()",
		["stat.energy"]			= "Energy()",
		["stat.focus"]			= "Focus()",
		["stat.haste_rating"]	= "HasteRating()",
		["stat.health"]			= "Health()",
		["stat.intellect"]		= "Intellect()",
		["stat.mana"]			= "Mana()",
		["stat.mastery_rating"]	= "MasteryRating()",
		["stat.maximum_energy"]	= "MaxEnergy()",
		["stat.maximum_focus"]	= "MaxFocus()",
		["stat.maximum_health"]	= "MaxHealth()",
		["stat.maximum_mana"]	= "MaxMana()",
		["stat.maximum_runic"]	= "MaxRunicPower()",
		["stat.rage"]			= "Rage()",
		["stat.runic"]			= "RunicPower()",
		["stat.spell_power"]	= "Spellpower()",
		["stat.spirit"]			= "Spirit()",
		["stat.stamina"]		= "Stamina()",
		["stat.strength"]		= "Strength()",
		["time"]				= "TimeInCombat()",
		["time_to_bloodlust"]	= "TimeToBloodlust()",
		["time_to_die"]			= "TimeToDie()",
	}

	EmitOperandCharacter = function(operand, parseNode, nodeList, annotation, action, target)
		local ok = true
		local node

		target = target and (target .. ".") or ""
		local code
		if CHARACTER_PROPERTY[operand] then
			code = target .. CHARACTER_PROPERTY[operand]
		elseif operand == "anticipation_charges" then
			local name = "anticipation_buff"
			code = format("BuffStacks(%s)", name)
			AddSymbol(annotation, name)
		elseif operand == "burning_ember" then
			code = format("%sBurningEmbers() / 10", target)
		elseif strfind(operand, "^incoming_damage_") then
			local seconds, measure = strmatch(operand, "^incoming_damage_([%d]+)(m?s)$")
			seconds = tonumber(seconds)
			if measure == "ms" then
				seconds = seconds / 1000
			end
			code = format("IncomingDamage(%f)", seconds)
		elseif operand == "mana_gem_charges" then
			local itemName = "mana_gem"
			code = format("ItemCharges(%s)", itemName)
			AddSymbol(annotation, itemName)
		elseif operand == "mastery_value" then
			code = format("%sMasteryEffect() / 100", target)
		elseif operand == "position_front" then
			-- "position_front" should always be false in Ovale because we assume the
			-- player can get into the optimal attack position at all times.
			code = "False(position_front)"
		else
			ok = false
		end
		if ok and code then
			annotation.astAnnotation = annotation.astAnnotation or {}
			node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
		end

		return ok, node
	end
end

EmitOperandCooldown = function(operand, parseNode, nodeList, annotation, action)
	local ok = true
	local node

	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "cooldown" then
		local name = tokenIterator()
		local property = tokenIterator()
		name = Disambiguate(name, annotation.class, annotation.specialization)

		local code
		if property == "duration" then
			code = format("SpellCooldownDuration(%s)", name)
		elseif property == "remains" then
			code = format("SpellCooldown(%s)", name)
		elseif property == "up" then
			code = format("not SpellCooldown(%s) > 0", name)
		else
			ok = false
		end
		if ok and code then
			annotation.astAnnotation = annotation.astAnnotation or {}
			node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
			AddSymbol(annotation, name)
		end
	else
		ok = false
	end

	return ok, node
end

EmitOperandDot = function(operand, parseNode, nodeList, annotation, action, target)
	local ok = true
	local node

	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "dot" then
		local name = tokenIterator()
		local property = tokenIterator()
		name = Disambiguate(name, annotation.class, annotation.specialization)
		local dotName = name .. "_debuff"
		dotName = Disambiguate(dotName, annotation.class, annotation.specialization)
		local prefix = strfind(dotName, "_buff$") and "Buff" or "Debuff"
		target = target and (target .. ".") or ""

		local code
		if property == "attack_power" then
			code = format("%s%sAttackPower(%s)", target, prefix, dotName)
		elseif property == "crit_pct" then
			code = format("%s%sSpellCritChance(%s)", target, prefix, dotName)
		elseif property == "duration" then
			code = format("%s%sDuration(%s)", target, prefix, dotName)
		elseif property == "multiplier" then
			code = format("%s%DamageMultiplier(%s)", target, prefix, dotName)
		elseif property == "remains" then
			code = format("%s%sRemaining(%s)", target, prefix, dotName)
		elseif property == "spell_power" then
			code = format("%s%sSpellpower(%s)", target, prefix, dotName)
		elseif property == "tick_dmg" then
			code = format("%sLastEstimatedDamage(%s)", target, dotName)
		elseif property == "ticking" then
			code = format("%s%sPresent(%s)", target, prefix, dotName)
		elseif property == "ticks" then
			code = format("%sTicks(%s)", target, dotName)
		elseif property == "ticks_remain" then
			code = format("%sTicksRemaining(%s)", target, dotName)
		else
			ok = false
		end
		if ok and code then
			annotation.astAnnotation = annotation.astAnnotation or {}
			node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
			AddSymbol(annotation, dotName)
		end
	else
		ok = false
	end

	return ok, node
end

EmitOperandGlyph = function(operand, parseNode, nodeList, annotation, action)
	local ok = true
	local node

	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "glyph" then
		local name = tokenIterator()
		local property = tokenIterator()
		name = Disambiguate(name, annotation.class, annotation.specialization)
		local glyphName = "glyph_of_" .. name
		glyphName = Disambiguate(glyphName, annotation.class, annotation.specialization)

		local code
		if property == "disabled" then
			code = format("not Glyph(%s)", glyphName)
		elseif property == "enabled" then
			code = format("Glyph(%s)", glyphName)
		else
			ok = false
		end
		if ok and code then
			annotation.astAnnotation = annotation.astAnnotation or {}
			node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
			AddSymbol(annotation, glyphName)
		end
	else
		ok = false
	end

	return ok, node
end

EmitOperandSetBonus = function(operand, parseNode, nodeList, annotation, action)
	local ok = true
	local node

	local name, count, role = strmatch(operand, "^set_bonus%.(%w+)_(%d+)pc_(%w+)$")
	local code
	if name and count and role then
		local tierLevel = strmatch(name, "^tier(%d+)")
		if tierLevel then
			name = format("T%s", tierLevel)
		end
		code = format("ArmorSetBonus(%s_%s %s)", name, role, count)
	else
		ok = false
	end
	if ok and code then
		annotation.astAnnotation = annotation.astAnnotation or {}
		node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
	end

	return ok, node
end

EmitOperandSpecial = function(operand, parseNode, nodeList, annotation, action, target)
	local ok = true
	local node

	target = target and (target .. ".") or ""
	local code
	if operand == "active_flame_shock" then
		local debuffName = "flame_shock_debuff"
		code = format("DebuffCountOnAny(%s)", debuffName)
		AddSymbol(annotation, debuffName)
	elseif operand == "action.frozen_orb.in_flight" then
		-- The Frozen Orb is still in flight if fewer than 10s have elapsed since it was cast.
		local name = "frozen_orb"
		code = format("SpellCooldown(%s) > SpellCooldownDuration(%s) - 10", name, name)
		AddSymbol(annotation, name)
	elseif operand == "buff.beast_cleave.down" then
		-- Beast Cleave is a buff on the hunter's pet.
		local buffName = "pet_beast_cleave_buff"
		code = format("pet.BuffExpires(%s any=1)", buffName)
		AddSymbol(annotation, buffName)
	elseif operand == "buff.havoc.remains" then
		-- Havoc is a debuff on one of the warlock's targets.
		local debuffName = "havoc_debuff"
		code = format("DebuffRemainingOnAny(%s)", debuffName)
		AddSymbol(annotation, debuffName)
	elseif operand == "buff.havoc.stack" then
		-- Havoc is a debuff on one of the warlock's targets.
		local debuffName = "havoc_debuff"
		code = format("DebuffStacksOnAny(%s)", debuffName)
		AddSymbol(annotation, debuffName)
	elseif operand == "buff.rune_of_power.remains" then
		code = "RuneOfPowerRemaining()"
	elseif operand == "buff.wild_mushroom.max_stack" then
		local maxStack = 0
		if annotation.class == "DRUID" then
			if annotation.specialization == "restoration" then
				maxStack = 1
			elseif annotation.specialization == "balance" then
				maxStack = 3
			end
		end
		code = tostring(maxStack)
	elseif operand == "buff.wild_mushroom.stack" then
		code = "WildMushroomCount()"
	elseif operand == "debuff.casting.react" then
		code = target .. "IsInterruptible()"
	elseif operand == "debuff.flying.down" then
		code = target .. "True(debuff_flying_down)"
	elseif operand == "buff.raid_movement.duration" then
		code = "0"
	elseif operand == "cooldown.icy_veins.remains" then
		code = "IcyVeinsCooldownRemaining()"
		annotation.cooldown_icy_veins_remains = annotation.class
	elseif operand == "debuff.invulnerable.react" then
		-- Pretend the target can never be invulnerable.
		code = "InCombat(no)"
	elseif operand == "distance" then
		code = target .. "Distance()"
	elseif operand == "dot.ignite.tick_dmg" then
		local debuffName = "ignite_debuff"
		target = "target."
		code = format("%sTickValue(%s)", target, debuffName)
		AddSymbol(annotation, debuffName)
	elseif operand == "dot.sacred_shield.remains" then
		--[[
			Sacred Shield is handled specially because SimulationCraft treats it like
			a damaging spell, e.g., "target.dot.sacred_shield.remains" to represent the
			buff on the player.
		--]]
		local buffName = "sacred_shield_buff"
		code = format("BuffPresent(%s)", buffName)
		AddSymbol(annotation, buffName)
	elseif operand == "dot.zen_sphere.ticking" then
		-- Zen Sphere is a helpful DoT.
		local buffName = "zen_sphere_buff"
		code = format("BuffPresent(%s)", buffName)
		AddSymbol(annotation, buffName)
	elseif operand == "greater_fire_elemental.active" or operand == "primal_fire_elemental.active" then
		local totemName = "fire_elemental_totem"
		code = format("TotemPresent(fire totem=%s)", totemName)
		AddSymbol(annotation, totemName)
	elseif operand == "pyro_chain" then
		if parseNode.asType == "boolean" then
			code = "GetState(pyro_chain) > 0"
		else
			code = "GetState(pyro_chain)"
		end
	else
		ok = false
	end
	if ok and code then
		annotation.astAnnotation = annotation.astAnnotation or {}
		node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
	end

	return ok, node
end

EmitOperandTalent = function(operand, parseNode, nodeList, annotation, action)
	local ok = true
	local node

	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "talent" then
		local name = tokenIterator()
		local property = tokenIterator()
		-- Talent names need no disambiguation as they are the same across all specializations.
		--name = Disambiguate(name, annotation.class, annotation.specialization)
		local talentName = name .. "_talent"
		talentName = Disambiguate(talentName, annotation.class, annotation.specialization)

		local code
		if property == "disabled" then
			code = format("Talent(%s no)", talentName)
		elseif property == "enabled" then
			code = format("Talent(%s)", talentName)
		else
			ok = false
		end
		if ok and code then
			annotation.astAnnotation = annotation.astAnnotation or {}
			node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
			AddSymbol(annotation, talentName)
		end
	else
		ok = false
	end

	return ok, node
end

EmitOperandTotem = function(operand, parseNode, nodeList, annotation, action)
	local ok = true
	local node

	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "totem" then
		local name = tokenIterator()
		local property = tokenIterator()
		name = Disambiguate(name, annotation.class, annotation.specialization)
		local totemType = TOTEM_TYPE[name]

		local code
		if property == "active" then
			if totemType then
				code = format("TotemPresent(%s totem=%s)", totemType, name)
			else
				code = format("TotemPresent(%s)", name)
			end
		elseif property == "remains" then
			if totemType then
				code = format("TotemRemaining(%s totem=%s)", totemType, name)
			else
				code = format("TotemRemaining(%s)", name)
			end
		else
			ok = false
		end
		if ok and code then
			annotation.astAnnotation = annotation.astAnnotation or {}
			node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
			if totemType then
				AddSymbol(annotation, name)
			end
		end
	else
		ok = false
	end

	return ok, node
end

EmitOperandTrinket = function(operand, parseNode, nodeList, annotation, action)
	local ok = true
	local node

	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "trinket" then
		local procType = tokenIterator()
		local statName = tokenIterator()
		local property = tokenIterator()
		local buffName = format("trinket_%s_%s_buff", procType, statName)
		buffName = Disambiguate(buffName, annotation.class, annotation.specialization)

		local code
		if property == "cooldown_remains" then
			code = format("BuffCooldown(%s)", buffName)
		elseif property == "down" then
			code = format("BuffExpires(%s)", buffName)
		elseif property == "react" then
			if parseNode.asType == "boolean" then
				code = format("BuffPresent(%s)", buffName)
			else
				code = format("BuffStacks(%s)", buffName)
			end
		elseif property == "remains" then
			code = format("BuffRemaining(%s)", buffName)
		elseif property == "stack" then
			code = format("BuffStacks(%s)", buffName)
		elseif property == "up" then
			code = format("BuffPresent(%s)", buffName)
		else
			ok = false
		end
		if ok and code then
			annotation.astAnnotation = annotation.astAnnotation or {}
			node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
			AddSymbol(annotation, buffName)
		end
	else
		ok = false
	end

	return ok, node
end

do
	EMIT_VISITOR = {
		["action"] = EmitAction,
		["action_list"] = EmitActionList,
		["arithmetic"] = EmitExpression,
		["compare"] = EmitExpression,
		["function"] = EmitFunction,
		["logical"] = EmitExpression,
		["number"] = EmitNumber,
		["operand"] = EmitOperand,
	}
end

local function InsertSupportingFunctions(child, annotation)
	local count = 0
	local nodeList = annotation.astAnnotation.nodeList
	if annotation.mind_freeze == "DEATHKNIGHT" then
		local code = [[
			AddFunction InterruptActions
			{
				if target.IsFriend(no) and target.IsInterruptible()
				{
					if target.InRange(mind_freeze) Spell(mind_freeze)
					if target.Classification(worldboss no)
					{
						if Talent(asphyxiate_talent) and target.InRange(asphyxiate) Spell(asphyxiate)
						if target.InRange(strangulate) Spell(strangulate)
						Spell(arcane_torrent_runicpower)
						if target.InRange(quaking_palm) Spell(quaking_palm)
					}
				}
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "arcane_torrent_runicpower")
		AddSymbol(annotation, "asphyxiate")
		AddSymbol(annotation, "asphyxiate_talent")
		AddSymbol(annotation, "mind_freeze")
		AddSymbol(annotation, "quaking_palm")
		AddSymbol(annotation, "strangulate")
		count = count + 1
	end
	if annotation.savage_roar == "DRUID" then
		local code = [[
			AddFunction SavageRoar
			{
				if Glyph(glyph_of_savagery) Spell(savage_roar_glyphed)
				if Glyph(glyph_of_savagery no) and ComboPoints() > 0 Spell(savage_roar)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "glyph_of_savagery")
		AddSymbol(annotation, "savage_roar")
		AddSymbol(annotation, "savage_roar_glyphed")
		count = count + 1
	end
	if annotation.faerie_fire == "DRUID" then
		local code = [[
			AddFunction FaerieFire
			{
				if Talent(faerie_swarm_talent) Spell(faerie_swarm)
				if Talent(faerie_swarm_talent no) Spell(faerie_fire)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "faerie_fire")
		AddSymbol(annotation, "faerie_swarm")
		AddSymbol(annotation, "faerie_swarm_talent")
		count = count + 1
	end
	if annotation.skull_bash_bear == "DRUID" or annotation.skull_bash_cat == "DRUID" then
		local code = [[
			AddFunction InterruptActions
			{
				if target.IsFriend(no) and target.IsInterruptible()
				{
					if Stance(druid_bear_form) and target.InRange(skull_bash_bear) Spell(skull_bash_bear)
					if Stance(druid_cat_form) and target.InRange(skull_bash_cat) Spell(skull_bash_cat)
					if target.Classification(worldboss no)
					{
						if Talent(mighty_bash_talent) and target.InRange(mighty_bash) Spell(mighty_bash)
						if Talent(typhoon_talent) and target.InRange(skull_bash_cat) Spell(typhoon)
						if Stance(druid_cat_form) and ComboPoints() > 0 and target.InRange(maim) Spell(maim)
					}
				}
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "maim")
		AddSymbol(annotation, "mighty_bash")
		AddSymbol(annotation, "mighty_bash_talent")
		AddSymbol(annotation, "skull_bash_bear")
		AddSymbol(annotation, "skull_bash_cat")
		AddSymbol(annotation, "typhoon")
		AddSymbol(annotation, "typhoon_talent")
		count = count + 1
	end
	if annotation.summon_pet == "HUNTER" then
		local code = [[
			AddFunction SummonPet
			{
				if pet.Present(no) Texture(ability_hunter_beastcall help=L(summon_pet))
				if pet.IsDead() Spell(revive_pet)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "revive_pet")
		count = count + 1
	end
	if annotation.counter_shot == "HUNTER" or annotation.silencing_shot == "HUNTER" then
		local code = [[
			AddFunction InterruptActions
			{
				if target.IsFriend(no) and target.IsInterruptible()
				{
					Spell(silencing_shot)
					Spell(counter_shot)
					if target.Classification(worldboss no)
					{
						Spell(arcane_torrent_focus)
						if target.InRange(quaking_palm) Spell(quaking_palm)
					}
				}
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "arcane_torrent_focus")
		AddSymbol(annotation, "counter_shot")
		AddSymbol(annotation, "quaking_palm")
		AddSymbol(annotation, "silencing_shot")
		count = count + 1
	end
	if annotation.aspect_of_the_hawk == "HUNTER" then
		local code = [[
			AddFunction AspectOfTheHawk
			{
				if Talent(aspect_of_the_iron_hawk_talent) and not Stance(hunter_aspect_of_the_iron_hawk) Spell(aspect_of_the_iron_hawk)
				if Talent(aspect_of_the_iron_hawk_talent no) and not Stance(hunter_aspect_of_the_hawk) Spell(aspect_of_the_hawk)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "aspect_of_the_hawk")
		AddSymbol(annotation, "aspect_of_the_iron_hawk")
		AddSymbol(annotation, "aspect_of_the_iron_hawk_talent")
		count = count + 1
	end
	if annotation.cooldown_icy_veins_remains == "MAGE" then
		local code = [[
			AddFunction IcyVeinsCooldownRemaining
			{
				if Glyph(glyph_of_icy_veins) SpellCooldown(icy_veins_glyphed)
				if Glyph(glyph_of_icy_veins no) SpellCooldown(icy_veins)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "glyph_of_icy_veins")
		AddSymbol(annotation, "icy_veins")
		AddSymbol(annotation, "icy_veins_glyphed")
		count = count + 1
	end
	if annotation.icy_veins == "MAGE" then
		local code = [[
			AddFunction IcyVeins
			{
				if Glyph(glyph_of_icy_veins) Spell(icy_veins_glyphed)
				if Glyph(glyph_of_icy_veins no) Spell(icy_veins)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "glyph_of_icy_veins")
		AddSymbol(annotation, "icy_veins")
		AddSymbol(annotation, "icy_veins_glyphed")
		count = count + 1
	end
	if annotation.mana_gem == "MAGE" then
		local code = [[
			AddFunction UseManaGem
			{
				if Glyph(glyph_of_mana_gem) Item(brilliant_mana_gem)
				if Glyph(glyph_of_mana_gem no) Item(mana_gem)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "brilliant_mana_gem")
		AddSymbol(annotation, "glyph_of_mana_gem")
		AddSymbol(annotation, "mana_gem")
		count = count + 1
	end
	if annotation.conjure_mana_gem == "MAGE" then
		local code = [[
			AddFunction ConjureManaGem
			{
				if Glyph(glyph_of_mana_gem) and ItemCharges(brilliant_mana_gem) < 10 Spell(conjure_brilliant_mana_gem)
				if Glyph(glyph_of_mana_gem no) and ItemCharges(mana_gem) < 10 Spell(conjure_mana_gem)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "brilliant_mana_gem")
		AddSymbol(annotation, "conjure_brilliant_mana_gem")
		AddSymbol(annotation, "conjure_mana_gem")
		AddSymbol(annotation, "glyph_of_mana_gem")
		AddSymbol(annotation, "mana_gem")
		count = count + 1
	end
	if annotation.counterspell == "MAGE" then
		local code = [[
			AddFunction InterruptActions
			{
				if target.IsFriend(no) and target.IsInterruptible() 
				{
					Spell(counterspell)
					if target.Classification(worldboss no)
					{
						Spell(arcane_torrent_mana)
						if target.InRange(quaking_palm) Spell(quaking_palm)
					}
				}
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "arcane_torrent_mana")
		AddSymbol(annotation, "counterspell")
		AddSymbol(annotation, "quaking_palm")
		count = count + 1
	end
	if annotation.spear_hand_strike == "MONK" then
		local code = [[
			AddFunction InterruptActions
			{
				if target.IsFriend(no) and target.IsInterruptible()
				{
					if target.InRange(spear_hand_strike) Spell(spear_hand_strike)
					if target.Classification(worldboss no)
					{
						if target.InRange(paralysis) Spell(paralysis)
						Spell(arcane_torrent_chi)
						if target.InRange(quaking_palm) Spell(quaking_palm)
					}
				}
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "arcane_torrent_chi")
		AddSymbol(annotation, "paralysis")
		AddSymbol(annotation, "quaking_palm")
		AddSymbol(annotation, "spear_hand_strike")
		count = count + 1
	end
	if annotation.rebuke == "PALADIN" then
		local code = [[
			AddFunction InterruptActions
			{
				if target.IsFriend(no) and target.IsInterruptible()
				{
					if target.InRange(rebuke) Spell(rebuke)
					if target.Classification(worldboss no)
					{
						if Talent(fist_of_justice_talent) Spell(fist_of_justice)
						if Talent(fist_of_justice_talent no) and target.InRange(hammer_of_justice) Spell(hammer_of_justice)
						#Spell(blinding_light)
						Spell(arcane_torrent_mana)
						if target.InRange(quaking_palm) Spell(quaking_palm)
					}
				}
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "arcane_torrent_mana")
		AddSymbol(annotation, "fist_of_justice")
		AddSymbol(annotation, "hammer_of_justice")
		AddSymbol(annotation, "quaking_palm")
		AddSymbol(annotation, "rebuke")
		count = count + 1
	end
	if annotation.exorcism == "PALADIN" then
		local code = [[
			AddFunction Exorcism
			{
				if Glyph(glyph_of_mass_exorcism) Spell(exorcism_glyphed)
				if Glyph(glyph_of_mass_exorcism no) Spell(exorcism)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "exorcism")
		AddSymbol(annotation, "exorcism_glyphed")
		AddSymbol(annotation, "glyph_of_mass_exorcism")
		count = count + 1
	end
	if annotation.consecration == "PALADIN" then
		local code = [[
			AddFunction Consecration
			{
				if Glyph(glyph_of_consecration) Spell(consecration_glyphed)
				if Glyph(glyph_of_consecration no) Spell(consecration)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "consecration")
		AddSymbol(annotation, "consecration_glyphed")
		AddSymbol(annotation, "glyph_of_consecration")
		count = count + 1
	end
	if annotation.silence == "PRIEST" then
		local code = [[
			AddFunction InterruptActions
			{
				if target.IsFriend(no) and target.IsInterruptible()
				{
					Spell(silence)
					if target.Classification(worldboss no)
					{
						Spell(arcane_torrent_mana)
						if target.InRange(quaking_palm) Spell(quaking_palm)
					}
				}
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "arcane_torrent_mana")
		AddSymbol(annotation, "quaking_palm")
		AddSymbol(annotation, "silence")
		count = count + 1
	end
	if annotation.stealth == "ROGUE" then
		local code = [[
			AddFunction Stealth
			{
				if Talent(subterfuge_talent) Spell(stealth_subterfuge)
				if Talent(subterfuge_talent no) Spell(stealth)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "stealth")
		AddSymbol(annotation, "stealth_subterfuge")
		AddSymbol(annotation, "subterfuge_talent")
		count = count + 1
	end
	if annotation.kick == "ROGUE" then
		local code = [[
			AddFunction InterruptActions
			{
				if target.IsFriend(no) and target.IsInterruptible()
				{
					if target.InRange(kick) Spell(kick)
					if target.Classification(worldboss no)
					{
						if target.InRange(kidney_shot) Spell(kidney_shot)
						if target.InRange(cheap_shot) and BuffPresent(stealthed_buff any=1) Spell(cheap_shot)
						Spell(arcane_torrent_energy)
						if target.InRange(quaking_palm) Spell(quaking_palm)
					}
				}
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "arcane_torrent_energy")
		AddSymbol(annotation, "cheap_shot")
		AddSymbol(annotation, "kick")
		AddSymbol(annotation, "kidney_shot")
		AddSymbol(annotation, "quaking_palm")
		count = count + 1
	end
	if annotation.wind_shear == "SHAMAN" then
		local code = [[
			AddFunction InterruptActions
			{
				if target.IsFriend(no) and target.IsInterruptible() 
				{
					Spell(wind_shear)
					if target.Classification(worldboss no)
					{
						Spell(arcane_torrent_mana)
						if target.InRange(quaking_palm) Spell(quaking_palm)
					}
				}
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "arcane_torrent_mana")
		AddSymbol(annotation, "quaking_palm")
		AddSymbol(annotation, "wind_shear")
		count = count + 1
	end
	if annotation.bloodlust == "SHAMAN" then
		local code = [[
			AddFunction Bloodlust
			{
				if CheckBoxOn(opt_bloodlust) and DebuffExpires(burst_haste_debuff any=1)
				{
					Spell(bloodlust)
					Spell(heroism)
				}
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "bloodlust")
		AddSymbol(annotation, "heroism")
		count = count + 1
	end
	if annotation.pummel == "WARRIOR" then
		local code = [[
			AddFunction InterruptActions
			{
				if target.IsFriend(no) and target.IsInterruptible()
				{
					if target.InRange(pummel) Spell(pummel)
					if Glyph(glyph_of_gag_order) and target.InRange(heroic_throw) Spell(heroic_throw)
					Spell(disrupting_shout)
					if target.Classification(worldboss no)
					{
						Spell(arcane_torrent_rage)
						if target.InRange(quaking_palm) Spell(quaking_palm)
					}
				}
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "arcane_torrent_rage")
		AddSymbol(annotation, "disrupting_shout")
		AddSymbol(annotation, "glyph_of_gag_order")
		AddSymbol(annotation, "heroic_throw")
		AddSymbol(annotation, "pummel")
		AddSymbol(annotation, "quaking_palm")
		count = count + 1
	end
	if annotation.use_item then
		local code = [[
			AddFunction UseItemActions
			{
				Item(HandSlot usable=1)
				Item(Trinket0Slot usable=1)
				Item(Trinket1Slot usable=1)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		count = count + 1
	end
	if annotation.use_potion_strength then
		local code = [[
			AddFunction UsePotionStrength
			{
				if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "mogu_power_potion")
		count = count + 1
	end
	if annotation.use_potion_intellect then
		local code = [[
			AddFunction UsePotionIntellect
			{
				if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(jade_serpent_potion usable=1)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "jade_serpent_potion")
		count = count + 1
	end
	if annotation.use_potion_armor then
		local code = [[
			AddFunction UsePotionArmor
			{
				if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(mountains_potion usable=1)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "mountains_potion")
		count = count + 1
	end
	if annotation.use_potion_agility then
		local code = [[
			AddFunction UsePotionAgility
			{
				if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "virmens_bite_potion")
		count = count + 1
	end
	return count
end

local function InsertSupportingControls(child, annotation)
	local count = 0
	local nodeList = annotation.astAnnotation.nodeList
	if annotation.trap_launcher == "HUNTER" then
		local code = [[
			AddCheckBox(opt_trap_launcher SpellName(trap_launcher) default)
		]]
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "trap_launcher")
		count = count + 1
	end
	if annotation.time_warp == "MAGE" then
		local code = [[
			AddCheckBox(opt_time_warp SpellName(time_warp) default)
		]]
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "time_warp")
		count = count + 1
	end
	if annotation.tricks_of_the_trade == "ROGUE" then
		local code = [[
			AddCheckBox(opt_tricks_of_the_trade SpellName(tricks_of_the_trade) default)
		]]
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "tricks_of_the_trade")
		count = count + 1
	end
	if annotation.bloodlust == "SHAMAN" then
		local code = [[
			AddCheckBox(opt_bloodlust SpellName(bloodlust) default)
		]]
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "bloodlust")
		count = count + 1
	end
	if annotation.skull_banner == "WARRIOR" then
		local code = [[
			AddCheckBox(opt_skull_banner SpellName(skull_banner) default)
		]]
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "skull_banner")
		count = count + 1
	end
	if annotation.heroic_leap == "WARRIOR" then
		local code = [[
			AddCheckBox(opt_heroic_leap_dps SpellName(heroic_leap) specialization=!protection)
		]]
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "heroic_leap")
		count = count + 1
	end
	if annotation.use_potion_strength then
		local code = [[
			AddCheckBox(opt_potion_strength ItemName(mogu_power_potion) default)
		]]
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "mogu_power_potion")
		count = count + 1
	end
	if annotation.use_potion_intellect then
		local code = [[
			AddCheckBox(opt_potion_intellect ItemName(jade_serpent_potion) default)
		]]
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "jade_serpent_potion")
		count = count + 1
	end
	if annotation.use_potion_armor then
		local code = [[
			AddCheckBox(opt_potion_armor ItemName(mountains_potion) default)
		]]
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "mountains_potion")
		count = count + 1
	end
	if annotation.use_potion_agility then
		local code = [[
			AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)
		]]
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "virmens_bite_potion")
		count = count + 1
	end
	return count
end
--</private-static-methods>

--<public-static-methods>
function OvaleSimulationCraft:OnInitialize()
	-- Resolve module dependencies.
	OvaleAST = Ovale.OvaleAST
	OvaleData = Ovale.OvaleData
	OvaleLexer = Ovale.OvaleLexer

	InitializeDisambiguation()
end

function OvaleSimulationCraft:Debug()
	self_pool:Debug()
	self_childrenPool:Debug()
	self_outputPool:Debug()
end

function OvaleSimulationCraft:ToString(tbl)
	local output = print_r(tbl)
	return tconcat(output, "\n")
end

function OvaleSimulationCraft:Release(profile)
	if profile.annotation then
		local annotation = profile.annotation
		if annotation.astAnnotation then
			OvaleAST:ReleaseAnnotation(annotation.astAnnotation)
		end
		if annotation.nodeList then
			for _, node in ipairs(annotation.nodeList) do
				self_pool:Release(node)
			end
		end
		for key, value in pairs(annotation) do
			if type(value) == "table" then
				wipe(value)
			end
			annotation[key] = nil
		end
		profile.annotation = nil
	end
	profile.actionList = nil
end

function OvaleSimulationCraft:ParseProfile(simc)
	local profile = {}
	for line in gmatch(simc, "[^\r\n]+") do
		-- Trim leading and trailing whitespace.
		line = strmatch(line, "^%s*(.-)%s*$")
		if not (strmatch(line, "^#.*") or strmatch(line, "^$")) then
			-- Line is not a comment or an empty string.
			local key, operator, value = strmatch(line, "([^%+=]+)(%+?=)(.*)")
			if operator == "=" then
				profile[key] = value
			elseif operator == "+=" then
				if type(profile[key]) ~= "table" then
					local oldValue = profile[key]
					profile[key] = {}
					tinsert(profile[key], oldValue)
				end
				tinsert(profile[key], value)
			end
		end
	end
	-- Concatenate variables defined over multiple lines using +=
	for k, v in pairs(profile) do
		if type(v) == "table" then
			profile[k] = tconcat(v)
		end
	end
	-- Parse the action lists.
	local ok = true
	local annotation = {}
	local nodeList = {}
	local actionList = {}
	for k, v in pairs(profile) do
		if ok and strmatch(k, "^actions") then
			local name = strmatch(k, "^actions%.([%w_]+)") or "default"
			local node
			ok, node = ParseActionList(name, v, nodeList, annotation)
			if ok then
				actionList[#actionList + 1] = node
			else
				break
			end
		end
	end
	-- Set the name, class, and specialization from the profile.
	for class in pairs(RAID_CLASS_COLORS) do
		local lowerClass = strlower(class)
		if profile[lowerClass] then
			annotation.class = class
			annotation.name = profile[lowerClass]
		end
	end
	annotation.specialization = profile.spec
	ok = ok and (annotation.class and annotation.specialization)
	annotation.pet = profile.default_pet

	profile.actionList = actionList
	profile.annotation = annotation
	annotation.nodeList = nodeList

	if not ok then
		self:Release(profile)
		profile = nil
	end
	return profile
end

function OvaleSimulationCraft:Unparse(profile)
	local output = self_outputPool:Get()
	if profile.actionList then
		for _, node in ipairs(profile.actionList) do
			output[#output + 1] = Unparse(node)
		end
	end
	local s = tconcat(output, "\n")
	self_outputPool:Release(output)
	return s
end

function OvaleSimulationCraft:Emit(profile)
	local nodeList = {}
	local ast = OvaleAST:NewNode(nodeList, true)
	ast.type = "script"

	local annotation = profile.annotation
	if profile.actionList then
		local child = ast.child
		annotation.astAnnotation = annotation.astAnnotation or {}
		annotation.astAnnotation.nodeList = nodeList
		for _, node in ipairs(profile.actionList) do
			local declarationNode = EmitActionList(node, nodeList, annotation)
			if declarationNode then
				child[#child + 1] = declarationNode
			end
		end
		annotation.supportingFunctionCount = InsertSupportingFunctions(child, annotation)
		annotation.supportingControlCount = InsertSupportingControls(child, annotation)
	end

	local output = self_outputPool:Get()
	-- Prepend a comment block header for the script.
	do
		output[#output + 1] = "# Based on SimulationCraft profile " .. annotation.name .. "."
		output[#output + 1] = "#	class=" .. strlower(annotation.class)
		output[#output + 1] = "#	spec=" .. annotation.specialization
		if profile.talents then
			output[#output + 1] = "#	talents=" .. profile.talents
		end
		if profile.glyphs then
			output[#output + 1] = "#	glyphs=" .. profile.glyphs
		end
		if profile.default_pet then
			output[#output + 1] = "#	pet=" .. profile.default_pet
		end
	end
	-- Includes.
	do
		output[#output + 1] = ""
		output[#output + 1] = "Include(ovale_common)"
		output[#output + 1] = format("Include(ovale_%s_spells)", strlower(annotation.class))
		-- Insert an extra blank line to separate section for controls from the includes.
		if annotation.supportingControlCount > 0 then
			output[#output + 1] = ""
		end
	end
	-- Output the script itself.
	output[#output + 1] = OvaleAST:Unparse(ast)
	-- Output a simplistic two-icon layout for the rotation.
	do
		-- Single-target rotation.
		output[#output + 1] = ""
		output[#output + 1] = format("AddIcon specialization=%s help=main enemies=1", annotation.specialization)
		output[#output + 1] = "{"
		if profile["actions.precombat"] then
			output[#output + 1] = format("	if InCombat(no) %s()", OvaleFunctionName("precombat", annotation.class, annotation.specialization))
		end
		output[#output + 1] = format("	%s()", OvaleFunctionName("default", annotation.class, annotation.specialization))
		output[#output + 1] = "}"
		-- AoE rotation.
		output[#output + 1] = ""
		output[#output + 1] = format("AddIcon specialization=%s help=aoe", annotation.specialization)
		output[#output + 1] = "{"
		if profile["actions.precombat"] then
			output[#output + 1] = format("	if InCombat(no) %s()", OvaleFunctionName("precombat", annotation.class, annotation.specialization))
		end
		output[#output + 1] = format("	%s()", OvaleFunctionName("default", annotation.class, annotation.specialization))
		output[#output + 1] = "}"
	end
	-- Append the required symbols for the script.
	if profile.annotation.symbolTable then
		output[#output + 1] = ""
		output[#output + 1] = "### Required symbols"
		tsort(profile.annotation.symbolTable)
		for _, symbol in ipairs(profile.annotation.symbolTable) do
			output[#output + 1] = "# " .. symbol
		end
	end
	local s = tconcat(output, "\n")
	self_outputPool:Release(output)
	return s
end
--</public-static-methods>
