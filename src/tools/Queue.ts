import { format } from "@wowts/string";

class BackToFrontIterator<T> {
    public value!: T;
    constructor(private invariant: OvaleDequeue<T>, public control: number) {}
    Next() {
        this.control = this.control - 1;
        this.value = this.invariant[this.control];
        return this.control >= this.invariant.first;
    }
}

class FrontToBackIterator<T> {
    public value!: T;
    constructor(private invariant: OvaleDequeue<T>, private control: number) {}
    Next() {
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

    InsertFront(element: T) {
        const first = this.first - 1;
        this.first = first;
        this[first] = element;
    }

    InsertBack(element: T) {
        const last = this.last + 1;
        this.last = last;
        this[last] = element;
    }

    RemoveFront() {
        const first = this.first;
        const element = this[first];
        if (element) {
            delete this[first];
            this.first = first + 1;
        }
        return element;
    }

    RemoveBack() {
        const last = this.last;
        const element = this[last];
        if (element) {
            delete this[last];
            this.last = last - 1;
        }
        return element;
    }

    At(index: number) {
        if (index > this.Size()) {
            return;
        }
        return this[this.first + index - 1];
    }

    Front() {
        return this[this.first];
    }

    Back() {
        return this[this.last];
    }

    BackToFrontIterator() {
        return new BackToFrontIterator<T>(this, this.last + 1);
    }

    FrontToBackIterator() {
        return new FrontToBackIterator<T>(this, this.first - 1);
    }

    Reset() {
        const iterator = this.BackToFrontIterator();
        while (iterator.Next()) {
            delete this[iterator.control];
        }
        this.first = 0;
        this.last = -1;
    }

    Size() {
        return this.last - this.first + 1;
    }

    DebuggingInfo() {
        return format(
            "Queue %s has %d item(s), first=%d, last=%d.",
            this.name,
            this.Size(),
            this.first,
            this.last
        );
    }
}

// Queue (FIFO) methods
export class OvaleQueue<T> extends OvaleDequeue<T> {
    Insert(value: T) {
        this.InsertBack(value);
    }

    Remove() {
        return this.RemoveFront();
    }

    Iterator() {
        return this.FrontToBackIterator();
    }
}

export class OvaleStack<T> extends OvaleDequeue<T> {
    Push(value: T) {
        this.InsertBack(value);
    }

    Pop() {
        return this.RemoveBack();
    }

    Top() {
        return this.Back();
    }
}
