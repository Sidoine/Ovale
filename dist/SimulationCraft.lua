local __exports = LibStub:NewLibrary("ovale/SimulationCraft", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local AceConfig = LibStub:GetLibrary("AceConfig-3.0", true)
local AceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0", true)
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Options = LibStub:GetLibrary("ovale/Options")
local OvaleOptions = __Options.OvaleOptions
local __Pool = LibStub:GetLibrary("ovale/Pool")
local OvalePool = __Pool.OvalePool
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local MakeString = __Ovale.MakeString
local __AST = LibStub:GetLibrary("ovale/AST")
local OvaleAST = __AST.OvaleAST
local isValueNode = __AST.isValueNode
local __Compile = LibStub:GetLibrary("ovale/Compile")
local OvaleCompile = __Compile.OvaleCompile
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
local __Lexer = LibStub:GetLibrary("ovale/Lexer")
local OvaleLexer = __Lexer.OvaleLexer
local __Power = LibStub:GetLibrary("ovale/Power")
local OvalePower = __Power.OvalePower
local __Controls = LibStub:GetLibrary("ovale/Controls")
local ResetControls = __Controls.ResetControls
local format = string.format
local gmatch = string.gmatch
local gsub = string.gsub
local find = string.find
local len = string.len
local lower = string.lower
local match = string.match
local sub = string.sub
local upper = string.upper
local ipairs = ipairs
local next = next
local pairs = pairs
local rawset = rawset
local tonumber = tonumber
local tostring = tostring
local type = type
local wipe = wipe
local setmetatable = setmetatable
local concat = table.concat
local insert = table.insert
local remove = table.remove
local sort = table.sort
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local OvaleSimulationCraftBase = OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleSimulationCraft"))
local KEYWORD = {}
local MODIFIER_KEYWORD = {
    ["ammo_type"] = true,
    ["animation_cancel"] = true,
    ["attack_speed"] = true,
    ["chain"] = true,
    ["choose"] = true,
    ["condition"] = true,
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
    ["interrupt_global"] = true,
    ["interrupt_if"] = true,
    ["interrupt_immediate"] = true,
    ["interval"] = true,
    ["lethal"] = true,
    ["line_cd"] = true,
    ["max_cycle_targets"] = true,
    ["max_energy"] = true,
    ["min_frenzy"] = true,
    ["moving"] = true,
    ["name"] = true,
    ["nonlethal"] = true,
    ["op"] = true,
    ["pct_health"] = true,
    ["precombat"] = true,
    ["precombat_seconds"] = true,
    ["precast_time"] = true,
    ["range"] = true,
    ["sec"] = true,
    ["slot"] = true,
    ["sync"] = true,
    ["sync_weapons"] = true,
    ["target"] = true,
    ["target_if"] = true,
    ["target_if_first"] = true,
    ["target_if_max"] = true,
    ["target_if_min"] = true,
    ["toggle"] = true,
    ["travel_speed"] = true,
    ["type"] = true,
    ["value"] = true,
    ["value_else"] = true,
    ["wait"] = true,
    ["wait_on_ready"] = true,
    ["weapon"] = true
}
local LITTERAL_MODIFIER = {
    ["name"] = true
}
local FUNCTION_KEYWORD = {
    ["ceil"] = true,
    ["floor"] = true
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
    ["wait"] = true
}
local RUNE_OPERAND = {
    ["rune"] = "rune"
}
local CONSUMABLE_ITEMS = {
    ["potion"] = true,
    ["food"] = true,
    ["flask"] = true,
    ["augmentation"] = true
}
do
    for keyword, value in pairs(MODIFIER_KEYWORD) do
        KEYWORD[keyword] = value
    end
    for keyword, value in pairs(FUNCTION_KEYWORD) do
        KEYWORD[keyword] = value
    end
    for keyword, value in pairs(SPECIAL_ACTION) do
        KEYWORD[keyword] = value
    end
end
local UNARY_OPERATOR = {
    ["!"] = {
        [1] = "logical",
        [2] = 15
    },
    ["-"] = {
        [1] = "arithmetic",
        [2] = 50
    },
    ["@"] = {
        [1] = "arithmetic",
        [2] = 50
    }
}
local BINARY_OPERATOR = {
    ["|"] = {
        [1] = "logical",
        [2] = 5,
        [3] = "associative"
    },
    ["^"] = {
        [1] = "logical",
        [2] = 8,
        [3] = "associative"
    },
    ["&"] = {
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
    ["="] = {
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
    ["~"] = {
        [1] = "compare",
        [2] = 20
    },
    ["!~"] = {
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
    }
}
local INDENT = {}
do
    INDENT[0] = ""
    local metatable = {
        __index = function(tbl, key)
            local _key = tonumber(key)
            if _key > 0 then
                local s = tbl[_key - 1] .. "	"
                rawset(tbl, key, s)
                return s
            end
            return INDENT[0]
        end

    }
    setmetatable(INDENT, metatable)
end
local EMIT_DISAMBIGUATION = {}
local OPERAND_TOKEN_PATTERN = "[^.]+"
local OPTIONAL_SKILLS = {
    ["volley"] = {
        class = "HUNTER",
        default = true
    },
    ["harpoon"] = {
        class = "HUNTER",
        specialization = "survival",
        default = true
    },
    ["time_warp"] = {
        class = "MAGE"
    },
    ["storm_earth_and_fire"] = {
        class = "MONK"
    },
    ["chi_burst"] = {
        class = "MONK",
        default = true
    },
    ["touch_of_karma"] = {
        class = "MONK",
        default = false
    },
    ["vanish"] = {
        class = "ROGUE",
        specialization = "assassination",
        default = true
    },
    ["blade_flurry"] = {
        class = "ROGUE",
        specialization = "outlaw",
        default = true
    },
    ["bloodlust"] = {
        class = "SHAMAN"
    },
    ["righteous_fury"] = {
        class = "PALADIN"
    },
    ["fel_rush"] = {
        class = "DEMONHUNTER",
        default = true
    },
    ["vengeful_retreat"] = {
        class = "DEMONHUNTER",
        default = true
    }
}
local self_functionDefined = {}
local self_functionUsed = {}
local self_outputPool = OvalePool("OvaleSimulationCraft_outputPool")
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
local self_lastSimC = nil
local self_lastScript = nil
do
    local actions = {
        simc = {
            name = "SimulationCraft",
            type = "execute",
            func = function()
                local appName = __exports.OvaleSimulationCraft:GetName()
                AceConfigDialog:SetDefaultSize(appName, 700, 550)
                AceConfigDialog:Open(appName)
            end

        }
    }
    for k, v in pairs(actions) do
        OvaleOptions.options.args.actions.args[k] = v
    end
end
local OVALE_TAGS = {
    [1] = "main",
    [2] = "shortcd",
    [3] = "cd"
}
local OVALE_TAG_PRIORITY = {}
do
    for i, tag in ipairs(OVALE_TAGS) do
        OVALE_TAG_PRIORITY[tag] = i * 10
    end
end
do
    local defaultDB = {
        overrideCode = ""
    }
    for k, v in pairs(defaultDB) do
        OvaleOptions.defaultDB.profile[k] = v
    end
    OvaleOptions:RegisterOptions(__exports.OvaleSimulationCraft)
end
local print_r = function(node, indent, done, output)
    done = done or {}
    output = output or {}
    indent = indent or ""
    if node == nil then
        insert(output, indent .. "nil")
    elseif type(node) ~= "table" then
        insert(output, indent .. node)
    else
        for key, value in pairs(node) do
            if type(value) == "table" then
                if done[value] then
                    insert(output, indent .. "[" .. tostring(key) .. "] => (self_reference)")
                else
                    done[value] = true
                    insert(output, indent .. "[" .. tostring(key) .. "] => {")
                    print_r(value, indent .. "    ", done, output)
                    insert(output, indent .. "}")
                end
            else
                insert(output, indent .. "[" .. tostring(key) .. "] => " .. tostring(value))
            end
        end
    end
    return output
end

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
        [1] = "^%d+%a[%w_]*([.:]?[%w_.]*)*",
        [2] = TokenizeName
    },
    [2] = {
        [1] = "^%d+%.?%d*",
        [2] = TokenizeNumber
    },
    [3] = {
        [1] = "^[%a_][%w_]*([.:]?[%w_.]*)*",
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
        [1] = "^.",
        [2] = Tokenize
    },
    [10] = {
        [1] = "^$",
        [2] = NoToken
    }
}
local GetPrecedence = function(node)
    local precedence = node.precedence
    if  not precedence then
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
local Unparse = function(node)
    local visitor = UNPARSE_VISITOR[node.type]
    if  not visitor then
        __exports.OvaleSimulationCraft:Error("Unable to unparse node of type '%s'.", node.type)
    else
        return visitor(node)
    end
end

local UnparseAction = function(node)
    local output = self_outputPool:Get()
    output[#output + 1] = node.name
    for modifier, expressionNode in pairs(node.child) do
        output[#output + 1] = modifier .. "=" .. Unparse(expressionNode)
    end
    local s = concat(output, ",")
    self_outputPool:Release(output)
    return s
end

local UnparseActionList = function(node)
    local output = self_outputPool:Get()
    local listName
    if node.name == "_default" then
        listName = "action"
    else
        listName = "action." .. node.name
    end
    output[#output + 1] = ""
    for i, actionNode in pairs(node.child) do
        local operator = (tonumber(i) == 1) and "=" or "+=/"
        output[#output + 1] = listName .. operator .. Unparse(actionNode)
    end
    local s = concat(output, "\n")
    self_outputPool:Release(output)
    return s
end

local UnparseExpression = function(node)
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

local UnparseFunction = function(node)
    return node.name .. "(" .. Unparse(node.child[1]) .. ")"
end

local UnparseNumber = function(node)
    return tostring(node.value)
end

local UnparseOperand = function(node)
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
        ["operand"] = UnparseOperand
    }
end
local SyntaxError = function(tokenStream, ...)
    __exports.OvaleSimulationCraft:Print(...)
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
    __exports.OvaleSimulationCraft:Print(concat(context, " "))
end

local ParseFunction = nil
local ParseModifier = nil
local ParseNumber = nil
local ParseOperand = nil
local ParseParentheses = nil
local ParseSimpleExpression = nil
local TicksRemainTranslationHelper = function(p1, p2, p3, p4)
    if p4 then
        return p1 .. p2 .. " < " .. tostring(tonumber(p4) + 1)
    else
        return p1 .. "<" .. tostring(tonumber(p3) + 1)
    end
end

local ParseAction = function(action, nodeList, annotation)
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
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line '%s'; name or special action expected.", token, action)
            ok = false
        end
    end
    local child = self_childrenPool:Get()
    if ok then
        local tokenType, token = tokenStream:Peek()
        while ok and tokenType do
            if tokenType == "," then
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
        annotation.sync = annotation.sync or {}
        annotation.sync[name] = annotation.sync[name] or node
    else
        self_childrenPool:Release(child)
    end
    return ok, node
end

local ParseActionList = function(name, actionList, nodeList, annotation)
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

local function ParseExpression(tokenStream, nodeList, annotation, minPrecedence)
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
                ok, rhsNode = ParseExpression(tokenStream, nodeList, annotation, precedence)
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
                ok, node = ParseSimpleExpression(tokenStream, nodeList, annotation)
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
                    if  not rhsNode then
                        SyntaxError(tokenStream, "Internal error: no right operand in binary operator %s.", token)
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
            SyntaxError(tokenStream, "Syntax error: %s of type %s is not a binary operator", token, tokenType)
            return false, nil
        end
        if  not keepScanning then
            break
        end
    end
    return ok, node
end
ParseFunction = function(tokenStream, nodeList, annotation)
    local ok = true
    local name
    do
        local tokenType, token = tokenStream:Consume()
        if tokenType == "keyword" and FUNCTION_KEYWORD[token] then
            name = token
        else
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token)
            ok = false
        end
    end
    if ok then
        local tokenType, token = tokenStream:Consume()
        if tokenType ~= "(" then
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; '(' expected.", token)
            ok = false
        end
    end
    local argumentNode
    if ok then
        ok, argumentNode = ParseExpression(tokenStream, nodeList, annotation)
    end
    if ok then
        local tokenType, token = tokenStream:Consume()
        if tokenType ~= ")" then
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.", token)
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
end

local ParseIdentifier = function(tokenStream, nodeList, annotation)
    local _, token = tokenStream:Consume()
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
    do
        local tokenType, token = tokenStream:Consume()
        if tokenType == "number" then
            value = tonumber(token)
        else
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing NUMBER; number expected.", token)
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
end

ParseOperand = function(tokenStream, nodeList, annotation)
    local ok = true
    local name
    do
        local tokenType, token = tokenStream:Consume()
        if tokenType == "name" then
            name = token
        elseif tokenType == "keyword" and (token == "target" or token == "cooldown") then
            name = token
        else
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing OPERAND; operand expected.", token)
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
end

ParseParentheses = function(tokenStream, nodeList, annotation)
    local ok = true
    local leftToken, rightToken
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
    local node
    if ok then
        ok, node = ParseExpression(tokenStream, nodeList, annotation)
    end
    if ok then
        local tokenType, token = tokenStream:Consume()
        if tokenType ~= rightToken then
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '%s' expected.", token, rightToken)
            ok = false
        end
    end
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
            return false, nil
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

local CamelCase = nil
do
    local CamelCaseHelper = function(first, ...)
        return upper(first) .. lower(...)
    end

    CamelCase = function(s)
        local tc = gsub(s, "(%a)(%w*)", CamelCaseHelper)
        return gsub(tc, "[%s_]", "")
    end

end
local CamelSpecialization = function(annotation)
    local output = self_outputPool:Get()
    local profileName, className, specialization = annotation.name, annotation.class, annotation.specialization
    if specialization then
        output[#output + 1] = specialization
    end
    if match(profileName, "_1[hH]_") then
        if className == "DEATHKNIGHT" and specialization == "frost" then
            output[#output + 1] = "dual wield"
        elseif className == "WARRIOR" and specialization == "fury" then
            output[#output + 1] = "single minded fury"
        end
    elseif match(profileName, "_2[hH]_") then
        if className == "DEATHKNIGHT" and specialization == "frost" then
            output[#output + 1] = "two hander"
        elseif className == "WARRIOR" and specialization == "fury" then
            output[#output + 1] = "titans grip"
        end
    elseif match(profileName, "_[gG]ladiator_") then
        output[#output + 1] = "gladiator"
    end
    local outputString = CamelCase(concat(output, " "))
    self_outputPool:Release(output)
    return outputString
end

local OvaleFunctionName = function(name, annotation)
    local functionName = CamelCase(name .. " actions")
    if annotation.specialization then
        functionName = CamelSpecialization(annotation) .. functionName
    end
    return functionName
end

local function AddSymbol(annotation, symbol)
    local symbolTable = annotation.symbolTable or {}
    local symbolList = annotation.symbolList or {}
    if  not symbolTable[symbol] and  not OvaleData.DEFAULT_SPELL_LIST[symbol] then
        symbolTable[symbol] = true
        symbolList[#symbolList + 1] = symbol
    end
    annotation.symbolTable = symbolTable
    annotation.symbolList = symbolList
end
local AddPerClassSpecialization = function(tbl, name, info, className, specialization, _type)
    className = className or "ALL_CLASSES"
    specialization = specialization or "ALL_SPECIALIZATIONS"
    tbl[className] = tbl[className] or {}
    tbl[className][specialization] = tbl[className][specialization] or {}
    tbl[className][specialization][name] = {
        [1] = info,
        [2] = _type or "Spell"
    }
end

local GetPerClassSpecialization = function(tbl, name, className, specialization)
    local info
    while  not info do
        while  not info do
            if tbl[className] and tbl[className][specialization] and tbl[className][specialization][name] then
                info = tbl[className][specialization][name]
            end
            if specialization ~= "ALL_SPECIALIZATIONS" then
                specialization = "ALL_SPECIALIZATIONS"
            else
                break
            end
        end
        if className ~= "ALL_CLASSES" then
            className = "ALL_CLASSES"
        else
            break
        end
    end
    if info then
        return info[1], info[2]
    end
    return 
end

local AddDisambiguation = function(name, info, className, specialization, _type)
    AddPerClassSpecialization(EMIT_DISAMBIGUATION, name, info, className, specialization, _type)
end

local function Disambiguate(annotation, name, className, specialization, _type)
    local disname, distype = GetPerClassSpecialization(EMIT_DISAMBIGUATION, name, className, specialization)
    if  not disname then
        if  not annotation.dictionary[name] then
            local otherName = match(name, "_buff$") and gsub(name, "_buff$", "") or gsub(name, "_debuff$", "")
            if annotation.dictionary[otherName] then
                return otherName, _type
            end
            local potionName = gsub(name, "potion_of_", "")
            if annotation.dictionary[potionName] then
                return potionName, _type
            end
        end
        return name, _type
    end
    return disname, distype
end
local InitializeDisambiguation = function()
    AddDisambiguation("none", "none")
    AddDisambiguation("bloodlust_buff", "burst_haste_buff")
    AddDisambiguation("buff_sephuzs_secret", "sephuzs_secret_buff")
    AddDisambiguation("arcane_torrent", "arcane_torrent_runicpower", "DEATHKNIGHT")
    AddDisambiguation("arcane_torrent", "arcane_torrent_dh", "DEMONHUNTER")
    AddDisambiguation("arcane_torrent", "arcane_torrent_energy", "DRUID")
    AddDisambiguation("arcane_torrent", "arcane_torrent_focus", "HUNTER")
    AddDisambiguation("arcane_torrent", "arcane_torrent_mana", "MAGE")
    AddDisambiguation("arcane_torrent", "arcane_torrent_chi", "MONK")
    AddDisambiguation("arcane_torrent", "arcane_torrent_holy", "PALADIN")
    AddDisambiguation("arcane_torrent", "arcane_torrent_mana", "PRIEST")
    AddDisambiguation("arcane_torrent", "arcane_torrent_energy", "ROGUE")
    AddDisambiguation("arcane_torrent", "arcane_torrent_mana", "SHAMAN")
    AddDisambiguation("arcane_torrent", "arcane_torrent_mana", "WARLOCK")
    AddDisambiguation("arcane_torrent", "arcane_torrent_rage", "WARRIOR")
    AddDisambiguation("blood_fury", "blood_fury_ap", "DEATHKNIGHT")
    AddDisambiguation("blood_fury", "blood_fury_ap", "HUNTER")
    AddDisambiguation("blood_fury", "blood_fury_sp", "MAGE")
    AddDisambiguation("blood_fury", "blood_fury_apsp", "MONK")
    AddDisambiguation("blood_fury", "blood_fury_ap", "ROGUE")
    AddDisambiguation("blood_fury", "blood_fury_apsp", "SHAMAN")
    AddDisambiguation("blood_fury", "blood_fury_sp", "WARLOCK")
    AddDisambiguation("blood_fury", "blood_fury_ap", "WARRIOR")
    AddDisambiguation("deaths_reach_talent", "deaths_reach_talent_unholy", "DEATHKNIGHT", "unholy")
    AddDisambiguation("grip_of_the_dead_talent", "grip_of_the_dead_talent_unholy", "DEATHKNIGHT", "unholy")
    AddDisambiguation("wraith_walk_talent", "wraith_walk_talent_blood", "DEATHKNIGHT", "blood")
    AddDisambiguation("asphyxiate", "asphyxiate_blood", "DEATHKNIGHT", "blood")
    AddDisambiguation("deaths_reach_talent", "deaths_reach_talent_unholy", "DEATHKNIGHT", "unholy")
    AddDisambiguation("grip_of_the_dead_talent", "grip_of_the_dead_talent_unholy", "DEATHKNIGHT", "unholy")
    AddDisambiguation("cold_heart_talent_buff", "cold_heart_buff", "DEATHKNIGHT", "frost")
    AddDisambiguation("outbreak_debuff", "virulent_plague_debuff", "DEATHKNIGHT", "unholy")
    AddDisambiguation("gargoyle", "summon_gargoyle", "DEATHKNIGHT", "unholy")
    AddDisambiguation("felblade_talent", "felblade_talent_havoc", "DEMONHUNTER", "havoc")
    AddDisambiguation("immolation_aura", "immolation_aura_havoc", "DEMONHUNTER", "havoc")
    AddDisambiguation("metamorphosis", "metamorphosis_veng", "DEMONHUNTER", "vengeance")
    AddDisambiguation("metamorphosis_buff", "metamorphosis_veng_buff", "DEMONHUNTER", "vengeance")
    AddDisambiguation("metamorphosis", "metamorphosis_havoc", "DEMONHUNTER", "havoc")
    AddDisambiguation("metamorphosis_buff", "metamorphosis_havoc_buff", "DEMONHUNTER", "havoc")
    AddDisambiguation("chaos_blades_debuff", "chaos_blades_buff", "DEMONHUNTER", "havoc")
    AddDisambiguation("throw_glaive", "throw_glaive_veng", "DEMONHUNTER", "vengeance")
    AddDisambiguation("throw_glaive", "throw_glaive_havoc", "DEMONHUNTER", "havoc")
    AddDisambiguation("feral_affinity_talent", "feral_affinity_talent_balance", "DRUID", "balance")
    AddDisambiguation("guardian_affinity_talent", "guardian_affinity_talent_restoration", "DRUID", "restoration")
    AddDisambiguation("a_murder_of_crows_talent", "mm_a_murder_of_crows_talent", "HUNTER", "marksmanship")
    AddDisambiguation("cat_beast_cleave", "pet_beast_cleave", "HUNTER", "beast_mastery")
    AddDisambiguation("cat_frenzy", "pet_frenzy", "HUNTER", "beast_mastery")
    AddDisambiguation("kill_command", "kill_command_sv", "HUNTER", "survival")
    AddDisambiguation("kill_command", "kill_command_sv", "HUNTER", "survival")
    AddDisambiguation("mongoose_bite_eagle", "mongoose_bite", "HUNTER", "survival")
    AddDisambiguation("multishot", "multishot_bm", "HUNTER", "beast_mastery")
    AddDisambiguation("multishot", "multishot_mm", "HUNTER", "marksmanship")
    AddDisambiguation("raptor_strike_eagle", "raptor_strike", "HUNTER", "survival")
    AddDisambiguation("serpent_sting", "serpent_sting_mm", "HUNTER", "marksmanship")
    AddDisambiguation("serpent_sting", "serpent_sting_sv", "HUNTER", "survival")
    AddDisambiguation("healing_elixir_talent", "healing_elixir_talent_mistweaver", "MONK", "mistweaver")
    AddDisambiguation("bok_proc_buff", "blackout_kick_buff", "MONK", "windwalker")
    AddDisambiguation("fortifying_brew", "fortifying_brew_mistweaver", "MONK", "mistweaver")
    AddDisambiguation("rushing_jade_wind", "rushing_jade_wind_windwalker", "MONK", "windwalker")
    AddDisambiguation("breath_of_fire_dot_debuff", "breath_of_fire_debuff", "MONK", "brewmaster")
    AddDisambiguation("brews", "ironskin_brew", "MONK", "brewmaster")
    AddDisambiguation("judgment_of_light_talent", "judgment_of_light_talent_holy", "PALADIN", "holy")
    AddDisambiguation("unbreakable_spirit_talent", "unbreakable_spirit_talent_holy", "PALADIN", "holy")
    AddDisambiguation("cavalier_talent", "cavalier_talent_holy", "PALADIN", "holy")
    AddDisambiguation("divine_purpose_buff", "divine_purpose_buff_holy", "PALADIN", "holy")
    AddDisambiguation("judgment", "judgment_holy", "PALADIN", "holy")
    AddDisambiguation("judgment", "judgment_prot", "PALADIN", "protection")
    AddDisambiguation("mindbender_talent", "mindbender_talent_discipline", "PRIEST", "discipline")
    AddDisambiguation("twist_of_fate_talent", "twist_of_fate_talent_discipline", "PRIEST", "discipline")
    AddDisambiguation("stealth_buff", "stealthed_buff", "ROGUE")
    AddDisambiguation("the_dreadlords_deceit_buff", "the_dreadlords_deceit_assassination_buff", "ROGUE", "assassination")
    AddDisambiguation("the_dreadlords_deceit_buff", "the_dreadlords_deceit_outlaw_buff", "ROGUE", "outlaw")
    AddDisambiguation("the_dreadlords_deceit_buff", "the_dreadlords_deceit_subtlety_buff", "ROGUE", "subtlety")
    AddDisambiguation("ascendance", "ascendance_elemental", "SHAMAN", "elemental")
    AddDisambiguation("ascendance", "ascendance_enhancement", "SHAMAN", "enhancement")
    AddDisambiguation("ascendance", "ascendance_restoration", "SHAMAN", "restoration")
    AddDisambiguation("chain_lightning", "chain_lightning_restoration", "SHAMAN", "restoration")
    AddDisambiguation("earth_shield_talent", "earth_shield_talent_restoration", "SHAMAN", "restoration")
    AddDisambiguation("echo_of_the_elements_talent", "resto_echo_of_the_elements_talent", "SHAMAN", "restoration")
    AddDisambiguation("flame_shock", "flame_shock_restoration", "SHAMAN", "restoration")
    AddDisambiguation("healing_surge", "healing_surge_restoration", "SHAMAN", "restoration")
    AddDisambiguation("lightning_bolt", "lightning_bolt_elemental", "SHAMAN", "elemental")
    AddDisambiguation("lightning_bolt", "lightning_bolt_enhancement", "SHAMAN", "enhancement")
    AddDisambiguation("strike", "windstrike", "SHAMAN", "enhancement")
    AddDisambiguation("totem_mastery", "totem_mastery_elemental", "SHAMAN", "elemental")
    AddDisambiguation("totem_mastery", "totem_mastery_enhancement", "SHAMAN", "enhancement")
    AddDisambiguation("132369", "wilfreds_sigil_of_superior_summoning", "WARLOCK", "demonology")
    AddDisambiguation("dark_soul", "dark_soul_misery", "WARLOCK", "affliction")
    AddDisambiguation("soul_conduit_talent", "demo_soul_conduit_talent", "WARLOCK", "demonology")
    AddDisambiguation("anger_management_talent", "fury_anger_management_talent", "WARRIOR", "fury")
    AddDisambiguation("bladestorm", "bladestorm_arms", "WARRIOR", "arms")
    AddDisambiguation("bladestorm", "bladestorm_fury", "WARRIOR", "fury")
    AddDisambiguation("bounding_stride_talent", "prot_bounding_stride_talent", "WARRIOR", "protection")
    AddDisambiguation("deep_wounds_debuff", "deep_wounds_arms_debuff", "WARRIOR", "arms")
    AddDisambiguation("deep_wounds_debuff", "deep_wounds_prot_debuff", "WARRIOR", "protection")
    AddDisambiguation("dragon_roar_talent", "prot_dragon_roar_talent", "WARRIOR", "protection")
    AddDisambiguation("execute", "execute_arms", "WARRIOR", "arms")
    AddDisambiguation("ravager", "ravager_prot", "WARRIOR", "protection")
    AddDisambiguation("massacre_talent", "arms_massacre_talent", "WARRIOR", "arms")
    AddDisambiguation("storm_bolt_talent", "prot_storm_bolt_talent", "WARRIOR", "protection")
    AddDisambiguation("sudden_death_buff", "sudden_death_arms_buff", "WARRIOR", "arms")
    AddDisambiguation("sudden_death_buff", "sudden_death_fury_buff", "WARRIOR", "fury")
    AddDisambiguation("sudden_death_talent", "fury_sudden_death_talent", "WARRIOR", "fury")
    AddDisambiguation("whirlwind", "whirlwind_arms", "WARRIOR", "arms")
    AddDisambiguation("meat_cleaver", "whirlwind", "WARRIOR", "fury")
end

local IsTotem = function(name)
    if sub(name, 1, 13) == "wild_mushroom" then
        return true
    elseif name == "prismatic_crystal" or name == "rune_of_power" then
        return true
    elseif sub(name, -7, -1) == "_statue" then
        return true
    elseif sub(name, -6, -1) == "_totem" then
        return true
    end
    return false
end

local NewLogicalNode = function(operator, lhsNode, rhsNode, nodeList)
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

local ConcatenatedConditionNode = function(conditionList, nodeList, annotation)
    local conditionNode
    if #conditionList > 0 then
        if #conditionList == 1 then
            conditionNode = conditionList[1]
        elseif #conditionList > 1 then
            local lhsNode = conditionList[1]
            local rhsNode = conditionList[2]
            conditionNode = NewLogicalNode("or", lhsNode, rhsNode, nodeList)
            for k = 3, #conditionList, 1 do
                lhsNode = conditionNode
                rhsNode = conditionList[k]
                conditionNode = NewLogicalNode("or", lhsNode, rhsNode, nodeList)
            end
        end
    end
    return conditionNode
end

local ConcatenatedBodyNode = function(bodyList, nodeList, annotation)
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

local OvaleTaggedFunctionName = function(name, tag)
    local bodyName, conditionName
    local prefix, suffix = match(name, "([A-Z]%w+)(Actions)")
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

local TagPriority = function(tag)
    return OVALE_TAG_PRIORITY[tag] or 10
end

local SPLIT_BY_TAG_VISITOR = nil
local SplitByTag = nil
local SplitByTagAction = nil
local SplitByTagAddFunction = nil
local SplitByTagCustomFunction = nil
local SplitByTagGroup = nil
local SplitByTagIf = nil
local SplitByTagState = nil
SplitByTag = function(tag, node, nodeList, annotation)
    local visitor = SPLIT_BY_TAG_VISITOR[node.type]
    if  not visitor then
        __exports.OvaleSimulationCraft:Error("Unable to split-by-tag node of type '%s'.", node.type)
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
        elseif isValueNode(firstParamNode) then
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
            __exports.OvaleSimulationCraft:Print("Warning: Unable to find %s '%s'", actionType, name)
        end
    elseif actionType == "texture" then
        local firstParamNode = node.rawPositionalParams[1]
        local id, name
        if firstParamNode.type == "variable" then
            name = firstParamNode.name
            id = annotation.dictionary and annotation.dictionary[name]
        elseif isValueNode(firstParamNode) then
            name = firstParamNode.value
            id = name
        end
        if actionTag == nil then
            actionTag, invokesGCD = OvaleData:GetSpellTagInfo(id)
        end
        if actionTag == nil then
            actionTag, invokesGCD = OvaleData:GetItemTagInfo(id)
        end
        if actionTag == nil then
            actionTag = "main"
            invokesGCD = true
        end
    else
        __exports.OvaleSimulationCraft:Print("Warning: Unknown action type '%'", actionType)
    end
    if  not actionTag then
        actionTag = "main"
        invokesGCD = true
        __exports.OvaleSimulationCraft:Print("Warning: Unable to determine tag for '%s', assuming '%s' (actionType: %s).", name, actionTag, actionType)
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
    local bodyNode, conditionNode = SplitByTag(tag, node.child[1], nodeList, annotation)
    if  not bodyNode or bodyNode.type ~= "group" then
        local newGroupNode = OvaleAST:NewNode(nodeList, true)
        newGroupNode.type = "group"
        newGroupNode.child[1] = bodyNode
        bodyNode = newGroupNode
    end
    if  not conditionNode or conditionNode.type ~= "group" then
        local newGroupNode = OvaleAST:NewNode(nodeList, true)
        newGroupNode.type = "group"
        newGroupNode.child[1] = conditionNode
        conditionNode = newGroupNode
    end
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
        bodyNode = OvaleAST:NewNode(nodeList)
        bodyNode.name = bodyName
        bodyNode.lowername = lower(bodyName)
        bodyNode.type = "custom_function"
        bodyNode.func = bodyName
        bodyNode.asString = bodyName .. "()"
        conditionNode = OvaleAST:NewNode(nodeList)
        conditionNode.name = conditionName
        conditionNode.lowername = lower(conditionName)
        conditionNode.type = "custom_function"
        conditionNode.func = conditionName
        conditionNode.asString = conditionName .. "()"
    else
        local functionTag = annotation.functionTag[functionName]
        if  not functionTag then
            if find(functionName, "Bloodlust") then
                functionTag = "cd"
            elseif find(functionName, "GetInMeleeRange") then
                functionTag = "shortcd"
            elseif find(functionName, "InterruptActions") then
                functionTag = "cd"
            elseif find(functionName, "SummonPet") then
                functionTag = "shortcd"
            elseif find(functionName, "UseItemActions") then
                functionTag = "cd"
            elseif find(functionName, "UsePotion") then
                functionTag = "cd"
            end
        end
        if functionTag then
            if functionTag == tag then
                bodyNode = node
            end
        else
            __exports.OvaleSimulationCraft:Print("Warning: Unable to determine tag for '%s()'.", node.name)
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
                insert(conditionList, 1, conditionNode)
                insert(remainderList, 1, conditionNode)
            end
            if bodyNode then
                if #conditionList == 0 then
                    insert(bodyList, 1, bodyNode)
                elseif #bodyList == 0 then
                    wipe(conditionList)
                    insert(bodyList, 1, bodyNode)
                else
                    local unlessNode = OvaleAST:NewNode(nodeList, true)
                    unlessNode.type = "unless"
                    unlessNode.child[1] = ConcatenatedConditionNode(conditionList, nodeList, annotation)
                    unlessNode.child[2] = ConcatenatedBodyNode(bodyList, nodeList, annotation)
                    wipe(bodyList)
                    wipe(conditionList)
                    insert(bodyList, 1, unlessNode)
                    local commentNode = OvaleAST:NewNode(nodeList)
                    commentNode.type = "comment"
                    insert(bodyList, 1, commentNode)
                    insert(bodyList, 1, bodyNode)
                end
                if index > 0 then
                    childNode = node.child[index]
                    if childNode.type ~= "comment" then
                        bodyNode, conditionNode = SplitByTag(tag, childNode, nodeList, annotation)
                        if  not bodyNode and index > 1 then
                            local start = index - 1
                            for k = index - 1, 1, -1 do
                                childNode = node.child[k]
                                if childNode.type == "comment" then
                                    if childNode.comment and sub(childNode.comment, 1, 5) == "pool_" then
                                        start = k
                                        break
                                    end
                                else
                                    break
                                end
                            end
                            if start < index - 1 then
                                for k = index - 1, start, -1 do
                                    insert(bodyList, 1, node.child[k])
                                end
                                index = start - 1
                            end
                        end
                    end
                end
                while index > 0 do
                    childNode = node.child[index]
                    if childNode.type == "comment" then
                        insert(bodyList, 1, childNode)
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
            local unlessNode = OvaleAST:NewNode(nodeList, true)
            unlessNode.type = "unless"
            unlessNode.child[1] = conditionNode
            unlessNode.child[2] = bodyNode
            local groupNode = OvaleAST:NewNode(nodeList, true)
            groupNode.type = "group"
            groupNode.child[1] = unlessNode
            bodyNode = groupNode
        end
        conditionNode = remainderNode
    end
    return bodyNode, conditionNode
end

SplitByTagIf = function(tag, node, nodeList, annotation)
    local bodyNode, conditionNode = SplitByTag(tag, node.child[2], nodeList, annotation)
    if conditionNode then
        local lhsNode = node.child[1]
        local rhsNode = conditionNode
        if node.type == "unless" then
            lhsNode = NewLogicalNode("not", lhsNode, nil, nodeList)
        end
        local andNode = NewLogicalNode("and", lhsNode, rhsNode, nodeList)
        conditionNode = andNode
    end
    if bodyNode then
        local ifNode = OvaleAST:NewNode(nodeList, true)
        ifNode.type = node.type
        ifNode.child[1] = node.child[1]
        ifNode.child[2] = bodyNode
        bodyNode = ifNode
    end
    return bodyNode, conditionNode
end

SplitByTagState = function(tag, node, nodeList, annotation)
    return node, nil
end

do
    SPLIT_BY_TAG_VISITOR = {
        ["action"] = SplitByTagAction,
        ["add_function"] = SplitByTagAddFunction,
        ["custom_function"] = SplitByTagCustomFunction,
        ["group"] = SplitByTagGroup,
        ["if"] = SplitByTagIf,
        ["state"] = SplitByTagState,
        ["unless"] = SplitByTagIf
    }
end
local EMIT_VISITOR = nil
local Emit = nil
local EmitAction = nil
local EmitActionList = nil
local EmitExpression = nil
local EmitFunction = nil
local EmitNumber = nil
local EmitOperand = nil
local EmitOperandAction = nil
local EmitOperandActiveDot = nil
local EmitOperandArtifact = nil
local EmitOperandAzerite = nil
local EmitOperandBuff = nil
local EmitOperandCharacter = nil
local EmitOperandCooldown = nil
local EmitOperandDisease = nil
local EmitOperandDot = nil
local EmitOperandGlyph = nil
local EmitOperandPet = nil
local EmitOperandPreviousSpell = nil
local EmitOperandRefresh = nil
local EmitOperandRaidEvent = nil
local EmitOperandRace = nil
local EmitOperandRune = nil
local EmitOperandSeal = nil
local EmitOperandSetBonus = nil
local EmitOperandSpecial = nil
local EmitOperandTalent = nil
local EmitOperandTarget = nil
local EmitOperandTotem = nil
local EmitOperandTrinket = nil
local EmitOperandVariable = nil
Emit = function(parseNode, nodeList, annotation, action)
    local visitor = EMIT_VISITOR[parseNode.type]
    if  not visitor then
        __exports.OvaleSimulationCraft:Error("Unable to emit node of type '%s'.", parseNode.type)
    else
        return visitor(parseNode, nodeList, annotation, action)
    end
end

local EmitModifier = function(modifier, parseNode, nodeList, annotation, action)
    local node, code
    local className = annotation.class
    local specialization = annotation.specialization
    if modifier == "if" then
        node = Emit(parseNode, nodeList, annotation, action)
    elseif modifier == "target_if" then
        node = Emit(parseNode, nodeList, annotation, action)
    elseif modifier == "five_stacks" and action == "focus_fire" then
        local value = tonumber(Unparse(parseNode))
        if value == 1 then
            local buffName = "pet_frenzy_buff"
            AddSymbol(annotation, buffName)
            code = format("pet.BuffStacks(%s) >= 5", buffName)
        end
    elseif modifier == "line_cd" then
        if  not SPECIAL_ACTION[action] then
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
    elseif modifier == "precombat" then
        local value = tonumber(Unparse(parseNode))
        if value == 1 then
            code = "not InCombat()"
        else
            code = "InCombat()"
        end
    elseif modifier == "sync" then
        local name = Unparse(parseNode)
        if name == "whirlwind_mh" then
            name = "whirlwind"
        end
        node = annotation.astAnnotation and annotation.astAnnotation.sync and annotation.astAnnotation.sync[name]
        if  not node then
            local syncParseNode = annotation.sync[name]
            if syncParseNode then
                local syncActionNode = EmitAction(syncParseNode, nodeList, annotation, action)
                local syncActionType = syncActionNode.type
                if syncActionType == "action" then
                    node = syncActionNode
                elseif syncActionType == "custom_function" then
                    node = syncActionNode
                elseif syncActionType == "if" or syncActionType == "unless" then
                    local lhsNode = syncActionNode.child[1]
                    if syncActionType == "unless" then
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
                    __exports.OvaleSimulationCraft:Print("Warning: Unable to emit action for 'sync=%s'.", name)
                    name = Disambiguate(annotation, name, className, specialization)
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
    if  not node and code then
        annotation.astAnnotation = annotation.astAnnotation or {}
        node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
    end
    return node
end

local EmitConditionNode = function(nodeList, bodyNode, conditionNode, parseNode, annotation, action)
    local extraConditionNode = conditionNode
    conditionNode = nil
    for modifier, expressionNode in pairs(parseNode.child) do
        local rhsNode = EmitModifier(modifier, expressionNode, nodeList, annotation, action)
        if rhsNode then
            if  not conditionNode then
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

local function EmitNamedVariable(name, nodeList, annotation, modifier, parseNode, action, conditionNode)
    if  not annotation.variable then
        annotation.variable = {}
    end
    local node = annotation.variable[name]
    local group
    if  not node then
        node = OvaleAST:NewNode(nodeList, true)
        annotation.variable[name] = node
        node.type = "add_function"
        node.name = name
        group = OvaleAST:NewNode(nodeList, true)
        group.type = "group"
        node.child[1] = group
    else
        group = node.child[1]
    end
    annotation.currentVariable = node
    local value = Emit(modifier.value, nodeList, annotation, action)
    local newNode = EmitConditionNode(nodeList, value, conditionNode or nil, parseNode, annotation, action)
    if newNode.type == "if" then
        insert(group.child, 1, newNode)
    else
        insert(group.child, newNode)
    end
    annotation.currentVariable = nil
end
local function EmitVariableMin(name, nodeList, annotation, modifier, parseNode, action)
    EmitNamedVariable(name .. "_min", nodeList, annotation, modifier, parseNode, action)
    local valueNode = annotation.variable[name]
    valueNode.name = name .. "_value"
    annotation.variable[valueNode.name] = valueNode
    local bodyCode = format("AddFunction %s { if %s_value() > %s_min() %s_value() %s_min() }", name, name, name, name, name)
    local node = OvaleAST:ParseCode("add_function", bodyCode, nodeList, annotation.astAnnotation)
    annotation.variable[name] = node
end
local function EmitVariableMax(name, nodeList, annotation, modifier, parseNode, action)
    EmitNamedVariable(name .. "_max", nodeList, annotation, modifier, parseNode, action)
    local valueNode = annotation.variable[name]
    valueNode.name = name .. "_value"
    annotation.variable[valueNode.name] = valueNode
    local bodyCode = format("AddFunction %s { if %s_value() < %s_max() %s_value() %s_max() }", name, name, name, name, name)
    local node = OvaleAST:ParseCode("add_function", bodyCode, nodeList, annotation.astAnnotation)
    annotation.variable[name] = node
end
local function EmitVariableAdd(name, nodeList, annotation, modifier, parseNode, action)
    local valueNode = annotation.variable[name]
    if valueNode then
        return 
    end
    EmitNamedVariable(name, nodeList, annotation, modifier, parseNode, action)
end
local function EmitVariableIf(name, nodeList, annotation, modifier, parseNode, action)
    local node = annotation.variable[name]
    local group
    if  not node then
        node = OvaleAST:NewNode(nodeList, true)
        annotation.variable[name] = node
        node.type = "add_function"
        node.name = name
        group = OvaleAST:NewNode(nodeList, true)
        group.type = "group"
        node.child[1] = group
    else
        group = node.child[1]
    end
    annotation.currentVariable = node
    local ifNode = OvaleAST:NewNode(nodeList, true)
    ifNode.type = "if"
    ifNode.child[1] = Emit(modifier.condition, nodeList, annotation)
    ifNode.child[2] = Emit(modifier.value, nodeList, annotation)
    insert(group.child, ifNode)
    local elseNode = OvaleAST:NewNode(nodeList, true)
    elseNode.type = "unless"
    elseNode.child[1] = ifNode.child[1]
    elseNode.child[2] = Emit(modifier.value_else, nodeList, annotation)
    insert(group.child, elseNode)
    annotation.currentVariable = nil
end
local function EmitVariable(nodeList, annotation, modifier, parseNode, action, conditionNode)
    if  not annotation.variable then
        annotation.variable = {}
    end
    local op = (modifier.op and Unparse(modifier.op)) or "set"
    local name = Unparse(modifier.name)
    if match(name, "^%d") then
        name = "_" .. name
    end
    if op == "min" then
        EmitVariableMin(name, nodeList, annotation, modifier, parseNode, action)
    elseif op == "max" then
        EmitVariableMax(name, nodeList, annotation, modifier, parseNode, action)
    elseif op == "add" then
        EmitVariableAdd(name, nodeList, annotation, modifier, parseNode, action)
    elseif op == "set" then
        EmitNamedVariable(name, nodeList, annotation, modifier, parseNode, action, conditionNode)
    elseif op == "setif" then
        EmitVariableIf(name, nodeList, annotation, modifier, parseNode, action)
    elseif op == "reset" then
    else
        __exports.OvaleSimulationCraft:Error("Unknown variable operator '%s'.", op)
    end
end
local checkOptionalSkill = function(action, className, specialization)
    local data = OPTIONAL_SKILLS[action]
    if  not data then
        return false
    end
    if data.specialization and data.specialization ~= specialization then
        return false
    end
    if data.class and data.class ~= className then
        return false
    end
    return true
end

EmitAction = function(parseNode, nodeList, annotation)
    local node
    local canonicalizedName = lower(gsub(parseNode.name, ":", "_"))
    local className = annotation.class
    local specialization = annotation.specialization
    local camelSpecialization = CamelSpecialization(annotation)
    local role = annotation.role
    local action, type = Disambiguate(annotation, canonicalizedName, className, specialization, "Spell")
    local bodyNode
    local conditionNode
    if action == "auto_attack" and  not annotation.melee then
    elseif action == "auto_shot" then
    elseif action == "choose_target" then
    elseif action == "augmentation" or action == "flask" or action == "food" then
    elseif action == "snapshot_stats" then
    else
        local bodyCode, conditionCode
        local expressionType = "expression"
        local modifier = parseNode.child
        local isSpellAction = true
        if className == "DEATHKNIGHT" and action == "antimagic_shell" then
            conditionCode = "IncomingDamage(1.5 magic=1) > 0"
        elseif className == "DEATHKNIGHT" and action == "mind_freeze" then
            bodyCode = camelSpecialization .. "InterruptActions()"
            annotation[action] = className
            annotation.interrupt = className
            isSpellAction = false
        elseif className == "DEMONHUNTER" and action == "disrupt" then
            bodyCode = camelSpecialization .. "InterruptActions()"
            annotation[action] = className
            annotation.interrupt = className
            isSpellAction = false
        elseif className == "DRUID" and action == "pulverize" then
            local debuffName = "thrash_bear_debuff"
            AddSymbol(annotation, debuffName)
            conditionCode = format("target.DebuffGain(%s) <= BaseDuration(%s)", debuffName, debuffName)
        elseif className == "DRUID" and specialization == "guardian" and action == "rejuvenation" then
            local spellName = "enhanced_rejuvenation"
            AddSymbol(annotation, spellName)
            conditionCode = format("SpellKnown(%s)", spellName)
        elseif className == "DRUID" and (action == "skull_bash" or action == "solar_beam") then
            bodyCode = camelSpecialization .. "InterruptActions()"
            annotation[action] = className
            annotation.interrupt = className
            isSpellAction = false
        elseif className == "DRUID" and action == "wild_charge" then
            bodyCode = camelSpecialization .. "GetInMeleeRange()"
            annotation[action] = className
            isSpellAction = false
        elseif className == "DRUID" and action == "new_moon" then
            conditionCode = "not SpellKnown(half_moon) and not SpellKnown(full_moon)"
            AddSymbol(annotation, "half_moon")
            AddSymbol(annotation, "full_moon")
        elseif className == "DRUID" and action == "half_moon" then
            conditionCode = "SpellKnown(half_moon)"
        elseif className == "DRUID" and action == "full_moon" then
            conditionCode = "SpellKnown(full_moon)"
        elseif className == "HUNTER" and (action == "muzzle" or action == "counter_shot") then
            bodyCode = camelSpecialization .. "InterruptActions()"
            annotation[action] = className
            annotation.interrupt = className
            isSpellAction = false
        elseif className == "HUNTER" and action == "exotic_munitions" then
            if modifier.ammo_type then
                local name = Unparse(modifier.ammo_type)
                action = name .. "_ammo"
                local buffName = "exotic_munitions_buff"
                AddSymbol(annotation, buffName)
                conditionCode = format("BuffRemaining(%s) < 1200", buffName)
            else
                isSpellAction = false
            end
        elseif className == "HUNTER" and action == "kill_command" then
            conditionCode = "pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned()"
        elseif className == "MAGE" and action == "arcane_brilliance" then
            conditionCode = "BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1)"
        elseif className == "MAGE" and action == "counterspell" then
            bodyCode = camelSpecialization .. "InterruptActions()"
            annotation[action] = className
            annotation.interrupt = className
            isSpellAction = false
        elseif className == "MAGE" and find(action, "pet_") then
            conditionCode = "pet.Present()"
        elseif className == "MAGE" and (action == "start_burn_phase" or action == "start_pyro_chain" or action == "stop_burn_phase" or action == "stop_pyro_chain") then
            local stateAction, stateVariable = match(action, "([^_]+)_(.*)")
            local value = (stateAction == "start") and 1 or 0
            if value == 0 then
                conditionCode = format("GetState(%s) > 0", stateVariable)
            else
                conditionCode = format("not GetState(%s) > 0", stateVariable)
            end
            bodyCode = format("SetState(%s %d)", stateVariable, value)
            isSpellAction = false
        elseif className == "MAGE" and action == "time_warp" then
            conditionCode = "CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1)"
            annotation[action] = className
        elseif className == "MAGE" and action == "water_elemental" then
            conditionCode = "not pet.Present()"
        elseif className == "MONK" and action == "chi_sphere" then
            isSpellAction = false
        elseif className == "MONK" and action == "gift_of_the_ox" then
            isSpellAction = false
        elseif className == "MONK" and action == "nimble_brew" then
            conditionCode = "IsFeared() or IsRooted() or IsStunned()"
        elseif className == "MONK" and action == "spear_hand_strike" then
            bodyCode = camelSpecialization .. "InterruptActions()"
            annotation[action] = className
            annotation.interrupt = className
            isSpellAction = false
        elseif className == "MONK" and action == "storm_earth_and_fire" then
            conditionCode = "CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff)"
            annotation[action] = className
        elseif className == "MONK" and action == "touch_of_death" then
            conditionCode = "(not CheckBoxOn(opt_touch_of_death_on_elite_only) or (not UnitInRaid() and target.Classification(elite)) or target.Classification(worldboss)) or not BuffExpires(hidden_masters_forbidden_touch_buff)"
            annotation[action] = className
            annotation.opt_touch_of_death_on_elite_only = "MONK"
            AddSymbol(annotation, "hidden_masters_forbidden_touch_buff")
        elseif className == "MONK" and action == "whirling_dragon_punch" then
            conditionCode = "SpellCooldown(fists_of_fury)>0 and SpellCooldown(rising_sun_kick)>0"
        elseif className == "PALADIN" and action == "blessing_of_kings" then
            conditionCode = "BuffExpires(mastery_buff)"
        elseif className == "PALADIN" and action == "judgment" then
            if modifier.cycle_targets then
                AddSymbol(annotation, action)
                bodyCode = "Spell(" .. action .. " text=double)"
                isSpellAction = false
            end
        elseif className == "PALADIN" and action == "rebuke" then
            bodyCode = camelSpecialization .. "InterruptActions()"
            annotation[action] = className
            annotation.interrupt = className
            isSpellAction = false
        elseif className == "PALADIN" and specialization == "protection" and action == "arcane_torrent_holy" then
            isSpellAction = false
        elseif className == "PALADIN" and action == "righteous_fury" then
            conditionCode = "CheckBoxOn(opt_righteous_fury_check)"
            annotation[action] = className
        elseif className == "PRIEST" and (action == "silence" or action == "mind_bomb") then
            bodyCode = camelSpecialization .. "InterruptActions()"
            annotation[action] = className
            annotation.interrupt = className
            isSpellAction = false
        elseif className == "ROGUE" and action == "adrenaline_rush" then
            conditionCode = "EnergyDeficit() > 1"
        elseif className == "ROGUE" and action == "apply_poison" then
            if modifier.lethal then
                local name = Unparse(modifier.lethal)
                action = name .. "_poison"
                local buffName = "lethal_poison_buff"
                AddSymbol(annotation, buffName)
                conditionCode = format("BuffRemaining(%s) < 1200", buffName)
            else
                isSpellAction = false
            end
        elseif className == "ROGUE" and action == "between_the_eyes" then
            bodyCode = "Spell(between_the_eyes text=BTE)"
        elseif className == "ROGUE" and specialization == "combat" and action == "blade_flurry" then
            annotation.blade_flurry = className
            conditionCode = "CheckBoxOn(opt_blade_flurry)"
        elseif className == "ROGUE" and action == "cancel_autoattack" then
            isSpellAction = false
        elseif className == "ROGUE" and action == "kick" then
            bodyCode = camelSpecialization .. "InterruptActions()"
            annotation[action] = className
            annotation.interrupt = className
            isSpellAction = false
        elseif className == "ROGUE" and action == "pistol_shot" then
            bodyCode = "Spell(pistol_shot text=PS)"
        elseif className == "ROGUE" and action == "premeditation" then
            conditionCode = "ComboPoints() < 5"
        elseif className == "ROGUE" and specialization == "combat" and action == "slice_and_dice" then
            local buffName = "slice_and_dice_buff"
            AddSymbol(annotation, buffName)
            conditionCode = format("BuffRemaining(%s) < BaseDuration(%s)", buffName, buffName)
        elseif className == "ROGUE" and (specialization == "assassination" or specialization == "combat") and action == "vanish" then
            annotation.vanish = className
            conditionCode = format("CheckBoxOn(opt_vanish)", action)
        elseif className == "SHAMAN" and sub(action, 1, 11) == "ascendance_" then
            local buffName = action .. "_buff"
            AddSymbol(annotation, buffName)
            conditionCode = format("BuffExpires(%s)", buffName)
        elseif className == "SHAMAN" and action == "bloodlust" then
            bodyCode = camelSpecialization .. "Bloodlust()"
            annotation[action] = className
            isSpellAction = false
        elseif className == "SHAMAN" and action == "magma_totem" then
            local spellName = "primal_strike"
            AddSymbol(annotation, spellName)
            conditionCode = format("target.InRange(%s)", spellName)
        elseif className == "SHAMAN" and action == "totem_mastery" then
            conditionCode = "(not TotemPresent(totem_mastery) or InCombat()) and Speed() == 0"
            AddSymbol(annotation, "totem_mastery")
        elseif className == "SHAMAN" and action == "wind_shear" then
            bodyCode = camelSpecialization .. "InterruptActions()"
            annotation[action] = className
            annotation.interrupt = className
            isSpellAction = false
        elseif className == "WARLOCK" and action == "cancel_metamorphosis" then
            local spellName = "metamorphosis"
            local buffName = "metamorphosis_buff"
            AddSymbol(annotation, spellName)
            AddSymbol(annotation, buffName)
            bodyCode = format("Spell(%s text=cancel)", spellName)
            conditionCode = format("BuffPresent(%s)", buffName)
            isSpellAction = false
        elseif className == "WARLOCK" and action == "felguard_felstorm" then
            conditionCode = "pet.Present() and pet.CreatureFamily(Felguard)"
        elseif className == "WARLOCK" and action == "grimoire_of_sacrifice" then
            conditionCode = "pet.Present()"
        elseif className == "WARLOCK" and action == "havoc" then
            conditionCode = "Enemies() > 1"
        elseif className == "WARLOCK" and action == "service_pet" then
            if annotation.pet then
                local spellName = "service_" .. annotation.pet
                AddSymbol(annotation, spellName)
                bodyCode = format("Spell(%s)", spellName)
            else
                bodyCode = "Texture(spell_nature_removecurse help=ServicePet)"
            end
            isSpellAction = false
        elseif className == "WARLOCK" and action == "summon_pet" then
            if annotation.pet then
                local spellName = "summon_" .. annotation.pet
                AddSymbol(annotation, spellName)
                bodyCode = format("Spell(%s)", spellName)
            else
                bodyCode = "Texture(spell_nature_removecurse help=L(summon_pet))"
            end
            conditionCode = "not pet.Present()"
            isSpellAction = false
        elseif className == "WARLOCK" and action == "wrathguard_wrathstorm" then
            conditionCode = "pet.Present() and pet.CreatureFamily(Wrathguard)"
        elseif className == "WARRIOR" and action == "battle_shout" and role == "tank" then
            conditionCode = "BuffExpires(stamina_buff)"
        elseif className == "WARRIOR" and action == "charge" then
            conditionCode = "CheckBoxOn(opt_melee_range) and target.InRange(charge)"
        elseif className == "WARRIOR" and action == "commanding_shout" and role == "attack" then
            conditionCode = "BuffExpires(attack_power_multiplier_buff)"
        elseif className == "WARRIOR" and action == "enraged_regeneration" then
            conditionCode = "HealthPercent() < 80"
        elseif className == "WARRIOR" and sub(action, 1, 7) == "execute" then
            if modifier.target then
                local target = tonumber(Unparse(modifier.target))
                if target then
                    isSpellAction = false
                end
            end
        elseif className == "WARRIOR" and action == "heroic_charge" then
            isSpellAction = false
        elseif className == "WARRIOR" and action == "heroic_leap" then
            conditionCode = "CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40)"
        elseif className == "WARRIOR" and action == "pummel" then
            bodyCode = camelSpecialization .. "InterruptActions()"
            annotation[action] = className
            annotation.interrupt = className
            isSpellAction = false
        elseif action == "auto_attack" then
            bodyCode = camelSpecialization .. "GetInMeleeRange()"
            isSpellAction = false
        elseif className == "DEMONHUNTER" and action == "metamorphosis_havoc" then
            conditionCode = "not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight()"
            annotation.opt_meta_only_during_boss = "DEMONHUNTER"
        elseif checkOptionalSkill(action, className, specialization) then
            annotation[action] = className
            conditionCode = "CheckBoxOn(opt_" .. action .. ")"
        elseif action == "variable" then
            EmitVariable(nodeList, annotation, modifier, parseNode, action, conditionNode)
            isSpellAction = false
        elseif action == "call_action_list" or action == "run_action_list" or action == "swap_action_list" then
            if modifier.name then
                local name = Unparse(modifier.name)
                local functionName = OvaleFunctionName(name, annotation)
                bodyCode = functionName .. "()"
                if className == "MAGE" and specialization == "arcane" and (name == "burn" or name == "init_burn") then
                    conditionCode = "CheckBoxOn(opt_arcane_mage_burn_phase)"
                    annotation.opt_arcane_mage_burn_phase = className
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
        elseif action == "pool_resource" then
            bodyNode = OvaleAST:NewNode(nodeList)
            bodyNode.type = "simc_pool_resource"
            bodyNode.for_next = (modifier.for_next ~= nil)
            if modifier.extra_amount then
                bodyNode.extra_amount = tonumber(Unparse(modifier.extra_amount))
            end
            isSpellAction = false
        elseif action == "potion" then
            local name = (modifier.name and Unparse(modifier.name)) or annotation.consumables["potion"]
            if name then
                name = Disambiguate(annotation, name, className, specialization, "item")
                bodyCode = format("Item(%s usable=1)", name)
                conditionCode = "CheckBoxOn(opt_use_consumables) and target.Classification(worldboss)"
                annotation.opt_use_consumables = className
                AddSymbol(annotation, format("%s", name))
                isSpellAction = false
            end
        elseif action == "stance" then
            if modifier.choose then
                local name = Unparse(modifier.choose)
                if className == "MONK" then
                    action = "stance_of_the_" .. name
                elseif className == "WARRIOR" then
                    action = name .. "_stance"
                else
                    action = name
                end
            else
                isSpellAction = false
            end
        elseif action == "summon_pet" then
            bodyCode = camelSpecialization .. "SummonPet()"
            annotation[action] = className
            isSpellAction = false
        elseif action == "use_items" then
            bodyCode = camelSpecialization .. "UseItemActions()"
            annotation["use_item"] = true
            isSpellAction = false
        elseif action == "use_item" then
            local legendaryRing = nil
            if modifier.slot then
                local slot = Unparse(modifier.slot)
                if match(slot, "finger") then
                    legendaryRing = Disambiguate(annotation, "legendary_ring", className, specialization)
                end
            elseif modifier.name then
                local name = Unparse(modifier.name)
                name = Disambiguate(annotation, name, className, specialization)
                if match(name, "legendary_ring") then
                    legendaryRing = name
                end
            end
            if legendaryRing then
                conditionCode = format("CheckBoxOn(opt_%s)", legendaryRing)
                bodyCode = format("Item(%s usable=1)", legendaryRing)
                AddSymbol(annotation, legendaryRing)
                annotation.use_legendary_ring = legendaryRing
            else
                bodyCode = camelSpecialization .. "UseItemActions()"
                annotation[action] = true
            end
            isSpellAction = false
        elseif action == "wait" then
            if modifier.sec then
                local seconds = tonumber(Unparse(modifier.sec))
                if seconds then
                else
                    bodyNode = OvaleAST:NewNode(nodeList)
                    bodyNode.type = "simc_wait"
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
                    bodyCode = format("%s(%s text=%s)", type, action, actionTarget)
                end
            end
            bodyCode = bodyCode or type .. "(" .. action .. ")"
        end
        annotation.astAnnotation = annotation.astAnnotation or {}
        if  not bodyNode and bodyCode then
            bodyNode = OvaleAST:ParseCode(expressionType, bodyCode, nodeList, annotation.astAnnotation)
        end
        if  not conditionNode and conditionCode then
            conditionNode = OvaleAST:ParseCode(expressionType, conditionCode, nodeList, annotation.astAnnotation)
        end
        if bodyNode then
            node = EmitConditionNode(nodeList, bodyNode, conditionNode, parseNode, annotation, action)
        end
    end
    return node
end

EmitActionList = function(parseNode, nodeList, annotation)
    local groupNode = OvaleAST:NewNode(nodeList, true)
    groupNode.type = "group"
    local child = groupNode.child
    local poolResourceNode
    local emit = true
    for _, actionNode in ipairs(parseNode.child) do
        local commentNode = OvaleAST:NewNode(nodeList)
        commentNode.type = "comment"
        commentNode.comment = actionNode.action
        child[#child + 1] = commentNode
        if emit then
            local statementNode = EmitAction(actionNode, nodeList, annotation)
            if statementNode then
                if statementNode.type == "simc_pool_resource" then
                    local powerType = OvalePower.POOLED_RESOURCE[annotation.class]
                    if powerType then
                        if statementNode.for_next then
                            poolResourceNode = statementNode
                            poolResourceNode.powerType = powerType
                        else
                            emit = false
                        end
                    end
                elseif poolResourceNode then
                    child[#child + 1] = statementNode
                    local bodyNode
                    local poolingConditionNode
                    if statementNode.child then
                        poolingConditionNode = statementNode.child[1]
                        bodyNode = statementNode.child[2]
                    else
                        bodyNode = statementNode
                    end
                    local powerType = CamelCase(poolResourceNode.powerType)
                    local extra_amount = poolResourceNode.extra_amount
                    if extra_amount and poolingConditionNode then
                        local code = OvaleAST:Unparse(poolingConditionNode)
                        local extraAmountPattern = powerType .. "%(%) >= [%d.]+"
                        local replaceString = format("True(pool_%s %d)", poolResourceNode.powerType, extra_amount)
                        code = gsub(code, extraAmountPattern, replaceString)
                        poolingConditionNode = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    end
                    if bodyNode.type == "action" and bodyNode.rawPositionalParams and bodyNode.rawPositionalParams[1] then
                        local name = OvaleAST:Unparse(bodyNode.rawPositionalParams[1])
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
                elseif statementNode.simc_wait then
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
                    if operator == "-" and isValueNode(rhsNode) then
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
                    if  not node and code then
                        annotation.astAnnotation = annotation.astAnnotation or {}
                        node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
                    end
                end
            elseif (parseNode.operator == "=" or parseNode.operator == "!=") and (parseNode.child[1].name == "target" or parseNode.child[1].name == "current_target") then
                local rhsNode = parseNode.child[2]
                local name = rhsNode.name
                if find(name, "^[%a_]+%.") then
                    name = match(name, "^[%a_]+%.([%a_]+)")
                end
                local code
                if parseNode.operator == "=" then
                    if name == "sim_target" then
                        code = "True(target_is_sim_target)"
                    else
                        code = format("target.Name(%s)", name)
                        AddSymbol(annotation, name)
                    end
                else
                    code = format("not target.Name(%s)", name)
                    AddSymbol(annotation, name)
                end
                annotation.astAnnotation = annotation.astAnnotation or {}
                node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
            elseif (parseNode.operator == "=" or parseNode.operator == "!=") and parseNode.child[1].name == "sim_target" then
                local code
                if parseNode.operator == "=" then
                    code = "True(target_is_sim_target)"
                else
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
                    msg = MakeString("Warning: %s operator '%s' right failed.", parseNode.type, parseNode.operator)
                elseif rhsNode then
                    msg = MakeString("Warning: %s operator '%s' left failed.", parseNode.type, parseNode.operator)
                else
                    msg = MakeString("Warning: %s operator '%s' left and right failed.", parseNode.type, parseNode.operator)
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
        msg = msg or MakeString("Warning: Operator '%s' is not implemented.", parseNode.operator)
        __exports.OvaleSimulationCraft:Print(msg)
        local stringNode = OvaleAST:NewNode(nodeList)
        stringNode.type = "string"
        stringNode.value = "FIXME_" .. parseNode.operator
        return stringNode
    end
    return node
end

EmitFunction = function(parseNode, nodeList, annotation, action)
    local node
    if parseNode.name == "ceil" or parseNode.name == "floor" then
        node = EmitExpression(parseNode.child[1], nodeList, annotation, action)
    else
        __exports.OvaleSimulationCraft:Print("Warning: Function '%s' is not implemented.", parseNode.name)
        node = OvaleAST:NewNode(nodeList)
        node.type = "variable"
        node.name = "FIXME_" .. parseNode.name
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
    local token = match(operand, OPERAND_TOKEN_PATTERN)
    local target
    if token == "target" then
        ok, node = EmitOperandTarget(operand, parseNode, nodeList, annotation, action)
        if  not ok then
            target = token
            operand = sub(operand, len(target) + 2)
            token = match(operand, OPERAND_TOKEN_PATTERN)
        end
    end
    if  not ok then
        ok, node = EmitOperandRune(operand, parseNode, nodeList, annotation, action)
    end
    if  not ok then
        ok, node = EmitOperandSpecial(operand, parseNode, nodeList, annotation, action, target)
    end
    if  not ok then
        ok, node = EmitOperandRaidEvent(operand, parseNode, nodeList, annotation, action)
    end
    if  not ok then
        ok, node = EmitOperandRace(operand, parseNode, nodeList, annotation, action)
    end
    if  not ok then
        ok, node = EmitOperandAction(operand, parseNode, nodeList, annotation, action, target)
    end
    if  not ok then
        ok, node = EmitOperandCharacter(operand, parseNode, nodeList, annotation, action, target)
    end
    if  not ok then
        if token == "active_dot" then
            target = target or "target"
            ok, node = EmitOperandActiveDot(operand, parseNode, nodeList, annotation, action, target)
        elseif token == "aura" then
            ok, node = EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target)
        elseif token == "artifact" then
            ok, node = EmitOperandArtifact(operand, parseNode, nodeList, annotation, action, target)
        elseif token == "azerite" then
            ok, node = EmitOperandAzerite(operand, parseNode, nodeList, annotation, action, target)
        elseif token == "buff" then
            ok, node = EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target)
        elseif token == "consumable" then
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
        elseif token == "ground_aoe" then
            ok, node = EmitOperandGroundAoe(operand, parseNode, nodeList, annotation, action)
        end
    end
    if  not ok then
        __exports.OvaleSimulationCraft:Print("Warning: Variable '%s' is not implemented.", parseNode.name)
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
    if sub(operand, 1, 7) == "action." then
        local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
        tokenIterator()
        name = tokenIterator()
        property = tokenIterator()
    else
        name = action
        property = operand
    end
    if  not name then
        return false, nil
    end
    local className, specialization = annotation.class, annotation.specialization
    name = Disambiguate(annotation, name, className, specialization)
    target = target and (target .. ".") or ""
    local buffName = name .. "_debuff"
    buffName = Disambiguate(annotation, buffName, className, specialization)
    local prefix = find(buffName, "_buff$") and "Buff" or "Debuff"
    local buffTarget = (prefix == "Debuff") and "target." or target
    local talentName = name .. "_talent"
    talentName = Disambiguate(annotation, talentName, className, specialization)
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
    elseif property == "duration" or property == "new_duration" then
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
        code = "True(miss_react)"
    elseif property == "persistent_multiplier" or property == "pmultiplier" then
        code = format("PersistentMultiplier(%s)", buffName)
    elseif property == "recharge_time" then
        code = format("SpellChargeCooldown(%s)", name)
    elseif property == "full_recharge_time" then
        code = format("SpellFullRecharge(%s)", name)
    elseif property == "remains" then
        if IsTotem(name) then
            code = format("TotemRemaining(%s)", name)
        else
            code = format("%s%sRemaining(%s)", buffTarget, prefix, buffName)
            symbol = buffName
        end
    elseif property == "shard_react" then
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
        code = format("CanCast(%s)", name)
    elseif property == "usable_in" then
        code = format("SpellCooldown(%s)", name)
    elseif property == "marks_next_gcd" then
        code = "0"
    else
        ok = false
    end
    if ok and code then
        if name == "call_action_list" and property ~= "gcd" then
            __exports.OvaleSimulationCraft:Print("Warning: dubious use of call_action_list in %s", code)
        end
        annotation.astAnnotation = annotation.astAnnotation or {}
        node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
        if  not SPECIAL_ACTION[symbol] then
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
        name = Disambiguate(annotation, name, annotation.class, annotation.specialization)
        local dotName = name .. "_debuff"
        dotName = Disambiguate(annotation, dotName, annotation.class, annotation.specialization)
        local prefix = find(dotName, "_buff$") and "Buff" or "Debuff"
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
        local code
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

EmitOperandAzerite = function(operand, parseNode, nodeList, annotation, action, target)
    local ok = true
    local node
    local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
    local token = tokenIterator()
    if token == "azerite" then
        local code
        local name = tokenIterator()
        local property = tokenIterator()
        if property == "rank" then
            code = format("AzeriteTraitRank(%s_trait)", name)
        elseif property == "enabled" then
            code = format("HasAzeriteTrait(%s_trait)", name)
        else
            ok = false
        end
        if ok and code then
            annotation.astAnnotation = annotation.astAnnotation or {}
            node = OvaleAST:ParseCode("expression", code, nodeList, annotation.astAnnotation)
            AddSymbol(annotation, name .. "_trait")
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
        buffName = Disambiguate(annotation, buffName, annotation.class, annotation.specialization)
        local target
        local prefix = find(buffName, "_buff$") and "Buff" or "Debuff"
        if prefix == "Debuff" then
            target = "target."
        else
            target = ""
        end
        local any = OvaleData.DEFAULT_SPELL_LIST[buffName] and " any=1" or ""
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
    if token == "aura" or token == "buff" or token == "debuff" or token == "consumable" then
        local name = tokenIterator()
        local property = tokenIterator()
        if (token == "consumable" and property == nil) then
            property = "remains"
        end
        name = Disambiguate(annotation, name, annotation.class, annotation.specialization)
        local buffName = (token == "debuff") and name .. "_debuff" or name .. "_buff"
        buffName = Disambiguate(annotation, buffName, annotation.class, annotation.specialization)
        local prefix = find(buffName, "_buff$") and "Buff" or "Debuff"
        local any = OvaleData.DEFAULT_SPELL_LIST[buffName] and " any=1" or ""
        target = target and (target .. ".") or ""
        if buffName == "dark_transformation_buff" and target == "" then
            target = "pet."
        end
        if buffName == "pet_beast_cleave_buff" and target == "" then
            target = "pet."
        end
        if buffName == "pet_frenzy_buff" and target == "" then
            target = "pet."
        end
        local code
        if property == "cooldown_remains" then
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
        elseif property == "improved" then
            code = format("%sImproved(%s%s)", prefix, buffName)
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
        ["active_enemies"] = "Enemies()",
        ["astral_power"] = "AstralPower()",
        ["astral_power.deficit"] = "AstralPowerDeficit()",
        ["blade_dance_worth_using"] = "0",
        ["blood.frac"] = "Rune(blood)",
        ["buff.movement.up"] = "Speed() > 0",
        ["buff.out_of_range.up"] = "not target.InRange()",
        ["bugs"] = "0",
        ["chi"] = "Chi()",
        ["chi.max"] = "MaxChi()",
        ["combo_points"] = "ComboPoints()",
        ["combo_points.deficit"] = "ComboPointsDeficit()",
        ["combo_points.max"] = "MaxComboPoints()",
        ["consecration.remains"] = "BuffRemaining(consecration)",
        ["cp_max_spend"] = "MaxComboPoints()",
        ["crit_pct_current"] = "SpellCritChance()",
        ["current_insanity_drain"] = "CurrentInsanityDrain()",
        ["darkglare_no_de"] = "NotDeDemons(darkglare)",
        ["death_and_decay.ticking"] = "BuffPresent(death_and_decay)",
        ["death_sweep_worth_using"] = "0",
        ["delay"] = "0",
        ["demonic_fury"] = "DemonicFury()",
        ["desired_targets"] = "Enemies(tagged=1)",
        ["doomguard_no_de"] = "NotDeDemons(doomguard)",
        ["dreadstalker_no_de"] = "NotDeDemons(dreadstalker)",
        ["dreadstalker_remaining_duration"] = "DemonDuration(dreadstalker)",
        ["eclipse_change"] = "TimeToEclipse()",
        ["eclipse_energy"] = "EclipseEnergy()",
        ["enemies"] = "Enemies()",
        ["energy"] = "Energy()",
        ["energy.deficit"] = "EnergyDeficit()",
        ["energy.max"] = "MaxEnergy()",
        ["energy.regen"] = "EnergyRegenRate()",
        ["energy.time_to_max"] = "TimeToMaxEnergy()",
        ["feral_spirit.remains"] = "TotemRemaining(sprit_wolf)",
        ["finality"] = "HasArtifactTrait(finality)",
        ["focus"] = "Focus()",
        ["focus.deficit"] = "FocusDeficit()",
        ["focus.max"] = "MaxFocus()",
        ["focus.regen"] = "FocusRegenRate()",
        ["focus.time_to_max"] = "TimeToMaxFocus()",
        ["frost.frac"] = "Rune(frost)",
        ["fury"] = "Fury()",
        ["fury.deficit"] = "FuryDeficit()",
        ["health"] = "Health()",
        ["health.deficit"] = "HealthMissing()",
        ["health.max"] = "MaxHealth()",
        ["health.pct"] = "HealthPercent()",
        ["health.percent"] = "HealthPercent()",
        ["holy_power"] = "HolyPower()",
        ["infernal_no_de"] = "NotDeDemons(infernal)",
        ["insanity"] = "Insanity()",
        ["level"] = "Level()",
        ["lunar_max"] = "TimeToEclipse(lunar)",
        ["mana"] = "Mana()",
        ["mana.deficit"] = "ManaDeficit()",
        ["mana.max"] = "MaxMana()",
        ["mana.pct"] = "ManaPercent()",
        ["maelstrom"] = "Maelstrom()",
        ["nonexecute_actors_pct"] = "0",
        ["pain"] = "Pain()",
        ["pain.deficit"] = "PainDeficit()",
        ["pet_count"] = "Demons()",
        ["rage"] = "Rage()",
        ["rage.deficit"] = "RageDeficit()",
        ["rage.max"] = "MaxRage()",
        ["raid_event.adds.remains"] = "0",
        ["raw_haste_pct"] = "SpellCastSpeedPercent()",
        ["rtb_list.any.5"] = "BuffCount(roll_the_bones_buff more 4)",
        ["rtb_list.any.6"] = "BuffCount(roll_the_bones_buff more 5)",
        ["rune.deficit"] = "RuneDeficit()",
        ["runic_power"] = "RunicPower()",
        ["runic_power.deficit"] = "RunicPowerDeficit()",
        ["service_no_de"] = "0",
        ["shadow_orb"] = "ShadowOrbs()",
        ["sigil_placed"] = "SigilCharging(flame)",
        ["solar_max"] = "TimeToEclipse(solar)",
        ["soul_shard"] = "SoulShards()",
        ["soul_fragments"] = "SoulFragments()",
        ["ssw_refund_offset"] = "target.Distance() % 3 - 1",
        ["stat.mastery_rating"] = "MasteryRating()",
        ["stealthed"] = "Stealthed()",
        ["stealthed.all"] = "Stealthed()",
        ["stealthed.rogue"] = "Stealthed()",
        ["time"] = "TimeInCombat()",
        ["time_to_20pct"] = "TimeToHealthPercent(20)",
        ["time_to_die"] = "TimeToDie()",
        ["time_to_die.remains"] = "TimeToDie()",
        ["time_to_shard"] = "TimeToShard()",
        ["time_to_sht.4"] = "100",
        ["time_to_sht.5"] = "100",
        ["wild_imp_count"] = "Demons(wild_imp)",
        ["wild_imp_no_de"] = "NotDeDemons(wild_imp)",
        ["wild_imp_remaining_duration"] = "DemonDuration(wild_imp)"
    }
    EmitOperandCharacter = function(operand, parseNode, nodeList, annotation, action, target)
        local ok = true
        local node
        local className = annotation.class
        local specialization = annotation.specialization
        local camelSpecialization = CamelSpecialization(annotation)
        target = target and (target .. ".") or ""
        local code
        if CHARACTER_PROPERTY[operand] then
            code = target .. CHARACTER_PROPERTY[operand]
        elseif className == "MAGE" and operand == "incanters_flow_dir" then
            local name = "incanters_flow_buff"
            code = format("BuffDirection(%s)", name)
            AddSymbol(annotation, name)
        elseif className == "PALADIN" and operand == "time_to_hpg" then
            code = camelSpecialization .. "TimeToHPG()"
            if specialization == "holy" then
                annotation.time_to_hpg_heal = className
            elseif specialization == "protection" then
                annotation.time_to_hpg_tank = className
            elseif specialization == "retribution" then
                annotation.time_to_hpg_melee = className
            end
        elseif className == "PRIEST" and operand == "shadowy_apparitions_in_flight" then
            code = "1"
        elseif operand == "rtb_buffs" then
            code = "BuffCount(roll_the_bones_buff)"
        elseif className == "ROGUE" and operand == "anticipation_charges" then
            local name = "anticipation_buff"
            code = format("BuffStacks(%s)", name)
            AddSymbol(annotation, name)
        elseif sub(operand, 1, 22) == "active_enemies_within." then
            code = "Enemies()"
        elseif find(operand, "^incoming_damage_") then
            local _seconds, measure = match(operand, "^incoming_damage_([%d]+)(m?s?)$")
            local seconds = tonumber(_seconds)
            if measure == "ms" then
                seconds = seconds / 1000
            end
            if parseNode.asType == "boolean" then
                code = format("IncomingDamage(%f) > 0", seconds)
            else
                code = format("IncomingDamage(%f)", seconds)
            end
        elseif sub(operand, 1, 10) == "main_hand." then
            local weaponType = sub(operand, 11)
            if weaponType == "1h" then
                code = "HasWeapon(main type=one_handed)"
            elseif weaponType == "2h" then
                code = "HasWeapon(main type=two_handed)"
            end
        elseif operand == "mastery_value" then
            code = format("%sMasteryEffect() / 100", target)
        elseif operand == "position_front" then
            code = "False(position_front)"
        elseif sub(operand, 1, 5) == "role." then
            local role = match(operand, "^role%.([%w_]+)")
            if role and role == annotation.role then
                code = format("True(role_%s)", role)
            else
                code = format("False(role_%s)", role)
            end
        elseif operand == "spell_haste" or operand == "stat.spell_haste" then
            code = "100 / { 100 + SpellCastSpeedPercent() }"
        elseif operand == "attack_haste" or operand == "stat.attack_haste" then
            code = "100 / { 100 + MeleeAttackSpeedPercent() }"
        elseif sub(operand, 1, 13) == "spell_targets" then
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
        name, prefix = Disambiguate(annotation, name, annotation.class, annotation.specialization, "Spell")
        local code
        if property == "execute_time" then
            code = format("ExecuteTime(%s)", name)
        elseif property == "duration" then
            code = format("%sCooldownDuration(%s)", prefix, name)
        elseif property == "ready" then
            code = format("%sCooldown(%s) == 0", prefix, name)
        elseif property == "remains" or property == "adjusted_remains" then
            if parseNode.asType == "boolean" then
                code = format("%sCooldown(%s) > 0", prefix, name)
            else
                code = format("%sCooldown(%s)", prefix, name)
            end
        elseif property == "up" then
            code = format("not %sCooldown(%s) > 0", prefix, name)
        elseif property == "charges" then
            if parseNode.asType == "boolean" then
                code = format("%sCharges(%s) > 0", prefix, name)
            else
                code = format("%sCharges(%s)", prefix, name)
            end
        elseif property == "charges_fractional" then
            code = format("%sCharges(%s count=0)", prefix, name)
        elseif property == "max_charges" then
            code = format("%sMaxCharges(%s)", prefix, name)
        elseif property == "full_recharge_time" then
            code = format("%sCooldown(%s)", prefix, name)
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

local function EmitOperandGroundAoe(operand, parseNode, nodeList, annotation, action)
    local ok = true
    local node
    local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
    local token = tokenIterator()
    if token == "ground_aoe" then
        local name = tokenIterator()
        local property = tokenIterator()
        name = Disambiguate(annotation, name, annotation.class, annotation.specialization)
        local dotName = name .. "_debuff"
        dotName = Disambiguate(annotation, dotName, annotation.class, annotation.specialization)
        local prefix = find(dotName, "_buff$") and "Buff" or "Debuff"
        local target = ""
        local code
        if property == "remains" then
            code = format("%s%sRemaining(%s)", target, prefix, dotName)
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
EmitOperandDot = function(operand, parseNode, nodeList, annotation, action, target)
    local ok = true
    local node
    local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
    local token = tokenIterator()
    if token == "dot" then
        local name = tokenIterator()
        local property = tokenIterator()
        name = Disambiguate(annotation, name, annotation.class, annotation.specialization)
        local dotName = name .. "_debuff"
        dotName = Disambiguate(annotation, dotName, annotation.class, annotation.specialization)
        local prefix = find(dotName, "_buff$") and "Buff" or "Debuff"
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
        elseif property == "tick_time_remains" then
            code = format("%sTickTimeRemaining(%s)", target, dotName)
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
        name = Disambiguate(annotation, name, annotation.class, annotation.specialization)
        local glyphName = "glyph_of_" .. name
        glyphName = Disambiguate(annotation, glyphName, annotation.class, annotation.specialization)
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
        name = Disambiguate(annotation, name, annotation.class, annotation.specialization)
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
            local petOperand = match(operand, pattern)
            ok, node = EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, "pet")
        else
            local pattern = format("^pet%%.%s%%.([%%w_.]+)", name)
            local petOperand = match(operand, pattern)
            local target = "pet"
            if petOperand then
                ok, node = EmitOperandSpecial(petOperand, parseNode, nodeList, annotation, action, target)
                if  not ok then
                    ok, node = EmitOperandAction(petOperand, parseNode, nodeList, annotation, action, target)
                end
                if  not ok then
                    ok, node = EmitOperandCharacter(petOperand, parseNode, nodeList, annotation, action, target)
                end
                if  not ok then
                    local petAbilityName = match(petOperand, "^[%w_]+%.([^.]+)")
                    petAbilityName = Disambiguate(annotation, petAbilityName, annotation.class, annotation.specialization)
                    if sub(petAbilityName, 1, 4) ~= "pet_" then
                        petOperand = gsub(petOperand, "^([%w_]+)%.", "%1." .. name .. "_")
                    end
                    if property == "buff" then
                        ok, node = EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, target)
                    elseif property == "cooldown" then
                        ok, node = EmitOperandCooldown(petOperand, parseNode, nodeList, annotation, action)
                    elseif property == "debuff" then
                        ok, node = EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, target)
                    elseif property == "dot" then
                        ok, node = EmitOperandDot(petOperand, parseNode, nodeList, annotation, action, target)
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
        if tonumber(name) then
            howMany = tonumber(name)
            name = tokenIterator()
        end
        name = Disambiguate(annotation, name, annotation.class, annotation.specialization)
        local code
        if token == "prev" then
            code = format("PreviousSpell(%s)", name)
        elseif token == "prev_gcd" then
            if howMany ~= 1 then
                code = format("PreviousGCDSpell(%s count=%d)", name, howMany)
            else
                code = format("PreviousGCDSpell(%s)", name)
            end
        else
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
    if sub(operand, 1, 11) == "raid_event." then
        local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
        tokenIterator()
        name = tokenIterator()
        property = tokenIterator()
    else
        local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
        name = tokenIterator()
        property = tokenIterator()
    end
    local code
    if name == "movement" then
        if property == "cooldown" or property == "in" then
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
        if property == "cooldown" then
            code = "600"
        elseif property == "count" then
            code = "0"
        elseif property == "exists" or property == "up" then
            code = "False(raid_event_adds_exists)"
        elseif property == "in" then
            code = "600"
        elseif property == "duration" then
            code = "10"
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
        local race = lower(tokenIterator())
        local code
        if race then
            local raceId = nil
            if (race == "blood_elf") then
                raceId = "BloodElf"
            elseif race == "troll" then
                raceId = "Troll"
            elseif race == "orc" then
                raceId = "Orc"
            else
                __exports.OvaleSimulationCraft:Print("Warning: Race '%s' not defined", race)
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
    elseif match(operand, "^rune.time_to_([%d]+)$") then
        local runes = match(operand, "^rune.time_to_([%d]+)$")
        code = format("TimeToRunes(%d)", runes)
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
    local setBonus = match(operand, "^set_bonus%.(.*)$")
    local code
    if setBonus then
        local tokenIterator = gmatch(setBonus, "[^_]+")
        local name = tokenIterator()
        local count = tokenIterator()
        local role = tokenIterator()
        if name and count then
            local setName, level = match(name, "^(%a+)(%d*)$")
            if setName == "tier" then
                setName = "T"
            else
                setName = upper(setName)
            end
            if level then
                name = setName .. tostring(level)
            end
            if role then
                name = name .. "_" .. role
            end
            count = match(count, "(%d+)pc")
            if name and count then
                code = format("ArmorSetBonus(%s %d)", name, count)
            end
        end
        if  not code then
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
        local name = lower(tokenIterator())
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
    local className = annotation.class
    local specialization = annotation.specialization
    target = target and (target .. ".") or ""
    operand = lower(operand)
    local code
    if className == "DEATHKNIGHT" and operand == "dot.breath_of_sindragosa.ticking" then
        local buffName = "breath_of_sindragosa_buff"
        code = format("BuffPresent(%s)", buffName)
        AddSymbol(annotation, buffName)
    elseif className == "DEATHKNIGHT" and sub(operand, 1, 24) == "pet.dancing_rune_weapon." then
        local petOperand = sub(operand, 25)
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
                target = sub(target, 1, -2)
            end
            ok, node = EmitOperandDot(petOperand, parseNode, nodeList, annotation, action, target)
        end
    elseif className == "DEMONHUNTER" and operand == "buff.metamorphosis.extended_by_demonic" then
        code = "not BuffExpires(extended_by_demonic_buff)"
    elseif className == "DEMONHUNTER" and operand == "cooldown.chaos_blades.ready" then
        code = "Talent(chaos_blades_talent) and SpellCooldown(chaos_blades) == 0"
        AddSymbol(annotation, "chaos_blades_talent")
        AddSymbol(annotation, "chaos_blades")
    elseif className == "DEMONHUNTER" and operand == "cooldown.nemesis.ready" then
        code = "Talent(nemesis_talent) and SpellCooldown(nemesis) == 0"
        AddSymbol(annotation, "nemesis_talent")
        AddSymbol(annotation, "nemesis")
    elseif className == "DEMONHUNTER" and operand == "cooldown.metamorphosis.ready" and specialization == "havoc" then
        code = "(not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight()) and SpellCooldown(metamorphosis_havoc) == 0"
        AddSymbol(annotation, "metamorphosis_havoc")
    elseif className == "DRUID" and operand == "buff.wild_charge_movement.down" then
        code = "True(wild_charge_movement_down)"
    elseif className == "DRUID" and operand == "eclipse_dir.lunar" then
        code = "EclipseDir() < 0"
    elseif className == "DRUID" and operand == "eclipse_dir.solar" then
        code = "EclipseDir() > 0"
    elseif className == "DRUID" and operand == "max_fb_energy" then
        local spellName = "ferocious_bite"
        code = format("EnergyCost(%s max=1)", spellName)
        AddSymbol(annotation, spellName)
    elseif className == "HUNTER" and operand == "buff.careful_aim.up" then
        code = "target.HealthPercent() > 80 or BuffPresent(rapid_fire_buff)"
        AddSymbol(annotation, "rapid_fire_buff")
    elseif className == "HUNTER" and operand == "buff.stampede.remains" then
        local spellName = "stampede"
        code = format("TimeSincePreviousSpell(%s) < 40", spellName)
        AddSymbol(annotation, spellName)
    elseif className == "HUNTER" and operand == "lowest_vuln_within.5" then
        code = "target.DebuffRemaining(vulnerable)"
        AddSymbol(annotation, "vulnerable")
    elseif className == "MAGE" and operand == "buff.rune_of_power.remains" then
        code = "TotemRemaining(rune_of_power)"
    elseif className == "MAGE" and operand == "buff.shatterlance.up" then
        code = "HasTrinket(t18_class_trinket) and PreviousGCDSpell(frostbolt)"
        AddSymbol(annotation, "frostbolt")
        AddSymbol(annotation, "t18_class_trinket")
    elseif className == "MAGE" and (operand == "burn_phase" or operand == "pyro_chain") then
        if parseNode.asType == "boolean" then
            code = format("GetState(%s) > 0", operand)
        else
            code = format("GetState(%s)", operand)
        end
    elseif className == "MAGE" and (operand == "burn_phase_duration" or operand == "pyro_chain_duration") then
        local variable = sub(operand, 1, -10)
        if parseNode.asType == "boolean" then
            code = format("GetStateDuration(%s) > 0", variable)
        else
            code = format("GetStateDuration(%s)", variable)
        end
    elseif className == "MAGE" and operand == "dot.frozen_orb.ticking" then
        local name = "frozen_orb"
        code = format("SpellCooldown(%s) > SpellCooldownDuration(%s) - 10", name, name)
        AddSymbol(annotation, name)
    elseif className == "MAGE" and operand == "firestarter.active" then
        code = "Talent(firestarter_talent) and target.HealthPercent() >= 90"
        AddSymbol(annotation, "firestarter_talent")
    elseif className == "MONK" and sub(operand, 1, 35) == "debuff.storm_earth_and_fire_target." then
        local property = sub(operand, 36)
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
    elseif className == "MONK" and operand == "dot.zen_sphere.ticking" then
        local buffName = "zen_sphere_buff"
        code = format("BuffPresent(%s)", buffName)
        AddSymbol(annotation, buffName)
    elseif className == "MONK" and sub(operand, 1, 8) == "stagger." then
        local property = sub(operand, 9)
        if property == "heavy" or property == "light" or property == "moderate" then
            local buffName = format("%s_stagger_debuff", property)
            code = format("DebuffPresent(%s)", buffName)
            AddSymbol(annotation, buffName)
        elseif property == "pct" then
            code = format("%sStaggerRemaining() / %sMaxHealth() * 100", target, target)
        else
            ok = false
        end
    elseif className == "MONK" and operand == "spinning_crane_kick.count" then
        code = "SpellCount(spinning_crane_kick)"
        AddSymbol(annotation, "spinning_crane_kick")
    elseif className == "PALADIN" and operand == "dot.sacred_shield.remains" then
        local buffName = "sacred_shield_buff"
        code = format("BuffRemaining(%s)", buffName)
        AddSymbol(annotation, buffName)
    elseif className == "PRIEST" and operand == "mind_harvest" then
        code = "target.MindHarvest()"
    elseif className == "PRIEST" and operand == "natural_shadow_word_death_range" then
        code = "target.HealthPercent() < 20"
    elseif className == "PRIEST" and operand == "primary_target" then
        code = "1"
    elseif className == "ROGUE" and operand == "trinket.cooldown.up" then
        code = "HasTrinket(draught_of_souls) and ItemCooldown(draught_of_souls) > 0"
        AddSymbol(annotation, "draught_of_souls")
    elseif className == "ROGUE" and operand == "mantle_duration" then
        code = "BuffRemaining(master_assassins_initiative)"
        AddSymbol(annotation, "master_assassins_initiative")
    elseif className == "ROGUE" and operand == "poisoned_enemies" then
        code = "0"
    elseif className == "ROGUE" and operand == "poisoned_bleeds" then
        code = "DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff)"
        AddSymbol(annotation, "rupture_debuff")
        AddSymbol(annotation, "garrote_debuff")
        AddSymbol(annotation, "internal_bleeding_talent")
        AddSymbol(annotation, "internal_bleeding_debuff")
    elseif className == "ROGUE" and operand == "exsanguinated" then
        code = "target.DebuffPresent(exsanguinated)"
        AddSymbol(annotation, "exsanguinated")
    elseif className == "ROGUE" and operand == "master_assassin_remains" then
        code = "BuffRemaining(master_assassin_buff)"
        AddSymbol(annotation, "master_assassin_buff")
    elseif className == "ROGUE" and operand == "buff.roll_the_bones.remains" then
        code = "BuffRemaining(roll_the_bones_buff)"
        AddSymbol(annotation, "roll_the_bones_buff")
    elseif className == "SHAMAN" and operand == "buff.resonance_totem.remains" then
        code = "TotemRemaining(totem_mastery)"
        ok = true
    elseif className == "SHAMAN" and match(operand, "pet.[a-z_]+.active") then
        code = "pet.Present()"
        ok = true
    elseif className == "WARLOCK" and match(operand, "pet%.service_[a-z_]+%..+") then
        local spellName, property = match(operand, "pet%.(service_[a-z_]+)%.(.+)")
        if property == "active" then
            code = format("SpellCooldown(%s) > 100", spellName)
            AddSymbol(annotation, spellName)
        else
            ok = false
        end
    elseif className == "WARLOCK" and match(operand, "dot.unstable_affliction_([1-5]).remains") then
        local num = match(operand, "dot.unstable_affliction_([1-5]).remains")
        code = format("target.DebuffStacks(unstable_affliction_debuff) >= %s", num)
    elseif className == "WARLOCK" and operand == "buff.active_uas.stack" then
        code = "target.DebuffStacks(unstable_affliction_debuff)"
    elseif className == "WARLOCK" and match(operand, "pet%.[a-z_]+%..+") then
        local spellName, property = match(operand, "pet%.([a-z_]+)%.(.+)")
        if property == "remains" then
            code = format("DemonDuration(%s)", spellName)
        elseif property == "active" then
            code = format("DemonDuration(%s) > 0", spellName)
        end
    elseif className == "WARLOCK" and operand == "contagion" then
        code = "BuffRemaining(unstable_affliction_buff)"
    elseif className == "WARLOCK" and operand == "buff.wild_imps.stack" then
        code = "Demons(wild_imp)"
    elseif className == "WARLOCK" and operand == "buff.dreadstalkers.remains" then
        code = "DemonDuration(dreadstalker)"
    elseif className == "WARLOCK" and match(operand, "prev_gcd.%d.hand_of_guldan") then
        code = "PreviousGCDSpell(hand_of_guldan)"
    elseif className == "WARRIOR" and sub(operand, 1, 23) == "buff.colossus_smash_up." then
        local property = sub(operand, 24)
        local debuffName = "colossus_smash_debuff"
        AddSymbol(annotation, debuffName)
        if property == "down" then
            code = format("DebuffCountOnAny(%s) == 0", debuffName)
        elseif property == "up" then
            code = format("DebuffCountOnAny(%s) > 0", debuffName)
        else
            ok = false
        end
    elseif className == "WARRIOR" and operand == "gcd.remains" and (action == "battle_cry" or action == "avatar") then
        code = "0"
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
        code = t .. "IsInterruptible()"
    elseif operand == "debuff.flying.down" then
        code = target .. "True(debuff_flying_down)"
    elseif operand == "distance" then
        code = target .. "Distance()"
    elseif sub(operand, 1, 9) == "equipped." then
        local name = Disambiguate(annotation, sub(operand, 10), className, specialization)
        code = format("HasEquippedItem(%s_item)", name)
        AddSymbol(annotation, name .. "_item")
    elseif operand == "gcd.max" then
        code = "GCD()"
    elseif operand == "gcd.remains" then
        code = "GCDRemaining()"
    elseif sub(operand, 1, 15) == "legendary_ring." then
        local name = Disambiguate(annotation, "legendary_ring", className, specialization)
        local buffName = name .. "_buff"
        local properties = sub(operand, 16)
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
        if target ~= "" then
            code = target .. "TimeToDie()"
        else
            code = "target.TimeToDie()"
        end
    elseif sub(operand, 1, 10) == "using_apl." then
        local aplName = match(operand, "^using_apl%.([%w_]+)")
        code = format("List(opt_using_apl %s)", aplName)
        annotation.using_apl = annotation.using_apl or {}
        annotation.using_apl[aplName] = true
    elseif operand == "cooldown.buff_sephuzs_secret.remains" then
        code = "BuffCooldown(sephuzs_secret_buff)"
        AddSymbol(annotation, "sephuzs_secret_buff")
    elseif operand == "is_add" then
        local t = target or "target."
        code = format("not %sClassification(worldboss)", t)
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
        local name = lower(tokenIterator())
        local property = tokenIterator()
        local talentName = name .. "_talent"
        talentName = Disambiguate(annotation, talentName, annotation.class, annotation.specialization)
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

EmitOperandTarget = function(operand, parseNode, nodeList, annotation, action)
    local ok = true
    local node
    local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
    local token = tokenIterator()
    if token == "target" then
        local property = tokenIterator()
        local code
        if property == "adds" then
            code = "Enemies()-1"
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

EmitOperandTotem = function(operand, parseNode, nodeList, annotation, action)
    local ok = true
    local node
    local tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN)
    local token = tokenIterator()
    if token == "totem" then
        local name = lower(tokenIterator())
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
        if procType == "cooldown" then
            if statName == "remains" then
                code = "{ ItemCooldown(Trinket0Slot) and ItemCooldown(Trinket1Slot) }"
            else
                ok = false
            end
        elseif sub(procType, 1, 4) == "has_" then
            code = format("True(trinket_%s_%s)", procType, statName)
        else
            local property = tokenIterator()
            local buffName = format("trinket_%s_%s_buff", procType, statName)
            buffName = Disambiguate(annotation, buffName, annotation.class, annotation.specialization)
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
        ["operand"] = EmitOperand
    }
end
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
local function SweepComments(childNodes, index)
    local count = 0
    for k = index - 1, 1, -1 do
        if childNodes[k].type == "comment" then
            remove(childNodes, k)
            count = count + 1
        else
            break
        end
    end
    return count
end
local function isNode(n)
    return type(n) == "table"
end
local function Sweep(node)
    local isChanged
    local isSwept
    isChanged, isSwept = false, false
    if node.type == "add_function" then
    elseif node.type == "custom_function" and  not self_functionDefined[node.name] then
        isChanged, isSwept = true, true
    elseif node.type == "group" or node.type == "script" then
        local child = node.child
        local index = #child
        while index > 0 do
            local childNode = child[index]
            local changed, swept = Sweep(childNode)
            if isNode(swept) then
                if swept.type == "group" then
                    remove(child, index)
                    for k = #swept.child, 1, -1 do
                        insert(child, index, swept.child[k])
                    end
                    if node.type == "group" then
                        local count = SweepComments(child, index)
                        index = index - count
                    end
                else
                    child[index] = swept
                end
            elseif swept then
                remove(child, index)
                if node.type == "group" then
                    local count = SweepComments(child, index)
                    index = index - count
                end
            end
            isChanged = isChanged or changed or  not  not swept
            index = index - 1
        end
        if node.type == "group" or node.type == "script" then
            local childNode = child[1]
            while childNode and childNode.type == "comment" and ( not childNode.comment or childNode.comment == "") do
                isChanged = true
                remove(child, 1)
                childNode = child[1]
            end
        end
        isSwept = isSwept or (#child == 0)
        isChanged = isChanged or  not  not isSwept
    elseif node.type == "icon" then
        isChanged, isSwept = Sweep(node.child[1])
    elseif node.type == "if" then
        isChanged, isSwept = Sweep(node.child[2])
    elseif node.type == "logical" then
        if node.expressionType == "binary" then
            local lhsNode, rhsNode = node.child[1], node.child[2]
            for index, childNode in ipairs(node.child) do
                local changed, swept = Sweep(childNode)
                if isNode(swept) then
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
            isChanged = isChanged or  not  not isSwept
        end
    elseif node.type == "unless" then
        local changed, swept = Sweep(node.child[2])
        if isNode(swept) then
            node.child[2] = swept
            isSwept = false
        elseif swept then
            isSwept = swept
        else
            changed, swept = Sweep(node.child[1])
            if isNode(swept) then
                node.child[1] = swept
                isSwept = false
            elseif swept then
                isSwept = node.child[2]
            end
        end
        isChanged = isChanged or changed or  not  not isSwept
    elseif node.type == "wait" then
        isChanged, isSwept = Sweep(node.child[1])
    end
    return isChanged, isSwept
end
local InsertInterruptFunction = function(child, annotation, interrupts)
    local nodeList = annotation.astAnnotation.nodeList
    local className = annotation.class
    local specialization = annotation.specialization
    local camelSpecialization = CamelSpecialization(annotation)
    local spells = interrupts or {}
    if OvaleData.PANDAREN_CLASSES[className] then
        insert(spells, {
            name = "quaking_palm",
            stun = 1,
            order = 98
        })
    end
    if OvaleData.TAUREN_CLASSES[className] then
        insert(spells, {
            name = "war_stomp",
            stun = 1,
            order = 99,
            range = "target.Distance(less 5)"
        })
    end
    sort(spells, function(a, b)
        return tonumber(a.order or 0) < tonumber(b.order or 0)
    end
)
    local lines = {}
    for _, spell in pairs(spells) do
        AddSymbol(annotation, spell.name)
        if (spell.addSymbol ~= nil) then
            for _, v in pairs(spell.addSymbol) do
                AddSymbol(annotation, v)
            end
        end
        local conditions = {}
        if spell.range == nil then
            insert(conditions, format("target.InRange(%s)", spell.name))
        elseif spell.range ~= "" then
            insert(conditions, spell.range)
        end
        if spell.interrupt == 1 then
            insert(conditions, "target.IsInterruptible()")
        end
        if spell.worksOnBoss == 0 or spell.worksOnBoss == nil then
            insert(conditions, "not target.Classification(worldboss)")
        end
        if spell.extraCondition ~= nil then
            insert(conditions, spell.extraCondition)
        end
        local line = ""
        if #conditions > 0 then
            line = line .. "if " .. concat(conditions, " and ") .. " "
        end
        line = line .. format("Spell(%s)", spell.name)
        insert(lines, line)
    end
    local fmt = [[
		AddFunction %sInterruptActions
		{
			if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
			{
				%s
			}
		}
	]]
    local code = format(fmt, camelSpecialization, concat(lines, "\n"))
    local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
    insert(child, 1, node)
    annotation.functionTag[node.name] = "cd"
end

local InsertInterruptFunctions = function(child, annotation)
    local interrupts = {}
    if annotation.mind_freeze == "DEATHKNIGHT" then
        insert(interrupts, {
            name = "mind_freeze",
            interrupt = 1,
            worksOnBoss = 1,
            order = 10
        })
        if annotation.specialization == "blood" or annotation.specialization == "unholy" then
            insert(interrupts, {
                name = "asphyxiate",
                stun = 1,
                order = 20
            })
        end
        if annotation.specialization == "frost" then
            insert(interrupts, {
                name = "blinding_sleet",
                disorient = 1,
                range = "target.Distance(less 12)",
                order = 20
            })
        end
    end
    if annotation.disrupt == "DEMONHUNTER" then
        insert(interrupts, {
            name = "disrupt",
            interrupt = 1,
            worksOnBoss = 1,
            order = 10
        })
        insert(interrupts, {
            name = "imprison",
            cc = 1,
            extraCondition = "target.CreatureType(Demon Humanoid Beast)",
            order = 999
        })
        if annotation.specialization == "havoc" then
            insert(interrupts, {
                name = "chaos_nova",
                stun = 1,
                range = "target.Distance(less 8)",
                order = 100
            })
            insert(interrupts, {
                name = "fel_eruption",
                stun = 1,
                order = 20
            })
        end
        if annotation.specialization == "vengeance" then
            insert(interrupts, {
                name = "sigil_of_silence",
                interrupt = 1,
                order = 110,
                range = "",
                extraCondition = "not SigilCharging(silence misery chains) and (target.RemainingCastTime() >= (2 - Talent(quickened_sigils_talent) + GCDRemaining()))"
            })
            insert(interrupts, {
                name = "sigil_of_misery",
                disorient = 1,
                order = 120,
                range = "",
                extraCondition = "not SigilCharging(silence misery chains) and (target.RemainingCastTime() >= (2 - Talent(quickened_sigils_talent) + GCDRemaining()))"
            })
            insert(interrupts, {
                name = "sigil_of_chains",
                pull = 1,
                order = 130,
                range = "",
                extraCondition = "not SigilCharging(silence misery chains) and (target.RemainingCastTime() >= (2 - Talent(quickened_sigils_talent) + GCDRemaining()))"
            })
        end
    end
    if annotation.skull_bash == "DRUID" or annotation.solar_beam == "DRUID" then
        if annotation.specialization == "guardian" or annotation.specialization == "feral" then
            insert(interrupts, {
                name = "skull_bash",
                interrupt = 1,
                worksOnBoss = 1,
                order = 10
            })
        end
        if annotation.specialization == "balance" then
            insert(interrupts, {
                name = "solar_beam",
                interrupt = 1,
                worksOnBoss = 1,
                order = 10
            })
        end
        insert(interrupts, {
            name = "mighty_bash",
            stun = 1,
            order = 20
        })
        if annotation.specialization == "guardian" then
            insert(interrupts, {
                name = "incapacitating_roar",
                incapacitate = 1,
                order = 30,
                range = "target.Distance(less 10)"
            })
        end
        insert(interrupts, {
            name = "typhoon",
            knockback = 1,
            order = 110,
            range = "target.Distance(less 15)"
        })
        if annotation.specialization == "feral" then
            insert(interrupts, {
                name = "maim",
                stun = 1,
                order = 40
            })
        end
    end
    if annotation.counter_shot == "HUNTER" then
        insert(interrupts, {
            name = "counter_shot",
            interrupt = 1,
            worksOnBoss = 1,
            order = 10
        })
    end
    if annotation.muzzle == "HUNTER" then
        insert(interrupts, {
            name = "muzzle",
            interrupt = 1,
            worksOnBoss = 1,
            order = 10
        })
    end
    if annotation.counterspell == "MAGE" then
        insert(interrupts, {
            name = "counterspell",
            interrupt = 1,
            worksOnBoss = 1,
            order = 10
        })
    end
    if annotation.spear_hand_strike == "MONK" then
        insert(interrupts, {
            name = "spear_hand_strike",
            interrupt = 1,
            worksOnBoss = 1,
            order = 10
        })
        insert(interrupts, {
            name = "paralysis",
            cc = 1,
            order = 999
        })
        insert(interrupts, {
            name = "leg_sweep",
            stun = 1,
            order = 30,
            range = "target.Distance(less 5)"
        })
    end
    if annotation.rebuke == "PALADIN" then
        insert(interrupts, {
            name = "rebuke",
            interrupt = 1,
            worksOnBoss = 1,
            order = 10
        })
        insert(interrupts, {
            name = "hammer_of_justice",
            stun = 1,
            order = 20
        })
        if annotation.specialization == "protection" then
            insert(interrupts, {
                name = "avengers_shield",
                interrupt = 1,
                worksOnBoss = 1,
                order = 15
            })
            insert(interrupts, {
                name = "blinding_light",
                disorient = 1,
                order = 50,
                range = "target.Distance(less 10)"
            })
        end
    end
    if annotation.silence == "PRIEST" then
        insert(interrupts, {
            name = "silence",
            interrupt = 1,
            worksOnBoss = 1,
            order = 10
        })
        insert(interrupts, {
            name = "mind_bomb",
            stun = 1,
            order = 30,
            extraCondition = "target.RemainingCastTime() > 2"
        })
    end
    if annotation.kick == "ROGUE" then
        insert(interrupts, {
            name = "kick",
            interrupt = 1,
            worksOnBoss = 1,
            order = 10
        })
        insert(interrupts, {
            name = "cheap_shot",
            stun = 1,
            order = 20
        })
        if annotation.specialization == "outlaw" then
            insert(interrupts, {
                name = "between_the_eyes",
                stun = 1,
                order = 30,
                extraCondition = "ComboPoints() >= 1"
            })
            insert(interrupts, {
                name = "gouge",
                incapacitate = 1,
                order = 100
            })
        end
        if annotation.specialization == "assassination" or annotation.specialization == "subtlety" then
            insert(interrupts, {
                name = "kidney_shot",
                stun = 1,
                order = 30,
                extraCondition = "ComboPoints() >= 1"
            })
        end
    end
    if annotation.wind_shear == "SHAMAN" then
        insert(interrupts, {
            name = "wind_shear",
            interrupt = 1,
            worksOnBoss = 1,
            order = 10
        })
        if annotation.specialization == "enhancement" then
            insert(interrupts, {
                name = "sundering",
                knockback = 1,
                order = 20,
                range = "target.Distance(less 5)"
            })
        end
        insert(interrupts, {
            name = "capacitor_totem",
            stun = 1,
            order = 30,
            range = "",
            extraCondition = "target.RemainingCastTime() > 2"
        })
        insert(interrupts, {
            name = "hex",
            cc = 1,
            order = 100,
            extraCondition = "target.RemainingCastTime() > CastTime(hex) + GCDRemaining() and target.CreatureType(Humanoid Beast)"
        })
    end
    if annotation.pummel == "WARRIOR" then
        insert(interrupts, {
            name = "pummel",
            interrupt = 1,
            worksOnBoss = 1,
            order = 10
        })
        insert(interrupts, {
            name = "shockwave",
            stun = 1,
            worksOnBoss = 0,
            order = 20,
            range = "target.Distance(less 10)"
        })
        insert(interrupts, {
            name = "storm_bolt",
            stun = 1,
            worksOnBoss = 0,
            order = 20
        })
        if (annotation.specialization == "protection") then
            insert(interrupts, {
                name = "intercept",
                stun = 1,
                worksOnBoss = 0,
                order = 20,
                extraCondition = "Talent(warbringer_talent)",
                addSymbol = {
                    [1] = "warbringer_talent"
                }
            })
        end
        insert(interrupts, {
            name = "intimidating_shout",
            incapacitate = 1,
            worksOnBoss = 0,
            order = 100
        })
    end
    if #interrupts > 0 then
        InsertInterruptFunction(child, annotation, interrupts)
        return 1
    else
        return 0
    end
end

local InsertSupportingFunctions = function(child, annotation)
    local count = 0
    local nodeList = annotation.astAnnotation.nodeList
    local camelSpecialization = CamelSpecialization(annotation)
    if annotation.melee == "DEATHKNIGHT" then
        local fmt = [[
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(death_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
			}
		]]
        local code = format(fmt, camelSpecialization)
        local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
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
					if target.InRange(felblade) Spell(felblade)
					Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		]]
        local code = format(fmt, camelSpecialization)
        local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
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
        insert(child, 1, node)
        annotation.functionTag[node.name] = "shortcd"
        AddSymbol(annotation, "shear")
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
        insert(child, 1, node)
        annotation.functionTag[node.name] = "shortcd"
        AddSymbol(annotation, "mangle")
        AddSymbol(annotation, "shred")
        AddSymbol(annotation, "wild_charge")
        AddSymbol(annotation, "wild_charge_bear")
        AddSymbol(annotation, "wild_charge_cat")
        count = count + 1
    end
    if annotation.melee == "HUNTER" then
        local fmt = [[
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(raptor_strike)
				{
					Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		]]
        local code = format(fmt, camelSpecialization)
        local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
        annotation.functionTag[node.name] = "shortcd"
        AddSymbol(annotation, "raptor_strike")
        count = count + 1
    end
    if annotation.summon_pet == "HUNTER" then
        local fmt
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
        local code = format(fmt, camelSpecialization)
        local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
        annotation.functionTag[node.name] = "shortcd"
        AddSymbol(annotation, "revive_pet")
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
        insert(child, 1, node)
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
        insert(child, 1, node)
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
        insert(child, 1, node)
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
        insert(child, 1, node)
        AddSymbol(annotation, "crusader_strike")
        AddSymbol(annotation, "holy_wrath")
        AddSymbol(annotation, "judgment")
        AddSymbol(annotation, "sanctified_wrath_talent")
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
        insert(child, 1, node)
        annotation.functionTag[node.name] = "shortcd"
        AddSymbol(annotation, "rebuke")
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
        insert(child, 1, node)
        annotation.functionTag[node.name] = "shortcd"
        AddSymbol(annotation, "kick")
        AddSymbol(annotation, "shadowstep")
        count = count + 1
    end
    if annotation.melee == "SHAMAN" then
        local fmt = [[
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(stormstrike) 
				{
					if target.InRange(feral_lunge) Spell(feral_lunge)
					Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		]]
        local code = format(fmt, camelSpecialization)
        local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
        annotation.functionTag[node.name] = "shortcd"
        AddSymbol(annotation, "feral_lunge")
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
        insert(child, 1, node)
        annotation.functionTag[node.name] = "cd"
        AddSymbol(annotation, "bloodlust")
        AddSymbol(annotation, "heroism")
        count = count + 1
    end
    if annotation.melee == "WARRIOR" then
        local fmt = [[
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not InFlightToTarget(%s) and not InFlightToTarget(heroic_leap)
				{
					if target.InRange(%s) Spell(%s)
					if SpellCharges(%s) == 0 and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
					if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		]]
        local charge = "charge"
        if annotation.specialization == "protection" then
            charge = "intercept"
        end
        local code = format(fmt, camelSpecialization, charge, charge, charge, charge)
        local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
        annotation.functionTag[node.name] = "shortcd"
        AddSymbol(annotation, charge)
        AddSymbol(annotation, "heroic_leap")
        AddSymbol(annotation, "pummel")
        count = count + 1
    end
    if annotation.use_item then
        local fmt = [[
			AddFunction %sUseItemActions
			{
				Item(Trinket0Slot usable=1 text=13)
				Item(Trinket1Slot usable=1 text=14)
			}
		]]
        local code = format(fmt, camelSpecialization)
        local node = OvaleAST:ParseCode("add_function", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
        annotation.functionTag[node.name] = "cd"
        count = count + 1
    end
    return count
end

local AddOptionalSkillCheckBox = function(child, annotation, data, skill)
    local nodeList = annotation.astAnnotation.nodeList
    if data.class ~= annotation[skill] then
        return 0
    end
    local defaultText
    if data.default then
        defaultText = " default"
    else
        defaultText = ""
    end
    local fmt = [[
		AddCheckBox(opt_%s SpellName(%s)%s specialization=%s)
	]]
    local code = format(fmt, skill, skill, defaultText, annotation.specialization)
    local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
    insert(child, 1, node)
    AddSymbol(annotation, skill)
    return 1
end

local InsertSupportingControls = function(child, annotation)
    local count = 0
    for skill, data in pairs(OPTIONAL_SKILLS) do
        count = count + AddOptionalSkillCheckBox(child, annotation, data, skill)
    end
    local nodeList = annotation.astAnnotation.nodeList
    local ifSpecialization = "specialization=" .. annotation.specialization
    if annotation.using_apl and next(annotation.using_apl) then
        for name in pairs(annotation.using_apl) do
            if name ~= "normal" then
                local fmt = [[
					AddListItem(opt_using_apl %s "%s APL")
				]]
                local code = format(fmt, name, name)
                local node = OvaleAST:ParseCode("list_item", code, nodeList, annotation.astAnnotation)
                insert(child, 1, node)
            end
        end
        do
            local code = [[
				AddListItem(opt_using_apl normal L(normal_apl) default)
			]]
            local node = OvaleAST:ParseCode("list_item", code, nodeList, annotation.astAnnotation)
            insert(child, 1, node)
        end
    end
    if annotation.opt_meta_only_during_boss == "DEMONHUNTER" then
        local fmt = [[
			AddCheckBox(opt_meta_only_during_boss L(meta_only_during_boss) default %s)
		]]
        local code = format(fmt, ifSpecialization)
        local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
        count = count + 1
    end
    if annotation.opt_arcane_mage_burn_phase == "MAGE" then
        local fmt = [[
			AddCheckBox(opt_arcane_mage_burn_phase L(arcane_mage_burn_phase) default %s)
		]]
        local code = format(fmt, ifSpecialization)
        local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
        count = count + 1
    end
    if annotation.opt_touch_of_death_on_elite_only == "MONK" then
        local fmt = [[
			AddCheckBox(opt_touch_of_death_on_elite_only L(touch_of_death_on_elite_only) default %s)
		]]
        local code = format(fmt, ifSpecialization)
        local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
        count = count + 1
    end
    if annotation.use_legendary_ring then
        local legendaryRing = annotation.use_legendary_ring
        local fmt = [[
			AddCheckBox(opt_%s ItemName(%s) default %s)
		]]
        local code = format(fmt, legendaryRing, legendaryRing, ifSpecialization)
        local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
        AddSymbol(annotation, legendaryRing)
        count = count + 1
    end
    if annotation.opt_use_consumables then
        local fmt = [[
			AddCheckBox(opt_use_consumables L(opt_use_consumables) default %s)
		]]
        local code = format(fmt, ifSpecialization)
        local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
        count = count + 1
    end
    if annotation.melee then
        local fmt = [[
			AddCheckBox(opt_melee_range L(not_in_melee_range) %s)
		]]
        local code = format(fmt, ifSpecialization)
        local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
        count = count + 1
    end
    if annotation.interrupt then
        local fmt = [[
			AddCheckBox(opt_interrupt L(interrupt) default %s)
		]]
        local code = format(fmt, ifSpecialization)
        local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
        insert(child, 1, node)
        count = count + 1
    end
    return count
end

local InsertVariables = function(child, annotation)
    if annotation.variable then
        for _, v in pairs(annotation.variable) do
            insert(child, 1, v)
        end
    end
end

local GenerateIconBody = function(tag, profile)
    local annotation = profile.annotation
    local precombatName = OvaleFunctionName("precombat", annotation)
    local defaultName = OvaleFunctionName("_default", annotation)
    local precombatBodyName, precombatConditionName = OvaleTaggedFunctionName(precombatName, tag)
    local defaultBodyName = OvaleTaggedFunctionName(defaultName, tag)
    local mainBodyCode
    if annotation.using_apl and next(annotation.using_apl) then
        local output = self_outputPool:Get()
        output[#output + 1] = format("if List(opt_using_apl normal) %s()", defaultBodyName)
        for name in pairs(annotation.using_apl) do
            local aplName = OvaleFunctionName(name, annotation)
            local aplBodyName = OvaleTaggedFunctionName(aplName, tag)
            output[#output + 1] = format("if List(opt_using_apl %s) %s()", name, aplBodyName)
        end
        mainBodyCode = concat(output, "\n")
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

local OvaleSimulationCraftClass = __class(OvaleSimulationCraftBase, {
    constructor = function(self)
        OvaleSimulationCraftBase.constructor(self)
    end,
    OnInitialize = function(self)
        InitializeDisambiguation()
        self:CreateOptions()
    end,
    DebuggingInfo = function(self)
        self_pool:DebuggingInfo()
        self_childrenPool:DebuggingInfo()
        self_outputPool:DebuggingInfo()
    end,
    ToString = function(self, tbl)
        local output = print_r(tbl)
        return concat(output, "\n")
    end,
    Release = function(self, profile)
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
    end,
    ParseProfile = function(self, simc, annotation)
        local profile = {}
        for _line in gmatch(simc, "[^\r\n]+") do
            local line = match(_line, "^%s*(.-)%s*$")
            if  not (match(line, "^#.*") or match(line, "^$")) then
                local k, operator, value = match(line, "([^%+=]+)(%+?=)(.*)")
                local key = k
                if operator == "=" then
                    profile[key] = value
                elseif operator == "+=" then
                    if type(profile[key]) ~= "table" then
                        local oldValue = profile[key]
                        profile[key] = {}
                        insert(profile[key], oldValue)
                    end
                    insert(profile[key], value)
                end
            end
        end
        for k, v in pairs(profile) do
            if type(v) == "table" then
                profile[k] = concat(v)
            end
        end
        profile.templates = {}
        for k in pairs(profile) do
            if sub(k, 1, 2) == "$(" and sub(k, -1) == ")" then
                insert(profile.templates, k)
            end
        end
        local ok = true
        annotation = annotation or {}
        local nodeList = {}
        local actionList = {}
        for k, _v in pairs(profile) do
            local v = _v
            if ok and match(k, "^actions") then
                local name = match(k, "^actions%.([%w_]+)")
                if  not name then
                    name = "_default"
                end
                for index = #profile.templates, 1, -1 do
                    local template = profile.templates[index]
                    local variable = sub(template, 3, -2)
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
        sort(actionList, function(a, b)
            return a.name < b.name
        end
)
        for className in pairs(RAID_CLASS_COLORS) do
            local lowerClass = lower(className)
            if profile[lowerClass] then
                annotation.class = className
                annotation.name = profile[lowerClass]
            end
        end
        annotation.specialization = profile.spec
        annotation.level = profile.level
        ok = ok and (annotation.class ~= nil and annotation.specialization ~= nil and annotation.level ~= nil)
        annotation.pet = profile.default_pet
        local consumables = {}
        for k, v in pairs(CONSUMABLE_ITEMS) do
            if v then
                if profile[k] ~= nil then
                    consumables[k] = profile[k]
                end
            end
        end
        annotation.consumables = consumables
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
        if  not ok then
            self:Release(profile)
            profile = nil
        end
        return profile
    end,
    Unparse = function(self, profile)
        local output = self_outputPool:Get()
        if profile.actionList then
            for _, node in ipairs(profile.actionList) do
                output[#output + 1] = Unparse(node)
            end
        end
        local s = concat(output, "\n")
        self_outputPool:Release(output)
        return s
    end,
    EmitAST = function(self, profile)
        local nodeList = {}
        local ast = OvaleAST:NewNode(nodeList, true)
        local child = ast.child
        ast.type = "script"
        local annotation = profile.annotation
        local ok = true
        if profile.actionList then
            annotation.astAnnotation = annotation.astAnnotation or {}
            annotation.astAnnotation.nodeList = nodeList
            local dictionaryAST
            do
                OvaleDebug:ResetTrace()
                local dictionaryAnnotation = {
                    nodeList = {},
                    definition = profile.annotation.dictionary
                }
                local dictionaryFormat = [[
				Include(ovale_common)
				Include(ovale_trinkets_mop)
				Include(ovale_trinkets_wod)
				Include(ovale_%s_spells)
				%s
			]]
                local dictionaryCode = format(dictionaryFormat, lower(annotation.class), Ovale.db.profile.overrideCode or "")
                dictionaryAST = OvaleAST:ParseCode("script", dictionaryCode, dictionaryAnnotation.nodeList, dictionaryAnnotation)
                if dictionaryAST then
                    dictionaryAST.annotation = dictionaryAnnotation
                    annotation.dictionaryAST = dictionaryAST
                    annotation.dictionary = dictionaryAnnotation.definition
                    OvaleAST:PropagateConstants(dictionaryAST)
                    OvaleAST:PropagateStrings(dictionaryAST)
                    OvaleAST:FlattenParameters(dictionaryAST)
                    ResetControls()
                    OvaleCompile:EvaluateScript(dictionaryAST, true)
                end
            end
            for _, node in ipairs(profile.actionList) do
                local addFunctionNode = EmitActionList(node, nodeList, annotation)
                if addFunctionNode then
                    local actionListName = gsub(node.name, "^_+", "")
                    local commentNode = OvaleAST:NewNode(nodeList)
                    commentNode.type = "comment"
                    commentNode.comment = "## actions." .. actionListName
                    child[#child + 1] = commentNode
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
            annotation.supportingFunctionCount = InsertSupportingFunctions(child, annotation)
            annotation.supportingInterruptCount = InsertInterruptFunctions(child, annotation)
            annotation.supportingControlCount = InsertSupportingControls(child, annotation)
            InsertVariables(child, annotation)
            local className, specialization = annotation.class, annotation.specialization
            local lowerclass = lower(className)
            local aoeToggle = "opt_" .. lowerclass .. "_" .. specialization .. "_aoe"
            do
                local commentNode = OvaleAST:NewNode(nodeList)
                commentNode.type = "comment"
                commentNode.comment = "## " .. CamelCase(specialization) .. " icons."
                insert(child, commentNode)
                local code = format("AddCheckBox(%s L(AOE) default specialization=%s)", aoeToggle, specialization)
                local node = OvaleAST:ParseCode("checkbox", code, nodeList, annotation.astAnnotation)
                insert(child, node)
            end
            do
                local fmt = [[
				AddIcon checkbox=!%s enemies=1 help=shortcd specialization=%s
				{
					%s
				}
			]]
                local code = format(fmt, aoeToggle, specialization, GenerateIconBody("shortcd", profile))
                local node = OvaleAST:ParseCode("icon", code, nodeList, annotation.astAnnotation)
                insert(child, node)
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
                insert(child, node)
            end
            do
                local fmt = [[
				AddIcon enemies=1 help=main specialization=%s
				{
					%s
				}
			]]
                local code = format(fmt, specialization, GenerateIconBody("main", profile))
                local node = OvaleAST:ParseCode("icon", code, nodeList, annotation.astAnnotation)
                insert(child, node)
            end
            do
                local fmt = [[
				AddIcon checkbox=%s help=aoe specialization=%s
				{
					%s
				}
			]]
                local code = format(fmt, aoeToggle, specialization, GenerateIconBody("main", profile))
                local node = OvaleAST:ParseCode("icon", code, nodeList, annotation.astAnnotation)
                insert(child, node)
            end
            do
                local fmt = [[
				AddIcon checkbox=!%s enemies=1 help=cd specialization=%s
				{
					%s
				}
			]]
                local code = format(fmt, aoeToggle, specialization, GenerateIconBody("cd", profile))
                local node = OvaleAST:ParseCode("icon", code, nodeList, annotation.astAnnotation)
                insert(child, node)
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
                insert(child, node)
            end
            Mark(ast)
            local changed = Sweep(ast)
            while changed do
                Mark(ast)
                changed = Sweep(ast)
            end
            Mark(ast)
            Sweep(ast)
        end
        if  not ok then
            OvaleAST:Release(ast)
            ast = nil
        end
        return ast
    end,
    Emit = function(self, profile, noFinalNewLine)
        local ast = self:EmitAST(profile)
        local annotation = profile.annotation
        local className = annotation.class
        local lowerclass = lower(className)
        local specialization = annotation.specialization
        local output = self_outputPool:Get()
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
        do
            output[#output + 1] = ""
            output[#output + 1] = "Include(ovale_common)"
            output[#output + 1] = "Include(ovale_trinkets_mop)"
            output[#output + 1] = "Include(ovale_trinkets_wod)"
            output[#output + 1] = format("Include(ovale_%s_spells)", lowerclass)
            local overrideCode = Ovale.db.profile.overrideCode
            if overrideCode ~= "" then
                output[#output + 1] = ""
                output[#output + 1] = "# Overrides."
                output[#output + 1] = overrideCode
            end
            if annotation.supportingControlCount > 0 then
                output[#output + 1] = ""
            end
        end
        output[#output + 1] = OvaleAST:Unparse(ast)
        if profile.annotation.symbolTable then
            output[#output + 1] = ""
            output[#output + 1] = "### Required symbols"
            sort(profile.annotation.symbolList)
            for _, symbol in ipairs(profile.annotation.symbolList) do
                if  not tonumber(symbol) and profile.annotation.dictionary and  not profile.annotation.dictionary[symbol] and  not OvaleData.buffSpellList[symbol] then
                    self:Print("Warning: Symbol '%s' not defined", symbol)
                end
                output[#output + 1] = "# " .. symbol
            end
        end
        annotation.dictionary = nil
        if annotation.dictionaryAST then
            OvaleAST:Release(annotation.dictionaryAST)
        end
        if  not noFinalNewLine and output[#output] ~= "" then
            output[#output + 1] = ""
        end
        local s = concat(output, "\n")
        self_outputPool:Release(output)
        OvaleAST:Release(ast)
        return s
    end,
    CreateOptions = function(self)
        local options = {
            name = Ovale:GetName() .. " SimulationCraft",
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
                            type = "description"
                        },
                        input = {
                            order = 20,
                            name = L["SimulationCraft Profile"],
                            type = "input",
                            multiline = 25,
                            width = "full",
                            get = function(info)
                                return self_lastSimC
                            end,
                            set = function(info, value)
                                self_lastSimC = value
                                local profile = self:ParseProfile(self_lastSimC)
                                local code = ""
                                if profile then
                                    code = self:Emit(profile)
                                end
                                self_lastScript = gsub(code, "	", "    ")
                            end
                        }
                    }
                },
                overrides = {
                    order = 20,
                    name = L["Overrides"],
                    type = "group",
                    args = {
                        description = {
                            order = 10,
                            name = L["SIMULATIONCRAFT_OVERRIDES_DESCRIPTION"],
                            type = "description"
                        },
                        overrides = {
                            order = 20,
                            name = L["Overrides"],
                            type = "input",
                            multiline = 25,
                            width = "full",
                            get = function(info)
                                local code = Ovale.db.profile.code
                                return gsub(code, "	", "    ")
                            end,
                            set = function(info, value)
                                Ovale.db.profile.overrideCode = value
                                if self_lastSimC then
                                    local profile = self:ParseProfile(self_lastSimC)
                                    local code = ""
                                    if profile then
                                        code = self:Emit(profile)
                                    end
                                    self_lastScript = gsub(code, "	", "    ")
                                end
                            end
                        }
                    }
                },
                output = {
                    order = 30,
                    name = L["Output"],
                    type = "group",
                    args = {
                        description = {
                            order = 10,
                            name = L["The script translated from the SimulationCraft profile."],
                            type = "description"
                        },
                        output = {
                            order = 20,
                            name = L["Script"],
                            type = "input",
                            multiline = 25,
                            width = "full",
                            get = function()
                                return self_lastScript
                            end

                        }
                    }
                }
            }
        }
        local appName = self:GetName()
        AceConfig:RegisterOptionsTable(appName, options)
        AceConfigDialog:AddToBlizOptions(appName, "SimulationCraft", Ovale:GetName())
    end,
})
__exports.OvaleSimulationCraft = OvaleSimulationCraftClass()
