import { StateModule, OvaleState } from "./State";
import { CheckRequirements } from "./Requirement";
import { OvaleData } from "./Data";


export class DataState implements StateModule {
    CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {
    }
    CheckRequirements(spellId, atTime, tokens, index, targetGUID) {
        return CheckRequirements(spellId, atTime, tokens, index, targetGUID);
    }

    CheckSpellAuraData(auraId, spellData, atTime, guid) {
        return OvaleData.CheckSpellAuraData(auraId, spellData, atTime, guid);
    }
    CheckSpellInfo(spellId, atTime, targetGUID) {
        return OvaleData.CheckSpellInfo(spellId, atTime, targetGUID);
    }
    GetItemInfoProperty(itemId, atTime, property) {
        return OvaleData.GetItemInfoProperty(itemId, atTime, property);
    }
    GetSpellInfoProperty(spellId, atTime, property, targetGUID?) {
        return OvaleData.GetSpellInfoProperty(spellId, atTime, property, targetGUID);
    }    
}

export const dataState = new DataState();

OvaleState.RegisterState(dataState);