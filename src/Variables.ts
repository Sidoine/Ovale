import { LuaObj, pairs } from "@wowts/lua";
import { StateModule, OvaleState } from "./State";
import { baseState } from "./BaseState";

export class Variables implements StateModule {
    isState = true;
    isInitialized = false;
    futureVariable: LuaObj<number> = undefined;
    futureLastEnable: LuaObj<number> = undefined;
    variable:LuaObj<number> = {};
    lastEnable: LuaObj<number> = {}
    
    InitializeState() {
        this.futureVariable = {}
        this.futureLastEnable = {}
        if (!baseState.current.inCombat) {
            for (const [k] of pairs(this.variable)) {
                this.Log("Resetting state variable '%s'.", k);
                this.variable[k] = undefined;
                this.lastEnable[k] = undefined;
            }
        }
    }
    ResetState() {
        for (const [k] of pairs(this.futureVariable)) {
            this.futureVariable[k] = undefined;
            this.futureLastEnable[k] = undefined;
        }
    }
    CleanState() {
        for (const [k] of pairs(this.futureVariable)) {
            this.futureVariable[k] = undefined;
        }
        for (const [k] of pairs(this.futureLastEnable)) {
            this.futureLastEnable[k] = undefined;
        }
        for (const [k] of pairs(this.variable)) {
            this.variable[k] = undefined;
        }
        for (const [k] of pairs(this.lastEnable)) {
            this.lastEnable[k] = undefined;
        }      
    }

    GetState(name: string) {
        return this.futureVariable[name] || this.variable[name] || 0;
    }
    GetStateDuration(name: string) {
        let lastEnable = this.futureLastEnable[name] || this.lastEnable[name] || baseState.next.currentTime;
        return baseState.next.currentTime - lastEnable;
    }
    PutState(name: string, value: number, isFuture: boolean, atTime: number) {
        if (isFuture) {
            let oldValue = this.GetState(name);
            if (value != oldValue) {
                this.Log("Setting future state: %s from %s to %s.", name, oldValue, value);
                this.futureVariable[name] = value;
                this.futureLastEnable[name] = atTime;
            }
        } else {
            let oldValue = this.variable[name] || 0;
            if (value != oldValue) {
                OvaleState.DebugTimestamp("Advancing combat state: %s from %s to %s.", name, oldValue, value);
                this.Log("Advancing combat state: %s from %s to %s.", name, oldValue, value);
                this.variable[name] = value;
                this.lastEnable[name] = atTime;
            }
        }
    }

    Log(...__args: any[]) {
        OvaleState.Log(...__args);
    }
}

export const variables = new Variables();
OvaleState.RegisterState(variables);