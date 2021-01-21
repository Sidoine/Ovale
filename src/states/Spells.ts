import { huge as INFINITY } from "@wowts/math";
import { kpairs, tonumber } from "@wowts/lua";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    GetSpellCount,
    IsSpellInRange,
    IsUsableItem,
    IsUsableSpell,
    SpellId,
    UnitIsFriend,
} from "@wowts/wow-mock";
import { isNumber } from "../tools/tools";
import { OvaleSpellBookClass } from "./SpellBook";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { Tracer, DebugTools } from "../engine/debug";
import { OvaleProfilerClass, Profiler } from "../engine/profiler";
import { OvaleDataClass } from "../engine/data";
import { StateModule } from "../engine/state";
import { NamedParametersOf, AstActionNode } from "../engine/ast";
import { OvalePowerClass, PowerType } from "./Power";
import { OvaleRunesClass } from "./Runes";

const warriorInterceptSpellId = SpellId.intercept;
const warriorHeroicThrowSpellId = SpellId.heroic_throw;

export class OvaleSpellsClass implements StateModule {
    private module: AceModule & AceEvent;
    private tracer: Tracer;
    private profiler: Profiler;

    constructor(
        private spellBook: OvaleSpellBookClass,
        ovale: OvaleClass,
        ovaleDebug: DebugTools,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleData: OvaleDataClass,
        private power: OvalePowerClass,
        private runes: OvaleRunesClass
    ) {
        this.module = ovale.createModule(
            "OvaleSpells",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
        this.profiler = ovaleProfiler.create(this.module.GetName());
    }

    private handleInitialize = (): void => {};
    private handleDisable = (): void => {};
    getCastTime(spellId: number): number | undefined {
        if (spellId) {
            let [name, , , castTime] = this.spellBook.getSpellInfo(spellId);
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

    getSpellCount(spellId: number): number {
        const [index, bookType] = this.spellBook.getSpellBookIndex(spellId);
        if (index && bookType) {
            const spellCount = GetSpellCount(index, bookType);
            this.tracer.debug(
                "GetSpellCount: index=%s bookType=%s for spellId=%s ==> spellCount=%s",
                index,
                bookType,
                spellId,
                spellCount
            );
            return spellCount;
        } else {
            const spellName = this.spellBook.getSpellName(spellId);
            if (spellName) {
                const spellCount = GetSpellCount(spellName);
                this.tracer.debug(
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

    isSpellInRange(spellId: number, unitId: string): boolean | undefined {
        const [index, bookType] = this.spellBook.getSpellBookIndex(spellId);
        let returnValue;
        if (index && bookType) {
            returnValue = IsSpellInRange(index, bookType, unitId);
        } else if (this.spellBook.isKnownSpell(spellId)) {
            const name = this.spellBook.getSpellName(spellId);
            if (name) returnValue = IsSpellInRange(name, unitId);
        }
        if (returnValue == 1 && spellId == warriorInterceptSpellId) {
            return (
                UnitIsFriend("player", unitId) ||
                this.isSpellInRange(warriorHeroicThrowSpellId, unitId)
            );
        }
        if (returnValue === 1) return true;
        if (returnValue === 0) return false;
        return undefined;
    }

    cleanState(): void {}
    initializeState(): void {}
    resetState(): void {}
    isUsableItem(itemId: number, atTime: number): boolean {
        this.profiler.startProfiling("OvaleSpellBook_state_IsUsableItem");
        let isUsable = IsUsableItem(itemId);
        const ii = this.ovaleData.getItemInfo(itemId);
        if (ii) {
            if (isUsable) {
                const unusable = this.ovaleData.getItemInfoProperty(
                    itemId,
                    atTime,
                    "unusable"
                );
                if (unusable && unusable > 0) {
                    this.tracer.log(
                        "Item ID '%s' is flagged as unusable.",
                        itemId
                    );
                    isUsable = false;
                }
            }
        }
        this.profiler.stopProfiling("OvaleSpellBook_state_IsUsableItem");
        return isUsable;
    }
    isUsableSpell(
        spellId: number,
        atTime: number,
        targetGUID: string | undefined
    ): [boolean, boolean] {
        this.profiler.startProfiling("OvaleSpellBook_state_IsUsableSpell");
        let [isUsable, noMana] = [false, false];
        const isKnown = this.spellBook.isKnownSpell(spellId);
        const si = this.ovaleData.spellInfo[spellId];
        if (!isKnown) {
            this.tracer.log("Spell ID '%s' is not known.", spellId);
            [isUsable, noMana] = [false, false];
        } else if (si !== undefined) {
            const unusable = this.ovaleData.getSpellInfoProperty(
                spellId,
                atTime,
                "unusable",
                targetGUID
            );
            if (unusable !== undefined && tonumber(unusable) > 0) {
                this.tracer.log(
                    "Spell ID '%s' is flagged as unusable.",
                    spellId
                );
                [isUsable, noMana] = [false, false];
            } else {
                const seconds = this.timeToPowerForSpell(
                    spellId,
                    atTime,
                    targetGUID,
                    undefined
                );
                if (seconds > 0) {
                    this.tracer.log(
                        "Spell ID '%s' does not have enough power.",
                        spellId
                    );
                    [isUsable, noMana] = [false, true];
                } else {
                    this.tracer.log(
                        "Spell ID '%s' meets power requirements.",
                        spellId
                    );
                    [isUsable, noMana] = [true, false];
                }
            }
        } else {
            [isUsable, noMana] = IsUsableSpell(spellId);
        }
        this.profiler.stopProfiling("OvaleSpellBook_state_IsUsableSpell");
        return [isUsable, noMana];
    }

    timeToPowerForSpell(
        spellId: number,
        atTime: number,
        targetGUID: string | undefined,
        powerType: PowerType | undefined,
        extraPower?: NamedParametersOf<AstActionNode>
    ): number {
        let timeToPower = 0;
        const si = this.ovaleData.spellInfo[spellId];
        if (si) {
            for (const [, powerInfo] of kpairs(this.power.powerInfos)) {
                const pType = powerInfo.type;
                if (powerType == undefined || powerType == pType) {
                    let [cost] = this.power.powerCost(
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
                                this.tracer.log(
                                    "    Spell ID '%d' has cost of %d (+%d) %s",
                                    spellId,
                                    cost,
                                    extraAmount,
                                    pType
                                );
                                cost = cost + <number>extraAmount;
                            }
                        } else {
                            this.tracer.log(
                                "    spell ID '%d' has cost of %d %s",
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
                        this.tracer.log(
                            "    spell ID '%d' requires %f seconds for %d %s",
                            spellId,
                            seconds,
                            cost,
                            pType
                        );
                        if (timeToPower < seconds) {
                            timeToPower = seconds;
                        }
                        if (timeToPower == INFINITY) {
                            this.tracer.log(
                                "    short-circuiting checks for other power requirements"
                            );
                            break;
                        }
                    }
                }
            }
            if (timeToPower != INFINITY) {
                // Check runes, implemented as a separate module.
                const runes = this.ovaleData.getSpellInfoProperty(
                    spellId,
                    atTime,
                    "runes",
                    targetGUID
                );
                if (runes) {
                    const seconds = this.runes.getRunesCooldown(
                        atTime,
                        <number>runes
                    );
                    this.tracer.log(
                        "    spell ID '%d' requires %f seconds for %d runes",
                        spellId,
                        seconds,
                        runes
                    );
                    if (timeToPower < seconds) {
                        timeToPower = seconds;
                    }
                }
            }
        }
        this.tracer.log(
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
