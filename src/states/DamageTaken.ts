import { OvalePool } from "../tools/Pool";
import { OvaleQueue } from "../tools/Queue";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { band } from "@wowts/bit";
import { sub } from "@wowts/string";
import {
    CombatLogGetCurrentEventInfo,
    Enum,
    GetTime,
} from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { Profiler, OvaleProfilerClass } from "../engine/profiler";
import { Tracer, DebugTools } from "../engine/debug";

interface Event {
    timestamp: number;
    damage: number;
    magic: boolean;
}
const pool = new OvalePool<Event>("OvaleDamageTaken_pool");
const damageTakenWindow = 20;
const schoolMaskMagic = Enum.Damageclass.MaskMagical;

export class OvaleDamageTakenClass {
    damageEvent = new OvaleQueue<Event>("OvaleDamageTaken_damageEvent");
    private module: AceModule & AceEvent;
    private profiler: Profiler;
    private tracer: Tracer;

    constructor(
        private ovale: OvaleClass,
        profiler: OvaleProfilerClass,
        ovaleDebug: DebugTools
    ) {
        this.module = ovale.createModule(
            "OvaleDamageTaken",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.profiler = profiler.create(this.module.GetName());
        this.tracer = ovaleDebug.create(this.module.GetName());
    }

    private handleInitialize = () => {
        this.module.RegisterEvent(
            "COMBAT_LOG_EVENT_UNFILTERED",
            this.handleCombatLogEventUnfiltered
        );
        this.module.RegisterEvent(
            "PLAYER_REGEN_ENABLED",
            this.handlePlayerRegenEnabled
        );
    };

    private handleDisable = () => {
        this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.module.UnregisterEvent("PLAYER_REGEN_ENABLED");
        pool.drain();
    };

    private handleCombatLogEventUnfiltered = (
        event: string,
        ...parameters: any[]
    ) => {
        const [
            ,
            cleuEvent,
            ,
            ,
            ,
            ,
            ,
            destGUID,
            ,
            ,
            ,
            arg12,
            arg13,
            arg14,
            arg15,
        ] = CombatLogGetCurrentEventInfo();
        if (
            destGUID == this.ovale.playerGUID &&
            sub(cleuEvent, -7) == "_DAMAGE"
        ) {
            this.profiler.startProfiling(
                "OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED"
            );
            const now = GetTime();
            const eventPrefix = sub(cleuEvent, 1, 6);
            if (eventPrefix == "SWING_") {
                const amount = arg12;
                this.tracer.debug("%s caused %d damage.", cleuEvent, amount);
                this.addDamageTaken(now, amount);
            } else if (eventPrefix == "RANGE_" || eventPrefix == "SPELL_") {
                const [spellName, spellSchool, amount] = [arg13, arg14, arg15];
                const isMagicDamage = band(spellSchool, schoolMaskMagic) > 0;
                if (isMagicDamage) {
                    this.tracer.debug(
                        "%s (%s) caused %d magic damage.",
                        cleuEvent,
                        spellName,
                        amount
                    );
                } else {
                    this.tracer.debug(
                        "%s (%s) caused %d damage.",
                        cleuEvent,
                        spellName,
                        amount
                    );
                }
                this.addDamageTaken(now, amount, isMagicDamage);
            }
            this.profiler.stopProfiling(
                "OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED"
            );
        }
    };
    private handlePlayerRegenEnabled = (event: string) => {
        pool.drain();
    };

    private addDamageTaken(
        timestamp: number,
        damage: number,
        isMagicDamage?: boolean
    ) {
        this.profiler.startProfiling("OvaleDamageTaken_AddDamageTaken");
        const event = pool.get();
        event.timestamp = timestamp;
        event.damage = damage;
        event.magic = isMagicDamage || false;
        this.damageEvent.insertFront(event);
        this.removeExpiredEvents(timestamp);
        this.ovale.needRefresh();
        this.profiler.stopProfiling("OvaleDamageTaken_AddDamageTaken");
    }

    getRecentDamage(interval: number) {
        const now = GetTime();
        const lowerBound = now - interval;
        this.removeExpiredEvents(now);
        let [total, totalMagic] = [0, 0];
        const iterator = this.damageEvent.frontToBackIterator();
        while (iterator.next()) {
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
    removeExpiredEvents(timestamp: number) {
        this.profiler.startProfiling("OvaleDamageTaken_RemoveExpiredEvents");
        while (true) {
            const event = this.damageEvent.back();
            if (!event) {
                break;
            }
            if (event) {
                if (timestamp - event.timestamp < damageTakenWindow) {
                    break;
                }
                this.damageEvent.removeBack();
                pool.release(event);
                this.ovale.needRefresh();
            }
        }
        this.profiler.stopProfiling("OvaleDamageTaken_RemoveExpiredEvents");
    }
    debugDamageTaken() {
        this.tracer.print(this.damageEvent.debuggingInfo());
        const iterator = this.damageEvent.backToFrontIterator();
        while (iterator.next()) {
            const event = iterator.value;
            this.tracer.print("%d: %d damage", event.timestamp, event.damage);
        }
    }
}
