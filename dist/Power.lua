local __exports = LibStub:NewLibrary("ovale/Power", 80000)
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
local CheckRequirements = __Requirement.CheckRequirements
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ceil = math.ceil
local INFINITY = math.huge
local floor = math.floor
local pairs = pairs
local tostring = tostring
local tonumber = tonumber
local lower = string.lower
local concat = table.concat
local insert = table.insert
local GetPowerRegen = GetPowerRegen
local GetManaRegen = GetManaRegen
local GetSpellPowerCost = GetSpellPowerCost
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local Enum = Enum
local MAX_COMBO_POINTS = MAX_COMBO_POINTS
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local __BaseState = LibStub:GetLibrary("ovale/BaseState")
local baseState = __BaseState.baseState
local __tools = LibStub:GetLibrary("ovale/tools")
local isNumber = __tools.isNumber
local isLuaArray = __tools.isLuaArray
local strlower = lower
local self_SpellcastInfoPowerTypes = {
    [1] = "chi",
    [2] = "holypower"
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
    GetPowerRate = function(self, powerType)
        if baseState.next.inCombat then
            return self.activeRegen[powerType]
        else
            return self.inactiveRegen[powerType]
        end
    end,
    GetPower = function(self, powerType, atTime)
        local power = self.power[powerType] or 0
        if atTime then
            local now = baseState.next.currentTime
            local seconds = atTime - now
            if seconds > 0 then
                local powerRate = self:GetPowerRate(powerType) or 0
                power = power + powerRate * seconds
            end
        end
        return power
    end,
    PowerCost = function(self, spellId, powerType, atTime, targetGUID, maximumCost)
        self:StartProfiling("OvalePower_PowerCost")
        local spellCost = 0
        local spellRefund = 0
        local si = OvaleData.spellInfo[spellId]
        if si and si[powerType] then
            local cost, ratio = OvaleData:GetSpellInfoPropertyNumber(spellId, atTime, powerType, targetGUID, true)
            local original_cost = cost
            if cost == "refill" then
                local current_power = self:GetPower(powerType, atTime)
                local max_power = LibStub:GetLibrary("ovale/Power").OvalePower.current.maxPower[powerType]
                cost = current_power - max_power
            end
            if ratio and ratio ~= 0 then
                local maxCostParam = "max_" .. powerType
                local maxCost = si[maxCostParam]
                if maxCost then
                    local power = self:GetPower(powerType, atTime)
                    if power > (maxCost or maximumCost) then
                        cost = maxCost
                    elseif power > cost then
                        cost = power
                    end
                else
                    local addRequirements = si and si.require["add_" .. powerType .. "_from_aura"]
                    if addRequirements then
                        for v, requirement in pairs(addRequirements) do
                            local verified = CheckRequirements(spellId, atTime, requirement, 1, targetGUID)
                            if verified then
                                local aura = OvaleAura:GetAura("player", requirement[2], atTime, nil, true)
                                if aura[v] then
                                    cost = cost + aura[v]
                                end
                            end
                        end
                    end
                end
                spellCost = (cost > 0 and floor(cost * ratio)) or ceil(cost * ratio)
                local refund = si["refund_" .. powerType] or 0
                if refund == "cost" then
                    spellRefund = spellCost
                else
                    local refundRequirements = si and si.require["refund_" .. powerType]
                    if refundRequirements then
                        for v, requirement in pairs(refundRequirements) do
                            local verified = CheckRequirements(spellId, atTime, requirement, 1, targetGUID)
                            if verified then
                                if v == "cost" then
                                    spellRefund = spellCost
                                elseif isNumber(v) then
                                end
                                refund = refund + (tonumber(v) or 0)
                                break
                            end
                        end
                    end
                end
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
            if cost > 0 then
                local power = self:GetPower(powerType, atTime)
                if extraPower then
                    cost = cost + extraPower
                end
                if power < cost then
                    local powerRate = self:GetPowerRate(powerType) or 0
                    if powerRate > 0 then
                        seconds = (cost - power) / powerRate
                    else
                        seconds = INFINITY
                    end
                end
            end
        end
        return seconds
    end,
    constructor = function(self)
        self.powerType = nil
        self.activeRegen = {}
        self.inactiveRegen = {}
        self.maxPower = {}
        self.power = {}
        self.RequirePowerHandler = function(spellId, atTime, requirement, tokens, index, targetGUID)
            local verified = false
            local baseCost = tokens
            if index then
                baseCost = tokens[index]
                index = index + 1
            end
            if baseCost then
                if type(baseCost) ~= "number" then
                    baseCost = 0
                    -- Ovale:OneTimeMessage("Warning: expect number for baseCost; got %s (%s)", type(baseCost), baseCost)
                end
                if baseCost > 0 then
                    local powerType = requirement
                    local cost = self:PowerCost(spellId, powerType, atTime, targetGUID)
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
                    verified = true
                end
            else
                Ovale:OneTimeMessage("Warning: requirement '%s' power is missing a cost argument.", requirement)
                Ovale:OneTimeMessage(tostring(index))
                if isLuaArray(tokens) then
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
        self.POWER_INFO = {}
        self.POWER_TYPE = {}
        self.POOLED_RESOURCE = {
            ["DRUID"] = "energy",
            ["HUNTER"] = "focus",
            ["MONK"] = "energy",
            ["ROGUE"] = "energy"
        }
        self.PRIMARY_POWER = {
            energy = true,
            focus = true,
            mana = true
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
        OvalePowerBase.constructor(self)
        local possiblePowerTypes = {
            DEATHKNIGHT = {
                runicpower = "RUNIC_POWER"
            },
            DEMONHUNTER = {
                pain = "PAIN",
                fury = "FURY"
            },
            DRUID = {
                mana = "MANA",
                rage = "RAGE",
                energy = "ENERGY",
                combopoints = "COMBO_POINTS",
                lunarpower = "LUNAR_POWER"
            },
            HUNTER = {
                focus = "FOCUS"
            },
            MAGE = {
                mana = "MANA",
                arcanecharges = "ARCANE_CHARGES"
            },
            MONK = {
                mana = "MANA",
                energy = "ENERGY",
                chi = "CHI"
            },
            PALADIN = {
                mana = "MANA",
                holypower = "HOLY_POWER"
            },
            PRIEST = {
                mana = "MANA",
                insanity = "INSANITY"
            },
            ROGUE = {
                energy = "ENERGY",
                combopoints = "COMBO_POINTS"
            },
            SHAMAN = {
                mana = "MANA",
                maelstrom = "MAELSTROM"
            },
            WARLOCK = {
                mana = "MANA",
                soulshards = "SOUL_SHARDS"
            },
            WARRIOR = {
                rage = "RAGE"
            }
        }
        for powerType, powerId in pairs(Enum.PowerType) do
            local powerTypeLower = strlower(powerType)
            local powerToken = Ovale.playerClass ~= nil and possiblePowerTypes[Ovale.playerClass][powerTypeLower]
            if powerToken then
                self.POWER_TYPE[powerId] = powerTypeLower
                self.POWER_TYPE[powerToken] = powerTypeLower
                self.POWER_INFO[powerTypeLower] = {
                    id = powerId,
                    token = powerToken,
                    mini = 0,
                    maxCost = (powerTypeLower == "combopoints" and MAX_COMBO_POINTS) or 0
                }
            end
        end
    end,
    OnInitialize = function(self)
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "EventHandler")
        self:RegisterEvent("PLAYER_LEVEL_UP", "EventHandler")
        self:RegisterEvent("UNIT_DISPLAYPOWER")
        self:RegisterEvent("UNIT_LEVEL")
        self:RegisterEvent("UNIT_MAXPOWER")
        self:RegisterEvent("UNIT_POWER_UPDATE")
        self:RegisterEvent("UNIT_POWER_FREQUENT", "UNIT_POWER_UPDATE")
        self:RegisterEvent("UNIT_RANGEDDAMAGE")
        self:RegisterEvent("UNIT_SPELL_HASTE", "UNIT_RANGEDDAMAGE")
        self:RegisterMessage("Ovale_StanceChanged", "EventHandler")
        self:RegisterMessage("Ovale_TalentsChanged", "EventHandler")
        for powerType in pairs(self.POWER_INFO) do
            RegisterRequirement(powerType, self.RequirePowerHandler)
        end
    end,
    OnDisable = function(self)
        for powerType in pairs(self.POWER_INFO) do
            UnregisterRequirement(powerType)
        end
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        self:UnregisterEvent("PLAYER_LEVEL_UP")
        self:UnregisterEvent("UNIT_DISPLAYPOWER")
        self:UnregisterEvent("UNIT_LEVEL")
        self:UnregisterEvent("UNIT_MAXPOWER")
        self:UnregisterEvent("UNIT_POWER_UPDATE")
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
    UNIT_POWER_UPDATE = function(self, event, unitId, powerToken)
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
            self:DebugTimestamp("%s: %d -> %d (%s).", event, self.current.power[powerType], power, powerType)
            if self.current.power[powerType] ~= power then
                self.current.power[powerType] = power
            end
        else
            for powerType, powerInfo in pairs(self.POWER_INFO) do
                local power = UnitPower("player", powerInfo.id, powerInfo.segments)
                self:DebugTimestamp("%s: %d -> %d (%s).", event, self.current.power[powerType], power, powerType)
                if self.current.power[powerType] ~= power then
                    self.current.power[powerType] = power
                end
            end
        end
        if event == "UNIT_POWER_UPDATE" then
            Ovale:needRefresh()
        end
        self:StopProfiling("OvalePower_UpdatePower")
    end,
    UpdatePowerRegen = function(self, event)
        self:StartProfiling("OvalePower_UpdatePowerRegen")
        for powerType in pairs(self.POWER_INFO) do
            local currentType = self.current.powerType
            if powerType == currentType then
                local inactiveRegen, activeRegen = GetPowerRegen()
                self.current.inactiveRegen[powerType], self.current.activeRegen[powerType] = inactiveRegen, activeRegen
                Ovale:needRefresh()
            elseif powerType == "mana" then
                local inactiveRegen, activeRegen = GetManaRegen()
                self.current.inactiveRegen[powerType], self.current.activeRegen[powerType] = inactiveRegen, activeRegen
                Ovale:needRefresh()
            elseif self.current.activeRegen[powerType] == nil then
                local inactiveRegen, activeRegen = 0, 0
                if powerType == "energy" then
                    inactiveRegen, activeRegen = 10, 10
                end
                self.current.inactiveRegen[powerType], self.current.activeRegen[powerType] = inactiveRegen, activeRegen
                Ovale:needRefresh()
            end
        end
        self:StopProfiling("OvalePower_UpdatePowerRegen")
    end,
    UpdatePowerType = function(self, event)
        self:StartProfiling("OvalePower_UpdatePowerType")
        local powerId = UnitPowerType("player")
        local powerType = self.POWER_TYPE[powerId]
        if self.current.powerType ~= powerType then
            self.current.powerType = powerType
            Ovale:needRefresh()
        end
        self:StopProfiling("OvalePower_UpdatePowerType")
    end,
    GetSpellCost = function(self, spellId, powerType)
        local spellPowerCost = GetSpellPowerCost(spellId)[1]
        if spellPowerCost then
            local cost = spellPowerCost.cost
            local typeId = spellPowerCost.type
            if cost == "refill" then
                local current_power = self:GetPower(powerType, atTime)
                local max_power = self.current.maxPower[powerType]
                cost = current_power - max_power
            end
            for pt, p in pairs(self.POWER_INFO) do
                if p.id == typeId and (powerType == nil or pt == powerType) then
                    return cost, pt
                end
            end
        end
        return nil, nil
    end,
    DebugPower = function(self)
        local array = {}
        insert(array, "Current Power Type: " .. self.current.powerType)
        for powerType, v in pairs(self.current.power) do
            insert(array, "\nPower Type: " .. powerType)
            insert(array, "Power: " .. v .. " / " .. self.current.maxPower[powerType])
            insert(array, "Active Regen: / " .. self.current.activeRegen[powerType])
            insert(array, "Inactive Regen: / " .. self.current.inactiveRegen[powerType])
        end
        return concat(array, "\n")
    end,
    TimeToPower = function(self, spellId, atTime, targetGUID, powerType, extraPower)
        return self:GetState(atTime):TimeToPower(spellId, atTime, targetGUID, powerType, extraPower)
    end,
    InitializeState = function(self)
        for powerType in pairs(__exports.OvalePower.POWER_INFO) do
            self.next.power[powerType] = 0
            self.next.inactiveRegen[powerType], self.next.activeRegen[powerType] = 0, 0
        end
    end,
    ResetState = function(self)
        __exports.OvalePower:StartProfiling("OvalePower_ResetState")
        for powerType in pairs(__exports.OvalePower.POWER_INFO) do
            self.next.power[powerType] = self.current.power[powerType] or 0
            self.next.maxPower[powerType] = self.current.maxPower[powerType] or 0
            self.next.activeRegen[powerType] = self.current.activeRegen[powerType] or 0
            self.next.inactiveRegen[powerType] = self.current.inactiveRegen[powerType] or 0
        end
        __exports.OvalePower:StopProfiling("OvalePower_ResetState")
    end,
    CleanState = function(self)
        for powerType in pairs(__exports.OvalePower.POWER_INFO) do
            self.next.power[powerType] = nil
        end
    end,
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvalePower:StartProfiling("OvalePower_ApplySpellStartCast")
        if isChanneled then
            self:ApplyPowerCost(spellId, targetGUID, startCast, spellcast)
        end
        __exports.OvalePower:StopProfiling("OvalePower_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __exports.OvalePower:StartProfiling("OvalePower_ApplySpellAfterCast")
        if  not isChanneled then
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
                local power = self.next.power[powerType] or 0
                if cost then
                    power = power - cost
                end
                if refund then
                    power = power + refund
                end
                local seconds = OvaleFuture.next.nextCast - atTime
                if seconds > 0 then
                    local powerRate = self.next:GetPowerRate(powerType) or 0
                    power = power + powerRate * seconds
                end
                local mini = powerInfo.mini or 0
                if mini and power < mini then
                    power = mini
                end
                local maxi = self.current.maxPower[powerType]
                if maxi and power > maxi then
                    power = maxi
                end
                self.next.power[powerType] = power
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
