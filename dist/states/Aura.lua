local __exports = LibStub:NewLibrary("ovale/states/Aura", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local __Pool = LibStub:GetLibrary("ovale/Pool")
local OvalePool = __Pool.OvalePool
local __State = LibStub:GetLibrary("ovale/State")
local States = __State.States
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local pairs = pairs
local tonumber = tonumber
local wipe = wipe
local next = next
local kpairs = pairs
local unpack = unpack
local lower = string.lower
local concat = table.concat
local insert = table.insert
local sort = table.sort
local GetTime = GetTime
local UnitAura = UnitAura
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local INFINITY = math.huge
local huge = math.huge
local __tools = LibStub:GetLibrary("ovale/tools")
local isNumber = __tools.isNumber
local isString = __tools.isString
local __Condition = LibStub:GetLibrary("ovale/Condition")
local ParseCondition = __Condition.ParseCondition
local ReturnValue = __Condition.ReturnValue
local strlower = lower
local tconcat = concat
local self_playerGUID = "fake_guid"
local self_petGUID = {}
local self_pool = OvalePool("OvaleAura_pool")
local UNKNOWN_GUID = "0"
__exports.DEBUFF_TYPE = {
    curse = true,
    disease = true,
    enrage = true,
    magic = true,
    poison = true
}
__exports.SPELLINFO_DEBUFF_TYPE = {}
do
    for debuffType in pairs(__exports.DEBUFF_TYPE) do
        local siDebuffType = strlower(debuffType)
        __exports.SPELLINFO_DEBUFF_TYPE[siDebuffType] = debuffType
    end
end
local CLEU_AURA_EVENTS = {
    SPELL_AURA_APPLIED = true,
    SPELL_AURA_REMOVED = true,
    SPELL_AURA_APPLIED_DOSE = true,
    SPELL_AURA_REMOVED_DOSE = true,
    SPELL_AURA_REFRESH = true,
    SPELL_AURA_BROKEN = true,
    SPELL_AURA_BROKEN_SPELL = true
}
local CLEU_TICK_EVENTS = {
    SPELL_PERIODIC_DAMAGE = true,
    SPELL_PERIODIC_HEAL = true,
    SPELL_PERIODIC_ENERGIZE = true,
    SPELL_PERIODIC_DRAIN = true,
    SPELL_PERIODIC_LEECH = true
}
local array = {}
__exports.PutAura = function(auraDB, guid, auraId, casterGUID, aura)
    local auraForGuid = auraDB[guid]
    if  not auraForGuid then
        auraForGuid = self_pool:Get()
        auraDB[guid] = auraForGuid
    end
    local auraForId = auraForGuid[auraId]
    if  not auraForId then
        auraForId = self_pool:Get()
        auraForGuid[auraId] = auraForId
    end
    local previousAura = auraForId[casterGUID]
    if previousAura then
        self_pool:Release(previousAura)
    end
    auraForId[casterGUID] = aura
    aura.guid = guid
    aura.spellId = auraId
    aura.source = casterGUID
end
__exports.GetAura = function(auraDB, guid, auraId, casterGUID)
    if auraDB[guid] and auraDB[guid][auraId] and auraDB[guid][auraId][casterGUID] then
        return auraDB[guid][auraId][casterGUID]
    end
end
local function GetAuraAnyCaster(auraDB, guid, auraId)
    local auraFound
    if auraDB[guid] and auraDB[guid][auraId] then
        for _, aura in pairs(auraDB[guid][auraId]) do
            if  not auraFound or auraFound.ending < aura.ending then
                auraFound = aura
            end
        end
    end
    return auraFound
end
local function GetDebuffType(auraDB, guid, debuffType, filter, casterGUID)
    local auraFound
    if auraDB[guid] then
        for _, whoseTable in pairs(auraDB[guid]) do
            local aura = whoseTable[casterGUID]
            if aura and aura.debuffType == debuffType and aura.filter == filter then
                if  not auraFound or auraFound.ending < aura.ending then
                    auraFound = aura
                end
            end
        end
    end
    return auraFound
end
local function GetDebuffTypeAnyCaster(auraDB, guid, debuffType, filter)
    local auraFound
    if auraDB[guid] then
        for _, whoseTable in pairs(auraDB[guid]) do
            for _, aura in pairs(whoseTable) do
                if aura and aura.debuffType == debuffType and aura.filter == filter then
                    if  not auraFound or auraFound.ending < aura.ending then
                        auraFound = aura
                    end
                end
            end
        end
    end
    return auraFound
end
local function GetAuraOnGUID(auraDB, guid, auraId, filter, mine)
    local auraFound
    if __exports.DEBUFF_TYPE[auraId] then
        if mine and self_playerGUID then
            auraFound = GetDebuffType(auraDB, guid, auraId, filter, self_playerGUID)
            if  not auraFound then
                for petGUID in pairs(self_petGUID) do
                    local aura = GetDebuffType(auraDB, guid, auraId, filter, petGUID)
                    if aura and ( not auraFound or auraFound.ending < aura.ending) then
                        auraFound = aura
                    end
                end
            end
        else
            auraFound = GetDebuffTypeAnyCaster(auraDB, guid, auraId, filter)
        end
    else
        if mine and self_playerGUID then
            auraFound = __exports.GetAura(auraDB, guid, auraId, self_playerGUID)
            if  not auraFound then
                for petGUID in pairs(self_petGUID) do
                    local aura = __exports.GetAura(auraDB, guid, auraId, petGUID)
                    if aura and ( not auraFound or auraFound.ending < aura.ending) then
                        auraFound = aura
                    end
                end
            end
        else
            auraFound = GetAuraAnyCaster(auraDB, guid, auraId)
        end
    end
    return auraFound
end
__exports.RemoveAurasOnGUID = function(auraDB, guid)
    if auraDB[guid] then
        local auraTable = auraDB[guid]
        for auraId, whoseTable in pairs(auraTable) do
            for casterGUID, aura in pairs(whoseTable) do
                self_pool:Release(aura)
                whoseTable[casterGUID] = nil
            end
            self_pool:Release(whoseTable)
            auraTable[auraId] = nil
        end
        self_pool:Release(auraTable)
        auraDB[guid] = nil
    end
end
local AuraInterface = __class(nil, {
    constructor = function(self)
        self.aura = {}
        self.serial = {}
        self.auraSerial = 0
    end
})
local count
local stacks
local startChangeCount, endingChangeCount
local startFirst, endingLast
__exports.OvaleAuraClass = __class(States, {
    constructor = function(self, ovaleState, ovalePaperDoll, baseState, ovaleData, ovaleGuid, lastSpell, ovaleOptions, ovaleDebug, ovale, ovaleProfiler, ovaleSpellBook)
        self.ovaleState = ovaleState
        self.ovalePaperDoll = ovalePaperDoll
        self.baseState = baseState
        self.ovaleData = ovaleData
        self.ovaleGuid = ovaleGuid
        self.lastSpell = lastSpell
        self.ovaleOptions = ovaleOptions
        self.ovaleDebug = ovaleDebug
        self.ovale = ovale
        self.ovaleSpellBook = ovaleSpellBook
        self.OnInitialize = function()
            self_playerGUID = self.ovale.playerGUID
            self_petGUID = self.ovaleGuid.petGUID
            self.module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", self.COMBAT_LOG_EVENT_UNFILTERED)
            self.module:RegisterEvent("PLAYER_ENTERING_WORLD", self.PLAYER_ENTERING_WORLD)
            self.module:RegisterEvent("PLAYER_REGEN_ENABLED", self.PLAYER_REGEN_ENABLED)
            self.module:RegisterEvent("UNIT_AURA", self.UNIT_AURA)
            self.module:RegisterMessage("Ovale_GroupChanged", self.handleOvaleGroupChanged)
            self.module:RegisterMessage("Ovale_UnitChanged", self.Ovale_UnitChanged)
        end
        self.OnDisable = function()
            self.module:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            self.module:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self.module:UnregisterEvent("PLAYER_REGEN_ENABLED")
            self.module:UnregisterEvent("PLAYER_UNGHOST")
            self.module:UnregisterEvent("UNIT_AURA")
            self.module:UnregisterMessage("Ovale_GroupChanged")
            self.module:UnregisterMessage("Ovale_UnitChanged")
            for guid in pairs(self.current.aura) do
                __exports.RemoveAurasOnGUID(self.current.aura, guid)
            end
            self_pool:Drain()
        end
        self.COMBAT_LOG_EVENT_UNFILTERED = function(event, ...)
            self.debug:DebugTimestamp("COMBAT_LOG_EVENT_UNFILTERED", CombatLogGetCurrentEventInfo())
            local _, cleuEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, spellName, _, auraType, amount = CombatLogGetCurrentEventInfo()
            local mine = sourceGUID == self_playerGUID or self.ovaleGuid:IsPlayerPet(sourceGUID)
            if mine and cleuEvent == "SPELL_MISSED" then
                local unitId = self.ovaleGuid:GUIDUnit(destGUID)
                if unitId then
                    self.debug:DebugTimestamp("%s: %s (%s)", cleuEvent, destGUID, unitId)
                    self:ScanAuras(unitId, destGUID)
                end
            end
            if CLEU_AURA_EVENTS[cleuEvent] then
                local unitId = self.ovaleGuid:GUIDUnit(destGUID)
                self.debug:DebugTimestamp("UnitId: ", unitId)
                if unitId then
                    if  not self.ovaleGuid.UNIT_AURA_UNIT[unitId] then
                        self.debug:DebugTimestamp("%s: %s (%s)", cleuEvent, destGUID, unitId)
                        self:ScanAuras(unitId, destGUID)
                    end
                elseif mine then
                    self.debug:DebugTimestamp("%s: %s (%d) on %s", cleuEvent, spellName, spellId, destGUID)
                    local now = GetTime()
                    if cleuEvent == "SPELL_AURA_REMOVED" or cleuEvent == "SPELL_AURA_BROKEN" or cleuEvent == "SPELL_AURA_BROKEN_SPELL" then
                        self:LostAuraOnGUID(destGUID, now, spellId, sourceGUID)
                    else
                        local filter = (auraType == "BUFF" and "HELPFUL") or "HARMFUL"
                        local si = self.ovaleData.spellInfo[spellId]
                        local aura = GetAuraOnGUID(self.current.aura, destGUID, spellId, filter, true)
                        local duration = 15
                        if aura then
                            duration = aura.duration
                        elseif si and si.duration then
                            duration = self.ovaleData:GetSpellInfoPropertyNumber(spellId, now, "duration", destGUID) or 15
                        end
                        local expirationTime = now + duration
                        local count
                        if cleuEvent == "SPELL_AURA_APPLIED" then
                            count = 1
                        elseif cleuEvent == "SPELL_AURA_APPLIED_DOSE" or cleuEvent == "SPELL_AURA_REMOVED_DOSE" then
                            count = amount
                        elseif cleuEvent == "SPELL_AURA_REFRESH" then
                            count = (aura and aura.stacks) or 1
                        end
                        self:GainedAuraOnGUID(destGUID, now, spellId, sourceGUID, filter, true, nil, count, nil, duration, expirationTime, false, spellName)
                    end
                end
            elseif mine and CLEU_TICK_EVENTS[cleuEvent] and self_playerGUID then
                self.debug:DebugTimestamp("%s: %s", cleuEvent, destGUID)
                local aura = __exports.GetAura(self.current.aura, destGUID, spellId, self_playerGUID)
                local now = GetTime()
                if aura and self:IsActiveAura(aura, now) then
                    local name = aura.name or "Unknown spell"
                    local baseTick, lastTickTime = aura.baseTick, aura.lastTickTime
                    local tick
                    if lastTickTime then
                        tick = now - lastTickTime
                    elseif  not baseTick then
                        self.debug:Debug("    First tick seen of unknown periodic aura %s (%d) on %s.", name, spellId, destGUID)
                        local si = self.ovaleData.spellInfo[spellId]
                        baseTick = (si and si.tick and si.tick) or 3
                        tick = self:GetTickLength(spellId)
                    else
                        tick = baseTick
                    end
                    aura.baseTick = baseTick
                    aura.lastTickTime = now
                    aura.tick = tick
                    self.debug:Debug("    Updating %s (%s) on %s, tick=%s, lastTickTime=%s", name, spellId, destGUID, tick, lastTickTime)
                    self.ovale.refreshNeeded[destGUID] = true
                end
            end
        end
        self.PLAYER_ENTERING_WORLD = function(event)
            self:ScanAllUnitAuras()
        end
        self.PLAYER_REGEN_ENABLED = function(event)
            self:RemoveAurasOnInactiveUnits()
            self_pool:Drain()
        end
        self.UNIT_AURA = function(event, unitId)
            self.debug:Debug(event, unitId)
            self:ScanAuras(unitId)
        end
        self.handleOvaleGroupChanged = function()
            return self:ScanAllUnitAuras()
        end
        self.Ovale_UnitChanged = function(event, unitId, guid)
            if (unitId == "pet" or unitId == "target") and guid then
                self.debug:Debug(event, unitId, guid)
                self:ScanAuras(unitId, guid)
            end
        end
        self.buffLastExpire = function(positionalParameters, namedParameters, atTime)
            local spellId = unpack(positionalParameters)
            local target, filter, mine = ParseCondition(namedParameters, self.baseState)
            local aura = self:GetAura(target, spellId, atTime, filter, mine)
            if  not aura then
                return 
            end
            return ReturnValue(0, aura.ending, 1)
        end
        self.ApplySpellStartCast = function(spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
            self.profiler:StartProfiling("OvaleAura_ApplySpellStartCast")
            if isChanneled then
                local si = self.ovaleData.spellInfo[spellId]
                if si and si.aura then
                    if si.aura.player then
                        self:ApplySpellAuras(spellId, self_playerGUID, startCast, si.aura.player, spellcast)
                    end
                    if si.aura.target then
                        self:ApplySpellAuras(spellId, targetGUID, startCast, si.aura.target, spellcast)
                    end
                    if si.aura.pet then
                        local petGUID = self.ovaleGuid:UnitGUID("pet")
                        if petGUID then
                            self:ApplySpellAuras(spellId, petGUID, startCast, si.aura.pet, spellcast)
                        end
                    end
                end
            end
            self.profiler:StopProfiling("OvaleAura_ApplySpellStartCast")
        end
        self.ApplySpellAfterCast = function(spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
            self.profiler:StartProfiling("OvaleAura_ApplySpellAfterCast")
            if  not isChanneled then
                local si = self.ovaleData.spellInfo[spellId]
                if si and si.aura then
                    if si.aura.player then
                        self:ApplySpellAuras(spellId, self_playerGUID, endCast, si.aura.player, spellcast)
                    end
                    if si.aura.pet then
                        local petGUID = self.ovaleGuid:UnitGUID("pet")
                        if petGUID then
                            self:ApplySpellAuras(spellId, petGUID, startCast, si.aura.pet, spellcast)
                        end
                    end
                end
            end
            self.profiler:StopProfiling("OvaleAura_ApplySpellAfterCast")
        end
        self.ApplySpellOnHit = function(spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
            self.profiler:StartProfiling("OvaleAura_ApplySpellAfterHit")
            if  not isChanneled then
                local si = self.ovaleData.spellInfo[spellId]
                if si and si.aura and si.aura.target then
                    local travelTime = si.travel_time or 0
                    if travelTime > 0 then
                        local estimatedTravelTime = 1
                        if travelTime < estimatedTravelTime then
                            travelTime = estimatedTravelTime
                        end
                    end
                    local atTime = endCast + travelTime
                    self:ApplySpellAuras(spellId, targetGUID, atTime, si.aura.target, spellcast)
                end
            end
            self.profiler:StopProfiling("OvaleAura_ApplySpellAfterHit")
        end
        States.constructor(self, AuraInterface)
        self.module = ovale:createModule("OvaleAura", self.OnInitialize, self.OnDisable, aceEvent)
        self.debug = ovaleDebug:create("OvaleAura")
        self.profiler = ovaleProfiler:create("OvaleAura")
        self.ovaleState:RegisterState(self)
        self:addDebugOptions()
    end,
    registerConditions = function(self, condition)
        condition:RegisterCondition("bufflastexpire", true, self.buffLastExpire)
    end,
    IsWithinAuraLag = function(self, time1, time2, factor)
        factor = factor or 1
        local auraLag = self.ovaleOptions.db.profile.apparence.auraLag
        local tolerance = (factor * auraLag) / 1000
        return time1 - time2 < tolerance and time2 - time1 < tolerance
    end,
    CountMatchingActiveAura = function(self, aura)
        self.debug:Log("Counting aura %s found on %s with (%s, %s)", aura.spellId, aura.guid, aura.start, aura.ending)
        count = count + 1
        stacks = stacks + aura.stacks
        if aura.ending < endingChangeCount then
            startChangeCount, endingChangeCount = aura.gain, aura.ending
        end
        if aura.gain < startFirst then
            startFirst = aura.gain
        end
        if aura.ending > endingLast then
            endingLast = aura.ending
        end
    end,
    addDebugOptions = function(self)
        local output = {}
        local debugOptions = {
            playerAura = {
                name = L["Auras (player)"],
                type = "group",
                args = {
                    buff = {
                        name = L["Auras on the player"],
                        type = "input",
                        multiline = 25,
                        width = "full",
                        get = function(info)
                            wipe(output)
                            local now = GetTime()
                            local helpful = self:DebugUnitAuras("player", "HELPFUL", now)
                            if helpful then
                                output[#output + 1] = "== BUFFS =="
                                output[#output + 1] = helpful
                            end
                            local harmful = self:DebugUnitAuras("player", "HARMFUL", now)
                            if harmful then
                                output[#output + 1] = "== DEBUFFS =="
                                output[#output + 1] = harmful
                            end
                            return tconcat(output, "\n")
                        end
                    }
                }
            },
            targetAura = {
                name = L["Auras (target)"],
                type = "group",
                args = {
                    targetbuff = {
                        name = L["Auras on the target"],
                        type = "input",
                        multiline = 25,
                        width = "full",
                        get = function(info)
                            wipe(output)
                            local now = GetTime()
                            local helpful = self:DebugUnitAuras("target", "HELPFUL", now)
                            if helpful then
                                output[#output + 1] = "== BUFFS =="
                                output[#output + 1] = helpful
                            end
                            local harmful = self:DebugUnitAuras("target", "HARMFUL", now)
                            if harmful then
                                output[#output + 1] = "== DEBUFFS =="
                                output[#output + 1] = harmful
                            end
                            return tconcat(output, "\n")
                        end
                    }
                }
            }
        }
        for k, v in pairs(debugOptions) do
            self.ovaleDebug.defaultOptions.args[k] = v
        end
    end,
    ScanAllUnitAuras = function(self)
        for unitId in pairs(self.ovaleGuid.UNIT_AURA_UNIT) do
            self:ScanAuras(unitId)
        end
    end,
    RemoveAurasOnInactiveUnits = function(self)
        for guid in pairs(self.current.aura) do
            local unitId = self.ovaleGuid:GUIDUnit(guid)
            if  not unitId then
                self.debug:Debug("Removing auras from GUID %s", guid)
                __exports.RemoveAurasOnGUID(self.current.aura, guid)
                self.current.serial[guid] = nil
            end
        end
    end,
    IsActiveAura = function(self, aura, atTime)
        local boolean = false
        atTime = atTime or self.baseState.next.currentTime
        if aura.state then
            if aura.serial == self.next.auraSerial and aura.stacks > 0 and aura.gain <= atTime and atTime <= aura.ending then
                boolean = true
            elseif aura.consumed and self:IsWithinAuraLag(aura.ending, atTime) then
                boolean = true
            end
        else
            if aura.serial == self.current.serial[aura.guid] and aura.stacks > 0 and aura.gain <= atTime and atTime <= aura.ending then
                boolean = true
            elseif aura.consumed and self:IsWithinAuraLag(aura.ending, atTime) then
                boolean = true
            end
        end
        return boolean
    end,
    GainedAuraOnGUID = function(self, guid, atTime, auraId, casterGUID, filter, visible, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3)
        self.profiler:StartProfiling("OvaleAura_GainedAuraOnGUID")
        casterGUID = casterGUID or UNKNOWN_GUID
        count = (count and count > 0 and count) or 1
        duration = (duration and duration > 0 and duration) or INFINITY
        expirationTime = (expirationTime and expirationTime > 0 and expirationTime) or INFINITY
        local aura = __exports.GetAura(self.current.aura, guid, auraId, casterGUID)
        local auraIsActive
        if aura then
            auraIsActive = aura.stacks > 0 and aura.gain <= atTime and atTime <= aura.ending
        else
            aura = self_pool:Get()
            __exports.PutAura(self.current.aura, guid, auraId, casterGUID, aura)
            auraIsActive = false
        end
        local auraIsUnchanged = aura.source == casterGUID and aura.duration == duration and aura.ending == expirationTime and aura.stacks == count and aura.value1 == value1 and aura.value2 == value2 and aura.value3 == value3
        aura.serial = self.current.serial[guid]
        if  not auraIsActive or  not auraIsUnchanged then
            self.debug:Debug("    Adding %s %s (%s) to %s at %f, aura.serial=%d, duration=%f, expirationTime=%f, auraIsActive=%s, auraIsUnchanged=%s", filter, name, auraId, guid, atTime, aura.serial, duration, expirationTime, (auraIsActive and "true") or "false", (auraIsUnchanged and "true") or "false")
            aura.name = name
            aura.duration = duration
            aura.ending = expirationTime
            if duration < INFINITY and expirationTime < INFINITY then
                aura.start = expirationTime - duration
            else
                aura.start = atTime
            end
            aura.gain = atTime
            aura.lastUpdated = atTime
            local direction = aura.direction or 1
            if aura.stacks then
                if aura.stacks < count then
                    direction = 1
                elseif aura.stacks > count then
                    direction = -1
                end
            end
            aura.direction = direction
            aura.stacks = count
            aura.consumed = false
            aura.filter = filter
            aura.visible = visible
            aura.icon = icon
            aura.debuffType = (isString(debuffType) and lower(debuffType)) or debuffType
            aura.stealable = isStealable
            aura.value1, aura.value2, aura.value3 = value1, value2, value3
            local mine = casterGUID == self_playerGUID or self.ovaleGuid:IsPlayerPet(casterGUID)
            if mine then
                local spellcast = self.lastSpell:LastInFlightSpell()
                if spellcast and spellcast.stop and  not self:IsWithinAuraLag(spellcast.stop, atTime) then
                    spellcast = self.lastSpell.lastSpellcast
                    if spellcast and spellcast.stop and  not self:IsWithinAuraLag(spellcast.stop, atTime) then
                        spellcast = nil
                    end
                end
                if spellcast and spellcast.target == guid then
                    local spellId = spellcast.spellId
                    local spellName = self.ovaleSpellBook:GetSpellName(spellId) or "Unknown spell"
                    local keepSnapshot = false
                    local si = self.ovaleData.spellInfo[spellId]
                    if si and si.aura then
                        local auraTable = (self.ovaleGuid:IsPlayerPet(guid) and si.aura.pet) or si.aura.target
                        if auraTable and auraTable[filter] then
                            local spellData = auraTable[filter][auraId]
                            if spellData.cachedParams.named.refresh_keep_snapshot and (spellData.cachedParams.named.enabled == nil or spellData.cachedParams.named.enabled) then
                                keepSnapshot = true
                            end
                        end
                    end
                    if keepSnapshot then
                        self.debug:Debug("    Keeping snapshot stats for %s %s (%d) on %s refreshed by %s (%d) from %f, now=%f, aura.serial=%d", filter, name, auraId, guid, spellName, spellId, aura.snapshotTime, atTime, aura.serial)
                    else
                        self.debug:Debug("    Snapshot stats for %s %s (%d) on %s applied by %s (%d) from %f, now=%f, aura.serial=%d", filter, name, auraId, guid, spellName, spellId, spellcast.snapshotTime, atTime, aura.serial)
                        self.lastSpell:CopySpellcastInfo(spellcast, aura)
                    end
                end
                local si = self.ovaleData.spellInfo[auraId]
                if si then
                    if si.tick then
                        self.debug:Debug("    %s (%s) is a periodic aura.", name, auraId)
                        if  not auraIsActive then
                            aura.baseTick = si.tick
                            if spellcast and spellcast.target == guid then
                                aura.tick = self:GetTickLength(auraId, spellcast)
                            else
                                aura.tick = self:GetTickLength(auraId)
                            end
                        end
                    end
                    if si.buff_cd and guid == self_playerGUID then
                        self.debug:Debug("    %s (%s) is applied by an item with a cooldown of %ds.", name, auraId, si.buff_cd)
                        if  not auraIsActive then
                            aura.cooldownEnding = aura.gain + si.buff_cd
                        end
                    end
                end
            end
            if  not auraIsActive then
                self.module:SendMessage("Ovale_AuraAdded", atTime, guid, auraId, aura.source)
            elseif  not auraIsUnchanged then
                self.module:SendMessage("Ovale_AuraChanged", atTime, guid, auraId, aura.source)
            end
            self.ovale.refreshNeeded[guid] = true
        end
        self.profiler:StopProfiling("OvaleAura_GainedAuraOnGUID")
    end,
    LostAuraOnGUID = function(self, guid, atTime, auraId, casterGUID)
        self.profiler:StartProfiling("OvaleAura_LostAuraOnGUID")
        local aura = __exports.GetAura(self.current.aura, guid, auraId, casterGUID)
        if aura then
            local filter = aura.filter
            self.debug:Debug("    Expiring %s %s (%d) from %s at %f.", filter, aura.name, auraId, guid, atTime)
            if aura.ending > atTime then
                aura.ending = atTime
            end
            local mine = casterGUID == self_playerGUID or self.ovaleGuid:IsPlayerPet(casterGUID)
            if mine then
                aura.baseTick = nil
                aura.lastTickTime = nil
                aura.tick = nil
                if aura.start + aura.duration > aura.ending then
                    local spellcast
                    if guid == self_playerGUID then
                        spellcast = self.lastSpell:LastSpellSent()
                    else
                        spellcast = self.lastSpell.lastSpellcast
                    end
                    if spellcast then
                        if (spellcast.success and spellcast.stop and self:IsWithinAuraLag(spellcast.stop, aura.ending)) or (spellcast.queued and self:IsWithinAuraLag(spellcast.queued, aura.ending)) then
                            aura.consumed = true
                            local spellName = self.ovaleSpellBook:GetSpellName(spellcast.spellId) or "Unknown spell"
                            self.debug:Debug("    Consuming %s %s (%d) on %s with queued %s (%d) at %f.", filter, aura.name, auraId, guid, spellName, spellcast.spellId, spellcast.queued)
                        end
                    end
                end
            end
            aura.lastUpdated = atTime
            self.module:SendMessage("Ovale_AuraRemoved", atTime, guid, auraId, aura.source)
            self.ovale.refreshNeeded[guid] = true
        end
        self.profiler:StopProfiling("OvaleAura_LostAuraOnGUID")
    end,
    ScanAuras = function(self, unitId, guid)
        self.profiler:StartProfiling("OvaleAura_ScanAuras")
        guid = guid or self.ovaleGuid:UnitGUID(unitId)
        if guid then
            local harmfulFilter = (self.ovaleOptions.db.profile.apparence.fullAuraScan and "HARMFUL") or "HARMFUL|PLAYER"
            local helpfulFilter = (self.ovaleOptions.db.profile.apparence.fullAuraScan and "HELPFUL") or "HELPFUL|PLAYER"
            self.debug:DebugTimestamp("Scanning auras on %s (%s)", guid, unitId)
            local serial = self.current.serial[guid] or 0
            serial = serial + 1
            self.debug:Debug("    Advancing age of auras for %s (%s) to %d.", guid, unitId, serial)
            self.current.serial[guid] = serial
            local i = 1
            local filter = helpfulFilter
            local now = GetTime()
            while true do
                local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, _, spellId, _, _, _, value1, value2, value3 = UnitAura(unitId, i, filter)
                if  not name then
                    if filter == helpfulFilter then
                        filter = harmfulFilter
                        i = 1
                    else
                        break
                    end
                else
                    local casterGUID = unitCaster and self.ovaleGuid:UnitGUID(unitCaster)
                    if casterGUID then
                        if debuffType == "" then
                            debuffType = "enrage"
                        end
                        local auraType = (filter == harmfulFilter and "HARMFUL") or "HELPFUL"
                        self:GainedAuraOnGUID(guid, now, spellId, casterGUID, auraType, true, icon, count, debuffType, duration, expirationTime, isStealable, name, value1, value2, value3)
                    end
                    i = i + 1
                end
            end
            if self.current.aura[guid] then
                local auraTable = self.current.aura[guid]
                for auraId, whoseTable in pairs(auraTable) do
                    for casterGUID, aura in pairs(whoseTable) do
                        if aura.serial == serial - 1 then
                            if aura.visible then
                                self:LostAuraOnGUID(guid, now, tonumber(auraId), casterGUID)
                            else
                                aura.serial = serial
                                self.debug:Debug("    Preserving aura %s (%d), start=%s, ending=%s, aura.serial=%d", aura.name, aura.spellId, aura.start, aura.ending, aura.serial)
                            end
                        end
                    end
                end
            end
            self.debug:Debug("End scanning of auras on %s (%s).", guid, unitId)
        end
        self.profiler:StopProfiling("OvaleAura_ScanAuras")
    end,
    GetStateAura = function(self, guid, auraId, casterGUID, atTime)
        local state = self:GetState(atTime)
        local aura = __exports.GetAura(state.aura, guid, auraId, casterGUID)
        if atTime and ( not aura or aura.serial < self.next.auraSerial) then
            aura = __exports.GetAura(self.current.aura, guid, auraId, casterGUID)
        end
        return aura
    end,
    DebugUnitAuras = function(self, unitId, filter, atTime)
        wipe(array)
        local guid = self.ovaleGuid:UnitGUID(unitId)
        if atTime and guid and self.next.aura[guid] then
            for auraId, whoseTable in pairs(self.next.aura[guid]) do
                for _, aura in pairs(whoseTable) do
                    if self:IsActiveAura(aura, atTime) and aura.filter == filter and  not aura.state then
                        local name = aura.name or "Unknown spell"
                        insert(array, name .. ": " .. auraId .. " " .. (aura.debuffType or "nil") .. " enrage=" .. ((aura.debuffType == "enrage" and 1) or 0))
                    end
                end
            end
        end
        if guid and self.current.aura[guid] then
            for auraId, whoseTable in pairs(self.current.aura[guid]) do
                for _, aura in pairs(whoseTable) do
                    if self:IsActiveAura(aura, atTime) and aura.filter == filter then
                        local name = aura.name or "Unknown spell"
                        insert(array, name .. ": " .. auraId .. " " .. (aura.debuffType or "nil") .. " enrage=" .. ((aura.debuffType == "enrage" and 1) or 0))
                    end
                end
            end
        end
        if next(array) then
            sort(array)
            return concat(array, "\n")
        end
    end,
    GetStateAuraAnyCaster = function(self, guid, auraId, atTime)
        local auraFound
        if self.current.aura[guid] and self.current.aura[guid][auraId] then
            for _, aura in pairs(self.current.aura[guid][auraId]) do
                if aura and  not aura.state and self:IsActiveAura(aura, atTime) then
                    if  not auraFound or auraFound.ending < aura.ending then
                        auraFound = aura
                    end
                end
            end
        end
        if atTime and self.next.aura[guid] and self.next.aura[guid][auraId] then
            for _, aura in pairs(self.next.aura[guid][auraId]) do
                if aura.stacks > 0 then
                    if  not auraFound or auraFound.ending < aura.ending then
                        auraFound = aura
                    end
                end
            end
        end
        return auraFound
    end,
    GetStateDebuffType = function(self, guid, debuffType, filter, casterGUID, atTime)
        local auraFound = nil
        if self.current.aura[guid] then
            for _, whoseTable in pairs(self.current.aura[guid]) do
                local aura = whoseTable[casterGUID]
                if aura and  not aura.state and self:IsActiveAura(aura, atTime) then
                    if aura.debuffType == debuffType and aura.filter == filter then
                        if  not auraFound or auraFound.ending < aura.ending then
                            auraFound = aura
                        end
                    end
                end
            end
        end
        if atTime and self.next.aura[guid] then
            for _, whoseTable in pairs(self.next.aura[guid]) do
                local aura = whoseTable[casterGUID]
                if aura and aura.stacks > 0 then
                    if aura.debuffType == debuffType and aura.filter == filter then
                        if  not auraFound or auraFound.ending < aura.ending then
                            auraFound = aura
                        end
                    end
                end
            end
        end
        return auraFound
    end,
    GetStateDebuffTypeAnyCaster = function(self, guid, debuffType, filter, atTime)
        local auraFound
        if self.current.aura[guid] then
            for _, whoseTable in pairs(self.current.aura[guid]) do
                for _, aura in pairs(whoseTable) do
                    if aura and  not aura.state and self:IsActiveAura(aura, atTime) then
                        if aura.debuffType == debuffType and aura.filter == filter then
                            if  not auraFound or auraFound.ending < aura.ending then
                                auraFound = aura
                            end
                        end
                    end
                end
            end
        end
        if atTime and self.next.aura[guid] then
            for _, whoseTable in pairs(self.next.aura[guid]) do
                for _, aura in pairs(whoseTable) do
                    if aura and  not aura.state and aura.stacks > 0 then
                        if aura.debuffType == debuffType and aura.filter == filter then
                            if  not auraFound or auraFound.ending < aura.ending then
                                auraFound = aura
                            end
                        end
                    end
                end
            end
        end
        return auraFound
    end,
    GetStateAuraOnGUID = function(self, guid, auraId, filter, mine, atTime)
        local auraFound = nil
        if __exports.DEBUFF_TYPE[auraId] then
            if mine then
                auraFound = self:GetStateDebuffType(guid, auraId, filter, self_playerGUID, atTime)
                if  not auraFound then
                    for petGUID in pairs(self_petGUID) do
                        local aura = self:GetStateDebuffType(guid, auraId, filter, petGUID, atTime)
                        if aura and ( not auraFound or auraFound.ending < aura.ending) then
                            auraFound = aura
                        end
                    end
                end
            else
                auraFound = self:GetStateDebuffTypeAnyCaster(guid, auraId, filter, atTime)
            end
        else
            if mine then
                local aura = self:GetStateAura(guid, auraId, self_playerGUID, atTime)
                if aura and aura.stacks > 0 then
                    auraFound = aura
                else
                    for petGUID in pairs(self_petGUID) do
                        aura = self:GetStateAura(guid, auraId, petGUID, atTime)
                        if aura and aura.stacks > 0 then
                            auraFound = aura
                            break
                        end
                    end
                end
            else
                auraFound = self:GetStateAuraAnyCaster(guid, auraId, atTime)
            end
        end
        return auraFound
    end,
    GetAuraByGUID = function(self, guid, auraId, filter, mine, atTime)
        local auraFound = nil
        if self.ovaleData.buffSpellList[auraId] then
            for id in pairs(self.ovaleData.buffSpellList[auraId]) do
                local aura = self:GetStateAuraOnGUID(guid, id, filter, mine, atTime)
                if aura and ( not auraFound or auraFound.ending < aura.ending) then
                    self.debug:Log("Aura %s matching '%s' found on %s with (%s, %s)", id, auraId, guid, aura.start, aura.ending)
                    auraFound = aura
                else
                end
            end
            if  not auraFound then
                self.debug:Log("Aura matching '%s' is missing on %s.", auraId, guid)
            end
        else
            auraFound = self:GetStateAuraOnGUID(guid, auraId, filter, mine, atTime)
            if auraFound then
                self.debug:Log("Aura %s found on %s with (%s, %s) [stacks=%d]", auraId, guid, auraFound.start, auraFound.ending, auraFound.stacks)
            else
                self.debug:Log("Aura %s is missing on %s.", auraId, guid)
            end
        end
        return auraFound
    end,
    GetAura = function(self, unitId, auraId, atTime, filter, mine)
        local guid = self.ovaleGuid:UnitGUID(unitId)
        if  not guid then
            return 
        end
        return self:GetAuraByGUID(guid, auraId, filter, mine, atTime)
    end,
    GetAuraWithProperty = function(self, unitId, propertyName, filter, atTime)
        local count = 0
        local guid = self.ovaleGuid:UnitGUID(unitId)
        if  not guid then
            return 
        end
        local start = huge
        local ending = 0
        if self.current.aura[guid] then
            for _, whoseTable in pairs(self.current.aura[guid]) do
                for _, aura in pairs(whoseTable) do
                    if self:IsActiveAura(aura, atTime) and  not aura.state then
                        if aura[propertyName] and aura.filter == filter then
                            count = count + 1
                            start = (aura.gain < start and aura.gain) or start
                            ending = (aura.ending > ending and aura.ending) or ending
                        end
                    end
                end
            end
        end
        if self.next.aura[guid] then
            for _, whoseTable in pairs(self.next.aura[guid]) do
                for _, aura in pairs(whoseTable) do
                    if self:IsActiveAura(aura, atTime) then
                        if aura[propertyName] and aura.filter == filter then
                            count = count + 1
                            start = (aura.gain < start and aura.gain) or start
                            ending = (aura.ending > ending and aura.ending) or ending
                        end
                    end
                end
            end
        end
        if count > 0 then
            self.debug:Log("Aura with '%s' property found on %s (count=%s, minStart=%s, maxEnding=%s).", propertyName, unitId, count, start, ending)
        else
            self.debug:Log("Aura with '%s' property is missing on %s.", propertyName, unitId)
            return 
        end
        return start, ending
    end,
    AuraCount = function(self, auraId, filter, mine, minStacks, atTime, excludeUnitId)
        self.profiler:StartProfiling("OvaleAura_state_AuraCount")
        minStacks = minStacks or 1
        count = 0
        stacks = 0
        startChangeCount, endingChangeCount = huge, huge
        startFirst, endingLast = huge, 0
        local excludeGUID = (excludeUnitId and self.ovaleGuid:UnitGUID(excludeUnitId)) or nil
        for guid, auraTable in pairs(self.current.aura) do
            if guid ~= excludeGUID and auraTable[auraId] then
                if mine and self_playerGUID then
                    local aura = self:GetStateAura(guid, auraId, self_playerGUID, atTime)
                    if aura and self:IsActiveAura(aura, atTime) and aura.filter == filter and aura.stacks >= minStacks and  not aura.state then
                        self:CountMatchingActiveAura(aura)
                    end
                    for petGUID in pairs(self_petGUID) do
                        aura = self:GetStateAura(guid, auraId, petGUID, atTime)
                        if aura and self:IsActiveAura(aura, atTime) and aura.filter == filter and aura.stacks >= minStacks and  not aura.state then
                            self:CountMatchingActiveAura(aura)
                        end
                    end
                else
                    for casterGUID in pairs(auraTable[auraId]) do
                        local aura = self:GetStateAura(guid, auraId, casterGUID, atTime)
                        if aura and self:IsActiveAura(aura, atTime) and aura.filter == filter and aura.stacks >= minStacks and  not aura.state then
                            self:CountMatchingActiveAura(aura)
                        end
                    end
                end
            end
        end
        for guid, auraTable in pairs(self.next.aura) do
            if guid ~= excludeGUID and auraTable[auraId] then
                if mine then
                    local aura = auraTable[auraId][self_playerGUID]
                    if aura then
                        if self:IsActiveAura(aura, atTime) and aura.filter == filter and aura.stacks >= minStacks then
                            self:CountMatchingActiveAura(aura)
                        end
                    end
                    for petGUID in pairs(self_petGUID) do
                        aura = auraTable[auraId][petGUID]
                        if self:IsActiveAura(aura, atTime) and aura.filter == filter and aura.stacks >= minStacks and  not aura.state then
                            self:CountMatchingActiveAura(aura)
                        end
                    end
                else
                    for _, aura in pairs(auraTable[auraId]) do
                        if self:IsActiveAura(aura, atTime) and aura.filter == filter and aura.stacks >= minStacks then
                            self:CountMatchingActiveAura(aura)
                        end
                    end
                end
            end
        end
        self.debug:Log("AuraCount(%d) is %s, %s, %s, %s, %s, %s", auraId, count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast)
        self.profiler:StopProfiling("OvaleAura_state_AuraCount")
        return count, stacks, startChangeCount, endingChangeCount, startFirst, endingLast
    end,
    InitializeState = function(self)
        self.next.aura = {}
        self.next.auraSerial = 0
        self_playerGUID = self.ovale.playerGUID
    end,
    ResetState = function(self)
        self.profiler:StartProfiling("OvaleAura_ResetState")
        self.next.auraSerial = self.next.auraSerial + 1
        if next(self.next.aura) then
            self.debug:Log("Resetting aura state:")
        end
        for guid, auraTable in pairs(self.next.aura) do
            for auraId, whoseTable in pairs(auraTable) do
                for casterGUID, aura in pairs(whoseTable) do
                    self_pool:Release(aura)
                    whoseTable[casterGUID] = nil
                    self.debug:Log("    Aura %d on %s removed.", auraId, guid)
                end
                if  not next(whoseTable) then
                    self_pool:Release(whoseTable)
                    auraTable[auraId] = nil
                end
            end
            if  not next(auraTable) then
                self_pool:Release(auraTable)
                self.next.aura[guid] = nil
            end
        end
        self.profiler:StopProfiling("OvaleAura_ResetState")
    end,
    CleanState = function(self)
        for guid in pairs(self.next.aura) do
            __exports.RemoveAurasOnGUID(self.next.aura, guid)
        end
    end,
    ApplySpellAuras = function(self, spellId, guid, atTime, auraList, spellcast)
        self.profiler:StartProfiling("OvaleAura_state_ApplySpellAuras")
        for filter, filterInfo in kpairs(auraList) do
            for auraIdKey, spellData in pairs(filterInfo) do
                local auraId = tonumber(auraIdKey)
                local duration = self:GetBaseDuration(auraId, spellcast)
                local stacks = 1
                local count = nil
                local extend = 0
                local toggle = nil
                local refresh = false
                local keepSnapshot = false
                local data = self.ovaleData:CheckSpellAuraData(auraId, spellData, atTime, guid)
                if data.refresh then
                    refresh = true
                elseif data.refresh_keep_snapshot then
                    refresh = true
                    keepSnapshot = true
                elseif data.toggle then
                    toggle = true
                elseif isNumber(data.set) then
                    count = data.set
                elseif isNumber(data.extend) then
                    extend = data.extend
                elseif isNumber(data.add) then
                    stacks = data.add
                else
                    self.debug:Log("Aura has nothing defined")
                end
                if data.enabled == nil or data.enabled then
                    local si = self.ovaleData.spellInfo[auraId]
                    local auraFound = self:GetAuraByGUID(guid, auraId, filter, true, atTime)
                    if auraFound and self:IsActiveAura(auraFound, atTime) then
                        local aura
                        if auraFound.state then
                            aura = auraFound
                        else
                            aura = self:AddAuraToGUID(guid, auraId, auraFound.source, filter, nil, 0, huge, atTime)
                            for k, v in kpairs(auraFound) do
                                (aura)[k] = v
                            end
                            aura.serial = self.next.auraSerial
                            self.debug:Log("Aura %d is copied into simulator.", auraId)
                        end
                        if toggle then
                            self.debug:Log("Aura %d is toggled off by spell %d.", auraId, spellId)
                            stacks = 0
                        end
                        if count and count > 0 then
                            stacks = count - aura.stacks
                        end
                        if refresh or extend > 0 or stacks > 0 then
                            if refresh then
                                self.debug:Log("Aura %d is refreshed to %d stack(s).", auraId, aura.stacks)
                            elseif extend > 0 then
                                self.debug:Log("Aura %d is extended by %f seconds, preserving %d stack(s).", auraId, extend, aura.stacks)
                            else
                                local maxStacks = 1
                                if si and si.max_stacks then
                                    maxStacks = si.max_stacks
                                end
                                aura.stacks = aura.stacks + stacks
                                if aura.stacks > maxStacks then
                                    aura.stacks = maxStacks
                                end
                                self.debug:Log("Aura %d gains %d stack(s) to %d because of spell %d.", auraId, stacks, aura.stacks, spellId)
                            end
                            if extend > 0 then
                                aura.duration = aura.duration + extend
                                aura.ending = aura.ending + extend
                            else
                                aura.start = atTime
                                if aura.tick and aura.tick > 0 then
                                    local remainingDuration = aura.ending - atTime
                                    local extensionDuration = 0.3 * duration
                                    if remainingDuration < extensionDuration then
                                        aura.duration = remainingDuration + duration
                                    else
                                        aura.duration = extensionDuration + duration
                                    end
                                else
                                    aura.duration = duration
                                end
                                aura.ending = aura.start + aura.duration
                            end
                            aura.gain = atTime
                            self.debug:Log("Aura %d with duration %s now ending at %s", auraId, aura.duration, aura.ending)
                            if keepSnapshot then
                                self.debug:Log("Aura %d keeping previous snapshot.", auraId)
                            elseif spellcast then
                                self.lastSpell:CopySpellcastInfo(spellcast, aura)
                            end
                        elseif stacks == 0 or stacks < 0 then
                            if stacks == 0 then
                                aura.stacks = 0
                            else
                                aura.stacks = aura.stacks + stacks
                                if aura.stacks < 0 then
                                    aura.stacks = 0
                                end
                                self.debug:Log("Aura %d loses %d stack(s) to %d because of spell %d.", auraId, -1 * stacks, aura.stacks, spellId)
                            end
                            if aura.stacks == 0 then
                                self.debug:Log("Aura %d is completely removed.", auraId)
                                aura.ending = atTime
                                aura.consumed = true
                            end
                        end
                    else
                        if toggle then
                            self.debug:Log("Aura %d is toggled on by spell %d.", auraId, spellId)
                            stacks = 1
                        end
                        if  not refresh and stacks > 0 then
                            self.debug:Log("New aura %d at %f on %s", auraId, atTime, guid)
                            local debuffType
                            if si then
                                for k, v in pairs(__exports.SPELLINFO_DEBUFF_TYPE) do
                                    if si[k] == 1 then
                                        debuffType = v
                                        break
                                    end
                                end
                            end
                            local aura = self:AddAuraToGUID(guid, auraId, self_playerGUID, filter, debuffType, 0, huge, atTime)
                            aura.stacks = stacks
                            aura.start = atTime
                            aura.duration = duration
                            if si and si.tick then
                                aura.baseTick = si.tick
                                aura.tick = self:GetTickLength(auraId, spellcast)
                            end
                            aura.ending = aura.start + aura.duration
                            aura.gain = aura.start
                            if spellcast then
                                self.lastSpell:CopySpellcastInfo(spellcast, aura)
                            end
                        end
                    end
                else
                    self.debug:Log("Aura %d (%s) is not applied.", auraId, spellData)
                end
            end
        end
        self.profiler:StopProfiling("OvaleAura_state_ApplySpellAuras")
    end,
    AddAuraToGUID = function(self, guid, auraId, casterGUID, filter, debuffType, start, ending, atTime, snapshot)
        local aura = self_pool:Get()
        aura.state = true
        aura.serial = self.next.auraSerial
        aura.lastUpdated = atTime
        aura.filter = filter
        aura.start = start or 0
        aura.ending = ending or huge
        aura.duration = aura.ending - aura.start
        aura.gain = aura.start
        aura.stacks = 1
        aura.debuffType = (isString(debuffType) and lower(debuffType)) or debuffType
        self.ovalePaperDoll:UpdateSnapshot(aura, snapshot)
        __exports.PutAura(self.next.aura, guid, auraId, casterGUID, aura)
        return aura
    end,
    RemoveAuraOnGUID = function(self, guid, auraId, filter, mine, atTime)
        local auraFound = self:GetAuraByGUID(guid, auraId, filter, mine, atTime)
        if auraFound and self:IsActiveAura(auraFound, atTime) then
            local aura
            if auraFound.state then
                aura = auraFound
            else
                aura = self:AddAuraToGUID(guid, auraId, auraFound.source, filter, nil, 0, huge, atTime)
                for k, v in kpairs(auraFound) do
                    (aura)[k] = v
                end
                aura.serial = self.next.auraSerial
            end
            aura.stacks = 0
            aura.ending = atTime
            aura.lastUpdated = atTime
        end
    end,
    GetBaseDuration = function(self, auraId, spellcast)
        spellcast = spellcast or self.ovalePaperDoll.current
        local combopoints = spellcast.combopoints or 0
        local duration = INFINITY
        local si = self.ovaleData.spellInfo[auraId]
        if si and si.duration then
            local value, ratio = self.ovaleData:GetSpellInfoPropertyNumber(auraId, nil, "duration", nil, true) or 15, 1
            if si.add_duration_combopoints and combopoints then
                duration = (value + si.add_duration_combopoints * combopoints) * ratio
            else
                duration = value * ratio
            end
        end
        if si and si.haste and spellcast then
            local hasteMultiplier = self.ovalePaperDoll:GetHasteMultiplier(si.haste, spellcast)
            duration = duration / hasteMultiplier
        end
        return duration
    end,
    GetTickLength = function(self, auraId, snapshot)
        snapshot = snapshot or self.ovalePaperDoll.current
        local tick = 3
        local si = self.ovaleData.spellInfo[auraId]
        if si then
            tick = si.tick or tick
            local hasteMultiplier = self.ovalePaperDoll:GetHasteMultiplier(si.haste, snapshot)
            tick = tick / hasteMultiplier
        end
        return tick
    end,
})
