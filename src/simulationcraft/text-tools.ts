import {
    LuaArray,
    tonumber,
    setmetatable,
    rawset,
    type,
    tostring,
    pairs,
} from "@wowts/lua";
import { format, gsub, upper, lower, match } from "@wowts/string";
import { Annotation } from "./definitions";
import { OvalePool } from "../tools/Pool";

export const indentations: LuaArray<string> = {};
{
    indentations[0] = "";
    const metatable = {
        // eslint-disable-next-line @typescript-eslint/naming-convention
        __index: function (tbl: LuaArray<string>, key: string) {
            const _key = tonumber(key);
            if (_key > 0) {
                const s = `${tbl[_key - 1]}\t`;
                rawset(tbl, key, s);
                return s;
            }
            return indentations[0];
        },
    };
    setmetatable(indentations, metatable);
}

export function printRepeat(data: any) {
    let buffer = "";
    const padder = "  ";
    const max = 10;

    function _repeat(str: string, num: number) {
        let output = "";
        for (let i = 1; i <= num; i += 1) {
            output = output + str;
        }
        return output;
    }

    function _dumpvar(d: any, depth: number) {
        if (depth > max) return;

        const t = type(d);
        const str = (d !== undefined && tostring(d)) || "";
        if (t == "table") {
            buffer = buffer + format(" (%s) {\n", str);
            for (const [k, v] of pairs(d)) {
                buffer =
                    buffer +
                    format(" %s [%s] =>", _repeat(padder, depth + 1), k);
                _dumpvar(v, depth + 1);
            }
            buffer = buffer + format(" %s }\n", _repeat(padder, depth));
        } else if (t == "number") {
            buffer = buffer + format(" (%s) %d\n", t, str);
        } else {
            buffer = buffer + format(" (%s) %s\n", t, str);
        }
    }

    _dumpvar(data, 0);
    return buffer;
}

export const outputPool = new OvalePool<LuaArray<string>>(
    "OvaleSimulationCraft_outputPool"
);

function camelCaseHelper(first: string, rest: string) {
    return `${upper(first)}${lower(rest)}`;
}

export function toCamelCase(s: string) {
    const tc = gsub(s, "(%a)(%w*)", camelCaseHelper);
    return gsub(tc, "[%s_]", "");
}

export function toLowerSpecialization(annotation: Annotation) {
    return lower(annotation.specialization);
}

export function toOvaleFunctionName(name: string, annotation: Annotation) {
    let functionName = lower(`${name}actions`);
    if (annotation.specialization) {
        functionName = `${toLowerSpecialization(annotation)}${functionName}`;
    }
    return functionName;
}

export function toOvaleTaggedFunctionName(
    name: string,
    tag: string
): [string?, string?] {
    let bodyName, conditionName;
    const [prefix, suffix] = match(name, "([a-z]%w+)(actions)$");
    if (prefix && suffix) {
        bodyName = lower(`${prefix}${tag}${suffix}`);
        conditionName = lower(`${prefix}${tag}postconditions`);
    }
    return [bodyName, conditionName];
}
