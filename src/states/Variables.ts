import { LuaObj, pairs } from "@wowts/lua";
import { StateModule } from "../State";
import { BaseState } from "../BaseState";
import { OvaleDebugClass, Tracer } from "../Debug";
import { OvaleCombatClass } from "./combat";

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
        let lastEnable =
            this.futureLastEnable[name] ||
            this.lastEnable[name] ||
            this.baseState.next.currentTime;
        return this.baseState.next.currentTime - lastEnable;
    }
    PutState(name: string, value: number, isFuture: boolean, atTime: number) {
        if (isFuture) {
            let oldValue = this.GetState(name);
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
            let oldValue = this.variable[name] || 0;
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
}
