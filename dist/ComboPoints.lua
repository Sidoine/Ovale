local __exports = LibStub:NewLibrary("ovale/ComboPoints", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
local __Equipment = LibStub:GetLibrary("ovale/Equipment")
local OvaleEquipment = __Equipment.OvaleEquipment
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local __Power = LibStub:GetLibrary("ovale/Power")
local OvalePower = __Power.OvalePower
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __Requirement = LibStub:GetLibrary("ovale/Requirement")
local RegisterRequirement = __Requirement.RegisterRequirement
local UnregisterRequirement = __Requirement.UnregisterRequirement
local __LastSpell = LibStub:GetLibrary("ovale/LastSpell")
local lastSpell = __LastSpell.lastSpell
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local insert = table.insert
local remove = table.remove
local GetTime = GetTime
local UnitPower = UnitPower
local MAX_COMBO_POINTS = MAX_COMBO_POINTS
local UNKNOWN = UNKNOWN
local ANTICIPATION = 115189
local ANTICIPATION_DURATION = 15
local ANTICIPATION_TALENT = 18
local self_hasAnticipation = false
local RUTHLESSNESS = 14161
local self_hasRuthlessness = false
local ENVENOM = 32645
local self_hasAssassination4pT17 = false
local self_pendingComboEvents = {}
local PENDING_THRESHOLD = 0.8
local function AddPendingComboEvent(atTime, spellId, guid, reason, combo)
    local comboEvent = {
        atTime = atTime,
        spellId = spellId,
        guid = guid,
        reason = reason,
        combo = combo
    }
    insert(self_pendingComboEvents, comboEvent)
    Ovale:needRefresh()
end
local function RemovePendingComboEvents(atTime, spellId, guid, reason, combo)
    local count = 0
    for k = #self_pendingComboEvents, 1, -1 do
        local comboEvent = self_pendingComboEvents[k]
        if (atTime and atTime - comboEvent.atTime > PENDING_THRESHOLD) or (comboEvent.spellId == spellId and comboEvent.guid == guid and ( not reason or comboEvent.reason == reason) and ( not combo or comboEvent.combo == combo)) then
            if comboEvent.combo == "finisher" then
                __exports.OvaleComboPoints:Debug("Removing expired %s event: spell %d combo point finisher from %s.", comboEvent.reason, comboEvent.spellId, comboEvent.reason)
            else
                __exports.OvaleComboPoints:Debug("Removing expired %s event: spell %d for %d combo points from %s.", comboEvent.reason, comboEvent.spellId, comboEvent.combo, comboEvent.reason)
            end
            count = count + 1
            remove(self_pendingComboEvents, k)
            Ovale:needRefresh()
        end
    end
    return count
end
local ComboPointsData = __class(nil, {
    constructor = function(self)
        self.combo = 0
    end
})
local OvaleComboPointsBase = OvaleState:RegisterHasState(OvaleProfiler:RegisterProfiling(OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleComboPoints", aceEvent))), ComboPointsData)
local OvaleComboPointsClass = __class(OvaleComboPointsBase, {
    OnInitialize = function(self)
        if Ovale.playerClass == "ROGUE" or Ovale.playerClass == "DRUID" then
            self:RegisterEvent("PLAYER_ENTERING_WORLD", self.Update)
            self:RegisterEvent("PLAYER_TARGET_CHANGED")
            self:RegisterEvent("UNIT_POWER")
            self:RegisterEvent("Ovale_EquipmentChanged")
            self:RegisterMessage("Ovale_SpellFinished")
            self:RegisterMessage("Ovale_TalentsChanged")
            RegisterRequirement("combo", self.RequireComboPointsHandler)
            lastSpell:RegisterSpellcastInfo(self)
        end
    end,
    OnDisable = function(self)
        if Ovale.playerClass == "ROGUE" or Ovale.playerClass == "DRUID" then
            lastSpell:UnregisterSpellcastInfo(self)
            UnregisterRequirement("combo")
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self:UnregisterEvent("PLAYER_TARGET_CHANGED")
            self:UnregisterEvent("UNIT_POWER")
            self:UnregisterEvent("Ovale_EquipmentChanged")
            self:UnregisterMessage("Ovale_SpellFinished")
            self:UnregisterMessage("Ovale_TalentsChanged")
        end
    end,
    PLAYER_TARGET_CHANGED = function(self, event, cause)
        if cause == "NIL" or cause == "down" then
        else
            self.Update()
        end
    end,
    UNIT_POWER = function(self, event, unitId, powerToken)
        if powerToken ~= OvalePower.POWER_INFO.combopoints.token then
            return 
        end
        if unitId == "player" then
            local oldCombo = self.current.combo
            self.Update()
            local difference = self.current.combo - oldCombo
            self:DebugTimestamp("%s: %d -> %d.", event, oldCombo, self.current.combo)
            local now = GetTime()
            RemovePendingComboEvents(now)
            if #self_pendingComboEvents > 0 then
                local comboEvent = self_pendingComboEvents[1]
                local spellId, _, reason, combo = comboEvent.spellId, comboEvent.guid, comboEvent.reason, comboEvent.combo
                if combo == difference or (combo == "finisher" and self.current.combo == 0 and difference < 0) then
                    self:Debug("    Matches pending %s event for %d.", reason, spellId)
                    remove(self_pendingComboEvents, 1)
                end
            end
        end
    end,
    Ovale_EquipmentChanged = function(self, event)
        self_hasAssassination4pT17 = (Ovale.playerClass == "ROGUE" and OvalePaperDoll:IsSpecialization("assassination") and OvaleEquipment:GetArmorSetCount("T17") >= 4)
    end,
    Ovale_SpellFinished = function(self, event, atTime, spellId, targetGUID, finish)
        self:Debug("%s (%f): Spell %d finished (%s) on %s", event, atTime, spellId, finish, targetGUID or UNKNOWN)
        local si = OvaleData.spellInfo[spellId]
        if si and si.combo == "finisher" and finish == "hit" then
            self:Debug("    Spell %d hit and consumed all combo points.", spellId)
            AddPendingComboEvent(atTime, spellId, targetGUID, "finisher", "finisher")
            if self_hasRuthlessness and self.current.combo == MAX_COMBO_POINTS then
                self:Debug("    Spell %d has 100% chance to grant an extra combo point from Ruthlessness.", spellId)
                AddPendingComboEvent(atTime, spellId, targetGUID, "Ruthlessness", 1)
            end
            if self_hasAssassination4pT17 and spellId == ENVENOM then
                self:Debug("    Spell %d refunds 1 combo point from Assassination 4pT17 set bonus.", spellId)
                AddPendingComboEvent(atTime, spellId, targetGUID, "Assassination 4pT17", 1)
            end
            if self_hasAnticipation and targetGUID ~= Ovale.playerGUID then
                if OvaleSpellBook:IsHarmfulSpell(spellId) then
                    local aura = OvaleAura:GetAuraByGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true, atTime)
                    if OvaleAura:IsActiveAura(aura, atTime) then
                        self:Debug("    Spell %d hit with %d Anticipation charges.", spellId, aura.stacks)
                        AddPendingComboEvent(atTime, spellId, targetGUID, "Anticipation", aura.stacks)
                    end
                end
            end
        end
    end,
    Ovale_TalentsChanged = function(self, event)
        if Ovale.playerClass == "ROGUE" then
            self_hasAnticipation = OvaleSpellBook:GetTalentPoints(ANTICIPATION_TALENT) > 0
            self_hasRuthlessness = OvaleSpellBook:IsKnownSpell(RUTHLESSNESS)
        end
    end,
    GetComboPoints = function(self, atTime)
        if atTime == nil then
            local now = GetTime()
            RemovePendingComboEvents(now)
            local total = self.current.combo
            for k = 1, #self_pendingComboEvents, 1 do
                local combo = self_pendingComboEvents[k].combo
                if combo == "finisher" then
                    total = 0
                else
                    total = total + combo
                end
                if total > MAX_COMBO_POINTS then
                    total = MAX_COMBO_POINTS
                end
            end
            return total
        end
        return self.next.combo
    end,
    DebugComboPoints = function(self)
        self:Print("Player has %d combo points.", self.current.combo)
    end,
    ComboPointCost = function(self, spellId, atTime, targetGUID)
        self:StartProfiling("OvaleComboPoints_ComboPointCost")
        local spellCost = 0
        local spellRefund = 0
        local si = OvaleData.spellInfo[spellId]
        if si and si.combo then
            local cost = OvaleData:GetSpellInfoProperty(spellId, atTime, "combo", targetGUID)
            if cost == "finisher" then
                cost = self:GetComboPoints(atTime)
                local minCost = si.min_combo or si.mincombo or 1
                local maxCost = si.max_combo
                if cost < minCost then
                    cost = minCost
                end
                if maxCost and cost > maxCost then
                    cost = maxCost
                end
            else
                local buffExtra = si.buff_combo
                if buffExtra then
                    local aura = OvaleAura:GetAura("player", buffExtra, atTime, nil, true)
                    local isActiveAura = OvaleAura:IsActiveAura(aura, atTime)
                    if isActiveAura then
                        local buffAmount = si.buff_combo_amount or 1
                        cost = cost + buffAmount
                    end
                end
                cost = -1 * cost
            end
            spellCost = cost
            local refund = OvaleData:GetSpellInfoProperty(spellId, atTime, "refund_combo", targetGUID)
            if refund == "cost" then
                refund = spellCost
            end
            spellRefund = refund or 0
        end
        self:StopProfiling("OvaleComboPoints_ComboPointCost")
        return spellCost, spellRefund
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvaleComboPoints:StartProfiling("OvaleComboPoints_ApplySpellAfterCast")
        local si = OvaleData.spellInfo[spellId]
        if si and si.combo then
            local cost, refund = self:ComboPointCost(spellId, endCast, targetGUID)
            local power = self.next.combo
            power = power - cost + refund
            if power <= 0 then
                power = 0
                if self_hasRuthlessness and self.next.combo == MAX_COMBO_POINTS then
                    __exports.OvaleComboPoints:Log("Spell %d grants one extra combo point from Ruthlessness.", spellId)
                    power = power + 1
                end
                if self_hasAnticipation and self.next.combo > 0 then
                    local aura = OvaleAura:GetAuraByGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true, endCast)
                    if OvaleAura:IsActiveAura(aura, endCast) then
                        power = power + aura.stacks
                        OvaleAura:RemoveAuraOnGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true, endCast)
                        if power > MAX_COMBO_POINTS then
                            power = MAX_COMBO_POINTS
                        end
                    end
                end
            end
            if power > MAX_COMBO_POINTS then
                if self_hasAnticipation and  not si.temp_combo then
                    local stacks = power - MAX_COMBO_POINTS
                    local aura = OvaleAura:GetAuraByGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true, endCast)
                    if OvaleAura:IsActiveAura(aura, endCast) then
                        stacks = stacks + aura.stacks
                        if stacks > MAX_COMBO_POINTS then
                            stacks = MAX_COMBO_POINTS
                        end
                    end
                    local start = endCast
                    local ending = start + ANTICIPATION_DURATION
                    aura = OvaleAura:AddAuraToGUID(Ovale.playerGUID, ANTICIPATION, Ovale.playerGUID, "HELPFUL", nil, start, ending, start)
                    aura.stacks = stacks
                end
                power = MAX_COMBO_POINTS
            end
            self.next.combo = power
        end
        __exports.OvaleComboPoints:StopProfiling("OvaleComboPoints_ApplySpellAfterCast")
    end,
    InitializeState = function(self)
        self.next.combo = 0
    end,
    ResetState = function(self)
        self.next.combo = self:GetComboPoints(nil)
        for k = 1, #self_pendingComboEvents, 1 do
            local comboEvent = self_pendingComboEvents[k]
            if comboEvent.reason == "Anticipation" then
                OvaleAura:RemoveAuraOnGUID(Ovale.playerGUID, ANTICIPATION, "HELPFUL", true, comboEvent.atTime)
                break
            end
        end
    end,
    CleanState = function(self)
    end,
    constructor = function(self, ...)
        OvaleComboPointsBase.constructor(self, ...)
        self.Update = function()
            self:StartProfiling("OvaleComboPoints_Update")
            self.current.combo = UnitPower("player", 4)
            Ovale:needRefresh()
            self:StopProfiling("OvaleComboPoints_Update")
        end
        self.RequireComboPointsHandler = function(spellId, atTime, requirement, tokens, index, targetGUID)
            local verified = false
            local cost = tokens
            if index then
                cost = tokens[index]
                index = index + 1
            end
            if cost then
                local costValue = self:ComboPointCost(spellId, atTime, targetGUID)
                if costValue > 0 then
                    local power = self:GetComboPoints(atTime)
                    if power >= costValue then
                        verified = true
                    end
                else
                    verified = true
                end
                if costValue > 0 then
                    local result = verified and "passed" or "FAILED"
                    self:Log("    Require %d combo point(s) at time=%f: %s", costValue, atTime, result)
                end
            else
                Ovale:OneTimeMessage("Warning: requirement '%s' is missing a cost argument.", requirement)
            end
            return verified, requirement, index
        end
        self.CopySpellcastInfo = function(mod, spellcast, dest)
            if spellcast.combo then
                dest.combo = spellcast.combo
            end
        end
        self.SaveSpellcastInfo = function(module, spellcast, atTime, state)
            local spellId = spellcast.spellId
            if spellId then
                local si = OvaleData.spellInfo[spellId]
                if si then
                    if si.combo == "finisher" then
                        local combo
                        combo = OvaleData:GetSpellInfoProperty(spellId, atTime, "combo", spellcast.target)
                        if combo == "finisher" then
                            local min_combo = si.min_combo or si.mincombo or 1
                            if self.current.combo >= min_combo then
                                combo = self.current.combo
                            else
                                combo = min_combo
                            end
                        elseif combo == 0 then
                            combo = MAX_COMBO_POINTS
                        end
                        spellcast.combo = combo
                    end
                end
            end
        end
    end
})
__exports.OvaleComboPoints = OvaleComboPointsClass()
OvaleState:RegisterState(__exports.OvaleComboPoints)
