import { huge as INFINITY } from "@wowts/math";
import { kpairs } from "@wowts/lua";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    GetSpellCount,
    IsSpellInRange,
    IsUsableItem,
    IsUsableSpell,
    UnitIsFriend,
} from "@wowts/wow-mock";
import { isNumber } from "../tools/tools";
import { OvaleSpellBookClass } from "./SpellBook";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { Tracer, OvaleDebugClass } from "../engine/debug";
import { OvaleProfilerClass, Profiler } from "../engine/profiler";
import { OvaleDataClass } from "../engine/data";
import { StateModule } from "../engine/state";
import { NamedParametersOf, AstActionNode } from "../engine/ast";
import { OvalePowerClass, PowerType } from "./Power";

const WARRIOR_INCERCEPT_SPELLID = 198304;
const WARRIOR_HEROICTHROW_SPELLID = 57755;

export class OvaleSpellsClass implements StateModule {
    private module: AceModule & AceEvent;
    private tracer: Tracer;
    private profiler: Profiler;

    constructor(
        private OvaleSpellBook: OvaleSpellBookClass,
        ovale: OvaleClass,
        ovaleDebug: OvaleDebugClass,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleData: OvaleDataClass,
        private power: OvalePowerClass
    ) {
        this.module = ovale.createModule(
            "OvaleSpells",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
        this.profiler = ovaleProfiler.create(this.module.GetName());
    }

    private OnInitialize = (): void => {};
    private OnDisable = (): void => {};
    GetCastTime(spellId: number): number | undefined {
        if (spellId) {
            let [name, , , castTime] = this.OvaleSpellBook.GetSpellInfo(
                spellId
            );
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
        const [index, bookType] = this.OvaleSpellBook.GetSpellBookIndex(
            spellId
        );
        if (index && bookType) {
            const spellCount = GetSpellCount(index, bookType);
            this.tracer.Debug(
                "GetSpellCount: index=%s bookType=%s for spellId=%s ==> spellCount=%s",
                index,
                bookType,
                spellId,
                spellCount
            );
            return spellCount;
        } else {
            const spellName = this.OvaleSpellBook.GetSpellName(spellId);
            if (spellName) {
                const spellCount = GetSpellCount(spellName);
                this.tracer.Debug(
                    "GetSpellCount: spellName=%s for spellId=%s ==> spellCount=%s",
                    spellName,
                    spellId,
                    spellCount
                );
                return spellCount;
            }
            return 0;
        }
    }

    IsSpellInRange(spellId: number, unitId: string): boolean | undefined {
        const [index, bookType] = this.OvaleSpellBook.GetSpellBookIndex(
            spellId
        );
        let returnValue;
        if (index && bookType) {
            returnValue = IsSpellInRange(index, bookType, unitId);
        } else if (this.OvaleSpellBook.IsKnownSpell(spellId)) {
            const name = this.OvaleSpellBook.GetSpellName(spellId);
            if (name) returnValue = IsSpellInRange(name, unitId);
        }
        if (returnValue == 1 && spellId == WARRIOR_INCERCEPT_SPELLID) {
            return (
                UnitIsFriend("player", unitId) ||
                this.IsSpellInRange(WARRIOR_HEROICTHROW_SPELLID, unitId)
            );
        }
        if (returnValue === 1) return true;
        if (returnValue === 0) return false;
        return undefined;
    }

    CleanState(): void {}
    InitializeState(): void {}
    ResetState(): void {}
    IsUsableItem(itemId: number, atTime: number): boolean {
        this.profiler.StartProfiling("OvaleSpellBook_state_IsUsableItem");
        let isUsable = IsUsableItem(itemId);
        const ii = this.ovaleData.ItemInfo(itemId);
        if (ii) {
            if (isUsable) {
                const unusable = this.ovaleData.GetItemInfoProperty(
                    itemId,
                    atTime,
                    "unusable"
                );
                if (unusable && unusable > 0) {
                    this.tracer.Log(
                        "Item ID '%s' is flagged as unusable.",
                        itemId
                    );
                    isUsable = false;
                }
            }
        }
        this.profiler.StopProfiling("OvaleSpellBook_state_IsUsableItem");
        return isUsable;
    }
    IsUsableSpell(
        spellId: number,
        atTime: number,
        targetGUID: string | undefined
    ): [boolean, boolean] {
        this.profiler.StartProfiling("OvaleSpellBook_state_IsUsableSpell");
        let [isUsable, noMana] = [true, false]
        let isKnown = this.OvaleSpellBook.IsKnownSpell(spellId);
        if (!isKnown) {
            // check the WOW API if the spell is usable, if it is than we assume that it is a known spell
            [isUsable, noMana] = IsUsableSpell(spellId); 
            isKnown = isUsable;
            this.tracer.Log("Checked WoW API for spell %s. Returns [%s, %s]", spellId, isUsable, noMana);
        }
        const si = this.ovaleData.spellInfo[spellId];
        if (si && isKnown) {
            this.tracer.Log(
                "Found spell info about %s (isKnown = %s)",
                spellId,
                isKnown
            );

            const unusable = this.ovaleData.GetSpellInfoProperty(
                spellId,
                atTime,
                "unusable",
                targetGUID
            );
            if (unusable !== undefined && unusable > 0) {
                this.tracer.Log(
                    "Spell ID '%s' is flagged as unusable.",
                    spellId
                );
                isUsable = false;
            }
            if (isUsable) {
                const seconds = this.TimeToPowerForSpell(
                    spellId,
                    atTime,
                    targetGUID,
                    undefined
                );
                noMana = (seconds > 0);
                if (noMana) {
                    isUsable = false;
                    this.tracer.Log(
                        "Spell ID '%s' does not have enough power.",
                        spellId
                    );
                } else {
                    this.tracer.Log(
                        "Spell ID '%s' passed power requirements.",
                        spellId
                    );
                }
            }
        } 
        this.profiler.StopProfiling("OvaleSpellBook_state_IsUsableSpell");
        return [isUsable, noMana];
    }

    TimeToPowerForSpell(
        spellId: number,
        atTime: number,
        targetGUID: string | undefined,
        powerType: PowerType | undefined,
        extraPower?: NamedParametersOf<AstActionNode>
    ): number {
        let timeToPower = 0;
        const si = this.ovaleData.spellInfo[spellId];
        if (si) {
            for (const [, powerInfo] of kpairs(this.power.POWER_INFO)) {
                const pType = powerInfo.type;
                if (powerType == undefined || powerType == pType) {
                    let [cost] = this.power.PowerCost(
                        spellId,
                        pType,
                        atTime,
                        targetGUID
                    );
                    if (cost > 0) {
                        if (extraPower) {
                            let extraAmount;
                            if (pType == "energy") {
                                extraAmount = extraPower.extra_energy;
                            } else if (pType == "focus") {
                                extraAmount = extraPower.extra_focus;
                            }
                            if (isNumber(extraAmount)) {
                                this.tracer.Log(
                                    "    Spell ID '%d' has cost of %d (+%d) %s",
                                    spellId,
                                    cost,
                                    extraAmount,
                                    pType
                                );
                                cost = cost + <number>extraAmount;
                            }
                        } else {
                            this.tracer.Log(
                                "    Spell ID '%d' has cost of %d %s",
                                spellId,
                                cost,
                                pType
                            );
                        }
                        const seconds = this.power.getTimeToPowerAt(
                            this.power.next,
                            cost,
                            pType,
                            atTime
                        );
                        this.tracer.Log(
                            "    Spell ID '%d' requires %f seconds to %d %s",
                            spellId,
                            seconds,
                            cost,
                            pType
                        );
                        if (timeToPower < seconds) {
                            timeToPower = seconds;
                        }
                        if (timeToPower === INFINITY) break;
                    }
                }
            }
        }
        this.tracer.Log(
            "Spell ID '%d' requires %f seconds for power requirements.",
            spellId,
            timeToPower
        );
        return timeToPower;
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
