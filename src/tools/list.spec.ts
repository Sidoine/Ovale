import { expect, test } from "@jest/globals";
import { LuaArray } from "@wowts/lua";
import { List } from "./list";

test("new list is empty", () => {
    const l = new List<number>();
    expect(l.isEmpty()).toBe(true);
    expect(l.length).toBe(0);
    expect(l.front()).toBe(undefined);
    expect(l.back()).toBe(undefined);
});

test("from empty array", () => {
    const l = new List<number>();
    l.fromArray({});
    expect(l.length).toBe(0);
    expect(l.asArray()).toEqual({});
});

test("nodeOf from empety list", () => {
    const l = new List<number>();
    const [node, index] = l.nodeOf(10);
    expect(node).toBe(undefined);
    expect(index).toBe(undefined);
});

test("indexOf from empty list", () => {
    const l = new List<number>();
    expect(l.indexOf(10)).toBe(0);
});

test("from one-element array", () => {
    const l = new List<number>();
    const expected = { 1: 10 };
    l.fromArray(expected);
    expect(l.length).toBe(1);
    expect(l.back()).toBe(10);
    expect(l.asArray()).toEqual(expected);
});

test("from two-element array", () => {
    const l = new List<number>();
    const expected = { 1: 10, 2: 20 };
    l.fromArray(expected);
    expect(l.length).toBe(2);
    expect(l.front()).toBe(10);
    expect(l.back()).toBe(20);
    expect(l.asArray()).toEqual(expected);
});

test("as array", () => {
    const l = new List<number>();
    const t = { 1: 10, 2: 20, 3: 30 };
    l.fromArray(t);
    expect(l.asArray()).toEqual(t);
    expect(l.asArray(true)).toEqual({ 1: 30, 2: 20, 3: 10 });
});

test("push onto empty list", () => {
    const l = new List<number>();
    l.push(10);
    expect(l.length).toBe(1);
    expect(l.back()).toBe(10);
});

test("unshift empty list", () => {
    const l = new List<number>();
    l.unshift(10);
    expect(l.length).toBe(1);
    expect(l.front()).toBe(10);
});

test("pop from empty list", () => {
    const l = new List<number>();
    expect(l.pop()).toBe(undefined);
});

test("shift empty list", () => {
    const l = new List<number>();
    expect(l.shift()).toBe(undefined);
});

test("one-element list has same front and back", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10 });
    expect(l.front()).toBe(l.back());
});

test("insert after into one-element list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10 });
    const [node] = l.nodeOf(10);
    l.insertAfter(node, 20);
    expect(l.asArray()).toEqual({ 1: 10, 2: 20 });
});

test("insert before into one-element list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10 });
    const [node] = l.nodeOf(10);
    l.insertBefore(node, 20);
    expect(l.asArray()).toEqual({ 1: 20, 2: 10 });
});

test("push onto one-element list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10 });
    l.push(20);
    expect(l.length).toBe(2);
    expect(l.back()).toBe(20);
});

test("unshift one-element list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10 });
    l.unshift(20);
    expect(l.length).toBe(2);
    expect(l.front()).toBe(20);
});

test("pop from one-element list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10 });
    expect(l.pop()).toBe(10);
    expect(l.length).toBe(0);
});

test("shift one-element list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10 });
    expect(l.shift()).toBe(10);
    expect(l.length).toBe(0);
});

test("remove at 1 of one-element list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10 });
    expect(l.removeAt(1)).toBe(10);
    expect(l.length).toBe(0);
});

test("nodeOf missing from one-element list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10 });
    const [node, index] = l.nodeOf(20);
    expect(node).toBe(undefined);
    expect(index).toBe(undefined);
});

test("indexOf missing from one-element list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10 });
    expect(l.indexOf(20)).toBe(0);
});

test("insert after front of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    const [node] = l.nodeOf(10);
    l.insertAfter(node, 40);
    expect(l.asArray()).toEqual({ 1: 10, 2: 40, 3: 20, 4: 30 });
});

test("insert after back of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    const [node] = l.nodeOf(30);
    l.insertAfter(node, 40);
    expect(l.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
});

test("insert after middle of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    const [node] = l.nodeOf(20);
    l.insertAfter(node, 40);
    expect(l.asArray()).toEqual({ 1: 10, 2: 20, 3: 40, 4: 30 });
});

test("insert before front of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    const [node] = l.nodeOf(10);
    l.insertBefore(node, 40);
    expect(l.asArray()).toEqual({ 1: 40, 2: 10, 3: 20, 4: 30 });
});

test("insert before back of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    const [node] = l.nodeOf(30);
    l.insertBefore(node, 40);
    expect(l.asArray()).toEqual({ 1: 10, 2: 20, 3: 40, 4: 30 });
});

test("insert before middle of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    const [node] = l.nodeOf(20);
    l.insertBefore(node, 40);
    expect(l.asArray()).toEqual({ 1: 10, 2: 40, 3: 20, 4: 30 });
});

test("push onto list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20 });
    l.push(30);
    expect(l.asArray()).toEqual({ 1: 10, 2: 20, 3: 30 });
});

test("unshift list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20 });
    l.unshift(30);
    expect(l.asArray()).toEqual({ 1: 30, 2: 10, 3: 20 });
});

test("pop from list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    expect(l.pop()).toBe(30);
    expect(l.asArray()).toEqual({ 1: 10, 2: 20 });
});

test("shift list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    expect(l.shift()).toBe(10);
    expect(l.asArray()).toEqual({ 1: 20, 2: 30 });
});

test("insert at front of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    l.insertAt(1, 40);
    expect(l.asArray()).toEqual({ 1: 40, 2: 10, 3: 20, 4: 30 });
});

test("insert at middle of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    l.insertAt(l.length, 40);
    expect(l.asArray()).toEqual({ 1: 10, 2: 20, 3: 40, 4: 30 });
});

test("remove at front of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    expect(l.removeAt(1)).toBe(10);
    expect(l.asArray()).toEqual({ 1: 20, 2: 30 });
});

test("remove at back of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    expect(l.removeAt(l.length)).toBe(30);
    expect(l.asArray()).toEqual({ 1: 10, 2: 20 });
});

test("remove at middle of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    expect(l.removeAt(2)).toBe(20);
    expect(l.asArray()).toEqual({ 1: 10, 2: 30 });
});

test("nodeOf missing from list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    const [node, index] = l.nodeOf(40);
    expect(node).toBe(undefined);
    expect(index).toBe(undefined);
});

test("nodeOf existing from front of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    const [node, index] = l.nodeOf(10);
    expect(node && node.value).toBe(10);
    expect(index).toBe(1);
});

test("nodeOf existing from back of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    const [node, index] = l.nodeOf(30);
    expect(node && node.value).toBe(30);
    expect(index).toBe(3);
});

test("nodeOf existing from middle of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    const [node, index] = l.nodeOf(20);
    expect(node && node.value).toBe(20);
    expect(index).toBe(2);
});

test("indexOf missing from list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    expect(l.indexOf(40)).toBe(0);
});

test("indexOf existing from front of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    expect(l.indexOf(10)).toBe(1);
});

test("indexOf existing from back of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    expect(l.indexOf(30)).toBe(3);
});

test("indexOf existing from middle of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    expect(l.indexOf(20)).toBe(2);
});

test("back to front iterator of empty list", () => {
    const l = new List<number>();
    const iterator = l.backToFrontIterator();
    expect(iterator.next()).toBe(false);
});

test("back to front iterator of one-element list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10 });
    const t: LuaArray<number> = {};
    const iterator = l.backToFrontIterator();
    for (let i = 1; iterator.next(); i++) {
        t[i] = iterator.value;
    }
    expect(t).toEqual(l.asArray());
});

test("back to front iterator of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    const t: LuaArray<number> = {};
    const iterator = l.backToFrontIterator();
    for (let i = 1; iterator.next(); i++) {
        t[i] = iterator.value;
    }
    expect(t).toEqual(l.asArray(true));
});

test("front to back iterator of empty list", () => {
    const l = new List<number>();
    const iterator = l.frontToBackIterator();
    expect(iterator.next()).toBe(false);
});

test("front to back iterator of one-element list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10 });
    const t: LuaArray<number> = {};
    const iterator = l.frontToBackIterator();
    for (let i = 1; iterator.next(); i++) {
        t[i] = iterator.value;
    }
    expect(t).toEqual(l.asArray());
});

test("front to back iterator of list", () => {
    const l = new List<number>();
    l.fromArray({ 1: 10, 2: 20, 3: 30 });
    const t: LuaArray<number> = {};
    const iterator = l.frontToBackIterator();
    for (let i = 1; iterator.next(); i++) {
        t[i] = iterator.value;
    }
    expect(t).toEqual(l.asArray());
});
