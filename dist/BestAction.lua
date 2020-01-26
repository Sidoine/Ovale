local __exports = LibStub:NewLibrary("ovale/BestAction", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Pool = LibStub:GetLibrary("ovale/Pool")
local OvalePool = __Pool.OvalePool
local __TimeSpan = LibStub:GetLibrary("ovale/TimeSpan")
local UNIVERSE = __TimeSpan.UNIVERSE
local newTimeSpanFromArray = __TimeSpan.newTimeSpanFromArray
local EMPTY_SET = __TimeSpan.EMPTY_SET
local newTimeSpan = __TimeSpan.newTimeSpan
local releaseTimeSpans = __TimeSpan.releaseTimeSpans
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local abs = math.abs
local huge = math.huge
local floor = math.floor
local min = math.min
local assert = assert
local ipairs = ipairs
local loadstring = loadstring
local pairs = pairs
local tonumber = tonumber
local wipe = wipe
local GetActionCooldown = GetActionCooldown
local GetActionTexture = GetActionTexture
local GetItemIcon = GetItemIcon
local GetItemCooldown = GetItemCooldown
local GetItemSpell = GetItemSpell
local GetSpellTexture = GetSpellTexture
local IsActionInRange = IsActionInRange
local IsCurrentAction = IsCurrentAction
local IsItemInRange = IsItemInRange
local IsUsableAction = IsUsableAction
local IsUsableItem = IsUsableItem
local __AST = LibStub:GetLibrary("ovale/AST")
local isNodeType = __AST.isNodeType
local __tools = LibStub:GetLibrary("ovale/tools")
local isNumber = __tools.isNumber
local isString = __tools.isString
local INFINITY = huge
__exports.OvaleBestActionClass = __class(nil, {
    constructor = function(self, ovaleEquipment, ovaleActionBar, ovaleData, ovaleCooldown, ovaleState, baseState, ovalePaperDoll, ovaleCompile, ovaleCondition, Ovale, OvaleGUID, OvalePower, OvaleFuture, OvaleSpellBook, ovaleProfiler, ovaleDebug, variables, ovaleRunes, OvaleSpells)
        self.ovaleEquipment = ovaleEquipment
        self.ovaleActionBar = ovaleActionBar
        self.ovaleData = ovaleData
        self.ovaleCooldown = ovaleCooldown
        self.ovaleState = ovaleState
        self.baseState = baseState
        self.ovalePaperDoll = ovalePaperDoll
        self.ovaleCompile = ovaleCompile
        self.ovaleCondition = ovaleCondition
        self.Ovale = Ovale
        self.OvaleGUID = OvaleGUID
        self.OvalePower = OvalePower
        self.OvaleFuture = OvaleFuture
        self.OvaleSpellBook = OvaleSpellBook
        self.variables = variables
        self.ovaleRunes = ovaleRunes
        self.OvaleSpells = OvaleSpells
        self.self_serial = 0
        self.self_timeSpan = {}
        self.self_valuePool = OvalePool("OvaleBestAction_valuePool")
        self.self_value = {}
        self.onInitialize = function()
            self.module:RegisterMessage("Ovale_ScriptChanged", self.Ovale_ScriptChanged)
        end
        self.OnDisable = function()
            self.module:UnregisterMessage("Ovale_ScriptChanged")
        end
        self.Ovale_ScriptChanged = function()
            for node, timeSpan in pairs(self.self_timeSpan) do
                timeSpan:Release()
                self.self_timeSpan[node] = nil
            end
            for node, value in pairs(self.self_value) do
                self.self_valuePool:Release(value)
                self.self_value[node] = nil
            end
        end
        self.ComputeAction = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeAction")
            local nodeId = element.nodeId
            local timeSpan = self:GetTimeSpan(element)
            local result
            self.tracer:Log("[%d]    evaluating action: %s(%s)", nodeId, element.name, element.paramsAsString)
            local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend, actionCharges = self:GetActionInfo(element, atTime)
            element.actionTexture = actionTexture
            element.actionInRange = actionInRange
            element.actionCooldownStart = actionCooldownStart
            element.actionCooldownDuration = actionCooldownDuration
            element.actionUsable = actionUsable
            element.actionShortcut = actionShortcut
            element.actionIsCurrent = actionIsCurrent
            element.actionEnable = actionEnable
            element.actionType = actionType
            element.actionId = actionId
            element.actionTarget = actionTarget
            element.actionResourceExtend = actionResourceExtend
            element.actionCharges = actionCharges
            local action = element.positionalParams[1]
            if  not actionTexture then
                self.tracer:Log("[%d]    Action %s not found.", nodeId, action)
                wipe(timeSpan)
            elseif  not actionEnable then
                self.tracer:Log("[%d]    Action %s not enabled.", nodeId, action)
                wipe(timeSpan)
            elseif element.namedParams.usable == 1 and  not actionUsable then
                self.tracer:Log("[%d]    Action %s not usable.", nodeId, action)
                wipe(timeSpan)
            else
                local spellInfo
                if actionType == "spell" then
                    local spellId = actionId
                    if spellId then
                        spellInfo = self.ovaleData.spellInfo[spellId]
                    end
                    if spellInfo and spellInfo.casttime then
                        element.castTime = spellInfo.casttime
                    else
                        element.castTime = self.OvaleSpellBook:GetCastTime(spellId)
                    end
                else
                    element.castTime = 0
                end
                local start
                if actionCooldownStart and actionCooldownStart > 0 and (actionCharges == nil or actionCharges == 0) then
                    self.tracer:Log("[%d]    Action %s (actionCharges=%s)", nodeId, action, actionCharges or "(nil)")
                    if actionCooldownDuration and actionCooldownDuration > 0 then
                        self.tracer:Log("[%d]    Action %s is on cooldown (start=%f, duration=%f).", nodeId, action, actionCooldownStart, actionCooldownDuration)
                        start = actionCooldownStart + actionCooldownDuration
                    else
                        self.tracer:Log("[%d]    Action %s is waiting on the GCD (start=%f).", nodeId, action, actionCooldownStart)
                        start = actionCooldownStart
                    end
                else
                    if actionCharges == nil then
                        self.tracer:Log("[%d]    Action %s is off cooldown.", nodeId, action)
                        start = atTime
                    elseif actionCooldownDuration and actionCooldownDuration > 0 then
                        self.tracer:Log("[%d]    Action %s still has %f charges and is not on GCD.", nodeId, action, actionCharges)
                        start = atTime
                    else
                        self.tracer:Log("[%d]    Action %s still has %f charges but is on GCD (start=%f).", nodeId, action, actionCharges, actionCooldownStart)
                        start = actionCooldownStart or 0
                    end
                end
                if actionResourceExtend and actionResourceExtend > 0 then
                    if element.namedParams.pool_resource and element.namedParams.pool_resource == 1 then
                        self.tracer:Log("[%d]    Action %s is ignoring resource requirements because it is a pool_resource action.", nodeId, action)
                    else
                        self.tracer:Log("[%d]    Action %s is waiting on resources (start=%f, extend=%f).", nodeId, action, start, actionResourceExtend)
                        start = start + actionResourceExtend
                    end
                end
                self.tracer:Log("[%d]    start=%f atTime=%f", nodeId, start, atTime)
                local offgcd = element.namedParams.offgcd or (spellInfo and spellInfo.offgcd) or 0
                element.offgcd = (offgcd == 1) and true or nil
                if element.offgcd then
                    self.tracer:Log("[%d]    Action %s is off the global cooldown.", nodeId, action)
                elseif start < atTime then
                    self.tracer:Log("[%d]    Action %s is waiting for the global cooldown.", nodeId, action)
                    local newStart = atTime
                    if self.OvaleFuture:IsChanneling(atTime) then
                        local spell = self.OvaleFuture:GetCurrentCast(atTime)
                        if spell then
                            local si = spell.spellId and self.ovaleData.spellInfo[spell.spellId]
                            if si then
                                local channel = si.channel or si.canStopChannelling
                                if channel then
                                    local hasteMultiplier = self.ovalePaperDoll:GetHasteMultiplier(si.haste, self.ovalePaperDoll.next)
                                    local numTicks = floor(channel * hasteMultiplier + 0.5)
                                    local tick = (spell.stop - spell.start) / numTicks
                                    local tickTime = spell.start
                                    for i = 1, numTicks, 1 do
                                        tickTime = tickTime + tick
                                        if newStart <= tickTime then
                                            break
                                        end
                                    end
                                    newStart = tickTime
                                    self.tracer:Log("[%d]    %s start=%f, numTicks=%d, tick=%f, tickTime=%f", nodeId, spell.spellId, newStart, numTicks, tick, tickTime)
                                end
                            end
                        end
                    end
                    if start < newStart then
                        start = newStart
                    end
                end
                self.tracer:Log("[%d]    Action %s can start at %f.", nodeId, action, start)
                timeSpan:Copy(start, INFINITY)
                result = element
            end
            self.profiler:StopProfiling("OvaleBestAction_ComputeAction")
            return timeSpan, result
        end
        self.ComputeArithmetic = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeArithmetic")
            local timeSpan = self:GetTimeSpan(element)
            local result
            local rawTimeSpanA, nodeA = self:Compute(element.child[1], atTime)
            local a, b, c, timeSpanA = self:AsValue(atTime, rawTimeSpanA, nodeA)
            local rawTimeSpanB, nodeB = self:Compute(element.child[2], atTime)
            local x, y, z, timeSpanB = self:AsValue(atTime, rawTimeSpanB, nodeB)
            timeSpanA:Intersect(timeSpanB, timeSpan)
            if timeSpan:Measure() == 0 then
                self.tracer:Log("[%d]    arithmetic '%s' returns %s with zero measure", element.nodeId, element.operator, timeSpan)
                result = self:SetValue(element, 0)
            else
                local operator = element.operator
                local t = atTime
                self.tracer:Log("[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s", element.nodeId, a, b, c, operator, x, y, z)
                local l, m, n
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
                            self.Ovale:OneTimeMessage("[%d] Division by 0 in %s", element.nodeId, element.asString)
                        end
                        B = 0.00001
                    end
                    l = A / B
                    m = t
                    local numerator = B * c - A * z
                    if numerator ~= INFINITY then
                        n = numerator / (B ^ 2)
                    else
                        n = numerator
                    end
                    local bound
                    if z == 0 then
                        bound = INFINITY
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
                result = self:SetValue(element, l, m, n)
            end
            self.profiler:StopProfiling("OvaleBestAction_ComputeArithmetic")
            return timeSpan, result
        end
        self.ComputeCompare = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeCompare")
            local timeSpan = self:GetTimeSpan(element)
            local rawTimeSpanA, elementA = self:Compute(element.child[1], atTime)
            local a, b, c, timeSpanA = self:AsValue(atTime, rawTimeSpanA, elementA)
            local rawTimeSpanB, elementB = self:Compute(element.child[2], atTime)
            local x, y, z, timeSpanB = self:AsValue(atTime, rawTimeSpanB, elementB)
            timeSpanA:Intersect(timeSpanB, timeSpan)
            if timeSpan:Measure() == 0 then
                self.tracer:Log("[%d]    compare '%s' returns %s with zero measure", element.nodeId, element.operator, timeSpan)
            else
                local operator = element.operator
                self.tracer:Log("[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s", element.nodeId, a, b, c, operator, x, y, z)
                local A = a - b * c
                local B = x - y * z
                if c == z then
                    if  not ((operator == "==" and A == B) or (operator == "!=" and A ~= B) or (operator == "<" and A < B) or (operator == "<=" and A <= B) or (operator == ">" and A > B) or (operator == ">=" and A >= B)) then
                        wipe(timeSpan)
                    end
                else
                    local diff = B - A
                    local t
                    if diff == INFINITY then
                        t = INFINITY
                    else
                        t = diff / (c - z)
                    end
                    t = (t > 0) and t or 0
                    self.tracer:Log("[%d]    intersection at t = %s", element.nodeId, t)
                    local scratch
                    if (c > z and operator == "<") or (c > z and operator == "<=") or (c < z and operator == ">") or (c < z and operator == ">=") then
                        scratch = timeSpan:IntersectInterval(0, t)
                    elseif (c < z and operator == "<") or (c < z and operator == "<=") or (c > z and operator == ">") or (c > z and operator == ">=") then
                        scratch = timeSpan:IntersectInterval(t, INFINITY)
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
            return timeSpan, element
        end
        self.ComputeCustomFunction = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeCustomFunction")
            local timeSpan = self:GetTimeSpan(element)
            local result
            local node = self.ovaleCompile:GetFunctionNode(element.name)
            if node then
                local timeSpanA, elementA = self:Compute(node.child[1], atTime)
                if timeSpanA then
                    timeSpan:copyFromArray(timeSpanA)
                end
                result = elementA
            else
                wipe(timeSpan)
            end
            self.profiler:StopProfiling("OvaleBestAction_ComputeCustomFunction")
            return timeSpan, result
        end
        self.ComputeFunction = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeFunction")
            local timeSpan = self:GetTimeSpan(element)
            local result
            local start, ending, value, origin, rate = self.ovaleCondition:EvaluateCondition(element.func, element.positionalParams, element.namedParams, atTime)
            if start ~= nil and ending ~= nil then
                timeSpan:Copy(start, ending)
            else
                wipe(timeSpan)
            end
            if value ~= nil then
                result = self:SetValue(element, value, origin, rate)
            end
            self.tracer:Log("[%d]    condition '%s' returns %s, %s, %s, %s, %s", element.nodeId, element.name, start, ending, value, origin, rate)
            self.profiler:StopProfiling("OvaleBestAction_ComputeFunction")
            return timeSpan, result
        end
        self.ComputeGroup = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeGroup")
            local bestTimeSpan, bestElement
            local best = newTimeSpan()
            local current = newTimeSpan()
            for _, node in ipairs(element.child) do
                local currentTimeSpan, currentElement = self:Compute(node, atTime)
                currentTimeSpan:IntersectInterval(atTime, INFINITY, current)
                if current:Measure() > 0 then
                    local nodeString = (currentElement and currentElement.nodeId) and " [" .. currentElement.nodeId .. "]" or ""
                    self.tracer:Log("[%d]    group checking [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString)
                    local currentCastTime
                    if currentElement then
                        currentCastTime = currentElement.castTime
                    end
                    local gcd = self.OvaleFuture:GetGCD(nil, atTime)
                    if  not currentCastTime or currentCastTime < gcd then
                        currentCastTime = gcd
                    end
                    local currentIsBetter = false
                    if best:Measure() == 0 then
                        self.tracer:Log("[%d]    group first best is [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString)
                        currentIsBetter = true
                    else
                        local threshold = (bestElement and bestElement.namedParams) and bestElement.namedParams.wait or 0
                        if best[1] - current[1] > threshold then
                            self.tracer:Log("[%d]    group new best is [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString)
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
            local timeSpan = self:GetTimeSpan(element, bestTimeSpan)
            if  not bestTimeSpan then
                wipe(timeSpan)
            end
            if bestElement then
                local id = bestElement.value
                if bestElement.positionalParams then
                    id = bestElement.positionalParams[1]
                end
                self.tracer:Log("[%d]    group best action %s remains %s", element.nodeId, id, timeSpan)
            else
                self.tracer:Log("[%d]    group no best action returns %s", element.nodeId, timeSpan)
            end
            self.profiler:StopProfiling("OvaleBestAction_ComputeGroup")
            return timeSpan, bestElement
        end
        self.ComputeIf = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeIf")
            local timeSpan = self:GetTimeSpan(element)
            local result
            local timeSpanA = self:ComputeBool(element.child[1], atTime)
            local conditionTimeSpan = timeSpanA
            if element.type == "unless" then
                conditionTimeSpan = timeSpanA:Complement()
            end
            if conditionTimeSpan:Measure() == 0 then
                timeSpan:copyFromArray(conditionTimeSpan)
                self.tracer:Log("[%d]    '%s' returns %s with zero measure", element.nodeId, element.type, timeSpan)
            else
                local timeSpanB, elementB = self:Compute(element.child[2], atTime)
                conditionTimeSpan:Intersect(timeSpanB, timeSpan)
                self.tracer:Log("[%d]    '%s' returns %s (intersection of %s and %s)", element.nodeId, element.type, timeSpan, conditionTimeSpan, timeSpanB)
                result = elementB
            end
            if element.type == "unless" then
                conditionTimeSpan:Release()
            end
            self.profiler:StopProfiling("OvaleBestAction_ComputeIf")
            return timeSpan, result
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
            return timeSpan, element
        end
        self.ComputeLua = function(element, atTime)
            if  not element.lua then
                return EMPTY_SET
            end
            self.profiler:StartProfiling("OvaleBestAction_ComputeLua")
            local value = loadstring(element.lua)()
            self.tracer:Log("[%d]    lua returns %s", element.nodeId, value)
            local result
            if value then
                result = self:SetValue(element, value)
            end
            local timeSpan = self:GetTimeSpan(element, UNIVERSE)
            self.profiler:StopProfiling("OvaleBestAction_ComputeLua")
            return timeSpan, result
        end
        self.ComputeState = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeState")
            local result = element
            assert(element.func == "setstate")
            local name = element.positionalParams[1]
            local value = element.positionalParams[2]
            self.tracer:Log("[%d]    %s: %s = %s", element.nodeId, element.name, element.positionalParams[1], element.positionalParams[2])
            local currentValue = self.variables:GetState(name)
            local timeSpan
            if currentValue ~= value then
                timeSpan = self:GetTimeSpan(element, UNIVERSE)
            else
                timeSpan = EMPTY_SET
            end
            self.profiler:StopProfiling("OvaleBestAction_ComputeState")
            return timeSpan, result
        end
        self.ComputeValue = function(element, atTime)
            self.profiler:StartProfiling("OvaleBestAction_ComputeValue")
            self.tracer:Log("[%d]    value is %s", element.nodeId, element.value)
            local timeSpan = self:GetTimeSpan(element, UNIVERSE)
            self.profiler:StopProfiling("OvaleBestAction_ComputeValue")
            return timeSpan, element
        end
        self.COMPUTE_VISITOR = {
            ["action"] = self.ComputeAction,
            ["arithmetic"] = self.ComputeArithmetic,
            ["compare"] = self.ComputeCompare,
            ["custom_function"] = self.ComputeCustomFunction,
            ["function"] = self.ComputeFunction,
            ["group"] = self.ComputeGroup,
            ["if"] = self.ComputeIf,
            ["logical"] = self.ComputeLogical,
            ["lua"] = self.ComputeLua,
            ["state"] = self.ComputeState,
            ["unless"] = self.ComputeIf,
            ["value"] = self.ComputeValue
        }
        self.module = Ovale:createModule("BestAction", self.onInitialize, self.OnDisable, aceEvent)
        self.profiler = ovaleProfiler:create(self.module:GetName())
        self.tracer = ovaleDebug:create(self.module:GetName())
    end,
    SetValue = function(self, node, value, origin, rate)
        local result = self.self_value[node.nodeId]
        if  not result then
            result = self.self_valuePool:Get()
            self.self_value[node.nodeId] = result
        end
        result.type = "value"
        result.value = value or 0
        result.origin = origin or 0
        result.rate = rate or 0
        return result
    end,
    AsValue = function(self, atTime, timeSpan, node)
        local value, origin, rate
        if node and isNodeType(node, "value") then
            value = node.value
            origin = node.origin
            rate = node.rate
            timeSpan = timeSpan or UNIVERSE
        elseif timeSpan and timeSpan:HasTime(atTime) then
            value, origin, rate, timeSpan = 1, 0, 0, UNIVERSE
        else
            value, origin, rate, timeSpan = 0, 0, 0, UNIVERSE
        end
        return value, origin, rate, timeSpan
    end,
    GetTimeSpan = function(self, node, defaultTimeSpan)
        local timeSpan = self.self_timeSpan[node.nodeId]
        if timeSpan then
            if defaultTimeSpan then
                timeSpan:copyFromArray(defaultTimeSpan)
            end
        else
            self.self_timeSpan[node.nodeId] = newTimeSpanFromArray(defaultTimeSpan)
            timeSpan = self.self_timeSpan[node.nodeId]
        end
        return timeSpan
    end,
    GetActionItemInfo = function(self, element, atTime, target)
        self.profiler:StartProfiling("OvaleBestAction_GetActionItemInfo")
        local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId
        local itemId = element.positionalParams[1]
        if  not isNumber(itemId) then
            local itemIdFromSlot = self.ovaleEquipment:GetEquippedItemBySlotName(itemId)
            if  not itemIdFromSlot then
                self.tracer:Log("Unknown item '%s'.", element.positionalParams[1])
                return
            end
            itemId = itemIdFromSlot
        end
        self.tracer:Log("Item ID '%s'", itemId)
        local action = self.ovaleActionBar:GetForItem(itemId)
        local spellName = GetItemSpell(itemId)
        if element.namedParams.texture then
            actionTexture = "Interface\\Icons\\" .. element.namedParams.texture
        end
        actionTexture = actionTexture or GetItemIcon(itemId)
        actionInRange = IsItemInRange(itemId, target)
        actionCooldownStart, actionCooldownDuration, actionEnable = GetItemCooldown(itemId)
        actionUsable = (spellName and IsUsableItem(itemId) and self.OvaleSpells:IsUsableItem(itemId, atTime)) or false
        if action then
            actionShortcut = self.ovaleActionBar:GetBinding(action)
            actionIsCurrent = IsCurrentAction(action)
        end
        actionType = "item"
        actionId = itemId
        self.profiler:StopProfiling("OvaleBestAction_GetActionItemInfo")
        return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent or false, actionEnable, actionType, actionId, target, 0, 0
    end,
    GetActionMacroInfo = function(self, element, atTime, target)
        self.profiler:StartProfiling("OvaleBestAction_GetActionMacroInfo")
        local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId
        local macro = element.positionalParams[1]
        local action = self.ovaleActionBar:GetForMacro(macro)
        if  not action then
            self.tracer:Log("Unknown macro '%s'.", macro)
            return
        end
        if element.namedParams.texture then
            actionTexture = "Interface\\Icons\\" .. element.namedParams.texture
        end
        actionTexture = actionTexture or GetActionTexture(action)
        actionInRange = IsActionInRange(action, target)
        actionCooldownStart, actionCooldownDuration, actionEnable = GetActionCooldown(action)
        actionUsable = IsUsableAction(action)
        actionShortcut = self.ovaleActionBar:GetBinding(action)
        actionIsCurrent = IsCurrentAction(action)
        actionType = "macro"
        actionId = macro
        self.profiler:StopProfiling("OvaleBestAction_GetActionMacroInfo")
        return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target, 0, 0
    end,
    GetActionSpellInfo = function(self, element, atTime, target)
        self.profiler:StartProfiling("OvaleBestAction_GetActionSpellInfo")
        local spell = element.positionalParams[1]
        if isNumber(spell) then
            return self:getSpellActionInfo(spell, element, atTime, target)
        elseif isString(spell) then
            local spellList = self.ovaleData.buffSpellList[spell]
            for spellId in pairs(spellList) do
                if self.OvaleSpellBook:IsKnownSpell(spellId) then
                    return self:getSpellActionInfo(spellId, element, atTime, target)
                end
            end
        end
        return
    end,
    getSpellActionInfo = function(self, spellId, element, atTime, target)
        local targetGUID = self.OvaleGUID:UnitGUID(target)
        if  not targetGUID then
            return
        end
        local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionResourceExtend, actionCharges
        local si = self.ovaleData.spellInfo[spellId]
        local replacedSpellId = nil
        if si and si.replaced_by then
            local replacement = self.ovaleData:GetSpellInfoProperty(spellId, atTime, "replaced_by", targetGUID)
            if replacement then
                replacedSpellId = spellId
                spellId = replacement
                si = self.ovaleData.spellInfo[spellId]
                self.tracer:Log("Spell ID '%s' is replaced by spell ID '%s'.", replacedSpellId, spellId)
            end
        end
        local action = self.ovaleActionBar:GetForSpell(spellId)
        if  not action and replacedSpellId then
            self.tracer:Log("Action not found for spell ID '%s'; checking for replaced spell ID '%s'.", spellId, replacedSpellId)
            action = self.ovaleActionBar:GetForSpell(replacedSpellId)
            if action then
                spellId = replacedSpellId
            end
        end
        local isKnownSpell = self.OvaleSpellBook:IsKnownSpell(spellId)
        if  not isKnownSpell and replacedSpellId then
            self.tracer:Log("Spell ID '%s' is not known; checking for replaced spell ID '%s'.", spellId, replacedSpellId)
            isKnownSpell = self.OvaleSpellBook:IsKnownSpell(replacedSpellId)
            if isKnownSpell then
                spellId = replacedSpellId
            end
        end
        if  not isKnownSpell and  not action then
            self.tracer:Log("Unknown spell ID '%s'.", spellId)
            return
        end
        local isUsable, noMana = self.OvaleSpells:IsUsableSpell(spellId, atTime, targetGUID)
        self.tracer:Log("OvaleSpells:IsUsableSpell(%d, %f, %s) returned %d, %d", spellId, atTime, targetGUID, isUsable, noMana)
        if  not isUsable and  not noMana then
            return
        end
        if element.namedParams.texture then
            actionTexture = "Interface\\Icons\\" .. element.namedParams.texture
        end
        actionTexture = actionTexture or GetSpellTexture(spellId)
        actionInRange = self.OvaleSpells:IsSpellInRange(spellId, target)
        actionCooldownStart, actionCooldownDuration, actionEnable = self.ovaleCooldown:GetSpellCooldown(spellId, atTime)
        self.tracer:Log("GetSpellCooldown returned %f, %f", actionCooldownStart, actionCooldownDuration)
        actionCharges = self.ovaleCooldown:GetSpellCharges(spellId, atTime)
        actionResourceExtend = 0
        actionUsable = isUsable
        if action then
            actionShortcut = self.ovaleActionBar:GetBinding(action)
            actionIsCurrent = IsCurrentAction(action)
        end
        actionType = "spell"
        actionId = spellId
        if si then
            if si.texture then
                actionTexture = "Interface\\Icons\\" .. si.texture
            end
            if actionCooldownStart and actionCooldownDuration then
                local extraPower = element.namedParams.extra_amount or 0
                local timeToCd = (actionCooldownDuration > 0) and (actionCooldownStart + actionCooldownDuration - atTime) or 0
                local timeToPower = self.OvalePower:TimeToPower(spellId, atTime, targetGUID, nil, extraPower)
                local runes = self.ovaleData:GetSpellInfoProperty(spellId, atTime, "runes", targetGUID)
                if runes then
                    local timeToRunes = self.ovaleRunes:GetRunesCooldown(atTime, runes)
                    if timeToPower < timeToRunes then
                        timeToPower = timeToRunes
                    end
                end
                if timeToPower > timeToCd then
                    actionResourceExtend = timeToPower - timeToCd
                    self.tracer:Log("Spell ID '%s' requires an extra %fs for primary resource.", spellId, actionResourceExtend)
                end
            end
        end
        self.profiler:StopProfiling("OvaleBestAction_GetActionSpellInfo")
        return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent or false, actionEnable, actionType, actionId, target, actionResourceExtend, actionCharges
    end,
    GetActionTextureInfo = function(self, element, atTime, target)
        self.profiler:StartProfiling("OvaleBestAction_GetActionTextureInfo")
        local actionTexture
        do
            local texture = element.positionalParams[1]
            local spellId = tonumber(texture)
            if spellId then
                actionTexture = GetSpellTexture(spellId)
            else
                actionTexture = "Interface\\Icons\\" .. texture
            end
        end
        local actionInRange = false
        local actionCooldownStart = 0
        local actionCooldownDuration = 0
        local actionEnable = true
        local actionUsable = true
        local actionShortcut = nil
        local actionIsCurrent = false
        local actionType = "texture"
        local actionId = actionTexture
        self.profiler:StopProfiling("OvaleBestAction_GetActionTextureInfo")
        return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target, 0, 0
    end,
    StartNewAction = function(self)
        self.ovaleState:ResetState()
        self.OvaleFuture:ApplyInFlightSpells()
        self.self_serial = self.self_serial + 1
    end,
    GetActionInfo = function(self, element, atTime)
        if element and element.type == "action" then
            if element.serial and element.serial >= self.self_serial then
                self.tracer:Log("[%d]    using cached result (age = %d/%d)", element.nodeId, element.serial, self.self_serial)
                return element.actionTexture, element.actionInRange, element.actionCooldownStart, element.actionCooldownDuration, element.actionUsable, element.actionShortcut, element.actionIsCurrent, element.actionEnable, element.actionType, element.actionId, element.actionTarget, element.actionResourceExtend, element.actionCharges
            else
                local target = element.namedParams.target or self.baseState.next.defaultTarget
                if element.name == "item" then
                    return self:GetActionItemInfo(element, atTime, target)
                elseif element.name == "macro" then
                    return self:GetActionMacroInfo(element, atTime, target)
                elseif element.name == "spell" then
                    return self:GetActionSpellInfo(element, atTime, target)
                elseif element.name == "texture" then
                    return self:GetActionTextureInfo(element, atTime, target)
                end
            end
        end
        return
    end,
    GetAction = function(self, node, atTime)
        self.profiler:StartProfiling("OvaleBestAction_GetAction")
        local groupNode = node.child[1]
        local timeSpan, element = self:PostOrderCompute(groupNode, atTime)
        if element and element.type == "state" and timeSpan then
            local variable, value = element.positionalParams[1], element.positionalParams[2]
            local isFuture =  not timeSpan:HasTime(atTime)
            self.variables:PutState(variable, value, isFuture, atTime)
        end
        self.profiler:StopProfiling("OvaleBestAction_GetAction")
        return timeSpan, element
    end,
    PostOrderCompute = function(self, element, atTime)
        self.profiler:StartProfiling("OvaleBestAction_PostOrderCompute")
        local timeSpan, result
        local postOrder = element.postOrder
        if postOrder and  not (element.serial and element.serial >= self.self_serial) then
            local index = 1
            local N = #postOrder
            while index < N do
                local childNode, parentNode = postOrder[index], postOrder[index + 1]
                index = index + 2
                timeSpan, result = self:PostOrderCompute(childNode, atTime)
                if parentNode and timeSpan then
                    local shortCircuit = false
                    if parentNode.child and parentNode.child[1] == childNode then
                        if parentNode.type == "if" and timeSpan:Measure() == 0 then
                            self.tracer:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero-measure time span.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        elseif parentNode.type == "unless" and timeSpan:IsUniverse() then
                            self.tracer:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        elseif parentNode.type == "logical" and parentNode.operator == "and" and timeSpan:Measure() == 0 then
                            self.tracer:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero measure.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        elseif parentNode.type == "logical" and parentNode.operator == "or" and timeSpan:IsUniverse() then
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
        timeSpan, result = self:RecursiveCompute(element, atTime)
        self.profiler:StopProfiling("OvaleBestAction_PostOrderCompute")
        return timeSpan, result
    end,
    RecursiveCompute = function(self, element, atTime)
        self.profiler:StartProfiling("OvaleBestAction_RecursiveCompute")
        local timeSpan, result
        if element then
            if element.serial == -1 then
                self.Ovale:OneTimeMessage("Recursive call is not supported. This is a known bug with arcane mage script")
                return EMPTY_SET, element.result
            elseif element.serial and element.serial >= self.self_serial then
                timeSpan = element.timeSpan or EMPTY_SET
                result = element.result
            else
                if element.asString then
                    self.tracer:Log("[%d] >>> Computing '%s' at time=%f: %s", element.nodeId, element.type, atTime, element.asString)
                else
                    self.tracer:Log("[%d] >>> Computing '%s' at time=%f", element.nodeId, element.type, atTime)
                end
                element.serial = -1
                local visitor = self.COMPUTE_VISITOR[element.type]
                if visitor then
                    timeSpan, result = visitor(element, atTime)
                    element.serial = self.self_serial
                    element.timeSpan = timeSpan
                    element.result = result
                else
                    self.tracer:Log("[%d] Runtime error: unable to compute node of type '%s'.", element.nodeId, element.type)
                    timeSpan = EMPTY_SET
                end
                if result and isNodeType(result, "value") then
                    self.tracer:Log("[%d] <<< '%s' returns %s with value = %s, %s, %s", element.nodeId, element.type, timeSpan, result.value, result.origin, result.rate)
                elseif result and result.nodeId then
                    self.tracer:Log("[%d] <<< '%s' returns [%d] %s", element.nodeId, element.type, result.nodeId, timeSpan)
                else
                    self.tracer:Log("[%d] <<< '%s' returns %s", element.nodeId, element.type, timeSpan)
                end
            end
        else
            timeSpan = EMPTY_SET
        end
        self.profiler:StopProfiling("OvaleBestAction_RecursiveCompute")
        return timeSpan, result
    end,
    ComputeBool = function(self, element, atTime)
        local timeSpan, newElement = self:Compute(element, atTime)
        if newElement and isNodeType(newElement, "value") and newElement.value == 0 and newElement.rate == 0 then
            return EMPTY_SET
        else
            return timeSpan
        end
    end,
    Compute = function(self, element, atTime)
        return self:PostOrderCompute(element, atTime)
    end,
})
