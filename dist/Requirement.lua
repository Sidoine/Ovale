local __exports = LibStub:NewLibrary("ovale/Requirement", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __tools = LibStub:GetLibrary("ovale/tools")
local isLuaArray = __tools.isLuaArray
__exports.getNextToken = function(tokens, index)
    if isLuaArray(tokens) then
        local result = tokens[index]
        return result, index + 1
    end
    return tokens, index
end
__exports.OvaleRequirement = __class(nil, {
    constructor = function(self, ovale, baseState, ovaleGuid)
        self.ovale = ovale
        self.baseState = baseState
        self.ovaleGuid = ovaleGuid
        self.nowRequirements = {}
    end,
    RegisterRequirement = function(self, name, nowMethod)
        self.nowRequirements[name] = nowMethod
    end,
    UnregisterRequirement = function(self, name)
        self.nowRequirements[name] = nil
    end,
    CheckRequirements = function(self, spellId, atTime, tokens, index, targetGUID)
        local requirements = self.nowRequirements
        targetGUID = targetGUID or self.ovaleGuid:UnitGUID(self.baseState.next.defaultTarget or "target")
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
                    self.ovale:OneTimeMessage("Warning: requirement '%s' has no registered handler; FAILING requirement.", name)
                    verified = false
                end
            end
            return verified, requirement, index
        end
        return true, nil, nil
    end,
})
