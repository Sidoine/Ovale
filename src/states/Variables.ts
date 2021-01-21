import { LuaArray, LuaObj, pairs, wipe } from "@wowts/lua";
import { StateModule } from "../engine/state";
import { BaseState } from "./BaseState";
import { DebugTools, Tracer } from "../engine/debug";
import { OvaleCombatClass } from "./combat";
import {
    ConditionAction,
    OvaleConditionClass,
    returnConstant,
} from "../engine/condition";
import { huge } from "@wowts/math";
import {
    AstFunctionNode,
    NamedParametersOf,
    setResultType,
} from "../engine/ast";

export class Variables implements StateModule {
    isState = true;
    isInitialized = false;
    futureVariable: LuaObj<number> = {};
    futureLastEnable: LuaObj<number> = {};
    variable: LuaObj<number> = {};
    lastEnable: LuaObj<number> = {};
    private tracer: Tracer;

    constructor(
        private combat: OvaleCombatClass,
        private baseState: BaseState,
        ovaleDebug: DebugTools
    ) {
        this.tracer = ovaleDebug.create("Variables");
    }

    registerConditions(condition: OvaleConditionClass) {
        condition.registerCondition("getstate", false, this.getState);
        condition.registerAction("setstate", this.setState);
        condition.registerCondition(
            "getstateduration",
            false,
            this.getStateDuration
        );
    }

    initializeState() {
        if (!this.combat.isInCombat(undefined)) {
            for (const [k] of pairs(this.variable)) {
                this.tracer.log("Resetting state variable '%s'.", k);
                delete this.variable[k];
                delete this.lastEnable[k];
            }
        }
    }
    resetState() {
        for (const [k] of pairs(this.futureVariable)) {
            delete this.futureVariable[k];
            delete this.futureLastEnable[k];
        }
    }
    cleanState() {
        for (const [k] of pairs(this.futureVariable)) {
            delete this.futureVariable[k];
        }
        for (const [k] of pairs(this.futureLastEnable)) {
            delete this.futureLastEnable[k];
        }
        for (const [k] of pairs(this.variable)) {
            delete this.variable[k];
        }
        for (const [k] of pairs(this.lastEnable)) {
            delete this.lastEnable[k];
        }
    }

    getStateValue(name: string) {
        return this.futureVariable[name] || this.variable[name] || 0;
    }
    getStateDurationAtTime(name: string, atTime: number) {
        const lastEnable =
            this.futureLastEnable[name] ||
            this.lastEnable[name] ||
            this.baseState.currentTime;
        return atTime - lastEnable;
    }
    putState(name: string, value: number, isFuture: boolean, atTime: number) {
        if (isFuture) {
            const oldValue = this.getStateValue(name);
            if (value != oldValue) {
                this.tracer.log(
                    "Setting future state: %s from %s to %s.",
                    name,
                    oldValue,
                    value
                );
                this.futureVariable[name] = value;
                this.futureLastEnable[name] = atTime;
            }
        } else {
            const oldValue = this.variable[name] || 0;
            if (value != oldValue) {
                this.tracer.debugTimestamp(
                    "Advancing combat state: %s from %s to %s.",
                    name,
                    oldValue,
                    value
                );
                this.tracer.log(
                    "Advancing combat state: %s from %s to %s.",
                    name,
                    oldValue,
                    value
                );
                this.variable[name] = value;
                this.lastEnable[name] = atTime;
            }
        }
    }

    /**  Get the value of the named state variable from the simulator.
	 @name GetState
	 @paramsig number or boolean
	 @param name The name of the state variable.
	 @return The value of the state variable.
     */
    private getState = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const name = positionalParams[1];
        const value = this.getStateValue(name);
        return returnConstant(value);
    };

    /** Get the duration in seconds that the simulator was most recently in the named state.
	 @name GetStateDuration
	 @paramsig number or boolean
	 @param name The name of the state variable.
	 @return The number of seconds.
     */
    private getStateDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const name = positionalParams[1];
        const value = this.getStateDurationAtTime(name, atTime);
        return returnConstant(value);
    };

    private setState: ConditionAction = (
        positionalParams,
        namedParams,
        atTime,
        result
    ) => {
        const name = positionalParams[1] as string;
        const value = positionalParams[2] as number;
        const currentValue = this.getStateValue(name);
        if (currentValue !== value) {
            // TODO The actual variable setting is done
            // when "displaying" the value
            setResultType(result, "state");
            result.value = value;
            result.name = name;
            result.timeSpan.copy(0, huge);
        } else {
            wipe(result.timeSpan);
        }
    };
}
