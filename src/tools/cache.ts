import { LuaObj } from "@wowts/lua";
import { List, ListNode } from "./list";

class Cache<T> {
    list: List<T>;
    nodeByValue: LuaObj<ListNode<T>> = {};

    constructor(public size: number) {
        this.list = new List<T>();
    }

    isFull() {
        return this.list.length >= this.size;
    }

    newest() {
        return this.list.back();
    }

    oldest() {
        return this.list.front();
    }

    asArray() {
        return this.list.asArray();
    }

    evict() {
        return this.list.shift();
    }

    put(value: T) {
        this.remove(value);
        const evicted = (this.isFull() && this.evict()) || undefined;
        /* Pretend to cast to string to satisfy TypeScript.
         * Lua tables can accept anything as a valid key.
         */
        const key = value as unknown as string;
        this.nodeByValue[key] = this.list.push(value);
        return evicted;
    }

    remove(value: T) {
        /* Pretend to cast to string to satisfy TypeScript.
         * Lua tables can accept anything as a valid key.
         */
        const key = value as unknown as string;
        const node = this.nodeByValue[key];
        if (node) {
            this.list.remove(node);
        }
    }
}

export class LRUCache<T> extends Cache<T> {
    evict() {
        // LRU policy evicts the oldest item
        return this.list.shift();
    }
}

export class MRUCache<T> extends Cache<T> {
    evict() {
        // MRU policy evicts the newest item
        return this.list.pop();
    }
}
