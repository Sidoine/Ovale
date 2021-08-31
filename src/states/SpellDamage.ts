import { LuaArray } from "@wowts/lua";
import { OvaleClass } from "../Ovale";
import {
    CombatLogEvent,
    DamagePayload,
    SpellPayloadHeader,
    SpellPeriodicPayloadHeader,
} from "../engine/combat-log-event";

export class OvaleSpellDamageClass {
    value: LuaArray<number> = {};

    constructor(
        private ovale: OvaleClass,
        private combatLogEvent: CombatLogEvent
    ) {
        ovale.createModule(
            "OvaleSpellDamage",
            this.handleInitialize,
            this.handleDisable
        );
    }

    private handleInitialize = () => {
        this.combatLogEvent.registerEvent(
            "SPELL_DAMAGE",
            this,
            this.handleCombatLogEvent
        );
        this.combatLogEvent.registerEvent(
            "SPELL_PERIODIC_DAMAGE",
            this,
            this.handleCombatLogEvent
        );
    };

    private handleDisable = () => {
        this.combatLogEvent.unregisterAllEvents(this);
    };

    private handleCombatLogEvent = (cleuEvent: string) => {
        const cleu = this.combatLogEvent;
        if (cleu.sourceGUID == this.ovale.playerGUID) {
            let spellId: number | undefined;
            if (cleu.header.type == "SPELL") {
                const header = cleu.header as SpellPayloadHeader;
                spellId = header.spellId;
            } else if (cleu.header.type == "SPELL_PERIODIC") {
                const header = cleu.header as SpellPeriodicPayloadHeader;
                spellId = header.spellId;
            }
            if (spellId) {
                const payload = cleu.payload as DamagePayload;
                this.value[spellId] = payload.amount;
                this.ovale.needRefresh();
            }
        }
    };
    getSpellDamage(spellId: number) {
        return this.value[spellId];
    }
}
