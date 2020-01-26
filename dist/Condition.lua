local __exports = LibStub:NewLibrary("ovale/Condition", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local next = next
local huge = math.huge
local INFINITY = huge
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
__exports.OvaleConditionClass = __class(nil, {
    constructor = function(self, baseState)
        self.baseState = baseState
        self.conditions = {}
        self.spellBookConditions = {
            spell = true
        }
    end,
    RegisterCondition = function(self, name, isSpellBookCondition, func)
        self.conditions[name] = func
        if isSpellBookCondition then
            self.spellBookConditions[name] = true
        end
    end,
    UnregisterCondition = function(self, name)
        self.conditions[name] = nil
    end,
    IsCondition = function(self, name)
        return (self.conditions[name] ~= nil)
    end,
    IsSpellBookCondition = function(self, name)
        return (self.spellBookConditions[name] ~= nil)
    end,
    EvaluateCondition = function(self, name, positionalParams, namedParams, atTime)
        return self.conditions[name](positionalParams, namedParams, atTime)
    end,
    HasAny = function(self)
        return next(self.conditions) ~= nil
    end,
    ParseCondition = function(self, positionalParams, namedParams, defaultTarget)
        local target = namedParams.target or defaultTarget or "player"
        namedParams.target = namedParams.target or target
        if target == "cycle" or target == "target" then
            target = self.baseState.next.defaultTarget
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
    end,
})
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
    return 
end
__exports.Compare = function(value, comparator, limit)
    return __exports.TestValue(0, INFINITY, value, 0, 0, comparator, limit)
end
