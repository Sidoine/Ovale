local __exports = LibStub:NewLibrary("ovale/DemonHunterSigils", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ipairs = ipairs
local tonumber = tonumber
local insert = table.insert
local remove = table.remove
local GetTime = GetTime
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UPDATE_DELAY = 0.5
local SIGIL_ACTIVATION_TIME = 2
local activated_sigils = {}
local sigil_start = {
    [204513] = {
        type = "flame"
    },
    [204596] = {
        type = "flame"
    },
    [189110] = {
        type = "flame",
        talent = 7
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
local QUICKENED_SIGILS_TALENT = 14
__exports.OvaleSigilClass = __class(nil, {
    constructor = function(self, ovalePaperDoll, ovale, ovaleSpellBook)
        self.ovalePaperDoll = ovalePaperDoll
        self.ovale = ovale
        self.ovaleSpellBook = ovaleSpellBook
        self.OnInitialize = function()
            if self.ovale.playerClass == "DEMONHUNTER" then
                self.module:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", self.UNIT_SPELLCAST_SUCCEEDED)
                self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", self.COMBAT_LOG_EVENT_UNFILTERED)
            end
        end
        self.OnDisable = function()
            if self.ovale.playerClass == "DEMONHUNTER" then
                self.module:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
                self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            end
        end
        self.COMBAT_LOG_EVENT_UNFILTERED = function(event, ...)
            if ( not self.ovalePaperDoll:IsSpecialization("vengeance")) then
                return 
            end
            local _, cleuEvent, _, sourceGUID, _, _, _, _, _, _, _, spellid = CombatLogGetCurrentEventInfo()
            if sourceGUID == self.ovale.playerGUID and cleuEvent == "SPELL_AURA_APPLIED" then
                if (sigil_end[spellid] ~= nil) then
                    local s = sigil_end[spellid]
                    local t = s.type
                    remove(activated_sigils[t], 1)
                end
            end
        end
        self.UNIT_SPELLCAST_SUCCEEDED = function(event, unitId, guid, spellId, ...)
            if ( not self.ovalePaperDoll:IsSpecialization("vengeance")) then
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
                if (tal == nil or self.ovaleSpellBook:GetTalentPoints(tal) > 0) then
                    insert(activated_sigils[t], GetTime())
                end
            end
        end
        self.module = ovale:createModule("OvaleSigil", self.OnInitialize, self.OnDisable, aceEvent)
        activated_sigils["flame"] = {}
        activated_sigils["silence"] = {}
        activated_sigils["misery"] = {}
        activated_sigils["chains"] = {}
    end,
    IsSigilCharging = function(self, type, atTime)
        if (#activated_sigils[type] == 0) then
            return false
        end
        local charging = false
        for _, v in ipairs(activated_sigils[type]) do
            local activation_time = SIGIL_ACTIVATION_TIME + UPDATE_DELAY
            if (self.ovaleSpellBook:GetTalentPoints(QUICKENED_SIGILS_TALENT) > 0) then
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
