import { OvalePool } from "./Pool";
import { OvaleQueue } from "./Queue";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { band, bor } from "@wowts/bit";
import { sub } from "@wowts/string";
import { GetTime, SCHOOL_MASK_ARCANE, SCHOOL_MASK_FIRE, SCHOOL_MASK_FROST, SCHOOL_MASK_HOLY, SCHOOL_MASK_NATURE, SCHOOL_MASK_SHADOW, CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "./Ovale";
import { Profiler, OvaleProfilerClass } from "./Profiler";
import { Tracer, OvaleDebugClass } from "./Debug";

interface Event{
    timestamp: number;
    damage: number;
    magic: boolean;
}
let self_pool = new OvalePool<Event>("OvaleDamageTaken_pool");
let DAMAGE_TAKEN_WINDOW = 20;
let SCHOOL_MASK_MAGIC = bor(SCHOOL_MASK_ARCANE, SCHOOL_MASK_FIRE, SCHOOL_MASK_FROST, SCHOOL_MASK_HOLY, SCHOOL_MASK_NATURE, SCHOOL_MASK_SHADOW);

export class OvaleDamageTakenClass {
    damageEvent = new OvaleQueue<Event>("OvaleDamageTaken_damageEvent");
    private module: AceModule & AceEvent;
    private profiler: Profiler;
    private tracer: Tracer;

    constructor(private ovale: OvaleClass, profiler: OvaleProfilerClass, ovaleDebug: OvaleDebugClass) {
        this.module = ovale.createModule("OvaleDamageTaken", this.OnInitialize, this.OnDisable, aceEvent);
        this.profiler = profiler.create(this.module.GetName());
        this.tracer = ovaleDebug.create(this.module.GetName());
    }

    private OnInitialize = () => {
        this.module.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", this.COMBAT_LOG_EVENT_UNFILTERED);
        this.module.RegisterEvent("PLAYER_REGEN_ENABLED", this.PLAYER_REGEN_ENABLED);
    }
    
    private OnDisable = () => {
        this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.module.UnregisterEvent("PLAYER_REGEN_ENABLED");
        self_pool.Drain();
    }
    
    private COMBAT_LOG_EVENT_UNFILTERED = (event: string, ...__args: any[]) => {
        let [, cleuEvent, , , , , , destGUID, , , , arg12, arg13, arg14, arg15] = CombatLogGetCurrentEventInfo();
        if (destGUID == this.ovale.playerGUID && sub(cleuEvent, -7) == "_DAMAGE") {
            this.profiler.StartProfiling("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED");
            let now = GetTime();
            let eventPrefix = sub(cleuEvent, 1, 6);
            if (eventPrefix == "SWING_") {
                let amount = arg12;
                this.tracer.Debug("%s caused %d damage.", cleuEvent, amount);
                this.AddDamageTaken(now, amount);
            } else if (eventPrefix == "RANGE_" || eventPrefix == "SPELL_") {
                let [spellName, spellSchool, amount] = [arg13, arg14, arg15];
                let isMagicDamage = (band(spellSchool, SCHOOL_MASK_MAGIC) > 0);
                if (isMagicDamage) {
                    this.tracer.Debug("%s (%s) caused %d magic damage.", cleuEvent, spellName, amount);
                } else {
                    this.tracer.Debug("%s (%s) caused %d damage.", cleuEvent, spellName, amount);
                }
                this.AddDamageTaken(now, amount, isMagicDamage);
            }
            this.profiler.StopProfiling("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    private PLAYER_REGEN_ENABLED = (event: string) => {
        self_pool.Drain();
    }
    
    private AddDamageTaken(timestamp: number, damage: number, isMagicDamage?: boolean) {
        this.profiler.StartProfiling("OvaleDamageTaken_AddDamageTaken");
        let event = self_pool.Get();
        event.timestamp = timestamp;
        event.damage = damage;
        event.magic = isMagicDamage;
        this.damageEvent.InsertFront(event);
        this.RemoveExpiredEvents(timestamp);
        this.ovale.needRefresh();
        this.profiler.StopProfiling("OvaleDamageTaken_AddDamageTaken");
    }
    
    GetRecentDamage(interval: number) {
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
    RemoveExpiredEvents(timestamp: number) {
        this.profiler.StartProfiling("OvaleDamageTaken_RemoveExpiredEvents");
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
                this.ovale.needRefresh();
            }
        }
        this.profiler.StopProfiling("OvaleDamageTaken_RemoveExpiredEvents");
    }
    DebugDamageTaken() {
        this.tracer.Print(this.damageEvent.DebuggingInfo());
        const iterator = this.damageEvent.BackToFrontIterator();
        while (iterator.Next()) {
            const event = iterator.value;
            this.tracer.Print("%d: %d damage", event.timestamp, event.damage);
        }
    }
}
