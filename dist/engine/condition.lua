local __exports = LibStub:NewLibrary("ovale/engine/condition", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local next = next
local ipairs = ipairs
local unpack = unpack
local huge = math.huge
local __toolstools = LibStub:GetLibrary("ovale/tools/tools")
local isString = __toolstools.isString
local insert = table.insert
local INFINITY = huge
local COMPARATOR = {
    atleast = true,
    atmost = true,
    equal = true,
    less = true,
    more = true
}
__exports.isComparator = function(token)
    return COMPARATOR[token] ~= nil
end
__exports.getFunctionSignature = function(name, infos)
    local result = name .. "("
    for k, v in ipairs(infos.parameters) do
        if k > 1 then
            result = result .. ", "
        end
        result = result .. v.name .. ": " .. v.type
    end
    return result .. ")"
end
__exports.OvaleConditionClass = __class(nil, {
    constructor = function(self, baseState)
        self.baseState = baseState
        self.conditions = {}
        self.actions = {}
        self.spellBookConditions = {
            spell = true
        }
        self.typedConditions = {}
    end,
    RegisterCondition = function(self, name, isSpellBookCondition, func)
        self.conditions[name] = func
        if isSpellBookCondition then
            self.spellBookConditions[name] = true
        end
    end,
    register = function(self, name, func, returnParameters, ...)
        local infos = {
            func = func,
            parameters = {...},
            namedParameters = {},
            returnValue = returnParameters
        }
        for k, v in ipairs(infos.parameters) do
            infos.namedParameters[v.name] = k
            if v.name == "target" then
                infos.targetIndex = k
            end
            if v.type == "string" and v.mapValues then
                infos.replacements = infos.replacements or {}
                insert(infos.replacements, {
                    index = k,
                    mapValues = v.mapValues
                })
            end
        end
        self.typedConditions[name] = infos
    end,
    registerAlias = function(self, name, alias)
        self.typedConditions[alias] = self.typedConditions[name]
    end,
    call = function(self, name, atTime, positionalParams)
        local infos = self.typedConditions[name]
        if infos.replacements then
            for _, v in ipairs(infos.replacements) do
                local value = positionalParams[v.index]
                if value then
                    local replacement = v.mapValues[value]
                    if replacement then
                        positionalParams[v.index] = replacement
                    end
                end
            end
        end
        if infos.targetIndex and (positionalParams[infos.targetIndex] == "target" or positionalParams[infos.targetIndex] == "cycle") then
            positionalParams[infos.targetIndex] = self.baseState.next.defaultTarget
        end
        return infos.func(atTime, unpack(positionalParams))
    end,
    registerAction = function(self, name, func)
        self.actions[name] = func
    end,
    UnregisterCondition = function(self, name)
        self.conditions[name] = nil
    end,
    getInfos = function(self, name)
        return self.typedConditions[name]
    end,
    IsCondition = function(self, name)
        return self.conditions[name] ~= nil
    end,
    IsSpellBookCondition = function(self, name)
        return self.spellBookConditions[name] ~= nil
    end,
    EvaluateCondition = function(self, name, positionalParams, namedParams, atTime)
        return self.conditions[name](positionalParams, namedParams, atTime)
    end,
    HasAny = function(self)
        return next(self.conditions) ~= nil
    end,
})
__exports.ParseCondition = function(namedParams, baseState, defaultTarget)
    local target = (isString(namedParams.target) and namedParams.target) or defaultTarget or "player"
    namedParams.target = namedParams.target or target
    if target == "cycle" or target == "target" then
        target = baseState.next.defaultTarget
    end
    local filter
    if namedParams.filter then
        if namedParams.filter == "debuff" then
            filter = "HARMFUL"
        elseif namedParams.filter == "buff" then
            filter = "HELPFUL"
        end
    end
    local mine = true
    if namedParams.any and namedParams.any == 1 then
        mine = false
    end
    return target, filter, mine
end
__exports.TestBoolean = function(a, yesno)
    if  not yesno or yesno == "yes" then
        if a then
            return 0, INFINITY
        end
    else
        if  not a then
            return 0, INFINITY
        end
    end
    return 
end
__exports.ReturnValue = function(value, origin, rate)
    return 0, INFINITY, value, origin, rate
end
__exports.ReturnValueBetween = function(start, ending, value, origin, rate)
    if start >= ending then
        return 
    end
    return start, ending, value, origin, rate
end
__exports.ReturnConstant = function(value)
    return 0, INFINITY, value, 0, 0
end
__exports.ReturnBoolean = function(value)
    if value then
        return 0, INFINITY
    end
    return 
end
__exports.TestValue = function(start, ending, value, origin, rate, comparator, limit)
    if value == nil or origin == nil or rate == nil then
        return 
    end
    start = start or 0
    ending = ending or INFINITY
    if  not comparator then
        if start < ending then
            return start, ending, value, origin, rate
        else
            return 0, INFINITY, 0, 0, 0
        end
    elseif  not __exports.isComparator(comparator) then
        return 
    elseif  not limit then
        return 
    elseif rate == 0 then
        if (comparator == "less" and value < limit) or (comparator == "atmost" and value <= limit) or (comparator == "equal" and value == limit) or (comparator == "atleast" and value >= limit) or (comparator == "more" and value > limit) then
            return start, ending
        end
    elseif (comparator == "less" and rate > 0) or (comparator == "atmost" and rate > 0) or (comparator == "atleast" and rate < 0) or (comparator == "more" and rate < 0) then
        local t = (limit - value) / rate + origin
        ending = (ending < t and ending) or t
        return start, ending
    elseif (comparator == "less" and rate < 0) or (comparator == "atmost" and rate < 0) or (comparator == "atleast" and rate > 0) or (comparator == "more" and rate > 0) then
        local t = (limit - value) / rate + origin
        start = (start > t and start) or t
        return start, INFINITY
    end
    return 
end
__exports.Compare = function(value, comparator, limit)
    return __exports.TestValue(0, INFINITY, value, 0, 0, comparator, limit)
end
