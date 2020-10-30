import { LuaArray } from "@wowts/lua";
import test, { ExecutionContext, TestInterface } from "ava";
import { IMock, Mock } from "typemoq";
import { AstAnnotation, AstNode, OvaleASTClass } from "../AST";
import { OvaleDataClass } from "../Data";
import { OvaleDebugClass, Tracer } from "../Debug";
import { Annotation, OperandParseNode } from "./definitions";
import { Emiter } from "./emiter";
import { Unparser } from "./unparser";

interface Context {
    debug: IMock<OvaleDebugClass>;
    ast: IMock<OvaleASTClass>;
    data: IMock<OvaleDataClass>;
    unparser: IMock<Unparser>;
    emiter: Emiter;
    annotation: IMock<Annotation>;
    astAnnotation: IMock<AstAnnotation>;
    tracer: IMock<Tracer>;
}

const t = test as TestInterface<Context>;

t.beforeEach((t) => {
    t.context.tracer = Mock.ofType<Tracer>();
    t.context.debug = Mock.ofType<OvaleDebugClass>();
    t.context.debug
        .setup((x) => x.create("SimulationCraftEmiter"))
        .returns(() => t.context.tracer.object);
    t.context.ast = Mock.ofType<OvaleASTClass>();
    t.context.data = Mock.ofType<OvaleDataClass>();
    t.context.unparser = Mock.ofType<Unparser>();
    t.context.annotation = Mock.ofType<Annotation>();
    t.context.astAnnotation = Mock.ofType<AstAnnotation>();
    t.context.annotation.setup((x) => x.classId).returns(() => "MAGE");
    t.context.annotation.setup((x) => x.specialization).returns(() => "arcane");
    t.context.annotation
        .setup((x) => x.astAnnotation)
        .returns(() => t.context.astAnnotation.object);
    t.context.emiter = new Emiter(
        t.context.debug.object,
        t.context.ast.object,
        t.context.data.object,
        t.context.unparser.object
    );
});

function testOperand(
    t: ExecutionContext<Context>,
    operand: string,
    expectedExpression: string
) {
    // Arrange
    const parseNode: OperandParseNode = {
        type: "operand",
        nodeId: 12,
        name: operand,
        asType: "value",
    };
    const nodeList: LuaArray<AstNode> = {};
    const expected: AstNode = {} as AstNode;
    t.context.ast
        .setup((x) =>
            x.ParseCode(
                "expression",
                expectedExpression,
                nodeList,
                t.context.annotation.object.astAnnotation
            )
        )
        .returns(() => [
            expected,
            nodeList,
            t.context.annotation.object.astAnnotation,
        ]);

    // Act
    const result = t.context.emiter.Emit(
        parseNode,
        nodeList,
        t.context.annotation.object,
        undefined
    );

    // Assert
    t.is(result, expected);
}

t("emiter target.debuff.casting.react", (t) => {
    testOperand(t, "target.debuff.casting.react", "target.IsInterruptible()");
});

t("emiter self.target", (t) => {
    testOperand(t, "self.target", "player.target()");
});

t("emiter target", (t) => {
    testOperand(t, "target", "target.targetguid()");
});

t("emiter unknown function (call one time message instead)", (t) => {
    // Arrange
    const parseNode: OperandParseNode = {
        type: "operand",
        nodeId: 12,
        name: "unknown.operand.condition",
        asType: "value",
    };
    const nodeList: LuaArray<AstNode> = {};
    const expected: AstNode = { rawPositionalParams: {} } as AstNode;
    t.context.ast
        .setup((x) => x.newFunction(nodeList, "message", true))
        .returns(() => expected);

    // Act
    const result = t.context.emiter.Emit(
        parseNode,
        nodeList,
        t.context.annotation.object,
        undefined
    );

    // Assert
    t.is(result, expected);
});
