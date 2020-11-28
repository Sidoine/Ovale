import { OvaleClass } from "../Ovale";
import { States, StateModule } from "../engine/State";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { ipairs, LuaArray, wipe } from "@wowts/lua";
import { GetRuneCooldown, GetTime } from "@wowts/wow-mock";
import { huge } from "@wowts/math";
import { sort } from "@wowts/table";
import { SpellCast, PaperDollSnapshot } from "./LastSpell";
import { AceModule } from "@wowts/tsaddon";
import { Tracer, OvaleDebugClass } from "../engine/Debug";
import { Profiler, OvaleProfilerClass } from "../engine/Profiler";
import { OvaleDataClass } from "../engine/Data";
import { OvalePowerClass } from "./Power";
import { OvalePaperDollClass } from "./PaperDoll";

const EMPOWER_RUNE_WEAPON = 47568;
const RUNE_SLOTS = 6;

interface Rune {
    startCooldown: number;
    endCooldown: number;
}

const IsActiveRune = function (rune: Rune, atTime: number) {
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
        ovaleDebug: OvaleDebugClass,
        ovaleProfiler: OvaleProfilerClass,
        private ovaleData: OvaleDataClass,
        private ovalePower: OvalePowerClass,
        private ovalePaperDoll: OvalePaperDollClass
    ) {
        super(RuneData);
        this.module = ovale.createModule(
            "OvaleRunes",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
        this.profiler = ovaleProfiler.create(this.module.GetName());
    }

    private OnInitialize = () => {
        if (this.ovale.playerClass == "DEATHKNIGHT") {
            for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
                this.current.rune[slot] = { endCooldown: 0, startCooldown: 0 };
            }
            this.module.RegisterEvent(
                "PLAYER_ENTERING_WORLD",
                this.UpdateAllRunes
            );
            this.module.RegisterEvent(
                "RUNE_POWER_UPDATE",
                this.RUNE_POWER_UPDATE
            );
            this.module.RegisterEvent(
                "UNIT_RANGEDDAMAGE",
                this.UNIT_RANGEDDAMAGE
            );
            this.module.RegisterEvent(
                "UNIT_SPELL_HASTE",
                this.UNIT_RANGEDDAMAGE
            );
            if (this.ovale.playerGUID) this.UpdateAllRunes();
        }
    };
    private OnDisable = () => {
        if (this.ovale.playerClass == "DEATHKNIGHT") {
            this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
            this.module.UnregisterEvent("RUNE_POWER_UPDATE");
            this.module.UnregisterEvent("UNIT_RANGEDDAMAGE");
            this.module.UnregisterEvent("UNIT_SPELL_HASTE");
            this.current.rune = {};
        }
    };
    private RUNE_POWER_UPDATE = (
        event: string,
        slot: number,
        usable: boolean
    ) => {
        this.tracer.Debug(event, slot, usable);
        this.UpdateRune(slot);
    };
    // private RUNE_TYPE_UPDATE = (event: string, slot: number) => {
    //     this.tracer.Debug(event, slot);
    //     this.UpdateRune(slot);
    // }
    private UNIT_RANGEDDAMAGE = (event: string, unitId: string) => {
        if (unitId == "player") {
            this.tracer.Debug(event);
            this.UpdateAllRunes();
        }
    };
    UpdateRune(slot: number) {
        this.profiler.StartProfiling("OvaleRunes_UpdateRune");
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
            this.tracer.Debug(
                "Warning: rune information for slot %d not available.",
                slot
            );
        }
        this.profiler.StopProfiling("OvaleRunes_UpdateRune");
    }
    private UpdateAllRunes = () => {
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            this.UpdateRune(slot);
        }
    };
    DebugRunes() {
        const now = GetTime();
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            const rune = this.current.rune[slot];
            if (IsActiveRune(rune, now)) {
                this.tracer.Print("rune[%d] is active.", slot);
            } else {
                this.tracer.Print(
                    "rune[%d] comes off cooldown in %f seconds.",
                    slot,
                    rune.endCooldown - now
                );
            }
        }
    }

    InitializeState() {
        this.next.rune = {};
        for (const [slot] of ipairs(this.current.rune)) {
            this.next.rune[slot] = { endCooldown: 0, startCooldown: 0 };
        }
    }
    ResetState() {
        this.profiler.StartProfiling("OvaleRunes_ResetState");
        for (const [slot, rune] of ipairs(this.current.rune)) {
            const stateRune = this.next.rune[slot];
            stateRune.endCooldown = rune.endCooldown;
            stateRune.startCooldown = rune.startCooldown;
        }
        this.profiler.StopProfiling("OvaleRunes_ResetState");
    }
    CleanState() {
        for (const [slot, rune] of ipairs(this.next.rune)) {
            wipe(rune);
            delete this.next.rune[slot];
        }
    }
    ApplySpellStartCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.StartProfiling("OvaleRunes_ApplySpellStartCast");
        if (isChanneled) {
            this.ApplyRuneCost(spellId, startCast, spellcast);
        }
        this.profiler.StopProfiling("OvaleRunes_ApplySpellStartCast");
    };
    ApplySpellAfterCast = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        isChanneled: boolean,
        spellcast: SpellCast
    ) => {
        this.profiler.StartProfiling("OvaleRunes_ApplySpellAfterCast");
        if (!isChanneled) {
            this.ApplyRuneCost(spellId, endCast, spellcast);
            if (spellId == EMPOWER_RUNE_WEAPON) {
                for (const [slot] of ipairs(this.next.rune)) {
                    this.ReactivateRune(slot, endCast);
                }
            }
        }
        this.profiler.StopProfiling("OvaleRunes_ApplySpellAfterCast");
    };

    ApplyRuneCost(spellId: number, atTime: number, spellcast: SpellCast) {
        const si = this.ovaleData.spellInfo[spellId];
        if (si) {
            let count = si.runes || 0;
            while (count > 0) {
                this.ConsumeRune(spellId, atTime, spellcast);
                count = count - 1;
            }
        }
    }
    ReactivateRune(slot: number, atTime: number) {
        const rune = this.next.rune[slot];
        if (rune.startCooldown > atTime) {
            rune.startCooldown = atTime;
        }
        rune.endCooldown = atTime;
    }
    ConsumeRune(spellId: number, atTime: number, snapshot: PaperDollSnapshot) {
        this.profiler.StartProfiling("OvaleRunes_state_ConsumeRune");
        let consumedRune: Rune | undefined;
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            const rune = this.next.rune[slot];
            if (IsActiveRune(rune, atTime)) {
                consumedRune = rune;
                break;
            }
        }
        if (consumedRune) {
            let start = atTime;
            for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
                const rune = this.next.rune[slot];
                if (rune.endCooldown > start) {
                    start = rune.endCooldown;
                }
            }
            const duration =
                10 /
                this.ovalePaperDoll.GetSpellCastSpeedPercentMultiplier(
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

        this.profiler.StopProfiling("OvaleRunes_state_ConsumeRune");
    }
    RuneCount(atTime: number) {
        this.profiler.StartProfiling("OvaleRunes_state_RuneCount");
        const state = this.GetState(atTime);
        let count = 0;
        let [startCooldown, endCooldown] = [huge, huge];
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            const rune = state.rune[slot];
            if (IsActiveRune(rune, atTime)) {
                count = count + 1;
            } else if (rune.endCooldown < endCooldown) {
                [startCooldown, endCooldown] = [
                    rune.startCooldown,
                    rune.endCooldown,
                ];
            }
        }
        this.profiler.StopProfiling("OvaleRunes_state_RuneCount");
        return [count, startCooldown, endCooldown];
    }

    RuneDeficit(atTime: number) {
        this.profiler.StartProfiling("OvaleRunes_state_RuneDeficit");
        const state = this.GetState(atTime);
        let count = 0;
        let [startCooldown, endCooldown] = [huge, huge];
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            const rune = state.rune[slot];
            if (!IsActiveRune(rune, atTime)) {
                count = count + 1;
                if (rune.endCooldown < endCooldown) {
                    [startCooldown, endCooldown] = [
                        rune.startCooldown,
                        rune.endCooldown,
                    ];
                }
            }
        }
        this.profiler.StopProfiling("OvaleRunes_state_RuneDeficit");
        return [count, startCooldown, endCooldown];
    }

    GetRunesCooldown(atTime: number, runes: number) {
        if (runes <= 0) {
            return 0;
        }
        if (runes > RUNE_SLOTS) {
            this.tracer.Log(
                "Attempt to read %d runes but the maximum is %d",
                runes,
                RUNE_SLOTS
            );
            return 0;
        }
        const state = this.GetState(atTime);
        this.profiler.StartProfiling("OvaleRunes_state_GetRunesCooldown");
        for (let slot = 1; slot <= RUNE_SLOTS; slot += 1) {
            const rune = state.rune[slot];
            usedRune[slot] = rune.endCooldown - atTime;
        }
        sort(usedRune);
        this.profiler.StopProfiling("OvaleRunes_state_GetRunesCooldown");
        return usedRune[runes];
    }
}
