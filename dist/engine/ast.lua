local __exports = LibStub:NewLibrary("ovale/engine/ast", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __uiLocalization = LibStub:GetLibrary("ovale/ui/Localization")
local L = __uiLocalization.L
local __toolsPool = LibStub:GetLibrary("ovale/tools/Pool")
local OvalePool = __toolsPool.OvalePool
local __condition = LibStub:GetLibrary("ovale/engine/condition")
local getFunctionSignature = __condition.getFunctionSignature
local __lexer = LibStub:GetLibrary("ovale/engine/lexer")
local OvaleLexer = __lexer.OvaleLexer
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
local __toolstools = LibStub:GetLibrary("ovale/tools/tools")
local checkToken = __toolstools.checkToken
local isNumber = __toolstools.isNumber
local __toolsTimeSpan = LibStub:GetLibrary("ovale/tools/TimeSpan")
local EMPTY_SET = __toolsTimeSpan.EMPTY_SET
local newTimeSpan = __toolsTimeSpan.newTimeSpan
local UNIVERSE = __toolsTimeSpan.UNIVERSE
local KEYWORD = {
    ["and"] = true,
    ["if"] = true,
    ["not"] = true,
    ["or"] = true,
    ["unless"] = true,
    ["true"] = true,
    ["false"] = true
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
__exports.checkSpellInfo = {
    add_cd = true,
    add_duration = true,
    add_duration_combopoints = true,
    alternate = true,
    arcanecharges = true,
    base = true,
    bonusap = true,
    bonusapcp = true,
    bonuscp = true,
    bonusmainhand = true,
    bonusoffhand = true,
    bonussp = true,
    buff_cd = true,
    buff_cdr = true,
    buff_totem = true,
    canStopChannelling = true,
    casttime = true,
    cd = true,
    cd_haste = true,
    channel = true,
    charge_cd = true,
    chi = true,
    combopoints = true,
    damage = true,
    duration = true,
    effect = true,
    energy = true,
    focus = true,
    forcecd = true,
    fury = true,
    gcd = true,
    gcd_haste = true,
    haste = true,
    health = true,
    holypower = true,
    inccounter = true,
    insanity = true,
    interrupt = true,
    lunarpower = true,
    maelstrom = true,
    mana = true,
    max_stacks = true,
    max_totems = true,
    max_travel_time = true,
    offgcd = true,
    pain = true,
    physical = true,
    rage = true,
    replaced_by = true,
    resetcounter = true,
    runes = true,
    runicpower = true,
    shared_cd = true,
    soulshards = true,
    stacking = true,
    tag = true,
    texture = true,
    tick = true,
    to_stance = true,
    totem = true,
    travel_time = true,
    unusable = true,
    addlist = true,
    dummy_replace = true,
    learn = true,
    pertrait = true,
    proc = true
}
do
    for keyword, value in pairs(SPELL_AURA_KEYWORD) do
        DECLARATION_KEYWORD[keyword] = value
    end
    for keyword, value in pairs(DECLARATION_KEYWORD) do
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
__exports.setResultType = function(result, type)
    result.type = type
end
__exports.isAstNodeWithChildren = function(node)
    return node.child ~= nil
end
local checkCheckBoxParameters = {
    enabled = true
}
local spellAuraListParametersCheck = {
    enabled = true,
    add = true,
    set = true,
    extend = true,
    refresh = true,
    refresh_keep_snapshot = true,
    toggle = true
}
local checkSpellRequireParameters = {
    add = true,
    percent = true,
    set = true,
    enabled = true
}
local checkAddFunctionParameters = {
    help = true
}
local checkListParameters = {
    enabled = true
}
local iconParametersCheck = {
    secure = true,
    enemies = true,
    target = true,
    size = true,
    type = true,
    help = true,
    text = true,
    flash = true,
    enabled = true
}
local checkListItemParameters = {
    enabled = true
}
local function isExpressionNode(node)
    return (node.type == "logical" or node.type == "arithmetic" or node.type == "compare" or node.type == "expression")
end
local checkFunctionParameters = {
    filter = true,
    target = true,
    text = true,
    pool_resource = true,
    usable = true,
    offgcd = true,
    texture = true,
    extra_amount = true,
    help = true,
    count = true,
    any = true,
    max = true,
    tagged = true
}
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
        if __exports.isAstNodeWithChildren(node) then
            self.ovaleAst.childrenPool:Release(node.child)
        end
        if node.postOrder then
            self.ovaleAst.postOrderPool:Release(node.postOrder)
        end
        wipe(node)
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
        self.positionalParametersPool = OvalePool("OvaleAST_FlattenParameterValues")
        self.rawNamedParametersPool = OvalePool("OvaleAST_rawNamedParametersPool")
        self.rawPositionalParametersPool = OvalePool("OVALEAST_rawPositionParametersPool")
        self.namedParametersPool = OvalePool("OvaleAST_FlattenParametersPool")
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
                s = format("AddFunction %s %s%s", node.name, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams), self.UnparseGroup(node.body))
            else
                s = format("AddFunction %s%s", node.name, self.UnparseGroup(node.body))
            end
            return s
        end
        self.UnparseAddIcon = function(node)
            local s
            if self:HasParameters(node) then
                s = format("AddIcon %s%s", self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams), self.UnparseGroup(node.body))
            else
                s = format("AddIcon%s", self.UnparseGroup(node.body))
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
        self.unparseBoolean = function(node)
            return (node.value and "true") or "false"
        end
        self.UnparseComment = function(node)
            if  not node.comment or node.comment == "" then
                return ""
            else
                return "#" .. node.comment
            end
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
                    if operatorInfo and operatorInfo[3] == "associative" and rhsNode.type == "expression" and node.operator == rhsNode.operator then
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
                if filter and self:Unparse(filter) == "debuff" then
                    name = gsub(node.name, "^Buff", "Debuff")
                else
                    name = node.name
                end
                local target = node.rawNamedParams.target
                if target and target.type == "string" then
                    s = format("%s.%s(%s)", target.value, name, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams, true, true))
                else
                    s = format("%s(%s)", name, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams, true))
                end
            else
                s = format("%s()", node.name)
            end
            return s
        end
        self.unparseUndefined = function()
            return "undefined"
        end
        self.unparseTypedFunction = function(node)
            local s
            if self:HasParameters(node) then
                s = node.name .. "("
                if node.rawNamedParams.target and node.rawNamedParams.target.type == "string" then
                    s = node.rawNamedParams.target.value .. "." .. s
                end
                local infos = self.ovaleCondition:getInfos(node.name)
                if infos then
                    local nameParameters = false
                    local first = true
                    for k, v in ipairs(infos.parameters) do
                        local value = node.rawPositionalParams[k]
                        if value and value.type ~= "undefined" then
                            if v.name == "filter" or v.name == "target" or (v.defaultValue ~= nil and ((v.type == "boolean" and value.type == "boolean" and value.value == v.defaultValue) or (v.type == "number" and value.type == "value" and value.value == v.defaultValue) or (v.type == "string" and value.type == "string" and value.value == v.defaultValue))) then
                                nameParameters = true
                            else
                                if first then
                                    first = false
                                else
                                    s = s .. " "
                                end
                                if nameParameters then
                                    s = s .. (v.name .. "=")
                                end
                                s = s .. self:unparseParameter(value)
                            end
                        else
                            nameParameters = true
                        end
                    end
                end
                s = s .. ")"
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
            if node.name then
                return node.name
            end
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
            local identifier = node.name or node.spellId
            local buffName = node.buffName or node.buffSpellId
            return format("%s(%s %s %s)", node.keyword, identifier, buffName, self:UnparseParameters(node.rawPositionalParams, node.rawNamedParams))
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
            if node.name then
                if node.func then
                    return node.func .. "(" .. node.name .. ")"
                end
                return node.name
            end
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
            ["boolean"] = self.unparseBoolean,
            ["checkbox"] = self.UnparseAddCheckBox,
            ["compare"] = self.UnparseExpression,
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
            ["typed_function"] = self.unparseTypedFunction,
            ["undefined"] = self.unparseUndefined,
            ["unless"] = self.UnparseUnless,
            ["value"] = self.UnparseValue,
            ["variable"] = self.UnparseVariable
        }
        self.ParseAddCheckBox = function(tokenStream, annotation)
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
            local descriptionNode = self.ParseString(tokenStream, annotation)
            if  not descriptionNode then
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, "ParseAddCheckBox", annotation, 1, checkCheckBoxParameters)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; ')' expected.", token)
                return nil
            end
            local node = self:newNodeWithParameters("checkbox", annotation, positionalParams, namedParams)
            node.name = name
            node.description = descriptionNode
            return node
        end
        self.ParseAddFunction = function(tokenStream, annotation)
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
            local positionalParams, namedParams = self:ParseParameters(tokenStream, "ParseAddFunction", annotation, 0, checkAddFunctionParameters)
            if  not positionalParams or  not namedParams then
                return nil
            end
            local bodyNode = self.ParseGroup(tokenStream, annotation)
            if  not bodyNode then
                return nil
            end
            local node = self:newNodeWithBodyAndParameters("add_function", annotation, bodyNode, positionalParams, namedParams)
            node.name = name
            annotation.parametersReference = annotation.parametersReference or {}
            annotation.parametersReference[#annotation.parametersReference + 1] = node
            annotation.postOrderReference = annotation.postOrderReference or {}
            annotation.postOrderReference[#annotation.postOrderReference + 1] = bodyNode
            annotation.customFunction = annotation.customFunction or {}
            annotation.customFunction[name] = node
            return node
        end
        self.ParseAddIcon = function(tokenStream, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "addicon") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDICON; 'AddIcon' expected.", token)
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, "addicon", annotation, 0, iconParametersCheck)
            if  not positionalParams or  not namedParams then
                return nil
            end
            local bodyNode = self.ParseGroup(tokenStream, annotation)
            if  not bodyNode then
                return nil
            end
            local node = self:newNodeWithBodyAndParameters("icon", annotation, bodyNode, positionalParams, namedParams)
            annotation.postOrderReference = annotation.postOrderReference or {}
            annotation.postOrderReference[#annotation.postOrderReference + 1] = bodyNode
            return node
        end
        self.ParseAddListItem = function(tokenStream, annotation)
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
            local descriptionNode = self.ParseString(tokenStream, annotation)
            if  not descriptionNode then
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, "ParseAddListItem", annotation, 0, checkListItemParameters)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; ')' expected.", token)
                return nil
            end
            local node = self:newNodeWithParameters("list_item", annotation, positionalParams, namedParams)
            node.name = name
            node.item = item
            node.description = descriptionNode
            return node
        end
        self.ParseComment = function()
            return nil
        end
        self.ParseDeclaration = function(tokenStream, annotation)
            local node
            local tokenType, token = tokenStream:Peek()
            if tokenType == "keyword" and token and DECLARATION_KEYWORD[token] then
                if token == "addcheckbox" then
                    node = self.ParseAddCheckBox(tokenStream, annotation)
                elseif token == "addfunction" then
                    node = self.ParseAddFunction(tokenStream, annotation)
                elseif token == "addicon" then
                    node = self.ParseAddIcon(tokenStream, annotation)
                elseif token == "addlistitem" then
                    node = self.ParseAddListItem(tokenStream, annotation)
                elseif token == "define" then
                    node = self.ParseDefine(tokenStream, annotation)
                elseif token == "include" then
                    node = self.ParseInclude(tokenStream, annotation)
                elseif token == "iteminfo" then
                    node = self.ParseItemInfo(tokenStream, annotation)
                elseif token == "itemrequire" then
                    node = self.ParseItemRequire(tokenStream, annotation)
                elseif token == "itemlist" then
                    node = self.ParseList(tokenStream, annotation)
                elseif token == "scorespells" then
                    node = self.ParseScoreSpells(tokenStream, annotation)
                elseif checkToken(SPELL_AURA_KEYWORD, token) then
                    node = self.ParseSpellAuraList(tokenStream, annotation)
                elseif token == "spellinfo" then
                    node = self.ParseSpellInfo(tokenStream, annotation)
                elseif token == "spelllist" then
                    node = self.ParseList(tokenStream, annotation)
                elseif token == "spellrequire" then
                    node = self.ParseSpellRequire(tokenStream, annotation)
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
        self.ParseDefine = function(tokenStream, annotation)
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
            local node = self:NewNode("define", annotation)
            node.name = name
            node.value = value
            annotation.definition = annotation.definition or {}
            annotation.definition[name] = value
            return node
        end
        self.ParseExpression = function(tokenStream, annotation, minPrecedence)
            minPrecedence = minPrecedence or 0
            local node
            local tokenType, token = tokenStream:Peek()
            if tokenType then
                local opInfo = UNARY_OPERATOR[token]
                if opInfo then
                    local opType, precedence = opInfo[1], opInfo[2]
                    tokenStream:Consume()
                    local operator = token
                    local rhsNode = self.ParseExpression(tokenStream, annotation, precedence)
                    if rhsNode then
                        if operator == "-" and rhsNode.type == "value" then
                            local value = -1 * tonumber(rhsNode.value)
                            node = self:GetNumberNode(value, annotation)
                        else
                            node = self:newNodeWithChildren(opType, annotation)
                            node.expressionType = "unary"
                            node.operator = operator
                            node.precedence = precedence
                            node.child[1] = rhsNode
                        end
                    else
                        return nil
                    end
                elseif token == "{" then
                    local expression = self:parseGroup(tokenStream, annotation)
                    if  not expression then
                        return nil
                    end
                    node = expression
                else
                    local simpleExpression = self:ParseSimpleExpression(tokenStream, annotation)
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
                            local rhsNode = self.ParseExpression(tokenStream, annotation, precedence)
                            if rhsNode then
                                node = self:newNodeWithChildren(opType, annotation)
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
        self.ParseFunction = function(tokenStream, annotation)
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
            if  not target then
                if sub(name, 1, 6) == "target" then
                    target = "target"
                    name = sub(name, 7)
                end
            end
            local filter
            if sub(name, 1, 6) == "debuff" then
                filter = "debuff"
            elseif sub(name, 1, 4) == "buff" then
                filter = "buff"
            elseif sub(name, 1, 11) == "otherdebuff" then
                filter = "debuff"
            elseif sub(name, 1, 9) == "otherbuff" then
                filter = "buff"
            end
            local infos = self.ovaleCondition:getInfos(name)
            if infos then
                return self:parseTypedFunction(tokenStream, annotation, name, target, filter, infos)
            end
            if  not self:parseToken(tokenStream, "FUNCTION", "(") then
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, "function", annotation, nil, checkFunctionParameters)
            if  not positionalParams or  not namedParams then
                return nil
            end
            if  not self:parseToken(tokenStream, "FUNCTION", ")") then
                return nil
            end
            if target then
                namedParams.target = self:newString(annotation, target)
            end
            if filter then
                namedParams.filter = self:newString(annotation, filter)
            end
            local nodeType
            if STATE_ACTION[name] then
                nodeType = "state"
            elseif ACTION_PARAMETER_COUNT[name] then
                local count = ACTION_PARAMETER_COUNT[name]
                if count > #positionalParams then
                    self:SyntaxError(tokenStream, "Syntax error: action '%s' requires at least %d fixed parameter(s).", name, count)
                    return nil
                end
                nodeType = "action"
            elseif STRING_LOOKUP_FUNCTION[name] then
                nodeType = "function"
            elseif self.ovaleCondition:IsCondition(name) then
                nodeType = "function"
            else
                nodeType = "custom_function"
            end
            local node = self:newNodeWithParameters(nodeType, annotation, positionalParams, namedParams)
            node.name = name
            if STRING_LOOKUP_FUNCTION[name] then
                annotation.stringReference = annotation.stringReference or {}
                annotation.stringReference[#annotation.stringReference + 1] = node
            end
            node.asString = self.UnparseFunction(node)
            if nodeType == "custom_function" then
                annotation.functionCall = annotation.functionCall or {}
                annotation.functionCall[node.name] = true
            end
            if nodeType == "function" and self.ovaleCondition:IsSpellBookCondition(name) then
                local parameter = positionalParams[1]
                if  not parameter then
                    self:SyntaxError(tokenStream, "Type error: %s function expect a spell id parameter", name)
                end
                annotation.spellNode = annotation.spellNode or {}
                annotation.spellNode[#annotation.spellNode + 1] = parameter
            end
            return node
        end
        self.ParseGroup = function(tokenStream, annotation)
            local tokenType, token = tokenStream:Consume()
            if tokenType ~= "{" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '{' expected.", token)
                return nil
            end
            local node = self:newNodeWithChildren("group", annotation)
            local child = node.child
            tokenType = tokenStream:Peek()
            while tokenType and tokenType ~= "}" do
                local statementNode = self.ParseStatement(tokenStream, annotation)
                if statementNode then
                    child[#child + 1] = statementNode
                    tokenType = tokenStream:Peek()
                else
                    self.nodesPool:Release(node)
                    return nil
                end
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= "}" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '}' expected.", token)
                self.nodesPool:Release(node)
                return nil
            end
            return node
        end
        self.ParseIf = function(tokenStream, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "if") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing IF; 'if' expected.", token)
                return nil
            end
            local conditionNode = self.ParseStatement(tokenStream, annotation)
            if  not conditionNode then
                return nil
            end
            local bodyNode = self.ParseStatement(tokenStream, annotation)
            if  not bodyNode then
                return nil
            end
            local node = self:newNodeWithChildren("if", annotation)
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
            local includeTokenStream = OvaleLexer(name, code, MATCHES, FILTERS)
            local node = self.ParseScriptStream(includeTokenStream, nodeList, annotation)
            includeTokenStream:Release()
            return node
        end
        self.ParseItemInfo = function(tokenStream, annotation)
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
            local positionalParams, namedParams = self:ParseParameters(tokenStream, "iteminfo", annotation, nil, __exports.checkSpellInfo)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; ')' expected.", token)
                return nil
            end
            local node = self:newNodeWithParameters("item_info", annotation, positionalParams, namedParams)
            node.itemId = tonumber(itemId)
            if name then
                node.name = name
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
            return node
        end
        self.ParseItemRequire = function(tokenStream, annotation)
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
            local property = self:parseCheckedNameToken(tokenStream, "ITEMREQUIRE", __exports.checkSpellInfo)
            if  not property then
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, "itemrequire", annotation, 0, checkSpellRequireParameters)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; ')' expected.", token)
                return nil
            end
            local node = self:newNodeWithParameters("itemrequire", annotation, positionalParams, namedParams)
            node.itemId = tonumber(itemId)
            if name then
                node.name = name
            end
            node.property = property
            if name then
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
            return node
        end
        self.ParseList = function(tokenStream, annotation)
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
            local positionalParams, namedParams = self:ParseParameters(tokenStream, "list", annotation, nil, checkListParameters)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; ')' expected.", token)
                return nil
            end
            local node = self:newNodeWithParameters("list", annotation, positionalParams, namedParams)
            node.keyword = keyword
            node.name = name
            annotation.definition[name] = name
            return node
        end
        self.ParseNumber = function(tokenStream, annotation)
            local value
            local tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                value = tonumber(token)
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing NUMBER; number expected.", token)
                return nil
            end
            local node = self:GetNumberNode(value, annotation)
            return node
        end
        self.ParseScoreSpells = function(tokenStream, annotation)
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
            local positionalParams, namedParams = self:ParseParameters(tokenStream, "scorespells", annotation, nil, checkListParameters)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; ')' expected.", token)
                return nil
            end
            local node = self:newNodeWithParameters("score_spells", annotation, positionalParams, namedParams)
            return node
        end
        self.ParseScriptStream = function(tokenStream, annotation)
            self.profiler:StartProfiling("OvaleAST_ParseScript")
            local ast = self:newNodeWithChildren("script", annotation)
            local child = ast.child
            while true do
                local tokenType, token = tokenStream:Peek()
                if tokenType then
                    local declarationNode = self.ParseDeclaration(tokenStream, annotation)
                    if  not declarationNode then
                        self.debug:Error("Failed on " .. token)
                        self.nodesPool:Release(ast)
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
            self.profiler:StopProfiling("OvaleAST_ParseScript")
            return ast
        end
        self.ParseSimpleParameterValue = function(tokenStream, annotation)
            local isBang = false
            local tokenType = tokenStream:Peek()
            if tokenType == "!" then
                isBang = true
                tokenStream:Consume()
            end
            local expressionNode
            tokenType = tokenStream:Peek()
            if tokenType == "(" or tokenType == "-" then
                expressionNode = self.ParseExpression(tokenStream, annotation)
            else
                expressionNode = self:ParseSimpleExpression(tokenStream, annotation)
            end
            if  not expressionNode then
                return nil
            end
            local node
            if isBang then
                node = self:newNodeWithChildren("bang_value", annotation)
                node.child[1] = expressionNode
            else
                node = expressionNode
            end
            return node
        end
        self.ParseSpellAuraList = function(tokenStream, annotation)
            local keyword = self:parseKeywordTokens(tokenStream, "SPELLAURALIST", SPELL_AURA_KEYWORD)
            if  not keyword then
                self.debug:Error("Failed on keyword")
                return nil
            end
            if  not self:parseToken(tokenStream, "SPELLAURALIST", "(") then
                self.debug:Error("Failed on (")
                return nil
            end
            local spellId, name = self:parseNumberOrNameParameter(tokenStream, "SPELLAURALIST")
            local buffSpellId, buffName = self:parseNumberOrNameParameter(tokenStream, "SPELLAURALIST")
            local positionalParams, namedParams = self:ParseParameters(tokenStream, "spellauralist", annotation, 0, spellAuraListParametersCheck)
            if  not positionalParams or  not namedParams then
                return nil
            end
            if  not self:parseToken(tokenStream, "SPELLAURALIST", ")") then
                self.debug:Error("Failed on )")
                return nil
            end
            local node = self:newNodeWithParameters("spell_aura_list", annotation, positionalParams, namedParams)
            node.keyword = keyword
            if spellId then
                node.spellId = spellId
            elseif name then
                node.name = name
            end
            if buffSpellId then
                node.buffSpellId = buffSpellId
            elseif buffName then
                node.buffName = buffName
            end
            if name or buffName then
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
            return node
        end
        self.ParseSpellInfo = function(tokenStream, annotation)
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
            local positionalParams, namedParams = self:ParseParameters(tokenStream, "spellinfo", annotation, 0, __exports.checkSpellInfo)
            if  not positionalParams or  not namedParams then
                return nil
            end
            tokenType, token = tokenStream:Consume()
            if tokenType ~= ")" then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; ')' expected.", token)
                return nil
            end
            local node = self:newNodeWithParameters("spell_info", annotation, positionalParams, namedParams)
            if spellId then
                node.spellId = spellId
            end
            if name then
                node.name = name
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
            return node
        end
        self.ParseSpellRequire = function(tokenStream, annotation)
            if self:parseKeywordToken(tokenStream, "SPELLREQUIRE", "spellrequire") == nil then
                return nil
            end
            if  not self:parseToken(tokenStream, "SPELLREQUIRE", "(") then
                return nil
            end
            local spellId, name = self:parseNumberOrNameParameter(tokenStream, "SPELLREQUIRE")
            if  not spellId and  not name then
                return nil
            end
            local property = self:parseCheckedNameToken(tokenStream, "SPELLREQUIRE", __exports.checkSpellInfo)
            if  not property then
                return nil
            end
            local positionalParams, namedParams = self:ParseParameters(tokenStream, "spellrequire", annotation, 0, checkSpellRequireParameters)
            if  not positionalParams or  not namedParams then
                return nil
            end
            if  not self:parseToken(tokenStream, "SPELLREQUIRE", ")") then
                return nil
            end
            local node = self:newNodeWithParameters("spell_require", annotation, positionalParams, namedParams)
            if spellId then
                node.spellId = spellId
            end
            node.property = property
            if name then
                node.name = name
                annotation.nameReference = annotation.nameReference or {}
                annotation.nameReference[#annotation.nameReference + 1] = node
            end
            return node
        end
        self.ParseStatement = function(tokenStream, annotation)
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
                    if  not tokenType or BINARY_OPERATOR[token] then
                        node = self.ParseExpression(tokenStream, annotation)
                    else
                        node = self:parseGroup(tokenStream, annotation)
                    end
                elseif token == "if" then
                    node = self.ParseIf(tokenStream, annotation)
                elseif token == "unless" then
                    node = self.ParseUnless(tokenStream, annotation)
                else
                    node = self.ParseExpression(tokenStream, annotation)
                end
            end
            return node
        end
        self.ParseString = function(tokenStream, annotation)
            local value
            local tokenType, token = tokenStream:Peek()
            if tokenType == "string" and token then
                value = token
                tokenStream:Consume()
            elseif tokenType == "name" and token then
                if STRING_LOOKUP_FUNCTION[lower(token)] then
                    return self.ParseFunction(tokenStream, annotation)
                else
                    value = token
                    tokenStream:Consume()
                end
            else
                tokenStream:Consume()
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing STRING; string, variable, or function expected.", token)
                return nil
            end
            local node = self:newString(annotation, value)
            annotation.stringReference = annotation.stringReference or {}
            annotation.stringReference[#annotation.stringReference + 1] = node
            return node
        end
        self.ParseUnless = function(tokenStream, annotation)
            local tokenType, token = tokenStream:Consume()
            if  not (tokenType == "keyword" and token == "unless") then
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing UNLESS; 'unless' expected.", token)
                return nil
            end
            local conditionNode = self.ParseExpression(tokenStream, annotation)
            if  not conditionNode then
                return nil
            end
            local bodyNode = self.ParseStatement(tokenStream, annotation)
            if  not bodyNode then
                return nil
            end
            local node = self:newNodeWithChildren("unless", annotation)
            node.child[1] = conditionNode
            node.child[2] = bodyNode
            return node
        end
        self.ParseVariable = function(tokenStream, annotation)
            local name
            local tokenType, token = tokenStream:Consume()
            if (tokenType == "name" or tokenType == "keyword") and token then
                name = token
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing VARIABLE; name expected.", token)
                return nil
            end
            local node = self:NewNode("variable", annotation)
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
            ["expression"] = self.ParseStatement,
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
    GetNumberNode = function(self, value, annotation)
        annotation.numberFlyweight = annotation.numberFlyweight or {}
        local node = annotation.numberFlyweight[value]
        if  not node then
            node = self:newValue(annotation, value)
            annotation.numberFlyweight[value] = node
        end
        return node
    end,
    PostOrderTraversal = function(self, node, array, visited)
        if __exports.isAstNodeWithChildren(node) then
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
    GetPrecedence = function(self, node)
        if isExpressionNode(node) then
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
        end
        return 0
    end,
    HasParameters = function(self, node)
        return next(node.rawPositionalParams) or next(node.rawNamedParams)
    end,
    Unparse = function(self, node)
        if node.asString then
            return node.asString
        else
            local visitor = self.UNPARSE_VISITOR[node.type]
            if  not visitor then
                self.debug:Error("Unable to unparse node of type '%s'.", node.type)
                return "Unkown_" .. node.type
            else
                node.asString = visitor(node)
                return node.asString
            end
        end
    end,
    unparseParameter = function(self, node)
        if node.type == "string" or node.type == "value" or node.type == "variable" or node.type == "boolean" then
            return self:Unparse(node)
        else
            return "(" .. self:Unparse(node) .. ")"
        end
    end,
    UnparseParameters = function(self, positionalParams, namedParams, noFilter, noTarget)
        local output = self.outputPool:Get()
        if namedParams then
            for k, v in kpairs(namedParams) do
                if ( not noFilter or k ~= "filter") and ( not noTarget or k ~= "target") then
                    output[#output + 1] = format("%s=%s", k, self:unparseParameter(v))
                end
            end
        end
        sort(output)
        for k = #positionalParams, 1, -1 do
            insert(output, 1, self:unparseParameter(positionalParams[k]))
        end
        local outputString = concat(output, " ")
        self.outputPool:Release(output)
        return outputString
    end,
    SyntaxError = function(self, tokenStream, pattern, ...)
        self.debug:Warning(pattern, ...)
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
        self.debug:Debug("Visit " .. nodeType)
        if  not visitor then
            self.debug:Error("Unable to parse node of type '%s'.", nodeType)
            return nil
        else
            local result = visitor(tokenStream, annotation)
            if  not result then
                self.debug:Error([[Failed in %s visitor]], nodeType)
            end
            return result
        end
    end,
    parseTypedFunction = function(self, tokenStream, annotation, name, target, filter, infos)
        if  not self:parseToken(tokenStream, "FUNCTION", "(") then
            return nil
        end
        local positionalParams, namedParams = self:ParseParameters(tokenStream, "function", annotation, nil)
        if  not positionalParams or  not namedParams then
            return nil
        end
        if  not self:parseToken(tokenStream, "FUNCTION", ")") then
            return nil
        end
        if target then
            namedParams.target = self:newString(annotation, target)
        end
        if filter then
            namedParams.filter = self:newString(annotation, filter)
        end
        if #positionalParams > #infos.parameters then
            self:SyntaxError(tokenStream, "Type error: the %s function takes %d parameters", name, #infos.parameters)
            return nil
        end
        for key, node in kpairs(namedParams) do
            local parameterIndex = infos.namedParameters[key]
            if parameterIndex ~= nil then
                if positionalParams[parameterIndex] ~= nil then
                    self:SyntaxError(tokenStream, "Type error: the %s parameters is named in the %s function although it appears already in the parameters list", key, name)
                    return nil
                end
                positionalParams[parameterIndex] = node
            else
                self:SyntaxError(tokenStream, "Type error: unknown %s parameter in %s function", key, getFunctionSignature(name, infos))
                return nil
            end
        end
        for key, parameterInfos in ipairs(infos.parameters) do
            local parameter = positionalParams[key]
            if  not parameter then
                if parameterInfos.defaultValue ~= nil then
                    if parameterInfos.type == "string" then
                        positionalParams[key] = self:newString(annotation, parameterInfos.defaultValue)
                    elseif parameterInfos.type == "number" then
                        positionalParams[key] = self:newValue(annotation, parameterInfos.defaultValue)
                    elseif parameterInfos.type == "boolean" then
                        positionalParams[key] = self:newBoolean(annotation, parameterInfos.defaultValue)
                    else
                        self:SyntaxError(tokenStream, "Type error: parameter type unknown in %s function", name)
                        return nil
                    end
                elseif  not parameterInfos.optional then
                    self:SyntaxError(tokenStream, "Type error: parameter %s is required in %s function", parameterInfos.name, name)
                    return nil
                else
                    positionalParams[key] = self:newUndefined(annotation)
                end
            else
                if parameterInfos.type == "number" then
                    if parameterInfos.isSpell then
                        annotation.spellNode = annotation.spellNode or {}
                        insert(annotation.spellNode, parameter)
                    end
                elseif parameterInfos.type == "string" and parameter.type == "string" then
                    if parameterInfos.checkTokens then
                        if  not checkToken(parameterInfos.checkTokens, parameter.value) then
                            self:SyntaxError(tokenStream, "Type error: parameter %s has not a valid value in function %s", key, name)
                            return nil
                        end
                    end
                end
            end
        end
        local node = self:newNodeWithParameters("typed_function", annotation, positionalParams, namedParams)
        node.name = name
        node.asString = self.unparseTypedFunction(node)
        return node
    end,
    parseGroup = function(self, tokenStream, annotation)
        local group = self.ParseGroup(tokenStream, annotation)
        if group and #group.child == 1 then
            local result = group.child[1]
            self.nodesPool:Release(group)
            return result
        end
        return group
    end,
    ParseParameters = function(self, tokenStream, methodName, annotation, maxNumberOfParameters, namedParameters)
        local positionalParams = self.rawPositionalParametersPool:Get()
        local namedParams = (self.rawNamedParametersPool:Get())
        while true do
            local tokenType = tokenStream:Peek()
            if tokenType then
                local nextTokenType = tokenStream:Peek(2)
                if nextTokenType == "=" then
                    local parameterName
                    if namedParameters then
                        parameterName = self:parseCheckedNameToken(tokenStream, methodName, namedParameters)
                    else
                        parameterName = self:parseNameToken(tokenStream, methodName)
                    end
                    if  not parameterName then
                        return 
                    end
                    tokenStream:Consume()
                    local node = self.ParseSimpleParameterValue(tokenStream, annotation)
                    if  not node then
                        return 
                    end
                    namedParams[parameterName] = node
                else
                    local node
                    if tokenType == "name" or tokenType == "keyword" then
                        node = self.ParseVariable(tokenStream, annotation)
                        if  not node then
                            return 
                        end
                    elseif tokenType == "number" then
                        node = self.ParseNumber(tokenStream, annotation)
                        if  not node then
                            return 
                        end
                    elseif tokenType == "-" then
                        tokenStream:Consume()
                        node = self.ParseNumber(tokenStream, annotation)
                        if node then
                            local value = -1 * node.value
                            node = self:GetNumberNode(value, annotation)
                        else
                            return 
                        end
                    elseif tokenType == "string" then
                        node = self.ParseString(tokenStream, annotation)
                        if  not node then
                            return 
                        end
                    else
                        break
                    end
                    positionalParams[#positionalParams + 1] = node
                    if maxNumberOfParameters and #positionalParams > maxNumberOfParameters then
                        self:SyntaxError(tokenStream, "Error: the maximum number of parameters in %s is %s", methodName, maxNumberOfParameters)
                        return 
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
    ParseParentheses = function(self, tokenStream, annotation)
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
        local node = self.ParseExpression(tokenStream, annotation)
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
    ParseSimpleExpression = function(self, tokenStream, annotation)
        local node
        local tokenType, token = tokenStream:Peek()
        if tokenType == "number" then
            node = self.ParseNumber(tokenStream, annotation)
        elseif tokenType == "string" then
            node = self.ParseString(tokenStream, annotation)
        elseif tokenType == "keyword" and (token == "true" or token == "false") then
            tokenStream:Consume()
            node = self:newBoolean(annotation, token == "true")
        elseif tokenType == "name" or tokenType == "keyword" then
            tokenType, token = tokenStream:Peek(2)
            if tokenType == "." or tokenType == "(" then
                node = self.ParseFunction(tokenStream, annotation)
            else
                node = self.ParseVariable(tokenStream, annotation)
            end
        elseif tokenType == "(" or tokenType == "{" then
            node = self:ParseParentheses(tokenStream, annotation)
        else
            tokenStream:Consume()
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION", token)
            return nil
        end
        return node
    end,
    parseNumberOrNameParameter = function(self, tokenStream, methodName)
        local tokenType, token = tokenStream:Consume()
        local spellId, name
        if tokenType == "-" then
            tokenType, token = tokenStream:Consume()
            if tokenType == "number" then
                spellId = -tonumber(token)
            else
                self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' wheren parsing '%s'; number expected", token, methodName)
                return 
            end
        elseif tokenType == "number" then
            spellId = tonumber(token)
        elseif tokenType == "name" then
            name = token
        else
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing '%s'; number or name expected.", token, methodName)
            return 
        end
        return spellId, name
    end,
    parseToken = function(self, tokenStream, methodName, expectedToken)
        local tokenType, token = tokenStream:Consume()
        if tokenType ~= expectedToken then
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing %s; '%s' expected.", token, methodName, expectedToken)
            return false
        end
        return true
    end,
    parseKeywordTokens = function(self, tokenStream, methodName, keyCheck)
        local keyword
        local tokenType, token = tokenStream:Consume()
        if tokenType == "keyword" and token and checkToken(keyCheck, token) then
            keyword = token
        else
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing %s; keyword expected.", token, methodName)
            return nil
        end
        return keyword
    end,
    parseKeywordToken = function(self, tokenStream, methodName, keyCheck)
        local keyword
        local tokenType, token = tokenStream:Consume()
        if tokenType == "keyword" and token and token == keyCheck then
            keyword = keyCheck
        else
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing %s; keyword %s expected.", token, methodName, keyCheck)
            return nil
        end
        return keyword
    end,
    parseCheckedNameToken = function(self, tokenStream, methodName, keyCheck)
        local keyword
        local tokenType, token = tokenStream:Consume()
        if tokenType == "name" and token and checkToken(keyCheck, token) then
            keyword = token
        else
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing %s; name expected.", token, methodName)
            return nil
        end
        return keyword
    end,
    parseNameToken = function(self, tokenStream, methodName)
        local keyword
        local tokenType, token = tokenStream:Consume()
        if tokenType == "name" and token then
            keyword = token
        else
            self:SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing %s; name expected.", token, methodName)
            return nil
        end
        return keyword
    end,
    newFunction = function(self, name, annotation)
        local node = self:newNodeWithParameters("function", annotation)
        node.name = name
        return node
    end,
    newString = function(self, annotation, value)
        local node = self:NewNode("string", annotation)
        node.value = value
        node.result.constant = true
        local result = node.result
        result.timeSpan:copyFromArray(UNIVERSE)
        result.type = "value"
        result.value = value
        return node
    end,
    newVariable = function(self, annotation, name)
        local node = self:NewNode("variable", annotation)
        node.name = name
        return node
    end,
    newValue = function(self, annotation, value)
        local node = self:NewNode("value", annotation)
        node.value = value
        node.result.constant = true
        local result = node.result
        result.type = "value"
        result.value = value
        result.timeSpan:copyFromArray(UNIVERSE)
        result.origin = 0
        result.rate = 0
        return node
    end,
    newBoolean = function(self, annotation, value)
        local node = self:NewNode("boolean", annotation)
        node.value = value
        node.result.constant = true
        local result = node.result
        result.timeSpan:copyFromArray(UNIVERSE)
        result.type = "value"
        result.value = value
        return node
    end,
    newUndefined = function(self, annotation)
        local node = self:NewNode("undefined", annotation)
        node.result.constant = true
        node.result.timeSpan:copyFromArray(EMPTY_SET)
        return node
    end,
    internalNewNodeWithParameters = function(self, type, annotation, rawPositionalParameters, rawNamedParams)
        local node = self:internalNewNodeWithChildren(type, annotation)
        node.rawNamedParams = rawNamedParams or self.rawNamedParametersPool:Get()
        node.rawPositionalParams = rawPositionalParameters or self.rawPositionalParametersPool:Get()
        node.cachedParams = {
            named = self.namedParametersPool:Get(),
            positional = self.positionalParametersPool:Get()
        }
        annotation.parametersReference = annotation.parametersReference or {}
        annotation.parametersReference[#annotation.parametersReference + 1] = node
        return node
    end,
    internalNewNodeWithChildren = function(self, type, annotation)
        local node = self:internalNewNode(type, annotation)
        node.child = self.childrenPool:Get()
        return node
    end,
    internalNewNode = function(self, type, annotation)
        local node = self.nodesPool:Get()
        node.type = type
        node.annotation = annotation
        local nodeList = annotation.nodeList
        local nodeId = #nodeList + 1
        node.nodeId = nodeId
        nodeList[nodeId] = node
        node.result = {
            type = "none",
            timeSpan = newTimeSpan(),
            serial = 0
        }
        return node
    end,
    newNodeWithBodyAndParameters = function(self, type, annotation, body, rawPositionalParameters, rawNamedParams)
        local node = self:internalNewNodeWithParameters(type, annotation, rawPositionalParameters, rawNamedParams)
        node.body = body
        node.child[1] = body
        return node
    end,
    newNodeWithParameters = function(self, type, annotation, rawPositionalParameters, rawNamedParams)
        return self:internalNewNodeWithParameters(type, annotation, rawPositionalParameters, rawNamedParams)
    end,
    newNodeWithChildren = function(self, type, annotation)
        return self:internalNewNodeWithChildren(type, annotation)
    end,
    NewNode = function(self, type, annotation)
        return self:internalNewNode(type, annotation)
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
        ast.result.timeSpan:Release()
        wipe(ast.result)
        wipe(ast)
        self.nodesPool:Release(ast)
    end,
    ParseCode = function(self, nodeType, code, nodeList, annotation)
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
            if ast.type == "script" then
                ast.annotation = annotation
                self:PropagateConstants(ast)
                self:PropagateStrings(ast)
                self:VerifyFunctionCalls(ast)
                if options.optimize then
                    self:Optimize(ast)
                end
                self:InsertPostOrderTraversal(ast)
                return ast
            end
            self.debug:Debug("Unexpected type " .. ast.type .. " in parseScript")
            self:Release(ast)
        else
            self.debug:Error("Parse failed")
        end
        self:ReleaseAnnotation(annotation)
        return nil
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
    getId = function(self, name, dictionary)
        local itemId = dictionary[name]
        if itemId then
            if isNumber(itemId) then
                return itemId
            else
                self.debug:Error(name .. " is as string and not an item id")
            end
        end
        return 0
    end,
    PropagateConstants = function(self, ast)
        self.profiler:StartProfiling("OvaleAST_PropagateConstants")
        if ast.annotation then
            local dictionary = ast.annotation.definition
            if dictionary and ast.annotation.nameReference then
                for _, node in ipairs(ast.annotation.nameReference) do
                    if (node.type == "item_info" or node.type == "itemrequire") and node.name then
                        node.itemId = self:getId(node.name, dictionary)
                    elseif node.type == "spell_aura_list" or node.type == "spell_info" or node.type == "spell_require" then
                        if node.name then
                            node.spellId = self:getId(node.name, dictionary)
                        end
                        if node.type == "spell_aura_list" and node.buffName then
                            node.buffSpellId = self:getId(node.buffName, dictionary)
                        end
                    elseif node.type == "variable" then
                        local name = node.name
                        local value = dictionary[name]
                        if value then
                            if isNumber(value) then
                                local valueNode = node
                                valueNode.type = "value"
                                valueNode.name = name
                                valueNode.value = value
                                valueNode.origin = 0
                                valueNode.rate = 0
                            else
                                local valueNode = node
                                valueNode.type = "string"
                                valueNode.value = value
                                valueNode.name = name
                            end
                        else
                            local valueNode = node
                            valueNode.type = "string"
                            valueNode.value = name
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
                local nodeAsString = node
                if node.type == "string" then
                    local key = node.value
                    local value = L[key]
                    if key ~= value then
                        nodeAsString.value = value
                        nodeAsString.name = key
                    end
                elseif node.type == "variable" then
                    nodeAsString.type = "string"
                    local name = node.name
                    nodeAsString.name = node.name
                    nodeAsString.value = name
                elseif node.type == "value" then
                    local value = node.value
                    nodeAsString.type = "string"
                    nodeAsString.name = tostring(node.value)
                    nodeAsString.value = tostring(value)
                elseif node.type == "function" then
                    local key = node.rawPositionalParams[1]
                    local stringKey
                    if isAstNode(key) then
                        if key.type == "value" then
                            stringKey = tostring(key.value)
                        elseif key.type == "variable" then
                            stringKey = key.name
                        elseif key.type == "string" then
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
                            nodeAsString.type = "string"
                            nodeAsString.value = value
                            nodeAsString.func = node.name
                            nodeAsString.name = stringKey
                        end
                    end
                end
            end
        end
        self.profiler:StopProfiling("OvaleAST_PropagateStrings")
    end,
    VerifyFunctionCalls = function(self, ast)
        self.profiler:StartProfiling("OvaleAST_VerifyFunctionCalls")
        if ast.annotation and ast.annotation.verify then
            local customFunction = ast.annotation.customFunction
            local functionCall = ast.annotation.functionCall
            if functionCall then
                for name in pairs(functionCall) do
                    if  not (ACTION_PARAMETER_COUNT[name] or STRING_LOOKUP_FUNCTION[name] or self.ovaleCondition:IsCondition(name) or (customFunction and customFunction[name])) then
                        self.debug:Error("unknown function '%s'.", name)
                    end
                end
            end
        end
        self.profiler:StopProfiling("OvaleAST_VerifyFunctionCalls")
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
                if __exports.isAstNodeWithChildren(node) then
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
