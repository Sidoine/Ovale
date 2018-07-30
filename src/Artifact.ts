import { OvaleDebug } from "./Debug";
import { L } from "./Localization";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
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

let OvaleArtifactBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleArtifact", aceEvent));
class OvaleArtifactClass extends OvaleArtifactBase {
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
                    get: (info: LuaArray<string>) => {
                        return this.DebugTraits();
                    }
                }
            }
        }
    }    

    constructor() {
        super();
        for (const [k, v] of pairs(this.debugOptions)) {
            OvaleDebug.options.args[k] = v;
        }
    }

    OnInitialize() {
    }
    OnDisable() {
    }
    UpdateTraits(message: string) {
        return;
    }
    HasTrait(spellId: number) {
        return false;
    }
    TraitRank(spellId: number) {
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

export const OvaleArtifact = new OvaleArtifactClass();