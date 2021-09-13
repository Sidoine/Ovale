import { SpellId, UnitStagger } from "@wowts/wow-mock";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray, pairs } from "@wowts/lua";
import { AceModule } from "@wowts/tsaddon";
import { OvaleClass } from "../Ovale";
import {
    CombatLogEvent,
    DamagePayload,
    SpellPeriodicPayloadHeader,
} from "../engine/combat-log-event";
import {
    ConditionFunction,
    OvaleConditionClass,
    returnConstant,
    returnValueBetween,
} from "../engine/condition";
import { DebugTools, Tracer } from "../engine/debug";
import { OvaleAuraClass } from "./Aura";
import { OvaleHealthClass } from "./Health";
import { OvalePaperDollClass } from "./PaperDoll";
import { Deque } from "../tools/Queue";
import { isNumber } from "../tools/tools";
import { AstFunctionNode, NamedParametersOf } from "../engine/ast";

const staggerAuraId: LuaArray<boolean> = {
    [SpellId.heavy_stagger_buff]: true,
    [SpellId.moderate_stagger_buff]: true,
    [SpellId.light_stagger_buff]: true,
};

export class OvaleStaggerClass {
    private module: AceModule & AceEvent;
    private tracer: Tracer;
    // keep a history of the last 30 ticks of Stagger
    private staggerTicks = new Deque<number>(30, true);

    constructor(
        private ovale: OvaleClass,
        debug: DebugTools,
        private aura: OvaleAuraClass,
        private health: OvaleHealthClass,
        private paperDoll: OvalePaperDollClass,
        private combatLogEvent: CombatLogEvent
    ) {
        this.module = ovale.createModule(
            "OvaleStagger",
            this.onEnable,
            this.onDisable,
            aceEvent
        );
        this.tracer = debug.create(this.module.GetName());
    }

    private onEnable = () => {
        if (this.ovale.playerClass == "MONK") {
            this.module.RegisterMessage(
                "Ovale_SpecializationChanged",
                this.onOvaleSpecializationChanged
            );
        }
        const specialization = this.paperDoll.getSpecialization();
        this.onOvaleSpecializationChanged(
            "onEnable",
            specialization,
            specialization
        );
    };

    private onDisable = () => {
        if (this.ovale.playerClass == "MONK") {
            this.module.UnregisterMessage("Ovale_SpecializationChanged");
            this.module.UnregisterMessage("Ovale_AuraRemoved");
            this.combatLogEvent.unregisterAllEvents(this);
            this.emptyTickQueue();
        }
    };

    private onOvaleSpecializationChanged = (
        event: string,
        newSpecialization: string,
        oldSpecialization: string
    ) => {
        if (newSpecialization == "brewmaster") {
            this.tracer.debug("Installing stagger event handlers.");
            this.module.RegisterMessage(
                "Ovale_AuraRemoved",
                this.onOvaleAuraRemoved
            );
            this.combatLogEvent.registerEvent(
                "SPELL_PERIODIC_DAMAGE",
                this,
                this.onSpellPeriodicDamage
            );
        } else {
            this.tracer.debug("Removing stagger event handlers.");
            this.module.UnregisterMessage("Ovale_AuraRemoved");
            this.combatLogEvent.unregisterAllEvents(this);
            this.emptyTickQueue();
        }
    };

    private onOvaleAuraRemoved = (
        event: string,
        atTime: number,
        guid: string,
        auraId: number,
        caster: string
    ) => {
        if (staggerAuraId[auraId]) {
            const stagger = UnitStagger("player");
            if (stagger === 0) {
                this.tracer.debug("Empty stagger pool; clearing ticks.");
                this.emptyTickQueue();
            }
        }
    };

    private onSpellPeriodicDamage = (cleuEvent: string) => {
        const cleu = this.combatLogEvent;
        if (cleu.sourceGUID == this.ovale.playerGUID) {
            const header = cleu.header as SpellPeriodicPayloadHeader;
            if (header.spellId == SpellId.stagger_buff) {
                const payload = cleu.payload as DamagePayload;
                const amount = payload.amount;
                this.tracer.debug(
                    `stagger tick ${amount} (${this.staggerTicks.length})`
                );
                this.staggerTicks.push(amount);
            }
        }
    };

    private emptyTickQueue = () => {
        const queue = this.staggerTicks;
        // TODO replace with queue.clear() when available
        queue.first = 0;
        queue.last = 0;
        queue.length = 0;
    };

    private getAnyStaggerAura(atTime: number) {
        for (const [auraId] of pairs(staggerAuraId)) {
            const aura = this.aura.getAura("player", auraId, atTime, "HARMFUL");
            if (aura && this.aura.isActiveAura(aura, atTime)) {
                return aura;
            }
        }
        return undefined;
    }

    lastTickDamage(countTicks?: number): number {
        if (!countTicks || countTicks === 0 || countTicks < 0) {
            countTicks = 1;
        }
        let damage = 0;
        const queue = this.staggerTicks;
        for (let i = queue.length; i >= 1; i--) {
            if (countTicks > 0) {
                const amount = queue.at(i) || 0;
                damage += amount;
                countTicks -= 1;
            }
        }
        return damage;
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

    /** Get the remaining amount of damage Stagger will cause to the target.
	 @name StaggerRemaining
	 @paramsig number
	 @return The amount of damage.
	 @usage
	 if StaggerRemaining() / MaxHealth() >0.4 Spell(purifying_brew)
     */
    private staggerRemaining: ConditionFunction = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const aura = this.getAnyStaggerAura(atTime);
        if (aura) {
            const [gain, start, ending] = [aura.gain, aura.start, aura.ending];
            const stagger = UnitStagger("player");
            const rate = (-1 * stagger) / (ending - start);
            return returnValueBetween(gain, ending, 0, ending, rate);
        }
        return [];
    };

    private staggerPercent: ConditionFunction = (
        positionalparameters,
        namedParams,
        atTime
    ) => {
        let [start, ending, value, origin, rate] = this.staggerRemaining(
            positionalparameters,
            namedParams,
            atTime
        );
        const healthMax = this.health.getUnitHealthMax("player");
        if (value && isNumber(value)) {
            value = (value * 100) / healthMax;
        }
        if (rate) {
            rate = (rate * 100) / healthMax;
        }
        return [start, ending, value, origin, rate];
    };

    private missingStaggerPercent: ConditionFunction = (
        positionalparameters,
        namedParams,
        atTime
    ) => {
        let [start, ending, value, origin, rate] = this.staggerRemaining(
            positionalparameters,
            namedParams,
            atTime
        );
        const healthMax = this.health.getUnitHealthMax("player");
        if (value && isNumber(value)) {
            value = ((healthMax - value) * 100) / healthMax;
        }
        if (rate) {
            rate = -(rate * 100) / healthMax;
        }
        return [start, ending, value, origin, rate];
    };

    /** Get the last Stagger tick damage.
	 @name StaggerTick
     @paramsig number or boolean
     @param count Optional. Counts n amount of previous stagger ticks.
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
