local __exports = LibStub:NewLibrary("ovale/Data", 10000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local __GUID = LibStub:GetLibrary("ovale/GUID")
local OvaleGUID = __GUID.OvaleGUID
local __PaperDoll = LibStub:GetLibrary("ovale/PaperDoll")
local OvalePaperDoll = __PaperDoll.OvalePaperDoll
local __State = LibStub:GetLibrary("ovale/State")
local baseState = __State.baseState
local __Debug = LibStub:GetLibrary("ovale/Debug")
local OvaleDebug = __Debug.OvaleDebug
local __Requirement = LibStub:GetLibrary("ovale/Requirement")
local self_requirement = __Requirement.self_requirement
local CheckRequirements = __Requirement.CheckRequirements
local type = type
local pairs = pairs
local tonumber = tonumber
local wipe = wipe
local find = string.find
local huge = math.huge
local floor = math.floor
local ceil = math.ceil
local OvaleDataBase = OvaleDebug:RegisterDebugging(Ovale:NewModule("OvaleData"))
local INFINITY = huge
local BLOODELF_CLASSES = {
    ["DEATHKNIGHT"] = true,
    ["DEMONHUNTER"] = true,
    ["DRUID"] = false,
    ["HUNTER"] = true,
    ["MAGE"] = true,
    ["MONK"] = true,
    ["PALADIN"] = true,
    ["PRIEST"] = true,
    ["ROGUE"] = true,
    ["SHAMAN"] = false,
    ["WARLOCK"] = true,
    ["WARRIOR"] = true
}
local PANDAREN_CLASSES = {
    ["DEATHKNIGHT"] = false,
    ["DEMONHUNTER"] = false,
    ["DRUID"] = false,
    ["HUNTER"] = true,
    ["MAGE"] = true,
    ["MONK"] = true,
    ["PALADIN"] = false,
    ["PRIEST"] = true,
    ["ROGUE"] = true,
    ["SHAMAN"] = true,
    ["WARLOCK"] = false,
    ["WARRIOR"] = true
}
local TAUREN_CLASSES = {
    ["DEATHKNIGHT"] = true,
    ["DEMONHUNTER"] = false,
    ["DRUID"] = true,
    ["HUNTER"] = true,
    ["MAGE"] = false,
    ["MONK"] = true,
    ["PALADIN"] = true,
    ["PRIEST"] = true,
    ["ROGUE"] = false,
    ["SHAMAN"] = true,
    ["WARLOCK"] = false,
    ["WARRIOR"] = true
}
local STAT_NAMES = {
    [1] = "agility",
    [2] = "bonus_armor",
    [3] = "critical_strike",
    [4] = "haste",
    [5] = "intellect",
    [6] = "mastery",
    [7] = "multistrike",
    [8] = "spirit",
    [9] = "spellpower",
    [10] = "strength",
    [11] = "versatility"
}
local STAT_SHORTNAME = {
    agility = "agi",
    critical_strike = "crit",
    intellect = "int",
    strength = "str",
    spirit = "spi"
}
local STAT_USE_NAMES = {
    [1] = "trinket_proc",
    [2] = "trinket_stacking_proc",
    [3] = "trinket_stacking_stat",
    [4] = "trinket_stat",
    [5] = "trinket_stack_proc"
}
local OvaleDataClass = __class(OvaleDataBase, {
    constructor = function(self)
        self.STAT_NAMES = STAT_NAMES
        self.STAT_SHORTNAME = STAT_SHORTNAME
        self.STAT_USE_NAMES = STAT_USE_NAMES
        self.BLOODELF_CLASSES = BLOODELF_CLASSES
        self.PANDAREN_CLASSES = PANDAREN_CLASSES
        self.TAUREN_CLASSES = TAUREN_CLASSES
        self.itemInfo = {}
        self.itemList = {}
        self.spellInfo = {}
        self.buffSpellList = {
            fear_debuff = {
                [5246] = true,
                [5484] = true,
                [5782] = true,
                [8122] = true
            },
            incapacitate_debuff = {
                [6770] = true,
                [12540] = true,
                [20066] = true,
                [137460] = true
            },
            root_debuff = {
                [122] = true,
                [339] = true
            },
            stun_debuff = {
                [408] = true,
                [853] = true,
                [1833] = true,
                [5211] = true,
                [46968] = true
            },
            attack_power_multiplier_buff = {
                [6673] = true,
                [19506] = true,
                [57330] = true
            },
            critical_strike_buff = {
                [1459] = true,
                [24604] = true,
                [24932] = true,
                [61316] = true,
                [90309] = true,
                [90363] = true,
                [97229] = true,
                [116781] = true,
                [126309] = true,
                [126373] = true,
                [128997] = true,
                [160052] = true,
                [160200] = true
            },
            haste_buff = {
                [49868] = true,
                [55610] = true,
                [113742] = true,
                [128432] = true,
                [135678] = true,
                [160003] = true,
                [160074] = true,
                [160203] = true
            },
            mastery_buff = {
                [19740] = true,
                [24907] = true,
                [93435] = true,
                [116956] = true,
                [128997] = true,
                [155522] = true,
                [160073] = true,
                [160198] = true
            },
            multistrike_buff = {
                [24844] = true,
                [34889] = true,
                [49868] = true,
                [57386] = true,
                [58604] = true,
                [109773] = true,
                [113742] = true,
                [166916] = true,
                [172968] = true
            },
            spell_power_multiplier_buff = {
                [1459] = true,
                [61316] = true,
                [90364] = true,
                [109773] = true,
                [126309] = true,
                [128433] = true,
                [160205] = true
            },
            stamina_buff = {
                [469] = true,
                [21562] = true,
                [50256] = true,
                [90364] = true,
                [160003] = true,
                [160014] = true,
                [166928] = true,
                [160199] = true
            },
            str_agi_int_buff = {
                [1126] = true,
                [20217] = true,
                [90363] = true,
                [115921] = true,
                [116781] = true,
                [159988] = true,
                [160017] = true,
                [160077] = true,
                [160206] = true
            },
            versatility_buff = {
                [1126] = true,
                [35290] = true,
                [50518] = true,
                [55610] = true,
                [57386] = true,
                [159735] = true,
                [160045] = true,
                [160077] = true,
                [167187] = true,
                [167188] = true,
                [172967] = true
            },
            bleed_debuff = {
                [1079] = true,
                [16511] = true,
                [33745] = true,
                [77758] = true,
                [113344] = true,
                [115767] = true,
                [122233] = true,
                [154953] = true,
                [155722] = true
            },
            healing_reduced_debuff = {
                [8680] = true,
                [54680] = true,
                [115625] = true,
                [115804] = true
            },
            stealthed_buff = {
                [1784] = true,
                [5215] = true,
                [11327] = true,
                [24450] = true,
                [58984] = true,
                [90328] = true,
                [102543] = true,
                [148523] = true,
                [115191] = true,
                [115192] = true,
                [115193] = true,
                [185422] = true
            },
            burst_haste_buff = {
                [2825] = true,
                [32182] = true,
                [80353] = true,
                [90355] = true
            },
            burst_haste_debuff = {
                [57723] = true,
                [57724] = true,
                [80354] = true,
                [95809] = true
            },
            raid_movement_buff = {
                [106898] = true
            }
        }
        self.DEFAULT_SPELL_LIST = {}
        OvaleDataBase.constructor(self)
        for _, useName in pairs(STAT_USE_NAMES) do
            local name
            for _, statName in pairs(STAT_NAMES) do
                name = useName .. "_" .. statName .. "_buff"
                self.buffSpellList[name] = {}
                local shortName = STAT_SHORTNAME[statName]
                if shortName then
                    name = useName .. "_" .. shortName .. "_buff"
                    self.buffSpellList[name] = {}
                end
            end
            name = useName .. "_any_buff"
            self.buffSpellList[name] = {}
        end
        do
            for name in pairs(self.buffSpellList) do
                self.DEFAULT_SPELL_LIST[name] = true
            end
        end
    end,
    Reset = function(self)
        wipe(self.itemInfo)
        wipe(self.spellInfo)
        for k, v in pairs(self.buffSpellList) do
            if  not self.DEFAULT_SPELL_LIST[k] then
                wipe(v)
                self.buffSpellList[k] = nil
            elseif find(k, "^trinket_") then
                wipe(v)
            end
        end
    end,
    SpellInfo = function(self, spellId)
        local si = self.spellInfo[spellId]
        if  not si then
            si = {
                aura = {
                    player = {},
                    target = {},
                    pet = {},
                    damage = {}
                },
                require = {}
            }
            self.spellInfo[spellId] = si
        end
        return si
    end,
    GetSpellInfo = function(self, spellId)
        if type(spellId) == "number" then
            return self.spellInfo[spellId]
        elseif self.buffSpellList[spellId] then
            for auraId in pairs(self.buffSpellList[spellId]) do
                if self.spellInfo[auraId] then
                    return self.spellInfo[auraId]
                end
            end
        end
    end,
    ItemInfo = function(self, itemId)
        local ii = self.itemInfo[itemId]
        if  not ii then
            ii = {
                require = {}
            }
            self.itemInfo[itemId] = ii
        end
        return ii
    end,
    GetItemTagInfo = function(self, spellId)
        return "cd", false
    end,
    GetSpellTagInfo = function(self, spellId)
        local tag = "main"
        local invokesGCD = true
        local si = self.spellInfo[spellId]
        if si then
            invokesGCD =  not si.gcd or si.gcd > 0
            tag = si.tag
            if  not tag then
                local cd = si.cd
                if cd then
                    if cd > 90 then
                        tag = "cd"
                    elseif cd > 29 or  not invokesGCD then
                        tag = "shortcd"
                    end
                elseif  not invokesGCD then
                    tag = "shortcd"
                end
                si.tag = tag
            end
            tag = tag or "main"
        end
        return tag, invokesGCD
    end,
    CheckSpellAuraData = function(self, auraId, spellData, atTime, guid)
        guid = guid or OvaleGUID:UnitGUID("player")
        local index, value, data
        if type(spellData) == "table" then
            value = spellData[1]
            index = 2
        else
            value = spellData
        end
        if value == "count" then
            local N
            if index then
                N = spellData[index]
                index = index + 1
            end
            if N then
                data = tonumber(N)
            else
                Ovale:OneTimeMessage("Warning: '%d' has '%s' missing final stack count.", auraId, value)
            end
        elseif value == "extend" then
            local seconds
            if index then
                seconds = spellData[index]
                index = index + 1
            end
            if seconds then
                data = tonumber(seconds)
            else
                Ovale:OneTimeMessage("Warning: '%d' has '%s' missing duration.", auraId, value)
            end
        else
            local asNumber = tonumber(value)
            value = asNumber or value
        end
        local verified = true
        if index then
            verified = CheckRequirements(auraId, atTime, spellData, index, guid)
        end
        return verified, value, data
    end,
    CheckSpellInfo = function(self, spellId, atTime, targetGUID)
        targetGUID = targetGUID or OvaleGUID:UnitGUID(baseState.defaultTarget or "target")
        local verified = true
        local requirement
        for name, handler in pairs(self_requirement) do
            local value = self:GetSpellInfoProperty(spellId, atTime, name, targetGUID)
            if value then
                local method, arg = handler[1], handler[2]
                arg = self[method] and self or arg
                local index = (type(value) == "table") and 1 or nil
                verified, requirement = arg[method](arg, spellId, atTime, name, value, index, targetGUID)
                if  not verified then
                    break
                end
            end
        end
        return verified, requirement
    end,
    GetItemInfoProperty = function(self, itemId, atTime, property)
        local targetGUID = OvaleGUID:UnitGUID("player")
        local ii = self:ItemInfo(itemId)
        local value = ii and ii[property]
        local requirements = ii and ii.require[property]
        if requirements then
            for v, requirement in pairs(requirements) do
                local verified = CheckRequirements(itemId, atTime, requirement, 1, targetGUID)
                if verified then
                    value = tonumber(v) or v
                    break
                end
            end
        end
        return value
    end,
    GetSpellInfoProperty = function(self, spellId, atTime, property, targetGUID)
        targetGUID = targetGUID or OvaleGUID:UnitGUID(baseState.defaultTarget or "target")
        local si = self.spellInfo[spellId]
        local value = si and si[property]
        local requirements = si and si.require[property]
        if requirements then
            for v, requirement in pairs(requirements) do
                local verified = CheckRequirements(spellId, atTime, requirement, 1, targetGUID)
                if verified then
                    value = tonumber(v) or v
                    break
                end
            end
        end
        if  not value or  not tonumber(value) then
            return value
        end
        local addpower = si and si["add" .. property]
        if addpower then
            value = value + addpower
        end
        local ratio = si and si[property .. "_percent"]
        if ratio then
            ratio = ratio / 100
        else
            ratio = 1
        end
        local multipliers = si and si.require[property .. "_percent"]
        if multipliers then
            for v, requirement in pairs(multipliers) do
                local verified = CheckRequirements(spellId, atTime, requirement, 1, targetGUID)
                if verified then
                    ratio = ratio * (tonumber(v) or 0) / 100
                end
            end
        end
        local actual = (value > 0 and floor(value * ratio)) or ceil(value * ratio)
        return actual
    end,
    GetDamage = function(self, spellId, attackpower, spellpower, mainHandWeaponDamage, offHandWeaponDamage, combo)
        local si = self.spellInfo[spellId]
        if  not si then
            return nil
        end
        local damage = si.base or 0
        attackpower = attackpower or 0
        spellpower = spellpower or 0
        mainHandWeaponDamage = mainHandWeaponDamage or 0
        offHandWeaponDamage = offHandWeaponDamage or 0
        combo = combo or 0
        if si.bonusmainhand then
            damage = damage + si.bonusmainhand * mainHandWeaponDamage
        end
        if si.bonusoffhand then
            damage = damage + si.bonusoffhand * offHandWeaponDamage
        end
        if si.bonuscp then
            damage = damage + si.bonuscp * combo
        end
        if si.bonusap then
            damage = damage + si.bonusap * attackpower
        end
        if si.bonusapcp then
            damage = damage + si.bonusapcp * attackpower * combo
        end
        if si.bonussp then
            damage = damage + si.bonussp * spellpower
        end
        return damage
    end,
    GetBaseDuration = function(self, auraId, spellcast)
        spellcast = spellcast or OvalePaperDoll
        local combo = spellcast.combo or 0
        local holy = spellcast.holy or 0
        local duration = INFINITY
        local si = self.spellInfo[auraId]
        if si and si.duration then
            duration = si.duration
            if si.addduration then
                duration = duration + si.addduration
            end
            if si.adddurationcp and combo then
                duration = duration + si.adddurationcp * combo
            end
            if si.adddurationholy and holy then
                duration = duration + si.adddurationholy * (holy - 1)
            end
        end
        if si and si.haste and spellcast then
            local hasteMultiplier = OvalePaperDoll:GetHasteMultiplier(si.haste, spellcast)
            duration = duration / hasteMultiplier
        end
        return duration
    end,
    GetTickLength = function(self, auraId, snapshot)
        local tick = 3
        local si = self.spellInfo[auraId]
        if si then
            tick = si.tick or tick
            local hasteMultiplier = OvalePaperDoll:GetHasteMultiplier(si.haste, snapshot)
            tick = tick / hasteMultiplier
        end
        return tick
    end,
})
__exports.OvaleData = OvaleDataClass()
