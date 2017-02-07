--[[--------------------------------------------------------------------
    Copyright (C) 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleSimulationCraft = Ovale:NewModule("OvaleSimulationCraft")
Ovale.OvaleSimulationCraft = OvaleSimulationCraft

--<private-static-properties>
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = Ovale.L
local OvaleDebug = Ovale.OvaleDebug
local OvaleOptions = Ovale.OvaleOptions
local OvalePool = Ovale.OvalePool

-- Forward declarations for module dependencies.
local OvaleAST = nil
local OvaleCompile = nil
local OvaleData = nil
local OvaleHonorAmongThieves = nil
local OvaleLexer = nil
local OvalePower = nil
local OvaleScripts = nil

local format = string.format
local gmatch = string.gmatch
local gsub = string.gsub
local ipairs = ipairs
local next = next
local pairs = pairs
local rawset = rawset
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
local tremove = table.remove
local tsort = table.sort
local type = type
local wipe = wipe
local yield = coroutine.yield
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

-- Keywords for SimulationCraft action lists.
local KEYWORD = {}

local MODIFIER_KEYWORD = {
	["ammo_type"] = true,
	["animation_cancel"] = true,
	["attack_speed"] = true,
	["chain"] = true,
	["choose"] = true,
	["cooldown"] = true,
	["cooldown_stddev"] = true,
	["cycle_targets"] = true,
	["damage"] = true,
	["early_chain_if"] = true,
	["extra_amount"] = true,
	["five_stacks"] = true,
	["for_next"] = true,
	["if"] = true,
	["interrupt"] = true,
	["interrupt_if"] = true,
	["interrupt_immediate"] = true,
	["lethal"] = true,
	["line_cd"] = true,
	["max_cycle_targets"] = true,
	["max_energy"] = true,
	["min_frenzy"] = true,
	["moving"] = true,
	["name"] = true,
	["nonlethal"] = true,
	["op"] = true,
	["range"] = true,
	["sec"] = true,
	["slot"] = true,
	["sync"] = true,
	["sync_weapons"] = true,
	["target"] = true,
	["target_if"] = true,
	["target_if_first"] = true,		-- "target_if_<type>" is a fake modifier.
	["target_if_max"] = true,
	["target_if_min"] = true,
	["toggle"] = true,
	["travel_speed"] = true,
	["type"] = true,
	["value"] = true,
	["wait"] = true,
	["wait_on_ready"] = true,
	["weapon"] = true,
}

local LITTERAL_MODIFIER = {
	["name"] = true
}

local FUNCTION_KEYWORD = {
	["ceil"] = true,
	["floor"] = true,
}

local SPECIAL_ACTION = {
	["apply_poison"] = true,
	["auto_attack"] = true,
	["call_action_list"] = true,
	["cancel_buff"] = true,
	["cancel_metamorphosis"] = true,
	["exotic_munitions"] = true,
	["flask"] = true,
	["food"] = true,
	["health_stone"] = true,
	["pool_resource"] = true,
	["potion"] = true,
	["run_action_list"] = true,
	["snapshot_stats"] = true,
	["stance"] = true,
	["start_moving"] = true,
	["stealth"] = true,
	["stop_moving"] = true,
	["swap_action_list"] = true,
	["use_item"] = true,
	["variable"] = true,
	["wait"] = true,
}

local RUNE_OPERAND = {
	["rune"] = "rune"
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
	["!"]  = { "logical", 15 },
	["-"]  = { "arithmetic", 50 },
	["@"]  = { "arithmetic", 50 },
}
local BINARY_OPERATOR = {
	-- logical
	["|"]  = { "logical",  5, "associative" },
	["^"]  = { "logical",  8, "associative" },
	["&"]  = { "logical", 10, "associative" },
	-- comparison
	["!="] = { "compare", 20 },
	["<"]  = { "compare", 20 },
	["<="] = { "compare", 20 },
	["="]  = { "compare", 20 },
	["=="]  = { "compare", 20 },
	[">"]  = { "compare", 20 },
	[">="] = { "compare", 20 },
	["~"]  = { "compare", 20 },
	["!~"] = { "compare", 20 },
	-- addition, subtraction
	["+"]  = { "arithmetic", 30, "associative" },
	["-"]  = { "arithmetic", 30 },
	-- multiplication, division, modulus
	["%"]  = { "arithmetic", 40 },
	["*"]  = { "arithmetic", 40, "associative" },
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

local POTION_STAT = {
	["draenic_agility"]		= "agility",
	["draenic_armor"]		= "armor",
	["draenic_intellect"]	= "intellect",
	["draenic_strength"]	= "strength",
	["jade_serpent"]		= "intellect",
	["mogu_power"]			= "strength",
	["mountains"]			= "armor",
	["tolvir"]				= "agility",
	["virmens_bite"]		= "agility",
}

-- Mark() and Sweep() static variables.
-- functionDefined[name] = true if the function is declared with AddFunction(), or false otherwise.
local self_functionDefined = {}
-- functionUsed[name] = true if the function is used within the script, or false otherwise.
local self_functionUsed = {}

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

-- Save the most recent profile entered into the SimulationCraft input window.
local self_lastSimC = nil
-- Save the most recent script translated from the profile in the SimulationCraft input window.
local self_lastScript = nil

do
	-- Add a slash command "/ovale simc" to access the GUI for this module.
	local actions = {
		simc  = {
			name = "SimulationCraft",
			type = "execute",
			func = function()
				local appName = OvaleSimulationCraft:GetName()
				AceConfigDialog:SetDefaultSize(appName, 700, 550)
				AceConfigDialog:Open(appName)
			end,
		},
	}
	-- Inject into OvaleOptions.
	for k, v in pairs(actions) do
		OvaleOptions.options.args.actions.args[k] = v
	end
	OvaleOptions:RegisterOptions(OvaleSimulationCraft)
end

-- XXX Temporary hard-coding of tags and tag priorities.
local OVALE_TAGS = { "main", "shortcd", "cd" }
local OVALE_TAG_PRIORITY = {}
do
	for i, tag in pairs(OVALE_TAGS) do
		OVALE_TAG_PRIORITY[tag] = i * 10
	end
end

do
	local defaultDB = {
		overrideCode = "",
	}
	-- Insert defaults into OvaleOptions.
	for k, v in pairs(defaultDB) do
		OvaleOptions.defaultDB.profile[k] = v
	end
	OvaleOptions:RegisterOptions(OvaleSimulationCraft)
end
--</private-static-properties>

--<private-static-methods>
-- Implementation of PHP-like print_r() taken from http://lua-users.org/wiki/TableSerialization.
-- This is used to print out a table, but has been modified to print out an AST.
local function print_r(node, indent, done, output)
	done = done or {}
	output = output or {}
	indent = indent or ''
	if node == nil then
		tinsert(output, indent.. 'nil')
	elseif type(node) ~= "table" then
		tinsert(output, indent .. node)
	else
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
	end
	return output
end

local function debug_r(tbl)
	local output = print_r(tbl)
	print(tconcat(output, "\n"))
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
		{ "^==", Tokenize },
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
		OvaleSimulationCraft:Error("Unable to unparse node of type '%s'.", node.type)
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
	if node.name == "_default" then
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
		elseif rhsPrecedence and precedence == rhsPrecedence then
			if BINARY_OPERATOR[node.operator][3] == "associative" and node.operator == rhsNode.operator then
				rhsExpression = Unparse(rhsNode)
			else
				rhsExpression = "(" .. Unparse(rhsNode) .. ")"
			end
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
	OvaleSimulationCraft:Print(...)
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
	OvaleSimulationCraft:Print(tconcat(context, " "))
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
		-- Fix "|" being silently replaced by "||" in WoW strings entered via an edit box.
		stream = gsub(stream, "||", "|")
	end
	do
		-- Fix bugs in SimulationCraft action lists.
		-- ",," into ","
		stream = gsub(stream, ",,", ",")
		-- "&&" into "&"
		stream = gsub(stream, "%&%&", "&")
		-- "target.target." into "target."
		stream = gsub(stream, "target%.target%.", "target.")
	end
	do
		-- Changes to SimulationCraft action lists for easier translation into Ovale timespan concept.
		-- "active_dot.dotName=0" into "!(active_dot.dotName>0)"
		stream = gsub(stream, "(active_dot%.[%w_]+)=0", "!(%1>0)")
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
	do
		-- Convert "@" absolute value unary operator for easier translation into Ovale timespan concept.
		-- "@expr1<N" into "(expr1<N&expr1>-N)"
		stream = gsub(stream, "%@([a-z_%.]+)<(=?)([0-9]+)", "(%1<%2%3&%1>%2-%3)")
		-- "@expr1>N" into "(expr1>N|expr1<-N)"
		stream = gsub(stream, "%@([a-z_%.]+)>(=?)([0-9]+)", "(%1>%2%3|%1<%2-%3)")
	end
	do
		-- Convert "!foo.cooldown.up" into "foo.cooldown.down" to avoid emitting "not not ...".
		stream = gsub(stream, "!([a-z_%.]+)%.cooldown%.up", "%1.cooldown.down")
	end
	do
		stream = gsub(stream, "!talent%.([a-z_%.]+)%.enabled", "talent.%1.disabled")
	end
	do
		--[[
			Mage APLs have a custom "target_if=max:..." modifier to the "choose_target"
			action which does not adhere to the language standard.
		--]]
		stream = gsub(stream, ",target_if=first:", ",target_if_first=")
		stream = gsub(stream, ",target_if=max:", ",target_if_max=")
		stream = gsub(stream, ",target_if=min:", ",target_if_min=")
	end
	do
		--"sim.target" is the "priority target" property of the simulator, change into "sim_target".
		stream = gsub(stream, "sim.target", "sim_target")
	end
	local tokenStream = OvaleLexer("SimulationCraft", GetTokenIterator(stream))
	-- Consume the action.
	local name
	do
		local tokenType, token = tokenStream:Consume()
		if (tokenType == "keyword" and SPECIAL_ACTION[token]) or tokenType == "name" then
			name = token
		else
			SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line '%s'; name or special action expected.", token, action)
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
				SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line '%s'; ',' expected.", token, action)
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
		-- Save first action for "sync=action" references.
		annotation.sync = annotation.sync or {}
		annotation.sync[name] = annotation.sync[name] or node
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
				if ok and node then
					node.asType = "boolean"
				end
			end
		end
	end

	-- Peek at the next token to see if it is a binary operator.
	while ok do
		local keepScanning = false
		local tokenType, token = tokenStream:Peek()

		if not tokenType then
			break
		end

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
					if not rhsNode then
						SyntaxError(tokenStream, "Internal error: no right operand in binary operator %s.", token)
						return false				
					end
					rhsNode.asType = asType
					-- Left-rotate tree to preserve precedence.
					while node.type == rhsNode.type and node.operator == rhsNode.operator and BINARY_OPERATOR[node.operator][3] == "associative" and rhsNode.expressionType == "binary" do
						node.child[2] = rhsNode.child[1]
						rhsNode.child[1] = node
						node = rhsNode
						rhsNode = node.child[2]
					end
				end
			end
		elseif not node then
			SyntaxError(tokenStream, "Syntax error: %s of type %s is not a binary operator", token, tokenType)
			return false
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

ParseIdentifier = function(tokenStream, nodeList, annotation)
	local tokenType, token = tokenStream:Consume()
	local node = NewNode(nodeList)
	node.type = "operand"
	node.name = token
	annotation.operand = annotation.operand or {}
	annotation.operand[#annotation.operand + 1] = node
	return true, node
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
		if LITTERAL_MODIFIER[name] then 
			ok, expressionNode = ParseIdentifier(tokenStream, nodeList, annotation)
		else
			ok, expressionNode = ParseExpression(tokenStream, nodeList, annotation)
			if ok and expressionNode and name == "sec" then
				expressionNode.asType = "value"
			end
		end
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
		elseif tokenType == "keyword" and (token == "target" or token == "cooldown") then
			-- Allow a bare "target" to be used as an operand.
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
		node.rune = RUNE_OPERAND[name]
		if node.rune then
			local firstCharacter = strsub(name, 1, 1)
			node.includeDeath = (firstCharacter == "B" or firstCharacter == "F" or firstCharacter == "U")
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
	elseif tokenType == "keyword" then
		if FUNCTION_KEYWORD[token] then
			ok, node = ParseFunction(tokenStream, nodeList, annotation)
		elseif token == "target" or token == "cooldown" then
			ok, node = ParseOperand(tokenStream, nodeList, annotation)
		else
			SyntaxError(tokenStream, "Warning: unknown keyword %s when parsing SIMPLE EXPRESSION", token)	
			return false
		end
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

local function CamelSpecialization(annotation)
	local output = self_outputPool:Get()
	local profileName, class, specialization = annotation.name, annotation.class, annotation.specialization
	if specialization then
		output[#output + 1] = specialization
	end
	if strmatch(profileName, "_1[hH]_") then
		if class == "DEATHKNIGHT" and specialization == "frost" then
			output[#output + 1] = "dual wield"
		elseif class == "WARRIOR" and specialization == "fury" then
			output[#output + 1] = "single minded fury"
		end
	elseif strmatch(profileName, "_2[hH]_") then
		if class == "DEATHKNIGHT" and specialization == "frost" then
			output[#output + 1] = "two hander"
		elseif class == "WARRIOR" and specialization == "fury" then
			output[#output + 1] = "titans grip"
		end
	elseif strmatch(profileName, "_[gG]ladiator_") then
		output[#output + 1] = "gladiator"
	end
	local outputString = CamelCase(tconcat(output, " "))
	self_outputPool:Release(output)
	return outputString
end

local function OvaleFunctionName(name, annotation)
	local functionName = CamelCase(name .. " actions")
	if annotation.specialization then
		functionName = CamelSpecialization(annotation) .. functionName
	end
	return functionName
end

local function AddSymbol(annotation, symbol)
	local symbolTable = annotation.symbolTable or {}
	-- Add the symbol to the table if it's not already present and it's not a globally-defined spell list name.
	if not symbolTable[symbol] and not OvaleData.DEFAULT_SPELL_LIST[symbol] then
		symbolTable[symbol] = true
		symbolTable[#symbolTable + 1] = symbol
	end
	annotation.symbolTable = symbolTable
end

local function AddPerClassSpecialization(tbl, name, info, class, specialization, type)
	class = class or "ALL_CLASSES"
	specialization = specialization or "ALL_SPECIALIZATIONS"
	tbl[class] = tbl[class] or {}
	tbl[class][specialization] = tbl[class][specialization] or {}
	tbl[class][specialization][name] = { info, type or "Spell" }
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
	if info then
		return info[1], info[2]
	end
	return nil
end

local function AddDisambiguation(name, info, class, specialization, type)
	AddPerClassSpecialization(EMIT_DISAMBIGUATION, name, info, class, specialization, type)
end

local function Disambiguate(name, class, specialization, type)
	local disname, distype = GetPerClassSpecialization(EMIT_DISAMBIGUATION, name, class, specialization, type)
	if not disname then
	 	return name, type
	end
	return disname, distype
end

local function InitializeDisambiguation()
	AddDisambiguation("bloodlust_buff",			"burst_haste_buff")
	AddDisambiguation("trinket_proc_all_buff",	"trinket_proc_any_buff")
	-- WoD legendary ring
	AddDisambiguation("etheralus_the_eternal_reward",			"legendary_ring_spirit", nil, nil, "Item")
	AddDisambiguation("maalus_the_blood_drinker",				"legendary_ring_agility", nil, nil, "Item")
	AddDisambiguation("nithramus_the_allseer",					"legendary_ring_intellect", nil, nil, "Item")
	AddDisambiguation("sanctus_sigil_of_the_unbroken",			"legendary_ring_bonus_armor", nil, nil, "Item")
	AddDisambiguation("thorasus_the_stone_heart_of_draenor",	"legendary_ring_strength", nil, nil, "Item")
	-- Death Knight
	AddDisambiguation("arcane_torrent",			"arcane_torrent_runicpower",	"DEATHKNIGHT")
	AddDisambiguation("blood_fury",				"blood_fury_ap",				"DEATHKNIGHT")
	AddDisambiguation("breath_of_sindragosa_debuff",	"breath_of_sindragosa_buff",	"DEATHKNIGHT")
	AddDisambiguation("legendary_ring",			"legendary_ring_bonus_armor",	"DEATHKNIGHT",	"blood", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_strength",		"DEATHKNIGHT",	"frost", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_strength",		"DEATHKNIGHT",	"unholy", "Item")
	AddDisambiguation("soul_reaper",			"soul_reaper_blood",			"DEATHKNIGHT",	"blood")
	AddDisambiguation("soul_reaper",			"soul_reaper_frost",			"DEATHKNIGHT",	"frost")
	AddDisambiguation("soul_reaper",			"soul_reaper_unholy",			"DEATHKNIGHT",	"unholy")
	-- Demon Hunter
	AddDisambiguation("metamorphosis", 			"metamorphosis_veng", 			"DEMONHUNTER", "vengeance")
	AddDisambiguation("metamorphosis_buff", 	"metamorphosis_veng_buff", 		"DEMONHUNTER", "vengeance")
	AddDisambiguation("metamorphosis", 			"metamorphosis_havoc", 			"DEMONHUNTER", "havoc")
	AddDisambiguation("metamorphosis_buff", 	"metamorphosis_havoc_buff", 	"DEMONHUNTER", "havoc")
	AddDisambiguation("throw_glaive", 			"throw_glaive_veng", 			"DEMONHUNTER", "vengeance")
	AddDisambiguation("throw_glaive", 			"throw_glaive_havoc", 			"DEMONHUNTER", "havoc")
	-- Druid
	AddDisambiguation("arcane_torrent",			"arcane_torrent_energy",		"DRUID")
	AddDisambiguation("berserk",				"berserk_bear",					"DRUID",		"guardian")
	AddDisambiguation("berserk",				"berserk_cat",					"DRUID",		"feral")
	AddDisambiguation("blood_fury",				"blood_fury_apsp",				"DRUID")
	AddDisambiguation("dream_of_cenarius",		"dream_of_cenarius_caster",		"DRUID",		"balance")
	AddDisambiguation("dream_of_cenarius",		"dream_of_cenarius_melee",		"DRUID",		"feral")
	AddDisambiguation("dream_of_cenarius",		"dream_of_cenarius_tank",		"DRUID",		"guardian")
	AddDisambiguation("force_of_nature",		"force_of_nature_caster",		"DRUID",		"balance")
	AddDisambiguation("force_of_nature",		"force_of_nature_melee",		"DRUID",		"feral")
	AddDisambiguation("force_of_nature",		"force_of_nature_tank",			"DRUID",		"guardian")
	AddDisambiguation("fury_of_elue", 			"fury_of_elune", 				"DRUID")
	AddDisambiguation("heart_of_the_wild",		"heart_of_the_wild_tank",		"DRUID",		"guardian")
	AddDisambiguation("incarnation",			"incarnation_chosen_of_elune",	"DRUID",		"balance")
	AddDisambiguation("incarnation",			"incarnation_king_of_the_jungle",	"DRUID",	"feral")
	AddDisambiguation("incarnation",			"incarnation_son_of_ursoc",		"DRUID",		"guardian")
	AddDisambiguation("legendary_ring",			"legendary_ring_agility",		"DRUID",		"feral", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_bonus_armor",	"DRUID",		"guardian", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_intellect",		"DRUID",		"balance", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_spirit",		"DRUID",		"restoration", "Item")
	AddDisambiguation("lunar_strike", 			"lunar_strike_balance", 		"DRUID", 		"balance")
	AddDisambiguation("moonfire",				"moonfire_cat",					"DRUID",		"feral")
	AddDisambiguation("omen_of_clarity",		"omen_of_clarity_melee",		"DRUID",		"feral")
	AddDisambiguation("rejuvenation_debuff",	"rejuvenation_buff",			"DRUID")
	AddDisambiguation("starsurge",				"starsurge_moonkin",			"DRUID",		"balance")
	AddDisambiguation("frenzied_regeneration_debuff", "frenzied_regeneration_buff", "DRUID", 	"guardian")
	AddDisambiguation("thrash_debuff", 			"thrash_bear_debuff", 			"DRUID", 		"guardian")
	-- Hunter
	AddDisambiguation("arcane_torrent",			"arcane_torrent_focus",			"HUNTER")
	AddDisambiguation("beast_cleave",			"pet_beast_cleave",				"HUNTER",		"beast_mastery")
	AddDisambiguation("blood_fury",				"blood_fury_ap",				"HUNTER")
	AddDisambiguation("focusing_shot",			"focusing_shot_marksmanship",	"HUNTER",		"marksmanship")
	AddDisambiguation("frenzy",					"pet_frenzy",					"HUNTER",		"beast_mastery")
	AddDisambiguation("legendary_ring",			"legendary_ring_agility",		"HUNTER",		nil, "Item")
	AddDisambiguation("trueshot_debuff", "trueshot_buff", "HUNTER")
	-- Mage
	AddDisambiguation("arcane_torrent",			"arcane_torrent_mana",			"MAGE")
	AddDisambiguation("arcane_charge_buff",		"arcane_charge_debuff",			"MAGE",			"arcane")
	AddDisambiguation("blood_fury",				"blood_fury_sp",				"MAGE")
	AddDisambiguation("legendary_ring",			"legendary_ring_intellect",		"MAGE", 		nil, "Item")
	AddDisambiguation("water_jet",				"water_elemental_water_jet",	"MAGE",			"frost")
	-- Monk
	AddDisambiguation("arcane_torrent",			"arcane_torrent_chi",			"MONK")
	AddDisambiguation("blood_fury",				"blood_fury_apsp",				"MONK")
	AddDisambiguation("chi_explosion",			"chi_explosion_heal",			"MONK",			"mistweaver")
	AddDisambiguation("chi_explosion",			"chi_explosion_melee",			"MONK",			"windwalker")
	AddDisambiguation("chi_explosion",			"chi_explosion_tank",			"MONK",			"brewmaster")
	AddDisambiguation("legendary_ring",			"legendary_ring_agility",		"MONK",			"windwalker", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_bonus_armor",	"MONK",			"brewmaster", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_spirit",		"MONK",			"mistweaver", "Item")
	AddDisambiguation("zen_sphere_debuff",		"zen_sphere_buff",				"MONK")
	-- Paladin
	AddDisambiguation("arcane_torrent",			"arcane_torrent_holy",			"PALADIN")
	AddDisambiguation("avenging_wrath",			"avenging_wrath_heal",			"PALADIN",		"holy")
	AddDisambiguation("avenging_wrath",			"avenging_wrath_melee",			"PALADIN",		"retribution")
	AddDisambiguation("avenging_wrath",			"avenging_wrath_melee",			"PALADIN",		"protection")
	AddDisambiguation("blood_fury",				"blood_fury_apsp",				"PALADIN")
	AddDisambiguation("legendary_ring",			"legendary_ring_bonus_armor",	"PALADIN",		"protection", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_spirit",		"PALADIN",		"holy", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_strength",		"PALADIN",		"retribution", "Item")
	AddDisambiguation("sacred_shield_debuff",	"sacred_shield_buff",			"PALADIN")
	-- Priest
	AddDisambiguation("arcane_torrent",			"arcane_torrent_mana",			"PRIEST")
	AddDisambiguation("blood_fury",				"blood_fury_sp",				"PRIEST")
	AddDisambiguation("cascade",				"cascade_caster",				"PRIEST",		"shadow")
	AddDisambiguation("cascade",				"cascade_heal",					"PRIEST",		"discipline")
	AddDisambiguation("cascade",				"cascade_heal",					"PRIEST",		"holy")
	AddDisambiguation("devouring_plague_tick",	"devouring_plague",				"PRIEST")
	AddDisambiguation("divine_star",			"divine_star_caster",			"PRIEST",		"shadow")
	AddDisambiguation("divine_star",			"divine_star_heal",				"PRIEST",		"discipline")
	AddDisambiguation("divine_star",			"divine_star_heal",				"PRIEST",		"holy")
	AddDisambiguation("halo",					"halo_caster",					"PRIEST",		"shadow")
	AddDisambiguation("halo",					"halo_heal",					"PRIEST",		"discipline")
	AddDisambiguation("halo",					"halo_heal",					"PRIEST",		"holy")
	AddDisambiguation("legendary_ring",			"legendary_ring_intellect",		"PRIEST",		"shadow", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_spirit",		"PRIEST",		"discipline", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_spirit",		"PRIEST",		"holy", "Item")
	AddDisambiguation("renew_debuff",			"renew_buff",					"PRIEST")
	-- Rogue
	AddDisambiguation("arcane_torrent",			"arcane_torrent_energy",		"ROGUE")
	AddDisambiguation("blood_fury",				"blood_fury_ap",				"ROGUE")
	AddDisambiguation("legendary_ring",			"legendary_ring_agility",		"ROGUE",		nil, "Item")
	AddDisambiguation("stealth_buff",			"stealthed_buff",				"ROGUE")
	AddDisambiguation("roll_the_bones_debuff",	"roll_the_bones_buff",			"ROGUE")
	AddDisambiguation("envenom_debuff",			"envenom_buff",					"ROGUE")
	AddDisambiguation("vendetta_buff",			"vendetta_debuff",				"ROGUE",		"assassination") -- TODO Strange, is there actualy a buff?
	AddDisambiguation("deeper_strategem_talent","deeper_stratagem_talent",      "ROGUE",        "subtlety")
	AddDisambiguation("finality_nightblade_buff", "finality_nightblade_debuff", "ROGUE")
	-- Shaman
	AddDisambiguation("arcane_torrent",			"arcane_torrent_mana",			"SHAMAN")
	AddDisambiguation("ascendance",				"ascendance_caster",			"SHAMAN",		"elemental")
	AddDisambiguation("ascendance",				"ascendance_heal",				"SHAMAN",		"restoration")
	AddDisambiguation("ascendance",				"ascendance_melee",				"SHAMAN",		"enhancement")
	AddDisambiguation("blood_fury",				"blood_fury_apsp",				"SHAMAN")
	AddDisambiguation("legendary_ring",			"legendary_ring_agility",		"SHAMAN",		"enhancement", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_intellect",		"SHAMAN",		"elemental", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_spirit",		"SHAMAN",		"restoration", "Item")
	AddDisambiguation("unleashed_fury",			"unleashed_fury_melee",			"SHAMAN",		"enhancement", "Item")
	-- Warlock
	AddDisambiguation("arcane_torrent",			"arcane_torrent_mana",			"WARLOCK")
	AddDisambiguation("blood_fury",				"blood_fury_sp",				"WARLOCK")
	AddDisambiguation("dark_soul",				"dark_soul_instability",		"WARLOCK",		"destruction")
	AddDisambiguation("dark_soul",				"dark_soul_knowledge",			"WARLOCK",		"demonology")
	AddDisambiguation("dark_soul",				"dark_soul_misery",				"WARLOCK",		"affliction")
	AddDisambiguation("legendary_ring",			"legendary_ring_intellect",		"WARLOCK",		nil, "Item")
	AddDisambiguation("life_tap_debuff",		"empowered_life_tap_buff", "WARLOCK")
	-- Warrior
	AddDisambiguation("arcane_torrent",			"arcane_torrent_rage",			"WARRIOR")
	AddDisambiguation("blood_fury",				"blood_fury_ap",				"WARRIOR")
	AddDisambiguation("execute",				"execute_arms",					"WARRIOR",		"arms")
	AddDisambiguation("legendary_ring",			"legendary_ring_bonus_armor",	"WARRIOR",		"protection")
	AddDisambiguation("legendary_ring",			"legendary_ring_strength",		"WARRIOR",		"arms", "Item")
	AddDisambiguation("legendary_ring",			"legendary_ring_strength",		"WARRIOR",		"fury", "Item")
	AddDisambiguation("shield_barrier",			"shield_barrier_melee",			"WARRIOR",		"arms")
	AddDisambiguation("shield_barrier",			"shield_barrier_melee",			"WARRIOR",		"fury")
	AddDisambiguation("shield_barrier",			"shield_barrier_tank",			"WARRIOR",		"protection")
end

local function IsTotem(name)
	if strsub(name, 1, 13) == "wild_mushroom" then
		-- Druids.
		return true
	elseif name == "prismatic_crystal" or name == "rune_of_power" then
		-- Mages.
		return true
	elseif strsub(name, -7, -1) == "_statue" then
		-- Monks.
		return true
	elseif strsub(name, -6, -1) == "_totem" then
		-- Shamans.
		return true
	end
	return false
end

--[[--------------------------
	Split-by-tag functions
--]]--------------------------

local function NewLogicalNode(operator, lhsNode, rhsNode, nodeList)
	nodeList = nodeList or rhsNode
	local node = OvaleAST:NewNode(nodeList, true)
	node.type = "logical"
	node.operator = operator
	if operator == "not" then
		node.expressionType = "unary"
		node.child[1] = lhsNode
	else
		node.expressionType = "binary"
		node.child[1] = lhsNode
		node.child[2] = rhsNode
	end
	return node
end

local function ConcatenatedConditionNode(conditionList, nodeList, annotation)
	local conditionNode
	if #conditionList > 0 then
		if #conditionList == 1 then
			conditionNode = conditionList[1]
		elseif #conditionList > 1 then
			local lhsNode = conditionList[1]
			local rhsNode = conditionList[2]
			conditionNode = NewLogicalNode("or", lhsNode, rhsNode, nodeList)
			for k = 3, #conditionList do
				lhsNode = conditionNode
				rhsNode = conditionList[k]
				conditionNode = NewLogicalNode("or", lhsNode, rhsNode, nodeList)
			end
		end
	end
	return conditionNode
end

local function ConcatenatedBodyNode(bodyList, nodeList, annotation)
	local bodyNode
	if #bodyList > 0 then
		bodyNode = OvaleAST:NewNode(nodeList, true)
		bodyNode.type = "group"
		for k, node in ipairs(bodyList) do
			bodyNode.child[k] = node
		end
	end
	return bodyNode
end

local function OvaleTaggedFunctionName(name, tag)
	local bodyName, conditionName
	local prefix, suffix = strmatch(name, "([A-Z]%w+)(Actions)")
	if prefix and suffix then
		local camelTag
		if tag == "shortcd" then
			camelTag = "ShortCd"
		else
			camelTag = CamelCase(tag)
		end
		bodyName = prefix .. camelTag .. suffix
		conditionName = prefix .. camelTag .. "PostConditions"
	end
	return bodyName, conditionName
end

local function TagPriority(tag)
	return OVALE_TAG_PRIORITY[tag] or 10
end

local SPLIT_BY_TAG_VISITOR = nil
-- Forward declarations of split-by-tag functions.
local SplitByTag = nil
local SplitByTagAction = nil
local SplitByTagAddFunction = nil
local SplitByTagCustomFunction = nil
local SplitByTagGroup = nil
local SplitByTagIf = nil
local SplitByTagState = nil

SplitByTag = function(tag, node, nodeList, annotation)
	local visitor = SPLIT_BY_TAG_VISITOR[node.type]
	if not visitor then
		OvaleSimulationCraft:Error("Unable to split-by-tag node of type '%s'.", node.type)
	else
		return visitor(tag, node, nodeList, annotation)
	end
end

SplitByTagAction = function(tag, node, nodeList, annotation)
	local bodyNode, conditionNode
	local actionTag, invokesGCD
	local name = "UNKNOWN"
	local actionType = node.func
	if actionType == "item" or actionType == "spell" then
		local firstParamNode = node.rawPositionalParams[1]
		local id, name
		if firstParamNode.type == "variable" then
			name = firstParamNode.name
			id = annotation.dictionary and annotation.dictionary[name]
		elseif firstParamNode.type == "value" then
			name = firstParamNode.value
			id = name
		end
		if id then
			if actionType == "item" then
				actionTag, invokesGCD = OvaleData:GetItemTagInfo(id)
			elseif actionType == "spell" then
				actionTag, invokesGCD = OvaleData:GetSpellTagInfo(id)
			end
		else
			OvaleSimulationCraft:Print("Warning: Unable to find %s '%s'", actionType, name)
		end
	elseif actionType == "texture" then
		-- Textures are assumed to be "main" tag and invoke the GCD.
		actionTag = "main"
		invokesGCD = true
	else
		OvaleSimulationCraft:Print("Warning: Unknown action type '%'", actionType)
	end
	-- Default to "main" tag and assume the GCD is invoked.'
	if not actionTag then
		actionTag = "main"
		invokesGCD = true
		OvaleSimulationCraft:Print("Warning: Unable to determine tag for '%s', assuming '%s' (actionType: %s).", name, actionTag, actionType)
	end
	if actionTag == tag then
		bodyNode = node
	elseif invokesGCD and TagPriority(actionTag) < TagPriority(tag) then
		conditionNode = node
	end
	return bodyNode, conditionNode
end

SplitByTagAddFunction = function(tag, node, nodeList, annotation)
	local bodyName, conditionName = OvaleTaggedFunctionName(node.name, tag)

	-- Split the function body by the tag.
	local bodyNode, conditionNode = SplitByTag(tag, node.child[1], nodeList, annotation)
	if not bodyNode or bodyNode.type ~= "group" then
		local newGroupNode = OvaleAST:NewNode(nodeList, true)
		newGroupNode.type = "group"
		newGroupNode.child[1] = bodyNode
		bodyNode = newGroupNode
	end
	if not conditionNode or conditionNode.type ~= "group" then
		local newGroupNode = OvaleAST:NewNode(nodeList, true)
		newGroupNode.type = "group"
		newGroupNode.child[1] = conditionNode
		conditionNode = newGroupNode
	end

	-- Wrap groups in AddFunction() nodes.
	local bodyFunctionNode = OvaleAST:NewNode(nodeList, true)
	bodyFunctionNode.type = "add_function"
	bodyFunctionNode.name = bodyName
	bodyFunctionNode.child[1] = bodyNode

	local conditionFunctionNode = OvaleAST:NewNode(nodeList, true)
	conditionFunctionNode.type = "add_function"
	conditionFunctionNode.name = conditionName
	conditionFunctionNode.child[1] = conditionNode

	return bodyFunctionNode, conditionFunctionNode
end

SplitByTagCustomFunction = function(tag, node, nodeList, annotation)
	local bodyNode, conditionNode
	local functionName = node.name
	if annotation.taggedFunctionName[functionName] then
		local bodyName, conditionName = OvaleTaggedFunctionName(functionName, tag)
		-- Body.
		bodyNode = OvaleAST:NewNode(nodeList)
		bodyNode.name = bodyName
		bodyNode.lowername = strlower(bodyName)
		bodyNode.type = "custom_function"
		bodyNode.func = bodyName
		bodyNode.asString = bodyName .. "()"
		-- Post conditions.
		conditionNode = OvaleAST:NewNode(nodeList)
		conditionNode.name = conditionName
		conditionNode.lowername = strlower(conditionName)
		conditionNode.type = "custom_function"
		conditionNode.func = conditionName
		conditionNode.asString = conditionName .. "()"
	else
		local functionTag = annotation.functionTag[functionName]
		if not functionTag then
			if strfind(functionName, "Bloodlust") then
				functionTag = "cd"
			elseif strfind(functionName, "GetInMeleeRange") then
				functionTag = "shortcd"
			elseif strfind(functionName, "InterruptActions") then
				functionTag = "cd"
			elseif strfind(functionName, "SummonPet") then
				functionTag = "shortcd"
			elseif strfind(functionName, "UseItemActions") then
				functionTag = "cd"
			elseif strfind(functionName, "UsePotion") then
				functionTag = "cd"
			end
		end
		if functionTag then
			if functionTag == tag then
				bodyNode = node
			end
		else
			OvaleSimulationCraft:Print("Warning: Unable to determine tag for '%s()'.", node.name)
			bodyNode = node
		end
	end
	return bodyNode, conditionNode
end

SplitByTagGroup = function(tag, node, nodeList, annotation)
	local index = #node.child
	local bodyList = {}
	local conditionList = {}
	local remainderList = {}
	while index > 0 do
		local childNode = node.child[index]
		index = index - 1
		if childNode.type ~= "comment" then
			local bodyNode, conditionNode = SplitByTag(tag, childNode, nodeList, annotation)
			if conditionNode then
				tinsert(conditionList, 1, conditionNode)
				tinsert(remainderList, 1, conditionNode)
			end
			if bodyNode then
				if #conditionList == 0 then
					tinsert(bodyList, 1, bodyNode)
				elseif #bodyList == 0 then
					wipe(conditionList)
					tinsert(bodyList, 1, bodyNode)
				else -- if #conditionList > 0 and #bodyList > 0 then
					-- New body with pre-existing condition, so convert to an "unless" node.
					local unlessNode = OvaleAST:NewNode(nodeList, true)
					unlessNode.type = "unless"
					unlessNode.child[1] = ConcatenatedConditionNode(conditionList, nodeList, annotation)
					unlessNode.child[2] = ConcatenatedBodyNode(bodyList, nodeList, annotation)
					wipe(bodyList)
					wipe(conditionList)
					tinsert(bodyList, 1, unlessNode)
					-- Add a blank line above this "unless" node.
					local commentNode = OvaleAST:NewNode(nodeList)
					commentNode.type = "comment"
					tinsert(bodyList, 1, commentNode)
					-- Insert the new body.
					tinsert(bodyList, 1, bodyNode)
				end
				-- Peek at the previous statement to check if this is part of a "pool_resource" statement pair.
				if index > 0 then
					childNode = node.child[index]
					if childNode.type ~= "comment" then
						bodyNode, conditionNode = SplitByTag(tag, childNode, nodeList, annotation)
						if not bodyNode and index > 1 then
							-- The previous statement is not part of this tag, so check the comments above it for "pool_resource".
							local start = index - 1
							for k = index - 1, 1, -1 do
								childNode = node.child[k]
								if childNode.type == "comment" then
									if childNode.comment and strsub(childNode.comment, 1, 5) == "pool_" then
										-- Found the starting "pool_resource" comment.
										start = k
										break
									end
								else
									break
								end
							end
							if start < index - 1 then
								--[[
									This was part of a "pool_resource" statement pair where the previous statement
									is not part of this tag, so insert the comment block here as well for documentation,
									and "advance" the index to skip the previous statement altogether.
								--]]
								for k = index - 1, start, -1 do
									tinsert(bodyList, 1, node.child[k])
								end
								index = start - 1
							end
						end
					end
				end
				-- Insert the comment block from above the new body.
				while index > 0 do
					childNode = node.child[index]
					if childNode.type == "comment" then
						tinsert(bodyList, 1, childNode)
						index = index - 1
					else
						break
					end
				end
			end
		end
	end

	local bodyNode = ConcatenatedBodyNode(bodyList, nodeList, annotation)
	local conditionNode = ConcatenatedConditionNode(conditionList, nodeList, annotation)
	local remainderNode = ConcatenatedConditionNode(remainderList, nodeList, annotation)
	if bodyNode then
		if conditionNode then
			-- Combine conditions and body into an "unless" node.
			local unlessNode = OvaleAST:NewNode(nodeList, true)
			unlessNode.type = "unless"
			unlessNode.child[1] = conditionNode
			unlessNode.child[2] = bodyNode
			-- Create "group" node around the "unless" node.
			local groupNode = OvaleAST:NewNode(nodeList, true)
			groupNode.type = "group"
			groupNode.child[1] = unlessNode
			-- Set return values.
			bodyNode = groupNode
		end
		conditionNode = remainderNode
	end
	return bodyNode, conditionNode
end

SplitByTagIf = function(tag, node, nodeList, annotation)
	local bodyNode, conditionNode = SplitByTag(tag, node.child[2], nodeList, annotation)
	if conditionNode then
		-- Combine pre-existing conditions and new conditions into an "and" node.
		local lhsNode = node.child[1]
		local rhsNode = conditionNode
		if node.type == "unless" then
			-- Flip the boolean condition if the original node was an "unless" node.
			lhsNode = NewLogicalNode("not", lhsNode, nodeList)
		end
		local andNode = NewLogicalNode("and", lhsNode, rhsNode, nodeList)
		conditionNode = andNode
	end
	if bodyNode then
		-- Combine pre-existing conditions and body into an "if/unless" node.
		local ifNode = OvaleAST:NewNode(nodeList, true)
		ifNode.type = node.type
		ifNode.child[1] = node.child[1]
		ifNode.child[2] = bodyNode
		bodyNode = ifNode
	end
	return bodyNode, conditionNode
end

SplitByTagState = function(tag, node, nodeList, annotation)
	return node
end

do
	SPLIT_BY_TAG_VISITOR = {
		["action"] = SplitByTagAction,
		["add_function"] = SplitByTagAddFunction,
		["custom_function"] = SplitByTagCustomFunction,
		["group"] = SplitByTagGroup,
		["if"] = SplitByTagIf,
		["state"] = SplitByTagState,
		["unless"] = SplitByTagIf,
	}
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
local EmitOperandActiveDot = nil
local EmitOperandBuff = nil
local EmitOperandCharacter = nil
local EmitOperandCooldown = nil
local EmitOperandDisease = nil
local EmitOperandDot = nil
local EmitOperandGlyph = nil
local EmitOperandPet = nil
local EmitOperandPreviousSpell = nil
local EmitOperandRaidEvent = nil
local EmitOperandRace = nil
local EmitOperandRune = nil
local EmitOperandSeal = nil
local EmitOperandSetBonus = nil
local EmitOperandSpecial = nil
local EmitOperandTalent = nil
local EmitOperandTotem = nil
local EmitOperandTrinket = nil

Emit = function(parseNode, nodeList, annotation, action)
	local visitor = EMIT_VISITOR[parseNode.type]
	if not visitor then
		OvaleSimulationCraft:Error("Unable to emit node of type '%s'.", parseNode.type)
	else
		return visitor(parseNode, nodeList, annotation, action)
	end
end

EmitConditionNode = function(nodeList, bodyNode, conditionNode, parseNode, annotation, action)
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
		else
			conditionNode = extraConditionNode
		end
	end

	-- Create "if" node.
	if conditionNode then
		local node = OvaleAST:NewNode(nodeList, true)
		node.type = "if"
		node.child[1] = conditionNode
		node.child[2] = bodyNode
		if bodyNode.type == "simc_pool_resource" then
			node.simc_pool_resource = true
		elseif bodyNode.type == "simc_wait" then
			node.simc_wait = true
		end
		return node
	else
		return bodyNode
	end
end

EmitNamedVariable = function(name, nodeList, annotation, modifier, parseNode, action, conditionNode)
	if not annotation.variable then
		annotation.variable = {}
	end

	local node = annotation.variable[name]
	local group
	if not node then
		-- The variable does not already exist, create it
		node = OvaleAST:NewNode(nodeList, true)
		annotation.variable[name] = node
		node.type = "add_function"
		node.name = name
		-- The condition will be in a group that will be the first child
		group = OvaleAST:NewNode(nodeList, true)
		group.type = "group"
		node.child[1] = group
	else
		-- Add the condition to the existing group (the first child)
		group = node.child[1]
	end 

	-- Need to know which is the current variable in order to avoid recursive calls
	-- For now, there does not seems complicated cases where variable A uses variable B, which uses variable A
	annotation.currentVariable = node

	local value = Emit(modifier.value, nodeList, annotation, action)
	local newNode = EmitConditionNode(nodeList, value, conditionNode or nil, parseNode, annotation, action)
	if newNode.type == "if" then
		-- As Ovale stops at first value that is true, the if need to be in inverse order 
		tinsert(group.child, 1, newNode)
	else
		tinsert(group.child, newNode)
	end

	annotation.currentVariable = nil
end

EmitVariableMin = function(name, nodeList, annotation, modifier, parseNode, action)
	EmitNamedVariable(name .. "_min", nodeList, annotation, modifier, parseNode, action)
	local valueNode = annotation.variable[name] 
	valueNode.name = name .. "_value"
	annotation.variable[valueNode.name] = valueNode

	local bodyCode = format("AddFunction %s { if %s_value() > %s_min() %s_value() %s_min() }", name, name, name, name, name)
	local node = OvaleAST:ParseCode("add_function", bodyCode, nodeList, annotation.astAnnotation)
	annotation.variable[name] = node
end

EmitVariable = function(nodeList, annotation, modifier, parseNode, action, conditionNode)
	if not annotation.variable then
		annotation.variable = {}
	end

	local op = (modifier.op and Unparse(modifier.op)) or "set"
	local name = Unparse(modifier.name)
	if op == "min" then
		EmitVariableMin(name, nodeList, annotation, modifier, parseNode, action) 
	elseif op == "set" then
		EmitNamedVariable(name, nodeList, annotation, modifier, parseNode, action, conditionNode)
	else
		OvaleSimulationCraft:Error("Unknown variable operator '%s'.", op)
	end
end

EmitAction = function(parseNode, nodeList, annotation)
	local node
	local canonicalizedName = strlower(gsub(parseNode.name, ":", "_"))
	local class = annotation.class
	local specialization = annotation.specialization
	local camelSpecialization = CamelSpecialization(annotation)
	local role = annotation.role
	local action = Disambiguate(canonicalizedName, class, specialization)

	if action == "auto_attack" and not annotation.melee then
		-- skip
	elseif action == "auto_shot" then
		-- skip
	elseif action == "choose_target" then
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
		if class == "DEATHKNIGHT" and action == "antimagic_shell" then
			-- Only suggest Anti-Magic Shell if there is incoming magic damage to absorb to generate runic power.
			conditionCode = "IncomingDamage(1.5 magic=1) > 0"
		elseif class == "DEATHKNIGHT" and action == "mind_freeze" then
			bodyCode = camelSpecialization .. "InterruptActions()"
			annotation[action] = class
			annotation.interrupt = class
			isSpellAction = false
		elseif class == "DEMONHUNTER" and action == "consume_magic" then
			bodyCode = camelSpecialization .. "InterruptActions()"
			annotation[action] = class
			annotation.interrupt = class
			isSpellAction = false
		elseif class == "DRUID" and action == "pulverize" then
			--[[
				WORKAROUND: Work around Blizzard bug where Pulverize can only be used within 15s of
				when the existing Thrash stack was applied, regardless of how much time is left on
				the DoT: http://us.battle.net/wow/en/forum/topic/15354966771
			--]]
			local debuffName = "thrash_bear_debuff"
			AddSymbol(annotation, debuffName)
			conditionCode = format("target.DebuffGain(%s) <= BaseDuration(%s)", debuffName, debuffName)
		elseif class == "DRUID" and specialization == "guardian" and action == "rejuvenation" then
			-- Only cast Rejuvenation as a guardian druid if it is Enhanced Rejuvenation (castable in bear form).
			local spellName = "enhanced_rejuvenation"
			AddSymbol(annotation, spellName)
			conditionCode = format("SpellKnown(%s)", spellName)
		elseif class == "DRUID" and action == "skull_bash" then
			bodyCode = camelSpecialization .. "InterruptActions()"
			annotation[action] = class
			annotation.interrupt = class
			isSpellAction = false
		elseif class == "DRUID" and action == "wild_charge" then
			bodyCode = camelSpecialization .. "GetInMeleeRange()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "HUNTER" and (action == "muzzle" or action == "counter_shot") then
			bodyCode = camelSpecialization .. "InterruptActions()"
			annotation[action] = class
			annotation.interrupt = class
			isSpellAction = false
		elseif class == "HUNTER" and action == "exotic_munitions" then
			if modifier.ammo_type then
				local name = Unparse(modifier.ammo_type)
				action = name .. "_ammo"
				-- Always have at least 20 minutes of an Exotic Munitions buff applied when out of combat.
				local buffName = "exotic_munitions_buff"
				AddSymbol(annotation, buffName)
				conditionCode = format("BuffRemaining(%s) < 1200", buffName)
			else
				isSpellAction = false
			end
		elseif class == "HUNTER" and action == "kill_command" then
			-- Kill Command requires that a pet that can move freely.
			conditionCode = "pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned()"
		elseif class == "HUNTER" and action == "volley" then
			annotation.volley = class
			conditionCode = "CheckBoxOn(opt_volley)"
		elseif class == "HUNTER" and strsub(action, -5) == "_trap" then
			annotation.trap_launcher = class
			conditionCode = "CheckBoxOn(opt_trap_launcher)"
		elseif class == "MAGE" and action == "arcane_brilliance" then
			-- Only cast Arcane Brilliance if not already raid-buffed.
			conditionCode = "BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1)"
		elseif class == "MAGE" and action == "counterspell" then
			bodyCode = camelSpecialization .. "InterruptActions()"
			annotation[action] = class
			annotation.interrupt = class
			isSpellAction = false
		elseif class == "MAGE" and strfind(action, "pet_") then
			conditionCode = "pet.Present()"
		elseif class == "MAGE" and (action == "start_burn_phase" or action == "start_pyro_chain" or action == "stop_burn_phase" or action == "stop_pyro_chain") then
			--[[
				Translate the mage state actions using Ovale state variables:

					start_<state>	SetState(<state> 1)
					stop_<state>	SetState(<state> 0)

				Also insert checks so that the state is set only if it changes.
			--]]
			local stateAction, stateVariable = strmatch(action, "([^_]+)_(.*)")
			local value = (stateAction == "start") and 1 or 0
			if value == 0 then
				conditionCode = format("GetState(%s) > 0", stateVariable)
			else -- if value == 1 then
				conditionCode = format("not GetState(%s) > 0", stateVariable)
			end
			bodyCode = format("SetState(%s %d)", stateVariable, value)
			isSpellAction = false
		elseif class == "MAGE" and action == "time_warp" then
			-- Only suggest Time Warp if it will have an effect.
			conditionCode = "CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1)"
			annotation[action] = class
		elseif class == "MAGE" and action == "water_elemental" then
			-- Only suggest summoning the Water Elemental if the pet is not already summoned.
			conditionCode = "not pet.Present()"
		elseif class == "MONK" and action == "chi_burst" then
			-- Only suggest Chi Burst if it's toggled on.
			conditionCode = "CheckBoxOn(opt_chi_burst)"
			annotation[action] = class
		elseif class == "MONK" and action == "chi_sphere" then
			-- skip
			isSpellAction = false
		elseif class == "MONK" and action == "gift_of_the_ox" then
			-- skip
			isSpellAction = false
		elseif class == "MONK" and action == "nimble_brew" then
			-- Only suggest Nimble Brew to break snares, roots, and stuns.
			conditionCode = "IsFeared() or IsRooted() or IsStunned()"
		elseif class == "MONK" and action == "spear_hand_strike" then
			bodyCode = camelSpecialization .. "InterruptActions()"
			annotation[action] = class
			annotation.interrupt = class
			isSpellAction = false
		elseif class == "MONK" and action == "storm_earth_and_fire" then
			conditionCode = "CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff)"
			annotation[action] = class
		elseif class == "MONK" and action == "whirling_dragon_punch" then
			conditionCode = "SpellCooldown(fists_of_fury)>0 and SpellCooldown(rising_sun_kick)>0"
		elseif class == "PALADIN" and action == "blessing_of_kings" then
			-- Only cast Blessing of Kings if it won't overwrite the player's own Blessing of Might.
			conditionCode = "BuffExpires(mastery_buff)"
		elseif class == "PALADIN" and action == "judgment" then
			-- If "cycle_targets=1" is used with Judgment, then it is for the Glyph of Double Jeopardy.
			if modifier.cycle_targets then
				AddSymbol(annotation, action)
				bodyCode = "Spell(" .. action .. " text=double)"
				isSpellAction = false
			end
		elseif class == "PALADIN" and action == "rebuke" then
			bodyCode = camelSpecialization .. "InterruptActions()"
			annotation[action] = class
			annotation.interrupt = class
			isSpellAction = false
		elseif class == "PALADIN" and specialization == "protection" and action == "arcane_torrent_holy" then
			-- skip
			isSpellAction = false
		elseif class == "PALADIN" and action == "righteous_fury" then
			-- Only suggest Righteous Fury if the check is toggled on.
			conditionCode = "CheckBoxOn(opt_righteous_fury_check)"
			annotation[action] = class
		elseif class == "PRIEST" and action == "silence" then
			bodyCode = camelSpecialization .. "InterruptActions()"
			annotation[action] = class
			annotation.interrupt = class
			isSpellAction = false
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
		elseif class == "ROGUE" and specialization == "combat" and action == "blade_flurry" then
			annotation.blade_flurry = class
			conditionCode = "CheckBoxOn(opt_blade_flurry)"
		elseif class == "ROGUE" and action == "honor_among_thieves" then
			if modifier.cooldown then
				local cooldown = Unparse(modifier.cooldown)
				local buffName = action .. "_cooldown_buff"
				annotation[buffName] = cooldown
				annotation[action] = class
			end
			isSpellAction = false
		elseif class == "ROGUE" and action == "kick" then
			bodyCode = camelSpecialization .. "InterruptActions()"
			annotation[action] = class
			annotation.interrupt = class
			isSpellAction = false
		elseif class == "ROGUE" and action == "premeditation" then
			-- Don't suggest Premeditation if already at the combo point cap.
			conditionCode = "ComboPoints() < 5"
		elseif class == "ROGUE" and specialization == "combat" and action == "slice_and_dice" then
			-- Don't suggest Slice and Dice if a more powerful buff is already in effect.
			local buffName = "slice_and_dice_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffRemaining(%s) < BaseDuration(%s)", buffName, buffName)
		elseif class == "ROGUE" and (specialization == "assassination" or specialization == "combat") and action == "vanish" then
			--[[
				Allow toggling Vanish suggestions for Assassination and Combat so they can be used
				situationally.  Vanish is a major DPS cooldown for Subtlety so the suggestion can't
				be toggled for that specialization.
			--]]
			annotation.vanish = class
			conditionCode = format("CheckBoxOn(opt_vanish)", spellName)
		elseif class == "SHAMAN" and strsub(action, 1, 11) == "ascendance_" then
			-- Ascendance doesn't go on cooldown until after the buff expires, so don't
			-- suggest Ascendance if already in Ascendance.
			local buffName = action .. "_buff"
			AddSymbol(annotation, buffName)
			conditionCode = format("BuffExpires(%s)", buffName)
		elseif class == "SHAMAN" and action == "bloodlust" then
			bodyCode = camelSpecialization .. "Bloodlust()"
			annotation[action] = class
			isSpellAction = false
		elseif class == "SHAMAN" and action == "magma_totem" then
			-- Only suggest Magma Totem if within melee range of the target.
			local spellName = "primal_strike"
			AddSymbol(annotation, spellName)
			conditionCode = format("target.InRange(%s)", spellName)
		elseif class == "SHAMAN" and action == "wind_shear" then
			bodyCode = camelSpecialization .. "InterruptActions()"
			annotation[action] = class
			annotation.interrupt = class
			isSpellAction = false
		elseif class == "WARLOCK" and action == "cancel_metamorphosis" then
			local spellName = "metamorphosis"
			local buffName = "metamorphosis_buff"
			AddSymbol(annotation, spellName)
			AddSymbol(annotation, buffName)
			bodyCode = format("Spell(%s text=cancel)", spellName)
			conditionCode = format("BuffPresent(%s)", buffName)
			isSpellAction = false
		elseif class == "WARLOCK" and action == "felguard_felstorm" then
			conditionCode = "pet.Present() and pet.CreatureFamily(Felguard)"
		elseif class == "WARLOCK" and action == "grimoire_of_sacrifice" then
			-- Grimoire of Sacrifice requires a pet to already be summoned.
			conditionCode = "pet.Present()"
		elseif class == "WARLOCK" and action == "havoc" then
			-- Havoc requires another target.
			conditionCode = "Enemies() > 1"
		elseif class == "WARLOCK" and action == "service_pet" then
			if annotation.pet then
				local spellName = "service_" .. annotation.pet
				AddSymbol(annotation, spellName)
				bodyCode = format("Spell(%s)", spellName)
			else
				bodyCode = "Texture(spell_nature_removecurse help=ServicePet)"
			end
			isSpellAction = false
		elseif class == "WARLOCK" and action == "summon_pet" then
			if annotation.pet then
				local spellName = "summon_" .. annotation.pet
				AddSymbol(annotation, spellName)
				bodyCode = format("Spell(%s)", spellName)
			else
				bodyCode = "Texture(spell_nature_removecurse help=L(summon_pet))"
			end
			-- Only summon a pet if one is not already summoned.
			conditionCode = "not pet.Present()"
			isSpellAction = false
		elseif class == "WARLOCK" and action == "wrathguard_wrathstorm" then
			conditionCode = "pet.Present() and pet.CreatureFamily(Wrathguard)"
		elseif class == "WARRIOR" and action == "battle_shout" and role == "tank" then
			-- Only cast Battle Shout if it won't overwrite the player's own Commanding Shout.
			conditionCode = "BuffExpires(stamina_buff)"
		elseif class == "WARRIOR" and action == "charge" then
			conditionCode = "CheckBoxOn(opt_melee_range) and target.InRange(charge)"
		elseif class == "WARRIOR" and action == "commanding_shout" and role == "attack" then
			-- Only cast Commanding Shout if it won't overwrite the player's own Battle Shout.
			conditionCode = "BuffExpires(attack_power_multiplier_buff)"
		elseif class == "WARRIOR" and action == "enraged_regeneration" then
			-- Only suggest Enraged Regeneration at below 80% health.
			conditionCode = "HealthPercent() < 80"
		elseif class == "WARRIOR" and strsub(action, 1, 7) == "execute" then
			if modifier.target then
				local target = tonumber(Unparse(modifier.target))
				if target then
					-- Skip "execute" actions if they are not on the main target.
					isSpellAction = false
				end
			end
		elseif class == "WARRIOR" and action == "heroic_charge" then
			--[[
				"Heroic Charge" is moving out of melee range enough to Charge back to the target
				in order to gain more rage.
			--]]
			-- skip
			isSpellAction = false
		elseif class == "WARRIOR" and action == "heroic_leap" then
			-- Use Charge as a range-finder for Heroic Leap.
			local spellName = "charge"
			AddSymbol(annotation, spellName)
			conditionCode = format("CheckBoxOn(opt_melee_range) and target.InRange(%s)", spellName)
		elseif class == "WARRIOR" and action == "pummel" then
			bodyCode = camelSpecialization .. "InterruptActions()"
			annotation[action] = class
			annotation.interrupt = class
			isSpellAction = false
		elseif action == "auto_attack" then
			bodyCode = camelSpecialization .. "GetInMeleeRange()"
			isSpellAction = false
		elseif class == "DEMONHUNTER" and action == "variable" and Unparse(modifier.name) == "pooling_for_meta" then
			-- Add a checkbox asking whether to only pool for meta during boss fights
			local conditionCode = "not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight()"
			local conditionNode = OvaleAST:ParseCode(expressionType, conditionCode, nodeList, annotation.astAnnotation)
			EmitVariable(nodeList, annotation, modifier, parseNode, action, conditionNode)
			isSpellAction = false
			annotation.pooling_for_meta = class
		elseif action == "variable" then
			EmitVariable(nodeList, annotation, modifier, parseNode, action)
			isSpellAction = false
		elseif action == "call_action_list" or action == "run_action_list" or action == "swap_action_list" then
			if modifier.name then
				local name = Unparse(modifier.name)
				local functionName = OvaleFunctionName(name, annotation)
				bodyCode = functionName .. "()"
				-- Special-case the "burn" action list for arcane mages.
				if class == "MAGE" and specialization == "arcane" and (name == "burn" or name == "init_burn") then
					conditionCode = "CheckBoxOn(opt_arcane_mage_burn_phase)"
					annotation.opt_arcane_mage_burn_phase = class
				end
			end
			isSpellAction = false
		elseif action == "cancel_buff" then
			if modifier.name then
				local spellName = Unparse(modifier.name)
				local buffName = spellName .. "_buff"
				AddSymbol(annotation, spellName)
				AddSymbol(annotation, buffName)
				bodyCode = format("Texture(%s text=cancel)", spellName)
				conditionCode = format("BuffPresent(%s)", buffName)
				isSpellAction = false
			end
		elseif action == "mana_potion" then
			bodyCode = camelSpecialization .. "UsePotionMana()"
			annotation.use_potion_mana = class
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
		elseif action == "potion" then
			if modifier.name then
				local name = Unparse(modifier.name)
				local stat = POTION_STAT[name]
				if stat == "agility" then
					bodyCode = camelSpecialization .. "UsePotionAgility()"
					annotation.use_potion_agility = class
				elseif stat == "armor" then
					bodyCode = camelSpecialization .. "UsePotionArmor()"
					annotation.use_potion_armor = class
				elseif stat == "intellect" then
					bodyCode = camelSpecialization .. "UsePotionIntellect()"
					annotation.use_potion_intellect = class
				elseif stat == "strength" then
					bodyCode = camelSpecialization .. "UsePotionStrength()"
					annotation.use_potion_strength = class
				end
				isSpellAction = false
			end
		elseif action == "stance" then
			if modifier.choose then
				local name = Unparse(modifier.choose)
				if class == "MONK" then
					action = "stance_of_the_" .. name
				elseif class == "WARRIOR" then
					action = name .. "_stance"
				else
					action = name
				end
			else
				isSpellAction = false
			end
		elseif action == "summon_pet" then
			bodyCode = camelSpecialization .. "SummonPet()"
			annotation[action] = class
			isSpellAction = false
		elseif action == "use_item" then
			local legendaryRing = false
			if modifier.slot then
				local slot = Unparse(modifier.slot)
				if strmatch(slot, "finger") then
					legendaryRing = Disambiguate("legendary_ring", class, specialization)
				end
			elseif modifier.name then
				local name = Unparse(modifier.name)
				name = Disambiguate(name, class, specialization)
				if strmatch(name, "legendary_ring") then
					legendaryRing = name
				elseif false then
					-- Use named item and require the symbol name.
					bodyCode = format("Item(%s usable=1)", name)
					AddSymbol(annotation, name)
				end
			end
			if legendaryRing then
				conditionCode = format("CheckBoxOn(opt_%s)", legendaryRing)
				bodyCode = format("Item(%s usable=1)", legendaryRing)
				AddSymbol(annotation, legendaryRing)
				annotation.use_legendary_ring = legendaryRing
			else
				--[[
					When "use_item" is encountered in an action list, it is usually meant to use
					all of the equipped trinkets at the same time.
				--]]
				bodyCode = camelSpecialization .. "UseItemActions()"
				annotation[action] = true
			end
			isSpellAction = false
		elseif action == "wait" then
			if modifier.sec then
				local seconds = tonumber(Unparse(modifier.sec))
				if seconds then
					--[[
						Ovale does not support SimulationCraft's concept of "waiting for N seconds".
						Just skip if the modifier sec=N is present, where N is a number.
					--]]
				else
					--[[
						Create a special "wait" AST node that will be transformed in
						a later step into something OvaleAST can understand and unparse.
					--]]
					bodyNode = OvaleAST:NewNode(nodeList)
					bodyNode.type = "simc_wait"
					-- "wait,sec=expr" means to halt the processing of the action list if "expr > 0".
					local expressionNode = Emit(modifier.sec, nodeList, annotation, action)
					local code = OvaleAST:Unparse(expressionNode)
					conditionCode = code .. " > 0"
				end
			end
			isSpellAction = false
		end
		if isSpellAction then
			AddSymbol(annotation, action)
			if modifier.target then
				local actionTarget = Unparse(modifier.target)
				if actionTarget == "2" then
					actionTarget = "other"
				end
				if actionTarget ~= "1" then
					bodyCode = format("Spell(%s text=%s)", action, actionTarget)
				end
			end
			bodyCode = bodyCode or "Spell(" .. action .. ")"
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
			node = EmitConditionNode(nodeList, bodyNode, conditionNode, parseNode, annotation, action)
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
					local powerType = OvalePower.POOLED_RESOURCE[annotation.class]
					if powerType then
						if statementNode.for_next then
							poolResourceNode = statementNode
							poolResourceNode.powerType = powerType
						else
							-- This is a bare "pool_resource" statement, which means pool
							-- continually and skip the rest of the action list.
							emit = false
						end
					end
				elseif poolResourceNode then
					-- This is the action following "pool_resource,for_next=1".
					child[#child + 1] = statementNode
					local bodyNode
					local poolingConditionNode
					if statementNode.child then
						-- This is a conditional statement, so set the body to the "then" clause.
						poolingConditionNode = statementNode.child[1]
						bodyNode = statementNode.child[2]
					else
						bodyNode = statementNode
					end
					local powerType = CamelCase(poolResourceNode.powerType)
					local extra_amount = poolResourceNode.extra_amount
					if extra_amount and poolingConditionNode then
						-- Remove any 'Energy() >= N' conditions from the pooling condition.
						local code = OvaleAST:Unparse(poolingConditionNode)
						local extraAmountPattern = powerType .. "%(%) >= [%d.]+"
						local replaceString = format("True(pool_%s %d)", poolResourceNode.powerType, extra_amount)
						code = gsub(code, extraAmountPattern, replaceString)
						poolingConditionNode = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
					end
					if bodyNode.type == "action" and bodyNode.rawPositionalParams and bodyNode.rawPositionalParams[1] then
						local name = OvaleAST:Unparse(bodyNode.rawPositionalParams[1])
						-- Create a condition node that includes checking that the spell is not on cooldown.
						local powerCondition
						if extra_amount then
							powerCondition = format("TimeTo%s(%d)", powerType, extra_amount)
						else
							powerCondition = format("TimeTo%sFor(%s)", powerType, name)
						end
						local code = format("SpellUsable(%s) and SpellCooldown(%s) < %s", name, name, powerCondition)
						local conditionNode = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
						if statementNode.child then
							local rhsNode = conditionNode
							conditionNode = OvaleAST:NewNode(nodeList, true)
							conditionNode.type = "logical"
							conditionNode.expressionType = "binary"
							conditionNode.operator = "and"
							conditionNode.child[1] = poolingConditionNode
							conditionNode.child[2] = rhsNode
						end
						-- Create node to hold the rest of the statements.
						local restNode = OvaleAST:NewNode(nodeList, true)
						child[#child + 1] = restNode
						if statementNode.type == "unless" then
							restNode.type = "if"
						else
							restNode.type = "unless"
						end
						restNode.child[1] = conditionNode
						restNode.child[2] = OvaleAST:NewNode(nodeList, true)
						restNode.child[2].type = "group"
						child = restNode.child[2].child
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
	node.name = OvaleFunctionName(parseNode.name, annotation)
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
			elseif parseNode.operator == "^" then
				operator = "xor"
			elseif parseNode.operator == "|" then
				operator = "or"
			elseif parseNode.operator == "=" then
				operator = "=="
			elseif parseNode.operator == "%" then
				operator = "/"
			elseif parseNode.type == "compare" or parseNode.type == "arithmetic" then
				operator = parseNode.operator
			end
			if parseNode.type == "compare" and parseNode.child[1].rune then
				--[[
					Special handling for rune comparisons.
					This ONLY handles rune expressions of the form "<rune><operator><number>".
					These are translated to equivalent "Rune(<rune>) <operator> <number>" expressions,
					but with some munging of the numbers since Rune() returns a fractional number of runes.
				--]]
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
					local runeFunction = "Rune"
					local runeCondition
					runeCondition = runeFunction .. "()"
					if op == ">" then
						code = format("%s >= %d", runeCondition, number + 1)
					elseif op == ">=" then
						code = format("%s >= %d", runeCondition, number)
					elseif op == "=" then
						code = format("%s >= %d", runeCondition, number)
					elseif op == "<=" then
						code = format("%s < %d", runeCondition, number + 1)
					elseif op == "<" then
						code = format("%s < %d", runeCondition, number)
					end
					if not node and code then
						annotation.astAnnotation = annotation.astAnnotation or {}
						node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
					end
				end
			elseif (parseNode.operator == "=" or parseNode.operator == "!=") and (parseNode.child[1].name == "target" or parseNode.child[1].name == "current_target") then
				--[[
					Special handling for "target=X" or "current_target=X" expressions.
				--]]
				local rhsNode = parseNode.child[2]
				local name = rhsNode.name
				-- Strip out any leading "target." or "pet." prefixes.
				if strfind(name, "^[%a_]+%.") then
					name = strmatch(name, "^[%a_]+%.([%a_]+)")
				end
				local code
				if parseNode.operator == "=" then
					code = format("target.Name(%s)", name)
				else -- if parseNode.operator == "!=" then
					code = format("not target.Name(%s)", name)
				end
				AddSymbol(annotation, name)
				annotation.astAnnotation = annotation.astAnnotation or {}
				node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
			-- elseif (parseNode.operator == "=" or parseNode.operator == "!=") and parseNode.child[1].name == "last_judgment_target" then
			-- 	local code
			-- 	if parseNode.operator == "=" then
			-- 		code = "True(last_judgement_target)"
			-- 	else -- if parseNode.operator == "!=" then
			-- 		local buffName = "glyph_of_double_jeopardy_buff"
			-- 		code = "BuffPresent(" .. buffName .. ")"
			-- 		AddSymbol(annotation, buffName)
			-- 	end
			-- 	annotation.astAnnotation = annotation.astAnnotation or {}
			-- 	node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
			elseif (parseNode.operator == "=" or parseNode.operator == "!=") and parseNode.child[1].name == "sim_target" then
				--[[
					Special handling for "sim_target=X" expressions.
					Ovale has no concept of the "primary", "main" or "boss" target, so "sim_target=X" is always true.
				--]]
				local code
				if parseNode.operator == "=" then
					code = "True(target_is_sim_target)"
				else -- if parseNode.operator == "!=" then
					code = "False(target_is_sim_target)"
				end
				annotation.astAnnotation = annotation.astAnnotation or {}
				node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
			elseif operator then
				local lhsNode = Emit(parseNode.child[1], nodeList, annotation, action)
				local rhsNode = Emit(parseNode.child[2], nodeList, annotation, action)
				if lhsNode and rhsNode then
					node = OvaleAST:NewNode(nodeList, true)
					node.type = opInfo[1]
					node.expressionType = "binary"
					node.operator = operator
					node.child[1] = lhsNode
					node.child[2] = rhsNode
				elseif lhsNode then
					msg = Ovale:MakeString("Warning: %s operator '%s' right failed.", parseNode.type, parseNode.operator)
				elseif rhsNode then
					msg = Ovale:MakeString("Warning: %s operator '%s' left failed.", parseNode.type, parseNode.operator)
				else
					msg = Ovale:MakeString("Warning: %s operator '%s' left and right failed.", parseNode.type, parseNode.operator)
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
		msg = msg or Ovale:MakeString("Warning: Operator '%s' is not implemented.", parseNode.operator)
		OvaleSimulationCraft:Print(msg)
		node = OvaleAST:NewNode(nodeList)
		node.type = "string"
		node.value = "FIXME_" .. parseNode.operator
	end
	return node
end

EmitFunction = function(parseNode, nodeList, annotation, action)
	local node
	if parseNode.name == "ceil" or parseNode.name == "floor" then
		-- Pretend ceil and floor have no effect.
		node = EmitExpression(parseNode.child[1], nodeList, annotation, action)
	else
		OvaleSimulationCraft:Print("Warning: Function '%s' is not implemented.", parseNode.name)
		node = OvaleAST:NewNode(nodeList)
		node.type = "variable"
		node.name = "FIXME_" .. parseNode.name
	end
	return node
end

EmitModifier = function(modifier, parseNode, nodeList, annotation, action)
	local node, code
	local class = annotation.class
	local specialization = annotation.specialization

	if modifier == "if" then
		node = Emit(parseNode, nodeList, annotation, action)
	elseif modifier == "target_if" then
		-- TODO In fact, it asks to change the target to a target that fullfill this condition
		-- Because it is not supported, for now just apply the condition to the current target
		node = Emit(parseNode, nodeList, annotation, action)
	elseif modifier == "five_stacks" and action == "focus_fire" then
		local value = tonumber(Unparse(parseNode))
		if value == 1 then
			local buffName = "pet_frenzy_buff"
			AddSymbol(annotation, buffName)
			code = format("pet.BuffStacks(%s) >= 5", buffName)
		end
	elseif modifier == "line_cd" then
		if not SPECIAL_ACTION[action] then
			AddSymbol(annotation, action)
			local expressionCode = OvaleAST:Unparse(Emit(parseNode, nodeList, annotation, action))
			code = format("TimeSincePreviousSpell(%s) > %s", action, expressionCode)
		end
	elseif modifier == "max_cycle_targets" then
		local debuffName = action .. "_debuff"
		AddSymbol(annotation, debuffName)
		local expressionCode = OvaleAST:Unparse(Emit(parseNode, nodeList, annotation, action))
		code = format("DebuffCountOnAny(%s) < Enemies() and DebuffCountOnAny(%s) <= %s", debuffName, debuffName, expressionCode)
	elseif modifier == "max_energy" then
		local value = tonumber(Unparse(parseNode))
		if value == 1 then
			-- SimulationCraft's max_energy is the maximum energy cost of the action if used.
			code = format("Energy() >= EnergyCost(%s max=1)", action)
		end
	elseif modifier == "min_frenzy" and action == "focus_fire" then
		local value = tonumber(Unparse(parseNode))
		if value then
			local buffName = "pet_frenzy_buff"
			AddSymbol(annotation, buffName)
			code = format("pet.BuffStacks(%s) >= %d", buffName, value)
		end
	elseif modifier == "moving" then
		local value = tonumber(Unparse(parseNode))
		if value == 0 then
			code = "not Speed() > 0"
		else
			code = "Speed() > 0"
		end
	elseif modifier == "sync" then
		local name = Unparse(parseNode)
		-- Fix only known case where we need to disambiguate a name within a SimulationCraft profile.
		if name == "whirlwind_mh" then
			name = "whirlwind"
		end
		node = annotation.astAnnotation and annotation.astAnnotation.sync and annotation.astAnnotation.sync[name]
		if not node then
			local syncParseNode = annotation.sync[name]
			if syncParseNode then
				local syncActionNode = EmitAction(syncParseNode, nodeList, annotation)
				local syncActionType = syncActionNode.type
				if syncActionType == "action" then
					node = syncActionNode
				elseif syncActionType == "custom_function" then
					node = syncActionNode
				elseif syncActionType == "if" or syncActionType == "unless" then
					local lhsNode = syncActionNode.child[1]
					if syncActionType == "unless" then
						-- Flip the boolean condition for an "unless" node.
						local notNode = OvaleAST:NewNode(nodeList, true)
						notNode.type = "logical"
						notNode.expressionType = "unary"
						notNode.operator = "not"
						notNode.child[1] = lhsNode
						lhsNode = notNode
					end
					local rhsNode = syncActionNode.child[2]
					local andNode = OvaleAST:NewNode(nodeList, true)
					andNode.type = "logical"
					andNode.expressionType = "binary"
					andNode.operator = "and"
					andNode.child[1] = lhsNode
					andNode.child[2] = rhsNode
					node = andNode
				else
					OvaleSimulationCraft:Print("Warning: Unable to emit action for 'sync=%s'.", name)
					name = Disambiguate(name, class, specialization)
					AddSymbol(annotation, name)
					code = format("Spell(%s)", name)
				end
			end
		end
		if node then
			annotation.astAnnotation = annotation.astAnnotation or {}
			annotation.astAnnotation.sync = annotation.astAnnotation.sync or {}
			annotation.astAnnotation.sync[name] = node
		end
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
	if token == "target" then
		target = token
		operand = strsub(operand, strlen(target) + 2)		-- consume
		token = strmatch(operand, OPERAND_TOKEN_PATTERN)	-- peek
	end
	ok, node = EmitOperandRune(operand, parseNode, nodeList, annotation, action)
	if not ok then
		ok, node = EmitOperandSpecial(operand, parseNode, nodeList, annotation, action, target)
	end
	if not ok then
		ok, node = EmitOperandRaidEvent(operand, parseNode, nodeList, annotation, action)
	end
	if not ok then
		ok, node = EmitOperandRace(operand, parseNode, nodeList, annotation, action)
	end
	if not ok then
		ok, node = EmitOperandAction(operand, parseNode, nodeList, annotation, action, target)
	end
	if not ok then
		ok, node = EmitOperandCharacter(operand, parseNode, nodeList, annotation, action, target)
	end
	if not ok then
		if token == "active_dot" then
			target = target or "target"
			ok, node = EmitOperandActiveDot(operand, parseNode, nodeList, annotation, action, target)
		elseif token == "aura" then
			ok, node = EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target)
		elseif token == "artifact" then
			ok, node = EmitOperandArtifact(operand, parseNode, nodeList, annotation, action, target)
		elseif token == "buff" then
			ok, node = EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target)
		elseif token == "cooldown" then
			ok, node = EmitOperandCooldown(operand, parseNode, nodeList, annotation, action)
		elseif token == "debuff" then
			target = target or "target"
			ok, node = EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target)
		elseif token == "disease" then
			target = target or "target"
			ok, node = EmitOperandDisease(operand, parseNode, nodeList, annotation, action, target)
		elseif token == "dot" then
			target = target or "target"
			ok, node = EmitOperandDot(operand, parseNode, nodeList, annotation, action, target)
		elseif token == "glyph" then
			ok, node = EmitOperandGlyph(operand, parseNode, nodeList, annotation, action)
		elseif token == "pet" then
			ok, node = EmitOperandPet(operand, parseNode, nodeList, annotation, action)
		elseif token == "prev" or token == "prev_gcd" or token == "prev_off_gcd" then
			ok, node = EmitOperandPreviousSpell(operand, parseNode, nodeList, annotation, action)
		elseif token == "refreshable" then
			ok, node = EmitOperandRefresh(operand, parseNode, nodeList, annotation, action)
		elseif token == "seal" then
			ok, node = EmitOperandSeal(operand, parseNode, nodeList, annotation, action)
		elseif token == "set_bonus" then
			ok, node = EmitOperandSetBonus(operand, parseNode, nodeList, annotation, action)
		elseif token == "talent" then
			ok, node = EmitOperandTalent(operand, parseNode, nodeList, annotation, action)
		elseif token == "totem" then
			ok, node = EmitOperandTotem(operand, parseNode, nodeList, annotation, action)
		elseif token == "trinket" then
			ok, node = EmitOperandTrinket(operand, parseNode, nodeList, annotation, action)
		elseif token == "variable" then
			ok, node = EmitOperandVariable(operand, parseNode, nodeList, annotation, action)
		end
	end
	if not ok then
		OvaleSimulationCraft:Print("Warning: Variable '%s' is not implemented.", parseNode.name)
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

	local class, specialization = annotation.class, annotation.specialization
	name = Disambiguate(name, class, specialization)
	target = target and (target .. ".") or ""
	local buffName = name .. "_debuff"
	buffName = Disambiguate(buffName, class, specialization)
	local prefix = strfind(buffName, "_buff$") and "Buff" or "Debuff"
	local buffTarget = (prefix == "Debuff") and "target." or target
	local talentName = name .. "_talent"
	talentName = Disambiguate(talentName, class, specialization)
	local symbol = name

	local code
	if property == "active" then
		if IsTotem(name) then
			code = format("TotemPresent(%s)", name)
		else
			code = format("%s%sPresent(%s)", target, prefix, buffName)
			symbol = buffName
		end
	elseif property == "cast_regen" then
		code = format("FocusCastingRegen(%s)", name)
	elseif property == "cast_time" then
		code = format("CastTime(%s)", name)
	elseif property == "charges" then
		code = format("Charges(%s)", name)
	elseif property == "max_charges" then
		code = format("SpellMaxCharges(%s)", name)
	elseif property == "charges_fractional" then
		code = format("Charges(%s count=0)", name)
	elseif property == "cooldown" then
		code = format("SpellCooldown(%s)", name)
	elseif property == "cooldown_react" then
		code = format("not SpellCooldown(%s) > 0", name)
	elseif property == "cost" then
		code = format("PowerCost(%s)", name)
	elseif property == "crit_damage" then
		code = format("%sCritDamage(%s)", target, name)
	elseif property == "duration" or property == "new_duration" then -- TODO #75
		code = format("BaseDuration(%s)", buffName)
		symbol = buffName
	elseif property == "enabled" then
		if parseNode.asType == "boolean" then
			code = format("Talent(%s)", talentName)
		else
			code = format("TalentPoints(%s)", talentName)
		end
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
	elseif property == "persistent_multiplier" then
		code = format("PersistentMultiplier(%s)", buffName)
	elseif property == "recharge_time" then
		code = format("SpellChargeCooldown(%s)", name)
	elseif property == "remains" then
		if IsTotem(name) then
			code = format("TotemRemaining(%s)", name)
		else
			code = format("%s%sRemaining(%s)", buffTarget, prefix, buffName)
			symbol = buffName
		end
	elseif property == "shard_react" then
		-- XXX
		code = "SoulShards() >= 1"
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
		code = format("TravelTime(%s)", name)
	elseif property == "usable" then
		code = format("Spell(%s)", name)
	elseif property == "usable_in" then
		code = format("Spell(%s)", name)
	else
		ok = false
	end
	if ok and code then
		if name == "call_action_list" and property ~= "gcd" then
			OvaleSimulationCraft:Print("Warning: dubious use of call_action_list in %s", code)
		end
		annotation.astAnnotation = annotation.astAnnotation or {}
		node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
		if not SPECIAL_ACTION[symbol] then
			AddSymbol(annotation, symbol)
		end
	end

	return ok, node
end

EmitOperandActiveDot = function(operand, parseNode, nodeList, annotation, action, target)
	local ok = true
	local node

	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "active_dot" then
		local name = tokenIterator()
		name = Disambiguate(name, annotation.class, annotation.specialization)
		local dotName = name .. "_debuff"
		dotName = Disambiguate(dotName, annotation.class, annotation.specialization)
		local prefix = strfind(dotName, "_buff$") and "Buff" or "Debuff"
		target = target and (target .. ".") or ""

		local code = format("%sCountOnAny(%s)", prefix, dotName)
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

EmitOperandArtifact = function(operand, parseNode, nodeList, annotation, action, target)
	local ok = true
	local node
	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "artifact" then
		local name = tokenIterator()
		local property = tokenIterator()

		if property == "rank" then
			code = format("ArtifactTraitRank(%s)", name) 
		elseif property == "enabled" then
			code = format("HasArtifactTrait(%s)", name)
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

EmitOperandRefresh = function(operand, parseNode, nodeList, annotation, action, target)
	local ok = true
	local node
	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "refreshable" then
		local buffName = action .. "_debuff"
		buffName = Disambiguate(buffName, annotation.class, annotation.specialization)
		local target
		local prefix = strfind(buffName, "_buff$") and "Buff" or "Debuff"
		if prefix == "Debuff" then 
			target = "target."
		else
			target = ""
		end
		local any = OvaleData.DEFAULT_SPELL_LIST[buffName] and " any=1" or ""
		-- TODO Surely not the right function, need to look in simulationcraft code what means "refreshable"  
		local code = format("%sRefreshable(%s%s)", target, buffName, any)
		node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
		AddSymbol(annotation, buffName)
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
		local any = OvaleData.DEFAULT_SPELL_LIST[buffName] and " any=1" or ""
		target = target and (target .. ".") or ""

		-- Unholy death knight's Dark Transformation applies the buff to the ghoul/pet.
		if buffName == "dark_transformation_buff" and target == "" then
			target = "pet."
		end
		-- Hunter's Beast Cleave is a buff on the hunter's pet.
		if buffName == "pet_beast_cleave_buff" and target == "" then
			target = "pet."
		end
		-- Hunter's Frenzy is a buff on both the player and the pet, but track the pet one.
		if buffName == "pet_frenzy_buff" and target == "" then
			target = "pet."
		end

		-- Assume that the "potion" action has already been seen.
		if buffName == "potion_buff" then
			if annotation.use_potion_agility then
				buffName = "potion_agility_buff"
			elseif annotation.use_potion_armor then
				buffName = "potion_armor_buff"
			elseif annotation.use_potion_intellect then
				buffName = "potion_intellect_buff"
			elseif annotation.use_potion_strength then
				buffName = "potion_strength_buff"
			end
		end

		local code
		if property == "cooldown_remains" then
			-- Assume that the spell and the buff have the same name.
			code = format("SpellCooldown(%s)", name)
		elseif property == "down" then
			code = format("%s%sExpires(%s%s)", target, prefix, buffName, any)
		elseif property == "duration" then
			code = format("BaseDuration(%s)", buffName)
		elseif property == "max_stack" then
			code = format("SpellData(%s max_stacks)", buffName)
		elseif property == "react" or property == "stack" then
			if parseNode.asType == "boolean" then
				code = format("%s%sPresent(%s%s)", target, prefix, buffName, any)
			else
				code = format("%s%sStacks(%s%s)", target, prefix, buffName, any)
			end
		elseif property == "remains" then
			if parseNode.asType == "boolean" then
				code = format("%s%sPresent(%s%s)", target, prefix, buffName, any)
			else
				code = format("%s%sRemaining(%s%s)", target, prefix, buffName, any)
			end
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
		["astral_power"] 		= "AstralPower()",
		["astral_power.deficit"]= "AstralPowerDeficit()",
		["blade_dance_worth_using"] = "0",--TODO
		["blood.frac"]			= "Rune(blood)",
		["buff.out_of_range.up"] = "not target.InRange()",
		["chi"]					= "Chi()",
		["chi.max"]				= "MaxChi()",
		["combo_points"]		= "ComboPoints()",
		["combo_points.deficit"]= "ComboPointsDeficit()",
		["combo_points.max"]    = "MaxComboPoints()",
		["cp_max_spend"]		= "MaxComboPoints()", -- TODO Difference with combo_points.max??
		["crit_pct_current"]	= "SpellCritChance()",
		["current_insanity_drain"] = "CurrentInsanityDrain()",
		["darkglare_no_de"]     = "NotDeDemons(darkglare)",
		["death_sweep_worth_using"] = "0", --TODO
		["delay"]				= "0", -- TODO
		["demonic_fury"]		= "DemonicFury()",
		["desired_targets"]		= "Enemies(tagged=1)",
		["doomguard_no_de"]		= "NotDeDemons(doomguard)",
		["dreadstalker_no_de"]  = "NotDeDemons(dreadstalker)",
		["dreadstalker_remaining_duration"] = "DemonDuration(dreadstalker)",
		["eclipse_change"]		= "TimeToEclipse()",	-- XXX
		["eclipse_energy"]		= "EclipseEnergy()",	-- XXX
		["enemies"]				= "Enemies()",
		["energy"]				= "Energy()",
		["energy.deficit"]		= "EnergyDeficit()",
		["energy.max"]			= "MaxEnergy()",
		["energy.regen"]		= "EnergyRegenRate()",
		["energy.time_to_max"]	= "TimeToMaxEnergy()",
		["feral_spirit.remains"] = "TotemRemaining(sprit_wolf)",
		["finality"]			= "HasArtifactTrait(finality)",
		["focus"]				= "Focus()",
		["focus.deficit"]		= "FocusDeficit()",
		["focus.max"]			= "MaxFocus()",
		["focus.regen"]			= "FocusRegenRate()",
		["focus.time_to_max"]	= "TimeToMaxFocus()",
		["frost.frac"]			= "Rune(frost)",
		["fury"]				= "Fury()",
		["fury.deficit"]		= "FuryDeficit()",
		["health"]				= "Health()",
		["health.deficit"]		= "HealthMissing()",
		["health.max"]			= "MaxHealth()",
		["health.pct"]			= "HealthPercent()",
		["health.percent"]		= "HealthPercent()",
		["holy_power"]			= "HolyPower()",
		["infernal_no_de"]		= "NotDeDemons(infernal)",
		["insanity"]			= "Insanity()",
		["level"]				= "Level()",
		["lunar_max"]			= "TimeToEclipse(lunar)",	-- XXX
		["mana"]				= "Mana()",
		["mana.deficit"]		= "ManaDeficit()",
		["mana.max"]			= "MaxMana()",
		["mana.pct"]			= "ManaPercent()",
		["maelstrom"]			= "Maelstrom()",
		["nonexecute_actors_pct"] = "0", -- TODO #74
		["pain"]				= "Pain()",
		["rage"]				= "Rage()",
		["rage.deficit"]		= "RageDeficit()",
		["rage.max"]			= "MaxRage()",
		["raw_haste_pct"]		= "SpellHaste()",
		["rtb_list.any.5"]		= "BuffCount(roll_the_bones_buff more 4)",
		["rtb_list.any.6"]		= "BuffCount(roll_the_bones_buff more 5)",
		["runic_power"]			= "RunicPower()",
		["runic_power.deficit"]	= "RunicPowerDeficit()",
		["service_no_de"]		= "0", -- TODO manage service pet in WildImps.lua
		["shadow_orb"]			= "ShadowOrbs()",
		["sigil_placed"]		= "SigilCharging(flame)",
		["solar_max"]			= "TimeToEclipse(solar)",	-- XXX
		["soul_shard"]			= "SoulShards()",
		["soul_fragments"]		= "BuffStacks(soul_fragments)",
		["ssw_refund_offset"]	= "target.Distance() % 3 - 1",
		["stat.multistrike_pct"]= "MultistrikeChance()",
		["stealthed"]			= "Stealthed()",
		["stealthed.all"]		= "Stealthed()",
		["stealthed.rogue"]		= "Stealthed()",
		["time"]				= "TimeInCombat()",
		["time_to_20pct"]		= "TimeToHealthPercent(20)",
		["time_to_die"]			= "TimeToDie()",
		["time_to_die.remains"]	= "TimeToDie()",
		["wild_imp_count"] 		= "Demons(wild_imp)",
		["wild_imp_no_de"]		= "NotDeDemons(wild_imp)",
		["wild_imp_remaining_duration"] = "DemonDuration(wild_imp)"
	}

	EmitOperandCharacter = function(operand, parseNode, nodeList, annotation, action, target)
		local ok = true
		local node

		local class = annotation.class
		local specialization = annotation.specialization
		local camelSpecialization = CamelSpecialization(annotation)

		target = target and (target .. ".") or ""
		local code
		if CHARACTER_PROPERTY[operand] then
			code = target .. CHARACTER_PROPERTY[operand]
		elseif class == "MAGE" and operand == "incanters_flow_dir" then
			local name = "incanters_flow_buff"
			code = format("BuffDirection(%s)", name)
			AddSymbol(annotation, name)
		elseif class == "PALADIN" and operand == "time_to_hpg" then
			code = camelSpecialization .. "TimeToHPG()"
			if specialization == "holy" then
				annotation.time_to_hpg_heal = class
			elseif specialization == "protection" then
				annotation.time_to_hpg_tank = class
			elseif specialization == "retribution" then
				annotation.time_to_hpg_melee = class
			end
		elseif class == "PRIEST" and operand == "shadowy_apparitions_in_flight" then
			--[[
				Ovale does not currently track Shadowy Apparitions.  For now, always
				assume there is one in flight.
			--]]
			code = "1"
		elseif operand == "rtb_buffs" then
			code = "BuffCount(roll_the_bones_buff)"
		elseif class == "ROGUE" and operand == "anticipation_charges" then
			local name = "anticipation_buff"
			code = format("BuffStacks(%s)", name)
			AddSymbol(annotation, name)
		elseif strsub(operand, 1, 22) == "active_enemies_within." then
			-- "active_enemies_within.<distance>" is roughly equivalent to the number of enemies.
			code = "Enemies()"
		elseif strfind(operand, "^incoming_damage_") then
			local seconds, measure = strmatch(operand, "^incoming_damage_([%d]+)(m?s?)$")
			seconds = tonumber(seconds)
			if measure == "ms" then
				seconds = seconds / 1000
			end
			if parseNode.asType == "boolean" then
				code = format("IncomingDamage(%f) > 0", seconds)
			else
				code = format("IncomingDamage(%f)", seconds)
			end
		elseif strsub(operand, 1, 10) == "main_hand." then
			local weaponType = strsub(operand, 11)
			if weaponType == "1h" then
				code = "HasWeapon(main type=one_handed)"
			elseif weaponType == "2h" then
				code = "HasWeapon(main type=two_handed)"
			end
		elseif operand == "mastery_value" then
			code = format("%sMasteryEffect() / 100", target)
		elseif operand == "position_front" then
			-- "position_front" should always be false in Ovale because we assume the
			-- player can get into the optimal attack position at all times.
			code = "False(position_front)"
		elseif strsub(operand, 1, 5) == "role." then
			local role = strmatch(operand, "^role%.([%w_]+)")
			if role and role == annotation.role then
				code = format("True(role_%s)", role)
			else
				code = format("False(role_%s)", role)
			end
		elseif operand == "spell_haste" or operand == "stat.spell_haste" then
			-- "spell_haste" is the player's spell factor, e.g.,
			-- 25% haste corresponds to a "spell_haste" value of 1/(1 + 0.25) = 0.8.
			code = "100 / { 100 + SpellHaste() }"
		elseif operand == "attack_haste" or operand == "stat.attack_haste" then
			code = "100 / { 100 + MeleeHaste() }"
		elseif strsub(operand, 1, 13) == "spell_targets" then
			-- "spell_target.<spell>" is roughly equivalent to the number of enemies.
			code = "Enemies()"
		elseif operand == "t18_class_trinket" then
			code = format("HasTrinket(%s)", operand)
			AddSymbol(annotation, operand)
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
		local prefix
		name, prefix = Disambiguate(name, annotation.class, annotation.specialization, "Spell")
				
		-- Assume that the "potion" action has already been seen.
		if name == "potion" then
			prefix = "Item"
			if annotation.use_potion_agility then
				name = "draenic_agility_potion"
			elseif annotation.use_potion_armor then
				name = "draenic_armor_potion"
			elseif annotation.use_potion_intellect then
				name = "draenic_intellect_potion"
			elseif annotation.use_potion_strength then
				name = "draenic_strength_potion"
			end
		end

		local code
		if property == "execute_time" then
			code = format("ExecuteTime(%s)", name)
		elseif property == "duration" then
			code = format("%sCooldownDuration(%s)", prefix, name)
		elseif property == "ready" then
			code = format("%sCooldown(%s) == 0", prefix, name)
		elseif property == "remains" then
			if parseNode.asType == "boolean" then
				code = format("%sCooldown(%s) > 0", prefix, name)
			else
				code = format("%sCooldown(%s)", prefix, name)
			end
		elseif property == "up" then
			code = format("not %sCooldown(%s) > 0", prefix, name)
		elseif property == "charges" then
			if parseNode.asType == "boolean" then
				code = format("%sChargeCooldown(%s) > 0", prefix, name)
			else
				code = format("%sChargeCooldown(%s)", prefix, name)
			end
		elseif property == "charges_fractional" then
			code = format("%sCharges(%s count=0)", prefix, name)
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

EmitOperandDisease = function(operand, parseNode, nodeList, annotation, action, target)
	local ok = true
	local node

	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "disease" then
		local property = tokenIterator()
		target = target and (target .. ".") or ""

		local code
		if property == "max_ticking" then
			code = target .. "DiseasesAnyTicking()"
		elseif property == "min_remains" then
			code = target .. "DiseasesRemaining()"
		elseif property == "min_ticking" then
			code = target .. "DiseasesTicking()"
		elseif property == "ticking" then
			code = target .. "DiseasesAnyTicking()"
		else
			ok = false
		end
		if ok and code then
			annotation.astAnnotation = annotation.astAnnotation or {}
			node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
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
		if property == "duration" then
			code = format("%s%sDuration(%s)", target, prefix, dotName)
		elseif property == "pmultiplier" then
			code = format("%s%sPersistentMultiplier(%s)", target, prefix, dotName)
		elseif property == "remains" then
			code = format("%s%sRemaining(%s)", target, prefix, dotName)
		elseif property == "stack" then
			code = format("%s%sStacks(%s)", target, prefix, dotName)
		elseif property == "tick_dmg" then
			code = format("%sTickValue(%s)", target, prefix, dotName)
		elseif property == "ticking" then
			code = format("%s%sPresent(%s)", target, prefix, dotName)
		elseif property == "ticks_remain" then
			code = format("%sTicksRemaining(%s)", target, dotName)
		elseif property == "exsanguinated" then
			code = format("TargetDebuffRemaining(%s_exsanguinated)", dotName)
		elseif property == "refreshable" then
			code = format("%s%sRefreshable(%s)", target, prefix, dotName)
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

EmitOperandPet = function(operand, parseNode, nodeList, annotation, action)
	local ok = true
	local node

	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "pet" then
		local name = tokenIterator()
		local property = tokenIterator()
		name = Disambiguate(name, annotation.class, annotation.specialization)
		local isTotem = IsTotem(name)
		local code
		if isTotem and property == "active" then
			code = format("TotemPresent(%s)", name)
		elseif isTotem and property == "remains" then
			code = format("TotemRemaining(%s)", name)
		elseif property == "active" then
			code = "pet.Present()"
		elseif name == "buff" then
			local pattern = format("^pet%%.([%%w_.]+)", operand)
			local petOperand = strmatch(operand, pattern)

			ok, node = EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, "pet")
		else
			-- Strip the "pet.<name>." from the operand and re-evaluate.
			local pattern = format("^pet%%.%s%%.([%%w_.]+)", name)
			local petOperand = strmatch(operand, pattern)
			local target = "pet"
			if petOperand then
				ok, node = EmitOperandSpecial(petOperand, parseNode, nodeList, annotation, action, target)
				if not ok then
					ok, node = EmitOperandAction(petOperand, parseNode, nodeList, annotation, action, target)
				end
				if not ok then
					ok, node = EmitOperandCharacter(petOperand, parseNode, nodeList, annotation, action, target)
				end
				if not ok then
					-- Prefix the pet ability name with the name of the pet if it does not already begin with "pet".
					local petAbilityName = strmatch(petOperand, "^[%w_]+%.([^.]+)")
					petAbilityName = Disambiguate(petAbilityName, annotation.class, annotation.specialization)
					if strsub(petAbilityName, 1, 4) ~= "pet_" then
						petOperand = gsub(petOperand, "^([%w_]+)%.", "%1." .. name .. "_")
					end
					if property == "buff" then
						ok, node = EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, target)
					elseif property == "cooldown" then
						ok, node = EmitOperandCooldown(petOperand, parseNode, nodeList, annotation, action)
					elseif property == "debuff" then
						ok, node = EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, target)
					else
						ok = false
					end
				end
			else
				ok = false
			end
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

EmitOperandPreviousSpell = function(operand, parseNode, nodeList, annotation, action)
	local ok = true
	local node

	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "prev" or token == "prev_gcd" or token == "prev_off_gcd" then
		local name = tokenIterator()
		local howMany = 1
		if tonumber(name) ~= math.nan then
			howMany = tonumber(name)
			name = tokenIterator()
		end
		name = Disambiguate(name, annotation.class, annotation.specialization)
		local code
		if token == "prev" then
			code = format("PreviousSpell(%s)", name)
		elseif token == "prev_gcd" then
			if howMany ~= 1 then
				code = format("PreviousGCDSpell(%s count=%d)", name, howMany)
			else
				code = format("PreviousGCDSpell(%s)", name)
			end
		else -- if token == "prev_off_gcd" then
			code = format("PreviousOffGCDSpell(%s)", name)
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

EmitOperandRaidEvent = function(operand, parseNode, nodeList, annotation, action)
	local ok = true
	local node

	local name
	local property
	if strsub(operand, 1, 11) == "raid_event." then
		local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
		local token = tokenIterator()
		name = tokenIterator()
		property = tokenIterator()
	else
		local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
		name = tokenIterator()
		property = tokenIterator()
	end

	local code
	if name == "movement" then
		--[[
			The "movement" raid event simulates needing to move during the encounter.
			We always assume the fight is Patchwerk-style, meaning no movement is
			necessary.
		--]]
		if property == "cooldown" or property == "in" then
			-- Pretend the next "movement" raid event is ten minutes from now.
			code = "600"
		elseif property == "distance" then
			code = "target.Distance()"
		elseif property == "exists" then
			code = "False(raid_event_movement_exists)"
		elseif property == "remains" then
			code = "0"
		else
			ok = false
		end
	elseif name == "adds" then
		--[[
			The "adds" raid event simulates waves of adds on regular intervals.
			This is separate from the dynamic number of active enemies.
			We always assume that there are no add waves.
		--]]
		if property == "cooldown" then
			-- Pretend the next "adds" raid event is ten minutes from now.
			code = "600"
		elseif property == "count" then
			code = "0"
		elseif property == "exists" or property == "up" then
			code = "False(raid_event_adds_exists)"
		elseif property == "in" then
			-- Pretend the next "adds" raid event is ten minutes from now.
			code = "600"
		else
			ok = false
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

EmitOperandRace = function(operand, parseNode, nodeList, annotation, action)
	local ok = true
	local node
	
	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "race" then
		local race = strlower(tokenIterator())
		local code
		if race then
			local raceId = nil
			if(race == "blood_elf") then
				raceId = "BloodElf"
			else
				self:Print("Warning: Race '%s' not defined", race)				
			end
			code = format("Race(%s)", raceId)
		else
			ok = false
		end
		if ok and code then
			annotation.astAnnotation = annotation.astAnnotation or {}
			node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
		end
	else
		ok = false
	end

	return ok, node
end

EmitOperandRune = function(operand, parseNode, nodeList, annotation, action)
	local ok = true
	local node

	local code
	if parseNode.rune then
		if parseNode.asType == "boolean" then
			code = "RuneCount() >= 1"
		else
			code = "RuneCount()"
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

EmitOperandSetBonus = function(operand, parseNode, nodeList, annotation, action)
	local ok = true
	local node

	local setBonus = strmatch(operand, "^set_bonus%.(.*)$")
	local code
	if setBonus then
		local tokenIterator = gmatch(setBonus, "[^_]+")
		local name = tokenIterator()
		local count = tokenIterator()
		local role = tokenIterator()
		if name and count then
			local setName, level = strmatch(name, "^(%a+)(%d*)$")
			if setName == "tier" then
				setName = "T"
			else
				setName = strupper(setName)
			end
			if level then
				name = setName .. tostring(level)
			end
			if role then
				name = name .. "_" .. role
			end
			count = strmatch(count, "(%d+)pc")
			if name and count then
				code = format("ArmorSetBonus(%s %d)", name, count)
			end
		end
		if not code then
			ok = false
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

EmitOperandSeal = function(operand, parseNode, nodeList, annotation, action)
	local ok = true
	local node

	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	if token == "seal" then
		local name = strlower(tokenIterator())
		local code
		if name then
			code = format("Stance(paladin_seal_of_%s)", name)
		else
			ok = false
		end
		if ok and code then
			annotation.astAnnotation = annotation.astAnnotation or {}
			node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
		end
	else
		ok = false
	end

	return ok, node
end

EmitOperandSpecial = function(operand, parseNode, nodeList, annotation, action, target)
	local ok = true
	local node

	local class = annotation.class
	local specialization = annotation.specialization

	target = target and (target .. ".") or ""
	operand = strlower(operand)
	local code
	if class == "DEATHKNIGHT" and operand == "dot.breath_of_sindragosa.ticking" then
		-- Breath of Sindragosa is the player buff from channeling the spell.
		local buffName = "breath_of_sindragosa_buff"
		code = format("BuffPresent(%s)", buffName)
		AddSymbol(annotation, buffName)
	elseif class == "DEATHKNIGHT" and strsub(operand, -9, -1) == ".ready_in" then
		local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
		local spellName = tokenIterator()
		spellName = Disambiguate(spellName, class, specialization)
		code = format("TimeToSpell(%s)", spellName)
		AddSymbol(annotation, spellName)
	elseif class == "DEATHKNIGHT" and strsub(operand, 1, 24) == "pet.dancing_rune_weapon." then
		local petOperand = strsub(operand, 25)
		local tokenIterator = gmatch(petOperand, OPERAND_TOKEN_PATTERN)
		local token = tokenIterator()
		if token == "active" then
			local buffName = "dancing_rune_weapon_buff"
			code = format("BuffPresent(%s)", buffName)
			AddSymbol(annotation, buffName)
		elseif token == "dot" then
			if target == "" then
				target = "target"
			else
				target = strsub(target, 1, -2)
			end
			ok, node = EmitOperandDot(petOperand, parseNode, nodeList, annotation, action, target)
		end
	elseif class == "DRUID" and operand == "buff.wild_charge_movement.down" then
		-- "wild_charge_movement" is a fake SimulationCraft buff that lasts for the
		-- duration of the movement during Wild Charge.
		code = "True(wild_charge_movement_down)"
	elseif class == "DRUID" and operand == "eclipse_dir.lunar" then
		code = "EclipseDir() < 0"
	elseif class == "DRUID" and operand == "eclipse_dir.solar" then
		code = "EclipseDir() > 0"
	elseif class == "DRUID" and operand == "max_fb_energy" then
		-- SimulationCraft's max_fb_energy is the maximum cost of Ferocious Bite if used.
		local spellName = "ferocious_bite"
		code = format("EnergyCost(%s max=1)", spellName)
		AddSymbol(annotation, spellName)
	elseif class == "HUNTER" and operand == "buff.careful_aim.up" then
		-- The "careful_aim" buff is a fake SimulationCraft buff.
		code = "target.HealthPercent() > 80 or BuffPresent(rapid_fire_buff)"
		AddSymbol(annotation, "rapid_fire_buff")
	elseif class == "HUNTER" and operand == "buff.stampede.remains" then
		--[[
			There is no "Stampede" buff visible on the client-side, so just check how long since
			Stampede was previously cast.  The duration of the effect is 40 seconds.
		--]]
		local spellName = "stampede"
		code = format("TimeSincePreviousSpell(%s) < 40", spellName)
		AddSymbol(annotation, spellName)
	elseif class == "MAGE" and operand == "buff.rune_of_power.remains" then
		code = "TotemRemaining(rune_of_power)"
	elseif class == "MAGE" and operand == "buff.shatterlance.up" then
		--[[
			Shatterlance is a hidden buff applied by the T18 mage class trinket after a Frostbolt
			is cast.  Implement as a check for the T18 class trinket and whether the previous spell
			was Frostbolt.
		--]]
		code = "HasTrinket(t18_class_trinket) and PreviousGCDSpell(frostbolt)"
		AddSymbol(annotation, "frostbolt")
		AddSymbol(annotation, "t18_class_trinket")
	elseif class == "MAGE" and (operand == "burn_phase" or operand == "pyro_chain") then
		if parseNode.asType == "boolean" then
			code = format("GetState(%s) > 0", operand)
		else
			code = format("GetState(%s)", operand)
		end
	elseif class == "MAGE" and (operand == "burn_phase_duration" or operand == "pyro_chain_duration") then
		local variable = strsub(operand, 1, -10)
		if parseNode.asType == "boolean" then
			code = format("GetStateDuration(%s) > 0", variable)
		else
			code = format("GetStateDuration(%s)", variable)
		end
	elseif class == "MAGE" and operand == "dot.frozen_orb.ticking" then
		-- The Frozen Orb is ticking if fewer than 10s have elapsed since it was cast.
		local name = "frozen_orb"
		code = format("SpellCooldown(%s) > SpellCooldownDuration(%s) - 10", name, name)
		AddSymbol(annotation, name)
	elseif class == "MONK" and strsub(operand, 1, 35) == "debuff.storm_earth_and_fire_target." then
		local property = strsub(operand, 36)
		if target == "" then
			target = "target."
		end
		local debuffName = "storm_earth_and_fire_target_debuff"
		AddSymbol(annotation, debuffName)
		if property == "down" then
			code = format("%sDebuffExpires(%s)", target, debuffName)
		elseif property == "up" then
			code = format("%sDebuffPresent(%s)", target, debuffName)
		else
			ok = false
		end
	elseif class == "MONK" and operand == "dot.zen_sphere.ticking" then
		-- Zen Sphere is a helpful DoT.
		local buffName = "zen_sphere_buff"
		code = format("BuffPresent(%s)", buffName)
		AddSymbol(annotation, buffName)
	elseif class == "MONK" and strsub(operand, 1, 8) == "stagger." then
		local property = strsub(operand, 9)
		if property == "heavy" or property == "light" or property == "moderate" then
			local buffName = format("%s_stagger_debuff", property)
			code = format("DebuffPresent(%s)", buffName)
			AddSymbol(annotation, buffName)
		elseif property == "pct" then
			code = format("%sStaggerRemaining() / %sMaxHealth() * 100", target, target)
		else
			ok = false
		end
	elseif class == "PALADIN" and operand == "dot.sacred_shield.remains" then
		--[[
			Sacred Shield is handled specially because SimulationCraft treats it like
			a damaging spell, e.g., "target.dot.sacred_shield.remains" to represent the
			buff on the player.
		--]]
		local buffName = "sacred_shield_buff"
		code = format("BuffRemaining(%s)", buffName)
		AddSymbol(annotation, buffName)
	elseif class == "PRIEST" and operand == "mind_harvest" then
		code = "target.MindHarvest()"
	elseif class == "PRIEST" and operand == "natural_shadow_word_death_range" then
		code = "target.HealthPercent() < 20"
	elseif class == "PRIEST" and operand == "primary_target" then
		-- Ovale has no concept of the "primary", "main" or "boss" target, so "primary_target" should always return 1.
		code = "1"
	elseif class == "ROGUE" and operand == "poisoned_enemies" then
		-- TODO Need to track the number of poisoned enemies
		code = "0" 
	elseif class == "ROGUE" and operand == "exsanguinated" then
		code = "target.DebuffPresent(exsanguinated)"
	elseif class == "ROGUE" and specialization == "subtlety" and strsub(operand, 1, 29) == "cooldown.honor_among_thieves." then
		-- The cooldown of Honor Among Thieves is implemented as a hidden buff.
		local property = strsub(operand, 30)
		local buffName = "honor_among_thieves_cooldown_buff"
		AddSymbol(annotation, buffName)
		annotation.honor_among_thieves = class
		if property == "down" then
			code = format("BuffPresent(%s)", buffName)
		elseif property == "remains" then
			code = format("BuffRemaining(%s)", buffName)
		elseif property == "up" then
			code = format("BuffExpires(%s)", buffName)
		else
			ok = false
		end
	elseif class == "SHAMAN" and strmatch(operand, "pet.[a-z_]+.remains") then
		-- TODO Don't know how to do this
		code = "PetPresent()"
		ok = true
	elseif class == "WARLOCK" and strmatch(operand, "pet%.service_[a-z_]+%..+") then
		local spellName, property = strmatch(operand, "pet%.(service_[a-z_]+)%.(.+)")
		if property == "active" then
			--[[
				It's not possible to track guardian pets, so assume the pet is active
				if the spell was recently placed on cooldown.  The "service_pet" spells
				have a shared cooldown of 120s and the guardian pet lasts for 20s.
			--]]
			code = format("SpellCooldown(%s) > 100", spellName)
			AddSymbol(annotation, spellName)
		else
			ok = false
		end
	elseif class == "WARLOCK" and strmatch(operand, "dot.unstable_affliction_([1-5]).remains") then
		local num = strmatch(operand, "dot.unstable_affliction_([1-5]).remains")
		code = format("target.DebuffStacks(unstable_affliction_debuff) >= %s", num)
	elseif class == "WARRIOR" and strsub(operand, 1, 23) == "buff.colossus_smash_up." then
		local property = strsub(operand, 24)
		local debuffName = "colossus_smash_debuff"
		AddSymbol(annotation, debuffName)
		if property == "down" then
			code = format("DebuffCountOnAny(%s) == 0", debuffName)
		elseif property == "up" then
			code = format("DebuffCountOnAny(%s) > 0", debuffName)
		else
			ok = false
		end
	elseif class == "WARRIOR" and operand == "buff.revenge.react" then
		code = "RageCost(revenge) == 0"
	elseif operand == "buff.enrage.down" then
		code = "not " .. target .. "IsEnraged()"
	elseif operand == "buff.enrage.remains" then
		code = target .. "EnrageRemaining()"
	elseif operand == "buff.enrage.up" then
		code = target .. "IsEnraged()"
	elseif operand == "debuff.casting.react" then
		code = target .. "IsInterruptible()"
	elseif operand == "debuff.casting.up" then
		local t = (target == "" and "target.") or target
		code = t.."IsInterruptible()"
	elseif operand == "debuff.flying.down" then
		code = target .. "True(debuff_flying_down)"
	elseif operand == "distance" then
		code = target .. "Distance()"
	elseif strsub(operand, 1, 9) == "equipped." then
		local name = strsub(operand, 10)
		code = format("HasEquippedItem(%s)", name)
		AddSymbol(annotation, name)
	elseif operand == "gcd.max" then
		code = "GCD()"
	elseif operand == "gcd.remains" then
		code = "GCDRemaining()"
	elseif strsub(operand, 1, 15) == "legendary_ring." then
		local name = Disambiguate("legendary_ring", class, specialization)
		local buffName = name .. "_buff"
		local properties = strsub(operand, 16)
		local tokenIterator = gmatch(properties, OPERAND_TOKEN_PATTERN)
		local token = tokenIterator()
		if token == "cooldown" then
			token = tokenIterator()
			if token == "down" then
				code = format("ItemCooldown(%s) > 0", name)
				AddSymbol(annotation, name)
			elseif token == "remains" then
				code = format("ItemCooldown(%s)", name)
				AddSymbol(annotation, name)
			elseif token == "up" then
				code = format("not ItemCooldown(%s) > 0", name)
				AddSymbol(annotation, name)
			end
		elseif token == "has_cooldown" then
			code = format("ItemCooldown(%s) > 0", name)
			AddSymbol(annotation, name)
		elseif token == "up" then
			code = format("BuffPresent(%s)", buffName)
			AddSymbol(annotation, buffName)
		elseif token == "remains" then
			code = format("BuffRemaining(%s)", buffName)
			AddSymbol(annotation, buffName)
		end
	elseif operand == "ptr" then
		code = "PTR()"
	elseif operand == "time_to_die" then
		--[[
			"time_to_die" is both a character property and a time event in SimulationCraft.
			Silently translate all "time_to_die" to the equivalent of "target.time_to_die".
		--]]
		if target ~= "" then
			code = target .."TimeToDie()"
		else
			code = "target.TimeToDie()"
		end
	elseif strsub(operand, 1, 10) == "using_apl." then
		local aplName = strmatch(operand, "^using_apl%.([%w_]+)")
		code = format("List(opt_using_apl %s)", aplName)
		annotation.using_apl = annotation.using_apl or {}
		annotation.using_apl[aplName] = true
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
		local name = strlower(tokenIterator())
		local property = tokenIterator()
		-- Talent names need no disambiguation as they are the same across all specializations.
		--name = Disambiguate(name, annotation.class, annotation.specialization)
		local talentName = name .. "_talent"
		talentName = Disambiguate(talentName, annotation.class, annotation.specialization)

		local code
		if property == "disabled" then
			if parseNode.asType == "boolean" then
				code = format("not Talent(%s)", talentName)
			else
				code = format("Talent(%s no)", talentName)
			end
		elseif property == "enabled" then
			if parseNode.asType == "boolean" then
				code = format("Talent(%s)", talentName)
			else
				code = format("TalentPoints(%s)", talentName)
			end
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
		local name = strlower(tokenIterator())
		local property = tokenIterator()

		local code
		if property == "active" then
			code = format("TotemPresent(%s)", name)
		elseif property == "remains" then
			code = format("TotemRemaining(%s)", name)
		else
			ok = false
		end
		if ok and code then
			annotation.astAnnotation = annotation.astAnnotation or {}
			node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
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

		local code
		if strsub(procType, 1, 4) == "has_" then
			-- Assume these conditions are always true.
			-- TODO: Teach OvaleEquipment to check these conditions.
			code = format("True(trinket_%s_%s)", procType, statName)
		else
			local property = tokenIterator()
			local buffName = format("trinket_%s_%s_buff", procType, statName)
			buffName = Disambiguate(buffName, annotation.class, annotation.specialization)

			if property == "cooldown" then
				code = format("BuffCooldownDuration(%s)", buffName)
			elseif property == "cooldown_remains" then
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
			if ok then
				AddSymbol(annotation, buffName)
			end
		end
		if ok and code then
			annotation.astAnnotation = annotation.astAnnotation or {}
			node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
		end
	else
		ok = false
	end

	return ok, node
end

EmitOperandVariable = function(operand, parseNode, nodeList, annotation, action)
	-- local node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
	local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
	local token = tokenIterator()
	local node
	local ok
	if token == "variable" then
		local name = tokenIterator()

		if annotation.currentVariable and annotation.currentVariable.name == name then
			local group = annotation.currentVariable.child[1]
			if #group.child == 0 then
				node = OvaleAST:ParseCode("expression", "0", nodeList, annotation.astAnnotation)
			else
				-- TODO: create a sub-function
				node = OvaleAST:ParseCode("expression", OvaleAST:Unparse(group), nodeList, annotation.astAnnotation)
			end
		else
			node = OvaleAST:NewNode(nodeList)
			node.type = "function"
			node.name = name
		end
		ok = true
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

-- Mark all functions that are used in the AST tree below the given node using pre-order traversal.
local function PreOrderTraversalMark(node)
	if node.type == "custom_function" then
		self_functionUsed[node.name] = true
	else
		if node.type == "add_function" then
			self_functionDefined[node.name] = true
		end
		if node.child then
			for _, childNode in ipairs(node.child) do
				PreOrderTraversalMark(childNode)
			end
		end
	end
end

local function Mark(node)
	wipe(self_functionDefined)
	wipe(self_functionUsed)
	PreOrderTraversalMark(node)
end

-- Sweep (remove) the block of comments above the given line index in the childNodes array.
local function SweepComments(childNodes, index)
	local count = 0
	for k = index - 1, 1, -1 do
		if childNodes[k].type == "comment" then
			tremove(childNodes, k)
			count = count + 1
		else
			break
		end
	end
	return count
end

-- Sweep (remove) all usages of functions that are empty or unused.
local function Sweep(node)
	local isChanged, isSwept = false, false
	if node.type == "add_function" then
	-- TODODOO
		-- if self_functionUsed[node.name] then
		-- 	isChanged, isSwept = Sweep(node.child[1])
		-- else
		-- 	isChanged, isSwept = true, true
		-- end
	elseif node.type == "custom_function" and not self_functionDefined[node.name] then
		isChanged, isSwept = true, true
	elseif node.type == "group" or node.type == "script" then
		local child = node.child
		local index = #child
		while index > 0 do
			local childNode = child[index]
			local changed, swept = Sweep(childNode)
			if type(swept) == "table" then
				if swept.type == "group" then
					-- Directly insert a replacement group's statements in place of the replaced node.
					tremove(child, index)
					for k = #swept.child, 1, -1 do
						tinsert(child, index, swept.child[k])
					end
					if node.type == "group" then
						local count = SweepComments(child, index)
						index = index - count
					end
				else
					-- Use the replacement node.
					child[index] = swept
				end
			elseif swept then
				tremove(child, index)
				if node.type == "group" then
					local count = SweepComments(child, index)
					index = index - count
				end
			end
			isChanged = isChanged or changed or not not swept
			index = index - 1
		end
		-- Remove blank lines at the top of groups and scripts.
		if node.type == "group" or node.type == "script" then
			local childNode = child[1]
			while childNode and childNode.type == "comment" and (not childNode.comment or childNode.comment == "") do
				isChanged = true
				tremove(child, 1)
				childNode = child[1]
			end
		end
		isSwept = isSwept or (#child == 0)
		isChanged = isChanged or not not isSwept
	elseif node.type == "icon" then
		isChanged, isSwept = Sweep(node.child[1])
	elseif node.type == "if" then
		isChanged, isSwept = Sweep(node.child[2])
	elseif node.type == "logical" then
		if node.expressionType == "binary" then
			local lhsNode, rhsNode = node.child[1], node.child[2]
			for index, childNode in ipairs(node.child) do
				local changed, swept = Sweep(childNode)
				if type(swept) == "table" then
					node.child[index] = swept
				elseif swept then
					if node.operator == "or" then
						isSwept = (childNode == lhsNode) and rhsNode or lhsNode
					else
						isSwept = isSwept or swept
					end
					break
				end
				if changed then
					isChanged = isChanged or changed
					break
				end
			end
			isChanged = isChanged or not not isSwept
		end
	elseif node.type == "unless" then
		local changed, swept = Sweep(node.child[2])
		if type(swept) == "table" then
			node.child[2] = swept
			isSwept = false
		elseif swept then
			isSwept = swept
		else
			changed, swept = Sweep(node.child[1])
			if type(swept) == "table" then
				node.child[1] = swept
				isSwept = false
			elseif swept then
				isSwept = node.child[2]
			end
		end
		isChanged = isChanged or changed or not not isSwept
	elseif node.type == "wait" then
		isChanged, isSwept = Sweep(node.child[1])
	end
	return isChanged, isSwept
end

local function InsertInterruptFunction(child, annotation, name)
	local nodeList = annotation.astAnnotation.nodeList
	local camelSpecialization = CamelSpecialization(annotation)
	local fmt = [[
		AddFunction %sInterruptActions
		{
			if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
			{
				Spell(%s)
				if not target.Classification(worldboss)
				{
					Spell(arcane_torrent_focus)
					if target.InRange(quaking_palm) Spell(quaking_palm)
					Spell(war_stomp)
				}
			}
		}
	]]
	local code = format(fmt, camelSpecialization, name)
	local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
	tinsert(child, 1, node)
	annotation.functionTag[node.name] = "cd"
	AddSymbol(annotation, "arcane_torrent_focus")
	AddSymbol(annotation, name)
	AddSymbol(annotation, "quaking_palm")
	AddSymbol(annotation, "war_stomp")
end

local function InsertSupportingFunctions(child, annotation)
	local count = 0
	local nodeList = annotation.astAnnotation.nodeList
	local camelSpecialization = CamelSpecialization(annotation)

	if annotation.mind_freeze == "DEATHKNIGHT" then
		local fmt = [[
			AddFunction %sInterruptActions
			{
				if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
				{
					if target.InRange(mind_freeze) Spell(mind_freeze)
					if not target.Classification(worldboss)
					{
						if target.InRange(asphyxiate) Spell(asphyxiate)
						if target.InRange(strangulate) Spell(strangulate)
						Spell(arcane_torrent_runicpower)
						if target.InRange(quaking_palm) Spell(quaking_palm)
						Spell(war_stomp)
					}
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "arcane_torrent_runicpower")
		AddSymbol(annotation, "asphyxiate")
		AddSymbol(annotation, "mind_freeze")
		AddSymbol(annotation, "quaking_palm")
		AddSymbol(annotation, "strangulate")
		AddSymbol(annotation, "war_stomp")
		count = count + 1
	end
	if annotation.melee == "DEATHKNIGHT" then
		local fmt = [[
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(death_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "shortcd"
		AddSymbol(annotation, "death_strike")
		count = count + 1
	end
	if annotation.melee == "DEMONHUNTER" and annotation.specialization == "havoc" then
		local fmt = [[
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(chaos_strike) 
				{
					Spell(felblade)
					Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "shortcd"
		AddSymbol(annotation, "chaos_strike")
		count = count + 1
	end
	if annotation.melee == "DEMONHUNTER" and annotation.specialization == "vengeance" then
		local fmt = [[
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(shear) Texture(misc_arrowlup help=L(not_in_melee_range))
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "shortcd"
		AddSymbol(annotation, "shear")
		count = count + 1
	end
	if annotation.melee == "DEMONHUNTER" and annotation.specialization == "havoc" then
		local fmt = [[
			AddFunction %sInterruptActions
			{
				if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
				{
					if target.InRange(consume_magic) Spell(consume_magic)
					if not target.Classification(worldboss) 
					{
						if target.Distance(less 8) Spell(arcane_torrent_dh)
						if target.Distance(less 8) Spell(chaos_nova)
						Spell(fel_eruption)
						if target.CreatureType(Demon Humanoid Beast) Spell(imprison)
					}
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "shortcd"
		AddSymbol(annotation, "consume_magic")
		AddSymbol(annotation, "arcane_torrent_dh")
		AddSymbol(annotation, "fel_eruption")
		AddSymbol(annotation, "imprison")
		count = count + 1
	end
	if annotation.melee == "DEMONHUNTER" and annotation.specialization == "vengeance" then
		local fmt = [[
			AddFunction %sInterruptActions
			{
				if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
				{
					if target.InRange(consume_magic) Spell(consume_magic)
					if not target.Classification(worldboss) 
					{
						unless SigilCharging(silence misery chains)
						{
							if (target.RemainingCastTime() >= 2 or (target.RemainingCastTime() >= 1 and Talent(quickened_sigils_talent))) Spell(sigil_of_silence)
							if target.Distance(less 8) Spell(arcane_torrent_dh)
							Spell(sigil_of_misery)
							Spell(fel_eruption)
							if target.CreatureType(Demon) Spell(imprison)
							Spell(sigil_of_chains)
							if target.IsTargetingPlayer() Spell(empower_wards)
						}
					}
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "shortcd"
		AddSymbol(annotation, "consume_magic")
		AddSymbol(annotation, "sigil_of_silence")
		AddSymbol(annotation, "arcane_torrent_dh")
		AddSymbol(annotation, "sigil_of_misery")
		AddSymbol(annotation, "fel_eruption")
		AddSymbol(annotation, "imprison")
		AddSymbol(annotation, "sigil_of_chains")
		AddSymbol(annotation, "empower_wards")
		count = count + 1
	end
	if annotation.skull_bash == "DRUID" then
		local fmt = [[
			AddFunction %sInterruptActions
			{
				if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
				{
					if target.InRange(skull_bash) Spell(skull_bash)
					if not target.Classification(worldboss)
					{
						if target.InRange(mighty_bash) Spell(mighty_bash)
						Spell(typhoon)
						if target.InRange(maim) Spell(maim)
						Spell(war_stomp)
					}
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "maim")
		AddSymbol(annotation, "mighty_bash")
		AddSymbol(annotation, "skull_bash")
		AddSymbol(annotation, "typhoon")
		AddSymbol(annotation, "war_stomp")
		count = count + 1
	end
	if annotation.melee == "DRUID" then
		local fmt = [[
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred)
				{
					if target.InRange(wild_charge) Spell(wild_charge)
					Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "shortcd"
		AddSymbol(annotation, "mangle")
		AddSymbol(annotation, "shred")
		AddSymbol(annotation, "wild_charge")
		AddSymbol(annotation, "wild_charge_bear")
		AddSymbol(annotation, "wild_charge_cat")
		count = count + 1
	end
	if annotation.summon_pet == "HUNTER" then
		local fmt
		if annotation.specialization == "beast_mastery" then
			fmt = [[
				AddFunction %sSummonPet
				{
					if pet.IsDead()
					{
						if not DebuffPresent(heart_of_the_phoenix_debuff) Spell(heart_of_the_phoenix)
						Spell(revive_pet)
					}
					if not pet.Present() and not pet.IsDead() and not PreviousSpell(revive_pet) Texture(ability_hunter_beastcall help=L(summon_pet))
				}
			]]
		else
			fmt = [[
				AddFunction %sSummonPet
				{
					if not Talent(lone_wolf_talent)
					{
						if pet.IsDead()
						{
							if not DebuffPresent(heart_of_the_phoenix_debuff) Spell(heart_of_the_phoenix)
							Spell(revive_pet)
						}
						if not pet.Present() and not pet.IsDead() and not PreviousSpell(revive_pet) Texture(ability_hunter_beastcall help=L(summon_pet))
					}
				}
			]]
			AddSymbol(annotation, "lone_wolf_talent")
		end
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "shortcd"
		AddSymbol(annotation, "revive_pet")
		count = count + 1
	end
	if annotation.counter_shot == "HUNTER" then
		InsertInterruptFunction(child, annotation, "counter_shot")
		count = count + 1
	end
	if annotation.muzzle == "HUNTER" then
		InsertInterruptFunction(child, annotation, "muzzle")
		count = count + 1
	end
	if annotation.counterspell == "MAGE" then
		local fmt = [[
			AddFunction %sInterruptActions
			{
				if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
				{
					Spell(counterspell)
					if not target.Classification(worldboss)
					{
						Spell(arcane_torrent_mana)
						if target.InRange(quaking_palm) Spell(quaking_palm)
					}
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "arcane_torrent_mana")
		AddSymbol(annotation, "counterspell")
		AddSymbol(annotation, "quaking_palm")
		count = count + 1
	end
	if annotation.spear_hand_strike == "MONK" then
		local fmt = [[
			AddFunction %sInterruptActions
			{
				if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
				{
					if target.InRange(spear_hand_strike) Spell(spear_hand_strike)
					if not target.Classification(worldboss)
					{
						if target.InRange(paralysis) Spell(paralysis)
						Spell(arcane_torrent_chi)
						if target.InRange(quaking_palm) Spell(quaking_palm)
						Spell(war_stomp)
					}
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "arcane_torrent_chi")
		AddSymbol(annotation, "paralysis")
		AddSymbol(annotation, "quaking_palm")
		AddSymbol(annotation, "spear_hand_strike")
		AddSymbol(annotation, "war_stomp")
		count = count + 1
	end
	if annotation.melee == "MONK" then
		local fmt = [[
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "shortcd"
		AddSymbol(annotation, "tiger_palm")
		count = count + 1
	end
	if annotation.time_to_hpg_heal == "PALADIN" then
		local code = [[
			AddFunction HolyTimeToHPG
			{
				SpellCooldown(crusader_strike holy_shock judgment)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "crusader_strike")
		AddSymbol(annotation, "holy_shock")
		AddSymbol(annotation, "judgment")
		count = count + 1
	end
	if annotation.time_to_hpg_melee == "PALADIN" then
		local code = [[
			AddFunction RetributionTimeToHPG
			{
				SpellCooldown(crusader_strike exorcism hammer_of_wrath hammer_of_wrath_empowered judgment usable=1)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "crusader_strike")
		AddSymbol(annotation, "exorcism")
		AddSymbol(annotation, "hammer_of_wrath")
		AddSymbol(annotation, "judgment")
		count = count + 1
	end
	if annotation.time_to_hpg_tank == "PALADIN" then
		local code = [[
			AddFunction ProtectionTimeToHPG
			{
				if Talent(sanctified_wrath_talent) SpellCooldown(crusader_strike holy_wrath judgment)
				if not Talent(sanctified_wrath_talent) SpellCooldown(crusader_strike judgment)
			}
		]]
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "crusader_strike")
		AddSymbol(annotation, "holy_wrath")
		AddSymbol(annotation, "judgment")
		AddSymbol(annotation, "sanctified_wrath_talent")
		count = count + 1
	end
	if annotation.rebuke == "PALADIN" then
		local fmt = [[
			AddFunction %sInterruptActions
			{
				if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
				{
					if target.InRange(rebuke) Spell(rebuke)
					if target.InRange(avengers_shield) Spell(avengers_shield)
					if not target.Classification(worldboss)
					{
						if target.InRange(hammer_of_justice) Spell(hammer_of_justice)
						if target.Distance(less 10) Spell(blinding_light)
						if target.Distance(less 8) Spell(arcane_torrent_holy)
						if target.Distance(less 8) Spell(war_stomp)
						if target.InRange(quaking_palm) Spell(quaking_palm)
					}
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "arcane_torrent_holy")
		AddSymbol(annotation, "blinding_light")
		AddSymbol(annotation, "hammer_of_justice")
		AddSymbol(annotation, "quaking_palm")
		AddSymbol(annotation, "rebuke")
		AddSymbol(annotation, "war_stomp")
		count = count + 1
	end
	if annotation.melee == "PALADIN" then
		local fmt = [[
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "shortcd"
		AddSymbol(annotation, "rebuke")
		count = count + 1
	end
	if annotation.silence == "PRIEST" then
		local fmt = [[
			AddFunction %sInterruptActions
			{
				if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
				{
					Spell(silence)
					if not target.Classification(worldboss)
					{
						Spell(arcane_torrent_mana)
						if target.InRange(quaking_palm) Spell(quaking_palm)
						Spell(war_stomp)
					}
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "arcane_torrent_mana")
		AddSymbol(annotation, "quaking_palm")
		AddSymbol(annotation, "silence")
		AddSymbol(annotation, "war_stomp")
		count = count + 1
	end
	if annotation.kick == "ROGUE" then
		local fmt = [[
			AddFunction %sInterruptActions
			{
				if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
				{
					if target.InRange(kick) Spell(kick)
					if not target.Classification(worldboss)
					{
						if target.InRange(cheap_shot) Spell(cheap_shot)
						if target.InRange(deadly_throw) and ComboPoints() == 5 Spell(deadly_throw)
						if target.InRange(between_the_eyes) Spell(between_the_eyes)
						if target.InRange(kidney_shot) Spell(kidney_shot)
						Spell(arcane_torrent_energy)
						if target.InRange(gouge) Spell(gouge)
						if target.InRange(quaking_palm) Spell(quaking_palm)
					}
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "arcane_torrent_energy")
		AddSymbol(annotation, "between_the_eyes")
		AddSymbol(annotation, "cheap_shot")
		AddSymbol(annotation, "deadly_throw")
		AddSymbol(annotation, "kick")
		AddSymbol(annotation, "kidney_shot")
		AddSymbol(annotation, "quaking_palm")
		count = count + 1
	end
	if annotation.melee == "ROGUE" then
		local fmt = [[
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(kick)
				{
					Spell(shadowstep)
					Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "shortcd"
		AddSymbol(annotation, "kick")
		AddSymbol(annotation, "shadowstep")
		count = count + 1
	end
	if annotation.wind_shear == "SHAMAN" then
		local fmt = [[
			AddFunction %sInterruptActions
			{
				if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
				{
					Spell(wind_shear)
					if not target.Classification(worldboss)
					{
						Spell(arcane_torrent_mana)
						if target.InRange(quaking_palm) Spell(quaking_palm)
						Spell(war_stomp)
					}
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "arcane_torrent_mana")
		AddSymbol(annotation, "quaking_palm")
		AddSymbol(annotation, "wind_shear")
		AddSymbol(annotation, "war_stomp")
		count = count + 1
	end
	if annotation.melee == "SHAMAN" then
		local fmt = [[
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(stormstrike) 
				{
					if target.Distance() >= 8 and target.Distance() <= 25 Spell(feral_lunge)
					Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "shortcd"
		AddSymbol(annotation, "stormstrike")
		count = count + 1
	end
	if annotation.bloodlust == "SHAMAN" then
		local fmt = [[
			AddFunction %sBloodlust
			{
				if CheckBoxOn(opt_bloodlust) and DebuffExpires(burst_haste_debuff any=1)
				{
					Spell(bloodlust)
					Spell(heroism)
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "bloodlust")
		AddSymbol(annotation, "heroism")
		count = count + 1
	end
	if annotation.pummel == "WARRIOR" then
		local fmt = [[
			AddFunction %sInterruptActions
			{
				if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
				{
					if target.InRange(pummel) Spell(pummel)
					if not target.Classification(worldboss)
					{
						Spell(arcane_torrent_rage)
						if target.InRange(quaking_palm) Spell(quaking_palm)
						Spell(war_stomp)
					}
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "arcane_torrent_rage")
		AddSymbol(annotation, "heroic_throw")
		AddSymbol(annotation, "pummel")
		AddSymbol(annotation, "quaking_palm")
		AddSymbol(annotation, "war_stomp")
		count = count + 1
	end
	if annotation.melee == "WARRIOR" then
		local fmt = [[
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range)
				{
					if target.InRange(charge) Spell(charge)
					if target.InRange(charge) Spell(heroic_leap)
					if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "shortcd"
		AddSymbol(annotation, "charge")
		AddSymbol(annotation, "heroic_leap")
		AddSymbol(annotation, "pummel")
		count = count + 1
	end
	if annotation.use_item then
		local fmt = [[
			AddFunction %sUseItemActions
			{
				Item(Trinket0Slot usable=1)
				Item(Trinket1Slot usable=1)
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		count = count + 1
	end
	if annotation.use_potion_strength then
		local fmt = [[
			AddFunction %sUsePotionStrength
			{
				if CheckBoxOn(opt_potion_strength) and target.Classification(worldboss) Item(draenic_strength_potion usable=1)
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "draenic_strength_potion")
		count = count + 1
	end
	if annotation.use_potion_mana then
		local fmt = [[
			AddFunction %sUsePotionMana
			{
				if CheckBoxOn(opt_potion_mana) Item(draenic_mana_potion usable=1)
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "draenic_mana_potion")
		count = count + 1
	end
	if annotation.use_potion_intellect then
		local fmt = [[
			AddFunction %sUsePotionIntellect
			{
				if CheckBoxOn(opt_potion_intellect) and target.Classification(worldboss) Item(draenic_intellect_potion usable=1)
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "draenic_intellect_potion")
		count = count + 1
	end
	if annotation.use_potion_armor then
		local fmt = [[
			AddFunction %sUsePotionArmor
			{
				if CheckBoxOn(opt_potion_armor) and target.Classification(worldboss) Item(draenic_armor_potion usable=1)
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "draenic_armor_potion")
		count = count + 1
	end
	if annotation.use_potion_agility then
		local fmt = [[
			AddFunction %sUsePotionAgility
			{
				if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
			}
		]]
		local code = format(fmt, camelSpecialization)
		local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		annotation.functionTag[node.name] = "cd"
		AddSymbol(annotation, "draenic_agility_potion")
		count = count + 1
	end
	return count
end

local function InsertSupportingControls(child, annotation)
	local count = 0
	local nodeList = annotation.astAnnotation.nodeList

	local ifSpecialization = "specialization=" .. annotation.specialization
	
	if annotation.using_apl and next(annotation.using_apl) then
		-- Add non-default list items.
		for name in pairs(annotation.using_apl) do
			if name ~= "normal" then
				local fmt = [[
					AddListItem(opt_using_apl %s "%s APL")
				]]
				local code = format(fmt, name, name)
				local node = OvaleAST:ParseCode("list_item", code, nodeList, annotation.astAnnotation)
				tinsert(child, 1, node)
			end
		end
		-- Add default list item.
		do
			local code = [[
				AddListItem(opt_using_apl normal L(normal_apl) default)
			]]
			local node = OvaleAST:ParseCode("list_item", code, nodeList, annotation.astAnnotation)
			tinsert(child, 1, node)
		end
	end
	if annotation.pooling_for_meta == "DEMONHUNTER" then
		local fmt = [[
			AddCheckBox(opt_meta_only_during_boss L(meta_only_during_boss) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "metamorphosis_havoc")
		count = count + 1
	end
	if annotation.volley == "HUNTER" then
		local fmt = [[
			AddCheckBox(opt_volley SpellName(volley) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "volley")
		count = count + 1
	end
	if annotation.trap_launcher == "HUNTER" then
		local fmt = [[
			AddCheckBox(opt_trap_launcher SpellName(trap_launcher) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "trap_launcher")
		count = count + 1
	end
	if annotation.time_warp == "MAGE" then
		local fmt = [[
			AddCheckBox(opt_time_warp SpellName(time_warp) %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "time_warp")
		count = count + 1
	end
	if annotation.opt_arcane_mage_burn_phase == "MAGE" then
		local fmt = [[
			AddCheckBox(opt_arcane_mage_burn_phase L(arcane_mage_burn_phase) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		count = count + 1
	end
	if annotation.storm_earth_and_fire == "MONK" then
		local fmt = [[
			AddCheckBox(opt_storm_earth_and_fire SpellName(storm_earth_and_fire) %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "storm_earth_and_fire")
		count = count + 1
	end
	if annotation.chi_burst == "MONK" then
		local fmt = [[
			AddCheckBox(opt_chi_burst SpellName(chi_burst) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "chi_burst")
		count = count + 1
	end
	if annotation.vanish == "ROGUE" then
		local fmt = [[
			AddCheckBox(opt_vanish SpellName(vanish) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "vanish")
		count = count + 1
	end
	if annotation.blade_flurry == "ROGUE" then
		local fmt = [[
			AddCheckBox(opt_blade_flurry SpellName(blade_flurry) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "blade_flurry")
		count = count + 1
	end
	if annotation.bloodlust == "SHAMAN" then
		local fmt = [[
			AddCheckBox(opt_bloodlust SpellName(bloodlust) %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "bloodlust")
		count = count + 1
	end
	if annotation.righteous_fury == "PALADIN" then
		local fmt = [[
			AddCheckBox(opt_righteous_fury_check SpellName(righteous_fury) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "righteous_fury")
		count = count + 1
	end
	if annotation.use_legendary_ring then
		local legendaryRing = annotation.use_legendary_ring
		local fmt = [[
			AddCheckBox(opt_%s ItemName(%s) default %s)
		]]
		local code = format(fmt, legendaryRing, legendaryRing, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, legendaryRing)
		count = count + 1
	end
	if annotation.use_potion_strength then
		local fmt = [[
			AddCheckBox(opt_potion_strength ItemName(draenic_strength_potion) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "draenic_strength_potion")
		count = count + 1
	end
	if annotation.use_potion_mana then
		local fmt = [[
			AddCheckBox(opt_potion_mana ItemName(draenic_mana_potion) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "draenic_mana_potion")
		count = count + 1
	end
	if annotation.use_potion_intellect then
		local fmt = [[
			AddCheckBox(opt_potion_intellect ItemName(draenic_intellect_potion) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "draenic_intellect_potion")
		count = count + 1
	end
	if annotation.use_potion_armor then
		local fmt = [[
			AddCheckBox(opt_potion_armor ItemName(draenic_armor_potion) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "draenic_armor_potion")
		count = count + 1
	end
	if annotation.use_potion_agility then
		local fmt = [[
			AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		AddSymbol(annotation, "draenic_agility_potion")
		count = count + 1
	end
	if annotation.melee then
		local fmt = [[
			AddCheckBox(opt_melee_range L(not_in_melee_range) %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		count = count + 1
	end
	if annotation.interrupt then
		local fmt = [[
			AddCheckBox(opt_interrupt L(interrupt) default %s)
		]]
		local code = format(fmt, ifSpecialization)
		local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
		tinsert(child, 1, node)
		count = count + 1
	end
	return count
end

local function InsertSupportingDefines(child, annotation)
	local count = 0
	local nodeList = annotation.astAnnotation.nodeList
	if annotation.honor_among_thieves == "ROGUE" then
		local buffName = "honor_among_thieves_cooldown_buff"
		do
			local code = format("SpellInfo(%s duration=%f)", buffName, annotation[buffName])
			local node = OvaleAST:ParseCode("spell_info", code, nodeList, annotation.astAnnotation)
			tinsert(child, 1, node)
			count = count + 1
		end
		do
			local code = format("Define(%s %d)", buffName, OvaleHonorAmongThieves.spellId)
			local node = OvaleAST:ParseCode("define", code, nodeList, annotation.astAnnotation)
			tinsert(child, 1, node)
			count = count + 1
		end
		AddSymbol(annotation, buffName)
	end
	return count
end

local function InsertVariables(child, annotation)
	if annotation.variable then
		for k,v in pairs(annotation.variable) do
			tinsert(child, 1, v)
		end
	end
end

local function GenerateIconBody(tag, profile)
	local annotation = profile.annotation
	local precombatName = OvaleFunctionName("precombat", annotation)
	local defaultName = OvaleFunctionName("_default", annotation)
	local precombatBodyName, precombatConditionName = OvaleTaggedFunctionName(precombatName, tag)
	local defaultBodyName, defaultConditionName = OvaleTaggedFunctionName(defaultName, tag)

	local mainBodyCode
	if annotation.using_apl and next(annotation.using_apl) then
		local output = self_outputPool:Get()
		output[#output + 1] = format("if List(opt_using_apl normal) %s()", defaultBodyName)
		for name in pairs(annotation.using_apl) do
			local aplName = OvaleFunctionName(name, annotation)
			local aplBodyName, aplConditionName = OvaleTaggedFunctionName(aplName, tag)
			output[#output + 1] = format("if List(opt_using_apl %s) %s()", name, aplBodyName)
		end
		mainBodyCode = tconcat(output, "\n")
		self_outputPool:Release(output)
	else
		mainBodyCode = defaultBodyName .. "()"
	end

	local code
	if profile["actions.precombat"] then
		local fmt = [[
			if not InCombat() %s()
			unless not InCombat() and %s()
			{
				%s
			}
		]]
		code = format(fmt, precombatBodyName, precombatConditionName, mainBodyCode)
	else
		code = mainBodyCode
	end
	return code
end
--</private-static-methods>

--<public-static-methods>
function OvaleSimulationCraft:OnInitialize()
	-- Resolve module dependencies.
	OvaleAST = Ovale.OvaleAST
	OvaleCompile = Ovale.OvaleCompile
	OvaleData = Ovale.OvaleData
	OvaleHonorAmongThieves = Ovale.OvaleHonorAmongThieves
	OvaleLexer = Ovale.OvaleLexer
	OvalePower = Ovale.OvalePower
	OvaleScripts = Ovale.OvaleScripts

	InitializeDisambiguation()
	self:CreateOptions()
end

function OvaleSimulationCraft:DebuggingInfo()
	self_pool:DebuggingInfo()
	self_childrenPool:DebuggingInfo()
	self_outputPool:DebuggingInfo()
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
	-- Create list of text templates: $(variable)=content
	profile.templates = {}
	for k, v in pairs(profile) do
		if strsub(k, 1, 2) == "$(" and strsub(k, -1) == ")" then
			tinsert(profile.templates, k)
		end
	end
	-- Parse the action lists.
	local ok = true
	local annotation = {}
	local nodeList = {}
	local actionList = {}
	for k, v in pairs(profile) do
		if ok and strmatch(k, "^actions") then
			-- Name the default action list "_default" so it's first alphabetically.
			local name = strmatch(k, "^actions%.([%w_]+)") or "_default"
			-- Substitute for any text templates found in the action list.
			-- Assumes that a text template will only use previously defined text templates.
			for index = #profile.templates, 1, -1 do
				local template = profile.templates[index]
				local variable = strsub(template, 3, -2)
				local pattern = "%$%(" .. variable .. "%)"
				v = gsub(v, pattern, profile[template])
			end
			local node
			ok, node = ParseActionList(name, v, nodeList, annotation)
			if ok then
				actionList[#actionList + 1] = node
			else
				break
			end
		end
	end
	-- Sort the action lists alphabetically.
	tsort(actionList, function(a, b) return a.name < b.name end)
	-- Set the name, class, specialization, and role from the profile.
	for class in pairs(RAID_CLASS_COLORS) do
		local lowerClass = strlower(class)
		if profile[lowerClass] then
			annotation.class = class
			annotation.name = profile[lowerClass]
		end
	end
	annotation.specialization = profile.spec
	annotation.level = profile.level
	ok = ok and (annotation.class and annotation.specialization and annotation.level)
	annotation.pet = profile.default_pet

	-- Set the attack range of the class and role.
	if profile.role == "tank" then
		annotation.role = profile.role
		annotation.melee = annotation.class
	elseif profile.role == "spell" then
		annotation.role = profile.role
		annotation.ranged = annotation.class
	elseif profile.role == "attack" or profile.role == "dps" then
		annotation.role = "attack"
		if profile.position == "ranged_back" then
			annotation.ranged = annotation.class
		else
			annotation.melee = annotation.class
		end
	end

	-- Create table of tagged Ovale function names.
	local taggedFunctionName = {}
	for _, node in ipairs(actionList) do
		local fname = OvaleFunctionName(node.name, annotation)
		taggedFunctionName[fname] = true
		for _, tag in pairs(OVALE_TAGS) do
			local bodyName, conditionName = OvaleTaggedFunctionName(fname, tag)
			taggedFunctionName[bodyName] = true
			taggedFunctionName[conditionName] = true
		end
	end
	annotation.taggedFunctionName = taggedFunctionName
	annotation.functionTag = {}

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

function OvaleSimulationCraft:EmitAST(profile)
	local nodeList = {}
	local ast = OvaleAST:NewNode(nodeList, true)
	local child = ast.child
	ast.type = "script"

	local annotation = profile.annotation
	local ok = true
	if profile.actionList then
		annotation.astAnnotation = annotation.astAnnotation or {}
		annotation.astAnnotation.nodeList = nodeList
		-- Load the dictionary of defined symbols from evaluating the script headers.
		local dictionaryAST
		do
			OvaleDebug:ResetTrace()
			local dictionaryAnnotation = { nodeList = {} }
			local dictionaryFormat = [[
				Include(ovale_common)
				Include(ovale_trinkets_mop)
				Include(ovale_trinkets_wod)
				Include(ovale_%s_spells)
				%s
			]]
			local dictionaryCode = format(dictionaryFormat, strlower(annotation.class), Ovale.db.profile.overrideCode)
			dictionaryAST = OvaleAST:ParseCode("script", dictionaryCode, dictionaryAnnotation.nodeList, dictionaryAnnotation)
			if dictionaryAST then
				dictionaryAST.annotation = dictionaryAnnotation
				annotation.dictionaryAST = dictionaryAST
				annotation.dictionary = dictionaryAnnotation.definition
				OvaleAST:PropagateConstants(dictionaryAST)
				OvaleAST:PropagateStrings(dictionaryAST)
				OvaleAST:FlattenParameters(dictionaryAST)
				Ovale:ResetControls()
				OvaleCompile:EvaluateScript(dictionaryAST, true)
			end
		end
		-- Generate the AST "add_function" nodes from the action lists.
		for _, node in ipairs(profile.actionList) do
			local addFunctionNode = EmitActionList(node, nodeList, annotation)
			if addFunctionNode then
				local actionListName = gsub(node.name, "^_+", "")
				local commentNode = OvaleAST:NewNode(nodeList)
				commentNode.type = "comment"
				commentNode.comment = "## actions." .. actionListName
				child[#child + 1] = commentNode
				--child[#child + 1] = addFunctionNode
				-- Split this action list function by each tag.
				for _, tag in pairs(OVALE_TAGS) do
					local bodyNode, conditionNode = SplitByTag(tag, addFunctionNode, nodeList, annotation)
					child[#child + 1] = bodyNode
					child[#child + 1] = conditionNode
				end
			else
				ok = false
				break
			end
		end
	end
	if ok then
		-- Insert header nodes.
		annotation.supportingFunctionCount = InsertSupportingFunctions(child, annotation)
		annotation.supportingControlCount = InsertSupportingControls(child, annotation)
		annotation.supportingDefineCount = InsertSupportingDefines(child, annotation)
		InsertVariables(child, annotation)

		-- Output a standard four-icon layout for the rotation: [shortcd] [main] [aoe] [cd]
		local class, specialization = annotation.class, annotation.specialization
		local lowerclass = strlower(class)
		local aoeToggle = "opt_" .. lowerclass .. "_" .. specialization .. "_aoe"

		-- Icon headers.
		do
			local commentNode = OvaleAST:NewNode(nodeList)
			commentNode.type = "comment"
			commentNode.comment = "## " .. CamelCase(specialization) .. " icons."
			tinsert(child, commentNode)
			local code = format("AddCheckBox(%s L(AOE) default specialization=%s)", aoeToggle, specialization)
			local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
			tinsert(child, node)
		end
		-- Short CD rotation.
		do
			local fmt = [[
				AddIcon checkbox=!%s enemies=1 help=shortcd specialization=%s
				{
					%s
				}
			]]
			local code = format(fmt, aoeToggle, specialization, GenerateIconBody("shortcd", profile))
			local node = OvaleAST:ParseCode("icon", code, nodeList, annotation.astAnnotation)
			tinsert(child, node)
		end
		do
			local fmt = [[
				AddIcon checkbox=%s help=shortcd specialization=%s
				{
					%s
				}
			]]
			local code = format(fmt, aoeToggle, specialization, GenerateIconBody("shortcd", profile))
			local node = OvaleAST:ParseCode("icon", code, nodeList, annotation.astAnnotation)
			tinsert(child, node)
		end
		-- Single-target rotation.
		do
			local fmt = [[
				AddIcon enemies=1 help=main specialization=%s
				{
					%s
				}
			]]
			local code = format(fmt, specialization, GenerateIconBody("main", profile))
			local node = OvaleAST:ParseCode("icon", code, nodeList, annotation.astAnnotation)
			tinsert(child, node)
		end
		-- AoE rotation.
		do
			local fmt = [[
				AddIcon checkbox=%s help=aoe specialization=%s
				{
					%s
				}
			]]
			local code = format(fmt, aoeToggle, specialization, GenerateIconBody("main", profile))
			local node = OvaleAST:ParseCode("icon", code, nodeList, annotation.astAnnotation)
			tinsert(child, node)
		end
		-- CD rotation.
		do
			local fmt = [[
				AddIcon checkbox=!%s enemies=1 help=cd specialization=%s
				{
					%s
				}
			]]
			local code = format(fmt, aoeToggle, specialization, GenerateIconBody("cd", profile))
			local node = OvaleAST:ParseCode("icon", code, nodeList, annotation.astAnnotation)
			tinsert(child, node)
		end
		do
			local fmt = [[
				AddIcon checkbox=%s help=cd specialization=%s
				{
					%s
				}
			]]
			local code = format(fmt, aoeToggle, specialization, GenerateIconBody("cd", profile))
			local node = OvaleAST:ParseCode("icon", code, nodeList, annotation.astAnnotation)
			tinsert(child, node)
		end

		-- Walk the AST and remove empty and unused functions.
		Mark(ast)
		local changed = Sweep(ast)
		while changed do
			Mark(ast)
			changed = Sweep(ast)
		end
		-- XXX Shouldn't need the extra Mark/Sweep here.
		Mark(ast)
		Sweep(ast)
	end
	if not ok then
		OvaleAST:Release(ast)
		ast = nil
	end
	return ast
end

function OvaleSimulationCraft:Emit(profile, noFinalNewLine)
	local nodeList = {}
	local ast = self:EmitAST(profile)
	local annotation = profile.annotation
	local class = annotation.class
	local lowerclass = strlower(class)
	local specialization = annotation.specialization

	local output = self_outputPool:Get()
	-- Prepend a comment block header for the script.
	do
		output[#output + 1] = "# Based on SimulationCraft profile " .. annotation.name .. "."
		output[#output + 1] = "#	class=" .. lowerclass
		output[#output + 1] = "#	spec=" .. specialization
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
		output[#output + 1] = "Include(ovale_trinkets_mop)"
		output[#output + 1] = "Include(ovale_trinkets_wod)"
		output[#output + 1] = format("Include(ovale_%s_spells)", lowerclass)
		-- Insert local class override code if it exists.
		local overrideCode = Ovale.db.profile.overrideCode
		if overrideCode ~= "" then
			output[#output + 1] = ""
			output[#output + 1] = "# Overrides."
			output[#output + 1] = overrideCode
		end
		-- Insert an extra blank line to separate section for controls from the includes.
		if annotation.supportingDefineCount + annotation.supportingControlCount > 0 then
			output[#output + 1] = ""
		end
	end
	-- Output the script itself.
	output[#output + 1] = OvaleAST:Unparse(ast)
	-- Append the required symbols for the script.
	if profile.annotation.symbolTable then
		output[#output + 1] = ""
		output[#output + 1] = "### Required symbols"
		tsort(profile.annotation.symbolTable)
		for _, symbol in ipairs(profile.annotation.symbolTable) do
			if not tonumber(symbol) and profile.annotation.dictionary and not profile.annotation.dictionary[symbol] and not OvaleData.buffSpellList[symbol] then
				-- TODO Need to be redesigned
				self:Print("Warning: Symbol '%s' not defined", symbol)				
			end
			output[#output + 1] = "# " .. symbol
		end
	end

	-- Clean-up
	annotation.dictionary = nil
	if annotation.dictionaryAST then
		OvaleAST:Release(annotation.dictionaryAST)
	end


	-- Ensure that the script always ends in a blank line.
	if not noFinalNewLine and output[#output] ~= "" then
		output[#output + 1] = ""
	end
	local s = tconcat(output, "\n")
	self_outputPool:Release(output)
	OvaleAST:Release(ast)
	return s
end

function OvaleSimulationCraft:CreateOptions()
	local options = {
		name = OVALE .. " SimulationCraft",
		type = "group",
		args = {
			input = {
				order = 10,
				name = L["Input"],
				type = "group",
				args = {
					description = {
						order = 10,
						name = L["The contents of a SimulationCraft profile."] .. "\nhttps://code.google.com/p/simulationcraft/source/browse/profiles",
						type = "description",
					},
					input = {
						order = 20,
						name = L["SimulationCraft Profile"],
						type = "input",
						multiline = 25,
						width = "full",
						get = function(info) return self_lastSimC end,
						set = function(info, value)
							self_lastSimC = value
							local profile = self:ParseProfile(self_lastSimC)
							local code = ""
							if profile then
								code = self:Emit(profile)
							end
							-- Substitute spaces for tabs.
							self_lastScript = gsub(code, "\t", "    ")
						end,
					},
				},
			},
			overrides = {
				order = 20,
				name = L["Overrides"],
				type = "group",
				args = {
					description = {
						order = 10,
						name = L["SIMULATIONCRAFT_OVERRIDES_DESCRIPTION"],
						type = "description",
					},
					overrides = {
						order = 20,
						name = L["Overrides"],
						type = "input",
						multiline = 25,
						width = "full",
						get = function(info)
							local code = Ovale.db.profile.overrideCode
							-- Substitute spaces for tabs.
							return gsub(code, "\t", "    ")
						end,
						set = function(info, value)
							Ovale.db.profile.overrideCode = value
							if self_lastSimC then
								local profile = self:ParseProfile(self_lastSimC)
								local code = ""
								if profile then
									code = self:Emit(profile)
								end
								-- Substitute spaces for tabs.
								self_lastScript = gsub(code, "\t", "    ")
							end
						end,
					},
				},
			},
			output = {
				order = 30,
				name = L["Output"],
				type = "group",
				args = {
					description = {
						order = 10,
						name = L["The script translated from the SimulationCraft profile."],
						type = "description",
					},
					output = {
						order = 20,
						name = L["Script"],
						type = "input",
						multiline = 25,
						width = "full",
						get = function() return self_lastScript end,
					},
				},
			},
		},
	}

	local appName = self:GetName()
	AceConfig:RegisterOptionsTable(appName, options)
	AceConfigDialog:AddToBlizOptions(appName, "SimulationCraft", OVALE)
end
--</public-static-methods>
