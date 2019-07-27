import { OvalePaperDollClass } from "./PaperDoll";
import { OvaleSpellBookClass } from "./SpellBook";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { ipairs, LuaObj, LuaArray, tonumber, lualength } from "@wowts/lua";
import { insert, remove } from "@wowts/table";
import { GetTime, CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { OvaleClass } from "./Ovale";
import { AceModule } from "@wowts/tsaddon";
import { StateModule } from "./State";

let UPDATE_DELAY = 0.5;
let SIGIL_ACTIVATION_TIME = 2;
type SigilType = "flame" | "silence" | "misery" | "chains";
let activated_sigils: LuaObj<LuaArray<number>> = {}

interface Sigil {
    type: SigilType;
    talent?: number;
}

let sigil_start: LuaArray<Sigil> = {
    [204513]: {
        type: "flame"
    },
    [204596]: {
        type: "flame"
    },
    [189110]: {
        type: "flame",
        talent: 7
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
let sigil_end: LuaArray<Sigil> = {
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
let QUICKENED_SIGILS_TALENT = 14;
export class OvaleSigilClass implements StateModule {
    private module: AceModule & AceEvent;

    constructor(private ovalePaperDoll: OvalePaperDollClass, private ovale: OvaleClass, private ovaleSpellBook: OvaleSpellBookClass) {
        this.module = ovale.createModule("OvaleSigil", this.OnInitialize, this.OnDisable, aceEvent);
        activated_sigils["flame"] = {};
        activated_sigils["silence"] = {};
        activated_sigils["misery"] = {};
        activated_sigils["chains"] = {};
    }
    
    private OnInitialize = () => {
        if (this.ovale.playerClass == "DEMONHUNTER") {
            this.module.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", this.UNIT_SPELLCAST_SUCCEEDED);
            this.module.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", this.COMBAT_LOG_EVENT_UNFILTERED);
        }
    }
    private OnDisable = () => {
        if (this.ovale.playerClass == "DEMONHUNTER") {
            this.module.UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
            this.module.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }

    private COMBAT_LOG_EVENT_UNFILTERED = (event: string, ...__args: any[]) => {
        if ((!this.ovalePaperDoll.IsSpecialization("vengeance"))) {
            return;
        }
        let [, cleuEvent, , sourceGUID, , , , , , , , spellid] = CombatLogGetCurrentEventInfo();        
        if (sourceGUID == this.ovale.playerGUID && cleuEvent == 'SPELL_AURA_APPLIED') {
            if ((sigil_end[spellid] != undefined)) {
                let s = sigil_end[spellid];
                let t = s.type;
                remove(activated_sigils[t], 1);
            }
        }
    }
    
    private UNIT_SPELLCAST_SUCCEEDED = (event: string, unitId: string, guid: string, spellId: number, ...__args: any[]) => {
        if ((!this.ovalePaperDoll.IsSpecialization("vengeance"))) {
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
            if ((tal == undefined || this.ovaleSpellBook.GetTalentPoints(tal) > 0)) {
                insert(activated_sigils[t], GetTime());
            }
        }
    }

    IsSigilCharging(type: SigilType, atTime: number) {
        if ((lualength(activated_sigils[type]) == 0)) {
            return false;
        }
        let charging = false;
        for (const [, v] of ipairs(activated_sigils[type])) {
            let activation_time = SIGIL_ACTIVATION_TIME + UPDATE_DELAY;
            if ((this.ovaleSpellBook.GetTalentPoints(QUICKENED_SIGILS_TALENT) > 0)) {
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