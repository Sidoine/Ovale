import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { CombatLogGetCurrentEventInfo } from "@wowts/wow-mock";
import { LuaArray, LuaObj } from "@wowts/lua";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";

const combatLogDamageEvents: LuaObj<boolean> = {
    SPELL_DAMAGE: true,
    SPELL_PERIODIC_AURA: true,
};

export class OvaleSpellDamageClass {
    value: LuaArray<number> = {};
    private module: AceModule & AceEvent;

    constructor(private ovale: OvaleClass) {
        this.module = ovale.createModule(
            "OvaleSpellDamage",
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
    }

    private handleInitialize = () => {
        this.module.RegisterEvent(
            "COMBAT_LOG_EVENT_UNFILTERED",
            this.handleCombatLogEventUnfiltered
        );
    };

    private handleDisable = () => {
        this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    };

    private handleCombatLogEventUnfiltered = (
        event: string,
        ...parameters: any[]
    ) => {
        const [, cleuEvent, , sourceGUID, , , , , , , , arg12, , , arg15] =
            CombatLogGetCurrentEventInfo();
        if (sourceGUID == this.ovale.playerGUID) {
            if (combatLogDamageEvents[cleuEvent]) {
                const [spellId, amount] = [arg12, arg15];
                this.value[spellId] = amount;
                this.ovale.needRefresh();
            }
        }
    };
    getSpellDamage(spellId: number) {
        return this.value[spellId];
    }
}
