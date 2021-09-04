import { States, StateModule } from "../engine/state";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { Tracer, DebugTools } from "../engine/debug";
import { GetTime } from "@wowts/wow-mock";
import { OvaleSpellBookClass } from "./SpellBook";

export class CombatState {
    inCombat = false;
    combatStartTime = 0;
}

export class OvaleCombatClass
    extends States<CombatState>
    implements StateModule
{
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    constructor(
        private ovale: OvaleClass,
        debug: DebugTools,
        private ovaleSpellBook: OvaleSpellBookClass
    ) {
        super(CombatState);
        this.module = ovale.createModule(
            "Combat",
            this.onInitialize,
            this.onRelease,
            aceEvent
        );
        this.tracer = debug.create("OvaleCombat");
    }

    public isInCombat(atTime: number | undefined) {
        return this.getState(atTime).inCombat;
    }

    public initializeState() {}

    public resetState() {
        this.next.inCombat = this.current.inCombat;
        this.next.combatStartTime = this.current.combatStartTime || 0;
    }

    public cleanState() {}

    public applySpellOnHit = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        channel: boolean
    ) => {
        if (
            !this.next.inCombat &&
            this.ovaleSpellBook.isHarmfulSpell(spellId)
        ) {
            this.next.inCombat = true;
            if (channel) {
                this.next.combatStartTime = startCast;
            } else {
                this.next.combatStartTime = endCast;
            }
        }
    };

    private onInitialize = () => {
        this.module.RegisterEvent(
            "PLAYER_REGEN_DISABLED",
            this.handlePlayerRegenDisabled
        );
        this.module.RegisterEvent(
            "PLAYER_REGEN_ENABLED",
            this.handlePlayerRegenEnabled
        );
    };

    private onRelease = () => {
        this.module.UnregisterEvent("PLAYER_REGEN_DISABLED");
        this.module.UnregisterEvent("PLAYER_REGEN_ENABLED");
    };

    private handlePlayerRegenDisabled = (event: string) => {
        this.tracer.debug(event, "Entering combat.");
        const now = GetTime();
        this.current.inCombat = true;
        this.current.combatStartTime = now;
        this.ovale.needRefresh();
        this.module.SendMessage("Ovale_CombatStarted", now);
    };

    private handlePlayerRegenEnabled = (event: string) => {
        this.tracer.debug(event, "Leaving combat.");
        const now = GetTime();
        this.current.inCombat = false;
        this.ovale.needRefresh();
        this.module.SendMessage("Ovale_CombatEnded", now);
    };
}
