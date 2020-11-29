import { test, expect } from "@jest/globals";
import { Mock } from "typemoq";
import { BaseState } from "../states/BaseState";
import { assertDefined } from "../tests/helpers";
import { OvaleConditionClass } from "./condition";

const baseStateMock = Mock.ofType<BaseState>();

test("call", () => {
    // Arrange
    const condition = new OvaleConditionClass(baseStateMock.object);
    condition.register(
        "test",
        (atTime: number, a: number, b: string) => {
            return [a, a + 10, b, atTime];
        },
        { type: "string" },
        { type: "number", name: "a", optional: false },
        { type: "string", name: "b", optional: false }
    );

    // Act
    const result = condition.call("test", 15, { 1: 5, 2: "text" });

    // Assert
    expect(result).toEqual([5, 15, "text", 15]);
});

test("getInfos", () => {
    // Arrange
    const condition = new OvaleConditionClass(baseStateMock.object);
    condition.register(
        "test",
        (atTime: number, a: number, b: string | undefined) => {
            return [a, a + 10, b];
        },
        { type: "string" },
        { type: "number", name: "a", optional: false },
        { type: "string", name: "b", optional: true }
    );

    // Act
    const result = condition.getInfos("test");

    // Assert
    assertDefined(result);
    expect(result.parameters).toEqual({
        1: { type: "number", name: "a", optional: false },
        2: { type: "string", name: "b", optional: true },
    });
    expect(result.namedParameters).toEqual({ a: 1, b: 2 });
});

test("call with replacement", () => {
    // Arrange
    const condition = new OvaleConditionClass(baseStateMock.object);
    condition.register(
        "test",
        (atTime: number, a: string) => {
            return [0, 10, a];
        },
        { type: "string" },
        {
            type: "string",
            name: "a",
            optional: false,
            mapValues: { original: "mapped" },
        }
    );

    // Act
    const result = condition.call("test", 0, { 1: "original" });

    // Assert
    assertDefined(result);
    expect(result).toEqual([0, 10, "mapped"]);
});
