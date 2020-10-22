local __exports = LibStub:NewLibrary("ovale/simulationcraft/definitions", 80300)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local pairs = pairs
local ipairs = ipairs
local kpairs = pairs
__exports.interruptsClasses = {
    mind_freeze = "DEATHKNIGHT",
    pummel = "WARRIOR",
    disrupt = "DEMONHUNTER",
    skull_bash = "DRUID",
    solar_beam = "DRUID",
    rebuke = "PALADIN",
    silence = "PRIEST",
    mind_bomb = "PRIEST",
    kick = "ROGUE",
    wind_shear = "SHAMAN",
    counter_shot = "HUNTER",
    counterspell = "MAGE",
    muzzle = "HUNTER",
    spear_hand_strike = "MONK"
}
__exports.classInfos = {
    DEATHKNIGHT = {
        frost = {
            interrupt = "mind_freeze"
        },
        blood = {
            interrupt = "mind_freeze"
        },
        unholy = {
            interrupt = "mind_freeze"
        }
    },
    DEMONHUNTER = {
        havoc = {
            interrupt = "disrupt"
        },
        vengeance = {
            interrupt = "disrupt"
        }
    },
    DRUID = {
        guardian = {
            interrupt = "skull_bash"
        },
        feral = {
            interrupt = "skull_bash"
        },
        balance = {
            interrupt = "solar_beam"
        }
    },
    HUNTER = {
        beast_mastery = {
            interrupt = "counter_shot"
        },
        survival = {
            interrupt = "muzzle"
        },
        marksmanship = {
            interrupt = "counter_shot"
        }
    },
    MAGE = {
        frost = {
            interrupt = "counterspell"
        },
        fire = {
            interrupt = "counterspell"
        },
        arcane = {
            interrupt = "counterspell"
        }
    },
    MONK = {
        brewmaster = {
            interrupt = "spear_hand_strike"
        },
        windwalker = {
            interrupt = "spear_hand_strike"
        }
    },
    PALADIN = {
        retribution = {
            interrupt = "rebuke"
        },
        protection = {
            interrupt = "rebuke"
        }
    },
    PRIEST = {
        shadow = {
            interrupt = "silence"
        }
    },
    ROGUE = {
        assassination = {
            interrupt = "kick"
        },
        outlaw = {
            interrupt = "kick"
        },
        subtlety = {
            interrupt = "kick"
        }
    },
    SHAMAN = {
        elemental = {
            interrupt = "wind_shear"
        },
        enhancement = {
            interrupt = "wind_shear"
        }
    },
    WARLOCK = {},
    WARRIOR = {
        fury = {
            interrupt = "pummel"
        },
        protection = {
            interrupt = "pummel"
        },
        arms = {
            interrupt = "pummel"
        }
    }
}
__exports.CHARACTER_PROPERTY = {}
__exports.KEYWORD = {}
__exports.MODIFIER_KEYWORD = {
    ["ammo_type"] = true,
    ["animation_cancel"] = true,
    ["attack_speed"] = true,
    ["cancel_if"] = true,
    ["chain"] = true,
    ["choose"] = true,
    ["condition"] = true,
    ["cooldown"] = true,
    ["cooldown_stddev"] = true,
    ["cycle_targets"] = true,
    ["damage"] = true,
    ["delay"] = true,
    default = true,
    ["dynamic_prepot"] = true,
    ["early_chain_if"] = true,
    ["effect_name"] = true,
    ["extra_amount"] = true,
    ["five_stacks"] = true,
    ["for_next"] = true,
    ["if"] = true,
    ["interrupt"] = true,
    ["interrupt_global"] = true,
    ["interrupt_if"] = true,
    ["interrupt_immediate"] = true,
    ["interval"] = true,
    ["lethal"] = true,
    ["line_cd"] = true,
    ["max_cycle_targets"] = true,
    ["max_energy"] = true,
    ["min_frenzy"] = true,
    ["moving"] = true,
    ["name"] = true,
    ["nonlethal"] = true,
    ["op"] = true,
    only_cwc = true,
    ["pct_health"] = true,
    ["precombat"] = true,
    ["precombat_seconds"] = true,
    precombat_time = true,
    ["precast_time"] = true,
    ["range"] = true,
    ["sec"] = true,
    ["slot"] = true,
    ["slots"] = true,
    ["strikes"] = true,
    ["sync"] = true,
    ["sync_weapons"] = true,
    ["target"] = true,
    ["target_if"] = true,
    ["target_if_first"] = true,
    ["target_if_max"] = true,
    ["target_if_min"] = true,
    ["toggle"] = true,
    ["travel_speed"] = true,
    ["type"] = true,
    ["use_off_gcd"] = true,
    ["use_while_casting"] = true,
    ["value"] = true,
    ["value_else"] = true,
    ["wait"] = true,
    ["wait_on_ready"] = true,
    ["weapon"] = true
}
__exports.LITTERAL_MODIFIER = {
    ["name"] = true
}
__exports.FUNCTION_KEYWORD = {
    ["ceil"] = true,
    ["floor"] = true
}
__exports.SPECIAL_ACTION = {
    ["apply_poison"] = true,
    ["auto_attack"] = true,
    ["call_action_list"] = true,
    ["cancel_buff"] = true,
    ["cancel_metamorphosis"] = true,
    ["cycling_variable"] = true,
    ["exotic_munitions"] = true,
    ["flask"] = true,
    ["food"] = true,
    ["health_stone"] = true,
    ["pool_resource"] = true,
    ["potion"] = true,
    ["run_action_list"] = true,
    ["sequence"] = true,
    ["snapshot_stats"] = true,
    ["stance"] = true,
    ["start_moving"] = true,
    ["stealth"] = true,
    ["stop_moving"] = true,
    ["swap_action_list"] = true,
    ["use_items"] = true,
    ["use_item"] = true,
    ["variable"] = true,
    ["wait"] = true
}
local powerModifiers = {
    ["max"] = {
        name = "max",
        before = true
    },
    ["deficit"] = {
        name = "deficit"
    },
    ["pct"] = {
        name = "percent"
    }
}
__exports.MISC_OPERAND = {
    ["active_enemies"] = {
        name = "enemies"
    },
    ["astral_power"] = {
        name = "astralpower",
        modifiers = powerModifiers
    },
    ["chi"] = {
        name = "chi",
        modifiers = powerModifiers
    },
    ["combo_points"] = {
        name = "combopoints",
        modifiers = powerModifiers
    },
    ["cp_max_spend"] = {
        name = "maxcombopoints"
    },
    ["energy"] = {
        name = "energy",
        modifiers = powerModifiers
    },
    ["expected_combat_length"] = {
        name = "expectedcombatlength"
    },
    ["holy_power"] = {
        name = "holypower",
        modifiers = powerModifiers
    },
    ["fight_remains"] = {
        name = "fightremains"
    },
    ["focus"] = {
        name = "focus",
        modifiers = powerModifiers
    },
    ["fury"] = {
        name = "fury",
        modifiers = powerModifiers
    },
    ["insanity"] = {
        name = "insanity",
        modifiers = powerModifiers
    },
    ["level"] = {
        name = "level"
    },
    ["maelstrom"] = {
        name = "maelstrom",
        modifiers = powerModifiers
    },
    ["mana"] = {
        name = "mana",
        modifiers = powerModifiers
    },
    ["pain"] = {
        name = "pain",
        modifiers = powerModifiers
    },
    ["rage"] = {
        name = "rage",
        modifiers = powerModifiers
    },
    ["rune"] = {
        name = "rune",
        modifiers = powerModifiers
    },
    ["runic_power"] = {
        name = "runicpower",
        modifiers = powerModifiers
    },
    ["soul_fragments"] = {
        name = "soulfragments",
        modifiers = powerModifiers
    },
    ["soul_shard"] = {
        name = "soulshards",
        modifiers = powerModifiers
    },
    ["stealthed"] = {
        name = "stealthed",
        modifiers = {
            all = {
                name = ""
            },
            rogue = {
                name = ""
            }
        }
    },
    ["time"] = {
        name = "timeincombat"
    },
    ["time_to_shard"] = {
        name = "timetoshard"
    }
}
__exports.RUNE_OPERAND = {
    ["rune"] = "rune"
}
__exports.CONSUMABLE_ITEMS = {
    ["potion"] = true,
    ["food"] = true,
    ["flask"] = true,
    ["augmentation"] = true
}
do
    for keyword, value in kpairs(__exports.MODIFIER_KEYWORD) do
        __exports.KEYWORD[keyword] = value
    end
    for keyword, value in pairs(__exports.FUNCTION_KEYWORD) do
        __exports.KEYWORD[keyword] = value
    end
    for keyword, value in pairs(__exports.SPECIAL_ACTION) do
        __exports.KEYWORD[keyword] = value
    end
end
__exports.UNARY_OPERATOR = {
    ["!"] = {
        [1] = "logical",
        [2] = 15
    },
    ["-"] = {
        [1] = "arithmetic",
        [2] = 50
    },
    ["@"] = {
        [1] = "arithmetic",
        [2] = 50
    }
}
__exports.BINARY_OPERATOR = {
    ["|"] = {
        [1] = "logical",
        [2] = 5,
        [3] = "associative"
    },
    ["^"] = {
        [1] = "logical",
        [2] = 8,
        [3] = "associative"
    },
    ["&"] = {
        [1] = "logical",
        [2] = 10,
        [3] = "associative"
    },
    ["!="] = {
        [1] = "compare",
        [2] = 20
    },
    ["<"] = {
        [1] = "compare",
        [2] = 20
    },
    ["<="] = {
        [1] = "compare",
        [2] = 20
    },
    ["="] = {
        [1] = "compare",
        [2] = 20
    },
    ["=="] = {
        [1] = "compare",
        [2] = 20
    },
    [">"] = {
        [1] = "compare",
        [2] = 20
    },
    [">="] = {
        [1] = "compare",
        [2] = 20
    },
    ["~"] = {
        [1] = "compare",
        [2] = 20
    },
    ["!~"] = {
        [1] = "compare",
        [2] = 20
    },
    ["+"] = {
        [1] = "arithmetic",
        [2] = 30,
        [3] = "associative"
    },
    ["-"] = {
        [1] = "arithmetic",
        [2] = 30
    },
    ["%"] = {
        [1] = "arithmetic",
        [2] = 40
    },
    ["*"] = {
        [1] = "arithmetic",
        [2] = 40,
        [3] = "associative"
    },
    [">?"] = {
        [1] = "arithmetic",
        [2] = 25,
        [3] = "associative"
    },
    ["<?"] = {
        [1] = "arithmetic",
        [2] = 25,
        [3] = "associative"
    },
    ["%%"] = {
        [1] = "arithmetic",
        [2] = 40
    }
}
__exports.OPTIONAL_SKILLS = {
    ["fel_rush"] = {
        class = "DEMONHUNTER",
        default = true
    },
    ["vengeful_retreat"] = {
        class = "DEMONHUNTER",
        default = true
    },
    ["volley"] = {
        class = "HUNTER",
        default = true
    },
    ["harpoon"] = {
        class = "HUNTER",
        specialization = "survival",
        default = true
    },
    ["blink"] = {
        class = "MAGE",
        default = false
    },
    ["time_warp"] = {
        class = "MAGE"
    },
    ["storm_earth_and_fire"] = {
        class = "MONK",
        default = true
    },
    ["chi_burst"] = {
        class = "MONK",
        default = true
    },
    ["touch_of_karma"] = {
        class = "MONK",
        default = false
    },
    ["flying_serpent_kick"] = {
        class = "MONK",
        default = true
    },
    ["vanish"] = {
        class = "ROGUE",
        specialization = "assassination",
        default = true
    },
    ["blade_flurry"] = {
        class = "ROGUE",
        specialization = "outlaw",
        default = true
    },
    ["bloodlust"] = {
        class = "SHAMAN"
    },
    ["shield_of_vengeance"] = {
        class = "PALADIN",
        specialization = "retribution",
        default = false
    }
}
__exports.checkOptionalSkill = function(action, className, specialization)
    local data = __exports.OPTIONAL_SKILLS[action]
    if  not data then
        return false
    end
    if data.specialization and data.specialization ~= specialization then
        return false
    end
    if data.class and data.class ~= className then
        return false
    end
    return true
end
__exports.Annotation = __class(nil, {
    constructor = function(self, ovaleData, name, classId, specialization)
        self.ovaleData = ovaleData
        self.name = name
        self.classId = classId
        self.specialization = specialization
        self.consumables = {}
        self.taggedFunctionName = {}
        self.dictionary = {}
        self.variable = {}
        self.symbolList = {}
        self.astAnnotation = {
            nodeList = {},
            definition = self.dictionary
        }
    end,
    AddSymbol = function(self, symbol)
        local symbolTable = self.symbolTable or {}
        local symbolList = self.symbolList
        if  not symbolTable[symbol] and  not self.ovaleData.DEFAULT_SPELL_LIST[symbol] then
            symbolTable[symbol] = true
            symbolList[#symbolList + 1] = symbol
        end
        self.symbolTable = symbolTable
        self.symbolList = symbolList
    end,
})
__exports.OVALE_TAGS = {
    [1] = "main",
    [2] = "shortcd",
    [3] = "cd"
}
local OVALE_TAG_PRIORITY = {}
for i, tag in ipairs(__exports.OVALE_TAGS) do
    OVALE_TAG_PRIORITY[tag] = i * 10
end
__exports.TagPriority = function(tag)
    return OVALE_TAG_PRIORITY[tag] or 10
end
