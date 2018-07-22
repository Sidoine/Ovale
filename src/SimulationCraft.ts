import AceConfig from "@wowts/ace_config-3.0";
import AceConfigDialog from "@wowts/ace_config_dialog-3.0";
import { L } from "./Localization";
import { OvaleDebug } from "./Debug";
import { OvaleOptions } from "./Options";
import { OvalePool } from "./Pool";
import { Ovale, MakeString } from "./Ovale";
import { OvaleAST, AstNode, OperatorType, AstAnnotation, NodeType, isValueNode, FunctionNode, StringNode, ValueNode } from "./AST";
import { OvaleCompile } from "./Compile";
import { OvaleData } from "./Data";
import { OvaleLexer, TokenizerDefinition, Tokenizer } from "./Lexer";
import { OvalePower } from "./Power";
import { ResetControls } from "./Controls";
import { format, gmatch, gsub, find, len, lower, match, sub, upper } from "@wowts/string";
import { ipairs, next, pairs, rawset, tonumber, tostring, type, wipe, LuaObj, LuaArray, setmetatable, lualength, truthy } from "@wowts/lua";
import { concat, insert, remove, sort } from "@wowts/table";
import { RAID_CLASS_COLORS } from "@wowts/wow-mock";

let OvaleSimulationCraftBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleSimulationCraft"));
export let OvaleSimulationCraft: OvaleSimulationCraftClass;

type ClassRole = "tank" | "spell" | "attack";
type ClassType = string;


interface Annotation {
    class?: ClassType;
    name?: string;
    specialization?: string;
    level?: string;
    pet?: string;
    consumables?: LuaObj<string>;
    role?: ClassRole;
    melee?: ClassType;
    ranged?: ClassType;
    taggedFunctionName?: LuaObj<boolean>;
    functionTag?: any;
    nodeList?: LuaArray<ScNode>;
    
    astAnnotation?: any;
    dictionaryAST?: any;
    dictionary?: any;
    supportingFunctionCount?: number;
    supportingInterruptCount?: number;
    supportingControlCount?: number;
    supportingDefineCount?: number;
    symbolTable?: LuaObj<boolean>;
    symbolList?: LuaArray<string>;
    operand?: LuaArray<ScNode>;

    sync?: LuaObj<ParseNode>; 

    using_apl?: LuaObj<boolean>;
    currentVariable?: AstNode;
    variable?: LuaObj<AstNode>;

    trap_launcher?: string;
    skull_bash?: string;
    solar_beam?: string;
    interrupt?: string;
    consume_magic?: string;
    mind_freeze?: string;
    wild_charge?: string;
    muzzle?: string;
    counter_shot?: string;
    counterspell?: string;
    use_legendary_ring?:string;
    opt_touch_of_death_on_elite_only?:string;
    opt_arcane_mage_burn_phase?:string;
    opt_meta_only_during_boss?: string;
    pummel?: string;
    wind_shear?: string;
    kick?: string;
    silence?: string;
    rebuke?: string;
    spear_hand_strike?: string;
    time_to_hpg_heal?: string;
    time_to_hpg_melee?: string;
    time_to_hpg_tank?: string;
    bloodlust?: string;
    use_item?: boolean;
    summon_pet?: string;
    storm_earth_and_fire?: string;
    touch_of_death?: string;
    opt_use_consumables?: string;
    righteous_fury?: string;
    mind_bomb?: string;
    blade_flurry?: string;
    time_warp?:string;
    vanish?: string;
}

interface ChildParseNode extends LuaArray<ParseNode> {
    [key:string]: ParseNode;
    ammo_type?: ParseNode;
    cycle_targets?: ParseNode;
    lethal?: ParseNode;
    cooldown?: ParseNode;
    target?: ParseNode;
    for_next?: ParseNode;
    extra_amount?: ParseNode;
    choose?: ParseNode;
    slot?: ParseNode;
    sec?: ParseNode;

    op?: ParseNode;
    name?: ParseNode;
    value?: ParseNode;
    value_else?: ParseNode;
    condition?: ParseNode;
}

interface ParseNode {
    name: string;
    child: ChildParseNode;
    rune: string;
    asType: NodeType;
    type: "action" | "action_list" | "arithmetic" | "compare" |
    "function" | "logical" | "number" | "operand";

    // Not sure
    value: number;
    expressionType: "unary" | "binary";

    // Dubious
    operator: OperatorType;
    includeDeath: boolean;
    left: string;
    right: string;
    action: string;
    nodeId: number;
    precedence: number;
}

interface Profile {
    templates?: any;
    spec?: string;
    level?: string;
    default_pet?: string;
    role?: ClassRole;
    position?: "ranged_back";
    actionList?:LuaArray<ParseNode>;
    annotation?: Annotation;
    talents?: string;
    glyphs?: string;
    ["actions.precombat"]?:string;
}

let KEYWORD: LuaObj<boolean> = {
}
let MODIFIER_KEYWORD: LuaObj<boolean> = {
    ["ammo_type"]: true,
    ["animation_cancel"]: true,
    ["attack_speed"]: true,
    ["chain"]: true,
    ["choose"]: true,
    ["condition"]: true,
    ["cooldown"]: true,
    ["cooldown_stddev"]: true,
    ["cycle_targets"]: true,
    ["damage"]: true,
    ["early_chain_if"]: true,
    ["extra_amount"]: true,
    ["five_stacks"]: true,
    ["for_next"]: true,
    ["if"]: true,
    ["interrupt"]: true,
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
    ["range"]: true,
    ["sec"]: true,
    ["slot"]: true,
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
    ["value"]: true,
    ["value_else"]: true,
    ["wait"]: true,
    ["wait_on_ready"]: true,
    ["weapon"]: true
}
let LITTERAL_MODIFIER: LuaObj<boolean> = {
    ["name"]: true
}
let FUNCTION_KEYWORD: LuaObj<boolean> = {
    ["ceil"]: true,
    ["floor"]: true
}
let SPECIAL_ACTION: LuaObj<boolean> = {
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
    ["snapshot_stats"]: true,
    ["stance"]: true,
    ["start_moving"]: true,
    ["stealth"]: true,
    ["stop_moving"]: true,
    ["swap_action_list"]: true,
    ["use_item"]: true,
    ["variable"]: true,
    ["wait"]: true
}
let RUNE_OPERAND: LuaObj<string> = {
    ["rune"]: "rune"
}
let CONSUMABLE_ITEMS: LuaObj<boolean> = {
    ["potion"]: true,
    ["food"]: true,
    ["flask"]: true,
    ["augmentation"]: true
}
{
    for (const [keyword, value] of pairs(MODIFIER_KEYWORD)) {
        KEYWORD[keyword] = value;
    }
    for (const [keyword, value] of pairs(FUNCTION_KEYWORD)) {
        KEYWORD[keyword] = value;
    }
    for (const [keyword, value] of pairs(SPECIAL_ACTION)) {
        KEYWORD[keyword] = value;
    }
}
let UNARY_OPERATOR: LuaObj<{1: "logical" | "arithmetic", 2: number}> = {
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
let BINARY_OPERATOR: LuaObj<{1: "logical" | "compare" | "arithmetic", 2: number, 3?: string}> = {
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
    }
}
let INDENT: LuaArray<string> = {
}
{
    INDENT[0] = "";
    let metatable = {
        __index: function (tbl: LuaArray<string>, key: string) {
            const _key = tonumber(key);
            if (_key > 0) {
                let s = `${tbl[_key - 1]}\t`;
                rawset(tbl, key, s);
                return s;
            }
            return INDENT[0];
        }
    }
    setmetatable(INDENT, metatable);
}
let EMIT_DISAMBIGUATION = {
}
// let EMIT_EXTRA_PARAMETERS = {
// }
let OPERAND_TOKEN_PATTERN = "[^.]+";
// let POTION_STAT = {
//     ["draenic_agility"]: "agility",
//     ["draenic_armor"]: "armor",
//     ["draenic_intellect"]: "intellect",
//     ["draenic_strength"]: "strength",
//     ["jade_serpent"]: "intellect",
//     ["mogu_power"]: "strength",
//     ["mountains"]: "armor",
//     ["tolvir"]: "agility",
//     ["virmens_bite"]: "agility"
// }
let OPTIONAL_SKILLS: LuaObj<{class: string, default?: boolean, specialization?: string}> = {
    ["volley"]: {
        class: "HUNTER",
        default: true
    },
    ["harpoon"]: {
        class: "HUNTER",
        specialization: "survival",
        default: true
    },
    ["time_warp"]: {
        class: "MAGE"
    },
    ["storm_earth_and_fire"]: {
        class: "MONK"
    },
    ["chi_burst"]: {
        class: "MONK",
        default: true
    },
    ["touch_of_karma"]: {
        class: "MONK",
        default: false
    },
    ["vanish"]: {
        class: "ROGUE",
        specialization: "assassination",
        default: true
    },
    ["blade_flurry"]: {
        class: "ROGUE",
        specialization: "outlaw",
        default: true
    },
    ["bloodlust"]: {
        class: "SHAMAN"
    },
    ["righteous_fury"]: {
        class: "PALADIN"
    },
    ["fel_rush"]: {
        class: "DEMONHUNTER",
        default: true
    },
    ["vengeful_retreat"]: {
        class: "DEMONHUNTER",
        default: true
    }
}

type ScNode = ParseNode;

let self_functionDefined: LuaObj<boolean> = {
}
let self_functionUsed: LuaObj<boolean> = {
}
let self_outputPool = new OvalePool<LuaArray<string>>("OvaleSimulationCraft_outputPool");
let self_childrenPool = new OvalePool<ChildParseNode>("OvaleSimulationCraft_childrenPool");
class SelfPool extends OvalePool<ParseNode> {
    constructor(){
        super("OvaleSimulationCraft_pool");
    }

    Clean(node: ParseNode) {
        if (node.child) {
            self_childrenPool.Release(node.child);
            node.child = undefined;
        }
    }
}

let self_pool = new SelfPool();
let self_lastSimC: string = undefined;
let self_lastScript: string = undefined;
{
    let actions = {
        simc: {
            name: "SimulationCraft",
            type: "execute",
            func: function () {
                let appName = OvaleSimulationCraft.GetName();
                AceConfigDialog.SetDefaultSize(appName, 700, 550);
                AceConfigDialog.Open(appName);
            }
        }
    }
    for (const [k, v] of pairs(actions)) {
        OvaleOptions.options.args.actions.args[k] = v;
    }
    // OvaleOptions.RegisterOptions(OvaleSimulationCraft);
}
let OVALE_TAGS:LuaArray<string> = {
    1: "main",
    2: "shortcd",
    3: "cd"
}
let OVALE_TAG_PRIORITY: LuaObj<number> = {}
{
    for (const [i, tag] of ipairs(OVALE_TAGS)) {
        OVALE_TAG_PRIORITY[tag] = i * 10;
    }
}
{
    let defaultDB = {
        overrideCode: ""
    }
    for (const [k, v] of pairs(defaultDB)) {
        OvaleOptions.defaultDB.profile[k] = v;
    }
    OvaleOptions.RegisterOptions(OvaleSimulationCraft);
}
const print_r = function(node: any, indent?: string, done?: LuaObj<boolean>, output?: LuaArray<string>) {
    done = done || {}
    output = output || {}
    indent = indent || '';
    if (node == undefined) {
        insert(output, `${indent}nil`);
    } else if (type(node) != "table") {
        insert(output, `${indent}${node}`);
    } else {
        for (const [key, value] of pairs(node)) {
            if (type(value) == "table") {
                if (done[value]) {
                    insert(output, `${indent}[${tostring(key)}] => (self_reference)`);
                } else {
                    done[value] = true;
                    insert(output, `${indent}[${tostring(key)}] => {`);
                    print_r(value, `${indent}    `, done, output);
                    insert(output, `${indent}}`);
                }
            } else {
                insert(output, `${indent}[${tostring(key)}] => ${tostring(value)}`);
            }
        }
    }
    return output;
}
// const debug_r = function(tbl) {
//     let output = print_r(tbl);
//     OvaleSimulationCraft.Debug(tconcat(output, "\n"));
// }
const NewNode = function(nodeList: ChildParseNode, hasChild?: boolean) {
    let node = self_pool.Get();
    if (nodeList) {
        let nodeId = lualength(nodeList) + 1;
        node.nodeId = nodeId;
        nodeList[nodeId] = node;
    }
    if (hasChild) {
        node.child = self_childrenPool.Get();
    }
    return node;
}
const TokenizeName:Tokenizer = function(token) {
    if (KEYWORD[token]) {
        return ["keyword", token];
    } else {
        return ["name", token];
    }
}
const TokenizeNumber:Tokenizer = function(token) {
    return ["number", token];
}
const Tokenize:Tokenizer = function(token) {
    return [token, token];
}
const NoToken:Tokenizer = function() {
    return [undefined, undefined];
}
const MATCHES:LuaArray<TokenizerDefinition> = {
    1: {
        1: "^%d+%a[%w_]*[.:]?[%w_.]*",
        2: TokenizeName
    },
    2: {
        1: "^%d+%.?%d*",
        2: TokenizeNumber
    },
    3: {
        1: "^[%a_][%w_]*[.:]?[%w_.]*",
        2: TokenizeName
    },
    4: {
        1: "^!=",
        2: Tokenize
    },
    5: {
        1: "^<=",
        2: Tokenize
    },
    6: {
        1: "^>=",
        2: Tokenize
    },
    7: {
        1: "^!~",
        2: Tokenize
    },
    8: {
        1: "^==",
        2: Tokenize
    },
    9: {
        1: "^.",
        2: Tokenize
    },
    10: {
        1: "^$",
        2: NoToken
    }
}

const GetPrecedence = function(node: ScNode) {
    let precedence = node.precedence;
    if (!precedence) {
        let operator = node.operator;
        if (operator) {
            if (node.expressionType == "unary" && UNARY_OPERATOR[operator]) {
                precedence = UNARY_OPERATOR[operator][2];
            } else if (node.expressionType == "binary" && BINARY_OPERATOR[operator]) {
                precedence = BINARY_OPERATOR[operator][2];
            }
        }
    }
    return precedence;
}
let UNPARSE_VISITOR: LuaObj<(node: ParseNode) => string> = undefined;
const Unparse = function(node: ParseNode) {
    let visitor = UNPARSE_VISITOR[node.type];
    if (!visitor) {
        OvaleSimulationCraft.Error("Unable to unparse node of type '%s'.", node.type);
    } else {
        return visitor(node);
    }
}
const UnparseAction = function(node: ParseNode) {
    let output = self_outputPool.Get();
    output[lualength(output) + 1] = node.name;
    for (const [modifier, expressionNode] of pairs(node.child)) {
        output[lualength(output) + 1] = `${modifier}=${Unparse(expressionNode)}`;
    }
    let s = concat(output, ",");
    self_outputPool.Release(output);
    return s;
}
const UnparseActionList = function(node: ParseNode) {
    let output = self_outputPool.Get();
    let listName;
    if (node.name == "_default") {
        listName = "action";
    } else {
        listName = `action.${node.name}`;
    }
    output[lualength(output) + 1] = "";
    for (const [i, actionNode] of pairs(node.child)) {
        let operator = (tonumber(i) == 1) && "=" || "+=/";
        output[lualength(output) + 1] = `${listName}${operator}${Unparse(actionNode)}`;
    }
    let s = concat(output, "\n");
    self_outputPool.Release(output);
    return s;
}
const UnparseExpression = function(node: ParseNode) {
    let expression;
    let precedence = GetPrecedence(node);
    if (node.expressionType == "unary") {
        let rhsExpression;
        let rhsNode = node.child[1];
        let rhsPrecedence = GetPrecedence(rhsNode);
        if (rhsPrecedence && precedence >= rhsPrecedence) {
            rhsExpression = `(${Unparse(rhsNode)})`;
        } else {
            rhsExpression = Unparse(rhsNode);
        }
        expression = `${node.operator}${rhsExpression}`;
    } else if (node.expressionType == "binary") {
        let lhsExpression, rhsExpression;
        let lhsNode = node.child[1];
        let lhsPrecedence = GetPrecedence(lhsNode);
        if (lhsPrecedence && lhsPrecedence < precedence) {
            lhsExpression = `(${Unparse(lhsNode)})`;
        } else {
            lhsExpression = Unparse(lhsNode);
        }
        let rhsNode = node.child[2];
        let rhsPrecedence = GetPrecedence(rhsNode);
        if (rhsPrecedence && precedence > rhsPrecedence) {
            rhsExpression = `(${Unparse(rhsNode)})`;
        } else if (rhsPrecedence && precedence == rhsPrecedence) {
            if (BINARY_OPERATOR[node.operator][3] == "associative" && node.operator == rhsNode.operator) {
                rhsExpression = Unparse(rhsNode);
            } else {
                rhsExpression = `(${Unparse(rhsNode)})`;
            }
        } else {
            rhsExpression = Unparse(rhsNode);
        }
        expression = `${lhsExpression}${node.operator}${rhsExpression}`;
    }
    return expression;
}
const UnparseFunction = function(node: ParseNode) {
    return `${node.name}(${Unparse(node.child[1])})`;
}
const UnparseNumber = function(node: ParseNode) {
    return tostring(node.value);
}
const UnparseOperand = function(node: ParseNode) {
    return node.name;
}
{
    UNPARSE_VISITOR = {
        ["action"]: UnparseAction,
        ["action_list"]: UnparseActionList,
        ["arithmetic"]: UnparseExpression,
        ["compare"]: UnparseExpression,
        ["function"]: UnparseFunction,
        ["logical"]: UnparseExpression,
        ["number"]: UnparseNumber,
        ["operand"]: UnparseOperand
    }
}
const SyntaxError = function(tokenStream: OvaleLexer, ...__args: any[]) {
    OvaleSimulationCraft.Print(...__args);
    let context: LuaArray<string> = {
        1: "Next tokens:"
    }
    for (let i = 1; i <= 20; i += 1) {
        let [tokenType, token] = tokenStream.Peek(i);
        if (tokenType) {
            context[lualength(context) + 1] = token;
        } else {
            context[lualength(context) + 1] = "<EOS>";
            break;
        }
    }
    OvaleSimulationCraft.Print(concat(context, " "));
}

type ParseFunction = (tokenStream: OvaleLexer, nodeList: ChildParseNode, annotation: Annotation) => [boolean, ScNode];

let ParseFunction: ParseFunction = undefined;
let ParseModifier: (tokenStream: OvaleLexer, nodeList: ChildParseNode, annotation: Annotation) => [boolean, string, ScNode] = undefined;
let ParseNumber: ParseFunction = undefined;
let ParseOperand: ParseFunction = undefined;
let ParseParentheses: ParseFunction = undefined;
let ParseSimpleExpression: ParseFunction = undefined;
// let ParseIdentifer: ParseFunction = undefined;

const TicksRemainTranslationHelper = function(p1: string, p2: string, p3: string, p4: string) {
    if (p4) {
        return `${p1}${p2} < ${tostring(tonumber(p4) + 1)}`;
    } else {
        return `${p1}<${tostring(tonumber(p3) + 1)}`;
    }
}
const ParseAction = function (action: string, nodeList: ChildParseNode, annotation: Annotation): [boolean, ScNode] {
    let ok = true;
    let stream = action;
    {
        stream = gsub(stream, "||", "|");
    }
    {
        stream = gsub(stream, ",,", ",");
        stream = gsub(stream, "%&%&", "&");
        stream = gsub(stream, "target%.target%.", "target.");
    }
    {
        stream = gsub(stream, "(active_dot%.[%w_]+)=0", "!(%1>0)");
        stream = gsub(stream, "([^_%.])(cooldown_remains)=0", "%1!(%2>0)");
        stream = gsub(stream, "([a-z_%.]+%.cooldown_remains)=0", "!(%1>0)");
        stream = gsub(stream, "([^_%.])(remains)=0", "%1!(%2>0)");
        stream = gsub(stream, "([a-z_%.]+%.remains)=0", "!(%1>0)");
        stream = gsub(stream, "([^_%.])(ticks_remain)(<?=)([0-9]+)", TicksRemainTranslationHelper);
        stream = gsub(stream, "([a-z_%.]+%.ticks_remain)(<?=)([0-9]+)", TicksRemainTranslationHelper);
    }
    {
        stream = gsub(stream, "%@([a-z_%.]+)<(=?)([0-9]+)", "(%1<%2%3&%1>%2-%3)");
        stream = gsub(stream, "%@([a-z_%.]+)>(=?)([0-9]+)", "(%1>%2%3|%1<%2-%3)");
    }
    {
        stream = gsub(stream, "!([a-z_%.]+)%.cooldown%.up", "%1.cooldown.down");
    }
    {
        stream = gsub(stream, "!talent%.([a-z_%.]+)%.enabled", "talent.%1.disabled");
    }
    {
        stream = gsub(stream, ",target_if=first:", ",target_if_first=");
        stream = gsub(stream, ",target_if=max:", ",target_if_max=");
        stream = gsub(stream, ",target_if=min:", ",target_if_min=");
    }
    {
        stream = gsub(stream, "sim.target", "sim_target");
    }
    
    let tokenStream = new OvaleLexer("SimulationCraft", stream, MATCHES);
    let name;
    {
        let [tokenType, token] = tokenStream.Consume();
        if ((tokenType == "keyword" && SPECIAL_ACTION[token]) || tokenType == "name") {
            name = token;
        } else {
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line '%s'; name or special action expected.", token, action);
            ok = false;
        }
    }
    let child = self_childrenPool.Get();
    if (ok) {
        let [tokenType, token] = tokenStream.Peek();
        while (ok && tokenType) {
            if (tokenType == ",") {
                tokenStream.Consume();
                let modifier: any, expressionNode: ScNode;
                [ok, modifier, expressionNode] = ParseModifier(tokenStream, nodeList, annotation);
                if (ok) {
                    child[modifier] = expressionNode;
                    [tokenType, token] = tokenStream.Peek();
                }
            } else {
                SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line '%s'; ',' expected.", token, action);
                ok = false;
            }
        }
    }
    let node : ParseNode;
    if (ok) {
        node = NewNode(nodeList);
        node.type = "action";
        node.action = action;
        node.name = name;
        node.child = child;
        annotation.sync = annotation.sync || {}
        annotation.sync[name] = annotation.sync[name] || node;
    } else {
        self_childrenPool.Release(child);
    }
    return [ok, node];
}
const ParseActionList = function (name: string, actionList: string, nodeList: ChildParseNode, annotation: Annotation): [boolean, ParseNode] {
    let ok = true;
    let child = self_childrenPool.Get();
    for (const action of gmatch(actionList, "[^/]+")) {
        let actionNode;
        [ok, actionNode] = ParseAction(action, nodeList, annotation);
        if (ok) {
            child[lualength(child) + 1] = actionNode;
        } else {
            break;
        }
    }
    let node: ParseNode;
    if (ok) {
        node = NewNode(nodeList);
        node.type = "action_list";
        node.name = name;
        node.child = child;
    } else {
        self_childrenPool.Release(child);
    }
    return [ok, node];
}

function  ParseExpression(tokenStream: OvaleLexer, nodeList: ChildParseNode, annotation: Annotation, minPrecedence?: number):[boolean, ParseNode] {
    minPrecedence = minPrecedence || 0;
    let ok = true;
    let node: ScNode;
    {
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType) {
            let opInfo: { 1: "logical" | "arithmetic", 2: number} = UNARY_OPERATOR[token];
            if (opInfo) {
                let [opType, precedence] = [opInfo[1], opInfo[2]];
                let asType: "boolean" | "value" = (opType == "logical") && "boolean" || "value";
                tokenStream.Consume();
                let operator = token;
                let rhsNode: ParseNode;
                [ok, rhsNode] = ParseExpression(tokenStream, nodeList, annotation, precedence);
                if (ok) {
                    if (operator == "-" && rhsNode.type == "number") {
                        rhsNode.value = -1 * rhsNode.value;
                        node = rhsNode;
                    } else {
                        node = NewNode(nodeList, true);
                        node.type = opType;
                        node.expressionType = "unary";
                        node.operator = <OperatorType> operator;
                        node.precedence = precedence;
                        node.child[1] = rhsNode;
                        rhsNode.asType = asType;
                    }
                }
            } else {
                [ok, node] = ParseSimpleExpression(tokenStream, nodeList, annotation);
                if (ok && node) {
                    node.asType = "boolean";
                }
            }
        }
    }
    while (ok) {
        let keepScanning = false;
        let [tokenType, token] = tokenStream.Peek();
        if (!tokenType) {
            break;
        }
        let opInfo = BINARY_OPERATOR[token];
        if (opInfo) {
            let [opType, precedence] = [opInfo[1], opInfo[2]];
            let asType: "boolean" | "value" = (opType == "logical") && "boolean" || "value";
            if (precedence && precedence > minPrecedence) {
                keepScanning = true;
                tokenStream.Consume();
                let operator = token;
                let lhsNode = node;
                let rhsNode;
                [ok, rhsNode] = ParseExpression(tokenStream, nodeList, annotation, precedence);
                if (ok) {
                    node = NewNode(nodeList, true);
                    node.type = opType;
                    node.expressionType = "binary";
                    node.operator = <OperatorType>operator;
                    node.precedence = precedence;
                    node.child[1] = lhsNode;
                    node.child[2] = rhsNode;
                    lhsNode.asType = <"boolean"|"value"> asType;
                    if (!rhsNode) {
                        SyntaxError(tokenStream, "Internal error: no right operand in binary operator %s.", token);
                        return [false, undefined];
                    }
                    rhsNode.asType = asType;
                    while (node.type == rhsNode.type && node.operator == rhsNode.operator && BINARY_OPERATOR[node.operator][3] == "associative" && rhsNode.expressionType == "binary") {
                        node.child[2] = rhsNode.child[1];
                        rhsNode.child[1] = node;
                        node = rhsNode;
                        rhsNode = node.child[2];
                    }
                }
            }
        } else if (!node) {
            SyntaxError(tokenStream, "Syntax error: %s of type %s is not a binary operator", token, tokenType);
            return [false, undefined];
        }
        if (!keepScanning) {
            break;
        }
    }
    return [ok, node];
}
ParseFunction = function (tokenStream: OvaleLexer, nodeList, annotation) {
    let ok = true;
    let name;
    {
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "keyword" && FUNCTION_KEYWORD[token]) {
            name = token;
        } else {
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token);
            ok = false;
        }
    }
    if (ok) {
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; '(' expected.", token);
            ok = false;
        }
    }
    let argumentNode;
    if (ok) {
        [ok, argumentNode] = ParseExpression(tokenStream, nodeList, annotation);
    }
    if (ok) {
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.", token);
            ok = false;
        }
    }
    let node;
    if (ok) {
        node = NewNode(nodeList, true);
        node.type = "function";
        node.name = name;
        node.child[1] = argumentNode;
    }
    return [ok, node];
}
const ParseIdentifier = function (tokenStream: OvaleLexer, nodeList: ChildParseNode, annotation: Annotation): [boolean, ScNode] {
    let [, token] = tokenStream.Consume();
    let node = NewNode(nodeList);
    node.type = "operand";
    node.name = token;
    annotation.operand = annotation.operand || {
    }
    annotation.operand[lualength(annotation.operand) + 1] = node;
    return [true, node];
}
ParseModifier = function (tokenStream: OvaleLexer, nodeList, annotation) {
    let ok = true;
    let name: string;
    {
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "keyword" && MODIFIER_KEYWORD[token]) {
            name = token;
        } else {
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line; expression keyword expected.", token);
            ok = false;
        }
    }
    if (ok) {
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType != "=") {
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line; '=' expected.", token);
            ok = false;
        }
    }
    let expressionNode: ScNode;
    if (ok) {
        if (LITTERAL_MODIFIER[name]) {
            [ok, expressionNode] = ParseIdentifier(tokenStream, nodeList, annotation);
        } else {
            [ok, expressionNode] = ParseExpression(tokenStream, nodeList, annotation);
            if (ok && expressionNode && name == "sec") {
                expressionNode.asType = "value";
            }
        }
    }
    return [ok, name, expressionNode];
}
ParseNumber = function (tokenStream: OvaleLexer, nodeList, annotation) {
    let ok = true;
    let value;
    {
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "number") {
            value = tonumber(token);
        } else {
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing NUMBER; number expected.", token);
            ok = false;
        }
    }
    let node;
    if (ok) {
        node = NewNode(nodeList);
        node.type = "number";
        node.value = value;
    }
    return [ok, node];
}
ParseOperand = function (tokenStream: OvaleLexer, nodeList, annotation) {
    let ok = true;
    let name;
    {
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name") {
            name = token;
        } else if (tokenType == "keyword" && (token == "target" || token == "cooldown")) {
            name = token;
        } else {
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing OPERAND; operand expected.", token);
            ok = false;
        }
    }
    let node: ScNode;
    if (ok) {
        node = NewNode(nodeList);
        node.type = "operand";
        node.name = name;
        node.rune = RUNE_OPERAND[name];
        if (node.rune) {
            let firstCharacter = sub(name, 1, 1);
            node.includeDeath = (firstCharacter == "B" || firstCharacter == "F" || firstCharacter == "U");
        }
        annotation.operand = annotation.operand || {
        }
        annotation.operand[lualength(annotation.operand) + 1] = node;
    }
    return [ok, node];
}
ParseParentheses = function (tokenStream: OvaleLexer, nodeList, annotation) {
    let ok = true;
    let leftToken, rightToken;
    {
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "(") {
            [leftToken, rightToken] = ["(", ")"];
        } else if (tokenType == "{") {
            [leftToken, rightToken] = ["{", "}"];
        } else {
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '(' or '{' expected.", token);
            ok = false;
        }
    }
    let node: ScNode;
    if (ok) {
        [ok, node] = ParseExpression(tokenStream, nodeList, annotation);
    }
    if (ok) {
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType != rightToken) {
            SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '%s' expected.", token, rightToken);
            ok = false;
        }
    }
    if (ok) {
        node.left = leftToken;
        node.right = rightToken;
    }
    return [ok, node];
}
ParseSimpleExpression = function (tokenStream: OvaleLexer, nodeList, annotation):[boolean, ScNode] {
    let ok = true;
    let node;
    let [tokenType, token] = tokenStream.Peek();
    if (tokenType == "number") {
        [ok, node] = ParseNumber(tokenStream, nodeList, annotation);
    } else if (tokenType == "keyword") {
        if (FUNCTION_KEYWORD[token]) {
            [ok, node] = ParseFunction(tokenStream, nodeList, annotation);
        } else if (token == "target" || token == "cooldown") {
            [ok, node] = ParseOperand(tokenStream, nodeList, annotation);
        } else {
            SyntaxError(tokenStream, "Warning: unknown keyword %s when parsing SIMPLE EXPRESSION", token);
            return [false, undefined];
        }
    } else if (tokenType == "name") {
        [ok, node] = ParseOperand(tokenStream, nodeList, annotation);
    } else if (tokenType == "(") {
        [ok, node] = ParseParentheses(tokenStream, nodeList, annotation);
    } else {
        SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION", token);
        tokenStream.Consume();
        ok = false;
    }
    return [ok, node];
}
let CamelCase: (s: string) => string = undefined;
{
    const CamelCaseHelper = function(first: string, rest: string) {
        return `${upper(first)}${lower(rest)}`;
    }
    CamelCase = function (s: string) {
        let tc = gsub(s, "(%a)(%w*)", CamelCaseHelper);
        return gsub(tc, "[%s_]", "");
    }
}
const CamelSpecialization = function(annotation: Annotation) {
    let output = self_outputPool.Get();
    let [profileName, className, specialization] = [annotation.name, annotation.class, annotation.specialization];
    if (specialization) {
        output[lualength(output) + 1] = specialization;
    }
    if (truthy(match(profileName, "_1[hH]_"))) {
        if (className == "DEATHKNIGHT" && specialization == "frost") {
            output[lualength(output) + 1] = "dual wield";
        } else if (className == "WARRIOR" && specialization == "fury") {
            output[lualength(output) + 1] = "single minded fury";
        }
    } else if (truthy(match(profileName, "_2[hH]_"))) {
        if (className == "DEATHKNIGHT" && specialization == "frost") {
            output[lualength(output) + 1] = "two hander";
        } else if (className == "WARRIOR" && specialization == "fury") {
            output[lualength(output) + 1] = "titans grip";
        }
    } else if (truthy(match(profileName, "_[gG]ladiator_"))) {
        output[lualength(output) + 1] = "gladiator";
    }
    let outputString = CamelCase(concat(output, " "));
    self_outputPool.Release(output);
    return outputString;
}
const OvaleFunctionName = function(name: string, annotation: Annotation) {
    let functionName = CamelCase(`${name} actions`);
    if (annotation.specialization) {
        functionName = `${CamelSpecialization(annotation)}${functionName}`;
    }
    return functionName;
}
const AddSymbol = function(annotation: Annotation, symbol: string) {
    let symbolTable = annotation.symbolTable || {}
    let symbolList = annotation.symbolList || {};
    if (!symbolTable[symbol] && !OvaleData.DEFAULT_SPELL_LIST[symbol]) {
        symbolTable[symbol] = true;
        symbolList[lualength(symbolList) + 1] = symbol;
    }
    annotation.symbolTable = symbolTable;
    annotation.symbolList = symbolList;
}
const AddPerClassSpecialization = function(tbl: LuaObj<LuaObj<LuaObj<{1: string, 2: string}>>>, name: string, info: string, className: string, specialization: string, _type: string) {
    className = className || "ALL_CLASSES";
    specialization = specialization || "ALL_SPECIALIZATIONS";
    tbl[className] = tbl[className] || {
    }
    tbl[className][specialization] = tbl[className][specialization] || {
    }
    tbl[className][specialization][name] = {
        1: info,
        2: _type || "Spell"
    }
}
const GetPerClassSpecialization = function(tbl: LuaObj<LuaObj<LuaObj<{1: string, 2: string}>>>, name: string, className: string, specialization: string) {
    let info;
    while (!info) {
        while (!info) {
            if (tbl[className] && tbl[className][specialization] && tbl[className][specialization][name]) {
                info = tbl[className][specialization][name];
            }
            if (specialization != "ALL_SPECIALIZATIONS") {
                specialization = "ALL_SPECIALIZATIONS";
            } else {
                break;
            }
        }
        if (className != "ALL_CLASSES") {
            className = "ALL_CLASSES";
        } else {
            break;
        }
    }
    if (info) {
        return [info[1], info[2]];
    }
    return [];
}
const AddDisambiguation = function(name: string, info: string, className?: string, specialization?: string, _type?: string) {
    AddPerClassSpecialization(EMIT_DISAMBIGUATION, name, info, className, specialization, _type);
}
function Disambiguate(name: string, className: string, specialization: string, _type?: string): [string, string] {
    let [disname, distype] = GetPerClassSpecialization(EMIT_DISAMBIGUATION, name, className, specialization);
    if (!disname) {
        return [name, _type];
    }
    return [disname, distype];
}
const InitializeDisambiguation = function() {
    AddDisambiguation("bloodlust_buff", "burst_haste_buff");
    AddDisambiguation("trinket_proc_all_buff", "trinket_proc_any_buff");
    AddDisambiguation("trinket_stack_proc_all_buff", "trinket_proc_any_buff");
    AddDisambiguation("etheralus_the_eternal_reward", "legendary_ring_spirit", undefined, undefined, "Item");
    AddDisambiguation("maalus_the_blood_drinker", "legendary_ring_agility", undefined, undefined, "Item");
    AddDisambiguation("nithramus_the_allseer", "legendary_ring_intellect", undefined, undefined, "Item");
    AddDisambiguation("sanctus_sigil_of_the_unbroken", "legendary_ring_bonus_armor", undefined, undefined, "Item");
    AddDisambiguation("thorasus_the_stone_heart_of_draenor", "legendary_ring_strength", undefined, undefined, "Item");
    AddDisambiguation("arcane_torrent", "arcane_torrent_runicpower", "DEATHKNIGHT");
    AddDisambiguation("blood_fury", "blood_fury_ap", "DEATHKNIGHT");
    AddDisambiguation("breath_of_sindragosa_debuff", "breath_of_sindragosa_buff", "DEATHKNIGHT");
    AddDisambiguation("legendary_ring", "legendary_ring_bonus_armor", "DEATHKNIGHT", "blood", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_strength", "DEATHKNIGHT", "frost", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_strength", "DEATHKNIGHT", "unholy", "Item");
    AddDisambiguation("soul_reaper", "soul_reaper_blood", "DEATHKNIGHT", "blood");
    AddDisambiguation("soul_reaper", "soul_reaper_frost", "DEATHKNIGHT", "frost");
    AddDisambiguation("soul_reaper", "soul_reaper_unholy", "DEATHKNIGHT", "unholy");
    AddDisambiguation("outbreak_debuff", "virulent_plague_debuff", "DEATHKNIGHT", "unholy");
    AddDisambiguation("arcane_torrent", "arcane_torrent_dh", "DEMONHUNTER");
    AddDisambiguation("metamorphosis", "metamorphosis_veng", "DEMONHUNTER", "vengeance");
    AddDisambiguation("metamorphosis_buff", "metamorphosis_veng_buff", "DEMONHUNTER", "vengeance");
    AddDisambiguation("metamorphosis", "metamorphosis_havoc", "DEMONHUNTER", "havoc");
    AddDisambiguation("metamorphosis_buff", "metamorphosis_havoc_buff", "DEMONHUNTER", "havoc");
    AddDisambiguation("chaos_blades_debuff", "chaos_blades_buff", "DEMONHUNTER", "havoc");
    AddDisambiguation("throw_glaive", "throw_glaive_veng", "DEMONHUNTER", "vengeance");
    AddDisambiguation("throw_glaive", "throw_glaive_havoc", "DEMONHUNTER", "havoc");
    AddDisambiguation("arcane_torrent", "arcane_torrent_energy", "DRUID");
    AddDisambiguation("berserk", "berserk_bear", "DRUID", "guardian");
    AddDisambiguation("berserk", "berserk_cat", "DRUID", "feral");
    AddDisambiguation("blood_fury", "blood_fury_apsp", "DRUID");
    AddDisambiguation("dream_of_cenarius", "dream_of_cenarius_caster", "DRUID", "balance");
    AddDisambiguation("dream_of_cenarius", "dream_of_cenarius_melee", "DRUID", "feral");
    AddDisambiguation("dream_of_cenarius", "dream_of_cenarius_tank", "DRUID", "guardian");
    AddDisambiguation("force_of_nature", "force_of_nature_caster", "DRUID", "balance");
    AddDisambiguation("force_of_nature", "force_of_nature_melee", "DRUID", "feral");
    AddDisambiguation("force_of_nature", "force_of_nature_tank", "DRUID", "guardian");
    AddDisambiguation("fury_of_elue", "fury_of_elune", "DRUID");
    AddDisambiguation("heart_of_the_wild", "heart_of_the_wild_tank", "DRUID", "guardian");
    AddDisambiguation("incarnation", "incarnation_chosen_of_elune", "DRUID", "balance");
    AddDisambiguation("incarnation", "incarnation_king_of_the_jungle", "DRUID", "feral");
    AddDisambiguation("incarnation", "incarnation_guardian_of_ursoc", "DRUID", "guardian");
    AddDisambiguation("legendary_ring", "legendary_ring_agility", "DRUID", "feral", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_bonus_armor", "DRUID", "guardian", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_intellect", "DRUID", "balance", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_spirit", "DRUID", "restoration", "Item");
    AddDisambiguation("lunar_strike", "lunar_strike_balance", "DRUID", "balance");
    AddDisambiguation("moonfire", "moonfire_cat", "DRUID", "feral");
    AddDisambiguation("omen_of_clarity", "omen_of_clarity_melee", "DRUID", "feral");
    AddDisambiguation("rejuvenation_debuff", "rejuvenation_buff", "DRUID");
    AddDisambiguation("starsurge", "starsurge_moonkin", "DRUID", "balance");
    AddDisambiguation("starfall_debuff", "starfall_buff", "DRUID", "balance");
    AddDisambiguation("frenzied_regeneration_debuff", "frenzied_regeneration_buff", "DRUID", "guardian");
    AddDisambiguation("thrash_debuff", "thrash_bear_debuff", "DRUID", "guardian");
    AddDisambiguation("arcane_torrent", "arcane_torrent_focus", "HUNTER");
    AddDisambiguation("beast_cleave", "pet_beast_cleave", "HUNTER", "beast_mastery");
    AddDisambiguation("blood_fury", "blood_fury_ap", "HUNTER");
    AddDisambiguation("cat_dire_frenzy", "pet_dire_frenzy", "HUNTER");
    AddDisambiguation("focusing_shot", "focusing_shot_marksmanship", "HUNTER", "marksmanship");
    AddDisambiguation("frenzy", "pet_frenzy", "HUNTER", "beast_mastery");
    AddDisambiguation("legendary_ring", "legendary_ring_agility", "HUNTER", undefined, "Item");
    AddDisambiguation("trueshot_debuff", "trueshot_buff", "HUNTER");
    AddDisambiguation("arcane_torrent", "arcane_torrent_mana", "MAGE");
    AddDisambiguation("arcane_charge_buff", "arcane_charge_debuff", "MAGE", "arcane");
    AddDisambiguation("blood_fury", "blood_fury_sp", "MAGE");
    AddDisambiguation("legendary_ring", "legendary_ring_intellect", "MAGE", undefined, "Item");
    AddDisambiguation("water_jet", "water_elemental_water_jet", "MAGE", "frost");
    AddDisambiguation("potion", "deadly_grace_potion", "MAGE", "arcane", "Item");
    AddDisambiguation("potion", "prolonged_power_potion", "MAGE", "fire", "Item");
    AddDisambiguation("potion", "prolonged_power_potion", "MAGE", "frost", "Item");
    AddDisambiguation("potion_buff", "deadly_grace_potion_buff", "MAGE", "arcane");
    AddDisambiguation("potion_buff", "prolonged_power_buff", "MAGE", "fire");
    AddDisambiguation("potion_buff", "prolonged_power_buff", "MAGE", "frost");
    AddDisambiguation("arcane_torrent", "arcane_torrent_chi", "MONK");
    AddDisambiguation("blood_fury", "blood_fury_apsp", "MONK");
    AddDisambiguation("chi_explosion", "chi_explosion_heal", "MONK", "mistweaver");
    AddDisambiguation("chi_explosion", "chi_explosion_melee", "MONK", "windwalker");
    AddDisambiguation("chi_explosion", "chi_explosion_tank", "MONK", "brewmaster");
    AddDisambiguation("legendary_ring", "legendary_ring_agility", "MONK", "windwalker", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_bonus_armor", "MONK", "brewmaster", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_spirit", "MONK", "mistweaver", "Item");
    AddDisambiguation("zen_sphere_debuff", "zen_sphere_buff", "MONK");
    AddDisambiguation("arcane_torrent", "arcane_torrent_holy", "PALADIN");

    AddDisambiguation("blood_fury", "blood_fury_apsp", "PALADIN");
    AddDisambiguation("judgment_debuff", "judgment_ret_debuff", "PALADIN", "retribution");
    AddDisambiguation("legendary_ring", "legendary_ring_bonus_armor", "PALADIN", "protection", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_spirit", "PALADIN", "holy", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_strength", "PALADIN", "retribution", "Item");
    AddDisambiguation("sacred_shield_debuff", "sacred_shield_buff", "PALADIN");
    AddDisambiguation("arcane_torrent", "arcane_torrent_mana", "PRIEST");
    AddDisambiguation("blood_fury", "blood_fury_sp", "PRIEST");
    AddDisambiguation("cascade", "cascade_caster", "PRIEST", "shadow");
    AddDisambiguation("cascade", "cascade_heal", "PRIEST", "discipline");
    AddDisambiguation("cascade", "cascade_heal", "PRIEST", "holy");
    AddDisambiguation("devouring_plague_tick", "devouring_plague", "PRIEST");
    AddDisambiguation("divine_star", "divine_star_caster", "PRIEST", "shadow");
    AddDisambiguation("divine_star", "divine_star_heal", "PRIEST", "discipline");
    AddDisambiguation("divine_star", "divine_star_heal", "PRIEST", "holy");
    AddDisambiguation("halo", "halo_caster", "PRIEST", "shadow");
    AddDisambiguation("halo", "halo_heal", "PRIEST", "discipline");
    AddDisambiguation("halo", "halo_heal", "PRIEST", "holy");
    AddDisambiguation("legendary_ring", "legendary_ring_intellect", "PRIEST", "shadow", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_spirit", "PRIEST", "discipline", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_spirit", "PRIEST", "holy", "Item");
    AddDisambiguation("renew_debuff", "renew_buff", "PRIEST");
    AddDisambiguation("arcane_torrent", "arcane_torrent_energy", "ROGUE");
    AddDisambiguation("blood_fury", "blood_fury_ap", "ROGUE");
    AddDisambiguation("legendary_ring", "legendary_ring_agility", "ROGUE", undefined, "Item");
    AddDisambiguation("stealth_buff", "stealthed_buff", "ROGUE");
    AddDisambiguation("roll_the_bones_debuff", "roll_the_bones_buff", "ROGUE");
    AddDisambiguation("envenom_debuff", "envenom_buff", "ROGUE");
    AddDisambiguation("vendetta_buff", "vendetta_debuff", "ROGUE", "assassination");
    AddDisambiguation("exanguinate", "exsanguinate", "ROGUE", "assassination");
    AddDisambiguation("deeper_strategem_talent", "deeper_stratagem_talent", "ROGUE", "subtlety");
    AddDisambiguation("symbols_of_death_debuff","symbols_of_death_buff", 		"ROGUE")
    AddDisambiguation("arcane_torrent", "arcane_torrent_mana", "SHAMAN");
    AddDisambiguation("ascendance", "ascendance_elemental", "SHAMAN", "elemental");
    AddDisambiguation("ascendance", "ascendance_enhancement", "SHAMAN", "enhancement");
    AddDisambiguation("blood_fury", "blood_fury_apsp", "SHAMAN");
    AddDisambiguation("legendary_ring", "legendary_ring_agility", "SHAMAN", "enhancement", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_intellect", "SHAMAN", "elemental", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_spirit", "SHAMAN", "restoration", "Item");
    AddDisambiguation("lightning_bolt", "lightning_bolt_elemental", "SHAMAN", "elemental");
    AddDisambiguation("lightning_bolt", "lightning_bolt_enhancement", "SHAMAN", "enhancement");
    AddDisambiguation("unleashed_fury", "unleashed_fury_melee", "SHAMAN", "enhancement", "Item");
    AddDisambiguation("strike", "stormstrike", "SHAMAN", "enhancement");
    AddDisambiguation("arcane_torrent", "arcane_torrent_mana", "WARLOCK");
    AddDisambiguation("blood_fury", "blood_fury_sp", "WARLOCK");
    AddDisambiguation("dark_soul", "dark_soul_instability", "WARLOCK", "destruction");
    AddDisambiguation("dark_soul", "dark_soul_knowledge", "WARLOCK", "demonology");
    AddDisambiguation("dark_soul", "dark_soul_misery", "WARLOCK", "affliction");
    AddDisambiguation("legendary_ring", "legendary_ring_intellect", "WARLOCK", undefined, "Item");
    AddDisambiguation("life_tap_debuff", "empowered_life_tap_buff", "WARLOCK");
    AddDisambiguation("soul_effigy_agony", "agony", "WARLOCK", "affliction");
    AddDisambiguation("unstable_affliction_1_debuff", "unstable_affliction_debuff", "WARLOCK", "affliction");
    AddDisambiguation("unstable_affliction_2_debuff", "unstable_affliction_debuff", "WARLOCK", "affliction");
    AddDisambiguation("unstable_affliction_3_debuff", "unstable_affliction_debuff", "WARLOCK", "affliction");
    AddDisambiguation("unstable_affliction_4_debuff", "unstable_affliction_debuff", "WARLOCK", "affliction");
    AddDisambiguation("unstable_affliction_5_debuff", "unstable_affliction_debuff", "WARLOCK", "affliction");
    AddDisambiguation("active_havoc_buff", "havoc_buff", "WARLOCK", "destruction");
    AddDisambiguation("arcane_torrent", "arcane_torrent_rage", "WARRIOR");
    AddDisambiguation("blood_fury", "blood_fury_ap", "WARRIOR");
    AddDisambiguation("legendary_ring", "legendary_ring_bonus_armor", "WARRIOR", "protection");
    AddDisambiguation("legendary_ring", "legendary_ring_strength", "WARRIOR", "arms", "Item");
    AddDisambiguation("legendary_ring", "legendary_ring_strength", "WARRIOR", "fury", "Item");
    AddDisambiguation("shield_barrier", "shield_barrier_melee", "WARRIOR", "arms");
    AddDisambiguation("shield_barrier", "shield_barrier_melee", "WARRIOR", "fury");
    AddDisambiguation("shield_barrier", "shield_barrier_tank", "WARRIOR", "protection");
    AddDisambiguation("exhaustion_buff", "burst_haste_debuff");

    //Death Knight
    AddDisambiguation("deaths_reach_talent", "deaths_reach_talent_unholy", "DEATHKNIGHT", "unholy");
    AddDisambiguation("grip_of_the_dead_talent", "grip_of_the_dead_talent_unholy", "DEATHKNIGHT", "unholy");
    AddDisambiguation("wraith_walk_talent", "wraith_walk_talent_blood", "DEATHKNIGHT", "blood");

    //Demon Hunter
    AddDisambiguation("felblade_talent", "felblade_talent_havoc", "DEMONHUNTER", "havoc");

    //Druid
    AddDisambiguation("feral_affinity_talent", "feral_affinity_talent_balance", "DRUID", "balance");
    AddDisambiguation("guardian_affinity_talent", "guardian_affinity_talent_restoration", "DRUID", "restoration");

    //Hunter
    AddDisambiguation("a_murder_of_crows_talent", "a_murder_of_crows_talent_marksman", "HUNTER", "marksman");

    //Monk
    AddDisambiguation("healing_elixir_talent", "healing_elixir_talent_mistweaver", "MONK", "mistweaver");

    //Paladin
    AddDisambiguation("judgment_of_light_talent", "judgment_of_light_talent_holy", "PALADIN", "holy");
    AddDisambiguation("unbreakable_spirit_talent", "unbreakable_spirit_talent_holy", "PALADIN", "holy");
    AddDisambiguation("cavalier_talent", "cavalier_talent_holy", "PALADIN", "holy");
    AddDisambiguation("divine_purpose_buff", "divine_purpose_buff_holy", "PALADIN", "holy");
    AddDisambiguation("judgment", "judgment_holy", "PALADIN", "holy");
    AddDisambiguation("judgment", "judgment_prot", "PALADIN", "protection");

    //Priest
    AddDisambiguation("mindbender_talent", "mindbender_talent_discipline", "PRIEST", "discipline");
    AddDisambiguation("twist_of_fate_talent", "twist_of_fate_talent_discipline", "PRIEST", "discipline");
    
    //Shaman
    AddDisambiguation("earth_shield_talent", "earth_shield_talent_restoration", "SHAMAN", "restoration");
    AddDisambiguation("echo_of_the_elements_talent", "echo_of_the_elements_talent_restoration", "SHAMAN", "restoration");

    //Warlock
    AddDisambiguation("soul_conduit_talent", "soul_conduit_talent_demonology", "WARLOCK", "demonology");

    //Warrior
    AddDisambiguation("anger_management_talent", "anger_management_talent_fury", "WARRIOR", "fury");
    AddDisambiguation("bounding_stride_talent", "bounding_stride_talent_protection", "WARRIOR", "protection");
    AddDisambiguation("dragon_roar_talent", "dragon_roar_talent_protection", "WARRIOR", "protection");
    AddDisambiguation("massacre_talent", "massacre_talent_arms", "WARRIOR", "arms");
    AddDisambiguation("storm_bolt_talent", "storm_bolt_talent_protection", "WARRIOR", "protection");
    AddDisambiguation("sudden_death_talent", "sudden_death_talent_fury", "WARRIOR", "fury");
    AddDisambiguation("bladestorm", "bladestorm_arms", "WARRIOR", "arms");
    AddDisambiguation("bladestorm", "bladestorm_fury", "WARRIOR", "fury");
    AddDisambiguation("execute", "execute_arms", "WARRIOR", "arms");
    AddDisambiguation("whirlwind", "whirlwind_arms", "WARRIOR", "arms");
}
const IsTotem = function(name: string) {
    if (sub(name, 1, 13) == "wild_mushroom") {
        return true;
    } else if (name == "prismatic_crystal" || name == "rune_of_power") {
        return true;
    } else if (sub(name, -7, -1) == "_statue") {
        return true;
    } else if (sub(name, -6, -1) == "_totem") {
        return true;
    }
    return false;
}
const NewLogicalNode = function(operator: OperatorType, lhsNode: AstNode, rhsNode: AstNode | undefined, nodeList: LuaArray<AstNode>) {
    let node = OvaleAST.NewNode(nodeList, true);
    node.type = "logical";
    node.operator = operator;
    if (operator == "not") {
        node.expressionType = "unary";
        node.child[1] = lhsNode;
    } else {
        node.expressionType = "binary";
        node.child[1] = lhsNode;
        node.child[2] = rhsNode;
    }
    return node;
}
const ConcatenatedConditionNode = function(conditionList: LuaArray<AstNode>, nodeList: LuaArray<AstNode>, annotation: Annotation) {
    let conditionNode: AstNode;
    if (lualength(conditionList) > 0) {
        if (lualength(conditionList) == 1) {
            conditionNode = conditionList[1];
        } else if (lualength(conditionList) > 1) {
            let lhsNode = conditionList[1];
            let rhsNode = conditionList[2];
            conditionNode = NewLogicalNode("or", lhsNode, rhsNode, nodeList);
            for (let k = 3; k <= lualength(conditionList); k += 1) {
                lhsNode = conditionNode;
                rhsNode = conditionList[k];
                conditionNode = NewLogicalNode("or", lhsNode, rhsNode, nodeList);
            }
        }
    }
    return conditionNode;
}
const ConcatenatedBodyNode = function(bodyList: LuaArray<AstNode>, nodeList: LuaArray<AstNode>, annotation: Annotation) {
    let bodyNode: AstNode;
    if (lualength(bodyList) > 0) {
        bodyNode = OvaleAST.NewNode(nodeList, true);
        bodyNode.type = "group";
        for (const [k, node] of ipairs(bodyList)) {
            bodyNode.child[k] = node;
        }
    }
    return bodyNode;
}
const OvaleTaggedFunctionName = function(name: string, tag: string) {
    let bodyName: string, conditionName: string;
    let [prefix, suffix] = match(name, "([A-Z]%w+)(Actions)");
    if (prefix && suffix) {
        let camelTag;
        if (tag == "shortcd") {
            camelTag = "ShortCd";
        } else {
            camelTag = CamelCase(tag);
        }
        bodyName = `${prefix}${camelTag}${suffix}`;
        conditionName = `${prefix}${camelTag}PostConditions`;
    }
    return [bodyName, conditionName];
}
const TagPriority = function(tag: string) {
    return OVALE_TAG_PRIORITY[tag] || 10;
}

type Splitter = (tag: string, node: AstNode, nodeList: LuaArray<AstNode>, annotation: Annotation) => [AstNode, AstNode]
let SPLIT_BY_TAG_VISITOR: LuaObj<Splitter> = undefined;
let SplitByTag: Splitter = undefined;
let SplitByTagAction: Splitter = undefined;
let SplitByTagAddFunction: Splitter = undefined;
let SplitByTagCustomFunction: Splitter = undefined;
let SplitByTagGroup: Splitter = undefined;
let SplitByTagIf: Splitter = undefined;
let SplitByTagState: Splitter = undefined;
SplitByTag = function (tag, node, nodeList, annotation) {
    let visitor = SPLIT_BY_TAG_VISITOR[node.type];
    if (!visitor) {
        OvaleSimulationCraft.Error("Unable to split-by-tag node of type '%s'.", node.type);
    } else {
        return visitor(tag, node, nodeList, annotation);
    }
}
SplitByTagAction = function (tag, node: FunctionNode, nodeList, annotation) {
    let bodyNode, conditionNode;
    let actionTag: string, invokesGCD: boolean;
    let name = "UNKNOWN";
    let actionType = node.func;
    if (actionType == "item" || actionType == "spell") {
        let firstParamNode = node.rawPositionalParams[1];
        let id, name;
        if (firstParamNode.type == "variable") {
            name = firstParamNode.name;
            id = annotation.dictionary && annotation.dictionary[name];
        } else if (isValueNode(firstParamNode)) {
            name = firstParamNode.value;
            id = name;
        }
        if (id) {
            if (actionType == "item") {
                [actionTag, invokesGCD] = OvaleData.GetItemTagInfo(id);
            } else if (actionType == "spell") {
                [actionTag, invokesGCD] = OvaleData.GetSpellTagInfo(id);
            }
        } else {
            OvaleSimulationCraft.Print("Warning: Unable to find %s '%s'", actionType, name);
        }
    } else if (actionType == "texture") {
        let firstParamNode = node.rawPositionalParams[1];
        let id, name;
        if (firstParamNode.type == "variable") {
            name = firstParamNode.name;
            id = annotation.dictionary && annotation.dictionary[name];
        } else if (isValueNode(firstParamNode)) {
            name = firstParamNode.value;
            id = name;
        }
        if (actionTag == undefined) {
            [actionTag, invokesGCD] = OvaleData.GetSpellTagInfo(id);
        }
        if (actionTag == undefined) {
            [actionTag, invokesGCD] = OvaleData.GetItemTagInfo(id);
        }
        if (actionTag == undefined) {
            actionTag = "main";
            invokesGCD = true;
        }
    } else {
        OvaleSimulationCraft.Print("Warning: Unknown action type '%'", actionType);
    }
    if (!actionTag) {
        actionTag = "main";
        invokesGCD = true;
        OvaleSimulationCraft.Print("Warning: Unable to determine tag for '%s', assuming '%s' (actionType: %s).", name, actionTag, actionType);
    }
    if (actionTag == tag) {
        bodyNode = node;
    } else if (invokesGCD && TagPriority(actionTag) < TagPriority(tag)) {
        conditionNode = node;
    }
    return [bodyNode, conditionNode];
}
SplitByTagAddFunction = function (tag, node, nodeList, annotation) {
    let [bodyName, conditionName] = OvaleTaggedFunctionName(node.name, tag);
    let [bodyNode, conditionNode] = SplitByTag(tag, node.child[1], nodeList, annotation);
    if (!bodyNode || bodyNode.type != "group") {
        let newGroupNode = OvaleAST.NewNode(nodeList, true);
        newGroupNode.type = "group";
        newGroupNode.child[1] = bodyNode;
        bodyNode = newGroupNode;
    }
    if (!conditionNode || conditionNode.type != "group") {
        let newGroupNode = OvaleAST.NewNode(nodeList, true);
        newGroupNode.type = "group";
        newGroupNode.child[1] = conditionNode;
        conditionNode = newGroupNode;
    }
    let bodyFunctionNode = OvaleAST.NewNode(nodeList, true);
    bodyFunctionNode.type = "add_function";
    bodyFunctionNode.name = bodyName;
    bodyFunctionNode.child[1] = bodyNode;
    let conditionFunctionNode = OvaleAST.NewNode(nodeList, true);
    conditionFunctionNode.type = "add_function";
    conditionFunctionNode.name = conditionName;
    conditionFunctionNode.child[1] = conditionNode;
    return [bodyFunctionNode, conditionFunctionNode];
}
SplitByTagCustomFunction = function (tag, node, nodeList, annotation) {
    let bodyNode, conditionNode;
    let functionName = node.name;
    if (annotation.taggedFunctionName[functionName]) {
        let [bodyName, conditionName] = OvaleTaggedFunctionName(functionName, tag);
        bodyNode = OvaleAST.NewNode(nodeList);
        bodyNode.name = bodyName;
        bodyNode.lowername = lower(bodyName);
        bodyNode.type = "custom_function";
        bodyNode.func = bodyName;
        bodyNode.asString = `${bodyName}()`;
        conditionNode = OvaleAST.NewNode(nodeList);
        conditionNode.name = conditionName;
        conditionNode.lowername = lower(conditionName);
        conditionNode.type = "custom_function";
        conditionNode.func = conditionName;
        conditionNode.asString = `${conditionName}()`;
    } else {
        let functionTag = annotation.functionTag[functionName];
        if (!functionTag) {
            if (truthy(find(functionName, "Bloodlust"))) {
                functionTag = "cd";
            } else if (truthy(find(functionName, "GetInMeleeRange"))) {
                functionTag = "shortcd";
            } else if (truthy(find(functionName, "InterruptActions"))) {
                functionTag = "cd";
            } else if (truthy(find(functionName, "SummonPet"))) {
                functionTag = "shortcd";
            } else if (truthy(find(functionName, "UseItemActions"))) {
                functionTag = "cd";
            } else if (truthy(find(functionName, "UsePotion"))) {
                functionTag = "cd";
            }
        }
        if (functionTag) {
            if (functionTag == tag) {
                bodyNode = node;
            }
        } else {
            OvaleSimulationCraft.Print("Warning: Unable to determine tag for '%s()'.", node.name);
            bodyNode = node;
        }
    }
    return [bodyNode, conditionNode];
}
SplitByTagGroup = function (tag, node, nodeList, annotation) {
    let index = lualength(node.child);
    let bodyList = {
    }
    let conditionList = {
    }
    let remainderList = {
    }
    while (index > 0) {
        let childNode = node.child[index];
        index = index - 1;
        if (childNode.type != "comment") {
            let [bodyNode, conditionNode] = SplitByTag(tag, childNode, nodeList, annotation);
            if (conditionNode) {
                insert(conditionList, 1, conditionNode);
                insert(remainderList, 1, conditionNode);
            }
            if (bodyNode) {
                if (lualength(conditionList) == 0) {
                    insert(bodyList, 1, bodyNode);
                } else if (lualength(bodyList) == 0) {
                    wipe(conditionList);
                    insert(bodyList, 1, bodyNode);
                } else {
                    let unlessNode = OvaleAST.NewNode(nodeList, true);
                    unlessNode.type = "unless";
                    unlessNode.child[1] = ConcatenatedConditionNode(conditionList, nodeList, annotation);
                    unlessNode.child[2] = ConcatenatedBodyNode(bodyList, nodeList, annotation);
                    wipe(bodyList);
                    wipe(conditionList);
                    insert(bodyList, 1, unlessNode);
                    let commentNode = OvaleAST.NewNode(nodeList);
                    commentNode.type = "comment";
                    insert(bodyList, 1, commentNode);
                    insert(bodyList, 1, bodyNode);
                }
                if (index > 0) {
                    childNode = node.child[index];
                    if (childNode.type != "comment") {
                        [bodyNode, conditionNode] = SplitByTag(tag, childNode, nodeList, annotation);
                        if (!bodyNode && index > 1) {
                            let start = index - 1;
                            for (let k = index - 1; k >= 1; k += -1) {
                                childNode = node.child[k];
                                if (childNode.type == "comment") {
                                    if (childNode.comment && sub(childNode.comment, 1, 5) == "pool_") {
                                        start = k;
                                        break;
                                    }
                                } else {
                                    break;
                                }
                            }
                            if (start < index - 1) {
                                for (let k = index - 1; k >= start; k += -1) {
                                    insert(bodyList, 1, node.child[k]);
                                }
                                index = start - 1;
                            }
                        }
                    }
                }
                while (index > 0) {
                    childNode = node.child[index];
                    if (childNode.type == "comment") {
                        insert(bodyList, 1, childNode);
                        index = index - 1;
                    } else {
                        break;
                    }
                }
            }
        }
    }
    let bodyNode = ConcatenatedBodyNode(bodyList, nodeList, annotation);
    let conditionNode = ConcatenatedConditionNode(conditionList, nodeList, annotation);
    let remainderNode = ConcatenatedConditionNode(remainderList, nodeList, annotation);
    if (bodyNode) {
        if (conditionNode) {
            let unlessNode = OvaleAST.NewNode(nodeList, true);
            unlessNode.type = "unless";
            unlessNode.child[1] = conditionNode;
            unlessNode.child[2] = bodyNode;
            let groupNode = OvaleAST.NewNode(nodeList, true);
            groupNode.type = "group";
            groupNode.child[1] = unlessNode;
            bodyNode = groupNode;
        }
        conditionNode = remainderNode;
    }
    return [bodyNode, conditionNode];
}
SplitByTagIf = function (tag, node, nodeList, annotation) {
    let [bodyNode, conditionNode] = SplitByTag(tag, node.child[2], nodeList, annotation);
    if (conditionNode) {
        let lhsNode = node.child[1];
        let rhsNode = conditionNode;
        if (node.type == "unless") {
            lhsNode = NewLogicalNode("not", lhsNode, undefined, nodeList);
        }
        let andNode = NewLogicalNode("and", lhsNode, rhsNode, nodeList);
        conditionNode = andNode;
    }
    if (bodyNode) {
        let ifNode = OvaleAST.NewNode(nodeList, true);
        ifNode.type = node.type;
        ifNode.child[1] = node.child[1];
        ifNode.child[2] = bodyNode;
        bodyNode = ifNode;
    }
    return [bodyNode, conditionNode];
}
SplitByTagState = function (tag, node, nodeList, annotation) {
    return [node, undefined];
}
{
    SPLIT_BY_TAG_VISITOR = {
        ["action"]: SplitByTagAction,
        ["add_function"]: SplitByTagAddFunction,
        ["custom_function"]: SplitByTagCustomFunction,
        ["group"]: SplitByTagGroup,
        ["if"]: SplitByTagIf,
        ["state"]: SplitByTagState,
        ["unless"]: SplitByTagIf
    }
}

type EmitVisitor = (parseNode: ParseNode, nodeList: LuaArray<AstNode>, annotation: Annotation, action?: string) => AstNode;
type EmitOperandVisitor = (operand: string, parseNode: ParseNode, nodeList: LuaArray<AstNode>, annotation: Annotation, action: string, target?: string) => [boolean, AstNode];

let EMIT_VISITOR: LuaObj<EmitVisitor> = undefined;
let Emit:EmitVisitor = undefined;
let EmitAction:EmitVisitor = undefined;
let EmitActionList:EmitVisitor = undefined;
let EmitExpression:EmitVisitor = undefined;
let EmitFunction:EmitVisitor = undefined;
let EmitNumber:EmitVisitor = undefined;
let EmitOperand:EmitVisitor = undefined;
let EmitOperandAction:EmitOperandVisitor = undefined;
let EmitOperandActiveDot:EmitOperandVisitor = undefined;
let EmitOperandArtifact:EmitOperandVisitor = undefined;
let EmitOperandAzerite:EmitOperandVisitor = undefined;
let EmitOperandBuff:EmitOperandVisitor = undefined;
let EmitOperandCharacter:EmitOperandVisitor = undefined;
let EmitOperandCooldown:EmitOperandVisitor = undefined;
let EmitOperandDisease:EmitOperandVisitor = undefined;
let EmitOperandDot:EmitOperandVisitor = undefined;
let EmitOperandGlyph:EmitOperandVisitor = undefined;
let EmitOperandPet:EmitOperandVisitor = undefined;
let EmitOperandPreviousSpell:EmitOperandVisitor = undefined;
let EmitOperandRefresh:EmitOperandVisitor = undefined;
let EmitOperandRaidEvent:EmitOperandVisitor = undefined;
let EmitOperandRace:EmitOperandVisitor = undefined;
let EmitOperandRune:EmitOperandVisitor = undefined;
let EmitOperandSeal:EmitOperandVisitor = undefined;
let EmitOperandSetBonus:EmitOperandVisitor = undefined;
let EmitOperandSpecial:EmitOperandVisitor = undefined;
let EmitOperandTalent:EmitOperandVisitor = undefined;
let EmitOperandTarget:EmitOperandVisitor = undefined;
let EmitOperandTotem:EmitOperandVisitor = undefined;
let EmitOperandTrinket:EmitOperandVisitor = undefined;
let EmitOperandVariable:EmitOperandVisitor = undefined;
Emit = function (parseNode, nodeList, annotation, action) {
    let visitor = EMIT_VISITOR[parseNode.type];
    if (!visitor) {
        OvaleSimulationCraft.Error("Unable to emit node of type '%s'.", parseNode.type);
    } else {
        return visitor(parseNode, nodeList, annotation, action);
    }
}

const EmitModifier = function (modifier: string, parseNode: ParseNode, nodeList: LuaArray<AstNode>, annotation: Annotation, action: string) {
    let node: AstNode, code;
    let className = annotation.class;
    let specialization = annotation.specialization;
    if (modifier == "if") {
        node = Emit(parseNode, nodeList, annotation, action);
    } else if (modifier == "target_if") {
        node = Emit(parseNode, nodeList, annotation, action);
    } else if (modifier == "five_stacks" && action == "focus_fire") {
        let value = tonumber(Unparse(parseNode));
        if (value == 1) {
            let buffName = "pet_frenzy_buff";
            AddSymbol(annotation, buffName);
            code = format("pet.BuffStacks(%s) >= 5", buffName);
        }
    } else if (modifier == "line_cd") {
        if (!SPECIAL_ACTION[action]) {
            AddSymbol(annotation, action);
            let expressionCode = OvaleAST.Unparse(Emit(parseNode, nodeList, annotation, action));
            code = format("TimeSincePreviousSpell(%s) > %s", action, expressionCode);
        }
    } else if (modifier == "max_cycle_targets") {
        let debuffName = `${action}_debuff`;
        AddSymbol(annotation, debuffName);
        let expressionCode = OvaleAST.Unparse(Emit(parseNode, nodeList, annotation, action));
        code = format("DebuffCountOnAny(%s) < Enemies() and DebuffCountOnAny(%s) <= %s", debuffName, debuffName, expressionCode);
    } else if (modifier == "max_energy") {
        let value = tonumber(Unparse(parseNode));
        if (value == 1) {
            code = format("Energy() >= EnergyCost(%s max=1)", action);
        }
    } else if (modifier == "min_frenzy" && action == "focus_fire") {
        let value = tonumber(Unparse(parseNode));
        if (value) {
            let buffName = "pet_frenzy_buff";
            AddSymbol(annotation, buffName);
            code = format("pet.BuffStacks(%s) >= %d", buffName, value);
        }
    } else if (modifier == "moving") {
        let value = tonumber(Unparse(parseNode));
        if (value == 0) {
            code = "not Speed() > 0";
        } else {
            code = "Speed() > 0";
        }
    } else if (modifier == "precombat") {
        let value = tonumber(Unparse(parseNode));
        if (value == 1) {
            code = "not InCombat()";
        } else {
            code = "InCombat()";
        }
    } else if (modifier == "sync") {
        let name = Unparse(parseNode);
        if (name == "whirlwind_mh") {
            name = "whirlwind";
        }
        node = annotation.astAnnotation && annotation.astAnnotation.sync && annotation.astAnnotation.sync[name];
        if (!node) {
            let syncParseNode = annotation.sync[name];
            if (syncParseNode) {
                let syncActionNode = EmitAction(syncParseNode, nodeList, annotation, action);
                let syncActionType = syncActionNode.type;
                if (syncActionType == "action") {
                    node = syncActionNode;
                } else if (syncActionType == "custom_function") {
                    node = syncActionNode;
                } else if (syncActionType == "if" || syncActionType == "unless") {
                    let lhsNode = syncActionNode.child[1];
                    if (syncActionType == "unless") {
                        let notNode = OvaleAST.NewNode(nodeList, true);
                        notNode.type = "logical";
                        notNode.expressionType = "unary";
                        notNode.operator = "not";
                        notNode.child[1] = lhsNode;
                        lhsNode = notNode;
                    }
                    let rhsNode = syncActionNode.child[2];
                    let andNode = OvaleAST.NewNode(nodeList, true);
                    andNode.type = "logical";
                    andNode.expressionType = "binary";
                    andNode.operator = "and";
                    andNode.child[1] = lhsNode;
                    andNode.child[2] = rhsNode;
                    node = andNode;
                } else {
                    OvaleSimulationCraft.Print("Warning: Unable to emit action for 'sync=%s'.", name);
                    [name] = Disambiguate(name, className, specialization);
                    AddSymbol(annotation, name);
                    code = format("Spell(%s)", name);
                }
            }
        }
        if (node) {
            annotation.astAnnotation = annotation.astAnnotation || {
            }
            annotation.astAnnotation.sync = annotation.astAnnotation.sync || {
            }
            annotation.astAnnotation.sync[name] = node;
        }
    }
    if (!node && code) {
        annotation.astAnnotation = annotation.astAnnotation || {};
        [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
    }
    return node;
}

const EmitConditionNode = function (nodeList: LuaArray<AstNode>, bodyNode: AstNode, conditionNode: AstNode, parseNode: ParseNode, annotation: Annotation, action: string) {
    let extraConditionNode = conditionNode;
    conditionNode = undefined;
    for (const [modifier, expressionNode] of pairs(parseNode.child)) {
        let rhsNode = EmitModifier(modifier, expressionNode, nodeList, annotation, action);
        if (rhsNode) {
            if (!conditionNode) {
                conditionNode = rhsNode;
            } else {
                let lhsNode = conditionNode;
                conditionNode = OvaleAST.NewNode(nodeList, true);
                conditionNode.type = "logical";
                conditionNode.expressionType = "binary";
                conditionNode.operator = "and";
                conditionNode.child[1] = lhsNode;
                conditionNode.child[2] = rhsNode;
            }
        }
    }
    if (extraConditionNode) {
        if (conditionNode) {
            let lhsNode = conditionNode;
            let rhsNode = extraConditionNode;
            conditionNode = OvaleAST.NewNode(nodeList, true);
            conditionNode.type = "logical";
            conditionNode.expressionType = "binary";
            conditionNode.operator = "and";
            conditionNode.child[1] = lhsNode;
            conditionNode.child[2] = rhsNode;
        } else {
            conditionNode = extraConditionNode;
        }
    }
    if (conditionNode) {
        let node = OvaleAST.NewNode(nodeList, true);
        node.type = "if";
        node.child[1] = conditionNode;
        node.child[2] = bodyNode;
        if (bodyNode.type == "simc_pool_resource") {
            node.simc_pool_resource = true;
        } else if (bodyNode.type == "simc_wait") {
            node.simc_wait = true;
        }
        return node;
    } else {
        return bodyNode;
    }
}
function EmitNamedVariable(name: string, nodeList: LuaArray<AstNode>, annotation: Annotation, modifier: ChildParseNode, parseNode: ParseNode, action: string, conditionNode?: AstNode) {
    if (!annotation.variable) {
        annotation.variable = {}
    }
    let node = annotation.variable[name];
    let group;
    if (!node) {
        node = OvaleAST.NewNode(nodeList, true);
        annotation.variable[name] = node;
        node.type = "add_function";
        node.name = name;
        group = OvaleAST.NewNode(nodeList, true);
        group.type = "group";
        node.child[1] = group;
    } else {
        group = node.child[1];
    }
    annotation.currentVariable = node;
    let value = Emit(modifier.value, nodeList, annotation, action);
    let newNode = EmitConditionNode(nodeList, value, conditionNode || undefined, parseNode, annotation, action);
    if (newNode.type == "if") {
        insert(group.child, 1, newNode);
    } else {
        insert(group.child, newNode);
    }
    annotation.currentVariable = undefined;
}

function EmitVariableMin(name: string, nodeList: LuaArray<AstNode>, annotation: Annotation, modifier: ChildParseNode, parseNode: ParseNode, action: string) {
    EmitNamedVariable(`${name}_min`, nodeList, annotation, modifier, parseNode, action);
    let valueNode = annotation.variable[name];
    valueNode.name = `${name}_value`;
    annotation.variable[valueNode.name] = valueNode;
    let bodyCode = format("AddFunction %s { if %s_value() > %s_min() %s_value() %s_min() }", name, name, name, name, name);
    let [node] = OvaleAST.ParseCode("add_function", bodyCode, nodeList, annotation.astAnnotation);
    annotation.variable[name] = node;
}

function EmitVariableMax(name: string, nodeList: LuaArray<AstNode>, annotation: Annotation, modifier: ChildParseNode, parseNode: ParseNode, action: string) {
    EmitNamedVariable(`${name}_max`, nodeList, annotation, modifier, parseNode, action);
    let valueNode = annotation.variable[name];
    valueNode.name = `${name}_value`;
    annotation.variable[valueNode.name] = valueNode;
    let bodyCode = format("AddFunction %s { if %s_value() < %s_max() %s_value() %s_max() }", name, name, name, name, name);
    let [node] = OvaleAST.ParseCode("add_function", bodyCode, nodeList, annotation.astAnnotation);
    annotation.variable[name] = node;
}

function EmitVariableAdd(name: string, nodeList: LuaArray<AstNode>, annotation: Annotation, modifier: ChildParseNode, parseNode: ParseNode, action: string) {
    // TODO
    let valueNode = annotation.variable[name];
    if (valueNode) return;
    EmitNamedVariable(name, nodeList, annotation, modifier, parseNode, action);
}

function EmitVariableIf(name: string, nodeList: LuaArray<AstNode>, annotation: Annotation, modifier: ChildParseNode, parseNode: ParseNode, action: string) {
    let node = annotation.variable[name];
    let group: AstNode;
    if (!node) {
        node = OvaleAST.NewNode(nodeList, true);
        annotation.variable[name] = node;
        node.type = "add_function";
        node.name = name;
        group = OvaleAST.NewNode(nodeList, true);
        group.type = "group";
        node.child[1] = group;
    } else {
        group = node.child[1];
    }

    annotation.currentVariable = node;

    const ifNode = OvaleAST.NewNode(nodeList, true);
    ifNode.type = "if";
    ifNode.child[1] = Emit(modifier.condition, nodeList, annotation);
    ifNode.child[2] = Emit(modifier.value, nodeList, annotation);
    insert(group.child, ifNode);
    const elseNode = OvaleAST.NewNode(nodeList, true);
    elseNode.type = "unless";
    elseNode.child[1] = ifNode.child[1];
    elseNode.child[2] = Emit(modifier.value_else, nodeList, annotation);
    insert(group.child, elseNode);

    annotation.currentVariable = undefined;
}

function EmitVariable(nodeList: LuaArray<AstNode>, annotation: Annotation, modifier: ChildParseNode, parseNode: ParseNode, action: string, conditionNode?: AstNode) {
    if (!annotation.variable) {
        annotation.variable = {}
    }
    let op = (modifier.op && Unparse(modifier.op)) || "set";
    let name = Unparse(modifier.name);
    if (truthy(match(name, "^%d"))) {
        name = "_" + name;
    }
    if (op == "min") {
        EmitVariableMin(name, nodeList, annotation, modifier, parseNode, action);
    } else if (op == "max") {
        EmitVariableMax(name, nodeList, annotation, modifier, parseNode, action);
    } else if (op == "add") {
        EmitVariableAdd(name, nodeList, annotation, modifier, parseNode, action);
    } else if (op == "set") {
        EmitNamedVariable(name, nodeList, annotation, modifier, parseNode, action, conditionNode);
    } else if (op === "setif") {
        EmitVariableIf(name, nodeList, annotation, modifier, parseNode, action);
    } else if (op === "reset") {
        // TODO need to refactor code to allow this kind of thing
    } else {
        OvaleSimulationCraft.Error("Unknown variable operator '%s'.", op);
    }
}
const checkOptionalSkill = function(action: string, className: string, specialization: string) {
    let data = OPTIONAL_SKILLS[action];
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
EmitAction = function (parseNode: ParseNode, nodeList, annotation) {
    let node: AstNode;
    let canonicalizedName = lower(gsub(parseNode.name, ":", "_"));
    let className = annotation.class;
    let specialization = annotation.specialization;
    let camelSpecialization = CamelSpecialization(annotation);
    let role = annotation.role;
    let [action, type] = Disambiguate(canonicalizedName, className, specialization, "Spell");
    let bodyNode: AstNode;
    let conditionNode: AstNode;
    if (action == "auto_attack" && !annotation.melee) {
    } else if (action == "auto_shot") {
    } else if (action == "choose_target") {
    } else if (action == "augmentation" || action == "flask" || action == "food") {
    } else if (action == "snapshot_stats") {
    } else {
        let bodyCode, conditionCode;
        let expressionType = "expression";
        let modifier = parseNode.child;
        let isSpellAction = true;
        if (className == "DEATHKNIGHT" && action == "antimagic_shell") {
            conditionCode = "IncomingDamage(1.5 magic=1) > 0";
        } else if (className == "DEATHKNIGHT" && action == "mind_freeze") {
            bodyCode = `${camelSpecialization}InterruptActions()`;
            annotation[action] = className;
            annotation.interrupt = className;
            isSpellAction = false;
        } else if (className == "DEMONHUNTER" && action == "consume_magic") {
            bodyCode = `${camelSpecialization}InterruptActions()`;
            annotation[action] = className;
            annotation.interrupt = className;
            isSpellAction = false;
        } else if (className == "DRUID" && action == "pulverize") {
            let debuffName = "thrash_bear_debuff";
            AddSymbol(annotation, debuffName);
            conditionCode = format("target.DebuffGain(%s) <= BaseDuration(%s)", debuffName, debuffName);
        } else if (className == "DRUID" && specialization == "guardian" && action == "rejuvenation") {
            let spellName = "enhanced_rejuvenation";
            AddSymbol(annotation, spellName);
            conditionCode = format("SpellKnown(%s)", spellName);
        } else if (className == "DRUID" && (action == "skull_bash" || action == "solar_beam")) {
            bodyCode = `${camelSpecialization}InterruptActions()`;
            annotation[action] = className;
            annotation.interrupt = className;
            isSpellAction = false;
        } else if (className == "DRUID" && action == "wild_charge") {
            bodyCode = `${camelSpecialization}GetInMeleeRange()`;
            annotation[action] = className;
            isSpellAction = false;
        } else if (className == "DRUID" && action == "new_moon") {
            conditionCode = "not SpellKnown(half_moon) and not SpellKnown(full_moon)";
            AddSymbol(annotation, "half_moon");
            AddSymbol(annotation, "full_moon");
        } else if (className == "DRUID" && action == "half_moon") {
            conditionCode = "SpellKnown(half_moon)";
        } else if (className == "DRUID" && action == "full_moon") {
            conditionCode = "SpellKnown(full_moon)";
        } else if (className == "HUNTER" && (action == "muzzle" || action == "counter_shot")) {
            bodyCode = `${camelSpecialization}InterruptActions()`;
            annotation[action] = className;
            annotation.interrupt = className;
            isSpellAction = false;
        } else if (className == "HUNTER" && action == "exotic_munitions") {
            if (modifier.ammo_type) {
                let name = Unparse(modifier.ammo_type);
                action = `${name}_ammo`;
                let buffName = "exotic_munitions_buff";
                AddSymbol(annotation, buffName);
                conditionCode = format("BuffRemaining(%s) < 1200", buffName);
            } else {
                isSpellAction = false;
            }
        } else if (className == "HUNTER" && action == "kill_command") {
            conditionCode = "pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned()";
        } else if (className == "MAGE" && action == "arcane_brilliance") {
            conditionCode = "BuffExpires(critical_strike_buff any=1) or BuffExpires(spell_power_multiplier_buff any=1)";
        } else if (className == "MAGE" && action == "counterspell") {
            bodyCode = `${camelSpecialization}InterruptActions()`;
            annotation[action] = className;
            annotation.interrupt = className;
            isSpellAction = false;
        } else if (className == "MAGE" && truthy(find(action, "pet_"))) {
            conditionCode = "pet.Present()";
        } else if (className == "MAGE" && (action == "start_burn_phase" || action == "start_pyro_chain" || action == "stop_burn_phase" || action == "stop_pyro_chain")) {
            let [stateAction, stateVariable] = match(action, "([^_]+)_(.*)");
            let value = (stateAction == "start") && 1 || 0;
            if (value == 0) {
                conditionCode = format("GetState(%s) > 0", stateVariable);
            } else {
                conditionCode = format("not GetState(%s) > 0", stateVariable);
            }
            bodyCode = format("SetState(%s %d)", stateVariable, value);
            isSpellAction = false;
        } else if (className == "MAGE" && action == "time_warp") {
            conditionCode = "CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1)";
            annotation[action] = className;
        } else if (className == "MAGE" && action == "water_elemental") {
            conditionCode = "not pet.Present()";
        } else if (className == "MONK" && action == "chi_sphere") {
            isSpellAction = false;
        } else if (className == "MONK" && action == "gift_of_the_ox") {
            isSpellAction = false;
        } else if (className == "MONK" && action == "nimble_brew") {
            conditionCode = "IsFeared() or IsRooted() or IsStunned()";
        } else if (className == "MONK" && action == "spear_hand_strike") {
            bodyCode = `${camelSpecialization}InterruptActions()`;
            annotation[action] = className;
            annotation.interrupt = className;
            isSpellAction = false;
        } else if (className == "MONK" && action == "storm_earth_and_fire") {
            conditionCode = "CheckBoxOn(opt_storm_earth_and_fire) and not BuffPresent(storm_earth_and_fire_buff)";
            annotation[action] = className;
        } else if (className == "MONK" && action == "touch_of_death") {
            conditionCode = "(not CheckBoxOn(opt_touch_of_death_on_elite_only) or (not UnitInRaid() and target.Classification(elite)) or target.Classification(worldboss)) or not BuffExpires(hidden_masters_forbidden_touch_buff)";
            annotation[action] = className;
            annotation.opt_touch_of_death_on_elite_only = "MONK";
            AddSymbol(annotation, "hidden_masters_forbidden_touch_buff");
        } else if (className == "MONK" && action == "whirling_dragon_punch") {
            conditionCode = "SpellCooldown(fists_of_fury)>0 and SpellCooldown(rising_sun_kick)>0";
        } else if (className == "PALADIN" && action == "blessing_of_kings") {
            conditionCode = "BuffExpires(mastery_buff)";
        } else if (className == "PALADIN" && action == "judgment") {
            if (modifier.cycle_targets) {
                AddSymbol(annotation, action);
                bodyCode = `Spell(${action} text=double)`;
                isSpellAction = false;
            }
        } else if (className == "PALADIN" && action == "rebuke") {
            bodyCode = `${camelSpecialization}InterruptActions()`;
            annotation[action] = className;
            annotation.interrupt = className;
            isSpellAction = false;
        } else if (className == "PALADIN" && specialization == "protection" && action == "arcane_torrent_holy") {
            isSpellAction = false;
        } else if (className == "PALADIN" && action == "righteous_fury") {
            conditionCode = "CheckBoxOn(opt_righteous_fury_check)";
            annotation[action] = className;
        } else if (className == "PRIEST" && (action == "silence" || action == "mind_bomb")) {
            bodyCode = `${camelSpecialization}InterruptActions()`;
            annotation[action] = className;
            annotation.interrupt = className;
            isSpellAction = false;
        } else if (className == "ROGUE" && action == "adrenaline_rush") {
            conditionCode = "EnergyDeficit() > 1";
        } else if (className == "ROGUE" && action == "apply_poison") {
            if (modifier.lethal) {
                let name = Unparse(modifier.lethal);
                action = `${name}_poison`;
                let buffName = "lethal_poison_buff";
                AddSymbol(annotation, buffName);
                conditionCode = format("BuffRemaining(%s) < 1200", buffName);
            } else {
                isSpellAction = false;
            }
        } else if (className == "ROGUE" && action == "between_the_eyes") {
            bodyCode = "Spell(between_the_eyes text=BTE)";
        } else if (className == "ROGUE" && specialization == "combat" && action == "blade_flurry") {
            annotation.blade_flurry = className;
            conditionCode = "CheckBoxOn(opt_blade_flurry)";
        } else if (className == "ROGUE" && action == "cancel_autoattack") {
            isSpellAction = false;
        } else if (className == "ROGUE" && action == "kick") {
            bodyCode = `${camelSpecialization}InterruptActions()`;
            annotation[action] = className;
            annotation.interrupt = className;
            isSpellAction = false;
        } else if (className == "ROGUE" && action == "pistol_shot") {
            bodyCode = "Spell(pistol_shot text=PS)";
        } else if (className == "ROGUE" && action == "premeditation") {
            conditionCode = "ComboPoints() < 5";
        } else if (className == "ROGUE" && specialization == "combat" && action == "slice_and_dice") {
            let buffName = "slice_and_dice_buff";
            AddSymbol(annotation, buffName);
            conditionCode = format("BuffRemaining(%s) < BaseDuration(%s)", buffName, buffName);
        } else if (className == "ROGUE" && (specialization == "assassination" || specialization == "combat") && action == "vanish") {
            annotation.vanish = className;
            conditionCode = format("CheckBoxOn(opt_vanish)", action);
        } else if (className == "SHAMAN" && sub(action, 1, 11) == "ascendance_") {
            let buffName = `${action}_buff`;
            AddSymbol(annotation, buffName);
            conditionCode = format("BuffExpires(%s)", buffName);
        } else if (className == "SHAMAN" && action == "bloodlust") {
            bodyCode = `${camelSpecialization}Bloodlust()`;
            annotation[action] = className;
            isSpellAction = false;
        } else if (className == "SHAMAN" && action == "magma_totem") {
            let spellName = "primal_strike";
            AddSymbol(annotation, spellName);
            conditionCode = format("target.InRange(%s)", spellName);
        } else if (className == "SHAMAN" && action == "totem_mastery") {
            conditionCode = "(not TotemPresent(totem_mastery) or InCombat()) and Speed() == 0";
            AddSymbol(annotation, "totem_mastery");
        } else if (className == "SHAMAN" && action == "wind_shear") {
            bodyCode = `${camelSpecialization}InterruptActions()`;
            annotation[action] = className;
            annotation.interrupt = className;
            isSpellAction = false;
        } else if (className == "WARLOCK" && action == "cancel_metamorphosis") {
            let spellName = "metamorphosis";
            let buffName = "metamorphosis_buff";
            AddSymbol(annotation, spellName);
            AddSymbol(annotation, buffName);
            bodyCode = format("Spell(%s text=cancel)", spellName);
            conditionCode = format("BuffPresent(%s)", buffName);
            isSpellAction = false;
        } else if (className == "WARLOCK" && action == "felguard_felstorm") {
            conditionCode = "pet.Present() and pet.CreatureFamily(Felguard)";
        } else if (className == "WARLOCK" && action == "grimoire_of_sacrifice") {
            conditionCode = "pet.Present()";
        } else if (className == "WARLOCK" && action == "havoc") {
            conditionCode = "Enemies() > 1";
        } else if (className == "WARLOCK" && action == "service_pet") {
            if (annotation.pet) {
                let spellName = `service_${annotation.pet}`;
                AddSymbol(annotation, spellName);
                bodyCode = format("Spell(%s)", spellName);
            } else {
                bodyCode = "Texture(spell_nature_removecurse help=ServicePet)";
            }
            isSpellAction = false;
        } else if (className == "WARLOCK" && action == "summon_pet") {
            if (annotation.pet) {
                let spellName = `summon_${annotation.pet}`;
                AddSymbol(annotation, spellName);
                bodyCode = format("Spell(%s)", spellName);
            } else {
                bodyCode = "Texture(spell_nature_removecurse help=L(summon_pet))";
            }
            conditionCode = "not pet.Present()";
            isSpellAction = false;
        } else if (className == "WARLOCK" && action == "wrathguard_wrathstorm") {
            conditionCode = "pet.Present() and pet.CreatureFamily(Wrathguard)";
        } else if (className == "WARRIOR" && action == "battle_shout" && role == "tank") {
            conditionCode = "BuffExpires(stamina_buff)";
        } else if (className == "WARRIOR" && action == "charge") {
            conditionCode = "CheckBoxOn(opt_melee_range) and target.InRange(charge)";
        } else if (className == "WARRIOR" && action == "commanding_shout" && role == "attack") {
            conditionCode = "BuffExpires(attack_power_multiplier_buff)";
        } else if (className == "WARRIOR" && action == "enraged_regeneration") {
            conditionCode = "HealthPercent() < 80";
        } else if (className == "WARRIOR" && sub(action, 1, 7) == "execute") {
            if (modifier.target) {
                let target = tonumber(Unparse(modifier.target));
                if (target) {
                    isSpellAction = false;
                }
            }
        } else if (className == "WARRIOR" && action == "heroic_charge") {
            isSpellAction = false;
        } else if (className == "WARRIOR" && action == "heroic_leap") {
            conditionCode = "CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40)";
        } else if (className == "WARRIOR" && action == "pummel") {
            bodyCode = `${camelSpecialization}InterruptActions()`;
            annotation[action] = className;
            annotation.interrupt = className;
            isSpellAction = false;
        } else if (action == "auto_attack") {
            bodyCode = `${camelSpecialization}GetInMeleeRange()`;
            isSpellAction = false;
        } else if (className == "DEMONHUNTER" && action == "metamorphosis_havoc") {
            conditionCode = "not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight()";
            annotation.opt_meta_only_during_boss = "DEMONHUNTER";
        } else if (checkOptionalSkill(action, className, specialization)) {
            annotation[action] = className;
            conditionCode = `CheckBoxOn(opt_${action})`;
        } else if (action == "variable") {
            EmitVariable(nodeList, annotation, modifier, parseNode, action, conditionNode);
            isSpellAction = false;
        } else if (action == "call_action_list" || action == "run_action_list" || action == "swap_action_list") {
            if (modifier.name) {
                let name = Unparse(modifier.name);
                let functionName = OvaleFunctionName(name, annotation);
                bodyCode = `${functionName}()`;
                if (className == "MAGE" && specialization == "arcane" && (name == "burn" || name == "init_burn")) {
                    conditionCode = "CheckBoxOn(opt_arcane_mage_burn_phase)";
                    annotation.opt_arcane_mage_burn_phase = className;
                }
            }
            isSpellAction = false;
        } else if (action == "cancel_buff") {
            if (modifier.name) {
                let spellName = Unparse(modifier.name);
                let buffName = `${spellName}_buff`;
                AddSymbol(annotation, spellName);
                AddSymbol(annotation, buffName);
                bodyCode = format("Texture(%s text=cancel)", spellName);
                conditionCode = format("BuffPresent(%s)", buffName);
                isSpellAction = false;
            }
        } else if (action == "pool_resource") {
            bodyNode = OvaleAST.NewNode(nodeList);
            bodyNode.type = "simc_pool_resource";
            bodyNode.for_next = (modifier.for_next != undefined);
            if (modifier.extra_amount) {
                bodyNode.extra_amount = tonumber(Unparse(modifier.extra_amount));
            }
            isSpellAction = false;
        } else if (action == "potion") {
            let name = (modifier.name && Unparse(modifier.name)) || annotation.consumables["potion"];
            if (truthy(match(name, "^(%w+)_potion"))) {
                [name] = match(name, "^(%w+)_potion");
            }
            if (name) {
                bodyCode = format("Item(%s_potion usable=1)", name);
                conditionCode = "CheckBoxOn(opt_use_consumables) and target.Classification(worldboss)";
                annotation.opt_use_consumables = className;
                AddSymbol(annotation, format("%s_potion", name));
                isSpellAction = false;
            }
        } else if (action == "stance") {
            if (modifier.choose) {
                let name = Unparse(modifier.choose);
                if (className == "MONK") {
                    action = `stance_of_the_${name}`;
                } else if (className == "WARRIOR") {
                    action = `${name}_stance`;
                } else {
                    action = name;
                }
            } else {
                isSpellAction = false;
            }
        } else if (action == "summon_pet") {
            bodyCode = `${camelSpecialization}SummonPet()`;
            annotation[action] = className;
            isSpellAction = false;
        } else if (action == "use_items") {
            bodyCode = `${camelSpecialization}UseItemActions()`;
            annotation["use_item"] = true;
            isSpellAction = false;
        } else if (action == "use_item") {
            let legendaryRing: string = undefined;
            if (modifier.slot) {
                let slot = Unparse(modifier.slot);
                if (truthy(match(slot, "finger"))) {
                    [legendaryRing] = Disambiguate("legendary_ring", className, specialization);
                }
            } else if (modifier.name) {
                let name = Unparse(modifier.name);
                [name] = Disambiguate(name, className, specialization);
                if (truthy(match(name, "legendary_ring"))) {
                    legendaryRing = name;
                }
                // } else if (false) {
                //     bodyCode = format("Item(%s usable=1)", name);
                //     AddSymbol(annotation, name);
                // }
            }
            if (legendaryRing) {
                conditionCode = format("CheckBoxOn(opt_%s)", legendaryRing);
                bodyCode = format("Item(%s usable=1)", legendaryRing);
                AddSymbol(annotation, legendaryRing);
                annotation.use_legendary_ring = legendaryRing;
            } else {
                bodyCode = `${camelSpecialization}UseItemActions()`;
                annotation[action] = true;
            }
            isSpellAction = false;
        } else if (action == "wait") {
            if (modifier.sec) {
                let seconds = tonumber(Unparse(modifier.sec));
                if (seconds) {
                } else {
                    bodyNode = OvaleAST.NewNode(nodeList);
                    bodyNode.type = "simc_wait";
                    let expressionNode = Emit(modifier.sec, nodeList, annotation, action);
                    let code = OvaleAST.Unparse(expressionNode);
                    conditionCode = code + " > 0";
                }
            }
            isSpellAction = false;
        }
        if (isSpellAction) {
            AddSymbol(annotation, action);
            if (modifier.target) {
                let actionTarget = Unparse(modifier.target);
                if (actionTarget == "2") {
                    actionTarget = "other";
                }
                if (actionTarget != "1") {
                    bodyCode = format("%s(%s text=%s)", type, action, actionTarget);
                }
            }
            bodyCode = bodyCode || `${type}(${action})`;
        }
        annotation.astAnnotation = annotation.astAnnotation || {
        }
        if (!bodyNode && bodyCode) {
            [bodyNode] = OvaleAST.ParseCode(expressionType, bodyCode, nodeList, annotation.astAnnotation);
        }
        if (!conditionNode && conditionCode) {
            [conditionNode] = OvaleAST.ParseCode(expressionType, conditionCode, nodeList, annotation.astAnnotation);
        }
        if (bodyNode) {
            node = EmitConditionNode(nodeList, bodyNode, conditionNode, parseNode, annotation, action);
        }
    }
    return node;
}
EmitActionList = function (parseNode, nodeList, annotation) {
    let groupNode = OvaleAST.NewNode(nodeList, true);
    groupNode.type = "group";
    let child = groupNode.child;
    let poolResourceNode;
    let emit = true;
    for (const [, actionNode] of ipairs(parseNode.child)) {
        let commentNode = OvaleAST.NewNode(nodeList);
        commentNode.type = "comment";
        commentNode.comment = actionNode.action;
        child[lualength(child) + 1] = commentNode;
        if (emit) {
            let statementNode = EmitAction(actionNode, nodeList, annotation);
            if (statementNode) {
                if (statementNode.type == "simc_pool_resource") {
                    let powerType = OvalePower.POOLED_RESOURCE[annotation.class];
                    if (powerType) {
                        if (statementNode.for_next) {
                            poolResourceNode = statementNode;
                            poolResourceNode.powerType = powerType;
                        } else {
                            emit = false;
                        }
                    }
                } else if (poolResourceNode) {
                    child[lualength(child) + 1] = statementNode;
                    let bodyNode;
                    let poolingConditionNode: AstNode;
                    if (statementNode.child) {
                        poolingConditionNode = statementNode.child[1];
                        bodyNode = statementNode.child[2];
                    } else {
                        bodyNode = statementNode;
                    }
                    let powerType = CamelCase(poolResourceNode.powerType);
                    let extra_amount = poolResourceNode.extra_amount;
                    if (extra_amount && poolingConditionNode) {
                        let code = OvaleAST.Unparse(poolingConditionNode);
                        let extraAmountPattern = powerType + "%(%) >= [%d.]+";
                        let replaceString = format("True(pool_%s %d)", poolResourceNode.powerType, extra_amount);
                        code = gsub(code, extraAmountPattern, replaceString);
                        [poolingConditionNode] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                    }
                    if (bodyNode.type == "action" && bodyNode.rawPositionalParams && bodyNode.rawPositionalParams[1]) {
                        let name = OvaleAST.Unparse(bodyNode.rawPositionalParams[1]);
                        let powerCondition;
                        if (extra_amount) {
                            powerCondition = format("TimeTo%s(%d)", powerType, extra_amount);
                        } else {
                            powerCondition = format("TimeTo%sFor(%s)", powerType, name);
                        }
                        let code = format("SpellUsable(%s) and SpellCooldown(%s) < %s", name, name, powerCondition);
                        let [conditionNode] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                        if (statementNode.child) {
                            let rhsNode = conditionNode;
                            conditionNode = OvaleAST.NewNode(nodeList, true);
                            conditionNode.type = "logical";
                            conditionNode.expressionType = "binary";
                            conditionNode.operator = "and";
                            conditionNode.child[1] = poolingConditionNode;
                            conditionNode.child[2] = rhsNode;
                        }
                        let restNode = OvaleAST.NewNode(nodeList, true);
                        child[lualength(child) + 1] = restNode;
                        if (statementNode.type == "unless") {
                            restNode.type = "if";
                        } else {
                            restNode.type = "unless";
                        }
                        restNode.child[1] = conditionNode;
                        restNode.child[2] = OvaleAST.NewNode(nodeList, true);
                        restNode.child[2].type = "group";
                        child = restNode.child[2].child;
                    }
                    poolResourceNode = undefined;
                } else if (statementNode.type == "simc_wait") {
                } else if (statementNode.simc_wait) {
                    let restNode = OvaleAST.NewNode(nodeList, true);
                    child[lualength(child) + 1] = restNode;
                    restNode.type = "unless";
                    restNode.child[1] = statementNode.child[1];
                    restNode.child[2] = OvaleAST.NewNode(nodeList, true);
                    restNode.child[2].type = "group";
                    child = restNode.child[2].child;
                } else {
                    child[lualength(child) + 1] = statementNode;
                    if (statementNode.simc_pool_resource) {
                        if (statementNode.type == "if") {
                            statementNode.type = "unless";
                        } else if (statementNode.type == "unless") {
                            statementNode.type = "if";
                        }
                        statementNode.child[2] = OvaleAST.NewNode(nodeList, true);
                        statementNode.child[2].type = "group";
                        child = statementNode.child[2].child;
                    }
                }
            }
        }
    }
    let node = OvaleAST.NewNode(nodeList, true);
    node.type = "add_function";
    node.name = OvaleFunctionName(parseNode.name, annotation);
    node.child[1] = groupNode;
    return node;
}
EmitExpression = function (parseNode, nodeList, annotation, action) {
    let node: AstNode;
    let msg;
    if (parseNode.expressionType == "unary") {
        let opInfo = UNARY_OPERATOR[parseNode.operator];
        if (opInfo) {
            let operator: OperatorType;
            if (parseNode.operator == "!") {
                operator = "not";
            } else if (parseNode.operator == "-") {
                operator = parseNode.operator;
            }
            if (operator) {
                let rhsNode = Emit(parseNode.child[1], nodeList, annotation, action);
                if (rhsNode) {
                    if (operator == "-" && isValueNode(rhsNode)) {
                        rhsNode.value = -1 * <number>rhsNode.value;
                    } else {
                        node = OvaleAST.NewNode(nodeList, true);
                        node.type = opInfo[1];
                        node.expressionType = "unary";
                        node.operator = operator;
                        node.precedence = opInfo[2];
                        node.child[1] = rhsNode;
                    }
                }
            }
        }
    } else if (parseNode.expressionType == "binary") {
        let opInfo = BINARY_OPERATOR[parseNode.operator];
        if (opInfo) {
            let operator: OperatorType;
            if (parseNode.operator == "&") {
                operator = "and";
            } else if (parseNode.operator == "^") {
                operator = "xor";
            } else if (parseNode.operator == "|") {
                operator = "or";
            } else if (parseNode.operator == "=") {
                operator = "==";
            } else if (parseNode.operator == "%") {
                operator = "/";
            } else if (parseNode.type == "compare" || parseNode.type == "arithmetic") {
                operator = parseNode.operator;
            }
            if (parseNode.type == "compare" && parseNode.child[1].rune) {
                let lhsNode = parseNode.child[1];
                let rhsNode = parseNode.child[2];
                let runeType = lhsNode.rune;
                let number = (rhsNode.type == "number") && tonumber(Unparse(rhsNode)) || undefined;
                if (rhsNode.type == "number") {
                    number = tonumber(Unparse(rhsNode));
                }
                if (runeType && number) {
                    let code;
                    let op = parseNode.operator;
                    let runeFunction = "Rune";
                    let runeCondition;
                    runeCondition = `${runeFunction}()`;
                    if (op == ">") {
                        code = format("%s >= %d", runeCondition, number + 1);
                    } else if (op == ">=") {
                        code = format("%s >= %d", runeCondition, number);
                    } else if (op == "=") {
                        code = format("%s >= %d", runeCondition, number);
                    } else if (op == "<=") {
                        code = format("%s < %d", runeCondition, number + 1);
                    } else if (op == "<") {
                        code = format("%s < %d", runeCondition, number);
                    }
                    if (!node && code) {
                        annotation.astAnnotation = annotation.astAnnotation || {};
                        [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
                    }
                }
            } else if ((parseNode.operator == "=" || parseNode.operator == "!=") && (parseNode.child[1].name == "target" || parseNode.child[1].name == "current_target")) {
                let rhsNode = parseNode.child[2];
                let name = rhsNode.name;
                if (truthy(find(name, "^[%a_]+%."))) {
                    [name] = match(name, "^[%a_]+%.([%a_]+)");
                }
                let code;
                if (parseNode.operator == "=") {
                    if (name == "sim_target") {
                        code = "True(target_is_sim_target)";
                    } else {
                        code = format("target.Name(%s)", name);
                        AddSymbol(annotation, name);
                    }
                } else {
                    code = format("not target.Name(%s)", name);
                    AddSymbol(annotation, name);
                }
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            } else if ((parseNode.operator == "=" || parseNode.operator == "!=") && parseNode.child[1].name == "sim_target") {
                let code;
                if (parseNode.operator == "=") {
                    code = "True(target_is_sim_target)";
                } else {
                    code = "False(target_is_sim_target)";
                }
                annotation.astAnnotation = annotation.astAnnotation || {};
                [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            } else if (operator) {
                let lhsNode = Emit(parseNode.child[1], nodeList, annotation, action);
                let rhsNode = Emit(parseNode.child[2], nodeList, annotation, action);
                if (lhsNode && rhsNode) {
                    node = OvaleAST.NewNode(nodeList, true);
                    node.type = opInfo[1];
                    node.expressionType = "binary";
                    node.operator = operator;
                    node.child[1] = lhsNode;
                    node.child[2] = rhsNode;
                } else if (lhsNode) {
                    msg = MakeString("Warning: %s operator '%s' right failed.", parseNode.type, parseNode.operator);
                } else if (rhsNode) {
                    msg = MakeString("Warning: %s operator '%s' left failed.", parseNode.type, parseNode.operator);
                } else {
                    msg = MakeString("Warning: %s operator '%s' left and right failed.", parseNode.type, parseNode.operator);
                }
            }
        }
    }
    if (node) {
        if (parseNode.left && parseNode.right) {
            node.left = "{";
            node.right = "}";
        }
    } else {
        msg = msg || MakeString("Warning: Operator '%s' is not implemented.", parseNode.operator);
        OvaleSimulationCraft.Print(msg);
        const stringNode = <StringNode>OvaleAST.NewNode(nodeList);
        stringNode.type = "string";
        stringNode.value = `FIXME_${parseNode.operator}`;
        return stringNode;
    }
    return node;
}
EmitFunction = function (parseNode, nodeList, annotation, action) {
    let node;
    if (parseNode.name == "ceil" || parseNode.name == "floor") {
        node = EmitExpression(parseNode.child[1], nodeList, annotation, action);
    } else {
        OvaleSimulationCraft.Print("Warning: Function '%s' is not implemented.", parseNode.name);
        node = OvaleAST.NewNode(nodeList);
        node.type = "variable";
        node.name = `FIXME_${parseNode.name}`;
    }
    return node;
}

EmitNumber = function (parseNode, nodeList, annotation, action) {
    let node = <ValueNode>OvaleAST.NewNode(nodeList);
    node.type = "value";
    node.value = parseNode.value;
    node.origin = 0;
    node.rate = 0;
    return node;
}
EmitOperand = function (parseNode, nodeList, annotation, action) {
    let ok = false;
    let node;
    let operand = parseNode.name;
    let [token] = match(operand, OPERAND_TOKEN_PATTERN);
    let target;
    if (token == "target") {
        [ok, node] = EmitOperandTarget(operand, parseNode, nodeList, annotation, action);
        if (!ok) {
            target = token;
            operand = sub(operand, len(target) + 2);
            [token] = match(operand, OPERAND_TOKEN_PATTERN);
        }
    }
    if (!ok) {
        [ok, node] = EmitOperandRune(operand, parseNode, nodeList, annotation, action);
    }
    if (!ok) {
        [ok, node] = EmitOperandSpecial(operand, parseNode, nodeList, annotation, action, target);
    }
    if (!ok) {
        [ok, node] = EmitOperandRaidEvent(operand, parseNode, nodeList, annotation, action);
    }
    if (!ok) {
        [ok, node] = EmitOperandRace(operand, parseNode, nodeList, annotation, action);
    }
    if (!ok) {
        [ok, node] = EmitOperandAction(operand, parseNode, nodeList, annotation, action, target);
    }
    if (!ok) {
        [ok, node] = EmitOperandCharacter(operand, parseNode, nodeList, annotation, action, target);
    }
    if (!ok) {
        if (token == "active_dot") {
            target = target || "target";
            [ok, node] = EmitOperandActiveDot(operand, parseNode, nodeList, annotation, action, target);
        } else if (token == "aura") {
            [ok, node] = EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target);
        } else if (token == "artifact") {
            [ok, node] = EmitOperandArtifact(operand, parseNode, nodeList, annotation, action, target);
        } else if (token == "azerite") {
            [ok, node] = EmitOperandAzerite(operand, parseNode, nodeList, annotation, action, target);
        } else if (token == "buff") {
            [ok, node] = EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target);
        } else if (token == "consumable") {
            [ok, node] = EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target);
        } else if (token == "cooldown") {
            [ok, node] = EmitOperandCooldown(operand, parseNode, nodeList, annotation, action);
        } else if (token == "debuff") {
            target = target || "target";
            [ok, node] = EmitOperandBuff(operand, parseNode, nodeList, annotation, action, target);
        } else if (token == "disease") {
            target = target || "target";
            [ok, node] = EmitOperandDisease(operand, parseNode, nodeList, annotation, action, target);
        } else if (token == "dot") {
            target = target || "target";
            [ok, node] = EmitOperandDot(operand, parseNode, nodeList, annotation, action, target);
        } else if (token == "glyph") {
            [ok, node] = EmitOperandGlyph(operand, parseNode, nodeList, annotation, action);
        } else if (token == "pet") {
            [ok, node] = EmitOperandPet(operand, parseNode, nodeList, annotation, action);
        } else if (token == "prev" || token == "prev_gcd" || token == "prev_off_gcd") {
            [ok, node] = EmitOperandPreviousSpell(operand, parseNode, nodeList, annotation, action);
        } else if (token == "refreshable") {
            [ok, node] = EmitOperandRefresh(operand, parseNode, nodeList, annotation, action);
        } else if (token == "seal") {
            [ok, node] = EmitOperandSeal(operand, parseNode, nodeList, annotation, action);
        } else if (token == "set_bonus") {
            [ok, node] = EmitOperandSetBonus(operand, parseNode, nodeList, annotation, action);
        } else if (token == "talent") {
            [ok, node] = EmitOperandTalent(operand, parseNode, nodeList, annotation, action);
        } else if (token == "totem") {
            [ok, node] = EmitOperandTotem(operand, parseNode, nodeList, annotation, action);
        } else if (token == "trinket") {
            [ok, node] = EmitOperandTrinket(operand, parseNode, nodeList, annotation, action);
        } else if (token == "variable") {
            [ok, node] = EmitOperandVariable(operand, parseNode, nodeList, annotation, action);
        } else if (token == "ground_aoe") {
            [ok, node] = EmitOperandGroundAoe(operand, parseNode, nodeList, annotation, action);
        }
    }
    if (!ok) {
        OvaleSimulationCraft.Print("Warning: Variable '%s' is not implemented.", parseNode.name);
        node = OvaleAST.NewNode(nodeList);
        node.type = "variable";
        node.name = `FIXME_${parseNode.name}`;
    }
    return node;
}
EmitOperandAction = function (operand, parseNode, nodeList, annotation, action, target) {
    let ok = true;
    let node;
    let name;
    let property;
    if (sub(operand, 1, 7) == "action.") {
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        tokenIterator();
        name = tokenIterator();
        property = tokenIterator();
    } else {
        name = action;
        property = operand;
    }

    let [className, specialization] = [annotation.class, annotation.specialization];
    [name] = Disambiguate(name, className, specialization);
    target = target && (`${target}.`) || "";
    let buffName = `${name}_debuff`;
    [buffName] = Disambiguate(buffName, className, specialization);
    let prefix = truthy(find(buffName, "_buff$")) && "Buff" || "Debuff";
    let buffTarget = (prefix == "Debuff") && "target." || target;
    let talentName = `${name}_talent`;
    [talentName] = Disambiguate(talentName, className, specialization);
    let symbol = name;
    let code;
    if (property == "active") {
        if (IsTotem(name)) {
            code = format("TotemPresent(%s)", name);
        } else {
            code = format("%s%sPresent(%s)", target, prefix, buffName);
            symbol = buffName;
        }
    } else if (property == "cast_regen") {
        code = format("FocusCastingRegen(%s)", name);
    } else if (property == "cast_time") {
        code = format("CastTime(%s)", name);
    } else if (property == "charges") {
        code = format("Charges(%s)", name);
    } else if (property == "max_charges") {
        code = format("SpellMaxCharges(%s)", name);
    } else if (property == "charges_fractional") {
        code = format("Charges(%s count=0)", name);
    } else if (property == "cooldown") {
        code = format("SpellCooldown(%s)", name);
    } else if (property == "cooldown_react") {
        code = format("not SpellCooldown(%s) > 0", name);
    } else if (property == "cost") {
        code = format("PowerCost(%s)", name);
    } else if (property == "crit_damage") {
        code = format("%sCritDamage(%s)", target, name);
    } else if (property == "duration" || property == "new_duration") {
        code = format("BaseDuration(%s)", buffName);
        symbol = buffName;
    } else if (property == "enabled") {
        if (parseNode.asType == "boolean") {
            code = format("Talent(%s)", talentName);
        } else {
            code = format("TalentPoints(%s)", talentName);
        }
        symbol = talentName;
    } else if (property == "execute_time") {
        code = format("ExecuteTime(%s)", name);
    } else if (property == "gcd") {
        code = "GCD()";
    } else if (property == "hit_damage") {
        code = format("%sDamage(%s)", target, name);
    } else if (property == "in_flight" || property == "in_flight_to_target") {
        code = format("InFlightToTarget(%s)", name);
    } else if (property == "miss_react") {
        code = "True(miss_react)";
    } else if (property == "persistent_multiplier" || property == "pmultiplier") {
        code = format("PersistentMultiplier(%s)", buffName);
    } else if (property == "recharge_time") {
        code = format("SpellChargeCooldown(%s)", name);
    } else if (property == "full_recharge_time") {
        code = format("SpellFullRecharge(%s)", name)
    } else if (property == "remains") {
        if (IsTotem(name)) {
            code = format("TotemRemaining(%s)", name);
        } else {
            code = format("%s%sRemaining(%s)", buffTarget, prefix, buffName);
            symbol = buffName;
        }
    } else if (property == "shard_react") {
        code = "SoulShards() >= 1";
    } else if (property == "tick_time") {
        code = format("%sTickTime(%s)", buffTarget, buffName);
        symbol = buffName;
    } else if (property == "ticking") {
        code = format("%s%sPresent(%s)", buffTarget, prefix, buffName);
        symbol = buffName;
    } else if (property == "ticks_remain") {
        code = format("%sTicksRemaining(%s)", buffTarget, buffName);
        symbol = buffName;
    } else if (property == "travel_time") {
        code = format("TravelTime(%s)", name);
    } else if (property == "usable") {
        code = format("CanCast(%s)", name);
    } else if (property == "usable_in") {
        code = format("SpellCooldown(%s)", name);
    } else if (property == "marks_next_gcd") {
        code = "0"; // TODO
    } else {
        ok = false;
    }
    if (ok && code) {
        if (name == "call_action_list" && property != "gcd") {
            OvaleSimulationCraft.Print("Warning: dubious use of call_action_list in %s", code);
        }
        annotation.astAnnotation = annotation.astAnnotation || {};
        [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        if (!SPECIAL_ACTION[symbol]) {
            AddSymbol(annotation, symbol);
        }
    }
    return [ok, node];
}
EmitOperandActiveDot = function (operand, parseNode, nodeList, annotation, action, target) {
    let ok = true;
    let node;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "active_dot") {
        let name = tokenIterator();
        [name] = Disambiguate(name, annotation.class, annotation.specialization);
        let dotName = `${name}_debuff`;
        [dotName] = Disambiguate(dotName, annotation.class, annotation.specialization);
        let prefix = truthy(find(dotName, "_buff$")) && "Buff" || "Debuff";
        target = target && (`${target}.`) || "";
        let code = format("%sCountOnAny(%s)", prefix, dotName);
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            AddSymbol(annotation, dotName);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandArtifact = function (operand, parseNode, nodeList, annotation, action, target) {
    let ok = true;
    let node;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "artifact") {
        let code:string;
        let name = tokenIterator();
        let property = tokenIterator();
        if (property == "rank") {
            code = format("ArtifactTraitRank(%s)", name);
        } else if (property == "enabled") {
            code = format("HasArtifactTrait(%s)", name);
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            AddSymbol(annotation, name);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandAzerite = function (operand, parseNode, nodeList, annotation, action, target) {
    let ok = true;
    let node;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "azerite") {
        let code:string;
        let name = tokenIterator();
        let property = tokenIterator();
        if (property == "enabled") {
            code = format("HasAzeriteTrait(%s)", name);
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            AddSymbol(annotation, name);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandRefresh = function (operand, parseNode, nodeList, annotation, action, target) {
    let ok = true;
    let node;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "refreshable") {
        let buffName = `${action}_debuff`;
        [buffName] = Disambiguate(buffName, annotation.class, annotation.specialization);
        let target;
        let prefix = truthy(find(buffName, "_buff$")) && "Buff" || "Debuff";
        if (prefix == "Debuff") {
            target = "target.";
        } else {
            target = "";
        }
        let any = OvaleData.DEFAULT_SPELL_LIST[buffName] && " any=1" || "";
        let code = format("%sRefreshable(%s%s)", target, buffName, any);
        [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        AddSymbol(annotation, buffName);
    }
    return [ok, node];
}
EmitOperandBuff = function (operand, parseNode, nodeList, annotation, action, target) {
    let ok = true;
    let node;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "aura" || token == "buff" || token == "debuff" || token == "consumable") {
        let name = tokenIterator();
        let property = tokenIterator();
        if ((token == "consumable" && property == undefined)) {
            property = "remains";
        }
        [name] = Disambiguate(name, annotation.class, annotation.specialization);
        let buffName = (token == "debuff") && `${name}_debuff` || `${name}_buff`;
        [buffName] = Disambiguate(buffName, annotation.class, annotation.specialization);
        let prefix = truthy(find(buffName, "_buff$")) && "Buff" || "Debuff";
        let any = OvaleData.DEFAULT_SPELL_LIST[buffName] && " any=1" || "";
        target = target && (`${target}.`) || "";
        if (buffName == "dark_transformation_buff" && target == "") {
            target = "pet.";
        }
        if (buffName == "pet_beast_cleave_buff" && target == "") {
            target = "pet.";
        }
        if (buffName == "pet_frenzy_buff" && target == "") {
            target = "pet.";
        }
        let code;
        if (property == "cooldown_remains") {
            code = format("SpellCooldown(%s)", name);
        } else if (property == "down") {
            code = format("%s%sExpires(%s%s)", target, prefix, buffName, any);
        } else if (property == "duration") {
            code = format("BaseDuration(%s)", buffName);
        } else if (property == "max_stack") {
            code = format("SpellData(%s max_stacks)", buffName);
        } else if (property == "react" || property == "stack") {
            if (parseNode.asType == "boolean") {
                code = format("%s%sPresent(%s%s)", target, prefix, buffName, any);
            } else {
                code = format("%s%sStacks(%s%s)", target, prefix, buffName, any);
            }
        } else if (property == "remains") {
            if (parseNode.asType == "boolean") {
                code = format("%s%sPresent(%s%s)", target, prefix, buffName, any);
            } else {
                code = format("%s%sRemaining(%s%s)", target, prefix, buffName, any);
            }
        } else if (property == "up") {
            code = format("%s%sPresent(%s%s)", target, prefix, buffName, any);
        } else if (property == "improved") {
            code = format("%sImproved(%s%s)", prefix, buffName);
        } else if (property == "value") {
            code = format("%s%sAmount(%s%s)", target, prefix, buffName, any);
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            AddSymbol(annotation, buffName);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
{
    let CHARACTER_PROPERTY: LuaObj<string> = {
        ["active_enemies"]: "Enemies()",
        ["astral_power"]: "AstralPower()",
        ["astral_power.deficit"]: "AstralPowerDeficit()",
        ["blade_dance_worth_using"]: "0",
        ["blood.frac"]: "Rune(blood)",
        ["buff.out_of_range.up"]: "not target.InRange()",
        ["bugs"]: "0",
        ["chi"]: "Chi()",
        ["chi.max"]: "MaxChi()",
        ["combo_points"]: "ComboPoints()",
        ["combo_points.deficit"]: "ComboPointsDeficit()",
        ["combo_points.max"]: "MaxComboPoints()",
        ["cp_max_spend"]: "MaxComboPoints()",
        ["crit_pct_current"]: "SpellCritChance()",
        ["current_insanity_drain"]: "CurrentInsanityDrain()",
        ["darkglare_no_de"]: "NotDeDemons(darkglare)",
        ["death_sweep_worth_using"]: "0",
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
        ["feral_spirit.remains"]: "TotemRemaining(sprit_wolf)",
        ["finality"]: "HasArtifactTrait(finality)",
        ["focus"]: "Focus()",
        ["focus.deficit"]: "FocusDeficit()",
        ["focus.max"]: "MaxFocus()",
        ["focus.regen"]: "FocusRegenRate()",
        ["focus.time_to_max"]: "TimeToMaxFocus()",
        ["frost.frac"]: "Rune(frost)",
        ["fury"]: "Fury()",
        ["fury.deficit"]: "FuryDeficit()",
        ["health"]: "Health()",
        ["health.deficit"]: "HealthMissing()",
        ["health.max"]: "MaxHealth()",
        ["health.pct"]: "HealthPercent()",
        ["health.percent"]: "HealthPercent()",
        ["holy_power"]: "HolyPower()",
        ["infernal_no_de"]: "NotDeDemons(infernal)",
        ["insanity"]: "Insanity()",
        ["level"]: "Level()",
        ["lunar_max"]: "TimeToEclipse(lunar)",
        ["mana"]: "Mana()",
        ["mana.deficit"]: "ManaDeficit()",
        ["mana.max"]: "MaxMana()",
        ["mana.pct"]: "ManaPercent()",
        ["maelstrom"]: "Maelstrom()",
        ["nonexecute_actors_pct"]: "0",
        ["pain"]: "Pain()",
        ["pain.deficit"]: "PainDeficit()",
        ["pet_count"]: "Demons()",
        ["rage"]: "Rage()",
        ["rage.deficit"]: "RageDeficit()",
        ["rage.max"]: "MaxRage()",
        ["raid_event.adds.remains"]: "0", // TODO
        ["raw_haste_pct"]: "SpellHaste()",
        ["rtb_list.any.5"]: "BuffCount(roll_the_bones_buff more 4)",
        ["rtb_list.any.6"]: "BuffCount(roll_the_bones_buff more 5)",
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
        ["time_to_die"]: "TimeToDie()",
        ["time_to_die.remains"]: "TimeToDie()",
        ["time_to_sht.4"]: "100", // TODO
        ["time_to_sht.5"]: "100",
        ["wild_imp_count"]: "Demons(wild_imp)",
        ["wild_imp_no_de"]: "NotDeDemons(wild_imp)",
        ["wild_imp_remaining_duration"]: "DemonDuration(wild_imp)"
    }
    EmitOperandCharacter = function (operand, parseNode, nodeList, annotation, action, target) {
        let ok = true;
        let node;
        let className = annotation.class;
        let specialization = annotation.specialization;
        let camelSpecialization = CamelSpecialization(annotation);
        target = target && (`${target}.`) || "";
        let code;
        if (CHARACTER_PROPERTY[operand]) {
            code = `${target}${CHARACTER_PROPERTY[operand]}`;
        } else if (className == "MAGE" && operand == "incanters_flow_dir") {
            let name = "incanters_flow_buff";
            code = format("BuffDirection(%s)", name);
            AddSymbol(annotation, name);
        } else if (className == "PALADIN" && operand == "time_to_hpg") {
            code = `${camelSpecialization}TimeToHPG()`;
            if (specialization == "holy") {
                annotation.time_to_hpg_heal = className;
            } else if (specialization == "protection") {
                annotation.time_to_hpg_tank = className;
            } else if (specialization == "retribution") {
                annotation.time_to_hpg_melee = className;
            }
        } else if (className == "PRIEST" && operand == "shadowy_apparitions_in_flight") {
            code = "1";
        } else if (operand == "rtb_buffs") {
            code = "BuffCount(roll_the_bones_buff)";
        } else if (className == "ROGUE" && operand == "anticipation_charges") {
            let name = "anticipation_buff";
            code = format("BuffStacks(%s)", name);
            AddSymbol(annotation, name);
        } else if (sub(operand, 1, 22) == "active_enemies_within.") {
            code = "Enemies()";
        } else if (truthy(find(operand, "^incoming_damage_"))) {
            let [_seconds, measure] = match(operand, "^incoming_damage_([%d]+)(m?s?)$");
            let seconds = tonumber(_seconds);
            if (measure == "ms") {
                seconds = seconds / 1000;
            }
            if (parseNode.asType == "boolean") {
                code = format("IncomingDamage(%f) > 0", seconds);
            } else {
                code = format("IncomingDamage(%f)", seconds);
            }
        } else if (sub(operand, 1, 10) == "main_hand.") {
            let weaponType = sub(operand, 11);
            if (weaponType == "1h") {
                code = "HasWeapon(main type=one_handed)";
            } else if (weaponType == "2h") {
                code = "HasWeapon(main type=two_handed)";
            }
        } else if (operand == "mastery_value") {
            code = format("%sMasteryEffect() / 100", target);
        } else if (operand == "position_front") {
            code = "False(position_front)";
        } else if (sub(operand, 1, 5) == "role.") {
            let [role] = match(operand, "^role%.([%w_]+)");
            if (role && role == annotation.role) {
                code = format("True(role_%s)", role);
            } else {
                code = format("False(role_%s)", role);
            }
        } else if (operand == "spell_haste" || operand == "stat.spell_haste") {
            code = "100 / { 100 + SpellHaste() }";
        } else if (operand == "attack_haste" || operand == "stat.attack_haste") {
            code = "100 / { 100 + MeleeHaste() }";
        } else if (sub(operand, 1, 13) == "spell_targets") {
            code = "Enemies()";
        } else if (operand == "t18_class_trinket") {
            code = format("HasTrinket(%s)", operand);
            AddSymbol(annotation, operand);
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        }
        return [ok, node];
    }
}
EmitOperandCooldown = function (operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "cooldown") {
        let name = tokenIterator();
        let property = tokenIterator();
        let prefix;
        [name, prefix] = Disambiguate(name, annotation.class, annotation.specialization, "Spell");
        let code;
        if (property == "execute_time") {
            code = format("ExecuteTime(%s)", name);
        } else if (property == "duration") {
            code = format("%sCooldownDuration(%s)", prefix, name);
        } else if (property == "ready") {
            code = format("%sCooldown(%s) == 0", prefix, name);
        } else if (property == "remains" || property == "adjusted_remains") {
            if (parseNode.asType == "boolean") {
                code = format("%sCooldown(%s) > 0", prefix, name);
            } else {
                code = format("%sCooldown(%s)", prefix, name);
            }
        } else if (property == "up") {
            code = format("not %sCooldown(%s) > 0", prefix, name);
        } else if (property == "charges") {
            if (parseNode.asType == "boolean") {
                code = format("%sCharges(%s) > 0", prefix, name);
            } else {
                code = format("%sCharges(%s)", prefix, name);
            }
        } else if (property == "charges_fractional") {
            code = format("%sCharges(%s count=0)", prefix, name);
        } else if (property == "full_recharge_time") {
            code = format("%sCooldown(%s)", prefix, name);
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            AddSymbol(annotation, name);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandDisease = function (operand, parseNode, nodeList, annotation, action, target) {
    let ok = true;
    let node;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "disease") {
        let property = tokenIterator();
        target = target && (`${target}.`) || "";
        let code;
        if (property == "max_ticking") {
            code = `${target}DiseasesAnyTicking()`;
        } else if (property == "min_remains") {
            code = `${target}DiseasesRemaining()`;
        } else if (property == "min_ticking") {
            code = `${target}DiseasesTicking()`;
        } else if (property == "ticking") {
            code = `${target}DiseasesAnyTicking()`;
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}

function EmitOperandGroundAoe(operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "ground_aoe") {
        let name = tokenIterator();
        let property = tokenIterator();
        [name] = Disambiguate(name, annotation.class, annotation.specialization);
        let dotName = `${name}_debuff`;
        [dotName] = Disambiguate(dotName, annotation.class, annotation.specialization);
        let prefix = truthy(find(dotName, "_buff$")) && "Buff" || "Debuff";
        const target = "";
        let code;
        if (property == "remains") {
            code = format("%s%sRemaining(%s)", target, prefix, dotName);
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            AddSymbol(annotation, dotName);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}

EmitOperandDot = function (operand, parseNode, nodeList, annotation, action, target) {
    let ok = true;
    let node;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "dot") {
        let name = tokenIterator();
        let property = tokenIterator();
        [name] = Disambiguate(name, annotation.class, annotation.specialization);
        let dotName = `${name}_debuff`;
        [dotName] = Disambiguate(dotName, annotation.class, annotation.specialization);
        let prefix = truthy(find(dotName, "_buff$")) && "Buff" || "Debuff";
        target = target && (`${target}.`) || "";
        let code;
        if (property == "duration") {
            code = format("%s%sDuration(%s)", target, prefix, dotName);
        } else if (property == "pmultiplier") {
            code = format("%s%sPersistentMultiplier(%s)", target, prefix, dotName);
        } else if (property == "remains") {
            code = format("%s%sRemaining(%s)", target, prefix, dotName);
        } else if (property == "stack") {
            code = format("%s%sStacks(%s)", target, prefix, dotName);
        } else if (property == "tick_dmg") {
            code = format("%sTickValue(%s)", target, prefix, dotName);
        } else if (property == "ticking") {
            code = format("%s%sPresent(%s)", target, prefix, dotName);
        } else if (property == "ticks_remain") {
            code = format("%sTicksRemaining(%s)", target, dotName);
        } else if (property == "tick_time_remains") {
            code = format("%sTickTimeRemaining(%s)", target, dotName);
        } else if (property == "exsanguinated") {
            code = format("TargetDebuffRemaining(%s_exsanguinated)", dotName);
        } else if (property == "refreshable") {
            code = format("%s%sRefreshable(%s)", target, prefix, dotName);
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            AddSymbol(annotation, dotName);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandGlyph = function (operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node: AstNode;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "glyph") {
        let name = tokenIterator();
        let property = tokenIterator();
        [name] = Disambiguate(name, annotation.class, annotation.specialization);
        let glyphName = `glyph_of_${name}`;
        [glyphName] = Disambiguate(glyphName, annotation.class, annotation.specialization);
        let code;
        if (property == "disabled") {
            code = format("not Glyph(%s)", glyphName);
        } else if (property == "enabled") {
            code = format("Glyph(%s)", glyphName);
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            AddSymbol(annotation, glyphName);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandPet = function (operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node: AstNode;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "pet") {
        let name = tokenIterator();
        let property = tokenIterator();
        [name] = Disambiguate(name, annotation.class, annotation.specialization);
        let isTotem = IsTotem(name);
        let code;
        if (isTotem && property == "active") {
            code = format("TotemPresent(%s)", name);
        } else if (isTotem && property == "remains") {
            code = format("TotemRemaining(%s)", name);
        } else if (property == "active") {
            code = "pet.Present()";
        } else if (name == "buff") {
            let pattern = format("^pet%%.([%%w_.]+)", operand);
            let [petOperand] = match(operand, pattern);
            [ok, node] = EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, "pet");
        } else {
            let pattern = format("^pet%%.%s%%.([%%w_.]+)", name);
            let [petOperand] = match(operand, pattern);
            let target = "pet";
            if (petOperand) {
                [ok, node] = EmitOperandSpecial(petOperand, parseNode, nodeList, annotation, action, target);
                if (!ok) {
                    [ok, node] = EmitOperandAction(petOperand, parseNode, nodeList, annotation, action, target);
                }
                if (!ok) {
                    [ok, node] = EmitOperandCharacter(petOperand, parseNode, nodeList, annotation, action, target);
                }
                if (!ok) {
                    let [petAbilityName] = match(petOperand, "^[%w_]+%.([^.]+)");
                    [petAbilityName] = Disambiguate(petAbilityName, annotation.class, annotation.specialization);
                    if (sub(petAbilityName, 1, 4) != "pet_") {
                        petOperand = gsub(petOperand, "^([%w_]+)%.", `%1.${name}_`);
                    }
                    if (property == "buff") {
                        [ok, node] = EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, target);
                    } else if (property == "cooldown") {
                        [ok, node] = EmitOperandCooldown(petOperand, parseNode, nodeList, annotation, action);
                    } else if (property == "debuff") {
                        [ok, node] = EmitOperandBuff(petOperand, parseNode, nodeList, annotation, action, target);
                    } else if (property == "dot") {
                        [ok, node] = EmitOperandDot(petOperand, parseNode, nodeList, annotation, action, target);
                    } else {
                        ok = false;
                    }
                }
            } else {
                ok = false;
            }
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            AddSymbol(annotation, name);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandPreviousSpell = function (operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node: AstNode;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "prev" || token == "prev_gcd" || token == "prev_off_gcd") {
        let name = tokenIterator();
        let howMany = 1;
        if (tonumber(name)) {
            howMany = tonumber(name);
            name = tokenIterator();
        }
        [name] = Disambiguate(name, annotation.class, annotation.specialization);
        let code;
        if (token == "prev") {
            code = format("PreviousSpell(%s)", name);
        } else if (token == "prev_gcd") {
            if (howMany != 1) {
                code = format("PreviousGCDSpell(%s count=%d)", name, howMany);
            } else {
                code = format("PreviousGCDSpell(%s)", name);
            }
        } else {
            code = format("PreviousOffGCDSpell(%s)", name);
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            AddSymbol(annotation, name);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandRaidEvent = function (operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node: AstNode;
    let name;
    let property;
    if (sub(operand, 1, 11) == "raid_event.") {
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        tokenIterator();
        name = tokenIterator();
        property = tokenIterator();
    } else {
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        name = tokenIterator();
        property = tokenIterator();
    }
    let code;
    if (name == "movement") {
        if (property == "cooldown" || property == "in") {
            code = "600";
        } else if (property == "distance") {
            code = "target.Distance()";
        } else if (property == "exists") {
            code = "False(raid_event_movement_exists)";
        } else if (property == "remains") {
            code = "0";
        } else {
            ok = false;
        }
    } else if (name == "adds") {
        if (property == "cooldown") {
            code = "600";
        } else if (property == "count") {
            code = "0";
        } else if (property == "exists" || property == "up") {
            code = "False(raid_event_adds_exists)";
        } else if (property == "in") {
            code = "600";
        } else {
            ok = false;
        }
    } else {
        ok = false;
    }
    if (ok && code) {
        annotation.astAnnotation = annotation.astAnnotation || {};
        [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
    }
    return [ok, node];
}
EmitOperandRace = function (operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node: AstNode;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "race") {
        let race = lower(tokenIterator());
        let code;
        if (race) {
            let raceId = undefined;
            if ((race == "blood_elf")) {
                raceId = "BloodElf";
            } else if (race == "troll") {
                raceId = "Troll";
            } else if (race == "orc") {
                raceId = "Orc";
            } else {
                OvaleSimulationCraft.Print("Warning: Race '%s' not defined", race);
            }
            code = format("Race(%s)", raceId);
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {
            };
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandRune = function (operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node: AstNode;
    let code;
    if (parseNode.rune) {
        if (parseNode.asType == "boolean") {
            code = "RuneCount() >= 1";
        } else {
            code = "RuneCount()";
        }
    } else if (truthy(match(operand, "^rune.time_to_([%d]+)$"))) {
        let runes = match(operand, "^rune.time_to_([%d]+)$");
        code = format("TimeToRunes(%d)", runes);
    } else {
        ok = false;
    }
    if (ok && code) {
        annotation.astAnnotation = annotation.astAnnotation || {};
        [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
    }
    return [ok, node];
}
EmitOperandSetBonus = function (operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node;
    let [setBonus] = match(operand, "^set_bonus%.(.*)$");
    let code;
    if (setBonus) {
        let tokenIterator = gmatch(setBonus, "[^_]+");
        let name = tokenIterator();
        let count = tokenIterator();
        let role = tokenIterator();
        if (name && count) {
            let [setName, level] = match(name, "^(%a+)(%d*)$");
            if (setName == "tier") {
                setName = "T";
            } else {
                setName = upper(setName);
            }
            if (level) {
                name = `${setName}${tostring(level)}`;
            }
            if (role) {
                name = `${name}_${role}`;
            }
            [count] = match(count, "(%d+)pc");
            if (name && count) {
                code = format("ArmorSetBonus(%s %d)", name, count);
            }
        }
        if (!code) {
            ok = false;
        }
    } else {
        ok = false;
    }
    if (ok && code) {
        annotation.astAnnotation = annotation.astAnnotation || {};
        [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
    }
    return [ok, node];
}
EmitOperandSeal = function (operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "seal") {
        let name = lower(tokenIterator());
        let code;
        if (name) {
            code = format("Stance(paladin_seal_of_%s)", name);
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {};
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandSpecial = function (operand, parseNode, nodeList, annotation, action, target) {
    let ok = true;
    let node: AstNode;
    let className = annotation.class;
    let specialization = annotation.specialization;
    target = target && (`${target}.`) || "";
    operand = lower(operand);
    let code;
    if (className == "DEATHKNIGHT" && operand == "dot.breath_of_sindragosa.ticking") {
        let buffName = "breath_of_sindragosa_buff";
        code = format("BuffPresent(%s)", buffName);
        AddSymbol(annotation, buffName);
    /*
    } else if (className == "DEATHKNIGHT" && sub(operand, -9, -1) == ".ready_in") {
        let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
        let spellName = tokenIterator();
        [spellName] = Disambiguate(spellName, className, specialization);
        code = format("TimeToSpell(%s)", spellName);
        AddSymbol(annotation, spellName);
    */
    } else if (className == "DEATHKNIGHT" && sub(operand, 1, 24) == "pet.dancing_rune_weapon.") {
        let petOperand = sub(operand, 25);
        let tokenIterator = gmatch(petOperand, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "active") {
            let buffName = "dancing_rune_weapon_buff";
            code = format("BuffPresent(%s)", buffName);
            AddSymbol(annotation, buffName);
        } else if (token == "dot") {
            if (target == "") {
                target = "target";
            } else {
                target = sub(target, 1, -2);
            }
            [ok, node] = EmitOperandDot(petOperand, parseNode, nodeList, annotation, action, target);
        }
    } else if (className == "DEMONHUNTER" && operand == "buff.metamorphosis.extended_by_demonic") {
        code = "not BuffExpires(extended_by_demonic_buff)";
    } else if (className == "DEMONHUNTER" && operand == "cooldown.chaos_blades.ready") {
        code = "Talent(chaos_blades_talent) and SpellCooldown(chaos_blades) == 0";
        AddSymbol(annotation, "chaos_blades_talent");
        AddSymbol(annotation, "chaos_blades");
    } else if (className == "DEMONHUNTER" && operand == "cooldown.nemesis.ready") {
        code = "Talent(nemesis_talent) and SpellCooldown(nemesis) == 0";
        AddSymbol(annotation, "nemesis_talent");
        AddSymbol(annotation, "nemesis");
    } else if (className == "DEMONHUNTER" && operand == "cooldown.metamorphosis.ready" && specialization == "havoc") {
        code = "(not CheckBoxOn(opt_meta_only_during_boss) or IsBossFight()) and SpellCooldown(metamorphosis_havoc) == 0";
        AddSymbol(annotation, "metamorphosis_havoc");
    } else if (className == "DRUID" && operand == "buff.wild_charge_movement.down") {
        code = "True(wild_charge_movement_down)";
    } else if (className == "DRUID" && operand == "eclipse_dir.lunar") {
        code = "EclipseDir() < 0";
    } else if (className == "DRUID" && operand == "eclipse_dir.solar") {
        code = "EclipseDir() > 0";
    } else if (className == "DRUID" && operand == "max_fb_energy") {
        let spellName = "ferocious_bite";
        code = format("EnergyCost(%s max=1)", spellName);
        AddSymbol(annotation, spellName);
    } else if (className == "HUNTER" && operand == "buff.careful_aim.up") {
        code = "target.HealthPercent() > 80 or BuffPresent(rapid_fire_buff)";
        AddSymbol(annotation, "rapid_fire_buff");
    } else if (className == "HUNTER" && operand == "buff.stampede.remains") {
        let spellName = "stampede";
        code = format("TimeSincePreviousSpell(%s) < 40", spellName);
        AddSymbol(annotation, spellName);
    } else if (className == "HUNTER" && operand == "lowest_vuln_within.5") {
        code = "target.DebuffRemaining(vulnerable)";
        AddSymbol(annotation, "vulnerable");
    } else if (className == "MAGE" && operand == "buff.rune_of_power.remains") {
        code = "TotemRemaining(rune_of_power)";
    } else if (className == "MAGE" && operand == "buff.shatterlance.up") {
        code = "HasTrinket(t18_class_trinket) and PreviousGCDSpell(frostbolt)";
        AddSymbol(annotation, "frostbolt");
        AddSymbol(annotation, "t18_class_trinket");
    } else if (className == "MAGE" && (operand == "burn_phase" || operand == "pyro_chain")) {
        if (parseNode.asType == "boolean") {
            code = format("GetState(%s) > 0", operand);
        } else {
            code = format("GetState(%s)", operand);
        }
    } else if (className == "MAGE" && (operand == "burn_phase_duration" || operand == "pyro_chain_duration")) {
        let variable = sub(operand, 1, -10);
        if (parseNode.asType == "boolean") {
            code = format("GetStateDuration(%s) > 0", variable);
        } else {
            code = format("GetStateDuration(%s)", variable);
        }
    } else if (className == "MAGE" && operand == "dot.frozen_orb.ticking") {
        let name = "frozen_orb";
        code = format("SpellCooldown(%s) > SpellCooldownDuration(%s) - 10", name, name);
        AddSymbol(annotation, name);
    } else if (className == "MAGE" && operand == "firestarter.active") {
        code = "Talent(firestarter_talent) and target.HealthPercent() >= 90";
        AddSymbol(annotation, "firestarter_talent");
    } else if (className == "MONK" && sub(operand, 1, 35) == "debuff.storm_earth_and_fire_target.") {
        let property = sub(operand, 36);
        if (target == "") {
            target = "target.";
        }
        let debuffName = "storm_earth_and_fire_target_debuff";
        AddSymbol(annotation, debuffName);
        if (property == "down") {
            code = format("%sDebuffExpires(%s)", target, debuffName);
        } else if (property == "up") {
            code = format("%sDebuffPresent(%s)", target, debuffName);
        } else {
            ok = false;
        }
    } else if (className == "MONK" && operand == "dot.zen_sphere.ticking") {
        let buffName = "zen_sphere_buff";
        code = format("BuffPresent(%s)", buffName);
        AddSymbol(annotation, buffName);
    } else if (className == "MONK" && sub(operand, 1, 8) == "stagger.") {
        let property = sub(operand, 9);
        if (property == "heavy" || property == "light" || property == "moderate") {
            let buffName = format("%s_stagger_debuff", property);
            code = format("DebuffPresent(%s)", buffName);
            AddSymbol(annotation, buffName);
        } else if (property == "pct") {
            code = format("%sStaggerRemaining() / %sMaxHealth() * 100", target, target);
        } else {
            ok = false;
        }
    } else if (className == "MONK" && operand == "spinning_crane_kick.count") {
        code = "SpellCount(spinning_crane_kick)";
        AddSymbol(annotation, "spinning_crane_kick");
    } else if (className == "PALADIN" && operand == "dot.sacred_shield.remains") {
        let buffName = "sacred_shield_buff";
        code = format("BuffRemaining(%s)", buffName);
        AddSymbol(annotation, buffName);
    } else if (className == "PRIEST" && operand == "mind_harvest") {
        code = "target.MindHarvest()";
    } else if (className == "PRIEST" && operand == "natural_shadow_word_death_range") {
        code = "target.HealthPercent() < 20";
    } else if (className == "PRIEST" && operand == "primary_target") {
        code = "1";
    } else if (className == "ROGUE" && operand == "trinket.cooldown.up") {
        code = "HasTrinket(draught_of_souls) and ItemCooldown(draught_of_souls) > 0";
        AddSymbol(annotation, "draught_of_souls");
    } else if (className == "ROGUE" && operand == "mantle_duration") {
        code = "BuffRemaining(master_assassins_initiative)";
        AddSymbol(annotation, "master_assassins_initiative");
    } else if (className == "ROGUE" && operand == "poisoned_enemies") {
        code = "0";
    } else if (className == "ROGUE" && operand == "poisoned_bleeds") {
        code = "DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff)";
        AddSymbol(annotation, "rupture_debuff");
        AddSymbol(annotation, "garrote_debuff");
        AddSymbol(annotation, "internal_bleeding_talent");
        AddSymbol(annotation, "internal_bleeding_debuff");
    } else if (className == "ROGUE" && operand == "exsanguinated") {
        code = "target.DebuffPresent(exsanguinated)";
        AddSymbol(annotation, "exsanguinated");
    } else if (className == "SHAMAN" && operand == "buff.resonance_totem.remains") {
        code = "TotemRemaining(totem_mastery)";
        ok = true;
    } else if (className == "SHAMAN" && truthy(match(operand, "pet.[a-z_]+.active"))) {
        code = "pet.Present()";
        ok = true;
    } else if (className == "WARLOCK" && truthy(match(operand, "pet%.service_[a-z_]+%..+"))) {
        let [spellName, property] = match(operand, "pet%.(service_[a-z_]+)%.(.+)");
        if (property == "active") {
            code = format("SpellCooldown(%s) > 100", spellName);
            AddSymbol(annotation, spellName);
        } else {
            ok = false;
        }
    } else if (className == "WARLOCK" && truthy(match(operand, "dot.unstable_affliction_([1-5]).remains"))) {
        let num = match(operand, "dot.unstable_affliction_([1-5]).remains");
        code = format("target.DebuffStacks(unstable_affliction_debuff) >= %s", num);
    } else if (className == "WARLOCK" && operand == "buff.active_uas.stack") {
        code = "target.DebuffStacks(unstable_affliction_debuff)";
    } else if (className == "WARRIOR" && sub(operand, 1, 23) == "buff.colossus_smash_up.") {
        let property = sub(operand, 24);
        let debuffName = "colossus_smash_debuff";
        AddSymbol(annotation, debuffName);
        if (property == "down") {
            code = format("DebuffCountOnAny(%s) == 0", debuffName);
        } else if (property == "up") {
            code = format("DebuffCountOnAny(%s) > 0", debuffName);
        } else {
            ok = false;
        }
    } else if (className == "WARRIOR" && operand == "gcd.remains" && (action == "battle_cry" || action == "avatar")) {
        code = "0";
    } else if (operand == "buff.enrage.down") {
        code = `not ${target}IsEnraged()`;
    } else if (operand == "buff.enrage.remains") {
        code = `${target}EnrageRemaining()`;
    } else if (operand == "buff.enrage.up") {
        code = `${target}IsEnraged()`;
    } else if (operand == "debuff.casting.react") {
        code = `${target}IsInterruptible()`;
    } else if (operand == "debuff.casting.up") {
        let t = (target == "" && "target.") || target;
        code = `${t}IsInterruptible()`;
    } else if (operand == "debuff.flying.down") {
        code = `${target}True(debuff_flying_down)`;
    } else if (operand == "distance") {
        code = `${target}Distance()`;
    } else if (sub(operand, 1, 9) == "equipped.") {
        let name = sub(operand, 10);
        code = format("HasEquippedItem(%s)", name);
        AddSymbol(annotation, name);
    } else if (operand == "gcd.max") {
        code = "GCD()";
    } else if (operand == "gcd.remains") {
        code = "GCDRemaining()";
    } else if (sub(operand, 1, 15) == "legendary_ring.") {
        let [name] = Disambiguate("legendary_ring", className, specialization);
        let buffName = `${name}_buff`;
        let properties = sub(operand, 16);
        let tokenIterator = gmatch(properties, OPERAND_TOKEN_PATTERN);
        let token = tokenIterator();
        if (token == "cooldown") {
            token = tokenIterator();
            if (token == "down") {
                code = format("ItemCooldown(%s) > 0", name);
                AddSymbol(annotation, name);
            } else if (token == "remains") {
                code = format("ItemCooldown(%s)", name);
                AddSymbol(annotation, name);
            } else if (token == "up") {
                code = format("not ItemCooldown(%s) > 0", name);
                AddSymbol(annotation, name);
            }
        } else if (token == "has_cooldown") {
            code = format("ItemCooldown(%s) > 0", name);
            AddSymbol(annotation, name);
        } else if (token == "up") {
            code = format("BuffPresent(%s)", buffName);
            AddSymbol(annotation, buffName);
        } else if (token == "remains") {
            code = format("BuffRemaining(%s)", buffName);
            AddSymbol(annotation, buffName);
        }
    } else if (operand == "ptr") {
        code = "PTR()";
    } else if (operand == "time_to_die") {
        if (target != "") {
            code = `${target}TimeToDie()`;
        } else {
            code = "target.TimeToDie()";
        }
    } else if (sub(operand, 1, 10) == "using_apl.") {
        let [aplName] = match(operand, "^using_apl%.([%w_]+)");
        code = format("List(opt_using_apl %s)", aplName);
        annotation.using_apl = annotation.using_apl || {
        }
        annotation.using_apl[aplName] = true;
    } else if (operand == "cooldown.buff_sephuzs_secret.remains") {
        code = "BuffCooldown(sephuzs_secret_buff)";
        AddSymbol(annotation, "sephuzs_secret_buff");
    } else if (operand == "is_add") {
        let t = target || "target.";
        code = format("not %sClassification(worldboss)", t);
    } else {
        ok = false;
    }
    if (ok && code) {
        annotation.astAnnotation = annotation.astAnnotation || {};
        [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
    }
    return [ok, node];
}
EmitOperandTalent = function (operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node: AstNode;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "talent") {
        let name = lower(tokenIterator());
        let property = tokenIterator();
        let talentName = `${name}_talent`;
        [talentName] = Disambiguate(talentName, annotation.class, annotation.specialization);
        let code;
        if (property == "disabled") {
            if (parseNode.asType == "boolean") {
                code = format("not Talent(%s)", talentName);
            } else {
                code = format("Talent(%s no)", talentName);
            }
        } else if (property == "enabled") {
            if (parseNode.asType == "boolean") {
                code = format("Talent(%s)", talentName);
            } else {
                code = format("TalentPoints(%s)", talentName);
            }
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {
            };
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
            AddSymbol(annotation, talentName);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandTarget = function (operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node: AstNode;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "target") {
        let property = tokenIterator();
        let code;
        if (property == "adds") {
            code = "Enemies()-1";
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {
            };
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandTotem = function (operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node: AstNode;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "totem") {
        let name = lower(tokenIterator());
        let property = tokenIterator();
        let code;
        if (property == "active") {
            code = format("TotemPresent(%s)", name);
        } else if (property == "remains") {
            code = format("TotemRemaining(%s)", name);
        } else {
            ok = false;
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {
            };
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandTrinket = function (operand, parseNode, nodeList, annotation, action) {
    let ok = true;
    let node: AstNode;
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    if (token == "trinket") {
        let procType = tokenIterator();
        let statName = tokenIterator();
        let code;
        if (procType === "cooldown") {
            if (statName == "remains") {
                code = "{ ItemCooldown(Trinket0Slot) and ItemCooldown(Trinket1Slot) }";
            } else {
                ok = false;
            }
        }
        else if (sub(procType, 1, 4) == "has_") {
            code = format("True(trinket_%s_%s)", procType, statName);
        } else {
            let property = tokenIterator();
            let buffName = format("trinket_%s_%s_buff", procType, statName);
            [buffName] = Disambiguate(buffName, annotation.class, annotation.specialization);
            if (property == "cooldown") {
                code = format("BuffCooldownDuration(%s)", buffName);
            } else if (property == "cooldown_remains") {
                code = format("BuffCooldown(%s)", buffName);
            } else if (property == "down") {
                code = format("BuffExpires(%s)", buffName);
            } else if (property == "react") {
                if (parseNode.asType == "boolean") {
                    code = format("BuffPresent(%s)", buffName);
                } else {
                    code = format("BuffStacks(%s)", buffName);
                }
            } else if (property == "remains") {
                code = format("BuffRemaining(%s)", buffName);
            } else if (property == "stack") {
                code = format("BuffStacks(%s)", buffName);
            } else if (property == "up") {
                code = format("BuffPresent(%s)", buffName);
            } else {
                ok = false;
            }
            if (ok) {
                AddSymbol(annotation, buffName);
            }
        }
        if (ok && code) {
            annotation.astAnnotation = annotation.astAnnotation || {
            };
            [node] = OvaleAST.ParseCode("expression", code, nodeList, annotation.astAnnotation);
        }
    } else {
        ok = false;
    }
    return [ok, node];
}
EmitOperandVariable = function (operand, parseNode, nodeList, annotation, action) {
    let tokenIterator = gmatch(operand, OPERAND_TOKEN_PATTERN);
    let token = tokenIterator();
    let node: AstNode;
    let ok;
    if (token == "variable") {
        let name = tokenIterator();
        if (annotation.currentVariable && annotation.currentVariable.name == name) {
            let group = annotation.currentVariable.child[1];
            if (lualength(group.child) == 0) {
                [node] = OvaleAST.ParseCode("expression", "0", nodeList, annotation.astAnnotation);
            } else {
                [node] = OvaleAST.ParseCode("expression", OvaleAST.Unparse(group), nodeList, annotation.astAnnotation);
            }
        } else {
            node = OvaleAST.NewNode(nodeList);
            node.type = "function";
            node.name = name;
        }
        ok = true;
    } else {
        ok = false;
    }
    return [ok, node];
}
{
    EMIT_VISITOR = {
        ["action"]: EmitAction,
        ["action_list"]: EmitActionList,
        ["arithmetic"]: EmitExpression,
        ["compare"]: EmitExpression,
        ["function"]: EmitFunction,
        ["logical"]: EmitExpression,
        ["number"]: EmitNumber,
        ["operand"]: EmitOperand
    }
}
function PreOrderTraversalMark(node: AstNode) {
    if (node.type == "custom_function") {
        self_functionUsed[node.name] = true;
    } else {
        if (node.type == "add_function") {
            self_functionDefined[node.name] = true;
        }
        if (node.child) {
            for (const [, childNode] of ipairs(node.child)) {
                PreOrderTraversalMark(childNode);
            }
        }
    }
}
function Mark(node: AstNode) {
    wipe(self_functionDefined);
    wipe(self_functionUsed);
    PreOrderTraversalMark(node);
}
function SweepComments(childNodes: LuaArray<AstNode>, index: number) {
    let count = 0;
    for (let k = index - 1; k >= 1; k += -1) {
        if (childNodes[k].type == "comment") {
            remove(childNodes, k);
            count = count + 1;
        } else {
            break;
        }
    }
    return count;
}

function isNode(n:any): n is AstNode {
    return type(n) == "table";
}

// Sweep (remove) all usages of functions that are empty or unused.
function Sweep(node: AstNode):[boolean, boolean|AstNode] {
    let isChanged: boolean;
    let isSwept: boolean | AstNode;
    [isChanged, isSwept] = [false, false];
    if (node.type == "add_function") {
    } else if (node.type == "custom_function" && !self_functionDefined[node.name]) {
        [isChanged, isSwept] = [true, true];
    } else if (node.type == "group" || node.type == "script") {
        let child = node.child;
        let index = lualength(child);
        while (index > 0) {
            let childNode = child[index];
            let [changed, swept] = Sweep(childNode);
            if (isNode(swept)) {
                if (swept.type == "group") {
                    // Directly insert a replacement group's statements in place of the replaced node.
                    remove(child, index);
                    for (let k = lualength(swept.child); k >= 1; k += -1) {
                        insert(child, index, swept.child[k]);
                    }
                    if (node.type == "group") {
                        let count = SweepComments(child, index);
                        index = index - count;
                    }
                } else {
                    child[index] = swept;
                }
            } else if (swept) {
                remove(child, index);
                if (node.type == "group") {
                    let count = SweepComments(child, index);
                    index = index - count;
                }
            }
            isChanged = isChanged || changed || !!swept;
            index = index - 1;
        }
        // Remove blank lines at the top of groups and scripts.
        if (node.type == "group" || node.type == "script") {
            let childNode = child[1];
            while (childNode && childNode.type == "comment" && (!childNode.comment || childNode.comment == "")) {
                isChanged = true;
                remove(child, 1);
                childNode = child[1];
            }
        }
        isSwept = isSwept || (lualength(child) == 0);
        isChanged = isChanged || !!isSwept;
    } else if (node.type == "icon") {
        [isChanged, isSwept] = Sweep(node.child[1]);
    } else if (node.type == "if") {
        [isChanged, isSwept] = Sweep(node.child[2]);
    } else if (node.type == "logical") {
        if (node.expressionType == "binary") {
            let [lhsNode, rhsNode] = [node.child[1], node.child[2]];
            for (const [index, childNode] of ipairs(node.child)) {
                let [changed, swept] = Sweep(childNode);
                if (isNode(swept)) {
                    node.child[index] = swept;
                } else if (swept) {
                    if (node.operator == "or") {
                        isSwept = (childNode == lhsNode) && rhsNode || lhsNode;
                    } else {
                        isSwept = isSwept || swept;
                    }
                    break;
                }
                if (changed) {
                    isChanged = isChanged || changed;
                    break;
                }
            }
            isChanged = isChanged || !!isSwept;
        }
    } else if (node.type == "unless") {
        let [changed, swept] = Sweep(node.child[2]);
        if (isNode(swept)) {
            node.child[2] = swept;
            isSwept = false;
        } else if (swept) {
            isSwept = swept;
        } else {
            [changed, swept] = Sweep(node.child[1]);
            if (isNode(swept)) {
                node.child[1] = swept;
                isSwept = false;
            } else if (swept) {
                isSwept = node.child[2];
            }
        }
        isChanged = isChanged || changed || !!isSwept;
    } else if (node.type == "wait") {
        [isChanged, isSwept] = Sweep(node.child[1]);
    }
    return [isChanged, isSwept];
}

interface Spell {
    order: number;
    name: string;
    interrupt?: number;
    worksOnBoss?: number;
    range?: string;
    stun?: number;
    addSymbol?: LuaObj<any>;
    extraCondition?:string;
}

const InsertInterruptFunction = function(child: LuaArray<AstNode>, annotation: Annotation, interrupts: LuaArray<Spell>) {
    let nodeList = annotation.astAnnotation.nodeList;
    let className = annotation.class;
    let specialization = annotation.specialization;
    let camelSpecialization = CamelSpecialization(annotation);
    let spells = interrupts || {}
    if (OvaleData.BLOODELF_CLASSES[className]) {
        const [name] = Disambiguate("arcane_torrent", className, specialization);
        insert(spells, {
            name: name,
            interrupt: 1,
            worksOnBoss: 1,
            order: 97,
            range: "target.Distance(less 8)"
        });
    }
    if (OvaleData.PANDAREN_CLASSES[className]) {
        insert(spells, {
            name: "quaking_palm",
            stun: 1,
            order: 98
        });
    }
    if (OvaleData.TAUREN_CLASSES[className]) {
        insert(spells, {
            name: "war_stomp",
            stun: 1,
            order: 99,
            range: "target.Distance(less 5)"
        });
    }
    sort(spells, function (a, b) {
        return tonumber(a.order || 0) < tonumber(b.order || 0);
    });
    let lines:LuaArray<string> = {}
    for (const [, spell] of pairs(spells)) {
        AddSymbol(annotation, spell.name);
        if ((spell.addSymbol != undefined)) {
            for (const [, v] of pairs(spell.addSymbol)) {
                AddSymbol(annotation, v);
            }
        }
        let conditions: LuaArray<string> = {}
        if (spell.range == undefined) {
            insert(conditions, format("target.InRange(%s)", spell.name));
        } else if (spell.range != "") {
            insert(conditions, spell.range);
        }
        if (spell.interrupt == 1) {
            insert(conditions, "target.IsInterruptible()");
        }
        if (spell.worksOnBoss == 0 || spell.worksOnBoss == undefined) {
            insert(conditions, "not target.Classification(worldboss)");
        }
        if (spell.extraCondition != undefined) {
            insert(conditions, spell.extraCondition);
        }
        let line = "";
        if (lualength(conditions) > 0) {
            line = `${line}if ${concat(conditions, " and ")} `;
        }
        line = `${line}${format("Spell(%s)", spell.name)}`;
        insert(lines, line);
    }
    let fmt = `
		AddFunction %sInterruptActions
		{
			if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
			{
				%s
			}
		}
	`;
    let code = format(fmt, camelSpecialization, concat(lines, "\n"));
    let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
    insert(child, 1, node);
    annotation.functionTag[node.name] = "cd";
}
const InsertInterruptFunctions = function(child: LuaArray<AstNode>, annotation: Annotation) {
    let interrupts = {
    }
    if (annotation.mind_freeze == "DEATHKNIGHT") {
        insert(interrupts, {
            name: "mind_freeze",
            interrupt: 1,
            worksOnBoss: 1,
            order: 10
        });
        if (annotation.specialization == "blood" || annotation.specialization == "unholy") {
            insert(interrupts, {
                name: "asphyxiate",
                stun: 1,
                order: 20
            });
        }
        if (annotation.specialization == "frost") {
            insert(interrupts, {
                name: "blinding_sleet",
                disorient: 1,
                range: "target.Distance(less 12)",
                order: 20
            });
        }
    }
    if (annotation.consume_magic == "DEMONHUNTER") {
        insert(interrupts, {
            name: "consume_magic",
            interrupt: 1,
            worksOnBoss: 1,
            order: 10
        });
        insert(interrupts, {
            name: "fel_eruption",
            stun: 1,
            order: 20
        });
        insert(interrupts, {
            name: "imprison",
            cc: 1,
            extraCondition: "target.CreatureType(Demon Humanoid Beast)",
            order: 999
        });
        if (annotation.specialization == "havoc") {
            insert(interrupts, {
                name: "chaos_nova",
                stun: 1,
                range: "target.Distance(less 8)",
                order: 100
            });
        }
        if (annotation.specialization == "vengeance") {
            insert(interrupts, {
                name: "sigil_of_silence",
                interrupt: 1,
                order: 110,
                range: "",
                extraCondition: "not SigilCharging(silence misery chains) and (target.RemainingCastTime() >= (2 - Talent(quickened_sigils_talent) + GCDRemaining()))"
            });
            insert(interrupts, {
                name: "sigil_of_misery",
                disorient: 1,
                order: 120,
                range: "",
                extraCondition: "not SigilCharging(silence misery chains) and (target.RemainingCastTime() >= (2 - Talent(quickened_sigils_talent) + GCDRemaining()))"
            });
            insert(interrupts, {
                name: "sigil_of_chains",
                pull: 1,
                order: 130,
                range: "",
                extraCondition: "not SigilCharging(silence misery chains) and (target.RemainingCastTime() >= (2 - Talent(quickened_sigils_talent) + GCDRemaining()))"
            });
        }
    }
    if (annotation.skull_bash == "DRUID" || annotation.solar_beam == "DRUID") {
        if (annotation.specialization == "guardian" || annotation.specialization == "feral") {
            insert(interrupts, {
                name: "skull_bash",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10
            });
        }
        if (annotation.specialization == "balance") {
            insert(interrupts, {
                name: "solar_beam",
                interrupt: 1,
                worksOnBoss: 1,
                order: 10
            });
        }
        insert(interrupts, {
            name: "mighty_bash",
            stun: 1,
            order: 20
        });
        if (annotation.specialization == "guardian") {
            insert(interrupts, {
                name: "incapacitating_roar",
                incapacitate: 1,
                order: 30,
                range: "target.Distance(less 10)"
            });
        }
        insert(interrupts, {
            name: "typhoon",
            knockback: 1,
            order: 110,
            range: "target.Distance(less 15)"
        });
        if (annotation.specialization == "feral") {
            insert(interrupts, {
                name: "maim",
                stun: 1,
                order: 40
            });
        }
    }
    if (annotation.counter_shot == "HUNTER") {
        insert(interrupts, {
            name: "counter_shot",
            interrupt: 1,
            worksOnBoss: 1,
            order: 10
        });
    }
    if (annotation.muzzle == "HUNTER") {
        insert(interrupts, {
            name: "muzzle",
            interrupt: 1,
            worksOnBoss: 1,
            order: 10
        });
    }
    if (annotation.counterspell == "MAGE") {
        insert(interrupts, {
            name: "counterspell",
            interrupt: 1,
            worksOnBoss: 1,
            order: 10
        });
    }
    if (annotation.spear_hand_strike == "MONK") {
        insert(interrupts, {
            name: "spear_hand_strike",
            interrupt: 1,
            worksOnBoss: 1,
            order: 10
        });
        insert(interrupts, {
            name: "paralysis",
            cc: 1,
            order: 999
        });
        insert(interrupts, {
            name: "leg_sweep",
            stun: 1,
            order: 30,
            range: "target.Distance(less 5)"
        });
    }
    if (annotation.rebuke == "PALADIN") {
        insert(interrupts, {
            name: "rebuke",
            interrupt: 1,
            worksOnBoss: 1,
            order: 10
        });
        insert(interrupts, {
            name: "hammer_of_justice",
            stun: 1,
            order: 20
        });
        if (annotation.specialization == "protection") {
            insert(interrupts, {
                name: "avengers_shield",
                interrupt: 1,
                worksOnBoss: 1,
                order: 15
            });
            insert(interrupts, {
                name: "blinding_light",
                disorient: 1,
                order: 50,
                range: "target.Distance(less 10)"
            });
        }
    }
    if (annotation.silence == "PRIEST") {
        insert(interrupts, {
            name: "silence",
            interrupt: 1,
            worksOnBoss: 1,
            order: 10
        });
        insert(interrupts, {
            name: "mind_bomb",
            stun: 1,
            order: 30,
            extraCondition: "target.RemainingCastTime() > 2"
        });
    }
    if (annotation.kick == "ROGUE") {
        insert(interrupts, {
            name: "kick",
            interrupt: 1,
            worksOnBoss: 1,
            order: 10
        });
        insert(interrupts, {
            name: "cheap_shot",
            stun: 1,
            order: 20
        });
        if (annotation.specialization == "outlaw") {
            insert(interrupts, {
                name: "between_the_eyes",
                stun: 1,
                order: 30,
                extraCondition: "ComboPoints() >= 1"
            });
            insert(interrupts, {
                name: "gouge",
                incapacitate: 1,
                order: 100
            });
        }
        if (annotation.specialization == "assassination" || annotation.specialization == "subtlety") {
            insert(interrupts, {
                name: "kidney_shot",
                stun: 1,
                order: 30,
                extraCondition: "ComboPoints() >= 1"
            });
        }
    }
    if (annotation.wind_shear == "SHAMAN") {
        insert(interrupts, {
            name: "wind_shear",
            interrupt: 1,
            worksOnBoss: 1,
            order: 10
        });
        if (annotation.specialization == "enhancement") {
            insert(interrupts, {
                name: "sundering",
                knockback: 1,
                order: 20,
                range: "target.Distance(less 5)"
            });
        }
        insert(interrupts, {
            name: "lightning_surge_totem",
            stun: 1,
            order: 30,
            range: "",
            extraCondition: "target.RemainingCastTime() > 2"
        });
        insert(interrupts, {
            name: "hex",
            cc: 1,
            order: 100,
            extraCondition: "target.RemainingCastTime() > CastTime(hex) + GCDRemaining() and target.CreatureType(Humanoid Beast)"
        });
    }
    if (annotation.pummel == "WARRIOR") {
        insert(interrupts, {
            name: "pummel",
            interrupt: 1,
            worksOnBoss: 1,
            order: 10
        });
        insert(interrupts, {
            name: "shockwave",
            stun: 1,
            worksOnBoss: 0,
            order: 20,
            range: "target.Distance(less 10)"
        });
        insert(interrupts, {
            name: "storm_bolt",
            stun: 1,
            worksOnBoss: 0,
            order: 20
        });
        if ((annotation.specialization == "protection")) {
            insert(interrupts, {
                name: "intercept",
                stun: 1,
                worksOnBoss: 0,
                order: 20,
                extraCondition: "Talent(warbringer_talent)",
                addSymbol: {
                    1: "warbringer_talent"
                }
            });
        }
        insert(interrupts, {
            name: "intimidating_shout",
            incapacitate: 1,
            worksOnBoss: 0,
            order: 100
        });
    }
    if (lualength(interrupts) > 0) {
        InsertInterruptFunction(child, annotation, interrupts);
        return 1;
    } else {
        return 0;
    }
}
const InsertSupportingFunctions = function(child: LuaArray<AstNode>, annotation: Annotation) {
    let count = 0;
    let nodeList = annotation.astAnnotation.nodeList;
    let camelSpecialization = CamelSpecialization(annotation);
    if (annotation.melee == "DEATHKNIGHT") {
        let fmt = `
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(death_strike) Texture(misc_arrowlup help=L(not_in_melee_range))
			}
		`;
        let code = format(fmt, camelSpecialization);
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        annotation.functionTag[node.name] = "shortcd";
        AddSymbol(annotation, "death_strike");
        count = count + 1;
    }
    if (annotation.melee == "DEMONHUNTER" && annotation.specialization == "havoc") {
        let fmt = `
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(chaos_strike) 
				{
					if target.InRange(felblade) Spell(felblade)
					Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		`;
        let code = format(fmt, camelSpecialization);
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        annotation.functionTag[node.name] = "shortcd";
        AddSymbol(annotation, "chaos_strike");
        count = count + 1;
    }
    if (annotation.melee == "DEMONHUNTER" && annotation.specialization == "vengeance") {
        let fmt = `
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(shear) Texture(misc_arrowlup help=L(not_in_melee_range))
			}
		`;
        let code = format(fmt, camelSpecialization);
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        annotation.functionTag[node.name] = "shortcd";
        AddSymbol(annotation, "shear");
        count = count + 1;
    }
    if (annotation.melee == "DRUID") {
        let fmt = `
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred)
				{
					if target.InRange(wild_charge) Spell(wild_charge)
					Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		`;
        let code = format(fmt, camelSpecialization);
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        annotation.functionTag[node.name] = "shortcd";
        AddSymbol(annotation, "mangle");
        AddSymbol(annotation, "shred");
        AddSymbol(annotation, "wild_charge");
        AddSymbol(annotation, "wild_charge_bear");
        AddSymbol(annotation, "wild_charge_cat");
        count = count + 1;
    }
    if (annotation.melee == "HUNTER") {
        let fmt = `
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(raptor_strike)
				{
					Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		`;
        let code = format(fmt, camelSpecialization);
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        annotation.functionTag[node.name] = "shortcd";
        AddSymbol(annotation, "raptor_strike");
        count = count + 1;
    }
    if (annotation.summon_pet == "HUNTER") {
        let fmt;
        if (annotation.specialization == "beast_mastery") {
            fmt = `
				AddFunction %sSummonPet
				{
					if pet.IsDead()
					{
						if not DebuffPresent(heart_of_the_phoenix_debuff) Spell(heart_of_the_phoenix)
						Spell(revive_pet)
					}
					if not pet.Present() and not pet.IsDead() and not PreviousSpell(revive_pet) Texture(ability_hunter_beastcall help=L(summon_pet))
				}
			`;
        } else {
            fmt = `
				AddFunction %sSummonPet
				{
					if not Talent(lone_wolf_talent)
					{
						if pet.IsDead()
						{
							if not DebuffPresent(heart_of_the_phoenix_debuff) Spell(heart_of_the_phoenix)
							Spell(revive_pet)
						}
						if not pet.Present() and not pet.IsDead() and not PreviousSpell(revive_pet) Texture(ability_hunter_beastcall help=L(summon_pet))
					}
				}
			`;
            AddSymbol(annotation, "lone_wolf_talent");
        }
        let code = format(fmt, camelSpecialization);
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        annotation.functionTag[node.name] = "shortcd";
        AddSymbol(annotation, "revive_pet");
        count = count + 1;
    }
    if (annotation.melee == "MONK") {
        let fmt = `
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(tiger_palm) Texture(misc_arrowlup help=L(not_in_melee_range))
			}
		`;
        let code = format(fmt, camelSpecialization);
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        annotation.functionTag[node.name] = "shortcd";
        AddSymbol(annotation, "tiger_palm");
        count = count + 1;
    }
    if (annotation.time_to_hpg_heal == "PALADIN") {
        let code = `
			AddFunction HolyTimeToHPG
			{
				SpellCooldown(crusader_strike holy_shock judgment)
			}
		`;
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        AddSymbol(annotation, "crusader_strike");
        AddSymbol(annotation, "holy_shock");
        AddSymbol(annotation, "judgment");
        count = count + 1;
    }
    if (annotation.time_to_hpg_melee == "PALADIN") {
        let code = `
			AddFunction RetributionTimeToHPG
			{
				SpellCooldown(crusader_strike exorcism hammer_of_wrath hammer_of_wrath_empowered judgment usable=1)
			}
		`;
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        AddSymbol(annotation, "crusader_strike");
        AddSymbol(annotation, "exorcism");
        AddSymbol(annotation, "hammer_of_wrath");
        AddSymbol(annotation, "judgment");
        count = count + 1;
    }
    if (annotation.time_to_hpg_tank == "PALADIN") {
        let code = `
			AddFunction ProtectionTimeToHPG
			{
				if Talent(sanctified_wrath_talent) SpellCooldown(crusader_strike holy_wrath judgment)
				if not Talent(sanctified_wrath_talent) SpellCooldown(crusader_strike judgment)
			}
		`;
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        AddSymbol(annotation, "crusader_strike");
        AddSymbol(annotation, "holy_wrath");
        AddSymbol(annotation, "judgment");
        AddSymbol(annotation, "sanctified_wrath_talent");
        count = count + 1;
    }
    if (annotation.melee == "PALADIN") {
        let fmt = `
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
			}
		`;
        let code = format(fmt, camelSpecialization);
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        annotation.functionTag[node.name] = "shortcd";
        AddSymbol(annotation, "rebuke");
        count = count + 1;
    }
    if (annotation.melee == "ROGUE") {
        let fmt = `
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(kick)
				{
					Spell(shadowstep)
					Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		`;
        let code = format(fmt, camelSpecialization);
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        annotation.functionTag[node.name] = "shortcd";
        AddSymbol(annotation, "kick");
        AddSymbol(annotation, "shadowstep");
        count = count + 1;
    }
    if (annotation.melee == "SHAMAN") {
        let fmt = `
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not target.InRange(stormstrike) 
				{
					if target.InRange(feral_lunge) Spell(feral_lunge)
					Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		`;
        let code = format(fmt, camelSpecialization);
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        annotation.functionTag[node.name] = "shortcd";
        AddSymbol(annotation, "feral_lunge");
        AddSymbol(annotation, "stormstrike");
        count = count + 1;
    }
    if (annotation.bloodlust == "SHAMAN") {
        let fmt = `
			AddFunction %sBloodlust
			{
				if CheckBoxOn(opt_bloodlust) and DebuffExpires(burst_haste_debuff any=1)
				{
					Spell(bloodlust)
					Spell(heroism)
				}
			}
		`;
        let code = format(fmt, camelSpecialization);
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        annotation.functionTag[node.name] = "cd";
        AddSymbol(annotation, "bloodlust");
        AddSymbol(annotation, "heroism");
        count = count + 1;
    }
    if (annotation.melee == "WARRIOR") {
        let fmt = `
			AddFunction %sGetInMeleeRange
			{
				if CheckBoxOn(opt_melee_range) and not InFlightToTarget(%s) and not InFlightToTarget(heroic_leap)
				{
					if target.InRange(%s) Spell(%s)
					if SpellCharges(%s) == 0 and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
					if not target.InRange(pummel) Texture(misc_arrowlup help=L(not_in_melee_range))
				}
			}
		`;
        let charge = "charge";
        if (annotation.specialization == "protection") {
            charge = "intercept";
        }
        let code = format(fmt, camelSpecialization, charge, charge, charge, charge);
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        annotation.functionTag[node.name] = "shortcd";
        AddSymbol(annotation, charge);
        AddSymbol(annotation, "heroic_leap");
        AddSymbol(annotation, "pummel");
        count = count + 1;
    }
    if (annotation.use_item) {
        let fmt = `
			AddFunction %sUseItemActions
			{
				Item(Trinket0Slot usable=1 text=13)
				Item(Trinket1Slot usable=1 text=14)
			}
		`;
        let code = format(fmt, camelSpecialization);
        let [node] = OvaleAST.ParseCode("add_function", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        annotation.functionTag[node.name] = "cd";
        count = count + 1;
    }
    return count;
}
const AddOptionalSkillCheckBox = function(child: LuaArray<AstNode>, annotation: Annotation, data:any, skill: string) {
    let nodeList = annotation.astAnnotation.nodeList;
    if (data.class != annotation[skill]) {
        return 0;
    }
    let defaultText;
    if (data.default) {
        defaultText = " default";
    } else {
        defaultText = "";
    }
    let fmt = `
		AddCheckBox(opt_%s SpellName(%s)%s specialization=%s)
	`;
    let code = format(fmt, skill, skill, defaultText, annotation.specialization);
    let [node] = OvaleAST.ParseCode("checkbox", code, nodeList, annotation.astAnnotation);
    insert(child, 1, node);
    AddSymbol(annotation, skill);
    return 1;
}
const InsertSupportingControls = function(child: LuaArray<AstNode>, annotation: Annotation) {
    let count = 0;
    for (const [skill, data] of pairs(OPTIONAL_SKILLS)) {
        count = count + AddOptionalSkillCheckBox(child, annotation, data, skill);
    }
    let nodeList = annotation.astAnnotation.nodeList;
    let ifSpecialization = `specialization=${annotation.specialization}`;
    if (annotation.using_apl && next(annotation.using_apl)) {
        for (const [name] of pairs(annotation.using_apl)) {
            if (name != "normal") {
                let fmt = `
					AddListItem(opt_using_apl %s "%s APL")
				`;
                let code = format(fmt, name, name);
                let [node] = OvaleAST.ParseCode("list_item", code, nodeList, annotation.astAnnotation);
                insert(child, 1, node);
            }
        }
        {
            let code = `
				AddListItem(opt_using_apl normal L(normal_apl) default)
			`;
            let [node] = OvaleAST.ParseCode("list_item", code, nodeList, annotation.astAnnotation);
            insert(child, 1, node);
        }
    }
    if (annotation.opt_meta_only_during_boss == "DEMONHUNTER") {
        let fmt = `
			AddCheckBox(opt_meta_only_during_boss L(meta_only_during_boss) default %s)
		`;
        let code = format(fmt, ifSpecialization);
        let [node] = OvaleAST.ParseCode("checkbox", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        count = count + 1;
    }
    if (annotation.opt_arcane_mage_burn_phase == "MAGE") {
        let fmt = `
			AddCheckBox(opt_arcane_mage_burn_phase L(arcane_mage_burn_phase) default %s)
		`;
        let code = format(fmt, ifSpecialization);
        let [node] = OvaleAST.ParseCode("checkbox", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        count = count + 1;
    }
    if (annotation.opt_touch_of_death_on_elite_only == "MONK") {
        let fmt = `
			AddCheckBox(opt_touch_of_death_on_elite_only L(touch_of_death_on_elite_only) default %s)
		`;
        let code = format(fmt, ifSpecialization);
        let [node] = OvaleAST.ParseCode("checkbox", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        count = count + 1;
    }
    if (annotation.use_legendary_ring) {
        let legendaryRing = annotation.use_legendary_ring;
        let fmt = `
			AddCheckBox(opt_%s ItemName(%s) default %s)
		`;
        let code = format(fmt, legendaryRing, legendaryRing, ifSpecialization);
        let [node] = OvaleAST.ParseCode("checkbox", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        AddSymbol(annotation, legendaryRing);
        count = count + 1;
    }
    if (annotation.opt_use_consumables) {
        let fmt = `
			AddCheckBox(opt_use_consumables L(opt_use_consumables) default %s)
		`;
        let code = format(fmt, ifSpecialization);
        let [node] = OvaleAST.ParseCode("checkbox", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        count = count + 1;
    }
    if (annotation.melee) {
        let fmt = `
			AddCheckBox(opt_melee_range L(not_in_melee_range) %s)
		`;
        let code = format(fmt, ifSpecialization);
        let [node] = OvaleAST.ParseCode("checkbox", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        count = count + 1;
    }
    if (annotation.interrupt) {
        let fmt = `
			AddCheckBox(opt_interrupt L(interrupt) default %s)
		`;
        let code = format(fmt, ifSpecialization);
        let [node] = OvaleAST.ParseCode("checkbox", code, nodeList, annotation.astAnnotation);
        insert(child, 1, node);
        count = count + 1;
    }
    return count;
}
/* Honor Among Thieves is now a PvP talent and is no longer supported in simcraft.
const InsertSupportingDefines = function(child: LuaArray<AstNode>, annotation: Annotation) {
    let count = 0;
    let nodeList = annotation.astAnnotation.nodeList;
    if (annotation.honor_among_thieves == "ROGUE") {
        let buffName = "honor_among_thieves_cooldown_buff";
        {
            let code = format("SpellInfo(%s duration=%f)", buffName, annotation[buffName]);
            let [node] = OvaleAST.ParseCode("spell_info", code, nodeList, annotation.astAnnotation);
            insert(child, 1, node);
            count = count + 1;
        }
        {
            let code = format("Define(%s %d)", buffName, OvaleHonorAmongThieves.spellId);
            let [node] = OvaleAST.ParseCode("define", code, nodeList, annotation.astAnnotation);
            insert(child, 1, node);
            count = count + 1;
        }
        AddSymbol(annotation, buffName);
    }
    return count;
}
*/
const InsertVariables = function(child: LuaArray<AstNode>, annotation: Annotation) {
    if (annotation.variable) {
        for (const [, v] of pairs(annotation.variable)) {
            insert(child, 1, v);
        }
    }
}
const GenerateIconBody = function(tag: string, profile: Profile) {
    let annotation = profile.annotation;
    let precombatName = OvaleFunctionName("precombat", annotation);
    let defaultName = OvaleFunctionName("_default", annotation);
    let [precombatBodyName, precombatConditionName] = OvaleTaggedFunctionName(precombatName, tag);
    let [defaultBodyName, ] = OvaleTaggedFunctionName(defaultName, tag);
    let mainBodyCode;
    if (annotation.using_apl && next(annotation.using_apl)) {
        let output = self_outputPool.Get();
        output[lualength(output) + 1] = format("if List(opt_using_apl normal) %s()", defaultBodyName);
        for (const [name] of pairs(annotation.using_apl)) {
            let aplName = OvaleFunctionName(name, annotation);
            let [aplBodyName, ] = OvaleTaggedFunctionName(aplName, tag);
            output[lualength(output) + 1] = format("if List(opt_using_apl %s) %s()", name, aplBodyName);
        }
        mainBodyCode = concat(output, "\n");
        self_outputPool.Release(output);
    } else {
        mainBodyCode = `${defaultBodyName}()`;
    }
    let code;
    if (profile["actions.precombat"]) {
        let fmt = `
			if not InCombat() %s()
			unless not InCombat() and %s()
			{
				%s
			}
		`;
        code = format(fmt, precombatBodyName, precombatConditionName, mainBodyCode);
    } else {
        code = mainBodyCode;
    }
    return code;
}
class OvaleSimulationCraftClass extends OvaleSimulationCraftBase {
    constructor() {
        super();
    }

    OnInitialize() {
        InitializeDisambiguation();
        this.CreateOptions();
    }
    DebuggingInfo() {
        self_pool.DebuggingInfo();
        self_childrenPool.DebuggingInfo();
        self_outputPool.DebuggingInfo();
    }
    ToString(tbl) {
        let output = print_r(tbl);
        return concat(output, "\n");
    }
    Release(profile: Profile) {
        if (profile.annotation) {
            let annotation = profile.annotation;
            if (annotation.astAnnotation) {
                OvaleAST.ReleaseAnnotation(annotation.astAnnotation);
            }
            if (annotation.nodeList) {
                for (const [, node] of ipairs(annotation.nodeList)) {
                    self_pool.Release(node);
                }
            }
            for (const [key, value] of pairs(annotation)) {
                if (type(value) == "table") {
                    wipe(value);
                }
                annotation[key] = undefined;
            }
            profile.annotation = undefined;
        }
        profile.actionList = undefined;
    }
    ParseProfile(simc: string) {
        let profile:Profile = {}
        for (const _line of gmatch(simc, "[^\r\n]+")) {
            let [line] = match(_line, "^%s*(.-)%s*$");
            if (!(truthy(match(line, "^#.*")) || truthy(match(line, "^$")))) {
                let [key, operator, value] = match(line, "([^%+=]+)(%+?=)(.*)");
                if (operator == "=") {
                    profile[key] = value;
                } else if (operator == "+=") {
                    if (type(profile[key]) != "table") {
                        let oldValue = profile[key];
                        profile[key] = {
                        }
                        insert(profile[key], oldValue);
                    }
                    insert(profile[key], value);
                }
            }
        }
        for (const [k, v] of pairs(profile)) {
            if (type(v) == "table") {
                profile[k] = concat(v);
            }
        }
        profile.templates = {
        }
        for (const [k, ] of pairs(profile)) {
            if (sub(k, 1, 2) == "$(" && sub(k, -1) == ")") {
                insert(profile.templates, k);
            }
        }
        let ok = true;
        let annotation: Annotation = {}
        let nodeList: ChildParseNode = {}
        let actionList: LuaArray<ScNode> = {
        }
        for (const [k, _v] of pairs(profile)) {
            let v = _v;
            if (ok && truthy(match(k, "^actions"))) {
                let [name] = match(k, "^actions%.([%w_]+)");
                if (!name) {
                    name = "_default";
                }
                for (let index = lualength(profile.templates); index >= 1; index += -1) {
                    let template = profile.templates[index];
                    let variable = sub(template, 3, -2);
                    let pattern = `%$%(${variable}%)`;
                    v = gsub(v, pattern, profile[template]);
                }
                let node;
                [ok, node] = ParseActionList(name, v, nodeList, annotation);
                if (ok) {
                    actionList[lualength(actionList) + 1] = node;
                } else {
                    break;
                }
            }
        }
        sort(actionList, function (a, b) {
            return a.name < b.name;
        });
        for (const [className] of pairs(RAID_CLASS_COLORS)) {
            let lowerClass = lower(className);
            if (profile[lowerClass]) {
                annotation.class = className;
                annotation.name = profile[lowerClass];
            }
        }
        annotation.specialization = profile.spec;
        annotation.level = profile.level;
        ok = ok && (annotation.class !== undefined && annotation.specialization !== undefined && annotation.level !== undefined);
        annotation.pet = profile.default_pet;
        let consumables:LuaObj<string> = {}
        for (const [k, v] of pairs(CONSUMABLE_ITEMS)) {
            if (v) {
                if (profile[k] != undefined) {
                    consumables[k] = profile[k];
                }
            }
        }
        annotation.consumables = consumables;
        if (profile.role == "tank") {
            annotation.role = profile.role;
            annotation.melee = annotation.class;
        } else if (profile.role == "spell") {
            annotation.role = profile.role;
            annotation.ranged = annotation.class;
        } else if (profile.role == "attack" || profile.role == "dps") {
            annotation.role = "attack";
            if (profile.position == "ranged_back") {
                annotation.ranged = annotation.class;
            } else {
                annotation.melee = annotation.class;
            }
        }
        let taggedFunctionName: LuaObj<boolean> = { }
        for (const [, node] of ipairs(actionList)) {
            let fname = OvaleFunctionName(node.name, annotation);
            taggedFunctionName[fname] = true;
            for (const [, tag] of pairs(OVALE_TAGS)) {
                let [bodyName, conditionName] = OvaleTaggedFunctionName(fname, tag);
                taggedFunctionName[bodyName] = true;
                taggedFunctionName[conditionName] = true;
            }
        }
        annotation.taggedFunctionName = taggedFunctionName;
        annotation.functionTag = {}
        profile.actionList = actionList;
        profile.annotation = annotation;
        annotation.nodeList = nodeList;
        if (!ok) {
            this.Release(profile);
            profile = undefined;
        }
        return profile;
    }
    Unparse(profile: Profile) {
        let output = self_outputPool.Get();
        if (profile.actionList) {
            for (const [, node] of ipairs(profile.actionList)) {
                output[lualength(output) + 1] = Unparse(node);
            }
        }
        let s = concat(output, "\n");
        self_outputPool.Release(output);
        return s;
    }
    EmitAST(profile: Profile) {
        let nodeList = {
        }
        let ast = OvaleAST.NewNode(nodeList, true);
        let child = ast.child;
        ast.type = "script";
        let annotation = profile.annotation;
        let ok = true;
        if (profile.actionList) {
            annotation.astAnnotation = annotation.astAnnotation || {
            }
            annotation.astAnnotation.nodeList = nodeList;
            let dictionaryAST: AstNode;
            {
                OvaleDebug.ResetTrace();
                let dictionaryAnnotation: AstAnnotation = {
                    nodeList: {
                    }
                }
                let dictionaryFormat = `
				Include(ovale_common)
				Include(ovale_trinkets_mop)
				Include(ovale_trinkets_wod)
				Include(ovale_%s_spells)
				%s
			`;
                let dictionaryCode = format(dictionaryFormat, lower(annotation.class), Ovale.db.profile.overrideCode || "");
                [dictionaryAST] = OvaleAST.ParseCode("script", dictionaryCode, dictionaryAnnotation.nodeList, dictionaryAnnotation);
                if (dictionaryAST) {
                    dictionaryAST.annotation = dictionaryAnnotation;
                    annotation.dictionaryAST = dictionaryAST;
                    annotation.dictionary = dictionaryAnnotation.definition;
                    OvaleAST.PropagateConstants(dictionaryAST);
                    OvaleAST.PropagateStrings(dictionaryAST);
                    OvaleAST.FlattenParameters(dictionaryAST);
                    ResetControls();
                    OvaleCompile.EvaluateScript(dictionaryAST, true);
                }
            }
            for (const [, node] of ipairs(profile.actionList)) {
                let addFunctionNode = EmitActionList(node, nodeList, annotation);
                if (addFunctionNode) {
                    let actionListName = gsub(node.name, "^_+", "");
                    let commentNode = OvaleAST.NewNode(nodeList);
                    commentNode.type = "comment";
                    commentNode.comment = `## actions.${actionListName}`;
                    child[lualength(child) + 1] = commentNode;
                    for (const [, tag] of pairs(OVALE_TAGS)) {
                        let [bodyNode, conditionNode] = SplitByTag(tag, addFunctionNode, nodeList, annotation);
                        child[lualength(child) + 1] = bodyNode;
                        child[lualength(child) + 1] = conditionNode;
                    }
                } else {
                    ok = false;
                    break;
                }
            }
        }
        if (ok) {
            annotation.supportingFunctionCount = InsertSupportingFunctions(child, annotation);
            annotation.supportingInterruptCount = InsertInterruptFunctions(child, annotation);
            annotation.supportingControlCount = InsertSupportingControls(child, annotation);
            // annotation.supportingDefineCount = InsertSupportingDefines(child, annotation);
            InsertVariables(child, annotation);
            let [className, specialization] = [annotation.class, annotation.specialization];
            let lowerclass = lower(className);
            let aoeToggle = `opt_${lowerclass}_${specialization}_aoe`;
            {
                let commentNode = OvaleAST.NewNode(nodeList);
                commentNode.type = "comment";
                commentNode.comment = `## ${CamelCase(specialization)} icons.`;
                insert(child, commentNode);
                let code = format("AddCheckBox(%s L(AOE) default specialization=%s)", aoeToggle, specialization);
                let [node] = OvaleAST.ParseCode("checkbox", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            {
                let fmt = `
				AddIcon checkbox=!%s enemies=1 help=shortcd specialization=%s
				{
					%s
				}
			`;
                let code = format(fmt, aoeToggle, specialization, GenerateIconBody("shortcd", profile));
                let [node] = OvaleAST.ParseCode("icon", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            {
                let fmt = `
				AddIcon checkbox=%s help=shortcd specialization=%s
				{
					%s
				}
			`;
                let code = format(fmt, aoeToggle, specialization, GenerateIconBody("shortcd", profile));
                let [node] = OvaleAST.ParseCode("icon", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            {
                let fmt = `
				AddIcon enemies=1 help=main specialization=%s
				{
					%s
				}
			`;
                let code = format(fmt, specialization, GenerateIconBody("main", profile));
                let [node] = OvaleAST.ParseCode("icon", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            {
                let fmt = `
				AddIcon checkbox=%s help=aoe specialization=%s
				{
					%s
				}
			`;
                let code = format(fmt, aoeToggle, specialization, GenerateIconBody("main", profile));
                let [node] = OvaleAST.ParseCode("icon", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            {
                let fmt = `
				AddIcon checkbox=!%s enemies=1 help=cd specialization=%s
				{
					%s
				}
			`;
                let code = format(fmt, aoeToggle, specialization, GenerateIconBody("cd", profile));
                let [node] = OvaleAST.ParseCode("icon", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            {
                let fmt = `
				AddIcon checkbox=%s help=cd specialization=%s
				{
					%s
				}
			`;
                let code = format(fmt, aoeToggle, specialization, GenerateIconBody("cd", profile));
                let [node] = OvaleAST.ParseCode("icon", code, nodeList, annotation.astAnnotation);
                insert(child, node);
            }
            Mark(ast);
            let [changed] = Sweep(ast);
            while (changed) {
                Mark(ast);
                [changed] = Sweep(ast);
            }
            Mark(ast);
            Sweep(ast);
        }
        if (!ok) {
            OvaleAST.Release(ast);
            ast = undefined;
        }
        return ast;
    }
    Emit(profile: Profile, noFinalNewLine?: boolean) {
        let ast = this.EmitAST(profile);
        let annotation = profile.annotation;
        let className = annotation.class;
        let lowerclass = lower(className);
        let specialization = annotation.specialization;
        let output = self_outputPool.Get();
        {
            output[lualength(output) + 1] = `# Based on SimulationCraft profile ${annotation.name}.`;
            output[lualength(output) + 1] = `#	class=${lowerclass}`;
            output[lualength(output) + 1] = `#	spec=${specialization}`;
            if (profile.talents) {
                output[lualength(output) + 1] = `#	talents=${profile.talents}`;
            }
            if (profile.glyphs) {
                output[lualength(output) + 1] = `#	glyphs=${profile.glyphs}`;
            }
            if (profile.default_pet) {
                output[lualength(output) + 1] = `#	pet=${profile.default_pet}`;
            }
        }
        {
            output[lualength(output) + 1] = "";
            output[lualength(output) + 1] = "Include(ovale_common)";
            output[lualength(output) + 1] = "Include(ovale_trinkets_mop)";
            output[lualength(output) + 1] = "Include(ovale_trinkets_wod)";
            output[lualength(output) + 1] = format("Include(ovale_%s_spells)", lowerclass);
            const overrideCode = Ovale.db.profile.overrideCode;
            if (overrideCode != "") {
                output[lualength(output) + 1] = "";
                output[lualength(output) + 1] = "# Overrides.";
                output[lualength(output) + 1] = overrideCode;
            }
            if (annotation.supportingControlCount > 0) {
                output[lualength(output) + 1] = "";
            }
        }
        output[lualength(output) + 1] = OvaleAST.Unparse(ast);
        if (profile.annotation.symbolTable) {
            output[lualength(output) + 1] = "";
            output[lualength(output) + 1] = "### Required symbols";
            sort(profile.annotation.symbolTable);

            for (const [, symbol] of ipairs(profile.annotation.symbolList)) {
                if (!tonumber(symbol) && profile.annotation.dictionary && !profile.annotation.dictionary[symbol] && !OvaleData.buffSpellList[symbol]) {
                    this.Print("Warning: Symbol '%s' not defined", symbol);
                }
                output[lualength(output) + 1] = `# ${symbol}`;
            }
        }
        annotation.dictionary = undefined;
        if (annotation.dictionaryAST) {
            OvaleAST.Release(annotation.dictionaryAST);
        }
        if (!noFinalNewLine && output[lualength(output)] != "") {
            output[lualength(output) + 1] = "";
        }
        let s = concat(output, "\n");
        self_outputPool.Release(output);
        OvaleAST.Release(ast);
        return s;
    }
    CreateOptions() {
        let options = {
            name: `${Ovale.GetName()} SimulationCraft`,
            type: "group",
            args: {
                input: {
                    order: 10,
                    name: L["Input"],
                    type: "group",
                    args: {
                        description: {
                            order: 10,
                            name: `${L["The contents of a SimulationCraft profile."]}\nhttps://code.google.com/p/simulationcraft/source/browse/profiles`,
                            type: "description"
                        },
                        input: {
                            order: 20,
                            name: L["SimulationCraft Profile"],
                            type: "input",
                            multiline: 25,
                            width: "full",
                            get: (info: any) => {
                                return self_lastSimC;
                            },
                            set: (info: any, value: string) => {
                                self_lastSimC = value;
                                let profile = this.ParseProfile(self_lastSimC);
                                let code = "";
                                if (profile) {
                                    code = this.Emit(profile);
                                }
                                self_lastScript = gsub(code, "\t", "    ");
                            }
                        }
                    }
                },
                overrides: {
                    order: 20,
                    name: L["Overrides"],
                    type: "group",
                    args: {
                        description: {
                            order: 10,
                            name: L["SIMULATIONCRAFT_OVERRIDES_DESCRIPTION"],
                            type: "description"
                        },
                        overrides: {
                            order: 20,
                            name: L["Overrides"],
                            type: "input",
                            multiline: 25,
                            width: "full",
                            get: (info: any) => {
                                const code = Ovale.db.profile.code;
                                return gsub(code, "\t", "    ");
                            },
                            set: (info: any, value: string) => {
                                Ovale.db.profile.overrideCode = value;
                                if (self_lastSimC) {
                                    let profile = this.ParseProfile(self_lastSimC);
                                    let code = "";
                                    if (profile) {
                                        code = this.Emit(profile);
                                    }
                                    self_lastScript = gsub(code, "\t", "    ");
                                }
                            }
                        }
                    }
                },
                output: {
                    order: 30,
                    name: L["Output"],
                    type: "group",
                    args: {
                        description: {
                            order: 10,
                            name: L["The script translated from the SimulationCraft profile."],
                            type: "description"
                        },
                        output: {
                            order: 20,
                            name: L["Script"],
                            type: "input",
                            multiline: 25,
                            width: "full",
                            get: function () {
                                return self_lastScript;
                            }
                        }
                    }
                }
            }
        }
        let appName = this.GetName();
        AceConfig.RegisterOptionsTable(appName, options);
        AceConfigDialog.AddToBlizOptions(appName, "SimulationCraft", Ovale.GetName());
    }
}

OvaleSimulationCraft = new OvaleSimulationCraftClass();