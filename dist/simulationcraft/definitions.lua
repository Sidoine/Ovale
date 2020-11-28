local __exports = LibStub:NewLibrary("ovale/simulationcraft/definitions", 90000)
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
    ["strict_sequence"] = true,
    ["swap_action_list"] = true,
    ["use_items"] = true,
    ["use_item"] = true,
    ["variable"] = true,
    ["wait"] = true
}
local powerModifiers = {
    ["max"] = {
        type = 1
    },
    ["deficit"] = {
        type = 0
    },
    ["pct"] = {
        name = "percent",
        type = 0
    },
    ["regen"] = {
        name = "regenrate",
        type = 0
    },
    ["time_to_50"] = {
        name = "timeto",
        type = 1,
        extraParameter = 50
    },
    ["time_to_max"] = {
        name = "timetomax",
        type = 1
    }
}
__exports.MISC_OPERAND = {
    ["active_enemies"] = {
        name = "enemies"
    },
    ["active_bt_triggers"] = {
        name = "buffcount",
        extraSymbol = "bt_buffs"
    },
    ["animacharged_cp"] = {
        name = "maxcombopoints"
    },
    ["astral_power"] = {
        name = "astralpower",
        modifiers = powerModifiers
    },
    ["ca_active"] = {
        code = "talent(careful_aim_talent) and targethealthpercent() > 70",
        symbolsInCode = {
            [1] = "careful_aim_talent"
        }
    },
    ["chi"] = {
        name = "chi",
        modifiers = powerModifiers
    },
    ["combo_points"] = {
        name = "combopoints",
        modifiers = powerModifiers
    },
    ["conduit"] = {
        symbol = "conduit",
        modifiers = {
            enabled = {
                type = 3
            },
            rank = {
                type = 0
            }
        }
    },
    ["consecration"] = {
        name = "buff",
        modifiers = {
            up = {
                type = 0,
                name = "present"
            }
        },
        extraSymbol = "consecration"
    },
    ["covenant"] = {
        name = "iscovenant",
        modifiers = {
            enabled = {
                type = 3
            }
        },
        symbol = ""
    },
    ["cp_max_spend"] = {
        name = "maxcombopoints"
    },
    ["death_knight"] = {
        symbol = "enchant",
        name = "checkboxon",
        modifiers = {
            runeforge = {
                type = 4,
                name = "weaponenchantpresent"
            },
            disable_aotd = {
                type = 2,
                name = "disable_aotd",
                createOptions = true
            },
            fwounded_targets = {
                type = 4,
                code = "buffcountonany",
                extraSymbol = "festering_wound_debuff"
            }
        }
    },
    ["death_and_decay"] = {
        modifiers = {
            ticking = {
                type = 4,
                name = "buffpresent"
            }
        },
        extraSymbol = "death_and_decay"
    },
    ["demon_soul_fragments"] = {
        name = "soulfragments"
    },
    ["desired_targets"] = {
        name = "enemies",
        extraNamedParameter = {
            name = "tagged",
            value = 1
        }
    },
    ["druid"] = {
        name = "checkboxon",
        modifiers = {
            catweave_bear = {
                type = 2,
                createOptions = true
            },
            owlweave_bear = {
                type = 2,
                createOptions = true
            },
            ticks_gained_on_refresh = {
                type = 4,
                name = "ticksgainedonrefresh"
            }
        },
        symbol = ""
    },
    ["eclipse"] = {
        modifiers = {
            in_lunar = {
                type = 4,
                name = "buffpresent",
                extraSymbol = "eclipse_lunar"
            },
            in_solar = {
                type = 4,
                name = "buffpresent",
                extraSymbol = "eclipse_solar"
            },
            solar_in_1 = {
                type = 5,
                code = "counter(solar) == 1"
            },
            solar_next = {
                type = 5,
                code = "counter(solar) == 1"
            },
            lunar_in_1 = {
                type = 4,
                code = "counter(lunar) == 1"
            },
            lunar_next = {
                type = 4,
                code = "counter(lunar) == 1"
            },
            any_next = {
                type = 5,
                code = "counter(lunar) + counter(solar) == 1"
            },
            in_any = {
                type = 4,
                name = "buffpresent",
                extraSymbol = "eclipse_any"
            },
            in_both = {
                type = 5,
                code = "buffpresent(eclipse_solar) and buffpresent(eclipse_lunar)",
                symbolsInCode = {
                    [1] = "eclipse_solar",
                    [2] = "eclipse_lunar"
                }
            }
        }
    },
    ["energy"] = {
        name = "energy",
        modifiers = powerModifiers
    },
    ["expected_combat_length"] = {
        name = "expectedcombatlength"
    },
    ["exsanguinated"] = {
        name = "targetdebuffremaining",
        symbol = "exsanguinated"
    },
    ["fight_remains"] = {
        name = "fightremains"
    },
    ["firestarter"] = {
        modifiers = {
            remains = {
                type = 4,
                name = "TargetTimeToHealthPercent",
                extraParameter = 90
            }
        }
    },
    ["focus"] = {
        name = "focus",
        modifiers = powerModifiers
    },
    ["fury"] = {
        name = "fury",
        modifiers = powerModifiers
    },
    ["health"] = {
        modifiers = {
            max = {
                type = 1
            }
        }
    },
    ["holy_power"] = {
        name = "holypower",
        modifiers = powerModifiers
    },
    ["incoming_imps"] = {
        name = "impsspawnedduring"
    },
    ["hot_streak_spells_in_flight"] = {
        name = "inflighttotarget",
        extraSymbol = "hot_streak"
    },
    ["interpolated_fight_remains"] = {
        name = "fightremains"
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
    ["next_wi_bomb"] = {
        name = "buffpresent",
        symbol = "bomb"
    },
    ["pain"] = {
        name = "pain",
        modifiers = powerModifiers
    },
    ["priest"] = {
        name = "checkboxon",
        modifiers = {
            self_power_infusion = {
                type = 2,
                createOptions = true
            }
        }
    },
    ["rage"] = {
        name = "rage",
        modifiers = powerModifiers
    },
    ["remaining_winters_chill"] = {
        name = "buffstacks",
        extraSymbol = "winters_chill"
    },
    ["rune"] = {
        name = "rune",
        modifiers = powerModifiers
    },
    ["runeforge"] = {
        modifiers = {
            equipped = {
                type = 1
            }
        },
        symbol = "runeforge"
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
    ["soulbind"] = {
        modifiers = {
            enabled = {
                type = 1
            }
        },
        symbol = "soulbind"
    },
    ["stagger"] = {
        modifiers = {
            last_tick_damage_4 = {
                name = "tick",
                type = 0
            },
            pct = {
                name = "percent",
                type = 0
            },
            amounttototalpct = {
                name = "missingpercent",
                type = 0
            }
        }
    },
    ["stealthed"] = {
        name = "buffpresent",
        modifiers = {
            all = {
                name = "stealthed_buff",
                type = 6
            },
            rogue = {
                type = 6,
                name = "rogue_stealthed_buff"
            },
            mantle = {
                name = "mantle_stealthed_buff",
                type = 6
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
        self.functionTag = {}
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
