local __exports = LibStub:NewLibrary("ovale/simulationcraft/parser", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Lexer = LibStub:GetLibrary("ovale/Lexer")
local OvaleLexer = __Lexer.OvaleLexer
local tostring = tostring
local tonumber = tonumber
local ipairs = ipairs
local __definitions = LibStub:GetLibrary("ovale/simulationcraft/definitions")
local KEYWORD = __definitions.KEYWORD
local SPECIAL_ACTION = __definitions.SPECIAL_ACTION
local UNARY_OPERATOR = __definitions.UNARY_OPERATOR
local BINARY_OPERATOR = __definitions.BINARY_OPERATOR
local FUNCTION_KEYWORD = __definitions.FUNCTION_KEYWORD
local MODIFIER_KEYWORD = __definitions.MODIFIER_KEYWORD
local LITTERAL_MODIFIER = __definitions.LITTERAL_MODIFIER
local RUNE_OPERAND = __definitions.RUNE_OPERAND
local gsub = string.gsub
local gmatch = string.gmatch
local sub = string.sub
local concat = table.concat
local __Pool = LibStub:GetLibrary("ovale/Pool")
local OvalePool = __Pool.OvalePool
local __tools = LibStub:GetLibrary("ovale/tools")
local checkToken = __tools.checkToken
local self_childrenPool = OvalePool("OvaleSimulationCraft_childrenPool")
local SelfPool = __class(OvalePool, {
    constructor = function(self)
        OvalePool.constructor(self, "OvaleSimulationCraft_pool")
    end,
    Clean = function(self, node)
        if node.child then
            self_childrenPool:Release(node.child)
            node.child = nil
        end
    end,
})
local self_pool = SelfPool()
local NewNode = function(nodeList, hasChild)
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

local TicksRemainTranslationHelper = function(p1, p2, p3, p4)
    if p4 then
        return p1 .. p2 .. " < " .. tostring(tonumber(p4) + 1)
    else
        return p1 .. "<" .. tostring(tonumber(p3) + 1)
    end
end

local TokenizeName = function(token)
    if KEYWORD[token] then
        return "keyword", token
    else
        return "name", token
    end
end

local TokenizeNumber = function(token)
    return "number", token
end

local Tokenize = function(token)
    return token, token
end

local NoToken = function()
    return nil, nil
end

local MATCHES = {
    [1] = {
        [1] = "^%d+%a[%w_]*[.:]?[%w_.:]*",
        [2] = TokenizeName
    },
    [2] = {
        [1] = "^%d+%.?%d*",
        [2] = TokenizeNumber
    },
    [3] = {
        [1] = "^[%a_][%w_]*[.:]?[%w_.:]*",
        [2] = TokenizeName
    },
    [4] = {
        [1] = "^!=",
        [2] = Tokenize
    },
    [5] = {
        [1] = "^<=",
        [2] = Tokenize
    },
    [6] = {
        [1] = "^>=",
        [2] = Tokenize
    },
    [7] = {
        [1] = "^!~",
        [2] = Tokenize
    },
    [8] = {
        [1] = "^==",
        [2] = Tokenize
    },
    [9] = {
        [1] = "^>%?",
        [2] = Tokenize
    },
    [10] = {
        [1] = "^.",
        [2] = Tokenize
    },
    [11] = {
        [1] = "^$",
        [2] = NoToken
    }
}
__exports.Parser = __class(nil, {
    constructor = function(self, ovaleDebug)
        self.tracer = ovaleDebug:create("SimulationCraftParser")
    end,
    release = function(self, nodeList)
        for _, node in ipairs(nodeList) do
            self_pool:Release(node)
        end
    end,
    SyntaxError = function(self, tokenStream, ...)
        self.tracer:Warning(...)
        local context = {
            [1] = "Next tokens:"
        }
        for i = 1, 20, 1 do
            local tokenType, token = tokenStream:Peek(i)
            if tokenType then
                context[#context + 1] = token
            else
                context[#context + 1] = "<EOS>"
                break
            end
        end
        self.tracer:Warning(concat(context, " "))
    end,
    ParseAction = function(self, action, nodeList, annotation)
        local ok = true
        local stream = action
        do
            stream = gsub(stream, "||", "|")
        end
        do
            stream = gsub(stream, ",,", ",")
            stream = gsub(stream, "%&%&", "&")
            stream = gsub(stream, "target%.target%.", "target.")
        end
        do
            stream = gsub(stream, "(active_dot%.[%w_]+)=0", "!(%1>0)")
            stream = gsub(stream, "([^_%.])(cooldown_remains)=0", "%1!(%2>0)")
            stream = gsub(stream, "([a-z_%.]+%.cooldown_remains)=0", "!(%1>0)")
            stream = gsub(stream, "([^_%.])(remains)=0", "%1!(%2>0)")
            stream = gsub(stream, "([a-z_%.]+%.remains)=0", "!(%1>0)")
            stream = gsub(stream, "([^_%.])(ticks_remain)(<?=)([0-9]+)", TicksRemainTranslationHelper)
            stream = gsub(stream, "([a-z_%.]+%.ticks_remain)(<?=)([0-9]+)", TicksRemainTranslationHelper)
        end
        do
            stream = gsub(stream, "%@([a-z_%.]+)<(=?)([0-9]+)", "(%1<%2%3&%1>%2-%3)")
            stream = gsub(stream, "%@([a-z_%.]+)>(=?)([0-9]+)", "(%1>%2%3|%1<%2-%3)")
        end
        do
            stream = gsub(stream, "!([a-z_%.]+)%.cooldown%.up", "%1.cooldown.down")
        end
        do
            stream = gsub(stream, "!talent%.([a-z_%.]+)%.enabled", "talent.%1.disabled")
        end
        do
            stream = gsub(stream, ",target_if=first:", ",target_if_first=")
            stream = gsub(stream, ",target_if=max:", ",target_if_max=")
            stream = gsub(stream, ",target_if=min:", ",target_if_min=")
        end
        do
            stream = gsub(stream, "sim.target", "sim_target")
        end
        local tokenStream = OvaleLexer("SimulationCraft", stream, MATCHES)
        local name
        do
            local tokenType, token = tokenStream:Consume()
            if (tokenType == "keyword" and SPECIAL_ACTION[token]) or tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line '%s'; name or special action expected.", token, action)
                ok = false
            end
        end
        local child = self_childrenPool:Get()
        local modifiers = self_childrenPool:Get()
        if ok then
            local tokenType, token = tokenStream:Peek()
            while ok and tokenType do
                if tokenType == "," then
                    tokenStream:Consume()
                    local modifier, expressionNode
                    ok, modifier, expressionNode = self:ParseModifier(tokenStream, nodeList, annotation)
                    if ok then
                        modifiers[modifier] = expressionNode
                        tokenType, token = tokenStream:Peek()
                    end
                else
                    self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line '%s'; ',' expected.", token, action)
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
            node.modifiers = modifiers
            annotation.sync = annotation.sync or {}
            annotation.sync[name] = annotation.sync[name] or node
        else
            self_childrenPool:Release(child)
        end
        return ok, node
    end,
    ParseActionList = function(self, name, actionList, nodeList, annotation)
        local ok = true
        local child = self_childrenPool:Get()
        for action in gmatch(actionList, "[^/]+") do
            local actionNode
            ok, actionNode = self:ParseAction(action, nodeList, annotation)
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
    end,
    ParseExpression = function(self, tokenStream, nodeList, annotation, minPrecedence)
        minPrecedence = minPrecedence or 0
        local ok = true
        local node
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
                    ok, rhsNode = self:ParseExpression(tokenStream, nodeList, annotation, precedence)
                    if ok then
                        if operator == "-" and rhsNode.type == "number" then
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
                    ok, node = self:ParseSimpleExpression(tokenStream, nodeList, annotation)
                    if ok and node then
                        node.asType = "boolean"
                    end
                end
            end
        end
        while ok do
            local keepScanning = false
            local tokenType, token = tokenStream:Peek()
            if  not tokenType then
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
                    ok, rhsNode = self:ParseExpression(tokenStream, nodeList, annotation, precedence)
                    if ok then
                        node = NewNode(nodeList, true)
                        node.type = opType
                        node.expressionType = "binary"
                        node.operator = operator
                        node.precedence = precedence
                        node.child[1] = lhsNode
                        node.child[2] = rhsNode
                        lhsNode.asType = asType
                        if  not rhsNode then
                            self:SyntaxError(tokenStream, "Internal error: no right operand in binary operator %s.", token)
                            return false, nil
                        end
                        rhsNode.asType = asType
                        while node.type == rhsNode.type and node.operator == rhsNode.operator and BINARY_OPERATOR[node.operator][3] == "associative" and rhsNode.expressionType == "binary" do
                            node.child[2] = rhsNode.child[1]
                            rhsNode.child[1] = node
                            node = rhsNode
                            rhsNode = node.child[2]
                        end
                    end
                end
            elseif  not node then
                self:SyntaxError(tokenStream, "Syntax error: %s of type %s is not a binary operator", token, tokenType)
                return false, nil
            end
            if  not keepScanning then
                break
            end
        end
        return ok, node
    end,
    ParseFunction = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local name
        do
            local tokenType, token = tokenStream:Consume()
            if tokenType == "keyword" and FUNCTION_KEYWORD[token] then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; '(' expected.", token)
                ok = false
            end
        end
        local argumentNode
        if ok then
            ok, argumentNode = self:ParseExpression(tokenStream, nodeList, annotation)
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = NewNode(nodeList, true)
            node.type = "function"
            node.name = name
            node.child[1] = argumentNode
        end
        return ok, node
    end,
    ParseIdentifier = function(self, tokenStream, nodeList, annotation)
        local _, token = tokenStream:Consume()
        local node = NewNode(nodeList)
        node.type = "operand"
        node.name = token
        annotation.operand = annotation.operand or {}
        annotation.operand[#annotation.operand + 1] = node
        return true, node
    end,
    ParseModifier = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local name
        do
            local tokenType, token = tokenStream:Consume()
            if tokenType == "keyword" and checkToken(MODIFIER_KEYWORD, token) then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line; expression keyword expected.", token)
                ok = false
            end
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "=" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line; '=' expected.", token)
                ok = false
            end
        end
        local expressionNode
        if ok then
            if LITTERAL_MODIFIER[name] then
                ok, expressionNode = self:ParseIdentifier(tokenStream, nodeList, annotation)
            else
                ok, expressionNode = self:ParseExpression(tokenStream, nodeList, annotation)
                if ok and expressionNode and name == "sec" then
                    expressionNode.asType = "value"
                end
            end
        end
        return ok, name, expressionNode
    end,
    ParseNumber = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local value
        do
            local tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                value = tonumber(token)
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing NUMBER; number expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = NewNode(nodeList)
            node.type = "number"
            node.value = value
        end
        return ok, node
    end,
    ParseOperand = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local name
        do
            local tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                name = token
            elseif tokenType == "keyword" and (token == "target" or token == "cooldown") then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing OPERAND; operand expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            node = NewNode(nodeList)
            node.type = "operand"
            node.name = name
            node.rune = RUNE_OPERAND[name]
            if node.rune then
                local firstCharacter = sub(name, 1, 1)
                node.includeDeath = (firstCharacter == "B" or firstCharacter == "F" or firstCharacter == "U")
            end
            annotation.operand = annotation.operand or {}
            annotation.operand[#annotation.operand + 1] = node
        end
        return ok, node
    end,
    ParseParentheses = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local leftToken, rightToken
        do
            local tokenType, token = tokenStream:Consume()
            if tokenType == "(" then
                leftToken, rightToken = "(", ")"
            elseif tokenType == "{" then
                leftToken, rightToken = "{", "}"
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '(' or '{' expected.", token)
                ok = false
            end
        end
        local node
        if ok then
            ok, node = self:ParseExpression(tokenStream, nodeList, annotation)
        end
        if ok then
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= rightToken then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '%s' expected.", token, rightToken)
                ok = false
            end
        end
        if ok then
            node.left = leftToken
            node.right = rightToken
        end
        return ok, node
    end,
    ParseSimpleExpression = function(self, tokenStream, nodeList, annotation)
        local ok = true
        local node
        local tokenType, token = tokenStream:Peek()
        if tokenType == "number" then
            ok, node = self:ParseNumber(tokenStream, nodeList, annotation)
        elseif tokenType == "keyword" then
            if FUNCTION_KEYWORD[token] then
                ok, node = self:ParseFunction(tokenStream, nodeList, annotation)
            elseif token == "target" or token == "cooldown" then
                ok, node = self:ParseOperand(tokenStream, nodeList, annotation)
            else
                self:SyntaxError(tokenStream, "Warning: unknown keyword %s when parsing SIMPLE EXPRESSION", token)
                return false, nil
            end
        elseif tokenType == "name" then
            ok, node = self:ParseOperand(tokenStream, nodeList, annotation)
        elseif tokenType == "(" then
            ok, node = self:ParseParentheses(tokenStream, nodeList, annotation)
        else
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION", token)
            tokenStream:Consume()
            ok = false
        end
        return ok, node
    end,
})
