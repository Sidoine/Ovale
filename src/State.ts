import { OvaleDebug } from "./Debug";
import { OvaleQueue } from "./Queue";
import { Ovale } from "./Ovale";
import { pairs, LuaObj } from "@wowts/lua";

let OvaleStateBase = Ovale.NewModule("OvaleState");
export let OvaleState: OvaleStateClass;

let self_stateAddons = new OvaleQueue<StateModule>("OvaleState_stateAddons");

export interface StateModule {
    CleanState():void;
    InitializeState():void;
    ResetState():void;
    ApplySpellStartCast?(spellId, targetGUID, startCast, endCast, channel, spellcast):void;
    ApplySpellAfterCast?(spellId, targetGUID, startCast, endCast, channel, spellcast):void;
    ApplySpellOnHit?(spellId, targetGUID, startCast, endCast, channel, spellcast):void;
}

const OvaleStateBaseClass = OvaleDebug.RegisterDebugging(OvaleStateBase);
class OvaleStateClass extends OvaleStateBaseClass {
    RegisterState(stateAddon: StateModule) {
        self_stateAddons.Insert(stateAddon);
    }
    UnregisterState(stateAddon: StateModule) {
        let stateModules = new OvaleQueue<StateModule>("OvaleState_stateModules");
        while (self_stateAddons.Size() > 0) {
            let addon = self_stateAddons.Remove();
            if (stateAddon != addon) {
                stateModules.Insert(addon);
            }
        }
        self_stateAddons = stateModules;
        stateAddon.CleanState();
    }
    InitializeState() {
        const iterator = self_stateAddons.Iterator();
        while (iterator.Next()) {
            iterator.value.InitializeState();
        }
    }
    ResetState() {
        const iterator = self_stateAddons.Iterator();
        while (iterator.Next()) {
            iterator.value.ResetState();
        }
    }

    ApplySpellStartCast(spellId, targetGUID, startCast, endCast, channel, spellcast) {
        const iterator = self_stateAddons.Iterator();
        while (iterator.Next()) {
            if (iterator.value.ApplySpellStartCast) {
                iterator.value.ApplySpellStartCast(spellId, targetGUID, startCast, endCast, channel, spellcast);
            }
        }
    }

    ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, channel, spellcast) {
        const iterator = self_stateAddons.Iterator();
        while (iterator.Next()) {
            if (iterator.value.ApplySpellAfterCast){
                iterator.value.ApplySpellAfterCast(spellId, targetGUID, startCast, endCast, channel, spellcast);
            }
        }
    }
    
    ApplySpellOnHit(spellId, targetGUID, startCast, endCast, channel, spellcast) {
        const iterator = self_stateAddons.Iterator();
        while (iterator.Next()) {
            if (iterator.value.ApplySpellOnHit) {
                iterator.value.ApplySpellOnHit(spellId, targetGUID, startCast, endCast, channel, spellcast);
            }
        }
    }
}

OvaleState = new OvaleStateClass();

export class BaseState implements StateModule {
    isState = true;
    isInitialized = false;
    futureVariable: LuaObj<any> = undefined;
    futureLastEnable: LuaObj<number> = undefined;
    variable:LuaObj<any> = undefined;
    lastEnable: LuaObj<number> = undefined;
    inCombat: boolean;
    currentTime: number;
    defaultTarget: string;

   
    InitializeState() {
        this.futureVariable = {}
        this.futureLastEnable = {}
        this.variable = {}
        this.lastEnable = {}
        this.defaultTarget = "target";
    }
    ResetState() {
        for (const [k] of pairs(this.futureVariable)) {
            this.futureVariable[k] = undefined;
            this.futureLastEnable[k] = undefined;
        }
        if (!this.inCombat) {
            for (const [k] of pairs(this.variable)) {
                this.Log("Resetting state variable '%s'.", k);
                this.variable[k] = undefined;
                this.lastEnable[k] = undefined;
            }
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
        this.defaultTarget = undefined;        
    }

    GetState(name) {
        return this.futureVariable[name] || this.variable[name] || 0;
    }
    GetStateDuration(name) {
        let lastEnable = this.futureLastEnable[name] || this.lastEnable[name] || this.currentTime;
        return this.currentTime - lastEnable;
    }
    PutState (name, value, isFuture) {
        if (isFuture) {
            let oldValue = this.GetState(name);
            if (value != oldValue) {
                this.Log("Setting future state: %s from %s to %s.", name, oldValue, value);
                this.futureVariable[name] = value;
                this.futureLastEnable[name] = this.currentTime;
            }
        } else {
            let oldValue = this.variable[name] || 0;
            if (value != oldValue) {
                OvaleState.DebugTimestamp("Advancing combat state: %s from %s to %s.", name, oldValue, value);
                this.Log("Advancing combat state: %s from %s to %s.", name, oldValue, value);
                this.variable[name] = value;
                this.lastEnable[name] = this.currentTime;
            }
        }
    }

    Log(...__args) {
        OvaleState.Log(...__args);
    }
}

export const baseState = new BaseState();