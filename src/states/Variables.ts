import { LuaArray, LuaObj, pairs, wipe } from "@wowts/lua";
import { StateModule } from "../engine/state";
import { BaseState } from "./BaseState";
import { OvaleDebugClass, Tracer } from "../engine/debug";
import { OvaleCombatClass } from "./combat";
import {
    Compare,
    ConditionAction,
    OvaleConditionClass,
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
        ovaleDebug: OvaleDebugClass
    ) {
        this.tracer = ovaleDebug.create("Variables");
    }

    registerConditions(condition: OvaleConditionClass) {
        condition.RegisterCondition("getstate", false, this.getState);
        condition.registerAction("setstate", this.setState);
        condition.RegisterCondition(
            "getstateduration",
            false,
            this.getStateDuration
        );
    }

    InitializeState() {
        if (!this.combat.isInCombat(undefined)) {
            for (const [k] of pairs(this.variable)) {
                this.tracer.Log("Resetting state variable '%s'.", k);
                delete this.variable[k];
                delete this.lastEnable[k];
            }
        }
    }
    ResetState() {
        for (const [k] of pairs(this.futureVariable)) {
            delete this.futureVariable[k];
            delete this.futureLastEnable[k];
        }
    }
    CleanState() {
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

    GetState(name: string) {
        return this.futureVariable[name] || this.variable[name] || 0;
    }
    GetStateDuration(name: string) {
        const lastEnable =
            this.futureLastEnable[name] ||
            this.lastEnable[name] ||
            this.baseState.next.currentTime;
        return this.baseState.next.currentTime - lastEnable;
    }
    PutState(name: string, value: number, isFuture: boolean, atTime: number) {
        if (isFuture) {
            const oldValue = this.GetState(name);
            if (value != oldValue) {
                this.tracer.Log(
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
                this.tracer.DebugTimestamp(
                    "Advancing combat state: %s from %s to %s.",
                    name,
                    oldValue,
                    value
                );
                this.tracer.Log(
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
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The value of the state variable.
	 @return A boolean value for the result of the comparison.
     */
    private getState = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [name, comparator, limit] = [
            positionalParams[1],
            positionalParams[2],
            positionalParams[3],
        ];
        const value = this.GetState(name);
        return Compare(value, comparator, limit);
    };

    /** Get the duration in seconds that the simulator was most recently in the named state.
	 @name GetStateDuration
	 @paramsig number or boolean
	 @param name The name of the state variable.
	 @param operator Optional. Comparison operator: less, atMost, equal, atLeast, more.
	 @param number Optional. The number to compare against.
	 @return The number of seconds.
	 @return A boolean value for the result of the comparison.
     */
    private getStateDuration = (
        positionalParams: LuaArray<any>,
        namedParams: NamedParametersOf<AstFunctionNode>,
        atTime: number
    ) => {
        const [name, comparator, limit] = [
            positionalParams[1],
            positionalParams[2],
            positionalParams[3],
        ];
        const value = this.GetStateDuration(name);
        return Compare(value, comparator, limit);
    };

    private setState: ConditionAction = (
        positionalParams,
        namedParams,
        atTime,
        result
    ) => {
        const name = positionalParams[1] as string;
        const value = positionalParams[2] as number;
        const currentValue = this.GetState(name);
        if (currentValue !== value) {
            // TODO The actual variable setting is done
            // when "displaying" the value
            setResultType(result, "state");
            result.value = value;
            result.name = name;
            result.timeSpan.Copy(0, huge);
        } else {
            wipe(result.timeSpan);
        }
    };
}
