import { OvaleDebug } from "./Debug";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { LuaObj, LuaArray, pairs, tostring, lualength, ipairs } from "@wowts/lua";
import { sort, insert, concat } from "@wowts/table";
import { C_AzeriteEssence } from "@wowts/wow-mock";

let tsort = sort;
let tinsert = insert;
let tconcat = concat;

interface Essence {
    name?: string;
    ID: number;
    rank: number,
    slot: number,
}

let OvaleAzeriteEssenceBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleAzeriteEssence", aceEvent));

class OvaleAzeriteEssenceClass extends OvaleAzeriteEssenceBase {
    self_essences: LuaObj<Essence> = {}

    debugOptions = {
        azeraitessences: {
            name: "Azerite essences",
            type: "group",
            args: {
                azeraitessences: {
                    name: "Azerite essences",
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: (info: LuaArray<string>) => {
                        return this.DebugEssences();
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
        this.RegisterEvent("AZERITE_ESSENCE_CHANGED", "UpdateEssences")
        this.RegisterEvent("AZERITE_ESSENCE_UPDATE", "UpdateEssences")
        this.RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateEssences")
    }
    
    OnDisable() {
        this.UnregisterEvent("AZERITE_ESSENCE_CHANGED")
        this.UnregisterEvent("AZERITE_ESSENCE_UPDATE")
        this.UnregisterEvent("PLAYER_ENTERING_WORLD")
    }
    
    UpdateEssences(e: string) {
        this.Debug("UpdateEssences after event %s", e);
        this.self_essences = {};
        for(const [,mileStoneInfo] of pairs(C_AzeriteEssence.GetMilestones() || {})) {
            if(mileStoneInfo.ID && mileStoneInfo.unlocked && mileStoneInfo.slot !== undefined) {
                let essenceId = C_AzeriteEssence.GetMilestoneEssence(mileStoneInfo.ID)
                if(essenceId) {
                    let essenceInfo = C_AzeriteEssence.GetEssenceInfo(essenceId)
                    
                    let essenceData = {
                        ID: essenceId,
                        name: essenceInfo.name,
                        rank: essenceInfo.rank,
                        slot: mileStoneInfo.slot,
                    }
                    this.self_essences[essenceId] = essenceData;
                    this.Debug("Found essence {ID: %d, name: %s, rank: %d, slot: %d}", essenceData.ID, essenceData.name, essenceData.rank, essenceData.slot);
                }
            }
        }
    }

    IsMajorEssence(essenceId: number) {
        let essence = this.self_essences[essenceId];
        if (essence)
        {
            return essence.slot == 0 && true || false;
        }
        return false;
    }
    
    IsMinorEssence(essenceId: number) {
        return this.self_essences[essenceId] !== undefined && true || false;
    }

    DebugEssences(){
        let output: LuaArray<string> = {};
        let array: LuaArray<string> = {}
        for (const [k, v] of pairs(this.self_essences)) {
            tinsert(array, `${tostring(v.name)}: ${tostring(k)} (slot:${v.slot} | rank:${v.rank})`);
        }
        tsort(array);
        for (const [, v] of ipairs(array)) {
            output[lualength(output) + 1] = v;
        }
        return tconcat(output, "\n");
    }
}
export const OvaleAzeriteEssence = new OvaleAzeriteEssenceClass();