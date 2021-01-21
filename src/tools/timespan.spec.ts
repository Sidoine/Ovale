import { test, expect } from "@jest/globals";
import { huge } from "@wowts/math";
import { newFromArgs } from "./TimeSpan";

test("HasTime with point to left of interval", () => {
    // Arrange
    const timeSpan = newFromArgs(10, 20);

    // Act
    const bool = timeSpan.hasTime(5);

    // Assert
    expect(bool).toBe(false);
});

test("HasTime with point on left endpoint of interval", () => {
    // Arrange
    const timeSpan = newFromArgs(10, 20);

    // Act
    const bool = timeSpan.hasTime(10);

    // Assert
    expect(bool).toBe(true);
});

test("HasTime with point inside interval", () => {
    // Arrange
    const timeSpan = newFromArgs(10, 20);

    // Act
    const bool = timeSpan.hasTime(15);

    // Assert
    expect(bool).toBe(true);
});

test("HasTime with point on right endpoint of interval", () => {
    // Arrange
    const timeSpan = newFromArgs(10, 20);

    // Act
    const bool = timeSpan.hasTime(20);

    // Assert
    expect(bool).toBe(false);
});

test("HasTime with point to right of interval", () => {
    // Arrange
    const timeSpan = newFromArgs(10, 20);

    // Act
    const bool = timeSpan.hasTime(25);

    // Assert
    expect(bool).toBe(false);
});

test("intersectInterval with one interval which is within the first", () => {
    // Arrange
    const timeSpan = newFromArgs(0, 10);

    // Act
    const result = timeSpan.intersectInterval(5, 10);

    // Assert
    expect(result[1]).toEqual(5);
    expect(result[2]).toEqual(10);
});

test("intersectInterval with one interval which overlaps the first", () => {
    // Arrange
    const timeSpan = newFromArgs(0, 10);

    // Act
    const result = timeSpan.intersectInterval(5, 15);

    // Assert
    expect(result[1]).toEqual(5);
    expect(result[2]).toEqual(10);
});

test("intersectInterval with one interval which overlaps the start of the first", () => {
    // Arrange
    const timeSpan = newFromArgs(0, 10);

    // Act
    const result = timeSpan.intersectInterval(-5, 5);

    // Assert
    expect(result[1]).toEqual(0);
    expect(result[2]).toEqual(5);
});

test("intersectInterval with one interval which does not overlap the end", () => {
    // Arrange
    const timeSpan = newFromArgs(0, 10);

    // Act
    const result = timeSpan.intersectInterval(11, 15);

    // Assert
    expect(result[1]).toBeUndefined();
});

test("intersectInterval with one interval which does not overlap the start", () => {
    // Arrange
    const timeSpan = newFromArgs(0, 10);

    // Act
    const result = timeSpan.intersectInterval(-5, -1);

    // Assert
    expect(result[1]).toBeUndefined();
});

test("intersectInterval with nothing", () => {
    // Arrange
    const timeSpan = newFromArgs();

    // Act
    const result = timeSpan.intersectInterval(1, huge);

    // Assert
    expect(result[1]).toBeUndefined();
});
