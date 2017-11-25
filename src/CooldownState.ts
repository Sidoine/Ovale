import { StateModule, OvaleState } from "./State";
import { OvaleCooldown } from "./Cooldown";
import { pairs } from "@wowts/lua";
import { SpellCast } from "./LastSpell";


class CooldownState implements StateModule {
    next = OvaleCooldown.next;
    ApplySpellStartCast(spellId, targetGUID, startCast, endCast, isChanneled, spellcast: SpellCast) {
        OvaleCooldown.StartProfiling("OvaleCooldown_ApplySpellStartCast");
        if (isChanneled) {
            this.ApplyCooldown(spellId, targetGUID, startCast);
        }
        OvaleCooldown.StopProfiling("OvaleCooldown_ApplySpellStartCast");
    }
    ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, isChanneled, spellcast: SpellCast) {
        OvaleCooldown.StartProfiling("OvaleCooldown_ApplySpellAfterCast");
        if (!isChanneled) {
            this.ApplyCooldown(spellId, targetGUID, endCast);
        }
        OvaleCooldown.StopProfiling("OvaleCooldown_ApplySpellAfterCast");
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
            for (const [k] of pairs(cd)) {
                cd[k] = undefined;
            }
            this.next.cd[spellId] = undefined;
        }
    }

    ApplyCooldown(spellId, targetGUID, atTime) {
        OvaleCooldown.StartProfiling("OvaleCooldown_state_ApplyCooldown");
        let cd = OvaleCooldown.GetCD(spellId, atTime);
        let duration = OvaleCooldown.GetSpellCooldownDuration(spellId, atTime, targetGUID);
        if (duration == 0) {
            cd.start = 0;
            cd.duration = 0;
            cd.enable = 1;
        } else {
            cd.start = atTime;
            cd.duration = duration;
            cd.enable = 1;
        }
        if (cd.charges && cd.charges > 0) {
            cd.chargeStart = cd.start;
            cd.charges = cd.charges - 1;
            if (cd.charges == 0) {
                cd.duration = cd.chargeDuration;
            }
        }
        OvaleCooldown.Log("Spell %d cooldown info: start=%f, duration=%f, charges=%s", spellId, cd.start, cd.duration, cd.charges || "(nil)");
        OvaleCooldown.StopProfiling("OvaleCooldown_state_ApplyCooldown");
    }
    DebugCooldown() {
        for (const [spellId, cd] of pairs(this.next.cd)) {
            if (cd.start) {
                if (cd.charges) {
                    OvaleCooldown.Print("Spell %s cooldown: start=%f, duration=%f, charges=%d, maxCharges=%d, chargeStart=%f, chargeDuration=%f", spellId, cd.start, cd.duration, cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration);
                } else {
                    OvaleCooldown.Print("Spell %s cooldown: start=%f, duration=%f", spellId, cd.start, cd.duration);
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


export const cooldownState = new CooldownState();
OvaleState.RegisterState(cooldownState);
