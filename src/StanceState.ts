import { StateModule, OvaleState } from "./State";
import { OvaleStance } from "./Stance";
import { dataState } from "./DataState";
import { type } from "@wowts/lua";

class StanceState implements StateModule {
    stance = undefined;
    InitializeState() {
        this.stance = undefined;
    }
    CleanState(): void {
    }
    ResetState() {
        OvaleStance.StartProfiling("OvaleStance_ResetState");
        this.stance = OvaleStance.stance || 0;
        OvaleStance.StopProfiling("OvaleStance_ResetState");
    }
    ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, isChanneled, spellcast) {
        OvaleStance.StartProfiling("OvaleStance_ApplySpellAfterCast");
        let stance = dataState.GetSpellInfoProperty(spellId, endCast, "to_stance", targetGUID);
        if (stance) {
            if (type(stance) == "string") {
                stance = OvaleStance.stanceId[stance];
            }
            this.stance = stance;
        }
        OvaleStance.StopProfiling("OvaleStance_ApplySpellAfterCast");
    }
    IsStance(name) {
        return OvaleStance.IsStance(name);
    } 
    RequireStanceHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        return OvaleStance.RequireStanceHandler(spellId, atTime, requirement, tokens, index, targetGUID);
    }
}

export const stanceState = new StanceState();
OvaleState.RegisterState(stanceState);
