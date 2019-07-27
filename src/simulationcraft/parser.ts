import { OvaleLexer, Tokenizer, TokenizerDefinition } from "../Lexer";
import { LuaArray, tostring, tonumber, lualength, ipairs } from "@wowts/lua";
import { ParseNode, Annotation, Modifier, KEYWORD, SPECIAL_ACTION, Modifiers, UNARY_OPERATOR, SimcUnaryOperatorType, BINARY_OPERATOR, SimcBinaryOperatorType, FUNCTION_KEYWORD, MODIFIER_KEYWORD, LITTERAL_MODIFIER, RUNE_OPERAND } from "./definitions";
import { gsub, gmatch, sub } from "@wowts/string";
import { OvaleDebugClass, Tracer } from "../Debug";
import { concat } from "@wowts/table";
import { OvalePool } from "../Pool";
import { checkToken } from "../tools";

const self_childrenPool = new OvalePool<LuaArray<ParseNode> | Modifiers>("OvaleSimulationCraft_childrenPool");

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


const NewNode = function(nodeList: LuaArray<ParseNode>, hasChild?: boolean) {
    let node = self_pool.Get();
    if (nodeList) {
        let nodeId = lualength(nodeList) + 1;
        node.nodeId = nodeId;
        nodeList[nodeId] = node;
    }
    if (hasChild) {
        node.child = self_childrenPool.Get() as LuaArray<ParseNode>;
    }
    return node;
}

const TicksRemainTranslationHelper = function(p1: string, p2: string, p3: string, p4: string) {
    if (p4) {
        return `${p1}${p2} < ${tostring(tonumber(p4) + 1)}`;
    } else {
        return `${p1}<${tostring(tonumber(p3) + 1)}`;
    }
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
        1: "^%d+%a[%w_]*[.:]?[%w_.:]*",
        2: TokenizeName
    },
    2: {
        1: "^%d+%.?%d*",
        2: TokenizeNumber
    },
    3: {
        1: "^[%a_][%w_]*[.:]?[%w_.:]*",
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
        1: "^>%?",
        2: Tokenize
    },
    10: {
        1: "^.",
        2: Tokenize
    },
    11: {
        1: "^$",
        2: NoToken
    }
}

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
    private ParseAction(action: string, nodeList: LuaArray<ParseNode>, annotation: Annotation): [boolean, ParseNode] {
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
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line '%s'; name or special action expected.", token, action);
                ok = false;
            }
        }
        const child = self_childrenPool.Get() as LuaArray<ParseNode>;
        const modifiers = self_childrenPool.Get() as Modifiers;
                        
        if (ok) {
            let [tokenType, token] = tokenStream.Peek();
            while (ok && tokenType) {
                if (tokenType == ",") {
                    tokenStream.Consume();
                    let modifier: Modifier, expressionNode: ParseNode;
                    [ok, modifier, expressionNode] = this.ParseModifier(tokenStream, nodeList, annotation);
                    if (ok) {
                        modifiers[modifier] = expressionNode;
                        [tokenType, token] = tokenStream.Peek();
                    }
                } else {
                    this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line '%s'; ',' expected.", token, action);
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
            node.modifiers = modifiers;
            annotation.sync = annotation.sync || {}
            annotation.sync[name] = annotation.sync[name] || node;
        } else {
            self_childrenPool.Release(child);
        }

        return [ok, node];
    }

    /** Parse an action list (a series of actions separated by "/""). Returns a ParseNode of type "action_list" */
    ParseActionList(name: string, actionList: string, nodeList: LuaArray<ParseNode>, annotation: Annotation): [boolean, ParseNode] {
        let ok = true;
        let child = self_childrenPool.Get() as LuaArray<ParseNode>;
        for (const action of gmatch(actionList, "[^/]+")) {
            let actionNode;
            [ok, actionNode] = this.ParseAction(action, nodeList, annotation);
            if (ok) {
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

    private ParseExpression(tokenStream: OvaleLexer, nodeList: LuaArray<ParseNode>, annotation: Annotation, minPrecedence?: number):[boolean, ParseNode] {
        minPrecedence = minPrecedence || 0;
        let ok = true;
        let node: ParseNode;
        {
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType) {
                let opInfo: { 1: "logical" | "arithmetic", 2: number} = UNARY_OPERATOR[token as SimcUnaryOperatorType];
                if (opInfo) {
                    let [opType, precedence] = [opInfo[1], opInfo[2]];
                    let asType: "boolean" | "value" = (opType == "logical") && "boolean" || "value";
                    tokenStream.Consume();
                    const operator = token as SimcUnaryOperatorType;
                    let rhsNode: ParseNode;
                    [ok, rhsNode] = this.ParseExpression(tokenStream, nodeList, annotation, precedence);
                    if (ok) {
                        if (operator == "-" && rhsNode.type == "number") {
                            rhsNode.value = -1 * rhsNode.value;
                            node = rhsNode;
                        } else {
                            node = NewNode(nodeList, true);
                            node.type = opType;
                            node.expressionType = "unary";
                            node.operator = operator;
                            node.precedence = precedence;
                            node.child[1] = rhsNode;
                            rhsNode.asType = asType;
                        }
                    }
                } else {
                    [ok, node] = this.ParseSimpleExpression(tokenStream, nodeList, annotation);
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
            let opInfo = BINARY_OPERATOR[token as SimcBinaryOperatorType];
            if (opInfo) {
                let [opType, precedence] = [opInfo[1], opInfo[2]];
                let asType: "boolean" | "value" = (opType == "logical") && "boolean" || "value";
                if (precedence && precedence > minPrecedence) {
                    keepScanning = true;
                    tokenStream.Consume();
                    const operator = token as SimcBinaryOperatorType;
                    let lhsNode = node;
                    let rhsNode;
                    [ok, rhsNode] = this.ParseExpression(tokenStream, nodeList, annotation, precedence);
                    if (ok) {
                        node = NewNode(nodeList, true);
                        node.type = opType;
                        node.expressionType = "binary";
                        node.operator = operator;
                        node.precedence = precedence;
                        node.child[1] = lhsNode;
                        node.child[2] = rhsNode;
                        lhsNode.asType = <"boolean"|"value"> asType;
                        if (!rhsNode) {
                            this.SyntaxError(tokenStream, "Internal error: no right operand in binary operator %s.", token);
                            return [false, undefined];
                        }
                        rhsNode.asType = asType;
                        while (node.type == rhsNode.type && node.operator == rhsNode.operator && BINARY_OPERATOR[node.operator as SimcBinaryOperatorType][3] == "associative" && rhsNode.expressionType == "binary") {
                            node.child[2] = rhsNode.child[1];
                            rhsNode.child[1] = node;
                            node = rhsNode;
                            rhsNode = node.child[2];
                        }
                    }
                }
            } else if (!node) {
                this.SyntaxError(tokenStream, "Syntax error: %s of type %s is not a binary operator", token, tokenType);
                return [false, undefined];
            }
            if (!keepScanning) {
                break;
            }
        }
        return [ok, node];
    }
    private ParseFunction(tokenStream: OvaleLexer, nodeList: LuaArray<ParseNode>, annotation: Annotation): [boolean, ParseNode] {
        let ok = true;
        let name;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "keyword" && FUNCTION_KEYWORD[token]) {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; '(' expected.", token);
                ok = false;
            }
        }
        let argumentNode;
        if (ok) {
            [ok, argumentNode] = this.ParseExpression(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.", token);
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
    private ParseIdentifier(tokenStream: OvaleLexer, nodeList: LuaArray<ParseNode>, annotation: Annotation): [boolean, ParseNode] {
        let [, token] = tokenStream.Consume();
        let node = NewNode(nodeList);
        node.type = "operand";
        node.name = token;
        annotation.operand = annotation.operand || {};
        annotation.operand[lualength(annotation.operand) + 1] = node;
        return [true, node];
    }

    private ParseModifier(tokenStream: OvaleLexer, nodeList: LuaArray<ParseNode>, annotation: Annotation): [boolean, Modifier, ParseNode] {
        let ok = true;
        let name: Modifier;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "keyword" && checkToken(MODIFIER_KEYWORD, token)) {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line; expression keyword expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "=") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing action line; '=' expected.", token);
                ok = false;
            }
        }
        let expressionNode: ParseNode;
        if (ok) {
            if (LITTERAL_MODIFIER[name]) {
                [ok, expressionNode] = this.ParseIdentifier(tokenStream, nodeList, annotation);
            } else {
                [ok, expressionNode] = this.ParseExpression(tokenStream, nodeList, annotation);
                if (ok && expressionNode && name == "sec") {
                    expressionNode.asType = "value";
                }
            }
        }
        return [ok, name, expressionNode];
    }
    private ParseNumber(tokenStream: OvaleLexer, nodeList: LuaArray<ParseNode>, annotation: Annotation): [boolean, ParseNode] {
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
        let node;
        if (ok) {
            node = NewNode(nodeList);
            node.type = "number";
            node.value = value;
        }
        return [ok, node];
    }
    private ParseOperand(tokenStream: OvaleLexer, nodeList: LuaArray<ParseNode>, annotation: Annotation): [boolean, ParseNode] {
        let ok = true;
        let name;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else if (tokenType == "keyword" && (token == "target" || token == "cooldown")) {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing OPERAND; operand expected.", token);
                ok = false;
            }
        }
        let node: ParseNode;
        if (ok) {
            node = NewNode(nodeList);
            node.type = "operand";
            node.name = name;
            node.rune = RUNE_OPERAND[name];
            if (node.rune) {
                let firstCharacter = sub(name, 1, 1);
                node.includeDeath = (firstCharacter == "B" || firstCharacter == "F" || firstCharacter == "U");
            }
            annotation.operand = annotation.operand || {}
            annotation.operand[lualength(annotation.operand) + 1] = node;
        }
        return [ok, node];
    }
    
    private ParseParentheses(tokenStream: OvaleLexer, nodeList: LuaArray<ParseNode>, annotation: Annotation): [boolean, ParseNode] {
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
        let node: ParseNode;
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
    
    private ParseSimpleExpression(tokenStream: OvaleLexer, nodeList: LuaArray<ParseNode>, annotation: Annotation):[boolean, ParseNode] {
        let ok = true;
        let node;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType == "number") {
            [ok, node] = this.ParseNumber(tokenStream, nodeList, annotation);
        } else if (tokenType == "keyword") {
            if (FUNCTION_KEYWORD[token]) {
                [ok, node] = this.ParseFunction(tokenStream, nodeList, annotation);
            } else if (token == "target" || token == "cooldown") {
                [ok, node] = this.ParseOperand(tokenStream, nodeList, annotation);
            } else {
                this.SyntaxError(tokenStream, "Warning: unknown keyword %s when parsing SIMPLE EXPRESSION", token);
                return [false, undefined];
            }
        } else if (tokenType == "name") {
            [ok, node] = this.ParseOperand(tokenStream, nodeList, annotation);
        } else if (tokenType == "(") {
            [ok, node] = this.ParseParentheses(tokenStream, nodeList, annotation);
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION", token);
            tokenStream.Consume();
            ok = false;
        }
        return [ok, node];
    }
}