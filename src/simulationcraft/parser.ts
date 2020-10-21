import { OvaleLexer, Tokenizer, TokenizerDefinition } from "../Lexer";
import { LuaArray, tostring, tonumber, lualength, ipairs } from "@wowts/lua";
import {
    ParseNode,
    Annotation,
    Modifier,
    KEYWORD,
    SPECIAL_ACTION,
    Modifiers,
    UNARY_OPERATOR,
    SimcUnaryOperatorType,
    BINARY_OPERATOR,
    SimcBinaryOperatorType,
    FUNCTION_KEYWORD,
    MODIFIER_KEYWORD,
    LITTERAL_MODIFIER,
    RUNE_OPERAND,
    ParseNodeWithChilds,
    ActionParseNode,
    ActionListParseNode,
    OperatorParseNode,
    FunctionParseNode,
    OperandParseNode,
    NumberParseNode,
} from "./definitions";
import { gsub, gmatch, sub } from "@wowts/string";
import { OvaleDebugClass, Tracer } from "../Debug";
import { concat } from "@wowts/table";
import { OvalePool } from "../Pool";
import { checkToken } from "../tools";

const self_childrenPool = new OvalePool<LuaArray<ParseNode> | Modifiers>(
    "OvaleSimulationCraft_childrenPool"
);

class SelfPool extends OvalePool<ParseNode> {
    constructor() {
        super("OvaleSimulationCraft_pool");
    }

    Clean(node: ParseNode) {
        if (
            node.type !== "number" &&
            node.type !== "operand" &&
            node.type !== "action"
        ) {
            self_childrenPool.Release(node.child);
            delete node.child;
        }
    }
}

let self_pool = new SelfPool();

function NewNode<T extends ParseNode>(nodeList: LuaArray<ParseNode>) {
    let node = self_pool.Get() as T;
    let nodeId = lualength(nodeList) + 1;
    node.nodeId = nodeId;
    nodeList[nodeId] = node;
    return node;
}

function newNodeWithChild<T extends ParseNodeWithChilds>(
    nodeList: LuaArray<ParseNode>
) {
    let node = self_pool.Get() as T;
    let nodeId = lualength(nodeList) + 1;
    node.nodeId = nodeId;
    nodeList[nodeId] = node;
    node.child = self_childrenPool.Get() as typeof node.child;
    return node;
}

const TicksRemainTranslationHelper = function (
    p1: string,
    p2: string,
    p3: string,
    p4: string
) {
    if (p4) {
        return `${p1}${p2} < ${tostring(tonumber(p4) + 1)}`;
    } else {
        return `${p1}<${tostring(tonumber(p3) + 1)}`;
    }
};

const TokenizeName: Tokenizer = function (token) {
    if (KEYWORD[token]) {
        return ["keyword", token];
    } else {
        return ["name", token];
    }
};
const TokenizeNumber: Tokenizer = function (token) {
    return ["number", token];
};
const Tokenize: Tokenizer = function (token) {
    return [token, token];
};
const NoToken: Tokenizer = function () {
    return [undefined, undefined];
};
const MATCHES: LuaArray<TokenizerDefinition> = {
    1: {
        1: "^%d+%a[%w_]*[.:]?[%w_.:]*",
        2: TokenizeName,
    },
    2: {
        1: "^%d+%.?%d*",
        2: TokenizeNumber,
    },
    3: {
        1: "^[%a_][%w_]*[.:]?[%w_.:]*",
        2: TokenizeName,
    },
    4: {
        1: "^!=",
        2: Tokenize,
    },
    5: {
        1: "^<=",
        2: Tokenize,
    },
    6: {
        1: "^>=",
        2: Tokenize,
    },
    7: {
        1: "^!~",
        2: Tokenize,
    },
    8: {
        1: "^==",
        2: Tokenize,
    },
    9: {
        1: "^>%?",
        2: Tokenize,
    },
    10: {
        1: "^<%?",
        2: Tokenize,
    },
    11: {
        1: "^%%%%",
        2: Tokenize,
    },
    12: {
        1: "^.",
        2: Tokenize,
    },
    13: {
        1: "^$",
        2: NoToken,
    },
};

export class Parser {
    private tracer: Tracer;
    constructor(ovaleDebug: OvaleDebugClass) {
        this.tracer = ovaleDebug.create("SimulationCraftParser");
    }
    public release(nodeList: LuaArray<ParseNode>) {
        for (const [, node] of ipairs(nodeList)) {
            self_pool.Release(node);
        }
    }

    private SyntaxError(tokenStream: OvaleLexer, ...__args: any[]) {
        this.tracer.Warning(...__args);
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
        this.tracer.Warning(concat(context, " "));
    }

    // function filterTargetAuraConditions(node: ParseNode) {
    //     const changed = false;
    //     for (const [k, child] of pairs(node.child)) {
    //         const n = filterTargetAuraConditions(child);
    //         if (n !== child) {
    //             changed = true;
    //         }
    //     }
    //     return node;
    // }

    /** Parse an action. An action may has modifiers separated by a comma */
    private ParseAction(
        action: string,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ): ActionParseNode | undefined {
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
            stream = gsub(
                stream,
                "([^_%.])(ticks_remain)(<?=)([0-9]+)",
                TicksRemainTranslationHelper
            );
            stream = gsub(
                stream,
                "([a-z_%.]+%.ticks_remain)(<?=)([0-9]+)",
                TicksRemainTranslationHelper
            );
        }
        {
            stream = gsub(
                stream,
                "%@([a-z_%.]+)<(=?)([0-9]+)",
                "(%1<%2%3&%1>%2-%3)"
            );
            stream = gsub(
                stream,
                "%@([a-z_%.]+)>(=?)([0-9]+)",
                "(%1>%2%3|%1<%2-%3)"
            );
        }
        {
            stream = gsub(
                stream,
                "!([a-z_%.]+)%.cooldown%.up",
                "%1.cooldown.down"
            );
        }
        {
            stream = gsub(
                stream,
                "!talent%.([a-z_%.]+)%.enabled",
                "talent.%1.disabled"
            );
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
        let [tokenType, token] = tokenStream.Consume();
        if (!token) {
            this.SyntaxError(
                tokenStream,
                "Warning: end of stream when parsing Action"
            );
            return undefined;
        }
        if (
            (tokenType == "keyword" && SPECIAL_ACTION[token]) ||
            tokenType == "name"
        ) {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing action line '%s'; name or special action expected.",
                token,
                action
            );
            return undefined;
        }

        const modifiers = self_childrenPool.Get() as Modifiers;

        [tokenType, token] = tokenStream.Peek();
        while (tokenType) {
            if (tokenType == ",") {
                tokenStream.Consume();
                const [modifier, expressionNode] = this.ParseModifier(
                    tokenStream,
                    nodeList,
                    annotation
                );
                if (modifier && expressionNode) {
                    modifiers[modifier] = expressionNode;
                    [tokenType, token] = tokenStream.Peek();
                } else {
                    return undefined;
                }
            } else {
                this.SyntaxError(
                    tokenStream,
                    "Syntax error: unexpected token '%s' when parsing action line '%s'; ',' expected.",
                    token,
                    action
                );
                self_childrenPool.Release(modifiers);
                return undefined;
            }
        }
        let node: ParseNode;
        node = NewNode<ActionParseNode>(nodeList);
        node.type = "action";
        node.action = action;
        node.name = name;
        node.modifiers = modifiers;
        annotation.sync = annotation.sync || {};
        annotation.sync[name] = annotation.sync[name] || node;

        return node;
    }

    /** Parse an action list (a series of actions separated by "/""). Returns a ParseNode of type "action_list" */
    ParseActionList(
        name: string,
        actionList: string,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ) {
        let child = self_childrenPool.Get() as LuaArray<ActionParseNode>;
        for (const action of gmatch(actionList, "[^/]+")) {
            const actionNode = this.ParseAction(action, nodeList, annotation);
            if (!actionNode) {
                self_childrenPool.Release(child);
                return undefined;
            }
            child[lualength(child) + 1] = actionNode;
            // if (actionNode.modifiers.cycle_targets) {
            //     // Create another action but with the condition negated
            //     const secondNode = NewNode(nodeList);
            //     secondNode.type = "action";
            //     secondNode.action = actionNode.action;
            //     secondNode.name = actionNode.name;
            //     const modifiers = self_childrenPool.Get() as Modifiers;
            //     for (const [k, n] of kpairs(actionNode.modifiers)) {
            //         if (k === "if") {
            //             const logicalNode = NewNode(nodeList, true);
            //             logicalNode.type = "logical";
            //             logicalNode.operator = "!";
            //             logicalNode.expressionType = "unary";
            //             logicalNode.child[1] = n;
            //             modifiers[k] = logicalNode;
            //         } else {
            //             modifiers[k] = n;
            //         }
            //     }
            //     modifiers.target = NewNode(nodeList);
            //     modifiers.target.type = "operand";
            //     modifiers.target.name = "cycle";
            //     secondNode.modifiers = modifiers;
            //     insert(child, secondNode);
            // }
        }
        let node: ParseNode;
        node = NewNode<ActionListParseNode>(nodeList);
        node.type = "action_list";
        node.name = name;
        node.child = child;
        return node;
    }

    private ParseExpression(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation,
        minPrecedence?: number
    ): ParseNode | undefined {
        minPrecedence = minPrecedence || 0;
        let node;

        let [tokenType, token] = tokenStream.Peek();
        if (!tokenType) return undefined;

        let opInfo: { 1: "logical" | "arithmetic"; 2: number } =
            UNARY_OPERATOR[token as SimcUnaryOperatorType];
        if (opInfo) {
            let [opType, precedence] = [opInfo[1], opInfo[2]];
            let asType: "boolean" | "value" =
                (opType == "logical" && "boolean") || "value";
            tokenStream.Consume();
            const operator = token as SimcUnaryOperatorType;
            const rhsNode = this.ParseExpression(
                tokenStream,
                nodeList,
                annotation,
                precedence
            );
            if (rhsNode === undefined) return undefined;

            if (operator == "-" && rhsNode.type == "number") {
                rhsNode.value = -1 * rhsNode.value;
                node = rhsNode;
            } else {
                node = newNodeWithChild<OperatorParseNode>(nodeList);
                node.type = "operator";
                node.operatorType = opType;
                node.expressionType = "unary";
                node.operator = operator;
                node.precedence = precedence;
                node.child[1] = rhsNode;
                rhsNode.asType = asType;
            }
        } else {
            const n = this.ParseSimpleExpression(
                tokenStream,
                nodeList,
                annotation
            );
            if (!n) {
                return undefined;
            }
            node = n;
            node.asType = "boolean";
        }

        while (true) {
            let keepScanning = false;
            let [tokenType, token] = tokenStream.Peek();
            if (!tokenType) {
                break;
            }
            let opInfo = BINARY_OPERATOR[token as SimcBinaryOperatorType];
            if (opInfo) {
                let [opType, precedence] = [opInfo[1], opInfo[2]];
                let asType: "boolean" | "value" =
                    (opType == "logical" && "boolean") || "value";
                if (precedence && precedence > minPrecedence) {
                    keepScanning = true;
                    tokenStream.Consume();
                    const operator = token as SimcBinaryOperatorType;
                    let lhsNode = node;
                    let rhsNode = this.ParseExpression(
                        tokenStream,
                        nodeList,
                        annotation,
                        precedence
                    );
                    if (!rhsNode) {
                        return undefined;
                    }
                    node = newNodeWithChild<OperatorParseNode>(nodeList);
                    node.type = "operator";
                    node.operatorType = opType;
                    node.expressionType = "binary";
                    node.operator = operator;
                    node.precedence = precedence;
                    node.child[1] = lhsNode;
                    node.child[2] = rhsNode;
                    lhsNode.asType = asType;
                    if (!rhsNode) {
                        this.SyntaxError(
                            tokenStream,
                            "Internal error: no right operand in binary operator %s.",
                            token
                        );
                        return undefined;
                    }
                    rhsNode.asType = asType;
                    while (
                        node.type == rhsNode.type &&
                        node.operator == rhsNode.operator &&
                        BINARY_OPERATOR[
                            node.operator as SimcBinaryOperatorType
                        ][3] == "associative" &&
                        rhsNode.expressionType == "binary"
                    ) {
                        node.child[2] = rhsNode.child[1];
                        rhsNode.child[1] = node;
                        node = rhsNode;
                        rhsNode = node.child[2];
                    }
                }
            } else if (!node) {
                this.SyntaxError(
                    tokenStream,
                    "Syntax error: %s of type %s is not a binary operator",
                    token,
                    tokenType
                );
                return undefined;
            }
            if (!keepScanning) {
                break;
            }
        }
        return node;
    }
    private ParseFunction(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ): ParseNode | undefined {
        let name;
        let [tokenType, token] = tokenStream.Consume();
        if (!token) {
            this.SyntaxError(
                tokenStream,
                "Warning: end of stream when parsing Function"
            );
            return undefined;
        }
        if (tokenType == "keyword" && FUNCTION_KEYWORD[token]) {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.",
                token
            );
            return undefined;
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
        let argumentNode = this.ParseExpression(
            tokenStream,
            nodeList,
            annotation
        );
        if (!argumentNode) return undefined;

        [tokenType, token] = tokenStream.Consume();
        if (tokenType != ")") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.",
                token
            );
            return undefined;
        }

        let node;
        node = newNodeWithChild<FunctionParseNode>(nodeList);
        node.type = "function";
        node.name = name;
        node.child[1] = argumentNode;
        return node;
    }
    private ParseIdentifier(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ): ParseNode | undefined {
        let [, token] = tokenStream.Consume();
        if (!token) {
            this.SyntaxError(
                tokenStream,
                "Warning: end of stream when parsing Identifier"
            );
            return undefined;
        }
        let node = NewNode<OperandParseNode>(nodeList);
        node.type = "operand";
        node.name = token;
        annotation.operand = annotation.operand || {};
        annotation.operand[lualength(annotation.operand) + 1] = node;
        return node;
    }

    private ParseModifier(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ): [Modifier?, ParseNode?] {
        let name: Modifier;
        let [tokenType, token] = tokenStream.Consume();
        if (tokenType == "keyword" && checkToken(MODIFIER_KEYWORD, token)) {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing action line; expression keyword expected.",
                token
            );
            return [];
        }
        [tokenType, token] = tokenStream.Consume();
        if (tokenType !== "=") {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing action line; '=' expected.",
                token
            );
            return [];
        }
        let expressionNode: ParseNode | undefined;
        if (LITTERAL_MODIFIER[name]) {
            expressionNode = this.ParseIdentifier(
                tokenStream,
                nodeList,
                annotation
            );
        } else {
            expressionNode = this.ParseExpression(
                tokenStream,
                nodeList,
                annotation
            );
            if (expressionNode && name == "sec") {
                expressionNode.asType = "value";
            }
        }
        return [name, expressionNode];
    }
    private ParseNumber(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ): ParseNode | undefined {
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
        let node;
        node = NewNode<NumberParseNode>(nodeList);
        node.type = "number";
        node.value = value;
        return node;
    }
    private ParseOperand(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ): ParseNode | undefined {
        let name;
        let [tokenType, token] = tokenStream.Consume();
        if (!token) {
            this.SyntaxError(
                tokenStream,
                "Warning: end of stream when parsing OPERAND"
            );
            return undefined;
        }
        if (tokenType == "name") {
            name = token;
        } else if (
            tokenType == "keyword" &&
            (token == "target" || token == "cooldown")
        ) {
            name = token;
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing OPERAND; operand expected.",
                token
            );
            return undefined;
        }

        let node: ParseNode;
        node = NewNode<OperandParseNode>(nodeList);
        node.type = "operand";
        node.name = name;
        node.rune = RUNE_OPERAND[name];
        if (node.rune) {
            let firstCharacter = sub(name, 1, 1);
            node.includeDeath =
                firstCharacter == "B" ||
                firstCharacter == "F" ||
                firstCharacter == "U";
        }
        annotation.operand = annotation.operand || {};
        annotation.operand[lualength(annotation.operand) + 1] = node;
        return node;
    }

    private ParseParentheses(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ): ParseNode | undefined {
        let leftToken, rightToken;
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
        const node = this.ParseExpression(tokenStream, nodeList, annotation);
        if (!node) return undefined;

        [tokenType, token] = tokenStream.Consume();
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

    private ParseSimpleExpression(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ) {
        let node;
        let [tokenType, token] = tokenStream.Peek();
        if (!token) {
            this.SyntaxError(
                tokenStream,
                "Warning: end of stream when parsing SIMPLE EXPRESSION"
            );
            return undefined;
        }
        if (tokenType == "number") {
            node = this.ParseNumber(tokenStream, nodeList, annotation);
        } else if (tokenType == "keyword") {
            if (FUNCTION_KEYWORD[token]) {
                node = this.ParseFunction(tokenStream, nodeList, annotation);
            } else if (token == "target" || token == "cooldown") {
                node = this.ParseOperand(tokenStream, nodeList, annotation);
            } else {
                this.SyntaxError(
                    tokenStream,
                    "Warning: unknown keyword %s when parsing SIMPLE EXPRESSION",
                    token
                );
                return undefined;
            }
        } else if (tokenType == "name") {
            node = this.ParseOperand(tokenStream, nodeList, annotation);
        } else if (tokenType == "(") {
            node = this.ParseParentheses(tokenStream, nodeList, annotation);
        } else {
            this.SyntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION",
                token
            );
            tokenStream.Consume();
            return undefined;
        }
        return node;
    }
}
