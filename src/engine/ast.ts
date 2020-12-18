import { L } from "../ui/Localization";
import { OvalePool } from "../tools/Pool";
import { OvaleProfilerClass, Profiler } from "./profiler";
import { OvaleDebugClass, Tracer } from "./debug";
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
    EMPTY_SET,
    newTimeSpan,
    OvaleTimeSpan,
    UNIVERSE,
} from "../tools/TimeSpan";
import { ActionType } from "./best-action";
import { PowerType } from "../states/Power";
import { LocalizationStrings } from "../ui/localization/definition";

const KEYWORD: LuaObj<boolean> = {
    ["and"]: true,
    ["if"]: true,
    ["not"]: true,
    ["or"]: true,
    ["unless"]: true,
    ["true"]: true,
    ["false"]: true,
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
    for (const [keyword, value] of pairs(SPELL_AURA_KEYWORD)) {
        DECLARATION_KEYWORD[keyword] = value;
    }
    for (const [keyword, value] of pairs(DECLARATION_KEYWORD)) {
        KEYWORD[keyword] = value;
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

const ACTION_PARAMETER_COUNT: Record<ActionType, number> = {
    ["item"]: 1,
    ["macro"]: 1,
    ["spell"]: 1,
    ["texture"]: 1,
    ["setstate"]: 2,
    value: 1,
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
        1: `^(['"]).-\\%1`,
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
            this.ovaleAst.childrenPool.Release(node.child);
        }
        if (node.postOrder) {
            this.ovaleAst.postOrderPool.Release(node.postOrder);
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
            node = this.newValue(annotation, value);
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

    private HasParameters<T extends NodeType, P extends string>(
        node: AstNodeWithParameters<T, P>
    ) {
        return next(node.rawPositionalParams) || next(node.rawNamedParams);
    }

    public Unparse(node: AstNode) {
        if (node.asString) {
            return node.asString;
        } else {
            const visitor = this.UNPARSE_VISITOR[node.type] as UnparserFunction<
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
    private unparseBoolean: UnparserFunction<AstBooleanNode> = (node) => {
        return (node.value && "true") || "false";
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
        const precedence = this.GetPrecedence(node);
        if (node.expressionType == "unary") {
            let rhsExpression;
            const rhsNode = node.child[1];
            const rhsPrecedence = this.GetPrecedence(rhsNode);
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
            const lhsNode = node.child[1];
            const lhsPrecedence = this.GetPrecedence(lhsNode);
            if (lhsPrecedence && lhsPrecedence < precedence) {
                lhsExpression = `{ ${this.Unparse(lhsNode)} }`;
            } else {
                lhsExpression = this.Unparse(lhsNode);
            }
            const rhsNode = node.child[2];
            const rhsPrecedence = this.GetPrecedence(rhsNode);
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

    private unparseAction: UnparserFunction<AstActionNode> = (node) => {
        return format(
            "%s(%s)",
            node.name,
            this.UnparseParameters(
                node.rawPositionalParams,
                node.rawNamedParams,
                true
            )
        );
    };

    private UnparseFunction: UnparserFunction<AstFunctionNode> = (node) => {
        let s;
        if (this.HasParameters(node)) {
            let name;
            const filter = node.rawNamedParams.filter;
            if (filter && this.Unparse(filter) == "debuff") {
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

    private unparseUndefined: UnparserFunction<AstUndefinedNode> = () => {
        return "undefined";
    };

    private unparseTypedFunction: UnparserFunction<AstTypedFunctionNode> = (
        node
    ) => {
        let s;
        if (this.HasParameters(node)) {
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
    private UnparseGroup: UnparserFunction<AstGroupNode> = (node) => {
        const output = this.outputPool.Get();
        output[lualength(output) + 1] = "";
        output[lualength(output) + 1] = `${INDENT(this.indent)}{`;
        this.indent = this.indent + 1;
        for (const [, statementNode] of ipairs(node.child)) {
            const s = this.Unparse(statementNode);
            if (s == "") {
                output[lualength(output) + 1] = s;
            } else {
                output[lualength(output) + 1] = `${INDENT(this.indent)}${s}`;
            }
        }
        this.indent = this.indent - 1;
        output[lualength(output) + 1] = `${INDENT(this.indent)}}`;
        const outputString = concat(output, "\n");
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
        const identifier = (node.name && node.name) || node.itemId;
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
        const identifier = (node.name && node.name) || node.itemId;
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
        namedParams?: RawNamedParameters<string>,
        noFilter?: boolean,
        noTarget?: boolean
    ) {
        const output = this.outputPool.Get();
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
        const output = this.outputPool.Get();
        let previousDeclarationType;
        for (const [, declarationNode] of ipairs(node.child)) {
            if (
                declarationNode.type == "item_info" ||
                declarationNode.type == "spell_aura_list" ||
                declarationNode.type == "spell_info" ||
                declarationNode.type == "spell_require"
            ) {
                const s = this.Unparse(declarationNode);
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
        const outputString = concat(output, "\n");
        this.outputPool.Release(output);
        return outputString;
    };
    private UnparseSpellAuraList: UnparserFunction<AstSpellAuraListNode> = (
        node
    ) => {
        const identifier = node.name || node.spellId;
        const buffName = node.buffName || node.buffSpellId;
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
        const identifier = (node.name && node.name) || node.spellId;
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
        const identifier = (node.name && node.name) || node.spellId;
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
        ["action"]: this.unparseAction,
        ["add_function"]: this.UnparseAddFunction,
        ["arithmetic"]: this.UnparseExpression,
        ["bang_value"]: this.UnparseBangValue,
        ["boolean"]: this.unparseBoolean,
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
        ["typed_function"]: this.unparseTypedFunction,
        ["undefined"]: this.unparseUndefined,
        ["unless"]: this.UnparseUnless,
        ["value"]: this.UnparseValue,
        ["variable"]: this.UnparseVariable,
    };

    private SyntaxError(
        tokenStream: OvaleLexer,
        pattern: string,
        ...__args: unknown[]
    ) {
        this.debug.Warning(pattern, ...__args);
        const context: LuaArray<string> = {
            1: "Next tokens:",
        };
        for (let i = 1; i <= 20; i += 1) {
            const [tokenType, token] = tokenStream.Peek(i);
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
        const bodyNode = this.ParseGroup(tokenStream, annotation);
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
    private ParseAddIcon: ParserFunction<AstIconNode> = (
        tokenStream,
        annotation
    ) => {
        const [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "addicon")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing ADDICON; 'AddIcon' expected.",
                token
            );
            return undefined;
        }
        const [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "addicon",
            annotation,
            0,
            iconParametersCheck
        );
        if (!positionalParams || !namedParams) return undefined;
        const bodyNode = this.ParseGroup(tokenStream, annotation);
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
        const descriptionNode = this.ParseString(tokenStream, annotation);
        if (!descriptionNode) return undefined;

        const [positionalParams, namedParams] = this.ParseParameters(
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
    private ParseComment: ParserFunction<AstCommentNode> = () => {
        return undefined;
    };
    private ParseDeclaration: ParserFunction = (
        tokenStream,
        annotation
    ): AstNode | undefined => {
        let node: AstNode | undefined;
        const [tokenType, token] = tokenStream.Peek();
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
        const node = this.NewNode("define", annotation);
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

        const [tokenType, token] = tokenStream.Peek();
        if (tokenType) {
            const opInfo = UNARY_OPERATOR[token as OperatorType];
            if (opInfo) {
                const [opType, precedence] = [opInfo[1], opInfo[2]];
                tokenStream.Consume();
                const operator: OperatorType = <OperatorType>token;
                const rhsNode = this.ParseExpression(
                    tokenStream,
                    annotation,
                    precedence
                );
                if (rhsNode) {
                    if (operator == "-" && rhsNode.type === "value") {
                        const value = -1 * tonumber(rhsNode.value);
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
            const [tokenType, token] = tokenStream.Peek();
            if (tokenType) {
                const opInfo = BINARY_OPERATOR[token as OperatorType];
                if (opInfo) {
                    const [opType, precedence] = [opInfo[1], opInfo[2]];
                    if (precedence && precedence > minPrecedence) {
                        keepScanning = true;
                        tokenStream.Consume();
                        const operator = <OperatorType>token;
                        const lhsNode = node;
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

    private parseTypedFunction(
        tokenStream: OvaleLexer,
        annotation: AstAnnotation,
        name: string,
        target: string | undefined,
        filter: string | undefined,
        infos: FunctionInfos
    ) {
        if (!this.parseToken(tokenStream, "FUNCTION", "(")) return undefined;

        const [positionalParams, namedParams] = this.ParseParameters(
            tokenStream,
            "function",
            annotation,
            undefined
        );
        if (!positionalParams || !namedParams) return undefined;

        if (!this.parseToken(tokenStream, "FUNCTION", ")")) return undefined;

        if (target) {
            namedParams.target = this.newString(annotation, target);
        }
        if (filter) {
            namedParams.filter = this.newString(annotation, filter);
        }

        if (lualength(positionalParams) > lualength(infos.parameters)) {
            this.SyntaxError(
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
                    this.SyntaxError(
                        tokenStream,
                        "Type error: the %s parameters is named in the %s function although it appears already in the parameters list",
                        key,
                        name
                    );
                    return undefined;
                }
                positionalParams[parameterIndex] = node;
            } else {
                this.SyntaxError(
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
                        this.SyntaxError(
                            tokenStream,
                            "Type error: parameter type unknown in %s function",
                            name
                        );
                        return undefined;
                    }
                } else if (!parameterInfos.optional) {
                    this.SyntaxError(
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
                            this.SyntaxError(
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
        const count = ACTION_PARAMETER_COUNT[name];
        const [positionalParams, namedParams] = this.ParseParameters(
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
        if (STRING_LOOKUP_FUNCTION[name]) {
            annotation.stringReference = annotation.stringReference || {};
            annotation.stringReference[
                lualength(annotation.stringReference) + 1
            ] = node;
        }
        node.asString = this.unparseAction(node);

        if (name === "spell") {
            const parameter = positionalParams[1];
            if (!parameter) {
                this.SyntaxError(
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

    private ParseFunction: ParserFunction<
        AstFunctionNode | AstTypedFunctionNode | AstActionNode
    > = (tokenStream, annotation) => {
        let name;
        {
            const [tokenType, token] = tokenStream.Consume();
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

        if (checkToken(checkActionType, name)) {
            return this.parseAction(tokenStream, annotation, name);
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

        const [positionalParams, namedParams] = this.ParseParameters(
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
        if (STATE_ACTION[name]) {
            nodeType = "state";
        } else if (STRING_LOOKUP_FUNCTION[name]) {
            nodeType = "function";
        } else if (this.ovaleCondition.IsCondition(name)) {
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
        if (STRING_LOOKUP_FUNCTION[name]) {
            annotation.stringReference = annotation.stringReference || {};
            annotation.stringReference[
                lualength(annotation.stringReference) + 1
            ] = node;
        }
        node.asString = this.UnparseFunction(node);
        if (nodeType === "custom_function") {
            annotation.functionCall = annotation.functionCall || {};
            annotation.functionCall[node.name] = true;
        }

        if (
            nodeType === "function" &&
            this.ovaleCondition.IsSpellBookCondition(name)
        ) {
            const parameter = positionalParams[1];
            if (!parameter) {
                this.SyntaxError(
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
        const node = this.newNodeWithChildren("group", annotation);
        const child = node.child;
        [tokenType] = tokenStream.Peek();
        while (tokenType && tokenType != "}") {
            const statementNode = this.ParseStatement(tokenStream, annotation);
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
        const [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "if")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing IF; 'if' expected.",
                token
            );
            return undefined;
        }
        const conditionNode = this.ParseStatement(tokenStream, annotation);
        if (!conditionNode) return undefined;
        const bodyNode = this.ParseStatement(tokenStream, annotation);
        if (!bodyNode) return undefined;
        const node = this.newNodeWithChildren("if", annotation);
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
        const code = this.ovaleScripts.GetScript(name);
        if (code === undefined) {
            this.debug.Error(
                "Script '%s' not found when parsing INCLUDE.",
                name
            );
            return undefined;
        }
        const includeTokenStream = new OvaleLexer(name, code, MATCHES, FILTERS);
        const node = this.ParseScriptStream(
            includeTokenStream,
            nodeList,
            annotation
        );
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
        const [positionalParams, namedParams] = this.ParseParameters(
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
        const property = this.parseCheckedNameToken(
            tokenStream,
            "ITEMREQUIRE",
            checkSpellInfo
        );
        if (!property) return undefined;

        const [positionalParams, namedParams] = this.ParseParameters(
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
        const [positionalParams, namedParams] = this.ParseParameters(
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
    private ParseNumber = (
        tokenStream: OvaleLexer,
        annotation: AstAnnotation
    ): Result<AstValueNode> => {
        let value;
        const [tokenType, token] = tokenStream.Consume();
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
        const node = this.GetNumberNode(value, annotation);
        return node;
    };
    private ParseParameters<T extends string>(
        tokenStream: OvaleLexer,
        methodName: string,
        annotation: AstAnnotation,
        maxNumberOfParameters: number | undefined,
        namedParameters?: KeyCheck<T>
    ): [RawPositionalParameters?, RawNamedParameters<T>?] {
        const positionalParams = this.rawPositionalParametersPool.Get();
        const namedParams = <RawNamedParameters<T>>(
            this.rawNamedParametersPool.Get()
        );
        while (true) {
            const [tokenType] = tokenStream.Peek();
            if (tokenType) {
                const [nextTokenType] = tokenStream.Peek(2);
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
                            const value = -1 * <number>node.value;
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
            const [tokenType, token] = tokenStream.Consume();
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
        const node = this.ParseExpression(tokenStream, annotation);
        if (!node) return undefined;
        const [tokenType, token] = tokenStream.Consume();
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
        const ast = this.newNodeWithChildren("script", annotation);
        const child = ast.child;
        while (true) {
            const [tokenType, token] = tokenStream.Peek();
            if (tokenType) {
                const declarationNode = this.ParseDeclaration(
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
        } else if (
            tokenType === "keyword" &&
            (token === "true" || token === "false")
        ) {
            tokenStream.Consume();
            node = this.newBoolean(annotation, token === "true");
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
        const [tokenType, token] = tokenStream.Consume();
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

    private parseKeywordTokens<T extends string>(
        tokenStream: OvaleLexer,
        methodName: string,
        keyCheck: KeyCheck<T>
    ): T | undefined {
        let keyword;
        const [tokenType, token] = tokenStream.Consume();
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

    private parseKeywordToken<T extends string>(
        tokenStream: OvaleLexer,
        methodName: string,
        keyCheck: T
    ): T | undefined {
        let keyword;
        const [tokenType, token] = tokenStream.Consume();
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

    private parseCheckedNameToken<T extends string>(
        tokenStream: OvaleLexer,
        methodName: string,
        keyCheck: KeyCheck<T>
    ): T | undefined {
        let keyword;
        const [tokenType, token] = tokenStream.Consume();
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

    private parseNameToken(
        tokenStream: OvaleLexer,
        methodName: string
    ): string | undefined {
        let keyword;
        const [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name" && token) {
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
        const keyword = this.parseKeywordTokens(
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
        const [spellId, name] = this.parseNumberOrNameParameter(
            tokenStream,
            "SPELLAURALIST"
        );
        const [buffSpellId, buffName] = this.parseNumberOrNameParameter(
            tokenStream,
            "SPELLAURALIST"
        );

        const [positionalParams, namedParams] = this.ParseParameters(
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
        const [positionalParams, namedParams] = this.ParseParameters(
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
    private ParseSpellRequire: ParserFunction<AstSpellRequireNode> = (
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

        const [positionalParams, namedParams] = this.ParseParameters(
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
    private ParseString: ParserFunction<
        AstStringNode | AstFunctionNode | AstActionNode | AstTypedFunctionNode
    > = (tokenStream, annotation) => {
        let value;
        const [tokenType, token] = tokenStream.Peek();
        if (tokenType == "string" && token) {
            value = token;
            tokenStream.Consume();
        } else if (tokenType == "name" && token) {
            if (STRING_LOOKUP_FUNCTION[lower(token)]) {
                // TODO Maybe have a specific parse function for string
                // lookup functions
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

        const node = this.newString(annotation, value);
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
        const [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "unless")) {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing UNLESS; 'unless' expected.",
                token
            );
            return undefined;
        }
        const conditionNode = this.ParseExpression(tokenStream, annotation);
        if (!conditionNode) return undefined;
        const bodyNode = this.ParseStatement(tokenStream, annotation);
        if (!bodyNode) return undefined;
        const node = this.newNodeWithChildren("unless", annotation);
        node.child[1] = conditionNode;
        node.child[2] = bodyNode;
        return node;
    };
    private ParseVariable: ParserFunction<AstVariableNode> = (
        tokenStream,
        annotation
    ) => {
        let name;
        const [tokenType, token] = tokenStream.Consume();
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

        const node = this.NewNode("variable", annotation);
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
        node.result.constant = true;
        const result = node.result as NodeValueResult;
        result.timeSpan.copyFromArray(UNIVERSE);
        result.type = "value";
        result.value = value;
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
        node.result.constant = true;
        const result = node.result as NodeValueResult;
        result.type = "value";
        result.value = value;
        result.timeSpan.copyFromArray(UNIVERSE);
        result.origin = 0;
        result.rate = 0;
        return node;
    }

    public newBoolean(annotation: AstAnnotation, value: boolean) {
        const node = this.NewNode("boolean", annotation);
        node.value = value;
        node.result.constant = true;
        const result = node.result;
        if (value) {
            result.timeSpan.copyFromArray(UNIVERSE);
        } else {
            wipe(result.timeSpan);
        }
        result.type = "none";
        return node;
    }

    public newUndefined(annotation: AstAnnotation) {
        const node = this.NewNode("undefined", annotation);
        node.result.constant = true;
        node.result.timeSpan.copyFromArray(EMPTY_SET);
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
        const node = this.nodesPool.Get() as NodeTypes[T];
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

    public NewNode<T extends Exclude<NodeType, NodeWithChildrenType>>(
        type: T,
        annotation: AstAnnotation
    ): NodeTypes[T] {
        return this.internalNewNode(type, annotation);
    }

    public NodeToString(node: AstNode) {
        const output = this.print_r(node);
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
        const tokenStream = new OvaleLexer("Ovale", code, MATCHES, {
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
        const code = this.ovaleScripts.GetScriptOrDefault(name);
        if (code) {
            return this.parseScript(code, options);
        } else {
            this.debug.Debug("No code to parse");
            return undefined;
        }
    }

    private getId(name: string, dictionary: LuaObj<string | number>) {
        const itemId = dictionary[name];
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
        this.profiler.StopProfiling("OvaleAST_PropagateConstants");
    }

    public PropagateStrings(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_PropagateStrings");
        if (ast.annotation && ast.annotation.stringReference) {
            for (const [, node] of ipairs(ast.annotation.stringReference)) {
                const nodeAsString = <AstStringNode>node;
                if (node.type === "string") {
                    const key = node.value;
                    const value = L[key as keyof LocalizationStrings];
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
                                L[stringKey as keyof LocalizationStrings] ||
                                stringKey;
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

    private VerifyFunctionCalls(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_VerifyFunctionCalls");
        if (ast.annotation && ast.annotation.verify) {
            const customFunction = ast.annotation.customFunction;
            const functionCall = ast.annotation.functionCall;
            if (functionCall) {
                for (const [name] of pairs(functionCall)) {
                    if (
                        !(
                            checkToken(checkActionType, name) ||
                            STRING_LOOKUP_FUNCTION[name] ||
                            this.ovaleCondition.IsCondition(name) ||
                            (customFunction && customFunction[name])
                        )
                    ) {
                        this.debug.Error("unknown function '%s'.", name);
                    }
                }
            }
        }
        this.profiler.StopProfiling("OvaleAST_VerifyFunctionCalls");
    }

    private InsertPostOrderTraversal(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_InsertPostOrderTraversal");
        const annotation = ast.annotation;
        if (annotation && annotation.postOrderReference) {
            for (const [, node] of ipairs(annotation.postOrderReference)) {
                const array = this.postOrderPool.Get();
                const visited = this.postOrderVisitedPool.Get();
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
        this.profiler.StopProfiling("OvaleAST_CommonSubExpressionElimination");
    }
}
