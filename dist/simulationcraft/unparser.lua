local __exports = LibStub:NewLibrary("ovale/simulationcraft/unparser", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __definitions = LibStub:GetLibrary("ovale/simulationcraft/definitions")
local UNARY_OPERATOR = __definitions.UNARY_OPERATOR
local BINARY_OPERATOR = __definitions.BINARY_OPERATOR
local tostring = tostring
local pairs = pairs
local tonumber = tonumber
local kpairs = pairs
local __texttools = LibStub:GetLibrary("ovale/simulationcraft/text-tools")
local self_outputPool = __texttools.self_outputPool
local concat = table.concat
local function GetPrecedence(node)
    if node.type ~= "operator" then
        return 0
    end
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
__exports.Unparser = __class(nil, {
    constructor = function(self, ovaleDebug)
        self.UnparseAction = function(node)
            local output = self_outputPool:Get()
            output[#output + 1] = node.name
            for modifier, expressionNode in kpairs(node.modifiers) do
                output[#output + 1] = modifier .. "=" .. self:Unparse(expressionNode)
            end
            local s = concat(output, ",")
            self_outputPool:Release(output)
            return s
        end
        self.UnparseActionList = function(node)
            local output = self_outputPool:Get()
            local listName
            if node.name == "_default" then
                listName = "action"
            else
                listName = "action." .. node.name
            end
            output[#output + 1] = ""
            for i, actionNode in pairs(node.child) do
                local operator = (tonumber(i) == 1 and "=") or "+=/"
                output[#output + 1] = listName .. operator .. self:Unparse(actionNode)
            end
            local s = concat(output, "\n")
            self_outputPool:Release(output)
            return s
        end
        self.UnparseExpression = function(node)
            local expression
            local precedence = GetPrecedence(node)
            if node.expressionType == "unary" then
                local rhsExpression
                local rhsNode = node.child[1]
                local rhsPrecedence = GetPrecedence(rhsNode)
                if rhsPrecedence and precedence >= rhsPrecedence then
                    rhsExpression = "(" .. self:Unparse(rhsNode) .. ")"
                else
                    rhsExpression = self:Unparse(rhsNode)
                end
                expression = node.operator .. rhsExpression
            elseif node.expressionType == "binary" then
                local lhsExpression, rhsExpression
                local lhsNode = node.child[1]
                local lhsPrecedence = GetPrecedence(lhsNode)
                if lhsPrecedence and lhsPrecedence < precedence then
                    lhsExpression = "(" .. self:Unparse(lhsNode) .. ")"
                else
                    lhsExpression = self:Unparse(lhsNode)
                end
                local rhsNode = node.child[2]
                local rhsPrecedence = GetPrecedence(rhsNode)
                if rhsPrecedence and precedence > rhsPrecedence then
                    rhsExpression = "(" .. self:Unparse(rhsNode) .. ")"
                elseif rhsPrecedence and precedence == rhsPrecedence then
                    if rhsNode.type == "operator" and BINARY_OPERATOR[node.operator][3] == "associative" and node.operator == rhsNode.operator then
                        rhsExpression = self:Unparse(rhsNode)
                    else
                        rhsExpression = "(" .. self:Unparse(rhsNode) .. ")"
                    end
                else
                    rhsExpression = self:Unparse(rhsNode)
                end
                expression = lhsExpression .. node.operator .. rhsExpression
            else
                return "Unknown node expression type"
            end
            return expression
        end
        self.UnparseFunction = function(node)
            return node.name .. "(" .. self:Unparse(node.child[1]) .. ")"
        end
        self.UnparseNumber = function(node)
            return tostring(node.value)
        end
        self.UnparseOperand = function(node)
            return node.name
        end
        self.UNPARSE_VISITOR = {
            ["action"] = self.UnparseAction,
            ["action_list"] = self.UnparseActionList,
            ["operator"] = self.UnparseExpression,
            ["function"] = self.UnparseFunction,
            ["number"] = self.UnparseNumber,
            ["operand"] = self.UnparseOperand
        }
        self.tracer = ovaleDebug:create("SimulationCraftUnparser")
    end,
    Unparse = function(self, node)
        local visitor = self.UNPARSE_VISITOR[node.type]
        if  not visitor then
            self.tracer:Error("Unable to unparse node of type '%s'.", node.type)
        else
            return visitor(node)
        end
    end,
})
