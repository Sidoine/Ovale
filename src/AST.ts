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
import { Result } from "./simulationcraft/definitions";

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
const SPELL_AURA_KEYWORD: LuaObj<boolean> = {
    ["SpellAddBuff"]: true,
    ["SpellAddDebuff"]: true,
    ["SpellAddPetBuff"]: true,
    ["SpellAddPetDebuff"]: true,
    ["SpellAddTargetBuff"]: true,
    ["SpellAddTargetDebuff"]: true,
    ["SpellDamageBuff"]: true,
    ["SpellDamageDebuff"]: true
}
const STANCE_KEYWORD = {
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

const ACTION_PARAMETER_COUNT: LuaObj<number> = {
    ["item"]: 1,
    ["macro"]: 1,
    ["spell"]: 1,
    ["texture"]: 1,
    ["setstate"]: 2
}
const STATE_ACTION: LuaObj<boolean> = {
    ["setstate"]: true
}
const STRING_LOOKUP_FUNCTION: LuaObj<boolean> = {
    ["ItemName"]: true,
    ["L"]: true,
    ["SpellName"]: true
}


export type OperatorType = "not" | "or" | "and" | "-" | "=" | "!=" |
    "xor" | "^" | "|" | "==" | "/" | "!" | ">" |
    ">=" | "<=" | "<" | "+" | "*" | "%" | ">?";

const UNARY_OPERATOR: {[key in OperatorType]?:{1: "logical" | "arithmetic", 2: number}} = {
    ["not"]: {
        1: "logical",
        2: 15
    },
    ["-"]: {
        1: "arithmetic",
        2: 50
    }
}
const BINARY_OPERATOR: {[key in OperatorType]?:{1: "logical" | "compare" | "arithmetic", 2: number, 3?: string}} = {
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

const indent:LuaArray<string> = {};
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
    nodeList: LuaArray<AstNode>;
    parametersReference?: LuaArray<AstNode>;
    postOrderReference?: LuaArray<AstNode>;
    customFunction?: LuaObj<AstNode>;
    stringReference?: LuaArray<AstNode>;
    functionCall?: LuaObj<boolean>;
    functionReference?: LuaArray<FunctionNode>;
    nameReference?: LuaArray<AstNode>;
    definition: LuaObj<any>;
    numberFlyweight?: LuaObj<ValueNode>;
    verify?:boolean;
    functionHash?: LuaObj<AstNode>;
    expressionHash?: LuaObj<AstNode>;
    parametersList?: LuaArray<NamedParameters>;
    sync?: LuaObj<AstNode>;
}

interface NodeTypes {
    function: FunctionNode;
    string: StringNode;
    variable: VariableNode;
    value: ValueNode;
    spell_aura_list: AstNode;
    item_info: AstNode;
    item_require: AstNode;
    spell_info: AstNode;
    spell_require: AstNode;
    score_spells: AstNode;
    add_function: AstNode;
    icon: AstNode;
    script: AstNode;
    checkbox: AstNode;
    list_item: AstNode;
    list: AstNode;
    logical: AstNode;
    group: AstNode;
    unless: AstNode;
    comment: AstNode;
    if: AstNode;
    simc_pool_resource: AstNode;
    simc_wait: AstNode;
    custom_function: FunctionNode;
    wait: AstNode;
    action: FunctionNode;
    operand: AstNode;
    arithmetic: AstNode;
    action_list: AstNode;
    compare: AstNode;
    boolean: AstNode;
    comma_separated_values: CsvNode;
    bang_value: AstNode;
    define: AstNode;
    state: FunctionNode;
    expression: AstNode;
}

export type NodeType = keyof NodeTypes;

export function isNodeType<T extends keyof NodeTypes>(node: AstNode, type:T) : node is NodeTypes[T] {
    return node.type === type;
}

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
    csv: LuaArray<AstNode>;
    type: "comma_separated_values";   
}

function isCsvNode(node: AstNode): node is CsvNode {
    return node.type === "comma_separated_values" || node.previousType === "comma_separated_values";
}

interface VariableNode extends AstNode {
    type: "variable";
    value: string;
}

function isVariableNode(node: AstNode): node is VariableNode {
    return node.type === "variable" || node.previousType === "variable";
}

export interface ValueNode extends AstNode {
    type: "value";
    value: string | number;
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
            this.ovaleAst.childrenPool.Release(node.child);
            delete node.child;
        }
        if (node.postOrder) {
            this.ovaleAst.postOrderPool.Release(node.postOrder);
            delete node.postOrder;
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
    rage?: number;
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
    // TODO This is not a good idea and this should be changed
    filter: AstNode | string;
    target: AstNode | string;
    listitem: LuaObj<AstNode>;
    checkbox: LuaArray<AstNode>;
}

type RawPositionalParameters = LuaArray<AstNode>;

type FlattenParameters = LuaArray<string | number>;
type FlattenParameterValue = FlattenParameters | string | number;
    
type ParserFunction<T = AstNode> = (tokenStream: OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation, minPrecedence?: number) => T | undefined;
type UnparserFunction<T extends AstNode = AstNode> = (node: T) => string;

function isAstNode(a: any): a is AstNode {
    return type(a) === "table";
}

export class OvaleASTClass {
    private indent:number = 0;
    private outputPool = new OvalePool<LuaArray<string>>("OvaleAST_outputPool");
    private listPool = new OvalePool<ListParameters>("OvaleAST_listPool");
    private checkboxPool = new OvalePool<CheckboxParameters>("OvaleAST_checkboxPool");
    private flattenParameterValuesPool = new OvalePool<LuaArray<FlattenParameterValue>>("OvaleAST_FlattenParameterValues");
    private rawNamedParametersPool = new OvalePool<RawNamedParameters>("OvaleAST_rawNamedParametersPool");
    private rawPositionalParametersPool = new OvalePool<RawPositionalParameters>("OVALEAST_rawPositionParametersPool");
    private flattenParametersPool = new OvalePool<FlattenParameters>("OvaleAST_FlattenParametersPool");
    private objectPool = new OvalePool<any>("OvalePool");
    public childrenPool = new OvalePool<LuaArray<AstNode>>("OvaleAST_childrenPool");
    public postOrderPool = new OvalePool<LuaArray<AstNode>>("OvaleAST_postOrderPool");
    private postOrderVisitedPool = new OvalePool<LuaObj<boolean>>("OvaleAST_postOrderVisitedPool");
    private nodesPool = new SelfPool(this);
    
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

    private print_r(node: AstNode, indent?: string, done?: LuaObj<boolean>, output?: LuaArray<string>) {
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

    private GetNumberNode(value: number, nodeList: LuaArray<AstNode>, annotation: AstAnnotation) {
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

    private PostOrderTraversal(node: AstNode, array: LuaArray<AstNode>, visited: LuaObj<boolean>) {
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
    private FlattenParameterValueNotCsv(parameterValue: SimpleValue, annotation: AstAnnotation): string | number {
        if (isAstNode(parameterValue)) {
            let node = parameterValue;
            let isBang = false;
            let value: string | number;
            if (node.type == "bang_value") {
                isBang = true;
                node = node.child[1];
            }
            if (isNodeType(node, "value")) {
                value = node.value;
            } else if (node.type == "variable") {
                value = node.name;
            } else if (isNodeType(node, "string")) {
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
    private FlattenParameterValue(parameterValue: SimpleValue, annotation: AstAnnotation): FlattenParameterValue {
        if (isAstNode(parameterValue) && isCsvNode(parameterValue)) {
            const parameters = this.flattenParametersPool.Get();
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

    private GetPrecedence(node: AstNode) {
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

    private HasParameters(node: AstNode) {
        return node.rawPositionalParams && next(node.rawPositionalParams) || node.rawNamedParams && next(node.rawNamedParams);
    }

    public Unparse(node: AstNode) {
        if (node.asString) {
            return node.asString;
        } else {
            let visitor;
           
            if (node.previousType) {
                visitor = this.UNPARSE_VISITOR[node.previousType] as UnparserFunction<NodeTypes[typeof node.previousType]>;
            } else {
                visitor = this.UNPARSE_VISITOR[node.type] as UnparserFunction<NodeTypes[typeof node.type]>;
            }
            if (!visitor) {
                this.debug.Error("Unable to unparse node of type '%s'.", node.type);
                return `Unkown_${node.type}`;
            } else {
                node.asString = visitor(node as NodeTypes[typeof node.previousType]);
                return node.asString;
            }
        }
    }

    private UnparseAddCheckBox: UnparserFunction = (node) => {
        let s;
        if (node.rawPositionalParams && next(node.rawPositionalParams) || node.rawNamedParams && next(node.rawNamedParams)) {
            s = format("AddCheckBox(%s %s %s)", node.name, this.Unparse(node.description), this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
        } else {
            s = format("AddCheckBox(%s %s)", node.name, this.Unparse(node.description));
        }
        return s;
    }
    private UnparseAddFunction: UnparserFunction = (node) => {
        let s;
        if (this.HasParameters(node)) {
            s = format("AddFunction %s %s%s", node.name, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams), this.UnparseGroup(node.child[1]));
        } else {
            s = format("AddFunction %s%s", node.name, this.UnparseGroup(node.child[1]));
        }
        return s;
    }
    private UnparseAddIcon: UnparserFunction = (node) => {
        let s;
        if (this.HasParameters(node)) {
            s = format("AddIcon %s%s", this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams), this.UnparseGroup(node.child[1]));
        } else {
            s = format("AddIcon%s", this.UnparseGroup(node.child[1]));
        }
        return s;
    }
    private UnparseAddListItem: UnparserFunction = (node) => {
        let s;
        if (this.HasParameters(node)) {
            s = format("AddListItem(%s %s %s %s)", node.name, node.item, this.Unparse(node.description), this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
        } else {
            s = format("AddListItem(%s %s %s)", node.name, node.item, this.Unparse(node.description));
        }
        return s;
    }
    private UnparseBangValue: UnparserFunction = (node) => {
        return `!${this.Unparse(node.child[1])}`;
    }
    private UnparseComment: UnparserFunction = (node) => {
        if (!node.comment || node.comment == "") {
            return "";
        } else {
            return `#${node.comment}`;
        }
    }
    private UnparseCommaSeparatedValues = (node: CsvNode) => {
        let output = this.outputPool.Get();
        for (const [k, v] of ipairs(node.csv)) {
            output[k] = this.Unparse(v);
        }
        let outputString = concat(output, ",");
        this.outputPool.Release(output);
        return outputString;
    }
    private UnparseDefine: UnparserFunction = (node) => {
        return format("Define(%s %s)", node.name, node.value);
    }
    private UnparseExpression: UnparserFunction = (node) => {
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
                if (operatorInfo && operatorInfo[3] == "associative" && node.operator == rhsNode.operator) {
                    rhsExpression = this.Unparse(rhsNode);
                } else {
                    rhsExpression = `{ ${this.Unparse(rhsNode)} }`;
                }
            } else {
                rhsExpression = this.Unparse(rhsNode);
            }
            expression = `${lhsExpression} ${node.operator} ${rhsExpression}`;
        } else {
            this.debug.Error(`node.expressionType '${node.expressionType}' is not known`);
            return "Not_Unparsable";
        }
        return expression;
    }
    private UnparseFunction: UnparserFunction<FunctionNode> = (node) => {
        let s;
        if (this.HasParameters(node)) {
            let name;
            let filter = node.rawNamedParams.filter;
            if (filter == "debuff") {
                name = gsub(node.name, "^Buff", "Debuff");
            } else {
                name = node.lowername;
            }
            let target = node.rawNamedParams.target;
            if (target) {
                s = format("%s.%s(%s)", target, name, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
            } else {
                s = format("%s(%s)", name, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
            }
        } else {
            s = format("%s()", node.lowername);
        }
        return s;
    }
    private UnparseGroup: UnparserFunction = (node) => {
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
    }
    private UnparseIf:UnparserFunction = (node) => {
        if (node.child[2].type == "group") {
            return format("if %s%s", this.Unparse(node.child[1]), this.UnparseGroup(node.child[2]));
        } else {
            return format("if %s %s", this.Unparse(node.child[1]), this.Unparse(node.child[2]));
        }
    }
    private UnparseItemInfo:UnparserFunction = (node) => {
        let identifier = node.name && node.name || node.itemId;
        return format("ItemInfo(%s %s)", identifier, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    private UnparseItemRequire: UnparserFunction = (node) => {
        let identifier = node.name && node.name || node.itemId;
        return format("ItemRequire(%s %s %s)", identifier, node.property, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    private UnparseList:UnparserFunction = (node) => {
        return format("%s(%s %s)", node.keyword, node.name, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    private UnparseValue = (node: ValueNode) => {
        return tostring(node.value);
    }
    private UnparseParameters(positionalParams: RawPositionalParameters, namedParams: RawNamedParameters) {
        let output = this.outputPool.Get();
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
        this.outputPool.Release(output);
        return outputString;
    }
    private UnparseScoreSpells: UnparserFunction = (node) => {
        return format("ScoreSpells(%s)", this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    private UnparseScript:UnparserFunction = (node: AstNode) => {
        let output = this.outputPool.Get();
        let previousDeclarationType;
        for (const [, declarationNode] of ipairs(node.child)) {
            if (declarationNode.type == "item_info" || declarationNode.type == "spell_aura_list" || declarationNode.type == "spell_info" || declarationNode.type == "spell_require") {
                let s = this.Unparse(declarationNode);
                if (s == "") {
                    output[lualength(output) + 1] = s;
                } else {
                    output[lualength(output) + 1] = `${INDENT(this.indent + 1)}${s}`;
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
        this.outputPool.Release(output);
        return outputString;
    }
    private UnparseSpellAuraList: UnparserFunction = (node) => {
        let identifier = node.name && node.name || node.spellId;
        return format("%s(%s %s)", node.keyword, identifier, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    private UnparseSpellInfo: UnparserFunction = (node) => {
        let identifier = node.name && node.name || node.spellId;
        return format("SpellInfo(%s %s)", identifier, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    private UnparseSpellRequire: UnparserFunction = (node) => {
        let identifier = node.name && node.name || node.spellId;
        return format("SpellRequire(%s %s %s)", identifier, node.property, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    private UnparseString = (node: StringNode) => {
        return `"${node.value}"`;
    }
    private UnparseUnless: UnparserFunction = (node) => {
        if (node.child[2].type == "group") {
            return format("unless %s%s", this.Unparse(node.child[1]), this.UnparseGroup(node.child[2]));
        } else {
            return format("unless %s %s", this.Unparse(node.child[1]), this.Unparse(node.child[2]));
        }
    }
    private UnparseVariable: UnparserFunction = (node) => {
        return node.name;
    }

    private UNPARSE_VISITOR: {[key in keyof NodeTypes]?: UnparserFunction<NodeTypes[key]>} = {
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

    private SyntaxError(tokenStream: OvaleLexer , ...__args: any[]) {
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

    private Parse(nodeType: NodeType, tokenStream: OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation):Result<AstNode> {
        const visitor = this.PARSE_VISITOR[nodeType];
        if (!visitor) {
            this.debug.Error("Unable to parse node of type '%s'.", nodeType);
            return undefined;
        } else {
            return visitor(tokenStream, nodeList, annotation);
        }
    }
    private ParseAddCheckBox: ParserFunction = (tokenStream, nodeList, annotation) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "AddCheckBox")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; 'AddCheckBox' expected.", token);
            return undefined;
        }

        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; '(' expected.", token);
            return undefined;
        }
        
        let name = "";
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; name expected.", token);
            return undefined;
        }
        const descriptionNode = this.ParseString(tokenStream, nodeList, annotation);
        if (!descriptionNode) return undefined;

        const [positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        if (!positionalParams || !namedParams) return undefined;

        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; ')' expected.", token);
            return undefined;
        }
        const node = this.NewNode(nodeList);
        node.type = "checkbox";
        node.name = name;
        node.description = descriptionNode;
        node.rawPositionalParams = positionalParams;
        node.rawNamedParams = namedParams;
        annotation.parametersReference = annotation.parametersReference || {};
        annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        return node;
    }
    private ParseAddFunction: ParserFunction = (tokenStream, nodeList, annotation) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "AddFunction")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; 'AddFunction' expected.", token);
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; name expected.", token);
            return undefined;
        }
        const [positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        if (!positionalParams || !namedParams) return undefined;
        let bodyNode = this.ParseGroup(tokenStream, nodeList, annotation);
        if (!bodyNode) return undefined;
        let node;
        node = this.NewNode(nodeList, true);
        node.type = "add_function";
        node.name = name;
        node.child[1] = bodyNode;
        node.rawPositionalParams = positionalParams;
        node.rawNamedParams = namedParams;
        annotation.parametersReference = annotation.parametersReference || {}
        annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        annotation.postOrderReference = annotation.postOrderReference || {}
        annotation.postOrderReference[lualength(annotation.postOrderReference) + 1] = bodyNode;
        annotation.customFunction = annotation.customFunction || {}
        annotation.customFunction[name] = node;
        return node;
    }
    private ParseAddIcon: ParserFunction = (tokenStream, nodeList, annotation) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "AddIcon")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDICON; 'AddIcon' expected.", token);
            return undefined;
        }
        let [positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        if (!positionalParams || !namedParams) return undefined;
        let bodyNode = this.ParseGroup(tokenStream, nodeList, annotation);
        if (!bodyNode) return undefined;
        let node: AstNode;
        node = this.NewNode(nodeList, true);
        node.type = "icon";
        node.child[1] = bodyNode;
        node.rawPositionalParams = positionalParams;
        node.rawNamedParams = namedParams;
        annotation.parametersReference = annotation.parametersReference || {}
        annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        annotation.postOrderReference = annotation.postOrderReference || {}
        annotation.postOrderReference[lualength(annotation.postOrderReference) + 1] = bodyNode;
        return node;
    }
    private ParseAddListItem: ParserFunction = (tokenStream, nodeList, annotation) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "AddListItem")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; 'AddListItem' expected.", token);
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; '(' expected.", token);
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.", token);
            return undefined;
        }
        
        let item;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name") {
            item = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.", token);
            return undefined;
        }
        let descriptionNode = this.ParseString(tokenStream, nodeList, annotation);
        if (!descriptionNode) return undefined;

        let [positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; ')' expected.", token);
            return undefined
        }
        let node;
        node = this.NewNode(nodeList);
        node.type = "list_item";
        node.name = name;
        node.item = item;
        node.description = descriptionNode;
        node.rawPositionalParams = positionalParams;
        node.rawNamedParams = namedParams;
        annotation.parametersReference = annotation.parametersReference || {};
        annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        return node;
    }
    private ParseComment: ParserFunction = (tokenStream, nodeList, annotation): AstNode | undefined => {
        return undefined;
    }
    private ParseDeclaration: ParserFunction = (tokenStream, nodeList, annotation): AstNode | undefined => {
        let node: AstNode | undefined;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType == "keyword" && DECLARATION_KEYWORD[token]) {
            if (token == "AddCheckBox") {
                node = this.ParseAddCheckBox(tokenStream, nodeList, annotation);
            } else if (token == "AddFunction") {
                node = this.ParseAddFunction(tokenStream, nodeList, annotation);
            } else if (token == "AddIcon") {
                node = this.ParseAddIcon(tokenStream, nodeList, annotation);
            } else if (token == "AddListItem") {
                node = this.ParseAddListItem(tokenStream, nodeList, annotation);
            } else if (token == "Define") {
                node = this.ParseDefine(tokenStream, nodeList, annotation);
            } else if (token == "Include") {
                node = this.ParseInclude(tokenStream, nodeList, annotation);
            } else if (token == "ItemInfo") {
                node = this.ParseItemInfo(tokenStream, nodeList, annotation);
            } else if (token == "ItemRequire") {
                node = this.ParseItemRequire(tokenStream, nodeList, annotation);
            } else if (token == "ItemList") {
                node = this.ParseList(tokenStream, nodeList, annotation);
            } else if (token == "ScoreSpells") {
                node = this.ParseScoreSpells(tokenStream, nodeList, annotation);
            } else if (SPELL_AURA_KEYWORD[token]) {
                node = this.ParseSpellAuraList(tokenStream, nodeList, annotation);
            } else if (token == "SpellInfo") {
                node = this.ParseSpellInfo(tokenStream, nodeList, annotation);
            } else if (token == "SpellList") {
                node = this.ParseList(tokenStream, nodeList, annotation);
            } else if (token == "SpellRequire") {
                node = this.ParseSpellRequire(tokenStream, nodeList, annotation);
            }
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DECLARATION; declaration keyword expected.", token);
            tokenStream.Consume();
            return undefined;
        }
        return node;
    }
    private ParseDefine: ParserFunction = (tokenStream, nodeList, annotation) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "Define")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; 'Define' expected.", token);
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; '(' expected.", token);
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; name expected.", token);
            return undefined;
        }
        let value: string|number;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "-") {
            [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                value = -1 * tonumber(token);
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; number expected after '-'.", token);
                return undefined;
            }
        } else if (tokenType == "number") {
            value = tonumber(token);
        } else if (tokenType == "string") {
            value = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; number or string expected.", token);
            return undefined;
        }
        
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; ')' expected.", token);
            return undefined;
        }
        let node : DefineNode;
        node = <DefineNode>this.NewNode(nodeList);
        node.type = "define";
        node.name = name;
        node.value = value;
        annotation.definition = annotation.definition || {}
        annotation.definition[name] = value;
        return node;
    }
    private ParseExpression: ParserFunction = (tokenStream, nodeList, annotation, minPrecedence?) => {
        minPrecedence = minPrecedence || 0;
        let node: AstNode;
        
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType) {
            let opInfo = UNARY_OPERATOR[token as OperatorType];
            if (opInfo) {
                let [opType, precedence] = [opInfo[1], opInfo[2]];
                tokenStream.Consume();
                let operator: OperatorType = <OperatorType>token;
                const rhsNode = this.ParseExpression(tokenStream, nodeList, annotation, precedence);
                if (rhsNode) {
                    if (operator == "-" && isNodeType(rhsNode, "value")) {
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
                } else {
                    return undefined;
                }
                
            } else {
                const simpleExpression = this.ParseSimpleExpression(tokenStream, nodeList, annotation);
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
                        let rhsNode = this.ParseExpression(tokenStream, nodeList, annotation, precedence);
                        if (rhsNode) {
                            node = this.NewNode(nodeList, true);
                            node.type = opType;
                            node.expressionType = "binary";
                            node.operator = operator;
                            node.precedence = precedence;

                            node.child[1] = lhsNode;
                            node.child[2] = rhsNode;
                            const operatorInfo = BINARY_OPERATOR[node.operator];
                            if (!operatorInfo) return undefined;
                            while (node.type == rhsNode.type && node.operator == rhsNode.operator && operatorInfo[3] == "associative" && rhsNode.expressionType == "binary") {
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
    }

    private ParseFunction: ParserFunction<FunctionNode> = (tokenStream, nodeList, annotation) => {
        let name, lowername;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
                lowername = lower(name);
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token);
                return undefined;
            }
        }
        let target;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType == ".") {
            target = name;
            [tokenType, token] = tokenStream.Consume(2);
            if (tokenType == "name") {
                name = token;
                lowername = lower(name);
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token);
                return undefined;
            }
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; '(' expected.", token);
            return undefined;
        }
        let [positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        if (!positionalParams || !namedParams) return undefined;
        if (ACTION_PARAMETER_COUNT[lowername]) {
            let count = ACTION_PARAMETER_COUNT[lowername];
            if (count > lualength(positionalParams)) {
                this.SyntaxError(tokenStream, "Syntax error: action '%s' requires at least %d fixed parameter(s).", name, count);
                return undefined;
            }
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.", token);
            return undefined;
        }
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
        let node;
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
        return node;
    }
    private ParseGroup: ParserFunction = (tokenStream, nodeList, annotation) => {
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType != "{") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '{' expected.", token);
            return undefined;
        }
        let child = this.childrenPool.Get();
        [tokenType] = tokenStream.Peek();
        while (tokenType && tokenType != "}") {
            let statementNode;
            statementNode = this.ParseStatement(tokenStream, nodeList, annotation);
            if (statementNode) {
                child[lualength(child) + 1] = statementNode;
                [tokenType] = tokenStream.Peek();
            } else {
                return undefined;
            }
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "}") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '}' expected.", token);
            this.childrenPool.Release(child);
            return undefined;
        }
        let node;
        node = this.NewNode(nodeList);
        node.type = "group";
        node.child = child;
        return node;
    }
    private ParseIf: ParserFunction = (tokenStream, nodeList, annotation) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "if")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing IF; 'if' expected.", token);
            return undefined;
        }
        let conditionNode, bodyNode;
        conditionNode = this.ParseExpression(tokenStream, nodeList, annotation);
        if (!conditionNode) return undefined;
        bodyNode = this.ParseStatement(tokenStream, nodeList, annotation);
        if (!bodyNode) return undefined;
        let node;
        node = this.NewNode(nodeList, true);
        node.type = "if";
        node.child[1] = conditionNode;
        node.child[2] = bodyNode;
        return node;
    }
    private ParseInclude: ParserFunction = (tokenStream, nodeList, annotation) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "Include")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; 'Include' expected.", token);
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; '(' expected.", token);
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; script name expected.", token);
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; ')' expected.", token);
            return undefined;
        }
        let code = this.ovaleScripts.GetScript(name);
        if (code === undefined) {
            this.debug.Error("Script '%s' not found when parsing INCLUDE.", name);
            return undefined;
        }
        let node;
        let includeTokenStream = new OvaleLexer(name, code, MATCHES, FILTERS);
        node = this.ParseScriptStream(includeTokenStream, nodeList, annotation);
        includeTokenStream.Release();
        return node;
    }
    private ParseItemInfo: ParserFunction = (tokenStream, nodeList, annotation) => {
        let name;
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "ItemInfo")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; 'ItemInfo' expected.", token);
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; '(' expected.", token);
            return undefined;
        }
        let itemId;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "number") {
            itemId = token;
        } else if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; number or name expected.", token);
            return undefined;
        }
        let [positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; ')' expected.", token);
            return undefined;
        }
        let node;
        node = this.NewNode(nodeList);
        node.type = "item_info";
        node.itemId = tonumber(itemId);
        if (name) node.name = name;
        node.rawPositionalParams = positionalParams;
        node.rawNamedParams = namedParams;
        annotation.parametersReference = annotation.parametersReference || {};
        annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        if (name) {
            annotation.nameReference = annotation.nameReference || {};
            annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
        }
        return node;
    }

    private ParseItemRequire: ParserFunction = (tokenStream, nodeList, annotation) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "ItemRequire")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; keyword expected.", token);
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; '(' expected.", token);
            return undefined;
        }
        let itemId, name;
    
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "number") {
            itemId = token;
        } else if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; number or name expected.", token);
            return undefined;
        }
        let property;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name") {
            property = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; property name expected.", token);
            return undefined;
        }
        let [positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; ')' expected.", token);
            return undefined;
        }
        let node;
        node = this.NewNode(nodeList);
        node.type = "item_require";
        node.itemId = tonumber(itemId);
        if (name) node.name = name;
        node.property = property as keyof SpellInfo;
        node.rawPositionalParams = positionalParams;
        node.rawNamedParams = namedParams;
        annotation.parametersReference = annotation.parametersReference || {}
        annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        if (name) {
            annotation.nameReference = annotation.nameReference || {}
            annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
        }
        return node;
    }
    private ParseList: ParserFunction = (tokenStream, nodeList, annotation) => {
        let keyword;
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "keyword" && (token == "ItemList" || token == "SpellList")) {
            keyword = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; keyword expected.", token);
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; '(' expected.", token);
            return undefined;
        }
        let name;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; name expected.", token);
            return undefined;
        }
        let [positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; ')' expected.", token);
            return undefined;
        }
        let node;
        node = this.NewNode(nodeList);
        node.type = "list";
        node.keyword = keyword;
        node.name = name;
        node.rawPositionalParams = positionalParams;
        node.rawNamedParams = namedParams;
        annotation.parametersReference = annotation.parametersReference || {}
        annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        return node;
    }
    private ParseNumber = (tokenStream:OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation): Result<ValueNode> => {
        let value;
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "number") {
            value = tonumber(token);
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing NUMBER; number expected.", token);
            return undefined;
        }
        let node = this.GetNumberNode(value, nodeList, annotation);
        return node;
    }
    private ParseParameterValue: ParserFunction = (tokenStream, nodeList, annotation) => {
        let node;
        let tokenType;
        let parameters: LuaArray<AstNode> | undefined;
        do {
            node = this.ParseSimpleParameterValue(tokenStream, nodeList, annotation);
            if (node) {
                [tokenType] = tokenStream.Peek();
                if (tokenType == ",") {
                    tokenStream.Consume();
                    parameters = parameters || <LuaArray<AstNode>> this.objectPool.Get();
                }
                if (parameters) {
                    parameters[lualength(parameters) + 1] = node;
                }
            } else {
                return undefined;
            }
        }
        while (!(node || tokenType != ","));
        if (parameters) {
            node = <CsvNode>this.NewNode(nodeList);
            node.type = "comma_separated_values";
            node.csv = parameters;
            annotation.objects = annotation.objects || {}
            annotation.objects[lualength(annotation.objects) + 1] = parameters;
        }
        return node;
    }
    private ParseParameters(tokenStream: OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation, isList?:boolean): [RawPositionalParameters?, RawNamedParameters?] {
        let positionalParams = this.rawPositionalParametersPool.Get();
        let namedParams = this.rawNamedParametersPool.Get();
        while (true) {
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType) {
                let name: string;
                let node;
                if (tokenType == "name") {
                    node = this.ParseVariable(tokenStream, nodeList, annotation);
                    if (node) {
                        name = node.name;
                    } else {
                        return [];
                    }
                } else if (tokenType == "number") {
                    node = this.ParseNumber(tokenStream, nodeList, annotation);
                    if (node) {
                        name = tostring(node.value);
                    } else {
                        return [];
                    }
                } else if (tokenType == "-") {
                    tokenStream.Consume();
                    node = this.ParseNumber(tokenStream, nodeList, annotation);
                    if (node) {
                        let value = -1 * <number>node.value;
                        node = this.GetNumberNode(value, nodeList, annotation);
                        name = tostring(value);
                    } else {
                        return [];
                    }
                } else if (tokenType == "string") {
                    node = this.ParseString(tokenStream, nodeList, annotation);
                    if (node && isNodeType(node, "string")) {
                        name = node.value;
                    } else {
                        return [];
                    }
                } else if (checkToken(PARAMETER_KEYWORD, token)) {
                    if (isList) {
                        this.SyntaxError(tokenStream, "Syntax error: unexpected keyword '%s' when parsing PARAMETERS; simple expression expected.", token);
                        return [];
                    } else {
                        tokenStream.Consume();
                        name = token;
                    }
                } else {
                    break;
                }

                // Check if this is a bare value or the start of a "name=value" pair.
                if (name) {
                    [tokenType, token] = tokenStream.Peek();
                    if (tokenType == "=") {
                        // Consume the '=' token.
                        tokenStream.Consume();
                        const parameterName = name as keyof RawNamedParameters;
                        //if (isListItemParameter(name, np)) {
                        if (parameterName === "listitem") {
                            const np = namedParams[parameterName];
                            //  Consume the list name.
                            let control = np || this.listPool.Get();
                            [tokenType, token] = tokenStream.Consume();
                            let list: string;
                            if (tokenType == "name") {
                                list = token;
                            } else {
                                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARAMETERS; name expected.", token);
                                return [];
                            }
                            [tokenType, token] = tokenStream.Consume();
                            if (tokenType != ":") {
                                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARAMETERS; ':' expected.", token);
                                return [];
                            }
                            // Consume the list item.
                            node = this.ParseSimpleParameterValue(tokenStream, nodeList, annotation);
                            if (!node) return [];
                            // Check afterwards that the parameter value is only "name" or "!name".
                            if (!(node.type == "variable" || (node.type == "bang_value" && node.child[1].type == "variable"))) {
                                this.SyntaxError(tokenStream, "Syntax error: 'listitem=%s' parameter with unexpected value '%s'.", this.Unparse(node));
                                return [];
                            }
                            control[list] = node;
                            if (!namedParams[parameterName]) {
                                namedParams[parameterName] = control;
                                annotation.listList = annotation.listList || {};
                                annotation.listList[lualength(annotation.listList) + 1] = control;
                            }
                        }
                        else if (name === "checkbox") {
                            // Get the checkbox name.
                            const np = namedParams[name];
                            let control = np || this.checkboxPool.Get();
                            node = this.ParseSimpleParameterValue(tokenStream, nodeList, annotation);
                            if (!node) return [];
                            // Check afterwards that the parameter value is only "name" or "!name".
                            if (!(node.type == "variable" || (node.type == "bang_value" && node.child[1].type == "variable"))) {
                                this.SyntaxError(tokenStream, "Syntax error: 'checkbox' parameter with unexpected value '%s'.", this.Unparse(node));
                                return [];
                            }
                            control[lualength(control) + 1] = node;
                            if (!namedParams[name]) {
                                namedParams[name] = control;
                                annotation.checkBoxList = annotation.checkBoxList || {};
                                annotation.checkBoxList[lualength(annotation.checkBoxList) + 1] = control;
                            }
                        }                            
                        else {
                            node = this.ParseParameterValue(tokenStream, nodeList, annotation);
                            if (!node) return [];
                            (<any>namedParams[parameterName]) = node;
                        }
                    } else {
                        if (!node) return [];
                        positionalParams[lualength(positionalParams) + 1] = node;
                    }
                }
            } else {
                break;
            }
        }
        annotation.rawPositionalParametersList = annotation.rawPositionalParametersList || {};
        annotation.rawPositionalParametersList[lualength(annotation.rawPositionalParametersList) + 1] = positionalParams;
        annotation.rawNamedParametersList = annotation.rawNamedParametersList || {};
        annotation.rawNamedParametersList[lualength(annotation.rawNamedParametersList) + 1] = namedParams;
        return [positionalParams, namedParams];
    }
    private ParseParentheses(tokenStream: OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation): AstNode | undefined {
        let leftToken, rightToken;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "(") {
                [leftToken, rightToken] = ["(", ")"];
            } else if (tokenType == "{") {
                [leftToken, rightToken] = ["{", "}"];
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '(' or '{' expected.", token);
                return undefined;
            }
        }
        let node = this.ParseExpression(tokenStream, nodeList, annotation);
        if (!node) return undefined;
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType != rightToken) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '%s' expected.", token, rightToken);
            return undefined;
        }
        node.left = leftToken;
        node.right = rightToken;
        return node;
    }
    private ParseScoreSpells: ParserFunction = (tokenStream, nodeList, annotation) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "ScoreSpells")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; 'ScoreSpells' expected.", token);
            return undefined;
        }

        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; '(' expected.", token);
            return undefined;
        }

        const [positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        if (!positionalParams || !namedParams) return undefined;

        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; ')' expected.", token);
            return undefined;
        }
        const node = this.NewNode(nodeList);
        node.type = "score_spells";
        node.rawPositionalParams = positionalParams;
        node.rawNamedParams = namedParams;
        annotation.parametersReference = annotation.parametersReference || {
        }
        annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        return node;
    }
    private ParseScriptStream: ParserFunction = (tokenStream: OvaleLexer, nodeList, annotation) => {
        this.profiler.StartProfiling("OvaleAST_ParseScript");
        let child = this.childrenPool.Get();
        while (true) {
            let [tokenType] = tokenStream.Peek();
            if (tokenType) {
                let declarationNode = this.ParseDeclaration(tokenStream, nodeList, annotation);
                if (!declarationNode) {
                    this.childrenPool.Release(child);
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
        let ast: AstNode;
        ast = this.NewNode();
        ast.type = "script";
        ast.child = child;
        this.profiler.StopProfiling("OvaleAST_ParseScript");
        return ast;
    }
    private ParseSimpleExpression(tokenStream: OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation): AstNode | undefined {
        let node;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType == "number") {
            node = this.ParseNumber(tokenStream, nodeList, annotation);
        } else if (tokenType == "string") {
            node = this.ParseString(tokenStream, nodeList, annotation);
        } else if (tokenType == "name") {
            [tokenType, token] = tokenStream.Peek(2);
            if (tokenType == "." || tokenType == "(") {
                node = this.ParseFunction(tokenStream, nodeList, annotation);
            } else {
                node = this.ParseVariable(tokenStream, nodeList, annotation);
            }
        } else if (tokenType == "(" || tokenType == "{") {
            node = this.ParseParentheses(tokenStream, nodeList, annotation);
        } else {
            tokenStream.Consume();
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION", token);
            return undefined;
        }
        return node;
    }
    private ParseSimpleParameterValue: ParserFunction = (tokenStream, nodeList, annotation) => {
        let isBang = false;
        let [tokenType] = tokenStream.Peek();
        if (tokenType == "!") {
            isBang = true;
            tokenStream.Consume();
        }
        let expressionNode;
        [tokenType] = tokenStream.Peek();
        if (tokenType == "(" || tokenType == "-") {
            expressionNode = this.ParseExpression(tokenStream, nodeList, annotation);
        } else {
            expressionNode = this.ParseSimpleExpression(tokenStream, nodeList, annotation);
        }
        if (!expressionNode) return undefined;
        let node;
        if (isBang) {
            node = this.NewNode(nodeList, true);
            node.type = "bang_value";
            node.child[1] = expressionNode;
        } else {
            node = expressionNode;
        }
        return node;
    }
    private ParseSpellAuraList: ParserFunction = (tokenStream, nodeList, annotation) => {
        let keyword;
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "keyword" && SPELL_AURA_KEYWORD[token]) {
            keyword = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; keyword expected.", token);
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; '(' expected.", token);
            return undefined;
        }
        let spellId, name;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "number") {
            spellId = tonumber(token);
        } else if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; number or name expected.", token);
            return undefined;
        }
        let [positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; ')' expected.", token);
            return undefined;
        }
        let node: AstNode;
        node = this.NewNode(nodeList);
        node.type = "spell_aura_list";
        node.keyword = keyword;
        if (spellId) node.spellId = spellId;
        if (name) node.name = name;
        node.rawPositionalParams = positionalParams;
        node.rawNamedParams = namedParams;
        annotation.parametersReference = annotation.parametersReference || {};
        annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        if (name) {
            annotation.nameReference = annotation.nameReference || {};
            annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
        }
        return node;
    }
    private ParseSpellInfo: ParserFunction = (tokenStream, nodeList, annotation) => {
        let name;
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "SpellInfo")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; 'SpellInfo' expected.", token);
            return undefined;
        }
        
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; '(' expected.", token);
            return undefined;
        }
        let spellId;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "number") {
            spellId = tonumber(token);
        } else if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; number or name expected.", token);
            return undefined;
        }
        let [positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; ')' expected.", token);
            return undefined;
        }
        let node;
        node = this.NewNode(nodeList);
        node.type = "spell_info";
        if (spellId) node.spellId = spellId;
        if (name) node.name = name;
        node.rawPositionalParams = positionalParams;
        node.rawNamedParams = namedParams;
        annotation.parametersReference = annotation.parametersReference || {};
        annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        if (name) {
            annotation.nameReference = annotation.nameReference || {};
            annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
        }
        return node;
    }
    private ParseSpellRequire: ParserFunction = (tokenStream, nodeList, annotation) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "SpellRequire")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; keyword expected.", token);
            return undefined;
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != "(") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; '(' expected.", token);
            return undefined;
        }
        let spellId, name;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "number") {
            spellId = tonumber(token);
        } else if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; number or name expected.", token);
            return undefined;
        }
        let property;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name") {
            property = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; property name expected.", token);
            return undefined;
        }
        let [positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        if (!positionalParams || !namedParams) return undefined;
        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; ')' expected.", token);
            return undefined;
        }
        let node;
        node = this.NewNode(nodeList);
        node.type = "spell_require";
        if (spellId) node.spellId = spellId;
        if (name) node.name = name;

        // TODO check all the casts to property names
        node.property = property as keyof SpellInfo;
        node.rawPositionalParams = positionalParams;
        node.rawNamedParams = namedParams;
        annotation.parametersReference = annotation.parametersReference || {};
        annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        if (name) {
            annotation.nameReference = annotation.nameReference || {};
            annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
        }
        return node;
    }
    private ParseStatement(tokenStream: OvaleLexer, nodeList: LuaArray<AstNode>, annotation: AstAnnotation): AstNode | undefined {
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
                        node = this.ParseExpression(tokenStream, nodeList, annotation);
                    } else {
                        node = this.ParseGroup(tokenStream, nodeList, annotation);
                    }
                } else {
                    this.SyntaxError(tokenStream, "Syntax error: unexpected end of script.");
                }
            } else if (token == "if") {
                node = this.ParseIf(tokenStream, nodeList, annotation);
            } else if (token == "unless") {
                node = this.ParseUnless(tokenStream, nodeList, annotation);
            } else {
                node = this.ParseExpression(tokenStream, nodeList, annotation);
            }
        }
        return node;
    }
    private ParseString: ParserFunction<StringNode | FunctionNode> = (tokenStream, nodeList, annotation) => {
        let value;
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
            return undefined;
        }
        
        let node: StringNode;
        node = <StringNode>this.NewNode(nodeList);
        node.type = "string";
        node.value = value;
        annotation.stringReference = annotation.stringReference || {};
        annotation.stringReference[lualength(annotation.stringReference) + 1] = node;
        return node;
    }
    private ParseUnless: ParserFunction = (tokenStream, nodeList, annotation) => {
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "unless")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing UNLESS; 'unless' expected.", token);
            return undefined;
        }
        let conditionNode, bodyNode;
        conditionNode = this.ParseExpression(tokenStream, nodeList, annotation);
        if (!conditionNode) return undefined;
        bodyNode = this.ParseStatement(tokenStream, nodeList, annotation);
        if (!bodyNode) return undefined;
        let node;
        node = this.NewNode(nodeList, true);
        node.type = "unless";
        node.child[1] = conditionNode;
        node.child[2] = bodyNode;
        return node;
    }
    private ParseVariable: ParserFunction = (tokenStream, nodeList, annotation) => {
        let name;
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "name") {
            name = token;
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing VARIABLE; name expected.", token);
            return undefined;
        }
        
        let node;
        node = this.NewNode(nodeList);
        node.type = "variable";
        node.name = name;
        annotation.nameReference = annotation.nameReference || {};
        annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
        return node;
    }
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

    public NewNode(nodeList?: LuaArray<AstNode>, hasChild?: boolean) {
        let node = this.nodesPool.Get();
        if (nodeList) {
            let nodeId = lualength(nodeList) + 1;
            node.nodeId = nodeId;
            nodeList[nodeId] = node;
        }
        if (hasChild) {
            node.child = this.childrenPool.Get();
        }
        return node;
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
            for (const [, parameters] of ipairs(annotation.rawPositionalParametersList)) {
                this.rawPositionalParametersPool.Release(parameters);
            }
        }
        if (annotation.rawNamedParametersList) {
            for (const [, parameters] of ipairs(annotation.rawNamedParametersList)) {
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
        if (ast.annotation) {
            this.ReleaseAnnotation(ast.annotation);
            ast.annotation = undefined;
        }
        this.nodesPool.Release(ast);
    }
    public ParseCode(nodeType: NodeType, code: string, nodeList: LuaArray<AstNode>, annotation: AstAnnotation): [AstNode, LuaArray<AstNode>, AstAnnotation] | [] {
        nodeList = nodeList || {}
        annotation = annotation || {}
        let tokenStream = new OvaleLexer("Ovale", code, MATCHES, { comments:  TokenizeComment, space: TokenizeWhitespace });
        const node = this.Parse(nodeType, tokenStream, nodeList, annotation);
        tokenStream.Release();
        if (!node) return [];
        return [node, nodeList, annotation];
    }

    public parseScript(code: string, options?: { optimize: boolean, verify: boolean}) {
        options = options || {
            optimize: true,
            verify: true
        };
        const annotation: AstAnnotation = {
            nodeList: {},
            verify: options.verify,
            definition: {}
        };
        const [ast] = this.ParseCode("script", code, annotation.nodeList, annotation);
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
            this.ReleaseAnnotation(annotation);
        }
        return ast;
    }

    public parseNamedScript(name: string, options?: { optimize: boolean, verify: boolean}) {
        let code = this.ovaleScripts.GetScriptOrDefault(name);
        if (code) {
            return this.parseScript(code, options);
        }
        else {
            this.debug.Debug("No code to parse");
            return undefined;
        }
    }
    
    public PropagateConstants(ast: AstNode) {
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
    public PropagateStrings(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_PropagateStrings");
        if (ast.annotation && ast.annotation.stringReference) {
            for (const [, node] of ipairs(ast.annotation.stringReference)) {
                const targetNode = <StringNode>node;
                if (isNodeType(node, "string")) {
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
                } else if (isNodeType(node, "value")) {
                    let value = node.value;
                    targetNode.previousType = "value";
                    targetNode.type = "string";
                    targetNode.value = tostring(value);
                } else if (node.type == "function") {
                    let key = node.rawPositionalParams[1];
                    let stringKey: string | undefined;
                    if (isAstNode(key)) {
                        if (isNodeType(key, "value")) {
                            stringKey = tostring(key.value);
                        } else if (isVariableNode(key)) {
                            stringKey = key.name;
                        } else if (isNodeType(key, "string")) {
                            stringKey = key.value;
                        } else {
                            stringKey = undefined;
                        }
                    }
                    else {
                        stringKey = tostring(key);
                    }
                    if (stringKey) {
                        let value: string | undefined;
                        let name = node.name;
                        if (name == "ItemName") {
                            [value] = GetItemInfo(stringKey)
                            if (!value) value = "item:" + stringKey;
                        } else if (name == "L") {
                            value = L[stringKey];
                        } else if (name == "SpellName") {
                            value = this.ovaleSpellBook.GetSpellName(tonumber(stringKey)) || "spell:" + stringKey;
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
        }
        this.profiler.StopProfiling("OvaleAST_PropagateStrings");
    }
    public FlattenParameters(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_FlattenParameters");
        let annotation = ast.annotation;
        if (annotation && annotation.parametersReference) {
            let dictionary = annotation.definition;
            for (const [, node] of ipairs<AstNode>(annotation.parametersReference)) {
                if (node.rawPositionalParams) {
                    let parameters = this.flattenParameterValuesPool.Get();
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
                            const value = node.rawNamedParams[key]!; //TODO
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
                let output = this.outputPool.Get();
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
                this.outputPool.Release(output);
            }
        }
        this.profiler.StopProfiling("OvaleAST_FlattenParameters");
    }
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

    private VerifyParameterStances(ast: AstNode) {
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

    private InsertPostOrderTraversal(ast: AstNode) {
        this.profiler.StartProfiling("OvaleAST_InsertPostOrderTraversal");
        let annotation = ast.annotation;
        if (annotation && annotation.postOrderReference) {
            for (const [, node] of ipairs<AstNode>(annotation.postOrderReference)) {
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
                if (node.child) {
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
