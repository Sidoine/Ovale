import { OvaleDebug } from "./Debug";
import { OvalePool } from "./Pool";
import { OvaleProfiler } from "./Profiler";
import { OvaleQueue } from "./Queue";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { band, bor } from "@wowts/bit";
import { sub } from "@wowts/string";
import { GetTime, SCHOOL_MASK_ARCANE, SCHOOL_MASK_FIRE, SCHOOL_MASK_FROST, SCHOOL_MASK_HOLY, SCHOOL_MASK_NATURE, SCHOOL_MASK_SHADOW } from "@wowts/wow-mock";

let OvaleDamageTakenBase = OvaleProfiler.RegisterProfiling(OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleDamageTaken", aceEvent)));
export let OvaleDamageTaken: OvaleDamageTakenClass;

interface Event{
    timestamp;
    damage;
    magic;
}
let self_pool = new OvalePool<Event>("OvaleDamageTaken_pool");
let DAMAGE_TAKEN_WINDOW = 20;
let SCHOOL_MASK_MAGIC = bor(SCHOOL_MASK_ARCANE, SCHOOL_MASK_FIRE, SCHOOL_MASK_FROST, SCHOOL_MASK_HOLY, SCHOOL_MASK_NATURE, SCHOOL_MASK_SHADOW);


class OvaleDamageTakenClass extends OvaleDamageTakenBase {
    damageEvent = new OvaleQueue<Event>("OvaleDamageTaken_damageEvent");

    OnInitialize() {
        this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.RegisterEvent("PLAYER_REGEN_ENABLED");
    }
    OnDisable() {
        this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.UnregisterEvent("PLAYER_REGEN_ENABLED");
        self_pool.Drain();
    }
    COMBAT_LOG_EVENT_UNFILTERED(event: string, ...__args: any[]) {
        let [timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, arg12, arg13, arg14, arg15, , , , , , , , , , ] = CombatLogGetCurrentEventInfo();
        if (destGUID == Ovale.playerGUID && sub(cleuEvent, -7) == "_DAMAGE") {
            this.StartProfiling("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED");
            let now = GetTime();
            let eventPrefix = sub(cleuEvent, 1, 6);
            if (eventPrefix == "SWING_") {
                let amount = arg12;
                this.Debug("%s caused %d damage.", cleuEvent, amount);
                this.AddDamageTaken(now, amount);
            } else if (eventPrefix == "RANGE_" || eventPrefix == "SPELL_") {
                let [spellName, spellSchool, amount] = [arg13, arg14, arg15];
                let isMagicDamage = (band(spellSchool, SCHOOL_MASK_MAGIC) > 0);
                if (isMagicDamage) {
                    this.Debug("%s (%s) caused %d magic damage.", cleuEvent, spellName, amount);
                } else {
                    this.Debug("%s (%s) caused %d damage.", cleuEvent, spellName, amount);
                }
                this.AddDamageTaken(now, amount, isMagicDamage);
            }
            this.StopProfiling("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    PLAYER_REGEN_ENABLED(event) {
        self_pool.Drain();
    }
    AddDamageTaken(timestamp, damage, isMagicDamage?) {
        this.StartProfiling("OvaleDamageTaken_AddDamageTaken");
        let event = self_pool.Get();
        event.timestamp = timestamp;
        event.damage = damage;
        event.magic = isMagicDamage;
        this.damageEvent.InsertFront(event);
        this.RemoveExpiredEvents(timestamp);
        Ovale.needRefresh();
        this.StopProfiling("OvaleDamageTaken_AddDamageTaken");
    }
    GetRecentDamage(interval) {
        let now = GetTime();
        let lowerBound = now - interval;
        this.RemoveExpiredEvents(now);
        let [total, totalMagic] = [0, 0];
        const iterator = this.damageEvent.FrontToBackIterator();
        while (iterator.Next()) {
            const event = iterator.value;
            if (event.timestamp < lowerBound) {
                break;
            }
            total = total + event.damage;
            if (event.magic) {
                totalMagic = totalMagic + event.damage;
            }
        }
        return [total, totalMagic];
    }
    RemoveExpiredEvents(timestamp) {
        this.StartProfiling("OvaleDamageTaken_RemoveExpiredEvents");
        while (true) {
            let event = this.damageEvent.Back();
            if (!event) {
                break;
            }
            if (event) {
                if (timestamp - event.timestamp < DAMAGE_TAKEN_WINDOW) {
                    break;
                }
                this.damageEvent.RemoveBack();
                self_pool.Release(event);
                Ovale.needRefresh();
            }
        }
        this.StopProfiling("OvaleDamageTaken_RemoveExpiredEvents");
    }
    DebugDamageTaken() {
        this.damageEvent.DebuggingInfo();
        const iterator = this.damageEvent.BackToFrontIterator();
        while (iterator.Next()) {
            const event = iterator.value;
            this.Print("%d: %d damage", event.timestamp, event.damage);
        }
    }
}

OvaleDamageTaken = new OvaleDamageTakenClass();