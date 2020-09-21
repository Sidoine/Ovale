local __exports = LibStub:NewLibrary("ovale/AST", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local __Pool = LibStub:GetLibrary("ovale/Pool")
local OvalePool = __Pool.OvalePool
local __Lexer = LibStub:GetLibrary("ovale/Lexer")
local OvaleLexer = __Lexer.OvaleLexer
local __Stance = LibStub:GetLibrary("ovale/Stance")
local STANCE_NAME = __Stance.STANCE_NAME
local ipairs = ipairs
local next = next
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local type = type
local wipe = wipe
local kpairs = pairs
local format = string.format
local gsub = string.gsub
local lower = string.lower
local sub = string.sub
local concat = table.concat
local insert = table.insert
local sort = table.sort
local GetItemInfo = GetItemInfo
local __tools = LibStub:GetLibrary("ovale/tools")
local isLuaArray = __tools.isLuaArray
local isNumber = __tools.isNumber
local isString = __tools.isString
local checkToken = __tools.checkToken
local KEYWORD = {
    ["and"] = true,
    ["if"] = true,
    ["not"] = true,
    ["or"] = true,
    ["unless"] = true
}
local DECLARATION_KEYWORD = {
    ["addactionicon"] = true,
    ["addcheckbox"] = true,
    ["addfunction"] = true,
    ["addicon"] = true,
    ["addlistitem"] = true,
    ["define"] = true,
    ["include"] = true,
    ["iteminfo"] = true,
    ["itemrequire"] = true,
    ["itemlist"] = true,
    ["scorespells"] = true,
    ["spellinfo"] = true,
    ["spelllist"] = true,
    ["spellrequire"] = true
}
__exports.PARAMETER_KEYWORD = {
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
    ["wait"] = true
}
local SPELL_AURA_KEYWORD = {
    ["spelladdbuff"] = true,
    ["spelladddebuff"] = true,
    ["spelladdpetbuff"] = true,
    ["spelladdpetdebuff"] = true,
    ["spelladdtargetbuff"] = true,
    ["spelladdtargetdebuff"] = true,
    ["spelldamagebuff"] = true,
    ["spelldamagedebuff"] = true
}
local STANCE_KEYWORD = {
    ["if_stance"] = true,
    ["stance"] = true,
    ["to_stance"] = true
}
do
    for keyword, value in pairs(SPELL_AURA_KEYWORD) do
        DECLARATION_KEYWORD[keyword] = value
    end
    for keyword, value in pairs(DECLARATION_KEYWORD) do
        KEYWORD[keyword] = value
    end
    for keyword, value in pairs(__exports.PARAMETER_KEYWORD) do
        KEYWORD[keyword] = value
    end
end
local ACTION_PARAMETER_COUNT = {
    ["item"] = 1,
    ["macro"] = 1,
    ["spell"] = 1,
    ["texture"] = 1,
    ["setstate"] = 2
}
local STATE_ACTION = {
    ["setstate"] = true
}
local STRING_LOOKUP_FUNCTION = {
    ["itemname"] = true,
    ["l"] = true,
    ["spellname"] = true
}
local UNARY_OPERATOR = {
    ["not"] = {
        [1] = "logical",
        [2] = 15
    },
    ["-"] = {
        [1] = "arithmetic",
        [2] = 50
    }
}
local BINARY_OPERATOR = {
    ["or"] = {
        [1] = "logical",
        [2] = 5,
        [3] = "associative"
    },
    ["xor"] = {
        [1] = "logical",
        [2] = 8,
        [3] = "associative"
    },
    ["and"] = {
        [1] = "logical",
        [2] = 10,
        [3] = "associative"
    },
    ["!="] = {
        [1] = "compare",
        [2] = 20
    },
    ["<"] = {
        [1] = "compare",
        [2] = 20
    },
    ["<="] = {
        [1] = "compare",
        [2] = 20
    },
    ["=="] = {
        [1] = "compare",
        [2] = 20
    },
    [">"] = {
        [1] = "compare",
        [2] = 20
    },
    [">="] = {
        [1] = "compare",
        [2] = 20
    },
    ["+"] = {
        [1] = "arithmetic",
        [2] = 30,
        [3] = "associative"
    },
    ["-"] = {
        [1] = "arithmetic",
        [2] = 30
    },
    ["%"] = {
        [1] = "arithmetic",
        [2] = 40
    },
    ["*"] = {
        [1] = "arithmetic",
        [2] = 40,
        [3] = "associative"
    },
    ["/"] = {
        [1] = "arithmetic",
        [2] = 40
    },
    ["^"] = {
        [1] = "arithmetic",
        [2] = 100
    },
    [">?"] = {
        [1] = "arithmetic",
        [2] = 25
    },
    ["<?"] = {
        [1] = "arithmetic",
        [2] = 25
    }
}
local indent = {}
indent[0] = ""
local function INDENT(key)
    local ret = indent[key]
    if ret == nil then
        ret = INDENT(key - 1) .. " "
        indent[key] = ret
    end
    return ret
end
__exports.isNodeType = function(node, type)
    return node.type == type
end
local function isCheckBoxParameter(key, value)
    return key == "checkbox"
end
local function isListItemParameter(key, value)
    return key == "listitem"
end
local function isCheckBoxFlattenParameters(key, value)
    return key == "checkbox"
end
local function isListItemFlattenParameters(key, value)
    return key == "listitem"
end
local function isCsvNode(node)
    return (node.type == "comma_separated_values" or node.previousType == "comma_separated_values")
end
local function isVariableNode(node)
    return node.type == "variable" or node.previousType == "variable"
end
local TokenizeComment = function(token)
    return "comment", token
end

local TokenizeName = function(token)
    token = lower(token)
    if KEYWORD[token] then
        return "keyword", token
    else
        return "name", token
    end
end

local TokenizeNumber = function(token)
    return "number", token
end

local TokenizeString = function(token)
    token = sub(token, 2, -2)
    return "string", token
end

local TokenizeWhitespace = function(token)
    return "space", token
end

local Tokenize = function(token)
    return token, token
end

local NoToken = function()
    return nil, nil
end

local MATCHES = {
    [1] = {
        [1] = "^%s+",
        [2] = TokenizeWhitespace
    },
    [2] = {
        [1] = "^%d+%.?%d*",
        [2] = TokenizeNumber
    },
    [3] = {
        [1] = "^[%a_][%w_]*",
        [2] = TokenizeName
    },
    [4] = {
        [1] = "^((['\"])%2)",
        [2] = TokenizeString
    },
    [5] = {
        [1] = [[^(['"]).-\%1]],
        [2] = TokenizeString
    },
    [6] = {
        [1] = [[^(['\"]).-[^\]%1]],
        [2] = TokenizeString
    },
    [7] = {
        [1] = "^#.-\n",
        [2] = TokenizeComment
    },
    [8] = {
        [1] = "^!=",
        [2] = Tokenize
    },
    [9] = {
        [1] = "^==",
        [2] = Tokenize
    },
    [10] = {
        [1] = "^<=",
        [2] = Tokenize
    },
    [11] = {
        [1] = "^>=",
        [2] = Tokenize
    },
    [12] = {
        [1] = "^>%?",
        [2] = Tokenize
    },
    [13] = {
        [1] = "^<%?",
        [2] = Tokenize
    },
    [14] = {
        [1] = "^.",
        [2] = Tokenize
    },
    [15] = {
        [1] = "^$",
        [2] = NoToken
    }
}
local FILTERS = {
    comments = TokenizeComment,
    space = TokenizeWhitespace
}
local SelfPool = __class(OvalePool, {
    constructor = function(self, ovaleAst)
        self.ovaleAst = ovaleAst
        OvalePool.constructor(self, "OvaleAST_pool")
    end,
    Clean = function(self, node)
        if node.child then
            self.ovaleAst.childrenPool:Release(node.child)
            node.child = nil
        end
        if node.postOrder then
            self.ovaleAst.postOrderPool:Release(node.postOrder)
            node.postOrder = nil
        end
    end,
})
local function isAstNode(a)
    return type(a) == "table"
end
__exports.OvaleASTClass = __class(nil, {
    constructor = function(self, ovaleCondition, ovaleDebug, ovaleProfiler, ovaleScripts, ovaleSpellBook)
        self.ovaleCondition = ovaleCondition
        self.ovaleScripts = ovaleScripts
        self.ovaleSpellBook = ovaleSpellBook
        self.indent = 0
        self.outputPool = OvalePool("OvaleAST_outputPool")
        self.listPool = OvalePool("OvaleAST_listPool")
        self.checkboxPool = OvalePool("OvaleAST_checkboxPool")
        self.flattenParameterValuesPool = OvalePool("OvaleAST_FlattenParameterValues")
        self.rawNamedParametersPool = OvalePool("OvaleAST_rawNamedParametersPool")
        self.rawPositionalParametersPool = OvalePool("OVALEAST_rawPositionParametersPool")
        self.flattenParametersPool = OvalePool("OvaleAST_FlattenParametersPool")
        self.objectPool = OvalePool("OvalePool")
        self.childrenPool = OvalePool("OvaleAST_childrenPool")
        self.postOrderPool = OvalePool("OvaleAST_postOrderPool")
        self.postOrderVisitedPool = OvalePool("OvaleAST_postOrderVisitedPool")
        self.nodesPool = SelfPool(self)
        self.UnparseAddCheckBox = function(node)
            local s
            if (node.rawPositionalParams and next(node.rawPositionalParams)) or (node.rawNamedParams and next(node.rawNamedParams)) then
                s = format("AddCheckBox(%s %s %s)", node.name, self:Unparse(node.description), self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
            else
                s = format("AddCheckBox(%s %s)", node.name, self:Unparse(node.description))
            end
            return s
        end
        self.UnparseAddFunction = function(node)
            local s
            if self:HasParameters(node) then
                s = format("AddFunction %s %s%s", node.name, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams), self.UnparseGroup(node.child[1]))
            else
                s = format("AddFunction %s%s", node.name, self.UnparseGroup(node.child[1]))
            end
            return s
        end
        self.UnparseAddIcon = function(node)
            local s
            if self:HasParameters(node) then
                s = format("AddIcon %s%s", self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams), self.UnparseGroup(node.child[1]))
            else
                s = format("AddIcon%s", self.UnparseGroup(node.child[1]))
            end
            return s
        end
        self.UnparseAddListItem = function(node)
            local s
            if self:HasParameters(node) then
                s = format("AddListItem(%s %s %s %s)", node.name, node.item, self:Unparse(node.description), self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
            else
                s = format("AddListItem(%s %s %s)", node.name, node.item, self:Unparse(node.description))
            end
            return s
        end
        self.UnparseBangValue = function(node)
            return "!" .. self:Unparse(node.child[1])
        end
        self.UnparseComment = function(node)
            if  not node.comment or node.comment == "" then
                return ""
            else
                return "#" .. node.comment
            end
        end
        self.UnparseCommaSeparatedValues = function(node)
            local output = self.outputPool:Get()
            for k, v in ipairs(node.csv) do
                output[k] = self:Unparse(v)
            end
            local outputString = concat(output, ",")
            self.outputPool:Release(output)
            return outputString
        end
        self.UnparseDefine = function(node)
            return format("Define(%s %s)", node.name, node.value)
        end
        self.UnparseExpression = function(node)
            local expression
            local precedence = self:GetPrecedence(node)
            if node.expressionType == "unary" then
                local rhsExpression
                local rhsNode = node.child[1]
                local rhsPrecedence = self:GetPrecedence(rhsNode)
                if rhsPrecedence and precedence >= rhsPrecedence then
                    rhsExpression = "{ " .. self:Unparse(rhsNode) .. " }"
                else
                    rhsExpression = self:Unparse(rhsNode)
                end
                if node.operator == "-" then
                    expression = "-" .. rhsExpression
                else
                    expression = node.operator .. " " .. rhsExpression
                end
            elseif node.expressionType == "binary" then
                local lhsExpression, rhsExpression
                local lhsNode = node.child[1]
                local lhsPrecedence = self:GetPrecedence(lhsNode)
                if lhsPrecedence and lhsPrecedence < precedence then
                    lhsExpression = "{ " .. self:Unparse(lhsNode) .. " }"
                else
                    lhsExpression = self:Unparse(lhsNode)
                end
                local rhsNode = node.child[2]
                local rhsPrecedence = self:GetPrecedence(rhsNode)
                if rhsPrecedence and precedence > rhsPrecedence then
                    rhsExpression = "{ " .. self:Unparse(rhsNode) .. " }"
                elseif rhsPrecedence and precedence == rhsPrecedence then
                    local operatorInfo = BINARY_OPERATOR[node.operator]
                    if operatorInfo and operatorInfo[3] == "associative" and node.operator == rhsNode.operator then
                        rhsExpression = self:Unparse(rhsNode)
                    else
                        rhsExpression = "{ " .. self:Unparse(rhsNode) .. " }"
                    end
                else
                    rhsExpression = self:Unparse(rhsNode)
                end
                expression = lhsExpression .. " " .. node.operator .. " " .. rhsExpression
            else
                self.debug:Error("node.expressionType '" .. node.expressionType .. "' is not known")
                return "Not_Unparsable"
            end
            return expression
        end
        self.UnparseFunction = function(node)
            local s
            if self:HasParameters(node) then
                local name
                local filter = node.rawNamedParams.filter
                if filter == "debuff" then
                    name = gsub(node.name, "^Buff", "Debuff")
                else
                    name = node.name
                end
                local target = node.rawNamedParams.target
                if target then
                    s = format("%s.%s(%s)", target, name, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
                else
                    s = format("%s(%s)", name, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
                end
            else
                s = format("%s()", node.name)
            end
            return s
        end
        self.UnparseGroup = function(node)
            local output = self.outputPool:Get()
            output[#output + 1] = ""
            output[#output + 1] = INDENT(self.indent) .. "{"
            self.indent = self.indent + 1
            for _, statementNode in ipairs(node.child) do
                local s = self:Unparse(statementNode)
                if s == "" then
                    output[#output + 1] = s
                else
                    output[#output + 1] = INDENT(self.indent) .. s
                end
            end
            self.indent = self.indent - 1
            output[#output + 1] = INDENT(self.indent) .. "}"
            local outputString = concat(output, "\n")
            self.outputPool:Release(output)
            return outputString
        end
        self.UnparseIf = function(node)
            if node.child[2].type == "group" then
                return format("if %s%s", self:Unparse(node.child[1]), self.UnparseGroup(node.child[2]))
            else
                return format("if %s %s", self:Unparse(node.child[1]), self:Unparse(node.child[2]))
            end
        end
        self.UnparseItemInfo = function(node)
            local identifier = (node.name and node.name) or node.itemId
            return format("ItemInfo(%s %s)", identifier, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
        end
        self.UnparseItemRequire = function(node)
            local identifier = (node.name and node.name) or node.itemId
            return format("ItemRequire(%s %s %s)", identifier, node.property, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
        end
        self.UnparseList = function(node)
            return format("%s(%s %s)", node.keyword, node.name, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
        end
        self.UnparseValue = function(node)
            return tostring(node.value)
        end
        self.UnparseScoreSpells = function(node)
            return format("ScoreSpells(%s)", self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
        end
        self.UnparseScript = function(node)
            local output = self.outputPool:Get()
            local previousDeclarationType
            for _, declarationNode in ipairs(node.child) do
                if declarationNode.type == "item_info" or declarationNode.type == "spell_aura_list" or declarationNode.type == "spell_info" or declarationNode.type == "spell_require" then
                    local s = self:Unparse(declarationNode)
                    if s == "" then
                        output[#output + 1] = s
                    else
                        output[#output + 1] = INDENT(self.indent + 1) .. s
                    end
                else
                    local insertBlank = false
                    if previousDeclarationType and previousDeclarationType ~= declarationNode.type then
                        insertBlank = true
                    end
                    if declarationNode.type == "add_function" or declarationNode.type == "icon" then
                        insertBlank = true
                    end
                    if insertBlank then
                        output[#output + 1] = ""
                    end
                    output[#output + 1] = self:Unparse(declarationNode)
                    previousDeclarationType = declarationNode.type
                end
            end
            local outputString = concat(output, "\n")
            self.outputPool:Release(output)
            return outputString
        end
        self.UnparseSpellAuraList = function(node)
            local identifier = (node.name and node.name) or node.spellId
            return format("%s(%s %s)", node.keyword, identifier, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
        end
        self.UnparseSpellInfo = function(node)
            local identifier = (node.name and node.name) or node.spellId
            return format("SpellInfo(%s %s)", identifier, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
        end
        self.UnparseSpellRequire = function(node)
            local identifier = (node.name and node.name) or node.spellId
            return format("SpellRequire(%s %s %s)", identifier, node.property, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
        end
        self.UnparseString = function(node)
            return "\"" .. node.value .. "\""
        end
        self.UnparseUnless = function(node)
            if node.child[2].type == "group" then
                return format("unless %s%s", self:Unparse(node.child[1]), self.UnparseGroup(node.child[2]))
            else
                return format("unless %s %s", self:Unparse(node.child[1]), self:Unparse(node.child[2]))
            end
        end
        self.UnparseVariable = function(node)
            return node.name
        end
        self.UNPARSE_VISITOR = {
            ["action"] = self.UnparseFunction,
            ["add_function"] = self.UnparseAddFunction,
            ["arithmetic"] = self.UnparseExpression,
            ["bang_value"] = self.UnparseBangValue,
            ["checkbox"] = self.UnparseAddCheckBox,
            ["compare"] = self.UnparseExpression,
            ["comma_separated_values"] = self.UnparseCommaSeparatedValues,
            ["comment"] = self.UnparseComment,
            ["custom_function"] = self.UnparseFunction,
            ["define"] = self.UnparseDefine,
            ["function"] = self.UnparseFunction,
            ["group"] = self.UnparseGroup,
            ["icon"] = self.UnparseAddIcon,
            ["if"] = self.UnparseIf,
            ["item_info"] = self.UnparseItemInfo,
            ["itemrequire"] = self.UnparseItemRequire,
            ["list"] = self.UnparseList,
            ["list_item"] = self.UnparseAddListItem,
            ["logical"] = self.UnparseExpression,
            ["score_spells"] = self.UnparseScoreSpells,
            ["script"] = self.UnparseScript,
            ["spell_aura_list"] = self.UnparseSpellAuraList,
            ["spell_info"] = self.UnparseSpellInfo,
            ["spell_require"] = self.UnparseSpellRequire,
            ["state"] = self.UnparseFunction,
            ["string"] = self.UnparseString,
            ["unless"] = self.UnparseUnless,
            ["value"] = self.UnparseValue,
            ["variable"] = self.UnparseVariable
        }
        self.ParseAddCheckBox = function(tokenStream, nodeList, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "addcheckbox") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; 'AddCheckBox' expected.", token)
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; '(' expected.", token)
                return nil
            end
            local name = ""
            tokenType, token = tokenStream:Consume()
            if tokenType == "name" and token ~= nil then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; name expected.", token)
                return nil
            end
            local descriptionNode = self.ParseString(tokenStream, nodeList, annotation)
            if  not descriptionNode then
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; ')' expected.", token)
                return nil
            end
            local node = self:NewNode(nodeList)
            node.type = "checkbox"
            node.name = name
            node.description = descriptionNode
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            return node
        end
        self.ParseAddFunction = function(tokenStream, nodeList, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "addfunction") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; 'AddFunction' expected.", token)
                return nil
            end
            local name
            tokenType, token = tokenStream:Consume()
            if tokenType == "name" and token then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; name expected.", token)
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
            if  not positionalParams or  not namedParams then
                return nil
            end
            local bodyNode = self.ParseGroup(tokenStream, nodeList, annotation)
            if  not bodyNode then
                return nil
            end
            local node
            node = self:NewNode(nodeList, true)
            node.type = "add_function"
            node.name = name
            node.child[1] = bodyNode
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            annotation.postOrderReference = annotation.postOrderReference or {}
            annotation.postOrderReference[#annotation.postOrderReference + 1] = bodyNode
            annotation.customFunction = annotation.customFunction or {}
            annotation.customFunction[name] = node
            return node
        end
        self.ParseAddIcon = function(tokenStream, nodeList, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "addicon") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDICON; 'AddIcon' expected.", token)
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
            if  not positionalParams or  not namedParams then
                return nil
            end
            local bodyNode = self.ParseGroup(tokenStream, nodeList, annotation)
            if  not bodyNode then
                return nil
            end
            local node
            node = self:NewNode(nodeList, true)
            node.type = "icon"
            node.child[1] = bodyNode
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            annotation.postOrderReference = annotation.postOrderReference or {}
            annotation.postOrderReference[#annotation.postOrderReference + 1] = bodyNode
            return node
        end
        self.ParseAddListItem = function(tokenStream, nodeList, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "addlistitem") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; 'AddListItem' expected.", token)
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; '(' expected.", token)
                return nil
            end
            local name
            tokenType, token = tokenStream:Consume()
            if tokenType == "name" and token then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.", token)
                return nil
            end
            local item
            tokenType, token = tokenStream:Consume()
            if tokenType == "name" and token then
                item = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.", token)
                return nil
            end
            local descriptionNode = self.ParseString(tokenStream, nodeList, annotation)
            if  not descriptionNode then
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; ')' expected.", token)
                return nil
            end
            local node
            node = self:NewNode(nodeList)
            node.type = "list_item"
            node.name = name
            node.item = item
            node.description = descriptionNode
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            return node
        end
        self.ParseComment = function(tokenStream, nodeList, annotation)
            return nil
        end
        self.ParseDeclaration = function(tokenStream, nodeList, annotation)
            local node
            local tokenType, token = tokenStream:Peek()
            if tokenType == "keyword" and token and DECLARATION_KEYWORD[token] then
                if token == "addcheckbox" then
                    node = self.ParseAddCheckBox(tokenStream, nodeList, annotation)
                elseif token == "addfunction" then
                    node = self.ParseAddFunction(tokenStream, nodeList, annotation)
                elseif token == "addicon" then
                    node = self.ParseAddIcon(tokenStream, nodeList, annotation)
                elseif token == "addlistitem" then
                    node = self.ParseAddListItem(tokenStream, nodeList, annotation)
                elseif token == "define" then
                    node = self.ParseDefine(tokenStream, nodeList, annotation)
                elseif token == "include" then
                    node = self.ParseInclude(tokenStream, nodeList, annotation)
                elseif token == "iteminfo" then
                    node = self.ParseItemInfo(tokenStream, nodeList, annotation)
                elseif token == "itemrequire" then
                    node = self.ParseItemRequire(tokenStream, nodeList, annotation)
                elseif token == "itemlist" then
                    node = self.ParseList(tokenStream, nodeList, annotation)
                elseif token == "scorespells" then
                    node = self.ParseScoreSpells(tokenStream, nodeList, annotation)
                elseif SPELL_AURA_KEYWORD[token] then
                    node = self.ParseSpellAuraList(tokenStream, nodeList, annotation)
                elseif token == "spellinfo" then
                    node = self.ParseSpellInfo(tokenStream, nodeList, annotation)
                elseif token == "spelllist" then
                    node = self.ParseList(tokenStream, nodeList, annotation)
                elseif token == "spellrequire" then
                    node = self.ParseSpellRequire(tokenStream, nodeList, annotation)
                else
                    self:SyntaxError(tokenStream, "Syntax error: unknown keywork '%s'", token)
                    return 
                end
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DECLARATION; declaration keyword expected.", token)
                tokenStream:Consume()
                return nil
            end
            return node
        end
        self.ParseDefine = function(tokenStream, nodeList, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "define") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; 'Define' expected.", token)
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; '(' expected.", token)
                return nil
            end
            local name
            tokenType, token = tokenStream:Consume()
            if tokenType == "name" and token then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; name expected.", token)
                return nil
            end
            local value
            tokenType, token = tokenStream:Consume()
            if tokenType == "-" then
                tokenType, token = tokenStream:Consume()
                if tokenType == "number" then
                    value = -1 * tonumber(token)
                else
                    self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; number expected after '-'.", token)
                    return nil
                end
            elseif tokenType == "number" then
                value = tonumber(token)
            elseif tokenType == "string" and token then
                value = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; number or string expected.", token)
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; ')' expected.", token)
                return nil
            end
            local node
            node = self:NewNode(nodeList)
            node.type = "define"
            node.name = name
            node.value = value
            annotation.definition = annotation.definition or {}
            annotation.definition[name] = value
            return node
        end
        self.ParseExpression = function(tokenStream, nodeList, annotation, minPrecedence)
            minPrecedence = minPrecedence or 0
            local node
            local tokenType, token = tokenStream:Peek()
            if tokenType then
                local opInfo = UNARY_OPERATOR[token]
                if opInfo then
                    local opType, precedence = opInfo[1], opInfo[2]
                    tokenStream:Consume()
                    local operator = token
                    local rhsNode = self.ParseExpression(tokenStream, nodeList, annotation, precedence)
                    if rhsNode then
                        if operator == "-" and __exports.isNodeType(rhsNode, "value") then
                            local value = -1 * tonumber(rhsNode.value)
                            node = self:GetNumberNode(value, nodeList, annotation)
                        else
                            node = self:NewNode(nodeList, true)
                            node.type = opType
                            node.expressionType = "unary"
                            node.operator = operator
                            node.precedence = precedence
                            node.child[1] = rhsNode
                        end
                    else
                        return nil
                    end
                else
                    local simpleExpression = self:ParseSimpleExpression(tokenStream, nodeList, annotation)
                    if  not simpleExpression then
                        return nil
                    end
                    node = simpleExpression
                end
            else
                return nil
            end
            local keepScanning = true
            while keepScanning do
                keepScanning = false
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
                            local rhsNode = self.ParseExpression(tokenStream, nodeList, annotation, precedence)
                            if rhsNode then
                                node = self:NewNode(nodeList, true)
                                node.type = opType
                                node.expressionType = "binary"
                                node.operator = operator
                                node.precedence = precedence
                                node.child[1] = lhsNode
                                node.child[2] = rhsNode
                                local operatorInfo = BINARY_OPERATOR[node.operator]
                                if  not operatorInfo then
                                    return nil
                                end
                                while node.type == rhsNode.type and node.operator == rhsNode.operator and operatorInfo[3] == "associative" and rhsNode.expressionType == "binary" do
                                    node.child[2] = rhsNode.child[1]
                                    rhsNode.child[1] = node
                                    node = rhsNode
                                    rhsNode = node.child[2]
                                end
                            else
                                return nil
                            end
                        end
                    end
                end
            end
            return node
        end
        self.ParseFunction = function(tokenStream, nodeList, annotation)
            local name
            do
                local tokenType, token = tokenStream:Consume()
                if (tokenType == "name" or tokenType == "keyword") and token then
                    name = token
                else
                    self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token)
                    return nil
                end
            end
            local target
            local tokenType, token = tokenStream:Peek()
            if tokenType == "." then
                target = name
                tokenType, token = tokenStream:Consume(2)
                if tokenType == "name" and token then
                    name = token
                else
                    self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token)
                    return nil
                end
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; '(' expected.", token)
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
            if  not positionalParams or  not namedParams then
                return nil
            end
            if ACTION_PARAMETER_COUNT[name] then
                local count = ACTION_PARAMETER_COUNT[name]
                if count > #positionalParams then
                    self:SyntaxError(tokenStream, "Syntax error: action '%s' requires at least %d fixed parameter(s).", name, count)
                    return nil
                end
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.", token)
                return nil
            end
            if  not namedParams.target then
                if sub(name, 1, 6) == "target" then
                    namedParams.target = "target"
                    name = sub(name, 7)
                end
            end
            if  not namedParams.filter then
                if sub(name, 1, 6) == "debuff" then
                    namedParams.filter = "debuff"
                elseif sub(name, 1, 4) == "buff" then
                    namedParams.filter = "buff"
                elseif sub(name, 1, 11) == "otherdebuff" then
                    namedParams.filter = "debuff"
                elseif sub(name, 1, 9) == "otherbuff" then
                    namedParams.filter = "buff"
                end
            end
            if target then
                namedParams.target = target
            end
            local node
            node = self:NewNode(nodeList)
            node.name = name
            if STATE_ACTION[name] then
                node.type = "state"
                node.func = name
            elseif ACTION_PARAMETER_COUNT[name] then
                node.type = "action"
                node.func = name
            elseif STRING_LOOKUP_FUNCTION[name] then
                node.type = "function"
                node.func = name
                annotation.stringReference = annotation.stringReference or {}
                annotation.stringReference[#annotation.stringReference + 1] = node
            elseif self.ovaleCondition:IsCondition(name) then
                node.type = "function"
                node.func = name
            else
                node.type = "custom_function"
                node.func = name
            end
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            node.asString = self.UnparseFunction(node)
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            annotation.functionCall = annotation.functionCall or {}
            annotation.functionCall[node.func] = true
            annotation.functionReference = annotation.functionReference or {}
            annotation.functionReference[#annotation.functionReference + 1] = node
            return node
        end
        self.ParseGroup = function(tokenStream, nodeList, annotation)
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "{" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '{' expected.", token)
                return nil
            end
            local child = self.childrenPool:Get()
            tokenType = tokenStream:Peek()
            while tokenType and tokenType ~= "}" do
                local statementNode
                statementNode = self:ParseStatement(tokenStream, nodeList, annotation)
                if statementNode then
                    child[#child + 1] = statementNode
                    tokenType = tokenStream:Peek()
                else
                    return nil
                end
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "}" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '}' expected.", token)
                self.childrenPool:Release(child)
                return nil
            end
            local node
            node = self:NewNode(nodeList)
            node.type = "group"
            node.child = child
            return node
        end
        self.ParseIf = function(tokenStream, nodeList, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "if") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing IF; 'if' expected.", token)
                return nil
            end
            local conditionNode, bodyNode
            conditionNode = self.ParseExpression(tokenStream, nodeList, annotation)
            if  not conditionNode then
                return nil
            end
            bodyNode = self:ParseStatement(tokenStream, nodeList, annotation)
            if  not bodyNode then
                return nil
            end
            local node
            node = self:NewNode(nodeList, true)
            node.type = "if"
            node.child[1] = conditionNode
            node.child[2] = bodyNode
            return node
        end
        self.ParseInclude = function(tokenStream, nodeList, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "include") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; 'Include' expected.", token)
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; '(' expected.", token)
                return nil
            end
            local name
            tokenType, token = tokenStream:Consume()
            if tokenType == "name" and token then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; script name expected.", token)
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; ')' expected.", token)
                return nil
            end
            local code = self.ovaleScripts:GetScript(name)
            if code == nil then
                self.debug:Error("Script '%s' not found when parsing INCLUDE.", name)
                return nil
            end
            local node
            local includeTokenStream = OvaleLexer(name, code, MATCHES, FILTERS)
            node = self.ParseScriptStream(includeTokenStream, nodeList, annotation)
            includeTokenStream:Release()
            return node
        end
        self.ParseItemInfo = function(tokenStream, nodeList, annotation)
            local name
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "iteminfo") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; 'ItemInfo' expected.", token)
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; '(' expected.", token)
                return nil
            end
            local itemId
            tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                itemId = token
            elseif tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; number or name expected.", token)
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; ')' expected.", token)
                return nil
            end
            local node
            node = self:NewNode(nodeList)
            node.type = "item_info"
            node.itemId = tonumber(itemId)
            if name then
                node.name = name
            end
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            if name then
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
            return node
        end
        self.ParseItemRequire = function(tokenStream, nodeList, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "itemrequire") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; keyword expected.", token)
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; '(' expected.", token)
                return nil
            end
            local itemId, name
            tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                itemId = token
            elseif tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; number or name expected.", token)
                return nil
            end
            local property
            tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                property = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; property name expected.", token)
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; ')' expected.", token)
                return nil
            end
            local node
            node = self:NewNode(nodeList)
            node.type = "itemrequire"
            node.itemId = tonumber(itemId)
            if name then
                node.name = name
            end
            node.property = property
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            if name then
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
            return node
        end
        self.ParseList = function(tokenStream, nodeList, annotation)
            local keyword
            local tokenType, token = tokenStream:Consume()
            if tokenType == "keyword" and (token == "itemlist" or token == "spelllist") then
                keyword = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; keyword expected.", token)
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; '(' expected.", token)
                return nil
            end
            local name
            tokenType, token = tokenStream:Consume()
            if tokenType == "name" and token then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; name expected.", token)
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; ')' expected.", token)
                return nil
            end
            local node
            node = self:NewNode(nodeList)
            node.type = "list"
            node.keyword = keyword
            node.name = name
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            return node
        end
        self.ParseNumber = function(tokenStream, nodeList, annotation)
            local value
            local tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                value = tonumber(token)
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing NUMBER; number expected.", token)
                return nil
            end
            local node = self:GetNumberNode(value, nodeList, annotation)
            return node
        end
        self.ParseParameterValue = function(tokenStream, nodeList, annotation)
            local node
            local tokenType
            local parameters
            repeat
                node = self.ParseSimpleParameterValue(tokenStream, nodeList, annotation)
                if node then
                    tokenType = tokenStream:Peek()
                    if tokenType == "," then
                        tokenStream:Consume()
                        parameters = parameters or self.objectPool:Get()
                    end
                    if parameters then
                        parameters[#parameters + 1] = node
                    end
                else
                    return nil
                end
            until not (node and tokenType == ",")
            if parameters then
                node = self:NewNode(nodeList)
                node.type = "comma_separated_values"
                node.csv = parameters
                annotation.objects = annotation.objects or {}
                annotation.objects[#annotation.objects + 1] = parameters
            end
            return node
        end
        self.ParseScoreSpells = function(tokenStream, nodeList, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "scorespells") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; 'ScoreSpells' expected.", token)
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; '(' expected.", token)
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; ')' expected.", token)
                return nil
            end
            local node = self:NewNode(nodeList)
            node.type = "score_spells"
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            return node
        end
        self.ParseScriptStream = function(tokenStream, nodeList, annotation)
            self.profiler:StartProfiling("OvaleAST_ParseScript")
            local child = self.childrenPool:Get()
            while true do
                local tokenType = tokenStream:Peek()
                if tokenType then
                    local declarationNode = self.ParseDeclaration(tokenStream, nodeList, annotation)
                    if  not declarationNode then
                        self.childrenPool:Release(child)
                        return nil
                    end
                    if declarationNode.type == "script" then
                        for _, node in ipairs(declarationNode.child) do
                            child[#child + 1] = node
                        end
                        self.nodesPool:Release(declarationNode)
                    else
                        child[#child + 1] = declarationNode
                    end
                else
                    break
                end
            end
            local ast
            ast = self:NewNode()
            ast.type = "script"
            ast.child = child
            self.profiler:StopProfiling("OvaleAST_ParseScript")
            return ast
        end
        self.ParseSimpleParameterValue = function(tokenStream, nodeList, annotation)
            local isBang = false
            local tokenType = tokenStream:Peek()
            if tokenType == "!" then
                isBang = true
                tokenStream:Consume()
            end
            local expressionNode
            tokenType = tokenStream:Peek()
            if tokenType == "(" or tokenType == "-" then
                expressionNode = self.ParseExpression(tokenStream, nodeList, annotation)
            else
                expressionNode = self:ParseSimpleExpression(tokenStream, nodeList, annotation)
            end
            if  not expressionNode then
                return nil
            end
            local node
            if isBang then
                node = self:NewNode(nodeList, true)
                node.type = "bang_value"
                node.child[1] = expressionNode
            else
                node = expressionNode
            end
            return node
        end
        self.ParseSpellAuraList = function(tokenStream, nodeList, annotation)
            local keyword
            local tokenType, token = tokenStream:Consume()
            if tokenType == "keyword" and token and SPELL_AURA_KEYWORD[token] then
                keyword = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; keyword expected.", token)
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; '(' expected.", token)
                return nil
            end
            local spellId, name
            tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                spellId = tonumber(token)
            elseif tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; number or name expected.", token)
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; ')' expected.", token)
                return nil
            end
            local node
            node = self:NewNode(nodeList)
            node.type = "spell_aura_list"
            node.keyword = keyword
            if spellId then
                node.spellId = spellId
            end
            if name then
                node.name = name
            end
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            if name then
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
            return node
        end
        self.ParseSpellInfo = function(tokenStream, nodeList, annotation)
            local name
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "spellinfo") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; 'SpellInfo' expected.", token)
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; '(' expected.", token)
                return nil
            end
            local spellId
            tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                spellId = tonumber(token)
            elseif tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; number or name expected.", token)
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; ')' expected.", token)
                return nil
            end
            local node
            node = self:NewNode(nodeList)
            node.type = "spell_info"
            if spellId then
                node.spellId = spellId
            end
            if name then
                node.name = name
            end
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            if name then
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
            return node
        end
        self.ParseSpellRequire = function(tokenStream, nodeList, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "spellrequire") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; keyword expected.", token)
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "(" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; '(' expected.", token)
                return nil
            end
            local spellId, name
            tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                spellId = tonumber(token)
            elseif tokenType == "name" then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; number or name expected.", token)
                return nil
            end
            local property
            tokenType, token = tokenStream:Consume()
            if tokenType == "name" then
                property = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; property name expected.", token)
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, nodeList, annotation)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; ')' expected.", token)
                return nil
            end
            local node
            node = self:NewNode(nodeList)
            node.type = "spell_require"
            if spellId then
                node.spellId = spellId
            end
            if name then
                node.name = name
            end
            node.property = property
            node.rawPositionalParams = positionalParams
            node.rawNamedParams = namedParams
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            if name then
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
            return node
        end
        self.ParseString = function(tokenStream, nodeList, annotation)
            local value
            local tokenType, token = tokenStream:Peek()
            if tokenType == "string" and token then
                value = token
                tokenStream:Consume()
            elseif tokenType == "name" and token then
                if STRING_LOOKUP_FUNCTION[lower(token)] then
                    return self.ParseFunction(tokenStream, nodeList, annotation)
                else
                    value = token
                    tokenStream:Consume()
                end
            else
                tokenStream:Consume()
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing STRING; string, variable, or function expected.", token)
                return nil
            end
            local node
            node = self:NewNode(nodeList)
            node.type = "string"
            node.value = value
            annotation.stringReference = annotation.stringReference or {}
            annotation.stringReference[#annotation.stringReference + 1] = node
            return node
        end
        self.ParseUnless = function(tokenStream, nodeList, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "unless") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing UNLESS; 'unless' expected.", token)
                return nil
            end
            local conditionNode, bodyNode
            conditionNode = self.ParseExpression(tokenStream, nodeList, annotation)
            if  not conditionNode then
                return nil
            end
            bodyNode = self:ParseStatement(tokenStream, nodeList, annotation)
            if  not bodyNode then
                return nil
            end
            local node
            node = self:NewNode(nodeList, true)
            node.type = "unless"
            node.child[1] = conditionNode
            node.child[2] = bodyNode
            return node
        end
        self.ParseVariable = function(tokenStream, nodeList, annotation)
            local name
            local tokenType, token = tokenStream:Consume()
            if tokenType == "name" and token then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing VARIABLE; name expected.", token)
                return nil
            end
            local node
            node = self:NewNode(nodeList)
            node.type = "variable"
            node.name = name
            annotation.nameReference = annotation.nameReference or {}
            annotation.nameReference[#annotation.nameReference + 1] = node
            return node
        end
        self.PARSE_VISITOR = {
            ["action"] = self.ParseFunction,
            ["add_function"] = self.ParseAddFunction,
            ["arithmetic"] = self.ParseExpression,
            ["bang_value"] = self.ParseSimpleParameterValue,
            ["checkbox"] = self.ParseAddCheckBox,
            ["compare"] = self.ParseExpression,
            ["comment"] = self.ParseComment,
            ["custom_function"] = self.ParseFunction,
            ["define"] = self.ParseDefine,
            ["expression"] = self.ParseExpression,
            ["function"] = self.ParseFunction,
            ["group"] = self.ParseGroup,
            ["icon"] = self.ParseAddIcon,
            ["if"] = self.ParseIf,
            ["item_info"] = self.ParseItemInfo,
            ["itemrequire"] = self.ParseItemRequire,
            ["list"] = self.ParseList,
            ["list_item"] = self.ParseAddListItem,
            ["logical"] = self.ParseExpression,
            ["score_spells"] = self.ParseScoreSpells,
            ["script"] = self.ParseScriptStream,
            ["spell_aura_list"] = self.ParseSpellAuraList,
            ["spell_info"] = self.ParseSpellInfo,
            ["spell_require"] = self.ParseSpellRequire,
            ["string"] = self.ParseString,
            ["unless"] = self.ParseUnless,
            ["value"] = self.ParseNumber,
            ["variable"] = self.ParseVariable
        }
        self.debug = ovaleDebug:create("OvaleAST")
        self.profiler = ovaleProfiler:create("OvaleAST")
    end,
    print_r = function(self, node, indent, done, output)
        done = done or {}
        output = output or {}
        indent = indent or ""
        for key, value in kpairs(node) do
            if isAstNode(value) then
                if done[value.nodeId] then
                    insert(output, indent .. "[" .. tostring(key) .. "] => (self_reference)")
                else
                    done[value.nodeId] = true
                    if value.type then
                        insert(output, indent .. "[" .. tostring(key) .. "] =>")
                    else
                        insert(output, indent .. "[" .. tostring(key) .. "] => {")
                    end
                    self:print_r(value, indent .. "    ", done, output)
                    if  not value.type then
                        insert(output, indent .. "}")
                    end
                end
            else
                insert(output, indent .. "[" .. tostring(key) .. "] => " .. tostring(value))
            end
        end
        return output
    end,
    GetNumberNode = function(self, value, nodeList, annotation)
        annotation.numberFlyweight = annotation.numberFlyweight or {}
        local node = annotation.numberFlyweight[value]
        if  not node then
            node = self:NewNode(nodeList)
            node.type = "value"
            node.value = value
            node.origin = 0
            node.rate = 0
            annotation.numberFlyweight[value] = node
        end
        return node
    end,
    PostOrderTraversal = function(self, node, array, visited)
        if node.child then
            for _, childNode in ipairs(node.child) do
                if  not visited[childNode.nodeId] then
                    self:PostOrderTraversal(childNode, array, visited)
                    array[#array + 1] = node
                end
            end
        end
        array[#array + 1] = node
        visited[node.nodeId] = true
    end,
    FlattenParameterValueNotCsv = function(self, parameterValue, annotation)
        if isAstNode(parameterValue) then
            local node = parameterValue
            local isBang = false
            local value
            if node.type == "bang_value" then
                isBang = true
                node = node.child[1]
            end
            if __exports.isNodeType(node, "value") then
                value = node.value
            elseif node.type == "variable" then
                value = node.name
            elseif __exports.isNodeType(node, "string") then
                value = node.value
            else
                return parameterValue
            end
            if isBang then
                value = "!" .. tostring(value)
            end
            return value
        end
        return parameterValue
    end,
    FlattenParameterValue = function(self, parameterValue, annotation)
        if isAstNode(parameterValue) and isCsvNode(parameterValue) then
            local parameters = self.flattenParametersPool:Get()
            for k, v in ipairs(parameterValue.csv) do
                parameters[k] = self:FlattenParameterValueNotCsv(v, annotation)
            end
            annotation.flattenParametersList = annotation.flattenParametersList or {}
            annotation.flattenParametersList[#annotation.flattenParametersList + 1] = parameters
            return parameters
        else
            return self:FlattenParameterValueNotCsv(parameterValue, annotation)
        end
    end,
    GetPrecedence = function(self, node)
        local precedence = node.precedence
        if  not precedence then
            local operator = node.operator
            if operator then
                if node.expressionType == "unary" then
                    local operatorInfos = UNARY_OPERATOR[operator]
                    if operatorInfos then
                        precedence = operatorInfos[2]
                    end
                elseif node.expressionType == "binary" then
                    local operatorInfos = BINARY_OPERATOR[operator]
                    if operatorInfos then
                        precedence = operatorInfos[2]
                    end
                end
            end
        end
        return precedence
    end,
    HasParameters = function(self, node)
        return ((node.rawPositionalParams and next(node.rawPositionalParams)) or (node.rawNamedParams and next(node.rawNamedParams)))
    end,
    Unparse = function(self, node)
        if node.asString then
            return node.asString
        else
            local visitor
            if node.previousType then
                visitor = self.UNPARSE_VISITOR[node.previousType]
            else
                visitor = self.UNPARSE_VISITOR[node.type]
            end
            if  not visitor then
                self.debug:Error("Unable to unparse node of type '%s'.", node.type)
                return "Unkown_" .. node.type
            else
                node.asString = visitor(node)
                return node.asString
            end
        end
    end,
    UnparseParameters = function(self, positionalParams, namedParams)
        local output = self.outputPool:Get()
        for k, v in kpairs(namedParams) do
            if isListItemParameter(k, v) then
                for list, item in pairs(v) do
                    output[#output + 1] = format("listitem=%s:%s", list, self:Unparse(item))
                end
            elseif isCheckBoxParameter(k, v) then
                for _, name in ipairs(v) do
                    output[#output + 1] = format("checkbox=%s", self:Unparse(name))
                end
            elseif isAstNode(v) then
                output[#output + 1] = format("%s=%s", k, self:Unparse(v))
            elseif k == "filter" or k == "target" then
            else
                output[#output + 1] = format("%s=%s", k, v)
            end
        end
        sort(output)
        for k = #positionalParams, 1, -1 do
            insert(output, 1, self:Unparse(positionalParams[k]))
        end
        local outputString = concat(output, " ")
        self.outputPool:Release(output)
        return outputString
    end,
    SyntaxError = function(self, tokenStream, ...)
        self.debug:Warning(...)
        local context = {
            [1] = "Next tokens:"
        }
        for i = 1, 20, 1 do
            local tokenType, token = tokenStream:Peek(i)
            if tokenType and token then
                context[#context + 1] = token
            else
                context[#context + 1] = "<EOS>"
                break
            end
        end
        self.debug:Warning(concat(context, " "))
    end,
    Parse = function(self, nodeType, tokenStream, nodeList, annotation)
        local visitor = self.PARSE_VISITOR[nodeType]
        if  not visitor then
            self.debug:Error("Unable to parse node of type '%s'.", nodeType)
            return nil
        else
            return visitor(tokenStream, nodeList, annotation)
        end
    end,
    ParseParameters = function(self, tokenStream, nodeList, annotation, isList)
        local positionalParams = self.rawPositionalParametersPool:Get()
        local namedParams = self.rawNamedParametersPool:Get()
        while true do
            local tokenType, token = tokenStream:Peek()
            if tokenType then
                local name
                local node
                if tokenType == "name" then
                    node = self.ParseVariable(tokenStream, nodeList, annotation)
                    if node then
                        name = node.name
                    else
                        return 
                    end
                elseif tokenType == "number" then
                    node = self.ParseNumber(tokenStream, nodeList, annotation)
                    if node then
                        name = tostring(node.value)
                    else
                        return 
                    end
                elseif tokenType == "-" then
                    tokenStream:Consume()
                    node = self.ParseNumber(tokenStream, nodeList, annotation)
                    if node then
                        local value = -1 * node.value
                        node = self:GetNumberNode(value, nodeList, annotation)
                        name = tostring(value)
                    else
                        return 
                    end
                elseif tokenType == "string" then
                    node = self.ParseString(tokenStream, nodeList, annotation)
                    if node and __exports.isNodeType(node, "string") then
                        name = node.value
                    else
                        return 
                    end
                elseif checkToken(__exports.PARAMETER_KEYWORD, token) then
                    if isList then
                        self:SyntaxError(tokenStream, "Syntax error: unexpected keyword '%s' when parsing PARAMETERS; simple expression expected.", token)
                        return 
                    else
                        tokenStream:Consume()
                        name = token
                    end
                else
                    break
                end
                if name then
                    tokenType, token = tokenStream:Peek()
                    if tokenType == "=" then
                        tokenStream:Consume()
                        local parameterName = name
                        if parameterName == "listitem" then
                            local np = namedParams[parameterName]
                            local control = np or self.listPool:Get()
                            tokenType, token = tokenStream:Consume()
                            local list
                            if tokenType == "name" and token then
                                list = token
                            else
                                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARAMETERS; name expected.", token)
                                return 
                            end
                            tokenType, token = tokenStream:Consume()
                            if tokenType ~= ":" then
                                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARAMETERS; ':' expected.", token)
                                return 
                            end
                            node = self.ParseSimpleParameterValue(tokenStream, nodeList, annotation)
                            if  not node then
                                return 
                            end
                            if  not (node.type == "variable" or (node.type == "bang_value" and node.child[1].type == "variable")) then
                                self:SyntaxError(tokenStream, "Syntax error: 'listitem=%s' parameter with unexpected value '%s'.", self:Unparse(node))
                                return 
                            end
                            control[list] = node
                            if  not namedParams[parameterName] then
                                namedParams[parameterName] = control
                                annotation.listList = annotation.listList or {}
                                annotation.listList[#annotation.listList + 1] = control
                            end
                        elseif name == "checkbox" then
                            local np = namedParams[name]
                            local control = np or self.checkboxPool:Get()
                            node = self.ParseSimpleParameterValue(tokenStream, nodeList, annotation)
                            if  not node then
                                return 
                            end
                            if  not (node.type == "variable" or (node.type == "bang_value" and node.child[1].type == "variable")) then
                                self:SyntaxError(tokenStream, "Syntax error: 'checkbox' parameter with unexpected value '%s'.", self:Unparse(node))
                                return 
                            end
                            control[#control + 1] = node
                            if  not namedParams[name] then
                                namedParams[name] = control
                                annotation.checkBoxList = annotation.checkBoxList or {}
                                annotation.checkBoxList[#annotation.checkBoxList + 1] = control
                            end
                        else
                            node = self.ParseParameterValue(tokenStream, nodeList, annotation)
                            if  not node then
                                return 
                            end
                            namedParams[parameterName] = node
                        end
                    else
                        if  not node then
                            return 
                        end
                        positionalParams[#positionalParams + 1] = node
                    end
                end
            else
                break
            end
        end
        annotation.rawPositionalParametersList = annotation.rawPositionalParametersList or {}
        annotation.rawPositionalParametersList[#annotation.rawPositionalParametersList + 1] = positionalParams
        annotation.rawNamedParametersList = annotation.rawNamedParametersList or {}
        annotation.rawNamedParametersList[#annotation.rawNamedParametersList + 1] = namedParams
        return positionalParams, namedParams
    end,
    ParseParentheses = function(self, tokenStream, nodeList, annotation)
        local leftToken, rightToken
        do
            local tokenType, token = tokenStream:Consume()
            if tokenType == "(" then
                leftToken, rightToken = "(", ")"
            elseif tokenType == "{" then
                leftToken, rightToken = "{", "}"
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '(' or '{' expected.", token)
                return nil
            end
        end
        local node = self.ParseExpression(tokenStream, nodeList, annotation)
        if  not node then
            return nil
        end
        local tokenType, token = tokenStream:Consume()
        if tokenType ~= rightToken then
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '%s' expected.", token, rightToken)
            return nil
        end
        node.left = leftToken
        node.right = rightToken
        return node
    end,
    ParseSimpleExpression = function(self, tokenStream, nodeList, annotation)
        local node
        local tokenType, token = tokenStream:Peek()
        if tokenType == "number" then
            node = self.ParseNumber(tokenStream, nodeList, annotation)
        elseif tokenType == "string" then
            node = self.ParseString(tokenStream, nodeList, annotation)
        elseif tokenType == "name" or tokenType == "keyword" then
            tokenType, token = tokenStream:Peek(2)
            if tokenType == "." or tokenType == "(" then
                node = self.ParseFunction(tokenStream, nodeList, annotation)
            else
                node = self.ParseVariable(tokenStream, nodeList, annotation)
            end
        elseif tokenType == "(" or tokenType == "{" then
            node = self:ParseParentheses(tokenStream, nodeList, annotation)
        else
            tokenStream:Consume()
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION", token)
            return nil
        end
        return node
    end,
    ParseStatement = function(self, tokenStream, nodeList, annotation)
        local node
        local tokenType, token = tokenStream:Peek()
        if tokenType then
            if token == "{" then
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
                        node = self.ParseExpression(tokenStream, nodeList, annotation)
                    else
                        node = self.ParseGroup(tokenStream, nodeList, annotation)
                    end
                else
                    self:SyntaxError(tokenStream, "Syntax error: unexpected end of script.")
                end
            elseif token == "if" then
                node = self.ParseIf(tokenStream, nodeList, annotation)
            elseif token == "unless" then
                node = self.ParseUnless(tokenStream, nodeList, annotation)
            else
                node = self.ParseExpression(tokenStream, nodeList, annotation)
            end
        end
        return node
    end,
    newFunction = function(self, nodeList, name, hasParameters)
        local node = self:NewNode(nodeList)
        node.type = "function"
        node.name = name
        if hasParameters then
            node.rawNamedParams = self.rawNamedParametersPool:Get()
            node.rawPositionalParams = self.rawPositionalParametersPool:Get()
        end
        return node
    end,
    newString = function(self, nodeList, value)
        local node = self:NewNode(nodeList)
        node.type = "string"
        node.value = value
        return node
    end,
    NewNode = function(self, nodeList, hasChild)
        local node = self.nodesPool:Get()
        if nodeList then
            local nodeId = #nodeList + 1
            node.nodeId = nodeId
            nodeList[nodeId] = node
        end
        if hasChild then
            node.child = self.childrenPool:Get()
        end
        return node
    end,
    NodeToString = function(self, node)
        local output = self:print_r(node)
        return concat(output, "\n")
    end,
    ReleaseAnnotation = function(self, annotation)
        if annotation.checkBoxList then
            for _, control in ipairs(annotation.checkBoxList) do
                self.checkboxPool:Release(control)
            end
        end
        if annotation.listList then
            for _, control in ipairs(annotation.listList) do
                self.listPool:Release(control)
            end
        end
        if annotation.objects then
            for _, parameters in ipairs(annotation.objects) do
                self.objectPool:Release(parameters)
            end
        end
        if annotation.rawPositionalParametersList then
            for _, parameters in ipairs(annotation.rawPositionalParametersList) do
                self.rawPositionalParametersPool:Release(parameters)
            end
        end
        if annotation.rawNamedParametersList then
            for _, parameters in ipairs(annotation.rawNamedParametersList) do
                self.rawNamedParametersPool:Release(parameters)
            end
        end
        if annotation.nodeList then
            for _, node in ipairs(annotation.nodeList) do
                self.nodesPool:Release(node)
            end
        end
        for _, value in kpairs(annotation) do
            if type(value) == "table" then
                wipe(value)
            end
        end
        wipe(annotation)
    end,
    Release = function(self, ast)
        if ast.annotation then
            self:ReleaseAnnotation(ast.annotation)
            ast.annotation = nil
        end
        self.nodesPool:Release(ast)
    end,
    ParseCode = function(self, nodeType, code, nodeList, annotation)
        nodeList = nodeList or {}
        annotation = annotation or {}
        local tokenStream = OvaleLexer("Ovale", code, MATCHES, {
            comments = TokenizeComment,
            space = TokenizeWhitespace
        })
        local node = self:Parse(nodeType, tokenStream, nodeList, annotation)
        tokenStream:Release()
        if  not node then
            return 
        end
        return node, nodeList, annotation
    end,
    parseScript = function(self, code, options)
        options = options or {
            optimize = true,
            verify = true
        }
        local annotation = {
            nodeList = {},
            verify = options.verify,
            definition = {}
        }
        local ast = self:ParseCode("script", code, annotation.nodeList, annotation)
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
            self:ReleaseAnnotation(annotation)
        end
        return ast
    end,
    parseNamedScript = function(self, name, options)
        local code = self.ovaleScripts:GetScriptOrDefault(name)
        if code then
            return self:parseScript(code, options)
        else
            self.debug:Debug("No code to parse")
            return nil
        end
    end,
    PropagateConstants = function(self, ast)
        self.profiler:StartProfiling("OvaleAST_PropagateConstants")
        if ast.annotation then
            local dictionary = ast.annotation.definition
            if dictionary and ast.annotation.nameReference then
                for _, node in ipairs(ast.annotation.nameReference) do
                    local valueNode = node
                    if (node.type == "item_info" or node.type == "itemrequire") and node.name then
                        local itemId = dictionary[node.name]
                        if itemId then
                            node.itemId = itemId
                        end
                    elseif (node.type == "spell_aura_list" or node.type == "spell_info" or node.type == "spell_require") and node.name then
                        local spellId = dictionary[node.name]
                        if spellId then
                            node.spellId = spellId
                        end
                    elseif isVariableNode(node) then
                        local name = node.name
                        local value = dictionary[name]
                        if value then
                            valueNode.previousType = "variable"
                            valueNode.type = "value"
                            valueNode.value = value
                            valueNode.origin = 0
                            valueNode.rate = 0
                        end
                    end
                end
            end
        end
        self.profiler:StopProfiling("OvaleAST_PropagateConstants")
    end,
    PropagateStrings = function(self, ast)
        self.profiler:StartProfiling("OvaleAST_PropagateStrings")
        if ast.annotation and ast.annotation.stringReference then
            for _, node in ipairs(ast.annotation.stringReference) do
                local targetNode = node
                if __exports.isNodeType(node, "string") then
                    local key = node.value
                    local value = L[key]
                    if key ~= value then
                        targetNode.value = value
                        targetNode.key = key
                    end
                elseif isVariableNode(node) then
                    local value = node.name
                    targetNode.previousType = node.type
                    targetNode.type = "string"
                    targetNode.value = value
                elseif __exports.isNodeType(node, "value") then
                    local value = node.value
                    targetNode.previousType = "value"
                    targetNode.type = "string"
                    targetNode.value = tostring(value)
                elseif node.type == "function" then
                    local key = node.rawPositionalParams[1]
                    local stringKey
                    if isAstNode(key) then
                        if __exports.isNodeType(key, "value") then
                            stringKey = tostring(key.value)
                        elseif isVariableNode(key) then
                            stringKey = key.name
                        elseif __exports.isNodeType(key, "string") then
                            stringKey = key.value
                        else
                            stringKey = nil
                        end
                    else
                        stringKey = tostring(key)
                    end
                    if stringKey then
                        local value
                        local name = node.name
                        if name == "itemname" then
                            value = GetItemInfo(stringKey)
                            if  not value then
                                value = "item:" .. stringKey
                            end
                        elseif name == "l" then
                            value = L[stringKey]
                        elseif name == "spellname" then
                            value = self.ovaleSpellBook:GetSpellName(tonumber(stringKey)) or "spell:" .. stringKey
                        end
                        if value then
                            targetNode.previousType = "function"
                            targetNode.type = "string"
                            targetNode.value = value
                            targetNode.key = stringKey
                        end
                    end
                end
            end
        end
        self.profiler:StopProfiling("OvaleAST_PropagateStrings")
    end,
    FlattenParameters = function(self, ast)
        self.profiler:StartProfiling("OvaleAST_FlattenParameters")
        local annotation = ast.annotation
        if annotation and annotation.parametersReference then
            local dictionary = annotation.definition
            for _, node in ipairs(annotation.parametersReference) do
                if node.rawPositionalParams then
                    local parameters = self.flattenParameterValuesPool:Get()
                    for key, value in ipairs(node.rawPositionalParams) do
                        parameters[key] = self:FlattenParameterValue(value, annotation)
                    end
                    node.positionalParams = parameters
                    annotation.positionalParametersList = annotation.positionalParametersList or {}
                    annotation.positionalParametersList[#annotation.positionalParametersList + 1] = parameters
                end
                if node.rawNamedParams then
                    local parameters = self.objectPool:Get()
                    for key in kpairs(node.rawNamedParams) do
                        if key == "listitem" then
                            local control = parameters[key] or self.objectPool:Get()
                            local listItems = node.rawNamedParams[key]
                            for list, item in pairs(listItems) do
                                control[list] = self:FlattenParameterValueNotCsv(item, annotation)
                            end
                            if  not parameters[key] then
                                parameters[key] = control
                                annotation.objects = annotation.objects or {}
                                annotation.objects[#annotation.objects + 1] = control
                            end
                        elseif key == "checkbox" then
                            local control = parameters[key] or self.objectPool:Get()
                            local checkBoxItems = node.rawNamedParams[key]
                            for i, name in ipairs(checkBoxItems) do
                                control[i] = self:FlattenParameterValueNotCsv(name, annotation)
                            end
                            if  not parameters[key] then
                                parameters[key] = control
                                annotation.objects = annotation.objects or {}
                                annotation.objects[#annotation.objects + 1] = control
                            end
                        else
                            local value = node.rawNamedParams[key]
                            local flattenValue = self:FlattenParameterValue(value, annotation)
                            if type(key) ~= "number" and dictionary and dictionary[key] then
                                parameters[dictionary[key]] = flattenValue
                            else
                                parameters[key] = flattenValue
                            end
                        end
                    end
                    node.namedParams = parameters
                    annotation.parametersList = annotation.parametersList or {}
                    annotation.parametersList[#annotation.parametersList + 1] = parameters
                end
                local output = self.outputPool:Get()
                for k, v in kpairs(node.namedParams) do
                    if isCheckBoxFlattenParameters(k, v) then
                        for _, name in ipairs(v) do
                            output[#output + 1] = format("checkbox=%s", name)
                        end
                    elseif isListItemFlattenParameters(k, v) then
                        for list, item in ipairs(v) do
                            output[#output + 1] = format("listitem=%s:%s", list, item)
                        end
                    elseif isLuaArray(v) then
                        output[#output + 1] = format("%s=%s", k, concat(v, ","))
                    else
                        output[#output + 1] = format("%s=%s", k, v)
                    end
                end
                sort(output)
                for k = #node.positionalParams, 1, -1 do
                    insert(output, 1, node.positionalParams[k])
                end
                if #output > 0 then
                    node.paramsAsString = concat(output, " ")
                else
                    node.paramsAsString = ""
                end
                self.outputPool:Release(output)
            end
        end
        self.profiler:StopProfiling("OvaleAST_FlattenParameters")
    end,
    VerifyFunctionCalls = function(self, ast)
        self.profiler:StartProfiling("OvaleAST_VerifyFunctionCalls")
        if ast.annotation and ast.annotation.verify then
            local customFunction = ast.annotation.customFunction
            local functionCall = ast.annotation.functionCall
            if functionCall then
                for name in pairs(functionCall) do
                    if ACTION_PARAMETER_COUNT[name] then
                    elseif STRING_LOOKUP_FUNCTION[name] then
                    elseif self.ovaleCondition:IsCondition(name) then
                    elseif customFunction and customFunction[name] then
                    else
                        self.debug:Error("unknown function '%s'.", name)
                    end
                end
            end
        end
        self.profiler:StopProfiling("OvaleAST_VerifyFunctionCalls")
    end,
    VerifyParameterStances = function(self, ast)
        self.profiler:StartProfiling("OvaleAST_VerifyParameterStances")
        local annotation = ast.annotation
        if annotation and annotation.verify and annotation.parametersReference then
            for _, node in ipairs(annotation.parametersReference) do
                if node.rawNamedParams then
                    for stanceKeyword in kpairs(STANCE_KEYWORD) do
                        local valueNode = (node.rawNamedParams[stanceKeyword])
                        if valueNode then
                            if isCsvNode(valueNode) then
                                valueNode = valueNode.csv[1]
                            end
                            if valueNode.type == "bang_value" then
                                valueNode = valueNode.child[1]
                            end
                            local value = self:FlattenParameterValue(valueNode, annotation)
                            if  not isNumber(value) then
                                if  not isString(value) then
                                    self.debug:Error("stance must be a string or a number")
                                elseif  not checkToken(STANCE_NAME, value) then
                                    self.debug:Error("unknown stance '%s'.", value)
                                end
                            end
                        end
                    end
                end
            end
        end
        self.profiler:StopProfiling("OvaleAST_VerifyParameterStances")
    end,
    InsertPostOrderTraversal = function(self, ast)
        self.profiler:StartProfiling("OvaleAST_InsertPostOrderTraversal")
        local annotation = ast.annotation
        if annotation and annotation.postOrderReference then
            for _, node in ipairs(annotation.postOrderReference) do
                local array = self.postOrderPool:Get()
                local visited = self.postOrderVisitedPool:Get()
                self:PostOrderTraversal(node, array, visited)
                self.postOrderVisitedPool:Release(visited)
                node.postOrder = array
            end
        end
        self.profiler:StopProfiling("OvaleAST_InsertPostOrderTraversal")
    end,
    Optimize = function(self, ast)
        self.profiler:StartProfiling("OvaleAST_CommonSubExpressionElimination")
        if ast and ast.annotation and ast.annotation.nodeList then
            local expressionHash = {}
            for _, node in ipairs(ast.annotation.nodeList) do
                local hash = node.asString
                if hash then
                    expressionHash[hash] = expressionHash[hash] or node
                end
            end
            for _, node in ipairs(ast.annotation.nodeList) do
                if node.child then
                    for i, childNode in ipairs(node.child) do
                        local hash = childNode.asString
                        if hash then
                            local hashNode = expressionHash[hash]
                            if hashNode then
                                node.child[i] = hashNode
                            else
                                expressionHash[hash] = childNode
                            end
                        end
                    end
                end
            end
            ast.annotation.expressionHash = expressionHash
        end
        self.profiler:StopProfiling("OvaleAST_CommonSubExpressionElimination")
    end,
})
