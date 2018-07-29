import { setmetatable } from "@wowts/lua";

export type Constructor<T> = new(...argv: any[]) => T;

export interface Library<T> {
    Embed<U>(base: Constructor<U>): Constructor<T & U>;
}

export function newClass(base: any, prototype: any) {
    const c = prototype;
    if (base) {
        if (!base.constructor) {
            base.constructor = () => {};
        }
    } else {
        if (!c.constructor)  {
            c.constructor = () => {};
        }
    }

    c.__index = c;
    setmetatable(c, <any> {
        // tslint:disable-next-line:variable-name
        __call: (cls: any, ...__args: any[]) => {
            const self = <{constructor(...args: any[]): void}> setmetatable({}, cls);
            self.constructor(...__args);
            return self;
        },
        __index: base,
    });
    return c;
}
