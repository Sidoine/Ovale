import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray } from "@wowts/lua";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import {
    CombatLogEvent,
    DamagePayload,
    SpellPayloadHeader,
    SpellPeriodicPayloadHeader,
} from "../engine/combat-log-event";

export class OvaleSpellDamageClass {
    value: LuaArray<number> = {};
    private module: AceModule & AceEvent;

    constructor(
        private ovale: OvaleClass,
        private combatLogEvent: CombatLogEvent
    ) {
        this.module = ovale.createModule(
            "OvaleSpellDamage",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
    }

    private handleInitialize = () => {
        this.module.RegisterMessage(
            "Ovale_CombatLogEvent",
            this.handleOvaleCombatLogEvent
        );
        this.combatLogEvent.registerEvent("SPELL_DAMAGE", this);
        this.combatLogEvent.registerEvent("SPELL_PERIODIC_DAMAGE", this);
    };

    private handleDisable = () => {
        this.module.UnregisterMessage("Ovale_CombatLogEvent");
        this.combatLogEvent.unregisterEvent("SPELL_DAMAGE", this);
        this.combatLogEvent.unregisterEvent("SPELL_PERIODIC_DAMAGE", this);
    };

    private handleOvaleCombatLogEvent = (event: string, cleuEvent: string) => {
        if (
            cleuEvent != "SPELL_DAMAGE" &&
            cleuEvent != "SPELL_PERIODIC_DAMAGE"
        ) {
            return;
        }
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
