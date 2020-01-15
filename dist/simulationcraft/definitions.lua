local __exports = LibStub:NewLibrary("ovale/simulationcraft/definitions", 80201)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local pairs = pairs
local ipairs = ipairs
local kpairs = pairs
__exports.interruptsClasses = {
    ["mind_freeze"] = "DEATHKNIGHT",
    ["pummel"] = "WARRIOR",
    ["disrupt"] = "DEMONHUNTER",
    ["skull_bash"] = "DRUID",
    ["solar_beam"] = "DRUID",
    ["rebuke"] = "PALADIN",
    ["silence"] = "PRIEST",
    ["mind_bomb"] = "PRIEST",
    ["kick"] = "ROGUE",
    ["wind_shear"] = "SHAMAN",
    ["counter_shot"] = "HUNTER",
    ["counterspell"] = "MAGE",
    ["muzzle"] = "HUNTER",
    ["spear_hand_strike"] = "MONK"
}
__exports.classInfos = {
    DEATHKNIGHT = {
        ["frost"] = {
            interrupt = "mind_freeze"
        },
        ["blood"] = {
            interrupt = "mind_freeze"
        },
        ["unholy"] = {
            interrupt = "mind_freeze"
        }
    },
    DEMONHUNTER = {
        ["havoc"] = {
            interrupt = "disrupt"
        },
        ["vengeance"] = {
            interrupt = "disrupt"
        }
    },
    DRUID = {
        ["guardian"] = {
            interrupt = "skull_bash"
        },
        ["feral"] = {
            interrupt = "skull_bash"
        },
        ["balance"] = {
            interrupt = "solar_beam"
        }
    },
    HUNTER = {
        ["beast_mastery"] = {
            interrupt = "counter_shot"
        },
        ["survival"] = {
            interrupt = "muzzle"
        },
        ["marksmanship"] = {
            interrupt = "counter_shot"
        }
    },
    MAGE = {
        ["frost"] = {
            interrupt = "counterspell"
        },
        ["fire"] = {
            interrupt = "counterspell"
        },
        ["arcane"] = {
            interrupt = "counterspell"
        }
    },
    MONK = {
        ["brewmaster"] = {
            interrupt = "spear_hand_strike"
        },
        ["windwalker"] = {
            interrupt = "spear_hand_strike"
        }
    },
    PALADIN = {
        ["retribution"] = {
            interrupt = "rebuke"
        },
        ["protection"] = {
            interrupt = "rebuke"
        }
    },
    PRIEST = {
        ["shadow"] = {
            interrupt = "silence"
        }
    },
    ROGUE = {
        ["assassination"] = {
            interrupt = "kick"
        },
        ["outlaw"] = {
            interrupt = "kick"
        },
        ["subtlety"] = {
            interrupt = "kick"
        }
    },
    SHAMAN = {
        ["elemental"] = {
            interrupt = "wind_shear"
        },
        ["enhancement"] = {
            interrupt = "wind_shear"
        }
    },
    WARLOCK = {},
    WARRIOR = {
        ["fury"] = {
            interrupt = "pummel"
        },
        ["protection"] = {
            interrupt = "pummel"
        },
        ["arms"] = {
            interrupt = "pummel"
        }
    }
}
__exports.CHARACTER_PROPERTY = {
    ["active_enemies"] = "Enemies()",
    ["astral_power"] = "AstralPower()",
    ["astral_power.deficit"] = "AstralPowerDeficit()",
    ["blade_dance_worth_using"] = "0",
    ["buff.arcane_charge.stack"] = "ArcaneCharges()",
    ["buff.arcane_charge.max_stack"] = "MaxArcaneCharges()",
    ["buff.movement.up"] = "Speed() > 0",
    ["buff.out_of_range.up"] = "not target.InRange()",
    ["bugs"] = "0",
    ["chi"] = "Chi()",
    ["chi.max"] = "MaxChi()",
    ["combo_points"] = "ComboPoints()",
    ["combo_points.deficit"] = "ComboPointsDeficit()",
    ["combo_points.max"] = "MaxComboPoints()",
    ["consecration.remains"] = "BuffRemaining(consecration)",
    ["consecration.up"] = "BuffPresent(consecration)",
    ["cooldown.army_of_the_dead.remains"] = "480",
    ["cp_max_spend"] = "MaxComboPoints()",
    ["crit_pct_current"] = "SpellCritChance()",
    ["current_insanity_drain"] = "CurrentInsanityDrain()",
    ["darkglare_no_de"] = "NotDeDemons(darkglare)",
    ["death_and_decay.ticking"] = "BuffPresent(death_and_decay)",
    ["death_sweep_worth_using"] = "0",
    ["death_knight.disable_aotd"] = "0",
    ["delay"] = "0",
    ["demonic_fury"] = "DemonicFury()",
    ["desired_targets"] = "Enemies(tagged=1)",
    ["doomguard_no_de"] = "NotDeDemons(doomguard)",
    ["dreadstalker_no_de"] = "NotDeDemons(dreadstalker)",
    ["dreadstalker_remaining_duration"] = "DemonDuration(dreadstalker)",
    ["eclipse_change"] = "TimeToEclipse()",
    ["eclipse_energy"] = "EclipseEnergy()",
    ["enemies"] = "Enemies()",
    ["energy"] = "Energy()",
    ["energy.deficit"] = "EnergyDeficit()",
    ["energy.max"] = "MaxEnergy()",
    ["energy.regen"] = "EnergyRegenRate()",
    ["energy.time_to_max"] = "TimeToMaxEnergy()",
    ["expected_combat_length"] = "600",
    ["feral_spirit.remains"] = "TotemRemaining(sprit_wolf)",
    ["finality"] = "HasArtifactTrait(finality)",
    ["firestarter.remains"] = "target.TimeToHealthPercent(90)",
    ["focus"] = "Focus()",
    ["focus.deficit"] = "FocusDeficit()",
    ["focus.max"] = "MaxFocus()",
    ["focus.regen"] = "FocusRegenRate()",
    ["focus.time_to_max"] = "TimeToMaxFocus()",
    ["fury"] = "Fury()",
    ["fury.deficit"] = "FuryDeficit()",
    ["health"] = "Health()",
    ["health.deficit"] = "HealthMissing()",
    ["health.max"] = "MaxHealth()",
    ["health.pct"] = "HealthPercent()",
    ["health.percent"] = "HealthPercent()",
    ["holy_power"] = "HolyPower()",
    ["incanters_flow_time_to.5.up"] = "StackTimeTo(incanters_flow_buff 5 up)",
    ["incanters_flow_time_to.4.down"] = "StackTimeTo(incanters_flow_buff 4 down)",
    ["infernal_no_de"] = "NotDeDemons(infernal)",
    ["insanity"] = "Insanity()",
    ["level"] = "Level()",
    ["lunar_max"] = "TimeToEclipse(lunar)",
    ["mana"] = "Mana()",
    ["mana.deficit"] = "ManaDeficit()",
    ["mana.max"] = "MaxMana()",
    ["mana.pct"] = "ManaPercent()",
    ["mana.time_to_max"] = "TimeToMaxMana()",
    ["maelstrom"] = "Maelstrom()",
    ["next_wi_bomb.pheromone"] = "SpellUsable(270323)",
    ["next_wi_bomb.shrapnel"] = "SpellUsable(270335)",
    ["next_wi_bomb.volatile"] = "SpellUsable(271045)",
    ["nonexecute_actors_pct"] = "0",
    ["pain"] = "Pain()",
    ["pain.deficit"] = "PainDeficit()",
    ["pet_count"] = "Demons()",
    ["pet.apoc_ghoul.active"] = "0",
    ["rage"] = "Rage()",
    ["rage.deficit"] = "RageDeficit()",
    ["rage.max"] = "MaxRage()",
    ["raid_event.adds.remains"] = "0",
    ["raid_event.invulnerable.exists"] = "0",
    ["raw_haste_pct"] = "SpellCastSpeedPercent()",
    ["rtb_list.any.5"] = "BuffCount(roll_the_bones_buff more 4)",
    ["rtb_list.any.6"] = "BuffCount(roll_the_bones_buff more 5)",
    ["rune.deficit"] = "RuneDeficit()",
    ["runic_power"] = "RunicPower()",
    ["runic_power.deficit"] = "RunicPowerDeficit()",
    ["service_no_de"] = "0",
    ["shadow_orb"] = "ShadowOrbs()",
    ["sigil_placed"] = "SigilCharging(flame)",
    ["solar_max"] = "TimeToEclipse(solar)",
    ["soul_shard"] = "SoulShards()",
    ["soul_fragments"] = "SoulFragments()",
    ["ssw_refund_offset"] = "target.Distance() % 3 - 1",
    ["stat.mastery_rating"] = "MasteryRating()",
    ["stealthed"] = "Stealthed()",
    ["stealthed.all"] = "Stealthed()",
    ["stealthed.rogue"] = "Stealthed()",
    ["time"] = "TimeInCombat()",
    ["time_to_20pct"] = "TimeToHealthPercent(20)",
    ["time_to_pct_30"] = "TimeToHealthPercent(30)",
    ["time_to_die"] = "TimeToDie()",
    ["time_to_die.remains"] = "TimeToDie()",
    ["time_to_shard"] = "TimeToShard()",
    ["time_to_sht.4"] = "100",
    ["time_to_sht.5"] = "100",
    ["wild_imp_count"] = "Demons(wild_imp)",
    ["wild_imp_no_de"] = "NotDeDemons(wild_imp)",
    ["wild_imp_remaining_duration"] = "DemonDuration(wild_imp)",
    ["buff.executioners_precision.stack"] = "0"
}
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
    ["pct_health"] = true,
    ["precombat"] = true,
    ["precombat_seconds"] = true,
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
