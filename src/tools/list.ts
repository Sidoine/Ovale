import { LuaArray, ipairs } from "@wowts/lua";

interface Iterator<T> {
    value: T;
    next(): boolean;
    replace(value: T): void;
}

class ListBackToFrontIterator<T> implements Iterator<T> {
    public value!: T;
    public node: ListNode<T> | undefined;
    private remaining = 0;

    constructor(list: List<T>) {
        this.node = list.head;
        this.remaining = list.length;
    }

    next() {
        if (this.node && this.remaining > 0) {
            this.node = this.node.prev;
            this.value = this.node.value;
            this.remaining -= 1;
            return this.remaining >= 0;
        }
        return false;
    }

    replace(value: T) {
        if (this.node) {
            this.node.value = value;
            this.value = value;
        }
    }
}

class ListFrontToBackIterator<T> implements Iterator<T> {
    public value!: T;
    public node: ListNode<T> | undefined;
    private remaining = 0;

    constructor(list: List<T>) {
        this.node = (list.head && list.head.prev) || undefined;
        this.remaining = list.length;
    }

    next() {
        if (this.node && this.remaining > 0) {
            this.node = this.node.next;
            this.value = this.node.value;
            this.remaining -= 1;
            return this.remaining >= 0;
        }
        return false;
    }

    replace(value: T) {
        if (this.node) {
            this.node.value = value;
            this.value = value;
        }
    }
}

export class ListNode<T> {
    next: ListNode<T>;
    prev: ListNode<T>;
    constructor(public value: T) {
        this.next = this;
        this.prev = this;
    }
}

/* Doubly-linked circular list:
 * - O(1) complexity to do insertions and removals anywhere.
 * - O(n) complexity to find a value in the list.
 */
export class List<T> {
    head: ListNode<T> | undefined;
    length = 0;

    constructor() {
        this.head = undefined;
    }

    isEmpty() {
        return this.length == 0;
    }

    front() {
        return (this.head && this.head.value) || undefined;
    }

    back() {
        return (this.head && this.head.prev.value) || undefined;
    }

    backToFrontIterator(): Iterator<T> {
        return new ListBackToFrontIterator<T>(this);
    }

    frontToBackIterator(): Iterator<T> {
        return new ListFrontToBackIterator<T>(this);
    }

    fromArray(t: LuaArray<T>) {
        for (const [, value] of ipairs(t)) {
            this.push(value);
        }
    }

    asArray(reverse?: boolean) {
        const t: LuaArray<T> = {};
        const iterator =
            (reverse == true && this.backToFrontIterator()) ||
            this.frontToBackIterator();
        for (let i = 1; iterator.next(); i++) {
            t[i] = iterator.value;
        }
        return t;
    }

    nodeOf(value: T): [ListNode<T> | undefined, number | undefined] {
        let node = this.head;
        let index = 1;
        if (node) {
            for (let remains = this.length; remains > 0; remains--) {
                if (node.value == value) {
                    return [node, index];
                }
                node = node.next;
                index += 1;
            }
        }
        return [undefined, undefined];
    }

    nodeAt(index: number) {
        const length = this.length;
        if (length > 0) {
            while (index > length) {
                index -= length;
            }
            while (index < 1) {
                index += length;
            }
            if (this.head) {
                let node = this.head;
                if (index <= length - index) {
                    for (let remains = index - 1; remains > 0; remains--) {
                        node = node.next;
                    }
                } else {
                    for (
                        let remains = length - index + 1;
                        remains > 0;
                        remains--
                    ) {
                        node = node.prev;
                    }
                }
                return node;
            }
        }
        return undefined;
    }

    insertAfter(node: ListNode<T> | undefined, value: T) {
        if (node) {
            const head = this.head;
            this.head = node.next;
            this.unshift(value);
            this.head = head;
        }
    }

    insertBefore(node: ListNode<T> | undefined, value: T) {
        if (node) {
            const head = this.head;
            if (node == head) {
                this.unshift(value);
            } else {
                this.head = node;
                this.push(value);
                this.head = head;
            }
        }
    }

    remove(node: ListNode<T> | undefined) {
        if (node) {
            const head = this.head;
            this.head = node.next;
            this.pop();
            if (this.head && head != node) {
                this.head = head;
            }
        }
    }

    indexOf(value: T) {
        const [, index] = this.nodeOf(value);
        return index || 0;
    }

    at(index: number) {
        const node = this.nodeAt(index);
        return (node && node.value) || undefined;
    }

    insertAt(index: number, value: T) {
        const node = this.nodeAt(index);
        if (node) {
            this.insertBefore(node, value);
        }
    }

    removeAt(index: number) {
        const node = this.nodeAt(index);
        if (node) {
            this.remove(node);
            return node.value;
        }
        return undefined;
    }

    replaceAt(index: number, value: T) {
        const node = this.nodeAt(index);
        if (node) {
            node.value = value;
        }
    }

    push(value: T) {
        const node = new ListNode<T>(value);
        if (!this.head) {
            this.head = node;
        } else {
            node.next = this.head;
            node.prev = this.head.prev;
            this.head.prev.next = node;
            this.head.prev = node;
        }
        this.length += 1;
        return node;
    }

    pop() {
        if (this.head) {
            const node = this.head.prev;
            const value = node.value;
            if (node == this.head) {
                this.head = undefined;
                this.length = 0;
            } else {
                node.prev.next = this.head;
                this.head.prev = node.prev;
                this.length -= 1;
            }
            return value;
        }
        return undefined;
    }

    unshift(value: T) {
        this.push(value);
        if (this.head) {
            this.head = this.head.prev;
        }
        return this.head;
    }

    shift() {
        const value = this.front();
        if (this.head) {
            this.remove(this.head);
        }
        return value;
    }
}
