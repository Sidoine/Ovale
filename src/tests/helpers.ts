import { expect } from "@jest/globals";

export function assertDefined<T>(a: T | undefined): asserts a is T {
    expect(a).toBeDefined();
}

export function assertIs<T extends string>(a: string, b: T): asserts a is T {
    expect(a).toBe(b);
}
