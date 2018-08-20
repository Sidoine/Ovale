import { readFileSync, writeFileSync } from "fs";
import { LuaObj } from "@wowts/lua";

export interface SpellPowerData {
    id: number;
    spell_id: number;
    /** Spell id for the aura during which this power type is active */
    aura_id: number;
    hotfix: number;
    power_type: PowerType;
    cost: number;
    cost_max: number;
    cost_per_tick: number;
    pct_cost: number;
    pct_cost_max: number;
    pct_cost_per_tick: number;
}

export const enum EffectType {
    E_NONE = 0,
    E_INSTAKILL = 1,
    E_SCHOOL_DAMAGE = 2,
    E_DUMMY = 3,
    E_PORTAL_TELEPORT = 4,
    E_TELEPORT_UNITS = 5,
    E_APPLY_AURA = 6,
    E_ENVIRONMENTAL_DAMAGE = 7,
    E_POWER_DRAIN = 8,
    E_HEALTH_LEECH = 9,
    E_HEAL = 10,
    E_BIND = 11,
    E_PORTAL = 12,
    E_RITUAL_BASE = 13,
    E_RITUAL_SPECIALIZE = 14,
    E_RITUAL_ACTIVATE_PORTAL = 15,
    E_QUEST_COMPLETE = 16,
    E_WEAPON_DAMAGE_NOSCHOOL = 17,
    E_RESURRECT = 18,
    E_ADD_EXTRA_ATTACKS = 19,
    E_DODGE = 20,
    E_EVADE = 21,
    E_PARRY = 22,
    E_BLOCK = 23,
    E_CREATE_ITEM = 24,
    E_WEAPON = 25,
    E_DEFENSE = 26,
    E_PERSISTENT_AREA_AURA = 27,
    E_SUMMON = 28,
    E_LEAP = 29,
    E_ENERGIZE = 30,
    E_WEAPON_PERCENT_DAMAGE = 31,
    E_TRIGGER_MISSILE = 32,
    E_OPEN_LOCK = 33,
    E_SUMMON_CHANGE_ITEM = 34,
    E_APPLY_AREA_AURA_PARTY = 35,
    E_LEARN_SPELL = 36,
    E_SPELL_DEFENSE = 37,
    E_DISPEL = 38,
    E_LANGUAGE = 39,
    E_DUAL_WIELD = 40,
    E_JUMP = 41,
    E_JUMP2 = 42,
    E_TELEPORT_UNITS_FACE_CASTER = 43,
    E_SKILL_STEP = 44,
    E_ADD_HONOR = 45,
    E_SPAWN = 46,
    E_TRADE_SKILL = 47,
    E_STEALTH = 48,
    E_DETECT = 49,
    E_TRANS_DOOR = 50,
    E_FORCE_CRITICAL_HIT = 51,
    E_GUARANTEE_HIT = 52,
    E_ENCHANT_ITEM = 53,
    E_ENCHANT_ITEM_TEMPORARY = 54,
    E_TAMECREATURE = 55,
    E_SUMMON_PET = 56,
    E_LEARN_PET_SPELL = 57,
    E_WEAPON_DAMAGE = 58,
    E_CREATE_RANDOM_ITEM = 59,
    E_PROFICIENCY = 60,
    E_SEND_EVENT = 61,
    E_POWER_BURN = 62,
    E_THREAT = 63,
    E_TRIGGER_SPELL = 64,
    E_APPLY_AREA_AURA_RAID = 65,
    E_RESTORE_ITEM_CHARGES = 66,
    E_HEAL_MAX_HEALTH = 67,
    E_INTERRUPT_CAST = 68,
    E_DISTRACT = 69,
    E_PULL = 70,
    E_PICKPOCKET = 71,
    E_ADD_FARSIGHT = 72,
    E_UNTRAIN_TALENTS = 73,
    E_APPLY_GLYPH = 74,
    E_HEAL_MECHANICAL = 75,
    E_SUMMON_OBJECT_WILD = 76,
    E_SCRIPT_EFFECT = 77,
    E_ATTACK = 78,
    E_SANCTUARY = 79,
    E_ADD_COMBO_POINTS = 80,
    E_CREATE_HOUSE = 81,
    E_BIND_SIGHT = 82,
    E_DUEL = 83,
    E_STUCK = 84,
    E_SUMMON_PLAYER = 85,
    E_ACTIVATE_OBJECT = 86,
    E_WMO_DAMAGE = 87,
    E_WMO_REPAIR = 88,
    E_WMO_CHANGE = 89,
    E_KILL_CREDIT = 90,
    E_THREAT_ALL = 91,
    E_ENCHANT_HELD_ITEM = 92,
    E_BREAK_PLAYER_TARGETING = 93,
    E_SELF_RESURRECT = 94,
    E_SKINNING = 95,
    E_CHARGE = 96,
    E_SUMMON_ALL_TOTEMS = 97,
    E_KNOCK_BACK = 98,
    E_DISENCHANT = 99,
    E_INEBRIATE = 100,
    E_FEED_PET = 101,
    E_DISMISS_PET = 102,
    E_REPUTATION = 103,
    E_SUMMON_OBJECT_SLOT1 = 104,
    E_SUMMON_OBJECT_SLOT2 = 105,
    E_SUMMON_OBJECT_SLOT3 = 106,
    E_SUMMON_OBJECT_SLOT4 = 107,
    E_DISPEL_MECHANIC = 108,
    E_SUMMON_DEAD_PET = 109,
    E_DESTROY_ALL_TOTEMS = 110,
    E_DURABILITY_DAMAGE = 111,
    E_112 = 112, // old E_SUMMON_DEMON
    E_RESURRECT_NEW = 113,
    E_ATTACK_ME = 114,
    E_DURABILITY_DAMAGE_PCT = 115,
    E_SKIN_PLAYER_CORPSE = 116,
    E_SPIRIT_HEAL = 117,
    E_SKILL = 118,
    E_APPLY_AREA_AURA_PET = 119,
    E_TELEPORT_GRAVEYARD = 120,
    E_NORMALIZED_WEAPON_DMG = 121,
    E_122 = 122,
    E_SEND_TAXI = 123,
    E_PLAYER_PULL = 124,
    E_MODIFY_THREAT_PERCENT = 125,
    E_STEAL_BENEFICIAL_BUFF = 126,
    E_PROSPECTING = 127,
    E_APPLY_AREA_AURA_FRIEND = 128,
    E_APPLY_AREA_AURA_ENEMY = 129,
    E_REDIRECT_THREAT = 130,
    E_131 = 131,
    E_PLAY_MUSIC = 132,
    E_UNLEARN_SPECIALIZATION = 133,
    E_KILL_CREDIT2 = 134,
    E_CALL_PET = 135,
    E_HEAL_PCT = 136,
    E_ENERGIZE_PCT = 137,
    E_LEAP_BACK = 138,
    E_CLEAR_QUEST = 139,
    E_FORCE_CAST = 140,
    E_141 = 141,
    E_TRIGGER_SPELL_WITH_VALUE = 142,
    E_APPLY_AREA_AURA_OWNER = 143,
    E_144 = 144,
    E_145 = 145,
    E_ACTIVATE_RUNE = 146,
    E_QUEST_FAIL = 147,
    E_148 = 148,
    E_149 = 149,
    E_150 = 150,
    E_TRIGGER_SPELL_2 = 151,
    E_152 = 152,
    E_153 = 153,
    E_TEACH_TAXI_NODE = 154,
    E_TITAN_GRIP = 155,
    E_ENCHANT_ITEM_PRISMATIC = 156,
    E_CREATE_ITEM_2 = 157,
    E_MILLING = 158,
    E_ALLOW_RENAME_PET = 159,
    E_160 = 160,
    E_TALENT_SPEC_COUNT = 161,
    E_TALENT_SPEC_SELECT = 162,
    E_163 = 163,
    E_164 = 164,
    E_165 = 165,
    E_166 = 166,
    E_167 = 167,
    E_168 = 168,
    E_169 = 169,
    E_170 = 170,
    E_171 = 171,
    E_172 = 172,
    E_173 = 173,
    E_174 = 174,
    E_175 = 175,
    E_176 = 176,
    E_179 = 179,
    E_188 = 188,
    E_189 = 189,
    E_196 = 196,
    E_203 = 203,
    E_206 = 206,
    E_223 = 223,
    E_230 = 230,
    E_238 = 238,
    E_243 = 243,
    E_MAX
}

export const enum EffectSubtype {
    A_NONE = 0,
    A_BIND_SIGHT = 1,
    A_MOD_POSSESS = 2,
    A_PERIODIC_DAMAGE = 3,
    A_DUMMY = 4,
    A_MOD_CONFUSE = 5,
    A_MOD_CHARM = 6,
    A_MOD_FEAR = 7,
    A_PERIODIC_HEAL = 8,
    A_MOD_ATTACKSPEED = 9,
    A_MOD_THREAT = 10,
    A_MOD_TAUNT = 11,
    A_MOD_STUN = 12,
    A_MOD_DAMAGE_DONE = 13,
    A_MOD_DAMAGE_TAKEN = 14,
    A_DAMAGE_SHIELD = 15,
    A_MOD_STEALTH = 16,
    A_MOD_STEALTH_DETECT = 17,
    A_MOD_INVISIBILITY = 18,
    A_MOD_INVISIBILITY_DETECTION = 19,
    A_OBS_MOD_HEALTH = 20, //20,21 unofficial
    A_OBS_MOD_MANA = 21,
    A_MOD_RESISTANCE = 22,
    A_PERIODIC_TRIGGER_SPELL = 23,
    A_PERIODIC_ENERGIZE = 24,
    A_MOD_PACIFY = 25,
    A_MOD_ROOT = 26,
    A_MOD_SILENCE = 27,
    A_REFLECT_SPELLS = 28,
    A_MOD_STAT = 29,
    A_MOD_SKILL = 30,
    A_MOD_INCREASE_SPEED = 31,
    A_MOD_INCREASE_MOUNTED_SPEED = 32,
    A_MOD_DECREASE_SPEED = 33,
    A_MOD_INCREASE_HEALTH = 34,
    A_MOD_INCREASE_ENERGY = 35,
    A_MOD_SHAPESHIFT = 36,
    A_EFFECT_IMMUNITY = 37,
    A_STATE_IMMUNITY = 38,
    A_SCHOOL_IMMUNITY = 39,
    A_DAMAGE_IMMUNITY = 40,
    A_DISPEL_IMMUNITY = 41,
    A_PROC_TRIGGER_SPELL = 42,
    A_PROC_TRIGGER_DAMAGE = 43,
    A_TRACK_CREATURES = 44,
    A_TRACK_RESOURCES = 45,
    A_46 = 46, // Ignore all Gear test spells
    A_MOD_PARRY_PERCENT = 47,
    A_48 = 48, // One periodic spell
    A_MOD_DODGE_PERCENT = 49,
    A_MOD_CRITICAL_HEALING_AMOUNT = 50,
    A_MOD_BLOCK_PERCENT = 51,
    A_MOD_CRIT_PERCENT = 52,
    A_PERIODIC_LEECH = 53,
    A_MOD_HIT_CHANCE = 54,
    A_MOD_SPELL_HIT_CHANCE = 55,
    A_TRANSFORM = 56,
    A_MOD_SPELL_CRIT_CHANCE = 57,
    A_MOD_INCREASE_SWIM_SPEED = 58,
    A_MOD_DAMAGE_DONE_CREATURE = 59,
    A_MOD_PACIFY_SILENCE = 60,
    A_MOD_SCALE = 61,
    A_PERIODIC_HEALTH_FUNNEL = 62,
    A_63 = 63, // old A_PERIODIC_MANA_FUNNEL
    A_PERIODIC_MANA_LEECH = 64,
    A_MOD_CASTING_SPEED_NOT_STACK = 65,
    A_FEIGN_DEATH = 66,
    A_MOD_DISARM = 67,
    A_MOD_STALKED = 68,
    A_SCHOOL_ABSORB = 69,
    A_EXTRA_ATTACKS = 70,
    A_MOD_SPELL_CRIT_CHANCE_SCHOOL = 71,
    A_MOD_POWER_COST_SCHOOL_PCT = 72,
    A_MOD_POWER_COST_SCHOOL = 73,
    A_REFLECT_SPELLS_SCHOOL = 74,
    A_MOD_LANGUAGE = 75,
    A_FAR_SIGHT = 76,
    A_MECHANIC_IMMUNITY = 77,
    A_MOUNTED = 78,
    A_MOD_DAMAGE_PERCENT_DONE = 79,
    A_MOD_PERCENT_STAT = 80,
    A_SPLIT_DAMAGE_PCT = 81,
    A_WATER_BREATHING = 82,
    A_MOD_BASE_RESISTANCE = 83,
    A_MOD_REGEN = 84,
    A_MOD_POWER_REGEN = 85,
    A_CHANNEL_DEATH_ITEM = 86,
    A_MOD_DAMAGE_PERCENT_TAKEN = 87,
    A_MOD_HEALTH_REGEN_PERCENT = 88,
    A_PERIODIC_DAMAGE_PERCENT = 89,
    A_90 = 90, // old A_MOD_RESIST_CHANCE
    A_MOD_DETECT_RANGE = 91,
    A_PREVENTS_FLEEING = 92,
    A_MOD_UNATTACKABLE = 93,
    A_INTERRUPT_REGEN = 94,
    A_GHOST = 95,
    A_SPELL_MAGNET = 96,
    A_MANA_SHIELD = 97,
    A_MOD_SKILL_TALENT = 98,
    A_MOD_ATTACK_POWER = 99,
    A_AURAS_VISIBLE = 100,
    A_MOD_RESISTANCE_PCT = 101,
    A_MOD_MELEE_ATTACK_POWER_VERSUS = 102,
    A_MOD_TOTAL_THREAT = 103,
    A_WATER_WALK = 104,
    A_FEATHER_FALL = 105,
    A_HOVER = 106,
    A_ADD_FLAT_MODIFIER = 107,
    A_ADD_PCT_MODIFIER = 108,
    A_ADD_TARGET_TRIGGER = 109,
    A_MOD_POWER_REGEN_PERCENT = 110,
    A_ADD_CASTER_HIT_TRIGGER = 111,
    A_OVERRIDE_CLASS_SCRIPTS = 112,
    A_MOD_RANGED_DAMAGE_TAKEN = 113,
    A_MOD_RANGED_DAMAGE_TAKEN_PCT = 114,
    A_MOD_HEALING = 115,
    A_MOD_REGEN_DURING_COMBAT = 116,
    A_MOD_MECHANIC_RESISTANCE = 117,
    A_MOD_HEALING_PCT = 118,
    A_119 = 119, // old A_SHARE_PET_TRACKING
    A_UNTRACKABLE = 120,
    A_EMPATHY = 121,
    A_MOD_OFFHAND_DAMAGE_PCT = 122,
    A_MOD_TARGET_RESISTANCE = 123,
    A_MOD_RANGED_ATTACK_POWER = 124,
    A_MOD_MELEE_DAMAGE_TAKEN = 125,
    A_MOD_MELEE_DAMAGE_TAKEN_PCT = 126,
    A_RANGED_ATTACK_POWER_ATTACKER_BONUS = 127,
    A_MOD_POSSESS_PET = 128,
    A_MOD_SPEED_ALWAYS = 129,
    A_MOD_MOUNTED_SPEED_ALWAYS = 130,
    A_MOD_RANGED_ATTACK_POWER_VERSUS = 131,
    A_MOD_INCREASE_ENERGY_PERCENT = 132,
    A_MOD_INCREASE_HEALTH_PERCENT = 133,
    A_MOD_MANA_REGEN_INTERRUPT = 134,
    A_MOD_HEALING_DONE = 135,
    A_MOD_HEALING_DONE_PERCENT = 136,
    A_MOD_TOTAL_STAT_PERCENTAGE = 137,
    A_MOD_HASTE = 138,
    A_FORCE_REACTION = 139,
    A_MOD_RANGED_HASTE = 140,
    A_MOD_RANGED_AMMO_HASTE = 141,
    A_MOD_BASE_RESISTANCE_PCT = 142,
    A_MOD_RESISTANCE_EXCLUSIVE = 143,
    A_SAFE_FALL = 144,
    A_MOD_PET_TALENT_POINTS = 145,
    A_ALLOW_TAME_PET_TYPE = 146,
    A_MECHANIC_IMMUNITY_MASK = 147,
    A_RETAIN_COMBO_POINTS = 148,
    A_REDUCE_PUSHBACK = 149, // Reduce Pushback
    A_MOD_SHIELD_BLOCKVALUE_PCT = 150,
    A_TRACK_STEALTHED = 151, // Track Stealthed
    A_MOD_DETECTED_RANGE = 152, // Mod Detected Range
    A_SPLIT_DAMAGE_FLAT = 153, // Split Damage Flat
    A_MOD_STEALTH_LEVEL = 154, // Stealth Level Modifier
    A_MOD_WATER_BREATHING = 155, // Mod Water Breathing
    A_MOD_REPUTATION_GAIN = 156, // Mod Reputation Gain
    A_PET_DAMAGE_MULTI = 157, // Mod Pet Damage
    A_MOD_SHIELD_BLOCKVALUE = 158,
    A_NO_PVP_CREDIT = 159,
    A_MOD_AOE_AVOIDANCE = 160,
    A_MOD_HEALTH_REGEN_IN_COMBAT = 161,
    A_POWER_BURN_MANA = 162,
    A_MOD_CRIT_DAMAGE_BONUS = 163,
    A_164 = 164,
    A_MELEE_ATTACK_POWER_ATTACKER_BONUS = 165,
    A_MOD_ATTACK_POWER_PCT = 166,
    A_MOD_RANGED_ATTACK_POWER_PCT = 167,
    A_MOD_DAMAGE_DONE_VERSUS = 168,
    A_MOD_CRIT_PERCENT_VERSUS = 169,
    A_DETECT_AMORE = 170,
    A_MOD_SPEED_NOT_STACK = 171,
    A_MOD_MOUNTED_SPEED_NOT_STACK = 172,
    A_173 = 173, // old A_ALLOW_CHAMPION_SPELLS
    A_MOD_SPELL_DAMAGE_OF_STAT_PERCENT = 174, // by defeult intelect, dependent from A_MOD_SPELL_HEALING_OF_STAT_PERCENT
    A_MOD_SPELL_HEALING_OF_STAT_PERCENT = 175,
    A_SPIRIT_OF_REDEMPTION = 176,
    A_AOE_CHARM = 177,
    A_MOD_DEBUFF_RESISTANCE = 178,
    A_MOD_ATTACKER_SPELL_CRIT_CHANCE = 179,
    A_MOD_FLAT_SPELL_DAMAGE_VERSUS = 180,
    A_181 = 181, // old A_MOD_FLAT_SPELL_CRIT_DAMAGE_VERSUS - possible flat spell crit damage versus
    A_MOD_RESISTANCE_OF_STAT_PERCENT = 182,
    A_MOD_CRITICAL_THREAT = 183,
    A_MOD_ATTACKER_MELEE_HIT_CHANCE = 184,
    A_MOD_ATTACKER_RANGED_HIT_CHANCE = 185,
    A_MOD_ATTACKER_SPELL_HIT_CHANCE = 186,
    A_MOD_ATTACKER_MELEE_CRIT_CHANCE = 187,
    A_MOD_ATTACKER_RANGED_CRIT_CHANCE = 188,
    A_MOD_RATING = 189,
    A_MOD_FACTION_REPUTATION_GAIN = 190,
    A_USE_NORMAL_MOVEMENT_SPEED = 191,
    A_HASTE_MELEE = 192,
    A_HASTE_ALL = 193,
    A_MOD_IGNORE_ABSORB_SCHOOL = 194,
    A_MOD_IGNORE_ABSORB_FOR_SPELL = 195,
    A_MOD_COOLDOWN = 196, // only 24818 Noxious Breath
    A_MOD_ATTACKER_SPELL_AND_WEAPON_CRIT_CHANCE = 197,
    A_198 = 198, // old A_MOD_ALL_WEAPON_SKILLS
    A_MOD_INCREASES_SPELL_PCT_TO_HIT = 199,
    A_MOD_KILL_XP_PCT = 200,
    A_FLY = 201,
    A_IGNORE_COMBAT_RESULT = 202,
    A_MOD_ATTACKER_MELEE_CRIT_DAMAGE = 203,
    A_MOD_ATTACKER_RANGED_CRIT_DAMAGE = 204,
    A_MOD_ATTACKER_SPELL_CRIT_DAMAGE = 205,
    A_MOD_FLIGHT_SPEED = 206,
    A_MOD_FLIGHT_SPEED_MOUNTED = 207,
    A_MOD_FLIGHT_SPEED_STACKING = 208,
    A_MOD_FLIGHT_SPEED_MOUNTED_STACKING = 209,
    A_MOD_FLIGHT_SPEED_NOT_STACKING = 210,
    A_MOD_FLIGHT_SPEED_MOUNTED_NOT_STACKING = 211,
    A_MOD_RANGED_ATTACK_POWER_OF_STAT_PERCENT = 212,
    A_MOD_RAGE_FROM_DAMAGE_DEALT = 213,
    A_214 = 214,
    A_ARENA_PREPARATION = 215,
    A_HASTE_SPELLS = 216,
    A_217 = 217,
    A_HASTE_RANGED = 218,
    A_MOD_MANA_REGEN_FROM_STAT = 219,
    A_MOD_RATING_FROM_STAT = 220,
    A_221 = 221,
    A_222 = 222,
    A_223 = 223,
    A_224 = 224,
    A_PRAYER_OF_MENDING = 225,
    A_PERIODIC_DUMMY = 226,
    A_PERIODIC_TRIGGER_SPELL_WITH_VALUE = 227,
    A_DETECT_STEALTH = 228,
    A_MOD_AOE_DAMAGE_AVOIDANCE = 229,
    A_230 = 230,
    A_PROC_TRIGGER_SPELL_WITH_VALUE = 231,
    A_MECHANIC_DURATION_MOD = 232,
    A_233 = 233,
    A_MECHANIC_DURATION_MOD_NOT_STACK = 234,
    A_MOD_DISPEL_RESIST = 235,
    A_CONTROL_VEHICLE = 236,
    A_MOD_SPELL_DAMAGE_OF_ATTACK_POWER = 237,
    A_MOD_SPELL_HEALING_OF_ATTACK_POWER = 238,
    A_MOD_SCALE_2 = 239,
    A_MOD_EXPERTISE = 240,
    A_FORCE_MOVE_FORWARD = 241,
    A_MOD_SPELL_DAMAGE_FROM_HEALING = 242,
    A_243 = 243,
    A_COMPREHEND_LANGUAGE = 244,
    A_MOD_DURATION_OF_MAGIC_EFFECTS = 245,
    A_MOD_DURATION_OF_EFFECTS_BY_DISPEL = 246,
    A_247 = 247,
    A_MOD_COMBAT_RESULT_CHANCE = 248,
    A_CONVERT_RUNE = 249,
    A_MOD_INCREASE_HEALTH_2 = 250,
    A_MOD_ENEMY_DODGE = 251,
    A_SLOW_ALL = 252,
    A_MOD_BLOCK_CRIT_CHANCE = 253,
    A_MOD_DISARM_SHIELD = 254,
    A_MOD_MECHANIC_DAMAGE_TAKEN_PERCENT = 255,
    A_NO_REAGENT_USE = 256,
    A_MOD_TARGET_RESIST_BY_SPELL_CLASS = 257,
    A_258 = 258,
    A_259 = 259,
    A_SCREEN_EFFECT = 260,
    A_PHASE = 261,
    A_262 = 262,
    A_ALLOW_ONLY_ABILITY = 263,
    A_264 = 264,
    A_265 = 265,
    A_266 = 266,
    A_MOD_IMMUNE_A_APPLY_SCHOOL = 267,
    A_MOD_ATTACK_POWER_OF_STAT_PERCENT = 268,
    A_MOD_IGNORE_DAMAGE_REDUCTION_SCHOOL = 269,
    A_MOD_IGNORE_TARGET_RESIST = 270, // Possibly need swap vs 195 aura used only in 1 spell Chaos Bolt Passive
    A_MOD_DAMAGE_FROM_CASTER = 271,
    A_MAELSTROM_WEAPON = 272,
    A_X_RAY = 273,
    A_274 = 274,
    A_MOD_IGNORE_SHAPESHIFT = 275,
    A_276 = 276, // Only "Test Mod Damage % Mechanic" spell, possible mod damage done
    A_MOD_MAX_AFFECTED_TARGETS = 277,
    A_MOD_DISARM_RANGED = 278,
    A_279 = 279,
    A_MOD_TARGET_ARMOR_PCT = 280,
    A_MOD_HONOR_GAIN = 281,
    A_MOD_BASE_HEALTH_PCT = 282,
    A_MOD_HEALING_RECEIVED = 283, // Possibly only for some spell family class spells
    A_284,
    A_MOD_ATTACK_POWER_OF_ARMOR = 285,
    A_ABILITY_PERIODIC_CRIT = 286,
    A_DEFLECT_SPELLS = 287,
    A_288 = 288,
    A_289 = 289,
    A_MOD_ALL_CRIT_CHANCE = 290,
    A_MOD_QUEST_XP_PCT = 291,
    A_OPEN_STABLE = 292,
    A_293 = 293,
    A_294 = 294,
    A_295 = 295,
    A_296 = 296,
    A_297 = 297,
    A_298 = 298,
    A_299 = 299,
    A_300 = 300,
    A_301 = 301,
    A_302 = 302,
    A_303 = 303,
    A_304 = 304,
    A_MOD_MINIMUM_SPEED = 305,
    A_306 = 306,
    A_307 = 307,
    A_308 = 308,
    A_309 = 309,
    A_310 = 310,
    A_311 = 311,
    A_312 = 312,
    A_313 = 313,
    A_314 = 314,
    A_315 = 315,
    A_316 = 316,
    A_317 = 317,
    A_318 = 318,
    A_319 = 319,
    A_320 = 320,
    A_321 = 321,
    A_322 = 322,
    A_323 = 323,
    A_324 = 324,
    A_325 = 325,
    A_326 = 326,
    A_327 = 327,
    A_328 = 328,
    A_329 = 329,
    A_330 = 330,
    A_331 = 331,
    A_332 = 332,
    A_333 = 333,
    A_334 = 334,
    A_335 = 335,
    A_336 = 336,
    A_337 = 337,
    A_338 = 338,
    A_339 = 339,
    A_340 = 340,
    A_341 = 341,
    A_342 = 342,
    A_343 = 343,
    A_344 = 344,
    A_345 = 345,
    A_346 = 346,
    A_347 = 347,
    A_348 = 348,
    A_349 = 349,
    A_350 = 350,
    A_351 = 351,
    A_352 = 352,
    A_353 = 353,
    A_354 = 354,
    A_355 = 355,
    A_356 = 356,
    A_357 = 357,
    A_358 = 358,
    A_359 = 359,
    A_360 = 360,
    A_361 = 361,
    A_362 = 362,
    A_363 = 363,
    A_364 = 364,
    A_365 = 365,
    A_366 = 366,
    A_367 = 367,
    A_371 = 371,
    A_373 = 373,
    A_377 = 377,
    A_378 = 378,
    A_379 = 379,
    A_380 = 380,
    A_381 = 381,
    A_382 = 382,
    A_383 = 383,
    A_385 = 385,
    A_389 = 389,
    A_392 = 392,
    A_393 = 393,
    A_395 = 395,
    A_396 = 396,
    A_400 = 400,
    A_402 = 402,
    A_403 = 403,
    A_404 = 404,
    A_405 = 405,
    A_407 = 407,
    A_408 = 408,
    A_409 = 409,
    A_410 = 410,
    A_411 = 411,
    A_412 = 412,
    A_416 = 416,
    A_417 = 417,
    A_418 = 418,
    A_419 = 419,
    A_421 = 421,
    A_MOD_ABSORB_DONE_PERCENT = 422,
    A_423 = 423,
    A_424 = 424,
    A_429 = 429,
    A_440 = 440,
    A_441 = 441,
    A_443 = 443,
    A_446 = 446,
    A_447 = 447,
    A_451 = 451,
    A_453 = 453,
    A_454 = 454,
    A_455 = 455,
    A_458 = 458,
    A_463 = 463,
    A_464 = 464,
    A_465 = 465,
    A_466 = 466,
    A_467 = 467,
    A_468 = 468,
    A_470 = 470,
    A_471 = 471,
    A_478 = 478,
    A_MAX
}

export const enum PowerType {
    POWER_HEALTH      = -2,
  POWER_MANA        = 0,
  POWER_RAGE        = 1,
  POWER_FOCUS       = 2,
  POWER_ENERGY      = 3,
  POWER_COMBO_POINT = 4,
  POWER_RUNE        = 5,
  POWER_RUNIC_POWER = 6,
  POWER_SOUL_SHARDS = 7,
  POWER_ASTRAL_POWER = 8,
  POWER_HOLY_POWER = 9,
  // Not yet used (MoP Monk deprecated resource #1)
  // Not yet used
  POWER_MAELSTROM     = 11,
  POWER_CHI           = 12,
  POWER_INSANITY      = 13,
  POWER_BURNING_EMBER = 14,
  POWER_DEMONIC_FURY  = 15,
  // Not yet used?
  POWER_FURY          = 17,
  POWER_PAIN          = 18,
}

export const enum SpellAttributes {
    Channeled = 1 << 34,
    Channeled2 = 1 << 38
}

export interface SpellData {
    name: string;
    id: number;
    /** 3 Hotfix bitmap
    Each field points to a field in this struct, starting from
    the first field. The most significant bit
    (0x8000 0000 0000 0000) indicates the presence of hotfixed
    effect data for this spell.*/
    hotfix: number;
    /** 4 Projectile Speed */
    prj_speed: number;
    /** 5 Spell school mask */
    school: number;
    /** 6 Class mask for spell */
    class_mask: number;
    /** 7 Racial mask for the spell */
    race_mask: number;
    /** 8 Array index for gtSpellScaling.dbc. -1 means the first non-class-specific sub array, and so on, 0 disabled */
    scaling_type: number;
    /** 9 Max scaling level(?), 0 == no restrictions, otherwise min( player_level, max_scaling_level ) */
    max_scaling_level: number;
    /** 10 Spell learned on level. NOTE: Only accurate for "class abilities" */
    spell_level: number;
    /** 11 Maximum level for scaling */
    max_level: number;
    // SpellRange.dbc
    /** 12 Minimum range in yards */
    min_range: number;
    /** 13 Maximum range in yards */
    max_range: number;
    // SpellCooldown.dbc
    /** 14 Cooldown in milliseconds */
    cooldown: number;
    /** 15 GCD in milliseconds */
    gcd: number;
    /** 16 Category cooldown in milliseconds */
    category_cooldown: number;
    // SpellCategory.dbc
    /** 17 Number of charges */
    charges: number;
    /** 18 Cooldown duration of charges */
    charge_cooldown: number;
    // SpellCategories.dbc
    /** 19 Spell category (for shared cooldowns, effects?) */
    category: number;
    // SpellDuration.dbc
    /** 20 Spell duration in milliseconds */
    duration: number;
    // SpellAuraOptions.dbc
    /** 21 Maximum stack size for spell */
    max_stack: number;
    /** 22 Spell proc chance in percent */
    proc_chance: number;
    /**  23 Per proc charge amount */
    proc_charges: number;
    /** 24 Proc flags */
    proc_flags: number;
    /** 25 ICD */
    internal_cooldown: number;
    /** 26 Base real procs per minute */
    rppm: number;
    // SpellEquippedItems.dbc
    /** 27  */
    equipped_class: number;
    /** 28 */
    equipped_invtype_mask: number;
    /** 29 */
    equipped_subclass_mask: number;
    // SpellScaling.dbc
    /** // 30 Minimum casting time in milliseconds */
    cast_min: number;
    /** // 31 Maximum casting time in milliseconds */
    cast_max: number;
    /** // 32 A divisor used in the formula for casting time scaling (20 always?) */
    cast_div: number;
    /** // 33 A scaling multiplier for level based scaling */
    c_scaling: number;
    /** // 34 A scaling divisor for level based scaling */
    c_scaling_level: number;
    // SpecializationSpells.dbc
    /** // Not included in hotfixed data, replaces spell with specialization specific spell */
    replace_spell_id: number;
    // Spell.dbc flags
    /** // 35 Spell.dbc "flags", record field 1..10, note that 12694 added a field here after flags_7 */
    attributes: number[];
    /** 36 SpellClassOptions.dbc flags */
    class_flags: number[];
    /** 37 SpellClassOptions.dbc spell family */
    class_flags_family: number;
    // SpellShapeshift.db2
    /** 38 Stance mask (used only for druid form restrictions?) */
    stance_mask: number;
    // SpellMechanic.db2
    /** 39 */
    mechanic: number;
    /** 40 Azerite power id */
    power_id: number;
    // Textual data
    /** 41 Spell.dbc description stringblock */
    desc: string;
    /** 42 Spell.dbc tooltip stringblock */
    tooltip: string;
    // SpellDescriptionVariables.dbc
    /** 43 Spell description variable stringblock, if present */
    desc_vars: string;
    // SpellIcon.dbc
    /** 44 */
    rank_str: string;

    /** 45 */
    req_max_level: number;

    spellEffects?: SpellEffectData[];
    spellPowers?: SpellPowerData[];
    identifier?: string;
    identifierScore?: number;
    talent?: TalentData;
    azeriteTrait?: AzeriteTrait;
}

export interface SpellEffectData {
    /** 1 Effect id */
    id: number;
    /** 2 Hotfix bitmap */
    hotfix: number;
    //   Each bit points to a field in this struct, starting from
    // the first field
    /** 3 Spell this effect belongs to */
    spell_id: number;
    /** 4 Effect index for the spell  */
    index: number;
    /** 5 Effect type */
    type: EffectType;
    /** 6 Effect sub-type */
    subtype: EffectSubtype;
    // SpellScaling.dbc
    /** 7 Effect average spell scaling multiplier */
    m_avg: number;
    /** 8 Effect delta spell scaling multiplier */
    m_delta: number;
    /** 9 Unused effect scaling multiplier */
    m_unk: number;
    //
    /** 10 Effect coefficient */
    sp_coeff: number;
    /** 11 Effect attack power coefficient */
    ap_coeff: number;
    /** 12 Effect amplitude (e.g., tick time) */
    amplitude: number;
    // SpellRadius.dbc
    /** 13 Minimum spell radius */
    radius: number;
    /** 14 Maximum spell radius */
    radius_max: number;
    //
    /** 15 Effect value */
    base_value: number;
    /** 16 Effect miscellaneous value */
    misc_value: number;
    /** 17 Effect miscellaneous value 2 */
    misc_value_2: number;
    /** // 18 Class family flags */
    class_flags: number[];
    /** // 19 Effect triggers this spell id */
    trigger_spell_id: number;
    /** 20 Effect chain multiplier */
    m_chain: number;
    /** 21 Effect points per combo points */
    pp_combo_points: number;
    /** 22 Effect real points per level */
    real_ppl: number;
    /** 23 Effect Mechanic */
    mechanic: number;
    /** 24 Number of targets (for chained spells) */
    chain_target: number;
    /** 25 Targeting related field 1 */
    targeting_1: number;
    /** 26 Targeting related field 2 */
    targeting_2: number;
    /** 27 Misc multiplier used for some spells(?) */
    m_value: number;
}

export interface TalentData {
    /** Talent name */
    name: string;        
    /** Talent id */
    id: number;          
    /** Unused for now, 0x00 for all */
    flags: number;       
    /** Class mask */
    m_class: number;     
    /** Specialization */
    spec: number;        
    /** Talent column */
    col: number;         
    /**Talent row */
    row: number;         
    /** Talent spell */
    spell_id: number;    
    /** Talent replaces the following spell id  */
    replace_id: number;  

    identifier: string;
    talentId: number;
}

export interface ItemData {
    id: number;
    name: string;
    flags_1: number;
    flags_2: number;
    type_flags: number;
    /** Ilevel */
    level: number;                 
    req_level: number;
    req_skill: number;
    req_skill_level: number;
    quality: number;
    inventory_type: number;
    item_class: number;
    item_subclass: number;
    bind_type: number;
    delay: number;
    dmg_range: number;
    item_modifier: number;
    race_mask: number;
    class_mask: number;
    /** item_mod_type */
    stat_type_e: number[];       
    stat_alloc: number[];
    stat_socket_mul: number[];
    /** item_spell_trigger_type */
    trigger_spell: number[];
    id_spell: number[];
    cooldown_duration: number[];
    cooldown_group: number[];
    cooldown_group_duration: number[];
    /**  item_socket_color */
    socket_color: number[];
    gem_properties: number;
    id_socket_bonus: number;
    id_set: number;
    id_suffix_group: number;
    id_scaling_distribution: number;
    id_artifact: number;

    identifier: string;
}

export interface AzeriteTrait {
    id: number;
    spellId: number;
    name: string;
    identifier: string;
}

export function isFriendlyTarget(targetId: number) {
    switch (targetId) {
        case 1:
        case 5:
        case 21:
        case 30:
        case 31:
        case 42:
        case 45:
        case 56:
            return true;
        default:
            return false;
    }  
}

function readFile(directory:string, fileName: string, zone: any[][], output: { [key: string]: any[][] }) {
    const spellDataFile = readFileSync(`${directory}/engine/dbc/generated/${fileName}.inc`, { encoding: "utf8" });

    function getColumns($data: string): [any[], number] {
        const columns = [];
        let i = 0;
        for (; i < $data.length; i++) {
            while ($data[i] === ' ') i++;
            const c = $data[i];
            if (c === '"') {
                let start = ++i;
                while ($data[i] !== '"') {
                    if ($data[i] === '\\') {
                        i++;
                    }
                    i++;
                }
                const text = $data.substring(start, i);
                i++;
                columns.push(text);
            } else if (c === "n") {
                const nullptr = "nullptr";
                if ($data.substr(i, nullptr.length) !== nullptr) throw Error("Excepted nullptr");
                i+=nullptr.length;
            } else if (c >= '0' && c <= '9' || c === '-') {
                let start = i++;
                while (($data[i] >= '0' && $data[i] <= '9') || ($data[i] >= 'a' && $data[i] <= 'f')
                    || $data[i] === 'x' || $data[i] === '.' || $data[i] === 'U') {
                    i++;
                }
                const number = $data.substring(start, i);
                columns.push(parseInt(number));
            } else if (c === '{') {
                const innerData = getColumns($data.substr(i + 1));
                columns.push(<(number | string)[]>innerData[0]);
                i += innerData[1] + 2;
            } else if (c === '}') {
                break;
            }
            while ($data[i] === ' ') i++;
            if ($data[i] === ',') {
                i++;
            } else if ($data[i] === '}' || $data[i] === undefined) {
                break;
            } else {
                throw new Error(`${fileName}: Unexcepted ${$data[i]} character at ${$data.substring(i - 3)} in ${$data}`);
            }
        }
        return [columns, i];
    }

    for (let $line of spellDataFile.split("\n")) {
        $line = $line.replace(/\/\/.*/, '').replace('nullptr', '');
        let match: RegExpMatchArray;
        if (match = $line.match(/static struct (\w+)/)) {
            zone = [];
            output[match[1]] = zone;            
        } else if (match = $line.match(/static constexpr std::array<(\w+)/)) {
            zone = [];
            output[match[1]] = zone;            
        }
        else if (match = $line.match(/{(.*)}/)) {
            let $data = match[1];
            const [columns] = getColumns($data);
            zone.push(columns);
        }
    }
}

function getIdentifier(name: string) {
    if (!name) return name;
    return name.toLowerCase().replace(/^potion of (the )?/, "").replace(/ /g, '_').replace("!", "_aura").replace(/[:'()]/g, "").replace(/-/g, "_")
}

export function getSpellData(directory: string) {
    let output: { [key: string]: any[][] } = {};
    let zone: any[][];
    readFile(directory, "sc_spell_data", zone, output);
    readFile(directory, "sc_talent_data", zone, output);
    readFile(directory, "sc_item_data", zone, output);
    readFile(directory, "azerite", zone, output);

    const identifiers: LuaObj<number> = {};
    
    const spellData: SpellData[] = [];
    const spellDataById = new Map<number, SpellData>();
    for (const row of output.spell_data_t) {
        const spell: SpellData = {
            name: row[0],
            id: row[1],
            hotfix: row[2],
            prj_speed: row[3],
            school: row[4],
            class_mask: row[5],
            race_mask: row[6],
            scaling_type: row[7],
            max_scaling_level: row[8],
            spell_level: row[9],
            max_level: row[10],
            min_range: row[11],
            max_range: row[12],
            cooldown: row[13],
            gcd: row[14],
            category_cooldown: row[15],
            charges: row[16],
            charge_cooldown: row[17],
            category: row[18],
            duration: row[19],
            max_stack: row[20],
            proc_chance: row[21],
            proc_charges: row[22],
            proc_flags: row[23],
            internal_cooldown: row[24],
            rppm: row[25],
            equipped_class: row[26],
            equipped_invtype_mask: row[27],
            equipped_subclass_mask: row[28],
            cast_min: row[29],
            cast_max: row[30],
            cast_div: row[31],
            c_scaling: row[32],
            c_scaling_level: row[33],
            replace_spell_id: row[34],
            attributes: row[35],
            class_flags: row[36],
            class_flags_family: row[37],
            stance_mask: row[38],
            mechanic: row[39],
            power_id: row[40],
            desc: row[41],
            tooltip: row[42],
            desc_vars: row[43],
            rank_str: row[44],
            req_max_level: row[45],
            identifierScore: 0
        };

        if (spell.name) {
            spell.identifier = getIdentifier(spell.name);
        }
        spellData.push(spell);
        spellDataById.set(spell.id, spell);
        if (!spell.identifier) continue;

        if (spell.cast_div > 0) spell.identifierScore ++;
        if (spell.spell_level > 0) spell.identifierScore++;
        if (spell.equipped_class > 0) spell.identifierScore++;
        if (spell.rank_str === "Racial") spell.identifierScore += 3;
    }

    for (const row of output.spelleffect_data_t) {
        const spellEffect: SpellEffectData = {
            id: row[0],
            hotfix: row[1],
            spell_id: row[2],
            index: row[3],
            type: row[4],
            subtype: row[5],
            m_avg: row[6],
            m_delta: row[7],
            m_unk: row[8],
            sp_coeff: row[9],
            ap_coeff: row[10],
            amplitude: row[11],
            radius: row[12],
            radius_max: row[13],
            base_value: row[14],
            misc_value: row[15],
            misc_value_2: row[16],
            class_flags: row[17],
            trigger_spell_id: row[18],
            m_chain: row[19],
            pp_combo_points: row[20],
            real_ppl: row[21],
            mechanic: row[22],
            chain_target: row[23],
            targeting_1: row[24],
            targeting_2: row[25],
            m_value: row[26]
        }
        const spell = spellDataById.get(spellEffect.spell_id);
        if (!spell.spellEffects) spell.spellEffects = [];
        spell.spellEffects.push(spellEffect);
        if (spellEffect.trigger_spell_id) {
            const triggerSpell = spellDataById.get(spellEffect.trigger_spell_id);
            if (!triggerSpell) {
                // console.log(`Can't find spell ${spellEffect.trigger_spell_id}`);
                continue;
            }
            if (triggerSpell.identifier === spell.identifier) {
                if (spell.tooltip) {
                    triggerSpell.identifier += "_trigger";
                }
                else if (isFriendlyTarget(spellEffect.targeting_1)) {
                    triggerSpell.identifier += "_buff";
                } else {
                    triggerSpell.identifier += "_debuff";
                }
            }
        }
    }

    for (const spell of spellData) {
        if (identifiers[spell.identifier]) {
            const other = spellDataById.get(identifiers[spell.identifier]);
            if (other.identifierScore > spell.identifierScore) continue;
        } 
        identifiers[spell.identifier] = spell.id;
    }

    for (const row of output.spellpower_data_t) {
        const spellPower: SpellPowerData = {
            id: row[0],
            spell_id: row[1],
            aura_id: row[2],
            hotfix: row[3],
            power_type: row[4],
            cost: row[5],
            cost_max: row[6],
            cost_per_tick: row[7],
            pct_cost: row[8],
            pct_cost_max: row[9],
            pct_cost_per_tick: row[10]
        };
        const spell = spellDataById.get(spellPower.spell_id);
        if (!spell.spellPowers) spell.spellPowers = [];
        spell.spellPowers.push(spellPower);
    }

    const talentsById = new Map<number, TalentData>();
    for (const row of output.talent_data_t) {
        const talent: TalentData = {
            name: row[0],
            id: row[1],
            flags: row[2],
            m_class: row[3],
            spec: row[4],
            col: row[5],
            row: row[6],
            spell_id: row[7],
            replace_id: row[8],
            identifier: getIdentifier(row[0]) + "_talent",
            talentId: 3 * row[6] + row[5] + 1
        };
        identifiers[talent.identifier] = talent.id;
        talentsById.set(talent.id, talent);
        if (talent.spell_id) {
            const spell = spellDataById.get(talent.spell_id);
            if (spell) {
                spell.talent = talent;
            }
        }
    }

    const azeriteTraitById = new Map<number, AzeriteTrait>();
    for (const row of output.azerite_power_entry_t) {
        const talent: AzeriteTrait = {
            id: row[0],
            spellId: row[1],
            name: row[2],
            identifier: getIdentifier(row[2]) + "_trait"
        };
        identifiers[talent.identifier] = talent.id;
        azeriteTraitById.set(talent.id, talent);
        if (talent.spellId) {
            const spell = spellDataById.get(talent.spellId);
            if (spell) {
                spell.azeriteTrait = talent;
            }
        }
    }

    const itemsById = new Map<number, ItemData>();
    for (const row of output.item_data_t) {
        const item: ItemData = {
            id: row[0],
            name: row[1],
            flags_1: row[2],
            flags_2: row[3],
            type_flags: row[4],
            level: row[5],
            req_level: row[6],
            req_skill: row[7],
            req_skill_level: row[8],
            quality: row[9],
            inventory_type: row[10],
            item_class: row[11],
            item_subclass: row[12],
            bind_type: row[13],
            delay: row[14],
            dmg_range: row[15],
            item_modifier: row[16],
            race_mask: row[17],
            class_mask: row[18],
            stat_type_e: row[19],
            stat_alloc: row[20],
            stat_socket_mul: row[21],
            trigger_spell: row[22],
            id_spell: row[23],
            cooldown_duration: row[24],
            cooldown_group: row[25],
            cooldown_group_duration: row[26],
            socket_color: row[27],
            gem_properties: row[28],
            id_socket_bonus: row[29],
            id_set: row[30],
            id_suffix_group: row[31],
            id_scaling_distribution: row[32],
            id_artifact: row[33],
            identifier: getIdentifier(row[1]) + '_item'
        }
        itemsById.set(item.id, item);
        identifiers[item.identifier] = item.id;
    }

writeFileSync("sample.json", JSON.stringify(spellData, undefined, 2), { encoding: "utf8"});

    return { spellData, spellDataById, identifiers, talentsById, itemsById, azeriteTraitById };
}