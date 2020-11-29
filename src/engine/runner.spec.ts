import { test, expect } from "@jest/globals";
import { It, Mock } from "typemoq";
import { BaseState } from "../states/BaseState";
import { assertIs } from "../tests/helpers";
import { newTimeSpan } from "../tools/TimeSpan";
import { AstAnnotation, AstTypedFunctionNode } from "./ast";
import { OvaleConditionClass } from "./condition";
import { OvaleDebugClass, Tracer } from "./debug";
import { OvaleProfilerClass, Profiler } from "./profiler";
import { Runner } from "./runner";

function makeRunner() {
    const profilerFactoryMock = Mock.ofType<OvaleProfilerClass>();
    const profilerMock = Mock.ofType<Profiler>();
    profilerFactoryMock
        .setup((x) => x.create(It.isAny()))
        .returns(() => profilerMock.object);
    const debugMock = Mock.ofType<OvaleDebugClass>();
    const trackerMock = Mock.ofType<Tracer>();
    debugMock
        .setup((x) => x.create(It.isAny()))
        .returns(() => trackerMock.object);
    const baseStateMock = Mock.ofType<BaseState>();
    const conditionMock = Mock.ofType<OvaleConditionClass>();
    const astAnnotationMock = Mock.ofType<AstAnnotation>();
    const runner = new Runner(
        profilerFactoryMock.object,
        debugMock.object,
        baseStateMock.object,
        conditionMock.object
    );
    runner.refresh();
    return {
        runner,
        profilerFactoryMock,
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
    const result = runner.Compute(typedFunction, 0);

    // Assert
    assertIs(result.type, "value");
    expect(result.value).toBe("mapped");
});
