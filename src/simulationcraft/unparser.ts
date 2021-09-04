import {
    unaryOperators,
    SimcUnaryOperatorType,
    binaryOperators,
    SimcBinaryOperatorType,
    ParseNode,
    ActionParseNode,
    OperatorParseNode,
    ActionListParseNode,
    FunctionParseNode,
    NumberParseNode,
    OperandParseNode,
} from "./definitions";
import {
    ipairs,
    kpairs,
    lualength,
    pairs,
    tonumber,
    tostring,
    wipe,
} from "@wowts/lua";
import { DebugTools, Tracer } from "../engine/debug";
import { outputPool } from "./text-tools";
import { concat } from "@wowts/table";

function getPrecedence(node: ParseNode) {
    if (node.type !== "operator") return 0;
    let precedence = node.precedence;
    if (!precedence) {
        const operator = node.operator;
        if (operator) {
            if (
                node.expressionType == "unary" &&
                unaryOperators[operator as SimcUnaryOperatorType]
            ) {
                precedence =
                    unaryOperators[operator as SimcUnaryOperatorType][2];
            } else if (
                node.expressionType == "binary" &&
                binaryOperators[operator as SimcBinaryOperatorType]
            ) {
                precedence =
                    binaryOperators[operator as SimcBinaryOperatorType][2];
            }
        }
    }
    return precedence;
}

type UnparseFunction<T extends ParseNode> = (node: T) => string;

export class Unparser {
    private tracer: Tracer;

    constructor(ovaleDebug: DebugTools) {
        this.tracer = ovaleDebug.create("SimulationCraftUnparser");
    }

    public unparse(node: ParseNode) {
        // TODO
        const visitor = this.unparseVisitors[
            node.type
        ] as UnparseFunction<ParseNode>;
        if (!visitor) {
            this.tracer.error(
                "Unable to unparse node of type '%s'.",
                node.type
            );
        } else {
            return visitor(node);
        }
    }
    private unparseAction: UnparseFunction<ActionParseNode> = (node) => {
        const output = outputPool.get();
        output[lualength(output) + 1] = node.name;
        for (const [modifier, expressionNode] of kpairs(node.modifiers)) {
            output[lualength(output) + 1] = `${modifier}=${this.unparse(
                expressionNode
            )}`;
        }
        let s = concat(output, ",");
        if (node.sequence) {
            wipe(output);
            output[lualength(output) + 1] = s;
            for (const [, actionNode] of ipairs(node.sequence)) {
                output[lualength(output) + 1] = this.unparseAction(actionNode);
            }
            s = concat(output, ":");
        }
        outputPool.release(output);
        return s;
    };
    private unparseActionList: UnparseFunction<ActionListParseNode> = (
        node
    ) => {
        const output = outputPool.get();
        let listName;
        if (node.name == "_default") {
            listName = "action";
        } else {
            listName = `action.${node.name}`;
        }
        output[lualength(output) + 1] = "";
        for (const [i, actionNode] of pairs(node.child)) {
            const operator = (tonumber(i) == 1 && "=") || "+=/";
            output[
                lualength(output) + 1
            ] = `${listName}${operator}${this.unparse(actionNode)}`;
        }
        const s = concat(output, "\n");
        outputPool.release(output);
        return s;
    };
    private unparseExpression: UnparseFunction<OperatorParseNode> = (node) => {
        let expression;
        const precedence = getPrecedence(node);
        if (node.expressionType == "unary") {
            let rhsExpression;
            const rhsNode = node.child[1];
            const rhsPrecedence = getPrecedence(rhsNode);
            if (rhsPrecedence && precedence >= rhsPrecedence) {
                rhsExpression = `(${this.unparse(rhsNode)})`;
            } else {
                rhsExpression = this.unparse(rhsNode);
            }
            expression = `${node.operator}${rhsExpression}`;
        } else if (node.expressionType == "binary") {
            let lhsExpression, rhsExpression;
            const lhsNode = node.child[1];
            const lhsPrecedence = getPrecedence(lhsNode);
            if (lhsPrecedence && lhsPrecedence < precedence) {
                lhsExpression = `(${this.unparse(lhsNode)})`;
            } else {
                lhsExpression = this.unparse(lhsNode);
            }
            const rhsNode = node.child[2];
            const rhsPrecedence = getPrecedence(rhsNode);
            if (rhsPrecedence && precedence > rhsPrecedence) {
                rhsExpression = `(${this.unparse(rhsNode)})`;
            } else if (rhsPrecedence && precedence == rhsPrecedence) {
                if (
                    rhsNode.type === "operator" &&
                    binaryOperators[
                        node.operator as SimcBinaryOperatorType
                    ][3] == "associative" &&
                    node.operator == rhsNode.operator
                ) {
                    rhsExpression = this.unparse(rhsNode);
                } else {
                    rhsExpression = `(${this.unparse(rhsNode)})`;
                }
            } else {
                rhsExpression = this.unparse(rhsNode);
            }
            expression = `${lhsExpression}${node.operator}${rhsExpression}`;
        } else {
            return "Unknown node expression type";
        }
        return expression;
    };
    private unparseFunction: UnparseFunction<FunctionParseNode> = (node) => {
        return `${node.name}(${this.unparse(node.child[1])})`;
    };
    private unparseNumber: UnparseFunction<NumberParseNode> = (node) => {
        return tostring(node.value);
    };
    private unparseOperand: UnparseFunction<OperandParseNode> = (node) => {
        return node.name;
    };

    unparseVisitors = {
        ["action"]: this.unparseAction,
        ["action_list"]: this.unparseActionList,
        ["operator"]: this.unparseExpression,
        ["function"]: this.unparseFunction,
        ["number"]: this.unparseNumber,
        ["operand"]: this.unparseOperand,
    };
}
