import { States, StateModule } from "../engine/state";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { Tracer, DebugTools } from "../engine/debug";
import { GetTime } from "@wowts/wow-mock";
import { OvaleSpellBookClass } from "./SpellBook";
import { LuaArray } from "@wowts/lua";
import {
    OvaleConditionClass,
    ConditionFunction,
    returnBoolean,
    returnConstant,
    returnValueBetween,
} from "../engine/condition";
import { huge as INFINITY } from "@wowts/math";
import { AstFunctionNode, NamedParametersOf } from "../engine/ast";

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

    public registerConditions(condition: OvaleConditionClass) {
        condition.registerCondition("incombat", false, this.inCombat);
        condition.registerCondition("timeincombat", false, this.timeInCombat);
        condition.registerCondition(
            "expectedcombatlength",
            false,
            this.expectedCombatLength
        );
        condition.registerCondition("fightremains", false, this.fightRemains);
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

    /** Test if the player is in combat.
	 @name InCombat
	 @paramsig boolean
	 @param yesno Optional. If yes, then return true if the player is in combat. If no, then return true if the player isn't in combat.
	     Default is yes.
	     Valid values: yes, no.
	 @return A boolean value.
	 @usage
	 if not InCombat() and not Stealthed() Spell(stealth)
     */
    private inCombat = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean = this.isInCombat(atTime);
        return returnBoolean(boolean);
    };

    /** Get the number of seconds elapsed since the player entered combat.
	 @name TimeInCombat
	 @paramsig number or boolean
	 @return The number of seconds.
	 @usage
	 if TimeInCombat() > 5 Spell(bloodlust)
     */
    private timeInCombat = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        if (this.isInCombat(atTime)) {
            const state = this.getState(atTime);
            const start = state.combatStartTime;
            return returnValueBetween(start, INFINITY, 0, start, 1);
        }
        return returnConstant(0);
    };

    private expectedCombatLength: ConditionFunction = (
        positional,
        named,
        atTime
    ) => {
        // TODO maybe should depend on the fact that it is a boss fight or not
        return returnConstant(15 * 60);
    };

    private fightRemains: ConditionFunction = () => {
        // TODO use enemies health
        return returnConstant(15 * 60);
    };
}
