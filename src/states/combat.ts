import { States, StateModule } from "../engine/state";
import { OvaleClass } from "../Ovale";
import { AceModule } from "@wowts/tsaddon";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { Tracer, OvaleDebugClass } from "../engine/debug";
import { GetTime } from "@wowts/wow-mock";
import { OvaleSpellBookClass } from "./SpellBook";
import { LuaArray } from "@wowts/lua";
import {
    OvaleConditionClass,
    ConditionFunction,
    ReturnBoolean,
    ReturnConstant,
    ReturnValueBetween,
} from "../engine/condition";
import { huge as INFINITY } from "@wowts/math";
import { AstFunctionNode, NamedParametersOf } from "../engine/ast";

export class CombatState {
    inCombat = false;
    combatStartTime = 0;
}

export class OvaleCombatClass
    extends States<CombatState>
    implements StateModule {
    private module: AceModule & AceEvent;
    private tracer: Tracer;

    constructor(
        private ovale: OvaleClass,
        debug: OvaleDebugClass,
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
        condition.RegisterCondition("incombat", false, this.InCombat);
        condition.RegisterCondition("timeincombat", false, this.TimeInCombat);
        condition.RegisterCondition(
            "expectedcombatlength",
            false,
            this.expectedCombatLength
        );
        condition.RegisterCondition("fightremains", false, this.fightRemains);
    }

    public isInCombat(atTime: number | undefined) {
        return this.GetState(atTime).inCombat;
    }

    public InitializeState() {}

    public ResetState() {
        this.next.inCombat = this.current.inCombat;
        this.next.combatStartTime = this.current.combatStartTime || 0;
    }

    public CleanState() {}

    public ApplySpellOnHit = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        channel: boolean
    ) => {
        if (
            !this.next.inCombat &&
            this.ovaleSpellBook.IsHarmfulSpell(spellId)
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
        this.tracer.Debug(event, "Entering combat.");
        const now = GetTime();
        this.current.inCombat = true;
        this.current.combatStartTime = now;
        this.ovale.needRefresh();
        this.module.SendMessage("Ovale_CombatStarted", now);
    };

    private handlePlayerRegenEnabled = (event: string) => {
        this.tracer.Debug(event, "Leaving combat.");
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
    private InCombat = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const boolean = this.isInCombat(atTime);
        return ReturnBoolean(boolean);
    };

    /** Get the number of seconds elapsed since the player entered combat.
	 @name TimeInCombat
	 @paramsig number or boolean
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if TimeInCombat() > 5 Spell(bloodlust)
     */
    private TimeInCombat = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        if (this.isInCombat(atTime)) {
            const state = this.GetState(atTime);
            const start = state.combatStartTime;
            return ReturnValueBetween(start, INFINITY, 0, start, 1);
        }
        return ReturnConstant(0);
    };

    private expectedCombatLength: ConditionFunction = (
        positional,
        named,
        atTime
    ) => {
        // TODO maybe should depend on the fact that it is a boss fight or not
        return ReturnConstant(15 * 60);
    };

    private fightRemains: ConditionFunction = () => {
        // TODO use enemies health
        return ReturnConstant(15 * 60);
    };
}
