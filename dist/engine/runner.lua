local __exports = LibStub:NewLibrary("ovale/engine/runner", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local ipairs = ipairs
local kpairs = pairs
local loadstring = loadstring
local tostring = tostring
local wipe = wipe
local abs = math.abs
local huge = math.huge
local min = math.min
local __ast = LibStub:GetLibrary("ovale/engine/ast")
local isAstNodeWithChildren = __ast.isAstNodeWithChildren
local setResultType = __ast.setResultType
local __toolsTimeSpan = LibStub:GetLibrary("ovale/tools/TimeSpan")
local EMPTY_SET = __toolsTimeSpan.EMPTY_SET
local newTimeSpan = __toolsTimeSpan.newTimeSpan
local releaseTimeSpans = __toolsTimeSpan.releaseTimeSpans
local UNIVERSE = __toolsTimeSpan.UNIVERSE
local __toolstools = LibStub:GetLibrary("ovale/tools/tools")
local isNumber = __toolstools.isNumber
local isString = __toolstools.isString
local OneTimeMessage = __toolstools.OneTimeMessage
__exports.Runner = __class(nil, {
    constructor = function(self, ovaleProfiler, ovaleDebug, baseState, ovaleCondition)
        self.baseState = baseState
        self.ovaleCondition = ovaleCondition
        self.self_serial = 0
        self.actionHandlers = {}
        self.computeBoolean = function(node)
            self:GetTimeSpan(node, UNIVERSE)
            self:SetValue(node, node.value)
            return node.result
        end
        self.ComputeAction = function(node, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeAction")
            local nodeId = node.nodeId
            local timeSpan = self:GetTimeSpan(node)
            self.tracer:Log("[%d]    evaluating action: %s()", nodeId, node.name)
            local _, namedParameters = self:computeParameters(node, atTime)
            local result = self:GetActionInfo(node, atTime, namedParameters)
            if result.type ~= "action" then
                return result
            end
            local action = node.name
            if  not result.actionTexture then
                self.tracer:Log("[%d]    Action %s not found.", nodeId, action)
                wipe(timeSpan)
            elseif  not result.actionEnable then
                self.tracer:Log("[%d]    Action %s not enabled.", nodeId, action)
                wipe(timeSpan)
            elseif namedParameters.usable == 1 and  not result.actionUsable then
                self.tracer:Log("[%d]    Action %s not usable.", nodeId, action)
                wipe(timeSpan)
            else
                if  not result.castTime then
                    result.castTime = 0
                end
                local start
                if result.actionCooldownStart and result.actionCooldownStart > 0 and (result.actionCharges == nil or result.actionCharges == 0) then
                    self.tracer:Log("[%d]    Action %s (actionCharges=%s)", nodeId, action, result.actionCharges or "(nil)")
                    if result.actionCooldownDuration and result.actionCooldownDuration > 0 then
                        self.tracer:Log("[%d]    Action %s is on cooldown (start=%f, duration=%f).", nodeId, action, result.actionCooldownStart, result.actionCooldownDuration)
                        start = result.actionCooldownStart + result.actionCooldownDuration
                    else
                        self.tracer:Log("[%d]    Action %s is waiting on the GCD (start=%f).", nodeId, action, result.actionCooldownStart)
                        start = result.actionCooldownStart
                    end
                else
                    if result.actionCharges == nil then
                        self.tracer:Log("[%d]    Action %s is off cooldown.", nodeId, action)
                        start = atTime
                    elseif result.actionCooldownDuration and result.actionCooldownDuration > 0 then
                        self.tracer:Log("[%d]    Action %s still has %f charges and is not on GCD.", nodeId, action, result.actionCharges)
                        start = atTime
                    else
                        self.tracer:Log("[%d]    Action %s still has %f charges but is on GCD (start=%f).", nodeId, action, result.actionCharges, result.actionCooldownStart)
                        start = result.actionCooldownStart or 0
                    end
                end
                if result.actionResourceExtend and result.actionResourceExtend > 0 then
                    if namedParameters.pool_resource and namedParameters.pool_resource == 1 then
                        self.tracer:Log("[%d]    Action %s is ignoring resource requirements because it is a pool_resource action.", nodeId, action)
                    else
                        self.tracer:Log("[%d]    Action %s is waiting on resources (start=%f, extend=%f).", nodeId, action, start, result.actionResourceExtend)
                        start = start + result.actionResourceExtend
                    end
                end
                self.tracer:Log("[%d]    start=%f atTime=%f", nodeId, start, atTime)
                if result.offgcd then
                    self.tracer:Log("[%d]    Action %s is off the global cooldown.", nodeId, action)
                elseif start < atTime then
                    self.tracer:Log("[%d]    Action %s is waiting for the global cooldown.", nodeId, action)
                end
                self.tracer:Log("[%d]    Action %s can start at %f.", nodeId, action, start)
                timeSpan:Copy(start, huge)
            end
            self.profiler:StopProfiling("OvaleBestAction_ComputeAction")
            return result
        end
        self.ComputeArithmetic = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeArithmetic")
            local timeSpan = self:GetTimeSpan(element)
            local result = element.result
            local nodeA = self:Compute(element.child[1], atTime)
            local a, b, c, timeSpanA = self:AsValue(atTime, nodeA)
            local nodeB = self:Compute(element.child[2], atTime)
            local x, y, z, timeSpanB = self:AsValue(atTime, nodeB)
            timeSpanA:Intersect(timeSpanB, timeSpan)
            if timeSpan:Measure() == 0 then
                self.tracer:Log("[%d]    arithmetic '%s' returns %s with zero measure", element.nodeId, element.operator, timeSpan)
                self:SetValue(element, 0)
            else
                local operator = element.operator
                local t = atTime
                self.tracer:Log("[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s", element.nodeId, a, b, c, operator, x, y, z)
                local l, m, n
                if  not isNumber(a) or  not isNumber(x) then
                    self.tracer:Error("[%d] Operands of arithmetic operators must be numbers", element.nodeId)
                    return result
                end
                local A = a + (t - b) * c
                local B = x + (t - y) * z
                if operator == "+" then
                    l = A + B
                    m = t
                    n = c + z
                elseif operator == "-" then
                    l = A - B
                    m = t
                    n = c - z
                elseif operator == "*" then
                    l = A * B
                    m = t
                    n = A * z + B * c
                elseif operator == "/" then
                    if B == 0 then
                        if A ~= 0 then
                            OneTimeMessage("[%d] Division by 0 in %s", element.nodeId, element.asString)
                        end
                        B = 0.00001
                    end
                    l = A / B
                    m = t
                    local numerator = B * c - A * z
                    if numerator ~= huge then
                        n = numerator / (B ^ 2)
                    else
                        n = numerator
                    end
                    local bound
                    if z == 0 then
                        bound = huge
                    else
                        bound = abs(B / z)
                    end
                    local scratch = timeSpan:IntersectInterval(t - bound, t + bound)
                    timeSpan:copyFromArray(scratch)
                    scratch:Release()
                elseif operator == "%" then
                    if c == 0 and z == 0 then
                        l = A % B
                        m = t
                        n = 0
                    else
                        self.tracer:Error("[%d]    Parameters of modulus operator '%' must be constants.", element.nodeId)
                        l = 0
                        m = 0
                        n = 0
                    end
                elseif operator == ">?" then
                    l = min(A, B)
                    m = t
                    if l == A then
                        n = c
                    else
                        n = z
                    end
                elseif operator == "<?" then
                    l = min(A, B)
                    m = t
                    if l == A then
                        n = z
                    else
                        n = c
                    end
                end
                self.tracer:Log("[%d]    arithmetic '%s' returns %s+(t-%s)*%s", element.nodeId, operator, l, m, n)
                self:SetValue(element, l, m, n)
            end
            self.profiler:StopProfiling("OvaleBestAction_ComputeArithmetic")
            return result
        end
        self.ComputeCompare = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeCompare")
            local timeSpan = self:GetTimeSpan(element)
            local elementA = self:Compute(element.child[1], atTime)
            local a, b, c, timeSpanA = self:AsValue(atTime, elementA)
            local elementB = self:Compute(element.child[2], atTime)
            local x, y, z, timeSpanB = self:AsValue(atTime, elementB)
            timeSpanA:Intersect(timeSpanB, timeSpan)
            if timeSpan:Measure() == 0 then
                self.tracer:Log("[%d]    compare '%s' returns %s with zero measure", element.nodeId, element.operator, timeSpan)
            else
                local operator = element.operator
                self.tracer:Log("[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s", element.nodeId, a, b, c, operator, x, y, z)
                if  not isNumber(a) or  not isNumber(x) then
                    if (operator == "==" and a ~= b) or (operator == "!=" and a == b) then
                        wipe(timeSpan)
                    end
                    return element.result
                end
                local A = a - b * c
                local B = x - y * z
                if c == z then
                    if  not ((operator == "==" and A == B) or (operator == "!=" and A ~= B) or (operator == "<" and A < B) or (operator == "<=" and A <= B) or (operator == ">" and A > B) or (operator == ">=" and A >= B)) then
                        wipe(timeSpan)
                    end
                else
                    local diff = B - A
                    local t
                    if diff == huge then
                        t = huge
                    else
                        t = diff / (c - z)
                    end
                    t = (t > 0 and t) or 0
                    self.tracer:Log("[%d]    intersection at t = %s", element.nodeId, t)
                    local scratch
                    if (c > z and operator == "<") or (c > z and operator == "<=") or (c < z and operator == ">") or (c < z and operator == ">=") then
                        scratch = timeSpan:IntersectInterval(0, t)
                    elseif (c < z and operator == "<") or (c < z and operator == "<=") or (c > z and operator == ">") or (c > z and operator == ">=") then
                        scratch = timeSpan:IntersectInterval(t, huge)
                    end
                    if scratch then
                        timeSpan:copyFromArray(scratch)
                        scratch:Release()
                    else
                        wipe(timeSpan)
                    end
                end
                self.tracer:Log("[%d]    compare '%s' returns %s", element.nodeId, operator, timeSpan)
            end
            self.profiler:StopProfiling("OvaleBestAction_ComputeCompare")
            return element.result
        end
        self.ComputeCustomFunction = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeCustomFunction")
            local timeSpan = self:GetTimeSpan(element)
            local result = element.result
            local node = element.annotation.customFunction and element.annotation.customFunction[element.name]
            if node then
                if self.tracer.debug.trace then
                    self.tracer:Log("[%d]: calling custom function [%d] %s", element.nodeId, node.child[1].nodeId, element.name)
                end
                local elementA = self:Compute(node.child[1], atTime)
                if self.tracer.debug.trace then
                    self.tracer:Log("[%d]: [%d] %s is returning %s", element.nodeId, node.child[1].nodeId, element.name, self:resultToString(elementA))
                end
                timeSpan:copyFromArray(elementA.timeSpan)
                self:copyResult(result, elementA)
            else
                self.tracer:Error("Unable to find " .. element.name)
                wipe(timeSpan)
            end
            self.profiler:StopProfiling("OvaleBestAction_ComputeCustomFunction")
            return result
        end
        self.ComputeFunction = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeFunction")
            local timeSpan = self:GetTimeSpan(element)
            local positionalParams, namedParams = self:computeParameters(element, atTime)
            local start, ending, value, origin, rate = self.ovaleCondition:EvaluateCondition(element.name, positionalParams, namedParams, atTime)
            if start ~= nil and ending ~= nil then
                timeSpan:Copy(start, ending)
            else
                wipe(timeSpan)
            end
            if value ~= nil then
                self:SetValue(element, value, origin, rate)
            end
            self.tracer:Log("[%d]    condition '%s' returns %s, %s, %s, %s, %s", element.nodeId, element.name, start, ending, value, origin, rate)
            self.profiler:StopProfiling("OvaleBestAction_ComputeFunction")
            return element.result
        end
        self.computeTypedFunction = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeFunction")
            local timeSpan = self:GetTimeSpan(element)
            local positionalParams = self:computePositionalParameters(element, atTime)
            local start, ending, value, origin, rate = self.ovaleCondition:call(element.name, atTime, positionalParams)
            if start ~= nil and ending ~= nil then
                timeSpan:Copy(start, ending)
            else
                wipe(timeSpan)
            end
            if value ~= nil then
                self:SetValue(element, value, origin, rate)
            end
            self.tracer:Log("[%d]    condition '%s' returns %s, %s, %s, %s, %s", element.nodeId, element.name, start, ending, value, origin, rate)
            self.profiler:StopProfiling("OvaleBestAction_ComputeFunction")
            return element.result
        end
        self.ComputeGroup = function(group, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeGroup")
            local bestTimeSpan, bestElement
            local best = newTimeSpan()
            local current = newTimeSpan()
            for _, child in ipairs(group.child) do
                local nodeString = child.asString or "[" .. child.type .. "]"
                self.tracer:Log("[%d]    group checking child [%d-%s]", group.nodeId, child.nodeId, nodeString)
                local currentElement = self:Compute(child, atTime)
                local currentTimeSpan = currentElement.timeSpan
                currentTimeSpan:IntersectInterval(atTime, huge, current)
                self.tracer:Log("[%d]    group checking child [%d-%s] result: %s", group.nodeId, child.nodeId, nodeString, current)
                if current:Measure() > 0 then
                    local currentIsBetter = false
                    if best:Measure() == 0 or  not bestElement then
                        self.tracer:Log("[%d]    group first best is [%d-%s]: %s", group.nodeId, child.nodeId, nodeString, current)
                        currentIsBetter = true
                    else
                        local threshold = (bestElement.type == "action" and bestElement.options and bestElement.options.wait) or 0
                        local difference = best[1] - current[1]
                        if difference > threshold or (difference == threshold and bestElement.type == "action" and currentElement.type == "action" and  not bestElement.actionUsable and currentElement.actionUsable) then
                            self.tracer:Log("[%d]    group new best is [%d-%s]: %s", group.nodeId, child.nodeId, nodeString, currentTimeSpan)
                            currentIsBetter = true
                        end
                    end
                    if currentIsBetter then
                        best:copyFromArray(current)
                        bestTimeSpan = currentTimeSpan
                        bestElement = currentElement
                    end
                end
            end
            releaseTimeSpans(best, current)
            local timeSpan = self:GetTimeSpan(group, bestTimeSpan)
            if bestElement then
                self:copyResult(group.result, bestElement)
                self.tracer:Log("[%d]    group best action remains %s at %s", group.nodeId, self:resultToString(group.result), timeSpan)
            else
                setResultType(group.result, "none")
                self.tracer:Log("[%d]    group no best action returns %s at %s", group.nodeId, self:resultToString(group.result), timeSpan)
            end
            self.profiler:StopProfiling("OvaleBestAction_ComputeGroup")
            return group.result
        end
        self.ComputeIf = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeIf")
            local timeSpan = self:GetTimeSpan(element)
            local result = element.result
            local timeSpanA = self:ComputeBool(element.child[1], atTime)
            local conditionTimeSpan = timeSpanA
            if element.type == "unless" then
                conditionTimeSpan = timeSpanA:Complement()
            end
            if conditionTimeSpan:Measure() == 0 then
                timeSpan:copyFromArray(conditionTimeSpan)
                self.tracer:Log("[%d]    '%s' returns %s with zero measure", element.nodeId, element.type, timeSpan)
            else
                local elementB = self:Compute(element.child[2], atTime)
                conditionTimeSpan:Intersect(elementB.timeSpan, timeSpan)
                self.tracer:Log("[%d]    '%s' returns %s (intersection of %s and %s)", element.nodeId, element.type, timeSpan, conditionTimeSpan, elementB.timeSpan)
                self:copyResult(result, elementB)
            end
            if element.type == "unless" then
                conditionTimeSpan:Release()
            end
            self.profiler:StopProfiling("OvaleBestAction_ComputeIf")
            return result
        end
        self.ComputeLogical = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeLogical")
            local timeSpan = self:GetTimeSpan(element)
            local timeSpanA = self:ComputeBool(element.child[1], atTime)
            if element.operator == "and" then
                if timeSpanA:Measure() == 0 then
                    timeSpan:copyFromArray(timeSpanA)
                    self.tracer:Log("[%d]    logical '%s' short-circuits with zero measure left argument", element.nodeId, element.operator)
                else
                    local timeSpanB = self:ComputeBool(element.child[2], atTime)
                    timeSpanA:Intersect(timeSpanB, timeSpan)
                end
            elseif element.operator == "not" then
                timeSpanA:Complement(timeSpan)
            elseif element.operator == "or" then
                if timeSpanA:IsUniverse() then
                    timeSpan:copyFromArray(timeSpanA)
                    self.tracer:Log("[%d]    logical '%s' short-circuits with universe as left argument", element.nodeId, element.operator)
                else
                    local timeSpanB = self:ComputeBool(element.child[2], atTime)
                    timeSpanA:Union(timeSpanB, timeSpan)
                end
            elseif element.operator == "xor" then
                local timeSpanB = self:ComputeBool(element.child[2], atTime)
                local left = timeSpanA:Union(timeSpanB)
                local scratch = timeSpanA:Intersect(timeSpanB)
                local right = scratch:Complement()
                left:Intersect(right, timeSpan)
                releaseTimeSpans(left, scratch, right)
            else
                wipe(timeSpan)
            end
            self.tracer:Log("[%d]    logical '%s' returns %s", element.nodeId, element.operator, timeSpan)
            self.profiler:StopProfiling("OvaleBestAction_ComputeLogical")
            return element.result
        end
        self.ComputeLua = function(element)
            if  not element.lua then
                return element.result
            end
            self.profiler:StartProfiling("OvaleBestAction_ComputeLua")
            local value = loadstring(element.lua)()
            self.tracer:Log("[%d]    lua returns %s", element.nodeId, value)
            if value then
                self:SetValue(element, value)
            end
            self:GetTimeSpan(element, UNIVERSE)
            self.profiler:StopProfiling("OvaleBestAction_ComputeLua")
            return element.result
        end
        self.ComputeValue = function(element)
            self.profiler:StartProfiling("OvaleBestAction_ComputeValue")
            self.tracer:Log("[%d]    value is %s", element.nodeId, element.value)
            self:GetTimeSpan(element, UNIVERSE)
            self:SetValue(element, element.value, element.origin, element.rate)
            self.profiler:StopProfiling("OvaleBestAction_ComputeValue")
            return element.result
        end
        self.computeString = function(element)
            self.tracer:Log("[%d]    value is %s", element.nodeId, element.value)
            self:GetTimeSpan(element, UNIVERSE)
            self:SetValue(element, element.value, nil, nil)
            return element.result
        end
        self.computeVariable = function(element)
            self.tracer:Log("[%d]    value is %s", element.nodeId, element.name)
            self:GetTimeSpan(element, UNIVERSE)
            self:SetValue(element, element.name, nil, nil)
            return element.result
        end
        self.COMPUTE_VISITOR = {
            ["action"] = self.ComputeAction,
            ["arithmetic"] = self.ComputeArithmetic,
            ["boolean"] = self.computeBoolean,
            ["compare"] = self.ComputeCompare,
            ["custom_function"] = self.ComputeCustomFunction,
            ["function"] = self.ComputeFunction,
            ["group"] = self.ComputeGroup,
            ["if"] = self.ComputeIf,
            ["logical"] = self.ComputeLogical,
            ["lua"] = self.ComputeLua,
            ["state"] = self.ComputeFunction,
            ["string"] = self.computeString,
            ["typed_function"] = self.computeTypedFunction,
            ["unless"] = self.ComputeIf,
            ["value"] = self.ComputeValue,
            ["variable"] = self.computeVariable
        }
        self.profiler = ovaleProfiler:create("runner")
        self.tracer = ovaleDebug:create("runner")
    end,
    refresh = function(self)
        self.self_serial = self.self_serial + 1
    end,
    PostOrderCompute = function(self, element, atTime)
        self.profiler:StartProfiling("OvaleBestAction_PostOrderCompute")
        local result
        local postOrder = element.postOrder
        if postOrder and  not (element.result.serial and element.result.serial >= self.self_serial) then
            local index = 1
            local N = #postOrder
            while index < N do
                local childNode, parentNode = postOrder[index], postOrder[index + 1]
                index = index + 2
                result = self:PostOrderCompute(childNode, atTime)
                if parentNode and result.timeSpan then
                    local shortCircuit = false
                    if isAstNodeWithChildren(parentNode) and parentNode.child[1] == childNode then
                        if parentNode.type == "if" and result.timeSpan:Measure() == 0 then
                            self.tracer:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero-measure time span.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        elseif parentNode.type == "unless" and result.timeSpan:IsUniverse() then
                            self.tracer:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        elseif parentNode.type == "logical" and parentNode.operator == "and" and result.timeSpan:Measure() == 0 then
                            self.tracer:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero measure.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        elseif parentNode.type == "logical" and parentNode.operator == "or" and result.timeSpan:IsUniverse() then
                            self.tracer:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        end
                    end
                    if shortCircuit then
                        while parentNode ~= postOrder[index] and index <= N do
                            index = index + 2
                        end
                        if index > N then
                            self.tracer:Error("Ran off end of postOrder node list for node %d.", element.nodeId)
                        end
                    end
                end
            end
        end
        self:RecursiveCompute(element, atTime)
        self.profiler:StopProfiling("OvaleBestAction_PostOrderCompute")
        return element.result
    end,
    RecursiveCompute = function(self, element, atTime)
        self.profiler:StartProfiling("OvaleBestAction_RecursiveCompute")
        if element.result.serial == -1 then
            OneTimeMessage("Recursive call is not supported in '%s'. Please fix the script.", element.asString or element.type)
            return element.result
        elseif element.result.serial and element.result.serial >= self.self_serial then
            self.tracer:Log("[%d] >>> Returning for '%s' cached value %s at %s", element.nodeId, element.asString or element.type, self:resultToString(element.result), element.result.timeSpan)
        else
            self.tracer:Log("[%d] >>> Computing '%s' at time=%f", element.nodeId, element.asString or element.type, atTime)
            element.result.serial = -1
            local visitor = self.COMPUTE_VISITOR[element.type]
            local result
            if visitor then
                result = visitor(element, atTime)
                element.result.serial = self.self_serial
                self.tracer:Log("[%d] <<< '%s' returns %s with value = %s", element.nodeId, element.asString or element.type, result.timeSpan, self:resultToString(result))
            else
                self.tracer:Error("[%d] Runtime error: unable to compute node of type '%s': %s.", element.nodeId, element.type, element.asString)
                wipe(element.result.timeSpan)
                element.result.serial = self.self_serial
            end
        end
        self.profiler:StopProfiling("OvaleBestAction_RecursiveCompute")
        return element.result
    end,
    ComputeBool = function(self, element, atTime)
        local newElement = self:Compute(element, atTime)
        if newElement.type == "value" and (newElement.value == 0 or newElement.value == false) and (newElement.rate == 0 or newElement.rate == nil) then
            return EMPTY_SET
        else
            return newElement.timeSpan
        end
    end,
    registerActionInfoHandler = function(self, name, handler)
        self.actionHandlers[name] = handler
    end,
    GetActionInfo = function(self, element, atTime, namedParameters)
        if element.type == "action" then
            if element.result.serial and element.result.serial >= self.self_serial then
                self.tracer:Log("[%d]    using cached result (age = %d/%d)", element.nodeId, element.result.serial, self.self_serial)
            else
                local target = (isString(namedParameters.target) and namedParameters.target) or self.baseState.next.defaultTarget
                local result = self.actionHandlers[element.name](element, atTime, target)
                if result.type == "action" then
                    result.options = namedParameters
                end
            end
        end
        return element.result
    end,
    copyResult = function(self, target, source)
        for k in kpairs(target) do
            if k ~= "timeSpan" and k ~= "type" and k ~= "serial" then
                target[k] = nil
            end
        end
        for k, v in kpairs(source) do
            if k ~= "timeSpan" then
                target[k] = v
            end
        end
    end,
    resultToString = function(self, result)
        if result.type == "value" then
            if result.value == nil then
                return "nil value"
            end
            if isString(result.value) then
                return "value \"" .. result.value .. "\""
            end
            if isNumber(result.value) then
                return "value " .. result.value .. " + (t - " .. tostring(result.origin) .. ") * " .. tostring(result.rate)
            end
            return "value " .. ((result.value == true and "true") or "false")
        elseif result.type == "action" then
            return "action " .. (result.actionType or "?") .. " " .. (result.actionId or "nil")
        elseif result.type == "none" then
            return [[none]]
        elseif result.type == "state" then
            return "state " .. result.name
        end
        return ""
    end,
    SetValue = function(self, node, value, origin, rate)
        local result = node.result
        setResultType(result, "value")
        result.value = value or 0
        result.origin = origin or 0
        result.rate = rate or 0
    end,
    AsValue = function(self, atTime, node)
        local value, origin, rate, timeSpan
        if node.type == "value" and node.value ~= nil then
            value = node.value
            origin = node.origin or 0
            rate = node.rate or 0
            timeSpan = node.timeSpan or UNIVERSE
        elseif node.timeSpan and node.timeSpan:HasTime(atTime) then
            value, origin, rate, timeSpan = 1, 0, 0, UNIVERSE
        else
            value, origin, rate, timeSpan = 0, 0, 0, UNIVERSE
        end
        return value, origin, rate, timeSpan
    end,
    GetTimeSpan = function(self, node, defaultTimeSpan)
        local timeSpan = node.result.timeSpan
        if defaultTimeSpan then
            timeSpan:copyFromArray(defaultTimeSpan)
        else
            wipe(timeSpan)
        end
        return timeSpan
    end,
    Compute = function(self, element, atTime)
        return self:PostOrderCompute(element, atTime)
    end,
    computeAsBoolean = function(self, element, atTime)
        local result = self:RecursiveCompute(element, atTime)
        return result.timeSpan:HasTime(atTime) or false
    end,
    computeAsNumber = function(self, element, atTime)
        local result = self:RecursiveCompute(element, atTime)
        if result.type == "value" and isNumber(result.value) then
            if result.origin ~= nil and result.rate ~= nil then
                return result.value + result.rate * (atTime - result.origin)
            end
            return result.value
        end
        return 0
    end,
    computeAsString = function(self, element, atTime)
        local result = self:RecursiveCompute(element, atTime)
        if result.type == "value" and isString(result.value) then
            return result.value
        end
        return nil
    end,
    computeAsValue = function(self, element, atTime)
        local result = self:RecursiveCompute(element, atTime)
        if result.type == "value" then
            if  not result.timeSpan:HasTime(atTime) then
                return nil
            end
            return result.value
        end
        return result.timeSpan:HasTime(atTime)
    end,
    computeParameters = function(self, node, atTime)
        if node.cachedParams.serial == nil or node.cachedParams.serial < self.self_serial then
            node.cachedParams.serial = self.self_serial
            for k, v in ipairs(node.rawPositionalParams) do
                node.cachedParams.positional[k] = self:computeAsValue(v, atTime) or false
            end
            for k, v in kpairs(node.rawNamedParams) do
                node.cachedParams.named[k] = self:computeAsValue(v, atTime)
            end
        end
        return node.cachedParams.positional, node.cachedParams.named
    end,
    computePositionalParameters = function(self, node, atTime)
        if node.cachedParams.serial == nil or node.cachedParams.serial < self.self_serial then
            node.cachedParams.serial = self.self_serial
            for k, v in ipairs(node.rawPositionalParams) do
                node.cachedParams.positional[k] = self:computeAsValue(v, atTime) or false
            end
        end
        return node.cachedParams.positional
    end,
})
