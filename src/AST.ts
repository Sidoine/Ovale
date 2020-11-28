import { L } from "./Localization";
import { OvalePool } from "./Pool";
import { OvaleProfilerClass, Profiler } from "./Profiler";
import { OvaleDebugClass, Tracer } from "./Debug";
import { Tokenizer, TokenizerDefinition } from "./Lexer";
import { OvaleConditionClass } from "./Condition";
import { OvaleLexer, LexerFilter } from "./Lexer";
import { OvaleScriptsClass } from "./Scripts";
import { OvaleSpellBookClass } from "./SpellBook";
import {
    LuaArray,
    LuaObj,
    ipairs,
    next,
    pairs,
    tonumber,
    tostring,
    type,
    wipe,
    lualength,
    kpairs,
} from "@wowts/lua";
import { format, gsub, lower, sub } from "@wowts/string";
import { concat, insert, sort } from "@wowts/table";
import { GetItemInfo } from "@wowts/wow-mock";
import { checkToken, isNumber, KeyCheck, TypeCheck } from "./tools";
import { SpellInfoProperty, SpellInfoValues } from "./Data";
import { HasteType } from "./states/PaperDoll";
import { Result } from "./simulationcraft/definitions";
import { newTimeSpan, OvaleTimeSpan } from "./TimeSpan";
import { ActionType } from "./BestAction";
import { PowerType } from "./states/Power";

const KEYWORD: LuaObj<boolean> = {
    ["and"]: true,
    ["if"]: true,
    ["not"]: true,
    ["or"]: true,
    ["unless"]: true,
};

const DECLARATION_KEYWORD: LuaObj<boolean> = {
    ["addactionicon"]: true,
    ["addcheckbox"]: true,
    ["addfunction"]: true,
    ["addicon"]: true,
    ["addlistitem"]: true,
    ["define"]: true,
    ["include"]: true,
    ["iteminfo"]: true,
    ["itemrequire"]: true,
    ["itemlist"]: true,
    ["scorespells"]: true,
    ["spellinfo"]: true,
    ["spelllist"]: true,
    ["spellrequire"]: true,
};

export type SpellAuraKeyWord =
    | "spelladdbuff"
    | "spelladddebuff"
    | "spelladdpetbuff"
    | "spelladdpetdebuff"
    | "spelladdtargetbuff"
    | "spelladdtargetdebuff"
    | "spelldamagebuff"
    | "spelldamagedebuff";

const SPELL_AURA_KEYWORD: KeyCheck<SpellAuraKeyWord> = {
    ["spelladdbuff"]: true,
    ["spelladddebuff"]: true,
    ["spelladdpetbuff"]: true,
    ["spelladdpetdebuff"]: true,
    ["spelladdtargetbuff"]: true,
    ["spelladdtargetdebuff"]: true,
    ["spelldamagebuff"]: true,
    ["spelldamagedebuff"]: true,
};

export const checkSpellInfo: TypeCheck<SpellInfoValues> = {
    add_cd: true,
    add_duration: true,
    add_duration_combopoints: true,
    alternate: true,
    arcanecharges: true,
    base: true,
    bonusap: true,
    bonusapcp: true,
    bonuscp: true,
    bonusmainhand: true,
    bonusoffhand: true,
    bonussp: true,
    // buff: true,
    buff_cd: true,
    buff_cdr: true,
    buff_totem: true,
    canStopChannelling: true,
    casttime: true,
    cd: true,
    cd_haste: true,
    channel: true,
    charge_cd: true,
    chi: true,
    combopoints: true,
    damage: true,
    duration: true,
    effect: true,
    energy: true,
    focus: true,
    forcecd: true,
    fury: true,
    gcd: true,
    gcd_haste: true,
    haste: true,
    health: true,
    holypower: true,
    inccounter: true,
    insanity: true,
    interrupt: true,
    lunarpower: true,
    maelstrom: true,
    mana: true,
    max_stacks: true,
    max_totems: true,
    max_travel_time: true,
    offgcd: true,
    pain: true,
    physical: true,
    rage: true,
    replaced_by: true,
    resetcounter: true,
    runes: true,
    runicpower: true,
    shared_cd: true,
    soulshards: true,
    stacking: true,
    // stat: true,
    tag: true,
    texture: true,
    tick: true,
    to_stance: true,
    totem: true,
    travel_time: true,
    unusable: true,
    addlist: true,
    dummy_replace: true,
    learn: true,
    pertrait: true,
    proc: true,
};

// const STANCE_KEYWORD = {
//     ["if_stance"]: true,
//     ["stance"]: true,
//     ["to_stance"]: true,
// };
{
    for (const [keyword, value] of pairs(SPELL_AURA_KEYWORD)) {
        DECLARATION_KEYWORD[keyword] = value;
    }
    for (const [keyword, value] of pairs(DECLARATION_KEYWORD)) {
        KEYWORD[keyword] = value;
    }
}

const ACTION_PARAMETER_COUNT: LuaObj<number> = {
    ["item"]: 1,
    ["macro"]: 1,
    ["spell"]: 1,
    ["texture"]: 1,
    ["setstate"]: 2,
};
const STATE_ACTION: LuaObj<boolean> = {
    ["setstate"]: true,
};
const STRING_LOOKUP_FUNCTION: LuaObj<boolean> = {
    ["itemname"]: true,
    ["l"]: true,
    ["spellname"]: true,
};

export type OperatorType =
    | "not"
    | "or"
    | "and"
    | "-"
    | "="
    | "!="
    | "xor"
    | "^"
    | "|"
    | "=="
    | "/"
    | "!"
    | ">"
    | ">="
    | "<="
    | "<"
    | "+"
    | "*"
    | "%"
    | ">?"
    | "<?";

const UNARY_OPERATOR: {
    [key in OperatorType]?: { 1: "logical" | "arithmetic"; 2: number };
} = {
    ["not"]: {
        1: "logical",
        2: 15,
    },
    ["-"]: {
        1: "arithmetic",
        2: 50,
    },
};
const BINARY_OPERATOR: {
    [key in OperatorType]?: {
        1: "logical" | "compare" | "arithmetic";
        2: number;
        3?: string;
    };
} = {
    ["or"]: {
        1: "logical",
        2: 5,
        3: "associative",
    },
    ["xor"]: {
        1: "logical",
        2: 8,
        3: "associative",
    },
    ["and"]: {
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
    ["/"]: {
        1: "arithmetic",
        2: 40,
    },
    ["^"]: {
        1: "arithmetic",
        2: 100,
    },
    [">?"]: {
        1: "arithmetic",
        2: 25,
    },
    ["<?"]: {
        1: "arithmetic",
        2: 25,
    },
};

const indent: LuaArray<string> = {};
indent[0] = "";
function INDENT(key: number) {
    let ret = indent[key];
    if (ret == undefined) {
        ret = `${INDENT(key - 1)} `;
        indent[key] = ret;
    }
    return ret;
}

export interface AstAnnotation {
    checkBoxList?: LuaArray<CheckboxParameters>;
    listList?: LuaArray<ListParameters>;
    positionalParametersList?: LuaArray<PositionalParameters>;
    rawPositionalParametersList?: LuaArray<RawPositionalParameters>;
    flattenParametersList?: LuaArray<NamedParameters>;
    rawNamedParametersList?: LuaArray<RawNamedParameters>;
    objects?: LuaArray<any>;
    nodeList: LuaArray<AstNode>;
    parametersReference?: LuaArray<AstNode>;
    postOrderReference?: LuaArray<AstGroupNode>;
    customFunction?: LuaObj<AstAddFunctionNode>;
    stringReference?: LuaArray<AstNode>;
    functionCall?: LuaObj<boolean>;
    functionReference?: LuaArray<AstFunctionNode>;
    nameReference?: LuaArray<AstNode>;
    definition: LuaObj<number | string>;
    numberFlyweight?: LuaObj<AstValueNode>;
    verify?: boolean;
    functionHash?: LuaObj<AstNode>;
    expressionHash?: LuaObj<AstNode>;
    parametersList?: LuaArray<NamedParameters>;
    sync?: LuaObj<AstNode>;
}

interface NodeTypes {
    action: AstFunctionNode;
    action_list: AstActionListNode;
    add_function: AstAddFunctionNode;
    arithmetic: AstExpressionNode;
    bang_value: AstBangValueNode;
    boolean: AstBooleanNode;
    checkbox: AstCheckBoxNode;
    comment: AstCommentNode;
    compare: AstExpressionNode;
    custom_function: AstFunctionNode;
    define: AstDefineNode;
    expression: AstExpressionNode;
    function: AstFunctionNode;
    group: AstGroupNode;
    icon: AstIconNode;
    if: AstIfNode;
    item_info: AstItemInfoNode;
    itemrequire: AstItemRequireNode;
    list: AstListNode;
    list_item: AstListItemNode;
    logical: AstExpressionNode;
    lua: AstLuaNode;
    score_spells: AstScoreSpellsNode;
    script: AstScriptNode;
    simc_pool_resource: AstSimcPoolResourceNode;
    simc_wait: AstSimcWaitnode;
    spell_aura_list: AstSpellAuraListNode;
    spell_info: AstSpellInfoNode;
    spell_require: AstSpellRequireNode;
    state: AstFunctionNode;
    string: AstStringNode;
    unless: AstUnlessNode;
    value: AstValueNode;
    variable: AstVariableNode;
}

export type NodeType = keyof NodeTypes;
type NodeWithParametersType = {
    [k in NodeType]: NodeTypes[k] extends AstNodeWithParameters<any, any>
        ? k
        : never;
}[NodeType];
type NodeWithChildrenType = {
    [k in NodeType]: NodeTypes[k] extends AstBaseNodeWithChildren<any>
        ? k
        : never;
}[NodeType];
type NodeWithBodyType = {
    [k in NodeType]: NodeTypes[k] extends { body: any } ? k : never;
}[NodeType];
interface BaseNodeValue {
    /**
     * The serial is used to know if the value has already
     * been computed this frame
     */
    serial: number;

    timeSpan: OvaleTimeSpan;
}

export interface NodeNoResult extends BaseNodeValue {
    type: "none";
}

export interface NodeStateResult extends BaseNodeValue {
    type: "state";
    value?: number;
    name?: string;
}

export interface NodeValueResult extends BaseNodeValue {
    type: "value";
    value?: number | string;
    origin?: number;
    rate?: number;
}

export interface NodeActionResult extends BaseNodeValue {
    type: "action";
    actionTexture?: string;
    actionInRange?: boolean;
    actionCooldownDuration?: number;
    actionCooldownStart?: number;
    actionUsable?: boolean;
    actionShortcut?: string;
    actionIsCurrent?: boolean;
    actionEnable?: boolean;
    actionType?: ActionType;
    actionId?: string | number;
    actionTarget?: string;
    actionResourceExtend?: number;
    actionCharges?: number;
    castTime?: number;
    offgcd?: boolean;
    options?: {
        wait?: FlattenParameterValue;
        text?: FlattenParameterValue;
        sound?: FlattenParameterValue;
        soundtime?: FlattenParameterValue;
        nored?: FlattenParameterValue;
        help?: FlattenParameterValue;
        pool_resource?: FlattenParameterValue;
        nocd?: FlattenParameterValue;
        flash?: FlattenParameterValue;
    };
}

interface AstNodeTypes {
    state: NodeStateResult;
    value: NodeValueResult;
    action: NodeActionResult;
    none: NodeNoResult;
}

export function setResultType<T extends AstNodeSnapshot["type"]>(
    result: AstNodeSnapshot,
    type: T
): asserts result is AstNodeTypes[T] {
    result.type = type;
}

/** Used to store the result of an AstNode */
export type AstNodeSnapshot =
    | NodeStateResult
    | NodeValueResult
    | NodeActionResult
    | NodeNoResult;

export interface AstBaseNode<T extends NodeType> {
    type: T;
    nodeId: number;
    asString?: string;

    annotation: AstAnnotation;
    postOrder?: LuaArray<AstNode>;

    result: AstNodeSnapshot;

    /** Used to decorate a node with a { or (. Only used to unparse the node */
    left?: string;

    /** Used to decorate a node with a } or ). Only used to unparse the node */
    right?: string;
}

export interface AstBaseNodeWithChildren<T extends NodeType>
    extends AstBaseNode<T> {
    child: LuaArray<AstNode>;
}

export function isAstNodeWithChildren(
    node: AstNode
): node is AstBaseNodeWithChildren<any> {
    return (node as any).child !== undefined;
}

export interface AstNodeWithParameters<
    T extends NodeType,
    P extends string = DefaultNamedParameters
> extends AstBaseNodeWithChildren<T> {
    rawPositionalParams: RawPositionalParameters;
    rawNamedParams: RawNamedParameters<P>;

    /**
     * Store the current values of the rawPositionalParams and rawNamedParams (only number or strings).
     * Used by conditions because they don't take full values (AstNodeSnapshot) as parameters.
     */
    cachedParams: {
        serial?: number;
        named: NamedParameters<P>;
        positional: PositionalParameters;
    };
}

export type AstNode =
    | AstActionListNode
    | AstAddFunctionNode
    | AstBangValueNode
    | AstBooleanNode
    | AstCheckBoxNode
    | AstCommentNode
    | AstDefineNode
    | AstExpressionNode
    | AstFunctionNode
    | AstGroupNode
    | AstIconNode
    | AstIfNode
    | AstItemInfoNode
    | AstItemRequireNode
    | AstListItemNode
    | AstListNode
    | AstLuaNode
    | AstScoreSpellsNode
    | AstScriptNode
    | AstSimcPoolResourceNode
    | AstSimcWaitnode
    | AstSpellAuraListNode
    | AstSpellInfoNode
    | AstSpellRequireNode
    | AstStringNode
    | AstUnlessNode
    | AstValueNode
    | AstVariableNode;

export interface AstLuaNode extends AstBaseNode<"lua"> {
    lua: string;
}

export interface AstSimcPoolResourceNode
    extends AstBaseNode<"simc_pool_resource"> {
    for_next: boolean;
    extra_amount: number;
    powerType: PowerType;
}

export interface AstBooleanNode extends AstBaseNode<"boolean"> {}

export interface AstSimcWaitnode extends AstBaseNodeWithChildren<"simc_wait"> {}

export interface AstActionListNode extends AstBaseNode<"action_list"> {}

export interface AstCheckBoxNode
    extends AstNodeWithParameters<"checkbox", "enabled"> {
    name: string;
    description: AstNode;
}

const checkCheckBoxParameters: NamedParametersCheck<AstCheckBoxNode> = {
    enabled: true,
};

export interface AstUnlessNode extends AstBaseNodeWithChildren<"unless"> {
    // TODO Should be moved to annotations instead (used by simc emiter)
    simc_pool_resource?: boolean;
    simc_wait?: boolean;
}

export interface AstSpellAuraListNode
    extends AstNodeWithParameters<
        "spell_aura_list",
        | "enabled"
        | "add"
        | "set"
        | "extend"
        | "refresh"
        | "toggle"
        | "refresh_keep_snapshot"
    > {
    keyword: SpellAuraKeyWord;
    name: string;
    spellId: number;
    buffName: string;
    buffSpellId: number;
}

type NamedParametersCheck<
    T extends AstNodeWithParameters<any, any>
> = TypeCheck<T["rawNamedParams"]>;

const spellAuraListParametersCheck: TypeCheck<
    AstSpellAuraListNode["rawNamedParams"]
> = {
    enabled: true,
    add: true,
    set: true,
    extend: true,
    refresh: true,
    refresh_keep_snapshot: true,
    toggle: true,
};

export interface AstSpellInfoNode
    extends AstNodeWithParameters<"spell_info", SpellInfoProperty> {
    name: string;
    spellId: number;
}
export interface AstSpellRequireNode
    extends AstNodeWithParameters<
        "spell_require",
        "set" | "add" | "percent" | "enabled"
    > {
    name: string;
    spellId: number;
    property: SpellInfoProperty;
}

const checkSpellRequireParameters: NamedParametersCheck<AstSpellRequireNode> = {
    add: true,
    percent: true,
    set: true,
    enabled: true,
};

export interface AstAddFunctionNode
    extends AstNodeWithParameters<"add_function", "help"> {
    name: string;
    body: AstGroupNode;
}

const checkAddFunctionParameters: NamedParametersCheck<AstAddFunctionNode> = {
    help: true,
};

export interface AstScriptNode extends AstBaseNodeWithChildren<"script"> {}

export interface AstScoreSpellsNode
    extends AstNodeWithParameters<"score_spells", "enabled"> {}

export interface AstListNode extends AstNodeWithParameters<"list", "enabled"> {
    keyword: string;
    name: string;
}

const checkListParameters: NamedParametersCheck<AstListNode> = {
    enabled: true,
};

export interface AstItemRequireNode
    extends AstNodeWithParameters<
        "itemrequire",
        "set" | "add" | "percent" | "enabled"
    > {
    name: string;
    itemId: number;
    property: SpellInfoProperty;
}

export interface AstItemInfoNode
    extends AstNodeWithParameters<"item_info", SpellInfoProperty> {
    name: string;
    itemId: number;
}

export interface AstGroupNode extends AstBaseNodeWithChildren<"group"> {}

export interface AstIfNode extends AstBaseNodeWithChildren<"if"> {
    // TODO Should be moved to annotations instead (used by simc emiter)
    simc_pool_resource?: boolean;
    simc_wait?: boolean;
}

export interface AstIconNode
    extends AstNodeWithParameters<
        "icon",
        | "secure"
        | "target"
        | "enemies"
        | "size"
        | "type"
        | "help"
        | "text"
        | "flash"
        | "enabled"
    > {
    body: AstGroupNode;
}

const iconParametersCheck: NamedParametersCheck<AstIconNode> = {
    secure: true,
    enemies: true,
    target: true,
    size: true,
    type: true,
    help: true,
    text: true,
    flash: true,
    enabled: true,
};

export interface AstListItemNode
    extends AstNodeWithParameters<"list_item", "enabled"> {
    name: string;
    item: string;
    description: AstNode;
}

const checkListItemParameters: NamedParametersCheck<AstListItemNode> = {
    enabled: true,
};

export interface AstBangValueNode
    extends AstBaseNodeWithChildren<"bang_value"> {}

export interface AstCommentNode extends AstBaseNode<"comment"> {
    comment: string;
}

export interface AstExpressionNode
    extends AstBaseNodeWithChildren<
        "logical" | "arithmetic" | "compare" | "expression"
    > {
    expressionType: "unary" | "binary";
    operator: OperatorType;
    precedence: number;
}

function isExpressionNode(node: AstNode): node is AstExpressionNode {
    return (
        node.type === "logical" ||
        node.type === "arithmetic" ||
        node.type === "compare" ||
        node.type === "expression"
    );
}

export interface AstFunctionNode
    extends AstNodeWithParameters<
        "state" | "action" | "function" | "custom_function",
        | "target"
        | "filter"
        | "text"
        | "pool_resource"
        | "usable"
        | "offgcd"
        | "texture"
        | "extra_amount"
        | "help"
        | "count"
        | "any"
        | "max"
        | "tagged"
    > {
    name: string;
}

const checkFunctionParameters: NamedParametersCheck<AstFunctionNode> = {
    filter: true,
    target: true,
    text: true,
    pool_resource: true,
    usable: true,
    offgcd: true,
    texture: true,
    extra_amount: true,
    help: true,
    count: true,
    any: true,
    max: true,
    tagged: true,
};

export interface AstStringNode extends AstBaseNode<"string"> {
    value: string;

    /** Used to unparse, if it was a constant that has been replaced by its value */
    name?: string;
    func?: string;
}

export interface AstVariableNode extends AstBaseNode<"variable"> {
    name: string;
}

export interface AstValueNode extends AstBaseNode<"value"> {
    value: number;
    origin: number;
    rate: number;

    /** Used to unparse, if it was a constant that has been replaced by its value */
    name?: string;
}

interface AstDefineNode extends AstBaseNode<"define"> {
    name: string;
    value: string | number;
}
// export interface AstNode {
//     child: LuaArray<AstNode>;
//     type: NodeType;
//     func: string;
//     name: string;
//     rune: string;
//     includeDeath: boolean;
//     itemId: number;
//     spellId: number;
//     key: string;
//     previousType: NodeType;
//     rawPositionalParams: RawPositionalParameters;
//     origin: number;
//     rate: number;
//     // positionalParams: PositionalParameters;
//     rawNamedParams: RawNamedParameters;
//     // namedParams: NamedParameters;
//     paramsAsString: string;
//     postOrder: LuaArray<AstNode>;
//     asString: string;
//     nodeId: number;
//     secure: boolean;
//     operator: OperatorType;
//     expressionType: "unary" | "binary";
//     simc_pool_resource: boolean;
//     simc_wait: boolean;
//     for_next: boolean;
//     extra_amount: number;
//     comment: string;
//     property: keyof SpellInfo;
//     keyword: string;
//     description: AstNode;
//     item?: string;
//     precedence: number;
//     value?: string | number;

//     // ?
//     annotation: AstAnnotation;

//     // Not sure (used in EmitActionList)
//     action: string;
//     asType: "boolean" | "value";
//     left: string;
//     right: string;

//     // ---
//     powerType: string;
// }

const TokenizeComment: Tokenizer = function (token) {
    return ["comment", token];
};

// const TokenizeLua:Tokenizer = function(token) {
//     token = strsub(token, 3, -3);
//     return ["lua", token];
// }

const TokenizeName: Tokenizer = function (token) {
    token = lower(token);
    if (KEYWORD[token]) {
        return ["keyword", token];
    } else {
        return ["name", token];
    }
};

const TokenizeNumber: Tokenizer = function (token) {
    return ["number", token];
};

const TokenizeString: Tokenizer = function (token) {
    token = sub(token, 2, -2);
    return ["string", token];
};
const TokenizeWhitespace: Tokenizer = function (token) {
    return ["space", token];
};

const Tokenize: Tokenizer = function (token) {
    return [token, token];
};
const NoToken: Tokenizer = function () {
    return [undefined, undefined];
};

const MATCHES: LuaArray<TokenizerDefinition> = {
    1: {
        1: "^%s+",
        2: TokenizeWhitespace,
    },
    2: {
        1: "^%d+%.?%d*",
        2: TokenizeNumber,
    },
    3: {
        1: "^[%a_][%w_]*",
        2: TokenizeName,
    },
    4: {
        1: "^((['\"])%2)",
        2: TokenizeString,
    },
    5: {
        1: `^(['\"]).-\\%1`,
        2: TokenizeString,
    },
    6: {
        1: `^(['\\"]).-[^\\]%1`,
        2: TokenizeString,
    },
    7: {
        1: "^#.-\n",
        2: TokenizeComment,
    },
    8: {
        1: "^!=",
        2: Tokenize,
    },
    9: {
        1: "^==",
        2: Tokenize,
    },
    10: {
        1: "^<=",
        2: Tokenize,
    },
    11: {
        1: "^>=",
        2: Tokenize,
    },
    12: {
        1: "^>%?",
        2: Tokenize,
    },
    13: {
        1: "^<%?",
        2: Tokenize,
    },
    14: {
        1: "^.",
        2: Tokenize,
    },
    15: {
        1: "^$",
        2: NoToken,
    },
};

const FILTERS: LexerFilter = {
    comments: TokenizeComment,
    space: TokenizeWhitespace,
};

class SelfPool extends OvalePool<AstNode> {
    constructor(private ovaleAst: OvaleASTClass) {
        super("OvaleAST_pool");
    }

    Clean(node: AstNode): void {
        if (isAstNodeWithChildren(node)) {
            this.ovaleAst.childrenPool.Release(
                (node as AstBaseNodeWithChildren<any>).child
            );
        }
        if (node.postOrder) {
            this.ovaleAst.postOrderPool.Release(node.postOrder);
        }
        wipe(node);
    }
}

type CheckboxParameters = LuaArray<AstNode>;
type ListParameters = LuaObj<AstNode>;

export interface ValuedNamedParameters {
    pertrait?: number;
    nocd?: number;
    cd?: number;
    flash?: string;
    help?: string;
    soundtime?: number;
    enemies?: number;
    texture?: string;
    itemset?: string;
    itemcount?: number;
    proc?: string;
    buff?: string;
    add_duration?: number;
    add_cd?: number;
    addlist?: string;
    dummy_replace?: string;
    learn?: number;
    shared_cd?: number;
    stance?: number;
    to_stance?: number;
    nored?: number;
    sound?: string;
    text?: string;
    mine?: number;
    offgcd?: number;
    casttime?: number;
    pool_resource?: number;
    size?: "small";
    unlimited?: number;
    wait?: number;
    max?: number;
    extra_amount?: number;
    type?: string;
    any?: number;
    usable?: number;
    haste?: HasteType;
    rage?: number;
}

export type NamedParameters<K extends string = DefaultNamedParameters> = {
    [key in K]?: FlattenParameterValue;
};

type FlattenParameterValue = string | number | boolean | undefined;
export type PositionalParameters = LuaArray<FlattenParameterValue>;

type DefaultNamedParameters =
    | keyof ValuedNamedParameters
    | "filter"
    | "target"
    | "listitem"
    | "checkbox"
    | "if"
    | "add"
    | "set"
    | "percent";

export type RawNamedParameters<K extends string = DefaultNamedParameters> = {
    [key in K]?: AstNode;
};

export type RawPositionalParameters = LuaArray<AstNode>;

type ParserFunction<T = AstNode> = (
    tokenStream: OvaleLexer,
    annotation: AstAnnotation,
    minPrecedence?: number
) => T | undefined;
type UnparserFunction<T extends AstNode = AstNode> = (node: T) => string;

function isAstNode(a: any): a is AstNode {
    return type(a) === "table";
}

export class OvaleASTClass {
    private indent: number = 0;
    private outputPool = new OvalePool<LuaArray<string>>("OvaleAST_outputPool");
    private listPool = new OvalePool<ListParameters>("OvaleAST_listPool");
    private checkboxPool = new OvalePool<CheckboxParameters>(
        "OvaleAST_checkboxPool"
    );
    private positionalParametersPool = new OvalePool<PositionalParameters>(
        "OvaleAST_FlattenParameterValues"
    );
    private rawNamedParametersPool = new OvalePool<RawNamedParameters>(
        "OvaleAST_rawNamedParametersPool"
    );
    private rawPositionalParametersPool = new OvalePool<
        RawPositionalParameters
    >("OVALEAST_rawPositionParametersPool");
    private namedParametersPool = new OvalePool<NamedParameters>(
        "OvaleAST_FlattenParametersPool"
    );
    private objectPool = new OvalePool<any>("OvalePool");
    public childrenPool = new OvalePool<LuaArray<AstNode>>(
        "OvaleAST_childrenPool"
    );
    public postOrderPool = new OvalePool<LuaArray<AstNode>>(
        "OvaleAST_postOrderPool"
    );
    private postOrderVisitedPool = new OvalePool<LuaObj<boolean>>(
        "OvaleAST_postOrderVisitedPool"
    );
    private nodesPool = new SelfPool(this);

    private debug: Tracer;
    private profiler: Profiler;

    constructor(
        private ovaleCondition: OvaleConditionClass,
        ovaleDebug: OvaleDebugClass,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleScripts: OvaleScriptsClass,
        private ovaleSpellBook: OvaleSpellBookClass
    ) {
        this.debug = ovaleDebug.create("OvaleAST");
        this.profiler = ovaleProfiler.create("OvaleAST");
    }

    private print_r(
        node: AstNode,
        indent?: string,
        done?: LuaObj<boolean>,
        output?: LuaArray<string>
    ) {
        done = done || {};
        output = output || {};
        indent = indent || "";
        for (const [key, value] of kpairs(node)) {
            if (isAstNode(value)) {
                if (done[value.nodeId]) {
                    insert(
                        output,
                        `${indent}[${tostring(key)}] => (self_reference)`
                    );
                } else {
                    done[value.nodeId] = true;
                    if (value.type) {
                        insert(output, `${indent}[${tostring(key)}] =>`);
                    } else {
                        insert(output, `${indent}[${tostring(key)}] => {`);
                    }
                    this.print_r(value, `${indent}    `, done, output);
                    if (!value.type) {
                        insert(output, `${indent}}`);
                    }
                }
            } else {
                insert(
                    output,
                    `${indent}[${tostring(key)}] => ${tostring(value)}`
                );
            }
        }
        return output;
    }

    private GetNumberNode(value: number, annotation: AstAnnotation) {
        annotation.numberFlyweight = annotation.numberFlyweight || {};
        let node = annotation.numberFlyweight[value];
        if (!node) {
            node = this.NewNode("value", annotation);
            node.value = value;
            node.origin = 0;
            node.rate = 0;
            annotation.numberFlyweight[value] = node;
        }
        return node;
    }

    private PostOrderTraversal(
        node: AstNode,
        array: LuaArray<AstNode>,
        visited: LuaObj<boolean>
    ) {
        if (isAstNodeWithChildren(node)) {
            for (const [, childNode] of ipairs(node.child)) {
                if (!visited[childNode.nodeId]) {
                    this.PostOrderTraversal(childNode, array, visited);
                    array[lualength(array) + 1] = node;
                }
            }
        }
        array[lualength(array) + 1] = node;
        visited[node.nodeId] = true;
    }

    private GetPrecedence(node: AstNode) {
        if (isExpressionNode(node)) {
            let precedence = node.precedence;
            if (!precedence) {
                const operator = node.operator;
                if (operator) {
                    if (node.expressionType == "unary") {
                        const operatorInfos = UNARY_OPERATOR[operator];
                        if (operatorInfos) precedence = operatorInfos[2];
                    } else if (node.expressionType == "binary") {
                        const operatorInfos = BINARY_OPERATOR[operator];
                        if (operatorInfos) precedence = operatorInfos[2];
                    }
                }
            }
            return precedence;
        }
        return 0;
    }

    private HasParameters(node: AstNodeWithParameters<any, any>) {
        return (
            (node.rawPositionalParams && next(node.rawPositionalParams)) ||
            (node.rawNamedParams && next(node.rawNamedParams))
        );
    }

    public Unparse(node: AstNode) {
        if (node.asString) {
            return node.asString;
        } else {
            let visitor = this.UNPARSE_VISITOR[node.type] as UnparserFunction<
                NodeTypes[typeof node.type]
            >;

            if (!visitor) {
                this.debug.Error(
                    "Unable to unparse node of type '%s'.",
                    node.type
                );
                return `Unkown_${node.type}`;
            } else {
                node.asString = visitor(node);
                return node.asString;
            }
        }
    }

    private UnparseAddCheckBox: UnparserFunction<AstCheckBoxNode> = (node) => {
        let s;
        if (
            (node.rawPositionalParams && next(node.rawPositionalParams)) ||
            (node.rawNamedParams && next(node.rawNamedParams))
        ) {
            s = format(
                "AddCheckBox(%s %s %s)",
                node.name,
                this.Unparse(node.description),
                this.UnparseParameters(
                    node.rawPositionalParams,
                    node.rawNamedParams
                )
            );
        } else {
            s = format(
                "AddCheckBox(%s %s)",
                node.name,
                this.Unparse(node.description)
            );
        }
        return s;
    };
    private UnparseAddFunction: UnparserFunction<AstAddFunctionNode> = (
        node
    ) => {
        let s;
        if (this.HasParameters(node)) {
            s = format(
                "AddFunction %s %s%s",
                node.name,
                this.UnparseParameters(
                    node.rawPositionalParams,
                    node.rawNamedParams
                ),
                this.UnparseGroup(node.body)
            );
        } else {
            s = format(
                "AddFunction %s%s",
                node.name,
                this.UnparseGroup(node.body)
            );
        }
        return s;
    };
    private UnparseAddIcon: UnparserFunction<AstIconNode> = (node) => {
        let s;
        if (this.HasParameters(node)) {
            s = format(
                "AddIcon %s%s",
                this.UnparseParameters(
                    node.rawPositionalParams,
                    node.rawNamedParams
                ),
                this.UnparseGroup(node.body)
            );
        } else {
            s = format("AddIcon%s", this.UnparseGroup(node.body));
        }
        return s;
    };
    private UnparseAddListItem: UnparserFunction<AstListItemNode> = (node) => {
        let s;
        if (this.HasParameters(node)) {
            s = format(
                "AddListItem(%s %s %s %s)",
                node.name,
                node.item,
                this.Unparse(node.description),
                this.UnparseParameters(
                    node.rawPositionalParams,
                    node.rawNamedParams
                )
            );
        } else {
            s = format(
                "AddListItem(%s %s %s)",
                node.name,
                node.item,
                this.Unparse(node.description)
            );
        }
        return s;
    };
    private UnparseBangValue: UnparserFunction<AstBangValueNode> = (node) => {
        return `!${this.Unparse(node.child[1])}`;
    };
    private UnparseComment: UnparserFunction<AstCommentNode> = (node) => {
        if (!node.comment || node.comment == "") {
            return "";
        } else {
            return `#${node.comment}`;
        }
    };
    private UnparseDefine: UnparserFunction<AstDefineNode> = (node) => {
        return format("Define(%s %s)", node.name, node.value);
    };
    private UnparseExpression: UnparserFunction<AstExpressionNode> = (node) => {
        let expression;
        let precedence = this.GetPrecedence(node);
        if (node.expressionType == "unary") {
            let rhsExpression;
            let rhsNode = node.child[1];
            let rhsPrecedence = this.GetPrecedence(rhsNode);
            if (rhsPrecedence && precedence >= rhsPrecedence) {
                rhsExpression = `{ ${this.Unparse(rhsNode)} }`;
            } else {
                rhsExpression = this.Unparse(rhsNode);
            }
            if (node.operator == "-") {
                expression = `-${rhsExpression}`;
            } else {
                expression = `${node.operator} ${rhsExpression}`;
            }
        } else if (node.expressionType == "binary") {
            let lhsExpression, rhsExpression;
            let lhsNode = node.child[1];
            let lhsPrecedence = this.GetPrecedence(lhsNode);
            if (lhsPrecedence && lhsPrecedence < precedence) {
                lhsExpression = `{ ${this.Unparse(lhsNode)} }`;
            } else {
                lhsExpression = this.Unparse(lhsNode);
            }
            let rhsNode = node.child[2];
            let rhsPrecedence = this.GetPrecedence(rhsNode);
            if (rhsPrecedence && precedence > rhsPrecedence) {
                rhsExpression = `{ ${this.Unparse(rhsNode)} }`;
            } else if (rhsPrecedence && precedence == rhsPrecedence) {
                const operatorInfo = BINARY_OPERATOR[node.operator];
                if (
                    operatorInfo &&
                    operatorInfo[3] == "associative" &&
                    rhsNode.type === "expression" &&
                    node.operator == rhsNode.operator
                ) {
                    rhsExpression = this.Unparse(rhsNode);
                } else {
                    rhsExpression = `{ ${this.Unparse(rhsNode)} }`;
                }
            } else {
                rhsExpression = this.Unparse(rhsNode);
            }
            expression = `${lhsExpression} ${node.operator} ${rhsExpression}`;
        } else {
            this.debug.Error(
                `node.expressionType '${node.expressionType}' is not known`
            );
            return "Not_Unparsable";
        }
        return expression;
    };
    private UnparseFunction: UnparserFunction<AstFunctionNode> = (node) => {
        let s;
        if (this.HasParameters(node)) {
            let name;
            let filter = node.rawNamedParams.filter;
            if (filter && this.Unparse(filter) == "debuff") {
                name = gsub(node.name, "^Buff", "Debuff");
            } else {
                name = node.name;
            }
            let target = node.rawNamedParams.target;
            if (target && target.type === "string") {
                s = format(
                    "%s.%s(%s)",
                    target.value,
                    name,
                    this.UnparseParameters(
                        node.rawPositionalParams,
                        node.rawNamedParams,
                        true,
                        true
                    )
                );
            } else {
                s = format(
                    "%s(%s)",
                    name,
                    this.UnparseParameters(
                        node.rawPositionalParams,
                        node.rawNamedParams,
                        true
                    )
                );
            }
        } else {
            s = format("%s()", node.name);
        }
        return s;
    };
    private UnparseGroup: UnparserFunction<AstGroupNode> = (node) => {
        let output = this.outputPool.Get();
        output[lualength(output) + 1] = "";
        output[lualength(output) + 1] = `${INDENT(this.indent)}{`;
        this.indent = this.indent + 1;
        for (const [, statementNode] of ipairs(node.child)) {
            let s = this.Unparse(statementNode);
            if (s == "") {
                output[lualength(output) + 1] = s;
            } else {
                output[lualength(output) + 1] = `${INDENT(this.indent)}${s}`;
            }
        }
        this.indent = this.indent - 1;
        output[lualength(output) + 1] = `${INDENT(this.indent)}}`;
        let outputString = concat(output, "\n");
        this.outputPool.Release(output);
        return outputString;
    };
    private UnparseIf: UnparserFunction<AstIfNode> = (node) => {
        if (node.child[2].type == "group") {
            return format(
                "if %s%s",
                this.Unparse(node.child[1]),
                this.UnparseGroup(node.child[2])
            );
        } else {
            return format(
                "if %s %s",
                this.Unparse(node.child[1]),
                this.Unparse(node.child[2])
            );
        }
    };
    private UnparseItemInfo: UnparserFunction<AstItemInfoNode> = (node) => {
        let identifier = (node.name && node.name) || node.itemId;
        return format(
            "ItemInfo(%s %s)",
            identifier,
            this.UnparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private UnparseItemRequire: UnparserFunction<AstItemRequireNode> = (
        node
    ) => {
        let identifier = (node.name && node.name) || node.itemId;
        return format(
            "ItemRequire(%s %s %s)",
            identifier,
            node.property,
            this.UnparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private UnparseList: UnparserFunction<AstListNode> = (node) => {
        return format(
            "%s(%s %s)",
            node.keyword,
            node.name,
            this.UnparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private UnparseValue = (node: AstValueNode) => {
        if (node.name) return node.name;
        return tostring(node.value);
    };

    private unparseParameter(node: AstNode) {
        if (
            node.type === "string" ||
            node.type === "value" ||
            node.type === "variable" ||
            node.type === "boolean"
        ) {
            return this.Unparse(node);
        } else {
            return `(${this.Unparse(node)})`;
        }
    }

    private UnparseParameters(
        positionalParams: RawPositionalParameters,
        namedParams: RawNamedParameters<any>,
        noFilter?: boolean,
        noTarget?: boolean
    ) {
        let output = this.outputPool.Get();
        for (const [k, v] of kpairs(namedParams)) {
            if (
                (!noFilter || k !== "filter") &&
                (!noTarget || k !== "target")
            ) {
                output[lualength(output) + 1] = format(
                    "%s=%s",
                    k,
                    this.unparseParameter(v)
                );
            }
        }

        sort(output);
        for (let k = lualength(positionalParams); k >= 1; k += -1) {
            insert(output, 1, this.unparseParameter(positionalParams[k]));
        }
        let outputString = concat(output, " ");
        this.outputPool.Release(output);
        return outputString;
    }
    private UnparseScoreSpells: UnparserFunction<AstScoreSpellsNode> = (
        node
    ) => {
        return format(
            "ScoreSpells(%s)",
            this.UnparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private UnparseScript: UnparserFunction<AstScriptNode> = (node) => {
        let output = this.outputPool.Get();
        let previousDeclarationType;
        for (const [, declarationNode] of ipairs(node.child)) {
            if (
                declarationNode.type == "item_info" ||
                declarationNode.type == "spell_aura_list" ||
                declarationNode.type == "spell_info" ||
                declarationNode.type == "spell_require"
            ) {
                let s = this.Unparse(declarationNode);
                if (s == "") {
                    output[lualength(output) + 1] = s;
                } else {
                    output[lualength(output) + 1] = `${INDENT(
                        this.indent + 1
                    )}${s}`;
                }
            } else {
                let insertBlank = false;
                if (
                    previousDeclarationType &&
                    previousDeclarationType != declarationNode.type
                ) {
                    insertBlank = true;
                }
                if (
                    declarationNode.type == "add_function" ||
                    declarationNode.type == "icon"
                ) {
                    insertBlank = true;
                }
                if (insertBlank) {
                    output[lualength(output) + 1] = "";
                }
                output[lualength(output) + 1] = this.Unparse(declarationNode);
                previousDeclarationType = declarationNode.type;
            }
        }
        let outputString = concat(output, "\n");
        this.outputPool.Release(output);
        return outputString;
    };
    private UnparseSpellAuraList: UnparserFunction<AstSpellAuraListNode> = (
        node
    ) => {
        let identifier = node.name || node.spellId;
        let buffName = node.buffName || node.buffSpellId;
        return format(
            "%s(%s %s %s)",
            node.keyword,
            identifier,
            buffName,
            this.UnparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private UnparseSpellInfo: UnparserFunction<AstSpellInfoNode> = (node) => {
        let identifier = (node.name && node.name) || node.spellId;
        return format(
            "SpellInfo(%s %s)",
            identifier,
            this.UnparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private UnparseSpellRequire: UnparserFunction<AstSpellRequireNode> = (
        node
    ) => {
        let identifier = (node.name && node.name) || node.spellId;
        return format(
            "SpellRequire(%s %s %s)",
            identifier,
            node.property,
            this.UnparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private UnparseString = (node: AstStringNode) => {
        if (node.name) {
            if (node.func) return `${node.func}(${node.name})`;
            return node.name;
        }
        return `"${node.value}"`;
    };
    private UnparseUnless: UnparserFunction<AstUnlessNode> = (node) => {
        if (node.child[2].type == "group") {
            return format(
                "unless %s%s",
                this.Unparse(node.child[1]),
                this.UnparseGroup(node.child[2])
            );
        } else {
            return format(
                "unless %s %s",
                this.Unparse(node.child[1]),
                this.Unparse(node.child[2])
            );
        }
    };
    private UnparseVariable: UnparserFunction<AstVariableNode> = (node) => {
        return node.name;
    };

    private UNPARSE_VISITOR: {
        [key in keyof NodeTypes]?: UnparserFunction<NodeTypes[key]>;
    } = {
        ["action"]: this.UnparseFunction,
        ["add_function"]: this.UnparseAddFunction,
        ["arithmetic"]: this.UnparseExpression,
        ["bang_value"]: this.UnparseBangValue,
        ["checkbox"]: this.UnparseAddCheckBox,
        ["compare"]: this.UnparseExpression,
        ["comment"]: this.UnparseComment,
        ["custom_function"]: this.UnparseFunction,
        ["define"]: this.UnparseDefine,
        ["function"]: this.UnparseFunction,
        ["group"]: this.UnparseGroup,
        ["icon"]: this.UnparseAddIcon,
        ["if"]: this.UnparseIf,
        ["item_info"]: this.UnparseItemInfo,
        ["itemrequire"]: this.UnparseItemRequire,
        ["list"]: this.UnparseList,
        ["list_item"]: this.UnparseAddListItem,
        ["logical"]: this.UnparseExpression,
        ["score_spells"]: this.UnparseScoreSpells,
        ["script"]: this.UnparseScript,
        ["spell_aura_list"]: this.UnparseSpellAuraList,
        ["spell_info"]: this.UnparseSpellInfo,
        ["spell_require"]: this.UnparseSpellRequire,
        ["state"]: this.UnparseFunction,
        ["string"]: this.UnparseString,
        ["unless"]: this.UnparseUnless,
        ["value"]: this.UnparseValue,
        ["variable"]: this.UnparseVariable,
    };

    private SyntaxError(tokenStream: OvaleLexer, ...__args: any[]) {
        this.debug.Warning(...__args);
        let context: LuaArray<string> = {
            1: "Next tokens:",
        };
        for (let i = 1; i <= 20; i += 1) {
            let [tokenType, token] = tokenStream.Peek(i);
            if (tokenType && token) {
                context[lualength(context) + 1] = token;
            } else {
                context[lualength(context) + 1] = "<EOS>";
                break;
            }
        }
        this.debug.Warning(concat(context, " "));
    }

    private Parse(
        nodeType: NodeType,
        tokenStream: OvaleLexer,
        nodeList: LuaArray<AstNode>,
        annotation: AstAnnotation
    ): Result<AstNode> {
        const visitor = this.PARSE_VISITOR[nodeType];
        this.debug.Debug(`Visit ${nodeType}`);
        if (!visitor) {
            this.debug.Error("Unable to parse node of type '%s'.", nodeType);
            return undefined;
        } else {
            const result = visitor(tokenStream, annotation);
            if (!result) {
                this.debug.Error(`Failed in %s visitor`, nodeType);
            }
            return result;
        }
    }
    private ParseAddCheckBox: ParserFunction<AstCheckBoxNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "addcheckbox")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; 'AddCheckBox' expected.",
                token
            );
            return undefined;
        }

        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; '(' expected.",
                token
            );
            return undefined;
        }

        let name = "";
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name" && token !== undefined) {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; name expected.",
                token
            );
            return undefined;
        }
        const descriptionNode = this.ParseString(tokenStream, annotation);
        if (!descriptionNode) return undefined;

        const [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "ParseAddCheckBox",
            annotation,
            1,
            checkCheckBoxParameters
        );
        if (!positionalParams || !namedParams) return undefined;

        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; ')' expected.",
                token
            );
            return undefined;
        }
        const node = this.newNodeWithParameters(
            "checkbox",
            annotation,
            positionalParams,
            namedParams
        );
        node.name = name;
        node.description = descriptionNode;

        return node;
    };
    private ParseAddFunction: ParserFunction<AstAddFunctionNode> = (
        tokenStream,

        annotation
    ) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "addfunction")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; 'AddFunction' expected.",
                token
            );
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name" && token) {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; name expected.",
                token
            );
            return undefined;
        }
        const [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "ParseAddFunction",
            annotation,
            0,
            checkAddFunctionParameters
        );
        if (!positionalParams || !namedParams) return undefined;
        let bodyNode = this.ParseGroup(tokenStream, annotation);
        if (!bodyNode) return undefined;
        let node;
        node = this.newNodeWithBodyAndParameters(
            "add_function",
            annotation,
            bodyNode,
            positionalParams,
            namedParams
        );
        node.name = name;
        annotation.parametersReference = annotation.parametersReference || {};
        annotation.parametersReference[
            lualength(annotation.parametersReference) + 1
        ] = node;
        annotation.postOrderReference = annotation.postOrderReference || {};
        annotation.postOrderReference[
            lualength(annotation.postOrderReference) + 1
        ] = bodyNode;
        annotation.customFunction = annotation.customFunction || {};
        annotation.customFunction[name] = node;
        return node;
    };
    private ParseAddIcon: ParserFunction<AstIconNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "addicon")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDICON; 'AddIcon' expected.",
                token
            );
            return undefined;
        }
        let [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "addicon",
            annotation,
            0,
            iconParametersCheck
        );
        if (!positionalParams || !namedParams) return undefined;
        let bodyNode = this.ParseGroup(tokenStream, annotation);
        if (!bodyNode) return undefined;
        let node: AstNode;
        node = this.newNodeWithBodyAndParameters(
            "icon",
            annotation,
            bodyNode,
            positionalParams,
            namedParams
        );
        annotation.postOrderReference = annotation.postOrderReference || {};
        annotation.postOrderReference[
            lualength(annotation.postOrderReference) + 1
        ] = bodyNode;
        return node;
    };
    private ParseAddListItem: ParserFunction<AstListItemNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "addlistitem")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; 'AddListItem' expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; '(' expected.",
                token
            );
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name" && token) {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.",
                token
            );
            return undefined;
        }

        let item;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name" && token) {
            item = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.",
                token
            );
            return undefined;
        }
        let descriptionNode = this.ParseString(tokenStream, annotation);
        if (!descriptionNode) return undefined;

        let [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "ParseAddListItem",
            annotation,
            0,
            checkListItemParameters
        );
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; ')' expected.",
                token
            );
            return undefined;
        }
        let node;
        node = this.newNodeWithParameters(
            "list_item",
            annotation,
            positionalParams,
            namedParams
        );
        node.name = name;
        node.item = item;
        node.description = descriptionNode;
        return node;
    };
    private ParseComment: ParserFunction<AstCommentNode> = (
        tokenStream,
        annotation
    ) => {
        return undefined;
    };
    private ParseDeclaration: ParserFunction = (
        tokenStream,
        annotation
    ): AstNode | undefined => {
        let node: AstNode | undefined;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType == "keyword" && token && DECLARATION_KEYWORD[token]) {
            if (token == "addcheckbox") {
                node = this.ParseAddCheckBox(tokenStream, annotation);
            } else if (token == "addfunction") {
                node = this.ParseAddFunction(tokenStream, annotation);
            } else if (token == "addicon") {
                node = this.ParseAddIcon(tokenStream, annotation);
            } else if (token == "addlistitem") {
                node = this.ParseAddListItem(tokenStream, annotation);
            } else if (token == "define") {
                node = this.ParseDefine(tokenStream, annotation);
            } else if (token == "include") {
                node = this.ParseInclude(tokenStream, annotation);
            } else if (token == "iteminfo") {
                node = this.ParseItemInfo(tokenStream, annotation);
            } else if (token == "itemrequire") {
                node = this.ParseItemRequire(tokenStream, annotation);
            } else if (token == "itemlist") {
                node = this.ParseList(tokenStream, annotation);
            } else if (token == "scorespells") {
                node = this.ParseScoreSpells(tokenStream, annotation);
            } else if (checkToken(SPELL_AURA_KEYWORD, token)) {
                node = this.ParseSpellAuraList(tokenStream, annotation);
            } else if (token == "spellinfo") {
                node = this.ParseSpellInfo(tokenStream, annotation);
            } else if (token == "spelllist") {
                node = this.ParseList(tokenStream, annotation);
            } else if (token == "spellrequire") {
                node = this.ParseSpellRequire(tokenStream, annotation);
            } else {
                this.SyntaxError(
                    tokenStream,
                    "Syntax error: unknown keywork '%s'",
                    token
                );
                return;
            }
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing DECLARATION; declaration keyword expected.",
                token
            );
            tokenStream.Consume();
            return undefined;
        }
        return node;
    };
    private ParseDefine: ParserFunction<AstDefineNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "define")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing DEFINE; 'Define' expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing DEFINE; '(' expected.",
                token
            );
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name" && token) {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing DEFINE; name expected.",
                token
            );
            return undefined;
        }
        let value: string | number;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "-") {
            [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                value = -1 * tonumber(token);
            } else {
                this.SyntaxError(
                    tokenStream,
                    "Syntax error: unexpected token '%s' when parsing DEFINE; number expected after '-'.",
                    token
                );
                return undefined;
            }
        } else if (tokenType == "number") {
            value = tonumber(token);
        } else if (tokenType == "string" && token) {
            value = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing DEFINE; number or string expected.",
                token
            );
            return undefined;
        }

        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing DEFINE; ')' expected.",
                token
            );
            return undefined;
        }
        let node: AstDefineNode;
        node = this.NewNode("define", annotation);
        node.name = name;
        node.value = value;
        annotation.definition = annotation.definition || {};
        annotation.definition[name] = value;
        return node;
    };
    private ParseExpression: ParserFunction<AstNode> = (
        tokenStream,
        annotation,
        minPrecedence?
    ) => {
        minPrecedence = minPrecedence || 0;
        let node: AstNode;

        let [tokenType, token] = tokenStream.Peek();
        if (tokenType) {
            let opInfo = UNARY_OPERATOR[token as OperatorType];
            if (opInfo) {
                let [opType, precedence] = [opInfo[1], opInfo[2]];
                tokenStream.Consume();
                let operator: OperatorType = <OperatorType>token;
                const rhsNode = this.ParseExpression(
                    tokenStream,
                    annotation,
                    precedence
                );
                if (rhsNode) {
                    if (operator == "-" && rhsNode.type === "value") {
                        let value = -1 * tonumber(rhsNode.value);
                        node = this.GetNumberNode(value, annotation);
                    } else {
                        node = this.newNodeWithChildren(opType, annotation);
                        node.expressionType = "unary";
                        node.operator = operator;
                        node.precedence = precedence;
                        node.child[1] = rhsNode;
                    }
                } else {
                    return undefined;
                }
            } else if (token === "{") {
                const expression = this.parseGroup(tokenStream, annotation);
                if (!expression) return undefined;
                node = expression;
            } else {
                const simpleExpression = this.ParseSimpleExpression(
                    tokenStream,
                    annotation
                );
                if (!simpleExpression) return undefined;
                node = simpleExpression;
            }
        } else {
            return undefined;
        }

        let keepScanning = true;
        while (keepScanning) {
            keepScanning = false;
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType) {
                let opInfo = BINARY_OPERATOR[token as OperatorType];
                if (opInfo) {
                    let [opType, precedence] = [opInfo[1], opInfo[2]];
                    if (precedence && precedence > minPrecedence) {
                        keepScanning = true;
                        tokenStream.Consume();
                        let operator = <OperatorType>token;
                        let lhsNode = node;
                        let rhsNode = this.ParseExpression(
                            tokenStream,
                            annotation,
                            precedence
                        );
                        if (rhsNode) {
                            node = this.newNodeWithChildren(opType, annotation);
                            node.expressionType = "binary";
                            node.operator = operator;
                            node.precedence = precedence;

                            node.child[1] = lhsNode;
                            node.child[2] = rhsNode;
                            const operatorInfo = BINARY_OPERATOR[node.operator];
                            if (!operatorInfo) return undefined;
                            while (
                                node.type == rhsNode.type &&
                                node.operator == rhsNode.operator &&
                                operatorInfo[3] == "associative" &&
                                rhsNode.expressionType == "binary"
                            ) {
                                node.child[2] = rhsNode.child[1];
                                rhsNode.child[1] = node;
                                node = rhsNode;
                                rhsNode = node.child[2];
                            }
                        } else {
                            return undefined;
                        }
                    }
                }
            }
        }
        return node;
    };

    private ParseFunction: ParserFunction<AstFunctionNode> = (
        tokenStream,
        annotation
    ) => {
        let name;
        {
            let [tokenType, token] = tokenStream.Consume();
            if ((tokenType === "name" || tokenType === "keyword") && token) {
                name = token;
            } else {
                this.SyntaxError(
                    tokenStream,
                    "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.",
                    token
                );
                return undefined;
            }
        }
        let target;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType == ".") {
            target = name;
            [tokenType, token] = tokenStream.Consume(2);
            if (tokenType == "name" && token) {
                name = token;
            } else {
                this.SyntaxError(
                    tokenStream,
                    "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.",
                    token
                );
                return undefined;
            }
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing FUNCTION; '(' expected.",
                token
            );
            return undefined;
        }
        let [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "function",
            annotation,
            undefined,
            checkFunctionParameters
        );
        if (!positionalParams || !namedParams) return undefined;
        if (ACTION_PARAMETER_COUNT[name]) {
            let count = ACTION_PARAMETER_COUNT[name];
            if (count > lualength(positionalParams)) {
                this.SyntaxError(
                    tokenStream,
                    "Syntax error: action '%s' requires at least %d fixed parameter(s).",
                    name,
                    count
                );
                return undefined;
            }
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.",
                token
            );
            return undefined;
        }
        if (!namedParams.target) {
            if (sub(name, 1, 6) == "target") {
                namedParams.target = this.newString(annotation, "target");
                name = sub(name, 7);
            }
        }
        if (!namedParams.filter) {
            if (sub(name, 1, 6) == "debuff") {
                namedParams.filter = this.newString(annotation, "debuff");
            } else if (sub(name, 1, 4) == "buff") {
                namedParams.filter = this.newString(annotation, "buff");
            } else if (sub(name, 1, 11) == "otherdebuff") {
                namedParams.filter = this.newString(annotation, "debuff");
            } else if (sub(name, 1, 9) == "otherbuff") {
                namedParams.filter = this.newString(annotation, "buff");
            }
        }
        if (target) {
            namedParams.target = this.newString(annotation, target);
        }
        let node;
        let nodeType: "state" | "action" | "function" | "custom_function";
        if (STATE_ACTION[name]) {
            nodeType = "state";
        } else if (ACTION_PARAMETER_COUNT[name]) {
            nodeType = "action";
        } else if (STRING_LOOKUP_FUNCTION[name]) {
            nodeType = "function";
        } else if (this.ovaleCondition.IsCondition(name)) {
            nodeType = "function";
        } else {
            nodeType = "custom_function";
        }

        node = this.newNodeWithParameters(
            nodeType,
            annotation,
            positionalParams,
            namedParams
        );
        node.name = name;
        if (STRING_LOOKUP_FUNCTION[name]) {
            annotation.stringReference = annotation.stringReference || {};
            annotation.stringReference[
                lualength(annotation.stringReference) + 1
            ] = node;
        }
        node.asString = this.UnparseFunction(node);
        annotation.functionCall = annotation.functionCall || {};
        annotation.functionCall[node.name] = true;
        annotation.functionReference = annotation.functionReference || {};
        annotation.functionReference[
            lualength(annotation.functionReference) + 1
        ] = node;
        return node;
    };

    private parseGroup(tokenStream: OvaleLexer, annotation: AstAnnotation) {
        const group = this.ParseGroup(tokenStream, annotation);
        if (group && lualength(group.child) === 1) {
            const result = group.child[1];
            this.nodesPool.Release(group);
            return result;
        }
        return group;
    }

    private ParseGroup: ParserFunction<AstGroupNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType != "{") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing GROUP; '{' expected.",
                token
            );
            return undefined;
        }
        let node = this.newNodeWithChildren("group", annotation);
        let child = node.child;
        [tokenType] = tokenStream.Peek();
        while (tokenType && tokenType != "}") {
            let statementNode;
            statementNode = this.ParseStatement(tokenStream, annotation);
            if (statementNode) {
                child[lualength(child) + 1] = statementNode;
                [tokenType] = tokenStream.Peek();
            } else {
                this.nodesPool.Release(node);
                return undefined;
            }
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "}") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing GROUP; '}' expected.",
                token
            );
            this.nodesPool.Release(node);
            return undefined;
        }
        return node;
    };
    private ParseIf: ParserFunction<AstIfNode> = (tokenStream, annotation) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "if")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing IF; 'if' expected.",
                token
            );
            return undefined;
        }
        let conditionNode, bodyNode;
        conditionNode = this.ParseStatement(tokenStream, annotation);
        if (!conditionNode) return undefined;
        bodyNode = this.ParseStatement(tokenStream, annotation);
        if (!bodyNode) return undefined;
        let node;
        node = this.newNodeWithChildren("if", annotation);
        node.child[1] = conditionNode;
        node.child[2] = bodyNode;
        return node;
    };
    private ParseInclude: ParserFunction<AstScriptNode> = (
        tokenStream,
        nodeList,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "include")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing INCLUDE; 'Include' expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing INCLUDE; '(' expected.",
                token
            );
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name" && token) {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing INCLUDE; script name expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing INCLUDE; ')' expected.",
                token
            );
            return undefined;
        }
        let code = this.ovaleScripts.GetScript(name);
        if (code === undefined) {
            this.debug.Error(
                "Script '%s' not found when parsing INCLUDE.",
                name
            );
            return undefined;
        }
        let node;
        let includeTokenStream = new OvaleLexer(name, code, MATCHES, FILTERS);
        node = this.ParseScriptStream(includeTokenStream, nodeList, annotation);
        includeTokenStream.Release();
        return node;
    };
    private ParseItemInfo: ParserFunction<AstItemInfoNode> = (
        tokenStream,
        annotation
    ) => {
        let name;
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "iteminfo")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMINFO; 'ItemInfo' expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMINFO; '(' expected.",
                token
            );
            return undefined;
        }
        let itemId;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "number") {
            itemId = token;
        } else if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMINFO; number or name expected.",
                token
            );
            return undefined;
        }
        let [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "iteminfo",
            annotation,
            undefined,
            checkSpellInfo
        );
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMINFO; ')' expected.",
                token
            );
            return undefined;
        }
        let node;
        node = this.newNodeWithParameters(
            "item_info",
            annotation,
            positionalParams,
            namedParams
        );
        node.itemId = tonumber(itemId);
        if (name) {
            node.name = name;
            annotation.nameReference = annotation.nameReference || {};
            annotation.nameReference[
                lualength(annotation.nameReference) + 1
            ] = node;
        }
        return node;
    };

    private ParseItemRequire: ParserFunction<AstItemRequireNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "itemrequire")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; keyword expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; '(' expected.",
                token
            );
            return undefined;
        }
        let itemId, name;

        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "number") {
            itemId = token;
        } else if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; number or name expected.",
                token
            );
            return undefined;
        }
        let property = this.parseName(
            tokenStream,
            "ITEMREQUIRE",
            checkSpellInfo
        );
        if (!property) return undefined;

        let [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "itemrequire",
            annotation,
            0,
            checkSpellRequireParameters
        );
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; ')' expected.",
                token
            );
            return undefined;
        }
        let node;
        node = this.newNodeWithParameters(
            "itemrequire",
            annotation,
            positionalParams,
            namedParams
        );
        node.itemId = tonumber(itemId);
        if (name) node.name = name;
        node.property = property;
        if (name) {
            annotation.nameReference = annotation.nameReference || {};
            annotation.nameReference[
                lualength(annotation.nameReference) + 1
            ] = node;
        }
        return node;
    };
    private ParseList: ParserFunction<AstListNode> = (
        tokenStream,
        annotation
    ) => {
        let keyword;
        let [tokenType, token] = tokenStream.Consume();
        if (
            tokenType == "keyword" &&
            (token == "itemlist" || token == "spelllist")
        ) {
            keyword = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing LIST; keyword expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing LIST; '(' expected.",
                token
            );
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name" && token) {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing LIST; name expected.",
                token
            );
            return undefined;
        }
        let [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "list",
            annotation,
            undefined,
            checkListParameters
        );
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing LIST; ')' expected.",
                token
            );
            return undefined;
        }
        let node;
        node = this.newNodeWithParameters(
            "list",
            annotation,
            positionalParams,
            namedParams
        );
        node.keyword = keyword;
        node.name = name;
        annotation.definition[name] = name;
        return node;
    };
    private ParseNumber = (
        tokenStream: OvaleLexer,
        annotation: AstAnnotation
    ): Result<AstValueNode> => {
        let value;
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "number") {
            value = tonumber(token);
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing NUMBER; number expected.",
                token
            );
            return undefined;
        }
        let node = this.GetNumberNode(value, annotation);
        return node;
    };
    private ParseParameters<T extends string = DefaultNamedParameters>(
        tokenStream: OvaleLexer,
        methodName: string,
        annotation: AstAnnotation,
        maxNumberOfParameters: number | undefined,
        namedParameters: KeyCheck<T>
    ): [RawPositionalParameters?, RawNamedParameters<T>?] {
        let positionalParams = this.rawPositionalParametersPool.Get();
        let namedParams = <RawNamedParameters<T>>(
            this.rawNamedParametersPool.Get()
        );
        while (true) {
            let [tokenType] = tokenStream.Peek();
            if (tokenType) {
                const [nextTokenType] = tokenStream.Peek(2);
                if (nextTokenType === "=") {
                    const parameterName = this.parseName(
                        tokenStream,
                        methodName,
                        namedParameters
                    );
                    if (!parameterName) {
                        return [];
                    }

                    // Consume the '=' token.
                    tokenStream.Consume();

                    const node = this.ParseSimpleParameterValue(
                        tokenStream,
                        annotation
                    );
                    if (!node) return [];
                    namedParams[parameterName] = node;
                } else {
                    let node;
                    if (tokenType == "name" || tokenType === "keyword") {
                        node = this.ParseVariable(tokenStream, annotation);
                        if (!node) {
                            return [];
                        }
                    } else if (tokenType == "number") {
                        node = this.ParseNumber(tokenStream, annotation);
                        if (!node) {
                            return [];
                        }
                    } else if (tokenType == "-") {
                        tokenStream.Consume();
                        node = this.ParseNumber(tokenStream, annotation);
                        if (node) {
                            let value = -1 * <number>node.value;
                            node = this.GetNumberNode(value, annotation);
                        } else {
                            return [];
                        }
                    } else if (tokenType == "string") {
                        node = this.ParseString(tokenStream, annotation);
                        if (!node) {
                            return [];
                        }
                    } else {
                        break;
                    }

                    // Check if this is a bare value or the start of a "name=value" pair.
                    positionalParams[lualength(positionalParams) + 1] = node;
                    if (
                        maxNumberOfParameters &&
                        lualength(positionalParams) > maxNumberOfParameters
                    ) {
                        this.SyntaxError(
                            tokenStream,
                            "Error: the maximum number of parameters in %s is %s",
                            methodName,
                            maxNumberOfParameters
                        );
                        return [];
                    }
                }
            } else {
                break;
            }
        }
        annotation.rawPositionalParametersList =
            annotation.rawPositionalParametersList || {};
        annotation.rawPositionalParametersList[
            lualength(annotation.rawPositionalParametersList) + 1
        ] = positionalParams;
        annotation.rawNamedParametersList =
            annotation.rawNamedParametersList || {};
        annotation.rawNamedParametersList[
            lualength(annotation.rawNamedParametersList) + 1
        ] = namedParams;
        return [positionalParams, namedParams];
    }
    private ParseParentheses(
        tokenStream: OvaleLexer,
        annotation: AstAnnotation
    ): AstNode | undefined {
        let leftToken, rightToken;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "(") {
                [leftToken, rightToken] = ["(", ")"];
            } else if (tokenType == "{") {
                [leftToken, rightToken] = ["{", "}"];
            } else {
                this.SyntaxError(
                    tokenStream,
                    "Syntax error: unexpected token '%s' when parsing PARENTHESES; '(' or '{' expected.",
                    token
                );
                return undefined;
            }
        }
        let node = this.ParseExpression(tokenStream, annotation);
        if (!node) return undefined;
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType != rightToken) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing PARENTHESES; '%s' expected.",
                token,
                rightToken
            );
            return undefined;
        }
        node.left = leftToken;
        node.right = rightToken;
        return node;
    }
    private ParseScoreSpells: ParserFunction<AstScoreSpellsNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "scorespells")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SCORESPELLS; 'ScoreSpells' expected.",
                token
            );
            return undefined;
        }

        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SCORESPELLS; '(' expected.",
                token
            );
            return undefined;
        }

        const [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "scorespells",
            annotation,
            undefined,
            checkListParameters
        );
        if (!positionalParams || !namedParams) return undefined;

        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SCORESPELLS; ')' expected.",
                token
            );
            return undefined;
        }
        const node = this.newNodeWithParameters(
            "score_spells",
            annotation,
            positionalParams,
            namedParams
        );
        return node;
    };
    private ParseScriptStream: ParserFunction<AstScriptNode> = (
        tokenStream: OvaleLexer,
        annotation
    ) => {
        this.profiler.StartProfiling("OvaleAST_ParseScript");
        let ast: AstNode;
        ast = this.newNodeWithChildren("script", annotation);
        const child = ast.child;
        while (true) {
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType) {
                let declarationNode = this.ParseDeclaration(
                    tokenStream,
                    annotation
                );
                if (!declarationNode) {
                    this.debug.Error(`Failed on ${token}`);
                    this.nodesPool.Release(ast);
                    return undefined;
                }
                if (declarationNode.type == "script") {
                    for (const [, node] of ipairs(declarationNode.child)) {
                        child[lualength(child) + 1] = node;
                    }
                    this.nodesPool.Release(declarationNode);
                } else {
                    child[lualength(child) + 1] = declarationNode;
                }
            } else {
                break;
            }
        }
        this.profiler.StopProfiling("OvaleAST_ParseScript");
        return ast;
    };
    private ParseSimpleExpression(
        tokenStream: OvaleLexer,
        annotation: AstAnnotation
    ) {
        let node;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType == "number") {
            node = this.ParseNumber(tokenStream, annotation);
        } else if (tokenType == "string") {
            node = this.ParseString(tokenStream, annotation);
        } else if (tokenType == "name" || tokenType === "keyword") {
            [tokenType, token] = tokenStream.Peek(2);
            if (tokenType == "." || tokenType == "(") {
                node = this.ParseFunction(tokenStream, annotation);
            } else {
                node = this.ParseVariable(tokenStream, annotation);
            }
        } else if (tokenType == "(" || tokenType == "{") {
            node = this.ParseParentheses(tokenStream, annotation);
        } else {
            tokenStream.Consume();
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION",
                token
            );
            return undefined;
        }
        return node;
    }
    private ParseSimpleParameterValue: ParserFunction<AstNode> = (
        tokenStream,
        annotation
    ) => {
        let isBang = false;
        let [tokenType] = tokenStream.Peek();
        if (tokenType == "!") {
            isBang = true;
            tokenStream.Consume();
        }
        let expressionNode;
        [tokenType] = tokenStream.Peek();
        if (tokenType == "(" || tokenType == "-") {
            expressionNode = this.ParseExpression(tokenStream, annotation);
        } else {
            expressionNode = this.ParseSimpleExpression(
                tokenStream,
                annotation
            );
        }
        if (!expressionNode) return undefined;
        let node;
        if (isBang) {
            node = this.newNodeWithChildren("bang_value", annotation);
            node.child[1] = expressionNode;
        } else {
            node = expressionNode;
        }
        return node;
    };

    private parseNumberOrNameParameter(
        tokenStream: OvaleLexer,
        methodName: string
    ): [number?, string?] {
        let [tokenType, token] = tokenStream.Consume();
        let spellId, name;
        if (tokenType === "-") {
            [tokenType, token] = tokenStream.Consume();
            if (tokenType === "number") spellId = -tonumber(token);
            else {
                this.SyntaxError(
                    tokenStream,
                    "Syntax error: unexpected token '%s' wheren parsing '%s'; number expected",
                    token,
                    methodName
                );
                return [];
            }
        } else if (tokenType == "number") {
            spellId = tonumber(token);
        } else if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing '%s'; number or name expected.",
                token,
                methodName
            );
            return [];
        }
        return [spellId, name];
    }

    // private parseName(tokenStream: OvaleLexer, methodName: string) {
    //     let [tokenType, token] = tokenStream.Consume();
    //     if (tokenType === "name") {
    //         return token;
    //     }
    //     this.SyntaxError(
    //         tokenStream,
    //         "Syntax error: unexpected token '%s' when parsing '%s'; name expected",
    //         token,
    //         methodName
    //     );
    //     return undefined;
    // }

    // private parseNumber(
    //     tokenStream: OvaleLexer,
    //     methodName: string
    // ): number | undefined {
    //     let [tokenType, token] = tokenStream.Consume();
    //     let spellId;
    //     if (tokenType === "-") {
    //         [tokenType, token] = tokenStream.Consume();
    //         if (tokenType === "number") spellId = -tonumber(token);
    //         else {
    //             this.SyntaxError(
    //                 tokenStream,
    //                 "Syntax error: unexpected token '%s' wheren parsing '%s'; number expected",
    //                 token,
    //                 methodName
    //             );
    //             return undefined;
    //         }
    //     } else if (tokenType == "number") {
    //         spellId = tonumber(token);
    //     } else {
    //         this.SyntaxError(
    //             tokenStream,
    //             "Syntax error: unexpected token '%s' when parsing '%s'; number expected.",
    //             token,
    //             methodName
    //         );
    //         return undefined;
    //     }
    //     return spellId;
    // }

    private parseToken(
        tokenStream: OvaleLexer,
        methodName: string,
        expectedToken: string
    ) {
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType != expectedToken) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing %s; '%s' expected.",
                token,
                methodName,
                expectedToken
            );
            return false;
        }
        return true;
    }

    private parseKeywords<T extends string>(
        tokenStream: OvaleLexer,
        methodName: string,
        keyCheck: KeyCheck<T>
    ): T | undefined {
        let keyword;
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "keyword" && token && checkToken(keyCheck, token)) {
            keyword = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing %s; keyword expected.",
                token,
                methodName
            );
            return undefined;
        }
        return keyword;
    }

    private parseKeyword<T extends string>(
        tokenStream: OvaleLexer,
        methodName: string,
        keyCheck: T
    ): T | undefined {
        let keyword;
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "keyword" && token && token === keyCheck) {
            keyword = keyCheck;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing %s; keyword %s expected.",
                token,
                methodName,
                keyCheck
            );
            return undefined;
        }
        return keyword;
    }

    private parseName<T extends string>(
        tokenStream: OvaleLexer,
        methodName: string,
        keyCheck: KeyCheck<T>
    ): T | undefined {
        let keyword;
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name" && token && checkToken(keyCheck, token)) {
            keyword = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing %s; name expected.",
                token,
                methodName
            );
            return undefined;
        }
        return keyword;
    }

    private ParseSpellAuraList: ParserFunction<AstSpellAuraListNode> = (
        tokenStream,
        annotation
    ) => {
        let keyword = this.parseKeywords(
            tokenStream,
            "SPELLAURALIST",
            SPELL_AURA_KEYWORD
        );

        if (!keyword) {
            this.debug.Error("Failed on keyword");
            return undefined;
        }

        if (!this.parseToken(tokenStream, "SPELLAURALIST", "(")) {
            this.debug.Error("Failed on (");
            return undefined;
        }
        let [spellId, name] = this.parseNumberOrNameParameter(
            tokenStream,
            "SPELLAURALIST"
        );
        let [buffSpellId, buffName] = this.parseNumberOrNameParameter(
            tokenStream,
            "SPELLAURALIST"
        );

        let [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "spellauralist",
            annotation,
            0,
            spellAuraListParametersCheck
        );
        if (!positionalParams || !namedParams) {
            return undefined;
        }
        if (!this.parseToken(tokenStream, "SPELLAURALIST", ")")) {
            this.debug.Error("Failed on )");
            return undefined;
        }

        let node: AstNode;
        node = this.newNodeWithParameters(
            "spell_aura_list",
            annotation,
            positionalParams,
            namedParams
        );
        node.keyword = keyword;
        if (spellId) node.spellId = spellId;
        else if (name) node.name = name;
        if (buffSpellId) node.buffSpellId = buffSpellId;
        else if (buffName) node.buffName = buffName;
        if (name || buffName) {
            annotation.nameReference = annotation.nameReference || {};
            annotation.nameReference[
                lualength(annotation.nameReference) + 1
            ] = node;
        }
        return node;
    };
    private ParseSpellInfo: ParserFunction<AstSpellInfoNode> = (
        tokenStream,
        annotation
    ) => {
        let name;
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "spellinfo")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SPELLINFO; 'SpellInfo' expected.",
                token
            );
            return undefined;
        }

        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SPELLINFO; '(' expected.",
                token
            );
            return undefined;
        }
        let spellId;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "number") {
            spellId = tonumber(token);
        } else if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SPELLINFO; number or name expected.",
                token
            );
            return undefined;
        }
        let [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "spellinfo",
            annotation,
            0,
            checkSpellInfo
        );
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SPELLINFO; ')' expected.",
                token
            );
            return undefined;
        }
        let node;
        node = this.newNodeWithParameters(
            "spell_info",
            annotation,
            positionalParams,
            namedParams
        );
        if (spellId) node.spellId = spellId;
        if (name) {
            node.name = name;
            annotation.nameReference = annotation.nameReference || {};
            annotation.nameReference[
                lualength(annotation.nameReference) + 1
            ] = node;
        }
        return node;
    };
    private ParseSpellRequire: ParserFunction<AstSpellRequireNode> = (
        tokenStream,
        annotation
    ) => {
        if (
            this.parseKeyword(tokenStream, "SPELLREQUIRE", "spellrequire") ===
            undefined
        )
            return undefined;
        if (!this.parseToken(tokenStream, "SPELLREQUIRE", "("))
            return undefined;
        const [spellId, name] = this.parseNumberOrNameParameter(
            tokenStream,
            "SPELLREQUIRE"
        );
        if (!spellId && !name) return undefined;

        let property = this.parseName(
            tokenStream,
            "SPELLREQUIRE",
            checkSpellInfo
        );
        if (!property) return undefined;

        let [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "spellrequire",
            annotation,
            0,
            checkSpellRequireParameters
        );
        if (!positionalParams || !namedParams) return undefined;
        if (!this.parseToken(tokenStream, "SPELLREQUIRE", ")"))
            return undefined;

        const node = this.newNodeWithParameters(
            "spell_require",
            annotation,
            positionalParams,
            namedParams
        );
        if (spellId) node.spellId = spellId;

        node.property = property;
        if (name) {
            node.name = name;
            annotation.nameReference = annotation.nameReference || {};
            annotation.nameReference[
                lualength(annotation.nameReference) + 1
            ] = node;
        }
        return node;
    };

    private ParseStatement = (
        tokenStream: OvaleLexer,
        annotation: AstAnnotation
    ): AstNode | undefined => {
        let node;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType) {
            if (token == "{") {
                let i = 1;
                let count = 0;
                while (tokenType) {
                    if (token == "{") {
                        count = count + 1;
                    } else if (token == "}") {
                        count = count - 1;
                    }
                    i = i + 1;
                    [tokenType, token] = tokenStream.Peek(i);
                    if (count == 0) {
                        break;
                    }
                }
                if (!tokenType || BINARY_OPERATOR[token as OperatorType]) {
                    node = this.ParseExpression(tokenStream, annotation);
                } else {
                    node = this.parseGroup(tokenStream, annotation);
                }
            } else if (token == "if") {
                node = this.ParseIf(tokenStream, annotation);
            } else if (token == "unless") {
                node = this.ParseUnless(tokenStream, annotation);
            } else {
                node = this.ParseExpression(tokenStream, annotation);
            }
        }
        return node;
    };
    private ParseString: ParserFunction<AstStringNode | AstFunctionNode> = (
        tokenStream,
        annotation
    ) => {
        let value;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType == "string" && token) {
            value = token;
            tokenStream.Consume();
        } else if (tokenType == "name" && token) {
            if (STRING_LOOKUP_FUNCTION[lower(token)]) {
                return this.ParseFunction(tokenStream, annotation);
            } else {
                value = token;
                tokenStream.Consume();
            }
        } else {
            tokenStream.Consume();
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing STRING; string, variable, or function expected.",
                token
            );
            return undefined;
        }

        let node: AstStringNode;
        node = this.NewNode("string", annotation);
        node.value = value;
        annotation.stringReference = annotation.stringReference || {};
        annotation.stringReference[
            lualength(annotation.stringReference) + 1
        ] = node;
        return node;
    };
    private ParseUnless: ParserFunction<AstUnlessNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "unless")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing UNLESS; 'unless' expected.",
                token
            );
            return undefined;
        }
        let conditionNode, bodyNode;
        conditionNode = this.ParseExpression(tokenStream, annotation);
        if (!conditionNode) return undefined;
        bodyNode = this.ParseStatement(tokenStream, annotation);
        if (!bodyNode) return undefined;
        let node;
        node = this.newNodeWithChildren("unless", annotation);
        node.child[1] = conditionNode;
        node.child[2] = bodyNode;
        return node;
    };
    private ParseVariable: ParserFunction<AstVariableNode> = (
        tokenStream,
        annotation
    ) => {
        let name;
        let [tokenType, token] = tokenStream.Consume();
        if ((tokenType == "name" || tokenType === "keyword") && token) {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing VARIABLE; name expected.",
                token
            );
            return undefined;
        }

        let node;
        node = this.NewNode("variable", annotation);
        node.name = name;
        annotation.nameReference = annotation.nameReference || {};
        annotation.nameReference[
            lualength(annotation.nameReference) + 1
        ] = node;
        return node;
    };
    private PARSE_VISITOR: { [key in NodeType]?: ParserFunction } = {
        ["action"]: this.ParseFunction,
        ["add_function"]: this.ParseAddFunction,
        ["arithmetic"]: this.ParseExpression,
        ["bang_value"]: this.ParseSimpleParameterValue,
        ["checkbox"]: this.ParseAddCheckBox,
        ["compare"]: this.ParseExpression,
        ["comment"]: this.ParseComment,
        ["custom_function"]: this.ParseFunction,
        ["define"]: this.ParseDefine,
        ["expression"]: this.ParseStatement,
        ["function"]: this.ParseFunction,
        ["group"]: this.ParseGroup,
        ["icon"]: this.ParseAddIcon,
        ["if"]: this.ParseIf,
        ["item_info"]: this.ParseItemInfo,
        ["itemrequire"]: this.ParseItemRequire,
        ["list"]: this.ParseList,
        ["list_item"]: this.ParseAddListItem,
        ["logical"]: this.ParseExpression,
        ["score_spells"]: this.ParseScoreSpells,
        ["script"]: this.ParseScriptStream,
        ["spell_aura_list"]: this.ParseSpellAuraList,
        ["spell_info"]: this.ParseSpellInfo,
        ["spell_require"]: this.ParseSpellRequire,
        ["string"]: this.ParseString,
        ["unless"]: this.ParseUnless,
        ["value"]: this.ParseNumber,
        ["variable"]: this.ParseVariable,
    };

    public newFunction(name: string, annotation: AstAnnotation) {
        const node = this.newNodeWithParameters("function", annotation);
        node.name = name;
        return node;
    }

    public newString(annotation: AstAnnotation, value: string) {
        const node = this.NewNode("string", annotation);
        node.value = value;
        return node;
    }

    public newVariable(annotation: AstAnnotation, name: string) {
        const node = this.NewNode("variable", annotation);
        node.name = name;
        return node;
    }

    public newValue(annotation: AstAnnotation, value: number) {
        const node = this.NewNode("value", annotation);
        node.value = value;
        return node;
    }

    private internalNewNodeWithParameters<T extends NodeWithParametersType>(
        type: T,
        annotation: AstAnnotation,
        rawPositionalParameters?: RawPositionalParameters,
        rawNamedParams?: NodeTypes[T]["rawNamedParams"]
    ) {
        const node = this.internalNewNodeWithChildren(type, annotation);
        node.rawNamedParams =
            rawNamedParams || this.rawNamedParametersPool.Get();
        node.rawPositionalParams =
            rawPositionalParameters || this.rawPositionalParametersPool.Get();
        node.cachedParams = {
            named: this.namedParametersPool.Get(),
            positional: this.positionalParametersPool.Get(),
        };
        annotation.parametersReference = annotation.parametersReference || {};
        annotation.parametersReference[
            lualength(annotation.parametersReference) + 1
        ] = node;
        return node;
    }

    private internalNewNodeWithChildren<T extends NodeWithChildrenType>(
        type: T,
        annotation: AstAnnotation
    ) {
        const node = this.internalNewNode(type, annotation);
        node.child = this.childrenPool.Get();
        return node;
    }

    private internalNewNode<T extends NodeType>(
        type: T,
        annotation: AstAnnotation
    ): NodeTypes[T] {
        let node = this.nodesPool.Get() as NodeTypes[T];
        node.type = type;
        node.annotation = annotation;
        const nodeList = annotation.nodeList;
        let nodeId = lualength(nodeList) + 1;
        node.nodeId = nodeId;
        nodeList[nodeId] = node;
        node.result = { type: "none", timeSpan: newTimeSpan(), serial: 0 };
        return node;
    }

    public newNodeWithBodyAndParameters<T extends NodeWithBodyType>(
        type: T,
        annotation: AstAnnotation,
        body: NodeTypes[T]["body"],
        rawPositionalParameters?: RawPositionalParameters,
        rawNamedParams?: NodeTypes[T]["rawNamedParams"]
    ): NodeTypes[T] {
        const node = this.internalNewNodeWithParameters(
            type,
            annotation,
            rawPositionalParameters,
            rawNamedParams
        );
        node.body = body;
        node.child[1] = body;
        return node;
    }

    public newNodeWithParameters<
        T extends Exclude<NodeWithParametersType, NodeWithBodyType>
    >(
        type: T,
        annotation: AstAnnotation,
        rawPositionalParameters?: RawPositionalParameters,
        rawNamedParams?: NodeTypes[T]["rawNamedParams"]
    ) {
        return this.internalNewNodeWithParameters(
            type,
            annotation,
            rawPositionalParameters,
            rawNamedParams
        );
    }

    public newNodeWithChildren<
        T extends Exclude<NodeWithChildrenType, NodeWithParametersType>
    >(type: T, annotation: AstAnnotation) {
        return this.internalNewNodeWithChildren(type, annotation);
    }

    public NewNode<T extends Exclude<NodeType, NodeWithChildrenType>>(
        type: T,
        annotation: AstAnnotation
    ): NodeTypes[T] {
        return this.internalNewNode(type, annotation);
    }

    public NodeToString(node: AstNode) {
        let output = this.print_r(node);
        return concat(output, "\n");
    }
    public ReleaseAnnotation(annotation: AstAnnotation) {
        if (annotation.checkBoxList) {
            for (const [, control] of ipairs(annotation.checkBoxList)) {
                this.checkboxPool.Release(control);
            }
        }
        if (annotation.listList) {
            for (const [, control] of ipairs(annotation.listList)) {
                this.listPool.Release(control);
            }
        }
        if (annotation.objects) {
            for (const [, parameters] of ipairs(annotation.objects)) {
                this.objectPool.Release(parameters);
            }
        }
        if (annotation.rawPositionalParametersList) {
            for (const [, parameters] of ipairs(
                annotation.rawPositionalParametersList
            )) {
                this.rawPositionalParametersPool.Release(parameters);
            }
        }
        if (annotation.rawNamedParametersList) {
            for (const [, parameters] of ipairs(
                annotation.rawNamedParametersList
            )) {
                this.rawNamedParametersPool.Release(parameters);
            }
        }
        if (annotation.nodeList) {
            for (const [, node] of ipairs(annotation.nodeList)) {
                this.nodesPool.Release(node);
            }
        }
        for (const [, value] of kpairs(annotation)) {
            if (type(value) == "table") {
                wipe(value);
            }
        }
        wipe(annotation);
    }
    public Release(ast: AstNode) {
        ast.result.timeSpan.Release();
        wipe(ast.result);
        wipe(ast);
        this.nodesPool.Release(ast);
    }
    public ParseCode(
        nodeType: NodeType,
        code: string,
        nodeList: LuaArray<AstNode>,
        annotation: AstAnnotation
    ): [AstNode, LuaArray<AstNode>, AstAnnotation] | [] {
        let tokenStream = new OvaleLexer("Ovale", code, MATCHES, {
            comments: TokenizeComment,
            space: TokenizeWhitespace,
        });
        const node = this.Parse(nodeType, tokenStream, nodeList, annotation);
        tokenStream.Release();
        if (!node) return [];
        return [node, nodeList, annotation];
    }

    public parseScript(
        code: string,
        options?: { optimize: boolean; verify: boolean }
    ) {
        options = options || {
            optimize: true,
            verify: true,
        };
        const annotation: AstAnnotation = {
            nodeList: {},
            verify: options.verify,
            definition: {},
        };
        const [ast] = this.ParseCode(
            "script",
            code,
            annotation.nodeList,
            annotation
        );
        if (ast) {
            if (ast.type == "script") {
                ast.annotation = annotation;
                this.PropagateConstants(ast);
                this.PropagateStrings(ast);
                //    this.FlattenParameters(ast);
                //this.VerifyParameterStances(ast);
                this.VerifyFunctionCalls(ast);
                if (options.optimize) {
                    this.Optimize(ast);
                }
                this.InsertPostOrderTraversal(ast);
                return ast;
            }

            this.debug.Debug(`Unexpected type ${ast.type} in parseScript`);
            this.Release(ast);
        } else {
            this.debug.Error("Parse failed");
        }

        this.ReleaseAnnotation(annotation);
        return undefined;
    }

    public parseNamedScript(
        name: string,
        options?: { optimize: boolean; verify: boolean }
    ) {
        let code = this.ovaleScripts.GetScriptOrDefault(name);
        if (code) {
            return this.parseScript(code, options);
        } else {
            this.debug.Debug("No code to parse");
            return undefined;
        }
    }

    private getId(name: string, dictionary: LuaObj<string | number>) {
        let itemId = dictionary[name];
        if (itemId) {
            if (isNumber(itemId)) {
                return itemId;
            } else {
                this.debug.Error(`${name} is as string and not an item id`);
            }
        }
        return 0;
    }

    public PropagateConstants(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_PropagateConstants");
        if (ast.annotation) {
            let dictionary = ast.annotation.definition;
            if (dictionary && ast.annotation.nameReference) {
                for (const [, node] of ipairs<AstNode>(
                    ast.annotation.nameReference
                )) {
                    if (
                        (node.type == "item_info" ||
                            node.type == "itemrequire") &&
                        node.name
                    ) {
                        node.itemId = this.getId(node.name, dictionary);
                    } else if (
                        node.type == "spell_aura_list" ||
                        node.type == "spell_info" ||
                        node.type == "spell_require"
                    ) {
                        if (node.name)
                            node.spellId = this.getId(node.name, dictionary);
                        if (node.type === "spell_aura_list" && node.buffName)
                            node.buffSpellId = this.getId(
                                node.buffName,
                                dictionary
                            );
                    } else if (node.type === "variable") {
                        let name = node.name;
                        let value = dictionary[name];
                        if (value) {
                            if (isNumber(value)) {
                                const valueNode = (node as unknown) as AstValueNode;
                                valueNode.type = "value";
                                valueNode.name = name;
                                valueNode.value = value;
                                valueNode.origin = 0;
                                valueNode.rate = 0;
                            } else {
                                const valueNode = (node as unknown) as AstStringNode;
                                valueNode.type = "string";
                                valueNode.value = value;
                                valueNode.name = name;
                            }
                        }
                    }
                }
            }
        }
        this.profiler.StopProfiling("OvaleAST_PropagateConstants");
    }

    public PropagateStrings(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_PropagateStrings");
        if (ast.annotation && ast.annotation.stringReference) {
            for (const [, node] of ipairs(ast.annotation.stringReference)) {
                const nodeAsString = <AstStringNode>node;
                if (node.type === "string") {
                    let key = node.value;
                    let value = L[key];
                    if (key != value) {
                        nodeAsString.value = value;
                        nodeAsString.name = key;
                    }
                } else if (node.type === "variable") {
                    nodeAsString.type = "string";
                    const name = node.name;
                    nodeAsString.name = node.name;
                    nodeAsString.value = name;
                } else if (node.type === "value") {
                    let value = node.value;
                    nodeAsString.type = "string";
                    nodeAsString.name = tostring(node.value);
                    nodeAsString.value = tostring(value);
                } else if (node.type == "function") {
                    let key = node.rawPositionalParams[1];
                    let stringKey: string | undefined;
                    if (isAstNode(key)) {
                        if (key.type === "value") {
                            stringKey = tostring(key.value);
                        } else if (key.type === "variable") {
                            stringKey = key.name;
                        } else if (key.type === "string") {
                            stringKey = key.value;
                        } else {
                            stringKey = undefined;
                        }
                    } else {
                        stringKey = tostring(key);
                    }
                    if (stringKey) {
                        let value: string | undefined;
                        let name = node.name;
                        if (name == "itemname") {
                            [value] = GetItemInfo(stringKey);
                            if (!value) value = "item:" + stringKey;
                        } else if (name == "l") {
                            value = L[stringKey];
                        } else if (name == "spellname") {
                            value =
                                this.ovaleSpellBook.GetSpellName(
                                    tonumber(stringKey)
                                ) || "spell:" + stringKey;
                        }
                        if (value) {
                            nodeAsString.type = "string";
                            nodeAsString.value = value;
                            nodeAsString.func = node.name;
                            nodeAsString.name = stringKey;
                        }
                    }
                }
            }
        }
        this.profiler.StopProfiling("OvaleAST_PropagateStrings");
    }
    // public FlattenParameters(ast: AstNode) {
    //     this.profiler.StartProfiling("OvaleAST_FlattenParameters");
    //     let annotation = ast.annotation;
    //     if (annotation && annotation.parametersReference) {
    //         let dictionary = annotation.definition;
    //         for (const [, node] of ipairs<AstNode>(
    //             annotation.parametersReference
    //         )) {
    //             if (node.rawPositionalParams) {
    //                 let parameters = this.flattenParameterValuesPool.Get();
    //                 for (const [key, value] of ipairs(
    //                     node.rawPositionalParams
    //                 )) {
    //                     parameters[key] = this.FlattenParameterValue(
    //                         value,
    //                         annotation
    //                     );
    //                 }
    //                 node.positionalParams = parameters;
    //                 annotation.positionalParametersList =
    //                     annotation.positionalParametersList || {};
    //                 annotation.positionalParametersList[
    //                     lualength(annotation.positionalParametersList) + 1
    //                 ] = parameters;
    //             }
    //             if (node.rawNamedParams) {
    //                 const parameters: NamedParameters = this.objectPool.Get();
    //                 for (const [key] of kpairs(node.rawNamedParams)) {
    //                     if (key === "listitem") {
    //                         const control: LuaObj<string | number> =
    //                             parameters[key] || this.objectPool.Get();
    //                         const listItems = node.rawNamedParams[key];
    //                         for (const [list, item] of pairs(listItems)) {
    //                             control[
    //                                 list
    //                             ] = this.FlattenParameterValueNotCsv(
    //                                 item,
    //                                 annotation
    //                             );
    //                         }
    //                         if (!parameters[key]) {
    //                             parameters[key] = control;
    //                             annotation.objects = annotation.objects || {};
    //                             annotation.objects[
    //                                 lualength(annotation.objects) + 1
    //                             ] = control;
    //                         }
    //                     } else if (key === "checkbox") {
    //                         let control: LuaObj<number | string> =
    //                             parameters[key] || this.objectPool.Get();
    //                         const checkBoxItems = node.rawNamedParams[key];
    //                         for (const [i, name] of ipairs(checkBoxItems)) {
    //                             control[i] = this.FlattenParameterValueNotCsv(
    //                                 name,
    //                                 annotation
    //                             );
    //                         }
    //                         if (!parameters[key]) {
    //                             parameters[key] = control;
    //                             annotation.objects = annotation.objects || {};
    //                             annotation.objects[
    //                                 lualength(annotation.objects) + 1
    //                             ] = control;
    //                         }
    //                     } else {
    //                         const value = node.rawNamedParams[key]!; //TODO
    //                         const flattenValue = this.FlattenParameterValue(
    //                             value,
    //                             annotation
    //                         );
    //                         if (
    //                             type(key) != "number" &&
    //                             dictionary &&
    //                             dictionary[key]
    //                         ) {
    //                             parameters[
    //                                 dictionary[key] as keyof typeof parameters
    //                             ] = flattenValue as any;
    //                         } else {
    //                             // TODO delete named parameters that are not single values
    //                             (<any>parameters[key]) = flattenValue;
    //                         }
    //                     }
    //                 }
    //                 node.namedParams = parameters;
    //                 annotation.parametersList = annotation.parametersList || {};
    //                 annotation.parametersList[
    //                     lualength(annotation.parametersList) + 1
    //                 ] = parameters;
    //             }
    //             let output = this.outputPool.Get();
    //             for (const [k, v] of kpairs(node.namedParams)) {
    //                 if (isCheckBoxFlattenParameters(k, v)) {
    //                     for (const [, name] of ipairs(v)) {
    //                         output[lualength(output) + 1] = format(
    //                             "checkbox=%s",
    //                             name
    //                         );
    //                     }
    //                 } else if (isListItemFlattenParameters(k, v)) {
    //                     for (const [list, item] of ipairs(v)) {
    //                         output[lualength(output) + 1] = format(
    //                             "listitem=%s:%s",
    //                             list,
    //                             item
    //                         );
    //                     }
    //                 } else if (isLuaArray<SimpleValue>(v)) {
    //                     output[lualength(output) + 1] = format(
    //                         "%s=%s",
    //                         k,
    //                         concat(v, ",")
    //                     );
    //                 } else {
    //                     output[lualength(output) + 1] = format("%s=%s", k, v);
    //                 }
    //             }
    //             sort(output);
    //             for (
    //                 let k = lualength(node.positionalParams);
    //                 k >= 1;
    //                 k += -1
    //             ) {
    //                 insert(output, 1, node.positionalParams[k] as string); // TODO
    //             }
    //             if (lualength(output) > 0) {
    //                 node.paramsAsString = concat(output, " ");
    //             } else {
    //                 node.paramsAsString = "";
    //             }
    //             this.outputPool.Release(output);
    //         }
    //     }
    //     this.profiler.StopProfiling("OvaleAST_FlattenParameters");
    // }
    private VerifyFunctionCalls(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_VerifyFunctionCalls");
        if (ast.annotation && ast.annotation.verify) {
            let customFunction = ast.annotation.customFunction;
            let functionCall = ast.annotation.functionCall;
            if (functionCall) {
                for (const [name] of pairs(functionCall)) {
                    if (ACTION_PARAMETER_COUNT[name]) {
                    } else if (STRING_LOOKUP_FUNCTION[name]) {
                    } else if (this.ovaleCondition.IsCondition(name)) {
                    } else if (customFunction && customFunction[name]) {
                    } else {
                        this.debug.Error("unknown function '%s'.", name);
                    }
                }
            }
        }
        this.profiler.StopProfiling("OvaleAST_VerifyFunctionCalls");
    }

    private InsertPostOrderTraversal(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_InsertPostOrderTraversal");
        let annotation = ast.annotation;
        if (annotation && annotation.postOrderReference) {
            for (const [, node] of ipairs(annotation.postOrderReference)) {
                let array = this.postOrderPool.Get();
                let visited = this.postOrderVisitedPool.Get();
                this.PostOrderTraversal(node, array, visited);
                this.postOrderVisitedPool.Release(visited);
                node.postOrder = array;
            }
        }
        this.profiler.StopProfiling("OvaleAST_InsertPostOrderTraversal");
    }

    private Optimize(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_CommonSubExpressionElimination");
        if (ast && ast.annotation && ast.annotation.nodeList) {
            let expressionHash: LuaObj<AstNode> = {};

            // Index all nodes by their hash
            for (const [, node] of ipairs<AstNode>(ast.annotation.nodeList)) {
                const hash = node.asString;
                if (hash) {
                    expressionHash[hash] = expressionHash[hash] || node;
                }
            }

            // Replace childs with the first node that has the same hash
            for (const [, node] of ipairs(ast.annotation.nodeList)) {
                if (isAstNodeWithChildren(node)) {
                    for (const [i, childNode] of ipairs(node.child)) {
                        const hash = childNode.asString;
                        if (hash) {
                            const hashNode = expressionHash[hash];
                            if (hashNode) {
                                node.child[i] = hashNode;
                            } else {
                                expressionHash[hash] = childNode;
                            }
                        }
                    }
                }
            }

            ast.annotation.expressionHash = expressionHash;
        }
        this.profiler.StopProfiling("OvaleAST_CommonSubExpressionElimination");
    }
}
