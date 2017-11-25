local __exports = LibStub:NewLibrary("ovale/DemonHunterSigils", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ipairs = ipairs
local tonumber = tonumber
local insert = table.insert
local remove = table.remove
local GetTime = GetTime
local huge = math.huge
local OvaleSigilBase = OvaleProfiler:RegisterProfiling(Ovale:NewModule("OvaleSigil", aceEvent))
local UPDATE_DELAY = 0.5
local SIGIL_ACTIVATION_TIME = huge
local activated_sigils = {}
local sigil_start = {
    [204596] = {
        type = "flame"
    },
    [189110] = {
        type = "flame",
        talent = 8
    },
    [202137] = {
        type = "silence"
    },
    [207684] = {
        type = "misery"
    },
    [202138] = {
        type = "chains"
    }
}
local sigil_end = {
    [204598] = {
        type = "flame"
    },
    [204490] = {
        type = "silence"
    },
    [207685] = {
        type = "misery"
    },
    [204834] = {
        type = "chains"
    }
}
local QUICKENED_SIGILS_TALENT = 15
local OvaleSigilClass = __class(OvaleSigilBase, {
    constructor = function(self)
        OvaleSigilBase.constructor(self)
        activated_sigils["flame"] = {}
        activated_sigils["silence"] = {}
        activated_sigils["misery"] = {}
        activated_sigils["chains"] = {}
    end,
    OnInitialize = function(self)
        if Ovale.playerClass == "DEMONHUNTER" then
            self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        end
    end,
    OnDisable = function(self)
        if Ovale.playerClass == "DEMONHUNTER" then
            self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        end
    end,
    UNIT_SPELLCAST_SUCCEEDED = function(self, event, unitId, spellName, spellRank, guid, spellId, ...)
        if ( not OvalePaperDoll:IsSpecialization("vengeance")) then
            return 
        end
        if (unitId == nil or unitId ~= "player") then
            return 
        end
        local id = tonumber(spellId)
        if (sigil_start[id] ~= nil) then
            local s = sigil_start[id]
            local t = s.type
            local tal = s.talent or nil
            if (tal == nil or OvaleSpellBook:GetTalentPoints(tal) > 0) then
                insert(activated_sigils[t], GetTime())
            end
        end
        if (sigil_end[id] ~= nil) then
            local s = sigil_end[id]
            local t = s.type
            remove(activated_sigils[t], 1)
        end
    end,
    IsSigilCharging = function(self, type, atTime)
        if (#activated_sigils[type] == 0) then
            return false
        end
        local charging = false
        for _, v in ipairs(activated_sigils[type]) do
            local activation_time = SIGIL_ACTIVATION_TIME + UPDATE_DELAY
            if (OvaleSpellBook:GetTalentPoints(QUICKENED_SIGILS_TALENT) > 0) then
                activation_time = activation_time - 1
            end
            charging = charging or atTime < v + activation_time
        end
        return charging
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
})
__exports.OvaleSigil = OvaleSigilClass()
OvaleState:RegisterState(__exports.OvaleSigil)
