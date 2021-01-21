import { OvaleClass } from "../Ovale";
import { States, StateModule } from "../engine/state";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { ipairs, LuaArray, wipe } from "@wowts/lua";
import { GetRuneCooldown, GetTime } from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { sort } from "@wowts/table";
import { SpellCast, PaperDollSnapshot } from "./LastSpell";
import { AceModule } from "@wowts/tsaddon";
import { Tracer, DebugTools } from "../engine/debug";
import { Profiler, OvaleProfilerClass } from "../engine/profiler";
import { OvaleDataClass } from "../engine/data";
import { OvalePowerClass } from "./Power";
import { OvalePaperDollClass } from "./PaperDoll";

const empowerRuneWeapon = 47568;
const runeSlots = 6;

interface Rune {
    startCooldown: number;
    endCooldown: number;
}

const isActiveRune = function (rune: Rune, atTime: number) {
    return rune.startCooldown == 0 || rune.endCooldown <= atTime;
};

class RuneData {
    rune: LuaArray<Rune> = {};
}

const usedRune: LuaArray<number> = {};

export class OvaleRunesClass extends States<RuneData> implements StateModule {
    private module: AceModule & AceEvent;
    private profiler: Profiler;
    private tracer: Tracer;
    constructor(
        private ovale: OvaleClass,
        ovaleDebug: DebugTools,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleData: OvaleDataClass,
        private ovalePower: OvalePowerClass,
        private ovalePaperDoll: OvalePaperDollClass
    ) {
        super(RuneData);
        this.module = ovale.createModule(
            "OvaleRunes",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
        this.profiler = ovaleProfiler.create(this.module.GetName());
    }

    private handleInitialize = () => {
        if (this.ovale.playerClass == "DEATHKNIGHT") {
            for (let slot = 1; slot <= runeSlots; slot += 1) {
                this.current.rune[slot] = { endCooldown: 0, startCooldown: 0 };
            }
            this.module.RegisterEvent(
                "PLAYER_ENTERING_WORLD",
                this.handleUpdateAllRunes
            );
            this.module.RegisterEvent(
                "RUNE_POWER_UPDATE",
                this.handleRunePowerUpdate
            );
            this.module.RegisterEvent(
                "UNIT_RANGEDDAMAGE",
                this.handleUnitRangedDamage
            );
            this.module.RegisterEvent(
                "UNIT_SPELL_HASTE",
                this.handleUnitRangedDamage
            );
            if (this.ovale.playerGUID) this.handleUpdateAllRunes();
        }
    };
    private handleDisable = () => {
        if (this.ovale.playerClass == "DEATHKNIGHT") {
            this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
            this.module.UnregisterEvent("RUNE_POWER_UPDATE");
            this.module.UnregisterEvent("UNIT_RANGEDDAMAGE");
            this.module.UnregisterEvent("UNIT_SPELL_HASTE");
            this.current.rune = {};
        }
    };
    private handleRunePowerUpdate = (
        event: string,
        slot: number,
        usable: boolean
    ) => {
        this.tracer.debug(event, slot, usable);
        this.updateRune(slot);
    };
    // private RUNE_TYPE_UPDATE = (event: string, slot: number) => {
    //     this.tracer.Debug(event, slot);
    //     this.UpdateRune(slot);
    // }
    private handleUnitRangedDamage = (event: string, unitId: string) => {
        if (unitId == "player") {
            this.tracer.debug(event);
            this.handleUpdateAllRunes();
        }
    };
    updateRune(slot: number) {
        this.profiler.startProfiling("OvaleRunes_UpdateRune");
        const rune = this.current.rune[slot];
        const [start, duration] = GetRuneCooldown(slot);
        if (start && duration) {
            if (start > 0) {
                rune.startCooldown = start;
                rune.endCooldown = start + duration;
            } else {
                rune.startCooldown = 0;
                rune.endCooldown = 0;
            }
            this.ovale.needRefresh();
        } else {
            this.tracer.debug(
                "Warning: rune information for slot %d not available.",
                slot
            );
        }
        this.profiler.stopProfiling("OvaleRunes_UpdateRune");
    }
    private handleUpdateAllRunes = () => {
        for (let slot = 1; slot <= runeSlots; slot += 1) {
            this.updateRune(slot);
        }
    };
    debugRunes() {
        const now = GetTime();
        for (let slot = 1; slot <= runeSlots; slot += 1) {
            const rune = this.current.rune[slot];
            if (isActiveRune(rune, now)) {
                this.tracer.print("rune[%d] is active.", slot);
            } else {
                this.tracer.print(
                    "rune[%d] comes off cooldown in %f seconds.",
                    slot,
                    rune.endCooldown - now
                );
            }
        }
    }

    initializeState() {
        this.next.rune = {};
        for (const [slot] of ipairs(this.current.rune)) {
            this.next.rune[slot] = { endCooldown: 0, startCooldown: 0 };
        }
    }
    resetState() {
        this.profiler.startProfiling("OvaleRunes_ResetState");
        for (const [slot, rune] of ipairs(this.current.rune)) {
            const stateRune = this.next.rune[slot];
            stateRune.endCooldown = rune.endCooldown;
            stateRune.startCooldown = rune.startCooldown;
        }
        this.profiler.stopProfiling("OvaleRunes_ResetState");
    }
    cleanState() {
        for (const [slot, rune] of ipairs(this.next.rune)) {
            wipe(rune);
            delete this.next.rune[slot];
        }
    }
    applySpellStartCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.startProfiling("OvaleRunes_ApplySpellStartCast");
        if (isChanneled) {
            this.applyRuneCost(spellId, startCast, spellcast);
        }
        this.profiler.stopProfiling("OvaleRunes_ApplySpellStartCast");
    };
    applySpellAfterCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.startProfiling("OvaleRunes_ApplySpellAfterCast");
        if (!isChanneled) {
            this.applyRuneCost(spellId, endCast, spellcast);
            if (spellId == empowerRuneWeapon) {
                for (const [slot] of ipairs(this.next.rune)) {
                    this.reactivateRune(slot, endCast);
                }
            }
        }
        this.profiler.stopProfiling("OvaleRunes_ApplySpellAfterCast");
    };

    applyRuneCost(spellId: number, atTime: number, spellcast: SpellCast) {
        const si = this.ovaleData.spellInfo[spellId];
        if (si) {
            let count = si.runes || 0;
            while (count > 0) {
                this.consumeRune(spellId, atTime, spellcast);
                count = count - 1;
            }
        }
    }
    reactivateRune(slot: number, atTime: number) {
        const rune = this.next.rune[slot];
        if (rune.startCooldown > atTime) {
            rune.startCooldown = atTime;
        }
        rune.endCooldown = atTime;
    }
    consumeRune(spellId: number, atTime: number, snapshot: PaperDollSnapshot) {
        this.profiler.startProfiling("OvaleRunes_state_ConsumeRune");
        let consumedRune: Rune | undefined;
        for (let slot = 1; slot <= runeSlots; slot += 1) {
            const rune = this.next.rune[slot];
            if (isActiveRune(rune, atTime)) {
                consumedRune = rune;
                break;
            }
        }
        if (consumedRune) {
            let start = atTime;
            for (let slot = 1; slot <= runeSlots; slot += 1) {
                const rune = this.next.rune[slot];
                if (rune.endCooldown > start) {
                    start = rune.endCooldown;
                }
            }
            const duration =
                10 /
                this.ovalePaperDoll.getSpellCastSpeedPercentMultiplier(
                    snapshot
                );
            consumedRune.startCooldown = start;
            consumedRune.endCooldown = start + duration;
            const runicpower =
                (this.ovalePower.next.power.runicpower || 0) + 10;
            const maxi = this.ovalePower.current.maxPower.runicpower;
            this.ovalePower.next.power.runicpower =
                (runicpower < maxi && runicpower) || maxi;
        }

        this.profiler.stopProfiling("OvaleRunes_state_ConsumeRune");
    }
    runeCount(atTime: number) {
        this.profiler.startProfiling("OvaleRunes_state_RuneCount");
        const state = this.getState(atTime);
        let count = 0;
        let [startCooldown, endCooldown] = [huge, huge];
        for (let slot = 1; slot <= runeSlots; slot += 1) {
            const rune = state.rune[slot];
            if (isActiveRune(rune, atTime)) {
                count = count + 1;
            } else if (rune.endCooldown < endCooldown) {
                [startCooldown, endCooldown] = [
                    rune.startCooldown,
                    rune.endCooldown,
                ];
            }
        }
        this.profiler.stopProfiling("OvaleRunes_state_RuneCount");
        return [count, startCooldown, endCooldown];
    }

    runeDeficit(atTime: number) {
        this.profiler.startProfiling("OvaleRunes_state_RuneDeficit");
        const state = this.getState(atTime);
        let count = 0;
        let [startCooldown, endCooldown] = [huge, huge];
        for (let slot = 1; slot <= runeSlots; slot += 1) {
            const rune = state.rune[slot];
            if (!isActiveRune(rune, atTime)) {
                count = count + 1;
                if (rune.endCooldown < endCooldown) {
                    [startCooldown, endCooldown] = [
                        rune.startCooldown,
                        rune.endCooldown,
                    ];
                }
            }
        }
        this.profiler.stopProfiling("OvaleRunes_state_RuneDeficit");
        return [count, startCooldown, endCooldown];
    }

    getRunesCooldown(atTime: number, runes: number) {
        if (runes <= 0) {
            return 0;
        }
        if (runes > runeSlots) {
            this.tracer.log(
                "Attempt to read %d runes but the maximum is %d",
                runes,
                runeSlots
            );
            return 0;
        }
        const state = this.getState(atTime);
        this.profiler.startProfiling("OvaleRunes_state_GetRunesCooldown");
        for (let slot = 1; slot <= runeSlots; slot += 1) {
            const rune = state.rune[slot];
            if (isActiveRune(rune, atTime)) {
                usedRune[slot] = 0;
            } else {
                usedRune[slot] = rune.endCooldown - atTime;
            }
        }
        sort(usedRune);
        this.profiler.stopProfiling("OvaleRunes_state_GetRunesCooldown");
        return usedRune[runes];
    }
}
