import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvalePaperDoll } from "./PaperDoll";
import { OvaleSpellBook } from "./SpellBook";
import { OvaleState } from "./State";
import aceEvent from "@wowts/ace_event-3.0";
import { ipairs, LuaObj, LuaArray, tonumber, lualength } from "@wowts/lua";
import { insert, remove } from "@wowts/table";
import { GetTime } from "@wowts/wow-mock";
import { huge } from "@wowts/math";

let OvaleSigilBase = OvaleProfiler.RegisterProfiling(Ovale.NewModule("OvaleSigil", aceEvent));
export let OvaleSigil: OvaleSigilClass;
let UPDATE_DELAY = 0.5;
let SIGIL_ACTIVATION_TIME = huge;
let activated_sigils: LuaObj<LuaArray<number>> = {
}
let sigil_start = {
    [204513]: {
        type: "flame"
    },
    [204596]: {
        type: "flame"
    },
    [189110]: {
        type: "flame",
        talent: 8
    },
    [202137]: {
        type: "silence"
    },
    [207684]: {
        type: "misery"
    },
    [202138]: {
        type: "chains"
    }
}
let sigil_end = {
    [204598]: {
        type: "flame"
    },
    [204490]: {
        type: "silence"
    },
    [207685]: {
        type: "misery"
    },
    [204834]: {
        type: "chains"
    }
}
let QUICKENED_SIGILS_TALENT = 15;
class OvaleSigilClass extends OvaleSigilBase {
    constructor() {
        super();
        activated_sigils["flame"] = {
        }
        activated_sigils["silence"] = {
        }
        activated_sigils["misery"] = {
        }
        activated_sigils["chains"] = {
        }
    }
    
    OnInitialize() {
        if (Ovale.playerClass == "DEMONHUNTER") {
            this.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "DEMONHUNTER") {
            this.UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
        }
    }

    UNIT_SPELLCAST_SUCCEEDED(event, unitId, spellName, spellRank, guid, spellId, ...__args) {
        if ((!OvalePaperDoll.IsSpecialization("vengeance"))) {
            return;
        }
        if ((unitId == undefined || unitId != "player")) {
            return;
        }
        let id = tonumber(spellId);
        if ((sigil_start[id] != undefined)) {
            let s = sigil_start[id];
            let t = s.type;
            let tal = s.talent || undefined;
            if ((tal == undefined || OvaleSpellBook.GetTalentPoints(tal) > 0)) {
                insert(activated_sigils[t], GetTime());
            }
        }
        if ((sigil_end[id] != undefined)) {
            let s = sigil_end[id];
            let t = s.type;
            remove(activated_sigils[t], 1);
        }
    }
    
    IsSigilCharging(type, atTime: number) {
        if ((lualength(activated_sigils[type]) == 0)) {
            return false;
        }
        let charging = false;
        for (const [, v] of ipairs(activated_sigils[type])) {
            let activation_time = SIGIL_ACTIVATION_TIME + UPDATE_DELAY;
            if ((OvaleSpellBook.GetTalentPoints(QUICKENED_SIGILS_TALENT) > 0)) {
                activation_time = activation_time - 1;
            }
            charging = charging || atTime < v + activation_time;
        }
        return charging;
    }
    CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {
    }
}
OvaleSigil = new OvaleSigilClass();
OvaleState.RegisterState(OvaleSigil);