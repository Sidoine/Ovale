import {
    ipairs,
    kpairs,
    loadstring,
    lualength,
    LuaObj,
    tostring,
    wipe,
} from "@wowts/lua";
import { abs, huge, huge as INFINITY, max, min } from "@wowts/math";
import {
    AstActionNode,
    AstBooleanNode,
    AstExpressionNode,
    AstFunctionNode,
    AstGroupNode,
    AstIfNode,
    AstLuaNode,
    AstNode,
    AstNodeSnapshot,
    AstNodeWithParameters,
    AstStringNode,
    AstTypedFunctionNode,
    AstUnlessNode,
    AstValueNode,
    AstVariableNode,
    isAstNodeWithChildren,
    NamedParameters,
    NamedParametersOf,
    NodeActionResult,
    NodeNoResult,
    NodeType,
    NodeTypes,
    PositionalParameters,
    setResultType,
} from "./ast";
import { BaseState } from "../states/BaseState";
import { ActionType } from "./best-action";
import { OvaleConditionClass } from "./condition";
import { DebugTools, Tracer } from "./debug";
import { OvaleProfilerClass, Profiler } from "./profiler";
import {
    newTimeSpan,
    OvaleTimeSpan,
    releaseTimeSpans,
    universe,
} from "../tools/TimeSpan";
import { isNumber, isString, oneTimeMessage } from "../tools/tools";

export type ActionInfo = [
    texture?: string,
    inRange?: boolean,
    cooldownStart?: number,
    cooldownDuration?: number,
    usable?: boolean,
    shortcut?: string,
    isCurrent?: boolean,
    enable?: boolean,
    type?: ActionType,
    id?: string | number,
    target?: string,
    resourceExtend?: number,
    charges?: number,
    castTime?: number
];

export type ActionInfoHandler = (
    element: AstActionNode,
    atTime: number,
    target: string
) => NodeActionResult | NodeNoResult;

type ComputerFunction<T extends AstNode> = (
    element: T,
    atTime: number
) => AstNodeSnapshot;

export class Runner {
    private profiler: Profiler;
    private tracer: Tracer;
    public serial = 0;
    private actionHandlers: LuaObj<ActionInfoHandler> = {};

    constructor(
        ovaleProfiler: OvaleProfilerClass,
        ovaleDebug: DebugTools,
        private baseState: BaseState,
        private ovaleCondition: OvaleConditionClass
    ) {
        this.profiler = ovaleProfiler.create("runner");
        this.tracer = ovaleDebug.create("runner");
    }

    public refresh() {
        this.serial = this.serial + 1;
        this.tracer.log("Advancing age to %d.", this.serial);
    }

    public postOrderCompute(element: AstNode, atTime: number): AstNodeSnapshot {
        this.profiler.startProfiling("OvaleBestAction_PostOrderCompute");
        let result: AstNodeSnapshot | undefined;
        const postOrder = element.postOrder;
        if (postOrder && element.result.serial !== this.serial) {
            this.tracer.log(
                "[%d] [[[ Compute '%s' post-order nodes.",
                element.nodeId,
                element.type
            );
            let index = 1;
            const n = lualength(postOrder);
            while (index < n) {
                const [childNode, parentNode] = [
                    postOrder[index],
                    postOrder[index + 1],
                ];
                index = index + 2;
                result = this.postOrderCompute(childNode, atTime);

                let shortCircuit = false;
                if (
                    isAstNodeWithChildren(parentNode) &&
                    parentNode.child[1] == childNode
                ) {
                    if (
                        parentNode.type == "if" &&
                        result.timeSpan.measure() == 0
                    ) {
                        this.tracer.log(
                            "[%d]    '%s' [%d] will trigger short-circuit evaluation of parent node '%s' [%d] with zero-measure time span.",
                            element.nodeId,
                            childNode.type,
                            childNode.nodeId,
                            parentNode.type,
                            parentNode.nodeId
                        );
                        shortCircuit = true;
                    } else if (
                        parentNode.type == "unless" &&
                        result.timeSpan.isUniverse()
                    ) {
                        this.tracer.log(
                            "[%d]    '%s' [%d] will trigger short-circuit evaluation of parent node '%s' [%d] with universe as time span.",
                            element.nodeId,
                            childNode.type,
                            childNode.nodeId,
                            parentNode.type,
                            parentNode.nodeId
                        );
                        shortCircuit = true;
                    } else if (
                        parentNode.type == "logical" &&
                        parentNode.operator == "and" &&
                        result.timeSpan.measure() == 0
                    ) {
                        this.tracer.log(
                            "[%d]    '%s' [%d] will trigger short-circuit evaluation of parent node '%s' [%d] with zero measure.",
                            element.nodeId,
                            childNode.type,
                            childNode.nodeId,
                            parentNode.type,
                            parentNode.nodeId
                        );
                        shortCircuit = true;
                    } else if (
                        parentNode.type == "logical" &&
                        parentNode.operator == "or" &&
                        result.timeSpan.isUniverse()
                    ) {
                        this.tracer.log(
                            "[%d]    '%s' [%d] will trigger short-circuit evaluation of parent node '%s' [%d] with universe as time span.",
                            element.nodeId,
                            childNode.type,
                            childNode.nodeId,
                            parentNode.type,
                            parentNode.nodeId
                        );
                        shortCircuit = true;
                    }
                }
                if (shortCircuit) {
                    while (parentNode != postOrder[index] && index <= n) {
                        index = index + 2;
                    }
                    if (index > n) {
                        this.tracer.error(
                            "Ran off end of postOrder node list for node %d.",
                            element.nodeId
                        );
                    }
                }
            }
            this.tracer.log(
                "[%d] ]]] Compute '%s' post-order nodes: complete.",
                element.nodeId,
                element.type
            );
        }
        this.recursiveCompute(element, atTime);
        this.profiler.stopProfiling("OvaleBestAction_PostOrderCompute");
        return element.result;
    }
    private recursiveCompute(
        element: AstNode,
        atTime: number
    ): AstNodeSnapshot {
        this.profiler.startProfiling("OvaleBestAction_RecursiveCompute");
        this.tracer.log(
            "[%d] >>> Computing '%s' at time=%f",
            element.nodeId,
            element.asString || element.type,
            atTime
        );
        if (element.result.constant) {
            // Constant value
            this.tracer.log(
                "[%d] <<< '%s' returns %s with constant %s",
                element.nodeId,
                element.asString || element.type,
                element.result.timeSpan,
                this.resultToString(element.result)
            );
            return element.result;
        } else if (element.result.serial == -1) {
            oneTimeMessage(
                "Recursive call is not supported in '%s'. Please fix the script.",
                element.asString || element.type
            );
            return element.result;
        } else if (element.result.serial === this.serial) {
            this.tracer.log(
                "[%d] <<< '%s' returns %s with cached %s",
                element.nodeId,
                element.asString || element.type,
                element.result.timeSpan,
                this.resultToString(element.result)
            );
        } else {
            // Set to -1 to prevent recursive call of this same node (see check above)
            element.result.serial = -1;
            const visitor = this.computeVisitors[
                element.type
            ] as ComputerFunction<typeof element>;
            let result;
            if (visitor) {
                result = visitor(element, atTime);
                element.result.serial = this.serial;

                this.tracer.log(
                    "[%d] <<< '%s' returns %s with computed %s",
                    element.nodeId,
                    element.asString || element.type,
                    result.timeSpan,
                    this.resultToString(element.result)
                );
            } else {
                this.tracer.error(
                    "[%d] Runtime error: unable to compute node of type '%s': %s.",
                    element.nodeId,
                    element.type,
                    element.asString
                );
                wipe(element.result.timeSpan);
                element.result.serial = this.serial;
            }
        }
        this.profiler.stopProfiling("OvaleBestAction_RecursiveCompute");
        return element.result;
    }

    private computeBool(element: AstNode, atTime: number) {
        const newElement = this.compute(element, atTime);
        // if (
        //     newElement.type === "value" &&
        //     newElement.value == 0 &&
        //     (newElement.rate == 0 || newElement.rate === undefined)
        // ) {
        //     // Force a value of 0 to be falsy
        //     return EMPTY_SET;
        // } else {
        return newElement.timeSpan;
        // }
    }

    public registerActionInfoHandler(name: string, handler: ActionInfoHandler) {
        this.actionHandlers[name] = handler;
    }

    public getActionInfo(
        element: AstActionNode,
        atTime: number,
        namedParameters: NamedParametersOf<AstActionNode>
    ) {
        if (element.result.serial === this.serial) {
            this.tracer.log(
                "[%d]    using cached result (age = %d/%d)",
                element.nodeId,
                element.result.serial,
                this.serial
            );
        } else {
            const target =
                (isString(namedParameters.target) && namedParameters.target) ||
                this.baseState.defaultTarget;
            const result = this.actionHandlers[element.name](
                element,
                atTime,
                target
            );
            if (result.type === "action") result.options = namedParameters;
        }
        return element.result;
    }

    private computeBoolean: ComputerFunction<AstBooleanNode> = (node) => {
        if (node.value) {
            this.getTimeSpan(node, universe);
        } else {
            this.getTimeSpan(node);
        }
        return node.result;
    };

    private computeAction: ComputerFunction<AstActionNode> = (
        node,
        atTime: number
    ) => {
        this.profiler.startProfiling("OvaleBestAction_ComputeAction");
        const nodeId = node.nodeId;
        const timeSpan = this.getTimeSpan(node);
        this.tracer.log("[%d]    evaluating action: %s()", nodeId, node.name);
        const [, namedParameters] = this.computeParameters(node, atTime);
        const result = this.getActionInfo(node, atTime, namedParameters);
        if (result.type !== "action") return result;

        const action = node.name;
        // element.positionalParams[1];
        if (result.actionTexture === undefined) {
            this.tracer.log("[%d]    Action %s not found.", nodeId, action);
            wipe(timeSpan);
            setResultType(result, "none");
        } else if (!result.actionEnable) {
            this.tracer.log("[%d]    Action %s not enabled.", nodeId, action);
            wipe(timeSpan);
            setResultType(result, "none");
        } else if (namedParameters.usable == 1 && !result.actionUsable) {
            this.tracer.log("[%d]    Action %s not usable.", nodeId, action);
            wipe(timeSpan);
            setResultType(result, "none");
        } else {
            if (result.castTime === undefined) {
                result.castTime = 0;
            }
            let start: number;
            if (
                result.actionCooldownStart !== undefined &&
                result.actionCooldownStart > 0 &&
                (result.actionCharges == undefined || result.actionCharges == 0)
            ) {
                this.tracer.log(
                    "[%d]    Action %s (actionCharges=%s)",
                    nodeId,
                    action,
                    result.actionCharges || "(nil)"
                );
                if (
                    result.actionCooldownDuration !== undefined &&
                    result.actionCooldownDuration > 0
                ) {
                    this.tracer.log(
                        "[%d]    Action %s is on cooldown (start=%f, duration=%f).",
                        nodeId,
                        action,
                        result.actionCooldownStart,
                        result.actionCooldownDuration
                    );
                    start =
                        result.actionCooldownStart +
                        result.actionCooldownDuration;
                } else {
                    this.tracer.log(
                        "[%d]    Action %s is waiting on the GCD (start=%f).",
                        nodeId,
                        action,
                        result.actionCooldownStart
                    );
                    start = result.actionCooldownStart;
                }
            } else {
                if (result.actionCharges == undefined) {
                    this.tracer.log(
                        "[%d]    Action %s is off cooldown.",
                        nodeId,
                        action
                    );
                    start = atTime;
                } else if (
                    result.actionCooldownDuration !== undefined &&
                    result.actionCooldownDuration > 0
                ) {
                    this.tracer.log(
                        "[%d]    Action %s still has %f charges and is not on GCD.",
                        nodeId,
                        action,
                        result.actionCharges
                    );
                    start = atTime;
                } else {
                    this.tracer.log(
                        "[%d]    Action %s still has %f charges but is on GCD (start=%f).",
                        nodeId,
                        action,
                        result.actionCharges,
                        result.actionCooldownStart
                    );
                    start = result.actionCooldownStart || 0;
                }
            }
            if (
                result.actionResourceExtend !== undefined &&
                result.actionResourceExtend > 0
            ) {
                if (
                    namedParameters.pool_resource !== undefined &&
                    namedParameters.pool_resource == 1
                ) {
                    this.tracer.log(
                        "[%d]    Action %s is ignoring resource requirements because it is a pool_resource action.",
                        nodeId,
                        action
                    );
                } else {
                    this.tracer.log(
                        "[%d]    Action %s is waiting on resources (start=%f, extend=%f).",
                        nodeId,
                        action,
                        start,
                        result.actionResourceExtend
                    );
                    start = start + result.actionResourceExtend;
                }
            }
            this.tracer.log(
                "[%d]    start=%f atTime=%f",
                nodeId,
                start,
                atTime
            );
            if (result.offgcd) {
                this.tracer.log(
                    "[%d]    Action %s is off the global cooldown.",
                    nodeId,
                    action
                );
            } else if (start < atTime) {
                this.tracer.log(
                    "[%d]    Action %s is waiting for the global cooldown.",
                    nodeId,
                    action
                );
                start = atTime;
            }
            this.tracer.log(
                "[%d]    Action %s can start at %f.",
                nodeId,
                action,
                start
            );
            timeSpan.copy(start, huge);
        }
        this.profiler.stopProfiling("OvaleBestAction_ComputeAction");
        return result;
    };
    private computeArithmetic: ComputerFunction<AstExpressionNode> = (
        element,
        atTime
    ) => {
        this.profiler.startProfiling("OvaleBestAction_ComputeArithmetic");
        const timeSpan = this.getTimeSpan(element);
        const result = element.result;
        const nodeA = this.compute(element.child[1], atTime);
        const [a, b, c, timeSpanA] = this.asValue(atTime, nodeA);
        const nodeB = this.compute(element.child[2], atTime);
        const [x, y, z, timeSpanB] = this.asValue(atTime, nodeB);
        timeSpanA.intersect(timeSpanB, timeSpan);
        if (timeSpan.measure() == 0) {
            this.tracer.log(
                "[%d]    arithmetic '%s' returns %s with zero measure",
                element.nodeId,
                element.operator,
                timeSpan
            );
            this.setValue(element, 0);
        } else {
            const operator = element.operator;
            const t = atTime;
            this.tracer.log(
                "[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s",
                element.nodeId,
                a,
                b,
                c,
                operator,
                x,
                y,
                z
            );
            let l, m, n; // The new value, origin, and rate
            if (!isNumber(a) || !isNumber(x)) {
                this.tracer.error(
                    "[%d] Operands of arithmetic operators must be numbers",
                    element.nodeId
                );
                return result;
            }
            const at = a + (t - b) * c; // the A value at time t
            let bt = x + (t - y) * z; // The B value at time t
            /**
             * A(t) = a + (t - b)*c
             *      = a + (t - t0 + t0 - b)*c, for all t0
             *      = a + (t - t0)*c + (t0 - b)*c
             *      = [a + (t0 - b)*c] + (t - t0)*c
             *      = A(t0) + (t - t0)*c
             * B(t) = B(t0) + (t - t0)*z
             */
            if (operator == "+") {
                /**
                 * A(t) + B(t) = [A(t0) + B(t0)] + (t - t0)*(c + z)
                 */
                l = at + bt;
                m = t;
                n = c + z;
            } else if (operator == "-") {
                /**
                 * A(t) - B(t) = [A(t0) - B(t0)] + (t - t0)*(c - z)
                 */
                l = at - bt;
                m = t;
                n = c - z;
            } else if (operator == "*") {
                /**
                 * A(t)*B(t) = [A(t0) + (t - t0)*c] * [B(t0) + (t - t0)*z]
                 *           = [A(t0)*B(t0)] + (t - t0)*[A(t0)*z + B(t0)*c] + (t - t0)^2*(c*z)
                 *           = [A(t0)*B(t0)] + (t - t0)*[A(t0)*z + B(t0)*c] + O(t^2)
                 */
                l = at * bt;
                m = t;
                n = at * z + bt * c;
            } else if (operator == "/") {
                /**
                 *      C(t) = 1/B(t)
                 *           = 1/[B(t0) - (t - t0)*z]
                 *      C(t) = C(t0) + C'(t0)*(t - t0) + O(t^2) (Taylor series at t = t0)
                 *           = 1/B(t0) + [-z/B(t0)^2]*(t - t0) + O(t^2) converges when |t - t0| < |B(t0)/z|
                 * A(t)/B(t) = A(t0)/B(t0) + (t - t0)*{[B(t0)*c - A(t0)*z]/B(t0)^2} + O(t^2)
                 *           = A(t0)/B(t0) + (t - t0)*{[c/B(t0)] - [A(t0)/B(t0)]*[z/B(t0)]} + O(t^2)
                 */
                if (bt === 0) {
                    if (at !== 0) {
                        oneTimeMessage(
                            "[%d] Division by 0 in %s",
                            element.nodeId,
                            element.asString
                        );
                    }
                    bt = 0.00001;
                }
                l = at / bt;
                m = t;
                n = c / bt - (at / bt) * (z / bt);
                let bound;
                if (z == 0) {
                    bound = huge;
                } else {
                    bound = abs(bt / z);
                }
                const scratch = timeSpan.intersectInterval(
                    t - bound,
                    t + bound
                );
                timeSpan.copyFromArray(scratch);
                scratch.release();
            } else if (operator == "%") {
                // A % B = A mod B
                if (c == 0 && z == 0) {
                    l = at % bt;
                    m = t;
                    n = 0;
                } else {
                    this.tracer.error(
                        "[%d]    Parameters of modulus operator '%' must be constants.",
                        element.nodeId
                    );
                    l = 0;
                    m = 0;
                    n = 0;
                }
            } else if (operator === "<?" || operator === ">?") {
                // A(t) <? B(t) = min(A(t), B(t))
                // A(t) >? B(t) = max(A(t), B(t))
                if (z === c) {
                    // A(t) and B(t) have the same slope.
                    l = (operator === "<?" && min(at, bt)) || max(at, bt);
                    m = t;
                    n = z;
                } else {
                    /**
                     * A(t) and B(t) intersect when:
                     *                   A(t) = B(t)
                     *     A(t0) - (t - t0)*c = B(t0) - (t - t0)*z
                     *       (t - t0)*(z - c) = B(t0) - A(t0)
                     *                 t - t0 = [B(t0) - A(t0)]/(z - c)
                     */
                    const ct = (bt - at) / (z - c);
                    if (ct <= 0) {
                        // A(t) and B(t) intersect at or to the left of t0.
                        const scratch = timeSpan.intersectInterval(
                            t + ct,
                            INFINITY
                        );
                        timeSpan.copyFromArray(scratch);
                        scratch.release();
                        if (z < c) {
                            // A(t) has a greater slope than B(t).
                            l = (operator === ">?" && at) || bt;
                        } else {
                            // B(t) has a greater slope than A(t).
                            l = (operator === "<?" && at) || bt;
                        }
                    } else {
                        // A(t) and B(t) intersect to the right of t0.
                        const scratch = timeSpan.intersectInterval(0, t + ct);
                        timeSpan.copyFromArray(scratch);
                        scratch.release();
                        if (z < c) {
                            // A(t) has a greater slope than B(t).
                            l = (operator === "<?" && at) || bt;
                        } else {
                            // B(t) has a greater slope than A(t).
                            l = (operator === ">?" && at) || bt;
                        }
                    }
                    m = t;
                    n = (l === at && c) || z;
                }
            }
            this.tracer.log(
                "[%d]    arithmetic '%s' returns %s+(t-%s)*%s",
                element.nodeId,
                operator,
                l,
                m,
                n
            );
            this.setValue(element, l, m, n);
        }
        this.profiler.stopProfiling("OvaleBestAction_ComputeArithmetic");
        return result;
    };
    private computeCompare: ComputerFunction<AstExpressionNode> = (
        element,
        atTime
    ) => {
        this.profiler.startProfiling("OvaleBestAction_ComputeCompare");
        const timeSpan = this.getTimeSpan(element);
        const elementA = this.compute(element.child[1], atTime);
        const [a, b, c, timeSpanA] = this.asValue(atTime, elementA);
        const elementB = this.compute(element.child[2], atTime);
        const [x, y, z, timeSpanB] = this.asValue(atTime, elementB);
        timeSpanA.intersect(timeSpanB, timeSpan);

        if (timeSpan.measure() == 0) {
            this.tracer.log(
                "[%d]    compare '%s' returns %s with zero measure",
                element.nodeId,
                element.operator,
                timeSpan
            );
        } else {
            const operator = element.operator;
            this.tracer.log(
                "[%d]    %s+(t-%s)*%s %s %s+(t-%s)*%s",
                element.nodeId,
                a,
                b,
                c,
                operator,
                x,
                y,
                z
            );
            if (!isNumber(a) || !isNumber(x)) {
                if (
                    (operator === "==" && a !== b) ||
                    (operator === "!=" && a === b)
                ) {
                    wipe(timeSpan);
                }
                return element.result;
            }
            const at = a - b * c;
            const bt = x - y * z;
            if (c == z) {
                if (
                    !(
                        (operator == "==" && at == bt) ||
                        (operator == "!=" && at != bt) ||
                        (operator == "<" && at < bt) ||
                        (operator == "<=" && at <= bt) ||
                        (operator == ">" && at > bt) ||
                        (operator == ">=" && at >= bt)
                    )
                ) {
                    wipe(timeSpan);
                }
            } else {
                const diff = bt - at;
                let t;
                if (diff == huge) {
                    t = huge;
                } else {
                    t = diff / (c - z);
                }
                t = (t > 0 && t) || 0;
                this.tracer.log(
                    "[%d]    intersection at t = %s",
                    element.nodeId,
                    t
                );
                let scratch: OvaleTimeSpan | undefined;
                if (
                    (c > z && operator == "<") ||
                    (c > z && operator == "<=") ||
                    (c < z && operator == ">") ||
                    (c < z && operator == ">=")
                ) {
                    scratch = timeSpan.intersectInterval(0, t);
                } else if (
                    (c < z && operator == "<") ||
                    (c < z && operator == "<=") ||
                    (c > z && operator == ">") ||
                    (c > z && operator == ">=")
                ) {
                    scratch = timeSpan.intersectInterval(t, huge);
                }
                if (scratch) {
                    timeSpan.copyFromArray(scratch);
                    scratch.release();
                } else {
                    wipe(timeSpan);
                }
            }
            this.tracer.log(
                "[%d]    compare '%s' returns %s",
                element.nodeId,
                operator,
                timeSpan
            );
        }
        this.profiler.stopProfiling("OvaleBestAction_ComputeCompare");
        return element.result;
    };
    private computeCustomFunction: ComputerFunction<AstFunctionNode> = (
        element,
        atTime
    ): AstNodeSnapshot => {
        this.profiler.startProfiling("OvaleBestAction_ComputeCustomFunction");
        const timeSpan = this.getTimeSpan(element);
        const result = element.result;
        const node =
            element.annotation.customFunction &&
            element.annotation.customFunction[element.name];
        if (node) {
            if (this.tracer.debugTools.trace)
                this.tracer.log(
                    "[%d]: calling custom function [%d] %s",
                    element.nodeId,
                    node.child[1].nodeId,
                    element.name
                );
            const elementA = this.compute(node.child[1], atTime);
            timeSpan.copyFromArray(elementA.timeSpan);
            if (this.tracer.debugTools.trace)
                this.tracer.log(
                    "[%d]: [%d] %s is returning %s with timespan = %s",
                    element.nodeId,
                    node.child[1].nodeId,
                    element.name,
                    this.resultToString(elementA),
                    timeSpan
                );
            this.copyResult(result, elementA);
        } else {
            this.tracer.error(`Unable to find ${element.name}`);
            wipe(timeSpan);
        }
        this.profiler.stopProfiling("OvaleBestAction_ComputeCustomFunction");
        return result;
    };

    // private copyValue(target: AstNodeSnapshot, source: AstNodeSnapshot) {
    //     target.value = source.value;
    //     target.rate = source.rate;
    //     target.origin = source.origin;
    // }

    private copyResult(target: AstNodeSnapshot, source: AstNodeSnapshot) {
        for (const [k] of kpairs(target)) {
            if (
                k !== "timeSpan" &&
                k !== "type" &&
                k !== "serial" &&
                source[k] === undefined
            )
                delete target[k];
        }
        for (const [k, v] of kpairs(source)) {
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            if (
                k !== "timeSpan" &&
                k !== "serial" &&
                k !== "constant" &&
                target[k] !== v
            ) {
                (target[k] as any) = v;
            }
        }
    }

    private computeFunction: ComputerFunction<AstFunctionNode> = (
        element,
        atTime: number
    ) => {
        this.profiler.startProfiling("OvaleBestAction_ComputeFunction");
        const timeSpan = this.getTimeSpan(element);
        const [positionalParams, namedParams] = this.computeParameters(
            element,
            atTime
        );
        const [
            start,
            ending,
            value,
            origin,
            rate,
        ] = this.ovaleCondition.evaluateCondition(
            element.name,
            positionalParams,
            namedParams,
            atTime
        );
        if (start !== undefined && ending !== undefined) {
            timeSpan.copy(start, ending);
        } else {
            wipe(timeSpan);
        }
        if (value !== undefined) {
            this.setValue(element, value, origin, rate);
        }
        this.tracer.log(
            "[%d]    condition '%s' returns %s, %s, %s, %s, %s",
            element.nodeId,
            element.name,
            start,
            ending,
            value,
            origin,
            rate
        );
        this.profiler.stopProfiling("OvaleBestAction_ComputeFunction");
        return element.result;
    };

    private computeTypedFunction: ComputerFunction<AstTypedFunctionNode> = (
        element,
        atTime: number
    ) => {
        this.profiler.startProfiling("OvaleBestAction_ComputeFunction");
        const timeSpan = this.getTimeSpan(element);
        const positionalParams = this.computePositionalParameters(
            element,
            atTime
        );
        const [start, ending, value, origin, rate] = this.ovaleCondition.call(
            element.name,
            atTime,
            positionalParams
        );
        if (start !== undefined && ending !== undefined) {
            timeSpan.copy(start, ending);
        } else {
            wipe(timeSpan);
        }
        if (value !== undefined) {
            this.setValue(element, value, origin, rate);
        }
        this.tracer.log(
            "[%d]    condition '%s' returns %s, %s, %s, %s, %s",
            element.nodeId,
            element.name,
            start,
            ending,
            value,
            origin,
            rate
        );
        this.profiler.stopProfiling("OvaleBestAction_ComputeFunction");
        return element.result;
    };

    private computeGroup: ComputerFunction<AstGroupNode> = (group, atTime) => {
        this.profiler.startProfiling("OvaleBestAction_ComputeGroup");
        let bestTimeSpan, bestElement;
        const best = newTimeSpan();
        const currentTimeSpanAfterTime = newTimeSpan();
        for (const [, child] of ipairs(group.child)) {
            const nodeString = child.asString || child.type;
            this.tracer.log(
                "[%d]    checking child '%s' [%d]",
                group.nodeId,
                nodeString,
                child.nodeId
            );
            const currentElement = this.compute(child, atTime);
            const currentElementTimeSpan = currentElement.timeSpan;
            wipe(currentTimeSpanAfterTime);
            currentElementTimeSpan.intersectInterval(
                atTime,
                huge,
                currentTimeSpanAfterTime
            );
            this.tracer.log(
                "[%d]    child '%s' [%d]: %s",
                group.nodeId,
                nodeString,
                child.nodeId,
                currentTimeSpanAfterTime
            );
            if (currentTimeSpanAfterTime.measure() > 0) {
                let currentIsBetter = false;
                if (best.measure() == 0 || bestElement === undefined) {
                    this.tracer.log(
                        "[%d]    group first best is '%s' [%d]: %s",
                        group.nodeId,
                        nodeString,
                        child.nodeId,
                        currentTimeSpanAfterTime
                    );
                    currentIsBetter = true;
                } else {
                    const threshold =
                        (bestElement.type === "action" &&
                            bestElement.options &&
                            bestElement.options.wait) ||
                        0;
                    const difference = best[1] - currentTimeSpanAfterTime[1];
                    if (
                        difference > threshold ||
                        (difference === threshold &&
                            bestElement.type === "action" &&
                            currentElement.type === "action" &&
                            !bestElement.actionUsable &&
                            currentElement.actionUsable)
                    ) {
                        this.tracer.log(
                            "[%d]    group new best is '%s' [%d]: %s",
                            group.nodeId,
                            nodeString,
                            child.nodeId,
                            currentElementTimeSpan
                        );
                        currentIsBetter = true;
                    } else {
                        this.tracer.log(
                            "[%d]    group best is still %s: %s",
                            group.nodeId,
                            this.resultToString(group.result),
                            best
                        );
                    }
                }
                if (currentIsBetter) {
                    best.copyFromArray(currentTimeSpanAfterTime);
                    bestTimeSpan = currentElementTimeSpan;
                    bestElement = currentElement;
                }
            } else {
                this.tracer.log(
                    "[%d]    child '%s' [%d] has zero measure, skipping",
                    group.nodeId,
                    nodeString,
                    child.nodeId
                );
            }
        }
        releaseTimeSpans(best, currentTimeSpanAfterTime);
        const timeSpan = this.getTimeSpan(group, bestTimeSpan);
        if (bestElement) {
            this.copyResult(group.result, bestElement);
            this.tracer.log(
                "[%d]    group best action remains %s at %s",
                group.nodeId,
                this.resultToString(group.result),
                timeSpan
            );
        } else {
            setResultType(group.result, "none");

            this.tracer.log(
                "[%d]    group no best action returns %s at %s",
                group.nodeId,
                this.resultToString(group.result),
                timeSpan
            );
        }
        this.profiler.stopProfiling("OvaleBestAction_ComputeGroup");
        return group.result;
    };

    private resultToString(result: AstNodeSnapshot) {
        if (result.type === "value") {
            if (result.value === undefined) {
                return "nil value";
            }
            if (isString(result.value)) {
                return `value "${result.value}"`;
            }
            if (isNumber(result.value)) {
                return `value ${result.value} + (t - ${tostring(
                    result.origin
                )}) * ${tostring(result.rate)}`;
            }
            return `value ${(result.value === true && "true") || "false"}`;
        } else if (result.type === "action") {
            return `action ${result.actionType || "?"} ${
                result.actionId || "nil"
            }`;
        } else if (result.type === "none") {
            return `none`;
        } else if (result.type === "state") {
            return `state ${result.name}`;
        }
        return "";
    }

    private computeIf: ComputerFunction<AstIfNode | AstUnlessNode> = (
        element,
        atTime
    ) => {
        this.profiler.startProfiling("OvaleBestAction_ComputeIf");
        const timeSpan = this.getTimeSpan(element);
        const result = element.result;
        const timeSpanA = this.computeBool(element.child[1], atTime);
        let conditionTimeSpan = timeSpanA;
        if (element.type == "unless") {
            conditionTimeSpan = timeSpanA.complement();
        }
        if (conditionTimeSpan.measure() == 0) {
            timeSpan.copyFromArray(conditionTimeSpan);
            this.tracer.log(
                "[%d]    '%s' returns %s with zero measure",
                element.nodeId,
                element.type,
                timeSpan
            );
        } else {
            const elementB = this.compute(element.child[2], atTime);
            conditionTimeSpan.intersect(elementB.timeSpan, timeSpan);
            this.tracer.log(
                "[%d]    '%s' returns %s (intersection of %s and %s)",
                element.nodeId,
                element.type,
                timeSpan,
                conditionTimeSpan,
                elementB.timeSpan
            );
            this.copyResult(result, elementB);
        }
        if (element.type == "unless") {
            conditionTimeSpan.release();
        }
        this.profiler.stopProfiling("OvaleBestAction_ComputeIf");
        return result;
    };

    private computeLogical: ComputerFunction<AstExpressionNode> = (
        element,
        atTime
    ) => {
        this.profiler.startProfiling("OvaleBestAction_ComputeLogical");
        const timeSpan = this.getTimeSpan(element);
        const timeSpanA = this.computeBool(element.child[1], atTime);
        if (element.operator == "and") {
            if (timeSpanA.measure() == 0) {
                timeSpan.copyFromArray(timeSpanA);
                this.tracer.log(
                    "[%d]    logical '%s' short-circuits with zero measure left argument",
                    element.nodeId,
                    element.operator
                );
            } else {
                const timeSpanB = this.computeBool(element.child[2], atTime);
                timeSpanA.intersect(timeSpanB, timeSpan);
            }
        } else if (element.operator == "not") {
            timeSpanA.complement(timeSpan);
        } else if (element.operator == "or") {
            if (timeSpanA.isUniverse()) {
                timeSpan.copyFromArray(timeSpanA);
                this.tracer.log(
                    "[%d]    logical '%s' short-circuits with universe as left argument",
                    element.nodeId,
                    element.operator
                );
            } else {
                const timeSpanB = this.computeBool(element.child[2], atTime);
                timeSpanA.union(timeSpanB, timeSpan);
            }
        } else if (element.operator == "xor") {
            const timeSpanB = this.computeBool(element.child[2], atTime);
            const left = timeSpanA.union(timeSpanB);
            const scratch = timeSpanA.intersect(timeSpanB);
            const right = scratch.complement();
            left.intersect(right, timeSpan);
            releaseTimeSpans(left, scratch, right);
        } else {
            wipe(timeSpan);
        }

        this.tracer.log(
            "[%d]    logical '%s' returns %s",
            element.nodeId,
            element.operator,
            timeSpan
        );
        this.profiler.stopProfiling("OvaleBestAction_ComputeLogical");
        return element.result;
    };
    private computeLua: ComputerFunction<AstLuaNode> = (element) => {
        if (!element.lua) return element.result;
        this.profiler.startProfiling("OvaleBestAction_ComputeLua");
        const value = loadstring(element.lua)();
        this.tracer.log("[%d]    lua returns %s", element.nodeId, value);
        if (value !== undefined) {
            this.setValue(element, value);
        }
        this.getTimeSpan(element, universe);
        this.profiler.stopProfiling("OvaleBestAction_ComputeLua");
        return element.result;
    };

    private computeValue: ComputerFunction<AstValueNode> = (element) => {
        this.profiler.startProfiling("OvaleBestAction_ComputeValue");
        this.tracer.log("[%d]    value is %s", element.nodeId, element.value);
        this.getTimeSpan(element, universe);
        this.setValue(element, element.value, element.origin, element.rate);
        this.profiler.stopProfiling("OvaleBestAction_ComputeValue");
        return element.result;
    };

    private computeString: ComputerFunction<AstStringNode> = (element) => {
        this.tracer.log("[%d]    value is %s", element.nodeId, element.value);
        this.getTimeSpan(element, universe);
        this.setValue(element, element.value, undefined, undefined);
        return element.result;
    };

    private computeVariable: ComputerFunction<AstVariableNode> = (element) => {
        // TODO This should not happen but it's to support many old cases where an undefined variable name is used
        // as a string
        this.tracer.log("[%d]    value is %s", element.nodeId, element.name);
        this.getTimeSpan(element, universe);
        this.setValue(element, element.name, undefined, undefined);
        return element.result;
    };

    private setValue(
        node: AstNode,
        value?: number | string,
        origin?: number,
        rate?: number
    ): void {
        const result = node.result;
        if (result.type !== "value") {
            setResultType(result, "value");
        }
        value = value || 0;
        origin = origin || 0;
        rate = rate || 0;
        if (
            value !== result.value ||
            result.origin !== origin ||
            result.rate !== rate
        ) {
            result.value = value;
            result.origin = origin;
            result.rate = rate;
        }
    }

    private asValue(
        atTime: number,
        node: AstNodeSnapshot
    ): [
        value: number | string | boolean,
        origin: number,
        rate: number,
        timeSpan: OvaleTimeSpan
    ] {
        let value: number | string | boolean,
            origin: number,
            rate: number,
            timeSpan;
        if (node.type === "value" && node.value !== undefined) {
            value = node.value;
            origin = node.origin || 0;
            rate = node.rate || 0;
            timeSpan = node.timeSpan || universe;
        } else if (node.timeSpan.hasTime(atTime)) {
            [value, origin, rate, timeSpan] = [1, 0, 0, universe];
        } else {
            [value, origin, rate, timeSpan] = [0, 0, 0, universe];
        }
        return [value, origin, rate, timeSpan];
    }

    private getTimeSpan(node: AstNode, defaultTimeSpan?: OvaleTimeSpan) {
        const timeSpan = node.result.timeSpan;
        if (defaultTimeSpan) {
            timeSpan.copyFromArray(defaultTimeSpan);
        } else {
            wipe(timeSpan);
        }
        return timeSpan;
    }

    public compute(element: AstNode, atTime: number): AstNodeSnapshot {
        return this.postOrderCompute(element, atTime);
    }

    public computeAsBoolean(element: AstNode, atTime: number) {
        const result = this.recursiveCompute(element, atTime);
        return result.timeSpan.hasTime(atTime);
    }

    public computeAsNumber(element: AstNode, atTime: number) {
        const result = this.recursiveCompute(element, atTime);
        if (result.type === "value" && isNumber(result.value)) {
            if (result.origin !== undefined && result.rate !== undefined)
                return result.value + result.rate * (atTime - result.origin);
            return result.value;
        }
        return 0;
    }

    public computeAsString(element: AstNode, atTime: number) {
        const result = this.recursiveCompute(element, atTime);
        if (result.type === "value" && isString(result.value)) {
            return result.value;
        }
        return undefined;
    }

    public computeAsValue(element: AstNode, atTime: number) {
        const result = this.recursiveCompute(element, atTime);
        if (result.type === "value") {
            if (!result.timeSpan.hasTime(atTime)) return undefined;
            return result.value;
        }
        return result.timeSpan.hasTime(atTime);
    }

    public computeParameters<T extends NodeType, P extends string>(
        node: AstNodeWithParameters<T, P>,
        atTime: number
    ): [PositionalParameters, NamedParameters<P>] {
        if (
            node.cachedParams.serial === undefined ||
            node.cachedParams.serial < this.serial
        ) {
            node.cachedParams.serial = this.serial;

            for (const [k, v] of ipairs(node.rawPositionalParams)) {
                node.cachedParams.positional[k] =
                    this.computeAsValue(v, atTime) || false;
            }

            for (const [k, v] of kpairs(node.rawNamedParams)) {
                node.cachedParams.named[k] = this.computeAsValue(v, atTime);
            }
        }

        return [node.cachedParams.positional, node.cachedParams.named];
    }

    public computePositionalParameters<T extends NodeType, P extends string>(
        node: AstNodeWithParameters<T, P>,
        atTime: number
    ): PositionalParameters {
        if (
            node.cachedParams.serial === undefined ||
            node.cachedParams.serial < this.serial
        ) {
            this.tracer.log("computing positional parameters");
            node.cachedParams.serial = this.serial;
            for (const [k, v] of ipairs(node.rawPositionalParams)) {
                node.cachedParams.positional[k] = this.computeAsValue(
                    v,
                    atTime
                );
            }
        }

        return node.cachedParams.positional;
    }

    computeVisitors: {
        [k in AstNode["type"]]?: ComputerFunction<NodeTypes[k]>;
    } = {
        ["action"]: this.computeAction,
        ["arithmetic"]: this.computeArithmetic,
        ["boolean"]: this.computeBoolean,
        ["compare"]: this.computeCompare,
        ["custom_function"]: this.computeCustomFunction,
        ["function"]: this.computeFunction,
        ["group"]: this.computeGroup,
        ["if"]: this.computeIf,
        ["logical"]: this.computeLogical,
        ["lua"]: this.computeLua,
        ["state"]: this.computeFunction,
        ["string"]: this.computeString,
        ["typed_function"]: this.computeTypedFunction,
        ["unless"]: this.computeIf,
        ["value"]: this.computeValue,
        ["variable"]: this.computeVariable,
    };
}
