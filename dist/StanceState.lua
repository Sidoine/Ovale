local __exports = LibStub:NewLibrary("ovale/StanceState", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __Stance = LibStub:GetLibrary("ovale/Stance")
local OvaleStance = __Stance.OvaleStance
local __DataState = LibStub:GetLibrary("ovale/DataState")
local dataState = __DataState.dataState
local type = type
local StanceState = __class(nil, {
    InitializeState = function(self)
        self.stance = nil
    end,
    CleanState = function(self)
    end,
    ResetState = function(self)
        OvaleStance:StartProfiling("OvaleStance_ResetState")
        self.stance = OvaleStance.stance or 0
        OvaleStance:StopProfiling("OvaleStance_ResetState")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        OvaleStance:StartProfiling("OvaleStance_ApplySpellAfterCast")
        local stance = dataState:GetSpellInfoProperty(spellId, endCast, "to_stance", targetGUID)
        if stance then
            if type(stance) == "string" then
                stance = OvaleStance.stanceId[stance]
            end
            self.stance = stance
        end
        OvaleStance:StopProfiling("OvaleStance_ApplySpellAfterCast")
    end,
    IsStance = function(self, name)
        return OvaleStance:IsStance(name)
    end,
    RequireStanceHandler = function(self, spellId, atTime, requirement, tokens, index, targetGUID)
        return OvaleStance:RequireStanceHandler(spellId, atTime, requirement, tokens, index, targetGUID)
    end,
    constructor = function(self)
        self.stance = nil
    end
})
__exports.stanceState = StanceState()
OvaleState:RegisterState(__exports.stanceState)
