import { Ovale } from "./Ovale";
import { OvaleDebug } from "./Debug";
import { OvaleState, StateModule } from "./State";
import { OvaleAura } from "./Aura";
import aceEvent from "@wowts/ace_event-3.0";
import { GetTime, CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { LuaArray } from "@wowts/lua";

let OvaleDemonHunterSoulFragmentsBase = OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleDemonHunterSoulFragments", aceEvent));
export let OvaleDemonHunterSoulFragments: OvaleDemonHunterSoulFragmentsClass;

let SOUL_FRAGMENTS_BUFF_ID = 203981;
let SOUL_FRAGMENT_SPELLS:LuaArray<number> = {
    [225919]: 2,    // Fracture
    [203782]: 1,    // Shear
    [228477]: -2,   // Soul Cleave
}
let SOUL_FRAGMENT_FINISHERS:LuaArray<boolean> = {
    [247454]: true,   // Spirit Bomb
    [263648]: true,   // Soul Barrier
}

class OvaleDemonHunterSoulFragmentsClass extends OvaleDemonHunterSoulFragmentsBase {
    estimatedCount: number;
    atTime: number;
    estimated: boolean;

    constructor() {
        super();
    }

    OnInitialize() {
        if (Ovale.playerClass == "DEMONHUNTER") {
            this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "DEMONHUNTER") {
            this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    COMBAT_LOG_EVENT_UNFILTERED(event: string, ...__args: any[]) {
        let [, subtype, , sourceGUID, , , , , , , , spellID] = CombatLogGetCurrentEventInfo();
        let me = Ovale.playerGUID;
        if (sourceGUID == me) {
            if (subtype == "SPELL_CAST_SUCCESS" && SOUL_FRAGMENT_SPELLS[spellID]) {
                this.AddPredictedSoulFragments(GetTime(), SOUL_FRAGMENT_SPELLS[spellID]);
            }
            if (subtype == "SPELL_CAST_SUCCESS" && SOUL_FRAGMENT_FINISHERS[spellID]) {
                this.SetPredictedSoulFragment(GetTime(), 0);
            }
        }
    }
    AddPredictedSoulFragments(atTime: number, added: number) {
        let currentCount = this.GetSoulFragmentsBuffStacks(atTime) || 0;
        this.SetPredictedSoulFragment(atTime, currentCount + added)
    }
    SetPredictedSoulFragment(atTime: number, count: number) {
        this.estimatedCount = (count < 0 && 0) || (count > 5 && 5) || count;
        this.atTime = atTime
        this.estimated = true
    }
    SoulFragments(atTime: number) {
        let stacks = this.GetSoulFragmentsBuffStacks(atTime)
        if (this.estimated) {
            if (atTime - (this.atTime || 0) < 1.2) {
                stacks = this.estimatedCount;
            }
            else {
                this.estimated = false;
            }
        }
        return stacks;
    }
    GetSoulFragmentsBuffStacks(atTime: number) {
        let aura = OvaleAura.GetAura("player", SOUL_FRAGMENTS_BUFF_ID, atTime, "HELPFUL", true);
        let stacks = OvaleAura.IsActiveAura(aura, atTime) && aura.stacks || 0;
        return stacks;
    }
}

class DemonHunterSoulFragmentsState implements StateModule {
    CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {
    }
}

OvaleDemonHunterSoulFragments = new OvaleDemonHunterSoulFragmentsClass();
export const demonHunterSoulFragmentsState = new DemonHunterSoulFragmentsState();
OvaleState.RegisterState(demonHunterSoulFragmentsState);
