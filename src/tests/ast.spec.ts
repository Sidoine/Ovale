import test from "ava";
import { IoC } from "../ioc";

test("parse Define", t => {
    // Arrange
    const ioc = new IoC();
    const ast = ioc.ast;

    // Act
    const [astNode, nodeList, annotation ] = ast.ParseCode("script", `Define(test 18)`, {}, {});

    // Assert
    t.truthy(astNode);
    t.truthy(nodeList);
    t.truthy(annotation.definition);
    t.is(annotation.definition["test"], 18);
});
