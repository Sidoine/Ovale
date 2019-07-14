local __exports = LibStub:NewLibrary("ovale/Condition", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local next = next
local huge = math.huge
local __BaseState = LibStub:GetLibrary("ovale/BaseState")
local baseState = __BaseState.baseState
local OvaleConditionBase = OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleCondition"))
local INFINITY = huge
local self_condition = {}
local self_spellBookCondition = {}
self_spellBookCondition["spell"] = true
local COMPARATOR = {
    atLeast = true,
    atMost = true,
    equal = true,
    less = true,
    more = true
}
__exports.isComparator = function(token)
    return COMPARATOR[token] ~= nil
end
local OvaleConditionClass = __class(OvaleConditionBase, {
    RegisterCondition = function(self, name, isSpellBookCondition, func)
        self_condition[name] = func
        if isSpellBookCondition then
            self_spellBookCondition[name] = true
        end
    end,
    UnregisterCondition = function(self, name)
        self_condition[name] = nil
    end,
    IsCondition = function(self, name)
        return (self_condition[name] ~= nil)
    end,
    IsSpellBookCondition = function(self, name)
        return (self_spellBookCondition[name] ~= nil)
    end,
    EvaluateCondition = function(self, name, positionalParams, namedParams, atTime)
        return self_condition[name](positionalParams, namedParams, atTime)
    end,
    HasAny = function(self)
        return next(self_condition) ~= nil
    end,
})
__exports.OvaleCondition = OvaleConditionClass()
__exports.ParseCondition = function(positionalParams, namedParams, defaultTarget)
    local target = namedParams.target or defaultTarget or "player"
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
    else
        if  not namedParams.any and namedParams.mine and namedParams.mine ~= 1 then
            mine = false
        end
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
    return nil
end
__exports.ReturnValue = function(value, origin, rate)
    return 0, INFINITY, value, origin, rate
end
__exports.TestValue = function(start, ending, value, origin, rate, comparator, limit)
    if  not value or  not origin or  not rate then
        return nil
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
        __exports.OvaleCondition:Error("unknown comparator %s", comparator)
    elseif  not limit then
        __exports.OvaleCondition:Error("comparator %s missing limit", comparator)
    elseif rate == 0 then
        if (comparator == "less" and value < limit) or (comparator == "atMost" and value <= limit) or (comparator == "equal" and value == limit) or (comparator == "atLeast" and value >= limit) or (comparator == "more" and value > limit) then
            return start, ending
        end
    elseif (comparator == "less" and rate > 0) or (comparator == "atMost" and rate > 0) or (comparator == "atLeast" and rate < 0) or (comparator == "more" and rate < 0) then
        local t = (limit - value) / rate + origin
        ending = (ending < t) and ending or t
        return start, ending
    elseif (comparator == "less" and rate < 0) or (comparator == "atMost" and rate < 0) or (comparator == "atLeast" and rate > 0) or (comparator == "more" and rate > 0) then
        local t = (limit - value) / rate + origin
        start = (start > t) and start or t
        return start, INFINITY
    end
    return nil
end
__exports.Compare = function(value, comparator, limit)
    return __exports.TestValue(0, INFINITY, value, 0, 0, comparator, limit)
end
