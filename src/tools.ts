import {
    type,
    LuaArray,
    LuaObj,
    pairs,
    strjoin,
    tostring,
    tostringall,
    truthy,
    wipe,
    select,
} from "@wowts/lua";
import { len, find, format } from "@wowts/string";
import { DEFAULT_CHAT_FRAME, UIFrame } from "@wowts/wow-mock";

export function isString(s: any): s is string {
    return type(s) === "string";
}

export function isNumber(s: any): s is number {
    return type(s) === "number";
}

export function isLuaArray<T>(a: any): a is LuaArray<T> {
    return type(a) === "table";
}

export type KeyCheck<T extends string> = { [K in T]: boolean };

export type TypeCheck<T> = { [K in keyof Required<T>]: boolean };
export function checkToken<T extends string>(
    type: KeyCheck<T>,
    token: any
): token is T {
    return type[<T>token];
}

export const oneTimeMessages: LuaObj<boolean | "printed"> = {};

export function MakeString(s?: string, ...__args: any[]) {
    if (s && len(s) > 0) {
        if (truthy(__args) && select("#", __args) > 0) {
            if (truthy(find(s, "%%%.%d")) || truthy(find(s, "%%[%w]"))) {
                s = format(s, ...tostringall(...__args));
            } else {
                s = strjoin(" ", s, ...tostringall(...__args));
            }
        } else {
            return s;
        }
    } else {
        s = tostring(undefined);
    }
    return s;
}

export function Print(...__args: any[]) {
    let s = MakeString(...__args);
    DEFAULT_CHAT_FRAME.AddMessage(format("|cff33ff99Ovale|r: %s", s));
}

export function OneTimeMessage(...__args: any[]) {
    let s = MakeString(...__args);
    if (!oneTimeMessages[s]) {
        oneTimeMessages[s] = true;
    }
}

export function ClearOneTimeMessages() {
    wipe(oneTimeMessages);
}

export function PrintOneTimeMessages() {
    for (const [s] of pairs(oneTimeMessages)) {
        if (oneTimeMessages[s] != "printed") {
            Print(s);
            oneTimeMessages[s] = "printed";
        }
    }
}

export type AceEventHandler<E> = E extends (
    x: UIFrame,
    ...args: infer P
) => infer R
    ? (...args: P) => R
    : never;
