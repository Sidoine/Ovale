import { LuaArray, ipairs, lualength } from "@wowts/lua";

interface Iterator<T> {
    value: T;
    next(): boolean;
}

class DequeBackToFrontIterator<T> implements Iterator<T> {
    public value!: T;
    private index = 0;
    private remaining = 0;

    constructor(private deque: Deque<T>) {
        this.index = deque.indexAfter(deque.last);
        this.remaining = deque.length;
    }

    next() {
        if (this.deque.length == 0) {
            return false;
        }
        this.index = this.deque.indexBefore(this.index);
        this.value = this.deque.buffer[this.index];
        this.remaining -= 1;
        return this.remaining >= 0;
    }
}

class DequeFrontToBackIterator<T> implements Iterator<T> {
    public value!: T;
    private index = 0;
    private remaining = 0;

    constructor(private deque: Deque<T>) {
        this.index = deque.indexBefore(deque.first);
        this.remaining = deque.length;
    }

    next() {
        if (this.deque.length == 0) {
            return false;
        }
        this.index = this.deque.indexAfter(this.index);
        this.value = this.deque.buffer[this.index];
        this.remaining -= 1;
        return this.remaining >= 0;
    }
}

// Double-ended queue
export class Deque<T> {
    capacity = 0;
    private canGrow = true;

    buffer: LuaArray<T> = {};
    first = 0;
    last = 0;
    length = 0;

    constructor(capacity?: number, fixed?: boolean) {
        this.capacity = (capacity && capacity > 0 && capacity) || 1;
        this.canGrow = fixed == undefined || !fixed;
    }

    isEmpty() {
        return this.length == 0;
    }

    isFull() {
        return !this.canGrow && this.length == this.capacity;
    }

    front() {
        return (this.length > 0 && this.buffer[this.first]) || undefined;
    }

    back() {
        return (this.length > 0 && this.buffer[this.last]) || undefined;
    }

    indexAfter = (index: number) => {
        return (index < this.capacity && index + 1) || 1;
    };

    indexBefore = (index: number) => {
        return (index > 1 && index - 1) || this.capacity;
    };

    backToFrontIterator() {
        return new DequeBackToFrontIterator<T>(this);
    }

    frontToBackIterator() {
        return new DequeFrontToBackIterator<T>(this);
    }

    fromArray(t: LuaArray<T>) {
        const length = lualength(t);
        if (length > 0) {
            const buffer = this.buffer;
            for (const [i, value] of ipairs(t)) {
                buffer[i] = value;
            }
            if (this.capacity < length) {
                this.capacity = length;
            }
            this.first = 1;
            this.last = length;
            this.length = length;
        } else {
            this.first = 0;
            this.last = 0;
            this.length = 0;
        }
    }

    asArray(reverse?: boolean) {
        const t: LuaArray<T> = {};
        let index = 1;
        const iterator =
            (reverse == true && this.backToFrontIterator()) ||
            this.frontToBackIterator();
        while (iterator.next()) {
            t[index] = iterator.value;
            index += 1;
        }
        return t;
    }

    indexOf(value: T, from?: number) {
        const buffer = this.buffer;
        const capacity = this.capacity;
        let index = from || 1;
        let mappedIndex = this.first + index - 1;
        let remaining = this.length - index + 1;
        while (remaining > 0) {
            if (buffer[mappedIndex] == value) {
                return index;
            }
            index += 1;
            mappedIndex = (mappedIndex < capacity && mappedIndex + 1) || 1;
            remaining -= 1;
        }
        return 0;
    }

    at(index: number) {
        if (1 <= index && index <= this.length) {
            index = this.first + index - 1;
            if (index > this.capacity) {
                index -= this.capacity;
            }
            return this.buffer[index];
        }
        return undefined;
    }

    removeAt(index: number) {
        if (index == 1) {
            this.shift();
        } else if (index == this.length) {
            this.pop();
        } else if (1 < index && index < this.length) {
            const buffer = this.buffer;
            const first = this.first;
            const last = this.last;
            const length = this.length;
            const mappedIndex = first + index - 1;
            if (last > first) {
                // 1 [2 3 4] 5
                if (index - 1 > length - index) {
                    // [1 .. (index - 1)] is longer than [(index + 1) .. length]
                    let i = mappedIndex;
                    while (i < last) {
                        buffer[i] = buffer[i + 1];
                        i += 1;
                    }
                    delete buffer[last];
                    this.last -= 1;
                } else {
                    let i = mappedIndex;
                    while (i > first) {
                        buffer[i] = buffer[i - 1];
                        i -= 1;
                    }
                    delete buffer[first];
                    this.first += 1;
                }
            } else {
                // 1 2] 3 [4 5
                if (mappedIndex > this.capacity) {
                    let i = mappedIndex - this.capacity;
                    while (i < last) {
                        buffer[i] = buffer[i + 1];
                        i += 1;
                    }
                    delete buffer[last];
                    this.last -= 1;
                } else {
                    let i = mappedIndex;
                    while (i > first) {
                        buffer[i] = buffer[i - 1];
                        i -= 1;
                    }
                    delete buffer[first];
                    this.first += 1;
                }
            }
            this.length -= 1;
        }
    }

    private grow(capacity?: number) {
        capacity = capacity || 2 * this.capacity;
        if (capacity > this.capacity && this.last < this.first) {
            // shift [first, first + 1, ... , capacity] elements to the right
            const shift = capacity - this.capacity;
            const buffer = this.buffer;
            const first = this.first;
            let i = this.capacity;
            while (i >= first) {
                buffer[i + shift] = buffer[i];
                delete buffer[i];
                i -= 1;
            }
            this.first = this.first + shift;
        }
        this.capacity = capacity;
    }

    push(value: T) {
        if (this.length == 0) {
            this.length = 1;
            this.first = 1;
            this.last = 1;
            this.buffer[1] = value;
        } else {
            if (this.length < this.capacity) {
                this.length += 1;
            } else if (this.canGrow) {
                this.grow();
                this.length += 1;
            } else {
                this.first = this.indexAfter(this.first);
            }
            this.last = this.indexAfter(this.last);
            this.buffer[this.last] = value;
        }
    }

    pop() {
        if (this.length > 0) {
            const value = this.buffer[this.last];
            if (this.length == 1) {
                this.length = 0;
                this.first = 0;
                this.last = 0;
            } else {
                this.length -= 1;
                this.last = this.indexBefore(this.last);
            }
            return value;
        }
        return undefined;
    }

    unshift(value: T) {
        if (this.length == 0) {
            this.length = 1;
            this.first = 1;
            this.last = 1;
            this.buffer[1] = value;
        } else {
            if (this.length < this.capacity) {
                this.length += 1;
            } else if (this.canGrow) {
                this.grow();
                this.length += 1;
            } else {
                this.last = this.indexBefore(this.last);
            }
            this.first = this.indexBefore(this.first);
            this.buffer[this.first] = value;
        }
    }

    shift() {
        if (this.length > 0) {
            const value = this.buffer[this.first];
            if (this.length == 1) {
                this.length = 0;
                this.first = 0;
                this.last = 0;
            } else {
                this.first = this.indexAfter(this.first);
                this.length -= 1;
            }
            return value;
        }
        return undefined;
    }
}

export class Queue<T> extends Deque<T> {
    iterator() {
        return this.frontToBackIterator();
    }
}

// Stack (FIFO)
export class Stack<T> extends Deque<T> {
    top() {
        return super.back();
    }

    iterator() {
        return this.backToFrontIterator();
    }
}
