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
import { OvaleDebugClass, Tracer } from "./debug";
import { OvaleProfilerClass, Profiler } from "./profiler";
import {
    newTimeSpan,
    OvaleTimeSpan,
    releaseTimeSpans,
    UNIVERSE,
} from "../tools/TimeSpan";
import { isNumber, isString, OneTimeMessage } from "../tools/tools";

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
    public self_serial = 0;
    private actionHandlers: LuaObj<ActionInfoHandler> = {};

    constructor(
        ovaleProfiler: OvaleProfilerClass,
        ovaleDebug: OvaleDebugClass,
        private baseState: BaseState,
        private ovaleCondition: OvaleConditionClass
    ) {
        this.profiler = ovaleProfiler.create("runner");
        this.tracer = ovaleDebug.create("runner");
    }

    public refresh() {
        this.self_serial = this.self_serial + 1;
        this.tracer.Log("Advancing age to %d.", this.self_serial);
    }

    public PostOrderCompute(element: AstNode, atTime: number): AstNodeSnapshot {
        this.profiler.StartProfiling("OvaleBestAction_PostOrderCompute");
        let result: AstNodeSnapshot | undefined;
        const postOrder = element.postOrder;
        if (postOrder && element.result.serial !== this.self_serial) {
            this.tracer.Log(
                "[%d] [[[ Compute '%s' post-order nodes.",
                element.nodeId,
                element.type
            );
            let index = 1;
            const N = lualength(postOrder);
            while (index < N) {
                const [childNode, parentNode] = [
                    postOrder[index],
                    postOrder[index + 1],
                ];
                index = index + 2;
                result = this.PostOrderCompute(childNode, atTime);

                let shortCircuit = false;
                if (
                    isAstNodeWithChildren(parentNode) &&
                    parentNode.child[1] == childNode
                ) {
                    if (
                        parentNode.type == "if" &&
                        result.timeSpan.Measure() == 0
                    ) {
                        this.tracer.Log(
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
                        result.timeSpan.IsUniverse()
                    ) {
                        this.tracer.Log(
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
                        result.timeSpan.Measure() == 0
                    ) {
                        this.tracer.Log(
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
                        result.timeSpan.IsUniverse()
                    ) {
                        this.tracer.Log(
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
                    while (parentNode != postOrder[index] && index <= N) {
                        index = index + 2;
                    }
                    if (index > N) {
                        this.tracer.Error(
                            "Ran off end of postOrder node list for node %d.",
                            element.nodeId
                        );
                    }
                }
            }
            this.tracer.Log(
                "[%d] ]]] Compute '%s' post-order nodes: complete.",
                element.nodeId,
                element.type
            );
        }
        this.RecursiveCompute(element, atTime);
        this.profiler.StopProfiling("OvaleBestAction_PostOrderCompute");
        return element.result;
    }
    private RecursiveCompute(
        element: AstNode,
        atTime: number
    ): AstNodeSnapshot {
        this.profiler.StartProfiling("OvaleBestAction_RecursiveCompute");
        this.tracer.Log(
            "[%d] >>> Computing '%s' at time=%f",
            element.nodeId,
            element.asString || element.type,
            atTime
        );
        if (element.result.constant) {
            // Constant value
            this.tracer.Log(
                "[%d] <<< '%s' returns %s with constant %s",
                element.nodeId,
                element.asString || element.type,
                element.result.timeSpan,
                this.resultToString(element.result)
            );
            return element.result;
        } else if (element.result.serial == -1) {
            OneTimeMessage(
                "Recursive call is not supported in '%s'. Please fix the script.",
                element.asString || element.type
            );
            return element.result;
        } else if (element.result.serial === this.self_serial) {
            this.tracer.Log(
                "[%d] <<< '%s' returns %s with cached %s",
                element.nodeId,
                element.asString || element.type,
                element.result.timeSpan,
                this.resultToString(element.result)
            );
        } else {
            // Set to -1 to prevent recursive call of this same node (see check above)
            element.result.serial = -1;
            const visitor = this.COMPUTE_VISITOR[
                element.type
            ] as ComputerFunction<typeof element>;
            let result;
            if (visitor) {
                result = visitor(element, atTime);
                element.result.serial = this.self_serial;

                this.tracer.Log(
                    "[%d] <<< '%s' returns %s with computed %s",
                    element.nodeId,
                    element.asString || element.type,
                    result.timeSpan,
                    this.resultToString(element.result)
                );
            } else {
                this.tracer.Error(
                    "[%d] Runtime error: unable to compute node of type '%s': %s.",
                    element.nodeId,
                    element.type,
                    element.asString
                );
                wipe(element.result.timeSpan);
                element.result.serial = this.self_serial;
            }
        }
        this.profiler.StopProfiling("OvaleBestAction_RecursiveCompute");
        return element.result;
    }

    private ComputeBool(element: AstNode, atTime: number) {
        const newElement = this.Compute(element, atTime);
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

    public GetActionInfo(
        element: AstActionNode,
        atTime: number,
        namedParameters: NamedParametersOf<AstActionNode>
    ) {
        if (element.result.serial === this.self_serial) {
            this.tracer.Log(
                "[%d]    using cached result (age = %d/%d)",
                element.nodeId,
                element.result.serial,
                this.self_serial
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
            this.GetTimeSpan(node, UNIVERSE);
        } else {
            this.GetTimeSpan(node);
        }
        return node.result;
    };

    private ComputeAction: ComputerFunction<AstActionNode> = (
        node,
        atTime: number
    ) => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeAction");
        const nodeId = node.nodeId;
        const timeSpan = this.GetTimeSpan(node);
        this.tracer.Log("[%d]    evaluating action: %s()", nodeId, node.name);
        const [, namedParameters] = this.computeParameters(node, atTime);
        const result = this.GetActionInfo(node, atTime, namedParameters);
        if (result.type !== "action") return result;

        const action = node.name;
        // element.positionalParams[1];
        if (result.actionTexture === undefined) {
            this.tracer.Log("[%d]    Action %s not found.", nodeId, action);
            wipe(timeSpan);
            setResultType(result, "none");
        } else if (!result.actionEnable) {
            this.tracer.Log("[%d]    Action %s not enabled.", nodeId, action);
            wipe(timeSpan);
            setResultType(result, "none");
        } else if (namedParameters.usable == 1 && !result.actionUsable) {
            this.tracer.Log("[%d]    Action %s not usable.", nodeId, action);
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
                this.tracer.Log(
                    "[%d]    Action %s (actionCharges=%s)",
                    nodeId,
                    action,
                    result.actionCharges || "(nil)"
                );
                if (
                    result.actionCooldownDuration !== undefined &&
                    result.actionCooldownDuration > 0
                ) {
                    this.tracer.Log(
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
                    this.tracer.Log(
                        "[%d]    Action %s is waiting on the GCD (start=%f).",
                        nodeId,
                        action,
                        result.actionCooldownStart
                    );
                    start = result.actionCooldownStart;
                }
            } else {
                if (result.actionCharges == undefined) {
                    this.tracer.Log(
                        "[%d]    Action %s is off cooldown.",
                        nodeId,
                        action
                    );
                    start = atTime;
                } else if (
                    result.actionCooldownDuration !== undefined &&
                    result.actionCooldownDuration > 0
                ) {
                    this.tracer.Log(
                        "[%d]    Action %s still has %f charges and is not on GCD.",
                        nodeId,
                        action,
                        result.actionCharges
                    );
                    start = atTime;
                } else {
                    this.tracer.Log(
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
                    this.tracer.Log(
                        "[%d]    Action %s is ignoring resource requirements because it is a pool_resource action.",
                        nodeId,
                        action
                    );
                } else {
                    this.tracer.Log(
                        "[%d]    Action %s is waiting on resources (start=%f, extend=%f).",
                        nodeId,
                        action,
                        start,
                        result.actionResourceExtend
                    );
                    start = start + result.actionResourceExtend;
                }
            }
            this.tracer.Log(
                "[%d]    start=%f atTime=%f",
                nodeId,
                start,
                atTime
            );
            if (result.offgcd) {
                this.tracer.Log(
                    "[%d]    Action %s is off the global cooldown.",
                    nodeId,
                    action
                );
            } else if (start < atTime) {
                this.tracer.Log(
                    "[%d]    Action %s is waiting for the global cooldown.",
                    nodeId,
                    action
                );
                start = atTime;
            }
            this.tracer.Log(
                "[%d]    Action %s can start at %f.",
                nodeId,
                action,
                start
            );
            timeSpan.Copy(start, huge);
        }
        this.profiler.StopProfiling("OvaleBestAction_ComputeAction");
        return result;
    };
    private ComputeArithmetic: ComputerFunction<AstExpressionNode> = (
        element,
        atTime
    ) => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeArithmetic");
        const timeSpan = this.GetTimeSpan(element);
        const result = element.result;
        const nodeA = this.Compute(element.child[1], atTime);
        const [a, b, c, timeSpanA] = this.AsValue(atTime, nodeA);
        const nodeB = this.Compute(element.child[2], atTime);
        const [x, y, z, timeSpanB] = this.AsValue(atTime, nodeB);
        timeSpanA.Intersect(timeSpanB, timeSpan);
        if (timeSpan.Measure() == 0) {
            this.tracer.Log(
                "[%d]    arithmetic '%s' returns %s with zero measure",
                element.nodeId,
                element.operator,
                timeSpan
            );
            this.SetValue(element, 0);
        } else {
            const operator = element.operator;
            const t = atTime;
            this.tracer.Log(
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
                this.tracer.Error(
                    "[%d] Operands of arithmetic operators must be numbers",
                    element.nodeId
                );
                return result;
            }
            const A = a + (t - b) * c; // the A value at time t
            let B = x + (t - y) * z; // The B value at time t
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
                l = A + B;
                m = t;
                n = c + z;
            } else if (operator == "-") {
                /**
                 * A(t) - B(t) = [A(t0) - B(t0)] + (t - t0)*(c - z)
                 */
                l = A - B;
                m = t;
                n = c - z;
            } else if (operator == "*") {
                /**
                 * A(t)*B(t) = [A(t0) + (t - t0)*c] * [B(t0) + (t - t0)*z]
                 *           = [A(t0)*B(t0)] + (t - t0)*[A(t0)*z + B(t0)*c] + (t - t0)^2*(c*z)
                 *           = [A(t0)*B(t0)] + (t - t0)*[A(t0)*z + B(t0)*c] + O(t^2)
                 */
                l = A * B;
                m = t;
                n = A * z + B * c;
            } else if (operator == "/") {
                /**
                 *      C(t) = 1/B(t)
                 *           = 1/[B(t0) - (t - t0)*z]
                 *      C(t) = C(t0) + C'(t0)*(t - t0) + O(t^2) (Taylor series at t = t0)
                 *           = 1/B(t0) + [-z/B(t0)^2]*(t - t0) + O(t^2) converges when |t - t0| < |B(t0)/z|
                 * A(t)/B(t) = A(t0)/B(t0) + (t - t0)*{[B(t0)*c - A(t0)*z]/B(t0)^2} + O(t^2)
                 *           = A(t0)/B(t0) + (t - t0)*{[c/B(t0)] - [A(t0)/B(t0)]*[z/B(t0)]} + O(t^2)
                 */
                if (B === 0) {
                    if (A !== 0) {
                        OneTimeMessage(
                            "[%d] Division by 0 in %s",
                            element.nodeId,
                            element.asString
                        );
                    }
                    B = 0.00001;
                }
                l = A / B;
                m = t;
                n = c / B - (A / B) * (z / B);
                let bound;
                if (z == 0) {
                    bound = huge;
                } else {
                    bound = abs(B / z);
                }
                const scratch = timeSpan.IntersectInterval(
                    t - bound,
                    t + bound
                );
                timeSpan.copyFromArray(scratch);
                scratch.Release();
            } else if (operator == "%") {
                // A % B = A mod B
                if (c == 0 && z == 0) {
                    l = A % B;
                    m = t;
                    n = 0;
                } else {
                    this.tracer.Error(
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
                    l = (operator === "<?" && min(A, B)) || max(A, B);
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
                    const C = (B - A) / (z - c);
                    if (C <= 0) {
                        // A(t) and B(t) intersect at or to the left of t0.
                        const scratch = timeSpan.IntersectInterval(
                            t + C,
                            INFINITY
                        );
                        timeSpan.copyFromArray(scratch);
                        scratch.Release();
                        if (z < c) {
                            // A(t) has a greater slope than B(t).
                            l = (operator === ">?" && A) || B;
                        } else {
                            // B(t) has a greater slope than A(t).
                            l = (operator === "<?" && A) || B;
                        }
                    } else {
                        // A(t) and B(t) intersect to the right of t0.
                        const scratch = timeSpan.IntersectInterval(0, t + C);
                        timeSpan.copyFromArray(scratch);
                        scratch.Release();
                        if (z < c) {
                            // A(t) has a greater slope than B(t).
                            l = (operator === "<?" && A) || B;
                        } else {
                            // B(t) has a greater slope than A(t).
                            l = (operator === ">?" && A) || B;
                        }
                    }
                    m = t;
                    n = (l === A && c) || z;
                }
            }
            this.tracer.Log(
                "[%d]    arithmetic '%s' returns %s+(t-%s)*%s",
                element.nodeId,
                operator,
                l,
                m,
                n
            );
            this.SetValue(element, l, m, n);
        }
        this.profiler.StopProfiling("OvaleBestAction_ComputeArithmetic");
        return result;
    };
    private ComputeCompare: ComputerFunction<AstExpressionNode> = (
        element,
        atTime
    ) => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeCompare");
        const timeSpan = this.GetTimeSpan(element);
        const elementA = this.Compute(element.child[1], atTime);
        const [a, b, c, timeSpanA] = this.AsValue(atTime, elementA);
        const elementB = this.Compute(element.child[2], atTime);
        const [x, y, z, timeSpanB] = this.AsValue(atTime, elementB);
        timeSpanA.Intersect(timeSpanB, timeSpan);

        if (timeSpan.Measure() == 0) {
            this.tracer.Log(
                "[%d]    compare '%s' returns %s with zero measure",
                element.nodeId,
                element.operator,
                timeSpan
            );
        } else {
            const operator = element.operator;
            this.tracer.Log(
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
            const A = a - b * c;
            const B = x - y * z;
            if (c == z) {
                if (
                    !(
                        (operator == "==" && A == B) ||
                        (operator == "!=" && A != B) ||
                        (operator == "<" && A < B) ||
                        (operator == "<=" && A <= B) ||
                        (operator == ">" && A > B) ||
                        (operator == ">=" && A >= B)
                    )
                ) {
                    wipe(timeSpan);
                }
            } else {
                const diff = B - A;
                let t;
                if (diff == huge) {
                    t = huge;
                } else {
                    t = diff / (c - z);
                }
                t = (t > 0 && t) || 0;
                this.tracer.Log(
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
                    scratch = timeSpan.IntersectInterval(0, t);
                } else if (
                    (c < z && operator == "<") ||
                    (c < z && operator == "<=") ||
                    (c > z && operator == ">") ||
                    (c > z && operator == ">=")
                ) {
                    scratch = timeSpan.IntersectInterval(t, huge);
                }
                if (scratch) {
                    timeSpan.copyFromArray(scratch);
                    scratch.Release();
                } else {
                    wipe(timeSpan);
                }
            }
            this.tracer.Log(
                "[%d]    compare '%s' returns %s",
                element.nodeId,
                operator,
                timeSpan
            );
        }
        this.profiler.StopProfiling("OvaleBestAction_ComputeCompare");
        return element.result;
    };
    private ComputeCustomFunction: ComputerFunction<AstFunctionNode> = (
        element,
        atTime
    ): AstNodeSnapshot => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeCustomFunction");
        const timeSpan = this.GetTimeSpan(element);
        const result = element.result;
        const node =
            element.annotation.customFunction &&
            element.annotation.customFunction[element.name];
        if (node) {
            if (this.tracer.debug.trace)
                this.tracer.Log(
                    "[%d]: calling custom function [%d] %s",
                    element.nodeId,
                    node.child[1].nodeId,
                    element.name
                );
            const elementA = this.Compute(node.child[1], atTime);
            timeSpan.copyFromArray(elementA.timeSpan);
            if (this.tracer.debug.trace)
                this.tracer.Log(
                    "[%d]: [%d] %s is returning %s with timespan = %s",
                    element.nodeId,
                    node.child[1].nodeId,
                    element.name,
                    this.resultToString(elementA),
                    timeSpan
                );
            this.copyResult(result, elementA);
        } else {
            this.tracer.Error(`Unable to find ${element.name}`);
            wipe(timeSpan);
        }
        this.profiler.StopProfiling("OvaleBestAction_ComputeCustomFunction");
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

    private ComputeFunction: ComputerFunction<AstFunctionNode> = (
        element,
        atTime: number
    ) => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeFunction");
        const timeSpan = this.GetTimeSpan(element);
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
        ] = this.ovaleCondition.EvaluateCondition(
            element.name,
            positionalParams,
            namedParams,
            atTime
        );
        if (start !== undefined && ending !== undefined) {
            timeSpan.Copy(start, ending);
        } else {
            wipe(timeSpan);
        }
        if (value !== undefined) {
            this.SetValue(element, value, origin, rate);
        }
        this.tracer.Log(
            "[%d]    condition '%s' returns %s, %s, %s, %s, %s",
            element.nodeId,
            element.name,
            start,
            ending,
            value,
            origin,
            rate
        );
        this.profiler.StopProfiling("OvaleBestAction_ComputeFunction");
        return element.result;
    };

    private computeTypedFunction: ComputerFunction<AstTypedFunctionNode> = (
        element,
        atTime: number
    ) => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeFunction");
        const timeSpan = this.GetTimeSpan(element);
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
            timeSpan.Copy(start, ending);
        } else {
            wipe(timeSpan);
        }
        if (value !== undefined) {
            this.SetValue(element, value, origin, rate);
        }
        this.tracer.Log(
            "[%d]    condition '%s' returns %s, %s, %s, %s, %s",
            element.nodeId,
            element.name,
            start,
            ending,
            value,
            origin,
            rate
        );
        this.profiler.StopProfiling("OvaleBestAction_ComputeFunction");
        return element.result;
    };

    private ComputeGroup: ComputerFunction<AstGroupNode> = (group, atTime) => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeGroup");
        let bestTimeSpan, bestElement;
        const best = newTimeSpan();
        const currentTimeSpanAfterTime = newTimeSpan();
        for (const [, child] of ipairs(group.child)) {
            const nodeString = child.asString || child.type;
            this.tracer.Log(
                "[%d]    checking child '%s' [%d]",
                group.nodeId,
                nodeString,
                child.nodeId
            );
            const currentElement = this.Compute(child, atTime);
            const currentElementTimeSpan = currentElement.timeSpan;
            wipe(currentTimeSpanAfterTime);
            currentElementTimeSpan.IntersectInterval(
                atTime,
                huge,
                currentTimeSpanAfterTime
            );
            this.tracer.Log(
                "[%d]    child '%s' [%d]: %s",
                group.nodeId,
                nodeString,
                child.nodeId,
                currentTimeSpanAfterTime
            );
            if (currentTimeSpanAfterTime.Measure() > 0) {
                let currentIsBetter = false;
                if (best.Measure() == 0 || bestElement === undefined) {
                    this.tracer.Log(
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
                        this.tracer.Log(
                            "[%d]    group new best is '%s' [%d]: %s",
                            group.nodeId,
                            nodeString,
                            child.nodeId,
                            currentElementTimeSpan
                        );
                        currentIsBetter = true;
                    } else {
                        this.tracer.Log(
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
                this.tracer.Log(
                    "[%d]    child '%s' [%d] has zero measure, skipping",
                    group.nodeId,
                    nodeString,
                    child.nodeId
                );
            }
        }
        releaseTimeSpans(best, currentTimeSpanAfterTime);
        const timeSpan = this.GetTimeSpan(group, bestTimeSpan);
        if (bestElement) {
            this.copyResult(group.result, bestElement);
            this.tracer.Log(
                "[%d]    group best action remains %s at %s",
                group.nodeId,
                this.resultToString(group.result),
                timeSpan
            );
        } else {
            setResultType(group.result, "none");

            this.tracer.Log(
                "[%d]    group no best action returns %s at %s",
                group.nodeId,
                this.resultToString(group.result),
                timeSpan
            );
        }
        this.profiler.StopProfiling("OvaleBestAction_ComputeGroup");
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

    private ComputeIf: ComputerFunction<AstIfNode | AstUnlessNode> = (
        element,
        atTime
    ) => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeIf");
        const timeSpan = this.GetTimeSpan(element);
        const result = element.result;
        const timeSpanA = this.ComputeBool(element.child[1], atTime);
        let conditionTimeSpan = timeSpanA;
        if (element.type == "unless") {
            conditionTimeSpan = timeSpanA.Complement();
        }
        if (conditionTimeSpan.Measure() == 0) {
            timeSpan.copyFromArray(conditionTimeSpan);
            this.tracer.Log(
                "[%d]    '%s' returns %s with zero measure",
                element.nodeId,
                element.type,
                timeSpan
            );
        } else {
            const elementB = this.Compute(element.child[2], atTime);
            conditionTimeSpan.Intersect(elementB.timeSpan, timeSpan);
            this.tracer.Log(
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
            conditionTimeSpan.Release();
        }
        this.profiler.StopProfiling("OvaleBestAction_ComputeIf");
        return result;
    };

    private ComputeLogical: ComputerFunction<AstExpressionNode> = (
        element,
        atTime
    ) => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeLogical");
        const timeSpan = this.GetTimeSpan(element);
        const timeSpanA = this.ComputeBool(element.child[1], atTime);
        if (element.operator == "and") {
            if (timeSpanA.Measure() == 0) {
                timeSpan.copyFromArray(timeSpanA);
                this.tracer.Log(
                    "[%d]    logical '%s' short-circuits with zero measure left argument",
                    element.nodeId,
                    element.operator
                );
            } else {
                const timeSpanB = this.ComputeBool(element.child[2], atTime);
                timeSpanA.Intersect(timeSpanB, timeSpan);
            }
        } else if (element.operator == "not") {
            timeSpanA.Complement(timeSpan);
        } else if (element.operator == "or") {
            if (timeSpanA.IsUniverse()) {
                timeSpan.copyFromArray(timeSpanA);
                this.tracer.Log(
                    "[%d]    logical '%s' short-circuits with universe as left argument",
                    element.nodeId,
                    element.operator
                );
            } else {
                const timeSpanB = this.ComputeBool(element.child[2], atTime);
                timeSpanA.Union(timeSpanB, timeSpan);
            }
        } else if (element.operator == "xor") {
            const timeSpanB = this.ComputeBool(element.child[2], atTime);
            const left = timeSpanA.Union(timeSpanB);
            const scratch = timeSpanA.Intersect(timeSpanB);
            const right = scratch.Complement();
            left.Intersect(right, timeSpan);
            releaseTimeSpans(left, scratch, right);
        } else {
            wipe(timeSpan);
        }

        this.tracer.Log(
            "[%d]    logical '%s' returns %s",
            element.nodeId,
            element.operator,
            timeSpan
        );
        this.profiler.StopProfiling("OvaleBestAction_ComputeLogical");
        return element.result;
    };
    private ComputeLua: ComputerFunction<AstLuaNode> = (element) => {
        if (!element.lua) return element.result;
        this.profiler.StartProfiling("OvaleBestAction_ComputeLua");
        const value = loadstring(element.lua)();
        this.tracer.Log("[%d]    lua returns %s", element.nodeId, value);
        if (value !== undefined) {
            this.SetValue(element, value);
        }
        this.GetTimeSpan(element, UNIVERSE);
        this.profiler.StopProfiling("OvaleBestAction_ComputeLua");
        return element.result;
    };

    private ComputeValue: ComputerFunction<AstValueNode> = (element) => {
        this.profiler.StartProfiling("OvaleBestAction_ComputeValue");
        this.tracer.Log("[%d]    value is %s", element.nodeId, element.value);
        this.GetTimeSpan(element, UNIVERSE);
        this.SetValue(element, element.value, element.origin, element.rate);
        this.profiler.StopProfiling("OvaleBestAction_ComputeValue");
        return element.result;
    };

    private computeString: ComputerFunction<AstStringNode> = (element) => {
        this.tracer.Log("[%d]    value is %s", element.nodeId, element.value);
        this.GetTimeSpan(element, UNIVERSE);
        this.SetValue(element, element.value, undefined, undefined);
        return element.result;
    };

    private computeVariable: ComputerFunction<AstVariableNode> = (element) => {
        // TODO This should not happen but it's to support many old cases where an undefined variable name is used
        // as a string
        this.tracer.Log("[%d]    value is %s", element.nodeId, element.name);
        this.GetTimeSpan(element, UNIVERSE);
        this.SetValue(element, element.name, undefined, undefined);
        return element.result;
    };

    private SetValue(
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

    private AsValue(
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
            timeSpan = node.timeSpan || UNIVERSE;
        } else if (node.timeSpan.HasTime(atTime)) {
            [value, origin, rate, timeSpan] = [1, 0, 0, UNIVERSE];
        } else {
            [value, origin, rate, timeSpan] = [0, 0, 0, UNIVERSE];
        }
        return [value, origin, rate, timeSpan];
    }

    private GetTimeSpan(node: AstNode, defaultTimeSpan?: OvaleTimeSpan) {
        const timeSpan = node.result.timeSpan;
        if (defaultTimeSpan) {
            timeSpan.copyFromArray(defaultTimeSpan);
        } else {
            wipe(timeSpan);
        }
        return timeSpan;
    }

    public Compute(element: AstNode, atTime: number): AstNodeSnapshot {
        return this.PostOrderCompute(element, atTime);
    }

    public computeAsBoolean(element: AstNode, atTime: number) {
        const result = this.RecursiveCompute(element, atTime);
        return result.timeSpan.HasTime(atTime);
    }

    public computeAsNumber(element: AstNode, atTime: number) {
        const result = this.RecursiveCompute(element, atTime);
        if (result.type === "value" && isNumber(result.value)) {
            if (result.origin !== undefined && result.rate !== undefined)
                return result.value + result.rate * (atTime - result.origin);
            return result.value;
        }
        return 0;
    }

    public computeAsString(element: AstNode, atTime: number) {
        const result = this.RecursiveCompute(element, atTime);
        if (result.type === "value" && isString(result.value)) {
            return result.value;
        }
        return undefined;
    }

    public computeAsValue(element: AstNode, atTime: number) {
        const result = this.RecursiveCompute(element, atTime);
        if (result.type === "value") {
            if (!result.timeSpan.HasTime(atTime)) return undefined;
            return result.value;
        }
        return result.timeSpan.HasTime(atTime);
    }

    public computeParameters<T extends NodeType, P extends string>(
        node: AstNodeWithParameters<T, P>,
        atTime: number
    ): [PositionalParameters, NamedParameters<P>] {
        if (
            node.cachedParams.serial === undefined ||
            node.cachedParams.serial < this.self_serial
        ) {
            node.cachedParams.serial = this.self_serial;

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
            node.cachedParams.serial < this.self_serial
        ) {
            this.tracer.Log("computing positional parameters");
            node.cachedParams.serial = this.self_serial;
            for (const [k, v] of ipairs(node.rawPositionalParams)) {
                node.cachedParams.positional[k] = this.computeAsValue(
                    v,
                    atTime
                );
            }
        }

        return node.cachedParams.positional;
    }

    COMPUTE_VISITOR: {
        [k in AstNode["type"]]?: ComputerFunction<NodeTypes[k]>;
    } = {
        ["action"]: this.ComputeAction,
        ["arithmetic"]: this.ComputeArithmetic,
        ["boolean"]: this.computeBoolean,
        ["compare"]: this.ComputeCompare,
        ["custom_function"]: this.ComputeCustomFunction,
        ["function"]: this.ComputeFunction,
        ["group"]: this.ComputeGroup,
        ["if"]: this.ComputeIf,
        ["logical"]: this.ComputeLogical,
        ["lua"]: this.ComputeLua,
        ["state"]: this.ComputeFunction,
        ["string"]: this.computeString,
        ["typed_function"]: this.computeTypedFunction,
        ["unless"]: this.ComputeIf,
        ["value"]: this.ComputeValue,
        ["variable"]: this.computeVariable,
    };
}
