import { LuaObj, LuaArray, lualength, ipairs, truthy, wipe } from "@wowts/lua";
import {
    AstAddFunctionNode,
    AstAnnotation,
    AstBaseNode,
    AstFunctionNode,
    AstGroupNode,
    AstIfNode,
    AstNode,
    AstUnlessNode,
    OperatorType,
    OvaleASTClass,
} from "../engine/ast";
import { Annotation, getTagPriority } from "./definitions";
import { DebugTools, Tracer } from "../engine/debug";
import { OvaleDataClass } from "../engine/data";
import { toOvaleTaggedFunctionName } from "./text-tools";
import { find, sub } from "@wowts/string";
import { insert } from "@wowts/table";

type SplitterFunction<T extends AstBaseNode<any>> = (
    tag: string,
    node: T,
    nodeList: LuaArray<AstNode>,
    annotation: Annotation
) => [AstNode?, AstNode?];

export class Splitter {
    private tracer: Tracer;

    constructor(
        private ovaleAst: OvaleASTClass,
        ovaleDebug: DebugTools,
        private ovaleData: OvaleDataClass
    ) {
        this.tracer = ovaleDebug.create("SimulationCraftSplitter");
    }

    private newLogicalNode(
        operator: OperatorType,
        lhsNode: AstNode,
        rhsNode: AstNode | undefined,
        annotation: AstAnnotation
    ) {
        const node = this.ovaleAst.newNodeWithChildren("logical", annotation);
        node.operator = operator;
        if (!rhsNode) {
            node.expressionType = "unary";
            node.child[1] = lhsNode;
        } else {
            node.expressionType = "binary";
            node.child[1] = lhsNode;
            node.child[2] = rhsNode;
        }
        return node;
    }

    private concatenatedConditionNode(
        conditionList: LuaArray<AstNode>,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation
    ) {
        let conditionNode;
        if (lualength(conditionList) > 0) {
            if (lualength(conditionList) == 1) {
                conditionNode = conditionList[1];
            } else if (lualength(conditionList) > 1) {
                let lhsNode = conditionList[1];
                let rhsNode = conditionList[2];
                conditionNode = this.newLogicalNode(
                    "or",
                    lhsNode,
                    rhsNode,
                    annotation.astAnnotation
                );
                for (let k = 3; k <= lualength(conditionList); k += 1) {
                    lhsNode = conditionNode;
                    rhsNode = conditionList[k];
                    conditionNode = this.newLogicalNode(
                        "or",
                        lhsNode,
                        rhsNode,
                        annotation.astAnnotation
                    );
                }
            }
        }
        return conditionNode;
    }

    private concatenatedBodyNode(
        bodyList: LuaArray<AstNode>,
        nodeList: LuaArray<AstNode>,
        annotation: Annotation
    ) {
        let bodyNode;
        if (lualength(bodyList) > 0) {
            bodyNode = this.ovaleAst.newNodeWithChildren(
                "group",
                annotation.astAnnotation
            );
            for (const [k, node] of ipairs(bodyList)) {
                bodyNode.child[k] = node;
            }
        }
        return bodyNode;
    }

    public splitByTag: SplitterFunction<AstNode> = (
        tag,
        node,
        nodeList,
        annotation
    ) => {
        const visitor = this.splitByTagVisitors[node.type];
        if (!visitor) {
            this.tracer.error(
                "Unable to split-by-tag node of type '%s'.",
                node.type
            );
            return [];
        } else {
            return visitor(tag, node, nodeList, annotation);
        }
    };

    private splitByTagAction: SplitterFunction<AstFunctionNode> = (
        tag,
        node,
        nodeList,
        annotation
    ) => {
        let bodyNode, conditionNode;
        let actionTag, invokesGCD;
        const name = "UNKNOWN";
        const actionType = node.name;
        if (actionType == "item" || actionType == "spell") {
            const firstParamNode = node.rawPositionalParams[1];
            let id, name;
            if (firstParamNode.type == "variable") {
                name = firstParamNode.name;
                id = annotation.dictionary && annotation.dictionary[name];
            } else if (firstParamNode.type === "value") {
                name = firstParamNode.value;
                id = <number>firstParamNode.value;
            }
            if (id) {
                if (actionType == "item") {
                    [actionTag, invokesGCD] = this.ovaleData.getItemTagInfo(id);
                } else if (actionType == "spell") {
                    [actionTag, invokesGCD] =
                        this.ovaleData.getSpellTagInfo(id);
                }
            } else {
                this.tracer.print(
                    "Warning: Unable to find %s '%s'",
                    actionType,
                    name
                );
            }
        } else if (actionType == "texture") {
            const firstParamNode = node.rawPositionalParams[1];
            let id, name;
            if (firstParamNode.type == "variable") {
                name = firstParamNode.name;
                id = annotation.dictionary && annotation.dictionary[name];
            } else if (firstParamNode.type === "value") {
                name = firstParamNode.value;
                id = <number>name;
            }
            if (id) {
                [actionTag, invokesGCD] = this.ovaleData.getSpellTagInfo(id);
                if (actionTag == undefined) {
                    [actionTag, invokesGCD] = this.ovaleData.getItemTagInfo(id);
                }
            }
            if (actionTag == undefined) {
                actionTag = "main";
                invokesGCD = true;
            }
        } else {
            this.tracer.print("Warning: Unknown action type '%'", actionType);
        }
        if (!actionTag) {
            actionTag = "main";
            invokesGCD = true;
            this.tracer.print(
                "Warning: Unable to determine tag for '%s', assuming '%s' (actionType: %s).",
                name,
                actionTag,
                actionType
            );
        }
        if (actionTag == tag) {
            bodyNode = node;
        } else if (
            invokesGCD &&
            getTagPriority(actionTag) < getTagPriority(tag)
        ) {
            conditionNode = node;
        }
        return [bodyNode, conditionNode];
    };

    private splitByTagAddFunction: SplitterFunction<AstAddFunctionNode> = (
        tag,
        node,
        nodeList,
        annotation
    ) => {
        const [bodyName, conditionName] = toOvaleTaggedFunctionName(
            node.name,
            tag
        );
        if (!bodyName || !conditionName) return [];
        let [bodyNode, conditionNode] = this.splitByTag(
            tag,
            node.child[1],
            nodeList,
            annotation
        );
        if (!bodyNode || bodyNode.type != "group") {
            const newGroupNode = this.ovaleAst.newNodeWithChildren(
                "group",
                annotation.astAnnotation
            );
            if (bodyNode) newGroupNode.child[1] = bodyNode;
            bodyNode = newGroupNode;
        }
        if (!conditionNode || conditionNode.type != "group") {
            const newGroupNode = this.ovaleAst.newNodeWithChildren(
                "group",
                annotation.astAnnotation
            );
            if (conditionNode) newGroupNode.child[1] = conditionNode;
            conditionNode = newGroupNode;
        }
        const bodyFunctionNode = this.ovaleAst.newNodeWithBodyAndParameters(
            "add_function",
            annotation.astAnnotation,
            bodyNode
        );
        bodyFunctionNode.name = bodyName;
        const conditionFunctionNode =
            this.ovaleAst.newNodeWithBodyAndParameters(
                "add_function",
                annotation.astAnnotation,
                conditionNode
            );
        conditionFunctionNode.name = conditionName;
        return [bodyFunctionNode, conditionFunctionNode];
    };

    private splitByTagCustomFunction: SplitterFunction<AstFunctionNode> = (
        tag,
        node,
        nodeList,
        annotation
    ) => {
        let bodyNode, conditionNode;
        const functionName = node.name;
        if (annotation.taggedFunctionName[functionName]) {
            const [bodyName, conditionName] = toOvaleTaggedFunctionName(
                functionName,
                tag
            );
            if (bodyName && conditionName) {
                bodyNode = this.ovaleAst.newNodeWithParameters(
                    "custom_function",
                    annotation.astAnnotation
                );
                bodyNode.name = bodyName;
                bodyNode.asString = `${bodyName}()`;
                conditionNode = this.ovaleAst.newNodeWithParameters(
                    "custom_function",
                    annotation.astAnnotation
                );
                conditionNode.name = conditionName;
                conditionNode.asString = `${conditionName}()`;
            }
        } else {
            let functionTag = annotation.functionTag[functionName];
            if (!functionTag) {
                if (truthy(find(functionName, "bloodlust"))) {
                    functionTag = "cd";
                } else if (truthy(find(functionName, "getinmeleerange"))) {
                    functionTag = "shortcd";
                } else if (truthy(find(functionName, "interruptactions"))) {
                    functionTag = "cd";
                } else if (truthy(find(functionName, "summonpet"))) {
                    functionTag = "shortcd";
                } else if (truthy(find(functionName, "useitemactions"))) {
                    functionTag = "cd";
                } else if (truthy(find(functionName, "usepotion"))) {
                    functionTag = "cd";
                } else if (truthy(find(functionName, "useheartessence"))) {
                    functionTag = "cd";
                }
            }
            if (functionTag) {
                if (functionTag == tag) {
                    bodyNode = node;
                }
            } else {
                this.tracer.print(
                    "Warning: Unable to determine tag for '%s()'.",
                    node.name
                );
                bodyNode = node;
            }
        }
        return [bodyNode, conditionNode];
    };

    private splitByTagGroup: SplitterFunction<AstGroupNode> = (
        tag,
        node,
        nodeList,
        annotation
    ) => {
        let index = lualength(node.child);
        const bodyList: LuaArray<AstNode> = {};
        const conditionList: LuaArray<AstNode> = {};
        const remainderList: LuaArray<AstNode> = {};
        while (index > 0) {
            let childNode = node.child[index];
            index = index - 1;
            if (childNode.type != "comment") {
                let [bodyNode, conditionNode] = this.splitByTag(
                    tag,
                    childNode,
                    nodeList,
                    annotation
                );
                if (conditionNode) {
                    insert(conditionList, 1, conditionNode);
                    insert(remainderList, 1, conditionNode);
                }
                if (bodyNode) {
                    if (lualength(conditionList) == 0) {
                        insert(bodyList, 1, bodyNode);
                    } else if (lualength(bodyList) == 0) {
                        wipe(conditionList);
                        insert(bodyList, 1, bodyNode);
                    } else {
                        const unlessNode = this.ovaleAst.newNodeWithChildren(
                            "unless",
                            annotation.astAnnotation
                        );
                        const condition = this.concatenatedConditionNode(
                            conditionList,
                            nodeList,
                            annotation
                        );
                        const body = this.concatenatedBodyNode(
                            bodyList,
                            nodeList,
                            annotation
                        );
                        if (condition && body) {
                            unlessNode.child[1] = condition;
                            unlessNode.child[2] = body;
                        }
                        wipe(bodyList);
                        wipe(conditionList);
                        insert(bodyList, 1, unlessNode);
                        const commentNode = this.ovaleAst.newNode(
                            "comment",
                            annotation.astAnnotation
                        );
                        insert(bodyList, 1, commentNode);
                        insert(bodyList, 1, bodyNode);
                    }
                    if (index > 0) {
                        childNode = node.child[index];
                        if (childNode.type != "comment") {
                            [bodyNode, conditionNode] = this.splitByTag(
                                tag,
                                childNode,
                                nodeList,
                                annotation
                            );
                            if (!bodyNode && index > 1) {
                                let start = index - 1;
                                for (let k = index - 1; k >= 1; k += -1) {
                                    childNode = node.child[k];
                                    if (childNode.type == "comment") {
                                        if (
                                            childNode.comment &&
                                            sub(childNode.comment, 1, 5) ==
                                                "pool_"
                                        ) {
                                            start = k;
                                            break;
                                        }
                                    } else {
                                        break;
                                    }
                                }
                                if (start < index - 1) {
                                    for (
                                        let k = index - 1;
                                        k >= start;
                                        k += -1
                                    ) {
                                        insert(bodyList, 1, node.child[k]);
                                    }
                                    index = start - 1;
                                }
                            }
                        }
                    }
                    while (index > 0) {
                        childNode = node.child[index];
                        if (childNode.type == "comment") {
                            insert(bodyList, 1, childNode);
                            index = index - 1;
                        } else {
                            break;
                        }
                    }
                }
            }
        }
        let bodyNode = this.concatenatedBodyNode(
            bodyList,
            nodeList,
            annotation
        );
        let conditionNode = this.concatenatedConditionNode(
            conditionList,
            nodeList,
            annotation
        );
        const remainderNode = this.concatenatedConditionNode(
            remainderList,
            nodeList,
            annotation
        );
        if (bodyNode) {
            if (conditionNode) {
                const unlessNode = this.ovaleAst.newNodeWithChildren(
                    "unless",
                    annotation.astAnnotation
                );
                unlessNode.child[1] = conditionNode;
                unlessNode.child[2] = bodyNode;
                const groupNode = this.ovaleAst.newNodeWithChildren(
                    "group",
                    annotation.astAnnotation
                );
                groupNode.child[1] = unlessNode;
                bodyNode = groupNode;
            }
            conditionNode = remainderNode;
        }
        return [bodyNode, conditionNode];
    };

    private splitByTagIf: SplitterFunction<AstIfNode | AstUnlessNode> = (
        tag,
        node,
        nodeList,
        annotation
    ) => {
        let [bodyNode, conditionNode] = this.splitByTag(
            tag,
            node.child[2],
            nodeList,
            annotation
        );
        if (conditionNode) {
            let lhsNode = node.child[1];
            const rhsNode = conditionNode;
            if (node.type == "unless") {
                lhsNode = this.newLogicalNode(
                    "not",
                    lhsNode,
                    undefined,
                    annotation.astAnnotation
                );
            }
            const andNode = this.newLogicalNode(
                "and",
                lhsNode,
                rhsNode,
                annotation.astAnnotation
            );
            conditionNode = andNode;
        }
        if (bodyNode) {
            const ifNode = this.ovaleAst.newNodeWithChildren(
                node.type,
                annotation.astAnnotation
            );
            ifNode.type = node.type;
            ifNode.child[1] = node.child[1];
            ifNode.child[2] = bodyNode;
            bodyNode = ifNode;
        }
        return [bodyNode, conditionNode];
    };

    private splitByTagState: SplitterFunction<AstFunctionNode> = (
        tag,
        node,
        nodeList,
        annotation
    ) => {
        return [node, undefined];
    };

    private splitByTagVisitors: LuaObj<SplitterFunction<any>> = {
        ["action"]: this.splitByTagAction,
        ["add_function"]: this.splitByTagAddFunction,
        ["custom_function"]: this.splitByTagCustomFunction,
        ["group"]: this.splitByTagGroup,
        ["if"]: this.splitByTagIf,
        ["state"]: this.splitByTagState,
        ["unless"]: this.splitByTagIf,
    };
}
