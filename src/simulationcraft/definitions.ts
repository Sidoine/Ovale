import { ClassId } from "@wowts/wow-mock";
import { SpecializationName } from "../PaperDoll";
import { LuaObj, LuaArray, pairs, lualength, ipairs, kpairs } from "@wowts/lua";
import { AstNode, NodeType, AstAnnotation } from "../AST";
import { TypeCheck } from "../tools";
import { OvaleDataClass } from "../Data";

export type ClassRole = "tank" | "spell" | "attack";
export type ClassType = string;

export type Result<T> = T | undefined;

export type Interrupts = "mind_freeze" | "pummel" | "disrupt" | "skull_bash" | "solar_beam" |
    "rebuke" | "silence" | "mind_bomb" | "kick" | "wind_shear" | "counter_shot" | "muzzle" |
    "counterspell" | "spear_hand_strike";
export const interruptsClasses: { [k in Interrupts]: ClassId } = {
    "mind_freeze": "DEATHKNIGHT",
    "pummel": "WARRIOR",
    "disrupt": "DEMONHUNTER",
    "skull_bash": "DRUID",
    "solar_beam": "DRUID",
    "rebuke": "PALADIN",
    "silence": "PRIEST",
    "mind_bomb": "PRIEST",
    "kick": "ROGUE",
    "wind_shear": "SHAMAN",
    "counter_shot": "HUNTER",
    "counterspell": "MAGE",
    "muzzle": "HUNTER",
    "spear_hand_strike": "MONK"
}

interface SpecializationInfo {
    interrupt: Interrupts;
}

export type ClassInfo = { [key in SpecializationName]?: SpecializationInfo }

export const classInfos: { [key in ClassId]: ClassInfo} = {
    DEATHKNIGHT: {
        "frost": { interrupt: "mind_freeze" },
        "blood": { interrupt: "mind_freeze" },
        "unholy": { interrupt: "mind_freeze"}
    },
    DEMONHUNTER: {
        "havoc": { interrupt: "disrupt" },
        "vengeance": { interrupt: "disrupt"}
    },
    DRUID: {
        "guardian": { interrupt: "skull_bash" },
        "feral": { interrupt: "skull_bash" },
        "balance": {interrupt: "solar_beam"}
    },
    HUNTER: {
        "beast_mastery": { interrupt: "counter_shot" },
        "survival": { interrupt: "muzzle" },
        "marksmanship": { interrupt: "counter_shot"}
    },
    MAGE: {
        "frost": {interrupt: "counterspell"},
        "fire": { interrupt: "counterspell" },
        "arcane": {interrupt: "counterspell"}
    },
    MONK: {
        "brewmaster": { interrupt: "spear_hand_strike" },
        "windwalker": { interrupt: "spear_hand_strike"}
    },
    PALADIN: {
        "retribution": { interrupt: "rebuke" },
        "protection": { interrupt: "rebuke"}
    },
    PRIEST: {
        "shadow": { interrupt: "silence"}
    },
    ROGUE: {
        "assassination": { interrupt: "kick" },
        "outlaw": { interrupt: "kick" },
        "subtlety": {interrupt: "kick"}
    },
    SHAMAN: {
        "elemental": { interrupt: "wind_shear" },
        "enhancement": {interrupt: "wind_shear"}
    },
    WARLOCK: {
    },
    WARRIOR: {
        "fury": { interrupt: "pummel" },
        "protection": { interrupt: "pummel" },
        "arms": { interrupt: "pummel"}
    }
}

export const CHARACTER_PROPERTY: LuaObj<string> = {
    ["active_enemies"]: "Enemies()",
    ["astral_power"]: "AstralPower()",
    ["astral_power.deficit"]: "AstralPowerDeficit()",
    ["blade_dance_worth_using"]: "0",
    ["buff.arcane_charge.stack"]: "ArcaneCharges()",
    ["buff.arcane_charge.max_stack"]: "MaxArcaneCharges()",
    ["buff.movement.up"]: "Speed() > 0",
    ["buff.out_of_range.up"]: "not target.InRange()",
    ["bugs"]: "0",
    ["chi"]: "Chi()",
    ["chi.max"]: "MaxChi()",
    ["combo_points"]: "ComboPoints()",
    ["combo_points.deficit"]: "ComboPointsDeficit()",
    ["combo_points.max"]: "MaxComboPoints()",
    ["consecration.remains"]: "BuffRemaining(consecration)",
    ["consecration.up"]: "BuffPresent(consecration)",
	["cooldown.army_of_the_dead.remains"]: "480", // always consider army of the dead to be on cooldown, this is to "fix" the UH DK script from working
    ["cp_max_spend"]: "MaxComboPoints()",
    ["crit_pct_current"]: "SpellCritChance()",
    ["current_insanity_drain"]: "CurrentInsanityDrain()",
    ["darkglare_no_de"]: "NotDeDemons(darkglare)",
    ["death_and_decay.ticking"]: "BuffPresent(death_and_decay)",
    ["death_sweep_worth_using"]: "0",
    ["death_knight.disable_aotd"]: "0",
    ["delay"]: "0",
    ["demonic_fury"]: "DemonicFury()",
    ["desired_targets"]: "Enemies(tagged=1)",
    ["doomguard_no_de"]: "NotDeDemons(doomguard)",
    ["dreadstalker_no_de"]: "NotDeDemons(dreadstalker)",
    ["dreadstalker_remaining_duration"]: "DemonDuration(dreadstalker)",
    ["eclipse_change"]: "TimeToEclipse()",
    ["eclipse_energy"]: "EclipseEnergy()",
    ["enemies"]: "Enemies()",
    ["energy"]: "Energy()",
    ["energy.deficit"]: "EnergyDeficit()",
    ["energy.max"]: "MaxEnergy()",
    ["energy.regen"]: "EnergyRegenRate()",
    ["energy.time_to_max"]: "TimeToMaxEnergy()",
    ["expected_combat_length"]: "600",
    ["feral_spirit.remains"]: "TotemRemaining(sprit_wolf)",
    ["finality"]: "HasArtifactTrait(finality)",
    ["firestarter.remains"]: "target.TimeToHealthPercent(90)",
    ["focus"]: "Focus()",
    ["focus.deficit"]: "FocusDeficit()",
    ["focus.max"]: "MaxFocus()",
    ["focus.regen"]: "FocusRegenRate()",
    ["focus.time_to_max"]: "TimeToMaxFocus()",
    ["fury"]: "Fury()",
    ["fury.deficit"]: "FuryDeficit()",
    ["health"]: "Health()",
    ["health.deficit"]: "HealthMissing()",
    ["health.max"]: "MaxHealth()",
    ["health.pct"]: "HealthPercent()",
    ["health.percent"]: "HealthPercent()",
    ["holy_power"]: "HolyPower()",
    ["incanters_flow_time_to.5.up"]: "StackTimeTo(incanters_flow_buff 5 up)",
    ["incanters_flow_time_to.4.down"]: "StackTimeTo(incanters_flow_buff 4 down)",
    ["infernal_no_de"]: "NotDeDemons(infernal)",
    ["insanity"]: "Insanity()",
    ["level"]: "Level()",
    ["lunar_max"]: "TimeToEclipse(lunar)",
    ["mana"]: "Mana()",
    ["mana.deficit"]: "ManaDeficit()",
    ["mana.max"]: "MaxMana()",
    ["mana.pct"]: "ManaPercent()",
	["mana.time_to_max"]: "TimeToMaxMana()",
    ["maelstrom"]: "Maelstrom()",
    ["next_wi_bomb.pheromone"]: "SpellUsable(270323)",
    ["next_wi_bomb.shrapnel"]: "SpellUsable(270335)",
    ["next_wi_bomb.volatile"]: "SpellUsable(271045)",
    ["nonexecute_actors_pct"]: "0",
    ["pain"]: "Pain()",
    ["pain.deficit"]: "PainDeficit()",
    ["pet_count"]: "Demons()",
    ["pet.apoc_ghoul.active"]: "0",
    ["rage"]: "Rage()",
    ["rage.deficit"]: "RageDeficit()",
    ["rage.max"]: "MaxRage()",
    ["raid_event.adds.remains"]: "0", // TODO
    ["raid_event.invulnerable.exists"]: "0", //TODO
    ["raw_haste_pct"]: "SpellCastSpeedPercent()",
    ["rtb_list.any.5"]: "BuffCount(roll_the_bones_buff more 4)",
    ["rtb_list.any.6"]: "BuffCount(roll_the_bones_buff more 5)",
    ["rune.deficit"]: "RuneDeficit()",
    ["runic_power"]: "RunicPower()",
    ["runic_power.deficit"]: "RunicPowerDeficit()",
    ["service_no_de"]: "0",
    ["shadow_orb"]: "ShadowOrbs()",
    ["sigil_placed"]: "SigilCharging(flame)",
    ["solar_max"]: "TimeToEclipse(solar)",
    ["soul_shard"]: "SoulShards()",
    ["soul_fragments"]: "SoulFragments()",
    ["ssw_refund_offset"]: "target.Distance() % 3 - 1",
    ["stat.mastery_rating"]: "MasteryRating()",
    ["stealthed"]: "Stealthed()",
    ["stealthed.all"]: "Stealthed()",
    ["stealthed.rogue"]: "Stealthed()",
    ["time"]: "TimeInCombat()",
    ["time_to_20pct"]: "TimeToHealthPercent(20)",
    ["time_to_pct_30"]: "TimeToHealthPercent(30)",
    ["time_to_die"]: "TimeToDie()",
    ["time_to_die.remains"]: "TimeToDie()",
    ["time_to_shard"]: "TimeToShard()",
    ["time_to_sht.4"]: "100", // TODO
    ["time_to_sht.5"]: "100",
    ["wild_imp_count"]: "Demons(wild_imp)",
    ["wild_imp_no_de"]: "NotDeDemons(wild_imp)",
    ["wild_imp_remaining_duration"]: "DemonDuration(wild_imp)",
    ["buff.executioners_precision.stack"]:"0"
};

export interface Modifiers {
    ammo_type?: ParseNode;
    animation_cancel?: ParseNode;
    attack_speed?: ParseNode;
    cancel_if?: ParseNode;
    chain?: ParseNode;
    choose?: ParseNode;
    condition?: ParseNode,
    cooldown?: ParseNode,
    cooldown_stddev?: ParseNode,
    cycle_targets?: ParseNode,
    damage?: ParseNode,
    delay?: ParseNode;
    dynamic_prepot?: ParseNode,
    early_chain_if?: ParseNode,
    effect_name?: ParseNode,
    extra_amount?: ParseNode,
    five_stacks?: ParseNode,
    for_next?: ParseNode,
    if?: ParseNode,
    interrupt?: ParseNode,
    interrupt_global?: ParseNode,
    interrupt_if?: ParseNode,
    interrupt_immediate?: ParseNode,
    interval?: ParseNode,
    lethal?: ParseNode,
    line_cd?: ParseNode,
    max_cycle_targets?: ParseNode,
    max_energy?: ParseNode,
    min_frenzy?: ParseNode,
    moving?: ParseNode,
    name?: ParseNode,
    nonlethal?: ParseNode,
    op?: ParseNode,
    pct_health?: ParseNode,
    precombat?: ParseNode,
    precombat_seconds?: ParseNode, //todo
    precast_time?: ParseNode, //todo
    range?: ParseNode,
    sec?: ParseNode,
    slot?: ParseNode,
    slots?: ParseNode,
    strikes?: ParseNode;
    sync?: ParseNode,
    sync_weapons?: ParseNode,
    target?: ParseNode,
    target_if?: ParseNode,
    target_if_first?: ParseNode,
    target_if_max?: ParseNode,
    target_if_min?: ParseNode,
    toggle?: ParseNode,
    travel_speed?: ParseNode,
    type?: ParseNode,
    use_off_gcd?: ParseNode,
    use_while_casting?: ParseNode,
    value?: ParseNode,
    value_else?: ParseNode,
    wait?: ParseNode,
    wait_on_ready?: ParseNode,
    weapon?: ParseNode
}

export type Modifier = keyof Modifiers;

export type ParseNodeType = "action" | "action_list" | "arithmetic" | "compare" |
"function" | "logical" | "number" | "operand"

export type SimcBinaryOperatorType = "|" | "^" |
    "&" | "!=" | "<" | "<=" | "=" | "==" | ">" | ">=" |
    "~" | "!~" | "+" | "%" | "*" | "-" | ">?";
export type SimcUnaryOperatorType = "!" | "-" | "@";
export type SimcOperatorType = SimcUnaryOperatorType | SimcBinaryOperatorType;

export interface ParseNode {
    name: string;
    child: LuaArray<ParseNode>;
    modifiers: Modifiers;
    rune: string;
    asType: NodeType;
    type: ParseNodeType;

    // Not sure
    value: number;
    expressionType: "unary" | "binary";

    // Dubious
    operator: SimcOperatorType;
    includeDeath: boolean;
    left: string;
    right: string;
    action: string;
    nodeId: number;
    precedence: number;
}

export interface ProfileStrings {
    spec?: SpecializationName;
    level?: string;
    default_pet?: string;
    role?: ClassRole;
    talents?: string;
    glyphs?: string;
}

export interface ProfileLists {
    ["actions.precombat"]?:string;
}

export interface Profile extends ProfileStrings, ProfileLists {
    templates: LuaArray<keyof Profile>;
    position?: "ranged_back";
    actionList?:LuaArray<ParseNode>;
    annotation: Annotation;
}

export let KEYWORD: LuaObj<boolean> = {}
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
    ["pct_health"]: true,
    ["precombat"]: true,
    ["precombat_seconds"]: true, //todo
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
    ["weapon"]: true
}
export let LITTERAL_MODIFIER: LuaObj<boolean> = {
    ["name"]: true
}
export let FUNCTION_KEYWORD: LuaObj<boolean> = {
    ["ceil"]: true,
    ["floor"]: true
}
export let SPECIAL_ACTION: LuaObj<boolean> = {
    ["apply_poison"]: true,
    ["auto_attack"]: true,
    ["call_action_list"]: true,
    ["cancel_buff"]: true,
    ["cancel_metamorphosis"]: true,
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
    ["swap_action_list"]: true,
    ["use_items"]: true,
    ["use_item"]: true,
    ["variable"]: true,
    ["wait"]: true
}
export let RUNE_OPERAND: LuaObj<string> = {
    ["rune"]: "rune"
}
export let CONSUMABLE_ITEMS: LuaObj<boolean> = {
    ["potion"]: true,
    ["food"]: true,
    ["flask"]: true,
    ["augmentation"]: true
}
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
export let UNARY_OPERATOR: {[k in SimcUnaryOperatorType]: {1: "logical" | "arithmetic", 2: number}} = {
    ["!"]: {
        1: "logical",
        2: 15
    },
    ["-"]: {
        1: "arithmetic",
        2: 50
    },
    ["@"]: {
        1: "arithmetic",
        2: 50
    }
}
export let BINARY_OPERATOR: {[k in SimcBinaryOperatorType]: {1: "logical" | "compare" | "arithmetic", 2: number, 3?: "associative"}} = {
    ["|"]: {
        1: "logical",
        2: 5,
        3: "associative"
    },
    ["^"]: {
        1: "logical",
        2: 8,
        3: "associative"
    },
    ["&"]: {
        1: "logical",
        2: 10,
        3: "associative"
    },
    ["!="]: {
        1: "compare",
        2: 20
    },
    ["<"]: {
        1: "compare",
        2: 20
    },
    ["<="]: {
        1: "compare",
        2: 20
    },
    ["="]: {
        1: "compare",
        2: 20
    },
    ["=="]: {
        1: "compare",
        2: 20
    },
    [">"]: {
        1: "compare",
        2: 20
    },
    [">="]: {
        1: "compare",
        2: 20
    },
    ["~"]: {
        1: "compare",
        2: 20
    },
    ["!~"]: {
        1: "compare",
        2: 20
    },
    ["+"]: {
        1: "arithmetic",
        2: 30,
        3: "associative"
    },
    ["-"]: {
        1: "arithmetic",
        2: 30
    },
    ["%"]: {
        1: "arithmetic",
        2: 40
    },
    ["*"]: {
        1: "arithmetic",
        2: 40,
        3: "associative"
    },
    [">?"]: {
        1: "arithmetic",
        2: 25,
        3: "associative"
    }
}


export interface OptionalSkill {
    class: string;
    default?: boolean;
    specialization?: string;
}

export const OPTIONAL_SKILLS = {
    ["fel_rush"]: <OptionalSkill>{
        class: "DEMONHUNTER",
        default: true
    },
    ["vengeful_retreat"]: <OptionalSkill>{
        class: "DEMONHUNTER",
        default: true
    },
    ["volley"]: <OptionalSkill> {
        class: "HUNTER",
        default: true
    },
    ["harpoon"]: <OptionalSkill>{
        class: "HUNTER",
        specialization: "survival",
        default: true
    },
    ["blink"]: <OptionalSkill>{
        class: "MAGE",
        default: false,
    },
    ["time_warp"]: <OptionalSkill>{
        class: "MAGE"
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
        default: true
    },
    ["vanish"]: <OptionalSkill>{
        class: "ROGUE",
        specialization: "assassination",
        default: true
    },
    ["blade_flurry"]: <OptionalSkill>{
        class: "ROGUE",
        specialization: "outlaw",
        default: true
    },
    ["bloodlust"]: <OptionalSkill>{
        class: "SHAMAN"
    }, 
    ["shield_of_vengeance"]: <OptionalSkill>{
        class: "PALADIN",
        specialization: "retribution",
        default: false,
    },
}


export function checkOptionalSkill(action: string, className: string, specialization: string) : action is keyof typeof OPTIONAL_SKILLS {
    let data = OPTIONAL_SKILLS[<keyof typeof OPTIONAL_SKILLS>action];
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
    functionTag?: any;
    nodeList?: LuaArray<ParseNode>;
    
    astAnnotation: AstAnnotation;
    dictionaryAST?: any;
    dictionary: LuaObj<number> = {};
    supportingFunctionCount?: number;
    supportingInterruptCount?: number;
    supportingControlCount?: number;
    supportingDefineCount?: number;
    symbolTable?: LuaObj<boolean>;
    operand?: LuaArray<ParseNode>;

    sync?: LuaObj<ParseNode>; 

    using_apl?: LuaObj<boolean>;
    currentVariable?: AstNode;
    variable: LuaObj<AstNode> = {};

    trap_launcher?: string;
    interrupt?: string;
    wild_charge?: string;
    use_legendary_ring?:string;
    opt_touch_of_death_on_elite_only?:string;
    opt_arcane_mage_burn_phase?:string;
    opt_meta_only_during_boss?: string;
    opt_priority_rotation?: string;
    time_to_hpg_heal?: string;
    time_to_hpg_melee?: string;
    time_to_hpg_tank?: string;
    bloodlust?: string;
    use_item?: boolean;
	use_heart_essence?: boolean;
    summon_pet?: string;
    storm_earth_and_fire?: string;
    touch_of_death?: string;
    flying_serpent_kick?: string;
    opt_use_consumables?: string;
    blade_flurry?: string;
    blink?: string;
    time_warp?:string;
    vanish?: string;
    volley?: string;
    harpoon?: string;
    chi_burst?: string;
    touch_of_karma?: string;
    fel_rush?: string;
    vengeful_retreat?:string;
    shield_of_vengeance?: string;
    symbolList: LuaArray<string> = {};

    constructor(private ovaleData: OvaleDataClass, public name: string, public classId: ClassId, public specialization: SpecializationName) {
        this.astAnnotation = { nodeList: {}, definition: this.dictionary };
    }

    public AddSymbol(symbol: string) {
        let symbolTable = this.symbolTable || {}
        let symbolList = this.symbolList;
        if (!symbolTable[symbol] && !this.ovaleData.DEFAULT_SPELL_LIST[symbol]) {
            symbolTable[symbol] = true;
            symbolList[lualength(symbolList) + 1] = symbol;
        }
        this.symbolTable = symbolTable;
        this.symbolList = symbolList;
    }
}


export const OVALE_TAGS:LuaArray<string> = {
    1: "main",
    2: "shortcd",
    3: "cd"
}
const OVALE_TAG_PRIORITY: LuaObj<number> = {}
for (const [i, tag] of ipairs(OVALE_TAGS)) {
    OVALE_TAG_PRIORITY[tag] = i * 10;
}

export function TagPriority(tag: string) {
    return OVALE_TAG_PRIORITY[tag] || 10;
}