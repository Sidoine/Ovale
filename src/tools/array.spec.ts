import { expect, test } from "@jest/globals";
import {
    binaryInsert,
    binaryInsertUnique,
    binarySearch,
    binaryRemove,
} from "./array";

test("insert into empty array", () => {
    const expected = { 1: 1 };
    const t = {};
    binaryInsert(t, 1);
    expect(t).toEqual(expected);
});

test("insert smallest into one-element array", () => {
    const expected = { 1: 1, 2: 10 };
    const t = { 1: 10 };
    binaryInsert(t, 1);
    expect(t).toEqual(expected);
});

test("insert largest into one-element array", () => {
    const expected = { 1: 10, 2: 100 };
    const t = { 1: 10 };
    binaryInsert(t, 100);
    expect(t).toEqual(expected);
});

test("insert match into one-element array", () => {
    const expected = { 1: 10, 2: 10 };
    const t = { 1: 10 };
    binaryInsert(t, 10);
    expect(t).toEqual(expected);
});

test("insert smallest into sorted array", () => {
    const expected = { 1: 1, 2: 10, 3: 20, 4: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryInsert(t, 1);
    expect(t).toEqual(expected);
});

test("insert smallest match into sorted array", () => {
    const expected = { 1: 10, 2: 10, 3: 20, 4: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryInsert(t, 10);
    expect(t).toEqual(expected);
});

test("insert largest into sorted array", () => {
    const expected = { 1: 10, 2: 20, 3: 30, 4: 100 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryInsert(t, 100);
    expect(t).toEqual(expected);
});

test("insert largest match into sorted array", () => {
    const expected = { 1: 10, 2: 20, 3: 30, 4: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryInsert(t, 30);
    expect(t).toEqual(expected);
});

test("insert middle of sorted array", () => {
    const expected = { 1: 10, 2: 20, 3: 25, 4: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryInsert(t, 25);
    expect(t).toEqual(expected);
});

test("insert middle match of sorted array", () => {
    const expected = { 1: 10, 2: 20, 3: 20, 4: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryInsert(t, 20);
    expect(t).toEqual(expected);
});

test("insert unique into empty array", () => {
    const expected = { 1: 1 };
    const t = {};
    binaryInsertUnique(t, 1);
    expect(t).toEqual(expected);
});

test("insert unique smallest into one-element array", () => {
    const expected = { 1: 1, 2: 10 };
    const t = { 1: 10 };
    binaryInsertUnique(t, 1);
    expect(t).toEqual(expected);
});

test("insert unique largest into one-element array", () => {
    const expected = { 1: 10, 2: 100 };
    const t = { 1: 10 };
    binaryInsertUnique(t, 100);
    expect(t).toEqual(expected);
});

test("insert unique match into one-element array", () => {
    const expected = { 1: 10 };
    const t = { 1: 10 };
    binaryInsertUnique(t, 10);
    expect(t).toEqual(expected);
});

test("insert unique smallest into sorted array", () => {
    const expected = { 1: 1, 2: 10, 3: 20, 4: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryInsertUnique(t, 1);
    expect(t).toEqual(expected);
});

test("insert unique smallest match into sorted array", () => {
    const expected = { 1: 10, 2: 20, 3: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryInsertUnique(t, 10);
    expect(t).toEqual(expected);
});

test("insert unique largest into sorted array", () => {
    const expected = { 1: 10, 2: 20, 3: 30, 4: 100 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryInsertUnique(t, 100);
    expect(t).toEqual(expected);
});

test("insert unique largest match into sorted array", () => {
    const expected = { 1: 10, 2: 20, 3: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryInsertUnique(t, 30);
    expect(t).toEqual(expected);
});

test("insert unique middle of sorted array", () => {
    const expected = { 1: 10, 2: 20, 3: 25, 4: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryInsertUnique(t, 25);
    expect(t).toEqual(expected);
});

test("insert unique middle match of sorted array", () => {
    const expected = { 1: 10, 2: 20, 3: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryInsertUnique(t, 20);
    expect(t).toEqual(expected);
});

test("remove from empty array", () => {
    const expected = {};
    const t = {};
    binaryRemove(t, 1);
    expect(t).toEqual(expected);
});

test("remove from one-element array", () => {
    const expected = {};
    const t = { 1: 10 };
    binaryRemove(t, 10);
    expect(t).toEqual(expected);
});

test("remove nonexistent from one-element array", () => {
    const expected = { 1: 10 };
    const t = { 1: 10 };
    binaryRemove(t, 1);
    expect(t).toEqual(expected);
});

test("remove smallest nonexistent from sorted array", () => {
    const expected = { 1: 10, 2: 20, 3: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryRemove(t, 1);
    expect(t).toEqual(expected);
});

test("remove smallest match from sorted array", () => {
    const expected = { 1: 20, 2: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryRemove(t, 10);
    expect(t).toEqual(expected);
});

test("remove largest nonexistent from sorted array", () => {
    const expected = { 1: 10, 2: 20, 3: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryRemove(t, 100);
    expect(t).toEqual(expected);
});

test("remove largest match from sorted array", () => {
    const expected = { 1: 10, 2: 20 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryRemove(t, 30);
    expect(t).toEqual(expected);
});

test("remove middle nonexistent from sorted array", () => {
    const expected = { 1: 10, 2: 20, 3: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryRemove(t, 25);
    expect(t).toEqual(expected);
});

test("remove middle match from sorted array", () => {
    const expected = { 1: 10, 2: 30 };
    const t = { 1: 10, 2: 20, 3: 30 };
    binaryRemove(t, 20);
    expect(t).toEqual(expected);
});

test("search in empty array", () => {
    const t = {};
    const index = binarySearch(t, 1);
    expect(index).toBe(undefined);
});

test("search in one-element array", () => {
    const t = { 1: 10 };
    const index = binarySearch(t, 10);
    expect(index).toBe(1);
});

test("search nonexistent in one-element array", () => {
    const t = { 1: 10 };
    const index = binarySearch(t, 1);
    expect(index).toBe(undefined);
});

test("search smallest nonexistent in sorted array", () => {
    const t = { 1: 10, 2: 20, 3: 30 };
    const index = binarySearch(t, 1);
    expect(index).toBe(undefined);
});

test("search smallest match in sorted array", () => {
    const t = { 1: 10, 2: 20, 3: 30 };
    const index = binarySearch(t, 10);
    expect(index).toBe(1);
});

test("search largest nonexistent in sorted array", () => {
    const t = { 1: 10, 2: 20, 3: 30 };
    const index = binarySearch(t, 100);
    expect(index).toBe(undefined);
});

test("search largest match in sorted array", () => {
    const t = { 1: 10, 2: 20, 3: 30 };
    const index = binarySearch(t, 30);
    expect(index).toBe(3);
});

test("search middle nonexistent in sorted array", () => {
    const t = { 1: 10, 2: 20, 3: 30 };
    const index = binarySearch(t, 25);
    expect(index).toBe(undefined);
});

test("search middle match in sorted array", () => {
    const t = { 1: 10, 2: 20, 3: 30 };
    const index = binarySearch(t, 20);
    expect(index).toBe(2);
});

test("insert with custom compare", () => {
    const expected = { 1: 30, 2: 25, 3: 20, 4: 10 };
    const t = { 1: 30, 2: 20, 3: 10 };
    binaryInsert(t, 25, (a, b) => {
        return a > b;
    });
    expect(t).toEqual(expected);
});
