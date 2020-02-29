import { UNARY_OPERATOR, SimcUnaryOperatorType, BINARY_OPERATOR, SimcBinaryOperatorType, ParseNode } from "./definitions";
import { LuaObj, tostring, lualength, pairs, tonumber } from "@wowts/lua";
import { OvaleDebugClass, Tracer } from "../Debug";
import { self_outputPool } from "./text-tools";
import { concat } from "@wowts/table";

function GetPrecedence(node: ParseNode) {
    let precedence = node.precedence;
    if (!precedence) {
        let operator = node.operator;
        if (operator) {
            if (node.expressionType == "unary" && UNARY_OPERATOR[operator as SimcUnaryOperatorType]) {
                precedence = UNARY_OPERATOR[operator as SimcUnaryOperatorType][2];
            } else if (node.expressionType == "binary" && BINARY_OPERATOR[operator as SimcBinaryOperatorType]) {
                precedence = BINARY_OPERATOR[operator as SimcBinaryOperatorType][2];
            }
        }
    }
    return precedence;
}

type UnparseFunction = (node: ParseNode) => string;

export class Unparser {
    private tracer: Tracer;

    constructor(ovaleDebug: OvaleDebugClass) {
        this.tracer = ovaleDebug.create("SimulationCraftUnparser");
    }

    public Unparse(node: ParseNode) {
        let visitor = this.UNPARSE_VISITOR[node.type];
        if (!visitor) {
            this.tracer.Error("Unable to unparse node of type '%s'.", node.type);
        } else {
            return visitor(node);
        }
    }
    private UnparseAction: UnparseFunction = (node: ParseNode) => {
        let output = self_outputPool.Get();
        output[lualength(output) + 1] = node.name;
        for (const [modifier, expressionNode] of pairs(node.child)) {
            output[lualength(output) + 1] = `${modifier}=${this.Unparse(expressionNode)}`;
        }
        let s = concat(output, ",");
        self_outputPool.Release(output);
        return s;
    }
    private UnparseActionList: UnparseFunction = (node: ParseNode) => {
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
            output[lualength(output) + 1] = `${listName}${operator}${this.Unparse(actionNode)}`;
        }
        let s = concat(output, "\n");
        self_outputPool.Release(output);
        return s;
    }
    private UnparseExpression: UnparseFunction = (node: ParseNode) => {
        let expression;
        let precedence = GetPrecedence(node);
        if (node.expressionType == "unary") {
            let rhsExpression;
            let rhsNode = node.child[1];
            let rhsPrecedence = GetPrecedence(rhsNode);
            if (rhsPrecedence && precedence >= rhsPrecedence) {
                rhsExpression = `(${this.Unparse(rhsNode)})`;
            } else {
                rhsExpression = this.Unparse(rhsNode);
            }
            expression = `${node.operator}${rhsExpression}`;
        } else if (node.expressionType == "binary") {
            let lhsExpression, rhsExpression;
            let lhsNode = node.child[1];
            let lhsPrecedence = GetPrecedence(lhsNode);
            if (lhsPrecedence && lhsPrecedence < precedence) {
                lhsExpression = `(${this.Unparse(lhsNode)})`;
            } else {
                lhsExpression = this.Unparse(lhsNode);
            }
            let rhsNode = node.child[2];
            let rhsPrecedence = GetPrecedence(rhsNode);
            if (rhsPrecedence && precedence > rhsPrecedence) {
                rhsExpression = `(${this.Unparse(rhsNode)})`;
            } else if (rhsPrecedence && precedence == rhsPrecedence) {
                if (BINARY_OPERATOR[node.operator as SimcBinaryOperatorType][3] == "associative" && node.operator == rhsNode.operator) {
                    rhsExpression = this.Unparse(rhsNode);
                } else {
                    rhsExpression = `(${this.Unparse(rhsNode)})`;
                }
            } else {
                rhsExpression = this.Unparse(rhsNode);
            }
            expression = `${lhsExpression}${node.operator}${rhsExpression}`;
        } else {
            return "Unknown node expression type";
        }
        return expression;
    }
    private UnparseFunction: UnparseFunction = (node: ParseNode) => {
        return `${node.name}(${this.Unparse(node.child[1])})`;
    }
    private UnparseNumber: UnparseFunction = (node: ParseNode) => {
        return tostring(node.value);
    }
    private UnparseOperand: UnparseFunction = (node: ParseNode) => {
        return node.name;
    }
 
    UNPARSE_VISITOR: LuaObj<(node: ParseNode) => string> = {
        ["action"]: this.UnparseAction,
        ["action_list"]: this.UnparseActionList,
        ["arithmetic"]: this.UnparseExpression,
        ["compare"]: this.UnparseExpression,
        ["function"]: this.UnparseFunction,
        ["logical"]: this.UnparseExpression,
        ["number"]: this.UnparseNumber,
        ["operand"]: this.UnparseOperand
    }
}