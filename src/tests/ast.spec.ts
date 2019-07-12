import test from "ava";
import { OvaleASTClass } from "../AST";

test("parse Define", t => {
    // Arrange
    const ast = new OvaleASTClass();

    // Act
    const [astNode, nodeList, annotation ] = ast.ParseCode("script", `Define(test 18)`, {}, {});

    // Assert
    t.truthy(astNode);
    t.truthy(nodeList);
    t.truthy(annotation.definition);
    t.is(annotation.definition["test"], 18);
});
