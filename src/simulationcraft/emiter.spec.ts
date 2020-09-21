import { LuaArray } from "@wowts/lua";
import test, { TestInterface } from "ava";
import { IMock, Mock } from "typemoq";
import { AstAnnotation, AstNode, OvaleASTClass } from "../AST";
import { OvaleDataClass } from "../Data";
import { OvaleDebugClass } from "../Debug";
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
}

const t = test as TestInterface<Context>;

t.beforeEach((t) => {
    t.context.debug = Mock.ofType<OvaleDebugClass>();
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

t("emiter target.debuff.casting.react", (t) => {
    // Arrange
    const parseNode: OperandParseNode = {
        type: "operand",
        nodeId: 12,
        name: "target.debuff.casting.react",
        asType: "value",
    };
    const nodeList: LuaArray<AstNode> = {};
    const expected: AstNode = {} as AstNode;
    t.context.ast
        .setup((x) =>
            x.ParseCode(
                "expression",
                "target.IsInterruptible()",
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
    const expected: AstNode = {} as AstNode;
    t.context.ast
        .setup((x) =>
            x.ParseCode(
                "expression",
                "target.IsInterruptible()",
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
});
