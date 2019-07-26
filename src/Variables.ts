import { LuaObj, pairs } from "@wowts/lua";
import { StateModule } from "./State";
import { OvaleFutureClass } from "./Future";
import { BaseState } from "./BaseState";
import { OvaleDebugClass, Tracer } from "./Debug";

export class Variables implements StateModule {
    isState = true;
    isInitialized = false;
    futureVariable: LuaObj<number> = undefined;
    futureLastEnable: LuaObj<number> = undefined;
    variable:LuaObj<number> = {};
    lastEnable: LuaObj<number> = {}
    private tracer: Tracer;
    
    constructor(private ovaleFuture: OvaleFutureClass, private baseState: BaseState, ovaleDebug: OvaleDebugClass) {
        this.tracer = ovaleDebug.create("Variables");
    }

    InitializeState() {
        this.futureVariable = {}
        this.futureLastEnable = {}
        if (!this.ovaleFuture.IsInCombat(undefined)) {
            for (const [k] of pairs(this.variable)) {
                this.tracer.Log("Resetting state variable '%s'.", k);
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
        let lastEnable = this.futureLastEnable[name] || this.lastEnable[name] || this.baseState.next.currentTime;
        return this.baseState.next.currentTime - lastEnable;
    }
    PutState(name: string, value: number, isFuture: boolean, atTime: number) {
        if (isFuture) {
            let oldValue = this.GetState(name);
            if (value != oldValue) {
                this.tracer.Log("Setting future state: %s from %s to %s.", name, oldValue, value);
                this.futureVariable[name] = value;
                this.futureLastEnable[name] = atTime;
            }
        } else {
            let oldValue = this.variable[name] || 0;
            if (value != oldValue) {
                this.tracer.DebugTimestamp("Advancing combat state: %s from %s to %s.", name, oldValue, value);
                this.tracer.Log("Advancing combat state: %s from %s to %s.", name, oldValue, value);
                this.variable[name] = value;
                this.lastEnable[name] = atTime;
            }
        }
    }
}
