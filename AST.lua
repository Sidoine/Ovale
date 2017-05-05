--[[--------------------------------------------------------------------
    Copyright (C) 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

--[[----------------------------------------------------------------------------
	This module implements a parser that generates an abstract syntax tree (AST)
	from an Ovale script.

	An AST data structure is a table with the following public properties:

		ast.annotation
		ast.annotation.customFunction
		ast.annotation.definition
		ast.annotation.functionCall
		ast.child
--]]----------------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleAST = Ovale:NewModule("OvaleAST")
Ovale.OvaleAST = OvaleAST

--<private-static-properties>
local L = Ovale.L
local OvalePool = Ovale.OvalePool
local OvaleProfiler = Ovale.OvaleProfiler

-- Forward declarations for module dependencies.
local OvaleCondition = nil
local OvaleLexer = nil
local OvaleScripts = nil
local OvaleSpellBook = nil
local OvaleStance = nil

local format = string.format
local gsub = string.gsub
local ipairs = ipairs
local next = next
local pairs = pairs
local rawset = rawset
local setmetatable = setmetatable
local strlower = string.lower
local strsub = string.sub
local tconcat = table.concat
local tinsert = table.insert
local tonumber = tonumber
local tostring = tostring
local tsort = table.sort
local type = type
local wipe = wipe
local yield = coroutine.yield
local API_GetItemInfo = GetItemInfo

-- Register for profiling.
OvaleProfiler:RegisterProfiling(OvaleAST)

-- Keywords for the Ovale script language.
local KEYWORD = {
	["and"] = true,
	["if"] = true,
	["not"] = true,
	["or"] = true,
	["unless"] = true,
}

local DECLARATION_KEYWORD = {
	["AddActionIcon"] = true,
	["AddCheckBox"] = true,
	["AddFunction"] = true,
	["AddIcon"] = true,
	["AddListItem"] = true,
	["Define"] = true,
	["Include"] = true,
	["ItemInfo"] = true,
	["ItemRequire"] = true,
	["ItemList"] = true,
	["ScoreSpells"] = true,
	["SpellInfo"] = true,
	["SpellList"] = true,
	["SpellRequire"] = true,
}

local PARAMETER_KEYWORD = {
	["checkbox"] = true,
	["help"] = true,
	["if_buff"] = true,
	["if_equipped"] = true,
	["if_spell"] = true,
	["if_stance"] = true,
	["if_target_debuff"] = true,
	["itemcount"] = true,
	["itemset"] = true,
	["level"] = true,
	["listitem"] = true,
	["pertrait"] = true,
	["specialization"] = true,
	["talent"] = true,
	["trait"] = true,
	["text"] = true,
	["wait"] = true,
}

local SPELL_AURA_KEYWORD = {
	["SpellAddBuff"] = true,
	["SpellAddDebuff"] = true,
	["SpellAddPetBuff"] = true,
	["SpellAddPetDebuff"] = true,
	["SpellAddTargetBuff"] = true,
	["SpellAddTargetDebuff"] = true,
	["SpellDamageBuff"] = true,
	["SpellDamageDebuff"] = true,
}

local STANCE_KEYWORD = {
	["if_stance"] = true,
	["stance"] = true,
	["to_stance"] = true,
}

do
	-- SpellAuraList keywords are declaration keywords.
	for keyword, value in pairs(SPELL_AURA_KEYWORD) do
		DECLARATION_KEYWORD[keyword] = value
	end
	-- All keywords are Ovale script keywords.
	for keyword, value in pairs(DECLARATION_KEYWORD) do
		KEYWORD[keyword] = value
	end
	for keyword, value in pairs(PARAMETER_KEYWORD) do
		KEYWORD[keyword] = value
	end
end

-- Table of pattern/tokenizer pairs for the Ovale script language.
local MATCHES = nil

-- Functions that are actions; ACTION_PARAMETER_COUNT[action] = number of required parameters
local ACTION_PARAMETER_COUNT = {
	["item"] = 1,
	["macro"] = 1,
	["spell"] = 1,
	["texture"] = 1,
	["setstate"] = 2,
}

-- Actions that are special "state" actions and return no other relevant action information.
local STATE_ACTION = {
	["setstate"] = true,
}
-- Functions for accessing string databases.
local STRING_LOOKUP_FUNCTION = {
	["ItemName"] = true,
	["L"] = true,
	["SpellName"] = true,
}

-- Unary and binary operators with precedence.
local UNARY_OPERATOR = {
	["not"] = { "logical", 15 },
	["-"]   = { "arithmetic", 50 },
}
local BINARY_OPERATOR = {
	-- logical
	["or"]  = { "logical", 5, "associative" },
	["xor"]	= { "logical", 8, "associative" },
	["and"] = { "logical", 10, "associative" },
	-- comparison
	["!="]  = { "compare", 20 },
	["<"]   = { "compare", 20 },
	["<="]  = { "compare", 20 },
	["=="]  = { "compare", 20 },
	[">"]   = { "compare", 20 },
	[">="]  = { "compare", 20 },
	-- addition, subtraction
	["+"]   = { "arithmetic", 30, "associative" },
	["-"]   = { "arithmetic", 30 },
	-- multiplication, division, modulus
	["%"]   = { "arithmetic", 40 },
	["*"]   = { "arithmetic", 40, "associative" },
	["/"]   = { "arithmetic", 40 },
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

local self_indent = 0
local self_outputPool = OvalePool("OvaleAST_outputPool")

local self_controlPool = OvalePool("OvaleAST_controlPool")
local self_parametersPool = OvalePool("OvaleAST_parametersPool")
local self_childrenPool = OvalePool("OvaleAST_childrenPool")
local self_postOrderPool = OvalePool("OvaleAST_postOrderPool")
local self_pool = OvalePool("OvaleAST_pool")
do
	self_pool.Clean = function(self, node)
		if node.child then
			self_childrenPool:Release(node.child)
			node.child = nil
		end
		if node.postOrder then
			self_postOrderPool:Release(node.postOrder)
			node.postOrder = nil
		end
	end
end
--</private-static-properties>

--<public-static-properties>
-- Export list of parameters keywords.
OvaleAST.PARAMETER_KEYWORD = PARAMETER_KEYWORD
--</public-static-properties>

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
				if value.type then
					tinsert(output, indent .. "[" .. tostring(key) .. "] =>")
				else
					tinsert(output, indent .. "[" .. tostring(key) .. "] => {")
				end
				print_r(value, indent .. "    ", done, output)
				if not value.type then
					tinsert(output, indent .. "}")
				end
			end
		else
			tinsert(output, indent .. "[" .. tostring(key) .. "] => " .. tostring(value))
		end
	end
	return output
end

-- Follow the flyweight pattern for number nodes.
local function GetNumberNode(value, nodeList, annotation)
	-- Check for a flyweight node with this exact numerical value.
	annotation.numberFlyweight = annotation.numberFlyweight or {}
	local node = annotation.numberFlyweight[value]
	if not node then
		node = OvaleAST:NewNode(nodeList)
		node.type = "value"
		node.value = value
		node.origin = 0
		node.rate = 0
		-- Store the first node with this exact numerical value in numberFlyweight.
		annotation.numberFlyweight[value] = node
	end
	return node
end

--[[
	Fill an array of nodes in order of post-order traversal.
	The odd indices hold the nodes in post-order traversal order.
	The even indices hold the parents of the node in the preceding indices.
--]]
local function PostOrderTraversal(node, array, visited)
	if node.child then
		for _, childNode in ipairs(node.child) do
			if not visited[childNode] then
				PostOrderTraversal(childNode, array, visited)
				-- Insert the current node as the parent of the preceding child node.
				array[#array + 1] = node
			end
		end
	end
	array[#array + 1] = node
	visited[node] = true
end

--[[---------------------------------------------
	Lexer functions (for use with OvaleLexer)
--]]---------------------------------------------
local function TokenizeComment(token)
	return yield("comment", token)
end

local function TokenizeLua(token, options)
	-- Strip off leading [[ and trailing ]].
	token = strsub(token, 3, -3)
	return yield("lua", token)
end

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

local function TokenizeString(token, options)
	-- Strip leading and trailing quote characters.
	if options and options.string then
		token = strsub(token, 2, -2)
	end
	return yield("string", token)
end

local function TokenizeWhitespace(token)
	return yield("space", token)
end

local function Tokenize(token)
	return yield(token, token)
end

local function NoToken()
	return yield(nil)
end

do
	MATCHES = {
		{ "^%s+", TokenizeWhitespace },
		{ "^%d+%.?%d*", TokenizeNumber },
		{ "^[%a_][%w_]*", TokenizeName },
		{ "^((['\"])%2)", TokenizeString },	-- empty string
		{ [[^(['\"]).-\\%1]], TokenizeString },
		{ [[^(['\"]).-[^\]%1]], TokenizeString },
		{ "^#.-\n", TokenizeComment },
		{ "^!=", Tokenize },
		{ "^==", Tokenize },
		{ "^<=", Tokenize },
		{ "^>=", Tokenize },
		{ "^.", Tokenize },
		{ "^$", NoToken },
	}
end

local function GetTokenIterator(s)
	local exclude = { space = true, comments = true }
	do
		-- Fix some API brokenness in the Penlight lexer.
		if exclude.space then
			exclude[TokenizeWhitespace] = true
		end
		if exclude.comments then
			exclude[TokenizeComment] = true
		end
	end
	return OvaleLexer.scan(s, MATCHES, exclude)
end

-- "Flatten" a parameter value node into a string, or a table of strings if it is a comma-separated value.
local function FlattenParameterValue(parameterValue, annotation)
	local value = parameterValue
	if type(parameterValue) == "table" then
		local node = parameterValue
		if node.type == "comma_separated_values" then
			value = self_parametersPool:Get()
			for k, v in ipairs(node.csv) do
				value[k] = FlattenParameterValue(v, annotation)
			end
			annotation.parametersList = annotation.parametersList or {}
			annotation.parametersList[#annotation.parametersList + 1] = value
		else
			local isBang = false
			if node.type == "bang_value" then
				isBang = true
				node = node.child[1]
			end
			if node.type == "value" then
				value = node.value
			elseif node.type == "variable" then
				value = node.name
			elseif node.type == "string" then
				value = node.value
			end
			if isBang then
				value = "!" .. tostring(value)
			end
		end
	end
	return value
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

local function HasParameters(node)
	return node.rawPositionalParams and next(node.rawPositionalParams) or node.rawNamedParams and next(node.rawNamedParams)
end

-- Forward declarations of functions needed to implement the recursive unparser.
local UNPARSE_VISITOR = nil
local Unparse = nil
local UnparseAddCheckBox = nil
local UnparseAddFunction = nil
local UnparseAddIcon = nil
local UnparseAddListItem = nil
local UnparseBangValue = nil
local UnparseComment = nil
local UnparseCommaSeparatedValues = nil
local UnparseDefine = nil
local UnparseExpression = nil
local UnparseFunction = nil
local UnparseGroup = nil
local UnparseIf = nil
local UnparseItemInfo = nil
local UnparseItemRequire = nil
local UnparseList = nil
local UnparseNumber = nil
local UnparseParameters = nil
local UnparseScoreSpells = nil
local UnparseScript = nil
local UnparseSpellAuraList = nil
local UnparseSpellInfo = nil
local UnparseSpellRequire = nil
local UnparseString = nil
local UnparseUnless = nil
local UnparseVariable = nil

Unparse = function(node)
	if node.asString then
		-- Return cached string representation if present.
		return node.asString
	else
		local visitor
		if node.previousType then
			visitor = UNPARSE_VISITOR[node.previousType]
		else
			visitor = UNPARSE_VISITOR[node.type]
		end
		if not visitor then
			OvaleAST:Error("Unable to unparse node of type '%s'.", node.type)
		else
			return visitor(node)
		end
	end
end

UnparseAddCheckBox = function(node)
	local s
	if node.rawPositionalParams and next(node.rawPositionalParams) or node.rawNamedParams and next(node.rawNamedParams) then
		s = format("AddCheckBox(%s %s %s)", node.name, Unparse(node.description), UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
	else
		s = format("AddCheckBox(%s %s)", node.name, Unparse(node.description))
	end
	return s
end

UnparseAddFunction = function(node)
	local s
	if HasParameters(node) then
		s = format("AddFunction %s %s%s", node.name, UnparseParameters(node.rawPositionalParams, node.rawNamedParams), UnparseGroup(node.child[1]))
	else
		s = format("AddFunction %s%s", node.name, UnparseGroup(node.child[1]))
	end
	return s
end

UnparseAddIcon = function(node)
	local s
	if HasParameters(node) then
		s = format("AddIcon %s%s", UnparseParameters(node.rawPositionalParams, node.rawNamedParams), UnparseGroup(node.child[1]))
	else
		s = format("AddIcon%s", UnparseGroup(node.child[1]))
	end
	return s
end

UnparseAddListItem = function(node)
	local s
	if HasParameters(node) then
		s = format("AddListItem(%s %s %s %s)", node.name, node.item, Unparse(node.description), UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
	else
		s = format("AddListItem(%s %s %s)", node.name, node.item, Unparse(node.description))
	end
	return s
end

UnparseBangValue = function(node)
	return "!" .. Unparse(node.child[1])
end

UnparseComment = function(node)
	if not node.comment or node.comment == "" then
		return ""
	else
		return "#" .. node.comment
	end
end

UnparseCommaSeparatedValues = function(node)
	local output = self_outputPool:Get()
	for k, v in ipairs(node.csv) do
		output[k] = Unparse(v)
	end
	local outputString = tconcat(output, ",")
	self_outputPool:Release(output)
	return outputString
end

UnparseDefine = function(node)
	return format("Define(%s %s)", node.name, node.value)
end

UnparseExpression = function(node)
	local expression
	local precedence = GetPrecedence(node)
	if node.expressionType == "unary" then
		local rhsExpression
		local rhsNode = node.child[1]
		local rhsPrecedence = GetPrecedence(rhsNode)
		if rhsPrecedence and precedence >= rhsPrecedence then
			rhsExpression = "{ " .. Unparse(rhsNode) .. " }"
		else
			rhsExpression = Unparse(rhsNode)
		end
		if node.operator == "-" then
			expression = "-" .. rhsExpression
		else
			expression = node.operator .. " " .. rhsExpression
		end
	elseif node.expressionType == "binary" then
		local lhsExpression, rhsExpression
		local lhsNode = node.child[1]
		local lhsPrecedence = GetPrecedence(lhsNode)
		if lhsPrecedence and lhsPrecedence < precedence then
			lhsExpression = "{ " .. Unparse(lhsNode) .. " }"
		else
			lhsExpression = Unparse(lhsNode)
		end
		local rhsNode = node.child[2]
		local rhsPrecedence = GetPrecedence(rhsNode)
		if rhsPrecedence and precedence > rhsPrecedence then
			rhsExpression = "{ " .. Unparse(rhsNode) .. " }"
		elseif rhsPrecedence and precedence == rhsPrecedence then
			if BINARY_OPERATOR[node.operator][3] == "associative" and node.operator == rhsNode.operator then
				rhsExpression = Unparse(rhsNode)
			else
				rhsExpression = "{ " .. Unparse(rhsNode) .. " }"
			end
		else
			rhsExpression = Unparse(rhsNode)
		end
		expression = lhsExpression .. " " .. node.operator .. " " .. rhsExpression
	end
	return expression
end

UnparseFunction = function(node)
	local s
	if HasParameters(node) then
		local name
		local filter = node.rawNamedParams.filter
		if filter == "debuff" then
			name = gsub(node.name, "^Buff", "Debuff")
		else
			name = node.name
		end
		local target = node.rawNamedParams.target
		if target then
			s = format("%s.%s(%s)", target, name, UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
		else
			s = format("%s(%s)", name, UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
		end
	else
		s = format("%s()", node.name)
	end
	return s
end

UnparseGroup = function(node)
	local output = self_outputPool:Get()
	output[#output + 1] = ""
	output[#output + 1] = INDENT[self_indent] .. "{"
	self_indent = self_indent + 1
	for _, statementNode in ipairs(node.child) do
		local s = Unparse(statementNode)
		if s == "" then
			output[#output + 1] = s
		else
			output[#output + 1] = INDENT[self_indent] .. s
		end
	end
	self_indent = self_indent - 1
	output[#output + 1] = INDENT[self_indent] .. "}"

	local outputString = tconcat(output, "\n")
	self_outputPool:Release(output)
	return outputString
end

UnparseIf = function(node)
	if node.child[2].type == "group" then
		return format("if %s%s", Unparse(node.child[1]), UnparseGroup(node.child[2]))
	else
		return format("if %s %s", Unparse(node.child[1]), Unparse(node.child[2]))
	end
end

UnparseItemInfo = function(node)
	local identifier = node.name and node.name or node.itemId
	return format("ItemInfo(%s %s)", identifier, UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
end

UnparseItemRequire = function(node)
	local identifier = node.name and node.name or node.itemId
	return format("ItemRequire(%s %s %s)", identifier, node.property, UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
end

UnparseList = function(node)
	return format("%s(%s %s)", node.keyword, node.name, UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
end

UnparseNumber = function(node)
	return tostring(node.value)
end

UnparseParameters = function(positionalParams, namedParams)
	local output = self_outputPool:Get()
	for k, v in pairs(namedParams) do
		if k == "checkbox" then
			for _, name in ipairs(v) do
				output[#output + 1] = format("checkbox=%s", Unparse(name))
			end
		elseif k == "listitem" then
			for list, item in pairs(v) do
				output[#output + 1] = format("listitem=%s:%s", list, Unparse(item))
			end
		elseif type(v) == "table" then
			output[#output + 1] = format("%s=%s", k, Unparse(v))
		elseif k == "filter" or k == "target" then
			-- Skip output of "filter" or "target".
		else
			output[#output + 1] = format("%s=%s", k, v)
		end
	end
	tsort(output)
	for k = #positionalParams, 1, -1 do
		tinsert(output, 1, Unparse(positionalParams[k]))
	end
	local outputString = tconcat(output, " ")
	self_outputPool:Release(output)
	return outputString
end

UnparseScoreSpells = function(node)
	return format("ScoreSpells(%s)", UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
end

UnparseScript = function(node)
	local output = self_outputPool:Get()
	local previousDeclarationType
	for _, declarationNode in ipairs(node.child) do
		if declarationNode.type == "item_info" or declarationNode.type == "spell_aura_list" or declarationNode.type == "spell_info" or declarationNode.type == "spell_require" then
			local s = Unparse(declarationNode)
			if s == "" then
				output[#output + 1] = s
			else
				output[#output + 1] = INDENT[self_indent + 1] .. s
			end
		else
			local insertBlank = false
			-- Add an extra blank line if the type is different from the previous type.
			if previousDeclarationType and previousDeclarationType ~= declarationNode.type then
				insertBlank = true
			end
			-- Always an extra blank line preceding "AddFunction" or "AddIcon".
			if declarationNode.type == "add_function" or declarationNode.type == "icon" then
				insertBlank = true
			end
			if insertBlank then
				output[#output + 1] = ""
			end
			output[#output + 1] = Unparse(declarationNode)
			previousDeclarationType = declarationNode.type
		end
	end
	local outputString = tconcat(output, "\n")
	self_outputPool:Release(output)
	return outputString
end

UnparseSpellAuraList = function(node)
	local identifier = node.name and node.name or node.spellId
	return format("%s(%s %s)", node.keyword, identifier, UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
end

UnparseSpellInfo = function(node)
	local identifier = node.name and node.name or node.spellId
	return format("SpellInfo(%s %s)", identifier, UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
end

UnparseSpellRequire = function(node)
	local identifier = node.name and node.name or node.spellId
	return format("SpellRequire(%s %s %s)", identifier, node.property, UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
end

UnparseString = function(node)
	return '"' .. node.value .. '"'
end

UnparseUnless = function(node)
	if node.child[2].type == "group" then
		return format("unless %s%s", Unparse(node.child[1]), UnparseGroup(node.child[2]))
	else
		return format("unless %s %s", Unparse(node.child[1]), Unparse(node.child[2]))
	end
end

UnparseVariable = function(node)
	return node.name
end

do
	UNPARSE_VISITOR = {
		["action"] = UnparseFunction,
		["add_function"] = UnparseAddFunction,
		["arithmetic"] = UnparseExpression,
		["bang_value"] = UnparseBangValue,
		["checkbox"] = UnparseAddCheckBox,
		["compare"] = UnparseExpression,
		["comma_separated_values"] = UnparseCommaSeparatedValues,
		["comment"] = UnparseComment,
		["custom_function"] = UnparseFunction,
		["define"] = UnparseDefine,
		["function"] = UnparseFunction,
		["group"] = UnparseGroup,
		["icon"] = UnparseAddIcon,
		["if"] = UnparseIf,
		["item_info"] = UnparseItemInfo,
		["item_require"] = UnparseItemRequire,
		["list"] = UnparseList,
		["list_item"] = UnparseAddListItem,
		["logical"] = UnparseExpression,
		["score_spells"] = UnparseScoreSpells,
		["script"] = UnparseScript,
		["spell_aura_list"] = UnparseSpellAuraList,
		["spell_info"] = UnparseSpellInfo,
		["spell_require"] = UnparseSpellRequire,
		["state"] = UnparseFunction,
		["string"] = UnparseString,
		["unless"] = UnparseUnless,
		["value"] = UnparseNumber,
		["variable"] = UnparseVariable,
	}
end

--[[--------------------
	Parser functions
--]]--------------------

-- Prints the error message and the next 20 tokens from tokenStream.
local function SyntaxError(tokenStream, ...)
	OvaleAST:Print(...)
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
	OvaleAST:Print(tconcat(context, " "))
end

-- Forward declarations of parser functions needed to implement a recursive descent parser.
local PARSE_VISITOR = nil
local Parse = nil
local ParseAddCheckBox = nil
local ParseAddFunction = nil
local ParseAddIcon = nil
local ParseAddListItem = nil
local ParseDeclaration = nil
local ParseDefine = nil
local ParseExpression = nil
local ParseFunction = nil
local ParseGroup = nil
local ParseIf = nil
local ParseInclude = nil
local ParseItemInfo = nil
local ParseItemRequire = nil
local ParseList = nil
local ParseNumber = nil
local ParseParameterValue = nil
local ParseParameters = nil
local ParseParentheses = nil
local ParseScoreSpells = nil
local ParseScript = nil
local ParseSimpleExpression = nil
local ParseSimpleParameterValue = nil
local ParseSpellAuraList = nil
local ParseSpellInfo = nil
local ParseSpellRequire = nil
local ParseString = nil
local ParseStatement = nil
local ParseUnless = nil
local ParseVariable = nil

Parse = function(nodeType, tokenStream, nodeList, annotation)
	local visitor = PARSE_VISITOR[nodeType]
	if not visitor then
		OvaleAST:Error("Unable to parse node of type '%s'.", nodeType)
	else
		return visitor(tokenStream, nodeList, annotation)
	end
end

ParseAddCheckBox = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the 'AddCheckBox' token.
	do
		local tokenType, token = tokenStream:Consume()
		if not (tokenType == "keyword" and token == "AddCheckBox") then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; 'AddCheckBox' expected.", token)
			ok = false
		end
	end
	-- Consume the left parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "(" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; '(' expected.", token)
			ok = false
		end
	end
	-- Consume the checkbox name.
	local name
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; name expected.", token)
			ok = false
		end
	end
	-- Consume the description string.
	local descriptionNode
	if ok then
		ok, descriptionNode = ParseString(tokenStream, nodeList, annotation)
	end
	-- Consume any parameters.
	local parameters
	local positionalParams, namedParams
	if ok then
		ok, positionalParams, namedParams = ParseParameters(tokenStream, nodeList, annotation)
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= ")" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; ')' expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList)
		node.type = "checkbox"
		node.name = name
		node.description = descriptionNode
		node.rawPositionalParams = positionalParams
		node.rawNamedParams = namedParams
		annotation.parametersReference = annotation.parametersReference or {}
		annotation.parametersReference[#annotation.parametersReference + 1] = node
	end
	return ok, node
end

ParseAddFunction = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the 'AddFunction' token.
	local tokenType, token = tokenStream:Consume()
	if not (tokenType == "keyword" and token == "AddFunction") then
		SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; 'AddFunction' expected.", token)
		ok = false
	end
	-- Consume the function name.
	local name
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; name expected.", token)
			ok = false
		end
	end
	-- Consume any parameters.
	local positionalParams, namedParams
	if ok then
		ok, positionalParams, namedParams = ParseParameters(tokenStream, nodeList, annotation)
	end
	-- Consume the body.
	local bodyNode
	if ok then
		ok, bodyNode = ParseGroup(tokenStream, nodeList, annotation)
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList, true)
		node.type = "add_function"
		node.name = name
		node.child[1] = bodyNode
		node.rawPositionalParams = positionalParams
		node.rawNamedParams = namedParams
		annotation.parametersReference = annotation.parametersReference or {}
		annotation.parametersReference[#annotation.parametersReference + 1] = node
		-- Add the postOrder list to the body node.
		annotation.postOrderReference = annotation.postOrderReference or {}
		annotation.postOrderReference[#annotation.postOrderReference + 1] = bodyNode
		annotation.customFunction = annotation.customFunction or {}
		annotation.customFunction[name] = node
	end
	return ok, node
end

ParseAddIcon = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the 'AddIcon' token.
	local tokenType, token = tokenStream:Consume()
	if not (tokenType == "keyword" and token == "AddIcon") then
		SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDICON; 'AddIcon' expected.", token)
		ok = false
	end
	-- Consume any parameters.
	local positionalParams, namedParams
	if ok then
		ok, positionalParams, namedParams = ParseParameters(tokenStream, nodeList, annotation)
	end
	-- Consume the body.
	local bodyNode
	if ok then
		ok, bodyNode = ParseGroup(tokenStream, nodeList, annotation)
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList, true)
		node.type = "icon"
		node.child[1] = bodyNode
		node.rawPositionalParams = positionalParams
		node.rawNamedParams = namedParams
		annotation.parametersReference = annotation.parametersReference or {}
		annotation.parametersReference[#annotation.parametersReference + 1] = node
		-- Add the postOrder list to the body node.
		annotation.postOrderReference = annotation.postOrderReference or {}
		annotation.postOrderReference[#annotation.postOrderReference + 1] = bodyNode
	end
	return ok, node
end

ParseAddListItem = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the 'AddListItem' token.
	do
		local tokenType, token = tokenStream:Consume()
		if not (tokenType == "keyword" and token == "AddListItem") then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; 'AddListItem' expected.", token)
			ok = false
		end
	end
	-- Consume the left parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "(" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; '(' expected.", token)
			ok = false
		end
	end
	-- Consume the list name.
	local name
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.", token)
			ok = false
		end
	end
	-- Consume the item name.
	local item
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "name" then
			item = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.", token)
			ok = false
		end
	end
	-- Consume the description string.
	local descriptionNode
	if ok then
		ok, descriptionNode = ParseString(tokenStream, nodeList, annotation)
	end
	-- Consume any parameters.
	local positionalParams, namedParams
	if ok then
		ok, positionalParams, namedParams = ParseParameters(tokenStream, nodeList, annotation)
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= ")" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; ')' expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList)
		node.type = "list_item"
		node.name = name
		node.item = item
		node.description = descriptionNode
		node.rawPositionalParams = positionalParams
		node.rawNamedParams = namedParams
		annotation.parametersReference = annotation.parametersReference or {}
		annotation.parametersReference[#annotation.parametersReference + 1] = node
	end
	return ok, node
end

ParseDeclaration = function(tokenStream, nodeList, annotation)
	local ok = true
	local node
	local tokenType, token = tokenStream:Peek()
	if tokenType == "keyword" and DECLARATION_KEYWORD[token] then
		if token == "AddCheckBox" then
			ok, node = ParseAddCheckBox(tokenStream, nodeList, annotation)
		elseif token == "AddFunction" then
			ok, node = ParseAddFunction(tokenStream, nodeList, annotation)
		elseif token == "AddIcon" then
			ok, node = ParseAddIcon(tokenStream, nodeList, annotation)
		elseif token == "AddListItem" then
			ok, node = ParseAddListItem(tokenStream, nodeList, annotation)
		elseif token == "Define" then
			ok, node = ParseDefine(tokenStream, nodeList, annotation)
		elseif token == "Include" then
			ok, node = ParseInclude(tokenStream, nodeList, annotation)
		elseif token == "ItemInfo" then
			ok, node = ParseItemInfo(tokenStream, nodeList, annotation)
		elseif token == "ItemRequire" then
			ok, node = ParseItemRequire(tokenStream, nodeList, annotation)
		elseif token == "ItemList" then
			ok, node = ParseList(tokenStream, nodeList, annotation)
		elseif token == "ScoreSpells" then
			ok, node = ParseScoreSpells(tokenStream, nodeList, annotation)
		elseif SPELL_AURA_KEYWORD[token] then
			ok, node = ParseSpellAuraList(tokenStream, nodeList, annotation)
		elseif token == "SpellInfo" then
			ok, node = ParseSpellInfo(tokenStream, nodeList, annotation)
		elseif token == "SpellList" then
			ok, node = ParseList(tokenStream, nodeList, annotation)
		elseif token == "SpellRequire" then
			ok, node = ParseSpellRequire(tokenStream, nodeList, annotation)
		end
	else
		SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DECLARATION; declaration keyword expected.", token)
		tokenStream:Consume()
		ok = false
	end
	return ok, node
end

ParseDefine = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the 'Define' token.
	do
		local tokenType, token = tokenStream:Consume()
		if not (tokenType == "keyword" and token == "Define") then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; 'Define' expected.", token)
			ok = false
		end
	end
	-- Consume the left parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "(" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; '(' expected.", token)
			ok = false
		end
	end
	-- Consume the variable name.
	local name
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; name expected.", token)
			ok = false
		end
	end
	-- Consume the value.
	local value
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "-" then
			-- Negative number.
			tokenType, token = tokenStream:Consume()
			if tokenType == "number" then
				-- Elide the unary negation operator into the number.
				value = -1 * tonumber(token)
			else
				SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; number expected after '-'.", token)
				ok = false
			end
		elseif tokenType == "number" then
			value = tonumber(token)
		elseif tokenType == "string" then
			value = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; number or string expected.", token)
			ok = false
		end
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= ")" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; ')' expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList)
		node.type = "define"
		node.name = name
		node.value = value
		annotation.definition = annotation.definition or {}
		annotation.definition[name] = value
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
				tokenStream:Consume()
				local operator = token
				local rhsNode
				ok, rhsNode = ParseExpression(tokenStream, nodeList, annotation, precedence)
				if ok then
					if operator == "-" and rhsNode.type == "value" then
						-- Elide the unary negation operator into the number.
						local value = -1 * rhsNode.value
						node = GetNumberNode(value, nodeList, annotation)
					else
						node = OvaleAST:NewNode(nodeList, true)
						node.type = opType
						node.expressionType = "unary"
						node.operator = operator
						node.precedence = precedence
						node.child[1] = rhsNode
					end
				end
			else
				ok, node = ParseSimpleExpression(tokenStream, nodeList, annotation)
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
				if precedence and precedence > minPrecedence then
					keepScanning = true
					tokenStream:Consume()
					local operator = token
					local lhsNode = node
					local rhsNode
					ok, rhsNode = ParseExpression(tokenStream, nodeList, annotation, precedence)
					if ok then
						node = OvaleAST:NewNode(nodeList, true)
						node.type = opType
						node.expressionType = "binary"
						node.operator = operator
						node.precedence = precedence
						node.child[1] = lhsNode
						node.child[2] = rhsNode
						-- Left-rotate tree to preserve precedence.
						local rotated = false
						while node.type == rhsNode.type and node.operator == rhsNode.operator and BINARY_OPERATOR[node.operator][3] == "associative" and rhsNode.expressionType == "binary" do
							node.child[2] = rhsNode.child[1]
							rhsNode.child[1] = node
							-- Re-cache the string representation for the new LHS node.
							node.asString = UnparseExpression(node)
							-- Re-assign node and RHS node for the following loop.
							node = rhsNode
							rhsNode = node.child[2]
							rotated = true
						end
						if rotated then
							-- Re-cache the string representation for the new top-level expression node.
							node.asString = UnparseExpression(node)
						end
					end
				end
			end
		end
		if not keepScanning then
			break
		end
	end

	if ok and node then
		-- Cache string representation.
		node.asString = node.asString or Unparse(node)
	end
	return ok, node
end

ParseFunction = function(tokenStream, nodeList, annotation)
	local ok = true
	local name, lowername
	-- Consume the name.
	do
		local tokenType, token = tokenStream:Consume()
		if tokenType == "name" then
			name = token
			lowername = strlower(name)
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token)
			ok = false
		end
	end
	-- Check for <target>.<function>.
	local target
	if ok then
		local tokenType, token = tokenStream:Peek()
		if tokenType == "." then
			target = name
			tokenType, token = tokenStream:Consume(2)
			if tokenType == "name" then
				name = token
				lowername = strlower(name)
			else
				SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token)
				ok = false
			end
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
	-- Consume any function parameters.
	local positionalParams, namedParams
	if ok then
		ok, positionalParams, namedParams = ParseParameters(tokenStream, nodeList, annotation)
	end
	-- Verify that an action has the required number of fixed parameters.
	if ok and ACTION_PARAMETER_COUNT[lowername] then
		local count = ACTION_PARAMETER_COUNT[lowername]
		if count > #positionalParams then
			SyntaxError(tokenStream, "Syntax error: action '%s' requires at least %d fixed parameter(s).", name, count)
			ok = false
		end
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= ")" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.", token)
			ok = false
		end
	end
	if ok then
		-- Parse the function name.
		if not namedParams.target then
			-- Auto-set the target if the function name starts with "Target".
			if strsub(lowername, 1, 6) == "target" then
				namedParams.target = "target"
				lowername = strsub(lowername, 7)
				name = strsub(name, 7)
			end
		end
		if not namedParams.filter then
			-- Auto-set the aura filter if the function name starts with "Debuff" or "Buff".
			if strsub(lowername, 1, 6) == "debuff" then
				namedParams.filter = "debuff"
			elseif strsub(lowername, 1, 4) == "buff" then
				namedParams.filter = "buff"
			elseif strsub(lowername, 1, 11) == "otherdebuff" then
				namedParams.filter = "debuff"
			elseif strsub(lowername, 1, 9) == "otherbuff" then
				namedParams.filter = "buff"
			end
		end
		-- Set the target if given in a prefix.
		if target then
			namedParams.target = target
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList)
		node.name = name
		node.lowername = lowername
		if STATE_ACTION[lowername] then
			node.type = "state"
			-- Built-in functions are case-insensitive.
			node.func = lowername
		elseif ACTION_PARAMETER_COUNT[lowername] then
			node.type = "action"
			-- Built-in functions are case-insensitive.
			node.func = lowername
		elseif STRING_LOOKUP_FUNCTION[name] then
			node.type = "function"
			-- String-lookup functions are case-sensitive.
			node.func = name
			annotation.stringReference = annotation.stringReference or {}
			annotation.stringReference[#annotation.stringReference + 1] = node
		elseif OvaleCondition:IsCondition(lowername) then
			node.type = "function"
			-- Built-in functions are case-insensitive.
			node.func = lowername
		else
			node.type = "custom_function"
			-- Script-defined functions are case-sensitive.
			node.func = name
		end
		node.rawPositionalParams = positionalParams
		node.rawNamedParams = namedParams
		-- Cache string representation.
		node.asString = UnparseFunction(node)
		annotation.parametersReference = annotation.parametersReference or {}
		annotation.parametersReference[#annotation.parametersReference + 1] = node
		annotation.functionCall = annotation.functionCall or {}
		annotation.functionCall[node.func] = true
		annotation.functionReference = annotation.functionReference or {}
		annotation.functionReference[#annotation.functionReference + 1] = node
	end
	return ok, node
end

ParseGroup = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the left brace.
	do
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "{" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '{' expected.", token)
			ok = false
		end
	end
	-- Consume any statements up to the matching right brace.
	local child = self_childrenPool:Get()
	local tokenType, token = tokenStream:Peek()
	while ok and tokenType and tokenType ~= "}" do
		local statementNode
		ok, statementNode = ParseStatement(tokenStream, nodeList, annotation)
		if ok then
			child[#child + 1] = statementNode
			tokenType, token = tokenStream:Peek()
		else
			break
		end
	end
	-- Consume the right brace.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "}" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '}' expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList)
		node.type = "group"
		node.child = child
	else
		self_childrenPool:Release(child)
	end
	return ok, node
end

ParseIf = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the 'if' token.
	do
		local tokenType, token = tokenStream:Consume()
		if not (tokenType == "keyword" and token == "if") then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing IF; 'if' expected.", token)
			ok = false
		end
	end
	-- Consume the condition and body.
	local conditionNode, bodyNode
	if ok then
		ok, conditionNode = ParseExpression(tokenStream, nodeList, annotation)
	end
	if ok then
		ok, bodyNode = ParseStatement(tokenStream, nodeList, annotation)
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList, true)
		node.type = "if"
		node.child[1] = conditionNode
		node.child[2] = bodyNode
	end
	return ok, node
end

ParseInclude = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the 'Include' token.
	do
		local tokenType, token = tokenStream:Consume()
		if not (tokenType == "keyword" and token == "Include") then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; 'Include' expected.", token)
			ok = false
		end
	end
	-- Consume the left parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "(" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; '(' expected.", token)
			ok = false
		end
	end
	-- Consume the script name.
	local name
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; script name expected.", token)
			ok = false
		end
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= ")" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; ')' expected.", token)
			ok = false
		end
	end
	-- Get the code associated with the script name.
	local code = OvaleScripts:GetScript(name)
	if not code then
		OvaleAST:Error("Script '%s' not found when parsing INCLUDE.", name)
		ok = false
	end
	-- Create the AST node.
	local node
	if ok then
		local includeTokenStream = OvaleLexer(name, GetTokenIterator(code))
		ok, node = ParseScript(includeTokenStream, nodeList, annotation)
		includeTokenStream:Release()
	end
	return ok, node
end

ParseItemInfo = function(tokenStream, nodeList, annotation)
	local ok = true
	local name, lowername
	-- Consume the 'ItemInfo' token.
	do
		local tokenType, token = tokenStream:Consume()
		if not (tokenType == "keyword" and token == "ItemInfo") then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; 'ItemInfo' expected.", token)
			ok = false
		end
	end
	-- Consume the left parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "(" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; '(' expected.", token)
			ok = false
		end
	end
	-- Consume the item ID.
	local itemId, name
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "number" then
			itemId = token
		elseif tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; number or name expected.", token)
			ok = false
		end
	end
	-- Consume any ItemInfo parameters.
	local positionalParams, namedParams
	if ok then
		ok, positionalParams, namedParams = ParseParameters(tokenStream, nodeList, annotation)
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= ")" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; ')' expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList)
		node.type = "item_info"
		node.itemId = itemId
		node.name = name
		node.rawPositionalParams = positionalParams
		node.rawNamedParams = namedParams
		annotation.parametersReference = annotation.parametersReference or {}
		annotation.parametersReference[#annotation.parametersReference + 1] = node
		if name then
			annotation.nameReference = annotation.nameReference or {}
			annotation.nameReference[#annotation.nameReference + 1] = node
		end
	end
	return ok, node
end

ParseItemRequire = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the keyword token.
	do
		local tokenType, token = tokenStream:Consume()
		if not (tokenType == "keyword" and token == "ItemRequire") then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; keyword expected.", token)
			ok = false
		end
	end
	-- Consume the left parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "(" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; '(' expected.", token)
			ok = false
		end
	end
	-- Consume the item ID.
	local itemId, name
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "number" then
			itemId = token
		elseif tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; number or name expected.", token)
			ok = false
		end
	end
	-- Consume the property name.
	local property
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "name" then
			property = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; property name expected.", token)
			ok = false
		end
	end
	-- Consume any parameters.
	local positionalParams, namedParams
	if ok then
		ok, positionalParams, namedParams = ParseParameters(tokenStream, nodeList, annotation)
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= ")" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; ')' expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList)
		node.type = "item_require"
		node.itemId = itemId
		node.name = name
		node.property = property
		node.rawPositionalParams = positionalParams
		node.rawNamedParams = namedParams
		annotation.parametersReference = annotation.parametersReference or {}
		annotation.parametersReference[#annotation.parametersReference + 1] = node
		if name then
			annotation.nameReference = annotation.nameReference or {}
			annotation.nameReference[#annotation.nameReference + 1] = node
		end
	end
	return ok, node
end

ParseList = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the list token.
	local keyword
	do
		local tokenType, token = tokenStream:Consume()
		if tokenType == "keyword" and (token == "ItemList" or token == "SpellList") then
			keyword = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; keyword expected.", token)
			ok = false
		end
	end
	-- Consume the left parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "(" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; '(' expected.", token)
			ok = false
		end
	end
	-- Consume the list name.
	local name
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; name expected.", token)
			ok = false
		end
	end
	-- Consume the list.
	local positionalParams, namedParams
	if ok then
		ok, positionalParams, namedParams = ParseParameters(tokenStream, nodeList, annotation)
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= ")" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; ')' expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList)
		node.type = "list"
		node.keyword = keyword
		node.name = name
		node.rawPositionalParams = positionalParams
		node.rawNamedParams = namedParams
		annotation.parametersReference = annotation.parametersReference or {}
		annotation.parametersReference[#annotation.parametersReference + 1] = node
	end
	return ok, node
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
		node = GetNumberNode(value, nodeList, annotation)
	end
	return ok, node
end

ParseParameterValue = function(tokenStream, nodeList, annotation)
	local ok = true
	local node
	local tokenType, token
	local parameters
	repeat
		ok, node = ParseSimpleParameterValue(tokenStream, nodeList, annotation)
		if ok and node then
			tokenType, token = tokenStream:Peek()
			if tokenType == "," then
				-- Consume the ',' token.
				tokenStream:Consume()
				parameters = parameters or self_parametersPool:Get()
			end
			if parameters then
				parameters[#parameters + 1] = node
			end
		end
	until not ok or tokenType ~= ","
	if ok and parameters then
		-- This was a list of comma-separated values.
		node = OvaleAST:NewNode(nodeList)
		node.type = "comma_separated_values"
		node.csv = parameters
		annotation.parametersList = annotation.parametersList or {}
		annotation.parametersList[#annotation.parametersList + 1] = parameters
	end
	return ok, node
end

ParseParameters = function(tokenStream, nodeList, annotation, isList)
	local ok = true
	local positionalParams = self_parametersPool:Get()
	local namedParams = self_parametersPool:Get()
	while ok do
		local tokenType, token = tokenStream:Peek()
		if tokenType then
			local name, node
			if tokenType == "name" then
				ok, node = ParseVariable(tokenStream, nodeList, annotation)
				if ok then
					name = node.name
				end
			elseif tokenType == "number" then
				ok, node = ParseNumber(tokenStream, nodeList, annotation)
				if ok then
					name = node.value
				end
			elseif tokenType == "-" then
				-- This should be a negative number.
				-- Consume the '-' token.
				tokenStream:Consume()
				ok, node = ParseNumber(tokenStream, nodeList, annotation)
				if ok then
					-- Elide the unary negation operator into the number.
					local value = -1 * node.value
					node = GetNumberNode(value, nodeList, annotation)
					name = value
				end
			elseif tokenType == "string" then
				ok, node = ParseString(tokenStream, nodeList, annotation)
				if ok then
					name = node.value
				end
			elseif PARAMETER_KEYWORD[token] then
				if isList then
					SyntaxError(tokenStream, "Syntax error: unexpected keyword '%s' when parsing PARAMETERS; simple expression expected.", token)
					ok = false
				else
					tokenStream:Consume()
					name = token
				end
			else
				break
			end
			-- Check if this is a bare value or the start of a "name=value" pair.
			if ok and name then
				tokenType, token = tokenStream:Peek()
				if tokenType == "=" then
					-- Consume the '=' token.
					tokenStream:Consume()
					if name == "checkbox" or name == "listitem" then
						local control = namedParams[name] or self_controlPool:Get()
						if name == "checkbox" then
							-- Get the checkbox name.
							ok, node = ParseSimpleParameterValue(tokenStream, nodeList, annotation)
							if ok and node then
								-- Check afterwards that the parameter value is only "name" or "!name".
								if not (node.type == "variable" or (node.type == "bang_value" and node.child[1].type == "variable")) then
									SyntaxError(tokenStream, "Syntax error: 'checkbox' parameter with unexpected value '%s'.", Unparse(node))
									ok = false
								end
							end
							if ok then
								control[#control + 1] = node
							end
						else -- if name == "listitem" then
							-- Consume the list name.
							tokenType, token = tokenStream:Consume()
							local list
							if tokenType == "name" then
								list = token
							else
								SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARAMETERS; name expected.", token)
								ok = false
							end
							if ok then
								-- Consume the ':' token.
								tokenType, token = tokenStream:Consume()
								if tokenType ~= ":" then
									SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARAMETERS; ':' expected.", token)
									ok = false
								end
							end
							if ok then
								-- Consume the list item.
								ok, node = ParseSimpleParameterValue(tokenStream, nodeList, annotation)
							end
							if ok and node then
								-- Check afterwards that the parameter value is only "name" or "!name".
								if not (node.type == "variable" or (node.type == "bang_value" and node.child[1].type == "variable")) then
									SyntaxError(tokenStream, "Syntax error: 'listitem=%s' parameter with unexpected value '%s'.", Unparse(node))
									ok = false
								end
							end
							if ok then
								control[list] = node
							end
						end
						if not namedParams[name] then
							namedParams[name] = control
							annotation.controlList = annotation.controlList or {}
							annotation.controlList[#annotation.controlList + 1] = control
						end
					else
						-- Get the value.
						ok, node = ParseParameterValue(tokenStream, nodeList, annotation)
						namedParams[name] = node
					end
				else
					positionalParams[#positionalParams + 1] = node
				end
			end
		else
			break
		end
	end
	if ok then
		annotation.parametersList = annotation.parametersList or {}
		annotation.parametersList[#annotation.parametersList + 1] = positionalParams
		annotation.parametersList[#annotation.parametersList + 1] = namedParams
	else
		positionalParams = nil
		namedParams = nil
	end
	return ok, positionalParams, namedParams
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

ParseScoreSpells = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the 'ScoreSpells' token.
	do
		local tokenType, token = tokenStream:Consume()
		if not (tokenType == "keyword" and token == "ScoreSpells") then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; 'ScoreSpells' expected.", token)
			ok = false
		end
	end
	-- Consume the left parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "(" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; '(' expected.", token)
			ok = false
		end
	end
	-- Consume the list of spells.
	local positionalParams, namedParams
	if ok then
		ok, positionalParams, namedParams = ParseParameters(tokenStream, nodeList, annotation)
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= ")" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; ')' expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList)
		node.type = "score_spells"
		node.rawPositionalParams = positionalParams
		node.rawNamedParams = namedParams
		annotation.parametersReference = annotation.parametersReference or {}
		annotation.parametersReference[#annotation.parametersReference + 1] = node
	end
	return ok, node
end

ParseScript = function(tokenStream, nodeList, annotation)
	OvaleAST:StartProfiling("OvaleAST_ParseScript")
	local ok = true
	-- Consume each declaration.
	local child = self_childrenPool:Get()
	while ok do
		local tokenType, token = tokenStream:Peek()
		if tokenType then
			local declarationNode
			ok, declarationNode = ParseDeclaration(tokenStream, nodeList, annotation)
			if ok then
				if declarationNode.type == "script" then
					for _, node in ipairs(declarationNode.child) do
						child[#child + 1] = node
					end
					-- All "script" nodes are standalone and need to be explicitly released.
					self_pool:Release(declarationNode)
				else
					child[#child + 1] = declarationNode
				end
			end
		else
			break
		end
	end
	-- Create the AST node.
	local ast
	if ok then
		-- Create a standalone AST node.
		ast = OvaleAST:NewNode()
		ast.type = "script"
		ast.child = child
	else
		self_childrenPool:Release(child)
	end
	OvaleAST:StopProfiling("OvaleAST_ParseScript")
	return ok, ast
end

ParseSimpleExpression = function(tokenStream, nodeList, annotation)
	local ok = true
	local node
	local tokenType, token = tokenStream:Peek()
	if tokenType == "number" then
		ok, node = ParseNumber(tokenStream, nodeList, annotation)
	elseif tokenType == "string" then
		ok, node = ParseString(tokenStream, nodeList, annotation)
	elseif tokenType == "name" then
		tokenType, token = tokenStream:Peek(2)
		if tokenType == "." or tokenType == "(" then
			ok, node = ParseFunction(tokenStream, nodeList, annotation)
		else
			ok, node = ParseVariable(tokenStream, nodeList, annotation)
		end
	elseif tokenType == "(" or tokenType == "{" then
		ok, node = ParseParentheses(tokenStream, nodeList, annotation)
	else
		tokenStream:Consume()
		SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION", token)
		ok = false
	end
	return ok, node
end

ParseSimpleParameterValue = function(tokenStream, nodeList, annotation)
	local ok = true
	local isBang = false
	local tokenType, token = tokenStream:Peek()
	if tokenType == "!" then
		isBang = true
		-- Consume the '!' token.
		tokenStream:Consume()
	end
	local expressionNode
	tokenType, token = tokenStream:Peek()
	if tokenType == "(" or tokenType == "-" then
		ok, expressionNode = ParseExpression(tokenStream, nodeList, annotation)
	else
		ok, expressionNode = ParseSimpleExpression(tokenStream, nodeList, annotation)
	end
	local node
	if isBang then
		node = OvaleAST:NewNode(nodeList, true)
		node.type = "bang_value"
		node.child[1] = expressionNode
	else
		node = expressionNode
	end
	return ok, node
end

ParseSpellAuraList = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the keyword token.
	local keyword
	do
		local tokenType, token = tokenStream:Consume()
		if tokenType == "keyword" and SPELL_AURA_KEYWORD[token] then
			keyword = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; keyword expected.", token)
			ok = false
		end
	end
	-- Consume the left parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "(" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; '(' expected.", token)
			ok = false
		end
	end
	-- Consume the spell ID.
	local spellId, name
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "number" then
			spellId = token
		elseif tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; number or name expected.", token)
			ok = false
		end
	end
	
	-- Consume any parameters.
	local positionalParams, namedParams
	if ok then
		ok, positionalParams, namedParams = ParseParameters(tokenStream, nodeList, annotation)
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= ")" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; ')' expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList)
		node.type = "spell_aura_list"
		node.keyword = keyword
		node.spellId = spellId
		node.name = name
		node.rawPositionalParams = positionalParams
		node.rawNamedParams = namedParams
		annotation.parametersReference = annotation.parametersReference or {}
		annotation.parametersReference[#annotation.parametersReference + 1] = node
		if name then
			annotation.nameReference = annotation.nameReference or {}
			annotation.nameReference[#annotation.nameReference + 1] = node
		end
	end
	return ok, node
end

ParseSpellInfo = function(tokenStream, nodeList, annotation)
	local ok = true
	local name, lowername
	-- Consume the 'SpellInfo' token.
	do
		local tokenType, token = tokenStream:Consume()
		if not (tokenType == "keyword" and token == "SpellInfo") then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; 'SpellInfo' expected.", token)
			ok = false
		end
	end
	-- Consume the left parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "(" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; '(' expected.", token)
			ok = false
		end
	end
	-- Consume the spell ID.
	local spellId, name
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "number" then
			spellId = token
		elseif tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; number or name expected.", token)
			ok = false
		end
	end
	-- Consume any SpellInfo parameters.
	local positionalParams, namedParams
	if ok then
		ok, positionalParams, namedParams = ParseParameters(tokenStream, nodeList, annotation)
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= ")" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; ')' expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList)
		node.type = "spell_info"
		node.spellId = spellId
		node.name = name
		node.rawPositionalParams = positionalParams
		node.rawNamedParams = namedParams
		annotation.parametersReference = annotation.parametersReference or {}
		annotation.parametersReference[#annotation.parametersReference + 1] = node
		if name then
			annotation.nameReference = annotation.nameReference or {}
			annotation.nameReference[#annotation.nameReference + 1] = node
		end
	end
	return ok, node
end

ParseSpellRequire = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the keyword token.
	do
		local tokenType, token = tokenStream:Consume()
		if not (tokenType == "keyword" and token == "SpellRequire") then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; keyword expected.", token)
			ok = false
		end
	end
	-- Consume the left parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= "(" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; '(' expected.", token)
			ok = false
		end
	end
	-- Consume the spell ID.
	local spellId, name
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "number" then
			spellId = token
		elseif tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; number or name expected.", token)
			ok = false
		end
	end
	-- Consume the property name.
	local property
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType == "name" then
			property = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; property name expected.", token)
			ok = false
		end
	end
	-- Consume any parameters.
	local positionalParams, namedParams
	if ok then
		ok, positionalParams, namedParams = ParseParameters(tokenStream, nodeList, annotation)
	end
	-- Consume the right parenthesis.
	if ok then
		local tokenType, token = tokenStream:Consume()
		if tokenType ~= ")" then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; ')' expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList)
		node.type = "spell_require"
		node.spellId = spellId
		node.name = name
		node.property = property
		node.rawPositionalParams = positionalParams
		node.rawNamedParams = namedParams
		annotation.parametersReference = annotation.parametersReference or {}
		annotation.parametersReference[#annotation.parametersReference + 1] = node
		if name then
			annotation.nameReference = annotation.nameReference or {}
			annotation.nameReference[#annotation.nameReference + 1] = node
		end
	end
	return ok, node
end

ParseStatement = function(tokenStream, nodeList, annotation)
	local ok = true
	local node
	local tokenType, token = tokenStream:Peek()
	if tokenType then
		local parser
		if token == "{" then
			-- Find the matching '}' and inspect the next token to see if this is an expression or a group.
			local i = 1
			local count = 0
			while tokenType do
				if token == "{" then
					count = count + 1
				elseif token == "}" then
					count = count - 1
				end
				i = i + 1
				tokenType, token = tokenStream:Peek(i)
				if count == 0 then
					break
				end
			end
			if tokenType then
				if BINARY_OPERATOR[token] then
					ok, node = ParseExpression(tokenStream, nodeList, annotation)
				else
					ok, node = ParseGroup(tokenStream, nodeList, annotation)
				end
			else
				SyntaxError(tokenStream, "Syntax error: unexpected end of script.")
			end
		elseif token == "if" then
			ok, node = ParseIf(tokenStream, nodeList, annotation)
		elseif token == "unless" then
			ok, node = ParseUnless(tokenStream, nodeList, annotation)
		else
			ok, node = ParseExpression(tokenStream, nodeList, annotation)
		end
	end
	return ok, node
end

ParseString = function(tokenStream, nodeList, annotation)
	local ok = true
	local node
	local value
	if ok then
		local tokenType, token = tokenStream:Peek()
		if tokenType == "string" then
			value = token
			tokenStream:Consume()
		elseif tokenType == "name" then
			if STRING_LOOKUP_FUNCTION[token] then
				ok, node = ParseFunction(tokenStream, nodeList, annotation)
			else
				value = token
				tokenStream:Consume()
			end
		else
			tokenStream:Consume()
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing STRING; string, variable, or function expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	if ok and not node then
		node = OvaleAST:NewNode(nodeList)
		node.type = "string"
		node.value = value
		annotation.stringReference = annotation.stringReference or {}
		annotation.stringReference[#annotation.stringReference + 1] = node
	end
	return ok, node
end

ParseUnless = function(tokenStream, nodeList, annotation)
	local ok = true
	-- Consume the 'unless' token.
	do
		local tokenType, token = tokenStream:Consume()
		if not (tokenType == "keyword" and token == "unless") then
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing UNLESS; 'unless' expected.", token)
			ok = false
		end
	end
	-- Consume the condition and body.
	local conditionNode, bodyNode
	if ok then
		ok, conditionNode = ParseExpression(tokenStream, nodeList, annotation)
	end
	if ok then
		ok, bodyNode = ParseStatement(tokenStream, nodeList, annotation)
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList, true)
		node.type = "unless"
		node.child[1] = conditionNode
		node.child[2] = bodyNode
	end
	return ok, node
end

ParseVariable = function(tokenStream, nodeList, annotation)
	local ok = true
	local name
	-- Consume the variable name.
	do
		local tokenType, token = tokenStream:Consume()
		if tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing VARIABLE; name expected.", token)
			ok = false
		end
	end
	-- Create the AST node.
	local node
	if ok then
		node = OvaleAST:NewNode(nodeList)
		node.type = "variable"
		node.name = name
		annotation.nameReference = annotation.nameReference or {}
		annotation.nameReference[#annotation.nameReference + 1] = node
	end
	return ok, node
end

do
	PARSE_VISITOR = {
		["action"] = ParseFunction,
		["add_function"] = ParseAddFunction,
		["arithmetic"] = ParseExpression,
		["bang_value"] = ParseSimpleParameterValue,
		["checkbox"] = ParseAddCheckBox,
		["compare"] = ParseExpression,
		["comment"] = ParseComment,
		["custom_function"] = ParseFunction,
		["define"] = ParseDefine,
		["expression"] = ParseExpression,
		["function"] = ParseFunction,
		["group"] = ParseGroup,
		["icon"] = ParseAddIcon,
		["if"] = ParseIf,
		["item_info"] = ParseItemInfo,
		["item_require"] = ParseItemRequire,
		["list"] = ParseList,
		["list_item"] = ParseAddListItem,
		["logical"] = ParseExpression,
		["score_spells"] = ParseScoreSpells,
		["script"] = ParseScript,
		["spell_aura_list"] = ParseSpellAuraList,
		["spell_info"] = ParseSpellInfo,
		["spell_require"] = ParseSpellRequire,
		["string"] = ParseString,
		["unless"] = ParseUnless,
		["value"] = ParseNumber,
		["variable"] = ParseVariable,
	}
end
--</private-static-methods>

--<public-static-methods>
function OvaleAST:OnInitialize()
	-- Resolve module dependencies.
	OvaleCondition = Ovale.OvaleCondition
	OvaleLexer = Ovale.OvaleLexer
	OvaleScripts = Ovale.OvaleScripts
	OvaleSpellBook = Ovale.OvaleSpellBook
	OvaleStance = Ovale.OvaleStance
end

function OvaleAST:DebugAST()
	self_pool:DebuggingInfo()
	self_parametersPool:DebuggingInfo()
	self_controlPool:DebuggingInfo()
	self_childrenPool:DebuggingInfo()
	self_outputPool:DebuggingInfo()
end

-- Get a new node from the pool and save it in the nodes array.
function OvaleAST:NewNode(nodeList, hasChild)
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

function OvaleAST:NodeToString(node)
	local output = print_r(node)
	return tconcat(output, "\n")
end

function OvaleAST:ReleaseAnnotation(annotation)
	if annotation.controlList then
		for _, control in ipairs(annotation.controlList) do
			self_controlPool:Release(control)
		end
	end
	if annotation.parametersList then
		for _, parameters in ipairs(annotation.parametersList) do
			self_parametersPool:Release(parameters)
		end
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
end

function OvaleAST:Release(ast)
	if ast.annotation then
		self:ReleaseAnnotation(ast.annotation)
		ast.annotation = nil
	end
	self_pool:Release(ast)
end

function OvaleAST:ParseCode(nodeType, code, nodeList, annotation)
	nodeList = nodeList or {}
	annotation = annotation or {}
	local tokenStream = OvaleLexer("Ovale", GetTokenIterator(code))
	local ok, node = Parse(nodeType, tokenStream, nodeList, annotation)
	tokenStream:Release()
	return node, nodeList, annotation
end

function OvaleAST:ParseScript(name, options)
	-- Get the code associated with the script name.
	local code = OvaleScripts:GetScript(name)
	local ast
	if code then
		options = options or { optimize = true, verify = true }
		-- Annotation table for the AST.
		local annotation = {
			nodeList = {},
			verify = options.verify,
		}
		ast = self:ParseCode("script", code, annotation.nodeList, annotation)
		if ast then
			ast.annotation = annotation
			self:PropagateConstants(ast)
			self:PropagateStrings(ast)
			self:FlattenParameters(ast)
			self:VerifyParameterStances(ast)
			self:VerifyFunctionCalls(ast)
			if options.optimize then
				self:Optimize(ast)
			end
			self:InsertPostOrderTraversal(ast)
		else
			-- Create a dummy node to properly release resources.
			ast = self:NewNode()
			ast.annotation = annotation
			self:Release(ast)
			ast = nil
		end
	end
	return ast
end

function OvaleAST:Unparse(node)
	return Unparse(node)
end

-- Replaces variables with their defined values.
function OvaleAST:PropagateConstants(ast)
	self:StartProfiling("OvaleAST_PropagateConstants")
	if ast.annotation then
		local dictionary = ast.annotation.definition
		if dictionary and ast.annotation.nameReference then
			for _, node in ipairs(ast.annotation.nameReference) do
				if (node.type == "item_info" or node.type == "item_require") and node.name then
					local itemId = dictionary[node.name]
					if itemId then
						node.itemId = itemId
					end
				elseif (node.type == "spell_aura_list" or node.type == "spell_info" or node.type == "spell_require") and node.name then
					local spellId = dictionary[node.name]
					if spellId then
						node.spellId = spellId
					end
				elseif node.type == "variable" then
					local name = node.name
					local value = dictionary[name]
					if value then
						-- Convert to a value node.
						node.previousType = "variable"
						node.type = "value"
						node.value = value
						node.origin = 0
						node.rate = 0
					end
				end
			end
		end
	end
	self:StopProfiling("OvaleAST_PropagateConstants")
end

-- Replaces variables and string-lookup function calls with string values.
function OvaleAST:PropagateStrings(ast)
	self:StartProfiling("OvaleAST_PropagateStrings")
	if ast.annotation and ast.annotation.stringReference then
		for _, node in ipairs(ast.annotation.stringReference) do
			if node.type == "string" then
				local key = node.value
				local value = L[key]
				if key ~= value then
					node.value = value
					node.key = key
				end
			elseif node.type == "variable" then
				local value = node.name
				-- Convert to a string node.
				node.previousType = node.type
				node.type = "string"
				node.value = value
			elseif node.type == "number" then
				local value = tostring(node.value)
				-- Convert to a string node.
				node.previousType = "number"
				node.type = "string"
				node.value = value
			elseif node.type == "function" then
				-- Get the lookup key for the string database.
				local key = node.rawPositionalParams[1]
				if type(key) == "table" then
					if key.type == "value" then
						key = key.value
					elseif key.type == "variable" then
						key = key.name
					elseif key.type == "string" then
						key = key.value
					end
				end
				local value
				if key then
					local name = node.name
					if name == "ItemName" then
						value = API_GetItemInfo(key) or "item:" .. key
					elseif name == "L" then
						value = L[key]
					elseif name == "SpellName" then
						value = OvaleSpellBook:GetSpellName(key) or "spell:" .. key
					end
				end
				if value then
					-- Convert to a string node.
					node.previousType = "function"
					node.type = "string"
					node.value = value
					node.key = key
				end
			end
		end
	end
	self:StopProfiling("OvaleAST_PropagateStrings")
end

-- "Flattens" parameter tables by replacing table values with the bare numerical or string values
-- so that the parameter table can be used directly by script conditions.
function OvaleAST:FlattenParameters(ast)
	self:StartProfiling("OvaleAST_FlattenParameters")
	local annotation = ast.annotation
	if annotation and annotation.parametersReference then
		local dictionary = annotation.definition
		for _, node in ipairs(annotation.parametersReference) do
			if node.rawPositionalParams then
				local parameters = self_parametersPool:Get()
				for key, value in ipairs(node.rawPositionalParams) do
					parameters[key] = FlattenParameterValue(value, annotation)
				end
				node.positionalParams = parameters
				annotation.parametersList = annotation.parametersList or {}
				annotation.parametersList[#annotation.parametersList + 1] = parameters
			end
			if node.rawNamedParams then
				local parameters = self_parametersPool:Get()
				for key, value in pairs(node.rawNamedParams) do
					-- Lookup the key.
					if key == "checkbox" or key == "listitem" then
						local control = parameters[key] or self_controlPool:Get()
						if key == "checkbox" then
							for i, name in ipairs(value) do
								control[i] = FlattenParameterValue(name, annotation)
							end
						else -- if key == "listitem" then
							for list, item in pairs(value) do
								control[list] = FlattenParameterValue(item, annotation)
							end
						end
						if not parameters[key] then
							parameters[key] = control
							annotation.controlList = annotation.controlList or {}
							annotation.controlList[#annotation.controlList + 1] = control
						end
					else
						if type(key) ~= "number" and dictionary and dictionary[key] then
							key = dictionary[key]
						end
						parameters[key] = FlattenParameterValue(value, annotation)
					end
				end
				node.namedParams = parameters
				annotation.parametersList = annotation.parametersList or {}
				annotation.parametersList[#annotation.parametersList + 1] = parameters
			end
			-- Save a flattened string representation of the parameters.
			local output = self_outputPool:Get()
			for k, v in pairs(node.namedParams) do
				if k == "checkbox" then
					for _, name in ipairs(v) do
						output[#output + 1] = format("checkbox=%s", name)
					end
				elseif k == "listitem" then
					for list, item in ipairs(v) do
						output[#output + 1] = format("listitem=%s:%s", list, item)
					end
				elseif type(v) == "table" then
					-- Comma-separated value.
					output[#output + 1] = format("%s=%s", k, tconcat(v, ","))
				else
					output[#output + 1] = format("%s=%s", k, v)
				end
			end
			tsort(output)
			for k = #node.positionalParams, 1, -1 do
				tinsert(output, 1, node.positionalParams[k])
			end
			if #output > 0 then
				node.paramsAsString = tconcat(output, " ")
			else
				node.paramsAsString = ""
			end
			self_outputPool:Release(output)
		end
	end
	self:StopProfiling("OvaleAST_FlattenParameters")
end

-- Verify that all functions called within the script are known.
function OvaleAST:VerifyFunctionCalls(ast)
	self:StartProfiling("OvaleAST_VerifyFunctionCalls")
	if ast.annotation and ast.annotation.verify then
		local customFunction = ast.annotation.customFunction
		local functionCall = ast.annotation.functionCall
		if functionCall then
			for name in pairs(functionCall) do
				if ACTION_PARAMETER_COUNT[name] then
					-- Function call is an action.
				elseif STRING_LOOKUP_FUNCTION[name] then
					-- Function call is a string-lookup function.
				elseif OvaleCondition:IsCondition(name) then
					-- Function call is a registered script condition.
				elseif customFunction and customFunction[name] then
					-- Function call is a script-defined function (via AddFunction).
				else
					self:Error("unknown function '%s'.", name)
				end
			end
		end
	end
	self:StopProfiling("OvaleAST_VerifyFunctionCalls")
end

function OvaleAST:VerifyParameterStances(ast)
	self:StartProfiling("OvaleAST_VerifyParameterStances")
	local annotation = ast.annotation
	if annotation and annotation.verify and annotation.parametersReference then
		for _, node in ipairs(annotation.parametersReference) do
			if node.rawNamedParams then
				for stanceKeyword in pairs(STANCE_KEYWORD) do
					local valueNode = node.rawNamedParams[stanceKeyword]
					if valueNode then
						if valueNode.type == "comma_separated_values" then
							valueNode = valueNode.csv[1]
						end
						if valueNode.type == "bang_value" then
							valueNode = valueNode.child[1]
						end
						local value = FlattenParameterValue(valueNode, annotation)
						if OvaleStance.STANCE_NAME[value] then
							-- The value is a valid stance name.
						elseif type(value) == "number" then
							-- The value is a number, which is a valid stance reference.
						else
							self:Error("unknown stance '%s'.", value)
						end
					end
				end
			end
		end
	end
	self:StopProfiling("OvaleAST_VerifyParameterStances")
end

-- Insert a "postOrder" property into top-level nodes.
function OvaleAST:InsertPostOrderTraversal(ast)
	self:StartProfiling("OvaleAST_InsertPostOrderTraversal")
	local annotation = ast.annotation
	if annotation and annotation.postOrderReference then
		for _, node in ipairs(annotation.postOrderReference) do
			local array = self_postOrderPool:Get()
			local visited = self_postOrderPool:Get()
			PostOrderTraversal(node, array, visited)
			self_postOrderPool:Release(visited)
			node.postOrder = array
			--[[
			local postOrder = node.postOrder
			local output = self_outputPool:Get()
			local i = 1
			while postOrder[i] do
				local child, parent = postOrder[i], postOrder[i + 1]
				output[#output + 1] = child.nodeId
				i = i + 2
			end
			local outputHeader = format("Post-order for %d has %d nodes: ", node.nodeId, (i - 1) / 2)
			local outputString = outputHeader .. tconcat(output, ", ")
			self_outputPool:Release(output)
			self:Print(outputString)
			--]]
		end
	end
	self:StopProfiling("OvaleAST_InsertPostOrderTraversal")
end

function OvaleAST:Optimize(ast)
	self:CommonFunctionElimination(ast)
	self:CommonSubExpressionElimination(ast)
end

--[[----------------------------------------------------------------------------
	Common Function Elimination

	This is an optimizing transformation of the AST that globally replaces
	references to function nodes to the node of the first function call made
	with identical parameters.
--]]----------------------------------------------------------------------------
function OvaleAST:CommonFunctionElimination(ast)
	self:StartProfiling("OvaleAST_CommonFunctionElimination")
	if ast.annotation then
		-- Hash all of the function calls.
		if ast.annotation.functionReference then
			local functionHash = ast.annotation.functionHash or {}
			for _, node in ipairs(ast.annotation.functionReference) do
				if node.positionalParams or node.namedParams then
					local hash = node.name .. "(" .. node.paramsAsString .. ")"
					node.functionHash = hash
					functionHash[hash] = functionHash[hash] or node
				end
			end
			ast.annotation.functionHash = functionHash
		end

		-- Walk the AST and search for child nodes that are function nodes and
		-- replace with a reference to the hashed node.
		if ast.annotation.functionHash and ast.annotation.nodeList then
			local functionHash = ast.annotation.functionHash
			for _, node in ipairs(ast.annotation.nodeList) do
				if node.child then
					for k, childNode in ipairs(node.child) do
						if childNode.functionHash then
							node.child[k] = functionHash[childNode.functionHash]
						end
					end
				end
			end
		end
	end
	self:StopProfiling("OvaleAST_CommonFunctionElimination")
end

--[[----------------------------------------------------------------------------
	Common Sub-Expression Elimination

	This is an optimizing transformation of the AST that globally replaces
	references to nodes with a string representation with the first node found
	that has the same string representation.
--]]----------------------------------------------------------------------------

function OvaleAST:CommonSubExpressionElimination(ast)
	self:StartProfiling("OvaleAST_CommonSubExpressionElimination")
	if ast and ast.annotation and ast.annotation.nodeList then
		local expressionHash = {}
		-- Walk the AST and search for child nodes that have string representations.
		for _, node in ipairs(ast.annotation.nodeList) do
			local hash = node.asString
			-- Hash the node if it has a string representation.
			if hash then
				expressionHash[hash] = expressionHash[hash] or node
			end
			-- Replace all child nodes with hashed nodes if they exist.
			if node.child then
				for i, childNode in ipairs(node.child) do
					hash = childNode.asString
					if hash then
						local hashNode = expressionHash[hash]
						if hashNode then
							-- Replace the child node with a previous hashed node if it exists.
							node.child[i] = hashNode
						else
							-- Hash the child node if it has a string representation.
							expressionHash[hash] = childNode
						end
					end
				end
			end
		end
		ast.annotation.expressionHash = expressionHash
	end
	self:StopProfiling("OvaleAST_CommonSubExpressionElimination")
end
--</public-static-methods>
