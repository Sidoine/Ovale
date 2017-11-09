import { StateModule, baseState, OvaleState } from "./State";
import { OvaleSpellBook } from "./SpellBook";
import { OvaleData } from "./Data";
import { dataState } from "./DataState";
import { OvalePower, powerState } from "./Power";
import { cooldownState } from "./CooldownState";
import { runesState } from "./Runes";
import { type } from "@wowts/lua";
import { IsUsableItem } from "@wowts/wow-mock";

class SpellBookState implements StateModule {
    CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {
    }

    IsUsableItem(itemId, atTime?) {
        OvaleSpellBook.StartProfiling("OvaleSpellBook_state_IsUsableItem");
        let isUsable = IsUsableItem(itemId);
        let ii = OvaleData.ItemInfo(itemId);
        if (ii) {
            if (isUsable) {
                let unusable = dataState.GetItemInfoProperty(itemId, atTime, "unusable");
                if (unusable && unusable > 0) {
                    OvaleSpellBook.Log("Item ID '%s' is flagged as unusable.", itemId);
                    isUsable = false;
                }
            }
        }
        OvaleSpellBook.StopProfiling("OvaleSpellBook_state_IsUsableItem");
        return isUsable;
    }
    IsUsableSpell(spellId, atTime, targetGUID) {
        OvaleSpellBook.StartProfiling("OvaleSpellBook_state_IsUsableSpell");
        if (type(atTime) == "string" && !targetGUID) {
            [atTime, targetGUID] = [undefined, atTime];
        }
        atTime = atTime || baseState.currentTime;
        let isUsable = OvaleSpellBook.IsKnownSpell(spellId);
        let noMana = false;
        let si = OvaleData.spellInfo[spellId];
        if (si) {
            if (isUsable) {
                let unusable = dataState.GetSpellInfoProperty(spellId, atTime, "unusable", targetGUID);
                if (unusable && unusable > 0) {
                    OvaleSpellBook.Log("Spell ID '%s' is flagged as unusable.", spellId);
                    isUsable = false;
                }
            }
            if (isUsable) {
                let requirement;
                [isUsable, requirement] = dataState.CheckSpellInfo(spellId, atTime, targetGUID);
                if (!isUsable) {
                    if (OvalePower.PRIMARY_POWER[requirement]) {
                        noMana = true;
                    }
                    if (noMana) {
                        OvaleSpellBook.Log("Spell ID '%s' does not have enough %s.", spellId, requirement);
                    } else {
                        OvaleSpellBook.Log("Spell ID '%s' failed '%s' requirements.", spellId, requirement);
                    }
                }
            }
        } else {
            [isUsable, noMana] = OvaleSpellBook.IsUsableSpell(spellId);
        }
        OvaleSpellBook.StopProfiling("OvaleSpellBook_state_IsUsableSpell");
        return [isUsable, noMana];
    }
    GetTimeToSpell(spellId, atTime, targetGUID, extraPower?) {
        if (type(atTime) == "string" && !targetGUID) {
            [atTime, targetGUID] = [undefined, atTime];
        }
        atTime = atTime || baseState.currentTime;
        let timeToSpell = 0;
        {
            let [start, duration] = cooldownState.GetSpellCooldown(spellId);
            let seconds = (duration > 0) && (start + duration - atTime) || 0;
            if (timeToSpell < seconds) {
                timeToSpell = seconds;
            }
        }
        {
            let seconds = powerState.TimeToPower(spellId, atTime, targetGUID, undefined, extraPower);
            if (timeToSpell < seconds) {
                timeToSpell = seconds;
            }
        }
        {
            let runes = dataState.GetSpellInfoProperty(spellId, atTime, "runes", targetGUID);
            if (runes) {
                let seconds = runesState.GetRunesCooldown(atTime, runes);
                if (timeToSpell < seconds) {
                    timeToSpell = seconds;
                }
            }
        }
        return timeToSpell;
    }
    RequireSpellCountHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        return OvaleSpellBook.RequireSpellCountHandler(spellId, atTime, requirement, tokens, index, targetGUID);
    }
}

export const spellBookState = new SpellBookState();
OvaleState.RegisterState(spellBookState);
