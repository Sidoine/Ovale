import { OvalePool } from "../tools/Pool";
import { Deque } from "../tools/Queue";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { band } from "@wowts/bit";
import { LuaObj, pairs } from "@wowts/lua";
import { Enum, GetTime } from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import {
    CombatLogEvent,
    DamagePayload,
    RangePayloadHeader,
    SpellPayloadHeader,
    SpellPeriodicPayloadHeader,
} from "../engine/combat-log-event";
import { Tracer, DebugTools } from "../engine/debug";

interface Event {
    timestamp: number;
    damage: number;
    magic: boolean;
}
const pool = new OvalePool<Event>("OvaleDamageTaken_pool");
const damageTakenWindow = 20;
const schoolMaskMagic = Enum.Damageclass.MaskMagical;

const damageTakenEvent: LuaObj<boolean> = {
    RANGE_DAMAGE: true,
    SPELL_DAMAGE: true,
    SPELL_PERIODIC_DAMAGE: true,
    SWING_DAMAGE: true,
};

export class OvaleDamageTakenClass {
    damageEvent = new Deque<Event>(); // newest events pushed onto back of deque
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    constructor(
        private ovale: OvaleClass,
        ovaleDebug: DebugTools,
        private combatLogEvent: CombatLogEvent
    ) {
        this.module = ovale.createModule(
            "OvaleDamageTaken",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
    }

    private handleInitialize = () => {
        this.module.RegisterEvent(
            "PLAYER_REGEN_ENABLED",
            this.handlePlayerRegenEnabled
        );
        this.module.RegisterMessage(
            "Ovale_CombatLogEvent",
            this.handleOvaleCombatLogEvent
        );
        for (const [event] of pairs(damageTakenEvent)) {
            this.combatLogEvent.registerEvent(event, this);
        }
    };

    private handleDisable = () => {
        this.module.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.module.UnregisterMessage("Ovale_CombatLogEvent");
        for (const [event] of pairs(damageTakenEvent)) {
            this.combatLogEvent.registerEvent(event, this);
        }
        pool.drain();
    };

    private handleOvaleCombatLogEvent = (event: string, cleuEvent: string) => {
        if (!damageTakenEvent[cleuEvent]) {
            return;
        }
        const cleu = this.combatLogEvent;
        const destGUID = cleu.destGUID;
        if (destGUID == this.ovale.playerGUID) {
            const payload = cleu.payload as DamagePayload;
            const amount = payload.amount;
            const now = GetTime();
            if (cleu.header.type == "SWING") {
                this.tracer.debug("%s caused %d damage.", cleuEvent, amount);
                this.addDamageTaken(now, amount);
            } else {
                let spellName: string | undefined;
                let school: number | undefined;
                if (cleu.header.type == "RANGE") {
                    const header = cleu.header as RangePayloadHeader;
                    spellName = header.spellName;
                    school = header.school;
                } else if (cleu.header.type == "SPELL") {
                    const header = cleu.header as SpellPayloadHeader;
                    spellName = header.spellName;
                    school = header.school;
                } else if (cleu.header.type == "SPELL_PERIODIC") {
                    const header = cleu.header as SpellPeriodicPayloadHeader;
                    spellName = header.spellName;
                    school = header.school;
                }
                if (spellName && school) {
                    const isMagicDamage = band(school, schoolMaskMagic) > 0;
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
            }
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
        const event = pool.get();
        event.timestamp = timestamp;
        event.damage = damage;
        event.magic = isMagicDamage || false;
        this.damageEvent.push(event);
        this.removeExpiredEvents(timestamp);
        this.ovale.needRefresh();
    }

    getRecentDamage(interval: number) {
        const now = GetTime();
        const lowerBound = now - interval;
        this.removeExpiredEvents(now);
        let [total, totalMagic] = [0, 0];
        const iterator = this.damageEvent.backToFrontIterator();
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
        while (true) {
            // remove expired events from front of deque
            const event = this.damageEvent.front();
            if (!event) {
                break;
            }
            if (timestamp - event.timestamp < damageTakenWindow) {
                break;
            }
            this.damageEvent.shift();
            pool.release(event);
            this.ovale.needRefresh();
        }
    }
    debugDamageTaken() {
        this.tracer.print(this.module.GetName());
        const iterator = this.damageEvent.backToFrontIterator();
        while (iterator.next()) {
            const event = iterator.value;
            this.tracer.print("%d: %d damage", event.timestamp, event.damage);
        }
    }
}
