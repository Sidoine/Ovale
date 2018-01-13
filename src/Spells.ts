import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { RegisterRequirement, UnregisterRequirement, Tokens } from "./Requirement";
import aceEvent from "@wowts/ace_event-3.0";
import { tonumber } from "@wowts/lua";
import { GetSpellCount, IsSpellInRange, IsUsableItem, IsUsableSpell, UnitIsFriend } from "@wowts/wow-mock";
import { OvaleState } from "./State";
import { OvaleData } from "./Data";
import { OvalePower } from "./Power";
// import { OvaleCooldown } from "./Cooldown";
// import { OvaleRunes } from "./Runes";
import { OvaleSpellBook } from "./SpellBook";

let WARRIOR_INCERCEPT_SPELLID = 198304;
let WARRIOR_HEROICTHROW_SPELLID = 57755;

export let OvaleSpells:OvaleSpellsClass;
const OvaleSpellsBase = OvaleProfiler.RegisterProfiling(OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleSpellBook", aceEvent)))
class OvaleSpellsClass extends OvaleSpellsBase {
    OnInitialize(): void {
        RegisterRequirement("spellcount_min", this.RequireSpellCountHandler);
        RegisterRequirement("spellcount_max", this.RequireSpellCountHandler);
    }
    OnDisable(): void {
        UnregisterRequirement("spellcount_max");
        UnregisterRequirement("spellcount_min");
   }
    GetCastTime(spellId: number): number {
        if (spellId) {
            let [name, , , castTime] = OvaleSpellBook.GetSpellInfo(spellId);
            if (name) {
                if (castTime) {
                    castTime = castTime / 1000;
                } else {
                    castTime = 0;
                }
            } else {
                castTime = undefined;
            }
            return castTime;
        }
    }

    GetSpellCount(spellId: number): number {
        let [index, bookType] = OvaleSpellBook.GetSpellBookIndex(spellId);
        if (index && bookType) {
            let spellCount = GetSpellCount(index, bookType);
            this.Debug("GetSpellCount: index=%s bookType=%s for spellId=%s ==> spellCount=%s", index, bookType, spellId, spellCount);
            return spellCount;
        } else {
            let spellName = OvaleSpellBook.GetSpellName(spellId);
            let spellCount = GetSpellCount(spellName);
            this.Debug("GetSpellCount: spellName=%s for spellId=%s ==> spellCount=%s", spellName, spellId, spellCount);
            return spellCount;
        }
    }

    IsSpellInRange(spellId: number, unitId: string): number {
        let [index, bookType] = OvaleSpellBook.GetSpellBookIndex(spellId);
        let returnValue: number = undefined;
        if (index && bookType) {
            returnValue = IsSpellInRange(index, bookType, unitId);
        } else if (OvaleSpellBook.IsKnownSpell(spellId)) {
            let name = OvaleSpellBook.GetSpellName(spellId);
            returnValue = IsSpellInRange(name, unitId);
        }
        if ((returnValue == 1 && spellId == WARRIOR_INCERCEPT_SPELLID)) {
            return (UnitIsFriend("player", unitId) == 1 || OvaleSpells.IsSpellInRange(WARRIOR_HEROICTHROW_SPELLID, unitId) == 1) && 1 || 0;
        }
        return returnValue;
    }
    
    RequireSpellCountHandler = (spellId: number, atTime: number, requirement: string, tokens: Tokens, index: number, targetGUID: string):[boolean, string, number] => {
        let verified = false;
        let countString: string;
        if (index) {
            countString = <string>tokens[index];
            index = index + 1;
        }
        if (countString) {
            let count = tonumber(countString) || 1;
            let actualCount = OvaleSpells.GetSpellCount(spellId);
            verified = (requirement == "spellcount_min" && count <= actualCount) || (requirement == "spellcount_max" && count >= actualCount);
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' is missing a count argument.", requirement);
        }
        return [verified, requirement, index];
    }

    CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {
    }
    IsUsableItem(itemId: number, atTime: number): boolean {
        OvaleSpells.StartProfiling("OvaleSpellBook_state_IsUsableItem");
        let isUsable = IsUsableItem(itemId);
        let ii = OvaleData.ItemInfo(itemId);
        if (ii) {
            if (isUsable) {
                let unusable = OvaleData.GetItemInfoProperty(itemId, atTime, "unusable");
                if (unusable && unusable > 0) {
                    OvaleSpells.Log("Item ID '%s' is flagged as unusable.", itemId);
                    isUsable = false;
                }
            }
        }
        OvaleSpells.StopProfiling("OvaleSpellBook_state_IsUsableItem");
        return isUsable;
    }
    IsUsableSpell(spellId: number, atTime: number, targetGUID: string): [boolean, boolean] {
        OvaleSpells.StartProfiling("OvaleSpellBook_state_IsUsableSpell");
        let isUsable = OvaleSpellBook.IsKnownSpell(spellId);
        let noMana = false;
        let si = OvaleData.spellInfo[spellId];
        if (si) {
            if (isUsable) {
                let unusable = OvaleData.GetSpellInfoProperty(spellId, atTime, "unusable", targetGUID);
                if (unusable && unusable > 0) {
                    OvaleSpells.Log("Spell ID '%s' is flagged as unusable.", spellId);
                    isUsable = false;
                }
            }
            if (isUsable) {
                let requirement;
                [isUsable, requirement] = OvaleData.CheckSpellInfo(spellId, atTime, targetGUID);
                if (!isUsable) {
                    noMana = OvalePower.PRIMARY_POWER[requirement];
                    if (noMana) {
                        OvaleSpells.Log("Spell ID '%s' does not have enough %s.", spellId, requirement);
                    } else {
                        OvaleSpells.Log("Spell ID '%s' failed '%s' requirements.", spellId, requirement);
                    }
                }
            }
        } else {
            let [index, bookType] = OvaleSpellBook.GetSpellBookIndex(spellId);
            if (index && bookType) {
                return IsUsableSpell(index, bookType);
            } else if (OvaleSpellBook.IsKnownSpell(spellId)) {
                let name = OvaleSpellBook.GetSpellName(spellId);
                return IsUsableSpell(name);
            }
        }
        OvaleSpells.StopProfiling("OvaleSpellBook_state_IsUsableSpell");
        return [isUsable, noMana];
    }
    /*
    GetTimeToSpell(spellId: number, atTime: number, targetGUID: string, extraPower?: number) {
        if (type(atTime) == "string" && !targetGUID) {
            [atTime, targetGUID] = [undefined, atTime];
        }
        let timeToSpell = 0;
        {
            let [start, duration] = OvaleCooldown.GetSpellCooldown(spellId, atTime);
            let seconds = (duration > 0) && (start + duration - atTime) || 0;
            if (timeToSpell < seconds) {
                timeToSpell = seconds;
            }
        }
        {
            let seconds = OvalePower.TimeToPower(spellId, atTime, targetGUID, undefined, extraPower);
            if (timeToSpell < seconds) {
                timeToSpell = seconds;
            }
        }
        {
            let runes = OvaleData.GetSpellInfoProperty(spellId, atTime, "runes", targetGUID);
            if (runes) {
                let seconds = OvaleRunes.GetRunesCooldown(atTime, <number>runes);
                if (timeToSpell < seconds) {
                    timeToSpell = seconds;
                }
            }
        }
        return timeToSpell;
    }
    */
}

OvaleSpells = new OvaleSpellsClass();
OvaleState.RegisterState(OvaleSpells);
