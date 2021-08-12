import { expect, test } from "@jest/globals";
import { Deque } from "./Queue";

test("new queue", () => {
    const q = new Deque<number>();
    expect(q.capacity).toBe(1);
});

test("new queue sets size", () => {
    const q = new Deque<number>(10);
    expect(q.capacity).toBe(10);
});

test("new queue is empty", () => {
    const q = new Deque<number>();
    expect(q.isEmpty()).toBe(true);
    expect(q.length).toBe(0);
    expect(q.front()).toBe(undefined);
    expect(q.back()).toBe(undefined);
});

test("new queue is not full", () => {
    const q = new Deque<number>();
    expect(q.isFull()).toBe(false);
});

test("indexOf from empty queue", () => {
    const q = new Deque<number>();
    expect(q.indexOf(10)).toBe(0);
});

test("push onto empty queue", () => {
    const q = new Deque<number>();
    q.push(10);
    expect(q.length).toBe(1);
    expect(q.back()).toBe(10);
});

test("from empty array", () => {
    const q = new Deque<number>();
    q.fromArray({});
    expect(q.length).toBe(0);
    expect(q.isEmpty()).toBe(true);
    expect(q.asArray()).toEqual({});
});

test("from one-element array", () => {
    const q = new Deque<number>();
    const expected = { 1: 10 };
    q.fromArray(expected);
    expect(q.length).toBe(1);
    expect(q.back()).toBe(10);
    expect(q.asArray()).toEqual(expected);
});

test("from two-element array", () => {
    const q = new Deque<number>();
    const expected = { 1: 10, 2: 20 };
    q.fromArray(expected);
    expect(q.capacity).toBe(2);
    expect(q.length).toBe(2);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(20);
    expect(q.asArray()).toEqual(expected);
});

test("as array", () => {
    const q = new Deque<number>();
    const t = { 1: 10, 2: 20, 3: 30 };
    q.fromArray(t);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30 });
    expect(q.asArray(true)).toEqual({ 1: 30, 2: 20, 3: 10 });
});

test("unshift empty queue", () => {
    const q = new Deque<number>();
    q.unshift(10);
    expect(q.length).toBe(1);
    expect(q.front()).toBe(10);
    expect(q.asArray()).toEqual({ 1: 10 });
});

test("one-element queue has same front and back", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10 });
    expect(q.length).toBe(1);
    expect(q.front()).toBe(q.back());
});

test("pop from one-element queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10 });
    expect(q.pop()).toBe(10);
    expect(q.length).toBe(0);
    expect(q.isEmpty()).toBe(true);
});

test("shift one-element queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10 });
    expect(q.shift()).toBe(10);
    expect(q.length).toBe(0);
    expect(q.isEmpty()).toBe(true);
});

test("remove at 1 of one-element queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10 });
    q.removeAt(1);
    expect(q.length).toBe(0);
    expect(q.isEmpty()).toBe(true);
});

test("indexOf missing from one-element queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10 });
    expect(q.indexOf(20)).toBe(0);
});

test("indexOf existing from one-element queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10 });
    expect(q.indexOf(10)).toBe(1);
});

test("push onto queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10, 2: 20 });
    q.push(30);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(30);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30 });
});

test("unshift queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10, 2: 20 });
    q.unshift(30);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(30);
    expect(q.back()).toBe(20);
    expect(q.asArray()).toEqual({ 1: 30, 2: 10, 3: 20 });
});

test("pop from queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10, 2: 20, 3: 30 });
    const value = q.pop();
    expect(q.length).toBe(2);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(20);
    expect(value).toBe(30);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20 });
});

test("shift queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10, 2: 20, 3: 30 });
    const value = q.shift();
    expect(q.length).toBe(2);
    expect(q.front()).toBe(20);
    expect(q.back()).toBe(30);
    expect(value).toBe(10);
    expect(q.asArray()).toEqual({ 1: 20, 2: 30 });
});

test("remove at 1 of queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.removeAt(1);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(20);
    expect(q.back()).toBe(40);
    expect(q.asArray()).toEqual({ 1: 20, 2: 30, 3: 40 });
});

test("remove at end of queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.removeAt(q.length);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(30);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30 });
});

test("remove at middle of queue near front", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.removeAt(2);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(40);
    expect(q.asArray()).toEqual({ 1: 10, 2: 30, 3: 40 });
});

test("remove at middle of queue near back", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.removeAt(3);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(40);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 40 });
});

test("indexOf missing from queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10, 2: 20, 3: 30, 4: 40 });
    expect(q.indexOf(50)).toBe(0);
});

test("indexOf existing from front of queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10, 2: 20, 3: 30, 4: 40 });
    expect(q.indexOf(10)).toBe(1);
});

test("indexOf existing from back of queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10, 2: 20, 3: 30, 4: 40 });
    expect(q.indexOf(40)).toBe(4);
});

test("indexOf existing from middle of queue", () => {
    const q = new Deque<number>();
    q.fromArray({ 1: 10, 2: 20, 3: 30, 4: 40 });
    expect(q.indexOf(20)).toBe(2);
});

test("grow queue", () => {
    const q = new Deque<number>();
    q.push(10);
    expect(q.capacity).toBe(1);
    q.push(20); // grow once
    expect(q.capacity).toBe(2);
    q.push(30); // grow twice
    expect(q.capacity).toBe(4);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(30);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30 });
});

test("not full fixed queue", () => {
    const q = new Deque<number>(3, true);
    q.fromArray({ 1: 10, 2: 20 });
    expect(q.capacity).toBe(3);
    expect(q.length).toBe(2);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(20);
    expect(q.isFull()).toBe(false);
});

test("full fixed queue", () => {
    const q = new Deque<number>(3, true);
    q.fromArray({ 1: 10, 2: 20, 3: 30 });
    expect(q.capacity).toBe(3);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(30);
    expect(q.isFull()).toBe(true);
});

test("push onto full queue", () => {
    const q = new Deque<number>(3, true);
    q.fromArray({ 1: 10, 2: 20, 3: 30 });
    q.push(40);
    expect(q.capacity).toBe(3);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(20);
    expect(q.back()).toBe(40);
    expect(q.isFull()).toBe(true);
    expect(q.asArray()).toEqual({ 1: 20, 2: 30, 3: 40 });
});

test("unshift full queue", () => {
    const q = new Deque<number>(3, true);
    q.fromArray({ 1: 10, 2: 20, 3: 30 });
    q.unshift(40);
    expect(q.capacity).toBe(3);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(40);
    expect(q.back()).toBe(20);
    expect(q.isFull()).toBe(true);
    expect(q.asArray()).toEqual({ 1: 40, 2: 10, 3: 20 });
});

function createWraparoundQueue(fixed?: boolean) {
    /* Return a 4-element queue with capacity 5 that starts in the
     * middle of the buffer.
     */
    if (fixed == undefined) {
        fixed = false;
    }
    const q = new Deque<number>(5, fixed);
    q.push(-20);
    q.push(-10);
    q.push(0);
    q.push(10);
    q.push(20);
    q.shift(); // remove -20
    q.shift(); // remove -10
    q.shift(); // remove 0
    q.push(30);
    q.push(40);
    // queue.buffer: 30 40] nil [10 20
    //expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    return q;
}

test("queue with wraparound indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    expect(q.length).toBe(4);
    expect(q.capacity).toBe(5);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(40);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
});

test("push onto queue with wrapround indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.push(50);
    expect(q.capacity).toBe(5);
    expect(q.length).toBe(5);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(50);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40, 5: 50 });
});

test("unshift queue with wrapround indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.unshift(50);
    expect(q.capacity).toBe(5);
    expect(q.length).toBe(5);
    expect(q.front()).toBe(50);
    expect(q.back()).toBe(40);
    expect(q.asArray()).toEqual({ 1: 50, 2: 10, 3: 20, 4: 30, 5: 40 });
});

test("pop from queue with wrapround indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    expect(q.pop()).toBe(40);
    expect(q.capacity).toBe(5);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(30);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30 });
});

test("shift queue with wrapround indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    expect(q.shift()).toBe(10);
    expect(q.capacity).toBe(5);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(20);
    expect(q.back()).toBe(40);
    expect(q.asArray()).toEqual({ 1: 20, 2: 30, 3: 40 });
});

test("remove at 1 of queue with wraparound indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.removeAt(1);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(20);
    expect(q.back()).toBe(40);
    expect(q.asArray()).toEqual({ 1: 20, 2: 30, 3: 40 });
});

test("remove at end of queue with wraparound indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.removeAt(q.length);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(30);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30 });
});

test("remove at middle of queue near front with wraparound indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.removeAt(2);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(40);
    expect(q.asArray()).toEqual({ 1: 10, 2: 30, 3: 40 });
});

test("remove at middle of queue near back with wraparound indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.removeAt(3);
    expect(q.length).toBe(3);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(40);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 40 });
});

test("indexOf missing from queue with wraparound indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    expect(q.indexOf(50)).toBe(0);
});

test("indexOf existing from front of queue with wraparound indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    expect(q.indexOf(10)).toBe(1);
});

test("indexOf existing from back of queue with wraparound indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    expect(q.indexOf(40)).toBe(4);
});

test("indexOf existing from middle of queue with wraparound indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    expect(q.indexOf(20)).toBe(2);
});

test("grow queue with wraparound indexing", () => {
    const q = createWraparoundQueue();
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.push(50); // buffer at full capacity
    q.push(60);
    expect(q.length).toBe(6);
    expect(q.capacity).toBe(10);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(60);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40, 5: 50, 6: 60 });
});

test("full queue with wraparound indexing", () => {
    const q = createWraparoundQueue(true);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.push(50); // buffer at full capacity
    expect(q.capacity).toBe(5);
    expect(q.length).toBe(5);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(50);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40, 5: 50 });
});

test("push onto full queue with wraparound indexing", () => {
    const q = createWraparoundQueue(true);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.push(50); // buffer at full capacity
    q.push(60);
    expect(q.capacity).toBe(5);
    expect(q.length).toBe(5);
    expect(q.front()).toBe(20);
    expect(q.back()).toBe(60);
    expect(q.asArray()).toEqual({ 1: 20, 2: 30, 3: 40, 4: 50, 5: 60 });
});

test("unshift full queue with wraparound indexing", () => {
    const q = createWraparoundQueue(true);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.push(50); // buffer at full capacity
    q.unshift(60);
    expect(q.capacity).toBe(5);
    expect(q.length).toBe(5);
    expect(q.front()).toBe(60);
    expect(q.back()).toBe(40);
    expect(q.asArray()).toEqual({ 1: 60, 2: 10, 3: 20, 4: 30, 5: 40 });
});

test("pop from full queue with wraparound indexing", () => {
    const q = createWraparoundQueue(true);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.push(50); // buffer at full capacity
    expect(q.pop()).toBe(50);
    expect(q.capacity).toBe(5);
    expect(q.length).toBe(4);
    expect(q.front()).toBe(10);
    expect(q.back()).toBe(40);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
});

test("shift from full queue with wraparound indexing", () => {
    const q = createWraparoundQueue(true);
    expect(q.asArray()).toEqual({ 1: 10, 2: 20, 3: 30, 4: 40 });
    q.push(50); // buffer at full capacity
    expect(q.shift()).toBe(10);
    expect(q.capacity).toBe(5);
    expect(q.length).toBe(4);
    expect(q.front()).toBe(20);
    expect(q.back()).toBe(50);
    expect(q.asArray()).toEqual({ 1: 20, 2: 30, 3: 40, 4: 50 });
});
