import { StateModule } from "./State";
import { OvaleCooldownClass, CooldownData } from "./Cooldown";
import { pairs, kpairs } from "@wowts/lua";
import { SpellCast } from "./LastSpell";
import { Profiler, OvaleProfilerClass } from "./Profiler";
import { Tracer, OvaleDebugClass } from "./Debug";


export class CooldownState implements StateModule {
    next: CooldownData;
    private profiler: Profiler;
    private tracer: Tracer;

    constructor(private ovaleCooldown: OvaleCooldownClass, ovaleProfiler: OvaleProfilerClass, ovaleDebug: OvaleDebugClass) {
        this.profiler = ovaleProfiler.create("CooldownState");
        this.tracer = ovaleDebug.create("CooldownState");
        this.next = this.ovaleCooldown.next;
    }

    ApplySpellStartCast(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        this.profiler.StartProfiling("OvaleCooldown_ApplySpellStartCast");
        if (isChanneled) {
            this.ApplyCooldown(spellId, targetGUID, startCast);
        }
        this.profiler.StopProfiling("OvaleCooldown_ApplySpellStartCast");
    }
    ApplySpellAfterCast(spellId: number, targetGUID: string, startCast: number, endCast: number, isChanneled: boolean, spellcast: SpellCast) {
        this.profiler.StartProfiling("OvaleCooldown_ApplySpellAfterCast");
        if (!isChanneled) {
            this.ApplyCooldown(spellId, targetGUID, endCast);
        }
        this.profiler.StopProfiling("OvaleCooldown_ApplySpellAfterCast");
    }

    InitializeState() {
        this.next.cd = {}
    }
    ResetState() {
        for (const [, cd] of pairs(this.next.cd)) {
            cd.serial = undefined;
        }
    }
    CleanState() {
        for (const [spellId, cd] of pairs(this.next.cd)) {
            for (const [k] of kpairs(cd)) {
                delete cd[k];
            }
            delete this.next.cd[spellId];
        }
    }

    ApplyCooldown(spellId: number, targetGUID: string, atTime: number) {
        this.profiler.StartProfiling("OvaleCooldown_state_ApplyCooldown");
        let cd = this.ovaleCooldown.GetCD(spellId, atTime);
        let duration = this.ovaleCooldown.GetSpellCooldownDuration(spellId, atTime, targetGUID);
        if (duration == 0) {
            cd.start = 0;
            cd.duration = 0;
            cd.enable = true;
        } else {
            cd.start = atTime;
            cd.duration = duration;
            cd.enable = true;
        }
        if (cd.charges && cd.charges > 0) {
            cd.chargeStart = cd.start;
            cd.charges = cd.charges - 1;
            if (cd.charges == 0) {
                cd.duration = cd.chargeDuration;
            }
        }
        this.tracer.Log("Spell %d cooldown info: start=%f, duration=%f, charges=%s", spellId, cd.start, cd.duration, cd.charges || "(nil)");
        this.profiler.StopProfiling("OvaleCooldown_state_ApplyCooldown");
    }
    DebugCooldown() {
        for (const [spellId, cd] of pairs(this.next.cd)) {
            if (cd.start) {
                if (cd.charges) {
                    this.tracer.Print("Spell %s cooldown: start=%f, duration=%f, charges=%d, maxCharges=%d, chargeStart=%f, chargeDuration=%f", spellId, cd.start, cd.duration, cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration);
                } else {
                    this.tracer.Print("Spell %s cooldown: start=%f, duration=%f", spellId, cd.start, cd.duration);
                }
            }
        }
    }
//    ResetSpellCooldown (spellId, atTime) {
//         let now = atTime;
//         if (atTime >= now) {
//             let cd = this.GetCD(spellId, atTime);
//             if (cd.start + cd.duration > now) {
//                 cd.start = now;
//                 cd.duration = atTime - now;
//             }
//         }
//     }
}

