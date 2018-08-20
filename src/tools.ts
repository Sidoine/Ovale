import { type, LuaArray } from "@wowts/lua";


export function isString(s: any): s is string {
    return type(s) === "string";
}

export function isNumber(s: any): s is number {
    return type(s) === "number";
}

export function isLuaArray<T>(a: any): a is LuaArray<T> {
    return type(a) === "table";
}

export type TypeCheck<T> = { [K in keyof T]: boolean};
export function checkToken<T>(type: TypeCheck<T>, token: any): token is keyof T {
    return type[<keyof T>token];
}
