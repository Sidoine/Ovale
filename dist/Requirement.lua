local __exports = LibStub:NewLibrary("ovale/Requirement", 10000)
if not __exports then return end
local __GUID = LibStub:GetLibrary("ovale/GUID")
local OvaleGUID = __GUID.OvaleGUID
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __BaseState = LibStub:GetLibrary("ovale/BaseState")
local baseState = __BaseState.baseState
__exports.nowRequirements = {}
__exports.RegisterRequirement = function(name, nowMethod)
    __exports.nowRequirements[name] = nowMethod
end
__exports.UnregisterRequirement = function(name)
    __exports.nowRequirements[name] = nil
end
__exports.CheckRequirements = function(spellId, atTime, tokens, index, targetGUID)
    local requirements = __exports.nowRequirements
    targetGUID = targetGUID or OvaleGUID:UnitGUID(baseState.next.defaultTarget or "target")
    local name = tokens[index]
    index = index + 1
    if name then
        local verified = true
        local requirement = name
        while verified and name do
            local handler = requirements[name]
            if handler then
                verified, requirement, index = handler(spellId, atTime, name, tokens, index, targetGUID)
                name = tokens[index]
                index = index + 1
            else
                Ovale:OneTimeMessage("Warning: requirement '%s' has no registered handler; FAILING requirement.", name)
                verified = false
            end
        end
        return verified, requirement, index
    end
    return true, nil, nil
end
