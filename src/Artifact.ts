import { GetArtifactTraits, RegisterCallback, UnregisterCallback } from "@wowts/lib_artifact_data-1.0";
import { OvaleDebug } from "./Debug";
import { L } from "./Localization";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { sort, insert, concat } from "@wowts/table";
import { pairs, ipairs, wipe, tostring, lualength } from "@wowts/lua";

let tsort = sort;
let tinsert = insert;
let tconcat = concat;


let OvaleArtifactBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleArtifact", aceEvent));
class OvaleArtifactClass extends OvaleArtifactBase {
    self_traits = {}

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
                    get: (info) => {
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
    
        this.RegisterEvent("SPELLS_CHANGED", (message) => this.UpdateTraits(message));
        RegisterCallback(this, "ARTIFACT_ADDED", message => this.UpdateTraits(message));
        RegisterCallback(this, "ARTIFACT_EQUIPPED_CHANGED", m => this.UpdateTraits(m));
        RegisterCallback(this, "ARTIFACT_ACTIVE_CHANGED", m => this.UpdateTraits(m));
        RegisterCallback(this, "ARTIFACT_TRAITS_CHANGED", m => this.UpdateTraits(m));
    }
    OnDisable() {
        UnregisterCallback(this, "ARTIFACT_ADDED");
        UnregisterCallback(this, "ARTIFACT_EQUIPPED_CHANGED");
        UnregisterCallback(this, "ARTIFACT_ACTIVE_CHANGED");
        UnregisterCallback(this, "ARTIFACT_TRAITS_CHANGED");
        this.UnregisterEvent("SPELLS_CHANGED");
    }
    UpdateTraits(message) {
        let [, traits] = GetArtifactTraits();
        this.self_traits = {}
        if (!traits) {
            return;
        }
        for (const [, v] of ipairs(traits)) {
            this.self_traits[v.spellID] = v;
        }
    }
    HasTrait(spellId) {
        return this.self_traits[spellId] && this.self_traits[spellId].currentRank;
    }
    TraitRank(spellId) {
        if (!this.self_traits[spellId]) {
            return 0;
        }
        return this.self_traits[spellId].currentRank;
    }
    output = {}
    DebugTraits() {
        wipe(this.output);
        let array = {
        }
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