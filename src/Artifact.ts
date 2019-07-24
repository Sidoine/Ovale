import { OvaleDebugClass } from "./Debug";
import { L } from "./Localization";
import { sort, insert, concat } from "@wowts/table";
import { pairs, ipairs, wipe, tostring, lualength, LuaObj, LuaArray } from "@wowts/lua";

let tsort = sort;
let tinsert = insert;
let tconcat = concat;

interface Trait {
    name?: string;
    spellID: string;
    currentRank?: number;
}

export class OvaleArtifactClass {
    self_traits: LuaObj<Trait> = {}

    debugOptions = {
        artifacttraits: {
            name: L["Artifact traits"],
            type: "group",
            args: {
                artifacttraits: {
                    name: L["Artifact traits"],
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: () => {
                        return this.DebugTraits();
                    }
                }
            }
        }
    }    


    constructor(ovaleDebug: OvaleDebugClass) {
        for (const [k, v] of pairs(this.debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }
    }

    OnInitialize() {
    }
    OnDisable() {
    }
    UpdateTraits() {
        return;
    }
    HasTrait() {
        return false;
    }
    TraitRank() {
        return 0;
    }
    output: LuaArray<string> = {}
    DebugTraits() {
        wipe(this.output);
        let array: LuaArray<string> = {}
        for (const [k, v] of pairs(this.self_traits)) {
            tinsert(array, `${tostring(v.name)}: ${tostring(k)}`);
        }
        tsort(array);
        for (const [, v] of ipairs(array)) {
            this.output[lualength(this.output) + 1] = v;
        }
        return tconcat(this.output, "\n");
    }
}
