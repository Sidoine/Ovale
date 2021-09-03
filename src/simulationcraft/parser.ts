import { OvaleLexer, Tokenizer, TokenizerDefinition } from "../engine/lexer";
import {
    LuaArray,
    tostring,
    tonumber,
    lualength,
    ipairs,
    wipe,
} from "@wowts/lua";
import {
    ParseNode,
    Annotation,
    Modifier,
    keywords,
    specialActions,
    Modifiers,
    unaryOperators,
    SimcUnaryOperatorType,
    binaryOperators,
    SimcBinaryOperatorType,
    functionKeywords,
    modifierKeywords,
    litteralModifiers,
    runeOperands,
    ParseNodeWithChilds,
    ActionParseNode,
    ActionListParseNode,
    OperatorParseNode,
    FunctionParseNode,
    OperandParseNode,
    NumberParseNode,
} from "./definitions";
import { gsub, gmatch, sub } from "@wowts/string";
import { DebugTools, Tracer } from "../engine/debug";
import { concat } from "@wowts/table";
import { OvalePool } from "../tools/Pool";
import { checkToken } from "../tools/tools";

const childrenPool = new OvalePool<LuaArray<ParseNode> | Modifiers>(
    "OvaleSimulationCraft_childrenPool"
);

class SelfPool extends OvalePool<ParseNode> {
    constructor() {
        super("OvaleSimulationCraft_pool");
    }

    clean(node: ParseNode) {
        if (
            node.type !== "number" &&
            node.type !== "operand" &&
            node.type !== "action"
        ) {
            childrenPool.release(node.child);
        }
        wipe(node);
    }
}

const selfPool = new SelfPool();

function newNode<T extends ParseNode>(nodeList: LuaArray<ParseNode>) {
    const node = selfPool.get() as T;
    const nodeId = lualength(nodeList) + 1;
    node.nodeId = nodeId;
    nodeList[nodeId] = node;
    return node;
}

function newNodeWithChild<T extends ParseNodeWithChilds>(
    nodeList: LuaArray<ParseNode>
) {
    const node = selfPool.get() as T;
    const nodeId = lualength(nodeList) + 1;
    node.nodeId = nodeId;
    nodeList[nodeId] = node;
    node.child = childrenPool.get() as typeof node.child;
    return node;
}

const ticksRemainTranslationHelper = function (
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

const tokenizeName: Tokenizer = function (token) {
    if (keywords[token]) {
        return ["keyword", token];
    } else {
        return ["name", token];
    }
};
const tokenizeNumber: Tokenizer = function (token) {
    return ["number", token];
};
const tokenize: Tokenizer = function (token) {
    return [token, token];
};
const noToken: Tokenizer = function () {
    return [undefined, undefined];
};
const tokenMatches: LuaArray<TokenizerDefinition> = {
    1: {
        1: "^%d+%a[%w_]*[.:]?[%w_.:]*",
        2: tokenizeName,
    },
    2: {
        1: "^%d+%.?%d*",
        2: tokenizeNumber,
    },
    3: {
        1: "^[%a_][%w_]*[.:]?[%w_.:]*",
        2: tokenizeName,
    },
    4: {
        1: "^!=",
        2: tokenize,
    },
    5: {
        1: "^<=",
        2: tokenize,
    },
    6: {
        1: "^>=",
        2: tokenize,
    },
    7: {
        1: "^!~",
        2: tokenize,
    },
    8: {
        1: "^==",
        2: tokenize,
    },
    9: {
        1: "^>%?",
        2: tokenize,
    },
    10: {
        1: "^<%?",
        2: tokenize,
    },
    11: {
        1: "^%%%%",
        2: tokenize,
    },
    12: {
        1: "^.",
        2: tokenize,
    },
    13: {
        1: "^$",
        2: noToken,
    },
};

export class Parser {
    private tracer: Tracer;
    constructor(ovaleDebug: DebugTools) {
        this.tracer = ovaleDebug.create("SimulationCraftParser");
    }
    public release(nodeList: LuaArray<ParseNode>) {
        for (const [, node] of ipairs(nodeList)) {
            selfPool.release(node);
        }
    }

    private syntaxError(
        tokenStream: OvaleLexer,
        pattern: string,
        ...parameters: unknown[]
    ) {
        this.tracer.warning(pattern, ...parameters);
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
        this.tracer.warning(concat(context, " "));
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
    private parseAction(
        action: string,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation,
        actionListName: string
    ): ActionParseNode | undefined {
        let stream = action;
        {
            stream = gsub(stream, "||", "|");
        }
        {
            stream = gsub(stream, ",,", ",");
            stream = gsub(stream, "%&%&", "&");
            stream = gsub(stream, "target%.target%.", "target.");
            stream = gsub(stream, "name=name=", "name=");
            stream = gsub(stream, "name=name=", "name=");
            stream = gsub(stream, "name=BT&Charge:", "name=BT_Charge:");
            stream = gsub(stream, "name=BT&Reck:", "name=BT_Reck:");
        }
        {
            // From the Shadows is a target debuff, not a player buff.
            stream = gsub(
                stream,
                "buff%.from_the_shadows%.",
                "target.debuff.from_the_shadows."
            );
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
                ticksRemainTranslationHelper
            );
            stream = gsub(
                stream,
                "([a-z_%.]+%.ticks_remain)(<?=)([0-9]+)",
                ticksRemainTranslationHelper
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

        const tokenStream = new OvaleLexer(
            "SimulationCraft",
            stream,
            tokenMatches
        );
        let name;
        let [tokenType, token] = tokenStream.consume();
        if (!token) {
            this.syntaxError(
                tokenStream,
                "Warning: end of stream when parsing Action"
            );
            return undefined;
        }
        if (
            (tokenType == "keyword" && specialActions[token]) ||
            tokenType == "name"
        ) {
            name = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing action line '%s'; name or special action expected.",
                token,
                action
            );
            return undefined;
        }

        const modifiers = childrenPool.get() as Modifiers;

        [tokenType, token] = tokenStream.peek();
        while (tokenType) {
            if (tokenType == ",") {
                tokenStream.consume();
                const [modifier, expressionNode] = this.parseModifier(
                    tokenStream,
                    nodeList,
                    annotation
                );
                if (modifier && expressionNode) {
                    modifiers[modifier] = expressionNode;
                    [tokenType, token] = tokenStream.peek();
                } else {
                    return undefined;
                }
            } else {
                this.syntaxError(
                    tokenStream,
                    "Syntax error: unexpected token '%s' when parsing action line '%s'; ',' expected.",
                    token,
                    action
                );
                childrenPool.release(modifiers);
                return undefined;
            }
        }
        const node = newNode<ActionParseNode>(nodeList);
        node.type = "action";
        node.action = action;
        node.name = name;
        node.actionListName = actionListName;
        node.modifiers = modifiers;
        annotation.sync = annotation.sync || {};
        annotation.sync[name] = annotation.sync[name] || node;

        return node;
    }

    /** Parse an action list (a series of actions separated by "/""). Returns a ParseNode of type "action_list" */
    parseActionList(
        name: string,
        actionList: string,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ) {
        const child = childrenPool.get() as LuaArray<ActionParseNode>;
        for (const action of gmatch(actionList, "[^/]+")) {
            const actionNode = this.parseAction(
                action,
                nodeList,
                annotation,
                name
            );
            if (!actionNode) {
                childrenPool.release(child);
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
        const node = newNode<ActionListParseNode>(nodeList);
        node.type = "action_list";
        node.name = name;
        node.child = child;
        return node;
    }

    private parseExpression(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation,
        minPrecedence?: number
    ): ParseNode | undefined {
        minPrecedence = minPrecedence || 0;
        let node;

        const [tokenType, token] = tokenStream.peek();
        if (!tokenType) return undefined;

        const opInfo: { 1: "logical" | "arithmetic"; 2: number } =
            unaryOperators[token as SimcUnaryOperatorType];
        if (opInfo) {
            const [opType, precedence] = [opInfo[1], opInfo[2]];
            const asType: "boolean" | "value" =
                (opType == "logical" && "boolean") || "value";
            tokenStream.consume();
            const operator = token as SimcUnaryOperatorType;
            const rhsNode = this.parseExpression(
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
            const n = this.parseSimpleExpression(
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
            const [tokenType, token] = tokenStream.peek();
            if (!tokenType) {
                break;
            }
            const opInfo = binaryOperators[token as SimcBinaryOperatorType];
            if (opInfo) {
                const [opType, precedence] = [opInfo[1], opInfo[2]];
                const asType: "boolean" | "value" =
                    (opType == "logical" && "boolean") || "value";
                if (precedence && precedence > minPrecedence) {
                    keepScanning = true;
                    tokenStream.consume();
                    const operator = token as SimcBinaryOperatorType;
                    const lhsNode = node;
                    let rhsNode = this.parseExpression(
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
                        this.syntaxError(
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
                        binaryOperators[
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
                this.syntaxError(
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
    private parseFunction(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ): ParseNode | undefined {
        let name;
        let [tokenType, token] = tokenStream.consume();
        if (!token) {
            this.syntaxError(
                tokenStream,
                "Warning: end of stream when parsing Function"
            );
            return undefined;
        }
        if (tokenType == "keyword" && functionKeywords[token]) {
            name = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.",
                token
            );
            return undefined;
        }
        [tokenType, token] = tokenStream.consume();
        if (tokenType != "(") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing FUNCTION; '(' expected.",
                token
            );
            return undefined;
        }
        const argumentNode = this.parseExpression(
            tokenStream,
            nodeList,
            annotation
        );
        if (!argumentNode) return undefined;

        [tokenType, token] = tokenStream.consume();
        if (tokenType != ")") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.",
                token
            );
            return undefined;
        }

        const node = newNodeWithChild<FunctionParseNode>(nodeList);
        node.type = "function";
        node.name = name;
        node.child[1] = argumentNode;
        return node;
    }
    private parseIdentifier(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ): ParseNode | undefined {
        const [, token] = tokenStream.consume();
        if (!token) {
            this.syntaxError(
                tokenStream,
                "Warning: end of stream when parsing Identifier"
            );
            return undefined;
        }
        const node = newNode<OperandParseNode>(nodeList);
        node.type = "operand";
        node.name = token;
        annotation.operand = annotation.operand || {};
        annotation.operand[lualength(annotation.operand) + 1] = node;
        return node;
    }

    private parseModifier(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ): [Modifier?, ParseNode?] {
        let name: Modifier;
        let [tokenType, token] = tokenStream.consume();
        if (tokenType == "keyword" && checkToken(modifierKeywords, token)) {
            name = token;
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing action line; expression keyword expected.",
                token
            );
            return [];
        }
        [tokenType, token] = tokenStream.consume();
        if (tokenType !== "=") {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing action line; '=' expected.",
                token
            );
            return [];
        }
        let expressionNode: ParseNode | undefined;
        if (litteralModifiers[name]) {
            expressionNode = this.parseIdentifier(
                tokenStream,
                nodeList,
                annotation
            );
        } else {
            expressionNode = this.parseExpression(
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
    private parseNumber(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>
    ): ParseNode | undefined {
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
        const node = newNode<NumberParseNode>(nodeList);
        node.type = "number";
        node.value = value;
        return node;
    }
    private parseOperand(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ): ParseNode | undefined {
        let name;
        const [tokenType, token] = tokenStream.consume();
        if (!token) {
            this.syntaxError(
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
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing OPERAND; operand expected.",
                token
            );
            return undefined;
        }

        const node = newNode<OperandParseNode>(nodeList);
        node.type = "operand";
        node.name = name;
        node.rune = runeOperands[name];
        if (node.rune) {
            const firstCharacter = sub(name, 1, 1);
            node.includeDeath =
                firstCharacter == "B" ||
                firstCharacter == "F" ||
                firstCharacter == "U";
        }
        annotation.operand = annotation.operand || {};
        annotation.operand[lualength(annotation.operand) + 1] = node;
        return node;
    }

    private parseParentheses(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ): ParseNode | undefined {
        let leftToken, rightToken;
        let [tokenType, token] = tokenStream.consume();
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
        const node = this.parseExpression(tokenStream, nodeList, annotation);
        if (!node) return undefined;

        [tokenType, token] = tokenStream.consume();
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

    private parseSimpleExpression(
        tokenStream: OvaleLexer,
        nodeList: LuaArray<ParseNode>,
        annotation: Annotation
    ) {
        let node;
        const [tokenType, token] = tokenStream.peek();
        if (!token) {
            this.syntaxError(
                tokenStream,
                "Warning: end of stream when parsing SIMPLE EXPRESSION"
            );
            return undefined;
        }
        if (tokenType == "number") {
            node = this.parseNumber(tokenStream, nodeList);
        } else if (tokenType == "keyword") {
            if (functionKeywords[token]) {
                node = this.parseFunction(tokenStream, nodeList, annotation);
            } else if (token == "target" || token == "cooldown") {
                node = this.parseOperand(tokenStream, nodeList, annotation);
            } else {
                this.syntaxError(
                    tokenStream,
                    "Warning: unknown keyword %s when parsing SIMPLE EXPRESSION",
                    token
                );
                return undefined;
            }
        } else if (tokenType == "name") {
            node = this.parseOperand(tokenStream, nodeList, annotation);
        } else if (tokenType == "(") {
            node = this.parseParentheses(tokenStream, nodeList, annotation);
        } else {
            this.syntaxError(
                tokenStream,
                "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION",
                token
            );
            tokenStream.consume();
            return undefined;
        }
        return node;
    }
}
