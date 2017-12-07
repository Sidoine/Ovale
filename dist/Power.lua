local __exports = LibStub:NewLibrary("ovale/Power", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Profiler = LibStub:GetLibrary("ovale/Profiler")
local OvaleProfiler = __Profiler.OvaleProfiler
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __Aura = LibStub:GetLibrary("ovale/Aura")
local OvaleAura = __Aura.OvaleAura
local __Future = LibStub:GetLibrary("ovale/Future")
local OvaleFuture = __Future.OvaleFuture
local __Data = LibStub:GetLibrary("ovale/Data")
local OvaleData = __Data.OvaleData
local __State = LibStub:GetLibrary("ovale/State")
local OvaleState = __State.OvaleState
local __Requirement = LibStub:GetLibrary("ovale/Requirement")
local RegisterRequirement = __Requirement.RegisterRequirement
local UnregisterRequirement = __Requirement.UnregisterRequirement
local __LastSpell = LibStub:GetLibrary("ovale/LastSpell")
local lastSpell = __LastSpell.lastSpell
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ceil = math.ceil
local INFINITY = math.huge
local floor = math.floor
local pairs = pairs
local type = type
local tostring = tostring
local GetPowerRegen = GetPowerRegen
local GetSpellPowerCost = GetSpellPowerCost
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local SPELL_POWER_ALTERNATE_POWER = SPELL_POWER_ALTERNATE_POWER
local SPELL_POWER_CHI = SPELL_POWER_CHI
local CHI_COST = CHI_COST
local SPELL_POWER_COMBO_POINTS = SPELL_POWER_COMBO_POINTS
local COMBO_POINTS_COST = COMBO_POINTS_COST
local SPELL_POWER_ENERGY = SPELL_POWER_ENERGY
local ENERGY_COST = ENERGY_COST
local SPELL_POWER_FOCUS = SPELL_POWER_FOCUS
local FOCUS_COST = FOCUS_COST
local SPELL_POWER_HOLY_POWER = SPELL_POWER_HOLY_POWER
local HOLY_POWER_COST = HOLY_POWER_COST
local SPELL_POWER_MANA = SPELL_POWER_MANA
local MANA_COST = MANA_COST
local SPELL_POWER_RAGE = SPELL_POWER_RAGE
local RAGE_COST = RAGE_COST
local SPELL_POWER_RUNIC_POWER = SPELL_POWER_RUNIC_POWER
local RUNIC_POWER_COST = RUNIC_POWER_COST
local SPELL_POWER_SOUL_SHARDS = SPELL_POWER_SOUL_SHARDS
local SOUL_SHARDS_COST = SOUL_SHARDS_COST
local SPELL_POWER_LUNAR_POWER = SPELL_POWER_LUNAR_POWER
local LUNAR_POWER_COST = LUNAR_POWER_COST
local SPELL_POWER_INSANITY = SPELL_POWER_INSANITY
local INSANITY_COST = INSANITY_COST
local SPELL_POWER_MAELSTROM = SPELL_POWER_MAELSTROM
local MAELSTROM_COST = MAELSTROM_COST
local SPELL_POWER_ARCANE_CHARGES = SPELL_POWER_ARCANE_CHARGES
local ARCANE_CHARGES_COST = ARCANE_CHARGES_COST
local SPELL_POWER_PAIN = SPELL_POWER_PAIN
local PAIN_COST = PAIN_COST
local SPELL_POWER_FURY = SPELL_POWER_FURY
local FURY_COST = FURY_COST
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local __BaseState = LibStub:GetLibrary("ovale/BaseState")
local baseState = __BaseState.baseState
local function isString(s)
    return type(s) == "string"
end
local self_SpellcastInfoPowerTypes = {
    [1] = "chi",
    [2] = "holy"
}
do
    local debugOptions = {
        power = {
            name = L["Power"],
            type = "group",
            args = {
                power = {
                    name = L["Power"],
                    type = "input",
                    multiline = 25,
                    width = "full",
                    get = function(info)
                        return __exports.OvalePower:DebugPower()
                    end

                }
            }
        }
    }
    for k, v in pairs(debugOptions) do
        OvaleDebug.options.args[k] = v
    end
end
local PowerModule = __class(nil, {
    GetPower = function(self, powerType, atTime)
        local power = self.power[powerType] or 0
        local powerRate = 0
        if self.powerType and self.powerType == powerType and self.activeRegen then
            powerRate = self.activeRegen
        elseif self.powerRate and self.powerRate[powerType] then
            powerRate = self.powerRate[powerType]
        end
        if atTime then
            local now = baseState.next.currentTime
            local seconds = atTime - now
            if seconds > 0 then
                power = power + powerRate * seconds
            end
        end
        return power
    end,
    PowerCost = function(self, spellId, powerType, atTime, targetGUID, maximumCost)
        self:StartProfiling("OvalePower_PowerCost")
        local buffParam = "buff_" .. powerType
        local spellCost = 0
        local spellRefund = 0
        local si = OvaleData.spellInfo[spellId]
        if si and si[powerType] then
            local cost = OvaleData:GetSpellInfoProperty(spellId, atTime, powerType, targetGUID)
            local costNumber
            if isString(cost) then
                if cost == "finisher" then
                    cost = self:GetPower(powerType, atTime)
                    local minCostParam = "min_" .. powerType
                    local maxCostParam = "max_" .. powerType
                    local minCost = si[minCostParam] or 1
                    local maxCost = si[maxCostParam]
                    if cost < minCost then
                        costNumber = minCost
                    end
                    if maxCost and cost > maxCost then
                        costNumber = maxCost
                    end
                elseif cost == "refill" then
                    costNumber = self:GetPower(powerType, atTime) - self.maxPower[powerType]
                end
                costNumber = 0
            else
                local buffExtraParam = buffParam
                local buffAmountParam = buffParam .. "_amount"
                local buffExtra = si[buffExtraParam]
                if buffExtra then
                    local aura = OvaleAura:GetAura("player", buffExtra, atTime, nil, true)
                    local isActiveAura = OvaleAura:IsActiveAura(aura, atTime)
                    if isActiveAura then
                        local buffAmount = 0
                        if type(buffAmountParam) == "number" then
                            buffAmount = si[buffAmountParam] or -1
                        elseif si[buffAmountParam] == "value3" then
                            buffAmount = aura.value3 or -1
                        elseif si[buffAmountParam] == "value2" then
                            buffAmount = aura.value2 or -1
                        elseif si[buffAmountParam] == "value1" then
                            buffAmount = aura.value1 or -1
                        else
                            buffAmount = -1
                        end
                        local siAura = OvaleData.spellInfo[buffExtra]
                        if siAura and siAura.stacking == 1 then
                            buffAmount = buffAmount * aura.stacks
                        end
                        cost = cost + buffAmount
                        self:Log("Spell ID '%d' had %f %s added from aura ID '%d'.", spellId, buffAmount, powerType, aura.spellId)
                    end
                end
                costNumber = cost
            end
            local extraPowerParam = "extra_" .. powerType
            local extraPower = OvaleData:GetSpellInfoProperty(spellId, atTime, extraPowerParam, targetGUID)
            if extraPower and  not isString(extraPower) then
                if  not maximumCost then
                    local power = floor(self:GetPower(powerType, atTime))
                    power = power > cost and power - costNumber or 0
                    if extraPower >= power then
                        extraPower = power
                    end
                end
                costNumber = costNumber + extraPower
            end
            spellCost = ceil(costNumber)
            local refundParam = "refund_" .. powerType
            local refund = OvaleData:GetSpellInfoProperty(spellId, atTime, refundParam, targetGUID)
            if isString(refund) then
                if refund == "cost" then
                    spellRefund = ceil(spellCost)
                end
            else
                spellRefund = ceil(refund or 0)
            end
        else
            local cost = __exports.OvalePower:GetSpellCost(spellId, powerType)
            if cost then
                spellCost = cost
            end
        end
        self:StopProfiling("OvalePower_PowerCost")
        return spellCost, spellRefund
    end,
    StartProfiling = function(self, name)
        __exports.OvalePower:StartProfiling(name)
    end,
    StopProfiling = function(self, name)
        __exports.OvalePower:StopProfiling(name)
    end,
    Log = function(self, ...)
        __exports.OvalePower:Log(...)
    end,
    TimeToPower = function(self, spellId, atTime, targetGUID, powerType, extraPower)
        local seconds = 0
        powerType = powerType or __exports.OvalePower.POOLED_RESOURCE[OvalePaperDoll.class]
        if powerType then
            local cost = self:PowerCost(spellId, powerType, atTime, targetGUID)
            local power = self:GetPower(powerType, atTime)
            local powerRate = self.powerRate[powerType] or 0
            if extraPower then
                cost = cost + extraPower
            end
            if power < cost then
                if powerRate > 0 then
                    seconds = (cost - power) / powerRate
                else
                    seconds = INFINITY
                end
            end
        end
        return seconds
    end,
    constructor = function(self)
        self.powerType = nil
        self.activeRegen = 0
        self.inactiveRegen = 0
        self.powerRate = {}
        self.maxPower = {}
        self.power = {}
        self.RequirePowerHandler = function(spellId, atTime, requirement, tokens, index, targetGUID)
            local verified = false
            local cost = tokens
            if index then
                cost = tokens[index]
                index = index + 1
            end
            if cost then
                local powerType = requirement
                cost = self:PowerCost(spellId, powerType, atTime, targetGUID)
                if cost > 0 then
                    local power = self:GetPower(powerType, atTime)
                    if power >= cost then
                        verified = true
                    end
                    self:Log("   Has power %f %s", power, powerType)
                else
                    verified = true
                end
                if cost > 0 then
                    local result = verified and "passed" or "FAILED"
                    self:Log("    Require %f %s at time=%f: %s", cost, powerType, atTime, result)
                end
            else
                Ovale:OneTimeMessage("Warning: requirement '%s' power is missing a cost argument.", requirement)
                Ovale:OneTimeMessage(tostring(index))
                if type(tokens) == "table" then
                    for k, v in pairs(tokens) do
                        Ovale:OneTimeMessage(k .. " = " .. tostring(v))
                    end
                end
            end
            return verified, requirement, index
        end
    end
})
local OvalePowerBase = OvaleState:RegisterHasState(OvaleDebug:RegisterDebugging(OvaleProfiler:RegisterProfiling(Ovale:NewModule("OvalePower", aceEvent))), PowerModule)
local OvalePowerClass = __class(OvalePowerBase, {
    constructor = function(self)
        self.POWER_INFO = {
            alternate = {
                id = SPELL_POWER_ALTERNATE_POWER,
                token = "ALTERNATE_RESOURCE_TEXT",
                mini = 0
            },
            chi = {
                id = SPELL_POWER_CHI,
                token = "CHI",
                mini = 0,
                costString = CHI_COST
            },
            combopoints = {
                id = SPELL_POWER_COMBO_POINTS,
                token = "COMBO_POINTS",
                mini = 0,
                costString = COMBO_POINTS_COST
            },
            energy = {
                id = SPELL_POWER_ENERGY,
                token = "ENERGY",
                mini = 0,
                costString = ENERGY_COST
            },
            focus = {
                id = SPELL_POWER_FOCUS,
                token = "FOCUS",
                mini = 0,
                costString = FOCUS_COST
            },
            holy = {
                id = SPELL_POWER_HOLY_POWER,
                token = "HOLY_POWER",
                mini = 0,
                costString = HOLY_POWER_COST
            },
            mana = {
                id = SPELL_POWER_MANA,
                token = "MANA",
                mini = 0,
                costString = MANA_COST
            },
            rage = {
                id = SPELL_POWER_RAGE,
                token = "RAGE",
                mini = 0,
                costString = RAGE_COST
            },
            runicpower = {
                id = SPELL_POWER_RUNIC_POWER,
                token = "RUNIC_POWER",
                mini = 0,
                costString = RUNIC_POWER_COST
            },
            soulshards = {
                id = SPELL_POWER_SOUL_SHARDS,
                token = "SOUL_SHARDS",
                mini = 0,
                costString = SOUL_SHARDS_COST
            },
            astralpower = {
                id = SPELL_POWER_LUNAR_POWER,
                token = "LUNAR_POWER",
                mini = 0,
                costString = LUNAR_POWER_COST
            },
            insanity = {
                id = SPELL_POWER_INSANITY,
                token = "INSANITY",
                mini = 0,
                costString = INSANITY_COST
            },
            maelstrom = {
                id = SPELL_POWER_MAELSTROM,
                token = "MAELSTROM",
                mini = 0,
                costString = MAELSTROM_COST
            },
            arcanecharges = {
                id = SPELL_POWER_ARCANE_CHARGES,
                token = "ARCANE_CHARGES",
                mini = 0,
                costString = ARCANE_CHARGES_COST
            },
            pain = {
                id = SPELL_POWER_PAIN,
                token = "PAIN",
                mini = 0,
                costString = PAIN_COST
            },
            fury = {
                id = SPELL_POWER_FURY,
                token = "FURY",
                mini = 0,
                costString = FURY_COST
            }
        }
        self.PRIMARY_POWER = {
            energy = true,
            focus = true,
            mana = true
        }
        self.POWER_TYPE = {}
        self.POOLED_RESOURCE = {
            ["DRUID"] = "energy",
            ["HUNTER"] = "focus",
            ["MONK"] = "energy",
            ["ROGUE"] = "energy"
        }
        self.RequirePowerHandler = function(spellId, atTime, requirement, tokens, index, targetGUID)
            return self:GetState(atTime).RequirePowerHandler(spellId, atTime, requirement, tokens, index, targetGUID)
        end
        self.CopySpellcastInfo = function(mod, spellcast, dest)
            for _, powerType in pairs(self_SpellcastInfoPowerTypes) do
                if spellcast[powerType] then
                    dest[powerType] = spellcast[powerType]
                end
            end
        end
        self.SaveSpellcastInfo = function(mod, spellcast, atTime, snapshot)
            local spellId = spellcast.spellId
            if spellId then
                local si = OvaleData.spellInfo[spellId]
                if si then
                    local state = self:GetState(atTime)
                    for _, powerType in pairs(self_SpellcastInfoPowerTypes) do
                        if si[powerType] == "finisher" then
                            local maxCostParam = "max_" .. powerType
                            local maxCost = si[maxCostParam] or 1
                            local cost = OvaleData:GetSpellInfoProperty(spellId, atTime, powerType, spellcast.target)
                            if isString(cost) then
                                if cost == "finisher" then
                                    local power = state:GetPower(powerType, atTime)
                                    if power > maxCost then
                                        spellcast[powerType] = maxCost
                                    else
                                        spellcast[powerType] = power
                                    end
                                end
                            elseif cost == 0 then
                                spellcast[powerType] = maxCost
                            end
                            spellcast[powerType] = cost
                        end
                    end
                end
            end
        end
        OvalePowerBase.constructor(self)
        for powerType, v in pairs(self.POWER_INFO) do
            if v.id == nil then
                self:Print("Unknown resource %s", v.token)
            end
            self.POWER_TYPE[v.id] = powerType
            self.POWER_TYPE[v.token] = powerType
        end
    end,
    OnInitialize = function(self)
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "EventHandler")
        self:RegisterEvent("PLAYER_LEVEL_UP", "EventHandler")
        self:RegisterEvent("UNIT_DISPLAYPOWER")
        self:RegisterEvent("UNIT_LEVEL")
        self:RegisterEvent("UNIT_MAXPOWER")
        self:RegisterEvent("UNIT_POWER")
        self:RegisterEvent("UNIT_POWER_FREQUENT", "UNIT_POWER")
        self:RegisterEvent("UNIT_RANGEDDAMAGE")
        self:RegisterEvent("UNIT_SPELL_HASTE", "UNIT_RANGEDDAMAGE")
        self:RegisterMessage("Ovale_StanceChanged", "EventHandler")
        self:RegisterMessage("Ovale_TalentsChanged", "EventHandler")
        for powerType in pairs(self.POWER_INFO) do
            RegisterRequirement(powerType, self.RequirePowerHandler)
        end
        lastSpell:RegisterSpellcastInfo(self)
    end,
    OnDisable = function(self)
        lastSpell:UnregisterSpellcastInfo(self)
        for powerType in pairs(self.POWER_INFO) do
            UnregisterRequirement(powerType)
        end
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("PLAYER_LEVEL_UP")
        self:UnregisterEvent("UNIT_DISPLAYPOWER")
        self:UnregisterEvent("UNIT_LEVEL")
        self:UnregisterEvent("UNIT_MAXPOWER")
        self:UnregisterEvent("UNIT_POWER")
        self:UnregisterEvent("UNIT_POWER_FREQUENT")
        self:UnregisterEvent("UNIT_RANGEDDAMAGE")
        self:UnregisterEvent("UNIT_SPELL_HASTE")
        self:UnregisterMessage("Ovale_StanceChanged")
        self:UnregisterMessage("Ovale_TalentsChanged")
    end,
    EventHandler = function(self, event)
        self:UpdatePowerType(event)
        self:UpdateMaxPower(event)
        self:UpdatePower(event)
        self:UpdatePowerRegen(event)
    end,
    UNIT_DISPLAYPOWER = function(self, event, unitId)
        if unitId == "player" then
            self:UpdatePowerType(event)
            self:UpdatePowerRegen(event)
        end
    end,
    UNIT_LEVEL = function(self, event, unitId)
        if unitId == "player" then
            self:EventHandler(event)
        end
    end,
    UNIT_MAXPOWER = function(self, event, unitId, powerToken)
        if unitId == "player" then
            local powerType = self.POWER_TYPE[powerToken]
            if powerType then
                self:UpdateMaxPower(event, powerType)
            end
        end
    end,
    UNIT_POWER = function(self, event, unitId, powerToken)
        if unitId == "player" then
            local powerType = self.POWER_TYPE[powerToken]
            if powerType then
                self:UpdatePower(event, powerType)
            end
        end
    end,
    UNIT_RANGEDDAMAGE = function(self, event, unitId)
        if unitId == "player" then
            self:UpdatePowerRegen(event)
        end
    end,
    UpdateMaxPower = function(self, event, powerType)
        self:StartProfiling("OvalePower_UpdateMaxPower")
        if powerType then
            local powerInfo = self.POWER_INFO[powerType]
            local maxPower = UnitPowerMax("player", powerInfo.id, powerInfo.segments)
            if self.current.maxPower[powerType] ~= maxPower then
                self.current.maxPower[powerType] = maxPower
                Ovale:needRefresh()
            end
        else
            for powerType, powerInfo in pairs(self.POWER_INFO) do
                local maxPower = UnitPowerMax("player", powerInfo.id, powerInfo.segments)
                if self.current.maxPower[powerType] ~= maxPower then
                    self.current.maxPower[powerType] = maxPower
                    Ovale:needRefresh()
                end
            end
        end
        self:StopProfiling("OvalePower_UpdateMaxPower")
    end,
    UpdatePower = function(self, event, powerType)
        self:StartProfiling("OvalePower_UpdatePower")
        if powerType then
            local powerInfo = self.POWER_INFO[powerType]
            local power = UnitPower("player", powerInfo.id, powerInfo.segments)
            if self.current.power[powerType] ~= power then
                self.current.power[powerType] = power
                Ovale:needRefresh()
            end
            self:DebugTimestamp("%s: %d -> %d (%s).", event, self.current.power[powerType], power, powerType)
        else
            for powerType, powerInfo in pairs(self.POWER_INFO) do
                local power = UnitPower("player", powerInfo.id, powerInfo.segments)
                if self.current.power[powerType] ~= power then
                    self.current.power[powerType] = power
                    Ovale:needRefresh()
                end
                self:DebugTimestamp("%s: %d -> %d (%s).", event, self.current.power[powerType], power, powerType)
            end
        end
        Ovale:needRefresh()
        self:StopProfiling("OvalePower_UpdatePower")
    end,
    UpdatePowerRegen = function(self, event)
        self:StartProfiling("OvalePower_UpdatePowerRegen")
        local inactiveRegen, activeRegen = GetPowerRegen()
        if self.current.inactiveRegen ~= inactiveRegen or self.current.activeRegen ~= activeRegen then
            self.current.inactiveRegen, self.current.activeRegen = inactiveRegen, activeRegen
            Ovale:needRefresh()
        end
        self:StopProfiling("OvalePower_UpdatePowerRegen")
    end,
    UpdatePowerType = function(self, event)
        self:StartProfiling("OvalePower_UpdatePowerType")
        local currentType = UnitPowerType("player")
        local powerType = self.POWER_TYPE[currentType]
        if self.current.powerType ~= powerType then
            self.current.powerType = powerType
            Ovale:needRefresh()
        end
        Ovale:needRefresh()
        self:StopProfiling("OvalePower_UpdatePowerType")
    end,
    GetSpellCost = function(self, spellId, powerType)
        local spellPowerCost = GetSpellPowerCost(spellId)[1]
        if spellPowerCost then
            local cost = spellPowerCost.cost
            local typeId = spellPowerCost.type
            for pt, p in pairs(self.POWER_INFO) do
                if p.id == typeId and (powerType == nil or pt == powerType) then
                    return cost, pt
                end
            end
        end
        return nil, nil
    end,
    DebugPower = function(self)
        self:Print("Power type: %s", self.current.powerType)
        for powerType, v in pairs(self.current.power) do
            self:Print("Power (%s): %d / %d", powerType, v, self.current.maxPower[powerType])
        end
        self:Print("Active regen: %f", self.current.activeRegen)
        self:Print("Inactive regen: %f", self.current.inactiveRegen)
    end,
    TimeToPower = function(self, spellId, atTime, targetGUID, powerType, extraPower)
        return self:GetState(atTime):TimeToPower(spellId, atTime, targetGUID, powerType, extraPower)
    end,
    InitializeState = function(self)
        for powerType in pairs(__exports.OvalePower.POWER_INFO) do
            self.next.power[powerType] = 0
        end
        self.next.powerRate = {}
    end,
    ResetState = function(self)
        __exports.OvalePower:StartProfiling("OvalePower_ResetState")
        for powerType in pairs(__exports.OvalePower.POWER_INFO) do
            self.next.power[powerType] = self.current.power[powerType] or 0
            self.next.maxPower[powerType] = self.current.maxPower[powerType] or 0
        end
        for powerType in pairs(__exports.OvalePower.POWER_INFO) do
            self.next.powerRate[powerType] = 0
        end
        if baseState.current.inCombat then
            self.next.powerRate[self.current.powerType] = self.current.activeRegen
        else
            self.next.powerRate[self.current.powerType] = self.current.inactiveRegen
        end
        __exports.OvalePower:StopProfiling("OvalePower_ResetState")
    end,
    CleanState = function(self)
        for powerType in pairs(__exports.OvalePower.POWER_INFO) do
            self.next.power[powerType] = nil
        end
        for k in pairs(self.current.powerRate) do
            self.next.powerRate[k] = nil
        end
    end,
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvalePower:StartProfiling("OvalePower_ApplySpellStartCast")
        if isChanneled then
            if baseState.next.inCombat then
                self.next.powerRate[self.current.powerType] = self.current.activeRegen
            end
            self:ApplyPowerCost(spellId, targetGUID, startCast, spellcast)
        end
        __exports.OvalePower:StopProfiling("OvalePower_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvalePower:StartProfiling("OvalePower_ApplySpellAfterCast")
        if  not isChanneled then
            if baseState.next.inCombat then
                self.next.powerRate[self.current.powerType] = self.current.activeRegen
            end
            self:ApplyPowerCost(spellId, targetGUID, endCast, spellcast)
        end
        __exports.OvalePower:StopProfiling("OvalePower_ApplySpellAfterCast")
    end,
    ApplyPowerCost = function(self, spellId, targetGUID, atTime, spellcast)
        __exports.OvalePower:StartProfiling("OvalePower_state_ApplyPowerCost")
        local si = OvaleData.spellInfo[spellId]
        do
            local cost, powerType = __exports.OvalePower:GetSpellCost(spellId)
            if cost and powerType and self.next.power[powerType] and  not (si and si[powerType]) then
                self.next.power[powerType] = self.next.power[powerType] - cost
            end
        end
        if si then
            for powerType, powerInfo in pairs(__exports.OvalePower.POWER_INFO) do
                local cost, refund = self.next:PowerCost(spellId, powerType, atTime, targetGUID)
                local power = self[powerType] or 0
                if cost then
                    power = power - cost + refund
                    local seconds = OvaleFuture.next.nextCast - atTime
                    if seconds > 0 then
                        local powerRate = self.next.powerRate[powerType] or 0
                        power = power + powerRate * seconds
                    end
                    local mini = powerInfo.mini or 0
                    local maxi = self.current.maxPower[powerType]
                    if mini and power < mini then
                        power = mini
                    end
                    if maxi and power > maxi then
                        power = maxi
                    end
                    self[powerType] = power
                end
            end
        end
        __exports.OvalePower:StopProfiling("OvalePower_state_ApplyPowerCost")
    end,
    PowerCost = function(self, spellId, powerType, atTime, targetGUID, maximumCost)
        return self:GetState(atTime):PowerCost(spellId, powerType, atTime, targetGUID, maximumCost)
    end,
})
__exports.OvalePower = OvalePowerClass()
OvaleState:RegisterState(__exports.OvalePower)
