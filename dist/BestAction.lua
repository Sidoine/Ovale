local __exports = LibStub:NewLibrary("ovale/BestAction", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Pool = LibStub:GetLibrary("ovale/Pool")
local OvalePool = __Pool.OvalePool
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __TimeSpan = LibStub:GetLibrary("ovale/TimeSpan")
local UNIVERSE = __TimeSpan.UNIVERSE
local newTimeSpanFromArray = __TimeSpan.newTimeSpanFromArray
local EMPTY_SET = __TimeSpan.EMPTY_SET
local newTimeSpan = __TimeSpan.newTimeSpan
local releaseTimeSpans = __TimeSpan.releaseTimeSpans
local __ActionBar = LibStub:GetLibrary("ovale/ActionBar")
local OvaleActionBar = __ActionBar.OvaleActionBar
local __Compile = LibStub:GetLibrary("ovale/Compile")
local OvaleCompile = __Compile.OvaleCompile
local __Condition = LibStub:GetLibrary("ovale/Condition")
local OvaleCondition = __Condition.OvaleCondition
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
local __Equipment = LibStub:GetLibrary("ovale/Equipment")
local OvaleEquipment = __Equipment.OvaleEquipment
local __GUID = LibStub:GetLibrary("ovale/GUID")
local OvaleGUID = __GUID.OvaleGUID
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local abs = math.abs
local huge = math.huge
local floor = math.floor
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
local isValueNode = __AST.isValueNode
local __Future = LibStub:GetLibrary("ovale/Future")
local OvaleFuture = __Future.OvaleFuture
local __Power = LibStub:GetLibrary("ovale/Power")
local OvalePower = __Power.OvalePower
local __Cooldown = LibStub:GetLibrary("ovale/Cooldown")
local OvaleCooldown = __Cooldown.OvaleCooldown
local __Runes = LibStub:GetLibrary("ovale/Runes")
local OvaleRunes = __Runes.OvaleRunes
local __Variables = LibStub:GetLibrary("ovale/Variables")
local variables = __Variables.variables
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local __BaseState = LibStub:GetLibrary("ovale/BaseState")
local baseState = __BaseState.baseState
local __Spells = LibStub:GetLibrary("ovale/Spells")
local OvaleSpells = __Spells.OvaleSpells
local __tools = LibStub:GetLibrary("ovale/tools")
local isNumber = __tools.isNumber
local OvaleBestActionBase = OvaleDebug:RegisterDebugging(OvaleProfiler:RegisterProfiling(Ovale:NewModule("OvaleBestAction", aceEvent)))
local INFINITY = huge
local self_serial = 0
local self_timeSpan = {}
local self_valuePool = OvalePool("OvaleBestAction_valuePool")
local self_value = {}
__exports.OvaleBestAction = nil
local function SetValue(node, value, origin, rate)
    local result = self_value[node.nodeId]
    if  not result then
        result = self_valuePool:Get()
        self_value[node.nodeId] = result
    end
    result.type = "value"
    result.value = value or 0
    result.origin = origin or 0
    result.rate = rate or 0
    return result
end
local function AsValue(atTime, timeSpan, node)
    local value, origin, rate
    if node and isValueNode(node) then
        value, origin, rate = node.value, node.origin, node.rate
    elseif timeSpan and timeSpan:HasTime(atTime) then
        value, origin, rate, timeSpan = 1, 0, 0, UNIVERSE
    else
        value, origin, rate, timeSpan = 0, 0, 0, UNIVERSE
    end
    return value, origin, rate, timeSpan
end
local function GetTimeSpan(node, defaultTimeSpan)
    local timeSpan = self_timeSpan[node.nodeId]
    if timeSpan then
        if defaultTimeSpan then
            timeSpan:copyFromArray(defaultTimeSpan)
        end
    else
        self_timeSpan[node.nodeId] = newTimeSpanFromArray(defaultTimeSpan)
        timeSpan = self_timeSpan[node.nodeId]
    end
    return timeSpan
end
local function GetActionItemInfo(element, state, atTime, target)
    __exports.OvaleBestAction:StartProfiling("OvaleBestAction_GetActionItemInfo")
    local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId
    local itemId = element.positionalParams[1]
    if  not isNumber(itemId) then
        itemId = OvaleEquipment:GetEquippedItem(itemId)
    end
    if  not itemId then
        __exports.OvaleBestAction:Log("Unknown item '%s'.", element.positionalParams[1])
    else
        __exports.OvaleBestAction:Log("Item ID '%s'", itemId)
        local action = OvaleActionBar:GetForItem(itemId)
        local spellName = GetItemSpell(itemId)
        if element.namedParams.texture then
            actionTexture = "Interface\\Icons\\" .. element.namedParams.texture
        end
        actionTexture = actionTexture or GetItemIcon(itemId)
        actionInRange = IsItemInRange(itemId, target)
        actionCooldownStart, actionCooldownDuration, actionEnable = GetItemCooldown(itemId)
        actionUsable = spellName and IsUsableItem(itemId) and OvaleSpells:IsUsableItem(itemId, atTime)
        if action then
            actionShortcut = OvaleActionBar:GetBinding(action)
            actionIsCurrent = IsCurrentAction(action)
        end
        actionType = "item"
        actionId = itemId
    end
    __exports.OvaleBestAction:StopProfiling("OvaleBestAction_GetActionItemInfo")
    return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end
local function GetActionMacroInfo(element, state, atTime, target)
    __exports.OvaleBestAction:StartProfiling("OvaleBestAction_GetActionMacroInfo")
    local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId
    local macro = element.positionalParams[1]
    local action = OvaleActionBar:GetForMacro(macro)
    if  not action then
        __exports.OvaleBestAction:Log("Unknown macro '%s'.", macro)
    else
        if element.namedParams.texture then
            actionTexture = "Interface\\Icons\\" .. element.namedParams.texture
        end
        actionTexture = actionTexture or GetActionTexture(action)
        actionInRange = IsActionInRange(action, target)
        actionCooldownStart, actionCooldownDuration, actionEnable = GetActionCooldown(action)
        actionUsable = IsUsableAction(action)
        actionShortcut = OvaleActionBar:GetBinding(action)
        actionIsCurrent = IsCurrentAction(action)
        actionType = "macro"
        actionId = macro
    end
    __exports.OvaleBestAction:StopProfiling("OvaleBestAction_GetActionMacroInfo")
    return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end
local function GetActionSpellInfo(element, state, atTime, target)
    __exports.OvaleBestAction:StartProfiling("OvaleBestAction_GetActionSpellInfo")
    local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionResourceExtend, actionCharges
    local targetGUID = OvaleGUID:UnitGUID(target)
    local spellId = element.positionalParams[1]
    local si = OvaleData.spellInfo[spellId]
    local replacedSpellId = nil
    if si and si.replace then
        local replacement = OvaleData:GetSpellInfoProperty(spellId, atTime, "replace", targetGUID)
        if replacement then
            replacedSpellId = spellId
            spellId = replacement
            si = OvaleData.spellInfo[spellId]
            __exports.OvaleBestAction:Log("Spell ID '%s' is replaced by spell ID '%s'.", replacedSpellId, spellId)
        end
    end
    local action = OvaleActionBar:GetForSpell(spellId)
    if  not action and replacedSpellId then
        __exports.OvaleBestAction:Log("Action not found for spell ID '%s'; checking for replaced spell ID '%s'.", spellId, replacedSpellId)
        action = OvaleActionBar:GetForSpell(replacedSpellId)
    end
    local isKnownSpell = OvaleSpellBook:IsKnownSpell(spellId)
    if  not isKnownSpell and replacedSpellId then
        __exports.OvaleBestAction:Log("Spell ID '%s' is not known; checking for replaced spell ID '%s'.", spellId, replacedSpellId)
        isKnownSpell = OvaleSpellBook:IsKnownSpell(replacedSpellId)
    end
    if  not isKnownSpell and  not action then
        __exports.OvaleBestAction:Log("Unknown spell ID '%s'.", spellId)
    else
        local isUsable, noMana = OvaleSpells:IsUsableSpell(spellId, atTime, targetGUID)
        if isUsable or noMana then
            if element.namedParams.texture then
                actionTexture = "Interface\\Icons\\" .. element.namedParams.texture
            end
            actionTexture = actionTexture or GetSpellTexture(spellId)
            actionInRange = OvaleSpells:IsSpellInRange(spellId, target)
            actionCooldownStart, actionCooldownDuration, actionEnable = OvaleCooldown:GetSpellCooldown(spellId, atTime)
            __exports.OvaleBestAction:Log("GetSpellCooldown returned %f, %f", actionCooldownStart, actionCooldownDuration)
            actionCharges = OvaleCooldown:GetSpellCharges(spellId, atTime)
            actionResourceExtend = 0
            actionUsable = isUsable
            if action then
                actionShortcut = OvaleActionBar:GetBinding(action)
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
                    local timeToPower = OvalePower:TimeToPower(spellId, atTime, targetGUID, nil, extraPower)
                    local runes = OvaleData:GetSpellInfoProperty(spellId, atTime, "runes", targetGUID)
                    if runes then
                        local timeToRunes = OvaleRunes:GetRunesCooldown(atTime, runes)
                        if timeToPower < timeToRunes then
                            timeToPower = timeToRunes
                        end
                    end
                    if timeToPower > timeToCd then
                        actionResourceExtend = timeToPower - timeToCd
                        __exports.OvaleBestAction:Log("Spell ID '%s' requires an extra %fs for primary resource.", spellId, actionResourceExtend)
                    end
                end
            end
        end
    end
    __exports.OvaleBestAction:StopProfiling("OvaleBestAction_GetActionSpellInfo")
    return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target, actionResourceExtend, actionCharges
end
local GetActionTextureInfo = function(element, state, atTime, target)
    __exports.OvaleBestAction:StartProfiling("OvaleBestAction_GetActionTextureInfo")
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
    local actionInRange = nil
    local actionCooldownStart = 0
    local actionCooldownDuration = 0
    local actionEnable = 1
    local actionUsable = true
    local actionShortcut = nil
    local actionIsCurrent = nil
    local actionType = "texture"
    local actionId = actionTexture
    __exports.OvaleBestAction:StopProfiling("OvaleBestAction_GetActionTextureInfo")
    return actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, target
end

local OvaleBestActionClass = __class(OvaleBestActionBase, {
    constructor = function(self)
        self.ComputeAction = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_ComputeAction")
            local nodeId = element.nodeId
            local timeSpan = GetTimeSpan(element)
            local result
            __exports.OvaleBestAction:Log("[%d]    evaluating action: %s(%s)", nodeId, element.name, element.paramsAsString)
            local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend, actionCharges = self:GetActionInfo(element, state, atTime)
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
                __exports.OvaleBestAction:Log("[%d]    Action %s not found.", nodeId, action)
                wipe(timeSpan)
            elseif  not (actionEnable and actionEnable > 0) then
                __exports.OvaleBestAction:Log("[%d]    Action %s not enabled.", nodeId, action)
                wipe(timeSpan)
            elseif element.namedParams.usable == 1 and  not actionUsable then
                __exports.OvaleBestAction:Log("[%d]    Action %s not usable.", nodeId, action)
                wipe(timeSpan)
            else
                local spellInfo
                if actionType == "spell" then
                    local spellId = actionId
                    spellInfo = spellId and OvaleData.spellInfo[spellId]
                    if spellInfo and spellInfo.casttime then
                        element.castTime = spellInfo.casttime
                    else
                        element.castTime = OvaleSpellBook:GetCastTime(spellId)
                    end
                else
                    element.castTime = 0
                end
                local start
                if actionCooldownStart and actionCooldownStart > 0 and (actionCharges == nil or actionCharges == 0) then
                    __exports.OvaleBestAction:Log("[%d]    Action %s (actionCharges=%s)", nodeId, action, actionCharges or "(nil)")
                    if actionCooldownDuration and actionCooldownDuration > 0 then
                        __exports.OvaleBestAction:Log("[%d]    Action %s is on cooldown (start=%f, duration=%f).", nodeId, action, actionCooldownStart, actionCooldownDuration)
                        start = actionCooldownStart + actionCooldownDuration
                    else
                        __exports.OvaleBestAction:Log("[%d]    Action %s is waiting on the GCD (start=%f).", nodeId, action, actionCooldownStart)
                        start = actionCooldownStart
                    end
                else
                    if actionCharges == nil then
                        __exports.OvaleBestAction:Log("[%d]    Action %s is off cooldown.", nodeId, action)
                        start = atTime
                    elseif actionCooldownDuration and actionCooldownDuration > 0 then
                        __exports.OvaleBestAction:Log("[%d]    Action %s still has %f charges and is not on GCD.", nodeId, action, actionCharges)
                        start = atTime
                    else
                        self:Log("[%d]    Action %s still has %f charges but is on GCD (start=%f).", nodeId, action, actionCharges, actionCooldownStart)
                        start = actionCooldownStart
                    end
                end
                if actionResourceExtend and actionResourceExtend > 0 then
                    if element.namedParams.pool_resource and element.namedParams.pool_resource == 1 then
                        __exports.OvaleBestAction:Log("[%d]    Action %s is ignoring resource requirements because it is a pool_resource action.", nodeId, action)
                    else
                        __exports.OvaleBestAction:Log("[%d]    Action %s is waiting on resources (start=%f, extend=%f).", nodeId, action, start, actionResourceExtend)
                        start = start + actionResourceExtend
                    end
                end
                __exports.OvaleBestAction:Log("[%d]    start=%f atTime=%f", nodeId, start, atTime)
                local offgcd = element.namedParams.offgcd or (spellInfo and spellInfo.offgcd) or 0
                element.offgcd = (offgcd == 1) and true or nil
                if element.offgcd then
                    __exports.OvaleBestAction:Log("[%d]    Action %s is off the global cooldown.", nodeId, action)
                elseif start < atTime then
                    __exports.OvaleBestAction:Log("[%d]    Action %s is waiting for the global cooldown.", nodeId, action)
                    local newStart = atTime
                    if OvaleFuture:IsChanneling(atTime) then
                        local spell = OvaleFuture:GetCurrentCast(atTime)
                        local si = spell and spell.spellId and OvaleData.spellInfo[spell.spellId]
                        if si then
                            local channel = si.channel or si.canStopChannelling
                            if channel then
                                local hasteMultiplier = OvalePaperDoll:GetHasteMultiplier(si.haste, OvalePaperDoll.next)
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
                                __exports.OvaleBestAction:Log("[%d]    %s start=%f, numTicks=%d, tick=%f, tickTime=%f", nodeId, spell.spellId, newStart, numTicks, tick, tickTime)
                            end
                        end
                    end
                    if start < newStart then
                        start = newStart
                    end
                end
                __exports.OvaleBestAction:Log("[%d]    Action %s can start at %f.", nodeId, action, start)
                timeSpan:Copy(start, INFINITY)
                result = element
            end
            self:StopProfiling("OvaleBestAction_ComputeAction")
            return timeSpan, result
        end
        self.ComputeArithmetic = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local timeSpan = GetTimeSpan(element)
            local result
            local rawTimeSpanA, nodeA = self:Compute(element.child[1], state, atTime)
            local a, b, c, timeSpanA = AsValue(atTime, rawTimeSpanA, nodeA)
            local rawTimeSpanB, nodeB = self:Compute(element.child[2], state, atTime)
            local x, y, z, timeSpanB = AsValue(atTime, rawTimeSpanB, nodeB)
            timeSpanA:Intersect(timeSpanB, timeSpan)
            if timeSpan:Measure() == 0 then
                __exports.OvaleBestAction:Log("[%d]    arithmetic '%s' returns %s with zero measure", element.nodeId, element.operator, timeSpan)
                result = SetValue(element, 0)
            else
                local operator = element.operator
                local t = atTime
                __exports.OvaleBestAction:Log("[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s", element.nodeId, a, b, c, operator, x, y, z)
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
                        Ovale:OneTimeMessage("[%d] Division by 0 in %s", element.nodeId, element.asString)
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
                        self:Error("[%d]    Parameters of modulus operator '%' must be constants.", element.nodeId)
                        l = 0
                        m = 0
                        n = 0
                    end
                end
                __exports.OvaleBestAction:Log("[%d]    arithmetic '%s' returns %s+(t-%s)*%s", element.nodeId, operator, l, m, n)
                result = SetValue(element, l, m, n)
            end
            self:StopProfiling("OvaleBestAction_Compute")
            return timeSpan, result
        end
        self.ComputeCompare = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local timeSpan = GetTimeSpan(element)
            local rawTimeSpanA, elementA = self:Compute(element.child[1], state, atTime)
            local a, b, c, timeSpanA = AsValue(atTime, rawTimeSpanA, elementA)
            local rawTimeSpanB, elementB = self:Compute(element.child[2], state, atTime)
            local x, y, z, timeSpanB = AsValue(atTime, rawTimeSpanB, elementB)
            timeSpanA:Intersect(timeSpanB, timeSpan)
            if timeSpan:Measure() == 0 then
                __exports.OvaleBestAction:Log("[%d]    compare '%s' returns %s with zero measure", element.nodeId, element.operator, timeSpan)
            else
                local operator = element.operator
                __exports.OvaleBestAction:Log("[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s", element.nodeId, a, b, c, operator, x, y, z)
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
                    __exports.OvaleBestAction:Log("[%d]    intersection at t = %s", element.nodeId, t)
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
                __exports.OvaleBestAction:Log("[%d]    compare '%s' returns %s", element.nodeId, operator, timeSpan)
            end
            self:StopProfiling("OvaleBestAction_Compute")
            return timeSpan, element
        end
        self.ComputeCustomFunction = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local timeSpan = GetTimeSpan(element)
            local result
            local node = OvaleCompile:GetFunctionNode(element.name)
            if node then
                local timeSpanA, elementA = self:Compute(node.child[1], state, atTime)
                timeSpan:copyFromArray(timeSpanA)
                result = elementA
            else
                wipe(timeSpan)
            end
            self:StopProfiling("OvaleBestAction_Compute")
            return timeSpan, result
        end
        self.ComputeFunction = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_ComputeFunction")
            local timeSpan = GetTimeSpan(element)
            local result
            local start, ending, value, origin, rate = OvaleCondition:EvaluateCondition(element.func, element.positionalParams, element.namedParams, state, atTime)
            if start and ending then
                timeSpan:Copy(start, ending)
            else
                wipe(timeSpan)
            end
            if value then
                result = SetValue(element, value, origin, rate)
            end
            __exports.OvaleBestAction:Log("[%d]    condition '%s' returns %s, %s, %s, %s, %s", element.nodeId, element.name, start, ending, value, origin, rate)
            self:StopProfiling("OvaleBestAction_ComputeFunction")
            return timeSpan, result
        end
        self.ComputeGroup = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local bestTimeSpan, bestElement
            local best = newTimeSpan()
            local current = newTimeSpan()
            for _, node in ipairs(element.child) do
                local currentTimeSpan, currentElement = self:Compute(node, state, atTime)
                currentTimeSpan:IntersectInterval(atTime, INFINITY, current)
                if current:Measure() > 0 then
                    local nodeString = (currentElement and currentElement.nodeId) and " [" .. currentElement.nodeId .. "]" or ""
                    __exports.OvaleBestAction:Log("[%d]    group checking [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString)
                    local currentCastTime
                    if currentElement then
                        currentCastTime = currentElement.castTime
                    end
                    local gcd = OvaleFuture:GetGCD(nil, atTime)
                    if  not currentCastTime or currentCastTime < gcd then
                        currentCastTime = gcd
                    end
                    local currentIsBetter = false
                    if best:Measure() == 0 then
                        __exports.OvaleBestAction:Log("[%d]    group first best is [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString)
                        currentIsBetter = true
                    else
                        local threshold = (bestElement and bestElement.namedParams) and bestElement.namedParams.wait or 0
                        if best[1] - current[1] > threshold then
                            __exports.OvaleBestAction:Log("[%d]    group new best is [%d]: %s%s", element.nodeId, node.nodeId, current, nodeString)
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
            local timeSpan = GetTimeSpan(element, bestTimeSpan)
            if  not bestTimeSpan then
                wipe(timeSpan)
            end
            if bestElement then
                local id = bestElement.value
                if bestElement.positionalParams then
                    id = bestElement.positionalParams[1]
                end
                __exports.OvaleBestAction:Log("[%d]    group best action %s remains %s", element.nodeId, id, timeSpan)
            else
                __exports.OvaleBestAction:Log("[%d]    group no best action returns %s", element.nodeId, timeSpan)
            end
            self:StopProfiling("OvaleBestAction_Compute")
            return timeSpan, bestElement
        end
        self.ComputeIf = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local timeSpan = GetTimeSpan(element)
            local result
            local timeSpanA = self:ComputeBool(element.child[1], state, atTime)
            local conditionTimeSpan = timeSpanA
            if element.type == "unless" then
                conditionTimeSpan = timeSpanA:Complement()
            end
            if conditionTimeSpan:Measure() == 0 then
                timeSpan:copyFromArray(conditionTimeSpan)
                __exports.OvaleBestAction:Log("[%d]    '%s' returns %s with zero measure", element.nodeId, element.type, timeSpan)
            else
                local timeSpanB, elementB = self:Compute(element.child[2], state, atTime)
                conditionTimeSpan:Intersect(timeSpanB, timeSpan)
                __exports.OvaleBestAction:Log("[%d]    '%s' returns %s (intersection of %s and %s)", element.nodeId, element.type, timeSpan, conditionTimeSpan, timeSpanB)
                result = elementB
            end
            if element.type == "unless" then
                conditionTimeSpan:Release()
            end
            self:StopProfiling("OvaleBestAction_Compute")
            return timeSpan, result
        end
        self.ComputeLogical = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local timeSpan = GetTimeSpan(element)
            local timeSpanA = self:ComputeBool(element.child[1], state, atTime)
            if element.operator == "and" then
                if timeSpanA:Measure() == 0 then
                    timeSpan:copyFromArray(timeSpanA)
                    __exports.OvaleBestAction:Log("[%d]    logical '%s' short-circuits with zero measure left argument", element.nodeId, element.operator)
                else
                    local timeSpanB = self:ComputeBool(element.child[2], state, atTime)
                    timeSpanA:Intersect(timeSpanB, timeSpan)
                end
            elseif element.operator == "not" then
                timeSpanA:Complement(timeSpan)
            elseif element.operator == "or" then
                if timeSpanA:IsUniverse() then
                    timeSpan:copyFromArray(timeSpanA)
                    __exports.OvaleBestAction:Log("[%d]    logical '%s' short-circuits with universe as left argument", element.nodeId, element.operator)
                else
                    local timeSpanB = self:ComputeBool(element.child[2], state, atTime)
                    timeSpanA:Union(timeSpanB, timeSpan)
                end
            elseif element.operator == "xor" then
                local timeSpanB = self:ComputeBool(element.child[2], state, atTime)
                local left = timeSpanA:Union(timeSpanB)
                local scratch = timeSpanA:Intersect(timeSpanB)
                local right = scratch:Complement()
                left:Intersect(right, timeSpan)
                releaseTimeSpans(left, scratch, right)
            else
                wipe(timeSpan)
            end
            __exports.OvaleBestAction:Log("[%d]    logical '%s' returns %s", element.nodeId, element.operator, timeSpan)
            self:StopProfiling("OvaleBestAction_Compute")
            return timeSpan, element
        end
        self.ComputeLua = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_ComputeLua")
            local value = loadstring(element.lua)()
            __exports.OvaleBestAction:Log("[%d]    lua returns %s", element.nodeId, value)
            local result
            if value then
                result = SetValue(element, value)
            end
            local timeSpan = GetTimeSpan(element, UNIVERSE)
            self:StopProfiling("OvaleBestAction_ComputeLua")
            return timeSpan, result
        end
        self.ComputeState = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            local result = element
            assert(element.func == "setstate")
            __exports.OvaleBestAction:Log("[%d]    %s: %s = %s", element.nodeId, element.name, element.positionalParams[1], element.positionalParams[2])
            local timeSpan = GetTimeSpan(element, UNIVERSE)
            self:StopProfiling("OvaleBestAction_Compute")
            return timeSpan, result
        end
        self.ComputeValue = function(element, state, atTime)
            self:StartProfiling("OvaleBestAction_Compute")
            __exports.OvaleBestAction:Log("[%d]    value is %s", element.nodeId, element.value)
            local timeSpan = GetTimeSpan(element, UNIVERSE)
            self:StopProfiling("OvaleBestAction_Compute")
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
        OvaleBestActionBase.constructor(self)
        self:RegisterMessage("Ovale_ScriptChanged")
    end,
    OnDisable = function(self)
        self:UnregisterMessage("Ovale_ScriptChanged")
    end,
    Ovale_ScriptChanged = function(self)
        for node, timeSpan in pairs(self_timeSpan) do
            timeSpan:Release()
            self_timeSpan[node] = nil
        end
        for node, value in pairs(self_value) do
            self_valuePool:Release(value)
            self_value[node] = nil
        end
    end,
    StartNewAction = function(self)
        OvaleState:ResetState()
        OvaleFuture:ApplyInFlightSpells()
        self_serial = self_serial + 1
    end,
    GetActionInfo = function(self, element, state, atTime)
        if element and element.type == "action" then
            if element.serial and element.serial >= self_serial then
                OvaleSpellBook:Log("[%d]    using cached result (age = %d/%d)", element.nodeId, element.serial, self_serial)
                return element.actionTexture, element.actionInRange, element.actionCooldownStart, element.actionCooldownDuration, element.actionUsable, element.actionShortcut, element.actionIsCurrent, element.actionEnable, element.actionType, element.actionId, element.actionTarget, element.actionResourceExtend, element.actionCharges
            else
                local target = element.namedParams.target or baseState.next.defaultTarget
                if element.lowername == "item" then
                    return GetActionItemInfo(element, state, atTime, target)
                elseif element.lowername == "macro" then
                    return GetActionMacroInfo(element, state, atTime, target)
                elseif element.lowername == "spell" then
                    return GetActionSpellInfo(element, state, atTime, target)
                elseif element.lowername == "texture" then
                    return GetActionTextureInfo(element, state, atTime, target)
                end
            end
        end
        return nil
    end,
    GetAction = function(self, node, state, atTime)
        self:StartProfiling("OvaleBestAction_GetAction")
        local groupNode = node.child[1]
        local timeSpan, element = self:Compute(groupNode, state, atTime)
        if element and element.type == "state" then
            local variable, value = element.positionalParams[1], element.positionalParams[2]
            local isFuture =  not timeSpan:HasTime(atTime)
            variables:PutState(variable, value, isFuture, atTime)
        end
        self:StopProfiling("OvaleBestAction_GetAction")
        return timeSpan, element
    end,
    PostOrderCompute = function(self, element, state, atTime)
        self:StartProfiling("OvaleBestAction_Compute")
        local timeSpan, result
        local postOrder = element.postOrder
        if postOrder and  not (element.serial and element.serial >= self_serial) then
            local index = 1
            local N = #postOrder
            while index < N do
                local childNode, parentNode = postOrder[index], postOrder[index + 1]
                index = index + 2
                timeSpan, result = self:PostOrderCompute(childNode, state, atTime)
                if parentNode then
                    local shortCircuit = false
                    if parentNode.child and parentNode.child[1] == childNode then
                        if parentNode.type == "if" and timeSpan:Measure() == 0 then
                            __exports.OvaleBestAction:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero-measure time span.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        elseif parentNode.type == "unless" and timeSpan:IsUniverse() then
                            __exports.OvaleBestAction:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        elseif parentNode.type == "logical" and parentNode.operator == "and" and timeSpan:Measure() == 0 then
                            __exports.OvaleBestAction:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with zero measure.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        elseif parentNode.type == "logical" and parentNode.operator == "or" and timeSpan:IsUniverse() then
                            __exports.OvaleBestAction:Log("[%d]    '%s' will trigger short-circuit evaluation of parent node [%d] with universe as time span.", element.nodeId, childNode.type, parentNode.nodeId)
                            shortCircuit = true
                        end
                    end
                    if shortCircuit then
                        while parentNode ~= postOrder[index] and index <= N do
                            index = index + 2
                        end
                        if index > N then
                            self:Error("Ran off end of postOrder node list for node %d.", element.nodeId)
                        end
                    end
                end
            end
        end
        timeSpan, result = self:RecursiveCompute(element, state, atTime)
        self:StopProfiling("OvaleBestAction_Compute")
        return timeSpan, result
    end,
    RecursiveCompute = function(self, element, state, atTime)
        self:StartProfiling("OvaleBestAction_Compute")
        local timeSpan, result
        if element then
            if element.serial == -1 then
                Ovale:OneTimeMessage("Recursive call is not supported. This is a known bug with arcane mage script")
                return EMPTY_SET, element.result
            elseif element.serial and element.serial >= self_serial then
                timeSpan = element.timeSpan
                result = element.result
            else
                if element.asString then
                    __exports.OvaleBestAction:Log("[%d] >>> Computing '%s' at time=%f: %s", element.nodeId, element.type, atTime, element.asString)
                else
                    __exports.OvaleBestAction:Log("[%d] >>> Computing '%s' at time=%f", element.nodeId, element.type, atTime)
                end
                element.serial = -1
                local visitor = self.COMPUTE_VISITOR[element.type]
                if visitor then
                    timeSpan, result = visitor(element, state, atTime)
                    element.serial = self_serial
                    element.timeSpan = timeSpan
                    element.result = result
                else
                    __exports.OvaleBestAction:Log("[%d] Runtime error: unable to compute node of type '%s'.", element.nodeId, element.type)
                end
                if result and isValueNode(result) then
                    __exports.OvaleBestAction:Log("[%d] <<< '%s' returns %s with value = %s, %s, %s", element.nodeId, element.type, timeSpan, result.value, result.origin, result.rate)
                elseif result and result.nodeId then
                    __exports.OvaleBestAction:Log("[%d] <<< '%s' returns [%d] %s", element.nodeId, element.type, result.nodeId, timeSpan)
                else
                    __exports.OvaleBestAction:Log("[%d] <<< '%s' returns %s", element.nodeId, element.type, timeSpan)
                end
            end
        end
        self:StopProfiling("OvaleBestAction_Compute")
        return timeSpan, result
    end,
    ComputeBool = function(self, element, state, atTime)
        local timeSpan, newElement = self:Compute(element, state, atTime)
        if newElement and isValueNode(newElement) and newElement.value == 0 and newElement.rate == 0 then
            return EMPTY_SET
        else
            return timeSpan
        end
    end,
    Compute = function(self, element, state, atTime)
        return self:PostOrderCompute(element, state, atTime)
    end,
})
__exports.OvaleBestAction = OvaleBestActionClass()
