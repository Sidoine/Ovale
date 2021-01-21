import { format } from "@wowts/string";

class BackToFrontIterator<T> {
    public value!: T;
    constructor(private invariant: OvaleDequeue<T>, public control: number) {}
    next() {
        this.control = this.control - 1;
        this.value = this.invariant[this.control];
        return this.control >= this.invariant.first;
    }
}

class FrontToBackIterator<T> {
    public value!: T;
    constructor(private invariant: OvaleDequeue<T>, private control: number) {}
    next() {
        this.control = this.control + 1;
        this.value = this.invariant[this.control];
        return this.control <= this.invariant.last;
    }
}

export class OvaleDequeue<T> {
    first = 0;
    last = -1;
    [index: number]: T;

    constructor(public name: string) {}

    insertFront(element: T) {
        const first = this.first - 1;
        this.first = first;
        this[first] = element;
    }

    insertBack(element: T) {
        const last = this.last + 1;
        this.last = last;
        this[last] = element;
    }

    removeFront() {
        const first = this.first;
        const element = this[first];
        if (element) {
            delete this[first];
            this.first = first + 1;
        }
        return element;
    }

    removeBack() {
        const last = this.last;
        const element = this[last];
        if (element) {
            delete this[last];
            this.last = last - 1;
        }
        return element;
    }

    at(index: number) {
        if (index > this.size()) {
            return;
        }
        return this[this.first + index - 1];
    }

    front() {
        return this[this.first];
    }

    back() {
        return this[this.last];
    }

    backToFrontIterator() {
        return new BackToFrontIterator<T>(this, this.last + 1);
    }

    frontToBackIterator() {
        return new FrontToBackIterator<T>(this, this.first - 1);
    }

    reset() {
        const iterator = this.backToFrontIterator();
        while (iterator.next()) {
            delete this[iterator.control];
        }
        this.first = 0;
        this.last = -1;
    }

    size() {
        return this.last - this.first + 1;
    }

    debuggingInfo() {
        return format(
            "Queue %s has %d item(s), first=%d, last=%d.",
            this.name,
            this.size(),
            this.first,
            this.last
        );
    }
}

// Queue (FIFO) methods
export class OvaleQueue<T> extends OvaleDequeue<T> {
    insert(value: T) {
        this.insertBack(value);
    }

    remove() {
        return this.removeFront();
    }

    iterator() {
        return this.frontToBackIterator();
    }
}

export class OvaleStack<T> extends OvaleDequeue<T> {
    push(value: T) {
        this.insertBack(value);
    }

    pop() {
        return this.removeBack();
    }

    top() {
        return this.back();
    }
}
