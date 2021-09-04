import { SpellId } from "@wowts/wow-mock";
import { LuaArray, lualength, pairs } from "@wowts/lua";
import { insert, remove } from "@wowts/table";
import { OvaleClass } from "../Ovale";
import { StateModule } from "../engine/state";
import { OvaleCombatClass } from "./combat";
import {
    CombatLogEvent,
    DamagePayload,
    SpellPeriodicPayloadHeader,
} from "../engine/combat-log-event";

let serial = 1;
const maxLength = 30;
export class OvaleStaggerClass implements StateModule {
    staggerTicks: LuaArray<number> = {};

    constructor(
        private ovale: OvaleClass,
        private combat: OvaleCombatClass,
        private combatLogEvent: CombatLogEvent
    ) {
        ovale.createModule(
            "OvaleStagger",
            this.handleInitialize,
            this.handleDisable
        );
    }

    private handleInitialize = () => {
        if (this.ovale.playerClass == "MONK") {
            this.combatLogEvent.registerEvent(
                "SPELL_PERIODIC_DAMAGE",
                this,
                this.handleSpellPeriodicDamage
            );
        }
    };
    private handleDisable = () => {
        if (this.ovale.playerClass == "MONK") {
            this.combatLogEvent.unregisterAllEvents(this);
        }
    };
    private handleSpellPeriodicDamage = (cleuEvent: string) => {
        const cleu = this.combatLogEvent;
        if (cleu.sourceGUID == this.ovale.playerGUID) {
            serial = serial + 1;
            const header = cleu.header as SpellPeriodicPayloadHeader;
            if (header.spellId == SpellId.stagger_buff) {
                const payload = cleu.payload as DamagePayload;
                insert(this.staggerTicks, payload.amount);
                if (lualength(this.staggerTicks) > maxLength) {
                    remove(this.staggerTicks, 1);
                }
            }
        }
    };

    cleanState(): void {}
    initializeState(): void {}
    resetState(): void {
        if (!this.combat.isInCombat(undefined)) {
            for (const [k] of pairs(this.staggerTicks)) {
                delete this.staggerTicks[k];
            }
        }
    }

    lastTickDamage(countTicks: number): number {
        if (!countTicks || countTicks == 0 || countTicks < 0) countTicks = 1;

        let damage = 0;
        const arrLen = lualength(this.staggerTicks);

        if (arrLen < 1) return 0;

        for (let i = arrLen; i > arrLen - (countTicks - 1); i += -1) {
            damage += this.staggerTicks[i] || 0;
        }
        return damage;
    }
}
