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
local find = string.find
local OvaleWildImpsBase = Ovale:NewModule("OvaleWildImps", aceEvent)
local demonData = {
    [55659] = {
        duration = 12
    },
    [98035] = {
        duration = 12
    },
    [103673] = {
        duration = 12
    },
    [11859] = {
        duration = 25
    },
    [89] = {
        duration = 25
    },
	[17252] = {
		duration = 25
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
    COMBAT_LOG_EVENT_UNFILTERED = function(self, event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId)
        self_serial = self_serial + 1
        Ovale:needRefresh()
        if sourceGUID ~= Ovale.playerGUID then
            return 
        end
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
        elseif cleuEvent == "SPELL_INSTAKILL" then
            if spellId == 196278 then
                self_demons[destGUID] = nil
            end
        elseif cleuEvent == "SPELL_CAST_SUCCESS" then
            if spellId == 193396 then
                for _, d in pairs(self_demons) do
                    d.de = true
                end
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
