import { assert, tostring, wipe, LuaArray } from "@wowts/lua";
import { insert, remove } from "@wowts/table";
import { format } from "@wowts/string";

export class OvalePool<T> {
    pool: LuaArray<T> = {};
    size = 0;
    unused = 0;
    name: string;

    constructor(name: string) {
        this.name = name || "OvalePool";
    }

    get() {
        // OvalePool.StartProfiling(this.name);
        assert(this.pool);
        let item = remove(this.pool);
        if (item) {
            this.unused = this.unused - 1;
        } else {
            this.size = this.size + 1;
            item = <T>{};
        }
        // OvalePool.StopProfiling(this.name);
        return item;
    }
    release(item: T): void {
        // OvalePool.StartProfiling(this.name);
        assert(this.pool);
        this.clean(item);
        insert(this.pool, item);
        this.unused = this.unused + 1;
        // OvalePool.StopProfiling(this.name);
    }
    drain(): void {
        //OvalePool.StartProfiling(this.name);
        this.pool = {};
        this.size = this.size - this.unused;
        this.unused = 0;
        //OvalePool.StopProfiling(this.name);
    }
    debuggingInfo(): string {
        return format(
            "Pool %s has size %d with %d item(s).",
            tostring(this.name),
            this.size,
            this.unused
        );
    }

    clean(item: T): void {
        wipe(item);
    }
}
