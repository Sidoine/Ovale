local __exports = LibStub:NewLibrary("ovale/Requirement", 10000)
if not __exports then return end
local __GUID = LibStub:GetLibrary("ovale/GUID")
local OvaleGUID = __GUID.OvaleGUID
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __State = LibStub:GetLibrary("ovale/State")
local baseState = __State.baseState
__exports.self_requirement = {}
__exports.RegisterRequirement = function(name, method, arg)
    __exports.self_requirement[name] = {
        [1] = method,
        [2] = arg
    }
end
__exports.UnregisterRequirement = function(name)
    __exports.self_requirement[name] = nil
end
__exports.CheckRequirements = function(spellId, atTime, tokens, index, targetGUID)
    targetGUID = targetGUID or OvaleGUID:UnitGUID(baseState.defaultTarget or "target")
    local name = tokens[index]
    index = index + 1
    if name then
        local verified = true
        local requirement = name
        while verified and name do
            local handler = __exports.self_requirement[name]
            if handler then
                local method = handler[1]
                local arg = handler[2]
                verified, requirement, index = arg[method](arg, spellId, atTime, name, tokens, index, targetGUID)
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
