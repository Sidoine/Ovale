local __exports = LibStub:NewLibrary("ovale/Data", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local type = type
local ipairs = ipairs
local pairs = pairs
local wipe = wipe
local find = string.find
local __tools = LibStub:GetLibrary("ovale/tools")
local isNumber = __tools.isNumber
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
    [7] = "spirit",
    [8] = "spellpower",
    [9] = "strength",
    [10] = "versatility"
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
__exports.OvaleDataClass = __class(nil, {
    constructor = function(self, runner)
        self.runner = runner
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
                [1856] = true,
                [58984] = true,
                [102543] = true,
                [115192] = true,
                [115193] = true,
                [185313] = true
            },
            rogue_stealthed_buff = {
                [1784] = true,
                [1856] = true,
                [185313] = true,
                [115192] = true
            },
            mantle_stealthed_buff = {
                [1784] = true,
                [1856] = true
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
            },
            roll_the_bones_buff = {
                [193356] = true,
                [199600] = true,
                [193358] = true,
                [193357] = true,
                [199603] = true,
                [193359] = true
            }
        }
        self.DEFAULT_SPELL_LIST = {}
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
                    player = {
                        HELPFUL = {},
                        HARMFUL = {}
                    },
                    target = {
                        HELPFUL = {},
                        HARMFUL = {}
                    },
                    pet = {
                        HELPFUL = {},
                        HARMFUL = {}
                    },
                    damage = {
                        HELPFUL = {},
                        HARMFUL = {}
                    }
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
        local _, named = self.runner:computeParameters(spellData, atTime)
        return named
    end,
    GetItemInfoProperty = function(self, itemId, atTime, property)
        local ii = self:ItemInfo(itemId)
        if ii then
            return self:getSpellInfoProperty(ii, atTime, property)
        end
        return nil
    end,
    GetSpellInfoProperty = function(self, spellId, atTime, property, targetGUID)
        local si = self.spellInfo[spellId]
        if si then
            return self:getSpellInfoProperty(si, atTime, property)
        end
        return nil
    end,
    getSpellInfoProperty = function(self, si, atTime, property)
        local value = si[property]
        if atTime then
            local requirements = si.require[property]
            if requirements then
                for _, requirement in ipairs(requirements) do
                    local _, named = self.runner:computeParameters(requirement, atTime)
                    if named.enabled == nil or named.enabled then
                        if named.set ~= nil then
                            value = named.set
                        end
                        if named.add ~= nil and isNumber(value) and isNumber(named.add) then
                            value = (value + named.add)
                        end
                        if named.percent ~= nil and isNumber(value) and isNumber(named.percent) then
                            value = ((value * named.percent) / 100)
                        end
                    end
                end
            end
        end
        return value
    end,
    GetSpellInfoPropertyNumber = function(self, spellId, atTime, property, targetGUID, splitRatio)
        local si = self.spellInfo[spellId]
        if  not si then
            return 
        end
        local ratioParam = property .. "_percent"
        local ratio = self:getSpellInfoProperty(si, atTime, ratioParam)
        if ratio ~= nil then
            ratio = ratio / 100
        else
            ratio = 1
        end
        local value = self:getSpellInfoProperty(si, atTime, property)
        if ratio ~= 0 and value ~= nil then
            local addParam = "add_" .. property
            local addProperty = self:getSpellInfoProperty(si, atTime, addParam)
            if addProperty then
                value = value + addProperty
            end
        else
            value = 0
        end
        if splitRatio then
            return value, ratio
        end
        return value * ratio
    end,
    GetDamage = function(self, spellId, attackpower, spellpower, mainHandWeaponDPS, offHandWeaponDPS, combopoints)
        local si = self.spellInfo[spellId]
        if  not si then
            return nil
        end
        local damage = si.base or 0
        attackpower = attackpower or 0
        spellpower = spellpower or 0
        mainHandWeaponDPS = mainHandWeaponDPS or 0
        offHandWeaponDPS = offHandWeaponDPS or 0
        combopoints = combopoints or 0
        if si.bonusmainhand then
            damage = damage + si.bonusmainhand * mainHandWeaponDPS
        end
        if si.bonusoffhand then
            damage = damage + si.bonusoffhand * offHandWeaponDPS
        end
        if si.bonuscp then
            damage = damage + si.bonuscp * combopoints
        end
        if si.bonusap then
            damage = damage + si.bonusap * attackpower
        end
        if si.bonusapcp then
            damage = damage + si.bonusapcp * attackpower * combopoints
        end
        if si.bonussp then
            damage = damage + si.bonussp * spellpower
        end
        return damage
    end,
})
