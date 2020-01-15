import { LuaArray, tonumber, setmetatable, rawset, type, tostring, pairs, lualength, truthy } from "@wowts/lua";
import { format, gsub, upper, lower, match } from "@wowts/string";
import { Annotation } from "./definitions";
import { OvalePool } from "../Pool";
import { concat } from "@wowts/table";

export let INDENT: LuaArray<string> = {}
{
    INDENT[0] = "";
    let metatable = {
        __index: function (tbl: LuaArray<string>, key: string) {
            const _key = tonumber(key);
            if (_key > 0) {
                let s = `${tbl[_key - 1]}\t`;
                rawset(tbl, key, s);
                return s;
            }
            return INDENT[0];
        }
    }
    setmetatable(INDENT, metatable);
}


export function print_r( data: any ) {
    let buffer: string = ""
    let padder: string = "  "
    let max: number = 10
    
    function _repeat(str: string, num: number) {
        let output: string = ""
        for (let i = 0; i < num; i += 1) {
            output = output + str;
        }
        return output;
    }
    
    function _dumpvar(d: any, depth: number) {
        if (depth > max) return
        
        let t = type(d)
        let str = d !== undefined && tostring(d) || ""
        if (t == "table") {
            buffer = buffer + format(" (%s) {\n", str)
            for (const [k, v] of pairs(d)) {
                buffer = buffer + format(" %s [%s] =>", _repeat(padder, depth+1), k)
                _dumpvar(v, depth+1)
            }
            buffer = buffer + format(" %s }\n", _repeat(padder, depth))
        }
        else if (t == "number") {
            buffer = buffer + format(" (%s) %d\n", t, str)
        }
        else {
            buffer = buffer + format(" (%s) %s\n", t, str)
        }
    }
    
    _dumpvar(data, 0)
    return buffer
}

export const self_outputPool = new OvalePool<LuaArray<string>>("OvaleSimulationCraft_outputPool");

function CamelCaseHelper(first: string, rest: string) {
    return `${upper(first)}${lower(rest)}`;
}

export function CamelCase(s: string) {
    let tc = gsub(s, "(%a)(%w*)", CamelCaseHelper);
    return gsub(tc, "[%s_]", "");
}

export function CamelSpecialization(annotation: Annotation) {
    let output = self_outputPool.Get();
    let [profileName, className, specialization] = [annotation.name, annotation.classId, annotation.specialization];
    if (specialization) {
        output[lualength(output) + 1] = specialization;
    }
    if (truthy(match(profileName, "_1[hH]_"))) {
        if (className == "DEATHKNIGHT" && specialization == "frost") {
            output[lualength(output) + 1] = "dual wield";
        } else if (className == "WARRIOR" && specialization == "fury") {
            output[lualength(output) + 1] = "single minded fury";
        }
    } else if (truthy(match(profileName, "_2[hH]_"))) {
        if (className == "DEATHKNIGHT" && specialization == "frost") {
            output[lualength(output) + 1] = "two hander";
        } else if (className == "WARRIOR" && specialization == "fury") {
            output[lualength(output) + 1] = "titans grip";
        }
    } else if (truthy(match(profileName, "_[gG]ladiator_"))) {
        output[lualength(output) + 1] = "gladiator";
    }
    let outputString = CamelCase(concat(output, " "));
    self_outputPool.Release(output);
    return outputString;
}


export function OvaleFunctionName(name: string, annotation: Annotation) {
    let functionName = CamelCase(`${name} actions`);
    if (annotation.specialization) {
        functionName = `${CamelSpecialization(annotation)}${functionName}`;
    }
    return functionName;
}


export function OvaleTaggedFunctionName(name: string, tag: string): [string?, string?] {
    let bodyName, conditionName;
    let [prefix, suffix] = match(name, "([A-Z]%w+)(Actions)");
    if (prefix && suffix) {
        let camelTag;
        if (tag == "shortcd") {
            camelTag = "ShortCd";
        } else {
            camelTag = CamelCase(tag);
        }
        bodyName = `${prefix}${camelTag}${suffix}`;
        conditionName = `${prefix}${camelTag}PostConditions`;
    }
    return [bodyName, conditionName];
}