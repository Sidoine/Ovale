local __exports = LibStub:NewLibrary("ovale/WildImps", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local tonumber = tonumber
local pairs = pairs
local GetTime = GetTime
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local find = string.find
local OvaleWildImpsBase = Ovale:NewModule("OvaleWildImps", aceEvent)
local demonData = {
    [55659] = { -- Wild Imp
        duration = 12
    },
    [143622] = { -- Wild Imp Inner Demons Talent
        duration = 12
    },
    [98035] = { -- Dreadstalker
        duration = 12
    },
    [135002] = { -- Demonic Tyrant
        duration = 15
    },
    [135816] = { -- Vile Fiend
        duration = 15
    },
	[17252] = { -- Felguard
		duration = 15
	}
}
local self_demons = {}
local self_serial = 1
local OvaleWildImpsClass = __class(OvaleWildImpsBase, {
    OnInitialize = function(self)
        if Ovale.playerClass == "WARLOCK" then
            self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self_demons = {}
        end
    end,
    OnDisable = function(self)
        if Ovale.playerClass == "WARLOCK" then
            self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
    end,
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, ...)
        local _, cleuEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId = CombatLogGetCurrentEventInfo()
        if sourceGUID ~= Ovale.playerGUID then
            return 
        end
        self_serial = self_serial + 1
        if cleuEvent == "SPELL_SUMMON" then
            local _, _, _, _, _, _, _, creatureId = find(destGUID, "(%S+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%S+)")
            creatureId = tonumber(creatureId)
            local now = GetTime()
			if creatureId == 17252 and not spellId == 111898 then
				return
			end
            for id, v in pairs(demonData) do
                if id == creatureId then
                    self_demons[destGUID] = {
                        id = creatureId,
                        timestamp = now,
                        finish = now + v.duration
                    }
                    break
                end
            end
            for k, d in pairs(self_demons) do
                if d.finish < now then
                    self_demons[k] = nil
                end
            end
            Ovale:needRefresh()
        elseif cleuEvent == "SPELL_CAST_SUCCESS" then
            if spellId == 196277 then
                self_demons[destGUID] = nil
                Ovale:needRefresh()
            end
        end
    end,
    CleanState = function(self)
    end,
    InitializeState = function(self)
    end,
    ResetState = function(self)
    end,
    GetNotDemonicEmpoweredDemonsCount = function(self, creatureId, atTime)
        local count = 0
        for _, d in pairs(self_demons) do
            if d.finish >= atTime and d.id == creatureId and  not d.de then
                count = count + 1
            end
        end
        return count
    end,
    GetDemonsCount = function(self, creatureId, atTime)
        local count = 0
        for _, d in pairs(self_demons) do
            if d.finish >= atTime and d.id == creatureId then
                count = count + 1
            end
        end
        return count
    end,
    GetRemainingDemonDuration = function(self, creatureId, atTime)
        local max = 0
        for _, d in pairs(self_demons) do
            if d.finish >= atTime and d.id == creatureId then
                local remaining = d.finish - atTime
                if remaining > max then
                    max = remaining
                end
            end
        end
        return max
    end,
})
__exports.OvaleWildImps = OvaleWildImpsClass()
OvaleState:RegisterState(__exports.OvaleWildImps)
