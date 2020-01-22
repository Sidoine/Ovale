import { LuaObj, LuaArray, lualength, ipairs, truthy, wipe } from "@wowts/lua";
import { AstNode, OperatorType, OvaleASTClass, isNodeType } from "../AST";
import { Annotation, TagPriority } from "./definitions";
import { OvaleDebugClass, Tracer } from "../Debug";
import { OvaleDataClass } from "../Data";
import { OvaleTaggedFunctionName } from "./text-tools";
import { find, sub } from "@wowts/string";
import { insert } from "@wowts/table";

type SplitterFunction = (tag: string, node: AstNode, nodeList: LuaArray<AstNode>, annotation: Annotation) => [AstNode?, AstNode?]
    
export class Splitter {
    private tracer: Tracer;

    constructor(private ovaleAst: OvaleASTClass, ovaleDebug: OvaleDebugClass, private ovaleData: OvaleDataClass) {
        this.tracer = ovaleDebug.create("SimulationCraftSplitter");
    }

    private NewLogicalNode(operator: OperatorType, lhsNode: AstNode, rhsNode: AstNode | undefined, nodeList: LuaArray<AstNode>) {
        let node = this.ovaleAst.NewNode(nodeList, true);
        node.type = "logical";
        node.operator = operator;
        if (operator == "not") {
            node.expressionType = "unary";
            node.child[1] = lhsNode;
        } else {
            node.expressionType = "binary";
            node.child[1] = lhsNode;
            node.child[2] = rhsNode!;
        }
        return node;
    }

    private ConcatenatedConditionNode(conditionList: LuaArray<AstNode>, nodeList: LuaArray<AstNode>, annotation: Annotation) {
        let conditionNode;
        if (lualength(conditionList) > 0) {
            if (lualength(conditionList) == 1) {
                conditionNode = conditionList[1];
            } else if (lualength(conditionList) > 1) {
                let lhsNode = conditionList[1];
                let rhsNode = conditionList[2];
                conditionNode = this.NewLogicalNode("or", lhsNode, rhsNode, nodeList);
                for (let k = 3; k <= lualength(conditionList); k += 1) {
                    lhsNode = conditionNode;
                    rhsNode = conditionList[k];
                    conditionNode = this.NewLogicalNode("or", lhsNode, rhsNode, nodeList);
                }
            }
        }
        return conditionNode;
    }

    private ConcatenatedBodyNode(bodyList: LuaArray<AstNode>, nodeList: LuaArray<AstNode>, annotation: Annotation) {
        let bodyNode;
        if (lualength(bodyList) > 0) {
            bodyNode = this.ovaleAst.NewNode(nodeList, true);
            bodyNode.type = "group";
            for (const [k, node] of ipairs(bodyList)) {
                bodyNode.child[k] = node;
            }
        }
        return bodyNode;
    }

    public SplitByTag: SplitterFunction = (tag, node, nodeList, annotation) => {
        let visitor = this.SPLIT_BY_TAG_VISITOR[node.type];
        if (!visitor) {
            this.tracer.Error("Unable to split-by-tag node of type '%s'.", node.type);
            return [];
        } else {
            return visitor(tag, node, nodeList, annotation);
        }
    }
    
    private SplitByTagAction: SplitterFunction = (tag, node, nodeList, annotation) => {
        let bodyNode, conditionNode;
        let actionTag, invokesGCD;
        let name = "UNKNOWN";
        let actionType = node.func;
        if (actionType == "item" || actionType == "spell") {
            let firstParamNode = node.rawPositionalParams[1];
            let id, name;
            if (firstParamNode.type == "variable") {
                name = firstParamNode.name;
                id = annotation.dictionary && annotation.dictionary[name];
            } else if (isNodeType(firstParamNode, "value")) {
                name = firstParamNode.value;
                id = <number>firstParamNode.value;
            }
            if (id) {
                if (actionType == "item") {
                    [actionTag, invokesGCD] = this.ovaleData.GetItemTagInfo(id);
                } else if (actionType == "spell") {
                    [actionTag, invokesGCD] = this.ovaleData.GetSpellTagInfo(id);
                }
            } else {
                this.tracer.Print("Warning: Unable to find %s '%s'", actionType, name);
            }
        } else if (actionType == "texture") {
            let firstParamNode = node.rawPositionalParams[1];
            let id, name;
            if (firstParamNode.type == "variable") {
                name = firstParamNode.name;
                id = annotation.dictionary && annotation.dictionary[name];
            } else if (isNodeType(firstParamNode, "value")) {
                name = firstParamNode.value;
                id = <number>name;
            }
            if (id) {
                [actionTag, invokesGCD] = this.ovaleData.GetSpellTagInfo(id);
                if (actionTag == undefined) {
                    [actionTag, invokesGCD] = this.ovaleData.GetItemTagInfo(id);
                }
            }
            if (actionTag == undefined) {
                actionTag = "main";
                invokesGCD = true;
            }
        } else {
            this.tracer.Print("Warning: Unknown action type '%'", actionType);
        }
        if (!actionTag) {
            actionTag = "main";
            invokesGCD = true;
            this.tracer.Print("Warning: Unable to determine tag for '%s', assuming '%s' (actionType: %s).", name, actionTag, actionType);
        }
        if (actionTag == tag) {
            bodyNode = node;
        } else if (invokesGCD && TagPriority(actionTag) < TagPriority(tag)) {
            conditionNode = node;
        }
        return [bodyNode, conditionNode];
    }
    
    private SplitByTagAddFunction: SplitterFunction = (tag, node, nodeList, annotation) => {
        let [bodyName, conditionName] = OvaleTaggedFunctionName(node.name, tag);
        if (!bodyName || !conditionName) return [];
        let [bodyNode, conditionNode] = this.SplitByTag(tag, node.child[1], nodeList, annotation);
        if (!bodyNode || bodyNode.type != "group") {
            let newGroupNode = this.ovaleAst.NewNode(nodeList, true);
            newGroupNode.type = "group";
            if (bodyNode) newGroupNode.child[1] = bodyNode;
            bodyNode = newGroupNode;
        }
        if (!conditionNode || conditionNode.type != "group") {
            let newGroupNode = this.ovaleAst.NewNode(nodeList, true);
            newGroupNode.type = "group";
            if (conditionNode) newGroupNode.child[1] = conditionNode;
            conditionNode = newGroupNode;
        }
        let bodyFunctionNode = this.ovaleAst.NewNode(nodeList, true);
        bodyFunctionNode.type = "add_function";
        bodyFunctionNode.name = bodyName;
        bodyFunctionNode.child[1] = bodyNode;
        let conditionFunctionNode = this.ovaleAst.NewNode(nodeList, true);
        conditionFunctionNode.type = "add_function";
        conditionFunctionNode.name = conditionName;
        conditionFunctionNode.child[1] = conditionNode;
        return [bodyFunctionNode, conditionFunctionNode];
    }
   
   private SplitByTagCustomFunction: SplitterFunction = (tag, node, nodeList, annotation) => {
        let bodyNode, conditionNode;
        let functionName = node.name;
        if (annotation.taggedFunctionName[functionName]) {
            let [bodyName, conditionName] = OvaleTaggedFunctionName(functionName, tag);
            if (bodyName && conditionName) {
                bodyNode = this.ovaleAst.NewNode(nodeList);
                bodyNode.name = bodyName;
                bodyNode.type = "custom_function";
                bodyNode.func = bodyName;
                bodyNode.asString = `${bodyName}()`;
                conditionNode = this.ovaleAst.NewNode(nodeList);
                conditionNode.name = conditionName;
                conditionNode.type = "custom_function";
                conditionNode.func = conditionName;
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
                this.tracer.Print("Warning: Unable to determine tag for '%s()'.", node.name);
                bodyNode = node;
            }
        }
        return [bodyNode, conditionNode];
    }
    
    private SplitByTagGroup: SplitterFunction = (tag, node, nodeList, annotation) => {
        let index = lualength(node.child);
        let bodyList: LuaArray<AstNode> = {};
        let conditionList: LuaArray<AstNode> = {};
        let remainderList: LuaArray<AstNode> = {};
        while (index > 0) {
            let childNode = node.child[index];
            index = index - 1;
            if (childNode.type != "comment") {
                let [bodyNode, conditionNode] = this.SplitByTag(tag, childNode, nodeList, annotation);
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
                        let unlessNode = this.ovaleAst.NewNode(nodeList, true);
                        unlessNode.type = "unless";
                        const condition = this.ConcatenatedConditionNode(conditionList, nodeList, annotation);
                        const body = this.ConcatenatedBodyNode(bodyList, nodeList, annotation);
                        if (condition && body) {
                            unlessNode.child[1] = condition;
                            unlessNode.child[2] = body;
                        }
                        wipe(bodyList);
                        wipe(conditionList);
                        insert(bodyList, 1, unlessNode);
                        let commentNode = this.ovaleAst.NewNode(nodeList);
                        commentNode.type = "comment";
                        insert(bodyList, 1, commentNode);
                        insert(bodyList, 1, bodyNode);
                    }
                    if (index > 0) {
                        childNode = node.child[index];
                        if (childNode.type != "comment") {
                            [bodyNode, conditionNode] = this.SplitByTag(tag, childNode, nodeList, annotation);
                            if (!bodyNode && index > 1) {
                                let start = index - 1;
                                for (let k = index - 1; k >= 1; k += -1) {
                                    childNode = node.child[k];
                                    if (childNode.type == "comment") {
                                        if (childNode.comment && sub(childNode.comment, 1, 5) == "pool_") {
                                            start = k;
                                            break;
                                        }
                                    } else {
                                        break;
                                    }
                                }
                                if (start < index - 1) {
                                    for (let k = index - 1; k >= start; k += -1) {
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
        let bodyNode = this.ConcatenatedBodyNode(bodyList, nodeList, annotation);
        let conditionNode = this.ConcatenatedConditionNode(conditionList, nodeList, annotation);
        let remainderNode = this.ConcatenatedConditionNode(remainderList, nodeList, annotation);
        if (bodyNode) {
            if (conditionNode) {
                let unlessNode = this.ovaleAst.NewNode(nodeList, true);
                unlessNode.type = "unless";
                unlessNode.child[1] = conditionNode;
                unlessNode.child[2] = bodyNode;
                let groupNode = this.ovaleAst.NewNode(nodeList, true);
                groupNode.type = "group";
                groupNode.child[1] = unlessNode;
                bodyNode = groupNode;
            }
            conditionNode = remainderNode;
        }
        return [bodyNode, conditionNode];
    }
    
    private SplitByTagIf: SplitterFunction = (tag, node, nodeList, annotation) => {
        let [bodyNode, conditionNode] = this.SplitByTag(tag, node.child[2], nodeList, annotation);
        if (conditionNode) {
            let lhsNode = node.child[1];
            let rhsNode = conditionNode;
            if (node.type == "unless") {
                lhsNode = this.NewLogicalNode("not", lhsNode, undefined, nodeList);
            }
            let andNode = this.NewLogicalNode("and", lhsNode, rhsNode, nodeList);
            conditionNode = andNode;
        }
        if (bodyNode) {
            let ifNode = this.ovaleAst.NewNode(nodeList, true);
            ifNode.type = node.type;
            ifNode.child[1] = node.child[1];
            ifNode.child[2] = bodyNode;
            bodyNode = ifNode;
        }
        return [bodyNode, conditionNode];
    }
    
    private SplitByTagState: SplitterFunction = (tag, node, nodeList, annotation) => {
        return [node, undefined];
    }
    
    private SPLIT_BY_TAG_VISITOR: LuaObj<SplitterFunction> = {
        ["action"]: this.SplitByTagAction,
        ["add_function"]: this.SplitByTagAddFunction,
        ["custom_function"]: this.SplitByTagCustomFunction,
        ["group"]: this.SplitByTagGroup,
        ["if"]: this.SplitByTagIf,
        ["state"]: this.SplitByTagState,
        ["unless"]: this.SplitByTagIf
    }
}