import { ClassId } from "@wowts/wow-mock";
import { SpecializationName } from "../states/PaperDoll";
import { LuaObj, LuaArray, pairs, lualength, ipairs, kpairs } from "@wowts/lua";
import {
    NodeType,
    AstAnnotation,
    AstAddFunctionNode,
    AstScriptNode,
    AstFunctionNode,
} from "../engine/AST";
import { TypeCheck } from "../tools/tools";
import { OvaleDataClass } from "../engine/Data";

export type ClassRole = "tank" | "spell" | "attack";
export type ClassType = string;

export type Result<T> = T | undefined;

export type Interrupts =
    | "mind_freeze"
    | "pummel"
    | "disrupt"
    | "skull_bash"
    | "solar_beam"
    | "rebuke"
    | "silence"
    | "mind_bomb"
    | "kick"
    | "wind_shear"
    | "counter_shot"
    | "muzzle"
    | "counterspell"
    | "spear_hand_strike";
export const interruptsClasses: { [k in Interrupts]: ClassId } = {
    mind_freeze: "DEATHKNIGHT",
    pummel: "WARRIOR",
    disrupt: "DEMONHUNTER",
    skull_bash: "DRUID",
    solar_beam: "DRUID",
    rebuke: "PALADIN",
    silence: "PRIEST",
    mind_bomb: "PRIEST",
    kick: "ROGUE",
    wind_shear: "SHAMAN",
    counter_shot: "HUNTER",
    counterspell: "MAGE",
    muzzle: "HUNTER",
    spear_hand_strike: "MONK",
};

interface SpecializationInfo {
    interrupt: Interrupts;
}

export type ClassInfo = { [key in SpecializationName]?: SpecializationInfo };

export const classInfos: { [key in ClassId]: ClassInfo } = {
    DEATHKNIGHT: {
        frost: { interrupt: "mind_freeze" },
        blood: { interrupt: "mind_freeze" },
        unholy: { interrupt: "mind_freeze" },
    },
    DEMONHUNTER: {
        havoc: { interrupt: "disrupt" },
        vengeance: { interrupt: "disrupt" },
    },
    DRUID: {
        guardian: { interrupt: "skull_bash" },
        feral: { interrupt: "skull_bash" },
        balance: { interrupt: "solar_beam" },
    },
    HUNTER: {
        beast_mastery: { interrupt: "counter_shot" },
        survival: { interrupt: "muzzle" },
        marksmanship: { interrupt: "counter_shot" },
    },
    MAGE: {
        frost: { interrupt: "counterspell" },
        fire: { interrupt: "counterspell" },
        arcane: { interrupt: "counterspell" },
    },
    MONK: {
        brewmaster: { interrupt: "spear_hand_strike" },
        windwalker: { interrupt: "spear_hand_strike" },
    },
    PALADIN: {
        retribution: { interrupt: "rebuke" },
        protection: { interrupt: "rebuke" },
    },
    PRIEST: {
        shadow: { interrupt: "silence" },
    },
    ROGUE: {
        assassination: { interrupt: "kick" },
        outlaw: { interrupt: "kick" },
        subtlety: { interrupt: "kick" },
    },
    SHAMAN: {
        elemental: { interrupt: "wind_shear" },
        enhancement: { interrupt: "wind_shear" },
    },
    WARLOCK: {},
    WARRIOR: {
        fury: { interrupt: "pummel" },
        protection: { interrupt: "pummel" },
        arms: { interrupt: "pummel" },
    },
};

export const CHARACTER_PROPERTY: LuaObj<string> = {
    // ["active_enemies"]: "Enemies()",
    // ["astral_power"]: "AstralPower()",
    // ["astral_power.deficit"]: "AstralPowerDeficit()",
    // ["blade_dance_worth_using"]: "0",
    // ["buff.arcane_charge.stack"]: "ArcaneCharges()",
    // ["buff.arcane_charge.max_stack"]: "MaxArcaneCharges()",
    // ["buff.movement.up"]: "Speed() > 0",
    // ["buff.out_of_range.up"]: "not target.InRange()",
    // ["bugs"]: "0",
    // ["chi"]: "Chi()",
    // ["chi.max"]: "MaxChi()",
    // ["combo_points"]: "ComboPoints()",
    // ["combo_points.deficit"]: "ComboPointsDeficit()",
    // ["combo_points.max"]: "MaxComboPoints()",
    // ["consecration.remains"]: "BuffRemaining(consecration)",
    // ["consecration.up"]: "BuffPresent(consecration)",
    // ["cooldown.army_of_the_dead.remains"]: "480", // always consider army of the dead to be on cooldown, this is to "fix" the UH DK script from working
    // ["cp_max_spend"]: "MaxComboPoints()",
    // ["crit_pct_current"]: "SpellCritChance()",
    // ["current_insanity_drain"]: "CurrentInsanityDrain()",
    // ["darkglare_no_de"]: "NotDeDemons(darkglare)",
    // ["death_and_decay.ticking"]: "BuffPresent(death_and_decay)",
    // ["death_sweep_worth_using"]: "0",
    // ["death_knight.disable_aotd"]: "0",
    // ["delay"]: "0",
    // ["demonic_fury"]: "DemonicFury()",
    // ["desired_targets"]: "Enemies(tagged=1)",
    // ["doomguard_no_de"]: "NotDeDemons(doomguard)",
    // ["dreadstalker_no_de"]: "NotDeDemons(dreadstalker)",
    // ["dreadstalker_remaining_duration"]: "DemonDuration(dreadstalker)",
    // ["eclipse_change"]: "TimeToEclipse()",
    // ["eclipse_energy"]: "EclipseEnergy()",
    // ["enemies"]: "Enemies()",
    // ["energy"]: "Energy()",
    // ["energy.deficit"]: "EnergyDeficit()",
    // ["energy.max"]: "MaxEnergy()",
    // ["energy.regen"]: "EnergyRegenRate()",
    // ["energy.time_to_max"]: "TimeToMaxEnergy()",
    // ["expected_combat_length"]: "600",
    // ["feral_spirit.remains"]: "TotemRemaining(sprit_wolf)",
    // ["finality"]: "HasArtifactTrait(finality)",
    // ["firestarter.remains"]: "target.TimeToHealthPercent(90)",
    // ["focus"]: "Focus()",
    // ["focus.deficit"]: "FocusDeficit()",
    // ["focus.max"]: "MaxFocus()",
    // ["focus.regen"]: "FocusRegenRate()",
    // ["focus.time_to_max"]: "TimeToMaxFocus()",
    // ["fury"]: "Fury()",
    // ["fury.deficit"]: "FuryDeficit()",
    // ["health"]: "Health()",
    // ["health.deficit"]: "HealthMissing()",
    // ["health.max"]: "MaxHealth()",
    // ["health.pct"]: "HealthPercent()",
    // ["health.percent"]: "HealthPercent()",
    // ["holy_power"]: "HolyPower()",
    // ["incanters_flow_time_to.5.up"]: "StackTimeTo(incanters_flow_buff 5 up)",
    // ["incanters_flow_time_to.5.any"]: "StackTimeTo(incanters_flow_buff 5 any)",
    // ["incanters_flow_time_to.4.down"]: "StackTimeTo(incanters_flow_buff 4 down)",
    // ["infernal_no_de"]: "NotDeDemons(infernal)",
    // ["insanity"]: "Insanity()",
    // ["level"]: "Level()",
    // ["lunar_max"]: "TimeToEclipse(lunar)",
    // ["mana"]: "Mana()",
    // ["mana.deficit"]: "ManaDeficit()",
    // ["mana.max"]: "MaxMana()",
    // ["mana.pct"]: "ManaPercent()",
    // ["mana.time_to_max"]: "TimeToMaxMana()",
    // ["maelstrom"]: "Maelstrom()",
    // ["next_wi_bomb.pheromone"]: "SpellUsable(270323)",
    // ["next_wi_bomb.shrapnel"]: "SpellUsable(270335)",
    // ["next_wi_bomb.volatile"]: "SpellUsable(271045)",
    // ["nonexecute_actors_pct"]: "0",
    // ["pain"]: "Pain()",
    // ["pain.deficit"]: "PainDeficit()",
    // ["pet_count"]: "Demons()",
    // ["pet.apoc_ghoul.active"]: "0",
    // ["rage"]: "Rage()",
    // ["rage.deficit"]: "RageDeficit()",
    // ["rage.max"]: "MaxRage()",
    // ["raid_event.adds.remains"]: "0", // TODO
    // ["raid_event.invulnerable.exists"]: "0", //TODO
    // ["raw_haste_pct"]: "SpellCastSpeedPercent()",
    // ["rtb_list.any.5"]: "BuffCount(roll_the_bones_buff more 4)",
    // ["rtb_list.any.6"]: "BuffCount(roll_the_bones_buff more 5)",
    // ["rune.deficit"]: "RuneDeficit()",
    // ["runic_power"]: "RunicPower()",
    // ["runic_power.deficit"]: "RunicPowerDeficit()",
    // ["service_no_de"]: "0",
    // ["shadow_orb"]: "ShadowOrbs()",
    // ["sigil_placed"]: "SigilCharging(flame)",
    // ["solar_max"]: "TimeToEclipse(solar)",
    // ["soul_shard"]: "SoulShards()",
    // ["soul_fragments"]: "SoulFragments()",
    // ["ssw_refund_offset"]: "target.Distance() % 3 - 1",
    // ["stat.mastery_rating"]: "MasteryRating()",
    // ["stealthed"]: "Stealthed()",
    // ["stealthed.all"]: "Stealthed()",
    // ["stealthed.rogue"]: "Stealthed()",
    // ["target.debuff.casting.react"]: "target.Casting(harmful)",
    // ["time"]: "TimeInCombat()",
    // ["time_to_20pct"]: "TimeToHealthPercent(20)",
    // ["time_to_pct_30"]: "TimeToHealthPercent(30)",
    // ["time_to_die"]: "TimeToDie()",
    // ["time_to_die.remains"]: "TimeToDie()",
    // ["time_to_shard"]: "TimeToShard()",
    // ["time_to_sht.4"]: "100", // TODO
    // ["time_to_sht.5"]: "100",
    // ["variable.disable_combustion"]: "0", // TODO: undefined variables in SimulationCraft
    // ["wild_imp_count"]: "Demons(wild_imp)",
    // ["wild_imp_no_de"]: "NotDeDemons(wild_imp)",
    // ["wild_imp_remaining_duration"]: "DemonDuration(wild_imp)",
    // ["buff.executioners_precision.stack"]:"0"
};

export interface Modifiers {
    ammo_type?: ParseNode;
    animation_cancel?: ParseNode;
    attack_speed?: ParseNode;
    cancel_if?: ParseNode;
    chain?: ParseNode;
    choose?: ParseNode;
    condition?: ParseNode;
    cooldown?: ParseNode;
    cooldown_stddev?: ParseNode;
    cycle_targets?: ParseNode;
    damage?: ParseNode;
    default?: ParseNode;
    delay?: ParseNode;
    dynamic_prepot?: ParseNode;
    early_chain_if?: ParseNode;
    effect_name?: ParseNode;
    extra_amount?: ParseNode;
    five_stacks?: ParseNode;
    for_next?: ParseNode;
    if?: ParseNode;
    interrupt?: ParseNode;
    interrupt_global?: ParseNode;
    interrupt_if?: ParseNode;
    interrupt_immediate?: ParseNode;
    interval?: ParseNode;
    lethal?: ParseNode;
    line_cd?: ParseNode;
    max_cycle_targets?: ParseNode;
    max_energy?: ParseNode;
    min_frenzy?: ParseNode;
    moving?: ParseNode;
    name?: ParseNode;
    nonlethal?: ParseNode;
    only_cwc?: ParseNode;
    op?: ParseNode;
    pct_health?: ParseNode;
    precombat?: ParseNode;
    precombat_seconds?: ParseNode; //todo
    precombat_time?: ParseNode;
    precast_time?: ParseNode; //todo
    range?: ParseNode;
    sec?: ParseNode;
    slot?: ParseNode;
    slots?: ParseNode;
    strikes?: ParseNode;
    sync?: ParseNode;
    sync_weapons?: ParseNode;
    target?: ParseNode;
    target_if?: ParseNode;
    target_if_first?: ParseNode;
    target_if_max?: ParseNode;
    target_if_min?: ParseNode;
    toggle?: ParseNode;
    travel_speed?: ParseNode;
    type?: ParseNode;
    use_off_gcd?: ParseNode;
    use_while_casting?: ParseNode;
    value?: ParseNode;
    value_else?: ParseNode;
    wait?: ParseNode;
    wait_on_ready?: ParseNode;
    weapon?: ParseNode;
}

export type Modifier = keyof Modifiers;

export type ParseNodeType =
    | "action"
    | "action_list"
    | "arithmetic"
    | "compare"
    | "function"
    | "logical"
    | "number"
    | "operand";

export type SimcBinaryOperatorType =
    | "|"
    | "^"
    | "&"
    | "!="
    | "<"
    | "<="
    | "="
    | "=="
    | ">"
    | ">="
    | "~"
    | "!~"
    | "+"
    | "%"
    | "*"
    | "-"
    | ">?"
    | "<?"
    | "%%";
export type SimcUnaryOperatorType = "!" | "-" | "@";
export type SimcOperatorType = SimcUnaryOperatorType | SimcBinaryOperatorType;

interface BaseParseNode {
    nodeId: number;
    asType: NodeType;

    // TODO Used by ActionParseNode, ActionListParseNode, and FunctionParseNode
    name?: string;

    // TODO: used to add parenthesis around the node
    // Need to remove that because that's ugly
    left?: string;
    right?: string;
}

export interface ActionParseNode extends BaseParseNode {
    type: "action";
    name: string;
    action: string;
    modifiers: Modifiers;
    actionListName: string;
}

interface BaseParseNodeWithChilds<T extends ParseNode> extends BaseParseNode {
    child: LuaArray<T>;
}

export interface ActionListParseNode
    extends BaseParseNodeWithChilds<ActionParseNode> {
    type: "action_list";
    name: string;
}

export interface OperatorParseNode extends BaseParseNode {
    type: "operator";
    expressionType: "unary" | "binary";
    operator: SimcOperatorType;
    child: LuaArray<ParseNode>;
    precedence: number;
    operatorType: "arithmetic" | "compare" | "logical";
}

export interface FunctionParseNode extends BaseParseNode {
    type: "function";
    name: string;
    child: LuaArray<ParseNode>;
}

export interface NumberParseNode extends BaseParseNode {
    type: "number";
    value: number;
}

export interface OperandParseNode extends BaseParseNode {
    type: "operand";
    name: string;
    asType: "boolean" | "value";
    rune?: string;
    includeDeath?: boolean;
}

export type ParseNodeWithChilds =
    | FunctionParseNode
    | ActionListParseNode
    | OperatorParseNode;

export type ParseNode =
    | ActionParseNode
    | ActionListParseNode
    | OperatorParseNode
    | FunctionParseNode
    | NumberParseNode
    | OperandParseNode;

// export interface ParseNode {
//     name: string;
//     child: LuaArray<ParseNode>;
//     modifiers: Modifiers;
//     rune?: string;
//     asType: NodeType;
//     type: ParseNodeType;

//     // Not sure
//     value: number;
//     expressionType: "unary" | "binary";

//     // Dubious
//     operator: SimcOperatorType;
//     includeDeath: boolean;
//     left: string;
//     right: string;
//     action: string;
//     nodeId: number;
//     precedence: number;
// }

export interface ProfileStrings {
    spec?: SpecializationName;
    level?: string;
    default_pet?: string;
    role?: ClassRole;
    talents?: string;
    glyphs?: string;
}

export interface ProfileLists {
    ["actions.precombat"]?: string;
}

export interface Profile extends ProfileStrings, ProfileLists {
    templates: LuaArray<keyof Profile>;
    position?: "ranged_back";
    actionList?: LuaArray<ActionListParseNode>;
    annotation: Annotation;
}

export const KEYWORD: LuaObj<boolean> = {};
export const MODIFIER_KEYWORD: TypeCheck<Modifiers> = {
    ["ammo_type"]: true,
    ["animation_cancel"]: true,
    ["attack_speed"]: true,
    ["cancel_if"]: true,
    ["chain"]: true,
    ["choose"]: true,
    ["condition"]: true,
    ["cooldown"]: true,
    ["cooldown_stddev"]: true,
    ["cycle_targets"]: true,
    ["damage"]: true,
    ["delay"]: true,
    default: true,
    ["dynamic_prepot"]: true,
    ["early_chain_if"]: true,
    ["effect_name"]: true,
    ["extra_amount"]: true,
    ["five_stacks"]: true,
    ["for_next"]: true,
    ["if"]: true,
    ["interrupt"]: true,
    ["interrupt_global"]: true,
    ["interrupt_if"]: true,
    ["interrupt_immediate"]: true,
    ["interval"]: true,
    ["lethal"]: true,
    ["line_cd"]: true,
    ["max_cycle_targets"]: true,
    ["max_energy"]: true,
    ["min_frenzy"]: true,
    ["moving"]: true,
    ["name"]: true,
    ["nonlethal"]: true,
    ["op"]: true,
    only_cwc: true,
    ["pct_health"]: true,
    ["precombat"]: true,
    ["precombat_seconds"]: true, //todo
    precombat_time: true,
    ["precast_time"]: true, //todo
    ["range"]: true,
    ["sec"]: true,
    ["slot"]: true,
    ["slots"]: true,
    ["strikes"]: true,
    ["sync"]: true,
    ["sync_weapons"]: true,
    ["target"]: true,
    ["target_if"]: true,
    ["target_if_first"]: true,
    ["target_if_max"]: true,
    ["target_if_min"]: true,
    ["toggle"]: true,
    ["travel_speed"]: true,
    ["type"]: true,
    ["use_off_gcd"]: true,
    ["use_while_casting"]: true,
    ["value"]: true,
    ["value_else"]: true,
    ["wait"]: true,
    ["wait_on_ready"]: true,
    ["weapon"]: true,
};
export const LITTERAL_MODIFIER: LuaObj<boolean> = {
    ["name"]: true,
};
export const FUNCTION_KEYWORD: LuaObj<boolean> = {
    ["ceil"]: true,
    ["floor"]: true,
};
export const SPECIAL_ACTION: LuaObj<boolean> = {
    ["apply_poison"]: true,
    ["auto_attack"]: true,
    ["call_action_list"]: true,
    ["cancel_buff"]: true,
    ["cancel_metamorphosis"]: true,
    ["cycling_variable"]: true,
    ["exotic_munitions"]: true,
    ["flask"]: true,
    ["food"]: true,
    ["health_stone"]: true,
    ["pool_resource"]: true,
    ["potion"]: true,
    ["run_action_list"]: true,
    ["sequence"]: true,
    ["snapshot_stats"]: true,
    ["stance"]: true,
    ["start_moving"]: true,
    ["stealth"]: true,
    ["stop_moving"]: true,
    ["strict_sequence"]: true,
    ["swap_action_list"]: true,
    ["use_items"]: true,
    ["use_item"]: true,
    ["variable"]: true,
    ["wait"]: true,
};

export const enum MiscOperandModifierType {
    Suffix,
    Prefix,
    Parameter,
    Remove,
    Replace,
    Code,
    Symbol,
}

interface MiscOperandModifier {
    name?: string;
    type: MiscOperandModifierType;
    extraParameter?: number | string;
    extraSymbol?: string;
    createOptions?: boolean;
    code?: string;
    symbolsInCode?: LuaArray<string>;
}

const powerModifiers: LuaObj<MiscOperandModifier> = {
    ["max"]: { type: MiscOperandModifierType.Prefix },
    ["deficit"]: { type: MiscOperandModifierType.Suffix },
    ["pct"]: { name: "percent", type: MiscOperandModifierType.Suffix },
    ["regen"]: { name: "regenrate", type: MiscOperandModifierType.Suffix },
    ["time_to_50"]: {
        name: "timeto",
        type: MiscOperandModifierType.Prefix,
        extraParameter: 50,
    },
    ["time_to_max"]: {
        name: "timetomax",
        type: MiscOperandModifierType.Prefix,
    },
};

export interface MiscOperand {
    name?: string;
    modifiers?: LuaObj<MiscOperandModifier>;
    symbol?: string;
    extraParameter?: number | string;
    extraNamedParameter?: {
        name: keyof AstFunctionNode["rawNamedParams"];
        value: number | string;
    };
    extraSymbol?: string;
    code?: string;
    symbolsInCode?: LuaArray<string>;
}

export const MISC_OPERAND: LuaObj<MiscOperand> = {
    ["active_enemies"]: { name: "enemies" },
    ["active_bt_triggers"]: { name: "buffcount", extraSymbol: "bt_buffs" },
    ["animacharged_cp"]: { name: "maxcombopoints" },
    ["astral_power"]: { name: "astralpower", modifiers: powerModifiers },
    ["ca_active"]: {
        code: "talent(careful_aim_talent) and targethealthpercent() > 70",
        symbolsInCode: {
            1: "careful_aim_talent",
        },
    },
    ["chi"]: { name: "chi", modifiers: powerModifiers },
    ["combo_points"]: { name: "combopoints", modifiers: powerModifiers },
    ["conduit"]: {
        symbol: "conduit",
        modifiers: {
            enabled: { type: MiscOperandModifierType.Remove },
            rank: { type: MiscOperandModifierType.Suffix },
        },
    },
    ["consecration"]: {
        name: "buff",
        modifiers: {
            up: { type: MiscOperandModifierType.Suffix, name: "present" },
        },
        extraSymbol: "consecration",
    },
    ["covenant"]: {
        name: "iscovenant",
        modifiers: {
            enabled: { type: MiscOperandModifierType.Remove },
        },
        symbol: "",
    },
    ["cp_max_spend"]: { name: "maxcombopoints" },
    ["death_knight"]: {
        symbol: "enchant",
        name: "checkboxon",
        modifiers: {
            runeforge: {
                type: MiscOperandModifierType.Replace,
                name: "weaponenchantpresent",
            },
            disable_aotd: {
                type: MiscOperandModifierType.Parameter,
                name: "disable_aotd",
                createOptions: true,
            },
            fwounded_targets: {
                type: MiscOperandModifierType.Replace,
                code: "buffcountonany",
                extraSymbol: "festering_wound_debuff",
            },
        },
    },
    ["death_and_decay"]: {
        modifiers: {
            ticking: {
                type: MiscOperandModifierType.Replace,
                name: "buffpresent",
            },
        },
        extraSymbol: "death_and_decay",
    },
    ["demon_soul_fragments"]: {
        name: "soulfragments", // GREATER/demon
    },
    ["desired_targets"]: {
        name: "enemies",
        extraNamedParameter: { name: "tagged", value: 1 },
    },
    ["druid"]: {
        name: "checkboxon",
        modifiers: {
            catweave_bear: {
                type: MiscOperandModifierType.Parameter,
                createOptions: true,
            },
            owlweave_bear: {
                type: MiscOperandModifierType.Parameter,
                createOptions: true,
            },
            ticks_gained_on_refresh: {
                type: MiscOperandModifierType.Replace,
                name: "ticksgainedonrefresh",
            },
        },
        symbol: "",
    },
    ["eclipse"]: {
        modifiers: {
            in_lunar: {
                type: MiscOperandModifierType.Replace,
                name: "buffpresent",
                extraSymbol: "eclipse_lunar",
            },
            in_solar: {
                type: MiscOperandModifierType.Replace,
                name: "buffpresent",
                extraSymbol: "eclipse_solar",
            },
            solar_in_1: {
                type: MiscOperandModifierType.Code,
                code: "counter(solar) == 1",
            },
            solar_next: {
                type: MiscOperandModifierType.Code,
                code: "counter(solar) == 1",
            },
            lunar_in_1: {
                type: MiscOperandModifierType.Replace,
                code: "counter(lunar) == 1",
            },
            lunar_next: {
                type: MiscOperandModifierType.Replace,
                code: "counter(lunar) == 1",
            },
            any_next: {
                type: MiscOperandModifierType.Code,
                code: "counter(lunar) + counter(solar) == 1",
            },
            in_any: {
                type: MiscOperandModifierType.Replace,
                name: "buffpresent",
                extraSymbol: "eclipse_any",
            },
            in_both: {
                type: MiscOperandModifierType.Code,
                code:
                    "buffpresent(eclipse_solar) and buffpresent(eclipse_lunar)",
                symbolsInCode: { 1: "eclipse_solar", 2: "eclipse_lunar" },
            },
        },
    },
    ["energy"]: { name: "energy", modifiers: powerModifiers },
    ["expected_combat_length"]: { name: "expectedcombatlength" },
    ["exsanguinated"]: {
        name: "targetdebuffremaining",
        symbol: "exsanguinated",
    },
    ["fight_remains"]: { name: "fightremains" },
    ["firestarter"]: {
        modifiers: {
            remains: {
                type: MiscOperandModifierType.Replace,
                name: "TargetTimeToHealthPercent",
                extraParameter: 90,
            },
        },
    },
    ["focus"]: { name: "focus", modifiers: powerModifiers },
    ["fury"]: { name: "fury", modifiers: powerModifiers },
    ["health"]: {
        modifiers: { max: { type: MiscOperandModifierType.Prefix } },
    },
    ["holy_power"]: { name: "holypower", modifiers: powerModifiers },
    ["incoming_imps"]: { name: "impsspawnedduring" },
    ["hot_streak_spells_in_flight"]: {
        name: "inflighttotarget",
        extraSymbol: "hot_streak",
    },
    ["interpolated_fight_remains"]: { name: "fightremains" },
    ["insanity"]: { name: "insanity", modifiers: powerModifiers },
    ["level"]: { name: "level" },
    ["maelstrom"]: { name: "maelstrom", modifiers: powerModifiers },
    ["mana"]: { name: "mana", modifiers: powerModifiers },
    ["next_wi_bomb"]: {
        name: "buffpresent",
        symbol: "bomb",
    },
    ["pain"]: { name: "pain", modifiers: powerModifiers },
    ["priest"]: {
        name: "checkboxon",
        modifiers: {
            self_power_infusion: {
                type: MiscOperandModifierType.Parameter,
                createOptions: true,
            },
        },
    },
    ["rage"]: { name: "rage", modifiers: powerModifiers },
    ["remaining_winters_chill"]: {
        name: "buffstacks",
        extraSymbol: "winters_chill",
    },
    ["rune"]: { name: "rune", modifiers: powerModifiers },
    ["runeforge"]: {
        modifiers: {
            equipped: { type: MiscOperandModifierType.Prefix },
        },
        symbol: "runeforge",
    },
    ["runic_power"]: { name: "runicpower", modifiers: powerModifiers },
    ["soul_fragments"]: { name: "soulfragments", modifiers: powerModifiers },
    ["soul_shard"]: { name: "soulshards", modifiers: powerModifiers },
    ["soulbind"]: {
        modifiers: { enabled: { type: MiscOperandModifierType.Prefix } },
        symbol: "soulbind",
    },
    ["stagger"]: {
        modifiers: {
            last_tick_damage_4: {
                name: "tick",
                type: MiscOperandModifierType.Suffix,
            },
            pct: {
                name: "percent",
                type: MiscOperandModifierType.Suffix,
            },
            amounttototalpct: {
                name: "missingpercent",
                type: MiscOperandModifierType.Suffix,
            },
        },
    },
    ["stealthed"]: {
        name: "buffpresent",
        modifiers: {
            all: {
                name: "stealthed_buff",
                type: MiscOperandModifierType.Symbol,
            },
            rogue: {
                type: MiscOperandModifierType.Symbol,
                name: "rogue_stealthed_buff",
            },
            mantle: {
                name: "mantle_stealthed_buff",
                type: MiscOperandModifierType.Symbol,
            },
        },
    },
    ["time"]: { name: "timeincombat" },
    ["time_to_shard"]: { name: "timetoshard" },
};
export const RUNE_OPERAND: LuaObj<string> = {
    ["rune"]: "rune",
};
export const CONSUMABLE_ITEMS: LuaObj<boolean> = {
    ["potion"]: true,
    ["food"]: true,
    ["flask"]: true,
    ["augmentation"]: true,
};
{
    for (const [keyword, value] of kpairs(MODIFIER_KEYWORD)) {
        KEYWORD[keyword] = value;
    }
    for (const [keyword, value] of pairs(FUNCTION_KEYWORD)) {
        KEYWORD[keyword] = value;
    }
    for (const [keyword, value] of pairs(SPECIAL_ACTION)) {
        KEYWORD[keyword] = value;
    }
}
export const UNARY_OPERATOR: {
    [k in SimcUnaryOperatorType]: { 1: "logical" | "arithmetic"; 2: number };
} = {
    ["!"]: {
        1: "logical",
        2: 15,
    },
    ["-"]: {
        1: "arithmetic",
        2: 50,
    },
    ["@"]: {
        1: "arithmetic",
        2: 50,
    },
};
export const BINARY_OPERATOR: {
    [k in SimcBinaryOperatorType]: {
        1: "logical" | "compare" | "arithmetic";
        2: number;
        3?: "associative";
    };
} = {
    ["|"]: {
        1: "logical",
        2: 5,
        3: "associative",
    },
    ["^"]: {
        1: "logical",
        2: 8,
        3: "associative",
    },
    ["&"]: {
        1: "logical",
        2: 10,
        3: "associative",
    },
    ["!="]: {
        1: "compare",
        2: 20,
    },
    ["<"]: {
        1: "compare",
        2: 20,
    },
    ["<="]: {
        1: "compare",
        2: 20,
    },
    ["="]: {
        1: "compare",
        2: 20,
    },
    ["=="]: {
        1: "compare",
        2: 20,
    },
    [">"]: {
        1: "compare",
        2: 20,
    },
    [">="]: {
        1: "compare",
        2: 20,
    },
    ["~"]: {
        1: "compare",
        2: 20,
    },
    ["!~"]: {
        1: "compare",
        2: 20,
    },
    ["+"]: {
        1: "arithmetic",
        2: 30,
        3: "associative",
    },
    ["-"]: {
        1: "arithmetic",
        2: 30,
    },
    ["%"]: {
        1: "arithmetic",
        2: 40,
    },
    ["*"]: {
        1: "arithmetic",
        2: 40,
        3: "associative",
    },
    [">?"]: {
        1: "arithmetic",
        2: 25,
        3: "associative",
    },
    ["<?"]: {
        1: "arithmetic",
        2: 25,
        3: "associative",
    },
    ["%%"]: {
        1: "arithmetic",
        2: 40,
    },
};

export interface OptionalSkill {
    class: string;
    default?: boolean;
    specialization?: string;
}

export const OPTIONAL_SKILLS = {
    ["fel_rush"]: <OptionalSkill>{
        class: "DEMONHUNTER",
        default: true,
    },
    ["vengeful_retreat"]: <OptionalSkill>{
        class: "DEMONHUNTER",
        default: true,
    },
    ["volley"]: <OptionalSkill>{
        class: "HUNTER",
        default: true,
    },
    ["harpoon"]: <OptionalSkill>{
        class: "HUNTER",
        specialization: "survival",
        default: true,
    },
    ["blink"]: <OptionalSkill>{
        class: "MAGE",
        default: false,
    },
    ["time_warp"]: <OptionalSkill>{
        class: "MAGE",
    },
    ["storm_earth_and_fire"]: <OptionalSkill>{
        class: "MONK",
        default: true,
    },
    ["chi_burst"]: <OptionalSkill>{
        class: "MONK",
        default: true,
    },
    ["touch_of_karma"]: <OptionalSkill>{
        class: "MONK",
        default: false,
    },
    ["flying_serpent_kick"]: <OptionalSkill>{
        class: "MONK",
        default: true,
    },
    ["vanish"]: <OptionalSkill>{
        class: "ROGUE",
        specialization: "assassination",
        default: true,
    },
    ["blade_flurry"]: <OptionalSkill>{
        class: "ROGUE",
        specialization: "outlaw",
        default: true,
    },
    ["bloodlust"]: <OptionalSkill>{
        class: "SHAMAN",
    },
    ["shield_of_vengeance"]: <OptionalSkill>{
        class: "PALADIN",
        specialization: "retribution",
        default: false,
    },
};

export function checkOptionalSkill(
    action: string,
    className: string,
    specialization: string
): action is keyof typeof OPTIONAL_SKILLS {
    const data = OPTIONAL_SKILLS[<keyof typeof OPTIONAL_SKILLS>action];
    if (!data) {
        return false;
    }
    if (data.specialization && data.specialization != specialization) {
        return false;
    }
    if (data.class && data.class != className) {
        return false;
    }
    return true;
}

export type InterruptAnnotation = { [key in Interrupts]?: ClassId };

export class Annotation implements InterruptAnnotation {
    mind_freeze?: ClassId;
    pummel?: ClassId;
    disrupt?: ClassId;
    skull_bash?: ClassId;
    solar_beam?: ClassId;
    rebuke?: ClassId;
    silence?: ClassId;
    mind_bomb?: ClassId;
    kick?: ClassId;
    wind_shear?: ClassId;
    counter_shot?: ClassId;
    muzzle?: ClassId;
    counterspell?: ClassId;
    spear_hand_strike?: ClassId;

    level?: string;
    pet?: string;
    consumables: LuaObj<string> = {};
    role?: ClassRole;
    melee?: ClassType;
    ranged?: ClassType;
    position?: string;
    taggedFunctionName: LuaObj<boolean> = {};
    functionTag: LuaObj<"cd" | "shortcd"> = {};
    nodeList?: LuaArray<ParseNode>;

    astAnnotation: AstAnnotation;
    dictionaryAST?: AstScriptNode;
    dictionary: LuaObj<number | string> = {};
    supportingFunctionCount?: number;
    supportingInterruptCount?: number;
    supportingControlCount?: number;
    supportingDefineCount?: number;
    symbolTable?: LuaObj<boolean>;
    operand?: LuaArray<ParseNode>;

    sync?: LuaObj<ActionParseNode>;

    using_apl?: LuaObj<boolean>;
    currentVariable?: AstAddFunctionNode;
    variable: LuaObj<AstAddFunctionNode> = {};

    trap_launcher?: string;
    interrupt?: string;
    wild_charge?: string;
    use_legendary_ring?: string;
    options?: LuaObj<boolean>;
    opt_priority_rotation?: string;
    time_to_hpg_heal?: string;
    time_to_hpg_melee?: string;
    time_to_hpg_tank?: string;
    bloodlust?: string;
    use_item?: boolean;
    summon_pet?: string;
    storm_earth_and_fire?: string;
    touch_of_death?: string;
    flying_serpent_kick?: string;
    opt_use_consumables?: string;
    blade_flurry?: string;
    blink?: string;
    time_warp?: string;
    vanish?: string;
    volley?: string;
    harpoon?: string;
    chi_burst?: string;
    touch_of_karma?: string;
    fel_rush?: string;
    vengeful_retreat?: string;
    shield_of_vengeance?: string;
    symbolList: LuaArray<string> = {};

    constructor(
        private ovaleData: OvaleDataClass,
        public name: string,
        public classId: ClassId,
        public specialization: SpecializationName
    ) {
        this.astAnnotation = { nodeList: {}, definition: this.dictionary };
    }

    public AddSymbol(symbol: string) {
        const symbolTable = this.symbolTable || {};
        const symbolList = this.symbolList;
        if (
            !symbolTable[symbol] &&
            !this.ovaleData.DEFAULT_SPELL_LIST[symbol]
        ) {
            symbolTable[symbol] = true;
            symbolList[lualength(symbolList) + 1] = symbol;
        }
        this.symbolTable = symbolTable;
        this.symbolList = symbolList;
    }
}

export const OVALE_TAGS: LuaArray<string> = {
    1: "main",
    2: "shortcd",
    3: "cd",
};
const OVALE_TAG_PRIORITY: LuaObj<number> = {};
for (const [i, tag] of ipairs(OVALE_TAGS)) {
    OVALE_TAG_PRIORITY[tag] = i * 10;
}

export function TagPriority(tag: string) {
    return OVALE_TAG_PRIORITY[tag] || 10;
}
