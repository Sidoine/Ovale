import { Ovale } from "./Ovale";
import { OvaleDebug } from "./Debug";
import { OvaleState, StateModule } from "./State";
import aceEvent from "@wowts/ace_event-3.0";
import { insert } from "@wowts/table";
import { GetTime, GetSpellCount } from "@wowts/wow-mock";
import { LuaArray, type, pairs } from "@wowts/lua";


let OvaleDemonHunterSoulFragmentsBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleDemonHunterSoulFragments", aceEvent));
export let OvaleDemonHunterSoulFragments: OvaleDemonHunterSoulFragmentsClass;

let SOUL_FRAGMENTS_BUFF_ID = 228477;
let SOUL_FRAGMENTS_SPELL_HEAL_ID = 203794;
let SOUL_FRAGMENTS_SPELL_CAST_SUCCESS_ID = 204255;
let SOUL_FRAGMENT_FINISHERS = {
    [228477]: true,
    [247454]: true,
    [227225]: true
}

interface SoulFragments {
    timestamp: number;
    fragments: number;
}

class OvaleDemonHunterSoulFragmentsClass extends OvaleDemonHunterSoulFragmentsBase {
    last_checked: number;
    soul_fragments: LuaArray<SoulFragments>;
    last_soul_fragment_count:SoulFragments;

    constructor() {
        super();
        this.SetCurrentSoulFragments(0);
    
        if (Ovale.playerClass == "DEMONHUNTER") {
            this.RegisterEvent("PLAYER_REGEN_ENABLED");
            this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
            this.RegisterEvent("PLAYER_REGEN_DISABLED");
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "DEMONHUNTER") {
            this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
            this.UnregisterEvent("PLAYER_REGEN_ENABLED");
            this.UnregisterEvent("PLAYER_REGEN_DISABLED");
        }
    }
    PLAYER_REGEN_ENABLED() {
        this.SetCurrentSoulFragments();
    }
    PLAYER_REGEN_DISABLED() {
        this.soul_fragments = {
        }
        this.last_checked = undefined;
        this.SetCurrentSoulFragments();
    }

    COMBAT_LOG_EVENT_UNFILTERED(event, _2, subtype, _4, sourceGUID, _6, _7, _8, _9, _10, _11, _12, spellID, spellName) {
        let me = Ovale.playerGUID;
        if (sourceGUID == me) {
            //let current_sould_fragment_count = this.last_soul_fragment_count;
            if (subtype == "SPELL_HEAL" && spellID == SOUL_FRAGMENTS_SPELL_HEAL_ID) {
                this.SetCurrentSoulFragments(this.last_soul_fragment_count.fragments - 1);
            }
            if (subtype == "SPELL_CAST_SUCCESS" && spellID == SOUL_FRAGMENTS_SPELL_CAST_SUCCESS_ID) {
                this.SetCurrentSoulFragments(this.last_soul_fragment_count.fragments + 1);
            }
            if (subtype == "SPELL_CAST_SUCCESS" && SOUL_FRAGMENT_FINISHERS[spellID]) {
                this.SetCurrentSoulFragments(0);
            }
            let now = GetTime();
            if (this.last_checked == undefined || now - this.last_checked >= 1.5) {
                this.SetCurrentSoulFragments();
            }
        }
    }
    SetCurrentSoulFragments(count?) {
        let now = GetTime();
        this.last_checked = now;
        this.soul_fragments = this.soul_fragments || {
        }
        if (type(count) != "number") {
            count = GetSpellCount(SOUL_FRAGMENTS_BUFF_ID) || 0;
        }
        if (count < 0) {
            count = 0;
        }
        if (this.last_soul_fragment_count == undefined || this.last_soul_fragment_count.fragments != count) {
            let entry:SoulFragments = {
                timestamp: now,
                fragments: count
            }
            this.Debug("Setting current soul fragment count to '%d' (at: %s)", entry.fragments, entry.timestamp);
            this.last_soul_fragment_count = entry;
            insert(this.soul_fragments, entry);
        }
    }
    DebugSoulFragments() {
    }
}

class DemonHunterSoulFragmentsState implements StateModule {
    CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {
    }
    SoulFragments(atTime: number) {
        let currentTime:number = undefined;
        let count: number = undefined;
        for (const [, v] of pairs(OvaleDemonHunterSoulFragments.soul_fragments)) {
            if (v.timestamp >= atTime && (currentTime == undefined || v.timestamp < currentTime)) {
                currentTime = v.timestamp;
                count = v.fragments;
            }
        }
        if (count) return count;
        return (OvaleDemonHunterSoulFragments.last_soul_fragment_count != undefined && OvaleDemonHunterSoulFragments.last_soul_fragment_count.fragments) || 0;
    }

}

export const demonHunterSoulFragmentsState = new DemonHunterSoulFragmentsState();
OvaleState.RegisterState(demonHunterSoulFragmentsState);
