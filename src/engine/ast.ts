import { l } from "../ui/Localization";
import { OvalePool } from "../tools/Pool";
import { OvaleProfilerClass, Profiler } from "./profiler";
import { DebugTools, Tracer } from "./debug";
import { Tokenizer, TokenizerDefinition } from "./lexer";
import {
    FunctionInfos,
    getFunctionSignature,
    OvaleConditionClass,
} from "./condition";
import { OvaleLexer, LexerFilter } from "./lexer";
import { OvaleScriptsClass } from "./scripts";
import { OvaleSpellBookClass } from "../states/SpellBook";
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
import { checkToken, isNumber, KeyCheck, TypeCheck } from "../tools/tools";
import { SpellInfoProperty, SpellInfoValues } from "./data";
import { Result } from "../simulationcraft/definitions";
import {
    emptySet,
    newTimeSpan,
    OvaleTimeSpan,
    universe,
} from "../tools/TimeSpan";
import { ActionType } from "./best-action";
import { PowerType } from "../states/Power";
import { LocalizationStrings } from "../ui/localization/definition";

const keywords: LuaObj<boolean> = {
    ["and"]: true,
    ["if"]: true,
    ["not"]: true,
    ["or"]: true,
    ["unless"]: true,
    ["true"]: true,
    ["false"]: true,
};

const declarationKeywords: LuaObj<boolean> = {
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

const spellAuraKewords: KeyCheck<SpellAuraKeyWord> = {
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
    half_duration: true,
    haste: true,
    health: true,
    holypower: true,
    icd: true,
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
    rppm: true,
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
    max_alternate: true,
    max_arcanecharges: true,
    max_chi: true,
    max_combopoints: true,
    max_energy: true,
    max_focus: true,
    max_fury: true,
    max_holypower: true,
    max_insanity: true,
    max_lunarpower: true,
    max_maelstrom: true,
    max_mana: true,
    max_pain: true,
    max_rage: true,
    max_runicpower: true,
    max_soulshards: true,
    refund_alternate: true,
    refund_arcanecharges: true,
    refund_chi: true,
    refund_combopoints: true,
    refund_energy: true,
    refund_focus: true,
    refund_fury: true,
    refund_holypower: true,
    refund_insanity: true,
    refund_lunarpower: true,
    refund_maelstrom: true,
    refund_mana: true,
    refund_pain: true,
    refund_rage: true,
    refund_runicpower: true,
    refund_soulshards: true,
    set_alternate: true,
    set_arcanecharges: true,
    set_chi: true,
    set_combopoints: true,
    set_energy: true,
    set_focus: true,
    set_fury: true,
    set_holypower: true,
    set_insanity: true,
    set_lunarpower: true,
    set_maelstrom: true,
    set_mana: true,
    set_pain: true,
    set_rage: true,
    set_runicpower: true,
    set_soulshards: true,
};

{
    for (const [keyword, value] of pairs(spellAuraKewords)) {
        declarationKeywords[keyword] = value;
    }
    for (const [keyword, value] of pairs(declarationKeywords)) {
        keywords[keyword] = value;
    }
}

const checkActionType: KeyCheck<ActionType> = {
    item: true,
    macro: true,
    setstate: true,
    spell: true,
    texture: true,
    value: true,
};

const actionParameterCounts: Record<ActionType, number> = {
    ["item"]: 1,
    ["macro"]: 1,
    ["spell"]: 1,
    ["texture"]: 1,
    ["setstate"]: 2,
    value: 1,
};
const stateActions: LuaObj<boolean> = {
    ["setstate"]: true,
};
const stringLookupFunctions: LuaObj<boolean> = {
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

const unaryOperators: {
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
const binaryOperators: {
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
function indentation(key: number) {
    let ret = indent[key];
    if (ret == undefined) {
        ret = `${indentation(key - 1)} `;
        indent[key] = ret;
    }
    return ret;
}

export interface AstAnnotation {
    checkBoxList?: LuaArray<CheckboxParameters>;
    listList?: LuaArray<ListParameters>;
    positionalParametersList?: LuaArray<PositionalParameters>;
    rawPositionalParametersList?: LuaArray<RawPositionalParameters>;
    flattenParametersList?: LuaArray<NamedParameters<string>>;
    rawNamedParametersList?: LuaArray<RawNamedParameters<string>>;
    nodeList: LuaArray<AstNode>;
    parametersReference?: LuaArray<AstNode>;
    postOrderReference?: LuaArray<AstGroupNode>;
    customFunction?: LuaObj<AstAddFunctionNode>;
    stringReference?: LuaArray<AstNode>;
    functionCall?: LuaObj<boolean>;
    spellNode?: LuaArray<AstNode>;
    nameReference?: LuaArray<AstNode>;
    definition: LuaObj<number | string>;
    numberFlyweight?: LuaObj<AstValueNode>;
    verify?: boolean;
    functionHash?: LuaObj<AstNode>;
    expressionHash?: LuaObj<AstNode>;
    parametersList?: LuaArray<NamedParameters<string>>;
    sync?: LuaObj<AstNode>;
}

export interface NodeTypes {
    action: AstActionNode;
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
    typed_function: AstTypedFunctionNode;
    undefined: AstUndefinedNode;
    unless: AstUnlessNode;
    value: AstValueNode;
    variable: AstVariableNode;
}

export type NodeType = keyof NodeTypes;
type NodeWithParametersType = {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    [k in NodeType]: NodeTypes[k] extends AstNodeWithParameters<any, any>
        ? k
        : never;
}[NodeType];
type NodeWithChildrenType = {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    [k in NodeType]: NodeTypes[k] extends AstBaseNodeWithChildren<any>
        ? k
        : never;
}[NodeType];
type NodeWithBodyType = {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    [k in NodeType]: NodeTypes[k] extends { body: any } ? k : never;
}[NodeType];
interface BaseNodeValue {
    /**
     * The serial is used to know if the value has already
     * been computed this frame. It is a positive value
     * or -1 if it's currently computed, or 0 it it was never computed
     */
    serial: number;
    constant?: boolean;

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
    actionSlot?: number;
    actionEnable?: boolean;
    actionType?: ActionType;
    actionId?: string | number;
    actionTarget?: string;
    actionResourceExtend?: number;
    actionCharges?: number;
    castTime?: number;
    offgcd?: boolean;
    options?: NamedParametersOf<AstActionNode>;
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

export type AllAstNodeSnapshot = NodeStateResult &
    NodeValueResult &
    NodeActionResult &
    NodeNoResult;

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
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
): node is AstBaseNodeWithChildren<any> {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return (node as any).child !== undefined;
}

export interface AstNodeWithParameters<T extends NodeType, P extends string>
    extends AstBaseNodeWithChildren<T> {
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
    | AstActionNode
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
    | AstTypedFunctionNode
    | AstUndefinedNode
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

export interface AstBooleanNode extends AstBaseNode<"boolean"> {
    value: boolean;
}

export type AstSimcWaitnode = AstBaseNodeWithChildren<"simc_wait">;

export type AstActionListNode = AstBaseNode<"action_list">;

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
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
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

export type AstScriptNode = AstBaseNodeWithChildren<"script">;

export type AstScoreSpellsNode = AstNodeWithParameters<
    "score_spells",
    "enabled"
>;

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

export type AstGroupNode = AstBaseNodeWithChildren<"group">;

export interface AstIfNode extends AstBaseNodeWithChildren<"if"> {
    // TODO Should be moved to annotations instead (used by simc emiter)
    simc_pool_resource?: boolean;
    simc_wait?: boolean;
}

export interface AstIconNode
    extends AstNodeWithParameters<
        "icon",
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

export type AstBangValueNode = AstBaseNodeWithChildren<"bang_value">;

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
        "state" | "function" | "custom_function",
        | "target"
        | "filter"
        | "excludeTarget"
        | "stacks"
        | "haste"
        | "tagged"
        | "name"
        | "max"
        | "count"
        | "unlimited"
        | "usable"
        | "any"
        | "value"
    > {
    name: string;
}

const checkFunctionParameters: NamedParametersCheck<AstFunctionNode> = {
    filter: true,
    target: true,
    count: true,
    excludeTarget: true,
    haste: true,
    max: true,
    name: true,
    stacks: true,
    tagged: true,
    unlimited: true,
    usable: true,
    any: true,
    value: true,
};

export interface AstActionNode
    extends AstNodeWithParameters<
        "action",
        | "wait"
        | "text"
        | "sound"
        | "soundtime"
        | "nored"
        | "help"
        | "pool_resource"
        | "flash"
        | "usable"
        | "target"
        | "offgcd"
        | "extra_energy"
        | "extra_focus"
        | "texture"
    > {
    name: ActionType;
}

const checkActionParameters: NamedParametersCheck<AstActionNode> = {
    flash: true,
    help: true,
    nored: true,
    pool_resource: true,
    sound: true,
    soundtime: true,
    text: true,
    wait: true,
    target: true,
    usable: true,
    offgcd: true,
    extra_energy: true,
    extra_focus: true,
    texture: true,
};

export interface AstTypedFunctionNode
    extends AstNodeWithParameters<"typed_function", string> {
    name: string;
}

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

type AstUndefinedNode = AstBaseNode<"undefined">;

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

const tokenizeComment: Tokenizer = function (token) {
    return ["comment", token];
};

// const TokenizeLua:Tokenizer = function(token) {
//     token = strsub(token, 3, -3);
//     return ["lua", token];
// }

const tokenizeName: Tokenizer = function (token) {
    token = lower(token);
    if (keywords[token]) {
        return ["keyword", token];
    } else {
        return ["name", token];
    }
};

const tokenizeNumber: Tokenizer = function (token) {
    return ["number", token];
};

const tokenizeString: Tokenizer = function (token) {
    token = sub(token, 2, -2);
    return ["string", token];
};
const tokenizeWhitespace: Tokenizer = function (token) {
    return ["space", token];
};

const tokenize: Tokenizer = function (token) {
    return [token, token];
};
const noToken: Tokenizer = function () {
    return [undefined, undefined];
};

const tokenMatches: LuaArray<TokenizerDefinition> = {
    1: {
        1: "^%s+",
        2: tokenizeWhitespace,
    },
    2: {
        1: "^%d+%.?%d*",
        2: tokenizeNumber,
    },
    3: {
        1: "^[%a_][%w_]*",
        2: tokenizeName,
    },
    4: {
        1: "^((['\"])%2)",
        2: tokenizeString,
    },
    5: {
        1: `^(['"]).-\\%1`,
        2: tokenizeString,
    },
    6: {
        1: `^(['\\"]).-[^\\]%1`,
        2: tokenizeString,
    },
    7: {
        1: "^#.-\n",
        2: tokenizeComment,
    },
    8: {
        1: "^!=",
        2: tokenize,
    },
    9: {
        1: "^==",
        2: tokenize,
    },
    10: {
        1: "^<=",
        2: tokenize,
    },
    11: {
        1: "^>=",
        2: tokenize,
    },
    12: {
        1: "^>%?",
        2: tokenize,
    },
    13: {
        1: "^<%?",
        2: tokenize,
    },
    14: {
        1: "^.",
        2: tokenize,
    },
    15: {
        1: "^$",
        2: noToken,
    },
};

const lexerFilters: LexerFilter = {
    comments: tokenizeComment,
    space: tokenizeWhitespace,
};

class SelfPool extends OvalePool<AstNode> {
    constructor(private ovaleAst: OvaleASTClass) {
        super("OvaleAST_pool");
    }

    clean(node: AstNode): void {
        if (isAstNodeWithChildren(node)) {
            this.ovaleAst.childrenPool.release(node.child);
        }
        if (node.postOrder) {
            this.ovaleAst.postOrderPool.release(node.postOrder);
        }
        wipe(node);
    }
}

type CheckboxParameters = LuaArray<AstNode>;
type ListParameters = LuaObj<AstNode>;

export type NamedParameters<K extends string> = {
    [key in K]?: FlattenParameterValue;
};

export type NamedParametersOf<
    K extends AstNodeWithParameters<NodeType, string>
> = K["cachedParams"]["named"];

type FlattenParameterValue = string | number | boolean | undefined;
export type PositionalParameters = LuaArray<FlattenParameterValue>;

export type RawNamedParameters<K extends string> = {
    [key in K]?: AstNode;
};

export type RawPositionalParameters = LuaArray<AstNode>;

type ParserFunction<T = AstNode> = (
    tokenStream: OvaleLexer,
    annotation: AstAnnotation,
    minPrecedence?: number
) => T | undefined;
type UnparserFunction<T extends AstNode = AstNode> = (node: T) => string;

function isAstNode(a: unknown): a is AstNode {
    return type(a) === "table";
}

export class OvaleASTClass {
    private indent = 0;
    private outputPool = new OvalePool<LuaArray<string>>("OvaleAST_outputPool");
    private listPool = new OvalePool<ListParameters>("OvaleAST_listPool");
    private checkboxPool = new OvalePool<CheckboxParameters>(
        "OvaleAST_checkboxPool"
    );
    private positionalParametersPool = new OvalePool<PositionalParameters>(
        "OvaleAST_FlattenParameterValues"
    );
    private rawNamedParametersPool = new OvalePool<RawNamedParameters<string>>(
        "OvaleAST_rawNamedParametersPool"
    );
    private rawPositionalParametersPool = new OvalePool<RawPositionalParameters>(
        "OVALEAST_rawPositionParametersPool"
    );
    private namedParametersPool = new OvalePool<NamedParameters<string>>(
        "OvaleAST_FlattenParametersPool"
    );
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
        ovaleDebug: DebugTools,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleScripts: OvaleScriptsClass,
        private ovaleSpellBook: OvaleSpellBookClass
    ) {
        this.debug = ovaleDebug.create("OvaleAST");
        this.profiler = ovaleProfiler.create("OvaleAST");
    }

    private printRecurse(
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
                    this.printRecurse(value, `${indent}    `, done, output);
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

    private getNumberNode(value: number, annotation: AstAnnotation) {
        annotation.numberFlyweight = annotation.numberFlyweight || {};
        let node = annotation.numberFlyweight[value];
        if (!node) {
            node = this.newValue(annotation, value);
            annotation.numberFlyweight[value] = node;
        }
        return node;
    }

    private postOrderTraversal(
        node: AstNode,
        array: LuaArray<AstNode>,
        visited: LuaObj<boolean>
    ) {
        if (isAstNodeWithChildren(node)) {
            for (const [, childNode] of ipairs(node.child)) {
                if (!visited[childNode.nodeId]) {
                    this.postOrderTraversal(childNode, array, visited);
                    array[lualength(array) + 1] = node;
                }
            }
        }
        array[lualength(array) + 1] = node;
        visited[node.nodeId] = true;
    }

    private getPrecedence(node: AstNode) {
        if (isExpressionNode(node)) {
            let precedence = node.precedence;
            if (!precedence) {
                const operator = node.operator;
                if (operator) {
                    if (node.expressionType == "unary") {
                        const operatorInfos = unaryOperators[operator];
                        if (operatorInfos) precedence = operatorInfos[2];
                    } else if (node.expressionType == "binary") {
                        const operatorInfos = binaryOperators[operator];
                        if (operatorInfos) precedence = operatorInfos[2];
                    }
                }
            }
            return precedence;
        }
        return 0;
    }

    private hasParameters<T extends NodeType, P extends string>(
        node: AstNodeWithParameters<T, P>
    ) {
        return next(node.rawPositionalParams) || next(node.rawNamedParams);
    }

    public unparse(node: AstNode) {
        if (node.asString) {
            return node.asString;
        } else {
            const visitor = this.unparseVisitors[node.type] as UnparserFunction<
                NodeTypes[typeof node.type]
            >;

            if (!visitor) {
                this.debug.error(
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

    private unparseAddCheckBox: UnparserFunction<AstCheckBoxNode> = (node) => {
        let s;
        if (
            (node.rawPositionalParams && next(node.rawPositionalParams)) ||
            (node.rawNamedParams && next(node.rawNamedParams))
        ) {
            s = format(
                "AddCheckBox(%s %s %s)",
                node.name,
                this.unparse(node.description),
                this.unparseParameters(
                    node.rawPositionalParams,
                    node.rawNamedParams
                )
            );
        } else {
            s = format(
                "AddCheckBox(%s %s)",
                node.name,
                this.unparse(node.description)
            );
        }
        return s;
    };
    private unparseAddFunction: UnparserFunction<AstAddFunctionNode> = (
        node
    ) => {
        let s;
        if (this.hasParameters(node)) {
            s = format(
                "AddFunction %s %s%s",
                node.name,
                this.unparseParameters(
                    node.rawPositionalParams,
                    node.rawNamedParams
                ),
                this.unparseGroup(node.body)
            );
        } else {
            s = format(
                "AddFunction %s%s",
                node.name,
                this.unparseGroup(node.body)
            );
        }
        return s;
    };
    private unparseAddIcon: UnparserFunction<AstIconNode> = (node) => {
        let s;
        if (this.hasParameters(node)) {
            s = format(
                "AddIcon %s%s",
                this.unparseParameters(
                    node.rawPositionalParams,
                    node.rawNamedParams
                ),
                this.unparseGroup(node.body)
            );
        } else {
            s = format("AddIcon%s", this.unparseGroup(node.body));
        }
        return s;
    };
    private unparseAddListItem: UnparserFunction<AstListItemNode> = (node) => {
        let s;
        if (this.hasParameters(node)) {
            s = format(
                "AddListItem(%s %s %s %s)",
                node.name,
                node.item,
                this.unparse(node.description),
                this.unparseParameters(
                    node.rawPositionalParams,
                    node.rawNamedParams
                )
            );
        } else {
            s = format(
                "AddListItem(%s %s %s)",
                node.name,
                node.item,
                this.unparse(node.description)
            );
        }
        return s;
    };
    private unparseBangValue: UnparserFunction<AstBangValueNode> = (node) => {
        return `!${this.unparse(node.child[1])}`;
    };
    private unparseBoolean: UnparserFunction<AstBooleanNode> = (node) => {
        return (node.value && "true") || "false";
    };
    private unparseComment: UnparserFunction<AstCommentNode> = (node) => {
        if (!node.comment || node.comment == "") {
            return "";
        } else {
            return `#${node.comment}`;
        }
    };
    private unparseDefine: UnparserFunction<AstDefineNode> = (node) => {
        return format("Define(%s %s)", node.name, node.value);
    };
    private unparseExpression: UnparserFunction<AstExpressionNode> = (node) => {
        let expression;
        const precedence = this.getPrecedence(node);
        if (node.expressionType == "unary") {
            let rhsExpression;
            const rhsNode = node.child[1];
            const rhsPrecedence = this.getPrecedence(rhsNode);
            if (rhsPrecedence && precedence >= rhsPrecedence) {
                rhsExpression = `{ ${this.unparse(rhsNode)} }`;
            } else {
                rhsExpression = this.unparse(rhsNode);
            }
            if (node.operator == "-") {
                expression = `-${rhsExpression}`;
            } else {
                expression = `${node.operator} ${rhsExpression}`;
            }
        } else if (node.expressionType == "binary") {
            let lhsExpression, rhsExpression;
            const lhsNode = node.child[1];
            const lhsPrecedence = this.getPrecedence(lhsNode);
            if (lhsPrecedence && lhsPrecedence < precedence) {
                lhsExpression = `{ ${this.unparse(lhsNode)} }`;
            } else {
                lhsExpression = this.unparse(lhsNode);
            }
            const rhsNode = node.child[2];
            const rhsPrecedence = this.getPrecedence(rhsNode);
            if (rhsPrecedence && precedence > rhsPrecedence) {
                rhsExpression = `{ ${this.unparse(rhsNode)} }`;
            } else if (rhsPrecedence && precedence == rhsPrecedence) {
                const operatorInfo = binaryOperators[node.operator];
                if (
                    operatorInfo &&
                    operatorInfo[3] == "associative" &&
                    rhsNode.type === "expression" &&
                    node.operator == rhsNode.operator
                ) {
                    rhsExpression = this.unparse(rhsNode);
                } else {
                    rhsExpression = `{ ${this.unparse(rhsNode)} }`;
                }
            } else {
                rhsExpression = this.unparse(rhsNode);
            }
            expression = `${lhsExpression} ${node.operator} ${rhsExpression}`;
        } else {
            this.debug.error(
                `node.expressionType '${node.expressionType}' is not known`
            );
            return "Not_Unparsable";
        }
        return expression;
    };

    private unparseAction: UnparserFunction<AstActionNode> = (node) => {
        return format(
            "%s(%s)",
            node.name,
            this.unparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams,
                true
            )
        );
    };

    private unparseFunction: UnparserFunction<AstFunctionNode> = (node) => {
        let s;
        if (this.hasParameters(node)) {
            let name;
            const filter = node.rawNamedParams.filter;
            if (filter && this.unparse(filter) == "debuff") {
                name = gsub(node.name, "^Buff", "Debuff");
            } else {
                name = node.name;
            }
            const target = node.rawNamedParams.target;
            if (target && target.type === "string") {
                s = format(
                    "%s.%s(%s)",
                    target.value,
                    name,
                    this.unparseParameters(
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
                    this.unparseParameters(
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

    private unparseUndefined: UnparserFunction<AstUndefinedNode> = () => {
        return "undefined";
    };

    private unparseTypedFunction: UnparserFunction<AstTypedFunctionNode> = (
        node
    ) => {
        let s;
        if (this.hasParameters(node)) {
            s = node.name + "(";
            if (
                node.rawNamedParams.target &&
                node.rawNamedParams.target.type === "string"
            )
                s = node.rawNamedParams.target.value + "." + s;
            const infos = this.ovaleCondition.getInfos(node.name);
            if (infos) {
                let nameParameters = false;
                let first = true;
                for (const [k, v] of ipairs(infos.parameters)) {
                    const value = node.rawPositionalParams[k];
                    if (value && value.type !== "undefined") {
                        if (
                            v.name === "filter" ||
                            v.name === "target" ||
                            (v.defaultValue !== undefined &&
                                ((v.type === "boolean" &&
                                    value.type === "boolean" &&
                                    value.value === v.defaultValue) ||
                                    (v.type === "number" &&
                                        value.type === "value" &&
                                        value.value === v.defaultValue) ||
                                    (v.type === "string" &&
                                        value.type === "string" &&
                                        value.value === v.defaultValue)))
                        ) {
                            nameParameters = true;
                        } else {
                            if (first) first = false;
                            else s += " ";
                            if (nameParameters) s += v.name + "=";
                            s += this.unparseParameter(value);
                        }
                    } else {
                        nameParameters = true;
                    }
                }
            }
            s += ")";
        } else {
            s = format("%s()", node.name);
        }
        return s;
    };
    private unparseGroup: UnparserFunction<AstGroupNode> = (node) => {
        const output = this.outputPool.get();
        output[lualength(output) + 1] = "";
        output[lualength(output) + 1] = `${indentation(this.indent)}{`;
        this.indent = this.indent + 1;
        for (const [, statementNode] of ipairs(node.child)) {
            const s = this.unparse(statementNode);
            if (s == "") {
                output[lualength(output) + 1] = s;
            } else {
                output[lualength(output) + 1] = `${indentation(
                    this.indent
                )}${s}`;
            }
        }
        this.indent = this.indent - 1;
        output[lualength(output) + 1] = `${indentation(this.indent)}}`;
        const outputString = concat(output, "\n");
        this.outputPool.release(output);
        return outputString;
    };
    private unparseIf: UnparserFunction<AstIfNode> = (node) => {
        if (node.child[2].type == "group") {
            return format(
                "if %s%s",
                this.unparse(node.child[1]),
                this.unparseGroup(node.child[2])
            );
        } else {
            return format(
                "if %s %s",
                this.unparse(node.child[1]),
                this.unparse(node.child[2])
            );
        }
    };
    private unparseItemInfo: UnparserFunction<AstItemInfoNode> = (node) => {
        const identifier = (node.name && node.name) || node.itemId;
        return format(
            "ItemInfo(%s %s)",
            identifier,
            this.unparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private unparseItemRequire: UnparserFunction<AstItemRequireNode> = (
        node
    ) => {
        const identifier = (node.name && node.name) || node.itemId;
        return format(
            "ItemRequire(%s %s %s)",
            identifier,
            node.property,
            this.unparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private unparseList: UnparserFunction<AstListNode> = (node) => {
        return format(
            "%s(%s %s)",
            node.keyword,
            node.name,
            this.unparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private unparseValue = (node: AstValueNode) => {
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
            return this.unparse(node);
        } else {
            return `(${this.unparse(node)})`;
        }
    }

    private unparseParameters(
        positionalParams: RawPositionalParameters,
        namedParams?: RawNamedParameters<string>,
        noFilter?: boolean,
        noTarget?: boolean
    ) {
        const output = this.outputPool.get();
        if (namedParams) {
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
        }

        sort(output);
        for (let k = lualength(positionalParams); k >= 1; k += -1) {
            insert(output, 1, this.unparseParameter(positionalParams[k]));
        }
        const outputString = concat(output, " ");
        this.outputPool.release(output);
        return outputString;
    }
    private unparseScoreSpells: UnparserFunction<AstScoreSpellsNode> = (
        node
    ) => {
        return format(
            "ScoreSpells(%s)",
            this.unparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private unparseScript: UnparserFunction<AstScriptNode> = (node) => {
        const output = this.outputPool.get();
        let previousDeclarationType;
        for (const [, declarationNode] of ipairs(node.child)) {
            if (
                declarationNode.type == "item_info" ||
                declarationNode.type == "spell_aura_list" ||
                declarationNode.type == "spell_info" ||
                declarationNode.type == "spell_require"
            ) {
                const s = this.unparse(declarationNode);
                if (s == "") {
                    output[lualength(output) + 1] = s;
                } else {
                    output[lualength(output) + 1] = `${indentation(
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
                output[lualength(output) + 1] = this.unparse(declarationNode);
                previousDeclarationType = declarationNode.type;
            }
        }
        const outputString = concat(output, "\n");
        this.outputPool.release(output);
        return outputString;
    };
    private unparseSpellAuraList: UnparserFunction<AstSpellAuraListNode> = (
        node
    ) => {
        const identifier = node.name || node.spellId;
        const buffName = node.buffName || node.buffSpellId;
        return format(
            "%s(%s %s %s)",
            node.keyword,
            identifier,
            buffName,
            this.unparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private unparseSpellInfo: UnparserFunction<AstSpellInfoNode> = (node) => {
        const identifier = (node.name && node.name) || node.spellId;
        return format(
            "SpellInfo(%s %s)",
            identifier,
            this.unparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private unparseSpellRequire: UnparserFunction<AstSpellRequireNode> = (
        node
    ) => {
        const identifier = (node.name && node.name) || node.spellId;
        return format(
            "SpellRequire(%s %s %s)",
            identifier,
            node.property,
            this.unparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams
            )
        );
    };
    private unparseString = (node: AstStringNode) => {
        if (node.name) {
            if (node.func) return `${node.func}(${node.name})`;
            return node.name;
        }
        return `"${node.value}"`;
    };
    private unparseUnless: UnparserFunction<AstUnlessNode> = (node) => {
        if (node.child[2].type == "group") {
            return format(
                "unless %s%s",
                this.unparse(node.child[1]),
                this.unparseGroup(node.child[2])
            );
        } else {
            return format(
                "unless %s %s",
                this.unparse(node.child[1]),
                this.unparse(node.child[2])
            );
        }
    };
    private unparseVariable: UnparserFunction<AstVariableNode> = (node) => {
        return node.name;
    };

    private unparseVisitors: {
        [key in keyof NodeTypes]?: UnparserFunction<NodeTypes[key]>;
    } = {
        ["action"]: this.unparseAction,
        ["add_function"]: this.unparseAddFunction,
        ["arithmetic"]: this.unparseExpression,
        ["bang_value"]: this.unparseBangValue,
        ["boolean"]: this.unparseBoolean,
        ["checkbox"]: this.unparseAddCheckBox,
        ["compare"]: this.unparseExpression,
        ["comment"]: this.unparseComment,
        ["custom_function"]: this.unparseFunction,
        ["define"]: this.unparseDefine,
        ["function"]: this.unparseFunction,
        ["group"]: this.unparseGroup,
        ["icon"]: this.unparseAddIcon,
        ["if"]: this.unparseIf,
        ["item_info"]: this.unparseItemInfo,
        ["itemrequire"]: this.unparseItemRequire,
        ["list"]: this.unparseList,
        ["list_item"]: this.unparseAddListItem,
        ["logical"]: this.unparseExpression,
        ["score_spells"]: this.unparseScoreSpells,
        ["script"]: this.unparseScript,
        ["spell_aura_list"]: this.unparseSpellAuraList,
        ["spell_info"]: this.unparseSpellInfo,
        ["spell_require"]: this.unparseSpellRequire,
        ["state"]: this.unparseFunction,
        ["string"]: this.unparseString,
        ["typed_function"]: this.unparseTypedFunction,
        ["undefined"]: this.unparseUndefined,
        ["unless"]: this.unparseUnless,
        ["value"]: this.unparseValue,
        ["variable"]: this.unparseVariable,
    };

    private syntaxError(
        tokenStream: OvaleLexer,
        pattern: string,
        ...parameters: unknown[]
    ) {
        this.debug.warning(pattern, ...parameters);
        const context: LuaArray<string> = {
            1: "Next tokens:",
        };
        for (let i = 1; i <= 20; i += 1) {
            const [tokenType, token] = tokenStream.peek(i);
            if (tokenType && token) {
                context[lualength(context) + 1] = token;
            } else {
                context[lualength(context) + 1] = "<EOS>";
                break;
            }
        }
        this.debug.warning(concat(context, " "));
    }

    private parse(
        nodeType: NodeType,
        tokenStream: OvaleLexer,
        nodeList: LuaArray<AstNode>,
        annotation: AstAnnotation
    ): Result<AstNode> {
        const visitor = this.parseVisitors[nodeType];
        this.debug.debug(`Visit ${nodeType}`);
        if (!visitor) {
            this.debug.error("Unable to parse node of type '%s'.", nodeType);
            return undefined;
        } else {
            const result = visitor(tokenStream, annotation);
            if (!result) {
                this.debug.error(`Failed in %s visitor`, nodeType);
            }
            return result;
        }
    }
    private parseAddCheckBox: ParserFunction<AstCheckBoxNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.consume();
        if (!(tokenType == "keyword" && token == "addcheckbox")) {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; 'AddCheckBox' expected.",
                token
            );
            return undefined;
        }

        [tokenType, token] = tokenStream.consume();
        if (tokenType != "(") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; '(' expected.",
                token
            );
            return undefined;
        }

        let name = "";
        [tokenType, token] = tokenStream.consume();
        if (tokenType == "name" && token !== undefined) {
            name = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; name expected.",
                token
            );
            return undefined;
        }
        const descriptionNode = this.parseString(tokenStream, annotation);
        if (!descriptionNode) return undefined;

        const [positionalParams, namedParams] = this.parseParameters(
            tokenStream,
            "ParseAddCheckBox",
            annotation,
            1,
            checkCheckBoxParameters
        );
        if (!positionalParams || !namedParams) return undefined;

        [tokenType, token] = tokenStream.consume();
        if (tokenType != ")") {
            this.syntaxError(
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
    private parseAddFunction: ParserFunction<AstAddFunctionNode> = (
        tokenStream,

        annotation
    ) => {
        let [tokenType, token] = tokenStream.consume();
        if (!(tokenType == "keyword" && token == "addfunction")) {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; 'AddFunction' expected.",
                token
            );
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.consume();
        if (tokenType == "name" && token) {
            name = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; name expected.",
                token
            );
            return undefined;
        }
        const [positionalParams, namedParams] = this.parseParameters(
            tokenStream,
            "ParseAddFunction",
            annotation,
            0,
            checkAddFunctionParameters
        );
        if (!positionalParams || !namedParams) return undefined;
        const bodyNode = this.innerParseGroup(tokenStream, annotation);
        if (!bodyNode) return undefined;
        const node = this.newNodeWithBodyAndParameters(
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
    private parseAddIcon: ParserFunction<AstIconNode> = (
        tokenStream,
        annotation
    ) => {
        const [tokenType, token] = tokenStream.consume();
        if (!(tokenType == "keyword" && token == "addicon")) {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDICON; 'AddIcon' expected.",
                token
            );
            return undefined;
        }
        const [positionalParams, namedParams] = this.parseParameters(
            tokenStream,
            "addicon",
            annotation,
            0,
            iconParametersCheck
        );
        if (!positionalParams || !namedParams) return undefined;
        const bodyNode = this.innerParseGroup(tokenStream, annotation);
        if (!bodyNode) return undefined;
        const node = this.newNodeWithBodyAndParameters(
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
    private parseAddListItem: ParserFunction<AstListItemNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.consume();
        if (!(tokenType == "keyword" && token == "addlistitem")) {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; 'AddListItem' expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.consume();
        if (tokenType != "(") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; '(' expected.",
                token
            );
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.consume();
        if (tokenType == "name" && token) {
            name = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.",
                token
            );
            return undefined;
        }

        let item;
        [tokenType, token] = tokenStream.consume();
        if (tokenType == "name" && token) {
            item = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.",
                token
            );
            return undefined;
        }
        const descriptionNode = this.parseString(tokenStream, annotation);
        if (!descriptionNode) return undefined;

        const [positionalParams, namedParams] = this.parseParameters(
            tokenStream,
            "ParseAddListItem",
            annotation,
            1,
            checkListItemParameters
        );
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.consume();
        if (tokenType != ")") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; ')' expected.",
                token
            );
            return undefined;
        }
        const node = this.newNodeWithParameters(
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
    private parseComment: ParserFunction<AstCommentNode> = () => {
        return undefined;
    };
    private parseDeclaration: ParserFunction = (
        tokenStream,
        annotation
    ): AstNode | undefined => {
        let node: AstNode | undefined;
        const [tokenType, token] = tokenStream.peek();
        if (tokenType == "keyword" && token && declarationKeywords[token]) {
            if (token == "addcheckbox") {
                node = this.parseAddCheckBox(tokenStream, annotation);
            } else if (token == "addfunction") {
                node = this.parseAddFunction(tokenStream, annotation);
            } else if (token == "addicon") {
                node = this.parseAddIcon(tokenStream, annotation);
            } else if (token == "addlistitem") {
                node = this.parseAddListItem(tokenStream, annotation);
            } else if (token == "define") {
                node = this.parseDefine(tokenStream, annotation);
            } else if (token == "include") {
                node = this.parseInclude(tokenStream, annotation);
            } else if (token == "iteminfo") {
                node = this.parseItemInfo(tokenStream, annotation);
            } else if (token == "itemrequire") {
                node = this.parseItemRequire(tokenStream, annotation);
            } else if (token == "itemlist") {
                node = this.parseList(tokenStream, annotation);
            } else if (token == "scorespells") {
                node = this.parseScoreSpells(tokenStream, annotation);
            } else if (checkToken(spellAuraKewords, token)) {
                node = this.parseSpellAuraList(tokenStream, annotation);
            } else if (token == "spellinfo") {
                node = this.parseSpellInfo(tokenStream, annotation);
            } else if (token == "spelllist") {
                node = this.parseList(tokenStream, annotation);
            } else if (token == "spellrequire") {
                node = this.parseSpellRequire(tokenStream, annotation);
            } else {
                this.syntaxError(
                    tokenStream,
                    "Syntax error: unknown keywork '%s'",
                    token
                );
                return;
            }
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing DECLARATION; declaration keyword expected.",
                token
            );
            tokenStream.consume();
            return undefined;
        }
        return node;
    };
    private parseDefine: ParserFunction<AstDefineNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.consume();
        if (!(tokenType == "keyword" && token == "define")) {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing DEFINE; 'Define' expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.consume();
        if (tokenType != "(") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing DEFINE; '(' expected.",
                token
            );
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.consume();
        if (tokenType == "name" && token) {
            name = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing DEFINE; name expected.",
                token
            );
            return undefined;
        }
        let value: string | number;
        [tokenType, token] = tokenStream.consume();
        if (tokenType == "-") {
            [tokenType, token] = tokenStream.consume();
            if (tokenType == "number") {
                value = -1 * tonumber(token);
            } else {
                this.syntaxError(
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
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing DEFINE; number or string expected.",
                token
            );
            return undefined;
        }

        [tokenType, token] = tokenStream.consume();
        if (tokenType != ")") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing DEFINE; ')' expected.",
                token
            );
            return undefined;
        }
        const node = this.newNode("define", annotation);
        node.name = name;
        node.value = value;
        annotation.definition = annotation.definition || {};
        annotation.definition[name] = value;
        return node;
    };
    private parseExpression: ParserFunction<AstNode> = (
        tokenStream,
        annotation,
        minPrecedence?
    ) => {
        minPrecedence = minPrecedence || 0;
        let node: AstNode;

        const [tokenType, token] = tokenStream.peek();
        if (tokenType) {
            const opInfo = unaryOperators[token as OperatorType];
            if (opInfo) {
                const [opType, precedence] = [opInfo[1], opInfo[2]];
                tokenStream.consume();
                const operator: OperatorType = <OperatorType>token;
                const rhsNode = this.parseExpression(
                    tokenStream,
                    annotation,
                    precedence
                );
                if (rhsNode) {
                    if (operator == "-" && rhsNode.type === "value") {
                        const value = -1 * tonumber(rhsNode.value);
                        node = this.getNumberNode(value, annotation);
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
                const simpleExpression = this.parseSimpleExpression(
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
            const [tokenType, token] = tokenStream.peek();
            if (tokenType) {
                const opInfo = binaryOperators[token as OperatorType];
                if (opInfo) {
                    const [opType, precedence] = [opInfo[1], opInfo[2]];
                    if (precedence && precedence > minPrecedence) {
                        keepScanning = true;
                        tokenStream.consume();
                        const operator = <OperatorType>token;
                        const lhsNode = node;
                        let rhsNode = this.parseExpression(
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
                            const operatorInfo = binaryOperators[node.operator];
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

    private parseTypedFunction(
        tokenStream: OvaleLexer,
        annotation: AstAnnotation,
        name: string,
        target: string | undefined,
        filter: string | undefined,
        infos: FunctionInfos
    ) {
        if (!this.parseToken(tokenStream, "FUNCTION", "(")) return undefined;

        const [positionalParams, namedParams] = this.parseParameters(
            tokenStream,
            "function",
            annotation,
            undefined
        );
        if (!positionalParams || !namedParams) return undefined;

        if (target) {
            namedParams.target = this.newString(annotation, target);
        }
        if (filter) {
            namedParams.filter = this.newString(annotation, filter);
        }

        if (lualength(positionalParams) > lualength(infos.parameters)) {
            this.syntaxError(
                tokenStream,
                "Type error: the %s function takes %d parameters",
                name,
                lualength(infos.parameters)
            );
            return undefined;
        }
        for (const [key, node] of kpairs(namedParams)) {
            const parameterIndex = infos.namedParameters[key];
            if (parameterIndex !== undefined) {
                if (positionalParams[parameterIndex] !== undefined) {
                    this.syntaxError(
                        tokenStream,
                        "Type error: the %s parameters is named in the %s function although it appears already in the parameters list",
                        key,
                        name
                    );
                    return undefined;
                }
                positionalParams[parameterIndex] = node;
            } else {
                this.syntaxError(
                    tokenStream,
                    "Type error: unknown %s parameter in %s function",
                    key,
                    getFunctionSignature(name, infos)
                );
                return undefined;
            }
        }

        for (const [key, parameterInfos] of ipairs(infos.parameters)) {
            const parameter = positionalParams[key];
            if (!parameter) {
                if (parameterInfos.defaultValue !== undefined) {
                    if (parameterInfos.type === "string") {
                        positionalParams[key] = this.newString(
                            annotation,
                            parameterInfos.defaultValue
                        );
                    } else if (parameterInfos.type === "number") {
                        positionalParams[key] = this.newValue(
                            annotation,
                            parameterInfos.defaultValue
                        );
                    } else if (parameterInfos.type === "boolean") {
                        positionalParams[key] = this.newBoolean(
                            annotation,
                            parameterInfos.defaultValue
                        );
                    } else {
                        this.syntaxError(
                            tokenStream,
                            "Type error: parameter type unknown in %s function",
                            name
                        );
                        return undefined;
                    }
                } else if (!parameterInfos.optional) {
                    this.syntaxError(
                        tokenStream,
                        "Type error: parameter %s is required in %s function",
                        parameterInfos.name,
                        name
                    );
                    return undefined;
                } else {
                    positionalParams[key] = this.newUndefined(annotation);
                }
            } else {
                if (parameterInfos.type === "number") {
                    if (parameterInfos.isSpell) {
                        annotation.spellNode = annotation.spellNode || {};
                        insert(annotation.spellNode, parameter);
                    }
                } else if (
                    parameterInfos.type === "string" &&
                    parameter.type === "string"
                ) {
                    if (parameterInfos.checkTokens) {
                        if (
                            !checkToken(
                                parameterInfos.checkTokens,
                                parameter.value
                            )
                        ) {
                            this.syntaxError(
                                tokenStream,
                                "Type error: parameter %s has not a valid value in function %s",
                                key,
                                name
                            );
                            return undefined;
                        }
                    }
                }
            }
        }
        if (!this.parseToken(tokenStream, "FUNCTION", ")")) return undefined;

        const node = this.newNodeWithParameters(
            "typed_function",
            annotation,
            positionalParams,
            namedParams
        );
        node.name = name;
        node.asString = this.unparseTypedFunction(node);

        return node;
    }

    private parseAction(
        tokenStream: OvaleLexer,
        annotation: AstAnnotation,
        name: ActionType
    ) {
        if (!this.parseToken(tokenStream, "ACTION", "(")) return undefined;
        const count = actionParameterCounts[name];
        const [positionalParams, namedParams] = this.parseParameters(
            tokenStream,
            "function",
            annotation,
            count,
            checkActionParameters
        );
        if (!positionalParams || !namedParams) return undefined;
        if (!this.parseToken(tokenStream, "ACTION", ")")) return undefined;

        const node = this.newNodeWithParameters(
            "action",
            annotation,
            positionalParams,
            namedParams
        );

        node.name = name;
        if (stringLookupFunctions[name]) {
            annotation.stringReference = annotation.stringReference || {};
            annotation.stringReference[
                lualength(annotation.stringReference) + 1
            ] = node;
        }
        node.asString = this.unparseAction(node);

        if (name === "spell") {
            const parameter = positionalParams[1];
            if (!parameter) {
                this.syntaxError(
                    tokenStream,
                    "Type error: %s function expect a spell id parameter",
                    name
                );
            }
            annotation.spellNode = annotation.spellNode || {};
            annotation.spellNode[
                lualength(annotation.spellNode) + 1
            ] = parameter;
        }

        return node;
    }

    private parseFunction: ParserFunction<
        AstFunctionNode | AstTypedFunctionNode | AstActionNode
    > = (tokenStream, annotation) => {
        let name;
        {
            const [tokenType, token] = tokenStream.consume();
            if ((tokenType === "name" || tokenType === "keyword") && token) {
                name = token;
            } else {
                this.syntaxError(
                    tokenStream,
                    "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.",
                    token
                );
                return undefined;
            }
        }

        if (checkToken(checkActionType, name)) {
            return this.parseAction(tokenStream, annotation, name);
        }

        let target;
        let [tokenType, token] = tokenStream.peek();
        if (tokenType == ".") {
            target = name;
            [tokenType, token] = tokenStream.consume(2);
            if (tokenType == "name" && token) {
                name = token;
            } else {
                this.syntaxError(
                    tokenStream,
                    "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.",
                    token
                );
                return undefined;
            }
        }

        if (!target) {
            if (sub(name, 1, 6) == "target") {
                target = "target";
                name = sub(name, 7);
            }
        }

        let filter;
        if (sub(name, 1, 6) == "debuff") {
            filter = "debuff";
        } else if (sub(name, 1, 4) == "buff") {
            filter = "buff";
        } else if (sub(name, 1, 11) == "otherdebuff") {
            filter = "debuff";
        } else if (sub(name, 1, 9) == "otherbuff") {
            filter = "buff";
        }

        const infos = this.ovaleCondition.getInfos(name);
        if (infos) {
            return this.parseTypedFunction(
                tokenStream,
                annotation,
                name,
                target,
                filter,
                infos
            );
        }

        if (!this.parseToken(tokenStream, "FUNCTION", "(")) return undefined;

        const [positionalParams, namedParams] = this.parseParameters(
            tokenStream,
            "function",
            annotation,
            undefined,
            checkFunctionParameters
        );
        if (!positionalParams || !namedParams) return undefined;

        if (!this.parseToken(tokenStream, "FUNCTION", ")")) return undefined;

        if (target) {
            namedParams.target = this.newString(annotation, target);
        }
        if (filter) {
            namedParams.filter = this.newString(annotation, filter);
        }

        let nodeType: "state" | "function" | "custom_function";
        if (stateActions[name]) {
            nodeType = "state";
        } else if (stringLookupFunctions[name]) {
            nodeType = "function";
        } else if (this.ovaleCondition.isCondition(name)) {
            nodeType = "function";
        } else {
            nodeType = "custom_function";
        }

        const node = this.newNodeWithParameters(
            nodeType,
            annotation,
            positionalParams,
            namedParams
        );

        node.name = name;
        if (stringLookupFunctions[name]) {
            annotation.stringReference = annotation.stringReference || {};
            annotation.stringReference[
                lualength(annotation.stringReference) + 1
            ] = node;
        }
        node.asString = this.unparseFunction(node);
        if (nodeType === "custom_function") {
            annotation.functionCall = annotation.functionCall || {};
            annotation.functionCall[node.name] = true;
        }

        if (
            nodeType === "function" &&
            this.ovaleCondition.isSpellBookCondition(name)
        ) {
            const parameter = positionalParams[1];
            if (!parameter) {
                this.syntaxError(
                    tokenStream,
                    "Type error: %s function expect a spell id parameter",
                    name
                );
            }
            annotation.spellNode = annotation.spellNode || {};
            annotation.spellNode[
                lualength(annotation.spellNode) + 1
            ] = parameter;
        }

        return node;
    };

    private parseGroup(tokenStream: OvaleLexer, annotation: AstAnnotation) {
        const group = this.innerParseGroup(tokenStream, annotation);
        if (group && lualength(group.child) === 1) {
            const result = group.child[1];
            this.nodesPool.release(group);
            return result;
        }
        return group;
    }

    private innerParseGroup: ParserFunction<AstGroupNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.consume();
        if (tokenType != "{") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing GROUP; '{' expected.",
                token
            );
            return undefined;
        }
        const node = this.newNodeWithChildren("group", annotation);
        const child = node.child;
        [tokenType] = tokenStream.peek();
        while (tokenType && tokenType != "}") {
            const statementNode = this.parseStatement(tokenStream, annotation);
            if (statementNode) {
                child[lualength(child) + 1] = statementNode;
                [tokenType] = tokenStream.peek();
            } else {
                this.nodesPool.release(node);
                return undefined;
            }
        }
        [tokenType, token] = tokenStream.consume();
        if (tokenType != "}") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing GROUP; '}' expected.",
                token
            );
            this.nodesPool.release(node);
            return undefined;
        }
        return node;
    };
    private parseIf: ParserFunction<AstIfNode> = (tokenStream, annotation) => {
        const [tokenType, token] = tokenStream.consume();
        if (!(tokenType == "keyword" && token == "if")) {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing IF; 'if' expected.",
                token
            );
            return undefined;
        }
        const conditionNode = this.parseStatement(tokenStream, annotation);
        if (!conditionNode) return undefined;
        const bodyNode = this.parseStatement(tokenStream, annotation);
        if (!bodyNode) return undefined;
        const node = this.newNodeWithChildren("if", annotation);
        node.child[1] = conditionNode;
        node.child[2] = bodyNode;
        return node;
    };
    private parseInclude: ParserFunction<AstScriptNode> = (
        tokenStream,
        nodeList,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.consume();
        if (!(tokenType == "keyword" && token == "include")) {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing INCLUDE; 'Include' expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.consume();
        if (tokenType != "(") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing INCLUDE; '(' expected.",
                token
            );
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.consume();
        if (tokenType == "name" && token) {
            name = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing INCLUDE; script name expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.consume();
        if (tokenType != ")") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing INCLUDE; ')' expected.",
                token
            );
            return undefined;
        }
        const code = this.ovaleScripts.getScript(name);
        if (code === undefined) {
            this.debug.error(
                "Script '%s' not found when parsing INCLUDE.",
                name
            );
            return undefined;
        }
        const includeTokenStream = new OvaleLexer(
            name,
            code,
            tokenMatches,
            lexerFilters
        );
        const node = this.parseScriptStream(
            includeTokenStream,
            nodeList,
            annotation
        );
        includeTokenStream.release();
        return node;
    };
    private parseItemInfo: ParserFunction<AstItemInfoNode> = (
        tokenStream,
        annotation
    ) => {
        let name;
        let [tokenType, token] = tokenStream.consume();
        if (!(tokenType == "keyword" && token == "iteminfo")) {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMINFO; 'ItemInfo' expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.consume();
        if (tokenType != "(") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMINFO; '(' expected.",
                token
            );
            return undefined;
        }
        let itemId;
        [tokenType, token] = tokenStream.consume();
        if (tokenType == "number") {
            itemId = token;
        } else if (tokenType == "name") {
            name = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMINFO; number or name expected.",
                token
            );
            return undefined;
        }
        const [positionalParams, namedParams] = this.parseParameters(
            tokenStream,
            "iteminfo",
            annotation,
            undefined,
            checkSpellInfo
        );
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.consume();
        if (tokenType != ")") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMINFO; ')' expected.",
                token
            );
            return undefined;
        }
        const node = this.newNodeWithParameters(
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

    private parseItemRequire: ParserFunction<AstItemRequireNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.consume();
        if (!(tokenType == "keyword" && token == "itemrequire")) {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; keyword expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.consume();
        if (tokenType != "(") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; '(' expected.",
                token
            );
            return undefined;
        }
        let itemId, name;

        [tokenType, token] = tokenStream.consume();
        if (tokenType == "number") {
            itemId = token;
        } else if (tokenType == "name") {
            name = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; number or name expected.",
                token
            );
            return undefined;
        }
        const property = this.parseCheckedNameToken(
            tokenStream,
            "ITEMREQUIRE",
            checkSpellInfo
        );
        if (!property) return undefined;

        const [positionalParams, namedParams] = this.parseParameters(
            tokenStream,
            "itemrequire",
            annotation,
            0,
            checkSpellRequireParameters
        );
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.consume();
        if (tokenType != ")") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; ')' expected.",
                token
            );
            return undefined;
        }
        const node = this.newNodeWithParameters(
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
    private parseList: ParserFunction<AstListNode> = (
        tokenStream,
        annotation
    ) => {
        let keyword;
        let [tokenType, token] = tokenStream.consume();
        if (
            tokenType == "keyword" &&
            (token == "itemlist" || token == "spelllist")
        ) {
            keyword = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing LIST; keyword expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.consume();
        if (tokenType != "(") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing LIST; '(' expected.",
                token
            );
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.consume();
        if (tokenType == "name" && token) {
            name = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing LIST; name expected.",
                token
            );
            return undefined;
        }
        const [positionalParams, namedParams] = this.parseParameters(
            tokenStream,
            "list",
            annotation,
            undefined,
            checkListParameters
        );
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.consume();
        if (tokenType != ")") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing LIST; ')' expected.",
                token
            );
            return undefined;
        }
        const node = this.newNodeWithParameters(
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
    private parseNumber = (
        tokenStream: OvaleLexer,
        annotation: AstAnnotation
    ): Result<AstValueNode> => {
        let value;
        const [tokenType, token] = tokenStream.consume();
        if (tokenType == "number") {
            value = tonumber(token);
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing NUMBER; number expected.",
                token
            );
            return undefined;
        }
        const node = this.getNumberNode(value, annotation);
        return node;
    };
    private parseParameters<T extends string>(
        tokenStream: OvaleLexer,
        methodName: string,
        annotation: AstAnnotation,
        maxNumberOfParameters: number | undefined,
        namedParameters?: KeyCheck<T>
    ): [RawPositionalParameters?, RawNamedParameters<T>?] {
        const positionalParams = this.rawPositionalParametersPool.get();
        const namedParams = <RawNamedParameters<T>>(
            this.rawNamedParametersPool.get()
        );
        while (true) {
            const [tokenType] = tokenStream.peek();
            if (tokenType) {
                const [nextTokenType] = tokenStream.peek(2);
                if (nextTokenType === "=") {
                    let parameterName;
                    if (namedParameters) {
                        parameterName = this.parseCheckedNameToken(
                            tokenStream,
                            methodName,
                            namedParameters
                        );
                    } else {
                        parameterName = this.parseNameToken(
                            tokenStream,
                            methodName
                        ) as T;
                    }

                    if (!parameterName) {
                        return [];
                    }

                    // Consume the '=' token.
                    tokenStream.consume();

                    const node = this.parseSimpleParameterValue(
                        tokenStream,
                        annotation
                    );
                    if (!node) return [];
                    namedParams[parameterName] = node;
                } else {
                    let node;
                    if (tokenType == "name" || tokenType === "keyword") {
                        node = this.parseVariable(tokenStream, annotation);
                        if (!node) {
                            return [];
                        }
                    } else if (tokenType == "number") {
                        node = this.parseNumber(tokenStream, annotation);
                        if (!node) {
                            return [];
                        }
                    } else if (tokenType == "-") {
                        tokenStream.consume();
                        node = this.parseNumber(tokenStream, annotation);
                        if (node) {
                            const value = -1 * <number>node.value;
                            node = this.getNumberNode(value, annotation);
                        } else {
                            return [];
                        }
                    } else if (tokenType == "string") {
                        node = this.parseString(tokenStream, annotation);
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
                        this.syntaxError(
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
    private parseParentheses(
        tokenStream: OvaleLexer,
        annotation: AstAnnotation
    ): AstNode | undefined {
        let leftToken, rightToken;
        {
            const [tokenType, token] = tokenStream.consume();
            if (tokenType == "(") {
                [leftToken, rightToken] = ["(", ")"];
            } else if (tokenType == "{") {
                [leftToken, rightToken] = ["{", "}"];
            } else {
                this.syntaxError(
                    tokenStream,
                    "Syntax error: unexpected token '%s' when parsing PARENTHESES; '(' or '{' expected.",
                    token
                );
                return undefined;
            }
        }
        const node = this.parseExpression(tokenStream, annotation);
        if (!node) return undefined;
        const [tokenType, token] = tokenStream.consume();
        if (tokenType != rightToken) {
            this.syntaxError(
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
    private parseScoreSpells: ParserFunction<AstScoreSpellsNode> = (
        tokenStream,
        annotation
    ) => {
        let [tokenType, token] = tokenStream.consume();
        if (!(tokenType == "keyword" && token == "scorespells")) {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SCORESPELLS; 'ScoreSpells' expected.",
                token
            );
            return undefined;
        }

        [tokenType, token] = tokenStream.consume();
        if (tokenType != "(") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SCORESPELLS; '(' expected.",
                token
            );
            return undefined;
        }

        const [positionalParams, namedParams] = this.parseParameters(
            tokenStream,
            "scorespells",
            annotation,
            undefined,
            checkListParameters
        );
        if (!positionalParams || !namedParams) return undefined;

        [tokenType, token] = tokenStream.consume();
        if (tokenType != ")") {
            this.syntaxError(
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
    private parseScriptStream: ParserFunction<AstScriptNode> = (
        tokenStream: OvaleLexer,
        annotation
    ) => {
        this.profiler.startProfiling("OvaleAST_ParseScript");
        const ast = this.newNodeWithChildren("script", annotation);
        const child = ast.child;
        while (true) {
            const [tokenType, token] = tokenStream.peek();
            if (tokenType) {
                const declarationNode = this.parseDeclaration(
                    tokenStream,
                    annotation
                );
                if (!declarationNode) {
                    this.debug.error(`Failed on ${token}`);
                    this.nodesPool.release(ast);
                    return undefined;
                }
                if (declarationNode.type == "script") {
                    for (const [, node] of ipairs(declarationNode.child)) {
                        child[lualength(child) + 1] = node;
                    }
                    this.nodesPool.release(declarationNode);
                } else {
                    child[lualength(child) + 1] = declarationNode;
                }
            } else {
                break;
            }
        }
        this.profiler.stopProfiling("OvaleAST_ParseScript");
        return ast;
    };
    private parseSimpleExpression(
        tokenStream: OvaleLexer,
        annotation: AstAnnotation
    ) {
        let node;
        let [tokenType, token] = tokenStream.peek();
        if (tokenType == "number") {
            node = this.parseNumber(tokenStream, annotation);
        } else if (tokenType == "string") {
            node = this.parseString(tokenStream, annotation);
        } else if (
            tokenType === "keyword" &&
            (token === "true" || token === "false")
        ) {
            tokenStream.consume();
            node = this.newBoolean(annotation, token === "true");
        } else if (tokenType == "name" || tokenType === "keyword") {
            [tokenType, token] = tokenStream.peek(2);
            if (tokenType == "." || tokenType == "(") {
                node = this.parseFunction(tokenStream, annotation);
            } else {
                node = this.parseVariable(tokenStream, annotation);
            }
        } else if (tokenType == "(" || tokenType == "{") {
            node = this.parseParentheses(tokenStream, annotation);
        } else {
            tokenStream.consume();
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION",
                token
            );
            return undefined;
        }
        return node;
    }
    private parseSimpleParameterValue: ParserFunction<AstNode> = (
        tokenStream,
        annotation
    ) => {
        let isBang = false;
        let [tokenType] = tokenStream.peek();
        if (tokenType == "!") {
            isBang = true;
            tokenStream.consume();
        }
        let expressionNode;
        [tokenType] = tokenStream.peek();
        if (tokenType == "(" || tokenType == "-") {
            expressionNode = this.parseExpression(tokenStream, annotation);
        } else {
            expressionNode = this.parseSimpleExpression(
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
        let [tokenType, token] = tokenStream.consume();
        let spellId, name;
        if (tokenType === "-") {
            [tokenType, token] = tokenStream.consume();
            if (tokenType === "number") spellId = -tonumber(token);
            else {
                this.syntaxError(
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
            this.syntaxError(
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
        const [tokenType, token] = tokenStream.consume();
        if (tokenType != expectedToken) {
            this.syntaxError(
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

    private parseKeywordTokens<T extends string>(
        tokenStream: OvaleLexer,
        methodName: string,
        keyCheck: KeyCheck<T>
    ): T | undefined {
        let keyword;
        const [tokenType, token] = tokenStream.consume();
        if (tokenType == "keyword" && token && checkToken(keyCheck, token)) {
            keyword = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing %s; keyword expected.",
                token,
                methodName
            );
            return undefined;
        }
        return keyword;
    }

    private parseKeywordToken<T extends string>(
        tokenStream: OvaleLexer,
        methodName: string,
        keyCheck: T
    ): T | undefined {
        let keyword;
        const [tokenType, token] = tokenStream.consume();
        if (tokenType == "keyword" && token && token === keyCheck) {
            keyword = keyCheck;
        } else {
            this.syntaxError(
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

    private parseCheckedNameToken<T extends string>(
        tokenStream: OvaleLexer,
        methodName: string,
        keyCheck: KeyCheck<T>
    ): T | undefined {
        let keyword;
        const [tokenType, token] = tokenStream.consume();
        if (tokenType == "name" && token && checkToken(keyCheck, token)) {
            keyword = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing %s; name expected.",
                token,
                methodName
            );
            return undefined;
        }
        return keyword;
    }

    private parseNameToken(
        tokenStream: OvaleLexer,
        methodName: string
    ): string | undefined {
        let keyword;
        const [tokenType, token] = tokenStream.consume();
        if (tokenType == "name" && token) {
            keyword = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing %s; name expected.",
                token,
                methodName
            );
            return undefined;
        }
        return keyword;
    }

    private parseSpellAuraList: ParserFunction<AstSpellAuraListNode> = (
        tokenStream,
        annotation
    ) => {
        const keyword = this.parseKeywordTokens(
            tokenStream,
            "SPELLAURALIST",
            spellAuraKewords
        );

        if (!keyword) {
            this.debug.error("Failed on keyword");
            return undefined;
        }

        if (!this.parseToken(tokenStream, "SPELLAURALIST", "(")) {
            this.debug.error("Failed on (");
            return undefined;
        }
        const [spellId, name] = this.parseNumberOrNameParameter(
            tokenStream,
            "SPELLAURALIST"
        );
        const [buffSpellId, buffName] = this.parseNumberOrNameParameter(
            tokenStream,
            "SPELLAURALIST"
        );

        const [positionalParams, namedParams] = this.parseParameters(
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
            this.debug.error("Failed on )");
            return undefined;
        }

        const node = this.newNodeWithParameters(
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
    private parseSpellInfo: ParserFunction<AstSpellInfoNode> = (
        tokenStream,
        annotation
    ) => {
        let name;
        let [tokenType, token] = tokenStream.consume();
        if (!(tokenType == "keyword" && token == "spellinfo")) {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SPELLINFO; 'SpellInfo' expected.",
                token
            );
            return undefined;
        }

        [tokenType, token] = tokenStream.consume();
        if (tokenType != "(") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SPELLINFO; '(' expected.",
                token
            );
            return undefined;
        }
        let spellId;
        [tokenType, token] = tokenStream.consume();
        if (tokenType == "number") {
            spellId = tonumber(token);
        } else if (tokenType == "name") {
            name = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SPELLINFO; number or name expected.",
                token
            );
            return undefined;
        }
        const [positionalParams, namedParams] = this.parseParameters(
            tokenStream,
            "spellinfo",
            annotation,
            0,
            checkSpellInfo
        );
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.consume();
        if (tokenType != ")") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SPELLINFO; ')' expected.",
                token
            );
            return undefined;
        }
        const node = this.newNodeWithParameters(
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
    private parseSpellRequire: ParserFunction<AstSpellRequireNode> = (
        tokenStream,
        annotation
    ) => {
        if (
            this.parseKeywordToken(
                tokenStream,
                "SPELLREQUIRE",
                "spellrequire"
            ) === undefined
        )
            return undefined;
        if (!this.parseToken(tokenStream, "SPELLREQUIRE", "("))
            return undefined;
        const [spellId, name] = this.parseNumberOrNameParameter(
            tokenStream,
            "SPELLREQUIRE"
        );
        if (!spellId && !name) return undefined;

        const property = this.parseCheckedNameToken(
            tokenStream,
            "SPELLREQUIRE",
            checkSpellInfo
        );
        if (!property) return undefined;

        const [positionalParams, namedParams] = this.parseParameters(
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

    private parseStatement = (
        tokenStream: OvaleLexer,
        annotation: AstAnnotation
    ): AstNode | undefined => {
        let node;
        let [tokenType, token] = tokenStream.peek();
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
                    [tokenType, token] = tokenStream.peek(i);
                    if (count == 0) {
                        break;
                    }
                }
                if (!tokenType || binaryOperators[token as OperatorType]) {
                    node = this.parseExpression(tokenStream, annotation);
                } else {
                    node = this.parseGroup(tokenStream, annotation);
                }
            } else if (token == "if") {
                node = this.parseIf(tokenStream, annotation);
            } else if (token == "unless") {
                node = this.parseUnless(tokenStream, annotation);
            } else {
                node = this.parseExpression(tokenStream, annotation);
            }
        }
        return node;
    };
    private parseString: ParserFunction<
        AstStringNode | AstFunctionNode | AstActionNode | AstTypedFunctionNode
    > = (tokenStream, annotation) => {
        let value;
        const [tokenType, token] = tokenStream.peek();
        if (tokenType == "string" && token) {
            value = token;
            tokenStream.consume();
        } else if (tokenType == "name" && token) {
            if (stringLookupFunctions[lower(token)]) {
                // TODO Maybe have a specific parse function for string
                // lookup functions
                return this.parseFunction(tokenStream, annotation);
            } else {
                value = token;
                tokenStream.consume();
            }
        } else {
            tokenStream.consume();
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing STRING; string, variable, or function expected.",
                token
            );
            return undefined;
        }

        const node = this.newString(annotation, value);
        annotation.stringReference = annotation.stringReference || {};
        annotation.stringReference[
            lualength(annotation.stringReference) + 1
        ] = node;
        return node;
    };
    private parseUnless: ParserFunction<AstUnlessNode> = (
        tokenStream,
        annotation
    ) => {
        const [tokenType, token] = tokenStream.consume();
        if (!(tokenType == "keyword" && token == "unless")) {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing UNLESS; 'unless' expected.",
                token
            );
            return undefined;
        }
        const conditionNode = this.parseExpression(tokenStream, annotation);
        if (!conditionNode) return undefined;
        const bodyNode = this.parseStatement(tokenStream, annotation);
        if (!bodyNode) return undefined;
        const node = this.newNodeWithChildren("unless", annotation);
        node.child[1] = conditionNode;
        node.child[2] = bodyNode;
        return node;
    };
    private parseVariable: ParserFunction<AstVariableNode> = (
        tokenStream,
        annotation
    ) => {
        let name;
        const [tokenType, token] = tokenStream.consume();
        if ((tokenType == "name" || tokenType === "keyword") && token) {
            name = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing VARIABLE; name expected.",
                token
            );
            return undefined;
        }

        const node = this.newNode("variable", annotation);
        node.name = name;
        annotation.nameReference = annotation.nameReference || {};
        annotation.nameReference[
            lualength(annotation.nameReference) + 1
        ] = node;
        return node;
    };
    private parseVisitors: { [key in NodeType]?: ParserFunction } = {
        ["action"]: this.parseFunction,
        ["add_function"]: this.parseAddFunction,
        ["arithmetic"]: this.parseExpression,
        ["bang_value"]: this.parseSimpleParameterValue,
        ["checkbox"]: this.parseAddCheckBox,
        ["compare"]: this.parseExpression,
        ["comment"]: this.parseComment,
        ["custom_function"]: this.parseFunction,
        ["define"]: this.parseDefine,
        ["expression"]: this.parseStatement,
        ["function"]: this.parseFunction,
        ["group"]: this.parseGroup,
        ["icon"]: this.parseAddIcon,
        ["if"]: this.parseIf,
        ["item_info"]: this.parseItemInfo,
        ["itemrequire"]: this.parseItemRequire,
        ["list"]: this.parseList,
        ["list_item"]: this.parseAddListItem,
        ["logical"]: this.parseExpression,
        ["score_spells"]: this.parseScoreSpells,
        ["script"]: this.parseScriptStream,
        ["spell_aura_list"]: this.parseSpellAuraList,
        ["spell_info"]: this.parseSpellInfo,
        ["spell_require"]: this.parseSpellRequire,
        ["string"]: this.parseString,
        ["unless"]: this.parseUnless,
        ["value"]: this.parseNumber,
        ["variable"]: this.parseVariable,
    };

    public newFunction(name: string, annotation: AstAnnotation) {
        const node = this.newNodeWithParameters("function", annotation);
        node.name = name;
        return node;
    }

    public newString(annotation: AstAnnotation, value: string) {
        const node = this.newNode("string", annotation);
        node.value = value;
        node.result.constant = true;
        const result = node.result as NodeValueResult;
        result.timeSpan.copyFromArray(universe);
        result.type = "value";
        result.value = value;
        return node;
    }

    public newVariable(annotation: AstAnnotation, name: string) {
        const node = this.newNode("variable", annotation);
        node.name = name;
        return node;
    }

    public newValue(annotation: AstAnnotation, value: number) {
        const node = this.newNode("value", annotation);
        node.value = value;
        node.result.constant = true;
        const result = node.result as NodeValueResult;
        result.type = "value";
        result.value = value;
        result.timeSpan.copyFromArray(universe);
        result.origin = 0;
        result.rate = 0;
        return node;
    }

    public newBoolean(annotation: AstAnnotation, value: boolean) {
        const node = this.newNode("boolean", annotation);
        node.value = value;
        node.result.constant = true;
        const result = node.result;
        if (value) {
            result.timeSpan.copyFromArray(universe);
        } else {
            wipe(result.timeSpan);
        }
        result.type = "none";
        return node;
    }

    public newUndefined(annotation: AstAnnotation) {
        const node = this.newNode("undefined", annotation);
        node.result.constant = true;
        node.result.timeSpan.copyFromArray(emptySet);
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
            rawNamedParams || this.rawNamedParametersPool.get();
        node.rawPositionalParams =
            rawPositionalParameters || this.rawPositionalParametersPool.get();
        node.cachedParams = {
            named: this.namedParametersPool.get(),
            positional: this.positionalParametersPool.get(),
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
        node.child = this.childrenPool.get();
        return node;
    }

    private internalNewNode<T extends NodeType>(
        type: T,
        annotation: AstAnnotation
    ): NodeTypes[T] {
        const node = this.nodesPool.get() as NodeTypes[T];
        node.type = type;
        node.annotation = annotation;
        const nodeList = annotation.nodeList;
        const nodeId = lualength(nodeList) + 1;
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

    public newNode<T extends Exclude<NodeType, NodeWithChildrenType>>(
        type: T,
        annotation: AstAnnotation
    ): NodeTypes[T] {
        return this.internalNewNode(type, annotation);
    }

    public nodeToString(node: AstNode) {
        const output = this.printRecurse(node);
        return concat(output, "\n");
    }
    public releaseAnnotation(annotation: AstAnnotation) {
        if (annotation.checkBoxList) {
            for (const [, control] of ipairs(annotation.checkBoxList)) {
                this.checkboxPool.release(control);
            }
        }
        if (annotation.listList) {
            for (const [, control] of ipairs(annotation.listList)) {
                this.listPool.release(control);
            }
        }
        if (annotation.rawPositionalParametersList) {
            for (const [, parameters] of ipairs(
                annotation.rawPositionalParametersList
            )) {
                this.rawPositionalParametersPool.release(parameters);
            }
        }
        if (annotation.rawNamedParametersList) {
            for (const [, parameters] of ipairs(
                annotation.rawNamedParametersList
            )) {
                this.rawNamedParametersPool.release(parameters);
            }
        }
        if (annotation.nodeList) {
            for (const [, node] of ipairs(annotation.nodeList)) {
                this.nodesPool.release(node);
            }
        }
        for (const [, value] of kpairs(annotation)) {
            if (type(value) == "table") {
                wipe(value);
            }
        }
        wipe(annotation);
    }
    public release(ast: AstNode) {
        ast.result.timeSpan.release();
        wipe(ast.result);
        wipe(ast);
        this.nodesPool.release(ast);
    }
    public parseCode(
        nodeType: NodeType,
        code: string,
        nodeList: LuaArray<AstNode>,
        annotation: AstAnnotation
    ): [AstNode, LuaArray<AstNode>, AstAnnotation] | [] {
        const tokenStream = new OvaleLexer("Ovale", code, tokenMatches, {
            comments: tokenizeComment,
            space: tokenizeWhitespace,
        });
        const node = this.parse(nodeType, tokenStream, nodeList, annotation);
        tokenStream.release();
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
        const [ast] = this.parseCode(
            "script",
            code,
            annotation.nodeList,
            annotation
        );
        if (ast) {
            if (ast.type == "script") {
                ast.annotation = annotation;
                this.propagateConstants(ast);
                this.propagateStrings(ast);
                //    this.FlattenParameters(ast);
                //this.VerifyParameterStances(ast);
                this.verifyFunctionCalls(ast);
                if (options.optimize) {
                    this.optimize(ast);
                }
                this.insertPostOrderTraversal(ast);
                return ast;
            }

            this.debug.debug(`Unexpected type ${ast.type} in parseScript`);
            this.release(ast);
        } else {
            this.debug.error("Parse failed");
        }

        this.releaseAnnotation(annotation);
        return undefined;
    }

    public parseNamedScript(
        name: string,
        options?: { optimize: boolean; verify: boolean }
    ) {
        const code = this.ovaleScripts.getScriptOrDefault(name);
        if (code) {
            return this.parseScript(code, options);
        } else {
            this.debug.debug("No code to parse");
            return undefined;
        }
    }

    private getId(name: string, dictionary: LuaObj<string | number>) {
        const itemId = dictionary[name];
        if (itemId) {
            if (isNumber(itemId)) {
                return itemId;
            } else {
                this.debug.error(`${name} is as string and not an item id`);
            }
        }
        return 0;
    }

    public propagateConstants(ast: AstNode) {
        this.profiler.startProfiling("OvaleAST_PropagateConstants");
        if (ast.annotation) {
            const dictionary = ast.annotation.definition;
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
                        const name = node.name;
                        const value = dictionary[name];
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
                        } else {
                            const valueNode = (node as unknown) as AstStringNode;
                            valueNode.type = "string";
                            valueNode.value = name;
                        }
                    }
                }
            }
        }
        this.profiler.stopProfiling("OvaleAST_PropagateConstants");
    }

    public propagateStrings(ast: AstNode) {
        this.profiler.startProfiling("OvaleAST_PropagateStrings");
        if (ast.annotation && ast.annotation.stringReference) {
            for (const [, node] of ipairs(ast.annotation.stringReference)) {
                const nodeAsString = <AstStringNode>node;
                if (node.type === "string") {
                    const key = node.value;
                    const value = l[key as keyof LocalizationStrings];
                    if (value) {
                        nodeAsString.value = value;
                        nodeAsString.name = key;
                    }
                } else if (node.type === "variable") {
                    nodeAsString.type = "string";
                    const name = node.name;
                    nodeAsString.name = node.name;
                    nodeAsString.value = name;
                } else if (node.type === "value") {
                    const value = node.value;
                    nodeAsString.type = "string";
                    nodeAsString.name = tostring(node.value);
                    nodeAsString.value = tostring(value);
                } else if (node.type == "function") {
                    const key = node.rawPositionalParams[1];
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
                        const name = node.name;
                        if (name == "itemname") {
                            [value] = GetItemInfo(stringKey);
                            if (!value) value = "item:" + stringKey;
                        } else if (name == "l") {
                            value =
                                l[stringKey as keyof LocalizationStrings] ||
                                stringKey;
                        } else if (name == "spellname") {
                            value =
                                this.ovaleSpellBook.getSpellName(
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
        this.profiler.stopProfiling("OvaleAST_PropagateStrings");
    }

    private verifyFunctionCalls(ast: AstNode) {
        this.profiler.startProfiling("OvaleAST_VerifyFunctionCalls");
        if (ast.annotation && ast.annotation.verify) {
            const customFunction = ast.annotation.customFunction;
            const functionCall = ast.annotation.functionCall;
            if (functionCall) {
                for (const [name] of pairs(functionCall)) {
                    if (
                        !(
                            checkToken(checkActionType, name) ||
                            stringLookupFunctions[name] ||
                            this.ovaleCondition.isCondition(name) ||
                            (customFunction && customFunction[name])
                        )
                    ) {
                        this.debug.error("unknown function '%s'.", name);
                    }
                }
            }
        }
        this.profiler.stopProfiling("OvaleAST_VerifyFunctionCalls");
    }

    private insertPostOrderTraversal(ast: AstNode) {
        this.profiler.startProfiling("OvaleAST_InsertPostOrderTraversal");
        const annotation = ast.annotation;
        if (annotation && annotation.postOrderReference) {
            for (const [, node] of ipairs(annotation.postOrderReference)) {
                const array = this.postOrderPool.get();
                const visited = this.postOrderVisitedPool.get();
                this.postOrderTraversal(node, array, visited);
                this.postOrderVisitedPool.release(visited);
                node.postOrder = array;
            }
        }
        this.profiler.stopProfiling("OvaleAST_InsertPostOrderTraversal");
    }

    private optimize(ast: AstNode) {
        this.profiler.startProfiling("OvaleAST_CommonSubExpressionElimination");
        if (ast && ast.annotation && ast.annotation.nodeList) {
            const expressionHash: LuaObj<AstNode> = {};

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
        this.profiler.stopProfiling("OvaleAST_CommonSubExpressionElimination");
    }
}
