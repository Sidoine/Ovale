import { test, expect } from "@jest/globals";
import { It, Mock } from "typemoq";
import { BaseState } from "../states/BaseState";
import { assertIs } from "../tests/helpers";
import { newTimeSpan } from "../tools/TimeSpan";
import { AstAnnotation, AstTypedFunctionNode } from "./ast";
import { OvaleConditionClass } from "./condition";
import { DebugTools, Tracer } from "./debug";
import { Runner } from "./runner";

function makeRunner() {
    const debugMock = Mock.ofType<DebugTools>();
    const trackerMock = Mock.ofType<Tracer>();
    debugMock
        .setup((x) => x.create(It.isAny()))
        .returns(() => trackerMock.object);
    const baseStateMock = Mock.ofType<BaseState>();
    const conditionMock = Mock.ofType<OvaleConditionClass>();
    const astAnnotationMock = Mock.ofType<AstAnnotation>();
    const runner = new Runner(
        debugMock.object,
        baseStateMock.object,
        conditionMock.object
    );
    runner.refresh();
    return {
        runner,
        debugMock,
        baseStateMock,
        conditionMock,
        astAnnotationMock,
    };
}

test("compute a typed_function", () => {
    // Arrange
    const { runner, astAnnotationMock, conditionMock } = makeRunner();

    conditionMock
        .setup((x) => x.call("test", 0, { 1: "original" }))
        .returns(() => [0, 10, "mapped"]);
    const typedFunction: AstTypedFunctionNode = {
        type: "typed_function",
        annotation: astAnnotationMock.object,
        cachedParams: { named: {}, positional: {} },
        child: {},
        name: "test",
        nodeId: 1,
        rawNamedParams: {},
        rawPositionalParams: {
            1: {
                annotation: astAnnotationMock.object,
                type: "string",
                nodeId: 2,
                result: { serial: 0, timeSpan: newTimeSpan(), type: "none" },
                value: "original",
            },
        },
        result: { serial: 0, timeSpan: newTimeSpan(), type: "none" },
    };

    // Act
    const result = runner.compute(typedFunction, 0);

    // Assert
    assertIs(result.type, "value");
    expect(result.value).toBe("mapped");
});
