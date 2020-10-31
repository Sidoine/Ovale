local __exports = LibStub:NewLibrary("ovale/states/Power", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local aceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
local ceil = math.ceil
local INFINITY = math.huge
local floor = math.floor
local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local tonumber = tonumber
local kpairs = pairs
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
local __tools = LibStub:GetLibrary("ovale/tools")
local isNumber = __tools.isNumber
local isLuaArray = __tools.isLuaArray
local OneTimeMessage = __tools.OneTimeMessage
local __State = LibStub:GetLibrary("ovale/State")
local States = __State.States
local strlower = lower
local self_SpellcastInfoPowerTypes = {
    [1] = "chi",
    [2] = "holypower"
}
local PowerState = __class(nil, {
    constructor = function(self)
        self.powerType = "mana"
        self.activeRegen = {}
        self.inactiveRegen = {}
        self.maxPower = {}
        self.power = {}
    end
})
local POWERS = {
    mana = true,
    rage = true,
    focus = true,
    energy = true,
    combopoints = true,
    runicpower = true,
    soulshards = true,
    lunarpower = true,
    holypower = true,
    alternate = true,
    maelstrom = true,
    chi = true,
    insanity = true,
    arcanecharges = true,
    pain = true,
    fury = true
}
__exports.POWER_TYPES = {}
__exports.POOLED_RESOURCE = {
    ["DRUID"] = "energy",
    ["HUNTER"] = "focus",
    ["MONK"] = "energy",
    ["ROGUE"] = "energy"
}
__exports.PRIMARY_POWER = {
    energy = true,
    focus = true,
    mana = true
}
__exports.OvalePowerClass = __class(States, {
    constructor = function(self, ovaleDebug, ovale, ovaleProfiler, ovaleData, ovaleFuture, baseState, ovaleAura, ovalePaperDoll, requirement, ovaleSpellBook, combat)
        self.ovale = ovale
        self.ovaleData = ovaleData
        self.ovaleFuture = ovaleFuture
        self.baseState = baseState
        self.ovaleAura = ovaleAura
        self.ovalePaperDoll = ovalePaperDoll
        self.requirement = requirement
        self.ovaleSpellBook = ovaleSpellBook
        self.combat = combat
        self.POWER_INFO = {}
        self.POWER_TYPE = {}
        self.OnInitialize = function()
            self.module:RegisterEvent("PLAYER_ENTERING_WORLD", self.EventHandler)
            self.module:RegisterEvent("PLAYER_LEVEL_UP", self.EventHandler)
            self.module:RegisterEvent("UNIT_DISPLAYPOWER", self.UNIT_DISPLAYPOWER)
            self.module:RegisterEvent("UNIT_LEVEL", self.UNIT_LEVEL)
            self.module:RegisterEvent("UNIT_MAXPOWER", self.UNIT_MAXPOWER)
            self.module:RegisterEvent("UNIT_POWER_UPDATE", self.UNIT_POWER_UPDATE)
            self.module:RegisterEvent("UNIT_POWER_FREQUENT", self.UNIT_POWER_UPDATE)
            self.module:RegisterEvent("UNIT_RANGEDDAMAGE", self.UNIT_RANGEDDAMAGE)
            self.module:RegisterEvent("UNIT_SPELL_HASTE", self.UNIT_RANGEDDAMAGE)
            self.module:RegisterMessage("Ovale_StanceChanged", self.EventHandler)
            self.module:RegisterMessage("Ovale_TalentsChanged", self.EventHandler)
            self:initializePower()
            for powerType in pairs(self.POWER_INFO) do
                self.requirement:RegisterRequirement(powerType, self.RequirePowerHandler)
            end
        end
        self.OnDisable = function()
            for powerType in pairs(self.POWER_INFO) do
                self.requirement:UnregisterRequirement(powerType)
            end
            self.module:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self.module:UnregisterEvent("PLAYER_LEVEL_UP")
            self.module:UnregisterEvent("UNIT_DISPLAYPOWER")
            self.module:UnregisterEvent("UNIT_LEVEL")
            self.module:UnregisterEvent("UNIT_MAXPOWER")
            self.module:UnregisterEvent("UNIT_POWER_UPDATE")
            self.module:UnregisterEvent("UNIT_POWER_FREQUENT")
            self.module:UnregisterEvent("UNIT_RANGEDDAMAGE")
            self.module:UnregisterEvent("UNIT_SPELL_HASTE")
            self.module:UnregisterMessage("Ovale_StanceChanged")
            self.module:UnregisterMessage("Ovale_TalentsChanged")
        end
        self.EventHandler = function(event)
            self:UpdatePowerType(event)
            self:UpdateMaxPower(event)
            self:UpdatePower(event)
            self:UpdatePowerRegen(event)
        end
        self.UNIT_DISPLAYPOWER = function(event, unitId)
            if unitId == "player" then
                self:UpdatePowerType(event)
                self:UpdatePowerRegen(event)
            end
        end
        self.UNIT_LEVEL = function(event, unitId)
            if unitId == "player" then
                self.EventHandler(event)
            end
        end
        self.UNIT_MAXPOWER = function(event, unitId, powerToken)
            if unitId == "player" then
                local powerType = self.POWER_TYPE[powerToken]
                if powerType then
                    self:UpdateMaxPower(event, powerType)
                end
            end
        end
        self.UNIT_POWER_UPDATE = function(event, unitId, powerToken)
            if unitId == "player" then
                local powerType = self.POWER_TYPE[powerToken]
                if powerType then
                    self:UpdatePower(event, powerType)
                end
            end
        end
        self.UNIT_RANGEDDAMAGE = function(event, unitId)
            if unitId == "player" then
                self:UpdatePowerRegen(event)
            end
        end
        self.RequirePowerHandler = function(spellId, atTime, requirement, tokens, index, targetGUID)
            return self:getPowerRequirementAt(self:GetState(atTime), spellId, atTime, requirement, tokens, index, targetGUID)
        end
        self.CopySpellcastInfo = function(mod, spellcast, dest)
            for _, powerType in pairs(self_SpellcastInfoPowerTypes) do
                if spellcast[powerType] then
                    dest[powerType] = spellcast[powerType]
                end
            end
        end
        States.constructor(self, PowerState)
        self.module = ovale:createModule("OvalePower", self.OnInitialize, self.OnDisable, aceEvent)
        self.tracer = ovaleDebug:create(self.module:GetName())
        self.profiler = ovaleProfiler:create(self.module:GetName())
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
                            return self:DebugPower()
                        end
                    }
                }
            }
        }
        for k, v in pairs(debugOptions) do
            ovaleDebug.defaultOptions.args[k] = v
        end
    end,
    initializePower = function(self)
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
            local powerToken = self.ovale.playerClass ~= nil and possiblePowerTypes[self.ovale.playerClass][powerTypeLower]
            if powerToken then
                self.POWER_TYPE[powerId] = powerTypeLower
                self.POWER_TYPE[powerToken] = powerTypeLower
                self.POWER_INFO[powerTypeLower] = {
                    id = powerId,
                    token = powerToken,
                    mini = 0,
                    type = powerTypeLower,
                    maxCost = (powerTypeLower == "combopoints" and MAX_COMBO_POINTS) or 0
                }
                insert(__exports.POWER_TYPES, powerTypeLower)
            end
        end
    end,
    UpdateMaxPower = function(self, event, powerType)
        self.profiler:StartProfiling("OvalePower_UpdateMaxPower")
        if powerType then
            local powerInfo = self.POWER_INFO[powerType]
            if powerInfo then
                local maxPower = UnitPowerMax("player", powerInfo.id, powerInfo.segments)
                if self.current.maxPower[powerType] ~= maxPower then
                    self.current.maxPower[powerType] = maxPower
                    self.ovale:needRefresh()
                end
            end
        else
            for powerType, powerInfo in pairs(self.POWER_INFO) do
                local maxPower = UnitPowerMax("player", powerInfo.id, powerInfo.segments)
                if self.current.maxPower[powerType] ~= maxPower then
                    self.current.maxPower[powerType] = maxPower
                    self.ovale:needRefresh()
                end
            end
        end
        self.profiler:StopProfiling("OvalePower_UpdateMaxPower")
    end,
    UpdatePower = function(self, event, powerType)
        self.profiler:StartProfiling("OvalePower_UpdatePower")
        if powerType then
            local powerInfo = self.POWER_INFO[powerType]
            if powerInfo then
                local power = UnitPower("player", powerInfo.id, powerInfo.segments)
                self.tracer:DebugTimestamp("%s: %d -> %d (%s).", event, self.current.power[powerType], power, powerType)
                if self.current.power[powerType] ~= power then
                    self.current.power[powerType] = power
                end
            end
        else
            for powerType, powerInfo in kpairs(self.POWER_INFO) do
                local power = UnitPower("player", powerInfo.id, powerInfo.segments)
                self.tracer:DebugTimestamp("%s: %d -> %d (%s).", event, self.current.power[powerType], power, powerType)
                if self.current.power[powerType] ~= power then
                    self.current.power[powerType] = power
                end
            end
        end
        if event == "UNIT_POWER_UPDATE" then
            self.ovale:needRefresh()
        end
        self.profiler:StopProfiling("OvalePower_UpdatePower")
    end,
    UpdatePowerRegen = function(self, event)
        self.profiler:StartProfiling("OvalePower_UpdatePowerRegen")
        for powerType in pairs(self.POWER_INFO) do
            local currentType = self.current.powerType
            if powerType == currentType then
                local inactiveRegen, activeRegen = GetPowerRegen()
                self.current.inactiveRegen[powerType], self.current.activeRegen[powerType] = inactiveRegen, activeRegen
                self.ovale:needRefresh()
            elseif powerType == "mana" then
                local inactiveRegen, activeRegen = GetManaRegen()
                self.current.inactiveRegen[powerType], self.current.activeRegen[powerType] = inactiveRegen, activeRegen
                self.ovale:needRefresh()
            elseif self.current.activeRegen[powerType] == nil then
                local inactiveRegen, activeRegen = 0, 0
                if powerType == "energy" then
                    inactiveRegen, activeRegen = 10, 10
                end
                self.current.inactiveRegen[powerType], self.current.activeRegen[powerType] = inactiveRegen, activeRegen
                self.ovale:needRefresh()
            end
        end
        self.profiler:StopProfiling("OvalePower_UpdatePowerRegen")
    end,
    UpdatePowerType = function(self, event)
        self.profiler:StartProfiling("OvalePower_UpdatePowerType")
        local powerId = UnitPowerType("player")
        local powerType = self.POWER_TYPE[powerId]
        if self.current.powerType ~= powerType then
            self.current.powerType = powerType
            self.ovale:needRefresh()
        end
        self.profiler:StopProfiling("OvalePower_UpdatePowerType")
    end,
    GetSpellCost = function(self, spell, powerType)
        local spellId = self.ovaleSpellBook:getKnownSpellId(spell)
        if spellId then
            local spellPowerCosts = GetSpellPowerCost(spellId)
            local spellPowerCost = spellPowerCosts and spellPowerCosts[1]
            if spellPowerCost then
                local cost = spellPowerCost.cost
                local typeId = spellPowerCost.type
                for pt, p in pairs(self.POWER_INFO) do
                    if p.id == typeId and (powerType == nil or pt == powerType) then
                        return cost, p.type
                    end
                end
            end
        else
            OneTimeMessage("No spell cost for " .. spell)
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
        return self:getTimeToPowerStateAt(self:GetState(atTime), spellId, atTime, targetGUID, powerType, extraPower)
    end,
    InitializeState = function(self)
        for powerType in kpairs(self.POWER_INFO) do
            self.next.power[powerType] = 0
            self.next.inactiveRegen[powerType], self.next.activeRegen[powerType] = 0, 0
        end
    end,
    ResetState = function(self)
        self.profiler:StartProfiling("OvalePower_ResetState")
        for powerType in kpairs(self.POWER_INFO) do
            self.next.power[powerType] = self.current.power[powerType] or 0
            self.next.maxPower[powerType] = self.current.maxPower[powerType] or 0
            self.next.activeRegen[powerType] = self.current.activeRegen[powerType] or 0
            self.next.inactiveRegen[powerType] = self.current.inactiveRegen[powerType] or 0
        end
        self.profiler:StopProfiling("OvalePower_ResetState")
    end,
    CleanState = function(self)
        for powerType in kpairs(self.POWER_INFO) do
            self.next.power[powerType] = nil
        end
    end,
    ApplySpellStartCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        self.profiler:StartProfiling("OvalePower_ApplySpellStartCast")
        if isChanneled then
            self:ApplyPowerCost(spellId, targetGUID, startCast, spellcast)
        end
        self.profiler:StopProfiling("OvalePower_ApplySpellStartCast")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        self.profiler:StartProfiling("OvalePower_ApplySpellAfterCast")
        if  not isChanneled then
            self:ApplyPowerCost(spellId, targetGUID, endCast, spellcast)
        end
        self.profiler:StopProfiling("OvalePower_ApplySpellAfterCast")
    end,
    ApplyPowerCost = function(self, spellId, targetGUID, atTime, spellcast)
        self.profiler:StartProfiling("OvalePower_state_ApplyPowerCost")
        local si = self.ovaleData.spellInfo[spellId]
        do
            local cost, powerType = self:GetSpellCost(spellId)
            if cost and powerType and self.next.power[powerType] and  not (si and si[powerType]) then
                local power = self.next.power[powerType]
                if power then
                    self.next.power[powerType] = power - cost
                end
            end
        end
        if si then
            for powerType, powerInfo in kpairs(self.POWER_INFO) do
                local cost, refund = self:getPowerCostAt(self.next, spellId, powerInfo.type, atTime, targetGUID)
                local power = self.next.power[powerType] or 0
                if cost then
                    power = power - cost
                end
                if refund then
                    power = power + refund
                end
                local seconds = self.ovaleFuture.next.nextCast - atTime
                if seconds > 0 then
                    local powerRate = self:getPowerRateAt(self.next, powerType, atTime) or 0
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
        self.profiler:StopProfiling("OvalePower_state_ApplyPowerCost")
    end,
    PowerCost = function(self, spellId, powerType, atTime, targetGUID, maximumCost)
        return self:getPowerCostAt(self:GetState(atTime), spellId, powerType, atTime, targetGUID, maximumCost)
    end,
    getPowerRateAt = function(self, state, powerType, atTime)
        if self.combat:isInCombat(atTime) then
            return state.activeRegen[powerType]
        else
            return state.inactiveRegen[powerType]
        end
    end,
    getPowerAt = function(self, state, powerType, atTime)
        local power = state.power[powerType] or 0
        if atTime then
            local now = self.baseState.next.currentTime
            local seconds = atTime - now
            if seconds > 0 then
                local powerRate = self:getPowerRateAt(state, powerType, atTime) or 0
                power = power + powerRate * seconds
            end
        end
        return power
    end,
    getPowerCostAt = function(self, state, spellId, powerType, atTime, targetGUID, maximumCost)
        self.profiler:StartProfiling("OvalePower_PowerCost")
        local spellCost = 0
        local spellRefund = 0
        local si = self.ovaleData.spellInfo[spellId]
        if si and si[powerType] then
            local cost, ratio = self.ovaleData:GetSpellInfoPropertyNumber(spellId, atTime, powerType, targetGUID, true)
            if ratio and ratio ~= 0 then
                local addRequirements = si and si.require and si.require["add_" .. powerType .. "_from_aura"]
                if addRequirements then
                    for v, rArray in pairs(addRequirements) do
                        if isLuaArray(rArray) then
                            for _, requirement in ipairs(rArray) do
                                local verified = self.requirement:CheckRequirements(spellId, atTime, requirement, 1, targetGUID)
                                if verified then
                                    local aura = self.ovaleAura:GetAura("player", requirement[2], atTime, nil, true)
                                    if aura and self.ovaleAura:IsActiveAura(aura, atTime) then
                                        cost = cost + (tonumber(v) or 0) * aura.stacks
                                    end
                                end
                            end
                        end
                    end
                end
                local maxCostParam = "max_" .. powerType
                local maxCost = si[maxCostParam]
                if maxCost then
                    local power = self:getPowerAt(state, powerType, atTime)
                    if power > maxCost or maximumCost then
                        cost = maxCost
                    elseif power > cost then
                        cost = power
                    end
                end
                spellCost = (cost > 0 and floor(cost * ratio)) or ceil(cost * ratio)
                local refund = si["refund_" .. powerType] or 0
                if refund == "cost" then
                    spellRefund = spellCost
                else
                    local refundRequirements = si and si.require["refund_" .. powerType]
                    if refundRequirements then
                        for v, rArray in pairs(refundRequirements) do
                            if isLuaArray(rArray) then
                                for _, requirement in ipairs(rArray) do
                                    local verified = self.requirement:CheckRequirements(spellId, atTime, requirement, 1, targetGUID)
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
                end
            end
        else
            local cost = self:GetSpellCost(spellId, powerType)
            if cost then
                spellCost = cost
            end
        end
        self.profiler:StopProfiling("OvalePower_PowerCost")
        return spellCost, spellRefund
    end,
    getPowerRequirementAt = function(self, state, spellId, atTime, requirement, tokens, index, targetGUID)
        local verified = false
        local baseCost = tokens[index]
        index = index + 1
        if baseCost then
            if baseCost > 0 then
                local powerType = requirement
                local cost = self:getPowerCostAt(state, spellId, powerType, atTime, targetGUID)
                if cost > 0 then
                    local power = self:getPowerAt(state, powerType, atTime)
                    if power >= cost then
                        verified = true
                    end
                    self.tracer:Log("   Has power %f %s", power, powerType)
                else
                    verified = true
                end
                if cost > 0 then
                    local result = (verified and "passed") or "FAILED"
                    self.tracer:Log("    Require %f %s at time=%f: %s", cost, powerType, atTime, result)
                end
            else
                verified = true
            end
        else
            OneTimeMessage("Warning: requirement '%s' power is missing a cost argument.", requirement)
            OneTimeMessage(tostring(index))
            if isLuaArray(tokens) then
                for k, v in pairs(tokens) do
                    OneTimeMessage(k .. " = " .. tostring(v))
                end
            end
        end
        return verified, requirement, index
    end,
    getTimeToPowerStateAt = function(self, state, spellId, atTime, targetGUID, powerType, extraPower)
        local seconds = 0
        powerType = powerType or __exports.POOLED_RESOURCE[self.ovalePaperDoll.class]
        if powerType then
            local cost = self:getPowerCostAt(state, spellId, powerType, atTime, targetGUID)
            if cost > 0 then
                local power = self:getPowerAt(state, powerType, atTime)
                if extraPower then
                    cost = cost + extraPower
                end
                if power < cost then
                    local powerRate = self:getPowerRateAt(state, powerType, atTime) or 0
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
})
