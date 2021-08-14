import { expect, test } from "@jest/globals";
import { LRUCache, MRUCache } from "./cache";

test("new LRU cache is not full", () => {
    const cache = new LRUCache<number>(3);
    expect(cache.isFull()).toBe(false);
});

test("put into empty LRU cache", () => {
    const cache = new LRUCache<number>(3);
    const value = cache.put(10);
    expect(value).toBe(undefined);
    expect(cache.oldest()).toBe(10);
    expect(cache.oldest()).toBe(cache.newest());
});

test("put into non-empty LRU cache", () => {
    const cache = new LRUCache<number>(3);
    cache.put(10);
    cache.put(20);
    const value = cache.put(30);
    expect(value).toBe(undefined);
    expect(cache.oldest()).toBe(10);
    expect(cache.newest()).toBe(30);
    expect(cache.asArray()).toEqual({ 1: 10, 2: 20, 3: 30 });
});

test("put into full LRU cache", () => {
    const cache = new LRUCache<number>(3);
    cache.put(10);
    cache.put(20);
    cache.put(30);
    const value = cache.put(40);
    expect(value).toBe(10);
    expect(cache.asArray()).toEqual({ 1: 20, 2: 30, 3: 40 });
});

test("new MRU cache is not full", () => {
    const cache = new MRUCache<number>(3);
    expect(cache.isFull()).toBe(false);
});

test("put into empty MRU cache", () => {
    const cache = new MRUCache<number>(3);
    const value = cache.put(10);
    expect(value).toBe(undefined);
    expect(cache.oldest()).toBe(10);
    expect(cache.oldest()).toBe(cache.newest());
});

test("put into non-empty MRU cache", () => {
    const cache = new MRUCache<number>(3);
    cache.put(10);
    cache.put(20);
    const value = cache.put(30);
    expect(value).toBe(undefined);
    expect(cache.oldest()).toBe(10);
    expect(cache.newest()).toBe(30);
    expect(cache.asArray()).toEqual({ 1: 10, 2: 20, 3: 30 });
});

test("put into full MRU cache", () => {
    const cache = new MRUCache<number>(3);
    cache.put(10);
    cache.put(20);
    cache.put(30);
    const value = cache.put(40);
    expect(value).toBe(30);
    expect(cache.asArray()).toEqual({ 1: 10, 2: 20, 3: 40 });
});
