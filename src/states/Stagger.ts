import { SpellId, UnitStagger } from "@wowts/wow-mock";
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
import {
    ConditionFunction,
    ConditionResult,
    OvaleConditionClass,
    parseCondition,
    returnConstant,
    returnValueBetween,
} from "../engine/condition";
import { OvaleAuraClass } from "./Aura";
import { OvaleHealthClass } from "./Health";
import { isNumber } from "../tools/tools";
import { BaseState } from "./BaseState";
import { AstFunctionNode, NamedParametersOf } from "../engine/ast";

const lightStagger = SpellId.light_stagger_buff;
const moderateStagger = SpellId.moderate_stagger_buff;
const heavyStagger = SpellId.heavy_stagger_buff;
const staggerDoT = 124255;

let serial = 1;
const maxLength = 30;
export class OvaleStaggerClass implements StateModule {
    staggerTicks: LuaArray<number> = {};

    constructor(
        private ovale: OvaleClass,
        private combat: OvaleCombatClass,
        private baseState: BaseState,
        private aura: OvaleAuraClass,
        private health: OvaleHealthClass,
        private combatLogEvent: CombatLogEvent
    ) {
        ovale.createModule(
            "OvaleStagger",
            this.handleInitialize,
            this.handleDisable
        );
    }

    public registerConditions(ovaleCondition: OvaleConditionClass) {
        ovaleCondition.registerCondition(
            "staggerremaining",
            false,
            this.staggerRemaining
        );
        ovaleCondition.registerCondition(
            "staggerremains",
            false,
            this.staggerRemaining
        );
        ovaleCondition.registerCondition(
            "staggertick",
            false,
            this.staggerTick
        );
        ovaleCondition.registerCondition(
            "staggerpercent",
            false,
            this.staggerPercent
        );
        ovaleCondition.registerCondition(
            "staggermissingpercent",
            false,
            this.missingStaggerPercent
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
            if (header.spellId == staggerDoT) {
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

    /** Get the remaining amount of damage Stagger will cause to the target.
	 @name StaggerRemaining
	 @paramsig number
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return The amount of damage.
	 @usage
	 if StaggerRemaining() / MaxHealth() >0.4 Spell(purifying_brew)
     */
    private staggerRemaining: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [target] = parseCondition(namedParams, this.baseState);
        return this.getAnyStaggerAura(target, atTime);
    };

    private getAnyStaggerAura(target: string, atTime: number): ConditionResult {
        let aura = this.aura.getAura(target, heavyStagger, atTime, "HARMFUL");
        if (!aura || !this.aura.isActiveAura(aura, atTime)) {
            aura = this.aura.getAura(
                target,
                moderateStagger,
                atTime,
                "HARMFUL"
            );
        }
        if (!aura || !this.aura.isActiveAura(aura, atTime)) {
            aura = this.aura.getAura(target, lightStagger, atTime, "HARMFUL");
        }
        if (aura && this.aura.isActiveAura(aura, atTime)) {
            const [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            const stagger = UnitStagger(target);
            const rate = (-1 * stagger) / (ending - start);
            return returnValueBetween(gain, ending, 0, ending, rate);
        }
        return [];
    }

    private staggerPercent: ConditionFunction = (
        positionalparameters,
        namedParams,
        atTime
    ) => {
        const [target] = parseCondition(namedParams, this.baseState);
        let [start, ending, value, origin, rate] = this.getAnyStaggerAura(
            target,
            atTime
        );
        const healthMax = this.health.getUnitHealthMax(target);
        if (value !== undefined && isNumber(value)) {
            value = (value * 100) / healthMax;
        }
        if (rate !== undefined) {
            rate = (rate * 100) / healthMax;
        }
        return [start, ending, value, origin, rate];
    };

    private missingStaggerPercent: ConditionFunction = (
        positionalparameters,
        namedParams,
        atTime
    ) => {
        const [target] = parseCondition(namedParams, this.baseState);
        let [start, ending, value, origin, rate] = this.getAnyStaggerAura(
            target,
            atTime
        );
        const healthMax = this.health.getUnitHealthMax(target);
        if (value !== undefined && isNumber(value)) {
            value = ((healthMax - value) * 100) / healthMax;
        }
        if (rate !== undefined) {
            rate = -(rate * 100) / healthMax;
        }
        return [start, ending, value, origin, rate];
    };

    /** Get the last Stagger tick damage.
	 @name StaggerTick
     @paramsig number or boolean
     @param count Optional. Counts n amount of previous stagger ticks.
	 @param target Optional. Sets the target to check. The target may also be given as a prefix to the condition.
	     Defaults to target=player.
	     Valid values: player, target, focus, pet.
	 @return Stagger tick damage.
	 @usage
     if StaggerTick() > 1000 Spell(purifying_brew) #return current tick of stagger
     or 
     if StaggerTick(2) > 1000 Spell(purifying_brew) #return two ticks of current stagger
     */
    private staggerTick: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const count = positionalParams[1];
        const damage = this.lastTickDamage(count);
        return returnConstant(damage);
    };
}
