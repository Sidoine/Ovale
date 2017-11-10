import { StateModule, baseState, OvaleState } from "./State";
import { OvaleCooldown } from "./Cooldown";
import { dataState } from "./DataState";
import { paperDollState } from "./PaperDoll";
import { Ovale } from "./Ovale";
import { OvaleData } from "./Data";
import { auraState } from "./Aura";
import { GetSpellCharges } from "@wowts/wow-mock";
import { sub } from "@wowts/string";
import { pairs, LuaObj } from "@wowts/lua";
import { SpellCast } from "./LastSpell";

let COOLDOWN_THRESHOLD = 0.10;

interface Cooldown {
    serial?: number;
    start?: number;
    charges?: number;
    duration?: number;
    enable?: number;
    maxCharges?: number;
    chargeStart?: number;
    chargeDuration?: number;
}

class CooldownState implements StateModule {
    cd: LuaObj<Cooldown> = undefined;

    
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

    RequireCooldownHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        let cdSpellId = tokens;
        let verified = false;
        if (index) {
            cdSpellId = tokens[index];
            index = index + 1;
        }
        if (cdSpellId) {
            let isBang = false;
            if (sub(cdSpellId, 1, 1) == "!") {
                isBang = true;
                cdSpellId = sub(cdSpellId, 2);
            }
            let cd = this.GetCD(cdSpellId);
            verified = !isBang && cd.duration > 0 || isBang && cd.duration <= 0;
            let result = verified && "passed" || "FAILED";
            OvaleCooldown.Log("    Require spell %s %s cooldown at time=%f: %s (duration = %f)", cdSpellId, isBang && "OFF" || !isBang && "ON", atTime, result, cd.duration);
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' is missing a spell argument.", requirement);
        }
        return [verified, requirement, index];
    }

    InitializeState() {
        this.cd = {
        }
    }
    ResetState() {
        for (const [, cd] of pairs(this.cd)) {
            cd.serial = undefined;
        }
    }
    CleanState() {
        for (const [spellId, cd] of pairs(this.cd)) {
            for (const [k] of pairs(cd)) {
                cd[k] = undefined;
            }
            this.cd[spellId] = undefined;
        }
    }

    ApplyCooldown(spellId, targetGUID, atTime) {
        OvaleCooldown.StartProfiling("OvaleCooldown_state_ApplyCooldown");
        let cd = this.GetCD(spellId);
        let duration = this.GetSpellCooldownDuration(spellId, atTime, targetGUID);
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
        for (const [spellId, cd] of pairs(this.cd)) {
            if (cd.start) {
                if (cd.charges) {
                    OvaleCooldown.Print("Spell %s cooldown: start=%f, duration=%f, charges=%d, maxCharges=%d, chargeStart=%f, chargeDuration=%f", spellId, cd.start, cd.duration, cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration);
                } else {
                    OvaleCooldown.Print("Spell %s cooldown: start=%f, duration=%f", spellId, cd.start, cd.duration);
                }
            }
        }
    }
    GetCD(spellId) {
        OvaleCooldown.StartProfiling("OvaleCooldown_state_GetCD");
        let cdName = spellId;
        let si = OvaleData.spellInfo[spellId];
        if (si && si.sharedcd) {
            cdName = si.sharedcd;
        }
        if (!this.cd[cdName]) {
            this.cd[cdName] = {
            }
        }
        let cd = this.cd[cdName];
        if (!cd.start || !cd.serial || cd.serial < OvaleCooldown.serial) {
            let [start, duration, enable] = OvaleCooldown.GetSpellCooldown(spellId);
            if (si && si.forcecd) {
                [start, duration] = OvaleCooldown.GetSpellCooldown(si.forcecd);
            }
            cd.serial = OvaleCooldown.serial;
            cd.start = start - COOLDOWN_THRESHOLD;
            cd.duration = duration;
            cd.enable = enable;
            let [charges, maxCharges, chargeStart, chargeDuration] = GetSpellCharges(spellId);
            if (charges) {
                cd.charges = charges;
                cd.maxCharges = maxCharges;
                cd.chargeStart = chargeStart;
                cd.chargeDuration = chargeDuration;
            }
        }
        let now = baseState.currentTime;
        if (cd.start) {
            if (cd.start + cd.duration <= now) {
                cd.start = 0;
                cd.duration = 0;
            }
        }
        if (cd.charges) {
            let [charges, maxCharges, chargeStart, chargeDuration] = [cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration];
            while (chargeStart + chargeDuration <= now && charges < maxCharges) {
                chargeStart = chargeStart + chargeDuration;
                charges = charges + 1;
            }
            cd.charges = charges;
            cd.chargeStart = chargeStart;
        }
        OvaleCooldown.StopProfiling("OvaleCooldown_state_GetCD");
        return cd;
    }
    GetSpellCooldown(spellId) {
        let cd = this.GetCD(spellId);
        return [cd.start, cd.duration, cd.enable];
    }
    GetSpellCooldownDuration(spellId, atTime, targetGUID) {
        let [start, duration] = this.GetSpellCooldown(spellId);
        if (duration > 0 && start + duration > atTime) {
            OvaleCooldown.Log("Spell %d is on cooldown for %fs starting at %s.", spellId, duration, start);
        } else {
            let si = OvaleData.spellInfo[spellId];
            duration = <number>dataState.GetSpellInfoProperty(spellId, atTime, "cd", targetGUID);
            if (duration) {
                if (si && si.addcd) {
                    duration = duration + si.addcd;
                }
                if (duration < 0) {
                    duration = 0;
                }
            } else {
                duration = 0;
            }
            OvaleCooldown.Log("Spell %d has a base cooldown of %fs.", spellId, duration);
            if (duration > 0) {
                let haste = dataState.GetSpellInfoProperty(spellId, atTime, "cd_haste", targetGUID);
                let multiplier = paperDollState.GetHasteMultiplier(haste);
                duration = duration / multiplier;
                if (si && si.buff_cdr) {
                    let aura = auraState.GetAura("player", si.buff_cdr);
                    if (auraState.IsActiveAura(aura, atTime)) {
                        duration = duration * aura.value1;
                    }
                }
            }
        }
        return duration;
    }
    GetSpellCharges(spellId, atTime?) {
        atTime = atTime || baseState.currentTime;
        let cd = this.GetCD(spellId);
        let [charges, maxCharges, chargeStart, chargeDuration] = [cd.charges, cd.maxCharges, cd.chargeStart, cd.chargeDuration];
        if (charges) {
            while (chargeStart + chargeDuration <= atTime && charges < maxCharges) {
                chargeStart = chargeStart + chargeDuration;
                charges = charges + 1;
            }
        }
        return [charges, maxCharges, chargeStart, chargeDuration];
    }
    ResetSpellCooldown (spellId, atTime) {
        let now = baseState.currentTime;
        if (atTime >= now) {
            let cd = this.GetCD(spellId);
            if (cd.start + cd.duration > now) {
                cd.start = now;
                cd.duration = atTime - now;
            }
        }
    }
}


export const cooldownState = new CooldownState();
OvaleState.RegisterState(cooldownState);
