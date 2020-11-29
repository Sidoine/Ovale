local __exports = LibStub:NewLibrary("ovale/states/combat", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __enginestate = LibStub:GetLibrary("ovale/engine/state")
local States = __enginestate.States
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local GetTime = GetTime
local __enginecondition = LibStub:GetLibrary("ovale/engine/condition")
local TestBoolean = __enginecondition.TestBoolean
local TestValue = __enginecondition.TestValue
local Compare = __enginecondition.Compare
local ReturnConstant = __enginecondition.ReturnConstant
local huge = math.huge
__exports.CombatState = __class(nil, {
    constructor = function(self)
        self.inCombat = false
        self.combatStartTime = 0
    end
})
__exports.OvaleCombatClass = __class(States, {
    constructor = function(self, ovale, debug, ovaleSpellBook)
        self.ovale = ovale
        self.ovaleSpellBook = ovaleSpellBook
        self.ApplySpellOnHit = function(spellId, targetGUID, startCast, endCast, channel)
            if  not self.next.inCombat and self.ovaleSpellBook:IsHarmfulSpell(spellId) then
                self.next.inCombat = true
                if channel then
                    self.next.combatStartTime = startCast
                else
                    self.next.combatStartTime = endCast
                end
            end
        end
        self.onInitialize = function()
            self.module:RegisterEvent("PLAYER_REGEN_DISABLED", self.handlePlayerRegenDisabled)
            self.module:RegisterEvent("PLAYER_REGEN_ENABLED", self.handlePlayerRegenEnabled)
        end
        self.onRelease = function()
            self.module:UnregisterEvent("PLAYER_REGEN_DISABLED")
            self.module:UnregisterEvent("PLAYER_REGEN_ENABLED")
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
        self.tracer = debug:create("OvaleCombat")
    end,
    registerConditions = function(self, condition)
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
})
