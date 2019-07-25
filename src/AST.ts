import { L } from "./Localization";
import { OvalePool } from "./Pool";
import { OvaleProfilerClass, Profiler } from "./Profiler";
import { OvaleDebugClass, Tracer } from "./Debug";
import { Tokenizer, TokenizerDefinition } from "./Lexer";
import { OvaleConditionClass } from "./Condition";
import { OvaleLexer, LexerFilter } from "./Lexer";
import { OvaleScriptsClass } from "./Scripts";
import { OvaleSpellBookClass } from "./SpellBook";
import { STANCE_NAME } from "./Stance";
import { LuaArray, LuaObj, ipairs, next, pairs, tonumber, tostring, type, wipe, lualength, kpairs } from "@wowts/lua";
import { format, gsub, lower, sub } from "@wowts/string";
import { concat, insert, sort } from "@wowts/table";
import { GetItemInfo } from "@wowts/wow-mock";
import { isLuaArray, isNumber, isString, checkToken } from "./tools";
import { SpellInfo } from "./Data";
import { HasteType } from "./PaperDoll";

const KEYWORD: LuaObj<boolean> = {
    ["and"]: true,
    ["if"]: true,
    ["not"]: true,
    ["or"]: true,
    ["unless"]: true
}

const DECLARATION_KEYWORD: LuaObj<boolean> = {
    ["AddActionIcon"]: true,
    ["AddCheckBox"]: true,
    ["AddFunction"]: true,
    ["AddIcon"]: true,
    ["AddListItem"]: true,
    ["Define"]: true,
    ["Include"]: true,
    ["ItemInfo"]: true,
    ["ItemRequire"]: true,
    ["ItemList"]: true,
    ["ScoreSpells"]: true,
    ["SpellInfo"]: true,
    ["SpellList"]: true,
    ["SpellRequire"]: true
}
export const PARAMETER_KEYWORD = {
    ["checkbox"]: true,
    ["help"]: true,
    ["if_buff"]: true,
    ["if_equipped"]: true,
    ["if_spell"]: true,
    ["if_stance"]: true,
    ["if_target_debuff"]: true,
    ["itemcount"]: true,
    ["itemset"]: true,
    ["level"]: true,
    ["listitem"]: true,
    ["pertrait"]: true,
    ["specialization"]: true,
    ["talent"]: true,
    ["trait"]: true,
    ["text"]: true,
    ["wait"]: true
}
let SPELL_AURA_KEYWORD: LuaObj<boolean> = {
    ["SpellAddBuff"]: true,
    ["SpellAddDebuff"]: true,
    ["SpellAddPetBuff"]: true,
    ["SpellAddPetDebuff"]: true,
    ["SpellAddTargetBuff"]: true,
    ["SpellAddTargetDebuff"]: true,
    ["SpellDamageBuff"]: true,
    ["SpellDamageDebuff"]: true
}
let STANCE_KEYWORD = {
    ["if_stance"]: true,
    ["stance"]: true,
    ["to_stance"]: true
}
{
    for (const [keyword, value] of pairs(SPELL_AURA_KEYWORD)) {
        DECLARATION_KEYWORD[keyword] = value;
    }
    for (const [keyword, value] of pairs(DECLARATION_KEYWORD)) {
        KEYWORD[keyword] = value;
    }
    for (const [keyword, value] of pairs(PARAMETER_KEYWORD)) {
        KEYWORD[keyword] = value;
    }
}

let ACTION_PARAMETER_COUNT: LuaObj<number> = {
    ["item"]: 1,
    ["macro"]: 1,
    ["spell"]: 1,
    ["texture"]: 1,
    ["setstate"]: 2
}
let STATE_ACTION: LuaObj<boolean> = {
    ["setstate"]: true
}
let STRING_LOOKUP_FUNCTION: LuaObj<boolean> = {
    ["ItemName"]: true,
    ["L"]: true,
    ["SpellName"]: true
}


export type OperatorType = "not" | "or" | "and" | "-" | "=" | "!=" |
    "xor" | "^" | "|" | "==" | "/" | "!" | ">" |
    ">=" | "<=" | "<" | "+" | "*" | "%" | ">?";

let UNARY_OPERATOR: {[key in OperatorType]?:{1: "logical" | "arithmetic", 2: number}} = {
    ["not"]: {
        1: "logical",
        2: 15
    },
    ["-"]: {
        1: "arithmetic",
        2: 50
    }
}
let BINARY_OPERATOR: {[key in OperatorType]?:{1: "logical" | "compare" | "arithmetic", 2: number, 3?: string}} = {
    ["or"]: {
        1: "logical",
        2: 5,
        3: "associative"
    },
    ["xor"]: {
        1: "logical",
        2: 8,
        3: "associative"
    },
    ["and"]: {
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
    ["/"]: {
        1: "arithmetic",
        2: 40
    },
    ["^"]: {
        1: "arithmetic",
        2: 100
    },
    [">?"]: {
        1: "arithmetic",
        2: 25
    }
}

let indent:LuaArray<string> = {};
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
    flattenParametersList?: LuaArray<FlattenParameters>;
    rawNamedParametersList?: LuaArray<RawNamedParameters>;
    objects?: LuaArray<any>;
    nodeList?: LuaArray<AstNode>;
    parametersReference?: LuaArray<AstNode>;
    postOrderReference?: LuaArray<AstNode>;
    customFunction?: LuaObj<AstNode>;
    stringReference?: LuaArray<AstNode>;
    functionCall?: LuaObj<boolean>;
    functionReference?: LuaArray<FunctionNode>;
    nameReference?: LuaArray<AstNode>;
    definition?: LuaObj<any>;
    numberFlyweight?: LuaObj<ValueNode>;
    verify?:boolean;
    functionHash?: LuaObj<AstNode>;
    expressionHash?: LuaObj<AstNode>;
    parametersList?: LuaArray<NamedParameters>;
}

export type NodeType = "function" | "string" | "variable" | "value" | "spell_aura_list" | "item_info" |
     "item_require" | "spell_info" | "spell_require" | "score_spells" |
     "add_function" | "icon" | "script" | "checkbox" | "list_item" | "list" |
     "logical" | "group" | "unless" | "comment" | "if" | "simc_pool_resource" |
     "simc_wait" | "custom_function" | "wait" | "action" | "operand" |
     "logical" | "arithmetic" | "action_list" | "compare" | "boolean" |
     "comma_separated_values" | "bang_value" | "define" | "state";

export interface AstNode {
    child: LuaArray<AstNode>;
    type: NodeType;
    func: string;
    name: string;
    rune: string;
    includeDeath: boolean;
    itemId: number;
    spellId: number;
    key: string;
    previousType: NodeType;
    rawPositionalParams: RawPositionalParameters;
    origin: number;
    rate: number;
    positionalParams:PositionalParameters;
    rawNamedParams: RawNamedParameters;
    namedParams:NamedParameters;
    paramsAsString: string;
    postOrder:LuaArray<AstNode>;
    functionHash: string;
    asString: string;
    nodeId: number;
    secure: boolean;
    operator:OperatorType;
    expressionType:  "unary" | "binary";
    simc_pool_resource:boolean;
    simc_wait: boolean;
    for_next: boolean;
    extra_amount: number;
    comment: string;
    property: keyof SpellInfo;
    keyword: string;
    description: AstNode;
    item?: string;
    precedence: number;
    value?: string | number;

    // ?
    annotation?: AstAnnotation;

    // Not sure (used in EmitActionList)
    action: string;
    asType: "boolean" | "value";
    left: string;
    right: string;
    lowername: string;

    // ---
    powerType: string;
}

export interface FunctionNode extends AstNode {
    func: string;
    type: "state" | "action" | "function" | "custom_function"
}

export interface StringNode extends AstNode {
    type: "string";
    value: string;
}

export function isStringNode(node: AstNode): node is StringNode {
    return node.type === "string";
}

function isCheckBoxParameter(key: string | number, value: Value): value is LuaArray<AstNode> {
    return key === "checkbox";
}

function isListItemParameter(key: string | number, value: Value): value is LuaObj<AstNode> {
    return key === "listitem";
}

function isCheckBoxFlattenParameters(key: string | number, value: FlattenParameterValue | FlattenListParameters | FlattenCheckBoxParameters): value is FlattenCheckBoxParameters {
    return key === "checkbox";
}

function isListItemFlattenParameters(key: string | number, value: FlattenParameterValue | FlattenListParameters | FlattenCheckBoxParameters): value is FlattenListParameters {
    return key === "listitem";
}

interface CsvNode extends AstNode {
    csv?: LuaArray<AstNode>;
    type: "comma_separated_values";   
}

function isCsvNode(node: AstNode): node is CsvNode {
    return node.type === "comma_separated_values";
}

interface VariableNode extends AstNode {
    type: "variable";
    value: string;
}

function isVariableNode(node: AstNode): node is VariableNode {
    return node.type === "variable";
}

export interface ValueNode extends AstNode {
    type: "value";
    value: string | number;
}

export function isValueNode(node: AstNode): node is ValueNode {
    return node.type === "value";
}

interface DefineNode extends AstNode {
    type: "define";
    value: string | number;
}

const TokenizeComment:Tokenizer = function(token) {
    return ["comment", token];
}

// const TokenizeLua:Tokenizer = function(token) {
//     token = strsub(token, 3, -3);
//     return ["lua", token];
// }

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

const TokenizeString:Tokenizer = function(token) {
    token = sub(token, 2, -2);
    return ["string", token];
}
const TokenizeWhitespace:Tokenizer = function(token) {
    return ["space", token];
}

const Tokenize:Tokenizer = function(token) {
    return [token, token];
}
const NoToken:Tokenizer = function() {
    return [undefined, undefined];
}

const MATCHES:LuaArray<TokenizerDefinition> = {
    1: {
        1: "^%s+",
        2: TokenizeWhitespace
    },
    2: {
        1: "^%d+%.?%d*",
        2: TokenizeNumber
    },
    3: {
        1: "^[%a_][%w_]*",
        2: TokenizeName
    },
    4: {
        1: "^((['\"])%2)",
        2: TokenizeString
    },
    5: {
        1: `^(['\"]).-\\%1`,
        2: TokenizeString
    },
    6: {
        1: `^(['\\"]).-[^\\]%1`,
        2: TokenizeString
    },
    7: {
        1: "^#.-\n",
        2: TokenizeComment
    },
    8: {
        1: "^!=",
        2: Tokenize
    },
    9: {
        1: "^==",
        2: Tokenize
    },
    10: {
        1: "^<=",
        2: Tokenize
    },
    11: {
        1: "^>=",
        2: Tokenize
    },
    12: {
        1: "^>%?",
        2: Tokenize,
    },
    13: {
        1: "^.",
        2: Tokenize
    },
    14: {
        1: "^$",
        2: NoToken
    }
}

const FILTERS:LexerFilter = {
    comments: TokenizeComment,
    space: TokenizeWhitespace
}

class SelfPool extends OvalePool<AstNode> {
    constructor(private ovaleAst: OvaleASTClass) {
        super("OvaleAST_pool");
    }

    Clean(node: AstNode): void {
        if (node.child) {
            this.ovaleAst.self_childrenPool.Release(node.child);
            node.child = undefined;
        }
        if (node.postOrder) {
            this.ovaleAst.self_postOrderPool.Release(node.postOrder);
            node.postOrder = undefined;
        }
    }
}

type SimpleValue = string | number | AstNode;
type CheckboxParameters = LuaArray<AstNode>;
type ListParameters =  LuaObj<AstNode>;
type ControlParameters = CheckboxParameters | ListParameters;
type Value = SimpleValue | ControlParameters;
type FlattenListParameters = LuaObj<FlattenParameterValue>;
type FlattenCheckBoxParameters = LuaArray<FlattenParameterValue>;

export interface ConditionNamedParameters {
    if_spell?:number;
    if_equipped?:number;
    if_stance?:number;
    level?:number;
    maxLevel?:number;
    specialization?:number;
    talent?:number;
    trait?:number;
    pertrait?:number;
}

export interface ValuedNamedParameters extends ConditionNamedParameters {
    pertrait?: number;
    nocd?: number;
    flash?: string;
    help?: string;
    soundtime?: number;
    enemies?: number;
    texture?: string;
    itemset?: string;
    itemcount?: number;
    proc?: string;
    buff?: string;
    add_duration?:number;
    add_cd?:number;
    addlist?:string;
    dummy_replace?:string;
    learn?:number;
    shared_cd?:number;
    stance?:number;
    to_stance?:number;
    nored?: number;
    sound?: string;
    text?: string;
    mine?: number;
    offgcd?: number;
    casttime?: number;
    pool_resource?: number;
    size?: "small";
    unlimited?: number;
    wait? :number;
    max?: number;
    extra_amount?: number;
    type?: string;
    any?: number;
    usable?: number;
    haste?: HasteType;
}

export interface NamedParameters extends ValuedNamedParameters {
    // TODO should not be there, see RawNamedParameters
    target?: string;
    filter?: string;
    checkbox?: LuaArray<string | number>;
    listitem?: LuaObj<string | number>;
}

export type PositionalParameters = LuaArray<FlattenParameterValue>;

type BaseRawNamedParameters = {[key in keyof ValuedNamedParameters]: AstNode};

interface RawNamedParameters extends BaseRawNamedParameters {
    filter: AstNode | string;
    target: AstNode | string;
    listitem: LuaObj<AstNode>;
    checkbox: LuaArray<AstNode>;
}

type RawPositionalParameters = LuaArray<AstNode>;

type FlattenParameters = LuaArray<string | number>;
type FlattenParameterValue = FlattenParameters | string | number;
    
type ParserFunction<T = AstNode> = (tokenStream: OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation, minPrecedence?: number) => [boolean, T];
type UnparserFunction = (node: AstNode) => string;

function isAstNode(a: any): a is AstNode {
    return type(a) === "table";
}

export class OvaleASTClass {
    self_indent:number = 0;
    self_outputPool = new OvalePool<LuaArray<string>>("OvaleAST_outputPool");
    self_listPool = new OvalePool<ListParameters>("OvaleAST_listPool");
    self_checkboxPool = new OvalePool<CheckboxParameters>("OvaleAST_checkboxPool");
    self_flattenParameterValuesPool = new OvalePool<LuaArray<FlattenParameterValue>>("OvaleAST_FlattenParameterValues");
    self_namedParametersPool = new OvalePool<NamedParameters>("OvaleAST_parametersPool");
    self_rawNamedParametersPool = new OvalePool<RawNamedParameters>("OvaleAST_rawNamedParametersPool");
    self_positionalParametersPool = new OvalePool<PositionalParameters>("OVALEAST_positionParametersPool");
    self_rawPositionalParametersPool = new OvalePool<RawPositionalParameters>("OVALEAST_rawPositionParametersPool");
    self_flattenParametersPool = new OvalePool<FlattenParameters>("OvaleAST_FlattenParametersPool");
    objectPool = new OvalePool<any>("OvalePool");
    self_childrenPool = new OvalePool<LuaArray<AstNode>>("OvaleAST_childrenPool");
    self_postOrderPool = new OvalePool<LuaArray<AstNode>>("OvaleAST_postOrderPool");
    postOrderVisitedPool = new OvalePool<LuaObj<boolean>>("OvaleAST_postOrderVisitedPool");
    self_pool = new SelfPool(this);
    
    private debug: Tracer;
    private profiler: Profiler;

    constructor(
        private ovaleCondition: OvaleConditionClass, 
        ovaleDebug: OvaleDebugClass,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleScripts: OvaleScriptsClass,
        private ovaleSpellBook: OvaleSpellBookClass) {
        this.debug = ovaleDebug.create("OvaleAST");
        this.profiler = ovaleProfiler.create("OvaleAST");
    }

    OnInitialize(){
    }

    print_r(node: AstNode, indent?: string, done?: LuaObj<boolean>, output?: LuaArray<string>) {
        done = done || {}
        output = output || {}
        indent = indent || '';
        for (const [key, value] of kpairs(node)) {
            if (isAstNode(value)) {
                if (done[value.nodeId]) {
                    insert(output, `${indent}[${ tostring(key)}] => (self_reference)`);
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
                insert(output, `${indent}[${tostring(key)}] => ${tostring(value)}`);
            }
        }
        return output;
    }

    GetNumberNode(value: number, nodeList: LuaArray<AstNode>, annotation: AstAnnotation) {
        annotation.numberFlyweight = annotation.numberFlyweight || {}
        let node = annotation.numberFlyweight[value];
        if (!node) {
            node = <ValueNode>this.NewNode(nodeList);
            node.type = "value";
            node.value = value;
            node.origin = 0;
            node.rate = 0;
            annotation.numberFlyweight[value] = node;
        }
        return node;
    }

    PostOrderTraversal(node: AstNode, array: LuaArray<AstNode>, visited: LuaObj<boolean>) {
        if (node.child) {
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

    /** Flatten a parameter value node into a string (must not be csv) */
    FlattenParameterValueNotCsv(parameterValue: SimpleValue, annotation: AstAnnotation): string | number {
        if (isAstNode(parameterValue)) {
            let node = parameterValue;
            let isBang = false;
            let value: string | number;
            if (node.type == "bang_value") {
                isBang = true;
                node = node.child[1];
            }
            if (isValueNode(node)) {
                value = node.value;
            } else if (node.type == "variable") {
                value = node.name;
            } else if (isStringNode(node)) {
                value = node.value;
            }
            else {
                // TODO not nice at all!
                return <any>parameterValue;
            }
            if (isBang) {
                value = `!${tostring(value)}`;
            }
            return value;
        }
        return parameterValue;
    }

    /** "Flatten" a parameter value node into a string, or a table of strings if it is a comma-separated value. */
    FlattenParameterValue(parameterValue: SimpleValue, annotation: AstAnnotation): FlattenParameterValue {
        if (isAstNode(parameterValue) && isCsvNode(parameterValue)) {
            const parameters = this.self_flattenParametersPool.Get();
            for (const [k, v] of ipairs(parameterValue.csv)) {
                parameters[k] = this.FlattenParameterValueNotCsv(v, annotation);
            }
            annotation.flattenParametersList = annotation.flattenParametersList || {}
            annotation.flattenParametersList[lualength(annotation.flattenParametersList) + 1] = parameters;
            return parameters;
        } else {
           return this.FlattenParameterValueNotCsv(parameterValue, annotation);
        }
    }

    GetPrecedence(node: AstNode) {
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

    HasParameters(node: AstNode) {
        return node.rawPositionalParams && next(node.rawPositionalParams) || node.rawNamedParams && next(node.rawNamedParams);
    }

    Unparse(node: AstNode) {
        if (node.asString) {
            return node.asString;
        } else {
            let visitor;
            if (node.previousType) {
                visitor = this.UNPARSE_VISITOR[node.previousType];
            } else {
                visitor = this.UNPARSE_VISITOR[node.type];
            }
            if (!visitor) {
                this.debug.Error("Unable to unparse node of type '%s'.", node.type);
            } else {
                return visitor(node);
            }
        }
    }

    UnparseAddCheckBox: UnparserFunction = (node) => {
        let s;
        if (node.rawPositionalParams && next(node.rawPositionalParams) || node.rawNamedParams && next(node.rawNamedParams)) {
            s = format("AddCheckBox(%s %s %s)", node.name, this.Unparse(node.description), this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
        } else {
            s = format("AddCheckBox(%s %s)", node.name, this.Unparse(node.description));
        }
        return s;
    }
    UnparseAddFunction: UnparserFunction = (node) => {
        let s;
        if (this.HasParameters(node)) {
            s = format("AddFunction %s %s%s", node.name, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams), this.UnparseGroup(node.child[1]));
        } else {
            s = format("AddFunction %s%s", node.name, this.UnparseGroup(node.child[1]));
        }
        return s;
    }
    UnparseAddIcon: UnparserFunction = (node) => {
        let s;
        if (this.HasParameters(node)) {
            s = format("AddIcon %s%s", this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams), this.UnparseGroup(node.child[1]));
        } else {
            s = format("AddIcon%s", this.UnparseGroup(node.child[1]));
        }
        return s;
    }
    UnparseAddListItem: UnparserFunction = (node) => {
        let s;
        if (this.HasParameters(node)) {
            s = format("AddListItem(%s %s %s %s)", node.name, node.item, this.Unparse(node.description), this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
        } else {
            s = format("AddListItem(%s %s %s)", node.name, node.item, this.Unparse(node.description));
        }
        return s;
    }
    UnparseBangValue: UnparserFunction = (node) => {
        return `!${this.Unparse(node.child[1])}`;
    }
    UnparseComment: UnparserFunction = (node) => {
        if (!node.comment || node.comment == "") {
            return "";
        } else {
            return `#${node.comment}`;
        }
    }
    UnparseCommaSeparatedValues: UnparserFunction = (node: CsvNode) => {
        let output = this.self_outputPool.Get();
        for (const [k, v] of ipairs(node.csv)) {
            output[k] = this.Unparse(v);
        }
        let outputString = concat(output, ",");
        this.self_outputPool.Release(output);
        return outputString;
    }
    UnparseDefine: UnparserFunction = (node: DefineNode) => {
        return format("Define(%s %s)", node.name, node.value);
    }
    UnparseExpression: UnparserFunction = (node) => {
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
                if (BINARY_OPERATOR[node.operator][3] == "associative" && node.operator == rhsNode.operator) {
                    rhsExpression = this.Unparse(rhsNode);
                } else {
                    rhsExpression = `{ ${this.Unparse(rhsNode)} }`;
                }
            } else {
                rhsExpression = this.Unparse(rhsNode);
            }
            expression = `${lhsExpression} ${node.operator} ${rhsExpression}`;
        }
        return expression;
    }
    UnparseFunction: UnparserFunction = (node) => {
        let s;
        if (this.HasParameters(node)) {
            let name;
            let filter = node.rawNamedParams.filter;
            if (filter == "debuff") {
                name = gsub(node.name, "^Buff", "Debuff");
            } else {
                name = node.name;
            }
            let target = node.rawNamedParams.target;
            if (target) {
                s = format("%s.%s(%s)", target, name, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
            } else {
                s = format("%s(%s)", name, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
            }
        } else {
            s = format("%s()", node.name);
        }
        return s;
    }
    UnparseGroup: UnparserFunction = (node) => {
        let output = this.self_outputPool.Get();
        output[lualength(output) + 1] = "";
        output[lualength(output) + 1] = `${INDENT(this.self_indent)}{`;
        this.self_indent = this.self_indent + 1;
        for (const [, statementNode] of ipairs(node.child)) {
            let s = this.Unparse(statementNode);
            if (s == "") {
                output[lualength(output) + 1] = s;
            } else {
                output[lualength(output) + 1] = `${INDENT(this.self_indent)}${s}`;
            }
        }
        this.self_indent = this.self_indent - 1;
        output[lualength(output) + 1] = `${INDENT(this.self_indent)}}`;
        let outputString = concat(output, "\n");
        this.self_outputPool.Release(output);
        return outputString;
    }
    UnparseIf:UnparserFunction = (node) => {
        if (node.child[2].type == "group") {
            return format("if %s%s", this.Unparse(node.child[1]), this.UnparseGroup(node.child[2]));
        } else {
            return format("if %s %s", this.Unparse(node.child[1]), this.Unparse(node.child[2]));
        }
    }
    UnparseItemInfo:UnparserFunction = (node) => {
        let identifier = node.name && node.name || node.itemId;
        return format("ItemInfo(%s %s)", identifier, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseItemRequire: UnparserFunction = (node) => {
        let identifier = node.name && node.name || node.itemId;
        return format("ItemRequire(%s %s %s)", identifier, node.property, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseList:UnparserFunction = (node) => {
        return format("%s(%s %s)", node.keyword, node.name, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseValue:UnparserFunction = (node: ValueNode) => {
        return tostring(node.value);
    }
    UnparseParameters(positionalParams: RawPositionalParameters, namedParams: RawNamedParameters) {
        let output = this.self_outputPool.Get();
        for (const [k, v] of kpairs(namedParams)) {
            if (isListItemParameter(k, v)) {
                for (const [list, item] of pairs(v)) {
                    output[lualength(output) + 1] = format("listitem=%s:%s", list, this.Unparse(item));
                }
            } else if (isCheckBoxParameter(k, v)) {
                for (const [, name] of ipairs(v)) {
                    output[lualength(output) + 1] = format("checkbox=%s", this.Unparse(name));
                }
            } else if (isAstNode(v)) {
                output[lualength(output) + 1] = format("%s=%s", k, this.Unparse(v));
            } else if (k == "filter" || k == "target") {
            } else {
                output[lualength(output) + 1] = format("%s=%s", k, v);
            }
        }
        sort(output);
        for (let k = lualength(positionalParams); k >= 1; k += -1) {
            // TODO suspicious cast
            insert(output, 1, this.Unparse(positionalParams[k]));
        }
        let outputString = concat(output, " ");
        this.self_outputPool.Release(output);
        return outputString;
    }
    UnparseScoreSpells: UnparserFunction = (node) => {
        return format("ScoreSpells(%s)", this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseScript:UnparserFunction = (node: AstNode) => {
        let output = this.self_outputPool.Get();
        let previousDeclarationType;
        for (const [, declarationNode] of ipairs(node.child)) {
            if (declarationNode.type == "item_info" || declarationNode.type == "spell_aura_list" || declarationNode.type == "spell_info" || declarationNode.type == "spell_require") {
                let s = this.Unparse(declarationNode);
                if (s == "") {
                    output[lualength(output) + 1] = s;
                } else {
                    output[lualength(output) + 1] = `${INDENT(this.self_indent + 1)}${s}`;
                }
            } else {
                let insertBlank = false;
                if (previousDeclarationType && previousDeclarationType != declarationNode.type) {
                    insertBlank = true;
                }
                if (declarationNode.type == "add_function" || declarationNode.type == "icon") {
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
        this.self_outputPool.Release(output);
        return outputString;
    }
    UnparseSpellAuraList: UnparserFunction = (node) => {
        let identifier = node.name && node.name || node.spellId;
        return format("%s(%s %s)", node.keyword, identifier, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseSpellInfo: UnparserFunction = (node) => {
        let identifier = node.name && node.name || node.spellId;
        return format("SpellInfo(%s %s)", identifier, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseSpellRequire: UnparserFunction = (node) => {
        let identifier = node.name && node.name || node.spellId;
        return format("SpellRequire(%s %s %s)", identifier, node.property, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseString: UnparserFunction = (node: StringNode) => {
        return `"${node.value}"`;
    }
    UnparseUnless: UnparserFunction = (node) => {
        if (node.child[2].type == "group") {
            return format("unless %s%s", this.Unparse(node.child[1]), this.UnparseGroup(node.child[2]));
        } else {
            return format("unless %s %s", this.Unparse(node.child[1]), this.Unparse(node.child[2]));
        }
    }
    UnparseVariable: UnparserFunction = (node) => {
        return node.name;
    }

    UNPARSE_VISITOR: LuaObj<UnparserFunction> = {
        ["action"]: this.UnparseFunction,
        ["add_function"]: this.UnparseAddFunction,
        ["arithmetic"]: this.UnparseExpression,
        ["bang_value"]: this.UnparseBangValue,
        ["checkbox"]: this.UnparseAddCheckBox,
        ["compare"]: this.UnparseExpression,
        ["comma_separated_values"]: this.UnparseCommaSeparatedValues,
        ["comment"]: this.UnparseComment,
        ["custom_function"]: this.UnparseFunction,
        ["define"]: this.UnparseDefine,
        ["function"]: this.UnparseFunction,
        ["group"]: this.UnparseGroup,
        ["icon"]: this.UnparseAddIcon,
        ["if"]: this.UnparseIf,
        ["item_info"]: this.UnparseItemInfo,
        ["item_require"]: this.UnparseItemRequire,
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
        ["variable"]: this.UnparseVariable
    }

    SyntaxError(tokenStream: OvaleLexer , ...__args: any[]) {
        this.debug.Warning(...__args);
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
        this.debug.Warning(concat(context, " "));
    }

    Parse(nodeType: string, tokenStream: OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation) {
        let visitor = this.PARSE_VISITOR[nodeType];
        if (!visitor) {
            this.debug.Error("Unable to parse node of type '%s'.", nodeType);
        } else {
            return visitor(tokenStream, nodeList, annotation);
        }
    }
    ParseAddCheckBox: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "AddCheckBox")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; 'AddCheckBox' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; '(' expected.", token);
                ok = false;
            }
        }
        let name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; name expected.", token);
                ok = false;
            }
        }
        let descriptionNode;
        if (ok) {
            [ok, descriptionNode] = this.ParseString(tokenStream, nodeList, annotation);
        }
        let positionalParams: RawPositionalParameters, namedParams: RawNamedParameters;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "checkbox";
            node.name = name;
            node.description = descriptionNode;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        }
        return [ok, node];
    }
    ParseAddFunction: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "AddFunction")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; 'AddFunction' expected.", token);
            ok = false;
        }
        let name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        let bodyNode;
        if (ok) {
            [ok, bodyNode] = this.ParseGroup(tokenStream, nodeList, annotation);
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList, true);
            node.type = "add_function";
            node.name = name;
            node.child[1] = bodyNode;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            annotation.postOrderReference = annotation.postOrderReference || {
            }
            annotation.postOrderReference[lualength(annotation.postOrderReference) + 1] = bodyNode;
            annotation.customFunction = annotation.customFunction || {
            }
            annotation.customFunction[name] = node;
        }
        return [ok, node];
    }
    ParseAddIcon: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "AddIcon")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDICON; 'AddIcon' expected.", token);
            ok = false;
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        let bodyNode;
        if (ok) {
            [ok, bodyNode] = this.ParseGroup(tokenStream, nodeList, annotation);
        }
        let node: AstNode;
        if (ok) {
            node = this.NewNode(nodeList, true);
            node.type = "icon";
            node.child[1] = bodyNode;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            annotation.postOrderReference = annotation.postOrderReference || {
            }
            annotation.postOrderReference[lualength(annotation.postOrderReference) + 1] = bodyNode;
        }
        return [ok, node];
    }
    ParseAddListItem: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "AddListItem")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; 'AddListItem' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; '(' expected.", token);
                ok = false;
            }
        }
        let name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.", token);
                ok = false;
            }
        }
        let item;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                item = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.", token);
                ok = false;
            }
        }
        let descriptionNode;
        if (ok) {
            [ok, descriptionNode] = this.ParseString(tokenStream, nodeList, annotation);
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "list_item";
            node.name = name;
            node.item = item;
            node.description = descriptionNode;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        }
        return [ok, node];
    }
    ParseComment: ParserFunction = (tokenStream, nodeList, annotation): [boolean, AstNode] => {
        return undefined;
    }
    ParseDeclaration: ParserFunction = (tokenStream, nodeList, annotation): [boolean, AstNode] => {
        let ok = true;
        let node: AstNode;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType == "keyword" && DECLARATION_KEYWORD[token]) {
            if (token == "AddCheckBox") {
                [ok, node] = this.ParseAddCheckBox(tokenStream, nodeList, annotation);
            } else if (token == "AddFunction") {
                [ok, node] = this.ParseAddFunction(tokenStream, nodeList, annotation);
            } else if (token == "AddIcon") {
                [ok, node] = this.ParseAddIcon(tokenStream, nodeList, annotation);
            } else if (token == "AddListItem") {
                [ok, node] = this.ParseAddListItem(tokenStream, nodeList, annotation);
            } else if (token == "Define") {
                [ok, node] = this.ParseDefine(tokenStream, nodeList, annotation);
            } else if (token == "Include") {
                [ok, node] = this.ParseInclude(tokenStream, nodeList, annotation);
            } else if (token == "ItemInfo") {
                [ok, node] = this.ParseItemInfo(tokenStream, nodeList, annotation);
            } else if (token == "ItemRequire") {
                [ok, node] = this.ParseItemRequire(tokenStream, nodeList, annotation);
            } else if (token == "ItemList") {
                [ok, node] = this.ParseList(tokenStream, nodeList, annotation);
            } else if (token == "ScoreSpells") {
                [ok, node] = this.ParseScoreSpells(tokenStream, nodeList, annotation);
            } else if (SPELL_AURA_KEYWORD[token]) {
                [ok, node] = this.ParseSpellAuraList(tokenStream, nodeList, annotation);
            } else if (token == "SpellInfo") {
                [ok, node] = this.ParseSpellInfo(tokenStream, nodeList, annotation);
            } else if (token == "SpellList") {
                [ok, node] = this.ParseList(tokenStream, nodeList, annotation);
            } else if (token == "SpellRequire") {
                [ok, node] = this.ParseSpellRequire(tokenStream, nodeList, annotation);
            }
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DECLARATION; declaration keyword expected.", token);
            tokenStream.Consume();
            ok = false;
        }
        return [ok, node];
    }
    ParseDefine: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "Define")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; 'Define' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; '(' expected.", token);
                ok = false;
            }
        }
        let name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; name expected.", token);
                ok = false;
            }
        }
        let value: string|number;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "-") {
                [tokenType, token] = tokenStream.Consume();
                if (tokenType == "number") {
                    value = -1 * tonumber(token);
                } else {
                    this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; number expected after '-'.", token);
                    ok = false;
                }
            } else if (tokenType == "number") {
                value = tonumber(token);
            } else if (tokenType == "string") {
                value = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; number or string expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; ')' expected.", token);
                ok = false;
            }
        }
        let node : DefineNode;
        if (ok) {
            node = <DefineNode>this.NewNode(nodeList);
            node.type = "define";
            node.name = name;
            node.value = value;
            annotation.definition = annotation.definition || {}
            annotation.definition[name] = value;
        }
        return [ok, node];
    }
    ParseExpression: ParserFunction = (tokenStream, nodeList, annotation, minPrecedence?) => {
        minPrecedence = minPrecedence || 0;
        let ok = true;
        let node: AstNode;
        {
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType) {
                let opInfo = UNARY_OPERATOR[token as OperatorType];
                if (opInfo) {
                    let [opType, precedence] = [opInfo[1], opInfo[2]];
                    tokenStream.Consume();
                    let operator: OperatorType = <OperatorType>token;
                    let rhsNode: AstNode;
                    [ok, rhsNode] = this.ParseExpression(tokenStream, nodeList, annotation, precedence);
                    if (ok) {
                        if (operator == "-" && isValueNode(rhsNode)) {
                            let value = -1 * tonumber(rhsNode.value);
                            node = this.GetNumberNode(value, nodeList, annotation);
                        } else {
                            node = this.NewNode(nodeList, true);
                            node.type = opType;
                            node.expressionType = "unary";
                            node.operator = operator;
                            node.precedence = precedence;
                            node.child[1] = rhsNode;
                        }
                    }
                } else {
                    [ok, node] = this.ParseSimpleExpression(tokenStream, nodeList, annotation);
                }
            }
        }
        while (ok) {
            let keepScanning = false;
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
                        let rhsNode: AstNode;
                        [ok, rhsNode] = this.ParseExpression(tokenStream, nodeList, annotation, precedence);
                        if (ok) {
                            node = this.NewNode(nodeList, true);
                            node.type = opType;
                            node.expressionType = "binary";
                            node.operator = operator;
                            node.precedence = precedence;

                            node.child[1] = lhsNode;
                            node.child[2] = rhsNode;
                            let rotated = false;
                            while (node.type == rhsNode.type && node.operator == rhsNode.operator && BINARY_OPERATOR[node.operator][3] == "associative" && rhsNode.expressionType == "binary") {
                                node.child[2] = rhsNode.child[1];
                                rhsNode.child[1] = node;
                                node.asString = this.UnparseExpression(node);
                                node = rhsNode;
                                rhsNode = node.child[2];
                                rotated = true;
                            }
                            if (rotated) {
                                node.asString = this.UnparseExpression(node);
                            }
                        }
                    }
                }
            }
            if (!keepScanning) {
                break;
            }
        }
        if (ok && node) {
            node.asString = node.asString || this.Unparse(node);
        }
        return [ok, node];
    }

    ParseFunction: ParserFunction<FunctionNode> = (tokenStream, nodeList, annotation) => {
        let ok = true;
        let name, lowername;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
                lowername = lower(name);
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token);
                ok = false;
            }
        }
        let target;
        if (ok) {
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType == ".") {
                target = name;
                [tokenType, token] = tokenStream.Consume(2);
                if (tokenType == "name") {
                    name = token;
                    lowername = lower(name);
                } else {
                    this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token);
                    ok = false;
                }
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; '(' expected.", token);
                ok = false;
            }
        }
        let positionalParams: RawPositionalParameters, namedParams: RawNamedParameters;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok && ACTION_PARAMETER_COUNT[lowername]) {
            let count = ACTION_PARAMETER_COUNT[lowername];
            if (count > lualength(positionalParams)) {
                this.SyntaxError(tokenStream, "Syntax error: action '%s' requires at least %d fixed parameter(s).", name, count);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            if (!namedParams.target) {
                if (sub(lowername, 1, 6) == "target") {
                    namedParams.target = "target";
                    lowername = sub(lowername, 7);
                    name = sub(name, 7);
                }
            }
            if (!namedParams.filter) {
                if (sub(lowername, 1, 6) == "debuff") {
                    namedParams.filter = "debuff";
                } else if (sub(lowername, 1, 4) == "buff") {
                    namedParams.filter = "buff";
                } else if (sub(lowername, 1, 11) == "otherdebuff") {
                    namedParams.filter = "debuff";
                } else if (sub(lowername, 1, 9) == "otherbuff") {
                    namedParams.filter = "buff";
                }
            }
            if (target) {
                namedParams.target = target;
            }
        }
        let node;
        if (ok) {
            node = <FunctionNode>this.NewNode(nodeList);
            node.name = name;
            node.lowername = lowername;
            if (STATE_ACTION[lowername]) {
                node.type = "state";
                node.func = lowername;
            } else if (ACTION_PARAMETER_COUNT[lowername]) {
                node.type = "action";
                node.func = lowername;
            } else if (STRING_LOOKUP_FUNCTION[name]) {
                node.type = "function";
                node.func = name;
                annotation.stringReference = annotation.stringReference || {}
                annotation.stringReference[lualength(annotation.stringReference) + 1] = node;
            } else if (this.ovaleCondition.IsCondition(lowername)) {
                node.type = "function";
                node.func = lowername;
            } else {
                node.type = "custom_function";
                node.func = name;
            }
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            node.asString = this.UnparseFunction(node);
            annotation.parametersReference = annotation.parametersReference || {};
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            annotation.functionCall = annotation.functionCall || {};
            annotation.functionCall[node.func] = true;
            annotation.functionReference = annotation.functionReference || {};
            annotation.functionReference[lualength(annotation.functionReference) + 1] = node;
        }
        return [ok, node];
    }
    ParseGroup: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "{") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '{' expected.", token);
                ok = false;
            }
        }
        let child = this.self_childrenPool.Get();
        let [tokenType] = tokenStream.Peek();
        while (ok && tokenType && tokenType != "}") {
            let statementNode;
            [ok, statementNode] = this.ParseStatement(tokenStream, nodeList, annotation);
            if (ok) {
                child[lualength(child) + 1] = statementNode;
                [tokenType] = tokenStream.Peek();
            } else {
                break;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "}") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '}' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "group";
            node.child = child;
        } else {
            this.self_childrenPool.Release(child);
        }
        return [ok, node];
    }
    ParseIf: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "if")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing IF; 'if' expected.", token);
                ok = false;
            }
        }
        let conditionNode, bodyNode;
        if (ok) {
            [ok, conditionNode] = this.ParseExpression(tokenStream, nodeList, annotation);
        }
        if (ok) {
            [ok, bodyNode] =this.ParseStatement(tokenStream, nodeList, annotation);
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList, true);
            node.type = "if";
            node.child[1] = conditionNode;
            node.child[2] = bodyNode;
        }
        return [ok, node];
    }
    ParseInclude: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "Include")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; 'Include' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; '(' expected.", token);
                ok = false;
            }
        }
        let name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; script name expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; ')' expected.", token);
                ok = false;
            }
        }
        let code = this.ovaleScripts.GetScript(name);
        if (code === undefined) {
            this.debug.Error("Script '%s' not found when parsing INCLUDE.", name);
            ok = false;
        }
        let node;
        if (ok) {
            let includeTokenStream = new OvaleLexer(name, code, MATCHES, FILTERS);
            [ok, node] = this.ParseScriptStream(includeTokenStream, nodeList, annotation);
            includeTokenStream.Release();
        }
        return [ok, node];
    }
    ParseItemInfo: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        let name;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "ItemInfo")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; 'ItemInfo' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; '(' expected.", token);
                ok = false;
            }
        }
        let itemId;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                itemId = token;
            } else if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; number or name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "item_info";
            node.itemId = tonumber(itemId);
            node.name = name;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            if (name) {
                annotation.nameReference = annotation.nameReference || {
                }
                annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
            }
        }
        return [ok, node];
    }

    ParseItemRequire: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "ItemRequire")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; keyword expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; '(' expected.", token);
                ok = false;
            }
        }
        let itemId, name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                itemId = token;
            } else if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; number or name expected.", token);
                ok = false;
            }
        }
        let property;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                property = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; property name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "item_require";
            node.itemId = tonumber(itemId);
            node.name = name;
            node.property = property as keyof SpellInfo;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {}
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            if (name) {
                annotation.nameReference = annotation.nameReference || {}
                annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
            }
        }
        return [ok, node];
    }
    ParseList: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        let keyword;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "keyword" && (token == "ItemList" || token == "SpellList")) {
                keyword = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; keyword expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; '(' expected.", token);
                ok = false;
            }
        }
        let name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "list";
            node.keyword = keyword;
            node.name = name;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {}
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        }
        return [ok, node];
    }
    ParseNumber = (tokenStream:OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation): [boolean, ValueNode] => {
        let ok = true;
        let value;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                value = tonumber(token);
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing NUMBER; number expected.", token);
                ok = false;
            }
        }
        let node: ValueNode;
        if (ok) {
            node = this.GetNumberNode(value, nodeList, annotation);
        }
        return [ok, node];
    }
    ParseParameterValue: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        let node;
        let tokenType;
        let parameters: LuaArray<AstNode>;
        do {
            [ok, node] = this.ParseSimpleParameterValue(tokenStream, nodeList, annotation);
            if (ok && node) {
                [tokenType] = tokenStream.Peek();
                if (tokenType == ",") {
                    tokenStream.Consume();
                    parameters = parameters || <LuaArray<AstNode>> this.objectPool.Get();
                }
                if (parameters) {
                    parameters[lualength(parameters) + 1] = node;
                }
            }
        }
        while (!(!ok || tokenType != ","));
        if (ok && parameters) {
            node = <CsvNode>this.NewNode(nodeList);
            node.type = "comma_separated_values";
            node.csv = parameters;
            annotation.objects = annotation.objects || {}
            annotation.objects[lualength(annotation.objects) + 1] = parameters;
        }
        return [ok, node];
    }
    ParseParameters(tokenStream: OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation, isList?:boolean): [boolean, RawPositionalParameters, RawNamedParameters] {
        let ok = true;
        let positionalParams = this.self_rawPositionalParametersPool.Get();
        let namedParams = this.self_rawNamedParametersPool.Get();
        while (ok) {
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType) {
                let name: string;
                let node;
                if (tokenType == "name") {
                    [ok, node] = this.ParseVariable(tokenStream, nodeList, annotation);
                    if (ok) {
                        name = node.name;
                    }
                } else if (tokenType == "number") {
                    [ok, node] = this.ParseNumber(tokenStream, nodeList, annotation);
                    if (ok) {
                        name = tostring(node.value);
                    }
                } else if (tokenType == "-") {
                    tokenStream.Consume();
                    [ok, node] = this.ParseNumber(tokenStream, nodeList, annotation);
                    if (ok) {
                        let value = -1 * <number>node.value;
                        node = this.GetNumberNode(value, nodeList, annotation);
                        name = tostring(value);
                    }
                } else if (tokenType == "string") {
                    [ok, node] = this.ParseString(tokenStream, nodeList, annotation);
                    if (ok && isStringNode(node)) {
                        name = node.value;
                    }
                } else if (checkToken(PARAMETER_KEYWORD, token)) {
                    if (isList) {
                        this.SyntaxError(tokenStream, "Syntax error: unexpected keyword '%s' when parsing PARAMETERS; simple expression expected.", token);
                        ok = false;
                    } else {
                        tokenStream.Consume();
                        name = token;
                    }
                } else {
                    break;
                }

                // Check if this is a bare value or the start of a "name=value" pair.
                if (ok && name) {
                    [tokenType, token] = tokenStream.Peek();
                    if (tokenType == "=") {
                        // Consume the '=' token.
                        tokenStream.Consume();
                        const parameterName = name as keyof RawNamedParameters;
                        //if (isListItemParameter(name, np)) {
                        if (parameterName === "listitem") {
                            const np = namedParams[parameterName];
                            //  Consume the list name.
                            let control = np || this.self_listPool.Get();
                            [tokenType, token] = tokenStream.Consume();
                            let list: string;
                            if (tokenType == "name") {
                                list = token;
                            } else {
                                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARAMETERS; name expected.", token);
                                ok = false;
                            }
                            if (ok) {
                                [tokenType, token] = tokenStream.Consume();
                                if (tokenType != ":") {
                                    this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARAMETERS; ':' expected.", token);
                                    ok = false;
                                }
                            }
                            if (ok) {
                                // Consume the list item.
                                [ok, node] = this.ParseSimpleParameterValue(tokenStream, nodeList, annotation);
                            }
                            if (ok && node) {
                                // Check afterwards that the parameter value is only "name" or "!name".
                                if (!(node.type == "variable" || (node.type == "bang_value" && node.child[1].type == "variable"))) {
                                    this.SyntaxError(tokenStream, "Syntax error: 'listitem=%s' parameter with unexpected value '%s'.", this.Unparse(node));
                                    ok = false;
                                }
                            }
                            if (ok) {
                                control[list] = node;
                            }
                            if (!namedParams[parameterName]) {
                                namedParams[parameterName] = control;
                                annotation.listList = annotation.listList || {};
                                annotation.listList[lualength(annotation.listList) + 1] = control;
                            }
                        }
                        else if (name === "checkbox") {
                            // Get the checkbox name.
                            const np = namedParams[name];
                            let control = np || this.self_checkboxPool.Get();
                            [ok, node] = this.ParseSimpleParameterValue(tokenStream, nodeList, annotation);
                            if (ok && node) {
                                // Check afterwards that the parameter value is only "name" or "!name".
                                if (!(node.type == "variable" || (node.type == "bang_value" && node.child[1].type == "variable"))) {
                                    this.SyntaxError(tokenStream, "Syntax error: 'checkbox' parameter with unexpected value '%s'.", this.Unparse(node));
                                    ok = false;
                                }
                            }
                            if (ok) {
                                control[lualength(control) + 1] = node;
                            }
                            if (!namedParams[name]) {
                                namedParams[name] = control;
                                annotation.checkBoxList = annotation.checkBoxList || {};
                                annotation.checkBoxList[lualength(annotation.checkBoxList) + 1] = control;
                            }
                        }                            
                        else {
                            [ok, node] = this.ParseParameterValue(tokenStream, nodeList, annotation);
                            (<any>namedParams[parameterName]) = node;
                        }
                    } else {
                        positionalParams[lualength(positionalParams) + 1] = node;
                    }
                }
            } else {
                break;
            }
        }
        if (ok) {
            annotation.rawPositionalParametersList = annotation.rawPositionalParametersList || {};
            annotation.rawPositionalParametersList[lualength(annotation.rawPositionalParametersList) + 1] = positionalParams;
            annotation.rawNamedParametersList = annotation.rawNamedParametersList || {};
            annotation.rawNamedParametersList[lualength(annotation.rawNamedParametersList) + 1] = namedParams;
        } else {
            positionalParams = undefined;
            namedParams = undefined;
        }
        return [ok, positionalParams, namedParams];
    }
    ParseParentheses(tokenStream: OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation): [boolean, AstNode] {
        let ok = true;
        let leftToken, rightToken;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "(") {
                [leftToken, rightToken] = ["(", ")"];
            } else if (tokenType == "{") {
                [leftToken, rightToken] = ["{", "}"];
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '(' or '{' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            [ok, node] = this.ParseExpression(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != rightToken) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '%s' expected.", token, rightToken);
                ok = false;
            }
        }
        if (ok) {
            node.left = leftToken;
            node.right = rightToken;
        }
        return [ok, node];
    }
    ParseScoreSpells: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "ScoreSpells")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; 'ScoreSpells' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; '(' expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "score_spells";
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        }
        return [ok, node];
    }
    ParseScriptStream: ParserFunction = (tokenStream: OvaleLexer, nodeList, annotation) => {
        this.profiler.StartProfiling("OvaleAST_ParseScript");
        let ok = true;
        let child = this.self_childrenPool.Get();
        while (ok) {
            let [tokenType] = tokenStream.Peek();
            if (tokenType) {
                let declarationNode: AstNode;
                [ok, declarationNode] = this.ParseDeclaration(tokenStream, nodeList, annotation);
                if (ok) {
                    if (declarationNode.type == "script") {
                        for (const [, node] of ipairs(declarationNode.child)) {
                            child[lualength(child) + 1] = node;
                        }
                        this.self_pool.Release(declarationNode);
                    } else {
                        child[lualength(child) + 1] = declarationNode;
                    }
                }
            } else {
                break;
            }
        }
        let ast: AstNode;
        if (ok) {
            ast = this.NewNode();
            ast.type = "script";
            ast.child = child;
        } else {
            this.self_childrenPool.Release(child);
        }
        this.profiler.StopProfiling("OvaleAST_ParseScript");
        return [ok, ast];
    }
    ParseSimpleExpression(tokenStream: OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation): [boolean, AstNode] {
        let ok = true;
        let node;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType == "number") {
            [ok, node] = this.ParseNumber(tokenStream, nodeList, annotation);
        } else if (tokenType == "string") {
            [ok, node] = this.ParseString(tokenStream, nodeList, annotation);
        } else if (tokenType == "name") {
            [tokenType, token] = tokenStream.Peek(2);
            if (tokenType == "." || tokenType == "(") {
                [ok, node] = this.ParseFunction(tokenStream, nodeList, annotation);
            } else {
                [ok, node] = this.ParseVariable(tokenStream, nodeList, annotation);
            }
        } else if (tokenType == "(" || tokenType == "{") {
            [ok, node] = this.ParseParentheses(tokenStream, nodeList, annotation);
        } else {
            tokenStream.Consume();
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION", token);
            ok = false;
        }
        return [ok, node];
    }
    ParseSimpleParameterValue: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        let isBang = false;
        let [tokenType] = tokenStream.Peek();
        if (tokenType == "!") {
            isBang = true;
            tokenStream.Consume();
        }
        let expressionNode;
        [tokenType] = tokenStream.Peek();
        if (tokenType == "(" || tokenType == "-") {
            [ok, expressionNode] = this.ParseExpression(tokenStream, nodeList, annotation);
        } else {
            [ok, expressionNode] = this.ParseSimpleExpression(tokenStream, nodeList, annotation);
        }
        let node;
        if (isBang) {
            node = this.NewNode(nodeList, true);
            node.type = "bang_value";
            node.child[1] = expressionNode;
        } else {
            node = expressionNode;
        }
        return [ok, node];
    }
    ParseSpellAuraList: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        let keyword;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "keyword" && SPELL_AURA_KEYWORD[token]) {
                keyword = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; keyword expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; '(' expected.", token);
                ok = false;
            }
        }
        let spellId, name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                spellId = token;
            } else if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; number or name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; ')' expected.", token);
                ok = false;
            }
        }
        let node: AstNode;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "spell_aura_list";
            node.keyword = keyword;
            node.spellId = tonumber(spellId);
            node.name = name;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {};
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            if (name) {
                annotation.nameReference = annotation.nameReference || {};
                annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
            }
        }
        return [ok, node];
    }
    ParseSpellInfo: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        let name;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "SpellInfo")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; 'SpellInfo' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; '(' expected.", token);
                ok = false;
            }
        }
        let spellId;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                spellId = token;
            } else if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; number or name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "spell_info";
            node.spellId = tonumber(spellId);
            node.name = name;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {};
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            if (name) {
                annotation.nameReference = annotation.nameReference || {};
                annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
            }
        }
        return [ok, node];
    }
    ParseSpellRequire: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "SpellRequire")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; keyword expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; '(' expected.", token);
                ok = false;
            }
        }
        let spellId, name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                spellId = token;
            } else if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; number or name expected.", token);
                ok = false;
            }
        }
        let property;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                property = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; property name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "spell_require";
            node.spellId = tonumber(spellId);
            node.name = name;

            // TODO check all the casts to property names
            node.property = property as keyof SpellInfo;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            if (name) {
                annotation.nameReference = annotation.nameReference || {
                }
                annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
            }
        }
        return [ok, node];
    }
    ParseStatement(tokenStream: OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation): [boolean, AstNode] {
        let ok = true;
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
                if (tokenType) {
                    if (BINARY_OPERATOR[token as OperatorType]) {
                        [ok, node] = this.ParseExpression(tokenStream, nodeList, annotation);
                    } else {
                        [ok, node] = this.ParseGroup(tokenStream, nodeList, annotation);
                    }
                } else {
                    this.SyntaxError(tokenStream, "Syntax error: unexpected end of script.");
                }
            } else if (token == "if") {
                [ok, node] = this.ParseIf(tokenStream, nodeList, annotation);
            } else if (token == "unless") {
                [ok, node] = this.ParseUnless(tokenStream, nodeList, annotation);
            } else {
                [ok, node] = this.ParseExpression(tokenStream, nodeList, annotation);
            }
        }
        return [ok, node];
    }
    ParseString: ParserFunction<StringNode | FunctionNode> = (tokenStream, nodeList, annotation) => {
        let ok = true;
        let value;
        if (ok) {
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType == "string") {
                value = token;
                tokenStream.Consume();
            } else if (tokenType == "name") {
                if (STRING_LOOKUP_FUNCTION[token]) {
                    return this.ParseFunction(tokenStream, nodeList, annotation);
                } else {
                    value = token;
                    tokenStream.Consume();
                }
            } else {
                tokenStream.Consume();
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing STRING; string, variable, or function expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let node: StringNode;
            node = <StringNode>this.NewNode(nodeList);
            node.type = "string";
            node.value = value;
            annotation.stringReference = annotation.stringReference || {};
            annotation.stringReference[lualength(annotation.stringReference) + 1] = node;
            return [ok, node];
        }
        return [false, undefined];
    }
    ParseUnless: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "unless")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing UNLESS; 'unless' expected.", token);
                ok = false;
            }
        }
        let conditionNode, bodyNode;
        if (ok) {
            [ok, conditionNode] = this.ParseExpression(tokenStream, nodeList, annotation);
        }
        if (ok) {
            [ok, bodyNode] = this.ParseStatement(tokenStream, nodeList, annotation);
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList, true);
            node.type = "unless";
            node.child[1] = conditionNode;
            node.child[2] = bodyNode;
        }
        return [ok, node];
    }
    ParseVariable: ParserFunction = (tokenStream, nodeList, annotation) => {
        let ok = true;
        let name;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing VARIABLE; name expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "variable";
            node.name = name;
            annotation.nameReference = annotation.nameReference || {
            }
            annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
        }
        return [ok, node];
    }
    PARSE_VISITOR: LuaObj<ParserFunction> = {
        ["action"]: this.ParseFunction,
        ["add_function"]: this.ParseAddFunction,
        ["arithmetic"]: this.ParseExpression,
        ["bang_value"]: this.ParseSimpleParameterValue,
        ["checkbox"]: this.ParseAddCheckBox,
        ["compare"]: this.ParseExpression,
        ["comment"]: this.ParseComment,
        ["custom_function"]: this.ParseFunction,
        ["define"]: this.ParseDefine,
        ["expression"]: this.ParseExpression,
        ["function"]: this.ParseFunction,
        ["group"]: this.ParseGroup,
        ["icon"]: this.ParseAddIcon,
        ["if"]: this.ParseIf,
        ["item_info"]: this.ParseItemInfo,
        ["item_require"]: this.ParseItemRequire,
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
        ["variable"]: this.ParseVariable
    }


    DebugAST() {
        this.debug.Log(this.self_pool.DebuggingInfo());
        this.debug.Log(this.self_namedParametersPool.DebuggingInfo());
        this.debug.Log(this.self_checkboxPool.DebuggingInfo());
        this.debug.Log(this.self_listPool.DebuggingInfo());
        this.debug.Log(this.self_childrenPool.DebuggingInfo());
        this.debug.Log(this.self_outputPool.DebuggingInfo());
    }

    NewNode(nodeList?: LuaArray<AstNode>, hasChild?: boolean) {
        let node = this.self_pool.Get();
        if (nodeList) {
            let nodeId = lualength(nodeList) + 1;
            node.nodeId = nodeId;
            nodeList[nodeId] = node;
        }
        if (hasChild) {
            node.child = this.self_childrenPool.Get();
        }
        return node;
    }
    NodeToString(node: AstNode) {
        let output = this.print_r(node);
        return concat(output, "\n");
    }
    ReleaseAnnotation(annotation: AstAnnotation) {
        if (annotation.checkBoxList) {
            for (const [, control] of ipairs(annotation.checkBoxList)) {
                this.self_checkboxPool.Release(control);
            }
        }
        if (annotation.listList) {
            for (const [, control] of ipairs(annotation.listList)) {
                this.self_listPool.Release(control);
            }
        }
        if (annotation.objects) {
            for (const [, parameters] of ipairs(annotation.objects)) {
                this.objectPool.Release(parameters);
            }
        }
        if (annotation.rawPositionalParametersList) {
            for (const [, parameters] of ipairs(annotation.rawPositionalParametersList)) {
                this.self_rawPositionalParametersPool.Release(parameters);
            }
        }
        if (annotation.rawNamedParametersList) {
            for (const [, parameters] of ipairs(annotation.rawNamedParametersList)) {
                this.self_rawNamedParametersPool.Release(parameters);
            }
        }
        if (annotation.nodeList) {
            for (const [, node] of ipairs(annotation.nodeList)) {
                this.self_pool.Release(node);
            }
        }
        for (const [, value] of kpairs(annotation)) {
            if (type(value) == "table") {
                wipe(value);
            }
        }
        wipe(annotation);
    }
    Release(ast: AstNode) {
        if (ast.annotation) {
            this.ReleaseAnnotation(ast.annotation);
            ast.annotation = undefined;
        }
        this.self_pool.Release(ast);
    }
    ParseCode(nodeType: string, code: string, nodeList: LuaArray<AstNode>, annotation: AstAnnotation): [AstNode, LuaArray<AstNode>, AstAnnotation] {
        nodeList = nodeList || {}
        annotation = annotation || {}
        let tokenStream = new OvaleLexer("Ovale", code, MATCHES, { comments:  TokenizeComment, space: TokenizeWhitespace });
        let [, node] = this.Parse(nodeType, tokenStream, nodeList, annotation);
        tokenStream.Release();
        return [node, nodeList, annotation];
    }
    ParseScript(name: string, options?: { optimize: boolean, verify: boolean}) {
        let code = this.ovaleScripts.GetScript(name);
        let ast: AstNode;
        if (code) {
            options = options || {
                optimize: true,
                verify: true
            }
            let annotation = {
                nodeList: {
                },
                verify: options.verify
            };
            [ast] = this.ParseCode("script", code, annotation.nodeList, annotation);
            if (ast) {
                ast.annotation = annotation;
                this.PropagateConstants(ast);
                this.PropagateStrings(ast);
                this.FlattenParameters(ast);
                this.VerifyParameterStances(ast);
                this.VerifyFunctionCalls(ast);
                if (options.optimize) {
                    this.Optimize(ast);
                }
                this.InsertPostOrderTraversal(ast);
            } else {
                ast = this.NewNode();
                ast.annotation = annotation;
                this.Release(ast);
                ast = undefined;
            }
        }
        else {
            this.debug.Debug("No code to parse");
        }
        return ast;
    }
    
    PropagateConstants(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_PropagateConstants");
        if (ast.annotation) {
            let dictionary = ast.annotation.definition;
            if (dictionary && ast.annotation.nameReference) {
                for (const [, node] of ipairs<AstNode>(ast.annotation.nameReference)) {
                    const valueNode = <ValueNode>node;
                    if ((node.type == "item_info" || node.type == "item_require") && node.name) {
                        let itemId = dictionary[node.name];
                        if (itemId) {
                            node.itemId = itemId;
                        }
                    } else if ((node.type == "spell_aura_list" || node.type == "spell_info" || node.type == "spell_require") && node.name) {
                        let spellId = dictionary[node.name];
                        if (spellId) {
                            node.spellId = spellId;
                        }
                    } else if (isVariableNode(node)) {
                        let name = node.name;
                        let value = dictionary[name];
                        if (value) {
                            valueNode.previousType = "variable";
                            valueNode.type = "value";
                            valueNode.value = value;
                            valueNode.origin = 0;
                            valueNode.rate = 0;
                        }
                    }
                }
            }
        }
        this.profiler.StopProfiling("OvaleAST_PropagateConstants");
    }
    PropagateStrings(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_PropagateStrings");
        if (ast.annotation && ast.annotation.stringReference) {
            for (const [, node] of ipairs(ast.annotation.stringReference)) {
                const targetNode = <StringNode>node;
                if (isStringNode(node)) {
                    let key = node.value;
                    let value = L[key];
                    if (key != value) {
                        targetNode.value = value;
                        targetNode.key = key;
                    }
                } else if (isVariableNode(node)) {
                    let value = node.name;
                    targetNode.previousType = node.type;
                    targetNode.type = "string";
                    targetNode.value = value;
                } else if (isValueNode(node)) {
                    let value = node.value;
                    targetNode.previousType = "value";
                    targetNode.type = "string";
                    targetNode.value = tostring(value);
                } else if (node.type == "function") {
                    let key = node.rawPositionalParams[1];
                    let stringKey: string;
                    if (isAstNode(key)) {
                        if (isValueNode(key)) {
                            stringKey = tostring(key.value);
                        } else if (isVariableNode(key)) {
                            stringKey = key.name;
                        } else if (isStringNode(key)) {
                            stringKey = key.value;
                        }
                    }
                    else {
                        stringKey = tostring(key);
                    }
                    let value;
                    if (stringKey) {
                        let name = node.name;
                        if (name == "ItemName") {
                            value = GetItemInfo(stringKey) || "item:" + stringKey;
                        } else if (name == "L") {
                            value = L[stringKey];
                        } else if (name == "SpellName") {
                            value = this.ovaleSpellBook.GetSpellName(tonumber(stringKey)) || "spell:" + stringKey;
                        }
                    }
                    if (value) {
                        targetNode.previousType = "function";
                        targetNode.type = "string";
                        targetNode.value = value;
                        targetNode.key = stringKey;
                    }
                }
            }
        }
        this.profiler.StopProfiling("OvaleAST_PropagateStrings");
    }
    FlattenParameters(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_FlattenParameters");
        let annotation = ast.annotation;
        if (annotation && annotation.parametersReference) {
            let dictionary = annotation.definition;
            for (const [, node] of ipairs<AstNode>(annotation.parametersReference)) {
                if (node.rawPositionalParams) {
                    let parameters = this.self_flattenParameterValuesPool.Get();
                    for (const [key, value] of ipairs(node.rawPositionalParams)) {
                        parameters[key] = this.FlattenParameterValue(value, annotation);
                    }
                    node.positionalParams = parameters;
                    annotation.positionalParametersList = annotation.positionalParametersList || {};
                    annotation.positionalParametersList[lualength(annotation.positionalParametersList) + 1] = parameters;
                }
                if (node.rawNamedParams) {
                    const parameters: NamedParameters = this.objectPool.Get();
                    for (const [key] of kpairs(node.rawNamedParams)) {
                        if (key === "listitem") {
                            const control: LuaObj<string | number> = parameters[key] || this.objectPool.Get();
                            const listItems = node.rawNamedParams[key];
                            for (const [list, item] of pairs(listItems)) {
                                control[list] = this.FlattenParameterValueNotCsv(item, annotation);
                            }
                            if (!parameters[key]) {
                                parameters[key] = control;
                                annotation.objects = annotation.objects || {}
                                annotation.objects[lualength(annotation.objects) + 1] = control;
                            }
                        }
                        else if (key === "checkbox") {
                            let control: LuaObj<number | string> = parameters[key] || this.objectPool.Get();
                            const checkBoxItems = node.rawNamedParams[key];
                            for (const [i, name] of ipairs(checkBoxItems)) {
                                control[i] = this.FlattenParameterValueNotCsv(name, annotation);
                            }
                            if (!parameters[key]) {
                                parameters[key] = control;
                                annotation.objects = annotation.objects || {}
                                annotation.objects[lualength(annotation.objects) + 1] = control;
                            }
                        }  else  {
                            const value = node.rawNamedParams[key];
                            const flattenValue = this.FlattenParameterValue(value, annotation);
                            if (type(key) != "number" && dictionary && dictionary[key]) {
                                (<any>parameters[dictionary[key] as keyof typeof parameters]) = flattenValue;
                            } else {
                                // TODO delete named parameters that are not single values
                                (<any>parameters[key]) = flattenValue;
                            }
                        }
                    }
                    node.namedParams = parameters;
                    annotation.parametersList = annotation.parametersList || {}
                    annotation.parametersList[lualength(annotation.parametersList) + 1] = parameters;
                }
                let output = this.self_outputPool.Get();
                for (const [k, v] of kpairs(node.namedParams)) {
                    if (isCheckBoxFlattenParameters(k, v)) {
                        for (const [, name] of ipairs(v)) {
                            output[lualength(output) + 1] = format("checkbox=%s", name);
                        }
                    } else if (isListItemFlattenParameters(k, v)) {
                        for (const [list, item] of ipairs(v)) {
                            output[lualength(output) + 1] = format("listitem=%s:%s", list, item);
                        }
                    } else if (isLuaArray<SimpleValue>(v)) {
                        output[lualength(output) + 1] = format("%s=%s", k, concat(v, ","));
                    } else {
                        output[lualength(output) + 1] = format("%s=%s", k, v);
                    }
                }
                sort(output);
                for (let k = lualength(node.positionalParams); k >= 1; k += -1) {
                    insert(output, 1, node.positionalParams[k]);
                }
                if (lualength(output) > 0) {
                    node.paramsAsString = concat(output, " ");
                } else {
                    node.paramsAsString = "";
                }
                this.self_outputPool.Release(output);
            }
        }
        this.profiler.StopProfiling("OvaleAST_FlattenParameters");
    }
    VerifyFunctionCalls(ast: AstNode) {
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
    VerifyParameterStances(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_VerifyParameterStances");
        let annotation = ast.annotation;
        if (annotation && annotation.verify && annotation.parametersReference) {
            for (const [, node] of ipairs(annotation.parametersReference)) {
                if (node.rawNamedParams) {
                    for (const [stanceKeyword] of kpairs(STANCE_KEYWORD)) {
                        let valueNode = <AstNode> node.rawNamedParams[stanceKeyword];
                        if (valueNode) {
                            if (isCsvNode(valueNode)) {
                                valueNode = valueNode.csv[1];
                            }
                            if (valueNode.type == "bang_value") {
                                valueNode = valueNode.child[1];
                            }
                            let value = this.FlattenParameterValue(valueNode, annotation);
                            if (!isNumber(value)) {
                                if (!isString(value)) {
                                    this.debug.Error("stance must be a string or a number");
                                }
                                else if (!checkToken(STANCE_NAME, value)) {
                                    this.debug.Error("unknown stance '%s'.", value);
                                }
                            }                            
                        }
                    }
                }
            }
        }
        this.profiler.StopProfiling("OvaleAST_VerifyParameterStances");
    }
    InsertPostOrderTraversal(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_InsertPostOrderTraversal");
        let annotation = ast.annotation;
        if (annotation && annotation.postOrderReference) {
            for (const [, node] of ipairs<AstNode>(annotation.postOrderReference)) {
                let array = this.self_postOrderPool.Get();
                let visited = this.postOrderVisitedPool.Get();
                this.PostOrderTraversal(node, array, visited);
                this.postOrderVisitedPool.Release(visited);
                node.postOrder = array;
            }
        }
        this.profiler.StopProfiling("OvaleAST_InsertPostOrderTraversal");
    }
    Optimize(ast: AstNode) {
        this.CommonFunctionElimination(ast);
        this.CommonSubExpressionElimination(ast);
    }
    CommonFunctionElimination(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_CommonFunctionElimination");
        if (ast.annotation) {
            if (ast.annotation.functionReference) {
                let functionHash = ast.annotation.functionHash || {}
                for (const [, node] of ipairs<AstNode>(ast.annotation.functionReference)) {
                    if (node.positionalParams || node.namedParams) {
                        let hash = `${node.name}(${node.paramsAsString})`;
                        node.functionHash = hash;
                        functionHash[hash] = functionHash[hash] || node;
                    }
                }
                ast.annotation.functionHash = functionHash;
            }
            if (ast.annotation.functionHash && ast.annotation.nodeList) {
                let functionHash = ast.annotation.functionHash;
                for (const [, node] of ipairs<AstNode>(ast.annotation.nodeList)) {
                    if (node.child) {
                        for (const [k, childNode] of ipairs(node.child)) {
                            if (childNode.functionHash) {
                                node.child[k] = functionHash[childNode.functionHash];
                            }
                        }
                    }
                }
            }
        }
        this.profiler.StopProfiling("OvaleAST_CommonFunctionElimination");
    }
    CommonSubExpressionElimination(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_CommonSubExpressionElimination");
        if (ast && ast.annotation && ast.annotation.nodeList) {
            let expressionHash: LuaObj<AstNode> = {};
            for (const [, node] of ipairs<AstNode>(ast.annotation.nodeList)) {
                let hash = node.asString;
                if (hash) {
                    expressionHash[hash] = expressionHash[hash] || node;
                }
                if (node.child) {
                    for (const [i, childNode] of ipairs(node.child)) {
                        hash = childNode.asString;
                        if (hash) {
                            let hashNode = expressionHash[hash];
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
