import { LuaArray } from "@wowts/lua";
import { test, beforeEach, expect } from "@jest/globals";
import { IMock, Mock } from "typemoq";
import {
    AstAnnotation,
    AstFunctionNode,
    AstNode,
    AstNodeSnapshot,
    OvaleASTClass,
} from "../engine/ast";
import { OvaleDataClass } from "../engine/data";
import { DebugTools, Tracer } from "../engine/debug";
import { Annotation, OperandParseNode } from "./definitions";
import { Emiter } from "./emiter";
import { Unparser } from "./unparser";

interface Context {
    debug: IMock<DebugTools>;
    ast: IMock<OvaleASTClass>;
    data: IMock<OvaleDataClass>;
    unparser: IMock<Unparser>;
    emiter: Emiter;
    annotation: IMock<Annotation>;
    astAnnotation: IMock<AstAnnotation>;
    tracer: IMock<Tracer>;
    nodeList: LuaArray<AstNode>;
}

const context: Context = {} as Context;

beforeEach(() => {
    context.tracer = Mock.ofType<Tracer>();
    context.debug = Mock.ofType<DebugTools>();
    context.debug
        .setup((x) => x.create("SimulationCraftEmiter"))
        .returns(() => context.tracer.object);
    context.ast = Mock.ofType<OvaleASTClass>();
    context.data = Mock.ofType<OvaleDataClass>();
    context.unparser = Mock.ofType<Unparser>();
    context.annotation = Mock.ofType<Annotation>();
    context.astAnnotation = Mock.ofType<AstAnnotation>();
    context.nodeList = {};
    context.astAnnotation
        .setup((x) => x.nodeList)
        .returns(() => context.nodeList);

    context.annotation.setup((x) => x.classId).returns(() => "MAGE");
    context.annotation.setup((x) => x.specialization).returns(() => "arcane");
    context.annotation
        .setup((x) => x.astAnnotation)
        .returns(() => context.astAnnotation.object);
    context.emiter = new Emiter(
        context.debug.object,
        context.ast.object,
        context.data.object,
        context.unparser.object
    );
});

function testOperand(operand: string, expectedExpression: string) {
    // Arrange
    const parseNode: OperandParseNode = {
        type: "operand",
        nodeId: 12,
        name: operand,
        asType: "value",
    };
    const nodeList: LuaArray<AstNode> = {};
    const expected: AstNode = {} as AstNode;
    context.ast
        .setup((x) =>
            x.parseCode(
                "expression",
                expectedExpression,
                nodeList,
                context.annotation.object.astAnnotation
            )
        )
        .returns(() => [
            expected,
            nodeList,
            context.annotation.object.astAnnotation,
        ]);

    // Act
    const result = context.emiter.emit(
        parseNode,
        nodeList,
        context.annotation.object,
        undefined
    );

    // Assert
    expect(result).toBe(expected);
}

test("emiter target.debuff.casting.react", () => {
    testOperand("target.debuff.casting.react", "target.IsInterruptible()");
});

test("emiter self.target", () => {
    testOperand("self.target", "player.targetguid()");
});

test("emiter target", () => {
    testOperand("target", "target.guid()");
});

test("emiter unknown function (call one time message instead)", () => {
    // Arrange
    const parseNode: OperandParseNode = {
        type: "operand",
        nodeId: 12,
        name: "unknown.operand.condition",
        asType: "value",
    };
    const expected: AstFunctionNode = {
        annotation: context.astAnnotation.object,
        cachedParams: { named: {}, positional: {} },
        child: {},
        name: "",
        nodeId: 0,
        rawNamedParams: {},
        rawPositionalParams: {},
        result: {} as AstNodeSnapshot,
        type: "function",
    };
    context.ast
        .setup((x) => x.newFunction("message", context.astAnnotation.object))
        .returns(() => expected);

    // Act
    const result = context.emiter.emit(
        parseNode,
        context.nodeList,
        context.annotation.object,
        undefined
    );

    // Assert
    expect(result).toBe(expected);
});
