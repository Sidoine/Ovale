import { OvaleFuture } from "./Future";
import { OvaleCooldown } from "./Cooldown";
import { lastSpell, self_pool, SpellCast } from "./LastSpell";
import { OvaleSpellBook } from "./SpellBook";
import { OvaleGUID } from "./GUID";
import { OvaleState, baseState } from "./State";
import { Ovale } from "./Ovale";
import { paperDollState, OvalePaperDoll } from "./PaperDoll";
import { dataState } from "./DataState";
import { OvaleStance } from "./Stance";
import { wipe, pairs, lualength } from "@wowts/lua";
import { GetTime } from "@wowts/wow-mock";
import { insert, remove } from "@wowts/table";

let SIMULATOR_LAG = 0.005;

class FutureState {

    inCombat = undefined;
    combatStartTime = undefined;
    currentSpellId = undefined;
    startCast = undefined;
    endCast = undefined;
    nextCast: number = undefined;
    lastCast = undefined;
    channel = undefined;
    lastSpellId = undefined;
    lastGCDSpellId = undefined;
    lastGCDSpellIds = {}
    
    lastOffGCDSpellId = undefined;
    counter = undefined;
    
    InitializeState() {
        this.lastCast = {}
        this.counter = {}
    }
    ResetState() {
        OvaleFuture.StartProfiling("OvaleFuture_ResetState");
        let now = GetTime();
        baseState.currentTime = now;
        OvaleFuture.Log("Reset state with current time = %f", baseState.currentTime);
        this.inCombat = OvaleFuture.inCombat;
        this.combatStartTime = OvaleFuture.combatStartTime || 0;
        this.nextCast = now;
        let reason = "";
        let [start, duration] = OvaleCooldown.GetGlobalCooldown(now);
        if (start && start > 0) {
            let ending = start + duration;
            if (this.nextCast < ending) {
                this.nextCast = ending;
                reason = " (waiting for GCD)";
            }
        }
        let lastGCDSpellcastFound, lastOffGCDSpellcastFound, lastSpellcastFound;
        for (let i = lualength(lastSpell.queue); i >= 1; i += -1) {
            let spellcast = lastSpell.queue[i];
            if (spellcast.spellId && spellcast.start) {
                OvaleFuture.Log("    Found cast %d of spell %s (%d), start = %s, stop = %s.", i, spellcast.spellName, spellcast.spellId, spellcast.start, spellcast.stop);
                if (!lastSpellcastFound) {
                    this.lastSpellId = spellcast.spellId;
                    if (spellcast.start && spellcast.stop && spellcast.start <= now && now < spellcast.stop) {
                        this.currentSpellId = spellcast.spellId;
                        this.startCast = spellcast.start;
                        this.endCast = spellcast.stop;
                        this.channel = spellcast.channel;
                    }
                    lastSpellcastFound = true;
                }
                if (!lastGCDSpellcastFound && !spellcast.offgcd) {
                    this.PushGCDSpellId(spellcast.spellId);
                    if (spellcast.stop && this.nextCast < spellcast.stop) {
                        this.nextCast = spellcast.stop;
                        reason = " (waiting for spellcast)";
                    }
                    lastGCDSpellcastFound = true;
                }
                if (!lastOffGCDSpellcastFound && spellcast.offgcd) {
                    this.lastOffGCDSpellId = spellcast.spellId;
                    lastOffGCDSpellcastFound = true;
                }
            }
            if (lastGCDSpellcastFound && lastOffGCDSpellcastFound && lastSpellcastFound) {
                break;
            }
        }
        if (!lastSpellcastFound) {
            let spellcast = lastSpell.lastSpellcast;
            if (spellcast) {
                this.lastSpellId = spellcast.spellId;
                if (spellcast.start && spellcast.stop && spellcast.start <= now && now < spellcast.stop) {
                    this.currentSpellId = spellcast.spellId;
                    this.startCast = spellcast.start;
                    this.endCast = spellcast.stop;
                    this.channel = spellcast.channel;
                }
            }
        }
        if (!lastGCDSpellcastFound) {
            let spellcast = lastSpell.lastGCDSpellcast;
            if (spellcast) {
                this.lastGCDSpellId = spellcast.spellId;
                if (spellcast.stop && this.nextCast < spellcast.stop) {
                    this.nextCast = spellcast.stop;
                    reason = " (waiting for spellcast)";
                }
            }
        }
        if (!lastOffGCDSpellcastFound) {
            let spellcast = OvaleFuture.lastOffGCDSpellcast;
            if (spellcast) {
                this.lastOffGCDSpellId = spellcast.spellId;
            }
        }
        OvaleFuture.Log("    lastSpellId = %s, lastGCDSpellId = %s, lastOffGCDSpellId = %s", this.lastSpellId, this.lastGCDSpellId, this.lastOffGCDSpellId);
        OvaleFuture.Log("    nextCast = %f%s", this.nextCast, reason);
        wipe(this.lastCast);
        for (const [k, v] of pairs(OvaleFuture.counter)) {
            this.counter[k] = v;
        }
        OvaleFuture.StopProfiling("OvaleFuture_ResetState");
    }
    CleanState() {
        for (const [k] of pairs(this.lastCast)) {
            this.lastCast[k] = undefined;
        }
        for (const [k] of pairs(this.counter)) {
            this.counter[k] = undefined;
        }
    }
    ApplySpellStartCast(spellId, targetGUID, startCast, endCast, channel, spellcast) {
        OvaleFuture.StartProfiling("OvaleFuture_ApplySpellStartCast");
        if (channel) {
            OvaleFuture.UpdateCounters(spellId, startCast, targetGUID);
        }
        OvaleFuture.StopProfiling("OvaleFuture_ApplySpellStartCast");
    }
    ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, channel, spellcast) {
        OvaleFuture.StartProfiling("OvaleFuture_ApplySpellAfterCast");
        if (!channel) {
            OvaleFuture.UpdateCounters(spellId, endCast, targetGUID);
        }
        OvaleFuture.StopProfiling("OvaleFuture_ApplySpellAfterCast");
    }

    GetCounter (id) {
        return this.counter[id] || 0;
    }
    GetCounterValue(id) {
        return this.GetCounter(id);
    }

    TimeOfLastCast(spellId) {
        return this.lastCast[spellId] || OvaleFuture.lastCastTime[spellId] || 0;
    }
    IsChanneling(atTime) {
        atTime = atTime || baseState.currentTime;
        return this.channel && (atTime < this.endCast);
    }
    static staticSpellcast = {}

    PushGCDSpellId(spellId) {
        if (this.lastGCDSpellId) {
            insert(this.lastGCDSpellIds, this.lastGCDSpellId);
            if (lualength(this.lastGCDSpellIds) > 5) {
                remove(this.lastGCDSpellIds, 1);
            }
        }
        this.lastGCDSpellId = spellId;
    }
    ApplySpell(spellId:number, targetGUID:string, startCast:number, endCast?:number, channel?: boolean, spellcast?: SpellCast) {
        OvaleFuture.StartProfiling("OvaleFuture_state_ApplySpell");
        if (spellId) {
            if (!targetGUID) {
                targetGUID = Ovale.playerGUID;
            }
            let castTime;
            if (startCast && endCast) {
                castTime = endCast - startCast;
            } else {
                castTime = OvaleSpellBook.GetCastTime(spellId) || 0;
                startCast = startCast || this.nextCast;
                endCast = endCast || (startCast + castTime);
            }
            if (!spellcast) {
                spellcast = FutureState.staticSpellcast;
                wipe(spellcast);
                spellcast.caster = Ovale.playerGUID;
                spellcast.spellId = spellId;
                spellcast.spellName = OvaleSpellBook.GetSpellName(spellId);
                spellcast.target = targetGUID;
                spellcast.targetName = OvaleGUID.GUIDName(targetGUID);
                spellcast.start = startCast;
                spellcast.stop = endCast;
                spellcast.channel = channel;
                paperDollState.UpdateSnapshot(spellcast);
                let atTime = channel && startCast || endCast;
                for (const [, mod] of pairs(lastSpell.modules)) {
                    let func = mod.SaveSpellcastInfo;
                    if (func) {
                        func(mod, spellcast, atTime, this);
                    }
                }
            }
            this.lastSpellId = spellId;
            this.startCast = startCast;
            this.endCast = endCast;
            this.lastCast[spellId] = endCast;
            this.channel = channel;
            let gcd = this.GetGCD(spellId, startCast, targetGUID);
            let nextCast = (castTime > gcd) && endCast || (startCast + gcd);
            if (this.nextCast < nextCast) {
                this.nextCast = nextCast;
            }
            if (gcd > 0) {
                this.PushGCDSpellId(spellId);
            } else {
                this.lastOffGCDSpellId = spellId;
            }
            let now = GetTime();
            if (startCast >= now) {
                baseState.currentTime = startCast + SIMULATOR_LAG;
            } else {
                baseState.currentTime = now;
            }
            OvaleFuture.Log("Apply spell %d at %f currentTime=%f nextCast=%f endCast=%f targetGUID=%s", spellId, startCast, baseState.currentTime, nextCast, endCast, targetGUID);
            if (!this.inCombat && OvaleSpellBook.IsHarmfulSpell(spellId)) {
                this.inCombat = true;
                if (channel) {
                    this.combatStartTime = startCast;
                } else {
                    this.combatStartTime = endCast;
                }
            }
            if (startCast > now) {
                OvaleState.ApplySpellStartCast(spellId, targetGUID, startCast, endCast, channel, spellcast);
            }
            if (endCast > now) {
                OvaleState.ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, channel, spellcast);
            }
            OvaleState.ApplySpellOnHit(spellId, targetGUID, startCast, endCast, channel, spellcast);
        }
        OvaleFuture.StopProfiling("OvaleFuture_state_ApplySpell");
    }
    GetDamageMultiplier(spellId, targetGUID, atTime) {
        return OvaleFuture.GetDamageMultiplier(spellId, targetGUID, atTime);
    }
    UpdateCounters(spellId, atTime, targetGUID){
        return OvaleFuture.UpdateCounters(spellId, atTime, targetGUID);
    }

    
    ApplyInFlightSpells() {
        // this.StartProfiling("OvaleFuture_ApplyInFlightSpells");
        let now = GetTime();
        let index = 1;
        while (index <= lualength(lastSpell.queue)) {
            let spellcast = lastSpell.queue[index];
            if (spellcast.stop) {
                let isValid = false;
                let description;
                if (now < spellcast.stop) {
                    isValid = true;
                    description = spellcast.channel && "channelling" || "being cast";
                } else if (now < spellcast.stop + 5) {
                    isValid = true;
                    description = "in flight";
                }
                if (isValid) {
                    if (spellcast.target) {
                        OvaleState.Log("Active spell %s (%d) is %s to %s (%s), now=%f, endCast=%f", spellcast.spellName, spellcast.spellId, description, spellcast.targetName, spellcast.target, now, spellcast.stop);
                    } else {
                        OvaleState.Log("Active spell %s (%d) is %s, now=%f, endCast=%f", spellcast.spellName, spellcast.spellId, description, now, spellcast.stop);
                    }
                    this.ApplySpell(spellcast.spellId, spellcast.target, spellcast.start, spellcast.stop, spellcast.channel, spellcast);
                } else {
                    // if (spellcast.target) {
                    //     this.Debug("Warning: removing active spell %s (%d) to %s (%s) that should have finished.", spellcast.spellName, spellcast.spellId, spellcast.targetName, spellcast.target);
                    // } else {
                    //     this.Debug("Warning: removing active spell %s (%d) that should have finished.", spellcast.spellName, spellcast.spellId);
                    // }
                    remove(lastSpell.queue, index);
                    self_pool.Release(spellcast);
                    index = index - 1;
                }
            }
            index = index + 1;
        }
        // this.StopProfiling("OvaleFuture_ApplyInFlightSpells");
    }

    GetGCD(spellId?, atTime?, targetGUID?) {
        spellId = spellId || futureState.currentSpellId;
        if (!atTime) {
            if (futureState.endCast && futureState.endCast > baseState.currentTime) {
                atTime = futureState.endCast;
            } else {
                atTime = baseState.currentTime;
            }
        }
        targetGUID = targetGUID || OvaleGUID.UnitGUID(baseState.defaultTarget);
        let gcd = spellId && <number>dataState.GetSpellInfoProperty(spellId, atTime, "gcd", targetGUID);
        if (!gcd) {
            let haste;
            [gcd, haste] = OvaleCooldown.GetBaseGCD();
            if (Ovale.playerClass == "MONK" && OvalePaperDoll.IsSpecialization("mistweaver")) {
                gcd = 1.5;
                haste = "spell";
            } else if (Ovale.playerClass == "DRUID") {
                if (OvaleStance.IsStance("druid_cat_form")) {
                    gcd = 1.0;
                    haste = false;
                }
            }
            let gcdHaste = spellId && dataState.GetSpellInfoProperty(spellId, atTime, "gcd_haste", targetGUID);
            if (gcdHaste) {
                haste = gcdHaste;
            } else {
                let siHaste = spellId && dataState.GetSpellInfoProperty(spellId, atTime, "haste", targetGUID);
                if (siHaste) {
                    haste = siHaste;
                }
            }
            let multiplier = paperDollState.GetHasteMultiplier(haste);
            gcd = gcd / multiplier;
            gcd = (gcd > 0.750) && gcd || 0.750;
        }
        return gcd;
    }
}
    
export const futureState = new FutureState();
OvaleState.RegisterState(futureState);
    
    