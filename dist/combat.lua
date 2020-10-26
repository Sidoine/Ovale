local __exports = LibStub:NewLibrary("ovale/combat", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __State = LibStub:GetLibrary("ovale/State")
local States = __State.States
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local GetTime = GetTime
local tonumber = tonumber
local __Condition = LibStub:GetLibrary("ovale/Condition")
local TestBoolean = __Condition.TestBoolean
local TestValue = __Condition.TestValue
local Compare = __Condition.Compare
local ReturnConstant = __Condition.ReturnConstant
local huge = math.huge
local __tools = LibStub:GetLibrary("ovale/tools")
local OneTimeMessage = __tools.OneTimeMessage
__exports.CombatState = __class(nil, {
    constructor = function(self)
        self.inCombat = false
        self.combatStartTime = 0
    end
})
__exports.OvaleCombatClass = __class(States, {
    constructor = function(self, ovale, debug, ovaleSpellBook, requirement, condition)
        self.ovale = ovale
        self.ovaleSpellBook = ovaleSpellBook
        self.requirement = requirement
        self.onInitialize = function()
            self.module:RegisterEvent("PLAYER_REGEN_DISABLED", self.handlePlayerRegenDisabled)
            self.module:RegisterEvent("PLAYER_REGEN_ENABLED", self.handlePlayerRegenEnabled)
            self.requirement:RegisterRequirement("combat", self.CombatRequirement)
        end
        self.onRelease = function()
            self.module:UnregisterEvent("PLAYER_REGEN_DISABLED")
            self.module:UnregisterEvent("PLAYER_REGEN_ENABLED")
            self.requirement:UnregisterRequirement("combat")
        end
        self.handlePlayerRegenDisabled = function(event)
            self.tracer:Debug(event, "Entering combat.")
            local now = GetTime()
            self.current.inCombat = true
            self.current.combatStartTime = now
            self.ovale:needRefresh()
            self.module:SendMessage("Ovale_CombatStarted", now)
        end
        self.handlePlayerRegenEnabled = function(event)
            self.tracer:Debug(event, "Leaving combat.")
            local now = GetTime()
            self.current.inCombat = false
            self.ovale:needRefresh()
            self.module:SendMessage("Ovale_CombatEnded", now)
        end
        self.CombatRequirement = function(spellId, atTime, requirement, tokens, index, targetGUID)
            local verified = false
            local combatFlag = tokens[index]
            index = index + 1
            if combatFlag then
                combatFlag = tonumber(combatFlag)
                if (combatFlag == 1 and self:isInCombat(atTime)) or (combatFlag ~= 1 and  not self:isInCombat(atTime)) then
                    verified = true
                end
                local result = (verified and "passed") or "FAILED"
                if combatFlag == 1 then
                    self.tracer:Log("    Require combat at time=%f: %s", atTime, result)
                else
                    self.tracer:Log("    Require NOT combat at time=%f: %s", atTime, result)
                end
            else
                OneTimeMessage("Warning: requirement '%s' is missing an argument.", requirement)
            end
            return verified, requirement, index
        end
        self.InCombat = function(positionalParams, namedParams, atTime)
            local yesno = positionalParams[1]
            local boolean = self:isInCombat(atTime)
            return TestBoolean(boolean, yesno)
        end
        self.TimeInCombat = function(positionalParams, namedParams, atTime)
            local comparator, limit = positionalParams[1], positionalParams[2]
            if self:isInCombat(atTime) then
                local start = self:GetState(atTime).combatStartTime
                return TestValue(start, huge, 0, start, 1, comparator, limit)
            end
            return Compare(0, comparator, limit)
        end
        self.expectedCombatLength = function(positional, named, atTime)
            return ReturnConstant(15 * 60)
        end
        self.fightRemains = function()
            return ReturnConstant(15 * 60)
        end
        States.constructor(self, __exports.CombatState)
        self.module = ovale:createModule("Combat", self.onInitialize, self.onRelease, aceEvent)
        self.tracer = debug:create("Combat")
        condition:RegisterCondition("incombat", false, self.InCombat)
        condition:RegisterCondition("timeincombat", false, self.TimeInCombat)
        condition:RegisterCondition("expectedcombatlength", false, self.expectedCombatLength)
        condition:RegisterCondition("fightremains", false, self.fightRemains)
    end,
    isInCombat = function(self, atTime)
        return self:GetState(atTime).inCombat
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
        self.next.inCombat = self.current.inCombat
        self.next.combatStartTime = self.current.combatStartTime or 0
    end,
    CleanState = function(self)
    end,
    ApplySpellOnHit = function(self, spellId, targetGUID, startCast, endCast, channel)
        if  not self.next.inCombat and self.ovaleSpellBook:IsHarmfulSpell(spellId) then
            self.next.inCombat = true
            if channel then
                self.next.combatStartTime = startCast
            else
                self.next.combatStartTime = endCast
            end
        end
    end,
})
