import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { CombatLogGetCurrentEventInfo, UnitStagger } from "@wowts/wow-mock";
import { LuaArray, lualength, LuaObj, pairs } from "@wowts/lua";
import { insert, remove } from "@wowts/table";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import { StateModule } from "../State";
import { OvaleCombatClass } from "./combat";
import {
    Compare,
    ConditionFunction,
    ConditionResult,
    OvaleConditionClass,
    ParseCondition,
    ReturnValueBetween,
} from "../Condition";
import { OvaleAuraClass } from "./Aura";
import { OvaleHealthClass } from "./Health";
import { isNumber } from "../tools";
import { BaseState } from "../BaseState";

const LIGHT_STAGGER = 124275;
const MODERATE_STAGGER = 124274;
const HEAVY_STAGGER = 124273;

let self_serial = 1;
let MAX_LENGTH = 30;
export class OvaleStaggerClass implements StateModule {
    staggerTicks: LuaArray<number> = {};
    private module: AceModule & AceEvent;

    constructor(
        private ovale: OvaleClass,
        private combat: OvaleCombatClass,
        private baseState: BaseState,
        private aura: OvaleAuraClass,
        private health: OvaleHealthClass
    ) {
        this.module = ovale.createModule(
            "OvaleStagger",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
    }

    public registerConditions(ovaleCondition: OvaleConditionClass) {
        ovaleCondition.RegisterCondition(
            "staggerremaining",
            false,
            this.StaggerRemaining
        );
        ovaleCondition.RegisterCondition(
            "staggerremains",
            false,
            this.StaggerRemaining
        );
        ovaleCondition.RegisterCondition(
            "staggertick",
            false,
            this.StaggerTick
        );
        ovaleCondition.RegisterCondition(
            "staggerpercent",
            false,
            this.staggerPercent
        );
        ovaleCondition.RegisterCondition(
            "staggermissingpercent",
            false,
            this.missingStaggerPercent
        );
    }

    private OnInitialize = () => {
        if (this.ovale.playerClass == "MONK") {
            this.module.RegisterEvent(
                "COMBAT_LOG_EVENT_UNFILTERED",
                this.COMBAT_LOG_EVENT_UNFILTERED
            );
        }
    };
    private OnDisable = () => {
        if (this.ovale.playerClass == "MONK") {
            this.module.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    };
    private COMBAT_LOG_EVENT_UNFILTERED = (event: string, ...__args: any[]) => {
        let [
            ,
            cleuEvent,
            ,
            sourceGUID,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            spellId,
            ,
            ,
            amount,
        ] = CombatLogGetCurrentEventInfo();
        if (sourceGUID != this.ovale.playerGUID) {
            return;
        }
        self_serial = self_serial + 1;
        if (cleuEvent == "SPELL_PERIODIC_DAMAGE" && spellId == 124255) {
            insert(this.staggerTicks, amount);
            if (lualength(this.staggerTicks) > MAX_LENGTH) {
                remove(this.staggerTicks, 1);
            }
        }
    };

    CleanState(): void {}
    InitializeState(): void {}
    ResetState(): void {
        if (!this.combat.isInCombat(undefined)) {
            for (const [k] of pairs(this.staggerTicks)) {
                delete this.staggerTicks[k];
            }
        }
    }

    LastTickDamage(countTicks: number): number {
        if (!countTicks || countTicks == 0 || countTicks < 0) countTicks = 1;

        let damage = 0;
        let arrLen = lualength(this.staggerTicks);

        if (arrLen < 1) return 0;

        for (let i = arrLen; i > arrLen - (countTicks - 1); i += -1) {
            damage += this.staggerTicks[i] || 0;
        }
        return damage;
    }

    /** Get the remaining amount of damage Stagger will cause to the target.
	 @name StaggerRemaining
	 @paramsig number
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The amount of damage.
	 @return A boolean value for the result of the comparison.
	 @usage
	 if StaggerRemaining() / MaxHealth() >0.4 Spell(purifying_brew)
     */
    private StaggerRemaining: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: LuaObj<any>,
        atTime: number
    ) => {
        let [target] = ParseCondition(namedParams, this.baseState);
        return this.getAnyStaggerAura(target, atTime);
    };

    private getAnyStaggerAura(target: string, atTime: number): ConditionResult {
        let aura = this.aura.GetAura(target, HEAVY_STAGGER, atTime, "HARMFUL");
        if (!aura || !this.aura.IsActiveAura(aura, atTime)) {
            aura = this.aura.GetAura(
                target,
                MODERATE_STAGGER,
                atTime,
                "HARMFUL"
            );
        }
        if (!aura || !this.aura.IsActiveAura(aura, atTime)) {
            aura = this.aura.GetAura(target, LIGHT_STAGGER, atTime, "HARMFUL");
        }
        if (aura && this.aura.IsActiveAura(aura, atTime)) {
            let [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            let stagger = UnitStagger(target);
            let rate = (-1 * stagger) / (ending - start);
            return ReturnValueBetween(gain, ending, 0, ending, rate);
        }
        return [];
    }

    private staggerPercent: ConditionFunction = (
        positionalparameters,
        namedParams,
        atTime
    ) => {
        let [target] = ParseCondition(namedParams, this.baseState);
        let [start, end, value, origin, rate] = this.getAnyStaggerAura(
            target,
            atTime
        );
        const healthMax = this.health.UnitHealthMax(target);
        if (value !== undefined && isNumber(value)) {
            value = (value * 100) / healthMax;
        }
        if (rate !== undefined) {
            rate = (rate * 100) / healthMax;
        }
        return [start, end, value, origin, rate];
    };

    private missingStaggerPercent: ConditionFunction = (
        positionalparameters,
        namedParams,
        atTime
    ) => {
        let [target] = ParseCondition(namedParams, this.baseState);
        let [start, end, value, origin, rate] = this.getAnyStaggerAura(
            target,
            atTime
        );
        const healthMax = this.health.UnitHealthMax(target);
        if (value !== undefined && isNumber(value)) {
            value = ((healthMax - value) * 100) / healthMax;
        }
        if (rate !== undefined) {
            rate = -(rate * 100) / healthMax;
        }
        return [start, end, value, origin, rate];
    };

    /** Get the last Stagger tick damage.
	 @name StaggerTick
     @paramsig number or boolean
     @param count Optional. Counts n amount of previous stagger ticks.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return Stagger tick damage.
	 @return A boolean value for the result of the comparison.
	 @usage
     if StaggerTick() > 1000 Spell(purifying_brew) #return current tick of stagger
     or 
     if StaggerTick(2) > 1000 Spell(purifying_brew) #return two ticks of current stagger
     */
    private StaggerTick: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: LuaObj<any>,
        atTime: number
    ) => {
        let [count, comparator, limit] = [
            positionalParams[1],
            positionalParams[2],
            positionalParams[2],
        ];
        let damage = this.LastTickDamage(count);
        return Compare(damage, comparator, limit);
    };
}
