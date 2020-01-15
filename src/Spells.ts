import { Tokens, OvaleRequirement } from "./Requirement";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { tonumber } from "@wowts/lua";
import { GetSpellCount, IsSpellInRange, IsUsableItem, IsUsableSpell, UnitIsFriend } from "@wowts/wow-mock";
import { OvaleSpellBookClass } from "./SpellBook";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "./Ovale";
import { Tracer, OvaleDebugClass } from "./Debug";
import { OvaleProfilerClass, Profiler } from "./Profiler";
import { OvaleDataClass } from "./Data";
import { PRIMARY_POWER, PowerType } from "./Power";
import { StateModule } from "./State";

let WARRIOR_INCERCEPT_SPELLID = 198304;
let WARRIOR_HEROICTHROW_SPELLID = 57755;

export class OvaleSpellsClass implements StateModule {
    private module: AceModule & AceEvent;
    private tracer: Tracer;
    private profiler: Profiler;

    constructor(private OvaleSpellBook: OvaleSpellBookClass, private ovale: OvaleClass, ovaleDebug: OvaleDebugClass, ovaleProfiler: OvaleProfilerClass, private ovaleData: OvaleDataClass, private requirement: OvaleRequirement) {
        this.module = ovale.createModule("OvaleSpells", this.OnInitialize, this.OnDisable, aceEvent);
        this.tracer = ovaleDebug.create(this.module.GetName());
        this.profiler = ovaleProfiler.create(this.module.GetName());
    }

    private OnInitialize = (): void => {
        this.requirement.RegisterRequirement("spellcount_min", this.RequireSpellCountHandler);
        this.requirement.RegisterRequirement("spellcount_max", this.RequireSpellCountHandler);
    }
    private OnDisable = (): void => {
        this.requirement.UnregisterRequirement("spellcount_max");
        this.requirement.UnregisterRequirement("spellcount_min");
    }
    GetCastTime(spellId: number): number | undefined {
        if (spellId) {
            let [name, , , castTime] = this.OvaleSpellBook.GetSpellInfo(spellId);
            if (name) {
                if (castTime) {
                    castTime = castTime / 1000;
                } else {
                    castTime = 0;
                }
            } else {
                return undefined;
            }
            return castTime;
        }
    }

    GetSpellCount(spellId: number): number {
        let [index, bookType] = this.OvaleSpellBook.GetSpellBookIndex(spellId);
        if (index && bookType) {
            let spellCount = GetSpellCount(index, bookType);
            this.tracer.Debug("GetSpellCount: index=%s bookType=%s for spellId=%s ==> spellCount=%s", index, bookType, spellId, spellCount);
            return spellCount;
        } else {
            let spellName = this.OvaleSpellBook.GetSpellName(spellId);
            if (spellName) {
                let spellCount = GetSpellCount(spellName);
                this.tracer.Debug("GetSpellCount: spellName=%s for spellId=%s ==> spellCount=%s", spellName, spellId, spellCount);
                return spellCount;
            }
            return 0;
        }
    }

    IsSpellInRange(spellId: number, unitId: string): boolean | undefined {
        let [index, bookType] = this.OvaleSpellBook.GetSpellBookIndex(spellId);
        let returnValue;
        if (index && bookType) {
            returnValue = IsSpellInRange(index, bookType, unitId);
        } else if (this.OvaleSpellBook.IsKnownSpell(spellId)) {
            let name = this.OvaleSpellBook.GetSpellName(spellId);
            if (name) returnValue = IsSpellInRange(name, unitId);
        }
        if ((returnValue == 1 && spellId == WARRIOR_INCERCEPT_SPELLID)) {
            return (UnitIsFriend("player", unitId) || this.IsSpellInRange(WARRIOR_HEROICTHROW_SPELLID, unitId));
        }
        return (returnValue == 1 && true) || (returnValue == 0 && false) || (returnValue === undefined && undefined);
    }
    
    private RequireSpellCountHandler = (spellId: number, atTime: number, requirement: string, tokens: Tokens, index: number, targetGUID: string):[boolean, string, number] => {
        let verified = false;
        let countString;
        if (index) {
            countString = <string>tokens[index];
            index = index + 1;
        }
        if (countString) {
            let count = tonumber(countString) || 1;
            let actualCount = this.GetSpellCount(spellId);
            verified = (requirement == "spellcount_min" && count <= actualCount) || (requirement == "spellcount_max" && count >= actualCount);
        } else {
            this.ovale.OneTimeMessage("Warning: requirement '%s' is missing a count argument.", requirement);
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
        this.profiler.StartProfiling("OvaleSpellBook_state_IsUsableItem");
        let isUsable = IsUsableItem(itemId);
        let ii = this.ovaleData.ItemInfo(itemId);
        if (ii) {
            if (isUsable) {
                let unusable = this.ovaleData.GetItemInfoProperty(itemId, atTime, "unusable");
                if (unusable && unusable > 0) {
                    this.tracer.Log("Item ID '%s' is flagged as unusable.", itemId);
                    isUsable = false;
                }
            }
        }
        this.profiler.StopProfiling("OvaleSpellBook_state_IsUsableItem");
        return isUsable;
    }
    IsUsableSpell(spellId: number, atTime: number, targetGUID: string): [boolean, boolean] {
        this.profiler.StartProfiling("OvaleSpellBook_state_IsUsableSpell");
        let isUsable = this.OvaleSpellBook.IsKnownSpell(spellId);
        let noMana = false;
        let si = this.ovaleData.spellInfo[spellId];
        let requirement: string;
        if (si) {
            if (isUsable) {
                let unusable = this.ovaleData.GetSpellInfoProperty(spellId, atTime, "unusable", targetGUID);
                if (unusable && unusable > 0) {
                    this.tracer.Log("Spell ID '%s' is flagged as unusable.", spellId);
                    isUsable = false;
                }
            }
            if (isUsable) {
                [isUsable, requirement] = this.ovaleData.CheckSpellInfo(spellId, atTime, targetGUID);
                if (!isUsable) {
                    noMana = PRIMARY_POWER[requirement as PowerType] || false;
                    if (noMana) {
                        this.tracer.Log("Spell ID '%s' does not have enough %s.", spellId, requirement);
                    } else {
                        this.tracer.Log("Spell ID '%s' failed '%s' requirements.", spellId, requirement);
                    }
                }
            }
        } else {
            let [index, bookType] = this.OvaleSpellBook.GetSpellBookIndex(spellId);
            if (index && bookType) {
                return IsUsableSpell(index, bookType);
            } else if (this.OvaleSpellBook.IsKnownSpell(spellId)) {
                let name = this.OvaleSpellBook.GetSpellName(spellId);
                if (!name) return [false, false];
                return IsUsableSpell(name);
            }
        }
        this.profiler.StopProfiling("OvaleSpellBook_state_IsUsableSpell");
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
