import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaObj, LuaArray, pairs, tostring, lualength, ipairs } from "@wowts/lua";
import { sort, insert, concat } from "@wowts/table";
import { C_AzeriteEssence } from "@wowts/wow-mock";
import { OvaleClass } from "./Ovale";
import { AceModule } from "@wowts/tsaddon";
import { OvaleDebugClass, Tracer } from "./Debug";

interface Essence {
    name?: string;
    ID: number;
    rank: number,
    slot: number,
}


export class OvaleAzeriteEssenceClass {
    self_essences: LuaObj<Essence> = {}

    private debugOptions = {
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
    };

    private module: AceModule & AceEvent;
    private tracer: Tracer;

    constructor(ovale: OvaleClass, ovaleDebug: OvaleDebugClass) {
        this.module = ovale.createModule("OvaleAzeriteEssence", this.OnInitialize, this.OnDisable, aceEvent);
        this.tracer = ovaleDebug.create("OvaleAzeriteEssence");
        for (const [k, v] of pairs(this.debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }
    }
    
    private OnInitialize = () => {
        this.module.RegisterEvent("AZERITE_ESSENCE_CHANGED", this.UpdateEssences);
        this.module.RegisterEvent("AZERITE_ESSENCE_UPDATE", this.UpdateEssences);
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.UpdateEssences);
    }
    
    private OnDisable = () => {
        this.module.UnregisterEvent("AZERITE_ESSENCE_CHANGED");
        this.module.UnregisterEvent("AZERITE_ESSENCE_UPDATE");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
    }
    
    private UpdateEssences = (e: string) => {
        this.tracer.Debug("UpdateEssences after event %s", e);
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
                    this.tracer.Debug("Found essence {ID: %d, name: %s, rank: %d, slot: %d}", essenceData.ID, essenceData.name, essenceData.rank, essenceData.slot);
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
    
    EssenceRank(essenceId: number) {
        let essence = this.self_essences[essenceId];
        return essence !== undefined && essence.rank || 0;
    }

    DebugEssences(){
        let output: LuaArray<string> = {};
        let array: LuaArray<string> = {}
        for (const [k, v] of pairs(this.self_essences)) {
            insert(array, `${tostring(v.name)}: ${tostring(k)} (slot:${v.slot} | rank:${v.rank})`);
        }
        sort(array);
        for (const [, v] of ipairs(array)) {
            output[lualength(output) + 1] = v;
        }
        return concat(output, "\n");
    }
}